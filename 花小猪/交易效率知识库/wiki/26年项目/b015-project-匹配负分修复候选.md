---
title: "B015 项目候选：匹配联合决策负分修复"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_key: "b015-project-matching-negative-score-fix"
source_ids:
  - "knowledge:2210085351088"
  - "knowledge:2209988725872"
  - "knowledge:2210257284562"
related:
  - "b014-project-商家匹配联合决策V1候选.md"
  - "b014-project-调层改造V1候选.md"
---

# B015 项目候选：匹配联合决策负分修复

> BRD 将该改造归入“26 常规项目”，计划随匹配重构 V1.0 在 10 月下旬上线；当前材料没有上线回执，本页只作为候选依赖归档。

## 问题与方案

匹配联合决策的距离和取消惩罚可能使约 18% 的候选 OD 得分为负。直接过滤或降级会减少匹配量，也会让统一策略无法完整生效。候选修复方案给所有 Score 加同量级、可配置的平移项，再通过归一化映射到兼容倾斜的区间，目标是保留候选排序并避免负分。

## 与主项目的关系

- 该修复不计划单独实验，拟并入商家匹配联合决策 V1.0 的总实验。
- 主项目以完单和取消约束下降低接驾距离；Review 与离线参数材料提供了拉格朗日目标、三动作竞争和参数回放思路，但不构成生产效果。
- “距离教师 + LP/MILP”与真实三动作回放均是离线求参候选；材料中的距离下降和模式占比变化属于回放结果，不能外推为线上收益。

## 验收与缺口

需核验平移参数对归一化、倾斜系数、空匹配和匹配量的影响，并随总实验联合观察履约、取消、距离和三种派单模式占比。公式图片、完整 SQL、参数配置、代码版本及上线回执未完整解析。

## 原始来源

- [Score 负分修复 BRD](../../raw/cooper/knowledge-2210085351088.md)
- [匹配重构 Review](../../raw/cooper/knowledge-2209988725872.md)
- [仿真离线参数求解](../../raw/cooper/knowledge-2210257284562.md)
