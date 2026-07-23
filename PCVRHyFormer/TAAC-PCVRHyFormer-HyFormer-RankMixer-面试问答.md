---
tags:
  - TAAC
  - PCVR
  - HyFormer
  - RankMixer
  - DIN
  - 面试
created: 2026-07-23
---

# TAAC / PCVRHyFormer / HyFormer / RankMixer 面试问答

> 使用建议：先背每题的“面试回答”，面试官追问时再展开“技术细节”。  
> 口径说明：本文严格区分三件事：**HyFormer 论文原版**、**RankMixer 论文原版**、**本项目 PCVRHyFormer 实现**。三者不能混讲。

## 0. 30 秒项目总述

我参加的是 2026 腾讯广告算法大赛 TAAC，赛题与 KDD Cup 联合，任务是在同时包含多字段行为序列和用户、广告、上下文等非序列特征的工业广告数据上预测目标广告的点击后转化率 pCVR。

我的最终代码是 `features/baseline - 516改`。主干采用 PCVRHyFormer：先把静态特征压缩成 NS Tokens，把四路行为分别编码成序列 Tokens；每个行为域生成两个 Query Token，通过两层“域内序列建模 → Query Cross-Attention 读取序列 → RankMixer 跨域及静态特征融合”反复迭代，最后预测转化概率。

我最重要的结构改动是把 DIN 的候选感知思想前置到 Query Generator：用候选 item 表示对每路历史做双线性 attention pooling，再由候选相关的兴趣摘要生成 Query。这样 Query 从初始化开始就是 target-aware 的，而不是主干处理完以后再补一个 DIN 分支。此外还做了离散 ID 与对应统计值的逐元素融合、请求时间与行为时间双尺度编码，以及稀疏/稠密参数分治优化。

---

## 1. TAAC 是什么比赛？任务背景是什么？

### 面试回答

TAAC 是 Tencent Advertising Algorithm Competition，即腾讯广告算法大赛。2026 年赛题与 KDD Cup 联合，核心方向是大规模推荐的统一建模：要求模型在同一个架构里处理多字段用户行为序列和用户画像、候选广告、请求上下文等非序列特征，输出目标广告的预测转化率 pCVR。

pCVR 表示用户已经点击广告后继续完成目标转化的概率，例如购买、注册或激活。它不仅是一个二分类问题，也直接影响广告排序和出价：以 CPA 广告为例，eCPM 通常同时依赖 pCTR、pCVR 和出价，所以 pCVR 的排序质量会影响平台收入、广告主 ROI 和用户体验。

这个任务的主要难点有四个：第一，类别 ID 基数高，存在明显长尾和 OOV；第二，历史行为很长而且噪声多；第三，不同行为序列的语义和字段空间不同，不能简单拼在一起；第四，线上模型既要有精度，也要满足高 QPS、低延迟和可扩展性。因此赛题重点不是单纯堆特征，而是寻找一种可以统一处理序列建模和异构特征交互、并具有 scaling 潜力的 Recommendation Block。

### 可补充的任务形式

给定用户 $u$、目标广告 $i$、上下文 $c$ 和多路历史行为 $S_1,\ldots,S_K$，模型学习：

$$
\hat y=P(y=1\mid u,i,c,S_1,\ldots,S_K)
$$

训练目标是二元交叉熵，比赛核心评价指标是 AUC。AUC 衡量正样本排在负样本前面的概率，适合正负样本不均衡的转化预估场景。

---

## 2. 你的 baseline 是什么？

### 面试回答

我在项目里说的 baseline，是**未加入候选感知 Query Pooling 的 PCVRHyFormer 主干**，不是纯 DIN，也不是简单 Embedding 拼接 MLP。

它先把 user、item 和静态上下文压成固定数量的 NS Tokens；四路行为序列分别编码；每个域用 masked mean pooling 得到序列摘要，并和全部 NS Tokens 拼接，通过两套 FFN 生成两个 Query Token。之后堆两层 HyFormer Block：每层先独立更新各行为序列，再让 Query 通过 Cross-Attention 读取本域序列，最后把四个域的 Query 和 NS Tokens 放进 RankMixer 做跨域与静态特征融合。最终将八个 Query 展平后预测 pCVR。

