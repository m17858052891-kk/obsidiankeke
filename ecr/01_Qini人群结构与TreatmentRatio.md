# Qini 人群结构稳定如何评判与计算（Treatment Ratio）

## 30 秒回答

Qini 前段的人群结构是否稳定，不能只看 Qini/AUCC 高不高，还要看排序后的 treatment/control 构成是否偏离实验原始分流比例。对第 $k$ 个 score 分桶或累计 Top-$\alpha$ 人群，计算：

$$
r_k=\frac{n_{t,k}}{n_{t,k}+n_{c,k}}
$$

其中 $n_{t,k}$、$n_{c,k}$ 是该人群中 treatment 与 control 样本数。若试验分流概率为 $p_t$，并且排序没有学到 treatment 身份，$r_k$ 应围绕 $p_t$ 随机波动；若在头部持续显著偏低或偏高，说明模型可能把 treatment assignment 或曝光结构当成 uplift 信号。它是诊断护栏，不是单独判死刑的指标。

## 1. 为什么要看人群结构

Qini/AUCC 用观察到的 treatment 与 control 结果估计增量。它隐含一个前提：排序后的每个局部人群里，treatment 和 control 仍具有可比较性。若 Top 人群几乎全来自某一组，曲线的增益既可能来自真实异质性，也可能来自样本构成偏移、重复曝光或可预测的分组痕迹。

因此本项目的模型选择是“两条腿”：Call MTAUCC 是主目标；Qini curve、treatment-ratio curve、ATE error、按档位指标和多切分稳定性是护栏。

## 2. 计算口径

对每个非 control 档位 $m$，只取该 treatment 与 100 档 control 的评估样本。按预测 uplift $\hat\tau_m(x)$ 从高到低排序。

### 分桶 ratio

将排序样本切为等量的 $B$ 个 bucket：

$$
r_b=\frac{\sum_{i\in b}\mathbb{1}(W_i=m)}{\sum_{i\in b}1}
$$

它回答“第 $b$ 段人群的 treatment 占比是否异常”。实践中用 10、20 或 100 个分桶；样本少的深档位应减少桶数。

### 累计 ratio

对 Top-$q$ 累计人群：

$$
r(q)=\frac{\sum_{i\in Top(q)}\mathbb{1}(W_i=m)}{|Top(q)|}
$$

它更贴近业务：若线上只触达前 5%/10%，前段是否仍可比。

### 与基线比较

基线不是固定的 0.5，而是有效评估样本的原始实验比例：

$$
p_m=\frac{N_m}{N_m+N_{100}}
$$

如果数据经过过滤、去重或按日期切分，应使用**同一评估切片的实际有效比例**，不能照搬配置中的理论分流概率。

## 3. 怎样判断“稳定”

稳定不等于每个点等于 $p_m$。推荐同时看：

| 检查 | 稳定的表现 | 风险信号 |
| --- | --- | --- |
| Top 5%/10%/20% 累计 ratio | 围绕 $p_m$ 小幅波动 | 连续显著偏离，且样本量足够 |
| 分桶 ratio 曲线 | 无持续趋势，变化可由抽样解释 | 头部单调下凸/上凸、跨 seed 重现 |
| 置信区间 | 覆盖或接近 $p_m$ | 多个相邻桶不覆盖 $p_m$ |
| 分 treatment 复查 | 多档位一致且合理 | 只在深档/高频人群异常 |
| 多切分复查 | 时间/城市/seed 后方向稳定 | 仅一个随机切分有效 |

可用二项近似的标准误：

$$
SE(r_b)\approx\sqrt{\frac{p_m(1-p_m)}{n_b}}
$$

作图时加上 $p_m\pm1.96SE$ 参考带；样本极少时改用 bootstrap 区间。切勿对小 bucket 的锯齿过度解读。

## 4. Qini 图里前段下凸是什么意思

图的具体颜色和实现可能不同，核心看排序头部的 $r(q)$。若 treatment-ratio 在前段明显低于基线（常被描述为红线下凸），说明高分人群中 control 占比异常高；反之则是 treatment 占比异常高。两者都提示“分组身份与 score 有关联”，不是只有某一个方向才有问题。

在本项目的强 Corr 单阶段实验中，AUCC 可显著上升，但 ratio 风险也变大。这符合机制：全局相关性损失会积极利用所有能解释伪标签变化的模式，其中可能包含 treatment-side 高频曝光、深档样本结构或特征泄漏。

## 5. ratio 不平能否直接说明模型无效？

不能。它是重要的因果诊断而非因果证明。真实的 treatment effect 异质性、有限样本、分流后过滤、比例估计错误都可能带来偏离。正确动作是：

1. 核验分流概率、去重、过滤和评估代码；
2. 看 Top 区间的样本量与置信区间；
3. 分档位、按时间/城市/用户频次切片；
4. 同时看 AUCC/Qini、ATE error、校准和多 seed；
5. 若异常跨切分稳定存在，把它作为模型选择的强护栏。

## 6. 本项目的落地结论

单阶段强 PU-Corr/Corr 证明排序监督有效，却可能把 assignment artifact 放大；只训练 head 的保守方案 ratio 较稳但 AUCC 空间有限。H2 Soft T2 用 TwoStage anchor、按档位校准和低学习率软解冻，在候选中实现较平的 ratio 与较高的 Call MTAUCC，故作为当前推荐点。
