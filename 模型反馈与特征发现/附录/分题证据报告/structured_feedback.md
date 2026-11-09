> [!info] 分题阶段记录
> 此文件保留分题阅读时的版本与措辞。最终版本、合并结论和统计以专题主报告及证据台账为准。

# 结构化反馈与 LLM 特征工程：子题证据报告

核查日：2026-11-06。范围是模型反馈怎样指导特征发现，覆盖“反馈超越总分”“互补特征组合”“跨模型迁移”三个问题。本文记录文献证据与推论，不提供实验方案，也不判断用户系统采用何种预测模型。共收录 27 个候选，13 篇核读方法或关键结果表，实际打开 9 个作者仓库，进一步读过 4 份核心源码及 1 份提示模板。未运行任何论文算法。

机器可合并记录见 structured_feedback.json（工作记录：`structured_feedback.json`）；前 8 个仓库和核心代码快照见 structured_repo_evidence.json（工作记录：`structured_repo_evidence.json`）；第 9 个仓库见 structured_robust_repo_evidence.json（工作记录：`structured_robust_repo_evidence.json`）。这些文件区别“论文声明开源”“连接器实际返回目录/README”“源码逻辑核对”“执行复现”四个层级。本次没有达到执行复现层级。

## 一、可以形成主线的结论

