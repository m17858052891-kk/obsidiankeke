# RankLoss 与 Pairwise Loss 如何构造

## 30 秒回答

真实 ITE 不可观测，所以先以 treatment $m$ 对比 100 档 control 构造 IPW 伪 uplift；把 $y\in\{0,1\}$ 改为 $s(y)=2y-1\in\{-1,+1\}$，使未呼叫也有信息。Corr Loss 让预测 uplift 与伪标签在 batch 内的整体高低变化一致，是稠密的全局排序主损失；matched pairwise 则在表征空间匹配相似的 treatment/control 用户，对确定的局部正负顺序施加 logistic/margin 约束，是辅助损失。

## 1. 伪标签：从不可见 ITE 到可学习排序信号

对某个 treatment $m$，令 $W\in\{m,100\}$，$e_m(x)=P(W=m\mid x)$，$e_0(x)=P(W=100\mid x)$。将 outcome 改写为 $s_i=2y_i-1$。一个可用于排序的 transformed/IPW pseudo 可写成：

$$
z_i^{(m)}=s_i\left(\frac{\mathbb{1}(W_i=m)}{e_m(x_i)}-\frac{\mathbb{1}(W_i=100)}{e_0(x_i)}\right)
$$

在随机试验中优先使用已知、且在有效样本上校验过的分流概率；若有效日志比例与实验配置不一致，要使用相应日志口径或重新估计 propensity。该伪标签不是用户级真实 ITE，但在随机化、overlap、SUTVA 等条件下，其条件期望与 uplift 方向相关，适合作为 noisy ranking supervision。

四类样本的方向如下：

| 组别与结果 | $z^{(m)}$ 方向 | 排序含义 |
| --- | --- | --- |
| treatment + call | 正 | 补贴后响应，前排证据 |
| treatment + no-call | 负 | 补贴后仍无响应，后排证据 |
| control + call | 负 | 不补也会呼叫，不应作为高 uplift |
| control + no-call | 正 | 未被激活，存在被补贴拉动的空间 |

若直接用 $y$，所有 no-call 的伪标签变为 0，后两类负/正反事实方向都会坍缩，丢失了大量样本信息；这正是采用 $2y-1$ 的原因。

## 2. Corr Rank Loss：全局、稠密的排序约束

模型输出各档位响应概率 $\hat\mu_m(x)$ 与 $\hat\mu_{100}(x)$，其 rank score 为 $q_i=\hat\tau_m(x_i)=\hat\mu_m(x_i)-\hat\mu_{100}(x_i)$。在每个 treatment-control 子集内计算 Pearson correlation：

$$
\rho_m=\frac{\sum_i(q_i-\bar q)(z_i-\bar z)}{\sqrt{\sum_i(q_i-\bar q)^2+\epsilon}\sqrt{\sum_i(z_i-\bar z)^2+\epsilon}},\qquad
\mathcal L_{corr}=\frac{1}{|\mathcal M|}\sum_m(1-\rho_m)
$$

实践要求：按 treatment 分组计算而不是将各档混算；group 样本数不足或 score 方差近零时跳过/降权；每组可上限采样以防大档位主导；ε 防止数值除零。

Corr 对整体平移和正比例缩放不敏感，优化的是相对方向，更贴近 AUCC 的排序性质。它使用 batch 内全部样本，梯度稠密，因此对 AUCC 的提升通常比纯 pairwise 更强。

## 3. Matched Pairwise Loss：局部、可比的错序修正

全局随机配对会把不可比用户硬拉在一起，因此先在 Stage-1 或 detach 的表示空间 $h(x)$ 中为每个样本寻找另一组的 Top-K 邻居。可以按余弦相似度或负距离加温度 softmax 加权：

$$
w_{ij}=\frac{\exp(sim(h_i,h_j)/T_{match})}{\sum_{j'\in N_K(i)}\exp(sim(h_i,h_{j'})/T_{match})}
$$

只保留具有明确相对方向的 pair。例如：

| pair | 目标 |
| --- | --- |
| treatment-call vs. matched control-no-call | $q_t>q_c$ |
| treatment-no-call vs. matched control-call | $q_t<q_c$ |

令 $d_{ij}\in\{+1,-1\}$ 表示所需顺序，采用平滑 RankNet 形式：

$$
\mathcal L_{pair}=\frac1{|P|}\sum_{(i,j)\in P}w_{ij}\log\left(1+\exp\left(-\frac{d_{ij}(q_i-q_j-margin)}{T_{rank}}\right)\right)
$$

`match_topk=4`、`match_temperature=0.2`、`rank_temperature=1.0`、`margin=0` 是当前 H2 记录中的配置。Top-K 索引本身不可导，通常用于选择/加权 pair；表征可选择 detach，避免模型为了凑配对而扭曲共享表征。

## 4. 为什么二者要联合使用

Corr 负责快速建立整体方向，但容易吸收 batch 内的结构性偏差；pairwise 只用有限的可比 pair，梯度稀疏、匹配也有误差，所以单独效果较弱。联合目标为：

$$
\mathcal L=\mathcal L_{base}+\lambda_c\mathcal L_{corr}+\lambda_p\mathcal L_{pair}
$$

当前 H2 取 $\lambda_c=0.015$、$\lambda_p=0.003$：Corr 为主，Pairwise 为局部约束。所有排序 loss 仅在校准后的 score 空间中计算，详见《10_Zscore与温度系数》。

## 常见追问

**为什么 control-no-call 是正向，不等于该人一定会被拉动？** 它只是总体意义上的相对正证据，不是观察到的反事实结果，故必须配合随机化、IPW、匹配和稳健评估。

**为什么不使用随机 pair？** 相似不是充分条件，但随机 pair 连基本可比性都没有；表征匹配只是降低局部比较噪声，不能被表述为严格反事实配对。
