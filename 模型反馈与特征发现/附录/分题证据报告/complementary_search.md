> [!info] 分题阶段记录
> 此文件保留分题阅读时的版本与措辞。最终版本、合并结论和统计以专题主报告及证据台账为准。

# 互补特征组合搜索：证据与技术路线

更新：2026-11-06。此分支核查 30 篇候选，其中 12 篇为核心方法阅读；另附 SCOPE-FE v2 专项核查，总计 31 条。11 个论文关联仓库读取了 README，其中多个继续读取实现；SCOPE-FE 同名候选仓库另计，未认定为作者代码。没有安装或运行模型实验，没有写入用户 Obsidian vault。

结构化记录见 主 JSON（工作记录：`complementary_search.json`） 与 SCOPE-FE 补充（工作记录：`complementary_search_supplement.json`）。逐篇记录明确阅读深度；“摘要核查”“方法局部核查”不能当作全文精读。实验数字均为论文报告，不是本次复现实验。

## 先区分三种“组合”

1. **一个公式内部组合输入列**：例如 $x_1/x_2$、分组聚合、树表达式。IIFE、AutoCross、DSR/PySR、TopoFE 主要包含这类搜索。
2. **多个输出列一起形成表示**：例如 $\Phi=[g_1(X),g_2(X),g_3(X)]$。FEAT 个体明确是一组树表示；其模型读取整组表示。这个搜索单位最贴近“某列单独没有明显收益，但和另一列一起有效”。
3. **按整体模型中的重要性给单列排序**：OpenFE 第二阶段、SAGE 的最终输出属于相关但不同的情形。联合训练或联盟平均能让分数反映交互，却不保证按分数取 top-k 就得到最优集合。

必须同时问：搜索状态是什么、一次变更是什么、评价时带哪些其他列、最后怎样选出集合。论文写“joint”“interaction”“beam”或集合 argmax，不能替代这些检查。

