# 1. 总结：最优架构

# 目录

- [# 1.1 当前最优架构详解：TwoStage progressive H2 soft T2](#11-当前最优架构详解twostage-progressive-h2-soft-t2)
- [# 4.1 Factual baseline：确认普通响应预测不是最终目标](#41-factual-baseline确认普通响应预测不是最终目标)
- [# 4.2 Pairwise alone：更贴近排序，但梯度不够强](#42-pairwise-alone更贴近排序但梯度不够强)
- [# 4.3 Corr / PU-Corr rank：AUCC 拉升最强，但 treatment-ratio 风险变大](#43-corr-pu-corr-rankaucc-拉升最强但-treatment-ratio-风险变大)
- [# 4.4 Clean pid 与频次加权：数据修正有帮助，但不能粗暴降权](#44-clean-pid-与频次加权数据修正有帮助但不能粗暴降权)
- [# 4.5 Score calibration E 组：score 空间处理有效，但仍不能替代 ratio-safe 主线](#45-score-calibration-e-组score-空间处理有效但仍不能替代-ratio-safe-主线)
- [# 4.6 TwoStage soft-unfreeze / anneal：AUCC 能追回，但 ratio 风险回潮](#46-twostage-soft-unfreeze-annealaucc-能追回但-ratio-风险回潮)
- [# 4.7 G组：HeadRank：平稳 anchor 上加 rank，收益有限](#47-g组headrank平稳-anchor-上加-rank收益有限)
- [# 4.8 H2 Soft T2 Extended Epoch Check：延长训练不能解决 AUCC 偏低](#48-h2-soft-t2-extended-epoch-check延长训练不能解决-aucc-偏低)

|                                 |             |         |          |          |
| ------------------------------- | ----------- | ------- | -------- | -------- |
|                                 | Call MTAUCC | Random  | Avg AUCC | Avg Qini |
| TwoStage progressive H2 soft T2 | 0.65293     | 0.42947 | 0.3769   | 0.1728   |

# 1.1 当前最优架构详解：TwoStage progressive H2 soft T2

![[Pasted image 20260714204810.png]]

> 当前模型是一个“先稳住因果响应预测，再温和加入排序优化”的两阶段多档位 uplift 排序模型。它先用 CFR 结构分别预测不同折扣档位下用户的呼叫概率，再以相对 100 档的概率差作为 uplift 分数；随后在第二阶段固定或小幅微调底层表征，在 uplift 分数上加入经过校准的 Corr 排序损失和 pairwise 排序损失，用来提升 Call AUCC，同时尽量避免 rank loss 破坏原本较稳定的 treatment/control 结构。

这个架构分成四层理解：

1. **CFR 多档位响应模型。** shared bottom 学习用户/订单的共性表征，多个 treatment head 分别输出不同折扣档位下的 call 概率。不足是单纯 factual BCE 只会优化“当前被分到的档位是否 call”，不会直接优化 AUCC 排序。
2. **TwoStage anchor 训练。** 第一阶段只训练相对稳定的 response/uplift anchor；第二阶段再在 anchor 基础上加入排序目标。这样做是因为 rank loss 很容易把 treatment 侧重复曝光、高频人群、深折扣偏置当成可排序信号。如果一开始就让强 rank loss 更新 shared bottom，整个表征空间会被偏差信号牵着走，表现为 Call AUCC 可能很高，但 QINI treatment-ratio 红线明显异常。
3. **Calibrated rank loss。** 第二阶段不是直接对原始 uplift score 做相关性或 pairwise 排序，而是先对每个 treatment 的 score 做 zscore + tanh 校准

这里的目的，是把不同 treatment 的 score 放到可比尺度上，并压缩长尾极值，避免深折扣档位因为 score 尺度漂移获得过强梯度。H2 使用 `T=2`，属于“比 H1 更有区分度、比 H3 更保守”的折中。

4. **Progressive soft-unfreeze。** 第二阶段不是一下子完全放开所有参数，而是先 hard-freeze 底层，只让 head 适配 rank loss；随后 soft-unfreeze 部分 shared bottom，并把 shared bottom 学习率设置为 head 学习率的 `0.01` 倍。这个设计的作用，是让模型在不大幅破坏 anchor 的前提下追回 AUCC。

> 这一组是 TwoStage progressive rank calibration 主线。它先用 samearch/headrank anchor 稳住 treatment/control 的基本排序结构，再通过 H0→H1→H2→H3 逐步增加 rank 自由度：H0 只训练 head 作为过渡，H1/H2/H3 在小学习率下 soft-unfreeze shared bottom，并通过温度 T 从 3 到 2/1 控制 rank score 的锐化程度。

|                                   |                                                  |           |                                               |       |                                 |             |             |            |            |                                       |
| --------------------------------- | ------------------------------------------------ | --------- | --------------------------------------------- | ----- | ------------------------------- | ----------- | ----------- | ---------- | ---------- | ------------------------------------- |
| 实验                                | 冻结/学习率                                           | 温度        | Rank 权重                                       | Epoch | 目的                              | Call MTAUCC | Random      | Avg AUCC   | Avg Qini   | 结论                                    |
| TwoStage samearch headrank anchor | 固定或近似固定 shared bottom                            | -         | 弱 rank                                        | 已完成   | 得到 treatment-ratio 相对平的起点       | 0.63847     | 0.40557     | 0.3928     | 0.2076     | ratio 更稳，但 AUCC 仍偏低                   |
| H0 headwarm T3                    | 冻结 `embed_layers + share_block`                  | `T=3`     | `uplift_rank=0.010`, `pair=0.002`             | 2     | 只让 head 适配 rank score，避免一开始冲击底座 | 0.64352     | 0.42947     | 0.3589     | 0.1550     | 过渡阶段，防止 rank spike                    |
| H1 soft T3                        | 冻结 `embed_layers`，`share_block` 用 `0.01×lr_head` | `T=3`     | `uplift_rank=0.012`, `pair=0.0025`            | 3     | 温和恢复 AUCC                       | 0.64425     | 0.42947     | 0.3760     | 0.1700     | AUCC 温和恢复                             |
| H2 soft T2                        | 冻结 `embed_layers`，`share_block` 用 `0.01×lr_head` | `**T=2**` | `**uplift_rank=0.015**`**,** `**pair=0.003**` | **3** | **最终推荐点：比 H1 更有排序区分度，比 H3 更保守** | **0.65293** | **0.42947** | **0.3769** | **0.1728** | **最终选择：ratio 相对较平候选中 Call MTAUCC 最高** |
| H3 soft T1                        | 同 H2                                             | `T=1`     | `uplift_rank=0.015`, `pair=0.003`             | 3     | 进一步锐化，但 Call MTAUCC 没有超过 H2     | 0.65213     | 0.42947     | 0.3782     | 0.1740     | Avg AUCC 略高，但主指标 Call MTAUCC 低于 H2    |

H2 的总 loss 可以写成：

其中 包含 CFR 原有的 factual response 学习和表征约束，保证模型仍然是一个可用的 call probability model；后两项是新增的 AUCC 排序目标。

H2 中 ，`detach_stats=true`，即均值/方差只作为校准统计量，不让梯度通过 batch 统计量反向传播。这个设计的目的有两个：

1. 把不同 treatment 的 score 尺度拉到可比空间，避免某些深档因为均值/方差漂移天然获得更大 rank 梯度；
2. 用 `tanh` 压缩长尾极值，防止少数极端样本主导相关性梯度。

当前关键参数是：`min_samples_per_group=2`，`max_group_samples=128`，`match_topk=4`，`match_temperature=0.2`，`rank_temperature=1.0`，`margin=0.0`。它的作用不是替代 corr，而是给 corr 提供更接近 LambdaRank/AUCC 的局部排序约束。

`corr-rank` 可以把 AUCC 拉得很高，但也会把 treatment-side selection artifact 一起放大，导致 QINI 红线异常。H2 通过三道约束降低这个风险：

- **TwoStage anchor**：先让模型获得相对稳定的 treatment/control 排序组成，再加入 rank；
- **progressive unfreeze**：先冻住 shared bottom，只训练 head；再用 `0.01×lr_head` 轻微更新 `share_block`；
- **score calibration**：用 `zscore_tanh(T=2)` 限制 rank score 的尺度和长尾。

# 2.整体架构图 / 思考链路图

# 3. 当前 Loss 结构：baseline 原有项与新增项

当前主要 loss 分成两类：baseline 原有项用于学习 factual response 和因果表征；新增 rank 项用于直接提高 Call AUCC。最有效的是 `PU-Corr (2y-1)`，matched pairwise 是辅助项。

总体形式：

|   |   |   |   |   |   |
|---|---|---|---|---|---|
|Loss|Baseline or Added|公式/定义|目的|收益|风险|
|Factual BCE|Baseline||学 observed arm response|AUC 稳定|不直接优化 uplift ranking|
|Imbalance / ATE / constrain|Baseline|CFR/DRCFR 原有表征约束|缓解 treatment 表征差异|提供因果表征起点|不能单独解决 AUCC 排序|
|IPW pseudo|Early added||构造 uplift pseudo|简单直接|`y=0` 全为 0，未呼叫信息坍缩|
|PU-Corr `(2y-1)`|Added/main||让 caller/non-caller 都提供正负证据|AUCC 提升最明显|会学习 selection artifact|
|Corr rank|Added/main||最大化 score 与 pseudo 排序相关|尺度不敏感，梯度强|ratio 容易被 rank signal 带偏|
|Matched pairwise|Added/aux||让正向证据排在负向证据前|更贴近 LambdaRank/AUCC|pair 稀疏，单独太弱|
|Score calibration|Added/diagnostic|center / zscore /|缓解 score 均值漂移和长尾|E3 指标强|若不约束 ratio，仍可能放大 rank artifact|
|TwoStage freeze|Added/architecture|Stage1 factual，Stage2 freeze/soft-unfreeze rank|阻止 rank loss 污染 shared bottom|ratio 更稳|AUCC 损失明显|

`PU-Corr (2y-1)` 的四格解释是当前 loss 的关键：

|   |   |   |
|---|---|---|
|样本类型|pseudo 符号|排序含义|
|treatment caller|正|发券后 call，是正 uplift 证据|
|treatment non-caller|负|发券后仍不 call，是负证据|
|control caller|负|不发券也 call，说明不是增量，应压低|
|control non-caller|正|不发券不 call，是潜在可拉动人群|

这个设计参考 transformed outcome / uplift ranking 与 Learning-to-Rank for Uplift 的思路，结合当前 10-treatment RCT 数据做的工程化改写。

# 4. 实验迭代分块：每类方法的动机、结果和结论【seed=1111】

# 4.1 Factual baseline：确认普通响应预测不是最终目标

这一组的目的，是确认 CFR / DRCFR 作为 response prediction baseline 是否足够。做法是只训练 factual BCE 和 CFR/DRCFR 原有表征项，不加 AUCC/rank 目标。

> 架构模式注释：这一组是“纯响应预测底座”。模型只学习各 treatment 下的 observed call probability，CFR/DRCFR 的差异主要体现在表征约束/分解方式上，但没有额外的 uplift 排序头，也没有 corr、pairwise 或 score calibration。因此它回答的是“底座能不能预测 call”，不是“能不能把增量最大的人排在前面”。

|                        |                                           |             |         |          |          |                          |
| ---------------------- | ----------------------------------------- | ----------- | ------- | -------- | -------- | ------------------------ |
| 实验                     | 方法                                        | Call MTAUCC | Random  | Avg AUCC | Avg Qini | 结论                       |
| CFR factual baseline   | CFR shared bottom + treatment heads + BCE | 0.59046     | 0.42947 | 0.3253   | 0.1879   | AUC/响应预测可用，但 uplift 排序不足 |
| DRCFR factual baseline | DRCFR 表征/分解结构 + BCE                       | 0.58615     | 0.42947 | 0.2722   | 0.1839   | 没有天然优于 CFR               |

结论：baseline 说明模型可以学习 factual call probability，但它没有直接优化“谁应该排在前面”。因此后续必须引入 uplift/rank 目标。

# 4.2 Pairwise alone：更贴近排序，但梯度不够强

这一组的目的，是验证 LambdaRank / pairwise 思路能不能单独解决 AUCC。做法是构造 treatment/control matched pair，让正向增量证据排在负向证据前面。

> 架构模式注释：这一组是在 CFR/DRCFR 底座上只加入 matched pairwise rank loss。它不做全局相关性拟合，而是在 batch 内寻找相似 treatment/control 样本对，用局部顺序约束推动正 uplift 证据排在负证据前面。这个模式更接近 Learning-to-Rank 的 pairwise 思路，但依赖 batch 内有效 pair 的数量和匹配质量。

|                             |                              |             |         |          |          |                      |
| --------------------------- | ---------------------------- | ----------- | ------- | -------- | -------- | -------------------- |
| 实验                          | 方法                           | Call MTAUCC | Random  | Avg AUCC | Avg Qini | 结论                   |
| CFR matched pairwise only   | CFR + matched-IPW pairwise   | 0.60117     | 0.42947 | 0.3537   | 0.1807   | 较 CFR baseline 只小幅提升 |
| DRCFR matched pairwise only | DRCFR + matched-IPW pairwise | 0.52980     | 0.42947 | 0.3427   | 0.1738   | Call MTAUCC 反而下降     |

结论：pairwise 的目标形式合理，但 mini-batch 内有效 pair 稀疏、匹配噪声和 IPW 方差会让梯度偏弱。因此它适合作为辅助排序项，不适合作为单独主 loss。

# 4.3 Corr / PU-Corr rank：AUCC 拉升最强，但 treatment-ratio 风险变大

这一组的目的，是解决 factual baseline 不优化排序、pairwise alone 梯度弱的问题。做法是让 uplift score 与 IPW/PU pseudo label 做相关性对齐。关键改进是把 `y` 改成 `(2y-1)`，避免 `y=0` pseudo 全部坍缩为 0。

> 架构模式注释：这一组是“强 rank 单阶段训练”。模型仍是 CFR/DRCFR 多档位响应结构，但训练时直接把 uplift score 与 IPW/PU pseudo label 做全局相关性对齐，并辅以 matched pairwise。它的优势是 rank 梯度密集、AUCC 提升最明显；风险是 rank loss 会放大 treatment assignment artifact，尤其在深折扣和高频样本上容易把 selection bias 当作 uplift 信号。

|                               |                                    |             |         |          |          |                              |
| ----------------------------- | ---------------------------------- | ----------- | ------- | -------- | -------- | ---------------------------- |
| 实验                            | 方法                                 | Call MTAUCC | Random  | Avg AUCC | Avg Qini | 结论                           |
| CFR PU-Corr `(2y-1)` + pair   | CFR + PU-Corr + matched pairwise   | 0.83638     | 0.42947 | 0.5553   | 0.2772   | 明显高于 baseline，是 rank 主体有效的证据 |
| DRCFR PU-Corr `(2y-1)` + pair | DRCFR + PU-Corr + matched pairwise | 0.75836     | 0.42947 | 0.5790   | 0.2934   | Avg 指标不差，但 Call 低于 CFR       |
| CFR IPW corr + matched pair   | CFR + IPW corr + matched pairwise  | 1.01302     | 0.42947 | 0.7287   | 0.2985   | 离线 AUCC 极高，但 ratio 风险也最大     |

结论：corr / PU-Corr 是 AUCC 拉升最强的方法，但强 rank loss 很容易学习 treatment-side artifact。它证明“排序目标有用”，但不能单独作为推荐方案。

# 4.4 Clean pid 与频次加权：数据修正有帮助，但不能粗暴降权

这一组的目的，是处理 EDA 中发现的极端 pid、高频用户行、用户日重复曝光问题。做法包括删除极端 pid，或用 `sqrt(user-day)` 对同用户同天高频样本降权。

> 架构模式注释：这一组不是优先改模型结构，而是改训练样本的有效权重/样本集合。Clean pid 通过删除训练集中的极端重复曝光用户，减少少数异常 pid 对 rank loss 的污染；sqrt(user-day) weight 则把同用户同天多行样本按频次降权，试图降低订单行粒度训练对高频用户的过度加权。

|                                   |                               |             |         |          |          |                               |
| --------------------------------- | ----------------------------- | ----------- | ------- | -------- | -------- | ----------------------------- |
| 实验                                | 方法                            | Call MTAUCC | Random  | Avg AUCC | Avg Qini | 结论                            |
| Clean pid pure CFR baseline       | 只删除极端 pid，不加 rank loss        | 0.56653     | 0.42947 | 0.3226   | 0.1813   | 清洗本身不会自动提升排序                  |
| Clean pid PU-Corr + pair          | 删除极端 pid + PU-Corr + pairwise | 0.86604     | 0.42947 | 0.6096   | 0.2937   | 比 raw PU-Corr 更强，但仍有 ratio 风险 |
| Clean pid + sqrt(user-day) weight | 高频用户日样本按 降权                   | 0.75615     | 0.33570 | 0.5720   | 0.3173   | 统一降权压掉部分有效排序信号                |

结论：极端 pid 清洗方向是合理的，但频次加权不能一刀切。高频样本中既有污染，也可能有真实可排序信号；统一降权会同时压掉二者。

# 4.5 Score calibration E 组：score 空间处理有效，但仍不能替代 ratio-safe 主线

这一组检查 rank loss 是否受 score 均值漂移、尺度差异和长尾极值影响。做法是在 rank loss 内部对 uplift score 做 center / zscore / zscore+tanh，不改变 factual prediction，只改变 rank loss 看到的分数空间。

结论是：E3 是 E 组最强，说明 `zscore+tanh` calibration 对 AUCC 有效；但 E 组本质仍是强 rank 单阶段训练，QINI treatment-ratio 风险仍高于 H2，因此它是 AUCC 上界/score calibration 证据，不是最终推荐。

> 架构模式注释：这一组是“rank score 空间校准”。模型主体和 rank 目标不变，只在 rank loss 看到 score 之前做 center、zscore 或 zscore+tanh。它不改变 factual prediction，也不改变线上最终概率输出，只改变训练时排序梯度的尺度、中心和长尾形态，用来判断 AUCC 高低是否被 score 分布形态限制。

|                |                    |             |         |          |          |                                         |
| -------------- | ------------------ | ----------- | ------- | -------- | -------- | --------------------------------------- |
| 实验             | 方法                 | Call MTAUCC | Random  | Avg AUCC | Avg Qini | 结论                                      |
| E1 center      | rank score 去均值     | 0.89184     | 0.42947 | 0.6213   | 0.2965   | 均值校正确实增强 rank 训练，但不如 E3                 |
| E2 zscore      | 去均值 + 除标准差         | 0.82546     | 0.42947 | 0.5301   | 0.2716   | 更稳但排序强度下降明显                             |
| E3 zscore+tanh | zscore 后 tanh 压缩长尾 | 0.89449     | 0.42947 | 0.6470   | 0.3034   | E 组 AUCC 最高，是 score calibration 有效的核心证据 |

取舍：E3 说明 `zscore+tanh` 是有效的 score-space 校准方式，因此 H2 继承了它；但 E3 本身不是最终推荐，因为它是强 rank 单阶段模型，虽然 Call MTAUCC 达到 0.89449、Avg AUCC 达到 0.6470，但 treatment-ratio 仍存在深折扣侧下凸风险。H2 的目标不是追求最高离线 AUCC，而是在 ratio 相对可信的候选中选择更稳的折中点。

# 4.6 TwoStage soft-unfreeze / anneal：AUCC 能追回，但 ratio 风险回潮

这一组从 TwoStage 思路出发，尝试通过更强 rank 权重和 soft-unfreeze 恢复 AUCC。结论是：soft-unfreeze 确实能显著提高 AUCC，但越强的 rank 越容易把 ratio 风险带回来；因此它证明“追回 AUCC 有路径”，但不能直接替代 H2。

> 架构模式注释：这一组是“TwoStage 后的 AUCC 追回实验”。它继承 anchor 思路，但在第二阶段加大 corr/pair 权重、延长或增强 soft-unfreeze，让 shared bottom 获得更多 rank 梯度。它用来测试：在保留 anchor 的情况下，放开多少底座可以追回 AUCC；同时也观察 rank 强度增加后 treatment-ratio 风险何时回潮。

|                  |                                       |             |         |          |          |                             |
| ---------------- | ------------------------------------- | ----------- | ------- | -------- | -------- | --------------------------- |
| 实验               | 方法                                    | Call MTAUCC | Random  | Avg AUCC | Avg Qini | 结论                          |
| C1 weak          | TwoStage anneal，corr=0.01, pair=0.002 | 0.66193     | 0.40557 | 0.4030   | 0.2350   | 比 anchor 略升，仍偏保守            |
| C2 strong        | TwoStage anneal，corr=0.03, pair=0.005 | 0.73270     | 0.40557 | 0.4976   | 0.2858   | AUCC 明显追回，但 ratio 风险上升      |
| C2 stronger      | TwoStage anneal，corr=0.05, pair=0.005 | 0.83665     | 0.40557 | 0.6201   | 0.3410   | 指标高，但已接近强 rank 风险区          |
| B1 soft-unfreeze | soft-unfreeze，corr=0.03, pair=0.005   | 0.77800     | 0.40557 | 0.5445   | 0.2708   | shared bottom 放开后 AUCC 继续上升 |
| B2 soft-unfreeze | soft-unfreeze，corr=0.05, pair=0.005   | 0.89464     | 0.40557 | 0.6870   | 0.3243   | AUCC 很强，但不作为 ratio-safe 主线  |
| B3 soft-unfreeze | soft-unfreeze，corr=0.03, pair=0.010   | 0.77777     | 0.40557 | 0.5430   | 0.2713   | 增加 pair 未明显超过 B1            |

取舍：B2/C2 stronger 可以作为“AUCC 可追回”的证据，但它们不应替代 H2。H2 的定位是 ratio-safe 主线；B2/C2 stronger 的定位是上界/风险诊断。

# 4.7 G组：HeadRank：平稳 anchor 上加 rank，收益有限

这一组从 treatment-ratio 相对平的 anchor 出发，只调 headrank 的 corr/pair 权重，观察能否在不破坏 ratio 的前提下提高 AUCC。结论是：G1/G2/G3 的 Call MTAUCC 都在 0.63 左右，说明在几乎不动底座的情况下，head 层可追回的 AUCC 空间有限。

> 架构模式注释：这一组是“保守 HeadRank 微调”。它基本不动 shared bottom，只在 head 层附近加入较弱 rank loss，希望在 anchor 的稳定 ratio 基础上小幅提升 AUCC。这个模式最安全，但可训练自由度也最小，因此适合验证“只改 head 是否足够”，不适合作为强效果上界。

|     |                                         |             |         |          |          |                       |
| --- | --------------------------------------- | ----------- | ------- | -------- | -------- | --------------------- |
| 实验  | 方法                                      | Call MTAUCC | Random  | Avg AUCC | Avg Qini | 结论                    |
| G1  | samearch headrank，corr=0.01, pair=0.005 | 0.63211     | 0.40557 | 0.3876   | 0.2074   | ratio 相对稳，但 AUCC 提升有限 |
| G2  | samearch headrank，corr=0.02, pair=0.005 | 0.63362     | 0.40557 | 0.3880   | 0.2074   | 三者中 Call 最高，但提升极小     |
| G3  | samearch headrank，corr=0.03, pair=0.005 | 0.63267     | 0.40557 | 0.3883   | 0.2076   | 加大 corr 未带来稳定收益       |

取舍：G证明“完全保守地只动 head”很难把 AUCC 拉到 0.7+。它支持了 H2 的设计：不能只 hard-freeze，也不能完全放开 shared bottom，而要采用 progressive soft-unfreeze 和小学习率。

# 4.8 H2 Soft T2 Extended Epoch Check：延长训练不能解决 AUCC 偏低

这一组是在当前推荐主线 H2 soft T2 的基础上，只增加训练 epoch，检查“当前 H2 的 AUCC 不高是否只是因为训练还不充分”。实验结果显示，延长到 e8 后，Call MTAUCC 没有提升，反而从 0.65293 下降到 0.63490；Avg AUCC 也从 0.3769 小幅下降到 0.3745。Avg Qini 从 0.1728 略升到 0.1740，但提升很小，不足以抵消主指标下滑。因此，H2 的推荐点仍然是原来的 soft T2 短训练版本，而不是 extended epoch 版本。

> 架构模式注释：这一组不是新架构，而是 H2 的训练时长诊断。模型结构、rank 权重、temperature、soft-unfreeze 方式都保持不变，只把训练从原 H2 的 3 epoch 继续延长到 8 epoch。它用来回答一个很具体的问题：H2 的 AUCC 偏保守，是因为 rank 训练没跑够，还是因为这个 ratio-safe 约束本身限制了排序自由度。

|                        |                                       |             |         |          |          |          |               |                                  |
| ---------------------- | ------------------------------------- | ----------- | ------- | -------- | -------- | -------- | ------------- | -------------------------------- |
| 实验                     | 方法                                    | Call MTAUCC | Random  | Avg AUCC | Avg Qini | Avg Dini | Avg ATE Error | 结论                               |
| H2 soft T2             | progressive soft-unfreeze，T=2，epoch=3 | 0.65293     | 0.42947 | 0.3769   | 0.1728   | 0.1907   | 0.0103        | 当前主线：ratio 相对平候选中 Call MTAUCC 最高 |
| H2 soft T2 extended e8 | 保持 H2 配置，继续训练到 epoch=8                | 0.63490     | 0.42947 | 0.3745   | 0.1740   | 0.1912   | 0.0046        | 主指标下降，说明单纯延长训练不能追回 AUCC          |

分 treatment 看，extended e8 的 AUCC 并没有呈现系统性增强：

|   |   |   |   |   |
|---|---|---|---|---|
|Discount|AUCC|Qini|Dini|ATE Error|
|97|0.18388|0.04227|0.11095|0.00583|
|94|0.14279|0.00467|0.03499|0.00771|
|91|0.32271|0.12451|0.15183|0.00148|
|88|0.38445|0.18121|0.19386|0.00190|
|85|0.53662|0.28047|0.25745|0.00425|
|82|0.41132|0.21961|0.23091|0.00016|
|79|0.36929|0.17756|0.20610|0.00140|
|76|0.42951|0.22146|0.23658|0.00585|
|73|0.59015|0.32395|0.29834|0.01322|

训练过程的 validation 指标也支持这个判断：从 epoch 3 到 epoch 7，`val_auc` 只从约 0.75965 小幅上升到 0.75996，`val/uplift_rank` 基本维持在 0.98 左右，说明继续训练主要是在非常小的局部范围内微调 response prediction，并没有显著增强 uplift ranking。更关键的是，最终 report 的 Call MTAUCC 反而下降，说明 extended epoch 没有解决 H2 的核心瓶颈。

取舍：这个实验排除了“多跑几轮就能把 H2 拉上去”的简单解释。H2 的 AUCC 偏保守，更可能来自架构约束本身：为了保护 treatment-ratio，H2 限制了 rank loss 对 shared bottom 的破坏性更新，也限制了强 rank signal 的表达空间。因此后续如果要提高 AUCC，方向不应是简单延长 epoch，而应该是更精细地释放排序自由度，例如 gated residual、局部 soft-unfreeze、或在低风险样本上增强 rank 权重。
