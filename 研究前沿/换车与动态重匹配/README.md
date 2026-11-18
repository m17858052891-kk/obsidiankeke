---
type: 索引
status: 维护中
created: 2026-11-18
---

# 换车与动态重匹配

业务关联与补充查询入口。每日通用模型检索见 [[研究前沿/推荐模型检索地图|推荐模型检索地图]]；本页用于解释业务迁移和选择后续验证。

应答之后何时寻找替代司机、怎样比较保留原车与换车的预期收益，如何处理重新匹配中的机会成本？

按父单—子单还原决策和后果。考虑原司机占用、已空驶、重复换车、接驾时长与司乘取消，报告整个候选人群的净效果。

## 可直接执行的检索组合

公共短查询逐条执行，覆盖直接问题和跨领域机制。

- `"ride-hailing" reassignment rematching`
- `"dynamic matching" recourse switching cost`
- `"ride-hailing" pickup time cancellation prediction`
- `"online matching" commitment reoptimization`
- `"counterfactual prediction" treatment switching`
- `"optimal stopping" switching costs`

## 论文准入与第一步验证

主读依据是创新模块、机制和可信证据，保留医疗、推荐、广告、运筹和机器学习中的可迁移工作。记录能改以上哪个动作或模型、原文证据位置、第一步对照的样本与基线、只改的因素、主指标与失败判据。已有线上收益和现成业务数据仅用于适配说明。原文结果与本地未运行假设分别标注。

本地业务定位参考 [[花小猪/新人串讲：乘客侧链路与平台联合决策V3-V4（整理版）|乘客侧链路材料]]。资料记述按日期区分讨论稿、方案和上线结果。

## 资料索引

[[研究前沿/换车与动态重匹配/01-论文原文与精读/README|论文原文与精读]] · [[研究前沿/换车与动态重匹配/02-可复用方法卡/README|可复用方法卡]] · [[研究前沿/换车与动态重匹配/03-实验假设与结果/README|实验假设与结果]]
