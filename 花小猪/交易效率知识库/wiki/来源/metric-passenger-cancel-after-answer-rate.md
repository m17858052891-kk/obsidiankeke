---
title: "应答后乘客取消率｜来源摘要"
type: source
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/passenger-cancel-after-answer-rate.md"
related:
  - "../指标/passenger-cancel-after-answer-rate.md"
---

# 应答后乘客取消率｜来源摘要

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 来源身份

- 稳定 ID：`repo:strategy-dept-knowledge:directions/trading-efficiency/metric/passenger-cancel-after-answer-rate.md`
- 仓库相对路径：`directions/trading-efficiency/metric/passenger-cancel-after-answer-rate.md`
- 快照 commit：`a27b537bdef2b8f1cd7e3c503602dad9fde164c3`
- SHA-256：`354473c7ef727f98ebd072636dac8fb55bdc3e64dae0801d1f38e6289b74b220`
- 层级：部门库二次整理材料；原始 Cooper 来源未在本批逐一复核。

## 结构化摘要

- 应答后乘客取消率衡量订单被司机应答后，最终由乘客取消的比例。
- 这是乘客体验指标，常用于判断等待过长、接驾过远、沟通体验差等问题是否导致取消。

### 核心计算

```text
应答后乘客取消率 = 应答后乘客取消量 / 应答量（含改派）
```

- 分子：剔除改派后的应答后乘客取消订单数。
- 分母：含改派的应答订单数。
- 单位：比例。

## 使用边界

原材料 freshness 为 watch，最近内容复核日期为 2026-07-12。可用于定义候选知识与追溯，不据此宣布当前线上事实。

## 来源

- [passenger-cancel-after-answer-rate.md](../../raw/department-baseline/directions/trading-efficiency/metric/passenger-cancel-after-answer-rate.md)（快照 commit `a27b537`）

## 关联页面

- [passenger-cancel-after-answer-rate](../指标/passenger-cancel-after-answer-rate.md)
