# 输入、Embedding 与 EPNet

## 1. 模型接收什么

当前请求在 `prediction_time` 被组装为：

```text
passenger_seq: [L_p, F_p]
driver_seq:    [L_d, F_d]
x_static:      当前订单 / 用户 / 司机 / 场景特征
mask, role_id, relative_time
```

其中两条历史序列只含预测时点前且当时可获得的事件；`mask` 区分真实历史和 padding，`role_id` 区分乘客/司机事件。

## 2. 从字段到基础表示

- 稀疏 ID/类别：Embedding lookup；
- 连续字段：归一化后投影；
- 一个历史事件：将订单距离、接驾距离、价格、结果、时间差、空间/场景等字段 Embedding 融合为事件向量；
- 当前订单/上下文：组织为非序列字段表示。

事件向量仍保留在序列维度上，不能在进入 OneTrans 前过早池化成单个“历史均值”。

## 3. EPNet 在哪里

EPNet 作用于底层表示。设主干输入为 $x_{dnn}$，场景先验为 $x_{ep}$，门控为：

$$
g_{ep}=2\cdot\sigma(\operatorname{MLP}([\operatorname{sg}(x_{dnn}),x_{ep}]))
$$

$$
\tilde x_{dnn}=x_{dnn}\odot g_{ep}
$$

直觉是：同一历史行为或当前订单字段，在连环派/非连环派、不同时间/区域/供需场景中，应该使用不同强度的表示通道。

## 4. 为什么需要 stop-gradient

生成 gate 时对主干输入使用 stop-gradient，可以避免 gate 支路通过缩放系数反向强行改写共享 Embedding 底座。主干仍沿正常路径学习，gate 学习“当前样本哪些维度更应被放大或抑制”。

## 5. 与背景版本的边界

343 维特征、`[B,10,10]` 序列形状、`poso` 与六 tower 路由是某一 PosSA baseline 的已知实现信息，见 [[背景与实验-入口]]；不能自动等同为当前 OneTrans run 的精确配置。
