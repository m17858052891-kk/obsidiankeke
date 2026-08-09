
# 目录

- [[#1. 核心架构总览]]
- [[#2. 它要替代什么范式]]
- [[#3. 输入 token：S 与 NS 怎样构造]]
- [[#4. OneTrans Block：一次前向如何传导]]
- [[#5. Pyramid 与 KV Cache：长序列如何可用]]
- [[#6. 实验与证据]]
- [[#7. 消融与 Scaling]]
- [[#8. 一句话总结]]

# 1. 核心架构总览

OneTrans 的关键不是泛泛地“把特征 token 化”，而是把用户历史做成 S-token、把用户/候选商品/上下文等做成 NS-token，拼为 \([S;NS]\) 的因果序列。NS-token 位于历史之后，能够在每一层直接读取完整 S-token；因此，候选商品不用等历史先被压缩成单个用户向量，便可以决定自己该匹配哪段行为。

~~~text
多行为历史：点击 / 加购 / 购买 ───────> S-token
用户 + 候选商品 + 请求上下文 ─────────> NS-token
                                          │
                                          ▼
                  [S1, S2, ..., SL, NS1, ..., NSM]
                                          │
                                          ▼
        OneTrans Block × N：Mixed Attention + Mixed FFN
                                          │
                                          ▼
    Pyramid：深层保留尾部 Query；完整历史继续充当 K/V
                                          │
                                          ▼
                  最终 NS 表示 ──> CTR / CVR 等任务头
~~~

这个顺序同时服务两个目标：NS 读取 S，实现候选感知的细粒度行为匹配；S 不读取 NS，历史表示就与候选无关，可以在同一请求的多个候选之间、乃至相邻请求之间复用 KV cache。

# 2. 它要替代什么范式

## 2.1 传统的两段式精排

工业推荐排序模型通常包含两部分：

1. 用户行为序列建模
用 DIN、Transformer、LONGER 等结构，从用户历史行为中提取兴趣表示。

2. 非序列特征交互
用 DCNv2、Wukong、RankMixer、HyFormer等模型，对用户、商品、上下文、统计特征做高阶交叉。

这种范式可以概括为 encode-then-interaction：

```text
用户行为序列 -> 序列编码器 -> 用户兴趣向量
用户兴趣向量 + 用户/商品/上下文特征 -> 特征交互模块 -> 排序分数

```

## 2.2 为什么后融合不够

论文认为这种分离式架构有几个核心问题。

第一，序列特征和非序列特征只能后融合。用户历史行为先被压缩成一个或少数几个向量，之后才和候选商品、上下文等特征交互。这会损失细粒度行为和目标商品之间的对应关系。

第二，两个模块分别设计、分别扩展，系统复杂度高。序列模型和特征交互模型各自有自己的结构、优化方式和工程实现，不利于形成统一的 scaling 路线。

第三，很难自然复用 LLM 基础设施。LLM 生态已经积累了大量 Transformer 优化手段，例如 KV cache、FlashAttention、BF16/FP16、activation recomputation 等。传统推荐排序模型由于结构割裂，不能直接享受这些工程红利。

# 3. 输入 token：S 与 NS 怎样构造

## 3.1 S-token：历史事件

用户历史行为通常包含多种行为类型，例如：

- click
- add-to-cart
- purchase
- favorite

每个行为事件可能包含多个字段，例如 item id、category、brand、price、timestamp 等。OneTrans 将每个行为事件编码成一个 S-token。

论文讨论了两种多行为融合方式。

### 有可靠时间戳：时间感知融合

如果有可靠时间戳，则按照真实发生时间对不同类型行为排序：

```text
click item A at t1
add-to-cart item B at t2
purchase item C at t3

```

这种方式保留了用户行为的真实时间演化，更适合时间戳完整的业务场景。

### 无可靠时间戳：按行为影响度拼接

如果没有可靠时间戳，则按照行为意图强度组织序列，例如：

```text
purchase -> add-to-cart -> click

```

同时在不同行为类型之间插入 learnable `[SEP]` token，帮助模型区分行为段落。

实验显示，如果时间戳可用，timestamp-aware fusion 效果更好；如果时间戳不可用，timestamp-agnostic fusion 加 `[SEP]` 也是一个有效方案。

## 3.2 NS-token：当前请求中的非序列信息

非序列特征包括：

- 用户特征：年龄、性别、活跃度、长期偏好等。
- 商品特征：item id、类目、价格、品牌等。
- 上下文特征：场景、时间、入口、地理位置等。
- 统计特征：历史 CTR、CVR、曝光点击统计等。

OneTrans 提供了两种 tokenizer。

### Group-wise Tokenizer

人工按照语义把特征分组，每组特征通过一个 MLP 得到一个 token。例如：

```text
用户特征组 -> user token
商品特征组 -> item token
上下文特征组 -> context token
统计特征组 -> statistic token

```

优点是可解释性强，符合传统推荐系统的特征组织方式。缺点是依赖人工分组，且多个小 MLP 可能带来更多 kernel launch 开销。

### Auto-Split Tokenizer

把所有非序列特征拼接后通过一个 MLP，再 split 成多个 NS-token：

```text
concat(all non-sequence features) -> MLP -> split -> NS-tokens

```

若 `mathcal{NS}` 表示所有非序列特征 embedding 的拼接，公式为：

$$ X^{NS} = \operatorname{Split}(\operatorname{MLP}(\operatorname{Concat}(\mathcal{NS})), L_{NS}) $$

它不是把原始字段逐个硬切成 token：先用一个稠密投影让全部字段交互，再切为 (L_{NS}) 个同维子向量。因此任一个切出的 NS-token 都是全局特征的分布式表示，不必机械地对应“用户 token”或“商品 token”。论文消融显示 Auto-Split 优于手工分组；同时一次大 MLP 也减少了许多小 MLP 的 kernel launch。

将 S 与 NS 统一到维度 (d) 后，初始序列为
$$ X^{(0)} = [S\text{-tokens}; NS\text{-tokens}] \in \mathbb{R}^{(L_S+L_{NS})\times d} $$
例如“点击 A、加购 B、购买 C”的历史与候选 D 的特征会组成 [S_A, S_B, S_C, NS_1, ..., NS_M]。候选 D 属于 NS 部分：它从第一层起就能够对完整历史发起注意力，而不是等历史先被池化。

# 4. OneTrans Block：一次前向如何传导

OneTrans 并不是直接照搬标准 Transformer，而是针对推荐特征的异质性做了改造。

## 4.1 Mixed Attention 与 Mixed FFN：共享与特化

OneTrans Block 里最关键的结构选择之一，是 S-token 和 NS-token 不使用完全相同的参数策略。

简化地说：

```text
S-tokens: 共享参数
NS-tokens: token-specific 参数

```

这里的参数主要包括两类：
- attention 里的 Q/K/V projection 参数。
- FFN 里的前馈网络参数。

一层 Block 的计算顺序不是把两套网络串联，而是同一组 token 先经过 Pre-Norm 与 Mixed Attention，再做残差；随后再经过 Pre-Norm 与 Mixed FFN，再做一次残差：

$Z^{(n)} = \operatorname{MixedMHA}(\operatorname{Norm}(X^{(n-1)})) + X^{(n-1)}$

$X^{(n)} = \operatorname{MixedFFN}(\operatorname{Norm}(Z^{(n)})) + Z^{(n)}$

### S-token 为什么共享参数

S-token 表示用户历史行为序列。每个 S-token 都对应一个行为事件，例如一次点击、一次加购、一次购买。虽然具体 item 不同、行为类型不同，但这些 token 在模型里的角色是相似的：它们都是用户历史序列中的一个时间步。

因此，OneTrans 对所有 S-token 共享同一套 Q/K/V 和 FFN 参数：

```text
Q_s = X_s Wq_s
K_s = X_s Wk_s
V_s = X_s Wv_s
FFN_s = shared_ffn(X_s)

```

也就是说，不管是第 1 个历史行为还是第 100 个历史行为，都用同一套序列 token 处理函数。

这样选择有三个原因。
- 第一，S-token 数量通常很多。如果每个 S-token 都使用独立参数，参数量会随序列长度增长，几乎不可行。
- 第二，行为序列 token 相对同质。它们都表示“用户在某个时间点发生的行为”，更接近 NLP 中的文本 token。文本 Transformer 也不会给每个位置一套独立 Q/K/V，而是让所有 token 共享同一套投影。
- 第三，共享参数有利于泛化。模型学到的是“如何处理一个历史行为事件”，而不是记住某个固定位置的特殊处理方式。这样用户历史长度变化时也更自然。

可以把 S-token 的共享参数理解为：

```text
所有历史行为事件使用同一种序列建模语言。

```

### NS-token 为什么使用 token-specific 参数

NS-token 表示非序列特征字段，例如：

```text
user token
item token
context token
statistics token

```

这些 token 和 S-token 不同，它们不是同质的时间步，而是不同语义字段。user token 表示用户画像和长期偏好，item token 表示候选商品，context token 表示当前场景，statistics token 表示统计特征。它们的含义、数值分布、和预测目标的关系都不同。

因此，OneTrans 对 NS-token 使用 token-specific 参数。第 `i` 个 NS-token 可以有自己的 Q/K/V 和 FFN：

```text
Q_ns_i = X_ns_i Wq_ns_i
K_ns_i = X_ns_i Wk_ns_i
V_ns_i = X_ns_i Wv_ns_i
FFN_ns_i = ffn_ns_i(X_ns_i)

```

这样做的直觉是：不同字段需要不同的“解释器”。

例如：

- item token 做 query 时，应该更擅长从用户历史里找和候选商品相关的行为。
- user token 做 query 时，可能更关注长期画像和历史兴趣概括。
- context token 做 query 时，可能更关注当前场景如何调节用户兴趣。
- statistics token 可能更强调数值统计信号和校准信息。

如果这些 NS-token 完全共用同一套参数，模型需要用同一个函数同时处理用户、商品、上下文、统计等异质字段，表达能力会被压缩。

因此，NS-token-specific 参数的作用是：

```text
给每类非序列字段保留独立的语义变换能力。

```

### Q/K/V 在这里分别承担什么

在 attention 中：

```text
Q 决定当前 token 想找什么信息
K 决定当前 token 对外暴露什么索引
V 决定当前 token 真正传递什么内容

```

S-token 共享 Q/K/V，表示所有历史行为 token 使用同一套方式来提出查询、被其他 token 检索、以及传递行为信息。

NS-token 使用 token-specific Q/K/V，表示不同字段有不同的信息检索方式。比如 item token 和 context token 都可以 attend 到用户历史，但它们“想找的信息”不同：

```text
item token: 找和候选商品相似或互补的历史行为
context token: 找和当前场景相关的历史偏好
user token: 汇总用户长期兴趣和画像信号

```

这就是为什么 OneTrans 不把所有 token 的 Q/K/V 都简单共享。

每个 token 先由自己的投影得到查询、索引和值：

$q_i=W_i^Qx_i, k_i=W_i^Kx_i, v_i=W_i^Vx_i$

随后所有 token 的 Q、K、V 进入同一张注意力矩阵；区别只在于 S 位置复用共享投影，NS 位置使用对应的特化投影。

### FFN 在这里做什么

Attention 负责 token 之间的信息交换，FFN 负责每个 token 内部的信息加工。

S-token 共享 FFN，表示所有历史行为 token 使用同一种非线性变换来消化 attention 后的信息。

NS-token 使用 token-specific FFN，表示不同字段在拿到交互信息后，需要用不同方式进一步加工。例如 item token 在融合用户历史后，需要形成面向候选商品的匹配表示；context token 则更像是在学习当前场景下的调节因子。

所以可以把 FFN 的选择理解成：

```text
S-token shared FFN: 同一种方式加工历史行为
NS-token-specific FFN: 不同字段用不同方式消化交互结果

```

### 这套参数策略的取舍

OneTrans 的参数策略其实是在表达力和效率之间做折中。
如果所有 token 都共享参数：

```text
优点: 参数少，计算规整
缺点: NS-token 异质性表达不足

```

如果所有 token 都使用独立参数：

```text
优点: 表达力强
缺点: S-token 数量太大，参数量和计算成本不可控，也不利于泛化

```

OneTrans 选择中间路线：

```text
长而同质的 S-token: 共享参数
短而异质的 NS-token: token-specific 参数

```

这个策略和推荐系统的特征结构是匹配的：用户历史行为序列很长，适合共享；非序列字段数量少但语义差异大，适合保留字段专属参数。

最终可以概括为：

```text
S-tokens: homogeneous sequence events -> shared Q/K/V + shared FFN
NS-tokens: heterogeneous feature fields -> token-specific Q/K/V + token-specific FFN

```

## 4.2 Causal Attention：信息怎样流动

OneTrans 使用 causal attention，而不是 full attention。

输入 token 顺序通常是：

```text
[S-tokens, NS-tokens]

```

因此：

- S-token 只能看到自己之前的历史行为。
- NS-token 位于序列后部，可以看到完整历史行为和前面的 NS-token。

这带来一个重要工程好处：可以复用 KV cache。对于同一个用户的多次请求，用户历史行为对应的 K/V 可以缓存，避免重复计算。

消融实验显示，full attention 和 causal attention 效果接近，但 full attention 不利于 KV cache。因此 causal attention 是一个效果和效率折中的选择。

带 mask 的注意力仍是标准形式：

$\operatorname{Attention}(Q,K,V)=\operatorname{Softmax}(\frac{QK^\top}{\sqrt{d_h}}+M_{\mathrm{causal}})V$

## 4.3 顺序与结构信息

论文没有明确声明 OneTrans 使用了哪一种显式位置编码方法，例如 sinusoidal positional encoding、learnable absolute position embedding、RoPE、ALiBi 或 relative position bias。更稳妥的理解是：OneTrans 的顺序信息主要由 token 排列方式、causal mask 和行为类型信息共同表达。

首先，OneTrans 把 token 组织成固定顺序：

```text
[S-tokens..., NS-tokens...]

```

S-tokens 放在前面，表示用户历史行为；NS-tokens 放在后面，表示用户、商品、上下文、统计特征等非序列字段。这个顺序本身就定义了信息流方向：后面的 NS-token 可以看到前面的完整用户历史。

其次，OneTrans 使用 causal attention mask。也就是说，第 `i` 个 token 只能 attend 到它前面的 token：

```text
s1      -> 只能看自己
s2      -> 可以看 s1, s2
s3      -> 可以看 s1, s2, s3
...
item    -> 可以看完整 S-token 历史 + 前面的 NS-token
context -> 可以看完整 S-token 历史 + user/item 等前置 NS-token

```

因此，S-token 的时序关系主要通过“行为 token 的排列顺序 + causal mask”体现。

第三，S-token 的顺序来自行为序列组织方式。论文讨论了两种多行为融合策略：

```text
timestamp-aware:
按真实时间戳 interleave 多种行为序列

```

```text
timestamp-agnostic:
按行为意图强度拼接，例如 purchase -> add-to-cart -> click
不同行为段之间插入 learnable [SEP]

```

timestamp-aware 场景下，顺序就是用户真实行为时间线；timestamp-agnostic 场景下，顺序是人为定义的意图强度顺序。

此外，论文提到 timestamp-aware 方式会加入 sequence-type indicators，用来标识行为类型，例如 click、add-to-cart、purchase。这更像“行为类型编码”，不是传统意义上的位置编码，但它能帮助模型区分不同来源的行为序列。

对于 NS-token 来说，字段身份主要不依赖显式位置编码，而是依赖固定 token 排列和 token-specific 参数。例如 user token、item token、context token 拥有不同的 Q/K/V 和 FFN 参数，因此模型天然知道这些 token 对应不同字段。

可以这样总结：

```text
论文没有强调显式 positional encoding。
OneTrans 主要通过 token 顺序、causal mask、timestamp-aware/intent-aware 排列、
[SEP] token、sequence-type indicators 和 NS-token-specific 参数表达结构信息。

```

这也是 OneTrans 和普通 NLP Transformer 的一个差异：它不是把位置编码作为主要创新点，而是把推荐系统里的业务结构编码进 token 排列、mask 和字段专属参数中。

## 4.4 RMSNorm Pre-Norm

OneTrans 使用 RMSNorm pre-norm。推荐特征来源复杂，不同字段数值分布差异大，pre-norm 有助于稳定训练。

RMSNorm 全称是 Root Mean Square Layer Normalization，可以理解成 LayerNorm 的轻量版本。它的作用是把一个 hidden state 向量按照自身的均方根大小进行缩放，让向量整体尺度更稳定。

公式可以写成：

```text
RMS(x) = sqrt(mean(x_i^2) + epsilon)
RMSNorm(x) = x / RMS(x) * gamma

```

其中：

- `x` 是某个 token 的 hidden state 向量。
- `mean(x_i^2)` 是向量元素平方后的平均值。
- `epsilon` 用来防止除零。
- `gamma` 是可学习的缩放参数。

它和 LayerNorm 的主要区别是：LayerNorm 会先减去均值，再除以标准差；RMSNorm 不减均值，只按均方根缩放。

```text
LayerNorm: 减均值 + 除标准差
RMSNorm:  不减均值，只按 RMS 缩放

```

因此 RMSNorm 计算更轻，也常用于大规模 Transformer，例如 LLaMA 系列模型。对于 OneTrans 这种工业推荐模型来说，RMSNorm 的意义在于：输入 token 来自 ID embedding、数值统计特征、上下文特征、行为序列 embedding 等多种来源，数值尺度可能差异很大。进入 attention 或 FFN 前先做 RMSNorm，可以避免某些 token 因尺度过大主导 attention，也可以让深层 Transformer 训练更稳定。

OneTrans 采用的是 pre-norm 结构，即每个子层前先归一化：

```text
x -> RMSNorm -> Attention -> Residual
x -> RMSNorm -> FFN       -> Residual

```

简单说，RMSNorm 在 OneTrans Block 里承担的是“稳住 token 表示尺度”的角色。

# 5. Pyramid 与 KV Cache：长序列如何可用

OneTrans 的长序列工程核心是“减少深层更新、复用历史计算”。Pyramid Stack 随层数加深逐步减少参与 Query 计算的 S-token，但始终保留数量较少、承担最终预测的 NS-token；被压缩的历史也不是立即从记忆中删除，完整历史仍可作为 Key/Value 被保留的 Query 读取，因此注意力主项可由近似 $O(L^2d)$ 降为 $O(LL'd)$。因果 Attention 又保证历史 S-token 不依赖当前候选，使同一请求的多个候选可以复用历史 KV，相邻请求在历史只追加时也只需计算增量部分；再结合 FlashAttention-2、BF16/FP16 和 activation recomputation，模型分别从计算量、重复编码、算子效率和显存占用四个方向控制在线成本。

# 6. 实验与证据

论文在 ByteDance 的大规模工业数据上评估 CTR/CVR，包含 29.1B impressions、27.9M users 和 10.2M items。对比并非只选择弱基线，而是从 `DCNv2 + DIN` 出发，依次增强特征交互模块、增强序列模型，最后构造出较强的分离式基线 `RankMixer + Transformer`；OneTransS/L 仍然优于这一路线，说明收益不只是来自“换了更强的 Transformer”，而是来自让 S-token 与 NS-token 在同一骨干中逐层交互。相对 `DCNv2 + DIN`，OneTransL 报告 CTR AUC/UAUC 分别提升 1.53%/2.79%，CVR AUC/UAUC 分别提升 1.14%/3.23%，也明显高于 `RankMixer + Transformer` 的对应提升。

# 7. 消融与 Scaling

消融结果支持了各模块的分工：Auto-Split Tokenizer 比人工分组更易扩展且效果更好；时间戳可靠时按真实时间融合最优，否则 `[SEP]` 能帮助区分不同行为段；NS-token 的特化 Q/K/V 与 FFN 用来表达异质字段；Full Attention 没有带来显著增益却会破坏 KV cache，而移除 Pyramid 会显著增加计算量但收益有限。Scaling 实验进一步显示，扩展历史序列长度的收益最大，增加深度通常比单纯增加宽度更有效；OneTrans 与 RankMixer 都呈近似 log-linear 趋势，但 OneTrans 的斜率更陡，说明统一序列建模与特征交互后，新增参数和计算更容易转化为效果。

# 8. 一句话总结

OneTrans 将序列编码和特征交叉改写成 \([S;NS]\) 的因果 Transformer：S 是按时间组织的行为事件，NS 是当前用户、候选和上下文。NS 在每层读取完整 S，得到候选感知的细粒度匹配；S 不读取 NS，因而其 K/V 可跨候选复用。论文再以“历史共享、NS 特化”的参数策略表达异质性，用 Pyramid 降低长序列深层计算，并借助 KV cache、FlashAttention 等让统一大 backbone 满足工业时延。
