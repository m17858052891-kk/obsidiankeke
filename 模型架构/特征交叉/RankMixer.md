仅仅使用最基础的全连接层（MLP），只要交叉的方式对，就能达到甚至超越Transformer对效果，且速度更快

把所有用户和物品的特征全部token化之后，会得到一个二维矩阵：

行代表了不同的特征（用户年龄token、目标商品token、上下文token）
列代表每个特征的embedding向量维度

如果要做self-attention，计算量是O(N^2),但rankmixer采用了两步纯MLP操作完成信息融合

Token1 用户
【0.1，0.8，0.2，0.5】

Token2 目标商品
【0.9，0.1，0.7，0.2】

Token3 当前时间
【0.3，0.9，0.8，0.1】

**第一步：Token Mixing**  列计算
把矩阵转置，让全连接层MLP跨越不同的Token【0.1，0.9，0.3】进行计算，产生了新得分，更新了矩阵中的数字。找用户商品时间之间的可能匹配

**第二步：Channel Mixing** 行计算
矩阵转置回来，让全连接层在每个token自己的embedding维度内部进行深层计算，让用户自己的各项属性在上一步的更新后进行吸收

**在一个rankmixer block里，token mixing 和channel mixing会被堆叠很多次**

# 1. `RankMixerNSTokenizer` (特征预处理)

- **它的作用**：推荐系统的原始特征非常杂乱（有离散的 ID，有连续的浮点数，有长有短）。`RankMixerNSTokenizer` 的任务就是像“车间入口”一样，把这些杂乱的非序列特征（NS feats）强行统一打包、投影，变成**长度统一、维度一致的标准 Token 矩阵**，为后面的混合（Mix）做好准备。

# 2. `RankMixerBlock` (高阶特征会师)

- **它的位置**：在你的架构图中，它位于 Cross-Attention 之后： `concat(all decoded query tokens, NS tokens) -> RankMixerBlock`
- **它的作用**：
    - **输入**：一半是包含了用户历史动态兴趣的 `decoded query tokens`，另一半是代表当前状态的 `NS tokens`。
    - **执行**：它们被拼接到一起，形成了一个巨大的二维矩阵。RankMixerBlock 开启“横向 + 纵向”的交织模式。
    - **结果**：用户的“历史动态偏好”和当前的“静态画像及候选商品”在这一步发生了极其剧烈的化学反应，彻底融为一体。
