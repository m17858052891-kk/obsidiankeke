---
type: "实验假设"
topics: ["Scaling up 与效率"]
status: "维护中"
created: "2026-11-20"
experiment_status: "未运行"
experiment_id: "arxiv:2611.24214:first-test"
---

# Reliable-TFM-Scaling｜首个验证

[[研究前沿/Scaling up 与效率/01-论文原文与精读/Reliable-TFM-Scaling/精读|精读]] · [[研究前沿/Scaling up 与效率/02-可复用方法卡/Reliable-TFM-Scaling-核心机制与验证|采用模块]]

## 假设与对照

履约排序扩容：预先定三档同 FLOPs 小网格，分别调宽度和可见样本覆盖；先用单城近期和多城跨时段分别选型，再在未参与选择的最后时间段与一个更大预算点验证 LogLoss、校准、P99和外推误差。

失败判据：重新排序明显或留出大规模未超等预算基线，则不依赖该扩容处方。

固定比较窗口、候选与可用特征口径；数据集 ID、预算、种子、误差区间和晋级阈值待确认。

## 实际结果

未运行。仅登记可验证的假设；原文结果见来源，不作本地结果。
