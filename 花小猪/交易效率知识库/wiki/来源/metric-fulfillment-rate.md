---
title: "履约率｜来源摘要"
type: source
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/fulfillment-rate.md"
related:
  - "../指标/fulfillment-rate.md"
---

# 履约率｜来源摘要

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 来源身份

- 稳定 ID：`repo:strategy-dept-knowledge:directions/trading-efficiency/metric/fulfillment-rate.md`
- 仓库相对路径：`directions/trading-efficiency/metric/fulfillment-rate.md`
- 快照 commit：`a27b537bdef2b8f1cd7e3c503602dad9fde164c3`
- SHA-256：`1c25562a12073ef28d5b659c7cae6ee1c434acf5835f4ee4401d22258b9b3e64`
- 层级：部门库二次整理材料；原始 Cooper 来源未在本批逐一复核。

## 结构化摘要

- 履约率衡量 PK 获胜订单中，后续稳定履约的比例。
- 履约定义：这一单在应答后没有司机取消或乘客取消。
- 这是商家维度指标，用于评估 PK 获胜订单的真实履约质量。

### 核心计算

```text
履约率 = 履约数 / PK 获胜数
```

- 分子：履约数，即 PK 获胜后应答，且应答后没有司机取消或乘客取消的订单数。
- 分母：PK 获胜数。
- 单位：比例。

## 使用边界

原材料 freshness 为 watch，最近内容复核日期为 2026-07-12。可用于定义候选知识与追溯，不据此宣布当前线上事实。

## 来源

- [fulfillment-rate.md](../../raw/department-baseline/directions/trading-efficiency/metric/fulfillment-rate.md)（快照 commit `a27b537`）

## 关联页面

- [fulfillment-rate](../指标/fulfillment-rate.md)
