---
title: "来源摘要：Luban开发机使用指南"
type: source
raw_file: Luban开发机使用指南.md
tags: [Luban, 开发环境, GPU, PySpark, 深度学习]
created: 2026-05-29
updated: 2026-05-29
---

# 来源摘要：Luban 开发机使用指南

> 原文：[[花小猪/平台工具知识库/raw/Luban开发机使用指南.md]]

## 元信息

- **作者**：duruihuan, wuxiaojing, pengkan
- **类型**：团队内部开发指南
- **篇幅**：长文，纯文本格式
- **覆盖范围**：从环境申请到模型训练的完整开发流程

## 核心内容

### 为什么用 Luban（第1章）
- 对比普通开发机：Git✅、资源独享✅、自定义镜像✅、GPU✅、调度✅、Serving✅

### 快速开始（第2章）
- 入口：https://ml.intra.xiaojukeji.com/axe#/k8sinstancemgr
- 推荐镜像：`tf_conda_hadoop_git_torch_gpu_public`
- Jupyter Lab 配置（端口 8000-8100）

### Hadoop/Hive 访问（第3章）
- 镜像已配好内蒙古集群
- 直接 `hive` 命令进入
- ⚠️ 慎用 delete/mv 命令

### PySpark 任务（第4章）
- 三种模式：交互式/client/cluster
- 队列：`root.kflower_strategy_prod`
- 需要 conda activate python3.7

### 深度模型训练（第5章）
- 直接读 HDFS 数据训练（tf.data.TextLineDataset）
- TFRecord 加速训练
- GPU PyTorch：需用 pip 安装匹配 CUDA 版本
- TensorBoard 使用

### VSCode 远程开发（第6章）
- 推荐 VSCode 1.85-1.98 版本
- SSH 端口 8022，D盾码+密码登录
- Python 环境推荐 conda python3.7
- Git 配置和 SSH Key

### 常见问题
- 无资源 → 换区域/联系管理员
- OOM → 管理界面查监控
- 无 GPU → 离线任务训练
- Hadoop 账号：`prod_kflower_strategy`

## 更新了以下 Wiki 页面

- [[花小猪/平台工具知识库/wiki/entities/Luban]] — 主体内容
- [[花小猪/平台工具知识库/wiki/concepts/模型训练]] — Luban 脚本训练部分
- [[花小猪/平台工具知识库/wiki/entities/Spark]] — PySpark 提交方式

## 未完全提取的细节

- conda 完整包列表（numpy/pandas/sklearn/torch 等 30+ 包）
- 离线安装 VSCode 插件/conda library 的方法
- 自定义镜像分享流程
- kuma/uforge 内部库的安装方式
