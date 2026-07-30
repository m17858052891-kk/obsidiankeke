# Bi-DFCL：怎样用 RCT 与 OBS 共同优化营销决策

论文：[Bi-Level Decision-Focused Causal Learning for Large-Scale Marketing Optimization: Bridging Observational and Experimental Data](https://arxiv.org/abs/2510.19517)  
会议：NeurIPS 2025  
原图：论文 Figure 1（MTBAP 原始/对偶问题）、Figure 2（Bi-DFCL 总体框架）

## 1. 一句话先说清楚

**Bi-DFCL 在 DFCL 的“预测要为预算决策服务”之上，再解决一个更现实的问题：海量 OBS 数据够多但有偏，RCT 数据无偏但稀少。**它让 Target Network 从 OBS 学到低方差的基础规律，让 RCT 上的无偏决策质量通过一个可学习的 Bridge Network，反过来校正“应该怎样利用 OBS 学习”，并用双层优化与隐式求导完成端到端训练。

关键不是把 RCT 与 OBS 简单拼接，也不是给两者手调一个 loss 权重；而是让 RCT 的决策效果决定 Bridge 应怎样生成/修正 OBS 上的监督信号。

## 2. 从 DFCL 到 Bi-DFCL：多出来的难题是什么？

| 数据 | 优点 | 风险 |
|---|---|---|
| RCT（随机试验） | treatment 随机分配，满足强可忽略性，可无偏评估策略 | 昂贵、样本少，直接训练方差大 |
| OBS（观察日志） | 覆盖大、成本低、样本多 | 发券/折扣由旧策略选择，存在选择偏差、位置偏差、混杂 |

假设老策略更愿意给“本来就会下单”的用户发高券。OBS 会显示“高券用户订单更多”，但不能说明高券造成了更多订单。若直接把 OBS 当真，模型与下游 OR 可能把预算继续流向高活跃用户，偏差形成正反馈。

DFCL 的 surrogate 在 RCT 上是无偏的，但“只依赖 RCT”浪费了 OBS 的规模优势。Bi-DFCL 的任务就是在 **无偏但高方差** 与 **低方差但有偏** 之间找到随任务而变的平衡。

## 3. 读 Figure 1 / Figure 2 前先认识对象与符号

| 符号/模块 | 含义 | 不能误解成 |
|---|---|---|
| \(x_i,t_i,r_{it_i},c_{it_i}\) | 特征、已分配动作及其事实收益/成本 | 不是一个样本有所有动作的真实结果 |
| \(r_{ij},c_{ij}\) | 给 i 用 j 时的潜在收益和成本 | 对多数 j 是缺失的反事实 |
| \(z_{ij}\) | 预算分配策略是否选动作 j | 不是模型直接输出的概率标签 |
| \(f_\theta\) / Target Network | 最终要上线的预测模型 | 不是 Bridge，也不是 Teacher |
| \(g_\phi\) / Bridge Network | 学习如何把 OBS 信息转成更有用的训练信号 | 上线时不承担最终预测 |
| Teacher Network | 先在 RCT 上用标准 uplift/MSE 训练的教师 | 用于提供 OBS 的反事实伪标签锚点 |
| \(\mathcal D_{RCT}\)、\(\mathcal D_{OBS}\) | 无偏但少的试验数据、海量但有偏的观察数据 | 不能直接视为同分布 |
| PPL / PIFD | 两种原始（primal）决策 surrogate | PPL 是平滑可微路径；PIFD 是黑箱有限差分路径 |

## 4. Figure 2 的总体架构：先用一句话连起来

```mermaid
flowchart TB
    R[RCT: 少但随机、无偏] --> T[Teacher: RCT 上预训练]
    O[OBS: 多但有偏] --> B[Bridge Network g_φ]
    T --> B
    B --> P[为 OBS 构造/修正反事实伪标签]
    P --> L[下层：Target f_θ 在 OBS 上最小化预测损失]
    L --> F[得到临时最优 Target θ*(φ)]
    F --> U[上层：RCT 上最小化无偏决策损失]
    R --> U
    U --> B
    F --> S[部署：Target 预测 r̂,ĉ → 预算分配]
```

整张图可以用一句因果链解释：**Bridge 改变 OBS 上 Target 学到什么；Target 的改变会导致一个营销决策；RCT 负责检验这个决策是否真的好；这个检验的梯度再回去更新 Bridge。**

## 5. 按 Figure 2 的模块走完一次完整训练

### 5.1 第 0 步：Teacher 只做“可信锚点”，不直接当最终模型

论文先在 \(\mathcal D_{RCT}\) 上用任意 uplift 模型和标准 MSE 训练 Teacher。RCT 虽小，但 treatment 随机，Teacher 的作用是为 OBS 中未观察动作提供相对更可信的 counterfactual pseudo-label 基础。

这并不代表 Teacher 的每个反事实都是真值；它只是把“完全没见过的反事实”变成一个带 RCT 约束的起点。

### 5.2 第 1 步：Bridge 为 OBS 产生可学习的反事实监督

OBS 样本只看见它在旧策略下的 \((t_i,r_{it_i},c_{it_i})\)。论文中 Bridge \(g_\phi\) 输出一个 **bridge vector / gate**；它把当前 Target 的输出与固定 Teacher 的输出自适应组合，生成 OBS 中未观测 treatment 的 counterfactual pseudo-label，再用这些伪标签参数化 OBS 上的 prediction loss。也就是说，Bridge 并不是又预测一套独立的收益面，而是在“相信当前 Target 到什么程度、向 RCT Teacher 靠多少”之间学习软门控。

直觉例子：旧策略常给高活跃用户 8 元券。Teacher 根据 RCT 认为某类用户的 8 元券未必有很高增量；Bridge 学到应把 OBS 中“8 元券后订单高”的表象拉回更合理的反事实面，而不是让 Target 照单全收。

### 5.3 第 2 步（下层）：用大量 OBS 训练 Target，得到 \(\theta^*(\phi)\)

给定当前 Bridge，Target Network \(f_\theta\) 在 OBS 上最小化 prediction loss，学习输出每个动作下的 \(\hat r_{ij},\hat c_{ij}\)。这一步利用 OBS 的规模，降低泛化误差和估计方差。

形式上可写成：

\[
\theta^*(\phi)=\arg\min_\theta\; \mathcal L_{PL}^{OBS}(\theta,\phi).
\]

这里 \(\phi\) 进入伪标签/训练信号，因此它会改变下层最优 Target 是什么。这个依赖关系就是“双层”而不是“双 loss 加权”的根源。

### 5.4 第 3 步（上层）：不是看 MSE，而是用 RCT 检查最终预算决策

把下层得到的 \(\theta^*(\phi)\) 用在 RCT 上。Target 预测每个人每档券/折扣的收益和成本，预算优化器产生动作 \(z\)，上层用 RCT 构造无偏的决策质量估计并最小化：

\[
\min_\phi\;\mathcal L_{DL}^{RCT}(\theta^*(\phi)).
\]

因此 Bridge 被奖励的标准不是“让 OBS 拟合得更像旧策略”，而是“经它训练出的 Target，在独立随机试验上做出的预算分配是否更好”。论文强调这个结构也避免手工指定 \(\alpha L_{prediction}+\beta L_{decision}\) 的固定权重。

## 6. PPL 和 PIFD：上层的决策质量如何有梯度？

Figure 1 的原始问题是带预算的 0–1 多动作分配。离散解不可微，且反事实真实收益不可见；Bi-DFCL 先在 RCT 上给出无偏的决策质量估计，再给出两种训练路线。

### 6.1 Bi-DFCL-PPL：原始策略学习损失

PPL（Primal Policy Learning Loss）把硬的 one-hot 选择平滑成动作概率，例如把“选净收益最高的券”放松为 softmax 分配。它在**原始预算 \(B\)** 下优化，不像 DFCL 的 dual loss 那样汇总不同 \(\lambda\)/不同预算。因此它问的是更直接的问题：在当前真实预算下，分配概率改变会怎样影响 RCT 上估计的真实收益？

最大熵正则是这种连续 relaxation 的一个解释：熵让策略暂时不是完全硬选，换来可导的优化信号；温度越低越接近实际硬决策。

### 6.2 Bi-DFCL-PIFD：原始改进有限差分

PIFD（Primal Improved Finite Difference）则尽量保留原来离散 OR 的景观。它把“预测 → 求解器 → RCT 评估”的某些不可导环节当黑箱，通过小扰动估计决策损失对输出的变化，再将估到的梯度冻结为不可训练节点，接回自动微分图更新网络。

和普通逐坐标有限差分相比，论文设计了面向预算/动作的估计器以加速。应把它理解为**更贴近真实离散决策但相对更重**的一条路线，而不是一个新的因果标签模型。

## 7. 最难的一步：为什么需要隐式求导？

上层要更新 \(\phi\)，但上层损失依赖 \(\theta^*(\phi)\)：

```text
φ 改变
→ OBS 伪标签/下层 loss 改变
→ 下层训练出来的 θ* 改变
→ RCT 上的预算决策改变
→ 上层决策损失改变
```

如果把下层的每一步 SGD 都展开反传，既占显存又依赖具体训练路径，长训练还可能梯度消失。Bi-DFCL 用最优点的一阶条件 \(\nabla_\theta\mathcal L_{PL}^{OBS}(\theta^*,\phi)=0\) 做隐式微分，得到 \(d\theta^*/d\phi\) 的关系。

其中会出现 Hessian 逆，但论文不用显式构造/求逆，而用 conjugate gradient（CG）通过 Hessian-vector product 求解线性系统。这使算法只关注“下层已经到最优点时它必须满足什么条件”，而不是存储“它是如何走到那里”的整条路径。

## 8. Algorithm 1 中每一轮在干什么

1. 用 RCT 预训练 Teacher；初始化 Target、Bridge。
2. 对 OBS mini-batch，周期性（每 \(\tau\) 个 batch）处理上层：复制 Target 得到临时变量，利用当前 Bridge 生成伪标签，在下层 loss 上做若干次 **assumed update** 得到临时 \(\theta^*\)。
3. 对这个临时最优点用 CG 求 \(d\theta^*/d\phi\)，据此在 RCT 计算 PPL 或 PIFD 的上层梯度，更新 Bridge。
4. 使用刚更新的 Bridge 再生成 OBS 伪标签，真正更新一次 Target。
5. 训练结束后只输出 Target；上线由它预测 \(\hat r,\hat c\)，再交给预算分配器。

论文默认 assumed update 的步数为 1；这是工程近似，用来把双层训练控制在可承受的规模内，而不等于完整重训 Target。

## 9. 一个贯穿例子：发券应该给谁？

某平台有两类用户：高活跃用户 A 与沉默用户 B。旧策略把高券大量发给 A，所以 OBS 中 A 的“高券—订单”相关性很高。只用 OBS 的模型会以为 A 最值得继续拿高券。

RCT 却可能发现：A 即使不给券也会下单，高券的**增量**有限；B 的绝对订单少，但 5 元券带来的增量更大。Bi-DFCL 的下层不会丢掉 OBS 中关于两类用户行为的大量统计规律；上层会根据 RCT 中“用当前 Target 分券后实际订单是否更多”来校正 Bridge。最终 Target 可能把一部分高券从 A 挪给 B，预算有限时总增量订单更高。

这正是“桥接”不是加样本，而是让 RCT 指挥 OBS 如何参与学习。

## 10. 实验结果应怎样严谨解读

- 三类离线数据：Criteo-Uplift v2 hybrid；美团 money-off（约 550 万 RCT、2220 万 OBS）；美团折扣（约 500 万 RCT、3380 万 OBS）。
- 消融逐步加入 PPL、双层 OBS+RCT、counterfactual pseudo-label、implicit differentiation；两套营销数据的 EOM 提升从基线 1.0000 逐步到 1.0277 / 1.0252，说明每块都有边际贡献，但不代表它们在所有数据分布下必然独立相加。
- 线上四周、79 万商家随机分五组的 A/B 中，论文报告 DFCL-PIFD 相对 TSM-SL 提升 1.80%，Bi-DFCL-PPL 3.00%，Bi-DFCL-PIFD 3.22%。这支持“无偏 RCT 决策信号校正 OBS 训练方向”的系统价值。

## 11. DFCL 与 Bi-DFCL 的关系

| 维度 | DFCL | Bi-DFCL |
|---|---|---|
| 主攻问题 | 预测目标与预算决策目标不一致 | 决策不一致 + OBS 偏差/RCT 稀缺 |
| 决策处理 | 主要通过对偶 policy/entropy 或 IFD | 在原始预算问题上构造 PPL/PIFD |
| 数据假设 | RCT 能支持无偏 policy evaluation | RCT 无偏但少，OBS 多但有偏 |
| 核心结构 | 一个预测模型 + 决策 loss | Target + Bridge + Teacher 的双层优化 |
| 如何避免手调权重 | \(\alpha\) 平衡预测/决策仍需设计 | 让 RCT 上层目标数据驱动地校正下层 |

## 12. 局限与落地风险

1. **RCT 覆盖仍是底线。**如果 RCT 没覆盖将要上线的人群、干预档位或预算区域，上层的“无偏校正”也无法外推到这些区域。
2. **双层优化不是免费。**CG、HVP、周期性 upper step 都增加训练复杂度；需监控数值稳定、近似步数和额外训练时延。
3. **伪标签仍会传递 Teacher 的盲点。**Bridge 能根据上层决策质量纠偏，但不能从没有任何 RCT 信息的完全新干预中创造可靠因果知识。
4. **优化目标决定策略行为。**若收益只用订单数，模型可能偏向低质量或低利润订单；业务应把长期留存、风控、商家体验、频控/公平约束放进评价和 OR 约束。

## 13. 最终 takeaway

**Bi-DFCL 的核心贡献是把“OBS 多、RCT 真”变成一个可学习的因果闭环：OBS 负责学得稳，RCT 负责指方向，Bridge 负责让这两种信息在最终预算决策上对齐。**
