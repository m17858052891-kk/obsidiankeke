---
type: "方法"
topics: ["研究前沿", "方法精读"]
status: "维护中"
created: "2026-11-06"
module_id: "immd-flow:nystrom-reuse"
paper_id: "arxiv:2611.03962"
local_validation: "未验证"
---

# 固定核目标的Nyström计算复用

来源：[[研究前沿/uplift模型迭代/01-论文原文与精读/IMMD-Flow/精读|IMMD-Flow 精读]] · [原文](https://arxiv.org/html/2611.03962v1)

## 输入与输出

高维日志与多个候选干预→低成本目标系数

## 计算、训练与推理流程

输入侧landmark核回归；动作积分MonteCarlo；保存目标系数，生成过程中不重拟合。

## 效果证据与归因

E.6 Table8同输入求解9.09→0.04秒，SW2无明显损失；不能把该倍数当全流程倍数。

## 最小采用单元与耦合依赖

依赖核回归、ridge/landmark选择及固定编码；生成仍有粒子相互作用成本。

## 数据假设与失败边界

landmark数量渐进条件与实际规模均需检查；编码不保信息时目标不够。

## 潜在迁移（推断）

用于多策略分布估计的共享特征计算，离线预算先测拟合与生成分别耗时。

## 代码与本地验证

已核验[作者仓库](https://github.com/BariscanBozkurt/Interventional-MMD-Flow-Sampling)，commit `003d0e85b0ad9bce369bd346c6d473d438c0455f`；入口：[src/causality_utils/crossfit.py](https://github.com/BariscanBozkurt/Interventional-MMD-Flow-Sampling/blob/003d0e85b0ad9bce369bd346c6d473d438c0455f/src/causality_utils/crossfit.py)；[Simulations/ColorMNIST/dr_mmd_flow/colormnist_dr_mmd_flow_simulation.py](https://github.com/BariscanBozkurt/Interventional-MMD-Flow-Sampling/blob/003d0e85b0ad9bce369bd346c6d473d438c0455f/Simulations/ColorMNIST/dr_mmd_flow/colormnist_dr_mmd_flow_simulation.py)。已读取入口声明/关键片段，未审计全部实现、未安装运行。 [[研究前沿/uplift模型迭代/01-论文原文与精读/IMMD-Flow/代码核验|核验记录]]

无本地实验结果。
