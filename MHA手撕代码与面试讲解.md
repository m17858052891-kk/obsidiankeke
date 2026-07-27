---
tags:
  - 八股
  - Transformer
  - Attention
  - MHA
  - 手撕代码
created: 2026-07-23
updated: 2026-07-27
---

# Multi-Head Attention：面试极简手撕版

> 目标：面试现场能在 10 分钟内写完。这里只保留 Q/K/V 投影、拆头、缩放点积、Mask、合并多头和输出投影。

## 1. 先背数据流

输入形状：

$$
Q\in\mathbb R^{B\times L_q\times D},\qquad
K,V\in\mathbb R^{B\times L_k\times D}
$$

将 $D$ 拆成 $H$ 个 Head，$D_h=D/H$：

$$
(B,L,D)\rightarrow(B,H,L,D_h)
$$

每个 Head 分别计算：

$$
\operatorname{Attention}(Q,K,V)
=\operatorname{Softmax}\left(\frac{QK^T}{\sqrt{D_h}}+Mask\right)V
$$

最后把多头拼回 $(B,L_q,D)$，再经过输出投影。

---

## 2. 面试推荐代码

```python
import math
import torch
import torch.nn as nn


class MultiHeadAttention(nn.Module):
    def __init__(self, d_model, num_heads):
        super().__init__()
        assert d_model % num_heads == 0

        self.d_model = d_model
        self.num_heads = num_heads
        self.head_dim = d_model // num_heads

        self.wq = nn.Linear(d_model, d_model)
        self.wk = nn.Linear(d_model, d_model)
        self.wv = nn.Linear(d_model, d_model)
        self.wo = nn.Linear(d_model, d_model)

    def split_heads(self, x):
        # (B, L, D) -> (B, H, L, Dh)
        B, L, _ = x.shape
        x = x.reshape(B, L, self.num_heads, self.head_dim)
        return x.transpose(1, 2)

    def forward(self, query, key=None, value=None, mask=None):
        # 不传 key/value 时就是 Self-Attention
        if key is None:
            key = query
        if value is None:
            value = key

        B, Lq, _ = query.shape

        q = self.split_heads(self.wq(query))
        k = self.split_heads(self.wk(key))
        v = self.split_heads(self.wv(value))

        # (B, H, Lq, Dh) @ (B, H, Dh, Lk)
        # -> (B, H, Lq, Lk)
        scores = q @ k.transpose(-2, -1)
        scores = scores / math.sqrt(self.head_dim)

        # 统一约定：mask=True 表示可以关注，False 表示屏蔽
        if mask is not None:
            scores = scores.masked_fill(~mask, float("-inf"))

        attn = torch.softmax(scores, dim=-1)
        context = attn @ v                    # (B, H, Lq, Dh)

        # 合并所有 Head：(B, H, Lq, Dh) -> (B, Lq, D)
        context = context.transpose(1, 2).contiguous()
        context = context.reshape(B, Lq, self.d_model)
        return self.wo(context)
```

### 真正需要记住的只有六步

```text
1. Q/K/V 线性投影
2. reshape + transpose 拆成多头
3. scores = Q @ K^T / sqrt(Dh)
4. 加 Mask，在 Key 维做 Softmax
5. attention @ V
6. transpose + reshape 合并多头，再做 Wo
```

---

## 3. Self-Attention 使用示例

```python
B, L, D, H = 8, 20, 64, 4
x = torch.randn(B, L, D)
mha = MultiHeadAttention(D, H)

# 不传 key/value：Q、K、V 都来自 x
out = mha(x)
print(out.shape)  # (8, 20, 64)
```

## 4. Causal Mask 怎么写？

```python
# 下三角为 True：位置 i 只能看到自己和过去
causal_mask = torch.tril(
    torch.ones(L, L, dtype=torch.bool)
)[None, None, :, :]                     # (1, 1, L, L)

out = mha(x, mask=causal_mask)
```

由于 Broadcast，同一个 Causal Mask 会用于所有 Batch 和 Head。

## 5. Padding Mask 怎么写？

假设 `padding_mask` 的形状为 `(B,L)`，其中 `True` 表示 Padding：

```python
padding_mask = torch.zeros(B, L, dtype=torch.bool)
padding_mask[:, -3:] = True

# 转成 True=允许关注，并扩展为 (B, 1, 1, L)
valid_key_mask = (~padding_mask)[:, None, None, :]
out = mha(x, mask=valid_key_mask)
```

同时需要 Causal Mask 和 Padding Mask 时，直接取交集：

```python
mask = causal_mask & valid_key_mask
out = mha(x, mask=mask)
```

> Mask 主要屏蔽无效 Key，不会自动把 Padding Query 的输出清零；训练时还应在 Loss 中忽略 Padding 位置。

## 6. Cross-Attention 怎么调用？

```python
query = torch.randn(8, 4, 64)      # 4 个 Query Token
history = torch.randn(8, 100, 64)  # 历史序列

# Q 来自 query，K/V 来自 history
out = mha(query, history, history)
print(out.shape)  # (8, 4, 64)
```

Self-Attention 与 Cross-Attention 的代码完全相同，区别只在 Q/K/V 的来源：

- Self-Attention：Q、K、V 来自同一序列；
- Cross-Attention：Q 来自查询侧，K、V 来自被检索的上下文序列。

---

## 7. 为什么除以 $\sqrt{D_h}$？

若 $q,k$ 各维独立且方差为 1，那么点积 $q^Tk$ 的方差约为 $D_h$。Head 维度越大，Attention Logit 越大，Softmax 越容易饱和，梯度变小。

除以 $\sqrt{D_h}$ 后，Logit 的方差回到稳定量级。

## 8. 为什么需要 `contiguous()`？

`transpose` 改变了张量的 Stride，内存通常不连续。合并 Head 前写：

```python
context = context.transpose(1, 2).contiguous()
```

再 `reshape` 成 `(B,L,D)`，可以避免内存布局导致的问题。

## 9. 参数量和复杂度

Q、K、V、O 共四个 $D\times D$ 的投影矩阵：

$$
\operatorname{Params}\approx4D^2
$$

Self-Attention 的主要复杂度为：

$$
O(BL^2D+BLD^2)
$$

其中 $L^2D$ 来自 Attention，$LD^2$ 来自线性投影。Head 数变化通常不改变投影矩阵的总参数量。

## 10. 面试最常见的错误

1. 忘记检查 `d_model % num_heads == 0`；
2. 拆头后忘记转成 `(B,H,L,Dh)`；
3. 忘记除以 $\sqrt{D_h}$；
4. Softmax 维度写错，应该在 Key 维 `dim=-1`；
5. Mask 的 True/False 语义前后不一致；
6. `K.transpose(-2, -1)` 的维度写错；
7. 合并多头前忘记 `transpose`；
8. 某个 Query 的所有 Key 都被 Mask，导致 `softmax(-inf)` 出现 NaN。

## 11. 面试 30 秒讲法

> 我先对输入做 Q、K、V 三个线性投影，然后把隐藏维拆成多个 Head，形状从 `(B,L,D)` 变成 `(B,H,L,Dh)`。每个 Head 计算 `QK^T / sqrt(Dh)`，加入 Mask 后在 Key 维做 Softmax，再乘 V 得到 Context。最后把多头结果 transpose、reshape 回 `(B,L,D)`，经过输出投影。最容易写错的是 Softmax 维度、Mask 语义和多头合并时的维度顺序。

## 12. 一句话速记

> **投影 QKV → 拆头 → QK 转置相乘并缩放 → Mask + Softmax → 乘 V → 合头 + 输出投影。**
