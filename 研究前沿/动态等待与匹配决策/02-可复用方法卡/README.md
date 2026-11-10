---
type: "索引"
topics: ["动态等待与匹配决策","方法"]
status: "维护中"
created: "2026-11-04"
---

# 动态等待与匹配决策 可复用方法卡

[[研究前沿/动态等待与匹配决策/README|方向入口]] · [[研究前沿/_模板/方法卡|方法卡模板]]

比较两种规则前，先对齐它们何时看到候选、何时必须承诺。相同的候选评分接到不同的触发或容量规则上，得到的派单方案也会改变。

## 完整目录

<!-- 自动索引开始 -->
### 何时等待、何时承诺

- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/ALIGN-HOLD-filter|冻结奖励模型与切片密度带过滤]] · ALIGN-HOLD
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/ALIGN-HOLD-hardpairs|避开极端噪声的动态困难偏好采样]] · ALIGN-HOLD
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/ALIGN-HOLD-preferences|多视角轨迹偏好与平衡抽样]] · ALIGN-HOLD
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/TimelyThrifty-trigger-edf-skip|截止期触发并跳过放不下件的整批贪心]] · TimelyThrifty
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/DispatchDeadlineFF-commit-first-fit|到达绑定、最早期限发运的 First-Fit 基线]] · DispatchDeadlineFF
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/NoncrossingDelays-partition-trigger|历史分区势函数驱动异质等待触发]] · NoncrossingDelays
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/VRM-ready-netcost|最小增广净成本对应的匹配就绪阈值]] · VRM
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/NonlinearStoppingDual-local-certificate|从当前时点构造停止价值的非线性上界]] · NonlinearStoppingDual
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/StructuredStoppingQ-generator-q|带停止罚项的生成算子 q 函数]] · StructuredStoppingQ
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/AdaptiveMatchingQueries-interior-first|稀缺端点延后询问与批内中止]] · AdaptiveMatchingQueries
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/AdaptiveMatchingQueries-round-cap|乐观图逐轮匹配的端点查询上界]] · AdaptiveMatchingQueries

### 容量有限时优先匹配谁

- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/GenMatch-bipartite-context|先竞争后匹配的稀疏二部图编码]] · GenMatch
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/GenMatch-business-utility|阶段履约监督与可学习业务logit]] · GenMatch
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/GenMatch-state-pointer|集合状态与硬mask的可行匹配指针]] · GenMatch
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/LongestQueue-dual-critical-queue|流体对偶筛边与最长关键队列匹配]] · LongestQueue
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/StaticPriority-availability-certificate|相关可用库存的概率下界与策略证书]] · StaticPriority
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/StaticPriority-value-priority|按剩余匹配盈余排序的静态优先级]] · StaticPriority
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/FreeDisposalOCS-state-ocs|按权重阈值记账的多候选相关选择]] · FreeDisposalOCS
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/PerturbedGreedy-persistent-seed|资源固定种子的扰动贪心]] · PerturbedGreedy
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/RankOneMatroid-preserve-members|用已处理成员不变性维护在线贪心基]] · RankOneMatroid
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/RankOneMatroid-sample-real-swap|用历史与实际价值交换保护先前接纳者]] · RankOneMatroid
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/RankOneMatroid-survivor-law|先构造保留集合的分布，再设计在线接纳概率]] · RankOneMatroid
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/SampleContention-last-slot|只对随机到达的最后名额做单样本调节]] · SampleContention
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/SampleContention-sentinel|用两份激活样本抽选开始接纳的阈值元素]] · SampleContention
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/SparseStochasticMatching-sample-union|随机可行图匹配并集作为有限查询候选]] · SparseStochasticMatching
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/DecentralizedMatching-self-calibration|本地输出间隔驱动的异步匹配复核]] · DecentralizedMatching

### 策略遇到新市场或不完整反馈会怎样

- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/BilateralCDF-relative-cdf|保留探测报价的分阶段 CDF 差分估计]] · BilateralCDF
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/BilateralPrices-mhr-convex|单调风险率下用成交等待轮数估计凸损失]] · BilateralPrices
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/BilateralPrices-profit-information|按成交位更新参照价权重的利润与信息权衡]] · BilateralPrices
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/TraceSqrtTrade-trace-potential|用双侧后验标准差降幅权衡成交与信息]] · TraceSqrtTrade
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/DFQI-目标与源市场的 Bellman 联合回归|目标与源市场的 Bellman 联合回归]] · DFQI
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/DisclosureAgents-disclosure-stress-test|规则披露 × 自利参与者的调度策略压力测试]] · DisclosureAgents
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/DoseAllocation-variable-action-query|状态 query 汇聚变长有序动作，并分离分配与终局选择]] · DoseAllocation
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/OptimisticSOO-optimistic-bellman|区间分布置信集上的乐观Bellman更新]] · OptimisticSOO
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/TopKQueue-guardian-search|保留多条最优后代路径的Top-K细化]] · TopKQueue
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/TopKQueue-persistent-saa|持续运行队列的总成本率与分块采样]] · TopKQueue
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/UnknownIIDMatching-empirical-transport|在线经验运输生成参考分布虚拟请求]] · UnknownIIDMatching

<!-- 自动索引结束 -->

## 其他方向与已有精读

- [[研究前沿/面向决策的履约建模/02-可复用方法卡/FC-DFL-solver-feedback|用投影高斯平滑把离散求解器成本传回预测器]]
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/RAN-SCM-abduction-allocation|结构机制与个体残差共同驱动预算分配]]
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/OpenNWM-latent-action-grounding|无动作轨迹预训练与少量物理动作联合约束]]
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/PolicySampleRisk-combined-cvar|联合训练随机性与未来结果的 CVaR 风险分解]]
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/LatentForesight-action-consistency|真实与预测转移共享逆动作头的表示约束]]
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/LatentForesight-joint-prefix-scoring|目标进展与联合时序先验重排动作前缀]]
- [[研究前沿/uplift模型迭代/02-可复用方法卡/DoubleDiagonal-inventory-correction|利用四格预约率的库存干扰对照估计]]

[[研究前沿/_运行记录/README|历史批次与核验记录]]
