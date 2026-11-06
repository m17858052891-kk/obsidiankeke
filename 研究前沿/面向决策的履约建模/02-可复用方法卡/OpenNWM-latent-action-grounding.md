---
type: "方法"
topics: ["研究前沿", "方法精读"]
status: "维护中"
created: "2026-11-06"
module_id: "opennwm:latent-action-grounding"
paper_id: "arxiv:2611.01844"
local_validation: "未验证"
---

# 无动作轨迹预训练与少量物理动作联合约束

来源：[[研究前沿/面向决策的履约建模/01-论文原文与精读/OpenNWM/精读|OpenNWM 精读]] · [原文](https://arxiv.org/html/2611.01844v2)

## 输入与输出

输入异构状态轨迹及有动作/运动标签子集；输出兼顾转移预测和可执行运动语义的潜在接口及真实动作条件模型。

## 计算、训练与推理流程

当前未来对推断 latent → 视觉重建+KL → 有标注子集加运动预测 → 用 latent 与时距训练世界模型 → warmup 真实动作头 → 联合适配 → 在真实动作空间做 CEM 滚动规划。

## 效果证据与归因

Tables 4–5 的较小数据消融支持时间与 latent、视觉与物理监督互补；Table 2 导航主结果收益小于视觉主指标收益。不是纯无监督获得因果动作。

## 最小采用单元与耦合依赖

最小采用单元为双监督 latent 接口；在线动作条件适配和下游规划另需数据。重建头、KL、物理头与归一化耦合。

## 数据假设与失败边界

视觉变化可能混入环境因素；标注子集覆盖不足时语义不可靠；离线动作关联不构成因果识别。

## 潜在迁移（推断）

异构履约轨迹表示预训练，再用已知操作/结果标注约束，明确区分状态转移 latent 与真实可执行动作。

## 代码与本地验证

已核验[作者仓库](https://github.com/OpenSpace-Lab/OpenNWM)，commit `8a53524c6ed7e26aecbc91257f3a0b3bd212e9e5`；入口：[lam/lam/model.py](https://github.com/OpenSpace-Lab/OpenNWM/blob/8a53524c6ed7e26aecbc91257f3a0b3bd212e9e5/lam/lam/model.py)；[run.py](https://github.com/OpenSpace-Lab/OpenNWM/blob/8a53524c6ed7e26aecbc91257f3a0b3bd212e9e5/run.py)。已读取入口声明/关键片段，未审计全部实现、未安装运行。 [[研究前沿/面向决策的履约建模/01-论文原文与精读/OpenNWM/代码核验|核验记录]]

无本地实验结果。
