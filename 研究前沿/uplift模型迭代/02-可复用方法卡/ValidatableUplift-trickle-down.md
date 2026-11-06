---
type: "方法"
topics: ["研究前沿", "方法精读"]
status: "维护中"
created: "2026-11-06"
module_id: "validatableuplift:trickle-down"
paper_id: "arxiv:2610.37966"
local_validation: "未验证"
---

# 保留预算继续向下的TrickleDown检验

来源：[[研究前沿/uplift模型迭代/01-论文原文与精读/ValidatableUplift/精读|ValidatableUplift 精读]] · [原文](https://arxiv.org/html/2610.37966v1)

## 输入与输出

节点p值与α预算、v、子权重→受FWER控制的发现

## 计算、训练与推理流程

用vα检验；拒绝传全部预算，未拒传(1−v)剩余；对子节点按权重分配。

## 效果证据与归因

Prop1理论；Table3 scale0.45发现3.15 vs固定层级1.90；Table4根层可能损失功效。

## 最小采用单元与耦合依赖

与预定义层级和有效p值耦合；可复用预算传播，不能事后改权重。

## 数据假设与失败边界

并非全局最优功效，强效应浅层任务不一定占优。

## 潜在迁移（推断）

用于多层人群、动作档位异质性验证；实验先对齐真零假设和覆盖率。

## 代码与本地验证

本次核验的论文原文与元数据未提供可确认的作者实现入口；代码状态未知，不能据此断言不存在。未运行代码。 [[研究前沿/uplift模型迭代/01-论文原文与精读/ValidatableUplift/代码核验|核验记录]]

无本地实验结果。
