# Cooper目录盘点报告

这是目录元数据盘点，不代表正文已读取或知识已确认。

| 入口 | 状态 | 查询目录 | 节点出现数 | 最大相对深度 |
| --- | --- | ---: | ---: | ---: |
| internal | complete | 32 | 312 | 3 |
| platform | complete | 7 | 34 | 2 |
| efficiency | complete | 301 | 1112 | 10 |
| planning | complete | 23 | 80 | 3 |
| proposals | complete | 2 | 21 | 2 |
| lr26 | complete | 1 | 52 | 1 |
| lr25 | complete | 1 | 55 | 1 |

合计节点出现 1666，唯一(app, ID) 1666，重复ID 0。

## 范围与完整性

CLI exposes no pagination parameters. All space responses checked totalCount <= returned items; knowledge tree has no total/pagination fields. No evidence of truncation; server-hidden nodes cannot be independently ruled out.

12 sampled hasChild=false knowledge pages each returned zero children; all returned nested children arrays checked empty.

部门方案/LR已按标题生成selected、uncertain、excluded三份清单，并记录理由。uncertain不自动进入正文下载；excluded仅保存元数据。selected仍需正文复核。

## 恢复

重新运行 inventory.py 复用 responses/ 下已成功的目录响应，重建每入口清单。每目录响应独立保存；成功结果不需重新拉取。修改输入来源或主动更新应使用新的快照目录，避免覆盖已有来源版本。
