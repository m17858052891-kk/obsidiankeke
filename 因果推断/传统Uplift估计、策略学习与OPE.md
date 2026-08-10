
## 1. 先定义：我们到底想估计什么

对用户 $i$，令 $T_i\in\{0,1\}$ 表示是否给券，$Y_i(1)$、$Y_i(0)$ 是给券/不给券时的潜在结果。个体增量为：

$$
\tau_i=Y_i(1)-Y_i(0).
$$

同一用户只能观察到一个事实结果：

$$
Y_i=T_iY_i(1)+(1-T_i)Y_i(0).
$$

因此不能把“发券用户转化率减未发券用户转化率”直接称为个体因果效应；两群人可能本来就不同。

常见 estimand：

| 名称   | 公式                             | 回答的问题            |
| ---- | ------------------------------ | ---------------- |
| ATE  | $\mathbb E[Y(1)-Y(0)]$         | 全体平均增量           |
| ATT  | $\mathbb E[Y(1)-Y(0)\mid T=1]$ | 已被处理人群的平均增量      |
| CATE | $\mathbb E[Y(1)-Y(0)\mid X=x]$ | 某类特征人群的增量        |
| ITE  | $Y_i(1)-Y_i(0)$                | 单个人的增量，通常无法被直接验证 |

营销资源分配常需要 CATE/ITE 的排序或净价值，而不是仅 ATE。

## 2. 可识别性：模型再复杂也绕不开的前提

用观测数据识别 CATE，通常需要：

1. 一致性：观察到处理 $T=t$ 时，结果等于 $Y(t)$；
2. 可忽略性/无混杂：$(Y(1),Y(0))\perp T\mid X$；
3. 重叠性/positivity：对可比较的 $x$，有 $0<e(x)=P(T=1\mid X=x)<1$；
4. SUTVA 的关键部分：一个人的处理不会因别人的处理而改变其潜在结果。

发券、竞价、供需等场景常违反最后两条：强策略会导致部分人几乎必然领券；一个人被补贴可能改变司机供给或其他人的价格。此时再高的 AUUC 也不是自动的因果证明。

## 3. S、T、X Learner：最常见的起点

### 3.1 S-Learner：一个模型，把 treatment 当特征

训练单一预测器：

$$
\hat\mu(x,t)\approx\mathbb E[Y\mid X=x,T=t],
\qquad
\hat\tau(x)=\hat\mu(x,1)-\hat\mu(x,0).
$$

优点是简单、共享数据多；缺点是当 treatment 效应较弱时，模型可能忽略 treatment 特征，导致 uplift 被压小。

### 3.2 T-Learner：处理组和对照组各训一个模型

$$
\hat\mu_1(x)\leftarrow\{T=1\},\qquad
\hat\mu_0(x)\leftarrow\{T=0\},
\qquad
\hat\tau(x)=\hat\mu_1(x)-\hat\mu_0(x).
$$

它允许两组响应函数完全不同，直觉清晰；但当某一组样本少时方差大，且两塔的预测误差相减会放大。

### 3.3 X-Learner：先借另一组补出“伪效应”

先估计 $\hat\mu_1,\hat\mu_0$，再构造：

$$
D_i^{(1)}=Y_i-\hat\mu_0(X_i)\quad (T_i=1),
$$

$$
D_i^{(0)}=\hat\mu_1(X_i)-Y_i\quad (T_i=0).
$$

分别学习两组伪效应，再按 propensity 加权融合。它在 treatment/control 极不平衡时往往比简单 T-Learner 更稳，但仍依赖结果模型和倾向估计质量。

## 4. R-Learner、DR-Learner：怎样把倾向与结果模型结合

令 $e(x)=P(T=1\mid X=x)$，$\mu(x)=\mathbb E[Y\mid X=x]$。

R-Learner 的直觉是先将处理和结果都对 $X$ 残差化，再学习剩余处理变化带来的结果变化：

$$
\min_\tau\sum_i
\left[
(Y_i-\hat\mu(X_i))
-(T_i-\hat e(X_i))\tau(X_i)
\right]^2.
$$

它强调“在相似 $X$ 下，处理偏离常态时结果怎样变化”，但 overlap 差时 $T-\hat e(X)$ 接近 0，估计仍会不稳定。

DR-Learner 常用一个 doubly robust 伪结果作为监督信号：

$$
\tilde\tau_i
=
\hat\mu_1(X_i)-\hat\mu_0(X_i)
+
\frac{T_i}{\hat e(X_i)}[Y_i-\hat\mu_1(X_i)]
-
\frac{1-T_i}{1-\hat e(X_i)}[Y_i-\hat\mu_0(X_i)].
$$

再回归 $\tilde\tau_i$ 到 $X_i$。其“双重稳健”含义是：在满足其他前提时，结果模型或倾向模型中有一个估得正确，效应估计仍可保持一致；不是说任意数据、任意两个错误模型都可靠。

### Cross-fitting 为什么重要

若用同一批样本拟合 nuisance models（$\mu,e$）又生成伪标签，模型可能记住训练噪声。Cross-fitting 将数据折分：在其他折训练 $\hat\mu,\hat e$，再给当前折生成伪标签，降低过拟合带来的偏差。

