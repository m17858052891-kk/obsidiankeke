---
title: "RecoGEM: A Serving System for Production-Scale Generative Recommendation"
aliases: ["RecoGEM"]
first_author: "Xiangrui Yang"
arxiv_id: "2611.12296"
arxiv_version: "v1"
first_submitted: "2026-11-09"
weekly_first_featured: "2026-11-16"
source_url: "https://arxiv.org/html/2611.12296v1"
---

# 每步解码的候选数不同，推理引擎能省多少时间？

<!-- 全库方法复筛开始 -->
> **方法储备 · 训练目标与数据反馈**。保留“RecoGEM: A Serving System for Production-Scale Generative Recommendation”这一研究问题或机制；是否用于当前业务另行验证。
> 原有阅读范围与证据等级不变；储备不等于效果已验证。
> [[研究前沿/论文库复筛与阅读路线|全库阅读路线]] · [[研究前沿/训练目标与数据反馈/存量论文分层索引|本方向完整分层]]
<!-- 全库方法复筛结束 -->

RecoGEM: A Serving System for Production-Scale Generative Recommendation。第一作者 Xiangrui Yang。证据取自 2026 年 11 月 9 日提交的 v1，定位为§5.1–5.3、图 15–17。[arXiv 版本记录](https://arxiv.org/abs/2611.12296v1) · [原文](https://arxiv.org/html/2611.12296v1) · [[2611.12296v1.pdf|本地 PDF]]

## 方法改了什么

将候选状态、热更新等服务职责放到运行时，执行引擎按每步的短前缀和束宽分别规划张量形状。注意力内核针对短前缀合并工作，候选选择先在每行剪枝，再做请求级 Top-K。

## 作者验证了什么

OneModel（0.2B）固定 batch=32，对照 GeneralGen 共享形状配置并使用普通内核，其余模块一致。图 16 中吞吐从 366 升到 1,053 QPS，P99 从 89.0 降至 30.8 ms。更大 OneRec-v2 同批次的吞吐比为 1.84 倍。图 17 固定专用内核，仅改成逐步规划，OneModel 平均解码耗时从 39.5 降至 30.4 ms。

## 适用边界与迁移判断

这些结果衡量服务容量与尾延迟。相同推荐模型加速后，是否把省出的资源用于更宽搜索、能否改变用户行为，是后续两项独立决策。

[[00_总索引与阅读路线|知识库索引]] · [[研究前沿/周报/2026-11-16|本期周报]]
