---
tags:
  - 自动出价
  - GRM
  - 响应建模
  - 预算控制
  - CPA约束
  - AuctionNet
  - KDD2026
created: 2026-08-20
---

# GRM：怎样显式、可靠地满足预算与 CPA 约束？

论文：[Constrained Auto-Bidding via Generative Response Modeling](https://arxiv.org/abs/2605.27811)  
PDF：[arXiv PDF](https://arxiv.org/pdf/2605.27811)  
会议：KDD 2026  
作者：Eunseok Yang、Xingdong Zuo、Kyung-Min Kim  
机构：NAVER Corporation  
代码：论文与 arXiv 页面未提供官方代码仓库

## 1. 前置信息：总览、摘要与引言

### 1.1 一句话总览

GRM 不直接学习“当前应该输出什么 multiplier”，而是先根据历史预测**剩余周期的流量，以及 multiplier 对成本和价值的响应曲线**；控制器再分别求出满足剩余预算与目标 CPA 的最大 multiplier，并执行两者中更严格的一个。

### 1.2 研究背景与核心问题

自动出价希望在一个完整投放周期内最大化转化、收入等广告主价值，同时满足总预算与 CPA/ROAS 等效率约束。难点在于：约束跨越整个周期，但每次竞价发生在当下，决策时并不知道未来还有多少流量、竞争会有多激烈、不同出价强度能换来多少成本与价值。

论文将既有方法概括为两类：

1. **直接输出动作。** 反馈控制根据已经发生的花费和效率调节 multiplier，稳定但偏反应式；强化学习和生成式策略可以利用长历史，却常把预算、CPA 等约束压进 reward 或 RTG，难以看清是哪条约束限制了动作，也难以诊断违约原因。
2. **预测环境量再控制。** 流量预测或 bid-landscape 模型会预测流量、赢标率或价格分布，但通常只覆盖某一个环境量或单次竞价快照，仍缺少面向剩余周期、可直接用于约束求解的成本—价值响应。

GRM 的关键变化是：**把学习目标从 action 改成 response。** 响应曲线比最优动作更平滑；最优动作可能在约束边界处突然跳变，而成本和价值随 multiplier 的变化通常连续、单调、趋于饱和，因此更适合作为监督学习目标。

### 1.3 核心思路与数据流

<p align="center"><img src="./GRM Figure 1 - Framework.png" alt="Figure 1：GRM 整体框架" width="900" style="max-width: 100%; height: auto;"></p>

> Figure 1：左侧 GRM 使用 causal Transformer 编码状态—动作历史，输出剩余流量、成本曲线和价值曲线；右侧 Min-Pacing Controller 分别求预算根与 CPA 根，再取更小的 multiplier。

一轮在线决策可以概括为：

```text
截至当前 tick 的状态和历史 multiplier
                  |
                  v
          Causal Transformer
                  |
                  v
预测剩余流量 + 成本响应曲线 + 价值响应曲线
                  |
          +-------+-------+
          |               |
       预算求根          CPA 求根
        alpha_B           alpha_C
          |               |
          +-------+-------+
                  |
          alpha_t = min(alpha_B, alpha_C)
                  |
                  v
       对当前 tick 内所有曝光统一执行
       b_{t,i} = alpha_t * v_{t,i}
```

需要区分三个层次：

- **预测层：**GRM 输出的是函数形状和剩余流量，不是最终动作；
- **控制层：**解析控制器在预测曲线上求出当前窗口的 $\alpha_t$；
- **执行层：**同一 tick 内共享 $\alpha_t$，每个曝光的基础价值 $v_{t,i}$ 不同，因此最终 bid 仍然不同。

### 1.4 主要贡献

论文明确给出三项贡献：

1. 提出历史条件化的 GRM，预测剩余周期的流量、成本曲线与价值曲线，而不是直接生成动作；
2. 提出解析 Min-Pacing Controller，通过两个一维求根显式处理预算与 CPA，并证明它是 single-$\alpha$ 问题的精确解；
3. 从理论上给出 single-$\alpha$ 近似误差和预测误差到约束违约的界，并在 AuctionNet 上取得比最强基线高 $7.8\%$ 的平均 score。

### 1.5 阅读前先明确三个边界

#### 1.5.1 GRM 输出 multiplier 还是 bid

GRM 网络既不直接输出最终 bid，也不直接输出 multiplier。它输出 $7$ 个量：剩余流量的对数，以及成本曲线和价值曲线各 $3$ 个参数。控制器用这些预测求出 tick 级 multiplier $\alpha_t$，最终曝光级 bid 才是 $b_{t,i}=\alpha_t v_{t,i}$。

#### 1.5.2 预测的是因果响应还是条件响应

论文明确说明，日志只记录实际执行的 multiplier 及其结果，GRM 的目标不是恢复严格意义上的反事实因果效应，而是学习部署分布上的条件预测 $\widehat{\bar C}_{t:T}(\alpha\mid H_t)$。因此“response curve”不应直接等同于经过随机实验识别的因果剂量—反应曲线。

#### 1.5.3 “显式约束”是否等于绝对不违约

控制器会在**预测曲线**上显式求解预算与 CPA 可行边界；若预测完全准确且单调性、可求根条件成立，single-$\alpha$ 解满足约束。真实环境仍可能因曲线和流量预测误差而违约，论文给出的是“违约规模由预测误差控制”的上界，而不是无条件零违约保证。

## 2. Problem Setup：自动出价问题定义

### 2.1 General Bid Optimization：曝光级约束优化

广告主面对 $N$ 次曝光机会。第 $i$ 次机会的 bid 为 $b_i$，赢得曝光后的实际成本为 $c_i(b_i)$，实际业务价值为 $u_i(b_i)$。一般问题是：

$$
\max_{b_1,\ldots,b_N}\sum_{i=1}^{N}u_i(b_i). \qquad \text{(1)}
$$

预算约束为：

$$
\sum_{i=1}^{N}c_i(b_i)\le B. \qquad \text{(2)}
$$

目标 CPA 或 inverse ROAS 约束为：

$$
\frac{\sum_{i=1}^{N}c_i(b_i)}
{\sum_{i=1}^{N}u_i(b_i)}\le\tau. \qquad \text{(3)}
$$

$B$ 是整个周期的预算，$\tau$ 是目标 CPA；若 $u_i$ 表示收入，同一形式也可表达 inverse ROAS。这个问题难在曝光数量可能达到百万级、未来流量未知，而且预算与 CPA 将全部曝光决策耦合在一起。

### 2.2 Multiplier-Based Pacing：将高维 bid 压缩成一个控制量

生产系统通常将自动出价拆为两层：

- 下游价值模型对每次曝光预测基础价值 $v_i$；
- campaign 级控制器输出 pacing multiplier $\alpha$，形成 $b_i=\alpha v_i$。

这样不再独立优化数百万个 $b_i$，而是只调节一个 multiplier；同时保留基础价值排序：$v_i$ 越高，最终 bid 仍越高。

### 2.3 Tick-Level Formulation：窗口级控制与曝光级执行

论文将投放周期划分为 $T$ 个 tick，每个 tick 可以是分钟或小时。tick $t$ 内有 $I_t$ 次曝光机会，控制器选择一个有界 multiplier：

$$
b_{t,i}(\alpha_t)=\alpha_t v_{t,i},
\qquad i=1,\ldots,I_t. \qquad \text{(4)}
$$

其中 $\alpha_t\in\mathcal A=[\underline\alpha,\bar\alpha]$。同一 tick 的 multiplier 相同，但 $v_{t,i}$ 随曝光变化，因此 bid 不相同。

**直观理解：**GRM 决定的是“这一窗口整体要激进多少”，价值模型决定“窗口里哪条曝光更值得出高价”。

### 2.4 Information Structure：决策时已经知道什么

tick $t$ 开始时可见的决策前历史为：

$$
H_t:=\bigl(
s_{1:t},\alpha_{1:t-1},I_{1:t-1},
\mathrm{Cost}_{<t},\mathrm{Val}_{<t}
\bigr). \qquad \text{(5)}
$$

- $s_{1:t}$：时间、campaign 状态等上下文；
- $\alpha_{1:t-1}$：过去真正执行的 multiplier；
- $I_{1:t-1}$：过去各 tick 的流量；
- $\mathrm{Cost}_{<t}$、$\mathrm{Val}_{<t}$：截至上一 tick 的累计成本与价值。

控制器先基于 $H_t$ 决定 $\alpha_t$，随后 tick $t$ 的曝光才到达并完成竞价。因此 $I_t$、当前结果和未来响应都不能提前放入输入。

### 2.5 Spend and Value Curves：响应曲线是什么

给定历史 $H_t$，每次机会的期望成本曲线定义为：

$$
C_t(\alpha)
:=\mathbb E\!\left[c_{t,i}(\alpha)\mid H_t\right].
\qquad \text{(6)}
$$

每次机会的期望价值曲线为：

$$
V_t(\alpha)
:=\mathbb E\!\left[u_{t,i}(\alpha)\mid H_t\right].
\qquad \text{(7)}
$$

$v_{t,i}$ 是出价时使用的预估价值，$u_{t,i}$ 是竞价后实现的 KPI 结果，两者不是同一个量。CPA 场景中 $u_{t,i}$ 可以是转化指标；ROAS 场景中可以是收入。

### 2.6 Structural Assumptions：可求解依赖哪些结构

论文作出两个结构假设：

- **S1：**$C_t(\alpha)$ 严格递增，$V_t(\alpha)$ 非递减；
- **S2：**两条曲线有界，即 $C_t(\alpha),V_t(\alpha)\in[0,\bar M]$。

提高 multiplier 会提高赢标概率，因此成本增加、价值通常也不会下降；但当可赢流量趋于耗尽时，两者会逐渐饱和。这些性质是后续一维求根和精确性证明的基础。

### 2.7 Tick-Level Constrained Objective：序列目标

窗口级目标为：

$$
\max_{\alpha_{1:T}}
\sum_{t=1}^{T}I_tV_t(\alpha_t). \qquad \text{(8)}
$$

预算约束为：

$$
\sum_{t=1}^{T}I_tC_t(\alpha_t)\le B. \qquad \text{(9)}
$$

CPA 约束为：

$$
\frac{\sum_{t=1}^{T}I_tC_t(\alpha_t)}
{\sum_{t=1}^{T}I_tV_t(\alpha_t)}\le\tau. \qquad \text{(10)}
$$

公式（10）也可写成 $\sum_t I_tC_t(\alpha_t)\le\tau\sum_t I_tV_t(\alpha_t)$。ROI floor 等其他比率约束可以用相同方式扩展，但本文实验和控制推导主要围绕预算与 CPA。

## 3. Generative Response Model：怎样预测未来响应

### 3.1 Response Objects and Horizon-Aggregate Curves

#### 3.1.1 Horizon-Aggregate Curves：为什么预测整段平均曲线

控制器每次规划时暂时假设从当前 tick 到周期结束都使用同一个候选 multiplier $\alpha$，因此将逐 tick 曲线按流量加权，得到剩余周期的每机会平均成本：

$$
\bar C_{t:T}(\alpha)
:=\frac{\sum_{k=t}^{T}I_kC_k(\alpha)}
{\sum_{k=t}^{T}I_k}. \qquad \text{(11)}
$$

对应的每机会平均价值为：

$$
\bar V_{t:T}(\alpha)
:=\frac{\sum_{k=t}^{T}I_kV_k(\alpha)}
{\sum_{k=t}^{T}I_k}. \qquad \text{(12)}
$$

它们不是简单的逐 tick 算术平均，而是让高流量 tick 权重更大。虽然一次规划暂时使用 single-$\alpha$，系统每个 tick 都会重算，所以最终实际执行的 $\alpha_1,\ldots,\alpha_T$ 仍会随时间变化。

#### 3.1.2 Response Bundle：模型到底要预测什么

剩余周期的完整响应对象为：

$$
\mathcal R_{t:T}
:=\Bigl(
I_{t:T},\bar C_{t:T}(\cdot),\bar V_{t:T}(\cdot)
\Bigr). \qquad \text{(13)}
$$

其中 $I_{t:T}=\sum_{k=t}^{T}I_k$。给定候选 $\alpha$，剩余总成本与总价值分别为：

$$
\mathcal C_{t:T}(\alpha)
=I_{t:T}\bar C_{t:T}(\alpha),
\qquad
\mathcal V_{t:T}(\alpha)
=I_{t:T}\bar V_{t:T}(\alpha).
$$

**直观理解：**GRM 预测的是一张“如果后面整体使用不同 multiplier，预计会有多少机会、花多少钱、得到多少价值”的响应地图；controller 再在这张地图上找满足约束的点。

#### 3.1.3 History Encoder and Response Decoder

Causal sequence model 将历史压缩成隐状态：

$$
h_t=f_\theta\!\left(s_{1:t},\alpha_{1:t-1}\right)
\in\mathbb R^d. \qquad \text{(14)}
$$

响应解码器从 $h_t$ 预测完整 response bundle：

$$
\widehat{\mathcal R}_{t:T}
=g_\theta(h_t)
=\Bigl(
\widehat I_{t:T},
\widehat{\bar C}_{t:T}(\cdot),
\widehat{\bar V}_{t:T}(\cdot)
\Bigr). \qquad \text{(15)}
$$

网络只预测一组剩余周期聚合曲线，不为每个未来 tick 单独输出一组曲线。

### 3.2 Function-Valued Curve Parameterization

#### 3.2.1 Design Motivation：为什么使用 log-sigmoid

曲线需要同时满足：$\alpha=0$ 时没有赢标、成本和价值为 $0$；提高 multiplier 后响应单调增加；当几乎赢得全部可用流量时趋于饱和。论文将正态分布 CDF 作用在 $\log(\alpha)$ 上，用低维参数表达“前期增长快、后期边际收益递减”的竞价结构。

#### 3.2.2 Parametric Family：成本和价值曲线

成本曲线参数化为：

$$
\widehat{\bar C}_{t:T}(\alpha)
=a^{(C)}\cdot
\widetilde\Phi\!\left(b^{(C)},c^{(C)},\alpha\right).
\qquad \text{(16)}
$$

归一化函数为：

$$
\widetilde\Phi(b,c,\alpha)
:=
\frac{
\Phi\!\left(b\log(\alpha+\varepsilon)+c\right)
-\Phi\!\left(b\log\varepsilon+c\right)
}{
1-\Phi\!\left(b\log\varepsilon+c\right)
}.
$$

它满足：

$$
\widetilde\Phi(b,c,0)=0,
\qquad
\lim_{\alpha\to\infty}\widetilde\Phi(b,c,\alpha)=1.
$$

因此 $a^{(C)}$ 表示成本饱和值，$b^{(C)}$ 控制对 multiplier 的敏感程度，$c^{(C)}$ 控制水平位移。论文使用 $\varepsilon=10^{-3}$ 避免 $\log 0$。价值曲线使用完全相同的形式，参数为 $\theta^{(V)}=(a^{(V)},b^{(V)},c^{(V)})$；$a^{(\cdot)}$ 和 $b^{(\cdot)}$ 经过 softplus，保证为正并维持单调性。

#### 3.2.3 Seven-Dimensional Output：网络实际输出

模型输出为：

$$
\left(
\widehat I_{t:T},
\theta^{(C)},
\theta^{(V)}
\right)
=g_\theta(h_t). \qquad \text{(17)}
$$

由于两条曲线各有 $3$ 个参数，再加 $1$ 个剩余流量预测，所以每个 anchor tick 只需输出 $1+6=7$ 个数。附录进一步说明，实际输出的是 $\log\widehat I_{t:T}$，以适应重尾流量。

### 3.3 Training with Future-Sampling Supervision

#### 3.3.1 Training Data and Point Supervision

日志在 tick $k$ 只记录真正执行的 $\alpha_k$，以及 $I_k$、$\mathrm{Cost}_k$ 和 $\mathrm{Val}_k$。因此可构造的每机会监督点是：

$$
C_k(\alpha_k)\approx\frac{\mathrm{Cost}_k}{I_k},
\qquad
V_k(\alpha_k)\approx\frac{\mathrm{Val}_k}{I_k}.
\qquad \text{(18)}
$$

对于 anchor tick $t$，训练时从未来 $\{t,\ldots,T\}$ 中抽取多个 tick。不同未来 tick 的日志 multiplier 通常不同，于是形成散落在 $\alpha$ 轴上的监督点。

#### 3.3.2 Weighted Curve Fitting：散点如何监督整条曲线

GRM 并没有观察同一历史 $H_t$ 下所有候选 multiplier 的真实反事实结果。它用后续不同 tick、不同日志 multiplier 的观测点拟合一条剩余周期聚合曲线，并按 $I_k$ 加权，使高流量 tick 对曲线贡献更大。

**直观理解：**不是先在日志里找出一条完整曲线，而是把未来不同位置留下的“在这个 multiplier 下发生了什么”当作散点，训练一个历史条件化模型将这些散点概括为平滑曲线。

#### 3.3.3 Training Loss

每个 anchor $t$ 独立采样 $M$ 个未来索引 $k_1,\ldots,k_M\sim\mathcal U\{t,\ldots,T\}$，损失为：

$$
\begin{aligned}
\mathcal L(\theta)
=\mathbb E_t\Bigg[
&\frac{1}{M}\sum_{m=1}^{M}
\Bigg(
I_{k_m}
\Bigl(
\widehat{\bar C}_{t:T}(\alpha_{k_m})
-C_{k_m}(\alpha_{k_m})
\Bigr)^2\\
&\qquad\qquad+
I_{k_m}
\Bigl(
\widehat{\bar V}_{t:T}(\alpha_{k_m})
-V_{k_m}(\alpha_{k_m})
\Bigr)^2
\Bigg)\\
&+\lambda_I
\Bigl(
\log\widehat I_{t:T}-\log I_{t:T}
\Bigr)^2
\Bigg].
\end{aligned}
\qquad \text{(19)}
$$

前两项拟合成本和价值曲线，第三项拟合剩余流量。流量使用对数误差稳定重尾分布，$\lambda_I$ 控制流量损失权重。

#### 3.3.4 Identifiability and Coverage：论文如何界定可识别性

论文明确承认：$(\alpha_k,C_k(\alpha_k))$ 来自不同历史 $H_k$，不能据此恢复同一 $H_t$ 下严格的反事实曲线。GRM 学习的是部署分布上的条件预测，而不是无条件因果曲线。

模型依赖日志中的 action coverage。论文认为 pacing 调节、广告主异质性和 A/B 实验会自然产生多样的 multiplier 轨迹，因此无需另行在线探索；但若某些状态下 multiplier 覆盖非常窄，区间外的曲线形状仍主要来自参数化假设与跨样本泛化。

## 4. Analytic Constrained Control：怎样在预测曲线上求动作

### 4.1 From Average Curves to Horizon Totals

预测的剩余总成本为：

$$
\widehat{\mathcal C}_{t:T}(\alpha)
:=\widehat I_{t:T}\cdot
\widehat{\bar C}_{t:T}(\alpha).
\qquad \text{(20)}
$$

预测的剩余总价值为：

$$
\widehat{\mathcal V}_{t:T}(\alpha)
:=\widehat I_{t:T}\cdot
\widehat{\bar V}_{t:T}(\alpha).
\qquad \text{(21)}
$$

### 4.2 State-Dependent Remaining Constraints

当前剩余预算为：

$$
B_t:=B-\mathrm{Cost}_{<t}. \qquad \text{(22)}
$$

历史 CPA slack 为：

$$
\Delta_t
:=\tau\cdot\mathrm{Val}_{<t}-\mathrm{Cost}_{<t}.
\qquad \text{(23)}
$$

$\Delta_t>0$ 表示历史价值按目标 CPA 折算后仍有余量，$\Delta_t<0$ 表示历史阶段已经超出 CPA 目标。每个 tick 重新使用实际累计结果更新这两个量，使控制形成闭环。

### 4.3 Two One-Dimensional Solves

#### 4.3.1 Budget Root

预算边界要求预测的剩余总成本刚好等于剩余预算：

$$
\widehat{\mathcal C}_{t:T}(\alpha_B)=B_t.
\qquad \text{(24)}
$$

成本曲线严格递增时，$\alpha_B$ 是预算允许的最大出价强度，可通过二分查找求解。

#### 4.3.2 CPA Root

整体 CPA 约束等价于：

$$
\widehat{\mathcal C}_{t:T}(\alpha)
-\tau\widehat{\mathcal V}_{t:T}(\alpha)
\le\Delta_t. \qquad \text{(25)}
$$

CPA 边界根满足：

$$
\widehat{\mathcal C}_{t:T}(\alpha_C)
-\tau\widehat{\mathcal V}_{t:T}(\alpha_C)
=\Delta_t. \qquad \text{(26)}
$$

$\alpha_C$ 是 CPA 允许的最大出价强度。它同时使用历史累计 slack 和未来成本—价值预测，因此不是只看未来平均 CPA。

### 4.4 Min-Pacing Control Law

最终执行：

$$
\alpha_t=\min\{\alpha_B,\alpha_C\}.
\qquad \text{(27)}
$$

- 若 $\alpha_B<\alpha_C$，当前主要受预算限制；
- 若 $\alpha_C<\alpha_B$，当前主要受 CPA 限制；
- 取更小者就是选择两个可行上界中更严格的一个。

**直观理解：**预算根回答“最多出多激进才不会把钱花超”，CPA 根回答“最多出多激进才不会把效率做坏”；两者都要满足，所以选择更保守的那个。

### 4.5 CPA Monotonicity and Fallback

定义：

$$
\Psi_{t:T}(\alpha)
:=\widehat{\mathcal C}_{t:T}(\alpha)
-\tau\widehat{\mathcal V}_{t:T}(\alpha).
$$

若：

$$
\Psi'(\alpha)
=\widehat{\mathcal C}'(\alpha)
-\tau\widehat{\mathcal V}'(\alpha)>0,
$$

即边际成本大于目标 CPA 缩放后的边际价值，则 CPA 方程有唯一根。论文报告在 P14--P20 的 $4{,}032$ 个 anchor-tick 预测中，约 $98\%$ 的 $\Psi$ 在整个 action range 上单调。

若接近饱和导致 $\Psi$ 非单调，论文取从 $\underline\alpha$ 出发遇到的第一个根 $\alpha^{(1)}$，也就是包含最小 multiplier 的可行区间右端点，避免跨过第一个边界进入内部不可行区域。

### 4.6 Algorithm 1：Future-Sampling Training

<p align="center"><img src="./GRM Algorithm 1 - Training.png" alt="Algorithm 1：GRM Future-Sampling 训练流程" width="760" style="max-width: 100%; height: auto;"></p>

> Algorithm 1：对每个 anchor tick 编码历史、预测流量与两条曲线参数，再从未来抽取 $M$ 个监督 tick，通过公式（19）联合更新模型。

### 4.7 Algorithm 2：Receding-Horizon Online Control

<p align="center"><img src="./GRM Algorithm 2 - Online Control.png" alt="Algorithm 2：GRM 在线滚动控制流程" width="620" style="max-width: 100%; height: auto;"></p>

> Algorithm 2：每个 tick 都用真实累计成本和价值更新 $B_t$、$\Delta_t$，重新预测剩余响应并求两个根；只执行当前的 $\alpha_t$，观察反馈后再次规划。

这一区分很重要：训练阶段只学习环境响应；线上阶段不更新网络参数，而是不断更新状态并重复“预测—求根—执行一步”。

## 5. Theoretical Analysis：三条理论结论

### 5.1 Single-$\alpha$ Approximation and Structural Gap

#### 5.1.1 为什么 single-$\alpha$ 会有近似误差

原始问题允许每个未来 tick 使用不同的 $\alpha_k$，而一次 GRM 规划只用一条剩余周期聚合曲线，相当于假设剩余周期暂时共用一个 $\alpha$。令 $\mathrm{OPT}_{\mathrm{trajectory}}$ 为逐 tick 最优值，$\mathrm{OPT}_{\mathrm{single\text{-}}\alpha}$ 为 single-$\alpha$ 限制下的最优值，论文用不同 tick 的边际效率差异刻画两者间隙。

设 $\alpha^*$ 是 single-$\alpha$ 最优解，剩余周期平均边际效率为：

$$
\widetilde\lambda
:=\frac{\bar V'(\alpha^*)}{\bar C'(\alpha^*)}.
$$

效率离散度定义为：

$$
\sigma^2
:=\frac{1}{I_{t:T}}
\sum_{k=t}^{T}I_k
\left(
\frac{V_k'(\alpha^*)}{C_k'(\alpha^*)}
-\widetilde\lambda
\right)^2.
$$

它是各 tick“增加一点成本能换来多少边际价值”的流量加权方差。

#### 5.1.2 假设与 Structural Gap 定理

- **B1：**$C_k$、$V_k$ 二阶可微，且 $C_k'(\alpha)>0$；
- **B2：**$h_k(\alpha):=V_k(\alpha)-\widetilde\lambda C_k(\alpha)$ 在 $\alpha^*$ 邻域内为 $\gamma$-强凹。

论文给出：

$$
\mathrm{OPT}_{\mathrm{trajectory}}
-\mathrm{OPT}_{\mathrm{single\text{-}}\alpha}
\le
\frac{C_{\max}'^{,2}I_{t:T}}{2\gamma}\sigma^2,
$$

其中 $C'_{\max}=\max_k C_k'(\alpha^*)$。

**直观理解：**如果各未来 tick 的边际效率差不多，$\sigma\approx0$，暂时用一个 multiplier 规划整段未来几乎不损失最优性；如果不同时间段效率差别很大，single-$\alpha$ 的结构性损失就可能增大。

论文强调 B2 是局部假设。对公式（16）的 log-sigmoid，只需 $h_k$ 在实验中内部最优点 $\alpha^*$ 附近强凹，而不是要求整个 action range 都强凹。

### 5.2 Min-Pacing Exactness：为什么取两个根的最小值

假设：

- **A1：**$\mathcal V_{t:T}(\alpha)$ 非递减，$\mathcal C_{t:T}(\alpha)$ 严格递增；
- **A2：**在问题可行时，$\alpha_B$、$\alpha_C$ 的边界根存在。

预算可行域是 $\mathcal F_B=[\underline\alpha,\alpha_B]$，CPA 可行域的右边界不超过 $\alpha_C$。由于价值随 $\alpha$ 非递减，最优解必然是交集中的最大可行 multiplier，因此：

$$
\alpha^*=\min\{\alpha_B,\alpha_C\}.
$$

这个结论是对 **single-$\alpha$ 子问题** 的精确性证明，不代表 single-$\alpha$ 与完整逐 tick 最优策略完全等价；两者的差距由上一节的 $\sigma^2$ 控制。

若最大可能成本也花不完剩余预算，即：

$$
B_t>a^{(C)}\widehat I_{t:T},
$$

则预算根不存在，论文令 $\alpha_B:=\bar\alpha$；此时只由 CPA 根限制动作，若 CPA 也不绑定则执行 $\bar\alpha$。

### 5.3 Prediction Error and Constraint Violation

#### 5.3.1 三类预测误差

定义剩余周期上的一致误差：

$$
\epsilon_C
:=\sup_{t,\alpha}
\left|
\widehat{\bar C}_{t:T}(\alpha)
-\bar C_{t:T}(\alpha)
\right|,
$$

$$
\epsilon_V
:=\sup_{t,\alpha}
\left|
\widehat{\bar V}_{t:T}(\alpha)
-\bar V_{t:T}(\alpha)
\right|,
$$

$$
\epsilon_I
:=\sup_t
\left|
\widehat I_{t:T}-I_{t:T}
\right|.
$$

总成本曲线误差满足：

$$
\epsilon_t
:=\sup_\alpha
\left|
\widehat{\mathcal C}_{t:T}(\alpha)
-\mathcal C_{t:T}(\alpha)
\right|
\le
I_{t:T}\epsilon_C
+\epsilon_I\bar C_{\max}
+\epsilon_I\epsilon_C.
\qquad \text{(28)}
$$

其中 $\bar C_{\max}=\sup_\alpha\bar C_{t:T}(\alpha)$。第一项来自曲线形状误差，第二、三项来自剩余流量误差及其与曲线误差的交互。

#### 5.3.2 斜率假设

令：

$$
\bar\Psi_{t:T}(\alpha)
=\bar C_{t:T}(\alpha)-\tau\bar V_{t:T}(\alpha),
\qquad
\Psi_t(\alpha)=C_t(\alpha)-\tau V_t(\alpha).
$$

论文要求成本曲线与 $\Psi$ 的导数存在正下界，同时每 tick 导数有上界：

$$
0<\underline C'
\le\bar C'_{t:T}(\alpha)
\le\bar L_C,
\qquad
C_t'(\alpha)\le L_C,
$$

$$
0<\underline\Psi'
\le\bar\Psi'_{t:T}(\alpha)
\le\bar L_\Psi,
\qquad
|\Psi_t'(\alpha)|\le L_\Psi.
$$

正下界保证小的函数值误差不会被近乎水平的曲线放大成极大的根位置误差。

#### 5.3.3 Constraint Violation Bounds

在 A1--A2 与上述斜率条件下，预算满足：

$$
\begin{aligned}
\sum_t I_tC_t(\alpha_t)
\le B+\rho\Bigl(&
I_{1:T}\epsilon_C
+\epsilon_I\bar C_{\max}H_I\\
&+\epsilon_I\epsilon_CH_I
\Bigr),
\end{aligned}
\qquad \text{(29)}
$$

CPA slack 满足：

$$
\begin{aligned}
\sum_t I_t\Psi_t(\alpha_t)
\le\Delta+\rho_\Psi\Bigl(&
I_{1:T}(\epsilon_C+\tau\epsilon_V)
+\epsilon_I\bar\Psi_{\max}H_I\\
&+\epsilon_I(\epsilon_C+\tau\epsilon_V)H_I
\Bigr),
\end{aligned}
\qquad \text{(30)}
$$

其中：

$$
\rho=\frac{L_C}{\underline C'},
\qquad
\rho_\Psi=\frac{L_\Psi}{\underline\Psi'},
\qquad
H_I=\sum_{t=1}^{T}\frac{I_t}{I_{t:T}}.
$$

均匀流量下 $H_I$ 等于调和数 $H_T\le1+\ln T$。因此曲线误差带来 $O(I_{1:T}\epsilon_C)$ 的系统项，而流量误差因每 tick 重规划只累计到约 $O(\epsilon_I\log T)$。

**直观理解：**GRM 不是声称预测有误时也绝不违约，而是把“会违约多少”明确连接到“曲线和流量预测错了多少”；滚动重规划会不断用真实反馈纠偏，尤其抑制流量误差的长期累积。

## 6. Experiments：AuctionNet 实验

### 6.1 Setup

#### 6.1.1 Environment and Data

实验使用 NeurIPS 2024 Auto-Bidding Challenge 的 AuctionNet 仿真环境：

- 每个 delivery period 有 $48$ 个 tick 和超过 $0.5$ million 次竞价机会；
- 每个 tick 有 $48$ 个 agent 参与竞价；
- 日志总计超过 $500$ million 条记录，包含预估转化价值、bid、竞价日志和曝光结果；
- P7--P13 用于训练，P14--P20 用于主实验和预测质量评估。

这里的 P7、P8 等表示 AuctionNet 数据中的 **delivery period 编号**，不是模型参数或数据比例。主实验固定其他 $47$ 个广告主的 bid，只替换目标广告主策略；分布变化实验则让竞争 agent 按 AuctionNet competition protocol 动态出价。

#### 6.1.2 Baselines

所有方法最终都被统一为 tick 级 multiplier 输出：

- **BC：**模仿日志 multiplier；
- **CQL、IQL：**带离线正则的价值学习；
- **DT：**根据 RTG 生成动作，RTG 设为满足约束下的最佳可达价值；
- **DiffBid：**条件扩散出价；
- **EBaReT：**expert-guided reward Transformer；
- **FTRL：**分布变化实验中的工业控制基线。

对原本输出曝光级 bid 的 BC、CQL、IQL，论文先对预测 bid 求 tick 平均，再除以平均预测价值，转换成 multiplier。

#### 6.1.3 Metrics

AuctionNet 官方 score 为：

$$
\mathrm{score}
=p(\mathrm{cpa};d)
\sum_t\mathrm{Val}_t,
$$

其中：

$$
p(\mathrm{cpa};d)
=\min\left\{
\left(\frac{d}{\mathrm{cpa}}\right)^\beta,1
\right\},
\qquad \beta=2.
$$

当实际 CPA 不超过目标 $d$ 时惩罚为 $1$；超过目标后，累计价值会按违约程度折损。分布变化实验额外报告从正常环境到 shifted 环境的 score 下降比例。

#### 6.1.4 Implementation Details

正文给出的主要设置为：2 层 causal Transformer、4 个 attention head、hidden size $128$；2 层 MLP decoder 输出 $7$ 个参数；AdamW 学习率 $10^{-3}$、weight decay $10^{-5}$、batch size $64$；每个 anchor 抽取 $M=8$ 个未来 tick。完整设置见附录 Table 3。

### 6.2 Overall Performance

<p align="center"><img src="./GRM Table 1 - Overall Performance.png" alt="Table 1：AuctionNet 主实验结果" width="900" style="max-width: 100%; height: auto;"></p>

> Table 1：GRM 在 P14--P20 的平均 score 为 $33.88\pm2.40$，比最强基线 EBaReT 的 $31.43\pm1.86$ 高 $7.8\%$。

GRM-short 只预测当前 tick 的响应，平均 score 为 $31.14$，比完整 GRM 低约 $8.1\%$。这项对照支持论文的核心主张：只做当前快照响应无法提前利用未来流量、竞争、预算和 CPA 演化，剩余周期聚合预测具有额外价值。

需要注意，Table 1 的 score 已包含 CPA 违约惩罚，因此它同时反映累计价值与约束表现，并不是单独的纯价值指标。

### 6.3 Robustness to Distribution Shift

<p align="center"><img src="./GRM Figure 2 - Robustness.png" alt="Figure 2：分布变化下的鲁棒性" width="900" style="max-width: 100%; height: auto;"></p>

> Figure 2：左图将竞争者预算提高到 $1.1$ 倍，右图将目标 CPA 收紧到原来的 $0.8$ 倍；实色柱为正常环境，斜线柱为 shifted 环境。

在竞争增强下：

- GRM 下降 $7.2\%$；
- FTRL 下降 $9.0\%$；
- DT 下降 $22.6\%$。

在 CPA 收紧下：

- GRM 下降 $5.0\%$；
- FTRL 下降 $6.9\%$；
- DT 下降 $13.9\%$。

论文还报告 shifted 环境中的约束违约率：GRM 从 $6.5\%$ 增至 $9.8\%$，FTRL 从 $8.2\%$ 增至 $15.3\%$，DT 从 $10.8\%$ 增至 $28.7\%$。论文将 GRM 的优势归因于：每个 tick 重预测响应，并根据新 $B_t$、$\Delta_t$ 重新求根，而不是继续复用离线策略的固定动作规律。

### 6.4 Prediction Quality and Performance

<p align="center"><img src="./GRM Figure 3 - Validation Loss.png" alt="Figure 3：验证损失与决策表现" width="760" style="max-width: 100%; height: auto;"></p>

> Figure 3：横轴是 held-out validation loss，纵轴是 test score；10 个不同收敛程度的 checkpoint 呈显著负相关 $r=-0.78$、$p<0.01$。

最佳 checkpoint 的 loss 为 $0.96$，score 为 $33.88$；loss 高于 $1.04$ 的欠收敛 checkpoint 平均 score 低于 $30.0$。在 $18$ 组架构与超参数配置上重复分析，相关系数仍为 $r=-0.72$。

这说明更低的响应预测损失通常对应更好的决策表现，与公式（29）至（30）的方向一致。不过相关性实验不能单独证明全部性能增益由预测精度因果造成，因为 checkpoint 之间还可能存在其他训练差异；论文将 validation loss 作为难以直接观测反事实曲线误差时的代理指标。

### 6.5 Curve Family Ablation

<p align="center"><img src="./GRM Table 2 - Curve Ablation.png" alt="Table 2：响应曲线族消融" width="760" style="max-width: 100%; height: auto;"></p>

> Table 2：log-sigmoid 得分最高；linear、piecewise-linear、普通 sigmoid 和 monotone MLP 均有所下降。

论文给出的解释是：linear 无法表达高 $\alpha$ 区间的饱和，普通 sigmoid 缺少 $\log(\alpha)$ 变换，难以刻画中间区间的边际收益递减；monotone MLP 容量更大但略差，说明平滑的 horizon-aggregate target 不需要过高自由度，额外容量反而可能拟合噪声。

## 7. Related Work：相关工作

### 7.1 Real-Time Bidding and Auto-Bidding

RTB 需要在约 $100$ ms 内完成曝光级竞价，而预算、CPA 和 ROAS 约束跨越整个 campaign。系统必须同时满足“曝光级执行足够快”和“周期级决策能够协调未来”这两个尺度要求，这也是生产系统普遍采用价值模型加 campaign multiplier 分层架构的原因。

### 7.2 Control and Pacing

PID、反馈控制和拉格朗日对偶方法通过实际花费与目标之间的偏差更新 multiplier，具有稳定、低延迟的优势，但通常只使用有限的未来预测，主要在偏差发生后进行纠正。生产系统也常把预算 pacing 与 CPA/ROAS pacing 分开实现，再取多个 multiplier 的最小值。

GRM 保留这种 minimally-coupled 的 Min-Pacing 结构，但将根求解建立在历史条件化的未来响应曲线上，使 controller 从纯反应式控制扩展为预测式控制。

### 7.3 Reinforcement Learning

CQL、IQL 等 offline RL 通过保守价值估计或隐式正则从日志学习策略；online RL 可以持续适应环境，却会带来不可接受的预算浪费与在线探索风险。RL 出价方法通常通过 reward shaping 表达预算和效率约束，违约时难以区分是策略、价值估计还是 reward 权重造成的问题。

GRM 不学习 action policy 或 Q function，而是预测环境响应，再交给显式求解器处理约束。这种分解提高了可诊断性，但效果仍依赖响应模型在部署分布中的准确性。

### 7.4 Generative Models

DT、Constrained DT、DiffBid、GAS、GAVE 和 EBaReT 等方法将自动出价改写为 RTG 条件动作生成、扩散采样或带价值引导的序列生成。论文认为这些方法大多属于 scalar-conditioned action generation：多个业务目标被压入一个 return、critic 或搜索分数，难以直接指出当前 binding constraint。

GRM 的差别不是换一种动作生成器，而是根本不生成动作：先生成 function-valued response，再由解析 controller 求动作。

### 7.5 Bid-Landscape Modeling

Bid-landscape 模型预测单次竞价的赢标率或 clearing-price 分布，可以刻画 bid 对单次竞价结果的影响，但通常是曝光级快照，需要额外流量预测与周期控制层，也不一定利用 campaign 的执行历史。

GRM 直接预测历史条件化的剩余周期聚合成本与价值曲线，目标粒度不同。

### 7.6 Forecasting and Control Hybrids

预测加控制的方法会先预测流量或价值点估计，再由优化器转成动作。GRM 将点预测扩展成函数值预测：对每个候选 $\alpha$ 都能得到成本和价值响应，因此预算与 CPA 可以直接在预测函数上求解。

## 8. Conclusion：论文结论与证据边界

论文将自动出价重新拆成两个职责明确的模块：GRM 学习“环境会怎样响应 multiplier”，Min-Pacing Controller 决定“在预算和 CPA 下允许使用多大的 multiplier”。这一设计使每条约束都有独立边界根，也使真实违约能够对应到成本曲线、价值曲线或流量预测误差。

论文的核心结论为：

1. 在各 tick 边际效率离散度较小时，single-$\alpha$ 聚合规划接近逐 tick 最优；
2. 在单调且根存在的条件下，$\min\{\alpha_B,\alpha_C\}$ 是 single-$\alpha$ 问题的精确解；
3. 滚动控制的约束违约上界随曲线和流量预测误差增长；
4. AuctionNet 实验中 GRM 平均 score 为 $33.88$，比最强基线高 $7.8\%$，在两种 episode 级分布变化下也更稳定。

使用这一方法依赖几个关键前提：日志中必须有足够的 multiplier 覆盖；未来成本和价值对 multiplier 的响应能够被单调低维曲线近似；single-$\alpha$ 足以表达主要控制需求；线上环境与训练分布不能相差到使条件响应预测失真。论文仅在 AuctionNet 仿真环境中验证，没有公开真实线上 A/B 结果或官方实现。

## 9. Appendix A：完整理论证明

### 9.1 Structural Gap 的完整证明

附录先处理仅有预算约束的情况。trajectory 问题允许每个 tick 独立选择 $\alpha_k$，single-$\alpha$ 问题要求所有剩余 tick 共用一个 $\alpha$。

#### 9.1.1 Step 1：比较两个拉格朗日对偶

trajectory 形式的对偶函数为：

$$
D_T(\lambda)
=\sum_{k=t}^{T}I_k
\max_\alpha
\left[V_k(\alpha)-\lambda C_k(\alpha)\right]
+\lambda B_t.
$$

single-$\alpha$ 形式为：

$$
D_S(\lambda)
=\max_\alpha
\sum_{k=t}^{T}I_k
\left[V_k(\alpha)-\lambda C_k(\alpha)\right]
+\lambda B_t.
$$

因为 trajectory 允许每个 tick 分别最大化，所以对任意 $\lambda\ge0$ 都有 $D_T(\lambda)\ge D_S(\lambda)$。

#### 9.1.2 Step 2：代入 single-$\alpha$ 的最优对偶变量

预算绑定时，single-$\alpha$ 最优点 $\alpha^*$ 的 KKT 条件给出：

$$
\lambda_S^*
=\frac{\sum_k I_kV_k'(\alpha^*)}
{\sum_k I_kC_k'(\alpha^*)}
=\frac{\bar V'(\alpha^*)}{\bar C'(\alpha^*)}
=\widetilde\lambda.
$$

由 single-$\alpha$ 问题的强对偶与 trajectory 问题的弱对偶：

$$
\begin{aligned}
\mathrm{OPT}_{\mathrm{trajectory}}
-\mathrm{OPT}_{\mathrm{single\text{-}}\alpha}
&\le D_T(\widetilde\lambda)-D_S(\widetilde\lambda)\\
&=\sum_{k=t}^{T}I_k
\left[
\max_\alpha h_k(\alpha)-h_k(\alpha^*)
\right],
\end{aligned}
$$

其中 $h_k(\alpha)=V_k(\alpha)-\widetilde\lambda C_k(\alpha)$。

#### 9.1.3 Step 3：用强凹性限制每个 tick 的收益差

令：

$$
e_k
:=\frac{V_k'(\alpha^*)}{C_k'(\alpha^*)}
-\widetilde\lambda,
$$

则：

$$
h_k'(\alpha^*)
=C_k'(\alpha^*)e_k.
$$

由 $\gamma$-强凹性：

$$
\max_\alpha h_k(\alpha)-h_k(\alpha^*)
\le
\frac{\left(h_k'(\alpha^*)\right)^2}{2\gamma}
=\frac{\left(C_k'(\alpha^*)\right)^2e_k^2}{2\gamma}.
$$

对 tick 求和并使用 $C_k'(\alpha^*)\le C'_{\max}$：

$$
\mathrm{gap}
\le
\frac{C_{\max}'^{,2}}{2\gamma}
\sum_{k=t}^{T}I_ke_k^2
=\frac{C_{\max}'^{,2}I_{t:T}}{2\gamma}\sigma^2.
$$

#### 9.1.4 Extension to Budget + CPA

联合约束的拉格朗日函数为：

$$
\begin{aligned}
D(\lambda,\mu)
=&\sum_{k=t}^{T}I_k\max_\alpha
\Bigl[
V_k(\alpha)-\lambda C_k(\alpha)\\
&\qquad\qquad
-\mu\bigl(C_k(\alpha)-\tau V_k(\alpha)\bigr)
\Bigr]
+\lambda B_t+\mu\Delta_t.
\end{aligned}
$$

内部项可以重写为：

$$
V_k-\lambda C_k-\mu(C_k-\tau V_k)
=(1+\mu\tau)
\left[V_k-\widetilde\lambda C_k\right],
$$

其中有效对偶变量为：

$$
\widetilde\lambda
:=\frac{\lambda^*+\mu^*}{1+\mu^*\tau}.
$$

因此相同证明成立，只多出缩放系数：

$$
\mathrm{OPT}_{\mathrm{trajectory}}
-\mathrm{OPT}_{\mathrm{single\text{-}}\alpha}
\le
\frac{(1+\mu^*\tau)C_{\max}'^{,2}I_{t:T}\sigma^2}
{2\gamma}.
$$

### 9.2 Constraint Violation Bound 的完整证明

#### 9.2.1 先把平均曲线误差转成总成本误差

由：

$$
\begin{aligned}
\widehat{\mathcal C}_{t:T}-\mathcal C_{t:T}
=&\widehat I_{t:T}
\left(
\widehat{\bar C}_{t:T}-\bar C_{t:T}
\right)\\
&+\left(
\widehat I_{t:T}-I_{t:T}
\right)\bar C_{t:T},
\end{aligned}
$$

并使用 $\widehat I_{t:T}\le I_{t:T}+\epsilon_I$，得到公式（28）。

#### 9.2.2 Step 1：函数误差如何变成根误差

预测控制器和 oracle 共享同一个真实剩余预算 $B_t$：

$$
\widehat{\mathcal C}_{t:T}(\widehat\alpha_B)=B_t,
\qquad
\mathcal C_{t:T}(\alpha_B^*)=B_t.
$$

因此：

$$
\mathcal C_{t:T}(\widehat\alpha_B)-B_t
\le\epsilon_t.
$$

由中值定理和导数下界：

$$
|\widehat\alpha_B-\alpha_B^*|
\le
\frac{\epsilon_t}{I_{t:T}\underline C'}.
$$

#### 9.2.3 Step 2：根误差如何变成当前 tick 成本误差

$$
\begin{aligned}
&\left|
I_tC_t(\widehat\alpha_B)
-I_tC_t(\alpha_B^*)
\right|\\
&\qquad\le
I_tL_C|\widehat\alpha_B-\alpha_B^*|
\le
\rho\frac{I_t}{I_{t:T}}\epsilon_t,
\end{aligned}
$$

其中 $\rho=L_C/\underline C'$。

#### 9.2.4 Step 3：跨 tick 累加

令当前 tick 成本偏差为 $\delta_t$，则：

$$
\begin{aligned}
\sum_{t=1}^{T}|\delta_t|
\le\rho\Bigl(&
I_{1:T}\epsilon_C
+\epsilon_I\bar C_{\max}H_I\\
&+\epsilon_I\epsilon_CH_I
\Bigr).
\end{aligned}
$$

#### 9.2.5 Step 4：滚动控制为什么能够自我修正

由于实际动作 $\widehat\alpha_t\le\widehat\alpha_B$，且成本非负、单调：

$$
I_tC_t(\widehat\alpha_t)
\le I_tC_t(\alpha_B^*)+|\delta_t|.
$$

又因为 oracle 剩余成本不超过当前真实剩余预算 $B_t=B-\mathrm{Cost}_{<t}$，过去若多花了钱，下一 tick 的 $B_t$ 会变小，controller 自动变得更保守。这个 telescoping 结构最终得到公式（29）。

CPA 情况对 $\Psi_t=C_t-\tau V_t$ 重复 Step 1--3，得到公式（30）。由于 $\Psi_t$ 可以为正也可以为负，无法直接使用成本非负性的 telescoping，因此论文给出的 CPA 界是更保守的逐 tick 偏差累加界。

## 10. Appendix B：实现与补充实验

### 10.1 GRM Architecture and Hyperparameters

<p align="center"><img src="./GRM Table 3 - Hyperparameters.png" alt="Table 3：GRM 网络和训练超参数" width="760" style="max-width: 100%; height: auto;"></p>

> Table 3：causal Transformer 最长处理 $48$ 个 tick，decoder 为 hidden size $64$ 的 2 层 MLP，总参数量约 $850$K；controller 的 action range 为 $[0.01,300.0]$。

网络输入由最多 $48$ 个 tick 的状态与历史 multiplier 组成。Transformer 为 2 层、4 个 head，hidden/FFN dimension 分别为 $128/512$；decoder 输出 $\log\widehat I_{t:T}$ 与两条曲线的 $6$ 个参数。$a^{(\cdot)}$、$b^{(\cdot)}$ 使用 softplus 保证正值，二分求根相对误差阈值为 $10^{-6}$。

### 10.2 Per-Horizon-Phase Prediction Quality

<p align="center"><img src="./GRM Table 4 - Horizon Prediction.png" alt="Table 4：不同剩余周期阶段的预测质量" width="760" style="max-width: 100%; height: auto;"></p>

> Table 4：越接近周期末尾，成本与价值曲线 MSE 越低；但剩余流量分母变小，因此 traffic MAPE 从 early 的 $2.7\%$ 升至 late 的 $7.4\%$。

论文认为这一权衡会被滚动重规划部分吸收：晚期曲线更容易预测，流量相对误差虽上升，但可影响的剩余 tick 已经更少；理论上流量误差项按约 $O(\epsilon_I\log T)$ 累积。

### 10.3 Sensitivity to Traffic-Loss Weight

<p align="center"><img src="./GRM Table 5 - Traffic Loss Weight.png" alt="Table 5：流量损失权重敏感性" width="620" style="max-width: 100%; height: auto;"></p>

> Table 5：默认 $\lambda_I=0.1$ 得分最高；减到 $0.05$ 的损失大于增到 $0.5$，说明剩余流量预测对固定总成本和总价值的绝对尺度很重要。

这一结果也对应公式（20）至（21）：即使平均响应曲线正确，$\widehat I_{t:T}$ 明显偏差仍会使预测总成本和总价值整体缩放错误，进而移动预算根与 CPA 根。
