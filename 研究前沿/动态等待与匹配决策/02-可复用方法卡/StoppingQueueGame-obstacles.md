---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-13"
module_id: "StoppingQueueGame-obstacles"
source_papers: ["arxiv:2611.10396"]
version: "v1"
local_validation: "未运行"
---

# 用双边终止支付约束继续价值

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/StoppingQueueGame/精读|Discrete-Time Zero-Sum Markov Games with Control, Stopping, and State-Dependent Discounting]]

## 输入、流程与输出

输入状态转移、双方动作与转移支付、状态折现和两种终止支付。先对继续求矩阵博弈值，再作 max/min 更新至误差满足条件，输出每个状态的双方控制和首次进入终止集合的规则。

## 最小采用单元与依赖

最小单元是有优先顺序的继续价值更新。需要零和、同时停止收益约定与已知的单阶段模型。用数据估计转移时还需另行校准。

## 原文证据与实现

§3 式 (3.6)，定理 4.2 与算法 I/II；表 1–2 的均衡仅适用于 §6 的人工参数。

版本页与全文未列实现仓库。§5 算法 I/II 及 §6 的转移概率、支付、折现参数可作为重建入口。

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/StoppingQueueGame-tie|同时退出时的结算顺序能否翻转等待边界]]
