# 基础机制与历史baseline

本页全部是窗口前的基础机制或历史baseline，**不计本期新论文数**。除T05、G05两篇另有完整精读外，下表是经原论文/官方出版记录定位的机制背景索引；没有重跑实验，也没有完成逐条全文精读。它们帮助建立强对照，不提供本次核验过的效果排名。返回[[00_总索引与阅读路线]]。

## 常用机制与应保留的对照

| 原始来源 | 历史时间标识 | 对今天的迭代问题有何用 | baseline与不可直接迁移之处 |
|---|---|---|---|
| [Gradient Starvation](https://arxiv.org/abs/2011.09468)；更早[On the Learning Dynamics of Deep Neural Networks](https://arxiv.org/abs/1809.06848) | arXiv分别2020-11-18、2018-09-18；同机制演进背景 | 强预测特征可压制其他特征学习，解释“有新信息却没学进去” | 与T01联读；需要特征干预/日程对照，不能由新特征没涨直接确诊饥饿 |
| [PCGrad / Gradient Surgery](https://arxiv.org/abs/2001.06782) | arXiv2020-01-19 | 冲突时投影任务梯度，作为方向干预baseline | 与T04比较实际更新幅度和作用参数块；负cos不自动意味着业务负迁移 |
| [GradNorm](https://proceedings.mlr.press/v80/chen18a.html) | ICML2018官方记录 | 根据梯度范数和任务训练速度调节任务权重 | 梯度幅度与方向是不同轴；与固定权重、调好学习率baseline一起比较 |
| [MMoE](https://research.google/pubs/modeling-task-relationships-in-multi-task-learning-with-multi-gate-mixture-of-experts/) | KDD2018官方Google研究记录 | 共享专家、任务门控，显式控制共享表示的读取 | T02需要与强共享/私有塔基线比；隐藏特征混合不是G03所证的概率混合 |
| [ES-DFM / Capturing Delayed Feedback](https://arxiv.org/abs/2012.03245) | arXiv2020-12-06 | 将等待反馈的标签完整性与数据新鲜度权衡显式建模 | 先测自己的回流/延迟分布和事件定义，再校正；观察窗口不等于永不转化。与实验X01配套 |
| [ESDF / Entire Space Delayed Feedback](https://arxiv.org/abs/2011.11826) | arXiv2020，历史索引 | 点击—转化空间和延迟反馈共同建模的背景 | 不能用曝光/点击代理概率自动代替真实目标可观测性；与D04的propensity事件审计联读 |
| [DoReMi](https://arxiv.org/abs/2305.10429) | arXiv2023-05-17 | 通过小代理模型和域层面鲁棒优化选择数据权重，再用于较大训练 | 代理与目标模型、预算、重复率和任务分布可能失配；D06控制的是配比实验，不声称已击败DoReMi |
| [Co-teaching](https://arxiv.org/abs/1804.06872) | arXiv2018-04-18 | 两个网络互相提供小loss样本，作噪声标签处理baseline | 小loss可能只代表常见/容易，长尾真实难例可能被删；先有独立金标审计，再看同保留率随机对照 |
| [On Calibration of Modern Neural Networks](https://proceedings.mlr.press/v70/guo17a.html) | ICML2017官方记录 | 温度缩放是低成本概率校准baseline | 单个正温度二类模型保持排序，但概率乘价值、多模型混排、分群温度可能改变决策；校准集要时点合法 |
| [Distributionally Robust Neural Networks for Group Shifts](https://arxiv.org/abs/1911.08731) | arXiv2019-11-20 | groupDRO强调最差组，正则和组定义对泛化至关重要 | G05修复应与等学习率、随机切片、相同权重分布控制比；发现slice不等于应无限放大其权重 |
| [Deep Ensembles](https://arxiv.org/abs/1612.01474) | arXiv2016-12-05 | 多模型预测差异作为不确定性/错误检测baseline | 一致不等于正确，共享数据/偏差可造成稳定错误；需risk–coverage与独立漂移评估，不只看置信度 |
| [Maintaining Plasticity in Deep Continual Learning](https://arxiv.org/abs/2306.13812) | arXiv2023-06-23；后续传播标题可能变化 | 持续学习过程中保持学习能力、低效用单元更新的机制背景 | 与C02的诊断统计区分：OR本身不是重置算法；干预须查旧能力、未来泛化和计算代价 |
| [Spectral Collapse in Reinforcement Learning](https://arxiv.org/abs/2509.22335) | arXiv2025-09-26 | C02比较的谱/梯度几何背景 | 表征秩与优化可塑性不等价；任务/参数化不同会改变解释，不能把谱指标当通用故障灯 |
| [Smart Predict, then Optimize / SPO](https://arxiv.org/abs/1710.08005) | arXiv2017-10-22 | 用决策损失而非均方误差评价预测，SPO+是相关凸代理 | 原模型多为线性目标/可行域给定；用户响应、曝光反馈和策略性对手需额外建模，不能无条件迁移 |
| [Distilling the Knowledge in a Neural Network](https://arxiv.org/abs/1503.02531) | arXiv2015-03-09；仅记仓库公开日期，不断言是全球首次公开 | soft target传递类别之间相对信息，给小模型训练目标 | 教师额外输入、容量、训练数据分开记；同熵平滑/随机非目标概率是信息迁移负对照。见X07 |

## 两篇历史重点为何仍精读

- [[T05_显式稀疏与扩容失效_SSR]]：首发2026-04-09，离窗口很近且直接处理推荐扩容；其最新版本仍在4月。作为机制与强baseline背景，单列而不“借会议年份”算新文。
- [[G05_GHESD_实例错误切片]]：首发2025-12-31，2026有多个修订和ECCV记录。实例归属、关系假设、独立验证与修复归因对本任务价值很高，因此精读最新v4，同时保留历史身份。

## 强baseline的最低要求

本库的“baseline”有三层：**当前生产基线**回答是否值得替换；**公平调参的简单方法**回答复杂机制是否必要；**oracle/负对照**回答收益解释是否成立。论文里的一个较旧模型通常只覆盖第二层的一部分。

例如梯度法需有调好学习率/权重的普通训练；数据选择需有等保留率、等步数随机；持续学习需有同新鲜度FT/重训/简单回放；决策学习需有PTO+校准+utility选checkpoint；压缩需有同长度同刷新截断/均值和固定服务预算前沿。省略这些对照会把资源、目标或数据差异误记为新算法收益。
