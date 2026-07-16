# 目录

- [# 范式一：基于序列预测的自回归预训练 (Autoregressive Pre-training)](#范式一基于序列预测的自回归预训练-autoregressive-pre-training)
- [# 范式二：基于完形填空的双向自监督预训练 (Masked Language Modeling, MLM)](#范式二基于完形填空的双向自监督预训练-masked-language-modeling-mlm)
- [# 范式三：基于异构图与多模态的预训练 (Graph & Multi-modality Pre-training)](#范式三基于异构图与多模态的预训练-graph-multi-modality-pre-training)
- [# 范式四：对比学习预训练 (Contrastive Learning, CL)](#范式四对比学习预训练-contrastive-learning-cl)
- [# 总结：预训练出来的 User Embedding 怎么用？（下游迁移）](#总结预训练出来的-user-embedding-怎么用下游迁移)

在推荐系统中，**预训练 User Embedding（用户表征预训练）** 是近年来非常前沿且极具工业价值的方向。它的核心思想是：**“不要让模型在每次面对新任务（如下一个点击预测、跨域推荐、冷启动）时都从零开始认识用户，而是先用海量的无监督/自监督历史行为数据，为用户打造一个通用、强大的底层基础画像（Foundation Representation）。”**

这就是 NLP 领域中 BERT/Word2Vec 思想在推荐系统中的完美复现。

为了让你全面理解，我将“如何预训练 User Embedding”拆解为四大工业界主流范式，并结合具体的模型（如 PeterRec, U-BERT 等）为你详细说明。

# 范式一：基于序列预测的自回归预训练 (Autoregressive Pre-training)

这是最直观、也是工业界（如淘宝、腾讯）最常用的一种预训练方式，核心思想是“猜你下一步干什么”。

- **怎么做：**
    1. **收集序列：** 收集用户过去极长的一段行为序列（比如过去一年点击过的所有商品 ID 构成的序列 $x_1, x_2, \dots, x_t$）。
    2. **网络结构：** 通常使用单向的 Transformer Decoder（类似 GPT）或者 GRU/LSTM（如经典的 PeterRec 模型）。
    3. **预训练任务 (Next-Item Prediction)：** 遮挡住序列的最后一个商品，强迫网络利用前 $t-1$ 个商品去预测第 $t$ 个商品。
    4. **提取 User Embedding：** 当这个网络在几十亿的数据上收敛后，对于任意一个用户，我们只需把他过往的行为序列输入网络，网络**最后一层输出的隐层状态（Hidden State）**，就是这个用户完美的预训练 Embedding。
- **代表模型：** **PeterRec (Parameter-Efficient Transfer from Sequential Behaviors for User Modeling and Recommendation)**
    - _特点：_ PeterRec 证明了，仅仅通过这种简单的自回归预训练，提取出的 User Embedding 不仅能用来做推荐，还能极其准确地预测用户的自然属性（如年龄、性别、甚至是否结婚）。

# 范式二：基于完形填空的双向自监督预训练 (Masked Language Modeling, MLM)

这种方法直接照搬了 NLP 中 BERT 的灵魂，核心思想是“不仅看过去，还要看未来，结合上下文猜中间”。

- **怎么做：**
    1. **构造完形填空：** 拿到用户的一个完整行为序列（比如 50 个点击的商品），随机把其中 15% 的商品 ID 替换成特殊的 `[MASK]` 标签。
    2. **网络结构：** 使用双向的 Transformer Encoder（完全等同于 BERT 架构）。
    3. **预训练任务 (Cloze Task)：** 让模型通过上下文（被 Mask 掉的商品的前后点击记录），去还原被 Mask 掉的真实商品到底是啥。
    4. **提取 User Embedding：** 与 NLP 类似，通常会在序列最前面加一个特殊的 `[CLS]` Token，预训练结束后，这个 `[CLS]` 对应输出的 64 维或 128 维向量，就代表了该用户的全局预训练表征。
- **代表模型：** **BERT4Rec** 和 **U-BERT**
    - _特点：_ 相比单向预测，这种方式学到的 User Embedding 包含了更丰富的双向结构上下文，对用户的长期宏观兴趣刻画得极其精准。

# 范式三：基于异构图与多模态的预训练 (Graph & Multi-modality Pre-training)

单纯用 ID 序列预训练会遇到“ID 无法跨域迁移”的痛点（比如淘宝的商品 ID 拿到饿了么就没用了）。因此，现代预训练引入了文本、图结构和异构行为。

- **怎么做：**
    1. **引入多模态：** 除了商品 ID，把商品的标题（Text）、类目（Category）、甚至用户的评论（Reviews）都经过预训练文本模型（如 RoBERTa）转化为文本向量。
    2. **异构行为图：** 用户不仅有“点击”，还有“加购”、“收藏”、“搜索”。构建一个庞大的 User-Item 异构图。
    3. **预训练任务：**
        - _边预测 (Edge Prediction)：_ 随机挖掉图里的一些边，让模型预测用户和商品之间原本是否存在连线。
        - _跨模态对齐 (Contrastive Learning)：_ 强迫模型学会“用户搜索词的 Embedding”和“他最终点击商品的 Embedding”在空间上必须靠得很近（类似 CLIP 的思路）。
- **代表模型：** **UPRec (User-Aware Pre-training for Recommender Systems)**
    - _特点：_ 通过引入多模态和异构图，即使遇到一个全新的商品 ID（冷启动），只要它有文本描述，预训练模型也能立刻把它和用户匹配上。

# 范式四：对比学习预训练 (Contrastive Learning, CL)

这是目前学术界最火爆、也是极其优雅的一种自监督预训练范式（类似于 CV 里的 SimCLR）。

- **怎么做：**
    1. **数据增强 (Data Augmentation)：** 拿到用户的一个行为序列（原始样本）。我们对它进行两种不同的“轻微破坏”：
        - _破坏 A (Crop/Drop)：_ 随机删掉 20% 的行为，或者只截取前半段。
        - _破坏 B (Reorder)：_ 把序列里某几个商品打乱顺序。
    2. **孪生网络构建正负样本：** 破坏 A 和破坏 B 产生的两个新序列，因为都来自于同一个用户，所以它们互为**正样本对 (Positive Pair)**；而来自其他用户的序列，统统视为**负样本 (Negative)**。
    3. **预训练任务 (InfoNCE Loss)：** 强迫网络把正样本对在空间里死死拉近，同时把它们和其他所有负样本远远推开。
- **代表模型：** **CL4SRec** (Contrastive Learning for Sequential Recommendation)
    - _特点：_ 这种方式不需要让模型费尽心思去预测具体是哪个商品（避开了庞大的 Softmax 词表计算），而是让模型学习“宏观的表征聚类”。它对稀疏数据的鲁棒性极强。

# 总结：预训练出来的 User Embedding 怎么用？（下游迁移）

当你花费巨大的算力，用上述任何一种方法得到了一个预训练模型（Pre-trained Encoder）后，通常有两种用法：

1. **直接提取 (Feature Extraction / Frozen)：**

    直接把用户的历史送进预训练模型，拿到一个 128 维的向量。然后把预训练模型“冻结（不更新参数）”，只把这个 128 维向量当作一个超级强力的静态特征（类似于你的 $N_{flat}$ 静态人设），直接送入下游具体的业务模型（如 CVR 预估、发券模型）里。这种做法成本极低。

2. **微调 (Fine-tuning)：**

    把预训练模型的权重作为下游业务模型的初始化权重。然后用业务数据（带标签的点击/购买数据）进行反向传播，以一个较小的学习率继续微调整个网络。这是目前能达到 SOTA（性能天花板）的标准做法。
