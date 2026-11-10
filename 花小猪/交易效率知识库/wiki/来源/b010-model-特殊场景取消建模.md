---
title: "B010 模型来源：特殊场景取消建模"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: draft
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2201611191632"]
related: ["../模型/商家取消与流失模型.md"]
---

# B010 模型来源：特殊场景取消建模

材料针对扩播与连环派样本稀疏问题，比较 XGBoost、PLE 和 PPNet。扩播加非扩播样本下，扩播乘客取消 AUC 分别为 0.6485、0.649、0.6511；加入连环派后，XGBoost 的扩播/连环派 AUC 为 0.6523/0.6962，PPNet 为 0.656/0.6906，PLE 为 0.653/0.6862。

这组数字仅是特定离线样本与切分下的 AUC：PPNet 在扩播项较高，而 XGBoost 在连环派项较高，不能声称某一架构全面领先。正文未给出线上实验结论；架构图片和若干附件未解析，也不能据名称把 PPNet 与其他材料中的 PEPNet 合并为同一模型。

## 原始来源

- [特殊场景取消率多场景建模记录](../../raw/cooper/knowledge-2201611191632.md)（sha256 `9c415c5a42eabce65db41a7cdc76cc7aae41bcf89aa1f0464f494746960315ca`）
