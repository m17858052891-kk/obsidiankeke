---
tags:
  - 自动出价
  - Decision Transformer
  - Inverse Dynamics
  - Q-value
  - AuctionNet
  - 论文调研
created: 2026-08-14
---

# Guide：统一建模与探索的生成式自动出价

论文： [Generative Auto-Bidding with Unified Modeling and Exploration](https://arxiv.org/abs/2605.19457)  
代码： [M2C-Tech/GUIDE](https://github.com/M2C-Tech/GUIDE)  
作者：Mingming Zhang 等，Taobao & Tmall Group / Wuhan University  
会议：SIGIR 2026

## 1. 前置信息：总览、摘要与引言

### 1.1 一句话总览

自动出价的核心矛盾是：只模仿历史策略通常比较稳定，但不容易超过日志策略；过度探索虽然可能获得更高收益，却可能进入分布外动作并带来真实预算风险。

Guide 将这个矛盾拆成三条链路：

```text
历史状态、历史动作、RTG
        -> Decision Transformer
        -> 探索动作 a_hat_t + 下一状态 s_hat_{t+1}

当前状态 s_t + DT 预测的下一状态 s_hat_{t+1}
        -> Inverse Dynamics Module
        -> 更贴近历史行为的备用动作 a_hat_t^idm

DT 动作、IDM 动作
        -> Twin Q 网络评估
        -> 最终动作 a_t^*
```

因此 Guide 是一个 **Explore–Safeguard–Select** 流程：

- **Explore：** DT 通过 Q-value 正则化，尝试比日志动作更高价值的动作；
- **Safeguard：** IDM 根据状态转移重建行为一致、波动较小的备用动作；
- **Select：** Twin Q 网络分别评估两个候选动作，选择当前估计价值更高的动作。

### 1.2 摘要：论文提出了什么

论文首先指出，规则方法难以适应快速变化的广告环境；强化学习方法虽然能进行序列决策，但对长时间依赖和复杂历史行为的表达有限；已有生成式方法能够探索，却通常没有显式的安全回退机制。

Guide 的做法是：

1. 用 Decision Transformer 同时建模历史出价动作和环境状态转移；
2. 用 Q-value 正则化引导 DT 探索更高价值的动作；
3. 用 Inverse Dynamics Module 根据 DT 预测的未来状态，推断一个更贴近历史行为的备用动作；
4. 用 Twin Q 网络在 DT 动作和 IDM 动作之间自适应选择。

论文在公开数据集、广告竞价仿真环境和淘宝线上系统中进行实验。线上 A/B 测试中，Guide 报告 Ad GMV 提升 4.10%、Ad Click 提升 1.40%、Ad Cost 提升 1.66%、Ad ROI 提升 3.52%。

### 1.3 引言：为什么需要 Guide

#### 1.3.1 传统自动出价与 MDP 方法的局限

广告主希望在预算、CPA 或 ROI 等目标下获取更高价值的流量。人工出价和早期 PID 等反馈控制方法实现简单，但依赖人工调参，对竞争环境、流量分布和用户行为变化的适应能力有限。

强化学习把出价写成 MDP：当前状态包含预算、历史结果和市场信息，动作是当前出价，策略根据状态选择动作。但自动出价中的下一状态不仅受当前状态和动作影响，还可能依赖较长的历史轨迹；只用当前状态容易丢失长期节奏信息。

生成式模型将广告出价改写为序列生成问题，能够利用较长历史：

- DT 类方法主要生成出价动作序列；
- Decision Diffusion 类方法主要生成状态序列，再用逆动力学得到动作；
- GAS、GAVE 等方法进一步加入搜索或价值引导。

这些方法仍然存在一个共同缺口：**模型可以探索，但通常没有显式的安全回退机制。**

#### 1.3.2 探索与安全的核心矛盾

如果模型把动作从历史日志中推得很远，可能出现：

- Q 估计在分布外动作上高估；
- 预测的状态转移在真实环境中不可达；
- 单个窗口动作看起来更激进，但全天预算节奏变差；
- 线上无法快速回到已知的稳定策略。

Guide 的基本设计因此是：DT 负责探索，IDM 学习行为轨迹中的可达转移，Q 模块在两个候选动作之间做选择。

#### 1.3.3 Figure 1：不同广告出价建模方式

![[Figure 1 - Different Modeling Approaches.png]]

> 论文原图 Figure 1：Different Modeling Approaches in Ad Bidding。图中的 $a_t$ 和 $s_t$ 分别表示动作与状态，$\hat a_t^*$ 表示更好的动作，Q 表示 Q-value 模块。

图的阅读重点是：不同方法对“状态、动作以及更优动作”的关系建模方式不同。Guide 不仅生成动作，还让 DT 预测下一状态，再用 Q 模块评估不同候选动作。

#### 1.3.4 论文贡献

论文明确总结了三点贡献：

1. 提出统一建模范式，在同一个生成框架里同时捕捉广告环境动态和历史出价动作；
2. 提出“探索—保障—选择”机制，由 DT、IDM 和 Q-value action selector 协同工作；
3. 在离线数据、竞价仿真和真实线上环境中验证 Guide 的效果。

## 2. Preliminary：预备知识

### 2.1 Definition of Auto-Bidding Problem：自动出价问题定义

#### 2.1.1 Problem Setting：问题设置

自动出价的目标是在预算和 CPA 约束下，最大化赢得流量的总价值。令 $x_i\in\{0,1\}$ 表示是否赢得第 $i$ 次曝光，$v_i$ 表示该曝光带来的价值，$c_i$ 表示赢得该曝光的实际成本，则问题写成：

$$
\max_{\{b_i\}_{i=1}^{I}}\sum_{i=1}^{I}x_i v_i. \qquad \text{(1)}
$$

预算约束为：

$$
\sum_{i=1}^{I}x_i c_i\leq B. \qquad \text{(2)}
$$

CPA 约束为：

$$
CPA=\frac{\sum_{i=1}^{I}x_i c_i}{\sum_{i=1}^{I}x_i v_i}\leq C. \qquad \text{(3)}
$$

论文特别指出：预算约束通常被严格执行；CPA 往往只能在 campaign 结束后完整评估，因此在实际系统中通常更接近软约束。

这里的 $b_i$ 是曝光级 bid，但 Guide 后续把可调动作抽象成窗口级 multiplier。也就是说，模型不会为每次曝光都运行一个 Transformer，而是根据窗口状态产生一个可执行的出价参数。

#### 2.1.2 Optimal Bidding Policy：最优出价策略

根据互补松弛条件，论文引用已有结果，将理论最优出价写成曝光价值和 CPA 阈值的函数：

$$
b_i^*=(\lambda_0^*+\lambda_1^*C)v_i=\lambda^*v_i. \qquad \text{(4)}
$$

其中 $\lambda_0^*$ 和 $\lambda_1^*$ 是由 campaign 的预算和 CPA 要求决定的系数，$\lambda^*$ 是统一出价系数。

这个公式的意义不是说线上永远存在一个固定的最优 $\lambda$，而是给出一个基础结构：曝光价值 $v_i$ 决定相对 bid 强度，预算、CPA 和环境状态决定整体 multiplier。

#### 2.1.3 静态 multiplier 为什么不够

真实广告环境中，竞争者出价、流量质量和曝光机会持续变化，因此固定的 $\lambda^*$ 很快会失效。系统需要在每个时间步根据 campaign 状态和市场反馈调整 $\lambda_t$。

这一步把原始优化问题转成序列决策问题：每个时间窗口输出一个动作，动作改变后续的预算消耗、流量获取和奖励。

### 2.2 Sequence Modeling for Auto-bidding Problem：自动出价的序列建模

论文采用 DT 的条件序列建模方式，目标是在给定历史状态、动作、奖励和期望未来表现的情况下生成下一步动作。

定义如下：

- **状态 $s_t$：**第 $t$ 个时刻的出价环境特征，例如剩余预算、剩余时间、历史投放结果；
- **动作 $a_t$：**当前时刻可调的出价参数，例如 $a_t=\lambda_t$；
- **奖励 $r_t$：**第 $t$ 个窗口赢得的流量价值：

$$
r_t=\sum_{n=1}^{N_t}x_n v_n;
$$

- **RTG $R_t$：**从当前时刻到结束的累计奖励：

$$
R_t=\sum_{t'=t}^{T}r_{t'}.
$$

整段 bidding trajectory 表示为：

$$
\tau=(s_1,a_1,r_1,\ldots,s_T,a_T,r_T).
$$

### 2.3 本节作用

Preliminary 做了一个关键抽象：

```text
曝光级 bid 优化
  -> 窗口级 multiplier 决策
  -> 状态、动作、奖励、RTG 组成的长期轨迹
  -> DT / IDM / Q 模块可以共同处理
```

## 3. Method：方法

### 3.1 方法总览

论文方法部分先介绍 DT 与 IDM，再介绍两阶段训练，随后介绍 Q-value 优化和推理时动作选择。

![[Figure 2 - Overview Architecture.png]]

> 论文原图 Figure 2：Overview architecture。左侧是统一建模框架的训练流程，右侧是推理阶段的候选动作生成与 Q-value 选择。

图 2 可以按训练和推理两条链路阅读：

```text
训练：历史轨迹 -> DT 预测动作和下一状态 -> IDM 重建动作 -> Q 训练与正则化

推理：历史上下文 -> DT 动作与下一状态
                 -> IDM 动作
                 -> Q 评估两个动作
                 -> 最终动作
```

### 3.2 Unified Modeling of Bid Trajectories：统一建模出价轨迹

#### 3.2.1 Trajectory Construction and Modeling：轨迹构造与建模

广告竞价的一轮过程按时间顺序记录环境状态、出价动作和对应奖励：

$$
\tau=(s_1,a_1,r_1,s_2,a_2,r_2,\ldots,s_T,a_T,r_T). \qquad \text{(5)}
$$

Guide 让 DT 同时预测下一步动作和下一状态：

$$
(\hat a_t,\hat s_{t+1})\sim DT(R_{t-k+1},s_{t-k+1},a_{t-k+1},\ldots,R_t,s_t). \qquad \text{(6)}
$$

这里的含义是：

- 输入不是当前状态一个点，而是长度为 $k$ 的历史窗口；
- RTG 告诉模型当前希望朝什么回报水平生成；
- $\hat a_t$ 是 DT 给出的候选探索动作；
- $\hat s_{t+1}$ 是 DT 对采取该动作后下一状态的预测。

和 GAS、GAVE 等只重点生成出价动作的 DT 方法不同，Guide 额外预测下一环境状态。论文认为，这样可以获得更多监督信号，也让模型显式学习状态演化；同时，$\hat s_{t+1}$ 会成为 IDM 的输入，连接当前状态和下一状态之间的短期转移。

#### 3.2.2 Inverse Dynamics Module：逆动力学模块

逆动力学的方向与普通环境模型相反：

```text
正向动力学：当前状态 + 动作 -> 下一状态
逆动力学：当前状态 + 下一状态 -> 可能采取的动作
```

给定当前状态 $s_t$ 和 DT 预测的下一状态 $\hat s_{t+1}$，IDM 生成一个候选动作：

$$
\hat a_t^{idm}=f_{idm}(s_t,\hat s_{t+1}). \qquad \text{(7)}
$$

论文说明，$f_{idm}$ 通常用 MLP 参数化。它不是 Transformer，也不是另一个完整的序列模型，而是一个读取两个状态向量、输出连续动作的前馈网络。

训练时，用日志中的真实动作监督 IDM：

$$
\mathcal{L}_{idm}=\mathbb{E}_{(s_t,a_t)\sim\mathcal{D}}
\left[\left\|f_{idm}(s_t,\hat s_{t+1})-a_t\right\|^2\right]. \qquad \text{(8)}
$$

这里有一个容易误解的点：IDM 的输入使用的是 **DT 预测的下一状态**，而不是训练时直接偷看真实的 $s_{t+1}$。这样训练和推理的输入形式一致。

IDM 的第二个作用是反过来约束 DT 的状态预测。如果 DT 生成一个从 $s_t$ 出发不合理、不可达的 $\hat s_{t+1}$，IDM 就很难从这段转移重建出日志动作，IDM loss 会变大，并通过联合训练反馈给 DT。因此，IDM 不只是额外动作头，也在帮助 DT 生成更符合环境动力学的下一状态。

#### 3.2.3 Two-Stage Training：两阶段训练

论文不直接从随机初始化开始让 DT 和 IDM 完全联合训练，而是分两个阶段。

**阶段一：分开训练。**计算 IDM 损失时，对 DT 的下一状态预测执行 stop-gradient：

$$
\mathcal{L}_{idm}'=\mathbb{E}_{(s_t,a_t)\sim\mathcal{D}}
\left[\left\|f_{idm}(s_t,\operatorname{stop\_grad}(\hat s_{t+1}))-a_t\right\|^2\right]. \qquad \text{(9)}
$$

DT 单独学习动作行为克隆和下一状态预测：

$$
\mathcal{L}_{dt}=\mathbb{E}\left[(\hat a_t-a_t)^2+(\hat s_{t+1}-s_{t+1})^2\right]. \qquad \text{(10)}
$$

**阶段二：联合训练。**预训练完成后，放开 DT 预测状态到 IDM 的梯度，使 IDM 的逆动力学误差可以反向影响 DT：

$$
\mathcal{L}=\mathcal{L}_{dt}+\mathcal{L}_{idm}. \qquad \text{(11)}
$$

两阶段的工程逻辑是：先让两个模块各自学会基本能力，再让它们围绕状态—动作一致性协同优化。这样可以减少训练早期的梯度不稳定，并让 IDM 先形成质量较好的逆动力学表示。

### 3.3 Q-value-based optimization：基于 Q-value 的优化

仅用离线日志监督时，DT 的动作主要由历史行为决定，通常会停留在日志策略附近。这里要区分两个阶段：Guide 不是认为原始 DT 天然擅长探索，而是在 DT 的行为监督基础上加入 Twin Q。训练时，Q-value 正则化主要推动 DT 生成更高价值的候选动作；推理时，Twin Q 再负责在 DT 候选和 IDM 候选之间进行比较与选择。IDM 本身仍然根据状态转移重建更接近历史行为的保守动作。

#### 3.3.1 Twin Q Networks and Target Networks Architecture

Q 模块包含两个独立的 Q 网络 $Q_1$ 和 $Q_2$。每个网络输入 $(s_t,a_t)$，输出在状态 $s_t$ 下采取动作 $a_t$ 的预期累计回报。

每个在线 Q 网络都有对应的 target Q 网络 $Q_1^{\text{target}}$ 和 $Q_2^{\text{target}}$。target 网络参数通过在线网络参数的指数移动平均更新，用于稳定 TD 目标。

推理和目标计算都取两个 Q 的较小值：

```text
保守 Q(s, a) = min(Q1(s, a), Q2(s, a))
```

这样做的目标是减轻单个 Q 网络高估分布外动作价值的问题。需要注意，这只是保守估计机制，不等于对预算或 CPA 的形式化硬约束。

#### 3.3.2 Critic Training Procedure：Critic 训练

从 replay buffer 中采样 $(s_t,a_t,r_t,s_{t+1},a_{t+1})$，其中 $d_t$ 表示 episode 是否结束。TD 目标为：

$$
y_t=r_t+\gamma(1-d_t)
\min\left\{Q_1^{\text{target}}(s_{t+1},a_{t+1}),
Q_2^{\text{target}}(s_{t+1},a_{t+1})\right\}. \qquad \text{(12)}
$$

两个 critic 的损失为：

$$
\mathcal{L}_{critic}=\mathbb{E}\left[
\left(Q_1(s_t,a_t)-y_t\right)^2+
\left(Q_2(s_t,a_t)-y_t\right)^2\right]. \qquad \text{(13)}
$$

#### 3.3.3 Q-Optimized Actor Training：Q 优化的 Actor 训练

论文将 Q-value 正则化加入 actor 损失：

$$
\mathcal{L}_{actor}=\mathcal{L}_{dt}+\mathcal{L}_{idm}
+\mathbb{E}_{s}\left[-\min\left(Q_1(s,\hat a),Q_2(s,\hat a)\right)\right]. \qquad \text{(14)}
$$

由于正则项前面有负号，最小化该损失会鼓励 DT 候选动作生成更高 Q-value 的动作。因此，Guide 中的 DT 不是单纯复现日志，而是在行为监督的基础上向 Q 估计的高价值方向探索。换句话说，“DT 更偏探索”是加入 Q-value 正则化之后的 Guide 中 DT，而不是只接受离线行为监督的原始 DT。

论文有一个必须明确的细节：公式（14）中的 Q 正则化项作用在 DT 候选动作 $\hat a$ 上，**Q 模块不直接参与 IDM 的训练**。IDM 仍然根据 DT 预测的状态转移，重建日志中体现出的行为动作，因此它主要承担保守候选和 fallback 的作用。

### 3.4 Q-value Based Action Selection at Inference：推理时的动作选择

线上推理时，模型先得到两个候选动作：

- DT 候选动作 $\hat a_t$：更具有探索性；
- IDM 候选动作 $\hat a_t^{idm}$：更贴近历史状态转移和行为策略。

Q 模块分别计算两个候选动作的保守价值：

$$
Q_{dt}=\min\left\{Q_1(s,\hat a),Q_2(s,\hat a)\right\},
$$

$$
Q_{idm}=\min\left\{Q_1(s,\hat a^{idm}),Q_2(s,\hat a^{idm})\right\},
$$

选择价值更高的动作：

$$
a^*=\arg\max\left\{Q_{dt},Q_{idm}\right\}. \qquad \text{(15)}
$$

这一步不是把两个动作做平均，而是在两个完整候选之间做选择。论文的直观解释是：DT 可以大胆探索潜在高收益策略；当 DT 进入风险较高的分布外区域时，IDM 提供更保守的 fallback；Q 模块根据当前状态选择更值得执行的那个。

### 3.5 Summary：方法小结

Guide 的三个模块职责可以这样记：

| 模块 | 输入 | 输出 | 主要作用 |
|---|---|---|---|
| DT | RTG、历史状态、历史动作 | $\hat a_t$、$\hat s_{t+1}$ | 联合建模并产生探索动作 |
| IDM | $s_t$、$\hat s_{t+1}$ | $\hat a_t^{idm}$ | 根据状态转移重建行为一致动作 |
| Twin Q | 状态与候选动作 | Q-value | 评价候选动作并选择最终动作 |

论文对两种动作的定位是：DT 更偏探索，IDM 更偏行为模仿和稳定回退。IDM 并不是单纯为了产生第二个动作，而是把 DT 预测的未来状态拉回到更可能由历史行为产生的状态转移附近。

## 4. Offline Experiment：离线实验

### 4.1 Experimental Setting：实验设置

论文的离线实验回答三个问题：

- **RQ1：**Guide 是否在不同测试环境中优于基线？
- **RQ2：**各个设计选择分别贡献了什么？
- **RQ3：**DT 和 IDM 如何协同改善出价动作？

#### 4.1.1 Datasets：数据集与仿真环境

论文使用 AuctionNet，这是 NeurIPS 2024 Advertising Bidding Competition 的官方数据集和仿真环境。

- 数据模拟 48 个广告主在多个投放周期中的竞争；
- 每个周期约有 500,000 个曝光机会；
- 每个周期被划分为 48 个决策步；
- traffic-level 数据包含 pValue、bid、cost、win 等曝光级字段；
- trajectory-level 数据聚合为 RL 格式的 state、action、reward；
- 论文使用 final-round 数据，该版本比 preliminary-round 更稀疏、难度更高。

在仿真中，Guide 控制一个广告主，与其他 47 个由官方基线代理控制的广告主竞争；评估时还按照官方协议依次控制全部 48 个广告主，并聚合多个投放周期的结果。

#### 4.1.2 Metrics：指标

AuctionNet 的 bidding score 用价值和 CPA 惩罚共同计算：

$$
Score=\mathbb{P}(CPA;C)\cdot\sum_i x_i\cdot v_i. \qquad \text{(16)}
$$

当实际 CPA 超过约束 $C$ 时，惩罚函数为：

$$
\mathbb{P}(CPA;C)=
\min\left\{\left(\frac{C}{CPA}\right)^\beta,1\right\}. \qquad \text{(17)}
$$

论文通常设置 $\beta=2$。当 $CPA\leq C$ 时，惩罚函数为 1；只有当 CPA 超过约束时才会扣分。

#### 4.1.3 Baselines：基线

论文比较了两类基线：

- 离线 RL：BC、IQL、CQL、TD3-BC；
- 生成式模型：AIGB、DT、GAS、GAVE。

生成式基线使用官方代码，DT 相关方法保持相同设置，以减少实现差异造成的影响。

### 4.2 RQ1：离线数据与仿真环境结果

#### 4.2.1 AuctionNet 离线评估

论文报告不同预算水平下的 Score：

| 方法 | 50% | 75% | 100% | 125% | 150% |
|---|---:|---:|---:|---:|---:|
| IQL | 17.9 | 26.9 | 30.9 | 32.0 | 37.8 |
| BC | 15.0 | 20.3 | 26.8 | 31.6 | 36.6 |
| CQL | 16.1 | 22.4 | 27.9 | 32.1 | 37.6 |
| TD3-BC | 15.0 | 22.7 | 26.4 | 31.4 | 38.0 |
| DT | 18.4 | 24.9 | 27.6 | 35.6 | 39.4 |
| AIGB | 10.7 | 22.2 | 24.6 | 31.8 | 36.5 |
| GAS | 18.4 | 27.5 | 36.1 | 40.0 | 46.5 |
| GAVE | 19.6 | 28.3 | 37.2 | 42.7 | 47.4 |
| **Guide** | **20.3** | **29.1** | **37.6** | **43.3** | **48.3** |

Guide 在所有预算水平上都取得最高分。论文的解释是，统一建模和轨迹探索让模型更充分地利用了广告环境的历史信息，并减少了单纯依赖当前状态或日志行为策略的限制。

#### 4.2.2 AuctionNet 仿真环境

| 方法 | Simulation Score |
|---|---:|
| IQL | 6534 |
| BC | 6366 |
| CQL | 7138 |
| TD3-BC | 7008 |
| DT | 6920 |
| AIGB | 6248 |
| GAS | 7454 |
| **Guide** | **8343** |

仿真结果中 Guide 同样最高。GAS、GAVE 和 Guide 等具有探索能力的生成式方法整体优于基础 DT 和离线 RL；AIGB 在这组实验中表现最差，论文推测原因是长序列和稀疏奖励让 Decision Diffusion 较难学习合理策略。

### 4.3 RQ2：模型分析

#### 4.3.1 Ablation Study：消融实验

![[Figure 3 - Ablation Study.png]]

> 论文原图 Figure 3：Ablation Study。

论文测试了以下变体：

- **w/o IDM Action：**只使用 DT 动作；
- **w/o DT Action：**只使用 IDM 动作；
- **w/o Q Optimization：**移除 Q-value 正则化；
- **w/o Q Selection：**保留 Q 正则化，但随机选择动作；
- **w/o action modeling：**移除 DT 动作损失，只使用状态建模；
- **Original DT：**按照原始 DT 设置，不进行状态建模和 Guide 优化。

主要结论：

1. 去掉 DT 或 IDM 任一动作源都会降分，说明两个动作通道的耦合确实有贡献；
2. 随机选择代替 Q 选择会降分，结果位于两个单独动作源之间；
3. 去掉 Q 正则化后性能明显下降，但仍高于原始 DT，说明统一建模本身也有效；
4. 只建模状态、去掉动作损失时，效果仅略高于原始 DT，明显低于完整 Guide，说明状态和动作的联合建模很重要。

#### 4.3.2 Two-stage Training Analysis：两阶段训练分析

![[Figure 4 - Two-stage Training Analysis.png]]

> 论文原图 Figure 4：Two-stage Training Analysis。

图中比较了：全程联合训练、论文提出的两阶段训练、全程分开训练。

论文观察到：

- 训练早期，两阶段训练和全程分开训练曲线接近；
- 进入联合训练后，两阶段训练仍比全程联合训练下降更快；
- 两阶段训练的 loss 峰值更少、更低；
- 离线测试分数上，两阶段训练也最好。

因此论文认为，两阶段训练同时具有更好的稳定性和收敛速度，更适合实际部署。

### 4.4 RQ3：DT 和 IDM 的协同

#### 4.4.1 两种动作源的使用偏好

![[Figure 5 - Action Preferences.png]]

> 论文原图 Figure 5：Action preferences of different advertisers。

论文统计了全部 48 个广告主对 DT 动作和 IDM 动作的使用比例：

- 没有广告主完全忽略 DT 或 IDM，说明两条动作通道都实际参与了决策；
- 多数广告主超过 70% 的时间选择 DT 动作，说明 DT 的探索动作整体质量更高；
- 当 DT 的探索风险较高时，Q 选择器会切换到更保守的 IDM 动作。

论文进一步按预算和 CPA 约束将广告主分成高、中、低三档。更偏好 IDM 的极端情况主要是：

- 高预算 + 低约束；
- 低预算 + 高约束。

论文认为，这些预算与约束不匹配的情况更容易使 DT 在探索时出错，因此系统更倾向选择 IDM。

#### 4.4.2 动作波动性

![[Figure 6 - Action Volatility Comparison.png]]

> 论文原图 Figure 6：Volatility comparison between DT and IDM bid actions。

论文比较了 DT 和 IDM 动作的均值、方差和标准差。结果显示，IDM 动作整体波动更小，符合它作为稳定 fallback 的定位；DT 动作波动更大，符合它承担探索的定位。

### 4.5 本节作用

离线实验分别验证了三件事：

1. Guide 的整体效果优于基线；
2. DT、IDM、Q 正则化、Q 选择和联合状态—动作建模都不是可随意删除的装饰；
3. DT 和 IDM 在真实决策中不是二选一的固定角色，而是根据广告主和当前约束配置动态切换。

## 5. Online A/B Test：线上 A/B 测试

### 5.1 Deployment：部署方式

论文在淘宝广告平台部署 Guide，以 DT 作为对照基线。广告主可以设置预算以及 CPA、ROI 等约束，策略目标是在约束下优化流量价值。

#### 5.1.1 状态表示

每个 campaign 用 19 维状态向量描述，包含：

- 剩余预算比例、剩余出价步数比例；
- 当前 CPA 与目标 CPA 的偏差；
- 最近时间窗口的曝光、点击、转化、广告成本、GMV；
- CTR、CVR 等派生指标。

#### 5.1.2 动作执行与平滑

模型输出的动作不会直接无平滑地执行。线上系统把当前建议和前两小时的历史出价系数做窗口平均，以降低突然的 multiplier 跳变，保证 campaign 轨迹更稳定。

因此要区分：

- 模型输出：当前决策点的出价系数建议；
- 线上最终执行：经过历史窗口平滑后的出价系数。

#### 5.1.3 Reward 与 RTG

线上 reward 以广告主的 GMV 目标为基础，同时考虑 CPA 和预算约束以及相应惩罚。RTG 被定义为从当前时间窗口到促销日结束的预期累计 GMV，并在计算时纳入约束和惩罚项。

#### 5.1.4 工程配置

- 训练数据：一周历史广告 campaign 数据，每条轨迹对应一天；
- DT：6 层 Transformer，8 个 attention heads，hidden dimension 为 512；
- IDM 和 Q 模块：MLP hidden dimension 为 256；
- 推理频率：每 30 分钟更新一次出价决策；
- 覆盖范围：约 160,000 个商品，影响数千万美元 GMV 规模。

### 5.2 Online A/B Test Results：线上结果

#### 5.2.1 Overall Performance：整体表现

8 天线上 A/B 测试结果如下：

| 指标 | 提升 |
|---|---:|
| Ad Click | +1.40% |
| Ad Cost | +1.66% |
| Ad GMV | +4.10% |
| Ad ROI | +3.52% |

论文强调，Ad Cost 只增加 1.66%，而 Ad GMV 增加 4.10%，说明提升并不只是“多花钱买更多流量”，而是预算分配到了质量更高、转化可能性更高的曝光上。

#### 5.2.2 Trajectory optimization capability：轨迹优化能力

广告投放中，理想的花费轨迹应该随流量自然波动：流量高时多花，流量低时少花。论文根据观测到的流量事后构造 ideal ad cost trajectory，作为 oracle 参考。

![[Figure 7 - Cost Trajectory Analysis.png]]

> 论文原图 Figure 7：Cost Trajectory Analysis。

Guide 的成本轨迹与理想轨迹的 Pearson 相关系数为 96.31%，基线为 93.73%。论文认为，Guide 的预算 pacing 更贴近真实流量变化，基线在部分高峰时段出现了更明显的超支。

### 5.3 本节作用

线上实验补充了离线实验没有回答的两个问题：

- Guide 是否能在真实广告系统中稳定运行；
- 统一建模和候选动作选择是否能改善全天预算节奏。

结果显示，Guide 的收益提升同时伴随着更好的成本轨迹相关性，而不是单纯增加 bid 强度。

## 6. Conclusion and Limitations：结论与局限

### 6.1 结论翻译与总结

论文提出 Guide，一个用于自动广告出价的统一建模与探索框架。Guide 将 DT、IDM 和 Q-value 模块结合起来，在探索和安全之间取得平衡，并在离线数据、仿真环境和真实线上场景中超过多个基线。

线上测试中，Guide 使 Ad GMV 提升 4.10%。论文据此认为，Guide 为复杂广告环境中的自动出价提供了有效方案。

### 6.2 局限与未来方向

论文明确指出两点局限：

1. Guide 缺少针对突发流量变化的细粒度机制，因此对突然波动或特殊事件的响应能力有限；
2. 当前方法主要依赖离线数据和现有模型结构。

未来方向包括引入 LLM 进行轨迹控制和动态优化，以增强策略对持续变化市场的鲁棒性与适应性。

这里还需要做一个严格区分：Guide 的 IDM fallback 和 Twin Q 选择提供的是**行为一致性与价值筛选意义上的安全机制**，并不等同于 GRM 那种显式求预算根、CPA 根的硬约束控制器。论文中的 CPA/预算约束仍然通过状态、RTG、reward、仿真 score 和线上投放系统共同体现。
