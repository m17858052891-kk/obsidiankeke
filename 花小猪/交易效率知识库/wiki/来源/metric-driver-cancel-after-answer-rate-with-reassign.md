---
title: "应答后司机取消率（含改派）｜来源摘要"
type: source
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/driver-cancel-after-answer-rate-with-reassign.md"
related:
  - "../指标/driver-cancel-after-answer-rate-with-reassign.md"
---

# 应答后司机取消率（含改派）｜来源摘要

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 来源身份

- 稳定 ID：`repo:strategy-dept-knowledge:directions/trading-efficiency/metric/driver-cancel-after-answer-rate-with-reassign.md`
- 仓库相对路径：`directions/trading-efficiency/metric/driver-cancel-after-answer-rate-with-reassign.md`
- 快照 commit：`a27b537bdef2b8f1cd7e3c503602dad9fde164c3`
- SHA-256：`1ed751dc7f09d39a35ab2c68a8084ad54f420299d727e0dd6adc131cb80fd39c`
- 层级：部门库二次整理材料；原始 Cooper 来源未在本批逐一复核。

## 结构化摘要

- 应答后司机取消率（含改派）衡量订单被司机应答后，由司机取消或司机取消后触发改派的比例。
- 这是司机侧交易稳定性指标，用于观察派单质量、司机接单意愿和改派风险。

### 核心计算

```text
应答后司机取消率（含改派） = 应答后司机取消量（含改派） / 应答量（含改派）
```

- 分子：应答后司机取消订单数，包含司机取消后触发改派的订单。
- 分母：含改派的应答订单数。
- 单位：比例。

## 使用边界

原材料 freshness 为 watch，最近内容复核日期为 2026-07-12。可用于定义候选知识与追溯，不据此宣布当前线上事实。

## 来源

- [driver-cancel-after-answer-rate-with-reassign.md](../../raw/department-baseline/directions/trading-efficiency/metric/driver-cancel-after-answer-rate-with-reassign.md)（快照 commit `a27b537`）

## 关联页面

- [driver-cancel-after-answer-rate-with-reassign](../指标/driver-cancel-after-answer-rate-with-reassign.md)
