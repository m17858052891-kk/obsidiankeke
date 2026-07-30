---
tags: [模型架构, 召回, MIND, 多兴趣, 动态路由, 面试]
---

# MIND：多兴趣召回与 Behavior-to-Interest 动态路由

论文：[Multi-Interest Network with Dynamic Routing for Recommendation](https://arxiv.org/abs/1904.08030)

> MIND 的目标是为一个用户生成多个兴趣向量，而不是把所有历史强压成一个向量。每个兴趣向量都可独立去向量库召回，从而覆盖用户的多峰兴趣。

## 1. 为什么单一用户向量不够？

若用户既看数码又买美妆，把历史平均成一个向量会混合两个远离的兴趣簇。用这个“中间向量”做近邻检索，可能既不接近数码，也不接近美妆。MIND 输出 $K$ 个兴趣 capsule，使召回阶段能并行覆盖多个方向。

## 2. B2I 动态路由：从行为到兴趣槽

输入历史 item embedding 为 $e_1,\ldots,e_N$，输出兴趣向量为 $v_1,\ldots,v_K$。路由迭代的概念流程：

1. 初始化行为 $i$ 到兴趣槽 $j$ 的 logits $b_{ij}$；为了打破多个兴趣槽的对称性，实际实现通常需要随机初始化或其他非对称机制，**全部初始化为 0 且参数完全共享会使兴趣槽保持相同**。
2. 对每个行为，在 $K$ 个兴趣槽上 Softmax：$c_{ij}=\operatorname{softmax}_j(b_{ij})$。
3. 每个兴趣槽聚合分到自己的行为：$z_j=\sum_i c_{ij}S e_i$，其中 $S$ 是可学习投影。
4. 通过 squash 得到 capsule：

$$v_j=\frac{\|z_j\|^2}{1+\|z_j\|^2}\frac{z_j}{\|z_j\|}.$$

5. 用行为与兴趣槽的 agreement 更新 $b_{ij}$，再迭代数轮。

直觉上，和某个兴趣槽一致的行为会在下一轮更倾向分给该槽，因此形成软聚类。

## 3. Label-Aware Attention 为什么只在训练用？

训练时已知 target item embedding $e_t$，可用它从 $K$ 个兴趣中选择更相关的一支：

$$a_j=\operatorname{softmax}_j((v_j^Te_t)^p),\qquad v_u=\sum_ja_jv_j.$$

$p$ 控制选择尖锐程度。这样 next-item 的训练梯度主要更新和 target 相匹配的兴趣槽，促进分工。

线上没有真实 target，不能直接做这一步；而是用每个 $v_j$ 分别检索 Top-N，合并、去重、重排后送下游。这一训练—推理差异必须讲清。

## 4. 训练、服务与复杂度

训练通常将用户兴趣与正样本 item 做匹配，并配合 sampled softmax/负采样。服务时 $K$ 个兴趣向量各自访问 ANN（如 Faiss），候选合并后去重。$K$ 增大能提升覆盖，但增加路由、ANN 请求、候选合并和后续排序成本；它不是越多越好。

## 5. 不要说错的边界

- 动态路由得到的是多样化兴趣槽，**不保证纯净或互相正交**；
- attention 权重不是严格兴趣解释，也不是因果贡献；
- MIND 偏召回，通常不直接替代精排中的候选感知 DIN/Transformer；
- 冷启动、极短历史、兴趣槽塌缩和热门偏置都需额外处理。

## 6. 30 秒面试回答

> MIND 解决单用户向量无法表达多兴趣的问题。它通过 B2I 动态路由，把历史行为软分配到 $K$ 个兴趣 capsule；训练时用 target item 做 label-aware attention，让与目标最匹配的兴趣获得主要梯度。线上则用每个兴趣向量分别 ANN 召回并合并候选。核心收益是覆盖多峰兴趣，代价是多路检索和兴趣槽质量控制。
