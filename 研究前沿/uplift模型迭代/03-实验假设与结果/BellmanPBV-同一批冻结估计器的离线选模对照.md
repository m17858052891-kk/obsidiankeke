---
type: "实验"
topics: ["研究前沿", "uplift模型迭代"]
status: "维护中"
created: "2026-11-14"
paper_id: "arxiv:2610.35748"
version: "v2"
experiment_id: "BellmanPBV-H1"
source_papers: ["arxiv:2610.35748"]
experiment_status: "待设计/未运行"
local_validation: "未运行"
---

# 同一批冻结估计器的离线选模对照

[[研究前沿/uplift模型迭代/02-可复用方法卡/BellmanPBV-用候选差异检验价值模型的残差|用候选差异检验价值模型的残差]] · [[研究前沿/uplift模型迭代/01-论文原文与精读/BellmanPBV/精读|论文依据]]

在有独立高精度策略真值的模拟环境切分训练和验证轨迹，保持候选及随机种子一致，对比 PBV、有无惩罚、LSTD 和平方 TD。报告模型被选择后的价值绝对误差、低覆盖分层与时耗。若在留出环境中排序反向或改善只在单一覆盖档出现，则缩小适用范围。

状态为未运行。数据版本、预算、代码提交、日志与实测结果待确认。
