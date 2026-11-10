---
title: "来源摘要：策略算法平台EVE介绍"
type: source
raw_file: 策略算法平台EVE介绍.md
tags: [EVE, 模型训练, 模型部署, 特征管理]
created: 2026-05-29
updated: 2026-05-29
---

# 来源摘要：策略算法平台 EVE 介绍

> 原文：[[花小猪/平台工具知识库/raw/策略算法平台EVE介绍.md]]

## 元信息

- **类型**：内部平台使用手册（详细版，含截图）
- **篇幅**：800+ 行，大量截图
- **覆盖范围**：EVE 全功能介绍（训练、部署、定期更新、日志采集、服务调用）

## 核心内容

### 平台定位
- 滴滴自研一站式策略算法中台
- 覆盖：特征加工/管理/上线 → 模型训练/管理/部署 → AB分流/策略/评估
- 策略中台 FT 维护

### 模型训练（第2章）
- 可视化 DAG 编排（拖拽组件 + 连线）
- 数据来源：个人/公共/业务数据（Hive）
- 支持 XGBoost、SparkML
- 深度模型：TF SavedModel、PyTorch TorchScript 导入
- model.conf 配置格式（inputNames/inputShapes/featureOrder）

### 模型部署（第3章）
- 三种方式：集群(model)/集群(dl115)/容器部署
- 流程：创建服务 → 特征映射 → 预发 → 审核 → 部署 → 切流
- 特征映射四种方式：手动/自动/批量操作/JSON导入
- 容器部署优势：版本更新、资源隔离、大模型支持

### 定期更新（第5章）
- 非增量：相同参数+新数据
- Pipeline：训练→导出→评估→部署
- SQL 日期变量 `${BIZ_DATE_LINE}`
- 评估标准配置防止劣质模型上线

### 模型日志采集（第6章）
- publickey 注册 + Odin 节点配置
- hne 集群 vs hna 集群区分
- 审批人：@adamzhangcong 张聪

### 服务调用（第4章）
- eve-sdk 推荐
- thrift IDL 接口定义
- model_name + version 路由逻辑

## 更新了以下 Wiki 页面

- [[花小猪/平台工具知识库/wiki/entities/EVE]] — 主体内容
- [[花小猪/平台工具知识库/wiki/concepts/模型训练]] — 训练流程部分
- [[花小猪/平台工具知识库/wiki/concepts/模型定期更新]] — 定期更新章节
- [[花小猪/平台工具知识库/wiki/workflows/模型部署上线流程]] — 部署流程

## 未完全提取的细节

- 各组件的详细参数配置（文档指向外部链接）
- 截图中的 UI 操作细节
- thrift IDL 完整定义（仅提取了部分字段）
