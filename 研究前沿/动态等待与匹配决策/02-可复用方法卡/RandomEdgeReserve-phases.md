---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-12"
module_id: "RandomEdgeReserve-phases"
source_papers: ["arxiv:2611.13571"]
version: "v1"
local_validation: "未运行"
---

# 用影子匹配决定早期保留、晚期恢复的端点

来源为 [[研究前沿/动态等待与匹配决策/01-论文原文与精读/RandomEdgeReserve/精读|Improved Bounds for Online Matching with Random Edge Arrivals]]。

## 输入、操作与输出

输入单次到达的无权边、归一化时间与实际/影子可用状态。按 $a,b$ 三段推进，早期随机拒绝影子可接纳边，中段完成影子可接纳边，晚期允许未被实际占有的端点重新匹配，但禁止保留端点彼此匹配。输出不可逆的接纳或跳过，无离线模型训练。

## 原文证据与实现

定理 1.1/1.2、算法 1 与附录 B 给出两组参数的期望最坏比 0.5445、0.5535。证据针对整套三阶段规则。

作者工程提供求上界的 opt.py、cpp/solver.cpp 和 lean/Main.lean。该工程验证固定图递推，不是三阶段线上调度器。[作者仓库](https://github.com/fstqwq/Random-Order-Matching-Upper-Bounds)

## 迁移推断

适用于无法收回出价、但被跳过候选的资源以后仍能接新机会的场景。若边到达顺序可预测或有权重，界需另证。

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/RandomEdgeReserve-orders|端点保留的收益对到达顺序有多敏感]]
