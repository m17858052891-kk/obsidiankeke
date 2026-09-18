论文：[Decision Focused Causal Learning for Direct Counterfactual Marketing Optimization](https://arxiv.org/abs/2407.13664)

会议：KDD 2024

DOI：[10.1145/3637528.3672353](https://doi.org/10.1145/3637528.3672353)

## 1. 前置信息：总览、摘要与引言

### 1.1 一句话总览

DFCL 不只训练模型预测每个人在各个 treatment 下的收益和成本，还把这些预测送入预算分配器，用最终资源分配质量反向训练预测模型。

### 1.2 业务背景与核心矛盾

营销优惠、补贴和动态定价都会消耗预算。平台不仅要判断“谁更可能转化”，还要在一批候选个体中同时决定：给谁、给哪一档 treatment，以及如何使整批成本不超预算。

传统两阶段链路是：

```text
因果结果模型预测收益/成本
→ 多选背包或其他资源分配器
→ 输出每个人的 treatment
```

问题是，MSE 或 Logloss 关心所有样本的平均预测误差，优化器却关心预算边界附近的相对排序和最终动作。因此，**预测指标更好，不必然意味着被分配器选出的动作更好**。

### 1.3 营销场景的三个难点

1. **约束不确定：**个体在不同 treatment 下的成本需要预测，现实预算也会波动，不能只为单一预算点训练。
2. **反事实缺失：**每个人只会接受一种 treatment，无法同时观察其他 treatment 下的真实收益和成本。
3. **大规模组合优化不可导：**下游是含离散选择和 $\arg\max$ 的多选背包问题，不能直接向预测网络反向传播。

### 1.4 论文的解决思路与贡献

- 用拉格朗日对偶将全局预算约束转成影子价格 $\lambda$，并利用预算 $B$ 与 $\lambda$ 的对应关系覆盖多个预算区间。
- 基于 RCT 的随机 treatment 分配，构造可用事实结果计算的预测损失与决策损失替代量。
- 提出 Policy Learning Loss、Maximum Entropy Regularized Loss 和 Improved Finite-Difference 三条梯度路径，并用对偶分解将训练扩展到数千万级数据。
- 在 CRITEO-UPLIFT v2、美团营销 RCT 数据和四周线上 A/B 测试中验证最终决策收益。

**直观理解：**DFCL 不是一个独立的“出价模型”，也不只输出一个最佳 treatment。它的可学习部分先输出每个人、每个档位的预测收益和成本；下游分配器再在预算约束下输出最终档位。DFCL 把分配器纳入训练目标，但分配器本身仍然是优化模块。

## 2. Related Work：相关工作

### 2.1 营销中的两阶段方法

两阶段方法先用 S-Learner、Causal Forest、表示学习或 uplift 模型预测不同 treatment 下的结果，再用贪心或拉格朗日对偶求解资源分配。它们的预测损失与下游决策目标分离。

### 2.2 Decision-Focused Learning

Decision-Focused Learning 通常按 `predict → optimize → evaluate → update` 训练：优化器用模型预测做决策，再用真实决策质量更新预测器。已有方法通过解析求导、平滑替代损失或黑盒扰动估计优化层梯度，但营销场景还同时存在反事实缺失、多预算与百万级离散求解问题。

### 2.3 Direct Resource/Policy Optimization

DRP 在二元 treatment 下直接学习 ROI 排序；DPM 将该思路扩展到多 treatment，但依赖边际效用递减等假设。DFCL 不只学一个固定 decision factor，而是保留收益、成本结果面，并用任意预算下的分配质量训练它们。

## 3. Problem Formulation：问题定义

### 3.1 变量与业务对应

- $i\in\{1,\ldots,N\}$：用户、商家或一次营销机会。
- $j\in\{1,\ldots,M\}$：treatment 档位，如不干预、5%、10%、15%、20% 折扣。
- $r_{ij}$：个体 $i$ 接受 treatment $j$ 后的潜在收益。
- $c_{ij}$：对应潜在成本。
- $z_{ij}\in\{0,1\}$：是否将 treatment $j$ 分配给个体 $i$。
- $B$：整批分配可用的预算。

### 3.2 多 treatment 预算分配问题

若完整结果面 $r,c$ 已知，营销分配可写成多选背包问题（MTBAP/MCKP）：

$$
\begin{aligned}
\max_z\quad F(z,B)&=\sum_i\sum_jz_{ij}r_{ij},\\
\text{s.t.}\quad
&\sum_i\sum_jz_{ij}c_{ij}\le B,\\
&\sum_jz_{ij}=1,\quad\forall i,\\
&z_{ij}\in\{0,1\},\quad\forall i,j.
\end{aligned}
\qquad \text{(1)}
$$

每个人必须选一个 treatment，通常将“不干预”也作为成本为 0 的档位；全体成本不能超过 $B$。

### 3.3 组合优化的近似解与预测问题

MCKP 是 NP-hard 问题。贪心法和拉格朗日对偶都可得到近似比：

$$
\rho=1-\frac{\max_{i,j}r_{ij}}{\mathrm{OPT}}.
$$

在大规模营销中，$\mathrm{OPT}$ 是数百万个体的总收益，单个体的最大收益相对很小，因而 $\rho\approx1$。真正的难点不是已知 $r,c$ 后怎样求解，而是在决策前 $r,c$ 未知，只能使用 $\hat r,\hat c$。传统两阶段方法优化预测误差，但该方向可能与优化决策质量的方向不一致。

**口径说明：**论文的 $r_{ij}$ 是 treatment $j$ 下的 outcome，不自动等于 uplift。如果业务目标是最大化相对不干预的增量，需要先定义 $\Delta r_{ij}=r_{ij}-r_{i0}$ 与 $\Delta c_{ij}=c_{ij}-c_{i0}$，并在训练、优化和评估中保持同一口径。

## 4. Learning Framework of DFCL：学习框架

总损失由预测损失和决策损失组成：

$$
\mathcal L_{\mathrm{DFCL}}
=\alpha\mathcal L_{\mathrm{PL}}+\mathcal L_{\mathrm{DL}}.
$$

$\mathcal L_{\mathrm{PL}}$ 保持结果面预测的精度和泛化；$\mathcal L_{\mathrm{DL}}$ 直接衡量下游营销分配质量；$\alpha$ 调节两者的权衡。

### 4.1 Prediction Loss：预测损失

如果每个人的所有 treatment 结果都可见，完整结果面 MSE 为：

$$
\mathcal L_{\mathrm{MSE}}(r,c,\hat r,\hat c)
=\frac{1}{NM}\sum_i\sum_j
\left[(r_{ij}-\hat r_{ij})^2+(c_{ij}-\hat c_{ij})^2\right].
\qquad \text{(2)}
$$

但对个体 $i$，现实中只能观察它实际接受的 treatment $t_i$ 下的 $r_{i,t_i},c_{i,t_i}$，这是因果推断的根本问题。论文使用大小为 $N$ 的 RCT 数据：

$$
\mathcal D=\{(x_i,t_i,r_{i,t_i},c_{i,t_i})\}_{i=1}^{N},
$$

并以 $N_j$ 表示实际分到 treatment $j$ 的样本数。可计算的事实预测损失为：

$$
\mathcal L_{\mathrm{PL}}(r,c,\hat r,\hat c)
=\frac{1}{M}\sum_i\frac{1}{N_{t_i}}
\left[(r_{i,t_i}-\hat r_{i,t_i})^2
+(c_{i,t_i}-\hat c_{i,t_i})^2\right].
\qquad \text{(3)}
$$

在 RCT 的 $T\perp X$ 假设下，论文的 Theorem 1 给出：

$$
\mathcal L_{\mathrm{PL}}=\mathcal L_{\mathrm{MSE}}.
$$

**直观理解：**$1/N_{t_i}$ 不是在为单个人虚构反事实，而是先在每个随机 treatment 组内求平均，再对各组求平均。RCT 使这个事实结果平均在总体上等价于完整潜在结果面的 MSE。

### 4.2 Decision Loss：决策损失

决策时用预测结果面替代未知的真实结果面：

$$
z^*(B,\hat r,\hat c)
=\arg\max_zF(z,B,\hat r,\hat c).
$$

不改变这套由预测驱动的动作，再用真实收益结算其决策价值：

$$
\sum_i\sum_j r_{ij}z^*_{ij}(B,\hat r,\hat c).
$$

固定预算 $B$ 下的决策损失定义为价值的负数：

$$
\mathcal L_{\mathrm{DL}}(B,r,c,\hat r,\hat c)
=-\sum_i\sum_jr_{ij}z^*_{ij}(B,\hat r,\hat c).
$$

由于真实业务预算波动较大，论文不只优化一个预算点，而定义任意预算下的决策损失：

$$
\begin{aligned}
\mathcal L_{\mathrm{DL}}(r,c,\hat r,\hat c)
&=\int_0^\infty\mathcal L_{\mathrm{DL}}(B,r,c,\hat r,\hat c)\,dB\\
&=-\int_0^\infty\sum_i\sum_j
r_{ij}z^*_{ij}(B,\hat r,\hat c)\,dB.
\end{aligned}
$$

实际计算时将预算离散化：

$$
\mathcal L_{\mathrm{DL}}(r,c,\hat r,\hat c)
=\sum_B\mathcal L_{\mathrm{DL}}(B,r,c,\hat r,\hat c).
$$

这个理想损失不能直接训练：它既需要不可见的完整反事实 $r,c$，又含有离散、不可导的分配器。

### 4.3 Learning Framework：整体训练闭环

<p align="center"><img src="DFCL Algorithm 1.png" alt="Algorithm 1：Decision Focused Causal Learning" width="760"></p>

Algorithm 1 的原始逻辑是：模型输出 $\hat r,\hat c$，用 RCT 事实列计算 $\mathcal L_{\mathrm{PL}}$，对多个预算 $B$ 求解 $z^*$ 并计算 $\mathcal L_{\mathrm{DL}}$，最后以组合损失更新模型参数 $\omega$。其最关键、也最困难的一步是估计 $\partial\mathcal L_{\mathrm{DFCL}}/\partial\omega$。

**直观理解：**预测损失像“安全带”，防止结果面为迎合某些决策边界而整体漂移；决策损失则将学习重点放在真正会改变 treatment 和预算分配的误差上。

## 5. Gradient Estimation of DFCL：梯度估计

### 5.1 Dual Decision Loss：对偶决策损失

预测损失可直接自动求导，本节的焦点是决策损失。对预算约束引入非负拉格朗日乘子 $\lambda$，可得原问题的对偶问题：

$$
\begin{aligned}
&\min_{\lambda\ge0}
\left(
\max_z\ \lambda B+\sum_i\sum_j(r_{ij}-\lambda c_{ij})z_{ij}
\right)\\
&\text{s.t.}\quad\sum_jz_{ij}=1,\quad
z_{ij}\in\{0,1\}\\
&=\min_{\lambda\ge0}\max_zH(z,\lambda,B,r,c)\\
&=\min_{\lambda\ge0}G(\lambda,B,r,c).
\end{aligned}
\qquad \text{(7)}
$$

可用梯度下降或二分搜索求 $\lambda^*$，终止条件可为：

$$
B-\sum_i\sum_jc_{ij}z_{ij}\le\epsilon
\quad\text{or}\quad\lambda\le\epsilon.
$$

记原始整数问题、连续松弛问题和对偶问题的最优解分别为 $z^*$、$z_c^*$ 和 $\lambda^*$，固定 $\lambda^*$ 得到的对偶分解解为：

$$
z^d(\lambda^*,B,r,c)
=\arg\max_zH(z,\lambda^*,B,r,c).
$$

论文的对偶定理给出：$\lambda^*$ 随预算 $B$ 增大而单调减小，并且

$$
\begin{aligned}
F(z^d,B,r,c)
&\le F(z^*,B,r,c)\\
&\le F_c(z_c^*,B,r,c)\\
&=G(\lambda^*,B,r,c)\\
&\le F(z^d,B,r,c)+\max_{i,j}r_{ij}.
\end{aligned}
$$

因此：

$$
\begin{aligned}
\rho
=\frac{F(z^d,B,r,c)}{F(z^*,B,r,c)}
&\ge1-\frac{\max_{i,j}r_{ij}}{F(z^*,B,r,c)}\\
&\approx1.
\end{aligned}
$$

决策时使用预测结果面：

$$
z^d(\lambda,\hat r,\hat c)
=\arg\max_zH(z,\lambda,\hat r,\hat c).
$$

在不影响动作的情况下去掉与预测无关的常数 $\lambda B$，一个 $\lambda$ 下的对偶决策损失为：

$$
\mathcal L_{\mathrm{DDL}}(\lambda,r,c,\hat r,\hat c)
=-\sum_i\sum_j(r_{ij}-\lambda c_{ij})
z^d_{ij}(\lambda,\hat r,\hat c).
$$

由于 $B$ 与 $\lambda^*$ 存在单调对应，任意预算下的目标可改写为任意 $\lambda$ 下的对偶决策损失：

$$
\begin{aligned}
\mathcal L_{\mathrm{DDL}}(r,c,\hat r,\hat c)
&=-\int_0^\infty\sum_i\sum_j(r_{ij}-\lambda c_{ij})
z^d_{ij}(\lambda,\hat r,\hat c)\,d\lambda\\
&\approx\sum_\lambda
\mathcal L_{\mathrm{DDL}}(\lambda,r,c,\hat r,\hat c).
\end{aligned}
$$

**直观理解：**$\lambda$ 是成本的影子价格。预算越紧，$\lambda$ 越大，高成本 treatment 的分数 $r-\lambda c$ 被压得越多。对偶变换的两个实际作用是：用多个 $\lambda$ 覆盖多个预算区间，并使固定 $\lambda$ 后的决策可按个体分解。

### 5.2 Policy Learning Loss：策略学习损失

固定 $\lambda$ 后，对偶内层可分解为：

$$
\max_zH(z,\lambda,\hat r,\hat c)
=\sum_i\max_j(\hat r_{ij}-\lambda\hat c_{ij}),
$$

因此硬决策为：

$$
z^d_{ij}(\lambda,\hat r,\hat c)
=\mathbb I\!\left[
j=\arg\max_k(\hat r_{ik}-\lambda\hat c_{ik})
\right].
$$

直接代入对偶损失得：

$$
\mathcal L_{\mathrm{DDL}}
=-\sum_\lambda\sum_i\sum_j
(r_{ij}-\lambda c_{ij})
\mathbb I\!\left[j=\arg\max_k(\hat r_{ik}-\lambda\hat c_{ik})\right].
$$

为避开不可导的指示函数，论文使用 softmax 平滑：

$$
\mathcal L'_{\mathrm{DDL}}(r,c,\hat r,\hat c)
=-\sum_\lambda\sum_i\sum_j
(r_{ij}-\lambda c_{ij})
\frac{\exp(\hat r_{ij}-\lambda\hat c_{ij})}
{\sum_k\exp(\hat r_{ik}-\lambda\hat c_{ik})}.
\qquad \text{(8)}
$$

定义软策略：

$$
p_{ij}(\lambda,\hat r,\hat c)
=\frac{\exp(\hat r_{ij}-\lambda\hat c_{ij})}
{\sum_k\exp(\hat r_{ik}-\lambda\hat c_{ik})}.
$$

由于完整 $r,c$ 不可见，论文使用 RCT 事实 treatment 和逆概率权重构造可计算的 Policy Learning Loss：

$$
\mathcal L_{\mathrm{PLL}}
=-\sum_\lambda\sum_i\frac{N}{N_{t_i}}
(r_{i,t_i}-\lambda c_{i,t_i})
\frac{\exp(\hat r_{i,t_i}-\lambda\hat c_{i,t_i})}
{\sum_j\exp(\hat r_{ij}-\lambda\hat c_{ij})}.
$$

论文的等价性结论为：

$$
\mathcal L_{\mathrm{PLL}}=\mathcal L'_{\mathrm{DDL}},
$$

$$
\min_{\hat r,\hat c}\mathcal L_{\mathrm{PLL}}
=\min_{\hat r,\hat c}\mathcal L_{\mathrm{DDL}}.
$$

**直观理解：**某个 RCT 样本真实拿到的 treatment 如果产生了较高的 $r-\lambda c$，损失就鼓励模型提高该 treatment 的软策略概率。$N/N_{t_i}$ 用于校正各 treatment 组样本量不同，并不代表观察到了该个体的其他反事实。

### 5.3 Maximum Entropy Regularized Loss：最大熵正则损失

为得到关于 $\hat r,\hat c$ 可导的闭式决策，论文将 $z\in\{0,1\}$ 松弛为 $z\in[0,1]$，并在对偶目标中加入最大熵正则：

$$
\begin{aligned}
\max_z\quad
&\sum_i\sum_j(\hat r_{ij}-\lambda\hat c_{ij})z_{ij}
-\tau\sum_i\sum_jz_{ij}\ln z_{ij},\\
\text{s.t.}\quad
&\sum_jz_{ij}=1,\quad z_{ij}\in[0,1].
\end{aligned}
$$

对等式约束引入对偶变量 $\beta_i$，拉格朗日函数为：

$$
\begin{aligned}
L(z,\beta)
=&\sum_i\sum_j(r_{ij}-\lambda c_{ij})z_{ij}
-\tau\sum_i\sum_jz_{ij}\ln z_{ij}\\
&-\sum_i\beta_i\left(1-\sum_jz_{ij}\right).
\end{aligned}
$$

令 $\partial L/\partial z=0$ 与 $\partial L/\partial\beta=0$，得到带温度的 softmax 闭式解：

$$
z^d_{ij}
=\frac{\exp[(\hat r_{ij}-\lambda\hat c_{ij})/\tau]}
{\sum_k\exp[(\hat r_{ik}-\lambda\hat c_{ik})/\tau]}.
$$

平滑后的对偶决策损失为：

$$
\mathcal L''_{\mathrm{DDL}}
=-\sum_\lambda\sum_i\sum_j(r_{ij}-\lambda c_{ij})
\frac{\exp[(\hat r_{ij}-\lambda\hat c_{ij})/\tau]}
{\sum_k\exp[(\hat r_{ik}-\lambda\hat c_{ik})/\tau]}.
$$

用 RCT 事实结果替代不可见的全结果面，得到：

$$
\mathcal L_{\mathrm{MERL}}
=-\sum_\lambda\sum_i\frac{N}{N_{t_i}}
(r_{i,t_i}-\lambda c_{i,t_i})
\frac{\exp[(\hat r_{i,t_i}-\lambda\hat c_{i,t_i})/\tau]}
{\sum_j\exp[(\hat r_{ij}-\lambda\hat c_{ij})/\tau]}.
$$

$\mathcal L_{\mathrm{PLL}}$ 是 $\tau=1$ 时的特例。$\tau$ 较大时策略更平滑；$\tau\to0$ 时更接近硬 $\arg\max$，但优化也更容易饱和。

### 5.4 Improved Finite-Difference Strategy：改进有限差分

#### 5.4.1 EOM 离线策略评估

给定 RCT 数据和任意分配策略，只使用“日志实际 treatment 等于策略建议 treatment”的样本，并用 treatment 概率 $p_{t_i}$ 做逆概率加权：

$$
\bar r(r,c,\hat r,\hat c)
=\frac1N\sum_i\frac{1}{p_{t_i}}r_{i,t_i}
\mathbb I\!\left[t_i=\arg\max_jz_{ij}\right],
$$

$$
\bar c(r,c,\hat r,\hat c)
=\frac1N\sum_i\frac{1}{p_{t_i}}c_{i,t_i}
\mathbb I\!\left[t_i=\arg\max_jz_{ij}\right].
$$

对原始 MCKP，可以二分搜索 $\lambda$ 使人均成本接近 $B/N$，并使用 $\bar r$ 估计该预算下的策略价值。于是决策损失可写为：

$$
\mathcal L_{\mathrm{DL}}(r,c,\hat r,\hat c)
=-\sum_B\bar r(B,r,c,\hat r,\hat c).
$$

#### 5.4.2 朴素有限差分

将整个“预测→分配→EOM评估”视为黑盒，对单个预测位置施加小扰动 $h$：

$$
\frac{\partial\mathcal L_{\mathrm{DL}}}{\partial\hat r_{ij}}
\approx
\frac{
\mathcal L_{\mathrm{DL}}(\hat r+h e^{ij},\hat c)
-\mathcal L_{\mathrm{DL}}(\hat r,\hat c)}{h}.
$$

$e^{ij}$ 只在第 $(i,j)$ 个位置为 1。$\partial\mathcal L_{\mathrm{DL}}/\partial\hat c_{ij}$ 同理。将估计的梯度组装成可自动反传的线性代理损失：

$$
\mathcal L_{\mathrm{FDL}}
=\sum_i\sum_j
\left(
\frac{\partial\mathcal L_{\mathrm{DL}}}{\partial\hat r_{ij}}\hat r_{ij}
+\frac{\partial\mathcal L_{\mathrm{DL}}}{\partial\hat c_{ij}}\hat c_{ij}
\right).
$$

朴素做法对每个 $i,j$ 都要重新求解和评估一次，在百万级数据上代价过高。

#### 5.4.3 Improved Finite Difference

对偶分解后，固定 $\lambda$ 的决策在个体之间独立。论文因而改用对偶 EOM 目标：

$$
\mathcal L_{\mathrm{DDL}}
=-\sum_\lambda
\left[
\bar r(\lambda,r,c,\hat r,\hat c)
-\lambda\bar c(\lambda,r,c,\hat r,\hat c)
\right].
$$

对每个样本，只计算足以使当前 treatment 发生切换的最小分数扰动，再局部更新 $\bar r,\bar c$，无需重新求解整批 MCKP。其代理损失为：

$$
\mathcal L_{\mathrm{IFDL}}
=\sum_i\sum_j
\left(
\frac{\partial\mathcal L_{\mathrm{DDL}}}{\partial\hat r_{ij}}\hat r_{ij}
+\frac{\partial\mathcal L_{\mathrm{DDL}}}{\partial\hat c_{ij}}\hat c_{ij}
\right).
$$

为提高数值稳定性，论文还截断扰动矩阵，并可在动作分数上使用 softmax：

$$
\mathcal L_{\mathrm{IFDL\text{-}Softmax}}
=\sum_i\sum_j
\frac{\partial\mathcal L_{\mathrm{DDL}}}{\partial a_{ij}}a_{ij},
\qquad
a_{ij}=\operatorname{Softmax}(\hat r_{ij}-\lambda\hat c_{ij}).
$$

**直观理解：**PL/MER 先把硬动作变成软概率；IFD 则保留硬决策器，直接问“要把某个档位推过当前决策边界，最小需要改多少预测；切换后的真实净收益会变好还是变差”。

## 6. Evaluation：实验

### 6.1 Offline Experiment：离线实验

#### 6.1.1 Dataset

- **CRITEO-UPLIFT v2：**1390 万条 RCT 样本，12 个特征、一个二元 treatment、visit/conversion 两个标签。论文按相关工作将 visit 作为成本、conversion 作为收益，70% 训练、30% 测试。
- **Marketing data：**美团外卖平台两周 RCT，第一周训练、第二周测试。280 万样本、107 个特征；treatment 为 $\{0,5,10,15,20\}$ 折扣档，结果为每日成本与订单数。

#### 6.1.2 Evaluation Metrics

- **Logloss/MSE：**普通预测精度。
- **AUCC（Area under Cost Curve）：**用于二元 treatment 下的 ROI/增量排序评估。
- **EOM（Expected Outcome Metric）：**基于 RCT 对任意分配策略的人均收益与成本做逆概率加权估计。

#### 6.1.3 Benchmarks

- **TSM-SL：**S-Learner 预测收益/成本，再求解 MCKP。
- **TSM-CF：**使用 Causal Forest 预测增量结果的两阶段基线。
- **DPM：**直接学习 MCKP decision factor 的方法。
- **CN：**对 treatment 与 outcome 预测加单调约束的多 treatment 模型。
- **CN+DFCL-PL：**使用预测损失与 PLL 训练 CN。
- **DFCL-PL / DFCL-MER / DFCL-IFD：**分别使用三种决策梯度路径。

#### 6.1.4 Implementation Details

- CRITEO 上：共享层是 128 维单层 MLP，四个 head 为 `[64, 1]` 两层 MLP；DFCL-MER 使用 $\tau=3$；Adam 训练 40 epoch，前 20 epoch 用交叉熵 warm-start。
- Marketing data 上：六类神经网络基线共用 `64-32-32-10` MLP，前 5 个输出是收益、后 5 个是成本；DFCL-MER 使用 $\tau=0.01$；训练 500 epoch。
- 硬件：AMD EPYC 7502P 32 核 2.50GHz，64GB 内存。

### 6.2 Experimental Results：离线结果

#### 6.2.1 Overall Performance

**Table 1：普通预测指标**

<p align="center"><img src="DFCL Table 1.png" alt="Table 1：Logloss 与 MSE" width="760"></p>

TSM-SL 在普通预测指标上最好：CRITEO Logloss 为 $0.2165\pm0.0001$，Marketing MSE 为 $0.2625\pm0.0009$。DFCL 的预测误差略高，因为它还在为决策边界分配模型容量。

**Table 2 与 Figure 1(a)：CRITEO AUCC**

<p align="center"><img src="DFCL Table 2.png" alt="Table 2：CRITEO AUCC" width="760"></p>

<p align="center"><img src="DFCL Figure 1a AUCC.png" alt="Figure 1(a)：AUCC" width="760"></p>

DFCL-IFD 的 AUCC 为 $0.7859\pm0.0021$，相对 TSM-SL 提升 $3.94\%$，是该数据集上的最优结果。DFCL-PL 和 DFCL-MER 与 DPM 接近，均好于两阶段基线。

**Table 3 与 Figure 1(b)：Marketing EOM**

<p align="center"><img src="DFCL Table 3.png" alt="Table 3：多预算 EOM" width="900"></p>

<p align="center"><img src="DFCL Figure 1b EOM.png" alt="Figure 1(b)：EOM" width="760"></p>

DFCL-IFD 在 1–6 的全部预算点上都取得最高 EOM，整体相对 TSM-SL 提升 $2.85\%$；DFCL-MER 和 DFCL-PL 分别提升 $2.06\%$ 和 $1.98\%$。CN+DFCL-PL 明显好于 CN，说明 DFCL 损失可以接入已有的结果模型。

**核心实验矛盾：**Table 1 中两阶段模型的预测指标最好，但 Table 2、Table 3 中 DFCL 的分配价值更高。这正是论文要验证的“预测误差与决策质量不等价”。

#### 6.2.2 Prediction Loss vs Decision Loss Trade-off

论文设置 $\alpha\in\{0.1,0.5,1,2,3,4,5,10\}$。在一定范围内增大 $\alpha$ 不会明显降低决策收益；$\alpha$ 过大时，预测损失主导训练，模型逐渐退化为两阶段方法。

<p align="center"><img src="DFCL Figure 2a Alpha.png" alt="Figure 2(a)：预测损失权重 alpha" width="760"></p>

#### 6.2.3 Impact of Lagrange Multiplier

论文比较 $\{0.1\}$、$\{0.1,0.5\}$ 和 $\{0.1,0.5,1.0\}$ 三组 $\lambda$。小 $\lambda$ 更容易学习高预算区域，大 $\lambda$ 更偏向低预算、强成本惩罚区域；使用多个 $\lambda$ 训练可平衡不同预算下的表现。

<p align="center"><img src="DFCL Figure 2b Lambda.png" alt="Figure 2(b)：Lagrange multiplier 的影响" width="760"></p>

### 6.3 Online A/B Testing：线上实验

#### 6.3.1 Setups

论文在美团折扣营销场景对 DFCL、DPM 和 TSM-SL 进行四周 A/B 测试。每天约 31 万家商户随机分到 G-DFCL、G-DPM 和 G-TSL，每家商户选择 $\{0,5,10,15,20\}$ 中的一个折扣档，目标是在有限预算下最大化订单数。

部署链路是：每天活动开始前，DFCL 预测各商户在不同折扣档下的收益和成本，再根据当天预算与其他约束离线分配折扣；用户在线产生反馈；历史随机数据和分配器继续用于后续模型更新。

<p align="center"><img src="DFCL Figure 3a Deployment.png" alt="Figure 3(a)：DFCL 线上部署" width="760"></p>

#### 6.3.2 Results

所有数值均除以 G-TSL 第一周订单数做归一化。G-DPM 相对 G-TSL 平均提升 $1.32\%$；G-DFCL 相对 G-TSL 提升 $2.17\%$，相对 G-DPM 再提升约 $0.85\%$。

<p align="center"><img src="DFCL Figure 3b Online AB.png" alt="Figure 3(b)：四周线上订单" width="760"></p>

## 7. Conclusion：结论

DFCL 将营销模型的学习目标从“尽量预测准收益和成本”扩展为“让预测经过资源分配器后得到更好的真实决策”。它通过拉格朗日对偶处理预算波动与大规模求解，用 RCT 加权处理反事实缺失，再通过 PL、MER 或 IFD 将决策质量变成可训练信号。

论文结果表明，最小化预测误差的两阶段模型在 MSE/Logloss 上更好，但 DFCL 在 AUCC、多预算 EOM 和线上订单上更好。这支持了“预测精度不等于决策质量”的核心主张。

## Appendix A：Theorem 1 的证明

记 $Y^r(T),Y^c(T)$ 为 treatment $T$ 下的收益和成本潜在结果，$\widehat Y^r(T),\widehat Y^c(T)$ 为对应预测。完整 MSE 可写为：

$$
\begin{aligned}
\mathcal L_{\mathrm{MSE}}
&=\frac1{NM}\sum_i\sum_j
\left[(r_{ij}-\hat r_{ij})^2+(c_{ij}-\hat c_{ij})^2\right]\\
&=\mathbb E_{X,T}\left[
(Y^r(T)-\widehat Y^r(T))^2
+(Y^c(T)-\widehat Y^c(T))^2
\right].
\end{aligned}
$$

事实预测损失的推导链为：

$$
\begin{aligned}
\mathcal L_{\mathrm{PL}}
&=\frac1M\sum_j\frac1{N_j}
\sum_{i:t_i=j}
\left[(r_{i,t_i}-\hat r_{i,t_i})^2
+(c_{i,t_i}-\hat c_{i,t_i})^2\right]\\
&=\frac1M\sum_j\mathbb E_X\left[
(Y^r(j)-\widehat Y^r(j))^2
+(Y^c(j)-\widehat Y^c(j))^2\mid T=j
\right]\\
&=\frac1M\sum_j\mathbb E_X\left[
(Y^r(j)-\widehat Y^r(j))^2
+(Y^c(j)-\widehat Y^c(j))^2
\right]\\
&=\mathbb E_{X,T}\left[
(Y^r(T)-\widehat Y^r(T))^2
+(Y^c(T)-\widehat Y^c(T))^2
\right]\\
&=\mathcal L_{\mathrm{MSE}}.
\end{aligned}
$$

第三行使用了 RCT 的 $T\perp X$。

## Appendix B：Policy Learning Loss 等价性证明

先记：

$$
\operatorname{softmax}(\hat r_{ij}-\lambda\hat c_{ij})
=\frac{\exp(\hat r_{ij}-\lambda\hat c_{ij})}
{\sum_k\exp(\hat r_{ik}-\lambda\hat c_{ik})}.
$$

平滑对偶损失可写成潜在结果期望：

$$
\begin{aligned}
\mathcal L'_{\mathrm{DDL}}
&=-\sum_\lambda\sum_i\sum_j
(r_{ij}-\lambda c_{ij})
\operatorname{softmax}(\hat r_{ij}-\lambda\hat c_{ij})\\
&=-NM\sum_\lambda\mathbb E_{X,T}
\left[
(Y^r(T)-\lambda Y^c(T))
\operatorname{softmax}(\widehat Y^r(T)-\lambda\widehat Y^c(T))
\right].
\end{aligned}
$$

对 $\mathcal L_{\mathrm{PLL}}$ 按 treatment 组重排，再使用 $T\perp X$，可得完全相同的期望：

$$
\mathcal L_{\mathrm{PLL}}=\mathcal L'_{\mathrm{DDL}}.
$$

当真实净收益最大的 treatment 对应预测分数趋近 $+\infty$，其他分数趋近 $-\infty$ 时：

$$
\operatorname{softmax}(\hat r_{ij}-\lambda\hat c_{ij})
\longrightarrow
\mathbb I\!\left[j=\arg\max_k(\hat r_{ik}-\lambda\hat c_{ik})\right].
$$

因此：

$$
\min_{\hat r,\hat c}\mathcal L_{\mathrm{PLL}}
=\min_{\hat r,\hat c}\mathcal L'_{\mathrm{DDL}}
=\min_{\hat r,\hat c}\mathcal L_{\mathrm{DDL}}.
$$

## Appendix C：Policy Evaluation Based on EOM

给定 RCT 样本、预测结果面和预算 $B$，Algorithm 3 用二分搜索找到使 EOM 人均成本接近 $B/N$ 的 $\lambda$，并返回该预算下的人均收益。

<p align="center"><img src="DFCL Algorithm 3.png" alt="Algorithm 3：原始 MCKP 的人均收益估计" width="760"></p>

**直观理解：**算法不是用预测收益评价预测策略，而是先用预测选动作，再用与该动作一致的 RCT 事实结果做逆概率加权结算。

## Appendix D：Lagrangian Duality Gradient Estimator

Algorithm 2 先计算 $a=\hat r-\lambda\hat c$ 和当前硬动作，再将样本分成“策略动作与 RCT 事实 treatment 一致”和“不一致”两类。对每类样本，它计算使动作跨过当前 $\arg\max$ 边界所需的最小收益/成本扰动，再构造对 $\hat r,\hat c$ 的梯度。

<p align="center"><img src="DFCL Algorithm 2.png" alt="Algorithm 2：拉格朗日对偶梯度估计器" width="620"></p>

论文为了便于理解在伪代码中使用 for-loop，实际实现使用矩阵运算。

## Appendix E：Supplementary Experimental Results

表中数值均以 G-TSL 第一周订单数归一化；95% 置信区间由 t-test 计算，显著性水平 $\alpha=0.05$。

<p align="center"><img src="DFCL Table 4.png" alt="Table 4：含置信区间的线上 A/B 结果" width="900"></p>

Table 4 给出四周细分结果：G-DPM 相对 G-TSL 提升 $1.32\%$，G-DFCL 提升 $2.17\%$，与正文 Figure 3(b) 的平均结论一致。
