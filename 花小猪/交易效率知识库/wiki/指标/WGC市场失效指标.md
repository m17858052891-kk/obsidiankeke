---
title: "WGC 市场失效指标"
type: metric
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-11-04
permission_scope: team
source_key: "wgc-market-failure-metric"
source_ids:
  - "knowledge:2207394069241"
source_url: "https://cooper.didichuxing.com/knowledge/2199610335356/2207394069241"
provenance:
  - "raw/cooper/knowledge-2207394069241.md sha256:4f13b1f0cf8b9959f08075bbf14f2942156a8e2c967da4aa77f1a5437ebc6b55"
related:
  - "../26年项目/LR26-005双边市场WGC效率探索.md"
  - "demand-satisfaction-rate.md"
  - "avg-pickup-duration.md"
---

# WGC 市场失效指标

## 指标意图

WGC 指标识别需求上升或供需恶化时，乘客完单体验与司机收入同时下降的“双输”区间。它是城市 × 30 分钟的监测/诊断信号，不是单一线上策略 KPI。

## 来源口径

前置范围：

- 花小猪呼叫量 Top 62 城市；
- 城市 × 30 分钟；
- `CR <= 0.78`；
- 30 分钟呼叫量 `> 544`，且当前呼叫量不低于前一小时两个 30 分钟时段的较小值。

在前置范围内，同时满足以下乘客与司机条件时判为 WGC：

1. 乘客侧满足任一项：CR 一小时环比下降超过 `5pp`、相对前四周同日同时段中位数下降超过 `5pp`、或 CR 绝对值低于 `0.6`；
2. 司机侧按同一参照期计算 B 补前 IPH，下降超过 `2%`，即乘客体验下降没有伴随司机收入改善。

```text
B补前 IPH = 30min 内司机 B补前实收总额 / 30min 内司机总在线小时
B补后 IPH = 30min 内司机 B补后实收总额 / 30min 内司机总在线小时
```

来源还对 B 补前/后 IPH 口径做过旧版敏感性分析，两种判定重合率约九成；这不等于两者可以在看板或实验中任意混用。

## 诊断变量

来源同时监测 TSH、需供比、服占比、计占比、CPM、IPH、完单率、司机取消率、预估/实际接驾时间、预估接驾距离、应答前后取消和车速等 17 类变量。WGC 的 IPH 可进一步写成：

```text
IPH = 补贴因子 × CPM × 车速 × 计占比
```

该乘法拆解用于解释收入变化，不能把拆解贡献直接当成独立因果效应。

## 使用限制

- `0.78 / 544 / 5pp / 2% / 0.6` 都是特定历史回溯形成的来源阈值，接入生产前需核对最新结果表和城市清单。
- 原始报告明确采用旧口径展示部分结果；Wiki 不把 `5.185%` 影响订单比例写成当前线上基线。
- NOTEARS/DYNOTEARS 是探索性结构学习，受隐藏混杂、线性和局部平稳假设约束。
- 59 张图片和外链表格尚未解析；SQL、看板字段、异常过滤和当前运行状态待补证据。

## 来源

- [LR26-005 原始快照](../../raw/cooper/knowledge-2207394069241.md)

## 关联页面

- [LR26-005 双边市场探索](../26年项目/LR26-005双边市场WGC效率探索.md)
- [需求满足率](demand-satisfaction-rate.md)
- [平均实际接驾时长](avg-pickup-duration.md)
