---
type: "实验假设"
topics: ["模型自进化"]
status: "维护中"
created: "2026-11-21"
experiment_status: "未运行"
experiment_id: "arxiv:2611.26531:first-test"
---

# CostAwareFeatureOptimization｜首个验证

[[研究前沿/模型自进化/01-论文原文与精读/CostAwareFeatureOptimization/精读|精读]] · [[研究前沿/模型自进化/02-可复用方法卡/CostAwareFeatureOptimization-核心机制与验证|采用模块]]

## 假设与对照

预分单或升舱履约特征搜索；固定已合法可见字段、样本窗、主干、种子、搜索预算和线上上限，先比较现有配置、确定性体量搜索和同预算代理提议；另做相同每类数量的血缘成本剪枝。独立窗看 NE/LogLoss、校准、P99、实际管线成本。

失败判据：离线收益依赖种子或超过同等预算与服务上限，或成本未下降，则不晋级。

固定比较窗口、候选与可用特征口径；数据集 ID、预算、种子、误差区间和晋级阈值待确认。

## 实际结果

未运行。仅登记可验证的假设；原文结果见来源，不作本地结果。
