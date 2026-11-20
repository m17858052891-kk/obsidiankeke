# 司乘行为序列建模 · 论文原文与精读

[[研究前沿/司乘行为序列建模/README|司乘行为序列建模]]

<!-- 自动索引开始 -->
### 怎样编码与查询司乘历史

### 方法、对照与适用边界

- [[研究前沿/司乘行为序列建模/01-论文原文与精读/TRIP/精读|TRIP｜历史的顺序、距当前多久与分组交互，应分别怎么验证？]]
- [[研究前沿/司乘行为序列建模/01-论文原文与精读/LWR/精读|LWR｜增加历史长度和增加推理层数，哪个更值得花算力？]]
- [[研究前沿/司乘行为序列建模/01-论文原文与精读/DP-Rec/精读|DP-Rec｜按兴趣变化切历史，比等长分块更好吗？]]
- [[研究前沿/司乘行为序列建模/01-论文原文与精读/T-RoPE/精读|T-RoPE｜序号以外，时间间隔与日历周期是否真的有增益？]]
- [[研究前沿/司乘行为序列建模/01-论文原文与精读/ChronicleRec/精读|ChronicleRec｜可缓存的历史摘要怎样避免所有 token 都只看最近？]]
- [[研究前沿/司乘行为序列建模/01-论文原文与精读/ECHO/精读|ECHO｜长历史能否先选原始事件，再按候选细查？]]
- [[研究前沿/司乘行为序列建模/01-论文原文与精读/DRIFT-GLASS/精读|DRIFT-GLASS｜历史检索前如何按兴趣漂移形成子序列？]]
- [[研究前沿/司乘行为序列建模/01-论文原文与精读/MuSeR/精读|MuSeR｜多兴趣长期表示怎样离线压缩并在线复用？]]
- [[研究前沿/司乘行为序列建模/01-论文原文与精读/CADET/精读|CADET｜序列训练如何保证只看到当时在线可用的事件？]]
- [[研究前沿/司乘行为序列建模/01-论文原文与精读/IntentGR/精读|IntentGR｜复用相似意图历史时，无覆盖样本还能获益吗？]]
- [[研究前沿/司乘行为序列建模/01-论文原文与精读/X-split-Argus/精读|X-split-Argus｜长历史能否预计算、短历史仍保留实时响应？]]
- [[研究前沿/司乘行为序列建模/01-论文原文与精读/TRESS/精读|TRESS｜不规则事件历史能否压成固定带宽的表示？]]
- [[研究前沿/司乘行为序列建模/01-论文原文与精读/ReflectRec/精读|ReflectRec｜从历史生成的画像能否保住原始偏好线索？]]
- [[研究前沿/司乘行为序列建模/01-论文原文与精读/TemporalRank/精读|TemporalRank｜序列越长，有效表示真的保留了较早输入吗？]]
<!-- 自动索引结束 -->

## 复用库内精读

- [[论文精读/HyFormer/HyFormer：CTR中的序列建模与特征交互|HyFormer｜当前订单该怎样查询司机和乘客的历史？]]

### 11 月 16 日周报补读

- [[TriGen_2611_16395|TriGen｜最近一次已回传的行为，要比长期历史占多大权重？]]
- [[RecMem_2611_17921|RecMem｜把较早的行为压成固定记忆，会丢掉哪些信息？]]
- 观察 · [[模型迭代研究知识库/50_持续学习/KuaiRecV2_动态候选池与逐日回测|KuaiRecV2｜逐日更新模型会忘掉哪些旧样本？]]