### 必须区分的三个 baseline

1. **论文的 BaseArch**：LONGER 做序列建模，RankMixer 做后置特征交互，两阶段串联。
2. **比赛/工程中的朴素 baseline**：通常可概括为 Embedding + 序列 mean pooling 或简单 attention + MLP。
3. **我的实验 baseline**：PCVRHyFormer，初始 Query 使用 mean pooling；最终的 `516改` 在它上面加入前置 bilinear target-aware pooling。

### 分数口径提醒

最终代码可以明确说是 `baseline - 516改`；但历史 baseline 目录后续继续被修改，`run.sh` 与代码默认项存在配置漂移。因此分数口径仍建议只引用已保存的榜单或训练日志，不要把未做严格等预算消融的总增益全部归因到单一模块。

---

## 3. 你在 HyFormer 上具体改了什么？

### 面试回答

我不是简单把 HyFormer 原论文照搬到 pCVR，而是做了五类适配。

第一，把论文的多序列思想适配成四个独立行为域，每个域保留自己的行为字段、序列编码器和两个 Query，避免不同域过早合并造成语义污染。

第二，重做非序列特征 Tokenization。用户侧离散特征形成 3 个 User NS Tokens，两个强稠密画像特征各形成一个 UE Token，候选 item 形成 2 个 Item NS Tokens，请求时刻形成 1 个 Time Token，总共 8 个 NS Tokens。

第三，增加两类语义对齐。一类是同一 fid 内离散 ID 与对应稠密统计值先逐元素相加再池化，保留 `id_j ↔ stat_j` 的配对关系；另一类是请求时间和行为时间的双尺度建模：请求时刻使用小时/星期周期编码，每个行为事件加入距请求时刻的 time-bucket embedding。

第四，也是最核心的改动：把 Query Generator 中的普通 mean pooling 换成候选感知的 Bilinear Target-Aware Pooling。候选 item 先对每一路历史进行软选择，得到 candidate-aware interest，再和 NS Tokens 一起生成 Query。

第五，针对小数据和工业稀疏特征做容量与优化控制：使用 $D=64$、两层 HyFormer、每域两个 Query；Embedding 用 Adagrad，稠密网络用 AdamW；跳过超高基数 embedding，并恢复验证集最优权重。

### 一句话总结改动

我把原本“由全局画像和平均历史生成的通用 Query”，改成了“由静态上下文和候选相关历史共同生成的 target-aware Query”，同时补齐了 pCVR 场景中的多域、时间和稀疏特征建模。

---

## 4. Query Token 是怎么得到的？

### 本项目的准确回答

本项目有四路行为序列，每路生成两个 Query，共八个。

先把候选 item 的两个 Item NS Tokens 取平均：

$$
e_{target}=\operatorname{Mean}(N_{item})\in\mathbb{R}^{D}
$$

对第 $s$ 路序列的第 $j$ 个行为 Token $h_{s,j}$，做双线性打分：

$$
z_{s,j}=\frac{(W_s h_{s,j})^\top e_{target}}{\sqrt D}
$$

对有效行为位置做 softmax，得到候选相关的序列摘要：

$$
\alpha_{s,j}=\operatorname{softmax}(z_{s,j}),\qquad
h_s^{target}=\sum_j\alpha_{s,j}h_{s,j}
$$

然后将 8 个 NS Tokens 展平，与本域的 $h_s^{target}$ 拼接、LayerNorm，再分别经过两套独立 FFN：

$$
G_s=[\operatorname{Flatten}(N_{NS});h_s^{target}]
$$

$$
q_{s,1}=FFN_{s,1}(G_s),\qquad q_{s,2}=FFN_{s,2}(G_s)
$$

所以初始 Query 不是随机可学习的 CLS Token，也不只是候选 item embedding，而是由**用户、候选、请求上下文和候选相关历史联合条件化生成**的语义兴趣槽。

