---
title: "召回重构 R02：CAA 距离加权实验"
type: analysis
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_ids:
  - "knowledge:2209634599260"
  - "knowledge:2209586715980"
related: ["召回重构R01-Hold与TP实验.md", "召回重构R03-CAA与OCR实验.md", "召回重构重复调用效率分析.md"]
---
# 召回重构 R02：CAA 距离加权实验

## 设计

R02（2026-08-25 至 08-31）用四组交叉比较 CAA v4/v5 与 TP 参数强弱。v5 在取消风险之外引入距离加权；同一模型分别搭配 `gamma=30` 和 `gamma=5000`，用于拆分模型变化与 TP 放宽的影响。

## 历史观察

- v5 相对 v4 稳定降低召回距离与最终应答距离，远距离过滤集中在 2.5km 以上；0—2km 内没有观察到类似 R01 强 Hold 的明显误伤。
- 代价是总体召回强度、覆盖和完单/CR 同时折损。Distinct OD 曾召回率在同 TP 参数比较下约下降 1.86pp 和 2.17pp。
- 订单级结果不能只看“召回且播单”的共现比例：来源明确提示该口径不保证事件顺序；入样订单完单率也只是召回日志样本，不是实验全体 ITT。

## 结论边界

该轮支持“距离惩罚确实改变候选结构”，但不支持“距离下降必然带来交易效率收益”。来源中的评估大师快照、显著性计算和图片未解析，参数仅代表 R02 历史配置；不据此推断当前 CAA 版本或线上参数。

## 来源

- [R02 0825—0831](../../raw/cooper/knowledge-2209634599260.md)
- [召回 PID 实验记录](../../raw/cooper/knowledge-2209586715980.md)

