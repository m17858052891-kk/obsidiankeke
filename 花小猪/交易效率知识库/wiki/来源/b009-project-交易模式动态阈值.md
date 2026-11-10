---
title: "订单价值交易模式动态阈值｜B009 来源摘要"
type: source
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_ids:
  - "knowledge:2200000736309"
related:
  - "../26年项目/交易价值统一.md"
processed_at: 2026-11-04
---

# 订单价值交易模式动态阈值｜B009 来源摘要

## 来源定位

- [动态阈值计算方案](../../raw/cooper/knowledge-2200000736309.md)，SHA-256 `9e0112c0660f3de4fc193c82eeadf40775f65a61c81253fcc4409edb04ea8547`

## 方案摘要

方案按城市周更阈值；低播单量城市合并计算。抢单/半指派阈值取“订单价值 70% 分位”和“使低价值样本拒取率低于 28% 的最大分数”两者较小值，以适应供需与订单结构变化。

## 证据边界

这是参数计算设计，缺少任务运行、回滚、异常城市和线上效果证据。70% 与 28% 是该历史方案参数，不应写成当前统一标准。

## 关联页面

- [交易价值统一](../26年项目/交易价值统一.md)
