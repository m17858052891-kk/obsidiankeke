---
type: "方法"
topics: ["研究前沿", "方法精读"]
status: "维护中"
created: "2026-11-06"
module_id: "poissonsl:hazard-stacking"
paper_id: "arxiv:2611.03256"
local_validation: "未验证"
---

# Poisson 折外风险率堆叠与一致竞争风险概率

来源：[[研究前沿/面向决策的履约建模/01-论文原文与精读/PoissonSL/精读|PoissonSL 精读]] · [原文](https://arxiv.org/html/2611.03256v1)

## 输入与输出

输入基线特征、事件/删失时间及原因；输出各原因 hazard、生存概率与 CIF。

## 计算、训练与推理流程

分段展开事件计数与暴露时长 → 在各折训练多个 Poisson 风险率模型 → 收集折外 log-hazard → 用 Poisson 似然拟合跨时间共享的元系数 → 重训基模型 → 由总风险率积分得到各原因 CIF。

## 效果证据与归因

§8 模拟支持非线性库的价值；§9/Table 3 时间外测试显示有竞争力但不总胜出。整体堆叠结果不等于每个基学习器的独立增益。

## 最小采用单元与耦合依赖

最小单元是 person–time 似然、折外元学习和 CIF 组合三者；可替换基模型。时间划分与 exposure offset 不可省略。原文系数非 simplex 约束。

## 数据假设与失败边界

需条件独立删失；稀有原因可能不适合大库。离散化 covariates 与无损聚合应区别；任何跨折统计都会带来泄漏。

## 潜在迁移（推断）

用于完成/取消等互斥事件的时间分布预测，并向优化器提供概率；动作因果意义需另外识别。

## 代码与本地验证

已核验[作者仓库](https://github.com/gpitt71/poissonsuperlearner)，commit `04f85ed39f8798cd9d137ae0031b8fc2f13c0e70`；入口：[R/superlearner.R](https://github.com/gpitt71/poissonsuperlearner/blob/04f85ed39f8798cd9d137ae0031b8fc2f13c0e70/R/superlearner.R)；[R/pch_absolute_risk.R](https://github.com/gpitt71/poissonsuperlearner/blob/04f85ed39f8798cd9d137ae0031b8fc2f13c0e70/R/pch_absolute_risk.R)。已读取入口声明/关键片段，未审计全部实现、未安装运行。 [[研究前沿/面向决策的履约建模/01-论文原文与精读/PoissonSL/代码核验|核验记录]]

无本地实验结果。

## 待验证想法

[[研究前沿/面向决策的履约建模/03-实验假设与结果/2026-11-06-竞争风险的折外堆叠|竞争风险的折外堆叠（未运行）]]
