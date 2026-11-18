---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-12"
module_id: "IntelligentDelivery-resource-value"
source_papers: ["meta:2026-11-11-intelligent-delivery"]
version: "2026-11-11"
local_validation: "未运行"
---

# 用分档增量收益和延迟代价选择请求的资源量

来源为 [[研究前沿/动态等待与匹配决策/01-论文原文与精读/IntelligentDelivery/精读|Intelligent Delivery: Making Every Unit of Compute Serve Better Ads]]。

## 输入、操作与输出

输入请求上下文、候选资源档位、当前容量和尾延迟约束。召回前运行一次共享特征模型，各专用预测器估计档位的收益与成本，主机内再对并发请求求受约束分配。可用 $\max\sum_i\widehat u_i(a_i)$ 且容量、尾延迟可行为迁移建模示意；原文未给这条公式、估计器损失或求解器。

## 原文证据与实现

工程文报告主要产品面识别高影响请求的离线表现相对旧模型约提高 20%。指标定义、分母、对照设置和区间均未公开；多年整体约 10% 的广告排序改进不能单独归因于该模块。

公开材料提供结构图与流程，未公开模型权重、训练数据或生产调度代码。

## 迁移推断

候选召回深度或计算强度若可以按请求调整，可先检验额外预算的可辨识收益，再比较分档配置。系统状态会影响后续延迟，单请求离线排序无法确认整机收益。

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/IntelligentDelivery-fixed-budget|相同容量和尾延迟下，按请求分档是否胜过静态分组]]
