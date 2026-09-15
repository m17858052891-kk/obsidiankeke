
## 0. 先用一分钟讲清项目

这是一个**多 treatment 的 uplift 排序**问题。对干预前特征 $X$、实际折扣档位 $W$、Call 标签 $Y$，模型先预测每一档下的潜在响应：

$$
\hat\mu_a(x)\approx P(Y(a)=1\mid X=x),
$$

再计算相对 100 档的增量：

$$
q^{(m)}(x)=\hat\tau_m(x)=\hat\mu_m(x)-\hat\mu_{100}(x).
$$

第一阶段用观测到的 factual 标签学稳定的 response 模型；第二阶段在保留 factual 约束的基础上，以 OOF-DR/PU 标签提供排序监督。核心目标不是提高绝对 Call 概率，而是在有限补贴下把**真正更可能被补贴拉动**的用户排到前面。

---

## 1. OOF-DR 伪标签怎么构造

### 1.1 它为什么需要

一个用户只会实际看到一个档位，只能观测 $Y(W)$；但我们想知道同一用户在 $m$ 档和 100 档下的差：

$$
\tau_m(x)=E[Y(m)-Y(100)\mid X=x].
$$

这两个潜在结果无法同时观测。DR（Doubly Robust）伪标签将：

- **结果模型**：预测该用户在每个档位下的响应；
- **倾向得分**：校正日志中各档位的样本比例；
- **真实观测残差**：用实际结果纠正结果模型；

合成一个可作为 CATE/uplift 排序监督的样本级信号。

### 1.2 要估计哪些辅助模型

对每一折训练样本，拟合：

$$
\hat\mu_a(x)=E[Y\mid X=x,W=a],
\qquad
\hat e_a(x)=P(W=a\mid X=x).
$$

若是严格 RCT，$e_a(x)$ 通常可直接取经核验后的**实际有效分流比例**；若分流依赖协变量、存在筛选或是观察日志，则需要 propensity model。无论哪种情况，都需检查每档有足够覆盖：$e_a(x)>0$。

### 1.3 二元 DR 公式

先将任一补贴档 $m$ 视为 treatment $T=1$、100 档视为 control $T=0$。令 $e(x)=P(T=1\mid x)$，标准 DR uplift 伪标签是：

$$
\phi_i^{DR}=
\hat\mu_1(X_i)-\hat\mu_0(X_i)
+\frac{\mathbb{1}(T_i=1)}{\hat e(X_i)}
\left[Y_i-\hat\mu_1(X_i)\right]
-\frac{\mathbb{1}(T_i=0)}{1-\hat e(X_i)}
\left[Y_i-\hat\mu_0(X_i)\right].
$$

第一项是模型给出的增量预测；后两项是逆倾向加权的残差修正。注意：**control 残差前是减号**，因为目标是 treatment 减 control。若看到“两个修正项都是加号”的写法，必须确认 control 项是否已在标签定义中预先带了负号；否则符号会错。

它的双重稳健含义是：在可忽略性、重叠性和常规正则条件下，结果模型或倾向模型有一侧正确时，平均效应相关估计仍有一致性保障。它不代表单个用户的伪标签就是真实 ITE，也不解决未观测混杂。

### 1.4 多档 treatment 如何扩展

对每个目标档位 $m\ne100$，分别相对 100 档构造：

$$
\phi_{i,m}^{DR}=
\hat\mu_m(X_i)-\hat\mu_{100}(X_i)
+\frac{\mathbb{1}(W_i=m)}{\hat e_m(X_i)}
\left[Y_i-\hat\mu_m(X_i)\right]
-\frac{\mathbb{1}(W_i=100)}{\hat e_{100}(X_i)}
\left[Y_i-\hat\mu_{100}(X_i)\right].
$$

实际属于其他档位的样本，在这个 $m$ vs. 100 对比里没有残差校正项，但仍有第一项模型预测。工程上可以：

1. 对每一个 $m$ 都构造一列 $phi_{m}^{DR}$；
2. 排序 loss 按档位分别聚合，避免大样本档位淹没小样本档位；
3. 对 $hat e_m$ 做 overlap 检查、必要的 clipping，并报告每档有效样本量。

