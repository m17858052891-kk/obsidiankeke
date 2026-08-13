# 05 SID 自回归解码

## SID 概率分解

如果目标商品 SID 为 ([s_0,s_1,s_2,s_3])，则：

$$
p(SID|h)=p(s_0|h)p(s_1|h,s_0)p(s_2|h,s_{<2})p(s_3|h,s_{<3})
$$

这把大规模 Item 分类拆成多个较小 code vocabulary 的条件分类。

## Teacher Forcing 和多级交叉熵

训练预测当前 code 时使用前面的真实 code。第 (l) 级输出 logits 后计算 (L_l=-\log p_l(s_l^*))，总损失为：

$$
L_{SID}=\sum_l\lambda_lL_l
$$

交叉熵加在 HSTU/decoder 的 SID 输出头，不是 RQ-VAE codebook 中。它让每一级学习条件概率，也为 Beam Search 提供可累加的 log probability。训练使用真实 prefix，推理使用模型生成 prefix，因此会有 exposure bias。

## Prefix Index / Trie

根据所有有效完整 SID 建立：

```python
prefix_next[prefix] = allowed_next_tokens
sid_to_items[full_sid] = item_list
```

每一步只允许扩展当前前缀的合法下一跳；Collision Token 也必须进入索引，否则只能保证基础 SID 合法，不能保证唯一映射。

## Prefix-Constrained Beam Search

```python
beams = [((), 0.0)]
for level in range(num_tokens):
    candidates = []
    for prefix, score in beams:
        for token in prefix_next.get(prefix, set()):
            candidates.append((prefix + (token,), score + log_prob(token)))
    beams = top_k(candidates, beam_size)
```

完成后通过 `sid_to_items` 映射商品，并做去重、seen filter、库存/上下架过滤和必要的候选回退。

## 合法性边界

如果有效 SID 表完整、前缀索引正确且解码严格遵守索引，则“SID 能映射到已登记商品”的结构合法率理论上可以达到 100%。这不代表推荐质量、库存、地域、用户未看或新商品覆盖也达到 100%。
