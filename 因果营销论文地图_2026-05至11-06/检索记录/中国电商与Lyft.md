> 本文件是检索过程留痕，含初始候选及初稿。最终证据等级、数值解释和修订以各篇正式笔记及复核页为准。

# 中国电商检索与证据卡（含交叉检索命中的 Lyft）

检索日期：2026-11-06；目标时间窗：2026-05-01—2026-11-06。以下事实均与原论文网页核对；“我的推断”是机制解释或采用建议，并非论文已证明结论。

## 已确认清单

|论文|机构证据|日期/版本|纳入意见|证据等级|
|---|---|---|---|---|
|Multi-channel Uplift Policy Learning（ReAlloc）|全文作者署名 Alibaba Group，淘宝实验|arXiv v1 2026-07-30|A：窗内首次公开|全文、合成消融、随机探索 OPE、线上 A/B，但结果表有内部冲突|
|Cross-Head Attention Uplift Network with Inverse Propensity Score under Unobserved Confounding（CHAUN/RA-IPS）|全文多个 Alibaba Group 作者|arXiv v1 2026-06-25|A：窗内首次公开|全文、离线实验与消融；无线上收益验证|
|Next Best Action: Causal Constrained Offline RL for Business Action Targeting（NBA）|五名作者均署名 Lyft|RecSys OARS workshop 2026-09-28；arXiv v1 2026-10-19|A：窗内公开|全文、时间外离线模型 OPE；不是线上收益|
|Scalable and Traceable Joint Uplift Modeling for Multi-Lever Online Marketing（M-DLRI）|KDD 官方作者名单含 Rui Wang/Bin Tong/Guan Wang，Alibaba Group|KDD 2026，DOI 10.1145/3770855.3818477；具体首发需补|保留正式发表候选，全文暂不可访问|KDD 官方名单与 DBLP 可核；ACM 403。不可从二次解读补全公式或实验|
|D³-Subsidy: Online and Sequential Driver Subsidy Decision-Making for Large-Scale Ride-Hailing Market|Didi International Business Group 署名|arXiv v1 2026-05-19；KDD 2026|邻近方向，不计严格因果估计核心集|全文是 diffusion/offline RL 补贴控制，有 A/B，未发现显式混杂识别校正方法|

---

## 1. ReAlloc：固定预算下，学“钱从哪挪到哪”而非只学响应值

