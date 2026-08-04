---
tags: [ECR, Uplift, 因果推断, 面试, RankLoss]
---

# ECR 面试深挖问答（第一批）

覆盖问题 1–63：业务目标、数据与实验、CFR baseline、IPW 伪标签、Corr Loss、Matched Pairwise。

> 使用边界：以下回答依据当前 ECR 项目材料整理。随机化粒度、线上分流规则、字段口径等未逐项确认的信息，回答时应说明“需要以实验配置或日志口径核实”，不要把推测说成项目事实。

## 一、项目全貌与业务目标

### Q1：这个 ECR 项目一句话是在解决什么问题？

**答：** 这是一个多档位补贴下的 uplift 排序问题。目标不是找最容易呼叫的人，而是找在某档补贴相对 100 档对照策略下，真正新增呼叫更大的用户。原 CFR 偏向事实响应预测，我在其上加入直接面向 Call AUCC 的排序监督，并用 TwoStage 和 ratio 诊断控制偏差风险。

### Q2：什么是 ECR？补贴档位具体代表什么？100 档为什么是 control？

**答：** 在本项目语境里，ECR 指面向不同补贴档位的呼叫响应与增量排序系统。73、76、79 到 100 表示不同力度的价格或补贴策略；100 档代表基准策略，因此作为 control。对档位 $m$，我们关心的是 $\hat p_m(x)-\hat p_{100}(x)$，而不是 $\hat p_m(x)$ 的绝对大小。

### Q3：业务为什么不能直接给所有人最高补贴？

**答：** 因为补贴有成本，高补贴也不必然带来等比例新增呼叫。自然会呼叫的人继续补贴，只是把原有交易变得更贵；对价格不敏感的人补贴也可能没有效果。真正业务目标应是有限预算下的净增量收益，而不是 treatment 组表面 call rate。

### Q4：为什么最终看 Call AUCC，而不是呼叫率、GMV 或模型 AUC？

**答：** Call AUCC 衡量按 uplift score 排序后，榜首人群是否带来更多 treatment 相对 control 的呼叫增量，和预算有限时“优先给谁补”的动作一致。分类 AUC 奖励的是谁会呼叫，容易把自然高响应用户排前；整体呼叫率会混入自然呼叫和成本。GMV 是更终局的指标，当前项目的直接干预标签是 Call，因此先用 Call AUCC 验证增量排序，线上再结合成本和收益决策。

### Q5：响应预测与补贴增量预测有什么本质差异？

**答：** 响应预测估计 $P(Y=1\mid X,T=m)$；uplift 估计的是反事实差值：

$$
\tau_m(x)=P(Y=1\mid X=x,T=m)-P(Y=1\mid X=x,T=100).
$$

一个用户不补贴也会呼叫，响应概率可以很高，但 uplift 接近零。前者回答“谁本来会叫”，后者回答“给谁补贴才会多叫”。

### Q6：给一个自然会呼叫但不该补、以及值得补的例子。

**答：** 用户 A 在 100 档下 call 概率为 0.90，在 73 档下为 0.92，uplift 只有 0.02；他虽然好转化，却不值得优先花补贴。用户 B 在 100 档下为 0.10，在 73 档下为 0.35，uplift 为 0.25，更值得补。这个例子说明 factual BCE 的最优排序不一定是 AUCC 的最优排序。

### Q7：项目最终是选人、选券档，还是两者都做？

**答：** 离线模型为每个档位生成 uplift score，因此支持“各档选人”；真正线上策略还应比较不同档的净增量价值，决定给谁、给哪一档或不给。完整决策可写为“预期增量收益减去补贴成本”，并加预算、频控和用户体验约束。当前项目核心先解决前半段：让各档的增量排序更可信。

## 二、实验设计、样本与标签

### Q8：数据来自 RCT 还是观察性日志？随机化单位是什么？

