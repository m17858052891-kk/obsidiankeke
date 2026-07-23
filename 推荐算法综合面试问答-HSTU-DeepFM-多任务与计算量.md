---
tags:
  - 八股
  - 推荐系统
  - HSTU
  - DeepFM
  - MultiTask
  - FLOPs
created: 2026-07-23
---

# 推荐算法综合面试问答：HSTU、Batch、DeepFM、多任务与计算量

> 口径提醒：HSTU 全称是 **Hierarchical Sequential Transduction Units**。它的 Dense Attention 仍然包含二次复杂度；不要把论文报告的吞吐提升直接说成“理论复杂度由平方降为线性”。

## 1. HSTU 的时间复杂度是多少？

### 面试回答

设 Batch Size 为 $B$，序列长度为 $L$，模型维度为 $D$，Attention 子空间维度为 $D_a$。

单层 Dense HSTU 的主要计算包括：

1. Pointwise Projection，生成 $U,V,Q,K$：约为 $O(BLD D_a)$；若各维度同阶，可写成 $O(BLD^2)$。
2. 计算 $QK^T$ 以及聚合 $V$：约为 $O(BL^2D_a)$。
3. Pointwise Transformation 和门控：约为 $O(BLD^2)$ 或更低，取决于投影维度。

因此常用的渐近写法是：

$$
O\left(BL^2D+BLD^2\right)
$$

如果只关注随序列长度增长的 Attention 主项，就是：

$$
O(BL^2D)
$$

所以 **Dense HSTU 与标准 Transformer Attention 在序列长度上都是二次复杂度**。HSTU 不是 Linear Attention。

### Ragged/Sparse 口径

推荐场景每个用户的真实长度 $L_i$ 不同。HSTU 的 jagged kernel 不按全局最大长度补齐，实际 Attention 计算更接近：

$$
O\left(\sum_{i=1}^{B}L_i^2D_a\right)
$$

而不是：

$$
O(BL_{max}^2D_a)
$$

如果 Stochastic Length 将第 $i$ 个样本保留为 $\tilde L_i$，则训练时 Attention 成本进一步变为：

$$
O\left(\sum_i\tilde L_i^2D_a\right)
$$

这减少的是有效长度和无效 Padding 计算，不意味着 HSTU 的 Dense Attention 算法本身不再是平方复杂度。

### 一句话回答

> 单层 Dense HSTU 仍是 $O(L^2D+LD^2)$；它的优势主要来自更小常数、更少激活、变长稀疏计算和训练/推理摊销，不应回答成 $O(LD)$。

---

## 2. HSTU 为什么比传统 Transformer 更适合长行为序列？

### 面试回答

原因既包括推荐数据的归纳偏置，也包括系统设计。

第一，HSTU 使用 Pointwise Aggregated Attention，不使用跨整行归一化的 Softmax。Softmax 会把所有历史行为权重压成和为 1，因此“有 1 次相关行为”和“有 100 次相关行为”都只能分配同一总质量，容易丢失兴趣强度。HSTU 的点式激活可以保留相关行为数量和强度，这对观看时长、互动强度等推荐目标更自然。

第二，它把相对位置和相对时间直接放进 Attention Bias。推荐行为是不规则时间序列，“三分钟前点击”和“三个月前点击”的意义不同，纯位置编码不足以表达这种时间间隔。

第三，它使用门控式 Pointwise Transformation，把聚合到的信息与输入相关的 gate 做逐元素交互，更适合高基数、异构、持续变化的推荐特征。

第四，HSTU 原生支持 jagged/ragged 序列，能够只计算每个用户的真实长度，并配合 fused kernel 避免大 Attention 中间张量和 Padding 浪费。

第五，Stochastic Length 利用行为的重复性，在训练时对子序列采样，减少长历史的有效计算量，同时让模型适应不同历史长度。

第六，生成式训练让一条用户序列同时提供多个位置的监督，序列编码成本可以在多个 target 之间摊销；推理时 M-FALCON 和 KV Cache 又能复用历史表示。

