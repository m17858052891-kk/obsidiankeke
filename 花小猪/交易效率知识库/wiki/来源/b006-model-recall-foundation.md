---
title: "B006 模型来源：召回价值基础率与特征契约"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: draft
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2208342470573", "cooper:knowledge:2208345117047", "cooper:knowledge:2208522851172"]
related: ["../模型/CAA履约率模型.md", "../模型/Efinish分桶模型.md"]
---

# B006 模型来源：召回价值基础率与特征契约

三份材料补齐了召回价值框架中的两个基础量。CAA 被定义为已应答 OD 对在完单前发生乘客或司机取消的概率，训练样本仅含已应答且终态明确的订单；异常、强制取消需剔除或单独建模。特征覆盖订单、司乘历史、等待、价格和时空上下文，召回阶段是否可取是上线前的硬约束。

E(finish) 不是当前深度模型，而是订单按轮次展开后，以城市、时段、供需档和等待轮次形成的最终完单率查找表。它近似“本轮不播、下一轮起的期望完单”，存在历史策略选择偏差和 T/T+1 语义偏差；低样本桶需逐级退化。文中时间表、延迟和命中率均是方案门槛，不是已完成事实。

特征清单进一步给出 CAA 的离线/在线字段映射，但字段表本身不证明所有特征已稳定接入，也不证明模型已上线。

## 原始来源

- [CAA建模](../../raw/cooper/knowledge-2208342470573.md)（sha256 `e1a4d79e0b0e04b8cc4bc4c1aa43f5fe7cc27a64eda2e5da6b6590208a951020`）
- [E_finish建模](../../raw/cooper/knowledge-2208345117047.md)（sha256 `b293126fae19724bcaccd94b2f1f5f9bac961da0c69c52e243629703bd788481`）
- [模型特征](../../raw/cooper/knowledge-2208522851172.md)（sha256 `9b3ac5077f373e83802078f0fdb0260c82a3c4b9eb02062deffa64051e563b2d`）

