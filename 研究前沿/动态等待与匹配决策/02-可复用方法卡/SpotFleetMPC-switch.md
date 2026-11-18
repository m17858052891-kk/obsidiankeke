---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-14"
module_id: "SpotFleetMPC-switch"
source_papers: ["arxiv:2611.11215"]
version: "v1"
local_validation: "未运行"
---

# 一过性高峰应调价还是搬动容量

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/SpotFleetMPC/精读|Spot Markets for AI Inference: Dynamic Capacity Allocation and Pricing on a Shared Accelerator Fleet]]

## 输入、动作与输出

输入模型部署、短期需求及功率预报、加载/卸载成本与各截止队列。逐期求解作者规划式 (21)，仅实施首期定价和部署决策，下一期更新。比较预期持续获益和双向切换损失，形成惰性区间。

## 使用时点与依赖

需要历史负载训练预测或估计季节项；调度决策在每个控制周期重算。不存在负载回落预期时，价格与部署的分工可能改变。

## 原文证据与实现

§5.4 定理 3、§6 与 §7 表 2–3、图 9。一般系统的 7.4% 对应联合策略。

附录 C 列 spot/code/spotsim.py、concept.py、run.py。此次检查 arXiv 源包只找到 TeX 与 figures，未核到可下载的这三个脚本。

## 迁移假设

固定需求曲线、部署和日期序列，只换 D=1、4、16 个周期；再在相同 D 下开放部署控制，分开计算窗口与切换的增量。本地尚未验证。

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/SpotFleetMPC-window|期限窗口是否真让同一批工作使用了更便宜容量]]
