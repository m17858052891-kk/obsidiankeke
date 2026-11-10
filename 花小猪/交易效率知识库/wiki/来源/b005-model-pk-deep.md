---
title: "B005 模型来源：PK可解释深度模型"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: draft
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2205042583153", "cooper:knowledge:2206536768826", "cooper:knowledge:2207183783077"]
related: ["../模型/PK模型谱系.md"]
---

# B005 模型来源：PK可解释深度模型

方案以Deep提取乘客与供需画像，Wide保留订单、司机和司乘差异化特征，分别输出乘客、司机履约分；二者在模型外线性融合。方案列出的实验是80%旧LR对照和4个5%权重组，属于实验设计，不是结果。

v1.1离线材料明确指出新旧模型样本空间不同，离线难直接比较，线上表现取决于加权方式。v1.2因旧LR对距离权重加倍造成对照接驾距离较小，尝试把新模型距离特征减半；单任务AUC结论未变，但融合后联合履约仍不如单LR。不能把单任务提升写成整体打分提升。

## 原始来源

- [结构升级方案](../../raw/cooper/knowledge-2205042583153.md)（sha256 `f1e6398e48ab70123d7453c0559242ca19ef7a462d66d718f47caa8b64653b4d`）
- [v1.1离线评估](../../raw/cooper/knowledge-2206536768826.md)（sha256 `a00e3e889467994e3de40bd7f0b36d0718e5e14ec27bdd3f36898e288a61a2b1`）
- [v1.2离线评估](../../raw/cooper/knowledge-2207183783077.md)（sha256 `bdc7c91baa57a370c6c5b82ea7bb1f480a8e11fcd70d106ecf37649fe870f533`）
