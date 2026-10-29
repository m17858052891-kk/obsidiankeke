---
tags: [模型架构, 特征交叉, DeepFM, 推荐系统, 面试]
---

# DeepFM：显式二阶交叉与隐式高阶建模

> DeepFM 将 FM 分支与 DNN 分支并行训练、共享底层特征 embedding：FM 显式建模一阶和二阶交叉，DNN 自动学习高阶非线性交叉。

## 1. 它和矩阵分解有什么关系？

矩阵分解用用户向量与物品向量内积表示交互：

$$
\hat y_{ui}=\langle v_u,v_i\rangle.
$$

FM 将这个思想推广到任意稀疏字段。每个特征 $x_i$ 有 embedding $v_i$，二阶交叉为：

$$
\sum_{i<j}\langle v_i,v_j\rangle x_ix_j.
$$

因此即使两个 ID 特征组合在训练中很少出现，也可借助各自 embedding 学到泛化交互。

## 2. DeepFM 的输出

$$
\hat y=\sigma(y_{\mathrm{FM}}+y_{\mathrm{DNN}}).
$$

其中：

$$
y_{\mathrm{FM}}=w_0+\sum_iw_ix_i+\sum_{i<j}\langle v_i,v_j\rangle x_ix_j.
$$

- 一阶项 $w_ix_i$：某特征单独的线性影响；
- 二阶项：显式 feature interaction；
- DNN 分支：将各字段 embedding concat 后经 MLP，学习高阶、非线性组合。

FM 二阶项可通过平方和技巧在 $O(k n)$ 而非枚举 $O(kn^2)$ 的复杂度计算：

$$
\frac12\sum_{f=1}^k\left[
\left(\sum_i v_{i,f}x_i\right)^2-\sum_i v_{i,f}^2x_i^2
\right].
$$

## 3. 为什么要共享 embedding？

FM 与 DNN 看到的是同一组底层 embedding：FM 为 DNN 提供稳定的低阶交叉归纳偏置，DNN 的梯度又能改进 embedding 的高阶表达；相比 Wide&Deep 中 Wide 与 Deep 两套特征工程，端到端程度更高。

## 4. 面试边界

- “显式”指 FM 有明确的两两内积公式，不是说模型直接枚举所有特征组合；
- DNN 虽可学习高阶交叉，但不保证每一种交叉都容易学到；
- 对强序列兴趣问题，DeepFM 不替代 DIN/SASRec/HSTU，而是更适合静态稀疏特征与基础交叉。

## 5. 从输入到输出：模块如何实现？

设输入有 $F$ 个 field，例如 user、item、city、category、hour。离散 field 查询 embedding，连续特征可直接拼接或先映射到 embedding；得到 $[e_1,\ldots,e_F]$。

```text
Sparse / Dense Features
        ├── 一阶线性权重 ───────────────┐
        ├── Shared Embedding → FM 二阶 ─┼→ 相加为 logit → Sigmoid
        └── Shared Embedding → Concat → DNN ─┘
```

FM 分支直接用 embedding 内积计算二阶项；DNN 分支将 $[e_1;e_2;\ldots;e_F]$ 拼接成 $F\times k$ 维输入，经过多层 MLP。训练时三条路径的梯度会共同更新同一张 embedding 表。

## 6. 为什么不是只用 MLP？为什么不是只用 FM？

只用 MLP：理论上可逼近交叉，但在高维稀疏、共现不足时，二阶结构未必容易学到；FM 将“低秩二阶交叉”作为明确归纳偏置，通常更省样本、更稳。

只用 FM：显式二阶强，但无法灵活表示复杂高阶、非线性条件组合。DeepFM 的价值是把低阶稳定性和高阶表达放到同一端到端模型中。

## 7. DeepFM 与常见模型

| 对比 | 核心差异 |
|---|---|
| FM | FM 只到一阶/二阶；DeepFM 额外有 DNN 高阶分支 |
| Wide&Deep | Wide 部分通常依赖人工交叉；DeepFM 的 FM 自动学习二阶交叉 |
| DCN | DeepFM 显式部分是二阶 FM；DCN 用 Cross Network 显式构造更高阶交叉 |
| DIN/SASRec | DeepFM 偏静态字段交叉；后二者重点是行为序列兴趣 |

## 8. 复杂度、风险与常见追问

Embedding 参数量通常最大，约为所有词表大小乘 embedding 维度；FM 二阶约 $O(Fk)$；DNN 成本取决于各层宽度。参数量大不一定 FLOPs 高：大 embedding 表往往首先带来内存、通信和访存压力。

**为什么输出前相加 logit，而不是各自 Sigmoid 后相加？** 因为每个分支都贡献未归一化证据，先相加再一次 Sigmoid 才对应一个统一的二分类 logit；分别 Sigmoid 会改变概率语义。

**共享 embedding 总是更好吗？** 不一定。它降低参数并让低/高阶信号互补，但梯度也可能冲突；强业务差异时可采用独立投影或部分共享。

## 9. 30 秒回答

> DeepFM 把同一套特征 embedding 并行送入 FM 与 DNN：FM 显式学习一阶和低秩二阶交叉，DNN 从拼接 embedding 学习隐式高阶非线性，最终在 logit 层相加后 Sigmoid。它比纯 FM 更有高阶表达、比纯 MLP 更有稀疏二阶归纳偏置，也减少了 Wide&Deep 的人工交叉依赖。
