---
title: "应答后司机取消率（含改派）"
type: metric
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/driver-cancel-after-answer-rate-with-reassign.md"
related:
  - "index.md"
  - "response-rate.md"
  - "passenger-cancel-after-answer-rate.md"
---

# 应答后司机取消率（含改派）

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 指标含义

- 应答后司机取消率（含改派）衡量订单被司机应答后，由司机取消或司机取消后触发改派的比例。
- 这是司机侧交易稳定性指标，用于观察派单质量、司机接单意愿和改派风险。

## 计算契约（来源口径，待复核）

```text
应答后司机取消率（含改派） = 应答后司机取消量（含改派） / 应答量（含改派）
```

- 分子：应答后司机取消订单数，包含司机取消后触发改派的订单。
- 分母：含改派的应答订单数。
- 单位：比例。

## 诊断用途

- 评估分单、匹配、连环派、PK 调整对司机接单后稳定性的影响。
- 识别策略是否把低质量订单推给司机，导致取消或改派增加。

## 使用限制与待确认

- 指标名称中“含改派”必须保留；不含改派版本需另行命名。
- 需要与司机有责取消、诱导取消等交易生态指标区分。
- SQL、看板字段、过滤条件、统计时间窗及异常值处理尚未获得可核验来源，待补充。

## 来源

- [driver-cancel-after-answer-rate-with-reassign.md](../../raw/department-baseline/directions/trading-efficiency/metric/driver-cancel-after-answer-rate-with-reassign.md)（快照 commit `a27b537`）

## 关联页面

- [index](index.md)
- [response-rate](response-rate.md)
- [passenger-cancel-after-answer-rate](passenger-cancel-after-answer-rate.md)
