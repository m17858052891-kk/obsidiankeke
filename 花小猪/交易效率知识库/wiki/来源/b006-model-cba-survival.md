---
title: "B006 模型来源：CBA离散生存模型"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: draft
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2209313959219", "cooper:knowledge:2209647178947", "cooper:knowledge:2209844711804", "cooper:knowledge:2209845236664"]
related: ["../模型/cba应答前取消模型.md"]
---

# B006 模型来源：CBA离散生存模型

当前详细版本把 CBA 建成 0—300 秒的一秒离散 hazard 模型，显式处理“先应答后不可再观察取消”的删失。输入契约为 10 个类别特征和 84 个连续特征，包含订单、乘客画像与历史行为、供需等；字段名称、顺序和预处理必须与配置锁定。

结构包含低秩特征交叉、订单编码、时间 Embedding 与订单—时间交互，并从 60 秒后施加 hazard 不下降的硬约束。当前实际训练目标只有删失感知的生存 NLL，time-AUC 排序与 CDF anchor 辅助项权重为 0。

保存的一次单轮离线评估覆盖 13,897,452 个订单和约 8.89 亿“订单×在险秒”机会。相对逐秒固定基线 BSS 为正但较小，早期好于尾段；4—6 秒峰值被低估，180 秒后若干窗口出现高估和负 BSS。随机种子未固定、仅 1 epoch、缺少正式累计时间依赖 AUC和完整发布包，因此只能视为方向性离线证据，不能推导线上收益。

## 原始来源

- [CBA离线结果2](../../raw/cooper/knowledge-2209313959219.md)（sha256 `4aa5a4b5f85dd1fe14894dd23520b4d353ac237a4084156d1a0cabb438215185`）
- [CBA模型特征](../../raw/cooper/knowledge-2209647178947.md)（sha256 `089eea51d30151b26fedf7c23fda7879d43e30caa72904ce6824967e7c7dfdb6`）
- [CBA离散时间生存模型](../../raw/cooper/knowledge-2209844711804.md)（sha256 `3ab1d8b2f74b1bb7aa5dfeb9fd6039d00ade7d561dcc6563cac2b3cddf6d73a6`）
- [CBA模型离线结果](../../raw/cooper/knowledge-2209845236664.md)（sha256 `1141c8656067c197ff7988b77be97ae20227974a081d02e92b7bc904b18daaba`）

