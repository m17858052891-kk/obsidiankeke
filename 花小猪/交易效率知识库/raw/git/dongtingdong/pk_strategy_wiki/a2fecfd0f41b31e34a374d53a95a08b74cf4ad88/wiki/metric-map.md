---
title: PK Metric Map
type: concept
created: 2026-05-29
updated: 2026-08-06
tags:
  - 指标
  - agent
  - pk决策
related:
  - wiki/concepts/AUC.md
  - wiki/concepts/履约率.md
  - wiki/concepts/接驾距离.md
  - wiki/concepts/司乘取消.md
---

# PK Metric Map

This page defines how Claude Code should reason about PK metrics during strategy and model optimization.

## Current Online Decision Rule

V4 Deep&Wide 的最终放量规则是：

1. 完单和 CR 不显著负；
2. 乘客 ETP + 司机接驾时长至少优化 0.1%；
3. 应答后乘客取消至少下降 0.1pp；
4. 同时报告司机取消（含改派）和分商家完单变化。

## Primary Offline Metric

| Metric | Direction | Notes |
| --- | --- | --- |
| AUC | Higher is better | 仍是模型诊断指标，但 V4 证明子任务 AUC 提升、综合 AUC 下降时仍可能产生线上交易效率收益，不能独立决定上线。 |

## Business Metrics

| Metric | Direction | Notes |
| --- | --- | --- |
| 履约率 / 完单率 / CR | Higher is better | Core business objective for PK decisions. |
| 乘客 ETP | Lower is better | 当前 V4 主要收益指标；应答时长 + 接驾时长，乘客视角、归一完单。 |
| 司机接驾时长 | Lower is better | 当前 V4 主要收益指标；呼叫至开始计费/取消，司机视角。 |
| 商家胜出率 | Depends on strategy | Must be interpreted by商家、城市、业务目标. |
| 毛利 | Higher is usually better | Guard against sacrificing CR or体验 for margin. |

## Guardrail Metrics

| Metric | Direction | Notes |
| --- | --- | --- |
| 接驾距离 | Lower is usually better | Strong feature and user experience guardrail. |
| 乘客取消率 | Lower is better | Watch especially for long wait and dynamic-window changes. |
| 司机取消率（含改派） | Lower is better | V4 最终组 +0.44pp，是当前最重要的负向护栏。 |
| 推理延迟 | Lower is better | Needed when model architecture gets more complex. |
| 特征缺失率 | Lower is better | Important for cold start and feature rebuilds. |

## Reporting Rules

- Always name the baseline model, strategy, data window, and sample filter.
- Report primary metric movement and guardrail movement together.
- Do not recommend shipping from AUC alone when business guardrails are missing.
- 对 Deep&Wide 必须注明权重组；0.8:0.2 的 CR 最优与最终 0.9:0.1 的交易效率最优不可混用。
