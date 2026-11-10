---
title: "PK 深度可解释模型 v1.1-v1.2 实验链"
type: analysis
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_ids:
  - "cooper:knowledge:2206536768826"
  - "cooper:knowledge:2207211037501"
  - "cooper:knowledge:2207283096074"
related:
  - "../来源/b005-evidence-2206536768826.md"
  - "../来源/b005-evidence-2207211037501.md"
  - "../来源/b005-evidence-2207283096074.md"
---

# PK 深度可解释模型 v1.1-v1.2 实验链

## 从离线到线上

离线评估显示，Wide&Deep 的乘客和司机单目标 AUC 高于 LR，但组合后的司乘履约 AUC 反而低于单 LR，暴露出加权方式问题。v1.1 线上实验进一步出现成交率下降、乘客取消及接驾距离上升，并提前停止。

## 关键修正与复验

v1.1 复盘认为 LR 曾将距离权重加倍，而深度模型未做同等处理；训练胜出样本与线上分单/PK 预测空间还存在样本选择偏差。v1.2 以距离权重修正后重开实验，接驾距离和时长显著下降，部分组成交率显著提高 0.09—0.17pp。

## 仍未闭环

- 人均完单未显著提升，司机取消、应答率和商家份额存在护栏代价。
- “距离权重遗漏”是强机制线索，但还需消融或对照验证因果贡献。
- 线上选择应基于综合护栏，不宜只取单一成交率最优组。

