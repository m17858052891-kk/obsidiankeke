---
title: "送驾时长占比｜来源摘要"
type: source
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/charge-duration-share.md"
related:
  - "../指标/charge-duration-share.md"
---

# 送驾时长占比｜来源摘要

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 来源身份

- 稳定 ID：`repo:strategy-dept-knowledge:directions/trading-efficiency/metric/charge-duration-share.md`
- 仓库相对路径：`directions/trading-efficiency/metric/charge-duration-share.md`
- 快照 commit：`a27b537bdef2b8f1cd7e3c503602dad9fde164c3`
- SHA-256：`3317b21d28d218d2d820dd3cb0910738eba7578b5431e424cae60bdf01dd98b5`
- 层级：部门库二次整理材料；原始 Cooper 来源未在本批逐一复核。

## 结构化摘要

- 送驾时长占比衡量司机有效载客送驾时间在“接驾 + 送驾”时间中的占比。
- 这是司机视角指标，表达司机时间是否更多花在有效载客上。

### 核心计算

```text
送驾时长占比 = 送驾时间 / (修正后接驾时间 + 送驾时间)
```

- 送驾时间：开始计费时间到结束计费时间。
- 接驾时间：使用单均接驾时长中的修正后接驾时间。
- 单位：比例。

## 使用边界

原材料 freshness 为 watch，最近内容复核日期为 2026-07-12。可用于定义候选知识与追溯，不据此宣布当前线上事实。

## 来源

- [charge-duration-share.md](../../raw/department-baseline/directions/trading-efficiency/metric/charge-duration-share.md)（快照 commit `a27b537`）

## 关联页面

- [charge-duration-share](../指标/charge-duration-share.md)
