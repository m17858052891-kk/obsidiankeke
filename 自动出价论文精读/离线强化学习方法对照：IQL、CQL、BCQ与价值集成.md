---
tags:
  - 离线强化学习
  - Offline-RL
  - IQL
  - CQL
  - 自动出价
  - Critic
created: 2026-09-03
---

# 离线强化学习方法对照：IQL、CQL、BCQ 与价值集成

> [!summary] 一句话总览
> 离线强化学习的共同难题是：模型只能使用固定日志，无法上线试错，因此很容易把数据中没有充分覆盖的动作错误估成高价值。IQL、CQL、BCQ、BEAR 和 TD3+BC 的主要区别，不是是否使用 Q，而是分别从“价值估计、候选动作、策略分布或行为克隆”哪一侧限制这种分布外外推。

相关论文笔记：[[07_GAS：生成式自动出价的后训练搜索]]、[[10_DRIVE：分布式动作、检索增强与价值评估]]。

## 1. 离线强化学习共同在解决什么？

离线强化学习只有固定数据集：

$$
\mathcal D=\{(s_t,a_t,r_t,s_{t+1})\}.
$$

训练期间不能把新动作放进真实环境验证。普通 Q-learning 使用：

$$
Q(s_t,a_t)\leftarrow r_t+\gamma\max_{a'}Q(s_{t+1},a').
$$

如果神经网络对没有在数据中出现的动作 $a'_{\mathrm{OOD}}$ 给出虚假高值，$\max$ 会优先选中它，并通过 Bellman backup 把误差传播到前面的状态。这就是离线强化学习中的分布外动作高估。

不同方法的核心选择可以概括为：

| 方法 | 如何处理分布外动作 | 直观理解 |
|---|---|---|
| IQL | 训练时不显式对任意新动作求 $\max Q$ | 不主动查询陌生动作 |
| CQL | 主动压低数据外动作的 Q | 陌生动作先打低分 |
| BCQ | 只生成接近行为数据的候选 | 陌生动作不进入候选池 |
| BEAR | 约束新策略与行为策略的分布距离 | 新策略不能离日志太远 |
| TD3+BC | Q 最大化与行为克隆同时优化 | 想改进，但要被日志拉住 |
| AWAC / AWR / CRR | 更高权重模仿高优势历史动作 | 多学日志中的好动作 |
| Ensemble Q | 利用多个 Q 的分歧估计不确定性 | 评委意见不一致就谨慎 |
| Distributional critic | 预测完整回报分布 | 同时衡量收益和尾部风险 |

## 2. IQL：隐式地偏向数据内高价值动作

