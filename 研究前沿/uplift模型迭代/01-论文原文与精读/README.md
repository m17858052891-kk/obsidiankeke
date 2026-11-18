---
type: "索引"
topics: ["uplift模型迭代","论文阅读"]
status: "维护中"
created: "2026-11-04"
---

# uplift模型迭代 论文原文与精读

[[研究前沿/uplift模型迭代/README|方向入口]] · [[研究前沿/_模板/论文精读|论文模板]]

先问对照是谁、处理有几档，再选择估计方法。若目标是固定预算下的选档，请直接看第三组。

## 完整目录

<!-- 自动索引开始 -->
### 干预带来多少增量

- [[研究前沿/uplift模型迭代/01-论文原文与精读/CMTP/精读|估计连续处理的局部调整对不同人群的影响 · CMTP]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/PPDF/精读|融合观察数据与试验数据估计处理效应 · PPDF]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/SIRNET/精读|借助代理结果调整预训练表征以估计处理效应 · SIRNET]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/MultiLTMLE/精读|序贯多档干预的双重稳健估计 · MultiLTMLE]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/MultiOutcomeAggregation/精读|多个结局指标如何合成一个干预效应 · MultiOutcomeAggregation]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/UniMVT/精读|多档发券中联合学习去偏点击率与增量 · UniMVT]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/MoELearner/精读|Data-informed Adaptation of Foundation Models for Causal Effect Estimation]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/SCOUTOutcome/精读|Causal Outcome Learning with Noisy Proxies · SCOUTOutcome]]

- [[研究前沿/uplift模型迭代/01-论文原文与精读/arXiv-2611.18411/精读|样本人群的增幅能用来排全站收益吗？]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/arXiv-2611.18945/精读|一项活动对后续参与的增量，能否拆成直接影响与多个中介路径？]]

### 估计在什么条件下可信

- [[研究前沿/uplift模型迭代/01-论文原文与精读/DoubleDiagonal/精读|用两侧分流缓解市场实验中的库存干扰 · DoubleDiagonal]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/NEDNet/精读|存在网络干扰时分解直接与间接效应 · NEDNet]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/NetworkDesignRisk/精读|不同分流方案如何改变网络曝光与估计风险 · NetworkDesignRisk]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/ValidatableUplift/精读|在独立样本上验证人群增量及差异 · ValidatableUplift]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/ValidatedDigitalTwins/精读|用实验检验数字孪生对政策效应的估计 · ValidatedDigitalTwins]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/AdaptiveFalsification/精读|自适应分流何时掩盖响应模型错误 · AdaptiveFalsification]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/PFNNuisance/精读|Does Predictive Performance Translate to Causal Performance? Evaluating tabular foundation models as nuisance learners for causal effect estimation]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/PolicyExposure/精读|邻居也受干预时该估哪一种增量 · PolicyExposure]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/JointHTECalibration/精读|Non-normal Limits and Joint Calibration of Cross-fitted Heterogeneity Tests]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/PlatformRandomizationSide/精读|One-Sided Randomization in Two-Sided Platform Experiments: Which Side Should be Randomized?]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/CoarsenedCovariates/精读|Lost in the Bins: Treatment Effects with Discretized Covariates]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/PriceResponseAudit/精读|历史销量预测变准，价格变化的响应可能更差（关联方向）]]

- [[研究前沿/uplift模型迭代/01-论文原文与精读/arXiv-2611.18128/精读|重尾结果下，改回归损失与截断增广残差有什么区别？]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/arXiv-2611.18458/精读|模型对某个动作有预测时，怎样判断该不该把它交给决策器？]]

### 怎样分配预算并评估策略

