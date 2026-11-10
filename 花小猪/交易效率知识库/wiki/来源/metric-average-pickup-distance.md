---
title: "平均接驾距离｜来源摘要"
type: source
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/average-pickup-distance.md"
related:
  - "../指标/average-pickup-distance.md"
---

# 平均接驾距离｜来源摘要

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 来源身份

- 稳定 ID：`repo:strategy-dept-knowledge:directions/trading-efficiency/metric/average-pickup-distance.md`
- 仓库相对路径：`directions/trading-efficiency/metric/average-pickup-distance.md`
- 快照 commit：`a27b537bdef2b8f1cd7e3c503602dad9fde164c3`
- SHA-256：`e395e5cdc882d9865bed33501fbfa71519cfe27ebc92e01a451ac46fe5263982`
- 层级：部门库二次整理材料；原始 Cooper 来源未在本批逐一复核。

## 结构化摘要

- 平均接驾距离衡量司机应答时到乘客发单地的预估路面距离。
- 这是司乘共同体验指标：司机承担接驾成本，乘客承担等待和取消风险。

### 核心计算

```text
平均接驾距离 = 预估接驾距离 / 应答量（含改派）
```

- 分子：司机应单时到乘客发单地的预估路面距离汇总。
- 分母：含改派的应答订单数。
- 单位：建议统一为米；若使用 km，必须在图表和文档中标注。

## 使用边界

原材料 freshness 为 watch，最近内容复核日期为 2026-07-12。可用于定义候选知识与追溯，不据此宣布当前线上事实。

## 来源

- [average-pickup-distance.md](../../raw/department-baseline/directions/trading-efficiency/metric/average-pickup-distance.md)（快照 commit `a27b537`）

## 关联页面

- [average-pickup-distance](../指标/average-pickup-distance.md)
