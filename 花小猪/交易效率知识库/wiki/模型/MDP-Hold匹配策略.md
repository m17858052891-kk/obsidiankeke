---
title: "MDP-Hold匹配策略"
type: model-card
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2199613359733", "cooper:knowledge:2199613361368"]
related: ["MDP时空价值网络.md", "../来源/b007-model-mdp-value.md"]
---

# MDP-Hold匹配策略

## 决策机制

为冷却期内司机增加可匹配的空订单节点，以当前时空状态价值 `V(s)` 作为司机—空节点边权，再通过 GS 匹配决定分单或 hold。它组合了 Hold 的当前收益门槛和 MDP 的未来价值，但不是独立的监督学习模型。

## 证据边界

- Hold 可能忽略长期收益；纯 MDP 可能在当前与未来价值都偏低时仍强制分单。
- 历史线上材料比较的是 MDP 排序与 IPH+Hold，不等同于完整 MDP-Hold 的独立归因实验。
- 城市、时段、天气、旧训练窗口和分流差异均可能影响观测结果。

## 来源

- [B007 MDP 时空价值与 Hold](../来源/b007-model-mdp-value.md)
