---
type: 文献研究笔记
topics: [特征工程, 模型反馈]
created: 2026-11-06
year: 2023
category: "理论、选择与迁移边界"
---

# STUNT: Few-shot Tabular Learning with Self-generated Tasks from Unlabeled Tables

> [!summary] 为什么读这篇
> 随机选列作伪目标构造few-shot任务，元学习encoder；伪validation用于调参/早停。

[论文/作者来源](https://arxiv.org/abs/2303.00918) · [代码来源](https://github.com/jaehyun513/STUNT)

**版本与发表状态：** ICLR 2023 Spotlight  
**实际阅读范围：** 摘要/README/评估源码定向核  
**本研究定位：** 理论、选择与迁移边界；补充阅读。未运行算法。

## 反馈怎样进入搜索

**反馈内容：** 自生成任务的预测损失与pseudo-validation。

**搜索单位：** 神经表示参数

**机制：** 随机选列作伪目标构造few-shot任务，元学习encoder；伪validation用于调参/早停。

## 对两个关键问题的意义

**互补组合：** 任务多样化可能改善表示泛化；非显式列协同搜索。

**跨模型或跨任务：** few-shot表征迁移/半监督；不是显式特征程序跨learner。

## 已核的验证与效果

本次研究不复述未逐表核验的benchmark数值。

以上保留论文实际设置。若只读摘要或定向段落，不从未读表格补写数值；作者报告与本研究是否复现是两件事。

## 局限与取舍

伪任务与真实任务匹配不是保证

官方eval是MLP encoder+prototype

**可以支持的判断：**

表格列可生成辅助任务训练表征

**不能据此推出：**

证明同一显式FE在RF/MLP/线性模型通用

其中对搜索盲区、适用范围与缺失对照的解释，是本研究根据方法或表格作出的判断；不把它们冒充作者报告的实验损失。

## 实现核查与复查位置

**仓库层级：** 已读源码；未运行

已读材料：README；eval.py。

从checkpoint获得embedding，再prototype分类

**论文位置：** Abstract

README

eval.py MLPProto/get_prototypes

代码观察针对核查时的公开版本；没有逐项重放论文结果，也没有把找到链接等同于可复现。

返回：[[模型反馈与特征发现/03-论文与代码总索引|论文与代码总索引]] · [[模型反馈与特征发现/01-研究结论与技术路线|研究主报告]]
