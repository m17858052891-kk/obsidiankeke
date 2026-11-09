---
type: 文献研究笔记
topics: [特征工程, 模型反馈]
created: 2026-11-06
year: 2023
category: "互补搜索与可微构造"
---

# OpenFE: Automated Feature Generation with Expert-level Performance

> [!summary] 为什么读这篇
> 枚举类型化一元/二元算子；FeatureBoost利用基模型预测init_score；stage1逐候选successive halving；stage2原始列+保留候选共同训练后归因排名。

[论文/作者来源](https://proceedings.mlr.press/v202/zhang23ay.html) · [代码来源](https://github.com/IIIS-Li-Group/OpenFE)

**版本与发表状态：** ICML 2023  
**实际阅读范围：** 核心：论文§3/§5/附录片段；README+openfe/openfe.py  
**本研究定位：** 互补搜索与可微构造；重点阅读。未运行算法。

## 反馈怎样进入搜索

**反馈内容：** stage1默认残差/增量拟合的验证表现；stage2默认LightGBM gain，可选permutation。

**搜索单位：** stage1单列候选；stage2联合输入归因；最后仍top-k列。

**机制：** 枚举类型化一元/二元算子；FeatureBoost利用基模型预测init_score；stage1逐候选successive halving；stage2原始列+保留候选共同训练后归因排名。

## 对两个关键问题的意义

**互补组合：** 联合阶段能体现条件交互，但第一阶段丢掉的候选不会自动恢复。树Gain来自多变量树路径，不能称为纯单变量检验。

**跨模型或跨任务：** 论文Table4将生成特征用于多种DNN；迁移详情由cross_model分支核。

## 已核的验证与效果

**设置：** 10公共集同一train/validation/test分割，LightGBM；base特征调参；各方法相同新列数、一阶特征；10次重复。Table3/§5.3。

**结果：** California RMSE 0.432±.004→.421±.002，Diabetes AUC .731±.001→.888±.002（特定transductive处理须标注）。附加68个CC18任务有19个未显著改善；二阶特征在多数基准未带来收益。

以上保留论文实际设置。若只读摘要或定向段落，不从未读表格补写数值；作者报告与本研究是否复现是两件事。

## 局限与取舍

早期逐候选剪枝可能漏纯协同；gain不等于因果贡献；第一阶段固定基预测不是完整重训；论文transductive聚合与线上inductive须区分。

**可以支持的判断：**

联合归因与逐列剪枝并存

提供高效增量评价，且可跳过stage1

**不能据此推出：**

全流程是单变量检验

gain为零则无互补价值

paper里的集合argmax证明算法全局最优

其中对搜索盲区、适用范围与缺失对照的解释，是本研究根据方法或表格作出的判断；不把它们冒充作者报告的实验损失。

## 实现核查与复查位置

**仓库层级：** 已读源码；未运行

已读材料：README.md；openfe/openfe.py。

默认 stage1_metric='predictive'、stage2_metric='gain_importance'；stage2把原始列与候选共同训练，importance_type='gain'；is_stage1=False可跳过第一阶段。

**论文位置：** Alg2–4；§3.2.2 p4；Table3；§5.5/§5 Discussion p7

code openfe.py:142/154/155/241/504/599

代码观察针对核查时的公开版本；没有逐项重放论文结果，也没有把找到链接等同于可复现。

返回：[[模型反馈与特征发现/03-论文与代码总索引|论文与代码总索引]] · [[模型反馈与特征发现/01-研究结论与技术路线|研究主报告]]