**树 Gain 不是单变量检验。** 一个节点的分裂收益取决于此前路径所划分的样本，整棵树可以表达交互。但从根开始的贪心分裂可能难以进入初期零收益的纯协同结构；训练完成的 gain 排名也不是对所有特征子集重新训练比较。OpenFE 恰好有两个不同环节：第一阶段逐候选 FeatureBoost 加速筛选，第二阶段将存活新列和原列共同输入 LightGBM 后排序。因此把整个 OpenFE 简化为“单变量检验”不准确；第一阶段漏掉弱单列强联合的候选，仍是合理机制风险。[OpenFE 论文](https://proceedings.mlr.press/v202/zhang23ay.html)

## 什么算互补，以及为什么难搜索

以下为分析框架，不是某篇论文的性能主张。令 $U_A(S)$ 表示在固定训练/验证划分、模型族 $A$、预算与指标下，把候选集 $S$ 加到原始特征后重新训练所得效用。比较：

- 单列条件增益：$\Delta(i\mid S)=U_A(S\cup\{i\})-U_A(S)$。
- 双列整体增益：$\Delta(\{i,j\}\mid S)=U_A(S\cup\{i,j\})-U_A(S)$。
- 二阶非加和项：$\Gamma(i,j\mid S)=U_A(S\cup\{i,j\})-U_A(S\cup\{i\})-U_A(S\cup\{j\})+U_A(S)$。

这些量依赖模型、样本、指标和背景集合，不能直接解释为因果互补。全体 $m$ 个候选的子集空间有 $2^m$ 个；只看大小不超过 $k$ 的组合仍有 $\sum_{r=0}^{k}\binom{m}{r}$。便宜反馈的作用是分配搜索预算，而不是消除组合复杂度。

**XOR 是机制反例，不是本次实验。** 若两个独立均匀二元输入的标签为 XOR，则两者边际互信息各为 0，联合互信息为 1 bit。先用边际相关筛掉它们会失败；保留一列后，另一列的条件信息才显现。三元 parity 进一步表明成对筛选也可能看不到高阶结构。mRMR、JMI、CMIM 是不同低维近似，不应统称为“都解决互补”。Brown 等人的统一框架可解释这些准则如何近似条件似然，以及统计估计成本。[Brown et al.](https://www.jmlr.org/papers/v13/brown12a.html)

另一个容易混淆的点：若 $g(X)$ 是完整原始输入的确定函数，则 $I(Y;g(X)\mid X)=0$。特征工程仍可能让有限模型更容易拟合、优化或泛化；这不等于凭空增加标签信息。跨表、历史窗口、聚合或 transductive 统计若引入不同可用上下文，需另外定义输入边界。

## 对应到可落地的研究路线

以下路线是基于证据的设计推论，没有宣称验证有效。

| 路线 | 主要借鉴 | 反馈进入哪里 | 对互补的价值 | 代价与边界 |
|---|---|---|---|---|
| 候选扩展前先分配算子/输入对预算 | IIFE、SCOPE-FE、SAFE | 目标交互信息、探测增益、树路径 | 把预算分配给更有希望的组合 | 对/算子先验可能漏掉低相关、高阶、跨簇组合 |
| 保留多个部分集合并允许合并/交换 | ExploreKit、AutoCross、RL transformation graph | 当前集合的条件增益与后续收益 | 比固定单次排名更接近集合问题 | beam 宽度有限仍会丢失先降后升路径；应明确实现是否真的多分支 |
| 整组表示作为个体进化 | FEAT | 样本损失、读出权重、梯度、复杂度 | 一次评价整组树；细粒度反馈决定改哪棵树 | 搜索昂贵，结果依赖读出模型和预算；无全局最优保证 |
| 联合可微门控 | STG、Concrete、L0 | 训练损失梯度与稀疏约束 | 可在优化中让多个输入共同保留 | 主要选择固定候选，不自动发现离散程序；非凸、松弛和阈值误差 |
| 家族多样性和跨家族表达式合成 | TopoFE、DSR/PySR、有限 MAP-Elites 先例 | 家族停滞、跨家族收益、表达式奖励 | 避免搜索只在一个算子家族内收缩 | 多样性指标不等于预测协同；最终逐列贪心仍可能漏组 |
| 联盟归因作为搜索诊断 | SAGE、Shapley–Taylor | 联盟中的损失贡献、交互归因 | 判断冗余/协同，辅助挑选待验证组合 | 归因不是最优子集搜索；条件分布近似与计算预算很关键 |

更明确的候选方案是：便宜的算子/成对反馈用于**提议和预算分配**；保留少量随机与跨家族候选，避免硬筛选封死空间；以一小组完整候选集作最终比较，允许 add-pair、swap、merge 等集合操作；把验证增益、稳定性、成本和失败原因分别记入搜索记忆。这里“保留随机配额”“增加集合操作”是建议，不是 IIFE 或 SCOPE-FE 已报告实现。

## 最直接的主证据

**IIFE 比一般相关性筛选更贴近本问题。** 它使用 $I(F_i;Y\mid F_j)-I(F_i;Y)$ 给输入对打分，以 top-K 对生成二元候选，然后在当前特征池上逐个评价候选并加赢家。它直接处理目标有关的二元互补，但最后仍是一次加入一列，且信息分数并未条件化在完整当前集合或残差上。实现 helper 的符号方向为 conditional MI 减 marginal MI；不要与采用相反符号的 co-information 定义混写。报告的均值相对提升受单一任务影响，去掉 OpenML 586 后从 26.88% 降到 8.74%；LGBM 一组比较中 IIFE 3.02% 与 OpenFE 3.11% 并不支持“IIFE 总是最好”。[IIFE](https://arxiv.org/html/2409.04665v1)

**FEAT 是“模型反馈怎样指明改哪里”的重要经典证据。** 个体为多棵树构成的整组表示；ridge 读出拟合整组表示，可微边权用梯度优化；读出系数绝对值较小的树更可能接受结构变异。样本级误差用于 ε-lexicase 选父代，误差/复杂度 Pareto 用于生存选择。这比一个总分提供了更多定位，但论文没有实现“按内部节点权重大小选择变异节点”；那只是展望。额外去相关目标也未必改善表示相关性，原文存在反向结果。[FEAT](https://arxiv.org/abs/1807.00981)

**TopoFE 必须纠正为“程序合成丰富，最终选择仍贪心”。** 单个程序输出一列；五个家族岛内演化，停滞时跨岛读取优质程序合成，历史跨家族收益更新 donor 权重。§3.3.4 与 Algorithm 1 的最终 GreedySelect 按候选验证分数降序处理，再删除与已选列过度相关者。集合 argmax 是目标表达，不是实际精确搜索算法；低相关不证明预测互补，高相关也不必然无增量信息。[TopoFE](https://arxiv.org/html/2607.23286)

**SCOPE-FE v2 的“联合控制”不是联合组选择。** 它把候选供给拆成两个门：训练数据的 X-X 关联聚类限制二元输入对，少量 FeatureBoost 探测决定算子预算；后面直接使用 OpenFE。因此可以引用它说明反馈应更早进入候选生成，但不能引用来证明任意互补子集得到优化。正文以 v2 为准；v1 的谱嵌入/模糊聚类叙述不能混入。官方代码未确认；同名仓库方法不符，不能拿来补足原文细节。[SCOPE-FE v2](https://arxiv.org/html/2604.27025v2)

## 结果解释与负面证据

- **OpenFE 二阶扩展并非总有效。** 论文讨论第二阶特征在多数测试数据没有显著提升，68 个 CC18 任务中 19 个没有显著增益。扩展搜索空间本身不是效果保证。聚合统计是否允许使用测试上下文也影响结论；inductive 与 transductive 设定要分开比较。
- **FEAT 与 XGBoost 的质量比较有统计边界。** 100 个回归任务、CV 超参数选择与重复划分中，二者差异不显著不等于所有任务等效；其紧凑性优势来自表达节点数口径，不能转换成任意实现的运行时间优势。
- **SCOPE-FE 的速度口径有边界。** 报告把不同组件时间相加；8/10 接近基线使用事后描述性阈值，不是预注册等效性检验。两个任务存在更明显退步。
- **可用性综述不能直接复制其百分比。** How Usable 原文对 53 篇、27 个有代码系统、可运行数量的正文和表格存在冲突，并将 27/53 写成不一致百分比。可引用“发布代码不等于可运行”的观察，不能把矛盾数量包装为可靠统一统计。该工作 arXiv 元数据标题与 PDF 正文标题也有变化。[原 PDF](https://arxiv.org/pdf/2508.13932)
- **符号回归与增量特征工程任务不同。** DSR 的 Nguyen 表达式精确恢复、PySR 的整式误差/复杂度 Pareto、AI Feynman 的物理结构先验，不能直接转化为现有业务模型加几列的提升。DSO 当前仓库还包含后续方法，不应把全部新功能归给 2021 年 DSR。

## 31 条候选索引

“核心”表示主要方法与实验上下文有实质核查；其余深度请看 JSON。仓库列“未确认”并不证明不存在。

| ID | 年 | 论文 | 阅读深度 | 仓库 |
|---|---:|---|---|---|
| C01 | 2024 | [IIFE: Interaction Information Based Automated Feature Engineering](https://arxiv.org/abs/2409.04665) | 核心：全文算法、实验、附录；README与iife.py/helper.py | [repo](https://github.com/tomoverman/IIFE) |
| C02 | 2023 | [OpenFE: Automated Feature Generation with Expert-level Performance](https://proceedings.mlr.press/v202/zhang23ay.html) | 核心：论文§3/§5/附录片段；README+openfe/openfe.py | [repo](https://github.com/IIIS-Li-Group/OpenFE) |
| C03 | 2019 | [Learning concise representations for regression by evolving networks of trees](https://arxiv.org/abs/1807.00981) | 核心：全文§2–5/实验与README、variation.cc | [repo](https://github.com/cavalab/feat) |
| C04 | 2016 | [ExploreKit: Automatic Feature Generation and Selection](https://people.eecs.berkeley.edu/~dawnsong/papers/icdm-2016.pdf) | 核心：原文§III–V；README和根目录 | [repo](https://github.com/giladkatz/ExploreKit) |
| C05 | 2019 | [AutoCross: Automatic Feature Crossing for Tabular Data in Real-World Applications](https://doi.org/10.1145/3292500.3330679) | 核心：作者托管PDF§4/§5 | 未确认 |
| C06 | 2019 | [The autofeat Python Library for Automated Feature Engineering and Selection](https://arxiv.org/abs/1901.07329) | 核心：全文§2；README+featsel.py | [repo](https://github.com/cod3licious/autofeat) |
| C07 | 2018 | [Feature Engineering for Predictive Modeling using Reinforcement Learning](https://arxiv.org/abs/1709.07150) | 核心：arXiv HTML方法全文；AAAI metadata | 未确认 |
| C08 | 2012 | [Conditional Likelihood Maximisation: A Unifying Framework for Information Theoretic Feature Selection](https://www.jmlr.org/papers/v13/brown12a.html) | 核心：论文§2–4关键推导及统计估计讨论 | 未确认 |
| C09 | 2020 | [Feature Selection using Stochastic Gates](https://proceedings.mlr.press/v119/yamada20a.html) | 核心：论文§3/§6、README、layers.py | [repo](https://github.com/runopti/stg) |
| C10 | 2020 | [Understanding Global Feature Contributions With Additive Importance Measures](https://arxiv.org/abs/2004.00668) | 核心：原文定义/算法；README+imputers.py | [repo](https://github.com/iancovert/sage) |
| C11 | 2021 | [Deep symbolic regression: Recovering mathematical expressions from data via risk-seeking policy gradients](https://openreview.net/forum?id=m5Qsh0kBQG) | 核心：全文算法/实验；DSO README | [repo](https://github.com/dso-org/deep-symbolic-optimization) |
| C12 | 2026 | [Adaptive Graph-of-Islands Evolution for Automatic Feature Engineering with LLMs (TopoFE)](https://arxiv.org/abs/2607.23286) | 核心：HTML§2–3机制，实验配置；repo未核 | 未确认 |
| C13 | 2016 | [Cognito: Automated Feature Engineering for Supervised Learning](https://research.ibm.com/publications/cognito-automated-feature-engineering-for-supervised-learning) | 作者机构摘要核对 | 未确认 |
| C14 | 2017 | [Learning Feature Engineering for Classification](https://www.ijcai.org/proceedings/2017/352) | 会议页面与PDF引言/方法概要 | 未确认 |
| C15 | 2019 | [Neural Feature Search: A Neural Architecture for Automated Feature Engineering](https://www.microsoft.com/en-us/research/uploads/prod/2019/09/NFS_ICDM_2019_camera_ready.pdf) | 作者PDF§II/III/IV局部 | 未确认 |
| C16 | 2015 | [Deep Feature Synthesis: Towards Automating Data Science Endeavors](https://doi.org/10.1109/DSAA.2015.7344858) | 作者工程README已核；论文全文未取到 | [repo](https://github.com/alteryx/featuretools) |
| C17 | 2017 | [AutoLearn — Automated Feature Generation and Selection](https://cdn.iiit.ac.in/cdn/web2py.iiit.ac.in/research_centres/publications/download/inproceedings.pdf.88535e0ea3a74e72.4943444d2d20323031372e706466.pdf) | 作者PDF摘要与作者README/main.py | [repo](https://github.com/saket-maheshwary/AutoLearn) |
| C18 | 2020 | [SAFE: Scalable Automatic Feature Engineering Framework for Industrial Tasks](https://arxiv.org/abs/2003.02556) | HTML方法§3–4 | 未确认 |
| C19 | 2005 | [Feature selection based on mutual information: criteria of max-dependency, max-relevance, and min-redundancy](https://www.home.penglab.com/papersall/docpdf/2005_TPAMI_FeaSel.pdf) | 作者PDF/元数据；Brown推导对照 | 未确认 |
| C20 | 2004 | [Fast Binary Feature Selection with Conditional Mutual Information](https://www.jmlr.org/papers/v5/fleuret04a.html) | 论文原文摘要/§2公式核 | 未确认 |
| C21 | 1996 | [Toward Optimal Feature Selection](https://www.cs.cmu.edu/~dgovinda/pdf/ml96-featsel.pdf) | 原论文摘要与Brown链接理论 | 未确认 |
| C22 | 2019 | [Concrete Autoencoders: Differentiable Feature Selection and Reconstruction](https://proceedings.mlr.press/v97/balin19a.html) | 会议原始摘要 | 未确认 |
| C23 | 2018 | [Learning Sparse Neural Networks through L0 Regularization](https://arxiv.org/abs/1712.01312) | 原摘要与STG比较背景 | 未确认 |
| C24 | 2020 | [The Shapley Taylor Interaction Index](https://proceedings.mlr.press/v119/sundararajan20a.html) | 原摘要/理论定位 | 未确认 |
| C25 | 2023 | [Interpretable Machine Learning for Science with PySR and SymbolicRegression.jl](https://arxiv.org/abs/2305.01582) | HTML§2方法概要；README | [repo](https://github.com/astroautomata/PySR) |
| C26 | 2020 | [AI Feynman 2.0: Pareto-optimal symbolic regression exploiting graph modularity](https://arxiv.org/abs/2006.10782) | HTML§2方法概览/官方摘要 | 未确认 |
| C27 | 2025 | [How Usable is Automated Feature Engineering for Tabular Data?](https://arxiv.org/abs/2508.13932) | 原PDF全文可访问，§4/Table1矛盾核对 | 未确认 |
| C28 | 2024 | [A Report on Semantic-Guided RL for Interpretable Feature Engineering](https://arxiv.org/abs/2410.02519) | HTML方法概要 | 未确认 |
| C29 | 2025 | [Collaborative Multi-Agent Reinforcement Learning for Automated Feature Transformation with Graph-Driven Path Optimization](https://arxiv.org/abs/2504.17355) | HTML§III方法概要 | 未确认 |
| C30 | 2019 | [Map-Elites Algorithm for Features Selection Problem](https://ceur-ws.org/Vol-2369/short10.pdf) | 5页原文机制概览 | 未确认 |
| C31 | 2026 | [SCOPE-FE: Structured Control of Operator and Pairwise Exploration for Feature Engineering via Quality-Aware Candidate-Space Reduction](https://arxiv.org/html/2604.27025v2) | 核心方法补充：v2 §3–5、表1–2、Appendix B；核查同名候选仓库README与实现后不认定为作者仓库 | 未确认 |

## 每篇核心证据定位

以下与 JSON 对应，保留评估对象、来源位置和不支持的结论。

### C01 IIFE: Interaction Information Based Automated Feature Engineering

- **搜索单位**：原始/已构造特征对→一个新公式→逐步扩充集合。
- **反馈**：统计交互信息决定提议对象；目标模型CV决定具体算子与新列；patience允许短期CV不改善。
- **评估设定**：8公开数据×3模型；5次80/20划分×5个搜索种子=25次；分类F1-micro，回归1-RAE；原则上前后各100次随机搜索、5-fold调参，但部分大数据的OpenFE RF/LGBM不做后调参。II用最多3000样本kNN混合变量估计，K=3，P通常20、部分40。
- **结果边界**：Table I平均秩2.50；整体相对基线26.88%受OpenML586极端值影响，去掉后8.74%；LGBM均值提升IIFE3.02%、OpenFE3.11%。这些是论文特定设置，不能直接迁移到内部业务。
- **原文定位**：§III Algorithm 1–3，尤其Algo3 lines11/16逐列CV；§IV-A1与TableI；§IV-C2 transductive对照；§VI-B参数/估计器/基线预算。
- **仓库核查**：匿名repo README指向作者public repo；helper.py实际 cmi(cola,colb,coly,k,data)-cmi(cola,colb,[],k,data)。README给K/patience/n_int_inf/int_inf_subset，CMI代码来自omesner/knncmi。 读取：README.md、src/iife.py、src/helper.py；未运行。
- **不支持**：全局最优组合；任意高阶协同都有保证；相对提升就是accuracy百分点。

### C02 OpenFE: Automated Feature Generation with Expert-level Performance

- **搜索单位**：stage1单列候选；stage2联合输入归因；最后仍top-k列。
- **反馈**：stage1默认残差/增量拟合的验证表现；stage2默认LightGBM gain，可选permutation。
- **评估设定**：10公共集同一train/validation/test分割，LightGBM；base特征调参；各方法相同新列数、一阶特征；10次重复。Table3/§5.3。
- **结果边界**：California RMSE 0.432±.004→.421±.002，Diabetes AUC .731±.001→.888±.002（特定transductive处理须标注）。附加68个CC18任务有19个未显著改善；二阶特征在多数基准未带来收益。
- **原文定位**：Alg2–4；§3.2.2 p4；Table3；§5.5/§5 Discussion p7；code openfe.py:142/154/155/241/504/599。
- **仓库核查**：默认 stage1_metric='predictive'、stage2_metric='gain_importance'；stage2把原始列与候选共同训练，importance_type='gain'；is_stage1=False可跳过第一阶段。 读取：README.md、openfe/openfe.py；未运行。
- **不支持**：全流程是单变量检验；gain为零则无互补价值；paper里的集合argmax证明算法全局最优。

### C03 Learning concise representations for regression by evolving networks of trees

- **搜索单位**：整组树表示；可插删维度、交换树、变异子树。
- **反馈**：整个表示的损失、每个样本误差、线性系数、可微边权梯度，各自控制不同部分。
- **评估设定**：100个OpenML真实/模拟回归任务；10-fold CV、5次随机shuffle；FEAT最多200代或60min、validation early stop；最终用最优超参的CV R²排序。
- **结果边界**：FEAT与XGBoost表现差异不显著(p=1.0)；FEAT节点数通常小2–4数量级；额外去相关目标反而生成更相关表示。不可把其CV报告包装成独立未触碰测试集结论。
- **原文定位**：§2.1.1 representation；§2.1.2 Eq3 Feedback：树内节点均匀变异，节点权重引导仅建议扩展；§2.1.3 lexicase/NSGA-II；§4/§5实验、负面去相关。
- **仓库核查**：README每个individual为表示，Pareto搜索；variation.cc有weighted mutation与crossover实现。当前主分支≠2019冻结版本。 读取：README.md、src/vary/variation.cc；未运行。
- **不支持**：节点梯度直接决定每个节点结构变异；已证明任意下游模型迁移；发现全局最优表示。

### C04 ExploreKit: Automatic Feature Generation and Selection

- **搜索单位**：当前集合Fi∪{候选f}，每轮单列。
- **反馈**：跨数据学习的候选优先级 + 当前任务wrapper增量表现。
- **评估设定**：25 OpenML分类集，66/34 train/test且保留类比例；Weka3.7默认C4.5/SVM/RF；内层k-fold选列。
- **结果边界**：Table III SVM ML Full平均相对错误减少17.4%、中位14.7%，但Heart为-14.3%；论文摘要约20% overall应带条件。
- **原文定位**：§IV-C p4逐列CV/停止规则；§V-A 66/34 split；TableIII正负结果。
- **仓库核查**：官方README只有联系信息，没有完整安装使用流程；Java/Maven工程可见。 读取：README.md、研究主报告 tree/pom.xml presence；未运行。
- **不支持**：完全无模型评价；20%是accuracy绝对百分点；保证保留互补组合。

### C05 AutoCross: Automatic Feature Crossing for Tabular Data in Real-World Applications

- **搜索单位**：特征集节点，但相邻节点只加一列cross；实际论文展示/算法每层走最佳一个孩子。
- **反馈**：候选集合的验证表现；计算上固定已有field参数主要估计新cross的价值。
- **评估设定**：§5将特征/模型在训练与验证（需时训练的20%）学习，测试报告AUC；benchmark与企业任务。
- **结果边界**：本次研究不转录表格汇总收益，以避免未完整核查数据集/基线对应。
- **原文定位**：作者PDF https://en.4paradigm.com/upload/file/20210427/20210427223536_85225.pdf；§4.2 p4 Alg1；§4.3；§5.1。
- **仓库核查**：本轮未确认作者开源repo；OpenFE_reproduce是复现，不能标为AutoCross作者代码。 读取：无已确认代码；未运行。
- **不支持**：已找到全局最优集合；beam必然跨越零增益中间步骤。

### C06 The autofeat Python Library for Automated Feature Engineering and Selection

- **搜索单位**：表达式候选池→集合选择；先扩展后缩减。
- **反馈**：线性模型系数/稳健选择反馈；候选构造主要规则驱动。
- **评估设定**：本次研究读方法与实现，不引用未逐表核实的实验增益。
- **结果边界**：§2.1例子：3原始变量扩展到约20→750→4000候选，说明组合爆炸；非算法普适复杂度常数。
- **原文定位**：§1对提前删除中间特征的讨论；§2.1/2.2；src/autofeat/featsel.py。
- **仓库核查**：已检查_add_noise_features、_noise_filtering、多次子采样/相关过滤；主分支为main。 读取：README.md、src/autofeat/featsel.py；未运行。
- **不支持**：穷举了无限表达式；所有互补组必然幸存。

### C07 Feature Engineering for Predictive Modeling using Reinforcement Learning

- **搜索单位**：整份表示节点与变换路径。
- **反馈**：即时奖励是图中最佳CV性能的新增幅度；状态含历史表现和剩余预算；近似Q学习。
- **评估设定**：原文以预算化图搜索比较不同RL/手工策略；本次研究未精核每组结果数字。
- **结果边界**：§Transformation Graph明确20变换、height5约320万节点，无法穷举，也无已知可用部分试验确定最优的性质。
- **原文定位**：Transformation Graph/Graph Exploration under a Budget Constraint；Traversal Policy Learning Eq immediate reward。
- **仓库核查**：未确认作者可直接运行的公开repo。 读取：无已确认代码；未运行。
- **不支持**：强化学习本身保证全局最优；有限budget可穷尽组合。

### C08 Conditional Likelihood Maximisation: A Unifying Framework for Information Theoretic Feature Selection

- **搜索单位**：完整目标是集合；实际常采用逐步加入候选的低阶统计。
- **反馈**：统计依赖反馈，不依赖某一具体训练后模型的重要性。
- **评估设定**：理论推导依赖filter近似/估计一致性；论文含实证比较，本次研究不转录总排名。
- **结果边界**：无普适收益数字。
- **原文定位**：§2.2 JMI定义；§3 Definition1/Theorems与CMI；§3.3高维估计；§4条件独立近似Eq15。
- **仓库核查**：本次未核作者软件，不关联未经核实第三方repo。 读取：无已确认代码；未运行。
- **不支持**：mRMR/JMI/CMIM解决任意高阶XOR；统计独立等价于因果无关。

### C09 Feature Selection using Stochastic Gates

- **搜索单位**：整个随机子集/门向量的连续松弛。
- **反馈**：端到端损失梯度；非线性共同使用已打开的特征。
- **评估设定**：合成MADELON与修改Friedman，5信息+495干扰列，600样本=450 train/50 val/100 test，重复20次；validation调稀疏超参。
- **结果边界**：Fig2作者报告F1优于所比基线；XOR额外实验在supplement，本次研究仅确认主文指向，未核该附录数值。
- **原文定位**：§3 Eq4–5和3.1；§6.1/Fig2；python/stg/layers.py FeatureSelector。
- **仓库核查**：代码 z=mu+sigma*noise，hard_sigmoid clamp(x+0.5,0,1)，训练时噪声、推理时关闭噪声；Gaussian CDF正则。 读取：README.md、python/stg/layers.py；未运行。
- **不支持**：纯统计排名等价方法；任意互补组都被选中。

### C10 Understanding Global Feature Contributions With Additive Importance Measures

- **搜索单位**：解释时采样联盟；不是特征生成/子集优化器。
- **反馈**：跨子集上下文的模型性能贡献；输出仍每列一个加性值。
- **评估设定**：本次研究读机制与实现，不引用未复核实验收益。
- **结果边界**：无全局搜索效率保证。
- **原文定位**：§2 predictive power；§3 SAGE；README Usage；sage/imputers.py MarginalImputer。
- **仓库核查**：默认示例MarginalImputer+PermutationEstimator；替换未观测列为背景样本并平均预测；支持group imputer入口可见但未深入。 读取：README.md、sage/imputers.py；未运行。
- **不支持**：高SAGE列top-k即最优集合；Shapley值就是交互值；默认边际插补等价条件插补。

### C11 Deep symbolic regression: Recovering mathematical expressions from data via risk-seeking policy gradients

- **搜索单位**：完整表达式/程序。
- **反馈**：整棵表达式拟合分数驱动生成分布；不需每个子树单独有预测价值。
- **评估设定**：Nguyen12表达式；100独立seed；DSR/PQT/VPG/GP各最多200万表达式评估；两任务调参后固定；recovery为符号等价。
- **结果边界**：Table1 DSR在Nguyen12 recovery=0%；不能用若干成功任务宣称通用表达式恢复。
- **原文定位**：§3 risk-seeking Eq1/Prop1/Alg1；§4/Table1；DSO README publications列表。
- **仓库核查**：仓库明确支持symbolic regression/control并列多篇后续论文；PyTorch重构另仓库。 读取：README.md；未运行。
- **不支持**：可恢复所有表达式；DSO当前最高成绩等于原始DSR成绩。

### C12 Adaptive Graph-of-Islands Evolution for Automatic Feature Engineering with LLMs (TopoFE)

- **搜索单位**：§2程序p:X→R为单列；跨家族算子复合；最终降序逐列+相关阈值选择。
- **反馈**：CV表现、接受/拒绝历史、跨家族合成收益、输出相关性/有效秩等诊断。
- **评估设定**：29数据=19分类+10回归；80/20 train/test，5 runs与不同split；训练内CV搜索。
- **结果边界**：本次研究不复述主效果排名；只核机制。
- **原文定位**：§2.2 Eq3–6；§3.1.3 Eq7；§3.2 archive树编辑距离；§3.3 Eq11–14；§3.3.4 Eq15与末段；Algorithm1 return GreedySelect。
- **仓库核查**：本次研究未确认官方repo与最终集合选择实现。 读取：无已确认代码；未运行。
- **不支持**：保证找到全局最优子集；每个岛代表真正不同信息；低相关性证明协同。


## 查询日志、来源与排除项

检索日志是本次研究的分组摘要，不伪造逐条时间戳。原始工具检索与读取结果保存在 ../sources/complementary/；这些是局部文本和代码证据，不代表下载了每篇完整 PDF。

| 路径 | 动作/目标 | 结果与边界 |
|---|---|---|
| paper-search 脚本 | arXiv、DBLP、OpenAlex、OpenReview、Semantic Scholar、Crossref 多源检索 | Python3 运行后依赖缺失/网络受限；六源无结果是访问失败，不能解释为无论文；原始错误见 search_api.log |
| 经典 AutoFE 题名检索 | OpenFE、ExploreKit、Cognito、AutoCross、autofeat、LFE、NFS、RL、AutoLearn、DFS、SAFE | 以 PMLR、AAAI/arXiv、IJCAI、JMLR、作者机构 PDF 为准 |
| 信息论与归因 | IIFE、mRMR/JMI/CMIM、Markov blanket、SAGE、Shapley–Taylor | 结合原文定义检查二元互补、条件化背景和符号方向 |
| 可微与整式搜索 | STG、Concrete、L0、FEAT、DSR、PySR、AI Feynman | 区分选输入、学表示、搜索整式；避免性能跨任务嫁接 |
| 新增和负面证据 | TopoFE、SMART、TCTO、How Usable、SCOPE-FE v2 | 新文接收状态未核时保留 arXiv 标签；版本、时间和数量冲突单列 |
| GitHub 连接器 | README、目录、具体实现 | 11 个关联仓库已读；代码可读不等于成功复现；同名 SCOPE-FE 单独排除官方归属 |

主要证据文件：openfe_code.txt / openfe_results.txt、iife_details.txt / iife_code.txt / featmore_2.txt、feat.txt / finalverify_0.txt、explorekit_detail.txt、autocross_detail.txt、brown_theory.txt / brown_more.txt、stg_code.txt / stg_results.txt、sage_imputers.txt、dsr_results.txt、topofe_end.txt、scope_full.txt / scope_more_0.txt / scope_results.txt、scope_repo_fs.txt、usability_pdf.txt / usability_more.txt。

排除或降级记录：

1. **没有绑定作者身份的仓库不作为官方实现**：例如 sethGu/SCOPE-FE；其 LLM 模板扩展、单变量筛选、语义 kNN 图和 beam 剪枝，与 v2 的硬聚类/算子探测不同。
2. **DFS 原论文全文获取未成功**：DOI 和 Featuretools README 可核，论文详细方法/实验结论不冒充全文阅读。
3. **JMI 原论文作为理论来源，未扩张为第 32 个独立核心条目**：主要通过 Brown 统一框架对照。
4. **一般 MAP-Elites 不直接当作特征工程实证**：仅保留 2019 年真正做特征子集 MAP-Elites 的小型先例；未发现足够证据据此声称大规模 AutoFE 优势。
5. **当前 DSO 主仓库与 2021 年论文分开**：后续 GP/其他符号任务功能不能反向归给 DSR。
6. **AutoMAN、SymboLLM-FE、CoFEH、RelAgent 由主线程覆盖**；TopoFE 模型迁移由 cross_model 分支覆盖，避免重复扩检。
7. **不把宣传性“优于所有方法”、作者单点排名或不可比实验当统一结论**；所有精确结果保留其数据、模型、切分、预算和指标边界。

本次研究的技术判断是：较有效的反馈往往不是更长的描述，而是能对应到可执行搜索决策——修改哪棵树、优先哪个算子或输入对、保留哪个部分集合，以及是否值得为某个组合支付完整模型评估成本。没有这里核查的方法在无附加假设时保证找到全局最优特征集合。

