---
title: only 举手率
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
  - ./hand-raise-rate.md
  - ./both-hand-raise-rate.md
---

# only 举手率

## 定义

- only 举手率衡量参与 PK 的样本中，只有一个司机举手的占比。
- only 举手指只有一个司机举手；该场景下 only 举手直接获胜。
- 这是商家维度指标，用于拆解 PK 参与样本中的单司机响应结构。

## 公式

```text
only 举手率 = 只有一个司机举手的 PK 数 / 参与 PK 数
```

- 分子：只有一个司机举手的 PK 数。
- 分母：参与 PK 数。
- 单位：比例。

## 关联指标

| 指标 | 关系 | 说明 |
| --- | --- | --- |
| 举手率 | 汇总指标 | only 举手率是整体举手率的拆分 |
| both 举手率 | 对照拆分 | 用于比较 both 场景响应差异 |
| PK 胜出率 | 下游排序 | only 举手直接获胜，会影响整体胜出率 |

## 使用场景

- 诊断参与 PK 流量中是否大量只有一个司机响应。
- 评估 only 举手直接获胜对整体 PK 胜出结构的影响。

## 注意事项

- only 举手直接获胜，不再进入多司机竞争排序。
- 分母为参与 PK 数，不是播单数。
