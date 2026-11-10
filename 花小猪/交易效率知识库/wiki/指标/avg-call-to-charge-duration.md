---
title: "单均呼叫-计费时长"
type: metric
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/avg-call-to-charge-duration.md"
related:
  - "index.md"
  - "avg-answer-duration.md"
  - "avg-etp.md"
---

# 单均呼叫-计费时长

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 指标含义

- 单均呼叫-计费时长衡量乘客从发单到司机开始计费的真实平均等待时长。
- 这是乘客视角指标，终点是开始计费，不是司机点击到达上车点。

## 计算契约（来源口径，待复核）

```text
单均呼叫-计费时长 = 呼叫-计费时长 / 完单量
```

- 呼叫-计费时长：同一次原始发单中，首次开始计费时间 - 第一次呼叫时间。
- 分母：完单量。
- 单位：建议统一为分钟。

## 口径逻辑

- 按原始发单 ID 归并改派链路。
- 取第一次呼叫时间作为起点。
- 取完单链路中的首次开始计费时间作为终点。
- 只对最终产生开始计费时间的完单样本计算单均。

## 诊断用途

- 衡量乘客从发单到真正开始行程计费的完整等待链路。
- 用于体验留存归因和策略总效果评估。

## 使用限制与待确认

- 与单均 ETP 的差异在终点：本指标到开始计费，ETP 到司机点击到达上车点。
- 只能用完单样本计算，否则没有开始计费时间。
- SQL、看板字段、过滤条件、统计时间窗及异常值处理尚未获得可核验来源，待补充。
- 不同时间指标的样本、分母和端点不同，未经同样本对齐，不能直接用指标均值相加减还原链路。

## 来源

- [avg-call-to-charge-duration.md](../../raw/department-baseline/directions/trading-efficiency/metric/avg-call-to-charge-duration.md)（快照 commit `a27b537`）

## 关联页面

- [index](index.md)
- [avg-answer-duration](avg-answer-duration.md)
- [avg-etp](avg-etp.md)
