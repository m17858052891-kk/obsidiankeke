# 模型架构：PEPNet × OneTrans

> 目标：解释已经构造好的“乘客历史序列 + 司机历史序列 + 用户/订单/上下文特征”如何进入 OneTrans，再如何通过 PEPNet 做个性化调节。

> 任务口径：**D = 乘客履约，O = 司机履约，OD = 司乘履约率**。

> 输入边界：事件、Attempt、宽表和预测锚点如何产出这些输入，见 [[01-特征底座与样本构建]]。本文不把“可能字段/推荐做法”误写成已确认的工程实现；精确 token 顺序、层数、loss 权重和 EPNet/Tokenizer 调用顺序须以代码为准。

> 模型边界：[[02a-已确认实现：PEPNet + Positional Self-Attention 序列基线]] 记录了已确认的传统双边序列 baseline；本文解释的是在其之后探索的 PEPNet × OneTrans 统一交互方案。两者不要混成同一套实现。

---

## 0. 一句话总结

这是一个面向司乘联合行为预测的、带个性化门控的统一序列建模架构：

~~~text
乘客历史订单序列
司机历史订单序列
用户/司机/订单/上下文特征
              ↓
Embedding / Unified Tokenizer
              ↓
OneTrans Unified Transformer
  ├── 乘客序列内部建模
  ├── 司机序列内部建模
  ├── 司机-乘客跨序列交互
  ├── 序列-静态特征交互
  └── 高阶非序列特征交互
              ↓
PEPNet Personalization
  ├── EPNet：底层 embedding 个性化
  └── PPNet：DNN hidden / 任务表示个性化
              ↓
共享表示 / 任务表示
              ↓
       ┌──────┼──────┐
       ↓      ↓      ↓
      D塔    O塔    OD塔
    乘客任务 司机任务 司乘任务
~~~

一句话回答：

> **OneTrans 负责把序列建模和特征交互统一起来，PEPNet 负责根据场景、用户、司机、订单等先验信息动态调节 Embedding 和任务网络，最后通过 D/O/OD 多任务头进行预测。**

---

## 1. 先澄清模块的物理位置

用户给出的逻辑结构是：

~~~text
原始输入
├── 乘客历史序列
├── 司机历史序列
├── 用户/订单/上下文特征
        ↓
Embedding / Tokenizer
        ↓
OneTrans
        ↓
PEPNet
        ↓
D / O / OD 任务头
~~~

这个结构作为系统级概览是正确的，但面试时需要补充一个细节：

> PEPNet 不是一个简单整体地放在 OneTrans 后面。PEPNet 内部有 EPNet 和 PPNet 两个插入点：EPNet 作用在底层 Embedding 侧，PPNet 作用在上层 DNN/任务表示侧。

因此更接近物理实现的结构是：

~~~text
Raw Features
    ↓
Base Embedding
    ↓
EPNet gate：Embedding personalization
    ↓
Tokenizer / Token assembly
    ↓
OneTrans backbone
    ↓
PPNet gate：Hidden/task personalization
    ↓
D/O/OD task heads
~~~

如果工程实现把 OneTrans 自带的 token projection 和 EPNet 合并，EPNet 与 tokenizer 的具体前后顺序需要以代码为准；但模块职责不变：

- EPNet：底层表示个性化；
- OneTrans：序列和非序列特征联合建模；
- PPNet：上层 hidden 和任务表示个性化；
- D/O/OD：最终多任务预测。

---

## 2. 项目背景和业务问题

### 2.1 为什么要建模司机和乘客序列

传统精排模型常使用当前订单的静态特征：

- 乘客 ID；
- 司机 ID；
- 当前订单起终点；
- 当前接驾距离；
- 当前时间和场景；
- 用户画像；
- 司机画像；
- 区域供需统计。

这些特征能够描述“当前是什么订单”，但不一定能够完整描述：

- 乘客最近是否频繁取消；
- 乘客是否对价格或距离敏感；
- 乘客近期是否有连续履约行为；
- 司机最近是否经常接单或取消；
- 司机对长距离接驾是否敏感；
- 某个司机和某类乘客/订单的历史交互结果；
- 当前订单和司机/乘客历史状态是否相似。

统计特征可以把历史压缩成次数、均值、比例，但会损失：

- 事件发生顺序；
- 行为之间的时间间隔；
- 最近行为和较早行为的差异；
- 价格、距离和时空条件的变化轨迹；
- 取消、接单、履约等事件的先后关系。

因此项目希望把历史订单组织成司机序列和乘客序列，让模型直接读取有顺序的行为历史。

### 2.2 三个任务

本文统一采用：

~~~text
D   = 乘客任务
O   = 司机任务
OD  = 司乘联合任务
~~~

本文不擅自展开 D/O/OD 的具体标签定义。它们可能对应取消、完单、履约或其他行为标签，最终以训练数据定义为准。

### 2.3 业务目标

当前记录的业务目标：

| 业务指标 | 目标 |
|---|---:|
| CR | +0.2pp |
| 乘客取消率 | -0.5pp |
| 2.5km+ 接驾距离占比 | -5% |

需要区分：

~~~text
离线指标：AUC、logloss、校准、分桶效果
线上指标：CR、乘客取消率、长距离接驾比例、订单/履约等业务指标
~~~

AUC 提升不能直接等价为业务指标已经达成。

---

## 3. 传统架构和 OneTrans 动机

### 3.1 传统 encode-then-interaction

传统推荐排序模型通常是：

~~~text
用户历史序列
        ↓
DIN / DIEN / Transformer / Self-Attention
        ↓
压缩成一个用户兴趣向量
        ↓
与用户/司机/订单/上下文特征拼接
        ↓
DCN / MMoE / PLE / SENet / RankMixer
        ↓
任务预测
~~~

在司乘场景中：

~~~text
乘客序列 → 乘客序列向量 ┐
司机序列 → 司机序列向量 ├→ 拼接静态特征 → 多任务网络
用户/订单/上下文 ───────┘
~~~

### 3.2 传统结构的四个问题

#### 问题一：序列被过早压缩

当前订单距离只能和整体乘客兴趣向量交互，无法精细判断：

