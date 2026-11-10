---
title: "Git 交易模型代码资产全景"
type: model-card
owner: "@tommywujian"
freshness: watch
status: experimental-code
last_reviewed: "2026-11-05"
permission_scope: department
source_ids:
  - "repo:bwh_stg/trade-model:267808883300da7e101d7b54680df18c870b5d54"
related:
  - "多场景司乘取消PEPNet.md"
  - "PEPNet与序列履约模型.md"
  - "生成式序列推荐研究谱系.md"
  - "模型部署与一致性验收.md"
---

# Git 交易模型代码资产全景

> 本页是代码资产地图，不是生产模型清单。仓库中的目录、离线结果表和 EVE 入口证明“实现或实验曾被保存”，不证明模型已上线、仍在服务或产生线上收益。

## 来源与抽样范围

- 仓库：`bwh_stg/trade-model`，commit `267808883300da7e101d7b54680df18c870b5d54`。
- 仓库共 1,143 个文件、147 个 Markdown。本次检查了顶层目录、`PEPNet/README.md` 的实验—代码映射、Baseline/OneTrans/HyFormer-Domain 说明，以及 Cancel_PEPnet_seq、DO_Onetrans、HyFormer-Domain 的模型、训练、预测入口抽样。
- 未逐行审计所有 `Others/` 变体，未运行训练/预测，也未读取或复述可能包含环境、表名、服务地址的敏感配置值。

## 资产不是单一模型，而是实验矩阵

| 资产族 | 代码中可确认的能力 | 证据边界 |
| --- | --- | --- |
| PEPNet / PEP00 / PEP01 / PEP02 | EPNet/PPNet 的有无、输入分组、task/domain gate、稀疏与数值分支、gate 正则和分学习率等消融 | 多个目录复用同一代码、靠 EVE 参数区分；本地配置不等于历史实际运行参数 |
| 特征交叉 | DCNv2、SENet/Bilinear、FiBiNet、Wukong，以及层数、秩、并行/堆叠、交叉前后位置等变体 | README 中有离线 AUC 映射，但不同阶段、字段数、epoch 和 seed 不可直接横比 |
| 序列建模 | OneTrans、PEPNet+序列编码、concat/flat 对照、因果注意力、自交叉与架构搜索变体 | 目录名和代码保存的是候选实现；checkpoint、上传包和线上版本需另查运行记录 |
| HyFormer-Domain | 驾驶员/乘客双历史独立编码，domain-conditioned query，两层 sequence encoding、query decoding/boosting，三任务与双 domain adapter/head | README 明确这是 EVE 实验适配；无线上流量、时延、资源和收益证据 |
| 其他多任务 | PLE、STAR、DTN/DTRN、AutoMTL 等研究或移植代码 | AutoMTL 等包含外部/移植资产，需保留来源边界，不能当作内部原创或已发布能力 |

## 可复核的模型结构事实

### 多场景取消与履约

`Cancel_PEPnet_seq/model.py` 同时保留 PLEModel 与 PEPModel。抽样版本把输入拆成 sparse、dense、serial、nonserial、binary、poso 及乘客/司机序列：

- PLE 路径为六个 task expert 输出，再由 binary domain 在成对 head 间硬路由，最终形成 OD/O/D 三个概率。
- PEP 路径将数值特征映射到 embedding，使用 EPNet 与三个任务 PPNet；序列分支使用 Transformer 编码器处理历史片段。
- 代码中的 OD/O/D loss 使用不同样本 mask，对应“司乘履约、乘客履约、司机履约”三个标签合同。该实现事实可补强 [[花小猪/交易效率知识库/wiki/模型/多场景司乘取消PEPNet]] 的工程层，但不能反推当前服务结构。

### OneTrans 与 HyFormer

- OneTrans 代码实现可学习位置编码、因果 mask attention、分位置 K/Q/V 与 FFN 参数，并存在多 block/concat/flat 等对照目录。
- HyFormer-Domain 的输入说明为静态字段加驾驶员/乘客两组历史序列；连续、类别和坐标分别编码，不直接相加原始异质数值。domain 字段独立嵌入，司机与乘客路径保持独立 tokenizer、encoder 和 query decoding。
- HyFormer 顶层共享 backbone，但 OD/O/D 各有表示塔，并按连环派/非连环派设置低秩 adapter 与输出 head 后硬路由。README 明确它不包含 OneTrans 的因果自注意力，也不包含 EPNet、PPNet、PLE 或 gate 正则。

## 训练与预测接口合同

仓库中较稳定的代码组织是：`model.py`/专用结构文件负责网络，`main.py` 负责训练，`test/main.py` 或 `predict.py` 负责批预测，YAML 和 feature-column 参数负责数据合同。

- 训练入口普遍接收训练/验证输入、模型续训路径、保存目录、特征列、标签列和调度分区；数据由 DMLite 表式 Dataset/DataLoader 读取。
- 训练过程计算 OD/O/D 分任务 AUC，并保存模型或最佳 checkpoint。HyFormer 说明中特别区分“step validation 仅监控”和“完整 epoch validation 选最佳 mean AUC”。
- 预测入口接收模型与数据输入、输出目标、保留列、特征列、批大小和分区；不同目录存在 PyTorch/EVE 测试入口与一个 TensorFlow Predictor 示例，不能假设接口或运行时已统一。
- README 多次注明 epoch、batch、学习率、lambda、block 数可能由 EVE 覆盖，因此本地 YAML 只能作为默认值或代码快照，不能作为历史运行真值。

## 对既有 Wiki 的实质增量

1. 既有页面主要总结文档中的模型结论；Git 资产补上了“实验目录—结构变体—训练/预测入口”的可复核工程地图。
2. PEPNet 不是一个固定网络名，而是一组围绕 EP/PP 分支、domain/task conditioning、稀疏/数值输入和优化器策略的实验谱系。
3. 序列路线至少分为 PEP+Transformer、OneTrans 因果序列和 HyFormer query decoding 三类，不应把它们合并成一个已上线版本。
4. README 自身保留大量“上传包待核、EVE 参数覆盖、重建组合、只对应同结构”的警告；这些应进入模型验收，而不是被离线 AUC 表掩盖。

## 覆盖缺口与验收清单

- 未核验 EVE run、checkpoint hash、模型注册、服务调用、灰度流量、线上指标、P99、资源、降级与回滚。
- 未解析实验结果 Excel 的全部行，也未复算 AUC；README 数值仅作为仓库自述，不升级为独立复现实验。
- `Others/` 数百个目录中可能存在重复、重建或历史覆盖版本；正式资产治理需按 `PROJECT.json`、文件 hash、run ID 和 checkpoint 去重。
- 训练与预测示例存在框架和接口差异；投产前仍需校验特征顺序、缺失值、domain 编码、label mask、导出格式和离在线一致性。

## 来源

- `bwh_stg/trade-model@267808883300da7e101d7b54680df18c870b5d54`

