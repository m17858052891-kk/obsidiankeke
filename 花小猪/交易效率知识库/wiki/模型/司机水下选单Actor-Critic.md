---
title: "司机水下选单 Actor-Critic"
type: model-card
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: department
source_key: "b017-model-driver-underwater-actor-critic"
source_ids: ["cooper:2207021279252"]
source_url: "https://cooper.didichuxing.com/team-file/2199582756311/2207021279252"
provenance: "B017 通读 2026 方案提炼；无离线结果、随机实验或上线回执"
related: ["长时分单强化学习.md", "终点供需价值模型.md", "稳定匹配GS算法.md"]
---

# 司机水下选单 Actor-Critic

## 目标与决策位置

方案在 GS/TP 轮次分单完成后、实际播单前加一层司机视角的决策：当前订单可能把司机送到冷区，或附近即将出现更高价值订单时，模型可拒绝本次播单，以最大化长期司机收入。这不是替代 GS/TP 的全局匹配求解器。

## 方案中的模型合同

- **state**：播单前的订单起终点供需、司机当日完单/取消行为、订单属性等实时特征。
- **action**：二元决策，0 丢弃当前播单，1 正常播单；训练时方案提出 epsilon-greedy 探索。
- **reward**：PK 失败/应答后取消给负奖励；完单以收入除以接驾+送驾+下一单听单间隔；拒绝播单则比较下一单与当前单的单位时间价值。
- **训练**：计划保留 10% 司机流量采集轨迹，落地为四元组，按 T-1 数据用 PPO 离线更新 Actor 与 Critic。
- **推理**：仅部署 Action/Actor 做实时拒绝决策；Critic/Value 用于离线优化目标。

## 证据边界与风险

原文是策略设计，没有样本表口径、模型结构、训练曲线、离线策略评估、安全探索约束、随机实验或生产回执。奖励中的 `R1`、拒单后下一单反事实以及轨迹终止规则也未完整定义，不能声称已经验证长期收入改善。

一张整体链路图未解析；该图不能作为系统已建成的证据。

## 来源与关联

- [强化学习驱动的司机水下选单策略](../../raw/cooper/cooper-2207021279252.md)
- [长时分单强化学习](长时分单强化学习.md)
- [终点供需价值模型](终点供需价值模型.md)
