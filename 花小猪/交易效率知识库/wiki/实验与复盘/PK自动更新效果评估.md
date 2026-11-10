---
title: "PK 模型自动更新效果评估"
type: analysis
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_ids:
  - "cooper:knowledge:2203934336165"
  - "cooper:knowledge:2206703206886"
related:
  - "../来源/b005-evidence-2203934336165.md"
  - "../来源/b005-evidence-2206703206886.md"
---

# PK 模型自动更新效果评估

## 离线证据

两周训练相对一周训练仅带来 0.0006 AUC 差异；跨日新旧模型表现接近，特殊节假日则出现共同下滑。这支持“PK 分布常态偏移较小、定期更新增益有限”的假设，但不能证明无需更新。

## 线上证据

2026 年 5% 更新实验的成交率、完单和 GMV 均未显著改善。两版迭代都造成 API 完单显著上升、宏鹄完单显著下降；第二版还出现应答率显著下降。自动更新因此更像稳定性维护机制，而非已证明的增长机制。

## 评估建议

- 核心效率、漏斗护栏与商家份额必须共同验收。
- 模型更新时更换分流种子会削弱跨周期可比性，应保留稳定锚点组。
- 节假日单独评估，避免平均 AUC 掩盖结构性退化。