**答：** 当前材料按多 treatment 的 RCT 数据处理，分流概率可用于 IPW。但不能只停在“是 RCT”：必须核实随机化单位是乘客、乘客日、订单还是冒泡请求。若随机化在乘客粒度、训练却是订单行，同一用户的重复出现会改变有效样本权重，后续分析不能再简单把每一行视为独立随机样本。

### Q9：如果是 RCT，为什么仍有 treatment-ratio 偏斜和选择偏差风险？

**答：** RCT 仅保证随机化时点、随机化单位上的 treatment 与协变量独立。分流后的样本过滤、缺失、同一 PID 高频冒泡、不同组留存率不同，或把用户级试验拆成订单行后重复计权，都可能让训练样本出现结构偏差。因此 ratio 偏斜不等于实验无效，但必须当作模型可能学习到组别或频次结构的告警。

### Q10：训练样本一行代表什么？

**答：** 应以实际数据表粒度回答，不能模糊说“一个用户”。当前项目已经发现 PID 重复和用户日频次问题，说明样本很可能包含多次冒泡或订单行。比较稳妥的描述是：每行对应一次可执行补贴决策的观测，但训练与评估必须补充用户级、用户日级去重或聚合诊断，防止少数高频用户主导结果。

### Q11：同一个 PID 重复出现为什么会影响因果评估？

**答：** 高频 PID 会在 loss 和 AUCC 中拥有更大权重；如果高频行为与 treatment 覆盖、城市或价格敏感度有关，模型可能学习“谁重复出现”而不是“谁对补贴敏感”。样本也不再独立，随机切分可能让同一人同时出现于训练和验证。项目对极端 PID 清洗，并将用户粒度验证作为必要补充。

### Q12：你怎么定义 label：发券后多久内 call 算正样本？

**答：** 应定义为“本次补贴或报价决策对应的有效观察窗口内是否发生 call”。窗口必须在 treatment 生效之后、下一次独立决策之前，并处理取消、重复冒泡和跨窗口归因。当前材料未给出固定时长，面试时应如实说明它由具体实验口径决定，不能编造一个小时数。

### Q13：样本过滤会不会引入 post-treatment selection bias？

**答：** 会。理想情况只使用 treatment 前已确定的准入规则；若按 treatment 后的曝光、展示、发单、支付或订单状态过滤，就可能只保留各档位下不同的“幸存”样本，使 treatment/control 不再可比。应画出完整样本漏斗并比较每层各组留存率，将所有 treatment 后字段从特征和准入条件中隔离。

### Q14：特征截点在哪里？哪些特征绝不能使用？

**答：** 截点应在本次补贴展示或价格决策之前，只使用历史行为、当前供需和决策前可获得的上下文。不能使用 treatment 后才产生的展示结果、实际支付金额、是否发单、是否应答、后续等待时长或最终完单结果；这些都可能造成未来信息泄漏或控制中介变量。工程上应按事件时间戳控制，而不是只按日期分区。

### Q15：哪些特征可能泄漏 treatment 身份？

**答：** 最直接的是优惠金额、最终应付价、券标签和档位 ID；更隐蔽的是由 treatment 影响的展示 box、下游支付字段、订单状态及处理后的供需统计。还有渠道、城市、用户分层等代理变量，若它们与分流规则高度相关，也可能泄漏组别。判断原则是：在用户被分到当前档位之前，这个字段是否已经存在。

### Q16：极端 PID、高频用户日问题是什么？为什么简单降权会伤害效果？

**答：** 少数 PID 或用户日的重复行会放大 Corr/IPW 的统计影响，使模型把频率结构误当 uplift。项目中清洗极端 PID 后，PU-Corr 的表现变好，说明异常重复确有污染；但对所有高频样本用 $\sqrt{\text{frequency}}$ 统一降权又使效果回落，因为高频中也有真实价格敏感信号。因此不能把频次一概视为噪声。

### Q17：各档位样本量、正样本率、分流概率是否一致？

**答：** 不应假设一致。档位间的样本量、call rate、有效覆盖和分流比例都会影响 IPW 方差、Corr 的 batch 稳定性和 AUCC 置信度。训练前应按档统计样本数、正负比例、propensity、有效 pair 数和 score 分布；训练时还要设置每组最小样本保护。

