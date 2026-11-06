---
type: "方法"
topics: ["研究前沿", "方法精读"]
status: "维护中"
created: "2026-11-06"
module_id: "selectivetrees:pruning-selection"
paper_id: "arxiv:2611.01134"
local_validation: "未验证"
---

# 把剪枝幸存纳入交互树的选择后推断

来源：[[研究前沿/uplift模型迭代/01-论文原文与精读/SelectiveTrees/精读|SelectiveTrees 精读]] · [原文](https://arxiv.org/html/2611.01134v1)

## 输入与输出

固定设计/规则、已知方差高斯结果、预指定节点→选择修正p值/CI

## 计算、训练与推理流程

GLS残差交互生长；固定惩罚剪枝；沿协方差匹配方向计算生长区间与二次幸存门槛；截断正态反演。

## 效果证据与归因

§5.4相同目标强剪枝FPR14.57→5.75%；§5.6深层区间可能极宽。

## 最小采用单元与耦合依赖

完整选择机制、原始对比方向、所有区间组件都必要；剪枝不重定义目标。

## 数据假设与失败边界

已知正对角协方差与条件高斯；单节点而非全树多重控制。

## 潜在迁移（推断）

保留小样本发现能力，同时审计选择偏差；与独立评估做假设/功效比较。

## 代码与本地验证

已核验[作者仓库](https://github.com/tomoshige/selective-inference-for-interaction-tree)，commit `928ba1396c3c645e100464a26c5b9de04de961b6`；入口：[reproduce.R](https://github.com/tomoshige/selective-inference-for-interaction-tree/blob/928ba1396c3c645e100464a26c5b9de04de961b6/reproduce.R)；[gls_tree.R](https://github.com/tomoshige/selective-inference-for-interaction-tree/blob/928ba1396c3c645e100464a26c5b9de04de961b6/gls_tree.R)。已读取入口声明/关键片段，未审计全部实现、未安装运行。 [[研究前沿/uplift模型迭代/01-论文原文与精读/SelectiveTrees/代码核验|核验记录]]

无本地实验结果。
