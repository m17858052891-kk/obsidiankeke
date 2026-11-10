---
title: "Git-平台PK多任务与强化学习代码实现"
type: model-card
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: department
source_ids:
  - "repo:git@git.xiaojukeji.com:bwh_stg/platform_pk.git@7b0870808d6f9273e7347536a7a53301a1abb3a8"
  - "repo:git@git.xiaojukeji.com:bwh_stg/pk_strategy_wiki.git@a2fecfd0f41b31e34a374d53a95a08b74cf4ad88:wiki/models/PLE多任务模型.md"
  - "repo:git@git.xiaojukeji.com:bwh_stg/pk_strategy_wiki.git@a2fecfd0f41b31e34a374d53a95a08b74cf4ad88:wiki/models/DQN.md"
related:
  - "PK模型谱系.md"
  - "PK动态窗口DQN.md"
  - "../来源/git-bwh-platform-pk与策略Wiki.md"
---

# Git-平台PK多任务与强化学习代码实现

> 本页将固定提交中能直接阅读的源码与策略 Wiki 分开。源码存在只能证明有相应实现，不证明当前已部署、实验仍在运行或线上收益仍有效。本页不转载生产路径、表名、调度信息和特征配置全量。

## 源码事实：PLE 多任务分支

来源：`bwh_stg/platform_pk@7b0870808d6f9273e7347536a7a53301a1abb3a8` 的 `pk_multitask_model/`。

| 层次 | 可验证实现 |
| --- | --- |
| 输入 | 将类别、通用数值、连环派数值、非连环派数值、二值分流和 POSO 输入分组；类别特征做 Embedding，数值特征归一化后做 Scalar2Vec。 |
| Expert | 共 15 个 Expert，按连环派、共享、非连环派三组输入组织；数值表达还使用平方、平方根、对数和高斯形变换构造多组 Expert 输入。 |
| Expert 内部 | DNN 与一层 CrossNetwork 的输出拼接，再经瓶颈层；POSO 输入生成逐 Expert 缩放。 |
| Gate/Tower | 6 个 softmax Gate 各混合 10 个 Expert，Expert 区间部分重叠；6 个 Tower 经二值场景分流后合成 OD/O/D 三个概率，另有一条独立分支输出 T，最终是 4 个概率。 |
| 训练 | 对 OD/O/D/T 使用按任务样本筛选的 BCE，梯度做范数裁剪；验证指标是四个任务分别的 AUC。 |
| 工程出口 | 训练脚本导出模型，预测脚本通过批处理预测器写出四列预测概率。 |

这些代码细节补充了既有 [PK模型谱系](PK模型谱系.md) 中的结构摘要，尤其是“6 Tower 如何合成 3+1 输出”和“共享 Expert 通过区间重叠实现”。

## 源码事实：DQN 动态窗口分支

来源：同一提交的 `pk_rl/`。

- 模型将状态拆为通用、当前胜者、当前败者三组，分别做类别 Embedding、数值归一化和两层 MLP，拼接后输出两个动作 Q 值。
- 训练状态是最长 20 步的序列；下一状态由序列左移一步构造。奖励同时包含终止基础项、完单项、时间惩罚与 PK 分变化项，TD 目标对不等时间间隔使用指数折扣。
- 实现保留主网络与目标网络，定期将主网络参数复制到目标网络；使用 MSE 和梯度裁剪训练，并导出 ONNX。
- 验证脚本输出第一个“结束窗口”动作的位置分布，并按部分终止/完单组合分组查看。这是代码层的离线评估输出，不是线上实验结论。

### 代码与文档的一个重要差异

`pk_strategy_wiki@a2fecfd0...` 的 DQN 页面把“经验回放”和“ε-贪婪探索”列为训练机制；但此次可读的 `platform_pk@7b087080...` 训练入口是顺序消费离线表数据，未见显式 replay buffer 或 ε-贪婪动作采样。因此应把前者标成“文档方案/其他链路可能实现”，不能归因到这一固定提交。

## 文档方案、离线结果与线上事实的边界

| 证据类型 | 本批可说的内容 | 不能推导 |
| --- | --- | --- |
| 源码事实 | 上述 TensorFlow/PyTorch 模型、训练、验证和导出逻辑存在于固定提交。 | 代码已通过生产验收、当前仍在调度。 |
| 文档方案 | 策略 Wiki 将 PLE 用于履约/最近司机多任务预测，将 DQN 用于“继续/结束”窗口决策。 | 文档中的路线图或机制都在本提交实现。 |
| 离线结果 | 策略 Wiki 记录的 AUC、验证损失或动作分布属于特定数据和时点。 | 可跨数据期、城市或任务口径横向比较。 |
| 线上事实 | 策略 Wiki 历史记载 PLE V1 扩量失败，也记载 DQN 曾处5%流量实验。 | 2026-11 仍为该状态；当前线上模型、流量和收益仍需工程/实验平台复核。 |

## 未覆盖

- 未运行训练、回放历史数据或验证导出模型的可加载性。
- 未校验生产特征一致性、模型注册、调度和服务端接入。
- 配置中的全量特征名、归一化常数和内部存储位置不在 Wiki 复制。

