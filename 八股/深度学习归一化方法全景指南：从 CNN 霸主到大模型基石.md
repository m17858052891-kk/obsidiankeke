在深度神经网络训练中，随着层数加深，数据分布会发生偏移（Internal Covariate Shift），导致梯度消失或爆炸，网络极难训练。归一化的核心目的就是**强行把数据的分布拉回到均值为 0、方差为 1 的标准状态，让优化地貌变得平滑，从而允许使用更大的学习率，加速收敛。**

几乎所有归一化方法的底层通用公式都是一致的：

$$y = \frac{x - \mu}{\sqrt{\sigma^2 + \epsilon}} \cdot \gamma + \beta$$

_其中，_$\mu$ _是均值，_$\sigma^2$ _是方差，_$\epsilon$ _是防止分母为 0 的极小数。最关键的是_ $\gamma$_（缩放）和_ $\beta$_（平移），它们是**可学习参数**。网络在强制归一化后，可以通过这两个参数把分布“还原”到它认为最有利的状态，从而保证网络的表达能力不被破坏。_

区别各类归一化方法的唯一核心在于：**我们在哪些维度上计算均值** $\mu$ **和方差** $\sigma^2$**？**

假设一个输入张量的形状为 $(N, C, H, W)$（CV 场景下的 Batch大小、通道数、高、宽）或 $(N, L, D)$（NLP 场景下的 Batch大小、序列长度、特征维度）。

## 目录

- [1.1 Batch Normalization (BN) - CV 领域的王者](#11-batch-normalization-bn---cv-领域的王者)
- [1.2 Layer Normalization (LN) - NLP 与 Transformer 的绝佳拍档](#12-layer-normalization-ln---nlp-与-transformer-的绝佳拍档)
- [1.3 Instance Normalization (IN) - 生成对抗网络（GAN）的宠儿](#13-instance-normalization-in---生成对抗网络gan的宠儿)
- [1.4 Group Normalization (GN) - 内存受限时的 CV 救星](#14-group-normalization-gn---内存受限时的-cv-救星)
- [2.1 RMSNorm (Root Mean Square Normalization) - LLaMA 家族的标配](#21-rmsnorm-root-mean-square-normalization---llama-家族的标配)
- [2.2 DeepNorm - 解决超深层网络梯度爆炸](#22-deepnorm---解决超深层网络梯度爆炸)

# 1. 经典的“四大金刚”

## 1.1 Batch Normalization (BN) - CV 领域的王者

- **计算维度：** 跨越 Batch ($N$) 和空间维度 ($H, W$ 或 $L$)，对每一个单独的通道/特征 ($C$ 或 $D$) 计算独立的均值和方差。
- **通俗理解：** 假设你在统计全班同学的成绩，BN 是求“全班所有人的数学平均分”和“全班所有人的英语平均分”。
- **优点：** 引入了基于 Batch 的噪声（每次 Batch 抽样不同），自带一定的正则化（Dropout）效果，在 CNN 中表现无可匹敌。
- **致命痛点：**
    1. **严重依赖 Batch Size：** 如果显存不够，Batch Size 很小（比如 2 或 4），统计出来的均值和方差极其不准，模型直接崩溃。
    2. **不适应动态序列（NLP）：** 句子里词的个数（长度 $L$）不一样，大量填充（Padding）的 0 会严重污染均值计算。且测试时的分布可能与训练时不同。

## 1.2 Layer Normalization (LN) - NLP 与 Transformer 的绝佳拍档

- **计算维度：** 跨越所有的通道/特征 ($C$ 或 $D$) 和空间维度，对**每一个样本**计算独立的均值和方差。
- **通俗理解：** LN 是求“张三自己所有科目的平均分”，然后“李四自己所有科目的平均分”。
- **优点：** **彻底摆脱了 Batch Size 的限制**，哪怕 Batch Size 为 1 也能完美工作。天然适应 RNN、Transformer 等处理长短不一的序列数据。
- **缺点：** 在处理图像（CNN）时，把同一张图片的所有通道（比如红、绿、蓝特征）混在一起算均值，破坏了空间和通道特异性，因此在 CV 里效果不如 BN。

## 1.3 Instance Normalization (IN) - 生成对抗网络（GAN）的宠儿

- **计算维度：** 仅仅对**单个样本的单个通道**（空间维度 $H, W$）计算均值和方差。
- **通俗理解：** 求“张三这一次考试的数学成绩（假设有多张考卷）的平均分”。
- **应用场景：** IN 是图像风格迁移（Style Transfer）和 GAN 里的标配。因为在图像生成中，图片的“风格”往往体现在单张图片某个通道的均值和方差上，IN 能有效地滤除掉这些特定风格，便于网络重新注入新风格。

## 1.4 Group Normalization (GN) - 内存受限时的 CV 救星

- **计算维度：** 将通道 ($C$) 分成 $G$ 个组，对单个样本的**每个通道组**计算均值和方差。它是 LN 和 IN 的折中。
- **应用场景：** 在目标检测（Object Detection）或 3D 医疗影像分割中，图片往往非常大，导致 Batch Size 只能设置为 1 或 2，BN 会失效。GN 不依赖 Batch，且比 IN 保留了更多通道间的依赖关系，是高分辨率 CV 任务的救星。

# 2. 大模型时代的归一化演进（Transformer 特供）

随着 LLM（如 LLaMA、GPT-4）将 Transformer 堆叠到几十上百层，传统的 LN 也暴露出计算稍慢的缺点，于是演化出了更极简的版本。

## 2.1 RMSNorm (Root Mean Square Normalization) - LLaMA 家族的标配

- **核心理念：** 研究者发现，LayerNorm 成功的核心其实在于**方差缩放**（把数据压到同一个尺度），而不在于**均值平移**（减去 $\mu$）。
- **公式优化：** RMSNorm 直接**砍掉了计算均值和减去均值的步骤**！

    $$y = \frac{x}{\text{RMS}(x)} \cdot \gamma \quad \text{其中} \quad \text{RMS}(x) = \sqrt{\frac{1}{d}\sum_{i=1}^d x_i^2 + \epsilon}$$
- **优势：** 因为少了算均值这一步，RMSNorm 的计算速度比 LN 快 10%~50%，而在数百亿参数的大模型实验中，它的表现和标准的 LN 几乎一模一样。因此它成为了现代大模型（如 LLaMA、Gemma）的绝对主流。

## 2.2 DeepNorm - 解决超深层网络梯度爆炸

- **核心理念：** 微软提出的技术，专门解决 Transformer 层数超过 100 层后极难训练的问题。
- **方案：** 它在进行残差连接（Add）和归一化（Norm）之前，先用一个系数 $\alpha$ 放大残差分支，同时在初始化时缩小权重，从理论上保证了不管网络叠多深，梯度都被严格框定在安全范围内。

# 3. 架构位置之争：Pre-Norm vs Post-Norm

在 Transformer 中，归一化放在哪一步也是至关重要的工程细节：

- **Post-Norm（后归一化）：** `x = LayerNorm(x + Sublayer(x))`。原始 Transformer 使用。优点是表现上限稍高；缺点是网络加深后非常容易在初期训练崩溃（梯度消失/爆炸），通常需要极其精细的 Warm-up 学习率调度。
- **Pre-Norm（前归一化）：** `x = x + Sublayer(LayerNorm(x))`。现代大模型（GPT-3, LLaMA）的标准做法。在进入 Attention 或 FFN 之前先做归一化。这使得残差路径是一条不受阻挡的直通车，**极大地提升了训练的稳定性**，即使不加 Warm-up 网络也不会轻易崩溃。
