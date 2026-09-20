# 协同 Semantic ID × HSTU 电商生成式推荐

## 一句话总览

项目把“在百万商品中直接分类”改写为“生成商品的多级 Semantic ID”：先学习商品协同表示并离散编码，再用 HSTU 建模用户多行为序列，最后通过购买目标 LoRA-SFT 和合法前缀 Beam Search 生成 Top-K 商品。

```text
淘宝行为日志
  → 加权共现 + Weighted Item2Vec
  → RQ-VAE 三级残差量化 + Collision Token
  → 用户 Item 序列转换为 SID/行为/时间序列
  → HSTU 多行为预训练
  → 购买目标 LoRA-SFT
  → Prefix-Constrained Beam Search + KV Cache
  → SID 映射回 Item，过滤历史商品，输出 Top-K
```

## 三分钟项目逐字稿

> 这个项目解决的是百万级商品推荐中直接预测 Item ID 的两个问题：第一，输出层要覆盖全部商品，类别空间很大；第二，Item ID 只是编号，不能表达商品之间的相似关系。因此我把推荐任务改写成多级 Semantic ID 生成。
>
> 数据使用天池淘宝用户行为日志。我先按用户和时间整理点击、收藏、加购、购买序列，再用行为强度、时间衰减和用户活跃度惩罚构造加权 item-item 共现样本。之后通过 Weighted Item2Vec 学习64维商品协同向量，让经常被同一批用户在相近时间交互的商品靠得更近。
>
> 接着，我用 RQ-VAE 把连续商品向量离散化。Encoder 将64维向量压缩到32维 latent，三个 codebook 依次量化当前残差：第一级表达主要信息，后两级补充前面没有表示好的细节。训练目标由重建损失、codebook loss 和 commitment loss 组成；由于最近邻 argmin 不可导，我使用 STE，让重建梯度能够更新 Encoder。三级 code 冲突时追加 Collision Token，保证最终 SID 能唯一映射回商品。
>
> 用户建模阶段，我把历史 Item ID 替换成 SID，同时保留行为类型和时间戳。每个时间步融合四级 SID embedding 与行为 embedding，HSTU 再通过 Q、K、V、门控 U、Pointwise SiLU、因果 Mask 和相对时间偏置建模兴趣变化。模型不再预测百万级 Item 类别，而是使用 Teacher Forcing 依次预测四级 SID，并对每一级计算交叉熵。
>
> 训练分两步。第一步使用点击、收藏、加购、购买全部目标做全参数预训练，学习通用兴趣迁移；第二步只选择购买位置作为目标，冻结预训练主干，用 Rank-16 LoRA 和 SID 输出头做监督微调。这样既保留多行为知识，也降低购买样本较少时的过拟合风险。LoRA阶段只训练12.13%的参数。
>
> 推理时使用合法 SID Prefix Trie 约束 Beam Search，避免生成不存在的 SID；同层 Beam 批量计算，并通过 KV Cache 复用父前缀。完整 SID 映射回 Item 后，再过滤历史商品并补齐 Top-K。最终在一万条购买测试样本上，HR@10 为0.0048、NDCG@10 为0.00281，分别约为全局加权热门基线的2.82倍和3.30倍。这个结果说明方案优于简单非个性化推荐，但绝对命中率仍低，项目定位是可验证的生成式推荐原型，而不是生产级效果结论。

## 关键实验事实

| 项目 | 结果 |
|---|---:|
| 原始日志 | 100,150,807 条 |
| 实验数据 | 49,383 用户、4,532,874 交互、1,050,816 商品 |
| SID 配置 | 3 个 256 大小 codebook + Collision Token |
| HSTU | 4 层、8 Heads、Hidden 256、最长序列 100 |
| 多行为预训练 | 486,020 训练样本，最佳验证损失 3.8978 |
| 购买 LoRA-SFT | 37,368 训练样本，Rank 16，最佳验证损失 3.6515 |
| 测试结果 | HR@10 0.0048，NDCG@10 0.00281，类目多样性 0.7695 |
| 推理延迟 | Encoder P95 8.67 ms，Decoder P95 99.81 ms |

## 阅读顺序

1. [RQ-VAE 原理与损失函数](01-RQ-VAE原理与损失函数.md)
2. [HSTU 序列建模](02-HSTU序列建模.md)
3. [LoRA-SFT 购买微调](03-LoRA-SFT购买微调.md)

## 必须保持准确的口径

- 淘宝数据没有真实曝光日志，项目中的“曝光”是加权交互代理。
- 当前模型是 HSTU-style 实现，不是 Meta 生产版本逐行复刻。
- 热门基线是全局加权热门榜，不是 SASRec、LightGCN 等强基线。
- 当前尚未完成预训练模型、LoRA 和全参数购买微调在同一测试集上的完整消融。