### Q18：深折扣档为什么通常更难、更不稳定？

**答：** 深折扣档往往样本更少、分布和 control 差异更大，overlap 更弱，IPW 方差也更高。其 uplift score 更容易长尾，强 Corr 会被极端样本带动。项目按 treatment 做 Z-score 与 Tanh 校准，正是为了限制这种档位尺度差异和长尾梯度。

## 三、CFR baseline 与多档响应建模

### Q19：你的 CFR baseline 结构是什么？

**答：** CFR 由共享 Embedding 与 Shared Bottom 学习用户和上下文表示，再通过 treatment-specific heads 输出各补贴档位的 call probability。训练时只对样本实际进入的 head 计算 factual BCE，同时通过 CFR 的表征约束缓解 treatment 间分布差异。档位 $m$ 与 100 档预测概率的差即为该档 uplift score。

### Q20：Shared Bottom 和 treatment-specific heads 分别负责什么？

**答：** Shared Bottom 学习跨档位共享的需求、价格敏感、城市供需等共性信息，提高样本效率；各 treatment head 表达不同补贴力度下的异质响应。完全独立十个塔会损失共享统计强度，只用统一 head 又难表达档位差异，因此共享底座加分支 head 是折中。

### Q21：CFR 输出什么？单档 uplift score 如何计算？

**答：** CFR 输出每个档位下的预测响应 $\hat p_m(x)$。以 100 档 control 为基准：

$$
s_m(x)=\hat p_m(x)-\hat p_{100}(x).
$$

单档离线 AUCC/Qini 按 $s_m$ 排序。多档上线不能仅选最大 $s_m$，还要将补贴成本、收益和预算约束纳入。

### Q22：为什么不直接预测一个 uplift head？

**答：** uplift 没有逐样本真值，直接预测一个 uplift head 缺少可靠的事实监督，也可能脱离各 treatment 响应概率的约束。CFR 先从可观测的 factual outcome 学 $\hat p_m$，再差分得到 uplift；我的 rank loss 是约束这个差分的顺序，而不是放弃 factual response 模型。

### Q23：CFR 的 factual BCE 监督的是哪一个 head？

**答：** 样本 $i$ 只监督其实际观察到的 $T_i$ 对应 head：

$$
L_{\mathrm{factual}}=-\frac1N\sum_i[y_i\log\hat p_{T_i}(x_i)+(1-y_i)\log(1-\hat p_{T_i}(x_i))].
$$

其他档位输出是反事实预测，不能用这条样本的 $y_i$ 直接监督。

### Q24：CFR 的表征平衡损失解决什么问题？为什么还不够？

**答：** 平衡损失让不同 treatment 组在表示空间更接近，降低模型把组间协变量差异误当作 effect 的风险。它解决反事实外推的表示差异，却不直接要求 uplift score 的 Top 排序正确。即使 factual 概率和表示平衡都不错，概率差的顺序仍可能与真实增量排序不一致，所以还需要 AUCC 对齐的 rank 目标。

### Q25：CFR 与 DRCFR 的区别是什么？为什么最终偏向 CFR？

**答：** CFR 更强调反事实回归与表征平衡；DRCFR 进一步解耦与 treatment、outcome 相关的表示成分，理论上希望减少混杂干扰。当前实验中 DRCFR 的 factual baseline 和加入 rank 后都没有稳定超过 CFR，因此最终按 Call MTAUCC、ratio 稳定性和训练可控性选择 CFR。这里不是说 DRCFR 理论无效，而是它在当前数据和任务上的经验收益不稳定。

### Q26：如果 factual AUC 很高，为什么 Call AUCC 仍可能很差？

**答：** factual AUC 奖励区分会 call 与不会 call 的人，其中包含自然高响应用户。Call AUCC 关注的是 treatment 相对 control 的增量，要求把“因为补贴才 call”的人排在前。因此一个模型可以很准确地预测自然呼叫，却不擅长识别补贴真正带来的边际效果。

