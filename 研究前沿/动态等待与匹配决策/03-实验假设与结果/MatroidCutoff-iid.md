---
type: "实验"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-13"
experiment_id: "MatroidCutoff-iid"
experiment_status: "待设计/未运行"
source_papers: ["arxiv:2611.06891"]
source_modules: ["MatroidCutoff-cutoff", "MatroidCutoff-reference"]
local_validation: "未运行"
---

# 共同分布被打破时，替代性阈值会不会失去优势

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/MatroidCutoff/精读|Prophet Secretary for Matroids and XOS Valuations: A Separation at 1-1/e and a 0.6767 Guarantee for I.I.D. Weights]]

[[研究前沿/动态等待与匹配决策/02-可复用方法卡/MatroidCutoff-cutoff|按剩余集合可替代性设接纳分位阈值]] · [[研究前沿/动态等待与匹配决策/02-可复用方法卡/MatroidCutoff-reference|不同分布的资源如何用参考价格和虚拟基接纳]]

## 假设、最小改动与基线

在分区拟阵的小实例上固定到达顺序，比较知道真实共同分布、错误地共用一个汇总分布，以及离线最优；扫描不同分组的价值尺度。

## 数据、口径与约束

每组容量与候选价值流须固定，对所有策略用相同场景；主指标为在线平均总收益/离线平均总收益，同时记录不可行接纳次数、各组接受率。

## 预算与失败判据

每个场景 1000 个合成种子，CPU；比较机会约束完全相同的朴素阈值。若同分布域内下界偏差显著，先核对平局与剩余拟阵，再解释异质性。

本地实验尚未运行。
