---
title: "策略方案：Model Merging 多模型统一部署优化"
type: proposal
created: 2026-05-27
updated: 2026-05-27
priority: 低
difficulty: 低
status: 方案设计
sources:
  - raw-research/多任务学习最新方法综述.md
tags:
  - Model-Merging
  - 模型部署
  - 降本增效
  - 策略方案
related:
  - wiki/research/多任务学习迭代方向.md
  - wiki/models/模型架构总览.md
  - wiki/entities/自动化更新机制.md
  - wiki/models/LR逻辑回归.md
  - wiki/models/Wide&Deep.md
  - wiki/models/PLE多任务模型.md
  - wiki/models/DQN.md
---

# 策略方案：Model Merging 多模型统一部署优化

## 1. 方案概述

### 1.1 一句话摘要

利用 Model Merging 技术将 PK 系统中多个独立训练的模型合并为统一推理框架，降低在线服务的模型数量、推理延迟和维护成本，同时保持各任务精度不降。

### 1.2 方案定位

| 维度 | 说明 |
|---|---|
| **目标模块** | PK 在线推理服务 / 模型部署流程 |
| **核心问题** | 模型数量增长 → 部署成本和推理链路复杂度上升 |
| **技术来源** | Model Merging 范式（2025 热门方向）：Task Arithmetic / TIES-Merging / DARE |
| **预期收益** | 推理 latency ==-30~50%==，模型维护成本 ==-40%==，部署复杂度降低 |
| **实施周期** | 3-4 周 |
| **建议时间窗口** | 模型架构稳定后（2027 Q1+），当前优先级低 |

---

## 2. 背景与动机

### 2.1 当前多模型现状

PK 系统目前维护的独立模型：

| 模型 | 模块 | 状态 | 推理链路 | 更新频率 |
|---|---|---|---|---|
| [[花小猪/PK策略知识库/wiki/models/LR逻辑回归.md\|LR]] | PK 打分 | ==线上生产== | 主链路 | 周级自动 |
| [[花小猪/PK策略知识库/wiki/models/Wide&Deep.md\|Wide&Deep]] | PK 打分 | 实验中 | AB 分流 | 按需 |
| [[花小猪/PK策略知识库/wiki/models/PLE多任务模型.md\|PLE]] | 窗口决策 | 离线 | 离线 | — |
| [[花小猪/PK策略知识库/wiki/models/DQN.md\|DQN]] | RL 窗口 | ==5% 在线== | 并行链路 | ==日级自动== |

**未来可能新增**（根据其他方案）：

| 模型 | 来源 | 增量 |
|---|---|---|
| MoE | [[花小猪/PK策略知识库/wiki/proposals/01-sparse-moe-多商家差异化建模.md]] | 新模型 |
| Dual-Encoder | [[花小猪/PK策略知识库/wiki/proposals/03-dual-encoder-异构场景建模.md]] | 新模型 |
| Reward Model | [[花小猪/PK策略知识库/wiki/proposals/04-偏好对齐-DPO-IPA.md]] | 新模型 |

### 2.2 成本问题

| 成本维度 | 当前 | 模型增加后 |
|---|---|---|
| **推理服务实例** | 2 套（LR + DQN） | 4-5 套 |
| **模型加载内存** | ~2 GB | ~5-8 GB |
| **串行推理延迟** | ~20ms（LR + DQN） | ~50-80ms |
| **自动更新管线** | 2 条 | 4-5 条 |
| **AB 实验复杂度** | 2 层分流 | 4-5 层分流 |
| **值班运维负担** | 中 | 高 |

### 2.3 Model Merging 的适用性

Model Merging 适合 PK 场景的原因：
- 多个模型的**输入特征高度重叠**（都使用司机/乘客/订单/供需特征）
- 模型服务**同一业务链路**（PK 决策），具有内在任务关联性
- 推理**延迟要求严格**（<50ms），减少模型数量直接降低延迟

---

## 3. 技术方案

### 3.1 方案对比

| 方案 | 原理 | 优点 | 缺点 | 适用性 |
|---|---|---|---|---|
| **A: Task Arithmetic** | 各任务模型参数向量相加/减 | 简单、无需重训 | 精度损失可能较大 | ⭐⭐ |
| **B: TIES-Merging** | 修剪冲突参数 + 符号一致性 | 精度更优 | 需调超参 | ==⭐⭐⭐== |
| **C: DARE** | 随机丢弃 + 缩放 | 支持大量模型合并 | 随机性引入方差 | ⭐⭐ |
| **D: 多头共享骨干** | 统一骨干 + 多预测头 | 最根本的解决 | 需要重新联合训练 | ⭐⭐⭐ |

**推荐：方案 D（多头共享骨干）为主，方案 B（TIES-Merging）为备选**。

> [!info] 方案选择依据
> PK 系统模型都是相对小型的 DNN，不是大语言模型。Task Arithmetic 等方法主要针对大模型微调场景。对 PK 来说，更实际的做法是设计多头共享骨干架构进行联合训练。

### 3.2 方案 D：多头共享骨干架构（推荐）

