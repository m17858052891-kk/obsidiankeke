---
type: "实验"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-13"
experiment_id: "DepthPortfolio-selector"
experiment_status: "待设计/未运行"
source_papers: ["arxiv:2611.12293"]
source_modules: ["DepthPortfolio-pool"]
local_validation: "未运行"
---

# 分配收益来自候选覆盖、更多实际计算，还是更好的停止时机

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/DepthPortfolio/精读|Depth as a Candidate Source: Portfolio Allocation for Recurrent Test-Time Scaling in Large Language Models]]

[[研究前沿/动态等待与匹配决策/02-可复用方法卡/DepthPortfolio-pool|不同候选来源值得在何时多取一次]]

## 假设、最小改动与基线

固定选择器和相同候选缓存，对照等配额、与策略逐题匹配实际预算的随机配额、带显式停止的策略；另外统计 oracle 可选上限。

## 数据、口径与约束

使用公开题目或合成多来源请求、候选与离线标签，训练和测试按题隔离。主指标是真正选中的成功率，另报实际生成时间、无可行动作与主动停止各占多少。

## 预算与失败判据

固定测试池、按题配对区间，CPU 回放；若匹配实际预算后收益消失，不能归因为更好的选来源。真实生成额外预算待确认。

本地实验尚未运行。