### Q27：多档位 head 是完全独立还是共享/累积的？为什么？

**答：** 当前主线是共享 Embedding 与 Shared Bottom、档位特异 head。项目也讨论过 cumulative head：它可以注入相邻档位平滑或单调先验，但会让浅层增量承受多个深档 loss 的梯度。独立 head 表达力更强却高方差；是否引入累计结构必须用逐档 response curve、ATE、校准和线上收益验证，而非凭直觉决定。

### Q28：多档位响应一定单调吗？累计 head 会不会引入错误先验？

**答：** 更大补贴通常提高效用，但实际观测响应还受展示、供需、品类和样本选择影响，并不保证严格单调。强行累计或单调约束可能减少无意义交叉，也可能压掉真实的异质或非单调模式。因此将它作为可检验先验更合理：先看相邻档 ATE、响应曲线和校准，再决定约束强度。

### Q29：FiLM、cumulative head、独立 head 各适合什么情况？

**答：** 独立 head 适合档位差异很大且样本充足的场景；cumulative head 适合档位顺序和响应平滑先验可信的场景；FiLM 用 treatment-specific 的缩放和平移调制共享表示，是参数量较小的折中。当前 H2 的核心改动不依赖 FiLM，它是后续缓解多档梯度冲突的候选方向，不应说成已经验证的最终模块。

## 四、ITE 不可见与 IPW 伪标签

### Q30：什么是 ITE、CATE、ATE？你的模型估计的是哪一个？

**答：** ITE 是单个用户在 treatment 与 control 下潜在结果的差，但无法直接观测；ATE 是全体平均差；CATE 是给定特征后的条件平均差。模型用 $\hat p_m(x)-\hat p_{100}(x)$ 估计的是 CATE/uplift score，并用它排序；不应声称得到了每个人真实 ITE。

### Q31：为什么不能拿用户真实 uplift 当监督标签？

**答：** 每个用户一次只能进入一个档位，只能看到 $Y_i(T_i)$，看不到该用户在其他档位下的潜在结果。RCT 只能保证不同用户群体平均可比，不能让同一用户同时经历 treatment 和 control。因此只能构造总体有效的 IPW、DR 或 matching 监督。

### Q32：你的 IPW 伪标签公式是什么？

**答：** 对档位 $m$ 与 100 档 control 的子样本：

$$
\phi_{i,m}=(2y_i-1)\left[
\frac{\mathbb I(T_i=m)}{e_m(x_i)}
-\frac{\mathbb I(T_i=100)}{e_{100}(x_i)}
\right].
$$

$e_m(x)$ 是用户进入档位 $m$ 的 propensity。它是 transformed-outcome 风格的排序伪标签，而不是个人真实 uplift。

### Q33：propensity 用已知分流概率还是估计 propensity？

**答：** 若实验配置可信且随机化概率已知，应优先使用已知分流概率，因为它更稳定，不额外引入 propensity 模型误差。若分流随分层变化、样本经过复杂过滤，或怀疑训练粒度上的有效分流已偏离随机化，则要估计 $e_m(x)$，并检查 treatment prediction AUC、校准、overlap 与重加权后协变量平衡。具体选择必须和随机化单位、样本漏斗一起说明。

### Q34：既然是 RCT，为什么还要 IPW？

**答：** 理想等比例 RCT 下，IPW 可以退化为对各组结果的常数缩放；保留它能统一处理多档位不均匀分流、不同有效样本量和可能存在的分层随机化。它表达的是“观测到的某组样本代表多少目标人群”。但不应因为是 RCT 就盲目训练复杂 propensity 模型；若分流概率相同且数据干净，额外估计反而可能增方差。

### Q35：IPW 成立需要哪些假设？

**答：** 第一是随机化或给定 $X$ 后无混杂；第二是 overlap，即每类特征人群进入 treatment 和 control 的概率都大于零；第三是 SUTVA，即 treatment 定义明确且用户结果不受其他用户 treatment 影响。打车补贴还应讨论干扰：大规模补贴会改变供需与价格，严格 SUTVA 可能近似而非完全成立。

