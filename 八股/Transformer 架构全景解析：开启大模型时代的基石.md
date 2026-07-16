自 2017 年 Google 发表著名论文《Attention Is All You Need》以来，Transformer 彻底改变了自然语言处理（NLP）乃至整个深度学习领域的格局。它证明了：**不需要卷积（CNN）或循环神经网络（RNN），仅靠注意力机制（Attention）就能实现顶级的序列建模效果。**

理解 Transformer，不仅是理解 ChatGPT 等大模型的必经之路，也是理解如今各类线性注意力、门控网络（如 HSTU）为何要进化的基础。

## 目录

- [2.1 自注意力机制（Self-Attention）—— 模型的灵魂](#21-自注意力机制self-attention-模型的灵魂)
- [2.2 多头注意力（Multi-Head Attention）—— 并行而非串行](#22-多头注意力multi-head-attention-并行而非串行)
- [2.3 位置编码（Positional Encoding）](#23-位置编码positional-encoding)
- [2.4 前馈神经网络（Feed-Forward Network, FFN）](#24-前馈神经网络feed-forward-network-ffn)
- [2.5 残差连接与层归一化（Add & Norm）](#25-残差连接与层归一化add-norm)

# 1. 核心突破：摒弃时序枷锁，拥抱完全并行计算

在 Transformer 出现之前，处理序列数据（如文本、时间序列）的主流是 RNN/LSTM。

- **RNN 的痛点：** 必须按顺序逐个 Token 处理，导致**无法并行计算**；且在长序列中容易出现**信息遗忘和梯度消失**。
- **Transformer 的破局：** 完全抛弃了时序递归结构。它将序列中所有的 Token 同时“铺开”，打破了距离限制，极大释放了 GPU 的并行计算能力。

# 2. 核心组件拆解与工程内幕

Transformer 内部由多个堆叠的 Block 组成，以下是核心组件及其实际工程落地的细节：

## 2.1 自注意力机制（Self-Attention）—— 模型的灵魂

这是提取特征的核心方式，模型会动态计算当前词与序列中其他所有词的相关性。核心公式为：

$$\text{Attention}(Q, K, V) = \text{Softmax}\left(\frac{QK^T}{\sqrt{d_k}}\right)V$$

**💡 工程实现暗门 1：Softmax 防溢出技巧 (Safe Softmax)** 在代码实现中，直接计算 $e^{x_i}$ 极其危险。如果 $QK^T$ 的某一项打分是 100，$e^{100}$ 会导致计算机数值溢出直接报错 `NaN`。 真实的工程实现会**减去当前行的最大值**：

$$\text{Softmax}(x_i) = \frac{e^{x_i - \max(x)}}{\sum_j e^{x_j - \max(x)}}$$

这样最大的指数项变成了 $e^0 = 1$，完美避免了向上溢出，且由于分子分母同乘了一个常数，数学上结果完全等价。

**💡 工程实现暗门 2：如果不除以** $\sqrt{d_k}$ **怎么办？** 除以 $\sqrt{d_k}$ 的初衷是防止点积数值过大导致 Softmax 进入“梯度消失的死区”。如果不用这个缩放因子，现代模型演化出了以下替代方案：

1. **QK-Norm (Q-K Normalization)：** 比如在 Llama 3 和 ViT-22B 中，在做点积之前，先对 $Q$ 和 $K$ 分别做一次 LayerNorm 或 RMSNorm。既然数值爆炸是 $Q$ 和 $K$ 带来的，提前把它们压扁就行了。
2. **Cosine Attention (余弦注意力)：** 放弃点积运算，改用余弦相似度 $\frac{Q \cdot K}{\vert{}Q\vert{}\vert{}K\vert{}}$。这直接把相似度硬性限制在了 $[-1, 1]$ 之间，然后乘上一个可学习的温度系数 $\tau$ 去放大，极其稳定。

## 2.2 多头注意力（Multi-Head Attention）—— 并行而非串行

> **误区澄清：** 多头注意力（MHA）和自注意力**不是串行关系**。在网络结构中，它们是“包含”关系。

Transformer 并不是先做一个大 Self-Attention，再接着做 MHA。而是将高维的 $Q, K, V$ 矩阵沿着特征维度切分成多个“头”（比如 512 维切成 8 个 64 维的头），然后这 8 个头**完全并行地**各自执行一次小的 Self-Attention，最后将 8 个结果拼接（Concat）并做一次线性映射。 这赋予了模型在同一时间拥有多个视角的能力（例如有的头关注主谓宾，有的头关注时态）。

## 2.3 位置编码（Positional Encoding）

Transformer 是并行处理所有词的，它本身**没有时间先后顺序的概念**。 为了解决这个问题，模型通过正弦和余弦函数（或现代的 RoPE 旋转位置编码）在输入数据中硬性注入了位置信息，模型就“知道”了每个词的绝对和相对位置。

## 2.4 前馈神经网络（Feed-Forward Network, FFN）

$$\text{FFN}(x) = \max(0, xW_1 + b_1)W_2 + b_2$$

注意力机制只是在做 Token 之间的“信息混合”，而 FFN 则负责对混合后的信息进行独立于序列的非线性特征提取（升维再降维）。

## 2.5 残差连接与层归一化（Add & Norm）

每个子层之后都有残差连接和归一化：$\text{Output} = \text{LayerNorm}(x + \text{Sublayer}(x))$。残差连接缓解了网络加深时的梯度消失。

**💡 核心抉择：为什么 NLP 霸主是 LayerNorm (LN) 而不是 BatchNorm (BN)？**

- **BatchNorm (跨样本归一化)：** 在一个 Batch 内，对同一个特征维度求均值和方差。它在 CV（计算机视觉）里是王者，因为图片尺寸通常是固定的。但在 NLP 中，句子的长短不一（通常需要 Pad 补零），补零的无意义数据会严重污染 BN 的均值和方差计算；且受限于显存，NLP 的 Batch Size 通常很小，BN 统计量极不稳定。
- **LayerNorm (跨特征归一化)：** 它是“自己管自己”。对每一个特定的 Token（例如“苹果”这个词），计算它自身所有特征维度的均值和方差进行归一化。它**完全不需要依赖其他样本，也无视序列长短和 Batch Size 的大小**，因此成为了 Transformer 的绝佳拍档。

# 3. 宏观结构与后世流派

原始 Transformer 用于机器翻译，包含 Encoder（全览全局信息）和 Decoder（掩码防作弊，自回归生成）。

- **Encoder-only 路线：** 如 BERT，擅长阅读理解。
- **Decoder-only 路线：** 如 GPT 系列，参数量暴增后展现出涌现能力，一统天下。

# 4. 总结

原生 Transformer 确立了框架，但也因为 Softmax Attention 留下了算力爆炸和容易梯度饱和的隐患。这正是后续模型如 HSTU 引入 SiLU 门控、各类模型引入 QK-Norm 试图解决的工程和理论痛点。
