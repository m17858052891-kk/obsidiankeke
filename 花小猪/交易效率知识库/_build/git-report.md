# T1 Git 来源盘点

检查时间：2026-11-04T09:27:07Z。

已逐一执行 `melos repo checkout` 检查用户指定的 5 个仓库。5 个均返回 `checkout failed: repo is not configured for this workspace`，因此本任务完成了入口可读性检查，但 Git 正文采集仍被配置阻塞；没有读取到 HEAD、文档清单或源码内容，不能视为已完成全文盘点。

| 仓库 | 状态 |
| --- | --- |
| bwh_stg/trade-of-passenger | 未配置，未读取 |
| bwh_stg/platform_pk | 未配置，未读取 |
| bwh_stg/trade-model | 未配置，未读取 |
| bwh_stg/pk_strategy_wiki | 未配置，未读取 |
| bwh_stg/cp_trade_strategy_wiki | 未配置，未读取 |

运行时目录列出了 `dongtingdong/pk_strategy_wiki` 和 `qinjiatong/cp_trade_strategy_wiki`。它们与请求来源的 owner 不同，仅记录为待验证候选，尚未确认是否镜像、旧仓库或等价来源，也未用其替代请求来源。

## 恢复方式

配置请求的仓库后，按 `git-inventory.json` 中的阻塞条目逐个重试，无需重新获取 Cooper 文档。每个成功仓库需继续读取自身 AGENTS.md、保存 HEAD 与 tracked 文档清单，再进入正文提炼。成功项按 commit 校验跳过，失败项单独重试。未通过平台配置边界使用直接 clone 或 HTTP 方式绕过。
