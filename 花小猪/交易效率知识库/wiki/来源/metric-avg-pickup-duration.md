---
title: "单均接驾时长｜来源摘要"
type: source
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/avg-pickup-duration.md"
related:
  - "../指标/avg-pickup-duration.md"
---

# 单均接驾时长｜来源摘要

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 来源身份

- 稳定 ID：`repo:strategy-dept-knowledge:directions/trading-efficiency/metric/avg-pickup-duration.md`
- 仓库相对路径：`directions/trading-efficiency/metric/avg-pickup-duration.md`
- 快照 commit：`a27b537bdef2b8f1cd7e3c503602dad9fde164c3`
- SHA-256：`3d5245f64fcfd9300282941c3d6eada6cfc36c9237585f1f64c7e6373346a8e2`
- 层级：部门库二次整理材料；原始 Cooper 来源未在本批逐一复核。

## 结构化摘要

- 单均接驾时长衡量司机从应答订单到到达上车点或取消前，被接驾过程占用的平均时间。
- 这是司机视角指标，表达司机被接驾阶段占用的时间，不是乘客等待总时长。

### 核心计算

```text
单均接驾时长 = 修正后接驾时间 / 应答订单量
```

- 分子：修正后接驾时间汇总。
- 分母：应答订单量，具体是否含改派需与看板口径一致。
- 单位：建议统一为分钟。

### 重要限制

修正逻辑区分可控/非可控运力和连环派/非连环派，详见指标卡与原文表格。

## 使用边界

原材料 freshness 为 watch，最近内容复核日期为 2026-07-12。可用于定义候选知识与追溯，不据此宣布当前线上事实。

## 来源

- [avg-pickup-duration.md](../../raw/department-baseline/directions/trading-efficiency/metric/avg-pickup-duration.md)（快照 commit `a27b537`）

## 关联页面

- [avg-pickup-duration](../指标/avg-pickup-duration.md)
