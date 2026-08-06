---
tags: [PCVRHyFormer, Token化, Attention, 特征工程, 序列建模, 面试]
---

# 静态特征 Token 化：原理、实现与 PCVRHyFormer 中的作用

> 这里的 Token 化不是 NLP 里“把句子切成词”。在推荐模型中，它指的是：把一个原始字段或一组语义紧密的字段，编码成一个固定维度的向量，并保留它来自哪个字段、属于什么类型。这个向量就是可以送入 Attention 的 token。

## 1. 先建立直觉：什么叫把特征变成 Token？

假设一个广告样本包含：

```text
用户：上海、活跃用户、偏好运动
候选商品：跑鞋、运动类目、价格 399
请求上下文：晚 9 点、首页推荐、无线网络
历史：点击过运动袜、购买过跑步装备、浏览过耳机
```

传统 MLP 常见做法是：每个离散字段查 embedding，全部拼起来：

$$x=[e_{city};e_{activity};e_{item};e_{category};e_{price};\ldots],$$

再送进 MLP。模型的第一层就开始混合所有字段。

Token 化则把字段或字段组组织成一组有身份的向量：

```text
[用户画像 Token, 候选商品 Token, 请求上下文 Token, 价格/统计 Token, ...]
```

每个 token 都是 $D$ 维，但它携带 `field/type` 信息。随后 Attention 可以学习“候选 token 应该读取用户 token 的哪部分、应匹配历史中的哪些行为”。

**一句话：Concat 是把所有特征提前揉成一根向量；Token 化是先保留信息块的边界，再让模型根据样本动态建立信息块之间的关系。**

### 1.1 Token 化是不是 Embedding 后再拼接？

可以这样理解，但需要区分“怎样得到向量”和“怎样组织向量”两个问题。

第一步是把不同类型的原始字段编码到统一维度 $D$。这个过程不一定都使用 Embedding：

- 离散 ID、类别字段通常查 Embedding 表；
- 连续数值通常先归一化，再通过 $Wx+b$ 投影；
- 多个连续字段可以先组成向量，再经过 Linear 或小 MLP；
- 多值集合或行为组可以先做 sum、mean 或 attention pooling；
- 已经是稠密表示的特征，也可以再通过投影层对齐维度。

统一写成：

$$
t_i=\operatorname{Project}_i(x_i)\in\mathbb R^D,
$$

其中 $\operatorname{Project}_i$ 可以是 Embedding、线性层、小 MLP 或 Pooling。随后通常还会加入字段身份：

$$
\tilde t_i=t_i+e_{\text{type}(i)}.
$$

因此，**成为 Token 的关键不是必须使用 Embedding，而是得到一个有明确字段或实体身份的 $D$ 维向量。**

第二步才是把这些向量组织起来。普通 Concat 与 Token 化都可能在代码里调用 `torch.cat`，真正的区别是有没有保留 Token 轴。

假设用户、候选、上下文三个表示都是 $D$ 维。普通 Concat 沿特征维拼接：

```python
x = torch.cat([user_emb, item_emb, context_emb], dim=-1)
# [B, 3 * D]
```

对应形状：

$$
[B,D]+[B,D]+[B,D]\longrightarrow[B,3D].
$$

随后送入 MLP：

$$
h=\sigma(Wx+b).
$$

把 $W$ 按输入字段拆开，可以写成：

$$
h=\sigma(W_u e_u+W_i e_i+W_c e_c+b).
$$

这里所谓“固定混合”，是指模型使用训练得到的一套全局共享矩阵，在固定字段位置上完成第一次混合；并不是说 MLP 对所有样本输出相同，也不是说 MLP 不能学习非线性交互。

Token 化则沿 Token 维堆叠：

```python
tokens = torch.stack([user_token, item_token, context_token], dim=1)
# [B, 3, D]
```

也可以写成：

```python
tokens = torch.cat(
    [
        user_token.unsqueeze(1),
        item_token.unsqueeze(1),
        context_token.unsqueeze(1),
    ],
    dim=1,
)
# [B, 3, D]
```

对应形状：

$$
[B,D]+[B,D]+[B,D]\longrightarrow[B,3,D].
$$

虽然代码也可能使用 `cat`，但没有把三个向量展平成 $3D$ 维，用户、候选和上下文仍是三个独立 Token。Attention 因而可以让候选 Token 作为 Query，根据当前样本动态计算它对用户、上下文和历史 Token 的读取权重。

| 对比项 | 普通 Concat | Token 化 |
|---|---|---|
| 编码方式 | Embedding、线性投影等均可 | Embedding、线性投影等均可 |
| 最终形状 | $[B,N\times D]$ | $[B,N,D]$ |
| 字段边界 | 主要依赖长向量中的固定位置 | 由独立 Token 和 type/field 标识保留 |
| 第一次交互 | MLP 使用全局共享参数整体混合 | Attention 按当前样本动态分配读取权重 |
| 后续处理 | MLP、Cross Network 等 | Attention、Transformer，再 Pooling/Concat + MLP |