### 1.5 为什么一定要 OOF / cross-fitting

如果样本 $i$ 同时用于训练 $\hat\mu,\hat e$，又用其训练内预测生成自己的残差：

$$
Y_i-\hat\mu_{W_i}(X_i),
$$

模型会因记忆训练样本而把残差压得过小，伪标签变得过于乐观；随后 rank loss 学到的是泄漏的噪声结构，不是可泛化 uplift。

正确做法是 K 折交叉拟合：

1. 划分 K 个折，最好按时间/用户分组，避免同一用户泄漏；
2. 第 $k$ 折以外的数据训练 $\hat\mu_a^{(-k)}$ 与 $\hat e_a^{(-k)}$；
3. 只对第 $k$ 折预测，得到 $\hat\mu_a^{oof}(X_i)$、$\hat e_a^{oof}(X_i)$；
4. 每条样本用其 OOF 预测代入 DR 公式；
5. 拼接各折的 $phi_{i,m}^{DR}$，仅把它用于训练集的排序监督。

**面试一句话**：OOF 不是为了把分数做高，而是保证每条伪标签都来自“没看过这条样本”的 nuisance model，防止残差泄漏和排序过拟合。

### 1.6 OOF-DR 的必做诊断

- 各档位的真实分流比例、估计 propensity 分布、最小值和极端权重；
- 截断前后 DR 标签的均值、方差、分位数和有效样本量；
- OOF 与 in-fold 伪标签的差异；若训练内显著更平滑/更好看，要警惕泄漏；
- 时间外和分城市/用户频次切片的排序表现；
- 伪标签只用于 rank loss，不能把它当作线上可解释的“个人真实收益”。

### 1.7 不要混淆：OOF-DR 与项目记录中的 PU/IPW 变换标签

`CFR梯度传播.md` 还记录了一种更轻量的、用于排序的 PU/IPW transformed outcome。对 $m$ 相对 100 档：

$$
z_i^{(m)}=(2Y_i-1)
\left[
\frac{\mathbb{1}(W_i=m)}{e_m(X_i)}
-\frac{\mathbb{1}(W_i=100)}{e_{100}(X_i)}
\right].
$$

其中 $2Y_i-1$ 将 Call/no-call 映射为 $+1/-1$：treatment-no-call 是负向证据，control-no-call 在这个**总体变换标签**下提供相对正向证据。这不表示 control-no-call 的用户个人一定会被补贴拉动。

两者的区别是：

| 标签 | 是否需要结果模型 $\mu$ | 是否需要 OOF | 特点 |
|---|---:|---:|---|
| PU/IPW transformed outcome $z_i^{(m)}$ | 否 | 只要 propensity 来自学习模型则建议 OOF | 简单，但方差主要受 inverse propensity 放大。 |
| OOF-DR $\phi_{i,m}^{DR}$ | 是 | 是 | 用结果预测降低方差并用残差校正，更复杂。 |

因此面试时应按实际实验标签回答：若当前 Corr 训练用的是 $z_i^{(m)}$，就说“PU/IPW-Corr”；若用的是 $\phi_{i,m}^{DR}$，才说“OOF-DR-Corr”。不能把两种标签混称为同一个公式。

---

## 2. Rank Loss 与 Pairwise Loss 分别怎么做

模型对档位 $m$ 的原始预测分数是：

$$
q_i^{(m)}=\hat\mu_m(X_i)-\hat\mu_{100}(X_i).
$$

其中 global rank loss 解决“全局排序大方向”，matched pairwise loss 解决“局部可比样本的临界错序”。二者不是替代关系。

### 2.1 全局 Rank Loss：当前主力是按档位的 Corr loss

对每个档位 $m$，收集该档对应的预测 uplift 向量 $\tilde q^{(m)}$ 和实际选定的一种伪标签（OOF-DR 的 $\phi^{DR}$ 或 PU/IPW 的 $z$）。为统一符号，下式记为 $z^{(m)}$。当前的全局排序目标可以写为：

