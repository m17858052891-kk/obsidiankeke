---
title: "Git 乘客远接驾盲盒与换车代码实现"
type: model-card
owner: "@tommywujian"
freshness: commit-pinned
status: code-evidence
last_reviewed: "2026-11-05"
permission_scope: department
source_ids:
  - "repo:bwh_stg/trade-of-passenger@cdef137c38e2640e33754bbdba3c9bcfb12be3bb"
related:
  - "盲盒补贴取消率双塔模型.md"
  - "接驾远换车取消与意愿模型.md"
  - "盲盒取消弹性模型.md"
---

# Git 乘客远接驾盲盒与换车代码实现

> 本页只记录仓库 `bwh_stg/trade-of-passenger` 在 commit `cdef137c38e2640e33754bbdba3c9bcfb12be3bb` 可静态验证的实现。它补充既有方案页的代码细节，不证明模型已训练完成、部署或取得线上收益。

## 仓库范围

仓库 README 将代码分为 `pickup_far_blindbox`（接驾远盲盒）和 `pickup_far_exchange`（接驾远换车）两部分。两者都使用 PyTorch 与 dmlite 的表数据、模型保存和批量预测接口；模型直接把配置中的类别特征数与数值特征数相加，作为统一注意力模块的输入维度。

## 盲盒：结构性单调约束双塔

### 代码实现

- `pickup_far_blindbox/model.py` 先将每个标量特征映射为向量，并加入可学习的位置向量；随后以 4 头自注意力学习特征交互，经残差、LayerNorm 和展平投影得到共享表示。
- 共享 MLP 后有两个输出分支：基础取消概率 `p_base`，以及经过 sigmoid 的折扣系数 `r`。券后取消概率按 `p_coupon = stop_gradient(p_base) * r` 构造，因此前向计算中必有 `0 ≤ p_coupon ≤ p_base`。
- `stop_gradient` 使券后样本的损失不会反向更新基础取消头，只更新共享表示之后的折扣系数分支；基础头由无券样本监督。该梯度隔离是代码事实，也是复现实验时需要单独评估的建模选择。
- 损失按 treatment 分流：无券样本对基础头计算二元交叉熵，有券样本对券后头计算二元交叉熵；若没有 treatment，则两个头都对同一标签计算 BCE 并相加。
- `predict.py` 将两个概率按列表写入 dmlite 的预测字段。代码没有直接输出 ITE；若业务需要“取消改善”，需在下游明确使用何种方向和公式（例如 `p_base - p_coupon`）。

### 离线评估实现

`pickup_far_blindbox/assess.py` 把 `1 - is_p_cancel` 作为 outcome、`is_coupon` 作为 treatment、`pred_ite` 作为排序分数，计算归一化 Dini 与 Qini，并生成 Qini 曲线。随机基线固定 seed 42，曲线默认使用 100 个分点。该脚本证明仓库包含 uplift 排序评估工具，但不提供本 commit 的实际指标结果。

### 配置默认值与入口状态

- 训练入口随机种子为 100；命令行学习率默认值为 0.01，但优化器实际构造为 `Adam(model.parameters())`，没有传入该参数，因此实际采用 PyTorch Adam 的默认学习率。
- 配置中的数值基线若等于 `-9999.0`，入口会替换为 0；具体特征清单与缩放参数依赖仓库外的 `config.yaml`，本 commit 未包含该文件。
- 当前 `main.py` 会先从工作目录加载固定文件名 `model_state_dict.pth`，随后才可选加载 `--modelInputs`；数据集构造与训练循环整体被注释，实际主流程是加载权重并导出 ONNX。故本快照不能直接作为完整训练脚本复现。

## 换车：取消与意愿联合建模

### 代码实现

- `pickup_far_exchange/model.py` 使用与盲盒相同的标量嵌入、可学习位置向量和 4 头特征自注意力，再经共享 MLP 接取消塔与意愿塔，分别输出 `p_cancel`、`p_willing`。
- 损失由两项 BCE 相加：取消标签监督 `p_cancel`；第二标签监督 `p_cancel * p_willing`。这是代码层面的 ESMM 式乘积约束，意味着第二标签按联合事件概率训练，而不是直接用 `p_willing` 做 BCE。
- `predict.py` 输出两个原始塔概率，不输出乘积概率；消费方必须明确第二列是意愿塔条件因子，还是业务约定的其他概率，不能仅按字段位置推断含义。

### 配置默认值与入口状态

- 训练随机种子为 100；命令行学习率默认值为 0.01，但同样没有传给 Adam。
- 数据加载使用 dmlite 的可迭代表数据集，batch size、epoch 数和 worker 数来自仓库外 `config.yaml`；`-9999.0` 的数值基线同样会被替换为 0。
- 验证日志两处引用了未定义变量 `auc_c_i`，而实际计算变量名是 `auc_c_w`，执行到这些日志会报错。
- 保存声明的输入形状是 `[-1, 2]`，示例输入却是 `[14, 137]`；同时关闭 ONNX 导出。真实特征维度由配置决定，复用前需统一模型签名。

## 代码证据与线上事实边界

| 层级 | 本 commit 可确认 | 本 commit 不能确认 |
| --- | --- | --- |
| 模型结构 | 注意力共享表示、双塔输出、盲盒单调乘积、换车 ESMM 式乘积损失 | 当前生产服务实际使用的模型结构与版本 |
| 训练 | 标签/处理分流与损失函数的代码意图 | 配置、样本表、完整可运行训练、收敛与校准 |
| 评估 | 盲盒包含 Qini/Dini 计算脚本 | 本 commit 对应的离线 AUC、Qini、Dini 数值 |
| 交付 | 存在 dmlite 保存与批预测入口 | 已部署、已切流、线上延迟、实验显著性或收益 |

因此，既有 Wiki 中的方案目标、离线结果和线上事实仍应分别引用各自证据；不得用这个代码快照补写上线状态或业务效果。仓库也未包含运行所需的配置、数据与权重文件，本次未执行训练或推理。

## 关联页面

- [盲盒补贴取消率双塔模型](盲盒补贴取消率双塔模型.md)
- [接驾远换车取消与意愿模型](接驾远换车取消与意愿模型.md)
- [盲盒取消弹性模型](盲盒取消弹性模型.md)
