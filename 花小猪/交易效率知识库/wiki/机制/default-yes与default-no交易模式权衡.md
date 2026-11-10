---
title: "default yes 与 default no 交易模式权衡"
type: mechanism
owner: "@tommywujian"
freshness: watch
status: historical-analysis
last_reviewed: null
permission_scope: team
source_ids: ["knowledge:2199613383711"]
related: ["交易产品运营能力地图.md", "../实验与复盘/不提前举手扩量实验链.md"]
---
# default yes 与 default no 交易模式权衡

## 历史问题

来源把花小猪当时的半指派 `default yes` 描述为每天 3 次拒单权益。历史观察称，约 45% 的改派订单对应司机已用完拒单权益，约 25% 对应司机仍未使用权益；另有“至少 20% 应答后乘客取消疑似司机诱导”的判断。它说明固定拒单权益可能同时存在不足与闲置，但不是严格因果结论。

遵义、临沂的司机分层表显示，不同剩余拒单次数在乘客取消、司机取消和改派中的结构差异明显。该表未给观察窗口、样本量、司机暴露或显著性，不能直接用来制定权益阈值。巴西 `default no` 的 70% 抢单率、90% 应答率也属于异市场参照，不能直接迁移。

## 决策框架

材料认为无管控的 `default no` 可能损失效率，而弱管控定位下保留 `default yes`；配套方向包括司机双开教育、按做单能力运营拒单权益，以及诱导取消治理。这是历史决策与治理建议，不代表当前仍采用每日 3 次权益或相关规则已经上线。

## 覆盖缺口

- 缺观察日期、实验分流、样本量、显著性、司机异质性和跨城市权重。
- “诱导取消”缺可复核判定标签与误判率。
- 当前交易模式、权益次数、配置版本、发布和回滚记录待确认。

## 来源

- [default yes VS default no](../../raw/cooper/knowledge-2199613383711.md)
