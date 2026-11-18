---
title: "KuaiRecV2: Benchmarking Large-Scale Continual Learning for Diversified and Multi-task Recommendation"
aliases: ["KuaiRecV2"]
first_author: "Chenxu Li"
arxiv_id: "2611.16795"
arxiv_version: "v1"
first_submitted: "2026-11-12"
weekly_first_featured: "2026-11-16"
source_url: "https://arxiv.org/html/2611.16795v1"
---

# 新视频每天进场，今天学到的模型还记得上周吗？

<!-- 全库方法复筛开始 -->
> **近期主读 · 模型自进化**。迭代增量更新与回放机制；固定日刷新频率，对比不更新、全量微调和小比例回放，同时按新旧实体报告排序、校准与遗忘。
> 证据边界：30 天演化目录协议中，一种设置 HR@50 从首日 39.09 降至第 7 日 0.19；5% 回放为 3.20，EWC-LoRA 为 0.20。是基准特定设置，不是业务预期收益。 本地实验未运行。
> [[研究前沿/论文库复筛与阅读路线|全库阅读路线]] · [[研究前沿/模型自进化/存量论文分层索引|本方向完整分层]]
<!-- 全库方法复筛结束 -->

KuaiRecV2: Benchmarking Large-Scale Continual Learning for Diversified and Multi-task Recommendation。第一作者 Chenxu Li。证据取自 2026 年 11 月 12 日提交的 v1，定位为§2 数据和时序协议、§3 实验、表 3。[arXiv 版本记录](https://arxiv.org/abs/2611.16795v1) · [原文](https://arxiv.org/html/2611.16795v1) · [[2611.16795v1.pdf|本地 PDF]] · [作者项目](https://github.com/cxli2333/KuaiRecV2)

## 方法改了什么

把快手 30 天交互按日排序，每天使用近七天创建的视频形成动态候选池。逐日更新 checkpoint，分别测新一天的命中、首日留出的老样本、覆盖与多任务指标。固定老样本回测可观察更新过程中的遗忘。

## 作者验证了什么

表 3 追踪同一批首日验证样本。MiniOneRec 的首日 HR@50 在首日训练后为 39.09，到第七天只剩 0.19。回放 5% 历史训练样本后，第七天回测为 3.20，EWC-LoRA 为 0.20（均按原表数值）。

## 适用边界与迁移判断

这是旧样本保留能力的离线比较。老样本保留更多是否提高今天的体验，需要同时看新日命中、覆盖和实际流量。数据筛选要求窗口内至少 100 次交互，低活跃用户的结论需另测。

[[00_总索引与阅读路线|知识库索引]] · [[研究前沿/周报/2026-11-16|本期周报]]
