---
title: "单均 ETP｜来源摘要"
type: source
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: 2026-07-12
permission_scope: department
source_ids:
  - "repo:strategy-dept-knowledge:directions/trading-efficiency/metric/avg-etp.md"
related:
  - "../指标/avg-etp.md"
---

# 单均 ETP｜来源摘要

> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。

## 来源身份

- 稳定 ID：`repo:strategy-dept-knowledge:directions/trading-efficiency/metric/avg-etp.md`
- 仓库相对路径：`directions/trading-efficiency/metric/avg-etp.md`
- 快照 commit：`a27b537bdef2b8f1cd7e3c503602dad9fde164c3`
- SHA-256：`a3f5dd4af00877fccdad1aa6bb520aedf4a0c33a96420910f4137520c523ee30`
- 层级：部门库二次整理材料；原始 Cooper 来源未在本批逐一复核。

## 结构化摘要

- ETP 是 Estimated Time of Pickup，在本方向口径中用于衡量乘客从发单到司机点击到达上车点的平均等待时长。
- 这是乘客视角指标，表达乘客被等待接驾占用的时间。

### 核心计算

```text
单均 ETP = 呼叫-司机到达上车点时长 / 到达样本量
```

- 呼叫-司机到达上车点时长：同一次原始发单中，司机点击到达上车点时间 - 第一次呼叫时间。
- 分母：司机到达上车点的样本量；若看板使用应答量或完单量，需要以看板为准。
- 单位：建议统一为分钟。

## 使用边界

原材料 freshness 为 watch，最近内容复核日期为 2026-07-12。可用于定义候选知识与追溯，不据此宣布当前线上事实。

## 来源

- [avg-etp.md](../../raw/department-baseline/directions/trading-efficiency/metric/avg-etp.md)（快照 commit `a27b537`）

## 关联页面

- [avg-etp](../指标/avg-etp.md)
