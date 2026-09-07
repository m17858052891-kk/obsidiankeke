# 2026 年 3 月论文检索内部记录

这是 `paper-search` 的完整检索记录，不属于群播正文。群播只读取已通过筛选的论文及 `research_map/paper_modules.jsonl`。

## 检索配置

- 日期：2026-03-01—2026-03-31。
- 主轨：用户侧动态定价、价格响应、券/激励、预算约束。
- 仿真轨：用户/请求生成、状态、延迟反馈、反事实数据与离线评估。
- 邻接轨：uplift、recommendation OPE、continuous-action OPE；仅在接口可迁移时入选。
- 业务排除：车辆、司机、匹配、调度、再平衡、车队与路网，以及商家广告竞价。

## 来源运行情况

- arXiv：成功，后续对入选论文逐篇核验摘要、HTML 方法与实验。
- DBLP、Crossref、Semantic Scholar、OpenAlex：跳过，原始错误为 `No module named 'requests'`。
- OpenReview：跳过，原始错误为 `openreview not installed`。
- 因多源脚本依赖缺失，本月不能声称做到了完整多库覆盖；入选结论以 arXiv 首发窗口及可核验的正式会议信息为准。

## 候选与决定

| 日期 | 论文 | 得分 | 决定 | 核心理由 |
|---|---|---:|---|---|
| 03-03 | Multi-Agent Influence Diagrams to Hybrid Threat Modeling | 3 | 淘汰 | 威胁建模，与用户价格/仿真无接口 |
| 03-04 | Fixed-Budget Constrained Best Arm Identification in Grouped Bandits | 6 | 淘汰 | 通用纯探索，没有用户动作—反馈落点 |
| 03-04 | Predicting Oscillations in Complex Networks with Delayed Feedback | 3 | 淘汰 | 控制时延，不是用户结果延迟 |
| 03-10 | From Weighting to Modeling | 8 | 入选 | 连续动作 OPE 的非参数平滑与模型校正 |
| 03-11 | RCTs for Frontier AI Governance | 5 | 淘汰 | uplift 为能力提升，同名异义 |
| 03-11 | Mind the Sim2Real Gap | 8 | 入选 | 真人对照和用户模拟真实性门禁 |
| 03-12 | LifeSim | 8 | 入选 | 长期状态、事件触发与反馈生成完整 |
| 03-13 | Dynamic Wholesale Pricing under Censored-Demand Learning | 6 | 淘汰 | 制造商—零售商批发定价，商家侧 |
| 03-17 | SpokenUS | 6 | 淘汰 | 语音噪声为主，价格响应接口不足 |
| 03-17 | Ride-Hailing Adjudication | 4 | 淘汰 | 网约车纠纷裁决，问题范围外 |
| 03-18 | Robust Dynamic Pricing and Admission Control | 8 | 入选 | 异质用户、公平状态与鲁棒安全定价 |
| 03-19 | Certifying MCKP for Gamma-Robust Discrete Pricing | 8 | 入选 | 离散选价、预算鲁棒化与证书 |
| 03-21 | Evaluating Uplift Modeling under Structural Biases | 8 | 入选 | 半合成反事实与结构偏差基准 |
| 03-23 | OPE for Ranking Policies under Deterministic Logging | 8 | 入选 | 确定性日志下利用用户反馈随机性 |
| 03-24 | OPE and Learning for Survival Outcomes under Censoring | 8 | 入选 | 长期结果右删失修正与约束学习 |
| 03-24 | Biased Error Attribution under Delayed Feedback | 4 | 淘汰 | 错误归因，不是用户结果揭晓 |
| 03-25 | Virtual Power Plant Price Elasticity | 5 | 淘汰 | 电力运行场景不可直接迁移 |
| 03-31 | Predictor-Based Output-Feedback Control | 3 | 淘汰 | 线性系统测量时延，范围外 |
| 03-31 | Monodense Deep Neural Model for Item Price Elasticity | 7 | 入选 | 单调价格响应与局部弹性接口清楚 |
| 03-31 | Option Pricing on AMM Tokens | 3 | 淘汰 | 金融衍生品定价，范围外 |

## 产出映射

- 20 篇候选全部记录在 `research_map/papers.jsonl`。
- 9 篇入选论文拆成 18 个模块，记录在 `research_map/paper_modules.jsonl`。
- 群播按 03-07、03-14、03-21（仿真/出价两条）、03-28、03-31 归档。
