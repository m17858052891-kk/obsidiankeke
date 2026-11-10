---
type: "索引"
topics: ["面向决策的履约建模","模型迭代"]
status: "维护中"
created: "2026-11-04"
---

# 面向决策的履约建模

怎样建模采取不同动作后发生的结果、时长、风险与状态转移，让预测更好地服务下游决策？

## 第一次读，从这里开始

先读 [[研究前沿/面向决策的履约建模/01-论文原文与精读/SensorWM/精读|相同积压量，正在上升和正在回落有何差别]]。原研究跟踪健康状态，履约是一个待检验的应用。建议先读它怎样处理上一步状态，再看作者到底用什么数据验证了预测。

## 按研究问题阅读

### 动作之后状态怎样变化

有连续历史状态时，[[研究前沿/面向决策的履约建模/01-论文原文与精读/SensorWM/精读|SensorWM]] 用当前状态和动作调整上一次的状态变化，向前滚动预测。若只有执行前后的快照、而多数内容没变，[[研究前沿/面向决策的履约建模/01-论文原文与精读/MKD2World/精读|MKD2World]] 在网页操作轨迹上给确实变化的元素更多训练权重。先判断自己的瓶颈是没利用最近趋势，还是模型总在重复旧状态；再分别检查多步误差或真实变化处的误差。业务中未执行动作的因果效果仍需要额外证据。

[[研究前沿/面向决策的履约建模/02-可复用方法卡/SensorWM-velocity-conditioned-transition|动作条件下的状态变化量]] · [[研究前沿/面向决策的履约建模/03-实验假设与结果/2026-11-10-二阶状态转移是否改善高峰期履约滚动预测|未运行：高峰期比较一阶和二阶积压预测]]

### 等待、取消和完成怎样一起估

先统一时钟。例如从接单时算起，取消和完单可作为互斥的首个终态，仍在等待的订单要记录随访截止时间。[[研究前沿/面向决策的履约建模/01-论文原文与精读/CompetingRiskLoss/精读|CompetingRiskLoss]] 比较多种损失怎样估计某一时点前各类事件的累计概率。[[研究前沿/面向决策的履约建模/01-论文原文与精读/CompetingEstimands/精读|CompetingEstimands]] 讨论同一策略同时改变几种结局时，风险集中还剩哪些人，以及这会怎样影响风险比的解释。要预测某时点前取消的比例，先看前者；要解释策略切换后风险比为什么不同，再看后者。

[[研究前沿/面向决策的履约建模/03-实验假设与结果/完单与取消首事件的损失和主干交叉验证|未运行：交叉比较首事件损失与预测主干]]

### 预测更准能让决策更好吗

把预测值交给相同的求解器，比较执行后真实成本与最优成本的差距。若怀疑少量错误标签会改变约束边界，[[研究前沿/面向决策的履约建模/01-论文原文与精读/RCIF/精读|RCIF]] 利用干净验证样本给训练样本重新加权。若要直接改变预测器的训练目标，[[研究前沿/面向决策的履约建模/01-论文原文与精读/DFLNOL/精读|DFLNOL]] 先学软选边层并冻结，再按真实参数评价预测引发的决策。后者的选边对照在合成优化实例上完成；上线前还要单测离散解可行性和解码时延。

[[研究前沿/面向决策的履约建模/02-可复用方法卡/DFLNOL-frozen-layer|固定优化层，按决策损失训练]] · [[研究前沿/面向决策的履约建模/03-实验假设与结果/2026-11-10-冻结选边层的决策损失与解码代价|未运行：分开度量训练收益与解码代价]]

## 完整资料与相关精读

[[研究前沿/00-总览|研究前沿总览]] · [[研究前沿/面向决策的履约建模/01-论文原文与精读/README|论文原文与精读]] · [[研究前沿/面向决策的履约建模/02-可复用方法卡/README|可复用方法卡]] · [[研究前沿/面向决策的履约建模/03-实验假设与结果/README|实验假设与结果]]

以往精读另见 [[研究前沿/面向决策的履约建模/01-论文原文与精读/ActTime/精读|ActTime]] · [[研究前沿/面向决策的履约建模/01-论文原文与精读/PtOGtO/精读|PtOGtO]] · [[研究前沿/面向决策的履约建模/01-论文原文与精读/StandIn/精读|StandIn]]。

[[研究前沿/_运行记录/README|最近一期与历史记录]] · [[研究前沿/_运行记录/待处理队列|待核原文]]

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

[[知识体系/04-因果推断/05-评估、策略学习与序贯因果|评估、策略学习与序贯因果]] 可用于梳理履约预测的下游策略评估。

## 初始检索线索

术语锚点（不视为本次新论文或已精读）：[司机接单行为建模](https://arxiv.org/abs/2107.07864)；[Decision calibration](https://arxiv.org/abs/2107.05719)。

## 队列处理规则

取消每日总篇数及每方向篇数上限；按创新价值、机制清晰度和可信效果证据决定精读数量，不凑数。每天先检查已有待精读队列，与新候选按价值、证据及等待时间共同排序，持续处理旧队列。只因原文不可访问、证据待核实或执行实际中断等具体原因保留待处理，并记录下一步；不因达到篇数或固定阅读预算而入队。理论与有价值的负面结论同样可收录。
