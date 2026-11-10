---
type: "索引"
topics: ["动态等待与匹配决策","模型迭代"]
status: "维护中"
created: "2026-11-04"
---

# 动态等待与匹配决策

面对动态到达和不确定反馈，何时立即行动、继续等待、触发批量匹配，以及怎样分配双方资源？

## 第一次读，从这里开始

先读 [[研究前沿/动态等待与匹配决策/01-论文原文与精读/TimelyThrifty/精读|可以等到截止时再合批吗]]。先画一条从到达到必须服务的时间线，标出什么时候得承诺、什么时候才能看到后续候选。下面的几种策略在这两个条件上有实质差别。

## 按研究问题阅读

### 现在承诺还是继续等

同样要少发几箱，[[研究前沿/动态等待与匹配决策/01-论文原文与精读/DispatchDeadlineFF/精读|DispatchDeadlineFF 的到达即绑定]] 要求订单到达时就绑定一个箱，后续只能向仍开放的箱追加。[[研究前沿/动态等待与匹配决策/01-论文原文与精读/TimelyThrifty/精读|TimelyThrifty 的截止时合批]] 可以先让订单留在待定池，到最早截止时再装箱。同一条订单流上，应先写明决策时点，再比较箱数和可行性。两篇均给出在线装箱的理论结果。

[[研究前沿/动态等待与匹配决策/02-可复用方法卡/TimelyThrifty-trigger-edf-skip|到期触发后怎样挑能装下的订单]] · [[研究前沿/动态等待与匹配决策/03-实验假设与结果/TimelyThrifty-deadline-batch-fill|未运行：分档容量与硬截止下的合批对照]]

### 有限容量优先分给谁

到单时有几类资源可选，眼前配哪一对，会影响下一单。[[研究前沿/动态等待与匹配决策/01-论文原文与精读/StaticPriority/精读|StaticPriority]] 用匹配收益扣除占用两类资源的机会成本，预先排好优先顺序。[[研究前沿/动态等待与匹配决策/01-论文原文与精读/LongestQueue/精读|LongestQueue]] 先用流体优化筛出合适的匹配边和关键类型，真正分配时再看哪些关键队列更长。选择基线时先问能否得到可信的到达率和耐心参数，以及实时队长是否可见。两篇理论结果采用的比较基准也不同。

[[研究前沿/动态等待与匹配决策/02-可复用方法卡/LongestQueue-dual-critical-queue|筛边与关键队列怎么配合]] · [[研究前沿/动态等待与匹配决策/03-实验假设与结果/2026-11-05-匹配理论基线|未运行：静态优先级与最长关键队列怎样比较]]

### 供需或等待成本变化后还能用吗

若变化来自等候本身，[[研究前沿/动态等待与匹配决策/01-论文原文与精读/VRM/精读|VRM]] 给出一个能解释的触发条件：累积等待成本足以覆盖最小增广路净成本时执行匹配。论文分析线性等待成本；若乘客会提前退出，需重新评估。若变化来自城市间奖励或转移规律不同，[[研究前沿/动态等待与匹配决策/01-论文原文与精读/DFQI/精读|DFQI]] 把目标城市和其他市场的 Q 函数联合估计，允许保留差异。它的迁移结果来自模拟及半合成轨迹，可先与只用目标市场数据的基线比较。

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/DFQI-检验小流量市场跨域训练的负迁移|未运行：低流量市场在什么条件下会出现负迁移]]

## 完整资料与相关精读

[[研究前沿/00-总览|研究前沿总览]] · [[研究前沿/动态等待与匹配决策/01-论文原文与精读/README|论文原文与精读]] · [[研究前沿/动态等待与匹配决策/02-可复用方法卡/README|可复用方法卡]] · [[研究前沿/动态等待与匹配决策/03-实验假设与结果/README|实验假设与结果]]

以往精读另见 [[研究前沿/动态等待与匹配决策/01-论文原文与精读/ALIGN-HOLD/精读|ALIGN-HOLD]] · [[研究前沿/动态等待与匹配决策/01-论文原文与精读/GenMatch/精读|GenMatch]] · [[研究前沿/动态等待与匹配决策/01-论文原文与精读/TopKQueue/精读|TopKQueue]]。

[[研究前沿/_运行记录/README|最近一期与历史记录]] · [[研究前沿/_运行记录/待处理队列|待核原文]]

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

## 初始检索线索

历史检索锚点（不视为本次新论文或已精读）：[online matching with delays](https://arxiv.org/abs/2408.08658)；[Lyft 非独占派单与市场分析](https://arxiv.org/abs/2603.21531)。锚点用于扩展引文和术语，不能替代近期检索。

## 队列处理规则

取消每日总篇数及每方向篇数上限；按创新价值、机制清晰度和可信效果证据决定精读数量，不凑数。每天先检查已有待精读队列，与新候选按价值、证据及等待时间共同排序，持续处理旧队列。只因原文不可访问、证据待核实或执行实际中断等具体原因保留待处理，并记录下一步；不因达到篇数或固定阅读预算而入队。理论与有价值的负面结论同样可收录。
