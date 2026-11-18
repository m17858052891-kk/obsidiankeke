---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-12"
module_id: "RandomEdgeReserve-exact-bound"
source_papers: ["arxiv:2611.13571"]
version: "v1"
local_validation: "未运行"
---

# 在固定小图上计算随机顺序在线策略的精确上界

来源为 [[研究前沿/动态等待与匹配决策/01-论文原文与精读/RandomEdgeReserve/精读|Improved Bounds for Online Matching with Random Edge Arrivals]]。

## 输入、操作与输出

输入小图及未知标号的均匀先验。离线从完整边集往回递推已观察图 $H$ 和空闲点 $U$，按兼容标号数给每条新边加权。可接边取接和拒两分支最大值，规范化同构状态并缓存有理数值。输出具有相同信息的任意策略均不能超过的期望值。

## 原文证据与实现

§5 式 (13)(14)、定理 1.3/1.4 及表 1。与小图的精确离线最优相除，得到两个图类的限制。时间随小图规模急剧增长。

作者工程提供求上界的 opt.py、cpp/solver.cpp 和 lean/Main.lean。该工程验证固定图递推，不是三阶段线上调度器。[作者仓库](https://github.com/fstqwq/Random-Order-Matching-Upper-Bounds)

## 迁移推断

可为新的贪心或学习策略提供小图信息上限。若给策略额外标签含义、非均匀边序或可召回的边，应同步修改递推和先验。

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/RandomEdgeReserve-orders|端点保留的收益对到达顺序有多敏感]]
