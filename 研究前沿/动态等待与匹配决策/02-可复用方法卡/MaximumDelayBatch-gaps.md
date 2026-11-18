---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-13"
module_id: "MaximumDelayBatch-gaps"
source_papers: ["arxiv:2611.13865"]
version: "v1"
local_validation: "未运行"
---

# 逐单连接收费时用到达间隔定服务点

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/MaximumDelayBatch/精读|Online Network Design with Maximum Delay and Stochastic Arrivals]]

## 输入、流程与输出

取合并流的前 $m$ 个到达间隔，按类型速率缩放为指数样本；构造半径、排序、剔除候选设施集合重叠的项，再固定其余请求的设施与清空日历。输出分区、即服务或延迟服务。

## 最小采用单元与依赖

最小单元是初始化采样后锁定分区。需要独立恒定泊松率、设施距离与启动费；使用间隔只作初始随机来源，并非估计未来需求趋势。

## 原文证据与实现

§4.1–4.4、定理 8.1；渐增周期给长期 3 倍，推论 8.7 给有限等待的取舍。

arXiv 正文未给实现仓库；§6.3 的算法 1 与 §8.3、§8.7 的算法 2 给出可核对步骤。

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/MaximumDelayBatch-objective|将逐单等待换成每批最长等待后，策略排序会不会翻转]]
