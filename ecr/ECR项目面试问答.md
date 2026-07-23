---
tags:
  - ECR
  - Uplift
  - Causal-Inference
  - CFR
  - Ranking
  - 面试
created: 2026-07-23
---

# ECR 项目面试问答

> 本文按“面试官提问 → 推荐回答 → 追问展开”组织。  
> 项目最终口径：**TwoStage Progressive H2 Soft T2 多档位 Uplift 排序模型**。  
> 注意：现有笔记没有写出 ECR 英文全称，面试时不要临场猜缩写；请按公司内部真实业务名称补充。

## 0. 一分钟项目介绍

**面试官：请先介绍一下 ECR 项目。**

这个项目研究的是多档位补贴下的呼叫增量排序。业务不是单纯预测“谁会呼叫”，而是要识别“谁会因为某一补贴档位而增加呼叫”，从而把有限补贴优先给真正可被激励的用户。

原 baseline 是 CFR 多档位响应模型：Shared Bottom 学习公共表征，多个 Treatment Head 分别预测十个档位下的呼叫概率，以 100 档为 control，第 $m$ 档的 uplift score 定义为：

$$
s_{i,m}=\hat p_m(x_i)-\hat p_{100}(x_i)
$$

但 baseline 只用 observed arm 上的 factual BCE，优化的是响应概率，不直接优化最终 Call AUCC 排序。因此我主要做了四件事：第一，用 IPW 和 $2y-1$ 构造四格因果排序伪标签；第二，用 Corr Loss 提供全局、稠密的排序监督，并用 matched pairwise 补充局部顺序；第三，在 rank loss 内对每个档位的 uplift score 做 z-score 加 tanh 校准；第四，采用 TwoStage 和 Progressive Soft-Unfreeze，先学习稳定响应 anchor，再温和加入排序梯度，防止模型为了刷 AUCC 学到 treatment identity、高频曝光等捷径。

最后选择 H2 Soft T2，不是因为它的单一 AUCC 最高，而是因为它在 treatment-ratio 相对稳定的候选中 Call MTAUCC 最好，体现了因果排序效果和可信度之间的折中。

---

## 一、业务与问题定义

## 1. 这个项目的业务目标是什么？

**推荐回答：**

业务目标是在多个补贴档位下进行增量人群排序。普通响应模型会把本来就容易呼叫的人排在前面，但给这些人补贴可能只是浪费预算。Uplift 模型关注 treatment 相对 control 带来的增量，希望优先触达“不给补贴不呼叫、给补贴才会呼叫”的可激励用户。

如果进一步落到策略层，模型输出的是每个用户、每个档位相对 control 的增量：

$$
\hat\tau_m(x)=\hat p(Y=1\mid X=x,T=m)-\hat p(Y=1\mid X=x,T=100)
$$

在有补贴成本和预算限制时，最终策略还应比较增量收益与成本，而不只是选择 uplift 最大的档位。

## 2. 为什么不能直接做呼叫概率预测？

**推荐回答：**

因为预测响应和预测增量是两个不同问题。高呼叫概率可能来自用户自身需求强，不代表补贴有效。例如一个用户在 control 下呼叫概率已经很高，即使 treatment 下也很高，两者差值可能接近零；响应模型会认为他很重要，uplift 模型却认为没有必要补贴。

可写成：

$$
\text{Response}=P(Y=1\mid X,T=m)
$$

$$
\text{Uplift}=P(Y=1\mid X,T=m)-P(Y=1\mid X,T=100)
$$

前者回答“会不会呼叫”，后者回答“补贴是否改变了呼叫行为”。

## 3. 为什么这是因果问题，而不只是排序问题？

**推荐回答：**

因为同一个用户在同一时刻只能接受一个档位，只能看到一个 factual outcome，其他档位下的结果都是反事实。我们真正关心的是两个潜在结果之差，但无法同时观测，因此必须依赖 RCT、倾向校正、结果模型等因果识别条件，才能把相关性排序解释为补贴增量排序。