论文：[Offline Reinforcement Learning with Implicit Q-Learning](https://arxiv.org/abs/2110.06169)

IQL（Implicit Q-Learning）不直接计算整个动作空间上的 $\max_{a'}Q(s',a')$，而是额外训练一个状态价值网络 $V(s)$，让它逼近离线数据所支持动作中偏高的 Q 值。

### 2.1 用 expectile regression 训练 $V$

$$
\mathcal L_V
=
\mathbb E_{(s,a)\sim\mathcal D}
\left[
L_2^\tau\left(Q_{\hat\phi}(s,a)-V_\psi(s)\right)
\right],
$$

其中：

$$
L_2^\tau(u)
=
\left|\tau-\mathbb I(u<0)\right|u^2.
$$

当 $\tau>0.5$ 时，高于 $V(s)$ 的 Q 样本获得更大权重，使 $V(s)$ 向数据内较高的 Q 值移动。这是 expectile，不是 quantile；它使用非对称平方误差，也不等于直接取最大值。

### 2.2 用 $V(s')$ 训练 Q

$$
y_t=r_t+\gamma V_\psi(s_{t+1}),
$$

$$
\mathcal L_Q
=
\mathbb E
\left[
\left(Q_\phi(s_t,a_t)-y_t\right)^2
\right].
$$

关键点是，目标里没有对任意新动作计算 $\max Q$。训练 Q 使用的当前动作 $a_t$ 来自离线数据，因此降低了对分布外动作的依赖。

### 2.3 标准 IQL 的 actor 提取

完整 IQL 还可以计算优势：

$$
A(s,a)=Q(s,a)-V(s),
$$

并用优势加权行为克隆训练策略：

$$
\mathcal L_\pi
=
-\mathbb E_{(s,a)\sim\mathcal D}
\left[
\exp\left(\beta A(s,a)\right)
\log\pi(a\mid s)
\right].
$$

高优势历史动作获得更大模仿权重。DRIVE 和 GAS 没有用这一 actor 去替代各自的生成模型，而是主要借用 IQL 的 $Q/V$ 学习部分训练候选动作评分器。

> [!note] 适用特点
> IQL 不像 CQL 那样显式压低所有可疑动作，因此通常没那么悲观；当候选已经受到数据支持、又需要识别数据内高价值尾部时，它很适合作为排序 critic。

## 3. CQL：显式学习保守 Q

论文：[Conservative Q-Learning for Offline Reinforcement Learning](https://arxiv.org/abs/2006.04779)

CQL（Conservative Q-Learning）在 TD loss 之外增加保守正则。典型形式可示意为：

$$
\mathcal L_{\mathrm{CQL}}
=
\mathcal L_{\mathrm{TD}}
+
\alpha
\left[
\mathbb E_s\log\sum_{a'}\exp Q(s,a')
-
\mathbb E_{(s,a)\sim\mathcal D}Q(s,a)
\right].
$$

第一项会对广泛候选动作的高 Q 施加压力，第二项相对保留数据动作的 Q。连续动作实现通常通过策略或其他 proposal 采样近似这些期望。

直观上，CQL 的原则是：

$$
\text{没有离线证据支持的动作}\Longrightarrow\text{价值先保守估计}.
$$

优点是对大范围生成候选更谨慎；代价是可能低估真实但稀有的优秀动作。DRIVE 的附录比较了 IQL 与 CQL critic：低预算时两者接近，较高预算下 IQL 更好，作者据此默认使用 IQL；该结果是 DRIVE 特定实验的经验结论，并不代表 IQL 在所有任务上都优于 CQL。

## 4. BCQ：先限制候选，再使用 Q 选择

论文：[Off-Policy Deep Reinforcement Learning without Exploration](https://arxiv.org/abs/1812.02900)

BCQ（Batch-Constrained Q-Learning）先学习行为数据中的动作分布：

$$
a\sim G_\omega(a\mid s),
$$

再对候选动作做有限扰动：

$$
\tilde a=a+\xi_\phi(s,a),
$$

最后只在这批受数据约束的候选中选择：

$$
a^*=\arg\max_{\tilde a\in\mathcal A_{\mathrm{BCQ}}}Q(s,\tilde a).
$$

BCQ 的核心不是让 Q 能可靠评估任意动作，而是不允许任意动作进入选择阶段。它与 DRIVE/GAS 的“proposal + critic”结构非常接近：行为生成模型对应候选生成，有限扰动对应局部搜索，Q 对候选执行最终排序。

## 5. BEAR：限制新策略与行为策略的距离

论文：[Stabilizing Off-Policy Q-Learning via Bootstrapping Error Reduction](https://arxiv.org/abs/1906.00949)

BEAR 约束学习策略 $\pi$ 与数据行为策略 $\pi_\beta$ 的分布距离：

$$
D\left(\pi(\cdot\mid s),\pi_\beta(\cdot\mid s)\right)\le\epsilon.
$$

它在提高 Q 的同时，使用 MMD 等距离约束策略不要离开数据支持区域。BEAR 更像一套完整的策略优化方法，而不是可直接替换到 DRIVE/GAS 中的单独 critic。

## 6. TD3+BC：价值改进与行为克隆的折中

论文：[A Minimalist Approach to Offline Reinforcement Learning](https://arxiv.org/abs/2106.06860)

TD3+BC 在 actor 目标中同时考虑高 Q 和行为克隆：

$$
\max_\pi
\mathbb E_{(s,a)\sim\mathcal D}
\left[
\lambda Q(s,\pi(s))
-
\|\pi(s)-a\|^2
\right].
$$

第一项推动策略改进，第二项把输出拉回历史行为附近。它实现简单、常作为强离线 RL 基线，但主要改变 actor 的训练方式；如果 DRIVE/GAS 仍保留 GMM 或 DT actor，就不能只替换 critic 而称为 TD3+BC。

## 7. AWAC、AWR 与 CRR：优势加权行为克隆

- AWAC：[Accelerating Online Reinforcement Learning with Offline Datasets](https://arxiv.org/abs/2006.09359)
- AWR：[Advantage-Weighted Regression](https://arxiv.org/abs/1910.00177)
- CRR：[Critic Regularized Regression](https://arxiv.org/abs/2006.15134)

这类方法共同使用 critic 判断历史动作相对当前状态基线是否更好：

$$
A(s,a)=Q(s,a)-V(s),
$$

然后以更大权重模仿高优势动作：

$$
w(s,a)=\exp\left(\frac{A(s,a)}{\lambda}\right),
$$

$$
\mathcal L_\pi
=
-\mathbb E
\left[
w(s,a)\log\pi(a\mid s)
\right].
$$

如果希望 DRIVE 的 critic 不仅在推理时重排 GMM 候选，还能反过来改善 GMM actor，可以把普通负对数似然改成优势加权似然：

$$
\mathcal L_{\mathrm{GMM-AW}}
=
-\mathbb E
\left[
w(s,a)\log p_\theta(a\mid H_t)
\right].
$$

这是对现有模块的解释性组合，不是 DRIVE 原论文已经验证的训练目标。

## 8. Ensemble Q：把 critic 分歧作为不确定性

代表工作：[Uncertainty-Based Offline Reinforcement Learning with Diversified Q-Ensemble](https://arxiv.org/abs/2110.01548)

训练多个 critic：

$$
Q_1(s,a),\ldots,Q_M(s,a),
$$

可以使用均值减去分歧惩罚：

$$
\operatorname{Score}(a)
=
\frac{1}{M}\sum_{k=1}^{M}Q_k(s,a)
-
\beta\operatorname{Std}_{k}\left[Q_k(s,a)\right].
$$

如果多个 critic 对某个动作分歧很大，说明该动作可能缺少数据支持或处在外推区域。GAS 的 Q-voting 也使用多个 critic，但它把每个 critic 在候选集合内的评分归一化后求和，强调排序共识；均值减标准差则显式惩罚不确定性。

## 9. Distributional critic：学习回报分布而非单一均值

代表论文：[A Distributional Perspective on Reinforcement Learning](https://arxiv.org/abs/1707.06887)

普通 Q 只学习期望回报：

$$
Q(s,a)=\mathbb E[Z(s,a)].
$$

Distributional critic 直接建模回报随机变量 $Z(s,a)$，因此可以区分“均值相同但风险不同”的动作，并使用分位数或 CVaR 等风险指标决策：

$$
a^*=\arg\max_a\operatorname{CVaR}_\alpha[Z(s,a)].
$$

这与 DRIVE 的 GMM 不是同一种分布：GMM 学习动作分布 $p(a\mid s)$，distributional critic 学习回报分布 $p(Z\mid s,a)$。二者可以同时存在，后者尤其适合预算、CPA、ROI 等尾部风险明显的任务。

## 10. 与 GAS 和 DRIVE 的对应关系

### 10.1 DRIVE

DRIVE 使用 GMM 和检索构造候选集，再使用双 IQL Q 的较小值排序：

$$
a^*=\arg\max_{a\in\mathcal A_{\mathrm{cand}}}
\min_{i=1,2}Q_i(s,a).
$$

它主要借用 IQL 的 $Q/V$ critic 学习，并没有使用标准 IQL actor 替换 GMM Transformer。

### 10.2 GAS

GAS 同样使用 IQL 学习价值，但把普通 $Q(s,a)$ 改成读取历史轨迹的 Transformer QT：

$$
Q_\phi^{\pi_\epsilon}(s_t,a_t^i)
=
\operatorname{QT}_\phi(s_t,a_t^i;s_{<t},a_{<t}).
$$

多个 QT 对候选动作分别评分，经过候选内 min-max 归一化后累加投票。IQL 决定 critic 如何从离线 transition 学价值，QT 决定 critic 使用什么历史表示，Q-voting 决定推理时如何集成多个 critic；三者是不同层面的设计。

### 10.3 可以怎样选择？

| 场景 | 更值得优先测试的方法 |
|---|---|
| 候选主要来自高相似度检索，数据支持较强 | IQL |
| GMM 或搜索范围较大，候选可能明显 OOD | CQL 或支持度过滤 |
| 候选数量较多，担心挑中偶然高估动作 | 双 Q 或 ensemble uncertainty |
| 状态不满足 Markov 性、需要历史策略感知 | 历史条件 IQL/CQL critic |
| 更关注 CPA、预算和 ROI 尾部风险 | Distributional critic |
| 希望 critic 反向改善 actor，而非只在推理时排序 | AWAC/IQL 式优势加权训练 |

对于“DRIVE 候选 + GAS 历史感知评估”的组合，一个可测试的结构是：

$$
q_k(a)
=
\min\left(
Q_{k,1}(H_t,s_t,a),
Q_{k,2}(H_t,s_t,a)
\right),
$$

再用 Q-voting 或不确定性惩罚汇总不同 $k$ 的结果。这里双 Q 负责保守，历史编码负责减少状态/策略混叠，ensemble 负责识别分歧，GMM 与检索负责候选覆盖。

## 11. 共同边界

> [!warning] 训练期 in-sample 不等于推理期绝对安全
> IQL 在训练时避免对任意分布外动作求最大值，但 DRIVE 推理时仍会评估 GMM 样本，GAS 也会评估局部扰动动作。这些候选仍可能落在数据支持边缘。因此 IQL 可以降低离线训练的不稳定性，却不能保证所有推理候选的 Q 都可靠。

> [!warning] critic 不能弥补候选缺失
> 如果真正的高价值动作没有进入候选集，再准确的 IQL、CQL 或 QT 也只能从较差候选中选择。候选覆盖误差与 critic 排序误差需要分开评估。

> [!note] 推荐对照实验
> 固定同一 actor、数据、reward 和候选集合，比较 IQL、CQL、历史感知 IQL、历史感知 CQL 与 ensemble critic。否则最终分数差异可能来自候选生成，而不是价值学习方法本身。

