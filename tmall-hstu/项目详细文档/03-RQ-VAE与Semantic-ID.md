# 03 RQ-VAE 风格量化与 Semantic ID

## 当前实现的准确定位

当前模块应称为 **RQ-VAE-style deterministic residual quantization autoencoder**。它有 Encoder、多个残差 Codebook、Decoder、重构损失、codebook loss 和 commitment loss，但没有标准 VAE 的 Gaussian posterior、随机采样和 KL divergence。

## 输入和残差量化

输入是 Item2Vec 商品向量 $x_i$，Encoder 得到 $z_e$。令 $r_0=z_e$，第 $l$ 级 codebook 选择最近 code：

$$
k_l=\arg\min_k\|r_l-C_l[k]\|_2^2,
\quad q_l=C_l[k_l],
\quad r_{l+1}=r_l-q_l
$$

最终量化向量为：

$$
z_q=\sum_l q_l
$$

各级索引拼成基础 SID。Decoder 用 $z_q$ 重构原始 Item2Vec 向量。

## 为什么使用残差量化

单级量化要求一个 code 直接表达整个向量，codebook 容量和冲突率之间矛盾。残差量化先表达粗粒度部分，再用后续 code 修正残差；多级小 codebook 的组合拥有更大的地址空间，也适合逐级自回归生成。

树模型或 Hierarchical KMeans 可以构造层级地址，适合作为 baseline，但普通树不天然按照 latent 残差量化，也可能破坏协同向量的几何结构，所以不是 RQ 的等价替代。

## 损失函数和不可导处理

### 记号

对一个商品向量 $x$，Encoder 输出连续 latent $z_e=E_\theta(x)$。令第 $l$ 级量化前的残差为 $r_l$，选中的 code 为 $q_l=C_l[k_l]$，其中 $r_0=z_e$：

$$
k_l=\arg\min_k\lVert r_l-C_l[k]\rVert_2^2,
\qquad
r_{l+1}=r_l-q_l,
\qquad
z_q=\sum_{l=0}^{L-1}q_l.
$$

以下的 $\operatorname{sg}[\cdot]$ 表示 stop-gradient：前向值不变，但反向梯度为零。它用于指定“哪一侧参数接收该项梯度”。

### 总损失

$$
\mathcal{L}_{RQ}
=\lambda_{rec}\mathcal{L}_{rec}
+\lambda_c\mathcal{L}_{codebook}
+\beta\mathcal{L}_{commit}.
$$

这里没有标准 VAE 的 KL loss：当前实现没有 Gaussian posterior 或随机采样，不能把 commitment loss 误称为 KL 正则。

### 1. 重构损失：让离散 code 保留 Item2Vec 语义

Decoder 将量化向量映射回原始向量空间：

$$
\hat x=D_\psi(z_q^{ST}).
$$

最常见的重构损失是 MSE：

$$
\mathcal{L}_{rec}=\lVert x-\hat x\rVert_2^2.
$$

若 Item2Vec 在使用前已经 L2 归一化，余弦重构往往更符合“保留协同相似方向”的语义：

$$
\mathcal{L}_{rec}^{cos}=1-
\frac{x^\top\hat x}{\lVert x\rVert_2\lVert\hat x\rVert_2+\epsilon}.
$$

也可以组合使用 $\mathcal{L}_{rec}+\gamma\mathcal{L}_{rec}^{cos}$。选择取决于下游更在意向量长度还是近邻/夹角；不能只因 loss 更低就认定 Semantic ID 更好，还应检查近邻商品一致性和下游推荐指标。

### 2. Codebook loss：把 code 向残差中心移动

每一级 codebook 应向当前分配给它的残差靠近：

$$
\mathcal{L}_{codebook}
=\sum_{l=0}^{L-1}
\left\lVert
\operatorname{sg}[r_l]-q_l
\right\rVert_2^2.
$$

在这一项中，$r_l$ 被 stop-gradient，故梯度只更新被选中的 $C_l[k_l]$（以及其所属 codebook），不更新 Encoder。直觉上这相当于在线 K-Means 的“更新聚类中心”：被分配到某个 code 的残差会把该 code 拉向自己。

若没有这一项，codebook 很难学到代表性向量；若只靠这一项而不约束 Encoder，Encoder latent 可能不断漂移，迫使 codebook 疲于追赶。

### 3. Commitment loss：让 Encoder 愿意贴近离散 code

对每一级残差，约束 Encoder 产生的表示靠近已选 code：

