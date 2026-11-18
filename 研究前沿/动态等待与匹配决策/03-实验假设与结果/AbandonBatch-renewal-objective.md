---
type: "实验"
topics: ["动态等待与匹配决策"]
status: "草稿"
created: "2026-11-12"
experiment_id: "AbandonBatch-renewal-objective"
experiment_status: "待设计/未运行"
source_modules: ["AbandonBatch-first-passage", "AbandonBatch-renewal"]
result: null
run_at: null
logs: null
---

# 单批调出的触发阈值，在重复清空时会损失多少收益

**待设计，未运行。** 同一组到达、耐心和收费条件下，按周期时间计价能使长期平均收益高于按单批收益选阈值。

## 最小改动与基线

固定事件模拟器和在线比较逻辑，只切换离线阈值选择目标。对照含立即服务、固定间隔、单批最优、重复清空最优；给各基线相同调参数据。先重复表 1 参数，再单独改变退出率和服务耗时。

## 数据、预算与失败判据

数据为合成到达和个体离开事件。划分开发与留出随机数流，按流配对；主指标每期净收益，另报尾部等候、退出率和周期数。首轮 CPU 预算与配对种子数待确认。若留出收益差区间含零，记不确定；若更差或违反预先设定的等待约束，记为失败。

代码版本、数据版本、运行时间和日志待确认。论文报告值见 [[研究前沿/动态等待与匹配决策/01-论文原文与精读/AbandonBatch/精读|Optimal Batching with Abandonment: Threshold Policies Under Risk-Neutral and Risk-Sensitive Criteria]]。

- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/AbandonBatch-first-passage|有退出风险时如何从队长确定一次清空阈值]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/AbandonBatch-renewal|按单位时间和后续周期重新选择合批阈值]]
