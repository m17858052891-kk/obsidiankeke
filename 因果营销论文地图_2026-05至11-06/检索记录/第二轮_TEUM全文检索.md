# TEUM 第二轮来源审计（2026-11-07）

## 取得的材料

| 材料 | 公共来源 | 本地保存 | 结果／用途 |
|---|---|---|---|
| DOI 出版元数据 | https://api.crossref.org/works/10.1145/3770855.3817649 | 既有 `work/teum_crossref.json` | 题名、作者机构、页码、online 2026-08-08；created 2026-08-06；没有摘要/全文 |
| 官方论文目录 | https://kdd2026.kdd.org/papers/ | Web 读取（既有全目录另在 work） | 题名与作者署名一致，Research track |
| OpenAlex 作品条目 | https://api.openalex.org/works/https://doi.org/10.1145/3770855.3817649 | `openalex.json` | 具有 abstract_inverted_index，已恢复完整摘要；has_fulltext=false、PDF/XML均false、仅ACM landing location |
| 完整摘要转录 | 同上 | `abstract_openalex.txt` | 三模块与部署场景；无实验数字；明确仅为索引转录，未拿到一手正文对照 |
| Ziming Wu ORCID | https://pub.orcid.org/v3.0/0000-0003-3348-7727/person | `orcid_ziming.json` | 无 researcher URLs、无公开稿 |
| Peicheng Yao ORCID | https://pub.orcid.org/v3.0/0009-0007-3330-7374/person | `orcid_peicheng.json` | 无 researcher URLs、无公开稿 |
| 作者 LinkedIn 公开搜索记录 | https://cn.linkedin.com/in/peichengyao/zh-cn | Web search snippet | 作者称co-first author并与腾讯导师完成；不作为方法正文依据 |
| 腾讯研究团队公开页 | https://socialalgo.github.io/ | Web open | 有Ziming Wu的相关公开工作，未检得TEUM链接；不推断该页覆盖作者所有论文 |
| KDD 官方完整议程 | https://kdd2026.kdd.org/full-program/ | `kdd_program.html` | 官方页面公开嵌入Whova |
| 官方嵌入的公开议程数据 | https://whova.com/embedded/event/As22EvgjdjIC7XoLbAG4Y41bA2JQnxLAEK-iJyT4y1Y%3D/ | `whova_agendas.json` | 正常公开GET成功，327056字符；本次数据无TEUM题名或DOI匹配，未取得对应摘要附件 |

Whova 读取仅使用官方嵌入页面已加载脚本所标明的 `agenda/public/get_agendas` 公共接口，没有登录，没有调用管理接口，没有添加管理员开关。公开脚本与网页留存是为证明来源链路；不把其他报告内容当作 TEUM 证据。

## 未取得的材料与检索覆盖

- ACM `https://dl.acm.org/doi/10.1145/3770855.3817649` 与 `/doi/pdf/` 均403；未绕过访问控制。
- Semantic Scholar DOI API 返回429；未将缺失解读为没有论文。
- 精确题名、TEUM+uplift、TEUM+作者、Team Effect-aware、DOI、中文“腾讯 TEUM／团队因果”等公开检索没有定位全文。
- 对 arxiv.org、scholarbank.nus.edu.sg、github.com、openreview.net、tencent.com、SSRN 做题名定向搜索，未定位作者稿。
- 搜索出现 Paper Digest 摘要摘句，与 OpenAlex 摘要相容，但不将二手摘要重述作为新的独立实验验证。
- DBLP只有DOI入口，Moonlight显示review pending，均未补齐正文。

## 本轮交付给主审的结论

主卡 `TEUM.md` 可以替代旧“仅题名”的待补卡，但证据级别必须写成“完整摘要索引转录／全文待补”。新增信息是三个模块（team awareness、decoupled uplift forecasting、GAN distillation）和两数据集／FPS部署的定性范围；没有新增任何可用于收益榜的数值。

另完成 BUOPLR 独立复核：`review_buoplr.md`，以及已运行通过的最小反例枚举 `buoplr_counterexample.py`。已检查主审 `work/round2/buoplr/BUOPLR.md` 的关键结果、方法描述、最强基线重算、单调性与RCT边界，未发现需纠正的关键错误；主审卡使用更贴近原文经验范围的1.5倍强样式反例，其37.5%恒定损失正确。


> 以上为检索时的工作记录，文中临时文件名属于研究工作区留痕。最终交付路径、证据等级与阅读入口以 [第二轮补全文与复核](../08-第二轮补全文与复核.md) 为准。
