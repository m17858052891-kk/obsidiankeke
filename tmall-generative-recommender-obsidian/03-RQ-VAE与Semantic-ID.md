# 03 RQ-VAE 与 Semantic ID

## 1. 目标

对每个 item 的连续向量 `z`，学习一个短的离散 code 序列：

```text
item -> [code_0, code_1, code_2, collision]
```

这样推荐模型不再直接生成百万级 item ID，而是生成少量 code。若每级 codebook 有 `K` 个 code，`L` 级理论地址空间为 `K^L`；实际有效地址由训练中出现过的 SID 决定。

## 2. 残差量化

设输入 embedding 为 `z`，第 `l` 级 codebook 为 `C_l`，残差为 `r_l`：

$$
r_0=z
$$

$$
k_l=\arg\min_k\|r_l-C_l[k]\|_2^2
$$

$$
q_l=C_l[k_l],\quad r_{l+1}=r_l-q_l
$$

最终量化向量为：

$$
q(z)=\sum_{l=0}^{L-1}q_l
$$

第一个 code 表示粗粒度信息，后续 code 表示前面量化后剩余的细节。相比一次性 VQ，残差量化更适合用多个 code 逐步增加表示容量。

## 3. 当前代码的 RQ-VAE 风格实现

`RQVAETokenizer` 包含：

- encoder：`32 → 128 → 32`。
- 3 个 codebook，每个大小为 256。
- residual quantization：逐级拟合残差。
- decoder：从量化向量重构原始 item embedding。
- 重构损失、codebook loss、commitment loss。

它是一个确定性量化自编码器。当前代码没有 VAE 中常见的 `μ/σ` 采样，也没有 KL divergence。因此面试时说“RQ-VAE 风格/残差量化自编码器”更准确，不要说成完整概率 VAE。

## 4. 损失函数

常见形式：

$$
\mathcal{L}=\mathcal{L}_{rec}+\lambda_c\mathcal{L}_{codebook}+\beta\mathcal{L}_{commit}
$$

重构损失：

$$
\mathcal{L}_{rec}=\|D(q(z))-z\|_2^2
$$

codebook loss：让 codebook 向 encoder 输出靠近：

$$
\mathcal{L}_{codebook}=\|\operatorname{sg}[z]-q(z)\|_2^2
$$

commitment loss：让 encoder 承诺使用选中的 code：

$$
\mathcal{L}_{commit}=\|z-\operatorname{sg}[q(z)]\|_2^2
$$

`sg` 表示 stop-gradient。straight-through estimator 在前向使用离散 quantized value，在反向把梯度近似传回连续 encoder 输出：

```python
quantized_st = z + (quantized - z).detach()
```

## 5. codebook collapse

如果大量 item 只使用少数 code，说明 codebook collapse。可能原因：

- codebook 初始化不好。
- commitment 权重过大，encoder 过早锁死。
- codebook 容量过大但训练样本不足。
- item embedding 本身被热门 item 主导。
- 优化学习率或量化温度不合适。

需要监控：

- 每级 code 的使用数。
- code 使用熵。
- 最常用 code 占比。
- 量化前后重构误差。
- 不同 code level 的残差范数。

可选改进：EMA codebook 更新、dead-code replacement、balanced assignment、分层 dropout、提高长尾 item 采样概率。

## 6. collision token

多个 item 可能得到相同的前三级 code。若直接把同一个 SID 映射成一个 item，会发生信息丢失。当前做法是：

1. 先用 3 个 RQ code 形成基础 SID。
2. 对冲突组追加一个 collision token。
3. 建立 `sid_table: item -> sid` 和 `sid_to_items: sid -> items`。

collision token 不是语义 code，而是冲突消解地址。面试时要说明它可能增加词表或前缀树的复杂度，也不应无限增长。

## 7. Semantic ID 的含义

这里的“semantic”不一定等同于文本语义。由于当前输入是协同行为学习得到的 item embedding，SID 更准确地说是**协同语义/用户行为语义的离散地址**。若用商品标题、类目、图像等内容 embedding，才更接近内容语义 SID；生产系统可以融合 content 和 collaborative embedding。

## 8. 关键面试问题

**问：为什么不直接给每个 item 一个随机 code？**

答：随机 code 只能完成压缩地址映射，无法利用 item 之间的相似关系。量化器输入的是由协同行为学习到的连续 embedding，因此相近 item 更可能共享前缀，生成模型能复用子结构。

**问：RQ-VAE 和普通 VQ 有什么区别？**

答：普通 VQ 通常用一次 code 近似向量；RQ 通过多个 code 逐级量化残差，先表示粗粒度部分，再表示细节，从而在较小 codebook 下获得更大的组合容量。

