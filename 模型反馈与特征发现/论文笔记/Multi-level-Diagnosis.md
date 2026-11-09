---
type: 文献研究笔记
topics: [特征工程, 模型反馈]
created: 2026-11-06
year: 2025
category: "结构反馈与语言生成"
---

# Multi-level Diagnosis and Evaluation for Robust Tabular Feature Engineering with Large Language Models

> [!summary] 为什么读这篇
> 对关键变量、关系符号、阈值三层诊断；按三层均分选FeatLLM规则集合

[论文/作者来源](https://aclanthology.org/2025.findings-emnlp.249/) · [代码来源](https://github.com/DohaLim/Robustness-eval)

**版本与发表状态：** Findings EMNLP 2025（ACL官方页；README引文较宽泛）  
**实际阅读范围：** 全文方法、Table1、局限及仓库  
**本研究定位：** 结构反馈与语言生成；补充阅读。未运行算法。

## 反馈怎样进入搜索

**反馈内容：** 协方差/符号/阈值等标签统计；主要为生成后诊断过滤

**搜索单位：** 从10个规则集选top3或删bottom3再等权集成

**机制：** 对关键变量、关系符号、阈值三层诊断；按三层均分选FeatLLM规则集合

## 对两个关键问题的意义

**互补组合：** 集合筛选的质量指标不等于条件增益；共线/交互能力未充分覆盖

**跨模型或跨任务：** 传统模型是比较基线；不构成冻结特征跨模型迁移

## 已核的验证与效果

**设置：** Table1，Credit-g，4-shot，3随机训练样例种子；AUC×100

**FeatLLM：** 52.27

**top3：** 57.77

**relative_improvement_percent：** 10.52

**absolute_points：** 5.5

**设置：** Table1，Adult，8-shot，AUC×100

**FeatLLM：** 87.29

**top3：** 86.35

**drop_bottom3：** 86.95

以上保留论文实际设置。若只读摘要或定向段落，不从未读表格补写数值；作者报告与本研究是否复现是两件事。

## 局限与取舍

golden relation是协方差符号，不能当因果；增加描述和fewshot有时降低可靠性；强过滤也会降低性能

**可以支持的判断：**

将一个总分拆成变量/关系/阈值可诊断生成失效位置

**不能据此推出：**

三级信号已用于模型误差驱动闭环

up to10.52%是普遍或绝对百分点增益

其中对搜索盲区、适用范围与缺失对照的解释，是本研究根据方法或表格作出的判断；不把它们冒充作者报告的实验损失。

## 实现核查与复查位置

**仓库层级：** 已读README或目录；未运行

已读README和根目录；evaluator.py、main.py、prompt_generator.py、data/、requirements.txt存在；未运行

**论文位置：** §3.3

§3.4

§4.2

Table1

Limitations

代码观察针对核查时的公开版本；没有逐项重放论文结果，也没有把找到链接等同于可复现。

返回：[[模型反馈与特征发现/03-论文与代码总索引|论文与代码总索引]] · [[模型反馈与特征发现/01-研究结论与技术路线|研究主报告]]
