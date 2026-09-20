# RQ-VAE：从连续商品向量到 Semantic ID

## 1. 做什么，为什么做

Weighted Item2Vec 为每个商品生成连续协同向量 $x_i\in\mathbb R^{64}$。连续向量适合表示相似性，却不能直接作为可生成的离散标签。RQ-VAE 将它压缩成多个离散 code：

$$
x_i \rightarrow z_i \rightarrow [c_{i,1},c_{i,2},c_{i,3}]
$$

这样做有两个优势：

- 把百万级 Item 分类拆成多个 256 类的小分类问题；
- 相似商品有机会共享前缀，形成粗到细的结构化表示。

## 2. Encoder 与 Decoder

Encoder 把64维 Item2Vec 向量压缩到32维 latent：

$$
z=E_\theta(x)
$$

当前结构为：

```text
64维输入 → Linear(64,256) → SiLU → Linear(256,32)
```

Decoder 负责从量化后的 latent 重构原向量：

$$
\hat x=D_\phi(z_q)
$$

```text
32维量化向量 → Linear(32,256) → SiLU → Linear(256,64)
```

## 3. 三级残差量化

三个 codebook 分别记为 $C^{(1)},C^{(2)},C^{(3)}$，每个包含256个32维向量。

初始化残差：

$$
r_0=z
$$

第 (l) 级选择距离当前残差最近的码本向量：

$$
c_l=\arg\min_k\left\|r_{l-1}-e_k^{(l)}\right\|_2^2
$$

然后更新残差：

$$
q_l=e_{c_l}^{(l)},\qquad r_l=r_{l-1}-q_l
$$

三级结束后：

$$
\hat z=q_1+q_2+q_3,\qquad SID=[c_1,c_2,c_3]
$$

含义很直接：第一级拟合主要信息，第二级拟合第一级留下的误差，第三级继续补细节。

距离通过矩阵并行计算：

$$
\|r-e_k\|^2=\|r\|^2+\|e_k\|^2-2r^\top e_k
$$

因此一个 Batch 可以一次得到形状为 `[batch_size, 256]` 的距离矩阵，再沿 code 维执行 `argmin`。

## 4. 为什么需要 STE

`argmin` 是离散选择，几乎处处梯度为0，直接反向传播会截断重建损失到 Encoder 的梯度。项目使用 Straight-Through Estimator：

$$
z_q=z+\operatorname{sg}(\hat z-z)
$$

其中 `sg` 表示 stop-gradient，对应 PyTorch 的 `detach()`：

```python
z_q = z + (z_hat - z).detach()
```

前向传播时：

$$
z_q=\hat z
$$

Decoder 真正使用离散码本向量。反向传播时近似：

$$
\frac{\partial z_q}{\partial z}=1
$$

因此重建梯度可以直接传给 Encoder。STE 不是 `argmin` 的真实导数，而是一个有偏但实用的梯度估计。

## 5. 三个损失函数

### 5.1 重建损失

$$
\mathcal L_{recon}=\|D_\phi(z_q)-x\|_2^2
$$

目的：保证离散 SID 仍保留原商品协同向量中的信息。

- 通过正常反向传播更新 Decoder；
- 通过 STE 更新 Encoder；
- 不直接更新 codebook。

### 5.2 Codebook Loss

$$
\mathcal L_{code}=\|\hat z-\operatorname{sg}(z)\|_2^2
$$

对应代码：

```python
codebook_loss = mse(z_hat, z.detach())
```

目的：让选中的码本向量靠近 Encoder 输出。这里只更新 codebook，不更新 Encoder。

### 5.3 Commitment Loss

$$
\mathcal L_{commit}=\|z-\operatorname{sg}(\hat z)\|_2^2
$$

对应代码：

```python
commitment_loss = mse(z, z_hat.detach())
```

目的：让 Encoder 输出靠近已经选中的 code，避免 latent 在码本之间反复漂移。这里只更新 Encoder。

### 5.4 总损失

$$
\mathcal L=
\mathcal L_{recon}
+\mathcal L_{code}
+\beta\mathcal L_{commit}
$$

当前 $\beta=0.25$。梯度关系如下：

| 损失 | Encoder | Codebook | Decoder | 是否经过 STE |
|---|---:|---:|---:|---:|
| Reconstruction | 更新 | 不更新 | 更新 | 是 |
| Codebook | 不更新 | 更新 | 不更新 | 否 |
| Commitment | 更新 | 不更新 | 不更新 | 否 |

## 6. 曝光容量约束

标准最近邻只关心量化误差，热门商品可能集中到少量 code。项目在 RQ-VAE 训练完成后，为每一级 code 设置累计加权交互容量：

$$
C=\max\left(
\gamma\frac{\sum_i e_i}{K},
\max_i e_i
\right)
$$

其中：

- $e_i$：商品的加权交互曝光代理；
- (K=256)：code 数；
- $\gamma=1.2$：容量系数。

商品按 $e_i$ 从高到低处理，在“剩余容量足够”的 code 中选择距离最近者：

$$
c_i=\arg\min_{k:\ load_k+e_i\le C}d_{ik}
$$

这样可以避免高热商品全部压到同一 code，但会牺牲最近邻最优性。正式实验中，Embedding MSE 从0.01070上升到0.01141，增加约6.6%；各级曝光负载 Gini 为0.122～0.133，没有容量溢出。

## 7. Collision Token

不同商品可能得到相同的三级 code。项目把碰撞定义为：

$$
[c_1,c_2,c_3]_i=[c_1,c_2,c_3]_j
$$

同一碰撞桶内按照 Item ID 稳定排序，追加第四级 token：

```text
商品A：[12, 47, 9] → [12, 47, 9, 1]
商品B：[12, 47, 9] → [12, 47, 9, 2]
```

容量约束前碰撞商品率为8.74%，加入容量约束后为18.18%；最大碰撞桶从160降到92。说明容量约束改善了热点桶尾部，但不保证降低总碰撞率。追加 Collision Token 后最终 SID 唯一。

## 8. 一分钟回答

> RQ-VAE 的输入是 Item2Vec 学到的64维商品协同向量。Encoder 先压缩到32维 latent，三个256大小的 codebook 再依次量化当前残差，最终三个 code 组成基础 Semantic ID。训练包含重建损失、codebook loss 和 commitment loss；因为最近邻 argmin 不可导，我用 STE 让重建梯度穿过量化操作更新 Encoder。训练完成后再施加加权交互容量约束平衡 code 负载，并为三级 code 冲突的商品追加 Collision Token，保证 SID 能唯一映射回 Item。容量约束会增加量化误差，因此本质上是表示精度和负载均衡之间的 trade-off。
