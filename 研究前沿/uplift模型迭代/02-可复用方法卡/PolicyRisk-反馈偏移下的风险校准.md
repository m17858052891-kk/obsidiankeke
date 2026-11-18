---
type: "方法"
topics: ["研究前沿","uplift模型迭代"]
status: "维护中"
created: "2026-11-12"
paper_id: "arxiv:2611.13163"
version: "v1"
module_id: "arxiv:2611.13163:method"
local_validation: "未验证"
---

# 反馈偏移下的风险校准

用历轮分流记录为下一轮选策略。每轮要知道实际使用的策略、候选阈值、观察损失和奖励，并能估计候选策略会怎样改变下一批样本的分布。

## 以风险上界筛选阈值

对每个候选策略估计置换权重，用 Sinkhorn 近似求解。在加权平均损失上加高斯 bootstrap 分位数修正，再与容许风险比较。用同一尺度记录入选策略的奖励，便于看清风险控制的代价。[风险估计式](https://arxiv.org/html/2611.13163v1#S3.E3) · [作者的置换权重实现](https://github.com/guoyihonggyh/High-Probability-Risk-Control/blob/601369f3e9809c8420bba12ae25e6711be448bec/permutation_weight.py)

## 分轮检查有多少次超限

按时间先选阈值，再用后续轮次评估。依次比较不加权、只加权、加权再加分位修正，记录超限频率、奖励和有效样本量。若候选策略缺乏重叠、密度比不可信或上界反复偏低，论文的渐近保证不足以支持使用。

[[研究前沿/uplift模型迭代/01-论文原文与精读/PolicyRisk/精读#对照、结果和限制|固定策略 QA 与反馈偏移两组证据]] · [原文图 2](https://arxiv.org/html/2611.13163v1#S5.F2) · [[研究前沿/uplift模型迭代/03-实验假设与结果/PolicyRisk-分流政策随历史迭代时，加权风险上界能否减少不达标轮次|本地逐轮回放，未运行]]。
