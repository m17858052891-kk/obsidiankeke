# 模型迭代中最难的问题：Treatment Ratio 失衡

## 面试版结论

最难的问题不是把 AUCC 做高，而是发现强 rank loss 虽然能显著提高离线 AUCC，却可能把 treatment/control 的样本构成偏差一起排到头部，表现为 Qini treatment-ratio 异常。我们没有用“最高 AUCC”直接选模型，而是依次排查数据、降低异常样本影响、调整 score 空间、限制 Stage-2 自由度。最终选择 TwoStage progressive H2 Soft T2：先有稳定 anchor，再以小权重校准 Corr/Pairwise 和低学习率软解冻追回排序收益。

## 1. 问题如何被发现

纯 CFR factual baseline 能预测 observed-arm call，但 uplift 排序不足。加入 PU-Corr 后 AUCC 提升明显，说明原模型确实缺少直接排序监督；但 Qini 图的 treatment-ratio 在头部出现持续偏离，且强 rank 权重下风险更大。

这是一种典型的“主指标很高但因果诊断变差”的冲突：模型可能同时学到了真实 uplift 和 treatment-side selection artifact，后者包括分组特征泄漏、特定档位样本结构、极端 PID、同用户同日重复曝光或样本过滤后比例变化。

## 2. 采取过的尝试与取舍

| 尝试 | 出发点 | 观察到的结论 | 为什么不单独采用 |
| --- | --- | --- | --- |
| Factual CFR baseline | 建立稳定响应锚点 | ratio 相对可控，但 Call MTAUCC 较低（记录约 0.59046） | 没有直接优化 uplift 排序 |
| Pairwise alone | 用局部可比顺序改善 AUCC | 有小幅提升（CFR 记录约 0.60117） | 有效 pair 稀疏、匹配噪声大，梯度不足 |
| 强 PU-Corr / IPW Corr | 用稠密全局排序直接冲 AUCC | AUCC 上升最强；强 IPW Corr 记录可达约 1.01302 | ratio 风险最大，无法作为稳健主线 |
| 清理极端 PID | 降低异常重复曝光污染 | 清理后强 rank 仍可提升 | 清洗本身不等于排序优化，且不能替代结构约束 |
| user-day 频次降权 | 抑制高频用户支配训练 | 部分风险被压制 | 真实高价值信号也被一刀切压掉，Random/主指标受损 |
| 仅做 score calibration | 处理档位尺度和长尾 | zscore+tanh 对 AUCC 有帮助 | 强 rank 的 assignment artifact 仍在 |
| Stage 2 hard-freeze | 防 rank 污染 shared bottom | ratio 更稳 | 只动 head，AUCC 回升有限 |
| 强 soft-unfreeze | 恢复排序自由度 | B2/C2 stronger 等方案可取得更高 AUCC | rank 风险回潮，不能只以主指标选型 |
| 延长 H2 训练 | 检查是否仅是未收敛 | e8 的 Call MTAUCC 从约 0.65293 降至约 0.63490 | 训练更久不是瓶颈解法 |

## 3. 为什么最终不选择其他办法

**不选单纯强 Corr：** 它给出的是性能上界与“排序信号有效”的证据，却没有足够稳健性证据。选它等于用难以解释的人群结构风险交换单点离线指标。

**不选单纯 Pairwise：** 因果直觉更局部，但它依赖 batch 内正负样本、相似近邻和匹配质量，无法提供足够密集的全局学习信号。

**不选统一频次降权：** 高频样本既可能是污染，也可能反映真实可排序机会；统一压低会损失后者。应优先做 PID/曝光审计、分层评估与针对性权重。

**不选完全冻结：** 稳定但可训练自由度太小；完全解冻则让 noisy rank 梯度重写 Stage-1 表征。二者都不能取得合理平衡。

## 4. 最终方案：H2 Soft T2

1. Stage 1 仅训练 CFR factual/base objective，得到 response/uplift anchor；
2. Stage 2 保留 base loss，叠加按档校准后的 PU-Corr 与 matched pairwise；
3. 先冻结 embedding 与 shared bottom，只让 head 适应 rank；
4. 后续冻结 embedding、以 `0.01 × lr_head` 软解冻 shared bottom；
5. 采用 Corr=0.015、Pairwise=0.003、T=2；
6. 以 Call MTAUCC 为主目标，并要求 Qini treatment-ratio 相对平稳。

H2 Soft T2 的记录结果为 Call MTAUCC 0.65293、Avg AUCC 0.3769、Avg Qini 0.1728。它不是所有实验中 AUCC 的最高点，而是“ratio 相对平的候选中 Call MTAUCC 最高”的推荐点。

## 5. 从这个问题得到的原则

1. 因果排序的主指标与结构诊断必须同时看；
2. 强 surrogate loss 能提升离线数值，也会放大数据中所有相关模式；
3. 先稳 response anchor，再逐步释放 rank 自由度，通常优于一阶段全量联合训练；
4. 任何“ratio 变平”的办法都要检查是否以损失真实排序信号为代价；
5. 最终仍需要时间切分、多 seed 与线上随机实验来判定真实价值。
