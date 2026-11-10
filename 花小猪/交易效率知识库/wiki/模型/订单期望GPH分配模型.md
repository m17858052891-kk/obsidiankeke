---
title: "订单期望GPH分配模型"
type: model-card
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2199613357445", "cooper:knowledge:2199613361404"]
related: ["../来源/b007-model-agent-allocation.md", "cba应答前取消模型.md", "竞争胜率模型.md"]
---

# 订单期望GPH分配模型

## 目标与表达

在共享司机的分单矩阵内，以期望 GPH 排序订单，方案表达为：

`GMV × (1 - P(应答后取消)) × P(渠道PK胜率) / (接驾时长 + 行程时长)`

V1 讨论中渠道 PK 胜率可暂不作为乘子，因此公式是总体设计而非已确认的单一线上实现。

## 输入与依赖

- 订单 GMV、接驾和行程时长。
- 应答后取消概率与渠道 PK 胜率；依赖模型版本和选择偏差控制。
- 1/5 分钟格子供给、冒泡、发单、应答、完单等实时特征可作为后续上下文，但来源未证明全部已接入。

## 状态与风险

原方案明确暂停等待旺季实验，预期收益不是实际收益。渠道、品类和 anycar 组合的样本稀疏、取消概率校准及 PK 策略反馈均需实验核验。

## 来源

- [B007 Agent 与运力分配建模](../来源/b007-model-agent-allocation.md)
