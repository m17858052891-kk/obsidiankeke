---
title: PK 胜出率
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
  - ./absolute-pk-win-rate.md
  - ./fulfillment-rate.md
---

# PK 胜出率

## 定义

- PK 胜出率衡量参与 PK 的样本中最终产生胜出订单的比例。
- 这是商家维度指标，用于评估参与 PK 后的胜出转化。

## 公式

```text
PK 胜出率 = 胜出订单数 / 参与 PK 数
```

- 分子：胜出订单数。
- 分母：参与 PK 数。
- 单位：比例。

## 关联指标

| 指标 | 关系 | 说明 |
| --- | --- | --- |
| 绝对 PK 胜出率 | 配套指标 | 两者通常分母不同，需要一起解释 |
| 履约率 | 结果质量 | 胜出后是否履约是排序质量关键 |
| 平均接驾距离 | 体验约束 | 胜出策略不能显著拉长接驾 |

## 使用场景

- 评估参与 PK 后是否形成胜出订单。
- 结合履约率判断胜出订单是否真正稳定履约。

## 注意事项

- 分母为参与 PK 数。
- only 举手直接获胜，both 举手进入多司机竞争，二者都会影响 PK 胜出率。
