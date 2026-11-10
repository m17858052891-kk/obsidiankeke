---
title: "来源摘要：kflower_strategy周期性任务指南"
type: source
raw_file: kflower_strategy周期性任务指南.md
tags: [周期性任务, 数梦, DUFE, kflower, 离线特征]
created: 2026-05-29
updated: 2026-05-29
---

# 来源摘要：kflower_strategy 周期性任务指南

> 原文：[[花小猪/平台工具知识库/raw/kflower_strategy周期性任务指南.md]]

## 元信息

- **类型**：团队操作指南（含大量截图，文件 8.6MB）
- **覆盖范围**：从数梦任务准备到 DUFE 特征上线的完整流程
- **团队**：kflower_strategy（霸王花交易定价）

## 核心内容

### 第1步：数梦周期性任务准备
- 项目空间：https://studio.data.didichuxing.com/?projectId=1143
- 流程：写 SQL → 注释写表测试 → 发布 → review → 冒烟
- 需申请 HDFS 权限（PAM 平台）

### 第2步：DUFE 离线特征生产
- 入口：https://dufe-v2.intra.xiaojukeji.com/new-task
- 基本信息配置（告警组 kflower_dups_dict）
- 任务配置：Dict 集群 + 数梦项目 kflower_marketplace + Spark 参数 + SQL
- SQL 示例：kflower_strategy.city_avg_eda 表
- 特征命名前缀规则
- 主键唯一性要求
- 依赖 tag + 偏移量
- 质检：行数 + 空值率

### 第3步：工单流转
- 预览 → 特征信息填写 → 两层审批（直属+管理员）→ 上线
- 等待 Fastload 完成

### 补充说明
- 9 条预设基线（L2/L7/L8 × 保障5/9/15 点）
- 定时切换逻辑（超过 cron_time 立即切换）

## 更新了以下 Wiki 页面

- [[花小猪/平台工具知识库/wiki/workflows/周期性任务配置流程]] — 完整操作流程

## 与其他来源的关系

- 与 [[花小猪/平台工具知识库/raw/离线特征生产.md]] 内容高度重叠
- 本文更偏 kflower 团队实操视角（含团队项目 ID、示例表名）
- 离线特征生产文档更偏平台通用视角
- 两者互为补充，wiki 流程页已整合两者信息
