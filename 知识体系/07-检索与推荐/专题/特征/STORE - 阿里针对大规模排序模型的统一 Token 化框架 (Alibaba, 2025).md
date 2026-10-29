- **论文名称**: _STORE: Semantic Tokenization, Orthogonal Rotation and Efficient Attention for Scaling Up Ranking Models_
    
- **链接**: [https://arxiv.org/abs/2511.18805](https://arxiv.org/abs/2511.18805 "null")


**论文核心思想**：传统的排序模型在不断增加特征和模型深度时，往往无法像大语言模型（LLM）那样展现出明显的“Scaling Laws（缩放定律）”。阿里认为，罪魁祸首是**高基数稀疏特征（如 Item ID）**和**特征交互带来的计算爆炸**。STORE 提出了一个完全基于 Token 的统一架构，彻底抛弃了传统的“稠密拼接到稀疏”的混合模式。

## 1. 解决的两大瓶颈

- **表征瓶颈 (Representation Bottleneck)**:
    
    - **现象**: 高维度的稀疏 ID（如淘宝几十亿的商品 ID）迫使模型的大量参数都集中在底层极其庞大的 Embedding 层。这些 Embedding 更新稀疏，导致表示呈现“低秩”状态，引发 "One-Epoch" 过拟合问题（训练一轮就过拟合，多训练反而掉点）。
        
    - **STORE 的解法**: **语义 Token 化 (Semantic Tokenization)**。将高基数特征彻底转化为低维、密集的 Semantic IDs。
        
- **计算瓶颈 (Computational Bottleneck)**:
    
    - **现象**: 如果把所有特征（用户特征、上下文特征、商品各种 ID）都当作平等的 Token 输入到 Transformer（Self-Attention）里进行交叉，特征数量一多，计算复杂度 $O(N^2)$ 就爆炸了。
        
    - **STORE 的解法**: **高效注意力 (Efficient Attention)** 和 **正交旋转 (Orthogonal Rotation)**。
        

## 2. STORE 的三大核心创新 (架构拆解)

这篇论文最精彩的部分在于它是如何处理特征并送入 Attention 层的。

### 创新一: 语义 Token 化 (针对高基数特征) 与 OPMQ

这是论文最核心的贡献，也是和 Kuaishou 使用的 RQ-Kmeans 最大的不同。

- **传统 RQ-Kmeans 的问题**: RQ 是在拟合残差，形成树状结构。但树状结构有时会导致不同层级的特征“语义纠缠”不清。
    
- **阿里的解法：OPMQ (Orthogonal, Parallel, Multi-expert Quantization)**
    
    - **并行专家 (Parallel Experts)**: 对于一个 Item 的原始预训练 Embedding（如 SASRec 提取的），OPMQ 不做残差，而是用 $K$ 个并行的“专家网络”将其映射到 $K$ 个潜在空间。
        
    - **独立量化**: 每个潜在空间独立寻找最近的 Codebook 中心，得到 $K$ 个平行的 SID。
        
    - **正交惩罚 (Orthogonal Regularization)**: **这是关键！** 为了防止这 $K$ 个专家学到一样的东西（视角重复），论文对这 $K$ 个专家网络的参数矩阵施加了**正交性约束**。数学公式：$L_{orth} = \vert{}\vert{}V V^T - I\vert{}\vert{}_F^2$。
        
    - **直白解释**: 就像盲人摸象，RQ-Kmeans 是先摸出一个大轮廓，再在这个轮廓上摸细节；OPMQ 是强制安排 $K$ 个盲人，一个人只能摸腿，一个人只能摸鼻子，大家摸到的信息（视角）必须是正交（互不重叠）的。
        

### 创新二: 正交旋转变换 (针对低基数/静态特征)

对于性别、年龄、类目这种原本就不稀疏的特征，阿里没有强行去做 SID（没必要）。

- **分组融合**: 先把这些静态特征分组，用简单的 MLP 融合成一个基础特征块 $C$。
    
- **正交旋转 (Orthogonal Rotation)**: 为了让这个基础块 $C$ 能和上面生成的 $K$ 个不同视角的 SID 更好地在 Attention 层里发生化学反应，模型使用 $K$ 组**正交矩阵**对 $C$ 进行旋转变换，生成 $K$ 个不同视角的静态特征表示 $O_i = C R_i$。
    
- **对齐**: 这样，1 个 SID 视角就对应 1 个静态特征视角，它们被拼接在一起（$X_0^i = [s_i, O_i]$），形成 $K$ 个统一的 Instance-wise Token，送入 Attention 层。
    

### 创新三: 高效注意力 (Efficient Attention)

既然特征都被统一成了 Token 序列，就可以用 Transformer 架构了。

- **MoBA (Mixture of Block Attention)**: 为了解决 $O(N^2)$ 的复杂度，STORE 没有用全局的 Self-Attention，而是借用了 LLM 领域的 MoBA 技术。
    
- **路由稀疏化**: 每个 Query 不再和所有的 Key/Value 计算注意力，而是通过一个路由网络（Router），动态决定只和最相关的几个 Block 进行计算。这就把计算量降下来了，同时过滤掉了噪声特征（Attention Dispersion）。
    

## 3. 实验效果与工业启示

- **告别 "One-Epoch"**: 论文的 Figure 2(a) 非常有意思。传统的 Item ID 模型训练超过 1 个 Epoch，AUC 就会断崖式下跌（过拟合）。而使用了 SID 的 STORE，随着 Epoch 增加，AUC 稳步提升。这证明 SID 成功地将“死记硬背的 ID”变成了“可泛化的语义表示”。
    
- **Scale Up 的潜力**: Figure 2 证明了，随着层数增加、SID 数量增加，模型效果都在稳步提升。这说明 STORE 架构确实具备了类似 LLM 的 Scaling 能力。
    

## 总结：阿里 vs. 快手，对您项目的指导意义

这两篇论文代表了两种完全不同的落地哲学：

1. **快手 (SID-Coord)**：**渐进式/插件式**。保留原有庞大的 ID 系统，把 SID 作为辅助特征，用门控（Gating）来调和。**适合项目初期，不想大改现有模型，追求快速上线验证。**
    
2. **阿里 (STORE)**：**革命式/重构式**。彻底抛弃高维稀疏 ID，全部转为并行的、正交的 SID Token，再用强大的 Attention 进行交叉。**适合项目后期，面临严重的冷启动或模型扩容瓶颈，决心重构底层架构。**
    

**建议**：在您的“司机 ID”转化项目中，考虑到落地的稳妥性，**快手的方案（配合 RQ-Kmeans）依然是首选的 Baseline**。阿里的 OPMQ（正交并行）思想非常先进，可以在后续作为 SID 生成阶段的一个“进阶优化策略”来进行对照实验。