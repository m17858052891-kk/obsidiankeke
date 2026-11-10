---
title: "PK 胜出率"
type: metric
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/pk-win-rate.md"
related:
  - "index.md"
  - "absolute-pk-win-rate.md"
  - "fulfillment-rate.md"
---

# PK 胜出率

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 指标含义

- PK 胜出率衡量参与 PK 的样本中最终产生胜出订单的比例。
- 这是商家维度指标，用于评估参与 PK 后的胜出转化。

## 计算契约（来源口径，待复核）

```text
PK 胜出率 = 胜出订单数 / 参与 PK 数
```

- 分子：胜出订单数。
- 分母：参与 PK 数。
- 单位：比例。

## 诊断用途

- 评估参与 PK 后是否形成胜出订单。
- 结合履约率判断胜出订单是否真正稳定履约。

## 使用限制与待确认

- 分母为参与 PK 数。
- only 举手直接获胜，both 举手进入多司机竞争，二者都会影响 PK 胜出率。
- SQL、看板字段、过滤条件、统计时间窗及异常值处理尚未获得可核验来源，待补充。

## 来源

- [pk-win-rate.md](../../raw/department-baseline/directions/trading-efficiency/metric/pk-win-rate.md)（快照 commit `a27b537`）

## 关联页面

- [index](index.md)
- [absolute-pk-win-rate](absolute-pk-win-rate.md)
- [fulfillment-rate](fulfillment-rate.md)