### 不要这样回答

不要只说“HSTU 没有 Softmax，所以复杂度从 $O(L^2)$ 变成 $O(L)$”。去掉 Softmax 并没有去掉 $QK^T$ 和 Attention 对 $V$ 的两次二次矩阵乘法。

---

## 3. HSTU 相比 Transformer，计算量节省在哪里？

### 3.1 Block 内部的节省

- HSTU 把 Projection、Attention、门控和 Transformation 做成更紧凑的结构。
- 论文指出，相比 Transformer，Attention 外的线性层从 6 个减少到 2 个。
- 用逐元素 gate 替代标准 Transformer 中较重的独立 FFN 路径，减少 $O(LD^2)$ 部分的计算和激活。
- Q/K/V/Gate 投影、LayerNorm、Dropout、输出投影等尽量融合，减少 kernel launch 和 HBM 读写。

### 3.2 变长序列的节省

标准 Padding Batch 按 $L_{max}$ 计算，短用户会浪费大量 Attention。HSTU 的 ragged grouped GEMM 按真实 $L_i$ 计算，节省量来自：

$$
BL_{max}^2-\sum_iL_i^2
$$

### 3.3 Stochastic Length

训练时对子序列进行 feature-weighted sampling，减少实际进入 Attention 的 Token 数。由于 Attention 对长度平方增长，长度下降一半，理论 Attention 乘加量约降到四分之一。

### 3.4 激活显存

HSTU 减少中间线性层和 FFN Activation，并通过 fused/memory-efficient Attention 不显式保存完整 Attention Matrix。显存省下来后，可以训练更深网络、更长序列或更大 Batch。

### 3.5 训练样本摊销

传统 impression-level 训练可能为同一用户历史和多个 target 重复编码。Generative Training 在一次序列前向中预测多个位置，把历史编码成本摊到多个监督信号上。

### 3.6 推理候选摊销

M-FALCON 将多个候选放入 microbatch，复用历史 K/V 和可缓存计算，避免每个候选重新编码完整用户历史。

### 总结

> HSTU 的节省主要是常数、稀疏性、内存 IO 和跨 target/candidate 的重复计算，而不是简单消除所有 $L^2$ 计算。论文在长度 8192 上报告比 FlashAttention2 Transformer 快 5.3–15.2 倍，这是端到端吞吐结果，不是 Big-O 降阶。

---

## 4. Batch Size 扩大 4 倍，走 1 个 Step，是否等价于原 Batch Size 走 4 个 Step？

### 面试回答

不等价。它们只是在“看过的样本数”上相同。

设四个小 Batch 的梯度分别是 $g_1,g_2,g_3,g_4$。

大 Batch 一步是在同一个参数点 $\theta_0$ 上计算平均梯度：

$$
\theta_1=\theta_0-\eta\frac{g_1(\theta_0)+g_2(\theta_0)+g_3(\theta_0)+g_4(\theta_0)}{4}
$$

小 Batch 四步则每一步都在更新后的参数上重新计算梯度：

$$
\theta_{k+1}=\theta_k-\eta g_{k+1}(\theta_k)
$$

后面三次梯度的计算位置已经不同，因此参数轨迹不一样。

### 还会有哪些差异？

1. 大 Batch 每看相同样本只更新 1 次，小 Batch 更新 4 次。
2. 小 Batch 梯度噪声更大，可能提供正则化并帮助跳出尖锐极小值。
3. Momentum、Adam 一二阶矩、Weight Decay 被更新的次数不同。
4. 学习率调度、Warmup、EMA、梯度裁剪按 Step 触发时会不同。
5. BatchNorm 的统计量不同；Dropout 的随机掩码也不同。
6. 如果保持 Epoch 数不变，大 Batch 的总优化 Step 会减少到四分之一。

### 梯度累积是否等价？

