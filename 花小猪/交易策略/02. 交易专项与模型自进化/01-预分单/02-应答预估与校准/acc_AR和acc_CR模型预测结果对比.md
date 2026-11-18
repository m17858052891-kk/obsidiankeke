---
title: "acc_AR和acc_CR模型预测结果对比"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2204778032787
cssclasses: ["strategy-body-note"]
---

# acc_AR和acc_CR模型预测结果对比

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2204778032787)

这里记录 2025-07-01 的时序对比。AR 按 call_time 聚合，CR 按 bubble_time 聚合；两者时间基准不同。CR 部分比较两种末层函数，图中读数按原实验理解。

**阅读定位**　[[#acc_AR模型预测值时序图|acc_AR模型预测值时序图]] · [[#acc_CR|acc_CR]]

## acc_AR模型预测值时序图

日期：2025-07-01

ar：基于call_time，5min时间片聚合真实的ar计算的结果

![](580a0c07e983d9b0-image.png)

## acc_CR

- 最后一层计算公式不同区分

- 基于bubble_time，5min一个时间片，cr曲线表示真实的cr，avg_predicr曲线表示改时间片预测cr的平均值

【1-exp(-x)】

![](92704656b407d6e6-image.png)

【sigmoid】

![](240497e527b04542-image.png)

【不同计算公式放到一起】

cr和cr2分别对应「1-exp(-x)」和「sigmoid」图中的cr，两者重合，符合预期

avg_predict：「sigmoid」图中预测cr的均值

avg_predict2：「1-exp(-x)」图中预测cr的均值

![](9de37aa03b5f02ee-image.png)

- 「sigmoid」函数预测结果相较于「1-exp(-x)」更加贴合真实cr

- 两种函数的预测cr都偏低
