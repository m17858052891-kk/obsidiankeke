# 因果推断：Uplift 面试阅读路线

## 1. 先建立任务与评估

1. [[传统Uplift估计、策略学习与OPE]]：ATE/CATE、S/T/X/DR Learner、Causal Forest 与策略离线评估；
2. [[因果推断 Uplift 评估指标深度解析：AUUC, Qini 与 AUCC]]；
3. [[qini score选择]]：高方差指标怎样稳健选模型；
4. [[发券场景的选择偏差与推荐场景的偏差--本质区别与去偏核心差异]]：为什么发券不是普通 CTR 排序。

## 2. 再理解表征学习模型

1. [[深度解析 CFR：反事实回归 (Counterfactual Regression)]]；
2. [[DR-CFR：解耦表征反事实回归]]；
3. [[EFIN详解：联动CFR与DR-CFR理解]]。

## 3. 最后回到项目落地

- [[CFR 与 DR-CFR 的对比分析及多干预场景下的模型抉择]]；
- ECR 目录中的 [[模型搭建思路逐字稿]] 与 [[../ecr/rankloss]]。

## 面试口径

先说明 estimand（要排序的是增量，而不是响应），再讲可识别性假设、模型结构、离线评估方差与线上约束。不要把 attention、IPM 或高 AUCC 直接表述为“因果已经被证明”。
