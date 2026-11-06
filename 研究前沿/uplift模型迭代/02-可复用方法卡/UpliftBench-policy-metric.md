---
type: "方法"
topics: ["研究前沿", "方法精读"]
status: "维护中"
created: "2026-11-06"
module_id: "upliftbench:policy-metric"
paper_id: "arxiv:2608.00915"
local_validation: "未验证"
---

# 按部署规则选择指标和校准阈值

来源：[[研究前沿/uplift模型迭代/01-论文原文与精读/UpliftBench/精读|UpliftBench 精读]] · [原文](https://arxiv.org/html/2608.00915v1)

## 输入与输出

模型OOF得分、可识别的评估样本、预算/阈值规则→策略价值与选模决定

## 计算、训练与推理流程

分别评估排序与固定阈值/固定预算策略；阈值仅在选择集校准，再在隔离集评估。

## 效果证据与归因

Prop5.3排序不变性；Jobs阈值校准遗憾下降81%，同样本重切分而非外部新实验。

## 最小采用单元与耦合依赖

最小单元为策略定义+独立选择/评价+可识别value估计；不是另加一个AUUC。

## 数据假设与失败边界

IPW受极端倾向影响；观察分桶校准不自动有效。

## 潜在迁移（推断）

补充收益阈值、预算分配的迭代准入指标。

## 代码与本地验证

已核验[作者仓库](https://github.com/binshuangli/uplift-bench)，commit `604cf7caee4f2f1322e0eac81968161741c7a99f`；入口：[scripts/run_bench.py](https://github.com/binshuangli/uplift-bench/blob/604cf7caee4f2f1322e0eac81968161741c7a99f/scripts/run_bench.py)；[scripts/f2_threshold.py](https://github.com/binshuangli/uplift-bench/blob/604cf7caee4f2f1322e0eac81968161741c7a99f/scripts/f2_threshold.py)。已读取入口声明/关键片段，未审计全部实现、未安装运行。 [[研究前沿/uplift模型迭代/01-论文原文与精读/UpliftBench/代码核验|核验记录]]

无本地实验结果。

## 待验证想法

[[研究前沿/uplift模型迭代/03-实验假设与结果/2026-11-06-评估目标与阈值校准|评估目标与阈值校准（未运行）]]
