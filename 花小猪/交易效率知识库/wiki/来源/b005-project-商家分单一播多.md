---
title: "商家分单一播多 V2/V2.1｜B005 来源摘要"
type: source
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_ids:
  - "cooper:2208749561363"
  - "cooper:2208749617203"
related:
  - "../26年项目/商家分单一播多.md"
processed_at: 2026-11-04
---

# 商家分单一播多 V2/V2.1｜B005 来源摘要

## 来源定位

- [V2.1 BRD](../../raw/cooper/cooper-2208749561363.md)，SHA-256 `e88df7c7d0404c27e46bb1025994f9128e145a8bdeb8e38b12672c93befb1e85`
- [V2 BRD](../../raw/cooper/cooper-2208749617203.md)，SHA-256 `fef03f02dcf05d00112536e9ca1f73028e7033b9b786c0c06d2da1d65cc737bf`
- 两份正文高度相似，作为同一方案的版本证据合并提炼；下载日不作为内容复核日。

## 方案摘要

同一 GS 层内一播多会使多运力集中到少数订单，并因 PBD 不支持一播多产生渠道份额腾挪。方案拟在正常 GS 匹配结束后增加层级，将剩余运力播给可连边端内订单中 IPH 最高者，不限制订单最大可播运力数。

## 指标与状态

正文引用 V2.0 实验结果，并给出宏鹄 PK 胜率 `+0.09pp`、自营约 `+0.06pp` 的 V2.1预期；这些是引用背景与收益测算，不是 V2.1 已实现结果。V2.1 仍以时间片实验、小流量到全量的分阶段标准描述，缺少本版本上线和验收记录。

## 关联页面

- [商家分单一播多](../26年项目/商家分单一播多.md)

