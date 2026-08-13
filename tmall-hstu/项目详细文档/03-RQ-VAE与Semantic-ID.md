# 03 RQ-VAE 风格量化与 Semantic ID

## 当前实现的准确定位

当前模块应称为 **RQ-VAE-style deterministic residual quantization autoencoder**。它有 Encoder、多个残差 Codebook、Decoder、重构损失、codebook loss 和 commitment loss，但没有标准 VAE 的 Gaussian posterior、随机采样和 KL divergence。

## 输入和残差量化

输入是 Item2Vec 商品向量 (x_i)，Encoder 得到 (z_e)。令 (r_0=z_e)，第 (l) 级 codebook 选择最近 code：

$$
k_l=\arg\min_k\|r_l-C_l[k]\|_2^2,
\quad q_l=C_l[k_l],
\quad r_{l+1}=r_l-q_l
$$

最终量化向量为：

$$
z_q=\sum_lq_l
$$

各级索引拼成基础 SID。Decoder 用 (z_q) 重构原始 Item2Vec 向量。

## 为什么使用残差量化

单级量化要求一个 code 直接表达整个向量，codebook 容量和冲突率之间矛盾。残差量化先表达粗粒度部分，再用后续 code 修正残差；多级小 codebook 的组合拥有更大的地址空间，也适合逐级自回归生成。

树模型或 Hierarchical KMeans 可以构造层级地址，适合作为 baseline，但普通树不天然按照 latent 残差量化，也可能破坏协同向量的几何结构，所以不是 RQ 的等价替代。

## 损失和不可导处理

$$
\mathcal{L}_{RQ}=\mathcal{L}_{rec}
+\lambda_c\mathcal{L}_{codebook}
+\beta\mathcal{L}_{commit}
$$

重构损失保持 Item2Vec 语义；codebook loss 更新码本；commitment loss 约束 Encoder 稳定使用选中的 code。量化索引的 `argmin` 不可导，通常用 Straight-Through Estimator：

```python
quantized_st = z_e + (quantized - z_e).detach()
```

## Codebook collapse

监控每级 code 使用数、使用熵、top code 占比、残差范数和重构误差。若大量商品只使用少数 code，说明 codebook collapse；可以尝试 EMA 更新、dead-code replacement、均衡采样和调整 commitment 权重。

## Collision Token

多个商品可能获得相同基础 SID。处理方法是统计冲突组，并按稳定规则追加 token：

```text
[12,37,5] → [12,37,5,COL_0]
[12,37,5] → [12,37,5,COL_1]
```

基础 code 表示协同语义，collision token 负责唯一寻址。Collision Token 不是 RQ-VAE 学出的语义 code，分配规则必须固定，否则 SID 映射会漂移。

## Semantic 的含义

当前输入来自 Item2Vec，所以这里的 Semantic ID 更准确是协同语义/行为语义的离散地址；如果加入标题、类目或图像 embedding，才会增加内容语义和冷启动能力。
