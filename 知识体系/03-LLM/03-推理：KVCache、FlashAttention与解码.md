---
type: 知识
topics: [LLM, 推理系统]
aliases: [LLM推理机制, KVCache与FlashAttention]
---

# 推理：KV cache、FlashAttention 与解码

先修：[[知识体系/02-神经网络与Transformer/02-Attention：数学、信息流与复杂度|Attention原理]]、[[知识体系/02-神经网络与Transformer/04-位置编码与RoPE|位置编码与RoPE]]、[[知识体系/03-LLM/01-分词、自回归与语言建模|分词与语言建模]]。推理速度要同时看算术量、显存容量、显存带宽和调度。减少其中一种成本，不代表其他成本自动下降。

## 1. Prefill 与 decode 的工作不同

Prefill 处理已知 prompt，在各层计算全部位置的表示，并建立 K/V 缓存。Decode 每轮通常为每条活跃序列生成一个新 token，只新增一个位置的 Q/K/V，但新 Q 仍要读取此前所有可见 K/V。

Prefill 有大量矩阵乘法并行度，长序列下通常更容易利用计算能力；小 batch decode 每步读取大量权重与 cache，常受到带宽限制。但这只是常见工作区间：batch、模型结构、序列长度和硬件会改变瓶颈，不能用两句话替代性能测量。

## 2. 为什么能缓存 K/V，却不需要保留过去的 Q

在固定参数、causal mask 和一致位置编码下，过去 token 的各层隐藏状态不依赖未来 token，因此过去的 K/V 不变。新 token 的 Q 负责读取这些历史信息，过去的 Q 不再参与新位置输出。

若每一步都重新运行整个前缀，历史位置的投影和中间层会被重复计算。KV cache 避免这些重复；但当前 query 对历史的读取仍随上下文长度增长。因此它不是把长上下文 decode 的计算变成与长度无关。

标准缓存容量近似为：

$$M_{KV}=2\times B\times L\times n_{\mathrm{layer}}\times h_{KV}\times d_h\times s,$$

其中 2 表示 K/V，$s$ 是每个元素字节数。忽略分配碎片和元数据。例：$B=1,L=32768,n=32,h_{KV}=8,d_h=128,s=2$，缓存约为 $4$ GiB；若使用 32 个 KV heads，则约为 $16$ GiB。这解释了 GQA 降低 cache 成本的直接机制。它通过共享 K/V 改变模型结构，质量影响需相应训练和评估。[GQA 论文](https://arxiv.org/abs/2305.13245)

前缀缓存只有在输入 token、模型/适配器、位置、mask 等相关条件一致时才能复用。文本看起来相同但 token 化或系统上下文不同，不应假定 cache 相同。

## 3. FlashAttention 为什么不需要保存整个分数矩阵

普通实现可能将 $L\times L$ 注意力分数写入显存，再读出做 Softmax 与乘 V。FlashAttention 将计算分块，在较快的片上存储中维护归一化统计，减少中间矩阵的显存读写。它仍计算精确稠密 attention（允许浮点舍入差异），并不把全连接注意力的算术复杂度从二次变成线性。[FlashAttention 原论文](https://arxiv.org/abs/2205.14135)

理解核心只需看一行 query。已有一组分数的最大值 $m$、指数和 $\ell=\sum_j e^{s_j-m}$、加权和 $o=\sum_j e^{s_j-m}v_j$。读入新分块，最大值为 $m_b$，令 $m'=\max(m,m_b)$，则：

$$
\ell'=e^{m-m'}\ell+\sum_{j\in b}e^{s_j-m'},
$$
$$
o'=e^{m-m'}o+\sum_{j\in b}e^{s_j-m'}v_j.
$$

处理完所有块后输出 $o'/\ell'$。共同缩放使旧块与新块仍处在同一个归一化坐标下；这与先得到全部分数后 Softmax 在数学上等价。分块不是分别 Softmax 后直接相加，那样会错误地给每块相同总权重。

## 4. PagedAttention 解决的是缓存组织问题

请求长度不同且动态结束，连续大块分配 KV cache 容易出现预留浪费和碎片。分页组织通过逻辑块到物理块的映射管理缓存，支持按需分配、共享等机制。它不等于 FlashAttention，也不等于减少每个 token 的 K/V 维度。[PagedAttention 原论文](https://arxiv.org/abs/2309.06180)

可以将三者分开：GQA 改每个 token 存多少；FlashAttention 改 attention 的读写计算方式；分页管理改这些数据如何分配与共享。它们可以组合，但收益不应简单按论文百分比相乘。

## 5. 解码策略改变选择规则

温度为 $\tau>0$ 时：

$$p_i(\tau)=\frac{e^{z_i/\tau}}{\sum_j e^{z_j/\tau}}.$$

低温更集中，高温更平坦，但不改变 logits 的排序。Greedy 每步选最大概率，不保证整段序列概率最大：第一步选择 0.6 的分支后最佳续写概率为 0.1，另一条 0.4 的分支后续为 0.9，整段概率分别是 0.06 与 0.36。

Top-k 保留固定数量候选；top-p 按概率累计保留足够质量的候选，再归一化采样。它们改变生成分布，不是修复模型知识。Beam search 保留多个高分前缀，但序列长度计分、重复和任务效用仍需定义；更高序列概率不一定更有帮助。

Speculative decoding 用较便宜的草稿模型提出多个 token，再由目标模型验证。适当的接受/拒绝与残余分布采样可保持目标分布；简单“目标看着差不多就接受”不具备这一保证。速度取决于接受率、草稿成本和验证并行收益。[Speculative decoding 原论文](https://arxiv.org/abs/2211.17192)

## 6. 系统指标回答不同问题

TTFT 是首 token 延迟，包含排队和 prefill 等；单个后续 token 的延迟反映 decode 体验；tokens/s 可能是单请求速度，也可能是全系统吞吐。提高 batch 常能增大总吞吐，却可能提高某个请求等待时间。

长输出会持续占用 cache 与调度槽；长输入消耗 prefill 资源。只报告平均吞吐可能掩盖尾延迟和长请求饥饿。比较系统时应固定输入/输出长度分布、并发、精度、质量要求及硬件。

## 7. 自检与解析

**问：KV cache 为什么在训练时通常不是同一种收益？** 训练本就一次处理已知序列，还需保存反向所需状态；缓存跨 decode 步避免重复前缀计算的动机不同。训练中的 activation checkpointing 见 [[知识体系/03-LLM/04-训练系统：显存、并行与量化|训练系统与量化]]。

**问：FlashAttention 是近似 attention 吗？** 原始核心算法不是。它重排精确 attention 的运算和存储，浮点次序可能导致微小差异。

**问：权重量化到 4 bit，长上下文显存会同步降至四分之一吗？** 不会。KV cache、激活、临时缓冲和量化元数据各有自己的精度与大小。
