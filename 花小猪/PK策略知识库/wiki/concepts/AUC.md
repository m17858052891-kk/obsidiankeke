---
title: AUC
type: concept
created: 2026-05-26
updated: 2026-05-26
tags:
  - 指标
  - 机器学习
related:
  - wiki/entities/PK模型.md
  - wiki/entities/PK可解释模型.md
  - wiki/entities/自动化更新机制.md
---

# AUC

AUC（Area Under the ROC Curve）是 [[花小猪/PK策略知识库/wiki/entities/PK模型.md|PK 模型]]的**核心离线评估指标**，衡量模型区分正样本（胜出完单）和负样本（胜出未完单）的能力。

## 定义

**AUC** 即 ROC 曲线下面积（Area Under the Receiver Operating Characteristic Curve）。

- **ROC 曲线**：以 FPR（假阳性率）为横轴、TPR（真阳性率/召回率）为纵轴，遍历所有分类阈值绘制的曲线。
  - TPR = TP / (TP + FN)  — 正样本中被正确识别的比例
  - FPR = FP / (FP + TN)  — 负样本中被错误标为正的比例
- **AUC 取值范围**：[0, 1]
  - **1.0** = 完美分类器（正负样本完全分开）
  - **0.5** = 随机猜测（无区分能力）
  - **< 0.5** = 比随机差（模型预测反向）

### 直观理解

AUC 等价于：**随机取一个正样本和一个负样本，模型给正样本打分高于负样本的概率**。

$$AUC = P(s_{pos} > s_{neg})$$

即所有正负样本对中，模型排序正确的比例（等价于 Wilcoxon-Mann-Whitney 统计量）。

### 为什么用 AUC 而非准确率

| 问题 | 准确率（Accuracy） | AUC |
|------|-------------------|-----|
| 样本不平衡 | 易受多数类主导 | 不受类别比例影响 |
| 阈值依赖 | 需先选定阈值 | 综合所有阈值的表现 |
| 排序能力 | 不反映排序质量 | 直接衡量排序质量 |

在 PK 场景中，关注的是"谁比谁更可能完单"的**排序能力**，而非单一阈值下的分类结果，因此 AUC 是天然适配的指标。

## 在 PK 系统中的应用

| 场景 | 用途 |
|---|---|
| 模型训练 | 验证集 AUC 评估模型质量 |
| 模型上线 | AUC 需达到阈值方可发布 |
| [[花小猪/PK策略知识库/wiki/entities/自动化更新机制.md|自动化更新]] | 新模型 AUC 不低于基线才能灰度 |
| 模型对比 | XGB vs LR vs Deep 的核心对比指标 |

## 各模型的 AUC

| 模型 | AUC | 说明 |
|---|---|---|
| XGBoost（PBD 端）| ==0.7345== | 40+ 特征，验证期 2024/01/02-01/15 |
| XGBoost（PBD 端验证）| ==0.7360== | 同上 |
| [[花小猪/PK策略知识库/wiki/entities/PK可解释模型.md|LR 可解释模型]] | ~0.72 | 特征精简后略低 |
| Deep 模型 | 探索中 | PLE + AutoInt 等架构 |

## AUC 与线上效果的关系

> [!warning] AUC 不等于线上效果
> AUC 更高不一定意味着线上完单率更高。LR 模型 AUC 略低于 XGB，但在宏鹄等三方商家上完单率反而提升 10%，因为可解释性带来的商家行为改善是 AUC 无法衡量的。

## 深入阅读

- [[花小猪/PK策略知识库/wiki/sources/01-司乘履约模型迭代.md]] — 线上 LR AUC > XGB 的重要发现
- [[花小猪/PK策略知识库/wiki/sources/03-PK可解释模型.md]] — 各版本离线 AUC 对比
