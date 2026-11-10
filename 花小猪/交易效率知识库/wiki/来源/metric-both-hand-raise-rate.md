---
title: "both 举手率｜来源摘要"
type: source
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/both-hand-raise-rate.md"
related:
  - "../指标/both-hand-raise-rate.md"
---

# both 举手率｜来源摘要

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 来源身份

- 稳定 ID：`repo:strategy-dept-knowledge:directions/trading-efficiency/metric/both-hand-raise-rate.md`
- 仓库相对路径：`directions/trading-efficiency/metric/both-hand-raise-rate.md`
- 快照 commit：`a27b537bdef2b8f1cd7e3c503602dad9fde164c3`
- SHA-256：`c1d81575b3b4bf5b368ee897828636311c8662cef572e1897fdf3ae0199d7702`
- 层级：部门库二次整理材料；原始 Cooper 来源未在本批逐一复核。

## 结构化摘要

- both 举手率衡量参与 PK 的样本中，有多于一个司机举手的占比。
- both 举手指有多于一个司机举手，需要在多个举手司机之间竞争。
- 这是商家维度指标，用于拆解 PK 参与样本中的多司机响应结构。

### 核心计算

```text
both 举手率 = 有多于一个司机举手的 PK 数 / 参与 PK 数
```

- 分子：有多于一个司机举手的 PK 数。
- 分母：参与 PK 数。
- 单位：比例。

## 使用边界

原材料 freshness 为 watch，最近内容复核日期为 2026-07-12。可用于定义候选知识与追溯，不据此宣布当前线上事实。

## 来源

- [both-hand-raise-rate.md](../../raw/department-baseline/directions/trading-efficiency/metric/both-hand-raise-rate.md)（快照 commit `a27b537`）

## 关联页面

- [both-hand-raise-rate](../指标/both-hand-raise-rate.md)
