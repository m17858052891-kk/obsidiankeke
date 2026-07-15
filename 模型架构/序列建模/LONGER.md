在传统的推荐系统中，受限于 Transformer $O(L^2)$ 的计算复杂度，用户行为序列通常被截断在几百到一千左右。但这会丢失极具价值的长期兴趣和周期性规律。

**LONGER (Long-sequence Optimized traNsformer for GPU-Efficient Recommenders)** 的核心使命只有一个：**打破显存与算力的物理瓶颈，将几万长度的超长序列直接塞进 Transformer 进行端到端计算。**

为了实现这个目标，LONGER 团队打出了一套极其精妙的“算法+工程”组合拳。

# 核心模块一：Token Merge 与 InnerTransformer (微观压缩术)

# 目录

- [# 1. Token Merge (宏观降维)](#1-token-merge-宏观降维)
- [# 2. InnerTransformer (微观保真)](#2-innertransformer-微观保真)
- [# 1. 因果掩码 (Causal Mask) - 守住物理底线](#1-因果掩码-causal-mask---守住物理底线)
- [# 2. 局部滑动窗口 (Local Window) - 捕捉短期兴趣转移](#2-局部滑动窗口-local-window---捕捉短期兴趣转移)
- [# 3. 稀疏/步幅注意力 (Stride Attention) - 捕捉长周期规律](#3-稀疏步幅注意力-stride-attention---捕捉长周期规律)
- [# 4. 感受野的“指数级扩大” (Dilated Receptive Field)](#4-感受野的指数级扩大-dilated-receptive-field)

面对 50,000 长度的 Token，最直观的想法是截断或降采样，但代价是丢失信息。LONGER 采用了“先打包，再梳理”的策略。

# 1. Token Merge (宏观降维)

将时间线上紧紧相邻的 $K$ 个行为 Token（例如同一分钟内连续滑过的 5 个短视频）打包成一个“宏观 Token”。

- **复杂度锐减的数学原理：** 标准 Self-Attention 的计算复杂度与序列长度的平方成正比。将长度为 $L$ 的序列按步长 $K$ 压缩后，序列长度变为 $\frac{L}{K}$。 新的计算复杂度变为：

    $$O\left( \left(\frac{L}{K}\right)^2 \cdot d \right) = \frac{1}{K^2} \cdot O(L^2 \cdot d)$$

    如果 $K=5$，Attention 的计算负担直接暴降至原来的 **1/25**。

# 2. InnerTransformer (微观保真)

**痛点：** 如果只是对这 $K$ 个 Token 求平均值（Mean Pooling）：

$$h_{macro} = \frac{1}{K} \sum_{i=1}^K x_i$$

这会彻底抹平这几个动作之间的时序先后关系（先看鼠标再看键盘 vs 先看键盘再看鼠标）。 **解法：** 在打包之前，让这 $K$ 个 Token 先穿过一个极其轻量级的单层 Transformer（即 InnerTransformer）：

$$H_{micro} = \operatorname{Transformer}_{inner}([x_1, x_2, \dots, x_K])$$

它像一个微观的“街道办”，专门理清局部几个行为的时序因果逻辑。经过它提炼出的输出（如取最后一个 Token 或池化结果）作为最终的“意图胶囊（Macro Token）”。真正做到了“极度压缩，却不失真”。

# 核心模块二：混合注意力与多层感知野 (宏观流转)

将序列压缩到几千个宏观 Token 后，直接做全连接 Attention 依然昂贵。LONGER 在全局视野采用了**混合注意力机制 (Hybrid Attention)**。

在底层矩阵运算中，注意力分数的计算公式为：

$$Attention(Q, K, V) = \operatorname{softmax}\left( \frac{QK^T}{\sqrt{d}} + M_{hybrid} \right) V$$

LONGER 通过巧妙设计掩码矩阵 $M_{hybrid}$，实现了三种注意力的融合：

# 1. 因果掩码 (Causal Mask) - 守住物理底线

严格限制信息流向，过去的节点绝对看不到未来的节点。

$$M_{causal}(i, j) = \begin{cases} 0, & \text{if } i \ge j \\ -\infty, & \text{if } i < j \end{cases}$$

_(注：_$-\infty$ _经过 softmax 后权重为 0，即完全切断联系。)_

# 2. 局部滑动窗口 (Local Window) - 捕捉短期兴趣转移

用户当下的兴趣往往受最近几个行为影响最大。设置窗口大小 $W$：

$$M_{local}(i, j) = 0 \quad \text{if } 0 \le i - j \le W$$

# 3. 稀疏/步幅注意力 (Stride Attention) - 捕捉长周期规律

**机制：** 引入步幅 $S$（Stride）。第 $i$ 个 Token 只被允许去和第 $i-S$, $i-2S$, $i-3S \dots$ 个 Token 连线。

$$M_{stride}(i, j) = 0 \quad \text{if } (i - j) \bmod S == 0$$

**物理意义：** 消费行为具有强周期性。假设步幅 $S$ 恰好对应一周的行为量，那么当前“周五晚上”的 Token 会直接跳过周一到周四的繁杂噪音，与上个“周五晚上”的行为直接进行连线，极其高效地提取跨度数千节点的周末规律。

# 4. 感受野的“指数级扩大” (Dilated Receptive Field)

既然跳着看会漏掉中间的信息，LONGER 是怎么弥补的？ 答案是**借鉴空洞卷积（Dilated Convolution）的多层堆叠思想**：

- **Layer 1:** 步幅 $S=2$（只看前天）。
- **Layer 2:** 步幅 $S=4$（基于 Layer 1 融合后的信息，再跳着看）。
- **Layer 3:** 步幅 $S=8$。 通过这种多层级交替，顶层的 Token 虽然单次 Attention 只看了远处的几个点，但在数学上，它的感受野（Receptive Field）已经以指数级扩张，间接地“看透”了几万长度的完整序列！

# 核心模块三：Global Token (中央枢纽与全知视角)

**痛点：** 即使有混合注意力，在长达几万的序列中，第 1 个行为（半年前）传递到最后 1 个行为时，信息也早就发生了严重的衰减或被噪音淹没（Long-term Dependency Vanishing）。

**解法：** 人为在时间序列之外，拼接一个或数个特殊的全局标记（Global Token，记为 $G$）。

$$Sequence_{input} = [G; T^{macro}_1, T^{macro}_2, \dots, T^{macro}_N]$$

- **一步直达的路由器：** 无论宏观 Token 排在第 1 位还是第 10000 位，它与 Global Token 计算 Attention 的物理距离**永远是 1**。
- **终生偏好的蓄水池：** 所有的局部行为都会源源不断地把特征“汇聚（Write）”到 Global Token 中（例如提取出“这个用户本质上是个硬核数码控”的底层人设）。
- **全局信息的广播塔：** 当任何一个时间节点的 Token 想要了解全局历史概况时，它不需要往前翻找一万步，只需要直接向 Global Token 进行一次“读取（Read）”即可。

# 核心模块四：极致的底层工程压榨 (System-Level Optimization)

在工业界，大模型的落地是算法与系统工程的联合战役。字节跳动的工程师为 LONGER 做了极端的硬件级托底：

1. **混合精度训练 (Mixed Precision)：** 结合 FP16/BF16 与 FP32 进行计算，这不仅仅是加速，更是把原本会被超长注意力矩阵撑爆的 GPU 显存生生抠出了一半的空间。
2. **分级存储架构 (Hierarchical Memory)：** 推荐系统的特征 Embedding 表往往高达数百 GB。LONGER 实现了极具智慧的资源调度：
    - **GPU 显存 (HBM)：** 只存放最核心、更新最高频的热门特征。
    - **CPU 内存 (DRAM)：** 存放中频特征，通过高带宽总线（PCIe/NVLink）与 GPU 通信。
    - **SSD 固态硬盘：** 存放数以亿计的低频长尾特征（几个月才出现一次的冷门商品）。 这种金字塔式的存储，完美兼顾了训练速度与硬件成本。

# 总结

如果把处理十万用户的行为序列比作“读一本十万字的小说”：

- **InnerTransformer** 是仔细研读每一段话的字里行间。
- **Local Window** 是精读当前所在的这一页。
- **Stride Attention** 是跳跃式地阅读每一章的标题。
- **Global Token** 则是拿着全书的“内容提要”随时查阅。 这一套极其精妙的组合拳，正是 LONGER 能够征服超长序列的底层密码。
