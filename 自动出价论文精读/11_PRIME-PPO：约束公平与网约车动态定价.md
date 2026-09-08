# PRIME-PPO：约束公平与网约车动态定价

> **阅读定位：** 这是一篇把网约车动态加价建模为“带公平、预算和机制边界的连续控制”问题的 PPO 扩展论文。它的价值不在提出新的 PPO 核心，而在把业务约束、调度/空驶信号、跨区域共享和离线价值教师塞进同一个训练目标。对于自动出价，最值得迁移的是“可行动作投影 + 拉格朗日预算约束 + 辅助业务预测”这一组合，而不是直接照搬双教师 critic。

论文：[Dynamic Pricing Strategy Optimization Based on a Reinforcement Learning PPO Algorithm: An Empirical Study on Ride-Hailing Platforms](https://doi.org/10.4018/JOEUC.406688)  
作者：Zhaozhi Zhang  
期刊：*Journal of Organizational and End User Computing*, 38(1), 2026, pp. 1–43  
代码：论文未提供。  
版本：开放获取版；本文据作者上传的全文及期刊页面整理，完成于 2026-09-08。

---

## 1. 前置信息：总览、摘要与引言

### 1.1 一句话总览

每个时段、每个区域输出连续价格乘数 $a_{t,i}$；用 PPO 最大化长期营收与服务质量，同时用对偶变量压住空驶/调度预算和收入或价格不公平，用机制层将原始动作投影到可发布价格，再让调度成功率、重定位价值和两种离线 Q 教师帮助学习。

### 1.2 研究背景与核心问题

网约车的加价同时改变乘客需求、司机供给、匹配率和空驶。只把即时 GMV 当回报会诱导极端峰时加价；只事后加规则又会破坏策略优化。论文因此把问题拆为五个缺口：

1. **多目标冲突：** 营收、等候时间、司机收入公平、用户价格公平与重定位成本无法由一个固定 reward 权重稳定协调。
2. **可执行性：** 连续策略直接吐出的乘数可能突破封顶、最低价或区域差价规则。
3. **系统耦合：** 定价不直接做派单/调度，却会通过需求与供给的空间变化影响两者。
4. **大规模区域：** 一区一套网络数据效率差；全共享又抹平区域异质性。
5. **值估计：** 纯 on-policy PPO 样本效率有限，尤其面对非平稳供需。

### 1.3 论文声称的五项贡献

论文把方法命名为 **PRIME-PPO**（Pricing with Repositioning Integration, Mechanism-awareness, and Equity via PPO）：

| 模块 | 做法 | 解决的问题 |
|---|---|---|
| Primal–dual | 对空驶/重定位成本与公平偏差维护 $λ_{src},\lambda_{fair}$ | 把软约束变成自适应惩罚 |
| Mechanism-aware | 有界动作映射、硬边界与软不等式惩罚 | 输出可发布、合规的价格 |
| Auxiliary | 预测派单成功 $y_t^{disp}$，回归重定位价值 $v_t^{repo}$ | 让定价表征看到系统后果 |
| Group sharing | 共享编码器 + 概率化区域组 adapter | 兼顾规模与异质性 |
| Dual-critic distillation | TD3 连续 Q 与 DQN 离散 Q 蒸馏进 PPO critic | 希望降低方差、获得价格弹性边界 |

**关键判断：** 前三项是一个相当自然且可部署的约束 RL 配方；后两项需要完整实现、环境和消融才能证明其增益，本文没有开源代码，因而不能据结果表直接认定它们在真实线上同样有效。

### 1.4 快速读图：端到端数据流（对应 Figure 1）

论文 Figure 1 的信息流可用下图等价阅读（此图是结构转写，不是原图）：

```text
区域供需、等待、历史乘数 s_t
        │
共享编码器 f_enc ──> 区域组 adapter ──> z_{t,i}
        │                                      │
        ├─> actor π_θ ─> 原始连续动作 ã_t ─> 机制映射/掩码 ─> 合规价格 a_t
        │                                      │
        ├─> PPO critic Q_ψ <── TD3 连续 Q、DQN 离散 Q（蒸馏）
        └─> 辅助头：派单概率、重定位价值

轨迹回报/成本 ─> 拉格朗日 reward ─> PPO 更新；
批量成本违规 ─> λ_src、λ_fair 对偶上升。
```

**直观理解：** actor 只负责“给价”；其他模块不是额外在线决策器，而是规定它能给什么价、如何为系统性后果付费，以及如何更快学会评估该价格。

---

## 2. 相关工作

论文把既有工作概括为三条线：早期规则化 surge pricing 与价格弹性模型关注短期供需；强化学习能够按状态连续决策，但常只优化收益或单一公平目标；多目标/分层强化学习能表达 trade-off，却面临城市级多区域扩展问题。作者的定位是把“公平 + 预算 + 调度重定位外溢 + 可行动作 + 可扩展表征”合并到 PPO。

**阅读提示：** 这不是对一个已知基准任务的轻量 PPO 改动，而是一篇系统组合论文。因此公平定义、模拟器如何从离线订单生成反事实价格响应、以及每个 baseline 是否等预算训练，比算法名称更决定结论强度。

---

## 3. 问题定义：受约束的区域级 MDP

### 3.1 MDP、状态、动作与奖励（公式 1–8）

论文把系统写成受约束 MDP：

$$
\mathcal{M}=\langle\mathcal{S},\mathcal{A},P,r,\gamma,\mathcal{C}\rangle . \qquad \text{(1)}
$$

$$
s_t\in\mathcal{S}. \qquad \text{(2)}
$$

$$
a_t=(a_{t,1},a_{t,2},\ldots,a_{t,G})\in\mathcal{A}\subseteq\mathbb{R}^{G}. \qquad \text{(3)}
$$

这里 $G$ 是区域数，$a_{t,i}$ 是区域 $i$ 的基础价乘数。状态文字说明包含区域需求强度、司机供给分布、等候时间和历史价格乘数。

$$
\mathcal{A}^{feas}_t=\{a_t\in\mathbb{R}^{G}\mid l_t\le a_t\le u_t,\;g_t(a_t)\le0\}. \qquad \text{(4)}
$$

$$
r_t^{base}=\alpha\,\mathrm{Revenue}_t-\beta\,\mathrm{Wait}_t. \qquad \text{(5)}
$$

$$
\mathbb{E}_{\pi_\theta}\!\left[\sum_{t=0}^{\infty}\gamma^t c_t^{src}\right]\le B. \qquad \text{(6)}
$$

$$
\mathbb{E}_{\pi_\theta}\!\left[\sum_{t=0}^{\infty}\gamma^t c_t^{fair}\right]\le\delta. \qquad \text{(7)}
$$

$$
\max_{\pi_\theta}\;\mathbb{E}_{\pi_\theta}\!\left[\sum_{t=0}^{\infty}\gamma^t r_t^{base}\right]
\quad\text{s.t. 公式（6）、（7）与 }a_t\in\mathcal{A}^{feas}_t. \qquad \text{(8)}
$$

其中 $c_t^{src}$ 是空驶/重定位成本，$B$ 为对应预算；$c_t^{fair}$ 是司机或区域之间的不公平度，$\delta$ 是容忍度。论文没有把 $\alpha,\beta$ 的具体取值、$c_t^{fair}$ 的单一可复现公式完整固定在问题定义处；实验部分又使用 JFI 和用户可比样本价格 CV，故“公平”其实存在至少两个评估口径。

### 3.2 符号表（Table 1）

| 符号 | 论文含义 |
|---|---|
| $s_t$ / $a_t$ | 时刻 $t$ 的系统状态 / 区域价格乘数动作 |
| $\pi_\theta$ / $r_t$ / $\gamma$ | 定价策略 / 即时平台回报 / 折扣因子 |
| SRC, $B$ | 服务重分配（空驶或重定位）成本及预算 |
| $F$, $\varepsilon$ | 不平等公平度量及其上界 |
| $\lambda_s$, $\lambda_f$ | SRC 与公平约束的对偶变量 |

---

## 4. PRIME-PPO 方法

### 4.1 原始–对偶约束 PPO（公式 9–18）

先看无约束收益：

$$
\max_\theta J(\pi_\theta)=\mathbb{E}_{\pi_\theta}\!\left[\sum_{t=0}^{\infty}\gamma^t r_t^{base}\right]. \qquad \text{(9)}
$$

论文将两个累计成本并列约束：

$$
\mathbb{E}_{\pi_\theta}\!\left[\sum_t\gamma^t c_t^{src}\right]\le B,\quad
\mathbb{E}_{\pi_\theta}\!\left[\sum_t\gamma^t c_t^{fair}\right]\le\delta. \qquad \text{(10)}
$$

拉格朗日目标和塑形 reward 为：

$$
\mathcal{L}(\theta,\lambda_{src},\lambda_{fair})=
J(\pi_\theta)-\lambda_{src}(J_{src}-B)-\lambda_{fair}(J_{fair}-\delta),
\quad \lambda_{src},\lambda_{fair}\ge0. \qquad \text{(11)}
$$

$$
r_t^{lag}=r_t^{base}-\lambda_{src}c_t^{src}-\lambda_{fair}c_t^{fair}. \qquad \text{(12)}
$$

$$
\hat A_t=\sum_{l=0}^{\infty}(\gamma\tau)^l\delta_{t+l}^{V},\qquad
\delta_t^V=r_t^{lag}+\gamma V_\psi(s_{t+1})-V_\psi(s_t). \qquad \text{(13)}
$$

$$
\rho_t(\theta)=\frac{\pi_\theta(a_t\mid s_t)}{\pi_{\theta_{old}}(a_t\mid s_t)}. \qquad \text{(14)}
$$

$$
\mathcal{L}^{clip}(\theta)=\mathbb{E}_t\!\left[\min\left(\rho_t\hat A_t,\operatorname{clip}(\rho_t,1-\epsilon,1+\epsilon)\hat A_t\right)\right]. \qquad \text{(15)}
$$

$$
\mathcal{L}^{value}(\psi)=\mathbb{E}_t\!\left[(V_\psi(s_t)-\hat R_t^{lag})^2\right]. \qquad \text{(16)}
$$

$$
\mathcal{L}^{ent}(\theta)=-\mathbb{E}_t\!\left[\mathcal H(\pi_\theta(\cdot\mid s_t))\right]. \qquad \text{(17)}
$$

$$
\mathcal{L}_{PPO}=-\mathcal{L}^{clip}+\kappa\mathcal{L}^{value}+\eta_{ent}\mathcal{L}^{ent}. \qquad \text{(18)}
$$

**直观理解：** 当成本均在阈值内，$\lambda$ 较小，策略接近普通 PPO；违规的 batch 会推高 $\lambda$，使之后同类动作的优势变小。这比人为固定“公平权重 = 0.1”更会随运行状态调节，但只保证训练目标的约束趋向，并不自动等于线上逐时段硬合规。

### 4.2 机制感知的动作实现（公式 19–23）

公式（19）再次明确可行动作集合：

$$
\mathcal{A}^{feas}_t=\{a_t\in\mathbb{R}^G\mid l_t\le a_t\le u_t,\;g_t(a_t)\le0\}. \qquad \text{(19)}
$$

actor 先采样无界高斯动作 $\tilde a_t$，再经 $\tanh$ 与区间缩放：

$$
\tilde a_t\sim\mathcal{N}(\mu_\theta(s_t),\sigma_\theta^2(s_t)),\qquad
a_t^{raw}=\tanh(\tilde a_t). \qquad \text{(20)}
$$

$$
a_t^{bound}=l_t+\frac{a_t^{raw}+1}{2}\odot(u_t-l_t). \qquad \text{(21)}
$$

$$
a_t=\Pi_{\{g_t(a)\le0\}}(a_t^{bound}),\qquad
r_t^{mech}=r_t^{lag}-\eta_{mech}\,[g_t(a_t)]_+. \qquad \text{(22)}
$$

有界变换必须修正 log-probability：

$$
\log\pi_\theta(a_t\mid s_t)=\log\mathcal N(\tilde a_t;\mu_\theta(s_t),\sigma_\theta^2(s_t))
-\sum_{i=1}^{G}\log\bigl(1-\tanh^2(\tilde a_{t,i})\bigr). \qquad \text{(23)}
$$

**边界条件：** 文中提及价格下限、surge cap、预算与跨区价格差，但没有给出 $g_t$ 的实际规则、投影算子实现或“可比用户/区域”的判定。因此该层是正确的工程接口，却不是可直接复现的机制设计。

### 4.3 调度与重定位的辅助信号（公式 24–28）

共享编码器给出 $h_t$。派单头输出请求被成功匹配的概率：

$$
\hat y_t^{disp}=\sigma(f_{\omega_d}(h_t,a_t)). \qquad \text{(24)}
$$

$$
\mathcal L_{disp}=-\mathbb E_t\!\left[y_t^{disp}\log\hat y_t^{disp}+(1-y_t^{disp})\log(1-\hat y_t^{disp})\right]. \qquad \text{(25)}
$$

重定位头回归由模拟器提供的“未来收益减空驶成本”价值：

$$
\hat v_t^{repo}=f_{\omega_r}(h_t,a_t). \qquad \text{(26)}
$$

$$
\mathcal L_{repo}=\mathbb E_t\!\left[(\hat v_t^{repo}-v_t^{repo})^2\right]. \qquad \text{(27)}
$$

$$
\mathcal L_{aux}=\eta_d\mathcal L_{disp}+\eta_r\mathcal L_{repo}. \qquad \text{(28)}
$$

**直观理解：** 它并没有让模型“直接派车”，而是让同一表征不得不预测“这个价之后能不能匹配、会不会造成更大的空间失衡”。这是一种比在 reward 里硬塞很多项更平滑的 credit assignment；前提是标签来自可信的调度回放或仿真器。

### 4.4 TD3/DQN 双教师值蒸馏（公式 29–34）

连续教师采用 TD3 风格 TD 损失与双 Q 最小 target：

$$
\mathcal L_{det}(\phi)=\mathbb E\!\left[(Q^{det}_\phi(s_t,a_t)-y_t^{det})^2\right]. \qquad \text{(29)}
$$

$$
y_t^{det}=r_t+\gamma\min_{j=1,2}Q^{det-}_{\phi_j}(s_{t+1},\pi_{\theta^-}(s_{t+1})). \qquad \text{(30)}
$$

离散教师在离散乘数格点 $\tilde{\mathcal A}$ 上学习：

$$
\mathcal L_{disc}(\varphi)=\mathbb E\!\left[(Q^{disc}_\varphi(s_t,\tilde a_t)-y_t^{disc})^2\right]. \qquad \text{(31)}
$$

$$
y_t^{disc}=r_t+\gamma\max_{\tilde a'\in\tilde{\mathcal A}}Q^{disc-}_\varphi(s_{t+1},\tilde a'). \qquad \text{(32)}
$$

主 critic 同时拟合两位教师，$\operatorname{sg}$ 表示 stop-gradient：

$$
\mathcal L_{dist}(\psi)=\mathbb E\!\left[
(Q^{main}_\psi(s_t,a_t)-\operatorname{sg}Q^{det}_\phi(s_t,a_t))^2+
(Q^{main}_\psi(s_t,\tilde a_t)-\operatorname{sg}Q^{disc}_\varphi(s_t,\tilde a_t))^2
\right]. \qquad \text{(33)}
$$

$$
\mathcal L_{critic}=\mathcal L_{value}(\psi)+\eta_{dist}\mathcal L_{dist}(\psi). \qquad \text{(34)}
$$

**需审慎解读：** PPO 的数据是 on-policy，而 TD3/DQN 教师使用 replay buffer；蒸馏不等于仍拥有严格的 on-policy 优化保证。论文也没有给出离散价格格点数、replay ratio、target-update 频率及教师预训练细节，这一模块是复现实验的最大缺口之一。

### 4.5 分层分组与参数共享（公式 35–40）

区域 $i$ 对 $K$ 个潜在组软分配：

$$
p(g\mid i)=\frac{\exp(\phi_g^\top e_i)}{\sum_{h=1}^{K}\exp(\phi_h^\top e_i)}. \qquad \text{(35)}
$$

$$
h_t=f_{enc}(s_t). \qquad \text{(36)}
$$

$$
z_{t,i}=\sum_{g=1}^{K}p(g\mid i)\,\mathcal A_g(h_t). \qquad \text{(37)}
$$

组 adapter 做 L2 衰减与相似组平滑：

$$
\mathcal L_{reg1}=\sum_{g=1}^{K}\lVert\theta_g\rVert_2^2. \qquad \text{(38)}
$$

$$
\mathcal L_{reg2}=\mu\sum_{g<h}w_{gh}\lVert\theta_g-\theta_h\rVert_2^2. \qquad \text{(39)}
$$

$$
\mathcal L_{group}=\mathcal L_{reg1}+\mathcal L_{reg2}. \qquad \text{(40)}
$$

这使复杂度主要随组数 $K$ 而不是区域数 $G$ 增长。论文未说明 $K$、$w_{gh}$ 的构造、是否发生组塌缩或组别的可解释性评估。

### 4.6 总目标、对偶更新与训练算法（公式 41–43；Algorithm 1）

$$
\min_{\theta,\psi,\Omega}\mathcal L_{total}=
\mathcal L_{PPO}(\theta)+\kappa\mathcal L_{value}(\psi)+\eta_{aux}\mathcal L_{aux}(\Omega)+\eta_{dist}\mathcal L_{dist}(\psi)+\eta_{group}\mathcal L_{group}. \qquad \text{(41)}
$$

$$
\lambda_{src}\leftarrow\max\{0,\lambda_{src}+\eta_\lambda(\bar c_{src}-b)\}. \qquad \text{(42)}
$$

$$
\lambda_{fair}\leftarrow\max\{0,\lambda_{fair}+\eta_\lambda(\bar c_{fair}-d)\}. \qquad \text{(43)}
$$

算法 1 的循环是：收集 $(s_t,a_t,r_t,c_t^{src},c_t^{fair})$ 并先执行动作可行化；基于拉格朗日 reward 计算 GAE；更新 actor 的 PPO 损失与辅助/分组项；更新 critic 与教师蒸馏；按违规更新对偶变量；最后以 replay buffer 更新 TD3、DQN 教师，直到收敛或训练步数上限。

---

## 5. 实验设计

### 5.1 数据、设置和评估口径

论文正文列出 New York Yellow Taxi（2019–2020，称超过 2 亿行）、Porto Taxi Trajectory（442 辆、15 秒 GPS）、Chicago Taxi（2024 release）与 DiDi GAIA；并称统一使用 80%/10%/10% 训练/验证/测试。actor 和 critic 都是 3 层、每层 256 hidden、ReLU 的 MLP；$\epsilon=0.2$、GAE 的 $\tau=0.95$、$\gamma=0.99$，Adam 初始学习率 $3\times10^{-4}$、余弦退火、梯度裁剪 0.5。实验使用 Python 3.10、PyTorch 2.1、两张 A100 80GB，mini-batch 为 8,192，每数据集 1,000 万环境步；对偶变量初值 0.1、步长 $10^{-3}$，两个辅助权重为 0.5，蒸馏软混合系数 0.3。机制层把乘数经验性限制为 $[0.7,1.5]$。每个模型报告 20 个测试 episode（有些图表又表述 5 个随机种子）。

指标公式如下：

$$
\mathrm{Revenue}=\sum_{i=1}^{N}p_iq_i. \qquad \text{(44)}
$$

$$
\mathrm{OFR}=\frac{\#\,\text{fulfilled requests}}{\#\,\text{total requests}}. \qquad \text{(45)}
$$

$$
\mathrm{JFI}=\frac{(\sum_{j=1}^{M}r_j)^2}{M\sum_{j=1}^{M}r_j^2}. \qquad \text{(46)}
$$

论文还评估平均等待、空驶/重定位距离与收敛 episode 数；这些为定义性度量，未都给出独立编号公式。

结果部分把部分指标用不同下标再次明确：

$$
\mathrm{JFI}=\frac{(\sum_{i=1}^{N}r_i)^2}{N\sum_{i=1}^{N}r_i^2}. \qquad \text{(47)}
$$

$$
\mathrm{Revenue}=\sum_{t=1}^{T}\sum_{i=1}^{M_t}p_i(t)\cdot l_i(t). \qquad \text{(48)}
$$

$$
\mathrm{ETD}=\frac{\sum_{t=1}^{T}\sum_{j=1}^{N_t}d_j(t)}{\sum_{t=1}^{T}M_t}. \qquad \text{(49)}
$$

$$
\mathrm{CV}_{price}=\frac{\sigma_{price}}{\mu_{price}}. \qquad \text{(50)}
$$

公式（44）与（48）均称营收：前者以接受指示 $q_i$ 表示已完成订单金额，后者显式写为动态价格 $p_i(t)$ 与基础价 $l_i(t)$ 的乘积；公式（46）与（47）是同一 JFI 的换下标重述。这里保留重复编号，是为完整覆盖原文而非两种不同指标。

### 5.2 主要结果（Tables 2–4；Figures 2–4）

| 表 | PRIME-PPO | 最强基线 | 论文的结论 |
|---|---:|---:|---|
| Table 2：单 episode 平均营收（$\times10^3$） | **179.6 ± 1.6** | TD3 170.7 ± 2.8 | 高 5.2% |
| Table 3：匹配率 | **89.6 ± 1.1%** | TD3 87.3 ± 1.3% | 高 2.3 pct |
| Table 4：司机收入 JFI | **0.927 ± 0.007** | FaPU 0.911 ± 0.008 | 更均衡 |

Figures 2、3、4 分别画营收收敛、匹配率训练轨迹、JFI 轨迹；图的叙事均是 PRIME-PPO 更快收敛并达到更高平台值。Table 2 的 HAG-PS/JDRCL/JPDR/DHDRDS-DQN/FaPU/TD3/VBMS-Mech 分别为 154.2/161.5/168.9/159.3/165.4/170.7/163.8；Table 3 的前六个（除 VBMS）为 83.7/85.2/86.9/84.4/85.8/87.3%。

### 5.3 城市场景营收、空驶和用户侧公平（Tables 5–8；Figures 5–8）

Table 5 报告另一套量纲为 $\times10^6$ CNY 的总营收：PRIME-PPO 为 **4.38M**，TD3 为 4.18M，作者称提升 4.8%。但这张表与 Table 2 的货币/episode 量纲不同，正文没有给出两者间的城市、时间跨度或汇总关系，不能把数值混为同一实验。

Table 6/Figure 6 是空驶距离比较，作者的结论是 PRIME-PPO 最低；Table 7/Figure 7 用“可比用户行程价格”的 CV 衡量用户侧公平，PRIME-PPO 为 **0.122 ± 0.004**，FaPU 为 0.139 ± 0.005（更低更好）。

预算偏差定义为：

$$
\Delta_{budget}=\frac{1}{T}\sum_{t=1}^{T}\left|\frac{b_t-\hat b}{\hat b}\right|. \qquad \text{(51)}
$$

Table 8/Figure 8 中 PRIME-PPO 的归一化预算偏差为 **0.113 ± 0.004**，低于 VBMS-Mech 的 0.149 ± 0.006、FaPU 的 0.155 ± 0.006、TD3 的 0.162 ± 0.005。这个结果支持“更接近预算”而非“每个时刻从不超预算”。

### 5.4 鲁棒性、综合权衡与弹性（Tables 9–11；Figures 9–11）

需求冲击下，reward 退化定义为：

$$
\Delta_{reward}=\frac{R_{nominal}-R_{shock}}{R_{nominal}}. \qquad \text{(52)}
$$

Figure 9/Table 9 比较 reward degradation 与 matching drop；正文称 PRIME-PPO 最低。Figure 10/Table 10 用归一化营收 $\hat R$、匹配 $\hat M$、等待 $1-\hat W$、公平 $\hat F$ 的雷达/综合分比较，PRIME-PPO 的 trade-off score 是 **0.817**，论文称这意味着 Pareto efficiency。这里应注意：雷达图外沿和加权综合分是作者自定归一化，不构成严格 Pareto 前沿证明。

Figure 11/Table 11 在峰时扫描乘数 $\{0.8,0.9,\ldots,1.4\}$。PRIME-PPO 的“Demand Elasticity”为 **1.42 ± 0.03**，营收曲线二阶差分方差为 **0.036 ± 0.002**；TD3 为 1.15/0.059，FaPU 为 1.18/0.062。论文将其解释为既能响应供需又避免价格曲线剧烈抖动。

### 5.5 消融与显著性（Table 12、Table 13）

Table 12 是最关键的可归因证据。完整模型为营收 112.6、匹配 92.4%、JFI 0.91、等待 3.4 分钟、取消 2.1%；每次移除一个模块：

| 变体 | 营收 ↑ | 匹配 ↑ | JFI ↑ | 等待 ↓ | 取消 ↓ |
|---|---:|---:|---:|---:|---:|
| Full | **112.6** | **92.4%** | **0.91** | **3.4** | **2.1%** |
| $-$Fair | 106.2 | 91.9% | 0.81 | 3.7 | 2.8% |
| $-$Mask | 108.5 | 92.0% | 0.84 | 3.5 | 2.4% |
| $-$Aux | 109.1 | 91.5% | 0.85 | 3.8 | 2.7% |
| $-$Group | 110.2 | 91.6% | 0.86 | 3.6 | 2.5% |
| $-$Distill | 107.3 | 91.8% | 0.83 | 3.7 | 2.6% |

从表中能直接读出的结论是：移除对偶公平/预算项损失最大；蒸馏、机制层也有较大损失；辅助头主要体现在等待和取消。不能直接读出“所有模块彼此协同因果成立”，因为没有二阶组合消融及独立实现细节。

Table 13 对 PRIME-PPO 与 JPDR/FaPU 的五指标做配对 $t$ 检验，报告的 p 值均小于 0.01（例如营收为 0.0031/0.0067，JFI 为 0.0009/0.0042）。这支持**所给评测样本内**差异不太像随机波动；效应量、置信区间和 episode 配对方式被放在文中所称的补充材料，当前可得正文没有完整呈现。

---

## 6. 作者讨论、部署叙述与限制

论文主张：公平与预算通过自适应约束而不是后处理规则被纳入策略；机制掩码把输出约束在监管范围；共享参数使数千区域推理可并行；可异步重训以应对天气/拥堵等非平稳需求。作者估计总训练时间约为 vanilla PPO 的 1.2–1.3 倍，并称所有城市/随机种子未出现崩溃。

论文明确承认两项限制：

1. 公平主要基于收入与价格方差，未覆盖可达性、长期司机福利或人口群体公平；
2. 双 critic 蒸馏和辅助学习会增加高频大规模实时部署的计算负担。

作者还提出先小流量灰度、保留规则兜底、周期性异步重训，而不是替换已有定价系统。

---

## 7. 批判性精读：证据强度与复现风险

### 7.1 论文内在不一致/缺失

| 风险点 | 观察 | 对结论的影响 |
|---|---|---|
| 数据集/城市叙述 | 数据段列 New York、Porto、Chicago、DiDi GAIA；前言和讨论又写 Chengdu、Hangzhou、New York、Chicago | 无法准确映射每张表是哪座城市、哪份原始数据 |
| 任务环境 | 订单日志本身不提供“价格改变后需求、司机重定位”的反事实 | 必须有仿真器或需求模型；论文没有足够细节复现 |
| 公平定义 | 训练约束称 $c_t^{fair}$，评估同时用司机 JFI 和用户价格 CV | 训练到底优化哪个公平目标、两者权衡关系不清楚 |
| 基线与量纲 | Table 2（$\times10^3$）和 Table 5（$\times10^6$ CNY）都称营收比较 | 不应跨表比较绝对收益或计算统一 uplift |
| 双教师细节 | 没有离散格点、replay buffer、教师/目标网络更新配置和预训练策略 | $-$Distill 增益难以独立复验 |
| 可行动作 | $g_t$、投影器、可比区域定义没有落地规则 | “机制合规”是框架声明，非可审计规范 |
| 线上证据 | 全文是离线/仿真评估与部署讨论 | 不可表述为已验证的真实线上增收 |

这不是说方法必然无效；而是更准确的结论应是：**论文提出了合理的约束 RL 系统设计，并在作者定义的实验环境中给出全面优势；但其工业可复现性和外部有效性尚未被公开材料充分证明。**

### 7.2 对自动出价的可迁移映射

| 网约车 PRIME-PPO | 自动出价中的对应物 |
|---|---|
| 区域 $i$ | campaign / ad group / 流量分桶 |
| 价格乘数 $a_{t,i}$ | bid multiplier、目标 CPA/ROAS 调节量 |
| 供需、等待、历史价格 | 流量、竞争、CVR、消耗、近窗出价 |
| 空驶成本 $c^{src}$ | 预算超支、无效消耗、频控/探索成本 |
| 司机收入 JFI、用户价格 CV | advertiser/campaign 间预算公平，或相似流量的价格一致性（需业务授权） |
| 派单成功辅助头 | win-rate / conversion / 有效曝光预测 |
| 重定位价值辅助头 | 预算迁移、后续窗口增量价值预测 |

**建议的最小可行迁移：**

1. 先把 action 设计成受限的增量乘数，例如 $[0.8,1.2]$，并用确定性投影保证账户日预算、出价上限、冷却期等硬规则；
2. 把预算/CPA/ROAS 写成累计约束，以 $\lambda$ 动态调整，而不是靠一组永久 reward 权重；
3. 用 win/conversion/后续价值做共享表示辅助任务；
4. 仅在有可靠离线评估器和 replay 覆盖时再加入 off-policy critic 蒸馏；
5. 上线采用 shadow → 小流量 → 分层 A/B，分别监控 spend pace、CPA/ROAS、波动、探索覆盖与公平指标。

**不建议直接迁移的部分：** 用“公平”惩罚来压不同广告主的收益，可能与投放目标、合约和竞价机制冲突；需先定义受保护对象和可解释的业务约束。DQN 离散教师也会让多维 bid action 的格点数指数膨胀，通常应改为低维 action、分解 Q 或直接省略。

---

## 8. 复现清单

- [ ] 明确决策粒度：区域/广告组、5/15/60 分钟窗口与 observation 延迟。
- [ ] 固化状态、价格/出价 action、硬边界和每个 $g_t(a)$ 的审计日志。
- [ ] 指定 $c^{src}$、$c^{fair}$、阈值 $B,\delta$ 与是否按 day/campaign 重置。
- [ ] 说明反事实环境：需求弹性模型、匹配/归因模型、随机性与 train/test 时间切分。
- [ ] 提供 PPO、GAE、对偶变量、aux 权重及所有 seed。
- [ ] 若用双教师，公开离散格点、replay source/ratio、target 更新、teacher warm-up 与蒸馏系数。
- [ ] 基线统一训练预算、动作空间、机制边界、数据切分和评估 episode。
- [ ] 报告均值、标准差、95% CI、效应量、跨城市/跨账户 holdout，以及所有失败情形。

---

## 9. 覆盖账本与素材说明

| 原文对象 | 覆盖位置 | 状态 |
|---|---|---|
| 摘要、引言、Related Work | 第 1–2 节 | 已覆盖 |
| 公式（1）–（43） | 第 3–4 节 | 已覆盖；按论文文字/符号转写为可移植 LaTex |
| 公式（44）–（52） | 第 5 节 | 已覆盖；（46）/（47）是 JFI 的重复下标写法，（44）/（48）是营收的两种写法 |
| Table 1–13 | 第 3、5 节及表格转录 | 已覆盖；关键数值逐表转录/说明 |
| Figure 1 | 第 1.4 节结构转写 | 已覆盖（原图标题：Overall Architecture） |
| Figure 2–4 | 第 5.2 节 | 已覆盖（营收、匹配、JFI 训练曲线） |
| Figure 5–8 | 第 5.3 节 | 已覆盖（城市营收、空驶、价格 CV、预算偏差） |
| Figure 9–11 | 第 5.4 节 | 已覆盖（冲击鲁棒性、综合雷达、弹性/平滑性） |
| Algorithm 1 | 第 4.6 节 | 已覆盖（输入、6 步迭代和停止条件） |
| Discussion/Deployment/Conclusion | 第 6–7 节 | 已覆盖 |

> **素材限制说明：** 出版社页面与 ResearchGate 全文可读取正文、公式、图表标题和数值，但在本次抓取环境中拒绝 PDF/原图二进制下载（HTTP 403）。为避免把整页截图伪装成图表，本文没有嵌入失真的页图，而是逐项保留图号、标题、读图结论和表值转录；原图可由论文 DOI 页或作者上传全文查看。若后续拿到 PDF，可在本笔记同级 `assets/` 中补入 Figure 1–11 的紧凑裁图，不需改写正文。

---

## 10. 最终结论

PRIME-PPO 的核心启示是：不要把动态定价/自动出价只当成“预测一个最赚钱的动作”，而应明确分离 **硬可行域**、**累计软约束**、**业务外溢的辅助预测** 和 **主决策策略**。论文的结果表明这种组合在其评测环境中同时改善营收、匹配、公平、预算与稳定性；但缺少代码、反事实环境细节和一致的数据集映射，暂不足以当成已验证的生产方案。真正值得优先落地和评估的，是动作投影与预算/效率对偶控制这一小而可审计的闭环。