**论文**：[arXiv 元数据](https://arxiv.org/abs/2607.28182)；[全文 v1](https://arxiv.org/html/2607.28182v1)。署名在全文首页；方法 §3—5，合成实验 §6，淘宝实验 §7，识别条件和证明附录 A。

### 问题与提出动机

营销预算 B 固定，广告、券、返利占比之和必须为 1。独立拟合各渠道 ROI 再分配，可能遗漏相互替代；联合预测响应后全局搜索，可能把模型从没见过的组合误当最优；低事实 MSE 也不保证挪预算的方向正确。论文将决策对象改为预算单纯形上受支持的局部相对边际收益。

### 方法结构（实现定位）

输入是决策前商品状态 H、预算 B、历史分配占比 p、结果 Y。当前线上分配是决策起点。

1. **快 teacher**：交叉拟合需求基线 m(H,B) 与旧策略平均分配 e(H,B)，计算 Y−m 与 p−e；残差分支以零残差处理为锚。训练同时包含事实响应、残差响应、局部梯度正则（§4.1，式 7—11）。其作用是减少“本来好卖的商品获更多预算”对边际估计的污染。
2. **慢 student**：不是直接平均多个挪钱方向的独立分数，而是学习标量势函数 s(H,B,p)，对它求导得到统一边际场；teacher 的有限差分与 Jacobian 是监督。Replay buffer 和 EMA 使历史几何保留、短期噪声平滑（§4.2，式 12—15）。由同一势函数产生梯度，可避免 A→B、B→C、C→A 的循环矛盾。
3. **保守决策**：只枚举局部零和调配。候选得分为势差减预测不确定性与低支持度惩罚；超过阈值才行动，否则 no-op（§4.3，式 16—19）。

**便于迁移的核心关系**：在固定 B 下，将占比 δ 从 k 挪给 l 的局部效果约为 δ(g_l−g_k)。它不是“l 的效果有多大”，而是“l 相比被抽走预算的 k 是否更值得”。这里 g 是对占比的导数；若要解释为每元收益，应再考虑预算 B 的单位换算。

### 结果与证据强度

- 淘宝 60 天、约 50 万商品；10% 商品随机探索集评估 DR OPE；日常日志只用于匹配后方向排序，作者明确其不能消除未观测混杂。
- Table 4：ReAlloc 的 DR lift 为 0.025，95%CI [0.012,0.043]，无支持模块为 −0.021；行动率分别 0.33 与 0.96。AdditiveROI 的 DR lift 是 0.023，CI [0.015,0.032]。前者均值略高，但区间重叠，不能宣称相对 AdditiveROI 的 OPE 优势显著。
- 线上：14 天、30 万 eligible items，10% ReAlloc、90% AdditiveROI，item 随机。Table 5 显示订单约 +3.5%，GMV −2.6%，营销 ROI −0.1%且不显著。不是“全指标增长”。
- 机制消融 Table 2：完整方法 deployable uplift 0.522；去 orthogonalization 为 0.412；teacher-only 为 0.144；去 support 为 0.001，OOS 0.984。证据支持局部去偏、蒸馏与支持约束共同作用，但它们是该合成设定中的证据，不能把数字当生产收益贡献拆分。

### 收益链路来源：我的推断

**偏差层**：商品需求同时影响投放与转化 → 事实拟合误把需求强弱当“加预算的收益” → 残差化降低这部分偏差 → 相对边际排序更接近真正的可干预响应。

**目标层**：MSE 注重已经发生的点，分配器消费的是相邻动作之间的差值 → 直接蒸馏边际/有限差分让训练容量服务决策 → 减少“预测值都很准但两个方案顺序相反”的错误。

**优化层**：最大化模型会主动挑最大的正向误差 → support/no-op 抑制外推并避免无把握改动 → 少量高可信挪钱能够比高频行动更有效。Table 4 的同样排序、去掉 support 就负收益，是这条链最直接的支撑。

**业务层**：总预算约束内将钱从低边际渠道移到高边际渠道 → 更多被真实激发的订单/更少无效支出。GMV 降而订单升意味着客单结构变化；不能简单说“用户更愿意买所以收入都上升”。按表中四舍五入数字，平均订单额的相对变化可估为 0.974/1.035−1≈−5.9%，这只是总量恒等式推断，不是论文直接报告。

### 与 baseline/pipeline 的关系

|既有组件|ReAlloc 替换或补充什么|不能直接替换什么|
|---|---|---|
|AdditiveROI 分渠道曲线|联合分配下相对边际，允许渠道替代|渠道之外的商品间预算总分配仍需另设层|
|S-learner/NN 的预测后全局优化|局部 causal teacher + 梯度 student + 有支持的搜索|并非换一个 backbone 就等价|
|R-learner/DML|沿用残差化思想，增加非线性响应、边际蒸馏与策略约束|不能把它理解为消除任意隐藏混杂|
|离线 RL 的悲观保守思想|借鉴支持限制、置信惩罚|这里主要是单次固定预算组合决策，不是跨期 CMDP|

### 可直接尝试的迭代与证伪

先保留现有模型，给分配器加“历史支持度 + 最大调幅 + no-op”对照，再做去偏局部斜率估计，最后试蒸馏。这样可以分离收益究竟来自模型还是限制优化器。用小范围随机预算扰动记录真实 propensity，按预算强度/渠道重叠度分层看 DR value、执行率、单位行动收益；线上同时看订单、GMV、毛利、真实支出。若只有 MSE 好看、随机扰动方向判断没改善，收益链第一跳就未成立。

### Double check：必须保留的疑点

1. **正文与表冲突**：§7.2 正文 profit margin +3.26 percentage points，Table 5 为 +1.42pt [0.8,2.0]；不能静默任选其一。主表应采用 Table 5 并注明正文不同，或暂不引用该收益作为确定值。
2. **置信区间冲突**：Table 5 cost 点估计 −2.5%，CI 却是 [−2.0%,−0.8%]，未包住点估计。需作者澄清。
3. Platform income 写“+3.2pt”，但未给清晰归一化分母；不可改写成收入 +3.2%。
4. §6 消融文字说“约 60% oracle gain”，Table 2 Rec.=0.455；应报告表中值而非复述宣传口径。
5. 正交化的保证有条件，连续多维处理仍要求局部支持及合适的 nuisance/局部模型。不要把“unbiased local gradients”当无条件生产事实。附录 A.1 明确要求给定 X 的处理可忽略性（潜在结果与分配独立）、一致性及局部 overlap；A.4 也明确正交化本身不保证识别。
6. 已用 [PDF 第8页](https://arxiv.org/pdf/2607.28182v1#page=8)复核 Table 5 与正文，利润/成本CI矛盾两版本一致，不是HTML解析造成。

---

## 2. CHAUN + RA-IPS：把处理/对照的信息共享与隐藏混杂稳健性拆成两个模块

**论文**：[元数据](https://arxiv.org/abs/2606.27114)；[全文 v1](https://arxiv.org/html/2606.27114v1)。方法 §3—4，数据 §5.1，主结果 Table 3，RA-IPS Table 4，架构消融 Table 5。

### 为什么提出

双头模型需要既学到处理与对照共有的购买倾向，又保留处理造成的差异。固定共享或完全独立都可能欠佳。另一个独立问题是站外广告历史 exposure 受外部媒体策略影响，当前特征无法记录所有共同原因；只用观测特征拟合 propensity 的 IPS 不会自动修复未观测混杂。

### 方法与数据流

`决策前特征 x → shared embedding → (propensity MLP；control MLP；treated MLP)`。

- 两个 outcome 表征相互做 query/key/value 注意力，分别输出 μ0 与 μ1，uplift 为 μ1−μ0；这是**同一用户的两个潜在结果表示之间**的交互，不是把处理组用户和对照组用户直接拼在一起，也不是将已实现 outcome 输入网络。
- Propensity 头用 treatment label 训练；IPS 加权 outcome loss；倾向分数用于 outcome loss 时 stop-gradient。另用两组平均逆概率权重应为 1 的矩约束抑制极端拟合（§4.1.4）。
- RA-IPS 给未观测因素造成的 logit 扰动设 Γ 上界，在允许的权重集合里找使损失最大的权重，再优化模型；Γ=1 退化普通 IPS。这是有明确敏感度范围的稳健优化，不是从数据识别出隐藏变量。与 RD-IPS 仅设逐样本权重上下界不同，RA-IPS 还试图约束全样本权重相对名义权重的平均偏移，避免因损失非负而把所有权重同时顶到上界。不过其写出的软约束公式存在符号疑点，见下方复核。

### 因果识别边界

论文所谓 ITE(x) 实际写成 E[Y(1)−Y(0)|X=x]，统计意义更接近 CATE，不能声称恢复每个个体的真实两个结果。Theorem 1 需要知道包含未观测 U 影响的真实 propensity π(x,u)。即使不显式观察 U，只要每条记录的真实分配概率确实已知，IPW 有识别信息；用 π(x) 代替并不满足前提。RA-IPS 的 guarantee 又依赖真实权重位于选定不确定集合、overlap、损失/权重有界。模型效果好与这些前提成立是两件事。

### 数值结果：优先与最强基线比较

|数据|CHAUN QINI|最强其他 QINI|相对改善（重算）|
|---|---:|---:|---:|
|CRITEO-UPLIFT|0.1955|DragonNet 0.1898|约 3.00%|
|LAZADA|0.0314|TARNet 0.0302|约 3.97%|
|Production|0.0130|DESCN 0.0122|约 6.56%|

摘要最高 +25.6% 实际对应 LAZADA 相对 DragonNet 0.0250，而非相对最强基线。Production top30 uplift：CHAUN 0.0261，DESCN 0.0286；如果线上只投 top30%，整体 QINI 更好并不必然使实际策略更好。

RA-IPS Table 4：Production CHAUN QINI 从 IPS 0.0130 到 0.0136（按四舍五入数重算约 +4.62%，正文说“最高5.4%”，无法用表中数字精确还原）；LAZADA-Masked 从 0.0221 到 0.0230，约 +4.07%；CRITEO-Masked 0.1658→0.1704，约 +2.77%。不要把 5.4% 当线上收入收益。

架构消融 Table 5：LAZADA QINI BaseNet 0.0236、MMoE 0.0262、CHAUN 0.0314；在这里 cross-head 相似度交互胜于相近参数量的通用两专家 gate。Criteo 上差距小，说明并非所有场景都值得复杂化。

### 收益链路来源：我的推断

**架构链**：两种潜在结果共享大量基础购买规律 → 动态共享可减少数据少的一支估计方差，同时保留 treatment 特异模式 → 两头相减时的误差减小 → 更可靠地把“本来会买”与“被促成购买”的人分开 → 在相同触达预算下可能减少无效曝光。但如果共享过强，两头一起塌缩，uplift 差异也会消失；因此应检查 τ 的离散度、分层校准而非只看 μ 的 AUC。

**稳健链**：历史媒体选择导致 propensity 偏差 → 普通 IPS 把某些高损失/稀有群体看轻 → 最坏权重训练促使模型不要依赖脆弱的归因 → 在合理混杂范围内排序不易翻转 → 策略跨媒体/跨时段更稳。Γ 过大可过分悲观、牺牲效能，且“隐藏混杂被消除”不是结论。

### 替换关系与最小实验

CHAUN 可替换 TARNet/DragonNet 一类双头的 outcome representation 模块；RA-IPS 可独立替换 IPS loss，不必和新架构捆绑上线。先做同一数据拆分上的 2×2：BaseNet/CHAUN × IPS/RA-IPS，再比 MMoE 保持参数量接近。固定后端预算分配，用真实 RCT 或随机 holdout 按目标投放比例看 Qini、top-k 增量、净收益以及 Γ 敏感性，避免只优化全曲线指标。

### Double check

1. 原论文 CRITEO 将原始随机 treatment 改成实际 exposure，再 PSM 构造评估集；不能写它直接在原始随机实验处理标签上验证。
2. Production 的评估依赖能额外拿到部分隐藏特征的一组样本做 PSM，仍是 pseudo-RCT，匹配不是随机化证据。未观测混杂完全消失未经证明。
3. Table 3 原文说 12 个指标中 9 个第一，按可见表实际有 4 项不是第一（Criteo AUUC、Lazada PUC、Production LIFT@30、Production PUC），不要复述“9/12”。
4. 没有线上 A/B 结果；其工程价值是候选模型与稳健 loss 的离线证据。
5. 网页残留 Conference 2018/Woodstock 和 Received 2009 模板占位；日期以 arXiv submission history 为准，不能据模板声称会议发表。
6. **复现前必须澄清 RA-IPS 符号**：§4.2 式13前的权重内层 argmax 写为加权损失 **加** λ×平均权重偏移的平方；Table 2 中 λ 为正。对最大化问题，加正平方会奖励偏离，而非约束偏离；与其文字“抑制全体权重膨胀”目标冲突。[PDF 第6页](https://arxiv.org/pdf/2606.27114v1#page=6)与HTML一致，不能归咎于HTML转写。可能是符号笔误或遗漏约束，需作者代码/更正核实。若自行实现硬约束内层最大化或负惩罚，应标记为我们依据方法意图改写的版本，不能声称逐式复现。
7. PDF 第9页的 Tables 3—5 已与 HTML 对照，以上指标重算及名次疑点在两版本一致。

---

## 3. Lyft NBA：因果转移模型 + 约束 MDP，让发券投资到长期状态变化

**论文**：[元数据](https://arxiv.org/abs/2610.26817)；[全文 v1](https://arxiv.org/html/2610.26817v1)。首页署名/会议，方法 §2，实验 §3—4，限制 §5。

### 为什么提出、解决什么

常见 `uplift → 当期 knapsack/LP` 会优先追当周反应；普通 RL 虽看长期，却可能从旧策略日志学到选择偏差，并把预算、频控做成软惩罚。NBA 让“因果校正的状态转移”和“显式预算约束下的长期价值”一起进入可审计 LP。

### 方法与核心式

案例每周决策，过去 28 天 RFM 经中位数划分形成 8 个生命周期状态，动作只有发券/不发券；即时 reward 是业务混合指标，γ=0.9。68 周数据中前 52 周训练、后 16 周构造评估 dynamics。

1. 用状态 s 与已观测混杂 z 拟合旧策略 propensity π_b(a|s,z)。
2. 通过 self-normalized IPW（权重按99分位裁剪）估计 P(s'|do(a),s) 与 R(s,do(a))。
3. 以状态动作 occupancy ζ(s,a) 为 LP 变量，最大化 ΣζR，加入 Bellman 流守恒与预算/群体支出/频控/竞争动作/资格/公平六类约束。解后归一化 ζ 得到随机策略。
4. 对偶变量给出预算或护栏的影子价格；零占用状态默认不干预。

**我的机制解释**：一个动作的增量长期价值可理解为“当前增量 reward + γ×它改变未来状态分布所带来的价值差”。相比只看 μ1−μ0，这里会为“当前响应一般但能够形成持续使用习惯”的人保留预算。该解释用于理解机制，不是原文另报告的数值。

### 已报告结果与未报告结果

在观测 coupon-rate cap 下，用时间外 holdout 数据估计的 dynamics 做**模型型 OPE**：相对估计历史策略 LTV +19%，相对 myopic 策略 +8%。模型将部分券从 Champion/Loyalist 移向 At-risk/Hibernating/Promising/New；myopic 更偏 Dormant，而长期策略更偏 New。**未报告线上 A/B**，不能说 Lyft 线上 LTV 已提升19%。

### 收益链路来源：我的推断

旧策略给高活跃人更多券，原始数据容易把他们高 LTV 归功于券 → 对 s,z 重加权降低可观测选择偏差 → 得到更接近发券本身作用的当周回报与后续状态变化 → MDP 将复购/习惯形成累计成未来价值 → LP 在相同预算中比较这些跨期价值 → 券从自然活跃者或只买一单的人挪向长期行为可改变者。论文的分群政策差异与 +8% 对 myopic 的离线结果支持“跨期优化有价值”，但不能单靠一套估计 dynamics 证明真实习惯形成。

### pipeline 替换关系

- 相对静态 uplift+MCKP/LP：替换的是“决策价值对象及状态流约束”，不是只将 CATE 的名字改成 LTV。
- 相对普通 offline RL：SNIPW 校正可观测混杂，LP 显式表达约束；仍需 no-unmeasured-confounding 与正确 dynamics。
- 相对 ReAlloc：NBA 主要处理跨期状态与预算，ReAlloc 处理同一次预算内部多渠道占比及局部支持；若要结合，需避免把两层的预算/费用重复计账，先明确时序与动作粒度。

### 可落地最小实验

先用足够粗的生命周期状态搭 8×2 表格 dynamics，与现有同预算短期策略对比；检查权重有效样本量、各状态动作覆盖、状态转移校准与时间漂移。做 2×2 消融：是否重加权 × 是否长期 LP，避免将全部 +19% 归于因果去偏。将累计净收益与发券成本、频率上限纳入评价，保留无券对照，至少覆盖多个复购周期的线上随机验证。若“新客→活跃”转移只有模型估计变好而随机试验不变，收益链关键跳失败。

### Double check

1. RFM 是近似 Markov 假设。过去28天重叠窗口本身使状态有记忆；强 LTV 预测力不等价于 Markov 充分性。
2. SNIPW 只处理记录到的共同原因；裁剪有偏差—方差权衡。
3. 在8状态2动作中支持充足，不代表扩到几十种券和用户向量仍充足。
4. γ=0.9 每周意味着很远期收益权重快速衰减，LTV 实际是该折扣目标下的值，不是任意定义的全年真实利润。
5. LP 约束是给定估计 dynamics 下的期望/长期频率约束，不意味着真实线上每一天每一条路径都严格不超支。
6. 文章没有置信区间和线上检验结果；+19% 与 +8% 不能当确定的可迁移收益。

---

## 4. M-DLRI：已确认论文存在，原文访问受限，避免以解读代替精读

- [KDD 2026 官方列表](https://kdd2026.kdd.org/papers/)搜索结果给出标题和作者机构：Zhe Wang / Ziyu Guan / Yaming Yang / Wei Zhao（西电），Rui Wang / Bin Tong / Guan Wang（Alibaba）。
- [DBLP 记录](https://dblp.org/rec/conf/kdd/WangWGYTZW26)：KDD (2) 2026:8202–8213。
- [ACM DOI](https://doi.org/10.1145/3770855.3818477)与 PDF 访问均返回403，未获全文。
- 淘天技术文章转载线索是[智源社区](https://hub.baai.ac.cn/view/55064)，标注来源“阿里妈妈技术”、2026-05-29；另[tool.lu 转载摘要](https://tool.lu/en_US/article/7Ys/detail)指向登录后可见的微信原文。它们只能用于定位原文，不能作为本轮严格方法/数值结论。
- 候选问题：多种营销杠杆联合处理的组合稀疏、参数爆炸、单调性及归因。线索提及 CP 低秩分解/联合编码/对数加性门控，但具体公式、识别假设、线上指标分母未核验。
- **不应引用未核实收益**：二手摘要分别出现 ROI +0.86% 与 incremental ROI +7%，可能指标不同，也可能转述错，不能混写。等待全文后再完整拆解。

## 5. D³-Subsidy：可借鉴的邻近工业控制 pipeline

[全文](https://arxiv.org/html/2605.20036v1)；[元数据](https://arxiv.org/abs/2605.20036)。2026-05-19 首发，Didi 国际业务与港大/港理工/哈工大合作，KDD 2026。

问题是城市供需动态下司机补贴、跨时预算率上限与服务延迟。用固定历史 prefix 条件化 diffusion 生成未来轨迹，inverse 模块解码城市级控制量，再通过拉格朗日对偶导出的闭式映射发到订单—司机粒度；多城市预训练与参数高效适配。§4.6 为2026-02-01—07真实线上A/B：同补贴率 cap，两组各50%订单，202,279 broadcasts；Rides +1.59%，GMV +2.06%，额外20ms；7天未超cap。

**为什么只作邻近**：有补贴干预与策略A/B，但核心是生成式顺序控制，未见显式估计 CATE、混杂去偏或可识别反事实建模；不能因为结果叫 uplift 就分类为 uplift estimation。可替换现有 city controller，在用户/司机 response 模块和控制模块之间提供借鉴。业务收益可能来自时序预算调度、约束与延迟改善；不能归因于“因果识别更准”。注意订单随机化在共享司机供给和城市预算下可能存在干扰，线上结果不自动等价于无干扰个体效应。

## 6. 排除与候选日志

|候选|结论|证据|
|---|---|---|
|Estimating the Effect of Timing on Coupon Effectiveness，2606.30664|旧作补上传，严格排除|[arXiv](https://arxiv.org/abs/2606.30664)明写发表于 KDD 2022 workshop；2026-06-17 只是上传|
|Jointly Optimizing Debiased CTR and Uplift for Coupons Marketing，2602.12972|2026-02-13，早于窗；若窗内正式发表可归 B，需另核|[arXiv](https://arxiv.org/abs/2602.12972)|
|Entire Chain Uplift Modeling with Context-Enhanced Learning for Intelligent Marketing，2402.03379|旧稿，检索显示2026-01-23撤回；不计窗内|需要最终用 arXiv 核查，不能采用 alphaXiv 自动生成2026 bib年份|
|Data-Driven Real-Time Coupon Allocation in the Online Platform|最初2024-02-29，2026-01-03修订；不计本窗新作|[作者SSRN](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4742589)|
|Oransim|2026-04-18，窗前且非小红书企业作者|[作者页](https://oran-cgsj.github.io/oransim-archive/)|

美团、京东、百度、小红书、拼多多、蚂蚁按 `2026 + causal/uplift/marketing/coupon/incentive + company` 与站点限定检索，此轮未确认新的严格核心论文。此表不是“这些公司没有论文”的断言，只反映本轮公开来源能核实的结果。

## 7. 搜索执行与错误披露

使用 web 搜索组合：`2026 uplift Alibaba`、`2026 causal marketing Meituan`、`2026 uplift JD.com`、`site:arxiv.org 2026 Alibaba causal marketing`、`site:arxiv.org 2026 Didi coupon`、`site:arxiv.org 2026 Baidu uplift`、`2026 uplift Pinduoduo`、`2026 causal marketing Xiaohongshu`、`2026 causal incentive Ant Group`，以及所有命中题目/模型名/DOI的精确检索。对命中的 arXiv abs 和 HTML逐项读取日期、署名、方法、结果和消融。

已按 paper-search skill 执行：

```text
python3 /Users/didi/.codex/skills/paper_search/scripts/search_papers.py --query 'uplift marketing Alibaba Meituan Didi' --start-year 2026 --end-year 2026 --max-papers 10
```

脚本 API 搜索失败，不把失败记作“数据库无论文”：

```text
[dblp] unavailable (import failed: No module named 'requests'); skipping this source.
[open_alex] unavailable (import failed: No module named 'requests'); skipping this source.
[openreview] Error: openreview not installed. pip install openreview-py
[crossref] unavailable (import failed: No module named 'requests'); skipping this source.
[semantic_scholar] unavailable (import failed: No module named 'requests'); skipping this source.
[arxiv] Error: <urlopen error [Errno 1] Operation not permitted>
```

六个API均未返回可用结果，转由联网 web 检索与原文核查。没有使用 model-knowledge 生成未核实的2026论文。

[返回检索说明](../05-检索说明与排除记录.md)
