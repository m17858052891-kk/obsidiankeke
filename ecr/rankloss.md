---
tags: [ECR, Uplift, RankLoss, IPW, AUCC, 面试]
---

# ECR Rank Loss：从 IPW 伪标签到 Uplift 排序

> 完整项目叙事见 [[模型搭建思路逐字稿]]。本文解释伪标签、Corr、Pairwise 与 score 校准。

## 1. 为什么不能直接用真实标签监督？

对用户 $x$，只能观察实际档位下的 $Y(T)$，看不到反事实 $Y(C)$；目标却是：

$$\tau_t(x)=\mu_t(x)-\mu_c(x).$$

因此，treatment 组的“呼叫”不等于高 uplift；它只是在随机分流或倾向校正后提供因果排序证据。

## 2. IPW 伪标签

对档位 $t$ 与 control $c$ 的子样本，令 $e_t(x)=P(T=t|x)$。用 $2Y-1$ 保留未呼叫的负向信息：

$$
\tilde\tau_t=
\frac{\mathbb 1[T=t](2Y-1)}{e_t(x)}
-\frac{\mathbb 1[T=c](2Y-1)}{e_c(x)}.
$$

在随机分流/正确倾向估计和 overlap 成立时：

$$E[\tilde\tau_t|x]=2(\mu_t(x)-\mu_c(x)).$$

它不是单用户真实 ITE，而是高方差、总体方向正确的伪监督。若直接使用 $Y\in\{0,1\}$，未呼叫样本都变为 0；用 $2Y-1$ 后，未呼叫也能提供排序方向。

## 3. Corr Loss：全局排序方向

模型分数为 $s_t(x)=\hat\mu_t(x)-\hat\mu_c(x)$。在有效 batch 内：

$$\rho=\operatorname{Corr}(s,\tilde\tau),\qquad \mathcal L_{corr}=1-\rho.$$

它不要求 score 数值拟合 noisy pseudo label，只要求高低变化同向，因此比 MSE 更贴近 AUCC/Qini。代价是依赖 batch 统计量；batch 小、伪标签方差高或 treatment assignment 有结构偏差时，梯度可能不稳定。

## 4. Matched Pairwise Loss：局部错序修正

对可信方向的样本对 $(i,j)$：

$$\mathcal L_{pair}=\operatorname{softplus}\left(-r_{ij}\frac{s_i-s_j}{\gamma}\right),$$

其中 $r_{ij}\in\{+1,-1\}$ 是期望顺序。项目应在相近表征/协变量的 treatment-control 样本中做 Top-K 软匹配；任意随机配对会把人群差异误学成 treatment 效应。

Corr 是全局、稠密方向约束；Pairwise 是局部、稀疏错序修正。前者通常主导整体 AUCC，后者作为补充。

## 5. Z-score + Tanh

不同折扣档位的 score 尺度和长尾不同。仅在 rank loss 内做：

$$z_i=\frac{s_i-\mu_t}{\sigma_t+\epsilon},\qquad \bar s_i=\tanh(z_i/T).$$

$T$ 大时更接近线性，$T$ 小时更快饱和。这不修改 factual head 的响应概率，只控制排序梯度。

## 6. TwoStage 下的完整目标

第一阶段只训练 factual response loss，得到稳定 anchor；第二阶段保留该 loss，并加入：

$$\mathcal L=\mathcal L_{factual}+\lambda_{corr}\mathcal L_{corr}+\lambda_{pair}\mathcal L_{pair}.$$

Head 可适应排序；Embedding 冻结、Shared Bottom 小学习率软解冻，限制 noisy rank gradient 污染表征。最终同时看 AUCC/Qini、treatment-ratio、factual LogLoss/校准、OOT 和多 seed。

## 7. 30 秒回答

> 真实 ITE 不可观测，所以我在 treatment 对 control 的子样本上，用 IPW 和 $2y-1$ 构造总体方向正确但高方差的 uplift 伪标签。Corr Loss 建立全局排序方向，Matched Pairwise 修正相近用户间的局部错序。各档位只在 rank loss 内做 Z-score 和带温 Tanh，最后用 factual anchor 加 TwoStage soft-unfreeze，避免排序梯度带偏响应表征。
