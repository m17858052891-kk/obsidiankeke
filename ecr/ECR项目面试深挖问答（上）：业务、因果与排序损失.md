---
tags: [ECR, Uplift, CFR, AUCC, 面试问答]
---

# ECR 项目面试深挖问答（上）

> 范围：第 1—62 题，覆盖业务问题、实验数据、CFR、因果伪标签、Corr Loss 与 Matched Pairwise。  
> 回答口径：项目实验已经验证的现象，用“项目中观察到”；未正式上线或仅为后续设计的内容，用“如果上线/下一步我会”。

## 一、项目全貌与业务目标

### 1. 这个 ECR 项目一句话是在解决什么问题？

这是一个多档位补贴场景下的 uplift 排序项目。目标不是预测谁最可能呼叫，而是识别“给某一档补贴后，呼叫概率相对不补贴真正增加更多”的用户，并在因果评估可信的前提下把他们排在前面，服务有限预算下的选人和选档。

### 2. 什么是 ECR？补贴档位具体代表什么？100 档为什么是 control？

项目关注的是补贴对呼叫转化的增量效果。数据中共有 10 个价格/补贴档位，100 档代表基准价格或不额外补贴，因此作为 control；73、76、79 等其他档位代表不同力度的补贴 treatment。数值是业务价格体系编码，因果含义是“某个补贴动作”相对“基准动作”的效果。

### 3. 业务为什么不能直接给所有人最高补贴？

最高补贴带来直接成本，且很多用户即使不补也会呼叫，对他们补贴没有增量收益。业务应比较每档补贴带来的增量呼叫、增量价值和补贴成本，在预算约束下优先给净增量价值更高的人，而不是只追求绝对呼叫率。

### 4. 你的最终优化目标为什么是 Call AUCC，而不是呼叫率、GMV 或模型 AUC？

Call AUCC 衡量按 uplift 分数从高到低投放时，前部人群能否累积更多真实呼叫增量，因此与有限预算下优先覆盖谁直接对齐。普通 call AUC 只评价事实组响应预测；GMV 需要进一步结合交易价值和补贴成本。项目先解决因果排序，再由策略层把 uplift 与成本、价值组合。

### 5. “预测用户会不会呼叫”和“预测补贴是否带来增量呼叫”有什么本质差异？

前者预测 \(\Pr(Y=1\mid X,T=m)\)，后者关心

$$
\tau_m(X)=\Pr(Y=1\mid X,T=m)-\Pr(Y=1\mid X,T=100).
$$

自然呼叫率很高的用户在两种档位下都可能高，因此事实响应高，却未必值得补贴。

### 6. 给一个“自然会呼叫但不该补”和“原本不呼叫但值得补”的例子。

用户 A 在 100 档的呼叫概率是 0.80，73 档是 0.82，uplift 为 0.02；用户 B 在 100 档是 0.10，73 档是 0.25，uplift 为 0.15。A 的绝对呼叫率更高，但有限补贴预算下应该优先 B。

### 7. 这个项目最终是“选人”“选券档”还是两者都做？线上动作是什么？

模型为每个用户、每个非 control 档位输出 uplift score，所以同时支持选人和按档比较。线上不应简单取最大 uplift，而应比较每档预期增量价值减补贴成本，再在预算约束下决定是否触达、选哪一档。本项目核心完成多档 uplift 排序底座，资源分配属于后续策略层。

## 二、实验设计、样本与标签

### 8. 数据来自 RCT 还是观察性日志？随机化单位是什么？

项目数据来自多档位补贴实验，因果主张主要依赖实验分流。回答时必须如实说明实际随机化单位；训练记录显示有订单行与重复 PID 问题，因此不能笼统说每一行独立随机。若随机化发生在乘客粒度而训练按订单行展开，需要承认用户内相关性。

### 9. 如果是 RCT，为什么仍有 treatment-ratio 偏斜和选择偏差风险？

