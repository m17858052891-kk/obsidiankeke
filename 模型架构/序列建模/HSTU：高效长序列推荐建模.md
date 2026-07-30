---
tags: [模型架构, 序列建模, HSTU, Transformer, 推荐系统, 面试]
---

# HSTU：高效长序列推荐建模

> HSTU（Hierarchical Sequential Transduction Unit）是面向工业推荐行为序列的 Transformer 变体。它要回答的并不是“如何完全消除注意力的二次复杂度”，而是：当序列很长、用户长度不一、batch 很大时，如何让**整个 Block**而非只有 Attention 更高效，同时保留行为间的细粒度交互。

## 0. 面试时先给结论

> 与标准 Transformer 相比，HSTU 的关键变化有三点：第一，用带相对时间/位置 bias 的 **pointwise attention**，以 SiLU 型逐点激活替代 Softmax 的“全行归一化竞争”；第二，用**门控的逐元素变换**替代重型 FFN，让 Attention 聚合结果和当前 token 的内容按维度相乘、筛选；第三，针对推荐中的变长历史使用 jagged/ragged 表示和融合算子，少算 padding、少做中间张量读写。它仍可能保留 $O(L^2)$ 的 token 两两交互，因此优势是端到端效率和工业可扩展性，不应说成“Attention 变成线性复杂度”。

---

## 1. 它解决的到底是什么问题？

以用户最近 $L$ 个行为为例，每个行为是一个 token，隐藏维度为 $D$。

标准 Transformer 单层的主要成本可以粗略写为：

$$
O(L^2D) \quad \text{（注意力的 token 两两交互）}
$$

$$
O(LD^2) \quad \text{（Q/K/V/输出投影和 FFN 的逐 token 大矩阵乘）}。
$$

在推荐中，后者常常也很贵：

- 一个用户可能只有 5 条行为，另一个用户有 500 条；若 pad 到 500，前者的大量计算完全无效；
- 候选物品多、batch 大时，FFN 的升维—降维会带来很大的激活显存；
- 真正的耗时不仅是 FLOPs，还包括中间张量的显存读写、多个小 kernel 的调度以及 padding。

所以 HSTU 的设计目标是：**保留“历史之间可以相互匹配”的能力，但减少 Softmax、宽 FFN、padding 和算子边界带来的系统开销。**

---

## 2. HSTU 和 Transformer 到底不同在哪？

| 部分 | 标准 Pre-LN Transformer | HSTU 的典型做法 | 直觉 |
|---|---|---|---|
| 输入顺序 | token embedding + 绝对/相对位置编码 | 行为 token + 时间/位置等相对 bias | 推荐里“隔了多久、相隔几次行为”往往比绝对第几个位置更重要 |
| 注意力权重 | $\operatorname{Softmax}(QK^T/\sqrt d)$ | 对分数逐点激活，如 $\operatorname{SiLU}(QK^T+b)$ | 不强制同一 query 对所有历史的权重和为 1 |
| 注意力语义 | 历史 token 彼此竞争有限的注意力预算 | 每个历史可独立贡献正/负强度 | 多条相似行为同时出现时，强度可以累积 |
| FFN | $W_2\sigma(W_1x)$，通常先扩宽再压回 | Attention 输出与内容 gate 逐元素相乘后再投影 | 用当前 token 决定“聚合到的信息哪些维度该通过” |
| 变长序列 | 通常 pad 成矩形张量并 mask | jagged/ragged（不规则）序列表示 | 不为不存在的历史做 QKV、FFN 或 attention |
| 工程实现 | 多个独立 projection、norm、dropout、激活 | 尽量融合 projection / norm / dropout / attention | 减少 kernel launch 和读写中间激活 |

### 2.1 最重要的区别：Softmax Attention vs. Pointwise Attention

标准注意力对第 $i$ 个 token：

$$
s_{ij}=\frac{q_i^\top k_j}{\sqrt d}+b_{ij},\qquad
\alpha_{ij}=\frac{e^{s_{ij}}}{\sum_{t\le i}e^{s_{it}}},\qquad
h_i=\sum_{j\le i}\alpha_{ij}v_j.
$$

其中 $j\le i$ 表示因果 mask：当前行为只能看自己及更早的历史。Softmax 的特点是：同一行的权重和必定为 1，因此历史行为之间是在竞争一份固定预算。

HSTU 可概念化为：

