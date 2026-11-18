---
type: "实验"
topics: ["动态等待与匹配决策"]
status: "草稿"
created: "2026-11-12"
experiment_id: "ForestMatching-cycles"
experiment_status: "待设计/未运行"
source_modules: ["ForestMatching-load-round"]
result: null
run_at: null
logs: null
---

# 候选图首次出现环后，按端点独立性舍入的误差有多大

**待设计，未运行。** 无环边流中联合空闲频率应等于端点边际乘积；插入闭环边后可能出现系统偏差。

## 最小改动与基线

冻结顺序、无权目标与容量。随机森林和 §6 硬例作正控，再只加入一条、逐步增多闭环边；比较算法 2、贪心与整图离线最大匹配。

## 数据、预算与失败判据

数据为可精确求最大匹配的小图；按图库分开发／留出，多随机种子复用同一图。主指标联合空闲频率误差与匹配规模/离线最优，报告区间。CPU 图规模和种子待确认。森林正控若无法恢复边际规律，应先排查实现；环上无稳定差异则否定所测偏差假设。

代码版本、数据版本、运行时间和日志待确认。论文报告值见 [[研究前沿/动态等待与匹配决策/01-论文原文与精读/ForestMatching/精读|Tight Competitive Bounds for Online Matching on Forests]]。

- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/ForestMatching-load-round|在森林边流上按端点空闲概率修正接纳率]]