RCT 只保证随机化单位上的可比性，不自动保证后续训练行独立、过滤后仍可比。重复冒泡、高频 PID、分流后的样本筛选、缺失和不同档位的样本生成机制，都可能让订单行的有效权重失衡。模型因此可能识别 treatment 身份或采样结构。

### 10. 训练样本是一行代表什么？

当前更接近行为/订单行级样本，而不是严格的一人一行，因此同一 PID 可多次出现。这提升样本量，但高频用户会在 loss 和 AUCC 中被重复加权。随机化、训练、评估三者粒度是否一致，是该项目最关键的数据诊断之一。

### 11. 同一个 PID 重复为什么影响因果评估？

同一用户多次出现时，其自然响应倾向、历史特征和 treatment 暴露被重复计入，样本不再独立。模型可能通过识别高频用户而非真实 treatment effect 提升排序。应同时做 PID 聚合/去重、用户日权重、用户粒度曲线和分簇标准误诊断，不能仅靠删除样本。

### 12. 你怎么定义 label：发券后多久内 call 算正样本？

应采用业务事先定义、对所有档位一致的归因窗口，例如价格展示/补贴触达后规定时间内是否产生有效 call。窗口结束必须晚于特征截点，且要处理重复触达与无法归因样本。具体时长应按项目真实口径回答，不能临场猜测。

### 13. 样本过滤会不会引入 post-treatment selection bias？

若过滤只使用 action 前已经存在的信息，如基础准入或请求有效性，风险较低；若使用展示后点击、发单、应答等被 treatment 影响的变量，就会破坏可比性。我的原则是把训练样本准入限制在 action 前或 action 无关条件，并对任何分流后过滤做组间平衡检查。

### 14. 特征截点在哪里？哪些特征不能用？

特征必须截止在补贴档位决定和展示之前。可以使用用户历史、当前请求上下文、实时供需和价格锚点；不能使用本次展示后的点击、最终价格、发单、应答、完单、实际优惠成本等后验信息。否则会产生线上不可用的泄漏。

### 15. 哪些特征可能泄漏 treatment 身份？

直接档位 ID、补贴金额、展示后的价格字段最危险；档位专属渠道标记、实验分流标识、按组写入的统计字段和高频行结构也可能间接泄漏。排查可训练 treatment classifier、看高分桶 treatment-ratio、并做各特征的 SMD 平衡诊断。

### 16. 极端 PID、高频用户日问题是什么？为什么不能统一降权？

极端高频 PID 在订单行训练中被重复放大，强 rank loss 易把其携带的结构当作 uplift。项目中 Clean PID 后排序效果改善，说明确有污染；但按用户日频次统一降权又损失效果，因为高频行为里也有真实价格敏感度信号。应区分异常重复和合法高频，而非一刀切。

### 17. 不同档位的样本量、正样本率、分流概率是否一致？

不能假设一致。必须按档统计样本量、call rate、实际 treatment share、propensity、特征 SMD 和有效 pair 数。若深档样本少或 propensity 小，IPW 与 Corr 方差会更大；因此项目按 treatment 计算 rank loss，并在 loss 内做分档标准化。

### 18. 深折扣档为什么更难、更不稳定？

深档常常样本更少、成本更高，且价格锚点变化与响应长尾更明显。其伪标签方差更大，cumulative 结构下误差也可能传播，所以强排序更容易出现 treatment-ratio 偏斜。应逐档报告 AUCC、Qini、样本量和成本收益。

## 三、因果目标与 CFR baseline

### 19. baseline CFR 的结构是什么？

baseline 是共享 Embedding 与 Shared Bottom，加 treatment-specific response heads。共享底座学习用户和场景的通用表示，每个档位 head 输出该档位下的 call probability；训练时用实际分流档位的 factual label 做 BCE，并保留 CFR 的表征约束。

### 20. Shared Bottom 和 treatment heads 分别做什么？

Shared Bottom 学习跨档共享的用户历史、请求和供需规律，提高样本效率；treatment heads 表达不同补贴力度下的响应差异。完全独立 tower 浪费样本，完全共享又忽略档位异质性，CFR 是两者的折中。

