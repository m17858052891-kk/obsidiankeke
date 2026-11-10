---
title: "指标目录与口径边界"
type: link-index
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/index.md"
related:
  - "absolute-pk-win-rate.md"
  - "average-pickup-distance.md"
  - "avg-answer-duration.md"
  - "avg-call-to-charge-duration.md"
  - "avg-etp.md"
  - "avg-pickup-duration.md"
  - "both-hand-raise-rate.md"
  - "charge-duration-share.md"
  - "driver-cancel-after-answer-rate-with-reassign.md"
  - "fulfillment-rate.md"
  - "hand-raise-rate.md"
  - "only-hand-raise-rate.md"
  - "passenger-cancel-after-answer-rate.md"
  - "pk-win-rate.md"
  - "response-rate.md"
  - "交易效率环境归一化评估.md"
  - "交易漏斗分端口径合同.md"
  - "扩播订单漏斗与取消诊断口径.md"
  - "司机热力值与分档合同.md"
  - "城市实验基础画像合同.md"
---

# 指标目录与口径边界

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

- [绝对 PK 胜出率](absolute-pk-win-rate.md)
- [平均接驾距离](average-pickup-distance.md)
- [单均应答时长](avg-answer-duration.md)
- [单均呼叫-计费时长](avg-call-to-charge-duration.md)
- [单均 ETP](avg-etp.md)
- [单均接驾时长](avg-pickup-duration.md)
- [both 举手率](both-hand-raise-rate.md)
- [送驾时长占比](charge-duration-share.md)
- [应答后司机取消率（含改派）](driver-cancel-after-answer-rate-with-reassign.md)
- [履约率](fulfillment-rate.md)
- [举手率](hand-raise-rate.md)
- [only 举手率](only-hand-raise-rate.md)
- [应答后乘客取消率](passenger-cancel-after-answer-rate.md)
- [PK 胜出率](pk-win-rate.md)
- [应答率](response-rate.md)
- [交易效率环境归一化评估](交易效率环境归一化评估.md)
- [司机时长与类型分层实验口径](司机时长与类型分层实验口径.md)
- [交易漏斗分端口径合同](交易漏斗分端口径合同.md)
- [扩播订单漏斗与取消诊断口径](扩播订单漏斗与取消诊断口径.md)
- [司机热力值与分档合同](司机热力值与分档合同.md)
- [城市实验基础画像合同](城市实验基础画像合同.md)

## 跨指标约束

- 改派版本、统计对象、时间窗与去重粒度必须随指标一起引用。
- only/both 举手率用于 PK 竞争结构；与举手率不同分母。
- 乘客取消率来源为分子不含改派、分母含改派，保留混合口径待确认。
- ETP 到到达事件；呼叫-计费到计费事件；司机接驾时长采用分场景修正。
- 年度目标不是当前线上表现。

## 来源

- [index.md](../../raw/department-baseline/directions/trading-efficiency/metric/index.md)（快照 commit `a27b537`）

## 关联页面

- [absolute-pk-win-rate](absolute-pk-win-rate.md)
- [average-pickup-distance](average-pickup-distance.md)
- [avg-answer-duration](avg-answer-duration.md)
- [avg-call-to-charge-duration](avg-call-to-charge-duration.md)
- [avg-etp](avg-etp.md)
- [avg-pickup-duration](avg-pickup-duration.md)
- [both-hand-raise-rate](both-hand-raise-rate.md)
- [charge-duration-share](charge-duration-share.md)
- [driver-cancel-after-answer-rate-with-reassign](driver-cancel-after-answer-rate-with-reassign.md)
- [fulfillment-rate](fulfillment-rate.md)
- [hand-raise-rate](hand-raise-rate.md)
- [only-hand-raise-rate](only-hand-raise-rate.md)
- [passenger-cancel-after-answer-rate](passenger-cancel-after-answer-rate.md)
- [pk-win-rate](pk-win-rate.md)
- [response-rate](response-rate.md)
- [交易效率环境归一化评估](交易效率环境归一化评估.md)
- [司机时长与类型分层实验口径](司机时长与类型分层实验口径.md)
- [交易漏斗分端口径合同](交易漏斗分端口径合同.md)
