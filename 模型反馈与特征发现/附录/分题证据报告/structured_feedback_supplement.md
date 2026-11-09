> [!info] 分题阶段记录
> 此文件保留分题阅读时的版本与措辞。最终版本、合并结论和统计以专题主报告及证据台账为准。

# 补充核查：LATTEArena 与 FeRG-LLM

核查日：2026-11-06。仅定向补充两篇，未扩展检索。结构化记录见 structured_feedback_supplement.json（工作记录：`structured_feedback_supplement.json`），作者仓库原始返回见 structured_supplement_repo_evidence.json（工作记录：`structured_supplement_repo_evidence.json`）。没有运行算法或重放日志。

## LATTEArena：价值在组件对照，原方法忠实性与统计口径需要保留

[arXiv 2606.09004v3](https://arxiv.org/html/2606.09004v3) 为2026-10-12扩展版；正文声明向IEEE投稿，未核实接收。它将15种方法拆为六个设计维度，再评价24个标准化代理配置。主表覆盖9分类、4回归数据集，另测3个大分类集；采用6个随机划分，train/valid/test=3:1:1，默认GPT-4o与RandomForest。VG、TG分别是同一评价器在验证/测试上的增益，AG是AutoGluon测试增益。

对本题最有价值的结果是 OGR 的分类平均增益：VG +3.55、TG +0.73、AG −0.32 个准确率百分点（Table4）。这把“适应反馈集”与“换更强学习流程后仍有用”分开。历史示例配置也未稳定改善收益；作者解释为历史只存新增列及分数，缺少父集合上下文。CART替换为原始metadata的消融中，token增加约280%，VG/TG略降（Table6）。这些是本基准的证据，不能直接升级为普遍规律。

这里尤其要避免把VG→AG整个差值都叫验证过拟合：它同时换了数据划分和预测流程；VG→TG更接近前者，TG→AG还含模型适配性。等token比较选了5个方法间VG差异较大的分类集，其曲线显示简单方法可能追上昂贵迭代法，外推范围需保留选择条件。[方法与评估](https://arxiv.org/html/2606.09004v3)。

分类表覆盖：CAAFE、FEBias、GPT-Signal、RAFG、SMARTFEAT、FeatLLM、FREEFORM、LFG、Adda、OCTree、FEBP/PromptFE、ELLM-FT、LLM-FE、LPFG、Rogue One。后续标准化配置排除或替换部分原生组件，不能按这份名单直接理解为原实现跑分。

### 代理配置不等于原论文复现

Table2明确以ELLM-FT的种群实现替代LLM-FE，并声称后者没有进化；这与LLM-FE原文及作者经验池代码不符。Table1把CAAFE年份写为NeurIPS2024，正式版本是2023。Table2对FeatLLM与基因组方法FREEFORM的适用对象描述疑似对调。论文对CAAFE“只有LLM选择”的概括也不能替代原作的验证接受/拒绝机制。

因此适合引用它的**组件对照和评估分层**，不宜声称“15种原始算法已被忠实且公平地全面比较”。Table2本身承认排除/替换人机交互、RAG、集成或额外模型。[LATTEArena Table2](https://arxiv.org/html/2606.09004v3)、[LLM-FE经验池](https://github.com/nikhilsab/LLMFE/blob/main/llmfe/buffer.py)、[CAAFE官方出版信息](https://proceedings.neurips.cc/paper_files/paper/2023/hash/8c2df4c35cdbee764ebb9e9d0acd5197-Abstract-Conference.html)。

### 实际打开仓库后的审计发现

已通过GitHub连接器打开 [goodenhak/LATTEArena](https://github.com/goodenhak/LATTEArena) 的根目录、README、日志目录说明，以及4份源码。日志目录实际存在；论文称4000余条，本次未逐条计数、执行或核对全部表格。

| 位置 | 实际内容 | 对证据解释的影响 |
|---|---|---|
| [日志README](https://github.com/goodenhak/LATTEArena/blob/main/execution_logs/README.md) | 声明过滤了早期失败日志，并有历史格式不一致 | 已发布日志不等于完整未经筛选运行记录 |
| [extract.py](https://github.com/goodenhak/LATTEArena/blob/main/execution_logs/extract.py) 472–480、593–595 | 多于一项时，排序删最低值，再算均值/标准差 | 当前脚本不是全种子平均；不得据此称无偏均值 |
| [check_success_rate.py](https://github.com/goodenhak/LATTEArena/blob/main/execution_logs/check_success_rate.py) 113–154 | OPRO任一对话turn无warning即整轮成功；其他族计数单位不同 | “99%成功”不能解释为每次生成99%无错 |
| 同上 6–18 | 主要以warning字符串判错 | 没有warning不等于语义正确或无标签泄漏 |
| [Evaluator.py](https://github.com/goodenhak/LATTEArena/blob/main/Evaluator.py) 221–235 | RF预处理用train与test协变量拼接拟合编码 | 测试协变量参与预处理；此处不等于读取测试标签 |
| [Preprocess.py](https://github.com/goodenhak/LATTEArena/blob/main/Preprocess.py) 38–46 | val比例按剩余样本换算 | 默认两者0.2时为60/20/20；README OpenFE段落的80/20再80/20表述不能直接照抄 |

这些观察针对当前仓库代码，尚未证明论文每张表一定由该版本/该汇总脚本生成。应报告“统计口径存在需澄清的问题”，不能据此指控所有结果错误。

作者关于“大样本自然消除过搜索风险”“架构复杂度导致指数成本”的表述也应降为其基准观察；有限配置的成本倍数并不能证明指数复杂度，扩大样本更不能普遍消除适应性过拟合。

### 对本综述的增量

本报告推论是：历史记录至少需要携带父特征集合、预测器配置和评价口径，否则把不同条件下的孤立分数并排，会误导后续生成。LATTEArena提供了相符的负面观察，但其失效原因解释没有独立因果辨识。它同时支持把“最终增益”“获取反馈的代价”“执行有效率”分开，不能用更复杂反思或更多历史自动代替更强证据。

## FeRG-LLM：终局效用训练生成器，区别于推理期反思

[FeRG-LLM 2503.23371v1](https://arxiv.org/html/2503.23371v1) 先用约7190份文档构造“提出特征思路→写Python”的两轮SFT，再在8个二分类数据集采样思路及代码，用XGBoost AUC形成chosen/rejected对，对思路进行DPO。它补上了一条重要路线：**反馈进入生成器参数，而不仅进入下一轮提示**。监督仍来自终局AUC，不能称为每个推理步骤都有过程奖励。

其集合选择也有区别：最多5个特征时枚举子集；更多时只评单列与全集。前者能比较小集合协同，后者遗漏中间大小子集。§4.1与Algorithm1明确使用80/20训练/测试划分，重复生成、选子集、收集每轮最高AUC后报告均值；未描述独立外层终测。因此这里不引用其总平均提升作为无选择偏差的泛化数字。分类反馈训练后另评回归属于任务泛化，未核到同一特征冻结后的跨模型迁移。

GitHub连接器精确搜索FeRG-LLM返回空列表；HTML中GitHub链接仅为arXiv通用页脚。本次未定位作者仓库，不等于断言没有代码。

## 本轮访问记录

直接打开两篇arXiv指定版本均成功。项目网站 https://goodenhak.github.io/LATTEArena/ 经web返回Internal Error，改用GitHub连接器。只进行了LATTEArena与FeRG-LLM精确仓库检索；未安装依赖、未进行大范围扩检。

