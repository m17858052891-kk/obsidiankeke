---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-13"
module_id: "PrescribedBatch-count"
source_papers: ["arxiv:2611.13757"]
version: "v1"
local_validation: "未运行"
---

# 单资源批量如何随到达率和固定成本改变

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/PrescribedBatch/精读|Stochastic Aggregation with Prescribed Resources and Additive Delay]]

## 输入、流程与输出

用 $q=\lambda w$ 计算 $n^*=\arg\min_{n\ge1} q/n+(n-1)/2$，在线在第 $n^*$ 个到达时清空，未凑齐的一批设置逐批增长的兜底时间。

## 最小采用单元与依赖

只需离线估计一项到达率及一次采购成本；有提前流失或非线性等待惩罚时阈值须重新计算。

## 原文证据与实现

§3.1–3.3、定理 6.3 和 6.7。$q=1$ 的最坏比约 1.409；无需用这个数预测多资源效果。

版本页及正文未列作者实现。多资源重建入口在 §7.2 的 LP 与 §7.4–7.5 的周期选择，单资源在定理 6.3。

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/PrescribedBatch-phase|同步不同队列的时钟，能节省多少重复采购]]
