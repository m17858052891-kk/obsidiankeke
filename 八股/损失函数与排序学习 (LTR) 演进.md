

# 目录

- [# 一、 连续数值回归 (Regression)](#一-连续数值回归-regression)
  - [# 1. 均方误差 (MSE / L2 Loss)](#1-均方误差-mse-l2-loss)
  - [# 2. 平均绝对误差 (MAE / L1 Loss)](#2-平均绝对误差-mae-l1-loss)
  - [# 3. Huber Loss (Smooth L1 Loss) - 成年人全都要](#3-huber-loss-smooth-l1-loss---成年人全都要)
- [# 二、 分类与不平衡学习 (Classification)](#二-分类与不平衡学习-classification)
  - [# 1. 交叉熵损失 (Cross-Entropy Loss)](#1-交叉熵损失-cross-entropy-loss)
  - [# 2. Focal Loss (焦点损失)](#2-focal-loss-焦点损失)
  - [# 3. Hinge Loss (折页损失)](#3-hinge-loss-折页损失)
  - [# 1. Triplet Loss (三元组损失)](#1-triplet-loss-三元组损失)
  - [# 2. InfoNCE Loss (对比损失)](#2-infonce-loss-对比损失)
- [# 1. Pointwise (单点法)](#1-pointwise-单点法)
- [# 2. Pairwise (配对法)](#2-pairwise-配对法)
- [# 3. Listwise (列表法)](#3-listwise-列表法)

在深度学习中，损失函数（Loss Function）是模型进化的“指南针”。它衡量了模型当前预测值与真实事实之间的差距，并指引优化器去更新参数。

为了梳理清楚，我们将损失函数分为三大世界：**绝对值预估世界**（基础回归与分类）、**度量与对比世界**（表征学习），以及**相对序世界**（搜索推荐的 LTR）。

# 第一部分：绝对值预估世界 (Classic Prediction)

在这个世界里，模型的目标是预测出一个尽量精确的绝对数值或绝对概率。

# 一、 连续数值回归 (Regression)

# 1. 均方误差 (MSE / L2 Loss)

- **数学公式：** $Loss = \frac{1}{n} \sum_{i=1}^n (y_i - \hat{y}_i)^2$
- **直觉：** 预测值偏离真实值越远，惩罚呈指数级剧烈增长。
- **痛点：** 对离群点（Outliers / 异常值）极其敏感。一个标注错误的异常数据，会产生巨大的 Loss，把模型带偏。

# 2. 平均绝对误差 (MAE / L1 Loss)

- **数学公式：** $Loss = \frac{1}{n} \sum_{i=1}^n \vert{}y_i - \hat{y}_i\vert{}$
- **直觉：** 线性惩罚。无论偏离多少，惩罚力度恒定。
- **优势：** 对异常值非常鲁棒（Robust）。

# 3. Huber Loss (Smooth L1 Loss) - 成年人全都要

- **机制：** 在误差较小时，它表现得像 MSE（处处平滑可导）；在误差较大时，它表现得像 MAE（对异常值鲁棒）。
- **💡 适用场景：** 目标检测（如 YOLO, Faster R-CNN）中的边界框回归（Bounding Box Regression），完美结合了 L1 和 L2 的优点。

# 二、 分类与不平衡学习 (Classification)

# 1. 交叉熵损失 (Cross-Entropy Loss)

- **二分类 (BCE)：** $Loss = - \frac{1}{n} \sum \left[ y_i \log(\hat{y}_i) + (1 - y_i) \log(1 - \hat{y}_i) \right]$
- **直觉：** 基于信息论。它不仅要求你猜对，还要求你“极其自信地猜对”。
- **适用场景：** 分类任务的绝对统治者。

# 2. Focal Loss (焦点损失)

- **数学公式：** $Loss = - \alpha_t (1 - \hat{y}_t)^\gamma \log(\hat{y}_t)$
- **痛点与突破：** 何恺明提出。在某些任务中（如 CTR 预估或目标检测），负样本（没点击/背景）占了 99%，正样本只有 1%。普通的 BCE 会被海量的简单负样本淹没。Focal Loss 引入了调节因子 $(1 - \hat{y}_t)^\gamma$：如果模型对某个样本已经预测得很准了（$\hat{y}$ 接近 1），这个调节因子就会趋近于 0，**直接让简单的样本不产生 Loss**，强迫模型把所有精力放在那些“难以区分的困难样本”上。
- **💡 适用场景：** 极端类别不平衡场景。

# 3. Hinge Loss (折页损失)

- **数学公式：** $Loss = \max(0, 1 - y \cdot \hat{y})$ （其中 $y \in \{-1, 1\}$）
- **直觉：** 支持向量机 (SVM) 的核心。只要你猜对了，并且确信度超过了一个“安全边界（Margin = 1）”，Loss 就是 0。即使你猜得特别特别准（比如 100），我也不会额外奖励你。
- **💡 适用场景：** 最大间隔分类器，要求分类边界清晰的场景。

# 第二部分：度量与对比学习世界 (Metric & Contrastive Learning)

在这个世界，模型不预测具体的概率，而是学习“如何判断两张图片或两段文本是否相似”。这是当前大模型和多模态的基石。

# 1. Triplet Loss (三元组损失)

- **机制：** 每次输入三个样本：锚点 (Anchor)、正样本 (Positive, 和锚点同类)、负样本 (Negative, 不同类)。
- **数学公式：** $Loss = \max(0, D(A, P) - D(A, N) + margin)$
- **直觉：** 强迫 Anchor 距离 Positive 的距离，比距离 Negative 的距离，至少要远一个 `margin` 的安全边际。
- **💡 适用场景：** 人脸识别（FaceNet）、细粒度图像检索。

# 2. InfoNCE Loss (对比损失)

- **机制：** Triplet 每次只拿一个负样本对比，而 InfoNCE 每次拿 **1 个正样本和** $K$ **个负样本** 进行全局对比。它本质上是一个多分类交叉熵。
- **直觉：** 把“从海量负样本中找出唯一的正样本”作为一个分类任务。负样本越多，模型学到的特征表征就越强大。
- **💡 适用场景：** 当今 **自监督学习 (Self-Supervised Learning)** 的绝对核心。SimCLR（图像）、CLIP（图文匹配）、SimCSE（文本向量化）均依赖于此。

# 第三部分：相对序世界 —— 排序学习 (Learning to Rank, LTR)

在搜索引擎或推荐系统中，用户不在乎绝对概率，只在乎“最符合我意图的商品是不是排在第一位”。

# 1. Pointwise (单点法)

- **机制：** 孤立地给每个 (User, Item) 对打一个分数，然后排序。
- **使用的 Loss：** MSE（拟合评分）或 Cross-Entropy（拟合点击率）。
- **致命痛点：** 忽略了商品之间的竞争关系，且忽略了页面位置偏误 (Position Bias)。
- **💡 适用场景：** 推荐系统的**粗排阶段 (Recall / Match)**，极度追求计算速度。

# 2. Pairwise (配对法)

- **机制：** 残酷的二元对立。每次拿出一对商品 $(A, B)$，目标是预测“A 排在 B 前面的概率”。
- **经典 Loss (BPR - Bayesian Personalized Ranking)：**

    $$Loss_{pairwise} = - \sum_{(A,B) \in D} \log \sigma(\hat{y}_A - \hat{y}_B)$$

    _(强迫模型让用户喜欢的 A 的打分，远远超过未互动的 B 的打分)_

- **优势：** 极大地提升了 Top-K 的排序能力。
- **💡 适用场景：** 工业界电商推荐系统中的**精排阶段 (Ranking)** 的常用基线。

# 3. Listwise (列表法)

- **机制：** 全局的指挥官。每次把同一个 Query（搜索词）下的**整个候选列表**塞给模型。
- **核心突破：LambdaRank / LambdaMART (微软提出)** 真实的排序指标（如 NDCG）是阶跃的、不可导的。Listwise 绕过了设计 Loss 函数，**直接定义了梯度（**$\lambda$**）**：

    $$\lambda_{A,B} = \frac{-\partial Loss_{pairwise}}{\partial (\hat{y}_A - \hat{y}_B)} \times \vert{}\Delta NDCG\vert{}$$

    _(如果交换 A 和 B 会导致极大的 NDCG 损失，模型更新它们的梯度就会极其猛烈；如果是队尾的交换，梯度就微乎其微。)_

- **💡 适用场景：** 搜索引擎（如 Google, 百度搜索）的绝对核心技术。高度依赖位置收益、需要严格优化头部 Top-3 质量的业务场景。