**文献事实：反馈的主要变化是把一个效用值展开成可定位、可操作的状态。** OCTree 给出分裂变量与阈值；SIGMA 给出当前模型的重要性分组；Text-and-Tabular 给出正负样本排序错误；Evolving LLM-Generated Features 给出混淆类对、逐类激活率和逐项删除后的效用。CAAFE 早已有评价闭环，LLM-FE 则扩展了程序记忆和搜索组织。因此，不能将这段发展写成“早期完全没有反馈，最新方法首次加入反馈”。[CAAFE](https://arxiv.org/html/2305.03403v2)、[OCTree](https://arxiv.org/html/2406.08527v2)、[SIGMA](https://arxiv.org/html/2608.17948v1)、[Text-and-Tabular](https://arxiv.org/html/2609.21894v1)。

**本报告推论：需要分开讨论“提示里有什么”与“最终按什么保留候选”。** 树、SHAP、错误例子可以改进提案；最终多数方法仍依靠验证效用筛选。结构化信号能缩小或重排搜索空间，但没有替代真实下游效用这一判据。反过来，程序历史虽仍配标量分数，也可能因为搜索单位变大而找到单列搜索难以发现的组合。这两条路线在文献中并行，不能用“结构化程度”排成单一优劣序列。[LLM-FE](https://arxiv.org/html/2503.14434v2)、[EFE](https://arxiv.org/html/2607.01548v1)。

**关于互补性，现有证据最常支持条件增益或探索多样性；对高阶协同的直接证明较少。** 使用不同算子、低相关过滤、跨重要度组生成，分别解决搜索覆盖和冗余，不能直接推出某组特征具有协同信息。本文把“作为整体评价的程序”“逐个加入当前集合”“先独立打分后联合剪枝”分别编码，避免把三者等同。[LLM-FE](https://arxiv.org/html/2503.14434v2)、[ELATE](https://arxiv.org/html/2508.14667v1)、[SIGMA](https://arxiv.org/html/2608.17948v1)。

**跨模型迁移有正面证据，也有清楚的负例。** OCTree 和 LLM-FE 明确将某个评价模型搜索出的特征转交另一个模型；OCTree 的 Clinical→MLP 错误率上升。与此同时，许多论文只是对不同预测器分别搜索。后者只能说明框架适用多个模型，不能证明同一组特征可以迁移。[OCTree Table 7](https://arxiv.org/html/2406.08527v2)、[LLM-FE Appendix C.1](https://arxiv.org/html/2503.14434v2)。

## 二、反馈信号的可比分类

| 反馈内容 | 论文锚点 | 直接告诉生成器什么 | 证据边界 |
|---|---|---|---|
| 验证分数、接受/拒绝、执行错误 | CAAFE | 上一代码块是否有效、是否改善当前集合 | 错误修复不等于发现新预测信息 |
| 分数与整段优秀程序历史 | LLM-FE、EFE | 哪些程序组合曾经成功 | 主要仍是适应度，不能描述为梯度或残差 |
| 预测树条件与阈值 | OCTree | 当前表征上的可用分裂结构 | 使用另训 CART，不保证是 XGBoost 内部解释 |
| 当前模型 SHAP 分组 | SIGMA、MedFeat | 当前模型依赖哪些列，哪些列弱于噪声参照 | 重要性是模型与表示条件下的量 |
| 具体误排、误判、混淆类对 | Text-and-Tabular、Evolving Features | 哪类样本仍无法区分 | 挑选错误样例可以带来偏差；全局重训收益需另验 |
| 激活分布、删一特征效用 | Evolving Features | 规则在哪些类触发、保留它是否必要 | 条件删除的贡献不同于单列相关性 |
| 残差代理与实现收益 | CRAFTER | 冻结骨干尚未解释的结构 | 代理残差相关与真实改进不同；主报告另核 |
| 变量、关系符号、阈值正确性 | Multi-level Diagnosis | 规则失败发生在哪一层 | 生成后诊断/过滤，未证明下游误差闭环 |
| MI/Granger粗评与SHAP联合剪枝 | ELATE | 单候选有无信号、进入集合后是否仍有用 | 边际统计和条件效用有不同盲点 |
| 搜索停滞、家族覆盖、接受/拒绝记忆 | TopoFE、MALMAS | 下一步搜索哪里、避免重复什么 | 搜索状态不等于模型内部机制 |

表内方法说明的来源分别见对应 JSON 的 `paper_url` 与 `evidence_locations`。这里“反馈”采用较宽的工程定义；元数据、EDA图形、知识库属于生成上下文，只有随当前模型/搜索状态更新时，才适合称为动态反馈。

数学上可区分两种量：候选单独的信号 `score(z, y)`，以及给定当前特征集合 S 后的效用变化 `Δ(z | S, M) = U(M fitted on S∪{z}) − U(M fitted on S)`。这是本报告的分析记号，不是这些论文共同采用的公式。一个候选的相关性或 SHAP 值，通常不能直接替代第二个量。二元协同可能满足各自加入时增益很小、共同加入时增益明显；逐项正增益门槛可能错过这种情况。该判断是搜索策略的逻辑边界，并非声称本文这些基准已证明出现具体协同漏检。

## 三、最能支撑“超越总分”的直接证据

### 1. OCTree：目前较清晰的结构反馈消融

论文将规则、验证分数和 CART 文本一并提示 LLM。Table 6 在四个数据集比较 score-only 与增加决策树反馈，错误率均下降：Disease 27.62→26.19，Clinical 45.61→45.07，electricity 6.89→6.65，kdd 19.47→19.07（单位为%，三次数据划分）。这是“保持性能反馈、额外加入结构”的直接证据，范围应保留为该论文的设置。

源码能够接上这条链：`ours/train_xg.py` 调用 CART→文本与提示生成；`ours/utils_xg.py` 将候选按分数组织并附上树文本。由此可支持“结构实际进入提示”。不能据此写成“提取目标 XGBoost 的全部路径作为新特征”。[论文方法与 Table 6](https://arxiv.org/html/2406.08527v2)、[作者核心代码](https://github.com/jaehyun513/OCTree/blob/main/ours/utils_xg.py)。

树在本领域至少有四种角色：预测模型的树结构、特征表达式语法树、候选搜索树、把规则直接组成最终分类树。OCTree、PromptFE、CRAFTER、From Prompts to Trees 分别涉及不同角色。它们不能因为标题或实现中都有 tree 就归为同一种模型反馈。

### 2. 从错误样本到可写出的语义区分

Text-and-Tabular 把交叉验证中正样本分数低于负样本的逆序对，转为 LLM 能读取的文本对照，并附上已正确排序的样例。论文与同预算随机生成加记忆的版本比较，反馈版分别用第 4、3、9 轮达到对照 15 轮终值。它支持“有针对性的错误实例能提高候选生成效率”，覆盖三个文本加表格分类任务。摘要“最多3×”与正文“最多5×”口径不同，正文宜直接报告轮数。

扩展到 MSE 残差和 NDCG 在该文主要是机制讨论，不能写成已做回归或排序基准。AUC 逆序减少在固定排序下有明确意义，但新增特征后全模型重新拟合会改变别的样本排序，因此一个局部区分本身不保证总体 AUC 改善。[方法与反馈消融](https://arxiv.org/html/2609.21894v1)。

Evolving LLM-Generated Features 更进一步反馈混淆类别、逐类规则激活率和逐项删除效用。其 Table 1 也给出反例：AGNews 平均准确率由初始规则的 82.7 降到进化后的 81.3；GoEmotions 与 HELOC 则改善。该研究没有把三类反馈逐项独立消融，因而只能支持这套组合机制的任务相关效果，不能据此宣布某一种反馈普遍最好。[方法、Table 1](https://arxiv.org/html/2610.03951v1)。

### 3. SHAP：把模型注意力结构化，但不把重要性绝对化

SIGMA 的关键不是让 LLM 直接读一张任意长的归因表，而是用噪声列参照把现有列分组，再同时探索组内与跨组候选；EXIT 约束近期用过的来源和变换，减少重复。作者的结果说明多样性机制有效，也记录了更强算子限制提高代码错误率，以及大模型在小数据验证集上过拟合的现象。[SIGMA](https://arxiv.org/html/2608.17948v1)。

MedFeat 将 SHAP 与预测模型的表达能力边界结合。消融显示去掉 SHAP 后平均 F1/AUPRC 分别相对下降 4.5%/4.2%，这里是相对下降而非百分点。其附录对对比算法做了较多改写，横向排名的解释强度应低于自身消融。[MedFeat Table 3 与 Appendix D](https://arxiv.org/html/2603.02221v2)。

负面证据可补入 FAccT2025 的 SHAP representation sensitivity：编码或分箱等表示变化可以改变归因结果。可得的结论是“SHAP 是当前模型和表示下的搜索启发”，而不是“SHAP 无用”或“SHAP 排序揭示变量的本质价值”。[官方论文](https://facctconference.org/static/docs/facct2025-206archivalpdfs/facct2025-final590-acmpaginated.pdf)。

### 4. 三级诊断：比一个总分更可解释，但其“golden”有定义范围

Multi-level Diagnosis 将 LLM 规则拆为选对变量、关系方向、阈值三层。它在 FeatLLM 的十组规则中按三层均分选 top3 或去掉 bottom3，再等权集成。Credit-g、4-shot 的 AUC×100 从 52.27 到 57.77，摘要的 10.52% 是相对改善，即绝对 +5.50 个百分点。Adult、8-shot 则由 87.29 降为 86.35（top3），说明这些代理质量指标也不保证更好的最终预测。

其“golden relation”按协方差符号定义，不能沿用正文宽泛措辞称为因果关系。论文还发现增加描述或样例有时降低可靠性，样例质量的重要性高于简单增加数量。这是结构化提示信息并非越多越好的直接边界证据。[Findings EMNLP2025 官方页面](https://aclanthology.org/2025.findings-emnlp.249/)、[方法与 Table 1](https://arxiv.org/html/2509.25207v1)。

## 四、互补性：文献实际优化的对象是什么

| 路线 | 代表论文 | 可支持的论断 | 尚不能支持的论断 |
|---|---|---|---|
| 一次加入一列/一块，按当前集合效用保留 | CAAFE、OCTree、SIGMA | 条件效用取代完全独立评分 | 必然发现各自无增益、共同有增益的组合 |
| 整段变换程序作为个体 | LLM-FE、EFE | 多个特征可以作为整体协同进化 | 程序内每个特征的贡献可解释或联合最优 |
| 保留多种规则集，再集成或筛选 | FeatLLM、Multi-level Diagnosis | 不同规则集合带来候选多样性 | 多样性本身证明互补信息 |
| 先边际粗评，后模型条件剪枝 | ELATE | 搜索成本与集合效用可以分层处理 | 早期边际筛选不会漏掉协同特征 |
| 多视图语义、稀疏文本、embedding联合 | Text-and-Tabular | 加入语义特征与已有视图在部分设置可继续提升 | 提升证明条件独立或正交信息 |

Text-and-Tabular 的 Table 2 有一处特别重要的证据缺口：论文展示 LLM+TFIDF、LLM+embedding 与三者联合，却没有列出 **TFIDF+embedding、不带 LLM** 的组合。三者最佳可以支持它是表内最佳组合；不能独立识别三视图相对双视图的全部额外收益由 LLM 特征贡献。统计条件独立更需要分布层面的依据，性能增益本身不构成证明。[Table 2](https://arxiv.org/html/2609.21894v1)。

ELATE 的方法值得用于组织综述：其便宜分数由 Granger 统计与 MI 构成，强调候选评分相对稳定；达到种群容量后才用 walk-forward 下的 XGB SHAP 及相关性剪枝。它体现“候选生成信号”和“特征集合质量”不是同一个问题。不过，Granger 的术语不能被写成已完成因果识别。[ELATE 方法](https://arxiv.org/html/2508.14667v1)。

## 五、跨模型迁移的证据等级

1. **接口兼容**：算法允许更换评价器。只说明代码/方法适配性。
2. **各模型分别重新搜索**：说明同一框架可为不同模型发现特征，不能证明同一特征迁移。
3. **在模型 A 搜索，固定特征，交给模型 B**：直接的迁移证据。
4. **冻结特征跨模型并跨数据分布仍稳定**：要求同时变化两个维度，本子题未发现可广泛概括的强证据。

CAAFE 明确使用 TabPFN 搜索并在 LR/RF/TabPFN 评价。OCTree Table 7 中，XGBoost 搜索特征用于 MLP，Clinical 错误率从 41.77 上升到 42.32，Disease 和 electricity 改善。LLM-FE 的 2025v2 Appendix C.1 中，XGB 特征转 MLP 的分类 ACC 从 0.745 到 0.763，目标模型重新搜索为 0.791；回归 NRMSE 从 0.871 到 0.848，重搜为 0.631。它们共同支持“可迁移但有模型适配损失”，不能推为通用可迁移保证。[CAAFE](https://arxiv.org/html/2305.03403v2)、[OCTree](https://arxiv.org/html/2406.08527v2)、[LLM-FE v2](https://arxiv.org/html/2503.14434v2)。

MedFeat 的跨临床队列/时间验证与这里的跨模型是两个维度；TopoFE 的迁移由跨模型子报告独立深入核验；CRAFTER 多骨干的细节由 研究主报告 核验。本报告不把这些设置混算为同一种证据。

## 六、需要保留在综述中的负面证据和版本问题

- **基线忠实性**：MALMAS Appendix B.1 将 LLM-FE 描述为单轮、20个候选、没有反馈的实现；原作与作者 `buffer.py` 均包含迭代多岛经验池。由该对比无法直接得出优于原始 LLM-FE 的结论。对 OCTree 的算法描述也与原作机制不符。[MALMAS](https://arxiv.org/html/2604.20261v1)、[LLM-FE经验池](https://github.com/nikhilsab/LLMFE/blob/main/llmfe/buffer.py)。
- **基线设置变化**：MedFeat 对 FeatLLM 去掉few-shot、对CAAFE把交叉验证改为单次划分等。可以报告作者采用的设置，不能把排名外推成原始方法的普遍优劣。[Appendix D](https://arxiv.org/html/2603.02221v2)。
- **验证反馈也可能过拟合**：SIGMA 的小数据分析已明确讨论这一点；不能将更大 LLM、更长搜索视为稳定单调收益。[SIGMA](https://arxiv.org/html/2608.17948v1)。
- **模型报告与代码版本分开**：LLM-FE 于2025有预印本，作者仓库与官方页面标识2026 TMLR；本文件引用的迁移数值来自2025v2。不要把这些数字自动当作2026最终版表格。
- **运行可用性**：AutoML2025 的调查覆盖53种方法、9项可用性标准；这是“发布代码不等于可复现运行”的补充依据，不能用来否定算法准确性。[调查](https://arxiv.org/abs/2508.13932)。
- **梯度措辞**：本次核读的核心 LLM 特征生成器多数接收文本化观察和标量评价。即便使用残差或所谓“textual gradient”，也不意味着对离散特征程序做了真实反向传播；写作时应明确究竟是数学梯度、残差代理，还是语言反思。

## 七、作者仓库核查清单

| 仓库 | 本次真正打开的内容 | 证据等级与限制 |
|---|---|---|
| [noahho/CAAFE](https://github.com/noahho/CAAFE) | 根目录、README、caafe/caafe.py | 代码显示ACC+AUC增益判断及保留/丢弃反馈；未运行 |
| [Sungwon-Han/FeatLLM](https://github.com/Sungwon-Han/FeatLLM) | 根目录、README | Main.ipynb、规则/模板存在；未核全部内部逻辑 |
| [jaehyun513/OCTree](https://github.com/jaehyun513/OCTree) | 根目录、README、ours/、train_xg.py、utils_xg.py | 树转文本进入提示有源码证据；README运行说明较少 |
| [nikhilsab/LLMFE](https://github.com/nikhilsab/LLMFE) | 根目录、README、llmfe/、buffer.py | 多岛经验池存在；MIT；未运行 |
| [shiralab/SIGMA](https://github.com/shiralab/SIGMA) | 根目录、README、提示模板 | 环境文件和入口存在；未运行 |
| [zyf505/PromptFE](https://github.com/zyf505/PromptFE) | 根目录、README | feat_tree.py、search_space.py等存在；未执行 |
| [egetaga/EFE](https://github.com/egetaga/EFE) | 根目录、README | EFE-Time/、EFE-Tab/、OpenEvolve相关内容；未执行 |
| [FeatEng/FeatEng](https://github.com/FeatEng/FeatEng) | 根目录、README | 基准材料存在；未运行 |
| [DohaLim/Robustness-eval](https://github.com/DohaLim/Robustness-eval) | 根目录、README | evaluator.py、数据、模板和环境说明存在；未执行 |

MALMAS 论文给出作者仓库链接，但本次连接器只返回重定向，单列为“声明存在、内容未核”。MedFeat、Text-and-Tabular、FAMOSE、ELATE、Evolving Features 未定位并实际打开可确认为作者的仓库；这个状态不能改写成“没有代码”。PIFE 的 OpenReview 页面遇到访问验证，仅保留投稿候选。

## 八、检索与排除日志

### 已执行工具与失败原文

先读取 paper-search 与 paper-structure-deep-dive 技能。按 paper-search 脚本尝试：

```text
python /Users/didi/.codex/skills/paper_search/scripts/search_papers.py --query 'large language model automated feature engineering feedback' --start-year 2023 --end-year 2026 --max-papers 15
/bin/bash: python: command not found
```

随后同参改为 python3，得到：

```text
[dblp] unavailable (import failed: No module named 'requests'); skipping this source.
[semantic_scholar] unavailable (import failed: No module named 'requests'); skipping this source.
[open_alex] unavailable (import failed: No module named 'requests'); skipping this source.
[crossref] unavailable (import failed: No module named 'requests'); skipping this source.
[openreview] Error: openreview not installed. pip install openreview-py
[arxiv] Error: <urlopen error [Errno 1] Operation not permitted>
```

六源均返回0项。这是依赖/网络执行失败，不是“没有相关论文”。按研究主报告协调未安装依赖，后续使用 web 搜索、论文官方全文与 GitHub 连接器。研究主报告另有统一API广搜原始记录 `search/feature_engineering_phrase.json`，不与本子任务失败混同。

### 查询族与追踪

以下是为复查整理的检索词族，不冒充完整逐调用原始日志：

| 轮次/目的 | 查询词族与定位动作 |
|---|---|
| 核心算法 | LLMFE/LLM-FE、CAAFE、OCTree、FeatLLM + feature engineering / feedback / GitHub |
| 结构反馈 | feature engineering + SHAP / residual / error feedback / decision tree / reflection |
| 程序进化 | evolutionary feature engineering / LLM evolutionary optimizer / ELATE |
| 2025–2026扩展 | SIGMA、MedFeat、FAMOSE、PromptFE、TopoFE、MALMAS、KnowFeat、SymboLLM-FE、FEAML、Rogue One |
| 具体错误定位 | LLMs as Feature Engineers for Text-and-Tabular Prediction；Evolving LLM-Generated Features for Interpretable Classification |
| 反例与工程边界 | SHAP feature representation sensitivity；How Usable is Automated Feature Engineering；FeatEng |
| 研究主报告新命中追踪 | 2509.25207；Human-LLM Collaborative Feature Engineering 2601.21060；给定OpenReview PDF反查PIFE |
| 元数据核对 | 精确题名 + site:aclanthology.org / site:arxiv.org / site:openreview.net / 官方会议域名 |
| 仓库核查 | GitHub连接器 search_repositories，再 fetch README、tree目录或明确源码；实际返回内容与论文声明分列 |

本轮最后精确检索 `site:aclanthology.org "Multi-level Diagnosis and Evaluation"` 纠正作者README较宽泛的EMNLP引文，正式版本为 Findings EMNLP2025。PIFE 查得 OpenReview `L5j7JSFvs6`，接收尚未确认。研究主报告负责最新AACL2026 Multi-Stage DPO论文，未重复计入本子题27项。

### 排除及降级

- ELLA：未找到可以确认对应的特征工程论文；研究主报告已说明初始名称记忆未确认，未把无关同名模型纳入。ELATE是已核实的独立条目，不能直接宣称二者为同一论文。
- OCTree检索出现的3D视觉octree论文排除。
- FAMOSE同名非作者GitHub项目排除，防止把同名仓库当复现代码。
- 第三方自动论文摘要只用于发现题名/链接；性能、方法与出版状态回到官方论文或作者源核查。
- 图文EDA的PIFE仅保留候选：OpenReview验证页阻止全文检查；未据检索摘要写数值结果。
- 论文“已投稿”“README宣称会议”“官方论文集已发布”分开；未把arXiv年份当正式出版年份。
- Human-LLM、FEAML、CoFEH、KnowFeat、SymboLLM-FE、Rogue One等仅到官方摘要/元数据，不能与深核条目使用同等论证权重。

## 九、候选索引

1. **CAAFE** — [Large Language Models for Automated Data Science: Introducing CAAFE for Context-Aware Automated Feature Engineering](https://arxiv.org/html/2305.03403v2)。NeurIPS 2023 main track（官方论文集核验）；核读深度：方法、实验设置、作者代码。
2. **FEATLLM** — [Large Language Models Can Automatically Engineer Features for Few-Shot Tabular Learning](https://arxiv.org/html/2404.09491v2)。ICML 2024；核读深度：方法及作者仓库。
3. **OCTREE** — [Optimized Feature Generation for Tabular Data via LLMs with Decision Tree Reasoning](https://arxiv.org/html/2406.08527v2)。NeurIPS 2024；官方论文核验；核读深度：方法、Table6/7及核心源码。
4. **LLMFE** — [LLM-FE: Automated Feature Engineering for Tabular Data with LLMs as Evolutionary Optimizers](https://arxiv.org/html/2503.14434v2)。初稿2025；TMLR 2026（README及官方页面确认）；数字取2025v2；核读深度：方法、消融、附录C.1及经验池代码。
5. **SIGMA** — [SIGMA: SHAP-Guided Implicit-Trajectory Generation for Metadata-Free LLM-Based AutoFE](https://arxiv.org/html/2608.17948v1)。arXiv 2608.17948v1 预印本；核读深度：方法、消融、表3及提示模板。
6. **TEXTTAB** — [LLMs as Feature Engineers for Text-and-Tabular Prediction](https://arxiv.org/html/2609.21894v1)。arXiv 2609.21894v1 预印本；核读深度：方法、表2及反馈消融。
7. **MEDFEAT** — [MedFeat: Model-Aware and Explainability-Driven Feature Engineering with LLMs for Clinical Tabular Prediction](https://arxiv.org/html/2603.02221v2)。arXiv 2603.02221v2 预印本；核读深度：方法、消融及基线实现附录。
8. **FAMOSE** — [FAMOSE: A ReAct Approach to Automated Feature Discovery](https://arxiv.org/html/2602.17641v1)。arXiv 2602.17641v1 预印本；核读深度：方法、设置和局限。
9. **ELATE** — [ELATE: Evolutionary Language model for Automated Time-series Engineering](https://arxiv.org/html/2508.14667v1)。arXiv 2508.14667v1 预印本；核读深度：方法及实验设置。
10. **EFE** — [Evolutionary Feature Engineering for Structured Data](https://arxiv.org/html/2607.01548v1)。arXiv 2607.01548v1 预印本；核读深度：方法及作者仓库。
11. **PROMPTFE** — [PromptFE: Automated Feature Engineering by Prompting](https://aclanthology.org/2026.eacl-long.28/)。EACL 2026 long paper，官方页核验；核读深度：官方论文方法与作者仓库。
12. **RUBRIC** — [Evolving LLM-Generated Features for Interpretable Classification](https://arxiv.org/html/2610.03951v1)。arXiv 2610.03951v1；页面有workshop抬头，接收未核验；核读深度：方法、表1及设置。
13. **ROBUSTNESS** — [Multi-level Diagnosis and Evaluation for Robust Tabular Feature Engineering with Large Language Models](https://aclanthology.org/2025.findings-emnlp.249/)。Findings EMNLP 2025（ACL官方页；README引文较宽泛）；核读深度：全文方法、Table1、局限及仓库。
14. **TOPOFE** — [TopoFE: Topology-Aware LLM-Guided Automated Feature Engineering](https://arxiv.org/html/2607.23286v1)。arXiv 2607.23286v1 预印本；核读深度：方法局部；迁移由cross_model子报告核验。
15. **CRAFTER** — [When Do Corrective Features Help? An Agent for Corrective Feature Discovery on Black-Box Forecasters](https://arxiv.org/html/2608.05207v1)。arXiv 2608.05207v1 预印本；核读深度：方法局部；主报告另作深入核验。
16. **MALMAS** — [Memory-Augmented LLM-based Multi-Agent System for Automated Feature Generation on Tabular Data](https://arxiv.org/html/2604.20261v1)。ACL 2026，官方PDF核验；核读深度：方法及Appendix B.1重点核验。
17. **ROGUEONE** — [Knowledge-Informed Automatic Feature Extraction via Collaborative Large Language Model Agents](https://arxiv.org/abs/2511.15074)。arXiv 2511.15074 预印本；核读深度：官方摘要/元数据候选。
18. **FEAML** — [The Semantic Architect: How FEAML Bridges Structured Data and LLMs for Multi-Label Tasks](https://arxiv.org/abs/2512.15082)。arXiv 2512.15082 预印本；核读深度：官方摘要/元数据候选。
19. **COFEH** — [CoFEH: LLM-driven Feature Engineering Empowered by Collaborative Bayesian Hyperparameter Optimization](https://arxiv.org/abs/2602.09851)。arXiv 2602.09851；会议状态本记录未核实；核读深度：官方摘要/元数据候选。
20. **KNOWFEAT** — [KnowFeat: Knowledge-Guided Feature Engineering via LLM Agents](https://arxiv.org/abs/2609.03529)。arXiv 2609.03529，预印本/投稿；核读深度：官方摘要/元数据候选。
21. **SYMBOLLMFE** — [SymboLLM-FE: LLM-Accelerated Symbolic Regression for Automated Feature Engineering on Tabular Data](https://arxiv.org/abs/2608.28408)。arXiv 2608.28408 预印本；核读深度：官方摘要/元数据候选。
22. **HUMANLLM** — [Human-LLM Collaborative Feature Engineering for Tabular Data](https://arxiv.org/abs/2601.21060)。arXiv 2601.21060；会议本记录未核验；核读深度：官方摘要/元数据候选。
23. **FEATENG** — [Can Models Help Us Create Better Models? Evaluating LLMs as Data Scientists](https://aclanthology.org/2026.findings-eacl.308/)。初稿arXiv2410.23331；Findings EACL2026；核读深度：官方摘要及基准仓库。
24. **USABILITY** — [How Usable is Automated Feature Engineering for Tabular Data?](https://arxiv.org/abs/2508.13932)。AutoML2025 nonarchival短论文；arXiv2508.13932；核读深度：官方摘要与元数据。
25. **PROMPTS2TREES** — [From Prompts to Trees: Effective LLM-Guided Tree Generation for Few-Shot Tabular Classification](https://arxiv.org/abs/2610.10227)。arXiv2610.10227；摘要备注EMNLP2026 main oral；核读深度：官方摘要/元数据候选。
26. **SHAPREP** — [SHAP-based Explanations are Sensitive to Feature Representation](https://arxiv.org/abs/2505.08345)。FAccT2025，官方PDF核验；核读深度：官方摘要及会议PDF关键结论。
27. **PIFE** — [PIFE: Progressive Insight Driven Feature Engineering via Multimodal Reasoning](https://openreview.net/pdf?id=L5j7JSFvs6)。OpenReview ICLR2026投稿；接收状态未核验；核读深度：官方检索摘要；PDF访问遇到验证。


补充元数据核验：CAAFE 为 [NeurIPS 2023 main track](https://proceedings.neurips.cc/paper_files/paper/2023/hash/8c2df4c35cdbee764ebb9e9d0acd5197-Abstract-Conference.html)，FeatLLM 为 [ICML 2024](https://proceedings.mlr.press/v235/han24f.html)。对应官方题名与版本已更新到 JSON。
