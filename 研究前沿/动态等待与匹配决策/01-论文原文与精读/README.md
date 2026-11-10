---
type: "索引"
topics: ["动态等待与匹配决策","论文阅读"]
status: "维护中"
created: "2026-11-04"
---

# 动态等待与匹配决策 论文原文与精读

[[研究前沿/动态等待与匹配决策/README|方向入口]] · [[研究前沿/_模板/论文精读|论文模板]]

先明确当前能否拒绝、能等到何时、已承诺的分配能否更改。三组论文分别讨论承诺时点、受限容量与策略失效条件。

## 完整目录

<!-- 自动索引开始 -->
### 何时等待、何时承诺

- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/ALIGN-HOLD/精读|从匹配经验中学习实时等待决策 · ALIGN-HOLD]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/TimelyThrifty/精读|允许延后承诺时怎样在截止前合批 · TimelyThrifty]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/DispatchDeadlineFF/精读|任务有发运截止时怎样在线装箱 · DispatchDeadlineFF]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/NoncrossingDelays/精读|用历史分区势函数处理不同等待代价 · NoncrossingDelays]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/VRM/精读|用等待损失与匹配成本决定何时触发匹配 · VRM]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/NonlinearStoppingDual/精读|用对偶方法分析非线性最优停止 · NonlinearStoppingDual]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/StructuredStoppingQ/精读|有限时域与跳跃风险下的最优停止 · StructuredStoppingQ]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/AdaptiveMatchingQueries/精读|查询次数与强制批处理如何约束随机匹配 · AdaptiveMatchingQueries]]

### 容量有限时优先匹配谁

- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/GenMatch/精读|用候选竞争与剩余状态生成整批派单方案 · GenMatch]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/LongestQueue/精读|存在退出时优先处理哪条等待队列 · LongestQueue]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/StaticPriority/精读|有退出风险时静态匹配优先级的理论保证 · StaticPriority]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/FreeDisposalOCS/精读|允许替换时改进在线边权匹配 · FreeDisposalOCS]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/PerturbedGreedy/精读|收益随机时怎样做在线匹配 · PerturbedGreedy]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/RankOneMatroid/精读|通过可逆交换在线分配受限容量 · RankOneMatroid]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/SampleContention/精读|用独立样本调节候选争抢同一容量的概率 · SampleContention]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/SparseStochasticMatching/精读|查询受限时怎样挑出值得评估的候选边 · SparseStochasticMatching]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/DecentralizedMatching/精读|去中心化动态市场中的稳定匹配 · DecentralizedMatching]]

### 策略遇到新市场或不完整反馈会怎样

- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/BilateralCDF/精读|买卖双方价值未知时如何学习利润最大化报价 · BilateralCDF]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/BilateralPrices/精读|双边交易中学习发布价格的遗憾界 · BilateralPrices]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/TraceSqrtTrade/精读|从交易反馈中学习双边报价 · TraceSqrtTrade]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/DFQI/精读|把相邻市场样本用于动作价值更新 · DFQI]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/DisclosureAgents/精读|检验司机了解调度规则后的策略稳健性 · DisclosureAgents]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/DoseAllocation/精读|在线试验中用强化学习逐步分配剂量 · DoseAllocation]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/OptimisticSOO/精读|半带反馈下的随机在线优化 · OptimisticSOO]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/TopKQueue/精读|用队列轨迹的平均成本搜索控制策略 · TopKQueue]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/UnknownIIDMatching/精读|到达分布未知时利用历史请求完成在线匹配 · UnknownIIDMatching]]

<!-- 自动索引结束 -->

## 其他方向与已有精读

- [[研究前沿/面向决策的履约建模/01-论文原文与精读/RCIF/精读|按样本对决策边界的影响重新加权训练数据 · RCIF]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/PtOGtO/精读|比较预测后优化与生成情景后优化 · PtOGtO]]。条件场景到优化器的接口与计算权衡。
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/FC-DFL/精读|用离散调度成本训练可再生能源预测器 · FC-DFL]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/RAN-SCM/精读|从调度日志中的混杂走向结构反事实 · RAN-SCM]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/OpenNWM/精读|利用潜在动作预训练导航世界模型 · OpenNWM]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/PolicySampleRisk/精读|分解训练样本与未来结果给策略带来的风险 · PolicySampleRisk]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/LatentForesight/精读|用动作条件下的潜在未来为候选前缀排序 · LatentForesight]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/DoubleDiagonal/精读|用两侧分流缓解市场实验中的库存干扰 · DoubleDiagonal]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/DD-LS/精读|考虑分配方案对需求的影响并用容量上界加速求解 · DD-LS]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/DFLNOL/精读|学习连续选边后按决策成本训练预测器 · DFLNOL]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/ActionCenteredCBwK/精读|在预算约束下估计各档促销相对不干预的增量 · ActionCenteredCBwK]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/NetworkDesignRisk/精读|不同分流方案如何改变网络曝光与估计风险 · NetworkDesignRisk]]

## 旧论文版本更新

- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/DisclosureAgents/版本更新-2026-11-09|检验司机了解调度规则后的策略稳健性 · DisclosureAgents v3]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/DecentralizedMatching/版本更新-2026-11-09|去中心化动态市场中的稳定匹配 · DecentralizedMatching v2]]

[[研究前沿/_运行记录/待处理队列|待取得原文或待核实的候选]] · [[研究前沿/_运行记录/README|查看历史批次与收录口径]]
