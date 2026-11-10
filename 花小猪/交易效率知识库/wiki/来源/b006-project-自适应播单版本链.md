---
title: "自适应播单 V1.1.2—V2 二期｜B006 来源摘要"
type: source
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_ids:
  - "cooper:2202865789015"
  - "cooper:2202871363049"
  - "cooper:2203294830970"
  - "cooper:2203508984131"
  - "cooper:2203535244837"
  - "cooper:2203992061715"
  - "cooper:2204140513184"
related:
  - "../26年项目/自适应播单策略.md"
processed_at: 2026-11-04
---

# 自适应播单 V1.1.2—V2 二期｜B006 来源摘要

## 来源定位

- [V1.1.2](../../raw/cooper/cooper-2202865789015.md)，SHA-256 `0267a711803c0556d93533c2d3745b0e2842e5aaac00d90fe3cc22cbb159bbff`
- [V1.2 策略](../../raw/cooper/cooper-2202871363049.md)，SHA-256 `ddb7ebd9d30d7177595208e86fb3ac03662f5f28251749382665493bbad5ecac`
- [V1 放量节奏](../../raw/cooper/cooper-2203294830970.md)，SHA-256 `474c50b75fa65e3645bd99bf0f6ab804f3595ff1f14b29134867c4c7910e0b38`
- [V1.2.1](../../raw/cooper/cooper-2203508984131.md)，SHA-256 `dd31db63abfdc69c2aefad65219107a0d197196389d896e297a875a1777ad084`
- [V2 策略](../../raw/cooper/cooper-2203535244837.md)，SHA-256 `e015df733025759d27e431a92ad312debc8cc5156683cd99587f5b1138b68caa`
- [V2 实验](../../raw/cooper/cooper-2203992061715.md)，SHA-256 `4fec05fd1b11dad1bbf0a154df405f6b84fa55385600a9bc37e0998242a29fab`
- [V2 二期实验](../../raw/cooper/cooper-2204140513184.md)，SHA-256 `09a05b43575429772e4abe5530bbe2f2ab6278b9d0e948c8b8d36d74bad92d46`

## 版本脉络

V1.1.2/V1.2 修正供需与竞争应答率口径，并按订单里程调整扩缩播；V1.2.1 将初始半径从城市分桶推进到 by 城市配置，并用中心加一圈格子刻画可用运力。V2 进一步把中心与一圈格子的空车、未播订单共同纳入供需档位，并规划周期任务产出半径配置。

V1 放量文档给出 15%→40%→70%→100% 的条件式节奏和异常回滚，但它是放量计划，不能单独证明每一步实际发生。V2 两份材料给出多组乘客随机分流设计，二期含实验结果表；具体结论仍需结合完整样本、显著性和最终决策复核。

## 证据边界

文档中的收益数字同时包含前序结果、预估目标和实验结果，三者不可互换；本摘要不据版本号推断现网版本，也不将实验配置视为已全量。

## 关联页面

- [自适应播单策略](../26年项目/自适应播单策略.md)

