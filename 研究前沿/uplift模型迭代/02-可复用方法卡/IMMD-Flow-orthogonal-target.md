---
type: "方法"
topics: ["研究前沿", "方法精读"]
status: "维护中"
created: "2026-11-06"
module_id: "immd-flow:orthogonal-target"
paper_id: "arxiv:2611.03962"
local_validation: "未验证"
---

# 先估计双稳健核目标，再优化干预结果分布

来源：[[研究前沿/uplift模型迭代/01-论文原文与精读/IMMD-Flow/精读|IMMD-Flow 精读]] · [原文](https://arxiv.org/html/2611.03962v1)

## 输入与输出

观察(x,a,y)、目标策略π、固定表示→干预分布粒子

## 计算、训练与推理流程

拟合条件核均值和密度比，平均增广score，冻结目标势，MMD粒子梯度更新并解码。

## 效果证据与归因

Prop3.2乘积误差；Table1优于DecFM的SW2，DR相对插件优势并不全面。

## 最小采用单元与耦合依赖

最小单元为DR核目标+可优化核势；可单用核目标作分布评估，但生成效果依赖粒子流。

## 数据假设与失败边界

无未测混杂、重叠和nuisance可积性；不识别个体反事实轨迹。

## 潜在迁移（推断）

从平均uplift扩展到分位数、尾部风险或多维结果分布。

## 代码与本地验证

已核验[作者仓库](https://github.com/BariscanBozkurt/Interventional-MMD-Flow-Sampling)，commit `003d0e85b0ad9bce369bd346c6d473d438c0455f`；入口：[src/causality_utils/crossfit.py](https://github.com/BariscanBozkurt/Interventional-MMD-Flow-Sampling/blob/003d0e85b0ad9bce369bd346c6d473d438c0455f/src/causality_utils/crossfit.py)；[Simulations/ColorMNIST/dr_mmd_flow/colormnist_dr_mmd_flow_simulation.py](https://github.com/BariscanBozkurt/Interventional-MMD-Flow-Sampling/blob/003d0e85b0ad9bce369bd346c6d473d438c0455f/Simulations/ColorMNIST/dr_mmd_flow/colormnist_dr_mmd_flow_simulation.py)。已读取入口声明/关键片段，未审计全部实现、未安装运行。 [[研究前沿/uplift模型迭代/01-论文原文与精读/IMMD-Flow/代码核验|核验记录]]

无本地实验结果。