## 5. Causal Forest：树模型怎样做异质性效应

Causal Forest 在树的分裂时不只追求结果 $Y$ 的预测误差下降，而倾向寻找 treatment effect 差异更明显的区域；一个叶子中再比较处理/对照结果，森林集成得到 CATE。

它适合中等规模、结构化特征和较强可解释诉求，可直接看哪些变量区分效应；局限是高维稀疏 ID、复杂序列或多档 treatment 时不如深度表征自然，仍需要足够 overlap。

## 6. 多档券/多 treatment：输出不是一个 uplift

若动作 $a\in\{0,1,\ldots,M\}$，需要估计：

$$
\tau_m(x)=\mu_m(x)-\mu_0(x),\qquad m=1,\ldots,M.
$$

最终不应只选最大 uplift，而应考虑成本和业务价值：

$$
v_m(x)
= \operatorname{value}(x)\cdot \tau_m(x)-\operatorname{cost}_m.
$$

然后在预算约束下做选人、选档。这与 [[营销因果决策论文精读/01_DFCL：怎样让因果预测直接服务营销资源分配]] 的“预测表进入资源分配器”完全衔接。

## 7. 策略学习与离线策略评估（OPE）

预测 CATE 只是中间步骤，最终策略是 $\pi(a\mid x)$：给什么动作、概率多大。日志来自历史行为策略 $\mu(a\mid x)$，若要离线估计新策略价值，必须记录或可靠估计历史 propensity。

### 7.1 IPS

$$
\hat V_{\mathrm{IPS}}(\pi)
=\frac1N\sum_{i=1}^N
\frac{\pi(A_i\mid X_i)}
{\mu(A_i\mid X_i)}Y_i.
$$

它将历史样本重加权到目标策略分布；若新策略偏好历史几乎没执行过的动作，分母很小，方差会爆炸。

### 7.2 SNIPS

$$
\hat V_{\mathrm{SNIPS}}(\pi)
=
\frac{\sum_i w_iY_i}{\sum_iw_i},
\qquad
w_i=\frac{\pi(A_i\mid X_i)}{\mu(A_i\mid X_i)}.
$$

归一化能缓解有限样本中权重总量波动，但可能引入偏差。

### 7.3 Doubly Robust OPE

设 $\hat q(x,a)$ 是结果模型：

$$
\hat V_{\mathrm{DR}}(\pi)
=\frac1N\sum_i
\left[
\sum_a\pi(a\mid X_i)\hat q(X_i,a)
+
\frac{\pi(A_i\mid X_i)}{\mu(A_i\mid X_i)}
\left(Y_i-\hat q(X_i,A_i)\right)
\right].
$$

它将直接模型与 IPS 校正结合，通常方差更可控；仍要求 logging policy、支持集和结果模型定义正确。

## 8. 何时不应相信 OPE 或 uplift 曲线

- 历史日志没有记录 propensity，且无法从策略重建；
- 目标策略会把人群推到日志从未覆盖的动作区域；
- 权重极端、有效样本量很小；
- 存在未观测混杂，例如人工运营依据未入库信息发券；
- 强网络干扰，例如补贴会改变供需和其他人的结果；
- 只用同一份数据反复调策略，再报告最优曲线。

这时应缩小策略变化、引入随机探索或 RCT，并报告权重分布、重叠诊断、协变量平衡和时间外结果。

## 9. 与现有笔记怎样选择

| 问题 | 优先阅读 |
|---|---|
| 用浅层/树模型快速做 uplift baseline | 本篇 S/T/X、Causal Forest |
| 为什么需要表示平衡 | [[深度解析 CFR：反事实回归 (Counterfactual Regression)]] |
| 怎样减轻 treatment 与 outcome 表征纠缠 | [[DR-CFR：解耦表征反事实回归]] |
| 多 treatment 的响应与交互 | [[EFIN详解：联动CFR与DR-CFR理解]] |
| 资源约束下如何把预测变成决策 | [[营销因果决策论文精读/01_DFCL：怎样让因果预测直接服务营销资源分配]] |
| OBS + RCT 怎样共同训练 | [[营销因果决策论文精读/02_Bi-DFCL：怎样用RCT与OBS共同优化营销决策]] |

## 10. 高频面试问答

### 为什么不能用“最高响应概率”做发券策略？

高响应者可能不发券也会转化。营销资源应按相对不发券时的增量、券成本与预算约束决策，而不是按 $P(Y=1\mid X,T=1)$ 排序。

### DR-Learner 和 DR-CFR 是同一个模型吗？

不是。DR-Learner 是常见的双重稳健伪标签/估计框架；DR-CFR 是特定的深度反事实表征方法。二者都可能使用 outcome 与 propensity 思想，但结构、目标和论文定义不同，不能混称。

### OPE 能代替线上实验吗？

不能。OPE 依赖历史策略覆盖、可忽略性和正确的 propensity/结果模型；它适合离线筛选与降低试错成本。面对新策略、大幅分布外动作或供需干扰，仍需要受控实验验证。
