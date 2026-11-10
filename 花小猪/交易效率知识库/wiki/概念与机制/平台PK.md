---
title: "平台PK"
type: concept
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:common/trading-strategy-introduction.md"
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/index.md"
  - "knowledge:2201642828464"
  - "knowledge:2203145965400"
  - "knowledge:2205690365368"
  - "knowledge:2203884869251"
related:
  - "../模型/CAA履约率模型.md"
  - "../指标/pk-win-rate.md"
  - "../指标/absolute-pk-win-rate.md"
  - "../26年项目/PK优化.md"
---

# 平台PK

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

平台 PK 在举手候选间选择胜者，兼顾履约、接驾成本和业务约束。来源描述的窗口机制是首个举手进入窗口，持续比较候选，窗口结束输出胜者；only 场景通常直接胜出。

PK 分可由预估司乘履约概率结合业务倾斜/管控组成，具体公式、参数、阈值和当前服务版本待补。动态窗口通过增加候选的收益与应答前等待成本进行权衡。

## 动态窗口的历史机制

历史 V0/V1 材料把固定 4 秒窗口改写为最优停止问题：首个司机举手后开始计时；后续司机继续与当前胜者比较；当模型判断当前候选满足停止条件时提前结束，否则在最长窗口到期后输出胜者。Top1 判断并不让该司机直接胜出，仍需与当前胜者按 PK 分比较，以保留履约之外的倾斜与管控因素。

证据显示目标经历过至少三种口径：4 秒内最终 PK 胜者、4 秒内预估接驾时长最短者，以及后续方案中的 only 举手完备性、接驾距离、司乘履约率或乘客取消率。它们的标签空间和收益函数不同，不应混写为同一模型版本。only 举手前置模型只在首个司机举手时判断举手完备性；动态时停模型则在每次候选变化后决定是否停止，另有“高乘客取消风险时允许延长到 8 秒”的历史分支。

## 阈值与覆盖合同

阈值不是单纯按 AUC 选择。历史阈值表给出两类合同：全国统一阈值 0.91 时策略触发率约 32.43%、精准率约 94.36%、召回率约 37.39%；分城市阈值则先把各城触发率约束在 25%～60%，再选择精准率接近 95% 的阈值，汇总触发率约 29.76%、精准率约 94.48%、召回率约 34.36%。该表未给训练/验证切分、低样本城市稳定性和线上阈值版本，因此只能作为历史离线选择规则。

## 离在线一致性门槛

2025 年历史校验覆盖两类服务：单商家举手概率 `pk_hxz_finish_rate_6 / pk_only_handsup_model_v1` 与司乘履约多任务 `pk_multitask_model / v1`。70 个司机 DUFE 特征的离在线 diff 被记录为 0，其余 28 个供需、16 个乘客、24 个司机实时特征的分布被描述为基本一致。27 个传入特征中，`cur_win_hands_up_time` 曾因工程放量配置自 1 月 9 日起错误置 0，2 月 18 日修复；来源按训练时间、城市和非零比例估算影响面“基本为 0”，但未提供独立复算。

一致性页还记录：only 举手模型的线上分数与离线复算一致；多任务模型因线上输出为未校准 logit、离线侧为 sigmoid 后概率，先做 sigmoid 后差值才接近 0。该结论只证明抽样复算的历史一致性，不等于当前服务仍在运行，也不覆盖全量日志、延迟、缺失和异常流量。

取消改善不等于 PK 胜率立刻提高：还受竞争者变化、距离、密度、参与数量等相对竞争因素影响。应区分 only/both 结构与 both 中绝对胜出率。

## 来源

- [trading-strategy-introduction.md](../../raw/department-baseline/common/trading-strategy-introduction.md)（快照 commit `a27b537`）
- [index.md](../../raw/department-baseline/directions/trading-efficiency/index.md)（快照 commit `a27b537`）
- [PK 动态窗口策略 V0](../../raw/cooper/knowledge-2201642828464.md)
- [PK 动态窗口策略 V1 方案](../../raw/cooper/knowledge-2203145965400.md)
- [PK 动态窗口 V1 阈值选择](../../raw/cooper/knowledge-2205690365368.md)
- [PK 动态窗口 V1 一致性校验](../../raw/cooper/knowledge-2203884869251.md)

## 关联页面

- [CAA履约率模型](../模型/CAA履约率模型.md)
- [pk-win-rate](../指标/pk-win-rate.md)
- [absolute-pk-win-rate](../指标/absolute-pk-win-rate.md)
- [PK优化](../26年项目/PK优化.md)
