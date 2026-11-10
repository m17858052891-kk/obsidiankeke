---
title: "B010 项目来源：差应答阈值配置"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: historical
last_reviewed: null
permission_scope: team
source_ids:
  - "knowledge:2200131015090"
related:
  - "极差应答运力释放.md"
---

# B010 项目来源：差应答阈值配置

> 2023 年配置与短期观察记录，不代表 2026 阈值或覆盖城市。

材料记录小猪端内快车/特惠快车的差应答释放配置：先在全国除郑州的 90% 流量采用 68% 应答率阈值，后在指定城市改为 73%；10% 流量以 -1 关闭触发。两日观察称自营、三方完单与大盘 CR 几乎无变化，但未给样本量、置信区间或完整实验表。

工程需求是在 Athena 品类展示与 Calcite hold 熔断的两处判断中增加来源开关：阈值可继续从 Dufe 读取，也可由 Apollo 参数直接覆盖；发单数阈值不变。

## 原始来源

- [节假日差应答阈值可配置需求](../../raw/cooper/knowledge-2200131015090.md)