$$
L_{corr}=
\frac{1}{|\mathcal M|}
\sum_{m\in\mathcal M}
\left[1-\operatorname{Corr}\left(\tilde q^{(m)},z^{(m)}\right)\right].
$$

皮尔逊相关系数为：

$$
\operatorname{Corr}(u,v)=
\frac{\sum_i(u_i-\bar u)(v_i-\bar v)}
{\sqrt{\sum_i(u_i-\bar u)^2}\sqrt{\sum_i(v_i-\bar v)^2}+\epsilon}.
$$

**具体做法**：一个 batch 内按 treatment 档位分组；每组计算模型 uplift 分数与 OOF-DR/PU 标签的相关性；对各档损失求平均或按业务权重聚合。优化目标是使二者同涨同跌，因而更贴近“排序方向”而不是伪标签绝对数值。

**为什么适合这里**：DR/IPW 样本级伪标签方差很大，直接 MSE 会强迫模型拟合不可靠的绝对大小；Corr 对平移和正比例缩放不敏感，更关注相对变化方向，且一个 batch 内每个样本都有梯度，属于稠密的全局排序信号。

**它的局限**：Pearson Corr 优化的是线性相关，不等于精确的 Top-K 排序指标；它也会让同一 batch 中所有样本耦合，若伪标签混入 assignment/exposure 捷径，强 Corr 会放大该风险。因此 Corr 应是主监督，但必须保留 factual loss、ratio/overlap 诊断和时间外验证。

> 泛化表述：若实现不是 Corr，而是 RankNet/LambdaRank，全局 pairwise 形式可写为 $\log[1+\exp(-y_{ij}(s_i-s_j))]$。但本项目应优先按实际采用的 `Corr 为主、Pairwise 为辅` 描述，不要混称。

### 2.2 Pairwise Loss：只对局部可比且方向明确的 pair 施压

先在 Stage-1 学到的表征空间或限定的同城市/同时间/同成本桶中，匹配 treatment 与 control 的相近样本，得到 pair 集合 $\mathcal P$。对一对 $(i,j)$：

- $d_{ij}=+1$：希望 $i$ 的 uplift 高于 $j$；
- $d_{ij}=-1$：希望 $i$ 的 uplift 低于 $j$；
- $w_{ij}$：匹配质量或置信度权重；
- $M$：可选安全边际；$T_{rank}$：排序温度。

RankNet 风格损失：

$$
L_{pair}=
\frac{1}{|\mathcal P|}
\sum_{(i,j)\in\mathcal P}w_{ij}
\log\left[
1+\exp\left(
-\frac{d_{ij}(\tilde q_i-\tilde q_j-M)}{T_{rank}}
\right)
\right].
$$

以两类典型的跨组观测为例：

- treatment-call 对 matched control-no-call：这是“相对更可能被补贴拉动”的正向局部证据，设 $d_{ij}=+1$；
- treatment-no-call 对 matched control-call：这是负向局部证据，设 $d_{ij}=-1$。

这不表示单条 treatment-call 一定是被补贴拉动，也不表示 control-no-call 一定能被拉动；pairwise 只是在随机化、匹配可比和总体统计意义下提供弱监督。

**梯度直觉**：记 $r_{ij}=d_{ij}(\tilde q_i-\tilde q_j-M)/T_{rank}$，则：

$$
\frac{\partial l_{ij}}{\partial(\tilde q_i-\tilde q_j)}
=-\frac{d_{ij}}{T_{rank}}\sigma(-r_{ij}).
$$

pair 已正确且有足够 margin 时，$\sigma(-r_{ij})$ 很小；错序越严重，梯度越大。$T_{rank}$ 越小，更新越激进，也越容易受噪声 pair 影响。

### 2.3 为什么 Corr 为主、Pairwise 为辅

| 维度 | Corr Rank Loss | Matched Pairwise Loss |
|---|---|---|
| 监督范围 | 整个 batch / 每个档位 | 仅入选的局部匹配 pair |
| 梯度 | 稠密，整体排序推动强 | 稀疏，局部方向更明确 |
| 优势 | 更容易提升整体 AUCC | 可减少纯全局相关带来的粗糙排序 |
| 风险 | 易利用分组/曝光捷径 | pair 数少、匹配质量与伪标签噪声敏感 |