## 4. ATE、CATE、ITE 分别是什么？

**推荐回答：**

- ATE 是整体平均处理效应：$E[Y(m)-Y(100)]$。
- CATE 是给定特征人群的条件平均处理效应：$E[Y(m)-Y(100)\mid X=x]$。
- ITE 是单个个体的处理效应：$Y_i(m)-Y_i(100)$。

真实 ITE 一般不可观测。模型输出的 $\hat\tau_m(x)$ 更准确地说是 CATE/ITE 的估计，而不是个体真实标签。

## 5. 你的因果识别依赖哪些假设？

**推荐回答：**

主要包括：

1. Consistency：用户实际接受档位 $m$ 时，观测结果等于潜在结果 $Y(m)$。
2. SUTVA：一个用户的 treatment 不影响其他用户结果，且同一档位没有未定义的多个版本。
3. Overlap：对需要比较的人群，各档位都有非零分配概率。
4. Ignorability：给定 $X$ 后 treatment assignment 与潜在结果独立；RCT 下理论上由随机化保证。
5. 特征、treatment 和标签的时间顺序正确，不存在未来信息穿越。

项目数据虽然来自 RCT，但还需要确认随机化粒度究竟是用户、用户日、冒泡还是订单行。订单行重复和样本选择会让分析数据不再表现为理想的独立随机样本。

---

## 二、Baseline 与模型结构

## 6. 你的 baseline 是什么？

**推荐回答：**

Baseline 是 CFR 多档位响应模型。它用共享 Embedding 和 Shared Bottom 学习用户、订单的公共表征，再通过多个 treatment-specific heads 输出十个补贴档位下的呼叫概率。训练时只在样本实际进入的档位上计算 factual BCE，并保留 CFR 的表征平衡、ATE 或约束项。

它的优势是响应概率稳定、共享表征提高样本效率；不足是训练目标没有直接要求 treatment-control 差值按照真实 uplift 排序。

## 7. 模型最终输出什么？

**推荐回答：**

模型先输出十个档位的 factual call probability：

$$
[\hat p_{100}(x),\hat p_{97}(x),\ldots,\hat p_{73}(x)]
$$

然后对每个非 control 档位计算：

$$
s_m(x)=\hat p_m(x)-\hat p_{100}(x)
$$

线上排序用的是 uplift score，而不是单独的 treatment probability。否则模型会把自然呼叫率高的人误当成高增量人群。

## 8. 为什么使用 Shared Bottom 加多个 Head？

**推荐回答：**

不同补贴档位共享大量用户需求和场景信息，Shared Bottom 能提高样本效率，特别是低频档位可以借助其他档位学习公共表示；独立 Head 则保留档位差异。

风险是不同档位的梯度可能冲突，共享表征也可能把 treatment-specific 模式抹平。可选改进包括轻量 FiLM、Adapter 或部分独立 Tower，但自由度越大，越需要防止 treatment leakage 和小样本过拟合。

## 9. Cumulative Head 是什么？为什么使用它？

**推荐回答：**

Cumulative Head 用相邻档位增量构造更深折扣的输出，例如：

$$
z_{73}=z_{100}+\Delta_{97}+\Delta_{94}+\cdots+\Delta_{73}
$$

它把“补贴更强时响应通常不应下降”的单调先验注入模型，能减少独立 Head 出现无序交叉并提高样本效率。

风险是浅层增量节点会接收多个后续档位的累计梯度：

$$
\frac{\partial L}{\partial\Delta_k}
=\sum_{m:\Delta_k\in z_m}\frac{\partial L_m}{\partial z_m}
$$

因此误差和 rank 噪声可能沿 cumulative path 传播，深折扣 score 方差也可能更大。需要监控各节点梯度范数，并与 Independent Head 做消融。

## 10. CFR 和 DRCFR 有什么区别？为什么 DRCFR 没有更好？

