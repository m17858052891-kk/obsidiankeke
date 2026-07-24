# 动态序列编码：从一条行为到 Query

本文只解释一件事：原始的多字段行为日志，如何变为 HyFormer 能读的候选感知 Query。

## 一个单样本例子

假设当前请求发生在周一 10:00，候选物品为 `Item-X`。`seq_a` 的一条行为由 3 个字段组成；业务字段名未保存在当前 schema 快照中，以下 A/B/C 只是位置示例。

```text
seq_a[用户]，shape=[3,4]，有效长度=2

字段 A: [101, 205, 0, 0]
字段 B: [  8,  12, 0, 0]
字段 C: [  3,   1, 0, 0]
时间戳 : [09:58:20, 09:20:00, 0, 0]
```

第 0 个位置是一条完整行为 `[101,8,3]`，第 1 个位置是 `[205,12,1]`；后两位是 padding。

## 1. 字段拼接，不是序列展平

第 0 个位置的三个字段分别查表：

```text
101 → e_A ∈ R^64
  8 → e_B ∈ R^64
  3 → e_C ∈ R^64
```

沿最后一维拼接：

```text
[e_A | e_B | e_C] ∈ R^192
      ↓ Linear(192→64) + GELU
content_0 ∈ R^64
```

对每个位置重复相同过程，因此输出仍是 `[4,64]`，不是把 `4×3×64` 压成一个长向量。

## 2. 加入相对请求时间

第 0 条行为距当前请求 100 秒，落进约 `60~120 秒` 的非均匀时间桶；查到 64 维时间向量后相加：

```text
token_0 = content_0 + time_embedding[60~120 秒]
```

最终：

```text
seq_a_tokens = [token_0, token_1, padding, padding]
shape = [4,64]
```

时间表示的是“距离这次请求多久”，并非简单的第几个位置；RoPE 则在后续 Transformer 中补充序列顺序。

## 3. 用 Item-X 先做前置软筛选

候选物品的两个 NS Token 取均值得到 `q_item`。对 `seq_a_tokens` 的两条有效记录，Bilinear Target-Aware Pooling 可能学出：

```text
Item-X 与 token_0 的相关性：高
Item-X 与 token_1 的相关性：低

softmax 权重：[0.85, 0.15]
interest_a = 0.85×token_0 + 0.15×token_1
```

这不是硬匹配规则，也不是删除第二条行为，而是给 Query Generator 一个与候选物品相关的域兴趣摘要。

## 4. 从兴趣摘要到 Query

```text
8 个 NS Token 展平：8×64 = 512维
本域 interest_a：64维
拼接后：576维
    ↓ LayerNorm
    ↓ FFN_a_1 → Q_a_1，64维
    ↓ FFN_a_2 → Q_a_2，64维
```

其余三域重复，产生 8 个初始 Query。完整 `seq_a_tokens` 并未丢弃，随后仍由两层 HyFormer 的 Transformer 和 Cross-Attention 读取。

## 面试一句话

> 每条行为先在事件内部完成多字段拼接与时间对齐；候选物品再对完整历史做软筛选，生成候选感知 Query。DIN 提供的是初始化方向，HyFormer 保留完整序列做后续两轮精细检索。
