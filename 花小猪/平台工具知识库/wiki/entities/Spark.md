---
title: Spark 大数据计算引擎
type: entity
tags: [计算引擎, 大数据, 分布式]
sources: [Spark基础与优化指南.md]
created: 2026-05-29
updated: 2026-05-29
---

# Spark 大数据计算引擎

## 定位

Apache Spark 是分布式数据计算引擎，在滴滴内部作为离线数据处理与模型训练的核心计算框架，运行在 YARN 集群上。

## 基本架构

运行在 YARN 上，关键角色：
- **Driver**（Team Leader）：运行 SparkContext，负责资源申请、任务分配和监控
- **Executor**（Team Member）：运行 Task 的进程，core 数 = 最大并发数
- **Worker Node**（工区）：集群中可运行代码的节点
- **Task**（需求）：任务执行单元

## 运行模式

| 模式 | 说明 | 命令示例 |
|------|------|---------|
| yarn-client | Driver 在本地，Executor 在集群（调试用） | `spark-submit --deploy-mode client` |
| yarn-cluster | Driver 和 Executor 都在集群（生产用） | `spark-submit --deploy-mode cluster` |
| spark-shell | 交互式编程环境，yarn-client 模式 | `pyspark --queue=...` |

## 资源配置建议

| 数据规模 | minExecutors | maxExecutors |
|---------|--------------|--------------|
| 万条以内 | 10 | 20 |
| 千万级别 | 100 | 200 |
| 亿级以上 | 200 | 300 |

## 常用队列

- `root.kflower_strategy_prod` — kflower 策略团队生产队列

## PySpark vs ScalaSpark

绝大多数情况下运行速度一致，团队主要使用 PySpark。

## 竞争对手

- **Flink**：流式处理毫秒级延迟（Spark 只能秒级 micro-batch）
- **TensorFlow**：深度模型训练效率更高（Spark ML 需频繁 shuffle）

## 与其他平台的关系

- [[花小猪/平台工具知识库/wiki/entities/数梦]]：通过数梦提交 Spark 任务
- [[花小猪/平台工具知识库/wiki/entities/EVE]]：EVE 底层依赖 Spark 进行离线数据处理
- [[花小猪/平台工具知识库/wiki/entities/Luban]]：在 Luban 开发机上可直接提交 PySpark 任务
- [[花小猪/平台工具知识库/wiki/entities/DUFE]]：特征生产 SQL 由 Spark 执行

## 相关页面

- [[花小猪/平台工具知识库/wiki/concepts/离线特征生产]] — Spark SQL 驱动的特征计算
- [[花小猪/平台工具知识库/raw/Spark基础与优化指南.md]] — 详细优化指南
