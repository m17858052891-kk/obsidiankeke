---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-12"
module_id: "AbandonBatch-first-passage"
source_papers: ["arxiv:2611.11281"]
version: "v1"
local_validation: "未运行"
---

# 有退出风险时如何从队长确定一次清空阈值

来源为 [[研究前沿/动态等待与匹配决策/01-论文原文与精读/AbandonBatch/精读|Optimal Batching with Abandonment: Threshold Policies Under Risk-Neutral and Risk-Sensitive Criteria]]。

## 输入、操作与输出

离线输入独立 Bernoulli 到达率、齐性退出率、固定与单件成本、折现率。先用 $x-A+D$ 的转移，从 $f(0)=0,g(0)=1$ 依式 (10)–(13) 向前递推，按 $(\beta\theta-\alpha-f(\theta))/g(\theta)$ 找第一个边际提高不为正的位置；在线比较期初队长与该阈值，清空全批或继续。

## 原文证据与实现

定理 1 在存在可盈阈值时提供模型内全部停止规则的最优性。§4.3 在折现基准下算得阈值 43，阈值 21、43 和 64 的平均周期约为 30、76、155 期。

作者在 §9 公开 Python 实现。已核实仓库中的 batching_core.py、generate_tables.py 与 verify_paper_numbers.py，未运行脚本。[作者代码](https://github.com/Ahkfor/Optimal-Batching-with-Abandonment)

## 迁移推断

可用作同质单队列零服务时间模型的等待基线。每时隙多个到达、异质耐心、履约配对等均会破坏原递推的状态或逐级首达前提。

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/AbandonBatch-renewal-objective|单批调出的触发阈值，在重复清空时会损失多少收益]]
