---
title: "应答率｜来源摘要"
type: source
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/response-rate.md"
related:
  - "../指标/response-rate.md"
---

# 应答率｜来源摘要

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 来源身份

- 稳定 ID：`repo:strategy-dept-knowledge:directions/trading-efficiency/metric/response-rate.md`
- 仓库相对路径：`directions/trading-efficiency/metric/response-rate.md`
- 快照 commit：`a27b537bdef2b8f1cd7e3c503602dad9fde164c3`
- SHA-256：`36e98b7f693a52bebc57a4da7ddced4c0855ce49e85bf382d7f1af64bb80b618`
- 层级：部门库二次整理材料；原始 Cooper 来源未在本批逐一复核。

## 结构化摘要

- 应答率衡量小猪端竞争呼叫中被司机应答的比例。
- 这是交易链路承接能力指标，用于观察召回、分单和派单策略是否让乘客呼叫被有效响应。

### 核心计算

```text
应答率 = 应答量 / 竞争呼叫
```

- 分子：剔除改派后的应答订单数。
- 分母：小猪端竞争呼叫订单数。
- 单位：比例。

## 使用边界

原材料 freshness 为 watch，最近内容复核日期为 2026-07-12。可用于定义候选知识与追溯，不据此宣布当前线上事实。

## 来源

- [response-rate.md](../../raw/department-baseline/directions/trading-efficiency/metric/response-rate.md)（快照 commit `a27b537`）

## 关联页面

- [response-rate](../指标/response-rate.md)
