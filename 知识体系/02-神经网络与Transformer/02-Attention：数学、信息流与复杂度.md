---
type: 知识
topics: [Transformer, 序列建模, LLM]
aliases: [Attention原理, 注意力模型, 多头注意力]
---

# Attention：数学、信息流与复杂度

Attention 可以看成一个内容依赖的读取操作：Query 指定当前要找什么，Key 用于匹配，Value 提供被读出的信息。真正决定能力的，是这些向量怎样生成、哪些位置允许相互读取，以及输出随后怎样变换。

## 1. 从形状推导一次读取

设查询输入为 $X_q\in\mathbb R^{B\times L_q\times d}$，被查询输入为 $X_k\in\mathbb R^{B\times L_k\times d}$。单头映射得到：

$$
Q=X_qW_Q,\quad K=X_kW_K,\quad V=X_kW_V,
$$

其中 $Q$ 的最后一维为 $d_k$，$K$ 同样为 $d_k$，$V$ 的最后一维为 $d_v$。忽略 batch 维：

$$
S=\frac{QK^\top}{\sqrt{d_k}}+M
\in\mathbb R^{L_q\times L_k},\qquad
A=\operatorname{softmax}_{\text{key}}(S),\qquad
O=AV\in\mathbb R^{L_q\times d_v}.
$$

Softmax 沿 key 维归一化，所以每一个 query 都有自己的一组读取权重。原始缩放点积 Attention 的定义见 [Transformer 原论文](https://arxiv.org/abs/1706.03762)。

若某一行权重为 $(0.7,0.2,0.1)$，Value 为 $(2,8,5)$，输出就是 $3.5$。匹配依据来自 Key，但混合的是 Value；把 Q/K/V 都理解成同一个 embedding，会丢掉“匹配什么”和“读出什么”的区别。

## 2. 为什么是 $\sqrt{d_k}$

设 $q_i,k_i$ 各自零均值、单位方差，各维及两向量近似独立。则：

$$
\operatorname{Var}(q^\top k)
=\operatorname{Var}\left(\sum_{i=1}^{d_k}q_ik_i\right)
\approx d_k.
$$

除以 $\sqrt{d_k}$ 后，打分方差近似保持常数。它针对的是维度增加时 logit 尺度的增长，不是在证明所有训练时刻点积都服从标准正态。

Softmax 的导数为 $\partial a_i/\partial s_j=a_i(\delta_{ij}-a_j)$。打分差异过大时，一个位置的权重接近 1，其余接近 0，许多导数会变小。缩放有助于缓解早期饱和，但不能单独保证训练稳定。

QK-Norm、可学习温度和余弦 Attention 是不同的尺度设计，是否仍保留维度缩放要看具体定义。**Llama 3 的子层前 RMSNorm 不等于分别对投影后的 Q/K 做 QK-Norm**；其官方 Attention 仍除以 head dimension 的平方根。[官方代码](https://github.com/meta-llama/llama3/blob/main/llama/model.py)

## 3. Self、Cross 和 Causal 描述不同维度

- Self-Attention：Q/K/V 来自同一组 token 的不同映射。
- Cross-Attention：Q 与 K/V 来自不同信息源，例如目标 query 读取行为序列。
- Causal Attention：通过 mask 限制可读取的依赖方向，可与前两者组合。

在自回归序列中，位置 $i$ 不能读取未来位置 $j>i$，相应 $M_{ij}=-\infty$。Padding mask 则屏蔽补齐位置，两者目的不同。某 query 的所有 key 都被屏蔽时，朴素 Softmax 可能产生未定义结果，不能把“全是负无穷”理解成天然输出全零。

因果 mask 中的“因果”是信息流顺序，不是统计因果推断中的干预识别。它防止未来 token 泄漏，不会自动解决混杂。

## 4. 多头不是把同一个结果复制几份

每个头在自己的投影空间执行 Attention，再拼接并经 $W_O$ 混合：

$$
\operatorname{MHA}(X)=\operatorname{Concat}(O_1,\ldots,O_H)W_O.
$$

固定总 hidden dimension $d=Hd_h$ 时，增加头数会缩小每头宽度；不是免费增加容量。不同头可能学习不同关系，但不能保证某一头稳定对应某个可解释语法功能。

MQA 让多个 Query 头共享一套 K/V；GQA 在 Query 头与 K/V 头之间按组共享。其重要收益来自减少自回归推理的 KV Cache 体积和读取量，而非直接消除所有 Attention 计算。[GQA 原论文](https://arxiv.org/abs/2305.13245)

## 5. “可并行”究竟发生在哪一步

教师强制训练时，完整训练序列已经给定，各位置可以在同一次前向中并行计算预测，只需 causal mask 阻止读取不应看到的 token。

生成时，位置 $t+1$ 的输入 token 通常需要先从位置 $t$ 的分布中选出。普通自回归生成因此仍有跨步依赖。单步内部的矩阵计算可以并行，不等于整段生成没有顺序依赖。

KV Cache 复用历史 token 的 K/V，避免每步重算整个前缀；它通常仍要让新 query 读取历史 cache。是否可以跨请求复用，还取决于前缀、参数、位置和 mask 是否一致，见 [[知识体系/03-LLM/03-推理：KVCache、FlashAttention与解码|LLM推理机制]]。

## 6. 复杂度要把不同部分分别计数

标准 self-attention 在 $L$ 个 token、总宽度 $d$ 下，Q/K/V 与输出投影约为 $O(BLd^2)$；点积和加权求和约为 $O(BL^2d)$。朴素实现保存的注意力权重规模约为 $O(BHL^2)$。

因此“Transformer 是 $O(L^2)$”省略了宽度、投影、FFN 和具体计算阶段。短序列、大宽度下，线性层可能占主要计算；长序列时二次项更突出。

FlashAttention 的核心收益是分块计算和减少显存读写，避免完整物化注意力矩阵；标准稠密版本仍计算相应的全量注意力关系，不应把它写成“将精确稠密 Attention 的算术复杂度变成线性”。[FlashAttention 原论文](https://arxiv.org/abs/2205.14135)

## 7. 从 Attention 到一个模型，还缺什么

只有内容依赖混合，并不自动有完整序列模型。位置机制让不同位置被区分；FFN 对每个位置做非线性特征变换；残差和归一化影响深层优化；训练目标决定模型需要保留哪些信息。

你已有 DIN、HyFormer、OneTrans 恰好提供三种信息流比较：候选 query 读取历史、短 query 与序列交互、序列和静态 token 在统一堆叠内交互。比较时先画“谁能读谁”，再比较层数和指标。

## 8. 自检与解析

**为什么 attention weight 不等于某输入对输出的完整因果贡献？**输出还取决于 Value、后续投影、残差与其他层；改变输入会同时改变多个路径，权重只是当前前向的一部分。

**如果 K 相同但 V 不同，会怎样？**相同 query 对这些位置的内容打分相同，但混合输出仍受各自 V 影响；位置与 mask 也可能打破权重相同。

**增加头数一定更慢吗？**总宽度固定时部分理论 FLOPs 接近，但矩阵形状、内存访问和 kernel 利用率会改变，实际耗时不能只由头数判断。
