# Cooper 下载报告：Batch 004

- 执行窗口：2026-11-04 18:04:56—18:06:02（Asia/Shanghai）
- 范围：`internal`、`platform`、`efficiency`、`planning`、`proposals`、`lr26`、`lr25`
- 本批选择：100 篇（`internal` 50，`efficiency` 50）
- 成功：94 篇
- 失败：6 篇（均为 `empty_body`）
- 正文体量：10,638,106 bytes
- 未解析图片：127 张；当前按正文优先策略保留计数，未将图片内容自动写入 Wiki

## 累计断点

- 成功：365
- 待抓取：1,131
- 失败：35
- 目录节点：37
- 不支持表格：12
- 明确排除：74
- 待人工筛选：17

下载状态保存在 `_build/downloads.json`，后续批次会跳过成功项并从待抓取项继续。

## 本批失败项

| key | 标题 | 原因 |
|---|---|---|
| `knowledge:2199777361748` | 司机愿接模型 | `empty_body` |
| `knowledge:2201717360428` | 01. 司乘履约模型迭代 | `empty_body` |
| `knowledge:2201901407851` | 预估应答时长模型 | `empty_body` |
| `knowledge:2202040171408` | JRC模型 | `empty_body` |
| `knowledge:2202042177415` | 14. 模型调研 | `empty_body` |
| `knowledge:2202319564348` | 03. PK可解释模型 | `empty_body` |

## 安全与证据边界

- 原始快照继续作为不可变证据保存于 `raw/cooper/`。
- Wiki 页面只提炼正文可证实的事实，并保留来源页、原始 URL、抓取时间与内容哈希。
- 空正文不据标题推断结论，留在失败队列供后续单独核查。
- 安全反馈命中的文档仍不自动重试，也不进入提炼。
