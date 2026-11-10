---
title: "B006 模型来源：OCR等待风险建模"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: draft
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2208839733814", "cooper:knowledge:2209420315886"]
related: ["../模型/订单流失率OCR模型.md"]
---

# B006 模型来源：OCR等待风险建模

OCR 以“订单×未播单轮次”为样本，预测约 3 秒内是否流失。多通道方案把等待时间、静态风险和二者交互拆开，以避免重复静态特征淹没等待效应；同时建议按订单归一化损失，避免长生命周期订单贡献过多负样本。

迭代材料记录了从多通道 BCE 到显式正斜率、最大值截断、固定概率基线和时间形状建模的候选版本。单调性是结构假设，不等于真实风险必然单调；必须按等待分桶检查 AUC、LogLoss、校准和消融。将“最后一次出现”直接作为流失标签仍可能混入日志截断或异常退出。

## 原始来源

- [OCR离散Hazard与等待时间多通道建模方案](../../raw/cooper/knowledge-2208839733814.md)（sha256 `ec003f2ce3ba63fc305370449f8869ab873468ac596f99fb1fbe4f596ea5559c`）
- [OCR模型迭代](../../raw/cooper/knowledge-2209420315886.md)（sha256 `bb8bb19fc33affab27b990e625f8dc521e1610421ce38859d71740370a2c3897`）

