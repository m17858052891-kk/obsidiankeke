---
type: "实验"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-13"
experiment_id: "SparsePredictDemote-inference"
experiment_status: "待设计/未运行"
source_papers: ["arxiv:2611.10293"]
source_modules: ["SparsePredictDemote-sparse"]
local_validation: "未运行"
---

# 把预测本身占用的处理时间算进去，稀疏查询何时得益

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/SparsePredictDemote/精读|Sparse Predict and Demote: Optimal Scheduling with Minimal Size Advice]]

[[研究前沿/动态等待与匹配决策/02-可复用方法卡/SparsePredictDemote-sparse|按已获服务时长抽查，再把长任务降级]]

## 假设、最小改动与基线

在同一批任务上切换不查询、到达即查、累积服务后抽查，保留 FCFS、FB 和免费精确 SRPT 作为对照；稀疏策略用相同预测器及后台规则。

## 数据、口径与约束

用到达时刻、服务量、每次预测占用及误差，按尾部族和负载分层。主指标为平均响应时间，另看分层 P99、降级率和等待队列稳定性。

## 预算与失败判据

合成流每档 30 个种子；若计入查询后平均无改善、队列发散或低优先任务触犯预先设定的尾延时容限，认为该档不适用。CPU 预算待确认。

本地实验尚未运行。
