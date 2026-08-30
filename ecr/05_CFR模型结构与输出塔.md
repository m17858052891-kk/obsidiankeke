# 原先 CFR 模型结构与输出塔

## 30 秒回答

CFR 是“共享表征 + 多 treatment 响应塔”。输入用户、订单及干预前特征后，embedding 与 shared bottom 提取共同表征；每个补贴档位各有一个 head，输出该用户在该档位下的 call probability。100 档作为 control，档位 $m$ 的 uplift score 是 $\hat\mu_m(x)-\hat\mu_{100}(x)$。factual BCE 只监督用户实际被分到的那一个塔，其他塔依赖共享表征与反事实泛化来估计。

## 1. 模型结构

```mermaid
flowchart LR
  X[干预前用户/订单特征 x] --> E[Embedding / 特征编码]
  E --> H[Shared Bottom: CFR representation h(x)]
  H --> C[100 档 Control head]
  H --> T1[97 档 head]
  H --> T2[94 档 head]
  H --> TN[其他补贴档位 heads]
  C --> MC[mu_100(x)]
  T1 --> M1[mu_97(x)]
  T2 --> M2[mu_94(x)]
  TN --> MN[mu_m(x)]
  MC --> U[各档 uplift: mu_m - mu_100]
  M1 --> U
  M2 --> U
  MN --> U
```

输入必须严格是 treatment 发生前可得的特征；发券后行为、结果窗口内统计和可直接识别档位的泄漏特征均不可进入模型。

## 2. 多档位输出

对每一个干预 arm $a$：

$$
h_i=f_{shared}(x_i),\qquad \hat\mu_a(x_i)=\sigma(g_a(h_i))
$$

本项目将 100 档定义为 control。对任一非 control 档位 $m$：

$$
\hat\tau_m(x)=\hat\mu_m(x)-\hat\mu_{100}(x)
$$

最终模型不只有一个排序分数，而是每个档位都有一条 uplift 曲线。线上还需将多档分数与成本、预算、频控和互斥触达规则结合，不能直接把每个用户分给最大 $\hat\tau_m$ 的档位。

## 3. Shared Bottom 与 heads 各自做什么

Shared bottom 学习跨档位共性，如用户活跃度、历史行为、订单上下文；treatment-specific heads 学习同一表征在不同补贴强度下的响应差异。共享可以缓解深档位样本稀缺，独立 head 又避免强加“补贴越大效果必然单调”的错误先验。

## 4. 为什么不是直接预测一个 uplift head

直接预测 uplift head 缺乏单用户的真实 ITE 标签，也失去了被观测 response probability 的稳定监督。潜在结果建模先估计 $\mu_m(x)$ 与 $\mu_{100}(x)$，再相减，能使用实际观测到的 outcome 训练事实头；代价是差分会放大两个概率估计误差，且 factual 最优不等于 uplift 排序最优，这正是后续引入 rank loss 的动机。

## 5. 为什么用 CFR，为什么还不够

CFR 通过共享表示和分布平衡约束减少 treatment/control 在表征空间的差异，为反事实推断提供更合理的起点。它解决的是“能否从一个组泛化到另一个组”的部分问题；它没有把 AUCC 的排序目标写入损失，也不会自动避免高频用户、档位样本量或 assignment pattern 被当作提升信号。因此它是 baseline/anchor，而不是最终答案。

## 6. 训练与输出的关键边界

- factual BCE 只更新实际 arm 对应 head 的观测响应；
- 反事实 head 通过共享参数、实验随机性和因果约束间接学习；
- rank calibration 不应改动线上业务概率的语义；
- 多档位 head 可独立、累计或用 FiLM 调制。当前选择独立 head，是因为尚无足够证据假设档位响应严格单调；
- 若升级到 DR/DRCFR，应先做相同数据切分、相同指标、同等调参预算的对照，不能仅比较单点最高数值。
