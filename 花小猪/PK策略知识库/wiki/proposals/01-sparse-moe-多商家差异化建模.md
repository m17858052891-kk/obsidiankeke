---
title: "策略方案：Sparse MoE 多商家差异化建模"
type: proposal
created: 2026-05-26
updated: 2026-08-06
priority: 高
difficulty: 中
status: 方案设计
sources:
  - raw-research/多任务学习最新方法综述.md
tags:
  - MoE
  - 多商家
  - pk模型
  - 模型架构
  - 策略方案
related:
  - wiki/research/多任务学习迭代方向.md
  - wiki/models/PLE多任务模型.md
  - wiki/models/Wide&Deep.md
  - wiki/models/LR逻辑回归.md
  - wiki/entities/倾斜策略.md
  - wiki/entities/PK模型.md
---

# 策略方案：Sparse MoE 多商家差异化建模

## 1. 方案概述

### 1.1 一句话摘要

引入 Sparse Mixture-of-Experts（稀疏混合专家）架构，为不同商家/运力类型构建专属 Expert 网络，在统一推理框架下实现差异化建模，提升 PK 打分精度和商家公平性。

### 1.2 方案定位

| 维度 | 说明 |
|---|---|
| **目标模块** | PK 打分模型（当前 [[花小猪/PK策略知识库/wiki/models/LR逻辑回归.md\|LR 在线]]，[[花小猪/PK策略知识库/wiki/models/Wide&Deep.md\|Wide&Deep]] 实验中）|
| **核心问题** | 统一模型无法捕捉商家间行为差异，"商家公平性"与"精度最大化"结构性矛盾 |
| **技术来源** | 快手 IPA + Sparse MoE（2025，主站全量，用户观看时长 ==+1.6%==）|
| **预期收益** | CR ==+0.1~0.3pp==，分商家 AUC 均有提升，接驾距离持平或略降 |
| **实施周期** | 6-8 周（方案设计 2 周 + 离线 3 周 + 在线 AB 3 周）|

---

## 2. 背景与动机

### 2.1 当前问题

PK 打分系统使用统一 LR 模型（AUC ~0.756）服务所有商家，但各商家的司机/乘客行为模式差异显著：

| 商家类型 | 司机行为特征 | 乘客行为特征 | 当前痛点 |
|---|---|---|---|
| **自营**（滴滴） | 高完单率，对接驾距离敏感 | 取消率低，品牌忠诚 | 模型未充分利用品牌效应 |
| **花小猪** | 价格导向，拒单率略高 | 价格敏感，取消率高 | 乘客取消信号被稀释 |
| **宏鹄**（出租车） | 接驾距离容忍度高 | 急单多，等待耐心低 | 距离权重不匹配场景 |
| **API 商家**（曹操/T3/首汽） | 拒单率较高，行为模式各异 | 多为兜底流量 | 小样本，特征不稳定 |

**数据佐证**（来自 [[花小猪/PK策略知识库/wiki/models/Wide&Deep.md]] 实验）：
- V4 Deep&Wide 最终放量组中：自营完单 ==+1.27%==、宏鹄完单 ==-1.08%==、API 完单 +0.51%，说明统一模型仍存在显著商家异质性
- 同一模型优化方向对不同商家产生相反效果，证实差异化需求

### 2.2 当前解决方案的局限

| 方案 | 机制 | 问题 |
|---|---|---|
| [[花小猪/PK策略知识库/wiki/entities/倾斜策略.md\|倾斜策略]] | 模型外加减分 | 粗粒度调整，无法适应特征维度的差异 |
| LR 统一模型 | 所有商家共享一组权重 | 无法区分"自营取消"和"花小猪取消"的含义差异 |
| 分商家训练独立模型 | 每商家一个模型 | 小商家数据不足，无法共享跨商家通用知识 |

### 2.3 为什么是 MoE

Sparse MoE 的核心优势在于**在保持参数共享的同时实现差异化**：
- Shared Expert 学习跨商家通用模式（如"接驾距离越短越好"）
- 商家 Expert 学习各自独特模式（如"花小猪乘客对价格的超额敏感"）
- Gate Network 动态路由，软切分比硬切分更鲁棒

---

## 3. 技术方案

### 3.1 整体架构

