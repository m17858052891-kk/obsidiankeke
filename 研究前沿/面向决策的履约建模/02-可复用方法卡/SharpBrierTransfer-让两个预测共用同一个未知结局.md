---
type: "方法"
topics: ["研究前沿", "面向决策的履约建模"]
status: "维护中"
created: "2026-11-14"
paper_id: "arxiv:2610.09658"
version: "v4"
module_id: "SharpBrierTransfer-M1"
source_papers: ["arxiv:2610.09658"]
local_validation: "未运行"
---

# 让两个预测共用同一个未知结局

[[研究前沿/面向决策的履约建模/01-论文原文与精读/SharpBrierTransfer/精读|新场景的履约标签还没到，能先判断哪个模型更准吗？]]

输入源域带删失的事件时间、目标域协变量、冻结预测和预设漂移范围。输出风险差的可识别区间和含抽样误差的外包络。先推导对同一 q 的损失差，再逐人取极值；独立地任意选择两个 q 会过宽。使用作者包的无结果入口，冻结输出后再运行回顾性对照。

**效果证据与归因。** 表 2 中，从 NWTS-3 转到 NWTS-4 的 20 种配置里，共用同一个未知结局概率得到的界支持候选模型 4 次，两个风险各自求界再相减支持 1 次。 [[研究前沿/面向决策的履约建模/01-论文原文与精读/SharpBrierTransfer/精读|原文对照及限制]]

[[研究前沿/面向决策的履约建模/03-实验假设与结果/SharpBrierTransfer-延迟标签到齐后复核先前的模型排序|延迟标签到齐后复核先前的模型排序（未运行）]]

**实现入口。** 复现包 applications/rotterdam_temporal/02_outcome_free_evaluation.py 和 03_retrospective_contrast.py 分别处理盲态比较与后验核验。 [作者复现包](https://doi.org/10.5281/zenodo.24122902)
