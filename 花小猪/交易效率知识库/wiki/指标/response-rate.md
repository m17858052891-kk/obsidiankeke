---
title: "应答率"
type: metric
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/response-rate.md"
  - "cooper:sheet:2207015802275"
related:
  - "index.md"
  - "driver-cancel-after-answer-rate-with-reassign.md"
  - "passenger-cancel-after-answer-rate.md"
---

# 应答率

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 指标含义

- 应答率衡量小猪端竞争呼叫中被司机应答的比例。
- 这是交易链路承接能力指标，用于观察召回、分单和派单策略是否让乘客呼叫被有效响应。

## 计算契约（来源口径，待复核）

```text
应答率 = 应答量 / 竞争呼叫
```

- 分子：剔除改派后的应答订单数。
- 分母：小猪端竞争呼叫订单数。
- 单位：比例。

## 诊断用途

- 评估召回、分单、派单模式调整对交易链路承接的影响。
- 监控城市、时段、策略实验组之间的响应能力差异。

## 2026 年 1 月平台观测样例

表格按日记录 2026-01-01 至 2026-01-31 的平台供需应答率，月内算术均值约为 77.61%，单日点值范围约为 59%—81%。这是一段描述性线上观测，不是实验结论；表格没有给出每日样本量、统计口径版本或异常解释，因此不能据此归因策略效果，也不应把月均值当作长期基线。

## 使用限制与待确认

- 当前口径使用剔除改派后的应答量作分子；若看板使用含改派应答量，应在复盘中显式说明。
- 不能只看应答率提升，还要同步看取消率、完单和履约率。
- SQL、看板字段、过滤条件、统计时间窗及异常值处理尚未获得可核验来源，待补充。
- 1 月表格仅有日期与应答率，缺分子分母、置信区间、城市/供需切片以及数据刷新说明。

## 来源

- [response-rate.md](../../raw/department-baseline/directions/trading-efficiency/metric/response-rate.md)（快照 commit `a27b537`）
- `cooper:sheet:2207015802275`：`工作表1!A1:Z100` 只读核验，实际有效至第 34 行（含说明、表头与 Avg）。

## 关联页面

- [index](index.md)
- [driver-cancel-after-answer-rate-with-reassign](driver-cancel-after-answer-rate-with-reassign.md)
- [passenger-cancel-after-answer-rate](passenger-cancel-after-answer-rate.md)
