---
type: 文献研究笔记
topics: [特征工程, 模型反馈]
created: 2026-11-06
year: 2026
category: "多模型反馈与经验学习"
---

# Do Tabular Foundation Models Still Need Feature Engineering?

> [!summary] 为什么读这篇
> 固定模型版本与默认推断配置，配对比较26预设FE条件；跨版本看可改善空间。

[论文/作者来源](https://arxiv.org/html/2609.13202v1)

**版本与发表状态：** arXiv preprint  
**实际阅读范围：** 全文方法、Results/Table4-5与限制深核  
**本研究定位：** 多模型反馈与经验学习；重点阅读。未运行算法。

## 反馈怎样进入搜索

**反馈内容：** 此文是评估研究，不训练FE生成器。

**搜索单位：** 预设变换/组合pipeline/版本

**机制：** 固定模型版本与默认推断配置，配对比较26预设FE条件；跨版本看可改善空间。

## 对两个关键问题的意义

**互补组合：** 分清典型变换效果与best-observed oracle上界。

**跨模型或跨任务：** 多个TFM版本的干预效应比较；非LLM搜索程序冻结迁移。

## 已核的验证与效果

13数据集、12版本、30splits；PFN分类best gain1.21→.25pp，PFN回归2.06→.19% relative RMSE reduction，ICL分类.73→.10pp；BHq=.0234，Holmp=.0502。

以上保留论文实际设置。若只读摘要或定向段落，不从未读表格补写数值；作者报告与本研究是否复现是两件事。

## 局限与取舍

小数据集、有限预设变换，不能泛化为FE无用

best observed是oracle不是可部署selection

NNRC用测试协变量且未独立validation调参

未发现官方repo

**可以支持的判断：**

目标learner升级会改变FE价值

评估需同learner raw baseline

通用FE平均收益在该范围较小

**不能据此推出：**

所有任务/所有LLM定制FE都无价值

强TFM能力提升是已严格识别的唯一因果原因

NNRC已得到独立部署有效性验证

其中对搜索盲区、适用范围与缺失对照的解释，是本研究根据方法或表格作出的判断；不把它们冒充作者报告的实验损失。

## 实现核查与复查位置

**仓库层级：** 未确认作者仓库

正文与标题检索未核到官方repo

**论文位置：** Experiments

ProblemSetup bestobserved B

Results/Table4/Table5

Algorithm1/Discussion

本次没有运行复现；未确认或未打开仓库不等于该研究没有代码。

返回：[[模型反馈与特征发现/03-论文与代码总索引|论文与代码总索引]] · [[模型反馈与特征发现/01-研究结论与技术路线|研究主报告]]
