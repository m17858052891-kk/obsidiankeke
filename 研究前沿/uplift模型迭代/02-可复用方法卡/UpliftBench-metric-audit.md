---
type: "方法"
topics: ["研究前沿", "方法精读"]
status: "维护中"
created: "2026-11-06"
module_id: "upliftbench:metric-audit"
paper_id: "arxiv:2608.00915"
local_validation: "未验证"
---

# 同预测上的uplift指标实现与稳定性审计

来源：[[研究前沿/uplift模型迭代/01-论文原文与精读/UpliftBench/精读|UpliftBench 精读]] · [原文](https://arxiv.org/html/2608.00915v1)

## 输入与输出

固定折预测、多个指标实现→排名冲突及不确定性报告

## 计算、训练与推理流程

保存计数/前缀均值定义；比较Qini、两种AUUC、policy value，按独立单位重采样；显式记录跳过/超时。

## 效果证据与归因

100IHDP Qini近零相关，ACIC/收入合成不复现；体现诊断价值而非通用指标优劣。

## 最小采用单元与耦合依赖

可独立采用评估层，不需复用全部模型；需保留预测及数据版本。

## 数据假设与失败边界

重复CV折不能当独立实验；数据子采样可改变排名。

## 潜在迁移（推断）

为后续autoresearch建立可追溯评估证据，减少优化错指标。

## 代码与本地验证

已核验[作者仓库](https://github.com/binshuangli/uplift-bench)，commit `604cf7caee4f2f1322e0eac81968161741c7a99f`；入口：[scripts/run_bench.py](https://github.com/binshuangli/uplift-bench/blob/604cf7caee4f2f1322e0eac81968161741c7a99f/scripts/run_bench.py)；[scripts/f2_threshold.py](https://github.com/binshuangli/uplift-bench/blob/604cf7caee4f2f1322e0eac81968161741c7a99f/scripts/f2_threshold.py)。已读取入口声明/关键片段，未审计全部实现、未安装运行。 [[研究前沿/uplift模型迭代/01-论文原文与精读/UpliftBench/代码核验|核验记录]]

无本地实验结果。

## 待验证想法

[[研究前沿/uplift模型迭代/03-实验假设与结果/2026-11-06-评估目标与阈值校准|评估目标与阈值校准（未运行）]]
