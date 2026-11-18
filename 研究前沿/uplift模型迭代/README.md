---
type: "索引"
topics: ["uplift模型迭代","模型迭代"]
status: "维护中"
created: "2026-11-04"
---

# uplift模型迭代

自 2026-11-18 起，本文作为方法参考。当前日报检索入口见 [[研究前沿/预分单与候选扩展/README|预分单与候选扩展]] · [[研究前沿/换车与动态重匹配/README|换车与动态重匹配]] · [[研究前沿/升舱与预算分配/README|升舱与预算分配]] · [[研究前沿/等应答页表单与交互决策/README|等应答页表单与交互决策]] · [[研究前沿/模型自进化/README|模型自进化]]。


怎样更准确、稳健、高效地估计干预增量，并把估计用于排序、分配和决策？

**策略迭代阅读入口**　[[研究前沿/uplift模型迭代/按交易策略先读|阅读顺序、可改模块与第一步对照]]

## 第一次读，从这里开始


先读 [[研究前沿/uplift模型迭代/01-论文原文与精读/PPDF/精读|随机试验很小时，观察数据能帮什么忙]]。读完试着说清两件事：哪批数据决定要估计谁的增量，哪批数据能帮助减少估计的波动。

## 按研究问题阅读

### 干预比不干预多带来多少

先定人群和对照。[[研究前沿/uplift模型迭代/01-论文原文与精读/PPDF/精读|PPDF]] 用随机试验识别试验人群的平均或分组增量，再用观察数据辅助拟合。若已经训练好模型，想判断它找出的“高增量人群”经不经得起检验，可读 [[研究前沿/uplift模型迭代/01-论文原文与精读/ValidatableUplift/精读|ValidatableUplift]]：先在训练集定好划分、方向和阈值，再到独立样本检验。前者关心估计精度，后者关心同时声称多个分组有效时的误报。

[[研究前沿/uplift模型迭代/02-可复用方法卡/PPDF-drfusion|两种数据怎样进入同一个损失]] · [[研究前沿/uplift模型迭代/03-实验假设与结果/2026-11-05-PPDF-候选假设|未运行：固定表示后比较融合损失]]

### 哪些数据足以识别增量

同一人只能看到一条结果。即使全程随机分组，两个组的结果分布也不足以确定个体增量的方差。[JointPOBounds 的上下界（原文）](https://arxiv.org/abs/2611.07536v1) 解释此时还能报告多窄的范围。如果发券会影响相邻用户，[[研究前沿/uplift模型迭代/01-论文原文与精读/NEDNet/精读|NEDNet 的自身与邻居效应]] 要另外记录邻居暴露，检查各组合是否在数据里出现，并检验自身处理和邻居暴露能否相加。它的效果来自两个社交网络的半合成实验。

[[研究前沿/uplift模型迭代/03-实验假设与结果/检验网络暴露分支遗漏的处理交互|未运行：加入处理与邻居暴露的交互，看加性分支何时失效]]

### 预算固定时怎样选档

如果每轮都可以探索，[[多档干预下，怎样判断对一个人再加一档是否值得|ActionCenteredCBwK]] 用当轮各档被选中的实际概率估计相对不干预的增量，再用剩余预算筛动作。若分配器已经固定，[[模型迭代思想记录/LCM-Promo：怎样把带场景的历史行为用到预测里|LCM-Promo 方法笔记]] 提供另一种对照：保持同一全局预算和分配器，只换促销响应模型。前者的对照来自半合成环境；后者报告了真实平台上更换模型的整体 A/B 结果。读前先确认自己能改估计器、分配器，还是两者都能改。

[[研究前沿/uplift模型迭代/02-可复用方法卡/按实际抽样分布中心化多档动作|多档动作怎样中心化]] · [[研究前沿/uplift模型迭代/03-实验假设与结果/预算固定时基线错设对多档增量决策的影响|未运行：固定预算和控制器，只替换增量估计]]

## 完整资料与相关精读

[[研究前沿/00-总览|研究前沿总览]] · [[研究前沿/uplift模型迭代/01-论文原文与精读/README|论文原文与精读]] · [[研究前沿/uplift模型迭代/02-可复用方法卡/README|可复用方法卡]] · [[研究前沿/uplift模型迭代/03-实验假设与结果/README|实验假设与结果]]

以往精读另见 [[研究前沿/uplift模型迭代/01-论文原文与精读/CMTP/精读|CMTP]] · [[研究前沿/uplift模型迭代/01-论文原文与精读/SIRNET/精读|SIRNET]]。

[[研究前沿/_运行记录/README|最近一期与历史记录]] · [[研究前沿/_运行记录/待处理队列|待核原文]]

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

公共短查询逐条执行。

- `"multi-treatment uplift" policy evaluation`
- `"uplift modeling" fixed budget`
- `"dose-response" pricing incentives`
- `"policy learning" multiple budget constraints`
- `"offline policy evaluation" randomized targeting`
- `多档补贴 增量完单 策略评估`

跨领域机制补查：

- `"heterogeneous treatment effects" ranking calibration`
- `"causal representation learning" multiple treatments`

## 收录边界

优先看发单前一次表单曝光中可选的折扣、补贴或展示组合。记录可选动作和不干预基线、随机化单位、预算及业务约束；在相同成本或相同触达比例下，检查哪种规则产生更多增量呼叫、完单或净收益。相同触达比例只有在单位成本相当时才近似同预算。也接纳能改变相邻档响应估计、策略排序或约束评估的表示、损失与校准模块。 依总规则判为主读、前沿观察或本轮略过。

本地依据　[[花小猪/2026年LR/【LR26-052】乘客与增长-技术建设-可变决策空间与双约束问题的Uplift 模型评估优化-V1.0|乘客与增长-技术建设-可变决策空间与双约束问题的Uplift 模型评估优化-V1.0]] · [[花小猪/2026年LR/【LR26-043】乘客与增长-表单策略-平台联合决策V4离线规划求解-V1.0|乘客与增长-表单策略-平台联合决策V4离线规划求解-V1.0]]


不要求来自网约车、营销或已有生产系统。医疗、广告、推荐、经济学等领域的方法，只要对处理效应、干预响应或因果决策有明确模块价值，都可收录。普通 CTR/CVR、通用 Transformer、LLM 或推荐模型须指出具体可迁移机制，不能只凭标题沾边入库。

论文创新模块和效果证据是主要标准；当前项目是否能立即接入仅作附注。跨方向论文按最主要贡献确定正文目录，在其他方向建立链接。

## 已有知识关联

[[论文精读/TaQFormer/TaQFormer：多维优惠券建模与OBS-RCT融合|TaQFormer 已有完整精读]]；[[知识体系/04-因果推断/README|因果推断知识体系]]；[[论文精读/自动出价论文精读/出价因果决策论文精读/README|DFCL 与 Bi-DFCL 阅读入口]]。已有原笔记保持为唯一正文，在这里建立索引。

## 初始检索线索

已有 5 篇已播报记录见运行状态；这些记录不代表都已完成 Obsidian 精读。TaQFormer 已有精读，其余按来源核验后补充。

## 队列处理规则

取消每日总篇数及每方向篇数上限；按创新价值、机制清晰度和可信效果证据决定精读数量，不凑数。每天先检查已有待精读队列，与新候选按价值、证据及等待时间共同排序，持续处理旧队列。只因原文不可访问、证据待核实或执行实际中断等具体原因保留待处理，并记录下一步；不因达到篇数或固定阅读预算而入队。理论与有价值的负面结论同样可收录。
