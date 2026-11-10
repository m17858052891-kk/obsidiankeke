---
title: "B009 模型来源：城市成交率自适应 Hold"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: draft
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2199863444201"]
related: ["../模型/司机Hold参数策略.md"]
---

# B009 模型来源：城市成交率自适应 Hold

材料提出按上一自然周的城市小猪端应答率，将基础 Hold 时长映射到应答时长分位点：高应答率城市使用更高分位点，低于阈值时 Hold 为 0。它属于规则化参数适配，而非端到端学习模型。

正文中的 V2 城市范围和预计全量日期是历史记录，不能据此认定当前覆盖或上线状态；材料没有给出该分档规则的因果实验结果。

## 原始来源

- [城市成交率自动化匹配](../../raw/cooper/knowledge-2199863444201.md)（sha256 `8167690e273f1f328b0acf79136598cafeabfa874f503b5afa844a51d86e9cfb`）
