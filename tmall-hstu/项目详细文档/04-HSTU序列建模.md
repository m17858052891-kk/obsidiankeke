# 04 HSTU 序列建模：项目实现

## 多行为序列如何融合

当前项目采用一条按时间排序的统一事件序列，不是 click、collect、cart、purchase 四个独立 HSTU 分支。一个事件表示为：

```text
event_t = (SID(item_t), action_t, time_t)
```

例如 `A-click → B-collect → C-cart → D-purchase`。统一序列保留了“浏览—收藏—加购—购买”的行为转化过程。四种行为不是被简单计数，而是通过行为类型 embedding 区分；同一个商品被 click 和 purchase 时，SID 可以相同，但 action embedding 不同。

四路独立序列也可以作为后续方案：分别编码四类行为，再用 Cross-Attention、门控或 pooling 融合。但这不是当前实现，不能在面试中说成四个序列编码器并行融合。

## 输入融合

对第 (t) 个行为的第 (l) 个 SID code：

$$
x_{t,l}=E_{SID}(c_{t,l})+E_{action}(a_t)+E_{time}(\Delta t_t)+E_{level}(l)
$$

行为 embedding 区分四种行为；时间间隔先离散成 bucket，再查时间 embedding；level embedding 区分 SID 的不同量化层。多个行为按时间顺序拼接后输入编码器。

## 相对位置、时间和 mask

相对 bias 可写为：

$$
B_{ij}=B_{pos}(i-j)+B_{time}(\Delta t_{ij})
$$

它让模型区分近期和长期行为。`causal mask` 防止当前位置读取未来，`padding mask` 忽略补齐位置；二者作用不同。

## 当前 HSTU-style Block

当前实现参考 HSTU 的 Q/K/V/U、pointwise activation 和 gated residual：

$$
[Q,K,V,U]=XW_{qkvu}
$$

$$
A=\operatorname{SiLU}(QK^T+B),\quad H=AV
$$

$$
Y=X+\operatorname{Dropout}((H\odot U)W_o)
$$

Q/K 建模行为间相关性，V 传递历史信息，U 控制聚合结果的通道。最终隐藏状态接 SID 的多级预测头。更严格的 Attention 原理和复杂度见 `08-HSTU原理与复杂度.md`。

## 当前边界

这里应称为 HSTU-style 简化实现，不声称和官方工业实现逐算子一致。若展开 SID 后序列变长，dense token-to-token 交互仍可能是 (O(L^2))，不能仅因为使用 SiLU 就称为 Linear Attention。
