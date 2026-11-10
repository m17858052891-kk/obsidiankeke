---
title: "送驾时长占比"
type: metric
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/charge-duration-share.md"
related:
  - "index.md"
  - "avg-pickup-duration.md"
---

# 送驾时长占比

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 指标含义

- 送驾时长占比衡量司机有效载客送驾时间在“接驾 + 送驾”时间中的占比。
- 这是司机视角指标，表达司机时间是否更多花在有效载客上。

## 计算契约（来源口径，待复核）

```text
送驾时长占比 = 送驾时间 / (修正后接驾时间 + 送驾时间)
```

- 送驾时间：开始计费时间到结束计费时间。
- 接驾时间：使用单均接驾时长中的修正后接驾时间。
- 单位：比例。

## 接驾时间修正

| 场景 | 接驾时间计算 |
| --- | --- |
| 可控运力 + 连环派 | 用上一单完成时间作为本单接驾起点；取消发生在上一单完成前记 0。 |
| 可控运力 + 非连环派 | 完单为开始计费时间 - 应答时间；未完单为取消时间 - 应答时间。 |
| 非可控运力 + 连环派 | 从应答到开始计费/取消的时间中扣除上一单送驾 ETA，扣后小于 0 记 0。 |
| 非可控运力 + 非连环派 | 完单为开始计费时间 - 应答时间；未完单为取消时间 - 应答时间。 |

## 诊断用途

- 判断策略是否提升司机有效载客效率，而不是只增加接驾或等待成本。
- 对比连环派、非连环派、可控/非可控运力的司机时间结构。

## 使用限制与待确认

- 不能用未修正的接驾时长计算送驾时长占比。
- 分母是司机时间口径，不是乘客等待口径。
- SQL、看板字段、过滤条件、统计时间窗及异常值处理尚未获得可核验来源，待补充。

## 来源

- [charge-duration-share.md](../../raw/department-baseline/directions/trading-efficiency/metric/charge-duration-share.md)（快照 commit `a27b537`）

## 关联页面

- [index](index.md)
- [avg-pickup-duration](avg-pickup-duration.md)
