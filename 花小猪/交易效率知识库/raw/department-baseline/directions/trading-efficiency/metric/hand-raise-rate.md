---
title: 举手率
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
  - ./only-hand-raise-rate.md
  - ./both-hand-raise-rate.md
---

# 举手率

## 定义

- 举手率衡量商家播单后，司机举手响应的比例。
- 这是商家维度指标，用于观察播单对司机响应意愿的牵引。

## 公式

```text
举手率 = 举手数 / 播单数
```

- 分子：举手数。
- 分母：播单数。
- 单位：比例。

## 关联指标

| 指标 | 关系 | 说明 |
| --- | --- | --- |
| only 举手率 | 拆分指标 | 用于区分 only 场景响应 |
| both 举手率 | 拆分指标 | 用于区分 both 场景响应 |
| PK 胜出率 | 下游排序 | 举手后的候选进入 PK 或胜出链路 |

## 使用场景

- 评估商家播单后司机是否愿意响应。
- 对比不同城市、时段、商家或策略版本下的播单响应质量。

## 注意事项

- 举手数和播单数需保持同一统计粒度。
- 该指标是商家维度指标，不等同于订单最终应答率。
