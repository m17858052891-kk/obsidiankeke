---
type: "索引"
topics: ["面向决策的履约建模","模型迭代"]
status: "维护中"
created: "2026-11-04"
---

# 面向决策的履约建模

怎样建模采取不同动作后发生的结果、时长、风险与状态转移，让预测更好地服务下游决策？

[[研究前沿/00-总览|研究前沿总览]] · [[研究前沿/面向决策的履约建模/01-论文原文与精读/README|论文原文与精读]] · [[研究前沿/面向决策的履约建模/02-可复用方法卡/README|可复用方法卡]] · [[研究前沿/面向决策的履约建模/03-实验假设与结果/README|实验假设与结果]]

## 中文关键词

面向决策的预测、决策导向学习、履约响应、完单概率、接单概率、取消风险、服务完成、时长分布、反事实响应、生存分析、竞争风险、多状态转移、预测优化一体化、决策校准。

## 直接相关英文关键词

- decision-focused learning
- predict-then-optimize
- end-to-end predict-and-optimize
- decision-aware prediction
- action-conditional outcome prediction
- service completion prediction
- fulfillment modeling
- driver acceptance prediction
- cancellation prediction
- pickup time prediction

## 跨领域方法关键词

- survival analysis
- time-to-event prediction
- competing risks
- multi-state models
- temporal point processes
- causal survival analysis
- counterfactual outcome modeling
- censoring and delayed feedback
- differentiable optimization
- decision calibration
- decision regret
- uncertainty-aware optimization
- distributionally robust optimization
- conformal risk control
- model-based reinforcement learning
- action-conditioned world models

## 可直接执行的检索组合

每条独立检索，按检索日期附加时间窗口；不得要求同一论文命中全部词。

- `"decision-focused learning" prediction optimization`
- `"predict-then-optimize" uncertainty`
- `"ride-hailing" acceptance cancellation prediction`
- `"service completion" prediction decision`
- `"survival analysis" "competing risks" learning`
- `"action conditional" outcome prediction`
- `"decision calibration" prediction`
- `履约建模 完单预测 接单预测 取消风险 决策导向学习`

扩展路线：

- `"counterfactual" time-to-event prediction`
- `"multi-state" survival decision`
- `"differentiable optimization" prediction regret`
- `"uncertainty" "predict-then-optimize"`
- `"world model" action conditioned uncertainty`
- `"delayed feedback" outcome prediction`

## 收录边界

履约包含接单、等待、接驾/到达、取消、完成等结果链条，同时纳入医疗、生存建模、推荐、供应链、运筹优化和模型式决策中的可迁移方法。不限于网约车，不因原场景不同或暂时没有本地数据而拒绝。只预测历史标签的工作也可入选，但应说明可复用模块和效果；普通预测不能被写成已识别动作的因果效果。不得仅用 fulfillment 单词做唯一入口，以免被仓储业务内容淹没。

论文创新模块和效果证据是主要标准；当前项目是否能立即接入仅作附注。跨方向论文按最主要贡献确定正文目录，在其他方向建立链接。

## 已有知识关联

[[生成式出价-仿真系统/因果响应模型与验证|因果响应模型与验证]]；[[知识体系/04-因果推断/05-评估、策略学习与序贯因果|评估、策略学习与序贯因果]]。这些是应用参考，不限制前沿模块收录。

## 初始检索线索

术语锚点（不视为本次新论文或已精读）：[司机接单行为建模](https://arxiv.org/abs/2107.07864)；[Decision calibration](https://arxiv.org/abs/2107.05719)。

