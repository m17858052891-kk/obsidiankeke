---
title: "需求满足率（冒泡完单率）"
type: concept
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_ids: ["cooper:knowledge:2200011223872"]
related: ["../来源/b010-evidence-2200011223872.md", "../实验与复盘/无运力车型折叠实验链.md"]
---
# 需求满足率（冒泡完单率）

## 定义

该来源将需求满足率定义为 `ECR × CR`，其中 ECR 为“呼单 / 去重冒泡”，CR 为呼单后的成交率。因此它同时覆盖从冒泡到呼单、再从呼单到完单的两段漏斗。

## 使用方式

当策略提高 CR 却压低 ECR 时，需求满足率比单看 CR 更能防止局部优化。仍需配合人均冒泡、人均呼叫、人均完单及份额迁移解释。

## 口径边界

必须确认分子分母、人群、时间窗和去重方式一致；不同文档中的“成交率”“CR”不应未经核对直接代入。
