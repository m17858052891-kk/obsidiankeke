---
title: "DRIVE：分布式动作、检索增强与价值评估"
aliases:
  - DRIVE论文精读
  - Distributional and Retrieval-Augmented Bidding with Value Evaluation
tags:
  - 论文精读
  - 自动出价
  - 离线强化学习
  - Decision-Transformer
  - 检索增强
  - GMM
  - IQL
paper: https://arxiv.org/abs/2606.14192
pdf: https://arxiv.org/pdf/2606.14192
venue: ICML 2026
status: arXiv v1
date_read: 2026-09-01
---

# DRIVE：Distributional and Retrieval-Augmented Bidding with Value Evaluation

> [!abstract] 一句话结论
> DRIVE 不让 Decision Transformer 直接回归并执行一个“平均动作”，而是先用 **GMM 生成多峰动作候选**、再从历史轨迹中 **检索相似且高 RTG 的动作候选**，最后用 **离线 IQL critic 对候选统一估值并选择**。它真正的创新不是某个单独组件，而是把“提出候选”和“决定执行”解耦。

## 0. 论文信息与阅读导航

- **题目**：DRIVE: Distributional and Retrieval-Augmented Bidding with Value Evaluation
- **作者**：Miduo Cui, Haochen Wang, Shangqin Mao, Xun Yang, Qianlong Xie, Xingxing Wang, Xuri Ge, Ying Zhou, Zhiwei Xu
- **会议**：ICML 2026
- **版本**：arXiv:2606.14192v1，2026-06-12
- **论文**：[arXiv 摘要页](https://arxiv.org/abs/2606.14192) · [PDF](https://arxiv.org/pdf/2606.14192)
- **代码**：论文首页与 arXiv 元数据未给出公开代码链接。

建议先看第 1、4、8 节形成总体认识，再回看公式与附录实现细节。

## 1. 论文到底解决了什么问题？

### 1.1 自动出价中的两个典型失败模式

论文认为，Transformer 式离线策略在自动出价中有两个互相叠加的问题。

1. **平均动作陷阱（Average Action Trap）**：同一类状态下可能同时存在保守出价和激进出价，两者都有效，但用 MSE 回归单个动作会逼近条件均值。这个均值未必对应任何真实的高回报策略，甚至可能落在两个有效模态之间的低价值区域。
2. **稀疏、长尾数据下的生成不可靠**：纯参数模型必须把所有历史经验压进权重；对少见状态或稀疏奖励状态，它容易产生缺乏数据支持的动作。

<p align="center"><img src="./assets/DRIVE Figure 1 - Two Core Challenges.png" width="92%"></p>

*图 1：左侧是多峰动作被点预测压成均值；右侧是稀疏、长尾状态下纯参数策略缺乏可靠锚点。*

图 2 给出 AuctionNet 中的真实例子。蓝线是 DT 的平均动作，红线是局部回报最好的动作，背景点表示离线数据中的动作，颜色越深代表 RTG 越高。高回报动作聚集在某个模态附近，而平均值会偏离它。

<p align="center"><img src="./assets/DRIVE Figure 2 - AuctionNet Failure Cases.png" width="72%"></p>

*图 2：AuctionNet 中两个平均动作失败案例。*

### 1.2 DRIVE 的核心思路

DRIVE 把一次决策拆成两步：

- **候选生成**：参数化的 GMM 负责“泛化”，非参数化检索负责“记忆”；
- **候选决策**：离线训练的双 Q critic 负责“在候选中选谁”。

这比“让一个网络一次性输出最终动作”多了一层显式搜索。它不是在线探索：所有模型训练、索引构建和价值学习都发生在离线数据上，线上只做采样、检索和排序。

## 2. Related Work：论文把自己放在什么位置？

### 2.1 从规则出价到离线强化学习

传统方法包括线性/非线性出价函数、PID 和 Smart Pacing。它们可控、便宜，但往往只优化短期反馈或预定义规则。模型化 RL 能表达长期约束，却有环境建模开销和 sim-to-real 偏差；模型无关 RL 随后直接优化连续出价因子。真实广告系统又很难承担在线探索的经济损失，因此离线 RL 成为更现实的路线。

### 2.2 离线 RL 与序列建模出价

BCQ、CQL、IQL 通过约束策略或保守价值估计处理离线分布偏移；DT 则把 RL 改写成“给定目标回报和历史状态，预测动作”的序列建模问题。GAVE、GAS、Peak-Return Greedy Slicing 分别从价值引导、后训练搜索和数据切片改善 DT 式策略。DiffBid 用扩散模型学习出价分布，但需要多步反向采样，论文同时质疑其长时域反向过程的准确性和实时延迟。

DRIVE 与这些工作的差异是：它保留 DT 的长程条件建模，但不再用单点回归作为终点，而是把分布采样和价值选择接在后面。

### 2.3 检索增强决策

RAG 在语言模型里通过外部证据缓解参数记忆不足；DT-Mem 和 RA-DT 把类似思想带到序列决策。DRIVE 的检索并不是把历史子轨迹拼进 Transformer 上下文，而是把历史动作直接加入候选集。换言之，检索提供的是“可以被执行的动作提案”，critic 再决定是否采纳。

## 3. Preliminaries：自动出价如何写成序列决策？

### 3.1 RTB 约束优化

一个投放周期内有 $N$ 次广告曝光机会。第 $i$ 次曝光的价值、支付和是否获胜分别为 $v_i$、$c_i$ 和 $x_i\in\{0,1\}$。目标是在预算和 KPI 约束下最大化累计价值：

$$
\begin{aligned}
\max_{\{x_i\}_{i=1}^{N}}\quad &\sum_{i=1}^{N}v_ix_i\\
\text{s.t.}\quad &\sum_{i=1}^{N}c_ix_i\le B,\\
&\mathcal{G}_j(x_{1:N})\le \mathcal{K}_j,\quad \forall j.
\end{aligned}
\qquad \text{(1)}
$$

在常见假设下，KKT 条件可导出按价值缩放的最优出价形式：

$$
b_i^*=\lambda v_i.
\qquad \text{(2)}
$$

因此策略真正要动态控制的是缩放因子 $\lambda$，而不是对每一次曝光单独运行一个 Transformer。

> [!note] 直观理解
> 在一个时间窗内，预测模型先给每个曝光一个价值 $v_i$；DRIVE 输出该时间窗共享的调节因子 $a_t=\lambda_t$，再用 $\lambda_t v_i$ 形成各曝光的最终报价。

### 3.2 MDP 与轨迹形式

论文把一天视为一个 episode，并切分成 $T$ 个决策步：

- 状态 $s_t$：预算余量、剩余时间、历史竞价/转化统计和当前流量等广告主与市场信息；
- 动作 $a_t$：当前时间窗内共享的出价调节因子 $\lambda_t$；
- 奖励 $r_t$：该时间窗的转化价值、点击数，以及可选的预算/KPI 违约惩罚；
- 折扣因子 $\gamma$：控制未来收益权重。

离线轨迹被组织为

$$
\tau=(\hat R_0,s_0,a_0,\ldots,\hat R_T,s_T,a_T),
$$

其中 return-to-go 为

$$
\hat R_t=\sum_{i=t}^{T}\gamma^{i-t}r_i.
$$

DT 用轨迹前缀、当前状态和目标 RTG 预测动作。需要注意：RTG 是一个条件信号，不是对某个动作因果价值的证明。

## 4. Methodology：DRIVE 的三个模块

<p align="center"><img src="./assets/DRIVE Figure 3 - Framework.png" width="98%"></p>

*图 3：DRIVE 总体框架。左侧 GMM 与中间检索产生候选，右侧 critic 只负责评估和选择。*

### 4.1 GMM 动作生成：从点预测改成分布预测

DT 式条件策略写作：

$$
a_t\sim\pi(a_t\mid \tau_{0:t-1},\hat R_t,s_t).
\qquad \text{(3)}
$$

标准连续动作 DT 通常用 MSE 学习确定性输出。DRIVE 把动作头换成含 $M$ 个高斯分量的混合密度头：

$$
\left\{\alpha_m,\mu_m,\sigma_m^2\right\}_{m=1}^{M},
\qquad \sum_{m=1}^{M}\alpha_m=1.
\qquad \text{(4)}
$$

条件动作分布为：

$$
P(a_t\mid\tau_{0:t-1},\hat R_t,s_t)
=\sum_{m=1}^{M}\alpha_m\,\mathcal N(a_t\mid\mu_m,\sigma_m^2).
\qquad \text{(5)}
$$

训练目标是历史动作的负对数似然：

$$
\mathcal L_{\mathrm{GMM}}
=-\mathbb E_{\tau\sim\mathcal D}
\left[
\sum_{t=1}^{T}\log\left(
\sum_{m=1}^{M}\alpha_m\mathcal N(a_t\mid\mu_m,\sigma_m^2)
\right)
\right].
\qquad \text{(6)}
$$

推理时从混合分布中采样 $L$ 个候选：

$$
a_t^{(l)}\sim\sum_{m=1}^{M}\alpha_m\mathcal N(\mu_m,\sigma_m^2),
\quad l=1,\ldots,L.
\qquad \text{(7)}
$$

> [!note] 直观理解
> 如果历史上“低价保预算”和“高价抢转化”都是合理模式，GMM 可以分别给两个峰；MSE 只能给它们的平均值。GMM 解决的是候选覆盖问题，但它本身不知道哪个候选在当前状态下最好。

### 4.2 检索增强候选：给稀疏状态一个历史锚点

对每个历史时刻，编码器把完整决策上下文映射为向量：

$$
h_t=f_{\mathrm{enc}}(\tau_{0:t-1},\hat R_t,s_t)\in\mathbb R^d.
\qquad \text{(8)}
$$

索引以 $h_t$ 为 key，以对应动作 $a_t$ 和历史 RTG $\hat R_t$ 为 value。策略编码器可以复用；AuctionNet 的工业规模设置采用独立、低维的轻量 Transformer，降低检索存储与延迟。

推理时先按余弦相似度取 $K_{\mathrm{pool}}$ 个邻居：

$$
\mathcal C_{\mathrm{pool}}
=\left\{(a_k,\hat R_k)\mid
k\in\operatorname{Top}\text{-}K_{\mathrm{pool}}^{\mathrm{sim}}(\mathcal I,h_t)
\right\}.
\qquad \text{(9)}
$$

再按这些邻居存储的 RTG 取前 $K$ 个动作：

$$
\mathcal A_{\mathrm{ret}}
=\left\{a_k\mid
k\in\operatorname{Top}\text{-}K^{\hat R}(\mathcal C_{\mathrm{pool}})
\right\}.
\qquad \text{(10)}
$$

> [!warning] 证据边界
> 高 RTG 说明这个动作出现在一条高回报后续轨迹里，但不等于“该动作造成了高回报”。历史市场、后续策略和未观测变量都可能是混杂因素。相似度过滤与 critic 二次估值能缓解问题，却不能把相关性自动变成因果性。

### 4.3 价值评估：IQL critic 统一裁决

> [!info] 方法背景
> IQL、CQL、BCQ、BEAR、TD3+BC、优势加权行为克隆与 ensemble critic 的统一对照，见 [[离线强化学习方法对照：IQL、CQL、BCQ与价值集成]]。

DRIVE 采用 IQL 训练两个 Q 网络和一个状态价值网络。状态价值通过上分位 expectile 回归逼近数据支持内的较高 Q 值：

$$
\mathcal L_V
=\mathbb E_{(s,a)\sim\mathcal D}\left[
L_2^\eta\left(\min_{i=1,2}Q_i(s,a)-V(s)\right)
\right],
\qquad \text{(11)}
$$

其中

$$
L_2^\eta(u)=\left|\eta-\mathbb I(u<0)\right|u^2,
\quad 0.5<\eta<1.
$$

Q 网络使用由 $V(s')$ 构造的 Bellman 目标：

$$
\mathcal L_Q
=\mathbb E_{(s,a,r,s')\sim\mathcal D}\left[
\left(Q(s,a)-\left(r+\gamma V(s')\right)\right)^2
\right].
\qquad \text{(12)}
$$

CPA 约束任务把原始奖励替换为：

$$
r'=r\times\min\left(
1,\left(\frac{\mathcal K}{C+\epsilon}\right)^\beta
\right),\qquad \beta=2.
\qquad \text{(13)}
$$

$\mathcal K$ 是目标 CPA，$C$ 是实际 CPA。达标时奖励不变，超标时奖励按比例衰减。最后合并两类候选

$$
\mathcal A_{\mathrm{cand}}=\mathcal A_{\mathrm{gen}}\cup\mathcal A_{\mathrm{ret}},
$$

并用双 Q 的较小值作保守排序：

$$
a^*=\arg\max_{a\in\mathcal A_{\mathrm{cand}}}
\min_{i=1,2}Q_i(s,a).
\qquad \text{(14)}
$$

> [!note] 直观理解
> GMM 说“我能想到这些做法”，检索说“历史上相似局面有人这样做过”，critic 则说“按离线价值模型判断，这些候选里谁最值得执行”。

> [!warning] CPA 不是硬保证
> 式（13）是软奖励塑形，不是显式可行域投影、拉格朗日约束或运行时安全屏障。因此论文所说的“安全/可行”应理解为经验上降低违约率，而不是理论保证 CPA 必然满足阈值。

## 5. Experiments：实验如何验证它？

### 5.1 数据集、基线与评价指标

论文在两类场景评估：

- **AuctionNet / AuctionNet-Sparse**：工业自动出价模拟基准。每条轨迹 48 步；Sparse 版本奖励更稀疏、转化区间更小。
- **D4RL**：Gym-MuJoCo 的 locomotion 任务和稀疏奖励 Maze2D，用于检验方法是否只对出价有效。

基线覆盖 CQL、IQL、BCQ、TD3+BC 等经典离线 RL，DT、CDT、PDiT 等序列模型，以及 GAS、GAVE、DiffBid 等自动出价方法。AuctionNet 主指标是累计价值 $\sum r$；约束实验另看经过式（13）塑形的 score 与 CPA exceed rate。D4RL 使用标准 normalized score。

### 5.2 主结果：AuctionNet

<p align="center"><img src="./assets/DRIVE Table 1 - AuctionNet Results.png" width="100%"></p>

*表 1：AuctionNet 与 AuctionNet-Sparse 在五档预算下的结果；10 个随机种子。*

常规 AuctionNet 上，DRIVE 的五档平均值为 **386.6**，高于 CQL 的 378.4 和 CDT 的 369.6；在 50%、100%、125%、150% 预算上为最佳。Sparse 平均值 **36.08**，只比 CQL 的 **36.06** 高 0.02。

论文正文使用了“在所有预算设置持续优于”的强表述，但表 1 更细致：常规数据的 75% 预算是 CQL 300 高于 DRIVE 297；Sparse 的 75% 和 125% 预算也是 CQL 更高。因此可靠结论是“**平均表现领先且多数预算档领先**”，而不是“每一格都最优”。

### 5.3 主结果：D4RL

<p align="center"><img src="./assets/DRIVE Table 2 - D4RL Results.png" width="100%"></p>

*表 2：D4RL Gym-MuJoCo 与 Maze2D 结果；DRIVE 自身结果报告 5 个种子的均值与标准差。*

- Gym 九项平均 **79.7**，高于 IQL 77.0、PDiT 76.3；walker2d-medium-replay 为 82.0，相比 DT 71.5 约提升 14.7%。
- Maze2D 平均 **92.5**，主要来自 maze2d-medium 的 136.8；可视化显示其能避免 DT 的撞墙或停滞。
- 但 DRIVE 并非逐任务最优：maze2d-umaze 的 56.3 明显低于 CQL 94.7，maze2d-large 的 84.4 也低于 TD3+BC 88.6。

### 5.4 组件消融：两个候选源缺一不可吗？

<p align="center"><img src="./assets/DRIVE Table 3 - Component Ablation.png" width="72%"></p>

*表 3：Actor Only、仅检索+critic、仅生成+critic和完整 DRIVE。*

完整 DRIVE 在五档预算都最好。只用检索+critic 在多个预算下甚至弱于原始 actor；只用 GMM 生成+critic 更稳定，但仍低于两类候选的并集。这说明提升不是“critic 随便重排一下就行”，也不是“把历史最佳动作直接拿来就行”，而是参数化泛化与非参数化记忆的互补。

### 5.5 GMM 与扩散动作头

<p align="center"><img src="./assets/DRIVE Table 4 - GMM versus Diffusion.png" width="70%"></p>

*表 4：同一 Transformer 骨干和 IQL critic 下，GMM 与 100 步 DDPM 动作头对比。*

GMM 在四个预算档更好，125% 预算略低；更重要的是每步约 **11 ms**，而 100 步扩散约 **223 ms**。这支持论文的工程判断：低维连续出价动作里，GMM 已能表达必要多峰性，扩散带来的额外灵活度不一定抵得过实时成本。

### 5.6 Q 函数是否真的多峰？

<p align="center"><img src="./assets/DRIVE Table 5 - Q Multimodality.png" width="70%"></p>

*表 5：在 2,000 个状态上分析 Q 曲线形状与 DT 次优程度。*

作者把动作空间均匀离散为 100 点：Q 曲线只有 1 个局部峰视为 unimodal，至少 2 个局部峰视为 multimodal；DT 动作的 Q 低于 100 个动作的第 80 百分位则计为 suboptimal。

- 多峰状态占 17.6%；
- 多峰状态中 DT 次优率 54.7%，单峰状态为 38.2%；
- DT 到最优动作 $a^*=\arg\max_aQ(s,a)$ 的平均距离从 4.24 增至 6.10。

这提供了“平均动作陷阱”不是纯示意图的定量证据。不过峰的数量依赖动作离散粒度和所学 critic；它描述的是估计 Q 面，而非真实环境价值面的直接观测。

### 5.7 跨骨干泛化

<p align="center"><img src="./assets/DRIVE Figure 4 - Backbone Generalization.png" width="68%"></p>

*图 4：把 DRIVE 组件接到 BC、PDiT、CDT 和 DT 后的预算平均值。*

四种骨干平均值都改善，其中 PDiT 从 317.2 到 378.0，绝对增加 60.8、相对约 19.2%。这说明框架不依赖标准 DT。但“每个预算都一致改善”仍不完全成立：附录表 10 中，75% 预算下 DT 为 298，DT+DRIVE 为 297。

## 6. 附录 A：实现与训练细节

### A.1 记号表

<p align="center"><img src="./assets/DRIVE Table 6 - Notation.png" width="82%"></p>

*表 6：论文完整符号表。核心区分是 $L$ 个生成动作、$K_{\mathrm{pool}}$ 个初检邻居和最终保留的 $K$ 个检索动作。*

### A.2 完整算法

<p align="center"><img src="./assets/DRIVE Algorithm 1 - Full Workflow.png" width="86%"></p>

*算法 1：三段离线准备加一段在线推理。*

算法揭示一个容易忽略的事实：DRIVE **不是端到端联合训练**。

1. 用式（6）训练 GMM 策略；
2. 编码离线轨迹并构建检索索引；
3. 用式（11）和（12）独立训练 IQL critic；
4. 推理时才把式（7）的采样动作和式（10）的检索动作合并，再按式（14）选择。

这种模块化设计便于替换骨干和 critic，也意味着候选分布不会根据 critic 的错误被反向共同修正。

### A.3 检索工程实现

- 建索引时删除 $\hat R_t=0$ 的 transition，减少无收益样本与索引内存；
- 使用 FAISS HNSW 近似最近邻；
- embedding 先归一化，再以内积实现余弦相似度；
- 实际先过采样约 $3K$ 个近邻，过滤无效项后按存储 RTG 取最终 $K$ 个；
- HNSW 提供速度/召回折中，但论文没有报告其近似检索召回率，无法判断漏检对最终策略的影响。

### A.4 网络和超参数

<p align="center"><img src="./assets/DRIVE Table 7 - Model Configurations.png" width="88%"></p>

*表 7：AuctionNet 主策略、独立检索编码器与 D4RL 模型配置。*

AuctionNet 主策略为 6 层、512 维、8 头 Transformer，窗口长度 20；检索编码器仅 3 层、64 维、4 头，但上下文长度为完整 48 步。D4RL 不使用独立编码器，直接检索策略骨干的上下文化表示。

<p align="center"><img src="./assets/DRIVE Table 8 - Critic Hyperparameters.png" width="72%"></p>

*表 8：IQL critic 配置。两类任务均使用 $\eta=0.7$、$\gamma=0.99$；AuctionNet 的 Q/V 网络更窄。*

## 7. 附录 B：数据与环境细节

<p align="center"><img src="./assets/DRIVE Figure 5 - Benchmark Environments.png" width="88%"></p>

*图 5：AuctionNet 出价仿真流程，以及 D4RL locomotion/Maze2D 环境。*

### B.1 AuctionNet 数据

<p align="center"><img src="./assets/DRIVE Table 9 - AuctionNet Statistics.png" width="70%"></p>

*表 9：AuctionNet 和 Sparse 版本的数据统计。*

两版均含 479,376 条轨迹、9,987 个投放周期、每轨迹 48 步、16 维状态和 1 维动作。普通版总转化范围 $[0,1512]$，Sparse 仅 $[0,57]$；CPA 范围也从 $[6,12]$ 变成 $[60,130]$，构成更困难的稀疏反馈场景。每个投放周期约含 50 万次曝光、48 个广告主。

16 个状态特征包括：剩余时间、剩余预算、历史/最近三步平均出价、历史/最近三步最低赢标价、pValue、转化、赢标率，当前平均 pValue 与流量数，以及最近三步和历史累计流量数。

<p align="center"><img src="./assets/DRIVE Figure 6 - Dense and Sparse Action Distributions.png" width="94%"></p>

*图 6：普通与稀疏版本在动作频次和 RTG 着色下都呈现多峰与长尾。*

### B.2 D4RL 的作用

Gym-MuJoCo 的 medium-replay 混合了训练早期探索噪声与较好行为；Maze2D 则天然允许绕障碍物的多个有效方向。两者分别检验“混合质量数据”和“多条可行路径”是否会让点回归产生折中动作。

## 8. 附录 C：补充结果与稳健性

### C.1 六个平均动作案例

<p align="center"><img src="./assets/DRIVE Figure 7 - Average Action Failure Cases.png" width="92%"></p>

*图 7：六个检索邻域中的经验动作分布、DT 均值动作与最高回报动作。*

论文定义两者差距为：

$$
\mathrm{Gap}=\left|a_{\mathrm{DT\ mean}}-a_{\mathrm{optimal}}\right|.
$$

图中最优动作通常位于高密度模态，而均值落在模态之间。不过“optimal”是该检索邻域中回报最高的历史动作，不应解读为全局真实最优动作。

### C.2 Maze2D 轨迹

<p align="center"><img src="./assets/DRIVE Figure 8 - Maze2D Trajectories.png" width="96%"></p>

*图 8：maze2d-medium 和 maze2d-large 各四个随机种子；论文称未手工筛选成功案例。*

展示的八组比较里，DRIVE 均形成无碰撞到达路径，DT 经常撞墙或停滞。这是有说服力的定性结果，但样本数仍小，不能替代完整成功率统计。

### C.3 分投放周期的 Q 多峰性

<p align="center"><img src="./assets/DRIVE Figure 9 - Q Function Multimodality.png" width="96%"></p>

*图 9：P7–P13 各周期中，多峰状态比例、DT 次优率和到最优动作距离。*

多峰比例在不同周期都不是零，且多峰组总体有更高次优率与更大动作距离，说明表 5 的平均结果不是由单一周期主导。

### C.4 不同骨干的逐预算结果

<p align="center"><img src="./assets/DRIVE Table 10 - Backbone Generalization.png" width="100%"></p>

*表 10：BC、PDiT、CDT、DT 接入 DRIVE 前后的逐预算数值。*

平均增益分别为 +16.9、+60.8、+24.8、+29.4。PDiT 获益最大，支持“显式候选与检索锚点能补足不同序列策略”的主张；DT 的 75% 预算出现 1 分退化，提醒我们不要把平均提升写成逐点单调提升。

### C.5 CPA 感知 critic

<p align="center"><img src="./assets/DRIVE Figure 10 - Constraint Aware Critic.png" width="84%"></p>

*图 10：加入 CPA 奖励塑形后，总分略降或接近，但 CPA 超标率下降。*

这说明 critic 确实能把任务约束编码进排序信号。但图中超标率仍在约 30%–47% 区间，并未消失，再次说明它是风险折中而非硬安全约束。

### C.6 IQL 与 CQL critic

<p align="center"><img src="./assets/DRIVE Figure 11 - IQL versus CQL Critic.png" width="68%"></p>

*图 11：低预算时两者接近；预算增大后 IQL critic 的优势扩大。*

正文先说“两种 critic 表现可比”，随后又说 IQL 显著胜出，措辞略有冲突。结合图和图注，更准确的解读是：低预算相近，较高预算下 IQL 更好；作者据此把 IQL 设为默认 critic。

### C.7 生成采样数 $L$

<p align="center"><img src="./assets/DRIVE Figure 12 - Sampling Size Sensitivity.png" width="68%"></p>

*图 12：$L=1,4,8,16,32$ 时结果总体平稳；带检索版本始终更高。*

候选越多并不单调改善，说明 GMM 在很小的 $L$ 下已能给出可用候选；检索提供的高质量锚点比盲目扩大采样更稳定。

### C.8 检索动作数 $K$

<p align="center"><img src="./assets/DRIVE Figure 13 - Retrieval Count Sensitivity.png" width="68%"></p>

*图 13：只检索基线随 $K$ 增大明显变好，完整 DRIVE 对 $K$ 不敏感。*

只依赖检索时，需要较大的邻居池才能覆盖好动作；完整 DRIVE 即使 $K=1$ 也接近最优，说明 GMM 候选降低了对检索数量的依赖。

### C.9 计算成本

- DT 平均每步 **10.44 ms**；DRIVE 为 **46.38 ms**；
- DRIVE 中 GMM 采样+检索共 **39.01 ms**，critic 评估 **7.37 ms**；
- 论文称典型 RTB 时延门槛为 50 或 100 ms，因此 46.38 ms 可用，但相对 50 ms 门槛余量只有约 3.6 ms；
- DT 峰值 CPU 内存 **9.36 GB**，DRIVE **28.94 GB**，其中 FAISS 索引约 **13.33 GB**，占新增内存的大头；
- 策略训练、索引构建和 critic 训练均为离线成本。

论文报告了三次运行的墙钟平均值，却没有在该段明确给出测量硬件与线上并发条件。因此这些数字能证明“单次离线实验实现达到几十毫秒级”，不能直接等同于生产集群的尾延迟 SLA。

## 9. 这篇论文最值得记住的三点

### 9.1 真正的抽象：proposal 与 selection 解耦

DRIVE 可以抽象为一个通用离线决策模板：

1. **生成器**覆盖参数模型学到的多种可能动作；
2. **检索器**补回参数模型不容易记住的长尾经验；
3. **价值器**在有限、相对有数据支持的候选上做选择。

这个框架比“GMM 用于出价”更有复用价值，也解释了它为什么能接入 BC、PDiT、CDT 和 DT。

### 9.2 它对平均动作问题的回答是“保留模态，再搜索”

单纯把 MSE 换成似然只能保留多峰，不能保证抽中的样本最好；单纯用 critic 在连续动作空间求最大又容易选到离线分布外动作。DRIVE 的折中是先构造一个有限候选集，再在集合内估值，降低连续空间外推风险。

### 9.3 检索不是最终答案，而是可拒绝的证据

历史动作不会被直接执行。它与生成动作同池竞争，critic 可以拒绝一个“相似但不合适”的历史案例。这种把检索结果作为 proposal 而非 oracle 的设计，比直接复制邻居动作更稳健。

## 10. 局限、疑问与可继续研究的方向

1. **没有真实线上 A/B 测试**：证据来自 AuctionNet 仿真与 D4RL，尚不能证明在线广告市场中的收益、尾延迟和稳定性。
2. **CPA 仅软约束**：奖励塑形能降低超标率，却没有理论可行性保证；严格业务约束还需要运行时投影、拉格朗日控制或安全层。
3. **RTG 检索可能带选择偏差**：按历史 RTG 筛动作混合了动作、状态和后续策略效果，最好补充仅相似度、优势值过滤、因果校正等对照。
4. **critic 仍可能错误排序**：候选虽比全动作空间更受数据支持，但 GMM 仍可能采到分布边缘，检索近邻也可能发生语义错配。论文没有给 critic 校准误差或候选覆盖率分析。
5. **检索索引成本不小**：峰值内存约从 9.36 GB 增至 28.94 GB；需要进一步研究量化、分层索引、冷热分区和索引刷新。
6. **复现信息仍有空缺**：论文给了网络与主要超参，但代码未公开，且没有完整说明 GMM 分量数 $M$、默认 $L/K/K_{\mathrm{pool}}$ 的全部最终取值及延迟测试硬件。
7. **统计显著性需要更谨慎**：AuctionNet 报 10 seeds、D4RL 的 DRIVE 报 5 seeds，但部分基线值取自原论文，实验协议未必完全同源；Sparse 相比 CQL 的平均优势只有 0.02。
8. **“多峰”由 learned Q 定义**：Q 面的峰可能来自真实多策略，也可能来自 critic 估计噪声；可用环境 rollout 或不确定性估计进一步验证。

## 11. 与自动出价研究脉络的关系

- 相比 [[Decision Transformer]]：DRIVE 保留 RTG 条件序列建模，但把确定性动作头改为分布候选，并增加检索和价值重排。
- 相比 [[GRAD：生成式预训练与多专家动作探索]]：两者都不满足于单点动作；DRIVE 更强调离线历史检索与 critic 选择，核心问题是多峰/稀疏支持，而不是专家路由本身。
- 相比扩散式出价：DRIVE 选择表达力较受限但一步采样快的 GMM，以换取实时性。
- 相比纯 CQL/IQL 策略：DRIVE 没让价值方法直接在整个连续动作空间输出动作，而是把 critic 限定为候选排序器。

## 12. 最终评价

DRIVE 是一篇“问题定义清楚、系统组合合理、实验覆盖较完整”的自动出价离线 RL 工作。它最有说服力的部分是：平均动作失败案例、Q 多峰统计、生成/检索互补消融，以及从扩散 223 ms 降到 GMM 11 ms 的工程选择。

同时，读者应把结论控制在证据范围内：它在多个基准的平均结果上领先，但不是每个预算和每个任务都最优；CPA 感知是软惩罚；检索 RTG 不是因果价值；最关键的真实线上 A/B 证据仍然缺失。因此，DRIVE 更像一个有潜力的离线候选搜索范式，而不是已经完成生产安全证明的自动出价系统。

论文的 Impact Statement 是 ICML 常见的通用表述，没有进一步讨论广告竞价可能涉及的预算风险、平台公平性或反馈回路；这些生产影响仍需单独评估。

## 公式与对象覆盖说明

- **正文结构**：摘要、引言、三组相关工作、两组预备知识、方法 4.1–4.3、实验 5.1–5.5、结论与 Impact Statement 均已覆盖。
- **技术附录**：A.1–A.4、B.1 数据与环境细节、C.1–C.9 补充实验均已覆盖。
- **公式**：原文编号公式（1）–（14），以及 RTG、expectile 非对称损失、候选集合并和 Gap 定义均已转写为可移植 LaTeX。
- **视觉对象**：图 1–13、表 1–10、算法 1 均使用原始矢量资源或紧裁剪对象插入；没有使用整页 PDF 截图。
