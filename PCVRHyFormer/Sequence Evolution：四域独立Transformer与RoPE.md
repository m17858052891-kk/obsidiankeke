# Sequence Evolution：四域独立 Transformer 与 RoPE

## 1. 它在整个模型中处于什么位置

一条行为经过“字段 Embedding → 同位置拼接投影 → 时间差桶相加”后，得到每域序列：

```text
seq_a: [B, L_a, 64]
seq_b: [B, L_b, 64]
seq_c: [B, L_c, 64]
seq_d: [B, L_d, 64]
```

**Sequence Evolution** 不是把四路序列压成一个向量，也不是 DIN pooling；它是在每个 HyFormer Block 的最前面，让每一路完整序列先在域内更新。输出仍然是逐位置的序列表示，随后才作为 Cross-Attention 的 K/V 被 Query 读取。

```text
带时间的 Sequence Tokens
        ↓
域内 Transformer + RoPE + padding mask
        ↓
更新后的完整序列 K/V
        ↓
Query Decoding（Query 对该域 K/V 做 Cross-Attention）
```

## 2. 为什么四个域要独立编码

四个域的字段空间、行为强度、长度和噪声分布不同。直接把它们首尾拼成一条大序列，会产生三个问题：

1. 不同行为之间的“相邻位置”未必有统一语义；
2. 高频/长序列域可能在 Self-Attention 中压制其他域；
3. 不同字段空间共用一套编码器，容易把域差异交给模型硬记忆。

因此当前实现为每个域建立独立的 TransformerEncoder 与独立的 Cross-Attention。域内先建模“该域自己的行为依赖”，跨域信息只在后面的 Query/NS Token 级 RankMixer 融合。

这是一种先分后合的结构：

```text
域内：保留各自的序列归纳偏置
域间：只在固定 16 个全局 Token 上交换证据
```

## 3. 一层 Transformer 到底做什么

当前 `seq_encoder_type=transformer` 时，每一路 Sequence Evolution 是一个 **Pre-LayerNorm Transformer Encoder**。设某域输入为：

$$
X_m^{(\ell-1)} \in \mathbb{R}^{B\times L_m\times64}
$$

先做 Self-Attention 残差：

$$
U_m^{(\ell)} = X_m^{(\ell-1)} + \operatorname{GatedMHA}(\operatorname{LN}(X_m^{(\ell-1)}))
$$

再做 FFN 残差：

$$
X_m^{(\ell)} = U_m^{(\ell)} + \operatorname{FFN}(\operatorname{LN}(U_m^{(\ell)}))
$$

其中 FFN 为：

```text
Linear(64 → 256) → GELU → Dropout → Linear(256 → 64) → Dropout
```

Pre-LN 的目的，是让残差主路径在堆叠时保持稳定；即使某层 Attention/FFN 还没学好，输入也可沿残差路径向下传递。

## 4. Self-Attention 如何在一个域内工作

对 LayerNorm 后的输入，每个位置都会生成 Q、K、V：

$$
Q=XW_Q,\qquad K=XW_K,\qquad V=XW_V
$$

再切分为多个头。若头数是 `H`，则每个 head 的维度为 `d_h=64/H`。对某个位置 `j`，Self-Attention 允许它向该域的所有有效行为位置读取信息：

$$
\operatorname{Attention}(Q,K,V)=\operatorname{softmax}\left(\frac{QK^\top}{\sqrt{d_h}}+M\right)V
$$

`M` 是 padding mask：padding 位置禁止作为 Key/Value 被读取。当前实现使用 PyTorch 的 scaled-dot-product attention；若整条序列全为 padding，注意力可能出现 NaN，代码会将该输出置零，再依靠残差保留输入，从而避免训练崩溃。

注意：这里是**域内 Self-Attention**。例如 `seq_a` 的第 10 条行为可关注 `seq_a` 的第 2、50 条行为，但不会在这一阶段直接注意 `seq_b`；跨域影响由后续 RankMixer 更新 Query 后，在下一层体现。

## 5. RoPE 如何表示顺序

