# Teads：用分层 Poisson 模型汇总稀疏 CPA 实验，再用业务门槛做发布决策

论文：**Estimating Heterogeneous Treatment Effects in Online Advertising Experiments: A Hierarchical Bayesian Approach**。Aljoša Vodopija、Anže Alič、Tim Poštuvan、Martin Jakomin、Blaž Škrlj，Teads。AdKDD 2026 workshop；模板页写 KDD ’26 不代表主会研究论文。

来源：[官方论文页](https://www.adkdd.org/papers/estimating-heterogeneous-treatment-effects-in-online-advertising-experiments%3A-a-hierarchical-bayesian-approach/2026) · [6 页全文，官方 S3](https://s3.us-west-1.amazonaws.com/papers.adkdd.org/2026/papers/adkdd26-vodopija-estimating.pdf) · [企业代码 ab-tea-lab](https://github.com/outbrain-inc/ab-tea-lab)。本轮已读全文、视觉核对 Table 2/Figure 3，并读代码；检索日 2026-11-07，代码 commit `49f7fc0e5df52869acfe8fa92d631a99a2cd4d3c`。由摘要卡升级为全文卡；代码默认值与论文实验设置存在差异，下文分开说明。

## 本次独立审计记录

复核截止：**2026-11-07（Asia/Shanghai）**。证据状态：**正文可得但关键材料缺失**：6页官方稿和公开代码固定commit已核；稿内无单列附录，完整论文实验配置、私有日志和过滤实现未取得。采用结论：**可开展最小验证**，优先旁路估计器与发布规则的分离验证。

|日期类型|核验结果|
|---|---|
|首次公开|AdKDD 2026公开稿可核；最早上传日/更早预印本未核|
|修订|官方PDF未给公开修订历史；代码比较固定到49f7fc0e5df52869acfe8fa92d631a99a2cd4d3c，不称当前所有版本一致|
|会议|AdKDD 2026-08-10；页眉KDD 8月9–13日为主会时间，不据此改变workshop归属|
|正式出版|独立正式出版日/DOI未核；论文首页五位作者均署名Teads|

【原文事实】下文模型、数表与案例回查PDF Eq.1–8、Table1–2、§5及固定版本源码；本文复用Poisson层级模型、NUTS、IVW、HDI/ROPE，新增价值是针对CPA实验的整合、校准与生产评估，不是发明贝叶斯统计或新的用户级CATE。

训练/推断输入是每小时累计的campaign×arm计数与spend、历史δ尺度及先验；输出θ/τ后验、HDI与发布建议。线上投放不需要逐request跑NUTS；发布层还需要预设成本阈值和执行日志。样本汇总单位是campaign，随机化单位是auction/request，两者不能混写。

## 1. 一句话结论

它把“每个 campaign 先算不稳定的 log CPA 比，再拿估计方差加权”改成“直接对转化计数和 spend 建联合层次模型”，主要改善**高异质性下实验推断的校准**；然后另加 HDI/ROPE 规则，阻止“统计上显著、业务上不够大”的模型发布。两项收益来自两个不同模块，不能混成“新估计器提高了广告收入”。

最适用的场景是大量 campaign、转化很稀疏、campaign 效果差异大、需要按小时监控平台模型实验。它输出总体平均 log conversion-intensity 比与后验分布，不是用于用户 targeting 的 CATE 排序模型。

## 2. 旧 pipeline 与卡点

旧方案沿用广告实验 meta-analysis：

```text
同一个线上 A/B 实验
  → 每个 campaign 的 control/treatment spend 与 conversions
  → campaign log rate-ratio + 估计 SE
  → random-effects inverse-variance weighting（IVW）
  → 总体效应、p-value / CI
  → 发布或回滚
```

问题一：零/少转化下，log rate ratio 需要连续性修正，方差估计也噪声很大。问题二：真实 campaign 异质性 $\tau$ 用点估计代入权重，若低估 $\tau$，总体 SE 偏小、误报上升。问题三：只检验 $\theta>0$ 把“非常小但显著”也视为可发布，不管维护、运行和迁移成本。

本文不是拿分层方法去击败“所有数据直接相加”这一弱 baseline；正文使用 **random-effects IVW + Paule–Mandel**，已显式考虑异质性。但没有比较 GLMM、带 HKSJ 修正的 IVW 等更强方案，因此不能声称击败所有现代 meta-analysis。

## 3. estimand、数据与实验识别

campaign $i$，variant $j\in\{0,1\}$，观察 spend $s_{ij}$、conversions $c_{ij}$。

$$
CPA_{ij}=s_{ij}/c_{ij},\qquad CVI_{ij}=1/CPA_{ij}=c_{ij}/s_{ij}.
$$

$\theta_i=\log(CVI_{i1}/CVI_{i0})$；正值意味着每单位花费获取更多转化。$\theta$ 是 campaign 效果分布的**平均 log rate ratio**，不是 $\log[(\sum c_1/\sum s_1)/(\sum c_0/\sum s_0)]$，也不是总广告收入的相对增量。对单个 campaign，CVI 比为 $e^{\theta_i}$、CPA 比为 $e^{-\theta_i}$；跨 campaign 不可把非线性变换后的平均当平均变换。

生产实验在 auction/request 层随机化，每个 campaign 一半预算给 treatment、一半给 control；排除内部测试 campaign 与累计 spend 小于 1美元 的 campaign。识别来源是这个实验设计，HBM 本身不消除观察数据混杂。花费作为固定 offset 的解释依赖预算/分配协议；若 treatment 本身大幅改变 spend 与竞争，需检验“每元转化效率”是否仍对应业务真正想要的政策效果。

同一 advertiser 下 campaign 相关，本文 inference model 没有 advertiser 层；这会影响独立性与不确定性，不因总 campaign 数大就自动消失。累计 spend 是实验期内变量，低于 1美元 的过滤应确认两臂共同资格定义，不能分别筛选两臂；过滤改变目标 campaign 集合，可能关联 treatment 引发的花费变化。论文没有完整公开过滤实现。HBM likelihood 本身能保留有 spend 但零 conversions 的记录，不应把“低 spend 过滤”误写成“删除零转化 campaign”。

## 4. 模块与公式：两个层次的改动

### 4.1 IVW 参考模块

论文 Eq.1 对每个计数加 0.5：

$$
\widehat\theta_i=\log\frac{(c_{i1}+0.5)/s_{i1}}{(c_{i0}+0.5)/s_{i0}},\quad
SE_i^2=\frac1{c_{i0}+0.5}+\frac1{c_{i1}+0.5}.
$$

随机效应权重 $w_i=1/(SE_i^2+\widehat\tau^2)$，总体为 $\sum_iw_i\widehat\theta_i/\sum_iw_i$；$\widehat\tau$ 用 Paule–Mandel。它保留每个 campaign 的异质性，但把 campaign 点估计和 SE 当输入，不能充分传播 $\tau$ 自身的不确定性。

### 4.2 HBM：直接对原始计数建模

$$
c_{ij}\sim Poisson(\lambda_{ij}),\qquad
\log\lambda_{ij}=\alpha_i+\theta_i z_{ij}+\log s_{ij}.
$$

$$
\alpha_i\sim N(\mu,\sigma^2),\qquad
\theta_i\sim N(\theta,\tau^2).
$$

$\alpha_i$ 是 control baseline log CVI，$\theta_i$ 是该 campaign 的 treatment log ratio；$\sigma$ 控制 baseline 差异，$\tau$ 控制 treatment 效果差异。它们不是同一个异质性参数。

超先验：

$$
\mu\sim N(m_\mu,s_\mu^2),\qquad \sigma\sim HalfNormal(h_\sigma),
\theta\sim N(0,s_\theta^2),\ \tau\sim HalfNormal(h_\tau).
$$

论文取 $m_\mu$ 为历史平均 log CVI，$s_\mu=10\delta$、$s_\theta=5\delta$、$h_\sigma=h_\tau=10\delta$。$\delta$ 是平台校准的业务参考尺度，没有公开其绝对数值；不能把 $+2\delta$ 翻译成“CPA 改善 2%”。

**为什么能稳：**Poisson likelihood 可直接使用零转化；稀疏 campaign 在其个体似然较弱时向总体收缩，高量 campaign 则更由自身数据决定。$\theta$ 与 $\tau$ 联合推断，异质性不确定性进入总体后验，减少“把估计不准的 heterogeneity 当已知”的过度自信。代价是 Normal 效果分布与 pooling 假设可能抹平真实尾部；这不是无条件优于独立估计。

### 4.3 推断实现

论文：PyMC NUTS，4 chains、每链 5000 warm-up 与 3000 posterior samples、target acceptance 0.95。报道 $\mu,\sigma,\theta,\tau$ 收敛诊断通过。约 30,000 campaign 的小时快照在 4 CPU cores 耗时 7–9 分钟；100,000 campaign 需 45–52 分钟。

平台 **5M requests/s 是业务流量背景**，不是 NUTS 吞吐或模型逐请求在线推理。统计模型跑在实验汇总层，频率是小时级。

### 4.4 HDI/ROPE 决策是第二个独立模块

每小时更新 95% HDI，与 $[-\delta,\delta]$ 比较：

- HDI 全在 ROPE 外：检测到超过实际意义门槛的正/负效果。
- HDI 全在 ROPE 内：实际等价。
- HDI 跨 ROPE 边界：继续观察。

实验至少运行 6 小时再开始序贯判定；若 HDI 宽度小于 $w_{max}=\delta$ 但仍跨边界，则按 precision criterion 停止，结论是**已较精确但业务边界未决**，不是已证明等价或收益必然小于门槛。

$\delta$ 由实验前的 week-long A/A 历史确定，为这些 A/A 的 95% HDI 最远端点绝对值的 1.2 倍，1.2 由产品方参与选定。对不同窄分组需重新校准，不能复制全平台门槛。

论文明确该 HDI/ROPE 流程**没有 formal optional-stopping guarantee**。200 个模拟 week-long hourly-monitoring runs 中，strict null 误判 0.0%、practical null $0.9\delta$ 误判 3.7% 是特定模拟的经验校准，不是任意停时的定理。

## 5. 实验设置：已检验与未检验的模型偏离

离线 DGP 基于五天生产数据校准，数值略作扰动：3000 advertisers；每 advertiser 的 campaign 数为 1+Poisson(9)；advertiser CPA 为 mean/std=50/20 的 LogNormal，campaign 内 CPA spread 为 Normal(5)；spend mean/std=160/200，双组相同。treatment log effects 用 $N(\theta^*,(\tau^*)^2)$，$\theta^*\in\{0,1.5\delta,2\delta,3\delta\}$、$\tau^*\in\{1\delta,\ldots,10\delta\}$。

计数用 NegBin2，dispersion $\phi=120$，$Var(c)=\lambda+\lambda^2/\phi$，因此 inference 的 Poisson 有适度错设。DGP 的 baseline 有 advertiser–campaign 层次，但 treatment effects 仍来自和 inference 一样的共同 Normal；这没有充分检验 advertiser-specific treatment effect 或 heavy tails。

正文称每个设置 200 次重复；Table 2 与序贯模拟报告的一些百分比不是 1/200 的整数倍（例如 5.9%、9.1%、3.7%）。卡片按原表转录，不能据此倒推出实际错误次数；复现时需要核对作者的重复/汇总口径。

## 6. 强 baseline 结果与局部反证

Table 2，异质性固定 $\tau^*=5\delta$。RMSE/bias 单位均为 $\delta$，其余为 %。

| 真效应 | 指标 | IVW | HBM |
|---|---|---:|---:|
| 0 | Type I error | 9.10 | 5.90 |
| 0 | Coverage | 93.50 | 95.20 |
| 0 | RMSE | 0.92 | 0.84 |
| 0 | Bias | 0.32 | 0.02 |
| 1.5δ | Power | 67.00 | 66.30 |
| 1.5δ | RMSE | 0.94 | 0.82 |
| 2δ | Power | 78.50 | 80.30 |
| 2δ | RMSE | 0.81 | 0.75 |
| 3δ | Power | 97.70 | 95.50 |
| 3δ | Coverage | 95.70 | 94.20 |
| 3δ | RMSE | 0.79 | 0.84 |

这不是全面碾压：大效应 3δ 时 IVW 的 RMSE 和 power 更好；HBM 核心是较少偏差与更稳健的校准。Figure 2 当 $\tau^*=10\delta$ 时 IVW 的 Type I error 超 35%，HBM 维持名义 5% 附近；IVW 同时“power 上升”不能只按检出率当优点，因为 null 下已大量误报。

论文离线 power 用单次 one-sided $P(\theta>0\mid D)>0.95$ 与 IVW p<0.05 比，**不是**线上 $HDI>\delta$ 的发布门槛。不要把 Table 2 的 80.3% 当业务 threshold 决策的 power。

## 7. 线上三个案例，实际改善了哪个决定

| Case | treatment vs control | 论文结果 | 能支持的业务结论 |
|---|---|---|---|
| I A/A | 同模型流量拆分 | 约 72h HDI 全入 ROPE；约 92h 满足 precision；click intensity 约 24h 等价 | 该运行的 null 校准与流程可用性 |
| II CVR | 新特征与超参优化的新 CVR 模型 vs 生产模型；约 500 advertisers / 7000 campaigns | 平均约 +2δ，约 32h HDI 超过 +δ，支持提前发布；余下时间效果稳定 | 较早确认该 CVR 模型的实际意义；不是 HBM 自身产生 +2δ |
| III retrieval | 新超参的双塔 creative pre-ranking vs 生产版本 | 平均约 +δ，始终跨 ROPE 上边界；约 72h 达 precision criterion，不推荐发布 | 避免在证据未清晰超过业务门槛时发布 |

Case III 里 IVW 单侧检验约 25h 显著，HBM 的 HDI 约 30h 已全大于零。**即使保留同一个 HBM，只把阈值设为 0，也会判赢**。因此这个案例对“避免低价值发布”的证据主要属于 **ROPE 门槛/决策规则**，不能全部归功于分层估计器。

作者用“效果太小、不值得 operational costs”解释不部署，但未公开成本量化、净利润或发布规则之间的随机对照。HDI 跨 δ 表明仍可能在 δ 两侧，不能写成已证明小于 δ；采取不发布是保守的业务选择。

## 8. 消融/稳健性与缺少的强比较

- 超先验尺度敏感性：$s_\mu,s_\theta\in\{5,7.5,10\}\delta$，$h_\sigma,h_\tau\in\{5,10,15\}\delta$；posterior mean 变化 <0.02δ，HDI width 变化 <2%。仅是所测范围，不表示任意先验都无关。
- Poisson 换 NegBin2：在校准的轻度 overdispersion 下均值变化 <0.02δ、区间宽度 <2.5%，快照约 8→12 分钟；支持当前场景保留 Poisson，不能推导严重零膨胀/重尾也安全。
- Case III 的 δ 从原值降至 0.7δ，作者称仍不清晰越过门槛；仍属同一个运行的敏感性。
- **没有** 2×2 的 IVW/HBM × 0/ROPE 决策规则实验；也没有 GLMM、advertiser 层 HBM、heavy-tail treatment-effect、固定错误率下的完整效能对比。

## 9. 代码核对：可以复用什么，不能直接当论文复现什么

[BayesianPoissonRegression](https://github.com/outbrain-inc/ab-tea-lab/blob/49f7fc0e5df52869acfe8fa92d631a99a2cd4d3c/src/ab_tea_lab/model/bayesian_poisson_regression.py) 实现 non-centered 参数化：$\alpha_i=\mu_\alpha+\sigma_\alpha u_i$、$\theta_i=\theta+\tau v_i$，$u_i,v_i\sim N(0,1)$，以及 `exp(alpha + z * theta) * spend` 的 Poisson likelihood。输出总体 θ 的 mean、std、HDI、posterior probability 与 $E[\tau^2]$。

代码与正文有三类差异：

1. [采样父类](https://github.com/outbrain-inc/ab-tea-lab/blob/49f7fc0e5df52869acfe8fa92d631a99a2cd4d3c/src/ab_tea_lab/model/poisson_regression.py) 默认 nutpie、2 chains、500 draws、1000 tune；论文是 4/3000/5000，需显式覆盖。代码超先验默认 scale=10，未自动按平台 δ 校准。
2. [IVW](https://github.com/outbrain-inc/ab-tea-lab/blob/49f7fc0e5df52869acfe8fa92d631a99a2cd4d3c/src/ab_tea_lab/model/inverse_variance.py) 默认只在至少一个 arm 为零时给两边加0.5；论文 Eq.1 写对所有 count 加0.5。代码也可选 HKSJ/t，而论文没有报告相应强 baseline。
3. [RandomSimulator](https://github.com/outbrain-inc/ab-tea-lab/blob/49f7fc0e5df52869acfe8fa92d631a99a2cd4d3c/src/ab_tea_lab/simulator/random.py) 默认 campaign 数采 exponential、CPA gamma/其他可选、默认计数 Poisson；论文 Table 1 用 Poisson campaign 数、LogNormal advertiser CPA、Normal within spread、NegBin2。README 的小例子不是 Table 2 的精确复现实验。

代码证实了模块构造，但目前仓库没有足以直接重跑论文所有表图的完整配置与私有生产数据。也未据本轮静态阅读声称已运行复现实验。

## 10. 逐模块收益审计

### 10.1 计数似然与部分汇聚：减少零/少事件造成的极端读数

【原文事实】Eq.5直接使用conversion count和spend offset；Eq.6给campaign基线与效果分布。Table2在零效应下RMSE从0.92δ降至0.84δ，重算相对降幅8.70%；1.5δ时从0.94δ降至0.82δ，降12.77%；3δ时反而由0.79δ升至0.84δ，增加6.33%。这些是固定DGP中的估计误差，不是广告ROI。

【分析推断】直接建计数分布→减少先算单campaign log-ratio及SE时零计数/连续性修正的影响；共享分布→让一个只有0/1次购买的小campaign不支配全平台结论→总体区间和上线判断更稳。例：极小campaign从0变1并不代表真实效果无限大，pooling会借其他campaign信息收缩它。这个动作仅改变实验读数和发布建议，不直接改变bidder的投放或CVR模型。

【待验证假说】如果增益主要来自稀疏计数处理，应在同一数据、相同过滤下看到低计数组的校准与coverage改善，而不是只在大campaign的平均值改善。替代解释是正态效果先验恰好贴合DGP、先验偏向零或不同连续性修正。将Poisson改为NegBin、加入重尾/双峰及advertiser级共同效果后若收益消失，不能宣称“稀疏广告通用稳健”。小广告主真正负效应被整体正均值抹平也是失败；需记录分组假阴性与尾部损失，而不只看总θ。

### 10.2 联合推断异质性：目标是正确不确定性，不是越窄越好

【原文事实】HBM对θ与τ同时采样；IVW使用Paule–Mandel异质性点估计。Table2 null误报9.1%→5.9%，是**下降3.2个百分点**，相对约35.16%；5.9%仍不是严格等于5%。Figure2显示高τ时差距扩大；GLMM等比较留待未来。

【分析推断】将τ的不确定性传播到θ后验→减少异质性被低估时的过度自信→避免把某个模型差异误判成平台普遍改善→少做错误发布。例如几个大campaign方向相反，单一τ点估计偏小可能使平台CI过窄；HBM有机会更诚实地反映不确定性。替代解释包括基线连续性修正、有限样本正态近似，而不仅是“贝叶斯优越”。

【待验证假说】统一null错误率后比较power和time-to-decision，并加入IVW-HKSJ、GLMM和advertiser层模型。如果经过合理修正的IVW同样校准且更快，优先选简单方案；若广告主聚类使HBM误报仍上升，则应加层级/改设计，不能靠更多MCMC采样解决数据相关。前提是该campaign集合具有可交换性，样本资格没有随两臂结果分别筛选。

### 10.3 ROPE门槛：用业务损失函数改变发布，而不是创造更大效果

【原文事实】§3.2使用HDI与ROPE，§5.4同一新retrieval模型在零门槛下会显著，在ROPE规则下不推荐发布；同一HBM的HDI约30小时已高于0。论文没有公开把δ换算成维护成本/净利润的财务模型。

【分析推断】将“值得上线”的门槛从0改为δ→过滤统计显著但收益不足以覆盖工程成本的改动→减少迁移和运维开销。例：每元转化率只改善极小幅度，却需要维护第二套检索索引，此时零门槛会误导。经营收益来自规则与实际成本匹配，非HBM自动创造。A/A噪声尺度是测量参考，不能天然替代最小经济价值。

【待验证假说】固定同一估计器，回放0/δ两种规则；同时固定δ比较不同估计器，隔离门槛贡献。检查错拒真正有价值改动、错发无价值改动及未决比例。若δ来自噪声大而被设得过高，可能错过许多小而累积重要的改进；若开销与收益不匹配，所谓少发布可能只是少创新。HDI跨δ时必须保留未决，不可把保守不发包装成已证明等价。

### 10.4 小时更新与精度停时：减少等待必须计入迟到结果和误判

【原文事实】§5每小时汇总，至少6小时后开始判定；CVR案例约32小时决策，实验仍继续观察约5天。论文没有formal optional-stopping guarantee；200次模拟的若干百分比与整数计数不完全相容，汇总细节待澄清。

【分析推断】序贯更新→较早确认有用改动→提前放量、释放实验流量，或提前停掉无效改动；实际执行需要发布平台接收建议并完成放量。例：确认CVR模型有效后提前一天上线才有潜在收益；如果审批/排期仍在周末，统计提速并不产生提前经营收益。

【待验证假说】固定误判和代价规则，记录全流程从实验开始到实际放量的时间，而不只记录首次区间越界。加入转化延迟、季节性、效果衰减及反复查看校准；如果提前决定在成熟标签上频繁反转，应停止自动发布。精度停止后仍跨门槛的结果是边界未决，不能为了减少时长强行二分。

## 11. baseline与pipeline关系表

|现有方法或论文（关系身份）|共同问题|本文具体改动|可替换或组合|不能替换|接口与假设对齐|公平比较实验|
|---|---|---|---|---|---|---|
|IVW-Paule–Mandel（原文实比，§2/4）|汇总campaign效果|用原始计数的HBM取代log比率+SE汇总|可替换估计器层，保留同一A/B采集|随机化、共同资格、业务决策阈值|相同平均log CVI目标、spend定义、零计数修正、过滤和停时|相同DGP/数据与错误率；同时报误报、coverage、power、CPU和耗时|
|Poisson/NegBin2（原文稳健性对照，§4.2.3）|计数过度离散|可替换likelihood|保留层级结构与决策规则|advertiser效应依赖、随机化设计|相同offset、层级先验、采样诊断|分轻/重度overdispersion比较coverage与推断时间|
|HDI/ROPE、mSPRT/Bayes factors（原文引用/讨论，非全套实比）|序贯实验决策|采用实用门槛与精度停止|ROPE门槛可与合适估计器组合|不能把其他方法的always-valid保证移植过来|相同最小有用效果、监控频率、停时和错误代价|固定边界/实用null，比较错发/错拒/等待损失|
|GLMM（原文未来比较）；IVW-HKSJ、advertiser层HBM（分析补充，非论文已报告结果）|有限样本与聚类稳健性|修正区间或增加广告主层|可作为更强替代基线|并非当然优于当前方案|同单位、campaign/advertiser依赖、estimand|相同调参资源和固定误报率，检验重尾/多峰/聚类DGP|
|CVR模型、双塔召回、用户uplift（被评估对象/分析补充）|提高投放或互动价值|本文只改变评估及发布层|可用于它们的随机A/B读数|不替换预测器、出价、资源分配或CATE排序|treatment是哪个系统改动、单位预算与结果成熟度|先固定被测策略比较测量规则，再另做策略效果实验|

## 12. 最小验证方案与采用结论

|项目|可执行方案|
|---|---|
|适用症状|低转化campaign很多，IVW总体结论随campaign组合或少数极端值跳变，且需要高频发布判断|
|数据前提|有效随机A/B、campaign×arm原始spend/整数conversion、advertiser ID、共同资格规则与历史A/A；另有原小时as-of累计快照，或事件时间+到达时间可重建；成熟终点不能直接回填早期快照|
|最小改动|旁路拟合一个Poisson HBM；固定上线规则，先只比较读数|
|固定项|实际实验、目标总体、conversion定义/归因窗、同一原始整数计数与零转化保留/资格规则、δ、监控时点和计算预算。IVW连续性修正按预注册版本；HBM用原始count，不加0.5；两种IVW修正另做敏感性|
|对照组|IVW-PM、IVW-HKSJ、条件允许的GLMM；同估计器0/δ规则对照|
|中间诊断|R-hat/ESS/发散、posterior predictive、广告主聚类、尾部负效应、offset/资格敏感性、未决比例|
|最终指标|已知θ且含延迟/聚类的仿真验power/coverage；历史A/A验零效应；成熟RCT回放验后续反转/一致性并计终点估计误差，不当真θ。实际发布阶段再按业务δ/成本函数验错误发布损失、决策至放量时长及业务加权效果|
|失败判据|更强简单基线同样校准且更快；聚类/延迟下误报失控；pooling掩盖关键负效应；改δ才出现全部收益|
|后续步骤|先完成历史A/A与成熟实验回放，再用预注册规则做shadow mode；只有规则稳定且成本模型明确才自动发布|

**采用结论：可开展最小验证。** 输入是常见实验聚合日志，能旁路进行，工程侵入低。适合高异质性、低计数场景；低异质性时IVW可能足够。先验证估计与门槛各自贡献，不以论文案例的CVR增益承诺本项目收入收益。

[本地完整原文](../原文/Teads_分层贝叶斯.pdf) · [返回阅读入口](../00-阅读入口.md) · [独立复核总报告](../09-独立逐篇复核报告.md)
