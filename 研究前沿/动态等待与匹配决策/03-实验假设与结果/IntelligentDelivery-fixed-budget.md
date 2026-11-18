---
type: "实验"
topics: ["动态等待与匹配决策"]
status: "草稿"
created: "2026-11-12"
experiment_id: "IntelligentDelivery-fixed-budget"
experiment_status: "待设计/未运行"
source_modules: ["IntelligentDelivery-resource-value"]
result: null
run_at: null
logs: null
---

# 相同容量和尾延迟下，按请求分档是否胜过静态分组

**待设计，未运行。** 若额外预算的边际收益在同一静态分组内仍差异明显，按请求配置能提高总有效结果。

## 最小改动与基线

保持候选模型和可选档位固定；离线允许随机分档的安全回放或合法实验记录上，比较同组定额、只按预期收益分档、联合收益与成本分档。

## 数据、预算与失败判据

需要各档成本与结果可比的样本、尾延迟与负载日志，按时间和负载分层留出。主指标单位预算的有效结果、约束为尾延迟和各组最低服务率。先估可辨识性，计算预算待确认。若档位选择缺少重叠则未能验证；若约束内无可重现增益或只在改变分母后见效则否定。

代码版本、数据版本、运行时间和日志待确认。论文报告值见 [[研究前沿/动态等待与匹配决策/01-论文原文与精读/IntelligentDelivery/精读|Intelligent Delivery: Making Every Unit of Compute Serve Better Ads]]。

- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/IntelligentDelivery-resource-value|用分档增量收益和延迟代价选择请求的资源量]]