[[研究前沿/_运行记录/2026-11-17-三方向检索与精读#往期周报补读|原文对照与本地验证思路]]

<!-- 全库方法索引开始 -->
[[研究前沿/司乘行为序列建模/存量论文分层索引|按主读、储备与待核验找资料]]

- [[研究前沿/面向决策的履约建模/01-论文原文与精读/ActTime/精读|ActTime: Action-Conditioned World Modeling for Time Series]]
- [[论文精读/HyFormer/HyFormer：CTR中的序列建模与特征交互|HyFormer：重新理解 CTR 中的序列建模与特征交互]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/StandIn/精读|Stand-In Effects and Pooling Amplification: Design-Based Tests of Whether Biological World Models Use Actions]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/OpenNWM/精读|OpenNWM: A Generalist Navigation World Model with Latent Action Pretraining]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/LatentForesight/精读|Coordinating Humanoid Loco-Manipulation through Action-Conditioned Latent Foresight]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/PrimeSim/精读|PrimeSim: A Generalist World Model Simulator from Large-Scale Cross-Embodiment Demonstrations]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/DoseAllocation/精读|Transformer-Based Reinforcement Learning for Phase I Dose Allocation]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/ForesightNav/精读|把动作后果蒸馏进单次前向的导航策略]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/INTERACT/精读|用动作条件的未来实体状态监督候选轨迹]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/LaMA-DT/精读|LaMA-DT · 先检验合成轨迹是否自洽，再用于策略学习]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/ComposableCausality/精读|Composable Causality: A Toolkit for Systematic Time-Series Causal Discovery and Treatment-Effect Benchmarking]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/GraspCF/精读|保持动作不变，让独立规划器重标可行性]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/MKD2World/精读|让动作后的局部变化在状态预测损失里可见]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/ADWM-OPE/精读|用目标策略引导下一状态的扩散式离线评估]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/DitherPlanning/精读|反复搜索是否会主动选中模型固定偏差]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/TabularDynamics/精读|最近几条转移足以预测下一步，也足以滚动二十步吗]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/ICUScenario/精读|共用服务队列里，何时把一次行动写回个体历史]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/BilinearBelief/精读|只看到部分状态，如何把不确定性连同动作向前推]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/SuccessorPPO/精读|预测后继的偏好要积累多少真实证据才能用于训练]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/CFEditTest/精读|反事实生成应同时检查动作是否生效和个体是否保真]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/DexForesight/精读|把已执行动作的预测表征蒸馏到轻量策略]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/QCCWM/精读|用同一份空间分组对照宏观状态和生成帧]]
- [[研究前沿/uplift模型迭代/01-论文原文与精读/MarketDoPFN/精读|Market Impact Estimation via Causal Foundation Models]]
- [[研究前沿/动态等待与匹配决策/01-论文原文与精读/arXiv-2611.18139/精读|容量上报滞后时，怎样避免把多份任务同时送往看起来空闲的节点？]]
- [[研究前沿/面向决策的履约建模/01-论文原文与精读/arXiv-2611.17626/精读|能否把部署时的迭代规划挪到训练阶段？]]
- [[论文精读/自动出价论文精读/01_Decision Transformer：RL怎样改写成序列建模|Decision Transformer：RL怎样改写成序列建模？]]
- [[2026推荐系统论文地图/论文/P2_时间长历史与记忆/DTE_2608_16274|DTE · 近期行为、消费周期和短时爆发各有多少价值]]
- [[2026推荐系统论文地图/论文/P2_时间长历史与记忆/KuaFu_2609_31045|KuaFu · 跨用户共享物品计算能否支撑更长的用户画像]]
- [[2026推荐系统论文地图/论文/P2_时间长历史与记忆/SequenceO1_2609_08443|SequenceO1 · 重复请求能否共享远期兴趣摘要]]
- [[2026推荐系统论文地图/论文/P2_时间长历史与记忆/UxSID_2605_09040|UxSID · 能否预先存好用户对每类目标的兴趣]]
- [[2026推荐系统论文地图/论文/P3_意图推理与召回接口/ConnectionMind_2608_10187|ConnectionMind · 社交图路径能否提供行为召回遗漏的候选]]
- [[2026推荐系统论文地图/论文/P3_意图推理与召回接口/OneLatent_WhisperRec_2610_30675|OneLatent / WhisperRec · 显式推理能否压成少数潜在标记]]
- [[2026推荐系统论文地图/论文/P3_意图推理与召回接口/OneReason_2606_06260|OneReason · 近线生成候选与实时推理特征各贡献多少]]
- [[2026推荐系统论文地图/论文/P3_意图推理与召回接口/OneRetrieval_2606_13533|OneRetrieval · 能否整合多路召回并保留运营编辑能力]]
- [[2026推荐系统论文地图/论文/P3_意图推理与召回接口/PAIR_2610_30941|PAIR · 人脉推荐怎样兼顾职业角色与近期偏好]]
- [[2026推荐系统论文地图/论文/P3_意图推理与召回接口/R2QRec_2610_39984|R2QRec · 能否把推荐意图译成已有检索器能用的查询]]
- [[2026推荐系统论文地图/论文/P3_意图推理与召回接口/RPORec_2605_21967|RPORec · 推理文本能给排序器提供多少额外信息]]
- [[2026推荐系统论文地图/论文/P3_意图推理与召回接口/RecGPT-Mobile_2605_04726|RecGPT-Mobile · 刚发生的兴趣能否赶上下次推荐]]
- [[2026推荐系统论文地图/论文/P3_意图推理与召回接口/RecGPT-V3_2607_15591|RecGPT-V3 · 长期意图如何通过标签和语义码进入召回]]
- [[2026推荐系统论文地图/论文/P3_意图推理与召回接口/X-Rec_2609_29180|X-Rec · 多个兴趣向量能否召回互补的物品]]
- [[2026推荐系统论文地图/论文/P5_排序训练与跨阶段协同/ReST_2609_01240|ReST · 强特征是否让精排模型忽略了行为序列]]
- [[知识体系/07-检索与推荐/专题/MIND|MIND：多兴趣召回与 Behavior-to-Interest 动态路由]]
- [[知识体系/07-检索与推荐/专题/序列建模/LONGER|LONGER：工业推荐超长序列建模详解]]
- [[知识体系/07-检索与推荐/专题/特征/SID-Coord Coordinating Semantic IDs for ID-based Ranking in Short-Video Search (Kuaishou, 2026)|SID-Coord Coordinating Semantic IDs for ID-based Ranking in Short-Video Search (Kuaishou, 2026)]]
- [[知识体系/07-检索与推荐/专题/序列建模/SASRec：因果自注意力序列推荐|SASRec：因果自注意力序列推荐]]
<!-- 全库方法索引结束 -->
