---
title: "B004 证据摘要：多标签应答率模型评估"
type: source
owner: "@tommywujian"
freshness: watch
status: completed
last_reviewed: null
permission_scope: team
source_ids:
  - "cooper:knowledge:2199613447206"
related:
  - "../实验与复盘/多标签应答率离线评估.md"
---

# B004 证据摘要：多标签应答率模型评估

## 来源定位

- 原始正文：[多label应答率模型试验效果](../../raw/cooper/knowledge-2199613447206.md)。
- 材料比较一个多输出神经网络与三个独立 XGB 模型在 30、120、300 秒窗口的离线预测表现。

## 结果摘要

三个时间窗中，两类模型的 AUC、Accuracy、Precision 和 Recall 接近。AUC 分别约为：300 秒 XGB 0.928、NN 0.927；120 秒 0.909、0.908；30 秒 0.892、0.890。来源据此认为多输出网络在预测效果相近时具有“一次输出多个时间窗概率”的业务灵活性。

## 证据边界

- 结果是离线比较，不代表在线业务收益或当前线上版本。
- 原文没有置信区间、时间外验证和城市外推结果，“相当”是描述性判断而非等效性检验。
- 原文建议等待聚合表单稳定后再替换线上模型，是条件性建议，不是已完成上线。