在更深的 HyFormer Block 中不会重新用 FFN 生成 Query，而是复用上一层 Cross-Attention 和 RankMixer 更新后的 Query，再去读取下一层序列表示。

### 与论文原版的差异

HyFormer 论文把初始 Query 描述为由非序列特征、序列 pooling summary 和原始 target features 共同生成，并强调多序列 pooling 信息。本项目的代码是每个域用“全部 NS Tokens + 本域 pooled summary”各自生成 Query；最终 `516改` 进一步把本域 mean pooling 换成 candidate-aware bilinear pooling。

---

## 5. 为什么在 Query 生成阶段加入 DIN Pooling？

### 面试回答

因为 pCVR 是一个 target-conditioned 任务：同一个用户面对不同候选广告时，真正相关的历史行为不同。如果先对历史做 mean pooling，所有行为权重相同，候选相关信号可能被大量无关浏览稀释。

把 DIN 思想放在 Query 生成阶段，相当于先用候选 item 提问：“这一路历史里哪些行为最能解释当前广告的转化？”得到的兴趣摘要再用来初始化 Query。因此后续两层 Cross-Attention 都从候选相关的起点出发，能够更早降噪，也让 Query Decoding 的检索方向更明确。

我使用双线性形式而不是裸点积，是因为 item token 和 behavior token 虽然都是 $D$ 维，但来源和语义空间不同，矩阵 $W_s$ 可以学习跨空间对齐关系。它依然只是 soft matching，不会像手工 exact match 那样把某个 ID 对齐规则写死。

### 为什么放在前面而不是输出端？

前置是 early routing：候选语义影响整个主干的推理路径。后置 residual 只是主干处理完以后补充一条候选相关信号，安全但进入太晚，无法阻止无关历史在前面两层序列编码和跨域融合中传播。

---

## 6. 纯 DIN 为什么不如 HyFormer？

### 面试回答

DIN 解决的是“候选 item 应该关注哪些历史行为”，本质是一次候选感知的加权池化；HyFormer 解决的范围更大：它同时处理序列内部依赖、多路行为域、静态异构特征交互，以及序列和非序列信息的多层迭代。

纯 DIN 通常是：候选 item 与每个行为计算相关性 → 加权求和成一个兴趣向量 → 与静态特征拼接 → MLP。它有三个瓶颈：

1. 一次池化会把长序列过早压成单向量，复杂兴趣和多意图容易丢失。
2. 它主要建模 candidate-to-history 匹配，对行为之间的依赖、跨序列域交互和静态特征反向影响序列读取建模不足。
3. 融合通常发生在末端，信息流是单向的；后续 MLP 再深，也不能恢复池化时已经丢掉的结构。

HyFormer 保留多个 Query 作为多个兴趣槽，并反复执行“读序列 → 与其他 Query/NS 特征交互 → 带着新上下文再读序列”。因此 DIN 更像一个强而专门的 pooling operator，HyFormer 是一个可堆叠的统一 backbone。我的方案不是否定 DIN，而是把 DIN 的 target-aware 优势用于 HyFormer 的 Query 初始化。

---

## 7. 在小数据量场景下，DIN 为什么没有比 HyFormer 更好？

### 面试回答

“模型更简单，所以小数据一定更好”并不成立，泛化误差同时取决于方差和归纳偏置。这个任务有四路异构行为、静态画像、候选信息和时间信息；如果只用 DIN 做一次候选匹配，它的模型偏差可能更大，丢掉的跨域和时序结构比减少的方差更重要。

另外，小数据时 item-history 的精确共现更稀疏，DIN 容易把注意力学成高基数 ID 的记忆或偶然匹配；HyFormer 的多个 Query、域内独立建模、RankMixer 交互和固定 Token bottleneck 提供了更合适的结构约束。我们的 HyFormer 也不是无控制地做大，而是使用 $D=64$、两层 Block、低 dropout、early stopping 和稀疏/稠密分治优化，因此容量仍然可控。

