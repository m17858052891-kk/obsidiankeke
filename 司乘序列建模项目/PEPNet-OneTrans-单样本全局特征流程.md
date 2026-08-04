# PEPNet × OneTrans：从一条司乘订单样本走完整模型

> 本文通过一条**虚构的离线样本**，梳理乘客历史序列、司机历史序列、用户/订单/上下文特征如何经过 Embedding、EPNet、OneTrans、PPNet，最终得到 D/O/OD 三个任务预测。  
> 
> 任务口径：**D = 乘客任务；O = 司机任务；OD = 司乘联合任务。**
>
> 说明：文中的特征字段、示例数值、token 排列和维度是用于讲解架构的合理示例；真实字段定义、张量形状、token 顺序和模块调用顺序必须以实际 SQL、特征配置和代码为准。

---

## 1. 全局架构

~~~text
当前离线样本
├── 乘客 P 的历史订单序列
├── 司机 D 的历史订单序列
└── 当前订单 R + 上下文特征
               ↓
      基础 Embedding / Feature Projection
               ↓
  EPNet：根据场景先验调节底层表示
               ↓
  Unified Tokenizer：组织 S-token / NS-token
               ↓
  OneTrans：统一序列—特征交互骨干
               ↓
  PPNet：根据样本和任务先验调节上层 hidden
               ↓
          D / O / OD 三个任务头
               ↓
     乘客、司机、司乘联合离线预测分数
~~~

这里每个模块的职责是：

| 模块 | 做什么 | 解决的问题 |
|---|---|---|
| Embedding | 把稀疏 ID、稠密数值、历史事件转为向量 | 原始特征格式异构 |
| EPNet | 对底层向量做场景/域条件门控 | 不同场景特征重要性不同 |
| Tokenizer | 把司机、乘客、订单、上下文组织成统一 token 序列 | 序列和静态特征原本割裂 |
| OneTrans | 做序列依赖、跨序列和高阶特征交互 | 传统先编码后交互的信息损失 |
| PPNet | 对上层 hidden 按样本和任务动态缩放 | 多任务固定共享参数不够个性化 |
| D/O/OD head | 输出各任务 logit/probability | 多目标联合预测 |

---

## 2. 用一条具体样本建立直觉

设当前离线样本的预测时点为：

~~~text
2025-06-25 08:30:00
~~~

当前订单为 R：

| 字段 | 示例值 | 含义 |
|---|---|---|
| passenger_id | P_1001 | 当前乘客 |
| driver_id | D_9008 | 当前司机 |
| product | 快车 | 当前产品/场景 |
| origin_grid | A | 起点区域 |
| destination_grid | B | 终点区域 |
| estimated_distance | 8.2 km | 预估行程距离 |
| pickup_distance | 2.8 km | 司机接驾距离 |
| price | 32 元 | 当前报价 |
| hour | 8 | 早高峰 |
| weekday | 工作日 | 时间上下文 |
| supply_demand | 紧张 | 区域供需上下文 |

当前样本要预测：

~~~text
D：乘客侧标签/行为
O：司机侧标签/行为
OD：司乘联合标签/行为
~~~

本文不把它们强行解释成具体取消或完单标签；真实标签定义取决于训练任务。

### 2.1 乘客 P 的历史序列

例如在预测时点之前，乘客 P 有 4 笔可用历史订单：

| 时间 | 历史行为 | 订单距离 | 接驾距离 | 价格 | 结果 | 场景 |
|---|---|---:|---:|---:|---|---|
| 6/24 19:10 | 下单 | 3.1 km | 1.0 km | 15 元 | 完成 | 晚高峰 |
| 6/23 08:20 | 下单 | 9.5 km | 3.5 km | 38 元 | 取消 | 早高峰 |
| 6/20 14:30 | 下单 | 2.2 km | 0.8 km | 12 元 | 完成 | 平峰 |
| 6/18 09:00 | 下单 | 7.8 km | 2.6 km | 31 元 | 完成 | 早高峰 |

