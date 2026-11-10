---
title: "接驾距离、ETP 与司机接驾时长的分母差异"
type: metric
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_ids:
  - "cooper:2209589579604"
  - "knowledge:2209787750049"
related:
  - "average-pickup-distance.md"
  - "avg-pickup-duration.md"
  - "normalized-passenger-etp.md"
  - "normalized-driver-pickup-duration.md"
---
# 接驾距离、ETP 与司机接驾时长的分母差异

## 三个指标不是同一口径

- 应答单接驾距离：以应答订单为观察对象的平均接驾距离，包含后续取消的应答订单。
- ETP：以完单订单为观察对象，从乘客发单到司机到达的平均等待时间。
- 司机接驾时长：司机完成每单所消耗的接驾时长总和/均值，具体归一分母需与看板确认。

因此，应答单接驾距离下降并不保证 ETP 和司机接驾时长按相同比例下降。取消率、完单样本选择、连环派结构以及预估距离和实际用时误差都会改变映射。

## 历史案例

- 召回重构材料提出：应答后取消率下降会让更多原本快速取消的订单进入长接驾过程，从而部分抵消接驾距离下降对司机时长的改善。
- 换车 V2.1 的历史点估计为归一完单口径乘客 ETP 约 -0.57%（单均 -2 秒），但归一应答口径司机接驾时长反向上升；材料把“取消订单被挽留”列为解释。
- 换车 V2.2 的历史点估计为乘客 ETP 显著 -0.78%（单均 -2.7 秒）、司机接驾时长 +0.82%（单均 +2.1 秒），二者合计 -0.09% 不显著；连环派扩换车也是候选解释。

这些案例来自历史分析，不能证明单一因果链，也不代表当前线上效果。

## 使用要求

1. 先统一应答单、完单、归一分母和是否含改派/取消。
2. 按连环派、非连环派及取消/完单拆样本。
3. 同时校验预估接驾时长与实际接驾时长误差。
4. 报告样本量、时间窗和显著性后再解释策略效果。

## 来源

- [接驾距离与 ETP、司机接驾时长变幅分析需求](../../raw/cooper/cooper-2209589579604.md)
- [交易效率指标和接驾距离指标差异分析](../../raw/cooper/knowledge-2209787750049.md)

## 关联页面

- [平均接驾距离](average-pickup-distance.md)
- [单均接驾时长](avg-pickup-duration.md)
- [归一乘客 ETP](normalized-passenger-etp.md)
- [归一司机接驾时长](normalized-driver-pickup-duration.md)
