---
title: "B009 模型来源：稳定匹配 GS 算法"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: draft
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2199613432353"]
related: ["../模型/稳定匹配GS算法.md"]
---

# B009 模型来源：稳定匹配 GS 算法

材料比较了 KM、贪心、Topspeed 与 Gale–Shapley 延迟接受算法。GS 将司机和订单拆成两套偏好排序，目标是避免双方都更偏好彼此的阻塞对；其方向性对主动方有利，复杂度与多目标表达方式也不同于最大权匹配。

文档中的 GMV、成交率、ASP 与接驾距离数字属于历史仿真结果，不能当作线上收益；实验仍以时间片或地理分片作为方案，线上版本和最终状态未确认。多张图未解析。

## 原始来源

- [稳定匹配算法](../../raw/cooper/knowledge-2199613432353.md)（sha256 `845268f34c355352e6348f8b331d2b710181e26ed17a7645babd39dee92f99c6`）
