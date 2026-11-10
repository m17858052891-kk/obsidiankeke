---
title: "实验评估 SQL 口径"
type: concept
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_ids: ["cooper:2209627092241", "cooper:2209605799076"]
related: ["index.md", "trade-funnel.md", "average-pickup-distance.md", "driver-cancel-after-answer-rate-with-reassign.md"]
---
# 实验评估 SQL 口径

## 实验单位与主链路

该快照是多组 SQL 模板，不是实验结论。乘客分流模板先从 Apollo 取 `pid` 和实验组，再按乘客聚合冒泡、呼叫、应答、完单、取消与接驾指标。另有时间片实验模板，两种分流不可混用同一显著性口径。

## 指标口径

- 呼叫/应答/完单均以去重订单计数，并按自营、宏鹄、API、滴滴自营和三方品牌拆分。
- 应答后乘客/司机取消同时保留“含改派”和“不含改派”计数；引用时必须标注版本。
- 平均预估接驾时长/距离以应答单为分母；距离模板还有 `>=3.5km` 的远距离订单计数。
- 时效链路包含呼叫到首次应答、到达和开始计费的时长，分母随应答量/完单量变化，不能只比较分子。

## 显著性

模板输出实验组与对照组均值、样本量、二阶矩及 95% 区间；区间上下界同号时标记显著。文档还要求 AA、AB 分别运行后再合并，因此未做 AA 验证的结果不应直接进入扩量决策。

## 2026 平台整合模板补充

平台大盘模板将漏斗评估、平台 ETP 与司机接驾时长合并，归一订单口径对齐 ETP，并以唯一 `pid + dt` 样本骨架左连接各指标表，避免拿某个中间表日期作为其他指标锚点。当前司机接驾时长仍采用开始计费口径，原文明确标记待改为到达口径；配套 Excel 未解析，因此模板只能作为待参数化、待验算的口径基线，不是实验结果。

## 覆盖缺口与来源

- SQL 包含多个不同实验的日期、城市和实验 key，执行前必须参数化复核；本页未执行任何 SQL。
- 原始快照：`raw/cooper/cooper-2209627092241.md`
- 补充快照：`raw/cooper/cooper-2209605799076.md`
- 来源：https://cooper.didichuxing.com/team-file/2199582756311/2209627092241
- 补充来源：https://cooper.didichuxing.com/team-file/2199582756311/2209605799076


