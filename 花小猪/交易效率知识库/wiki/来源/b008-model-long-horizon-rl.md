---
title: "B008 模型来源：长时分单强化学习"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: draft
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2199613411500"]
related: ["../模型/长时分单强化学习.md"]
---

# B008 模型来源：长时分单强化学习

材料将多轮司乘匹配建模为 PPO 时序决策：状态由司机、订单、可连边与环境特征构成，Pointer/Attention 结构自回归生成匹配序列，以完成匹配订单的总 GMV 作为主要 reward，并探索 ICM、逆模型和并行采样提升长期学习与样本效率。

文档记录了短时仿真中个别实验超过 IPH，也明确模型不稳定、多头特征振荡、长时训练和 critic reward shaping 尚待继续。20 张图片未解析，不能据此补充架构或效果细节。

## 原始来源

- [长时分单RL建模_v1](../../raw/cooper/knowledge-2199613411500.md)（sha256 `a1a4f126fd80aaf50922a55d48ce64cc00ec433d3540d83c2abe1e28e88acbf6`）
