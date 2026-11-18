---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-14"
module_id: "CapacityDelayOCO-proxy"
source_papers: ["arxiv:2606.11711"]
version: "v2"
local_validation: "未运行"
---

# 给未回传结果分配随机追踪期限

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/CapacityDelayOCO/精读|Capacity-Constrained Online Convex Optimization with Delayed Feedback]]

## 输入、动作与输出

输入硬容量 C、当前占用及代理期限分布。容量允许才入槽，实际反馈到来前超过期限就释放。若代理期限覆盖 d，其权重按 1/P(d′≥d) 构造，容量饱和作为单独损失处理；统一采样与 Pareto 采样给出两种权重尺度。输出加权延迟反馈及剩余槽。

## 使用时点与依赖

在线做保留/淘汰，再经延迟加权基学习器训练；先验知道最大积压的 Bernoulli 版本可用倍增扩展。若动作会改变反馈生成过程，需要额外的识别假设。

## 原文证据与实现

§4 算法 1、推论 4.4–4.5，§6 图 3 与附录 H。100 次配对使用实证调度器变体，理论随机化与实验调参有区别。

作者提供 [cc-oco 仓库](https://github.com/alex-rbch/cc-oco)，已核到根目录 run.py 与 src/。

## 迁移假设

生成关联或独立的延迟与凸损失流，固定追踪容量，比较全追踪、固定概率保留、Pareto 期限和只留短等待。记录实际观测比例与最大权重。本地尚未验证。

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/CapacityDelayOCO-delay|当迟到结果系统性不同，哪种追踪规则更稳]]
