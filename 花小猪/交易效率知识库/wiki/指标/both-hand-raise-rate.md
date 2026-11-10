---
title: "both 举手率"
type: metric
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/both-hand-raise-rate.md"
related:
  - "index.md"
  - "hand-raise-rate.md"
  - "only-hand-raise-rate.md"
---

# both 举手率

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 指标含义

- both 举手率衡量参与 PK 的样本中，有多于一个司机举手的占比。
- both 举手指有多于一个司机举手，需要在多个举手司机之间竞争。
- 这是商家维度指标，用于拆解 PK 参与样本中的多司机响应结构。

## 计算契约（来源口径，待复核）

```text
both 举手率 = 有多于一个司机举手的 PK 数 / 参与 PK 数
```

- 分子：有多于一个司机举手的 PK 数。
- 分母：参与 PK 数。
- 单位：比例。

## 诊断用途

- 诊断参与 PK 流量中多司机响应是否充分。
- 评估多司机举手场景下的 PK 竞争结构。

## 使用限制与待确认

- 分母为参与 PK 数，不是播单数。
- both 举手率和 only 举手率共同拆解参与 PK 的举手结构。
- SQL、看板字段、过滤条件、统计时间窗及异常值处理尚未获得可核验来源，待补充。
- 来源把 only/both 举手率称作整体举手率拆分，但两者分母为参与 PK 数，整体举手率分母为播单数。此处按 PK 竞争结构理解；不能直接相加还原整体举手率，需 owner 确认统计集合与去重粒度。

## 来源

- [both-hand-raise-rate.md](../../raw/department-baseline/directions/trading-efficiency/metric/both-hand-raise-rate.md)（快照 commit `a27b537`）

## 关联页面

- [index](index.md)
- [hand-raise-rate](hand-raise-rate.md)
- [only-hand-raise-rate](only-hand-raise-rate.md)
