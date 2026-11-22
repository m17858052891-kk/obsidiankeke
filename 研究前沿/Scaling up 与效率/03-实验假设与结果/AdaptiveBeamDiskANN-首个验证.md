---
type: "实验假设"
topics: ["Scaling up 与效率"]
status: "维护中"
created: "2026-11-22"
experiment_status: "未运行"
experiment_id: "arxiv:2611.26609:first-test"
---

# AdaptiveBeamDiskANN｜首个验证

[[研究前沿/Scaling up 与效率/01-论文原文与精读/AdaptiveBeamDiskANN/精读|精读]] · [[研究前沿/Scaling up 与效率/02-可复用方法卡/AdaptiveBeamDiskANN-核心机制与验证|采用模块]]

## 假设与对照

预分单候选检索若有ANN慢路径，固定索引、流量和候选合法性，在时间外流量比恒定预算、早停和自适应 pilot；加每请求硬上限，查 P99.9、截断失败和弱城召回。

失败判据：平均好而尾预算或候选覆盖出界则拒绝。

固定比较窗口、候选与可用特征口径；数据集 ID、预算、种子、误差区间和晋级阈值待确认。

## 实际结果

未运行。仅登记可验证的假设；原文结果见来源，不作本地结果。
