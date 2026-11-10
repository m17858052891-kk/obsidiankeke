---
title: both 举手率
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
  - ./only-hand-raise-rate.md
---

# both 举手率

## 定义

- both 举手率衡量参与 PK 的样本中，有多于一个司机举手的占比。
- both 举手指有多于一个司机举手，需要在多个举手司机之间竞争。
- 这是商家维度指标，用于拆解 PK 参与样本中的多司机响应结构。

## 公式

```text
both 举手率 = 有多于一个司机举手的 PK 数 / 参与 PK 数
```

- 分子：有多于一个司机举手的 PK 数。
- 分母：参与 PK 数。
- 单位：比例。

## 关联指标

| 指标 | 关系 | 说明 |
| --- | --- | --- |
| 举手率 | 汇总指标 | both 举手率是整体举手率的拆分 |
| only 举手率 | 对照拆分 | 用于比较 only 场景响应差异 |
| PK 胜出率 | 下游排序 | both 场景通常更需要结合胜出率评估 |

## 使用场景

- 诊断参与 PK 流量中多司机响应是否充分。
- 评估多司机举手场景下的 PK 竞争结构。

## 注意事项

- 分母为参与 PK 数，不是播单数。
- both 举手率和 only 举手率共同拆解参与 PK 的举手结构。
