---
title: "来源：embedding提取-预训练 PDF"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: completed-with-gaps
last_reviewed: "2026-11-05"
permission_scope: department
source_ids:
  - "attachment:01a1a9c1-b937-726d-b4fd-c6be80c677ba"
  - "knowledge:2206496231215"
  - "knowledge:2210341624504"
related:
  - "../模型/TabICL表格预训练与Embedding方案.md"
  - "../模型/git-交易模型代码资产全景.md"
  - "../模型/多场景司乘取消PEPNet.md"
---

# 来源：embedding提取-预训练 PDF

## 来源定位

原 Cooper 页面及用户新建副本均因内容安全策略无法通过 MCP 读取。用户随后导出并在 issue 中提供 4 页 PDF，本页以该附件作为可审计的替代来源；本地不可变快照为 `raw/attachments/embedding提取-预训练.pdf`，SHA-256 为 `05cdb6b10740feb5ca9aeea937b1981bb6cdeaee406081fe05a178b0331cf712`。

正文和四页版式均已检查。来源中出现的个人联系方式不进入 Wiki；图中的迁移学习分类和 TabICL 架构仅转述机制，不复制图片。

## 文档性质

这是一份**前置调研与方案讨论稿**，不是训练完成报告或上线记录。内容分为三层：团队任务与训练痛点、迁移学习/表格基础模型调研、内部预训练方案待决策项。

## 可确认的团队背景

- 数据以表格和文本为主，多模态较少；既有模型覆盖 XGBoost、LR/GBDT、TensorFlow/PyTorch 深度网络、PLE、多任务结构、LLM 与 ONNX 推理。
- 业务任务覆盖取消、履约、完单、呼返、成交、接受、流失召回、价格弹性与用户行为预测，可分为分类、回归、排序、多任务和生成/理解任务。
- 文档归纳的训练痛点包括：任务差异大导致统一表示困难、部分大样本任务欠拟合、小样本任务过拟合或不收敛，以及旧任务经验难以正迁移。

## 调研与方案边界

- 文档重点调研 TabICL：列内分布感知嵌入、行间交互、数据集级 ICL 三阶段结构；同时比较 GBDT、XTAB、CARTE、TabPFN、TabForestPFN 与 TabPFNv2。
- 来源记录了 TabICL 论文的规模、速度、显存和基准指标，但本项目未复现实验；这些数字只能作为“来源所述”，不能升级为内部离线结果。
- 内部方案当前停留在“先复现公开结果，再整理内部数据集”的规划阶段。标签统一、任务难度、预训练配比、下游优先级、列集合、分块 embedding 和增量训练均是待讨论项。
- 文档没有内部训练 run、样本版本、数据切分、checkpoint、离线指标、上线配置、线上实验或收益证据。

## 关联页面

- [[花小猪/交易效率知识库/wiki/模型/TabICL表格预训练与Embedding方案]]
- [[花小猪/交易效率知识库/wiki/模型/git-交易模型代码资产全景]]
- [[花小猪/交易效率知识库/wiki/模型/多场景司乘取消PEPNet]]
