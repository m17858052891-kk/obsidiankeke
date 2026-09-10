### 1. 特征 $X$、多档位 treatment $T$、观测标签 $Y$、各 treatment 下的潜在结果分别是什么？为什么这是多 treatment 的因果问题？
这个项目本质是一个多档位补贴的因果增量预测与排序问题。设用户、城市、时段、供需等干预前特征为 $X$，补贴档位为 $T$，例如 $T\in\{100,97,94,\dots,82\}$，100 表示不补贴；标签 $Y$ 是目标行为，如冒泡发单、完单或 Call。

对每个用户，理论上存在多个潜在结果：

$$
Y(100),Y(97),\dots,Y(82)
$$

但一次曝光只能观察到当前实际分配档位对应的 $Y(T)$，其余结果不可观测，因此不能直接按各组平均转化率决定策略。我们真正希望建模的是相对基准档位的增量：

$$
\tau_a(X)=\mathbb{E}[Y(a)-Y(100)\mid X],\quad a\in\{82,\dots,97\}
$$

最终策略不是找“完单概率最高”的用户，而是找“补贴后相对不补贴增量最大，且成本划算”的用户。

原始 CFR 的全链路是：输入特征 $X$，先经过共享表示网络得到 $\phi(X)$，再经不同 treatment head 输出各档位潜在响应 $\hat\mu_a(X)$。训练时只对样本实际接受的 treatment head 做 Factual BCE：

$$
L_{\text{factual}}
=
-\left[y\log \hat\mu_T(X)+(1-y)\log(1-\hat\mu_T(X))\right]
$$

同时加入表示平衡损失，例如 Wasserstein/IPM，使不同 treatment 组在表示空间更接近：

$$
L=L_{\text{factual}}+\lambda_{\text{bal}}L_{\text{IPM}}
$$

当前以 cumulative head 编码“补贴越大理论上响应不应更差”的单调先验：

$$
\hat\mu_{82}(X)\geq \hat\mu_{85}(X)\geq \dots\geq \hat\mu_{100}(X)
$$

### 2. 原 CFR 的训练目标是什么？它与最终想优化的“增量排序/策略收益”具体哪里不一致？
原 CFR 的问题是：它优化的是各 treatment 下响应概率的拟合质量，但业务最终关心的是 uplift 排序。例如两个用户的绝对发单率都可能很高，但其中一个即使不给补贴也会发单，真实增量很低；另一个绝对概率一般，但补贴带来的增量很大。只优化 Factual BCE 和 AUC，无法保证 uplift 排序正确。

### 3.你如何用 K 折交叉拟合构造 OOF-DR 伪标签？请写出二元 treatment 时的 DR 公式，并说明多档 treatment 如何扩展。
为此，我会基于交叉拟合构造 OOF-DR 伪标签。以二元 treatment 为例，令：

- $\hat e(X)=P(T=1\mid X)$：倾向得分模型；
- $\hat\mu_1(X),\hat\mu_0(X)$：结果模型；
- $T\in\{0,1\}$。

DR uplift 标签为：

$$
\hat\tau_{\text{DR}}(X)
=
\hat\mu_1(X)-\hat\mu_0(X)
+
\frac{\mathbb{I}(T=1)}{\hat e(X)}(Y-\hat\mu_1(X))
-
\frac{\mathbb{I}(T=0)}{1-\hat e(X)}(Y-\hat\mu_0(X))
$$

多 treatment 下，将每个折扣档位 $a$ 相对 100 档分别构造：

$$
\hat\tau_{a,100}(X)
=
\hat\mu_a(X)-\hat\mu_{100}(X)
+
\frac{\mathbb{I}(T=a)}{\hat e_a(X)}(Y-\hat\mu_a(X))
-
\frac{\mathbb{I}(T=100)}{\hat e_{100}(X)}(Y-\hat\mu_{100}(X))
$$

