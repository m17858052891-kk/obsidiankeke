---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-13"
module_id: "SubmodBandit-counts"
source_papers: ["arxiv:2611.11808"]
version: "v1"
local_validation: "未运行"
---

# 靠组规模和重复次数从整组反馈更新元素概率

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/SubmodBandit/精读|Efficient Online Submodular Maximization with Bandit Feedback]]

## 输入、流程与输出

预先输入容量、候选数、时长和奖励界。以论文分布抽 M，再有放回抽元素，去重执行；记录次数 N，接收一次标量收益，按式 (6) 除以规模与元素采样概率，更新下一轮的元素分布。

## 最小采用单元与依赖

最小单元包括组规模随机化、重复计数、归一化和正概率优化器。需要整组收益及时返回与边际价值递减。重试/延迟反馈和组内互补会改变保证。

## 原文证据与实现

算法 2，定理 3–5、图 1 与附录 E。三种实际基准的经验排名与一般类的理论界分别登记。

作者仓库已核实到 algorithms/sub_ew.py、main.py、固定 instances/ 和 tests/test_sub_ew.py，未运行。[仓库固定版本](https://github.com/jasonNikolaou/bandit-osm/tree/e01bce3f1e04c324833170ebd76c6ed132a9379a)

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/SubmodBandit-returns|候选搭配产生互补时，单调次模策略在哪里失效]]
