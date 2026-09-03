---
title: "GAS: Generative Auto-bidding with Post-training Search"
authors: "Yewen Li, Shuai Mao, Jingtong Gao, Nan Jiang, Yunjian Xu, Qingpeng Cai, Fei Pan, Peng Jiang, Bo An"
venue: "WWW Companion 2025"
paper: "https://arxiv.org/abs/2412.17018"
code: "https://github.com/yewen99/GAS_WWW-25"
tags:
  - 自动出价
  - 生成式决策
  - 后训练搜索
  - Decision-Transformer
  - Offline-RL
---

# GAS：使用后训练搜索的生成式自动出价

> **论文**：[GAS: Generative Auto-bidding with Post-training Search](https://arxiv.org/abs/2412.17018)  
> **作者**：Yewen Li, Shuai Mao, Jingtong Gao, Nan Jiang, Yunjian Xu, Qingpeng Cai, Fei Pan, Peng Jiang, Bo An  
> **会议**：Companion Proceedings of the ACM Web Conference 2025（WWW Companion 2025）  
> **代码**：[GAS_WWW-25](https://github.com/yewen99/GAS_WWW-25)

## 摘要

自动出价通过代表广告主自动提交出价，在在线广告中发挥着重要作用。近年来，生成式自动出价成为一种新趋势：它使用 Transformer、扩散模型等模型，根据可调条件生成出价，能够直接从数据中学习策略，并灵活适应不同偏好。

但是，低质量数据会导致条件（例如 return-to-go）与真实动作价值不匹配，这一问题在长序列决策中尤其明显；数据集中的多数偏好也可能妨碍模型泛化到少数广告主的偏好。针对不同偏好收集高质量数据并重新训练多个模型成本很高。

论文提出 GAS，即使用后训练搜索的生成式自动出价框架。GAS 通过弱到强搜索对齐，为不同偏好训练小型 critic，并使用受蒙特卡洛树搜索启发的搜索过程优化基础生成策略的输出。论文提出带策略指示的 Transformer critic 和 Q-voting 机制，并利用搜索为高频偏好场景提供微调方法。在真实数据集实验和快手广告平台在线 A/B 测试中，GAS 的目标成本提升 4.60%。

## 1. 引言

在线广告中大量曝光机会使人工调整出价难以实现。自动出价策略依据当前或历史竞价信息，在预算和 KPI 约束下自动调整出价。不同类型的广告主具有不同偏好：品牌广告主通常希望在平均展示成本等约束下尽可能扩大展示；效果广告主则关注在单次转化成本约束下最大化转化价值。因此，广告平台需要提供不同竞价策略，并在动态环境中持续优化策略，使其与广告主偏好保持一致。

强化学习长期用于自动出价，但通常依赖马尔可夫决策过程假设，即未来状态仅由当前状态和动作决定。论文引用的统计分析表明，历史状态序列长度与后续状态之间存在强相关性，仅依赖最近状态可能在不可预测的在线广告环境中产生不稳定性。此外，强化学习策略的偏好不容易控制；策略部署后偏好固定，交互性和可控性受限。

条件生成模型由此成为新的自动出价方向。Decision Transformer 可以使用较长历史进行决策，扩散模型可以根据条件直接生成规划轨迹；部署时修改条件值即可控制偏好。

论文指出，生成式自动出价存在两个内在挑战：

1. 生成式竞价性能受到数据质量影响。采集到的 return-to-go 不能反映动作的真实价值。例如，一个好动作之后若出现坏动作，该好动作对应的 return-to-go 可能较低；反之亦然。因此，训练时条件与真实动作价值不匹配，策略难以达到最优。
2. 实际竞价偏好随时间变化，而生成式方法会模仿数据中的多数偏好，甚至向多数偏好产生偏置。适配新的少数偏好通常需要重新训练，但随着 Transformer 基础模型变大，为不同偏好重复训练多个模型成本过高。

GAS 不修改条件设置，也不为每种偏好重新训练策略模型，而是训练一组代表不同偏好的小型 critic，再使用受 MCTS 启发的搜索优化基础模型输出。Q-learning 的 Bellman backup 只需要当前奖励，不受未来轨迹质量影响；由多种策略采集的大数据集也可用于训练 critic，使其评估不同质量的动作。

论文列出的贡献包括：

- 提出一种灵活、实用的后训练搜索框架，使生成式自动出价模型能够针对不同偏好进行优化与对齐。
- 使用历史竞价序列构造能够感知底层策略的 Transformer critic，并在搜索的价值反向传播阶段引入投票机制，提高价值近似准确率。
- 除测试时搜索外，还为高频偏好或重视计算效率的场景提供微调方法。
- 在大规模真实数据集和快手广告平台在线 A/B 测试中验证方法有效性。

## 2. 预备知识

### 2.1 问题定义

在一个时间周期内，设有按顺序到达的 $H$ 个曝光机会。广告主提交出价参与竞争；若广告主对曝光 $i$ 的出价 $b_i$ 高于其他广告主，则赢得该曝光，并支付成本 $c_i$。广告主的目标是最大化赢得曝光的总价值 $\sum_i o_i v_i$，其中 $v_i$ 是曝光价值，$o_i$ 是是否赢得曝光的二元变量。

预算约束为 $\sum_i o_i c_i\le B$。论文将其他 KPI 约束分为成本相关约束和非成本相关约束，并在本文中考虑具有统一形式的成本相关约束：

$$
\frac{\sum_i c_{ij}o_i}{\sum_i p_{ij}o_i}\le C_j,
$$

其中，$C_j$ 是广告主给定的第 $j$ 个约束上界，$p_{ij}$ 可以是回报或常数等效果指标，$c_{ij}$ 是约束 $j$ 对应的成本。

给定 $J$ 个约束，多约束竞价（MCB）写为：

$$
\begin{aligned}
\operatorname{maximize}\quad & \sum_i o_i v_i \\
\text{s.t.}\quad & \sum_i o_i c_i \le B, \\
& \frac{\sum_i c_{ij}o_i}{\sum_i p_{ij}o_i}\le C_j,\quad \forall j, \\
& o_i\in\{0,1\},\quad \forall i.
\end{aligned}
\qquad \text{(1)}
$$

已有研究给出的最优出价为：

$$
b_i^*=\lambda_0v_i+\sum_{j=1}^{J}\lambda_jp_{ij}C_j.
\qquad \text{(2)}
$$

其中，$b_i^*$ 是曝光 $i$ 的最优出价，$\lambda_j,\ j\in\{0,\ldots,J\}$ 是最优竞价参数。由于广告环境具有不确定性和动态性，这些参数很难直接计算。不同广告主可以通过不同约束组合表达不同偏好，例如只考虑预算约束的最大回报竞价，以及同时考虑预算与 CPA 约束的目标 CPA 竞价。

### 2.2 自动出价的决策过程

由于广告环境高度动态，最优竞价参数需要定期调整，因此自动出价被建模为序列决策任务。智能体在离散时间步与环境交互：在时间步 $t$，智能体接收描述实时广告状态的 $s_t\in\mathcal S$，并输出用于最终出价的动作 $a_t\in\mathcal A$。

环境具有未知状态转移动态 $\mathcal T$。在 MDP 假设下：

$$
\mathcal T:s_t\times a_t\rightarrow s_{t+1},
$$

策略写为 $\pi(a_t\mid s_t)$。若不采用 MDP 假设，下一状态还可能由历史轨迹 $\tau$ 等因素决定。状态转移后，环境产生奖励 $r_t$，表示时间段 $t$ 内对目标产生的价值。智能体重复这一过程直到竞价周期结束，并最大化整个周期的总价值。

- **状态 $s_t$**：从广告活动视角描述广告状态的信息集合，包括剩余时间、剩余预算、预算消耗速度，以及约束 $j$ 的当前 KPI 比率

$$
\frac{\sum_i c_{ij}o_i/\sum_i p_{ij}o_i}{C_j}.
$$

- **动作 $a_t$**：对竞价参数 $\lambda_j,\ j=0,\ldots,J$ 的调整：

$$
a_t=(a_t^{\lambda_0},\ldots,a_t^{\lambda_J}).
$$

- **奖励 $r_t$**：设 $\mathcal C$ 为时间步 $t$ 与 $t+1$ 之间的候选曝光集合，奖励可以设为该时间段内由 $\mathcal C$ 对目标贡献的价值。

## 3. 使用搜索的生成式自动出价

论文先说明如何使用受 MCTS 启发的后训练搜索优化基础策略输出，再给出搜索在自动出价中的两种应用方式。

<p align="center"><img src="assets/GAS Figure 1a - Post-training Search Pipeline.png" width="780"></p>

> **Figure 1(a)：GAS 流程。** GAS 将基础动作 $a_t$ 优化为与 critic 所表示偏好更一致的动作 $a_t^j$，包含三个阶段：（1）通过带噪扰动进行选择；（2）由基于 Transformer 的 Q-value 网络 QT 近似扩展与模拟；（3）通过 Q-voting 机制反向传播，以进行更好的价值评估。

<p align="center"><img src="assets/GAS Figure 1b - Online Auto-bidding System.png" width="520"></p>

> **Figure 1(b)：在线自动出价系统。** 快手在线自动出价系统，包括竞价环境与 GAS 的交互。

### 3.1 受 MCTS 启发的后训练搜索

论文采用 Decision Transformer 作为生成式自动出价的基础模型，其动作策略为：

$$
\begin{aligned}
a_t
&\sim\pi_{dt}\\
&=\operatorname{DT}_{\theta}
(a\mid s_{\le t},a_{<t},R_{\le t}).
\end{aligned}
\qquad \text{(3)}
$$

时间步 $t$ 的条件 $R_t$ 是 return-to-go：

$$
R_t=\sum_{i=t\sim T}\gamma^{i-t}r(s_i,a_i),
\qquad \text{(4)}
$$

其中，$\gamma$ 是折扣因子，$r(s_i,a_i)$ 是表示偏好的奖励函数；例如，它可以设为 $o_iv_i$，表示只考虑价值的偏好。

搜索的目标是找到更符合偏好的动作。典型 MCTS 在每个时间步包括四个部分：

- **选择**：从根状态节点 $s_t$ 出发，在探索预算 $N$ 内随机选择有效的子动作节点 $a_t^i,\ i=1,\ldots,N$。
- **扩展**：如果子动作节点未结束竞价过程，则根据 $s_{t+1}^i\sim\mathcal T$ 创建下一状态节点。
- **模拟**：从 $s_{t+1}^i$ 出发，按照策略 $\pi(a\mid s)$ rollout 至终点。
- **反向传播**：用 rollout 结果更新根状态 $s_t$ 下动作节点 $a_t^i$ 的价值信息。

论文选择在状态 $s_t$ 下执行偏好价值最大的动作，并用随机动作选择表示不确定性。由于竞价是典型的部分可观测 MDP，其他广告主行为不可预测，无法像围棋一样模拟所有可能过程。因此，GAS 不在模拟器中执行真实 rollout，而是用增强的 Transformer Q-value 函数同时近似扩展与模拟阶段。

#### MCTS 与 GAS 的对应关系（解释性整理）

| 标准 MCTS 阶段 | GAS 中的对应实现 | GAS 未采用的部分 |
|---|---|---|
| Selection | 由 DT 生成基础动作，并在其附近随机扰动得到候选动作 | 不使用 UCB、节点访问次数或树内递归选择 |
| Expansion | 将候选动作视为待评估的子动作节点 | 不显式生成候选动作对应的下一状态节点 |
| Simulation | QT 直接估计候选动作直到竞价结束的长期价值 | 不在模拟器或真实环境中执行 rollout |
| Backpropagation | 将多个 QT 对候选动作的归一化评分汇总为 Q-voting 结果 | 不沿多层树路径更新节点访问次数和累计回报 |

**方法定位（解释性理解）：** 按论文给出的 Algorithm 1，GAS 没有维护一棵持续扩展的搜索树，而是在每个时间步围绕 DT 输出执行一次单层局部搜索；执行选中的动作并观察新状态后，下一个时间步重新搜索。因此，它更接近“由生成策略提出候选动作，再由价值模型重新排序”，而不是完整 MCTS。

#### 3.1.1 选择

给定 Decision Transformer 策略 $\operatorname{DT}_\theta$，先生成基础动作 $a_t$，再将其乘以在 90% 到 110% 之间均匀采样的随机因子，得到 $N-1$ 个随机动作：

$$
\begin{aligned}
a_t^i&=a_t\epsilon,\\
\epsilon&\sim\mathcal U(90\%,110\%).
\end{aligned}
\qquad \text{(5)}
$$

保留原始基础动作，最终候选集合为：

$$
\begin{aligned}
\{a_t^i\}_{i=1:N}
&=\{a_t^i\}_{i=1:N-1}\oplus a_t.
\end{aligned}
$$

选择阶段随后从这些动作候选中选择一个动作。

#### 3.1.2 扩展与模拟

由于无法在模拟器或真实环境中 rollout，论文直接使用 Q-value 函数估计状态 $s_t$ 下候选动作 $a_t^i$ 的价值：

$$
\begin{aligned}
Q_\phi(s_t,a_t^i;\pi)
&=r(s_t,a_t^i)\\
&\quad+\mathbb E_{\substack{s_{t+1}\sim\mathcal T\\a_{t+1}\sim\pi}}
Q_\phi(s_{t+1},a_{t+1};\pi).
\end{aligned}
\qquad \text{(6)}
$$

论文使用 IQL 学习 $Q_\phi$。IQL 引入额外的 value 网络 $V_\psi(s)$，其损失为：

> [!info] 方法背景
> IQL 与 CQL、BCQ、BEAR、TD3+BC 等离线强化学习方法的差异，见 [[离线强化学习方法对照：IQL、CQL、BCQ与价值集成]]。

$$
\begin{aligned}
\mathcal L_V(\psi)
&=\mathbb E_{(s,a)\sim\mathcal D}\Big[
L_2^\tau\big(Q_{\hat\phi}(s,a)-V_\psi(s)\big)
\Big].
\end{aligned}
\qquad \text{(7)}
$$

其中，expectile regression 损失为：

$$
L_2^\tau(u)=\left|\tau-\mathbf 1(u<0)\right|u^2.
$$

value 网络用于学习 Q-value：

$$
\begin{aligned}
\mathcal L_Q(\phi)
&=\mathbb E_{\substack{(s_t,a_t,s_{t+1})\\\sim\mathcal D}}\Big[
r(s_t,a_t)+\gamma V_\psi(s_{t+1})\\
&\hspace{11em}-Q_\phi(s_t,a_t)
\Big]^2.
\end{aligned}
\qquad \text{(8)}
$$

原文式（8）在 $Q_\phi(s_t,a_t)$ 后多写了一个右括号；上式按可渲染的平方项括号形式排版。

式（6）表明 Q 与后续期望项中的底层策略 $\pi$ 耦合。但是，$Q_\phi(s_t,a_t)$ 只接收单个状态—动作对，没有策略指示，因此它实际基于采集数据的底层策略 $\pi_\beta$ 预测价值。生成式自动出价策略 $\pi_\epsilon$ 随条件变化，与 $\pi_\beta$ 不同，从而产生有偏的价值近似。

为表示实际策略 $\pi_\epsilon$，论文使用历史轨迹训练 Transformer Q-value 网络 QT：

$$
\begin{aligned}
Q_\phi^{\pi_\epsilon}(s_t,a_t^i)
&=Q_\phi(s_t,a_t^i;\pi_\epsilon)\\
&=\operatorname{QT}_\phi(s_t,a_t^i;s_{<t},a_{<t}).
\end{aligned}
\qquad \text{(9)}
$$

大规模预训练集包含由不同策略采集的轨迹，QT 可以使用历史轨迹预测未来轨迹：

$$
\{s_{\le t},a_{\le t}\}\rightarrow\{s_{t+1:T},a_{t+1:T}\}.
$$

训练完成后，$\operatorname{QT}_\phi(s_t,a_t^i;s_{<t},a_{<t})$ 返回直到竞价结束的 rollout 价值近似。

#### 3.1.3 反向传播：Q-voting

这里的“反向传播”是 MCTS 语境中的价值回传，不是使用梯度更新神经网络参数。由于 GAS 没有构造多层搜索树，它实际执行的是：将各个 QT 对候选动作的价值判断汇总回当前根状态，用于选择本时间步的最终动作。

Q-value 的过估计可能使搜索把错误价值反向传播到动作节点，进而执行较差动作。论文基于 consensus 的启发提出 Q-voting。

独立训练 $M$ 个具有不同随机种子的 Q-value 网络 $\{Q_{\phi_k}^{\pi_\epsilon}\}_{k=1:M}$。设 $N$ 个候选动作中，真实最优动作为 $a_t^j$，并用 $p(a\mid Q)$ 表示在给定 Q 网络时动作 $a$ 是最优动作的概率。consensus 写为：

$$
\begin{aligned}
p(a_t^j\mid Q_{\phi_k}^{\pi_\epsilon})
&>p(a_t^{i\ne j}\mid Q_{\phi_k}^{\pi_\epsilon}),\\
&\qquad \forall k\in\{1,\ldots,M\}.
\end{aligned}
\qquad \text{(10)}
$$

单个 Q 选择 $a_t^j$ 相对于不选择它的胜率定义为：

$$
\mathcal R^k:=
\frac{
p(a_t^j\mid Q_{\phi_k}^{\pi_\epsilon})
}{
\displaystyle\sum_{i\ne j}
p(a_t^i\mid Q_{\phi_k}^{\pi_\epsilon})
}.
\qquad \text{(11)}
$$

为简化，论文假设所有 $k\in\{1,\ldots,M\}$ 的 $p(a_t^i\mid Q_{\phi_k}^{\pi_\epsilon})$ 相同。多数投票最终选择动作 $a_t^i$ 的概率为：

$$
\begin{aligned}
&p\left(
a_t^i\mid\{Q_{\phi_k}^{\pi_\epsilon}\}_{k=1:M}
\right)\\
&=\sum_{l=\lfloor M/2\rfloor+1}^{M}
\binom{M}{l}\\
&\qquad\cdot
p(a_t^i\mid Q_{\phi_k}^{\pi_\epsilon})^l\\
&\qquad\cdot
\left(
1-p(a_t^i\mid Q_{\phi_k}^{\pi_\epsilon})
\right)^{M-l}.
\end{aligned}
$$

根据 Condorcet jury theorem，论文写出：

$$
\begin{aligned}
\mathcal R^{1:M}
&=
\frac{
p(a_t^i\mid\{Q_{\phi_k}^{\pi_\epsilon}\}_{k=1:M})
}{
\displaystyle\sum_{i\ne j}
p(a_t^i\mid\{Q_{\phi_k}^{\pi_\epsilon}\}_{k=1:M})
}\\
&>\mathcal R^k.
\end{aligned}
\qquad \text{(12)}
$$

论文给出的例子是：若对所有 $k$，$p(a_t^1\mid Q_{\phi_k}^{\pi_\epsilon})=0.4$，$p(a_t^2\mid Q_{\phi_k}^{\pi_\epsilon})=0.3$，$p(a_t^3\mid Q_{\phi_k}^{\pi_\epsilon})=0.3$，则 $\mathcal R^{1:3}=0.81>\mathcal R^k=0.67$。

为避免没有任何动作获得绝对多数票的无效投票结果，Q-voting 使用软多数投票。第一步，对每个 $Q_{\phi_k}^{\pi_\epsilon}$ 在全部候选动作上做 min-max 归一化：

$$
\begin{aligned}
v(a_t^i\mid Q_{\phi_k}^{\pi_\epsilon})
&=
\frac{
\begin{gathered}
Q_{\phi_k}^{\pi_\epsilon}(s_t,a_t^i)\\[-0.2em]
-\min_n\{Q_{\phi_k}^{\pi_\epsilon}(s_t,a_t^n)\}
\end{gathered}
}{
\begin{gathered}
\max_n\{Q_{\phi_k}^{\pi_\epsilon}(s_t,a_t^n)\}\\[-0.2em]
-\min_n\{Q_{\phi_k}^{\pi_\epsilon}(s_t,a_t^n)\}
\end{gathered}
}\\
&\in[0,1].
\end{aligned}
\qquad \text{(13)}
$$

第二步，对 $M$ 个 critic 的投票求和：

$$
\begin{aligned}
v\left(
a_t^i\mid\{Q_{\phi_k}^{\pi_\epsilon}\}_{k=1:M}
\right)
&=\sum_{k=1}^{M}
v(a_t^i\mid Q_{\phi_k}^{\pi_\epsilon}).
\end{aligned}
\qquad \text{(14)}
$$

完成上述搜索后，GAS 得到预期偏好价值高于基础动作 $a_t$ 的优化动作。

**直观理解：** DT 负责给出基础动作，多个 QT 相当于独立评审，只比较该动作附近的几个修改版本；GAS 最终执行获得总体评分最高的候选动作。

### 3.2 使用 GAS 竞价

GAS 有两种使用方式：在测试时进行搜索，以及使用搜索结果微调基础策略模型。两者都需要训练一组表示不同偏好的 critic。

**训练与推理边界：** 在 GAS-infer 中，DT 和 QT critic 均已训练完成；搜索阶段只执行候选生成、QT 前向估值和动作选择，不利用搜索结果在线反向更新 DT。只有 GAS-sft 会先用搜索得到偏好动作 $a_t^p$，再通过式（15）的监督损失更新 DT 参数。

#### 偏好表示

偏好由奖励函数的设置表示。论文给出三个例子：

1. 只考虑预算约束、不考虑 KPI 约束，最大化赢得曝光的价值，即 Max Return Bidding：

$$
r_t=o_tv_t.
$$

2. 同时考虑赢得的价值和 KPI 约束，最大化综合表现：

$$
\begin{aligned}
r_t
&=o_tv_t\cdot\frac{1}{J}\sum_j\\
&\qquad\cdot
\min\left\{
\left(\frac{C_j}{c_{tj}o_t/p_{tj}o_t}\right)^\beta,
1
\right\},\\
&\qquad \beta>1.
\end{aligned}
$$

3. 引入更大且可控的权重 $w$，使偏好更侧重 KPI 约束：

$$
\begin{aligned}
r_t
&=o_tv_t+\frac{w}{J}\sum_j\\
&\qquad\cdot
\min\left\{
\left(\frac{C_j}{c_{tj}o_t/p_{tj}o_t}\right)^\beta,
1
\right\},\\
&\qquad \beta>1.
\end{aligned}
$$

这些奖励函数用于依据式（8）训练 critic。

#### 3.2.1 推理时搜索：GAS-infer

在推理的每个时间步重复第 3.1 节的搜索过程，即得到 GAS-infer。它可以与一个基础策略模型和多个 critic 一起直接部署。

<p align="center"><img src="assets/GAS Algorithm 1 - Inference with Search.png" width="660"></p>

> **Algorithm 1：Inference with Search（GAS-infer）。** 输入基础策略 $\pi_\theta$、critic 集合 $\{Q_{\phi_k}^{\pi_\epsilon}\}_{k=1}^M$ 和初始状态 $s_0$。在每个时间步生成基础动作，构造 $N-1$ 个带噪动作，与基础动作组成候选集合；用式（14）的 Q-voting 估计每个候选动作的价值，选择价值最大的动作执行并更新状态。

#### 3.2.2 使用搜索微调：GAS-sft

搜索可以在基础动作质量较差或与偏好不一致时，从其附近找到更好的动作，因此可用于增强训练数据并微调基础策略。对于数据点 $\{s_t,a_t^{gt}\}$，以 $a_t^{gt}$ 为基础进行搜索，得到与偏好更一致的动作 $a_t^p$，再用监督微调损失训练 $\operatorname{DT}_\theta$：

$$
\mathcal L_{\operatorname{DT}}^{\operatorname{sft}}(\theta)=\operatorname{mse}(a_t,a_t^p).
\qquad \text{(15)}
$$

论文指出，DPO 和 RLHF 等其他偏好对齐方法通常基于查询数据集在轨迹层面工作，且被报告为不稳定，因此留作未来工作。

## 4. 实验

### 4.1 实验设置

#### 数据集

论文使用阿里巴巴发布的公开大规模真实竞价数据集 AuctionNet，以及具有更少转化、更具挑战性的 AuctionNet-sparse。数据集包含超过 5 亿条记录。

#### 评估指标

- **Value**：竞价周期内收到的总价值 $\sum_i o_iv_i$。
- **KPI 约束超限率（ER）**：令 $\mathbb{I}(x_j^h,C_j)$ 表示周期 $h$ 的最终 KPI 表现是否超过约束 $C_j$。原文在定义最终 KPI 表现时写作 $x_j^n=\sum_i c_{ij}o_i/\sum_i p_{ij}o_i$，在 ER 公式中使用 $x_j^h$。共有 $H$ 个周期，则：

$$
ER=\frac{1}{H}\sum_{h=1\sim H}\sum_{j=1\sim J}\mathbb{I}(x_j^h,C_j).
\qquad \text{(16)}
$$

- **Score**：先引入惩罚项：

$$
\begin{aligned}
penaty_j
&=\min\left\{
\left(
\frac{C_j}{
\displaystyle
\frac{\sum_i c_{ij}o_i}{\sum_i p_{ij}o_i}
}
\right)^\beta,
1
\right\},\\
&\qquad \beta=2.
\end{aligned}
\qquad \text{(17)}
$$

论文原文将该变量拼写为 `penaty`。综合得分为：

$$
score=\left(\sum_i o_iv_i\right)\times\min\{penaty_j\}_{j=1\sim J}.
\qquad \text{(18)}
$$

#### 对比方法

强化学习方法包括 USCB、BCQ、CQL 和 IQL；生成式方法包括基于扩散模型的 DiffBid、Decision Transformer（DT）、考虑多约束向量的 CDT，以及使用同时考虑赢得价值和 KPI 约束的奖励函数的 DT-score。

#### 实现细节

GAS 包括基础策略模型和多个 QT 网络。基础策略采用 DT-score；微调学习率为 $1\mathrm e{-5}$。每个 QT 使用 6 个注意力层、8 个注意力头和 512 的隐藏维度，共 14M 参数。训练 400k 步，使用 AdamW，学习率 $1\mathrm e{-4}$，批大小 128；训练在两张 NVIDIA H100 GPU 上进行。

### 4.2 与基线的性能比较

实验在 AuctionNet 和 AuctionNet-sparse 上，将预算设为最大可用预算的 50%、75%、100%、125% 和 150%，使用 Score 进行综合评估，基础策略为 DT-score。

<p align="center"><img src="assets/GAS Table 1 - Baseline Comparison.png" width="920"></p>

> **Table 1：MCB 任务中不同设置下与基线的比较。** 最优结果用粗体表示，基础策略结果加下划线，最后一列给出 GAS-infer 相对基础策略的提升。

论文报告，GAS-infer 和 GAS-sft 在不同预算设置下均优于其他方法。DT、CDT 和 DT-score 的表现也优于 IQL 等传统强化学习方法。DiffBid 在该大规模任务中表现不佳；论文给出的可能原因是，预测完整长轨迹和学习逆动力学模型引入了额外难度。

GAS-sft 的表现不及 GAS-infer。论文将其归因于 GAS-infer 在测试时通过额外的 critic 参数化并明确执行偏好信息，而 GAS-sft 将 actor 与 critic 信息融合进原模型，可能产生歧义，并削弱其 critic 能力约束。Q-voting 可以并行执行，每个时间步约耗时 0.1 秒，而相邻竞价时间步之间的间隔为 30 分钟。

### 4.3 偏好对齐性能

论文比较了 GAS-infer、GAS-sft 与基础 DT-score 在 Score-first、Value-first 和 ER-first 三种偏好下的对齐结果。

<p align="center"><img src="assets/GAS Table 2 - Preference Alignment.png" width="860"></p>

> **Table 2：不同偏好下两种搜索范式相对基础 DT-score 的对齐性能。**

论文报告，GAS-infer 和 GAS-sft 相比基础模型，在不同偏好下均获得了更好的对齐表现。

### 4.4 消融实验

<p align="center"><img src="assets/GAS Figure 2a - Searching Budget.png" width="520"></p>

> **Figure 2(a)：搜索预算。** 在不使用原始基础动作的设置下，将采样动作数从 1 增加到 5 可提升性能；超过 5 个动作后性能保持不变。

<p align="center"><img src="assets/GAS Figure 2b - Number of Critics.png" width="520"></p>

> **Figure 2(b)：critic 数量。** 搜索范围固定为 $\pm10\%$，选择 5 个随机动作进行价值评估。论文报告，将 QT 数量从 1 增加到更多可显著改善性能，最优点为 7 个 critic；同时原文写道，从 3 个 critic 继续增加没有显著改善，因此 3 个 critic 足以用于当前自动出价任务。

<p align="center"><img src="assets/GAS Figure 2c - Range of Search.png" width="520"></p>

> **Figure 2(c)：搜索范围。** 固定随机搜索 5 个动作时，AuctionNet 上 10% 搜索范围表现最好；超过 10% 后收益递减，min-max 方法在有限动作预算下效果最差。

<p align="center"><img src="assets/GAS Figure 2d - Stability.png" width="520"></p>

> **Figure 2(d)：稳定性比较。** 论文报告 GAS 比基础策略模型更稳定。

#### QT 的有效性

论文指出，扩展和模拟由 Q-value 函数近似，因此 Q-value 在底层策略下预测期望回报的准确性很重要。没有历史轨迹信息时，仅根据 $s_t$ 和 $a_t$ 预测 rollout 过程具有不明确性和高度随机性。带历史轨迹作为策略表示的 QT 明显优于只使用普通状态—动作对的 Q-value 函数。

论文还比较了不使用 Q-value 网络的搜索方式：Greedy 选择预测即时奖励最高的动作；Random 随机选择动作；Mean 对 5 个随机动作取平均值。

<p align="center"><img src="assets/GAS Table 3 - Effectiveness of QT.png" width="760"></p>

> **Table 3：QT 的有效性。** DT-score、Greedy、Mean、Random、GAS w/o QT 和 GAS-infer 的 Score 分别为 334、228、312、319、292 和 359。

## 5. 在线实验

GAS 部署在快手广告系统的多约束竞价场景。广告主设置预算，并可以选择是否附加 CPA/ROI 约束；竞价策略的目标是在约束下尽可能获得更多转化。由于在线测试资源有限且可能影响广告主价值，实验只比较 GAS-infer 与当前生产中的 DT 基线。

- **状态**：预算、成本、按时间分配的预算、按时间计算的成本速度、预测转化率、实际 CPA 或 ROI 状态等。
- **动作**：对上一时间步竞价系数的调整：

$$
\lambda_t=\lambda_{t-1}+a_t.
$$

其中，$\lambda_t$ 是式（2）中的竞价系数。

- **后训练搜索**：critic 以赢得曝光的价值总和训练；搜索使用 Value-first 设置；在基础动作的 $\pm10\%$ 范围内搜索 5 个点。

在线 A/B 测试持续 6 个完整自然日。对每个 MCB 广告活动，25% 的预算和流量分配给基线竞价模型，25% 分配给 GAS。

<p align="center"><img src="assets/GAS Table 4 - Online AB Test.png" width="700"></p>

> **Table 4：在线 A/B 测试结果。** GAS 的曝光量提升 1.65%，成本提升 0.94%，目标成本提升 4.60%，整体 ROI 提升 3.62%。论文报告所有指标均获得显著提升。

## 6. 相关工作

### 6.1 自动出价与离线强化学习

早期方法使用 PID 根据预设曲线优化预算消耗，OnlineLP 根据流量预测调整出价。随着在线竞价环境变复杂，USCB、SORL 和 MAAB 等强化学习算法用于竞价决策。离线强化学习从已有数据集学习策略，无需在线交互：BCQ 缩小动作空间以引导智能体靠近数据内策略；CQL 正则化 Q-value，学习保守价值估计；IQL 在训练时无需查询分布外动作的 Q-value，即可执行多步动态规划更新。论文指出，这些方法受到 MDP 假设限制，而生成模型在自动出价中显示出更大潜力。

### 6.2 生成模型

生成模型学习数据分布或变量之间的条件概率分布。VAE、Flow 和 GAN 等深度生成模型通过以可控高斯形式表示高维数据来学习复杂数据分布。Decision Transformer 使用自回归模型刻画复杂决策分布；扩散模型通过反向去噪过程根据条件生成样本。自动出价方法 DiffBid 根据回报等条件生成长轨迹，再使用逆动力学模型学习从当前状态映射到预测的下一状态。

### 6.3 偏好对齐

将基础模型微调到特定偏好的主要方式包括监督微调和基于人类反馈的偏好优化。SFT 构造特定领域的高质量轨迹，使基础模型与偏好对齐。RLHF 使用偏好模型和 PPO 进一步优化模型；DPO 及其变体直接利用偏好查询数据微调模型，跳过奖励建模和强化学习优化。近期也出现了只使用奖励模型、无需微调即可实现偏好对齐的后训练方法。

## 7. 结论

论文提出生成式自动出价框架 GAS，使用后训练搜索针对不同广告主偏好优化生成式自动出价策略。该方法使用 Transformer critic 和投票机制提高价值近似准确率，使单一模型无需针对不同偏好执行多次高成本训练。

论文列出两项局限：

1. 对 MCTS 的简化，例如近似扩展和模拟步骤，可能无法完整刻画真实竞价场景的复杂性。
2. GAS 的微调版本比推理版本计算效率更高，但性能仍然有限，需要更先进、更有效的微调方法。

## 致谢

该研究由新加坡国家研究基金会 Competitive Research Programme（Grant No. NRF-CRP23-2019-0006）支持。Shuai Mao 和 Yunjian Xu 还获得香港大学教育资助委员会 General Research Fund（GRF）项目 14200720，以及中国国家自然科学基金项目 62073273 的部分支持。

## 附录 A

### A.1 数据集细节

AuctionNet-sparse 是 AuctionNet 的稀疏版本，转化更少。每个数据集包含 21 个广告投放周期；每个周期约有 500,000 个曝光机会，并被划分为 48 个时间区间。每个广告主对全部曝光进行竞价。

<p align="center"><img src="assets/GAS Table 5 - Dataset Parameters.png" width="760"></p>

> **Table 5：AuctionNet 与 AuctionNet-sparse 的参数。** 两个数据集均有 479,376 条轨迹、9,987 个投放周期、每条轨迹 48 个时间步、16 维状态、1 维动作和 1 维 return-to-go。

每个数据集包含超过 5 亿条记录，每条记录包含多个广告主在不同时间步和投放周期的信息。状态的 16 个组成部分为：

1. `time_left`：当前广告投放周期的剩余时间步数。
2. `budget_left`：当前投放周期内广告主可用的剩余预算。
3. `historical_bid_mean`：广告主过去时间步出价的平均值。
4. `last_three_bid_mean`：最近三个时间步出价的平均值。
5. `historical_LeastWinningCost_mean`：过去时间步赢得曝光所需最低成本的平均值。
6. `historical_pValues_mean`：过去时间步历史 p-value 的平均值。
7. `historical_conversion_mean`：过去时间步广告主获得的转化数平均值。
8. `historical_xi_mean`：广告主在曝光机会中的平均获胜状态，1 表示获胜，0 表示未获胜。
9. `last_three_LeastWinningCost_mean`：最近三个时间步最低获胜成本的平均值。
10. `last_three_pValues_mean`：最近三个时间步广告曝光给用户的转化概率平均值。
11. `last_three_conversion_mean`：最近三个时间步转化数的平均值。
12. `last_three_xi_mean`：最近三个时间步广告主获胜状态的平均值。
13. `current_pValues_mean`：当前时间步 p-value 的平均值。
14. `current_pv_num`：当前时间步服务的曝光数量。
15. `last_three_pv_num_total`：最近三个时间步服务的曝光总数。
16. `historical_pv_num_total`：过去时间步服务的曝光总数。

实验使用阿里巴巴提供的模拟广告系统。评估中的一个 episode 即一个广告投放周期：一天被分为 48 个区间，每个区间 30 分钟；每个 episode 约包含 500,000 个按顺序到达的曝光机会；一个投放周期包含来自不同类别、具有不同预算与 CPA 的 48 个广告主。每次评估中，训练完成的模型代表一个具有指定预算和 CPA 的广告主参与竞价。论文使用不同广告主配置和投放周期多次评估，并将平均结果作为评估分数。

### A.2 QT 超参数

<p align="center"><img src="assets/GAS Table 6 - QT Hyperparameters.png" width="640"></p>

> **Table 6：QT 网络的详细超参数。** 批大小 128，训练步数 400,000，序列长度 20，学习率 $1\mathrm e{-4}$，6 个注意力层，8 个注意力头，AdamW，optimizer epsilon $1\mathrm e{-8}$，权重衰减 $1\mathrm e{-2}$，scale 2000，episode 长度 48，隐藏维度 512，ReLU，$\gamma=0.99$，$\tau=0.01$，expectile 为 0.7。
