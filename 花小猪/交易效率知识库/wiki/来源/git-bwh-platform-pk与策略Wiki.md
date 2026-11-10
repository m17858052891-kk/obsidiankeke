---
title: "Git-bwh-platform-pk与策略Wiki"
type: source
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: department
source_ids:
  - "repo:git@git.xiaojukeji.com:bwh_stg/platform_pk.git@7b0870808d6f9273e7347536a7a53301a1abb3a8"
  - "repo:git@git.xiaojukeji.com:bwh_stg/pk_strategy_wiki.git@a2fecfd0f41b31e34a374d53a95a08b74cf4ad88"
related:
  - "../模型/git-平台PK多任务与强化学习代码实现.md"
  - "../模型/PK模型谱系.md"
  - "Git知识库补充来源.md"
---

# Git-bwh-platform-pk与策略Wiki

本页登记两个固定 Git 提交的来源层级。两者不可相互替代：`platform_pk` 是代码实现证据，`pk_strategy_wiki` 是已整理的文档与历史证据导航。

| 仓库 | 固定提交 | 本批阅读范围 | 证据定位 |
| --- | --- | --- | --- |
| `bwh_stg/platform_pk` | `7b0870808d6f9273e7347536a7a53301a1abb3a8` | README，`pk_multitask_model/` 与 `pk_rl/` 中的模型、层、损失、训练、预测/数据及配置结构 | 可证明代码如何实现；不单独证明上线状态 |
| `bwh_stg/pk_strategy_wiki` | `a2fecfd0f41b31e34a374d53a95a08b74cf4ad88` | 模型总览、PLE、DQN、实验映射、代码映射和 PK 动态窗口来源页 | 文档方案、历史离线/线上结果的二次结构化摘要 |

## 新增信息与既有 Wiki 的关系

1. **代码级补充**：既有 Wiki 已经覆盖 PLE 多任务与 DQN 的业务建模、历史指标和实验摘要；本批新增了 Expert/Gate/Tower 的实际组合、OD/O/D/T 输出合成、DQN 三组状态编码、变时间 TD 目标与导出链路。
2. **一致性校验**：策略 Wiki 对 PLE 的 4 任务、样本筛选和结构摘要可与代码对应；DQN 的三组特征、两动作、奖励和变时间折扣也可对应。
3. **不一致项**：策略 Wiki 列出 replay buffer 和 ε-贪婪，但本次固定代码提交未见这两个显式实现。该项已在模型页保留为证据差异，不做自动归一。
4. **文档增量判断**：`pk_strategy_wiki` 的大部分业务文档已在 [PK模型谱系](../模型/PK模型谱系.md)、[PK动态窗口DQN](../模型/PK动态窗口DQN.md) 等页面提炼；本批不重复复制指标表，只登记固定提交、证据层级和代码差异。

## 证据分层

- **源码事实**：以 `platform_pk@7b087080...` 中的可执行逻辑为准，但未进行训练或部署验证。
- **文档方案**：来自 `pk_strategy_wiki@a2fecfd0...` 的架构、优化路线和训练机制描述；与代码不同时并列保留。
- **离线结果**：文档中的 AUC、验证损失和动作分布只属于原数据期与口径；本批没有复现。
- **线上事实**：文档历史记录中的扩量失败、5% 实验和在线迭代不视为当前状态；需用模型注册、调度和实验平台状态另行复核。

## 敏感信息处理

源码中可见内部存储位置、调度入参、全量特征名及归一化数组。本 Wiki 仅保留结构性信息，不复制这些配置值；需复现时应在原仓库权限内按固定提交阅读。

## 覆盖边界

- 未核对两个仓库之外的训练平台任务、模型注册和服务配置。
- 未解析文档中的图片、短效链接或外部附件；未从图中推断额外架构结论。
- 未将代码默认参数当作当前线上配置，也未运行代码或复现文档指标。