所以最准确的总结是：

> Token 化先用 Embedding、$Wx+b$、小 MLP 或 Pooling 把不同字段变成统一的 $D$ 维表示，再沿 Token 轴组成 $[B,N,D]$；普通 Concat 则把它们展平成 $[B,N\times D]$。两者都可能使用拼接操作，但只有前者保留了可供 Attention 逐 Token 读取的实体边界。

---

## 2. 原始字段怎样变成一个 Token？

Token 的形状通常是 $t_i\in\mathbb R^D$。不同类型特征不能粗暴用同一种编码，但最后可以投影到共同维度 $D$。

### 2.1 离散 ID / 类别字段

例如城市、类目、商品 ID：

$$e_i=\operatorname{Embedding}_i(x_i),\qquad t_i=e_i+e_{type(i)}.$$

`Embedding_i` 让不同取值有不同语义向量；$e_{type(i)}$ 是 field/type embedding，告诉模型“这是城市”还是“这是商品类目”。

### 2.2 连续数值 / 统计字段

例如价格、曝光次数、近 7 天 CTR、距离：先做缺失处理和归一化，再映射：

$$t_i=W_i\cdot \operatorname{Norm}(x_i)+b_i+e_{type(i)}.$$

也可先分桶，用 bucket embedding；数值特征很复杂时可用小 MLP。关键不是一定用线性层，而是**先处理尺度和缺失值，再映射到 token 维度**。

### 2.3 多值字段

例如用户近期兴趣类目集合：先对集合内 ID embedding 做 sum/mean/attention pooling，再加入字段类型：

$$t_{interest}=\operatorname{Pool}(e_{c_1},\ldots,e_{c_m})+e_{type}.$$

它是一条静态特征 token；若希望保留集合中每个元素的细粒度顺序与关系，则应将它们拆成序列 token，而不是强行池化成一个。

### 2.4 一组语义相关的字段

工程中 token 不必严格对应“一列特征”。例如候选 item ID、类目、价格、商家等可以先融合为一个“候选 Token”；用户画像字段可以融合为一个“用户 Token”。分组原则是：**组内信息天然共同描述一个实体，组间希望由模型显式交互。**

---

## 3. 为什么不同类型的 Token 能放在一起？

“同一维度”只代表它们有共同的计算接口，并不代表语义相同。

设静态 token 是 $T_s=[t_1,\ldots,t_F]$，历史序列 token 是 $H=[h_1,\ldots,h_L]$。二者都投影到 $D$ 维后，Attention 会再用不同参数生成：

$$Q=T_sW_Q,\qquad K=HW_K,\qquad V=HW_V.$$

候选 token $t_{candidate}$ 产生 query；每条历史 $h_j$ 产生 key/value。匹配分数：

$$s_j=\frac{q_{candidate}^Tk_j}{\sqrt d}.
$$

这个点积不是在问“跑鞋 token 和点击 token 是否是一种东西”，而是在训练目标监督下学习：**当前候选为跑鞋时，哪条历史可作为有用证据？**

这和人看病很像：年龄、化验指标、既往病史原始含义不同，但医生可以把它们共同用于判断风险；它们被共同决策，不代表被当作同一种信息。

### 3.1 谁让它们对齐？

不是人工规定“第 17 维都表示运动兴趣”，而是 CVR 的监督信号反向传播：如果“候选跑鞋 + 历史运动装备 + 晚间访问”常对应转化，投影层和 Attention 参数会逐渐形成有利于该任务的兼容关系。

因此说“映射到同一空间”要严谨：它是一个**任务驱动的可学习关系空间**，不是已经具有固定可解释坐标轴的通用语义空间。

---

## 4. 静态 Token 与行为序列 Token 的职责不同

| 类型 | 表示什么 | 是否有天然顺序 | 在 PCVR 中常见作用 |
|---|---|---|---|
| 静态 Token | 当前样本的用户、候选、请求、上下文、统计状态 | 通常没有 | 提供“现在是谁、看到什么、处在什么条件” |
| 序列 Token | 一次历史点击/购买/浏览等事件 | 有时间顺序 | 提供“过去做了什么、兴趣如何演化” |

静态 Token 一般不该套用行为序列的位置编码。它们没有“第 1 个字段先发生、第 2 个字段后发生”的时间语义；更合适的是 field/type embedding。为了让模型区分固定槽位，可加入 slot embedding，但它表达的是**字段身份**，不是时间顺序。

行为序列 Token 则需要行为类型、相对位置、时间间隔等编码，并需要 padding mask 与防穿越约束。

---

## 5. PCVRHyFormer 中是如何组织的？

项目中将用户、候选 item、请求上下文等特征压缩成 8 个静态 Token；四路行为历史先按域独立编码为序列表示。这样组织的原因不是“所有东西都变成 token 更先进”，而是对应两类不同结构：

