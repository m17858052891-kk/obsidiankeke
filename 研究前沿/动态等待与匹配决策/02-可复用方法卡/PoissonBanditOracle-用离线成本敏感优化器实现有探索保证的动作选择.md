---
type: "方法"
topics: ["研究前沿", "动态等待与匹配决策"]
status: "维护中"
created: "2026-11-14"
paper_id: "arxiv:2611.17109"
version: "v1"
module_id: "PoissonBanditOracle-M1"
source_papers: ["arxiv:2611.17109"]
local_validation: "未运行"
---

# 用离线成本敏感优化器实现有探索保证的动作选择

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/PoissonBanditOracle/精读|只有所选动作反馈时，大策略类的探索代价能降到多少？]]

输入候选策略类、历史所选损失与采样概率、新上下文样本和精确 oracle。输出动作分布与更新后的估计损失。整套扰动、概率近似和更新共同支持定理，单独加随机噪声没有这项保证。可先以小策略类枚举提供精确 oracle 和参照最优值。

**效果证据与归因。** 定理 1 在独立同分布上下文、预先固定损失与精确离线优化 oracle 下给出近平方根的期望遗憾界。原文提供形式化证明，未报告在线延迟实验。 [[研究前沿/动态等待与匹配决策/01-论文原文与精读/PoissonBanditOracle/精读|原文对照及限制]]

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/PoissonBanditOracle-在已知全动作损失的小策略类核对遗憾与耗时|在已知全动作损失的小策略类核对遗憾与耗时（未运行）]]

**实现入口。** poisson_playout_lean.zip 提供理论证明文件，论文算法 2 描述策略计算。 [作者仓库](https://github.com/kbanihashem/bandit-oracle-lean)