```
┌─────────────────────────────────────────────────────────────────┐
│                        输入特征层                                 │
│  [订单特征] [司机特征] [乘客特征] [供需特征] [商家ID] [城市ID]       │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │   Embedding Layer    │
                    │  (Scalar2Vec + ID)   │
                    └──────────┬──────────┘
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
   ┌──────▼──────┐    ┌───────▼──────┐    ┌───────▼──────┐
   │   Shared    │    │  Expert_自营  │    │  Expert_花小猪│
   │   Expert    │    │  (高履约模式) │    │  (价格敏感)  │
   │  (通用模式) │    └──────┬───────┘    └──────┬───────┘
   └──────┬──────┘           │                    │
          │           ┌──────▼───────┐    ┌──────▼───────┐
          │           │  Expert_宏鹄  │    │  Expert_API  │
          │           │ (出租车模式)  │    │  (第三方)    │
          │           └──────┬───────┘    └──────┬───────┘
          │                  │                    │
          └──────────────────┼────────────────────┘
                             │
                    ┌────────▼────────┐
                    │  Gate Network   │
                    │ (商家ID+城市ID  │
                    │  +供需特征门控)  │
                    └────────┬────────┘
                             │ (Top-K Sparse 激活)
                    ┌────────▼────────┐
                    │  Fusion Layer   │
                    │ (加权求和)       │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
       ┌──────▼──────┐ ┌────▼─────┐ ┌─────▼─────┐
       │ Wide Module │ │ 输出 LR  │ │ 可解释输出 │
       │ (保留可解释)│ │ (融合)   │ │ (权重归因) │
       └─────────────┘ └──────────┘ └───────────┘
```

### 3.2 Expert 设计

#### Expert 数量与分组

| Expert | 负责商家 | 训练样本量（估算日均） | 核心特征侧重 |
|---|---|---|---|
| **Shared Expert** | 所有 | ~500 万 | 接驾距离、供需、基础履约 |
| **Expert_自营** | 滴滴自营 | ~200 万 | 司机忠诚度、品牌效应、服务质量 |
| **Expert_花小猪** | 花小猪 | ~150 万 | 价格敏感度、乘客取消概率、低价容忍 |
| **Expert_宏鹄** | 宏鹄出租车 | ~80 万 | 出租车行为模式、急单响应 |
| **Expert_API** | 曹操/T3/首汽等 | ~50 万 | 第三方拒单模式、兜底流量特征 |

#### Expert 内部结构

```python
class Expert(nn.Module):
    def __init__(self, input_dim, hidden_dims=[256, 128], output_dim=64):
        self.layers = nn.Sequential(
            nn.Linear(input_dim, hidden_dims[0]),
            nn.ReLU(),
            nn.BatchNorm1d(hidden_dims[0]),
            nn.Linear(hidden_dims[0], hidden_dims[1]),
            nn.ReLU(),
            nn.Linear(hidden_dims[1], output_dim)
        )
    
    def forward(self, x):
        return self.layers(x)
```

每个 Expert 参数量约 50K，总参数量 ~300K（5 Expert × 50K + Gate + Tower），远小于 PLE 的 1M+。

### 3.3 Gate Network 设计

```python
class GateNetwork(nn.Module):
    """
    门控网络：根据商家ID、城市ID和上下文特征决定每个样本激活哪些Expert
    """
    def __init__(self, gate_input_dim, num_experts=5, top_k=2):
        self.gate = nn.Sequential(
            nn.Linear(gate_input_dim, 64),
            nn.ReLU(),
            nn.Linear(64, num_experts)
        )
        self.top_k = top_k  # 每次激活2个Expert（1 Shared + 1 商家）
        self.noise = nn.Linear(gate_input_dim, num_experts)  # 辅助负载均衡
    
    def forward(self, gate_input):
        logits = self.gate(gate_input)
        # 添加噪声防止Gate坍缩
        noise = self.noise(gate_input) * F.softplus(self.noise_weight)
        noisy_logits = logits + noise
        # Top-K稀疏激活
        top_k_values, top_k_indices = torch.topk(noisy_logits, self.top_k)
        top_k_gates = F.softmax(top_k_values, dim=-1)
        return top_k_gates, top_k_indices
```

**Gate 输入特征**：
- 商家 ID embedding（关键路由信号）
- 城市 ID embedding（城市间模式差异）
- 时段特征（早晚高峰行为不同）
- 供需比（供不应求时行为模式变化）

### 3.4 负载均衡与 Gate 坍缩防治

Gate 坍缩是 MoE 的核心风险——所有样本路由到同一 Expert，其他 Expert 退化。

**防治方案**：

