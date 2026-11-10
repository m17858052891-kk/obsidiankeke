---
type: "实验"
topics: ["动态等待与匹配决策", "候选假设"]
status: "维护中"
created: "2026-11-10"
experiment_id: "arxiv:2611.09611/deadline-batch-fill"
experiment_status: "待设计/未运行"
run_at: null
result: null
logs: null
---

# 整件跳过规则对分档容量和硬截止合批的作用

来源模块 [[研究前沿/动态等待与匹配决策/02-可复用方法卡/TimelyThrifty-trigger-edf-skip|截止期触发并跳过放不下件的整批贪心]]。原文见 [[研究前沿/动态等待与匹配决策/01-论文原文与精读/TimelyThrifty/精读|Online Timely Bin Packing Revisited: A Simpler Algorithm with Optimality in Special Cases]]。

**假设。** 固定每次发运成本且有待定池时，完整扫描保留的可用容量，能减少两档大小输入相对 Discrete-Greedy 与遇阻停止版本的箱数；改善幅度依赖窗口重叠和体积组成。

**设计。** 以小型合成轨迹匹配相同到达、体积、时限与随机种子，比较 Thrifty-Greedy、原文 Discrete-Greedy 和触发相同但遇首个不适配件就封箱的消融。事先划分等大、严格两档、连续体积和定理 4 的紧例；同一轨迹精确枚举可行批次，用集合划分计算最优。任一策略不可见未来。扫描、单批延迟、峰值待定件数均固定口径。

**检验。** 无逾期及容量违规作为前置条件。报告箱数/最优、装载率、等待 P95、每次触发扫描量，分层输出轨迹配对区间。等大组与离线箱数一致、两档比值不超过 1.5 是实现校验；紧例应出现 $2N/(N+1)$。若完整扫描未减少目标组箱数或超过可接受的运行预算，则迁移假设未获支持。预算与样本量待定，离线只作评价。

项目、代码版本、数据快照、配置和阈值待确认。尚未运行，无本地结果。
