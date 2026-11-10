---
title: "交易分类 Transformer 升级探索"
type: model-card
owner: "@tommywujian"
freshness: watch
status: offline-exploration
last_reviewed: null
permission_scope: department
source_ids: ["knowledge:2207491852262"]
related: ["多场景司乘取消PEPNet.md", "PEPNet与序列履约模型.md", "模型特征与上线合同.md"]
processed_at: "2026-11-04"
---

# 交易分类 Transformer 升级探索

> 这是基于 Qwen3 的结构与训练框架探索。离线表中的“线上模型”是对照名称，不等于本方案已上线；正文未给业务场景、样本切分、线上实验或发布记录。

## 结构方案

面向二分类任务，方案去掉 causal mask，并加入 CLS token 汇聚特征交叉信息。候选结构包括 token 分类、双塔、token freeze 分类，以及 CLS/average pooling。针对不同业务字段可能共享同一 embedding 而语义折叠的问题，材料提出用位置编码区分特征，或为不同字段使用非共享 `Wq/Wk/Wv`。

方案把后续结构迭代统一到 Qwen3，并把可配置项集中在 `config_model.yaml`。具体网络图和代码结构只存在于未解析图片中，无法从本地正文恢复完整张量、输入序列、损失和推理接口。

## 训练工程与离线记录

0.03B 模型的历史训练对照记录为：标准 attention + FP32 使用 90G、38 小时；FlashAttention + mixed precision 使用 40G、20 小时。该表未给硬件、卡数、批量、数据量和重复次数，只能视为单次工程记录。

离线表记录 0.003B 对照模型 AUC 0.8722、attention baseline AUC 0.8067，以及不加入取消信息的单塔模型 AUC 0.6958。由于样本、标签、切分、参数量和训练条件不完整，不能把差值单独归因于取消信息或结构。

## 验收缺口

- [ ] 明确预测目标、取消信息的观察时点和是否存在标签泄露。
- [ ] 补齐数据切分、类分布、校准、分场景稳定性和显著性。
- [ ] 补齐训练硬件、吞吐、推理延迟、成本和降级方案。
- [ ] 图片中的模型图、配置结构和代码组织未解析；无线上实验和生产版本证据。

## 来源

- [模型升级](../../raw/cooper/knowledge-2207491852262.md)