### Q36：小 propensity 会带来什么问题？是否做 clipping？

**答：** 小 $e_m(x)$ 会使 $1/e_m(x)$ 极大，少数样本即可主导伪标签、Corr 和 Pairwise 梯度。应先检查 propensity 分布与有效样本量；必要时做 clipping、稳定化权重或限制在 common-support 人群。clipping 是偏差与方差的折中，是否采用要同时看 AUCC、ratio、ATE error 和时间外稳定性。

### Q37：为什么把 $y$ 变成 $2y-1$？

**答：** 直接使用 $y\in\{0,1\}$ 时，所有未 call 样本的伪标签都会是零，treatment 未 call 与 control 未 call 对排序没有区分。映射后，call 为 $+1$，未 call 为 $-1$，四类观测都有方向信息。它并不让单样本成为真实 ITE，但提高了稀疏 call 标签下的排序监督密度。

### Q38：四类样本的伪标签符号分别是什么？

**答：** treatment-call 为正，treatment-no-call 为负；control-call 为负，因为不给补贴也会 call，更接近自然响应；control-no-call 为正，表示在基准策略下未响应、相对存在可被激励空间。这里的正负是总体排序证据，不能解释成单个 control-no-call 用户已被证明会响应补贴。

### Q39：control 未 call 为什么是相对正向证据？

**答：** 它说明该用户在 control 下没有自然 call，因此相对 control-call 用户，不应被当成自然高响应人群；在 transformed outcome 构造中对 uplift 方向有正向贡献。但它只能说明“仍可能有被激励空间”，不能证明给券一定有效。所以它需要与 treatment 观察、可比性匹配和最终实验评估结合。

### Q40：这个伪标签是无偏 ITE 吗？它在什么意义下有用？

**答：** 它不是个人真实 ITE，也不应按逐点回归标签理解。在正确分流、overlap 成立时，其条件期望满足：

$$
E[\phi_m\mid X=x]=2\bigl(\mu_m(x)-\mu_{100}(x)\bigr).
$$

因此它在总体或条件平均意义上给出 uplift 的同向监督，适合排序；单样本方差很高，正是后续不用 MSE、采用 Corr 和稳健训练的原因。

### Q41：你能推导它为什么与 uplift 同方向吗？

**答：** 条件于 $X=x$，有：

$$
E\left[\frac{\mathbb I(T=m)(2Y-1)}{e_m(x)}\middle|X=x\right]
=E[2Y(m)-1\mid X=x].
$$

control 项同理；两项相减后常数 $-1$ 抵消，得到两倍的 $\mu_m(x)-\mu_{100}(x)$。倍数不影响排序，但这一推导依赖分流正确与 positivity。

### Q42：如果实验分流比例和日志有效比例不一致，会怎样？

**答：** 如果只是已知的非均匀随机分流，使用正确组别 propensity 可以校正。若不一致来自过滤、缺失或策略性曝光，则不能只用一个全局比例，需要重新定义目标人群、估计有效 propensity，并检查重加权后协变量平衡。否则高分人群可能只是某档覆盖更高的人，而非 uplift 更高的人。

## 五、Corr Loss：全局排序监督

### Q43：为什么不用 MSE 或 Huber 直接回归伪 uplift？

**答：** IPW 伪标签高方差且尺度受 propensity 影响，MSE 会让少数极值主导训练，要求模型拟合不可靠的绝对数值。AUCC 主要关心谁排前面，而不要求预测值精确等于伪标签。Corr 只要求预测分数与伪标签整体同向变化，对整体平移和正比例缩放相对不敏感，更贴近排序目标。

### Q44：Corr Loss 的公式是什么？为什么更贴近 AUCC？

**答：** 对某档位有效 batch：

$$
\rho=\operatorname{Corr}(s,\phi),\qquad
L_{\mathrm{corr}}=1-\rho.
$$

