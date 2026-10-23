---
title: 论文精读索引
tags: [论文精读, 推荐系统]
created: 2026-08-27
---

# 论文精读

## 推荐系统统一建模

- [[OneTrans/OneTrans：统一特征交互与序列建模|OneTrans：统一特征交互与序列建模]] — S/NS token 统一因果 Transformer、混合参数、金字塔堆叠、跨请求 KV Cache。
- [[HyFormer/HyFormer：CTR中的序列建模与特征交互|HyFormer：CTR 中的序列建模与特征交互]] — Query Decoding 与 Query Boosting 逐层交替，多序列独立解码。
- [[HSTU/HSTU：生成式推荐与层次序列转导单元|HSTU：生成式推荐与层次序列转导单元]] — GR 任务重构、HSTU、Stochastic Length、M-FALCON，含技术附录。

## 因果建模与优惠券分配

- [[TaQFormer/TaQFormer：多维优惠券建模与OBS-RCT融合|TaQFormer：多维优惠券建模与 OBS–RCT 融合]] — 品类折扣 query、目标品类响应、冻结 OBS 参考与 LoRA 随机适配、全动作并行服务；含全部公式与原始图表。版本：arXiv:2610.26199v1。

## 快速对照

| 论文 | 统一对象 | 核心信息流 | 主要效率手段 | 主要任务 |
|---|---|---|---|---|
| OneTrans | S-token + NS-token | NS 在 causal stack 中读取完整 S 历史 | Pyramid、跨请求 KV Cache、FlashAttention | 工业 CTR/CVR 排序 |
| HyFormer | Global query + 序列 K/V + NS-token | Decoding 后 Boosting，逐层迭代 | 短 query cross-attention、Mixer、GPU pooling、异步 AllReduce | 工业 engagement/CTR |
| HSTU | 内容、动作及类别特征时间序列 | causal sequential transduction | generative training、SL、ragged kernel、M-FALCON | retrieval + ranking |

> [!info] 版本
> OneTrans 使用 arXiv:2510.26104v3；HyFormer 使用 arXiv:2601.12681v2；HSTU 使用 arXiv:2402.17152v3。

