---
type: "方法"
topics: ["研究前沿", "方法精读"]
status: "维护中"
created: "2026-11-06"
module_id: "primesim:self-rollout-memory"
paper_id: "arxiv:2611.04870"
local_validation: "未验证"
---

# 自生成历史上的整段训练与固定容量多尺度记忆

来源：[[研究前沿/面向决策的履约建模/01-论文原文与精读/PrimeSim/精读|PrimeSim 精读]] · [原文](https://arxiv.org/html/2611.04870v1)

## 输入与输出

输入自回归世界模型、短窗teacher、长episode及固定KV预算；输出长程更稳定的模型与分层缓存。

## 计算、训练与推理流程

4步蒸馏降低自rollout成本 → student使用自身历史 → fake-score/teacher做DMD → episode累计更新 → sink初始状态+稀疏slow+稠密local同步更新 → 训练推理缓存机制一致。

## 效果证据与归因

Tables 7–8 同10条长episode与21slot比较支持整段训练和分层组织；Table 6显示速度/质量权衡。未证明可独立去掉DMD等依赖保持效果。

## 最小采用单元与耦合依赖

最小记忆单元可独立探索，但原证据位于蒸馏+DMD自rollout系统。必须保留时间位置、状态续接及动作参考一致性。

## 数据假设与失败边界

自生成错误可进入慢记忆；teacher质量上限与mode-seeking偏差；只有10条长程评估，真实策略闭环未证实。

## 潜在迁移（推断）

长履约链状态模型中保留初始约束、稀疏事件史和近期状态，并用自身预测续接训练检查误差累积。

## 代码与本地验证

已核验[作者仓库](https://github.com/PrimebotTech/PrimeSim)，commit `c0ae256d53d1a504e3ec9817958c7b0b92007ef7`；截至本次仅 README、LICENSE 与 .gitignore，README 明确代码及权重 coming soon；未发布可执行实现。 [[研究前沿/面向决策的履约建模/01-论文原文与精读/PrimeSim/代码核验|核验记录]]

无本地实验结果。
