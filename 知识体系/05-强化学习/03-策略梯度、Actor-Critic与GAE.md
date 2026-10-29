---
type: 知识
topics: [强化学习, 策略梯度]
aliases: [策略梯度与GAE, Actor-Critic]
---

# 策略梯度、Actor-Critic 与 GAE

先修：[[知识体系/05-强化学习/01-MDP与Bellman|MDP与Bellman]]、[[知识体系/05-强化学习/02-价值学习：MC、TD与Q-learning|价值学习与TD]]、[[知识体系/02-神经网络与Transformer/01-反向传播、初始化与残差|反向传播与残差]]。价值学习通过比较 Q 选动作；策略梯度直接调整动作分布，使高回报轨迹更可能出现。

## 1. 不可微环境里为什么也能求策略梯度

设有限轨迹 $\tau=(s_0,a_0,\ldots,s_T)$，其概率为：

$$p_\theta(\tau)=p(s_0)\prod_{t=0}^{T-1}\pi_\theta(a_t\mid s_t)P(s_{t+1}\mid s_t,a_t).$$

若环境转移不依赖策略参数，且奖励无直接参数依赖，目标 $J(\theta)=E_{\tau\sim p_\theta}[R(\tau)]$ 满足：

$$\nabla J=E[R(\tau)\nabla\log p_\theta(\tau)]
=E\left[R(\tau)\sum_t\nabla\log\pi_\theta(a_t\mid s_t)\right].$$

这是 $\nabla p=p\nabla\log p$ 的恒等变换。环境无需可微，因为求导作用在策略改变轨迹概率的部分；但仍需样本估计回报，所以方差可能大。

## 2. Reward-to-go 为什么能去掉过去奖励

当前动作不可能改变此前已发生的奖励，而给定状态，$E_{a\sim\pi}[\nabla\log\pi(a\mid s)]=\nabla\sum_a\pi(a\mid s)=0$。因此过去奖励乘当前 score 的期望为零。

对折扣目标 $J=E[\sum_t\gamma^t r_t]$，一种精确有限轨迹写法是：

$$\nabla J=E\left[\sum_t\gamma^t\nabla\log\pi(a_t\mid s_t)G_t\right],\quad G_t=\sum_{k=t}^{T-1}\gamma^{k-t}r_k.$$

有些教材把 $\gamma^t$ 吸收到折扣状态访问分布，有些实践目标采用不同时间加权；比较公式时先对齐目标和采样分布，不能只看少了一个符号就判断错对。

## 3. Baseline 不改变期望，却能改变方差

对于与当前动作无关的 $b(s)$：

$$E_{a\sim\pi}[b(s)\nabla\log\pi(a\mid s)]=0.$$

因此可用 $G_t-b(s_t)$ 替代 $G_t$。常用 $V^\pi(s)$，形成优势 $A^\pi(s,a)=Q^\pi(s,a)-V^\pi(s)$。

优势比较“这个状态下该动作比通常表现好多少”，而非把所有高绝对奖励状态的动作都同等强化。状态 A 平均回报 100、动作得到 101；状态 B 平均 0、动作得到 5。优势分别约为 1 和 5，后者提供更强的相对改进信号。

严格的最小方差 baseline 还可能包含 score 范数加权，所以 $V$ 是常见有效选择，不必称为所有情况下的最优 baseline。实现 actor 损失时通常停止优势估计对 critic 的梯度，避免把本应固定的权重也作为优化路径。

## 4. Actor-Critic 的分工

Actor 参数化策略；critic 估计 $V$ 或 $Q$，为策略提供低方差学习信号。critic 不必知道真正反事实，只能从数据与 Bellman 结构学习，因此其误差会传给 actor。

用一步 TD residual：

$$\delta_t=r_t+\gamma V_\phi(s_{t+1})-V_\phi(s_t),$$

当 $V_\phi=V^\pi$ 时，给定 $s_t,a_t$ 的条件期望等于 $A^\pi(s_t,a_t)$。若 critic 不准，优势就有偏；更多 actor 更新可能强化 critic 的错误判断，而不是弥补它。

## 5. GAE 把多个时域的 TD 信号组合

定义：

$$\hat A_t^{GAE(\gamma,\lambda)}=\sum_{l=0}^{T-t-1}(\gamma\lambda)^l\delta_{t+l}.$$

它可递归计算 $\hat A_t=\delta_t+\gamma\lambda\hat A_{t+1}$，并在真正终止处正确截断。$\lambda=0$ 只用一步 TD；$\lambda=1$ 时 TD 项发生望远镜消去，接近多步回报减当前价值，并包含边界 bootstrap。[GAE 原论文](https://arxiv.org/abs/1506.02438)

自己算：两步 TD residual 为 $\delta_t=1,\delta_{t+1}=2$，$\gamma=0.9,\lambda=0.8$，则 $\hat A_t=1+0.72\times2=2.44$。第二步信号仍影响第一步动作，但被时域权重衰减。

当 critic 不准确时，较小 $\lambda$ 更多依赖它，通常减少采样方差却可能增加偏差；较大 $\lambda$ 使用更长真实回报，方差可能更大。若 critic 真值已知，某些偏差项会消失，所以“lambda 越小必定偏差越大”也需要说明误差来源。

## 6. On-policy 与 off-policy 的梯度分布

策略梯度期望取在目标策略诱导的状态动作分布下。若用旧策略数据，动作概率比可以修正部分分布差异，但状态分布与长轨迹问题仍需处理。把所有历史轨迹不加区分地放入 actor loss，不自动得到正确目标梯度。

重要性比值 $\pi(a\mid s)/b(a\mid s)$ 在行为概率很小时会很大。裁剪和归一化可以控制方差，却通常改变估计；设计替代目标时应承认这一权衡，见 [[知识体系/05-强化学习/04-PPO与SAC：约束与熵|PPO与SAC]]。

## 7. 文本生成中的映射

状态是 prompt 与当前前缀，动作是 token，结束符终止轨迹。整段回答评分可以作为末端奖励，但如何给每个 token 分配贡献仍需优势或其他估计。

某段输出得高分，不意味着其中每个步骤都正确；policy gradient 只根据当前奖励和归因机制更新概率。错误推理碰巧得到正确答案、讨好评审或利用格式漏洞，都可能得到正信号。见 [[知识体系/03-LLM/06-偏好优化：DPO、PPO与GRPO|偏好优化与LLM强化学习]]。

## 8. 自检与解析

**问：为什么 baseline 不能任意依赖动作？** 因为 $E[b(s,a)\nabla\log\pi(a\mid s)]$ 一般不再为零，会改变目标梯度，除非设计相应校正。

**问：actor loss 下降是否必然对应回报上升？** 不必。数据分布改变、critic 偏差、有限样本和过大更新都会使替代损失与真实回报脱离。

**问：GAE 是另一个策略算法吗？** 它主要是优势估计方法，可与不同策略更新方法组合，例如 PPO。
