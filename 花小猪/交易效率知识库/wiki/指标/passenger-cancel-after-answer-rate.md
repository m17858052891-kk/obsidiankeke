---
title: "应答后乘客取消率"
type: metric
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/passenger-cancel-after-answer-rate.md"
related:
  - "index.md"
  - "response-rate.md"
  - "avg-answer-duration.md"
  - "average-pickup-distance.md"
---

# 应答后乘客取消率

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 指标含义

- 应答后乘客取消率衡量订单被司机应答后，最终由乘客取消的比例。
- 这是乘客体验指标，常用于判断等待过长、接驾过远、沟通体验差等问题是否导致取消。

## 计算契约（来源口径，待复核）

```text
应答后乘客取消率 = 应答后乘客取消量 / 应答量（含改派）
```

- 分子：剔除改派后的应答后乘客取消订单数。
- 分母：含改派的应答订单数。
- 单位：比例。

## 诊断用途

- 评估 PK、分单、乘客交易策略对乘客取消的影响。
- 定位远接驾、长等待、换车等体验问题。

## 使用限制与待确认

- 当前是混合口径：分子不含改派，分母含改派；对外使用前需确认看板口径是否一致。
- 与司机取消率、客服取消率、完单率一起看，避免把取消结构变化误判为总体验改善。
- SQL、看板字段、过滤条件、统计时间窗及异常值处理尚未获得可核验来源，待补充。

## 来源

- [passenger-cancel-after-answer-rate.md](../../raw/department-baseline/directions/trading-efficiency/metric/passenger-cancel-after-answer-rate.md)（快照 commit `a27b537`）

## 关联页面

- [index](index.md)
- [response-rate](response-rate.md)
- [avg-answer-duration](avg-answer-duration.md)
- [average-pickup-distance](average-pickup-distance.md)