因此总目标不是二选一，而是：

$$
L_{total}=L_{base}+\lambda_cL_{corr}+\lambda_pL_{pair}.
$$

通常让 $\lambda_c$ 主导，$\lambda_p$ 较小做局部校正；若只训 Pairwise，监督太稀疏；若只用强 Corr，AUCC 可能升高但 treatment-ratio 风险变大。

---

## 3. 模型架构、前向与梯度如何传播

### 3.1 网络结构

```text
干预前特征 X
  ├─ 离散特征 → Embedding
  ├─ 连续特征 → 归一化/数值编码
  └─ 拼接
        ↓
  Shared Bottom / Shared Representation：h=f_shared(X)
        ↓
  Cumulative Response Head
        ↓
  μ̂_100, μ̂_97, μ̂_94, ...（每档响应概率）
        ↓
  q̂_m = μ̂_m - μ̂_100（各档 uplift）
        ├─ Factual BCE / 因果约束
        └─ Corr Rank + Matched Pairwise
```

Embedding 编码高基数离散信息；Shared Bottom 学跨档可共享的用户/场景响应表征；Cumulative Head 用结构先验表达“补贴更深时预测响应不应更低”。

### 3.2 Cumulative response head 如何保证单调

按补贴逐渐加深的顺序 $a_0=100,a_1,a_2,\ldots$，先预测 control base logit，再递推加非负 logit 增量：

$$
l_{i,100}=g_{100}(h_i),
$$

$$
l_{i,a_j}=l_{i,a_{j-1}}+\operatorname{softplus}\left(\Delta_{a_j}(h_i)\right),
\qquad
\hat\mu_{i,a_j}=\sigma(l_{i,a_j}).
$$

因为 $\operatorname{softplus}(z)>0$ 且 sigmoid 单调递增，所以：

$$
\hat\mu_{i,a_j}\ge\hat\mu_{i,a_{j-1}}.
$$

这是一个**结构性先验**，可以减少稀疏深档位乱序；前提是“补贴更深在其他条件相同时不应降低 Call 概率”在业务上可接受。它不保证净收益单调，因为更深补贴的成本更高。

### 3.3 第一阶段：Factual response 学什么，梯度到哪里

每条样本只在其实际档位 $W_i$ 上有观测标签，factual BCE 是：

$$
L_{factual}=-\frac{1}{n}\sum_i
\left[Y_i\log\hat\mu_{i,W_i}+(1-Y_i)\log(1-\hat\mu_{i,W_i})\right].
$$

对实际档位的 logit，梯度是：

$$
\frac{\partial L_{factual}}{\partial l_{i,W_i}}
=\hat\mu_{i,W_i}-Y_i.
$$

梯度路径：

```text
Factual BCE
  → 实际 W_i 对应的 cumulative logit / 增量 head
  → Shared Bottom
  → Embedding
```

其他反事实档位没有该样本的直接 BCE 监督；它们依靠其他档位样本、共享表示、RCT/重叠条件与结构约束获得泛化。这就是为什么 factual AUC 高不等于 uplift 排序一定好。

Base objective 还可包括表征平衡、ATE 或其他因果约束：

$$
L_{base}=L_{factual}+\lambda_{bal}L_{imbalance}+\lambda_{con}L_{constraint}.
$$

它们主要更新共享表示 $h$，减少不同档位间的分布差异。若当前实验没有明确记录某个 IPM 的精确形式，面试应说“表征平衡/因果约束”，不要硬说是某种特定 Wasserstein 实现。

### 3.4 第二阶段：排序梯度走哪些路径

对一个档位 $m$：

$$
q_i^{(m)}=\hat\mu_{i,m}-\hat\mu_{i,100}.
$$

因此：

$$
\frac{\partial q_i^{(m)}}{\partial\hat\mu_{i,m}}=1,
\qquad
\frac{\partial q_i^{(m)}}{\partial\hat\mu_{i,100}}=-1.
$$

