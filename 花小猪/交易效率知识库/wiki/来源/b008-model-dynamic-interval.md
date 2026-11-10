---
title: "B008 模型来源：动态分单间隔"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: draft
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2199613414004"]
related: ["../模型/动态分单间隔强化学习.md"]
---

# B008 模型来源：动态分单间隔

材料以每轮召回形成的连通二部图为状态单元，在“立即分单/继续等待”之间学习动作，以匹配权重或 GMV 作为 reward。早期 Q-table 方案因离散状态约束转向 DQN、Double DQN，并把订单总 GMV 等连续变量纳入状态。

文档仅报告 5—10 分钟仿真内相对固定间隔的正向结果，且标为 WIP；这不是线上显著收益。17 张图片未解析。

## 原始来源

- [动态分单间隔 WIP](../../raw/cooper/knowledge-2199613414004.md)（sha256 `b0f46f94e781af051da651452925e2df30f430879c6410c8c65760d23d2115c0`）
