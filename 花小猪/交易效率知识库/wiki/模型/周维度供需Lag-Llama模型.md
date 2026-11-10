---
title: "周维度供需 Lag-Llama 模型"
type: model-card
owner: "@tommywujian"
freshness: watch
status: offline-evidence
last_reviewed: null
permission_scope: team
source_key: "knowledge:2204046581122"
source_ids: ["knowledge:2204046581122"]
source_url: "https://cooper.didichuxing.com/knowledge/2199610335356/2204046581122"
provenance: "B020 通读 LR25044；模型介绍、离线实验与上线流程说明分开"
related: ["动调成交率触发模型.md"]
---

# 周维度供需 Lag-Llama 模型

## 任务与结构

任务是预测全国及重点城市下周中/周末呼叫趋势，为周资源分配提供输入。Lag-Llama 是 decoder-only 单变量概率时序基座模型，使用滞后与时刻特征、窗口标准化和 Student-t 分布头；本项目上下文长度记录为 365，并在分布损失外尝试趋势 loss。

## 离线发现

来源比较 Lag-Llama、历史同期 baseline、LGBM 和 TimXer。正文称 Lag-Llama 数值准确性优于 baseline，但不同周期稳定性仍低；引入天气、事件等外部特征的 TimXer 未优于仅日期特征版本。对“每次预测大多数城市同向性均超过 80%”的要求，文档给出不可行性分析，不能把单次最好结果外推为稳定保证。

## 状态边界

文档包含 EVE 发布流程说明，但未提供可核验的生产服务、实际资源决策收益或当前线上版本。因此本页只标为离线证据，不宣称已生产使用。

## 覆盖缺口

50 张图片和外部论文/模型链接未解析；评估表中的完整数值、数据泄露检查、节假日策略和当前调用关系待补。

## 来源

- [LR25044 原文](../../raw/cooper/knowledge-2204046581122.md)
