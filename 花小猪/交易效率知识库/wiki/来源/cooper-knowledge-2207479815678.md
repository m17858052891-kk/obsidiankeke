---
title: "onetrans实验结果｜Cooper来源摘要"
type: "source"
owner: "@tommywujian"
freshness: "watch"
status: "proposed"
last_reviewed: null
permission_scope: "team"
source_ids: ["knowledge:2207479815678"]
related: ["../模型/PEPNet与序列履约模型.md", "../26年项目/DO价值建模.md"]
source_period: "正文未给实验日期；含验证bug修复前后两组结果"
source_date: null
processed_at: "2026-11-04"
---

# onetrans实验结果｜来源摘要

> 来源更新/生效日未明确；下载日期不作为内容复核日期。此页为待复核提炼。

## 来源身份与时间

- ID：`knowledge:2207479815678`
- 原始目录：07. 技术沉淀 / 技术建设2026 / [前人工作]多任务模型改进 / onetrans实验结果
- [Cooper原文](https://cooper.didichuxing.com/knowledge/2199610335356/2207479815678)
- [不可变本地快照](../../raw/cooper/knowledge-2207479815678.md)
- SHA-256：`94f221e0cfb85feae7761547ca11a50e0fdfbf4909c312da07ad3e546a9f7675`
- 时间范围：正文未给实验日期；含验证bug修复前后两组结果

## 问题

比较 PLE、PEPNet 与 OneTrans/序列融合，并记录只验证一个batch的bug修复。

## 机制

探索序列分支、8层tower、warmup、司机/乘客单侧序列及OneTrans。必须区分修复前记录与“修改只验证一个batch的bug”之后的完整验证表。

## 证据

修复后epoch9：PLE-no-seq 0.7150/0.7259/0.7500，PLE-OneTrans 0.7350/0.7258/0.7972；OD绝对+2.00pp、D+4.72pp，O约持平。PEP-seq为0.7421/0.7339/0.8036，PEP-seq-OneTrans为0.7503/0.7613/0.8697。仅文档内同表比较。

## 状态

离线实验记录，存在评估实现修复，无线上AB或部署确认。

## 限制与待确认

原文将0.715→0.735写为+2.8pp，将0.7500→0.7972写为+6.3pp，混淆相对百分比与AUC绝对百分点；摘要按表值重算并说明。修复前AUC不可与修复后直接比较，数据集与随机种子仍缺失。

## 重要章节

PepNet结果；PLENet；修改只验证一个batch的bug：ple/pep

## 关联页面

- [PEPNet与序列履约模型](../模型/PEPNet与序列履约模型.md)
- [DO价值建模](../26年项目/DO价值建模.md)