### 严谨补充

如果没有保存“纯 DIN vs HyFormer、相同特征和训练预算”的完整消融日志，就应把上面的内容称为**机制解释**，而不是已被单一实验完全证明的因果结论。真正严谨的验证应固定 Tokenizer、特征、优化器和参数量，只替换序列聚合主干。

---

## 8. 详细讲一下 HyFormer

### 8.1 它要解决什么问题？

传统大规模推荐常用两阶段结构：先由 LONGER、Transformer 或 DIN 压缩行为序列，再把压缩结果和其他特征送入 RankMixer、DCN 等交互模块。这种结构的问题是序列先被独立压缩，异构特征只能在后面参与，形成 late fusion 和单向信息流。

HyFormer 的核心是用 Global/Query Tokens 作为序列与非序列特征之间的语义接口，在每一层交替进行 Query Decoding 和 Query Boosting，让两类信息共同演化。

### 8.2 输入表示

- **NS Tokens**：用户、候选 item、上下文、交叉特征等非序列特征。
- **Sequence Tokens**：行为事件的多字段 embedding，经拼接和投影后形成固定维度 Token，并可加入时间或位置编码。
- **Query Tokens**：由全局上下文和序列摘要条件化生成的少量语义槽，用于读取长行为序列。

### 8.3 一个 HyFormer Block 的数据流

```text
每路序列独立 Sequence Evolution
        ↓
Query Decoding：Query 对本域序列做 Cross-Attention
        ↓
把所有 Decoded Query 与 NS Tokens 拼接
        ↓
Query Boosting：用 RankMixer 式 Token Mixing + FFN 做跨域交互
        ↓
拆回各域 Query 和 NS Tokens，输入下一层
```

#### Sequence Evolution

每路行为使用独立的序列编码器得到本层 K/V。论文允许三种实现：Full Transformer、LONGER 式长序列编码和轻量 SwiGLU/FFN。本项目活动配置使用独立 Transformer Encoder，并叠加行为时间桶。

#### Query Decoding

对第 $l$ 层：

$$
\widetilde Q_s^{(l)}=\operatorname{CrossAttn}
\left(Q_s^{(l-1)},K_s^{(l)},V_s^{(l)}\right)
$$

Query 数量远少于序列长度，所以它像一组可学习的信息瓶颈：不保留所有行为，而是从长序列中抽取与全局任务有关的证据。

#### Query Boosting

把所有域的 Decoded Query 与 NS Tokens 合并，通过轻量 Token Mixing 和 FFN，让不同兴趣槽、不同序列域以及用户、候选、上下文信息交互，再作为下一层 Query。

### 8.4 为什么堆两层不是简单重复？

第一层 Query 先从本域行为中读取基础兴趣；RankMixer 让它获得其他域和静态特征；第二层 Query 带着新的跨域上下文再次读取本域序列。因此第二次读取的问题已经变了，形成：

```text
读取局部证据 → 全局交换信息 → 用全局上下文重新读取局部证据
```

这就是 HyFormer 所谓序列建模与特征交互的双向、迭代式信息流。

### 8.5 多序列为什么分开建模？

曝光、点击、搜索、转化等序列的字段空间和行为语义不同。直接拼成一条序列会迫使它们共享表示和位置语义。HyFormer 为每个域使用独立 Query 和序列编码，在 Query 层做跨域融合，既保留域内语义，又把跨域交互成本从长序列级降到少量 Query 级。

### 8.6 输出

本项目最终取第二个 Block 输出的 8 个 Query，拼成 $8\times64=512$ 维，投影回 64 维，再由 MLP 输出一个 pCVR logit。NS 和序列信息已经被 Query 读取和融合，因此不需要 flatten 全部历史。

---

## 9. 再详细讲一下 RankMixer

### 9.1 论文为什么提出 RankMixer？

传统推荐排序模型组合了许多 CPU 时代的手工交叉模块，GPU 上常常 memory-bound、MFU 低，不容易靠增加参数持续提升。标准 Self-Attention 对几百个异构 feature tokens 做两两相似度也不理想：推荐字段并不处在统一语义空间，且 attention matrix 带来额外计算和内存 IO。

