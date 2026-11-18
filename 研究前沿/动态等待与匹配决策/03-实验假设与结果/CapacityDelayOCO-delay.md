---
type: "实验"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-14"
experiment_id: "CapacityDelayOCO-delay"
experiment_status: "待设计/未运行"
source_papers: ["arxiv:2606.11711"]
source_modules: ["CapacityDelayOCO-proxy"]
local_validation: "未运行"
---

# 当迟到结果系统性不同，哪种追踪规则更稳

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/CapacityDelayOCO/精读|Capacity-Constrained Online Convex Optimization with Delayed Feedback]]

[[研究前沿/动态等待与匹配决策/02-可复用方法卡/CapacityDelayOCO-proxy|给未回传结果分配随机追踪期限]]

## 假设、改动与对照

生成关联或独立的延迟与凸损失流，固定追踪容量，比较全追踪、固定概率保留、Pareto 期限和只留短等待。记录实际观测比例与最大权重。

## 必要数据、评价与约束

使用完全可知真值的合成流，收益仅用于事后计分。主指标为相对最佳固定动作的平均遗憾，另报长延迟桶误差与占用峰值。

## 预算与失败判据

C 取 20/80/160，每格 50 组共同种子。若权重差异不能解释 bandit 下差异，或独立延迟时仍出现同样方向的偏差，则该机制解释需修订。

本地实验未运行。
