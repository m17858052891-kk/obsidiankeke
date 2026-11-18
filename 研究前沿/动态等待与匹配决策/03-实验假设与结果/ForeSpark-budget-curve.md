---
type: "实验"
topics: ["动态等待与匹配决策"]
status: "草稿"
created: "2026-11-12"
experiment_id: "ForeSpark-budget-curve"
experiment_status: "待设计/未运行"
source_modules: ["ForeSpark-joint-budget"]
result: null
run_at: null
logs: null
---

# 第一阶段也限额，能否提高每秒有效确认数

**待设计，未运行。** 第一阶段成本随总候选数上升且不同请求收益不同时，联合配置比固定第一阶段、只裁剪第二阶段有更高单位时间确认量。

## 最小改动与基线

固定候选生成器、最终匹配和所见历史。比较全量第一阶段+按需验证、按负载统一截断、每请求联合分配，并在小批量对照枚举解。

## 数据、预算与失败判据

先使用合成曲线，再用经许可的候选接受/拒绝记录和延迟测量；按时段切分，盲测时同时固定离线校准和容量。主指标有效确认/秒，约束 P95 等待与最差分组最低覆盖。初始 CPU 回放预算待确认。若优势仅来自放宽延迟或某分组被持续饿死则判失败。

代码版本、数据版本、运行时间和日志待确认。论文报告值见 [[研究前沿/动态等待与匹配决策/01-论文原文与精读/ForeSpark/精读|ForeSpark: Joint Draft and Verification Budget Scheduling for Parallel Speculative Decoding]]。

- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/ForeSpark-joint-budget|按接受概率与实测批延迟联选两个阶段的预算]]