**推荐回答：**

CFR 的重点是学习对 outcome 有用、同时减少 treatment 组间分布差异的表征；DRCFR 进一步对不同因果因素或表征成分做解耦，理论上在观察性数据里可能更有优势。

但本项目来自 RCT，传统 confounding 已被随机化显著削弱；当前主要风险反而是重复行、高频用户、treatment composition 和伪标签方差。更复杂的表征分解增加优化难度，不一定改善 AUCC。实验中 CFR factual baseline 的 Call MTAUCC 为 0.59046，DRCFR 为 0.58615；加入 matched pairwise 后 DRCFR 也没有胜出，所以最终选择更简单、稳定的 CFR 主干。

---

## 三、伪标签与排序损失

## 11. 真实 ITE 不可观测，你怎么训练排序模型？

**推荐回答：**

我为每个 treatment $m$ 与 control 100 构造 transformed outcome/IPW 伪标签：

$$
\phi_{i,m}
=(2y_i-1)\left[
\frac{\mathbb I(T_i=m)}{e_m(X_i)}
-\frac{\mathbb I(T_i=100)}{e_{100}(X_i)}
\right]
$$

在 RCT 下 $e_m$ 可使用实验分流概率；若估计 propensity，则必须 clipping 并监控有效样本量。这个伪标签不是单个用户的真实 uplift，但在总体期望上能提供 treatment-control 增量方向。

## 12. 为什么把标签从 $y$ 改成 $2y-1$？

**推荐回答：**

如果直接使用 $y\in\{0,1\}$，所有未呼叫样本都会令伪标签为零，treatment 未呼叫和 control 未呼叫无法区分，而未呼叫通常占数据大多数。

使用 $2y-1\in\{-1,1\}$ 后四类样本都有方向：

| 样本状态 | 伪标签方向 | 排序含义 |
|---|---:|---|
| Treatment、呼叫 | 正 | 正向 treatment 证据 |
| Treatment、未呼叫 | 负 | 给了补贴仍未响应 |
| Control、呼叫 | 负 | 不补贴也会自然呼叫 |
| Control、未呼叫 | 正 | 可能存在被补贴激活空间 |

从期望上看，这种编码估计的是 $2\times$ treatment effect，常数倍不影响 Corr 排序方向。

## 13. Control 未呼叫为什么给正信号？这是不是强行猜反事实？

**推荐回答：**

单个 control non-caller 并不能证明 treatment 后一定呼叫，因此不能把这个正号解释成真实 ITE 标签。它只是 transformed outcome 的一个带噪观测贡献：control 下未响应说明其自然响应较低，在随机化和总体平均意义下，对 treatment-control 差值提供正向方向。

所以关键是强调“总体无偏或方向有效”，不能把四格表当作单样本因果真值。也正因为单样本方差高，项目采用 Corr、分组、校准和 TwoStage 限制其影响。

## 14. 为什么使用 Corr Loss，而不是直接 MSE 回归伪标签？

**推荐回答：**

最终指标 AUCC 关注排序，不要求 uplift score 和高方差伪标签在数值尺度上完全一致。Corr Loss：

$$
L_{corr}=1-\operatorname{Corr}(s,\phi)
$$

对正比例缩放和平移不敏感，更关注预测分数与伪标签是否同涨同跌；MSE 则容易被 IPW 极值和伪标签尺度主导。

Corr 的优点是 batch 内监督稠密、梯度强，实验中 AUCC 提升明显；缺点是对 batch 构成敏感，只保证整体趋势，并可能利用 treatment composition。因此它需要和 factual anchor、pairwise 及 ratio 诊断一起使用。

## 15. Corr 是怎么提供排序信息的？它又没有显式排序 1、2、3、4。

**推荐回答：**

排序监督不一定要显式枚举完整名次。Corr 要求高伪标签样本对应高 score、低伪标签样本对应低 score。当两个样本预测相近但伪标签方向相反时，相关性会下降，梯度会推动正向样本分数上升、负向样本分数下降。

