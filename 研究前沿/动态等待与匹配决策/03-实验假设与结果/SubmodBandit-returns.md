---
type: "实验"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-13"
experiment_id: "SubmodBandit-returns"
experiment_status: "待设计/未运行"
source_papers: ["arxiv:2611.11808"]
source_modules: ["SubmodBandit-counts"]
local_validation: "未运行"
---

# 候选搭配产生互补时，单调次模策略在哪里失效

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/SubmodBandit/精读|Efficient Online Submodular Maximization with Bandit Feedback]]

[[研究前沿/动态等待与匹配决策/02-可复用方法卡/SubmodBandit-counts|靠组规模和重复次数从整组反馈更新元素概率]]

## 假设、最小改动与基线

在相同组队合成流中固定单项价值、逐档提高互补项，比较 Sub-EW、MSE3、OpaqueGreedy 与均匀选 k 个。

## 数据、口径与约束

小规模候选表能穷举最佳固定集合；每轮仅向学习器给实际整组奖励。主指标为平均近似遗憾，另报真实累计收益、平均实际组规模和反馈延迟。

## 预算与失败判据

每档配对 30 个随机种子。先核对零互补档的已知理论条件；若交叉排序在同数据重复无稳定性，或源自漏算去重后集合，则不支持互补解释。CPU。

本地实验尚未运行。
