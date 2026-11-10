---
title: "连环派 Hold 强化学习"
type: model-card
owner: "@tommywujian"
freshness: watch
status: historical-proposal
last_reviewed: null
permission_scope: department
source_key: "b012-model-chain-hold-rl"
source_ids: ["cooper:knowledge:2203636968024"]
related: ["司机Hold参数策略.md", "长时分单强化学习.md", "MDP-Hold匹配策略.md"]
---

# 连环派 Hold 强化学习

> 历史方案推导，没有收敛、离线策略评估、随机实验或上线证据。

## 决策合同

- 目标：最大化 GMV，同时通过拉格朗日项约束司乘取消。
- 状态：按分单轮次观察司机关联的一个或多个订单子状态。
- 动作：对 DO 对过滤或不过滤；训练按策略概率采样，测试取最大概率动作。
- 奖励：订单 GMV 减去超出取消约束的惩罚。

方案尝试把变长多订单状态拆成子状态，分别估计子价值后聚合为总价值，并计划用 5% PID 流量采集 actor 数据。

## 关键假设与风险

- 子状态被假设共享同一后续转移分布，且聚合公式含较强近似；需要用仿真或反事实评估验证。
- 在线采样会改变过滤和成交分布，取消约束可能在探索期被突破。
- 来源明确列出样本不足导致不收敛、过滤过多造成完单折损两项风险。
- 文档没有算法实现、训练曲线、基线对比、约束违反率或部署回执。

## 覆盖缺口

策略比较图、训练流和部署流程图未解析；它们不能作为系统已建成的证据。当前是否仍推进该方向未知。

## 来源与关联

- [连环派 Hold 策略 RL](../../raw/cooper/knowledge-2203636968024.md)
- [司机 Hold 参数策略](司机Hold参数策略.md)
- [长时分单强化学习](长时分单强化学习.md)

