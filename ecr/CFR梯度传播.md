CFR 的训练和梯度传播可以分为“前向预测、损失构造、反向传播、TwoStage 训练”四部分。

首先，输入是干预发生前的用户、订单、城市、时段等特征 \(x\)。离散特征先经过 embedding，和数值特征一起进入 shared bottom，得到共享表征：

$$
h_i=f_{\text{shared}}(x_i)
$$

然后以 cumulative response head 输出各档位响应。以 100 档 control 的 logit 为起点；按照折扣逐步加深的顺序，对每一档增加非负增量：

$$
l_{i,100}=g_{100}(h_i),\qquad
l_{i,a_j}=l_{i,a_{j-1}}+\operatorname{softplus}(\Delta_{a_j}(h_i)),
\qquad \hat\mu_{a_j}(x_i)=\sigma(l_{i,a_j})
$$

其中 \(a_0=100\)，\(a_1,a_2,\dots\) 是逐步加深的补贴档位；Softplus 保证每一步增量非负，因此深折扣的 logit、进而预测 Call 概率不低于浅折扣。100 档是 control，因此第 \(m\) 个补贴档位的 uplift 为：

$$
q_i^{(m)}=\hat\tau_m(x_i)=\hat\mu_m(x_i)-\hat\mu_{100}(x_i)
$$

可以把前向理解为：

```text
干预前特征 x
  → Embedding / 特征编码
  → Shared Bottom，得到 h(x)
  → Cumulative response head：100 档 base logit + 各档非负增量
  → μ̂_100(x), μ̂_97(x), μ̂_94(x), ...
  → 各档 uplift：μ̂_m(x) - μ̂_100(x)
```

第一阶段是 CFR 的 factual 训练。每个样本实际只进入一个 treatment，例如用户实际处于 94 档，那么只使用 94 档 head 的输出计算 BCE：

$$
\mathcal L_{\text{factual}}
=
-\frac{1}{n}\sum_i
\left[
y_i\log \hat\mu_{W_i}(x_i)
+
(1-y_i)\log(1-\hat\mu_{W_i}(x_i))
\right]
$$

这里 \(W_i\) 是样本实际被分到的档位。

从梯度看，若使用 logit 形式的 BCE，则实际 arm 的 logit 梯度很直观：

$$
\frac{\partial \mathcal L_{\text{factual}}}
{\partial l_{i,W_i}}
=
\hat\mu_{W_i}(x_i)-y_i
$$

所以：

- 实际档位 head 得到直接监督；
- 其他反事实 head 对该样本没有 factual 的直接梯度；
- 但实际档位 head 的梯度会继续回传至 shared bottom 和 embedding；
- 因为所有档位共享底座，不同 treatment 的样本共同塑造 \(h(x)\)，从而让各 head 可以基于共享表征学习反事实泛化。

这也是 CFR 的关键：反事实 head 并不是“凭空学出来”的，而是依赖随机实验、共享表征和因果约束间接学习。反过来，这也解释了它的局限：factual BCE 只保证 observed-arm response 拟合好，并不直接保证 uplift 排序正确。

CFR 的 base objective 还包括表征平衡或因果约束：

$$
\mathcal L_{\text{base}}
=
\mathcal L_{\text{factual}}
+
\alpha\mathcal L_{\text{imbalance}}
+
\beta\mathcal L_{\text{constraint}}
$$

其中 imbalance 的梯度主要直接作用在 shared representation \(h(x)\)，再回传到 shared bottom 和 embedding；通常不会像 factual BCE 一样直接监督某个 response head。它的作用是降低 treatment/control 在表示空间中的差异，使反事实泛化更合理。

目前材料记录了 imbalance、ATE、constraint 这些约束的存在，但没有给出某个具体实验中 IPM/Wasserstein 或 ATE 项的精确实现，因此面试中应说“采用表征平衡和因果约束”，不要擅自说成某一种唯一实现。

第二阶段才引入 uplift 排序目标。针对 treatment \(m\) 相对 control 100，先构造 IPW/PU 伪标签：

$$
z_i^{(m)}
=
(2y_i-1)
\left(
\frac{\mathbb{1}(W_i=m)}{e_m(x_i)}
-
\frac{\mathbb{1}(W_i=100)}{e_{100}(x_i)}
\right)
$$

