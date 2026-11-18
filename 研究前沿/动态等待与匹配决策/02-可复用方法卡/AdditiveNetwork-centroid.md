---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-13"
module_id: "AdditiveNetwork-centroid"
source_papers: ["arxiv:2611.13859"]
version: "v1"
local_validation: "未运行"
---

# 移动服务按需求重心安排往返

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/AdditiveNetwork/精读|Online Network Design with Additive Delays and Poisson Arrivals]]

## 输入、流程与输出

按树上各点到达率选重心；由重心向外递推服务尺度，式 (14) 舍入到对齐时钟。到期时走遍所需路径的并集再返回，路过其他等待请求时一并服务。

## 最小采用单元与依赖

最小单元是给定基地与周期后的路径并集；成本还依赖基地与分支率共同选取。原模型中的移动为即时服务动作，真实行程中到达、取消和运力多车均需另建。

## 原文证据与实现

§3.3、§7.3–7.6 与定理 7.8（PDF 第 32 页）。

正文未列作者代码。设施时间表见 §5.2；多根分区见 §6.2、6.5；移动时钟递推见式 (14) 与 §7.3。

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/AdditiveNetwork-location|固定服务分区对到达率漂移有多敏感]]
