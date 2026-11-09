---
type: 文献研究笔记
topics: [特征工程, 模型反馈]
created: 2026-11-06
year: 2022
category: "多模型反馈与经验学习"
---

# MACFE: A Meta-learning and Causality Based Feature Engineering Framework

> [!summary] 为什么读这篇
> 特征直方图+dataset meta-features检索MIC收益经验；DAGClassifier预选原始特征，再组合变换。

[论文/作者来源](https://arxiv.org/pdf/2207.04010) · [代码来源](https://github.com/Ivanrs297/MACFE)

**版本与发表状态：** 2022 Springer chapter linked by official repo; arXiv available  
**实际阅读范围：** 方法§4-5与训练/评价代码深核  
**本研究定位：** 多模型反馈与经验学习；补充阅读。未运行算法。

## 反馈怎样进入搜索

**反馈内容：** 元经验为MIC差，不是八模型反馈；八分类器只在末端评估。

**搜索单位：** 变换推荐矩阵及迭代一元/二元变换

**机制：** 特征直方图+dataset meta-features检索MIC收益经验；DAGClassifier预选原始特征，再组合变换。

## 对两个关键问题的意义

**互补组合：** 统计相关与高阶构造可作proposal先验；不保证任务条件增益。

**跨模型或跨任务：** 同一变换流程对八分类器评估；公开代码有有效性风险，不能作为严格冻结transfer高强证据。

## 已核的验证与效果

本次研究不报告摘要提升百分比；Table2存在部分raw优于MACFE格。

以上保留论文实际设置。若只读摘要或定向段落，不从未读表格补写数值；作者报告与本研究是否复现是两件事。

## 局限与取舍

公开experiments.py先用全数据y监督选特征，再在run_models里CV

evaluations.py的KNN/LR名称与classifier顺序反转

观测DAG依赖因果假设

不能断言论文内部实验必用完全相同代码

**可以支持的判断：**

历史统计经验可推荐变换

显式模型无关先验不等于各模型收益一致

**不能据此推出：**

八评价器共同训练

所报增益可视为严格无泄漏泛化证据

DAG发现即证明因果

其中对搜索盲区、适用范围与缺失对照的解释，是本研究根据方法或表格作出的判断；不把它们冒充作者报告的实验损失。

## 实现核查与复查位置

**仓库层级：** 已读源码；未运行

已读材料：README；run.py；code/experiments.py；code/evaluations.py。

监督预处理不嵌套fold与名称反序问题；仅静态审计

**论文位置：** §4.2/Algorithms1-2

§5/Table2

code/experiments.py

code/evaluations.py

代码观察针对核查时的公开版本；没有逐项重放论文结果，也没有把找到链接等同于可复现。

返回：[[模型反馈与特征发现/03-论文与代码总索引|论文与代码总索引]] · [[模型反馈与特征发现/01-研究结论与技术路线|研究主报告]]
