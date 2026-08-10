论文：[Decision Focused Causal Learning for Direct Counterfactual Marketing Optimization](https://arxiv.org/abs/2407.13664)

会议：KDD 2024

## 1. 总结

DFCL 不替换因果结果模型，而是让“结果面预测器 → 预算分配器”成为一个共同训练的闭环。普通模型只想把每个收益/成本预测得更准；DFCL 还要求：将这些预测拿去分配预算后，最终的**营销决策要更好**。价值在于“因果结果面估计”与“预算受限的实际动作”连为同一个训练目标。

```
一个人对不同券档会有不同收益与成本
→ 模型预测整张“人 × 券档”结果面
→ 分配器在预算内选择券档
→ 分配结果的质量反过来训练预测器。
```

## 2. 业务定义：模型最后要替谁、在什么约束下做什么决定？

DFCL 处理的不是“给每个用户打一个发券分”，而是：**在一批同时到来的候选人中，给每个人选一个动作，同时保证整批补贴不超预算。**

- 个体 $i\in\{1,\ldots,N\}$ 可以是用户、商家或一次营销机会；
- 动作 $j\in\{0,\ldots,M\}$ 可以是“不干预、3 元券、5 元券、8 元券”；这里把 $j=0$ 记作不干预；
- 最终动作不是模型逐人独立分类出来的，而是分配器综合全体人的收益、成本和预算后输出。

| 符号 | 含义 | 发券场景的直觉 |
|---|---|---|
| $x_i$ | 个体 $i$ 在决策时的特征 | 活跃度、价格敏感度、城市、供需、历史行为 |
| $t_i$ | 日志/RCT 中实际给到的动作 | 该用户实际拿到 5 元券 |
| $r_{ij}$ | 对 $i$ 采取 $j$ 后的潜在收益 | 如果给 5 元券，理论上会产生的订单、GMV 或利润 |
| $c_{ij}$ | 对 $i$ 采取 $j$ 后的潜在成本 | 券核销、补贴或业务定义的其他成本 |
| $z_{ij}$ | 最终是否给 $i$ 选动作 $j$ | $z_{i,5\text{元}}=1$ 表示最终发 5 元券 |
| $B$ | 当前这一批决策可使用的总预算 | 当日/当前窗口的补贴额度 |

若完整结果面都已知，论文将资源分配写为多选背包问题：

$$
\begin{aligned}
\max_z\quad &\sum_{i=1}^{N}\sum_{j=0}^{M}z_{ij}r_{ij}\\
\text{s.t.}\quad
&\sum_{i=1}^{N}\sum_{j=0}^{M}z_{ij}c_{ij}\le B,\\
&\sum_{j=0}^{M}z_{ij}=1,\qquad z_{ij}\in\{0,1\}.
\end{aligned}
$$

第一条约束表示全体成本不能超过预算；第二条表示每个人只能选一个动作。将“不干预”作为 $j=0$ 后，分配器也可以选择不给券，而不是被迫给每个人补贴。

### 2.1 原始收益不等于增量收益：先说清业务真正想优化什么

论文的 $r_{ij}$ 只表示“动作 $j$ 下能得到多少收益”，并不天然等于这份收益由动作带来了多少。若业务要回答的是“券额带来的**新增**完单/GMV”，就必须以不干预结果为基线：

$$
\Delta r_{ij}=r_{ij}-r_{i0},\qquad
\Delta c_{ij}=c_{ij}-c_{i0}.
$$

这两个差值才是动作 $j$ 相对“不做任何干预”的因果增量。下面的例子最容易看出差别：

| 用户 | 不发券完单概率 $r_{i0}$ | 发 5 元券后 $r_{i,5}$ | 原始结果 | 券带来的增量 $\Delta r_{i,5}$ |
|---|---:|---:|---:|---:|
| A：天然会下单 | 0.90 | 0.92 | 0.92 | 0.02 |
| B：被券拉动 | 0.10 | 0.30 | 0.30 | 0.20 |

若按发券后的原始完单率排序，会误以为 A 更值得发券；但 A 几乎本来就会下单，券只多带来 $0.02$ 个预期订单。若预算目标是增量完单，B 才是更值得花钱的对象。

因此有两种合法但不能混用的口径：

| 业务问题 | 分配器应输入什么 |
|---|---|
| 希望最大化动作后的总 GMV、总收入或总订单 | 原始结果 $(r_{ij},c_{ij})$ |
| 希望最大化补贴带来的新增 GMV、增量订单或增量利润 | 增量结果 $(\Delta r_{ij},\Delta c_{ij})$ |

若成本仅指券核销成本，通常 $c_{i0}=0$，于是 $\Delta c_{ij}=c_{ij}$；若成本还包含本来就会发生的履约或运营成本，则也应使用增量成本。**选择哪种口径后，模型训练、预算约束和离线评估必须全程使用同一口径。**

## 3. 反事实缺失：为什么不能直接拿“增量”当训练标签？

对同一位用户，我们只能看到其实际被分配的一个动作的结果。训练数据中第 $i$ 条样本是：

$$
(x_i,t_i,r_{i,t_i},c_{i,t_i}).
$$

例如用户 A 实际拿到 5 元券并完单，我们能观察 $r_{i,5}$ 和 $c_{i,5}$；但看不到“同一个 A 不发券、发 3 元券、发 8 元券时会怎样”。因此也看不到这个人真实的

$$
\Delta r_{i,5}=r_{i,5}-r_{i,0}.
$$

这就是反事实缺失：不是数据里少一列，而是同一个人的其他世界在现实中不会同时发生。

RCT 的作用是让 $t_i$ 随机分配。它不能让我们看到单个用户的全部结果面，但能保证：被分到动作 $j$ 的样本，在总体上可无偏代表“若采取 $j$ 会出现的结果”。模型据此学习完整预测结果面：

$$
m_\omega(x_i)=
\{(\hat r_{i0},\hat c_{i0}),\ldots,(\hat r_{iM},\hat c_{iM})\}.
$$

若业务选择增量口径，再由预测结果面构造：

$$
\hat{\Delta r}_{ij}=\hat r_{ij}-\hat r_{i0},\qquad
\hat{\Delta c}_{ij}=\hat c_{ij}-\hat c_{i0}.
$$

关键点是：**模型先估计每个动作下的潜在结果，再做差得到 uplift；不能把一个样本的事实结果直接当成它的 uplift 标签。**

## 4. 传统“预测 → 求解”为什么不够？

两阶段方法的链路是：

$$
\text{最小化逐格预测误差}
\;\longrightarrow\;
(\hat r,\hat c)
\;\longrightarrow\;
\text{求解器据此做预算分配}.
$$

它的问题不在于“预测没有用”，而在于普通 MSE/Logloss 和最终分配器关心的对象不同。

设预算只够给一人发券，A、B 的真实增量净价值分别为 $1.01$ 与 $1.00$。模型预测为 $\hat q_A=1.00,\hat q_B=1.02$，每个预测都只错了很小一点，却会让分配器把券从 A 错发给 B；这是会改变动作的**边界错序**。相反，对于远低于发券门槛的 C，即使预测误差更大，只要它仍排在最后，最终动作并不改变。

| 预测误差发生的位置 | MSE 的看法 | 分配器的看法 |
|---|---|---|
| A 与 B 在预算边界附近发生微小错序 | 误差很小 | 动作可能翻转，直接损失真实收益 |
| C 始终不会被选中，但数值误差较大 | 误差较大 | 动作不变，对当前策略几乎无影响 |

此外，求解器同时比较收益和成本。对固定影子价格 $\lambda$，它实际按

$$
\hat q_{ij}(\lambda)=\hat r_{ij}-\lambda\hat c_{ij}
$$

来比较动作；所以收入、成本中任意一个预测误差都可能改变最终排序与预算使用。

理想上，我们希望直接用“模型预测后得到的策略，在真实结果面上表现多好”来训练：

$$
z^*(B,\hat r,\hat c)
=\arg\max_z F(z,B,\hat r,\hat c),
\qquad
\mathcal L_{\mathrm{DL}}
=-\sum_{i,j}r_{ij}z_{ij}^*(B,\hat r,\hat c).
$$

但这正好遇到两个障碍：真实 $r_{ij},c_{ij}$ 的反事实不可见；而 $z^*$ 含有离散 $\arg\max$，不能直接反向传播。DFCL 的中心工作就是为这个决策损失构造可训练的梯度，而不是单纯更换一个预测 backbone。

## 5. DFCL ：输入、模块与输出

### 5.1 结果模型：输出什么？

DFCL 没有规定 backbone 必须是 Transformer、CFR 或某个特殊网络。论文实验使用共享 MLP 和多个 head；从框架角度，只要求模型接口为：

$$
m_{\omega}(x_i)
=\bigl(\hat{\boldsymbol r}_i,\hat{\boldsymbol c}_i\bigr)
=\left\{(\hat r_{ij},\hat c_{ij})\right\}_{j=1}^{M}.
$$

其中，$x_i$ 是个体 $i$ 的特征，$\omega$ 是结果模型参数；$\hat r_{ij}$、$\hat c_{ij}$ 分别表示模型对“给 $i$ 分配 treatment $j$”时收益与成本的预测。若动作是 $\{0,2,4,8\}$ 元券，输出就是四组 $(\hat r_{ij},\hat c_{ij})$，而不是只输出一个分数。

它不是输出一个“高价值用户分数”，而是输出一张**人 × 动作**结果面。共享 encoder + 动作专属收益/成本 head 是一种实现；只要可以预测多 treatment 的收益和成本，也可作为 DFCL 的 backbone。

### 5.2 事实预测损失：怎样用只观察到一个动作的 RCT 样本训练？

对实际分到 $t_i$ 的样本，只回归该事实动作对应的两个输出：

$$
\mathcal L_{\mathrm{PL}}(r,c,\hat r,\hat c)
=\frac{1}{M}\sum_{i=1}^{N}\frac{1}{N_{t_i}}
\left[
\left(r_{i,t_i}-\hat r_{i,t_i}\right)^2
+\left(c_{i,t_i}-\hat c_{i,t_i}\right)^2
\right].
$$

这里 $t_i$ 是样本 $i$ 在 RCT 中实际被随机分配到的动作，$N_{t_i}$ 是该动作组的样本数；因此每个样本只监督自己实际经历过的那一列结果。论文的 Theorem 1 说明，在 RCT 随机分配下，上式等价于完整结果面 MSE 的无偏估计：

$$
\mathcal L_{\mathrm{PL}}=\mathcal L_{\mathrm{MSE}},\qquad
\mathcal L_{\mathrm{MSE}}
=\frac{1}{NM}\sum_{i=1}^{N}\sum_{j=1}^{M}
\left[
\left(r_{ij}-\hat r_{ij}\right)^2
+\left(c_{ij}-\hat c_{ij}\right)^2
\right].
$$

$\mathcal L_{\mathrm{PL}}$ 让结果面数值稳定、可泛化；但只优化它仍是两阶段方法。

### 5.3 分配器：这一步输出最终动作

DFCL 面对的是一个**多选背包问题（MCKP）**：在一批同时到来的候选人中，每个人只能选一个动作，同时所有动作的总成本不能超过预算。

若暂时假设真实的收益、成本结果面都已知，原始问题是：

$$
\begin{aligned}
\max_{z}\quad F(z,B)
&=\sum_{i=1}^{N}\sum_{j=1}^{M}z_{ij}r_{ij}\\
\text{s.t.}\quad
&\sum_{i=1}^{N}\sum_{j=1}^{M}z_{ij}c_{ij}\le B,\\
&\sum_{j=1}^{M}z_{ij}=1,\quad \forall i,\\
&z_{ij}\in\{0,1\},\quad \forall i,j.
\end{aligned}
$$

每个符号的意思是：

| 符号 | 含义 |
|---|---|
| $i$ | 当前这一批要决策的第 $i$ 个用户、商家或曝光机会 |
| $j$ | 动作或 treatment，例如 $0/2/4/8$ 元券 |
| $r_{ij}$ | 给 $i$ 采取 $j$ 后的真实业务收益；在因果营销口径下也可输入真实增量价值 |
| $c_{ij}$ | 给 $i$ 采取 $j$ 后的真实成本 |
| $z_{ij}$ | 是否给 $i$ 选择 $j$；为 $1$ 表示选中，否则为 $0$ |
| $\sum_jz_{ij}=1$ | 每个人只能选一个动作。通常将“不干预/0 元券”也作为成本为 $0$ 的动作，因此不是“一个都不选”，而是选择 no-treatment。 |

真实线上看不到完整的，因此求解时要将其替换为模型预测的结果面：

$$
z^*(B,\hat r,\hat c)
=\arg\max_zF(z,B,\hat r,\hat c).
$$

分配器拿到的是整批人的 $(\hat r,\hat c)$，而不是孤立地看某一个人。它要在“给 A 多发 4 元券”与“把这 4 元留给 B、C”之间作全局权衡，最终才输出 $z^*$。

### 5.4 理想决策损失：真正想优化什么？

注意这里有两张不同的表：

- **预测表** $(\hat r,\hat c)$：供求解器作决策；
    

- **真实表** $(r,c)$：用于事后判断“这套由预测驱动的策略究竟好不好”。
    

若反事实全可见，完整计算流程会是：

```
1. 模型输出预测表 r̂、ĉ；
2. 求解器在预算 B 下依据预测表得到 z*(B,r̂,ĉ)；
3. 不改变 z*，把它放到真实结果表 r 上结算；
4. 得到这套策略真实带来的总收益。
```

第 3 步的策略价值为：

$$
\sum_{i=1}^{N}\sum_{j=1}^{M}
r_{ij}\,z_{ij}^*(B,\hat r,\hat c).
$$

所以决策损失定义为其负数：

$$
\mathcal L_{\mathrm{DL}}(B,r,c,\hat r,\hat c)
=-\sum_{i=1}^{N}\sum_{j=1}^{M}
r_{ij}\,z_{ij}^*(B,\hat r,\hat c).
$$

负号只因训练要做最小化：策略真实收益越大，$\mathcal L_{\mathrm{DL}}$ 越小。

在原始 DFCL 的设定里，预算会随业务环境波动，因此理想目标还希望在**多个预算**上都表现好。论文先写成连续预算上的积分：

$$
\mathcal L_{\mathrm{DL}}(r,c,\hat r,\hat c)
=\int_0^{\infty}\mathcal L_{\mathrm{DL}}(B,r,c,\hat r,\hat c)\,dB,
$$

实际计算时再将预算离散为一组 $B$：

$$
\mathcal L_{\mathrm{DL}}(r,c,\hat r,\hat c)
=\sum_B\mathcal L_{\mathrm{DL}}(B,r,c,\hat r,\hat c).
$$

这里有两个根本障碍：

1. 反事实缺失：对任一用户，只观察到了日志/RCT 实际执行档位 $t_i$ 下的 $(r_{i,t_i},c_{i,t_i})$，看不到其他 $(r_{ij},c_{ij})$；因此第 3 步不能直接在完整真实表上结算。
    

2. **离散求解不可导：**内部含 0-1 选择和 $\arg\max$。小幅改变 $(\hat r,\hat c)$ 往往不改变动作，梯度为 0；跨过某个边界时动作又会突然跳变。
    

DFCL 后面的**对偶、代理损失和有限差分**，就是分别让“预算不确定的大规模求解”和“反事实/不可导的训练信号”变得可处理。

## 6. 为什么引入拉格朗日对偶？

### 6.1 从全局预算约束到“收益减成本价格”

原始问题难在预算把所有用户耦合在一起：A 多花 2 元，就可能挤掉 B 的动作。论文对预算约束引入非负拉格朗日乘子 $\lambda$，将原 MCKP 写为对偶问题：

$$
\begin{aligned}
\min_{\lambda\ge 0}\ \max_z\quad
H(z,\lambda,B,r,c)
&=\lambda B+\sum_{i=1}^{N}\sum_{j=1}^{M}
\bigl(r_{ij}-\lambda c_{ij}\bigr)z_{ij}\\
\text{s.t.}\quad
&\sum_{j=1}^{M}z_{ij}=1,\quad\forall i,\\
&z_{ij}\in\{0,1\},\quad\forall i,j,\\[2pt]
G(\lambda,B,r,c)
&=\max_zH(z,\lambda,B,r,c).
\end{aligned}
$$

也就是说，原本的“总成本不超过 $B$”不再直接写在内层求解器里，而被 $\lambda$ 写进每个动作的价值中。$\lambda$ 可以理解为“每多消耗 1 单位成本的影子价格”：$\lambda$ 越大，系统越珍惜预算。于是某个动作原本的收益 $r_{ij}$，变成扣除资源机会成本后的净价值：

$$
q_{ij}(\lambda)=r_{ij}-\lambda c_{ij}.
$$

对偶问题的外层就是在 $\lambda\ge0$ 上寻找最合适的成本价格：

$$
\lambda^*(B,r,c)=\arg\min_{\lambda\ge0}G(\lambda,B,r,c).
$$

### 6.2 固定 $\lambda$ 后，为什么大背包能拆成逐人比较？

对固定的 $\lambda$，$\lambda B$ 对所有动作都是常数；而每人仍只需满足“恰好选一个动作”。因此内层问题可写为：

$$
\max_zH(z,\lambda,\hat r,\hat c)
=\sum_{i=1}^{N}\max_j\bigl(\hat r_{ij}-\lambda\hat c_{ij}\bigr),
$$

也就是每个用户各自比较预测净价值：

$$
z^d_{ij}(\lambda,\hat r,\hat c)
=\mathbb I\!\left[
j=\arg\max_k\bigl(\hat r_{ik}-\lambda\hat c_{ik}\bigr)
\right].
$$

这并不表示“预算约束消失了”。预算约束被浓缩进了合适的 $\lambda$：预算紧时提高 $\lambda$，所有高成本券的分数都会更快下降；预算宽松时降低 $\lambda$，更多高成本但高收益动作会进入选择。

论文给出，最优 $\lambda^*$ 可由梯度下降或二分搜索寻找；停止条件可以写为：

$$
B-\sum_{i=1}^{N}\sum_{j=1}^{M}c_{ij}z_{ij}\le\epsilon
\quad\text{or}\quad
\lambda\le\epsilon.
$$

实际由模型作决策时，将上式的真实结果表替换为预测表 $(\hat r,\hat c)$；直觉上的更新方向是：

```
若 Σ_i,j z^d_ij(λ) · ĉ_ij > B：预算花超了 → 增大 λ；
若 Σ_i,j z^d_ij(λ) · ĉ_ij < B：预算仍有余量 → 减小 λ；
```

由于动作离散，总成本会呈阶梯状，未必总能严格等于 $B$；论文将由 $\lambda^*$ 得到的 $z^d$ 视为原多选背包的近似解。其给出的近似比为：

$$
\rho
=\frac{F(z^d,B,r,c)}{F(z^*,B,r,c)}
\ge 1-\frac{\max_{i,j}r_{ij}}{F(z^*,B,r,c)}
\approx 1.
$$

在大规模营销场景中，单个个体的最大收益通常远小于整批总体收益，因此该近似通常足够紧。

### 6.3 DFCL 为什么在多个 $\lambda$ 上学习？

原始 DFCL 的目标不是只服务某个固定预算，而是希望预算高低变化时都能给出合理策略。论文的 Theorem 2 说明：预算 $B$ 增大时最优影子价格 $\lambda^*$ 单调减小，且给定最优 $\lambda^*$ 时，上节的逐人解 $z^d$ 是原问题的近似解。因此可将“在多个预算上评估策略”改写为“在多个 $\lambda$ 上评估逐人选择”。

给定预测表，论文先按预测净收益求出动作：

$$
z^d(\lambda^*,\hat r,\hat c)
=\arg\max_zH(z,\lambda^*,\hat r,\hat c).
$$

再用真实收益与成本结算这套动作，定义单个 $\lambda^*$ 下的对偶决策损失：

$$
\mathcal L_{\mathrm{DDL}}
(\lambda^*,B,r,c,\hat r,\hat c)
=-\left[
\lambda^*B+
\sum_{i=1}^{N}\sum_{j=1}^{M}
\bigl(r_{ij}-\lambda^*c_{ij}\bigr)
z^d_{ij}(\lambda^*,\hat r,\hat c)
\right].
$$

其中 $\lambda^*B$ 不依赖模型的预测值 $(\hat r,\hat c)$，做梯度估计时可视为常数。将 $\lambda$ 连续化后，论文写成：

$$
\begin{aligned}
\mathcal L_{\mathrm{DDL}}(r,c,\hat r,\hat c)
&=-\int_{0}^{\infty}
\sum_{i=1}^{N}\sum_{j=1}^{M}
\bigl(r_{ij}-\lambda c_{ij}\bigr)
z^d_{ij}(\lambda,\hat r,\hat c)\,d\lambda\\
&\approx\sum_{\lambda}
\mathcal L_{\mathrm{DDL}}(\lambda,r,c,\hat r,\hat c).
\end{aligned}
$$

这里应特别区分两件事：

- **选动作时**，模型依据预测净收益 $\hat r_{ij}-\lambda\hat c_{ij}$ 排序；
    

- **评价这套排序是否正确时**，理想上要看真实的净收益 $r_{ij}-\lambda c_{ij}$。
    

又因为真实表不可见、指示函数不可导，DFCL 才在下一节用 PLL / MER 的 softmax 代理，或 IFD 的 EOM + 有限差分，来近似这个对偶决策损失的训练梯度。对偶本身不是因果识别方法；它解决的是预算耦合、预算波动和大规模求解问题。

## 7. 三条训练路径：PL、MER、IFD 分别怎样让决策损失可训练？

这一节解决同一个训练难题。给定预测结果面后，分配器会用预测净价值

$$
\hat q_{ij}(\lambda)=\hat r_{ij}-\lambda\hat c_{ij}
$$

选动作：

$$
z^d_{ij}(\lambda)
=\mathbb I\!\left[
j=\arg\max_k\bigl(\hat r_{ik}-\lambda\hat c_{ik}\bigr)
\right].
$$

但这个硬选择有两个问题：

1. $\mathbb I[\arg\max]$ 是离散的，绝大多数微小预测变化都不会改变动作，自动微分得到的梯度为 0；
2. 即使动作变了，也只看得到日志实际动作 $t_i$ 的收益和成本，看不到未选动作的真实结果。

三种方法的共同目标都是：让模型学会提高“真实净收益高”的动作分数，同时压低“真实净收益低”的动作分数；不同点在于它们如何绕开硬 $\arg\max$、以及如何从 RCT 的事实结果中得到训练信号。

| 方法 | 核心办法 | 是否平滑硬决策 | 决策质量怎样结算 | 主要取舍 |
|---|---|---|---|---|
| DFCL-PL | 直接将 $\arg\max$ 换成 softmax 概率 | 是，无温度 softmax | RCT 事实样本的重加权期望净收益 | 最简单、高效，但训练目标是软策略 |
| DFCL-MER | 从“连续动作 + 最大熵正则”推导带温度 softmax | 是，温度 $\tau$ 可调 | 同样用 RCT 重加权 | 有明确优化推导，但 $\tau$ 带来软硬偏差 |
| DFCL-IFD | 保留原始离散分配器，将其当黑箱评估 | 不必先平滑 | EOM 无偏估计策略价值，再有限差分估梯度 | 最贴近原问题，但训练计算更重 |

> 名称容易混淆：论文的事实**预测损失**记作 $\mathcal L_{\mathrm{PL}}$；DFCL-PL 中的 PL 指 **Policy Learning**，其决策项记作 $\mathcal L_{\mathrm{PLL}}$。

### 7.1 共同底座：RCT 怎样把“只见事实结果”变成可训练信号？

无论 PL 还是 MER，都无法直接计算“所有动作的真实净收益”。对 RCT 样本，动作 $t_i$ 的分配概率已知，或可由每档样本数表示。因此，对事实动作乘以逆概率权重 $\frac{N}{N_{t_i}}$，可以在总体上无偏地补回“若所有人都采取该动作”的期望。

简单地说：某动作在 RCT 中被随机分得较少，就让这部分样本在损失中权重更大；被随机分得较多，则单样本权重更小。它不是在为单个人虚构反事实，而是在用随机实验的总体可比性构造无偏训练目标。

### 7.2 DFCL-PL：直接把硬选择换成 softmax 概率

PL 先将“给 $i$ 选哪档券”的硬选择改为一个软策略：

$$
p_{ij}(\lambda)
=\frac{\exp\bigl(\hat r_{ij}-\lambda\hat c_{ij}\bigr)}
{\sum_k\exp\bigl(\hat r_{ik}-\lambda\hat c_{ik}\bigr)}.
$$

$p_{ij}$ 可以理解为模型将动作 $j$ 分给 $i$ 的软概率。于是原来不可导的“选中哪档”变成了可导的“各档占多大概率”，理想目标变为最大化真实净收益的期望。

但真实 $(r_{ij},c_{ij})$ 仍不可全见，所以论文用 RCT 事实动作构造 Policy Learning Loss：

$$
\mathcal L_{\mathrm{PLL}}
=-\sum_{\lambda}\sum_i
\frac{N}{N_{t_i}}
\bigl(r_{i,t_i}-\lambda c_{i,t_i}\bigr)
p_{i,t_i}(\lambda).
$$

这条式子的含义可以逐项读：

- $\bigl(r_{i,t_i}-\lambda c_{i,t_i}\bigr)$：该用户在其真实被分配动作下，实际观察到的净收益；
- $p_{i,t_i}$：模型给这个事实动作分配的软概率；
- $\frac{N}{N_{t_i}}$：RCT 重加权，修正不同 treatment 样本量不同的问题；
- 负号：训练最小化损失，等价于让高净收益事实动作获得更高概率。

因此，若某用户随机拿到 5 元券后确实带来高净收益，梯度会提高 $\hat q_{i,5}$，并通过 softmax 相对压低其他券档的概率。论文证明，在 RCT 假设下，这个 surrogate 与平滑后的对偶决策目标具有相同最优解。

![[DFCL PL MER derivation.png|650]]

上图左栏是论文从硬 $\arg\max$、到 softmax、再到 $\mathcal L_{\mathrm{PLL}}$ 的原始推导。要注意：PL 训练的是软策略；在线仍可使用预算分配器输出硬动作，而不是按概率随机发券。

### 7.3 DFCL-MER：用最大熵正则得到“可控软硬程度”的 softmax

PL 已经用了 softmax，但 MER 进一步给出它从哪里来。它先将 $z_{ij}\in\{0,1\}$ 放松为连续分配比例 $z_{ij}\in[0,1]$，再在预测净收益上加入最大熵正则：

$$
\max_z\ 
\sum_{i,j}\bigl(\hat r_{ij}-\lambda\hat c_{ij}\bigr)z_{ij}
-\tau\sum_{i,j}z_{ij}\ln z_{ij},
\qquad
\text{s.t.}\ \sum_jz_{ij}=1.
$$

求这个连续问题的一阶条件，得到闭式解：

$$
z^d_{ij}(\lambda)
=\frac{
\exp\!\left[(\hat r_{ij}-\lambda\hat c_{ij})/\tau\right]
}{
\sum_k\exp\!\left[(\hat r_{ik}-\lambda\hat c_{ik})/\tau\right]
}.
$$

这里的 $\tau$ 是温度：

- $\tau$ 较大：概率更均匀，梯度平滑，但与最终硬分配差得更远；
- $\tau\rightarrow0$：更接近硬 $\arg\max$，但概率容易饱和，优化会更不稳定。

再将真实结果替换为 RCT 事实结果并重加权，得到 $\mathcal L_{\mathrm{MERL}}$；它与 $\mathcal L_{\mathrm{PLL}}$ 的差别仅在 softmax 内多了温度 $\tau$。论文明确指出：**PL 是 MER 在 $\tau=1$ 时的特例。**实验中作者在 CRITEO-UPLIFT v2 使用 $\tau=3$，在多 treatment 营销数据上使用 $\tau=0.01$，说明温度必须按数据与任务调节，并非固定常数。

**PL 与 MER 的关系。** 两者都用“softmax + RCT 重加权”避开不可导与反事实；PL 直接给出平滑策略，MER 则从最大熵正则的连续优化推导出带温度的策略。它们不是完全不同的模型，而是同一类 surrogate 的不同参数化。

### 7.4 DFCL-IFD：不替换硬分配器，而是直接估计“改一点预测会让策略好多少”

IFD 走另一条路线：不要求把硬分配器近似为 softmax，而是保留“预测结果面 → 求解器 → 硬策略”的原始链路，将整条链路视为黑箱。

第一步是 EOM（Expected Outcome Metric）。给定预测结果面与由它产生的策略，只保留“RCT 中实际动作恰好等于策略建议动作”的样本，并按治疗概率 $p_{t_i}$ 做逆概率加权：

$$
\bar r
=\frac1N\sum_i
\frac{r_{i,t_i}}{p_{t_i}}
\mathbb I\!\left[t_i=\pi(x_i)\right],
\qquad
\bar c
=\frac1N\sum_i
\frac{c_{i,t_i}}{p_{t_i}}
\mathbb I\!\left[t_i=\pi(x_i)\right].
$$

其中 $\pi(x_i)$ 是分配器建议给 $i$ 的动作。这样可以无偏估计这套策略的人均收益与成本，并据此得到多个预算下的策略损失 $\mathcal L_{\mathrm{DL}}$。

第二步是有限差分：轻微增加某一个预测 $\hat r_{ij}$，重新观察策略损失改变多少：

$$
\frac{\partial\mathcal L_{\mathrm{DL}}}{\partial\hat r_{ij}}
\approx
\frac{
\mathcal L_{\mathrm{DL}}(\hat r+h e^{ij},\hat c)
-\mathcal L_{\mathrm{DL}}(\hat r,\hat c)
}{h}.
$$

$e^{ij}$ 只在第 $i,j$ 个位置为 1，$h$ 是很小的扰动。如果抬高某个预测后，分配器因此换了券档且 EOM 评估更好，这个方向就应该被模型学习；若策略与价值没有变，梯度就接近 0。这正是 IFD 能对齐真实硬决策的原因。

![[DFCL IFD derivation.png|650]]

上图是论文对 EOM 和普通有限差分的原式。朴素做法要对每个 $i,j$ 都扰动并重新求解一次大规模 MCKP，百万级样本会非常慢。论文的“Improved”在于利用拉格朗日对偶后逐人可分解的结构：先求出会改变该个体动作的最小扰动，再只修正发生变化的那部分结果，而不是每次重新求解整批背包；同时会截断扰动矩阵，并可对动作分数做 softmax 平滑以改善数值稳定性。

**三者怎样选？** PL/MER 的训练代价接近普通可微模型，适合先获得稳定、可扩展的决策训练；IFD 对原始离散分配目标更直接，但评估与扰动代价更高。论文离线结果中 IFD 最强，不代表它在所有数据规模与工程约束下都必然最优。

## 8. 训练、上线流程

论文的 Algorithm 1 是整个训练闭环的最短版本：先预测完整结果面，再在多个预算下计算分配策略与决策损失，最后将预测损失和决策损失一起反传。

![[DFCL Algorithm 1.png|600]]

### 8.1 训练时

1. 从 RCT 取一个 batch：
   $$
   \mathcal D=\{(x_i,t_i,r_{i,t_i},c_{i,t_i})\}_{i=1}^{N}.
   $$
2. 结果模型输出每个动作下的预测：
   $$
   (\hat r,\hat c)=m_\omega(x).
   $$
3. 用事实动作计算预测损失 $\mathcal L_{\mathrm{PL}}$，保证结果面数值不漂移；
4. 对一个或多个预算 $B$（等价地，对多个影子价格 $\lambda$），由预测结果面得到策略
   $$
   z^*(B,\hat r,\hat c)=\arg\max_zF(z,B,\hat r,\hat c);
   $$
5. 用 PL、MER 或 IFD 构造可训练的决策项 $\mathcal L_{\mathrm{decision}}$；
6. 合并损失并更新参数：
   $$
   \mathcal L_{\mathrm{DFCL}}
   =\alpha\mathcal L_{\mathrm{PL}}+\mathcal L_{\mathrm{decision}},
   \qquad
   \omega\leftarrow\omega-\eta\nabla_\omega\mathcal L_{\mathrm{DFCL}}.
   $$

### 8.2 上线时

```
当前个体特征 x
→ 训练好的 m_ω 输出所有动作的 r̂、ĉ
→ 当前预算 B / 动态 λ 的分配器
→ 最终动作 z。
```

线上不再运行事实预测损失、RCT 重加权、EOM 或有限差分；这些属于训练和离线评估。DFCL 的线上主体仍是“结果面模型 + 预算分配器”。

## 9. 实验结果：预测指标、决策质量与多预算收益

论文使用两个 RCT 数据集：CRITEO-UPLIFT v2 约 1390 万样本，做二元 treatment 的 uplift/排序评估；营销数据约 280 万样本、107 个特征、5 个折扣档位，评估多 treatment 的预算分配。二元场景的核心指标是 AUCC；多档券场景使用基于 RCT 的 EOM 估计给定策略下的人均订单/收益。下面三张表不在回答三个不同问题。

### 9.1 Table 1：预测误差更低，是否就代表最终决策更好？

Table 1 只看普通预测指标：CRITEO 的 Logloss 与营销数据的 MSE，越小越好。`TSM-SL` 是常规两阶段 S-Learner；`DFCL-PL / MER / IFD` 分别是本文三种决策聚焦训练方式。`DPM` 与 `TSM-CF` 输出的是 decision factor 或增量干预效应，而不是同一形式的完整结果面，因此论文没有把它们填进这两个通用预测指标。

![](https://didoc.didichuxing.com/api/uploadfile?b=didoc2-upload-file-prod&k=images%2F1786375089688%2F_ubMCizNBY6VnZNCViZdf%2FDFCL_Table_1.png&filename=DFCL+Table+1.png)

只按 Logloss/MSE，TSM-SL 最好：CRITEO Logloss 为 ，营销数据 MSE 为 ；DFCL-IFD 分别为 、，略差。这个结果不是 DFCL 失败，反而正好验证论文的出发点：决策损失会把模型容量更集中在“会改变预算分配的边界样本”上，未必把全体样本的平均数值误差压到最低。

**本表结论。** 不能拿 MSE/Logloss 单独宣布 DFCL 优劣；DFCL 的主张必须转到下游决策质量上验证。代价是它在普通预测指标上可能略有回退，因此训练中才保留 作为稳定性与泛化约束。

### 9.2 Table 2：在二元干预下，排序出的“增量价值”是否更好？

AUCC 衡量从高到低按模型策略排序、逐步增加干预成本时，累计增量收益曲线下面积；越大表示模型越早找到了“高增量、成本合理”的对象。`Improvement` 是相对 TSM-SL 的提升。

![](https://didoc.didichuxing.com/api/uploadfile?b=didoc2-upload-file-prod&k=images%2F1786375113675%2FRKc_snOToXmnRfXDNTJZB%2FDFCL_Table_2.png&filename=DFCL+Table+2.png)

**如何读表。** DFCL-IFD 达到，是全部方法最高，较 TSM-SL 的 提升；DFCL-PL 和 DFCL-MER 分别为 、，与 DPM 的 接近，但不如 IFD。也就是说，保留原始离散决策结构、以 EOM 加改进有限差分估梯度的 IFD，在该二元场景中最有效。

![](https://didoc.didichuxing.com/api/uploadfile?b=didoc2-upload-file-prod&k=images%2F1786375128021%2FRxNRYukOCZVNz1K2mhhCL%2FPasted_image_20260730214001.png&filename=Pasted+image+20260730214001.png)

上图是 Table 2 的曲线版本：横轴为累计增量成本，纵轴为累计增量收益。曲线越靠左上、面积越大，意味着在同样花费下得到更多增量收益；它评估的是策略排序后的累计价值，而不是单个样本的 MSE。

**本表结论。** 在论文的 CRITEO RCT 评估协议中，DFCL-IFD 把“预测结果面”转化为了更好的实际干预排序；这是 Table 1 无法回答的问题。

### 9.3 Table 3：多档优惠、不同预算下，分配器的最终收益是否更高？

Table 3 切换到营销多 treatment 场景。每一列 Budget 是一个人均预算水平，表中数值是 EOM 估计的对应策略收益；最后一列是相对 TSM-SL 的整体提升。这里最关键的是：同一个模型不是只在一个预算点取巧，而要在 1–6 的不同预算下都做好资源分配。

![](https://didoc.didichuxing.com/api/uploadfile?b=didoc2-upload-file-prod&k=images%2F1786375144642%2FLAK468eNnJzb_PNN5yjGV%2FDFCL_Table_3.png&filename=DFCL+Table+3.png)

DFCL-IFD 在 6 个预算点上均为最高：从预算 1 的到预算 6 的，整体相对 TSM-SL 提升 ；DFCL-MER、DFCL-PL 的整体提升为 、，也高于 DPM 的 。`CN+DFCL-PL` 比 CN 多 个百分点（对），说明 DFCL 的损失可以接在已有 constrained network 上；但它仍不如直接的 DFCL-PL，论文推测是网络内预设约束限制了决策空间。

![](https://didoc.didichuxing.com/api/uploadfile?b=didoc2-upload-file-prod&k=images%2F1786375158096%2F2YqUpQY78sNN7Cia3wnTH%2FPasted_image_20260730214002.png&filename=Pasted+image+20260730214002.png)

上图是 Table 3 的曲线版本：横轴为预算，纵轴为 EOM 的增量收益。DFCL-IFD 曲线在图中始终更高，表明增益不是只集中在单个预算档位。

**本表结论。** DFCL 的实证价值不只是提高单点排序指标，而是在论文的多档优惠、预算分配和 RCT 反事实评估协议下，跨预算地改善最终分配收益；其中 IFD 是离线实验中最强的版本。
