---
type: "实验"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-13"
experiment_id: "MaximumDelayBatch-objective"
experiment_status: "待设计/未运行"
source_papers: ["arxiv:2611.13865"]
source_modules: ["MaximumDelayBatch-union", "MaximumDelayBatch-gaps"]
local_validation: "未运行"
---

# 将逐单等待换成每批最长等待后，策略排序会不会翻转

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/MaximumDelayBatch/精读|Online Network Design with Maximum Delay and Stochastic Arrivals]]

[[研究前沿/动态等待与匹配决策/02-可复用方法卡/MaximumDelayBatch-union|一批只计最久等待时如何决定是否合批]] · [[研究前沿/动态等待与匹配决策/02-可复用方法卡/MaximumDelayBatch-gaps|逐单连接收费时用到达间隔定服务点]]

## 假设、最小改动与基线

在同一条已保存到达流上同时按两种目标为即时、固定周期、计数阈值策略计分；在两种目标下各用小实例动态规划计算全知分批。

## 数据、口径与约束

仅需各到达时刻、类型与共享启动价；主指标为策略对各自离线最优的成本比，另报总等待、P95 和最长等待。负载覆盖 $L=0.8,1,1.05,2$，纳入末批清空。

## 预算与失败判据

每档 30 个共同随机种子。若排序未变，或差异仅来自未结清末批，则不支持目标口径引起翻转。CPU，未运行。

本地实验尚未运行。
