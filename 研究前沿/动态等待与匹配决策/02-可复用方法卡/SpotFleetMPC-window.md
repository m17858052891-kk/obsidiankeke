---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-14"
module_id: "SpotFleetMPC-window"
source_papers: ["arxiv:2611.11215"]
version: "v1"
local_validation: "未运行"
---

# 用截止前最便宜的容量计算可推迟工作的成本

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/SpotFleetMPC/精读|Spot Markets for AI Inference: Dynamic Capacity Allocation and Pricing on a Shared Accelerator Fleet]]

## 输入、动作与输出

给定可服务窗口 W、边际能耗成本 c、功率和容量约束导出的 μ、单位持有成本 h。计算 C=min_{s∈W}[c_s+μ_s+h(s−t)]；在线性需求的内点由 p=(π+C)/2 反推接纳量，服务在容量与截止允许的时段执行。

## 使用时点与依赖

定理使用单模型固定部署及确定性可见需求；滚动控制只可用当前可得预测，须计入预测偏差与截止。

## 原文证据与实现

§5.2 定理 1 和图 6 给出独立机制；§7 表 3 的系统利润还包含其他控制。

附录 C 列 spot/code/spotsim.py、concept.py、run.py。此次检查 arXiv 源包只找到 TeX 与 figures，未核到可下载的这三个脚本。

## 迁移假设

固定需求曲线、部署和日期序列，只换 D=1、4、16 个周期；再在相同 D 下开放部署控制，分开计算窗口与切换的增量。本地尚未验证。

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/SpotFleetMPC-window|期限窗口是否真让同一批工作使用了更便宜容量]]