$$
\mathcal{L}_{commit}
=\sum_{l=0}^{L-1}
\left\lVert
r_l-\operatorname{sg}[q_l]
\right\rVert_2^2.
$$

这里 $q_l$ 被 stop-gradient，梯度只流向 $r_l$、Encoder 和其前序连续表示，不更新 codebook。它避免 Encoder 随意输出远离所有 code 的值，再依靠 Decoder 硬重构。

系数 $\beta$ 是关键权衡：

- $\beta$ 太小：Encoder 与 codebook 脱节，量化误差大、code 不稳定；
- $\beta$ 太大：Encoder 被过强地拉向当前 code，表达能力和重构质量可能下降，也可能加剧少数 code 垄断；
- 应同时观察重构误差、每级使用率/熵、残差范数和下游检索或生成效果选取，而不是只看训练 loss。

### 4. 为什么 residual quantization 要逐级计算这些损失

第 0 级 code 负责解释 $z_e$ 的粗粒度部分；第 1 级 code 学 $r_1=z_e-q_0$ 的剩余误差；后续级继续解释尚未被编码的部分。因此 codebook 与 commitment loss 都应按级作用于各自的 $r_l$，而不是让所有 code 都直接拟合同一个 $z_e$。否则后续 codebook 会学到与首级重复的信息，残差分工失效。

常用的级别加权形式为：

$$
\mathcal{L}_{codebook}=
\sum_l\alpha_l
\left\lVert\operatorname{sg}[r_l]-q_l\right\rVert_2^2,
\qquad
\mathcal{L}_{commit}=
\sum_l\alpha_l
\left\lVert r_l-\operatorname{sg}[q_l]\right\rVert_2^2.
$$

通常先令 $\alpha_l=1$；若观察到深层残差过小、深层 code 不使用，再考虑调整权重，而非一开始就人为偏向某一层。

### 5. `argmin` 不可导时，STE 如何让重构梯度回到 Encoder

最近邻选择 $k_l=\arg\min_k\lVert r_l-C_l[k]\rVert^2$ 是离散操作，不能对 index 直接反向传播。前向时必须使用真实的量化向量 $z_q$；反向时常用 Straight-Through Estimator（STE），把量化层近似成恒等映射：

$$
z_q^{ST}=z_e+
\operatorname{sg}[z_q-z_e].
$$

它满足：

$$
z_q^{ST}=z_q\quad\text{（前向）},
\qquad
\frac{\partial z_q^{ST}}{\partial z_e}=I
\quad\text{（反向近似）}.
$$

对应实现是：

```python
z_q_st = z_e + (z_q - z_e).detach()
x_hat = decoder(z_q_st)
```

因此梯度分工是：

```text
L_rec      → Decoder；经 STE 近似回传到 Encoder
L_codebook → 仅更新被选中的各级 codebook vector
L_commit   → 仅更新 Encoder / 连续残差路径
```

严格说，STE 是有偏的梯度估计：它并没有给 `argmin` 求到真实导数，而是用“量化层在反向近似恒等”的工程近似换取可训练性。这也是为什么 codebook/commitment 两项不可省略。

### 6. 一个 batch 的训练流程

1. 计算 $z_e=E_\theta(x)$，初始化 $r_0=z_e$；
2. 对每一级：计算到该级 codebook 的距离，`argmin` 选 $k_l$，取 $q_l$，更新 $r_{l+1}=r_l-q_l$；
3. 求和得到 $z_q=\sum_lq_l$，构造 $z_q^{ST}$，Decoder 得到 $\hat x$；
4. 计算重构、逐级 codebook、逐级 commitment loss 并加权求和；
5. 反传：Decoder/Encoder/codebook 按上述梯度分工更新；
6. 定期记录每一级的 perplexity、活跃 code 数、top-code 占比、残差范数和重构/下游指标。

### 7. EMA codebook 更新是另一种实现，不是额外损失

有些 VQ/RQ-VAE 实现不通过 $\mathcal{L}_{codebook}$ 的梯度更新 codebook，而是对每个 code 维护分配次数与残差和的指数滑动平均（EMA），再把 code 更新为加权均值。它实现的仍是“code 向被分配残差中心移动”的目标。

若采用 EMA，通常：

- codebook 不接收 optimizer 的 codebook-loss 梯度；
- Encoder 仍通过 STE 的重构梯度和 commitment loss 学习；
- 要处理从未被分配的 dead code，例如从近期 encoder 输出中重置。

因此面试时应先确认代码采用的是 gradient-based codebook loss 还是 EMA；两者不要叠加后再重复解释为两套独立的更新动机。

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
