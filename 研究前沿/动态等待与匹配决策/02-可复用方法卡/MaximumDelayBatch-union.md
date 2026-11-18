---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-13"
module_id: "MaximumDelayBatch-union"
source_papers: ["arxiv:2611.13865"]
version: "v1"
local_validation: "未运行"
---

# 一批只计最久等待时如何决定是否合批

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/MaximumDelayBatch/精读|Online Network Design with Maximum Delay and Stochastic Arrivals]]

## 输入、流程与输出

输入固定单独成本、泊松率及通用服务上限 $M$。以 $L=\sum\lambda_xs_x$ 分两档，低档即时服务，高档按确定周期清空非空队列，输出下一服务时间与服务集合。

## 最小采用单元与依赖

可直接采用的单元是负载分支加清空时钟，初始化须同时核对统一动作和单独最低成本的假设。训练为空，模型只在到达时观测。

## 原文证据与实现

§3.2–3.5、算法 1、定理 6.2/6.5 节的一地点紧例。把请求等待相加会改变目标和证明。

arXiv 正文未给实现仓库；§6.3 的算法 1 与 §8.3、§8.7 的算法 2 给出可核对步骤。

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/MaximumDelayBatch-objective|将逐单等待换成每批最长等待后，策略排序会不会翻转]]