$$
s_{ij}=\frac{q_i^\top k_j}{\sqrt d}+b_{ij},\qquad
a_{ij}=\operatorname{SiLU}(s_{ij}),\qquad
h_i=\sum_{j\le i}a_{ij}v_j.
$$

这叫 pointwise（逐点）并不是说“没有两两匹配”；$q_i^\top k_j$ 仍在计算 $i,j$ 的相关性。它指的是**对每一个分数独立做激活**，不再通过 Softmax 与同一行其余 key 做归一化耦合。

例如，用户先后看了三次“跑鞋”，当前又在看运动袜：

- Softmax：三次跑鞋的权重会彼此竞争，总和只能是 1；
- Pointwise：三次高相关行为都可以形成较强信号并累积；
- 后续的 Norm 和 Gate 负责控制数值尺度及哪些维度真正输出，而不是让 Softmax 承担所有稳定性工作。

> 注意：SiLU 不是概率，也不会让权重和为 1；它允许小负值。因此不能把它说成“用 SiLU 近似 Softmax”。更准确地说，是换了一种聚合归纳偏置。

### 2.2 相对时间/位置 bias 加在哪里？

它加在注意力分数上、激活之前：

$$
b_{ij}=f(\Delta \text{position}_{ij},\Delta \text{time}_{ij},\text{行为类型}_{i,j},\ldots).
$$

最终是 $\operatorname{SiLU}(q_i^\top k_j/\sqrt d+b_{ij})$。例如“30 秒前点击”和“30 天前点击”，即使 item embedding 相似，也应得到不同的匹配强度。实践中 $f$ 可以是相对位置 bucket、时间差 bucket 的 embedding，或其可学习映射；具体特征取决于业务实现。

---

## 3. 一个 HSTU Block 怎样从输入走到输出？

下面是便于面试和实现理解的**概念版**。论文/开源实现会按 multi-head、维度切分、融合 kernel 改写张量细节，但数据流不变。

```text
输入行为序列 X
  ↓  Pre-Norm
U = LayerNorm(X)
  ↓  一次或少数几次融合线性投影
得到 Q、K、V，以及门控向量 G
  ↓
分数 S = QKᵀ / √d + causal mask + relative time/position bias
  ↓
A = SiLU(S)                  # pointwise attention
H = A V                       # 由历史 value 聚合
  ↓
Z = Norm(H) ⊙ G              # attention 信息 × 当前 token 的内容门控
  ↓
Y = X + W_o(Z)               # 输出投影 + 残差
```

可以把它拆成五个模块理解。

### 模块 A：行为 token 输入与序列组织

第 $i$ 条行为通常不仅是 item ID：

$$
x_i=e_{\text{item}_i}+e_{\text{action}_i}+e_{\text{context}_i}+\cdots
$$

例如一次电商行为可包含 `点击/加购/购买`、商品 ID、类目、价格桶、发生时间等。HSTU 的输入仍是 $[B,L,D]$ 的 token 表示，只是工业实现更倾向把不同用户的有效 token 拼接成一个 jagged 张量，并保存每个用户的起止 offset。

**为什么这一步重要？** 因为推荐序列不等长：若用户 A 有 10 条、用户 B 有 200 条，传统 padding 会让 A 的 190 个空位仍经过投影和 FFN；jagged 表示只存 210 个真实 token。

### 模块 B：Pre-Norm 与 Q/K/V/Gate 投影

先归一化：

$$
U=\operatorname{LayerNorm}(X).
$$

接着从 $U$ 投影出：

$$
Q=UW_Q,\quad K=UW_K,\quad V=UW_V,\quad G=\phi(UW_G).
$$

- $Q_i$：第 $i$ 个当前行为“要从历史里找什么”；
- $K_j$：第 $j$ 个历史行为“我是什么、能被什么 query 匹配”；
- $V_j$：一旦被选中，要向后续传递的内容；
- $G_i$：当前 token 的内容门，决定聚合结果的哪些通道有用。

工程中它们经常由一次 fused projection 一起算出，而不是代码里真写四次 `Linear`。这样做不改变数学含义，但能少一次次读取 $U$、少产生临时张量。

### 模块 C：Causal Pointwise Attention

先计算所有合法历史对：

$$
S_{ij}=\frac{Q_iK_j^\top}{\sqrt{d_h}}+b_{ij},\quad j\le i.
$$

