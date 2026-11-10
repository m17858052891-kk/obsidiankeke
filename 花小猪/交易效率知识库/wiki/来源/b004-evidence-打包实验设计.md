---
title: "B004 证据摘要：交易效率打包实验设计"
type: source
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_ids:
  - "cooper:cooper:2210254006615"
  - "cooper:cooper:2210127971029"
related:
  - "../实验与复盘/交易效率打包实验设计.md"
---

# B004 证据摘要：交易效率打包实验设计

## 来源定位

- [26年交易效率打包实验](../../raw/cooper/cooper-2210254006615.md)记录实验矩阵与计划比较，不包含已回收结果。
- [评估大师数据指标需求](../../raw/cooper/cooper-2210127971029.md)只记录新增 TSH-VCM 指标及回溯日期要求，未给出指标定义。

## 可复用信息

打包实验按乘客 PID 分流，每组计划 5% 流量，通过 PK、召回、匹配、换车和 hold 五项能力的开关组合形成八组。原文预先指定了七组比较，用于拆解商家分单、hold、匹配及已全量能力的收益。

## 证据边界

- 这是实验设计而非实验结论；不能把“结论回收”下的比较项写成已验证收益。
- 多项能力同时变化的比较只能解释组合效果；单能力归因须依赖只改变一个开关的组间比较。
- TSH-VCM 的分子、分母、样本范围和维度缺失，补齐口径前不进入正式指标字典。