~~~text
当前订单距离 ↔ 历史哪一笔长距离订单
当前场景     ↔ 历史哪一笔相同场景行为
当前价格     ↔ 历史哪些价格敏感行为
~~~

#### 问题二：静态特征难以参与序列表示学习

候选订单和上下文通常在序列被压缩后才进入模型，无法充分影响序列内部的表示。

#### 问题三：司机序列和乘客序列容易割裂

如果两类序列分别经过两个 Encoder，最后只拼接两个向量，模型缺少充分的跨序列 token 级交互。

#### 问题四：系统模块碎片化

序列 Encoder、特征交互模块和多任务网络分别实现，难以统一使用 FlashAttention、BF16/FP16、Activation recomputation 和 KV Cache。

### 3.3 OneTrans 的核心动机

OneTrans 的核心是：

> 把序列特征和非序列特征都表示成 token，然后用一个 Transformer 同时完成序列建模和特征交互。

它希望：

1. 消除序列表示和静态特征之间的表征隔阂；
2. 让司机、乘客、订单和上下文发生统一交互；
3. 复用大模型中的 Transformer 工程优化；
4. 在统一 backbone 上进行深度和宽度 scaling。

---

## 4. 输入层：原始特征如何组织

### 4.1 乘客历史序列

乘客序列的一个元素可以表示乘客过去的一次订单或行为事件。可能字段包括：

~~~text
passenger_id
order_id / attempt_id
订单状态
起终点区域
订单距离
接驾距离
价格/产品信息
时间戳
场景/入口
司机侧结果摘要
是否取消/是否完单等历史标签
~~~

具体字段以实际 SQL 和特征表为准。

历史事件必须满足：

~~~text
event_time < 当前样本预测时间
且 event_available_time <= 当前样本可用时间
~~~

不能只按照日期过滤，因为同一天内可能存在未来信息穿越。

### 4.2 司机历史序列

司机序列的一个元素可以表示司机过去的一次订单或服务事件。可能字段包括：

~~~text
driver_id
order_id / attempt_id
接单状态
应答状态
取消状态
完单状态
接驾距离
服务距离
起终点区域
时间戳
当前时段/工作日
供需或路况摘要
~~~

司机序列主要表达：

- 司机近期工作状态；
- 司机对距离和区域的偏好；
- 司机近期订单密度；
- 司机接单、取消和履约模式；
- 司机历史行为与当前订单的相似度。

### 4.3 用户、司机、订单和上下文特征

| 特征组 | 例子 |
|---|---|
| 乘客特征 | 乘客 ID、画像、活跃度、历史统计 |
| 司机特征 | 司机 ID、等级、近期活跃度、历史统计 |
| 订单特征 | 起点、终点、距离、价格、产品类型 |
| 上下文特征 | 时间、星期、入口、场景、区域 |
| 供需特征 | 区域供需、订单密度、运力状态 |
| 统计特征 | 取消率、履约率、均值、分位数 |

这些非序列特征最终也会被转成 NS-token，而不是只能拼成一个非常长的向量。

---

## 5. 序列样本建设和防穿越

### 5.1 样本锚点

每条训练样本应该有明确的预测锚点：

~~~text
sample_id
entity_id
current_order / attempt
prediction_time
label_time
~~~

历史序列围绕 prediction_time 截取。

### 5.2 时间条件

基本条件：

~~~text
event_time < prediction_time
~~~

更严格的条件：

~~~text
event_time < prediction_time
AND available_time <= prediction_time
~~~

available_time 用来防止迟到、回刷和离线补数造成线上不可见的信息泄漏。

### 5.3 序列排序

序列必须有稳定排序键：

~~~text
ORDER BY event_time ASC, stable_event_id ASC
~~~

不能只依赖普通聚合函数，因为普通聚合不保证数组内顺序。

### 5.4 序列截断

常见策略：

~~~text
最近 N 单
最近 N 天
最近 N 单且不超过 N 天
~~~

已有实验比较了长度 10、20、30、40，以及 passenger 序列时间跨度约束。当前一组 6 月数据中，长度 20 效果最好；但过滤数据量后，收益不能简单归因于过滤策略。

### 5.5 大规模历史回查

朴素方式：

~~~text
每个样本 join 过去时间窗口内全部历史
        ↓
排序
        ↓
取最近 N 条
~~~

问题：

- 中间结果膨胀；
- 高频司机/乘客数据倾斜；
- 大量无效历史扫描；
- 训练样本和历史数据发生巨量扩展。

更合理的工程方式：

~~~text
历史窄表按 entity_id + event_time 预排号
        ↓
样本先定位历史序号区间
        ↓
只回表取小范围完整字段
        ↓
组装序列 tensor
~~~

---

## 6. Embedding 层

### 6.1 稀疏 ID 特征

对乘客 ID、司机 ID、区域 ID、产品 ID 等稀疏特征使用 embedding table：

$$
e_i = E_i[id_i]
$$

多个字段可以拼接后投影：

$$
h = \operatorname{MLP}(e_{id_1} \oplus e_{id_2} \oplus \cdots \oplus e_{id_k})
$$

### 6.2 稠密特征

对距离、价格、次数和时长等 dense 特征，一般进行：

~~~text
缺失值处理
归一化/分桶/clip
Dense projection
~~~

可表示为：

$$
h_{dense} =
\operatorname{MLP}(\operatorname{Normalize}(x_{dense}))
$$

### 6.3 历史事件 Embedding

每个历史事件可以按字段分别 embedding，再融合：

$$
x_t =
\operatorname{Fuse}
\left(
e_{id,t},
e_{status,t},
e_{geo,t},
e_{time,t},
e_{distance,t},
e_{context,t}
\right)
$$

Fuse 可以是 concat + MLP、sum、attention pooling 或项目自定义融合层。OneTrans 的关键是让融合后的事件表示成为 sequence token，而不是先压成一个全局序列向量。

---

## 7. EPNet：底层 Embedding 个性化

### 7.1 EPNet 解决什么问题

多场景共享 embedding 的优点是参数少、数据共享；缺点是忽略场景差异，容易出现 domain seesaw。

EPNet 的折中方式：

~~~text
共享 Embedding
        ×
