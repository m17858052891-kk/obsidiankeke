# 目录

- [[#1. 模块定位：516 前置候选感知池化]]
- [[#2. 底层计算流程]]
- [[#3. 为什么比后置 DIN residual 更好]]
- [[#4. 宏观总结]]

# 1. 模块定位：516 前置候选感知池化

这篇文档的口径需要从“后置 DIN 增强分支”修正为 **516 前置 Candidate-Aware Pooling**。

当前最优版本不是在两层 HyFormer 之后再额外接一个 DIN residual，而是在 Query Generator 阶段就让候选 item 参与四路历史行为的池化。换句话说，候选感知不是输出端补丁，而是 Query 生成的输入条件。

# 2. 底层计算流程

首先，item 侧离散特征会被压成 2 个 Item NS Tokens。516 用它们的平均值作为候选商品表示：

$$
e_{target}=\operatorname{MeanPool}(N_{item})
$$

对于第 $s$ 个行为域，序列已经经过 `_embed_seq_domain` 得到行为 token：

$$
H_s=[h_{s,1},h_{s,2},\dots,h_{s,L}]
$$

随后执行 Bilinear Target-Aware Pooling：

$$
a_{s,j}=\operatorname{softmax}\left(rac{(W_s h_{s,j})^T e_{target}}{\sqrt D}
ight)
$$

$$
h^{target}_s=\sum_j a_{s,j}h_{s,j}
$$

其中 padding 行会被 mask 掉；如果整条序列都是 padding，权重会通过 `nan_to_num` 回到 0，避免出现 NaN。

最后，将候选感知兴趣向量和静态 NS 信息拼接后生成 Query：

$$
G_s=[N_{flat};h^{target}_s]
$$

$$
Q_s^{(1)},Q_s^{(2)}=\operatorname{FFN}_s(G_s)
$$

# 3. 为什么比后置 DIN residual 更好

后置 DIN residual 的逻辑是“主干先编码所有历史，最后再让候选 item 做一次检索”。它的安全性好，但候选信息进入太晚。

516 的优势是：

- **前置过滤**：无关历史在 Query 生成前就被降权；
- **主干受益**：两层 HyFormer 后续处理的是候选相关 Query，而不是泛化 Query；
- **表达力强**：双线性矩阵 $W_s$ 可以学习 item token 与行为 token 的跨空间映射；
- **结构更自然**：CVR 请求中候选 item 已知，把它提前用于兴趣抽取符合业务链路。

# 4. 宏观总结

516 的关键价值是把 DIN 思想从“输出端补丁”升级成“Query 生成条件”。因此，当前目录里关于 Candidate-Aware 的最优口径应统一为：**516 前置 target-aware pooling 优于后期 DIN residual 融合。**
