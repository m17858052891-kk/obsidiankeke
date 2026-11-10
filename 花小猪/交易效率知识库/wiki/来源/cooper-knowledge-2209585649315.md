---
title: "模型（差体验与乘客流失因果建模）｜Cooper来源摘要"
type: "source"
owner: "@tommywujian"
freshness: "watch"
status: "proposed"
last_reviewed: null
permission_scope: "team"
source_ids: ["knowledge:2209585649315"]
related: ["../26年项目/体验留存归因.md"]
source_period: "正文无明确实验日期或复核日期"
source_date: null
processed_at: "2026-11-04"
---

# 模型（差体验与乘客流失因果建模）｜来源摘要

> 来源更新/生效日未明确；下载日期不作为内容复核日期。此页为待复核提炼。

## 来源身份与时间

- ID：`knowledge:2209585649315`
- 原始目录：07. 技术沉淀 / 技术建设2026 / Attribution / 归因 / 模型
- [Cooper原文](https://cooper.didichuxing.com/knowledge/2199610335356/2209585649315)
- [不可变本地快照](../../raw/cooper/knowledge-2209585649315.md)
- SHA-256：`fde68297a06b4564cd2f39e06ec8743f315fce9c974d61bbd3c2ff36361cbcdd`
- 时间范围：正文无明确实验日期或复核日期

## 问题

预测差体验与流失关系，并估计某差体验下降1pp时对流失的反事实影响，希望表达置信程度。

## 机制

用差体验比例映射到[0,1]作为连续Treatment；讨论反事实支持不足、协变量淹没Treatment、多Treatment相关、DR纠偏、前期差体验对活跃窗口影响。比较VCNet、多维连续DML、DRCFR。

## 证据

区分需要真实个体效应的PEHE/ATE/ATT/MISE/ADRF AMSE/Policy Regret，与无个体真值时的Qini/AUUC、DR、RATE/AUTOC等；提出用真实W构造T/Y的合成数据方向。

## 状态

选型与评价框架草稿，无已选定生产模型、估计结果或业务增量。

## 限制与待确认

公式在图片中未解析；多Treatment相关原文标暂不考虑。缺失识别假设、混杂变量、重叠性检验、窗口定义与可验证反事实效果，不能把相关性当因果。

## 重要章节

要解决问题；难点；模型选型；指标；备注

## 关联页面

- [体验留存归因](../26年项目/体验留存归因.md)
