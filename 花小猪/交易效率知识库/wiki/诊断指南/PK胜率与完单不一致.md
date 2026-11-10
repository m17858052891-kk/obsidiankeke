---
title: "PK胜率与完单不一致的排查"
type: diagnostic
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:common/trading-strategy-introduction.md"
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/pk-win-rate.md"
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/absolute-pk-win-rate.md"
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/fulfillment-rate.md"
related:
  - "../指标/pk-win-rate.md"
  - "../指标/absolute-pk-win-rate.md"
  - "../指标/fulfillment-rate.md"
  - "../概念与机制/指标事件与样本.md"
---

# PK胜率与完单不一致的排查

> 来源是最近复核于2026-07-12的部门资料快照，当前口径为watch。本页提供排查顺序，不能据此认定某个真实波动的原因。

## 先明确现象

PK胜出率衡量参与PK后胜出的比例，完单是后续结果。比例提高不保证规模提高，也不保证胜出订单的履约改善。先确定是在比较商家还是平台、绝对订单数还是比率、哪段日期和哪类运力。

## 排查顺序

| 顺序 | 检查内容 | 需要取得的证据 |
| --- | --- | --- |
| 1. 对齐统计范围 | 商家、城市、入口、运力、日期时间窗、改派与换车链路、订单去重粒度是否一致 | 看板/SQL及原始发单ID到PK/应答/完单的链路映射；来源未提供完整SQL，需补取 |
| 2. 呼叫与竞争机会 | 总呼叫、竞争呼叫、入口流量、勾选结构是否变化 | 同口径量级与分层趋势，避免把分母下降造成的比率提升理解为完单增长 |
| 3. 召回与匹配 | 可召回司机、有效在线、召回范围、匹配和举手机会是否变化 | 按城市/时段/运力的过程量；变化只作为候选解释 |
| 4. PK结构与竞争内胜出 | only/both构成是否变化；both场景的绝对PK胜出率是否改善 | only/both参与数、胜出数、竞争商家数量和接驾质量；only通常直接胜出，整体胜率变化可能伴随结构变化 |
| 5. 胜出到应答 | 胜出订单是否形成有效应答，拒单/抢单响应或特殊模式是否变化 | PK胜出、播单、司机决策、首次应答的事件衔接，避免跨口径比较 |
| 6. 应答后履约 | 司机取消、乘客取消、改派、换车及长等待是否变化 | 同一胜出订单群的后续履约/完单；再按接驾距离、时长、连环派等分层 |

## 必须保留的口径边界

- only/both举手率分母为参与PK数，举手率分母为播单数；两者是不同结构，不能直接相加还原整体举手率。
- 绝对PK胜出率限定both竞争场景；整体PK胜率还包含only结构。
- 本批履约率来源的分母是PK获胜数，履约定义是应答后无司机或乘客取消；不能自行替换成完单数/应答数。
- 乘客取消率来源是分子不含改派、分母含改派；司机取消率是含改派版本，排查时先复核一致性。
- 来源介绍中的漏斗乘法依赖样本与条件口径一致。本页不把尚未核验的量连乘成精确公式。

## 怎样形成结论

先报告分层事实和仍待验证的解释。若要判断“某项PK策略导致完单变化”，还需要与策略版本、实验分流、时空干扰/挤占和业务同时变化对齐的证据；上述漏斗趋势和相关性本身不能完成因果归因。

## 来源

- [交易策略介绍：8.交易诊断框架、10.常见问题](../../raw/department-baseline/common/trading-strategy-introduction.md)
- [PK胜出率原文](../../raw/department-baseline/directions/trading-efficiency/metric/pk-win-rate.md)
- [绝对PK胜出率原文](../../raw/department-baseline/directions/trading-efficiency/metric/absolute-pk-win-rate.md)
- [履约率原文](../../raw/department-baseline/directions/trading-efficiency/metric/fulfillment-rate.md)

快照commit：`a27b537bdef2b8f1cd7e3c503602dad9fde164c3`。

## 关联页面

- [PK胜出率](../指标/pk-win-rate.md)
- [绝对PK胜出率](../指标/absolute-pk-win-rate.md)
- [履约率](../指标/fulfillment-rate.md)
- [指标事件与样本](../概念与机制/指标事件与样本.md)
