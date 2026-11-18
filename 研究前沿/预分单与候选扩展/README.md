---
type: 索引
status: 维护中
created: 2026-11-18
---

# 预分单与候选扩展

业务关联与补充查询入口。每日通用模型检索见 [[研究前沿/推荐模型检索地图|推荐模型检索地图]]；本页用于解释业务迁移和选择后续验证。

在原呼叫尚未应答时，什么时候召回未勾选运力、给谁展示候选、怎样估计确认接受和最终完单？

原勾选运力先应答、乘客拒绝或超时、运力共享及候选占用都影响对照。以全部符合条件的呼叫为分母，分别检查触发、接受、应答、完单和总等待。

## 可直接执行的检索组合

公共短查询逐条执行，覆盖直接问题和跨领域机制。

- `"ride-hailing" proactive dispatch passenger acceptance`
- `"ride-hailing" alternative service offer acceptance`
- `"online matching" delayed commitment opportunity cost`
- `"assortment optimization" sequential choice outside option`
- `"optimal stopping" service offer abandonment`
- `"contextual bandit" offer timing delayed feedback`

## 论文准入与第一步验证

主读依据是创新模块、机制和可信证据，保留医疗、推荐、广告、运筹和机器学习中的可迁移工作。记录能改以上哪个动作或模型、原文证据位置、第一步对照的样本与基线、只改的因素、主指标与失败判据。已有线上收益和现成业务数据仅用于适配说明。原文结果与本地未运行假设分别标注。

本地业务定位参考 [[花小猪/新人串讲：乘客侧链路与平台联合决策V3-V4（整理版）|乘客侧链路材料]]。资料记述按日期区分讨论稿、方案和上线结果。

## 资料索引

[[研究前沿/预分单与候选扩展/01-论文原文与精读/README|论文原文与精读]] · [[研究前沿/预分单与候选扩展/02-可复用方法卡/README|可复用方法卡]] · [[研究前沿/预分单与候选扩展/03-实验假设与结果/README|实验假设与结果]]
