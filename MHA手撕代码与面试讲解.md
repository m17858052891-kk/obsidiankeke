---
tags:
  - 八股
  - Transformer
  - Attention
  - MHA
  - 手撕代码
created: 2026-07-23
---

# Multi-Head Attention 手撕代码与面试讲解

## 1. 面试时先讲清数据流

输入：

$$
Q\in\mathbb R^{B\times L_q\times D},\quad
K,V\in\mathbb R^{B\times L_k\times D}
$$

将 $D$ 拆成 $H$ 个 Head，每个 Head 维度 $D_h=D/H$：

$$
(B,L,D)\rightarrow(B,H,L,D_h)
$$

每个 Head 独立执行 Scaled Dot-Product Attention：

$$
Attention(Q,K,V)=Softmax\left(\frac{QK^T}{\sqrt{D_h}}+Mask\right)V
$$

最后将所有 Head 拼回：

$$
(B,H,L_q,D_h)\rightarrow(B,L_q,D)
$$

再经过输出投影 $W_O$。

## 2. PyTorch 手撕实现

```python
import math
from typing import Optional, Tuple

import torch
import torch.nn as nn


class MultiHeadAttention(nn.Module):
    """不调用 nn.MultiheadAttention / scaled_dot_product_attention 的 MHA。

    Mask 约定：
    - key_padding_mask: (B, Lk)，bool，True 表示 Key 位置无效。
    - attn_mask: (Lq, Lk)、(B, Lq, Lk) 或 (B, H, Lq, Lk)。
      bool mask 中 True 表示禁止关注；浮点 mask 作为加性 bias。
    """

    def __init__(
        self,
        d_model: int,
        num_heads: int,
        dropout: float = 0.0,
        bias: bool = True,
    ) -> None:
        super().__init__()
        if d_model % num_heads != 0:
            raise ValueError("d_model must be divisible by num_heads")

        self.d_model = d_model
        self.num_heads = num_heads
        self.head_dim = d_model // num_heads
        self.scale = self.head_dim ** -0.5

        self.q_proj = nn.Linear(d_model, d_model, bias=bias)
        self.k_proj = nn.Linear(d_model, d_model, bias=bias)
        self.v_proj = nn.Linear(d_model, d_model, bias=bias)
        self.out_proj = nn.Linear(d_model, d_model, bias=bias)
        self.attn_dropout = nn.Dropout(dropout)

    def _split_heads(self, x: torch.Tensor) -> torch.Tensor:
        # (B, L, D) -> (B, L, H, Dh) -> (B, H, L, Dh)
        batch_size, seq_len, _ = x.shape
        x = x.reshape(batch_size, seq_len, self.num_heads, self.head_dim)
        return x.transpose(1, 2)

    def _prepare_attn_mask(
        self,
        attn_mask: torch.Tensor,
        batch_size: int,
    ) -> torch.Tensor:
        if attn_mask.dim() == 2:
            # (Lq, Lk) -> (1, 1, Lq, Lk)
            return attn_mask[None, None, :, :]
        if attn_mask.dim() == 3:
            # (B, Lq, Lk) -> (B, 1, Lq, Lk)
            if attn_mask.size(0) != batch_size:
                raise ValueError("3D attn_mask first dim must equal batch size")
            return attn_mask[:, None, :, :]
        if attn_mask.dim() == 4:
            return attn_mask
        raise ValueError("attn_mask must have 2, 3 or 4 dimensions")

    def forward(
        self,
        query: torch.Tensor,
        key: Optional[torch.Tensor] = None,
        value: Optional[torch.Tensor] = None,
        key_padding_mask: Optional[torch.Tensor] = None,
        attn_mask: Optional[torch.Tensor] = None,
        is_causal: bool = False,
        need_weights: bool = False,
    ) -> Tuple[torch.Tensor, Optional[torch.Tensor]]:
        """
        Args:
            query: (B, Lq, D)
            key:   (B, Lk, D)，None 时做 Self-Attention
            value: (B, Lk, D)，None 时使用 key
        Returns:
            output: (B, Lq, D)
            weights: need_weights=True 时为 (B, H, Lq, Lk)
        """
        if key is None:
            key = query
        if value is None:
            value = key

        batch_size, query_len, _ = query.shape
        key_len = key.size(1)

        q = self._split_heads(self.q_proj(query))  # (B, H, Lq, Dh)
        k = self._split_heads(self.k_proj(key))    # (B, H, Lk, Dh)
        v = self._split_heads(self.v_proj(value))  # (B, H, Lk, Dh)

        # (B, H, Lq, Dh) @ (B, H, Dh, Lk)
        # -> (B, H, Lq, Lk)
        scores = torch.matmul(q, k.transpose(-2, -1)) * self.scale

        if is_causal:
            if query_len != key_len:
                raise ValueError(
                    "This simple causal mask assumes self-attention with Lq == Lk"
                )
            causal_mask = torch.ones(
                query_len,
                key_len,
                dtype=torch.bool,
                device=query.device,
            ).triu(diagonal=1)
            scores = scores.masked_fill(
                causal_mask[None, None, :, :], float("-inf")
            )

        if attn_mask is not None:
            mask = self._prepare_attn_mask(attn_mask, batch_size).to(
                device=scores.device
            )
            if mask.dtype == torch.bool:
                scores = scores.masked_fill(mask, float("-inf"))
            else:
                scores = scores + mask.to(dtype=scores.dtype)

        if key_padding_mask is not None:
            if key_padding_mask.shape != (batch_size, key_len):
                raise ValueError(
                    "key_padding_mask must have shape (batch_size, key_len)"
                )
            scores = scores.masked_fill(
                key_padding_mask.to(
                    device=scores.device,
                    dtype=torch.bool,
                )[:, None, None, :],
                float("-inf"),
            )

        weights = torch.softmax(scores, dim=-1)
        # 整行 Key 都被 mask 时 softmax(-inf) 会产生 NaN；回退为全 0。
        weights = torch.nan_to_num(weights, nan=0.0)
        weights = self.attn_dropout(weights)

        context = torch.matmul(weights, v)  # (B, H, Lq, Dh)

        # (B, H, Lq, Dh) -> (B, Lq, H, Dh) -> (B, Lq, D)
        context = context.transpose(1, 2).contiguous()
        context = context.reshape(batch_size, query_len, self.d_model)
        output = self.out_proj(context)

        return output, weights if need_weights else None
```

