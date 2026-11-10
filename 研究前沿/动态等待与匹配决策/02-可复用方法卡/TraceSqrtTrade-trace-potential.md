---
type: "方法"
topics: ["动态等待与匹配决策", "用双侧后验标准差降幅权衡成交与信息"]
status: "维护中"
created: "2026-11-10"
module_id: "arxiv:2611.09615/trace-potential"
source_paper_id: "arxiv:2611.09615"
source_version: "v1"
local_validation: "未验证"
---

# 用双侧后验标准差降幅权衡成交与信息

来源 [[研究前沿/动态等待与匹配决策/01-论文原文与精读/TraceSqrtTrade/精读|Contextual Search and Bilateral Trade with a Trace-Square-Root Potential]]。

**输入输出。** 已知固定线性参数的联合先验、可观察上下文、单一待报价格和历史成交位。输出当前共同报价，反馈后得到新的联合后验。跨轮重复利用同一对隐参数。

**机制。** 令 $L(p)=\mathbb E[(B-S)_+(1-Y(p))]$，$D_Z(p)=\mathrm{sd}(Z)-\mathbb E[\mathrm{sd}(Z\mid Y(p))]$。Lemma 3.1 保证存在 $L(p)\le 2^{11}(D_S+D_B)$ 的价。算法 3 选择该类报价，按 $Y$ 实现的事件（失败含两种原因）联合条件化。后验是联合的，势函数却是两边边缘协方差的平方根迹之和。不存在离线训练环节；计算后验和选择下轮价格有模型依赖。

**证据与依赖。** §3.1 式 (14)–(19)、Thm. 3.2 给全时域后悔上界；若没有先验，§3.2 算法 4 需同时指定两个后继状态，作者明确未提供高效求解保证。无现实数据。可迁移到一位反馈下重复接触同一潜在类型的探索；审批或等候事件若混入额外拒绝原因，需在观测模型中显式加入。

代码核验。作者提供 Lean 4 形式化，TraceSqrt.lean、Audit.lean、TradeLottery.lean 对应入口及主要定理。仓库记录的是数学证明；未核到在线交易实现或实测数据，未在本地编译。[作者仓库](https://github.com/renatoppl/trace-square-root)

候选实验 [[研究前沿/动态等待与匹配决策/03-实验假设与结果/TraceSqrtTrade-one-bit-welfare|同为一次成交反馈，利用后验下降能否减少错过的交易剩余]]。
