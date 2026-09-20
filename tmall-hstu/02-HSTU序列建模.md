# HSTU：多行为用户兴趣建模

## 1. 做什么，为什么做

RQ-VAE 解决“商品如何编码”，HSTU 解决“用户下一步会对什么商品感兴趣”。输入不是单纯 Item 序列，而是按时间排序的多行为事件流：

```text
(SID_A, 点击, t1)
(SID_B, 收藏, t2)
(SID_C, 加购, t3)
(SID_D, 购买, t4)
```

统一事件流保留了从浏览到收藏、加购和购买的自然转化顺序；行为 embedding 区分动作含义，相对时间偏置区分近期兴趣和长期兴趣。

## 2. 输入表示

商品 $i_t$ 的四级 SID 为：

$$
s_t=[c_{t,1},c_{t,2},c_{t,3},c_{t,4}]
$$

第 (t) 个行为事件的输入表示为：

$$
x_t=
\sum_{l=1}^{4}E_l[c_{t,l}]
+E_b[b_t]
$$

其中：

- $E_l$：第 $l$ 级 SID embedding；
- $E_b$：点击、收藏、加购、购买的行为 embedding；
- 时间戳不直接相加，而是在事件两两交互时形成相对时间偏置。

长序列保留最近100条行为；短序列右侧 Padding，并用 valid mask 防止 Padding 参与计算。

## 3. HSTU Block

当前配置为4层 Encoder、8个 Attention Heads、Hidden Size 256。每层先做 LayerNorm：

$$
\bar X=LN(X)
$$

再计算四个投影：

$$
Q=\bar XW_Q,\quad
K=\bar XW_K,\quad
V=\bar XW_V,\quad
U=\operatorname{SiLU}(\bar XW_U)
$$

Q、K判断两个事件是否相关，V传递内容，U控制聚合结果进入当前位置的强度。

## 4. 相对时间偏置

两个事件的时间差：

$$
\Delta t_{ij}=|t_i-t_j|
$$

项目使用对数分桶：

$$
b_{ij}=\min\left(
\left\lfloor\log_2\left(1+\frac{\Delta t_{ij}}{60}\right)\right\rfloor,
B-1
\right)
$$

再查询每个 Head 独立的可学习偏置：

$$
R_{ij}^{(h)}=Embedding_h(b_{ij})
$$

对数分桶能细分短时间差，同时把很久以前的行为压缩到较粗的时间范围。

## 5. Pointwise SiLU 交互

普通 Transformer 使用 Softmax Attention；当前 HSTU-style 实现使用逐元素 SiLU：

$$
A^{(h)}=\operatorname{SiLU}\left(
\frac{Q^{(h)}K^{(h)\top}}{\sqrt{d_h}}+R^{(h)}
\right)
$$

之后施加因果 Mask 和有效位置 Mask：

$$
M_{ij}=1\quad\text{仅当}\quad j\le i
$$

当前位置只能看到过去，不能看到目标之后的未来行为。聚合结果为：

$$
H=\frac{(A\odot M)V}{\sqrt{L_{valid}}}
$$

与 Softmax 不同，SiLU 不要求一行权重和为1，多个历史行为可以同时保留较强信号；除以 $\sqrt{L_{valid}}$ 用于控制不同序列长度下的数值尺度。

## 6. 门控残差与门控 FFN

交互结果先标准化，再与门控 (U) 逐元素相乘：

$$
X'=X+W_O\left(LN(H)\odot U\right)
$$

随后进入门控 FFN：

$$
G=\operatorname{SiLU}(W_GLN(X'))
$$

$$
F=W_VLN(X')
$$

$$
X_{out}=X'+W_{ffn}(G\odot F)
$$

两次残差连接保留原始事件信息并改善梯度传播；门控结构让模型决定哪些兴趣更新值得写入用户状态。

## 7. 用户兴趣向量

经过4层 HSTU 后，取最后一个有效行为位置的隐藏状态：

$$
h_u=X^{(4)}_{L_{valid}}
$$

它概括了用户在当前时刻的商品兴趣、行为强度和时间演化，作为 SID Decoder 的条件向量。

## 8. 多行为预训练

预训练阶段，点击、收藏、加购、购买位置都可以作为下一商品目标。例如：

```text
输入：点击A、收藏B               → 目标：点击C的SID
输入：点击A、收藏B、点击C        → 目标：加购D的SID
输入：点击A、收藏B、点击C、加购D → 目标：购买E的SID
```

这里“多行为”有两层含义：

1. 历史中保留全部行为类型；
2. 预训练目标可以来自任意行为。

模型只预测目标商品 SID，不额外预测目标行为类型。正式预训练包含486,020条训练样本和49,383条验证样本。

## 9. SID 自回归 Decoder

目标商品 SID 为 $[c_1,c_2,c_3,c_4]$。Decoder 在用户兴趣 $h_u$ 条件下分四步生成：

$$
P(SID\mid h_u)=
P(c_1\mid h_u)
P(c_2\mid h_u,c_1)
P(c_3\mid h_u,c_1,c_2)
P(c_4\mid h_u,c_1,c_2,c_3)
$$

训练时使用 Teacher Forcing：预测第 (l) 级时输入真实前缀。四级交叉熵取平均：

$$
\mathcal L_{SID}=\frac{1}{4}\sum_{l=1}^{4}
CE(\hat c_l,c_l)
$$

这一步把一次百万级 Item 分类，转化成四次较小词表分类。

## 10. 时间切分与防泄漏

每个用户内部按时间划分：

```text
较早目标位置 → Train
倒数第二个目标 → Validation
最后一个目标 → Test
```

每个训练样本只使用目标之前的历史，因果 Mask 再从模型计算层面阻止未来信息进入当前位置。

## 11. 复杂度与边界

当前实现显式构造长度 $L\times L$ 的交互矩阵，时间复杂度和核心显存仍约为：

$$
O(BL^2D)
$$

所以它是保留 HSTU 关键机制的 HSTU-style 原型，不应声称具备生产版 HSTU 的全部 Jagged Tensor 和长序列优化。项目通过长度分桶、最长100截断、BF16、公共时间矩阵复用和多 Worker DataLoader 控制成本。

## 12. 一分钟回答

> 我先把用户历史商品替换成四级 SID，并叠加行为类型 embedding。HSTU 每层通过 Q、K、V 建模事件关系，用 U 做门控，再把相对时间差经过对数分桶加入交互分数；与普通 Softmax Attention 不同，当前实现使用 Pointwise SiLU，让多个历史事件可以同时保留强信号。因果 Mask 保证不看未来，门控残差和门控 FFN 更新用户状态。最后取最后一个有效位置作为用户兴趣向量，Decoder 通过 Teacher Forcing 和四级交叉熵生成下一商品 SID。多行为预训练利用了数量充足的点击、收藏和加购数据，为后续购买 LoRA-SFT 提供通用兴趣主干。
