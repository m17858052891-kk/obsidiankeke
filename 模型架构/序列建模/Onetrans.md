

# 目录

- [[#1. 总结]]
- [[#2. 论文要解决什么问题]]
- [[#3. OneTrans 的核心思想]]
- [[#4. 输入 token 如何构造]]
- [[#5. OneTrans Block 的设计]]
- [[#6. 工程优化]]
- [[#7. 实验设置和结果]]
- [[#8. 消融实验结论]]
- [[#9. Scaling Law 观察]]
- [[#10. 论文价值]]
- [[#11. 如果要复现或借鉴，应该关注什么]]
- [[#12. 最终 takeaway]]

# 1. 总结

> OneTrans 的核心是把推荐排序里原本分离的序列建模和特征交互统一成一个 Transformer。它把用户历史行为作为 S-token，把用户、商品、上下文等非序列特征作为 NS-token，然后用一个带有推荐场景改造的 causal Transformer 联合建模。这样既能让历史行为和候选商品做细粒度交互，又能复用 LLM 里的 KV cache、FlashAttention、混合精度等系统优化。实验上，它在 ByteDance 工业数据和在线 A/B 中都明显优于 RankMixer + Transformer，而且 p99 延迟还下降，说明统一架构不仅提升效果，也改善了工程效率。

如果要进一步评价，可以补充：

> 我认为这篇论文的重点不是简单地把 Transformer 用到推荐里，而是提出了一条推荐排序模型向统一 backbone 和 scaling law 演进的路线。不过它的结果依赖大规模数据和强工程系统，外部复现难度较高，中小团队借鉴时应优先验证 token 化统一建模和 KV cache 是否真的带来收益。

OneTrans 是一篇面向工业推荐排序场景的 Transformer 架构论文。它试图把推荐系统中长期分离的两类能力统一起来：

- 用户行为序列建模，例如点击、加购、购买历史。
- 非序列特征交互，例如用户画像、候选商品、上下文、统计特征。

传统排序模型通常先用序列模型编码用户历史，再把编码后的用户兴趣向量交给特征交互模块。OneTrans 则把序列特征和非序列特征都转成 token，放进同一个 Transformer 中联合建模，从而让不同特征之间可以更充分地交互，并复用 LLM 体系中的 KV cache、FlashAttention、混合精度等工程优化。

# 2. 论文要解决什么问题

# 2.1 工业推荐排序中的典型建模范式

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

# 2.2 传统范式的局限

论文认为这种分离式架构有几个核心问题。

第一，序列特征和非序列特征只能后融合。用户历史行为先被压缩成一个或少数几个向量，之后才和候选商品、上下文等特征交互。这会损失细粒度行为和目标商品之间的对应关系。

第二，两个模块分别设计、分别扩展，系统复杂度高。序列模型和特征交互模型各自有自己的结构、优化方式和工程实现，不利于形成统一的 scaling 路线。

第三，很难自然复用 LLM 基础设施。LLM 生态已经积累了大量 Transformer 优化手段，例如 KV cache、FlashAttention、BF16/FP16、activation recomputation 等。传统推荐排序模型由于结构割裂，不能直接享受这些工程红利。

# 3. OneTrans 的核心思想

OneTrans 的核心思路是：

> 把推荐排序中的所有信息都表示成 token，然后用一个 Transformer 同时做序列建模和特征交互。

这些 token 分为两类：

- S-tokens：sequence tokens，对应用户历史行为序列。
- NS-tokens：non-sequence tokens，对应用户画像、商品、上下文、统计特征等非序列特征。

整体输入形式可以理解为：

```text
[S-token_1, S-token_2, ..., S-token_L, NS-token_1, NS-token_2, ..., NS-token_M]

```

其中 S-token 表示用户历史行为，NS-token 表示当前排序请求中的非序列信息。模型通过一个统一的 Transformer backbone 对这些 token 做联合建模，最后用输出表示预测 CTR、CVR 等目标。

# 4. 输入 token 如何构造

# 4.1 序列特征：S-tokens

用户历史行为通常包含多种行为类型，例如：

- click
- add-to-cart
- purchase
- favorite

每个行为事件可能包含多个字段，例如 item id、category、brand、price、timestamp 等。OneTrans 将每个行为事件编码成一个 S-token。

论文讨论了两种多行为融合方式。

# timestamp-aware fusion

如果有可靠时间戳，则按照真实发生时间对不同类型行为排序：

```text
click item A at t1
add-to-cart item B at t2
purchase item C at t3

```

这种方式保留了用户行为的真实时间演化，更适合时间戳完整的业务场景。

# timestamp-agnostic fusion

如果没有可靠时间戳，则按照行为意图强度组织序列，例如：

```text
purchase -> add-to-cart -> click

```

同时在不同行为类型之间插入 learnable `[SEP]` token，帮助模型区分行为段落。

实验显示，如果时间戳可用，timestamp-aware fusion 效果更好；如果时间戳不可用，timestamp-agnostic fusion 加 `[SEP]` 也是一个有效方案。

# 4.2 非序列特征：NS-tokens

非序列特征包括：

- 用户特征：年龄、性别、活跃度、长期偏好等。
- 商品特征：item id、类目、价格、品牌等。
- 上下文特征：场景、时间、入口、地理位置等。
- 统计特征：历史 CTR、CVR、曝光点击统计等。

OneTrans 提供了两种 tokenizer。

# Group-wise Tokenizer

人工按照语义把特征分组，每组特征通过一个 MLP 得到一个 token。例如：

```text
用户特征组 -> user token
商品特征组 -> item token
上下文特征组 -> context token
统计特征组 -> statistic token

```

优点是可解释性强，符合传统推荐系统的特征组织方式。缺点是依赖人工分组，且多个小 MLP 可能带来更多 kernel launch 开销。

# Auto-Split Tokenizer

把所有非序列特征拼接后通过一个 MLP，再 split 成多个 NS-token：

```text
concat(all non-sequence features) -> MLP -> split -> NS-tokens

```

怎么把年龄、商品类目、当前时间也变成统一的Token呢？
OneTrans抛弃了传统的手工分组，提出了Auto-Split Tokenizer 。先把所有非序列特征NStoken直接Flatten，拼成稠密向量；再让这个向量经过MLP，让所有特征在这里进行密集交叉；最后把MLP输出的长向量，直接生硬的切分成L_NS个等长的Token

NS-tokens=split(MLP(concat(NS)),L_NS​)

由于MLP全连接的特性，切出来的每一个NS-Token都蕴含了全局的分布式表示

# 5. OneTrans Block 的设计

OneTrans 并不是直接照搬标准 Transformer，而是针对推荐特征的异质性做了改造。

# 5.1 S-token 与 NS-token 使用不同参数策略

OneTrans Block 里最关键的结构选择之一，是 S-token 和 NS-token 不使用完全相同的参数策略。

简化地说：

```text
S-tokens: 共享参数
NS-tokens: token-specific 参数

```

这里的参数主要包括两类：
- attention 里的 Q/K/V projection 参数。
- FFN 里的前馈网络参数。

# 5.1.1 S-token 为什么共享参数

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

# 5.1.2 NS-token 为什么使用 token-specific 参数

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

# 5.1.3 Q/K/V 参数策略怎么理解

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

# 5.1.4 FFN 参数策略怎么理解

Attention 负责 token 之间的信息交换，FFN 负责每个 token 内部的信息加工。

S-token 共享 FFN，表示所有历史行为 token 使用同一种非线性变换来消化 attention 后的信息。

NS-token 使用 token-specific FFN，表示不同字段在拿到交互信息后，需要用不同方式进一步加工。例如 item token 在融合用户历史后，需要形成面向候选商品的匹配表示；context token 则更像是在学习当前场景下的调节因子。

所以可以把 FFN 的选择理解成：

```text
S-token shared FFN: 同一种方式加工历史行为
NS-token-specific FFN: 不同字段用不同方式消化交互结果

```

# 5.1.5 这个策略的取舍

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

# 5.2 Causal Attention

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

# 5.3 位置编码与顺序信息

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

# 5.4 RMSNorm Pre-Norm

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

# 6. 工程优化

这篇论文很重要的一点是，它不仅提出模型结构，也认真讨论了工业在线部署。

# 6.1 Pyramid Stack

随着 Transformer 层数加深，OneTrans 逐步减少还参与 query 计算的 S-token 数量。

直觉是：浅层保留完整历史序列，深层只保留更少、更浓缩的行为 token，让信息逐渐聚合到关键 token 和 NS-token 中。

需要注意的是，Pyramid Stack 压缩的是 S-token，不压缩 NS-token。

```text
S-token:  用户历史行为序列 token，数量通常很长，会逐层减少参与 query 的数量
NS-token: 用户、商品、上下文、统计等非序列 token，数量通常较少，会始终保留

```

可以把它理解成下面这种层级结构：

```text
Layer 1:
[S S S S S S S S | NS NS NS NS]
Layer 2:
[  S S S S S S   | NS NS NS NS]
Layer 3:
[    S S S S     | NS NS NS NS]
Layer 4:
[      S S       | NS NS NS NS]

```

NS-token 一直保留，是因为它们承载当前排序请求的核心字段，例如 user token、item token、context token、stat token，也是最终 CTR/CVR 预测的信息汇聚载体。它们数量少，压缩带来的计算收益有限，但删除或压缩可能直接损害特征交互和预测效果。

S-token 则不同。用户历史行为序列可能很长，如果每一层都让所有历史行为 token 完整参与 attention，计算成本会很高。因此 Pyramid Stack 在深层逐步减少 S-token 作为 query 的数量，让模型在浅层读取长历史，在深层使用更浓缩的历史表示。

这里的“压缩”不应该理解成简单删除历史信息。更准确地说，它主要减少深层中 S-token 参与 query 计算的数量；历史行为的信息可以通过前面层的 attention 逐渐汇聚到保留下来的 S-token 和 NS-token 中，同时 K/V 缓存仍然可以帮助复用用户历史侧计算。

这样可以显著降低计算量。论文中的消融显示，如果不用 pyramid stack，TFLOPs 会明显上升，但效果收益并不明显。

# 6.2 Cross-request KV Caching

工业推荐中，同一个用户一次请求通常会对应多个候选商品。用户历史行为部分在这些候选商品之间是共享的。

OneTrans 利用 causal attention，将用户历史行为的 K/V 缓存下来：

- 同一请求内，多个候选商品复用用户历史 K/V。
- 不同请求之间，如果用户历史只是 append-only，只需要计算新增行为的 K/V。

这让序列侧计算从每次处理完整历史，变成只处理增量历史。

# 6.3 复用 LLM 训练和推理优化

由于 OneTrans 主体是 Transformer，因此可以直接复用 LLM 工程生态中的优化：

- FlashAttention-2
- BF16/FP16 混合精度
- activation recomputation
- KV cache

这四个优化分别对应不同瓶颈：

```text
FlashAttention-2         -> 降低 attention 的显存读写和计算开销
BF16/FP16 混合精度       -> 降低显存占用，提高矩阵计算吞吐
activation recomputation -> 用额外计算换训练显存
KV cache                 -> 推理时复用历史 K/V，避免重复计算长序列

```

# 6.3.1 FlashAttention-2

普通 attention 的核心计算是：

```text
Attention(Q, K, V) = softmax(QK^T / sqrt(d)) V

```

如果序列长度是 `L`，那么 `QK^T` 会产生一个 `L x L` 的 attention matrix。用户历史行为越长，这个矩阵越大，显存压力和显存读写开销都会迅速上升。

FlashAttention 的核心思想是：不要把完整 attention matrix 显式写到显存里，而是分块计算 attention，并把 softmax 的中间计算尽量放在 GPU 更快的片上 SRAM/cache 中完成。FlashAttention-2 在此基础上进一步优化并行策略，提高 GPU 利用率。

对 OneTrans 来说，FlashAttention-2 的意义是：

```text
S-token 序列可能很长
attention 是主要计算瓶颈
FlashAttention-2 可以让长序列 attention 更省显存、更快

```

简单说，FlashAttention-2 让 OneTrans 更高效地处理长用户行为序列。

# 6.3.2 BF16/FP16 混合精度

传统训练常用 FP32，也就是 32 位浮点数。FP32 精度高，但显存占用大，矩阵计算吞吐相对低。
混合精度训练会把大部分矩阵计算换成 16 位浮点：

```text
FP32: 32-bit
FP16: 16-bit
BF16: 16-bit

```

这样做的好处是：

- 显存占用下降。
- 矩阵乘法更快。
- GPU Tensor Core 利用率更高。
- 可以支持更大的 batch size、更深的模型或更长的序列。

FP16 和 BF16 都是 16 位，但侧重点不同：

```text
FP16:
尾数精度相对更细，但数值范围较小，更容易 overflow/underflow
BF16:
数值范围接近 FP32，更稳定，但尾数精度更低

```

因此，大模型训练里 BF16 很常见，因为它在保持较好数值稳定性的同时，能获得接近 16 位计算的效率收益。

在 OneTrans 中，BF16/FP16 混合精度主要用于降低 embedding、attention、FFN 的显存占用，并提升 Q/K/V projection、attention 和 FFN 矩阵乘法速度。

一句话概括：

```text
BF16/FP16 是用更低数值精度换更高训练/推理吞吐。

```

# 6.3.3 Activation Re-computation

训练 Transformer 时，前向传播会保存很多 activation，因为反向传播需要用这些中间结果计算梯度。

例如：

```text
x -> attention -> hidden -> FFN -> output

```

如果要完整反向传播，就需要保存 attention 输入输出、FFN 输入输出、norm 后结果等中间 activation。模型层数越深、序列越长、batch size 越大，activation 占用的显存就越高。

Activation re-computation 也叫 gradient checkpointing。它的核心思路是：

```text
前向时不保存所有 activation
只保存少量 checkpoint
反向时需要某些 activation，再重新算一遍

```

它做的是一个计算和显存的 trade-off：

```text
显存占用下降
计算量上升

```

对 OneTrans 来说，这主要是训练阶段的优化。OneTransL 这类模型参数更大、序列更长，如果保存所有 activation，训练显存压力会很高。activation recomputation 可以用额外前向计算换取更低显存占用，让更大模型或更长序列训练变得可行。

一句话概括：

```text
activation recomputation 是用多算一点，换显存省很多。

```

# 6.3.4 KV Cache

KV cache 主要用于推理阶段，尤其适合 causal attention。

在 attention 中，每个 token 会生成：

```text
Q: 当前 token 用来查询什么信息
K: 当前 token 被其他 token 检索时的索引
V: 当前 token 真正传递的内容

```

对于 causal attention，后面的 token 可以看前面的历史 token，但历史 token 的 K/V 一旦算好，就不需要每次重新计算。

在 LLM 里，KV cache 用于自回归生成：

```text
已经生成 token 的 K/V 缓存起来
下一个 token 只计算自己的 Q/K/V

```

在 OneTrans 里，KV cache 更有推荐系统特色。同一个用户一次请求通常会对应多个候选商品：

```text
user history = 相同
candidate item 1
candidate item 2
candidate item 3
...

```

用户历史 S-token 对这些候选商品是共享的。因此，S-token 的 K/V 可以先计算并缓存：

```text
用户历史 S-token -> 计算 K/V -> cache
不同候选 item 的 NS-token -> 复用同一份历史 K/V

```

进一步，如果用户下一次请求时历史只是新增了几个行为：

```text
旧历史: s1, s2, ..., s100
新历史: s1, s2, ..., s100, s101, s102

```

那么旧的 `s1...s100` 的 K/V 可以继续复用，只需要计算新增的 `s101, s102`。这就是论文强调的 cross-request KV caching。

KV cache 是 OneTrans 在线推理效率的关键，因为它避免了对同一用户历史的重复计算，也是 OneTransL 在线 p99 latency 能下降的重要原因之一。

# 6.3.5 四个优化放在一起看

训练阶段主要依赖：

```text
BF16/FP16 mixed precision: 降低显存，提高吞吐
activation recomputation: 降低 activation 显存
FlashAttention-2: 降低 attention 显存和 IO

```

推理阶段主要依赖：

```text
BF16/FP16 mixed precision: 提高推理吞吐
FlashAttention-2: 加速 attention
KV cache: 复用用户历史，减少重复计算

```

这也是论文题目中 "One Transformer" 的工程含义：统一架构之后，推荐模型可以走和 LLM 类似的系统优化路径。尤其是 causal attention + `[S-tokens, NS-tokens]` 的排列方式，让用户历史 K/V 缓存变得自然，这一点是传统“序列模型 + 特征交互模型”分离架构不那么容易优雅做到的。

# 7. 实验设置和结果

# 7.1 数据规模

论文使用 ByteDance 内部工业推荐数据，规模很大：
- 29.1B impressions
- 27.9M users
- 10.2M items
- 日均 118.2M impressions
任务包括 CTR 和 CVR 预测，指标包括 AUC 和 UAUC。

# 7.2 对比模型架构怎么理解

论文里的离线对比表把模型分成四类：base model、feature-interaction、sequence-modeling 和 unified framework。这个分组很重要，因为它不是简单罗列 baseline，而是在说明 OneTrans 相比传统“序列模块 + 特征交互模块”的增益来自哪里。

# 7.2.1 Base model: DCNv2 + DIN

基础模型是：

```text
DCNv2 + DIN

```

可以理解成一个经典的工业排序架构：

```text
用户历史行为序列 -> DIN -> 用户兴趣表示
非序列特征 + 用户兴趣表示 -> DCNv2 -> CTR/CVR 预测

```

其中 DIN 负责用户行为序列建模。DIN 的核心思想是 target attention：面对不同候选商品时，从用户历史行为中激活和当前候选商品更相关的兴趣。

DCNv2 负责非序列特征交互。它通过 cross network 显式建模用户、商品、上下文、统计特征之间的交叉关系。

所以 DCNv2 + DIN 代表的是典型的 encode-then-interaction 范式：先把序列编码成兴趣向量，再和其他特征做交互。

# 7.2.2 Feature-interaction: 只替换特征交互模块

这一组模型保持序列建模模块还是 DIN，只替换特征交互部分：

```text
Wukong + DIN
HiFormer + DIN
RankMixer + DIN

```

它们共同回答的问题是：

> 如果用户行为序列建模能力不变，只把 DCNv2 换成更强的特征交互模型，效果能提升多少？

可以这样理解：

```text
用户历史行为序列 -> DIN -> 用户兴趣表示
非序列特征 + 用户兴趣表示 -> 更强的特征交互模块 -> 预测

```

Wukong、HiFormer、RankMixer 都属于更强的 feature interaction backbone，用来捕捉比 DCNv2 更复杂的高阶特征组合。表格中 RankMixer + DIN 的提升最大，说明在这组对比里，RankMixer 是更强的特征交互模块。

但这一组仍然是分离式结构：DIN 先压缩历史行为，后续特征交互模块只能拿到压缩后的兴趣表示，不能直接和完整行为序列逐 token 交互。

# 7.2.3 Sequence-modeling: 只替换序列建模模块

这一组保持特征交互模块使用 RankMixer，只替换用户行为序列建模部分：

```text
RankMixer + StackDIN
RankMixer + LONGER
RankMixer + Transformer

```

它们回答的问题是：

> 如果特征交互模块已经很强，再把 DIN 换成更强的序列模型，效果能提升多少？

可以理解成：

```text
用户历史行为序列 -> 更强的序列模型 -> 用户兴趣表示
非序列特征 + 用户兴趣表示 -> RankMixer -> 预测

```

StackDIN 可以看成 DIN 的增强堆叠版本，试图通过多层兴趣抽取提升序列建模能力。

LONGER 更关注长用户行为序列建模，目标是从更长历史中提取用户兴趣。

Transformer 则用 self-attention 建模用户行为之间的依赖关系，相比 DIN 的 target attention，它能更充分地捕捉行为序列内部的关联。

表格中 RankMixer + Transformer 是这组最强 baseline，说明在分离式架构里，“强特征交互模块 + Transformer 序列建模”已经是一个很强的组合。

# 7.2.4 Unified framework: OneTrans

最后一组是：

```text
OneTransS
OneTransL

```

这里不再是“一个序列模型 + 一个特征交互模型”的拼接，而是把 S-token 和 NS-token 放进同一个 Transformer backbone 里：

```text
S-tokens + NS-tokens -> OneTrans Blocks -> CTR/CVR 预测

```

OneTransS 和 OneTransL 主要区别是模型规模不同，OneTransL 是更大的默认版本。

这组对比要证明的是：

> 即使用 RankMixer + Transformer 这种强分离式 baseline，统一框架 OneTrans 仍然更好。

从架构角度看，OneTrans 的优势不只是“序列模块更强”或“特征交互模块更强”，而是取消了两者之间的硬边界。候选 item、user、context 等 NS-token 可以直接 attend 到完整用户历史 S-token，而不是只接收一个已经压缩过的用户兴趣向量。

# 7.2.5 这张表应该怎么读

这张表的逻辑可以概括为：

```text
DCNv2 + DIN
  -> 只增强特征交互: Wukong / HiFormer / RankMixer + DIN
  -> 只增强序列建模: RankMixer + StackDIN / LONGER / Transformer
  -> 统一建模: OneTransS / OneTransL

```

因此它展示的是一个逐步增强路径：

1. 先从传统 base model 出发。
2. 证明更强的特征交互模块有收益。
3. 证明更强的序列建模模块有收益。
4. 最后证明把两者统一到一个 Transformer backbone 中，收益更大。

这也是 OneTrans 论文实验设计的核心说服力：它不是只和弱 baseline 比，而是先构造了很强的分离式模型 RankMixer + Transformer，再证明统一框架仍然有明显提升。

# 7.3 离线效果

相对 DCNv2 + DIN baseline，论文报告了以下提升。

RankMixer + Transformer：

- CTR AUC +0.57%
- CTR UAUC +0.90%
- CVR AUC +0.52%
- CVR UAUC +0.75%

OneTransS：

- CTR AUC +1.13%
- CTR UAUC +1.77%
- CVR AUC +0.90%
- CVR UAUC +1.66%

OneTransL：

- CTR AUC +1.53%
- CTR UAUC +2.79%
- CVR AUC +1.14%
- CVR UAUC +3.23%

结论是：在强 baseline 下，统一建模的 OneTrans 明显优于“RankMixer 特征交互 + Transformer 序列建模”的分离式结构。

# 7.4 在线 A/B 效果

OneTransL 相对 RankMixer + Transformer 的在线结果：

Feeds 场景：

- click/u +7.737%
- order/u +4.351%
- GMV/u +5.685%
- p99 latency -3.91%

Mall 场景：

- click/u +5.143%
- order/u +2.577%
- GMV/u +3.670%
- p99 latency -3.26%

这组结果很关键，因为 OneTransL 不只是提升了业务指标，还降低了 p99 延迟。说明模型统一化和 KV cache 等优化在在线系统里确实发挥了作用。

# 8. 消融实验结论

论文中的消融实验支持了几个核心设计。

# 8.1 Auto-Split Tokenizer 优于 Group-wise Tokenizer

Auto-Split 减少人工分组依赖，同时提升模型效果和计算效率。对工业系统来说，这种更自动化的 tokenizer 更容易扩展到大量特征。

# 8.2 timestamp-aware fusion 更优

当时间戳可靠时，真实时间顺序能提供更强的用户兴趣演化信号，因此 timestamp-aware fusion 表现更好。

# 8.3 `[SEP]` token 有帮助

在 timestamp-agnostic 场景下，不同行为类型之间插入 `[SEP]` token 有助于模型区分行为段落。去掉 `[SEP]` 后效果会下降。

# 8.4 NS-token 使用 token-specific 参数更好

非序列特征之间语义差异大，因此完全共享参数不够灵活。token-specific Q/K/V 和 FFN 能提升表达能力。

# 8.5 Causal attention 是有效折中

Full attention 效果没有显著优于 causal attention，但会破坏 KV cache 的高效使用。因此 causal attention 更适合在线工业推荐。

# 8.6 Pyramid Stack 降低计算成本

不用 pyramid stack 会显著增加计算量，但效果提升有限。说明长序列信息不一定需要在每一层都完整参与 query 计算，逐层压缩是合理的。

# 9. Scaling Law 观察

论文从三个方向扩展模型：

- 序列长度
- 深度
- 宽度

主要观察如下。

第一，增加序列长度收益最大。更多历史行为能给模型提供更丰富的用户兴趣证据。

第二，增加深度通常比增加宽度更有效。深层 Transformer 更适合逐步抽取复杂高阶交互。

第三，OneTrans 和 RankMixer 都呈现近似 log-linear scaling trend，但 OneTrans 的斜率更陡，说明统一 Transformer backbone 的参数和计算效率更高。

这部分是论文的一个亮点：它不是只证明某个模型在固定规模下更好，而是尝试说明 OneTrans 有更好的扩展趋势。

# 10. 论文价值

# 10.1 模型层面的价值

OneTrans 的核心贡献是把推荐排序中的两类核心能力统一进一个 backbone：

- 序列建模
- 特征交互

这减少了模块边界，也让行为历史和候选商品、上下文等特征能够在 token 级别细粒度交互。

# 10.2 工程层面的价值

OneTrans 最大的现实意义可能不是“Transformer 又赢了”，而是推荐排序模型可以更自然地复用 LLM 基础设施：

- 更成熟的 attention kernel
- 更成熟的混合精度训练
- 更成熟的 KV cache 机制
- 更清晰的 scaling 路径

# 10.3 业务层面的价值

在线 A/B 显示 OneTrans 在 click、order、GMV 上都有提升，同时 p99 延迟下降。这说明它不是单纯堆大模型，而是通过架构统一和缓存机制提升了效果/效率比。

# 11. 如果要复现或借鉴，应该关注什么

如果想在自己的推荐系统中借鉴 OneTrans，不建议一上来复现完整 OneTransL，而可以分阶段尝试。

# 11.1 第一阶段：统一 token 化

先把部分非序列特征组织成 NS-token，并和用户历史 S-token 放到同一个 attention 模块中，验证统一建模是否优于后融合。

重点看：

- CTR/CVR AUC
- UAUC
- 分用户活跃度分桶效果
- 长历史用户收益是否更明显

# 11.2 第二阶段：引入 causal attention 和缓存

如果统一 token 化有效，再考虑改成 causal attention，并设计用户历史 KV cache。

重点看：

- 单用户多候选的复用收益
- p95/p99 latency
- GPU 显存占用
- cache 命中率

# 11.3 第三阶段：扩展序列长度和模型深度

在工程成本可控的前提下，逐步增加序列长度和模型深度，观察是否有类似 scaling trend。

重点看：

- 更长历史是否提升长期兴趣建模
- 深层模型是否带来稳定收益
- 效果收益是否覆盖在线成本

# 12. 最终 takeaway

OneTrans 给推荐排序系统的启发是：

> 与其继续把“序列模型”和“特征交互模型”分开堆，不如把所有信息组织成统一 token 序列，用一个可扩展 Transformer backbone 联合建模；再通过 causal attention、KV cache、pyramid stack 和高效 attention kernel 把在线成本控制住。

它代表了一种趋势：工业推荐模型正在从模块拼接式架构，向统一 Transformer backbone 和可扩展系统优化路线靠近。
