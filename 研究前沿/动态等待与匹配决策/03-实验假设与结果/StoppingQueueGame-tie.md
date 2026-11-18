---
type: "实验"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-13"
experiment_id: "StoppingQueueGame-tie"
experiment_status: "待设计/未运行"
source_papers: ["arxiv:2611.10396"]
source_modules: ["StoppingQueueGame-obstacles"]
local_validation: "未运行"
---

# 同时退出时的结算顺序能否翻转等待边界

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/StoppingQueueGame/精读|Discrete-Time Zero-Sum Markov Games with Control, Stopping, and State-Dependent Discounting]]

[[研究前沿/动态等待与匹配决策/02-可复用方法卡/StoppingQueueGame-obstacles|用双边终止支付约束继续价值]]

## 假设、最小改动与基线

复制原文 §6 的队列表格并保持状态折现相同，只替换同时退出时的支付，再对照只允许客户停的版本。

## 数据、口径与约束

使用公开转移矩阵与成本参数。比较三组继续区间、初始队列价值、双方最优偏离收益；有限状态尾部沿用解析终值。

## 预算与失败判据

CPU 分别以 $10^{-6}$ 与更严精度求解。若停止集合在容差内一致，或表观翻转无法通过偏离收益核验，则不支持边界变化。

本地实验尚未运行。