它提供的是全局相对顺序约束，不是显式的全排列标签。这正适合真实 ITE 不可观测、只能得到带噪方向性监督的场景。

## 16. Pairwise Loss 是怎么构造的？

**推荐回答：**

我没有全局随机配对，而是在模型表征空间中为 treatment/control 寻找相近样本，通过 Top-K 软匹配构造局部 pair。典型方向包括：

- Treatment caller 相对 Control non-caller，应有更高 uplift score；
- Treatment non-caller 相对 Control caller，应有更低 uplift score。

可用 logistic pairwise loss：

$$
L_{pair}=\log\left(1+\exp[-r_{ij}(s_i-s_j)]\right)
$$

其中 $r_{ij}\in\{-1,1\}$ 表示期望顺序。最终参数包括 `match_topk=4`、`match_temperature=0.2`、`margin=0` 等。

## 17. 为什么 Pairwise 单独使用效果不强？

**推荐回答：**

因为每个 batch、每个档位内可构造的有效 treatment-control pair 数量有限，匹配本身也有噪声；Pairwise 只利用局部样本关系，梯度覆盖不如 Corr 稠密。实验中 CFR matched pairwise only 从 factual baseline 的 0.59046 提升到 0.60117，只有小幅增益。

因此 Corr 负责建立全局排序方向，Pairwise 负责补充局部顺序，两者是主辅关系。

## 18. 为什么不直接对 AUCC 求梯度？

**推荐回答：**

AUCC 包含排序、截断和累计统计，原始形式不可微，而且 mini-batch AUCC 方差大、容易被 batch treatment/control 构成影响。Corr 和 pairwise 是可微 surrogate：Corr 提供全局方向，pairwise 近似局部换序代价。

如果进一步优化，可以研究 LambdaRank 风格的 $\Delta AUCC$ 加权 pairwise，但仍要防止 treatment composition bias，不能只追求离线曲线面积。

## 19. IPW 和 DR 伪标签有什么区别？

**推荐回答：**

IPW 只用 propensity 重新加权，形式简单，但 propensity 小时方差会很大。DR 同时使用 propensity model 和 outcome model：

$$
\phi_m^{DR}=\hat\mu_m(X)-\hat\mu_{100}(X)
+\frac{I(T=m)}{e_m(X)}[Y-\hat\mu_m(X)]
-\frac{I(T=100)}{e_{100}(X)}[Y-\hat\mu_{100}(X)]
$$

理论上只要 propensity 或 outcome model 有一个正确，ATE 类估计仍一致。但双重鲁棒不保证有限样本的个体排序一定更好；nuisance 过拟合、残差长尾和 pseudo 方差都可能让 DR 排序变差。本项目中 DR 没有稳定超过 IPW，所以没有把理论优势直接等同于实际收益。

## 20. 为什么需要 OOF/Cross-Fitted DR？

**推荐回答：**

如果 nuisance model 在样本 $i$ 上训练后，又为同一条样本生成 $\hat\mu(X_i)$ 和 $\hat e(X_i)$，可能记忆标签，使 residual 过于乐观。Cross-fitting 用其余 $K-1$ 折训练 nuisance，只为未见过的第 $K$ 折生成 pseudo，再合并所有折外结果。

这样能减少 nuisance overfitting bias，代价是训练成本增加。工程上可先用 2-Fold 或轻量 XGBoost/LightGBM 生成并缓存 OOF pseudo。

---

## 四、Score Calibration 与两阶段训练

## 21. 为什么要对 uplift score 做 z-score + tanh？

**推荐回答：**

不同 treatment 的 uplift score 均值、方差和长尾程度不同，深折扣档位尤其容易产生极端值。如果直接输入 Corr/Pairwise，某些档位可能因为尺度大而获得过强 rank 梯度。

