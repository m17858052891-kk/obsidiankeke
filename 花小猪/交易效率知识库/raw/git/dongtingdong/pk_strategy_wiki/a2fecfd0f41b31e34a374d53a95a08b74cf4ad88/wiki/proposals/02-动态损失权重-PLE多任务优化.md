---
title: "策略方案：动态损失权重优化 PLE 多任务训练"
type: proposal
created: 2026-05-26
updated: 2026-05-26
priority: 高
difficulty: 低
status: 方案设计
sources:
  - raw-research/多任务学习最新方法综述.md
tags:
  - 多任务学习
  - 损失函数
  - PLE
  - pk窗口
  - 策略方案
related:
  - wiki/research/多任务学习迭代方向.md
  - wiki/models/PLE多任务模型.md
  - wiki/entities/PK窗口.md
  - wiki/concepts/AUC.md
---

# 策略方案：动态损失权重优化 PLE 多任务训练

## 1. 方案概述

### 1.1 一句话摘要

将 PLE 多任务模型的固定 BCE loss 权重替换为动态自适应权重机制，自动平衡 4 个任务（OD/O/D/T）的优化速度，缓解跷跷板效应和数据不平衡，提升核心任务 OD 的 AUC。

### 1.2 方案定位

| 维度 | 说明 |
|---|---|
| **目标模块** | [[wiki/models/PLE多任务模型.md\|PLE 多任务模型]]（动态窗口 V1 核心模型）|
| **核心问题** | 4 任务固定权重导致跷跷板效应、数据不平衡、梯度冲突 |
| **技术来源** | MTLPT 动态权重（Nature SR, 2025）+ Uncertainty Weighting (Kendall 2018) |
| **预期收益** | OD AUC 从 0.779 → ==0.785+==，训练收敛稳定性提升 |
| **实施周期** | ==1-2 周==（最快可验证的方向）|

---

## 2. 背景与动机

### 2.1 当前 PLE 训练现状

[[wiki/models/PLE多任务模型.md|PLE 模型]]当前配置：

| 任务 | 正样本定义 | AUC | 正样本率（估） | Loss 权重 |
|---|---|---|---|---|
| **OD**（司乘整体履约） | 完单 | ==0.779== | ~65% | 1.0 |
| **O**（乘客履约） | 乘客未取消 | 0.768 | ~80% | 1.0 |
| **D**（司机履约） | 司机未取消 | ==0.855== | ~90% | 1.0 |
| **T**（Top1 司机） | 接驾距离最短 | ==0.899== | ~30% | 1.0 |

当前使用均匀权重 `[1.0, 1.0, 1.0, 1.0]`，总 loss = BCE_OD + BCE_O + BCE_D + BCE_T。

### 2.2 存在的问题

#### 问题 1：跷跷板效应

T 任务 AUC 已达 0.899（接近天花板），继续优化 T 的梯度可能与 OD/O 冲突：
- T 任务偏好"选最近的司机"
- OD 任务偏好"选最可能完单的司机"（不一定最近）
- 两者梯度方向在特征维度上部分对立

#### 问题 2：数据不平衡

| 任务 | 正样本率 | 问题 |
|---|---|---|
| D（司机履约） | ~90% | 极度不平衡，正样本过多，loss 信号微弱 |
| T（Top1 司机） | ~30% | 负样本为主，但已训练充分（AUC 0.899） |
| OD（核心） | ~65% | 中等平衡，但受其他任务干扰 |

#### 问题 3：任务梯度冲突

直觉示例：
- 某订单中，司机A 接驾距离短（T 任务偏好），但历史取消率高（OD 任务不偏好）
- 统一优化下，梯度指向折衷方向，两个任务都未充分优化

### 2.3 动机总结

> 不改模型结构，仅通过 loss 权重的动态调整，即可获得显著的多任务优化收益。
> 这是**改动最小、验证最快、风险最低**的优化方向。

---

## 3. 技术方案

### 3.1 方案对比

