---
title: "单均应答时长"
type: metric
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/avg-answer-duration.md"
related:
  - "index.md"
  - "response-rate.md"
  - "avg-call-to-charge-duration.md"
---

# 单均应答时长

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 指标含义

- 单均应答时长衡量乘客发单后，到第一次被司机应答前等待的平均时间。
- 这是乘客视角指标，表达乘客等待司机响应的时间占用。

## 计算契约（来源口径，待复核）

```text
单均应答时长 = 呼叫-首次应答时长 / 应答量（不含改派）
```

- 呼叫-首次应答时长：同一次原始发单中，第一次应答时间 - 第一次呼叫时间。
- 分母：不含改派的应答量。
- 单位：建议统一为秒或分钟。

## 口径逻辑

- 先按原始发单 ID 归并改派链路。
- 取本次发单的第一次呼叫时间。
- 取本次发单的第一次应答时间。
- 过滤未应答换车子单，避免虚增无效等待。

## 诊断用途

- 诊断召回和分单链路是否让乘客过久等待首个司机响应。
- 评估策略对乘客初始等待体验的影响。

## 使用限制与待确认

- 乘客视角指标，不等于司机接驾时长。
- 分母是否含改派需要与看板统一；当前建议使用不含改派应答量。
- SQL、看板字段、过滤条件、统计时间窗及异常值处理尚未获得可核验来源，待补充。
- 不同时间指标的样本、分母和端点不同，未经同样本对齐，不能直接用指标均值相加减还原链路。

## 来源

- [avg-answer-duration.md](../../raw/department-baseline/directions/trading-efficiency/metric/avg-answer-duration.md)（快照 commit `a27b537`）

## 关联页面

- [index](index.md)
- [response-rate](response-rate.md)
- [avg-call-to-charge-duration](avg-call-to-charge-duration.md)
