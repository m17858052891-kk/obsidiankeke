---
title: "Scaling Up"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2210040331626
---

# Scaling Up

推荐做 scaling 的**真命题不是"能不能加参数"，而是解一个四元约束**：参数量要涨、FLOPs 可控、延迟不涨、信息不能稀释。三轴不是三个独立旋钮，它们共享同一个代价函数：

**共同约束：延迟 ≈ FLOPs ÷（MFU × 峰值算力）**

| **轴** <br> | **到底扩什么** <br> | **核心手段** <br> | **代表工作** <br> | **代价 / 边界** <br> |
| :---: | :---: | :---: | :---: | :---: |
| **参数量** <br> | 把参数从稀疏表搬进稠密骨干，并让总参数与激活算力解耦 <br> | Per-token FFN + 零参数 token mixing · Gated FFN · Sparse MoE · 清理碎片算子 <br> | RankMixer<br>TokenMixer-Large<br>MTFM（美团） <br> | 碎片算子收益随规模归零（700M 时 DCN 增益为 0）；MoE 直接套 top-k 会路由坍缩 <br> |
| **Token 量** <br> | 行为长度 L（主战场）· 特征 token 数 T（要克制）· 辅助 token · 生成 token <br> | Token Merge · 稀疏/线性注意力 · 两阶段离线在线 · KV cache · global token <br> | LONGER<br>HSTU · GEMs<br>ULTRA-HSTU <br> | L 的收益次线性且 O(L²) 会炸延迟；cross-attention 省算力但损表示力（ULTRA-HSTU 反驳点） <br> |
| **数据量** <br> | 不是样本数，而是「有效信息 ÷ 系统偏差」；口径含天数/覆盖/域数 <br> | 去偏重建（合成数据）· 去重与 request 级优化 · 持续蒸馏与降采样 · 漂移对抗 <br> | Meta ICML 2026<br>ROO（Request-Only）<br>华为 Performance Law <br> | 有偏日志会让 scaling law 直接消失；老数据不是中性的而是有害的 <br> |


> [!abstract]- 子页面（2）
> - [验证集后验取消率分析](%E9%AA%8C%E8%AF%81%E9%9B%86%E5%90%8E%E9%AA%8C%E5%8F%96%E6%B6%88%E7%8E%87%E5%88%86%E6%9E%90.md)
> - [履约率模型方案讨论](%E5%B1%A5%E7%BA%A6%E7%8E%87%E6%A8%A1%E5%9E%8B%E6%96%B9%E6%A1%88%E8%AE%A8%E8%AE%BA.md)