- [[多档干预下，怎样判断对一个人再加一档是否值得|在预算约束下估计各档促销相对不干预的增量 · ActionCenteredCBwK]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/OnsagerOPE/精读|同样本奖励模型的早停与策略价值校正 · OnsagerOPE]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/UpliftBench/精读|检查增量评价指标与实际策略目标是否一致 · UpliftBench]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/PolicyRisk/精读|策略改变样本分布后怎样限制下一轮超风险概率 · PolicyRisk]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/MultiLoggerIPS/精读|多套日志策略该如何合并才有较小估值方差 · MultiLoggerIPS]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/LoggerAcquisition/精读|有限预算下应从哪套历史政策追加一条观测 · LoggerAcquisition]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/StrategicEligibility/精读|Strategic Causal Policy Learning with Manipulable Eligibility]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/BellmanPBV/精读|没有线上真值时，怎样挑选估计策略价值的模型？]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/ChosenActionScore/精读|只知道选中项成败，失败样本该怎样进入损失（关联方向）]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/GateAndScale/精读|概率重新校准后，下游只看排名还是使用分值大小，会不会改变收益？（关联方向）]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/PolicyYouden/精读|两种分数交给同一套动作规则，为什么按样本对算的指标仍能把优劣排反？（关联方向）]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/arXiv-2611.18444/精读|同组成员会相互影响时，怎样找到达到目标的最低干预比例？]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/arXiv-2608.05434/精读|多档连续决策能否兼顾结果分位数与风险约束？]]

### 按通用方法恢复的储备与补充

- [[研究前沿/uplift模型迭代/01-论文原文与精读/CFEditTest/精读|反事实生成应同时检查动作是否生效和个体是否保真]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/CaseOnlySCCS/精读|Causal Inference from Self-controlled Case Series]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/CausalDef/精读|Constraints on Causal Inference as Experiment Comparison: A Framework for Identification, Transportability, and Policy Learning]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/CausalUCB/精读|Online Causal Configuration for Networked Systems via Doubly Robust Steady-State Learning]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/ClusterAdjustedSMD/精读|Bayesian Cluster-Adjusted Standardised Mean Differences: A Simulation Study]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/ClusterPaths/精读|把群内干预的自身中介与同伴中介分开]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/CompleteCaseTransport/精读|When Listwise Deletion Works: Causal Diagrams and Complete-Case Regression]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/ComposableCausality/精读|Composable Causality: A Toolkit for Systematic Time-Series Causal Discovery and Treatment-Effect Benchmarking]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/DistributionFirstITR/精读|Distribution-First Framework for Learning Risk-Sensitive Individualized Treatment Rules]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/EffectBlockTest/精读|控制其他变量后特征组还能解释多少增量异质性]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/ExcursionTD/精读|显式控制目标策略连续执行多少步]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/ExternalValidityBounds/精读|A Sensitivity Framework for Assessing External Validity]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/FADO/精读|FADO: Learning Causal Explanations with Prior-Fitted Networks]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/FedTrialATE/精读|不同试验的分流比例不同，怎样合并出目标人群的平均增量？]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/GraphBanditPrune/精读|部分因果图能排除哪些不值得探索的动作]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/GraphSCM/精读|没有上线前记录的地区，可以借相邻地区估计增量吗？]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/HELPIV/精读|Hedging out the HEDGE Bias: Identifying Dynamic Partial-Equilibrium Effects with Panel LP-IV]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/HeterogeneousIV/精读|Heterogeneous treatment effect estimation with instrumental variable methods]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/HiFIVE/精读|Causal Learning with Invalid Instruments for High-dimensional Imaging Responses]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/IMMD-Flow/精读|Sampling Interventional Distributions with Orthogonal MMD Flow]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/InverseConfoundingApplications/精读|Inverse Confounding Analysis: Part 2. Applications to Real- World Observational Data]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/JointPOBounds/精读|Identification and Bounding of Joint Expectation over Potential Outcomes]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/KernelCF/精读|When Covariance Is Not Enough: Kernel-Based Regularization for Single-Cell Counterfactuals]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/LEOSIL/精读|多个历史策略的质量不同，怎样避免把坏动作也当成专家样本？]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/LongitudinalMoE/精读|Unifying Data-Adaptive Longitudinal Treatment-Effect Subgroup Discovery and Pretreatment Membership Prediction]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/MarketDoPFN/精读|Market Impact Estimation via Causal Foundation Models]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/MediPFN/精读|MediPFN: Amortized In-Context Nuisance Learning and Inference for Causal Mediation Analysis]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/MultiClusterIV/精读|Instrumental variables with treatment clusters]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/PanelFA/精读|Semiparametric Inference in Panel Data with Interactive and High-dimensional Confounding]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/PostRelaxationProjection/精读|Inference After Model Refutation: Uniform Post-Relaxation Inference for Partially Identified Models]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/PosteriorAttributionBounds/精读|Sharp bounds for posterior causal attribution given complete factual records]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/PotentialEffectsInterval/精读|Estimating Treatment Effects with a Single Arm Clinical Trial and Data Summaries from an External Control Group: is it Possible?]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/PretrendSpillover/精读|Doubly robust estimation of direct and spillover effects using multiple pre-treatment periods]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/ProjectedIV/精读|Estimating Average Treatment Effects with Projected Instrumental Variables]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/ProximalDiD/精读|Proximal Difference-in-Differences for Causal Learning under Confounding and Outcome Drift]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/RMPW/精读|Ratio-of-mediator-probability weighting for causal mediation analysis: estimation, extensions, and practical guidance]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/RiskPOMDPBounds/精读|Accelerated Online Risk-Averse Policy Evaluation in POMDPs with Theoretical Guarantees and Novel CVaR Bounds]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/SelectiveTrees/精读|Selective inference for pruned interaction trees with known unequal variances in randomized trials]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/SmallTrialAdjustment/精读|Improving Efficiency and Power in Small Rare-Disease Trials Through Prespecified, Data-Adaptive Covariate Adjustment]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/SpatialConfoundingBounds/精读|Identifiability and partial identification under spatial confounding in additive risk models]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/SubgroupMaxT/精读|重叠人群的最大统计量校正]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/ThreeEngagementChecks/精读|A General Statistical Framework for Attention and Manipulation Checks]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/VAER/精读|Causal Machine Learning for Multilevel Studies with Unmeasured Cluster-Level Covariates via Variational Autoencoders]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/WeakIVCrossfit/精读|Weak-Instrument Inference and Model Diagnostics in Double Machine Learning for Linear Instrumental Variable Models]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/arXiv-2603.13662/精读|不在每个 bootstrap 样本重训核模型，会损失多少区间覆盖？]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/arXiv-2611.17875/精读|历史对照在哪一步加入，才能改善新实验的分配效率？]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/arXiv-2611.18116/精读|分期干预估计的所有权重都为正，置信区间就可靠吗？]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/arXiv-2611.18291/精读|双向反馈会同时破坏两个方向的工具变量分析吗？]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/arXiv-2611.19204/精读|连续干预时长只观察到下界，还能估计剂量响应吗？]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/arXiv-2611.19209/精读|只有少数单元受处理时，怎样给单个时点的反事实加区间？]]

