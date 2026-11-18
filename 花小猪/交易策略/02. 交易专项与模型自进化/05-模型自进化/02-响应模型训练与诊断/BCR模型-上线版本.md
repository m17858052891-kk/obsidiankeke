---
title: BCR模型-上线版本
source: https://cooper.didichuxing.com/knowledge/2199610335356/2209846005369
source_status: 发布版本无法导出，来自编辑态
source_structure: "[[2209846005369.json|Cooper 编辑态结构]]"
cssclasses:
  - strategy-body-note
---

# BCR模型-上线版本

**对照阅读**　[[BCR建模：概率约束、单调性与序列消融|概率约束与消融记录]]

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2209846005369)

先比较统一训练与评估口径下的版本，再看方法细节。策略指标同时保留点估计与配对区间，按原文区分观察到的提高和能确认的收益。

**阅读定位**　[[#1. 迭代主线|1. 迭代主线]] · [[#2. 各模型核心指标对比|2. 各模型核心指标对比]] · [[#3. 方法详解|3. 方法详解]]

## 1. 迭代主线

| 迭代阶段 | 优化方向 | 实际包含的改动 |
| --- | --- | --- |
| B0 → B3 | GMV 预测优化 | 独立 GMV Joint、动作感知价格/品类上下文、价格锚点残差； |
| B3 → F5 | Encoder 与特征融合优化 | 相对默勾位置、分类/GMV 双 Query、全量序列表示、晚融合、非序列表示加宽。 |
| F5 → T1 | 分类任务 Joint 分离 | CR、ECR、DSAR、finish_category 各用独立 Joint；GMV 分支此前已经独立 |
| T1 → SF0（上线版本） | 融合层精简 + 幸运盒子硬单调 | 先将非序列融合 MLP 从 $273\to256\to256$ 改为 $273\to256$， 加入幸运盒子硬单调 |
| T1 → T1H | 幸运盒子展现链硬单调约束 | 加入幸运盒子硬单调 |

本文统一使用 SF0 作为该模型的版本名。

## 2. 各模型核心指标对比

- 训练数据：preprocess_20260917_refresh

- 超参：seed=3407、batch_size=4096；主表统一 5 epochs，10 epochs 在 2.2 节单列

- 评估：MAE、RMSE 单位为元，MSE 单位为元²，MAPE 单位为 %；加粗表示本表该指标的最优点估计

> [!example]- 完整数据表（6 行记录）
> | 版本 | 参数量 | BCR AUC ↑ | CR AUC ↑ | ECR AUC ↑ | DSAR 条件 AUC ↑ | 品类宏 AUC ↑ | 品类准确率 ↑ | GMV MAE ↓（元） | GMV MSE ↓（元²） | GMV RMSE ↓（元） | GMV MAPE ↓（%） | MTAUCC@5 ↑（RAS v4） |
> | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
> | B0 | 478,486 | 0.7699 | 0.7809 | 0.7323 | 0.8631 | 0.8716 | 0.7396 | 2.0306 | 20.4185 | 4.5187 | 11.4104 | 9053.5224 |
> | B3 | 511,014 | 0.7712 | 0.7838 | 0.7332 | 0.8648 | 0.8781 | 0.7456 | 1.9569 | 15.7344 | 3.9667 | 11.0996 | 8735.2437 |
> | F5 | 851,286 | 0.7729 | 0.7864 | 0.7364 | 0.8717 | 0.8811 | 0.7485 | 1.9171 | 15.1737 | 3.8953 | 10.9300 | 10010.6759 |
> | T1 | 1,059,606 | 0.7735 | 0.7869 | 0.7378 | 0.8748 | 0.8824 | 0.7498 | 1.9116 | 15.1862 | 3.8970 | 10.8965 | 11280.2152 |
> | SF0 | 993,814 | 0.7737 | 0.7871 | 0.7380 | 0.8757 | 0.8828 | 0.7503 | 1.9070 | 15.0621 | 3.8810 | 10.8711 | 12041.6950 |
> | T1H | 1,059,606 | 0.7734 | 0.7867 | 0.7376 | 0.8750 | 0.8822 | 0.7493 | 1.9143 | 15.1846 | 3.8967 | 10.9109 | 13269.2059 |


读表时重点区分：

- B0 → B3：GMV 预测误差改善，但策略指标未确认改善。 MTAUCC@5 点估计下−3.515%

- B3 → F5：分类 AUC 和 GMV 误差整体改善。 MTAUCC@5 点估计+14.60%

- F5 → T1：分类 AUC 进一步提高。 MTAUCC@5 点估计提高+12.68%

- T1 → T1H：完整融合层上加入硬单调，MTAUCC@5 提高 +17.63%。

- SF0（上线版本）与 T1H：普通指标和策略指标的点估计各有侧重。 在本节 5 轮主表中，SF0 的各普通指标点估计最优，T1H 的 MTAUCC@5 最高；T1H 相对 SF0 高 1227.5109（+10.1938%）.

### 2.1 MTAUCC@5 的固定策略 Bootstrap 95% 区间

以下均为 RAS v4，每版 200/200 次有效重采样。单模型区间不直接用于判断模型差异；同一有序 trace、同一抽样种子的配对差异见 2.3 节。

| 版本 | MTAUCC@5（RAS v4） | 固定策略 bootstrap 95% 区间 |
| --- | --- | --- |
| B0 | 9053.5224 | [6604.1080, 11381.4528] |
| B3 | 8735.2437 | [6517.0729, 10984.5075] |
| F5 | 10010.6759 | [7662.7368, 12552.6176] |
| T1 | 11280.2152 | [9097.5527, 14003.5095] |
| SF0 | 12041.6950 | [9484.7086, 14842.9977] |
| T1H | 13269.2059 | [10421.7536, 15786.9697] |

### 2.2 T1H 训练轮数补充：5 epochs 与 10 epochs

相比 5 epochs，10 epochs 的普通 AUC 和 GMV 误差点估计改善；RAS MTAUCC@5 从 13269.2059 升至 13862.3838，增加 593.1779（+4.4703%）。但 $\mathrm{E10}-\mathrm{E5}$ 的配对 95% 区间为 [−1699.3031, 2599.6557]，包含 0；只能说本次点估计更高，不能确认延长训练带来了稳定策略收益。

> [!example]- 完整数据表（2 行记录）
> | T1H 训练轮数 | BCR AUC ↑ | CR AUC ↑ | ECR AUC ↑ | DSAR 条件 AUC ↑ | 品类宏 AUC ↑ | GMV MAE ↓（元） | GMV MSE ↓（元²） | GMV RMSE ↓（元） | GMV MAPE ↓（%） | MTAUCC@5 ↑（RAS v4） | 固定策略 95% 区间 |
> | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
> | 5 epochs | 0.7734 | 0.7867 | 0.7376 | 0.8750 | 0.8822 | 1.9143 | 15.1846 | 3.8967 | 10.9109 | 13269.2059 | [10421.7536, 15786.9697] |
> | 10 epochs | 0.7748 | 0.7879 | 0.7407 | 0.8771 | 0.8851 | 1.8807 | 14.9112 | 3.8615 | 10.7175 | 13862.3838 | [11325.1985, 16411.9838] |


## 3. 方法详解

### 3.0 B0 网络结构与符号说明

B0 是本轮迭代的无单调约束基线：非序列特征与序列特征经 Encoder 和 Shared Bottom 形成用户表示，与 560 个动作槽位的动作表示拼接后，统一经过共享 Joint MLP，再进入五个任务各自的 Tower / Head。GMV 直接预测金额（元），尚未引入独立 GMV Joint、动作前缀 Attention 和价格锚点残差。

![](https://didoc.didichuxing.com/api/uploadfile?b=didoc2-upload-file-prod&k=images%2F1790090177942%2FTGZHsorW71KIlLJATqrWo%2Fimage.png&filename=image.png)

下表为后续方法章节使用的符号；

| 符号 | 含义 | 单位 / 范围 |
| --- | --- | --- |
| $i$ | 当前冒泡的表单候选位置索引 | 从 1 开始，最多 20 个位置 |
| $L$ | 当前冒泡的有效序列长度 | 有效位置数，最多 20 |
| $k$ | 候选动作的默勾数；用于确定读取前几个位置 | 1～20，最终还需通过可行性 mask |
| $d$ | 幸运折扣与特价折扣的组合；与 $k$ 组成联合动作 $(d,k)$ | 配置中共有 28 个折扣组合 |
| $p_i$ | 位置 $i$ 的原始序列应付价格 avg_pas_total_fee_amt，未标准化 | 分；仅有限、非缺失且大于 0 的价格参与锚点计算 |
| $\mathcal P_k$ | 前 $k$ 个位置中，同时位于有效长度内且价格有效的位置集合 | 集合；对应下式的 $\mathcal P_k$ |
| $a_k$ | $\mathcal P_k$ 内原始应付价格的均值，再除以 100；无有效价格时取 0 | 元；同一样本、同一 $k$ 的所有折扣组合共用 |
| $r_{d,k}$ | GMV 网络对动作 $(d,k)$ 输出的可正可负修正量 | 元尺度，位于 Softplus 之前 |
| $M_{d,k}$ | 动作 $(d,k)$ 的可行性 mask，由 treatment_length 确定 | 1 表示可行，0 表示不可用槽位 |
| $\widehat y_{d,k}$ | 加入价格锚点、经过 Softplus 和可行性 mask 后的 GMV 输出 | 元；对应下式的 $\widehat y_{d,k}$ |

### 3.1 GMV 残差：先给金额基准，再学习修正量

#### 3.1.1 价格锚点来自什么

价格锚点使用原始序列应付价格。有效前缀位置集合定义为：

$\mathcal P_k
=
\{i:1\le i\le \min(k,L),\ p_i\ne -9999,\ p_i\text{ 有限},\ p_i>0\}.$

$p_i$ 的原始单位是分；锚点取有效价格的算术均值并除以 100，转换为元：

$a_k=
\begin{cases}
\displaystyle \frac{\sum_{i\in\mathcal P_k}p_i}{100\,|\mathcal P_k|},
&|\mathcal P_k|>0,\\[6pt]
0,&|\mathcal P_k|=0.
\end{cases}$

#### 3.1.2 网络如何预测残差

在 T1/T1H 中，GMV 分支接收全局表示、动作表示、自己的前缀上下文以及相对默勾位置，共 477 维。其路径为：

$\begin{aligned}
&\text{GMV 分支输入 }477\\
&\rightarrow\text{独立 GMV Joint：}477\to128\to64\\
&\rightarrow\text{GMV Tower：}64\to32\\
&\rightarrow\text{Linear Head：}32\to1\\
&\rightarrow\text{可正可负的残差 }r_{d,k}\\
&\rightarrow\text{与原始价格锚点 }a_k\text{ 相加}\\
&\rightarrow\operatorname{softplus}\\
&\rightarrow\text{可行动作 mask}\\
&\rightarrow\text{GMV，单位：元}
\end{aligned}$

残差 Head 后面没有先接 ReLU，因此允许向上或向下修正金额。最终输出为：

$\widehat y_{d,k}
=
M_{d,k}\,\operatorname{softplus}(a_k+r_{d,k}),
\qquad
\operatorname{softplus}(t)=\log(1+e^t).$

### 3.2 Encoder：两路编码、全局读取、保留宽表示

Encoder 不是只产生一个 128 维向量后把其他信息丢掉，而是保留非序列表示 $n$、序列摘要 $g$、逐位置表示 $H$；再生成一个较窄的 $u$ 专门服务后续 Query。

- 非序列特征，过MLP得到 $n$（256 维）

- 序列特征过transformer得到逐位置表示 $H$（$20\times128$）

- 用非序列信息读取全序列，得到 $g$（128 维）

- 先由 $n$（256 维）经过 Linear 生成一个 128 维全局 Query，在所有有效位置上做 Attention 池化：

$q_{\mathrm{global}}=W_{\mathrm{global}}n+b_{\mathrm{global}},
\qquad
\alpha_i^{\mathrm{global}}
=
\operatorname{softmax}_{i\le L}
\left(
\frac{q_{\mathrm{global}}^\top H_i}{\sqrt{128}}
\right),
\qquad
g=\sum_{i\le L}\alpha_i^{\mathrm{global}}H_i.$

- 晚融合：$z$（384 维）直达预测，$u$（128 维）只生成 Query

![](https://didoc.didichuxing.com/api/uploadfile?b=didoc2-upload-file-prod&k=images%2F1790090263594%2FTqGGFGR5Be2WteUOSguck%2Fimage.png&filename=image.png)

### 3.3 默勾数相关特征：相对位置 + 分类/GMV 双 Query

这两项不是同一种特征：相对位置描述“勾了多大比例”，双 Query 读取“这些候选具体是什么、对任务有何价值”。 它们结合原有默勾 Embedding，共同构造动作条件。

![](https://didoc.didichuxing.com/api/uploadfile?b=didoc2-upload-file-prod&k=images%2F1790090282669%2FzX_cwHN46XTkH6wjkVFCh%2Fimage.png&filename=image.png)

#### 3.3.1 相对默勾位置：同样 $k$，在不同表单中含义不同

原有 hook_embedding(k) 只描述第几个默勾档位，并不直接说明这个 $k$ 已覆盖当前表单的多少位置。E2 因此新增两个确定性数值特征：

$\widetilde L=\operatorname{clip}(L,1,20),
\qquad
\rho_k=
\left[
\min\left(\frac{k}{\widetilde L},1\right),
\frac{\max(\widetilde L-k,0)}{\widetilde L}
\right].$

第一维是覆盖比例，第二维是剩余比例。分母截断用于防止除零；最终动作是否可行仍由 treatment mask 判断，比例截断不负责把不可行动作变成合法动作。

| 示例表单 | 有效长度 $L$ | 候选默勾数 $k$ | 覆盖比例 | 剩余比例 |
| --- | --- | --- | --- | --- |
| 短表单 | 4 | 3 | 0.7500 | 0.2500 |
| 长表单 | 12 | 3 | 0.2500 | 0.7500 |

两条样本都勾 3 个，但覆盖范围明显不同。该表示无可训练参数，当前两维在合法范围内互为补充、和为 1，不是两份独立信息。代码仍保留两维，并同时送入 Query 输入与最终 Joint 输入。

这里用的是有效序列长度 $L$，不是某个折扣组合的最大可行默勾数；因此，同一样本、相同 $k$ 的相对位置也在折扣组合间复用。

#### 3.3.2 双 Query 从哪里来

Query 不是“在上一层 Attention 的权重上再切成两份”，而是用 Encoder 的 $u$（128 维）和候选默勾条件，经过两套独立 Linear直接生成：

$v_k=[u;\,E_{\mathrm{hook}}(k);\,k/20;\,\rho_k]
\in\mathbb R^{128+8+1+2}
=
\mathbb R^{139},$

$q_k^{\mathrm{cls}}=W_Q^{\mathrm{cls}}v_k+b_Q^{\mathrm{cls}},
\qquad
q_k^{\mathrm{gmv}}=W_Q^{\mathrm{gmv}}v_k+b_Q^{\mathrm{gmv}},
\qquad
q_k^{\mathrm{cls}},q_k^{\mathrm{gmv}}\in\mathbb R^{64}.$

#### 3.3.3 两套 Query 如何读取同一份 K/V

将整份 Transformer 输出 $H$ 投影成 64 维 Key 与 Value：

$K_i=W_KH_i+b_K,
\qquad
V_i=W_VH_i+b_V,
\qquad K_i,V_i\in\mathbb R^{64}.$

分类、GMV 共用这套 K/V，但 Key 投影和 Value 投影彼此不是同一套参数。对分支 $t\in\{\mathrm{cls},\mathrm{gmv}\}$，只聚合前 $k$ 个且位于有效长度内的位置：

$\mathcal I_k=\{i:1\le i\le \min(k,L)\},
\qquad
\alpha_{k,i}^{t}
=
\operatorname{softmax}_{i\in\mathcal I_k}
\left(
\frac{(q_k^t)^\top K_i}{\sqrt{64}}
\right),$

$c_k^t
=
\operatorname{ReLU}
\left(
\sum_{i\in\mathcal I_k}\alpha_{k,i}^t V_i
\right)
\in\mathbb R^{64}.$

不同 Query 可以对同一位置给出不同权重。例如分类任务可能更关注候选吸引力、运力等信息，GMV 更关注金额相关信息；这是允许模型学习的分工，不是已经通过 Attention 权重分析证明的固定分工。当 $k=1$ 且只有一个可聚合位置时，两套权重都退化为 1，上下文相同；

实现中按 20 个 $k$ 向量化计算两份 $[B,20,64]$ 上下文，再复用到 28 个折扣组合，形成 $[B,560,64]$。

#### 3.3.4 如何进入 560 个动作的预测

原有动作表示为 27 维：幸运折扣 Embedding 8 维、特价折扣 Embedding 8 维、默勾 Embedding 8 维，加上两项折扣深度及 $k/20$ 三个连续特征：

$a_{d,k}
=
[E_{\mathrm{lucky}}(d_l);
E_{\mathrm{special}}(d_s);
E_{\mathrm{hook}}(k);
1-d_l/100;
1-d_s/100;
k/20]
\in\mathbb R^{27}.$

最后按分支拼接：

$x_{d,k}^{\mathrm{cls}}=[z;\,a_{d,k};\,c_k^{\mathrm{cls}};\,\rho_k],
\qquad
x_{d,k}^{\mathrm{gmv}}=[z;\,a_{d,k};\,c_k^{\mathrm{gmv}};\,\rho_k],$

$\dim(x_{d,k}^t)=384+27+64+2=477.$

所以，同一 $k$ 的上下文与锚点可以复用，但不同折扣的 $a_{d,k}$ 不同，后续预测依然是动作相关的。

### 3.4 幸运盒子展现链硬单调：联合参数化 ECR、CR 与 BCR

#### 3.4.1 先明确约束范围，而不是约束全部 560 个动作

T1H 保留 T1 的完整网络，只在 CR/ECR 输出概率处接入 LM8 的联合硬变换。作用范围必须同时满足：

1. 样本的原始 city_id 属于配置的 77 个城市。

1. 固定同一个冒泡、同一个特价折扣、同一个默勾数 $k$。

1. 只考虑幸运折扣 97、94、91、88、85、82 中配置存在、且对该样本可行的动作。

1. 该链至少包含两个可行节点；单点链不做硬变换。

例如固定特价 100、默勾数 3，若相应动作可行，则构成：

幸运 100：不展现分支，独立保留，不接入以下链。

$97\rightarrow94\rightarrow91\rightarrow88\rightarrow85\rightarrow82.$

沿此幸运折扣链，折扣逐步加深（数值变小）；ECR 不降，CR 不升，BCR 不降。

幸运 100 在当前动作语义中表示不展现，不是展现链的浅折扣起点。如果某个中间档位不可行，就跳过该节点，将上一个可行节点与下一个可行节点衔接，例如 97、91 可行但 94 不可行时，实际约束 $97\to91$，不让 94 的 logit 参与递推。

#### 3.4.2 链首保持自由预测，后续节点改成受限增量

令 $j$ 按幸运折扣由浅到深排列，$z_j^e$、$z_j^c$ 分别为原 ECR/CR Head 的 logit。记链上的概率为 $e_j$、$c_j$，BCR 为 $b_j=e_jc_j$；$\sigma$ 表示 Sigmoid。

对第一个可行节点：

$e_1=\varepsilon+(1-\varepsilon)\sigma(z_1^e),
\qquad
c_1=\sigma(z_1^c),
\qquad
\varepsilon=10^{-7}.$

正下界用于避免后续概率比值除零。对每个后续可行节点，先生成两个介于 0 和 1 之间的系数：

$\eta_j=\sigma(z_j^e-6),
\qquad
\nu_j=\sigma(z_j^c).$

然后联合递推：

$e_j=e_{j-1}+(1-e_{j-1})\eta_j,$

$c_j
=
c_{j-1}
\left[
\nu_j+(1-\nu_j)\frac{e_{j-1}}{e_j}
\right],
\qquad
b_j=e_jc_j.$

$-6$ 来自固定 delta_bias=-6，使 ECR 增量系数在 logit 接近 0 时较小，避免初始化时过快接近 1；它不是新增可训练参数。计算在 FP32 中执行。

需要注意，深折扣节点的两个 logit 不再分别表示“独立 ECR 概率”和“独立 CR 概率”：ECR logit 控制增长步幅，CR logit 控制在允许范围内保留多少 CR，由递推后才得到最终概率。

#### 3.4.3 为什么三个方向能同时成立

首先 ECR 的增量非负：

$e_j-e_{j-1}=(1-e_{j-1})\eta_j\ge0.$

又因为 $e_j\ge e_{j-1}>0$、$0\le\nu_j\le1$，CR 的乘数不会超过 1，因此：

$c_{j-1}\frac{e_{j-1}}{e_j}
\le c_j\le c_{j-1}.$

这不仅规定 CR 不能上涨，还规定它不能下降得太快，以免抵消 ECR 的增长。将递推式乘以 $e_j$：

$b_j-b_{j-1}
=
c_{j-1}(e_j-e_{j-1})\nu_j
\ge0.$

所以三项约束是联合保证的：

$ECR_j\ge ECR_{j-1},
\qquad
CR_j\le CR_{j-1},
\qquad
BCR_j\ge BCR_{j-1}.$

这比“ECR 做递增、CR 做递减后再相乘”更强：后者不能单独保证乘积 BCR 的方向。

#### 3.4.4 一个递推例子

以下仅是公式示意，不是训练样本或真实模型输出。假设浅折扣节点已经得到 $\mathrm{ECR}=0.6000$、$\mathrm{CR}=0.5000$，下一档的增量系数 $\eta=0.2500$、保留系数 $\nu=0.5000$：

$e_{\mathrm{new}}=0.6+(1-0.6)\times0.25=0.7,$

$c_{\mathrm{new}}
=
0.5\left(0.5+0.5\times\frac{0.6}{0.7}\right)
=
\frac{13}{28}
\approx0.4643.$

| 节点 | ECR | CR | $\mathrm{BCR}=\mathrm{ECR}\times\mathrm{CR}$ |
| --- | --- | --- | --- |
| 浅折扣 | 0.6000 | 0.5000 | 0.3000 |
| 下一档深折扣 | 0.7000 | 0.4643 | 0.3250 |

ECR 提高、CR 降低，但 CR 的下降幅度受到限制，所以 BCR 仍提高。

### 3.5 T1H 网络结构总览

下图将共享 Encoder、宽表示晚融合、分类/GMV 双 Query、四分类独立 Joint、GMV 价格锚点残差、幸运盒子展现链硬单调，以及真实动作监督放在同一张图中，串联前述各项方法。

![](https://didoc.didichuxing.com/api/uploadfile?b=didoc2-upload-file-prod&k=images%2F1790090318620%2FrcfN8G3CaJG9PficdJnEc%2Fimage.png&filename=image.png)