| 方案 | 原理 | 优点 | 缺点 | 推荐度 |
|---|---|---|---|---|
| **A：DWA（Dynamic Weight Average）** | 基于 loss 下降速率调整权重 | 简单直观 | 对初始 loss 敏感 | ⭐⭐ |
| **B：Uncertainty Weighting** | 学习 homoscedastic uncertainty | 理论优美，端到端 | 增加可学参数 | ==⭐⭐⭐== |
| **C：GradNorm** | 归一化各任务梯度范数 | 直接对齐梯度 | 计算开销大 | ⭐⭐ |
| **D：MTLPT 指数调整** | loss 比值指数变换 | 响应迅速 | temperature 需调优 | ⭐⭐ |

**推荐方案 B（Uncertainty Weighting）为主，方案 A（DWA）为备选**。

### 3.2 方案 B：Uncertainty Weighting（推荐）

#### 原理

基于 Kendall et al. (2018) 的多任务学习不确定性加权：

$$\mathcal{L}_{total} = \sum_{i=1}^{4} \frac{1}{2\sigma_i^2} \mathcal{L}_i + \log \sigma_i$$

其中 $\sigma_i$ 是每个任务的**同方差不确定性**（homoscedastic uncertainty），作为可学习参数，训练过程中自动调整。

- 当任务 $i$ 的 loss 较大（难度高/数据噪声大）时，$\sigma_i$ 增大，有效权重 $\frac{1}{2\sigma_i^2}$ 减小，避免过度关注噪声
- 当任务 $i$ 的 loss 较小（已收敛）时，$\sigma_i$ 减小，权重增大——但 $\log \sigma_i$ 项会阻止 $\sigma_i$ 无限缩小

#### 实现代码

```python
class MultiTaskUncertaintyLoss(nn.Module):
    """
    Uncertainty Weighting for Multi-Task Learning
    适用于 PLE 4 任务：OD, O, D, T
    """
    def __init__(self, num_tasks=4, init_sigma=1.0):
        super().__init__()
        # log(sigma^2) 作为可学习参数，初始化为 0 => sigma=1
        self.log_vars = nn.Parameter(
            torch.full((num_tasks,), math.log(init_sigma ** 2))
        )
    
    def forward(self, losses: list):
        """
        Args:
            losses: [loss_OD, loss_O, loss_D, loss_T]，每个为标量
        Returns:
            total_loss: 加权总损失
            weights: 当前各任务有效权重（用于监控）
        """
        total_loss = 0
        weights = []
        for i, loss in enumerate(losses):
            precision = torch.exp(-self.log_vars[i])  # 1/sigma^2
            total_loss += precision * loss + self.log_vars[i]
            weights.append(precision.item())
        return total_loss, weights
```

#### 训练配置

```python
# 模型和loss初始化
model = PLEModel(...)
uncertainty_loss = MultiTaskUncertaintyLoss(num_tasks=4, init_sigma=1.0)

# 优化器需包含 loss 的可学参数
optimizer = Adam([
    {'params': model.parameters(), 'lr': 0.01},
    {'params': uncertainty_loss.parameters(), 'lr': 0.001}  # loss参数用较小lr
])

# 训练循环
for batch in dataloader:
    pred_od, pred_o, pred_d, pred_t = model(batch)
    
    loss_od = F.binary_cross_entropy(pred_od, label_od)
    loss_o = F.binary_cross_entropy(pred_o, label_o)
    loss_d = F.binary_cross_entropy(pred_d, label_d)
    loss_t = F.binary_cross_entropy(pred_t, label_t)
    
    total_loss, weights = uncertainty_loss([loss_od, loss_o, loss_d, loss_t])
    
    optimizer.zero_grad()
    total_loss.backward()
    optimizer.step()
    
    # 监控权重变化
    log_weights(weights)  # 期望：w_OD > w_O > w_T > w_D
```

### 3.3 方案 A：DWA（备选）

#### 原理

Dynamic Weight Average（Liu et al., 2019）：根据每个任务 loss 的下降速率动态调整权重。

$$w_i(t) = \frac{K \cdot \exp(r_i(t-1) / T)}{\sum_j \exp(r_j(t-1) / T)}$$

其中 $r_i(t) = \frac{\mathcal{L}_i(t)}{\mathcal{L}_i(t-1)}$ 为 loss 比率，T 为温度。

#### 实现