RankMixer 的目标是构造一个硬件友好、可重复堆叠、容易沿宽度/深度/Token 数扩展的特征交互 Block。

### 9.2 Tokenization

它先将不同维度的 embedding 组织为固定数量、固定宽度的 feature tokens。论文支持按语义分组，也支持把拼接后的 embedding 自动等分。Token 太多会让每个 Token 分不到足够计算，Token 太少又会退化成一个大 DNN，所以 Token 数是表达力与效率的折中。

### 9.3 Multi-head Token Mixing

设输入 $X\in\mathbb{R}^{B\times T\times D}$，且 $D$ 能被 $T$ 整除。把每个 Token 的通道切成 $T$ 份：

$$
X:(B,T,D)\rightarrow(B,T,T,D/T)
$$

交换“原 Token 轴”和“子空间轴”：

$$
(B,\text{token},\text{head},D/T)
\rightarrow
(B,\text{head},\text{token},D/T)
$$

再 reshape 回 $(B,T,D)$。这样新的每个 Token 都由所有旧 Token 的某个通道子空间拼成。这个 routing 是无参数、确定性的，不需要计算 $QK^\top$，但后续 FFN 可以在已重排的全局信息上学习非线性交互。

本项目中 $T=16,D=64$，所以每个 Token 被切成 16 份，每份 4 维；这也解释了代码里的硬约束 `d_model % T == 0`。

### 9.4 Per-token FFN

**RankMixer 论文原版**为每个 Token 使用独立参数的 FFN。这样不同语义子空间不会被一套共享参数强行处理，可以减少高频强特征压制长尾弱特征，同时在不改变激活计算量数量级的情况下增加参数容量。

原论文还可把 Per-token FFN 扩展成 Sparse MoE，通过动态路由增加参数容量而不同比增加推理 FLOPs。

### 9.5 本项目实现与原论文的关键差异

本项目 `RankMixerBlock` 的 Token Mixing 与论文思想一致，但 `fc1/fc2` 是直接作用于整个 $(B,T,D)$ 张量的一套 `nn.Linear`，因此所有 Token **共享同一套 FFN 参数**。它更接近“RankMixer 式无参数重排 + shared position-wise FFN”，不是论文完整的 parameter-isolated Per-token FFN。

面试时可以说：比赛版本为了控制小数据下的参数量和实现复杂度，保留了最核心的 Token Mixing，但没有复刻论文的独立 Per-token FFN 和 Sparse MoE。不要声称项目已实现完整 1B RankMixer。

---

## 10. 你有看过 HyFormer 的 paper 吗？Paper 里关键内容是什么？

### 面试回答

看过。论文题目是 *HyFormer: Revisiting the Roles of Sequence Modeling and Feature Interaction in CTR Prediction*。我认为关键不在于“又用了一个 Transformer”，而在于它重新定义了序列压缩 Query 的角色。

传统 BaseArch 是 LONGER 加 RankMixer：先压缩序列，再做异构特征交互，是单向 late fusion。HyFormer 把两者放进同一个可堆叠 Block：Query Decoding 让 Global Query 从长序列读取信息，Query Boosting 再让这些 Query 与非序列特征及其他 Query 交互；更新后的 Query 下一层重新读取序列。这样序列建模与特征交互从一次串联变成多层交替优化。

论文还有四个关键结论：

1. Query 不能只由 target feature 构成，加入非序列全局上下文和序列 pooling 信息更有效。
2. 多路异构序列应独立解码，再在 Query 层交互；直接 merge sequence 会掉点。
3. HyFormer 在相近参数量/FLOPs 下优于 LONGER+RankMixer 等强 baseline。
4. 从约 200M 扩展到 1B+ 参数时，HyFormer 的 AUC–参数和 AUC–FLOPs 曲线斜率更好，说明双向迭代结构能更有效利用新增容量。

