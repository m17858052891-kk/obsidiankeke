---
title: "动态播单与网出运力 hold｜B005 来源摘要"
type: source
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_ids:
  - "cooper:2200878816732"
  - "cooper:2201597242795"
  - "cooper:2202375299543"
related:
  - "../26年项目/自适应播单策略.md"
processed_at: 2026-11-04
---

# 动态播单与网出运力 hold｜B005 来源摘要

## 来源定位

- [网出运力 hold 策略](../../raw/cooper/cooper-2200878816732.md)，SHA-256 `e3c6614ab6fdb520ce47faf3ea3eaea4248c72319f63e93de84909dfa14202ad`
- [动态播单半径强化学习方案](../../raw/cooper/cooper-2201597242795.md)，SHA-256 `64b1db81678f7a27e3b953e00adba90e8b8ff685232eb8bc8750a3dda9c7b230`
- [乘客侧自适应播单 V1.2.0](../../raw/cooper/cooper-2202375299543.md)，SHA-256 `a693658f6a99d4995e83b4fb91dd11b52765ae475305d1575b943b4868525632`

## 方案谱系

运力 hold 以“小猪是否能在乘客取消前应答”为前提，结合应答时长、取消时长和外部运力响应时间决定接入时机；缺失外部实时供需时退化为历史响应时长与规则。强化学习方案把扩缩播半径作为动作，用应答/完单、等待和接驾距离权衡奖励，并明确仿真取消模块与线上存在偏差。V1.2.0 则用供需比、空闲运力数和实时竞争应答率配置播单半径。

## 状态与限制

三份材料分别是策略设计或 BRD。V1.2.0 引用早期 V3 实验背景，但其自身收益仍是预期；强化学习方案列出模型选择和低置信问题，没有上线结果；hold 文档也存在响应时长历史特征尚未完成的标记。

## 关联页面

- [自适应播单策略](../26年项目/自适应播单策略.md)