然后不做行归一化，而是逐元素激活：

$$
A_{ij}=\operatorname{SiLU}(S_{ij})=S_{ij}\cdot\operatorname{sigmoid}(S_{ij}).
$$

最后聚合 value：

$$
H_i=\sum_{j\le i}A_{ij}V_j.
$$

多头时，每个 head 有自己的 $Q,K,V$ 子空间，分别做上述计算，再拼接或投影回模型维度。这一点与 MHA 相同。

**为什么要有 causal mask？** 如果训练目标是“预测下一次点击/购买”，第 $i$ 个位置绝不能看 $i+1$ 的未来行为，否则离线指标会虚高，线上无此信息，产生特征穿越。

### 模块 D：Norm + Gate，替代重型 FFN 的核心

标准 Transformer 在 Attention 后另走一条大 FFN：

$$
\operatorname{FFN}(x)=W_2\sigma(W_1x),\quad W_1:D\to rD,\quad r\text{ 常取 }4.
$$

它很强，但中间会产生 $L\times rD$ 的大激活。HSTU 采用的核心思想是：先得到历史聚合 $H_i$，再用当前 token 产生的 gate 对它逐维调制：

$$
Z_i=\operatorname{Norm}(H_i)\odot G_i.
$$

其中 $\odot$ 是逐元素乘法。

可以这样理解：

- $H_i$ 回答：“历史里汇总出了哪些兴趣/信息”；
- $G_i$ 回答：“结合当前行为，我此刻允许哪些特征维度通过”；
- 若 $G_i$ 某维很小，该维的历史信号被抑制；若某维大，则放大该信号。

最后再输出投影并残差：

$$
Y=X+W_oZ.
$$

这不是和 FFN 严格等价：FFN 是通用的 token 内非线性变换，理论表达能力更直接；HSTU 的 gate 是**内容条件化的逐维选择**，它借助 attention 的上下文结果完成更轻量的表达。在推荐的序列任务中，这种取舍通常很划算，但若任务高度依赖复杂的 token 内组合，仍需用实验验证是否需要保留/加回更强 FFN。

### 模块 E：残差、堆叠与层级语义

输出 $Y$ 通过残差送入下一层。浅层通常捕捉近邻行为和局部共现；层数增加后，token 表示会反复进行“匹配—聚合—门控”，可形成更高阶的序列兴趣表示。最终可取最后一个有效位置、池化表示，或将每个位置表示用于 next-item / ranking head。

“Hierarchical”不应机械理解成一定有显式的树。它更强调多层 sequential transduction：不同层逐步把原始行为转化为更抽象的兴趣表示；具体的层数、头数、时间特征和输出头按任务配置。

---

## 4. 为什么它更适合长行为序列？优点分别来自哪里？

### 4.1 少 padding：收益与用户长度分布直接相关

假设一个 batch 有两位用户，长度分别是 10 和 200：

- pad 后按 $B\times L=2\times200=400$ 个位置进行逐 token 投影；
- jagged 后只处理 $10+200=210$ 个真实位置。

仅投影、Norm、Gate、FFN 这类线性于 token 数的部分，就接近减少 47.5% 的无效位置。用户长度长尾越明显，收益越大。

### 4.2 减轻 $O(LD^2)$：不只盯着 $O(L^2D)$

很多人只记得 Attention 的二次复杂度。但当 $D$ 较大、$L$ 不是极端大时，FFN 和投影的 $O(LD^2)$ 同样显著。HSTU 将表示变换与 gate 更紧密地结合，避免每层都使用一个宽度为 $rD$ 的独立 FFN 路径，能减少参数、激活和带宽压力。

### 4.3 Pointwise attention 的系统与建模收益

- **建模上**：多个相关历史可以同时累积，不被“总权重为 1”限制；
- **实现上**：避免 Softmax 的 reduction（求行最大值、求和、归一化）及相关中间状态，便于融合；
- **代价/风险**：不归一化意味着数值规模更依赖 Norm、初始化和训练稳定性，因此不能简单把 Softmax 删掉而不配套设计。

### 4.4 Fused kernel：减少“显存搬运”而非只减少 FLOPs

GPU 训练不总是算力受限，也常受限于带宽：一个模块先写出大张量，下一个模块又读入它，会很慢。把投影、变形、多头计算、激活、dropout 等尽量融合，可减少中间结果落到显存的次数。HSTU 的工业价值很大一部分来自这类系统协同，而非单一数学公式。

