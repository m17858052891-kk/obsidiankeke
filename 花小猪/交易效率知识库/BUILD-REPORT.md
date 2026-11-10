# 交易效率 LLM Wiki 构建检查点

截至 2026-11-05T11:37:54（本地运行时间）。T0–T6 已完成本地可读范围构建并通过验收。

## T0–T6 状态

- T0 本地骨架与断点：completed
- T1 Git盘点：completed；指定bwh_stg的5个仓库已读取并固定commit，共1387个受版本控制文件、368个Markdown；核心代码族与来源页已审阅，先前额外2库作为不同owner来源独立保留
- T2 Cooper递归盘点：completed；7入口1666节点，最大深度10；初筛与覆盖提升项均已复核，3个知识根页在B021闭环，pending_selection归零；目录读取0错误
- T3 正文分批获取：completed；累计1373有效成功、175失败；待下载与待筛选均归零；12表格已闭环，其中2排除、10个相关表格均深读至实际末行
- T4 主题提炼：completed；18基线来源和Cooper1373篇有效成功正文已完成；新增审阅5个bwh_stg仓库的核心代码族、模型入口和来源导航，trade-model按模型族抽样，未逐个复现实验
- T5 合并导航：completed；总索引/知识地图/日志与README已刷新；Git增量5页、PDF增量2页，Wiki共600页；10个相关表格已全部完成全范围深读
- T6 校验交付：completed；本地检查点600页，lint 0错误0警告；8题24条证据审查24pass；embedding提取-预训练通过用户导出PDF替代来源闭环；已生成不含Git元数据和认证信息的交付包

## 来源覆盖

| 类别 | 数量 |
| --- | ---: |
| 部门基线快照 | 18 |
| 既有额外 Git Markdown 快照 | 217 |
| bwh_stg 仓库 | 5（1387 文件 / 368 Markdown） |
| 用户导出 PDF 替代来源 | 1 |
| Cooper success | 1373 |
| Cooper pending | 0 |
| Cooper failed | 175 |
| Cooper directory | 37 |
| Cooper unsupported | 12 |
| Cooper excluded | 74 |
| Cooper pending_selection | 0 |

Wiki 当前 600 页。1373 篇有效 Cooper 成功正文已完成去重通读；原安全拒读页由用户导出 PDF 作为替代来源补齐，原失败状态继续保留用于审计。

## 验收与边界

- lint 为 0 错误、0 警告；8 题 24 条证据审查为 24 pass、0 fail、0 insufficient。
- 12 个表格已闭环，其中 2 个排除、10 个相关表格深读至实际末行。
- 其余失败项为 172 个空正文、1 个 LaTeX 解析错误、1 个 Metis 版本缺失；按用户指示不再处理。
- 图片、其他附件、外链、样本口径、显著性、服务配置、灰度、发布和回滚信息仍按来源缺口保留。
- 方案、离线结果、实验观察和线上事实分开；未知项不补造，历史 LR 不自动升级为当前有效性。

## 恢复

后续仅在新增来源或用户指定补充范围时，从 `_build/tasks.json`、`_build/downloads.json` 与本报告继续增量处理，不从头重跑。
