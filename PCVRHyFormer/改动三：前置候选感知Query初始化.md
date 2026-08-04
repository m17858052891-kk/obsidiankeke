# 改动三：前置候选感知 Query 初始化

## 1. 原始 HyFormer 的全局 Query 是怎么来的

原始 HyFormer 的 Query 不是固定的可学习参数。它由**全部非序列特征**和**序列全局均值摘要**动态生成。

设 $F_1,\ldots,F_M$ 为用户、候选 item、上下文等非序列特征，$H=[h_1,\ldots,h_L]$ 为序列 Token。论文的单序列通用形式先做：

$$
\bar h_{\mathrm{seq}}
=
\mathrm{MeanPool}(H)
=
\frac{1}{L}\sum_{t=1}^{L}h_t
$$

再组成全局信息：

$$
g=
\mathrm{Concat}
\left(F_1,\ldots,F_M,\bar h_{\mathrm{seq}}\right)
$$

最后由多个 FFN 生成 $N$ 个 Query：

$$
Q_0=
[\mathrm{FFN}_1(g),\ldots,\mathrm{FFN}_N(g)]
$$

候选 item 包含在 $F_1,\ldots,F_M$ 中，所以原始 Query 并非完全不看候选；但候选只会通过 FFN **间接影响** Query。序列摘要仍是与候选无关的 Mean Pooling，所有有效行为在初始化时权重相同。

原论文在多序列场景中为每条序列配置专属的一组 Query，再在 Query 层进行跨序列混合；本项目将这一思路具体化为“四域各两枚 Query”。原论文定义可见 [HyFormer 第 3.3 节](https://arxiv.org/html/2601.12681)。

## 2. 当前 baseline 的 Query 是怎么来的

在本项目的改动前口径中，对每一路行为序列做 masked mean pooling：

$$
h_m^{\mathrm{mean}}
=
\frac{\sum_j m_{m,j}z_{m,j}}
{\sum_jm_{m,j}+\epsilon}
$$

再将全部静态 NS Token 与本域摘要拼接，经 FFN 生成 Query。它能表达用户在该域的一般兴趣，但缺少一个条件：**当前到底在预测哪个候选物品。**

## 3. 516 的改动：将均值摘要替换为候选感知摘要

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

## 4. 原始 HyFormer、当前 baseline 与 516 的差异

| 环节 | 原始 HyFormer | 本项目改动前 baseline | 当前 516 |
|---|---|---|---|
| 序列摘要 | 全局 Mean Pooling | 每域 masked Mean Pooling | 每域 bilinear Target-Aware Pooling |
| 候选 item 如何参与 | 与其他 NS 特征一起进 Query FFN，间接作用 | 同左 | 先作为 Attention Query，显式决定行为位置权重 |
| 初始 Query 的含义 | “全局画像下，如何读取序列” | “该域的一般兴趣如何读取” | “当前候选下，该优先从该域找什么证据” |
| 是否保留完整序列 | 是 | 是 | 是 |

因此，516 的改动不是“让 Query 第一次看到候选 item”，而是让候选 item 在 Query 生成前就显式参与**序列位置级的软筛选**。这是它与原始 HyFormer 最关键的差别。

## 5. 这项改动解决什么问题

设用户既看过运动鞋，也看过护肤品。若当前候选是跑鞋，普通均值池化会同时把两类历史混入 Query；前置候选感知会学习提高“运动鞋相关行为”的权重、降低“护肤品相关行为”的权重。于是 Query 从第一层就携带“围绕当前候选应该如何读历史”的方向。

它不是硬 `item_id` match：双线性矩阵 `W_m` 允许候选与历史在不同表征维度之间建立软语义对应。因此它能表达类目、属性或行为组合层面的相关性，也能在没有 exact match 时工作。

## 6. 为什么不只使用前置 DIN

前置池化产生的是 64 维摘要，天然存在信息压缩。因此它只用于 Query 初始化；HyFormer 仍保留完整 `[L_m,64]` 序列，并让 Query 在每层对完整 K/V 做 Cross-Attention。

```text
前置 pooling：告诉 Query 先从哪里开始找
HyFormer decoding：允许 Query 回到完整历史中反复取证
RankMixer：让一个域读到的证据影响其他域的下一轮读取
```

这也是它相较于纯 DIN 的关键：候选感知不是最终的一次性聚合，而是后续多轮检索的初始化条件。

## 7. 与后置 residual DIN 的差别

| 维度 | 前置 candidate-aware pooling | 后置 residual DIN |
|---|---|---|
| 注入时机 | Query 生成前 | 主干输出前/后 |
| 影响范围 | 两层 Cross-Attention 的读取方向 | 最终表示的补充 |
| 主干完整序列 | 保留 | 保留 |
| 主要优势 | 更早提供候选相关检索方向 | 改动保守、易于回退 |
| 主要风险 | item/history 表征未对齐时，初始化可能不稳 | 候选语义进入较晚，难影响前面已完成的交互 |

当前仓库可以确认 516 前置模块的代码结构；但缺少严格同预算日志时，不应把“它绝对优于所有后置方案”当作已证明事实。正确的实验是固定主干、数据和训练预算，仅替换 mean pooling、前置 pooling、后置 residual 三种路径。

## 8. 面试表述

> 原始 HyFormer 的 Query 由全部非序列特征和序列均值摘要生成，候选 item 会通过 FFN 间接影响 Query，但不会在初始化阶段逐位置筛选历史。我在此基础上把均值摘要替换为候选感知的双线性 pooling：候选 item 先对每域历史做软筛选，再与静态画像一起生成 Query。这样候选相关性从第一层 Cross-Attention 就参与了历史读取；与此同时完整序列仍保留给 HyFormer，所以没有把一次 DIN 池化当成最终用户表示。
