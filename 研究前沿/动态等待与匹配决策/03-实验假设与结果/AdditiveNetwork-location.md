---
type: "实验"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-13"
experiment_id: "AdditiveNetwork-location"
experiment_status: "待设计/未运行"
source_papers: ["arxiv:2611.13859"]
source_modules: ["AdditiveNetwork-facility", "AdditiveNetwork-roots", "AdditiveNetwork-centroid"]
local_validation: "未运行"
---

# 固定服务分区对到达率漂移有多敏感

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/AdditiveNetwork/精读|Online Network Design with Additive Delays and Poisson Arrivals]]

[[研究前沿/动态等待与匹配决策/02-可复用方法卡/AdditiveNetwork-facility|先按需求密度分配服务点，再决定多久开一次]] · [[研究前沿/动态等待与匹配决策/02-可复用方法卡/AdditiveNetwork-roots|把可选服务根固定成连通区域]] · [[研究前沿/动态等待与匹配决策/02-可复用方法卡/AdditiveNetwork-centroid|移动服务按需求重心安排往返]]

## 假设、最小改动与基线

同一请求流比较静态需求半径分区、最近设施分区，以及定期重估半径的分区；各组共用同一开门时钟优化器。

## 数据、口径与约束

需要候选点、距离、开门价和逐次到达；前半段估率后冻结阈值，后半段调换两个区域的强弱。按采购、连接和逐单等待分解总成本，另报切换次数和最坏单等待。

## 预算与失败判据

扫描漂移幅度，独立生成 30 组流；若重估的成本节约在含切换代价后消失，则不支持重估。CPU，预算待确认。

本地实验尚未运行。
