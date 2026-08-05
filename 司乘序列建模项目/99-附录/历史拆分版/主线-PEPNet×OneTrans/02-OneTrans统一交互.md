# OneTrans：统一序列交互

## 1. 解决的硬边界

传统序列模型常采用：

```text
乘客序列 encoder → 向量
司机序列 encoder → 向量
静态特征 → MLP
三个向量 concat → task tower
```

它的问题是：静态订单特征只能在序列压缩之后参与交互；司机和乘客历史也容易各自独立编码。OneTrans 的做法是保留 token 粒度，在同一 backbone 中交互。

## 2. Tokenizer

| token 类型 | 来源 | 角色 |
|---|---|---|
| S-token | 乘客/司机历史事件 | 表示一条有顺序的历史行为 |
| NS-token | 当前订单、用户、司机、时间、区域、供需等静态字段 | 表示当前请求的非序列条件 |

每个 token 还需要类型/角色/时间信息。具体的 token 数量、排列顺序和静态字段分组须以工程配置为准。

## 3. 混合参数化与注意力

对 Transformer layer $l$：

$$
\operatorname{Attn}(Q,K,V)=\operatorname{softmax}\left(\frac{QK^T}{\sqrt d}+M\right)V
$$

OneTrans 的关键差异是：S-token 通常共享 Q/K/V 与 FFN 参数，以学习通用的行为处理函数；NS-token 为不同字段保留专属或分组参数，以免静态字段语义被过度同质化。最终注意力仍可让二者在同一上下文中交互。

## 4. 三类模型能力

1. **序列内部依赖：** 最近一次取消、接驾距离变化、时间间隔等事件模式；
2. **跨序列依赖：** 乘客近期行为与司机近期服务偏好的互补；
3. **序列—静态特征依赖：** 当前价格、接驾距离、区域供需影响哪些历史模式更相关。

## 5. Causal、Pyramid 与 KV Cache

- causal mask 控制 token 可见方向，避免未来行为泄漏；
- Pyramid 在层间压缩历史 token，以降低长序列计算；
- KV Cache 是潜在推理复用方式。

当前材料支持这些作为 OneTrans 的方法原理；是否在本项目启用、如何配置、是否获得延迟收益，均需以代码和压测记录为准。

## 6. 输出交给 PPNet

OneTrans 输出的是一份融合后的共享表示，而不是直接预测履约。接下来由任务级 PPNet 决定 OD/O/D 各自应保留哪些 hidden 通道，见 [[03-PPNet与D-O-OD任务输出]]。
