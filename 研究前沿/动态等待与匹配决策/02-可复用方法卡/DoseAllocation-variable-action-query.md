---
type: "方法"
topics: ["研究前沿", "方法精读"]
status: "维护中"
created: "2026-11-06"
module_id: "doseallocation:variable-action-query"
paper_id: "arxiv:2611.00395"
local_validation: "未验证"
---

# 状态 query 汇聚变长有序动作，并分离分配与终局选择

来源：[[研究前沿/动态等待与匹配决策/01-论文原文与精读/DoseAllocation/精读|DoseAllocation 精读]] · [原文](https://arxiv.org/html/2611.00395v1)

## 输入与输出

输入各有序选项的位置/尝试计数/结果计数/当前标识及全局状态；输出固定维策略表示与下一步局部动作。

## 计算、训练与推理流程

共享 token 编码 → 状态 query 对全部有效选项 cross-attention → mask 非法动作 → PPO 分配 → 终局用预设 isotonic selector → 分别评价分配覆盖与最终选择。

## 效果证据与归因

Tables 1–3 支持风险与精度权衡及优化敏感性；未独立证明 attention 的提升。约 0.10 PCS 变化主要来自终局 tie-break，须单独控制。

## 最小采用单元与耦合依赖

表示模块可替换到其他有序候选空间；PPO、邻接动作规则及终局选择器并不天然可分离地保持原文效果。最小表示单元为 token+query+padding/action mask。

## 数据假设与失败边界

仅同分布模拟，未见长度和延迟反馈未证实；奖励权重改变探索风险。attention 权重不是目标最优概率。

## 潜在迁移（推断）

序贯预算/等待档位分配；采用共享终局规则对照，防止选择器变化冒充策略创新。

## 代码与本地验证

本次核验的论文原文与元数据未提供可确认的作者实现入口；代码状态未知，不能据此断言不存在。未运行代码。 [[研究前沿/动态等待与匹配决策/01-论文原文与精读/DoseAllocation/代码核验|核验记录]]

无本地实验结果。
