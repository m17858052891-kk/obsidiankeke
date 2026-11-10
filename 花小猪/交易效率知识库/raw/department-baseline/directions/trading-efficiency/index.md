---
title: 交易效率方向总览
type: direction
owner: "@tommywujian"
freshness: watch
status: active
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - cooper:https://cooper.didichuxing.com/docs2/document/2207271198956
related:
  - metric/index.md
  - ../../common/trading-strategy-introduction.md
---

# 交易效率方向总览

> 团队定位:打造以 **乘客交易质量(ETP)与司机接单效率**为直接目标、交易质量(应答时长、接驾距离、改派、取消等)为间接过程的聚合交易系统。26 年核心 focus:**双边交易效率 & 乘客体验**。目标与项目以 [交易效率方向源文档](https://cooper.didichuxing.com/docs2/document/2207271198956) 为准。

## 文档目录

### Cooper

- [交易效率方向源文档](https://cooper.didichuxing.com/docs2/document/2207271198956)
- [平台交易](https://cooper.didichuxing.com/team-file/2204461264302/home)
- [交易效率 Cooper](https://cooper.didichuxing.com/knowledge/2199610335356/2208512037161)
- [团队规划总结](https://cooper.didichuxing.com/knowledge/2199610335356/2199613330623)
- [交易策略-策略内部-交易效率方向](https://cooper.didichuxing.com/team-file/2199582756311/2208633130437)

### Git / 知识库

- [策略部门知识库 - trading-efficiency](https://git.xiaojukeji.com/bwh_stg/strategy-dept-knowledge/tree/main/directions/trading-efficiency)
- [工程 git - allmatch-dispatch-go](https://git.xiaojukeji.com/Zeroizer/allmatch-dispatch-go)
- [乘客引导 git - trade-of-passenger](https://git.xiaojukeji.com/bwh_stg/trade-of-passenger)
- [PK git - platform_pk](https://git.xiaojukeji.com/bwh_stg/platform_pk)
- [交易模型 git - trade-model](https://git.xiaojukeji.com/bwh_stg/trade-model)
- [PK 知识库 - pk_strategy_wiki](https://git.xiaojukeji.com/bwh_stg/pk_strategy_wiki)
- [商家交易知识库 - cp_trade_strategy_wiki](https://git.xiaojukeji.com/bwh_stg/cp_trade_strategy_wiki)

## 团队职责

| 职责域 | 具体内容 | 边界/协作接口 |
| --- | --- | --- |
| 召回 / 分单 / PK 算法 | 维护并迭代商家召回(动态播单)、平台 PK(O 选 D 排序、举手司机排序)、分单 / 匹配主流程 | 本方向负责从订单呼叫后到乘客上车的交易匹配全链路 |
| 交易价值建模 | 沉淀履约率(CAA)、应答前取消(cba)、订单流失率、CR、DO 价值等口径与模型 | 公共指标走 `common/metrics/`;本方向只维护方向特有口径 |
| 实验方法论与上线复盘 | 实验设计选型(PID / switchback / 时空聚类)、挤占判定、关键 LR 与方案评审复盘 | 完整 LR 与方案正文留在对应 Wiki;本方向只沉淀方法、口径、风险与可复用结论 |

## 目标

> 来源:[交易效率方向源文档](https://cooper.didichuxing.com/docs2/document/2207271198956)。优化次序:双边效率优先(乘客 ETP / 司机接驾时长),乘客取消率第二,接驾距离为绝对值目标。

| 目标 | 衡量指标/验收标准 | 当前状态/备注 |
| --- | --- | --- |
| 双边交易效率(主背 P0) | ETP + 司机接驾时长 -1.5%;接驾距离绝对值 1650m | 约束:CR 不负 |
| 乘客体验 · 取消率(主背 P0) | delta 乘客取消率 -1.2pp | 远接驾/长应答的极端值占比是体验目标 |
| 成交率与需供比(共背) | 成交率绝对值 75%(P0);拉齐需供比效率 +2pp(P1) | 与司机/调节、行业方向共背 |
| DO 价值建模(技术主背 P1) | 离线收益 + 落地 | 突破 LR;支撑乘客个性化 PK |
| 倾斜额度管控(主背 P1) | 全年倾斜额度不超 | 倾斜对效率/取消/接驾均负向 |

## 重点项目

> 来源:[交易效率方向源文档](https://cooper.didichuxing.com/docs2/document/2207271198956) 与 [交易效率 Cooper](https://cooper.didichuxing.com/knowledge/2199610335356/2208512037161)。人力(规划口径):价值统一 / PK 优化 / DO 价值建模 合计 2;分单召回优化 / 匹配联合决策 合计 1.5;体验留存归因 0.5;乘客交易(含换车) 0.2;解法统一 吴健 0.3。

| 项目 | 项目目标 | 关键里程碑计划 | 关联知识沉淀 |
| --- | --- | --- | --- |
| 交易价值统一(P0) | 交易策略配置 / 解法收敛至平台侧;平台规范全链路(分发指导 → 分单遵循 → PK 执行 → 乘客透传);司机价值准入(F_j vs F_∅) | Q1:平台规范 + 价值统一 V1.0 上线;Q2:cba 应答前取消模型落地;Q3:召回 + PK 联动复盘 | 来源:[交易效率 Cooper](https://cooper.didichuxing.com/knowledge/2199610335356/2208512037161)、[交易策略-策略内部-交易效率方向](https://cooper.didichuxing.com/team-file/2199582756311/2208633130437);代码/知识库:[platform_pk](https://git.xiaojukeji.com/bwh_stg/platform_pk)、[allmatch-dispatch-go](https://git.xiaojukeji.com/Zeroizer/allmatch-dispatch-go);待沉淀:`technical-designs/`、`model-cards/`、`experiments/` |
| PK 优化(P0) | 落实「约束履约率最小化接驾距离」v1.1;CAA 考虑已等时长 / 被取消次数;乘客个性化 PK | Q1:v1.1 wide&deep 全量;Q2:新版履约率 / CAA 模型迭代;Q3:乘客个性化上线复盘 | 来源:[平台交易](https://cooper.didichuxing.com/team-file/2204461264302/home)、[交易效率 Cooper](https://cooper.didichuxing.com/knowledge/2199610335356/2208512037161);代码/知识库:[platform_pk](https://git.xiaojukeji.com/bwh_stg/platform_pk)、[pk_strategy_wiki](https://git.xiaojukeji.com/bwh_stg/pk_strategy_wiki)、[trade-model](https://git.xiaojukeji.com/bwh_stg/trade-model);待沉淀:`model-cards/`、`technical-designs/` |
| DO 价值建模(P0) | 突破 LR(模型对齐保留可解释);支撑乘客个性化 PK 与 D 选 O 价值;特征交叉、序列建模 | Q1:建模难度调研;Q2:拿到离线收益;Q3:落地 | 来源:[团队规划总结](https://cooper.didichuxing.com/knowledge/2199610335356/2199613330623)、[交易效率 Cooper](https://cooper.didichuxing.com/knowledge/2199610335356/2208512037161);代码/知识库:[trade-model](https://git.xiaojukeji.com/bwh_stg/trade-model)、[platform_pk](https://git.xiaojukeji.com/bwh_stg/platform_pk);待沉淀:`model-cards/`、`experiments/` |
| 分单召回优化(P0) | 商家召回主流程维护与优化;漏斗考虑订单流失;品类透出改乘客价值导向(降乘客取消、提 CR) | Q1:线上主流程更新频率 / 维护状态摸清;Q2:召回优化方案;Q3:实验复盘 | 来源:[交易策略-策略内部-交易效率方向](https://cooper.didichuxing.com/team-file/2199582756311/2208633130437);代码/知识库:[allmatch-dispatch-go](https://git.xiaojukeji.com/Zeroizer/allmatch-dispatch-go)、[cp_trade_strategy_wiki](https://git.xiaojukeji.com/bwh_stg/cp_trade_strategy_wiki);待沉淀:`algorithms/`、`experiments/` |
| 匹配联合决策(P0) | 统一派单模式 / 匹配 / 一播多联合优化,趋向全局最优;tp / GS 考虑竞争胜率,D 选 O 前置验证 | Q1:明确优化目标与约束;Q2:联合决策方案;Q3:沉淀风险红线 | 来源:[平台交易](https://cooper.didichuxing.com/team-file/2204461264302/home)、[交易效率 Cooper](https://cooper.didichuxing.com/knowledge/2199610335356/2208512037161);代码/知识库:[allmatch-dispatch-go](https://git.xiaojukeji.com/Zeroizer/allmatch-dispatch-go)、[platform_pk](https://git.xiaojukeji.com/bwh_stg/platform_pk);待沉淀:`algorithms/`、`technical-designs/` |
| 体验留存归因(P0) | 回答交易体验(应答时长、接驾距离的极端值)如何影响乘客留存 | Q1:MTA 多触点归因 / LTV 建模选型;Q2:差体验 → 留存影响量化;Q3:沉淀交易体验价值口径 | 来源:[团队规划总结](https://cooper.didichuxing.com/knowledge/2199610335356/2199613330623);代码/知识库:[trade-model](https://git.xiaojukeji.com/bwh_stg/trade-model);待沉淀:`concepts/`、`model-cards/`、`experiments/` |
| 乘客交易 | 乘客侧交易策略(换车、升舱透传等);其中**换车**:降接驾距离,探索商家出钱升舱换车 | 今年完成梳理 | 来源:[交易效率 Cooper](https://cooper.didichuxing.com/knowledge/2199610335356/2208512037161)、[交易策略-策略内部-交易效率方向](https://cooper.didichuxing.com/team-file/2199582756311/2208633130437);代码/知识库:[trade-of-passenger](https://git.xiaojukeji.com/bwh_stg/trade-of-passenger);待沉淀:`concepts/`、`experiments/` |
| 交易策略解法统一(吴健) | 统一交易策略解法,阈值策略由当前多个收敛至 2 个 | Q1:盘点端分发/召回/派单模式/topspeed/换车/PK 窗口阈值;Q2:解法统一方案;Q3:逐步替换 | 来源:[交易效率方向源文档](https://cooper.didichuxing.com/docs2/document/2207271198956)、[交易策略-策略内部-交易效率方向](https://cooper.didichuxing.com/team-file/2199582756311/2208633130437);代码/知识库:[策略部门知识库 - trading-efficiency](https://git.xiaojukeji.com/bwh_stg/strategy-dept-knowledge/tree/main/directions/trading-efficiency);待沉淀:`concepts/`、`playbooks/` |

## 技术栈

| 领域 | 主要技术 / 工具 | 代码 / 知识库 |
| --- | --- | --- |
| 召回 / 播单 | 动态播单、需供比 / 供需比、订单流失率、多场景多任务模型(PPNet) | [allmatch-dispatch-go](https://git.xiaojukeji.com/Zeroizer/allmatch-dispatch-go)、[cp_trade_strategy_wiki](https://git.xiaojukeji.com/bwh_stg/cp_trade_strategy_wiki)、[交易策略-策略内部-交易效率方向](https://cooper.didichuxing.com/team-file/2199582756311/2208633130437) |
| PK 排序 | LR、Wide&Deep、XGBoost、DQN、PLE 多任务;履约率 / CAA 模型;距离置换系数 λ_PK | [platform_pk](https://git.xiaojukeji.com/bwh_stg/platform_pk)、[pk_strategy_wiki](https://git.xiaojukeji.com/bwh_stg/pk_strategy_wiki)、[平台交易](https://cooper.didichuxing.com/team-file/2204461264302/home) |
| 分单 / 匹配 | 派单模式(tp / GS)、一播多、运筹 vs 贪心、竞争胜率、连环派 | [allmatch-dispatch-go](https://git.xiaojukeji.com/Zeroizer/allmatch-dispatch-go)、[platform_pk](https://git.xiaojukeji.com/bwh_stg/platform_pk)、[交易效率 Cooper](https://cooper.didichuxing.com/knowledge/2199610335356/2208512037161) |
| 交易模型 | DO 价值建模(突破 LR)、cba 应答前取消生存分析(Cox + Breslow / Nelson-Aalen 基线 + PCHIP 样条);特征交叉、序列建模;id embedding | [trade-model](https://git.xiaojukeji.com/bwh_stg/trade-model)、[交易模型相关规划](https://cooper.didichuxing.com/knowledge/2199610335356/2199613330623) |
| 乘客交易 / 引导 | 换车、升舱透传、乘客侧交易策略与乘客价值导向透出 | [trade-of-passenger](https://git.xiaojukeji.com/bwh_stg/trade-of-passenger)、[交易效率 Cooper](https://cooper.didichuxing.com/knowledge/2199610335356/2208512037161) |
| 实验设计 | PID(乘客分流)、switchback(时间片)、时空聚类、分流比扫描、对照组退化检查、MRD 双边随机 | [交易效率 Cooper](https://cooper.didichuxing.com/knowledge/2199610335356/2208512037161)、`experiments/` |
| 实验平台 | 评估大师 / 宏鹄、Apollo | [平台交易](https://cooper.didichuxing.com/team-file/2204461264302/home)、[交易策略-策略内部-交易效率方向](https://cooper.didichuxing.com/team-file/2199582756311/2208633130437) |
