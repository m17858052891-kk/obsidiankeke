---
type: "方法"
topics: ["动态等待与匹配决策", "单调风险率下用成交等待轮数估计凸损失"]
status: "维护中"
created: "2026-11-10"
module_id: "arxiv:2611.08173/mhr-convex"
source_paper_id: "arxiv:2611.08173"
source_version: "v1"
local_validation: "未验证"
---

# 单调风险率下用成交等待轮数估计凸损失

来源 [[研究前沿/动态等待与匹配决策/01-论文原文与精读/BilateralPrices/精读|Regret Bounds for Profit Maximization in Bilateral Trade: Learning the Best Posted-Price Mechanism]]。

**输入输出。** 两侧估值在一轮内独立且跨轮 IID；需要前文定义的方向性 MHR。输入已选 $(p,q)$ 与成交位序列，输出供随机凸 bandit 使用的 $-\log\mu(p,q)$ 估计。

**流程。** §5 先用结构化稀疏采样找到包含最优附近报价的安全凸域；在域中固定一个报价重复到首次成交。其前的失败次数可算调和数 $H_{N-1}$，加上 $-\log(q-p)$ 作为损失。实际收集一个损失观测所用的多轮均计入遗憾。每轮面对不同买卖双方，和等待某一订单响应是两种过程。

**证据。** 命题 3.2 给出目标凸性，Claim 5.5 分析几何等待的估计量，定理 5.1 给筛选、估计与凸优化联用的平方根阶。独立与 MHR 均应核验；低交易率时，估计延迟和极端等待次数会成为瓶颈。只满足正则时需改用 §6 辅助函数，原保证不能直接套用。

代码核验。核查 arXiv 摘要页、PDF/HTML 正文与公开题名检索，尚未核到作者发布的实现仓库。算法入口见文中伪代码。

候选实验 [[研究前沿/动态等待与匹配决策/03-实验假设与结果/BilateralPrices-assumption-shift|双边接受相关时，基于独立性的报价会损失多少利润]]。
