---
type: "实验"
topics: ["动态等待与匹配决策", "候选假设"]
status: "维护中"
created: "2026-11-10"
experiment_id: "arxiv:2611.08173/assumption-shift"
experiment_status: "待设计/未运行"
run_at: null
result: null
logs: null
---

# 双边接受相关时，基于独立性的报价会损失多少利润

来源模块 [[研究前沿/动态等待与匹配决策/02-可复用方法卡/BilateralPrices-mhr-convex|单调风险率下用成交等待轮数估计凸损失]]。原文见 [[研究前沿/动态等待与匹配决策/01-论文原文与精读/BilateralPrices/精读|Regret Bounds for Profit Maximization in Bilateral Trade: Learning the Best Posted-Price Mechanism]]。

**假设。** 固定单侧边缘分布和利润口径时，买卖接受相关会破坏交叉价重建，使按独立性适配的 MHR 策略在小样本失去优势。

**最小对照。** 同一组正边缘密度，用独立与不同相关程度的联合抽样产生多组市场，跨轮独立。比较 MHR 完整方法、通用二维 CDF 方案、同预算网格 bandit；各策略只见成交位，真实估值用于计算固定最优参考。另测保持独立但违反 MHR 的场景，区分两个假设。固定价差区间、价格权限、样本预算与调参划分。

**评估。** 主指标为留出市场上相对最佳固定价格的累计利润遗憾，辅报格点概率重建误差、每个凸损失观测耗用轮数和尾部计算时延。模拟器、随机种子、样本数与 CPU 时限待设计。若预置相关程度增大后估计偏差没有上升且遗憾无相对恶化，否定假设；若置信区间跨零则保持未决。

项目、代码版本、数据快照、配置和阈值待确认。尚未运行，无本地结果。
