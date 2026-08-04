---
tags:
  - 自动出价
  - Offline-RL
  - GAVE
  - Decision-Transformer
  - 论文精读
created: 2026-07-28
---
# GAVE：怎样超过历史次优轨迹？

论文：[Generative Auto-Bidding with Value-Guided Explorations](https://arxiv.org/abs/2504.14587)  
PDF：[作者公开版本](https://personal.ntu.edu.sg/boan/papers/SIGIR25_autobidding.pdf)  
代码：[Applied-Machine-Learning-Lab/GAVE](https://github.com/Applied-Machine-Learning-Lab/GAVE)  
会议：SIGIR 2025

> **一句话总结：** GAVE 以 Decision Transformer 为序列 backbone，但不止模仿历史动作。它先把广告主目标写成 score-based RTG，再在日志动作附近构造受限探索，用预测的 RTG 判断探索是否值得学习，并用高 expectile 的 value 估计为探索提供“朝更高价值处走”的方向。


![[Pasted image 20260730151405.png]]

## 第一部分：全景地图

这张图分为四块：上方 **(a)** 是一个时间步内的 GAVE 网络；左下 **(b)** 是训练时怎样从日志取样并计算损失；右下 **(c)** 是论文在竞价模拟器中的离线评估。图中 $\hat{\ }$ 表示模型预测， $\tilde{\ }$ 表示由日志动作局部扰动出来的“探索量”，没有符号的 $r_t,s_t,a_t$ 是日志或环境中真实观察到的量。

### 0. 先明确：图中的自动出价问题是什么？

对每个曝光机会 $i$，广告主给出出价 $b_i$；若高于其他广告主最高出价 $b_i^-$，则赢得曝光，记为 $x_i=1$。赢得后会付出成本 $c_i$，并获得私有价值 $v_i$（如预估转化价值）。论文将目标写为：

$$
\max \sum_i x_i v_i,
\quad \text{s.t.}\quad \sum_i x_i c_i \le B,
\quad \frac{\sum_i x_i c_i}{\sum_i x_i v_i}\le C.
$$

$B$ 是预算，$C$ 是 CPA 目标。CPA（Cost Per Action）是每次有效行为成本：

$$
\mathrm{CPA}=\frac{\text{广告总花费}}{\text{有效行为次数}}.
$$

例如花费 1,000 元得到 10 个下单，CPA 为 100 元/单。自动出价不是一味压低 CPA：完全不出价也可能 CPA 很低，却没有转化；目标是**在预算内尽量取得有效行为，同时控制 CPA**。论文不让模型直接为每次曝光输出任意价格，而用参数化出价：

$$
b_{t,n}=\lambda_t v_{t,n}.
$$

其中 $v_{t,n}$ 是下游价值模型在窗口 $t$ 对第 $n$ 次曝光给出的基础价值，$\lambda_t$ 是窗口级 bid coefficient。因此 Figure 1 的动作 $a_t$ 就是 $\lambda_t$。

预算可由平台即时限制；而完整 CPA 往往到整个周期结束才可确认。正因如此，GAVE 将 CPA 写入 score/RTG 的优化偏好，但并不声称仅靠网络即可为每个窗口给出硬可行性保证。

### 0.1 先有 DT，GAVE 为什么还要多做一步？

Decision Transformer（DT）把离线强化学习轨迹写成交错序列：

$$
(r_1,s_1,a_1,r_2,s_2,a_2,\ldots,r_T,s_T,a_T),
$$

再以 causal Transformer 建模条件分布：

$$
p_{\mathrm{data}}(a_t\mid r_{\le t},s_{\le t},a_{<t}).
$$

给定历史与“希望剩余获得多少回报”的 RTG，DT 从高回报日志中学习下一动作。它能利用长时序，但仍受历史行为策略覆盖范围限制：若历史里最好的轨迹仍是次优，直接模仿高分行为难以继续改进；直接大幅偏离日志又会进入 OOD 区域，反事实预测不可靠。

GAVE 保留这套 token + causal Transformer backbone，并补上四件事：用业务 score 构造 RTG、在日志动作附近用 $\hat\beta_t$ 局部探索、比较两种动作后的预测 RTG、用高 expectile value 把探索锚向较高且相对可信的价值区域。Figure 1 的其余部分就是这四件事如何连成一条训练链路。

### 1. 最下方的输入 token：$r_t,s_t,a_t$

图中蓝、绿、黄三个圆分别是：

- $r_t$（蓝）：时刻 $t$ 的 RTG，即从现在到投放结束希望/能够取得的剩余业务回报；GAVE 由兼顾价值和 CPA 的 score 构造它；
- $s_t$（绿）：时刻 $t$ 的状态，例如剩余预算、当前 CPA、剩余时间、流量和成本速度、历史出价统计；
- $a_t$（黄）：日志策略在该窗口实际使用的动作，即 bid coefficient $\lambda_t$。

一段样本按时间交错排列为：

$$
(r_{t-M},s_{t-M},a_{t-M},\ldots,r_t,s_t,a_t).
$$

论文图中只标注了 token embedding 与 position encoding；公开参考实现将各 token embedding 与 time embedding **拼接后再经线性层映射**为最终 token，并非标准 Transformer 中简单的逐元素相加。无论采用何种融合形式，causal mask 都使当前位置只看得到左侧历史，不能偷看未来窗口。

#### $s_t$ 怎样输入模型？

$s_t$ 不是把“预算、CPA、流量、城市、活动类型”等字段逐个当作一长串 Transformer token。GAVE 公开实现采用的形式是：**先把同一决策窗口内已经可知的字段整理为一个状态向量，再将这个向量映射为一个 state token。**

例如以 30 分钟为一个投放窗口，可以构造：

$$
s_t=[
\text{剩余预算比例},\ \text{已花预算比例},\ \text{当前 CPA/目标 CPA},\ \text{剩余时间比例},\ \text{当前流量预测},\ \text{近期成本速度},\ \text{近期转化速度},\ \text{近期平均出价系数},\ldots]
\in\mathbb R^{d_s}.
$$

论文实验中的 state dimension 是 16，因此一个 batch 的状态张量可写成：

$$
\text{states}\in\mathbb R^{B\times L\times16},
$$

其中 $B$ 是 batch size，$L$ 是历史窗口长度。也就是说，**每个时间步是一个 16 维快照；Transformer 建模的是这些快照随时间的变化。**

公开参考实现先对数值状态做均值方差归一化，再用线性层将整个状态向量投影到 hidden size：

$$
e_t^s=W_s\,\mathrm{Norm}(s_t)+b_s.
$$

随后将时间 embedding 与 $e_t^s$ 拼接、再映射为最终 state token；最终才与 $r_t$、$a_t$ 的 token 交错为 $[r_1,s_1,a_1,\ldots,r_t,s_t,a_t]$。因此，图中的绿色 $s_t$ 圆圈并不只代表一个原始字段，而是“当前窗口所有状态信息融合后的向量”。

构造 $s_t$ 时最重要的是**无信息泄漏**：只能使用决策时刻 $t$ 已知的信息。例如当前预算、已发生成本和可提前获得的流量预测可以使用；$t+1$ 窗口结束后才知道的真实转化、实际成本不能提前放入 $s_t$。

#### 特征从哪里计算而来

论文离线实验说明状态维度为 16；公开参考实现可直接确认它接收一个数值状态张量、以训练集均值和标准差归一化、再映射为 state token。论文在线实验列出的状态信息包括预算、CPA limit、预测值、流量/成本速度、分时预算、剩余时间和窗口平均 bid coefficient。

其余量在论文中的角色是：$a_t$ 是窗口级 bid coefficient；$v_{t,n}$ 是第 $t$ 个窗口第 $n$ 次曝光的私有价值，实际出价写为 $b_{t,n}=a_t v_{t,n}$；$x_{t,n}$ 与 $c_{t,n}$ 分别表示赢标指示和成本，用于累计价值、成本与 score；$r_t$ 是由 score-based RTG 构造出的条件 token。

#### 从一段真实日志走到四个 head

下面的数字只用于解释数据流，并非论文披露的某一条真实轨迹。假设一个广告主以 **30 分钟** 为一个决策窗口；现在是第 $t$ 个窗口，要决定此刻的 bid coefficient。我们截取最近两个完整窗口和当前窗口：

| 时间步 | RTG $r$ | 已知状态 $s$（只列部分字段） | 日志中的动作 $a$ |
|---|---:|---|---:|
| $t-2$ | 0.42 | 剩余预算 75%、CPA/目标 CPA=0.90、剩余时间 30%、成本速度正常 | 0.92 |
| $t-1$ | 0.37 | 剩余预算 66%、CPA/目标 CPA=0.96、剩余时间 20%、成本速度上升 | 0.98 |
| $t$ | 0.31 | 剩余预算 55%、CPA/目标 CPA=0.93、剩余时间 10%、流量预测较高 | 训练时日志有 1.00；线上尚未决定 |

为了送入模型，每个 $s_i$ 还会带有其余状态字段，组合成例如 16 维向量：

$$
s_t=[0.55,\ 0.93,\ 0.10,\ \text{成本速度},\ \text{流量预测},\ \text{近期转化速度},\ldots]\in\mathbb R^{16}.
$$

三个字段类型各自先投影到相同的 hidden size $d$，并与相同时间步的时间 embedding 融合：

$$
r_i\longrightarrow z_i^r\in\mathbb R^d,\qquad
s_i\longrightarrow z_i^s\in\mathbb R^d,\qquad
a_i\longrightarrow z_i^a\in\mathbb R^d.
$$

因此，**线上要预测动作时**的输入不是一堆原始标量，而是下面这串已经向量化的 token：

$$
[z^r_{t-2},z^s_{t-2},z^a_{t-2},z^r_{t-1},z^s_{t-1},z^a_{t-1},z^r_t,z^s_t].
$$

当前 $a_t$ 故意不放进来。对最后一个 $s_t$ token，causal mask 允许它读到左侧全部 token，却禁止它读取右侧未来：

~~~text
可见： r(t-2), s(t-2), a(t-2), r(t-1), s(t-1), a(t-1), r(t), s(t)
不可见：a(t), r(t+1), s(t+1), a(t+1), ...
~~~

每一层 Transformer 都让 $s_t$ 的 query 与它可见的历史 token 的 key/value 做 attention；经过多层 attention、残差连接与 FFN 后，最后一层在 $s_t$ 位置输出：

$$
h_t^s=
H_\theta(r_{t-2},s_{t-2},a_{t-2},r_{t-1},s_{t-1},a_{t-1},r_t,s_t)_{s_t}
\in\mathbb R^d.
$$

这就是所谓的 **current state token hidden state**：它不是额外采集的特征，而是当前 state token 在看完历史后形成的上下文表示。若 hidden size 为 128，$h_t^s$ 就是一个 128 维向量；它把“预算还剩多少、CPA 是否健康、过去动作怎样影响 RTG、现在还剩多少时间”等信息压缩在一起。

同一个 $h_t^s$ 接出三个 head：

$$
\hat a_t=\mathrm{Head}_a(h_t^s),\qquad
\hat\beta_t=\operatorname{Sigmoid}(\mathrm{FC}_\beta(h_t^s))+0.5,\qquad
\hat V_{t+1}=\mathrm{Head}_V(h_t^s).
$$

例如模型可能输出 $\hat a_t=1.07$、$\hat\beta_t=1.12$、$\hat V_{t+1}=0.32$。线上直接执行的候选动作是 $\hat a_t=1.07$；而训练时用日志锚点动作 $a_t=1.00$ 额外构造：

$$
\tilde a_t=1.12\times1.00=1.12.
$$

随后出现两次只差末尾动作的前向计算。用日志动作 $a_t=1.00$ 补全序列，读取 **action token** 的 hidden state 并经 RTG head 得到 $\hat r_{t+1}$；把同一个位置替换成探索动作 $\tilde a_t=1.12$，再次前向得到 $\tilde r_{t+1}$。例如：

$$
\hat r_{t+1}=0.300,\qquad \tilde r_{t+1}=0.304.
$$

这样，模型既能通过 $w_t$ 判断“1.12 是否相对 1.00 更好”，又能通过 $L_v$ 将探索后的预测 RTG 拉向 $\hat V_{t+1}=0.32$ 这个高价值锚点。其关键梯度链为：

$$
h_t^s\longrightarrow\hat\beta_t\longrightarrow\tilde a_t
\longrightarrow\tilde r_{t+1}\longrightarrow L_v.
$$

~~~mermaid
flowchart LR
    A["历史原始字段<br/>r, s, a"] --> B["字段投影与时间编码<br/>得到 r/s/a token"]
    B --> C["Causal Transformer<br/>当前 s_t 只看历史"]
    C --> H["s_t 位置的最终隐状态 h_t^s"]
    H --> AH["动作 head → â_t<br/>线上动作"]
    H --> BH["β head → β̂_t"]
    H --> VH["Value head → V̂_(t+1)"]
    BH --> E["β̂_t × 日志 a_t"]
    E --> F["探索动作 ã_t"]
    F --> G["替换末尾 action token<br/>第二次前向"]
    G --> RH["RTG head → r̃_(t+1)"]
    VH --> LV["L_v：高价值锚点"]
    RH --> LV
~~~

> **把两个位置分清：** 动作、$\beta$、value 这三个 head 都从当前 **state token** 的 $h_t^s$ 读出；只有“给定一个动作以后，下一步 RTG 怎样”才从补上 $a_t$ 或 $\tilde a_t$ 后的 **action token** 表示读出。这是 Figure 1 中 decoder 位置错开的原因。

### 2. 上半部分 (a)：同一个 Transformer 如何得到四类输出？

Transformer 产生每个 token 位置的隐藏表示，之后接不同线性 decoder（图中的灰/黄/蓝矩形）。图中采用 DT 常见的“错位预测”：

| 图中输出 | 从哪个时间点的历史表示读出 | 表示什么 | 后续用途 |
|---|---|---|---|
| $\hat a_t$ | 看到 $r_t,s_t$ 后 | 对当前出价系数的预测 | 正常动作头；线上最终使用的核心动作。 |
| $\hat V_{t+1}$ | 看到 $r_t,s_t$ 后 | 下一步可达到的高价值 RTG 锚点 | 用 expectile loss 学习，指导探索方向。 |
| $\hat\beta_t$ | 看到 $r_t,s_t$ 后的 **state token 隐状态** | 对日志动作做局部缩放的倍率 | 与 $a_t$ 相乘，构造探索动作。 |
| $\hat r_{t+1}$ | 给定到 $a_t$ 为止的历史后 | 若采取日志动作时，对下一步 RTG 的预测 | 与探索动作的 RTG 预测比较。 |

图中 $\hat\beta_t$ 不是直接替代线上 bid 的“另一个动作”。它服务于训练期的局部探索。因为训练日志里已知 $a_t$，模型可以围绕这个被数据支持的动作尝试小幅偏移；而线上真正转成出价系数的主要是动作头 $\hat a_t$。

### 3. 图右上 (a.1)：为什么有 $S_1,S_2,S_3$ 和 score-based RTG？

右上角先定义业务 score。例如：

$$
S_1=\sum_i x_iv_i,
\qquad
S_2=\min\left\{\left(\frac{C}{\mathrm{CPA}}\right)^2,1\right\}\sum_i x_iv_i,
$$

$$
S_3=\min\left\{\left(\frac{C}{\mathrm{CPA}}\right)^5,1\right\}\sum_i x_iv_i.
$$

$x_i$ 表示是否赢得曝光，$v_i$ 是该曝光的价值，$C$ 是目标 CPA。$S_1$ 只看价值；$S_2,S_3$ 在 CPA 超目标时施加不同强度的惩罚。论文用它们说明：RTG 应来自和业务评估一致的 score，而不是机械地只累计转化。选定某个 score 后，整段轨迹的未来 score 被转换为每个时刻的 $r_t$ token。

#### $S_1,S_2,S_3$ 不是模型自动挑选的三个分数

它们是论文用来展示 score-based RTG 的三个例子，不是模型输出。论文主实验采用 $S_2$（惩罚指数为 2），并在 Table 3 中交叉比较三种 score 构造 RTG、三种 score 评估的结果；其报告的现象是，对角线（RTG score 与评估 score 一致）通常最好。论文没有给出一个跨业务通用的 score 选择规则。
![[Pasted image 20260803170957.png]]

只把转化或累计价值当 reward 会有一个直接问题：模型可能通过激进抬价买到更多转化，却明显突破 CPA 目标。举例来说，若目标 CPA 为 100：

| 轨迹 | 累计价值 | CPA | $S_2$（$\gamma=2$） |
|---|---:|---:|---:|
| A：稳健 | 120 | 100 | 120 |
| B：猛冲 | 150 | 150 | $150\times(100/150)^2\approx66.7$ |

因此 B 虽有更多裸价值，却不是更好的业务轨迹。论文将每个时刻的 score 写为 $S_t$，并用：

$$
r_t=S_T-S_{t-1}
$$

构造 RTG。这样 $r_t$ 表示从当前时刻起，在 CPA 目标下还可能贡献多少有效业务价值；训练中“高 RTG”的含义便与评估时的高 score 对齐。这是目标对齐，不是保证每一时刻 CPA 都绝不越界的硬约束。

#### 训练时的 RTG 怎样从整段日志回填，线上又怎样得到它？

先记第 $t$ 个窗口结束为止的累计业务 score 为 $S_t$。训练数据拥有一整天已经结束的轨迹，因此可以在**离线回看**时先得到终局 score $S_T$，再对每个决策点回填：

$$
r_t=S_T-S_{t-1}.
$$

例如一天有三个窗口，按论文选定的 CPA-价值 score 计算得到：

| 窗口结束时刻     | 累计 score $S_t$ | 从该时刻后仍可争取的 RTG |
| ---------- | -------------: | -------------: |
| $S_0$（开始前） |              0 |  $r_1=S_3-S_0$ |
| $S_1$      |             40 |  $r_2=S_3-S_1$ |
| $S_2$      |             70 |  $r_3=S_3-S_2$ |
| $S_3$（结束）  |            100 |              0 |

因此，训练样本中的 $r_t$ 的确利用了未来结果，但这不是泄漏到线上：它是离线日志已经结束后制作的 **监督/条件序列**。类似语言模型可在训练时看到完整句子，在线生成时却只能看到前缀。

线上时刻 $t$ 并没有未来的 $S_T$，所以不能直接使用训练中的回填式。论文披露的线上设置是：由于真实转化稀疏，训练时以赢得流量的预期总转化构造 RTG；推理时将整段 RTG 设为该 campaign 前一天的预期总转化。

公开 AuctionNet 参考代码还可确认一种仿真时的条件更新：第一步令 `eval_curr_score = target_return`；后续步计算

$$
\mathrm{curr\_score}
=\mathrm{target\_return}
-\frac{\mathrm{getScore}(\mathrm{budget},\mathrm{cpa},\mathrm{state},\mathrm{pred\_all\_reward})}{\mathrm{scale}},
$$

并把该值追加到 return 序列。代码没有把这段仿真逻辑表述为一个通用的线上 RTG 更新定理；论文正文也没有给出额外的逐窗口 planner。

### 4. 图橙色虚线框 (a.2)：当前 state token 怎样接出 $\beta$ head？

这一块应拆成两步看。**$\beta$ 的信息来源是当前状态；日志动作只是它随后要缩放的对象。** 对时间步 $t$，送入 causal Transformer 的有效上下文是：

$$
[r_{t-M},s_{t-M},a_{t-M},\ldots,a_{t-1},r_t,s_t].
$$

这里没有当前动作 $a_t$。因果掩码保证 state token 只能汇总过去的 RTG、状态和动作，以及当前已经观察到的 $r_t,s_t$；因此它是在“看完当前环境以后、动作尚未决定以前”形成表示。记最后一层中 $s_t$ 位置的隐状态为：

$$
h^s_t=H_\theta(r_{t-M},s_{t-M},a_{t-M},\ldots,a_{t-1},r_t,s_t)_{s_t}.
$$

然后接一个专门的 $\beta$ head：

$$
u^\beta_t=\mathrm{FC}_\beta(h^s_t),
\qquad
\hat\beta_t=\operatorname{Sigmoid}(u^\beta_t)+0.5.
$$

所以 $\hat\beta_t\in(0.5,1.5)$。论文用 $\mathrm{FC}_\beta$ 概括该 head；作者公开参考实现把它实现为一个小 MLP：hidden state $\rightarrow$ 16 维线性层 $\rightarrow$ GELU $\rightarrow$ 8 维线性层 $\rightarrow$ GELU $\rightarrow$ 1 维线性层 $\rightarrow$ sigmoid，最后在网络外加 $0.5$。这一层数和宽度是实现选择，核心结构是“**state-token hidden state $\rightarrow$ 标量倍率**”，并非给 $\beta$ 单独输入一张原始特征表。

得到倍率后，训练时才取日志中已经记录的动作 $a_t$，构造附近的探索动作：

$$
\tilde a_t=\hat\beta_t a_t.
$$

例如当前 state token 已编码“剩余预算充足、CPA 低于目标、剩余时段不多”。$\beta$ head 输出 $u^\beta_t=0.49$，则 $\operatorname{Sigmoid}(0.49)\approx0.62$，$\hat\beta_t\approx1.12$。若日志动作是 $a_t=1.00$，便得到 $\tilde a_t=1.12$。反之，若状态显示 CPA 已偏高，head 可输出更小的倍率，例如 $\hat\beta_t=0.78$，将 $a_t=1.00$ 变成更保守的 $0.78$。

这里的因果方向很重要：

$$
(r_{<t},s_{<t},a_{<t},r_t,s_t)
\longrightarrow h^s_t
\longrightarrow\hat\beta_t
\mathop{\longrightarrow}^{\times a_t}\tilde a_t.
$$

$a_t$ 是离线日志中的**锚点动作**，不是 $\beta$ head 的输入。这样做的目的不是让模型凭空提出任意新动作，而是根据当前状态决定“应在这个数据支持的旧动作附近上调还是下调、调多少”。因此 $\beta$ 也不是 Mixture-of-Experts 那种在多个专家之间分配权重的 gate；它是一个有范围限制的、乘在单个日志动作上的局部扰动倍率。

#### 4.1 $\beta$ 没有直接标签，它靠哪条梯度学会“调多少”？

$\beta$ 没有“正确倍率”的人工标签。一次训练中，它先产生 $\tilde a_t$；模型再把末尾动作替换为 $\tilde a_t$ 做第二次前向计算，得到探索后的预测 RTG $\tilde r_{t+1}$。value 头从同一个 $h^s_t$ 读出高价值锚点 $\hat V_{t+1}$，于是最直接训练探索倍率的路径是：

$$
h^s_t
\longrightarrow \hat\beta_t
\longrightarrow \tilde a_t
\longrightarrow \tilde r_{t+1}
\longrightarrow L_v
=\bigl(\tilde r_{t+1}-\operatorname{stopgrad}(\hat V_{t+1})\bigr)^2.
$$

因为 $\hat V_{t+1}$ 在 $L_v$ 中 stop-gradient，优化器不能简单调低 value 头来减小误差；梯度会沿 $\tilde r_{t+1}\rightarrow\tilde a_t\rightarrow\hat\beta_t$ 回传，促使 $\beta$ 在受限区间内产生更接近该状态高价值锚点的扰动。若 $\alpha_4$ 是总损失中 $L_v$ 的权重，则该项梯度会再按 $\alpha_4$ 缩放。

四个损失对 $\beta$ 的角色也不同：

| 损失 | 是否给 $\beta$ head 提供主要直接训练信号 | 原因 |
|---|---|---|
| $L_r$ | 否 | 它用日志动作 $a_t$ 监督 $\hat r_{t+1}$，首先校准正常 RTG 预测。 |
| $L_a$ | 否（$\tilde a_t,w_t$ 均 stop-gradient） | 它训练主动作头 $\hat a_t$；detach 防止 $\beta$ 通过改“伪标签”或权重而投机减小动作误差。 |
| $L_e$ | 否 | 它训练 value head 形成高 expectile 的 $\hat V_{t+1}$ 锚点。 |
| $L_v$ | **是，设计上最直接的一条** | 它通过探索动作后的 RTG 预测，反传到 $\beta$ head。 |

共享 Transformer 参数仍可能同时收到多项损失的梯度；表中说的是 $\beta$ 这一探索头的**显式、直接**学习路径。这个拆分也解释了为何要 stop-gradient：没有 detach 时，$\beta$、$w_t$、value head 都可能通过彼此改变辅助目标来降低 loss，却不必学到可靠的探索方向。

#### 4.2 训练时有 $\beta$，为什么线上最终动作仍是 $\hat a_t$？

$\tilde a_t$ 的定义依赖历史日志动作 $a_t$，它是离线训练时用于构造“日志动作附近候选点”的工具。真实线上在时刻 $t$ 没有一条可供乘法的“本次日志动作”，所以 GAVE 的执行动作由看到 $r_t,s_t$ 的动作 head 输出 $\hat a_t$。因此，$\beta$ 在论文中服务于离线的 value-guided exploration 训练，而不是线上额外乘一次的动作 head。

### 5. 图左下 (b.1)：比较 $\tilde r_{t+1}$ 与 $\hat r_{t+1}$，生成权重 $w_t$

训练时拿同一段历史喂两次模型：一次接真实日志动作 $a_t$，得到 $\hat r_{t+1}$；一次把末尾动作换成探索动作 $\tilde a_t$，得到 $\tilde r_{t+1}$。二者的差经 sigmoid 变成：

$$
w_t=\mathrm{Sigmoid}\big(\alpha_r(\tilde r_{t+1}-\hat r_{t+1})\big).
$$

> **参数标注：** $\alpha_r$ 是人为设定的超参数，用于控制 sigmoid 对 RTG 差异的敏感程度，并非模型预测的量，也不同于总损失中的 $\alpha_1,\ldots,\alpha_4$。论文正文给出其作用但未单列具体数值；作者公开参考实现使用 $\alpha_r=100$，即 `sigmoid(100 * (curr_score_preds_1 - curr_score_preds))`。

若 $\tilde r_{t+1}>\hat r_{t+1}$，则 $w_t$ 偏大，说明模型认为这次局部上调更值得学习；反之，$w_t$ 偏小，动作头仍主要遵循日志动作。这个权重不是硬阈值，而是平滑地在“模仿原动作”和“向探索动作靠近”之间切换。

这个比较最终通过动作损失落实到动作头：

$$
L_a=\frac1N\sum_t\left[(1-w_t')(\hat a_t-a_t)^2+w_t'(\hat a_t-\tilde a_t')^2\right].
$$

上标 $'$ 表示 stop-gradient。也就是说，$L_a$ 只训练动作头在“靠近日志动作”和“靠近探索动作”之间做平滑选择，而不能让模型通过改动权重 $w_t$ 或探索标签 $\tilde a_t$ 来投机降低损失。这里的 exploration 是训练期在固定日志上构造的局部动作扰动。

### 6. 图中 (a.3) 与左下 (b.2)：$\hat V_{t+1}$ 为什么要出现？

先把这一块和上一节的 $w_t$ 区分开：$w_t$ 只做**两两比较**，它回答“探索动作相对日志动作是否更好”；$\hat V_{t+1}$ 则提供一个**绝对的高价值参照**，它回答“当前这类状态下，日志里较好的未来 RTG 大致应在什么水平”。

#### 6.1 只有 $w_t$ 时，问题在哪里？

假设当前状态是“预算还很充足、CPA 也未超标”。原动作 $a_t=1.00$，探索动作 $\tilde a_t=1.12$。模型预测：

$$
\hat r_{t+1}=0.300,\qquad \tilde r_{t+1}=0.304.
$$

因为 $0.304>0.300$，$w_t$ 会偏向探索动作，于是动作头会被鼓励从 1.00 向 1.12 靠近。这件事本身没有错，但它只说明：**在模型自己的预测里，1.12 比 1.00 好一点。**

离线学习的风险是，1.12 不是日志真实执行过的动作，$0.304$ 也不是观测到的真实反事实回报，而是模型预测。若模型在数据很少覆盖的区域产生偶然偏高的估计，比如把 1.35 错估成 0.315，单靠“谁更大”就可能不断把动作推向更远的 OOD 区域。这里的 OOD 可以简单理解为：**训练日志几乎没有相似动作和相似状态，模型没有足够事实依据却在外推。**

所以，$w_t$ 像“1.12 比 1.00 高不高”的局部裁判；它不能单独保证“这个改动是否朝一个可信的好区域走”。

#### 6.2 $\hat V_{t+1}$ 是什么：不是实际标签，而是高分锚点

论文概念上希望学习：

$$
V_{t+1}\approx\max_{a_t\in\mathcal A}r_{t+1}.
$$

意思是：在当前历史/状态下，如果可选动作里存在较优动作，它未来 RTG 大致能达到什么高水平。离线数据只记录了少数历史动作，无法真的遍历全部动作空间找最大值，所以论文不把 $V$ 当成已知标签，而是从 $s_t$ 对应的 Transformer 隐表示预测 $\hat V_{t+1}$。

这个 $\hat V_{t+1}$ 也不是“保证可达到的真实最优值”，更准确的理解是：**从已有日志里学习出的、偏向高回报侧的价值参照点。** 它的作用像一个锚，而不是 oracle。

#### 6.3 为什么用 expectile，而不用均方误差？

若用普通 MSE 回归 future RTG，模型会学到平均水平。假设相似状态下，日志里可观察到的下一步 RTG 是：

$$
0.20,\ 0.24,\ 0.27,\ 0.30.
$$

平均值是 0.2525。它适合回答“通常会怎样”，但不能回答“在这个状态下较好的表现处于哪里”。GAVE 希望探索超过旧策略，因此更需要后一个参照。

expectile loss 会对预测值下方和上方的误差赋不同权重。论文设 $\tau=0.99$：当高回报样本被低估时，惩罚更大，训练后的 $\hat V_{t+1}$ 会更靠近分布上侧，例如更接近 0.30 而不是 0.2525。它与分位数不完全相同，但可先把它直观理解为“由高分样本主导的平滑上界估计”。

$$
L_e=\frac1N\sum_t L^2_\tau(r_{t+1}-\hat V_{t+1}),\qquad \tau=0.99.
$$

#### 6.4 $L_v$ 到底怎样影响探索？

有了 value 锚点后，论文定义：

$$
L_v=\frac1N\sum_t(\tilde r_{t+1}-\hat V'_{t+1})^2.
$$

上标 $'$ 表示在计算这个损失时，$\hat V_{t+1}$ 被 stop-gradient（冻结梯度）。因此优化 $L_v$ 时，模型不能简单把 value 头从 0.32 改小到 0.304 来“假装匹配”；梯度会推动产生 $\tilde r_{t+1}$ 的探索路径改变，也就是通过探索倍率、共享表示和 RTG 预测相关参数，让探索动作更接近高价值区域。

继续上面的数值例子：

| 量 | 数值 | 含义 |
|---|---:|---|
| 原动作预测 $\hat r_{t+1}$ | 0.300 | 采用日志动作后的预期未来分数。 |
| 探索动作预测 $\tilde r_{t+1}$ | 0.304 | 1.12 倍动作比原动作略好。 |
| 高 expectile value $\hat V_{t+1}$ | 0.320 | 同类历史状态下，较高且有日志支撑的分数锚点。 |

此时 $w_t$ 会说：“0.304 比 0.300 好，可以给探索动作一点学习权重。”而 $L_v$ 会说：“0.304 虽有进步，但距离 0.320 的高价值区域还有距离；继续在局部、受限的动作范围内寻找能靠近该区域的方向。”它们一起工作，而不是互相替代。

注意，$L_v$ **不等于** 强迫所有探索预测都达到一个虚构的最高分。它同时受到三层限制：$\hat V$ 来自日志中的高回报侧、$\tilde a_t$ 受 $0.5$–$1.5$ 倍率限制、原始 RTG 预测受 $L_r$ 的日志监督约束。因此更准确的说法是“受价值锚点引导的受控外推”，而非“模型自由把预测分数抬高”。


#### 6.5 最后用一句话分清二者

> $w_t$ 是**相对比较器**：探索动作比原动作好不好；$\hat V_{t+1}$ 是**高分导航锚点**：这个探索方向是否仍朝向日志中相对可信的高价值区域。二者再配合 $\beta$ 的局部限幅和 stop-gradient，才构成 GAVE 的 value-guided exploration。

### 7. 图下方 (b)：四项训练信号如何汇合？

数据集提供长度 $M+1$ 的输入序列，真实的 $a_t,r_{t+1}$ 是主要标签。图中的四类损失对应：

- $L_r$：令 $\hat r_{t+1}$ 拟合日志的 $r_{t+1}$；
- $L_a$：用 $w_t$ 加权，使 $\hat a_t$ 在 $a_t$ 与 $\tilde a_t$ 之间选择更合适的学习目标；
- $L_e$：用 expectile loss 训练 $\hat V_{t+1}$；
- $L_v$：让探索后的 $\tilde r_{t+1}$ 靠近冻结的高价值锚点 $\hat V_{t+1}$。

它们加权为总损失 $L_o=\alpha_1L_r+\alpha_2L_a+\alpha_3L_e+\alpha_4L_v$。所以 GAVE 不是让生成式模型无监督地产生一条“看起来好”的轨迹，而是用日志标签、局部反事实比较和 value 锚点共同训练。

#### 把 Figure 1(b) 落成一次可检查的训练计算

令一个 batch 的窗口数为 $L=M+1$，公开实现中的状态维度为 $d_s=16$，hidden size 为 $d$。最核心的输入张量是：

| 张量 | 典型形状 | 来源 | 对当前动作头是否可见 |
|---|---|---|---|
| `states` | $B\times L\times d_s$ | 窗口级状态快照 | 当前 $s_t$ 可见；未来状态不可见。 |
| `actions` | $B\times L\times d_a$ | 日志中的窗口级 $\lambda$；通常 $d_a=1$ | 历史 $a_{<t}$ 可见；当前 $a_t$ 不给动作头看。 |
| `returns` | $B\times L\times1$ | 由完整训练轨迹回填的 score-based RTG | 当前 $r_t$ 是条件；未来 RTG 不可见。 |
| `timesteps/mask` | $B\times L$ | 窗口编号与 padding 信息 | 提供时间语义并屏蔽补齐位置。 |

先留空当前动作，形成决策上下文：

$$
X_t^{\mathrm{state}}=[r_{t-M},s_{t-M},a_{t-M},\ldots,a_{t-1},r_t,s_t].
$$

从 $s_t$ 位置读取 $h_t^s$，得到 $\hat a_t,\hat\beta_t,\hat V_{t+1}$；再补上日志锚点动作与探索动作，形成两条末尾不同的分支：

$$
X_t^a=[X_t^{\mathrm{state}},a_t],\qquad
X_t^{\tilde a}=[X_t^{\mathrm{state}},\tilde a_t],\qquad
\tilde a_t=\hat\beta_ta_t.
$$

它们各自从最后一个 action token 经过同一个 RTG decoder，得到：

$$
\hat r_{t+1}=\mathrm{Head}_r(H_\theta(X_t^a)_{a_t}),\qquad
\tilde r_{t+1}=\mathrm{Head}_r(H_\theta(X_t^{\tilde a})_{\tilde a_t}).
$$

最后计算四项损失、加权并做一次 backward。各项梯度职责如下：

| 损失 | 主要训练对象 | 对共享 Transformer 的作用 | 刻意阻断的捷径 |
|---|---|---|---|
| $L_r$ | RTG head | 校准日志动作后的 RTG 表征 | 不由探索伪标签直接监督。 |
| $L_a$ | 动作 head | 让状态表征支持动作预测 | $w_t,\tilde a_t$ detach，不能篡改权重或伪标签。 |
| $L_e$ | value head | 学到高 expectile 的 value 表征 | 不把 value 当成动作标签。 |
| $L_v$ | $\beta$ head、RTG head | 让探索分支靠近冻结的高价值锚点 | $\hat V_{t+1}$ detach，不能只移动锚点。 |

这也把 Figure 1 的反传方向说完整：$L_v$ 的关键路径是 $\tilde r_{t+1}\rightarrow\tilde a_t\rightarrow\hat\beta_t\rightarrow h_t^s$；而 $L_a$ 只将已经 detach 的探索结论当作动作头的软监督。

### 8. 图右下 (c)：评估与实际出价闭环

Figure 1(c) 是论文的离线评估闭环：模型输入上一动作 $a_{t-1}$、当前 RTG $r_t$ 与状态 $s_t$，输出 $\hat a_t$。该动作进入 auction / bidding simulation，并和其他广告主的动作共同决定曝光、价值、成本和环境转移；环境返回下一状态 $s_{t+1}$，再进入下一窗口。

论文的线上实验还明确采用前两小时历史窗口的动作平滑。设 $a_t$ 为 GAVE 在当前窗口输出的原始动作、$E$ 为前两小时包含的时间步集合，则实际 bid coefficient 为

$$
\lambda_t=a_t+\frac{1}{|E|}\sum_{t'=t-E}^{t-1}\lambda_{t'}.
$$

论文图中的 (c) 主要用于离线模拟评估，不能把模拟器反馈误认为训练日志天然拥有的真实反事实标签。

#### 公开代码中的仿真推理循环

公开参考代码的 `take_actions` 维护 `states`、`actions`、`rewards`、`curr_score` 与 `timesteps` 序列；每一步截取最近 $K$ 步、为不足 $K$ 的前缀补齐，并调用 `get_action` 获得当前动作。第一步将 `target_return` 作为当前条件；随后按上一节的 `getScore` 表达式重算 `curr_score` 并追加。这里描述的是公开仿真代码的行为，不额外推断为论文定义的生产架构。


## 第二部分：论文实验到底证明了什么？

实验部分要分开读：**离线模拟回答“在统一、可复现的拍卖环境中，方法是否优于比较算法”；线上 A/B 回答“在论文披露的生产场景中，是否观察到业务指标改善”。** 二者的证据强度和可外推范围不同，不能混为一谈。

先把论文的证据链拆成四个问题。这样读表时不会把“模型在模拟器中分数更高”误说成“已经普遍证明线上更优”。

| 论文要回答的问题 | 对应证据 | 可以支持的结论 | 不能直接推出的结论 |
|---|---|---|---|
| RQ1：整体效果是否更好？ | Table 2，AuctionNet / AuctionNet-Sparse 离线模拟 | 在该 benchmark、score 和预算设置下，GAVE 高于列出的 baseline。 | 所有广告场景、所有线上指标都会等比例提升。 |
| RQ2：RTG 与评估 score 对齐是否有用？ | Table 3，不同 $S_1,S_2,S_3$ 的交叉训练/评估 | 已确定业务 score 时，用同一 score 构造 RTG 更合适。 | 某一个固定 CPA 惩罚强度永远最优。 |
| RQ3 / RQ4：探索和值函数是否有贡献？ | Figure 2 的 $w_t$ 动态、Figure 3 的消融 | 完整设计的结果与“score 对齐 → 探索 → value 引导”逐层有效的解释一致。 | 每一个 loss 都已被完全独立、无交互地证明因果有效。 |
| 生产中是否观察到改善？ | Table 4，5 天线上 A/B | 在 Nobid 与 Costcap 两类论文披露场景中，GAVE 相对 IQL 有正向指标变化。 | 已证明长期显著性、跨业务泛化或绝对安全性。 |

### 2.1 离线模拟：比较的对象、环境和指标分别是什么？

论文在 AuctionNet 和 AuctionNet-Sparse 上评估。两个数据集各约有 479,376 条轨迹、9,987 个投放周期；每个周期被离散为 48 个时间步。评估遵循 AuctionNet benchmark 的多智能体竞价模拟：一个 24 小时周期内有 48 个 agent 竞争曝光，测试模型依次替换其中一个 agent，其余 agent 保持固定，最后对 48 轮替换的 score 取平均。

这里的 score 不是裸转化，而是论文的：

$$
S=\min\left\{\left(\frac{C}{\mathrm{CPA}}\right)^2,1\right\}\sum_i x_iv_i.
$$

即在价值基础上施加 CPA 惩罚，且实验固定 $\gamma=2$。这意味着表中的高分应解释为“在该模拟器和该 CPA-价值折中目标下更好”，而不是单独证明转化数、成本或任意业务指标都更好。

将离线评估的因果链写成一句话是：**模型输出窗口级出价系数 $\hat a_t$ → 与固定的其他 47 个 agent 在模拟拍卖中竞争 → 模拟环境根据拍卖结果更新成本、价值和下一状态 → 一个 24 小时周期结束后按 $S_2$ 打分。** 因此 Table 2 测的是“策略在仿真闭环中的累计 score”，不是从静态日志上直接算 AUC，也不是在真实流量上的即时收益。

比较方法包括规则/生成方法 DiffBid、USCB，offline RL 方法 CQL、IQL、BCQ，以及序列方法 DT、CDT、GAS。论文使用不同预算比例（50%、75%、100%、125%、150%）评估，并以 10 次独立运行的平均表现报告结果；表中 `*` 表示相对最佳 baseline 的双侧 t 检验达到 $p<0.05$。

### 2.2 总体结果：GAVE 在什么范围内胜出？

论文的 Table 2 显示：在两个数据集、五个预算比例的 10 个组合中，GAVE 的 score 都高于所列 baseline，并以 GAS 作为每个设置下最强 baseline 时，提升范围如下：

| 数据集 | 预算比例 | GAVE / 最强 baseline | 相对提升 |
|---|---|---:|---:|
| AuctionNet | 50% | 201 / 193 | 4.15% |
| AuctionNet | 100% | 376 / 359 | 4.74% |
| AuctionNet | 150% | 467 / 461 | 1.30% |
| AuctionNet-Sparse | 50% | 19.6 / 18.4 | 6.52% |
| AuctionNet-Sparse | 100% | 37.2 / 36.1 | 3.05% |
| AuctionNet-Sparse | 125% | 42.7 / 40.0 | 6.75% |

完整 10 个设置的提升范围为：AuctionNet 的 **1.30%–4.74%**，AuctionNet-Sparse 的 **1.94%–6.75%**。因此更严谨的结论是：**在论文采用的 AuctionNet 模拟协议、score 定义和预算覆盖范围内，GAVE 稳定优于其列出的比较方法。** 不能把“所有设置均高”直接说成“线上所有场景均会提升同等幅度”。

### 2.3 Score-based RTG 的证据：训练目标与评估目标对齐是否有用？

论文在 AuctionNet-Sparse、100% budget 上额外做了 alignment analysis。训练 RTG 与评估分别采用 $S_1$（仅价值）、$S_2$（CPA 惩罚指数 2）和 $S_3$（CPA 惩罚指数 5）：

| RTG 训练 score \ 评估 score | $S_1$ | $S_2$ | $S_3$ |
|---|---:|---:|---:|
| $S_1$ | **41.4** | 33.0 | 23.6 |
| $S_2$ | 39.9 | **37.2** | 33.3 |
| $S_3$ | 39.1 | 36.8 | **33.5** |

每一列最高值都出现在“训练 RTG 的 score = 评估 score”的对角线上。这支持论文的较窄结论：**若已明确业务评估函数，将同一函数用于构造 RTG 比用不匹配的 RTG 更合适。** 它不证明 $S_2$ 永远优于 $S_1$ 或 $S_3$；选哪一个仍取决于业务对 CPA 的约束强度。

### 2.4 消融：每个设计究竟提供了什么证据？

消融在 100% budget 下比较四种版本：

| 版本 | 保留内容 | 设计目的 |
|---|---|---|
| DT | 纯 DT，RTG 用裸累计价值 | 作为未做 score 对齐、探索、value 引导的基线。 |
| GAVE-VA | score-based RTG | 检验目标对齐本身的影响。 |
| GAVE-V | score-based RTG + action exploration | 检验局部探索及 RTG 比较的影响；移除 value 后用替代探索损失。 |
| GAVE | 上述全部 + learnable value | 检验 value 引导是否在探索上进一步有益。 |

Figure 3 的排序在两个数据集上均为：

$$
\mathrm{GAVE}>\mathrm{GAVE\text{-}V}>\mathrm{GAVE\text{-}VA}>\mathrm{DT}.
$$

这与论文的机制叙事一致：score 对齐带来第一层收益；局部探索带来额外收益；value 引导使探索不只追逐局部 RTG 虚高，从而进一步改善结果。更严谨地说，消融提供的是**与各模块有效性相一致的实证证据**；由于多个损失和共享参数同时改变，它不是对每个机制的独立因果证明。

尤其要注意 **GAVE-V 并不只是“把 value head 删除”**：论文同时以替代损失 $L_w=1-\operatorname{Sigmoid}(\alpha_r(\tilde r_{t+1}-\hat r'_{t+1}))$ 替换 $L_e,L_v$，让探索动作相对原动作的预测 RTG 更高。因此这项消融更准确地比较的是“有 value 锚定的探索”与“无 value 锚定、只提升相对 RTG 的探索”，而非一个完全只改动单变量的实验。

论文还报告训练中平均 $w_t$ 从约 0.5 上升并稳定在 0.5 以上。该现象说明在其模型预测下，探索动作逐渐被赋予更高权重；它是训练动态的佐证，不等同于真实线上探索动作一定更优。

### 2.5 线上 A/B：应怎样读这些业务数字？

论文在两个生产竞价场景与当时线上使用的 IQL 比较：

- **Nobid：** 在日预算内最大化转化；
- **Costcap：** 在 CPA / ROI 限制下最大化转化。

测试持续 5 天；论文称每个 campaign 的 25% 预算和流量被分配给 baseline 与 GAVE。结果为：

| 场景      |  Cost | Conversions | Target cost | CPA valid ratio |
| ------- | ----: | ----------: | ----------: | --------------: |
| Nobid   | +0.8% |       +8.0% |       +3.2% |               — |
| Costcap | +2.0% |       +3.6% |       +2.2% |           +1.9% |

这里 cost 上升并不必然是坏结果：若额外成本带来更多有效转化，且 Costcap 的 CPA 合规比例也提升，说明模型在论文的价值/约束评价下有正向业务收益。论文中 `target cost` 是为不同 campaign 目标做的 value-weighted conversion 指标：Costcap 取 CPA limit 作为 conversion value，Nobid 使用总流量的平均真实 CPA；`CPA valid ratio` 仅针对 Costcap，表示 CPA 未超过限制的 campaign 比例。

线上口径还与离线模拟不同：由于真实转化稀疏，论文训练时使用赢得流量的预期总转化 $\sum_i\mathrm{pcvr}_i$ 构造 RTG；推理时将整段 RTG 设为该 campaign 前一天的预期总转化。这说明线上实验验证的是“以预估转化为 RTG 条件的策略”在生产拍卖中的表现，不能把它与离线 $S_2$ 分数当成同一个指标直接横比。

但这组线上结果披露的时间只有 5 天，正文未给出置信区间、显著性检验、分 campaign 异质性或长期效果。因此更准确的解读是：**论文报告的线上 A/B 与离线结论方向一致，但公开信息不足以判断统计显著性、长期稳定性和跨行业可迁移性。**


---

## 第三部分：论文明确给出的适用边界

1. 论文指出，离线自动出价数据不能与环境交互；若直接探索，动作可能落入历史数据覆盖不足的 OOD 区域。这正是局部倍率探索与 value-guided exploration 要处理的问题。

2. 论文将 value 解释为当前状态下可达到的高 RTG 水平，但离线日志只记录有限历史动作，无法枚举动作空间并直接得到真实最大值。因此它以 expectile loss 学习 $\hat V_{t+1}$，而不是把 value 当作可观测的最优标签。

3. 离线结果来自 AuctionNet 模拟环境；线上结果来自两个竞价场景、持续 5 天的 A/B。
