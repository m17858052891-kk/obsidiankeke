---
title: "Arbor多任务架构搜索合同"
type: model-card
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: department
source_ids:
  - "knowledge:2209771689565"
related:
  - "PEPNet与序列履约模型.md"
  - "匹配V1多任务模型.md"
---

# Arbor多任务架构搜索合同

> 这是 2026 技术探索的实验治理合同，不是当前线上模型卡。来源中的机器地址、目录和恢复命令不进入 Wiki，也不得据此访问环境。

## 固定任务与评价

- 输入合同为 727 维：167 个静态字段、20×14 司机历史、20×14 乘客历史。
- 输出为 OD、O、D 三个二分类概率，以三头 AUC 及 Mean AUC 评价。
- 训练/验证表、样本过滤、标签、mask、字段顺序、随机种子、loss 和 AUC 计算要求冻结。
- Smoke 仅验证前向、反向、loss、验证和 checkpoint 链路；只有完整验证且 `valid=true` 的结果可参与候选排序。

## 两条建模轴

任务共享解决 OD/O/D 三目标之间的共享与冲突；domain 建模解决连环派和非连环派的分布差异。候选必须说明参数共享/隔离、binary 如何控制 query、adapter、归一化、专家或输出头，不能用三任务塔替代 domain 区分。

首轮搜索优先探索新的多任务关系骨架。DCNv2、FiBiNET、WuKong 可用于静态交叉，OneTrans 类模块可处理时序，但不能只把既有模块拼接后改名。每个候选还需报告参数量、显存、训练时间、实现风险及相对已有实验新增的信息。

## 实验治理与证据边界

每个候选需独立 run-id、输出目录、checkpoint、配置、代码 commit、模型哈希和结果文件；失败写为 `valid=false`，不得覆盖或静默丢弃。来源还要求保留资源采样并清理失败或非最优 checkpoint。

原文描述的是自动搜索流程与研究约束，没有提供已完成候选、完整验证 AUC、线上 AB、推理时延或生产版本。因此不能写成“Arbor 已找到更优模型”或“已上线”。来源含 1 张未解析图片；实验环境细节、恢复命令及代理配置不作为知识页内容传播。

## 来源与关联页面

- [Arbor 探索原文](../../raw/cooper/knowledge-2209771689565.md)
- [PEPNet 与序列履约模型](PEPNet与序列履约模型.md)
- [匹配 V1 多任务模型](匹配V1多任务模型.md)
