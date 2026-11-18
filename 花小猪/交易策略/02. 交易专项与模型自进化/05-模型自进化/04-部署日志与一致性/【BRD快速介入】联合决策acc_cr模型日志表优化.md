---
title: "【BRD快速介入】联合决策acc_cr模型日志表优化"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2206959515792
cssclasses: ["strategy-body-note"]
---

# 【BRD快速介入】联合决策acc_cr模型日志表优化

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2206959515792)

望岳：<https://ddp.intra.xiaojukeji.com/requirement/story/R-KF-644387?backUrl=/workbench/requirement>

## 一、需求背景

联合决策acc_cr模型的日志需要落商家 X 折扣维度的特征。当城市（如哈尔滨）的商家数过多时，日志表会超过1.3M的长度限制，在落ods表时会被截断。此时线上acc_cr计算正常，但下游仿真无法正常从Json字段中解析出日志，取到的sds特征均为空，**离线预测的acc_cr、默勾acc_cr阈值偏高**，进一步导致默勾水位偏高。

因此需要工程在过模型时进行优化，保证模型日志表的正确性，不被截断。

## 二、需求内容

日志表：kflower_marketplace.ods_log_kflower_dups_eve_public_log_h

模型：union_strategy_ar_deep_model_gpu

需要在过acc_cr模型时做切片，保证一条日志表的长度不被截断。
