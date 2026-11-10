---
title: "B010 模型来源：GS愿接分替代IPH"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: draft
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2200955288615", "cooper:knowledge:2201070774290", "cooper:knowledge:2201262562766"]
related: ["../模型/司机愿接模型.md", "../模型/稳定匹配GS算法.md"]
---

# B010 模型来源：GS愿接分替代IPH

方案将 GS 中司机对订单的 IPH 排序替换为取消/拒单概率：自营连环派、非连环派以及宏鹄连环派、非连环派分别复用已有模型。由于输出是“不想接”的概率，进入排序前取负；模型不可用时回退 IPH，并以 20、120 为边界做归一化。

实验文档区分了司机分流与时间片配置；“已发布配置”不等于全部实验已开启。后续复盘记录自营和宏鹄时间片的 CR 变化均不显著。实验城市中，单轮存在多个可选订单的播单占比最高为 14.35%，这是排序替换可直接影响范围的观察上限，不是模型准确率或可保证的收益上限。

材料提出下一步对低愿接 OD 做 hold，但这只是迭代方向，不能写成已实现或已验证策略。原文链接的实验平台细节与外部页面未纳入本批快照。

## 原始来源

- [策略方案](../../raw/cooper/knowledge-2200955288615.md)（sha256 `7a1040a148bd133653de1d523c790fbcf87f8995a8fa94e4bff9b396d0891267`）
- [实验方案](../../raw/cooper/knowledge-2201070774290.md)（sha256 `f12a506d8d13c91c516ad387702dbeed053a5096cc51539a4d2223031e9aed2b`）
- [收益上限分析](../../raw/cooper/knowledge-2201262562766.md)（sha256 `f60829f97ca85f9e9fbc273eb60e5be8e44dee50b8e6209931e3b2254d4006ff`）
