---
type: "实验"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-14"
experiment_id: "ShiftedTransport-phase"
experiment_status: "待设计/未运行"
source_papers: ["arxiv:2611.17090"]
source_modules: ["ShiftedTransport-phase"]
local_validation: "未运行"
---

# 同样的虚拟交换规则下，相位选择能否减少真实距离

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/ShiftedTransport/精读|Online Transportation via Shifted Geometric Scales]]

[[研究前沿/动态等待与匹配决策/02-可复用方法卡/ShiftedTransport-phase|固定资源点的树搜索如何选择尺度相位并保持真实指派]]

## 假设、改动与对照

相同一棵设施树比较优化相位、固定零相位、最近空位。用离线最小费用流求同一请求序列的最优。

## 必要数据、评价与约束

固定空间坐标、异质整容量及无回补。主指标为总距离／离线最优，另记虚拟步数和每次真实分配的可行性。

## 预算与失败判据

4–12 个设施、三档容量集中度，每档 100 个排列。若优化相位在相同比较网上既无改善又提高计算，或任何原指派被改变，则不支持采用。

本地实验未运行。
