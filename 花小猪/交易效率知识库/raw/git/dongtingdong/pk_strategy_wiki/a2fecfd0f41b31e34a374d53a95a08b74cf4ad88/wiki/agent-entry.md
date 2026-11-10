---
title: PK Agent Entry
type: index
created: 2026-05-29
updated: 2026-08-06
tags:
  - agent
  - pk决策
---

# PK Agent Entry

This is the first file Claude Code should read for PK strategy and model optimization work.

## Read Order

1. `CLAUDE.md` — project schema, page conventions, and domain rules.
2. `wiki/index.md` — full wiki navigation.
3. `wiki/overview.md` — system-level summary.
4. `wiki/metric-map.md` — primary metrics and guardrails.
5. `wiki/code-map.md` — mapping from wiki topics to model repository code paths.
6. Relevant entity, concept, model, proposal, or source pages.

## Common Entry Points

| Task | Start Here |
| --- | --- |
| Understand PK system | `wiki/overview.md` |
| Find strategy or model pages | `wiki/index.md` |
| Propose model optimization | `wiki/models/模型架构总览.md`, `wiki/research/多任务学习迭代方向.md`, `wiki/proposals/` |
| Work on AUC or offline model quality | `wiki/concepts/AUC.md`, `wiki/entities/PK模型.md`, `wiki/models/` |
| Work on CR or fulfillment | `wiki/concepts/履约率.md`, `wiki/entities/PK模型.md` |
| Work on dynamic window | `wiki/entities/PK窗口.md`, `wiki/models/PLE多任务模型.md`, `wiki/models/DQN.md` |
| Work on feature engineering | `wiki/concepts/特征工程.md`, `wiki/models/LR逻辑回归.md` |
| **Work on current online PK / ETP / pickup duration** | `wiki/models/Wide&Deep.md`, `wiki/sources/09-LR26-010-DeepWide-V1.0.md` |
| **Work on V5 约束-最小化范式 / 接驾距离 / ETP** | `wiki/entities/约束履约率最小化接驾距离策略.md`, `wiki/sources/08-约束履约率最小化接驾距离方案.md` |

## Search Boundaries

- Prefer `wiki/` pages first.
- Use `raw/` only when a wiki page is missing detail or the user asks for source evidence.
- Do not use unrelated sibling knowledge bases unless the project registry routes the task there.
