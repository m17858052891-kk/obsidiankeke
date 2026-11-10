---
title: "B015 项目候选：司乘双差城市召回扩距"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_key: "b015-project-double-shortage-recall-expansion"
source_ids:
  - "knowledge:2209773012223"
  - "knowledge:2209783989909"
related:
  - "b014-project-商家召回重构V1候选.md"
  - "b015-project-商家召回重构V1.1候选.md"
---

# B015 项目候选：司乘双差城市召回扩距

> 这是召回重构框架下的历史场景实验材料；进入 26 年项目目录只表示可供候选池复用，不代表 2026 当前仍在运行或已形成正式项目。

## 场景与方案

材料针对司乘双差城市，希望用更大召回覆盖换取应答提升，并接受一定接驾距离上涨。前序 PK 扩距未达到预期后，二期方案去掉订单 HOLD，同时用召回重构框架调整端内召回强度；材料记录的候选参数为 `beta=1.1`。

离线测算显示参数变化会同时改变 O/OD 召回率与距离：例如 `beta=1.1` 在样本中提高端内 O 召回率，但也提高 OD 召回距离。这是离线权衡，不是上线净收益。

## 实验门槛

- 只对端内流量生效，需与端外及大聚合资源转移分开观察。
- 除应答外，必须同时核验完单、取消、接驾距离、召回覆盖和商家份额。
- 时间片方案及实验平台链接存在，但当前快照未给出完整实验结果或最终放量结论。

## 覆盖缺口

测算表较大，图片、评估平台数据、显著性、真实实验周期和配置回执未完整解析；无法确认 `beta=1.1` 是否曾上线或当前仍有效。

## 原始来源

- [司乘双差城市召回扩距分析](../../raw/cooper/knowledge-2209773012223.md)
- [时间片实验方案](../../raw/cooper/knowledge-2209783989909.md)
