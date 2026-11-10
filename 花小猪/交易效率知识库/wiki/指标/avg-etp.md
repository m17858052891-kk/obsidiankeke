---
title: "单均 ETP"
type: metric
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/avg-etp.md"
related:
  - "index.md"
  - "avg-call-to-charge-duration.md"
  - "avg-pickup-duration.md"
---

# 单均 ETP

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 指标含义

- ETP 是 Estimated Time of Pickup，在本方向口径中用于衡量乘客从发单到司机点击到达上车点的平均等待时长。
- 这是乘客视角指标，表达乘客被等待接驾占用的时间。

## 计算契约（来源口径，待复核）

```text
单均 ETP = 呼叫-司机到达上车点时长 / 到达样本量
```

- 呼叫-司机到达上车点时长：同一次原始发单中，司机点击到达上车点时间 - 第一次呼叫时间。
- 分母：司机到达上车点的样本量；若看板使用应答量或完单量，需要以看板为准。
- 单位：建议统一为分钟。

## 口径逻辑

- 起点是乘客第一次呼叫时间。
- 终点是司机点击到达上车点时间。
- 若计算链路按“首次应答时间 + 接驾时长”还原到达时间，需要保证接驾时长与到达事件一致，避免混入司机视角修正接驾时长。

## 诊断用途

- 评估 PK、匹配和召回策略对乘客等待司机到达的影响。
- 与呼叫-计费时长一起区分“司机到达前等待”和“到达后到开始计费之间的等待”。

## 使用限制与待确认

- 不要把单均 ETP 写成预估接驾时长字段的简单平均；本次修正按司机点击到达上车点时间理解。
- 与单均接驾时长不同，本指标是乘客从呼叫开始的等待链路。
- SQL、看板字段、过滤条件、统计时间窗及异常值处理尚未获得可核验来源，待补充。
- 不同时间指标的样本、分母和端点不同，未经同样本对齐，不能直接用指标均值相加减还原链路。

## 来源

- [avg-etp.md](../../raw/department-baseline/directions/trading-efficiency/metric/avg-etp.md)（快照 commit `a27b537`）

## 关联页面

- [index](index.md)
- [avg-call-to-charge-duration](avg-call-to-charge-duration.md)
- [avg-pickup-duration](avg-pickup-duration.md)
