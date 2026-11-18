---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-12"
module_id: "AbandonBatch-renewal"
source_papers: ["arxiv:2611.11281"]
version: "v1"
local_validation: "未运行"
---

# 按单位时间和后续周期重新选择合批阈值

来源为 [[研究前沿/动态等待与匹配决策/01-论文原文与精读/AbandonBatch/精读|Optimal Batching with Abandonment: Threshold Policies Under Risk-Neutral and Risk-Sensitive Criteria]]。

## 输入、操作与输出

输入每个候选阈值的周期净收益和时长。清空后将系统重置到零，同分布地开始新周期。离线为每个阈值计算 $\mathbb E[R]/\mathbb E[T]$（长期平均），或 $\mathbb E[R(\delta)]/(1-\mathbb E[\delta^T])$（折现）。按定理 4 取第一个边际不再上升的位置；在线只比较库存与所选阈值。

## 原文证据与实现

表 2 在同一标定下对比两种目标；按长期最优值作分母，误用单次停止阈值造成 47.6% 或 18.3% 的模型内损失。两列的折现口径不同。

作者在 §9 公开 Python 实现。已核实仓库中的 batching_core.py、generate_tables.py 与 verify_paper_numbers.py，未运行脚本。[作者代码](https://github.com/Ahkfor/Optimal-Batching-with-Abandonment)

## 迁移推断

适用于清空后系统真正重置的周期控制。若上一批占用车辆或下一轮到达与前一轮相关，应保留跨批状态，不能沿用独立周期比值。

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/AbandonBatch-renewal-objective|单批调出的触发阈值，在重复清空时会损失多少收益]]
