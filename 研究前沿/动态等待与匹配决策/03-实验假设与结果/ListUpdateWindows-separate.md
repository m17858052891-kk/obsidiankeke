---
type: "实验"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-14"
experiment_id: "ListUpdateWindows-separate"
experiment_status: "待设计/未运行"
source_papers: ["arxiv:2611.17083"]
source_modules: ["ListUpdateWindows-head", "ListUpdateWindows-delay"]
local_validation: "未运行"
---

# 逐笔收费后，表首清理比只看截止多赚多少

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/ListUpdateWindows/精读|List Update with Time Windows and Delays without Batch-Serving]]

[[研究前沿/动态等待与匹配决策/02-可复用方法卡/ListUpdateWindows-head|到期前先清掉当前表首的请求]] · [[研究前沿/动态等待与匹配决策/02-可复用方法卡/ListUpdateWindows-delay|用当前位置给同类累计等待定服务阈值]]

## 假设、改动与对照

在相同请求流和初始列表上比较 FER、纯到期移首与到达即移首；同类请求逐笔收费。用小实例精确枚举对照。

## 必要数据、评价与约束

记录发布时间、截止、条目与每次服务后位置，按 k=2、4、8 分层。主指标为访问与交换总成本，另查逐笔截止及同项重叠。

## 预算与失败判据

每层 100 条 CPU 生成流，列长≤5。若 FER 对纯到期策略的优势只在同类免费合并时出现，或出现超时，则不支持迁移假设。

本地实验未运行。
