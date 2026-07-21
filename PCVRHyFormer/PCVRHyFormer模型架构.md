
# 目录

- [[#1. 一句话总结]]
- [[#2. Baseline 与 0.8255 最佳模型的总体对比]]
- [[#3. 完整架构图]]
- [[#4. 输入与数据处理]]
- [[#5. 非序列特征编码：NS Tokens]]
- [[#6. 序列特征编码]]
- [[#7. Query 生成：MultiSeqQueryGenerator]]
- [[#8. HyFormer 主干：MultiSeqHyFormerBlock]]
- [[#9. T 整除约束与 0.8255 最佳配置]]
- [[#10. 输出层]]
- [[#11. 相比朴素 baseline 的主要改动与原因]]
- [[#12. 被尝试后回退的改动]]
- [[#13. 与后续 `0.8255 - 副本` 实验版的区别]]
- [[#14. 后续增强模块为什么没有进入最终 0.8255 主模型]]
- [[#15. 推荐的论文式表述]]
- [[#16. 当前最佳配置清单]]
- [[#17. 最终结论]]

# 1. 一句话总结

0.8255 最佳模型可以概括为：

**PCVRHyFormer 是一个面向转化率预测的多源 token 化混合模型。它先把用户、商品、请求时间等非序列特征编码成 NS tokens，再把四路行为序列编码成 seq tokens；随后通过每路序列独立的 Query 生成与 Cross-Attention 提取兴趣，最后使用 RankMixer 在 Query tokens 与 NS tokens 间做联合混合，输出 CVR logit。**

这个架构的核心不是单纯堆大模型，而是把推荐场景中的几类信息拆成 token：

- 非序列静态上下文：用户、商品、请求时间。
- 序列行为上下文：`seq_a`、`seq_b`、`seq_c`、`seq_d`。
- 查询兴趣 token：每路序列生成 2 个 query，用来主动读取行为序列。
- RankMixer token mixing：让 query 与静态 token 之间发生轻量交互。

# 2. Baseline 与 0.8255 最佳模型的总体对比

# 2.1 架构层面对比

从当前本地代码看，`features/baseline/model.py` 与 `features/baseline - 副本-0.8255/model.py` 没有结构差异。也就是说，0.8255 不是另起炉灶的新模型，而是在同一个 PCVRHyFormer 框架下找到的一组更稳的训练与容量配置。

# 2.2 训练默认参数差异

本地 `diff` 显示，差异主要是：

| 参数/策略                 |          baseline 目录默认值 |               0.8255 最佳版本 | 为什么 0.8255 更稳                          |
| --------------------- | ----------------------: | ------------------------: | -------------------------------------- |
| `d_model`             |                     128 |                        64 | 128 参数量更大，容易过拟合；64 在当前数据规模和 token 数下更稳 |
| LR scheduler          | 有 warmup + cosine 的可选代码 | 移除 scheduler，固定 `lr=1e-4` | 实验记录显示固定学习率在前 5 个 epoch 更稳定            |
| dense optimizer LR    |                  `1e-4` |                    `1e-4` | 保持稳定基线                                 |
| dropout               |               默认 `0.01` |                 默认 `0.01` | 64 维模型不过度依赖强正则                         |
| `num_hyformer_blocks` |                       2 |                         2 | 4 层更容易过拟合，2 层足够                        |
| `num_queries`         |                       2 |                         2 | 每路序列 2 个兴趣查询，表达力与稳定性平衡                 |

因此，0.8255 的关键不是“加了很多复杂模块”，而是：

1. 保持 `d_model=64` 的中等容量。
2. 保持 `T=16`，满足 RankMixer full mode 的整除约束。
3. 使用固定学习率，避免 cosine 后期学习率过低。
4. 不启用会破坏稳定性的额外实验模块。

# 3. 完整架构图

```text
原始 Parquet 样本
│
├── user_int_feats
│ └── CoupledNSTokenizer / RankMixerNSTokenizer
│ ├── 普通离散特征：Embedding + mask mean pooling
│ └── coupled fids：int embedding + dense stat projection
│
├── user_dense_feats
│ ├── fid 61 → UE token
│ └── fid 87 → UE token
│
├── item_int_feats
│ └── RankMixerNSTokenizer → item NS tokens
│
├── timestamp
│ └── request_time_feats
│ ├── sin(hour), cos(hour)
│ └── sin(weekday), cos(weekday)
│ → request time token
│
├── seq_a / seq_b / seq_c / seq_d
│ ├── side-info ids → Embedding
│ ├── concat all side-info embeddings
│ ├── Linear + LayerNorm + GELU
│ └── + time_bucket embedding
│
├── NS tokens 拼接
│ └── user_ns + UE tokens + item_ns + request_time token
│
├── MultiSeqQueryGenerator
│ └── 对每一路序列：
│ concat(NS tokens flatten, seq mean pool)
│ → FFN
│ → 2 个 query tokens
│
├── MultiSeqHyFormerBlock × 2
│ ├── 每路序列独立 Sequence Encoder
│ ├── 每路 query 对对应序列做 Cross-Attention
│ ├── concat(all decoded query tokens, NS tokens)
│ └── RankMixerBlock 做 token mixing + FFN
│
├── concat 全部 query tokens
│ └── Linear + LayerNorm → sample embedding
│
└── Classifier
└── Linear + LayerNorm + SiLU + Dropout + Linear → CVR logit

```

# 4. 输入与数据处理

# 4.1 数据来源

模型读取原始多列 Parquet 数据，并依赖 `schema.json` 确定每个特征的：

- feature id
- vocab size
- array length
- dense dim
- sequence domain
- sequence timestamp fid

数据集模块将样本转成以下字段：

```text
user_int_feats
item_int_feats
user_dense_feats
item_dense_feats
seq_data[domain]
seq_lens[domain]
seq_time_buckets[domain]
request_time_feats
label

```

其中 label 定义为：

```text
label = (label_type == 2)

```

即把转化事件映射成二分类正样本。

# 4.2 请求时间特征

`timestamp` 会被转换为请求时间周期特征：

```text
sin(hour), cos(hour), sin(weekday), cos(weekday)

```

代码中还做了 `+8h` 偏移，用于近似中国时区，使 hour 更贴近用户真实活跃时间。

**为什么这样做：**

CVR 与请求时间强相关。例如午休、晚间、工作日/周末的转化意愿可能不同。直接使用原始时间戳会引入绝对时间记忆，泛化差；使用 sin/cos 周期编码可以表达周期规律，同时避免时间边界不连续。

# 4.3 序列时间桶

每条行为序列都有行为时间戳，数据集计算：

```text
time_diff = request_timestamp - behavior_timestamp

```

然后用预设边界切成 bucket。模型侧使用：

```text
token_emb = token_emb + time_embedding(time_bucket_ids)

```

**为什么这样做：**

推荐转化任务里，行为的新鲜度很重要。最近刚浏览、刚点击的行为通常比几个月前的行为更能解释当前转化。时间桶 embedding 让模型知道“这个行为距离当前请求有多远”，但不会强制施加单调衰减，表达更灵活。

# 5. 非序列特征编码：NS Tokens

NS tokens 是整个模型的第一层核心设计。传统 baseline 可能把所有 user/item 特征 embedding 后直接 concat，再喂入 MLP；这里改成 token 化表示。

# 5.1 RankMixerNSTokenizer

RankMixerNSTokenizer 的流程：

```text
每个 fid:
int id → Embedding
如果是多值特征 → mask mean pooling
所有 fid embedding 按 group 顺序拼接
→ padding 到可整除长度
→ 均分成 num_ns_tokens 个 chunk
→ 每个 chunk 过 Linear + LayerNorm + SiLU
→ 输出 NS tokens

```

**为什么这样做：**

1. 它保留了所有离散特征的 embedding 表达。
2. 通过切块生成固定数量 token，不再强依赖人工分组数量。
3. 后续 RankMixer 需要固定 token 数 `T`，RankMixerNSTokenizer 可以灵活控制 `user_ns_tokens` 与 `item_ns_tokens`。
4. 相比直接 concat MLP，token 化之后可以和 query tokens 一起参与 token mixing。

# 5.2 CoupledNSTokenizer

对以下用户特征：

```text
62, 63, 64, 65, 66, 89, 90, 91

```

代码认为它们的 int array 与 dense array 是 element-aligned，也就是同一个位置的 id 和 float stat 表示同一个对象的两种属性。

融合方式：

```text
fused_i = embedding(int_id_i) + stat_proj(float_stat_i)
fid_emb = mean_pool(fused_i over valid positions)

```

**为什么这样做：**

普通多值离散特征只知道“出现过哪些 id”，但不知道这些 id 对应的统计强度、权重或数值信息。CoupledNSTokenizer 把 id 表示和对应 dense stat 在元素级别融合，比“先平均 id embedding，再拼一个 dense 向量”更细。

它的优点是：

- 保留每个元素的 id 与数值关系。
- 对 padding 使用 mask mean pooling，避免 padding 污染。
- 使用加法融合，参数少、稳定，不会像乘法融合那样放大噪声。

实验记录中，FloatBucketProj、乘法融合等方案被回退，说明当前加法融合是更稳的选择。

# 5.3 UE tokens

`user_dense_feats` 中 fid `61` 和 `87` 被单独投影成 UE tokens：

```text
Linear(dim → d_model) + LayerNorm + SiLU

```

**为什么这样做：**

这两个 dense fid 很可能是较强的用户侧 embedding 或画像向量。如果直接和所有 dense 特征混在一起，会稀释其表达；单独作为 token 可以让后续 RankMixer 和 Query 生成模块显式使用它们。

这里曾尝试把 UE 投影加深为 2 层 MLP，但已回退。

**回退原因：**

- 2 层 MLP 增加参数量。
- 对 `d_model=64` 的模型来说，UE 线性投影已经足够。
- 额外非线性可能加快训练集拟合，但验证 AUC 没有收益。

# 5.4 request time token

请求时间的 4 维 sin/cos 特征被投影为 1 个 NS token。

**为什么这样做：**

请求时间既不是用户静态特征，也不是行为序列特征，但它会影响转化意愿。作为独立 token 可以让后续 RankMixer 和 QueryGenerator 同时利用时间上下文。

# 6. 序列特征编码

模型支持 4 个序列域：

```text
seq_a, seq_b, seq_c, seq_d

```

默认截断长度：

```text
seq_a: 256
seq_b: 256
seq_c: 512
seq_d: 512

```

每个 domain 内部包含多个 side-info fid。编码过程：

```text
每个 side-info fid:
id → Embedding
高基数 id 特征训练时加更强 dropout
concat all side-info embeddings
→ Linear(len(vs)*emb_dim → d_model)
→ LayerNorm
→ GELU
→ + time_bucket embedding

```

**为什么这样做：**

一条行为不是单个 item id，而是由多个 side-info 共同描述。把每个 side-info fid embedding 后拼接，可以保留行为事件的多字段结构；再投影到 `d_model=64`，使所有序列 token 与 NS tokens 进入同一表示空间。

# 7. Query 生成：MultiSeqQueryGenerator

每个序列域会生成 `num_queries=2` 个 query token。四个序列域总共：

```text
2 × 4 = 8 个 query tokens

```

生成方式：

```text
对第 i 路序列:
seq_pooled_i = mask_mean_pool(seq_tokens_i)
global_info_i = concat(flatten(ns_tokens), seq_pooled_i)
global_info_i → LayerNorm
global_info_i → 独立 FFN × num_queries
→ q_i_1, q_i_2

```

**为什么这样做：**

传统 attention 往往用一个固定 CLS token 或平均池化表示序列。这里用 query tokens 主动从序列中读取信息，有几个好处：

1. 每路序列有自己的 query，不同序列域不会过早混在一起。
2. Query 的生成依赖 NS tokens，因此它知道当前用户、商品、时间上下文。
3. 每路 2 个 query 可以表达多个兴趣子空间，比如近期强兴趣与长期偏好。
4. 相比全序列 concat 后做大 Transformer，计算更轻、更可控。

# 8. HyFormer 主干：MultiSeqHyFormerBlock

0.8255 使用：

```text
num_hyformer_blocks = 2
d_model = 64
num_heads = 4
hidden_mult = 4

```

每个 block 包含三步。

# 8.1 Sequence Evolution

每路序列独立经过 sequence encoder。默认是 TransformerEncoder：

```text
Pre-LN Self-Attention
→ residual
Pre-LN FFN
→ residual

```

注意力实现是自定义 `RoPEMultiheadAttention`，虽然 `use_rope` 默认关闭，但结构支持 RoPE。

**为什么每路序列独立编码：**

不同序列域可能表示不同类型行为，强行拼在一起会破坏语义边界。先独立编码可以让每路序列保留自己的行为模式。

# 8.2 Query Decoding

每路 query 对自己的序列做 cross-attention：

```text
query = q_tokens_i
key/value = encoded_seq_i

```

输出是 decoded query。

**为什么这样做：**

这一步让 query 真正“读取”序列信息。相比 mean pooling，它可以根据当前 query 自适应关注不同时间、不同 side-info 的行为。

# 8.3 Query Boosting / RankMixer

把所有 decoded query 和 NS tokens 拼起来：

```text
combined = concat(decoded_q_seq_a,
decoded_q_seq_b,
decoded_q_seq_c,
decoded_q_seq_d,
ns_tokens)

```

然后进入 RankMixerBlock：

```text
Token Mixing:
(B, T, D) → (B, T, T, D/T)
transpose token axis and subspace axis
→ reshape back to (B, T, D)
Per-token FFN:
LayerNorm → Linear → GELU → Dropout → Linear
Residual:
Q_boost = Q + FFN(mixed_Q)
→ LayerNorm

```

**为什么用 RankMixer：**

Transformer self-attention 可以做 token 交互，但参数和计算更重。RankMixer 的 token mixing 通过 reshape/transpose 完成，是一种几乎无参数的 token 交互方式。它尤其适合这里的短 token 序列：

```text
T = query tokens + NS tokens

```

既能让用户、商品、时间、序列兴趣相互作用，又不显著增加参数量。

# 9. T 整除约束与 0.8255 最佳配置

RankMixer full mode 要求：

```text
d_model % T == 0

```

其中：

```text
T = num_queries × num_sequences + num_ns

```

0.8255 最佳配置记录为：

```text
num_queries = 2
num_sequences = 4
user_ns_tokens = 3
UE tokens = 2
item_ns_tokens = 2
request_time token = 1

```

所以：

```text
num_ns = 3 + 2 + 2 + 1 = 8
T = 2 × 4 + 8 = 16
d_model = 64
64 % 16 = 0

```

**为什么这是关键：**

RankMixer 的 token mixing 会把 `D` 维通道切成 `T` 份。如果不能整除，就无法做无损 reshape。`T=16, D=64` 对应每个 token 子空间 `d_sub=4`，刚好可行。

这也是为什么文档里强调 `user_ns_tokens=3`。如果改成 `user_ns_tokens=5`，在其他设置不变时：

```text
num_ns = 5 + 2 + 2 + 1 = 10
T = 8 + 10 = 18
64 % 18 != 0

```

这会破坏 RankMixer full mode 的硬约束。

# 10. 输出层

经过两个 HyFormer block 后，只取所有序列的 query tokens：

```text
all_q = concat(curr_qs) # (B, 8, 64)
flatten → (B, 512)
Linear(512 → 64)
LayerNorm

```

最后分类器：

```text
Linear(64 → 64)
LayerNorm
SiLU
Dropout
Linear(64 → 1)

```

输出为单个 CVR logit，训练时使用 BCEWithLogitsLoss。

**为什么最后主要使用 query tokens：**

Query tokens 已经通过 cross-attention 读取了序列，又通过 RankMixer 与 NS tokens 混合。因此它们可以被视为“经过上下文增强后的兴趣表示”。最终使用 query tokens 而不是直接 flatten 所有 token，可以减少输出层维度，也让模型更聚焦于序列兴趣。

# 11. 相比朴素 baseline 的主要改动与原因

这里的“朴素 baseline”指常见的推荐模型写法：user/item embedding concat、序列 mean pooling 或简单 attention、MLP 输出。相对这种 baseline，PCVRHyFormer 的关键改动如下。

# 改动 1：非序列特征从 concat 向 token 化转变

**做法：**

使用 RankMixerNSTokenizer / CoupledNSTokenizer，把 user/item/time 表示成多个 NS tokens。

**原因：**

推荐特征非常异构，用户 id、用户画像、商品 id、请求时间并不是同一种语义。直接 concat 会让模型在第一层 MLP 里自行学习所有交互，参数压力大且解释性弱。token 化之后，每类信息可以作为独立对象参与交互。

**收益：**

- 更适合后续 token mixing。
- 便于控制用户侧和商品侧容量。
- 能把请求时间作为独立上下文注入。

# 改动 2：对 int+dense 对齐特征做 element-level 融合

**做法：**

对 coupled fids：

```text
embedding(int_id_i) + Linear(float_i)

```

然后按有效元素 mean pooling。

**原因：**

这些特征的 int array 和 dense array 在元素级别对齐。如果分开处理，模型会丢失“哪个 id 对应哪个 dense stat”的关系。element-level 融合能保留这种配对信息。

**为什么不用更复杂融合：**

实验记录里，分桶离散化和乘法融合都被回退。原因大概率是：

- 分桶会损失连续值精度。
- 乘法融合对数值尺度敏感，容易放大噪声。
- 加法融合参数少，更稳。

# 改动 3：引入 UE dedicated tokens

**做法：**

把 user dense fid `61`、`87` 单独投影成 token。

**原因：**

这类 dense 特征可能本身已经是强表达的用户 embedding 或统计画像。独立 token 可以让后续模块直接访问它们，而不是在一个大 dense 向量中被稀释。

**为什么回退 2 层 UE MLP：**

2 层 MLP 理论上表达力更强，但当前模型容量瓶颈不在这里。增加 MLP 会提升参数量和收敛难度，实验 AUC 没有提升，所以回退为单层 Linear + LayerNorm。

# 改动 4：加入 request time token

**做法：**

timestamp → hour/weekday sin-cos → Linear → request time token。

**原因：**

CVR 不是时间平稳的。用户在不同小时、不同星期的转化倾向不同。把请求时间作为 token 可以让模型学习“当前场景是否适合转化”。

**为什么用 sin/cos：**

小时和星期都是周期变量。比如 23 点和 0 点在数值上差很远，但时间上相邻。sin/cos 编码能保留周期连续性。

# 改动 5：序列 token 加 time bucket embedding

**做法：**

行为时间与请求时间做差，离散到 bucket，再加到序列 token 上。

**原因：**

同样的行为，发生在 5 分钟前和 30 天前意义完全不同。time bucket embedding 让模型知道行为新鲜度。

**为什么回退时间衰减乘法：**

文档记录中，可学习时间衰减没有提升。原因是：

- time bucket embedding 已经能表达时间差。
- 乘法衰减会强行假设“越远越弱”，但某些长期偏好未必应该被衰减。
- 多一个可学习衰减参数可能引入不稳定。

因此保留加法时间 embedding，移除乘法衰减。

# 改动 6：每路序列独立 Query 生成

**做法：**

每个序列域使用 NS tokens + 自身 mean pooling 生成 2 个 query tokens。

**原因：**

四路序列语义不同。如果只用一个全局 query，可能无法分别捕捉不同序列中的兴趣。每路序列独立生成 query，可以让模型学习：

- seq_a 应关注什么行为；
- seq_b 应关注什么行为；
- seq_c / seq_d 是否承载更长历史或不同粒度兴趣。

# 改动 7：Query-to-Sequence Cross-Attention

**做法：**

每路 query 对自己的序列做 cross-attention。

**原因：**

mean pooling 会把所有历史行为平均，容易让噪声行为干扰。Cross-Attention 允许 query 自适应选择重要行为，是序列兴趣提取的关键。

# 改动 8：RankMixer 替代重型全 token self-attention

**做法：**

concat query tokens + NS tokens 后，用 RankMixer 做 token mixing。

**原因：**

这个阶段 token 数短、语义强，没必要再用大 self-attention。RankMixer 参数少、计算轻，并且通过 reshape 实现跨 token 信息重排。

**为什么适合本模型：**

因为当前配置刚好满足：

```text
T = 16, d_model = 64

```

RankMixer 能稳定工作。

# 改动 9：保持 `d_model=64` 而不是 128

**做法：**

0.8255 最佳版本默认 `d_model=64`。

**原因：**

推荐比赛中的本地验证集往往与线上测试集存在时间分布差异。过大的模型容易记住高基数 id，在本地 AUC 高，但线上泛化下降。`d_model=64` 在容量和泛化之间更平衡。

实验记录也显示：

- `d_model=128` 参数量显著增大，容易过拟合。
- `d_model=96` 虽能满足整除，但峰值后振荡。
- `d_model=64` 是已验证稳定配置。

# 改动 10：固定学习率，移除 cosine scheduler

**做法：**

使用固定：

```text
lr = 1e-4

```

不使用 warmup + cosine decay。

**原因：**

实验记录显示，在约 5 epoch 的训练周期里，cosine scheduler 会让后期学习率下降过快，限制模型继续收敛。固定 `1e-4` 反而更稳定。

# 改动 11：禁用高基数 embedding 重初始化

**做法：**

`reinit_cardinality_threshold=0`，即不启用每 epoch 高基数 embedding 重置。

**原因：**

MultiEpoch 类方法适合数据被多轮重复训练、epoch 很多的场景；但当前比赛训练大约只跑 5 epoch。每轮末重置高基数 embedding 等于刚学到一点就清空，反而阻断收敛。

# 改动 12：跳过超高基数 embedding

**做法：**

```text
emb_skip_threshold = 1000000

```

vocab 超过阈值的特征不建 embedding，前向时用零向量代替。

**原因：**

超高基数 id 容易造成：

- 显存压力大；
- 参数极多；
- 对训练集 id 记忆严重；
- 线上遇到新 id 时泛化差。

跳过最高基数特征，是一种牺牲少量记忆能力、换取泛化和资源稳定性的策略。

# 12. 被尝试后回退的改动

这些内容很重要，因为它们说明最终模型为什么不是“越复杂越好”。

# 12.1 UE 2 层 MLP

**尝试：**

```text
Linear(dim → 2D) + SiLU + Linear(2D → D) + LayerNorm

```

**回退原因：**

没有提升 AUC，增加参数量和收敛难度。

# 12.2 时间衰减乘法

**尝试：**

```text
token_emb = token_emb * decay(time_bucket)

```

**回退原因：**

time bucket embedding 已经提供时间信息，额外乘法衰减没有收益，还可能误伤长期偏好。

# 12.3 FiLM Action-Type Conditioning

**尝试：**

使用 `label_type` 做条件调制。

**回退原因：**

这是数据泄露。因为 label 本身就是：

```text
label = (label_type == 2)

```

把 label_type 输入模型会让模型直接看到标签，导致异常高的训练/验证表现，推理时也不可用。

# 12.4 CosineAnnealingLR

**尝试：**

warmup + cosine decay。

**回退原因：**

当前训练 epoch 不长，学习率后期降得太低，导致收敛受限。固定 `1e-4` 更适合当前训练节奏。

# 12.5 增大 d_model

**尝试：**

`d_model=96`、`d_model=128`。

**回退原因：**

更大模型在本地可能更快拟合，但更容易过拟合高基数 id 和短期分布。最终 `d_model=64` 是更稳的泛化点。

# 13. 与后续 `0.8255 - 副本` 实验版的区别

目录 `features/baseline - 副本-0.8255 - 副本` 不是纯 0.8255 baseline，它继续加入了多项 post-0.8255 实验：

- DIN target-aware attention
- cross-domain pool
- time-decay pool
- R-Drop
- EMA
- label smoothing
- LAIN length-conditioning
- match features 开关

这些是后续探索，不应直接算作 0.8255 最佳模型的原始架构。

如果写论文或答辩，建议这样表述：

> 我们以 PCVRHyFormer 0.8255 版本作为稳定主干。后续尝试过 DIN、R-Drop、EMA、LAIN 等增强模块，但这些属于进一步实验，并非 0.8255 最佳 baseline 的必要组成。

# 14. 后续增强模块为什么没有进入最终 0.8255 主模型

这一节专门解释后续 `0.8255 - 副本` 中的增强模块。它们大多是合理的推荐系统想法，但在当前 PCVRHyFormer 主干、当前数据切分和当前训练轮数下，没有稳定超过 0.8255，因此不建议纳入最终最好模型的主体叙述。

# 14.1 DIN target-aware attention

**后续实验做法：**

使用 item NS tokens 作为 Query，把所有 HyFormer 编码后的行为序列拼起来作为 Key/Value：

```text
item_q = item_ns_tokens
kv = concat(final_seq_a, final_seq_b, final_seq_c, final_seq_d)
din_out = CrossAttention(item_q, kv)
din_pool = mean(din_out)
output = output + zero_init_linear(din_pool)

```

代码中还对 DIN 分支加了更强 dropout，并用 zero-init projection 保证训练初始时不破坏原 baseline。

**为什么这个想法合理：**

DIN 的核心思想是“候选 item 已知时，用户历史中与候选 item 更相关的行为应该权重更高”。这对广告 CVR 非常自然。例如用户历史里出现过相似广告、相似商品或同类目行为，确实可能影响转化概率。

**为什么在这个模型里没有稳定成为最终方案：**

PCVRHyFormer 原本已经有一条类似功能的路径：

```text
NS tokens → MultiSeqQueryGenerator → per-domain query
query → CrossAttention(seq)

```

也就是说，原模型的 query 本身已经由 user/item/time 上下文生成，并主动读取对应序列。DIN 再额外让 item_ns 查询所有序列，容易变成重复建模。

可能的负收益原因：

1. **信息冗余**：原 query-cross-attention 已经能学习 target-aware 行为选择，DIN 分支提供的新信息有限。
2. **容量增加**：DIN 额外增加一条 attention 分支和输出残差，训练集拟合更快，但验证更容易过拟合。
3. **item id 记忆增强**：DIN 强化 item 与历史行为的精确匹配，在本地同分布验证集可能有效，但线上时间后移、新 item 增多时泛化不稳。
4. **跨域拼接噪声**：把四路 final sequences 直接拼成一个大 KV，会弱化原模型“每路序列独立建模”的归纳偏置，不同 domain 的行为语义可能互相干扰。

**结论：**

DIN 是合理探索，但当前主干已经包含 query-based interest extraction。额外 DIN 分支没有提供足够新信息，反而增加过拟合风险，因此不纳入 0.8255 最佳模型。

# 14.2 Cross-domain pool

**后续实验做法：**

在 `MultiSeqQueryGenerator` 中额外加入一个 cross-domain token，来自四路序列 mean pooling 的拼接：

```text
cross_domain_info = FFN(concat(mean(seq_a), mean(seq_b), mean(seq_c), mean(seq_d)))
global_info = concat(ns_flat, seq_pool_i, cross_domain_info)

```

**为什么这个想法合理：**

用户行为跨域之间可能有关联。例如一个用户在不同序列域都有活跃行为，可能说明整体兴趣强度高；某个 domain 的行为也可能帮助解释另一个 domain。

**为什么在这里不起作用或收益不稳：**

原模型的 RankMixer 已经在每个 HyFormer block 中混合了：

```text
all decoded query tokens + ns_tokens

```

这意味着跨域信息本来会在 RankMixer 阶段交互。提前在 QueryGenerator 中加入 cross-domain pool，相当于把跨域融合前移。

可能问题：

1. **过早融合**：四路序列在进入各自 cross-attention 前就混合，可能破坏每路 query 的专门性。
2. **mean pooling 噪声大**：cross-domain pool 来自平均池化，可能把长尾、低相关历史行为一起压进去。
3. **增加 query FFN 输入维度**：QueryGenerator 的输入变大，参数变多，后续实验记录也指出新 pool 使 dense 参数明显增加，导致更早过拟合。

**结论：**

跨域交互是需要的，但当前模型把它放在 RankMixer 中更合适。提前加入 cross-domain pool 会削弱分域建模优势，并增加过拟合。

# 14.3 Time-decay pool

**后续实验做法：**

在 QueryGenerator 中额外加入基于时间桶的衰减池化：

```text
weight_t = softmax(-alpha * time_bucket_t)
time_decay_pool = sum(weight_t * seq_token_t)

```

**为什么这个想法合理：**

CVR 任务中，近期行为通常比远期行为更重要。显式时间衰减可以帮助模型聚焦最近兴趣。

**为什么没有进入最终模型：**

0.8255 主模型已有：

```text
seq_token = behavior_embedding + time_bucket_embedding

```

也就是说，时间差已经作为 embedding 注入每个行为 token。后续 attention 和 query 可以自己学习是否关注近期行为。

显式 time-decay pool 的问题：

1. **强加单调假设**：不是所有远期行为都没用。某些长期偏好可能比短期噪声更稳定。
2. **与 time_bucket embedding 重复**：时间信息已经存在，再加衰减池化容易冗余。
3. **近期噪声放大**：如果最近行为是偶然点击或低意图浏览，衰减池化会过度强调它。
4. **增加 QueryGenerator 容量**：和 cross-domain pool 一样，会扩大输入和参数，导致更早过拟合。

**结论：**

保留 time bucket embedding 更灵活；不采用显式时间衰减池化。

# 14.4 R-Drop

**后续实验做法：**

同一个 batch 做两次带 dropout 的 forward：

```text
loss = 0.5 * (BCE(logits1) + BCE(logits2))
+ alpha * symmetric_KL(logits1, logits2)

```

**为什么这个想法合理：**

R-Drop 希望模型对同一样本的不同 dropout 子网络输出保持一致，是一种正则化方法。理论上可以减少 dropout 带来的预测波动。

**为什么在当前模型里帮助有限：**

代码注释已经指出：当预测在后期接近 0/1 饱和时，KL 项会自然变小。也就是说，R-Drop 主要影响早期训练。

在这个任务中，主要矛盾不是普通 dropout 噪声，而是：

- 高基数 id 记忆；
- 本地验证与线上测试时间分布差异；
- 新增分支导致的容量增加。

R-Drop 对这些问题不是直接解法。

另外，R-Drop 会让每个训练 step 做两次 forward，训练成本翻倍。在比赛迭代中，如果 AUC 收益不稳定，就不值得作为最终主模型默认配置。

**结论：**

R-Drop 是训练正则，但不能解决该模型主要泛化瓶颈；收益不足以抵消训练成本和调参复杂度。

# 14.5 EMA

**后续实验做法：**

对 dense 参数维护 exponential moving average，验证和保存 best checkpoint 时使用 EMA 权重。

**为什么这个想法合理：**

EMA 可以平滑训练后期的参数震荡，常用于提升验证稳定性。

**为什么没有成为最终架构核心：**

EMA 不改变模型表达，只改变评估时的参数平均。它通常对“训练曲线抖动”有帮助，但对结构性过拟合、id 分布漂移帮助有限。

当前模型的强记忆主要来自 sparse embeddings，而后续代码中 EMA 只跟踪 dense params，不跟踪巨大 sparse embedding。这是合理的资源选择，但也意味着它无法平滑最容易过拟合的高基数 embedding 表。

**结论：**

EMA 可以作为训练技巧保留备选，但它不是 0.8255 主模型取得效果的架构原因，也不足以抵消后续复杂模块带来的过拟合。

# 14.6 Label smoothing

**后续实验做法：**

BCE 标签从硬标签改为：

```text
0 → alpha
1 → 1 - alpha

```

默认 `alpha=0.02`。

**为什么这个想法合理：**

label smoothing 可以防止模型把 logit 推到极端，缓解过拟合和过度自信。

**为什么帮助可能有限：**

CVR 是强监督二分类任务，label 本身由 `label_type == 2` 明确定义。过多 smoothing 可能降低正负样本边界的清晰度，尤其在 AUC 指标下，排序能力比概率校准更重要。

它可能改善 logloss 或校准，但不一定提升 AUC。

**结论：**

label smoothing 是校准型正则，不能保证排序 AUC 提升；在最终 0.8255 主模型中不作为必要设置。

# 14.7 InnerTrans + 更长序列

**后续实验做法：**

引入 LONGER-style InnerTrans，对原始长序列做局部 self-attention 压缩：

```text
每 G 个相邻 token → local attention → 压成 1 个 token

```

这样可以把 `seq_max_lens` 提高，比如尝试更长历史，同时控制后续 HyFormer 计算量。

**实验记录：**

`run.sh` 注释显示：

```text
InnerTrans + seq=1024 was tried (0.826 -> 0.8255, no gain)

```

**为什么没有收益：**

1. **长历史边际价值低**：默认 `256/256/512/512` 已经覆盖主要有效历史，更远行为对 CVR 的边际贡献有限。
2. **压缩损失细节**：InnerTrans 把局部多个行为压成一个 token，可能丢掉精确时间和具体行为细节。
3. **CVR 更依赖近期意图**：相比长期兴趣，转化更受当前请求、近期行为、候选 item 相关性影响。
4. **额外模块增加复杂度**：即使计算可控，参数和训练路径变复杂，未带来 AUC 增益。

**结论：**

更长序列并不天然更好。当前序列长度已经接近有效信息上限，继续拉长只带来噪声和压缩损失。

# 14.8 LAIN length-conditioning

**后续实验做法：**

对每路序列长度做 Fourier 编码，生成 length embedding，并用于：

1. 每个 domain prepend 若干 length prompt tokens；
2. 通过 zero-init residual 加到最终 output。

**为什么这个想法合理：**

序列长度本身是重要信号。历史很长的用户与历史很短的用户，行为可信度不同；某个 domain 很长也可能说明该 domain 兴趣强。

**为什么在当前模型里不一定有效：**

当前模型已经通过 padding mask、mean pooling denominator、attention mask 间接知道序列有效长度。LAIN 显式注入长度，可能带来两类问题：

1. **长度与活跃度强相关，容易过拟合**：模型可能学到“历史越长越容易转化”的本地相关性，但线上分布变化后不稳。
2. **prompt 改变序列结构**：prepend prompt tokens 会参与 attention，可能干扰原始行为序列的时间结构。
3. **与现有 QueryGenerator 重复**：QueryGenerator 已经使用 mask mean pool，每路序列的有效长度会影响池化结果。
4. **增加额外分支**：虽然 residual 是 zero-init，但 prompt 分支会直接进入 attention 路径，仍会改变训练动力学。

**结论：**

长度信号有价值，但当前主干已经隐式使用长度；LAIN 的显式长度 prompt 对这个模型可能是过强干预，收益不稳。

# 14.9 Explicit item-sequence match features

**后续实验做法：**

预先计算候选 item 与历史序列的匹配统计，例如：

```text
item_id ↔ seq_c fid 47
统计: log1p(count), recent_norm, ratio

```

再通过 zero-init Linear residual 加到模型 output。

**实验记录：**

`run.sh` 注释显示：

```text
match feature (item_id<->domain_c.47) regressed AUC 0.826 -> 0.820

```

`dataset.py` 中也记录，其他 category-level pairs 曾让 AUC 从约 `0.826` 降到 `0.824`。

**为什么这个想法合理：**

如果候选广告或商品曾出现在用户历史中，它确实可能是强信号。显式 match feature 可以避免模型自己从 attention 中慢慢学这个关系。

**为什么实际负收益明显：**

1. **显式规则太硬**：一旦把 exact match 作为强特征，模型可能过度依赖它。
2. **本地与线上分布不一致**：历史中出现候选 item 的比例、含义，在训练/验证/测试时间段可能不同。
3. **潜在泄露或后验行为风险**：如果某些序列包含与点击后或曝光后相关的信息，本地会看似强，但线上泛化会变差。
4. **哨兵值占比高**：注释提到大量样本可能只有 no-match sentinel，这会让模型学到偏置而不是有效排序。
5. **attention 已能隐式学习匹配**：原模型的 query-cross-attention 可以从序列中学习 item 相关性，显式统计可能反而破坏端到端表示。

**结论：**

显式 match features 虽然直觉上强，但在本任务中带来明显 AUC 回退，应关闭。更安全的方向是让模型通过 attention 隐式学习匹配，而不是手工注入可能分布漂移的强规则。

# 14.10 新增模块叠加后的总体问题

后续实验版不是单独加一个模块，而是叠加了：

```text
DIN + cross-domain pool + time-decay pool + R-Drop + EMA
+ label smoothing + LAIN + optional match features

```

`run.sh` 注释明确提到：

```text
The new pools roughly doubled the dense-param count of the Q FFN bank,
so the model now overfits ~2 epochs earlier than the 0.8255 baseline.

```

这说明负收益不是某一个模块的问题，而是整体复杂度超过了当前数据和训练策略能稳定支撑的范围。

最终可归纳为：

1. **原模型已经有 query-based interest extraction，DIN/pool 类增强信息重叠。**
2. **新增分支增加 dense 参数，导致更早过拟合。**
3. **显式 match 和时间衰减引入较强人工先验，面对线上分布漂移不稳。**
4. **训练正则如 R-Drop/EMA/label smoothing 只能缓和过拟合，不能抵消结构过复杂。**
5. **CVR 任务更看重稳定泛化，0.8255 的中等容量反而更合适。**

因此，最终模型选择保留 0.8255 主干，是因为它在表达力、归纳偏置和泛化风险之间更平衡。

# 15. 推荐的论文式表述

可以把模型描述为：

> 本方案提出一种面向 PCVR 预测的多序列混合 Transformer 架构 PCVRHyFormer。模型首先将用户、商品和请求时间等非序列特征转换为一组 non-sequential tokens；对于用户侧 int-dense 对齐特征，采用 element-level embedding 与统计值投影加法融合，以保留 id 与数值统计之间的对应关系。对于四路用户行为序列，模型分别对每个行为事件的 side-information 进行 embedding 拼接和线性投影，并叠加时间间隔 bucket embedding，以刻画行为新鲜度。随后，模型基于非序列 tokens 和每路序列的池化表示，为每个序列域生成多个 query tokens，并通过 cross-attention 从对应序列中提取兴趣表示。最后，所有 query tokens 与非序列 tokens 被送入 RankMixerBlock 进行轻量 token mixing，得到融合后的用户-商品-上下文表示，并通过 MLP 输出转化概率。

# 16. 当前最佳配置清单

```text
d_model = 64
emb_dim = 64
num_queries = 2
num_hyformer_blocks = 2
num_heads = 4
seq_encoder_type = transformer
hidden_mult = 4
dropout_rate = 0.01
lr = 1e-4
loss_type = bce
sparse_lr = 0.05
rank_mixer_mode = full
use_time_buckets = True
use_request_time = True
use_rope = False
emb_skip_threshold = 1000000
reinit_cardinality_threshold = 0
user_ue_fids = 61,87
user_coupled_fids = 62,63,64,65,66,89,90,91

```

RankMixer token 约束：

```text
num_ns = user_ns(3) + UE(2) + item_ns(2) + request_time(1) = 8
query_tokens = num_queries(2) × num_sequences(4) = 8
T = 8 + 8 = 16
d_model = 64
64 % 16 = 0

```

# 17. 最终结论

0.8255 模型的成功点在于“合适的结构复杂度 + 稳定的容量控制”。它没有盲目扩大 hidden size，也没有把所有增强模块都堆上去，而是保留了几个对推荐 CVR 任务真正有用的设计：
1. 非序列特征 token 化，便于上下文交互。
2. int+dense 对齐特征做元素级融合，保留细粒度统计信息。
3. 四路序列独立编码和独立 query，避免不同序列语义混杂。
4. Cross-Attention 用 query 主动读取行为兴趣。
5. RankMixer 用轻量方式融合 query 与静态上下文。
6. 时间 bucket 与请求时间 token 同时建模行为新鲜度和请求周期。
7. `d_model=64, T=16` 保证 RankMixer 可用且容量不过大。
8. 固定学习率和较低 dropout 提供更稳定的 5 epoch 收敛。

因此，这个模型可以被定位为：

**一个为广告 CVR 场景定制的多序列兴趣提取模型，其核心贡献是把静态上下文、行为序列和兴趣 query 统一到 token 视角下，并用 RankMixer 做轻量融合。**