将 4 个 Micro-batch 的 Loss 除以 4，连续 backward，但中间不 `optimizer.step()`，最后统一更新一次，这在以下条件下近似等价于 4 倍大 Batch：

- 四个 Micro-batch 使用同一个参数版本；
- Loss 缩放正确；
- 没有依赖 Batch 统计的 BatchNorm 或 Batch 内负样本/对比学习逻辑；
- 随机算子、数值精度和样本顺序影响可忽略。

但它等价的是“大 Batch 一步”，仍不等价于“小 Batch 四个优化 Step”。

### 学习率怎么调？

常见经验是 SGD 使用 Linear Scaling Rule，Batch 放大 $k$ 倍时学习率尝试放大 $k$ 倍并配 Warmup；Adam 类优化器不一定严格线性，需要重新调参。最重要的是明确 Scheduler 按 Step、Sample 还是 Token 推进。

---

## 5. DeepFM 和矩阵分解有什么关系？

### 面试回答

矩阵分解 MF 为每个用户和物品学习低维向量，通过内积预测偏好：

$$
\hat y_{ui}=b+b_u+b_i+p_u^Tq_i
$$

FM 可以看作 MF 对任意稀疏特征的推广。输入不再只有 user ID 和 item ID，而是任意 one-hot/multi-hot 特征：

$$
\hat y_{FM}(x)=w_0+\sum_iw_ix_i+
\sum_{i<j}\langle v_i,v_j\rangle x_ix_j
$$

如果输入只有一个 user one-hot 和一个 item one-hot，FM 的二阶项就是 $p_u^Tq_i$，退化为带 Bias 的矩阵分解。

DeepFM 在 FM 旁边增加 DNN 分支：

- FM 分支显式建模一阶和二阶交叉；
- Deep 分支从共享 Embedding 中学习高阶、非线性交互；
- 两路 Logit 相加后做 Sigmoid。

因此关系可以概括为：

```text
MF：只建模 user-item 内积
→ FM：推广到任意字段之间的二阶内积
→ DeepFM：FM 二阶显式交叉 + DNN 隐式高阶交叉
```

---

## 6. DeepFM 中如何显式做一阶和二阶特征交叉？

### 一阶项

每个特征学习一个标量权重：

$$
y^{(1)}=w_0+\sum_iw_ix_i
$$

对于类别特征，可以理解为每个 ID 查一张 1 维 Embedding 表；连续特征直接乘标量权重。

### 二阶项

每个特征 $i$ 学习 $K$ 维向量 $v_i$，任意两特征的交叉权重由内积生成：

$$
y^{(2)}=\sum_{i<j}\langle v_i,v_j\rangle x_ix_j
$$

它是“显式二阶”，因为明确枚举了二阶交互的数学形式；但不是为每一对特征单独学习一个参数，而是通过低秩向量内积共享统计强度，使训练中很少共现的组合也能泛化。

### 高效计算技巧

直接两两计算是 $O(N^2K)$。利用恒等式可降为 $O(NK)$：

$$
\sum_{i<j}\langle v_i,v_j\rangle x_ix_j
=\frac12\sum_{f=1}^{K}\left[
\left(\sum_iv_{i,f}x_i\right)^2
-\sum_i(v_{i,f}x_i)^2
\right]
$$

### Deep 分支

各字段 Embedding 拼接后进入 MLP：

$$
y_{deep}=MLP([v_1x_1;v_2x_2;\ldots])
$$

它学习的是隐式高阶交互，不保证每一层恰好对应几阶。

---

## 7. 你了解哪些多任务学习模型？

### 按范式回答

#### 1. Hard Parameter Sharing

- Shared Bottom：共享底座 + 每任务独立 Tower。
- 优点：简单、参数少、样本共享充分。
- 缺点：任务冲突、跷跷板现象明显。

#### 2. Expert Routing

