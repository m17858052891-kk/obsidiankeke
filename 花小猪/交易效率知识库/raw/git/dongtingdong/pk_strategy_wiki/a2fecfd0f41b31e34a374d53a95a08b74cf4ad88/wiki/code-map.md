---
title: PK Code Map
type: index
created: 2026-05-29
updated: 2026-05-29
sources:
  - /home/xiaoju/data9/hne/user_code/2/dongtingdong/designer/
tags:
  - code-map
  - agent
  - pk决策
---

# PK Code Map

This page maps PK wiki topics to code prefixes and editable Git repositories. The company platform may place multiple projects under one shared workspace, so do not treat the workspace root as a single repository.

## Code Workspace

- Code workspace root: `/home/xiaoju/data9/hne/user_code/2/dongtingdong/designer/`
- Workbench path on remote: `/nfs/volume-661-1/dongtingdong/strategy-ai-workbench`

## Directory Convention

每个 `pk_*` 项目目录下包含多个以框架名+ID 命名的子目录（如 `pytorch_learning_60919`），代表不同训练实验版本。典型文件结构：

| 文件 | 作用 |
| --- | --- |
| `model.py` | 模型架构定义 |
| `layer.py` | 自定义层（CrossNetwork, PLELayer, SENetLayer, BilinearInteraction 等） |
| `loss.py` | 损失函数（FocalLoss 等） |
| `train.py` | 训练脚本 |
| `predict.py` | 推理/预测脚本 |
| `config.py` / `config.yaml` | 特征定义、超参数配置 |
| `main.py` | 入口脚本（训练或数据处理） |
| `utils.py` | 工具函数 |
| `distill_lr.py` / `distill.py` | LR 蒸馏脚本 |

子目录前缀含义：`pytorch_learning_*` = PyTorch 训练实验；`deeplearning_predict_*` = 离线预测/推理；`self_eval_*` = 自评估（含 GAUC 等）；`general_python_*` = 通用 Python 脚本（数据处理/分析）。

## Editable Git Repositories

Fill this table after remote inspection. Only repositories marked editable should be changed by Claude Code.

| Repository | Path | Code Prefix / Scope | Editable | Commit Rule | Notes |
| --- | --- | --- | --- | --- | --- |
| pk_multi_cls_model | `pk_multi_cls_combine2/pytorch_learning_19771/` | `pk_multi_cls_combine2` 三分类 PLE 模型 | Yes | Commit meaningful iterations | Remote: `git@git.xiaojukeji.com:dongtingdong/pk_multi_cls_model.git`，branch `master`。唯一有 commit 历史的 pk 仓库，含完整 pipeline（train/predict/eval/distill/preprocess）。 |
| pk_multi_cls_model (clone) | `pk_example/pytorch_learning_48342/` | `pk_example` 基线模型 | No — empty | — | 同 remote，无 commit 历史，仅 `.git/config` 指向 origin。 |
| pk_multi_cls_model (clone) | `pk_example/pytorch_learning_61635/` | `pk_example` 基线模型 | No — empty | — | 同上。 |
| pk_multi_cls_model (clone) | `pk_example/pytorch_learning_67757/` | `pk_example` 基线模型 | No — empty | — | 同上。 |
| pk_multi_cls_model (clone) | `pk_multi_cls/pytorch_learning_38893/` | `pk_multi_cls` 多分类模型 | No — empty | — | 同上。 |

## Topic To Code Mapping