### 21. CFR 输出什么？单档 uplift score 如何计算？

模型输出各档响应概率 \(\hat p_m(x)\)。对档位 \(m\)，以 100 档为 control：

$$
s_m(x)=\hat p_m(x)-\hat p_{100}(x).
$$

单档 AUCC/Qini 按 \(s_m\) 排序。该分数是 CATE 的模型估计，不是观测到的个人 ITE。

### 22. 为什么不直接预测一个 uplift head？

uplift 没有个人真实标签；直接预测会失去 factual response 的锚点，也难验证概率是否合理。先预测各 treatment 下的 \(\mu_m(x)\)，再做差，能够利用事实监督、保留多档概率解释，并为排序损失提供稳定起点。

### 23. factual BCE 监督的是哪一个 head？

对样本 \(i\)，只监督其实际 treatment \(T_i\) 对应的输出：

$$
L_{\mathrm{factual}}=-\frac1N\sum_i[y_i\log\hat p_{T_i}(x_i)+(1-y_i)\log(1-\hat p_{T_i}(x_i))].
$$

其他反事实 head 没有该样本真实标签，只能借助共享参数、表征约束和其他样本间接学习。

### 24. CFR 的表征平衡损失解决什么？为什么不够？

它希望不同 treatment 组在共享表征空间更可比，减少协变量分布差异被误当成 treatment effect。它改善因果表征和反事实外推，但不显式要求高 uplift 人群排在前面；所以 factual/balance 做好，不代表 Call AUCC 最优。

### 25. CFR 与 DRCFR 的区别？为什么最后用 CFR？

DRCFR 更强调把与 treatment、outcome 相关的表征成分解耦；CFR 是更直接的共享表征加平衡。项目中 DRCFR factual baseline 和加入 rank 后都没有稳定超过 CFR 的 Call MTAUCC，所以选 CFR 是该数据和配置下的实证选择，不是说 DRCFR 理论上无效。

### 26. factual AUC 高，为什么 Call AUCC 仍可能差？

factual AUC 区分“会 call”和“不会 call”；AUCC 区分“补贴增量大”和“增量小”。自然高响应用户会帮助 factual AUC，却可能在 treatment/control 下都高，从而没有 uplift。两者标签与排序目标不同，必须同时评估。

### 27. 多档位 head 是独立还是累计？为什么？

基础结构共享 embedding/bottom，档位使用特异输出；项目也讨论过 cumulative head，用相邻档位增量构造深档输出，以注入补贴力度与响应的平滑先验。它能减少档位乱跳，但会让浅层增量接收多个深档 loss、误差沿路径传播，因此需与独立 head 对照验证。

### 28. 多档响应一定单调吗？累计 head 会不会引入错误先验？

不一定。更大补贴通常提升意愿，但实际响应还受供给、价格锚点、展示机制和样本选择影响。累计 head 若强加严格单调，可能系统性扭曲真实异质性；应比较独立、累计和弱单调正则，而非直接假设。

### 29. FiLM、累计 head、独立 head 各适合什么情况？

独立 head 最灵活，适合档位效应差异大且样本充足；累计 head 适合有较强平滑/单调先验的场景；FiLM 对共享表示做档位特异的轻量调制，适合主体规律共享但各档需要小偏移。它们只能改善表达能力，不能替代因果识别。

## 四、真实 ITE 不可见与 IPW 伪标签

### 30. 什么是 ITE、CATE、ATE？你的模型估计哪一个？

ITE 是同一用户两种潜在结果的差 \(Y_i(m)-Y_i(100)\)，但无法同时观察；ATE 是总体平均差；CATE 是给定 \(X=x\) 后的平均差。模型输出的是 CATE 估计，用于个体排序；不能说获得了真实 ITE 标签。

### 31. 为什么不能拿用户真实 uplift 当监督标签？

同一用户一次只能进入一个档位，只看到 \(Y_i(T_i)\)，看不到同一时刻的 \(Y_i(m)\) 与 \(Y_i(100)\)。这是反事实不可观测性。只能利用 RCT、IPW、DR 等方法构造总体上合理的代理监督与评估。

