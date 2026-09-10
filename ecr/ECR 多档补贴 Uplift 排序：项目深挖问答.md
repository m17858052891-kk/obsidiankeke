
## 一、指标与评估

### 1. 为什么主指标是 Call AUCC，而不是普通 AUC？

普通 AUC 衡量的是 call 与 no-call 的区分能力，无法区分“本来不发券也会 call 的自然高响应者”和“因为发券才新增 call 的可拉动者”。补贴决策要找后者，因此按预测 uplift 排序并评价累计 call 增量的 Call AUCC 才是主业务指标。

当前项目把 100 档作为 control，对任一补贴档位 $m$，以 $\hat\tau_m(x)$ 降序排序。对前 $k$ 个样本，一种累计增量估计可写为：

$$
U(k)=\sum_{i\le k,W_i=m}y_i-
\frac{n_m(k)}{n_{100}(k)}
\sum_{i\le k,W_i=100}y_i
$$

具体实现也可能使用 IPW、不同归一化或跨档聚合方式。因此报告任何 AUCC 数字前，都必须说明 treatment/control 对、纵轴、随机基线和聚合口径。

### 2. AUCC、AUUC、Qini 有什么区别？

- **AUUC**：通常是累计 uplift 曲线下面积；
- **AUCC / Call AUCC**：业务或代码中常指累计增量曲线面积，本项目强调累计 call 增量；
- **Qini**：同样基于排序后的 treatment-control 增量，但更强调组样本量校正，常报告相对随机策略的面积差。

Qini coefficient 的一种常见表达为：

$$
Q=\int_0^1\{Qini(q)-Qini_{random}(q)\}\,dq
$$

这些名称没有唯一统一实现，因此不能因为都叫 AUCC/AUUC/Qini 就直接横向比较。当前选型以 Call MTAUCC 为主，同时报告各档 AUCC/Qini、Random、ATE error 和 treatment-ratio。

### 3. 为什么 AUCC 高还要看 Qini treatment-ratio？

Qini/AUCC 的局部增量估计要求排序后 treatment 与 control 仍有可比性。对档位 $m$ 相对 100 档、某个累计 Top-$q$ 人群：

$$
r(q)=\frac{\sum_{i\in Top(q)}\mathbb{1}(W_i=m)}{|Top(q)|}
$$

应比较同一评估切片的有效实验比例：

$$
p_m=\frac{N_m}{N_m+N_{100}}
$$

若高分头部的 $r(q)$ 持续、显著偏离 $p_m$，可能说明 score 学到了 treatment assignment、曝光结构或过滤痕迹。它是重要诊断护栏，但不是单独判定模型无效的证据：真实异质性、有限样本和有效分流比例计算错误也可能造成偏离。

### 4. 如何判断 ratio 是随机波动还是异常？

同时检查 Top 5%/10%/20% 的累计 ratio、等量分桶 ratio、分档位曲线、时间/城市/用户频次切片和多 seed 结果。若桶内样本量为 $n_b$，可先用二项近似：

$$
SE(r_b)\approx\sqrt{\frac{p_m(1-p_m)}{n_b}}
$$

画出 $p_m\pm1.96SE$ 参考带；小样本深档位更适合 bootstrap 区间。异常应表现为样本量足够时连续多个头部桶偏离，且跨切分复现，而不是小桶的偶然锯齿。

### 5. AUCC 很高、ratio 变差时怎么办？

不直接选择离线 AUCC 最高的模型。先核验有效分流比例、去重与过滤规则、特征时间截点、重复 PID、高频曝光和可能泄漏的分组字段；再做分档位、时间、城市、频次与多 seed 复查。当前项目最终选择的是 ratio 相对平稳候选中的 Call MTAUCC 最优点，而不是全局 AUCC 峰值。

## 二、除了 CFR 或 Corr Loss，还做了哪些尝试？

### 6. 为什么不只训练原 CFR？

CFR 用 shared representation、各 treatment head 和 factual BCE 估计 observed-arm response。其优势是有稳定的观测标签监督；局限是 BCE 只优化“实际档位下是否 call”，并不要求增量大的用户排在前面。因此 factual AUC 高而 Call AUCC 不高是可能的。

