---
title: "Joint Null-Space Projection for Data-Free Model Merging"
aliases: ["JNSP"]
first_author: "Tian Xia"
arxiv_id: "2611.17103"
arxiv_version: "v1"
first_submitted: "2026-11-12"
weekly_first_featured: "2026-11-16"
source_url: "https://arxiv.org/html/2611.17103v1"
---

# 合并多个任务模型时，去掉冲突方向会连同有用信号一起删掉吗？

<!-- 全库方法复筛开始 -->
> **方法储备 · 模型自进化**。保留“合并多个任务模型时，去掉冲突方向会连同有用信号一起删掉吗？”这一研究问题或机制；是否用于当前业务另行验证。
> 原有阅读范围与证据等级不变；储备不等于效果已验证。
> [[研究前沿/论文库复筛与阅读路线|全库阅读路线]] · [[研究前沿/模型自进化/存量论文分层索引|本方向完整分层]]
<!-- 全库方法复筛结束 -->

Joint Null-Space Projection for Data-Free Model Merging。第一作者 Tian Xia。证据取自 2026 年 11 月 12 日提交的 v1，定位为§4–6、附录表 29。[arXiv 版本记录](https://arxiv.org/abs/2611.17103v1) · [原文](https://arxiv.org/html/2611.17103v1) · [[2611.17103v1.pdf|本地 PDF]] · [作者项目](https://github.com/sumorday/JNSP)

## 方法改了什么

从同一预训练骨干的各个微调权重减去初始权重。逐矩阵找每个任务改动最强的输入方向，把它的更新投影到其他任务主要方向的正交补，再合并。这样可直接处理权重，无需见到训练样本。

## 作者验证了什么

八个 CLIP 图像分类任务的 ViT-B/16 平均准确率，JNSP 为 89.45%，TIES 为 77.57%，较强的无数据对照 WUDI 为 88.47%。改用按任务顺序逐次投影，降到 69.6%。在八个 RoBERTa-large/GLUE 任务上，JNSP 得 31.43，常规缩放的任务向量相加得 59.70。

## 适用边界与迁移判断

多个任务共享的方向也可能携带共同能力。视觉与语言上的反转限制了迁移范围。推荐多任务模型若没有同一骨干分别微调的 checkpoint，不能直接照搬该比较。

[[00_总索引与阅读路线|知识库索引]] · [[研究前沿/周报/2026-11-16|本期周报]]