| Wiki Topic | Related Wiki Pages | Code Prefix | Owning Git Repository | Edit Scope | Notes |
| --- | --- | --- | --- | --- | --- |
| PK 模型（总体） | `wiki/entities/PK模型.md`, `wiki/models/模型架构总览.md` | `pk_example/`, `pk_example_2/` | pk_multi_cls_model (empty clones) | Read-only | 基线 PK 模型实验。使用 Wide&Deep 架构（`WideDeepModel`），含 CrossNetwork 特征交叉层（DCN）。多个 `self_eval_*` 子目录做离线评估。 |
| Wide&Deep 模型 | `wiki/models/模型架构总览.md` | `pk_deep_wide_model/` | 无 Git 仓库 | Read-only | Wide&Deep 架构独立项目。`pytorch_learning_16519/` 含完整 `model.py`、`train.py`、`predict.py`、`config.yaml`。 |
| PK 可解释模型（Deep） | `wiki/models/LR逻辑回归.md`, `wiki/entities/PK可解释模型.md` | `pk_deep_explained_model_v2/`, `pk_deep_explained_model_copu/` | 无 Git 仓库 | Read-only | Wide&Deep 可解释版本。`v2` 为主版本，`copu` 为拷贝/变体。含 `CrossNetwork` layer 和 `self_eval_*` 评估。 |
| LR 可解释模型（蒸馏） | `wiki/models/LR逻辑回归.md`, `wiki/entities/PK可解释模型.md` | `pk_multi_cls_combine/…/distill_lr.py`, `pk_multi_cls_combine2/…/distill.py` | pk_multi_cls_model（仅 combine2） | Editable | 从 PEPNet/PLE 多任务模型蒸馏出 3 个独立 LR（`LogisticRegression` -> `MultiTaskLogisticRegression`），用于获取可解释特征权重。 |
| PLE 多任务模型 | `wiki/models/PLE多任务模型.md` | `pk_pepnet/`, `pk_senet/`, `pk_multi_cls/`, `pk_multi_cls_combine/`, `pk_multi_cls_combine2/` | pk_multi_cls_model（仅 combine2） | Editable (combine2) / Read-only (others) | 基于 PLE + SENet + Bilinear Interaction 的多任务学习。核心类 `BaseMTModel`，特征三分组：ord（订单）/dri（司机）/pas（乘客）。 |
| PEPNet | `wiki/models/PLE多任务模型.md` | `pk_pepnet/pytorch_learning_60919/` | 无 Git 仓库 | Read-only | PEPNet 架构实现。`model.py` 含 `BaseMTModel` + `PLELayer` + `BilinearInteraction` + `SENetLayer` + `TaskSpecificProjection`；`layer.py` 含自定义层；`loss.py` 含 FocalLoss。 |
| SENet 特征交叉 | `wiki/models/PLE多任务模型.md` | `pk_senet/pytorch_learning_16318/` | 无 Git 仓库 | Read-only | SENet + Bilinear 特征交叉模块（`SENetBilinear`）。含 PLELayer、ExpertLayer。 |
| 多分类 PK 模型 | `wiki/models/PLE多任务模型.md` | `pk_multi_cls/`, `pk_multi_cls_combine/`, `pk_multi_cls_combine2/` | pk_multi_cls_model（仅 combine2） | Editable (combine2) / Read-only (others) | 三分类版本多任务模型。`pk_multi_cls_combine2/pytorch_learning_19771/` 是唯一有 commit 历史的仓库，含完整 pipeline。 |
| 特征工程 | `wiki/concepts/特征工程.md` | `pk_pepnet/…/config.yaml`, `pk_multi_cls_combine2/…/config.py` | pk_multi_cls_model（仅 combine2） | Editable (combine2) | `config.yaml` 定义稀疏/稠密/序列/非序列/二值/POSO 特征维度及归一化参数。典型配置：n_sparse=3, n_dense=52, n_serial=20, n_nonserial=20。 |
| PK 序列模型 | `wiki/models/PLE多任务模型.md` | `pk_sequential_model/` | 无 Git 仓库 | Read-only | 序列特征处理相关。`general_python_01389/main.py` 通过 Spark 做数据预处理。 |
| 动态窗口策略 | `wiki/entities/PK窗口.md`, `wiki/models/DQN.md` | N/A | N/A | No edit | `pk_*` 目录中未找到 DQN 或窗口策略相关代码。 |
| 冷启动系统 | `wiki/entities/冷启动系统.md` | N/A | N/A | No edit | `pk_*` 目录中未找到冷启动专用代码。 |

## Git Iteration Rules

- Before editing, run `git status --short` in the owning repository.
- Keep unrelated dirty changes untouched.
- After a meaningful experiment step, record the repository path, changed files, and commit intent.
- Prefer committing small, reviewable iterations in the owning repository.
- If a required file is outside any Git repository, pause and ask before editing.

## Usage Rules

- Use this file to avoid guessing where code lives.
- Update it whenever a durable mapping between wiki topic and code path is discovered.
- If a mapping is missing, inspect the code workspace and update this page before making broad code changes.
