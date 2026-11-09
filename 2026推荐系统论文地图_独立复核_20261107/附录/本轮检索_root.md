# 2026-11-07 独立补检：主编记录

窗口为2026-05-01至2026-11-07本次检索时点，Asia/Shanghai。按可确认首次公开日筛选，会议和最新版单列；检索不声称穷尽。网页搜索用于发现，关键事实以新下载的原始论文核验。旧检索记录保留为历史资料，不计本轮重新阅读。

## 本轮查询

2026-11-07 01:09—01:25（北京时间）执行以下查询，结果快照见[第二组搜索原始返回](../数据/root_search2_raw.json)、[第三组搜索原始返回](../数据/root_search3_raw.json)；首组只保留查询与选中条目，未保存完整原始结果，因此不声称日志完全可重放。

1. `site.arxiv.org 2026 recommendation Meta ChronoID Microsoft recommender November October`
2. `site.arxiv.org 2026 recommendation "RecIS" "HELIX" "UniRank"`
3. `site.amazon.science 2026 recommender systems recommendations RecSys`
4. `site.arxiv.org/abs/ "recommendation" "Microsoft" "2026" "September"`
5. `site.arxiv.org/abs/ "recommendation" "Apple" "2026"`
6. `site.arxiv.org/abs/ "recommender" "Pinterest" "2026"`
7. `site.arxiv.org/abs/ "recommendation" "LinkedIn" "2026"`
8. `site.arxiv.org/abs/ 2026 recommendation Alibaba Tencent Kuaishou ByteDance RecIS HELIX UniRank`
9. `site.arxiv.org/abs/ 2026 recommendation Netflix Meta Google Pinterest Microsoft November`
10. `site.amazon.science/publications 2026 recommendation "RecSys 2026"`
11. `site.microsoft.com/en-us/research "recommendation" "2026" "September"`

检索来源包括arXiv、Amazon Science、Microsoft Research官方目录；非官方聚合站仅提供ACT等线索，随即回到arXiv，不作为部署或数字的证据。阿里、字节/腾讯、快手及其他方法补检详见三组复核人的独立记录。

## 确定新增详细阅读的七篇

| 论文 | 原始入口 | 选择原因 | 处理 |
|---|---|---|---|
| ConnectionMind | https://arxiv.org/abs/2608.10187 | 补社交关系与LLM工业表征路线 | A组完成全文与部署核验后计详细数 |
| RecIS | https://arxiv.org/abs/2610.41457 | 补稀疏/稠密统一训练系统瓶颈 | A组完整复核；2025年已有同名框架，本次2026新报告增量与前序区分；效率不强推CTR |
| UniPinRec | https://arxiv.org/abs/2606.00422 | 补海外召回排序共享计算 | B组完成全文核验；v1 05-29而非编号6月 |
| HELIX | https://arxiv.org/abs/2609.37183 | 补候选条件交互与可复用序列联合扩展 | B组完成全文核验 |
| PinEqualizer | https://arxiv.org/abs/2607.22518 | 补全漏斗冷启探索及评价 | C组完成全文核验 |
| OneRetrieval | https://arxiv.org/abs/2606.13533 | 补可控属性SID与多路召回接口 | C组完成全文核验 |
| ACT | https://arxiv.org/abs/2611.00323 | 补唯一作者token与SID碰撞的反向比较 | 主编全文/附录已读，v1首发10-30 |

## 本轮候选、范围外与排除

| 条目 | 原始来源/日期证据 | 本轮状态和原因 |
|---|---|---|
| ChronoID 2606.14260 | https://arxiv.org/abs/2606.14260 ，v1 06-12；新下载HTML含Meta MRS与大学署名 | 时间符合；读取身份/摘要和设计概览，尚未完整核实验验，列待深读。不可据Meta署名称Meta上线。与DTE时间编码所在层不同 |
| User Embeddings are Superpositions…2611.08487 | https://arxiv.org/abs/2611.08487 ，HTML v1 11-05；Amazon | 新近可解释用户表示、自然语言人群检索；已核身份/摘要，未全读实验，列待核验候选，不算52篇 |
| Amazon End-to-end user and item embeddings | https://www.amazon.science/publications/end-to-end-user-and-item-embeddings-specializing-retrieval-representations-for-ranking | 官方RecSys2026线索，检索摘要提无微调表示AB与下游微调；首次公开日/完整方法结果未核，会议候选。不能凭摘要合并为一个线上方案 |
| Amazon SPREE | https://www.amazon.science/publications/aligning-recommendations-with-user-popularity-preferences | FAccT2026，推理期activation steering；官方仅年份，首次公开是否窗口内待查，未纳详细主集 |
| Microsoft Learning Better Reasoning for Generative Recommendation with Semantic IDs | https://www.microsoft.com/en-us/research/publications/ | 官方目录9月条目；作者归属、原始版本和上线未核，候选；不因为收在MS网站就认定MS生产 |
| Microsoft ICL-Bandit | https://www.microsoft.com/en-us/research/page/40/?taxonomy=msr-locale&term=en_us | 官方9月目录广告相关性标注，全文/首发待核；不能与直接排序AB混为一类 |
| Apple Amortizing Maximum Inner Product Search with Learned Support Functions | https://pr-mlr-shield-prod.apple.com/research/faster-retrieval | 11-05官方介绍ICML2026；介绍日期不是论文首发。主要通用MIPS/RAG，推荐实验证据与首发待核，不为企业平衡强纳 |
| Meta ETT 2610.02057 | https://arxiv.org/abs/2610.02057 | 本轮重新取abs与旧式HTML；abs仍标withdrawn，原因涉及不完整/错误实验数据，继续排除；可见旧正结果不作证据 |
| LinkedIn An Industrial-Scale Sequential Recommender 2602.12354 | https://arxiv.org/abs/2602.12354 | 首发2月范围外，必要时仅作已有顺序排序baseline；不因2026修订再计新论文 |
| SORT、SOLAR、OneTrans、OneRecThink、MemRec等 | 旧范围表记录各自范围外首发，必要时通过原文引文回看 | 作为技术脉络，不列当前新论文；本轮未重新核每个背景论文所有数字，旧排除记录不冒充当前完整原文复核 |

其他国内待查候选见分组coverage记录（如TGR、UniRank、RoFiGR等）。这是一份以可迁移机制和企业一手证据为优先的系统选读，不是2026全部推荐论文目录。对未完成全文核验的候选不提供精确收益结论，亦不把候选计入详细篇数。
