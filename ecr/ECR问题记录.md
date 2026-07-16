# 一、模型结构与因果表征

# 目录

- [1. Beta Head 为什么没有明显作用？是否因为数据来自 RCT？](#1-beta-head-为什么没有明显作用是否因为数据来自-rct)
- [2. QINI 前段明显偏向 Treatment，是否说明因果指标不可信？](#2-qini-前段明显偏向-treatment是否说明因果指标不可信)
- [3. Cumulative Head 是否会造成梯度叠加与累积误差？](#3-cumulative-head-是否会造成梯度叠加与累积误差)
- [4. FiLM 表征调制有什么作用？](#4-film-表征调制有什么作用)
- [5. ATE 和 ITE 分别是什么？](#5-ate-和-ite-分别是什么)
- [6. 当前 Pseudo Label 的具体构造方式](#6-当前-pseudo-label-的具体构造方式)
- [7. 能否获得“真实的标签纠正估计”或真实 Uplift？](#7-能否获得真实的标签纠正估计或真实-uplift)
- [8. 为什么用 Corr，而不是直接回归 Pseudo？](#8-为什么用-corr而不是直接回归-pseudo)
- [9. 为什么要从 IPW Pseudo 进一步升级到 DR Pseudo？](#9-为什么要从-ipw-pseudo-进一步升级到-dr-pseudo)
- [10. 什么是折外双重鲁棒（OOF/Cross-fitted DR）？](#10-什么是折外双重鲁棒oofcross-fitted-dr)
- [11. “只要把 Treatment 样本往前排，AUCC 就会提高”意味着什么？](#11-只要把-treatment-样本往前排aucc-就会提高意味着什么)
- [12. Score 本身是否也应该做 Rank？](#12-score-本身是否也应该做-rank)
- [13. 为什么需要限制 Stage 2 的可更新自由度？](#13-为什么需要限制-stage-2-的可更新自由度)
- [14. Bi-Anchor / Dual-Anchor 可以怎样设计？](#14-bi-anchor-dual-anchor-可以怎样设计)
- [15. 如何比较 DRCFR 与 XGBoost 学到的排序是否一致？](#15-如何比较-drcfr-与-xgboost-学到的排序是否一致)
- [16. XGBoost 作为纠正模型应该怎样做？](#16-xgboost-作为纠正模型应该怎样做)
- [17. 能否在 Batch 内计算每个折扣边的信噪比，优先训练高 SNR 档位？](#17-能否在-batch-内计算每个折扣边的信噪比优先训练高-snr-档位)
- [18. Auto Research 是否容易过拟合某个数据集？](#18-auto-research-是否容易过拟合某个数据集)
- [19. 什么叫“完全优化到测试集”？](#19-什么叫完全优化到测试集)
- [20. 为什么需要按时间切片验证？](#20-为什么需要按时间切片验证)

# 1. Beta Head 为什么没有明显作用？是否因为数据来自 RCT？

当前判断：RCT 可能是原因之一，但不能直接下结论。

Beta Head 如果主要用于学习 treatment assignment、倾向分或者组间偏差，那么在理想 RCT 中：

$$

P(T=m\mid X)=P(T=m)

$$

Treatment 与特征 \(X\) 理论上独立，Beta Head 可以学习的分流偏差较少，因此它相对于观察性数据的收益可能不明显。

但当前 EDA 已发现 \(X\) 对 73/100 分流具有较高可预测性，说明数据并非完全满足理想的订单行级随机性。可能存在：

- 随机化发生在乘客粒度，训练却使用订单行粒度；
- 同一个乘客重复冒泡，导致各组样本权重不一致；
- RCT 后存在过滤、缺失或者样本选择；
- Beta Head 的 loss 权重过低；
- Beta Head 只修正分流，却没有直接改善 uplift 排序；
- Beta Head 与 Shared Bottom 学到的信息重复。

因此需要用消融实验回答：

1. 移除 Beta Head 后，Call AUCC、ATE error 和 treatment-ratio 是否变化；
2. Beta Head 的 treatment prediction AUC 是否显著高于随机；
3. Beta Head 梯度是否真正进入 Shared Bottom；
4. 按 PID 去重或用户粒度加权后，Beta Head 是否仍然无效。

更严谨的会议表述是：

> Beta Head 没有取得明显收益，可能是因为 RCT 降低了倾向建模的必要性，也可能是当前偏差主要来自订单行重复和样本选择，而不是传统 treatment assignment bias。需要结合 propensity AUC、消融实验及梯度诊断进一步确认。

# 2. QINI 前段明显偏向 Treatment，是否说明因果指标不可信？

当前判断：不能仅凭 treatment-ratio 不平就断言 AUCC/QINI 完全无效，但它是一个非常重要的风险信号。

如果排序只依据真实 uplift，那么在 RCT 条件下，榜单头部的 treatment/control 比例不应出现无法由随机误差解释的系统性倾斜。

如果模型把 treatment 样本集中排在前面，那么 QINI 前段的累计增益可能同时包含：

$$

\text{观测增益} = \text{真实 Treatment Effect} + \text{Treatment Assignment Leakage} + \text{样本频次偏差} + \text{有限样本噪声}

$$

这种情况下，AUCC 上升可能部分来自“识别谁属于 treatment”，而不是“识别谁具有更高 uplift”。

需要同时观察：

- Treatment-ratio 的偏离程度；
- Treatment assignment prediction AUC；
- 排序前 1%、5%、10% 人群的特征 SMD；
- 用户粒度而非订单行粒度的曲线；
- 不同随机种子、日期切片下是否稳定；
- Call AUCC 提升是否伴随 ATE error 或概率校准恶化。

更准确的表述是：

> Treatment-ratio 前段显著偏斜不会自动使 AUCC 失效，但说明模型可能利用了 treatment 身份或重复采样结构。此时 AUCC 应被视为存在偏差风险，需要与 ratio、SMD、跨时间稳定性共同判断。

# 3. Cumulative Head 是否会造成梯度叠加与累积误差？

是的，但要区分“输出累加”和“梯度叠加”。

假设 cumulative head 使用相邻档位增量：

$$

z_{73}=z_{100}+\Delta_{97}+\Delta_{94}+\cdots+\Delta_{73}

$$

那么深折扣档位的输出依赖前面所有增量。对某个浅层增量 \(\Delta_k\)，它会同时接收多个后续档位损失的梯度：

$$

\frac{\partial L}{\partial \Delta_k} = \sum_{m:\Delta_k\in z_m} \frac{\partial L_m}{\partial z_m}

$$

因此可能出现：

- 靠近 control 的增量节点接收更多 treatment 的梯度；
- 某一层误差会传递到后续多个深档输出；
- 深折扣档位的 score 方差更大；
- Rank loss 的噪声可能沿 cumulative path 传播；
- 不同 treatment 之间难以完全解耦。

但 cumulative head 也有明确优势：

- 注入补贴力度与响应概率的单调性先验；
- 减少独立 Head 出现无序、交叉和剧烈波动；
- 在单调关系成立时提高样本效率。

下一步应比较：

- Cumulative Head；
- Independent Head；
- Cumulative Backbone + 独立校准 Head；
- FiLM 调制后的 Cumulative Head。

重点观察每个 treatment head 的梯度范数，以及 73、76、79 等深档是否存在系统性放大。

# 4. FiLM 表征调制有什么作用？

当前多档位模型使用共享的 Embedding 和 Shared Bottom。共享表征可以提高样本效率，但不同折扣档位对用户特征的响应模式不一定完全相同。

FiLM 为每个 treatment 提供轻量级的表征调制：

$$

h_m = \gamma_m\odot h+\beta_m

$$

其中 \(h\) 是共享表征，\(\gamma_m\) 和 \(\beta_m\) 是 treatment-specific 的缩放和偏移参数。

它的作用是：

- 保留 Shared Bottom 的主要信息；
- 给不同 treatment 少量独立表征能力；
- 缓解共享表征与多 Arm Head 之间的梯度冲突；
- 比完全独立 Tower 参数量更小、稳定性更高；
- 可作为不同档位的弱校准层。

需要注意，FiLM 只能缓解表征冲突，不能单独解决 treatment leakage 或伪标签偏差。

建议优先尝试：

$$

h_m=(1+\alpha\gamma_m)\odot h+\alpha\beta_m

$$

初始设置较小的 \(\alpha\)，使 FiLM 从接近恒等映射开始，避免训练初期破坏 Anchor。

# 二、ATE、ITE 与伪标签

# 5. ATE 和 ITE 分别是什么？

ATE 是总体平均处理效应：

$$

ATE_m = \mathbb E[Y(m)-Y(100)]

$$

它回答的是：

> 平均而言，给用户发第 \(m\) 档补贴，相比 100 档能够增加多少呼叫？

ITE 是个体处理效应：

$$

ITE_{i,m} = Y_i(m)-Y_i(100)

$$

它回答的是：

> 对具体用户 \(i\)，第 \(m\) 档补贴能够增加多少呼叫？

问题在于，同一个用户只能观测一个潜在结果，因此真实 ITE 无法直接观察。模型输出的：

$$

\hat \tau_m(x) = \hat p_m(x)-\hat p_{100}(x)

$$

只是 CATE/ITE 的模型估计，不是真实标签。

AUCC 主要评估模型能否根据 \(\hat\tau_m(x)\) 对用户进行有效排序，而不是要求精确恢复单个用户的真实 ITE。

# 6. 当前 Pseudo Label 的具体构造方式

对于 treatment \(m\) 与 control 100，使用：

$$

\phi_{i,m}^{IPW} = \tilde y_i \left[ \frac{\mathbb I(T_i=m)}{\hat e_m(x_i)} - \frac{\mathbb I(T_i=100)}{\hat e_{100}(x_i)} \right]

$$

其中：

$$

\tilde y_i=2y_i-1

$$

在理想 RCT 下，\(\hat e_m(x)\) 可以使用实验分流概率；如果分流概率不均衡，也可以使用估计 propensity，但要做 clipping。

采用 \(2y-1\) 后，伪标签方向如下：

|样本状态|Pseudo 方向|含义|
|---|---|---|
|Treatment、\(y=1\)|正|Treatment 下发生呼叫|
|Treatment、\(y=0\)|负|Treatment 下仍未呼叫|
|Control、\(y=1\)|负|不补贴也会自然呼叫|
|Control、\(y=0\)|正|可能存在被补贴激活的空间|

需要强调：这不是单样本真实 uplift，而是具有较高方差的 transformed outcome。它在总体期望意义上提供因果监督。

# 7. 能否获得“真实的标签纠正估计”或真实 Uplift？

无法获得单个用户的真实 ITE 标签，因为反事实不可观测。

可以获得或近似获得的只有：

1. RCT 下的总体 ATE；
2. 足够大子群上的 subgroup uplift；
3. IPW transformed outcome；
4. DR pseudo outcome；
5. Cross-fitted DR pseudo outcome；
6. 重复实验或特殊实验设计下的近似个体效应。

因此，伪标签的可信度不能通过“与真实 ITE 做误差比较”验证，而应通过以下方式验证：

- Pseudo 的分组均值能否还原 RCT ATE；
- 按 pseudo 分桶后，真实 treatment-control uplift 是否单调；
- 在独立验证集上，pseudo 高分组是否有更高真实增量；
- 不同 nuisance model 生成的 pseudo 排序是否稳定；
- 跨时间、跨城市、跨随机种子是否一致。

# 8. 为什么用 Corr，而不是直接回归 Pseudo？

主要因为 AUCC 关注排序，不要求预测 uplift 与 pseudo 在数值上完全相等。

相关性损失为：

$$

L_{\mathrm{corr}} = 1-\operatorname{Corr}(s,\phi)

$$

它关注 \(s\) 与 \(\phi\) 的共同变化方向，并且对平移和正比例缩放不敏感：

$$

\operatorname{Corr}(s,\phi) = \operatorname{Corr}(as+b,\phi),\qquad a>0

$$

而 MSE、Huber 等回归损失要求数值尺度接近。由于 IPW/DR pseudo 通常方差较大，直接回归很容易被极端值控制。

Corr 的优势是更贴近排序目标，缺点是：

- 对 batch 构成敏感；
- 可能利用 treatment 侧结构性差异；
- 只保证整体趋势，不保证局部样本顺序；
- 相关性高不代表因果估计无偏。

因此当前采用 Corr 作为主要排序信号，再用 Matched Pairwise 补充局部约束。

# 三、从 IPW 到 DR 与 Cross-Fitting

# 9. 为什么要从 IPW Pseudo 进一步升级到 DR Pseudo？

IPW 只依赖 propensity：

$$

\phi_{i,m}^{IPW} = Y_i \left[ \frac{\mathbb I(T_i=m)}{e_m(X_i)} - \frac{\mathbb I(T_i=100)}{e_{100}(X_i)} \right]

$$

当 propensity 很小或者估计不准时，IPW 权重会放大，导致伪标签方差很高。

DR 同时使用 propensity model 和 outcome model：

$$

\phi_{i,m}^{DR} = \hat\mu_m(X_i)-\hat\mu_{100}(X_i) + \frac{\mathbb I(T_i=m)}{\hat e_m(X_i)} \left[Y_i-\hat\mu_m(X_i)\right] - \frac{\mathbb I(T_i=100)}{\hat e_{100}(X_i)} \left[Y_i-\hat\mu_{100}(X_i)\right]

$$

其中：

$$

\hat\mu_m(X)=\mathbb E[Y\mid X,T=m]

$$

DR 的理论优势是：propensity model 和 outcome model 只要有一个估计正确，处理效应估计仍具有一致性。

但“双重鲁棒”不代表在有限样本中一定比 IPW 排序更好。DR 仍可能受到：

- Outcome model 偏差；
- 极端 propensity；
- Nuisance model 过拟合；
- 残差项长尾；
- 个体 pseudo 方差过高；
- 训练样本内预测泄漏；

的影响。

当前实验中 DR 排序未稳定超过 IPW，说明理论上的双重鲁棒性没有自动转化为更好的个体排序监督。

# 10. 什么是折外双重鲁棒（OOF/Cross-fitted DR）？

如果 nuisance model 在样本 \(i\) 上训练后，又为同一个样本生成 \(\hat\mu(X_i)\) 和 \(\hat e(X_i)\)，模型可能记忆标签，导致 DR residual 过于乐观。

Cross-fitting 的做法是：

1. 将训练集划分为 \(K\) 折；
2. 用其余 \(K-1\) 折训练 nuisance model；
3. 只为未参与训练的第 \(k\) 折生成 pseudo；
4. 合并所有折外预测；
5. 使用 OOF DR pseudo 训练最终排序模型。

这样每个样本的 pseudo 都由“没有见过该样本标签”的 nuisance model 生成，可减少过拟合偏差。

问题是 OOF 训练成本大约增加到原 nuisance 训练的 \(K\) 倍。因此需要比较：

- 非 OOF DR；
- 2-Fold DR；
- 5-Fold DR；
- OOF 只生成一次并缓存；
- 较轻量的 XGBoost/LightGBM nuisance model。

# 四、排序指标与 Treatment-ratio

# 11. “只要把 Treatment 样本往前排，AUCC 就会提高”意味着什么？

这是一个需要重点防范的指标捷径。

在有限样本下，如果榜单前部 treatment 样本明显多于 control，累计 treatment outcome 会更早增加，从而可能把 QINI/AUCC 曲线抬高。

此时提升可能来自两部分：

$$

\widehat{AUCC} = \text{真实 Uplift 排序能力} + \text{Treatment Composition Bias}

$$

因此，模型不能只看 AUCC，还需要检查：

- 排名前 \(k\%\) 的 treatment-ratio；
- 标准化后的 ratio gap；
- treatment/control 的有效样本量；
- 头部人群的特征 SMD；
- 用户粒度重新采样后的 AUCC；
- 在保持 treatment/control 配比下的 AUCC。

核心判断是：

> 如果 AUCC 的提升主要依赖 treatment 样本集中进入榜单头部，那么它可能不是可泛化的 uplift 排序能力。

# 12. Score 本身是否也应该做 Rank？

可以，但要明确排序对象。

模型最终排序分数为：

$$

s_{i,m}=\hat p_m(x_i)-\hat p_{100}(x_i)

$$

可以对 score 加入三类约束：

1. Score 与因果 pseudo 的全局相关性；
2. Score 在 matched pair 中的相对顺序；
3. Score 相对于 Stage 1 Anchor 的偏移限制。

不建议只对 treatment probability \(\hat p_m\) 做排序，因为这会优先学习自然呼叫率。排序目标应该作用于 treatment-control 差值，而不是单独的 factual probability。

还可以加入 Anchor 正则：

$$

L_{\mathrm{anchor}} = \mathbb E\left[ (s_{i,m}^{stage2}-s_{i,m}^{stage1})^2 \right]

$$

它可以限制 Rank Stage 过度改变原有 uplift score。

# 五、限制模型自由度与双 Anchor

# 13. 为什么需要限制 Stage 2 的可更新自由度？

Rank pseudo 的噪声通常高于 factual label。如果所有参数同时更新，模型可能通过改变 Shared Bottom 快速拟合伪标签中的 treatment leakage。

因此，当前采用：

- Stage 1：仅训练 factual response；
- Stage 2 前期：冻结 Embedding 和 Shared Bottom，只训练 Head；
- Stage 2 后期：只小幅解冻 Shared Bottom；
- Shared Bottom 学习率为 Head 的 \(0.01\) 倍；
- 保留 factual loss 约束；
- 控制 Corr 和 Pairwise 权重；
- 使用较短 Rank Stage。

其本质是：

$$

\min_\theta L_{\mathrm{rank}}(\theta) \quad \text{s.t.} \quad \|\theta-\theta_{\mathrm{anchor}}\|\leq\delta

$$

即在 Stage 1 Anchor 邻域内优化排序，而不是重新训练整个模型。

# 14. Bi-Anchor / Dual-Anchor 可以怎样设计？

可以保留两个不同含义的 Anchor。

第一个是 Response Anchor：

$$

s^{resp}_{i,m} = \hat p^{stage1}_m(x_i)-\hat p^{stage1}_{100}(x_i)

$$

它负责保证响应概率与 treatment-ratio 相对稳定。

第二个是 Rank Anchor：

$$

s^{rank}_{i,m}

$$

它由 Corr 和 Pairwise 优化，负责提高 AUCC。

最终分数可以写成：

$$

s^{final}_{i,m} = s^{resp}_{i,m} + g_{i,m} \left( s^{rank}_{i,m}-s^{resp}_{i,m} \right)

$$

其中 \(g_{i,m}\in[0,1]\) 是门控系数。

也可以使用固定权重：

$$

s^{final} = (1-\alpha)s^{resp} + \alpha s^{rank}

$$

Bi-Anchor 的优势是把“概率响应可信度”和“排序区分度”分开建模。风险是 Gate 可能坍缩到全 0 或全 1，因此必须监控 Gate 分布和最终 score 偏移。

# 六、模型一致性与替代模型诊断

# 15. 如何比较 DRCFR 与 XGBoost 学到的排序是否一致？

可以将 XGBoost/LightGBM 作为独立的浅层模型或 nuisance model，比较两套 score 的：

- Spearman 相关系数；
- Kendall Tau；
- Top 1%、5%、10% 人群重合率；
- 分 treatment 的排序相关性；
- 分城市、日期和频次人群的一致性；
- 两者 disagreement 最大的样本特征。

例如：

$$

\rho_m = \operatorname{Spearman} \left( s_m^{DRCFR}, s_m^{XGB} \right)

$$

但需要注意：

> 两个模型排序一致，不代表排序就是真实；排序不一致，也不代表深度模型一定错误。

如果两个结构差异较大的模型，在独立验证集上对同一批高 uplift 人群达成一致，可信度会更高。真正的验证仍然要看分桶后的 RCT uplift。

XGBoost 还可以承担以下角色：

- Outcome nuisance model；
- Propensity model；
- DR pseudo 生成器；
- 深度模型 score 的 residual corrector；
- 用于识别深度模型可能捕捉到的非线性捷径。

# 16. XGBoost 作为纠正模型应该怎样做？

可以先训练主模型获得：

$$

s^{deep}_{i,m}

$$

再使用 OOF 数据训练 XGBoost 预测 DR residual 或 subgroup uplift：

$$

r_{i,m} = \phi^{DR}_{i,m}-s^{deep}_{i,m}

$$

最终分数为：

$$

s^{final}_{i,m} = s^{deep}_{i,m} + \eta\hat r^{XGB}_{i,m}

$$

但必须满足：

- XGBoost 只使用训练集或 OOF 标签；
- \(\eta\) 在验证集选择；
- 不得使用测试集调参；
- 需要比较纠正前后的 AUCC、ratio 和校准；
- 防止 XGBoost 再次利用 treatment assignment 特征。

# 七、按信噪比动态分配 Rank Loss

# 17. 能否在 Batch 内计算每个折扣边的信噪比，优先训练高 SNR 档位？

思路可行，但不建议直接使用单 Batch 的 SNR 决定是否加入某个 treatment 的 Rank Loss。

可定义：

$$

SNR_m = \frac{|\mathbb E[\phi_m]|} {\sqrt{\operatorname{Var}(\phi_m)}+\epsilon}

$$

或者使用有效样本量：

$$

ESS_m = \frac{\left(\sum_i w_{i,m}\right)^2} {\sum_i w_{i,m}^2}

$$

然后设置档位权重：

$$

\lambda_m = \frac{f(SNR_m,ESS_m)} {\sum_kf(SNR_k,ESS_k)}

$$

风险在于：

- Batch 内 treatment 样本可能很少；
- 单 Batch 均值和方差波动很大；
- 73 vs. 100 样本更多，不代表其因果信号更可信；
- 模型可能长期忽略低频档位；
- 深档位可能因为样本量大而获得更高权重，进一步放大 cumulative gradient。

更合理的方式是：

- 使用 Train-only 全局统计量；
- 或维护跨 Batch 的 EMA；
- 对权重设置上下界；
- 保证每个 treatment 都有最低训练权重；
- 不使用验证集或测试集计算 SNR；
- 同时监控每个 Arm 的 ESS、pseudo 方差及 AUCC。

# 八、Auto Research 与泛化风险

# 18. Auto Research 是否容易过拟合某个数据集？

是的。自动搜索可能反复使用同一验证集选择：

- Loss 权重；
- 温度；
- 解冻层数；
- Rank Epoch；
- Pairwise 参数；
- Score calibration；
- Head 结构。

即使完全没有训练测试集，重复查看同一个验证集也会形成 validation overfitting。

搜索到的最优参数可能只适用于：

- 当前日期；
- 当前城市分布；
- 当前 treatment ratio；
- 当前用户频次结构；
- 当前随机种子。

建议采用多层评估：

1. 训练集用于拟合参数；
2. Validation-A 用于模型选择；
3. Validation-B 或时间外数据用于二次确认；
4. Test 集只进行一次最终评估；
5. 使用多随机种子报告均值与方差；
6. 限制自动搜索次数；
7. 优先搜索具有明确机制解释的参数。

最终模型不应只看单次最高 AUCC，而应考虑：

$$

\text{Score} = \text{AUCC} -\lambda_1\text{RatioRisk} -\lambda_2\text{SeedVariance} -\lambda_3\text{ATEError}

$$

# 19. 什么叫“完全优化到测试集”？

如果根据测试集结果反复修改：

- Loss；
- 模型结构；
- 特征；
- 清洗规则；
- Epoch；
- 超参数；

那么测试集实际上已经成为验证集，其结果不能再视为无偏泛化性能。

尤其是根据测试集中的具体异常 PID、城市或时段删除样本，属于明显的数据泄漏。

正确流程应为：

- 清洗规则只根据训练集制定；
- Validation/Test 中不能因为结果不好而删除特定 PID；
- 验证集用于选择模型；
- 测试集只用于最终锁定后的单次报告；
- 如果测试集已经被多轮用于决策，应重新准备 untouched holdout。

# 九、时间切片与特征穿越

# 20. 为什么需要按时间切片验证？

当前特征中存在历史频次、历史价格、历史呼叫率等统计特征。如果随机切分数据，可能出现：

- 同一用户相近时段同时进入训练集和验证集；
- 使用未来订单计算历史统计量；
- 用户当天后续行为泄漏到早期样本；
- 训练集和验证集共享高度相似的重复冒泡记录；
- 离线性能高估线上泛化能力。

因此建议采用时间切片：

$$

\text{Train Time} < \text{Validation Time} < \text{Test Time}

$$

并保证每个统计特征只使用样本时点之前的数据：

$$

X_i(t) = f\left(\mathcal H_i(<t)\right)

$$

需要重点检查：

- 特征统计窗口的结束时间；
- 是否包含当天未来行为；
- 同用户同天重复记录是否跨集合；
- Treatment assignment 是否在统计特征生成之后发生；
- 标签窗口是否与特征窗口重叠；
- PID 分割与时间分割的结果差异。

# 建议会议重点追问

1. Beta Head 的理论作用到底是修正 propensity、representation imbalance，还是 treatment-specific response？
2. 当前 RCT 是在哪个粒度随机化：乘客、乘客日、冒泡还是订单行？
3. Treatment-ratio 偏斜是否超出随机误差范围？是否在用户粒度仍然存在？
4. Cumulative Head 各增量节点的梯度范数是否随深度系统性放大？
5. Pseudo label 在验证集分桶后，真实 RCT uplift 是否单调？
6. DR 不如 IPW 是 nuisance model 偏差，还是 pseudo 方差过高？
7. OOF DR 能否先用轻量模型低成本验证，而不是直接训练多折 DRCFR？
8. AUCC 提升中有多少来自真实排序，有多少来自 treatment composition？
9. Stage 2 是否需要显式 Anchor regularization，而不仅依赖冻结参数？
10. 当前测试集是否已被反复用于模型选择？是否需要新的时间外 holdout？
11. FiLM 应用于所有档位还是只用于深折扣档位？如何防止自由度过大？
12. 动态 SNR 权重应该基于全局 Train-only 统计，还是 EMA？最低档位权重如何保证？
