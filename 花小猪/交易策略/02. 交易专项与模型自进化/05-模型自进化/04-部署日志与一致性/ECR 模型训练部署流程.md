---
title: "ECR 模型训练部署流程"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2208673418410
cssclasses: ["strategy-body-note"]
---

# ECR 模型训练部署流程

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2208673418410)

本文面向工程同学，讲清楚 ECR 模型从训练数据获取到线上部署的整体策略链路：每一步在做什么、上下游依赖是什么、工程侧需要理解哪些口径。

---

## 各步骤入口

| 步骤 | 说明 | 链接 / 路径 |
| --- | --- | --- |
| ① 确定样本口径 | 策略侧确定训练时间、城市、冒泡口径 | — |
| ② 数梦生成训练数据 | 按口径跑取数任务，产出训练集和测试集 | [ECR 数据生成任务](https://studio.data.didichuxing.com/batch?projectId=1143&taskId=41842225) |
| ③ 训练并选模型 | 多组超参训练，按 call mtaucc 选最优 checkpoint | [代码仓库 ](https://git.xiaojukeji.com/bwh_stg/union_stg_ecr_model)[`main/`](https://git.xiaojukeji.com/bwh_stg/union_stg_ecr_model)[ 目录](https://git.xiaojukeji.com/bwh_stg/union_stg_ecr_model) |
| ④ Eve 导出模型 | 将 checkpoint 导出为线上可调用的模型包 | [ECR 模型导出 Eve 任务](https://ether.intra.hongyibo.com.cn/labs/new/13942) |
| ⑤ 容器部署上线 | 更新模型版本和特征配置，完成上线校验 | [ECR 容器部署](https://ether.intra.hongyibo.com.cn/commonWrapperDeployV3/detail/1282) |

---

## 整体链路

ECR 模型用于预估冒泡 → 呼叫的转化效果，供联合决策在不同折扣、不同默勾方案之间做选择。完整流程分为五步：

```mermaid
flowchart LR
    A["① 确定样本口径"] --> B["② 数梦生成训练数据"]
    B --> C["③ 训练并选模型"]
    C --> D["④ Eve 导出模型"]
    D --> E["⑤ 容器部署上线"]
```

贯穿全链路有一个核心约束：**训练时的特征输入、Eve 导出时的特征配置、线上容器取到的特征，三者必须完全一致**，否则模型虽然能运行，但输出含义会偏。

---

## ① 确定样本口径

策略侧确定训练样本的时间范围、城市范围和冒泡口径。

当前口径：训练样本取**去重冒泡中的最后一次冒泡**，并要求是非熔断。

这里有一个工程侧需要理解的离在线差异：

- **线上**：对每一次冒泡实时预测

- **训练**：取去重后的最后一次冒泡

两者粒度不同，是已知的设计决策，属于可接受的离在线差异。但如果线上的缓存逻辑、熔断逻辑或冒泡去重逻辑发生变化，训练数据口径需要跟着调整，否则离线训练的样本分布就不再代表线上真实情况。

---

## ② 数梦生成训练数据

取数入口：[ECR 数据生成任务](https://studio.data.didichuxing.com/batch?projectId=1143&taskId=41842225)

策略侧在数梦任务中按①确定的口径关联格子维度、P 维度的特征，产出训练集和测试集数据，供下一步使用。

---

## ③ 训练并选模型

训练在本地工程中完成，入口是 `trainer.py`。

训练时会跑多组超参，每组训练多个 epoch 并保存 checkpoint。训练结束后不直接看训练 loss，而是跑离线评估脚本选模型，当前主要参考的指标是 `call mtaucc` 和 `ate error`，衡量模型对呼叫转化提升的排序能力。选出最优 checkpoint 后，该文件路径作为下一步 Eve 导出的输入。

---

## ④ Eve 导出模型

训练得到的 checkpoint 不能直接上线，需要通过 Eve 任务导出为线上可调用的模型包。

导出入口：[ECR 模型导出 Eve 任务](https://ether.intra.hongyibo.com.cn/labs/new/13942)

导出时做三件事：在 Eve 任务中配置线上预测需要的特征、上传最优模型文件、确认模型加载路径正确。

这里是全链路中风险最集中的环节。以下两项如果和训练侧不一致，模型能跑但输出会偏：

- 特征列表（与 `config` 对齐）

- 特征顺序（顺序不能依赖名称判断，需逐一比对）

---

## ⑤ 容器部署上线

导出完成后，在容器部署平台更新线上版本。

部署入口：[ECR 容器部署](https://ether.intra.hongyibo.com.cn/commonWrapperDeployV3/detail/1282)

部署时改两类配置：模型版本（指向本次 Eve 导出的模型）、特征离在线映射配置（保证线上取到的特征和离线训练、导出时使用的一致）。

上线后建议做一次一致性校验：取同一批样本，用离线模型和线上容器分别预测，对比输入特征值、模型输出分数和容器返回的版本号。如果分数有系统性偏差，优先排查特征顺序和默认值。

---

## 工程侧重点关注

理解这条链路后，工程同学主要盯四件事：

1. **样本口径**：训练取"去重冒泡最后一次冒泡"，线上缓存/熔断逻辑变化时要同步调整。

2. **特征一致性**：训练 config → Eve 导出 → 线上配置，三处特征列表和顺序必须一致。

3. **模型版本对应**：checkpoint → Eve 导出产物 → 容器部署版本，三者需能对应上。

4. **离在线校验**：每次上线后验证离线和线上预测结果一致。
