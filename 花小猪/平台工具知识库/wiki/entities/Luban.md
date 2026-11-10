---
title: Luban 鲁班开发机
type: entity
tags: [平台, 开发环境, 深度学习, GPU]
sources: [Luban开发机使用指南.md]
created: 2026-05-29
updated: 2026-05-29
---

# Luban 鲁班开发机

## 定位

滴滴内部的**模型平台**，提供训练资源管理、模型 Pipeline 搭建、线上 Serving 服务。相比 [[花小猪/平台工具知识库/wiki/entities/EVE]] 的拖拽式交互，Luban 更多使用脚本方式开发。

## 平台地址

- https://ml.intra.xiaojukeji.com/

## 核心优势（vs 开发机）

| 能力 | Luban | 普通开发机 |
|------|-------|----------|
| 深度学习 | ✅ | ✅ |
| Hadoop/Spark | ✅ | ✅ |
| Git | ✅ | ❌ |
| 资源独享 | ✅ | ❌ |
| 自定义镜像 | ✅ | ❌ |
| GPU | ✅ | ❌ |
| 调度 | ✅ | ❌ |
| 模型部署到线上 Serving | ✅ | ❌ |

## 快速开始

1. 进入 https://ml.intra.xiaojukeji.com/axe#/k8sinstancemgr
2. 新建实验环境，选择镜像 `tf_conda_hadoop_git_torch_gpu_public`
3. 等待状态变为 running，SSH 登录
4. 推荐使用 VSCode Remote-SSH 连接（端口 8022）

## 关键能力

### 访问 Hadoop/Hive

镜像已配好内蒙古集群访问配置，直接输入 `hive` 进入命令行。

### 提交 PySpark 任务

```bash
# 进入 conda 环境
conda activate python3.7

# 交互式
pyspark --queue=root.kflower_strategy_prod --conf spark.driver.host=<your_ip>

# Client 模式（调试用）
spark-submit --conf spark.driver.host=<your_ip> --master yarn --deploy-mode client --queue root.kflower_strategy_prod main.py

# Cluster 模式（生产用）
spark-submit --master yarn --deploy-mode cluster --queue root.kflower_strategy_prod main.py
```

### GPU 深度模型训练

- 检查 CUDA：`nvcc -V`
- PyTorch GPU 安装：需匹配 CUDA 版本，用 pip 安装（conda 默认装 CPU 版）
- TensorFlow GPU：使用 `tf.test.is_gpu_available()` 检查

### HDFS 数据直接训练

支持 `tf.data.TextLineDataset` 直接读取 HDFS，需配置环境变量：
```bash
export HADOOP_COMMON_HOME=/usr/local/hadoop-current/
export HADOOP_HDFS_HOME=/usr/local/hadoop-current/
```

## 开发环境配置

### VSCode Remote-SSH

- 推荐 VSCode 1.85-1.98 版本（centos glibc 兼容性）
- SSH 配置端口 8022，需输入 D 盾码 + 密码

### Conda 环境

推荐 Python 3.7，常用包见 [[花小猪/平台工具知识库/raw/Luban开发机使用指南.md]]

### Git 配置

```bash
git config --global user.name "dc_name"
git config --global user.email "dc_name@didiglobal.com"
ssh-keygen -o -t rsa -C "dc_name@didiglobal.com" -b 4096
```

## 常见问题

- **没有资源**：尝试不同区域/套餐，或联系管理员
- **OOM**：隔离环境内 `free` 看不到真实内存，需到管理界面查看监控
- **无 GPU 资源**：可使用离线任务训练
- **Hadoop 账号**：镜像默认使用 `prod_kflower_strategy`

## 相关页面

- [[花小猪/平台工具知识库/wiki/entities/EVE]] — 可视化训练平台
- [[花小猪/平台工具知识库/wiki/concepts/模型训练]] — 模型训练概念
- [[花小猪/平台工具知识库/wiki/entities/Spark]] — 计算引擎