因此对每个 treatment 的 score 做：

$$
z_{i,m}=\frac{s_{i,m}-\mu_m}{\sigma_m+\epsilon}
$$

$$
\tilde s_{i,m}=\tanh(z_{i,m}/T)
$$

z-score 让不同档位进入相近尺度，tanh 压缩极端长尾，温度 $T$ 控制锐化程度。该校准只作用于 rank loss 的训练空间，不修改最终 factual probability 和线上 uplift 定义。

## 22. 为什么 `detach_stats=true`？

**推荐回答：**

均值和方差在这里是校准统计量，不希望模型通过操纵整个 batch 的 $\mu$、$\sigma$ 来走捷径。Detach 后，梯度只作用于每个样本的 score，而不通过 batch statistics 反向传播，优化更稳定，也更接近“固定尺度标准化”的设计意图。

代价是统计量仍受小 batch 组成影响，因此需要保证每个档位的最小样本数，或使用更稳定的 train-only/EMA 统计。

## 23. 温度 $T=1,2,3$ 分别有什么影响？为什么选 $T=2$？

**推荐回答：**

$T$ 越小，tanh 输入绝对值越大，分数更快饱和、排序更锐；$T$ 越大，映射更平滑、梯度更保守。

H1 使用 T=3，比较稳定但区分度不足；H3 使用 T=1，Avg AUCC 略高，但 Call MTAUCC 没超过 H2；H2 的 T=2 在排序强度和 ratio 风险之间更平衡，所以最终选择 T=2，而不是认为它在理论上普遍最优。

## 24. 为什么采用 TwoStage，而不是一开始联合训练所有 Loss？

**推荐回答：**

factual label 是直接观测的，噪声相对低；rank pseudo 是反事实估计，方差高且可能包含 treatment leakage。如果训练初期让强 rank 梯度更新全部表征，模型会优先学习最容易提升 AUCC 的捷径，例如识别 treatment 身份、高频冒泡用户或深折扣样本，而不是学习真实异质性效应。

Stage 1 先用 factual objective 得到稳定 response/uplift anchor；Stage 2 再在 anchor 邻域加入 Corr 和 Pairwise。它本质上是：

$$
\min_\theta L_{rank}(\theta)
\quad\text{s.t.}\quad
\|\theta-\theta_{anchor}\|\le\delta
$$

## 25. Progressive Soft-Unfreeze 是怎么做的？

**推荐回答：**

Stage 2 先冻结 Embedding 和 Shared Bottom，只训练 Head，让输出层先适应 rank 目标；随后继续冻结 Embedding，只以 Head 学习率的 0.01 倍更新 Shared Bottom。这样 Head 有足够自由度改善排序，而底层表征只能围绕 Stage 1 anchor 小幅调整。

完全冻结虽然安全，但 AUCC 上限低；完全解冻虽然指标涨得快，却容易让 treatment-ratio 风险回潮。Progressive Soft-Unfreeze 是两者之间的信任域式折中。

## 26. 最终 Loss 是什么？

**推荐回答：**

总体可写为：

$$
L=L_{CFR/factual}
+\lambda_{corr}L_{PU-Corr}
+\lambda_{pair}L_{matched-pair}
$$

其中 factual/CFR 项保证模型仍是可用的多档位响应模型；Corr 是主要 AUCC 排序项；Pairwise 是局部辅助项。

最终 H2 的主要 rank 权重为：

```text
uplift_rank = 0.015
pair        = 0.003
temperature = 2
rank stage  = 3 epochs
shared bottom lr = 0.01 × head lr
```

权重不是越大越好；实验显示 rank 权重增强会提高 AUCC，但也会同步放大 ratio 风险。

---

## 五、指标、可信度与指标捷径

## 27. AUCC 和 QINI 分别是什么？

**推荐回答：**

两者都先按预测 uplift 从高到低排序，再观察逐步扩大触达人群时 treatment 相对 control 的累计增量。