```text
静态侧：实体/上下文间的字段交互
用户、候选、请求、统计 → 8 个 static tokens

序列侧：域内行为的时间演化
每一路历史 → sequence encoder + 时间/位置表示

融合侧：当前候选条件下，从多域历史中读取兴趣证据
候选相关 Query → DIN / Query Generator → HyFormer / Cross-Attention
```

### 一个完整例子

当前样本候选是“跑鞋”：

1. 候选 Token 编码跑鞋的 ID、类目、价格等；用户 Token 编码当前用户画像；请求 Token 编码晚 9 点、入口等；
2. 历史序列中含有“浏览运动袜、购买跑步装备、浏览耳机”；序列编码器同时看到顺序与时间；
3. 候选跑鞋形成 Query，和历史 token 做软匹配；运动袜/跑步装备的分数更高，耳机更低；
4. 聚合后的兴趣表示再与静态用户/上下文 token 融合，预测此刻 CVR。

如果候选变为“耳机”，**用户和历史没有变**，但候选 Query 改变，模型可以重新激活耳机历史而降低运动行为的重要性。这就是“静态候选条件 + 动态历史证据”共同拟合的含义。

---

## 6. Token 化相比 Concat 到底多了什么？

### 6.1 Concat + MLP 的计算方式

$$h=\operatorname{MLP}([e_1;e_2;\ldots;e_F]).$$

MLP 当然能学习字段交叉，但所有字段在第一层被固定地线性混合。它没有显式机制表示“本样本中候选应多读用户兴趣，另一个样本中应多读价格和上下文”。若要实现这种选择性，MLP 需要靠更多层和数据自己间接学到。

### 6.2 Token + Attention 的计算方式

$$\operatorname{Attn}(Q,K,V)=\operatorname{Softmax}(QK^T/\sqrt d)V.$$

每个 Query 都可对不同 Key 分配不同权重。候选 Token 可有选择地读取用户、上下文和历史；用户 Token 也可读取候选。这个“按样本动态路由信息”的结构，就是 Token 化配 Attention 的主要价值。

### 6.3 不是谁绝对更强

- 字段数量少、关系简单、数据量小或延迟极紧时，concat + MLP 更轻、更稳；
- 字段实体边界明显，存在候选条件化、多源/跨域交互时，Token + Attention 的结构偏置更合适；
- 实践最常见的不是二选一：Token 交互后仍会 concat/pooling，再接 MLP 或 RankMixer 做最终打分。

---

## 7. Token 化有哪些坑？

### 7.1 切得越细越好吗？

不是。每多一个 token 都会增加 token 数、Attention 成本和参数学习难度；强相关字段拆得太细还会把简单局部关系交给模型从头学习。应依据实体边界、交互需求和数据量选择粒度。

### 7.2 所有 Token 共享同一张 embedding 表吗？

通常不共享。用户 ID、商品 ID、城市 ID 的词表和语义不同，常用各自 embedding 表或各自投影层；共享的是输出维度 $D$ 与后续交互接口。强行共享可能造成 ID 空间碰撞与语义混淆。

### 7.3 静态 Token 需要位置编码吗？

不需要行为序列那种时间位置编码。必须有的是 field/type/slot 标识，否则 Attention 不知道一个向量来自用户还是候选。固定 slot embedding 可以使用，但它表示字段身份而非先后顺序。

### 7.4 为什么 Token 化后模型可能不升反降？

可能是 token 拆分过细、数据不足、缺少 type 标识、归一化不一致、Attention 层过深导致优化困难，或原问题根本不需要复杂条件交互。要通过控制变量消融：只 Token 化、再加 Attention、再加序列融合，逐步确认收益。

---

## 8. 回答模板


> 在这里 Token 化不是分词，而是把用户、候选、请求等字段或字段组编码成带类型标识的 $D$ 维向量。Concat 会让字段在第一层 MLP 固定混合；Token 化保留实体边界，让候选 Token 可以通过 Attention 动态读取用户、上下文和历史行为。静态与序列 token 虽来源不同，但分别编码后进入同一交互维度，训练目标会学习它们在当前 CVR 任务中的兼容关系；同维度是接口，不是语义相同。

### 追问：为什么不把历史也先池化为一个 Token？

若只需粗粒度长期偏好可以池化；但 PCVR 的目标依赖候选相关兴趣和时间演化，过早池化会丢失“哪一条历史、哪个时间段、哪个行为域有用”。因此保留行为 token，经序列编码和候选 Query 后再有选择地聚合。

### 追问：如何验证 Token 化带来收益？

固定特征、样本、训练预算，依次比较 `concat + MLP`、`static token + 同参数量交互层`、`static token + 序列融合`；同时看 AUC/LogLoss、分人群、时延和参数量。只有控制复杂度后的稳定增益，才能归因于 Token 化及其交互结构。
