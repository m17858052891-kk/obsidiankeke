# A组覆盖补检记录

检索日：2026-11-07（Asia/Shanghai）；窗口2026-05-01—11-07。原分配13篇，本轮新增ConnectionMind、RecIS，共15篇完整笔记。RecIS属于窗口内新报告、窗口外既有框架，增量新颖性待核，不计严格新方法。补检不是穷尽声明；候选检索命中不等于已完整审读。

| 查询 / 查验动作 | 一手入口与结果 | 处理 |
|---|---|---|
| `site.arxiv.org 2026 Alibaba recommendation "semantic" "May"` | arXiv方法检索；[dynamic single-level codebook 2608.21012](https://arxiv.org/abs/2608.21012)属其他组覆盖 | 去重，不新增A组篇数 |
| `site.arxiv.org 2026 Kuaishou recommendation "rationale" OR "long sequence"` | SARA、长历史路线；[VaLiDRec 2607.25209](https://arxiv.org/abs/2607.25209)为学术方法候选，未建立工业部署 | 不加入已审读工业清单；可作方法补充候选 |
| `site.icde2026.github.io GALA generative aligned learning` | [官方program](https://icde2026.github.io/program_details.html)：05-05 I&A-2 13:30–15:00，Eleme旧题名、同作者 | 与Shangou版本去重，补精确展示日；更早全文时间仍未知 |
| `site.research.google 2026 "Beyond Item IDs"` | 未找到比[arXiv原站](https://arxiv.org/abs/2606.07546)更能消解05-04/2606矛盾的一手记录 | 保留原站日期，不推导具体产品名 |
| 官方CIKM program及 `site.cikm2026.diag.uniroma1.it "Context-Aware Latent Reasoning"` | [官方program](https://cikm2026.diag.uniroma1.it/program/)前次访问可见CaLR；本次web再开cache miss。[作者代码](https://github.com/Ak4ne-windsky/CaLR)为后续核查入口 | 候选为USTC/Kuaishou、KuaiLite七日实验线索；首发日期和全文尚未完成，**不计完整深读** |
| `site.arxiv.org "ConnectionMind" "Meta"` | [2608.10187](https://arxiv.org/abs/2608.10187)，08-10；正文有Meta图候选与混合LLM/GNN生产描述 | 已新增完整P3笔记；±区间含义、具体产品名未知 |
| `site.arxiv.org "RecIS" "Unifying Sparse"` | [2610.41457](https://arxiv.org/abs/2610.41457)，10-30；[官方仓库](https://github.com/alibaba/recis) | 已新增完整P5笔记，训练效率不推出CTR/GMV |
| RecIS同名/前序补检 | [2509.20883](https://arxiv.org/abs/2509.20883) 2025-09-25；本轮重下[全文](https://arxiv.org/html/2509.20883v1)对比身份、模块与实验 | 重要范围修正：2026独立报告不代表框架新提出；见recis_predecessor_comparison.md |
| 相同缩写GALA排歧 | [2608.13741](https://arxiv.org/abs/2608.13741)为时间序列相关同名线索 | 不是本篇推荐GALA，不合并 |
| MoMoREC / CapsID线索 | MoMoREC存在AAAI早期出版入口；CapsID只得二级线索 | 前者窗口资格待按首发核查、后者尚无足够一手阅读；均不计完整篇数 |

访问与资料规则：13篇abs均本轮访问；12篇版本HTML成功，DTE v2 HTML404后改读PDF。KuaFu同时下载PDF核对宏未展开的作者单位。ConnectionMind使用root本轮新快照（不是旧缓存）；RecIS本轮自行下载。主访问记录见 `sources/access_log.json`，补充与前序见 `sources/supplemental_access_log.json`、`sources/predecessor_access_log.json`。没有把旧笔记当本轮原文。原vault未修改。
