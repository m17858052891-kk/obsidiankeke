---
title: "PK 长时取消因子相关性分析"
type: analysis
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_key: b019-evidence-pk-long-cancel-correlation
source_ids: ["cooper:knowledge:2204758383370"]
source_url: "https://cooper.didichuxing.com/knowledge/2199610335356/2204758383370"
related: ["司机长时取消因子三期实验.md", "../概念与机制/PK履约与距离弹性.md"]
---
# PK 长时取消因子相关性分析

## 分析目标与样本

历史分析用 2025-06-16 至 06-30 的约 174.5 万司机、约 7788 万条订单，比较前 N 天长时取消次数与次日是否发生长时取消，解释该因子在线效果不明显的原因。

## 主要发现

随历史窗口从短到长，相关系数增加但始终低于 0.07；长时取消本身稀疏，即使拉长到 28 天，历史为 0 的司机仍很多。阈值为 0 时订单召回约 28.4%，阈值到 0.1 时降至约 1.2%；从 0 调到 0.01、0.05，召回约从 28.4% 降至 18.6%、3.5%，表现出阈值高度敏感且区分空间有限。

## 结论边界

该结果支持“单一历史次数因子信号较弱”，不等同于该因子对实验无因果作用。相关性受口径、司机曝光和事件稀疏影响；长 SQL 未重跑，最终应结合线上实验、校准曲线和分城市稳定性判断。

## 来源

- [PK 引入司机长时取消因子相关性分析](../../raw/cooper/knowledge-2204758383370.md)