---

## 5. 复杂度：面试中怎样说才严谨？

### 结论

> 若采用 dense 的全量 token-to-token HSTU attention，$QK^T$ 和 $AV$ 仍需要 $O(L^2D)$；因此 HSTU 不等价于线性 Attention。它主要优化 $O(LD^2)$ 的线性层/FFN、变长 padding 与实际 kernel 效率。只有再结合窗口、稀疏模式、分块或其他 attention 近似时，二次项才会进一步下降。

### 何时收益大？

- 用户序列长度差异大，padding 浪费严重；
- 推荐训练 batch 大、候选多，激活与带宽是瓶颈；
- 模型维度较大，宽 FFN 的成本显著；
- 有成熟 jagged/fused kernel 支持。

### 何时不一定占优？

- 序列都很短且长度接近，ragged 的调度复杂度未必值得；
- 任务需要很复杂的 token 内非线性组合，轻量 gate 的表达不一定足够；
- 没有高效 kernel，仅用普通框架拼算子，理论结构优势可能被工程开销抵消。

---

## 6. 与 Transformer 的逐句面试问答

### Q1：HSTU 是把 Transformer 的 Softmax 换成 SiLU 吗？

不是。换 Softmax 是其中一环。完整 Block 还包括相对时间/位置 bias、内容门控替代重 FFN、变长 jagged 表示和融合实现。只换激活函数通常不能复现它的效率与效果。

### Q2：HSTU 为什么不需要 Softmax？

它不是“不需要稳定性”，而是把稳定性分散到分数设计、Norm、门控和训练配置中。推荐里多个历史行为同时强相关很常见，不强制权重和为 1 可以保留“兴趣数量/强度”的信息。代价是尺度不再自动归一化，所以必须认真处理归一化和数值稳定性。

### Q3：HSTU 的 Gate 是从哪里来的？

由当前位置归一化后的表示 $U_i$ 经可学习投影得到，如 $G_i=\phi(U_iW_G)$。它不是从未来拿信息；训练和推理时都只依赖当前 token 本身及此前层已因果聚合出的表示。

### Q4：Gate 能完全替代 FFN 吗？

不能说数学上完全等价。FFN 有更通用的逐 token 非线性映射能力；Gate 以更轻量的逐维条件选择为主。HSTU 的主张是对于大规模推荐序列，这个效率—表达力折中很有效，而不是所有任务中 Gate 必胜。

### Q5：为什么 HSTU 对长序列更快却仍有 $L^2$？

因为端到端耗时不只由注意力二次项决定。它减少了 padding、宽 FFN、投影/激活的内存访问，并采用融合算子。若 $L$ 无限增大，dense 两两交互仍是瓶颈；要进一步扩到更长序列，还需要窗口化、稀疏化或检索式记忆等配套方案。

---

## 7. 30 秒与 90 秒回答模板

### 30 秒

> HSTU 是给工业推荐长行为序列设计的高效 Transformer 变体。它用相对时间/位置 bias 的 pointwise attention 替代 Softmax attention：分数逐点过 SiLU，不强制所有历史竞争总和为 1；再用当前 token 生成的 gate，逐维筛选 attention 聚合结果，替代重型 FFN。同时通过 jagged 变长序列和融合 kernel 减少 padding、激活和访存。它不是把 $O(L^2)$ 彻底消掉，而是优化完整 Block 的端到端成本。

### 90 秒

> 标准 Transformer 既有 $O(L^2D)$ 的注意力，也有 QKV、输出投影和宽 FFN 带来的 $O(LD^2)$；在推荐中用户序列长度长尾明显，padding 和 FFN 激活常是实际瓶颈。HSTU 先对 token 做 Pre-Norm，联合投影得到 Q、K、V 和 gate；对 $QK^T$ 加上因果 mask、相对时间/位置 bias 后，用 SiLU 型 pointwise 激活而非 Softmax，再聚合 V。随后将聚合结果归一化并与当前 token 的 gate 逐元素相乘，最后输出投影加残差。这样一方面多个相关历史可同时累积，另一方面不用独立的大 FFN；配合 jagged 和 fused kernel，端到端更适合大 batch 的变长行为序列。但 dense attention 的配对仍是二次项，所以不能夸张成线性 Attention。

