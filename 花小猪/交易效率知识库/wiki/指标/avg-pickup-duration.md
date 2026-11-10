---
title: "单均接驾时长"
type: metric
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/avg-pickup-duration.md"
related:
  - "index.md"
  - "charge-duration-share.md"
  - "average-pickup-distance.md"
---

# 单均接驾时长

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 指标含义

- 单均接驾时长衡量司机从应答订单到到达上车点或取消前，被接驾过程占用的平均时间。
- 这是司机视角指标，表达司机被接驾阶段占用的时间，不是乘客等待总时长。

## 计算契约（来源口径，待复核）

```text
单均接驾时长 = 修正后接驾时间 / 应答订单量
```

- 分子：修正后接驾时间汇总。
- 分母：应答订单量，具体是否含改派需与看板口径一致。
- 单位：建议统一为分钟。

## 修正逻辑

| 场景 | 接驾时间计算 |
| --- | --- |
| 可控运力 + 连环派 | 用运力侧上下单关系识别上一单；完单时为本单开始计费时间 - 上一单完成时间；未完单且取消发生在上一单完成前记 0；未完单且取消发生在上一单完成后为本单取消时间 - 上一单完成时间。 |
| 可控运力 + 非连环派 | 完单时为开始计费时间 - 应答时间；未完单时为取消时间 - 应答时间。 |
| 非可控运力 + 连环派 | 完单时为开始计费时间 - 应答时间 - 上一单送驾 ETA；未完单时若取消前等待超过上一单送驾 ETA，则为取消时间 - 应答时间 - 上一单送驾 ETA，否则记 0。 |
| 非可控运力 + 非连环派 | 完单时为开始计费时间 - 应答时间；未完单时为取消时间 - 应答时间。 |

## 诊断用途

- 评估匹配、分单、连环派策略对司机时间成本的影响。
- 作为双边交易效率目标中司机效率侧的核心指标。

## 使用限制与待确认

- 不能直接用基础接驾时长覆盖所有场景，连环派必须扣除上一单送驾占用。
- 需按可控运力/非可控运力、连环派/非连环派拆分看。
- SQL、看板字段、过滤条件、统计时间窗及异常值处理尚未获得可核验来源，待补充。
- 不同时间指标的样本、分母和端点不同，未经同样本对齐，不能直接用指标均值相加减还原链路。

## 来源

- [avg-pickup-duration.md](../../raw/department-baseline/directions/trading-efficiency/metric/avg-pickup-duration.md)（快照 commit `a27b537`）

## 关联页面

- [index](index.md)
- [charge-duration-share](charge-duration-share.md)
- [average-pickup-distance](average-pickup-distance.md)
