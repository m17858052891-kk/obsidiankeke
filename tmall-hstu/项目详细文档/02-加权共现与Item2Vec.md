# 02 加权共现与 Item2Vec

## 目标

原始 Item ID 只是索引，没有商品相似性的几何结构。这里先把用户行为序列转成稀疏 item-item 关系，再用 Item2Vec 学习商品连续协同向量，供 RQ-VAE 量化。

## 加权共现

同一用户序列中，距离不超过窗口 (W) 的两个商品形成 pair。共现权重综合行为类型、时间距离、序列位置和用户活跃度：

$$
w_{ij}\mathrel{+}=b(a_i)b(a_j)
\exp\left(-\frac{|t_i-t_j|}{\tau_t}\right)
\frac{1}{\log(1+L_u)}
\gamma^{d(i,j)-1}
$$

它的输出是稀疏边 `(item_i, item_j, w_ij)`，不是 embedding，也不是 SID。工程上只保留局部 pair 和每个 item 的 top-N 邻居，避免构造 (O(N^2)) 的 dense 矩阵。行为权重是训练先验，不等于因果强度，需要通过消融验证。

## Weighted Item2Vec

建立商品 embedding table：

$$
E\in\mathbb{R}^{N\times d}
$$

对正 pair 使用归一化点积：

$$
s(i,j)=\frac{E_i}{\|E_i\|_2}\cdot\frac{E_j}{\|E_j\|_2}
$$

结合负采样训练：

$$
\mathcal{L}_{i,j}=-w_{ij}\log\sigma(s(i,j))
-\sum_{n\in\mathcal{N}(i)}\log\sigma(-s(i,n))
$$

共现权重决定正样本对梯度的贡献，训练后每一行 (E_i) 是一个商品的连续协同向量。当前实现使用稀疏 embedding 和 `SparseAdam`，因为每个 batch 只访问少量商品行。

## 负采样和 ItemCF 的区别

均匀负采样覆盖长尾，热门池负采样增加区分难度；需要控制热门采样概率，排除已知正样本，并注意未来正样本被误采成负样本的 false negative。

ItemCF 直接使用共现分做邻居召回；Item2Vec 使用共现 pair 训练参数化 embedding。两者可以共享协同信号，但 ItemCF 的输出是候选分数，Item2Vec 的输出是连续向量，后者可以继续进入 RQ-VAE。
