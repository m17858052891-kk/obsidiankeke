

论文：[Bi-Level Decision-Focused Causal Learning for Large-Scale Marketing Optimization: Bridging Observational and Experimental Data](https://arxiv.org/abs/2510.19517)  
会议：NeurIPS 2025  
原图：Figure 1（预算分配问题）、Figure 2（Bi-DFCL 总体架构）

## 1. 一句话总结

**Bi-DFCL 不改变最终线上模型“预测每个 treatment 的收益和成本，再做预算分配”的形式；它改变的是训练 Target 的方式：让海量但有偏的 OBS 提供规模，让稀缺但无偏的 RCT 用最终决策质量来校正 OBS 中缺失反事实标签的融合方式。**

最短的因果链是：

~~~text
Bridge φ
→ OBS 反事实伪标签
→ Target 的临时最优参数 θ*(φ)
→ 预测结果面 r̂、ĉ
→ 预算分配策略 z*
→ RCT 上的无偏决策价值
→ 反向更新 Bridge φ。
~~~

因此它不是三张预测结果面相加，也不是线上将三个网络串行运行；它是一个训练期双层优化框架。

## 2. 先理解它要解决的矛盾

营销/发券中，对个体 $i$ 和动作 $j$，真实但不可同时观测的结果是：

$$
r_{ij}=\text{收益},\qquad c_{ij}=\text{成本}.
$$

同一个人只能实际拿到一个动作 $t_i$，日志中只看得到：

$$
(x_i,t_i,r_{i,t_i},c_{i,t_i}).
$$

| 数据 | treatment 如何产生 | 能提供什么 | 主要问题 |
|---|---|---|---|
| RCT，$\mathcal D_{\rm RCT}$ | 随机分配 | 无偏的事实结果；可无偏评估策略价值 | 贵、样本少、对细分人群和多券档的结果面方差高 |
| OBS，$\mathcal D_{\rm OBS}$ | 旧策略选择 | 大样本、丰富场景、稳定的特征覆盖 | 选择偏差与混杂：高券后订单高，不代表高券造成订单高 |

DFCL 已经处理“预测 MSE 最小不等于预算策略最好”。Bi-DFCL 再处理：

> 若仅用 RCT，方向可信但学不稳；若让 OBS 直接决定反事实，又可能把旧策略偏差写进结果面。怎样让 RCT 决定 OBS 应被怎样使用？

### 2.1 RCT 与 OBS 的偏差-方差矛盾

这组矛盾不是“RCT 一定比 OBS 好”或“OBS 样本多就足够”，而是两类数据各自解决了不同的问题：

- **RCT：低偏差、高方差。**treatment 是随机分配的，因此券额与用户原本的购买意愿不系统相关。它可以无偏地估计干预带来的增量；但实验昂贵，按用户类型和券档继续切分后，每个局部结果面的估计会不稳定。
- **OBS：低方差、高偏差。**历史日志规模大、特征覆盖广，拟合通常更稳定；但旧策略会选择性地给某些用户发券，导致用户原本的购买意愿、场景和券额混在一起。

例如旧策略只给高活跃用户发 10 元券，OBS 中可能观察到：

$$
\mathbb E[Y\mid T=10] > \mathbb E[Y\mid T=0].
$$

这只说明“实际拿到 10 元券的人订单更多”，不等于券本身带来了正向增量：

$$
\mathbb E[Y(10)-Y(0)] > 0.
$$

前一个是带混杂的观测相关性，后一个才是我们希望用于资源分配的因果效应。于是：只用 RCT，方向可信但对细粒度人群和多券档的决策容易抖动；只用 OBS，结果平滑却可能稳定地学到旧策略偏差。

Bi-DFCL 的分工正是：**让 OBS 提供样本规模与特征覆盖，让 RCT 上无偏的最终决策质量决定 OBS 反事实信息应被如何相信。**它不只是把两份数据拼接训练，而是让 RCT 的上层决策损失反向校正 Bridge 对 OBS 伪标签的融合比例。

### 2.2 为什么百万级 RCT 仍可能“不够”？

“RCT 样本够不够”没有一个固定的总样本阈值。关键不是总人数，而是每个需要决策的“用户类型 $\times$ 券档 $\times$ 场景”单元中，有多少随机分配样本和有效结果。

粗略地说，某个局部单元的有效样本量会随以下切分迅速减少：

$$
N_{\mathrm{effective}}
\approx
\frac{N_{\mathrm{RCT}}}{\text{treatment 数}}
\times \text{人群占比}
\times \text{结果事件率}.
$$

例如 $220$ 万 RCT 样本分到 $8$ 个券档后，平均每档约 $27.5$ 万；若某类用户只占 $2\%$，该券档约剩 $5{,}500$ 人；若目标事件率为 $1\%$，真正观察到的正反馈约只有 $55$ 个。对于“该类用户是否应发这档券、发券的增量收益是否值得预算”的判断，这个信号可能仍有很大方差。

论文的 Marketing Data I 正好说明了这一点：它使用约 $222$ 万 RCT 训练样本和约 $2{,}220$ 万 OBS 样本。作者将 RCT-only 模型作为无偏参考，但仍将其性能限制归因于相对较小样本量带来的高方差；在大规模 OBS 与适量 RCT 融合后，EOM 更高。这里的“样本不足”是**相对于 8 个 treatment、180 个特征和预算分配任务的细粒度结果面而言**，不是说 $222$ 万在绝对数量上很少。[论文的样本量分析](https://arxiv.org/html/2510.19517)

因此，判断 RCT 是否足够，更应看决策稳定性而不是一个固定数字：

1. 关键券档、人群和场景是否都有随机曝光与有效正反馈，而不是存在近零覆盖的单元。
2. 将 RCT 随机切分或重采样后，预算分配策略在独立 RCT 上的 EOM / AUCC 置信区间是否足够窄，选人和选券是否频繁翻转。
3. 继续增加 RCT 后，独立 RCT 上的 EOM 是否已基本不再提升；若仍持续提升，说明方差仍是瓶颈。

如果只做传统两组均值检验，每个 treatment arm 的样本量通常还与要检测的最小增量效果 $\delta$、结果方差 $\sigma^2$、显著性水平和统计功效有关：

$$
n_{\mathrm{per\ arm}}
\approx
\frac{2(z_{1-\alpha/2}+z_{1-\beta})^2\sigma^2}{\delta^2}.
$$

但 Bi-DFCL 的问题比全局 ATE 更难：它需要为高维结果面和预算分配提供稳定的因果排序，因此不能只用这一条全局公式给出统一的“够用样本量”。

## 3. 下游究竟优化什么：Target 输出不是最终券档

Target 对每个个体、每个 treatment 输出完整结果面：

$$
\mathcal F_\theta(x_i)
=\{(\hat r_{ij},\hat c_{ij})\}_{j=1}^{M}.
$$

例如券档为 $\{0,2,4,6\}$ 元，Target 输出四组收益/成本预测；它不直接分类出 4 元券。

最终动作来自一个全局预算分配问题：

$$
\begin{aligned}
\max_z\quad&\sum_i\sum_jz_{ij}\hat r_{ij}\\
\text{s.t.}\quad&\sum_i\sum_jz_{ij}\hat c_{ij}\le B,\\
&\sum_jz_{ij}=1,\quad z_{ij}\in\{0,1\}.
\end{aligned}
$$

$z_{ij}=1$ 才表示“给 $i$ 选了 $j$”。通常把不干预/0 元券作为成本为 0 的一个动作，因此每人仍恰好选一个动作。

分配器可通过影子价格 $\lambda^*$ 实现近似求解：先比较

$$
g_{ij}=\hat r_{ij}-\lambda^*\hat c_{ij},
$$

再选择每个人净价值最高的档位。若预测总成本超预算，提高 $\lambda$；若预算仍有余量，降低 $\lambda$。二分搜索可找到使成本接近 $B$ 的 $\lambda^*$。这对应 Figure 2 右侧红框中的 Operation Research：

$$
z^*(\hat r,\hat c)=\mathcal A(H(\hat r,\hat c)).
$$

## 4. 先看 Figure 2：图中每一块在回答什么

![[Pasted image 20260730214003.png]]

从左到右是三段不同性质的计算：

| 图中区域 | 输入 | 做的事 | 输出 | 谁被更新 |
|---|---|---|---|---|
| 左：Lower-level Optimization | OBS、Teacher、Bridge | 构造事实/反事实标签，训练 Target 的预测能力 | 临时 Target 参数 $\hat\theta(\phi)$ | 临时更新 Target；正式下层阶段更新 Target |
| 中：Implicit Differentiation | 下层最优条件与上层梯度 | 计算“Bridge 改一点，最优 Target 会怎样变” | $d\theta^*/d\phi$ 的作用结果 | 为更新 Bridge 提供链式梯度 |
| 右：Upper-level Optimization | 临时 Target、RCT、预算分配器 | 评估“这种伪标签融合训练出来的策略是否真更好” | 决策损失 $\mathcal L_{\rm DL}$ 及其对结果面的梯度 | 更新 Bridge |

需要注意图的两类箭头：

- 实线从左到右：前向计算和数值传递；
- 从右回到左/中间的偏导箭头：训练信号和梯度传递。

接下来按图的顺序走完整一轮。

## 5. 图左：Teacher、Bridge 与 OBS 下层预测损失

### 5.1 Teacher：只提供 RCT 锚点，不直接上线

先在 RCT 上用普通预测损失预训练 Teacher $\mathcal F_\psi$，再冻结：

$$
(\hat r^{\rm pre}_{ij},\hat c^{\rm pre}_{ij})
=\mathcal F_\psi(x_i,j).
$$

它的作用不是保证每个格子绝对正确，而是提供一个相对无偏的参考点：由于 treatment 随机，Teacher 不容易把“旧策略偏好给谁发券”误学成券效。

### 5.2 Bridge：两个 gate，融合两张已有预测表

Bridge $\mathcal G_\phi$ 不是第三张收益/成本结果面。对样本 $i$、动作 $j$，它输出：

$$
\begin{aligned}
w^r_{ij}&=\operatorname{sigmoid}(\mathcal G^r_\phi(i,j)),\\
w^c_{ij}&=\operatorname{sigmoid}(\mathcal G^c_\phi(i,j)).
\end{aligned}
$$

随后融合 Teacher 与当前 Target 的预测：

$$
\begin{aligned}
r^{\rm cf}_{ij}
&=w^r_{ij}\hat r^{\rm pre}_{ij}+(1-w^r_{ij})\hat r_{ij},\\
c^{\rm cf}_{ij}
&=w^c_{ij}\hat c^{\rm pre}_{ij}+(1-w^c_{ij})\hat c_{ij}.
\end{aligned}
$$

| gate 值 | 融合含义 |
|---|---|
| $w=1$ | 完全采用 Teacher 预测 |
| $w=0$ | 完全采用当前 Target 预测 |
| $0<w<1$ | 两者软融合 |

收益与成本各用一个 gate，因为“谁会下单”的偏差模式与“券会不会核销、实际花多少钱”的偏差模式不必相同。

例如 OBS 中有一位高活跃用户，旧策略经常给其 8 元券且他常下单。Teacher 依据 RCT 认为 8 元券收益为 $0.20$，当前 Target 受旧策略偏差影响预测为 $0.50$。若 Bridge 给出 $w^r=0.8$：

$$
r^{\rm cf}=0.8\times0.20+0.2\times0.50=0.26.
$$

Target 便不会被 OBS 中“高券后订单高”的表象直接推向 $0.50$。

#### 这不是“检索相似历史样本的真实标签”

Bridge 生成的反事实伪标签，**不是**为当前 OBS 样本找一个历史上相似的人，再将那个相似人的事实结果搬过来。

若当前 OBS 样本 $i$ 实际拿到 8 元券，则日志只提供：

$$
(x_i,t_i=8,r_{i,8},c_{i,8}).
$$

其中 $r_{i,8},c_{i,8}$ 是当前样本自己的事实标签，直接用于下层训练；但它拿 0、3、5 元券会怎样，历史里并没有这个人的真实结果。对某个未执行动作，例如 5 元券，实际计算是：

$$
\begin{aligned}
\hat r^{\rm pre}_{i,5}
&=\text{Teacher 输入同一个 }x_i\text{ 后，对 5 元券的反事实预测},\\
\hat r_{i,5}
&=\text{当前 Target 输入同一个 }x_i\text{ 后，对 5 元券的反事实预测},\\
r^{\rm cf}_{i,5}
&=w^r_{i,5}\hat r^{\rm pre}_{i,5}
+(1-w^r_{i,5})\hat r_{i,5}.
\end{aligned}
$$

因此正确的数据流是：

~~~text
同一个 OBS 样本的特征 x_i
→ Teacher / Target 分别预测“该样本若执行未发生动作”的结果
→ Bridge 融合两份预测
→ 形成该样本的反事实伪标签。
~~~

Teacher 与 Target 在训练时当然会从大量历史样本中学习“哪些特征模式的人对哪档券反应相近”，所以预测会间接利用群体相似性；但论文没有显式做 nearest-neighbor 检索，也没有把别人的事实标签直接当成当前人的反事实标签。

### 5.3 Lower-level Prediction Loss：OBS 如何真正更新 Target

对 OBS 样本的事实动作 $t_i$，有日志真实标签，Target 直接拟合：

$$
(r_{i,t_i},c_{i,t_i}).
$$

对未执行的动作 $j\ne t_i$，没有真实反事实标签，则让 Target 拟合 Bridge 给出的伪标签：

$$
(r^{\rm cf}_{ij},c^{\rm cf}_{ij}).
$$

用平方损失表示，下层目标可理解为：

$$
\begin{aligned}
\mathcal L_{\rm PL}(\phi,\theta;\mathcal D_{\rm OBS})
=&\ \mathbb E_{i}\bigl[
(r_{i,t_i}-\hat r_{i,t_i})^2
+(c_{i,t_i}-\hat c_{i,t_i})^2
\bigr]\\
&+\mathbb E_{i}\sum_{j\ne t_i}\bigl[
(r^{\rm cf}_{ij}-\hat r_{ij})^2
+(c^{\rm cf}_{ij}-\hat c_{ij})^2
\bigr].
\end{aligned}
$$

这就是 Figure 2 左侧粉色框 $\mathcal L_{\rm PL}(\phi,\theta;\mathcal D_{\rm OBS})$：

- 它对 $\theta$ 可微，因此普通反向传播可以更新 Target；
- 它的标签中含 Bridge 输出，所以它也依赖 $\phi$；
- 但在下层优化中，直接被最小化的是 $\theta$，不是让 Bridge 只为降低 OBS 拟合误差而随意调整。

给定 Bridge，真正想得到的下层最优 Target 为：

$$
\theta^*(\phi)
=\arg\min_\theta\mathcal L_{\rm PL}(\phi,\theta;\mathcal D_{\rm OBS}).
$$

### 5.4 当前 Target 的预测到底来自 OBS 还是 RCT？

最准确的答案是：**当前 Target 的参数主要由 OBS 下层损失训练；但它不是“只拟合 OBS 事实标签”的普通 OBS-only 模型。**

在图左的 OBS batch 上，当前 Target 的预测是：

$$
(\hat r_{ij}^{\rm OBS},\hat c_{ij}^{\rm OBS})
=\mathcal F_\theta(x_i^{\rm OBS},j).
$$

它通过两类监督被更新：

1. OBS 已执行动作的真实事实标签；
2. 对 OBS 未执行动作，由 Bridge 融合 Teacher 与当前 Target 得到的反事实伪标签。

因此可将它称为“**以 OBS 为主要训练数据、受 RCT 间接校正的 Target**”。它既不同于只用 RCT 训练的 Teacher，也不同于完全忽略 RCT 的 OBS-only outcome 模型。

到了图右上层，参数不变的临时 Target 会被应用到 **RCT 用户特征** 上：

$$
(\hat r_{ij}^{\rm RCT},\hat c_{ij}^{\rm RCT})
=\mathcal F_{\hat\theta}(x_i^{\rm RCT},j).
$$

这里不是再用 RCT 对 Target 做一轮 MSE 监督训练；而是把“由 OBS 教出来的临时 Target”拿到无偏 RCT 上，检查它经过预算分配后的策略是否有效。若效果不好，RCT 梯度更新的是 Bridge，Bridge 再改变下一轮 OBS 训练 Target 时使用的反事实伪标签。

~~~text
OBS：直接训练 Target 的结果面。
RCT：不直接用预测 MSE 教 Target；通过决策质量间接教 Bridge。
Bridge：改变 OBS 的伪标签，从而在下一轮间接改变 Target。
~~~

## 6. 图中：为什么复制 Target，什么是 assumed update

若要知道 Bridge 的某个 gate 是否好，必须知道：

> “如果我用这个 Bridge 生成伪标签，并让 Target 真正在 OBS 上学一段时间，Target 最终会变成什么样？”

这个“学完后的 Target”就是 $\theta^*(\phi)$。但每次更新 Bridge 都把 Target 完全训练到收敛会很贵。因此 Figure 2 中先复制 $\mathcal F_\theta$ 到 $\mathcal F_{\hat\theta}$，在副本上做 $K$ 次 assumed update：

$$
\begin{aligned}
\hat\theta^{(0)}&=\theta,\\
\hat\theta^{(k+1)}
&=\hat\theta^{(k)}
-\eta\nabla_\theta
\mathcal L_{\rm PL}(\phi,\hat\theta^{(k)};\mathcal D_{\rm OBS}),\\
\hat\theta(\phi)&=\hat\theta^{(K)}.
\end{aligned}
$$

这里的 assumed 不是伪造数据，而是**假设 Target 会沿当前下层损失更新若干步**，用副本近似“若 Bridge 取当前参数，Target 将来会被训练成什么样”。此阶段不修改正式部署候选的 $\theta$。

### 6.1 它实际在替 Bridge 回答什么问题

Bridge 的 gate $w$ 不是一个可以单独用“预测误差小不小”判断好坏的量。它决定了反事实伪标签更偏向 Teacher 还是当前 Target；伪标签又会进入 OBS 的下层训练；因此 Bridge 真正需要回答的是：

> 若我采用当前这套 gate，让 Target 继续在 OBS 上学习，最后形成的收益/成本预测表，经过真实预算分配后是否更好？

可把依赖关系写成：

$$
\phi
\longrightarrow
\text{Bridge 融合的反事实伪标签}
\longrightarrow
\theta^*(\phi)
\longrightarrow
\bigl(\hat r,\hat c\bigr)
\longrightarrow
z^*
\longrightarrow
\mathcal L_{\rm DL}.
$$

其中 $\theta^*(\phi)$ 表示：**在 Bridge 参数为 $\phi$ 时，Target 若充分按下层 prediction loss 训练后会到达的参数。**真正想比较的是最右端的决策质量，而不只是某一格伪标签看起来是否合理。

### 6.2 为什么不能直接把正式 Target 训练到收敛再评估

理论上，可以每尝试一组 Bridge 参数 $\phi$，都重新训练一个 Target 至收敛，再在 RCT 上跑预算分配并比较结果；但这样每更新一次 Bridge 都要完成一次完整的 Target 训练，代价无法接受。

论文因此不直接得到精确的 $\theta^*(\phi)$，而从**当前正式 Target** $\theta$ 复制一个临时副本 $\hat\theta$，只模拟 $K$ 步下层训练，以 $\hat\theta^{(K)}$ 作为局部近似。这里的 assumed 表示“假设接下来按当前下层目标训练 $K$ 步会怎样”，不是假造新的 OBS 或 RCT 数据。

### 6.3 用一个券档例子走完这 $K$ 步模拟

假设用户 A 在 OBS 中实际领过 0 元券；对未实际发出的 8 元券，Teacher 预测增量收益为 $4$，当前 Target 预测为 $12$。若 Bridge 给出 $w^r_{A,8}=0.8$，则用于训练的反事实收益标签约为：

$$
\tilde r_{A,8}=0.8\times4+0.2\times12=5.6.
$$

这会让临时 Target 在第 1 步更新时，不再把“8 元券收益 12”当作唯一学习方向，而是向 $5.6$ 靠近；后续 $K-1$ 步仍会受这类融合标签、事实标签及其他 OBS 样本共同影响。完成 $K$ 步后，得到的是一张新的、受当前 Bridge 影响的临时收益/成本表，而不是只改变了 A 的一个数。

接着将这张表用于 RCT 用户的预算分配。若它仍倾向把大量 8 元券给高活跃、原本就容易下单的人，而 RCT 的无偏结果显示真实增量很小，右侧决策损失就会变差。随后梯度会推动 Bridge 调整：例如在这类用户和券档上减少对当前 Target 的盲目信任，或学习到更合适的融合比例。

### 6.4 副本和正式 Target 各自负责什么

| 对象 | 是否真正部署/保留 | 作用 |
|---|---|---|
| 正式 Target $\mathcal F_\theta$ | 是 | 持续接受 OBS 下层训练；训练结束后作为线上收益、成本预测模型。 |
| 临时副本 $\mathcal F_{\hat\theta}$ | 否 | 从当前 $\theta$ 拷贝后做 $K$ 步模拟，用来衡量“当前 Bridge 会把 Target 带向哪里”。 |
| Teacher $\mathcal F_{\theta^T}$ | 否 | 已由 RCT 预训练并冻结，为 Bridge 的伪标签融合提供相对无偏的预测参照。 |

因此，图中的 **Model Snapshot $\mathcal F_{\hat\theta}$ 不是 Teacher，也不是第二个将要上线的 Target**；它是 Bridge 上层训练时的一次“试运行结果”。等 Bridge 根据 RCT 信号更新后，才会用更新后的 Bridge 重新构造 OBS 伪标签，真正更新正式 Target $\theta$。

然后，副本 Target 输出：

$$
(\hat r,\hat c)=\mathcal F_{\hat\theta(\phi)}(x).
$$

这就是图中间 Model Snapshot $\mathcal F_{\hat\theta}$ 的来源。它把 Bridge 的影响转化为一个可在 RCT 上检验的完整结果面。

## 7. 图右：RCT 如何把“预测表”变成“决策质量”

### 7.1 分配器的前向传导

临时 Target 的 $\hat r,\hat c$ 进入预算分配器：

$$
z^*(\hat r,\hat c)=\mathcal A(H(\hat r,\hat c)).
$$

这一步只使用预测结果面来选择策略；它不使用 RCT 的真实结果替模型“作弊”选动作。

随后才用 RCT 评价策略 $z^*$。在 RCT 中，用户 $i$ 只随机实际执行了 $t_i$，因此利用 IPW 构造无偏的策略价值估计：

$$
\mathcal L_{\rm DL}
=-\mathbb E_{i,t_i}
\left[
\frac{N}{N_{t_i}}
z^*_{i,t_i}r_{i,t_i}
\right].
$$

其中：

- $z^*_{i,t_i}$：新策略是否恰好选择了 RCT 中实际随机到的动作；
- $r_{i,t_i}$：该事实动作下的真实收益；
- $N/N_{t_i}$：按实验组规模校正，使“只观察一个动作”的 RCT 样本可无偏估计策略价值；
- 负号表示训练最小化损失等价于最大化策略收益。

这对应 Figure 2 最右侧的 “Unbiased Estimation of $\mathcal L_{\rm DL}$”。它衡量的不是“Target 数值 MSE 小不小”，而是：

> 当前 Bridge 诱导出的 Target，经过真实预算分配后，在无偏 RCT 上是否做出了更赚钱的资源配置。

### 7.2 为什么这里不能直接反传？

分配器内部含：

$$
z^*_{ij}
=\mathbb 1\left[
j=\arg\max_k(\hat r_{ik}-\lambda^*\hat c_{ik})
\right],
$$

而 $\lambda^*$ 又由预算搜索得到。argmax 是离散跳变：大多数小扰动不会改变动作，梯度为零；越过边界时动作突然翻转。故 Figure 2 中从 Decision Loss 经过分配器回到 $\hat r,\hat c$ 的箭头，不能由普通自动微分直接得到。

论文用 PPL 或 PIFD 为这条箭头提供可用的近似梯度。

### 7.3 对应 Figure 2 黑色向左箭头：这才是“决策损失回传到临时 Target”

截图中从右向左的两条黑箭头属于**上层决策损失的反向梯度**，方向与前向计算相反。

前向时，数据从左向右流：

$$
\hat\theta
\longrightarrow
(\hat r,\hat c)
\longrightarrow
z^*(\hat r,\hat c)
\longrightarrow
\mathcal L_{\rm DL}.
$$

反向时，图中箭头表达的链式法则是：

$$
\frac{\partial\mathcal L_{\rm DL}}{\partial\hat\theta}
=
\underbrace{
\frac{\partial\mathcal L_{\rm DL}}{\partial z^*}
}_{\text{右侧箭头：策略好坏对动作的信号}}
\cdot
\underbrace{
\frac{\partial z^*}{\partial(\hat r,\hat c)}
}_{\text{经过预算分配器的梯度，离散且困难}}
\cdot
\underbrace{
\frac{\partial(\hat r,\hat c)}{\partial\hat\theta}
}_{\text{临时 Target 的普通网络反传}}.
$$

Figure 2 左边那条标为 $\partial z^*(\hat r,\hat c)/\partial\hat\theta$ 的箭头，可以看作后两项合并后的记号：临时 Target 参数变一点，会先改变 $\hat r,\hat c$，再经分配器改变 $z^*$。右边标为 $\partial\mathcal L_{\rm DL}/\partial z^*(\hat r,\hat c)$ 的箭头，则表示“当前硬分配策略的好坏”传给动作层的训练信号。

其中最难的就是中间项 $\partial z^*/\partial(\hat r,\hat c)$：它含预算搜索与离散 argmax，不能由普通自动微分获得。**PPL 或 PIFD 解决的正是 Figure 2 右半边这条梯度路径。**

但这两条箭头只让梯度回到临时 Target $\hat\theta$，还没有回到 Bridge。之后 Figure 2 中间的 Implicit Differentiation 再计算：

$$
\frac{d\mathcal L_{\rm DL}}{d\phi}
=
\frac{\partial\mathcal L_{\rm DL}}{\partial\hat\theta}
\cdot
\frac{d\hat\theta(\phi)}{d\phi}.
$$

因此整张图的梯度传导可分成两段：

~~~text
图右黑箭头：Decision Loss → 分配器 → 临时 Target
               由 PPL / PIFD 解决离散决策的梯度问题

图中隐式微分：临时 Target → Bridge
               由 implicit differentiation 解决双层依赖问题
~~~

## 8. PPL 与 PIFD：怎样让图右的决策梯度回到结果面

### 8.1 PPL：以软策略近似硬分配

PPL 将硬 one-hot 动作放松为带温 softmax 概率：

$$
z'_{ij}
=\frac{\exp[(\hat r_{ij}-\lambda^*\hat c_{ij})/\tau]}
{\sum_k\exp[(\hat r_{ik}-\lambda^*\hat c_{ik})/\tau]}.
$$

再将 RCT 中事实动作的概率带入策略价值：

$$
\mathcal L_{\rm PPL}
=-\mathbb E_{i,t_i}
\left[
\frac{N}{N_{t_i}}z'_{i,t_i}r_{i,t_i}
\right].
$$

因为 $z'$ 对 $\hat r,\hat c$ 连续可导，得到：

~~~text
L_PPL → z' → (r̂, ĉ) → 临时 Target θ̂。
~~~

$\tau$ 大时平滑但与硬策略差距更大；$\tau$ 小时更像 argmax，但概率更容易饱和。PPL 的本质是“用可导的软分配，学习 RCT 上期望更高的策略”。

### 8.2 PIFD：真实评分保持硬分配，有限差分估计方向

PIFD 不将真实评价替换为软策略。它仍用原始 hard decision loss 判断策略好坏，再问：

> 若将某个预测或动作偏好轻微改变，重新运行真实预算分配器后，RCT 决策损失变好了还是变坏了？

最朴素的有限差分形式是：

$$
\frac{\partial\mathcal L_{\rm DL}}{\partial\hat r_{ij}}
\approx
\frac{
\mathcal L_{\rm DL}(\hat r+\epsilon e_{ij},\hat c)
-\mathcal L_{\rm DL}(\hat r,\hat c)}
{\epsilon}.
$$

逐个 $(i,j)$ 重跑会很贵。论文使用 PPL-aware 的半黑盒估计器，将收益/成本扰动统一为对软分配偏好的扰动，并利用原始 primal 决策损失得到冻结方向：

$$
g^{\rm FD}_{ij}\approx
\frac{\partial\mathcal L_{\rm DL}}{\partial z'_{ij}}.
$$

再定义只服务反传的代理：

$$
\mathcal L_{\rm PIFD}
=\mathbb E_{i,j}
\left[
\operatorname{stopgrad}(g^{\rm FD}_{ij})z'_{ij}
\right].
$$

stopgrad 表示有限差分得到的方向是固定信号，模型不能通过修改该辅助项取巧；$z'$ 则仍提供可导通道。PIFD 的评价更贴近最终硬分配，但求解与数值估计成本更高。

| 方法 | 训练时按什么评价 | 梯度怎样得到 | 取舍 |
|---|---|---|---|
| PPL | 软策略在 RCT 上的期望收益 | softmax 直接自动微分 | 平滑、稳定；有软硬策略失配 |
| PIFD | 原始硬分配的 RCT 决策损失 | 扰动后真实损失的有限差分，再经软层传回 | 更接近原问题；更复杂、更耗计算 |

## 9. 图中间：隐式微分到底把哪条梯度传给 Bridge

到目前为止，PPL/PIFD 已给出：

$$
\nabla_{\theta^*}\mathcal L_{\rm DL},
$$

即“临时 Target 的预测结果若改变，RCT 决策损失怎样改变”。但上层真正要更新的是 Bridge 参数 $\phi$。Bridge 不直接进入分配器，它先影响伪标签，再影响下层最优解 $\theta^*(\phi)$，所以链式法则是：

$$
\frac{d\mathcal L_{\rm DL}}{d\phi}
=
\frac{\partial\mathcal L_{\rm DL}}{\partial\theta^*}
\frac{d\theta^*(\phi)}{d\phi}.
$$

难点是 $d\theta^*/d\phi$：若把所有下层 SGD 步都展开反传，计算图长、显存大、梯度还会依赖展开步数。论文改从下层最优点满足的一阶条件出发：

$$
\nabla_\theta
\mathcal L_{\rm PL}(\phi,\theta^*)=0.
$$

对 $\phi$ 求导：

$$
\nabla^2_{\theta\theta}\mathcal L_{\rm PL}
\frac{d\theta^*}{d\phi}
+
\nabla^2_{\phi\theta}\mathcal L_{\rm PL}
=0.
$$

令

$$
H=\nabla^2_{\theta\theta}\mathcal L_{\rm PL},
$$

则形式上有：

$$
\frac{d\theta^*}{d\phi}
=-H^{-1}\nabla^2_{\phi\theta}\mathcal L_{\rm PL}.
$$

代回上层梯度：

$$
\nabla_\phi\mathcal L_{\rm DL}
=-
\left(\nabla^2_{\phi\theta}\mathcal L_{\rm PL}\right)^{\!\top}
H^{-1}\nabla_{\theta^*}\mathcal L_{\rm DL}.
$$

实践中不显式构造或求逆巨大 Hessian $H$。先用 conjugate gradient 求：

$$
Hv=\nabla_{\theta^*}\mathcal L_{\rm DL},
$$

再用 Hessian-vector product 得到与 $\phi$ 有关的项。这正是 Figure 2 中间 Implicit Differentiation 的意义：它不是额外预测网络，而是从“下层最优条件”计算 Bridge 的超梯度。

## 10. 一次训练迭代：严格按 Figure 2 的时间顺序

设 Teacher 已由 RCT 预训练并冻结；Target 参数为 $\theta$，Bridge 参数为 $\phi$。

1. 从 OBS 取 batch，读取 $(x_i,t_i,r_{i,t_i},c_{i,t_i})$。
2. Teacher 与当前 Target 都输出各 treatment 的收益/成本预测。
3. Bridge 输出 $w^r,w^c$，为 OBS 未观察动作构造 $r^{\rm cf},c^{\rm cf}$。
4. 用事实标签与伪标签得到下层损失 $\mathcal L_{\rm PL}(\phi,\theta)$。
5. 复制正式 Target；在副本上做 $K$ 次 assumed update，得到 $\hat\theta(\phi)$。
6. 副本 Target 在 RCT 上输出 $\hat r,\hat c$；预算分配器在给定 $B$ 下得到策略 $z^*$。
7. RCT 用 IPW 无偏估计决策损失；PPL 或 PIFD 给出它对临时 Target 的梯度。
8. 隐式微分将该梯度穿过 $\theta^*(\phi)$，更新 Bridge $\phi$。
9. 用更新后的 Bridge 重新构造 OBS 伪标签，真正执行一次下层更新，更新正式 Target $\theta$。
10. 进入下一 batch；论文按设定的间隔执行上层 Bridge 更新，而下层 Target 更新更常发生。

可以把第 5–8 步看作“先问：如果这样教 Target，它日后在 RCT 策略上会不会更好”；第 9 步才是“把当前正确的教法真正用于训练 Target”。

## 11. 训练损失、梯度和参数更新：谁更新谁

| 名称 | 数据 | 前向依赖 | 直接更新 | 作用 |
|---|---|---|---|---|
| Teacher 预训练损失 | RCT | Teacher 输出与 RCT 事实标签 | $\psi$，预训练阶段 | 获得无偏锚点；之后冻结 |
| 下层预测损失 $\mathcal L_{\rm PL}$ | OBS | Teacher、Target、Bridge 伪标签 | 正式阶段更新 $\theta$ | 用大样本学习结果面 |
| PPL/PIFD 决策代理 | RCT | 临时 Target、分配器、策略价值估计 | 先形成 $\nabla_{\theta^*}\mathcal L_{\rm DL}$ | 判断策略好坏 |
| 隐式超梯度 | OBS 下层 + RCT 上层 | Hessian/HVP 与决策梯度 | $\phi$ | 让 RCT 决定伪标签融合方式 |

关键不是把所有 loss 直接相加后同时更新所有参数。更准确的依赖是：

$$
\underbrace{\mathcal L_{\rm PL}}_{\text{OBS}}
\xrightarrow{\arg\min_\theta}
\theta^*(\phi)
\xrightarrow{\mathcal L_{\rm DL}\text{ on RCT}}
\text{update }\phi.
$$

这也是 Bi-DFCL 相比 DFCL 的核心变化：DFCL 使用 prediction loss 与 decision loss 的显式加权；Bi-DFCL 将 OBS prediction loss 放在下层、RCT decision loss 放在上层，由双层优化自适应地决定二者如何协作。

## 12. 训练结束后，线上究竟保留什么

训练期的 Teacher、Bridge、assumed update、PPL/PIFD、隐式微分和 RCT decision loss 都不需要逐请求部署。线上仅保留：

~~~text
当前特征 x
→ Target F_θ 输出各券档 r̂(x,j)、ĉ(x,j)
→ 当前预算 B / 动态 λ / 频控与安全规则
→ 分配器输出最终 treatment。
~~~

对于券档 $\{0,2,4,6\}$，Target 输出：

$$
\{(\hat r(x,0),\hat c(x,0)),\ldots,
(\hat r(x,6),\hat c(x,6))\}.
$$

若业务关心券的增量效果，再相对 0 元券计算：

$$
\Delta\hat r(x,a)=\hat r(x,a)-\hat r(x,0),\qquad
\Delta\hat c(x,a)=\hat c(x,a)-\hat c(x,0).
$$

Bridge 不是线上动作 gate；$\lambda$、券档配额、频控和风险阈值也不是 Bridge 的输出，它们属于独立的预算控制/分配层。

## 13. 论文实验支持什么

- 论文在 Criteo-Uplift v2 Hybrid 与两套工业营销数据上比较 RCT-only、OBS-only、RCT+OBS 方法；二元 treatment 使用 AUCC，多 treatment 使用 RCT 上无偏的 EOM。
- 消融依次检验 PPL、双层优化、反事实伪标签和隐式求导的贡献。论文报告在两套营销数据的 EOM 上，基线 $1.0000$ 提升至 $1.0277/1.0252$。
- 四周线上 A/B、79 万商家随机分组中，论文报告 Bi-DFCL-PPL 相对 TSM-SL 提升 $3.00\%$，Bi-DFCL-PIFD 提升 $3.22\%$。

严谨的结论是：在论文的数据、RCT 覆盖、预算协议和 A/B 环境下，这种“OBS 下层学习 + RCT 上层校正”的训练方式优于文中对照方法。它不是证明任何 OBS/RCT 组合都必然有效。

## 14. 局限与落地时必须补的部分

1. **RCT 覆盖是边界。**某城市、时段、人群或高券档从未在 RCT 中出现时，Bridge 无法凭空得到可靠无偏校正。
2. **Teacher 不是 ground truth。**它只是相对无偏的锚点；若 RCT 小、特征覆盖差，Teacher 本身也可能高方差。
3. **双层优化成本高。**PPL/PIFD、assumed update、CG/HVP 都比单一 outcome 模型复杂，需要控制上层更新频率和数值稳定性。
4. **PPL 有近似，PIFD 有估计成本。**前者用软策略换可导性，后者更贴近硬策略但需要更多有限差分/求解工作。
5. **线上仍需硬护栏。**预算、频控、最低实付价、ETA、取消率和合规约束不能仅靠训练损失保证。


## 16. 最终 takeaway

> **Bi-DFCL 的本质是一个“谁来教 Target”的双层问题：OBS 负责大量教学样本，Teacher 提供 RCT 锚点，Bridge 决定缺失反事实标签的融合方式；但 Bridge 的优劣不由 OBS 拟合误差裁判，而由“这样训练出来的 Target 经预算分配后，能否在 RCT 上获得更高策略价值”裁判。**
