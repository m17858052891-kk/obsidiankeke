> [!info] 分题阶段记录
> 此文件保留分题阅读时的版本与措辞。最终版本、合并结论和统计以专题主报告及证据台账为准。

# 跨下游模型迁移、评价器偏置与可靠反馈：证据核查

研究截止：2026-11-06。任务：为“模型反馈怎样更有效指导特征发现”提供第三条主线；只读论文与公开代码，没有运行训练或复现实验。已使用 paper-search、paper-structure-deep-dive。结构化记录见 `cross_model.json`；原文与失败日志见 `cross_model_sources/`。

## 一、可直接进入总报告的结论

**已有直接证据表明：用一个便宜模型搜索出的显式特征，可以帮助另一个模型；但收益不是模型无关的属性。** OCTree、LLM-FE 有“先用 XGBoost 搜索，再把已生成特征交给另一 learner”的实验。AutoMAN 提供反向的 MLP→XGBoost 线索。它们也同时暴露了条件：不同 learner 的收益大小不同，个别迁移会恶化，自身搜索可能明显优于代理迁移。[OCTree §4.2/Table 6](https://arxiv.org/html/2406.08527v1)、[LLM-FE Appendix D.3/Table 13](https://arxiv.org/html/2503.14434v3)、[AutoMAN §4.3/Figure 3](https://arxiv.org/html/2406.04153v1)。

因此较有依据的路线不是“找到完全通用的最好特征”，而是**维护跨 learner 的增益向量，分出共享核心与模型专属补充；把代理搜索效率、目标模型收益、最差模型损失分别衡量**。这是本文的技术综合，不是已由某一篇论文完整验证的算法。

### 迁移证据必须分开

| 类型 | 严格问题 | 本轮代表 | 不能推出什么 |
|---|---|---|---|
| 显式特征跨 learner | 搜索时的模型 A 与最终模型 B 不同；程序/选择冻结后给 B | OCTree、LLM-FE、AutoMAN；TopoFE 有冻结协议但基线不完整 | 不保证所有 B 都改善 |
| 算法适用于多个 learner | 分别换模型重新搜索/调参都有效 | LFE 的 RF/LR 分别训练；许多 AutoFE 主表 | 不等于同一特征集迁移 |
| 多评价器优化 | 搜索/元标签直接观察多个模型 | GELFE 的四模型反馈 | “至少一个模型变好”不等于“所有模型变好” |
| 跨数据集元学习 | 历史数据经验用于新表选择变换 | LFE、GELFE、MACFE | 不等于跨 learner；依然可能学习某个评价器的偏好 |
| 表征/参数跨表迁移 | 复用 encoder、Transformer 或预训练权重 | STUNT、TransTab、XTab、CARTE、TabPFN | 不等于显式特征可直接用于任意 learner |
| 跨环境不变性 | 训练/测试分布或干预变了仍可靠 | ICP、IRM、anchor regression | 环境不变不等于模型不变，也不自动保证因果发现 |
| 选择稳定性 | 重采样后选择是否稳定 | Stability selection | 高频出现不代表因果、不代表各模型都有增益 |

## 二、九项重点核查

### 1. LLM-FE：目前最清楚的“迁移有益，但仍有模型专属收益”对照

论文 2025 首发，所读 v3 对应 TMLR 2026。D.3 用 XGBoost 产生特征，再用于 MLP/TabPFN；表同时保留原始特征 Base 与目标模型自身参与搜索的 LLM-FE。分类为 accuracy，回归为 normalized RMSE，均为五个随机 split 的均值±标准差。

| 下游模型 | Base 分类↑ / 回归↓ | XGB 搜索特征迁移 | 目标模型自身搜索 |
|---|---|---|---|
| MLP | .745±.034 / .871±.027 | .763±.030 / .848±.017 | .791±.029 / .631±.043 |
| TabPFN | .852±.028 / .289±.016 | .861±.017 / .287±.015 | .863±.018 / .286±.015 |

**支持：**便宜代理可以筛出部分共享有用结构。**不支持：**与自身搜索等价；所有数据集都改善；此表单独构成逐目标模型统计显著性证明。MLP 的回归差距尤其说明适配目标 learner 仍有价值。[原文 D.3/Table 13](https://arxiv.org/html/2503.14434v3#A4.SS3)。

仓库核到 `optimization_utils.py` 的 `_load_data` 与 `add_data_features`，可读取已保存函数并应用 train/test；`process` 支持复用 encoder/scaler。另 `filter_features` 把 train/test 拼接后去重、删 NaN 列，是利用测试协变量的处理，需要与严格 inductive 协议区分；本轮没有确认它是否进入表 13 的最终运行。[代码](https://github.com/nikhilsab/LLMFE/blob/main/optimization_utils.py)。

### 2. OCTree：真正迁移，也有明确失败格

规则搜索结合验证分数和转换为文本的决策树。Table 6 明确先用 XGBoost 优化规则，再给 MLP/HyperFast。四个数据集报告 test error 与三个随机 seed 的标准差。Clinical 的 MLP 从 **41.77±1.2 到 42.32±2.3**，标记 N/I，不能写成“普遍提升”。electricity 则 MLP 从 **15.64±.3 到 15.03±.3**，HyperFast 从 **15.37±.4 到 14.88±.2**。[§4.2/Table 6](https://arxiv.org/html/2406.08527v1)。

论文表中 Disease/HyperFast 的误差 28.57→27.62 与括号写的 5.8% 不能直接算出一致的相对降幅，因此本报告不重复该百分比。其他案例也不把误差条重叠直接判为显著或不显著。

仓库 `ours/train_xg.py` 能核到 validation accuracy 驱动排序、`get_cart`/`tree_to_code`、把 rule/tree/score 传入 prompt 以及保存增广数组；当前 `ours/` 只列出 XGB 搜索实现，未发现 Table 6 专门迁移入口。这是复现材料缺口，不是否定论文实验。[代码](https://github.com/jaehyun513/OCTree/blob/main/ours/train_xg.py)。

### 3. AutoMAN：可微生成的特征能被另一个 learner 使用，偏置仍保留

《Learned Feature Importance Scores for Automated Feature Engineering》(2024) 用局部 mask 选择变换输入、全局 mask 选择变换输出，通过 MLP 下游目标联合学习。§4.1/Table 3/Figure 3 又在生成特征上训练 MLP、XGBoost；Figure 3 对 Mice/Isolet/MNIST/Fraud 比较原始与生成表示。正文明确承认：MLP 收益更大，因为特征空间按 MLP 优化。它支持“可微代理可做显式 FE，再交给非可微模型”，不支持“代理偏置已经被消除”。没有核到官方实现。[原文 §4.3/Figure 3](https://arxiv.org/html/2406.04153v1)。

### 4. TopoFE：冻结协议强，迁移增益证明弱

2026 预印本 §5.3 明确固定 XGBoost 演化出的程序，向 CatBoost、MLP、TabPFN 迁移时不重新生成、选择或修改。Table 4 分类分别为 XGB **.837**、CatBoost **.849**、MLP **.816**、TabPFN **.873**；回归 RMSE 为 **2.679/2.624/2.993/2.591**。

关键缺口：该表没有每个目标 learner 的原始特征 baseline。TabPFN 高于 XGB 可能来自模型能力，不能据此归因于特征迁移；“super-transfer”应仅当作者表述。作者把 MLP 落后归因于没有归一化，但未在该节提供归一化对照。因此可写“同一特征集可被多模型消费”，不能写“证明稳定、任务无关的跨模型增益”。没有发现官方代码链接。[§5.3/Table 4](https://arxiv.org/html/2607.23286v1#S5.SS3)。

### 5. GELFE：最贴近多评价器特征推荐，但目标是 OR，不是通用

《Automated Feature Engineering for Automated Machine Learning》(KBS 2025) 扩展 LFE：以特征/标签分布等 meta-features 预测每个算子的价值。元训练用 **LR、RF、Linear SVM、KNN** 的五折 balanced accuracy；只要至少一个模型超过改善阈值，元标签就为正。§3.1 解释这是给 AutoML 留模型选择余地。因而“多模型标签”本质是收益并集，可能把对其他模型有害的算子也保留。§4/Table 5 指出 electricity 等数据上 AutoFE+RF 低于 RF；与 AutoML 的收益不能外推到固定 RF。[作者 PDF §3.1、§4/Table 5](https://personal.eur.nl/frasincar/papers/KBS2025a/kbs2025a.pdf)。

官方 `DataSetTrainV2.py` 核实四模型与 `NImprov >= 1`。版本差异：正文阈值为 `min(.01,.05*(1-baseline))`；所查代码只用 `.05*(1-baseline)`，且二元生成循环处于大块注释中。下载即运行并不能视为复现论文全部结果。[代码](https://github.com/Casper-de-Winter/GELFE/blob/master/DataSetTrainV2.py)。

### 6. LFE：跨数据集经验迁移，不是已证实的跨 learner 特征迁移

IJCAI 2017 的 LFE 把特征按类的分布压成 Quantile Sketch Array，再用每个变换对应的 MLP 预测是否有益；在新表上避免逐候选训练评价器。论文为 RF 与 LR **分别训练**经验预测器。它支持把历史反馈变成便宜的 proposal/value prior；不能因为两类模型都被报告，就称“同一组特征在模型之间迁移”。原文 89% 的分母是“存在任何 FE 改善的那些数据集”，不是全部任务或保证成功率。本轮核到正文索引片段与官方发表页；PDF 直接下载失败，未找到官方仓库。[论文](https://www.ijcai.org/Proceedings/2017/0352.pdf)。

### 7. TabPrep：共享结构盲点提供通用候选族，最后仍需按模型/数据挑选

2026 预印本用算术组合、类别/数值的组条件效应、伪类别数值模式设计生成器。合成分析揭示各模型对结构的响应不同。主实验覆盖 **51 个 TabArena 数据集**，对 linear/LightGBM/TabM/TabPFN-2.5 的调参空间增加 FE 变体；每模型 **200 个配置的 25%** 带 TabPrep。其 §4.1 明言，为减少单数据集性能退化风险，需要 HPO。[原文 §3、§4.1、Appendix D](https://arxiv.org/html/2606.02384v1)。

因此结果支持“变换族可广泛复用、模型与 FE 联合选择有效”，不等于冻结一个最优矩阵给全部 learner。仓库目前是 AutoGluon 生成逻辑的 sklearn wrapper，`fit_transform(X,y)` 与 `transform(X)` 分开； README 说明完整 TabArena workflow 示例尚待补充。[仓库](https://github.com/atschalz/tabprep)、[wrapper](https://github.com/atschalz/tabprep/blob/main/tabprep.py)。

### 8. Do Tabular Foundation Models Still Need Feature Engineering?：模型更新会改变反馈价值

2026 预印本研究 **13 小数据集、12 版本、26 个预设干预、30 paired splits**。固定 estimator 默认配置与其 native preprocessing；最优观察增益是对干预取最大值的 oracle 描述，不是可部署的验证集选择策略。TabPFN v1→v3 分类的 across-dataset median best gain 从 **1.21→.25 macro-F1 pp**，回归 v2→v3 从 **2.06%→.19% relative RMSE reduction**；TabICL 分类 v1→v2 为 **.73→.10 pp**。BH 调整后 q=.0234，Holm p=.0502，后者略过 .05。[原文 Experiments/Results/Table 5](https://arxiv.org/html/2609.13202v1)。

与 TabPrep 的“矛盾”来自 estimand 不同：旧版模型、广数据与调参集成空间的最佳可选 pipeline，对比小数据、更新版模型、固定默认配置的预设变换效应。不能据此宣布 FE 已无用；可以据此要求“重新量化目标 learner 当前剩余收益”。它的 NNRC 外部样本实验使用测试协变量做距离筛选，且无独立 validation 选择参数，应标为 transductive feasibility。未发现官方 repo。[Problem Setup、Discussion、Algorithm 1](https://arxiv.org/html/2609.13202v1)。

### 9. MACFE：模型无关的统计先验值得借鉴，实证需降权

2022 论文用 feature histogram + dataset meta-features 建立变换推荐矩阵，元经验按 **MIC 改善**存储，经因果图估计先选原始特征，再按相似经验变换。八个分类器是末端评估，不是八模型共同反馈。统计相关性更强不保证对每个 learner 有增益，且 observational DAG 的“causal”含义依赖假设。[§4–5](https://arxiv.org/pdf/2207.04010)。

官方 `experiments.py` 先在全表用标签训练 DAGClassifier 选择与变换，再 `evaluations.py` 内五折 `cross_validate`；所查版本有监督预处理没有嵌套在 fold 内的泄漏风险。`model_names` 首两项 KNN/LR 与实际 classifier 首两项 LR/KNN 反序。只能说明公开代码有这些问题，不能断言论文私有实验运行完全一致，因此本报告不复述其摘要相对提升数字。[构建入口](https://github.com/Ivanrs297/MACFE/blob/master/code/experiments.py)、[评价入口](https://github.com/Ivanrs297/MACFE/blob/master/code/evaluations.py)。

## 三、从证据推导的技术路线（建议，不冒充已有实证）

### 1. 将“有用”改成相对于已有集合、目标模型与使用条件的增益

确定当前特征集 S、候选 g 和 learner m 后，定义同样数据划分、同样训练预算下的条件增益：

\[
\Delta_m(g\mid S)=\operatorname{Score}_m(S\cup\{g\})-\operatorname{Score}_m(S).
\]

所有分数先统一为越大越好；最好保留原始量纲与误差/成本，别只留归一化总分。搜索反馈存成 \(\boldsymbol\Delta(g\mid S)=(\Delta_{m_1},\ldots,\Delta_{m_K})\)，另存各 fold、时间/业务切片、失败原因、复杂度与生成成本。

这里的条件 S 很重要：一条特征对 RF 的残差互补，却可能已经被 MLP 的交互能力覆盖；更换已有集合后原来的增益不能直接搬用。确定性 g(X) 不增加 X 对 Y 的信息，只改变模型可容易表示/优化的函数，因此无需把“共同提升”解释为发现了新信息或因果机制。

### 2. 区分三种真正不同的优化目标

| 产品目标 | 合适的反馈聚合 | 与证据的关系 |
|---|---|---|
| 最后可以挑任一模型 | `max_m Δ_m` 或“至少一个过阈值” | GELFE 的 OR 标签接近此目标 |
| 固定多模型共同使用 | 平均增益 + 最差模型不退化约束，或增益分布的下分位 | 本报告推导；不能用 GELFE OR 证明 |
| 大多数模型共享、少数有差异 | 共享核心 S_common + 各模型补充 S_m | 与 OCTree 失败格、LLM-FE 专属收益差距、AutoMAN 偏置相容 |

严格要求所有模型都显著变好可能使候选集为空，也会拒绝只帮助弱模型而对强模型中性的好特征。更实际的共享目标是：多数模型有稳定收益，其他模型的退化不超过可接受界限；保留 Pareto 候选，让部署方知道取舍。此处“界限”“权重”属于业务选择，不是论文普适常数。

### 3. 便宜评价器是分配预算的工具，不是最终真值

用模型族足够不同的小型委员会覆盖线性可分性、轴对齐切分、平滑交互、基础模型先验；全部用同族不同 seed，主要减少方差，未必降低归纳偏置。历史 LFE/GELFE 式元模型可以预测哪个“算子×输入集合×learner”值得调用昂贵评价器。低保真模型先筛选、目标模型复核；若二者候选排序经常不一致，应降低代理否决权。

应同时保留“不提升”的解释：强模型已经吸收该结构、预处理失配、候选冗余、真实无信号、样本噪声、计算预算不足，不能都压缩成“错误变换”。TopoFE 对 MLP 的归一化猜测正说明，评价器测到的可能是 feature×preprocessing×optimizer 的共同效果。

### 4. 可移植的是程序和数据契约，而不只是当前数据矩阵

记录列语义、单位、缺失/零分母行为、group key、时间可用性、未知类别规则与训练时拟合状态。程序/算子与选择策略冻结后，所有统计量仍必须只在各折训练部分拟合；不能因为“冻结特征”就把全数据均值或 target encoding 固定带进 fold。允许模型专属的标准化/编码 adapter，但要事先声明，避免把 adapter 改善误写为 feature transfer。

### 5. 真正需要的证据是迁移矩阵，而不是多模型主表

若未来验证：矩阵第 i 行是只用 learner i 搜索得到并冻结的特征，第 j 列是 learner j 对同一特征的 paired gain；每格都与 j 自己的 raw baseline 比，并分开记录目标模型重搜。还应保留从未参与搜索/选特征的 learner 作为模型维度的审计对象。对角线强而非对角线弱揭示代理特化；非对角线正才说明可迁移增益。本文没有执行这些实验。

## 四、可靠反馈：防止把验证噪声当知识积累

[Cawley & Talbot 2010](https://www.jmlr.org/papers/volume11/cawley10a/cawley10a.pdf) 指出有限样本上的模型选择准则本身会被过拟合；即使每次都用了 CV，反复挑最高分也没有消除选择偏差。对自动特征发现而言，生成器读到的每一个验证分数、错误样本、解释图，都可能让后续候选适应同一批样本。反馈更丰富，并不自动更可靠。

建议把开发反馈与最终证据分开：内层构建/拟合，搜索集给详细诊断，另有不进入搜索记忆的审计集；所有监督预处理都在对应训练 fold 内 fit。若有时间/用户/主体相关性，要按真实部署单元分组或按时间划分。不能把训练残差当泛化残差，也不能用目标泄漏构造的“高解释性特征”证明发现了结构。

[Reusable holdout](https://pubmed.ncbi.nlm.nih.gov/26250683/) 用控制信息泄露的方法应对自适应查询；[Ladder](https://proceedings.mlr.press/v37/blum15.html) 只在足够改善时更新可见成绩，减少连续排行榜反馈暴露。它们可启发“分层、限精度、门控反馈”，但不能未经建模就宣称任意 LLM agent 的逐样本解释流继承其理论保证。[Stability selection](https://stat.ethz.ch/Manuscripts/buhlmann/stabilityselection.pdf) 的重采样频率可作为补充稳健性信号；相关替代变量可能轮换，宜看变换族/等价组稳定性，而非强迫单列每次都入选。

## 五、候选全集与边界（23 项）

`深核` 指读到方法与对应实验/限制；`定向核` 指只核相关段落；`邻近`不作为显式跨 learner 直接证据。

| ID | 论文 / 年份 | 层级 | 主要角色 |
|---|---|---|---|
| CM01 | [Learning Feature Engineering for Classification](https://www.ijcai.org/Proceedings/2017/0352.pdf), 2017 | 定向核 | 历史反馈→变换推荐；RF/LR分别训练 |
| CM02 | [GELFE / Automated Feature Engineering for Automated Machine Learning](https://personal.eur.nl/frasincar/papers/KBS2025a/kbs2025a.pdf), 2025 | 深核+代码 | 四评价器OR标签；固定RF负例 |
| CM03 | [OCTree](https://arxiv.org/abs/2406.08527), 2024 | 深核+代码 | XGB→MLP/HyperFast迁移与失败格 |
| CM04 | [LLM-FE](https://arxiv.org/abs/2503.14434), 2025/2026 | 深核+代码 | Base/代理迁移/自身搜索三方对照 |
| CM05 | [AutoMAN](https://arxiv.org/abs/2406.04153), 2024 | 深核 | MLP学特征→XGB；代理偏置残留 |
| CM06 | [TopoFE](https://arxiv.org/abs/2607.23286), 2026 | 深核 | 严格冻结；目标模型raw基线不足 |
| CM07 | [TabPrep](https://arxiv.org/abs/2606.02384), 2026 | 深核+代码 | 跨模型结构盲点；联合HPO而非同集迁移 |
| CM08 | [Do TFMs Still Need FE?](https://arxiv.org/abs/2609.13202), 2026 | 深核 | 模型升级后通用FE剩余收益收缩 |
| CM09 | [MACFE](https://arxiv.org/abs/2207.04010), 2022 | 深核+代码 | MIC经验、因果预选；公开代码有效性风险 |
| CM10 | [STUNT](https://arxiv.org/abs/2303.00918), 2023 | 邻近+代码 | 无标签伪任务元学习、少样本表征；非显式程序 |
| CM11 | [TransTab](https://arxiv.org/abs/2205.09328), 2022 | 邻近+README | 列描述+值→跨表Transformer；非跨learner |
| CM12 | [XTab](https://proceedings.mlr.press/v202/zhu23k.html), 2023 | 定向核+代码 | 表专属featurizer、共享backbone；非统一显式特征 |
| CM13 | [CARTE](https://arxiv.org/abs/2402.16785), 2024 | 邻近+README | 行星状图+语义嵌入，跨不匹配schema迁移 |
| CM14 | [TabPFN / Accurate predictions on small data](https://www.nature.com/articles/s41586-024-08328-6), 2025 | 邻近 | 预训练推断模型；也是目标learner能力上界对照 |
| CM15 | [Auto-sklearn](https://papers.nips.cc/paper_files/paper/2015/hash/11d0e6287202fced83f79975ec59a3a6-Abstract.html), 2015 | 邻近 | 根据类似数据集历史性能热启动pipeline选择 |
| CM16 | [Invariant Causal Prediction](https://people.math.ethz.ch/~peterbu/Files/Manuscripts/invariant-causal-prediction.pdf), 2016 | 邻近 | 环境变化下条件机制不变；有识别假设 |
| CM17 | [Invariant Risk Minimization](https://arxiv.org/abs/1907.02893), 2019 | 邻近 | 跨环境共享最优分类器；不是模型池共享FE |
| CM18 | [Anchor regression](https://people.math.ethz.ch/~buhlmann/publications/anchor-JRSSB.pdf), 2021 | 邻近 | 给定shift类别下稳健性；不是任意模型保证 |
| CM19 | [Does IRM Capture Invariance?](https://proceedings.mlr.press/v130/kamath21a/kamath21a.pdf), 2021 | 邻近/负例 | 实用IRM近似与损失不变性存在失败条件 |
| CM20 | [The reusable holdout](https://pubmed.ncbi.nlm.nih.gov/26250683/), 2015 | 定向核 | 自适应反馈的统计有效性 |
| CM21 | [The Ladder](https://proceedings.mlr.press/v37/blum15.html), 2015 | 定向核 | 反馈发布门控，而非无限高精度得分 |
| CM22 | [On Over-fitting in Model Selection](https://www.jmlr.org/papers/volume11/cawley10a/cawley10a.pdf), 2010 | 定向核 | 搜索过程本身纳入外层评价 |
| CM23 | [Stability selection](https://stat.ethz.ch/Manuscripts/buhlmann/stabilityselection.pdf), 2010 | 定向核 | 子采样稳定性与有条件错误控制 |

补充给主报告：研究主报告 已核 MSDPO ACL 2026 §4.4/Table 3 的 XGB→AutoGluon 结果，本次研究不重复计入候选或转述未独立核验的数字。

## 六、公开实现核查（只读）

| 官方仓库 | 核到的内容 | 可用性/结论边界 |
|---|---|---|
| [LLMFE](https://github.com/nikhilsab/LLMFE) | 根目录、README、optimization_utils.py | 保存程序重用接口；尚未追完Table13调用链 |
| [OCTree](https://github.com/jaehyun513/OCTree) | README、ours目录、train_xg.py | 可核搜索反馈；未见迁移实验专门入口 |
| [GELFE](https://github.com/Casper-de-Winter/GELFE) | README/根目录、DataSetTrainV2.py | 四模型OR标签明确；阈值及注释与论文有差异 |
| [MACFE](https://github.com/Ivanrs297/MACFE) | README、run.py、experiments.py、evaluations.py | 监督预处理在CV外；LR/KNN名称次序反转 |
| [TabPrep](https://github.com/atschalz/tabprep) | README、tabprep.py | sklearn wrapper；依赖AutoGluon实现，完整benchmark例尚未齐 |
| [STUNT](https://github.com/jaehyun513/STUNT) | README、eval.py | 载入MLP encoder，再用prototype分类；不是任意learner FE |
| [XTab](https://github.com/BingzhaoZhu/XTab) | README、runexample.py | FT_TRANSFORMER的finetune_on checkpoint；完整预训练需AWS/打包源码 |
| [TransTab](https://github.com/RyanWangZf/transtab) | README/目录 | 支持cross-table pretrain/finetune；未深读训练代码 |
| [CARTE](https://github.com/soda-inria/carte) | README/目录 | 图Transformer估计器、数据/复现入口；未深读模型代码 |

无官方 repo 的项目已标“未发现”，不是断言“没有”。Google/GitHub 搜到名为 topofe 的用户是无关同名账号，未当作论文实现。

## 七、检索日志与排除项

执行 `paper_search/scripts/search_papers.py --query 'automated feature engineering transfer' --start-year 2024 --end-year 2026 --max-papers 8`。默认六个API源返回零项，因为：`requests` 缺失导致 DBLP/OpenAlex/Semantic Scholar/Crossref 跳过；OpenReview 缺包；arXiv 网络 `Operation not permitted`。完整 stderr 保存在 `cross_model_sources/search_cli.stderr`。这不代表检索范围里没有论文。随后使用 web 主源检索、arXiv/作者PDF与 GitHub connector 只读补齐。

查询族（全部 2026-11-06）：

1. `LLMFE appendix D.3 feature engineering downstream models transfer`；`Learning Feature Engineering for Classification LFE 2017 transfer learning`；`automated feature engineering cross model transfer 2025 2026`。
2. `LLM FE Automated Feature Engineering evolutionary optimizers Github Nam 2024 2503`；`automated feature engineering multiple models transfer`；`feature engineering multi-learner OR model-agnostic transfer 2024 2025 2026`。
3. `TabPrep: Closing arxiv github`；`MACFE meta-learning causality github`；`Automated feature engineering for automated machine learning 2025 authors`；`Do Tabular Foundation Models Still Need Feature Engineering github`（后者由 研究主报告 的 arXiv API 发现后交叉核原文）。
4. `STUNT Few-shot Tabular Learning Self-supervised Meta-learning github TransTab XTab CARTE github`；`TransTab Learning Transferable Tabular Transformers Across Tables arxiv`；`XTab Cross-table Pretraining github`；`CARTE Pretraining and Transfer github`。
5. `Learning Feature Engineering github code`、指定PDF中 `Random`/`classifier`/`Logistic`/`across models`；`OpenFE transfer neural/MLP`（本轮未额外核到严格冻结跨learner证据，交主分支，不计独立结论）。
6. `Dwork Reusable Holdout 2015 science`；`Blum Hardt Ladder leaderboard 2015`；`On Over-fitting in Model Selection Cawley Talbot 2010`；`Anchor regression heterogeneous data meet causality`；`Invariant Risk Minimization`；`Stability selection Meinshausen Bühlmann 2010 pdf`。

排除/降级：普通跨项目漏洞检测、时序图网络、材料领域多模型回归、专利、泛工具推荐、非官方摘要均不用于技术主张；XTFormer 被检到但与显式 FE 跨 learner 距离远，未计正式候选；FeRG-LLM 与其他 LLM/RL FE 由主研究分支负责，避免重复。TopoFE/MACFE/TFMneed 保留但明确限制；ICP/IRM/anchor 只作环境稳健性邻近背景，不能填补模型迁移证据。
