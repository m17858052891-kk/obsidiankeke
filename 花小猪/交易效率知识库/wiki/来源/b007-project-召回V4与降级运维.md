---
title: "召回 V4 与降级运维｜B007 来源摘要"
type: source
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_ids:
  - "cooper:2205573982725"
  - "cooper:2205712830020"
  - "cooper:2205874142629"
related:
  - "../26年项目/分单召回优化.md"
processed_at: 2026-11-04
---

# 召回 V4 与降级运维｜B007 来源摘要

## 来源定位

- [召回 V4 实验配置](../../raw/cooper/cooper-2205573982725.md)，SHA-256 `a351f4f2e197b6f6a6fe38f602b6f83858b85cac676185d49858c088a039dce4`
- [模型降级规则](../../raw/cooper/cooper-2205712830020.md)，SHA-256 `558bd60499ba0d97d26fbfb8a4fcb163bc69127a5d234ee1db87fe76be8f5d51`
- [V2 运维机制](../../raw/cooper/cooper-2205874142629.md)，SHA-256 `fe6680d78316680ecadf6ef1f6147f89c998e3b8c77c8b1f7869cf066a1ca126`

## 机制摘要

V4 文档记录 PID 分流实验配置及多个流失率模型版本，但未提供实验结果。高峰降级规则在取消率模型不可用时，按接驾距离与送驾/接驾里程比过滤。运维方案提出按月采集 2% 空白组、训练和离线仿真，再以 10% 流量观察、50% 扩量、全量的分阶段流程。

## 证据边界

运维 SOP 声称从 2026 年 1 月开始执行，但当前没有月度执行记录或回滚记录，需 owner 复核现状；V4 配置也不能替代实验结论。

## 关联页面

- [分单召回优化](../26年项目/分单召回优化.md)