### 32. 你的 IPW 伪标签公式是什么？

对 treatment \(m\) 与 control 100 的子样本，我使用：

$$
\phi_{i,m}=(2Y_i-1)\left[
\frac{\mathbb I(T_i=m)}{e_m(X_i)}
-\frac{\mathbb I(T_i=100)}{e_{100}(X_i)}
\right].
$$

其中 \(e_m(X)\) 是进入档位 \(m\) 的 propensity。它用于给单档 score \(s_m(x)\) 提供排序方向，而非充当个人真实 uplift。

### 33. propensity 用已知分流概率还是估计值？

理想 RCT 中优先使用实验配置或可审计的实际分流概率，因为更稳定、没有额外估计误差。若存在分层分流、过滤或与特征有关的不均衡，则可估计 \(e_m(X)\)，但必须校准、clip 并检查 overlap。不能为了“模型复杂”而在严格随机实验中盲目引入 propensity head。

### 34. 既然是 RCT，为什么还要 IPW？

若各 arm 概率不同，IPW 让不同分流比例下的观测结果可比较；即使等概率，公式也统一 treatment/control 的符号与贡献。更重要的是项目要构造样本级排序代理信号，而不只是计算 ATE。但理想 RCT 下 IPW 也不能解决重复行、后处理筛选和高方差。

### 35. IPW 成立需要哪些假设：随机化、overlap、SUTVA？

随机化/可忽略性要求给定 \(X\) 后 treatment 分配与潜在结果独立；overlap 要求每类相关用户进入 treatment 与 control 的概率都大于零；SUTVA 要求 treatment 定义唯一，且一个用户结果不被其他人的 treatment 通过未建模路径影响。补贴场景的供需和竞争会挑战最后一点，所以结论应限定在当前实验环境。

### 36. 小 propensity 有什么问题？如何处理？

小 propensity 会使 \(1/e_m(X)\) 极大，少数样本主导 Corr、Pairwise 和 AUCC，导致高方差与不稳定。应报告每档 propensity 分布、最大权重和有效样本量；可使用 clip、稳定化权重或仅保留 overlap 区域。代价是引入偏差，但常比无控制的极端方差更稳。

### 37. 为什么把 \(y\) 转成 \(2y-1\)？

若直接使用 \(y\in\{0,1\}\)，所有未 call 样本的 transformed outcome 都为零，treatment 未 call 与 control 未 call 没有区分。映射后 call 为 \(+1\)、未 call 为 \(-1\)，四种观测情形都有正负排序证据，提高了未响应样本利用率。

### 38. 四类样本的伪标签方向分别是什么？

treatment-call 为正，treatment-no-call 为负；control-call 为负，因为不补也会 call；control-no-call 为正，因为其在基准档没有自然响应。最后一类仅表示总体上的相对正向证据，不表示该个人一定会被补贴激活。

### 39. control 未 call 为什么是正向证据，却不等于一定会被拉动？

其正号来自 control 项前的负号与 \(2y-1=-1\) 的乘积，帮助模型识别“基准条件下不自然 call”的人群。但 treatment 下会不会 call 仍不可观测，他也可能对所有补贴无响应。因此它只是统计排序信号，不是个人反事实标签。

### 40. 伪标签是无偏 ITE 吗？它在哪个意义下有用？

不是个人 ITE 的无偏观测，单样本方差很大。若 propensity 正确且 overlap 成立：

$$
\mathbb E[\phi_{i,m}\mid X=x]
=2\{\mu_m(x)-\mu_{100}(x)\}.
$$

其条件期望与 uplift 同方向，因此可作排序辅助监督；不适合作为要求逐点精确拟合的真值。

### 41. 如何推导它的条件期望？

treatment 项的条件期望为 \(2\mu_m(X)-1\)，因为 indicator 的期望正好抵消 \(e_m(X)\)；control 项同理为 \(2\mu_{100}(X)-1\)。两项相减后常数抵消，得到 \(2(\mu_m-\mu_{100})\)。该推导依赖分流概率正确和可比性假设。

