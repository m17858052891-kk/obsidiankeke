# C组补充检索与覆盖边界

检索与复核日期：2026-11-07（Asia/Shanghai）。窗口2026-05-01至2026-11-07，首次公开优先。以下是定向补查，不声称穷尽工业推荐论文。检索命中不等于已读正文；详细核验数为原分配13篇+新增2篇=15篇，其中Amazon Playlist仅会议窗口补充、首次公开待核验。

|时间/查询|一手入口与命中|处理|
|---|---|---|
|本轮01:14左右；`site:arxiv.org 2026 LinkedIn "recommendation" "pre-ranking"`|[CC Retriever](https://arxiv.org/abs/2609.22441)；早期LinkedIn causal retrieval 2602.12354|CC已读；2月编号候选实际首发窗口外，不并入本轮方法数；搜索仅线索，按版本页核日期|
|同批；`site:arxiv.org 2026 Pinterest "exploration" "utility"`|[PinEqualizer](https://arxiv.org/abs/2607.22518)及官方工程blog|PinEqualizer经root补检指定，完整读本轮重新下载原文，新增一篇；工程blog不当论文计数|
|同批；`site:amazon.science 2026 "playlist" "curation"`|[Amazon Playlist官方页](https://www.amazon.science/publications/llm-based-playlist-curation-a-music-reasoning-approach-at-scale)|官方页只有年份，PDF MuRS会议日明确；不把会议日补成首次公开|
|同批；`site:arxiv.org 2026 Kuaishou "OneRetrieval"`|[OneRetrieval](https://arxiv.org/abs/2606.13533)|后经root指定新增，重新取得v2全文；首发6月11日、修订6月22日，完整方法/实验已读|
|上述搜索的相关命中|[TGR](https://arxiv.org/abs/2609.00986)，标题为TGR: Advancing Industrial Recommendation from Generative-Paradigm Ranking toward Unified Generation and Reasoning|透明候选，通知root；本组未全文复核，不进入15篇数，不借其摘要作方法关系证据|
|最终复核时；`site:arxiv.org 2026 Pinterest "PinEqualizer"`、`site:arxiv.org 2026 "OneRetrieval"`|arXiv两篇abs再次命中|分别确认7月24日、6月11日，排除二手站点可能出现的PinEqualizer 7月23日时区/索引差异|
|最终复核时；`site:arxiv.org 2026 Netflix "recommendation" "ranker"`|[GenRec](https://arxiv.org/abs/2608.10257)|与已有ID一致，无重复新增|
|最终复核时；`site:amazon.science 2026 "playlist curation"`|[Amazon作者页](https://www.amazon.science/author/zhonghao-luo)还列Scalable Explainability for Music Recommendation via Precomputed Reasoning；[官方音乐列表](https://www.amazon.science/publications?p=1&q=music)列MusicContainerNet|候选仅官方年份2026，首次公开月份/正文方法/上线证据待查；明确不纳入本轮已详细核验数，已通知root|

原文访问：初始13篇abs+版本全文共26项本轮HTTP200，见sources/access.json；OneRetrieval见sources/additional_access.json。PinEqualizer使用root同轮重新下载的abs/HTML快照并复制到本组，原路径与hash见sources/shared_snapshot_provenance.json。未使用旧work/research文本作为本轮原文证据。

文本抽取对HTML数学读取MathML alttext并跳过重复展示文本，避免同一数值/公式重复拼接；Amazon PDF使用pypdf提取，关键表格逐列核对。不能以正则关键词出现替代逐篇阅读。

覆盖缺口：公司官方站点无日期或论文未公开时不能确认窗口；标题变更按ID去重；作者单位与线上平台分别记录；全文未读的新候选仍保留候选身份，不宣称“已覆盖所有企业/路线”。
