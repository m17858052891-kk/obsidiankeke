---
tags: [模型架构, 特征交叉, FM, 矩阵分解, 推荐系统, 面试]
---

# FM：低秩二阶特征交叉

> Factorization Machine（FM）在 LR 一阶项上加入所有特征对的二阶交叉，并把交叉权重表示成 embedding 内积。它的核心价值是：在高维稀疏、长尾共现下，让不同组合共享统计强度。

## 1. 公式与组成

$$\hat y=w_0+\sum_{i=1}^{n}w_ix_i+\sum_{i<j}\langle v_i,v_j\rangle x_ix_j.$$

$w_i$ 是一阶权重，$v_i\in\mathbb R^k$ 是特征 embedding，$\langle v_i,v_j\rangle$ 是特征对 $(i,j)$ 的二阶交叉权重。用于 CTR 时，$\hat y$ 为 logit，再接 Sigmoid 和 BCE。

## 2. 为什么不直接给每个交叉一个参数？

直接二阶多项式需要 $O(n^2)$ 个 $w_{ij}$，而 `用户ID × 商品ID` 等长尾组合样本少。FM 令 $w_{ij}=\langle v_i,v_j\rangle$，参数降为 $O(nk)$。即使 $i,j$ 从未共现，二者 embedding 也可通过其他共现被更新，从而对新组合泛化。

## 3. 如何从 $O(n^2k)$ 高效计算？

利用平方展开：

$$
\sum_{i<j}\langle v_i,v_j\rangle x_ix_j
=\frac12\sum_{f=1}^{k}\left[(\sum_i v_{if}x_i)^2-\sum_i(v_{if}x_i)^2\right].
$$

只需遍历非零特征，成本为 $O(nnz(x)k)$。

## 4. FM 和矩阵分解（MF）的关系

MF 为用户、物品学习向量：$\hat y_{ui}=b+b_u+b_i+p_u^Tq_i$。若 FM 输入只有 User ID 与 Item ID two-hot，其二阶项就是 $p_u^Tq_i$。因此 **MF 是 FM 在 user-item 两类特征上的特例，FM 将低秩内积推广到任意稀疏特征。**

## 5. 局限与后续模型

标准 FM 主要二阶，且所有交叉共用同一种内积形式，难表达高阶强非线性与 field 语义。FFM 引入 field-aware embedding；DeepFM 加 DNN 学习隐式高阶；DCN/xDeepFM 使用不同显式高阶结构。

## 6. 高频问答

### 为什么适合广告推荐？

广告推荐有海量稀疏 ID，直接为每个组合建参会极度稀疏；FM 通过 embedding 共享统计强度。

### FM embedding 与神经网络 embedding 一样吗？

参数形式相似；FM 明确用内积定义二阶项，而神经网络 embedding 还能进入 MLP、Attention 等模块。

### FM 与 Polynomial LR？

Polynomial LR 为每个交叉独立建参；FM 用低秩分解生成交叉参数，参数少且长尾泛化更强。

## 7. 30 秒回答

> FM 等于 LR 加低秩二阶交叉：特征 $i,j$ 的交叉权重由 embedding 内积决定。它把 $O(n^2)$ 的交叉参数降到 $O(nk)$，缓解长尾组合稀疏；当输入只剩 user 和 item one-hot 时，FM 就退化为矩阵分解。
