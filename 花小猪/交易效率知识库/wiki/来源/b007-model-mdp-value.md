---
title: "B007 模型来源：MDP 时空价值与 Hold"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: draft
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2199613359733", "cooper:knowledge:2199613360746", "cooper:knowledge:2199613361364", "cooper:knowledge:2199613361368"]
related: ["../模型/MDP时空价值网络.md", "../模型/MDP-Hold匹配策略.md"]
---

# B007 模型来源：MDP 时空价值与 Hold

材料给出从表格型 SMDP 到 MLP 价值网络的演进：输入时间与位置状态，以分时衰减 GMV 构造 reward，用 2 小时 episode、idle 补集和 done mask 形成转移数据。数据分析指出“一单即走”会造成低价值峰，历史样本多模态与时间倒挂会干扰训练。

Hold 通过空订单节点把“不分单”纳入 GS 匹配；MDP-Hold 以当前状态价值作为空边价值，尝试兼顾当前门槛与未来收益。线上材料显示 MDP 排序相对 IPH+Hold 的效果随城市、时段、季节和流量变化，整体并非稳定正向，不能从局部时段外推全量收益。

## 原始来源

- [MDP-Hold](../../raw/cooper/knowledge-2199613359733.md)（sha256 `27be029fb06c277415948944476519079ba1d55458f963daadc116328bdf8137`）
- [时空状态价值网络](../../raw/cooper/knowledge-2199613360746.md)（sha256 `35ac656a8dec6d815d10bbb02d8bd01f53e40710de2611957c1a9e9d9bbfe742`）
- [Dataset双峰问题](../../raw/cooper/knowledge-2199613361364.md)（sha256 `754206e464fefa4291a9e33827b8eaa2083c9e48f1c3442a1c2d577371b9e1e7`）
- [MDP网络上线实验](../../raw/cooper/knowledge-2199613361368.md)（sha256 `1eedbf5649224f10d53a64b9f6ea367eb5c08ae611a03eb0dadd084ef4ba3dd9`）
