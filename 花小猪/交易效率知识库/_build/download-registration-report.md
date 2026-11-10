# T3 全量正文账本登记

登记时间：2026-11-04T09:34:22Z。本次仅登记，没有发起正文读取。

目录 manifest 已全部遍历完成，7 个 root 合计 1666 节点：internal 312、platform 34、efficiency 1112、planning 80、proposals 21、lr26 52、lr25 55。下载器额外登记 5 个知识根页自身正文，下载账本合计 1671 个唯一资源；space 根目录不作为正文。

| 状态 | 数量 |
| --- | ---: |
| 正文成功 | 88 |
| 待下载 | 1431 |
| 失败（空正文） | 12 |
| 目录 | 37 |
| 不支持的资源类型（表格） | 12 |
| 排除 | 74 |
| 待相关性确认 | 17 |

部门来源严格读取 `cooper/department-selected.json`（44）、`department-uncertain.json`（14）、`department-excluded.json`（70），按 `(app,id)` 关联，不再以独立正则重做选择。只将 selected 部门文档放入下载队列；uncertain 保留 `pending_selection`，excluded 保留排除原因。另有部门 3 个根页正文尚未分类，因此登记为 `pending_selection`，没有静默遗漏，也没有将全部门根页直接作为交易效率来源。4 个方向来源另排除 4 篇无关述职/绩效内容。

## 下一批命令

建议开始新正文批次并优先补根页与核心来源：

```bash
python3 trading-efficiency-llm-wiki/_build/download.py --roots internal platform efficiency planning proposals lr26 lr25 --limit 100
```

只更新账本、不读取正文：

```bash
python3 trading-efficiency-llm-wiki/_build/download.py --roots internal platform efficiency planning proposals lr26 lr25 --register-only
```

默认不重试旧失败；显式追加 `--retry-failed` 时最多尝试 3 次。成功原文按 SHA-256 跳过，不覆盖历史快照。正文与图片仍仅作文本采集，图片/附件内容没有被解析。