- QINI curve 更强调相对随机策略的累计增量曲线；Qini coefficient 通常是模型曲线相对随机基线的面积。
- AUCC 是 uplift/cumulative gain curve 下的面积，衡量整体排序质量。
- Call MTAUCC 是项目的多 treatment 核心指标，具体聚合和归一化应以项目评估脚本为准，不能套用普通 AUC 必须处于 $[0,1]$ 的解释。

两者关注的是增量排序，不等于普通响应 AUC。

## 28. 为什么 Call AUC 高不代表 Call AUCC 高？

**推荐回答：**

Call AUC 衡量谁更容易呼叫；Call AUCC 衡量谁的呼叫更容易被 treatment 改变。自然需求很强的人可以有很高响应概率和 AUC，但 treatment-control 差值很小，uplift 排序价值低。

本项目 factual CFR 可以做响应预测，但 Call MTAUCC 只有 0.59046，说明响应模型不是最终排序模型。

## 29. Treatment-ratio 曲线为什么重要？

**推荐回答：**

在理想 RCT 条件下，如果排序只基于 treatment effect，而不是 treatment identity，榜单头部的 treatment/control 比例不应出现无法由随机误差解释的系统性偏斜。

如果模型把 treatment 样本大量排到前面，累计 treatment outcome 会更早增长，AUCC/QINI 可能被人为抬高：

$$
\widehat{AUCC}
=\text{真实 Uplift 排序}
+\text{Treatment Composition Bias}
$$

所以 ratio 不是主效果指标，但它是识别“模型是否刷指标”的关键健康度指标。

## 30. Treatment-ratio 不平是否说明 AUCC 完全无效？

**推荐回答：**

不能直接下结论。有限样本波动、真实异质性和分层分流都可能造成局部偏离。但明显、稳定、跨种子存在的头部偏斜说明模型可能利用 treatment assignment 或重复采样结构。

需要结合以下诊断：treatment assignment AUC、Top 1%/5%/10% 的 ratio、特征 SMD、用户粒度重采样、不同日期/城市/随机种子稳定性、ATE error 和概率校准。

## 31. 数据来自 RCT，为什么模型还能学到 treatment identity？

**推荐回答：**

RCT 只保证在正确随机化单位和原始实验总体上的 treatment 独立。进入建模表之后，以下过程可能破坏理想性质：

- 同一用户或用户日产生不同数量的订单行，形成频次加权；
- 过滤、缺失和标签窗口导致 differential selection；
- 随机化单位不是订单行，但训练按订单行独立采样；
- 历史统计特征包含 treatment 后信息；
- 某些日期、城市或流量层的档位比例不同；
- mini-batch 中各档位构成波动大。

所以 RCT 不等于“最终训练表中不需要任何偏差诊断”。

## 32. 如何证明模型学到的不是指标捷径？

**推荐回答：**

我会做五类检查：

1. 在独立 RCT holdout 中按 score 分桶，检查真实 treatment-control uplift 是否单调。
2. 检查 top-k treatment ratio、SMD 和 propensity predictability。
3. 用用户/用户日为单位 bootstrap，避免重复订单行虚增显著性。
4. 做时间外、城市外和多随机种子验证。
5. 对比响应校准、ATE error 与 AUCC，确认排序提升没有以破坏基本概率结构为代价。

---

## 六、实验结果与模型选择

## 33. 你最关键的实验结论是什么？

**推荐回答：**

有四个核心结论：

1. Factual CFR 能预测响应，但不直接优化 uplift 排序，Call MTAUCC 为 0.59046。
2. Pairwise alone 目标合理但梯度稀疏，只提升到 0.60117，适合作为辅助项。
3. PU-Corr + Pairwise 能把 Call MTAUCC 提到 0.83638，证明强排序监督有效，但 treatment-ratio 风险明显上升。
4. 最终 H2 Soft T2 选择 0.65293，不追求单一最高 AUCC，而是在 ratio 相对稳定的候选里选择主指标最优点。

