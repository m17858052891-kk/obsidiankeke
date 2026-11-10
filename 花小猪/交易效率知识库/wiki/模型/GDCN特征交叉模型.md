---
title: "GDCN特征交叉模型"
type: model-card
owner: "@tommywujian"
freshness: watch
status: historical-offline
last_reviewed: null
permission_scope: department
source_ids: ["knowledge:2202074118400", "knowledge:2202140088579"]
related: ["PK模型谱系.md", "PEPNet与序列履约模型.md"]
---

# GDCN特征交叉模型

> 两份短材料的技术调研与离线点值，不代表当前 PK 结构或线上收益。

## 结构候选

GDCN 材料把它描述为在 DCNv2 各交叉层增加门控网络，选择保留或削弱交叉信息。材料同时提示门控链路可能带来类似循环结构的梯度衰减风险，但关键结构主要由三张未解析图片承载，无法从正文还原完整网络和参数量。

## 离线证据

- 一份未给出任务背景、样本与时间的表格记录分类 AUC：XGB 69.926、GDCN 70.491；回归行缺少有效结果。
- 另一份 PK 短表记录训练期 03/04—03/24、验证期 03/25—03/31，finish AUC 为 XGB 0.80591、AutoInt+PLE 0.80618、GDCNS+PLE 0.82374。

两表缺少年份、标签、样本过滤、特征、超参、置信区间和复现信息，且指标尺度与任务口径未证明一致，不能据此跨表排序或外推线上效果。

## 模型合同缺口

- GDCN/GDCNS 命名、与 PLE 的组合位置及门控公式。
- 完单标签、候选司机样本域、训练/推理特征和冷启动处理。
- 参数量、延迟、稳定性、校准、时间外验证与线上实验。
- 图片中的结构与实验表尚未解析，外链内容未纳入证据。

## 来源与关联

- [GDCN](../../raw/cooper/knowledge-2202074118400.md)
- [PK模型](../../raw/cooper/knowledge-2202140088579.md)
- [PK模型谱系](PK模型谱系.md)