- MMoE：共享多个 Expert，每个任务有独立 Gate。
- CGC/PLE：同时设置 Shared Experts 和 Task-specific Experts，并逐层提取。
- AdaTT：通过自适应任务到任务/专家融合增强任务差异。

#### 3. 漏斗/条件依赖建模

- ESMM/ESM2：通过 CTR、CVR 等联合建模解决样本选择偏差和数据稀疏。
- AITM：显式把上游任务信息传到下游任务，适合曝光→点击→转化等序列依赖。
- MMOE/PLE + Funnel Head：共享表示和阶段依赖可以组合使用。

#### 4. Soft Sharing

- Cross-Stitch Network：学习不同任务表示的线性组合。
- Sluice Network：更细粒度决定哪些层、哪些子空间共享。
- MTAN：用任务注意力从共享 Backbone 中选择特征。

#### 5. 优化层面的多任务

- Uncertainty Weighting：按任务不确定性自动学 Loss 权重。
- GradNorm：根据训练速度动态调节任务权重。
- PCGrad/CAGrad/MGDA：处理任务梯度冲突。

#### 6. 多场景/多域

- STAR、M2M、PEPNet 等：区分共享知识与场景特有参数。

### 面试时的组织方式

> 我会把多任务模型分成三层：结构共享方式、任务依赖方式和优化冲突处理。结构上有 Shared Bottom、MMoE、PLE；漏斗依赖有 ESMM、AITM；优化上有 GradNorm、Uncertainty Weighting、PCGrad。这样比只报模型名字更完整。

---

## 8. 多任务学习中如何处理“死专家”问题？

### 什么是死专家？

在 MoE/MMoE 中，如果 Gate 长期把权重集中给少数 Expert，其他 Expert 几乎收不到样本和梯度，就会欠训练；欠训练又让 Gate 更不愿选择它们，形成正反馈。

Dense Softmax Gate 中 Expert 通常不是严格零梯度，但权重可以小到“近似死亡”；Top-K Sparse MoE 更容易出现真正路由不到样本的 Expert。

### 解决方法

1. **Load-balancing auxiliary loss**：约束各 Expert 的路由概率或实际 Token 数更均衡。
2. **Gate entropy regularization**：训练早期提高 Gate 熵，避免过早塌缩。
3. **Noisy Gating / Gumbel Noise**：给路由加入探索噪声。
4. **Temperature schedule**：早期高温使分布平滑，后期降温形成专业化。
5. **Capacity 与最小流量约束**：设置 Expert capacity、最小路由概率或保底样本。
6. **Expert Dropout**：随机屏蔽热门 Expert，迫使 Gate 使用其他 Expert。
7. **Shared Expert + Private Expert**：PLE/CGC 中保留共享 Expert，降低某个任务独占所有流量的风险。
8. **更对称的初始化**：避免初始 Logit 偏差让某个 Expert 先发优势过大。
9. **路由 Z-loss / Logit 正则**：限制 Gate Logit 无限放大。
10. **按任务和数据分布采样**：防止大任务、大场景占满 Expert。

### 需要监控什么？

- 每个 Expert 的路由概率均值；
- 实际样本/Token 数和 Capacity Overflow；
- Expert 梯度范数、参数更新量；
- Gate 熵；
- 不同任务对 Expert 的选择矩阵；
- Expert 输出之间的相似度，防止“都活着但完全同质化”。

### 取舍

完全均匀也不是目标。MoE 需要专业化，Load Balance 只是避免极端塌缩；辅助损失太强会迫使无意义的平均路由，损害效果。

---

## 9. 除了 MMoE，还有哪些多任务学习范式？

### 面试回答

可以从四个方向说：

1. **共享程度**：Shared Bottom、Cross-Stitch、Sluice、MTAN。
2. **专家结构**：PLE/CGC、AdaTT、Sparse MoE。
3. **任务关系**：ESMM/ESM2 处理全空间漏斗，AITM 建模任务顺序依赖。
4. **梯度优化**：GradNorm/不确定性加权解决 Loss 尺度，PCGrad/CAGrad/MGDA解决梯度冲突。

