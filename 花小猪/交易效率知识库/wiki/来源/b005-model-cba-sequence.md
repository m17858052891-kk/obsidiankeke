---
title: "B005 模型来源：CBA生存分析与序列建模"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: draft
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2207093933732", "cooper:knowledge:2208055936397"]
related: ["../模型/cba应答前取消模型.md", "../模型/PEPNet与序列履约模型.md"]
---

# B005 模型来源：CBA生存分析与序列建模

CBA材料把应答和应答前取消视为竞争事件，并指出已应答订单的潜在取消时长不可观测。方案使用Cox比例风险，将基线风险与乘客/订单特征的相对风险分开；输出需随已等待时间变化，离线评价应使用时间依赖AUC等生存指标。

序列建模材料比较PEPNet与OneTrans组合。表内PEP-seq-OneTrans相对PEP-seq的OD/O/D AUC均提高，但其他变体并非全面提升；这些是同表离线比较，文中CR、取消和远接驾数字是目标而非已实现收益。

## 原始来源

- [CBA建模](../../raw/cooper/knowledge-2207093933732.md)（sha256 `387f9e79a63bda28ca2b46e93e3c80cee45babacd83a4afd6d96d64e504d70b8`）
- [序列建模模型](../../raw/cooper/knowledge-2208055936397.md)（sha256 `58b6a7ceed7f67386aa0155f08b9571a2f84fe0b6e8fe82f485e514225a8eac4`）
