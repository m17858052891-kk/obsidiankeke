---
title: "归一单均乘客 ETP"
type: metric
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-11-05
permission_scope: team
source_key: b014-evidence-normalized-passenger-etp
source_ids: ["knowledge:2207516995434"]
related: ["avg-etp.md", "normalized-driver-pickup-duration.md", "../诊断指南/换车取消率离线估算校验.md"]
---
# 归一单均乘客 ETP

## 历史口径

对每次乘客原始需求做归一，分子为最终完单订单从首次呼叫到最终开始计费的总等待时长，分母为归一完单订单数。它同时包含等待应答与等待接驾，比单个子订单的 ETP 更接近乘客完整需求体验。

## 使用约束

- 必须明确“最终开始计费”与旧版“司机到达”的事件差异。
- 换车、重发和改派需归并到同一原始需求，否则新子单会污染分母。
- 完单口径会受取消选择影响，宜与归一取消率和归一订单数共同解释。

## SQL 合同快照

历史 SQL 先以 `call_reassign_order_id / answer_reassign_order_id / order_id` 归并原始需求，过滤未应答换车子单，再取首次呼叫、首次应答及最终完单的开始计费时刻。实验评估按乘客打包，剔除窜组用户，并只统计首次进组后的订单。该实现还同时输出归一呼单数、归一完单数和人均指标，避免只看时长均值。

原文保留了“司机到达”改为“开始计费”的修订痕迹，也保留一段标记为“废弃”的旧 SQL；复用时不得混用两版事件终点。文中 2025—2026 月度测算是离线结果快照，不是线上实验或当前生产事实。

## 证据边界

来源包含大段历史 SQL，未执行；表名、事件字段、归一键、样本排除、分流配置和 2026 线上口径需数据 owner 复核。SQL 没有给出 SRM、显著性检验或发布版本。

## 来源

- [交易效率指标](../../raw/cooper/knowledge-2207516995434.md)