```python
# 1. Importance Loss：限制每个Expert的重要性得分方差
importance = gates.sum(dim=0)  # 各Expert被选中的总权重
importance_loss = (importance.std() / importance.mean()) ** 2

# 2. Load Balance Loss（Switch Transformer 方案）
# 让各Expert处理的token比例尽量均匀
fraction_routed = (gates > 0).float().mean(dim=0)
average_gate = gates.mean(dim=0)
balance_loss = num_experts * (fraction_routed * average_gate).sum()

# 3. 总损失
total_loss = task_loss + alpha * importance_loss + beta * balance_loss
```

建议参数：`alpha = 0.1, beta = 0.01`

### 3.5 与 Wide&Deep 架构的融合

MoE 不替代 Wide&Deep，而是**增强 Deep 侧**：

```
                Wide 侧（保留可解释性）
                ┌─────────────────────┐
                │ 接驾距离×2权重       │
                │ 司机取消率           │  → 可解释 PK 打分
                │ 乘客取消率           │
                └──────────┬──────────┘
                           │
           PK 打分 = Wide_score × w + Deep_score × (1-w)
                           │
                ┌──────────┴──────────┐
                │ Deep 侧（MoE 增强）  │
                │ Shared + 商家 Expert │  → 精度提升
                │ Gate 路由           │
                └─────────────────────┘
```

**关键设计决策**：Wide 侧权重仍然透明（保留商家可解释性），MoE 仅在 Deep 侧生效，不影响可解释性承诺。

---

## 4. 数据方案

### 4.1 训练数据

| 维度 | 规格 |
|---|---|
| **数据范围** | 近 14 天全城全商家 PK 日志 |
| **数据量** | 日均 ~500 万样本，14 天 ~7000 万 |
| **标签** | 是否完单（与现有 LR 标签一致）|
| **划分** | 按天划分 train/eval（最近 2 天 eval）|

### 4.2 商家样本分布与处理

| 商家 | 日均样本量 | 占比 | 处理策略 |
|---|---|---|---|
| 自营 | ~200 万 | 40% | 正常训练 |
| 花小猪 | ~150 万 | 30% | 正常训练 |
| 宏鹄 | ~80 万 | 16% | 正常训练 |
| API（曹操+T3+首汽等） | ~50 万 | 10% | 合并为 1 个 Expert，内部用 ID 区分 |
| 其他小商家 | ~20 万 | 4% | 路由到 Shared Expert |

### 4.3 特征工程增量

在现有 LR/Wide&Deep 特征基础上，新增：

| 特征 | 维度 | 来源 | 作用 |
|---|---|---|---|
| 商家 ID embedding | 16 | 新建 | Gate 核心路由信号 |
| 商家近 7d 平均 CR | 1 | 已有 | Expert 选择辅助 |
| 商家-城市交叉 ID | 16 | 新建 | 细粒度场景区分 |
| 商家司机池规模 | 1 | 已有 | 供给侧差异信号 |

---

## 5. 实施计划

### Phase 1：离线验证（3 周）

| 周 | 任务 | 交付物 | 验收标准 |
|---|---|---|---|
| W1 | 数据准备 + 基线复现 | Wide&Deep baseline AUC | 与线上一致 |
| W1-2 | MoE 模型开发 | 模型代码 + 训练 pipeline | 可在 EVE 跑通 |
| W2-3 | 离线实验 + 消融 | 实验报告 | 见下方评估标准 |

**离线评估标准**：

| 指标 | 基线（Wide&Deep） | MoE 目标 | 通过条件 |
|---|---|---|---|
| 全局 AUC | 0.756 | ≥0.760 | ==+0.4pp 以上== |
| 自营子集 AUC | — | 提升 | 任意提升 |
| 花小猪子集 AUC | — | 提升 | 任意提升 |
| 宏鹄子集 AUC | — | 提升 | 任意提升 |
| API 子集 AUC | — | 不降 | ≥基线 |
| 排序一致性（vs LR） | 89.6% | ≥85% | 可解释性保持 |

**消融实验设计**：

| 实验 | 目的 |
|---|---|
| A：不加 Shared Expert | 验证 Shared Expert 的跨商家迁移价值 |
| B：Expert 数 = 2（自营+非自营）| 验证粗粒度分组是否足够 |
| C：Top-K = 1 vs 2 vs 3 | 确定最优激活数 |
| D：去掉 Load Balance Loss | 验证负载均衡的必要性 |

### Phase 2：在线实验（3 周）