### 论文实验数字（被追问时再说）

- 工业数据来自抖音搜索，70 天、约 30 亿样本。
- 论文表格中 HyFormer AUC 为 0.6489；LONGER+RankMixer 为 0.6478；Full Transformer+RankMixer 为 0.6481。
- 去掉序列 pooling 信息，Delta AUC 为 -0.05%；Query 只保留原始 target 信息时为 -0.08%。
- 合并多序列并共享 Query 时为 -0.06%。
- 线上 A/B 报告了人均观看时长 +0.293%、完播数 +1.111%、Query Change Rate -0.236%。

---

## 11. 你觉得 HyFormer 有效果的原因是什么？

### 面试回答

我认为主要有四点。

第一，信息进入得更早。静态上下文不是等序列压缩完才参与，而是从 Query 初始化和每层 Query Boosting 开始就影响序列读取。

第二，信息流是双向迭代的。Query 从序列吸收证据，再和其他 Query、用户、候选及上下文融合，然后返回序列继续检索，能够形成更高阶的条件交互。

第三，多个 Query 是比单向量 pooling 更合理的瓶颈。它可以把用户多兴趣压缩到少量槽位，在表达力与长序列计算成本之间取得平衡。

第四，多序列先分域、后在 Query 层融合，既保留每个行为域的独特语义，又把昂贵的跨域交互限制在少量 Global Tokens 上。

对本项目而言，第五个原因是 Query 生成又加入了候选感知 pooling，使初始 Query 就围绕当前广告组织历史证据，更贴合 pCVR 的条件预测目标。

---

## 12. HyFormer 提出的核心意义是什么？

### 面试回答

HyFormer 的核心意义是把推荐模型中长期分离的“序列建模”和“异构特征交互”统一成一个可反复堆叠的共同演化过程。

它不是简单把所有 Token 塞进一个 Full Transformer，也不是先把序列压成一个向量再交叉，而是让少量 Global Query 充当接口：长序列侧负责提供可读取的 K/V，交互侧负责增强 Query；两者逐层交替。这样既避免全量序列和几百个异构字段做昂贵的全连接注意力，又突破 late fusion 的表达瓶颈，为工业推荐提供了更可扩展的统一骨干。

---

## 13. HyFormer 相比 DIN 这类传统模型有什么差异？

| 维度 | DIN | HyFormer |
|---|---|---|
| 核心目标 | 候选感知兴趣池化 | 统一序列建模与异构特征交互 |
| 序列压缩 | 通常一次 attention pooling | 多 Query、多层 Cross-Attention |
| 信息流 | target → history → pooled vector | sequence → Query → feature mixing → Query → sequence |
| 多兴趣 | 通常一个聚合兴趣向量 | 可配置多个语义 Query 槽 |
| 多序列 | 常需拼接或分别 DIN 后再拼 | 分域解码，Query 层跨域融合 |
| 静态特征参与时机 | 多在 pooling 后拼接 MLP | Query 生成和每层 Boosting 都参与 |
| 可堆叠性 | 不是天然同构 backbone | Query Decoding + Boosting 可重复堆叠 |
| 复杂度控制 | 对长度通常线性 | Cross-Attention 对长度线性，交互集中在少量 Query |

一句话说：DIN 重点回答“当前候选与哪些历史相关”，HyFormer进一步回答“候选、画像、多路历史和上下文如何在多层中相互修正”。

---

## 14. 为什么 DIN 不具备 scaling up 潜力，而 HyFormer 可以？

### 面试回答

更严谨的说法不是“DIN 完全不能扩展”，而是**DIN 缺少经过验证的高收益、同构 scaling 路径**。

DIN 的关键瓶颈是一次候选感知池化。增加 attention MLP 宽度或后置 DNN 深度会增加参数，但序列仍然很早被压成一个兴趣向量，信息瓶颈没有改变；而且不同模块形态不统一，扩深后不一定能稳定获得收益。

