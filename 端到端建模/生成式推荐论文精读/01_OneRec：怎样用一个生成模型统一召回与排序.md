# OneRec：怎样用一个生成模型统一召回与排序

论文：[OneRec: Unifying Retrieve and Rank with Generative Recommender and Preference Alignment](https://arxiv.org/abs/2502.18965)  
作者：Jiaxin Deng 等，Kuaishou，2025  
论文原图：Figure 1（统一架构 vs. 级联架构）、Figure 2（OneRec 训练与 IPA 总框架）

![[Pasted image 20260730211200.png]]

## 1. 按 Figure 1 的符号走完 OneRec 全流程，逐一解释途中的符号、图表等

Figure 1 的目的不是展开训练细节，而是先回答一个架构问题：**传统推荐为什么需要“召回、粗排、精排”三段，而 OneRec 为什么有可能用一个生成模型直接输出最终推荐列表？**

### 1.1 图 (a) 顶部：Unified Architecture 到底画了什么？

| 图中的元素 | 正确含义 | 不应误解为 |
|---|---|---|
| **Video Corpus $\sim10^{10}$** | 超大视频库。论文用它强调 OneRec 面对的仍是十亿级甚至百亿级 item 空间 | 在线时把百亿视频逐条送进 Encoder；这在计算上不可能 |
| 灰色小方块 | 离散化后的 **semantic-ID token** | 一个方块就是一个原始 video ID |
| **Encoder** | 编码用户历史行为序列，输出历史表示 $\mathbf H$ | 对整个视频库编码或给每个候选 item 独立打分 |
| $\mathbf H$ | Encoder 输出的一串 contextualized history states | 一个固定的 user embedding 向量 |
| **Decoder** | 以 $\mathbf H$ 为条件，自回归生成推荐列表中每个视频的 semantic-ID token | 对召回池中的所有视频并行打一个分数 |
| Decoder 内的蓝色虚线回箭头 | causal / autoregressive 依赖：后一个 token 只能看已生成 token | 循环网络；它仍是 Transformer，只是用了因果 mask |
| **Dozens / Recommended Videos** | 从生成的 token 串映射回真实视频后，直接展示的几十条列表 | 还要再经过一套精排模型才能决定最终顺序 |

可以把图 (a) 的真实数据流读成：

```text
离线：视频内容 → 多模态向量 → semantic ID 与“semantic ID → 视频”的索引

在线：用户近期正向历史的 semantic IDs
      → Encoder 得到 H
      → Decoder 条件生成一整个 session 的 semantic-ID 串
      → 通过索引映射回若干真实视频，按生成顺序展示
```

这里有一个容易混淆的点：图里 Video Corpus 用一根线连向 OneRec，是在表达“模型从全量内容空间生成 item”，**不是**说请求时把 corpus 的全部视频跑一遍。真正使这件事可行的是把 item 转换为多级 semantic IDs；Decoder 只需在较小的 codebook 词表上逐 token 生成。

### 1.2 用一个实际例子走图 (a)

假设用户小王最近有效观看过：

```text
露营帐篷测评 → 徒步路线攻略 → 山地摄影教程
```

这三条视频各自不是一个裸 ID，而是被编码成三层 semantic ID，例如：

```text
帐篷测评      → <a_6, b_1, c_5>
徒步路线攻略  → <a_2, b_1, c_7>
```

Encoder 看到的就是带边界标记的一长串历史 token；它学到“这个用户近期对户外感兴趣，同时与摄影也有交叉”。Decoder 先生成下一个视频的第一个 code token，例如 $a_9$，再在此前缀与 $\mathbf H$ 条件下生成 $b_7$、$c_1$。三层 token 合起来定位到一个真实视频；接着继续生成下一个视频的 token。

因此它不是“先在百亿库里召回 10 万条露营视频、再逐条算 CTR”，而是学习从历史兴趣直接写出一串视频的语义地址。第二条视频生成时已经知道第一条是什么，所以可以学到“先推一个帐篷实测，再推一个露营地攻略，比连续八条相似帐篷广告更像高质量 session”。

### 1.3 图 (b) 下半部分：传统 Cascade Architecture 的每一块

| 图中的块 | 输入规模 | 做什么 | 为何会形成上限 |
|---|---:|---|---|
| Retrieval / Coarse-grained Corpus | 全库约 $10^{10}$ | 多路召回或 ANN 从全库缩到约 $10^5$ | 漏掉的 item 后面永远无法找回 |
| Coarse-grained Ranking | 数十万级 | 用轻量模型缩到约 $10^3$ | 为了时延，特征和交互受限 |
| Fine-grained Ranking | 千级 | 用重模型逐 item 打分，留下约 $10^2$ | 仍只在前面传下来的候选中排序 |
| 最终展示 | 数十条 | 取 Top-K，常还附加重排规则 | 列表多样性/连贯性往往是事后规则 |

级联不是“错误架构”，它是用逐级缩小候选集换低延迟的工程解法。Figure 1 的对比强调：它的每一阶段都优化局部任务，前一阶段的 recall ceiling 会限制后一阶段；而 OneRec 试图把“选哪些 item”和“排成怎样的列表”放到同一个条件生成概率中学习。

### 1.4 Figure 1 没画出的两件事：必须补上才能叫“完整流程”

Figure 1 只画了**在线主干**。OneRec 之所以不仅是一个普通的生成召回模型，还依赖两部分训练设计：

1. 用高价值 session 做 **listwise next-token prediction**，让模型生成的不是孤立下一个 item，而是完整列表；
2. 用 Reward Model 选择模型自己生成的好/坏列表，再用 IPA + DPO 进行偏好对齐。

这两块由论文 Figure 2 详细展开，后面会继续按图解释。

## 2. 一句话总结

**OneRec 把“召回 → 粗排 → 精排”的多段漏斗改成“用户历史 → Encoder → 自回归 Decoder → 一整个推荐列表”的单阶段生成模型。**它以多级 semantic ID 降低超大 item 空间的生成难度，以稀疏 MoE 扩充容量，以 session-wise 训练学习列表上下文，再用 Reward Model + DPO 把生成结果向用户偏好对齐。

## 3. 生成前：item 为什么必须先 token 化？

### 3.1 一个视频如何变成 $\langle a_9,b_7,c_1\rangle$？

原始 item ID 本身没有语义，而且把亿级 ID 直接放进语言模型词表会造成巨大参数表与长尾稀疏问题。论文先为视频得到多模态向量 $\mathbf e_i\in\mathbb R^d$，再做 **multi-level balanced residual K-Means quantization**。

对某个视频 $i$：

1. 第一层 codebook $\mathcal C_1$ 找与 $\mathbf e_i$ 最近的中心，中心编号记为 $s_i^1$；
2. 取残差 $\mathbf r_i^2=\mathbf e_i-\mathbf c_{s_i^1}^1$；
3. 第二层 codebook 量化这个残差，得到 $s_i^2$；继续到第 $L$ 层；
4. 视频的 semantic ID 是 $\mathbf s_i=\langle s_i^1,s_i^2,\ldots,s_i^L\rangle$。

在图中，$a,b,c$ 表示不同层 codebook 的 token 类型；下标 $9,7,1$ 分别是这一层选到的 codeword 编号。**它们不是“视频 a、视频 b、视频 c”，也不代表三种模态。**

### 3.2 为什么要 balanced？

普通残差量化可能出现 hourglass：很少数 codeword 聚集大量热门视频，许多 codeword 很少被使用。这样 Decoder 对热门 token 学得很充分，长尾 token 的梯度却很少。

论文的 balanced K-Means 约束每个 cluster 分到相同数目的 item。它牺牲了一点“只追求最近中心”的自由度，换来 codebook 使用率更均衡。对于生成模型，这相当于避免某几条高频 token 成为拥堵的语言词，令每一层分类更可训练。

### 3.3 token 序列里的 SEP 与 BOS

| 标记 | 所在侧 | 作用 |
|---|---|---|
| `SEP` | Encoder 输入历史 | 分隔历史中的不同视频，使模型知道三层 token 属于同一个 item |
| `BOS` | Decoder 输入目标列表 | 标记要生成一个新视频的 semantic ID；训练时也起到右移输入的起点作用 |

例如 Encoder 可看到：

```text
SEP, <a_6>, <b_1>, <c_5>, SEP, <a_2>, <b_1>, <c_7>
```

Decoder 的 teacher-forcing 输入则像：

```text
BOS, <a_9>, <b_7>, <c_1>, BOS, <a_4>, <b_5>, <c_4>
```

论文把行为顺序作为序列结构使用；它没有在方法部分明确展开 position embedding 的具体实现。因此这里能确定的是 token 顺序、SEP/BOS 边界和 Decoder 的 causal mask 在携带顺序信息，不能把某种特定位置编码实现当成论文已声明的事实。

## 4. Figure 2 的原图：训练与偏好对齐全景

![[Pasted image 20260730204032.png]]

## 5. 按 Figure 2 走完 OneRec 的完整架构

Figure 2 分为上半部分 (a) **session-wise generation** 与下半部分 (b) **Iterative Preference Alignment, IPA**。前者回答“基础生成模型如何训练”，后者回答“模型生成的多个合理列表中，怎样偏向更好的一个”。

### 5.1 图 (a) 左侧：Encoder 如何把历史变成 $\mathbf H$？

输入为用户的正向历史 $\mathcal H_u=\{\mathbf v_1^h,\ldots,\mathbf v_n^h\}$。论文这里的“正向”指有效观看或点赞、关注、分享等行为，而非把快速划走的视频也一视同仁地放入历史。

Figure 2 中 OneRec Encoder 堆叠 $N/2$ 个 block；每个 block 的数据流是：

```text
历史 token states
→ Fully Visible Self-Attention
→ 残差 Add + RMSNorm
→ Feed Forward
→ 下一层历史 states
```

- **Fully Visible Self-Attention**：Encoder 内任意历史 token 可互相看见。第一个露营视频能与更晚的摄影视频相互注意，从而得到“户外摄影”这一组合兴趣，而不只是相邻点击的统计共现。
- **Add + RMSNorm**：残差保留输入路径，RMSNorm 稳定不同层的激活尺度。图中块的顺序就是这一层先交互、再归一化与前馈变换的主干。
- **Feed Forward**：对每个历史位置做非线性通道变换，补充 attention 的“跨 token 混合”。

最终 $\mathbf H=\operatorname{Encoder}(\mathcal H_u)$ 是**每个历史 token 都保留一份上下文化表示**。图中从 $\mathbf H$ 连向 Decoder 的线标有 `key/value`，正说明 Decoder 不是只拿一个用户向量，而是可以在每次生成时从不同历史位置取信息。

例子：生成“云台稳定器测评”时，Decoder 可能从 $\mathbf H$ 的摄影行为位置取较大注意力；生成“露营地避坑”时，则更关注帐篷/徒步行为。这个随生成 token 改变查询位置的能力，是简单平均历史 embedding 很难具备的。

### 5.2 图 (a) 右侧：Decoder 为何能生成一个列表？

Decoder 同样堆叠 $N/2$ 个 block，但每层有三段：

```text
已生成的目标 token
→ Causal Self-Attention
→ Fully Visible Cross-Attention（Q 来自 Decoder，K/V 来自 H）
→ Add + RMSNorm
→ 稀疏 MoE Layer
→ 下一个 token 的概率
```

1. **Causal Self-Attention**：位置 $t$ 只能看 $1$ 到 $t$ 的目标 token，不能偷看未来标签。因此模型在生成第二个视频时能知道第一个视频已经是什么；但训练时不能看见第二、第三个视频之后的 token。
2. **Fully Visible Cross-Attention**：Decoder 当前 token 表示作 Query，$\mathbf H$ 作 Key/Value；它可以在所有历史位置中查找与“当前要补全的语义地址”相关的兴趣证据。
3. **MoE Layer**：替代普通 Decoder FFN，是 OneRec 扩大参数容量的核心。

训练时使用 teacher forcing：真实目标 session 的前缀输入 Decoder，预测下一个 token，并对所有目标 token 的交叉熵求和：

$$
\mathcal L_{\mathrm{NTP}}
=-
\sum_{i=1}^{m}\sum_{j=1}^{L}
\log p_\Theta\!\left(s_i^{j+1}\mid
[\mathrm{BOS},s_1^1,\ldots,s_i^j],\mathcal H_u\right).
$$

这里 $m$ 是一个 session 的视频数，$L$ 是每个视频的 semantic-ID 层数。推理时没有真实后缀，才真正按“生成一个 token，再把它喂回去”的方式执行。

### 5.3 MoE Layer：图里的 Router、Expert、$\otimes$ 和 $\oplus$ 是什么？

| 图中符号 | 意义 |
|---|---|
| Router | 对当前 token 表示计算各 Expert 的 gate score |
| Expert 1 … Expert $N_{\mathrm{MoE}}$ | 多个独立的 FFN 子网络 |
| $\otimes$ | 某个 expert 输出乘对应的 gate 权重 |
| $\oplus$ | 将被选 expert 的加权输出相加，并走残差 |

对第 $l$ 层、第 $t$ 个 token 的隐藏状态 $\mathbf h_t^l$，论文写作：

$$
\mathbf h_t^{l+1}
=\mathbf h_t^l+
\sum_{i=1}^{N_{\mathrm{MoE}}}g_{i,t}\,operatorname{FFN}_i(\mathbf h_t^l),
$$

其中 router 先给每个 expert 打分 $s_{i,t}$，只保留 Top-$K_{\mathrm{MoE}}$ 个：

$$
g_{i,t}=
\begin{cases}
s_{i,t}, & s_{i,t}\in\operatorname{TopK}(s_{1,t},\ldots,s_{N_{\mathrm{MoE}},t}),\\
0, & \text{其他 expert}.
\end{cases}
$$

例如“露营装备”相关 token 可能主要路由到熟悉户外内容的 expert，“美妆教程”相关 token 则可能更多使用另一组 expert。模型总参数可以堆得很大，但每个 token 只实际计算 Top-$K$ 个 expert；论文报告线上推理只激活约 13% 参数。这是**容量增长不等于 FLOPs 等比例增长**的原因。

### 5.4 session-wise generation：它和普通 next-item prediction 差在哪？

普通 next-item 只训练 $p(v_{t+1}\mid \text{history})$：一次预测一个视频，若要出 10 条，则常分别生成/召回再靠规则去重、混排。

OneRec 训练的是：

$$
\mathcal S=\{v_1,\ldots,v_m\}=\mathcal M(\mathcal H_u),
$$

其中 $\mathcal S$ 是一次请求返回的完整 session。论文筛选高价值 session：例如实际有效观看视频数不少于 5、总观看时长超过阈值、或存在点赞/收藏/分享等行为。训练样本因此明确告诉模型“这几条视频作为一组出现是有效的”。

例子：对于露营用户，单独给“帐篷测评”很合理；但连续给十条不同帐篷测评，用户可能很快疲劳。session 训练可让第二、第三条转向“营地攻略”“摄影技巧”，把列表内部的互补性和顺序纳入同一个条件概率，而不是事后硬编码“同类目最多三条”。论文没有声称完全消除所有重排规则；更准确的说法是，它把一大部分列表关系交给生成模型学习。

### 5.5 图 (b)：Reward Model 是如何评价“一个 session”的？

曝光日志通常只展示过一条列表，所以没有天然的“同一用户、同一请求下 A 列表优于 B 列表”标签。OneRec 先训练一个 session-level RM：

1. 对 session 中每个 item $v_i$，结合用户表示 $u$ 做 target-aware 表示 $\tilde e_i=v_i\odot u$。论文用 $\odot$ 代表 target-aware 操作（如 target attention），**不应机械理解为逐元素乘法**；
2. 一组 $\{\tilde e_1,\ldots,\tilde e_m\}$ 再经 self-attention，让列表 item 彼此交互；
3. 将列表表示汇聚，送进多个 task tower，预测多种 session reward；论文列出 switch、有效观看、观看时长、like 等目标，并用多任务 BCE 训练；
4. 最终 RM 输出 $R(u,\mathcal S)$，作为“这个用户拿到这整张列表的预期偏好/价值”分数。

RM 的重点是 **user–list**，不是 item–user 的单点 CTR。这样“列表虽然每条都还行、但过度重复”的坏处才有机会被建模。

### 5.6 图 (b)：IPA 与 DPO 如何自我改进？

图中 $\mathcal M_t$ / OneRec$_t$ 是第 $t$ 轮模型。对同一个历史 $\mathcal H_u$：

1. 用 beam search 从 $\mathcal M_t$ 生成 $N$ 条不同的候选 session：$\mathcal S_u^1,\ldots,\mathcal S_u^N$；
2. RM 分别给出 $r_1,\ldots,r_N$；
3. 最高分列表 $\mathcal S_u^w$ 是图中的绿色 **chosen**，最低分 $\mathcal S_u^l$ 是红色 **rejected**；它们来自当前模型的 beam，因此是 self-hard pair，不是随便随机抽的负例；
4. 以 $\mathcal M_t$ 为 reference，初始化下一轮 $\mathcal M_{t+1}$，用 DPO 增大 chosen 相对 rejected 的条件概率：

$$
\mathcal L_{\mathrm{DPO}}
=-
\log\sigma\!\left[
\beta\log\frac{\mathcal M_{t+1}(\mathcal S_u^w\mid\mathcal H_u)}
{\mathcal M_t(\mathcal S_u^w\mid\mathcal H_u)}
-
\beta\log\frac{\mathcal M_{t+1}(\mathcal S_u^l\mid\mathcal H_u)}
{\mathcal M_t(\mathcal S_u^l\mid\mathcal H_u)}
\right];
$$

5. 更新后得到 $\mathcal M_{t+1}$，再用它产生下一轮更难的候选，形成图底部的 iterative training loop。

这不是让 RM 直接替代线上真实反馈。RM 只是构造偏好对的评委；DPO 是让生成器在当前可生成的相近答案中，学会更偏向 RM 认为好的那个。论文为控制 beam-sampling 成本，仅用 $r_{\mathrm{DPO}}=1\%$ 的训练数据做偏好对齐；其余仍保留 NTP 训练。因此实际 batch 的损失是：

$$
\mathcal L=
\begin{cases}
\mathcal L_{\mathrm{NTP}}+\lambda\mathcal L_{\mathrm{DPO}}, & \text{DPO 样本},\\
\mathcal L_{\mathrm{NTP}}, & \text{其余样本}.
\end{cases}
$$

## 6. 训练和线上推理要分开理解

| 阶段 | 输入 | 核心计算 | 输出 |
|---|---|---|---|
| 离线 session 训练 | 高价值历史—session 对 | Encoder–Decoder，$\mathcal L_{\mathrm{NTP}}$ | seed model $\mathcal M_t$ |
| 离线 IPA | 历史 + 当前模型生成的多条 beam | RM 打分、chosen/rejected、DPO | 对齐后的 $\mathcal M_{t+1}$ |
| 在线服务 | 当前用户历史 | Encoder 一次编码；Decoder 自回归 + beam search | 直接展示的推荐视频列表 |

论文的工程信息是：在线使用 OneRec-1B、beam size 128；用 KV cache 避免每步重算历史 token 的 K/V，用 float16 量化降低显存，并利用 MoE 的稀疏激活降低实际计算。要注意，beam size、生成长度、semantic-ID 层数都和时延直接相关；OneRec 的统一架构减少了多段候选链路，但并不意味着自回归服务天然比级联更便宜。

## 7. 实验结果支持什么、不支持什么

- 论文的离线实验表明，OneRec-1B 优于 OneRec-0.1B，支持在其设定下增加有效容量有收益；MoE 是让这种扩容更可承受的结构手段。
- IPA 优于多种 DPO 变体，支持“RM 选择 self-hard pair + 迭代更新”在该数据和 RM 设定下有额外价值。
- 论文在快手主场景部署 OneRec-1B，报告观看时长提升 **1.6%**。这是最接近业务结论的证据，但不自动保证迁移到不同内容生态、不同 session 定义也会得到同幅度提升。

## 8. 这篇论文真正的价值

OneRec 的贡献不只是“在推荐里套了一个生成模型”。它把 **语义 ID 离散化、Encoder–Decoder 列表生成、稀疏 MoE 扩容、session-level reward 与偏好后训练** 连成了一条闭环：

```text
能表示超大 item 空间
→ 能把列表作为序列生成
→ 能把模型容量扩上去
→ 能在高质量列表内继续学偏好差异
```

只有这些环节同时成立，单阶段生成才有机会替代复杂级联的核心决策，而不是只作为一个新的召回源。

## 9. 局限与落地时要谨慎的地方

1. **semantic ID 是地基。**codebook 的语义质量、均衡性与更新策略都会影响最终生成；新 item 如何及时编码也必须有工程方案。
2. **自回归服务有时延压力。**生成的 token 数、beam size 和 semantic-ID 深度都会叠加解码成本；KV cache 只能减少重复计算，不能消除生成步数。
3. **RM 会定义 IPA 的方向。**若 RM 过度偏爱热门、短时互动或某个代理指标，DPO 可能把该偏差稳定放大；应做长期价值、校准与安全约束评估。
4. **高价值 session 的筛选本身带偏好。**训练集把“有效观看数、时长、互动”定义成好列表，模型也会学到这套定义；换业务时应重设 session 和 reward，而不是照搬阈值。

## 10. 最终 takeaway

**Figure 1 说明 OneRec 想替换什么：把级联筛选变成从全局语义 ID 空间直接生成最终列表；Figure 2 说明它怎样做到：历史由 Encoder 编码，列表由带 MoE 的 Decoder 生成，再由 RM + IPA/DPO 迭代对齐。**
