---
type: 文献研究笔记
topics: [特征工程, 模型反馈]
created: 2026-11-06
year: 2025
category: "多模型反馈与经验学习"
---

# Automated Feature Engineering for Automated Machine Learning (GELFE)

> [!summary] 为什么读这篇
> 扩展LFE的meta-features和算子，以每算子随机森林元模型推荐变换，再与TPOT AutoML结合。

[论文/作者来源](https://personal.eur.nl/frasincar/papers/KBS2025a/kbs2025a.pdf) · [代码来源](https://github.com/Casper-de-Winter/GELFE)

**版本与发表状态：** Knowledge-Based Systems 321:113671, peer reviewed  
**实际阅读范围：** 方法/多评价器标签/实验与源码深核  
**本研究定位：** 多模型反馈与经验学习；重点阅读。未运行算法。

## 反馈怎样进入搜索

**反馈内容：** LR/RF/LinearSVM/KNN五折balanced accuracy；任一模型超过门槛即正类。

**搜索单位：** feature-set×operator

**机制：** 扩展LFE的meta-features和算子，以每算子随机森林元模型推荐变换，再与TPOT AutoML结合。

## 对两个关键问题的意义

**互补组合：** 当前特征集影响选择；多模型反馈采用OR目标而非共同改善。

**跨模型或跨任务：** 跨数据集元学习 + 显式多评价器元标签；主要服务可以选模型的AutoML，不是固定特征全部learner受益。

## 已核的验证与效果

§4/Table5明确electricity等AutoFE+RF可比RF差；AutoML联合效果不能等同于固定RF效果。

以上保留论文实际设置。若只读摘要或定向段落，不从未读表格补写数值；作者报告与本研究是否复现是两件事。

## 局限与取舍

OR标签可能保留伤害其他learner的候选

论文与代码阈值不完全一致

所查DataSetTrainV2.py的二元循环被注释

**可以支持的判断：**

多评价器标签可以服务后续AutoML选择

多评价器并不自动等于多模型共同获益

**不能据此推出：**

其OR元标签保证所有模型不退化

当前repo直接完整复现论文

其中对搜索盲区、适用范围与缺失对照的解释，是本研究根据方法或表格作出的判断；不把它们冒充作者报告的实验损失。

## 实现核查与复查位置

**仓库层级：** 已读源码；未运行

已读材料：DataSetTrainV2.py；README/根目录。

四模型与NImprov>=1核实；代码阈值0.05*(1-base)，正文min(0.01,0.05*(1-base))

**论文位置：** §3.1 pp11-13

§4/Table 5 pp21-22

DataSetTrainV2.py Train()

代码观察针对核查时的公开版本；没有逐项重放论文结果，也没有把找到链接等同于可复现。

返回：[[模型反馈与特征发现/03-论文与代码总索引|论文与代码总索引]] · [[模型反馈与特征发现/01-研究结论与技术路线|研究主报告]]
