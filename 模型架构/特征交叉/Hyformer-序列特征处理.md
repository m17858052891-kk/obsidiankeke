传统工业界的 CTR 模型通常是“两段式”：先用 DIN/Transformer 处理长序列得到几个池化向量，然后再和用户画像、环境特征一起扔进 MLP 或交叉网络中。这种“先各自为战，最后在顶层强行缝合”的做法，会导致细粒度特征交叉的严重信息丢失。

**HyFormer (Hybrid Transformer)** 的核心哲学是：**双向互通，层级交织 (Bidirectional, Layer-wise Interaction)**。它通过不断重复叠加 **HyFormer Block**，让序列信息和非序列（静态）特征在模型的每一层都发生深度纠缠。

我们以一个标准的 **HyFormer Block** 为例，深度拆解它的运作流程。

# 阶段零：Token 的世界观 (The Global Interface)

在进入 Block 之前，HyFormer 定义了整个宇宙由三种 Token 组成：

1. **NS Tokens (Non-Sequential Tokens)：** 用户的静态画像、上下文特征、候选商品特征等。
2. **Sequence Tokens：** 用户长长的历史行为序列（已被 Embedding 并带上了位置/时间编码）。
3. **Global Query Tokens：** 贯穿整个架构的核心枢纽，作为序列特征和非序列特征交流的媒介。

# 阶段一：Query Generator

在进行 Attention 之前，我们需要生成强大的“探照灯 (Query)”，用来去茫茫长序列里打捞有用的历史信息。

1. **基础底色注入 (Flatten NS Tokens)：** 将所有静态的 NS Tokens（比如“用户是 20 岁女性”、“候选商品是口红”）展平成一个长向量。这赋予了 Query **极其明确的目标和背景上下文**。
2. **全局历史概览 (Sequence Pooling)：** 分别提取当前历史行为序列的全局统计信息（如 Masked Mean Pool, Time-Decay Pool, Cross-Domain Pool），得到几个代表大盘状态的宏观向量。
3. **生成独立 Query (Latent-query Generation)：** 将（1）和（2）拼接起来，送入相互独立的 FFN（前馈神经网络）中。

    $$Q^{(1)}, Q^{(2)} = \text{FFN}(\text{Concat}(\text{NS\_flat}, \text{Pool}(H_{seq})))$$

    **物理意义：** 这两个 Query 就像是带着不同任务的侦探。侦探 A 带着“当前商品是口红，且用户最近爱买美妆”的线索；侦探 B 带着“当前用户是女性，且最近消费频次极高”的线索，准备出发去翻阅历史档案。

# 阶段二：Query Decoding (目标检索与过滤 - Transformer 的主场)

这个模块主要解决“在超长序列中找重点”的问题。

1. **角色分配：**
    - **Query (Q)：** 阶段一锻造出来的 Global Query Tokens。
    - **Key (K) / Value (V)：** 用户的超长历史行为序列 ($H_{seq}$)。
2. **Cross-Attention (靶向打捞)：** 让 Query 去和序列中的每一个 Token 进行相似度计算（内积）。

    $$\text{Decoded\_Queries} = \text{Softmax}\left(\frac{Q K^T}{\sqrt{d}}\right) V$$

    **物理意义：** 如果序列中有“防晒霜”、“眉笔”这样的历史记录，它们和 Query 的相似度极高，其特征就会被大量提取、浓缩进入 `Decoded_Queries` 中；而诸如“显卡”、“纯净水”等无关历史的权重趋近于 0，被直接过滤。

3. **阶段性产出：** 此时，原本长达上万的序列，已经被极限浓缩成了几个包含目标强相关意图的稠密向量 (`Decoded_Queries`)。

# 阶段三：Query Boosting (横纵暴力交叉 - RankMixer 的主场)

光找出来还不够，提取出的历史意图（Decoded Queries）必须和用户的当下特征（NS Tokens）发生剧烈的化学反应，才能预测出最终的点击率。

1. **大拼盘 (Token Aggregation)：** 将刚刚提炼出的 `Decoded_Queries`，与原始的静态 `NS Tokens` 拼接到一起。
2. **RankMixer 登场 (Token Mixing)：** 传统的 Transformer 在这一步依然会用 Self-Attention，但代价太高且没有必要。HyFormer 引入了基于 MLP-Mixer 思想的 RankMixer 结构。
    - **横向交叉 (Token-Mixing / Spatial Interaction)：** 跨越不同 Token 寻找关系（比如“提取出的美妆意图”与“女性画像”的交叉）。
    - **纵向交叉 (Channel-Mixing / Feature Interaction)：** 在每个特征维度内部进行深度的非线性变换。
3. **阶段性产出：** RankMixer 利用极其高效的全连接矩阵乘法，完成了历史动态意图和当下静态属性的深度融合，并输出强化后的 Queries。

# 宏观视角：为什么要“叠塔”？

以上就是**一个** HyFormer Block 的完整流程。 HyFormer 的强大在于，它会把阶段三输出的融合特征，作为**新的 Query**，再次送入**下一个** HyFormer Block 的阶段二（Query Decoding）中，去和深一层的序列特征进行新一轮的 Attention 检索。

这种**层层递进、交替纠缠**的设计，彻底打破了长序列和异构特征的壁垒，让两者在网络的每一层都能双向流动，最终产出无与伦比的排序表达能力。
