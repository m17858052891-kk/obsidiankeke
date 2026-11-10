---
title: "B009 模型来源：MDP 长期价值建模"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: draft
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2199613434298"]
related: ["../模型/MDP时空价值网络.md", "../模型/MDP-Hold匹配策略.md"]
---

# B009 模型来源：MDP 长期价值建模

材料把司机在时间、空间状态下选择订单建模为 MDP：action 为订单，reward 为衰减后的订单 GMV，通过 TD 更新状态价值，并将当前订单收益与终点未来价值组合为司机侧匹配边权。时间采用周期编码，空间使用格子中心坐标；训练数据按司机序列构造并补充 idle 转移。

文档同时记录了样本稀疏、状态漂移、reward shaping、跨时段衰减与重复更新等问题，且反思历史上线效果不明显。正文中的计划和优化建议不能当作已实现版本，多张曲线图未解析。

## 原始来源

- [MDP价值排序建模与优化](../../raw/cooper/knowledge-2199613434298.md)（sha256 `1e675d31dc6a97e520c1b6ed16b3d046fadf1cdf35ca49e5204447f14e9ac91a`）
