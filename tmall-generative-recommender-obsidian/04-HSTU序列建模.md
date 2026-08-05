# 04 HSTU 序列建模

## 1. 输入表示

历史中的每个行为不是一个单独的 item ID，而是多种 token 的组合：

```text
event_t = SID(item_t) + behavior_embedding(action_t) + time_embedding(time_gap_t)
```

若一个 SID 有 4 个 token，则历史序列长度约为 `4 × MAX_SEQ_LEN`。实际实现中，项目会将 SID code embedding、行为 embedding 和时间 embedding 相加，再输入 HSTU-style block。

## 2. 相对位置与时间偏置

绝对位置只能告诉模型“这是第几个位置”，相对偏置更直接地表达两个行为之间的距离。可以写成：

$$
B_{ij}=b_{pos}(i-j)+b_{time}(\Delta t_{ij})
$$

其中 `b_pos` 是相对位置 embedding，`b_time` 是时间差 bucket 的 embedding。这个偏置加到 attention score 或 interaction score 中，使模型可以学习“最近行为更重要”或“相隔较远的行为仍有长期兴趣价值”。

## 3. causal 和 padding mask

- causal mask：位置 `i` 只能访问 `j≤i`，防止看到未来 token。
- padding mask：padding 位置不参与有效交互。
- 生成 target 时，历史可以完整编码，但目标 SID 的 code 之间仍要遵循自回归条件。

这两个 mask 解决的是不同问题，不能混为一谈。

## 4. HSTU-style block

设输入为 `X`，通过线性层得到：

$$
[Q,K,V,U]=XW_{qkvu}
$$

加入相对位置/时间 bias 后得到交互矩阵：

$$
A=\operatorname{SiLU}(QK^T+B)
$$

当前实现用 pointwise SiLU 替代传统 Softmax 归一化，再用 `V` 聚合并与 `U` 做门控：

$$
H=A V
$$

$$
Y=X+\operatorname{Dropout}(H\odot U)W_o
$$

随后配合 LayerNorm/残差得到下一层输入。直觉上，`A` 表示 pairwise interaction，`U` 控制当前 token 接收多少更新。

## 5. 与普通 Transformer 的差异

| 维度 | 普通 Transformer | 当前 HSTU-style 实现 |
|---|---|---|
| score 归一化 | Softmax | Pointwise SiLU 形式 |
| FFN | 通常有两层 FFN | 采用门控更新，不依赖传统 FFN |
| 长序列重点 | 注意力矩阵成本高 | 尝试用更适合推荐序列的交互与门控 |
| 时间建模 | 常需额外加特征 | 显式加入相对位置/时间偏置 |
| 项目定位 | 通用序列建模 | 推荐场景的 HSTU-style 原型 |

最稳妥的说法是：“我参考 HSTU 的 `Q/K/V/U`、pointwise activation 和 gated residual 思路实现了推荐序列编码器。”如果面试官追问官方细节，要承认当前版本是简化实现。

## 6. 复杂度和工程问题

标准全注意力的时间/空间复杂度通常与序列长度平方相关：`O(L²d)`。如果 SID 展开后 `L` 变长，成本会明显增加。可以考虑：

- 只保留最近行为或按兴趣分桶。
- 先对一个行为的多个 SID code 做局部 pooling。
- 使用 block sparse / sliding window attention。
- 对短期和长期兴趣使用不同分支。
- 采用 mixed precision 和 fused kernel。

## 7. 关键面试问题

**问：为什么 HSTU 不直接等同于 Transformer？**

答：两者都使用序列交互，但 HSTU-style block 的 score、门控和推荐特化设计不同。项目中没有把它说成完全新的注意力机制，而是使用推荐场景中的 pointwise activation、`U` 门控和相对时间偏置来适配行为序列。

**问：长序列一定更好吗？**

答：不一定。过长序列会引入噪声、增加复杂度，并使近期兴趣被稀释。当前项目做了序列长度消融，选择验证集最优长度；生产中还会考虑按时间衰减或兴趣聚类截断。