从这些事件中，模型理论上可以学习到：

- 乘客近期有过取消行为；
- 取消样本和当前订单都发生在早高峰；
- 取消样本的接驾距离较长；
- 当前订单也属于较长接驾距离；
- 当前价格和历史早高峰订单接近。

这不是人工规则，而是希望 OneTrans 从 token 交互中学到的模式。

### 2.2 司机 D 的历史序列

例如在预测时点之前，司机 D 有 4 笔可用历史订单：

| 时间 | 历史行为 | 接驾距离 | 服务距离 | 结果 | 时段 |
|---|---|---:|---:|---|---|
| 6/25 08:05 | 接单 | 1.2 km | 4.0 km | 完成 | 早高峰 |
| 6/24 18:40 | 接单 | 3.0 km | 6.5 km | 取消 | 晚高峰 |
| 6/23 08:10 | 接单 | 2.5 km | 8.7 km | 完成 | 早高峰 |
| 6/20 13:50 | 接单 | 0.9 km | 3.2 km | 完成 | 平峰 |

从这些事件中，模型可能学习到：

- 司机近期处于活跃服务状态；
- 司机有长接驾距离下的取消行为；
- 司机对早高峰和中等接驾距离有不同偏好；
- 当前 2.8 km 接驾距离与司机历史行为存在关联。

### 2.3 静态和上下文特征

除序列外，当前样本还可以有：

~~~text
乘客画像：活跃度、历史取消率、近期订单频次
司机画像：等级、近期在线时长、接单率、历史履约率
订单特征：起终点、价格、预估距离、接驾距离、产品类型
上下文特征：小时、工作日、场景、区域供需、天气/路况
统计特征：区域历史取消率、司机近 N 单统计、乘客近 N 单统计
~~~

这些特征回答的是：

~~~text
现在是什么订单？
谁是当前乘客？
谁是当前司机？
当前所处什么场景？
~~~

而序列回答的是：

~~~text
这名乘客过去怎么做？
这名司机过去怎么做？
当前订单与过去的关系是什么？
~~~

---

## 3. 第一步：样本构造与防穿越

### 3.1 先定义预测锚点

这条样本的锚点是：

~~~text
prediction_time = 2025-06-25 08:30:00
~~~

任何历史事件必须满足：

~~~text
event_time < prediction_time
AND available_time <= prediction_time
~~~

其中：

- event_time：行为真实发生时间；
- available_time：该信息在线上真正可用的时间。

只写日期过滤不够。例如一笔订单在 6/25 09:00 才完成，就不能被放进 6/25 08:30 的历史序列。

### 3.2 排序与截断

乘客序列和司机序列都需要按稳定键排序：

~~~text
ORDER BY event_time ASC, stable_event_id ASC
~~~

然后按策略截断，例如：

~~~text
最近 20 单
或最近 30 天内的 20 单
~~~

已有离线实验中，长度 20 在一组 6 月数据上相对 10、30、40 表现最好；但最优长度依赖数据分布，不能直接视为固定结论。

### 3.3 为什么样本建设很重要

如果历史数据穿越，模型会看到未来取消、完成或应答结果，离线 AUC 会异常高，线上却无法复现。

因此，一个合格的序列样本至少要确保：

- 当前订单不会被塞进历史；
- 未来订单不会进入历史；
- 同时刻事件有稳定二级排序；
- 离线和线上采用同样截断规则；
- 不使用预测时点后才可获得的统计特征。

---

## 4. 第二步：把原始特征变成向量

### 4.1 稀疏 ID Embedding

乘客 ID、司机 ID、区域 ID、产品 ID 等稀疏字段通常查 Embedding 表：

$$
e_{passenger}=E_{passenger}[P\_1001]
$$

$$
e_{driver}=E_{driver}[D\_9008]
$$

$$
e_{product}=E_{product}[快车]
$$