#### 架构设计

```
┌─────────────────────────────────────────────────────────────┐
│                     统一输入层                                │
│  [订单] [司机] [乘客] [供需] [商家ID] [城市ID] [窗口状态]     │
└──────────────────────────┬──────────────────────────────────┘
                           │
                ┌──────────▼──────────┐
                │   Shared Backbone   │
                │                     │
                │  Embedding Layer    │
                │       ↓             │
                │  [256] → ReLU       │
                │       ↓             │
                │  [128] → ReLU       │
                │       ↓             │
                │  Shared Repr [64]   │
                └──────────┬──────────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
   ┌──────▼──────┐ ┌──────▼──────┐ ┌──────▼──────┐
   │  Head_PK    │ │ Head_Window │ │ Head_Cancel │
   │ (PK打分)    │ │ (窗口决策)  │ │ (取消预测)  │
   │             │ │             │ │             │
   │ [32]→[1]   │ │ [32]→[4]   │ │ [32]→[2]   │
   │ sigmoid    │ │ sigmoid×4  │ │ sigmoid×2  │
   └─────────────┘ └─────────────┘ └─────────────┘
        ↓                ↓                ↓
   PK完单概率     OD/O/D/T概率     乘客/司机取消概率
```

#### 三个预测头

| Head | 预测目标 | 对应现有模型 | 输出维度 |
|---|---|---|---|
| **Head_PK** | 司乘组合完单概率 | LR / Wide&Deep | 1 |
| **Head_Window** | OD/O/D/T 四任务概率 | PLE | 4 |
| **Head_Cancel** | 乘客取消/司机取消概率 | 治理因子模型 | 2 |

#### 实现代码

```python
class UnifiedPKModel(nn.Module):
    """
    统一 PK 推理模型：共享骨干 + 多预测头
    """
    def __init__(self, feature_dim, backbone_dims=[256, 128, 64], head_hidden=32):
        super().__init__()
        
        # 共享骨干
        self.backbone = nn.Sequential(
            nn.Linear(feature_dim, backbone_dims[0]),
            nn.ReLU(),
            nn.BatchNorm1d(backbone_dims[0]),
            nn.Linear(backbone_dims[0], backbone_dims[1]),
            nn.ReLU(),
            nn.Linear(backbone_dims[1], backbone_dims[2])
        )
        
        # PK 打分头
        self.head_pk = nn.Sequential(
            nn.Linear(backbone_dims[2], head_hidden),
            nn.ReLU(),
            nn.Linear(head_hidden, 1),
            nn.Sigmoid()
        )
        
        # 窗口决策头（4 任务）
        self.head_window = nn.Sequential(
            nn.Linear(backbone_dims[2], head_hidden),
            nn.ReLU(),
            nn.Linear(head_hidden, 4),
            nn.Sigmoid()
        )
        
        # 取消预测头
        self.head_cancel = nn.Sequential(
            nn.Linear(backbone_dims[2], head_hidden),
            nn.ReLU(),
            nn.Linear(head_hidden, 2),
            nn.Sigmoid()
        )
    
    def forward(self, features, task='all'):
        shared_repr = self.backbone(features)
        
        if task == 'pk':
            return self.head_pk(shared_repr)
        elif task == 'window':
            return self.head_window(shared_repr)
        elif task == 'cancel':
            return self.head_cancel(shared_repr)
        else:
            return {
                'pk': self.head_pk(shared_repr),
                'window': self.head_window(shared_repr),
                'cancel': self.head_cancel(shared_repr)
            }
```

#### 训练策略

```python
# 多任务联合训练，使用动态损失权重（可结合方案2）
loss_pk = F.binary_cross_entropy(pred_pk, label_pk)
loss_window = sum(F.binary_cross_entropy(pred_w[i], label_w[i]) for i in range(4))
loss_cancel = sum(F.binary_cross_entropy(pred_c[i], label_c[i]) for i in range(2))

# 动态权重或固定权重
total_loss = w_pk * loss_pk + w_window * loss_window + w_cancel * loss_cancel
```

### 3.3 方案 B：TIES-Merging（备选）

适用于已独立训练好的模型，不需要重新联合训练：

```python
def ties_merging(models, base_model, density=0.5):
    """
    TIES-Merging: Trim, Elect Sign, Merge
    
    Args:
        models: [model_lr, model_ple, model_dqn] 各任务微调模型
        base_model: 基础预训练模型（如果有）
        density: 保留参数比例
    """
    # Step 1: 计算各模型的 task vector (δ)
    task_vectors = [m.params - base_model.params for m in models]
    
    # Step 2: Trim — 按绝对值排序，保留 top density% 参数
    for tv in task_vectors:
        threshold = torch.quantile(tv.abs(), 1 - density)
        tv[tv.abs() < threshold] = 0  # 修剪小参数
    
    # Step 3: Elect Sign — 对每个参数位置，投票决定正负号
    signs = torch.sign(sum(tv.sign() for tv in task_vectors))
    
    # Step 4: 仅保留与多数符号一致的参数
    for tv in task_vectors:
        tv[tv.sign() != signs] = 0
    
    # Step 5: 合并
    merged_vector = sum(task_vectors) / len(task_vectors)
    merged_model = base_model.params + merged_vector
    
    return merged_model
```