### 7. 为什么不用 MSE 或 Huber 直接回归 uplift 伪标签？

当前排序监督使用 treatment $m$ 与 100 control 的 IPW/PU pseudo：

$$
z_i^{(m)}=(2y_i-1)
\left(
\frac{\mathbb{1}(W_i=m)}{e_m(x_i)}-
\frac{\mathbb{1}(W_i=100)}{e_{100}(x_i)}
\right)
$$

IPW 受 inverse propensity 放大，二元 outcome 噪声大，深档位样本少时方差更高。MSE/Huber 都在要求模型拟合伪标签绝对值；但这里伪标签的定位是总体排序方向，并非单用户真实 ITE。故采用 Corr，使预测 uplift 与伪标签的相对变化一致，更接近 AUCC 的排序目标。

### 8. 为什么 Corr 是主损失，Pairwise 只是辅助？

按档位在 treatment-control 子集中计算：

$$
\mathcal L_{corr}=
\frac{1}{|\mathcal M|}
\sum_m\left[1-Corr(\tilde q^{(m)},z^{(m)})\right]
$$

Corr 使用整个 batch，是稠密的全局排序梯度，提升 AUCC 的能力更强。Matched Pairwise 只使用表征空间中相近的异组样本对，约束 treatment-call 排在 matched control-no-call 前、treatment-no-call 排在 matched control-call 后：

$$
\mathcal L_{pair}=
\frac1{|P|}\sum_{(i,j)\in P}w_{ij}
\log\left(1+\exp\left(-\frac{d_{ij}(q_i-q_j-margin)}{T_{rank}}\right)\right)
$$

Pairwise 的局部可比性更好，但有效 pair 稀疏、匹配仍有噪声，单独训练的提升有限；因此当前结论是 Corr 为主、Pairwise 为辅。

### 9. 强 Corr 带来了什么问题？

强 PU-Corr/IPW-Corr 的 AUCC 提升最明显，但 Qini treatment-ratio 风险最大。已观察到的现象是高分人群中 control 占比异常偏高，意味着 score 与实验分组身份产生了不应有的关联。

能确认的是“ratio 异常”；不能仅凭曲线断言具体是哪一种四格样本造成。要进一步归因，需要按 score bucket 拆分 treatment-call、treatment-no-call、control-call、control-no-call。

### 10. 为解决 ratio 风险，具体尝试过什么？为什么没有单独采用？

| 尝试                   | 观察与取舍                                                    |
| -------------------- | -------------------------------------------------------- |
| Factual CFR baseline | ratio 相对可控，但 Call MTAUCC 较低，记录约 0.59046；未直接优化 uplift 排序。 |
| Pairwise only        | 记录约 0.60117；局部约束有效但梯度稀疏、匹配噪声大。                           |
| 强 PU-Corr/IPW-Corr   | AUCC 上升最强，强 IPW-Corr 记录可达约 1.01302；ratio 风险最大。           |
| 清理极端 PID             | 能降低异常重复曝光影响，但不能替代排序结构约束。                                 |
| user-day 频次降权        | 能部分抑制高频样本主导，但会一并压低真实高价值机会，Random/主指标受损。                  |
| 仅做 Z-score + Tanh    | 对 AUCC 有帮助，但无法消除强 rank 下的 assignment artifact。           |
| Stage-2 hard-freeze  | ratio 更稳，但只更新 head，排序收益有限。                               |
| 更强 soft-unfreeze     | 可取得更高 AUCC，但 rank 风险回潮。                                  |
| 延长 H2 训练             | e8 的 Call MTAUCC 从约 0.65293 降至约 0.63490，说明“训练更久”不是瓶颈解法。  |

### 11. H2 Soft T2 为什么是当前推荐方案？

它不是所有实验中 AUCC 的最高点，而是 ratio 相对平稳候选中 Call MTAUCC 最高的折中点。流程是：