这里 \(2y-1\) 很重要：它让 no-call 不再是零信息。treatment-no-call 是负向证据，control-no-call 则是相对正向证据。

为了不让不同档位的 score 尺度和极端值主导排序梯度，先对每个档位的 uplift 单独做校准：

$$
u_i=
\frac{
q_i-\operatorname{stopgrad}(\mu_m)
}{
\operatorname{stopgrad}(\sigma_m)+\epsilon
},
\qquad
\tilde q_i=\tanh(u_i/T)
$$

其中 `stopgrad` 表示均值和标准差仅是校准常数，不允许梯度通过 batch mean/std 回传。否则模型可能通过操纵整批样本的均值或方差降低 loss，而不是改善真正的样本相对顺序。

PU-Corr 的损失是：

$$
\mathcal L_{\text{corr}}
=
\frac{1}{|\mathcal M|}
\sum_m
\left[
1-\operatorname{Corr}(\tilde q^{(m)}, z^{(m)})
\right]
$$

Corr 的梯度是稠密的：一个样本的 score 不仅影响自身，也会通过 batch 的均值、协方差和方差影响同组其他样本。因此它对整体 AUCC 排序提升强，但也更容易放大 treatment assignment 或曝光结构中的捷径。

梯度路径可概括为：

```text
L_corr
  → 校准后的 uplift score q̃
  → 原始 uplift q = μ̂_m - μ̂_100
  → treatment-m head 与 control-100 head
  → Shared Bottom
  → Embedding / 输入特征参数
```

重点是：rank loss 会同时更新 treatment-\(m\) head 和 control head。因为：

$$
\frac{\partial q_i^{(m)}}{\partial \hat\mu_m}=1,
\qquad
\frac{\partial q_i^{(m)}}{\partial \hat\mu_{100}}=-1
$$

也就是说，如果模型要提高某个用户的 uplift，它既可以提高 treatment 下的预测响应，也可以降低 control 下的预测响应。正因如此，强 rank loss 有能力提升 AUCC，但也有风险破坏原有 response probability 的语义。

Matched Pairwise 则补充局部梯度。先在 Stage-1 的表征空间中为 treatment/control 样本寻找相似邻居，再对有明确方向的 pair 做 RankNet 式约束：

$$
\mathcal L_{\text{pair}}
=
\frac{1}{|P|}
\sum_{(i,j)\in P}
w_{ij}
\log
\left[
1+\exp
\left(
-\frac{
d_{ij}(\tilde q_i-\tilde q_j-\text{margin})
}{
T_{\text{rank}}
}
\right)
\right]
$$

如果 pair 的排序已经正确，梯度较小；错序越严重，梯度越大。它的梯度只集中在入选 pair 的两个样本及其对应的 treatment/control heads，因此比 Corr 更局部、更稀疏。

最终第二阶段总损失为：

$$
\mathcal L_{\text{total}}
=
\mathcal L_{\text{base}}
+
\lambda_c\mathcal L_{\text{corr}}
+
\lambda_p\mathcal L_{\text{pair}}
$$

当前材料中的 H2 Soft T2 配置为：

$$
\lambda_c=0.015,\qquad
\lambda_p=0.003,\qquad
T=2
$$

TwoStage 的目的，是控制 factual 梯度和 noisy rank 梯度之间的冲突：

1. Stage 1：仅训练 \(\mathcal L_{\text{base}}\)，学习稳定的 response/uplift anchor。
2. Stage 2 初期：加载 Stage-1 checkpoint，保留 factual loss，先冻结 embedding 和 shared bottom，只让各 treatment head 适应排序任务。
3. Stage 2 后期：embedding 继续冻结，shared bottom 以 `0.01 × lr_head` 的小学习率软解冻。
4. 这样 rank gradient 可以有限地调整共享表征，但不至于完全重写 Stage-1 已经学到的响应模型。

面试时最后可以总结：

> CFR 的 factual BCE 负责把“实际档位下会不会 Call”学准；共享表征与平衡约束让反事实估计有基础；Corr 和 Pairwise 再把梯度明确导向 uplift 排序。TwoStage 的本质，是先建立可信的 response anchor，再限制高噪声 rank gradient 对底座表征的破坏。


