---
title: "RankMixer与Onetrans：字节推荐场景下的两种Scaling范式"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2210247189634
---

# RankMixer与Onetrans：字节推荐场景下的两种Scaling范式

RankMixer 和 OneTrans 都研究了工业推荐模型的 scaling law：**推荐模型应该如何像大语言模型一样继续扩展？**

但两者选择了不同的切入点：

- **RankMixer：**硬件效率路线。采用 Token Mixing 和 Token-specific FFN 完成特征交互，将计算集中为 GPU 友好的大规模矩阵乘法。

- **OneTrans：**统一建模路线。将序列特征与非序列特征统一 Token 化，在同一个 Transformer 中完成序列建模和特征交互。

## Scaling Up的方向

![](86e3e9f02a3349e4-scaling.png)

Scaling Up 是指通过系统性增加模型容量、输入信息量和计算资源，持续提升模型效果。它关注的不只是“把模型做大”，更重要的是回答三个问题：

- 模型可以**沿哪些维度扩展**？

- **新增参数和计算量**能否稳定转化为**效果收益**？

- 扩展后的模型能否在 **GPU 上高效训练和部署**？

只有当模型效果能够随数据量、参数量和 FLOPs 的增长呈现稳定、可预测的提升趋势时，才能认为模型具备较好的 Scaling Law。

工业推荐模型通常可以沿以下维度进行扩展：

| 维度 <br> | 从 → 到 <br> | 收益 <br> | 成本 <br> |
| --- | --- | --- | --- |
| 序列长度 <br> | 几十条 → 千/万级长期行为 <br> | 长周期兴趣、跨天偏好 <br> | 注意力计算量、样本存储 <br> |
| 特征维度 <br> | 百级 → 千级 <br> | 更细的上下文与统计信号 <br> | 特征回填、取数时延 <br> |
| Embedding 维度 <br> | 8/16 → 64/128 <br> | 表达能力、减少哈希冲突 <br> | 表规模 = 基数 × 维度 <br> |
| NN 参数量 <br> | 百万级 → 十亿级 <br> | 拟合高阶交互 <br> | 训练吞吐、推理时延 <br> |
| 打分条数 <br> | 数百 → 千级一次打分 <br> | 减少漏斗损失 <br> | 计算量线性上涨 <br> |
| 训练数据时域 <br> | 固定窗口 → 全量 → 流式 <br> | 覆盖长尾、跟随分布漂移 <br> | 存储、样本时效一致性 <br> |

对于宽度为 D、Token 数量为 T、网络层数为 L 的稠密模型，参数量和计算量通常随这些维度共同增长。

不同扩展方向即使产生相近的参数量，也可能具有不同的硬件效率。增加宽度通常能够形成更大的矩阵乘法，提高 GPU 并行度；增加深度则会延长串行执行路径；增加 Token 数量能够引入更多信息，但也可能显著提高 Attention 的计算量。

验证 Scaling 是否成立，用有效 FLOPs 统一横轴，拟合幂律 `Metric(C) = M∞ − k·C^(−α)` 看 α 是否稳定、是否进入饱和区；同一预算下把计算分配给不同维度做等算力对比，比较边际收益；效果始终与时延、成本双轴评估，脱离时延约束的离线增益不可兑现。

传统的深度学习推荐模型在GPU上的MFU通常只有5%，而大语言模型可达到40%-60%。这个十倍的效率差距直接导致推荐系统无法享受scaling law的红利——即使增加参数量，大部分新增计算也被浪费在低效的内存访问上。它通常由多个专用模块组合而成，例如序列建模、特征交叉、多任务学习和预测塔。随着模型规模增加，这类架构容易遇到几个问题，导致传统模型难以Scaling up：

![](fb1876f46dc7818b-截屏2026-10-29_11.23.51.png)

- **==受内存访问速度限制：==**==核心操作以memory-bound为主，embedding lookup、特征交叉、序列建模等操作的访存量远大于计算量。==

- **算子碎片化：**DCN、注意力、特征级 MLP 和各种人工交叉模块具有不同的计算模式，容易产生大量小算子和中间张量读写，无法充分利用Tensor core，大部分操作都是小规模的向量运算或不规则访存。

- **模块独立扩展：**传统两段式架构通常先编码用户行为序列，再进行非序列特征交互；序列建模和特征交互分别扩展，不仅需要独立调参，也难以形成统一的 Scaling Law。新增计算可能集中在某个模块，而整体效果很快遇到瓶颈。

- **参数增长不等于有效容量增长：**增加层数、交叉模块或专家数量并不一定产生等比例收益。如果新增结构难以优化、GPU 执行效率低，或者输入信息不足，更多参数只会增加训练和部署成本。

因此，推荐模型的 Scaling Up 必须同时考虑：

> 模型容量、信息容量和硬件效率。

## 论文信息

- **标题**：RankMixer: Scaling Up Ranking Models in Industrial Recommenders（RankMixer：工业推荐系统中排序模型的规模化扩展）

- **作者**：Jie Zhu, Zhifang Fan, Xiaoxie Zhu, Yuchen Jiang, Hangyu Wang, Xintian Han, Haoran Ding, Xinmin Wang, Wenlin Zhao, Zhen Gong, Huizhi Yang, Zheng Chai, Zhe Chen, Yuchao Zheng, Qiwei Chen, Feng Zhang, Xun Zhou, Peng Xu, Xiao Yang, Di Wu, Zuotao Liu（字节跳动团队）

- **发表**：CIKM ’25（第 34 届 ACM International Conference on Information and Knowledge Management），pp. 6309–6316，2025 年 11 月 10–14 日

