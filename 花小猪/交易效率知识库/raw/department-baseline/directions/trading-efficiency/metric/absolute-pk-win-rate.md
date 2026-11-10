---
title: 绝对 PK 胜出率
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
  - ./pk-win-rate.md
  - ./fulfillment-rate.md
---

# 绝对 PK 胜出率

## 定义

- 绝对 PK 胜出率衡量 both 举手竞争场景下的胜出比例。
- 这是商家维度指标，用于观察多司机举手参与 PK 后的胜出效果。

## 公式

```text
绝对 PK 胜出率 = both 举手胜出数 / both 举手参与 PK 数
```

- 分子：both 举手胜出数。
- 分母：both 举手参与 PK 数。
- 单位：比例。

## 关联指标

| 指标 | 关系 | 说明 |
| --- | --- | --- |
| PK 胜出率 | 配套指标 | PK 胜出率分母是参与 PK 数，绝对 PK 胜出率分母限定 both 举手参与 PK 数 |
| 履约率 | 结果质量 | 胜出贡献需要结合履约判断 |
| 举手率 | 上游响应 | 举手不足会限制绝对胜出规模 |

## 使用场景

- 评估 both 举手竞争场景下的 PK 胜出效果。
- 对比不同城市、时段、商家或策略版本下多司机竞争的胜出质量。

## 注意事项

- 分母限定 both 举手参与 PK 数，不是全部参与 PK 数。
- 与 PK 胜出率相比，绝对 PK 胜出率更聚焦多司机举手竞争场景。
