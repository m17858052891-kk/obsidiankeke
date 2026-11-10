---
title: "多模型实验｜Cooper来源摘要"
type: "source"
owner: "@tommywujian"
freshness: "watch"
status: "proposed"
last_reviewed: null
permission_scope: "team"
source_ids: ["knowledge:2209768345955"]
related: ["../模型/PEPNet与序列履约模型.md", "../模型/DO价值模型.md", "../26年项目/DO价值建模.md"]
source_period: "目录祖先含“多任务模型-2026-08-27”；本页实验日期未明确"
source_date: null
processed_at: "2026-11-04"
---

# 多模型实验｜来源摘要

> 来源更新/生效日未明确；下载日期不作为内容复核日期。此页为待复核提炼。

## 来源身份与时间

- ID：`knowledge:2209768345955`
- 原始目录：07. 技术沉淀 / 技术建设2026 / 多任务模型-2026-08-27 / PEPNet / 多模型实验
- [Cooper原文](https://cooper.didichuxing.com/knowledge/2199610335356/2209768345955)
- [不可变本地快照](../../raw/cooper/knowledge-2209768345955.md)
- SHA-256：`d14c0ea8e0f2276cbe04749ba26a52f67d1c69dc8b2af51a3b68f87cada673c5`
- 时间范围：目录祖先含“多任务模型-2026-08-27”；本页实验日期未明确

## 问题

在OD/O/D三任务下寻找兼顾离线AUC和连环派/非连环派显式domain约束的骨架。

## 机制

比较STAR、DTN、HyFormer、AutoMTL。HyFormerDomain将binary从普通静态token拆出，独立domain embedding条件化司乘query，共享主干后使用分任务分域adapter/head并硬路由。

## 证据

HyFormer均值AUC 0.7760；HyFormerDomain为0.7582/0.7560/0.8330、均值0.7824，相对普通HyFormer均值+0.64pp。STAR改动仅小幅变化；DTN相对同期PEP01均值-1.11pp。

## 状态

本文阶段性离线结果；建议同训练预算复验，不等于已替换生产模型。

## 限制与待确认

STAR缺严格单变量基线。不同路线用不同对照，不能将所有差值相加。训练验证时间、样本规模、随机重复与在线影响未给出；图片结构未解析，仅使用文字描述。

## 重要章节

1、本阶段结论；2、模型结构；3.1 STAR；3.2 DTN/HyFormer/AutoMTL；3.3 HyFormer显式Domain改造

## 关联页面

- [PEPNet与序列履约模型](../模型/PEPNet与序列履约模型.md)
- [DO价值模型](../模型/DO价值模型.md)
- [DO价值建模](../26年项目/DO价值建模.md)
