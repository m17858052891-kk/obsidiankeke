---
title: "E(finish)分桶模型"
type: model-card
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2208345117047", "knowledge:2208949685197"]
related: ["../来源/b006-model-recall-foundation.md", "订单流失率OCR模型.md", "竞争胜率模型.md"]
---

# E(finish)分桶模型

## 目标与位置

估计订单处于某轮时最终完单的条件概率，作为“本轮不播、下一轮继续”的未来价值近似。它与 OCR 和 hold 激进度系数共同进入 hold 价值，不是普通的当前轮完单预测。

## 当前方案

V1 方案按订单×轮次展开历史样本，使用城市、时段、供需档、等待轮次四维分桶统计最终完单率。低样本桶需按维度逐级退化并设置全局兜底；查表值需要日更、漂移监控和命中率监控。

## 核心局限

- 历史轮次样本由旧策略筛选，存在选择偏差。
- 当前桶最终完单率只是下一轮剩余生命期完单率的近似。
- 方案中的工程排期、延迟、命中率与实验门槛不是已完成记录。
- 深度模型替代仅是后续演进方向。

## B034：历史数据血缘

补充来源把分桶结果表指向 `kflower_strategy.recall_efinish_json_doudi_daily`，分桶 key 的上游来自 `kflower_strategy.ods_log_kflower_ether_cp_dri_caa_model_hi`，并给出当时的周期任务入口。该记录只补足历史 Hive 血缘，没有字段 schema、分区、新鲜度、回填与质量校验，也不能证明这条任务仍在生产运行。

页面中的 DataMap 和任务链接属于外部入口，本批未解析；当前在线服务究竟读取哪张表、日更时刻和兜底版本仍待确认。

## 来源

- [B006召回价值基础率与特征契约](../来源/b006-model-recall-foundation.md)
- [E_finish建模原文](../../raw/cooper/knowledge-2208345117047.md)
- [Efinish Hive 表产出逻辑](../../raw/cooper/knowledge-2208949685197.md)