无论 Corr 还是 Pairwise，若 rank loss 希望提高 $q_m$，它可以：提高 treatment-$m$ 的预测响应，或降低 control-100 的预测响应。梯度路径是：

```text
Corr / Pairwise
  → 经 Z-score + Tanh 的 q̃_m
  → 原始 q_m = μ̂_m - μ̂_100
  → treatment-m 与 control-100 的 cumulative head
  → Shared Bottom
  → Embedding
```

这解释了它的收益与风险：rank loss 能直接对齐 uplift 排序，但强排序梯度也可能破坏 response probability 的校准或把 assignment 结构编码到 shared representation 中。

---

## 4. 为什么要做 Z-score + 带温度 Tanh

### 4.1 变换是什么

对每个档位 $m$，仅在该档的 rank loss 内，按 batch 或稳定统计量标准化 uplift 分数：

$$
u_i^{(m)}=
\frac{q_i^{(m)}-\operatorname{stopgrad}(\mu_m)}
{\operatorname{stopgrad}(\sigma_m)+\epsilon},
$$

再做带温度的压缩：

$$
\tilde q_i^{(m)}=\tanh\left(\frac{u_i^{(m)}}{T}\right).
$$

这里的 `stopgrad` 表示均值、标准差作为校准常数，不允许梯度通过它们回传；否则模型可能操纵 batch 均值/方差来降低 loss，而不是学习更可靠的相对顺序。该变换只用于 rank/pairwise 分支，线上输出仍是原始 $\hat\mu$ 与 $q$。

### 4.2 Z-score 具体解决什么

不同档位的 uplift 均值、尺度和方差不同。若直接将原始 $q_m$ 输入 Corr 或 Pairwise：

- 方差更大的档位会产生更大的 score 差和梯度，主导共享层；
- 均值漂移会使不同档位的 loss 不可比；
- 深档/长尾档位的少量异常分数会放大排序更新。

Z-score 将每档 score 置于可比较的中心和尺度，令 rank loss 更关注“该档位内谁相对更高”，而不是哪档天然数值更大。

### 4.3 Tanh 与温度 $T$ 具体解决什么

DR/IPW 相关监督存在长尾和高方差：小 propensity 会使残差修正很大，错序的极端样本对可能产生大梯度。Tanh 把输入压到 $(-1,1)$，其导数为：

$$
\frac{d}{du}\tanh\left(\frac{u}{T}\right)
=\frac{1}{T}\left[1-\tanh^2\left(\frac{u}{T}\right)\right].
$$

当 $|u|$ 很大时，导数趋近 0，极端分数不再无限放大梯度；中间区域仍可区分相对排序。

- $T$ 小：更早饱和，异常抑制更强，但会损失中等样本的细粒度排序；
- $T$ 大：更接近线性，保留更多差异，但对长尾更敏感；
- 当前记录的 $T=2$ 是经验折中，不应表述为普适最优值。

### 4.4 这套方案的边界

它改善的是**数值尺度和异常梯度**，不解决：未观测混杂、无 overlap、OOF 泄漏、错误 propensity，或 factual/rank 两个目标在共享层的方向冲突。标签变换后仍必须看各档 AUCC/Qini、treatment ratio、概率校准、时间外表现和 Top-K 的真实增量。

### 4.5 可替代方案：按问题选，不是盲目堆技巧

| 方案 | 主要解决的问题 | 与 Z+Tanh 的关系 | 代价/边界 |
|---|---|---|---|
| Winsorize / percentile clipping | 极端 score 或伪标签 | 更硬的截尾替代 | 阈值敏感，可能抹掉真实极端人群。 |
| RobustScaler / MAD / 分位数归一化 | 非高斯长尾、标准差不稳 | 可替 Z-score | 排序解释更弱，分位统计需稳定。 |
| Huber / robust pairwise | 异常 pair 的损失梯度 | 损失端替代或叠加 | 不能修复标签错误。 |
| 置信度加权 pair | 小 propensity、高方差 DR 标签 | 更针对噪声来源，可叠加 | 需估计方差/overlap，不能过度放大小组。 |
| propensity clipping / stabilized weight | IPW/DR 残差爆炸 | 应在伪标签源头处理 | 改变目标总体，必须报告截断敏感性。 |
| rank warm-up / curriculum | 排序梯度早期不稳 | 优化调度替代或叠加 | 需额外调度参数。 |
| 分层 batch / 按档均值聚合 | 大档位压制长尾档 | 可与 Z+Tanh 叠加 | 极小样本档仍难可靠学习。 |