```python
class DWALoss:
    """
    Dynamic Weight Average
    """
    def __init__(self, num_tasks=4, temperature=2.0):
        self.num_tasks = num_tasks
        self.T = temperature
        self.prev_losses = None
    
    def compute_weights(self, current_losses: list):
        if self.prev_losses is None:
            self.prev_losses = current_losses
            return [1.0] * self.num_tasks
        
        # 计算loss比率
        ratios = [curr / (prev + 1e-8) 
                  for curr, prev in zip(current_losses, self.prev_losses)]
        
        # softmax with temperature
        exp_ratios = [math.exp(r / self.T) for r in ratios]
        sum_exp = sum(exp_ratios)
        weights = [self.num_tasks * e / sum_exp for e in exp_ratios]
        
        self.prev_losses = current_losses
        return weights
```

#### 温度参数选择

| T | 效果 | 适用场景 |
|---|---|---|
| T → 0 | 所有权重集中在 loss 下降最慢的任务 | 极端不平衡 |
| T = 1 | 线性响应 | 一般情况 |
| ==T = 2== | 平滑响应（推荐） | PLE 场景 |
| T → ∞ | 等权重退化 | 无效果 |

### 3.4 方案选择建议

```
Step 1: 先实现 Uncertainty Weighting（方案B）
        → 如果 OD AUC 提升 ≥ 0.3pp，直接采用
        
Step 2: 如果方案B提升不显著，实验 DWA（方案A）
        → 调 T ∈ {1.0, 1.5, 2.0, 3.0}
        
Step 3: 如果两者都不理想，尝试组合
        → Uncertainty Weighting + 手动约束 w_OD ≥ w_others
```

---

## 4. 实验设计

### 4.1 离线实验矩阵

| 实验组 | Loss 方案 | 关键参数 | 目标 |
|---|---|---|---|
| **Baseline** | 固定等权重 [1,1,1,1] | — | 复现当前 PLE |
| **Exp-A1** | DWA | T=1.0 | — |
| **Exp-A2** | DWA | T=2.0 | — |
| **Exp-B1** | Uncertainty | init_sigma=1.0 | ==主实验== |
| **Exp-B2** | Uncertainty | init_sigma=0.5 | 敏感性检验 |
| **Exp-C** | 手动调优 [2,1,0.5,0.5] | — | OD 优先 baseline |
| **Exp-D** | GradNorm | alpha=1.5 | 消融对比 |

### 4.2 评估指标

| 指标 | 权重 | 说明 |
|---|---|---|
| **OD AUC** | ==核心== | 必须提升，直接影响窗口决策质量 |
| O AUC | 次要 | 乘客取消预测，影响窗口延长判断 |
| D AUC | 参考 | 已在高位（0.855），允许微降 |
| T AUC | 参考 | 已在高位（0.899），允许微降 |
| 训练收敛速度 | 参考 | epoch 数减少为正向 |
| 权重稳定性 | 监控 | σ 值训练后期应趋于稳定 |

### 4.3 成功标准

| 条件 | 标准 |
|---|---|
| **必须满足** | OD AUC ≥ 0.782（+0.3pp） |
| **理想目标** | OD AUC ≥ 0.785（+0.6pp） |
| **不可接受** | O AUC 下降超过 1pp |
| **bonus** | 训练 epoch 数减少 20%+ |

---

## 5. 实施计划

### 5.1 时间线

```
Day 1-2:   代码实现（Uncertainty + DWA）
Day 3-4:   Baseline 复现 + 实验矩阵跑通
Day 5-7:   全量实验 + 结果分析
Day 8-9:   消融实验 + 最优配置确认
Day 10:    实验报告 + 是否上线决策
```

### 5.2 工程改动范围

| 改动 | 文件/模块 | 影响 |
|---|---|---|
| 新增 loss 模块 | `loss/uncertainty.py` | 新文件，不影响现有 |
| 修改训练入口 | `train.py` | 替换 loss 计算逻辑 |
| 新增监控指标 | `metrics/` | 记录各任务权重变化 |
| ==不改== | 模型结构 | PLE 架构保持不变 |
| ==不改== | 特征 | 特征工程不变 |
| ==不改== | 推理逻辑 | 线上推理不受影响 |

