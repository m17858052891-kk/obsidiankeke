---
title: "策略方案：偏好对齐 — 从拟合 CR 到对齐长期体验"
type: proposal
created: 2026-05-27
updated: 2026-05-27
priority: 中
difficulty: 高
status: 方案设计
sources:
  - raw-research/多任务学习最新方法综述.md
tags:
  - 偏好对齐
  - DPO
  - IPA
  - 强化学习
  - 策略方案
related:
  - wiki/research/多任务学习迭代方向.md
  - wiki/models/DQN.md
  - wiki/entities/PK模型.md
  - wiki/concepts/履约率.md
  - wiki/concepts/司乘取消.md
---

# 策略方案：偏好对齐 — 从拟合 CR 到对齐长期体验

## 1. 方案概述

### 1.1 一句话摘要

借鉴推荐系统偏好对齐技术（快手 IPA/DPO），将 PK 模型的优化目标从"单次完单概率最大化"升级为"用户长期满意度对齐"，通过训练 Reward Model 建模长期体验，再用 DPO 对齐 PK 打分策略。

### 1.2 方案定位

| 维度 | 说明 |
|---|---|
| **目标模块** | PK 打分模型 + DQN 窗口策略 |
| **核心问题** | 当前优化单次 CR，但高 CR 不等于高长期满意度（如接驾距离长但完单→乘客不满） |
| **技术来源** | 快手 IPA（迭代偏好对齐） + DPO (Direct Preference Optimization) |
| **预期收益** | 长期指标提升：复购率 +0.5~1%、NPS +1~2 分 |
| **实施周期** | 12-16 周（调研 4 周 + 开发 4 周 + 实验 4-8 周）|
| **建议时间窗口** | 2026 Q4 – 2027 Q1（中期储备方向）|

---

## 2. 背景与动机

### 2.1 当前优化目标的局限

PK 模型当前优化目标：

$$\max P(\text{完单} | \text{司机}_i, \text{乘客}_j, \text{上下文})$$

这个目标存在**短视性**：

| 场景 | CR 视角 | 长期体验视角 |
|---|---|---|
| 接驾距离 8km 但完单 | ✅ CR +1 | ❌ 乘客等待 15 分钟，体验差，下次可能流失 |
| 司机服务评分 3.5 但完单 | ✅ CR +1 | ❌ 乘客体验差评，NPS 降低 |
| 乘客被分配到远距离低价单 | ✅ CR +1 | ❌ 司机不满，长期拒单率上升 |
| 新司机被持续跳过 | —（CR 无关） | ❌ 新司机留存下降，供给侧萎缩 |

### 2.2 快手 IPA 的启发

快手在推荐系统中的偏好对齐实践：

```
传统推荐：max P(click) → 标题党、低质内容胜出
IPA 推荐：max 长期满意度 → 高质量内容胜出

实现路径：
1. CTR 预测模型（基线）
2. 训练 Reward Model（模拟用户对推荐结果的长期评价）
3. DPO 对齐（让推荐模型的排序偏向 Reward Model 偏好的方向）

效果：主站全量上线，用户观看时长 +1.6%
```

**类比 PK 场景**：

```
传统 PK：max P(完单) → 只要完单就好，忽略体验
对齐 PK：max 长期满意度 → 不仅完单，还要体验好

实现路径：
1. CR 预测模型（当前 LR/Wide&Deep）
2. 训练 Reward Model（建模"好的匹配"定义）
3. DPO 对齐（PK 打分偏向长期体验更优的匹配）
```

### 2.3 与 DQN 的关系

[[wiki/models/DQN.md|DQN 动态窗口]]已经在做类似的长期优化尝试：

