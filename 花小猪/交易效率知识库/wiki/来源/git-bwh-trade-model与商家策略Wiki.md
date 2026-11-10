---
title: "Git 来源：bwh trade-model 与商家策略 Wiki"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: completed-with-gaps
last_reviewed: "2026-11-05"
permission_scope: department
source_ids:
  - "repo:bwh_stg/trade-model:267808883300da7e101d7b54680df18c870b5d54"
  - "repo:bwh_stg/cp_trade_strategy_wiki:996f692fa1fc7e890cb932571d54db948df1b8e9"
related:
  - "../模型/git-交易模型代码资产全景.md"
  - "../模型/多场景司乘取消PEPNet.md"
  - "../26年项目/自适应播单策略.md"
---

# Git 来源：bwh trade-model 与商家策略 Wiki

## 来源定位

本页记录两份 Git 快照的证据上限：

- `bwh_stg/trade-model@267808883300da7e101d7b54680df18c870b5d54`：1,143 个文件的交易模型实验代码库。
- `bwh_stg/cp_trade_strategy_wiki@996f692fa1fc7e890cb932571d54db948df1b8e9`：67 个文件、65 个 Markdown 的商家交易策略资料及其结构化 Wiki。

本次对前者抽样顶层目录、总 README、核心模型及训练/预测入口；对后者检查目录、overview、V0/V1/V2 版本页、concept/source 页。未逐文件通读全部代码与原始业务文档，未运行代码，也未复述敏感环境配置。

## trade-model 提供的新增证据

代码库把已有文档中的 PEPNet、多任务取消/履约与序列模型，落到一套可导航的实验矩阵：

- PEPNet 消融覆盖 EPNet、PPNet、domain/task gate、稀疏/数值分支、正则、梯度裁剪和分学习率。
- 特征交叉覆盖 DCNv2、SENet/Bilinear、FiBiNet、Wukong，并保存不同插入位置、秩、层数和组合方式。
- 序列路线覆盖 OneTrans、HyFormer-Domain、PEP+序列编码及多种 concat/flat/causal/self-cross 对照。
- 训练和预测通过 DMLite/EVE 风格入口衔接表式数据、特征列、标签列、分区和模型导出；不同子项目并未形成完全统一的运行时合同。

详细资产地图见 [[花小猪/交易效率知识库/wiki/模型/git-交易模型代码资产全景]]。

## 商家策略 Wiki 的内容与增量

该仓库把商家召回策略组织为三代演进：V0 固定扩播，V1 按供需自适应动态播单，V2 大范围召回后结合取消/流失模型过滤；概念页覆盖供需比、动播/扩播、播单半径、取消率模型、订单流失率和连环派。

相对当前交易效率 Wiki，它的主要新增价值是**来源编排与版本谱系**，而不是一组可直接升级为当前线上事实的新结论：

- 原始材料、source summary、concept 与 version 页面之间已有明确链接，适合作为商家策略文档导航入口。
- V0→V1→V2 把“固定半径—供需自适应—模型过滤”的机制变化串成连续版本线，可辅助核对当前 Wiki 中分散的召回、播单与取消模型页面。
- V2 页面明确把配置收敛、连环派/非连环派差异化过滤、ETA/EDA 双约束和份额迁移作为同一策略包的不同层面，但其中效果数字仍是仓库文档自述。

当前 Wiki 已有 [[花小猪/交易效率知识库/wiki/26年项目/自适应播单策略]]、[[花小猪/交易效率知识库/wiki/模型/动态播单半径策略]] 等页面覆盖核心机制，因此本批不重复搬运另一套 Wiki，也不把其历史配置参数复制为现行策略。

## 证据分层

| 证据 | 可以支持 | 不能支持 |
| --- | --- | --- |
| 代码文件与 README | 某结构、入口或实验映射在该 commit 中存在 | 已在生产运行、当前版本、线上收益 |
| 本地 YAML/配置 | 默认参数和字段合同的候选快照 | EVE 实际覆盖参数、现行服务配置 |
| 实验结果表/策略 Wiki | 来源作者记录的离线或历史实验结论 | 独立复现、因果显著性、当前全量状态 |
| version/concept/source 链接 | 文档版本关系与主题导航 | 业务配置已经按该版本执行 |

## 覆盖限制

- `trade-model` 的 1,143 个文件仅做家族级抽样，数百个 `Others/` 变体没有逐一代码审计；外部移植、重建组合和重复快照需后续按 hash/run 去重。
- `cp_trade_strategy_wiki` 的 raw 文档和图片/附件未逐项重解析；已生成 Wiki 中的表格数字未与实验平台或原始附件交叉验证。
- 两个仓库均未提供本次可核验的服务注册、线上调用、当前灰度比例、监控、延迟、资源、降级、回滚和 owner 验收链。
- 代码与文档中的环境地址、数据表、服务标识和配置值不在本页披露；需要时应在受控环境由 owner 按最小权限核验。

## 来源

- `bwh_stg/trade-model@267808883300da7e101d7b54680df18c870b5d54`
- `bwh_stg/cp_trade_strategy_wiki@996f692fa1fc7e890cb932571d54db948df1b8e9`
