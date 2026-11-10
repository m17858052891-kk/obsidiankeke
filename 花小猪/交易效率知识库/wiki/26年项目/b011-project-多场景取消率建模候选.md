---
title: "B011 项目候选：多场景取消率建模"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: historical
last_reviewed: null
permission_scope: team
source_key: "b011-project-multiscene-cancel-model"
source_ids:
  - "knowledge:2202536611628"
  - "knowledge:2202664805862"
related:
  - "聚合应答预期.md"
  - "分单召回优化.md"
---

# B011 项目候选：多场景取消率建模

> 历史建模方案和离线评估；没有 2026 年项目状态、线上收益或现网版本证据。

## 候选问题

扩播和连环派的样本量少，单场景乘客或司机取消模型不稳定。两份文档尝试引入常规场景样本，通过 PEPNet 或多场景多任务与 Experts Selector 共享信息，同时降低场景间的跷跷板风险。

## 历史方案与离线结果

- PEPNet 方案用 EPNet 对不同 domain 做 embedding 个性化，用 PPNet 对预测网络参数个性化。
- 多场景多任务方案把场景和任务联合建模，以专家选择缓解小样本场景表现。
- 原文声称多场景建模改善小样本场景离线性能，但没有足够线上 AB 证据支持推全结论。

## 进入 2026 规划前的门槛

1. 固定场景、标签和样本时窗，重跑单场景、共享底座和个性化网络的同口径离线对比。
2. 单独报告扩播、连环派、常规分单的 AUC、校准和样本覆盖，不用总体指标掩盖小场景退化。
3. 线上以策略筛选准确率、取消率、CR 和公平性为联合验收，且保留回滚对照。

## 覆盖缺口

模型结构图未解析；部分表格虽在文本快照中，但未按现网数据重现。当前页不能证明模型已部署或已产生线上增益。

## 原始来源

- [自营多场景乘客取消率建模](../../raw/cooper/knowledge-2202536611628.md)
- [多场景多任务数据建模—司机乘客取消 V1](../../raw/cooper/knowledge-2202664805862.md)

