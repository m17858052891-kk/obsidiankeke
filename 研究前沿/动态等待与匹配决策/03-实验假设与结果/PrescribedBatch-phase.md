---
type: "实验"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-13"
experiment_id: "PrescribedBatch-phase"
experiment_status: "待设计/未运行"
source_papers: ["arxiv:2611.13757"]
source_modules: ["PrescribedBatch-clock", "PrescribedBatch-count"]
local_validation: "未运行"
---

# 同步不同队列的时钟，能节省多少重复采购

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/PrescribedBatch/精读|Stochastic Aggregation with Prescribed Resources and Additive Delay]]

[[研究前沿/动态等待与匹配决策/02-可复用方法卡/PrescribedBatch-clock|共享资源的多个队列怎样对齐服务时间]] · [[研究前沿/动态等待与匹配决策/02-可复用方法卡/PrescribedBatch-count|单资源批量如何随到达率和固定成本改变]]

## 假设、最小改动与基线

固定单类周期，仅移动时钟相位，对比同步与独立随机相位；增加一个所有类型同频和一个单独服务基线。

## 数据、口径与约束

使用固定请求时序、资源集合与采购价，逐档扫描集合重叠率。主指标为采购成本加逐单等待，另报资源购买次数、最长等待及末批是否全部完成。

## 预算与失败判据

以每种重叠率的配对差评估；区间跨零或节约的购买费被多出的等待抵消即不支持。合成流各档 30 个种子，CPU 预算随类型规模待确认。

本地实验尚未运行。
