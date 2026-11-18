---
type: "实验"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-14"
experiment_id: "SubmodSecretary-overlap"
experiment_status: "待设计/未运行"
source_papers: ["arxiv:2611.17292"]
source_modules: ["SubmodSecretary-price"]
local_validation: "未运行"
---

# 相同预算下，高重复覆盖会让单项排序损失多少

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/SubmodSecretary/精读|The Submodular Secretary Problem: Tight $1-1/e$ for Monotone Objectives, and Strictly Between $1/e$ and $1/2$ in General]]

[[研究前沿/动态等待与匹配决策/02-可复用方法卡/SubmodSecretary-price|按过去能否达标的时长调整当前候选的接纳率]]

## 假设、改动与对照

固定覆盖对象和候选覆盖集，由低到高改变覆盖重叠；比较固定单项排序、只看当前边际、附录 B 的有限预算前缀基准。

## 必要数据、评价与约束

保留集合、随机到达次序、切实可用的价值查询，离线小实例枚举。主指标为覆盖量／离线最优，另记接纳数和查询数。

## 预算与失败判据

候选数≤20、k=2,4,6，每档 100 个排列。若重叠增加时单项排序的相对损失未扩大，或前缀对照需读取未来元素，则不支持这一解释。

本地实验未运行。
