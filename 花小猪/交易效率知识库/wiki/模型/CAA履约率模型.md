---
title: "CAA履约率模型"
type: model-card
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "cooper:knowledge:2208342470573"
  - "cooper:knowledge:2208522851172"
  - "cooper:knowledge:2209420260734"
  - "cooper:knowledge:2201715881032"
  - "knowledge:2210017050557"
  - "knowledge:2206086951587"
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/index.md"
  - "repo:strategy-dept-knowledge:common/trading-strategy-introduction.md"
related:
  - "../26年项目/PK优化.md"
  - "../指标/fulfillment-rate.md"
  - "../概念与机制/平台PK.md"
---

# CAA履约率模型

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 预测目标与使用位置

预测司乘履约质量，作为平台 PK 的价值依据。

## 来源提供的技术线索

方向规划提到 CAA 迭代考虑乘客已等时长、被取消次数。介绍列出司机/乘客历史取消行为、预计接驾距离时长与特殊场景等候选特征；实际训练特征未核验。

## 版本与上线状态

来源在 PK 技术栈中列 LR、Wide&Deep、XGBoost、DQN、PLE，但未逐一映射当前 CAA 版本，不能据此确定线上架构。

## 待补充的模型契约

- 标签定义、正负样本、采样与时间窗：待补充。
- 训练数据集、特征明细、数据泄露检查：待补充。
- 训练任务、参数、校准、离线评价：待补充。
- 推理服务、调用位置、延迟与降级：待补充。
- 版本变更、线上实验、LR 结论与适用范围：待补充。

本页是来源支持的候选模型卡，不能据此声称模型已上线或有确定收益。

## 来源

- [index.md](../../raw/department-baseline/directions/trading-efficiency/index.md)（快照 commit `a27b537`）
- [trading-strategy-introduction.md](../../raw/department-baseline/common/trading-strategy-introduction.md)（快照 commit `a27b537`）

## 关联页面

- [PK优化](../26年项目/PK优化.md)
- [fulfillment-rate](../指标/fulfillment-rate.md)
- [平台PK](../概念与机制/平台PK.md)

## B006契约补充

新来源将 CAA 明确定义为“已应答后到完单前发生乘客或司机取消的概率”，正样本为应答后取消、负样本为应答后完单。该定义与本页早期“履约率模型”命名方向相反，使用时必须明确输出是取消概率还是其补数，不能仅凭 CAA 名称互换。

特征契约覆盖订单、司机、乘客、等待、价格、时空及连环派特征，并要求召回阶段可取。历史迭代包含距离惩罚、近距离规则和多种结构探索；这些均是候选或历史离线证据，未确认当前线上版本。

- [B006召回价值基础率](../来源/b006-model-recall-foundation.md)
- [B006历史迭代](../来源/b006-model-history.md)

## Cooper首批证据补充

> 来源时间分别记录在来源摘要中；仅新增证据，不将下载日视为复核日。

已取得一份多目标序列履约实验：143维数值+200维司乘序列，PEPNet以EPNet场景门控、三路PPNet和双域六塔建模。原文限定为离线实验。

命名存在必须确认的差异：该文把caa称为“应答后取消率”，方向介绍用CAA指履约率模型。取消概率与履约概率的标签方向不能直接等同；O/D任务字母映射应随每个实验原文保留，不能跨文档推断。三任务与当前PK服务模型的注册/部署对应关系仍未知。

### 本批来源

- [序列建模-司乘履约模型](../来源/cooper-knowledge-2206086951587.md)
- [[BRD]DO价值建模离线探索](../来源/cooper-knowledge-2210017050557.md)

