---
tags:
  - 自动出价
  - AIGB
  - DiffBid
  - Diffusion
  - 论文精读
created: 2026-07-28
---

# AIGB：怎样生成完整出价轨迹

论文： [AIGB: Generative Auto-bidding via Diffusion Modeling](https://arxiv.org/abs/2405.16141)  
会议：KDD 2024  
论文中的模型名：DiffBid

> **一句话总结：** AIGB 将自动出价改写成条件生成问题：先根据收益、约束和反馈生成一整段未来状态轨迹，再用非马尔可夫逆动力学把“希望到达的下一状态”解码成当前出价参数，最后通过解析竞价公式得到曝光级 bid。

## 论文结构总览

| 论文部分 | 本文对应内容 |
|---|---|
| 1. Introduction | 为什么自动出价不适合只用当前状态逐步决策，以及 AIGB 的贡献 |
| 2. Preliminary | 多约束出价问题、状态、动作、奖励和轨迹定义 |
| 3. AIGB Paradigm | 先生成状态轨迹，再生成动作的分层范式 |
| 4. Diffusion Auto-bidding Model | DiffBid 的扩散建模、训练、条件和复杂度 |
| 5. Theoretical Analysis | 为什么 MLE 形式的轨迹生成对应一个非马尔可夫决策问题 |
| 6. Experiments | 离线仿真、消融、深度分析和线上 A/B 测试 |
| 7. Related Works | Offline RL、自动出价和扩散模型相关工作 |
| 8. Conclusion | 论文结论和未来工作 |
| Appendix A | 符号、DDPM 补充、配置、伪代码、动作控制、统计分析和理论证明 |

## 1. Introduction：引言

### 1.1 自动出价为什么是长时域决策问题

传统人工出价需要不断调整 bid，但线上广告平台面对的是海量、连续到来的曝光机会。自动出价系统通常每几分钟重新调整一次策略，同时还要考虑曝光分布、预算、平均成本和业务价值。因此一次投放 episode 往往跨越很长时间，早期的出价会影响后续能够获得的流量和剩余预算。

论文把自动出价看成一个长时域序列决策问题，而不是每个时间窗口独立做一次局部预测。

### 1.2 论文对 MDP 假设的质疑

许多 RL 自动出价方法把环境写成 MDP，假设下一状态只由当前状态和当前动作决定：

$$
(s_t,a_t) \longrightarrow (s_{t+1},r_t).
$$

论文通过统计分析发现，下一状态与更长历史状态序列之间存在明显相关性。也就是说，只看最近一个状态，可能无法解释当前预算节奏、流量变化和市场竞争状态。

![[AIGB Figure 1 - History Next State Correlation-1.png]]

**Figure 1：历史状态长度与下一状态之间的相关性。** 论文用它说明：自动出价环境中，历史长度增加后，下一状态的相关性仍可能增强，单纯的 Markov 化会丢失信息。

除了状态依赖更长历史，传统 RL 还面临两个问题：

1. 回报通常在较长时间之后才体现，奖励稀疏；
2. Bellman 递推会把估计误差沿时间传播，在离线数据覆盖有限时尤其容易出现复合误差。

### 1.3 AIGB 的核心想法

AIGB 不直接训练“当前状态到当前动作”的策略，而是把问题拆成两步：

1. **轨迹规划：** 在 return、约束和人类反馈等条件下生成未来状态轨迹；
2. **动作执行：** 根据当前历史状态和目标下一状态，通过 inverse dynamics 解码出当前 bidding parameters。

论文提出的 DiffBid 使用条件 DDPM 完成第一步，并使用非马尔可夫 inverse dynamics 完成第二步。这样做的重点是直接学习“整段轨迹与最终效果”的关系，而不是只学习相邻状态转移。

论文报告的主要结果包括：

- 离线仿真中，在不同预算和数据规模下超过 USCB、BCQ、CQL、IQL 和 DT；
- 线上 A/B 测试中，Buycnt 提升 2.09%，GMV 提升 2.81%，ROI 提升 3.36%；
- GPU 推理耗时约 0.2 秒/请求，基线约 0.07 秒/请求。

## 2. Preliminary：预备知识

### 2.1 Problem Formulation：多约束出价问题

一段投放期间有 $N$ 个按顺序到达的曝光机会。对曝光 $i$：

- $b_i$：提交的 bid；
- $o_i\in\{0,1\}$：是否赢得曝光；
- $c_i$：赢得曝光后的成本；
- $v_i$：赢得曝光带来的业务价值；
- $B$：广告主预算。

最基本的目标是在预算内最大化总价值：

**预算约束下的价值最大化**

$$
\max_{o_i}\sum_i o_i v_i,
\qquad
\text{s.t.}\quad \sum_i o_i c_i\le B.
\qquad \text{(1)}
$$

论文进一步把多个成本相关约束统一写成 ratio 形式：

**统一约束形式**

$$
\frac{\sum_i c_{ij}o_i}{\sum_i p_{ij}o_i}\le C_j,
\qquad j=1,\ldots,J.
\qquad \text{(2)}
$$

其中 $p_{ij}$ 可以是 return、点击、转化等 performance indicator，也可以是常数；$c_{ij}$ 是约束对应的成本项；$C_j$ 是第 $j$ 个约束的上限。

因此，多约束出价问题 MCB 可以写成：

**Multi-constrained Bidding**

$$
\begin{aligned}
\max_{o_i}\quad &\sum_i o_i v_i\\
\text{s.t.}\quad
&\sum_i o_i c_i\le B,\\
&\frac{\sum_i c_{ij}o_i}{\sum_i p_{ij}o_i}\le C_j,\quad \forall j,\\
&o_i\in\{0,1\}.
\end{aligned}
\qquad \text{(3)}
$$

### 2.2 解析竞价形式

论文引用已有研究给出的最优出价形式：

**多约束下的解析 bid**

$$
b_i^*=\lambda_0v_i+C_i\sum_{j=1}^{J}\lambda_jp_{ij}.
\qquad \text{(4)}
$$

这里 $\lambda_0,\lambda_1,\ldots,\lambda_J$ 是需要随环境变化而校准的 bidding parameters。论文源码在这里使用大写 $C_i$，但上下文中的 $C_j$ 表示约束阈值；阅读时应把它理解为解析竞价式中的成本相关项，而不要与约束上限混淆。

只考虑预算时，它对应 Max Return bidding；同时考虑预算和 CPC 时，则对应 Target-CPC bidding。

从 cost-effectiveness 的角度，也可以把曝光按 CE 排序，选择超过阈值 $ce^*$ 的曝光。此时预算和约束最终会体现为一个需要校准的阈值或参数。

### 2.3 Auto-Bidding as Decision-Making：状态、动作、奖励和轨迹

论文定义：

- **状态 $s_t$：** 时间窗口 $t$ 的实时广告状态，包括剩余时间、剩余预算、预算消耗速度、实时 CPC 和平均 CPC 等；
- **动作 $a_t$：** 当前时间窗口对 bidding parameters 的调整，维度与 $\lambda_j$ 的数量一致；
- **奖励 $r_t$：** 当前窗口内为目标带来的价值；
- **轨迹 $\tau$：** 一个 episode 内的状态、动作、奖励序列。

若环境转移只依赖 $(s_t,a_t)$，就是 MDP；如果还依赖更长的历史，就是非马尔可夫决策过程。论文的经验观察支持后一种情况。

![[AIGB Figure 2 - Overall Framework.png]]

**Figure 2：Generative Auto-bidding 总体框架。** 论文中扩散模块生成状态轨迹，逆动力学模块再生成 bidding parameters；图中的 bid 不是扩散网络直接输出的。

## 3. AIGB Paradigm for Auto-bidding：AIGB 范式

### 3.1 为什么优化状态轨迹

论文的统计分析给出一个关键观察：在该广告系统中，成本与 winning impressions 数量之间具有稳定关系，而且每个时间窗口的成本可以由状态轨迹中的预算变化近似得到。因此，一个好的出价策略可以转化为寻找一条好的状态轨迹。

这使得自动出价可以拆成两个监督学习问题：

$$
\text{条件轨迹生成}
\quad+
\text{状态到动作的逆动力学解码}.
$$

### 3.2 层级化执行链路

**第一层：生成未来状态轨迹。** 给定历史状态和目标条件，DiffBid 学习：

$$
p_\theta(x_0\mid y),
$$

其中 $x_0=(s_1,\ldots,s_T)$ 是完整的状态轨迹，$y$ 可以包含 return、约束或反馈。

**第二层：把目标状态转成动作。** 生成当前计划的下一状态 $s'_{t+1}$ 后，逆动力学模型根据历史窗口和目标下一状态输出：

$$
\hat a_t=f_\phi(s_{t-L:t},s'_{t+1}).
$$

**第三层：把参数动作转成曝光级 bid。** $\hat a_t$ 中的参数代入公式 4，再结合每条曝光自己的 $v_i,c_i,p_{ij}$，得到实际 $b_i^*$。

因此，AIGB 的粒度是：

| 粒度 | 输出 | 负责模块 |
|---|---|---|
| 轨迹级 | 未来状态轨迹 | 条件扩散模型 |
| 窗口级 | 当前 bidding parameters | inverse dynamics |
| 曝光级 | 最终 bid | 解析竞价公式 |

### 3.3 与逐窗口 RL 的区别

逐窗口 RL 更像是：

$$
(s_t,a_t)\rightarrow s_{t+1},r_t\rightarrow Q/\pi.
$$

AIGB 则直接建模：

$$
(\text{完整状态轨迹},\text{return/约束/反馈})
\rightarrow
\text{未来状态轨迹}.
$$

它并不要求把所有长期关系都压缩成当前状态，也不需要用 Bellman 递推逐步传播最终回报。

## 4. Diffusion Auto-bidding Model：DiffBid

### 4.1 Diffusion Modeling of Auto-bidding

#### 4.1.1 Overview：条件轨迹生成

论文首先用最大似然估计描述轨迹生成目标：

**条件轨迹生成的 MLE 目标**

$$
\max_\theta\;\mathbb E_{\tau\sim D}
\left[\log p_\theta\big(x_0(\tau)\mid y(\tau)\big)\right].
\qquad \text{(5)}
$$

其中 $x_0(\tau)$ 是日志中的干净状态轨迹，$y(\tau)$ 是与轨迹对应的 return、约束和反馈条件。

扩散模型把条件分布拆成两个过程：

**前向和反向分布**

$$
q(x_{k+1}\mid x_k),
\qquad
p_\theta(x_{k-1}\mid x_k,y).
\qquad \text{(6)}
$$

- $q$：训练时逐步加噪；
- $p_\theta$：生成时逐步去噪。

#### 4.1.2 Forward Process via Diffusion over States：对状态轨迹加噪

论文只对状态序列做扩散，而不是直接对动作或曝光级 bid 做扩散：

**状态轨迹表示**

$$
x_k(\tau):=\big(s_1,\ldots,s_t,\ldots,s_T\big)_k.
\qquad \text{(7)}
$$

它可以看成一个二维数组：第一维是时间窗口，第二维是状态特征。

每一步的前向加噪是高斯 Markov 链：

**单步前向加噪**

$$
q(x_k\mid x_{k-1})
=\mathcal N\left(x_k;\sqrt{1-\beta_k}\,x_{k-1},\beta_k I\right).
\qquad \text{(8)}
$$

当扩散步数增加，轨迹逐渐接近标准高斯噪声；训练目标是让网络学会从带噪轨迹中识别加入的噪声。

论文采用 cosine noise schedule 平滑设置 $\beta_k$，避免噪声强度突然变化。附录中给出：

**cosine noise schedule**

$$
\bar\alpha_k
=\frac{g(k)}{g(0)}
=\frac{\cos\left(\frac{k/K+\gamma}{1+\gamma}\frac{\pi}{2}\right)}
{\cos\left(\frac{\gamma}{1+\gamma}\frac{\pi}{2}\right)}.
\qquad \text{(9)}
$$

其中 $\alpha_k=1-\beta_k$，

$$
\bar\alpha_k=\prod_{i=1}^{k}\alpha_i.
$$

#### 4.1.3 Reverse Process for Bid Generation：反向生成状态轨迹

生成时从高斯噪声 $x'_K\sim\mathcal N(0,I)$ 出发，在 return、约束和反馈条件下逐步还原轨迹。

论文使用 classifier-free guidance。训练时随机丢弃条件，使同一个噪声网络同时学会有条件和无条件预测；生成时把两种噪声预测线性组合：

**classifier-free guidance**

$$
\hat\epsilon_k
=\epsilon_\theta(x_k,k)
+\omega\left[
\epsilon_\theta(x_k,y,k)-\epsilon_\theta(x_k,k)
\right].
\qquad \text{(10)}
$$

其中 $\omega$ 控制条件引导强度。

根据预测噪声，反向过程采样：

**反向高斯采样**

$$
x_{k-1}\sim
\mathcal N\left(x_{k-1};
\mu_\theta(x_k,y,k),
\Sigma_\theta(x_k,k)\right).
\qquad \text{(11)}
$$

论文采用的 DDPM 参数化为：

**反向均值和方差**

$$
\mu_\theta(x_k,y,k)
=\frac{1}{\sqrt{\alpha_k}}
\left(x_k-\frac{\beta_k}{\sqrt{1-\bar\alpha_k}}\hat\epsilon_k\right),
\qquad
\Sigma_\theta(x_k,k)=\beta_k I.
\qquad \text{(12)}
$$

在线服务时，每个窗口都把已经发生的历史状态重新写回当前轨迹，再对未来部分执行反向去噪。也就是说，模型虽然生成整段轨迹，但不会重新改写已经发生的历史。

**在线反向采样**

$$
x'_{k-1}
=\mu_\theta(x'_k,y,k)+\sqrt{\beta_k}\,z,
\qquad z\sim\mathcal N(0,I).
\qquad \text{(13)}
$$

从 $x'_0$ 中取计划下一状态 $s'_{t+1}$，再交给 inverse dynamics。

### 4.2 DiffBid Training：训练目标

DiffBid 由两个回归任务组成：

1. 噪声预测网络预测 forward diffusion 加入的噪声；
2. inverse dynamics 预测能够实现真实状态转移的动作。

**联合训练损失**

$$
\begin{aligned}
\mathcal L(\theta,\phi)
=&\;\mathbb E_{k,\tau\in\mathcal D}
\left[\|\epsilon-\epsilon_\theta(x_k(\tau),y(\tau),k)\|_2^2\right]\\
&+\mathbb E_{(s_{t-L:t},a_t,s'_{t+1})\in\mathcal D}
\left[\|a_t-f_\phi(s_{t-L:t},s'_{t+1})\|_2^2\right].
\end{aligned}
\qquad \text{(14)}
$$

第一项是带 mask 的噪声预测 MSE 的基本形式，第二项是动作解码的 MSE。论文源码没有引入额外的复杂 RL loss。

训练流程：

1. 从离线数据中抽取轨迹 $\tau$；
2. 随机采样扩散步 $k$ 和高斯噪声 $\epsilon$；
3. 根据公式 8 构造 $x_k$；
4. 预测噪声并计算第一项损失；
5. 从日志中取历史状态、真实动作和真实下一状态，计算第二项损失；
6. 随机丢弃 $y(\tau)$，训练 classifier-free guidance 所需的无条件分支。

### 4.3 Design of Conditions：条件设计

#### 4.3.1 Generation with Returns：按总收益生成

一条轨迹的总收益为：

$$
R(\tau)=\sum_{t=1}^{T}r_t.
$$

论文使用数据集内的最小值和最大值进行归一化：

**return 归一化**

$$
R
=\frac{R(\tau)-R_{\min}}
{R_{\max}-R_{\min}}.
\qquad \text{(15)}
$$

训练时，归一化后的 $R$ 作为条件输入；生成时设置 (R=1)，让模型生成数据覆盖范围内偏高收益的状态轨迹。这里的重点是：高 return 是生成条件，不是由模型在线计算出来的即时 reward。

#### 4.3.2 Generation with Constraints or Human Feedback：按约束和反馈生成

对于 Target-CPC，论文用二值变量表示轨迹是否满足约束：

**约束条件变量**

$$
E=\mathbb I_{x\le C}(x),
\qquad
x=\frac{\sum_i c_i o_i}{\sum_i p_i o_i}.
\qquad \text{(16)}
$$

生成时把 (E=1) 作为条件，就可以要求模型优先生成不违反 CPC 约束的轨迹。

论文还验证了两类反馈：

- **Smoothness：** 希望相邻时间窗口的 cost 变化更平滑，使用平均相邻 cost 变化量作为指标；
- **Early/Late Spend：** 希望预算更多在早半天或晚半天消耗，使用前半天成本占总成本的比例作为指标。

多个条件可以拼成向量 $y(\tau)$，因此一个 DiffBid 可以同时支持收益、约束和过程偏好的组合，而不是为每一种目标单独训练一个模型。

### 4.4 Complexity Analysis：复杂度

设噪声预测网络的时间复杂度为 $O(T_1)$，inverse dynamics 的复杂度为 $O(T_2)$，batch 大小为 $|\mathcal B|$，则训练一个 epoch 的复杂度为：

$$
O\left(|\mathcal B|(T_1+T_2)\right).
$$

生成时，扩散步数为 $K$，轨迹长度为 $L$，推理复杂度约为：

$$
O\left(KL(T_1+T_2)\right).
$$

论文强调，出价轨迹所需的扩散步数不必像图像生成那样非常大；在实验中较小的 $K$ 已经能获得较好的效果。

## 5. Theoretical Analysis：理论分析

### 5.1 MDP 与历史决策过程

- **MDP：** 下一状态和奖励只由当前状态、当前动作决定；
- **HDP / 非马尔可夫决策过程：** 下一步结果可以依赖完整历史 $s_{0:t}$。

AIGB 的条件生成器学习的是历史条件下的状态序列分布，而不是强行把历史压缩为一个 Markov state。

### 5.2 MLE 与非马尔可夫决策问题的对应

论文的理论结论是：在若干理想化前提下，如果 Markovian 环境转移 $p_{\gamma^*}(s_{t+1}\mid s_t,a_t)$ 已知，且真实历史条件分布 $p^*(s_{t+1}\mid s_{0:t})$ 可获得，那么可以为任意历史策略 $p_\alpha(a_t\mid s_{0:t})$ 构造一个非马尔可夫 reward：

**由策略和环境转移构造历史 reward**

$$
r_\alpha(s_{t+1},s_{0:t})
=\log\int
p_\alpha(a_t\mid s_{0:t})
p_{\gamma^*}(s_{t+1}\mid s_t,a_t)\,da_t.
\qquad \text{(17)}
$$

对应的 value 目标为：

**非马尔可夫决策目标**

$$
\sum_{t=0}^{T}
\mathbb E_{p^*(s_{0:t})}
\left[V^{p_\alpha}(s_{0:t})\right]
=
\mathbb E_{p^*(s_{0:T})}
\left[
\sum_{t=0}^{T}\sum_{k=t}^{T}
r_\alpha(s_{k+1};s_{0:k})
\right].
\qquad \text{(18)}
$$

论文据此说明：最大化状态轨迹的 MLE，与求解一个相应的非马尔可夫序列决策问题在最优性上是一致的。

### 5.3 理论结论的实际含义

这不是说 DiffBid 已经知道真实环境转移，也不是说它在线求解了一个显式 Q 函数。理论结果表达的是：

1. 轨迹生成的 MLE 可以对应一个历史依赖的决策目标；
2. 因此模型不必强行依赖 MDP 假设；
3. 这解释了它为什么适合随机性强、回报稀疏、长期依赖明显的广告环境。

## 6. Experiments：实验

### 6.1 Experimental Setup：实验设置

#### 6.1.1 Experimental Environment

论文搭建了 Real Advertising System（RAS）离线广告仿真系统，episode 为 96 个时间步，每步对应 15 分钟。环境包含多个广告主，广告主之间通过竞价争夺曝光机会。

附录给出的环境参数包括：

| 参数 | 值 |
|---|---:|
| 广告主数量 | 30 |
| episode 时间步数 $T$ | 96 |
| 最小预算 | 1000 元 |
| 最大预算 | 4000 元 |
| 最低 bid | 0 元 |
| 最高 bid | 1000 元 |
| 单次曝光最大价值 | 1 |
| 最大市场价格 | 1000 元 |

#### 6.1.2 Data Collection

离线数据来自 USCB 日志，设置包括：

- **USCB-5K：** 约 5,000 条轨迹；
- **USCBEx-5K：** 约 5,000 条，加入探索行为；
- **USCBEx-50K：** 约 50,000 条，加入探索行为。

USCBEx 通过随机探索扩大动作和状态覆盖，论文用它研究离线数据规模与探索覆盖对模型的影响。

#### 6.1.3 Baselines

对比方法包括：

- USCB：自动出价基线；
- BCQ：限制动作分布的 offline RL；
- CQL：保守 Q 学习；
- IQL：隐式 Q 学习；
- DT：Decision Transformer；
- DiffBid：AIGB 的扩散出价模型。

#### 6.1.4 Implementation Details

论文报告的主要设置：

- 扩散步数 $K\in\{5,10,20,30,50\}$；
- 历史长度 $L\in\{1,2,3\}$；
- classifier-free guidance 的 $\omega=0.2$；
- 条件随机丢弃概率为 0.2；
- batch size 约为训练轨迹的 2%；
- 训练 500 epochs；
- U-Net 隐藏维度为 128 或 256；
- Adam 学习率为 $10^{-4}$。

#### 6.1.5 Evaluation

测试预算设置为 1500、2000、2500、3000。每个方法随机初始化 50 次，报告 top-5 分数的平均值；核心指标是整个 episode 的 cumulative reward。

### 6.2 Performance Evaluation：主结果

**表 1：不同数据集和预算下的 cumulative reward。** 下表保留论文中的数值；`improv` 是 DiffBid 相对最接近基线的提升。

| Training Dataset | Budget | USCB | BCQ | CQL | IQL | DT | DiffBid | improv |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| USCB-5K | 1500 | 454.25 | 454.72 | 461.82 | 456.80 | 477.39 | **480.76** | 0.71% |
| USCB-5K | 2000 | 482.67 | 483.50 | 475.78 | 486.56 | 507.30 | **511.17** | 0.76% |
| USCB-5K | 2500 | 497.66 | 498.77 | 481.37 | 518.27 | 527.88 | **531.29** | 0.65% |
| USCB-5K | 3000 | 500.60 | 501.86 | 491.36 | 549.19 | 550.66 | **556.32** | 1.03% |
| USCBEx-5K | 1500 | 454.25 | 453.74 | 358.43 | 464.69 | 378.64 | **475.62** | 2.35% |
| USCBEx-5K | 2000 | 482.67 | 487.63 | 356.80 | 529.36 | 439.03 | **544.38** | 2.84% |
| USCBEx-5K | 2500 | 497.66 | 510.75 | 356.41 | 613.67 | 505.43 | **624.29** | 1.73% |
| USCBEx-5K | 3000 | 500.60 | 512.18 | 355.42 | 670.65 | 574.79 | **678.73** | 1.17% |
| USCBEx-50K | 1500 | 454.25 | 458.64 | 435.06 | 446.23 | 396.24 | **495.57** | 8.05% |
| USCBEx-50K | 2000 | 482.67 | 491.72 | 431.49 | 533.58 | 478.29 | **551.73** | 3.40% |
| USCBEx-50K | 2500 | 497.66 | 513.23 | 428.39 | 592.32 | 554.48 | **606.34** | 2.37% |
| USCBEx-50K | 3000 | 500.60 | 526.21 | 425.29 | 633.26 | 611.50 | **644.88** | 1.83% |

论文的主要观察：offline RL 整体优于 USCB，DiffBid 在不同预算和数据规模下都取得最高累计奖励；数据规模从 5K 增大到 50K 后，DiffBid 的收益进一步提升。

### 6.3 Ablation Study：消融实验

**表 2：DiffBid 消融。**

| Model | USCBEx-5K | USCBEx-50K |
|---|---:|---:|
| DiffBid | 2280.12 | 2395.60 |
| DiffBid w/o cond | 1812.64 | 1852.21 |
| DiffBid w/o non-mkv | 2254.78 | 2287.41 |

- `w/o cond`：把条件设为 0，而不是使用目标条件；
- `w/o non-mkv`：只使用当前状态和预测下一状态，不使用非马尔可夫历史状态窗口。

两个版本都出现明显下降，说明条件控制和历史状态信息都对最终效果有贡献。

### 6.4 In-depth Analysis：深入分析

#### 6.4.1 Study of State Transition

论文比较了 USCB 和 DiffBid 一天内的剩余预算曲线：

![[AIGB Figure 3 - State Transition - USCB.png]]

![[AIGB Figure 3 - State Transition - DiffBid.png]]

**Figure 3：单个 episode 的状态转移。** USCB 下不少广告主没有充分消耗预算；DiffBid 生成的轨迹更倾向于完成 80% 以上的预算。论文认为，高预算完成率轨迹通常与较高累计回报相关，扩散模型可以从数据中学习到这种轨迹形状。

#### 6.4.2 Performance under Constraints and Feedbacks

论文设置不同 CPC 阈值，比较 IQL 和 DiffBid 控制约束超限比例、同时保持收益的能力：

![[AIGB Figure 4 - CPC - IQL-1.png]]

![[AIGB Figure 4 - CPC - DiffBid-1.png]]

**Figure 4：CPC 约束下的表现。** DiffBid 能通过改变条件控制不同程度的 CPC 超限比例，并在控制约束的同时保持较好的 return。

论文还把平滑和早花/晚花反馈编码成条件：

![[AIGB Figure 5 - Smoothness-1.png]]

![[AIGB Figure 5 - Early Spend-1.png]]

**Figure 5：人类反馈条件。** 生成出的轨迹分布会随反馈条件改变，说明同一个模型可以组合多个过程偏好，而不必为每个偏好单独训练一个模型。

#### 6.4.3 Impact of Diffusion Steps

![[AIGB Figure 6 - Diffusion Steps-1.png]]

**Figure 6(a)：扩散步数影响。** 小预算广告主对扩散步数更敏感；较大预算下，约 30 步通常已经能取得较好结果。

#### 6.4.4 Stability

![[AIGB Figure 6 - Stability-1.png]]

**Figure 6(b)：稳定性。** CQL 和 IQL 在不同随机种子下更容易出现性能波动，DiffBid 的失败次数更少，表现更稳定。

### 6.5 Online A/B Test：线上实验

线上实验在阿里巴巴广告平台进行，时间为 2024 年 2 月 1 日至 2 月 8 日，基线是表现最好的 IQL。

**表 3：线上 A/B 测试结果。**

| Metrics | #Plan | Budget | Cost | Buycnt | GMV | ROI |
|---|---:|---:|---:|---:|---:|---:|
| Baseline | 2068 | 886744 | 834426.104 | 23584.6836 | 1853823 | 2.221 |
| DiffBid | 2068 | 886744 | 829992.384 | 24078.6883 | 1905954 | 2.296 |
| compare | - | - | -0.53% | +2.09% | +2.81% | +3.36% |

论文报告：Buycnt 提升 2.09%，GMV 提升 2.81%，ROI 提升 3.36%；GPU 加速下 DiffBid 约 0.2 秒/请求，基线约 0.07 秒/请求。

## 7. Related Works：相关工作

### 7.1 Offline RL

Offline RL 从固定日志学习策略，代表方法包括 BCQ、CQL、IQL 和 DT。它们分别通过动作分布约束、保守价值估计、隐式价值学习或条件序列建模来减轻离线数据外推风险。

AIGB 与它们的关键区别是：它不是逐步估计 (Q(s,a)) 或直接输出动作策略，而是学习整段状态轨迹的条件分布，再通过逆动力学解码动作。

### 7.2 Auto-bidding

自动出价研究通常从在线竞价机制、预算 pacing、成本约束和 RL 策略优化出发。AIGB 关注的是长期出价轨迹、稀疏回报和非马尔可夫状态依赖，并且把多种工业指标统一放入条件向量。

### 7.3 Diffusion Models

扩散模型通过前向加噪和反向去噪学习数据分布，已经应用于图像、视频和音频生成。AIGB 将其用于状态轨迹生成：噪声网络生成的是未来状态，不是最终曝光级 bid；动作由 inverse dynamics 和解析竞价层完成。

## 8. Conclusion：结论

论文提出了一个生成式自动出价范式，并实现了条件扩散模型 DiffBid。其核心是：

1. 把自动出价从逐窗口动作预测改写为完整状态轨迹生成；
2. 用 return、约束和反馈控制生成方向；
3. 用非马尔可夫 inverse dynamics 把轨迹计划落成窗口级参数；
4. 用解析竞价公式得到曝光级 bid。

实验表明，DiffBid 在离线仿真和线上广告系统中都优于多个 RL 基线。论文未来工作包括降低扩散生成延迟、提高模型鲁棒性。

## Appendix A：附录

### A.1 Notations：符号表

| 符号 | 含义 |
|---|---|
| $B$ | 广告主预算 |
| $C_j$ | 第 $j$ 个约束上限 |
| $o_i$ | 是否赢得第 $i$ 个曝光 |
| $v_i$ | 第 $i$ 个曝光的真实价值 |
| $b_i^*$ | 理论最优 bid |
| $s_t$ | 时间窗口 $t$ 的状态 |
| $a_t$ | 时间窗口 $t$ 的动作/出价参数 |
| $\hat a_t$ | 预测出的出价参数 |
| $R$ | 轨迹 return |
| $E$ | 约束满足指示变量 |
| $\epsilon_\theta$ | 预测噪声的去噪网络 |
| $f_\phi$ | 生成动作的 inverse dynamics 网络 |
| $\beta_k$ | 第 $k$ 步噪声调度系数 |
| $\alpha_k$ | $1-\beta_k$ |
| $\bar\alpha_k$ | $\prod_{i=1}^{k}\alpha_i$ |

### A.2 Diffusion Modeling：DDPM 补充

#### A.2.1 Forward process

给定原始轨迹 $x_0$，任意扩散步 $k$ 的带噪轨迹可以直接采样为：

**任意步的前向采样**

$$
q(x_k\mid x_0)
=\mathcal N\left(x_k;
\sqrt{\bar\alpha_k}x_0,
(1-\bar\alpha_k)I\right).
\qquad \text{(19)}
$$

等价地：

$$
x_k=\sqrt{\bar\alpha_k}x_0
+\sqrt{1-\bar\alpha_k}\,\epsilon,
\qquad \epsilon\sim\mathcal N(0,I).
$$

#### A.2.2 Reverse process

反向过程学习 $p_\theta(x_{k-1}\mid x_k)$，每一步根据当前带噪轨迹估计噪声，再计算下一步的高斯均值和方差。DDPM 的 ELBO 可以转化为噪声预测目标：

**噪声预测目标**

$$
\mathbb E_{k,x_0,\epsilon}
\left[
\left\|
\epsilon-\epsilon_\theta
\left(\sqrt{\bar\alpha_k}x_0
+\sqrt{1-\bar\alpha_k}\epsilon,k\right)
\right\|_2^2
\right].
\qquad \text{(20)}
$$

### A.3 Model Configuration：模型结构

论文明确说明：

- $\epsilon_\theta$ 使用 temporal U-Net；
- U-Net 包含 3 个重复 residual blocks；
- 每个 block 使用两层 temporal convolution、group normalization 和 Mish 激活；
- 时间步 embedding 和条件 embedding 都是 128 维；
- 两种 embedding 分别经过两层 MLP，隐藏维度 256、激活函数为 Mish，然后拼接；
- 拼接后的 embedding 加到每个 block 第一层 temporal convolution 的激活中；
- $f_\phi$ 使用 3 层 MLP。

所以，AIGB 的“扩散网络”不是普通的全连接 MLP，而是专门处理时间序列的 temporal U-Net；逆动力学解码器才是 3 层 MLP。

### A.4 Pseudo-code：伪代码

#### A.4.1 Bid Generation with DiffBid

```text
输入：噪声网络 epsilon_theta，逆动力学 f_phi，条件 y，扩散步数 K，噪声系数 beta
输出：当前 bidding parameters a_hat_t

1. 获取当前已观测历史状态 s_0:t
2. 采样初始噪声轨迹 x'_K ~ N(0, I)
3. 对 k = K, ..., 1：
   a. 将历史状态 x'_k[:t] 固定为真实 s_0:t
   b. 用 epsilon_theta 预测噪声，并使用 classifier-free guidance
   c. 根据 DDPM 均值和方差得到 x'_{k-1}
   d. 重新固定历史 prefix
4. 从 x'_0 中取历史窗口 s_{t-L:t} 和计划下一状态 s'_{t+1}
5. a_hat_t = f_phi(s_{t-L:t}, s'_{t+1})
6. 将 a_hat_t 代入解析竞价公式生成曝光级 bid
```

#### A.4.2 Training of DiffBid

```text
输入：初始化的 theta、phi，离线轨迹集合 D
输出：训练好的 theta、phi

重复直到收敛：
1. 从 D 中采样一批轨迹
2. 对每条轨迹采样扩散步 k 和高斯噪声 epsilon
3. 根据前向过程构造带噪轨迹 x_k
4. 计算噪声预测损失和 inverse dynamics 动作损失
5. 对 theta、phi 做梯度下降
```

### A.5 Analytical Results for Action Control：动作控制实验

论文把 return 重新定义为：奇数时间步动作之和减去偶数时间步动作之和，用来直接测试模型能否根据条件控制动作轨迹。

![[AIGB Appendix - Action Control-1.png]]

**附录图：动作控制能力。** DiffBid 比 IQL 更能按照目标条件控制长轨迹动作，论文将原因归结为：DiffBid 直接建模轨迹与 return 的关系，而 RL 在长时域动作控制中更容易受到误差传播影响。

### A.6 Statistical Analyses for Bidding Trajectory：出价轨迹统计分析

#### A.6.1 Cost-effectiveness 曲线

论文观察到，随着 winning impressions 数量增加，cost-effectiveness 呈 power-law decline。不同时间步的衰减速度可能不同，但“可赢曝光数量”和成本效率之间存在稳定关系。

![[AIGB Appendix - Cost Effectiveness.png]]

这支持了论文的关键转换：最优策略可以近似对应每个时间步应赢得多少曝光，从而对应一条目标状态轨迹。

#### A.6.2 Impression cost fluctuation

![[AIGB Appendix - Impression Cost Fluctuation.png]]

论文发现单次曝光成本在整个 episode 内相对稳定，波动小于 5%。因此可以用平均成本 $\bar c$ 近似单次成本：

$$
c_t\approx n_t\bar c,
$$

其中 $n_t$ 是时间步 $t$ 赢得的曝光数。又因为每一步的成本可以通过相邻状态中的剩余预算差得到，所以成本轨迹能够从状态轨迹中恢复。

### A.7 Theoretical Analysis：理论证明的主线

附录先定义 MDP 和 HDP：

- MDP 是从 state-action 到 state-reward 的随机映射；
- HDP 是从 history-action 到 observation-reward 的随机映射。

证明主线分为四步：

1. 最大似然训练使模型分布 $p_\theta$ 接近真实状态轨迹分布 $p^*$；
2. 由真实未来轨迹分布定义历史依赖的 value function；
3. 用状态转移概率和策略概率构造 reward、Q 和 V 的 Bellman 关系；
4. 证明该构造下的最优策略与 MLE 目标具有相同的最优解。

更直观地说，论文不是声称“扩散模型就是 RL”，而是证明：在给定条件下，最大似然轨迹生成可以被解释成一个非马尔可夫决策问题的最优解。

## 最终理解：AIGB 到底输出什么

完整链路如下：

$$
\text{历史状态 }s_{0:t}
\xrightarrow[\text{return/约束/反馈}]{\text{conditional diffusion}}
\text{未来状态轨迹 }x'_0
\xrightarrow{\text{取 }s'_{t+1}}
\xrightarrow{f_\phi}
\text{窗口级参数 }\hat a_t
\xrightarrow{\text{解析竞价公式}}
\text{曝光级 bid }b_i^*.
$$

需要特别区分：

- 扩散模型生成的是**状态轨迹**；
- inverse dynamics 生成的是**当前窗口的 bidding parameters**；
- 解析层生成的是**每次曝光最终提交的 bid**；
- 已经发生的历史状态在在线反向采样时会被重新覆盖回真实值，模型只规划当前之后的未来。

因此，AIGB 的核心能力是长时域轨迹规划和条件控制，而不是直接替代底层竞价公式。
