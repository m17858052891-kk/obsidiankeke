---
title: "PEPNet 序列建模离线实验"
type: analysis
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_key: b018-evidence-pepnet-sequence
source_ids: ["cooper:knowledge:2206291000614"]
source_url: "https://cooper.didichuxing.com/knowledge/2199610335356/2206291000614"
related: ["多标签应答率离线评估.md"]
---
# PEPNet 序列建模离线实验

## 离线探索

材料比较 PEPNet 在不同序列长度、特征、塔输入和 Batch Size 下的离线 AUC。拆出 O 塔、限制 10 天稀疏样本、只向部分塔输入序列均未稳定提升 O；其中限制样本后一度看似提升 D/OD，但样本只剩不足 10%，等量重做后收益消失。

序列长度 20 和加入时空特征在部分数据集改善 O，但跨 6 月与 12 月数据不稳定。Batch Size 对结果影响很大：材料在两套 2025 数据上记录 256 相对其他配置平均 AUC 提升 5pp 以上，并推测小 Batch 的梯度噪声抑制重复序列特征过拟合。

## 证据边界

这些是离线实验，不是线上收益或生产版本。不同表格存在重复实验名与数据集差异，不能跨行直接比较；训练代码、实验平台配置和当前部署状态未复核。

## 来源

- [序列建模实验](../../raw/cooper/knowledge-2206291000614.md)