<!-- 自动索引结束 -->

## 其他方向与已有精读

- [[论文精读/TaQFormer/TaQFormer：多维优惠券建模与OBS-RCT融合|结合观察数据与随机试验估计多维发券效果 · TaQFormer]] — arXiv:2610.26199v1；已有完整精读和原文附件。
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/ActTime/精读|在时间序列中比较候选动作的后果 · ActTime]]。动作排序与干预评价设计。
- [检验世界模型是否真正使用了动作信息 · StandIn（原文）](https://arxiv.org/abs/2611.01666)。动作作用检验与随机化假设。
- [从调度日志中的混杂走向结构反事实 · RAN-SCM（原文）](https://arxiv.org/abs/2611.00635)
- [纵向结局有界时检验敏感性假设 · BoundedSensitivity（原文）](https://arxiv.org/abs/2611.02642)
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/PolicySampleRisk/精读|分解训练样本与未来结果给策略带来的风险 · PolicySampleRisk]]
- [在线试验中用强化学习逐步分配剂量 · DoseAllocation（原文）](https://arxiv.org/abs/2611.00395)
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/IVBench/精读|用留出干预与同构盲模型检验模拟器 · IVBench]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/DFQI/精读|把相邻市场样本用于动作价值更新 · DFQI]]
- [用目标策略引导下一状态预测并离线评估价值 · ADWM-OPE（原文）](https://arxiv.org/abs/2606.05558v4)

[[研究前沿/_运行记录/待处理队列|待取得原文或待核实的候选]] · [[研究前沿/_运行记录/README|查看历史批次与收录口径]]