最有因果针对性的替代并不是单纯换激活函数，而是：先检查 overlap 和 propensity，再按伪标签方差/置信度给样本对加权。例如：

$$
w_i=\operatorname{clip}\left(
\frac{1}{\widehat{Var}(\phi_i^{DR})+\epsilon},w_{min},w_{max}
\right),
\qquad
w_{ij}=\sqrt{w_iw_j}.
$$

---

## 5. TwoStage 为什么能缓解梯度冲突

### 5.1 冲突从哪里来

Factual BCE 的目标是让实际档位下的概率正确：

$$
g_f=\nabla_{\theta_{shared}}L_{factual}.
$$

Rank loss 的目标是让 treatment-control 差值排序正确：

$$
g_r=\nabla_{\theta_{shared}}(\lambda_cL_{corr}+\lambda_pL_{pair}).
$$

当：

$$
g_f^\top g_r<0,
$$

两个目标在 shared layer 上相互拉扯。即便内积不为负，若 $\lVert g_r\rVert\gg\lVert g_f\rVert$，高噪声 rank 梯度也会淹没概率监督。应记录梯度余弦：

$$
\cos(g_f,g_r)=\frac{g_f^\top g_r}{\lVert g_f\rVert\lVert g_r\rVert}.
$$

### 5.2 当前 TwoStage 的做法与理由

**Stage 1：稳定 response anchor。** 只优化：

$$
L_{base}=L_{factual}+\lambda_{bal}L_{imbalance}+\lambda_{con}L_{constraint}.
$$

此时 Embedding、Shared Bottom、Cumulative Heads 都主要接收低方差的真实观测标签梯度，学到稳定的基础响应和单调结构。

**Stage 2：在 anchor 上做有限排序适配。** 加载 Stage-1 checkpoint，保留 $L_{base}$，再加入 $L_{corr}$、$L_{pair}$：

$$
L_{stage2}=L_{base}+\lambda_cL_{corr}+\lambda_pL_{pair}.
$$

训练策略是：

1. 先冻结 Embedding 与 Shared Bottom，只训练各档 head，使排序目标优先在输出端重新分配；
2. 随后 Embedding 仍冻结，Shared Bottom 以远小于 head 的学习率软解冻（当前记录为 $0.01\times lr_{head}$）；
3. factual loss 始终保留，防止排序微调把概率语义完全拉偏。

当前项目材料记录的 `H2 Soft T2` 超参数为：

$$
\lambda_c=0.015,\qquad
\lambda_p=0.003,\qquad
T=2,
$$

并以 shared bottom 使用 $0.01\times lr_{head}$ 的小学习率软解冻。它是当时实验中“ratio 相对平稳候选里的较优折中”，不是可脱离数据复用的通用最优超参数。

**为什么冻结 Embedding**：离散 embedding 是基础人群/城市/场景语义的底层载体，若被高方差 pseudo-rank 梯度大幅更新，容易将噪声或 assignment 痕迹写入最底层表示，恢复成本很高。

**为什么还软解冻 Shared Bottom**：只训 head 太保守，可能没有足够容量改善排序；小学习率允许有限地调整共享表示，同时减少灾难性遗忘。

### 5.3 TwoStage 不是什么

它不是因果识别手段，不能弥补无 overlap 或未观测混杂；也不保证每个任务都更优。它是一种优化稳定化策略，是否有效要通过消融比较：仅 Stage 1、Stage-2 hard freeze、Stage-2 soft unfreeze，并同时看概率校准、AUCC/Qini、ratio、OOT 和 Top-K 成本收益。

### 5.4 还能怎样缓解梯度冲突