HyFormer 的基本单元是可重复堆叠的 Query Decoding + Query Boosting。增加层数时，每层不是重复处理同一个静态向量，而是让更强的 Query 重新读取新的序列 K/V；增加 Query 数、宽度、序列侧容量或交互侧容量也都有明确语义。再加上 Cross-Attention 对序列长度近似线性、RankMixer 使用规则化 Token Mixing 和大矩阵 FFN，新增参数更容易转化成有效表达与 GPU 吞吐。

因此二者差别不只是参数多少，而是新增容量是否能改变信息交互深度、是否有稳定优化路径、是否能被现代硬件高效执行。

---

## 15. Transformer 结构里是什么带来了 scaling up 能力？

### 面试回答

不是某一个算子单独带来 scaling，而是几项设计共同作用：

1. **同构可堆叠 Block**：深度增加时结构规则，优化和系统实现容易复用。
2. **残差连接和归一化**：让深层网络保持稳定梯度，是“能堆深”的基础。
3. **Attention/Token Mixing**：负责跨 Token 的动态或规则化信息路由，扩大感受野。
4. **FFN**：负责每个 Token 内部的非线性通道变换，通常承载大部分稠密参数和容量。
5. **大规模矩阵乘法与并行性**：核心计算可以用 GPU/加速器高效执行，宽度、层数和 batch 增大时硬件利用率较好。
6. **统一表示接口**：所有输入都进入固定维度 Token 空间，模块之间容易组合和扩展。

如果面试官追问“Attention 还是 FFN 更关键”，可以回答：Attention 决定信息从哪里来，FFN 决定取到的信息如何被变换和存储；Attention 提供交互结构，FFN 往往提供主要参数容量。没有残差、归一化和硬件友好的矩阵计算，两者都很难真正 scale。

---

## 16. Transformer 里的 FFN 是做什么的？

### 面试回答

Attention 主要在 Token 之间搬运和聚合信息，FFN 则在每个 Token 内部做非线性通道变换。

标准形式是：

$$
FFN(x)=W_2\,\sigma(W_1x+b_1)+b_2
$$

通常先从 $D$ 扩到 $rD$，经过 GELU、SiLU 或 SwiGLU，再压回 $D$。扩维提供更大的中间特征空间，非线性让模型学习复杂的特征组合；残差则保留原始表示并帮助优化。

可以用一句直观的话解释：**Attention 决定一个 Token 应该看谁，FFN 决定它看完之后怎么理解和加工这些信息。**

在标准 Transformer 中 FFN 对所有位置共享参数；RankMixer 论文则使用 Per-token FFN，让不同语义 Token 拥有独立参数，以适配推荐系统中高度异构的字段空间。注意：本项目代码实际仍是 shared FFN。

---

## 17. RankMixer 相比直接堆 MLP 有什么区别？

### 面试回答

直接堆 MLP 通常先把所有特征拼成一个大向量，再用全连接层处理。这样会过早抹掉 Token 的语义边界，强特征容易主导弱特征；输入维度变大时，全连接矩阵参数和计算增长快，而且没有显式、稳定的跨 Token 路由结构。

RankMixer 先保留固定数量的语义 Token，再通过无参数 reshape-transpose 把每个 Token 的不同通道子空间重新路由到其他 Token，完成全局特征交换；之后用 Per-token FFN 分别建模不同子空间，并配合残差和 LayerNorm 稳定堆叠。

所以两者的本质区别是：

- 大 MLP 是“先完全揉成一个向量，再统一学习”；
- RankMixer 是“先保留语义分区，用固定拓扑做跨 Token 交换，再对每个子空间专门加工”。

论文消融也显示，把所有 Token concat 后过一个大 MLP，或让所有 FFN 接收同一份全局输入，表现都不如 Multi-head Token Mixing；Self-Attention 路由的计算成本更高，效果也略差。

### 本项目回答的最后一句

我们的实现保留了 RankMixer 的 Token 化、无参数重排、残差和归一化，但为控制比赛数据规模下的参数量，让各 Token 共享 FFN。因此它相对纯 MLP 仍有明确的 Token routing 结构，但容量隔离弱于论文原版。