1. Stage 1 只训练 CFR factual/base objective，得到 response/uplift anchor；
2. Stage 2 保留 base loss，加入按档校准后的 PU-Corr 与 matched pairwise；
3. 先冻结 embedding 与 shared bottom，只训练 heads；
4. 之后 embedding 继续冻结，以 `0.01 × lr_head` 软解冻 shared bottom；
5. 采用 Corr=0.015、Pairwise=0.003、温度 $T=2$。

记录结果为 Call MTAUCC 0.65293、Avg AUCC 0.3769、Avg Qini 0.1728。

### 12. Z-score 与 Tanh 分别解决什么？

不同档位的 uplift score 均值、方差和长尾不同。若直接进入 Corr/Pairwise，方差大或极值多的档位会获得更强梯度。当前只在 rank loss 内做按档校准：

$$
u_i=\frac{q_i-\operatorname{stopgrad}(\mu_m)}
{\operatorname{stopgrad}(\sigma_m)+\epsilon},
\qquad
\tilde q_i=\tanh(u_i/T)
$$

Z-score 处理中心与尺度漂移；Tanh 压制长尾极值；`stopgrad` 防止模型通过操纵 batch 统计量走捷径。这个校准仅服务于 rank loss，不修改线上服务的 $\hat\mu_m$ 或 $\hat\tau_m$ 语义。$T=2$ 是当前记录中的折中点；$T=1$ 更容易饱和，$T=3$ 更保守。

### 13. 是否尝试过 DRCFR、Beta head、FiLM 或累计 head？

当前以 cumulative head 表达“补贴越大理论上响应不应更差”的单调先验：100 档作为 base logit，逐步加深的补贴档位累加非负增量。DRCFR 理论上可引入更丰富的 DR/表示分解；Beta head 可建模不确定性/分布形态；FiLM 可用 treatment 条件调制表征。对这些替代结构，当前材料不额外主张未经验证的离线收益。

## 三、因果、样本与数据质量

### 14. RCT 为什么还需要 propensity/IPW？

随机化降低了 treatment assignment 与干预前协变量的关联，但不保证各 arm 的有效样本量相同。IPW 在这里用于构造可比较的 transformed outcome；前提是使用正确的有效分流比例，而不是未经核验的理论配置比例。

### 15. 这个因果解释依赖哪些假设？

- 随机化/可忽略性：给定 $x$ 后，treatment 不包含潜在 outcome 的额外信息；
- overlap/positivity：每个可比较的 $x$ 在 treatment 与 control 下都有正概率；
- SUTVA：用户结果不受其他用户 treatment 干扰，且处理定义明确；
- 一致性：实际接受的处理对应观察到的 outcome。

小 propensity 会使 inverse weight 很大。正确顺序是先检查随机化和有效分流比例，再诊断权重分布，必要时 clip/stabilize，最后在统一协议下比较 DR + OOF；不能无诊断地截断并忽略目标变化。

### 16. 为什么 control-no-call 是正向证据？它等于“会被拉动”吗？

不等于。对 $2y-1$ 的 IPW pseudo 而言，control-no-call 表示在没有补贴时未响应，因此在总体意义上是“可能存在可拉动空间”的相对正证据。它不是观察到的个人反事实结果，不能说该用户一定会被补贴拉动。

### 17. 哪些数据问题最危险？

每行粒度必须明确为用户、用户日或订单。重复 PID 会放大高频用户权重，并削弱独立同分布评估。所有特征必须在 intervention 前截断；券状态、后续行为、结果窗口统计和明显编码档位身份的字段都是泄漏候选。尤其要避免以 treatment 后变量筛样本，否则会产生 post-treatment selection bias。

## 四、从排序到业务决策与上线

### 18. 为什么不能给每个用户选择 uplift 最大的档位？

每档独立 uplift 最大不等于全局净收益最大。一个用户可能命中多个档位，必须考虑补贴成本、预算、频控、互斥触达和风险。可定义：

$$
V_m(x)=v_{call}\cdot\hat\tau_m(x)-cost_m-risk_m
$$

再在单用户最多一个档位、总预算和业务风险约束下做全局资源分配。深档 uplift 较高也不代表边际收益覆盖成本。
