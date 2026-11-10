---
title: "调层 PID 与时间片结论冲突诊断"
type: guide
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_key: b015-evidence-layer-pid-conflict
source_ids: ["cooper:knowledge:2210255901263"]
related: ["../实验与复盘/召回重构V1.0.2时间片实验复盘.md"]
---
# 调层 PID 与时间片结论冲突诊断

历史材料记录 PID 与时间片结论相反，且 334 城中 32 城完单显著负向、约占全国完单份额 28%。排查时：

1. 校验两类实验的城市、流量、周期与分组是否一致。
2. 将呼叫与去重呼叫分开；材料观察到应答前取消上升可能制造重复呼叫增长。
3. 按城市复核负向是否集中于特快/新乘客等被取消品类及其盒子份额。
4. 对多城市检验说明多重比较处理，不能直接把显著城市数量当整体因果强度。
5. 以统一分母重算完单、CR 和取消，再决定是模型、配置还是实验设计问题。

## 证据边界

原始结论依赖图片和两份 Excel，当前未解析复算；因此本页是排查框架，不认定具体原因已被证明。

## 来源

- [PID 实验分析](../../raw/cooper/knowledge-2210255901263.md)
