# 改动三：前置候选感知 Query 初始化

## 1. Baseline 的 Query 是怎么来的

baseline 中，对每一路行为序列做 masked mean pooling：

$$
h_m^{mean}=\frac{\sum_j m_{m,j}z_{m,j}}{\sum_jm_{m,j}+\epsilon}
$$

再将全部静态 NS Token 与本域摘要拼接，经 FFN 生成 Query。它能表达用户在该域的一般兴趣，但缺少一个条件：**当前到底在预测哪个候选物品。**

## 2. 516 的改动

候选物品的两个 Item NS Token 先求均值：

$$
q_{item}=\operatorname{mean}(N_{item})
$$

然后每一路序列各自使用一个双线性池化器：

$$
s_{m,j}=\frac{(W_mz_{m,j})^\top q_{item}}{\sqrt{D}},\qquad
\alpha_m=\operatorname{softmax}(s_m)
$$

$$
h_m^{target}=\sum_j\alpha_{m,j}z_{m,j}
$$

padding 位置在 softmax 前置为负无穷，因此不参与权重分配；全 padding 时实现会回退为零向量，避免 NaN。

最后，对每个域：

```text
8 个 NS Token 展平 + 本域 h_target
              ↓ LayerNorm
              ↓ 两套独立 FFN
           两个 64 维 Query
```

四域各两个 Query，共 8 个。完整序列没有被 `h_target` 替换，仍然进入两层 HyFormer 的 Transformer 与 Cross-Attention。

## 3. 这项改动解决什么问题

设用户既看过运动鞋，也看过护肤品。若当前候选是跑鞋，普通均值池化会同时把两类历史混入 Query；前置候选感知会学习提高“运动鞋相关行为”的权重、降低“护肤品相关行为”的权重。于是 Query 从第一层就携带“围绕当前候选应该如何读历史”的方向。

它不是硬 `item_id` match：双线性矩阵 `W_m` 允许候选与历史在不同表征维度之间建立软语义对应。因此它能表达类目、属性或行为组合层面的相关性，也能在没有 exact match 时工作。

## 4. 为什么不只使用前置 DIN

前置池化产生的是 64 维摘要，天然存在信息压缩。因此它只用于 Query 初始化；HyFormer 仍保留完整 `[L_m,64]` 序列，并让 Query 在每层对完整 K/V 做 Cross-Attention。

```text
前置 pooling：告诉 Query 先从哪里开始找
HyFormer decoding：允许 Query 回到完整历史中反复取证
RankMixer：让一个域读到的证据影响其他域的下一轮读取
```

这也是它相较于纯 DIN 的关键：候选感知不是最终的一次性聚合，而是后续多轮检索的初始化条件。

## 5. 与后置 residual DIN 的差别

| 维度 | 前置 candidate-aware pooling | 后置 residual DIN |
|---|---|---|
| 注入时机 | Query 生成前 | 主干输出前/后 |
| 影响范围 | 两层 Cross-Attention 的读取方向 | 最终表示的补充 |
| 主干完整序列 | 保留 | 保留 |
| 主要优势 | 更早提供候选相关检索方向 | 改动保守、易于回退 |
| 主要风险 | item/history 表征未对齐时，初始化可能不稳 | 候选语义进入较晚，难影响前面已完成的交互 |

当前仓库可以确认 516 前置模块的代码结构；但缺少严格同预算日志时，不应把“它绝对优于所有后置方案”当作已证明事实。正确的实验是固定主干、数据和训练预算，仅替换 mean pooling、前置 pooling、后置 residual 三种路径。

## 6. 面试表述

> baseline 的 Query 只由静态画像和序列均值得到，表达的是泛化兴趣；我把候选物品前置地接入 Query Generator，用它对每域历史做双线性软筛选，再生成 Query。这样候选相关性从第一层 Cross-Attention 就参与了历史读取。与此同时完整序列仍保留给 HyFormer，所以没有把一次 DIN 池化当成最终用户表示。
