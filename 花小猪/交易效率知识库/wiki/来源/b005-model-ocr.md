---
title: "B005 模型来源：订单流失率OCR"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: draft
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2208342461509"]
related: ["../模型/订单流失率OCR模型.md"]
---

# B005 模型来源：订单流失率OCR

OCR定义为当前轮不播单时，订单在约2秒轮次间隔内因乘客取消或被其他商家应答而流失的概率；不是订单全生命周期取消率。样本来自历史上该轮未向任何司机播单的订单，最后一次出现即标正样本的构造可能混入日志截断或系统异常，需要专门核验。

OCR进入hold价值，系统性偏高会推动召回，偏低会推动等待。特征方案仍有离线/在线来源和样本空间待确认，因此本页只记录设计契约，不声明模型已完成或上线。

## 原始来源

- [OCR建模](../../raw/cooper/knowledge-2208342461509.md)（sha256 `9ad3dfd416dbfd6a804652679dba764d4bc4ac934bc01cab619a13f77b6eafa5`）
