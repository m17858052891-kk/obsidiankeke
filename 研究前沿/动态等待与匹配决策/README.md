---
type: "索引"
topics: ["动态等待与匹配决策","模型迭代"]
status: "维护中"
created: "2026-11-04"
---

# 动态等待与匹配决策

面对动态到达和不确定反馈，何时立即行动、继续等待、触发批量匹配，以及怎样分配双方资源？

[[研究前沿/00-总览|研究前沿总览]] · [[研究前沿/动态等待与匹配决策/01-论文原文与精读/README|论文原文与精读]] · [[研究前沿/动态等待与匹配决策/02-可复用方法卡/README|可复用方法卡]] · [[研究前沿/动态等待与匹配决策/03-实验假设与结果/README|实验假设与结果]]

## 中文关键词

动态等待、延迟匹配、匹配时机、自适应批处理、批量匹配、在线匹配、最优停止、等待成本、耐心与放弃、动态资源分配、序贯匹配、截止时间约束。

## 直接相关英文关键词

- dynamic matching
- online matching with delays
- matching timing
- delayed matching
- adaptive batching
- batch matching
- optimal stopping
- waiting-time control
- deadline-aware matching
- dynamic resource allocation

## 跨领域方法关键词

- two-sided matching
- stochastic matching
- bipartite matching
- queueing control
- abandonment and reneging
- patience modeling
- learning-augmented online algorithms
- competitive analysis
- contextual bandits
- constrained Markov decision process
- semi-Markov decision process
- multi-agent reinforcement learning
- model predictive control
- uncertain acceptance
- reassignment and retry policies

## 可直接执行的检索组合

每条独立检索，按检索日期附加时间窗口；不得要求同一论文命中全部词。

- `"online matching" delays`
- `"dynamic matching" waiting cost`
- `"matching timing" reinforcement learning`
- `"adaptive batching" optimization`
- `"optimal stopping" matching`
- `"batch matching" cancellation patience`
- `"ride-hailing" matching dispatch waiting`
- `动态等待 延迟匹配 批量匹配 最优停止`

扩展路线：

- `"online resource allocation" delayed feedback`
- `"queueing control" abandonment learning`
- `"learning-augmented" online matching`
- `"stochastic matching" uncertain acceptance`
- `"optimal stopping" scheduling batching`

## 收录边界

同时覆盖网约车、拼车、即时配送、双边市场、排队调度和通用在线算法。接纳可迁移的等待价值估计、触发策略、资源竞争建模和求解模块，不要求现成网约车结果。纯静态匹配或一般路径规划需有与动态等待/分配决策清楚相连的创新模块。

论文创新模块和效果证据是主要标准；当前项目是否能立即接入仅作附注。跨方向论文按最主要贡献确定正文目录，在其他方向建立链接。

## 已有知识关联

[[生成式出价-仿真系统/README|生成式出价与仿真系统]]可作为后续项目映射参考，不作为论文准入条件。

## 初始检索线索

历史检索锚点（不视为本次新论文或已精读）：[online matching with delays](https://arxiv.org/abs/2408.08658)；[Lyft 非独占派单与市场分析](https://arxiv.org/abs/2603.21531)。锚点用于扩展引文和术语，不能替代近期检索。


## 2026-11-05 更新

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/ALIGN-HOLD/精读|ALIGN-HOLD 关键方法精读]] · [[研究前沿/_运行记录/2026-11-05-三方向检索|本期检索记录]]


## 2026-11-05 队列精读与处理规则

取消每日总篇数及每方向篇数上限；按创新价值、机制清晰度和可信效果证据决定精读数量，不凑数。每天先检查已有待精读队列，与新候选按价值、证据及等待时间共同排序，持续处理旧队列。只因原文不可访问、证据待核实或执行实际中断等具体原因保留待处理，并记录下一步；不因达到篇数或固定阅读预算而入队。理论与有价值的负面结论同样可收录。

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/LongestQueue/精读|LongestQueue]] · [[研究前沿/动态等待与匹配决策/01-论文原文与精读/StaticPriority/精读|StaticPriority]] · [[研究前沿/动态等待与匹配决策/01-论文原文与精读/GenMatch/精读|GenMatch]] · [[研究前沿/动态等待与匹配决策/01-论文原文与精读/TopKQueue/精读|TopKQueue]]

[[研究前沿/_运行记录/2026-11-05-队列精读|本次9篇精读与19张方法卡]]


<!-- 2026-11-06-daily-update -->
## 2026-11-06 检索与精读

新增精读 8 篇、方法卡 8 张、未运行实验假设 2 项。

[[研究前沿/_运行记录/2026-11-06-三方向检索与精读|本期全部论文、证据与检索覆盖]] · [[研究前沿/_运行记录/待处理队列|当前待处理状态]]
