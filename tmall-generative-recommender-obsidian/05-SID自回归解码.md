# 05 SID 自回归解码

## 1. 从 item 分类到 code 生成

直接 item 分类可以写成：

$$
p(i|h)
$$

SID 生成则分解为：

$$
p(s_0,s_1,s_2,s_3|h)
=p(s_0|h)p(s_1|h,s_0)p(s_2|h,s_0,s_1)p(s_3|h,s_0,s_1,s_2)
$$

其中 `h` 是 HSTU 编码后的用户历史表示。每个 code level 只有 256 个 code，显著小于数百万 item 的单层输出。

## 2. Teacher forcing

训练时目标 SID 为 `[s0,s1,s2,s3]`。解码器在预测 `s_l` 时输入前面真实的目标 code：

```text
预测 s0：输入 history
预测 s1：输入 history + gold s0
预测 s2：输入 history + gold s0 + gold s1
预测 s3：输入 history + gold s0 + gold s1 + gold s2
```

每一级使用 cross entropy，并忽略 padding code。当前实现对各 level 的 loss 做平均，另加轻微 label smoothing。

## 3. 曝光偏差

teacher forcing 的问题是训练时看到真实 prefix，推理时只能看到自己生成的 prefix，错误可能逐步累积。这叫 exposure bias。

改进方向：

- scheduled sampling。
- 用模型生成的 prefix 做 off-policy 训练。
- sequence-level loss 或 contrastive loss。
- prefix dropout，让模型适应不完整/错误前缀。
- 训练时加入非法 prefix 和 hard negative。

但 scheduled sampling 也可能造成训练目标不稳定，通常先用稳定的 teacher forcing，再针对线上误差做增强。

## 4. Prefix-Constrained Beam Search

建立前缀树：

```text
root
 ├─ c0=12
 │   ├─ c1=7
 │   │   └─ c2=33
 └─ c0=25
     └─ c1=4
```

在第 `l` 步，只从当前 prefix 的合法下一跳中选 token。这样可以保证：

- 生成的完整 SID 在训练表中存在。
- 不会生成无法映射到商品的 code 组合。
- beam 的每个候选都有可解释的 SID 路径。

基本过程：

```text
beams = [(empty_prefix, score=0)]
for level in code_levels:
    expand each beam with sid_prefix_next[prefix]
    add log probability
    keep top beam_size
map complete SID to item
remove seen items
return top-K items
```

## 5. 为什么不能只做 greedy decoding

greedy 每一级只保留概率最高的 code，早期错误可能导致后续没有可行路径，或者整体概率并非最优。beam search 保留多个 prefix，通常能提高召回覆盖和生成稳定性。代价是推理时间增加，需要控制 beam size、每步 branch top-k 和 prefix tree 查询。

## 6. SID 到商品的映射

推理完成后：

1. 将 code 序列拼成 tuple。
2. 在 `sid_to_items` 中查找对应 item 列表。
3. 如果存在 collision token，按完整 SID 区分冲突商品。
4. 对用户历史已出现 item 做 seen filter。
5. 可再接一个轻量 re-ranker 处理业务约束、库存、去重和多样性。

生成模型输出的是结构化地址，不一定等同于最终线上排序分数。

## 7. 约束搜索的风险

- SID 表覆盖不足会导致可行路径太少。
- collision token 太多会使词表和 beam 分支膨胀。
- 只保留训练中出现的 SID，无法直接生成新 item。
- 若过滤 seen item 后候选不足，需要回退到 ItemCF、热门或内容召回。

## 8. 关键面试问题

**问：为什么需要 prefix constraint？**

答：多级 code 的笛卡尔积中绝大多数组合并不对应真实商品。无约束生成会产生无效 SID，最后无法映射回 item。前缀约束将解码空间限制在训练中存在的 SID 集合内，牺牲一部分自由度换取有效率和稳定性。

**问：生成推荐和排序推荐的关系是什么？**

答：生成阶段负责从巨大 item 空间中产生结构化候选，排序阶段仍可以用生成概率、ItemCF 分数、业务特征和多样性约束做重排。生成不意味着不需要排序。

