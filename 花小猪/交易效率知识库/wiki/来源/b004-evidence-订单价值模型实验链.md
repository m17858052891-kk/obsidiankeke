---
title: "B004 证据摘要：订单价值模型实验链"
type: source
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_ids:
  - "cooper:cooper:2204851655455"
  - "cooper:cooper:2202605963074"
  - "cooper:cooper:2203645590604"
  - "cooper:cooper:2205210976894"
related:
  - "../实验与复盘/订单价值模型实验链.md"
---

# B004 证据摘要：订单价值模型实验链

## 来源定位

- [新版订单价值模型好差单对比](../../raw/cooper/cooper-2204851655455.md)是不同周期的描述性分层对比。
- [订单价值模型优化对照试验](../../raw/cooper/cooper-2202605963074.md)和 [V2 实验评估](../../raw/cooper/cooper-2203645590604.md)是实验需求/方案。
- [宏鹄订单价值模型补充实验](../../raw/cooper/cooper-2205210976894.md)记录补充实验配置，正文未给结果。

## 证据链

历史分层对比显示新版模型下好单与差单在 CPM、IPH、距离、拒单率和履约率上的差异更大，但新旧模型使用不同日期，不能直接作为因果收益。两份实验方案分别记录离线 AUC 预期提升 11.2pp 和 7.8pp，并计划用乘客 PID 随机分流观察竞争 CR、应答后取消和拒单率。补充实验改用司机 ID 随机分流，30% 对照不接模型、70% 实验接入放量阈值，周期记录为 8.27–9.2。

## 证据边界

- AUC 与业务收益预估来自方案，不是在线结果。
- 乘客 PID 与司机 ID 分流回答的问题不同，不能直接拼接估计量。
- 描述性好差单对比同时存在日期、流量和策略版本差异，仅用于形成假设。