---

## 18. 高频追问与防守口径

### 18.1 Bilinear Pooling 就是完整 DIN 吗？

不是。它借用了 DIN 的 target-aware interest activation 思想，但实现是双线性 attention pooling，没有照搬 DIN 原论文中拼接 target、history、差值、乘积后经过 Local Activation Unit 的完整形式。准确称呼是“DIN-inspired Bilinear Target-Aware Pooling”。

### 18.2 为什么不用裸 dot-product？

候选 item token 与行为 token 来源不同，即使维度相同也不保证语义坐标对齐。$W_s$ 提供可学习的跨空间映射；除以 $\sqrt D$ 控制打分尺度，padding mask 避免无效位置参与 softmax。

### 18.3 为什么每个域两个 Query？

一个 Query 容易形成单一兴趣瓶颈；多个 Query 可以覆盖不同兴趣子空间。但 Query 太多会增加 Cross-Attention 和 RankMixer Token 数，也提高过拟合风险。当前每域两个是表达力与小数据稳定性的折中，不应包装成理论最优。

### 18.4 为什么 $D=64,T=16$？

完整 Token Mixing 要求 $D\bmod T=0$。当前 4 域 × 每域 2 Query = 8 个 Query，再加 8 个 NS Tokens，总计 $T=16$；$64/16=4$，每个 Token 可被均匀切成 16 个 4 维子空间。扩大到 96/128 的实验没有稳定收益，说明数据量与正则约束下不能盲目增宽。

### 18.5 项目最有价值的 insight 是什么？

候选感知不一定要作为模型末端的额外预测分支；更有效的方式可能是把它变成 Query 的生成条件，让候选语义从主干第一步开始影响历史信息的读取。也就是把 DIN 从“最终聚合器”改造成 HyFormer 的“输入路由器”。

### 18.6 项目还有什么局限？

第一，最终代码已经明确为 `baseline - 516改`，但早期 baseline 与出分配置没有保存成完全不可变的快照，部分历史分数只能从注释和目录时间线恢复；第二，本地验证与榜单的差距提示时间漂移和高基数 ID 记忆问题；第三，当前 RankMixer 不是论文完整 Per-token FFN；第四，516 候选感知模块还缺少完整的等参数、等训练预算消融。因此后续应保存 commit hash、完整 config、数据切分和每个 ablation 的独立日志。

---

## 19. 一分钟收尾版

这个项目的核心不是简单把 DIN、Transformer 和 RankMixer 堆在一起，而是重新安排它们的职责：DIN-inspired pooling 在输入端负责候选感知的软路由，HyFormer 用多个 Query 对多路行为做两轮条件读取，RankMixer 在少量 Query 与静态 Tokens 上做低成本跨域交互。这样既保留了 DIN 对候选相关兴趣的强归纳偏置，又避免一次池化过早丢失信息，并利用 HyFormer 的同构迭代结构获得更好的扩展路径。

---

## 20. 论文与资料

- [HyFormer: Revisiting the Roles of Sequence Modeling and Feature Interaction in CTR Prediction](https://arxiv.org/abs/2601.12681)
- [RankMixer: Scaling Up Ranking Models in Industrial Recommenders](https://arxiv.org/abs/2507.15551)
- [Deep Interest Network for Click-Through Rate Prediction](https://arxiv.org/abs/1706.06978)
- [TAAC 2026 赛题公开介绍：统一处理多字段序列与非序列特征，预测目标广告 pCVR](https://www.c114.net.cn/ainews/68160.html)

## 21. 对应本地实现证据

- `features/baseline - 516改/model.py`
  - `BilinearTargetAttentionPooling`
  - `MultiSeqQueryGenerator`
  - `MultiSeqHyFormerBlock`
  - `RankMixerBlock`
- `features/baseline - 516改/CHANGES.md`
- Obsidian：[[当前最优模型架构]]、[[Baseline 版本对比与高价值特征改动审计]]、[[PCVRHyFormer 模型反汇编报告]]
