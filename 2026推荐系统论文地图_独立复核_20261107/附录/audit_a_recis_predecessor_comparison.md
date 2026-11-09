# RecIS 2025/2026 一手前序比对

核查日：2026-11-07。**结论：2026篇为独立编号的新报告，RecIS框架与多项基础优化2025已公开；缺逐项增量声明/旧版对照，不能确认全套为窗口内首次提出的新方法。单列补充，不计严格新方法。**

| 维度 | 2025前序 | 2026所读报告 | 判定 |
|---|---|---|---|
| 身份 | [2509.20883v1](https://arxiv.org/html/2509.20883v1)，2025-09-25，RecIS Team/同团队 | [2610.41457v1](https://arxiv.org/html/2610.41457v1)，2026-10-30，Hua Zong等 | 同框架/仓库，独立arXiv编号，非同编号版本更新；不能仅因换题名算框架首发 |
| 标题/摘要重点 | Sparse to Dense, A Unified Training Framework for Recommendation Models；PyTorch统一稀疏稠密、MBU和工业可用性 | Unifying Sparse and Dense Computation for Efficient Recommendation Training；GPU数据流、跨算子/设备/迭代 | 表述与强调改变，不能自动等同新机制 |
| 已有机制 | §2.2有融合、hash分片/All-to-All、向量化、warp归约、异步I/O | §3仍包含这些 | 不能把上述组件归为2026首次 |
| 更明确的技术描述 | 未提供2026式节点内合并/同rail往返与完整逆映射公式；I/O异步较概括 | §3.2分层通信、ΔS公式、forward CSR唯一写者/backward wave差别；§3.3参数无关PRE_FORWARD和争用约束 | 可确认是2026文新增/细化的披露内容；不能确认实现何时首次出现或其原创新颖性 |
| 实验 | §3以H20的MBU算子与MSE/LMA为主；MSE32H20，LMA64H20，TensorFlow/TorchRec比较 | §4广告/搜索/Lazada在PPU/H20/L20，TorchRec/PICASSO；更细通信/累加消融与质量曲线 | 实验对象/硬件/基线扩大，非2025同配置直接升级对照 |
| 缺口 | 无新旧RecIS软件版本线索可直接对齐 | 未提供2025 RecIS checkpoint/commit对照或明确逐项首次时间 | “新增披露”与“新增发明”必须分开 |

本轮重新下载2025 abs/HTML，正文重点比对§1摘要/贡献、§2系统模块、§3实验；2026全文此前已深读。前序仅用于身份/范围比对，不计第16篇完整深读。来源快照与哈希见 `sources/predecessor_access_log.json`。官方仓库[alibaba/recis](https://github.com/alibaba/recis)用于确认同一框架，不从当前仓库推断每项优化的首次上线日期。
