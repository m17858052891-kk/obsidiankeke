---
title: "平均接驾距离"
type: metric
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/average-pickup-distance.md"
related:
  - "index.md"
  - "avg-pickup-duration.md"
  - "avg-etp.md"
---

# 平均接驾距离

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 指标含义

- 平均接驾距离衡量司机应答时到乘客发单地的预估路面距离。
- 这是司乘共同体验指标：司机承担接驾成本，乘客承担等待和取消风险。

## 计算契约（来源口径，待复核）

```text
平均接驾距离 = 预估接驾距离 / 应答量（含改派）
```

- 分子：司机应单时到乘客发单地的预估路面距离汇总。
- 分母：含改派的应答订单数。
- 单位：建议统一为米；若使用 km，必须在图表和文档中标注。

## 诊断用途

- 评估 PK、分单召回、匹配联合决策是否降低接驾负担。
- 监控接驾距离目标和城市/时段差异。

## 使用限制与待确认

- 本指标是预估接驾距离，不是真实行驶距离。
- 接驾距离目标 1650m 需要确认是否与本指标同口径。
- SQL、看板字段、过滤条件、统计时间窗及异常值处理尚未获得可核验来源，待补充。

## 来源

- [average-pickup-distance.md](../../raw/department-baseline/directions/trading-efficiency/metric/average-pickup-distance.md)（快照 commit `a27b537`）

## 关联页面

- [index](index.md)
- [avg-pickup-duration](avg-pickup-duration.md)
- [avg-etp](avg-etp.md)
