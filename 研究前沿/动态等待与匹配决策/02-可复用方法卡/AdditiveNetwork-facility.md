---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-13"
module_id: "AdditiveNetwork-facility"
source_papers: ["arxiv:2611.13859"]
version: "v1"
local_validation: "未运行"
---

# 先按需求密度分配服务点，再决定多久开一次

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/AdditiveNetwork/精读|Online Network Design with Additive Delays and Poisson Arrivals]]

## 输入、流程与输出

输入客户和设施距离、启动费、各类泊松率。按需求支撑半径筛代表并固定分配；每个点在即开与周期 $p=\sqrt{2c/\Lambda}$ 间选低成本模式，空队列跳过。输出分配表及服务时钟。

## 最小采用单元与依赖

可先固定已有分配，只接入时间表开展对照。27.249 的全策略界还依赖代表点选择与原模型的线性等待。参数在服务前取得，运行中仅查表。

## 原文证据与实现

§3.1、5.2–5.3、定理 5.2（PDF 第 14 页）。

正文未列作者代码。设施时间表见 §5.2；多根分区见 §6.2、6.5；移动时钟递推见式 (14) 与 §7.3。

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/AdditiveNetwork-location|固定服务分区对到达率漂移有多敏感]]
