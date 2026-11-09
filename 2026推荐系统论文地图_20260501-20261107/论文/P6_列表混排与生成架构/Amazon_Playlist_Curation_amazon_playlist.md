---
title: "Amazon Playlist Curation"
paper_id: "amazon_playlist"
company: "Amazon Music"
date: "2026-09-28（会议）"
version: "官方PDF"
category: "P6_列表混排与生成架构"
scope: "会议窗口补充"
reviewed: "2026-11-07"
tags: ["推荐系统", "论文精读", "2026"]
---

> [总索引](../../00_总索引.md) · [问题地图](../../01_问题地图与选型路线.md) · [收益链路矩阵](../../02_逐篇收益链路与证伪矩阵.md) · [复核记录](../../06_逐篇复核与证据边界.md)

# Amazon Playlist Curation：用蒸馏LLM过滤不合适的歌曲

[官方页面](https://www.amazon.science/publications/llm-based-playlist-curation-a-music-reasoning-approach-at-scale)，题名 **LLM-Based Playlist Curation: A Music Reasoning Approach at Scale**，Amazon Music。[官方PDF](https://cdn.amazon.science/07/df/900083dc4a63988fec67fa69f9f0/murs-2026-llm-based-playlist-curation-camera-ready.pdf)。

**时间与层级：**PDF标MuRS 2026，2026-09-28；官方页面只写2026。可确认窗口内会议披露，尚未确认最早公开日，所以放入“会议窗口补充”，不计严格首发主集。是RecSys附属音乐推荐workshop，不能写成RecSys主会论文。

## 动机与pipeline位置

单首相关不等于整张歌单协调：相同genre也可能年代、速度、情绪不合。已有检索和排序之后的一堆人工规则难以表达多维音乐适配。

本工作作为**候选后处理quality gate**，通常从约50首预筛歌曲里去掉15–20%；不负责主题选择、全库召回，也不优化最终播放顺序。

## 方法

输入主题与每首歌的文本元数据（genre、mood、年代、声学描述、歌手背景），LLM输出保留/删除。比较逐首分类和整表subset selection后，选一次输入整表、仅输出应移除歌曲索引及局部理由。不会任意生成目录外歌曲。

教师Claude Opus 4.6给出推理与决策，学生Qwen3.5-4B用SFT蒸馏。约2万编辑歌单构造训练；逐首数据约34.3万pair，仅留教师与真值一致样本；整表约4万样本，不是所有样本都经过完全一致过滤。整表正负比5:1、负例主要随机插入，任务偏容易。

## 结果与限定

- PDF Table 2：negative-only P3 F1 0.96，输出344 tokens；全输出P1 2194 tokens，约减少84%。P7无逐首理由也达0.95，不支持“理由越长越好”。
- Table 1：8×A100环境，逐首0.34张歌单/s、整表7.5，约22倍；这是prompt和调用次数一起变化。
- Table 3：整表全参数SFT相对生产基线weighted precision +0.006%、weighted NDCG +0.092%，两种声学偏差下降；不是所有方法所有指标都更好，逐首LoRA precision为-0.004%。
- §6.5：**有限活跃用户群**、4周AB，engagement +0.06%、retention +0.03%，作者称显著。论文明确全量部署仍成本高，不能因摘要“production scale”就写成Amazon Music全量上线。
- 摘要/结论称蒸馏成本降低227倍，但未给足统一硬件/计费口径，不作为可直接复用的预算预测。

## 收益链路

**列表质量：**LLM同时读取主题与候选元数据 → 识别传统相关性分数漏掉的情绪/年代冲突 → 去掉不协调歌曲 → 减少破坏听歌体验的跳过或退出 → 可能改善参与和留存。后两步是合理机制推断；线上是quality gate整体效果，没有把每类冲突的中介贡献分开。

**部署：**只输出少数negative+学生蒸馏 → 降低token和调用成本 → 可以在部分线上场景启用更复杂判断。降本是可用条件，不自动证明推荐质量。

## 关系、最小实验与失败条件

与listwise reranker相似，但输出是子集，不是总排序；与常规ranker互补。优先尝试在业务明确的列表约束上使用，不必重建召回。

1. 固定候选与列表长度，对比旧规则、简单分类器、LLM gate；若收益来自列表变短而非更好的过滤，做随机等量删除即可暴露。
2. 用“同风格但错年代/错情绪”等hard negative替代随机负例，检验0.96是否保留。
3. 对比有/无解释、教师/学生，分别测过滤质量和成本；不能把自然语言理由当作真实决策因果解释。
4. 加入新歌和小众歌手人工盲评，防止教师知识陈旧或偏经典边界。

## double-check

- [x] 会议披露与首次公开日分开，workshop层级明确。
- [x] 有限活跃用户实验、全量成本限制均保留。
- [x] negative-only效果与蒸馏效果分开，成本口径不夸大。
- [x] 未把后处理写成端到端生成歌单。

## 本库关联阅读

[UGR](../../论文/P6_列表混排与生成架构/UGR_2610_39426.md)；[Sona](../../论文/P6_列表混排与生成架构/Sona_2608_11015.md)；[Spotify Agent](../../论文/P8_评估研发与推荐Agent/Spotify_Agent_2609_30297.md)。
