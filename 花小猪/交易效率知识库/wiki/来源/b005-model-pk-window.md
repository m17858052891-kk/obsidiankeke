---
title: "B005 模型来源：PK窗口多任务与唯一举手"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: draft
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2203850995922", "cooper:knowledge:2203890079221"]
related: ["../模型/PK模型谱系.md"]
---

# B005 模型来源：PK窗口多任务与唯一举手

## 多任务履约模型

2025-01-03～16训练、01-17～20测试。OD/O/D/T分别表示联合履约、司机侧、乘客侧和最近司机任务；不同任务的评价样本过滤条件不同。文档列出27项传入、28项供需、16项乘客历史、24项司机实时和70项司机历史特征，并采用多专家、POSO、门控和任务塔。原文AUC为0.779/0.768/0.855/0.899，只能作为该数据切分下的离线结果。

## 唯一举手模型

样本限定正常4秒PK窗口，选择第一个举手司机；标签是该司机是否为窗口中唯一举手者。模型为XGBoost，原文离线AUC 0.886。该模型预测竞争形态，不等同于履约概率，也不能从离线AUC推断缩窗收益。

## 原始来源

- [司乘履约多任务模型](../../raw/cooper/knowledge-2203850995922.md)（sha256 `81fb8e83a519964739e9656f156ffb8d06cd20900ae9f6b6146c008a15d0f652`）
- [only举手概率模型](../../raw/cooper/knowledge-2203890079221.md)（sha256 `22962325a64c6407f0d56f19f6d04f83a59ec24f8792040115cfd1c6e13039af`）
