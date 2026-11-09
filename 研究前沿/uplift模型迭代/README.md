---
type: "索引"
topics: ["uplift模型迭代","模型迭代"]
status: "维护中"
created: "2026-11-04"
---

# uplift模型迭代

怎样更准确、稳健、高效地估计干预增量，并把估计用于排序、分配和决策？

[[研究前沿/00-总览|研究前沿总览]] · [[研究前沿/uplift模型迭代/01-论文原文与精读/README|论文原文与精读]] · [[研究前沿/uplift模型迭代/02-可复用方法卡/README|可复用方法卡]] · [[研究前沿/uplift模型迭代/03-实验假设与结果/README|实验假设与结果]]

## 中文关键词

uplift建模、增益建模、异质性处理效应、个体处理效应、多处理效应、连续干预、剂量响应、因果表征、反事实学习、增量收益优化。

## 直接相关英文关键词

- uplift modeling
- heterogeneous treatment effect
- conditional average treatment effect
- individual treatment effect
- multi-treatment uplift
- continuous treatment effect
- dose-response estimation
- revenue uplift modeling

## 跨领域方法关键词

- causal representation learning
- orthogonal learning
- double machine learning
- doubly robust learning
- observational and randomized data fusion
- treatment-aware attention
- monotonic neural network
- multi-task learning for treatment effects
- uplift calibration
- policy learning
- off-policy evaluation
- decision-focused causal learning
- incremental profit optimization

## 可直接执行的检索组合

每条独立检索，按检索日期附加时间窗口；不得要求同一论文命中全部词。

- `"uplift modeling" deep learning`
- `"treatment effect estimation" representation learning`
- `"multi-treatment" uplift`
- `"continuous treatment" "dose response"`
- `"treatment effect" randomized observational data fusion`
- `"uplift" calibration ranking evaluation`
- `"causal" "decision-focused learning"`
- `uplift 异质性处理效应 多处理 连续干预 模型`

扩展路线：

- `"treatment effect" Transformer attention`
- `"causal inference" orthogonal representation`
- `"uplift" multi-task monotonic uncertainty`
- `"policy learning" heterogeneous treatment effects`

## 收录边界

不要求来自网约车、营销或已有生产系统。医疗、广告、推荐、经济学等领域的方法，只要对处理效应、干预响应或因果决策有明确模块价值，都可收录。普通 CTR/CVR、通用 Transformer、LLM 或推荐模型须指出具体可迁移机制，不能只凭标题沾边入库。

论文创新模块和效果证据是主要标准；当前项目是否能立即接入仅作附注。跨方向论文按最主要贡献确定正文目录，在其他方向建立链接。

## 已有知识关联

[[论文精读/TaQFormer/TaQFormer：多维优惠券建模与OBS-RCT融合|TaQFormer 已有完整精读]]；[[知识体系/04-因果推断/README|因果推断知识体系]]；[[自动出价论文精读/出价因果决策论文精读/README|DFCL 与 Bi-DFCL 阅读入口]]。已有原笔记保持为唯一正文，在这里建立索引。

## 初始检索线索

已有 5 篇已播报记录见运行状态；这些记录不代表都已完成 Obsidian 精读。TaQFormer 已有精读，其余按来源核验后补充。


## 2026-11-05 更新

[[研究前沿/uplift模型迭代/01-论文原文与精读/PPDF/精读|PPDF 关键方法精读]] · [[研究前沿/_运行记录/2026-11-05-三方向检索|本期检索记录]]


## 2026-11-05 队列精读与处理规则

取消每日总篇数及每方向篇数上限；按创新价值、机制清晰度和可信效果证据决定精读数量，不凑数。每天先检查已有待精读队列，与新候选按价值、证据及等待时间共同排序，持续处理旧队列。只因原文不可访问、证据待核实或执行实际中断等具体原因保留待处理，并记录下一步；不因达到篇数或固定阅读预算而入队。理论与有价值的负面结论同样可收录。

[[研究前沿/uplift模型迭代/01-论文原文与精读/CMTP/精读|CMTP]] · [[研究前沿/uplift模型迭代/01-论文原文与精读/SIRNET/精读|SIRNET]]

[[研究前沿/_运行记录/2026-11-05-队列精读|本次9篇精读与19张方法卡]]


<!-- 2026-11-06-daily-update -->
## 2026-11-06 检索与精读

新增精读 10 篇、方法卡 15 张、未运行实验假设 2 项。其中 4 篇为 11 月 4 日已播报论文的补精读，不是新发表论文。

[[研究前沿/_运行记录/2026-11-06-三方向检索与精读|本期全部论文、证据与检索覆盖]] · [[研究前沿/_运行记录/待处理队列|当前待处理状态]]

## 2026-11-09 检索与精读

6 篇新增精读、6 张方法卡、4 个未运行实验。[[研究前沿/_运行记录/2026-11-09-三方向检索与精读|逐篇目录与证据]]