## 34. E3/B2 的 AUCC 明显更高，为什么最终不选它们？

**推荐回答：**

因为离线 AUCC 不是唯一目标。E3 的 Call MTAUCC 达到 0.89449，B2 达到 0.89464，但它们属于强 rank 单阶段或更强 soft-unfreeze 配置，treatment-ratio 和深折扣侧异常更明显，模型可能同时放大真实 uplift 和 treatment composition artifact。

H2 的定位是 ratio-safe 主线：它接受一部分 AUCC 损失，换取更可信的排序组成。面试时应明确说这是风险约束下的模型选择，不是声称 H2 在所有离线指标上最好。

## 35. 为什么延长 H2 训练没有变好？

**推荐回答：**

H2 从 3 epoch 延长到 8 epoch 后，Call MTAUCC 从 0.65293 降到 0.63490，Avg AUCC 也轻微下降。这说明 H2 的保守 AUCC 不是单纯没收敛，而是 ratio-safe 约束和小学习率限制了排序自由度；继续训练还可能逐渐拟合伪标签噪声。

因此不能用“多跑几轮”解决目标冲突，需要改进伪标签质量、显式 anchor 正则或更可靠的 OOF DR，而不是只增加 epoch。

## 36. 为什么清洗极端 PID 有帮助，但统一频次降权反而下降？

**推荐回答：**

极端 PID 可能是少数异常重复曝光，对 rank loss 产生不成比例影响，定向清洗可以降低污染。但高频用户不全是噪声，其中也可能包含真实需求强度和可排序信息。统一按 user-day 频次降权会同时压掉污染和有效信号。

更合理的做法是基于 train-only 规则识别极端值，或把用户粒度采样、cluster-robust weighting 和有效样本量诊断结合起来，而不是一刀切降权。

---

## 七、工程、泛化与进一步改进

## 37. 如何防止时间穿越和验证集泄漏？

**推荐回答：**

历史呼叫率、历史价格和频次等统计特征只能使用样本时点之前的信息：

$$
X_i(t)=f(\mathcal H_i(<t))
$$

数据应满足 Train Time < Validation Time < Test Time，并避免同用户同天的高度相似记录跨集合。清洗规则只能由训练集确定；若反复根据测试集异常 PID、城市或日期修改规则，测试集已经退化成验证集。

## 38. 为什么随机切分可能高估效果？

**推荐回答：**

同一用户、相近时间和重复冒泡记录可能同时进入训练与验证；历史统计还可能包含验证时段或当天未来信息。模型会记住用户频次和局部分流结构，导致 AUCC 与 ratio 看起来更好，但时间外泛化下降。

应同时报告时间切分、用户粒度去重或 Group Split 结果。

## 39. 线上如何从多个档位中选择一个 treatment？

**推荐回答：**

当前模型提供每个档位相对 control 的 $\hat\tau_m(x)$。如果各档位成本不同，不能简单取最大 uplift，而应优化增量收益：

$$
m^*(x)=\arg\max_m
\left[V\cdot\hat\tau_m(x)-C_m\right]
$$

或在总预算、档位容量、公平性和风险约束下做全局分配。若更关注性价比，可参考 $\hat\tau_m/C_m$，但比值在小 uplift 时不稳定，实际更适合用约束优化或 Lagrangian policy。

这属于模型后的策略层，当前项目主要解决 uplift score 估计与排序，不能把两者混为同一项已完成工作。

## 40. 模型上线后怎么验证真实收益？

**推荐回答：**

最终仍需新的在线 RCT。可以把用户随机分到现网策略和 uplift 策略，观察增量呼叫、补贴成本、ROI、不同档位占比、长期留存和用户体验。还要监控 score 分布、treatment ratio、各档位有效样本量和校准漂移。

离线 AUCC 只能用于模型筛选，不能代替策略级因果实验。

