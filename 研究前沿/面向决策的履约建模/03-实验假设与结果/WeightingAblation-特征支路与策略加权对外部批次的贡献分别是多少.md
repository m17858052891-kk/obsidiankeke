---
type: "实验"
topics: ["研究前沿", "面向决策的履约建模"]
status: "维护中"
created: "2026-11-15"
paper_id: "doi:10.21203/rs.3.rs-11021990/v1"
version: "v1"
experiment_id: "WeightingAblation-H1"
experiment_status: "待设计/未运行"
source_modules: ["WeightingAblation-M1"]
---

# 特征支路与策略加权对外部批次的贡献分别是多少

[[研究前沿/面向决策的履约建模/02-可复用方法卡/WeightingAblation-用同一特征集分别消融加权与交互|用同一特征集分别消融加权与交互]] · [[研究前沿/面向决策的履约建模/01-论文原文与精读/WeightingAblation/精读|来源]]

固定特征可见时点、基模型、元学习器与评测样本，交叉启用交互支路和权重。按时间和地区独立留出，报告 AUC、校准、分组误差、权重有效样本量与配对区间。若收效只出现在用于挑权重的批次或不同特征集间，无法确认可迁移增益。

状态为待设计、未运行。数据版本、代码提交、预算、日志和结果待确认。
