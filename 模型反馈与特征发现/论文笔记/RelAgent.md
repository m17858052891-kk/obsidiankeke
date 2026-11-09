---
type: 文献研究笔记
topics: [特征工程, 模型反馈]
created: 2026-11-06
year: 2026
category: "结构反馈与语言生成"
---

# RelAgent: LLM Agents as Data Scientists for Relational Learning

> [!summary] 为什么读这篇
> 搜索SQL特征查询与下游模型配置；DuckDB evaluation workspace保留试验元数据及逐样本预测，agent用只读SQL对比同一行在不同版本的误差，决定下一步特征修改。

[论文/作者来源](https://arxiv.org/html/2605.07840) · [代码来源](https://github.com/HxyScotthuang/RelAgent)

**版本与发表状态：** arXiv v2 2026-10-21；作者仓库标NeurIPS 2026 accepted  
**实际阅读范围：** §4–5、Appendix A/B/G；三份核心代码已核  
**本研究定位：** 结构反馈与语言生成；重点阅读。未运行算法。

## 反馈怎样进入搜索

**反馈内容：** 逐样本预测/标签、跨版本错误变化、特征分布和重要性、试验历史；比只提供总分可追溯。

**搜索单位：** 整套SQL特征程序与模型配置。

**机制：** 搜索SQL特征查询与下游模型配置；DuckDB evaluation workspace保留试验元数据及逐样本预测，agent用只读SQL对比同一行在不同版本的误差，决定下一步特征修改。

## 对两个关键问题的意义

**互补组合：** 可成组构造关系聚合及连接，允许回溯版本；无全局最优保证。

**跨模型或跨任务：** 联合选择特征与learner是共同适配，不能视为固定特征跨learner迁移。

## 已核的验证与效果

Table7 RelBenchV1实体分类平均AUROC：完整78.38，去workspace75.78，去feedback66.86。这里只支持该设置下workspace有增量，不能把全部提升归因于任意一种诊断。

以上保留论文实际设置。若只读摘要或定向段落，不从未读表格补写数值；作者报告与本研究是否复现是两件事。

## 局限与取舍

诊断表含验证标签，必须与预测特征路径隔离；频繁查询验证误差仍有适应性选择压力；SQL可读不等于预测因果可解释。

**可以支持的判断：**

结构化可查询的反馈工作区能支持精细修正

公开代码包含对应诊断接口

**不能据此推出：**

该workspace消除了验证过拟合

跨模型选择等同迁移通用特征

其中对搜索盲区、适用范围与缺失对照的解释，是本研究根据方法或表格作出的判断；不把它们冒充作者报告的实验损失。

## 实现核查与复查位置

**仓库层级：** 已读源码；未运行

README、完整目录、eval_workspace.py、tools.py、validation.py已打开；确认trials/eval_predictions持久表、只读查询接口、残差相关/特征诊断函数。未执行。

**论文位置：** §4.1

§5.4 Table7

Appendix A Table9、B case study

scientist/eval_workspace.py；tools.py；validation.py

代码观察针对核查时的公开版本；没有逐项重放论文结果，也没有把找到链接等同于可复现。

返回：[[模型反馈与特征发现/03-论文与代码总索引|论文与代码总索引]] · [[模型反馈与特征发现/01-研究结论与技术路线|研究主报告]]
