---
tags: [模型架构, 特征交叉, RankMixer, MLP-Mixer, PCVRHyFormer, 面试]
---

# RankMixer：用受约束的 MLP 做 Token 与 Channel 交互

> RankMixer 的核心不是“MLP 一定比 Transformer 强”，而是在精排中 token 数量固定且不大时，用 MLP-Mixer 风格的交替混合，替代一次昂贵、内容自适应的全局 Self-Attention。它是特征交互模块，不负责替代长行为序列编码。

## 1. 它在 PCVRHyFormer 的什么位置？

```text
四域历史 → Sequence Evolution / Query Decoding → decoded queries
静态用户、候选、上下文 → NS tokens
decoded queries + NS tokens → RankMixer → 强化后的 queries → prediction head
```

因此它的输入已是较短的固定 token 集合：一部分是候选感知的动态兴趣 query，一部分是当前请求的静态 token。长序列中的时间依赖应在前面的 sequence encoder 中处理。

## 2. 输入形状与一个 Block 的数据流

令 $X\in\mathbb R^{B\times N\times D}$：$B$ 是 batch，$N$ 是 token 数，$D$ 是隐藏维度。

### Token Mixing：跨 token 交换信息

先对每个 channel 看长度为 $N$ 的 token 向量，再通过 MLP 混合：

$$X'=X+\operatorname{TokenMLP}(\operatorname{Norm}(X)^T)^T.$$

它回答的是：“候选 token、用户 token、上下文 token、兴趣 query 之间应如何固定结构地交换信息？”

### Channel Mixing：每个 token 内做非线性变换

$$Y=X'+\operatorname{ChannelMLP}(\operatorname{Norm}(X')).$$

它回答的是：“已经融合过上下文的某个 token，哪些表示维度和非线性组合应被保留？”

实际实现可以有门控、dropout、残差、Pre-LN 等变体；阅读代码时要以真实的张量 reshape、Norm 和 projection 为准。

## 3. 它和 Self-Attention 的本质区别

| | Self-Attention | RankMixer / MLP-Mixer 风格 |
|---|---|---|
| token 交互权重 | 由 $QK^T$ 随样本动态生成 | 由共享 MLP 参数产生，通常不显式做每对内容相似度 |
| 归一化 | Softmax 或其他 attention 激活 | MLP + 非线性 + 残差 |
| 优势 | 动态地选择不同 token 对 | 固定 $N$ 时实现简单、并行友好 |
| 弱点 | 成本/显存较高 | 对 token 顺序/数量敏感，动态检索能力较弱 |

因此不能说 RankMixer “没有 token 两两关系”或“必然更快”。Token Mixing 的全连接矩阵本身也常带 $N^2$ 参数/计算；它省掉的是 Q/K/V、相似度矩阵、Softmax 等机制，实际收益取决于 $N,D$、实现和硬件。

## 4. 为什么在这里可能合适？

PCVR 的 RankMixer 处理的是固定、较短的 token 集，而不是数千条原始历史。此时更重要的是让“当前候选—用户画像—请求上下文—已提炼兴趣 query”充分组合，而不是再从长序列中动态检索。受约束的 mixing 可以提供较强交叉，同时控制结构复杂度。

是否有效必须通过等参数量、等训练预算消融确认；如果任务依赖样本级动态 token 选择，Self-Attention/Cross-Attention 仍可能更合适。

## 5. 面试回答

> RankMixer 接在候选感知 query 与静态 token 融合之后，输入是短而固定的 $B\times N\times D$ token 矩阵。它交替做 Token Mixing 和 Channel Mixing：前者在 token 维交换用户、候选、上下文和兴趣信息，后者在每个 token 内做非线性变换。它不像 Self-Attention 通过 $QK^T$ 做样本自适应检索，所以不是普遍替代 Transformer；优势在于固定短 token 集上的结构与工程折中。
