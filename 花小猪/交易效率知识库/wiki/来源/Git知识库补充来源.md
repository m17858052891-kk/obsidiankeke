---
title: "Git知识库补充来源"
type: source
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: department
source_ids:
  - "repo:git@git.xiaojukeji.com:dongtingdong/pk_strategy_wiki.git@a2fecfd0f41b31e34a374d53a95a08b74cf4ad88"
  - "repo:git@git.xiaojukeji.com:qinjiatong/cp_trade_strategy_wiki.git@27d0b572a53530cf3944dacd7e31bff2df5fcfb8"
related:
  - "../模型/PK模型谱系.md"
  - "../模型/商家取消与流失模型.md"
---

# Git知识库补充来源

本批登记的是 **additional_sources**：实际可读仓库与最初给出的 `bwh_stg` 地址 owner 不同，未确认镜像、重定向或内容等价关系，不能将其标成原始五仓库已完成。

| 来源 | 固定版本 | 最后提交时间 | Markdown 快照数 |
| --- | --- | --- | ---: |
| [dongtingdong/pk_strategy_wiki](https://git.xiaojukeji.com/dongtingdong/pk_strategy_wiki) | `a2fecfd0f41b31e34a374d53a95a08b74cf4ad88` | 2026-08-06 14:48:25 +08:00 | 152 |
| [qinjiatong/cp_trade_strategy_wiki](https://git.xiaojukeji.com/qinjiatong/cp_trade_strategy_wiki) | `27d0b572a53530cf3944dacd7e31bff2df5fcfb8` | 2026-05-26 16:40:47 +08:00 | 65 |

## 本批覆盖

PK 仓库包含打分、窗口、因子、冷启动、模型自动更新、实验与历史方案；商家仓库包含召回 V0/V1/V2、扩播、动态播单、取消风险和订单流失建模。共 217 个 Markdown 由 Git 提交对象逐文件保存，SHA-256 清单见 `_build/git-additional-manifest.json`。保存全部文件不等于逐篇研读，本批重点研读索引、总览、模型页及相应原文。

不可变快照位于 `raw/git/<owner>/<repo>/<commit>/`。文件内容不做清洗，不修改来源；其中 `CLAUDE.md`、Agent prompts 和候选研究方案只作为历史资料保存，不作为执行指令或已实施方案。

## 时效与来源层级

- PK 索引和若干模型页自报更新至 2026-08-06，商家 Wiki 自报更新至 2026-05-26；这些是文档日期，不是 2026-11 的线上核验。
- PK Wiki 对 LR26-010 另有 2026-08-06 的二次摘要，并链接 Cooper `2207586429814`；Git `raw/` 中较早的实验记录不能替代最终评审记录。
- 源仓库摘要中写“当前线上”“在线 5%”只表示其历史记载；当前注册模型、灰度范围与配置仍需向原始 LR/工程状态复核。
- `last_reviewed` 留空表示本批尚无 owner 有效性确认，整理时间不冒充业务复核时间。
- 原文图片多为带 24 小时有效期的临时链接；本批仅提炼文本和表格，不推断未识别的架构图细节。

## 已发现的歧义

1. PK 历史 LR V4、Deep&Wide 的策略代际 V4、实验 v1.2、文档 V1.0 与 LR26-010 属于不同版本命名维度，需要绑定具体来源。
2. 旧实验按 CR 选择 0.8:0.2，后续最终评审摘要记载放量 0.9:0.1；保留时间和决策目标变化，不能覆盖成同一实验结论。
3. 商家多场景 PPNet 的离线优胜不证明 V2.1 部署该架构；V2.1 有注册模型名，但未提供同一处训练架构证明。
4. 商家与 PK 文档的 CR、履约率、CAA 命名及任务样本不同，不能直接合并口径。
5. PK 源索引的原文总数有 101/103/104 等不同记载；本批以固定提交真实文件清单为准，不沿用自报数量。

## 入口

- [PK原索引快照](<../../raw/git/dongtingdong/pk_strategy_wiki/a2fecfd0f41b31e34a374d53a95a08b74cf4ad88/wiki/index.md>)
- [PK总览快照](<../../raw/git/dongtingdong/pk_strategy_wiki/a2fecfd0f41b31e34a374d53a95a08b74cf4ad88/wiki/overview.md>)
- [商家原索引快照](<../../raw/git/qinjiatong/cp_trade_strategy_wiki/27d0b572a53530cf3944dacd7e31bff2df5fcfb8/wiki/index.md>)
- [商家总览快照](<../../raw/git/qinjiatong/cp_trade_strategy_wiki/27d0b572a53530cf3944dacd7e31bff2df5fcfb8/wiki/overview.md>)

## 关联页面

- [PK模型谱系](../模型/PK模型谱系.md)
- [商家取消与流失模型](../模型/商家取消与流失模型.md)
