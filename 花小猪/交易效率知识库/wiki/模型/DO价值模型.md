---
title: "DO价值模型"
type: model-card
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "knowledge:2209768345955"
  - "knowledge:2206086951587"
  - "knowledge:2208937143735"
  - "knowledge:2210017050557"
  - "knowledge:2210021577089"
  - "knowledge:2208485358447"
  - "knowledge:2209987713967"
  - "knowledge:2207393277952"
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/index.md"
  - "repo:strategy-dept-knowledge:common/trading-strategy-introduction.md"
related:
  - "../26年项目/DO价值建模.md"
  - "../26年项目/PK优化.md"
  - "../26年项目/匹配联合决策.md"
---

# DO价值模型

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 预测目标与使用位置

支撑乘客个性化 PK 和 D 选 O 的匹配价值，规划突破 LR 并保留可解释性。

## 来源提供的技术线索

方向页提出特征交叉、序列建模、id embedding；这些是规划/技术方向，不等于已完成训练配置。

## 版本与上线状态

Q1 调研、Q2 离线收益、Q3 落地均为历史计划。目标函数、标签、收益证据和当前模型版本待补。

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

- [DO价值建模](../26年项目/DO价值建模.md)
- [PK优化](../26年项目/PK优化.md)
- [匹配联合决策](../26年项目/匹配联合决策.md)

## Cooper首批证据补充

> 来源时间分别记录在来源摘要中；仅新增证据，不将下载日视为复核日。

BRD 将本轮明确为【26常规项目】交易系统架构升级下的离线探索，三任务为司机履约、乘客履约、订单完单；平均 AUC +3.5pp 是目标，不是已实现收益。AutoFE、OneTrans/HyFormer及门控专家/PEPNet为三条探索路线。

v0序列页只给实验入口和外置图，无法补齐实际结构。另一份序列实验提供2025年6月/12月时间切分和PEPNet结果；多模型实验提供HyFormerDomain阶段结果。它们属于不同实验条件，不能直接排序为统一版本演进或宣称当前最优线上模型。DO业务价值与三任务代理预测目标之间的正式映射仍待确认。

LR26-048 对离线探索做了收口：AutoFE 用 LLM 生成并筛选历史统计特征，序列路线比较 OneTrans/HyFormer，多任务路线优化 PLE 并探索 PEPNet。文档记录最终离线方案相对其线上模型离线基线平均 AUC 提升超过 3.5pp 目标，但“放量决策”仍明确为离线实验，后续还要完成特征工程、推理耗时验证和 PK 替换。该证据不能证明 DO 业务价值或线上收益已经实现。

## B019：交易价值统一与模型边界

- “交易价值统一”方案把召回、分单、Hold、PK 的等待成本统一为应答前取消 CBA，并用离散时间生存分析输出 300 个逐秒条件取消概率；首次发单计算并缓存，后续按 3 秒分单/4 秒 PK 窗口聚合。该模型预测无策略干预下的应答前取消风险，不等同于 DO 履约价值模型。
- 样本中的应答订单属于右删失，按到应答时间前仍未取消的信息进入 mask BCE；特征包括乘客画像、历史 CBA、订单与供需。材料仍是方案/工程设计，未给同口径离线结果或线上 AB 结论。
- DO 离线探索 V1 继续以司机履约、乘客履约、订单完单为代理任务，比较 PLE/PEPNet、序列和 AutoFE；不能把 CBA 生存概率与三任务 AUC 混成同一输出。
- 两份材料共 5+4 张未解析图片，评审表、实验结果和当前上线回执不完整。

### 本批来源

- [[BRD]DO价值建模离线探索](../来源/cooper-knowledge-2210017050557.md)
- [DO价值-序列建模](../来源/cooper-knowledge-2208937143735.md)
- [序列建模-司乘履约模型](../来源/cooper-knowledge-2206086951587.md)
- [多模型实验](../来源/cooper-knowledge-2209768345955.md)
- [LR26-048 离线探索汇总](../../raw/cooper/knowledge-2210021577089.md)
- [交易价值统一 V1](../../raw/cooper/knowledge-2208485358447.md)
- [DO价值建模离线探索 V1](../../raw/cooper/knowledge-2209987713967.md)

## B061：交易价值统一 V1 的准入合同

历史方案把流量分发、分单、PK 与乘客引导统一为订单维度的平台价值比较。司机候选价值写为履约概率减去距离惩罚；继续等待的价值同时考虑应答前取消风险、下一轮履约概率和下一轮接驾距离。司机准入条件是当前候选价值高于继续等待价值。

这是一份方案推导，不是已上线模型合同。履约概率来自 PK 履约率模型，应答前取消来自 CBA，下一轮履约与距离用历史分位数近似，距离置换系数复用 PK 参数；正文没有这些输入的版本、校准窗口、样本、显著性、线上配置或发布回执。未解析公式图也可能包含正文未覆盖的约束，因此不能把该方案写成现网事实或确定收益。

- [交易价值统一 V1 导航页](../../raw/cooper/knowledge-2207393277952.md)

