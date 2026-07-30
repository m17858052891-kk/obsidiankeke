---
tags: [ECR, Uplift, CFR, 排序, 面试]
---

# ECR 多档位补贴 Uplift 排序：核心 10 问

## 0. 一分钟项目介绍

项目面对多档位补贴，目标不是预测谁会呼叫，而是找出“给某档补贴后真正多呼叫”的用户。原 CFR 预测各档位 factual response，但训练目标与 Call AUCC 的增量排序目标不完全一致。我在 CFR 基础上用 IPW 的 $2y-1$ 伪标签提供排序监督，以 Corr Loss 建立全局排序、Matched Pairwise 修正局部顺序；再通过 TwoStage 和软解冻防止排序梯度破坏响应表征。最终在 Qini treatment-ratio 相对稳定的候选中选择 Call AUCC 更优的方案。

## 1. 为什么响应预测不等于 Uplift？

响应预测估计 $P(Y=1\mid X,T=m)$；Uplift 估计：

$$
\tau_m(x)=P(Y=1\mid X=x,T=m)-P(Y=1\mid X=x,T=0).
$$

天然高呼叫用户即使不发券也会呼叫，绝对响应高却未必值得补贴。策略应优先覆盖增量更大的人。

## 2. CFR baseline 输出什么，线上按什么排序？

CFR 用 Shared Bottom 加 treatment-specific heads 输出各档位响应概率 $\hat p_m(x)$。对档位 $m$，离线 uplift score 是：

$$
s_m(x)=\hat p_m(x)-\hat p_0(x).
$$

单档评估按 $s_m$ 排；多档上线还应将 uplift 与补贴成本、业务收益合成净增量价值后选档。

## 3. 真实 ITE 看不到，如何训练排序？

同一用户不能同时观察 treatment 与 control 结果，因此构造 IPW 伪标签。对于档位 $m$ 与 control：

$$
\phi_{i,m}=(2y_i-1)\left[
\frac{\mathbb I(T_i=m)}{e_m(X_i)}-
\frac{\mathbb I(T_i=0)}{e_0(X_i)}
\right].
$$

它不是个人真实 ITE，但在随机分流/倾向校正下，其条件期望提供增量排序方向。

## 4. 为什么要用 $2y-1$，而不是原始 $y$？

若用 $y\in\{0,1\}$，所有未呼叫样本伪标签为 0，treatment 未呼叫与 control 未呼叫无法区分。映射到 $\{-1,+1\}$ 后，treatment 呼叫为正向证据、treatment 未呼叫为负向证据；control 呼叫说明自然会呼叫，给负向证据；control 未呼叫则相对保留“可被激励”的正向方向。它增加信息利用，但也增加单样本噪声。

## 5. 为什么 Corr Loss 比直接 MSE 更适合？

AUCC 主要关心高 uplift 是否排在前面，而非预测值是否精确拟合高方差 IPW 伪标签的绝对尺度：

$$
\mathcal L_{\mathrm{corr}}=1-\operatorname{Corr}(s_m,\phi_m).
$$

Corr 对整体平移、缩放相对不敏感，推动高伪标签对应高 score；MSE 易被小 propensity 造成的极值主导。Pairwise 作为辅助约束，补充局部谁应排前的关系。

## 6. 为什么不从第一步就加入所有 Rank Loss？

伪标签和排序梯度噪声大，直接回传到 Embedding/Shared Bottom 容易使模型记住 treatment assignment、高频用户等捷径，出现 AUCC 虚高但 factual 表征和 ratio 变差。TwoStage 先用 factual BCE 学稳定多档响应，再冻结 Embedding、主训 Head，并以约 1% 学习率温和解冻 Shared Bottom。

## 7. 为什么要在排序损失内做 Z-score + Tanh？

不同 treatment 的 uplift score 尺度和 IPW 方差不同。按 treatment 内标准化后：

$$
\tilde s=\tanh(z/T),
$$

可以压缩长尾极值、让各档排序梯度更可比。该校准只用于 rank loss，不替代最终具有业务含义的 factual probability；$T=2$ 是实验折中而非理论常数。

## 8. AUCC/Qini 如何验证排序？

按 $s_m$ 排序，逐步扩大 Top 人群，在每个截断点比较 treatment 与 control 的真实响应差异。Qini 常用累计增量：

$$
Q(q)=Y_T(q)-Y_C(q)\frac{N_T(q)}{N_C(q)}.
$$

AUCC/Qini 都希望曲线前段更高，表示有限预算优先投头部人群能带来更多增量；它们不是普通 Call AUC。

## 9. 为什么还要看 treatment-ratio 曲线？

若高分桶中 treatment/control 占比明显偏离实验设计比例，模型可能学到了历史分配或 treatment identity，导致分桶内反事实不可比、Control 太少且 AUCC 被虚高。Ratio 不平不自动等于模型错误，但必须结合 propensity、协变量平衡、跨时间验证与线上实验判断。

## 10. 最终如何选模型、如何上线？

不按单一最高 AUCC 选模型，而是在 AUCC、Qini/ratio 稳定、factual 指标、跨时间一致性之间折中。上线时比较各档位的增量收益减补贴成本，并在预算约束下选人、选档；离线 uplift 是候选策略依据，真实收益仍需小流量实验验证。

