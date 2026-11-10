---
type: "索引"
topics: ["面向决策的履约建模","方法"]
status: "维护中"
created: "2026-11-04"
---

# 面向决策的履约建模 可复用方法卡

[[研究前沿/面向决策的履约建模/README|方向入口]] · [[研究前沿/_模板/方法卡|方法卡模板]]

识别要改的环节：动作条件的转移模型、等待时间与竞争结局的估计，或使用预测结果作决策的优化器。逐卡可查原领域的验证条件。

## 完整目录

<!-- 自动索引开始 -->
### 动作如何改变后续状态

- [[研究前沿/面向决策的履约建模/02-可复用方法卡/ActTime-boundary-prior|冻结动态核心后的零门控历史先验适配]] · ActTime
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/ActTime-controlled-state|按变量维护、动作驱动并由观测校正的状态]] · ActTime
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/ActTime-evaluation-ladder|事实误差、干预误差与动作排序分层评价]] · ActTime
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/SensorWM-effort-ranking|把候选变化按个体历史波动折算为执行代价]] · SensorWM
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/SensorWM-velocity-conditioned-transition|用动作调制近期位移的二阶潜状态转移]] · SensorWM
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/StandIn-design-randomization|保留完整随机化状态的动作作用检验]] · StandIn
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/StandIn-pooling-tempering|沿动作对比检查共享误差并缩放检验分数]] · StandIn
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/OpenNWM-latent-action-grounding|无动作轨迹预训练与少量物理动作联合约束]] · OpenNWM
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/PrimeSim-aligned-action-conditioning|转移动作对齐 attention 与直接 adapter 双路径]] · PrimeSim
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/PrimeSim-self-rollout-memory|自生成历史上的整段训练与固定容量多尺度记忆]] · PrimeSim
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/MKD2World-focus-margin|变化实体加权与仅在变化样本使用的旧状态负例]] · MKD2World
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/MKD2World-state-evidence|按动作意图提取候选后继状态的变化证据]] · MKD2World
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/IVBench-blind-skill|同构动作盲参照与组差技能值]] · IVBench
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/IVBench-perturbation-audit|动作代理泄漏、交换与替代检查]] · IVBench
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/BacktrackingOT-用独立噪声约束审计反事实情景|用独立噪声约束审计反事实情景]] · BacktrackingOT
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/RAN-SCM-abduction-allocation|结构机制与个体残差共同驱动预算分配]] · RAN-SCM
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/ForesightNav-dual-consequence|动作条件的邻域动态与约束双评分]] · ForesightNav
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/ForesightNav-group-distillation|混合候选组的后果偏好蒸馏]] · ForesightNav
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/GraspCF-clearance-representation|在聚合前显式保留约束余量]] · GraspCF
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/GraspCF-verified-pairs|保持候选动作的可行性翻转对与空对照]] · GraspCF
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/INTERACT-mode-future-alignment|按候选模式对齐未来实体状态]] · INTERACT
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/INTERACT-slot-transition|递归实体槽与潜动作条件的未来转移]] · INTERACT
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/LatentForesight-action-consistency|真实与预测转移共享逆动作头的表示约束]] · LatentForesight
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/LatentForesight-joint-prefix-scoring|目标进展与联合时序先验重排动作前缀]] · LatentForesight
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/LaMA-DT-用多目标一致性筛选合成轨迹|用多目标一致性筛选合成轨迹]] · LaMA-DT

### 怎样估计等待、完成与竞争风险

- [[研究前沿/面向决策的履约建模/02-可复用方法卡/BoundedSensitivity-bounded-imputation|阈值潜高斯上的有界结果敏感性补全]] · BoundedSensitivity
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/CompetingEstimands-竞争结局下风险比的压力测试|竞争结局下风险比的压力测试]] · CompetingEstimands
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/删失加权的竞争事件累积概率损失|删失加权的竞争事件累积概率损失]] · CompetingRiskLoss
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/竞争风险损失与主干的等预算交叉对照|竞争风险损失与主干的等预算交叉对照]] · CompetingRiskLoss
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/EGP-Hazard-删失暴露量与尾部风险的两阶段拟合|删失暴露量与尾部风险的两阶段拟合]] · EGP-Hazard
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/PoissonSL-hazard-stacking|Poisson 折外风险率堆叠与一致竞争风险概率]] · PoissonSL
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/SmoothConcordance-按分数差估计时长排序的可信度|按分数差估计时长排序的可信度]] · SmoothConcordance

### 预测怎样影响决策与策略评估

- [[研究前沿/面向决策的履约建模/02-可复用方法卡/RCIF-score|将训练样本影响传播到决策边界]] · RCIF
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/RCIF-weights|按决策影响加权重拟合及非线性退化检查]] · RCIF
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/DFLNOL-edge-decoding|连续选边与可行离散执行的分开检验]] · DFLNOL
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/DFLNOL-frozen-layer|冻结神经优化层，以真实参数计决策损失]] · DFLNOL
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/ADWM-OPE-用目标策略引导下一状态的扩散式离线评估|用目标策略引导下一状态的扩散式离线评估]] · ADWM-OPE
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/DD-LS-跨分配的期望收益上界|跨分配的期望收益上界]] · DD-LS
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/FC-DFL-solver-feedback|用投影高斯平滑把离散求解器成本传回预测器]] · FC-DFL
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/PolicySampleRisk-combined-cvar|联合训练随机性与未来结果的 CVaR 风险分解]] · PolicySampleRisk
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/PtOGtO-convexity-audit|检查预测权重是否破坏下游优化结构]] · PtOGtO
- [[研究前沿/面向决策的履约建模/02-可复用方法卡/PtOGtO-scenario-interface|条件场景生成到等权随机优化]] · PtOGtO

<!-- 自动索引结束 -->

## 其他方向与已有精读

- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/SparseStochasticMatching-sample-union|随机可行图匹配并集作为有限查询候选]]
- [[研究前沿/uplift模型迭代/02-可复用方法卡/IMMD-Flow-orthogonal-target|先估计双稳健核目标，再优化干预结果分布]]
- [[研究前沿/uplift模型迭代/02-可复用方法卡/IMMD-Flow-nystrom-reuse|固定核目标的Nyström计算复用]]

[[研究前沿/_运行记录/README|历史批次与核验记录]]