## 3. 最小使用示例

```python
torch.manual_seed(0)

mha = MultiHeadAttention(d_model=64, num_heads=4, dropout=0.1)
x = torch.randn(8, 20, 64)

# 最后 3 个位置是 Padding；True 表示不可作为 Key/Value 被关注。
padding_mask = torch.zeros(8, 20, dtype=torch.bool)
padding_mask[:, -3:] = True

out, attn = mha(
    query=x,
    key_padding_mask=padding_mask,
    is_causal=True,
    need_weights=True,
)

print(out.shape)   # torch.Size([8, 20, 64])
print(attn.shape)  # torch.Size([8, 4, 20, 20])
```

## 4. Cross-Attention 示例

```python
query = torch.randn(8, 4, 64)    # 4 个 Query Token
history = torch.randn(8, 100, 64)
history_padding = torch.zeros(8, 100, dtype=torch.bool)

out, _ = mha(
    query=query,
    key=history,
    value=history,
    key_padding_mask=history_padding,
)

print(out.shape)  # torch.Size([8, 4, 64])
```

## 5. 为什么要除以 $\sqrt{D_h}$？

若 $q,k$ 各维独立、均值 0、方差 1，则点积：

$$
q^Tk=\sum_{i=1}^{D_h}q_ik_i
$$

方差随 $D_h$ 增长，约为 $D_h$。维度越大，Logit 绝对值越大，Softmax 越容易饱和，梯度变小。除以 $\sqrt{D_h}$ 后，Logit 方差回到稳定量级。

## 6. 为什么要 `transpose(...).contiguous()`？

`transpose` 只改变 Stride，内存通常不连续。随后要将 `(B, L, H, Dh)` 展平成 `(B, L, D)`；调用 `contiguous()` 后再 `reshape/view` 可以保证 Head 和通道按预期排列。`reshape` 有时会自动复制，但手撕代码中显式写出更清楚。

## 7. Mask 的三种类型

### Key Padding Mask

形状 `(B, Lk)`，用于屏蔽每个样本长度之外的 Padding Key。它只屏蔽“别人是否能看到这个 Key”，不会自动把 Padding Query 的输出清零；如果下游保留 Padding Query，还应额外屏蔽输出或 Loss。

### Causal Mask

形状 `(L, L)` 的上三角 Mask，保证位置 $t$ 只能看到 $\le t$ 的历史。

### Attention Mask/Bias

可以是 bool Mask，也可以是浮点加性 Bias，例如相对位置 Bias、时间 Bias、ALiBi 等。

## 8. Self-Attention 与 Cross-Attention 的区别

- Self-Attention：$Q,K,V$ 都来自同一序列，$L_q=L_k$。
- Cross-Attention：$Q$ 来自 Query/Decoder/候选，$K,V$ 来自另一序列，$L_q$ 与 $L_k$ 可以不同。

复杂度：

$$
O(BL_qL_kD+ B(L_q+L_k)D^2)
$$

Self-Attention 取 $L_q=L_k=L$，得到 $O(BL^2D+BLD^2)$。

## 9. 参数量是多少？

标准实现包含 $W_Q,W_K,W_V,W_O$ 四个 $D\times D$ 矩阵：

$$
Params\approx4D^2
$$

加上 Bias 是 $4D$。Head 数改变不会改变总投影参数量，因为只是把同一个 $D$ 拆成多个 Head；但会改变每个 Head 的维度和表达方式。

## 10. 常见 Bug

1. 忘记检查 `d_model % num_heads == 0`。
2. 在错误维度上做 Softmax；应对最后的 Key 维 `dim=-1`。
3. Mask 语义写反；本实现约定 bool True 表示屏蔽。
4. 忘记除以 $\sqrt{D_h}$。
5. `transpose` 后直接用不兼容的 `view`。
6. Causal Mask 和 Padding Mask Broadcast 维度错误。
7. 全 Padding 行导致 `softmax(-inf)` 产生 NaN。
8. 误以为 Key Padding Mask 会自动屏蔽 Padding Query。
9. 返回多头平均权重，却误以为仍保留 Head 维。
10. Cross-Attention 中错误地让 Value 默认等于 Query；正确默认是 Value 等于 Key。

## 11. 面试 30 秒讲法

> 我先用四个线性层中的前三个得到 Q/K/V，把 `(B,L,D)` reshape 成 `(B,H,L,Dh)`。每个 Head 计算 `Q @ K^T / sqrt(Dh)`，依次加入 causal、attention 和 padding mask，然后在 Key 维做 Softmax，乘 V 得到每个 Head 的 Context。最后 transpose 回 `(B,L,H,Dh)`，拼成 `(B,L,D)` 并经过输出投影。实现里最容易错的是 Mask Broadcast、Softmax 维度、transpose 后内存不连续，以及全 Mask 行产生 NaN。
