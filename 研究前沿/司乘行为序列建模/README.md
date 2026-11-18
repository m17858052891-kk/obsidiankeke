---
type: 索引
status: 维护中
---

# 司乘行为序列建模

日报通用方法主线。长序列、多行为、时间编码、候选条件注意力、检索压缩、预训练和统一序列架构。每日先执行 [[研究前沿/推荐模型检索地图|推荐模型检索地图]] 中的独立方法查询，再用本页问题和业务入口补查。


历史事件、顺序和时间间隔各贡献多少？当前订单如何分别查询司机与乘客历史？序列与静态特征在哪一层交互？

固定同一批打分时已回传的事件、时间切分和模型预算，逐项比较窗口统计、无序聚合、保序编码、候选条件检索。按历史长短及供需场景检查变化。

## 先读与验证

[[论文精读/HyFormer/HyFormer：CTR中的序列建模与特征交互|HyFormer｜当前订单该怎样查询司机和乘客的历史？]]

固定同一批历史、主干和查询数，只改查询的初始化信息，对照固定查询与加入订单上下文的查询；在时间外样本上按历史长短比较 LogLoss 和分场景校准。

[[研究前沿/司乘行为序列建模/01-论文原文与精读/README|论文原文与精读]] · [[研究前沿/司乘行为序列建模/02-可复用方法卡/README|可复用方法卡]] · [[研究前沿/司乘行为序列建模/03-实验假设与结果/README|实验假设与结果]]

## 可直接执行的检索组合

### 直接相关

- `司机 乘客 行为序列 履约 预测`
- `"multi-behavior" sequence modeling ranking`
- `"target-conditioned" user behavior sequence`
- `"time-aware" sequential recommendation`

### 跨领域机制

- `"long user behavior" retrieval ranking`
- `"target attention" user behavior`
- `"unified feature interaction" sequence modeling`
- `"behavior sequence pretraining" ranking`
- `时序特征 标签回传 序列建模`

<!-- 存量复筛导航开始 -->
[[研究前沿/司乘行为序列建模/存量论文分层索引|全部存量：主读、储备、待核验]] · [[研究前沿/论文库复筛与阅读路线|跨方向阅读路线]]
<!-- 存量复筛导航结束 -->