### 4.倾向模型和结果模型分别学什么？为什么必须 OOF，若用同一份训练集预测伪标签会有什么问题？
如果数据来自严格随机实验，倾向得分可直接使用已知分流概率；如果是观察性数据，则需要用 propensity model 估计。

必须做 OOF 的原因是避免“自己给自己打分”。如果同一条样本既用于训练 nuisance model，又用该模型产生伪标签，模型可能记住该样本，残差被压低，DR 标签过于乐观，后续排序损失会学习到泄漏后的假信号。K 折交叉拟合中，每一折样本的 $\hat e,\hat\mu$ 都由未见过该折的数据训练得到。

拿到 OOF-DR uplift 后，我会把优化目标从单纯的 response fitting 扩展为“概率拟合 + 增量排序”。

### 5.全局 Rank Loss 和局部 Pairwise Loss 的 label、样本对构造、优化目标分别是什么？为什么两者要同时存在？
全局 Rank Loss 的作用是保证大范围人群排序方向正确。可以按 DR uplift 构造样本对：

$$
L_{\text{global}}
=
\sum_{i,j}
w_{ij}
\log\left(1+\exp\left[-\operatorname{sign}(\hat\tau_i-\hat\tau_j)
(s_i-s_j)\right]\right)
$$

其中 $s_i$ 是模型预测 uplift，$w_{ij}$ 可以随 uplift 差距增大而增大。它解决的是整体 Top 人群是否排对。

局部 Pairwise Loss 则只关注 uplift 接近、容易错序、且策略边界附近的样本对。因为真正影响策略的是“该给谁补、不给谁补”的临界比较。局部 loss 可以按相近城市、时段、成本区间或 uplift 差距筛选样本对，减少跨度过大样本带来的粗糙监督。

最终损失可以写作：

$$
L =
L_{\text{factual}}
+\lambda_{\text{rank}}L_{\text{global}}
+\lambda_{\text{pair}}L_{\text{local}}
+\lambda_{\text{bal}}L_{\text{IPM}}
+\lambda_{\text{mono}}L_{\text{mono}}
$$
### 6.TwoStage 为什么第一阶段学 factual response，第二阶段冻结 embedding、微调 shared layer/head？这解决了什么梯度冲突？
这里存在梯度冲突：Factual BCE 希望所有 head 尽可能拟合观测概率；Rank Loss 更关注 treatment 差分的相对顺序。直接一起强训时，shared representation 和 embedding 容易在两个目标之间拉扯，造成概率与排序都不稳定。


所以使用 TwoStage：

- 第一阶段只训练 Factual/轻量平衡约束，得到稳定的多 treatment response 表示；
- 第二阶段冻结 embedding，避免基础离散特征表示被噪声较大的排序梯度破坏；
- 微调 shared layer 和重点 treatment head，让模型在已有稳定 response 基础上改善 uplift 排序；
- 对长尾、高方差 DR 标签先做 Z-score，再用温度 Tanh 压缩极端值，减少少数异常样本主导 pairwise 梯度。

你会如何证明 Call AUCC 提升 15% 不是数据泄漏、离线偶然性或人群分布变化造成的？
最后，Call AUCC 提升不能只看一个离线数。我要验证：

1. 严格按时间、用户或实验桶切分，确保训练和验证不存在用户泄漏、未来特征泄漏。
2. OOF 伪标签必须由样本外 nuisance prediction 构造。
3. 比较各档位、城市、时段、人群的 uplift/QINI/AUCC，确认不是少数大盘人群驱动。
4. 检查 treatment 覆盖、倾向得分重叠和极端 IPW 权重；必要时截断权重。
5. 与仅 Factual CFR、仅 Rank、无交叉拟合、无 TwoStage 等版本做消融。
6. 验证 Top-K 人群的真实实验增量、成本、ROI，而不只看模型离线分数。
7. 上线前做小流量随机实验，观察增量、补贴率、预算消耗和长期副作用是否与离线方向一致。

一句话总结：原 CFR 解决“各补贴档位下会不会转化”，而这套改造解决“有限补贴应该优先给谁，才能产生最大的真实增量”。
