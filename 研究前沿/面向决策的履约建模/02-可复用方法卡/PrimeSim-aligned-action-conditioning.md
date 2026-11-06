---
type: "方法"
topics: ["研究前沿", "方法精读"]
status: "维护中"
created: "2026-11-06"
module_id: "primesim:aligned-action-conditioning"
paper_id: "arxiv:2611.04870"
local_validation: "未验证"
---

# 转移动作对齐 attention 与直接 adapter 双路径

来源：[[研究前沿/面向决策的履约建模/01-论文原文与精读/PrimeSim/精读|PrimeSim 精读]] · [原文](https://arxiv.org/html/2611.04870v1)

## 输入与输出

输入对齐的动作轨迹、初始状态与时间索引；输出受动作约束的状态生成表示。

## 计算、训练与推理流程

统一动作坐标/槽位 → 相对固定起点 → 每潜在帧动作token → shifted mask限制对应转移 → adapter直接残差注入 → 联合条件生成训练。

## 效果证据与归因

Tables 9–10 单平台组件消融支持相对起点与双路径；Table 1 局部校准仍落后，不能把PSNR提升等同精确动作响应。

## 最小采用单元与耦合依赖

最小单元为动作时间对齐+mask+adapter；依赖编码器时间下采样、动作坐标和缺失槽约定。原文索引有歧义需用对齐测试解决。

## 数据假设与失败边界

相对坐标与零槽可能有歧义；双路径不能弥补隐藏混杂或未覆盖动作。

## 潜在迁移（推断）

对不同操作后的履约状态预测，避免未来状态注意力读取错误时点动作，并让操作信号有明确通路。

## 代码与本地验证

已核验[作者仓库](https://github.com/PrimebotTech/PrimeSim)，commit `c0ae256d53d1a504e3ec9817958c7b0b92007ef7`；截至本次仅 README、LICENSE 与 .gitignore，README 明确代码及权重 coming soon；未发布可执行实现。 [[研究前沿/面向决策的履约建模/01-论文原文与精读/PrimeSim/代码核验|核验记录]]

无本地实验结果。
