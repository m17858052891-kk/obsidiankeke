---
type: "方法"
topics: ["动态等待与匹配决策", "带停止罚项的生成算子 q 函数"]
status: "维护中"
created: "2026-11-09"
module_id: "arxiv:2611.07362/generator-q"
source_paper_id: "arxiv:2611.07362"
source_version: "v1"
local_validation: "未验证"
---

# 带停止罚项的生成算子 q 函数

来源 [[研究前沿/动态等待与匹配决策/01-论文原文与精读/StructuredStoppingQ/精读|Continuous-time q-Learning for Finite-Horizon Portfolio Choice with Optimal Stopping in Jump-Diffusion Markets]]。

**输入输出。** 输入时点、状态、当前可选控制、立即行动价值及一类可微的跳扩散动力学，输出继续控制和停止区域。价值模型和未知动力学参数共用一个结构化动作值。

**计算与时点。** §2 式 (5)–(7) 把 $K(g-V)^+$ 写成二元动作；§5 式 (33)–(38) 用 $q=V_t+(\mathcal L^a_\phi+\mathcal J^a_\phi)V-\rho V+K\beta(g-V)$，在轨迹上联合拟合 $V,\phi$。奖励残差需乘保留下来的辅助状态 $R$ 与贴现。采样时用 Gibbs 策略；评估原始问题时由 $V\le g$ 触发，否则取继续动作的最大分。$K$ 过小会使停止近似偏软，温度 $\lambda$ 也会改变估计及边界，见 §6.1.6。

**原领域证据。** 图 4 给出模拟状态上的边界一致性，表 7 给出整体效用。两只资产测试期 5,000 条重采样路径上效用均值分别高约 1.61%、13.13%，同时平均财富收益降低。未单独隔离结构化生成算子相对于同预算自由 q 网络的贡献。

**迁移推断。** 可在有可控模拟器的短时等待/触发任务比较边界恢复质量。必要条件为可表达的状态演化、已知或可估计的立即匹配价值和连续控制作用；单条历史日志未观测的反事实转移需要额外识别依据。

代码核验。本次检查论文全文、arXiv 记录和按题名检索结果，作者算法仓库入口未知。

候选实验 [[研究前沿/动态等待与匹配决策/03-实验假设与结果/StructuredStoppingQ-boundary-recovery|供需跳变时，结构化动作值能否恢复等待边界]]。
