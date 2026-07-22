# 目录

- [[#核心修正：旧类比已经过时]]
- [[#1. 为什么后置零初始残差曾经看起来更安全]]
- [[#2. 为什么 516 前置候选感知最终更优]]
- [[#3. 新的架构类比]]

# 核心修正：旧类比已经过时

这篇文档原来把旧版 516 的风险和后置零初始残差的稳定性，类比为 Post-LN 到 Pre-LN 的演进。这个类比解释了“安全接入新模块”的工程价值，但现在需要修正：**最新复盘中，516 前置 target-aware pooling 才是更优版本。**

因此，0.826 的后置 DIN residual 不再是最优主线，而是一个保守、安全但候选语义进入较晚的备选结构。

# 1. 为什么后置零初始残差曾经看起来更安全

后置 DIN residual 的优势很清楚：

$$
h_{out}=h_{base}+W_{DIN}h_{DIN}
$$

当 $W_{DIN}=0$ 时，模型在训练起点严格等价于原始主干。这和 Pre-LN / ReZero 一类思想相似：先保住 identity path，再让新增模块逐渐发挥作用。

这个设计适合强基线上的低风险增量实验，但它也有一个代价：候选 item 信息进入太晚。主干已经处理过大量未过滤历史，无关行为可能已经在序列编码和 token mixing 中扩散。

# 2. 为什么 516 前置候选感知最终更优

516 的核心是把候选 item 语义前置到 Query Generator：

$$
e_{target}=\operatorname{MeanPool}(N_{item})
$$

$$
h^{target}_s=\sum_j \operatorname{softmax}\left(rac{(W_s h_{s,j})^T e_{target}}{\sqrt D}ight)h_{s,j}
$$

$$
Q_s=\operatorname{FFN}_s([N_{flat};h^{target}_s])
$$

这意味着 Query 从生成时就带着当前候选商品的条件。后续两层 HyFormer 不再对泛化兴趣做检索，而是在候选相关兴趣的基础上继续读序列、跨域融合。

它比后置 residual 更激进，但在当前任务中更有效，因为 CVR 请求天然已知候选 item，“先过滤历史，再推理兴趣”比“先推理泛化兴趣，最后补候选信息”更贴近业务问题。

# 3. 新的架构类比

更合适的新类比不是 Post-LN vs Pre-LN，而是：

- 后置 DIN residual：安全的输出端 adapter；
- 516 前置 target-aware pooling：条件化的输入路由 / early routing。

前者强调“不破坏主干”，后者强调“让主干一开始就处理更相关的信息”。最新结果说明，在 PCVRHyFormer 当前场景里，**early routing 的收益超过了后置 adapter 的安全收益。**
