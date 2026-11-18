---
type: 索引
status: 维护中
created: 2026-11-18
---

# 模型自进化

日报通用方法主线。持续增量学习、漂移、自训练、主动学习、自动特征发现和可复现实验选模。每日先执行 [[研究前沿/推荐模型检索地图|推荐模型检索地图]] 中的独立方法查询，再用本页问题和业务入口补查。

如何把新数据和真实反馈用于模型更新、发现失效人群、选择训练样本、自动提出和检验改动，并稳定提升以上场景的模型？

先以持续或增量学习、漂移检测、反馈纠偏、主动学习、自动实验与选模为工作定义。研究自训练时检查伪标签噪声和反馈闭环；研究自动实验时检查独立验证、候选选择偏差、复现和回退。论文探索可包含 AutoML 和研究 Agent，但必须对应具体模型改动与可追溯验证。

## 可直接执行的检索组合

公共短查询逐条执行，覆盖直接问题和跨领域机制。

- `"continual learning" recommendation concept drift`
- `"online learning" delayed feedback selection bias`
- `"self-training" recommender feedback loops`
- `"active learning" data selection ranking`
- `"automated feature engineering" tabular prediction`
- `"automated machine learning" temporal validation model selection`
- `"automated experimentation" machine learning reproducibility`
- `"sequence modeling" multi-scenario prediction scaling laws`

## 论文准入与第一步验证

主读依据是创新模块、机制和可信证据，保留医疗、推荐、广告、运筹和机器学习中的可迁移工作。记录能改以上哪个动作或模型、原文证据位置、第一步对照的样本与基线、只改的因素、主指标与失败判据。已有线上收益和现成业务数据仅用于适配说明。原文结果与本地未运行假设分别标注。

## 资料索引

[[研究前沿/模型自进化/01-论文原文与精读/README|论文原文与精读]] · [[研究前沿/模型自进化/02-可复用方法卡/README|可复用方法卡]] · [[研究前沿/模型自进化/03-实验假设与结果/README|实验假设与结果]]

<!-- 存量复筛导航开始 -->
[[研究前沿/模型自进化/存量论文分层索引|全部存量：主读、储备、待核验]] · [[研究前沿/论文库复筛与阅读路线|跨方向阅读路线]]
<!-- 存量复筛导航结束 -->
