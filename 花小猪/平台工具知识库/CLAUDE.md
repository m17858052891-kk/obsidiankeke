# 平台工具知识库 — Schema

本文件定义了知识库的结构、约定和工作流，供 LLM 在维护 wiki 时遵循。

## 领域

滴滴内部**策略算法研发**全链路平台工具知识库。涵盖数据处理、特征工程、模型训练、模型部署、策略上线、效果评估等环节使用的内部平台与工具。

## 目录结构

```
.
├── CLAUDE.md          # 本文件（schema）
├── llm-wiki.md        # 方法论原文
├── raw/               # 原始资料（不可变，LLM 只读）
├── wiki/              # LLM 生成并维护的 wiki 页面
│   ├── index.md       # 内容索引（按分类组织）
│   ├── log.md         # 变更日志（append-only）
│   ├── overview.md    # 全局概览与平台关系图
│   ├── entities/      # 实体页（平台、工具、服务）
│   ├── concepts/      # 概念页（技术概念、方法论）
│   ├── workflows/     # 流程页（SOP、操作指南）
│   └── sources/       # 原始资料摘要页
└── .obsidian/         # Obsidian 配置
```

## 页面约定

### Frontmatter

每个 wiki 页面都应包含 YAML frontmatter：

```yaml
---
title: 页面标题
type: entity | concept | workflow | source | overview
tags: [相关标签]
sources: [引用的原始资料文件名]
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

### 链接

- 使用 Obsidian wiki-link 格式：`[[花小猪/平台工具知识库/wiki/entities/EVE]]`
- 跨页引用要确保双向链接
- 原始资料引用格式：`> 来源：[[raw/文件名]]`

### 命名

- 实体页：以平台/工具的正式名称命名（如 `EVE.md`、`Luban.md`）
- 概念页：以中文概念名命名（如 `模型训练.md`、`特征工程.md`）
- 流程页：以动作短语命名（如 `模型部署上线流程.md`）
- 源文件摘要：以 `src-原始文件简称.md` 命名

## 工作流

### Ingest（摄入新资料）

1. 用户将新资料放入 `raw/`
2. LLM 阅读资料，与用户讨论要点
3. 在 `wiki/sources/` 创建摘要页
4. 更新相关实体页、概念页、流程页
5. 更新 `wiki/index.md`
6. 在 `wiki/log.md` 追加记录

### Query（查询）

1. 读取 `wiki/index.md` 定位相关页面
2. 深入阅读相关 wiki 页面
3. 综合回答，给出引用
4. 有价值的分析结果可存为新 wiki 页面

### Lint（健康检查）

定期检查：
- 孤立页面（无入链）
- 过时信息
- 缺失交叉引用
- 应有专页但尚未创建的概念
- raw/ 中尚未摄入的资料

## 分类体系

### 实体（entities）
平台、工具、服务等具体事物：
- EVE（策略算法平台）
- Luban（鲁班开发机/ML平台）
- DUFE（统一特征平台）
- 数梦/DataDream（数据调度平台）
- Apollo（实验平台）
- Spark（大数据计算引擎）

### 概念（concepts）
技术方法、抽象概念：
- 模型训练
- 特征工程
- 模型部署
- AB实验
- 离线特征生产
- 模型定期更新

### 流程（workflows）
操作步骤、SOP：
- 模型策略上线校验SOP
- 离线特征生产流程
- 模型部署上线流程
- 周期性任务配置流程

## 注意事项

- `raw/` 目录内容是不可变的，LLM 永远不修改原始资料
- wiki 页面之间应尽量形成稠密的交叉引用网络
- 当新资料与已有 wiki 内容矛盾时，在相关页面标注并说明
- 每次变更都要更新 log.md
- 内部链接（如 cooper、xiaojukeji 域名）保留原样，方便用户访问
