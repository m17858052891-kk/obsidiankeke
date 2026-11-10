---
title: EVE 策略算法平台
type: entity
tags: [平台, 模型训练, 模型部署, 特征管理, 策略管理]
sources: [策略算法平台EVE介绍.md, EVE使用手册-新手简化版.md]
created: 2026-05-29
updated: 2026-05-29
---

# EVE 策略算法平台

> EVE 读作"伊娃"，取自电影《机器人总动员 WALL-E》中女主角机器人的名字。

## 定位

滴滴自研的**一站式业务策略算法中台**，覆盖策略迭代的各个生命周期：特征加工/管理/上线 → 模型训练/管理/部署 → 实验 AB 分流/策略构建/效果评估。由策略中台 FT 负责维护。

## 平台地址

- 国内：https://ether.intra.xiaojukeji.com/
- 美东：https://ether.intra.didiglobal.com/
- 花小猪：http://ether.intra.hongyibo.com.cn/

## 核心能力

### 特征中心

> 注意：特征中心与 [[花小猪/平台工具知识库/wiki/entities/DUFE]] 是不同团队自建，一般一个算法团队只使用其中一个。

- **训练样本生成**：配置化支持样本提取任务
- **特征生产**：特征的加工、存储、推送
- **特征访问**：根据模型访问所有依赖特征

### 模型中心

- **模型开发 Pipeline**：可视化 DAG 编排（组件库 + 连线 + 调度）
- **模型仓库**：管理模型文件、版本、依赖特征、算子配置、评估信息
- **在线推理**：深度/非深度模型推理服务

### 策略中心

解决工程与算法协作问题，让算法 RD 可以自行变更在线策略而无需提需求给工程 RD。

### 流量管理

基于 Google 层域流量模型，提供流量管理，集成 [[花小猪/平台工具知识库/wiki/entities/Apollo]] 实验能力。

## 模型训练流程

详见 [[花小猪/平台工具知识库/wiki/concepts/模型训练]]

1. 配置数梦信息 → 准备数据 → 创建实验 → 构建 DAG → 运行并查看结果
2. 数据来源：个人数据 / 公共数据 / 业务数据（Hive 表）
3. 支持框架：XGBoost、SparkML、TensorFlow（SavedModel）、PyTorch（TorchScript）

## 模型部署

详见 [[花小猪/平台工具知识库/wiki/workflows/模型部署上线流程]]

三种部署方式：
| 部署方式 | 适用场景 |
|---------|---------|
| 集群部署 (model) | 非深度模型 |
| 集群部署 (dl115) | tf2.0 模型 |
| 容器部署 | 深度模型（推荐） |

部署流程：创建服务 → 特征映射 → 部署预发 → 审核（首次）→ 部署上线 → 切流

## 模型定期更新

详见 [[花小猪/平台工具知识库/wiki/concepts/模型定期更新]]

非增量训练：相同建模参数 + 最新数据 → 训练 → 导出 → 评估检查 → 部署上线

## 模型日志采集

- 注册 publickey → 填写 Odin 节点信息 → 创建同步任务
- hne 集群：业务线选 kflower，节点 `access.ether.public.gs.engine.kflower.didi.com`
- hna 集群：业务线选专快车，节点 `access.ether.public.engine.didi.com`

## 服务调用

- **eve-sdk**：推荐方式
- **thrift 调用**：需提供 model_name，按城市指定 version

## 底层依赖

- [[花小猪/平台工具知识库/wiki/entities/数梦]]：离线数据处理与调度
- [[花小猪/平台工具知识库/wiki/entities/Spark]]：计算引擎
- [[花小猪/平台工具知识库/wiki/entities/Luban]]：深度模型训练（TF/PyTorch）
- [[花小猪/平台工具知识库/wiki/entities/Apollo]]：实验分流与评估

## 相关文档

- [使用手册](https://cooper.didichuxing.com/knowledge/share/book/M2p5gqFoY7Ej/2199723608921)
- [常见报错汇总](https://cooper.didichuxing.com/knowledge/share/book/M2p5gqFoY7Ej/2199907944330)
- [EVE-SDK 文档](https://cooper.didichuxing.com/knowledge/share/book/M2p5gqFoY7Ej/2199992381220)
