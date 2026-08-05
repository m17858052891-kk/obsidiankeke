# 02 加权共现与 Item2Vec

## 1. 为什么需要协同表征

原始 item ID 只是整数编号，没有“相似商品”的几何结构。用户在短时间内连续点击的商品、收藏的商品和最终购买的商品之间，通常存在互补或替代关系。共现图把这种关系转成 item-item 边，Item2Vec 再把图结构压缩成低维向量。

注意：共现矩阵不是 SID。它是学习 item embedding 的训练信号，之后还要经过量化器才能生成离散 code。

## 2. 加权共现公式

对同一用户序列中距离不超过窗口 `W` 的两个商品 `i,j`，可以定义：

$$
w_{ij} \mathrel{+}= b(a_i)\cdot b(a_j)\cdot
\exp\left(-\frac{|t_i-t_j|}{\tau_t}\right)\cdot
\frac{1}{\log(1+L_u)}\cdot
\gamma^{d(i,j)-1}
$$

其中：

- `b(a)`：行为类型权重。
- `|t_i-t_j|`：时间距离。
- `τ_t`：时间衰减尺度。
- `L_u`：用户序列长度，抑制超活跃用户对共现图的支配。
- `d(i,j)`：序列位置距离。
- `γ`：位置衰减系数。

当前代码会加入正向和反向 pair，聚合后只保留每个 item 的 top-N 邻居，并限制训练 pair 数量，避免显式生成超大稠密矩阵。

## 3. 为什么必须稀疏化

商品数量可能达到数百万，稠密矩阵的空间复杂度是 `O(N^2)`，不可行。实际只保留观察到的局部共现边，数据结构可用：

```text
source_item -> [(neighbor_item, weight), ...]
```

这样空间复杂度近似为 `O(E)`，其中 `E` 是保留的稀疏边数。进一步的工程优化包括：

- 限制共现窗口。
- 每个 item 保留 top-N 邻居。
- 采用哈希或排序聚合 pair。
- 分片写入 Parquet/Key-Value 存储。
- 高频 item 单独做截断，防止热点节点产生过多边。

## 4. Weighted Item2Vec

模型用一个共享 embedding table `E∈R^{N×d}`。对正 pair `(i,j)`，希望 `E_i` 与 `E_j` 相似；对负样本 `n`，希望它们不相似。当前实现使用归一化后的点积：

$$
s(i,j)=\frac{E_i}{\|E_i\|_2}\cdot\frac{E_j}{\|E_j\|_2}
$$

正样本和负样本的加权 skip-gram loss 可写为：

$$
\mathcal{L}_{i,j}=-w_{ij}\log\sigma(s(i,j))
-\sum_{n\in\mathcal{N}(i)}\log\sigma(-s(i,n))
$$

当前代码使用 `sparse=True` 的 embedding 和 `SparseAdam`，因为每个 batch 只更新少数 item 行，避免每步对整个 embedding table 做 dense optimizer 更新。

## 5. 负采样

当前使用两类负样本：

- 一部分从全量 item 均匀采样，覆盖长尾。
- 一部分从热门 item pool 采样，增加与热门商品的区分难度。

负采样不是越随机越好。需要考虑：

- 是否排除当前用户已经交互过的 item。
- 是否从正样本的同类目或相似商品中采 hard negative。
- 热门采样是否会进一步放大 popularity bias。
- 负样本是否可能其实是用户未来会购买的 positive，即 false negative。

更严谨的改进是按时间窗口排除已知 positive，并用 popularity^`α` 控制采样分布；对序列推荐还可以使用 in-batch negative。

## 6. 这一步和 ItemCF 的关系

ItemCF 是“基于共现关系直接给候选打分”的非参数方法；Item2Vec 是“用共现关系学习向量”的参数方法。它们使用相似的行为信号，但用途不同：

| 方法 | 输出 | 是否训练神经网络 | 典型用途 |
|---|---|---|---|
| ItemCF | 邻居及共现分 | 否/弱参数 | 召回、解释 |
| Item2Vec | item embedding | 是 | 相似度、量化、神经召回 |
| RQ-VAE | 离散 code | 是 | Semantic ID、生成式推荐 |

## 7. 面试回答模板

**问：业内 SID 是由 itemCF 共现矩阵直接训练得到的吗？**

答：通常不是直接把共现矩阵当作 SID。共现或 ItemCF 信号常被用于学习 item embedding，随后再通过 RQ-VAE、RQ-KMeans 或类似残差量化方法把连续向量离散成多级 code。我的实现就是这条路线：行为加权的稀疏共现先训练 Weighted Item2Vec，再训练 RQ-VAE 风格 tokenizer。

