---
title: "绝对 PK 胜出率｜来源摘要"
type: source
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/absolute-pk-win-rate.md"
related:
  - "../指标/absolute-pk-win-rate.md"
---

# 绝对 PK 胜出率｜来源摘要

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 来源身份

- 稳定 ID：`repo:strategy-dept-knowledge:directions/trading-efficiency/metric/absolute-pk-win-rate.md`
- 仓库相对路径：`directions/trading-efficiency/metric/absolute-pk-win-rate.md`
- 快照 commit：`a27b537bdef2b8f1cd7e3c503602dad9fde164c3`
- SHA-256：`59b9da66e2976db87c09f569a9cb76011051de58063c19537b9cd0294b2251d1`
- 层级：部门库二次整理材料；原始 Cooper 来源未在本批逐一复核。

## 结构化摘要

- 绝对 PK 胜出率衡量 both 举手竞争场景下的胜出比例。
- 这是商家维度指标，用于观察多司机举手参与 PK 后的胜出效果。

### 核心计算

```text
绝对 PK 胜出率 = both 举手胜出数 / both 举手参与 PK 数
```

- 分子：both 举手胜出数。
- 分母：both 举手参与 PK 数。
- 单位：比例。

## 使用边界

原材料 freshness 为 watch，最近内容复核日期为 2026-07-12。可用于定义候选知识与追溯，不据此宣布当前线上事实。

## 来源

- [absolute-pk-win-rate.md](../../raw/department-baseline/directions/trading-efficiency/metric/absolute-pk-win-rate.md)（快照 commit `a27b537`）

## 关联页面

- [absolute-pk-win-rate](../指标/absolute-pk-win-rate.md)