它推动高伪标签样本获得更高 score、低伪标签样本获得更低 score，因此直接改善全局顺序。AUCC 也按 score 排序并观察前段累计增量，所以两者在排序目标上对齐；但 Corr 不是 AUCC 的严格可微等价式。

### Q45：Pearson correlation 对平移、缩放有什么性质？

**答：** 给 score 加常数不会改变 correlation；乘以正数不会改变方向，乘以负数会翻转符号。因此 Corr 不保证 score 的绝对大小或概率校准，只保证共同变化方向。项目必须保留 factual BCE，避免模型只有排序分数却失去各档响应概率的业务语义。

### Q46：Corr Loss 是 listwise、pairwise 还是 pointwise？

**答：** 它是 batch/listwise 的统计排序目标：一组样本共同决定均值、方差与协方差。它不同于逐点 MSE，也不同于显式比较一对样本的 Pairwise loss。项目让 Corr 提供稠密的全局方向，再用 matched Pairwise 补充局部错序。

### Q47：Corr 在 batch 内怎么计算？按 treatment 分开还是混在一起？

**答：** 应在“某 treatment 与 100 档 control”的有效子样本中分别计算，再聚合非 control 档位。不同档位的样本量、补贴力度、IPW 方差和 score 尺度不同，混在一起会让大样本或极端档位主导梯度。项目也按 treatment 进行 score calibration。

### Q48：某档位样本很少、方差接近零怎么办？

**答：** 应设置每组最小样本阈值，材料中至少有每组样本保护；若样本不足或 pseudo/score 方差过小，应跳过该组 loss、掩码或累计更多样本，而不是除以极小方差。还要长期监控每档有效样本数、梯度范数和被跳过比例，防止深档训练失真。

### Q49：Corr Loss 为什么可能很强、也可能不稳定？

**答：** 它一次利用 batch 内大量样本，梯度稠密，因此能迅速拉开整体排序；同时均值、方差和协方差都是 batch 统计量，IPW 极值、小组样本、高频 PID 与长尾 score 都会影响整组梯度。Z-score、Tanh、TwoStage 和软解冻本质上都是在约束这种强但噪声较大的排序信号。

### Q50：Corr Loss 为什么会把 treatment assignment artifact 当成有效排序信号？

**答：** 如果某些特征能预测 treatment，或 treatment 组在订单行粒度上有更多重复记录，这些特征会与伪标签结构相关。Corr 只优化 score 与 pseudo 的同向性，无法识别这种相关来自真实 effect 还是分流/频次结构，于是可能把 treatment 样本整体排到前面。Qini treatment-ratio 前段偏斜就是这一风险的告警。

### Q51：Corr 权重提高时发生了什么？为什么不选最大权重？

**答：** 实验显示增强 Corr 能显著拉升 AUCC，证实原 factual 目标缺少排序监督；但强 Corr、单阶段训练或更大软解冻也会使 ratio 风险回升。最终 H2 使用较保守的 $\lambda_{\mathrm{corr}}=0.015$，并结合 Pairwise、校准和 soft-unfreeze，而不是选择 B2/E3 一类离线 AUCC 更高但可能放大 selection artifact 的方案。

## 六、Matched Pairwise：局部错序修正

### Q52：既然有 Corr，为什么还需要 Pairwise？

**答：** Corr 约束整组共变趋势，仍可能保留许多局部错序，也可能通过整体漂移取巧。Pairwise 明确要求可信样本对中谁应排在谁前，提供局部、可解释的约束。项目中 Corr 负责全局稠密方向，Pairwise 负责局部修正和限制捷径。

### Q53：Pairwise 的样本对具体怎样构造？

**答：** 对档位 $m$，使用 treatment-call 相对 control-no-call 应更高、treatment-no-call 相对 control-call 应更低这两类方向。在 treatment/control 的协变量或表征空间中找相近样本，选择 Top-K 邻居并用相似度软加权，而不是全局随机配对。

### Q54：为什么 treatment-call 对 control-no-call 应排在前？