这些 embedding 是可训练参数，目的是把离散身份和类别投影到连续空间。

### 4.2 稠密特征投影

以当前订单的接驾距离为例：

~~~text
pickup_distance = 2.8 km
~~~

它可能经历：

~~~text
原始数值
  ↓
clip / log1p / normalize / bucketize
  ↓
linear 或 MLP projection
  ↓
dense feature vector
~~~

形式上可以写为：

$$
e_{pickup}
=
\operatorname{MLP}
(
\operatorname{Normalize}(2.8)
)
$$

价格、行程距离、订单频次、在线时长等稠密特征也可采用相同思路。

### 4.3 历史事件 Embedding

以乘客在 6/23 08:20 的历史订单为例：

~~~text
订单距离：9.5 km
接驾距离：3.5 km
价格：38 元
结果：取消
场景：早高峰
距当前预测时点：约 2 天
~~~

可得到一个 passenger event token：

$$
x_{p,2}
=
\operatorname{Fuse}
(
e_{status},
e_{distance},
e_{pickup},
e_{price},
e_{time},
e_{scene},
e_{result}
)
$$

其中 Fuse 可以是：

- concat + MLP；
- sum；
- field attention；
- 其他项目自定义的融合模块。

司机历史事件也用相同思路形成 driver event token。

### 4.4 为什么不能直接把历史统计拼接进去

直接拼接“乘客最近 10 单取消率”可以提供汇总信息，但会丢掉：

~~~text
哪一单取消？
取消发生在什么时间？
当时接驾距离多远？
是否和当前订单处在相似场景？
取消前后行为是否发生变化？
~~~

序列 token 保留了事件粒度，允许模型动态选择和当前订单最相关的历史。

---

## 5. 第三步：EPNet 在底层做什么

### 5.1 EPNet 的位置

在概念上，EPNet 位于底层 Embedding 一侧：

~~~text
基础特征 Embedding
        ↓
场景/域先验
        ↓
EPNet gate
        ↓
个性化 Embedding
        ↓
Tokenizer / OneTrans
~~~

它解决的问题是：

> 同一个乘客、司机或订单特征，在早高峰、平峰、不同产品或不同区域场景下，重要性不一样。

### 5.2 示例：当前订单的场景先验

当前订单具备：

~~~text
产品：快车
时段：工作日早高峰
区域供需：紧张
接驾距离：2.8 km
~~~

这些特征可以组成 domain prior：

$$
z_{domain}
=
\operatorname{Concat}
(
e_{product},
e_{hour},
e_{weekday},
e_{supply\_demand},
e_{region}
)
$$

同时，基础 Embedding 表示为 \(E\)。EPNet 的 Gate NU 生成：

$$
\delta_{domain}
=
\Omega_{ep}
(
z_{domain}
\oplus
\operatorname{StopGrad}(E)
)
$$

再做逐元素缩放：

$$
O_{ep}
=
\delta_{domain}
\otimes E
$$

### 5.3 直观理解

假设某一时刻 gate 的部分维度是：

~~~text
δdomain = [1.35, 0.82, 1.11, 0.64, ...]
~~~

这不代表某个具体业务字段被直接放大 1.35 倍，而是表示 embedding 空间中对应维度被动态调节：

~~~text
1.35：增强当前场景重要的表示维度
0.82：弱化当前场景较弱的表示维度
1.11：轻微增强
0.64：明显压制
~~~

对当前早高峰、供需紧张、较长接驾距离样本，EPNet 可能让与场景、距离和历史行为相关的 embedding 维度更突出。

### 5.4 Stop-Gradient 的意义

EPNet 读取共享 Embedding 时使用 Stop-Gradient：

$$
\operatorname{StopGrad}(E)
$$

其目的不是让 EPNet 不学习，而是避免 gate 的输入路径反向强干扰共享 Embedding。

可以理解为：

