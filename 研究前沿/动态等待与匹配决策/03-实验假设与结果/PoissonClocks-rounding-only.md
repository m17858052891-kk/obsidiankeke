---
type: "实验"
topics: ["动态等待与匹配决策"]
status: "草稿"
created: "2026-11-12"
experiment_id: "PoissonClocks-rounding-only"
experiment_status: "待设计/未运行"
source_modules: ["PoissonClocks-first-age"]
result: null
run_at: null
logs: null
---

# 只替换舍入的随机性，能否降低连续遗漏

**待设计，未运行。** 分数与候选资源完全固定时，相关时钟可能降低资源多轮零分配的概率，同时保留逐轮边际。

## 最小改动与基线

用同一组预生成分数轨迹，分别采用独立指数舍入和 First-Age 生成器；另用论文完整 Display Ads 分配作为独立对照。冻结分数层，记录资源连续遗漏和价值。

## 数据、预算与失败判据

按图与分数轨迹拆分开发/留出，平衡大小分数及突发流量。首要检查单轮频率与分数一致，再比较零分配率和最高保留价值；配对区间、CPU 规模待确认。边际检验失败先查实现，边际相同但遗漏指标无改善则拒绝迁移假设。

代码版本、数据版本、运行时间和日志待确认。论文报告值见 [[研究前沿/动态等待与匹配决策/01-论文原文与精读/PoissonClocks/精读|Online Correlated Exponential Clocks]]。

- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/PoissonClocks-first-age|保持逐轮分配概率的跨轮相关指数时钟]]
