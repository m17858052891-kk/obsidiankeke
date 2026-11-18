---
title: "应答时长模型EVE训练及模型优化"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2201901343078
---

## EVE模型训练及部署

目前特快盒子及等待应答页ETA预估深度学习模型通过luban离线训练，Ether导出部署的方式进行上线。为了方便模型的后续自动化更新在当前基础上直接通过EVE进行模型训练，再进一步导出部署上线，缩减了模型更新迭代的所需人力。

模型训练链接：<https://ether.intra.hongyibo.com.cn/labs/new/12702>

## ETA模型优化

主要将模型Loss由MSE改为HuberLoss，增强了模型对离群点的鲁棒性，优化前后模型效果如下

| Metrics <br> | 优化前 <br> | 优化后 <br> |
| --- | --- | --- |
| MSE <br> | 0.783 <br> | 0.840 <br> |
| RMSE <br> | 0.885 <br> | 0.917 <br> |
| MAE <br> | 0.349 <br> | 0.309 <br> |