## 41. 当前项目最大的局限是什么？

**推荐回答：**

第一，真实 ITE 不可观测，排序监督依赖高方差 pseudo；第二，强 Corr Loss 很容易利用 treatment composition；第三，RCT 的真实随机化粒度和订单行重复结构仍需进一步确认；第四，最终 H2 是可信度与指标折中，并没有解决所有 ratio 风险；第五，模型选择实验较多，需要独立时间外 holdout 防止 validation overfitting。

## 42. 如果继续做，你最优先改什么？

**推荐回答：**

我会优先做三件事：

1. 用轻量 outcome/propensity model 生成并缓存 2-Fold 或 5-Fold DR pseudo，验证能否降低 IPW 方差。
2. 增加显式 anchor regularization，例如约束 Stage 2 score 不要过度偏离 Stage 1，并对 ratio risk 建立可优化或早停指标。
3. 建立 untouched 时间外 holdout 和用户粒度 bootstrap，把 AUCC、ratio、ATE error、seed variance 合成多目标选择标准。

其次再考虑 FiLM、Bi-Anchor、SNR/ESS 动态档位权重或 LambdaRank 式 $\Delta AUCC$ 加权。

---

## 八、压力追问

## 43. 你的 PU-Corr 真的“因果”吗？

**推荐回答：**

Loss 本身不是因果性的来源。因果解释来自实验设计或可识别假设、正确 propensity、无穿越的数据处理和独立验证。PU-Corr 只是把 transformed outcome 的方向映射到可微排序目标。如果 treatment assignment、采样单位或特征时间有问题，它同样会学习偏差。

## 44. Corr 高就代表排序好吗？

**推荐回答：**

不一定。Corr 只保证 batch 内整体线性共同变化，对局部 top-k 顺序、跨 batch 稳定性和因果无偏性都没有保证。它还可能通过 treatment-side 特征获得高相关。因此需要 Pairwise、AUCC/QINI、ratio、分桶 uplift 和时间外验证共同判断。

## 45. 为什么不直接选择离线分数最高的模型？

**推荐回答：**

因为因果模型最危险的失败方式不是“指标低”，而是“指标很高但来自不可泛化的捷径”。如果 AUCC 提升伴随 treatment ratio、SMD 或 assignment AUC 异常，线上策略可能没有真实增量，甚至浪费补贴。最终模型选择必须把效果和可信度一起考虑。

## 46. 这个项目最有价值的 insight 是什么？

**推荐回答：**

最大的 insight 是：响应预测底座、因果排序目标和排序可信度必须分开处理。

- Factual CFR 负责建立稳定、可解释的各档位响应概率；
- Corr/Pairwise 负责补上 AUCC 排序监督；
- TwoStage、Soft-Unfreeze 和 score calibration 负责限制高方差 rank 信号污染底层表征；
- Treatment-ratio 等诊断负责识别“高 AUCC 是否来自指标捷径”。

所以最终方案不是简单增加一个 rank loss，而是在稳定 response anchor 邻域内做受约束的 uplift 排序优化。

---

## 九、30 秒收尾版

ECR 项目的核心矛盾是：factual response objective 和最终 uplift ranking metric 不一致。我保留 CFR 多档位响应模型作为 anchor，用 $2y-1$ 的 IPW transformed outcome 给呼叫和未呼叫样本都提供因果排序方向，再通过 Corr 建立全局排序、Matched Pairwise 补充局部顺序。由于强 rank loss 会放大 treatment composition artifact，我加入分档 z-score+tanh、TwoStage 和 Progressive Soft-Unfreeze。最终选择 H2 Soft T2，是在 Call AUCC 与 treatment-ratio 可信度之间做受约束的折中，而不是机械选择离线最高分。

## 十、对应 Obsidian 笔记

- [[CFR]]
- [[模型搭建思路]]
- [[模型搭建思路逐字稿]]
- [[ECR问题记录]]
- [[rankloss]]
