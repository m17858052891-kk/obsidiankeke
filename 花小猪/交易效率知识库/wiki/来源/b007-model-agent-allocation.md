---
title: "B007 模型来源：Agent 与运力分配建模"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: draft
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2199613357445", "cooper:knowledge:2199613361400", "cooper:knowledge:2199613361404"]
related: ["../模型/MDP时空价值网络.md", "../模型/订单期望GPH分配模型.md"]
---

# B007 模型来源：Agent 与运力分配建模

实时特征清单覆盖 1/5 分钟格子内供给、应答时长、冒泡、发单、应答和完单，并区分是否含三方、改派与多平台去重。Agent 设计记录描述可变长边集合的序列动作、联合概率与训练轨迹，但没有完整实验或部署证据。

运力分配方案提出以 `GMV × (1-cancel) × PK胜率 / (接驾+行程)` 表示期望 GPH，并明确渠道 PK 胜率可在 V1 暂不作为乘子。文档开头标记“暂停，等待旺季实验收益”，所以它是方案而非已上线模型。

## 原始来源

- [聚合平台应答实时特征](../../raw/cooper/knowledge-2199613357445.md)（sha256 `a81c301b95bf77be8ffd6f16b882da07ce0ff7efae3c4c799d6e1bd293b1f117`）
- [Agent设计机制梳理](../../raw/cooper/knowledge-2199613361400.md)（sha256 `6f78f2f15d7282168cc257800bd685339a2bed5712281e61cd67a8b395eb82b8`）
- [运力分配方案v1](../../raw/cooper/knowledge-2199613361404.md)（sha256 `8c6f006c4875876cf94c8140357a795b91510a84563830fb773230cb6f73a8f2`）
