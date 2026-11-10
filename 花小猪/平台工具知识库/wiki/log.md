---
title: 变更日志
type: overview
created: 2026-05-29
updated: 2026-05-29
---

# 变更日志

Append-only 记录，追踪 wiki 的演进历史。

---

## [2026-05-29] init | 知识库初始化

**操作类型**：初始化

**摘要**：按照 llm-wiki.md 方法论完成知识库三层架构初始化。

**创建的文件**：
- `CLAUDE.md` — Schema 定义
- `wiki/overview.md` — 全局概览
- `wiki/index.md` — 内容索引
- `wiki/log.md` — 本文件
- `wiki/entities/EVE.md` — EVE 策略算法平台
- `wiki/entities/Luban.md` — 鲁班开发机
- `wiki/entities/DUFE.md` — 统一特征平台
- `wiki/entities/数梦.md` — 数据调度平台
- `wiki/entities/Apollo.md` — 实验平台
- `wiki/entities/Spark.md` — 大数据计算引擎
- `wiki/concepts/模型训练.md` — 模型训练概念
- `wiki/concepts/特征工程.md` — 特征工程概念
- `wiki/concepts/离线特征生产.md` — 离线特征生产
- `wiki/concepts/模型定期更新.md` — 模型定期更新
- `wiki/workflows/模型部署上线流程.md` — 部署流程
- `wiki/workflows/模型策略上线校验SOP.md` — 校验 SOP
- `wiki/workflows/离线特征生产流程.md` — 特征生产流程

**摄入的原始资料**：
- 策略算法平台EVE介绍.md
- EVE使用手册-新手简化版.md
- Luban开发机使用指南.md
- DUFE特征平台使用.md
- 离线特征生产.md
- 模型策略上线校验SOP.md
- 模型训练框架介绍.md
- Spark基础与优化指南.md

**待办**：
- [x] ~~深度摄入 kflower_strategy周期性任务指南.md~~ → 已完成（见下条）
- [ ] 摄入 Git和Gitlab使用指南.md
- [ ] 摄入 需求管理.md
- [ ] 摄入 操作介绍.md
- [ ] 摄入 根据调度时间计算周几.md

---

## [2026-05-29] ingest | kflower_strategy 周期性任务指南

**操作类型**：摄入

**摘要**：读取 `raw/kflower_strategy周期性任务指南.md`（8.6MB，含大量 base64 图片），提取纯文本内容并创建流程页。

**创建的文件**：
- `wiki/workflows/周期性任务配置流程.md` — kflower_strategy 团队完整操作指南

**更新的文件**：
- `wiki/index.md` — 新增流程页条目，更新统计
- `wiki/log.md` — 追加本记录

**关键内容**：
- kflower_strategy 项目空间（projectId=1143）周期性任务准备流程
- DUFE 离线特征生产工单填写全流程（含 SQL 示例）
- 完整的基线 ID 列表（L2/L7/L8 × 3 个时段 = 9 条基线）
- 定时切换 vs 自动切换说明
- HDFS 权限申请、管理员联系方式等运维信息

---

## [2026-05-29] ingest | 新人入职指南 + 业务术语表

**操作类型**：摄入

**摘要**：读取 `raw/新人入职指南.md` 和 `raw/业务术语表.md`，分别创建流程页和概念页，并生成对应的来源摘要。

**创建的文件**：
- `wiki/workflows/新人入职指南.md` — 入职全流程（权限+业务+平台+环境）
- `wiki/concepts/业务术语表.md` — 80+ 条交易策略术语结构化整理
- `wiki/sources/src-新人入职指南.md` — 来源摘要
- `wiki/sources/src-业务术语表.md` — 来源摘要

**更新的文件**：
- `wiki/index.md` — 新增条目、更新原始资料列表和统计
- `wiki/log.md` — 追加本记录

**关键内容**：
- 权限申请三件套：Luban (kflowerStrategyEnv) / EVE (花小猪策略+实验平台用户) / Gitlab (bwh_stg)
- 因果推断方向（潜在因果模型、DR-CFR、Uplift）+ 优化求解（贪心/分桶）
- 本机环境：Clash Verge + 内网直连域名 + Miniforge + AI Coding 工具对比
- 业务术语 80+ 条：核心指标公式、分单派单术语、定价颗粒度 OT/ODT/ODTP、订单统计口径