场景条件 gate
        ↓
场景自适应 Embedding
~~~

### 7.2 Gate NU

第一层做特征交叉：

$$
x' = \operatorname{ReLU}(xW+b)
$$

第二层生成 gate：

$$
\delta =
\gamma \cdot
\operatorname{Sigmoid}(x'W' + b')
$$

常用设置：

$$
\gamma = 2
$$

gate 的直觉：

~~~text
δ 接近 0：抑制
δ 接近 1：保持
δ 大于 1：增强
~~~

### 7.3 EPNet 输入

场景先验可以包括：

- domain ID；
- 场景 ID；
- 乘客在当前场景的行为统计；
- 司机在当前场景的行为统计；
- 当前产品和入口；
- 用户/司机/订单在域内的曝光、点击、取消和履约统计。

记场景先验为 \(F_d\)，共享 embedding 为 \(E\)：

$$
\delta_{domain}
=
\Omega_{ep}
\left(
E(F_d) \oplus \operatorname{StopGrad}(E)
\right)
$$

$$
O_{ep} =
\delta_{domain} \otimes E
$$

### 7.4 为什么使用逐元素乘法

逐元素乘法可以做到：

- 维度级 feature selection；
- 维度级 feature amplification；
- 不改变 embedding 的形状；
- 额外参数和计算量小；
- 容易插入已有推荐模型。

### 7.5 为什么使用 Stop-Gradient

如果 EPNet 生成 gate 时直接通过输入 embedding 反向更新共享 embedding，大数据量场景可能通过 gate 梯度强行改变共享底座。

Stop-Gradient 的职责分离：

~~~text
共享 Embedding：学习跨场景共性
EPNet：学习如何根据场景调节共性表示
~~~

面试回答：

> Stop-Gradient 的目的是隔离共享 Embedding 的学习和场景 gate 的学习，避免个性化 gate 的优化过程反向破坏通用 embedding，从而缓解场景之间的梯度竞争和 domain seesaw。

---

## 8. OneTrans Tokenizer

### 8.1 S-token 和 NS-token

~~~text
S-token：Sequence token
  司机历史事件、乘客历史事件

NS-token：Non-sequence token
  用户画像、司机画像、当前订单、上下文、统计特征
~~~

在本项目中可以进一步增加类型：

~~~text
driver S-token
passenger S-token
user NS-token
driver-profile NS-token
order NS-token
context NS-token
statistics NS-token
~~~

### 8.2 一种统一排列

~~~text
[driver_S_1, ..., driver_S_Ld,
 passenger_S_1, ..., passenger_S_Lp,
 SEP_driver_passenger,
 user_NS, driver_NS, order_NS, context_NS, stat_NS]
~~~

也可以按照时间交错：

~~~text
[passenger_event_t1,
 driver_event_t2,
 passenger_event_t3,
 driver_event_t4,
 ...,
 NS tokens]
~~~

到底采用分段拼接还是时间交错，需要由业务时间语义和实际实现确定。核心要求：

- 模型知道 token 来自司机还是乘客；
- 模型知道事件时间或相对时间；
- 模型知道不同序列的边界；
- mask 不允许未来行为进入当前预测。

### 8.3 Role embedding 和时间信息

token 可以由多个组成部分相加：

$$
x_i =
e_{content,i}
+
e_{role,i}
+
e_{time,i}
+
e_{position,i}
$$

role 可以区分：

~~~text
DRIVER
PASSENGER
ORDER
CONTEXT
~~~

时间信息可以使用：

- 绝对位置；
- 相对位置；
- 事件时间戳；
- 距当前样本的时间差；
- 小时、星期、节假日 bucket；
- 时间差 bucket embedding。

这些是可选实现，不等于当前项目已经确认使用的全部字段。

### 8.4 Group-wise Tokenizer

按语义人工分组：

~~~text
用户特征组     → user token
司机特征组     → driver token
订单特征组     → order token
上下文特征组   → context token
统计特征组     → statistic token
~~~

优点：

- 语义清晰；
- 可解释；
- 容易做字段级消融；
- 方便设置 token-specific 参数。

缺点：

- 依赖人工分组；
- 特征分组成本高；
- 多个小 MLP 可能增加工程复杂度。

### 8.5 Auto-Split Tokenizer

先拼接所有非序列特征，经过 MLP 后切分成多个 NS-token：

$$
NS\text{-}Tokens =
\operatorname{Split}
\left(
\operatorname{MLP}(\operatorname{Concat}(NS))
\right)
$$

流程：

~~~text
所有 NS features
        ↓ concat/flatten
        ↓ MLP
        ↓ split
多个 NS-token
~~~

优点：

- 结构统一；
- token 数量可控；
- 非序列特征可以提前密集交叉；
- 减少人工分组。

缺点：

- 可解释性较弱；
- token 与原始字段不再一一对应；
- 需要关注 MLP 维度和切分策略。

---

## 9. OneTrans Block

### 9.1 标准 Transformer Block

标准 pre-norm Transformer：

$$
X' =
X +
\operatorname{MHA}(\operatorname{Norm}(X))
$$

$$
X_{out} =
X' +
\operatorname{FFN}(\operatorname{Norm}(X'))
$$

OneTrans 在此基础上增加：

- S/NS 混合参数化；
- 推荐场景 causal mask；
- S-token pyramid 压缩；
- 适配 KV Cache 的 token 排列。

### 9.2 RMSNorm Pre-Norm

RMSNorm：

$$
\operatorname{RMS}(x)
=
\sqrt{
\frac{1}{d}
\sum_{i=1}^{d}x_i^2
+
\epsilon
}
$$

$$
\operatorname{RMSNorm}(x)
=
\frac{x}{\operatorname{RMS}(x)}
\odot g
$$

它不显式减均值，只按均方根缩放，计算比 LayerNorm 更轻。

OneTrans 中的直觉：

~~~text
不同来源 token 尺度不同
        ↓
attention/FFN 前做 RMSNorm
        ↓
稳定 hidden scale
        ↓
深层 Transformer 更容易训练
~~~

### 9.3 Mixed Causal Attention

标准 attention：

$$
\operatorname{Attention}(Q,K,V)
=
\operatorname{Softmax}
\left(
\frac{QK^T}{\sqrt{d_k}} + M
\right)V
$$

其中 \(M\) 是 attention mask。

OneTrans 的参数策略：

~~~text
S-token：共享 Q/K/V
NS-token：token-specific Q/K/V
~~~

统一写为：

$$
Q_i = X_i W^Q_{type(i)}
$$

$$
K_i = X_i W^K_{type(i)}
$$

$$
V_i = X_i W^V_{type(i)}
$$

其中 type(i) 决定使用共享序列参数还是字段专属参数。

### 9.4 为什么 S-token 共享参数

S-token 都表示历史行为中的一个事件，语义相对同质。共享参数可以：

- 避免参数量随序列长度增长；
- 学习处理一个历史事件的通用函数；
- 适应不同历史长度；
- 提升 GPU 计算规整性。

### 9.5 为什么 NS-token 使用专属参数

NS-token 语义差异很大：

~~~text
user token：长期画像和偏好
order token：当前候选订单
context token：当前场景和环境
statistics token：统计和校准信号
~~~

如果全部共享参数，一个函数需要同时解释完全不同的字段。token-specific 参数保留不同字段的专属变换能力。

### 9.6 FFN 的混合参数化

Attention 负责 token 之间的信息交换，FFN 负责 token 内部加工：

~~~text
S-token：shared FFN
NS-token：token-specific FFN
~~~

可以写成：

$$
FFN_i(X_i)
=
\phi
\left(
X_i W^{up}_{type(i)}
+
b^{up}_{type(i)}
\right)
W^{down}_{type(i)}
+
b^{down}_{type(i)}
$$

### 9.7 Causal Mask

如果 token 顺序是：

~~~text
[driver history, passenger history, user, order, context]
~~~

causal 约束大致是：

~~~text
driver_s1：只能看自己
driver_s2：看前面的 driver history
passenger_sj：看允许的前序 history
order token：看前面的司机/乘客历史和前置 NS token
context token：看前置 token
~~~

不要在面试中笼统说“所有 token 双向交互”。OneTrans 使用 causal attention，实际信息方向由 token 顺序和 mask 决定。

### 9.8 跨序列交互

如果 driver/passenger token 在同一个 attention 图中，并且 mask 允许对应方向，就可以发生：

~~~text
driver token → passenger token
passenger token → driver token
driver/passenger token → order token
历史 token → context token
~~~

如果两类序列完全进入不同 Encoder，则只能在后面拼接表示，不能产生真正的 token 级跨序列 attention。

这与当前实验一致：统一 pep-seq-onetrans 优于 driver/passenger 独立版本，说明统一 backbone 下的跨序列交互可能很重要。

---

## 10. OneTrans Pyramid

### 10.1 为什么压缩

标准 self-attention 的计算通常近似为：

$$
O(L^2d)
$$

其中 \(L\) 是 token 数，\(d\) 是 hidden dimension。

司机和乘客历史合起来后，\(L\) 变大，会增加：

- attention FLOPs；
- 显存读写；
- 训练时间；
- 线上 P99 延迟。

### 10.2 Pyramid 直觉

浅层读取完整历史，深层逐步减少参与 query 的历史 S-token：

~~~text
Layer 1:
[S S S S S S S S | NS NS NS NS]

Layer 2:
[  S S S S S S   | NS NS NS NS]

Layer 3:
[    S S S S     | NS NS NS NS]

Layer 4:
[      S S       | NS NS NS NS]
~~~

重点：

- S-token 较长，适合逐层压缩；
- NS-token 数量较少，承载当前订单和上下文，不应随意删除；
- 压缩不是简单丢弃历史，而是让浅层 attention 将信息汇聚到保留 token 和 NS-token。

### 10.3 计算收益

如果第 \(l\) 层 query 数为 \(L_l\)，总 attention 开销可以表示为：

$$
\sum_{l=1}^{B} O(L_l^2d)
$$

当 \(L_l\) 随深度递减，深层计算显著降低。

### 10.4 风险

- 压缩过快可能丢失最近行为；
- 司机和乘客序列可能需要不同压缩比例；
- 只保留最近 token 可能忽略长期行为；
- D/O/OD 对历史范围的需求可能不同。

---

## 11. KV Cache

### 11.1 同一请求内的候选复用

一个请求可能对应多个候选订单：

~~~text
同一个司机/乘客历史
        ├── candidate_1
        ├── candidate_2
        ├── candidate_3
        └── candidate_4
~~~

如果历史部分相同，历史 token 的 K/V 可以被多个候选复用。

### 11.2 跨请求复用

如果历史是 append-only，相邻请求可以复用旧历史 K/V，只计算新增事件。

需要处理：

- 历史版本号；
- 时间 cutoff；
- 新增事件是否已经可用；
- driver/passenger ID 是否串线；
- Cache TTL；
- Cache 失效和回滚。

### 11.3 KV Cache 的收益和代价

收益：

- 降低历史重复计算；
- 降低候选数量带来的计算增长；
- 改善吞吐和 P99 延迟。

代价：

- cache 管理复杂；
- 需要线上离线序列一致；
- 命中率受活跃度影响；
- 迟到事件可能造成状态不一致。

---

## 12. PPNet：上层个性化调节

### 12.1 PPNet 解决什么问题

OneTrans 输出共享联合表示，但不同用户、司机、订单和任务的决策规律不同。PPNet 让共享 DNN/tower 对不同样本采用不同的有效 hidden 通道。

~~~text
共享 OneTrans representation
        ↓
用户/司机/订单/上下文先验
        ↓
PPNet Gate NU
        ↓
逐层 hidden scaling
        ↓
D/O/OD task representation
~~~

### 12.2 PPNet 的先验输入

可以使用：

- 乘客 ID 和画像；
- 司机 ID、等级和状态；
- 当前订单和候选特征；
- 司机/乘客历史统计；
- EPNet 输出；
- 场景和上下文特征。

先验信息必须在预测时点可用。

### 12.3 PPNet 公式

$$
\delta_{task}
=
\Omega_{pp}
\left(
O_{prior}
\oplus
\operatorname{StopGrad}(O_{ep})
\right)
$$

第 \(l\) 层：

$$
O_{pp}^{(l)}
=
\delta_{task}^{(l)}
\otimes H^{(l)}
$$

$$
H^{(l+1)}
=
f
\left(
O_{pp}^{(l)}W^{(l)}
+
b^{(l)}
\right)
$$

### 12.4 PPNet 是否生成一套用户模型

通常不是完整 hypernetwork。它不显式生成完整的 \(W^{(l)}\)，而是生成 hidden scaling gate：

~~~text
共享参数 W
    +
样本级 gate δ
    ↓
样本条件化的有效计算路径
~~~

因此比为每个用户维护一套模型更适合工业部署。

### 12.5 任务级差异化

D、O、OD 可以拥有不同的 gate 或 task-specific tower：

~~~text
D task：乘客相关 gate
O task：司机相关 gate
OD task：司乘联合 gate
~~~

关键是软性差异化，而不是完全拆成三个独立模型。

---

## 13. D/O/OD 任务头

### 13.1 结构

~~~text
OneTrans shared representation
        ↓
PPNet task-conditioned representation
        ↓
┌───────────┬───────────┬───────────┐
│ D tower   │ O tower   │ OD tower  │
└─────┬─────┴─────┬─────┴─────┬─────┘
      ↓           ↓           ↓
    D logit     O logit     OD logit
~~~

### 13.2 二分类输出

如果是二分类任务：

$$
p_t = \operatorname{Sigmoid}(z_t)
$$

其中 \(t\in\{D,O,OD\}\)。

### 13.3 多任务损失

$$
\mathcal{L}
=
\lambda_D\mathcal{L}_D
+
\lambda_O\mathcal{L}_O
+
\lambda_{OD}\mathcal{L}_{OD}
$$

二分类损失：

$$
\mathcal{L}_t
=
-y_t\log p_t
-
(1-y_t)\log(1-p_t)
$$

具体 loss 权重、样本权重和标签定义，需要以工程配置为准。

### 13.4 为什么需要多任务

司机和乘客行为并非完全独立：

- 当前订单状态同时影响双方；
- 司机取消可能影响乘客后续行为；
- 乘客状态可能影响司机决策；
- 司乘联合任务提供共享监督。

但多任务也会产生 task seesaw，因此需要 PEPNet 的任务 gate 做柔性调节。

### 13.5 D→O 交互

已有实验 TODO 提出：由于 O 任务收益较少，可以尝试把 D 表示作为 O 的输入。

建议顺序：

~~~text
D hidden → O tower
D logit + stop-gradient → O tower
D predicted probability → O tower
D/O 双向 cross interaction
~~~

不建议训练时直接使用真实 D 标签，否则可能导致标签泄漏和 train-serving skew。

---

## 14. 完整前向传播伪代码

以下是架构级伪代码，具体字段名和张量形状以实际工程为准：

~~~python
# 1. raw inputs
passenger_seq = batch["passenger_history"]
driver_seq = batch["driver_history"]
user_features = batch["user_features"]
driver_features = batch["driver_features"]
order_features = batch["order_features"]
context_features = batch["context_features"]

# 2. base embedding
passenger_events = embed_sequence(passenger_seq)
driver_events = embed_sequence(driver_seq)
user_emb = embed_static(user_features)
driver_emb = embed_static(driver_features)
order_emb = embed_static(order_features)
context_emb = embed_static(context_features)

# 3. EPNet
domain_prior = build_domain_prior(context_features, order_features)
base_embedding = build_base_embedding(
    passenger_events,
    driver_events,
    user_emb,
    driver_emb,
    order_emb,
    context_emb,
)

domain_gate_input = concat(domain_prior, stop_gradient(base_embedding))
domain_gate = gate_nu_ep(domain_gate_input)
personalized_embedding = domain_gate * base_embedding

# 4. unified tokenizer
tokens = unified_tokenizer(
    personalized_embedding,
    role_ids=["driver", "passenger", "user",
              "driver_profile", "order", "context"],
    time_features=batch["time_features"],
    position_ids=batch["position_ids"],
)

# 5. OneTrans
hidden = tokens
for layer in onetrans_layers:
    hidden = layer(
        hidden,
        causal_mask=batch["causal_mask"],
        token_types=batch["token_types"],
        pyramid_state=batch.get("pyramid_state"),
    )

# 6. shared representation
shared_repr = collect_task_representation(hidden)

# 7. PPNet
prior = concat(user_emb, driver_emb, order_emb, context_emb)
pp_gate_input = concat(prior, stop_gradient(shared_repr))

task_hidden = {}
for task in ["D", "O", "OD"]:
    h = shared_repr
    for layer_id, dnn_layer in enumerate(task_dnn_layers[task]):
        task_gate = gate_nu_pp(pp_gate_input,
                               task=task,
                               layer=layer_id)
        h = task_gate * h
        h = dnn_layer(h)
    task_hidden[task] = h

# 8. task heads
d_logit = d_head(task_hidden["D"])
o_logit = o_head(task_hidden["O"])
od_logit = od_head(task_hidden["OD"])

# 9. prediction
d_prob = sigmoid(d_logit)
o_prob = sigmoid(o_logit)
od_prob = sigmoid(od_logit)
~~~

注意：该伪代码解释模块职责，不代表当前工程的真实调用顺序。EPNet 与 OneTrans tokenizer 的先后，需要结合代码确认。

---

## 15. 训练流程和梯度流

### 15.1 训练流程

~~~text
样本构造
  ↓
按 prediction time 截断历史序列
  ↓
Embedding / Tokenizer
  ↓
EPNet 生成 domain gate
  ↓
OneTrans 前向
  ↓
PPNet 生成 task/layer gate
  ↓
D/O/OD heads
  ↓
多任务 loss
  ↓
反向传播
~~~

### 15.2 普通梯度路径

~~~text
Task loss
  → task head
  → PPNet / task DNN
  → OneTrans
  → tokenizer / embedding
~~~

Stop-Gradient 并不表示 EPNet/PPNet 完全没有梯度，而是切断特定的反馈路径，降低个性化 gate 与共享底座之间的强耦合。

### 15.3 多任务冲突

如果三个任务梯度方向不一致：

~~~text
D 梯度希望增强某个 hidden channel
O 梯度希望抑制同一个 channel
OD 梯度又有另一种需求
~~~

固定共享网络可能出现 task seesaw。PPNet 让不同任务对 hidden units 使用不同 gate，从而提供软性参数差异化。

---

## 16. 训练稳定性和超参数

### 16.1 Batch Size

已有实验显示 Batch Size 对序列 PEPNet 影响明显：

- 6 月和 12 月数据上，Batch Size=256 的序列模型均表现出较强收益；
- 小 Batch Size 的梯度噪声可能起到正则化作用；
- 但 Batch Size 变化同时改变 optimizer step、训练时间和参数更新次数。

更稳妥的说法：

> 在当前数据分布和训练设置下，Batch Size=256 表现较好；为了确认独立收益，需要固定总 optimizer step、学习率策略和训练样本量重新对照。

### 16.2 序列长度

一组 6 月数据：

| 序列长度 | OD AUC | O AUC | D AUC |
|---:|---:|---:|---:|
| 10 | 0.8017 | 0.7679 | 0.8915 |
| 20 | **0.8134** | **0.7945** | 0.8979 |
| 30 | 0.7948 | 0.7361 | 0.8977 |
| 40 | 0.7851 | 0.7660 | 0.8820 |

长度 20 在该组实验中最好，但最优长度依赖数据月份、样本分布和时间跨度。

### 16.3 过滤条件

passenger 序列长度 10 且时间跨度小于 10 天的实验曾出现很高收益，但数据量从约 16384w 降到约 1174w。控制数据量相近后收益消失，因此不能直接认为短时间过滤提升了序列质量。

### 16.4 Gate 监控

建议监控：

- gate 均值、方差和分位数；
- gate 是否大量接近 0 或 2；
- 不同任务 gate 是否饱和；
- 不同场景 gate 是否完全相同；
- gate 与样本难度、活跃度和标签的关系；
- 不同随机种子是否稳定。

---

## 17. 当前实验结果

### 17.1 PEPNet + OneTrans

| 模型 | OD AUC | O AUC（司机） | D AUC（乘客） |
|---|---:|---:|---:|
| pep-seq | 0.7421 | 0.7339 | 0.8036 |
| pep-seq-onetrans | **0.7503** | **0.7613** | **0.8697** |

提升：

~~~text
OD：+0.82pp
O ：+2.74pp
D ：+6.61pp
~~~

结论：OneTrans 与 PEPNet 具有明显协同性，D 任务提升最大。

### 17.2 PLE + OneTrans

| 模型 | OD AUC | O AUC（司机） | D AUC（乘客） |
|---|---:|---:|---:|
| ple-seq | 0.7149 | 0.7286 | 0.7500 |
| ple-onetrans | 0.7350 | 0.7258 | 0.7972 |
| warmup-ontrans-8layer-ple | 0.7308 | 0.7102 | **0.8109** |

OneTrans 对 PLE 的收益主要体现在 D 和 OD，O 基本持平或下降。

### 17.3 driver/passenger 独立版本

~~~text
统一 OneTrans：OD=0.7503，O=0.7613，D=0.8697
driver 定制：  OD=0.7178，O=0.7226，D=0.8216
pass 定制：    OD=0.7283，O=0.7086，D=0.8259
~~~

独立版本下降，说明当前任务更需要统一 backbone 下的跨序列交互。

### 17.4 当前实验主结论

1. PEPNet + OneTrans 是当前最有潜力的主方向；
2. OneTrans 对乘客任务 D 的提升最明显；
3. OneTrans 对司机任务 O 有一定提升，但收益相对弱；
4. 司机/乘客完全拆分会削弱跨序列交互；
5. 序列长度、Batch Size、数据过滤方式对结果影响很大；
6. D 表示辅助 O 是值得验证的下一步；
7. AUC 提升仍需要与 CR、取消率和接驾距离业务指标关联。

---

## 18. 未来线上化预研（未完成）

### 18.1 线上输入链路

~~~text
读取当前司机/乘客/订单
        ↓
获取历史事件索引
        ↓
按 prediction time 截断
        ↓
排序、padding、mask
        ↓
Embedding / Tokenizer
        ↓
OneTrans
        ↓
PEPNet gate
        ↓
D/O/OD logits
        ↓
业务打分或排序
~~~

### 18.2 线上离线一致性

需要保证：

~~~text
相同 sample_id
相同 driver/passenger ID
相同历史 cutoff
相同排序键
相同截断长度
相同 padding/mask
相同 token type
相同字典/embedding 版本
相同缺失值处理
~~~

建议对同一条样本输出：

~~~text
offline sequence
online sequence
offline token ids
online token ids
offline embedding
online embedding
offline logit
online logit
~~~

### 18.3 召回过滤模型序列化

需要确认：

- 模型导出格式；
- tokenizer 是否一起导出；
- 特征字典和 embedding 表版本；
- 序列字段顺序；
- 最大长度；
- padding/mask；
- driver/passenger role id；
- 模型热更新；
- 失败降级；
- CPU/GPU 推理延迟；
- batch 推理吞吐。

### 18.4 延迟拆分

建议把 P99 拆成：

~~~text
历史序列获取
序列组装
embedding lookup
tokenizer
OneTrans attention
OneTrans FFN
EPNet/PPNet gate
task heads
网络与序列化
~~~

不能只看整体延迟，否则无法判断瓶颈究竟来自数据链路还是 OneTrans。

### 18.5 工程优化对照

| 优化 | 主要阶段 | 解决的问题 |
|---|---|---|
| FlashAttention | 训练/推理 | attention 显存读写和吞吐 |
| BF16/FP16 | 训练/推理 | 显存和矩阵计算吞吐 |
| Activation recomputation | 训练 | activation 显存 |
| KV Cache | 主要推理 | 重复历史计算 |
| Pyramid | 训练/推理 | 长序列深层 attention 计算 |

---

## 19. 面试八股：高频问题

### Q1：这个模型一句话怎么讲？

> 这是一个基于 PEPNet 和 OneTrans 的司乘多任务序列模型，将司机历史、乘客历史以及订单上下文统一 token 化，通过一个 Transformer 同时建模序列依赖和特征交互，再通过 PEPNet 的 EPNet/PPNet 对底层 embedding 和上层任务表示做样本级个性化调节，最终预测乘客 D、司机 O 和司乘联合 OD 任务。

### Q2：OneTrans 和普通 Transformer 有什么区别？

> OneTrans 的核心差异不只是使用 Transformer，而是把序列 token 和非序列 token 放进同一个 backbone，并针对推荐系统 token 的异构性使用混合参数化：序列 token 共享 Q/K/V 和 FFN，非序列 token 使用 token-specific 参数，同时通过 causal attention、pyramid stack 和 KV Cache 适配工业场景。

### Q3：为什么不用序列 Encoder 加 MLP？

> 传统结构会先把完整历史压缩成一个向量，再与当前订单和上下文交互，导致候选特征无法参与细粒度序列建模。OneTrans 让历史行为 token 和订单/上下文 token 在同一个 attention 图中交互，保留更细粒度的行为—候选关系。

### Q4：OneTrans 输入有哪些 token？

> 主要有 S-token 和 NS-token。S-token 是司机和乘客历史事件；NS-token 是用户、司机画像、当前订单、上下文和统计特征。每个 token 还可以带 role、sequence type、时间差和位置等信息。

### Q5：driver/passenger 为什么不完全拆开？

> 完全拆开会削弱 driver-passenger 跨序列交互，并增加参数和数据需求。当前实验中独立版本低于统一 OneTrans，因此更倾向于统一 backbone，使用 role embedding、segment token 或软门控做差异化。

### Q6：OneTrans 如何表达时间顺序？

> 主要依赖历史事件排列、causal mask、位置/时间差特征、行为类型或 sequence type embedding。具体采用哪一种显式 position encoding，需要以代码配置为准。

### Q7：什么是混合参数化？

> 长而同质的序列 token 共享 Q/K/V 和 FFN，控制参数量并提升泛化；短而异质的用户、订单和上下文 token 使用 token-specific 参数，保留字段语义。

### Q8：为什么 S-token 共享参数？

> S-token 都表示历史行为中的一个事件，语义相对同质。共享参数可以避免参数量随序列长度增长，也让模型学习处理“一个历史事件”的通用函数。

### Q9：为什么 NS-token 使用专属参数？

> user、order、context 和 statistics 的语义不同。如果共用一个函数，表达能力会被压缩。token-specific 参数让不同字段拥有自己的 query、key、value 和 FFN 变换。

### Q10：PEPNet 是什么？

> PEPNet 是 Parameter and Embedding Personalized Network，通过先验信息生成 gate，对 Embedding 和 DNN hidden 做样本级调节。它不为每个用户训练完整模型，而是通过轻量 gate 改变共享模型的有效计算路径。

### Q11：EPNet 和 PPNet 的区别？

> EPNet 作用在底层 Embedding，主要根据场景信息进行 domain personalization；PPNet 作用在上层 DNN hidden/task representation，主要根据用户、司机、订单和任务先验进行 personalization。

### Q12：Gate NU 怎么做？

> Gate NU 是两层 MLP，先用 ReLU 做特征交叉，再用 Sigmoid 生成 gate，并乘以 gamma，通常 gamma=2，使 gate 大致位于 0 到 2，最后对 embedding 或 hidden 做逐元素乘法。

### Q13：为什么 gate 范围是 0 到 2？

> 以 1 为中心可以同时支持抑制和增强。接近 0 是抑制，接近 1 是保持，大于 1 是增强。

### Q14：为什么 EPNet 使用 Stop-Gradient？

> 为了隔离共享 embedding 的学习和场景 gate 的学习，避免某个场景的 gate 梯度反向破坏通用 embedding，缓解 domain seesaw。

### Q15：PPNet 是不是 hypernetwork？

> 它具有样本条件化参数调节思想，但通常不显式生成完整 DNN 权重，而是生成 hidden scaling gate，因此更准确地说是轻量参数个性化或动态调制。

### Q16：Pyramid Stack 做了什么？

> 随着层数增加，逐步减少参与 query 的历史 S-token 数量，把长历史信息提炼到更少的 token 和 NS-token 中，降低深层 attention 计算。

### Q17：为什么使用 causal attention？

> 一方面表达历史顺序并防止未来泄漏，另一方面将历史放前、候选和上下文放后，支持复用历史 K/V。

### Q18：KV Cache 在司乘场景怎么用？

> 同一请求的多个候选通常共享司机和乘客历史，因此历史 K/V 可以复用；如果历史是增量追加的，跨请求也可以只计算新增事件。前提是 cutoff、版本和序列构造一致。

### Q19：D/O/OD 怎么理解？

> D 是乘客任务，O 是司机任务，OD 是司乘联合任务。三个任务可以共享 OneTrans 表示，再通过 PEPNet 进行任务级个性化调节。

### Q20：为什么 D 任务提升比 O 任务大？

> 当前实验观察到 D 提升更明显，但不能确定唯一原因。可能与乘客序列信号更强、司机标签更稀疏、司机侧时空特征不足、司乘交互不足或任务不平衡有关。

### Q21：把 D 作为 O 输入会不会泄漏？

> 如果使用真实 D 标签，会有泄漏风险。更安全的是使用 D hidden、D logit 或线上可获得的 D prediction，并保证训练和线上输入分布一致。

### Q22：为什么 Batch Size=256 可能更好？

> 序列特征增加了冗余和相关维度，优化更复杂。较小 Batch Size 的梯度噪声可能起正则化作用，但需要固定 optimizer step、学习率和总样本量进一步确认。

### Q23：为什么长度 20 比 10、30、40 好？

> 可能存在信息与噪声平衡：10 历史不足，30/40 引入更老和更冗余行为，20 在当前数据分布下处于有效窗口。最优长度不能跨数据集直接外推。

### Q24：过滤短时间序列为什么不能直接认为有效？

> 因为过滤使样本量从约 16384w 变成 1174w，数据分布、难度和正负比例同时改变。控制数据量后收益消失，所以不能把初始高 AUC 直接归因于过滤。

### Q25：AUC 提升能否说明业务指标提升？

> 不能直接说明。AUC 反映排序区分能力，业务指标还受阈值、流量、校准、策略和供需环境影响，需要线上 A/B 或业务回放验证。

### Q26：如何检查序列穿越？

> 以 prediction time 为锚点，同时检查 event time 和 available time；使用稳定排序键，排除当前订单和未来事件；对离线和线上序列做字段级、token 级和 logit 级 diff。

### Q27：如何定位线上离线不一致？

> 从 sample ID、司机/乘客 ID、历史事件集合、排序、截断、padding、mask、role id、字典版本、embedding 和最终 logit 逐层对比，而不是只对比最终分数。

### Q28：OneTrans 的主要成本在哪里？

> 主要是长序列 attention、tokenizer 投影、FFN、序列获取和候选重复计算。可以使用 pyramid、FlashAttention、混合精度和 KV Cache 优化。

### Q29：如果延迟不允许，优先优化什么？

> 先确认序列获取和组装是否是瓶颈，再看 attention 和 FFN；优先做序列截断、pyramid、KV Cache、混合精度和批量化。

### Q30：项目核心创新怎么说？

> 核心不是简单使用 Transformer，而是把司机历史、乘客历史和订单上下文放进统一 token 空间联合建模，同时利用 PEPNet 在底层 embedding 和上层任务表示上做样本级个性化调节，兼顾跨序列交互、任务差异和工业部署效率。

---

## 20. 面试用 30 秒版本

> 我们把司机和乘客的历史订单序列，以及用户、订单、上下文等非序列特征统一转成 token，输入 OneTrans。OneTrans 使用 causal Transformer 同时学习序列依赖、司机—乘客跨序列交互和序列—订单特征交互，并通过混合参数化区分长序列 token 和异质非序列 token。之后引入 PEPNet，使用 EPNet 在 embedding 层根据场景先验生成 gate，使用 PPNet 在上层 hidden/task representation 上根据用户、司机和订单先验做动态调节，最后通过 D、O、OD 三个任务头预测乘客、司机和司乘联合行为。

---

## 21. 面试用 2 分钟版本

> 传统模型一般先把司机或乘客历史序列编码成一个压缩向量，再和当前订单、用户画像和上下文做特征交互。这样会导致序列在交互前被过早压缩，当前候选订单难以参与细粒度历史建模，司机和乘客序列之间也容易割裂。
>
> 我们的做法是把司机历史事件、乘客历史事件、用户/司机画像、当前订单和上下文都 token 化，统一输入 OneTrans。序列事件作为 S-token，用户、订单和上下文作为 NS-token。S-token 共享 Q/K/V 和 FFN，因为它们是相对同质的历史事件；NS-token 使用 token-specific 参数，因为 user、order、context 的语义差异很大。OneTrans 使用 causal mask 表达历史顺序，并用 pyramid 逐层压缩长序列，线上可以通过 KV Cache 复用相同司机/乘客历史。
>
> OneTrans 输出联合表示后，PEPNet 继续做个性化调节。EPNet 在底层 embedding 侧使用场景先验生成 domain gate，对共享 embedding 做逐元素缩放；PPNet 在上层 DNN hidden 侧使用用户、司机、订单等先验生成 task gate，对不同任务的 hidden representation 做动态调节。最终通过 D、O、OD 任务头完成多任务预测。
>
> 实验上，统一 PEPNet + OneTrans 优于 driver/passenger 完全拆分版本，说明当前任务需要跨序列交互。乘客任务 D 的提升比司机任务 O 更明显，后续可以研究 D 表示辅助 O、司机侧时空特征以及线上序列一致性。

---

## 22. 哪些是事实，哪些需要以代码为准

### 22.1 现有材料明确支持

- D 是乘客任务，O 是司机任务，OD 是司乘联合任务；
- 使用司机和乘客历史序列；
- PEPNet 包含 Gate NU、EPNet 和 PPNet；
- OneTrans 统一序列和非序列特征；
- OneTrans 使用混合参数化、causal attention、pyramid 和 KV Cache 思路；
- PEPNet + OneTrans 的离线结果；
- driver/passenger 独立版本低于统一版本；
- Batch Size、序列长度和数据过滤会显著影响结果；
- 召回序列化和线上一致性是落地重点。

### 22.2 当前材料没有明确

- 完整序列字段清单；
- token 的确切排列顺序；
- driver/passenger 是否时间交错；
- 显式 position encoding 的具体实现；
- EPNet 在工程代码中位于 tokenizer 前还是 token projection 后；
- PPNet 具体作用于 OneTrans 哪几层；
- 参数量、hidden size、head 数和实际层数；
- loss 权重、负采样和样本权重；
- GPU 数量、训练耗时、显存；
- 线上 P99、QPS 和 A/B 业务提升。

稳妥回答：

> 架构层面可以明确 OneTrans 负责统一序列—特征建模，EPNet 负责底层 embedding personalization，PPNet 负责上层 task representation personalization；但具体 token 字段、张量形状和模块调用顺序需要以工程实现为准。

---

## 23. 最终 Takeaway

~~~text
OneTrans：统一序列建模和特征交互
EPNet：场景/域条件下的 embedding gate
PPNet：用户/司机/订单/任务条件下的 hidden gate
Pyramid：长序列逐层压缩
Causal Mask：保证时序方向和支持 KV Cache
KV Cache：复用历史，降低线上重复计算
D/O/OD Heads：输出乘客、司机和司乘联合预测
~~~

整个模型可以记成：

> **统一 token 化输入，OneTrans 做序列与特征联合建模，PEPNet 做底层和上层个性化调节，多任务 head 输出乘客、司机和司乘联合行为。**

---

## 24. 关联文档

- [[04-离线实验与消融]]
- [[OneTrans：用一个 Transformer 统一序列建模与特征交互]]
- [[司乘行为序列建设项目面试问答]]
- [PEPNet 论文](https://arxiv.org/abs/2302.01115)
- [OneTrans 论文](https://arxiv.org/abs/2510.26104)
- [EVE 实验链接](https://ether-nmg.intra.hongyibo.com.cn/labs/new/15171)