**答：** 对可比用户，前者在 treatment 下 call、后者在 control 下未 call，较符合“补贴产生正向增量”的局部观测方向。它不是证明前者真实 ITE 必然大于后者，而是为 ranking 提供一条更可信的相对监督；匹配是降低人群差异混入该监督的关键。

### Q55：为什么 treatment-no-call 对 control-call 应排在后？

**答：** 前者在给了该档后仍未响应，后者不补贴也会自然 call；若两人协变量相近，前者缺乏补贴增量的证据，后者更像自然响应。因此前者应得到更低 uplift score。这一负向 pair 与正向 pair 一起使用，才能充分利用未 call 信息。

### Q56：为什么不能随机配对？

**答：** 随机 treatment 与随机 control 用户可能在城市、需求、价格锚点和历史活跃度上完全不同，outcome 差异会混入人群差异。Pairwise loss 会误把基线异质性学成 treatment effect。必须先限定可比邻域，并检查匹配后关键协变量平衡。

### Q57：在表征空间 Top-K 软匹配具体怎么做？

**答：** 对每个 treatment 样本，计算其与 control 候选的距离或相似度，取最相近的 $K$ 个，再对相似度做 softmax 得到权重 $w_{ij}$，用加权 Pairwise logistic loss 聚合。它比单一最近邻更稳，也比随机配对更能控制异质性；但 $K$、距离和温度必须通过有效 pair 数和稳定性消融选择。

### Q58：用哪个 representation 做 matching？Stage 2 表征在变，pair 是否跟着变？

**答：** 最稳妥的是使用 Stage 1 anchor 的冻结表示，或对表示 stop-gradient 后构造 pair，避免 rank loss 通过移动表征改变匹配关系。若每一步都基于不断变化的 Stage 2 表征重新匹配，模型可能得到更容易的 pair，训练会更不稳定。当前具体实现应按代码确认，不能把动态 matching 说成已验证事实。

### Q59：matching 是否 detach？Top-K 是不是不可导？

**答：** Top-K 选择通常不可导，工程上应把它视为 pair mining，不让梯度通过“谁被选中”反传；选中后的权重是否可导也需谨慎。对本项目，更重要的是防止模型为了降低 pair loss 而操控匹配集合，因此倾向将 pair 构造与主梯度隔离。实际实现细节应以代码为准。

### Q60：Top-K、matching temperature、rank temperature、margin 分别是什么意思？

**答：** Top-K 决定每个样本引用多少相近反事实候选；matching temperature 控制邻居权重是否集中于最近样本；rank temperature 控制 Pairwise logistic 曲线的陡峭程度；margin 决定希望两者 score 至少拉开多少。当前材料记录了 $K=4$、matching temperature=0.2、rank temperature=1.0、margin=0.0；它们都应通过 AUCC、ratio、有效 pair 数和时间外稳定性选择。

### Q61：Pairwise 单独效果为什么弱于 Corr？

**答：** Pairwise 只利用满足组别、outcome 方向和相似性要求的样本对，监督覆盖稀疏，且每个 batch 的有效 pair 数有限、受匹配质量影响。Corr 则对整组样本提供稠密梯度，更易建立全局排序。项目中 Pairwise only 仅小幅优于 CFR baseline，因此适合作为辅助而非主 loss。

### Q62：Pairwise 会不会把相似误当成反事实可比？

**答：** 会。高维距离近不代表所有混杂都已消除，尤其当表征本身也受 outcome 或 rank loss 影响。Pairwise 只是降低随机配对噪声的工程近似，不等于观察到真实反事实。需要配合 SMD、不同匹配空间的敏感性分析、用户级曲线与 RCT 评估。

### Q63：为什么 Pairwise 是辅助项而不是主 loss？

**答：** 它的方向更局部、更可解释，但 pair 稀疏且匹配存在误差；若作为主项，训练信号覆盖不足且波动大。Corr 提供主导的全局排序方向，Pairwise 修正局部顺序和限制捷径。最终 H2 使用较小的 $\lambda_{\mathrm{pair}}=0.003$，正是实验支持的分工。
