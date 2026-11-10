---
title: 应答率
type: metric
owner: "@tommywujian"
freshness: watch
status: active
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - cooper:2207271198956
related:
  - ./index.md
  - ./driver-cancel-after-answer-rate-with-reassign.md
  - ./passenger-cancel-after-answer-rate.md
---

# 应答率

## 定义

- 应答率衡量小猪端竞争呼叫中被司机应答的比例。
- 这是交易链路承接能力指标，用于观察召回、分单和派单策略是否让乘客呼叫被有效响应。

## 公式

```text
应答率 = 应答量 / 竞争呼叫
```

- 分子：剔除改派后的应答订单数。
- 分母：小猪端竞争呼叫订单数。
- 单位：比例。

## 关联指标

| 指标 | 关系 | 说明 |
| --- | --- | --- |
| 应答后乘客取消率 | 下游体验 | 应答变快或变多后需观察乘客取消是否改善 |
| 应答后司机取消率（含改派） | 下游稳定性 | 低质量应答可能带来司机取消或改派 |
| 单均应答时长 | 乘客等待 | 应答率和应答时长需一起看 |

## 使用场景

- 评估召回、分单、派单模式调整对交易链路承接的影响。
- 监控城市、时段、策略实验组之间的响应能力差异。

## 注意事项

- 当前口径使用剔除改派后的应答量作分子；若看板使用含改派应答量，应在复盘中显式说明。
- 不能只看应答率提升，还要同步看取消率、完单和履约率。
