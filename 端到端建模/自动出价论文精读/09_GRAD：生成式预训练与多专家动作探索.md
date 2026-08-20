---
tags:
  - 自动出价
  - 生成式决策
  - Decision Transformer
  - Mixture-of-Experts
  - ActionMoE
  - AuctionNet
  - KDD2026
created: 2026-08-19
---

# GRAD：生成式预训练与多专家动作探索

论文：[Generative Large-Scale Pre-trained Models for Automated Ad Bidding Optimization](https://arxiv.org/abs/2508.02002)  
PDF：[arXiv PDF](https://arxiv.org/pdf/2508.02002)  
会议：KDD 2026  
作者：Yu Lei、Jiayang Zhao、Yilei Zhao、Zhaoqi Zhang、Linyou Cai、Qianlong Xie、Xingxing Wang  
机构：北京邮电大学、美团、南洋理工大学  
代码：论文与 arXiv 页面未提供官方代码仓库

## 1. 前置信息：总览、摘要与引言

### 1.1 一句话总览

GRAD 在 Decision Transformer 式因果序列生成器上增加两个模块：用 **ActionMoE** 在历史动作附近构造并融合多种探索方向，用 **Value Estimator** 将时间、剩余预算和 CPC 偏离写入价值监督，最终生成兼顾收益、探索和约束偏好的出价动作。

### 1.2 研究背景与核心问题

现代自动出价不仅要提高点击、转化或 GMV，还要同时面对预算、CPC、ROI 等不同目标。生成式出价模型可以把历史状态、动作和目标条件组成序列，直接生成下一动作，但工业部署仍有两个问题：

1. **离线—线上分布错位。** 离线日志来自过去的流量与竞争环境；线上用户行为、竞价强度、节假日流量和冷启动 campaign 都可能变化。
2. **探索与约束冲突。** 若模型只模仿日志，很难超过历史策略；若动作偏离日志太远，又可能破坏预算节奏或 KPI。

论文希望构建一个可扩展的生成式出价基础模型：既利用长序列历史，又能扩大动作覆盖，并让价值监督感知业务约束。

### 1.3 核心思路

GRAD 的主链路可以压缩为：

```text
RTG g_t + 当前状态 s_t + 上一步动作 a_{t-1}
                    |
                    v
          Causal Transformer
                    |
          隐状态 h_t + 基础动作 a_hat_t
              /                     \
             v                       v
   Value Estimator                ActionMoE
 时间/预算/CPC价值监督       多专家路由 + 扰动动作 + 残差
             \                       /
              \                     /
               ---- 联合多目标训练 ----
                          |
                          v
                    出价动作 a_t^*
```

- **Causal Transformer：**学习“给定目标回报和历史，下一步应该怎样调节出价”。
- **Value Estimator：**预测奖励，并用时间、预算、CPC 和噪声构造的目标值监督价值头。
- **ActionMoE：**先对历史动作做区间扰动，再通过共享专家和 Top-1 路由专家产生残差，形成更丰富的动作。
- **联合损失：**同时优化动作拟合、价值预测、专家均衡和动作多样性。

### 1.4 论文贡献

论文明确总结了三点贡献：

1. 提出可扩展的端到端生成式自动出价框架，可根据线上资源配置专家规模；
2. 提出 ActionMoE，利用随机上调或下调后的动作数据扩大探索范围；
3. 在 AuctionNet、AuctionNet-Sparse 和美团线上系统验证效果，线上报告 GMV 提升 2.18%、ROI 提升 10.68%。

### 1.5 先明确三个边界

#### 1.5.1 模型输出什么

论文不同部分对动作粒度的描述略有差异：预备知识将 $a_t$ 定义为各约束对应出价系数的调整向量，AuctionNet 数据中动作维度为 1，线上设置又将 $a_t$ 描述为当前时间步的 bid value。较稳妥的理解是：**GRAD 输出窗口级或请求级的连续出价控制动作，在线系统再结合广告特征和排序链路生成最终 bid；它不是为每个曝光独立运行一次完整 Transformer。**

#### 1.5.2 Value Estimator 是否等于标准因果模型

论文在引言中称其执行 counterfactual inference，但方法公式只明确给出 $\mathrm{MLP}_{\mathrm{value}}(\mathbf h_t)$ 和构造目标 $R_t$，没有展示潜在结果、treatment、倾向得分或双重稳健估计。因此本文档将它称为 **约束感知的价值估计头**；“反事实估计”是论文的表述，但公开方法细节不足以把它等同于标准因果推断模型。

#### 1.5.3 是否具有预算和 CPC 硬约束

正文明确区分：预算是线上系统执行的硬约束，CPC 等结果型 KPI 更适合作为软约束。附录证明 ActionMoE 在一组 Lipschitz、可行裕量和残差有界假设下可以保持可行，但这是一项**条件性理论保证**；若线上没有显式执行这些边界或投影，不能直接理解为模型天然保证 CPC。

## 2. Preliminary：自动出价问题与序列决策

### 2.1 Auto-Bidding Problem：自动出价优化问题

自动出价包含 $I$ 次离散竞价。若第 $i$ 次竞价获胜，$x_i=1$，否则 $x_i=0$；$v_i$ 表示该曝光的价值。目标是最大化总价值：

$$
\operatorname{maximize}\quad \sum_{i=1}^{I}x_i v_i. \qquad \text{(1)}
$$

其中 $v_i$ 通常由 CTR 或 CVR 等价值预估得到。

在预算 $B$ 和 CPC 上限 $C$ 下，完整问题为：

$$
\begin{aligned}
\operatorname{maximize}\quad &\sum_{i=1}^{I}x_i v_i \\
\text{s.t.}\quad &\sum_{i=1}^{I}x_i c_i\le B,\\
&\frac{\sum_{i=1}^{I}x_i c_i}{\sum_{i=1}^{I}x_i p_i}\le C.
\end{aligned}
\qquad \text{(2)}
$$

$c_i$ 是获胜成本，$p_i$ 是第 $i$ 次曝光的预测 CTR。预算可以实时累计和截断；真实 CPC 依赖后续点击反馈，因此论文将其视作更适合通过惩罚处理的软约束。

在单一 CPC 约束下，论文引用已有线性规划结果，将理论最优 bid 写为：

$$
b_i^*=\lambda_0^*v_i+C\lambda_1^*p_i. \qquad \text{(3)}
$$

论文随后写 $\lambda^*=\lambda_0^*+C\lambda_1^*$ 是统一控制变量。需要注意，公式（3）一般仍含 $v_i$ 和 $p_i$ 两项；除非二者有额外关系，否则不能直接把整个右式无条件化成单个 $\lambda^*v_i$。

### 2.2 Auto-bidding Decision Process：序列决策

将自动出价写成 MDP：

$$
(\mathcal S,\mathcal A,\mathcal T,\mathcal R,\gamma),
$$

其中状态、动作、转移、奖励和折扣因子分别为 $\mathcal S$、$\mathcal A$、$\mathcal T$、$\mathcal R$ 和 $\gamma$。策略目标为：

$$
\pi^*=\arg\max_{\pi}\mathbb E_{\pi}\left[\sum_{t=0}^{T}\gamma^t r_t\right]. \qquad \text{(4)}
$$

- **状态 $s_t$：**剩余时间、剩余预算、花费速度、KPI 达成比例等 campaign 状态；
- **动作 $a_t$：**对出价系数的连续调整；
- **奖励 $r_t$：**相邻决策周期之间获得的点击、转化或收入价值。

**直观理解：**单次出价不只影响当前是否赢标，还会改变剩余预算和后续可选流量，因此模型需要看一段历史，而不是只根据当前快照做静态回归。

## 3. Method：GRAD 模型架构

### 3.1 Figure 1：整体架构

<p align="center"><img src="./GRAD Figure 1 - Overall Architecture.png" alt="Figure 1：GRAD 整体架构" width="900" style="max-width: 100%; height: auto;"></p>

> Figure 1：GRAD 整体架构。左侧为 RTG、状态和历史动作的序列输入，中间为 Causal Transformer，右上为 Value Estimator，底部为 ActionMoE。

从图中可以看出，同一份 Transformer 隐状态 $\mathbf h_t$ 同时服务于动作头、价值头和专家路由。ActionMoE 并不是另起一个完整策略网络，而是在基础序列表示和候选动作之上增加稀疏专家与残差融合。

### 3.2 Causal Transformer：生成基础动作

#### 3.2.1 条件动作分布

模型根据截至当前时刻的状态、历史动作和当前 RTG 生成下一动作：

$$
\hat a_t\sim\pi\!\left(\cdot\mid\{s_{\le t},a_{<t},g_t\}\right)
=\mathrm{CT}\!\left(\cdot\mid\{s_{\le t},a_{<t},g_t\}\right). \qquad \text{(5)}
$$

RTG 定义为从当前时刻到轨迹结束的累计未来奖励：

$$
g_t=\sum_{\tau=t}^{T}r_\tau,\qquad r_\tau=x_\tau v_\tau. \qquad \text{(6)}
$$

这与 Decision Transformer 的核心逻辑一致：把“希望未来还获得多少回报”作为动作生成条件。

#### 3.2.2 输入 Embedding

每个时间步将 RTG、状态、上一动作和位置编码拼接：

$$
\mathbf h_t^{(0)}=\mathrm{LayerNorm}\!\left(
E_g(g_t)\oplus E_s(s_t)\oplus E_a(a_{t-1})\oplus\mathrm{PE}(t)
\right). \qquad \text{(7)}
$$

$E_g$、$E_s$ 和 $E_a$ 都是线性 embedding 层，$\oplus$ 表示向量拼接。

#### 3.2.3 Transformer Blocks 与动作头

隐藏状态依次通过 $N$ 个 Transformer Block：

$$
\mathbf h_t^{(n)}=\mathrm{Block}^{(n)}\!\left(\mathbf h_t^{(n-1)}\right),
\qquad n=1,\ldots,N. \qquad \text{(8)}
$$

策略头用 MLP 和 $\tanh$ 输出基础动作：

$$
\hat a_t=\tanh\!\left(\mathrm{MLP}_{\mathrm{policy}}(\mathbf h_t^{(N)})\right). \qquad \text{(9)}
$$

基础策略仍使用日志动作进行 MSE 监督：

$$
\mathcal L_{\mathrm{policy}}
=\frac{1}{T}\sum_{t=1}^{T}\left\|\hat a_t-a_t\right\|_2^2. \qquad \text{(10)}
$$

**直观理解：**Causal Transformer 先提供一个“符合历史数据、又受 RTG 控制”的基础动作；真正扩大动作空间的工作主要由后面的 ActionMoE 完成。

### 3.3 Value Estimator：约束感知的价值监督

#### 3.3.1 Reward from Prediction

价值头直接读取 Transformer 隐状态：

$$
\hat r_t=\mathrm{MLP}_{\mathrm{value}}(\mathbf h_t). \qquad \text{(11)}
$$

#### 3.3.2 Reward with Time-Adjustment

论文不是直接用原始 reward 监督 $\hat r_t$，而是构造动态目标：

$$
R_t=\Gamma(t)\cdot\Omega(t)\cdot\Pi(t)\cdot g_t+\Theta_{\mathrm{noise}}. \qquad \text{(12)}
$$

各项含义如下：

- 时间项：$\Gamma(t)=e^t$；
- 成本惩罚：

$$
\Omega(t)=\min\left(1,\left(\frac{C}{\mathrm{CPC}_t}\right)^\gamma\right),
\qquad \gamma\in[1,+\infty);
$$

- 预算效率项：$\Pi(t)$ 表示剩余预算比例，其变化被写成：

$$
\frac{\partial\Pi(t)}{\partial t}\propto-\mathrm{CPC}_t. \qquad \text{(13)}
$$

- 随机噪声：

$$
\Theta_{\mathrm{noise}}\sim\mathcal N(0,\sigma^2).
$$

当 $\mathrm{CPC}_t>C$ 时，$C/\mathrm{CPC}_t<1$，$\Omega(t)$ 会降低对应 RTG 的监督强度；剩余预算越少，$\Pi(t)$ 也越小。

这里有一个原文歧义：论文把 $\Gamma(t)=e^t$ 称为 temporal decay，但 $e^t$ 随 $t$ 增大而增大。若 $t$ 是正向时间索引，它实际是增长权重；论文没有进一步解释时间是否经过反向编码或归一化，因此应保留公式并标注该命名不一致。

#### 3.3.3 Value Loss

价值头使用 MSE 拟合构造目标：

$$
\mathcal L_{\mathrm{value}}
=\frac{1}{T}\sum_{t=0}^{T}\left\|\hat r_t-R_t\right\|_2^2. \qquad \text{(14)}
$$

论文文字称其为“随时间增大的权重”，但公式（14）没有显式时间权重。按公开公式，它是对各时间步等权平均的 MSE。

**直观理解：**价值头不是像 Twin Q 一样学习 Bellman 回报并在多个动作之间做 argmax，而是学习一个经过时间、预算和 CPC 修正的目标值，让共享序列表示更贴近业务目标。

### 3.4 ActionMoE：多专家动作探索

#### 3.4.1 Action Exploratory：构造候选动作

ActionMoE 先对上一动作逐元素缩放：

$$
\mathbf a_{t-1}^{m}
=\mathbf a_{t-1}\odot\mathbf f_{t-1}^{m},
\qquad
\mathbf f_{t-1}^{m}\sim\mathcal U[0.8,1.2). \qquad \text{(15)}
$$

每个专家索引 $m\in\{1,\ldots,M\}$ 都得到一个候选动作。动作只在历史基准的 80% 到 120% 范围内扰动，因此它属于受限局部探索，而不是在整个动作空间中任意采样。

#### 3.4.2 Shared Expert：稳定路径

共享专家始终激活：

$$
\mathbf h_t^{\mathrm{shared}}
=\mathrm{FFN}_{\mathrm{shared}}(\mathbf h_t). \qquad \text{(16)}
$$

它为不同样本提供公共表示路径，减少所有决策完全依赖稀疏专家带来的波动。

#### 3.4.3 Routed Experts：Top-1 专家路由

模型计算隐状态与每个可训练专家路由向量 $\mathbf e_m$ 的匹配分数，只选择一个专家：

$$
\begin{cases}
\mathrm{gate}_t^{(m)}=\mathbb I[m=m^*],\\[4pt]
m^*=\arg\max_m\mathrm{Softmax}(\mathbf h_t^\top\mathbf e_m).
\end{cases}
\qquad \text{(17)}
$$

路由分支输出为：

$$
\mathbf h_t^{\mathrm{router}}
=\sum_{m=1}^{M}\mathrm{gate}_t^{(m)}
\cdot\mathrm{FFN}_{\mathrm{routed}}^{(m)}(\mathbf h_t). \qquad \text{(18)}
$$

由于只有 $m^*$ 对应的 gate 为 1，实际每次只计算一个 Routed Expert。

#### 3.4.4 共享路径与路由路径融合

$$
\mathbf Y_t
=\mathrm{LayerNorm}\!\left(
\mathbf h_t^{\mathrm{shared}}+\mathbf h_t^{\mathrm{router}}
\right). \qquad \text{(19)}
$$

最终动作通过 MLP 残差和候选动作加权得到：

$$
\mathbf a_t^*
=\mathrm{MLP}(\mathbf Y_t)
+\sum_{m=1}^{M}\omega_m\mathbf a_{t-1}^{m}. \qquad \text{(20)}
$$

$\omega_m$ 是可训练权重。该式将“根据当前状态生成的残差”和“历史动作附近的候选集合”结合起来。

**直观理解：**共享专家负责不丢掉稳定基线，路由专家负责针对不同状态学习不同调整方向；最终动作仍锚定在历史动作附近，因此探索强于纯 DT，但比全空间搜索更保守。

#### 3.4.5 Algorithm 1：ActionMoE 前向流程

<p align="center"><img src="./GRAD Algorithm 1 - ActionMoE Forward.png" alt="Algorithm 1：ActionMoE 前向流程" width="620" style="max-width: 100%; height: auto;"></p>

> Algorithm 1：输入状态表示 $\mathbf h_t$ 和基础动作 $\hat a_t$，先计算 MoE 表示与残差，再构造候选动作，最后通过可训练权重与残差得到 refined action。

算法与公式（20）的记号存在轻微差异：算法在循环中逐个形成 $\omega_m\mathbf a_{t-1}^m+\mathbf U_t$，公式（20）则对所有候选动作求和。论文没有进一步说明最终输出是候选集合还是求和后的单一动作，部署部分只描述最终生成 optimized bids。因此实现时需要以代码或补充材料确认张量形状。

#### 3.4.6 Mixture Balancing Loss

$$
\mathcal L_{\mathrm{balance}}
=\lambda_{\mathrm{aux}}\mathrm{AUX}(\mathbf p,\mathbf u)
+(1-\lambda_{\mathrm{aux}})
\left\|\mathbf h_t-\mathbf h_t^{\mathrm{shared}}\right\|_2^2. \qquad \text{(21)}
$$

$\mathbf p$ 是路由概率，$\mathbf u$ 是一个 mini-batch 中各专家的实际利用频率。第一项防止所有样本挤到少数专家，第二项将共享专家输出锚定在原始隐状态附近。

#### 3.4.7 Action Diversity Loss

$$
\mathcal L_{\mathrm{div}}
=\frac{1}{M}\sum_{m=1}^{M}
\cos\!\left(\mathbf a_t^*,\hat{\mathbf a}_t\right). \qquad \text{(22)}
$$

余弦相似度定义为：

$$
\cos(\mathbf u,\mathbf v)
=\frac{\langle\mathbf u,\mathbf v\rangle}
{\|\mathbf u\|_2\|\mathbf v\|_2}.
$$

最小化相似度会推动探索动作偏离基础动作。原公式在求和中没有给 $\mathbf a_t^*$ 添加专家索引 $m$，但文字描述的是多个探索动作；这可能是记号省略或排版问题，本文档保留原式，不擅自改写。

### 3.5 Multi-Objective Loss：联合训练目标

$$
\mathcal L
=\mathcal L_{\mathrm{policy}}
+\mathcal L_{\mathrm{value}}
+\lambda_b\mathcal L_{\mathrm{balance}}
+\lambda_d\mathcal L_{\mathrm{div}}. \qquad \text{(23)}
$$

四项分别控制：

- 对日志动作的拟合；
- 对时间、预算和 CPC 感知价值目标的拟合；
- 专家使用均衡；
- 探索动作多样性。

论文称 GRAD 为端到端联合训练框架，没有描述先单独训练 Transformer、再训练 MoE 的分阶段过程。

### 3.6 完整数据流

1. 从历史轨迹计算 $g_t$，与 $s_t$、$a_{t-1}$ 一起进入 Causal Transformer；
2. Transformer 输出共享隐状态 $\mathbf h_t$ 和基础动作 $\hat a_t$；
3. Value Estimator 用 $\mathbf h_t$ 预测 $\hat r_t$，并拟合构造目标 $R_t$；
4. ActionMoE 对历史动作生成 80% 到 120% 的候选，并由共享专家和 Top-1 专家生成残差；
5. 候选动作与残差融合为 $\mathbf a_t^*$；
6. 四类损失共同更新共享 Transformer、价值头、专家和动作融合模块；
7. 在线推理时只激活一个 Routed Expert，降低计算量。

## 4. Experiment：离线实验

### 4.1 Setup：数据集与指标

论文使用 AuctionNet 及其稀疏版本 AuctionNet-Sparse。主指标沿用 GAVE 的约束惩罚 score。对第 $j$ 个约束：

$$
\mathrm{penalty}_j
=\min\left\{
\left(
\frac{C_j}{\sum_i x_i c_{ij}/\sum_i x_i v_{ij}}
\right)^\beta,
1
\right\}. \qquad \text{(24)}
$$

总分为：

$$
\mathrm{score}
=\left(\sum_i x_i v_i\right)
\times\min_{j\in\{1,\ldots,J\}}\mathrm{penalty}_j. \qquad \text{(25)}
$$

$C_j$ 是第 $j$ 个 KPI 上限，$c_{ij}$ 和 $v_{ij}$ 是对应成本和价值，论文设置 $\beta=2$。一旦某个约束超限，最紧约束的 penalty 会压低最终 score。

AuctionNet 以 CPA 为约束，线上美团场景主要展示 CPC。两者共享相同的“价值乘约束惩罚”思路，但不是同一指标口径。

### 4.2 Comparative Evaluation：基线与主结果

比较方法包括：

- **DiffBid：**条件扩散生成完整出价轨迹；
- **USCB：**在线强化学习统一调节出价参数；
- **CQL、IQL、BCQ：**三类典型离线强化学习方法；
- **DT、CDT：**条件序列生成及其约束版本；
- **GAS：**DT 加 MCTS 后训练搜索；
- **GAVE：**DT 上的受限动作扰动和价值引导探索。

所有方法在 AuctionNet 与 Sparse 版本上使用 50%、75%、100%、125%、150% 五档预算比较。

<p align="center"><img src="./GRAD Table 1 - Performance Comparison.png" alt="Table 1：主实验结果" width="900" style="max-width: 100%; height: auto;"></p>

> Table 1：主实验结果。粗体是最高值，下划线是次优值。

结果可以归纳为：

- GRAD 在 10 组设置中取得 7 组第一；
- GAVE 在 AuctionNet 的 75% 和 100% 预算下高于 GRAD；
- 在 AuctionNet-Sparse 的所有预算档位，GRAD 均为第一，但相对 GAVE 的领先幅度较小；
- DiffBid 在该大规模任务上明显落后，论文认为整轨迹生成和 inverse dynamics 增加了学习难度。

因此实验支持“GRAD 整体稳定且在稀疏场景有优势”，但不能表述为每个设置都显著超过 GAVE。

### 4.3 Parameter Analysis：专家数量

<p align="center"><img src="./GRAD Figure 2 - Number of Experts.png" alt="Figure 2：不同专家数量的表现" width="900" style="max-width: 100%; height: auto;"></p>

> Figure 2：在 AuctionNet、100% 预算下比较 4、6、8 个专家。柱形表示 Score 和 Total Reward，折线表示 Exceed Rate 与 CPA Ratio。

从图中可以看出，专家数从 4 增至 6 时各项表现改善，增加到 8 后又回落。论文将其归因于模型复杂度、专家利用效率、训练不稳定和梯度稀释。最终默认使用 6 个专家。

### 4.4 Ablation Study：组件消融

<p align="center"><img src="./GRAD Table 2 - Ablation Study.png" alt="Table 2：GRAD 组件消融" width="760" style="max-width: 100%; height: auto;"></p>

> Table 2：$\mathbf A$ 表示 ActionMoE，$\mathbf V$ 表示 Value Estimator。

主要结论：

- 移除 ActionMoE 后，所有设置都下降，说明扩大动作覆盖确实有贡献；
- 移除 Value Estimator 后同样下降，在 Sparse 数据和部分高预算设置中影响明显；
- 同时移除二者后退化为基础序列策略，降幅最大；
- 两个模块作用互补：ActionMoE 负责候选动作多样性，Value Estimator 负责业务条件监督。

## 5. Online A/B Test：美团线上实验

### 5.1 Setup：轨迹与线上奖励

线上日志来自 2025 年 1 月至 3 月，包含 5,000 条基础轨迹和 30,000 条扩展轨迹。轨迹以 PID 控制逻辑聚合，每 15 分钟一个决策窗口，历史 bid 调整范围约为基准价格的 80% 到 120%。

- **状态：**预算、成本、收费、价格、分时预算、分时花费速度、预测转化率、真实 CPC 等；
- **动作：**时间步 $t$ 的 bid value $a_t$；
- **奖励：**同时考虑 CTR 和 CPC 超限惩罚：

$$
\mathrm{Reward}
=\log(1+1000\times\mathrm{CTR})
-\lambda\cdot\min\left(
P_{\max},
\left(\frac{\mathrm{CPC}-\vartheta}{\vartheta}\right)^3
\right). \qquad \text{(26)}
$$

$\lambda\in\{0,1\}$ 控制违规时是否激活惩罚，$\vartheta$ 是 CPC 阈值，$P_{\max}$ 限制最大惩罚。

这里的 $\lambda$ 是惩罚激活指示量，不是预备知识中控制 bid 的拉格朗日乘子或 multiplier，二者不要混淆。

### 5.2 Deployment：训练与推理链路

<p align="center"><img src="./GRAD Figure 3 - Online Deployment.png" alt="Figure 3：美团线上部署架构" width="760" style="max-width: 100%; height: auto;"></p>

> Figure 3：训练侧使用历史行为、预算和 KPI；推理侧使用 Causal Transformer、共享专家、Top-1 路由专家和 Value Estimator，生成 bid 后进入 Ranking。

线上部署在 Multiple Constraint Bidding 场景中：广告主设置预算，可选 CPC 或 ROI 约束，系统在约束下最大化转化。

训练阶段将历史用户行为聚合成 group；推理阶段约 $10^3$ 个 Raw Bid 候选经过初筛缩减为约 $10^2$ 个广告，再结合压缩广告特征和用户上下文生成 optimized bids，最后交给 Ranking 选广告。

论文称推理时冻结共享专家并只激活一个 Top-1 Routed Expert。更准确地说，线上推理本身不更新参数；这里强调的是稀疏激活只执行一个路由专家，从而控制延迟。

### 5.3 Online Results：结果与 CPC_CR

线上实验持续 7 天。CPC 合规率定义为：

$$
\mathrm{CPC\_CR}
=\frac{1}{T}\sum_{t=1}^{T}
\mathbb I\!\left(
\overline{\mathrm{CPC}}_t\le\gamma C_{\mathrm{target}}
\right)\times100\%. \qquad \text{(27)}
$$

$\gamma=1.2$，即平均 CPC 不超过目标的 120% 就算当天合规。

<p align="center"><img src="./GRAD Table 3 - Online AB Test.png" alt="Table 3：线上 A/B 实验" width="760" style="max-width: 100%; height: auto;"></p>

> Table 3：相对美团平台最优 RL 基线，CTR +3.93%、CPC_CR +5.64%、ROI +10.68%、GMV +2.18%。

线上结果说明离线收益并没有在部署链路中完全消失，同时 CPC 合规率也提高。不过论文只报告相对提升，没有公开流量比例、置信区间、显著性检验细节和绝对指标，因此无法从表格独立判断统计方差与业务基数。

## 6. Related Work：相关工作

### 6.1 Offline Reinforcement Learning

离线强化学习只使用预先收集的数据，适合无法进行高风险线上探索的场景。论文梳理了三类代表方法：

- CQL 通过保守价值惩罚减少分布外动作高估；
- BCQ 将策略限制在数据支持的动作附近；
- IQL 避免显式评价分布外动作，提高离线训练稳定性；
- DT 用序列建模复用不同回报水平的轨迹；
- IDQL 将扩散策略与隐式 Q-learning 结合。

### 6.2 Auto-bidding

自动出价从规则与模拟环境强化学习，发展到统一多约束、多智能体竞争和协作式强化学习。论文认为这些 RL 方法仍面临样本效率、训练稳定性和动态市场适应问题。

### 6.3 Generative Models

生成式决策分为两条主要路线：

- GAVE、GAS 等 Transformer 自回归动作生成；
- DiffBid 等条件扩散轨迹生成。

GRAD 选择第一条路线，并将多专家动作探索与价值监督嵌入 Causal Transformer。

## 7. Conclusion：结论与证据边界

论文的核心结论是：Causal Transformer、ActionMoE 和 Value Estimator 的组合能够在大规模出价数据上提高适应性，并在美团线上系统获得正向收益。

从公开证据看，最扎实的结论是：

- ActionMoE 和 Value Estimator 都有独立消融增益；
- 6 个专家优于 4 个和 8 个；
- GRAD 在多数 AuctionNet 设置领先，在 Sparse 版本尤其稳定；
- 线上 CTR、CPC_CR、ROI 和 GMV 同时正向。

需要保留的边界是：

- Value Estimator 的“因果/反事实”机制没有完整因果识别细节；
- CPC 主要通过 reward 和 value target 软引导，而非像 GRM 一样显式求根；
- 附录的硬约束结论依赖较强假设；
- 动作张量、候选集合与最终单动作之间的精确实现存在公式和算法记号差异；
- 官方代码尚未公开，部分实现细节无法交叉验证。

## 8. Appendix A–B：数据集与超参数

### 8.1 Table 4：数据集统计

<p align="center"><img src="./GRAD Table 4 - Dataset Statistics.png" alt="Table 4：AuctionNet 数据统计" width="760" style="max-width: 100%; height: auto;"></p>

> Table 4：两个数据集均含 479,376 条轨迹、每条轨迹 48 个时间步、16 维状态和 1 维动作。Sparse 版本的转化更稀疏，CPA 范围更高。

AuctionNet-Sparse 的单轨迹总转化范围为 0 到 57，而完整版本为 0 到 1512，因此 Sparse 更能检验模型在低反馈密度下的稳定性。

### 8.2 Table 5：超参数

<p align="center"><img src="./GRAD Table 5 - Hyperparameters.png" alt="Table 5：GRAD 超参数" width="620" style="max-width: 100%; height: auto;"></p>

> Table 5：模型使用 8 层注意力、16 个头、512 隐藏维度、6 个专家，训练 400,000 步。

几个关键设置：

- 序列长度 20，小于完整 episode 长度 48，说明模型训练时使用局部历史窗口；
- 学习率 $10^{-5}$，优化器 AdamW；
- $\gamma=0.99$，$\tau=0.01$，expectile 为 0.7；
- $\lambda_{\mathrm{aux}}=0.2$；
- 论文没有解释 expectile 在正文哪一项损失中使用，公开公式也没有出现对应 expectile loss，这是实现细节缺口。

## 9. Appendix C：硬约束动作空间理论

### 9.1 CMDP 与可行动作集合

令第 $k$ 个硬约束为 $C_k(s,a)\le0$，状态 $s$ 下的可行动作集合为：

$$
\mathcal F(s)=\{a\in\mathcal A:C_k(s,a)\le0,\ \forall k\}.
$$

论文指出，逐窗口预算 pacing 和 delivery limit 可以属于硬约束；CPC/CPA 等结果型指标通常通过惩罚进入目标。

理论首先作出两个假设。

**假设 1：约束对动作 Lipschitz。**

$$
|C_k(s,a)-C_k(s,a')|
\le L_k\|a-a'\|,
\qquad \forall a,a'\in\mathcal A,\ \forall s\in\mathcal S,
$$

并令 $L=\max_k L_k$。

**假设 2：历史动作存在可行裕量。**

$$
\max_k C_k(s_t,a_{t-1})\le-\eta,
\qquad \eta>0.
$$

也就是说，作为探索中心的历史动作不仅可行，还必须离约束边界保留至少 $\eta$ 的空间。

### 9.2 扰动与残差如何保持可行

ActionMoE 先构造 $a'=a_{t-1}\odot f$，其中 $f\in[1-\varepsilon,1+\varepsilon]^d$。

**Lemma C.1：缩放扰动的距离上界。**

$$
\|a'-a\|\le\varepsilon\|a\|.
$$

证明来自逐元素界：

$$
\|a'-a\|^2
=\sum_{i=1}^{d}(f_i-1)^2a_i^2
\le\varepsilon^2\sum_{i=1}^{d}a_i^2
=\varepsilon^2\|a\|^2.
$$

**Proposition C.2：Trust-Region 缩放保持可行。**

若

$$
\varepsilon\le\frac{\eta}{L\|a_{t-1}\|},
$$

则：

$$
\begin{aligned}
C_k(s_t,a')
&\le C_k(s_t,a_{t-1})+L_k\|a'-a_{t-1}\|\\
&\le-\eta+L\varepsilon\|a_{t-1}\|\\
&\le0.
\end{aligned}
$$

**假设 3：残差有界。**

令 $U_t=\mathrm{MLP}(Y_t)$，要求：

$$
\|U_t\|\le\delta,
\qquad
\delta\le\frac{\eta}{L}-\varepsilon\|a_{t-1}\|.
$$

**Proposition C.3：加入残差后仍可行。**

$$
C_k(s_t,a^*)
\le C_k(s_t,a')+L_k\|U_t\|
\le0+L\delta
\le0.
$$

如果不能保证残差上界，论文提出将候选动作投影回可行域：

$$
\Pi_{\mathcal F(s_t)}(a)
:=\arg\min_{b\in\mathcal F(s_t)}\|b-a\|,
$$

并令：

$$
a^\dagger=\Pi_{\mathcal F(s_t)}(\tilde a).
$$

若约束关于动作是凸的，投影还是非扩张映射：

$$
\|\Pi_{\mathcal F}(x)-\Pi_{\mathcal F}(y)\|
\le\|x-y\|.
$$

**直观理解：**历史动作有一圈安全余量，只要扰动和网络残差的总幅度不超过这圈余量，新动作仍在可行域内；如果幅度无法控制，就必须显式投影。

需要注意，正文固定使用 $[0.8,1.2)$ 扰动，但没有证明该 20% 幅度在所有线上状态都满足上述 $\varepsilon$ 上界，也没有在部署图中展示投影模块。因此理论给出的是“满足条件时可行”，不是无条件工程保证。

### 9.3 Penalized Objective 的单调改进

论文定义惩罚目标：

$$
J_\lambda(\pi)
:=\mathbb E_\pi\left[
\sum_{t=0}^{\infty}\gamma^t
\big(r(s_t,a_t)-\lambda\phi(C(s_t,a_t))\big)
\right],
$$

其中：

$$
C(s,a):=\max_k C_k(s,a),
$$

$\phi$ 是非负、凸、单调不减的惩罚函数，并在 $x\le0$ 时满足 $\phi(x)=0$。

惩罚优势函数为：

$$
A_\lambda^\pi(s,a)
=Q_\lambda^\pi(s,a)-V_\lambda^\pi(s).
$$

**Lemma C.5：惩罚 CMDP 的性能差分。**

$$
J_\lambda(\pi')-J_\lambda(\pi)
=\frac{1}{1-\gamma}
\mathbb E_{s\sim d_{\pi'}}\left[
\mathbb E_{a\sim\pi'(\cdot|s)}A_\lambda^\pi(s,a)
\right].
$$

Trust-Region 更新要求：

$$
\mathrm{KL}(\pi'(\cdot|s)\|\pi(\cdot|s))
\le\epsilon_{\mathrm{KL}},
$$

以及：

$$
\mathbb E_{a\sim\pi'(\cdot|s)}A_\lambda^\pi(s,a)
\ge
\alpha\,
\mathbb E_{a\sim\pi(\cdot|s)}A_\lambda^\pi(s,a),
\qquad \alpha\in(0,1].
$$

在优势有界 $|A_\lambda^\pi(s,a)|\le B$、状态占用密度比不低于 $\rho_{\min}$ 时，论文给出：

$$
\begin{aligned}
J_\lambda(\pi')-J_\lambda(\pi)
\ge{}&
\frac{\rho_{\min}}{1-\gamma}
\left(
\alpha\,
\mathbb E_{s\sim d_\pi}
\mathbb E_{a\sim\pi(\cdot|s)}
A_\lambda^\pi(s,a)
\right)\\
&-\mathcal O(\epsilon_{\mathrm{KL}}B).
\end{aligned}
$$

当 KL 步长足够小且基线的期望惩罚优势为正时，可以得到正向改进下界。

### 9.4 动作多样性与覆盖

论文将多样性条件写为：

$$
\frac{1}{M}\sum_{m=1}^{M}
\cos(\hat a_t,a_{t,m}^*)\le\rho,
\qquad \rho\in[0,1).
$$

等价的角度间隔为：

$$
\theta_m
:=\arccos\!\left(\cos(\hat a_t,a_{t,m}^*)\right)
\ge\arccos(\rho).
$$

归一化方向定义为：

$$
v_0=\frac{\hat a_t}{\|\hat a_t\|},
\qquad
v_m=\frac{a_{t,m}^*}{\|a_{t,m}^*\|},
$$

并构造 $V=[v_1,\ldots,v_M]$ 与 Gram 矩阵 $G=V^\top V$。论文给出：

$$
x^\top Gx
=\left\|\sum_{m=1}^{M}x_m v_m\right\|^2
\ge
(1-\rho^2)\|x\|^2
-\sum_{m\ne n}|x_mx_n|\Delta_{mn},
$$

其中：

$$
\Delta_{mn}
:=|\langle v_m-\rho v_0,\,v_n-\rho v_0\rangle|.
$$

若不同探索方向还满足 $|\langle v_m,v_n\rangle|\le\kappa<1$，则：

$$
\lambda_{\min}(G)\ge1-\kappa(M-1).
$$

当 $\kappa<1/(M-1)$ 时，探索方向集合具有较好的条件数；减小 $\rho$ 会扩大球面方向覆盖范围。

**直观理解：**多样性损失希望不同专家不要都沿着基础动作的同一方向微调；只有候选方向真正分开，多专家才比复制多个相同 FFN 有意义。

### 9.5 Top-1 路由与梯度稳定性

稀疏 MoE 输出可简写为：

$$
Y_t=\mathrm{LN}\!\left(
F_{\mathrm{shared}}(h_t)+F_{m^*}(h_t)
\right).
$$

假设隐藏状态与其梯度有界：

$$
\|h_t\|\le H,
\qquad
\|\nabla_\theta h_t\|\le G_h.
$$

若共享专家、路由专家和 LayerNorm 的 Lipschitz 常数分别为 $L_s$、$L_r$ 和 $L_{\mathrm{LN}}$，则：

$$
L_Y\le L_{\mathrm{LN}}(L_s+L_r).
$$

损失梯度上界为：

$$
\|\nabla_\theta\mathcal L\|
\le C\left(
\|\nabla_{Y_t}\mathcal L\|\cdot L_Y\cdot G_h
\right).
$$

Top-1 每次只激活一个路由分支，因此上界依赖 $L_s+L_r$，而不是所有专家 Lipschitz 常数之和。论文据此说明 Top-1 可以降低梯度方差并改善稳定性。

## 10. Appendix D：训练动态深入分析

### 10.1 Figure 4：惩罚目标与梯度稳定性

<p align="center"><img src="./GRAD Figure 4 - Penalized Objective Analysis.png" alt="Figure 4：惩罚目标训练分析" width="900" style="max-width: 100%; height: auto;"></p>

> Figure 4：左图比较 Top-1 routing 与多专家同时激活时的梯度范数；右图展示惩罚目标 $J_\lambda$ 随训练步数上升并逐渐稳定。

从图中可以看出，Top-1 routing 的梯度范数分布更集中，多专家同时激活的离群值更多；惩罚目标整体随训练推进提高。论文据此支持稀疏路由的稳定性和 penalized objective 的收敛趋势。

图中左子图实际比较的是 Top-1 与 Multi-expert，而正文描述为“有无 penalty 的梯度轨迹”；图文之间存在口径不完全一致，不能把左图直接当作 penalty 消融。

### 10.2 Figure 5：随机轨迹的 CPC_CR

<p align="center"><img src="./GRAD Figure 5 - CPC CR Trajectory.png" alt="Figure 5：随机轨迹 CPC_CR 对比" width="760" style="max-width: 100%; height: auto;"></p>

> Figure 5：在一段随机轨迹上比较 CEM、IQL 与 GRAD 的 CPC_CR。

GRAD 曲线整体最高且波动较小，IQL 次之，CEM 最低。该图是单条随机轨迹的案例分析，可以说明行为趋势，但不能替代跨轨迹总体统计。

## 11. 与现有生成式出价模型的关系

这一节是基于论文机制的综合归纳，不是论文新增实验。

| 模型 | 如何生成 | 如何探索或优化 | 约束方式 |
|---|---|---|---|
| DT | 根据 RTG 与历史直接生成下一动作 | 主要复用日志行为 | RTG/状态软条件 |
| GAVE | DT 生成动作，在日志动作附近做缩放探索 | RTG 与 expectile value 引导局部探索 | score-based RTG 软引导 |
| Guide | DT 动作与 IDM 保守动作形成两个候选 | Twin Q 在候选间选择，并用 Q 正则推动 DT | Q 选择与系统约束，无形式化 CPC 硬保证 |
| GRAD | Causal Transformer 生成基础动作，ActionMoE 融合多专家候选 | 路由专家、动作多样性损失和价值目标联合训练 | 预算由系统硬控，CPC 主要进入 reward/value；附录给条件性可行保证 |
| GRM | 预测 multiplier 对未来成本与价值的响应 | 求预算根和 CPA 根，选择更紧上界 | 显式响应建模与求根 |

GRAD 与 GAVE 都是在历史动作附近探索，但 GRAD 的区别是将探索方向参数化为共享专家和稀疏路由专家，并加入专家均衡与多样性损失；它不像 Guide 那样在两个动作间使用 Twin Q 做最终选择，也不像 GRM 那样显式预测响应曲线并求约束根。

## 12. 最终总结

**前提：**有大规模连续出价轨迹，能够构造 RTG、状态、历史动作和业务价值目标；历史动作附近存在可改进空间，且线上可以执行预算截断或可行动作保护。

**解决的问题：**纯 DT 容易停留在日志行为附近，而无约束扩大动作空间又容易引发线上分布外风险；同时普通 reward 难以同时表达时间、预算和 CPC 偏好。

**增加的能力：**用 ActionMoE 学习多种局部动作调整方向，用共享专家保持基线稳定，用 Top-1 路由控制计算量，再通过约束感知 Value Estimator 和多目标损失联合优化。

**最大的失败风险：**若扰动动作缺乏真实反馈覆盖，Value Estimator 对新动作的价值判断不可靠，或线上状态不满足附录的可行裕量与有界残差假设，ActionMoE 可能生成看似多样但不可执行的动作，导致 CPC、预算节奏和收益同时恶化。

**最小实验验证：**固定同一 Causal Transformer、数据和 reward，依次比较基础 CT、CT + ActionMoE、CT + Value Estimator、完整 GRAD；在 AuctionNet-Sparse 或自建竞争突变仿真中同时观察总价值、约束违约率、动作偏离日志幅度、专家利用率和梯度稳定性，确认提升来自有效探索而不是单纯扩大动作波动。