### 42. 实验分流比例与日志比例不一致会怎样？

若只是已知且稳定的不等比例分流，用正确 propensity 可校正尺度；若比例变化来自分流后筛选、缺失或不同 arm 的样本生成机制，仅用全局比例不够。需要分时间、城市、人群检查实际 share、propensity AUC、SMD 和 overlap，再决定条件 propensity 或限制训练人群。

## 五、Corr Loss

### 43. 为什么不用 MSE 或 Huber 直接回归伪 uplift？

IPW/PU 伪标签方差大、极值多，而 AUCC 关心高增量用户是否排在前部，不要求 score 与伪标签逐点相等。MSE 易被小 propensity 极值支配；Huber 虽稳一些，仍是点式数值拟合。Corr 直接优化整体高低变化方向，更贴近排序目标。

### 44. Corr Loss 的公式是什么？为什么对齐 AUCC？

对一个档位的有效样本，令 \(s\) 为预测 uplift、\(\phi\) 为伪标签：

$$
\rho=\operatorname{Corr}(s,\phi),\qquad
L_{\mathrm{corr}}=1-\rho.
$$

它要求高 \(\phi\) 对应高 \(s\)、低 \(\phi\) 对应低 \(s\)。AUCC 也只依赖排序前后关系，因此 Corr 比 factual BCE 或伪标签 MSE 更直接对齐。

### 45. Pearson correlation 对平移、缩放有什么性质？

整体平移和正比例缩放不会改变相关系数，乘以负数会翻转相关符号。因此 Corr 不约束 score 的绝对量级，只约束同向变化。优点是抗伪标签尺度问题，代价是不能把 Corr 后 score 当作精确的因果效应数值，必须保留 factual/base loss。

### 46. Corr Loss 是 listwise、pairwise 还是 pointwise？

它是更接近 listwise/global 的损失：一次用一个有效 treatment 子组内的均值、方差和协方差。它不是逐点回归，也不显式枚举样本对。监督稠密是其优势，batch 构成和极端样本敏感是其风险。

### 47. Corr 在 batch 内怎么计算？按 treatment 分开还是混算？

应在每个 treatment \(m\) 与 control 的有效子样本内分别计算，再对各非 control 档平均或加权。不同档的样本率、分数尺度和业务语义不同，混算会让样本量大或尺度大的档位主导 loss，也混淆单档 uplift 的定义。

### 48. 某档 batch 样本很少、方差接近零怎么办？

设置最小有效样本数，不足时跳过该档本 batch 的 Corr 或使用跨 batch 滑动统计；分母加 \(\epsilon\) 只能避免 NaN，不能制造信息。若长期不足，应增大 batch、对稀疏 arm 重采样，或承认该档当前无法稳定做 rank 学习。

### 49. Corr 的梯度为什么既强又可能不稳定？

Corr 的均值、方差和协方差都由全体样本共同决定，单个样本会影响全局统计量，因此梯度是耦合的。样本充足时能同时推动大量样本建立整体排序；IPW 极值、少量深档样本或 score 方差小的时候则会放大。这也是分档校准、Tanh 和 TwoStage 的必要性。

### 50. Corr 为什么会学到 treatment assignment artifact？

若特征能预测样本来自 treatment 还是 control，模型可利用伪标签的组别符号结构提高相关性，而不是识别真实异质效应。高频 PID、订单行重复、后处理筛选都可能制造该捷径。因此 Corr 提升后必须同时看 treatment-ratio、propensity AUC、SMD、用户粒度和 OOT 稳定性。

### 51. Corr 权重从弱到强时发生什么？为什么不选最大权重？

项目中增大 Corr 往往显著提高 Call MTAUCC，强 rank 单阶段或强 soft-unfreeze 可接近 0.89；同时 treatment-ratio 风险也更明显。最终 H2 Soft T2 用较保守的 Corr 权重 0.015、Pairwise 0.003，Call MTAUCC 为 0.65293；它不是最高 AUCC 点，而是 ratio 相对可接受候选中的稳定折中。

