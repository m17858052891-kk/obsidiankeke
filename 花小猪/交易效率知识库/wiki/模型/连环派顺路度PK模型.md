---
title: "连环派顺路度 PK 模型"
type: model-card
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: department
source_ids:
  - "knowledge:2204889857378"
related:
  - "PK模型谱系.md"
  - "连环派司乘取消XGBoost.md"
---

# 连环派顺路度 PK 模型

## 目标与设计

方案希望在 PK 打分中更强地惩罚低顺路连环派，以降低应答后乘客取消。它把司机是否变远、绕路比和上一单终点邻近性组合为绝对顺路、高顺路、低顺路、不顺路四类；绕路比定义为 `(AB+BC)/AC`，方案阈值为 1.2，邻近距离为 200 米，方向夹角阈值为 90 度。

计划新增 `serial_type`、`direct_distance`、`bac_angle`、`acb_angle` 四个 PK 特征，并预期权重均为负。`direct_eta` 和 `detour_ratio` 也列入特征建设表，但没有进入模型优化表，属于接口与训练合同的不一致，需以最终 schema 核验。

## 证据边界

来源正文称连环派在同接驾距离下乘客取消更高、绕路比越高取消越高，并认为旧 PK 分差不足；这些关系主要在未解析图片中，当前文本快照不能复核样本量、控制变量、曲线或显著性。预期负权重是设计约束，不是训练后权重或因果证据。

实验计划采用乘客随机分流，对照为线上 PK、实验为新策略，观察平台 CR/完单/GMV、司乘取消和低顺路连环派占比。来源没有实验结果、放量记录或当前生产状态，因此状态保持 `proposed`。

## 覆盖缺口

- 3 张关键分析图片未解析，BRD/PRD 外链未读取。
- 缺训练样本、标签、损失函数、离线指标、特征缺失值与非连环派哨兵值的线上处理验证。
- 未确认与可解释 LR、Deep&Wide 及连环派取消过滤模型的组合顺序。

## 来源与关联

- [PK 连环派订单乘客取消优化策略方案](../../raw/cooper/knowledge-2204889857378.md)
- [PK 模型谱系](PK模型谱系.md)
- [连环派司乘取消 XGBoost](连环派司乘取消XGBoost.md)