时间桶已经告诉模型“行为距当前请求多久”，但它并不完整表达“行为之间的序列顺序”。RoPE（Rotary Position Embedding）在每个 attention head 的 Q、K 投影之后、点积之前，对二维通道对做与位置相关的旋转：

$$
\begin{bmatrix}
q'_{2r}\\ q'_{2r+1}
\end{bmatrix}
=
\begin{bmatrix}
\cos\theta_{p,r} & -\sin\theta_{p,r}\\
\sin\theta_{p,r} & \cos\theta_{p,r}
\end{bmatrix}
\begin{bmatrix}
q_{2r}\\ q_{2r+1}
\end{bmatrix}
$$

K 使用同样的规则。这样 `Q_p^T K_q` 会自然包含相对位置 `p-q` 的信息；模型能区分“两个相邻行为”与“间隔很远的行为”，而无需额外给每个绝对位置维护一个可训练表。

当前代码的顺序是：

```text
输入 Token
 → Wq/Wk/Wv 投影
 → reshape 为多头
 → 对 Q 和 K 施加 RoPE
 → scaled dot-product attention
 → 可学习 gate
 → 输出投影 + 残差
```

这里的 RoPE 与时间桶是互补的：

| 信息 | 解决的问题 |
|---|---|
| 时间桶 | 行为距离当前请求的真实新鲜度，例如 2 分钟还是 2 天 |
| RoPE | 行为在该域列表中的相对顺序和间距结构 |

## 6. 可学习 Gate 做了什么

当前注意力实现还在 Attention 输出后加入门控：

$$
\operatorname{out}=W_O\bigl(\operatorname{Attn}(Q,K,V)\odot\sigma(W_GX)\bigr)
$$

直觉上，这给每个位置、每个通道一个“是否接纳本轮注意力更新”的开关。其初始设置是 `W_G=0`、bias 为 1，因此初期门值约为 `sigmoid(1)`，不会让门控一开始就随机关闭信息流；训练后再按数据学习选择性放大或抑制更新。

## 7. 跨两层 HyFormer，序列如何演化

以 `seq_a` 为例：

```text
初始 seq_a Tokens
  ↓ Block 1 的独立 Transformer
seq_a^1（更强的域内上下文）
  ↓ Block 1 的 Query Cross-Attention 被读取
  ↓ Query/NS 经 RankMixer 融合
更新后的 Query_a、NS Tokens
  ↓ Block 2 的独立 Transformer（输入是 seq_a^1，不是原始序列）
seq_a^2
  ↓ Block 2 的 Cross-Attention
最终 Decoded Query_a
```

因此第二层并非“重复编码原始序列”。它在已经演化过的序列表征上继续建模，同时使用包含跨域信息的更新 Query 重新读取；这共同形成“域内演化 + 跨域反馈 + 再检索”。

## 8. 计算与工程取舍

完整 Self-Attention 的复杂度约为 `O(L_m²·D)`。当前序列最大长度配置为 `256 / 256 / 512 / 512`，因此分域独立编码不仅保留语义，也避免把四条序列拼成一条更长序列后出现平方级计算放大。

需要监控：

- 各域真实有效长度分布；padding 比例过高会浪费计算。
- 序列排序方向与 RoPE/时间桶口径一致；例如“最新在前”与“最新在后”不能混用。
- RoPE 的缓存最大长度必须覆盖线上截断长度。
- 若扩到更长序列，应优先比较 LONGER/top-k 压缩编码器，而不是直接把全量 Transformer 长度翻倍。

## 9. 面试表述

> Sequence Evolution 是每个 HyFormer Block 的域内序列编码阶段。四路行为不直接拼接，而是各自用 Pre-LN Transformer 更新完整 Token 序列；Self-Attention 建模该域内的行为依赖，RoPE 表达相对顺序，时间桶表达相对当前请求的新鲜度。输出不是一个池化向量，而是完整 K/V，供 Query Cross-Attention 读取。第一层后 Query 经 RankMixer 获得跨域上下文，第二层再带着这个上下文读取已演化的序列，这就是两层设计的核心价值。
