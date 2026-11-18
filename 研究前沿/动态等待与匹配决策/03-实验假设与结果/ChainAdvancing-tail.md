---
type: "实验"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-14"
experiment_id: "ChainAdvancing-tail"
experiment_status: "待设计/未运行"
source_papers: ["arxiv:2611.16661"]
source_modules: ["ChainAdvancing-bands"]
local_validation: "未运行"
---

# 推进深链缩短的是末批还是多数请求的等待

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/ChainAdvancing/精读|Reducing Batch Makespan for LLM Agent Workloads through Inference-Environment Coordination]]

[[研究前沿/动态等待与匹配决策/02-可复用方法卡/ChainAdvancing-bands|按到达档和已揭示链深分配执行槽]]

## 假设、改动与对照

用同一组分段轨迹，在固定准入和并发槽下只换 FCFS 与分档深度排序；在同档内打乱已见深度作置换对照。

## 必要数据、评价与约束

需要各段所属轨迹、每段到达及服务时长、截止；主指标为 t100−t95，同时看 t95、总工期、单任务 P95 和超时率。

## 预算与失败判据

小型 CPU 离散事件回放，三种槽数，各 50 个相同流。若收益在打乱深度后保持，或总工期不降且主要人群变慢，则“识别长链”解释不成立。

本地实验未运行。