| 方法 | 适合的诊断 | 核心做法 | 相对 TwoStage 的位置 |
|---|---|---|---|
| Loss warm-up / curriculum | 早期 rank 噪声最大 | $\lambda_{rank}(t)$ 从小到大 | 最低成本，可与 TwoStage 组合。 |
| 交替更新 | 两目标同一步互相覆盖 | 若干 step 训 factual，再若干 step 训 rank+base | 简单，但切换频率要调。 |
| PCGrad | 梯度余弦持续为负 | 投影掉冲突分量 | 最针对“方向冲突”。 |
| GradNorm | 梯度范数严重失衡 | 动态调 $\lambda_f,\lambda_r$ | 更适合量级问题。 |
| 不确定性加权 | rank 标签整体更噪 | 学习各任务噪声权重 | 可减少手工调权。 |
| MGDA | 业务不愿预设优先级 | 寻找 Pareto 折中梯度 | 更复杂，非第一轮。 |
| Adapter / residual rank branch | 不希望 rank 改写基础概率 | 只让小型 rank 支路或 adapter 更新 | 结构性解耦，最接近冻结思想。 |

#### PCGrad 的公式

若 $g_f^\top g_r<0$，将 factual 梯度投影掉与 rank 冲突的部分：

$$
g_f'=g_f-\frac{g_f^\top g_r}{\lVert g_r\rVert^2}g_r.
$$

然后以 $g_f'+g_r$ 更新共享层。优点是直接处理负内积；缺点是每个 batch 要分别求两组梯度，通常只建议应用于 Shared Bottom，不必动任务 head。

#### GradNorm / 不确定性加权的公式

GradNorm 动态调整任务权重，使各任务在共享层的梯度范数与训练速度相匹配；它解决量级失衡，但不能消除方向冲突。

不确定性加权的常见形式：

$$
L=\frac{1}{2\sigma_f^2}L_{factual}
+\frac{1}{2\sigma_r^2}L_{rank}
+\log\sigma_f+\log\sigma_r.
$$

若 rank 标签整体噪声更大，模型可学习更大的 $\sigma_r$，从而降低即时 rank 权重。它仍应配合 OOF、overlap 和分档诊断。

---

## 6. 可直接背诵的收束回答

“我先用 K 折 cross-fitting 生成 OOF 的 outcome 和 propensity 预测，并对每个补贴档相对 100 档构造 DR 伪标签。DR 由结果模型差加 treatment 残差、减 control 残差组成；OOF 的作用是防止辅助模型记忆自身样本，把残差伪标签做得虚假平滑。

模型架构是 Embedding 加 Shared Bottom，再接 cumulative response head：以 100 档 base logit 为起点，用 softplus 非负增量递推各补贴档，保证响应概率单调。第一阶段用 factual BCE 和因果约束学稳定 response anchor；第二阶段保留 base loss，加入按档位的 Corr 全局排序和 matched Pairwise 局部排序。Corr 提供稠密的全局排序梯度，Pairwise 只约束相近、方向明确的跨组样本，因此是辅助。

排序损失通过 $q_m=\mu_m-\mu_{100}$ 同时回传到 treatment head、control head 和共享层，强行联合训练会与 factual probability 的梯度冲突。为此先冻结 Embedding 和底座让 head 适配，再以小学习率软解冻共享层。对长尾噪声，rank 分支内做按档 Z-score 统一尺度，再用带温度 Tanh 压缩极端梯度；但这不是因果修复，仍必须检查 overlap、treatment ratio、分档 OOT、概率校准和最终线上增量。”

## 7. 面试中不要过度宣称的点

- OOF-DR 是更稳健的伪标签构造，不是观测到个人真实 uplift；
- RCT 降低选择偏差，但有效分流比例、过滤、缺失和干扰仍需检查；
- cumulative head 是业务先验，不代表所有业务指标（尤其利润）一定单调；
- Z-score/Tanh、TwoStage、PCGrad 等是训练稳定化方法，不替代因果识别；
- Call AUCC 提升必须同时验证 Qini/treatment-ratio、分档覆盖、OOT、Top-K 成本收益，最终由线上随机实验确认。
