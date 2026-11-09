# Tatari：先修正控制人群与时间窗，再用 CEM + DML 估计广告增量

论文：**Causal Ad Incrementality without Experiments: Addressable-Audience CEM+DML at Billion-Impression Scale**。Jaeyeong Kim、Alexander J. Rasmussen、Jake P. Reschke、Abdullah M. Spall，均署名 Tatari。AdKDD 2026 workshop；不归为 KDD 主会论文。

来源：[官方论文页](https://www.adkdd.org/papers/causal-ad-incrementality-without-experiments%3A-addressable--audience-cem%2Bdml-at-billion-impression-scale/2026) · [6 页全文，官方 S3 对象](https://s3.us-west-1.amazonaws.com/papers.adkdd.org/2026/papers/adkdd26-kim-causal.pdf) · [官网 HTTP PDF](http://papers.adkdd.org/2026/papers/adkdd26-kim-causal.pdf)。本轮已逐页读全文，并视觉复核 Table 2–4；检索日 2026-11-07。此前“仅摘要”状态解除。官网 HTTPS 超时源于静态托管地址问题，不能据此说全文未公开。

## 本次独立审计记录

复核截止：**2026-11-07（Asia/Shanghai）**。证据状态：**正文可得但关键材料缺失**；6页官方完整稿已核，稿内无单列附录，未取得生产数据、完整过滤实现及路由阈值配置。采用结论：**需先补关键条件**（见§10）。

|日期类型|核验结果|
|---|---|
|首次公开|最早可核为AdKDD 2026公开记录；确切首次上线日/更早预印本未核，不把服务器修改时间当首发|
|修订|官方PDF无公开版本历史，本次使用原文目录中校验固定的6页稿|
|会议|AdKDD workshop 2026-08-10；企业署名由PDF首页核实为Tatari|
|正式出版|未核到独立正式出版日期或DOI；不因KDD模板就称主会正式论文|

【原文事实】下文§2—7的方法与数表均回查官方PDF相应节/表；其中额外识别风险为【分析推断】，经营传导需验证的部分在§8逐条标记。论文贡献主要是控制池与逐对窗口的系统组合，CEM、DML/R-learner、AIPW、IPW、surrogate均是既有统计模块的复用。

训练需要曝光前特征、处理和成熟结果及分折身份；报表部署仍需要目标期间曝光/身份/结果日志。它不是不等结果成熟即可逐请求决策的线上模型。用户/设备匹配后产生逐曝光anchor记录，原文未完整给出unique用户与记录加权的转换实现；实现总增量时应明确$n_T$所指数目，避免把重复曝光记录当独立用户。

## 1. 一句话结论与证据边界

这篇最值得借鉴的是**把“谁能成为控制”和“比较哪段时间”当作测量系统的核心设计**；CEM、R-learner、AIPW 都是标准估计模块。论文支持生产规模可运行、匹配显著改变估计、有限外部测量的一致性；没有证明预算优化后净利润提高，更没有证明“广告效果提高 33.8 倍”。

全文比摘要多出的关键结论：CEM + IPW 在四个 geo 对照中全部落入其区间，运营默认 CEM + R 只有三个；1.4% 是 bootstrap **均值**距实验 ATT 的相对误差，不是每次估计的平均绝对误差；8/8 A/A 中有一个未应用生产样本过滤。以下分别保留这些限定。

## 2. 旧 pipeline 与真正的卡点

### 2.1 Tatari 原有 SBI

原 SBI（simulation-based incrementality）根据曝光附近的 5 分钟流量基线及校准乘数推演自然到访，输出 campaign 总量。Table 3 写默认乘数 2.2。它不能直接提供家庭级异质效应或有原则的置信区间。论文 §1 称 5-minute **post-impression** window，§4.1 的机制解释称 **pre-impression** window，前后有表述不一致；这里不擅自认定其准确实现。

作者假设：既有品牌用户的活动密度高，把这部分流量外推为自然基线，会压低估计增量；统一乘数不能修复不同品牌的延迟再激活差异。Table 3 中差距随既有用户池而变化只是机制线索，没有随机拆分实验直接证明这个因果解释。

### 2.2 通常的观察测量

`目标广告已曝光用户 vs 所有未曝光用户 → 匹配/加权/回归 → 增量`。

问题不只是“模型不够强”：某些未曝光用户从来不进入可投广告池。对它们拟合 propensity 不能制造缺失的共同支持。与此同时，曝光组与控制组使用不同长度或起点的结果窗口，会混入观察机会差异。

RCT、ghost ads、PSA 和 geo test 是另外的识别设计，而不是需要被 R-learner 全部替代的弱 baseline。论文强调它们的成本、速度、平台协作和规模约束；保留随机实验锚点仍有价值。

## 3. 识别对象、样本单位与必要假设

- **处理**：目标 campaign 的曝光；控制来自同期间收到其他广告、但未收到目标广告的人。
- **数据单位**：匹配在 device/user 层形成，随后围绕 treated impression 生成带时间 anchor 的成对记录；同一身份和重用控制会产生相关性。
- **特征**：曝光前目标品牌站点 1/7/28 天 rolling sessions、其他广告主站点活动、第三方人口属性（§2.1）。
- **主要 estimand**：CEM 有共同支持的 treated 子集上的 ATT；总增量按 $\widehat{ATT}\times n_T$ 报告。不能无条件改写成全平台 ATE 或全部目标受众的增量。
- **识别要求**：consistency、给定这些处理前特征的 exchangeability、共同支持。可触达控制与匹配改善设计，但没有保证“购买意图”等未记录变量已全部控制。

额外审视：其他广告可能影响结果；“同期间看过其他广告”如果由观察期内行为决定，需检查选择条件是否包含处理后信息。下一次曝光又可能受 treatment 或用户行为影响，因此按下一次曝光截断窗口也应配合固定窗敏感性。A/A 与跨领域 benchmark 都不能排除真实 treatment 中的未测混杂。

## 4. 四阶段数据流与模块为什么存在

```text
跨广告主曝光日志 + 身份映射 + 处理前活动/人口属性
  → 可触达控制池（同期间收到其他广告且未收到目标广告）
  → CEM 分箱、只保留双组重叠 cell、1:5 匹配
  → 为每个 treated impression 设 anchor/结束点，复制给 matched controls
  → 按目标事件稀疏度选择 R-learner / surrogate DML / IPW
  → matched ATT、总增量、区间；可附用户层 τ(x)
```

### 4.1 CEM 先解决 overlap，再交给 nuisance models

CEM 使用独立零值箱与正值尾部分箱，尾部分位边界 $p_k=1-2^{-k}$。coarsening 从 6 箱降至 4 箱，在未匹配 treated 比例低于 2% 时停止。每个 surviving cell 默认一个 treated 配五个 controls；不足时有放回，记录 duplication ratio。

这样有两层作用：先删除根本没有对照的 cell，再约束处理前活动的可比程度。工程上是 Spark 的 bucket/groupby/join，比全量两两距离更容易扩展。论文对 PSM/nearest-neighbor 的复杂度描述较概括，不能推导所有近邻实现都必须 $O(N^2)$。

### 4.2 对称逐对窗口

正文给出的结束点为该用户的下一次曝光或 study end，两者较早者；treated 的起止点原样复制给匹配控制，rolling features 相对 anchor 计算。设计目的在于同一对观测拥有相同结果观察机会，并避免个体内窗口重叠。

关键证据缺口：Table 2 六条方法都使用这个窗口，所以该表**没有消融窗口本身**。论文将 CEM + naive-window 留到未来。7/28 天报表口径与逐曝光截断的完整工程细节也没有开源实现供核验。

### 4.3 R-learner：共同预测项残差化

3 折 cross-fitting 估计 $e(x)=P(T=1\mid X=x)$ 和 $\mu(x)=E[Y\mid X=x]$，构造 out-of-fold 残差：

$$
\widetilde T_i=T_i-\widehat e(X_i),\qquad
\widetilde Y_i=Y_i-\widehat\mu(X_i).
$$

然后以 Spark Random Forest 拟合：

$$
\widehat\tau=\arg\min_{\tau\in\mathcal F}
\sum_i\widetilde T_i^2\left(\frac{\widetilde Y_i}{\widetilde T_i}-\tau(X_i)\right)^2.
$$

直觉：先去掉“谁本来更容易曝光/到访”的可预测部分，再学习剩余 treatment 变化与 outcome 变化的关系；权重避免弱识别残差比值主导拟合。propensity 只拟合一次并跨 outcomes 复用。

ATE/ATT 的区间由 AIPW influence-function pass 构造，并使用 resolved-ID cluster-robust variance；有放回配对的 A/B bootstrap 按 IP 聚类。论文的 DML 渐近讨论以 nuisance 收敛、识别与其他正则条件为前提，不能扩展成每个用户 $\tau(x)$ 都自动有 $\sqrt n$ 正态保证。

### 4.4 稀疏路由

| 稀疏程度 | 模块 | 为什么有用 | 额外条件/缺口 |
|---|---|---|---|
| dense | 直接 R-learner | 直接估计目标 outcome | 足够事件量和 nuisance 质量 |
| sparse | 用到访 mediator $M$ 拟合 $g(X,T,M)=P(Y=1\mid X,T,M)$，以连续 proxy 跑 DML | 用更密集短期信号降低方差 | surrogacy/comparability；品牌认知绕开 visit 的路径可能不被保留 |
| very sparse | Hájek-normalized IPW，Fisher exact test 与 bootstrap CI | 避免复杂 outcome learner 在极少正例下不稳定 | overlap/propensity 仍要可信，不保证少量数据能精确识别 |

路由按 treated conversion count，阈值每次部署调定并在报告运行中固定；具体阈值、阈值敏感性、surrogacy 诊断未给出。surrogate 模型含 $T$，三路 sample splitting 也列为未来工作；不应把它当成已完整验证的通用“长短期增量转换器”。

## 5. 最有解释力的实验：同窗口下的 2×3 方法矩阵

Table 2 比较 `Naive / CEM` × `difference-in-means / R-learner / IPW`，单位是增量 conversions。下表保留点估计；geo 行带其 95% CI。

| 方法 | Pet Food | Fashion 全购买 | Fashion 新客 | Vitamins |
|---|---:|---:|---:|---:|
| 独立 geo SCM | −66 [−240,123] | 987 [572,1413] | 479 [308,603] | 61 [9,116] |
| A Naive + DiM | 419 | 2909 | 1279 | 99 |
| B CEM + DiM | 246 | 1043 | 409 | 77 |
| C Naive + R | −85 | 781 | 28 | 69 |
| D CEM + R（生产默认） | −88 | 853 | 285 | 26 |
| E Naive + IPW | −52 | 912 | 14 | 74 |
| F CEM + IPW | −7 | 931 | 342 | 37 |

**从控制变量角度解读：**

1. A→B 固定 DiM，主要看匹配。Fashion 全购买 2909→1043、新客 1279→409，证明在这些数据上控制可比性是很大的误差来源；这不是单纯 R-learner 赢弱回归。
2. B→D 固定 CEM，看 residualization。Pet Food 246→−88 更接近 near-null；但 Fashion 新客 409→285，反而落到 geo 下界 308 以下。不能声称“每一跳都更准”。
3. D vs F：生产 R 的 3/4 agreement 不强于 IPW 的 4/4。Fashion 新客由非残差化的 B、F 恢复进区间，作者把 miss 定位到 residualization。选择 R 也有 runtime 和 CATE 输出的考虑。
4. geo 使用 advertiser-selected DMAs、elastic-net synthetic control，属于独立准实验估计器，作者也不把它当 ground truth；全 DMA 用户与 matched addressable 用户并非同一 estimand。Pet Food 区间含 0，Vitamins 区间宽，3/4 agreement 的辨别力有限。

观察侧区间也不完全同口径：A/B 是 90% IP-cluster bootstrap（500 次），C/D 是 95% AIPW IF，E/F 是 95% IPW IF。不要直接据宽窄宣称覆盖率优劣。

## 6. SBI、A/A 与公开 benchmark：数字分别回答什么

### 6.1 SBI 分歧不是业务 lift

Table 3 的 28 天 DML/SBI 分别为 Fintech A 25.8×、Fintech B 1.9×、Health 3.6×、Furniture 1.2×、Wellness 1.1×、B2B SaaS 33.8×、Mobile App 2.7×、Retail 6.0×。例如 B2B SaaS 是 **同一数据的增量到访估计从 SBI 6.5K 变成 DML 220K**，不是用户到访增长到 33.8 倍，也不是已知真值下 SBI 误差改善 33.8 倍。

Wellness 与 Mobile App 对部分 ID-resolution cells 做了 post-hoc filter，因为其 7 天 treated lift 出现不合理负值。这个过滤由结果异常触发，可能改变样本总体及选择偏差，应用前必须预定义和独立验证。

### 6.2 A/A 能证伪管线错误，不能证明无混杂

从 20% control holdout 中分 pseudo-treatment/control，八个 AIPW 95% CI 都包含 0。Table 3 只列相对 lift 点估计，没有逐行 CI。Mobile App 小样本套过滤后 100% dropout，因此其 A/A **未过滤**，与生产处理不完全一致。论文对“全流程 8/8”的概括须连带此脚注。

### 6.3 LaLonde 对新构造的支持主要来自 CEM

NSW 实验参考 ATT 为 1,794美元；185 个 treated，外部 PSID-1/CPS-1 controls 分别 2490/15992；100 次 bootstrap。匹配单独就把 DiM 的平均绝对误差降约 84%/81%。

| PSID-1 的方法 | bootstrap ATT 均值 | 每次误差的平均绝对值 |
|---|---:|---:|
| R raw | 939 | 1028 |
| R + CEM-cut | 1819 | 922 |
| R + CEM-weighted | 1645 | 848 |
| DR + CEM-cut | 1726 | 810 |
| EconML NonParamDML raw | 2156 | 825 |
| EconML NonParamDML + CEM-cut | 1359 | 1078 |

所谓 **1.4% = |1819−1794|/1794**，不是 MAE 1.4%；R+CEM-cut 的 MAE 仍为 922美元。DR+CEM-cut 的均值误差约 3.8%，而 MAE 更低。作者称 R/T/X/DR 在 post-CEM 的绝对误差统计上不可区分，R 因 runtime 作为默认。

CEM-cut 保留 PSID/CPS 约 78%/85% treated，改变了目标总体。论文另做 CEM-weighted 并称 full-pool，但“smoothed inverse-frequency weighting”不能不加额外外推假设就恢复完全没有共同支持的单元。与外文 SOTA 的 15.7% 对比要区分 target population、均值误差与重复样本误差；不能据一个点估计差距推出广告生产因果有效性已被证明。

## 7. 工程收益、性能代价和适用范围

Table 1 的 Nie–Wager Setup B、固定 10×i3.4xlarge 集群、5 次均值：

| 每组 n | EconML NonParamDML | EconML DRLearner | PySpark R |
|---|---:|---:|---:|
| 10⁵ | 91 s | 92 s | 59 s |
| 10⁶ | 996 s | 1013 s | 127 s |
| 10⁷ | timeout | timeout | 1098 s |

这里比较单节点 EconML 参考与分布式 Spark；约 8×是系统配置下 wall-clock 收益，不是同硬件同资源的算法复杂度结论。重用 propensity 在多 outcome 下据报节约约 40% runtime；每 outcome 用 driver ThreadPoolExecutor 并行。典型分析采样每组 5M impressions，标题“billion”指日志规模背景，不能把它写成每次模型全量训练十亿行。

适合拥有跨广告主曝光的 CTV/DSP/平台；单个广告主通常拿不到构建此控制池的输入。新身份图特征、其他可触达池定义都只是未来扩展，未在本文 benchmark。

## 8. 逐模块收益审计：从测量改动到经营决策

以下链路中的业务传导均为【分析推断】；只有明确标为【原文事实】并给出表/节的部分才是论文已报告的证据。本文没有随机比较“采用新测量器作预算决策”与“采用旧测量器”的经营收益。

### 8.1 可触达控制池与CEM：先改变可比较的人，再谈模型

【原文事实】§2.1从其他广告主曝光人群取控制，按处理前活动和人口属性CEM；无重叠cell删除，估计对象为matched-subset ATT。Table2 A→B在同一窗口下将Fashion all-purchase的DiM从2909降到1043，geo参考点为987，但该比较同时改变匹配后人群，不能当相同estimand下已知真值的偏差消融。

【分析推断】可触达池→减少“根本无机会看到广告的人”与被曝光者的差别；CEM→限制可观测活动分布差异→自然高活跃不再全部计入广告增量→经营者可能减少对自然回访特别高的campaign加预算。例如品牌老客每天访问，不看广告也会到站；若控制来自低活跃网民，广告会被高估。反过来，匹配也可能删掉真实高效但缺对照的人，不能预设估计一定下降且下降一定正确。

【待验证假说】若收益主要来自选择偏差减少，在固定可识别目标子集上，与随机holdout的误差应下降，并伴随处理前SMD、propensity重叠和有效样本量改善。替代解释是换了目标人群或更强过滤，而不是同一效果估计变准。若平衡改善但同群RCT误差不降，或结果只靠删掉难例变好，应否定“已修好识别”的解释。只有已有跨广告主曝光、稳定身份和处理前特征时才适用；其他广告影响目标购买、资格含处理后行为或遗漏购买意图都可能使链路失败。

### 8.2 对称逐对窗口：修观察机会，不自动修动态选择

【原文事实】§1/§2.1将treated anchor到下一曝光或研究结束的窗口复制给控制；Table2所有方法用同一窗口，论文明确没有window消融。

【分析推断】相同观察长度→避免多观察几天自然多记转化→减少被时间机会驱动的ATT/排序差异→预算不再偏向人为长窗campaign。例：曝光组有7天机会，控制只有当天，模型会把后6天自然购买错算广告作用。将窗口配齐有可能修复这部分差，但下一次曝光若受广告响应影响，截断本身又成为处理后选择。

【待验证假说】固定样本和估计器比较预设固定窗与下一曝光截断窗；记录两臂观察时长、截断hazard、转化延迟及RCT误差。如果“改善”随窗口变化而反号、只在由处理影响的截断方案下出现，不能归因于更准确测量。决策执行要冻结报表口径，不能每个campaign挑最有利窗口；跨窗口数值不能直接混入同一预算排行。

### 8.3 残差化与稀疏路由：减少拟合误差的影响，不能制造识别

【原文事实】§2.2用3折样本外nuisance残差训练R-learner；§2.3根据treated转化计数路由到direct、surrogate或IPW。Table2 CEM+R只有3/4 geo点估计入参考CI，CEM+IPW是4/4；没有证明复杂模型总优于简单加权。代理阈值和正式surrogacy诊断留待未来。

【分析推断】正交化→弱化可预测自然活跃与曝光倾向拟合误差对效应读数的一阶影响→在同一匹配样本上调整条件增量→可能纠正投放判断。例：匹配箱内仍有活跃差异，残差模型可进一步调整。稀疏proxy则把“只有几个购买”转换为更密集的购买概率信号→可能降低报表波动。例：购买极少但到站较多时，站内访问可提供信息；品牌认知直接促成线下购买则可能绕过代理。

【待验证假说】固定控制池、窗口、特征、训练样本及调参资源，对比DiM/IPW/R/DR；看同一estimand的偏差、CI覆盖、分群校准，而不是只看预测AUC或估计增量大小。代理只在dense目标上先做降采样，再与direct和随机真值比较；若事件数下降时proxy稳定但偏差持续增大，否定“方差收益足以抵消代理错设”。R失效可来自重叠差、nuisance误设、cross-fit未按身份隔离；GAN/深网络规模在本文并非已验证增益来源。使用surrogate还依赖代理充分性、可比较性和无标签泄漏，当前没有完整证据。

### 8.4 分布式工程：把测量变得可运行，不把速度当准确性

【原文事实】Table1在$10^6$每组时Spark为127秒，EconML NonParamDML为996秒，重算约$996/127=7.84$倍；$10^7$每组Spark1098秒，单机参考超时。§2.4报告共享propensity多结果场景节约约40%时间，没有独立全量配置供复跑。

【分析推断】重用不随outcome变化的propensity、并行回归→同一更新周期内完成更多campaign/outcome→降低决策等待成本。例：原来测量要跨过每日预算更新点，提速后可赶上本轮调度。替代解释包括10节点与单节点资源差别、不同模型实现，不能把7.84倍视为算法在等算力下的速度定理。

【待验证假说】统一资源或报告CPU时/成本与wall-clock两套指标，同时比较数值一致性、更新延迟和故障率；若计算更快但数据仍要等7/28天成熟，实际决策提前可能为零。部署应输出版本、资格集合与数据成熟度，避免提速后使用未成熟标签导致假收益。

### 8.5 经营收益还缺一座桥：历史ATT不等于新增预算的边际回报

【原文事实】本文输出匹配人群的ATT、总增量与区间，没有识别新增一元预算的边际效果曲线，也没有报告测量器驱动预算的随机净利润提升。

【分析推断】即使过去campaign平均增量估准，预算翻倍后的新受众、竞价价格和饱和也可能不同。因此“估计更准→预算更好”至少需要一套明确的预算规则、成本口径和局部响应验证。例如A历史平均ROI高但已饱和，B历史平均低而边际ROI高；按ATT机械加预算仍可能选错。

【待验证假说】先以小幅预算扰动验证边际响应，再随机比较旧/新测量指导的规则，报告实际支出、覆盖、增量贡献毛利与延迟收益。若只改读数不改动作，没有经营收益；若动作变了但收益仅来自更多花费，不能归因于测量质量。负lift后的身份过滤应预注册且与结果隔离，不能先删“不可信负值”再声称效果变好。

## 9. baseline与pipeline关系表

|现有方法或论文（关系身份）|共同解决的问题|本文改变的模块|可替换或组合|不能替换|需要对齐的接口与假设|公平比较实验|
|---|---|---|---|---|---|---|
|Naive/CEM × DiM/R/IPW（原文实比，Table2）|观察广告增量|控制构造、匹配与估计器|匹配层与估计后端可分别替换|随机化和未测混杂识别|同一目标人群、特征、窗口、总量分母、CI口径|固定目标子集做2×3；统一cluster与置信度，额外报告被删人群|
|S/T/X/DR、EconML（原文实比，Table4/1）|CATE/ATT或可扩展实现|CEM前处理、Spark R-learner实现|可换nuisance/效应回归器或计算后端|广告场景因果有效性不能由NSW迁移保证|相同样本、预算、重复抽样、ATT目标与硬件|同目标MAE/coverage及CPU时，别只比bootstrap均值偏差|
|Tatari SBI（原文实比，Table3）|campaign上层到访增量|以匹配观察估计取代5分钟基线模拟|可旁路输出第二测量口径|不能据估计倍数判实际广告增长|统一7/28天、被过滤人群、曝光量与目标事件|同人群随机holdout锚定；不要以新估计器自身当真值|
|Near Impressions、ghost ads、surrogate index（原文引用/讨论，非本文完整实比）|可比对照或代理测量|本文采用跨广告主池、逐对窗及稀疏路由|有auction日志时可比较控制构造；surrogate仅替稀疏outcome层|随机实验保证、surrogacy识别条件|上游资格、拍卖事件可用性、代理路径和目标总体|相同estimand下分别评估，不能拿别文数字横比|
|[ETDC+HCA](ETDC_HCA.md)、预算LP（分析补充）|增量测量进入日常决策|Tatari是观察测量上游，ETDC是实验锚定校准|可作为诊断或辅助特征接入校准；价值经验证后进入预算器|ETDC实验锚、预算边际响应与全局约束|matched ATT与渠道总量、人群覆盖、货币/时间窗、边际而非平均价值|固定预算规则先比测量误差，再单独随机比预算规则|

## 10. 最小验证方案与采用结论

|项目|可执行方案|
|---|---|
|适用症状|同一campaign观察增量随控制池或窗口大幅变化，且传统自然基线疑似混入老客活动|
|数据前提|跨广告主可触达曝光、稳定身份、处理前活动、成熟目标标签；最好保留同人群随机holdout。只有广告主自己的已曝光日志不足|
|最小改动|先在一个campaign替换控制池+CEM；固定窗、固定IPW/DiM后端，暂不加surrogate和复杂DML|
|固定项|目标eligible集合、窗口、实际曝光和成本口径、身份规则、训练/调参资源；单列共同支持外人群|
|对照组|原控制池+同估计器、CEM+IPW、CEM+R；随机holdout作为独立锚，不把geo点估计当真值|
|中间诊断|SMD、overlap、ESS、重复控制、drop率、身份聚类、截断分布、目标人群覆盖、估计与RCT偏差/CI覆盖|
|最终指标|首阶段同目标增量误差与coverage；后续预算试验看实际支出下的增量利润、覆盖和长期护栏|
|失败判据|改善仅来自删人/负lift过滤；同群RCT误差不降；窗口反号；A/A经生产过滤后大量drop；额外复杂度不胜IPW|
|后续步骤|先补齐一致资格和测量锚，再加R/surrogate并逐层消融；只有小幅预算响应与规则A/B过关才进入自动预算闭环|

**采用结论：需先补关键条件。** 有跨广告主池、身份与实验锚的团队可以低成本开始样本构造试验；没有这些输入时，只照抄R-learner无法复现本文设计。全文已取得，但生产过滤、路由阈值、关键消融和预算机制仍缺，不适合作为“无需实验的确定因果ROI引擎”。

[本地完整原文](../原文/Tatari_CEM_DML.pdf) · [返回阅读入口](../00-阅读入口.md) · [独立复核总报告](../09-独立逐篇复核报告.md)
