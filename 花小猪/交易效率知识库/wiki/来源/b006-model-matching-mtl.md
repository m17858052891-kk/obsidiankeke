---
title: "B006 模型来源：匹配多任务模型"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: draft
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2209283010086"]
related: ["../模型/匹配V1多任务模型.md"]
---

# B006 模型来源：匹配多任务模型

匹配 V1.0 将召回阶段可用特征共同输入 Grab、PK、Outcome 三个 Head，并用各 Head 相对基线的归一化 Loss 组合搜索指标。候选晋级要求包含总体提升、Outcome 不退化和 Grab/PK 退化上限。

材料中的 PLE 与 GradNorm 比较属于离线架构搜索。三个任务的有效样本掩码不同，Loss 下降会受样本波动影响；收益小可能来自强基线、有限新增信息、历史选择偏差或训练参数，而不能仅归因为样本不足。原文未提供可核验的线上部署与收益结论。

## 原始来源

- [匹配V1.0模型](../../raw/cooper/knowledge-2209283010086.md)（sha256 `5352af4145555d90f4e4fb464a857dd43e6eac511ed2717148a3ba462bde2242`）