> [!info] 关键优势
> 动态损失权重**仅影响训练过程**，训练完成后的模型权重与普通模型没有区别。线上推理无任何额外开销。

### 5.3 EVE 平台适配

| 步骤 | 操作 |
|---|---|
| 1 | 在 EVE 训练配置中新增 `loss_type` 参数 |
| 2 | 支持 `loss_type = "uncertainty"` / `"dwa"` / `"fixed"` |
| 3 | 增加 loss 参数的 checkpoint 保存（用于分析 σ 演化） |
| 4 | Tensorboard 新增 task_weights 曲线 |

---

## 6. 监控与可视化

### 6.1 训练阶段监控

```
┌─────────────────────────────────────────────┐
│  Task Weight Evolution (Uncertainty)         │
│                                             │
│  w_OD ━━━━━━━━━━━━━━━━━━━━━━  2.1          │
│  w_O  ━━━━━━━━━━━━━━━          1.3          │
│  w_D  ━━━━━━━━                 0.6          │
│  w_T  ━━━━━━━━━                0.7          │
│       ─────────────────────────────         │
│       epoch 1    5    10   15   20          │
└─────────────────────────────────────────────┘
```

**预期权重走向**：
- w_OD（核心任务）：逐步升高 → 模型更关注完单预测
- w_O（乘客）：中等稳定
- w_D（司机，数据不平衡）：降低 → 避免简单任务占据梯度
- w_T（已收敛）：降低 → 避免过拟合

### 6.2 异常告警

| 告警条件 | 含义 | 处理 |
|---|---|---|
| 任何 σ > 10 | 该任务被几乎忽略 | 检查数据质量 |
| 任何 σ < 0.01 | 该任务权重爆炸 | 添加 σ 下界约束 |
| w_OD < w_others | 核心任务反而权重低 | 添加 w_OD ≥ 1.0 硬约束 |
| Loss NaN | 数值不稳定 | 添加 loss clipping |

---

## 7. 风险与应对

| 风险 | 概率 | 影响 | 应对 |
|---|---|---|---|
| OD 权重不升反降 | 低 | 核心任务效果变差 | 添加 `w_OD ≥ min_weight` 硬约束 |
| 数值不稳定 | 低 | 训练 NaN | σ clamp 在 [0.01, 10] |
| 过拟合 sigma | 中 | 权重震荡 | sigma 参数使用较小 lr (0.001) |
| 收益不显著 | 中 | 投入无产出 | 1 周快速验证，fail fast |

---

## 8. 成功指标总结

| 类别 | 指标 | 目标值 |
|---|---|---|
| **精度** | OD AUC | ≥ ==0.785==（+0.6pp）|
| **精度** | O AUC | ≥ 0.765（不降超 0.3pp）|
| **效率** | 训练收敛 epoch | 减少 ≥ 20% |
| **稳定性** | σ 值方差（后 5 epoch） | < 0.1 |
| **工程** | 推理 latency 变化 | ==0==（无额外开销）|

---

## 9. 后续扩展

| 方向 | 描述 | 时机 |
|---|---|---|
| **梯度手术（PCGrad/CAGrad）** | 在梯度层面解决冲突 | Uncertainty 收益不足时 |
| **任务优先级约束** | 硬约束 OD 为主任务 | 权重未自动收敛到预期时 |
| **动态任务掩码** | 某些 batch 只训练部分任务 | D 任务数据极度不平衡时 |
| **与 MoE 结合** | MoE Expert 内也用动态权重 | [[wiki/proposals/01-sparse-moe-多商家差异化建模.md\|MoE 方案]]落地后 |

---

## 10. 参考

- Kendall, A., Gal, Y., Cipolla, R. (2018). "Multi-task learning using uncertainty to weigh losses for scene geometry and semantics." CVPR.
- Liu, S., Johns, E., Davison, A.J. (2019). "End-to-End Multi-Task Learning with Attention." CVPR.
- MTLPT: A lightweight transformer based multi task learning model with dynamic weight allocation (Nature SR, 2025)
- Chen, Z. et al. (2018). "GradNorm: Gradient Normalization for Adaptive Loss Balancing in Deep Multitask Networks." ICML.
- [[wiki/research/多任务学习迭代方向.md]] — 方向评估总览
