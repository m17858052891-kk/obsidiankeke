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
- [[研究前沿/uplift模型迭代/01-论文原文与精读/IMMD-Flow/精读|用正交流模型采样干预后的结果分布 · IMMD-Flow]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/UniMVT/精读|多档发券中联合学习去偏点击率与增量 · UniMVT]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/LongitudinalMoE/精读|用处理前信息预测纵向效应亚群 · LongitudinalMoE]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/CaseOnlySCCS/精读|利用同一病例的不同时段估计干预效应 · CaseOnlySCCS]]

### 估计在什么条件下可信

- [[研究前沿/uplift模型迭代/01-论文原文与精读/HeterogeneousIV/精读|用工具变量估计异质干预效应 · HeterogeneousIV]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/ClusterAdjustedSMD/精读|用簇调整的标准化差异诊断协变量平衡 · ClusterAdjustedSMD]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/ComposableCausality/精读|构造时间序列因果发现与效应估计的可控基准 · ComposableCausality]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/DoubleDiagonal/精读|用两侧分流缓解市场实验中的库存干扰 · DoubleDiagonal]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/JointPOBounds/精读|不同潜在结果无法同时观测时如何界定联合期望 · JointPOBounds]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/NEDNet/精读|存在网络干扰时分解直接与间接效应 · NEDNet]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/NetworkDesignRisk/精读|不同分流方案如何改变网络曝光与估计风险 · NetworkDesignRisk]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/PotentialEffectsInterval/精读|只有外部对照汇总数据时怎样界定处理效应 · PotentialEffectsInterval]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/ProjectedIV/精读|用投影工具变量估计平均处理效应 · ProjectedIV]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/SelectiveTrees/精读|剪枝选出交互亚群后如何做统计推断 · SelectiveTrees]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/SubgroupMaxT/精读|多个重叠亚群同时检验时如何校正 · SubgroupMaxT]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/ValidatableUplift/精读|在独立样本上验证人群增量及差异 · ValidatableUplift]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/ValidatedDigitalTwins/精读|用实验检验数字孪生对政策效应的估计 · ValidatedDigitalTwins]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/AdaptiveFalsification/精读|自适应分流何时掩盖响应模型错误 · AdaptiveFalsification]]

### 怎样分配预算并评估策略

- [[研究前沿/uplift模型迭代/01-论文原文与精读/ActionCenteredCBwK/精读|在预算约束下估计各档促销相对不干预的增量 · ActionCenteredCBwK]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/OnsagerOPE/精读|同样本奖励模型的早停与策略价值校正 · OnsagerOPE]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/LCM-Promo/精读|从语言模型输出构造促销响应并分配优惠 · LCM-Promo]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/UpliftBench/精读|检查增量评价指标与实际策略目标是否一致 · UpliftBench]]

<!-- 自动索引结束 -->

## 其他方向与已有精读

- [[论文精读/TaQFormer/TaQFormer：多维优惠券建模与OBS-RCT融合|结合观察数据与随机试验估计多维发券效果 · TaQFormer]] — arXiv:2610.26199v1；已有完整精读和原文附件。
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/ActTime/精读|在时间序列中比较候选动作的后果 · ActTime]]。动作排序与干预评价设计。
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/StandIn/精读|检验世界模型是否真正使用了动作信息 · StandIn]]。动作作用检验与随机化假设。
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/RAN-SCM/精读|从调度日志中的混杂走向结构反事实 · RAN-SCM]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/BoundedSensitivity/精读|纵向结局有界时检验敏感性假设 · BoundedSensitivity]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/PolicySampleRisk/精读|分解训练样本与未来结果给策略带来的风险 · PolicySampleRisk]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/DoseAllocation/精读|在线试验中用强化学习逐步分配剂量 · DoseAllocation]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/IVBench/精读|用留出干预与同构盲模型检验模拟器 · IVBench]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/DFQI/精读|把相邻市场样本用于动作价值更新 · DFQI]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/ADWM-OPE/精读|用目标策略引导下一状态预测并离线评估价值 · ADWM-OPE]]

[[研究前沿/_运行记录/待处理队列|待取得原文或待核实的候选]] · [[研究前沿/_运行记录/README|查看历史批次与收录口径]]
