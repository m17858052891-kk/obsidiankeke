---
title: "PK 履约与距离弹性"
type: concept
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_key: b018-evidence-pk-elasticity
source_ids: ["cooper:2208749841049"]
source_url: "https://cooper.didichuxing.com/team-file/2199582756311/2208749841049"
related: ["平台PK.md", "../指标/pk-win-rate.md", "../指标/average-pickup-distance.md"]
---
# PK 履约与距离弹性

## 历史模型解释

材料用当时线上可解释 LR 模型做局部敏感性估算：取消率下降 1pp 对应空车 PK 胜率约 +0.6pp，拒单率下降 1pp 约对应 +0.3pp；接驾距离减少 50m 约对应 +1.4pp。它说明短期 PK 中距离项的边际影响可能大于单一履约项，但三者不是可直接相加的独立因果效应。

## 业务含义与边界

同一材料观察到自营履约更好但胜率更低，提示交易模式、距离和供需构成会共同影响份额。上述数字来自特定版本函数与样本，不是线上干预实验，也不能外推到新模型或新城市；内嵌图片未解析，完整系数与交互项仍待核对。

## 来源

- [PK 分析—自营](../../raw/cooper/cooper-2208749841049.md)

