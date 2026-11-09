---
type: 文献研究笔记
topics: [特征工程, 模型反馈]
created: 2026-11-06
year: 2025
category: "互补搜索与可微构造"
---

# Collaborative Multi-Agent Reinforcement Learning for Automated Feature Transformation with Graph-Driven Path Optimization

> [!summary] 为什么读这篇
> 在变换roadmap上聚类特征组，多个agent选head group/operation/tail group，group-wise crossing，图剪枝控制路径。

[论文/作者来源](https://arxiv.org/abs/2504.17355)

**版本与发表状态：** arXiv；方法TCTO  
**实际阅读范围：** HTML§III方法概要  
**本研究定位：** 互补搜索与可微构造；补充阅读。未运行算法。

## 反馈怎样进入搜索

**反馈内容：** 下游表现+变换深度复杂度奖励

**搜索单位：** 特征组与路径

**机制：** 在变换roadmap上聚类特征组，多个agent选head group/operation/tail group，group-wise crossing，图剪枝控制路径。

## 对两个关键问题的意义

**互补组合：** 组级提议提高搜索覆盖，仍需区分组内cross生成和最终集合互补。

**跨模型或跨任务：** 本次研究未核实直接跨模型特征迁移证据。

## 已核的验证与效果

**设置：** 未深入逐表核查，故不引用数字。

以上保留论文实际设置。若只读摘要或定向段落，不从未读表格补写数值；作者报告与本研究是否复现是两件事。

## 局限与取舍

非凸RL、组划分与剪枝偏差；未经逐表核验的headline不录。

**可以支持的判断：**

在变换roadmap上聚类特征组，多个agent选head group/operation/tail group，group-wise crossing，图剪枝控制路径。

**不能据此推出：**

任意高阶互补组合的全局最优保证

未经重评估的跨模型/业务收益

其中对搜索盲区、适用范围与缺失对照的解释，是本研究根据方法或表格作出的判断；不把它们冒充作者报告的实验损失。

## 实现核查与复查位置

**仓库层级：** 未确认作者仓库

未核作者repo。

**论文位置：** §III-A group-wise transformation

§III-C dual reward

§III-D prune roadmap

本次没有运行复现；未确认或未打开仓库不等于该研究没有代码。

返回：[[模型反馈与特征发现/03-论文与代码总索引|论文与代码总索引]] · [[模型反馈与特征发现/01-研究结论与技术路线|研究主报告]]
