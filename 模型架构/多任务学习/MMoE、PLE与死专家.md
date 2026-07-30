---
tags: [模型架构, 多任务学习, MMoE, PLE, MoE, 面试]
---

# MMoE、PLE 与死专家

## 1. 为什么需要多任务学习？

CTR、CVR、停留时长、GMV 等任务共享用户/物品语义，却也可能梯度冲突。硬共享一个底座容易负迁移；完全分塔又浪费共享信号。多任务学习的关键是：**哪些表示共享、哪些表示隔离、每个任务如何路由。**

## 2. MMoE

MMoE 有多个共享 Expert，每个任务有独立 Gate：

$$
h_t=\sum_{e=1}^E g_{t,e}(x)\cdot \operatorname{Expert}_e(x).
$$

不同任务可对同一批 Expert 使用不同权重，因此比 Shared Bottom 更灵活；但 Expert 全部共享，任务冲突强时仍可能发生负迁移。

## 3. PLE

PLE（Progressive Layered Extraction）每层同时设置 shared experts 和 task-specific experts，并通过逐层 CGC 让任务表示越来越专属。它的核心不是 Expert 更多，而是显式提供任务私有通路，因此通常比 MMoE 更能缓解负迁移；代价是参数、训练与调参复杂度上升。

## 4. 什么是死专家？

若 Gate 长期把绝大多数流量送给少数 Expert，其他 Expert 几乎收不到梯度，就形成 dead expert。表现是 Expert usage 极不均衡、热门 Expert 过载、模型名义容量很大但实际没有被用到。

常见处理：

- load-balancing loss 或 Gate entropy 正则；
- noisy gating / 较高温度，增加早期探索；
- capacity 与最小流量约束；
- Expert Dropout，随机屏蔽热门 Expert；
- shared + private experts；
- 监控每个 Expert 的流量、loss、梯度范数与任务覆盖。

平衡约束不能过强，否则每个 Expert 被迫均匀使用，又失去专业化意义。

## 5. 面试 30 秒回答

> MMoE 通过任务独立 Gate 对共享 Expert 做软路由，适合任务相关但偏好不同的场景；PLE 在共享 Expert 外加入逐层任务私有 Expert，更主动地隔离任务冲突。死专家是 Gate 流量塌缩导致部分 Expert 没有梯度，通常用负载均衡、噪声路由、容量约束和 Expert Dropout 缓解，并同时监控均衡与专业化的取舍。

## 6. MMoE 从输入到 Loss 的完整数据流

设有 $E$ 个 Expert、$K$ 个任务。所有 Expert 先接收同一输入 $x$：

$$f_e(x),\quad e=1,\ldots,E.$$

任务 $k$ 的独立 Gate 生成一个概率分布：

$$g_k(x)=\operatorname{Softmax}(W_{g,k}x),$$

再将专家表示混合：

$$h_k(x)=\sum_{e=1}^{E}g_{k,e}(x)f_e(x),\qquad \hat y_k=\operatorname{Tower}_k(h_k).$$

最后只在任务标签可观测的位置计算 loss：

$$\mathcal L=\sum_{k=1}^K\lambda_k\,m_k\,\mathcal L_k.$$

$m_k$ 是 observation mask。没有标签不代表负样本；例如 CVR 在未点击样本上可能是不可观测而不是 0。

## 7. Shared Bottom、MMoE、PLE 怎么选？

| 架构 | 共享方式 | 适合情况 | 风险 |
|---|---|---|---|
| Shared Bottom | 全部硬共享 | 任务高度相关、资源紧 | 梯度冲突与跷跷板 |
| MMoE | 共享 Expert + 任务 Gate | 任务相关性不一致 | Expert 仍全共享，可能塌缩 |
| PLE | Shared Expert + Task-specific Expert，多层 CGC | 任务冲突强、任务差异大 | 参数/延迟/调参成本更高 |

PLE 的 CGC 中，任务 gate 可以同时选择“自己的私有 expert”和 shared expert；shared gate 只选择 shared expert。层数增加后，公共信息与私有信息逐层分离。

## 8. 多任务训练中真正要监控什么？

- 每任务的 AUC、LogLoss、校准和分人群指标，而非只看总 loss；
- 各任务在共享参数上的梯度 cosine，长期为负说明存在局部冲突；
- 每任务的 gate 分布、expert usage、熵、梯度范数与 loss；
- 标签覆盖率和各任务 loss 尺度，避免样本最多的任务主导更新。

当任务 A 涨、任务 B 跌时，先排查标签空间、损失量级、采样和特征穿越；结构升级到 PLE 或 PCGrad 不应是第一反应。

## 9. 死专家的处理为什么不能只强制均匀？

若辅助 loss 过强，所有 expert 被迫均匀分流，模型失去“不同 expert 专业化”的意义。正确目标不是每个 batch 完全平均，而是长期不存在持续零流量专家，并且不同 expert 学到可区分的功能。常见做法是温和的 load-balance/entropy 正则、训练早期 noisy gate 或较高温度、expert dropout 与持续监控。

## 10. MMoE 不等于多目标决策

MMoE 解决多个预测任务怎样共享表示；它输出 CTR、CVR、时长等预测后，最终怎样平衡 GMV、成本和体验属于多目标排序/约束优化问题。训练 loss 权重与线上 serving 权重位置不同，不能互相替代。
