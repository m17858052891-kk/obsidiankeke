---
tags: [模型架构, HyFormer, 序列建模, 特征交叉, PCVRHyFormer, 面试]
---

# HyFormer：序列信息与静态特征的分层条件融合

> HyFormer 的合理表述是：先保留长行为序列的细粒度 token，再由带当前候选/上下文的少量 Query 去读取历史，最后与静态 token 做交叉；重复多层后，Query 能逐步更新。它不是“所有特征在每层无差别纠缠”的万能结构。

## 1. 为什么不直接“序列池化后 concat 静态特征”？

传统两段式是：`长序列 → 一个兴趣向量 → 与用户/候选/上下文 concat → MLP`。它便宜，但池化过早时，候选商品无法再访问具体历史行为。例如用户同时有数码和美妆兴趣，单一向量很难在“候选口红”和“候选显卡”之间动态切换。

## 2. 三类输入与职责

- **Sequence Tokens**：行为历史，带行为类型、位置/时间和 padding mask；负责保存可被检索的细粒度证据。
- **NS Tokens**：用户画像、候选 item、请求上下文、统计特征；负责描述当前样本条件。
- **Query Tokens**：少量潜在兴趣槽；负责把当前条件带入历史读取，并将长序列压缩成可用于排序的表示。

## 3. 一个 Block 的概念数据流

```text
NS tokens + 序列摘要 → Query Generator → Q
Q 作为 Query，sequence tokens 作为 K/V → Cross-Attention → decoded Q
decoded Q + NS tokens → RankMixer / feature interaction → boosted Q
boosted Q 进入下一层，继续读取更高层序列表示
```

Query Generator 可以利用候选、用户和序列摘要生成多个 query；在 PCVR 516 版本中，候选感知软匹配被提前到 Query 初始化阶段，使每个 query 一开始就偏向当前候选相关的历史。

## 4. 为什么是“分层”而不是一次 Cross-Attention？

第一层通常完成粗粒度的候选相关历史读取；静态特征交叉后，Query 表示带上更充分的当前样本条件；下一层可据此再次检索或重组兴趣。多层的潜在收益是“读取—融合—再读取”，代价是参数、延迟和小数据过拟合风险。层数不是越多越好。

## 5. 与 DIN、SASRec、RankMixer 的分工

| 模块 | 主要能力 |
|---|---|
| DIN | 候选感知地加权历史，通常不强编码顺序 |
| SASRec/域内 Transformer | 建模历史内部的顺序和兴趣演化 |
| HyFormer | 用 Query 把静态条件与序列读取、后续融合交替连接 |
| RankMixer | 在短 query + 静态 token 集上做受约束的交叉 |

HyFormer 不是用 RankMixer 替代序列 Attention，也不是 DIN 的简单堆叠；它把不同模块放在不同阶段解决不同的交互问题。

## 6. 复杂度与边界

若每路长度为 $L$、Query 数为 $M$，Cross-Attention 的主项约为 $O(LMD)$，通常 $M\ll L$，比对所有 token 做全局 Self-Attention 更可控。真正端到端成本仍要加上域内 Transformer、投影、RankMixer、padding 和多域数量。

当候选无关的序列状态已足够、数据量很小、或线上延迟严格时，简单的序列编码 + DIN/MLP 可能更稳。结构收益必须由同特征、同预算消融验证。

## 7. 面试回答

> HyFormer 将长序列、静态特征和少量 Query 分工：序列 token 保留历史证据，静态 token 描述当前候选与上下文，Query 作为条件化读头。每层先用 Query 对历史做 Cross-Attention，再将读出的兴趣与静态 token 做交叉，更新后的 Query 可进入下一层继续读取。它解决的是“先池化再融合”过早丢细节的问题，但不是所有场景都比 DIN/Transformer 更好，需看数据量、序列长度和消融。