> [!warning] TIES-Merging 的前提
> 要求各任务模型从**同一基础模型**微调而来。当前 LR、PLE、DQN 架构完全不同，无法直接 TIES。需要先统一为同一骨干架构，再分别微调，最后 TIES 合并。

---

## 4. 收益分析

### 4.1 推理链路优化

| 场景 | 当前 | 合并后 |
|---|---|---|
| PK 打分 | LR 推理 (5ms) | 统一模型推理 (15ms)，一次前向传播 |
| 窗口决策 | PLE 推理 (20ms) | 同上（Head_Window 复用 backbone） |
| 取消预测 | 独立模型 (10ms) | 同上（Head_Cancel 复用 backbone） |
| **总串行延迟** | ==35ms== | ==15ms==（==-57%==）|

### 4.2 运维成本优化

| 维度 | 当前（多模型） | 合并后（统一模型） | 节省 |
|---|---|---|---|
| 在线服务实例 | 3-4 套 | 1 套 | ==-60~75%== |
| 模型文件管理 | 3-4 个版本管线 | 1 个 | ==-60~75%== |
| AB 实验复杂度 | 多层分流 | 单层 | 显著简化 |
| [[花小猪/PK策略知识库/wiki/entities/自动化更新机制.md\|自动更新]]管线 | 3-4 条 | 1 条 | ==-60~75%== |
| 回滚操作 | 按模型逐个回滚 | 整体回滚 | 简化 |

### 4.3 潜在风险

| 风险 | 影响 | 缓解 |
|---|---|---|
| 单点故障 | 统一模型挂了所有功能失效 | 保留 LR 作为兜底 |
| 更新耦合 | 更新一个 Head 需要重新部署整个模型 | 支持 Head 级别热更新 |
| 精度损失 | 共享骨干可能无法完美适配所有任务 | 骨干足够宽 + 消融验证 |

---

## 5. 实施计划

### 前提条件

> [!warning] 时机判断
> 本方案建议在以下条件满足后启动：
> 1. PK 打分架构稳定（Wide&Deep 或 MoE 方案已定稿）
> 2. PLE/DQN 与新打分模型的协同关系已明确
> 3. 模型数量确实达到 3+ 个在线并行

### 时间线（3-4 周）

```
W1:   统一骨干架构设计 + 特征对齐
      确认各 Head 的输入/输出接口
W2:   联合训练 + 各 Head 独立精度验证
      消融实验：共享骨干宽度搜索
W3:   推理服务改造 + 延迟测试
      多 Head 按需推理接口实现
W4:   在线 AB 验证 + 全量迁移
```

### 精度验证标准

| Head | 基线（独立模型） | 合并后目标 | 底线 |
|---|---|---|---|
| Head_PK | LR AUC 0.756 | ≥ 0.756 | ≥ 0.753 |
| Head_Window OD | PLE AUC 0.779 | ≥ 0.779 | ≥ 0.775 |
| Head_Cancel | 独立模型 AUC | ≥ 基线 | ≥ 基线 - 0.5pp |

---

## 6. 风险与应对

| 风险 | 概率 | 影响 | 应对 |
|---|---|---|---|
| 共享骨干容量不足 | 中 | 某个 Head 精度下降 | 增大骨干宽度 / 用独立 adapter |
| DQN 的 RL 训练与骨干冲突 | 高 | DQN 需要 online 更新，骨干冻结不兼容 | DQN 单独保留，仅合并监督学习模型 |
| 单模型依赖风险 | 中 | 全链路故障 | LR 兜底 + 自动降级机制 |
| 各 Head 更新节奏不一致 | 中 | 需要频繁全模型重训 | Head 参数独立可更新 |

---

## 7. 成功指标

| 类别 | 指标 | 目标 |
|---|---|---|
| **精度** | 各 Head AUC | 不降超 0.3pp |
| **延迟** | P99 latency | ==-30~50%== |
| **成本** | 推理服务实例数 | ==-60%+== |
| **运维** | 更新管线数 | 减少到 1 条 |
| **稳定性** | 故障恢复时间 | ≤ 5 分钟（含自动降级） |

---

## 8. 参考

- Ilharco et al. (2023). "Editing Models with Task Arithmetic." ICLR.
- Yadav et al. (2023). "TIES-Merging: Resolving Interference When Merging Models." NeurIPS.
- Yu et al. (2024). "Language Models are Super Mario: Absorbing Abilities from Homologous Models as a Free Lunch." ICML.
- [[花小猪/PK策略知识库/wiki/models/模型架构总览.md]] — 全模型索引
- [[花小猪/PK策略知识库/wiki/entities/自动化更新机制.md]] — 当前更新流程
- [[花小猪/PK策略知识库/wiki/research/多任务学习迭代方向.md]] — 方向评估总览
