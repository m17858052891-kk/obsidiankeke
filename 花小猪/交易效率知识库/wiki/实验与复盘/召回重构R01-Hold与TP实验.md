---
title: "召回重构 R01 Hold 与 TP 实验"
type: analysis
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_key: b018-evidence-recall-r01
source_ids: ["cooper:knowledge:2209439031695"]
source_url: "https://cooper.didichuxing.com/knowledge/2199610335356/2209439031695"
related: ["召回重构V1项目复盘.md", "召回重构V1.0.2时间片实验复盘.md"]
---
# 召回重构 R01 Hold 与 TP 实验

## 实验设计

R01 以四组交叉比较 Hold 力度和 TP 放宽，并同时跟踪召回份额、距离、等待、连环派份额、完单与取消。其核心假设是把部分取消从应答后前移到应答前，以降低总等待；但 Hold 过强会损伤完单。

## 历史结果

组 1 与组 2 的比较显示，较弱 Hold 时完单约不显著 -0.58%、CR 显著 +0.15pp；更强 Hold 时完单显著 -0.76%、CR 显著 -0.45pp，虽然距离下降更大。材料据此将后续 Hold 参数放在两者之间。TP 放宽和距离单调 CAA 的结果仍不确定：它们会改变连环派份额，可能拉高司机接驾时长，不能只凭距离下降判好坏。

## 离线与线上边界

后续离线 CAA v5 加入距离惩罚，但原文也提示分连环派 AUC 异常，需要继续排查。该页记录的是实验决策过程，不代表新 CAA 或 TP 参数已经全量；35 张图片、外部配置和部分显著性计算未独立复核。

## 来源

- [R01 0822—0823 实验记录](../../raw/cooper/knowledge-2209439031695.md)