| 维度 | DQN | 偏好对齐 |
|---|---|---|
| **优化对象** | 窗口时长（等多久） | PK 打分（选谁） |
| **奖励信号** | 手工设计（R₀=5, R=15, α=0.45） | 数据驱动（Reward Model 学习） |
| **长期性** | 跨时间步衰减（γ^(t'-t)） | 跨订单用户级追踪 |
| **已有问题** | 奖励参数敏感、分城市差异未处理 | — |

> [!info] 协同机会
> DQN 的 reward 设计（当前手工参数）可以直接替换为 Reward Model 的输出，实现"窗口决策"和"司机选择"的统一长期优化。

---

## 3. 技术方案

### 3.1 三阶段实施框架

```
┌──────────────────────────────────────────────────────────────────┐
│  Stage 1: 定义 "好的匹配" (Reward 建模)                          │
│                                                                  │
│  历史数据 → 提取用户级长期指标 → 训练 Reward Model                 │
│  输入: (司机, 乘客, 上下文) → 输出: 长期满意度评分                  │
└──────────────────────────────┬───────────────────────────────────┘
                               │
┌──────────────────────────────▼───────────────────────────────────┐
│  Stage 2: 构建偏好数据集                                          │
│                                                                  │
│  对每个订单: 比较实际匹配 vs 次优匹配 → (preferred, rejected) 对    │
│  Reward 高的为 preferred，低的为 rejected                          │
└──────────────────────────────┬───────────────────────────────────┘
                               │
┌──────────────────────────────▼───────────────────────────────────┐
│  Stage 3: DPO 对齐                                               │
│                                                                  │
│  PK 模型参数微调: 提升 preferred 对的打分, 降低 rejected 对的打分   │
│  保持与原模型的 KL 散度约束 → 不过度偏离 CR 预测                    │
└──────────────────────────────────────────────────────────────────┘
```

### 3.2 Stage 1：Reward Model 设计

#### 长期满意度定义

| 指标 | 权重 | 数据来源 | 计算方式 |
|---|---|---|---|
| **7 日复购率** | ==0.35== | 用户订单表 | 该用户 7 日内是否再次下单 |
| **接驾等待时长满意度** | 0.20 | PK 日志 | 1 - (实际等待 / 可接受阈值) |
| **服务评分** | 0.20 | 评价表 | 归一化到 [0,1] |
| **是否投诉** | 0.15 | 投诉表 | 0/1 (负向) |
| **是否使用优惠券复购** | 0.10 | 营销表 | 0/1 (区分自然复购和促销复购) |

**综合 Reward 计算**：

$$R = w_1 \cdot \text{复购} + w_2 \cdot \text{等待满意度} + w_3 \cdot \text{评分} - w_4 \cdot \text{投诉} + w_5 \cdot \text{自然复购}$$

#### Reward Model 架构

```python
class RewardModel(nn.Module):
    """
    输入: 司乘组合特征 + 上下文
    输出: 标量 reward（预测长期满意度）
    """
    def __init__(self, input_dim, hidden_dims=[256, 128, 64]):
        super().__init__()
        self.backbone = nn.Sequential(
            nn.Linear(input_dim, hidden_dims[0]),
            nn.ReLU(),
            nn.Dropout(0.1),
            nn.Linear(hidden_dims[0], hidden_dims[1]),
            nn.ReLU(),
            nn.Dropout(0.1),
            nn.Linear(hidden_dims[1], hidden_dims[2]),
            nn.ReLU(),
            nn.Linear(hidden_dims[2], 1)  # 标量 reward
        )
    
    def forward(self, features):
        return self.backbone(features).squeeze(-1)
```

#### 训练方式

Reward Model 使用 **pairwise ranking loss** 训练：

```python
# 对同一订单的两个候选匹配：
# - chosen: 实际长期满意度更高的
# - rejected: 长期满意度更低的
def reward_loss(reward_chosen, reward_rejected):
    return -torch.log(torch.sigmoid(reward_chosen - reward_rejected)).mean()
```

### 3.3 Stage 2：偏好数据集构建

#### 数据构建流程

```
Step 1: 获取历史 PK 决策数据
        每个订单有: 胜者(winner) + 若干败者(losers)

Step 2: 追踪胜者的长期结果
        7日复购? 评分? 投诉? → 计算 Reward_winner

Step 3: 反事实估计败者的 Reward（关键难点）
        方案A: 用最近邻订单的实际 Reward 近似
        方案B: 用 Reward Model 直接预测 Reward_loser
        方案C: 仅使用可观测信号(接驾距离、历史评分)做近似

Step 4: 构建偏好对
        if Reward_winner > Reward_loser:
            preferred = winner, rejected = loser
        else:
            preferred = loser, rejected = winner  # 反转！说明当前PK选错了
```

#### 反事实估计的挑战

> [!warning] 核心难题
> 我们只观测到胜者的实际结果，败者的"如果被选中会怎样"是反事实的。这是偏好对齐在 PK 场景中最大的技术挑战。

**推荐方案**：方案 B（用 Reward Model 预测），原因：
- 方案 A 的近邻匹配在高维特征空间中质量不稳定
- 方案 C 过于粗糙，丢失了大量信息
- 方案 B 虽然有循环依赖（RM 预测 → 构建数据 → 训练 RM），但可通过迭代收敛（IPA 的核心思路）

### 3.4 Stage 3：DPO 对齐

#### DPO 原理

Direct Preference Optimization 直接优化策略模型，无需在线 RL：

$$\mathcal{L}_{DPO} = -\mathbb{E}_{(x, y_w, y_l)} \left[ \log \sigma \left( \beta \log \frac{\pi_\theta(y_w|x)}{\pi_{ref}(y_w|x)} - \beta \log \frac{\pi_\theta(y_l|x)}{\pi_{ref}(y_l|x)} \right) \right]$$

在 PK 场景中的对应：
- $x$ = 订单上下文
- $y_w$ = preferred 匹配（长期满意度高）
- $y_l$ = rejected 匹配（长期满意度低）
- $\pi_\theta$ = 待对齐的 PK 模型
- $\pi_{ref}$ = 参考模型（当前 LR/Wide&Deep）
- $\beta$ = KL 约束强度

#### PK 场景适配

```python
class PKAlignmentLoss(nn.Module):
    """
    将 DPO 适配到 PK 打分场景
    """
    def __init__(self, beta=0.1):
        super().__init__()
        self.beta = beta
    
    def forward(self, pk_model, ref_model, features_preferred, features_rejected, context):
        """
        Args:
            pk_model: 待对齐的PK模型
            ref_model: 参考模型(frozen)
            features_preferred: 长期满意度高的司乘组合特征
            features_rejected: 长期满意度低的司乘组合特征
            context: 订单上下文
        """
        # 当前模型的打分
        score_w = pk_model(features_preferred, context)  # preferred 分数
        score_l = pk_model(features_rejected, context)   # rejected 分数
        
        # 参考模型的打分（frozen）
        with torch.no_grad():
            ref_score_w = ref_model(features_preferred, context)
            ref_score_l = ref_model(features_rejected, context)
        
        # DPO loss
        log_ratio_w = score_w - ref_score_w
        log_ratio_l = score_l - ref_score_l
        loss = -F.logsigmoid(self.beta * (log_ratio_w - log_ratio_l)).mean()
        
        return loss
```

#### β 参数选择

| β 值 | 效果 | 适用场景 |
|---|---|---|
| β → 0 | 完全忽略参考模型，激进对齐 | 不推荐 |
| β = 0.05 | 温和对齐，CR 基本保持 | ==推荐起步== |
| β = 0.1 | 中等对齐 | 验证有效后 |
| β = 0.5 | 保守，接近参考模型 | 如 CR 显著下降时回退 |

### 3.5 IPA 迭代机制

借鉴快手 IPA，将上述三阶段变为迭代过程：

```
Iteration 0:
  RM₀ = 初始 Reward Model（基于历史数据训练）
  PK₀ = 当前 PK 模型（参考模型）

Iteration 1:
  数据₁ = PK₀ 产生的线上匹配结果 + RM₀ 打分
  PK₁ = DPO(PK₀, 数据₁)  → 第一版对齐模型

Iteration 2:
  数据₂ = PK₁ 产生的线上匹配结果 + RM₁ 打分
  RM₁ = 用 PK₁ 的新数据更新 RM₀
  PK₂ = DPO(PK₁, 数据₂)  → 第二版对齐模型
  ...
```

---

## 4. 实验设计

### 4.1 分阶段验证

#### Phase 0：可行性验证（4 周）

| 任务 | 验证内容 | 通过标准 |
|---|---|---|
| Reward 信号相关性分析 | 7 日复购率 vs CR 的相关系数 | r < 0.5（若 r 太高说明 CR 已足够，无需对齐） |
| 反事实估计质量 | Reward Model 在holdout set的排序AUC | ≥ 0.65 |
| 偏好数据集规模 | 有效偏好对数量 | ≥ 100 万对/月 |

#### Phase 1：离线验证（4 周）

| 实验 | 内容 | 核心指标 |
|---|---|---|
| DPO β 搜索 | β ∈ {0.01, 0.05, 0.1, 0.2, 0.5} | CR 变化 vs Reward 变化 |
| CR-Reward 帕累托 | 画出 CR-Reward 帕累托前沿 | 找到最优 trade-off |
| 消融：无 KL 约束 | β=0 | 验证 KL 约束必要性 |

#### Phase 2：在线验证（4-8 周）

| 维度 | 指标 | 目标 |
|---|---|---|
| **短期（1 周）** | CR | 下降不超过 ==0.05pp== |
| **短期** | 接驾距离 | 无显著变化 |
| **中期（4 周）** | 7 日复购率 | ==+0.5~1%== |
| **中期** | 用户评分 | +0.05 分 |
| **中期** | 投诉率 | -5~10% |
| **长期（8 周）** | 月活跃用户数 | 正向 |

### 4.2 CR 与长期体验的 Trade-off

> [!warning] 核心权衡
> 偏好对齐很可能以微小的 CR 下降为代价换取长期指标提升。需要与业务团队明确可接受的 CR 下降底线。

建议底线：
- CR 下降 ≤ ==0.05pp==（可接受）
- CR 下降 0.05~0.1pp → 需要 7 日复购率 +1% 以上才接受
- CR 下降 > 0.1pp → 不接受，回调 β

---

## 5. DQN Reward 优化（Quick Win）

在完整偏好对齐方案之前，可以先在 [[wiki/models/DQN.md|DQN]] 中引入 Reward Model 信号，作为 Quick Win：

### 5.1 当前 DQN Reward 问题

```
当前: R = R₀ + R·完单 - α·Δt + β·Δp
问题: R₀=5, R=15, α=0.45, β=0.5 均为手工设定
     未考虑完单后的用户体验
```

### 5.2 改进方案

```python
# 改进后的 DQN Reward
def compute_reward(state, action, next_state, done):
    base_reward = -alpha * delta_t + beta * delta_p  # 等待成本 + PK分改善
    
    if done:
        if completed:
            # 用 Reward Model 替代固定常数
            long_term_reward = reward_model.predict(winner_features)
            return base_reward + long_term_reward
        else:
            return base_reward + R_0  # 未完单仍用固定值
    else:
        return base_reward
```

**优势**：
- 改动极小（仅替换 DQN 的完单奖励常数）
- 快速验证 Reward Model 在 PK 场景的有效性
- 为完整偏好对齐积累经验

---

## 6. 实施计划

### 总时间线

```
2026 Q3:
  M1:  Reward 信号分析 + 可行性验证（Phase 0）
  M2:  Reward Model 训练 + 偏好数据集构建
  M3:  DQN Reward 优化（Quick Win）→ 在线验证

2026 Q4:
  M4:  DPO 对齐离线实验（Phase 1）
  M5:  在线 AB 实验（Phase 2 前半）
  M6:  迭代优化 + IPA 机制搭建

2027 Q1:
  M7-9: Phase 2 后半 + 长期指标观测 + 全量决策
```

### 团队配置

| 角色 | 人力 | 工作内容 |
|---|---|---|
| 算法 | 1.5 人 | Reward Model + DPO + 实验 |
| 数据 | 0.5 人 | 长期指标数据表构建 |
| 工程 | 0.5 人 | Reward Model 在线推理服务 |
| 产品/业务 | 0.5 人 | 长期满意度指标定义 + CR 底线对齐 |

---

## 7. 风险与应对

| 风险 | 概率 | 影响 | 应对 |
|---|---|---|---|
| **CR 显著下降** | 中 | 短期业务指标恶化 | β 约束 + CR 硬下限 + 快速回滚 |
| **Reward 信号与 CR 高度相关** | 中 | 对齐无增量 | Phase 0 先验证 r < 0.5 |
| **反事实估计不准** | 高 | 偏好数据质量差 | IPA 迭代 + 多种估计方法对比 |
| **长期指标观测周期长** | 高 | 实验结论滞后 | 用代理指标（接驾距离分布、评分）辅助判断 |
| **商家/业务团队不接受 CR 下降** | 中 | 方案无法上线 | 提前对齐预期 + 展示长期 ROI |

---

## 8. 成功指标

### 短期（Phase 0-1）

- [ ] Reward 信号与 CR 相关系数 r < 0.5
- [ ] Reward Model ranking AUC ≥ 0.65
- [ ] DPO 对齐后 CR 下降 ≤ 0.05pp

### 中期（Phase 2）

- [ ] 7 日复购率 ==+0.5%==
- [ ] 用户评分 ==+0.05==
- [ ] 投诉率 ==-5%==

### Quick Win（DQN Reward）

- [ ] DQN 策略触发后用户 7 日复购率提升
- [ ] DQN reward 参数不再需要手工调优

---

## 9. 参考

- 快手 IPA + Sparse MoE（2025，主站全量，观看时长 +1.6%）
- Rafailov et al. (2023). "Direct Preference Optimization: Your Language Model is Secretly a Reward Model." NeurIPS.
- [[wiki/models/DQN.md]] — 当前 DQN reward 设计
- [[wiki/concepts/履约率.md]] — CR 指标定义
- [[wiki/concepts/司乘取消.md]] — 取消行为分类
- [[wiki/research/多任务学习迭代方向.md]] — 方向评估总览