| 周 | 任务 | 流量 | 关注指标 |
|---|---|---|---|
| W4 | 灰度上线 | 5% 城市 | 服务稳定性、latency |
| W5-6 | AB 实验 | 20% 全国 | CR、分商家完单、接驾距离、取消率 |

**在线评估标准**：

| 指标 | 目标 | 底线 |
|---|---|---|
| 整体 CR | ==+0.1pp 以上== | ≥0 |
| 自营完单 | 正向 | ≥-0.5% |
| 宏鹄完单 | 正向 | ≥-1% |
| API 完单 | 正向 | ≥-2% |
| 接驾距离 | ≤+30m | ≤+50m |
| P99 latency | ≤50ms | ≤80ms |

### Phase 3：生产化（2 周）

- 接入 [[花小猪/PK策略知识库/wiki/entities/自动化更新机制.md|自动化更新]]流程
- Gate 路由分布监控看板（Woater）
- 模型回退机制（Gate 异常时降级为统一模型）

---

## 6. 工程考量

### 6.1 推理延迟

| 方案 | 预估 latency | 说明 |
|---|---|---|
| 当前 LR | ~5ms | 极轻量 |
| Wide&Deep | ~15ms | Deep 侧增加开销 |
| **MoE (Top-2)** | ==~20ms== | 仅激活 2 个 Expert，稀疏计算 |

MoE 的 Top-K 稀疏激活确保推理时仅计算 2 个 Expert（Shared + 商家 Expert），实际计算量仅为全量 Expert 的 40%。

### 6.2 内存与模型大小

| 模型 | 参数量 | 模型文件大小 |
|---|---|---|
| LR | ~30 | <1 KB |
| Wide&Deep | ~100K | ~400 KB |
| **MoE** | ==~300K== | ~1.2 MB |

在可接受范围内，不需要特殊的模型压缩。

### 6.3 训练资源

- EVE 平台 1 张 V100 即可完成日级训练
- 训练时间预估：7000 万样本 × 5 epoch ≈ 2-3 小时

---

## 7. 风险与应对

| 风险 | 影响 | 概率 | 应对策略 |
|---|---|---|---|
| **Gate 坍缩** | 所有样本路由同一 Expert，MoE 退化为普通模型 | 中 | Load Balance Loss + 监控 Expert 利用率 |
| **小商家数据稀疏** | API Expert 训练不充分 | 高 | 合并小商家为 1 Expert + Shared Expert 兜底 |
| **可解释性丧失** | 商家无法理解 PK 结果 | 中 | Wide 侧保留完整可解释链路 |
| **线上 latency 超标** | 影响用户体验 | 低 | Top-K 稀疏 + 模型量化 |
| **商家间互相影响** | 优化一商家损害另一商家 | 中 | AB 时必须分商家看数据 |

---

## 8. 成功指标

### 技术指标

- [ ] 全局 AUC ≥ 0.760（==+0.4pp==）
- [ ] 每个商家子集 AUC 均不降
- [ ] Gate 路由分布符合预期（各 Expert 负载差 < 3x）
- [ ] P99 latency ≤ 50ms

### 业务指标

- [ ] 整体 CR ==+0.1~0.3pp==
- [ ] 自营与宏鹄不再出现"优化一方损害另一方"
- [ ] 接驾距离不恶化

---

## 9. 后续扩展

| 扩展方向 | 时机 | 价值 |
|---|---|---|
| 增加城市维度 Expert | MoE 验证后 | 捕捉城市差异（一线 vs 二线） |
| 毛利 Expert | 毛利因子重启时 | 将[[花小猪/PK策略知识库/wiki/entities/毛利因子.md\|毛利因子]]融入模型内部而非后处理 |
| 时段 Expert（早/晚高峰） | 长期 | 捕捉时段行为差异 |
| 与 [[花小猪/PK策略知识库/wiki/models/PLE多任务模型.md\|PLE]] 合并 | 架构稳定后 | MoE-PLE 统一多任务多场景 |

---

## 10. 参考

- 快手 IPA + Sparse MoE（2025，主站全量，观看时长 +1.6%）
- Google MMoE: Modeling Task Relationships in Multi-task Learning with Multi-gate Mixture-of-Experts (KDD 2018)
- Switch Transformer: Scaling to Trillion Parameter Models with Simple and Efficient Sparsity (2021)
- [[花小猪/PK策略知识库/wiki/research/多任务学习迭代方向.md]] — 方向评估总览