~~~text
共享 Embedding：学习所有场景的通用规律
EPNet gate：学习当前场景如何调节通用规律
~~~

这有助于缓解多个场景之间的 domain seesaw。

---

## 6. 第四步：统一 Tokenizer 如何组织数据

### 6.1 S-token 和 NS-token

OneTrans 将输入划分为：

| Token 类型 | 本样本中的内容 |
|---|---|
| S-token | 乘客历史订单事件、司机历史订单事件 |
| NS-token | 乘客画像、司机画像、当前订单、上下文、统计特征 |

对当前样本，可形成：

~~~text
乘客 S-token：
P1, P2, P3, P4

司机 S-token：
D1, D2, D3, D4

NS-token：
PassengerProfile
DriverProfile
Order
Context
Statistics
~~~

### 6.2 一种可解释的 token 排列

一种示例排列：

~~~text
[D1, D2, D3, D4,
 SEP_DRIVER_PASSENGER,
 P1, P2, P3, P4,
 SEP_SEQUENCE_STATIC,
 PassengerProfile,
 DriverProfile,
 Order,
 Context,
 Statistics]
~~~

每个 token 还可以叠加：

$$
x_i
=
e_{content,i}
+
e_{role,i}
+
e_{time,i}
+
e_{position,i}
$$

其中：

- content embedding：事件/字段自身内容；
- role embedding：司机、乘客、订单、上下文等角色；
- time embedding：时间差、小时、星期或时间 bucket；
- position embedding：在序列中的相对位置。

### 6.3 司机—乘客 token 为什么需要 role 标识

司机和乘客历史事件可能都包含“取消”“距离”“区域”等字段。如果没有 role embedding，模型可能难以区分：

~~~text
乘客取消：表达乘客的价格/体验/等待敏感度
司机取消：表达司机的接驾偏好、收益预期或供需状态
~~~

因此即便字段结构相似，也需要让模型知道 token 属于谁。

### 6.4 Token 顺序决定信息方向

OneTrans 使用 causal attention，因此 token 排列不是纯格式问题，而会影响谁能看谁。

例如上述排列下：

- 后部 Order、Context、Statistics token 能看到前面的司机和乘客历史；
- PassengerProfile 能看到此前的历史；
- 早期 Driver token 无法看到后面的 Passenger token；
- 如果希望历史事件之间相互直接交互，需要重新设计 token 排列或 mask。

因此不能简单说“司机序列和乘客序列完全双向交互”。更准确的说法是：

> 两类序列被放在统一注意力图中，跨序列信息流由具体 token 排列和 causal mask 决定；当前订单和上下文 token 可以聚合前序司机、乘客历史，从而形成联合表征。

### 6.5 两种非序列 Tokenizer

#### Group-wise Tokenizer

人为分组：

~~~text
乘客画像特征组 → PassengerProfile token
司机画像特征组 → DriverProfile token
订单特征组     → Order token
上下文特征组   → Context token
统计特征组     → Statistics token
~~~

优点：可解释、方便消融。

#### Auto-Split Tokenizer

把全部非序列特征拼接，经过 MLP 后切分：

$$
NS\text{-}Tokens
=
\operatorname{Split}
(
\operatorname{MLP}
(
\operatorname{Concat}(NS)
)
)
$$

优点：让静态特征先发生稠密交互，人工分组负担更小。

当前项目实际采用哪一种，需要以代码为准。

---

## 7. 第五步：OneTrans 如何处理这些 Token

### 7.1 Block 的基本结构

OneTrans 可以抽象为重复堆叠的 Transformer Block：

~~~text
输入 Token
   ↓
RMSNorm
   ↓
Mixed Causal Attention
   ↓ + residual
RMSNorm
   ↓
Mixed FFN
   ↓ + residual
输出 Token
~~~

形式上：

$$
H'
=
H+
\operatorname{MixedMHA}
(
\operatorname{RMSNorm}(H)
)
$$

