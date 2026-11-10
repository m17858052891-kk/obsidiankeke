---
title: "Hold 线上参数陈旧诊断"
type: guide
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_key: b015-evidence-hold-stale-param-diagnosis
source_ids: ["cooper:knowledge:2199710152082"]
related: ["../模型/司机Hold参数策略.md", "../模型/MDP-Hold匹配策略.md"]
---
# Hold 线上参数陈旧诊断

历史材料显示，扩播短单实验期间线上 Hold 参数长期未更新，导致线上过滤比例约 22.75%，而用更新离线数据、将自营司机整体化估算时可达约 44%。这类偏差应按以下路径排查：

1. 核对参数生成日期、发布版本、城市覆盖与线上命中日志。
2. 分开比较“模型本可过滤”和“线上实际过滤”，避免把离线能力当上线效果。
3. 检查订单 GPH、格子/时间片、空车司机数和胜率近似是否同口径。
4. 对过滤后的订单继续观察分单与播单，防止把匹配层过滤直接等同为最终收益。
5. 为参数新鲜度、缺失率和版本漂移建立监控与回滚门槛。

## 证据边界

44%及后续 83.2%均含强假设与离线推演，不是线上实验收益。SQL、流程图和线上修复回执未复核，不能外推至当前版本。

## 来源

- [线上生效问题分析](../../raw/cooper/knowledge-2199710152082.md)
