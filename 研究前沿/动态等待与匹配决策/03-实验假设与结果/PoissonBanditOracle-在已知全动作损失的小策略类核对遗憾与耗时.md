---
type: "实验"
topics: ["研究前沿", "动态等待与匹配决策"]
status: "维护中"
created: "2026-11-14"
paper_id: "arxiv:2611.17109"
version: "v1"
experiment_id: "PoissonBanditOracle-H1"
source_papers: ["arxiv:2611.17109"]
experiment_status: "待设计/未运行"
local_validation: "未运行"
---

# 在已知全动作损失的小策略类核对遗憾与耗时

[[研究前沿/动态等待与匹配决策/02-可复用方法卡/PoissonBanditOracle-用离线成本敏感优化器实现有探索保证的动作选择|用离线成本敏感优化器实现有探索保证的动作选择]] · [[研究前沿/动态等待与匹配决策/01-论文原文与精读/PoissonBanditOracle/精读|论文依据]]

先生成有限策略类、独立上下文及预固定损失表，每轮只交给算法所选动作的损失，比较均匀探索和枚举基准。评估多轮累计遗憾、每轮 oracle 调用及墙钟时间。若随规模耗时超过已确认的时限，则不立线上方案；具体 K、时限、预算待确认。

状态为未运行。数据版本、预算、代码提交、日志与实测结果待确认。
