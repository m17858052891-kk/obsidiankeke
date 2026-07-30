---
tags: [模型架构, 序列建模, SASRec, Transformer, 推荐系统, 面试]
---

# SASRec：因果自注意力序列推荐

> SASRec（Self-Attentive Sequential Recommendation）把用户历史当作 token 序列，用带因果 mask 的 Transformer 编码前缀，并预测下一个物品。它擅长并行训练与捕捉远近行为依赖。

## 1. 输入、位置与训练目标

用户序列为 $[i_1,\ldots,i_L]$，第 $t$ 个输入一般是：

$$h_t^{(0)}=e_{i_t}+p_t,$$

其中 $e$ 为 item embedding，$p$ 为位置 embedding；实践还可加时间间隔/行为类型。位置 $t$ 的状态预测 $i_{t+1}$，可用 sampled softmax、全量 softmax 或负采样 BCE。

## 2. Causal Mask 为什么必要？

训练可并行算所有位置，但第 $t$ 位只能看 $\le t$ 的行为：

$$M_{t,j}=0\ (j\le t),\quad M_{t,j}=-\infty\ (j>t).$$

它防止模型训练时偷看未来 item，保证与线上按历史前缀推理一致。它不同于 Padding Mask：前者遮未来，后者遮不存在 token，二者都需要。

## 3. 一个 Block 做什么？

每层是因果 Multi-Head Self-Attention、残差归一化、逐位置 FFN、再一次残差归一化。Self-Attention 让任意两个位置交互路径为 1；FFN 做每位置的非线性通道变换。最终可取最后有效位置 $h_L$ 与候选 embedding 点积：

$$s(c|h_L)=h_L^Te_c.$$

## 4. 为什么比 RNN 更擅长长依赖？

RNN 从第 1 步传到第 $L$ 步要经过 $L$ 次递归，易遗忘且训练串行；SASRec 中远近 token 可直接 attention，训练也能并行。但 dense attention 计算/显存为 $O(L^2d)$，并非无限长序列都适用。

## 5. SASRec、BERT4Rec、DIN

- SASRec：单向因果，训练目标与 next-item 在线前缀预测一致；
- BERT4Rec：双向 attention，随机 mask item 恢复，可利用左右文但目标不同；
- DIN：候选感知筛历史，顺序编码较弱；SASRec 先编码候选无关序列状态，便于多候选打分。

## 6. 长序列与负采样

历史过长可截最近行为、滑窗/分层、稀疏 attention、兴趣聚类或缓存状态。随机负样本太容易会让模型只学热门度；曝光未点、同类 item 等 hard negative 更有信息，但也可能有 false negative。评估要看采样策略、校准和线上延迟。

## 7. 高频问答与 30 秒回答

**为什么要位置编码？** 不加位置时 self-attention 对排列近似置换等变，无法区分先后行为。

**复杂度？** 单层约 $O(BL^2d+BLd^2)$，attention 矩阵也带来 $O(BL^2)$ 显存；短序列时 FFN/投影可能是瓶颈。

> SASRec 是因果 Transformer 序列推荐：item 加位置表示后经过 causal self-attention，用历史前缀预测下一个 item。相比 RNN，它能并行训练并直接建模远距离依赖；相比 DIN，它强调时序演化且状态可缓存，但 dense attention 的二次复杂度限制超长序列，需要截断或稀疏化策略。
