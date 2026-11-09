# B组覆盖补检（2026-11-07，Asia/Shanghai）

范围：意图/召回接口、生成目标/解码、排序训练/跨阶段协同。按一手首次公开落在2026-05-01至2026-11-07纳入；公司归属与实际部署分开。以下是针对性补检，不宣称穷尽。

|时间|实际查询/入口|一手候选与处理|
|---|---|---|
|2026-11-07约01:24|`site.arxiv.org 2026 Pinterest unified retrieval ranking UniPinRec`；以及root覆盖交接的原文入口|[UniPinRec v1](https://arxiv.org/abs/2606.00422v1)：新增完成全文复核。首发2026-05-29，不按2606编号推断为6月；RecSys 2026。实际部署L0+L1、保留L2，见独立笔记。|
|同轮|`site.arxiv.org 2026 Tencent generative recommendation value alignment`|[UniVA v2](https://arxiv.org/abs/2605.05803v2)：已分配方法，复核而不重复新增。搜索混入第三方结果，不用第三方内容作数字证据。|
|同轮|`site.arxiv.org 2026 ByteDance HELIX recommendation sequence feature interaction`|[HELIX v2](https://arxiv.org/abs/2609.37183v2)：新增完成17页PDF含附录A/B。v1 9月29日、v2 9月30日；HTML 404，正常改用公开PDF。封面8月27日不是已证公开日期。|
|2026-11-07约01:25|`2026 Pinterest UniPinRec retrieval ranking`，限定arxiv.org|结果未形成新的可独立纳入方法；UniPinRec使用当前原文及root本轮新快照补足，不把搜索排序视为穷尽。|
|同轮|`2026 Kuaishou latent reasoning query recommendation`，限定arxiv.org|[OneLatent](https://arxiv.org/abs/2610.30675v2)与[WhisperRec旧ID](https://arxiv.org/abs/2607.26621v1)同方法族，去重只算一次；[KUAISHOU Explorer Challenge](https://arxiv.org/abs/2609.39828)为比赛/多方法总览候选，未在B组冒列成新增完整深读，交主编总覆盖表判断。|
|同轮|`2026 Tencent generative recommendation value`，限定arxiv.org|[TGR报告](https://arxiv.org/abs/2609.00986)包含CCFormer及BARGE/HiGR/Reason；CCFormer已有独立最新v2，其他分支归总图去重/覆盖处理，本组未读整报告不计完成。搜索同时返回2024旧文，按首发窗口排除。|

新增完成数：2（UniPinRec、HELIX）；原分配13篇，合计15篇。候选总览/比赛报告不混入这15篇的完整阅读计数。OneLatent跨ID改名只计一个方法。

本轮来源：`sources/access_log.json`记录原13篇及旧ID版本重新下载；UniPinRec复制root本轮抓取文件，并在`source_access_manifest.json`记录其本轮provenance；`new_sources/access_log.json`与`latest_check/access_log.json`保留HELIX HTML失败记录，PDF成功下载及SHA256见同一manifest。PDF文字来自pypdf，以17页页码定位；HTML数式以MathML alttext避免重复读数。原vault只读保留。

未解覆盖边界：这一组按指定方法范围分工，未把搜索命中等同完整复核；TGR/比赛总览和其他组候选请以主编最终去重清单为准。没有新增未经阅读全文的线上收益条目。
