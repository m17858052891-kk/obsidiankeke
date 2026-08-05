---
tags:
  - 自动出价
  - GRM
  - Constrained-Optimization
  - 论文精读
created: 2026-07-28
---

# GRM：怎样显式、可靠地满足预算与 CPA 约束？

论文：[Constrained Auto-Bidding via Generative Response Modeling](https://arxiv.org/abs/2605.27811)  
会议：KDD 2026

> **一句话总结：** GRM 不直接让神经网络输出出价动作，而是先预测“未来环境会如何响应不同 multiplier”，再用解析控制器对预算和 CPA/ROAS 约束做一维求根，最后取最保守的可行 multiplier。

![[Pasted image 20260730172707.png]]

## 第一部分：全景地图

Figure 1 可以拆成两块：绿色框是 **Generative Response Model**，负责预测未来 horizon 对不同动作的响应；橙色框是 **Min-Pacing Controller**，负责把预测曲线转成满足约束的当前动作。GRM 的关键转向是：**policy 不直接学“该出多少”，而是先学“出多少会发生什么”。**

整体链路可以写成：

$$
\underbrace{(s_{1:t},\alpha_{1:t-1})}_{\text{已知历史}}
\xrightarrow{\text{causal Transformer}}
\underbrace{\left(\widehat I_{t:T},\widehat{\bar C}_{t:T}(\alpha),\widehat{\bar V}_{t:T}(\alpha)\right)}_{\text{未来响应 bundle}}
\xrightarrow{\text{budget / CPA roots}}
\alpha_t
\xrightarrow{b_{t,i}=\alpha_t v_{t,i}}
\text{曝光级 bid}.
$$

一句话读图：**Transformer 预测未来流量、成本曲线和价值曲线；controller 在这些曲线上求预算根和效率根；谁更紧就听谁。**

### 0. 先明确：GRM 解决的自动出价问题是什么？

广告主希望在一个投放周期内最大化转化、GMV 或其他价值，同时满足预算和效率约束。一个典型形式是：

$$
\max \sum_i x_i v_i,
\qquad
\text{s.t.}\quad \sum_i x_i c_i \le B,
\qquad
\frac{\sum_i x_i c_i}{\sum_i x_i v_i}\le \tau.
$$

其中：

- $x_i$：是否赢得第 $i$ 次曝光；
- $v_i$：该曝光带来的价值，例如转化、GMV 或预估收益；
- $c_i$：实际支付成本；
- $B$：预算；
- $\tau$：CPA 上限或类似效率目标。

自动出价的困难不在于单次曝光公式，而在于**当前动作会影响未来预算消耗和效率状态**。如果现在过于激进，后面可能预算不够或 CPA 超标；如果现在过于保守，可能投放结束后预算没花完，价值也没拿到。

### 0.1 为什么不能只用 reward penalty？

很多 RL 或生成式方法会把约束写进 reward：

$$
\text{reward}=\text{value}-\lambda_1\cdot\text{budget violation}-\lambda_2\cdot\text{CPA violation}.
$$

这能让模型“倾向于少违规”，但不能保证每一步动作都位于可行区间。权重 $\lambda_1,\lambda_2$ 也很难跨 campaign、跨预算、跨流量分布稳定复用。

GRM 的设计更像控制系统：

1. 先预测动作与未来结果之间的响应关系；
2. 再把预算和 CPA 写成显式方程；
3. 用求根得到最大可行动作。

所以它的核心不是“又一个 Transformer policy”，而是**神经响应建模 + 解析约束控制**。

### 1. 先分清图中的时间与粒度

| 记号 | 含义 | 容易混淆点 |
|---|---|---|
| $t=1,\ldots,T$ | campaign 被切成的 tick，例如每 30 分钟一个决策窗口。 | 不是每条曝光。 |
| $i$ | tick 内的一次具体曝光机会。 | 最终 bid 是曝光级，但控制动作是 tick 级。 |
| $s_t$ | tick $t$ 决策前可见的状态向量。 | 不是单一字段。 |
| $\alpha_t$ | tick 级 multiplier，也就是 controller 输出的动作。 | 不是最终拍卖价格。 |
| $v_{t,i}$ | 第 $t$ 个 tick 内第 $i$ 次曝光的基础价值。 | GRM 不替代价值预估模型。 |
| $b_{t,i}$ | 最终提交给拍卖系统的曝光级 bid。 | 它由 $\alpha_t v_{t,i}$ 得到。 |
| $k\sim\mathcal U\{t,\ldots,T\}$ | 训练时从未来 horizon 中抽取的监督 tick。 | 不是线上要执行的 tick。 |

论文采用常见的两层出价形式：

$$
b_{t,i}=\alpha_t v_{t,i}.
$$

例如当前 $\alpha_t=1.2$，两个曝光机会的基础价值分别是 5 和 1，则最终 bid 是 6 和 1.2。这样做保留了价值模型对曝光质量的相对排序，同时只让自动出价模块控制整体激进程度。

### 2. 图底部的历史 token：模型到底看到了什么？

图底部是交错的状态和动作历史，例如：

$$
(s_{t-2},a_{t-2},s_{t-1},a_{t-1},s_t).
$$

更完整地说，决策时刻 $t$ 可用的信息可以写成：

$$
H_t=(s_{1:t},\alpha_{1:t-1},I_{1:t-1},\mathrm{Cost}_{<t},\mathrm{Val}_{<t}).
$$

这里 $s_t$ 是一个状态向量，通常包含：

- 当前时间、剩余时间比例；
- 剩余预算比例、已花预算比例；
- 当前 CPA/目标 CPA 或 ROAS 状态；
- 近期流量速度、成本速度、价值速度；
- 过去 multiplier 的统计；
- campaign 或场景上下文。

重要原则是**无信息泄漏**：$s_t$ 只能包含当前 tick 决策前已经知道的信息。未来 tick 的真实成本、真实价值、真实流量不能提前进入状态。

### 2.1 为什么图里看起来有当前 $a_t$？

Figure 1 底部可能画出最右侧动作位置，但线上真正决定 $\alpha_t$ 之前，模型不能把 $\alpha_t$ 当输入。更准确的理解是：

- 训练时，日志中确实有 $\alpha_t$，可用于监督或构造 token；
- 线上时，已知的是 $s_{1:t}$ 与 $\alpha_{1:t-1}$；
- GRM 先预测 response bundle；
- controller 再求出当前 $\alpha_t$。

也就是说，GRM 不是 autoregressive 地“先偷偷看当前动作再预测当前动作”，而是根据历史状态动作序列形成当前响应预测。

### 2.2 Causal Transformer 在这里的角色

Causal Transformer 把历史压缩成当前表征：

$$
h_t=f_\theta(s_{1:t},\alpha_{1:t-1}).
$$

它要学习的问题不是“复制历史动作”，而是“在这样的历史状态与动作演化之后，未来剩余 horizon 对 multiplier 会怎样响应”。

这和 Decision Transformer 的差别很大：DT 的输出通常是动作；GRM 的输出是**环境响应函数的参数**。

### 3. 三个黄色输出框：response bundle 是什么？

GRM 输出三个对象：

$$
\widehat{\mathcal R}_{t:T}
=
\left(
\widehat I_{t:T},
\widehat{\bar C}_{t:T}(\alpha),
\widehat{\bar V}_{t:T}(\alpha)
\right).
$$

| 输出 | 中文解释 | 为什么需要它 |
|---|---|---|
| $\widehat I_{t:T}$ | 从当前到投放结束的未来流量预测。 | 成本和价值曲线是单位机会平均量，必须乘以 traffic 才能得到总量。 |
| $\widehat{\bar C}_{t:T}(\alpha)$ | 如果后续 horizon 使用 multiplier $\alpha$，单位机会平均成本是多少。 | 预算约束需要预测未来会花多少钱。 |
| $\widehat{\bar V}_{t:T}(\alpha)$ | 如果后续 horizon 使用 multiplier $\alpha$，单位机会平均价值是多少。 | CPA/ROAS 需要预测花费相对价值是否健康。 |

把单位曲线转成总量：

$$
\widehat{\mathcal C}_{t:T}(\alpha)=\widehat I_{t:T}\widehat{\bar C}_{t:T}(\alpha),
\qquad
\widehat{\mathcal V}_{t:T}(\alpha)=\widehat I_{t:T}\widehat{\bar V}_{t:T}(\alpha).
$$

这一步很关键：controller 真正解约束时用的是剩余 horizon 的**总成本**和**总价值**，不是单位曲线本身。

### 3.1 curve 不是离散查表，而是参数化函数

论文让网络输出曲线参数，而不是在一堆离散 $\alpha$ 上逐点预测。直观形式是：

$$
\widehat{\bar C}(\alpha)=f_C(\alpha;\theta_C),
\qquad
\widehat{\bar V}(\alpha)=f_V(\alpha;\theta_V).
$$

文档已有口径中，曲线使用 $\log\alpha$ 上的 Normal CDF 风格单调饱和函数族，网络输出少量参数 $(a,b,c)$：

- $a$：饱和上限，决定曲线最终能到多高；
- $b$：斜率或敏感度，决定 multiplier 变化带来多大响应；
- $c$：横向平移，决定在哪个 multiplier 附近开始明显增长。

这类函数族背后的结构假设是：随着 $\alpha$ 增大，赢得更多曝光，成本和价值通常不下降，但会逐渐饱和。它用可解释先验换取样本效率和求根稳定性。

### 3.2 为什么要预测 aggregate curve？

Figure 1 中的上横线 $\bar C_{t:T},\bar V_{t:T}$ 表示它们是未来 horizon 上的聚合响应，不是每个 tick 一条独立曲线。

这意味着 GRM 问的是：

> 从现在到结束，如果统一采用某个 multiplier $\alpha$，平均成本和平均价值会怎样？

它不直接预测完整未来动作序列。这降低了问题维度，也让 controller 能用一维求根处理约束。

### 4. 左上角 $D_k$：训练标签从哪里来？

训练时，离线日志给出每个未来 tick $k$ 实际执行过的 multiplier 与结果：

$$
(\alpha_k,I_k,\mathrm{Cost}_k,\mathrm{Val}_k).
$$

因此可以得到日志动作处的观测点：

$$
C_k(\alpha_k)\approx\frac{\mathrm{Cost}_k}{I_k},
\qquad
V_k(\alpha_k)\approx\frac{\mathrm{Val}_k}{I_k}.
$$

对一个 anchor tick $t$，论文从 $\{t,\ldots,T\}$ 中采样未来 tick $k$，让模型在 $\alpha_k$ 这个位置拟合观测到的成本和价值，同时监督未来流量。

可以把训练理解成：

1. 输入 anchor $t$ 之前的历史；
2. 预测从 $t$ 到 $T$ 的 response bundle；
3. 随机抽一个未来点 $k$；
4. 用日志中 $k$ 点的真实结果监督曲线在 $\alpha_k$ 处的值；
5. 按 traffic 加权，避免小流量 tick 噪声过大。

### 4.1 这是不是完整反事实学习？

不是。日志只告诉我们“当时实际用了 $\alpha_k$，结果如何”，没有告诉我们“如果同一时刻换成所有其他 $\alpha$，结果如何”。

GRM 之所以能预测整条曲线，依赖三件事：

- 历史数据中不同 campaign、不同 tick 覆盖了不同 multiplier；
- Transformer 用历史状态条件化，减少不同情境混在一起的问题；
- 单调饱和函数族提供结构约束，使曲线不会任意乱摆。

所以不能说 GRM “拿到了真实反事实曲线”。更严谨的说法是：**它在结构化函数族和历史覆盖假设下，从日志点估计响应曲线。**

### 5. Budget Pacing：第一张紫色纸怎样得到 $\alpha_B$？

当前 tick 前已经花掉 $\mathrm{Cost}_{<t}$，剩余预算为：

$$
B_t=B-\mathrm{Cost}_{<t}.
$$

预算根定义为：

$$
\widehat{\mathcal C}_{t:T}(\alpha_B)=B_t.
$$

直观解释：

- 如果 $\alpha$ 太小，预测总成本低于剩余预算，可能花不完；
- 如果 $\alpha$ 太大，预测总成本超过剩余预算，可能超支；
- $\alpha_B$ 是刚好把预算用到边界的 multiplier。

因为成本响应曲线被设计为随 $\alpha$ 单调不下降，所以可以用 bisection 做稳定的一维求根。

### 5.1 如果根不存在怎么办？

实际系统中会有边界情况：

- 即使用最小 multiplier 也可能超预算；
- 即使用最大 multiplier 也花不完预算；
- traffic 预测接近 0，导致曲线几乎没有有效响应。

论文口径中，若最大 multiplier 也无法花完预算，则预算不再是当前限制，可将 $\alpha_B$ 设为动作上界 $\bar\alpha$。若最小 multiplier 都超预算，则 controller 应退到下界或采取保守动作。核心原则是：**求根失败时要落到边界，而不是让神经网络自由补一个动作。**

### 6. CPA Pacing：第二张紫色纸怎样得到 $\alpha_C$？

CPA 约束要把历史累计结果和未来预测结果合起来看：

$$
\frac{\mathrm{Cost}_{<t}+\widehat{\mathcal C}_{t:T}(\alpha)}
{\mathrm{Val}_{<t}+\widehat{\mathcal V}_{t:T}(\alpha)}
\le \tau.
$$

其中 $\tau$ 是目标 CPA。将其移项：

$$
\widehat{\mathcal C}_{t:T}(\alpha)-\tau\widehat{\mathcal V}_{t:T}(\alpha)
\le
\tau\mathrm{Val}_{<t}-\mathrm{Cost}_{<t}.
$$

定义历史 slack：

$$
\Delta_t=\tau\mathrm{Val}_{<t}-\mathrm{Cost}_{<t}.
$$

边界根为：

$$
\widehat{\mathcal C}_{t:T}(\alpha_C)-\tau\widehat{\mathcal V}_{t:T}(\alpha_C)=\Delta_t.
$$

$\Delta_t$ 的意义很直观：

- $\Delta_t$ 大：过去 CPA 健康，还有效率余量，允许更激进；
- $\Delta_t$ 小或为负：过去已经偏贵，当前必须更保守；
- 未来价值曲线越高，给定成本下越容易满足 CPA。

### 6.1 Figure 1 中的 ratio 为什么只是示意？

图里可能把 CPA 写成类似 $\widehat{\bar C}(\alpha)/\widehat{\bar V}(\alpha)$ 的形式。这是压缩画法。严格求根时，需要用 traffic 换算后的未来总量，并合并历史累计结果。

这里可以这样理解：

> 图上画的是未来单位响应的效率比，但 controller 真正约束的是全周期累计 CPA，所以要把已经发生的 cost/value 和预测未来 cost/value 一起放进方程。

### 7. 图中的 MIN：为什么取 $\min\{\alpha_B,\alpha_C\}$？

预算根和 CPA 根分别给出两个约束允许的最大 multiplier：

$$
\alpha_t=\min\{\alpha_B,\alpha_C\}.
$$

如果 $\alpha_B<\alpha_C$，说明预算更紧；如果 $\alpha_C<\alpha_B$，说明效率更紧。取 min 等价于取两个可行区间的交集。

这不是可学习 gate，也不是经验调参，而是显式控制逻辑。只要响应曲线单调且预测准确，较小的根同时满足两个约束。

### 7.1 为什么取最大可行 multiplier 合理？

在论文的 single-multiplier 假设下，价值曲线随 $\alpha$ 不下降。也就是说，在满足约束的范围内，越大的 multiplier 通常能赢得更多有效曝光。因此 controller 的目标可以理解为：

> 在不违反预算和 CPA 的前提下，选择最大的可行 $\alpha$。

这就是 min-pacing 的经济含义：不是越保守越好，而是把动作推到约束边界附近，提高预算使用和价值获取。

### 8. 一个具体例子：从状态到动作

假设当前 campaign：

```text
总预算 B = 10,000
已花 Cost_<t = 6,000
剩余预算 B_t = 4,000
目标 CPA τ = 100
已获得价值 Val_<t = 70
```

历史 CPA 为 $6000/70\approx85.7$，低于目标 100，因此还有一定效率余量：

$$
\Delta_t=100\times70-6000=1000.
$$

GRM 预测未来总成本曲线和价值曲线后，controller 分别求根：

```text
预算根 α_B = 1.30
CPA 根  α_C = 1.10
```

最终：

$$
\alpha_t=\min(1.30,1.10)=1.10.
$$

解释是：预算还允许更激进，但 CPA 约束更紧，所以当前应按效率上限执行。下一 tick 真实成本和价值回流后，系统会重新计算 slack、重新预测曲线、重新求根。

### 9. 训练与线上执行闭环

**训练时**：

1. 从离线 episode 采样 anchor tick $t$；
2. 输入历史状态与历史 multiplier；
3. Transformer 输出未来 traffic、成本曲线、价值曲线；
4. 从未来 $t{:}T$ 中采样监督 tick $k$；
5. 在日志实际 $\alpha_k$ 处拟合 $\mathrm{Cost}_k/I_k$ 与 $\mathrm{Val}_k/I_k$；
6. 用剩余 horizon traffic 监督 $\widehat I_{t:T}$；
7. 更新 GRM 参数。

**线上时**：

1. 读取当前状态和累计 cost/value；
2. GRM 预测未来 response bundle；
3. controller 求 $\alpha_B$；
4. controller 求 $\alpha_C$；
5. 取 $\min$ 得到当前 $\alpha_t$；
6. 对本 tick 的每次曝光执行 $b_{t,i}=\alpha_t v_{t,i}$；
7. 真实反馈进入下一 tick。

这就是 receding-horizon control：GRM 预测的是“从现在到结束”的剩余 horizon，但线上只执行当前一步，并在下一步重新规划。

## 第二部分：把每个知识点拆开讲

### 10. GRM 和 Decision Transformer 的本质差别

Decision Transformer 常见形式是：

$$
(R_1,s_1,a_1,\ldots,R_t,s_t)\rightarrow \hat a_t.
$$

它学习的是条件动作分布。GRM 的形式更像：

$$
(s_{1:t},\alpha_{1:t-1})\rightarrow
\left(\widehat I,\widehat{\bar C}(\alpha),\widehat{\bar V}(\alpha)\right)
\rightarrow \alpha_t.
$$

前者问“历史上类似情况下，应该怎么做”；后者问“如果我这样做，未来会怎样”。

因此 GRM 更适合约束场景：约束不是隐含在动作标签里，而是在 controller 里显式检查。

### 11. 为什么说 GRM 是 model-based 思路？

在强化学习语境中：

- model-free：直接学习 policy 或 value；
- model-based：学习环境响应或动力学，再规划动作。

GRM 不一定预测完整状态转移，但它预测 action multiplier 对未来 cost/value 的响应，因此具有明显 model-based 色彩。它的 planner 就是 min-pacing controller。

这也是它和 GAVE 的区别：GAVE 用 value-guided exploration 改进生成动作，GRM 用 response prediction + root solving 直接处理约束。

### 12. 为什么用 curve，而不是只预测当前最优 $\alpha$？

如果只预测 $\hat\alpha_t$，模型必须同时学会：

1. 未来流量怎么变化；
2. 成本和值怎么随动作变化；
3. 预算怎么约束；
4. CPA 怎么约束；
5. 多个约束谁更紧。

这会把业务规则和环境预测全压进一个黑盒。预测曲线后，模型只负责第 1、2 件事，controller 负责第 3、4、5 件事。

好处是：

- 可解释：能看到预算根和 CPA 根；
- 可调试：知道是预测错了，还是约束太紧；
- 可迁移：换预算或 CPA 目标时，不一定要重训 policy；
- 更稳：动作由显式可行区间决定。

### 13. 为什么曲线要单调？

在 multiplier 机制下，提高 $\alpha$ 通常会提高竞价竞争力，赢得更多曝光。因此成本和价值对 $\alpha$ 应该大体单调不下降。

如果网络随意输出非单调曲线，会出现很奇怪的 controller 行为：

- bisection 可能找不到稳定根；
- 更高出价反而预测更低成本，违反业务常识；
- 多个根同时存在，动作解释困难。

单调函数族不是为了让模型更花哨，而是为了让后面的求根器可用。

### 14. 为什么 curve 会饱和？

当 $\alpha$ 很小时，很多曝光赢不下来，成本和价值都低；当 $\alpha$ 增大，会赢得更多机会；但当 $\alpha$ 已经足够大后，可赢得的高质量流量接近上限，再继续增大 multiplier，新增价值会变少，成本也趋于饱和或边际变化变小。

这就是饱和曲线的直觉：

```text
低 α：几乎不赢，成本/价值低
中 α：赢量快速增加，曲线斜率大
高 α：可赢流量接近上限，曲线逐渐变平
```

### 15. 为什么 traffic 单独预测？

如果只预测总成本和总价值，模型很难区分：

- 流量多但单位成本低；
- 流量少但单位成本高；
- 流量变化导致总量变化；
- multiplier 变化导致单位响应变化。

GRM 把未来 traffic $\widehat I$ 与单位曲线 $\widehat{\bar C},\widehat{\bar V}$ 分开，有助于把“未来有多少机会”和“每个机会平均会花/赚多少”拆开建模。

### 16. 为什么用 future-sampled supervision？

如果每个 anchor $t$ 都监督完整未来 $t{:}T$ 的所有 tick，计算量和样本相关性都会很高。future sampling 随机抽一个未来 $k$，用它作为当前 anchor 的监督点。

这样做有两个作用：

- 让模型从不同 anchor 学到不同剩余 horizon 的响应；
- 用采样降低训练成本，同时覆盖多个未来位置。

但它也带来限制：每次只看到一个日志动作处的点，曲线形状仍依赖参数化和跨样本泛化。

### 17. 为什么说 GRM 能“显式满足约束”，但不能说“绝对不会违规”？

在预测曲线准确、单调假设成立、求根边界处理正确的前提下，controller 输出的 $\alpha_t$ 是预测模型下的可行动作。

但真实世界中：

- traffic 可能预测错；
- 成本曲线可能预测错；
- 价值曲线可能预测错；
- 拍卖竞争环境会突变；
- 价值反馈可能延迟。

因此更精确的说法是：**GRM 显式满足的是预测模型下的约束，并通过每 tick 重规划降低误差累积；真实约束稳定性仍依赖响应预测质量。**

### 18. 与 GAVE、AIGB、DT 的位置关系

| 方法 | 核心问题 | 动作怎么来 | 约束怎么处理 |
|---|---|---|---|
| DT | 把离线 RL 改成序列建模。 | 直接生成动作。 | 通常通过 RTG 或 reward 间接体现。 |
| AIGB | 生成完整出价轨迹。 | 条件生成未来动作序列。 | 依赖条件和训练分布。 |
| GAVE | 超过历史次优轨迹。 | 在日志附近做价值引导探索。 | 通过 score-based RTG 间接约束。 |
| GRM | 显式满足预算与 CPA。 | 先预测响应，再解析求根。 | 预算根、CPA 根、取 min。 |

所以 GRM 的贡献不是“生成能力更强”，而是**把约束从 reward 里拿出来，放回控制方程里**。

## 第三部分：实验与理论应怎样读

### 19. 论文实验到底验证什么？

论文在 AuctionNet 等自动出价模拟环境中比较多种 baseline，核心要看两类指标：

- 效果：value、conversion、score、ROAS 等是否更高；
- 约束：budget violation、CPA/ROAS violation、constraint stability 是否更好。

如果一个方法价值很高但经常超 CPA，它并不是工业意义上的好自动出价器。GRM 的实验重点应理解为：在相似 benchmark 下，预测响应再显式控制，能比直接 policy 或 penalty 方法更稳定地处理约束。

### 20. 理论结果应该怎么理解？

文档已有口径中，论文给出几个理论解释：

1. 在 single-multiplier 问题中，解析 controller 是精确的；
2. 相对逐 tick 完全控制的最优性缺口，与边际 value-per-cost 的离散程度有关；
3. receding-horizon 控制下，约束违反与预测误差相关。

这些结论不是证明“广告世界被完全解决”，而是证明在论文的动作降维、单调响应和预测误差假设下，这个结构有清晰的可行性与误差来源。

### 21. 最大局限

GRM 的局限也很明确：

- **反事实覆盖不足**：日志只覆盖历史实际 multiplier，曲线外推可能不准；
- **预测错则控制错**：controller 在错误曲线上求根，会精确地得到错误动作；
- **single multiplier 限制表达力**：一个 $\alpha$ 无法表达复杂人群、地域、时段、商品级异质动作；
- **延迟反馈问题**：CPA/价值反馈若延迟，状态和监督都会变难；
- **极端流量突变**：突发竞争变化会破坏历史响应规律。

因此落地时最重要的是监控 response calibration，而不仅是看最终 score。

### 22. 如果要工程借鉴，应该关注什么？

可借鉴点按优先级排序：

1. 先把自动出价动作降成业务可控的 multiplier；
2. 用状态历史预测未来 traffic、cost curve、value curve；
3. 对曲线施加单调和边界约束；
4. 用预算根和 CPA/ROAS 根显式求可行动作；
5. 每个 tick 重规划，避免一次预测锁死全天；
6. 上线前做曲线校准、根稳定性和极端状态回放测试。

## 最终 takeaway

> GRM 最值得学习的不是 Transformer 本身，而是问题重写方式：先把自动出价的复杂动作降成 multiplier，再学习 multiplier 到未来成本/价值的响应曲线，最后用显式求根满足预算和 CPA。神经网络处理不确定环境，解析控制器处理硬约束；这让系统比纯 reward penalty 更可解释、更可靠，但也把成败集中到了响应曲线是否预测准确上。
