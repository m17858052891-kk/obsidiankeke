---
type: "实验"
topics: ["研究前沿", "uplift模型迭代"]
status: "维护中"
created: "2026-11-15"
paper_id: "arxiv:2410.16870"
version: "v2"
experiment_id: "FedTrialATE-H1"
experiment_status: "待设计/未运行"
source_modules: ["FedTrialATE-M1"]
---

# 不同分流比例下的跨站增量复核

[[研究前沿/uplift模型迭代/02-可复用方法卡/FedTrialATE-分处理臂拟合后按目标总体标准化|分处理臂拟合后按目标总体标准化]] · [[研究前沿/uplift模型迭代/01-论文原文与精读/FedTrialATE/精读|来源]]

在有获准访问且可作集中基准的合成多站试验中，共用随机分配和样本，逐步改变站点截距、臂比例和站点规模。比较集中拟合、加权 meta、联邦分臂模型，报告混合总体 ATE 偏差、RMSE、区间覆盖和无法估计的站点数。若同设计矩阵下两种实现不一致，先修正聚合；若目标群体变化后误差反向，限制迁移。

状态为待设计、未运行。数据版本、代码提交、预算、日志和结果待确认。
