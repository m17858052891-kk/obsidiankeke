---
title: "GS 选择顺序优化｜B007 来源摘要"
type: source
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_ids:
  - "cooper:2204981928875"
  - "cooper:2205087355122"
related:
  - "../26年项目/GS选择顺序优化.md"
  - "../26年项目/分单召回优化.md"
processed_at: 2026-11-04
---

# GS 选择顺序优化｜B007 来源摘要

## 来源定位

- [BRD](../../raw/cooper/cooper-2204981928875.md)，SHA-256 `b1058e8e5ddc2d2e4ee5c2972e66faec8269bb73cdbc57e5412cb5e12f9749d5`
- [策略方案](../../raw/cooper/cooper-2205087355122.md)，SHA-256 `dad55fbf81936b5dd64338c4c4acfdce559c17af212010cf0ea1ace6419afd0a`

## 方案摘要

材料将 GS 的匹配顺序拆成司机先选 `GS_D`、订单先选 `GS_O` 与按订单/司机数量比动态切换的 `GS_S`。召回、交易模式和 OD 打分保持不变，变量只聚焦选择顺序；实验计划以城市 1 小时时间片轮转比较 `GS_D`、`GS_O` 与 `GS_S(k=1)`。

## 证据边界

BRD 中的完单、取消改善与策略方案中的理论推导均是目标或测算。实验周期仍为 TBD，未见结果、放量记录或现网配置，不能认定方案已上线或获得预估收益。

## 关联页面

- [GS 选择顺序优化](../26年项目/GS选择顺序优化.md)

