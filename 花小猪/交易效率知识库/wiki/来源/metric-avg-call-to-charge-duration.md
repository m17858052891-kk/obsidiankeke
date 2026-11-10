---
title: "单均呼叫-计费时长｜来源摘要"
type: source
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/avg-call-to-charge-duration.md"
related:
  - "../指标/avg-call-to-charge-duration.md"
---

# 单均呼叫-计费时长｜来源摘要

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 来源身份

- 稳定 ID：`repo:strategy-dept-knowledge:directions/trading-efficiency/metric/avg-call-to-charge-duration.md`
- 仓库相对路径：`directions/trading-efficiency/metric/avg-call-to-charge-duration.md`
- 快照 commit：`a27b537bdef2b8f1cd7e3c503602dad9fde164c3`
- SHA-256：`f5b70b85a2e119682051c11576e2b4679857351d9f711d9843cce1da278fe2a0`
- 层级：部门库二次整理材料；原始 Cooper 来源未在本批逐一复核。

## 结构化摘要

- 单均呼叫-计费时长衡量乘客从发单到司机开始计费的真实平均等待时长。
- 这是乘客视角指标，终点是开始计费，不是司机点击到达上车点。

### 核心计算

```text
单均呼叫-计费时长 = 呼叫-计费时长 / 完单量
```

- 呼叫-计费时长：同一次原始发单中，首次开始计费时间 - 第一次呼叫时间。
- 分母：完单量。
- 单位：建议统一为分钟。

## 使用边界

原材料 freshness 为 watch，最近内容复核日期为 2026-07-12。可用于定义候选知识与追溯，不据此宣布当前线上事实。

## 来源

- [avg-call-to-charge-duration.md](../../raw/department-baseline/directions/trading-efficiency/metric/avg-call-to-charge-duration.md)（快照 commit `a27b537`）

## 关联页面

- [avg-call-to-charge-duration](../指标/avg-call-to-charge-duration.md)
