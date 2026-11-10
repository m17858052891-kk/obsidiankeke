---
title: "绝对 PK 胜出率"
type: metric
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/absolute-pk-win-rate.md"
related:
  - "index.md"
  - "pk-win-rate.md"
  - "fulfillment-rate.md"
---

# 绝对 PK 胜出率

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 指标含义

- 绝对 PK 胜出率衡量 both 举手竞争场景下的胜出比例。
- 这是商家维度指标，用于观察多司机举手参与 PK 后的胜出效果。

## 计算契约（来源口径，待复核）

```text
绝对 PK 胜出率 = both 举手胜出数 / both 举手参与 PK 数
```

- 分子：both 举手胜出数。
- 分母：both 举手参与 PK 数。
- 单位：比例。

## 诊断用途

- 评估 both 举手竞争场景下的 PK 胜出效果。
- 对比不同城市、时段、商家或策略版本下多司机竞争的胜出质量。

## 使用限制与待确认

- 分母限定 both 举手参与 PK 数，不是全部参与 PK 数。
- 与 PK 胜出率相比，绝对 PK 胜出率更聚焦多司机举手竞争场景。
- SQL、看板字段、过滤条件、统计时间窗及异常值处理尚未获得可核验来源，待补充。

## 来源

- [absolute-pk-win-rate.md](../../raw/department-baseline/directions/trading-efficiency/metric/absolute-pk-win-rate.md)（快照 commit `a27b537`）

## 关联页面

- [index](index.md)
- [pk-win-rate](pk-win-rate.md)
- [fulfillment-rate](fulfillment-rate.md)
