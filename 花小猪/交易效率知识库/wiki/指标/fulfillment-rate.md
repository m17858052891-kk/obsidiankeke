---
title: "履约率"
type: metric
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/fulfillment-rate.md"
related:
  - "index.md"
  - "pk-win-rate.md"
  - "passenger-cancel-after-answer-rate.md"
---

# 履约率

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 指标含义

- 履约率衡量 PK 获胜订单中，后续稳定履约的比例。
- 履约定义：这一单在应答后没有司机取消或乘客取消。
- 这是商家维度指标，用于评估 PK 获胜订单的真实履约质量。

## 计算契约（来源口径，待复核）

```text
履约率 = 履约数 / PK 获胜数
```

- 分子：履约数，即 PK 获胜后应答，且应答后没有司机取消或乘客取消的订单数。
- 分母：PK 获胜数。
- 单位：比例。

## 诊断用途

- 评估 PK 获胜订单是否真正稳定履约。
- 作为商家维度的结果质量指标，辅助判断 PK 胜出是否带来有效订单。

## 使用限制与待确认

- 履约不是简单完单数口径，而是应答后没有司机或乘客取消。
- 分母限定为 PK 获胜数，不能混用参与 PK 数或播单数。
- SQL、看板字段、过滤条件、统计时间窗及异常值处理尚未获得可核验来源，待补充。

## 来源

- [fulfillment-rate.md](../../raw/department-baseline/directions/trading-efficiency/metric/fulfillment-rate.md)（快照 commit `a27b537`）

## 关联页面

- [index](index.md)
- [pk-win-rate](pk-win-rate.md)
- [passenger-cancel-after-answer-rate](passenger-cancel-after-answer-rate.md)