## 六、Matched Pairwise

### 52. 既然有 Corr，为什么还需要 Pairwise？

Corr 只保证整体同向，不能直接约束某个局部样本对是否错序。Pairwise 明确要求可信正向证据排在可信负向证据前，可修正局部错误，也限制 Corr 只靠整体漂移取巧。因此 Corr 是主损失，Pairwise 是辅助约束。

### 53. Pairwise 的样本对如何构造？

在某 treatment 与 control 的有效样本内，先筛出方向明确的组合，如 treatment-call 对 control-no-call，或 treatment-no-call 对 control-call。再在表征或严格截点协变量空间中选相近的异组 Top-K 邻居，按相似度加权，并用 logistic/softplus loss 推动正确顺序。

### 54. 为什么 treatment-call 对 control-no-call 应排在前？

在可比人群内，前者在有补贴时 call，后者在基准档未 call，是较强的“补贴可能产生增量”的方向证据。它不是同一人的反事实，因此必须依赖随机化或匹配降低混杂；Pairwise 将其作为局部排序监督，而不是确定真值。

### 55. 为什么 treatment-no-call 对 control-call 应排在后？

前者给补贴仍未 call，后者不补已 call，按 uplift 直觉前者更不像高增量用户。这与 transformed outcome 的正负方向一致。前提仍是两者在 treatment 之外足够可比，不能随意跨人群配对。

### 56. 为什么不能随机配对？

随机 pair 可能在城市、活跃度、行程质量、价格敏感度上完全不同，差异主要来自协变量而非 treatment。模型会学到错误顺序。匹配的目的就是近似构造“除 treatment/outcome 外相似”的局部比较。

### 57. 表征空间 Top-K 软匹配怎么做？

使用 Stage 1 相对稳定的 shared representation 或严格截点特征计算 treatment-control 样本相似度；每个锚点取异组最相近的 \(K\) 个邻居，项目配置中 \(K=4\)。再用 match temperature 把相似度转为软权重，对多个 pair loss 加权平均，降低单个最近邻配错的影响。

### 58. 用哪个 representation 做 matching？Stage 2 表征在变怎么办？

更稳妥的是使用 Stage 1 representation 或 stop-gradient 表示构造 pair，让匹配关系不被当前 rank loss 反向操纵。若动态随 Stage 2 刷新，匹配可能漂移，模型可能把空间改成有利于 loss 的形状；若必须刷新，应低频更新并监控距离、覆盖率与稳定性。

### 59. matching 是否 detach？Top-K 是否可导？

通常将邻居索引和匹配权重作为构造监督集合的离散步骤并 detach。Top-K 本身不可导，也没有必要让梯度穿过“谁是邻居”；梯度只需作用于 pair 内 score 的相对顺序。这更符合匹配负责可比性、rank loss 负责排序的分工。

### 60. Top-K、matching temperature、rank temperature、margin 分别是什么？

Top-K 决定每个锚点使用几个邻居；matching temperature 控制权重集中在最近邻还是分摊给多个邻居；rank temperature 控制 score 差进入 logistic 后的斜率；margin 是希望正负分数至少拉开的距离。它们都在权衡局部监督的强度和噪声。

### 61. Pairwise 单独效果为什么弱于 Corr？

Pairwise 只使用满足方向和匹配条件的少量 pair，覆盖率低，每个 pair 仍有反事实噪声；Corr 能利用一个 batch 内全部有效样本，监督更稠密。项目实验中 Pairwise-only 对 baseline 仅小幅改善，因此最终采用 Corr 主导、Pairwise 辅助。

### 62. Pairwise 会不会把“相似”误当成“反事实可比”？

会。表示距离小不等于严格因果可比；若表示含 treatment leakage，matching 甚至会放大问题。因此 Pairwise 不能单独证明因果有效，必须结合 RCT、协变量 SMD、propensity 诊断、不同匹配特征敏感性实验和用户粒度/OOT 评估。
