---
type: "实验"
topics: ["研究前沿", "面向决策的履约建模"]
status: "维护中"
created: "2026-11-16"
paper_id: "arxiv:2611.15829"
version: "v1"
experiment_id: "SampleCoverageLoss-H1"
experiment_status: "待设计/未运行"
source_modules: ["SampleCoverageLoss-M1"]
---

# 检验履约时长分布的覆盖改善是否牺牲均值精度

[[研究前沿/面向决策的履约建模/02-可复用方法卡/SampleCoverageLoss-按真值距离在条件样本中的分位数校准生成分布|按真值距离在条件样本中的分位数校准生成分布]] · [[研究前沿/面向决策的履约建模/01-论文原文与精读/SampleCoverageLoss/精读|来源]]

在结果已成熟且删失处理相同的数据上，固定主干、采样数和训练步数，对照仅追加训练、CRPS 型损失和参考点覆盖损失。按动作与负载分层比较覆盖误差、区间宽度、均值误差；若只靠无界扩宽区间改善覆盖，判为失败。

状态为待设计、未运行。数据版本、代码提交、预算、日志和结果待确认。
