---
title: "举手率"
type: metric
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/hand-raise-rate.md"
related:
  - "index.md"
  - "only-hand-raise-rate.md"
  - "both-hand-raise-rate.md"
---

# 举手率

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 指标含义

- 举手率衡量商家播单后，司机举手响应的比例。
- 这是商家维度指标，用于观察播单对司机响应意愿的牵引。

## 计算契约（来源口径，待复核）

```text
举手率 = 举手数 / 播单数
```

- 分子：举手数。
- 分母：播单数。
- 单位：比例。

## 诊断用途

- 评估商家播单后司机是否愿意响应。
- 对比不同城市、时段、商家或策略版本下的播单响应质量。

## 使用限制与待确认

- 举手数和播单数需保持同一统计粒度。
- 该指标是商家维度指标，不等同于订单最终应答率。
- SQL、看板字段、过滤条件、统计时间窗及异常值处理尚未获得可核验来源，待补充。
- 来源把 only/both 举手率称作整体举手率拆分，但两者分母为参与 PK 数，整体举手率分母为播单数。此处按 PK 竞争结构理解；不能直接相加还原整体举手率，需 owner 确认统计集合与去重粒度。

## 来源

- [hand-raise-rate.md](../../raw/department-baseline/directions/trading-efficiency/metric/hand-raise-rate.md)（快照 commit `a27b537`）

## 关联页面

- [index](index.md)
- [only-hand-raise-rate](only-hand-raise-rate.md)
- [both-hand-raise-rate](both-hand-raise-rate.md)
