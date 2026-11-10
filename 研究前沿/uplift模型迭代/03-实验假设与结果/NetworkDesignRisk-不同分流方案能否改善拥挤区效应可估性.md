---
type: "实验"
topics: ["研究前沿","uplift模型迭代"]
status: "维护中"
created: "2026-11-10"
paper_id: "arxiv:2611.08560"
experiment_id: "NetworkDesignRisk:exp"
experiment_status: "未运行"
---

# 不同分流方案能否改善拥挤区效应可估性

[[研究前沿/uplift模型迭代/02-可复用方法卡/NetworkDesignRisk-干扰网络中的联合曝光与设计风险|干扰网络中的联合曝光与设计风险]] · [[研究前沿/uplift模型迭代/01-论文原文与精读/NetworkDesignRisk/精读|NetworkDesignRisk 精读]]

## 假设、数据与最小改动

取真实或合成的小型司机共享图，固定处理比例、同一目标效应，枚举可行分配和联合缺失事件；比较独立分流与分簇分流。

## 基线、指标和失败判据

在已知真值的多组结果表上比较最大 MSE、偏差与方差；若相近随机预算下没有改善，或轻微改曝光定义即反转，则不推广。

项目数据可用性、预算与时限待确认。未运行，无本地结果或训练日志。
