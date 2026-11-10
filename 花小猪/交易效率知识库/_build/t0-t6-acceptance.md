# T0–T6 最终验收

| 任务 | 状态 | 验收结果 |
| --- | --- | --- |
| T0 本地骨架与断点 | completed | AGENTS、raw/wiki/_build 三层结构和恢复账本齐全 |
| T1 Git 盘点 | completed | 5 个 bwh_stg 仓库、2 个不同 owner 补充仓库均保留来源与 commit 边界 |
| T2 Cooper 递归盘点 | completed | 7 入口、1666 节点、最大深度 10、目录错误 0、待筛选 0 |
| T3 正文分批获取 | completed | 1373 有效成功正文；待下载 0；12 表格闭环；失败按用户指示停止 |
| T4 主题提炼 | completed | 成功正文去重通读；Git 与 PDF 增量已提炼；方案/离线/线上分层 |
| T5 合并导航 | completed | 索引、知识地图、日志、README 和构建报告已刷新；当前 600 页 |
| T6 校验交付 | completed | lint 0/0；8 题 24 rubric 全部 pass；缺口和恢复入口明确；交付包不含 Git 元数据和认证信息 |

## 保留边界

- 172 个空正文、1 个 LaTeX 解析错误、1 个 Metis 版本缺失按用户指示不处理。
- 原安全拒读 Cooper 页继续保留失败审计记录，正文内容由用户导出 PDF 替代来源完成提炼。
- 未解析图片、其他附件、外链、样本/显著性、生产配置与发布回执不被视为已确认事实。

## 交付包

- 评论附件：`trading-efficiency-llm-wiki-T0-T6-review.tar.gz`
- 内容：`AGENTS.md`、`README.md`、`BUILD-REPORT.md`、完整 `wiki/`，以及 T0–T6 验收、任务、lint、评测、Git/PDF 来源清单。
- 不包含：133MB 原始来源快照、Git 元数据、认证信息、临时渲染文件。原始来源继续保留在本地 `raw/` 断点，可按需单独交付。