$$
H_{out}
=
H'+
\operatorname{MixedFFN}
(
\operatorname{RMSNorm}(H')
)
$$

### 7.2 Mixed 参数化：谁共享参数，谁使用专属参数

OneTrans 的关键设计：

~~~text
S-token：共享 Q/K/V 和 FFN 参数
NS-token：使用 token-specific Q/K/V 和 FFN 参数
~~~

对本样本：

| Token | 参数策略 | 原因 |
|---|---|---|
| P1~P4、D1~D4 | 序列共享参数 | 都是历史事件，语义相对同质 |
| PassengerProfile | 专属参数 | 乘客画像字段 |
| DriverProfile | 专属参数 | 司机画像字段 |
| Order | 专属参数 | 当前候选订单 |
| Context | 专属参数 | 场景、时段、供需 |
| Statistics | 专属参数 | 历史统计/校准信息 |

统一写为：

$$
Q_i =
X_i W^Q_{type(i)}
$$

$$
K_i =
X_i W^K_{type(i)}
$$

$$
V_i =
X_i W^V_{type(i)}
$$

其中 type(i) 决定使用共享 S-token 参数，还是某个 NS-token 的专属参数。

### 7.3 Attention 到底在学习什么

以 Order token 为例，它代表当前订单：

~~~text
当前接驾距离：2.8 km
当前行程距离：8.2 km
当前价格：32 元
当前时段：早高峰
~~~

Order token 作为 query，可以从历史 token 中寻找与当前订单最相关的信息：

~~~text
注意力较高的乘客历史：
- 早高峰、接驾距离 3.5 km、结果取消的订单

注意力较高的司机历史：
- 早高峰、接驾距离 2.5 km、结果完成的订单
- 晚高峰、接驾距离 3.0 km、结果取消的订单
~~~

实际 attention 权重由模型自动学习；上述只是解释“当前订单 token 为什么需要看历史 token”。

### 7.4 乘客和司机信息怎么融合

在统一 Transformer 中，至少有两种融合路径：

~~~text
路径 A：当前 Order/Context token 聚合司机历史和乘客历史
路径 B：根据 token 排列与 mask，后序乘客/司机 token 直接读取前序另一类历史
~~~

即使采用严格 causal mask，Order/Context token 位于序列后部时也可以同时读取两类历史，形成联合状态：

~~~text
当前订单表示
=
乘客历史摘要
+
司机历史摘要
+
订单自身信息
+
当前上下文
~~~

这也是统一 OneTrans 可能优于 driver/passenger 完全拆分 Encoder 的原因。

### 7.5 RMSNorm 的作用

司机、乘客、订单、统计特征的向量数值分布可能不同。RMSNorm 在 attention/FFN 前稳定向量尺度：

$$
\operatorname{RMSNorm}(x)
=
\frac{x}
{
\sqrt{
\frac{1}{d}
\sum_{j=1}^{d}x_j^2
+
\epsilon
}
}
\odot g
$$

它可以减少某类 token 因数值尺度过大而过度主导 attention 的风险。

---

## 8. 第六步：Pyramid 如何处理长历史

### 8.1 为什么需要 Pyramid

如果乘客有 20 条历史、司机有 20 条历史，再加上多个 NS-token，总长度会持续增加。

标准 self-attention 的计算复杂度近似为：

$$
O(L^2d)
$$

其中 \(L\) 是 token 数，\(d\) 是 hidden dimension。

### 8.2 金字塔过程

OneTrans Pyramid 的直觉是：

~~~text
浅层：读更完整的司机/乘客历史
中层：减少一部分 S-token 参与 query
深层：保留较少、高信息密度的历史表示和全部 NS-token
~~~

示例：

~~~text
Layer 1：
[D1 D2 D3 D4 P1 P2 P3 P4 | NS NS NS NS NS]

Layer 2：
[   D2 D3 D4    P2 P3 P4 | NS NS NS NS NS]

Layer 3：
[      D3 D4       P3 P4 | NS NS NS NS NS]
~~~

需要注意：

- 这是解释性示意，不是当前项目的实际裁剪规则；
- Pyramid 主要压缩长序列 S-token；
- Order、Context 等 NS-token 通常保留，因为它们承载当前预测请求；
- 压缩不是简单删除，浅层已将部分历史信息传递给保留 token 和 NS-token。

### 8.3 和当前序列长度实验的关系

项目已有序列长度消融：

| 长度 | OD AUC | O AUC | D AUC |
|---:|---:|---:|---:|
| 10 | 0.8017 | 0.7679 | 0.8915 |
| 20 | **0.8134** | **0.7945** | 0.8979 |
| 30 | 0.7948 | 0.7361 | 0.8977 |
| 40 | 0.7851 | 0.7660 | 0.8820 |

这说明历史不是越长越好：过长历史可能引入过时、冗余和噪声行为。Pyramid 是计算优化；序列长度是信息范围选择；两者都需要通过消融共同确定。

---

## 9. 第七步：PPNet 如何对任务做个性化调节

### 9.1 OneTrans 输出什么

经过若干 OneTrans Block 后，至少能得到：

~~~text
乘客历史相关的 hidden states
司机历史相关的 hidden states
PassengerProfile hidden
DriverProfile hidden
Order hidden
Context hidden
Statistics hidden
~~~

可以从特定 NS-token、拼接多个 NS-token 或通过池化得到共享联合表示：

$$
h_{shared}
=
\operatorname{Readout}
(
H_{OneTrans}
)
$$

具体 readout 使用哪个 token 或怎样 pooling，需要看实际实现。

### 9.2 PPNet 的输入

PPNet 使用当前样本的个性化先验，例如：

~~~text
乘客画像 embedding
司机画像 embedding
订单 embedding
上下文 embedding
EPNet 输出或场景表示
OneTrans 的共享联合表示
~~~

形成：

$$
z_{prior}
=
\operatorname{Concat}
(
e_{passenger},
e_{driver},
e_{order},
e_{context}
)
$$

任务 gate：

$$
\delta_{task}
=
\Omega_{pp}
(
z_{prior}
\oplus
\operatorname{StopGrad}
(
h_{shared}
)
)
$$

### 9.3 D/O/OD 的 gate 为什么不同

同一条当前订单，对三个任务的重要信息不同：

~~~text
D（乘客）：
可能更看重乘客历史取消、价格、等待/接驾距离敏感度

O（司机）：
可能更看重司机最近接单/取消、收益效率、接驾偏好、供需状态

OD（司乘联合）：
需要同时看双方状态和订单匹配关系
~~~

PPNet 可以为不同任务、不同层生成不同 gate：

$$
h_{task}^{(l)}
=
\delta_{task}^{(l)}
\otimes
h^{(l)}
$$

再输入下一层 DNN：

$$
h^{(l+1)}
=
f
(
h_{task}^{(l)}W^{(l)}
+
b^{(l)}
)
$$

### 9.4 直观例子

假设 PPNet 对当前样本生成：

~~~text
D task gate：
更增强“乘客近期取消 + 高峰 + 长接驾距离”相关 hidden channel

O task gate：
更增强“司机近期接单率 + 当前接驾距离 + 区域供需”相关 hidden channel

OD task gate：
更增强“双方历史状态匹配 + 订单距离 + 时空条件”相关 hidden channel
~~~

这不是让三个任务拥有完全独立的模型，而是在共享 OneTrans 表示上走出不同的有效计算路径。

---

## 10. 第八步：三项任务如何输出

每个任务有自己的 tower/head：

~~~text
h_shared
   ↓
PPNet task-specific scaling
   ↓
D tower  → D logit  → D probability
O tower  → O logit  → O probability
OD tower → OD logit → OD probability
~~~

二分类时：

$$
p_t
=
\operatorname{Sigmoid}(z_t)
$$

其中：

$$
t\in\{D,O,OD\}
$$

多任务损失可以写成：

$$
\mathcal{L}
=
\lambda_D \mathcal{L}_D
+
\lambda_O \mathcal{L}_O
+
\lambda_{OD}\mathcal{L}_{OD}
$$

具体 loss 权重、标签定义、样本权重和负采样策略，现有文档没有明确，不应编造。

### 10.1 D→O 的扩展

当前实验记录提出过：O 任务提升较少，可以尝试将 D 表示作为 O 的输入。

较安全的顺序：

~~~text
D hidden → O tower
D logit + stop-gradient → O tower
D predicted probability → O tower
~~~

不要在训练时直接将真实 D 标签输入 O tower；线上预测时拿不到真实标签，会造成 train-serving skew 或信息泄漏。

---

## 11. 将整条样本串起来

下面把当前样本 R 再走一遍：

### 11.1 输入

~~~text
当前订单 R：
早高峰、快车、接驾距离 2.8 km、行程距离 8.2 km、价格 32 元、供需紧张

乘客 P：
历史有一笔早高峰、接驾距离 3.5 km 的取消订单

司机 D：
近期有接驾距离 2.5 km 的早高峰完成订单，也有 3.0 km 的取消订单
~~~

### 11.2 Embedding 与 EPNet

~~~text
ID、区域、产品 → embedding
距离、价格、频次 → dense projection
历史订单字段 → event embedding
早高峰/快车/供需紧张 → domain prior
domain prior → EPNet gate
EPNet gate × base embedding → 场景自适应表示
~~~

### 11.3 Tokenizer

~~~text
司机历史订单 → D1~D4 S-token
乘客历史订单 → P1~P4 S-token
当前订单 → Order NS-token
早高峰/供需 → Context NS-token
双方画像 → PassengerProfile / DriverProfile NS-token
统计信息 → Statistics NS-token
~~~

### 11.4 OneTrans

~~~text
Order token 查询：
“当前 2.8 km、早高峰、32 元订单与哪些历史行为相关？”

它可聚合：
- 乘客早高峰 3.5 km 接驾距离取消事件
- 司机早高峰 2.5 km 接驾距离完成事件
- 司机 3.0 km 接驾距离取消事件
- 当前供需紧张、产品快车等上下文
~~~

经过多层 attention 和 FFN，形成结合司机、乘客、订单、时空条件的联合表示。

### 11.5 PPNet 与任务头

~~~text
D tower：
强调乘客历史、价格/等待敏感度和当前订单条件

O tower：
强调司机接单/取消偏好、收益/距离和供需条件

OD tower：
强调双方状态匹配和订单条件
~~~

最终输出 D/O/OD 三项离线分数，用于训练中的多任务 loss 和离线 AUC 评估。

---

## 12. 与现有离线实验结果如何对应

### 12.1 PEPNet + OneTrans

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

这支持了以下架构判断：

- 统一 OneTrans 可能提高序列—静态特征交互质量；
- PEPNet 的个性化 gate 与 OneTrans 联合表示存在协同；
- 乘客任务 D 从序列建模中获得的收益最明显。

### 12.2 为什么不建议完全拆 driver/passenger

当前结果：

~~~text
统一 OneTrans：OD=0.7503，O=0.7613，D=0.8697
driver 定制：  OD=0.7178，O=0.7226，D=0.8216
pass 定制：    OD=0.7283，O=0.7086，D=0.8259
~~~

说明当前更值得尝试：

~~~text
统一 backbone
+
driver/passenger role embedding
+
segment token
+
软性任务/角色 gate
~~~

而不是完全独立的分支。

### 12.3 Batch Size 与数据过滤的谨慎结论

- Batch Size=256 在 6 月和 12 月的序列实验中表现较好，但需要固定总 optimizer step、学习率策略和训练样本量后重新确认；
- passenger 序列时间跨度过滤曾出现很高 AUC，但数据量从约 16384w 降到 1174w，控制数据量后收益消失，不能把初始提升直接归因于过滤策略；
- 序列长度 20 在一组数据上最好，不代表所有月份都应固定使用 20。

---

## 13. 当前模型是线下尝试，不是线上模型

当前材料支持的事实是：

- 已开展多组离线实验；
- 使用 AUC 作为主要离线评估；
- 有后续序列化、线上一致性和业务验证计划。

当前材料**不支持**的说法是：

- 已经线上部署；
- 已经完成线上 A/B；
- 已经实现 CR、取消率或接驾距离业务目标；
- 已经获得线上 P99、QPS、吞吐或业务收益。

面试或简历中应表述为：

> 完成离线对照、消融和架构验证，为后续线上化评估提供模型候选和实验依据。

而不是表述为“模型已上线”或“带来业务提升”。

---

## 14. 面试时如何用这条样本讲全局

### 14.1 30 秒版本

> 以一条当前司乘订单为样本，我们先按照预测时点截取乘客和司机的历史订单，避免未来信息穿越；将每笔历史订单编码成 S-token，将乘客画像、司机画像、当前订单、时空和统计特征编码成 NS-token。OneTrans 在统一 token 序列中通过 causal attention 建模历史依赖和订单—历史交互；EPNet 根据当前场景对底层 embedding 做动态缩放，PPNet 再根据乘客、司机、订单先验为 D、O、OD 三个任务生成不同 hidden gate，最终输出多任务离线预测分数。

### 14.2 2 分钟版本

> 假设当前是早高峰的一笔快车订单，乘客过去有一笔相似的长接驾距离取消订单，司机过去既有相似距离的完成订单，也有取消记录。传统做法会先把司机、乘客序列各自压成一个向量，再和当前订单拼接，模型很难细粒度地比较“当前订单”和“历史哪一笔订单”相似。
>
> 在这个架构中，每个历史订单先编码为事件 token，当前订单、上下文和画像特征也变成 token。EPNet 根据早高峰、产品、区域供需等场景信息，动态调节底层 embedding。之后 OneTrans 让当前 Order token 从司机和乘客历史中读取相关信息，形成联合表示；S-token 共享参数以保证长序列效率，订单、上下文等 NS-token 使用专属参数以保留字段语义。最后 PPNet 针对乘客 D、司机 O 和司乘 OD 任务生成不同的 hidden gate，使不同任务关注不同的有效通道，再由三套 task head 输出预测。
>
> 离线结果中，PEPNet + OneTrans 对乘客任务 D 提升最明显，但当前仍是离线尝试，后续需要验证线上一致性和业务指标映射。

---

## 15. 需要以代码确认的细节

下列内容不能只凭当前材料确定：

- 真实序列字段完整清单；
- token 的精确排列和 causal mask 细则；
- driver/passenger 是否按时间交错；
- 真实 embedding 维度、OneTrans 层数、head 数和参数量；
- EPNet 位于 tokenizer 前还是 token projection 后；
- PPNet 作用于哪些具体层；
- task readout 如何完成；
- loss 权重、负采样、样本权重；
- 训练机器、训练时间、显存和吞吐；
- 是否存在实际线上部署或 A/B。

更稳妥的口径是：

> 架构层面可以明确 OneTrans 负责统一序列—特征建模，EPNet 负责底层 embedding personalization，PPNet 负责上层 task representation personalization；具体特征、张量和调用顺序需要以工程实现为准。

---

## 16. 关联文档

- [[PEPNet-OneTrans-序列建模实验全量记录]]
- [[PEPNet-OneTrans-司乘序列建模架构八股]]
- [[模型架构/序列建模/Onetrans]]
- [PEPNet 论文](https://arxiv.org/abs/2302.01115)
- [OneTrans 论文](https://arxiv.org/abs/2510.26104)

