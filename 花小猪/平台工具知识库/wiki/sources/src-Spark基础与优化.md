---
title: "来源摘要：Spark基础与优化指南"
type: source
raw_file: Spark基础与优化指南.md
tags: [Spark, YARN, HDFS, 优化, 分布式]
created: 2026-05-29
updated: 2026-05-29
---

# 来源摘要：Spark 基础与优化指南

> 原文：[[花小猪/平台工具知识库/raw/Spark基础与优化指南.md]]

## 元信息

- **类型**：团队内部技术学习文档
- **篇幅**：大文件（仅读取前 50 行，后续内容待补充）
- **覆盖范围**：Spark 原理、YARN 架构、运行模式、优化技巧

## 已提取内容

### Spark 背景（第1章）
- 2010 UC Berkeley AMP 实验室开发，2014 Apache 顶级项目
- 比 Memory-based Hadoop MR 快 100x，Disk-based 快 10x
- 竞争者：Flink（流式毫秒级）、TensorFlow（深度模型效率）

### 基本架构（第2章）
- 运行在 YARN 集群上
- 角色：Driver/Executor/Worker Node/Task
- 工作流程：用户提交 → Driver 启动 → 申请资源 → 分发代码 → 执行 Task → 回收结果

### YARN（2.1）
- ResourceManager / ApplicationMaster / NodeManager / Container
- 完整提交流程图

### HDFS（2.2）
- Hadoop 分布式文件系统

### 运行模式（2.3）
- yarn-client：driver 本地，executor 集群（调试用）
- yarn-cluster：全在集群（生产用）
- spark-shell：交互式

### PySpark vs ScalaSpark（2.4）
- 绝大多数情况下速度一致

## 更新了以下 Wiki 页面

- [[花小猪/平台工具知识库/wiki/entities/Spark]] — 架构、运行模式、竞争对手

## 待补充

- 文件后半部分可能包含 Spark 优化技巧（shuffle/partition/cache 等）
- 需要后续分段读取补充
