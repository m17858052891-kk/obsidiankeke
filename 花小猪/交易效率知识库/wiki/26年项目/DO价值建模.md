---
title: "DO价值建模"
type: technical-design
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "knowledge:2207479815678"
  - "knowledge:2209768345955"
  - "knowledge:2205745382077"
  - "knowledge:2210017050557"
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/index.md"
related:
  - "../模型/DO价值模型.md"
  - "PK优化.md"
---

# DO价值建模

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 问题与规划目标

突破 LR 并保留解释性，支持乘客个性化 PK 与 D 选 O；研究特征交叉、序列建模。

## 2026 历史计划

Q1：难度调研；Q2：离线收益；Q3：落地。

以上来自方向规划，不是实际完成记录。

`技术建设2026` 又把年度技术探索拆成司乘履约多任务、embedding、样本删失/不平衡、匹配算法和特征挖掘，并给出 M3—M8 的计划节奏。该页同时记录了一组特征交叉与行为序列离线 AUC 点值，但没有样本窗口、置信区间、线上分流或发布回执；因此只作为研发候选与离线观察，不能据时间表认定已经落地。

其中行为序列结果呈现司机相关任务改善、乘客任务可能负向的异质性，说明多任务平均提升不能替代逐任务护栏。匹配算法方向也只写到离线模拟与后续实验计划，尚无线上收益证据。

## 评估约束

方向规划优先考虑乘客 ETP 与司机接驾时长，关注乘客取消、接驾距离；双边效率目标列 CR 不负。具体项目的主指标、护栏、样本范围和成本约束需由项目方案确认。

## 方案演进与当前状态

- 已有证据：方向规划摘要。
- 详细方案、版本替代关系、实际里程碑：待接入原始文档。
- 是否上线、覆盖城市/运力、线上配置与负责人分工：待确认。
- 关联实验/LR、效果量及不确定性：首批新增离线证据见下文，正式LR与线上证据仍待补齐。

## 下一批来源应补齐

原始方案 → 模型/策略版本 → 离线和线上实验 → LR 决策 → 当前部署证据；历史计划不自动晋升为当前结论。

## 来源

- [index.md](../../raw/department-baseline/directions/trading-efficiency/index.md)（快照 commit `a27b537`）

## 关联页面

- [DO价值模型](../模型/DO价值模型.md)
- [PK优化](PK优化.md)

## Cooper首批证据补充

> 来源时间分别记录在来源摘要中；仅新增证据，不将下载日视为复核日。

新增原始BRD：需求owner李昊远、不申请P0、离线实验暂不需要工程介入；三任务平均AUC+3.5pp为目标。方向规划P0与此具体需求“不申请P0”保留为不同层级描述，不能直接覆盖。

离线证据含技术建设规划、序列建模与多模型探索；OneTrans记录出现验证仅一个batch的bug，必须用修复后表。HyFormerDomain文档内均值AUC0.7824，比普通HyFormer+0.64pp；缺线上业务效果和当前生产部署证据。

### 本批来源

- [[BRD]DO价值建模离线探索](../来源/cooper-knowledge-2210017050557.md)
- [技术建设2026](../来源/cooper-knowledge-2205745382077.md)
- [多模型实验](../来源/cooper-knowledge-2209768345955.md)
- [onetrans实验结果](../来源/cooper-knowledge-2207479815678.md)