如果是 CTR/CVR 漏斗任务，我会优先比较 ESMM、AITM、MMoE 和 PLE：ESMM 解决样本空间偏差，AITM 利用阶段顺序，MMoE 提供任务选择性共享，PLE 进一步隔离共享与私有知识。它们解决的问题不同，不是简单的替代关系。

---

## 10. 参数量和浮点运算次数有什么区别？

### 参数量 Params

参数量是模型中需要学习和存储的数值个数，主要影响：

- 模型容量；
- 权重显存/磁盘；
- 优化器状态和梯度显存；
- 分布式训练中的参数通信。

一个 `Linear(Din, Dout)` 的参数量为：

$$
Din\times Dout+Dout
$$

它与这个 Linear 被调用多少次无关。

### FLOPs

FLOPs 是一次前向或训练过程中执行多少浮点运算，主要受输入形状和调用次数影响。上述 Linear 对 $B\times L$ 个 Token 做前向，乘加量约为：

$$
2BL\cdot Din\cdot Dout
$$

如果按一次乘加记一个 MAC，则 MACs 约为 $BLDinDout$；报告时要说明 FLOPs 是否把乘和加算作两次。

### 典型反例

- Embedding Table 可以有几十亿参数，但一次只 Lookup 少量行，FLOPs 很低，内存和通信很重。
- 小参数的共享 Transformer Block 在大量 Token、很多层上重复使用，参数不多但 FLOPs 很高。
- Sparse MoE 总参数量很大，但每个 Token 只激活 Top-K Expert，Active FLOPs 远小于总参数对应的 Dense FLOPs。
- KV Cache 增加内存，却能减少重复 FLOPs。

### FLOPs 不等于延迟

真实延迟还取决于：

- Memory Bandwidth 和 HBM IO；
- Kernel Launch；
- 并行度、矩阵形状和 MFU；
- 稀疏算子是否真的被硬件加速；
- 通信与 AllReduce；
- Batch Size；
- Cache 命中率。

因此可能出现“FLOPs 更多但延迟更低”，因为大 GEMM 的 GPU 利用率高；也可能“参数少、FLOPs 少但很慢”，因为算子碎片化或 Memory-bound。

### 一句话回答

> 参数量回答模型要存多少、容量多大；FLOPs 回答给定输入要算多少。两者相关但不等价，延迟还要看内存 IO、并行度和硬件利用率。

---

## 11. 高频追问

### HSTU 去掉 Softmax 后，Attention 权重还归一化吗？

HSTU 使用 Pointwise Aggregated/Normalized Attention，并在聚合后使用 LayerNorm 稳定表示。它不做传统 Softmax 那种“每个 Query 对所有 Key 的权重和为 1”的全序列竞争，因此能保留相关行为数量和强度。

### HSTU 一定比 Transformer 好吗？

不一定。优势来自推荐场景的高基数、非平稳词表、长且变长的行为流、目标感知排序和专用 Kernel。对短序列、小数据、没有时间戳或无法使用 fused jagged kernel 的场景，复杂实现未必值得。

### DeepFM 的“显式”是什么意思？

指二阶交互由 FM 公式明确限定为两两内积，而不是指每一对特征拥有一份完全独立参数。其交叉权重仍通过低秩 Embedding 分解得到。

### PLE 为什么通常比 MMoE 更能缓解负迁移？

MMoE 所有 Expert 都共享，任务只能通过 Gate 选择不同组合；PLE 同时提供 Shared Experts 和 Task-specific Experts，让公共知识与私有知识有不同参数通路，并逐层分离，减少无关任务强行共享。

### 参考资料

- [Actions Speak Louder than Words: Trillion-Parameter Sequential Transducers for Generative Recommendations](https://arxiv.org/abs/2402.17152)
- [Meta Generative Recommenders 官方实现](https://github.com/meta-recsys/generative-recommenders)
