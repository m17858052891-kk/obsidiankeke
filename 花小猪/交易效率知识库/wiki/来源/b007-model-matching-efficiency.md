---
title: "B007 模型来源：匹配效率拟合"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: draft
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2199613339930", "cooper:knowledge:2199613341457"]
related: ["../模型/匹配效率成交率拟合.md"]
---

# B007 模型来源：匹配效率拟合

两份材料描述城市粒度的成交率拟合：以供需比和密度解释竞争成交率，用于预算分配和水位调整。一个版本采用过去 28 天、周更新的 logit 形式；迭代记录还比较了 Ridge 与不同数据口径，并以城市测试集 MAE 分桶评价。

材料显示口径变化会显著改变效果，且 notebook 训练结果与例行化系数表曾不一致。该来源不能证明某一拟合版本仍在线有效。

## 原始来源

- [匹配效率拟合优化](../../raw/cooper/knowledge-2199613339930.md)（sha256 `5482cac8115a726c3ee083827973cba74ec2dc265d7b88ba3720d96fc2af214c`）
- [匹配效率的应用](../../raw/cooper/knowledge-2199613341457.md)（sha256 `dc194a2df325b6f549f89f0df333a2fc93d808428b1b11ffa143338085e84315`）
