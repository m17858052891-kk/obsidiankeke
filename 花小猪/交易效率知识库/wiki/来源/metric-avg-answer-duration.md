---
title: "单均应答时长｜来源摘要"
type: source
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/avg-answer-duration.md"
related:
  - "../指标/avg-answer-duration.md"
---

# 单均应答时长｜来源摘要

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 来源身份

- 稳定 ID：`repo:strategy-dept-knowledge:directions/trading-efficiency/metric/avg-answer-duration.md`
- 仓库相对路径：`directions/trading-efficiency/metric/avg-answer-duration.md`
- 快照 commit：`a27b537bdef2b8f1cd7e3c503602dad9fde164c3`
- SHA-256：`0b467505cb553509b10cd6a13c5c7a230da99e8cda23d94ce6049621f14371f8`
- 层级：部门库二次整理材料；原始 Cooper 来源未在本批逐一复核。

## 结构化摘要

- 单均应答时长衡量乘客发单后，到第一次被司机应答前等待的平均时间。
- 这是乘客视角指标，表达乘客等待司机响应的时间占用。

### 核心计算

```text
单均应答时长 = 呼叫-首次应答时长 / 应答量（不含改派）
```

- 呼叫-首次应答时长：同一次原始发单中，第一次应答时间 - 第一次呼叫时间。
- 分母：不含改派的应答量。
- 单位：建议统一为秒或分钟。

## 使用边界

原材料 freshness 为 watch，最近内容复核日期为 2026-07-12。可用于定义候选知识与追溯，不据此宣布当前线上事实。

## 来源

- [avg-answer-duration.md](../../raw/department-baseline/directions/trading-efficiency/metric/avg-answer-duration.md)（快照 commit `a27b537`）

## 关联页面

- [avg-answer-duration](../指标/avg-answer-duration.md)
