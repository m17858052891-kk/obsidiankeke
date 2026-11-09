---
type: 文献研究笔记
topics: [特征工程, 模型反馈]
created: 2026-11-06
year: 2023
category: "理论、选择与迁移边界"
---

# XTab: Cross-table Pretraining for Tabular Transformers

> [!summary] 为什么读这篇
> 表专属featurizer/head与共享transformer分离，联邦式预训练共享部分。

[论文/作者来源](https://proceedings.mlr.press/v202/zhu23k.html) · [代码来源](https://github.com/BingzhaoZhu/XTab)

**版本与发表状态：** ICML 2023  
**实际阅读范围：** 摘要/结论/官方源码定向核  
**本研究定位：** 理论、选择与迁移边界；补充阅读。未运行算法。

## 反馈怎样进入搜索

**反馈内容：** 重构/预训练损失，目标任务微调。

**搜索单位：** 共享backbone参数

**机制：** 表专属featurizer/head与共享transformer分离，联邦式预训练共享部分。

## 对两个关键问题的意义

**互补组合：** 不同schema共享通用表处理结构。

**跨模型或跨任务：** 多个Transformer可使用该预训练方法，但不代表一个显式特征矩阵迁移到所有模型。

## 已核的验证与效果

论文结论承认仍落后CatBoost；不把多backbone适用性写成feature transfer。

以上保留论文实际设置。若只读摘要或定向段落，不从未读表格补写数值；作者报告与本研究是否复现是两件事。

## 局限与取舍

需要表专属输入映射/微调

完整预训练仓库依赖AWS/S3及打包修改版本

**可以支持的判断：**

跨表预训练可迁移参数先验

**不能据此推出：**

已经验证树模型共享其生成特征

其中对搜索盲区、适用范围与缺失对照的解释，是本研究根据方法或表格作出的判断；不把它们冒充作者报告的实验损失。

## 实现核查与复查位置

**仓库层级：** 已读源码；未运行

已读材料：README；runexample.py。

FT_TRANSFORMER用checkpoint微调；完整框架以zip和AWS流程提供

**论文位置：** Paper§5 Conclusion

README

runexample.py finetune_on

代码观察针对核查时的公开版本；没有逐项重放论文结果，也没有把找到链接等同于可复现。

返回：[[模型反馈与特征发现/03-论文与代码总索引|论文与代码总索引]] · [[模型反馈与特征发现/01-研究结论与技术路线|研究主报告]]
