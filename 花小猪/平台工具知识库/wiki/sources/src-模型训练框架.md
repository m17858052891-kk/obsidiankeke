---
title: "来源摘要：模型训练框架介绍"
type: source
raw_file: 模型训练框架介绍.md
tags: [深度学习, 训练框架, PyTorch, ONNX, 多任务]
created: 2026-05-29
updated: 2026-05-29
---

# 来源摘要：模型训练框架介绍

> 原文：[[花小猪/平台工具知识库/raw/模型训练框架介绍.md]]

## 元信息

- **类型**：团队内部技术文档
- **篇幅**：单行长文（无换行），纯文本
- **覆盖范围**：团队自研深度模型训练框架的完整架构

## 核心内容

### 框架定位
- 团队内部封装的通用深度学习训练框架
- 运行在 EVE 平台上（花小猪实验链接）
- 核心改动：兼容多任务模型、训练可视化、模型管理

### 架构分层

| 层 | 文件 | 职责 |
|----|------|------|
| A. 配置管理 | config.yaml, config.py | 超参/模型选择/归一化参数 |
| B. 数据层 | main.py, utils.py | 归一化参数计算（E_MAX/C_BASE 等） |
| C. 模型层 | models/ | 工厂模式，DCN/MMOE/双塔等 |
| D. 训练引擎 | main.py | 多任务指标管理 + TensorBoard |
| E. 模型导出 | - | ONNX 格式，多任务适配 |
| F. 部署 | - | 对接工程 Serving |

### 关键设计
- **工厂模式**：MODEL_REGISTRY 注册表，yaml 配置动态实例化
- **多任务**：num_tasks 动态初始化指标容器，每个 Task 独立 Loss+AUC
- **归一化**：首次运行自动计算 E_MAX/E_MIN/C_BASE/C_SCALE，后续复用
- **ONNX 导出**：output_names 必须与 num_tasks 严格对应

### 使用方法
1. 编辑 config.yaml（模型名/任务数/超参/特征维度 E_NUM/C_NUM）
2. `python main.py`（首次自动计算归一化参数）
3. 自动保存最佳 model_weights.pt
4. 导出 .onnx 供工程上线

### EVE 平台上的 DAG 模块
- 原数据 → 通用算子 → 特征选取 → 数据拆分 → 模型训练 → 模型导出
- 特征选取中：稀疏特征排在数值特征前面（对应 E_NUM 和 C_NUM）

## 更新了以下 Wiki 页面

- [[花小猪/平台工具知识库/wiki/concepts/模型训练]] — 深度模型训练框架部分

## 未完全提取的细节

- model.py 中 Model class 的具体接口定义
- compute_loss 的实现约定
- training_recorder.csv 格式
- 模型导出的版本管理规范
- 工程侧对模型输出格式的要求链接
