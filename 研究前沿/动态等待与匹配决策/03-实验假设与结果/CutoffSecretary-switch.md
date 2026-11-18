---
type: "实验"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-14"
experiment_id: "CutoffSecretary-switch"
experiment_status: "待设计/未运行"
source_papers: ["arxiv:2611.14651"]
source_modules: ["CutoffSecretary-boundary"]
local_validation: "未运行"
---

# 同一份排序是否因无害估值误差提前回退

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/CutoffSecretary/精读|Multiple-Choice Secretary Problem with Predictions]]

[[研究前沿/动态等待与匹配决策/02-可复用方法卡/CutoffSecretary-boundary|什么时候放弃预测前 k 名名单]]

## 假设、改动与对照

在不改变前 k 名集合的情形只放大某些入选项真值，再引入少量跨边界误差。比较全名单相对误差触发、双侧分界触发、始终采用预测和无预测回退。

## 必要数据、评价与约束

模拟有固定 ID 与真值的候选表；同一随机到达排列和固定 k 对四法共用。主指标是相对离线前 k 收益，辅报切换时刻、剩余容量和误触发数。

## 预算与失败判据

每档容量与错误类型各 100 个配对排列，CPU。若无跨界时分界规则仍切换，或跨界场景没有减少误切换与收益损失，则不支持该假设。

本地实验未运行。
