---
type: "实验"
topics: ["研究前沿", "面向决策的履约建模"]
status: "维护中"
created: "2026-11-16"
paper_id: "arxiv:2611.15150"
version: "v1"
experiment_id: "TargetValidatedTransfer-H1"
experiment_status: "待设计/未运行"
source_modules: ["TargetValidatedTransfer-M1", "TargetValidatedTransfer-M2"]
---

# 用独立目标集检查冻结、解冻和回退三者的贡献

[[研究前沿/面向决策的履约建模/02-可复用方法卡/TargetValidatedTransfer-用独立目标样本决定是否启用适配分支|用独立目标样本决定是否启用适配分支]] · [[研究前沿/面向决策的履约建模/01-论文原文与精读/TargetValidatedTransfer/精读|来源]]

固定时间划分、算力和种子，对比目标基线、只训练新头、允许改表示、验证后回退；在独立测试集按条件预测分数和有害时间窗比例比较。若收益只见于选模型的验证集或相同预算下消失，判为未通过。

状态为待设计、未运行。数据版本、代码提交、预算、日志和结果待确认。

[[研究前沿/面向决策的履约建模/02-可复用方法卡/TargetValidatedTransfer-冻结源表示并训练目标域残差分支|来源模块：目标域残差支路]]
