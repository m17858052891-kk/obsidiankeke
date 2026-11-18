---
type: 索引
status: 维护中
---

# Scaling up 与效率

日报通用方法主线。模型、数据、序列和计算扩展，蒸馏、稀疏化、缓存及训练推理协同。每日先执行 [[研究前沿/推荐模型检索地图|推荐模型检索地图]] 中的独立方法查询，再用本页问题和业务入口补查。


分别检查训练数据量、单次可见历史长度、模型容量与计算量。记录多个规模点或明确的成本对照、固定条件、质量与延迟或显存。

同一数据切分下，一次改变一个规模轴。拉齐 FLOPs 或线上 P99 后比较质量，保留饱和与负结果；同时换训练数据、模型和系统的收益只计整套方案。

## 先读与验证

[[论文精读/OneTrans/OneTrans：统一特征交互与序列建模|OneTrans｜同样算力下，长历史值得保留到每一层吗？]]

固定训练集、输入历史长度和主干宽度，只开关逐层查询裁剪，比较完单 LogLoss、FLOPs 与推理 P99。若节约算力，再在相同预算下测试更长历史。

[[研究前沿/Scaling up 与效率/01-论文原文与精读/README|论文原文与精读]] · [[研究前沿/Scaling up 与效率/02-可复用方法卡/README|可复用方法卡]] · [[研究前沿/Scaling up 与效率/03-实验假设与结果/README|实验假设与结果]]

## 可直接执行的检索组合

### 直接相关

- `推荐模型 扩展规律 长序列 算力 延迟`
- `"scaling laws" recommendation ranking`
- `"sequence length" scaling industrial ranking`
- `"training data scaling" recommender`

### 跨领域机制

- `"compute optimal" recommendation`
- `"long sequence" retrieval compression serving latency`
- `"ranking" model scaling inference cost`
- `"sequence modeling" KV cache recommendation`

<!-- 存量复筛导航开始 -->
[[研究前沿/Scaling up 与效率/存量论文分层索引|全部存量：主读、储备、待核验]] · [[研究前沿/论文库复筛与阅读路线|跨方向阅读路线]]
<!-- 存量复筛导航结束 -->