- **DOI**：[10.1145/3746252.3761507](https://doi.org/10.1145/3746252.3761507)

## RankMixer：硬件效率优化

## 问题背景：为什么要做Token-Mixer？

随着 LLM 的成功，推荐系统领域也面临着 Scaling Up 的迫切需求。然而，工业级推荐系统在扩展模型时面临两大核心障碍：

- **严苛的工程约束**：工业推荐系统必须在极高的 QPS 下保持严格的推理延迟，这使得计算效率成为模型设计的首要考量。

- **硬件利用率低下**：传统的推荐模型 (DLRMs) 大多沿用 CPU 时代的架构设计，包含大量非并行的手动特征交叉模块。这些算子在现代 GPU 上表现为内存密集型而非计算密集型，导致MFU极低（通常在个位数百分比）。

RankMixer 通过hardware-aware的架构设计，从根本上解决了这一问题。其核心原则是**从硬件特性反推架构设计**，将推荐模型重构为统一的、GPU友好的计算图：

- **Multi-head Token Mixing ：**该模块取代了传统的 Self-attention。RankMixer 通过将特征 Token 分配到 H 个头，并利用参数无关的混合操作进行信息交互，降低复杂度。

- **Per-token FFN：**用Per-Token FFN捕捉特征异质性，用Sparse MoE实现参数高效的模型扩展。

### （一）RankMixer 整体架构

下图展示了RankMixer的完整架构。模型核心是$$L$$层堆叠的RankMixer Block，每个block包含Multi-head Token Mixing（替代Self-Attention）和Per-Token FFN（捕捉特征异质性）两个模块。输入特征经tokenization转换为$$T$$个统一维度的token，经$$L$$层block处理后通过mean pooling产生最终输出。

![](020838a07cd2c21b-image.png)

每个RankMixer Block的前向传播/层级更新公式为：

$$\begin{aligned} \mathbf{S}_{n-1} &= \text{LN}(\text{TokenMixing}(\mathbf{X}_{n-1}) + \mathbf{X}_{n-1}) \\ \mathbf{X}_n &= \text{LN}(\text{PFFN}(\mathbf{S}_{n-1}) + \mathbf{S}_{n-1}) \end{aligned}$$

- 当前层的输入为：$$\mathbf{X}_{n-1}$$，它表示第 n−1 层的输出，并作为第 n 层的输入。

- 多头 Token 混合操作为：$$\text{TokenMixing}(\cdot)$$该模块通过残差连接和层归一化保证信息流动与训练过程的稳定性。

- 基于 Token 的前馈网络为：$$\text{PFFN}(\cdot)$$ 该模块使用相互独立的参数建模每个 Token 的语义信息，然后再进行残差连接和层归一化。

整体复杂度为$$O(LTD^2)$$ 。在Sparse MoE版本中，Per-Token FFN可替换为专家网络，在保持推理成本的前提下扩展参数量（后面会讲到）。

### （二）Token Mixing 机制

Self-Attention的计算复杂度为$$O(T^2D)$$ （$$T$$ 为token数量，$$D$$ 为隐藏维度，这里默认长序列情况下省略投影成本），来自于需要计算所有token pair之间的相似度矩阵$$QK^T$$ 。在推荐场景中特征数量可达数百上千，这个$$T^2$$ 项成为显著瓶颈。

RankMixer的核心洞察是：**推荐任务需要的是token之间的信息混合（mixing），而非基于相似度的动态加权（attention）**。例如学习"年轻用户在一线城市更喜欢科技类物品"这样的高阶交互，本质是让多个token的信息融合形成新的representation，而不一定需要显式计算token pair相似度。

Token Mixing的核心思想是：**将不同 Token 的特征切片沿特征维度重新拼接，从而实现跨 Token 的信息交换****。**如上图右下角所示，给定输入token序列$$\mathbf{X} \in \mathbb{R}^{T \times D}$$ （$$T$$ 个token，每个维度为$$D$$ ），Token Mixing包含两个步骤。

首先是**Multi-head decomposition**。将每个token分解为$$H$$ 个head：

$$[\mathbf{x}_t^{(1)} \| \mathbf{x}_t^{(2)} \| \cdots \| \mathbf{x}_t^{(H)}] = \text{SplitHead}(\mathbf{x}_t)$$

其中$$\mathbf{x}_t^{(h)} \in \mathbb{R}^{D/H}$$ 是第$$t$$ 个token的第$$h$$ 个head。这和multi-head attention的分解方式相同，不同head可以捕捉不同类型的交互模式。

然后是**Token-wise mixing**。对每个head，将所有token的该head部分拼接起来：

$$\mathbf{s}^{(h)} = \text{Concat}(\mathbf{x}_1^{(h)}, \mathbf{x}_2^{(h)}, \ldots, \mathbf{x}_T^{(h)}) \in \mathbb{R}^{TD/H}$$

这个操作的关键在于：**它改变了数据的组织方式，从"按token组织"变为"按head组织"**。原始输入$$\mathbf{X}$$ 是$$T$$ 个长度为$$D$$ 的向量（每个token一个向量），经过SplitHead和Concat后，变为$$H$$ 个长度为$$TD/H$$ 的向量（每个head一个向量）。在每个head内部，不同token的特征紧密排列在一起，为信息混合创造了条件。

实际实现中，RankMixer设置$$H=T$$ ，这样每个"head"实际包含了所有token的一部分特征。经过mixing后，token数量保持不变，便于残差连接。

从复杂度角度看，Token Mixing的计算量为$$O(TD)$$ （主要是内存重排操作）。相比self-attention的$$O(T^2D + TD^2)$$ ，当 $$T$$ 较大时（推荐场景中 $$T$$ 可能有几百上千），Token Mixing避免了 $$T^2$$ 项，复杂度显著降低。当 $$T$$ 和 $$D$$ 相近时，两者复杂度相当，但Token Mixing没有softmax的normalize操作（需要额外的reduction kernel），进一步减少了kernel开销。

![](4bd366bac50fdc56-image.png)

```Python
def token_mixing(x, num_heads):
	B, T, D = x.shape
	H = num_heads
	assert D % H ==0
	head_dim = D // H
	# 1、splithead：拆分特征维
	x=x.reshape(B, T, H, head_dim) # [B, T, H, D/H]
	# 2、transpose：交换token维与head维
	x=x.transpose(1,2)  # [B, T, N, D/H]
	# 3、concat:直接重新拼成N个D维 token
	x=x.reshape(B, T, D) # [B, T, D]
	return x
```

尽管 self-attention 在大语言模型中已被证明非常有效，但它对于推荐系统而言并非最优。在自注意力机制中，注意力权重是通过 **token 的内积计算**得出的。这种方法在自然语言处理中效果良好，因为所有 token 共享一个统一的嵌入空间。然而，在推荐任务中，**特征空间本质上是异构的。**计算两个异构语义空间之间的内积相似度是非常困难的，特别是在推荐系统中，用户侧和物品侧特征的 ID 空间可能包含数亿个元素。因此，将自注意力机制应用于此类多样化的输入，其效果可能并不优于无参数的多头 Token Mixing 方法，且会消耗更多的计算量、内存 IO 操作和 GPU 显存。

一个关键问题是：**不显式计算token pair之间的相似度，如何保证能捕捉它们之间的交互？**答案在于**多层堆叠**。单层Token Mixing实现是"feature-level mixing"——不同token的同一维度特征会相互影响（因为它们被concat到同一个向量中）。但当堆叠多层Token Mixing时，第1层的每个token输出融合了所有token的一阶信息，第2层的输入已经是第1层mixed后的结果，每个token已经包含其他token的信息，第2层再次mixing实现了二阶交互。形式化地，令$$f(\cdot)$$ 表示单层Token Mixing，$$\mathbf{X}_0$$ 为输入，则：

 $$\mathbf{X}_1 = f(\mathbf{X}_0)$$

$$\mathbf{X}_2 = f(\mathbf{X}_1) = f(f(\mathbf{X}_0))$$

$$\cdots$$

$$\mathbf{X}_L = f \circ f \circ \cdots \circ f(\mathbf{X}_0)$$ *（L times）*

由于每层Token Mixing都在特征维度进行线性变换（通过后续的FFN实现），堆叠$$L$$ 层可以建模token之间的$$L$$ 阶多项式交互。在实际推荐模型中，$$L$$ 通常为6-12层，足以捕捉所需的高阶特征交叉。

从硬件角度看，Token Mixing的核心操作是数据重排（SplitHead和Concat），这在GPU上可以通过高效的kernel实现。重排操作可以设计为连续的内存读写，充分利用GPU的内存带宽。相比attention需要计算softmax（需要全局归一化），Token Mixing的操作是局部的、可并行的。更重要的是，SplitHead、Concat和后续的FFN可以融合成一个kernel，减少kernel launch overhead，这是MFU提升的关键所在。

### （三）FFN层的创新

#### Per-Token FFN

![](17f45286bd7b1209-image.png)

以往的 DLRM 模型倾向于在单个交互模块中混合来自许多不同语义空间的特征，FFN 的参数在所有 token 间共享，这可能导致高频字段占据主导地位，训练数据中出现更频繁、梯度更大的特征类型可能对共享参数产生更强影响，从而淹没低频或长尾信号。

从RankMixer Block可以看到，Per-Token FFN为每个token配备了独立的FFN参数。标准Transformer的FFN对所有token使用相同权重：

$$\text{FFN}(\mathbf{x}) = \mathbf{W}_2 \cdot \text{GELU}(\mathbf{W}_1 \mathbf{x} + \mathbf{b}_1) + \mathbf{b}_2$$ ，

其中$$\mathbf{W}_1 \in \mathbb{R}^{D \times 4D}$$ ，$$\mathbf{W}_2 \in \mathbb{R}^{4D \times D}$$ 。这在语言模型中是合理的，所有token都在同一个语义空间中，可以学到通用规律。但推荐系统的特征完全不同：用户ID表示隐式偏好、物品类目是粗粒度分类、点击率服从长尾分布、时间戳有周期性。这些特征的语义空间和分布特性完全不同，强行用同一个FFN处理会导致参数效率损失。

RankMixer的核心设计是：**每个token有独立的FFN参数**。对于第$$t$$个token，其FFN变换为：

$$\mathbf{v}_t = \mathbf{W}_{\text{pffn}}^{t,2} \cdot \text{GELU}(\mathbf{W}_{\text{pffn}}^{t,1} \mathbf{s}_t + \mathbf{b}_{\text{pffn}}^{t,1}) + \mathbf{b}_{\text{pffn}}^{t,2}$$

其中$$\mathbf{W}_{\text{pffn}}^{t,1} \in \mathbb{R}^{D \times kD}$$ ，$$\mathbf{W}_{\text{pffn}}^{t,2} \in \mathbb{R}^{kD \times D}$$ ，$$k$$ 是FFN隐藏层扩展系数。关键在于每个token的$$\mathbf{W}_{\text{pffn}}^{t,i}$$ 是独立的，这使得：

- 每个token可以学习特定于其语义空间的变换；

- 避免不同语义空间相互干扰。

值得强调的是，**Per-Token FFN与MMoE有本质区别**。MMoE中多个expert共享同一输入，gating network动态决定权重，输出是expert的加权组合：$$\mathbf{y} = \sum_{i=1}^{E} g_i(\mathbf{x}) \cdot \text{Expert}_i(\mathbf{x})$$ （所有expert看到相同的$$\mathbf{x}$$ ）。而Per-Token FFN中每个token有独立的输入和独立的FFN：$$\mathbf{v}_t = \text{FFN}_t(\mathbf{s}_t)$$ （每个FFN看到不同的$$\mathbf{s}_t$$ ）。这种参数隔离确保不同特征空间的学习相互独立，避免高频特征dominate低频特征。

从参数效率看，假设有$$T$$ 个token，Per-Token FFN的总参数量为$$\text{Param} = 2TkD^2$$ ，相比shared FFN（$$2kD^2$$ ）增加了$$T$$ 倍。但**计算复杂度不变**：$$\text{FLOPs} = 2TkD^2$$ ，与shared FFN相同（shared FFN需对$$T$$ 个token分别计算）。关键在于增加的参数是"专门化"的，每块参数只服务于特定token，学习效率更高。

**跨特征空间交互通过Token Mixing层实现。Per-Token FFN专注于各自特征空间的深度建模，**Token Mixing确保不同token的信息混合。这种"mixing + per-token processing"的组合，在保持参数隔离的同时，通过多层堆叠（$$\mathbf{S}_{n-1} = \text{LN}(\text{TokenMixing}(\mathbf{X}_{n-1}) + \mathbf{X}_{n-1})$$ ，$$\mathbf{X}_n = \text{LN}(\text{PFFN}(\mathbf{S}_{n-1}) + \mathbf{S}_{n-1})$$ ）实现了充分的跨空间交互。

#### Sparse MoE 扩展

![](7dcc10251d59715c-image.png)

有了Token Mixing和Per-Token FFN，RankMixer已经可以高效建模特征交互。但如何扩展到十亿甚至百亿参数？直接增加模型深度和宽度会线性增加计算量，推理延迟也会同比增加，这在工业场景中不可接受。Sparse Mixture-of-Experts（MoE）提供了解决方案：**不是让所有参数都参与每个样本的计算，而是根据样本特性动态选择一部分expert**。这样模型参数量可以很大，但**每个样本的计算量是固定的**（只激活少数expert）。

MoE的理想工作模式是每个expert专门化到某种特定样本模式。但在推荐场景中，实现有效的expert specialization面临很多挑战：

- 推荐系统的输入是高维稀疏特征向量，特征组合空间是指数级的，不同样本的表示可能散布在高维空间各个角落，缺乏清晰的cluster structure，导致gating network很难学到稳定的路由策略。

- 推荐数据往往极度不均衡，头部用户可能贡献50%样本，如果gating在训练早期将大量头部样本路由到某个expert，该expert会获得更多梯度更新，后续gating会继续将样本发给它，最终导致少数expert处理大部分样本，其余expert基本不被使用。

- 即使训练时expert负载相对均衡，推理时不同时刻的请求分布可能不同，某些expert可能成为瓶颈，增加延迟variance。

面对这些挑战，RankMixer采用了两种互补的训练策略。

首先是**ReLU Routing**。标准MoE使用Top-$$k$$ + Softmax routing，所有token分配到的expert数量固定为$$k$$ 个。Top-k选择平等对待所有特征 token，将预算浪费在低信息量的 token 上，而使高信息量的 token 匮乏，这阻碍了模型捕捉 token 间差异的能力。RankMixer采用ReLU Routing允许每个token激活不同数量的expert：

$$G_{i,j} = \text{ReLU}(h(\mathbf{s}_i)), \quad \mathbf{v}_i = \sum_{j=1}^{N_e} G_{i,j} \cdot e_{i,j}(\mathbf{s}_i)$$

其中$$h(\cdot)$$ 是router网络，$$N_e$$ 是每个token可用的expert数量，$$G_{i,j}$$是token$$i$$对expert$$j$$ 的gate值。ReLU的特性使得输出可以为0（不激活）或正值（激活），高信息量token可能激活更多expert。

为控制稀疏度，添加正则化项：

$$\mathcal{L} = \mathcal{L}_{\text{task}} + \lambda \mathcal{L}_{\text{reg}}$$ ，

其中$$\mathcal{L}_{\text{reg}} = \sum_{i=1}^{N_t} \sum_{j=1}^{N_e} G_{i,j}$$ ，系数$$\lambda$$ 控制平均激活expert数量，主要解决的是激活过多、计算失去稀疏性的问题。

其次是**Dense-Training / Sparse-Inference（DTSI-MoE）策略**。Per-Token FFN已将参数量增加$$T$$倍，再加上MoE会进一步扩大expert数量，容易导致训练不充分。DTSI-MoE使用两个router：训练时使用dense router$$h_{\text{train}}$$激活所有或大部分expert确保充分训练，推理时使用sparse router$$h_{\text{infer}}$$ 只激活少数expert降低计算成本。两个router同时训练，但只有$$h_{\text{infer}}$$ 受到$$\mathcal{L}_{\text{reg}}$$ 约束：

$$G_{i,j}^{\text{train}} = \text{ReLU}(h_{\text{train}}(\mathbf{s}_i)), \quad G_{i,j}^{\text{infer}} = \text{ReLU}(h_{\text{infer}}(\mathbf{s}_i))$$

训练时前向传播使用$$G_{i,j}^{\text{train}}$$ ，但同时计算$$G_{i,j}^{\text{infer}}$$ 并对其施加稀疏正则。推理时只使用$$h_{\text{infer}}$$ 。负载均衡通过正则化项$$\mathcal{L}_{\text{reg}}$$的软约束实现。对于expert$$j$$ ，其在batch中的总激活量为$$A_j = \sum_{i=1}^{N_t} G_{i,j}$$ 。正则化项可重写为$$\mathcal{L}_{\text{reg}} = \sum_j A_j$$ ，当某个expert的$$A_j$$ 过大时，梯度$$\frac{\partial \mathcal{L}_{\text{reg}}}{\partial h_{\text{infer}}}$$ 会抑制该expert的激活概率，从而实现负载均衡。相比硬约束（如capacity限制），这种软约束不会因expert满载而强制将样本分配给次优expert，保持了路由的灵活性。事实证明，DS-MoE 既能避免专家训练不足，又能降低推理成本。

### （四）Scaling Up

RankMixer 本质上是一种高度并行且可扩展的架构。其参数量和计算成本可以沿四个正交轴进行扩展：token 数量 T、模型宽度 D、层数 L 和专家数量 E。对于全稠密激活版本，单个样本的参数量和前向 FLOPs 可计算为：

$$\#\text{Param}\approx 2kLTD^2,\mathrm{FLOPs}\approx 4kLTD^2$$

k 是调整 FFN 隐藏维度的缩放比例。在稀疏 MoE 版本中，每个 token 的有效参数和计算量进一步按稀疏比 s 进行缩放。$$s=\frac{P_{\mathrm{activated}}}{P_{\mathrm{total}}}$$

下图展示了模型 AUC 增益随参数量和前向 FLOPs 增长的变化趋势。在两种缩放口径下，RankMixer 均呈现出最陡峭且较为稳定的 Scaling Law 曲线，并始终优于其他对比模型。这说明随着参数量和计算量增加，RankMixer 能够更有效地将模型规模转化为效果收益，具有较好的可扩展性。

![](1deed9386e45b663-截屏2026-10-23_18.00.45.png)

实验观察到了与 LLM 缩放定律一致的结论：模型质量主要与参数总量相关，不同的缩放方向（深度L、宽度D、TokenT ）产生几乎相同的性能。

从计算效率的角度来看，更大的隐藏层维度会产生更大的矩阵乘法形状，从而比堆叠更多层实现更高的 MFU。最终，论文采用的 100M 和 1B 模型配置分别为：D=768 T=16 L=2、D=1536 T=32 L=2

RankMixer实现高MFU的关键在于：**所有核心操作都是compute-bound的大矩阵乘法**。Token Mixing和PFFN占据约85%计算时间，全部是矩阵乘法操作，可高效利用GPU的Tensor Core（单个矩阵惩罚的kernel的MFU可达60-80%）。相比之下，传统DLRM中Embedding lookup（40%时间，memory-bound）、小kernel操作（35%时间，MFU < 10%）和kernel launch overhead（20%时间）占据主导，有效GEMM计算仅占5%，这解释了为什么传统DLRM的MFU只有4-5%，而RankMixer可达45%。

通过hardware-aware的架构设计，RankMixer将推荐模型从碎片化设计转变为统一架构范式。算法层面，Token Mixing将复杂度从$$O(T^2D)$$ 降低到$$O(TD^2)$$ ，RankMixer主要聚焦于模型内部的计算效率优化，推荐系统pipeline中仍存在其他碎片化问题：序列建模与特征交互的分离、召回与排序的分离、多任务之间的碎片化。

下一节将介绍OneTrans如何进一步突破这些壁垒，在统一的Transformer框架中实现端到端的联合优化。

## 论文信息

- **标题**：OneTrans: Unified Feature Interaction and Sequence Modeling with One Transformer in Industrial Recommender（OneTrans：使用单一 Transformer 统一工业推荐系统中的特征交互与序列建模）

- **作者**：Zhaoqi Zhang, Haolei Pei, Jun Guo, Tianyu Wang, Yufei Feng, Hui Sun, Shaowei Liu, Aixin Sun（字节跳动与南洋理工大学团队）

- **发表**：WWW ’26（The ACM Web Conference 2026，Industry Track），pp. 8162–8170，2026 年 4 月 13–17 日

## OneTrans：统一序列与特征交叉

## 问题背景：为什么要打破两段式Pipeline？

RankMixer 通过 hardware-aware 架构设计解决了 GPU 利用率问题，但推荐系统的整体架构仍存在碎片化。工业推荐系统的排序模型，长期以来沿用一种固定范式：

- **序列建模：**先用序列模块（如 DIN、Transformer）对用户行为历史进行编码，得到压缩的用户兴趣表示；

- **特征交互：**处理非序列化的用户画像、物品特征，送入特征交互模块（如 DCNv2、Wukong、RankMixer）完成高阶交叉。这一设计被称为 **encode-then-interaction pipeline**。

这种分离式设计存在两个根本问题：

（1）**信息流受限**，行为序列被压缩为固定向量之后，才与物品和上下文特征交互，这意味着物品特征无法在序列编码阶段对用户历史产生影响——candidate-aware 的信息无法逆向流入序列表示。

（2）**执行碎片化**，两模块独立执行，无法享受 LLM 的系统优化（KV Caching、FlashAttention），且需分别调优，难以形成统一 scaling law。

OneTrans 提出根本性架构革新：**将序列特征与非序列特征统一表示为 Token 序列，****用单一 Transformer backbone 同时完成序列建模和特征交互**。如下图所示，OneTrans 通过统一 tokenizer 将序列特征（S-tokens）和非序列特征（NS-tokens）转为统一 token 序列，在堆叠 Transformer 层中联合建模，打破序列与特征的信息壁垒，为应用 LLM 系统优化奠定基础。

![](49cd3beee8957c0b-image.png)

### （一）统一 Tokenization

OneTrans 的第一步是通过 Tokenizer 将所有输入特征映射为统一维度 d 的 Token 序列。特征被分为两类：来自用户行为历史的**序列特征（S-tokens）**，以及来自用户画像、物品属性、上下文信息的**非序列特征（NS-tokens）**。

#### 序列特征的 Token 化

对于点击序列、购买序列等多路行为序列，每一个交互事件（event）由 item ID 与其 side information（如类目、价格）拼接后，通过共享 MLP 投影到统一维度 d，得到对应的 S-token。

多路行为序列的融合方式有两种：若时间戳可用，则按时间交织排列；若时间戳不可用，则按行为意图强度（purchase → add-to-cart → click）有序拼接，并在序列边界处插入可学习的 \[SEP\] token 以区分边界。消融实验表明，**时间戳感知的融合方式优于意图排序方式**，因此在特征可用时应优先选择。

最终得到的 S-tokens 表示为：$$\mathbf{X}_{S} \in \mathbb{R}^{L_{S} \times d}$$

其中，L_S 为全部行为事件数量与 \[SEP\] token 数量之和。

#### 非序列特征的 Token 化：两种方案

非序列特征的 Token 化是 OneTrans 与前序工作（如 RankMixer）的重要区别之一。论文提出了两种方案。

**Group-wise Tokenizer**

Group-wise Tokenizer 按语义对特征进行人工预先分组。例如，将所有用户画像特征划为一组 g_1，物品特征划为 g_2，上下文特征划为 g_3，统计特征划为 g_4。每组特征在组内拼接后，通过各自独立的 MLP 投影为一个 d 维 Token：

$$\text{NS-tokens} = [\text{MLP}_1(\text{concat}(g_1)), \ldots, \text{MLP}_{L_{NS}}(\text{concat}(g_{L_{NS}}))]$$

这种方式语义清晰，但需要人工维护分组规则，并且多个独立 MLP 会带来多次 GPU kernel 启动开销。

**Auto-Split Tokenizer**

Auto-Split Tokenizer 更加自动化：将所有非序列特征统一拼接为一个向量，通过一次 MLP 投影到 L_NS × d 维空间，再按维度切分为 L_NS 个 Token：

$$\text{NS-tokens} = \text{split}(\text{MLP}(\text{concat}(\mathcal{NS})), L_{NS})$$

以一个具体例子说明：假设所有非序列特征拼接后的维度为 1000，预设 L_NS = 12，每个 Token 的维度 d = 80，则 MLP 的输出维度为 12 × 80 = 960，随后按每 80 维切分为 12 个 Token。

值得注意的是，L_NS 是一个**人工设定的超参数**，工业系统中通常取 8 至 32 之间。

Auto-Split 的优势在于只需要一次稠密矩阵乘法，减少了 kernel 启动开销。更重要的是，MLP 的权重矩阵是 dense 的，每个输出维度都可以感知全部输入特征，因此模型可以**自动学习跨语义类别的特征组合**，不受人工分组规则的约束。消融实验表明，Auto-Split 在 CTR 和 CVR 指标上均优于 Group-wise 方案。

需要指出的是，在 Auto-Split 中，一个特征的信息可能被分散到多个 Token 中。这并非设计缺陷，而是一种 distributed representation，类似于 NLP 中词向量的工作方式。后续 Transformer 层中的 token-level attention 能够重新整合这些分布式信息。

 ![](af00a9c59c446313-image.png)

### （二）混合参数化的因果注意力

如果直接用标准 Transformer 处理统一 token 序列，会遇到推荐系统特有的问题：**token 的异质性**。在 LLM 中，所有 token 都是词或 sub-word，语义空间相对统一，因此所有 token 共享 Q/K/V 和 FFN 参数是合理的。但在 OneTrans 中，S-tokens 来自行为序列（同质性强，都是用户与物品的交互事件），而 NS-tokens 来自完全不同的特征空间（用户年龄是人口统计学特征、物品价格是数值特征、查询词是文本特征）。如果强制所有 token 共享参数，会导致参数冲突，例如用于捕捉"序列中相邻物品相似性"的参数，对于"用户年龄 → 物品类目"的交互可能完全不适用。

OneTrans 的核心创新是 **Mixed Parameterization**：**S-tokens 共享一套参数，每个 NS-token 拥有独立的 token-specific 参数**。这种设计基于两个观察：

（1）行为序列中的所有事件都在同一语义空间（物品空间），可以高效地共享参数学习序列模式；

（2）非序列特征来自异构空间，需要独立参数捕捉各自的特性。

#### Mixed Causal Attention

![](972e50f0a267f1d4-image.png)

在 OneTrans Block 中，Multi-Head Attention 的 Q/K/V 计算采用混合参数化。对于第 i 个 token，其 query、key、value 计算为：

$$(\mathbf{q}_i, \mathbf{k}_i, \mathbf{v}_i) = (\mathbf{W}^Q_i \mathbf{x}_i, \mathbf{W}^K_i \mathbf{x}_i, \mathbf{W}^V_i \mathbf{x}_i)$$

参数的分配遵循混合策略：

![](24a2d438a3392e94-截屏2026-10-23_11.23.46.png)

这一设计的理由非常直接。S-tokens 来自同质化的行为事件，其语义空间相似，共享参数不仅合理而且参数利用率更高；而 NS-tokens 分别来自用户画像、物品属性、上下文信息，语义空间差异显著，若强制共享参数，模型将无法区分这些 Token 的异质语义，导致表达能力下降。消融实验中，将所有 Token 强制共享参数会使模型参数量大幅下降，同时带来明显的指标下滑。

OneTrans 采用 **Causal Attention Mask**，但 NS-tokens 放置在 S-tokens 之后，这导致了以下三个关键的信息流模式。

1. **S-side 因果依赖**：每个 S-token 只能 attend 到它之前的 S-tokens。对于 timestamp-aware 序列，这自然建模了时间因果关系；对于 timestamp-agnostic 序列（按意图排序），causal mask 让高意图行为（如下单）的信息可以传递到低意图行为（如点击），实现"从强信号过滤弱信号"的效果。

2. **NS-side 全局 attention**：每个 NS-token 可以 attend 到**所有** S-tokens（完整行为历史）以及它之前的 NS-tokens。这使得非序列特征可以充分利用序列证据，例如"物品类目"token 可以 attend 到所有历史点击的物品类目，自动学习"用户对该类目的历史偏好"。

3. **支持 Pyramid**：Causal mask 的方向性使得信息自然向序列尾部聚集，为后续的 Pyramid Stack 提供了理论基础（详见下一节）。

#### Mixed FFN

![](efca0b329c17c1d1-image.png)

Feed-Forward Network 同样采用混合参数化：

$$\text{MixedFFN}(\mathbf{x}_i) = \mathbf{W}^{2}_i \cdot \phi(\mathbf{W}^{1}_i \mathbf{x}_i + \mathbf{b}^1_i) + \mathbf{b}^2_i$$

其中$$\mathbf{W}^1_i, \mathbf{W}^2_i$$遵循与 attention 相同的条件参数化：S-tokens 共享$$\mathbf{W}^1_{\text{S}}, \mathbf{W}^2_{\text{S}}$$，每个 NS-token 有独立的$$\mathbf{W}^1_{\text{NS},i}, \mathbf{W}^2_{\text{NS},i}$$。

这里需要与 RankMixer 的 Per-Token FFN 做对比。RankMixer 为**每个** token 配备独立 FFN（包括序列 token），参数量为$$O(T \cdot d^2)$$ （$$T$$为 token 总数）。OneTrans 的 Mixed FFN 只为$$L_{NS}$$个 NS-tokens 配备独立参数，S-tokens 共享，参数量为$$O(L_{NS} \cdot d^2 + d^2)$$ 。在推荐场景中，$$L_{NS} \ll L_S$$（非序列特征数量远小于序列长度），这使得 OneTrans 在保持表达能力的同时显著降低了参数开销。更重要的是，**参数共享不是妥协，而是设计**，行为序列的同质性使得共享参数可以更高效地学习序列模式，避免参数冗余。

OneTrans 使用 **Pre-norm + RMSNorm**。在推荐场景中，S-tokens 和 NS-tokens 的数值范围和统计特性差异显著，Post-norm 容易导致 attention 分数的尺度失衡（某些 token 的 attention logits 过大）引发训练不稳定。Pre-norm 在每个子层之前先归一化，确保输入 attention 和 FFN 的 token 表示在相近的尺度上，RMSNorm 进一步通过 root mean square 归一化提供更稳定的梯度传播。

### （三）Pyramid Stack：渐进式蒸馏

![](d16b39d68013e35c-image.png)

OneTrans 的 Causal Attention 有一个重要特性：**信息自然向序列后方聚集**。在第 n 层，位置 i 的 token 融合了从第 1 个位置到第 i 个位置的信息；到第 n+1 层，位置 i+1 又融合了更新后的第 1 个位置到第 i+1 个位置的信息。随着层数加深，**靠后的 token 逐渐成为前面所有 token 信息的"汇聚点"**。特别地，NS-tokens 位于序列末尾，它们在深层会积累整个序列和前面 NS-tokens 的信息。

Pyramid Stack 正是利用这一特性：**逐层减少参与 attention 计算的 query token 数量，只保留序列尾部的 token**。通过逐层收缩token长度，==将最重要的信息逐步汇聚，在保持高阶交互能力的同时大幅降低计算开销。==具体地，设第$$n$$层的输入 token 序列长度为$$L$$，定义一个尾部索引序列$$\mathcal{Q} = [L-L'+1, \ldots, L]$$

其中，保留长度 L' 小于原序列长度 L。在 attention 计算中：

- **Keys 和 Values**：仍然从所有$$L$$个 token 计算，保持完整的上下文信息

- **Queries**：只从$$\mathcal{Q}$$中的$$L'$$  个 token 计算

$$\mathbf{q}_i = \mathbf{W}^Q_i \mathbf{x}_i, \quad i \in \mathcal{Q}$$

Attention 输出只保留$$\mathcal{Q}$$对应位置的结果，序列长度从$$L$$收缩到$$L'$$。通过在多层之间设置递减的$$L'$$（如 1190 → 595 → 297 → ... → 12），形成金字塔式的层级结构。

这种设计带来以下两个核心收益。

1. **Progressive Distillation（渐进式蒸馏）**：长行为序列（可能有数百上千个事件）通过逐层收缩，将信息逐步"蒸馏"到少量尾部 token 中。浅层 Transformer 学习局部模式（如相邻物品的相似性），深层 Transformer 在压缩后的 token 上学习全局模式（如长期兴趣漂移）。最终，所有序列信息都汇聚到 NS-tokens 中，为下游任务提供紧凑但信息丰富的表示。

2. **Compute Efficiency（计算效率）**：标准 Transformer 的 attention 复杂度为$$O(L^2 d)$$，FFN 复杂度为$$O(Ld^2)$$。Pyramid 将复杂度降低到$$O(LL'd)$$（attention）和$$O(L'd^2)$$（FFN）。当$$L' \ll L$$时（如序列长度从 1190 逐层减少到 12），计算量和激活内存都显著下降。

与标准 Transformer 相比，Pyramid Stack 的关键差异在于：标准 Transformer 需要在每一层保持完整序列长度，因为 LLM 需要输出每个位置的预测（如 next-token prediction）。而推荐任务只需要最终的排序分数，中间的序列 token 可以逐层丢弃，只要保证尾部 token 充分融合了历史信息即可。Causal attention 的方向性保证了这一点。

### （四）训练部署优化：Cross-Request KV Caching

统一架构的一个关键优势是可以无缝应用 LLM 的系统优化，其中最重要的是 **KV Caching**。在推荐场景中，一次请求通常返回数百个候选物品，每个候选对应一个样本。这些样本的**用户侧特征完全相同**（同一用户、同一行为序列），只有物品侧特征不同。传统 encode-then-interaction 架构中，序列编码模块虽然可以复用，但特征交互模块必须为每个候选重新计算，无法充分利用这种共享结构。

OneTrans 的统一 Transformer 自然地支持以下两阶段计算。

**Stage I（S-side，once per request）**：处理所有 S-tokens，计算每一层的 key、value 以及 attention 输出，并将它们缓存起来。这一阶段**每个请求只执行一次**，与候选数量无关。

**Stage II（NS-side，per candidate）**：对于每个候选物品，计算其对应的 NS-tokens，然后在每一层执行以下操作：

- 使用缓存的 S-side keys 和 values

- 计算 NS-tokens 的 queries

- 执行 Cross-Attention：NS-tokens attend 到缓存的 S-side keys

- 执行 NS-tokens 之间的 Self-Attention

- 通过 token-specific FFN 处理 NS-tokens

这种分解的关键在于：**S-tokens 的 KV 在所有候选之间共享，只有 NS-tokens 的 QKV 需要为每个候选重新计算。**假设一次请求有$$C$$个候选，传统方法需要$$O(C \cdot L_S)$$的序列计算，而 KV Caching 将其降低到$$O(L_S + C \cdot L_{NS})$$。由于$$L_{NS} \ll L_S$$（非序列特征数量远小于序列长度），实际复杂度近似$$O(1)$$（相对于候选数$$C$$）。

更进一步，OneTrans 实现了 **Cross-Request KV Caching**。用户的行为序列是 append-only 的，每次新请求相比上一次请求，只是在序列末尾新增了少量行为事件。因此，可以在多个请求之间复用 KV cache，具体分为以下两种情况。

- **首次请求**：计算完整序列的 KV，缓存

- **后续请求**：只计算新增的$$\Delta L$$个行为事件的 KV，与旧 cache 拼接

这将每次请求的序列计算从$$O(L_S)$$降低到$$O(\Delta L_S)$$ （$$\Delta L_S$$  通常只有个位数）。在高频推荐场景（如信息流刷新），用户行为序列在短时间内变化很小，Cross-Request KV Caching 的收益尤为显著。

需要注意的是，KV Caching 的有效性依赖于**统一的 Transformer 计算图**。如果序列建模和特征交互是两个独立模块，它们各自的中间表示无法跨候选复用**（因为两个模块的输入和参数完全不同）**。OneTrans 通过统一 tokenization 和 Mixed Parameterization，将两类特征置于同一个 attention 矩阵中，使得 S-tokens 的 KV 可以被所有候选的 NS-tokens 共享。这是 encode-then-interaction 架构无法实现的。

除了 KV Caching，OneTrans 还继承了 LLM 领域的其他系统优化：**FlashAttention-2** 通过 kernel fusion 和 memory tiling 减少 attention 的 I/O 开销，显著降低激活内存占用；**Mixed-Precision Training**（BF16/FP16）和 **Activation Recomputation** 结合使用，在保持数值稳定性的前提下进一步压缩内存。这些优化对于训练和部署大规模 OneTrans 模型（数亿参数）至关重要。

### （五）Scaling Up

Onetrans可以分别从输入长度、模型深度和模型宽度三个维度扩展，分析模型效果与计算量之间的关系。

**Length（输入长度）**：用户行为序列包含的 Token 数量。增加序列长度可以让模型接触更多历史行为，获得更丰富的用户兴趣证据。实验中，Length 是收益最显著的缩放维度。

**Depth（模型深度）**：堆叠的 OneTrans Block 数量。增加深度可以进行多轮 Token 交互，逐层提取更高阶的序列关系与特征组合，因此通常比单纯增加宽度带来更明显的效果提升。

**Width（模型宽度）**：Token 隐藏状态的维度，记为d。增加宽度可以提升单层模型的表达能力，同时形成规模更大的矩阵乘法，具有较好的 GPU 并行效率。但宽度增加也会显著提高每层的参数量、计算量和激活内存占用。

实验表明，在一定模型规模和计算量范围内，OneTrans 的效果增益与 FLOPs 呈现近对数线性线性关系：随着计算资源持续增加，模型性能能够稳定、可预测地提升。这说明 OneTrans 具有较明确的 Scaling Law，其扩展行为与大语言模型中观察到的缩放规律相似。

![](29df1fdfeda2a2f7-image.png)

在相同的性能增益下**，OneTrans 相比 RankMixer 与独立 Transformer 组成的两段式基线需要更少的计算资源**，其性能—计算曲线也具有更大的斜率。这说明统一架构能够更有效地将新增计算量转化为模型收益。其原因在于 OneTrans 使用同一套 Transformer 主干完成序列建模和非序列特征交互，减少了模块之间的信息压缩与结构割裂。

对比实验中的 RankMixer+Transformer 是由独立的 Transformer 序列模块和 RankMixer 特征交互模块组成的两段式模型。Scaling 实验主要扩大 RankMixer 侧，直至约 10 亿参数，而序列建模模块并未同步扩展，所以Onetrans的真正收益存疑。

OneTrans 的核心贡献在于从架构层面消除了序列建模与特征交互之间的模块壁垒。其技术路线可以归纳为三个层次的统一：

第一是**表示的统一**，通过 Tokenization 将异构特征映射为同一空间的 Token 序列；

第二是**计算的统一**，通过混合参数化的因果 Transformer 在单一计算图中完成所有类型的特征交互；

第三是**优化的统一**，通过 Pyramid Stack 和 KV Cache 等机制使整个系统能够以 LLM 工程实践为基础进行训练和部署。

在大规模工业数据集上，OneTrans 展现出接近对数线性的 Scaling Law，并在线上 A/B 测试中相较强基线（RankMixer+Transformer）取得了 +5.68% per-user GMV 的显著提升。这一结果表明，推荐系统的扩展瓶颈不仅在于模型容量，更在于信息流动的架构设计——而打通序列与特征之间的双向信息通道，正是 OneTrans 为这一问题给出的核心答案。
