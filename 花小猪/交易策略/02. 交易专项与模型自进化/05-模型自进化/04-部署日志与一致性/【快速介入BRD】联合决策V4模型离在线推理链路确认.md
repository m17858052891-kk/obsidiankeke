---
title: "【快速介入BRD】联合决策V4模型离在线推理链路确认"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2208773012484
cssclasses: ["strategy-body-note"]
---

# 【快速介入BRD】联合决策V4模型离在线推理链路确认

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2208773012484)

| | **需求基础信息** |
| --- | --- |
| 望岳 | [https://ddp.intra.xiaojukeji.com/requirement/story/R-KF-712680?backUrl=/requirement/list?filterDirId=2200](https://ddp.intra.xiaojukeji.com/requirement/story/R-KF-712680?backUrl=/requirement/list?filterDirId=2200) |
| 需求名称 | V4模型离在线推理链路确认 |
| 需求归属部门/FT | 平台供需 |
| 对应项目 | 表单策略 |
| 需求业务owner | 陈嘉曦 |
| ==需求是否申请P0== | 否 |
| 申请P0原因 | |

## 1 需求背景

联合决策 V4 模型的输入特征将会有1500维，模型参数量膨胀10～100倍，对于线上响应速度提出了更高的要求，因此需要工程前置确认线上耗时是否能满足诉求。

同时为了验证离线仿真系统可行性，需确认工程离线过模型的方式。

## 2 需求收益

降低V4模型上线耗时风险，支持V4离线仿真系统建设

## 3 需求功能点

### 3.1 线上耗时测试

1. 调研使用EVE 通用算子组件进行空值填充的耗时问题，对比使用通用算子 vs dups自己处理空值填充的在线推理耗时

2. 测试多输入参数、大参数过模型的耗时问题

### 3.2 离线过模型验证

1. 调研工程离线调用EVE上部署的深度模型的方式。
