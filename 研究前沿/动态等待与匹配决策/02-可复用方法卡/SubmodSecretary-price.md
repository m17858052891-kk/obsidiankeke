---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-14"
module_id: "SubmodSecretary-price"
source_papers: ["arxiv:2611.17292"]
version: "v1"
local_validation: "未运行"
---

# 按过去能否达标的时长调整当前候选的接纳率

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/SubmodSecretary/精读|The Submodular Secretary Problem: Tight $1-1/e$ for Monotone Objectives, and Strictly Between $1/e$ and $1/2$ in General]]

## 输入、动作与输出

输入已到候选、当前集合 A、此前的尺度和价格状态。普通元素以 w=f(A∪{i})−f(A)>θ 为合格，异常元素另行处理；只有当前合格且私有均匀随机数≤exp(−τ) 才接纳，到 k 即停止。

## 使用时点与依赖

需保存历史状态并支持价值查询，训练为空。τ 在 i 到达以后对当时及历史已选集合求得，不能将未来候选放入查询。

## 原文证据与实现

§3–4 证明预算和渐近界；§5 对非单调目标再引入不同策略的混合，提升不能独立归给衰减。

未核到作者仓库。§3 的 AttenuatedPricing、§5 与附录 B 是不同策略的原始入口。

## 迁移假设

固定覆盖对象和候选覆盖集，由低到高改变覆盖重叠；比较固定单项排序、只看当前边际、附录 B 的有限预算前缀基准。本地尚未验证。

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/SubmodSecretary-overlap|相同预算下，高重复覆盖会让单项排序损失多少]]
