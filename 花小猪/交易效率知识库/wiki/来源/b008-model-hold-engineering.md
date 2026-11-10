---
title: "B008 模型来源：Hold 参数与工程链路"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: draft
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2199613420364", "cooper:knowledge:2199613426776"]
related: ["../模型/司机Hold参数策略.md"]
---

# B008 模型来源：Hold 参数与工程链路

两份材料描述 Hold 的离线—在线链路：离线按时空格子、空闲司机数搜索 hold 时长和订单价值阈值，在线接收参数并统计状态，分单引擎据此选择等待或分单。离线分析以 `订单价格×3600/(等单+接驾+送驾时长)` 定义 IPH，并对历史城市、时段与参数变化做敏感性分析。

工程文档仍含排期和待验证项；离线历史分布不能直接证明新城市上线收益。参数分析含 60 张未解析图片，具体城市图表不纳入结论。

## 原始来源

- [hxz-hold流量策略开发方案v0.1](../../raw/cooper/knowledge-2199613420364.md)（sha256 `074ac4ef9d6877a0c1617145bff8b8b0bf30e23da4e68fb055e14930666e866a`）
- [hold策略参数离线分析v0.1](../../raw/cooper/knowledge-2199613426776.md)（sha256 `1a5be2c1795131a5fd117fb29f07427f0089f1067b5f9d8c1acaf7a0278f685c`）
