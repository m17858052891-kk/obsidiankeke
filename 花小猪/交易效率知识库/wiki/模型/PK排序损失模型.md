---
title: "PK排序损失模型"
type: model-card
owner: "@tommywujian"
freshness: watch
status: historical-offline
last_reviewed: null
permission_scope: department
source_ids: ["knowledge:2202063184688"]
related: ["PK模型谱系.md", "PK司机历史特征合同.md"]
---

# PK排序损失模型

> 历史离线探索；不代表线上模型、生产损失函数或当前版本。

## 任务与目标

材料认为 PK 只需要把可完单司机排在不可完单司机之前，不必先得到校准的履约概率，因此把任务从点概率学习改写为正负司机对的排序。候选损失对 `F(负)-F(正)` 的正间隔施加 ReLU 惩罚，与 AUC 的两两排序语义一致。

## 离线证据

同页表格记录 `hxz_v12 + CE` 的 AUC 为 0.8002，替换为 ranking loss 后为 0.8010，差值 0.08pp。材料没有样本期、正负样本构造、配对抽样、置信区间、重复实验或校准指标，因此只能说明该次历史离线比较中的小幅点估计变化。

## 模型合同缺口

- 标签如何处理乘客取消、司机取消、拒单、改派与未胜出样本。
- 每单正负司机的配对权重、难负样本策略和无正样本订单的处理。
- 排序分与线上 PK 规则、距离倾斜及商家约束的融合方式。
- 时间外/城市外泛化、校准、线上实验、服务版本与回滚证据。

## 来源与关联

- [排序损失函数](../../raw/cooper/knowledge-2202063184688.md)
- [PK模型谱系](PK模型谱系.md)

