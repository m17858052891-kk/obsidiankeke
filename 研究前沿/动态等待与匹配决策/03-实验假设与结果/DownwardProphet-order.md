---
type: "实验"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-14"
experiment_id: "DownwardProphet-order"
experiment_status: "待设计/未运行"
source_papers: ["arxiv:2611.16880"]
source_modules: ["DownwardProphet-order"]
local_validation: "未运行"
---

# 随机到达与可挑顺序在同一个约束族中差多少

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/DownwardProphet/精读|Tight Bounds for Downward-Closed Prophet and Secretary Problems]]

[[研究前沿/动态等待与匹配决策/02-可复用方法卡/DownwardProphet-order|用先验尺度决定优先观察哪些高价值机会]]

## 假设、改动与对照

以两个有互斥关系的大组及组内子集构造向下封闭族。固定独立激活指数分布，对比随机检查、降尺度顺序、反序，均用同一有限期动态规划接纳。

## 必要数据、评价与约束

生成小集合与已知先验，存同一组事后取值以分别计算离线最优。主指标为平均离线收益／平均在线收益，另报互斥约束锁定时刻。

## 预算与失败判据

至多 12 项，每档 200 个同种子样本。若降序的配对差异覆盖零，则这一实例不能支持可控排序有收益；小样本不用于验证渐近下界。

本地实验未运行。
