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
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/VRM-ready-netcost|最小增广净成本对应的匹配就绪阈值]] · VRM
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/AdaptiveMatchingQueries-interior-first|稀缺端点延后询问与批内中止]] · AdaptiveMatchingQueries
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/AdaptiveMatchingQueries-round-cap|乐观图逐轮匹配的端点查询上界]] · AdaptiveMatchingQueries
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/AbandonBatch-first-passage|有退出风险时如何从队长确定一次清空阈值]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/AbandonBatch-renewal|按单位时间和后续周期重新选择合批阈值]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/RejectionExposure-按请求聚合重复拒绝并检验零膨胀|按请求聚合重复拒绝并检验零膨胀]]


### 容量有限时优先匹配谁

- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/LongestQueue-dual-critical-queue|流体对偶筛边与最长关键队列匹配]] · LongestQueue
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/StaticPriority-availability-certificate|相关可用库存的概率下界与策略证书]] · StaticPriority
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/StaticPriority-value-priority|按剩余匹配盈余排序的静态优先级]] · StaticPriority
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/PerturbedGreedy-persistent-seed|资源固定种子的扰动贪心]] · PerturbedGreedy
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/DestinationSet-用当时可选的对象作条件选择的分母|用当时可选的对象作条件选择的分母]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/OverlappingChoiceSets-允许重叠替代组并按交界状态求展示集合|允许重叠替代组并按交界状态求展示集合]]

- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/带参与约束的优先级策略混合|带参与约束的优先级策略混合]]

### 策略遇到新市场或不完整反馈会怎样

- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/DFQI-目标与源市场的 Bellman 联合回归|目标与源市场的 Bellman 联合回归]] · DFQI
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/DisclosureAgents-disclosure-stress-test|规则披露 × 自利参与者的调度策略压力测试]] · DisclosureAgents
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/TopKQueue-guardian-search|保留多条最优后代路径的Top-K细化]] · TopKQueue
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/TopKQueue-persistent-saa|持续运行队列的总成本率与分块采样]] · TopKQueue
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/CapacityDelayOCO-proxy|给未回传结果分配随机追踪期限]]

### 按通用方法恢复的储备与补充

- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/AdditiveNetwork-centroid|移动服务按需求重心安排往返]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/AdditiveNetwork-facility|先按需求密度分配服务点，再决定多久开一次]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/AdditiveNetwork-roots|把可选服务根固定成连通区域]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/BilateralCDF-relative-cdf|保留探测报价的分阶段 CDF 差分估计]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/BilateralPrices-mhr-convex|单调风险率下用成交等待轮数估计凸损失]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/BilateralPrices-profit-information|按成交位更新参照价权重的利润与信息权衡]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/ChainAdvancing-bands|按到达档和已揭示链深分配执行槽]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/ConditionalResponseCompatibility-检验条件响应能否组成联合分布|检验条件响应能否组成联合分布]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/CutoffSecretary-boundary|什么时候放弃预测前 k 名名单]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/DIOS-tail-gradient|用完整轨迹训练下尾收益的停止策略]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/DecentralizedMatching-self-calibration|本地输出间隔驱动的异步匹配复核]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/DepthPortfolio-pool|不同候选来源值得在何时多取一次]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/DispatchDeadlineFF-commit-first-fit|到达绑定、最早期限发运的 First-Fit 基线]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/DoseAllocation-variable-action-query|状态 query 汇聚变长有序动作，并分离分配与终局选择]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/DownwardProphet-order|用先验尺度决定优先观察哪些高价值机会]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/FeasiblePairCCP-先检可行性，再固定下游分配器比较配对规则|先检可行性，再固定下游分配器比较配对规则]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/ForeSpark-joint-budget|按接受概率与实测批延迟联选两个阶段的预算]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/ForestMatching-load-round|在森林边流上按端点空闲概率修正接纳率]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/FreeDisposalOCS-state-ocs|按权重阈值记账的多候选相关选择]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/IntelligentDelivery-resource-value|用分档增量收益和延迟代价选择请求的资源量]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/ListUpdateWindows-delay|用当前位置给同类累计等待定服务阈值]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/ListUpdateWindows-head|到期前先清掉当前表首的请求]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/MatroidCutoff-cutoff|按剩余集合可替代性设接纳分位阈值]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/MatroidCutoff-reference|不同分布的资源如何用参考价格和虚拟基接纳]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/MaxSATWarmStart-比较组合优化热启动与等预算多种子|比较组合优化热启动与等预算多种子]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/MaximumDelayBatch-gaps|逐单连接收费时用到达间隔定服务点]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/MaximumDelayBatch-union|一批只计最久等待时如何决定是否合批]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/NoncrossingDelays-partition-trigger|历史分区势函数驱动异质等待触发]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/NonlinearStoppingDual-local-certificate|从当前时点构造停止价值的非线性上界]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/OptimisticSOO-optimistic-bellman|区间分布置信集上的乐观Bellman更新]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/PoissonBanditOracle-用离线成本敏感优化器实现有探索保证的动作选择|用离线成本敏感优化器实现有探索保证的动作选择]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/PoissonClocks-first-age|保持逐轮分配概率的跨轮相关指数时钟]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/PrescribedBatch-clock|共享资源的多个队列怎样对齐服务时间]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/PrescribedBatch-count|单资源批量如何随到达率和固定成本改变]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/RandomEdgeReserve-exact-bound|在固定小图上计算随机顺序在线策略的精确上界]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/RandomEdgeReserve-phases|用影子匹配决定早期保留、晚期恢复的端点]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/RankDelay-以组内最老等待触发批量服务|以组内最老等待触发批量服务]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/RankOneMatroid-preserve-members|用已处理成员不变性维护在线贪心基]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/RankOneMatroid-sample-real-swap|用历史与实际价值交换保护先前接纳者]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/RankOneMatroid-survivor-law|先构造保留集合的分布，再设计在线接纳概率]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/ResponseEquilibrium-冻结对手行为和重新求解行为各做一次评估|冻结对手行为和重新求解行为各做一次评估]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/RootGatedRacing-从根节点观测决定是否分配并行副本|从根节点观测决定是否分配并行副本]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/SampleContention-last-slot|只对随机到达的最后名额做单样本调节]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/SampleContention-sentinel|用两份激活样本抽选开始接纳的阈值元素]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/ShiftedTransport-phase|固定资源点的树搜索如何选择尺度相位并保持真实指派]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/SparsePredictDemote-sparse|按已获服务时长抽查，再把长任务降级]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/SparseStochasticMatching-sample-union|随机可行图匹配并集作为有限查询候选]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/SpotFleetMPC-switch|一过性高峰应调价还是搬动容量]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/SpotFleetMPC-window|用截止前最便宜的容量计算可推迟工作的成本]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/StoppingQueueGame-obstacles|用双边终止支付约束继续价值]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/StructuredStoppingQ-generator-q|带停止罚项的生成算子 q 函数]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/SubmodBandit-counts|靠组规模和重复次数从整组反馈更新元素概率]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/SubmodSecretary-price|按过去能否达标的时长调整当前候选的接纳率]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/SubsampledStopping-在线与离线共同面对同一条抽稀候选流|在线与离线共同面对同一条抽稀候选流]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/TraceSqrtTrade-trace-potential|用双侧后验标准差降幅权衡成交与信息]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/UnknownIIDMatching-empirical-transport|在线经验运输生成参考分布虚拟请求]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/带最短驻留时间的专家策略切换|带最短驻留时间的专家策略切换]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/强单调约束的博弈预测控制模仿|强单调约束的博弈预测控制模仿]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/按报告时延和队列误差联合修正分配|按报告时延和队列误差联合修正分配]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/按替代选择模型估算容量边际价值|按替代选择模型估算容量边际价值]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/按相同机会和履约条件评估跨期承诺|按相同机会和履约条件评估跨期承诺]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/重排缓冲与无嫉妒匹配|重排缓冲与无嫉妒匹配]]

<!-- 自动索引结束 -->

## 其他方向与已有精读

- [用投影高斯平滑把离散求解器成本传回预测器（原文）](https://arxiv.org/abs/2610.41238)
- [结构机制与个体残差共同驱动预算分配（原文）](https://arxiv.org/abs/2611.00635)
- [无动作轨迹预训练与少量物理动作联合约束（原文）](https://arxiv.org/abs/2611.01844)
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/PolicySampleRisk-combined-cvar|联合训练随机性与未来结果的 CVaR 风险分解]]
- [真实与预测转移共享逆动作头的表示约束（原文）](https://arxiv.org/abs/2611.04839)
- [目标进展与联合时序先验重排动作前缀（原文）](https://arxiv.org/abs/2611.04839)
- [[研究前沿/uplift模型迭代/02-可复用方法卡/DoubleDiagonal-inventory-correction|利用四格预约率的库存干扰对照估计]]

[[研究前沿/_运行记录/README|历史批次与核验记录]]
