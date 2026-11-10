---
title: "召回重构 R03：CAA 与 OCR 实验"
type: analysis
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_key: b020-evidence-recall-r03
source_ids: ["cooper:knowledge:2209585652707"]
source_url: "https://cooper.didichuxing.com/knowledge/2199610335356/2209585652707"
related: ["召回重构R01-Hold与TP实验.md", "../模型/caa应答前取消模型.md"]
---
# 召回重构 R03：CAA 与 OCR 实验

## 设计

R03 用四组拆分两个问题：CAA 距离加权模型增加“非连环派 2.35km 内输出置零”规则，以及 OCR 从静态阈值切换到不同区分度的单调模型。比较链路包含召回覆盖、距离分桶、等待时长与完单。

## 历史结果

- CAA 近距离规则恢复了近距离候选召回，但影响扩展到全距离段，远距离召回和平均接驾距离显著回升，未形成完单收益。
- OCR 中区分度更高的单调版本呈现“少召回、低距离、略高完单质量”的方向；相对静态阈值的整体优势尚未被明确验证。
- 因此该轮证明了规则可修复局部过滤过严，却没有证明它改善总体交易效率。

## 证据边界

来源含 9 张未解析图片；大盘结果、距离长表和反事实日志未独立复算。实验配置与结论属于 R03 历史证据，不能当作当前 CAA/OCR 线上版本。

## 来源

- [R03_0903](../../raw/cooper/knowledge-2209585652707.md)（SHA-256 `77c784ae703005e9d73be3527f37f7b9bf92b57a9afb4ca3bf28d2c78938708f`）
