---
type: "实验"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-14"
experiment_id: "SpotFleetMPC-window"
experiment_status: "待设计/未运行"
source_papers: ["arxiv:2611.11215"]
source_modules: ["SpotFleetMPC-window", "SpotFleetMPC-switch"]
local_validation: "未运行"
---

# 期限窗口是否真让同一批工作使用了更便宜容量

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/SpotFleetMPC/精读|Spot Markets for AI Inference: Dynamic Capacity Allocation and Pricing on a Shared Accelerator Fleet]]

[[研究前沿/动态等待与匹配决策/02-可复用方法卡/SpotFleetMPC-window|用截止前最便宜的容量计算可推迟工作的成本]] · [[研究前沿/动态等待与匹配决策/02-可复用方法卡/SpotFleetMPC-switch|一过性高峰应调价还是搬动容量]]

## 假设、改动与对照

固定需求曲线、部署和日期序列，只换 D=1、4、16 个周期；再在相同 D 下开放部署控制，分开计算窗口与切换的增量。

## 必要数据、评价与约束

模拟同一份分时容量、电价、到达量与截止，并固定可用于决策的预测版本。主指标为单位履约成本与完成收益，另查超时和交互服务下限。

## 预算与失败判据

4 条预先设定的峰谷形状，每类 30 组共同扰动，CPU。若长窗口未迁移实际服务时段，或收益依赖提前读取实现，则不支持截止带来容量价值。

本地实验未运行。
