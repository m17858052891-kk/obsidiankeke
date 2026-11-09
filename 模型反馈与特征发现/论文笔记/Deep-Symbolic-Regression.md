---
type: 文献研究笔记
topics: [特征工程, 模型反馈]
created: 2026-11-06
year: 2021
category: "互补搜索与可微构造"
---

# Deep symbolic regression: Recovering mathematical expressions from data via risk-seeking policy gradients

> [!summary] 为什么读这篇
> RNN采样合法表达式，优化常数，以拟合奖励评估；risk-seeking policy gradient只用top-ε高回报表达式更新，辅以熵奖励。

[论文/作者来源](https://openreview.net/forum?id=m5Qsh0kBQG) · [代码来源](https://github.com/dso-org/deep-symbolic-optimization)

**版本与发表状态：** ICLR 2021  
**实际阅读范围：** 核心：全文算法/实验；DSO README  
**本研究定位：** 互补搜索与可微构造；补充阅读。未运行算法。

## 反馈怎样进入搜索

**反馈内容：** 整棵表达式拟合分数驱动生成分布；不需每个子树单独有预测价值。

**搜索单位：** 完整表达式/程序。

**机制：** RNN采样合法表达式，优化常数，以拟合奖励评估；risk-seeking policy gradient只用top-ε高回报表达式更新，辅以熵奖励。

## 对两个关键问题的意义

**互补组合：** 可一跳采样组合，避免必须逐列增益的硬约束；但奖励稀疏、语法约束与分布塌缩仍存在。

**跨模型或跨任务：** 本质符号回归直接预测y；把表达式作任意模型的新特征是本报告推论，须二次评价。

## 已核的验证与效果

**设置：** Nguyen12表达式；100独立seed；DSR/PQT/VPG/GP各最多200万表达式评估；两任务调参后固定；recovery为符号等价。

**结果：** Table1 DSR在Nguyen12 recovery=0%；不能用若干成功任务宣称通用表达式恢复。

以上保留论文实际设置。若只读摘要或定向段落，不从未读表格补写数值；作者报告与本研究是否复现是两件事。

## 局限与取舍

目标是函数拟合而非条件增益特征；当前DSO repo包含2021/2022后续GP等算法，不能把最新表现归到ICLR2021。

**可以支持的判断：**

整程序反馈可学习组合构造分布

**不能据此推出：**

可恢复所有表达式

DSO当前最高成绩等于原始DSR成绩

其中对搜索盲区、适用范围与缺失对照的解释，是本研究根据方法或表格作出的判断；不把它们冒充作者报告的实验损失。

## 实现核查与复查位置

**仓库层级：** 已读README或目录；未运行

已读材料：README.md。

仓库明确支持symbolic regression/control并列多篇后续论文；PyTorch重构另仓库。

**论文位置：** §3 risk-seeking Eq1/Prop1/Alg1

§4/Table1

DSO README publications列表

代码观察针对核查时的公开版本；没有逐项重放论文结果，也没有把找到链接等同于可复现。

返回：[[模型反馈与特征发现/03-论文与代码总索引|论文与代码总索引]] · [[模型反馈与特征发现/01-研究结论与技术路线|研究主报告]]
