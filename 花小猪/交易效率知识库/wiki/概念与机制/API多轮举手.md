---
title: "API 多轮举手"
type: concept
owner: "@tommywujian"
freshness: watch
status: active
last_reviewed: null
permission_scope: team
source_ids:
  - "cooper:knowledge:2206172524014"
related:
  - "../来源/B003-规划历史-API多轮举手.md"
  - "../实验与复盘/API多轮举手实验.md"
---

# API 多轮举手

## 机制

API 商家首次 PK 失败或预分单被拒后，允许用新的候选司机再次参与后续 PK。它解决的是商家参与机会不对称，而不是直接改变 PK 排序分数。

半指派胜出条件是相邻但独立的机制：若窗口结束时最高分司机尚未确认，可延长等待，或让后续更高分的已确认司机胜出。

## 预期链路

```text
首次失败/预分单拒绝
  → API再次举手
  → 参与PK数增加
  → 额外PK胜出
  → API完单及平台完单变化
```

## 评估要求

- 单独设置“只开半指派条件”的实验组，才能隔离多轮举手增量。
- 同时看举手次数、参与 PK 数、胜出数、API 完单和平台完单。
- 按商家分别评估；某个商家有效不能外推到所有 API 运力。

## 关联页面

- [API多轮举手实验](../实验与复盘/API多轮举手实验.md)
- [来源摘要](../来源/B003-规划历史-API多轮举手.md)
