---
title: "B005 模型来源：竞争胜率与召回特征"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: draft
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2208261534982", "cooper:knowledge:2208342388492", "cooper:knowledge:2208342392224"]
related: ["../模型/竞争胜率模型.md"]
---

# B005 模型来源：竞争胜率与召回特征

竞争胜率模型以“商家司机已举手参与PK”事件为样本，预测TP或GS模式下是否胜出，输出两个概率供召回价值计算。训练样本受旧召回过滤和司机举手两层选择影响，存在明显选择偏差；TP/GS的时延、竞争强度和样本量也不同。

模型特征清单覆盖订单时空、等待时长、供需、司机分场景历史、乘客取消历史和派单模式。`召回V1.0模型`原文仅有标题，不能据此补全模型结构或上线状态。

## 原始来源

- [PK策略模型特征](../../raw/cooper/knowledge-2208261534982.md)（sha256 `b01864df493019056df9f9fe12713d969b99c43bde6c68becb7cac85aa74bac3`）
- [竞争胜率建模](../../raw/cooper/knowledge-2208342388492.md)（sha256 `8b8f68dd8b6ba0598a1df622ee420fc2c2a6761973e612f86feefa01a5f79ada`）
- [召回V1.0模型空白页](../../raw/cooper/knowledge-2208342392224.md)（sha256 `f4423abb62d4b518eaccdf54041401fca36f6af3157dda8c0e3347681a792027`）
