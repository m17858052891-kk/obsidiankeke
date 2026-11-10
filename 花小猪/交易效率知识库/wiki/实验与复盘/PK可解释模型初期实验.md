---
title: "PK 可解释模型初期实验"
type: analysis
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_key: b019-evidence-pk-explainable-initial
source_ids: ["cooper:knowledge:2202796540690"]
source_url: "https://cooper.didichuxing.com/knowledge/2199610335356/2202796540690"
related: ["PK可解释LR模型实验评估.md", "PK深度可解释模型实验链.md"]
---
# PK 可解释模型初期实验

## 实验设置

历史实验覆盖 22 个城市，主要评估期为 2024-08-03 至 08-08。剔除窜组后的 treatment/control 样本各约 77 万人。

## 历史结果

实验组人均呼叫显著 +0.82%，但 CR 显著 -0.74pp（表中相对 lift -0.99%），人均完单 -0.17% 不显著；人均自营完单显著 -12.87%，人均宏鹄完单显著 +8.28%，显示强烈的商家份额迁移。乘客应答后取消显著 +5.61%，而应答前取消和司机取消有所下降。未剔除窜组的较短窗口仍显示完单不显著、CR 负向以及自营向宏鹄迁移，但幅度不同。

## 决策边界

该初期版本不支持直接扩量：总完单没有显著提升，CR 和乘客取消护栏负向，并存在明显份额迁移。结果是历史版本证据，不能代表后续迭代；长 SQL 未复跑，城市异质性和窜组处理需与后续实验链联合解读。

## 来源

- [2024 PK 可解释模型初期评估](../../raw/cooper/knowledge-2202796540690.md)
