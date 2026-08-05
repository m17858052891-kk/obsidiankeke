---
tags:
  - 自动出价
  - LLM
  - LBM
  - Offline-RL
  - 论文精读
created: 2026-07-28
---

# LBM：怎样将 LLM 推理能力引入自动出价？

论文：[LBM: Hierarchical Large Auto-Bidding Model via Reasoning and Acting](https://arxiv.org/abs/2603.05134)  
PDF：[作者公开版本](https://personal.ntu.edu.sg/boan/papers/WWW26_LBM.pdf)  
会议：WWW 2026

> **一句话总结：** LBM 把自动出价拆成“高层推理”和“低层连续动作”两层：LBM-Think 用 LLM 生成投放状态的语言化 reasoning，LBM-Act 用数值轨迹和 CoT 双 embedding 输出精确动作，再用离线 Q 值筛选和微调 Think，避免语言推理脱离数据。

![[Pasted image 20260730172728.png]]

## 第一部分：全景地图

Figure 1 展示的是两个训练阶段，而不是一次普通推理。左边 Stage I 训练低层 **LBM-Act**，让它学会把语言 CoT 和数值决策序列融合成连续动作；右边 Stage II 固定 Act，用离线 Q-function 评价不同 CoT 诱导出的动作，再更新高层 **LBM-Think**。

整体链路可以写成：

$$
\underbrace{\{p_i,a_i\}_{i=t-H:t-1}}_{\text{压缩历史表现}}
\xrightarrow{\text{LBM-Think}}
 c_t
\quad + \quad
\underbrace{\{R_{t-L:t},s_{t-L:t},a_{t-L:t-1}\}}_{\text{DT 数值序列}}
\xrightarrow{\text{LBM-Act}}
\tilde a_t.
$$

一句话读图：**Think 负责把复杂投放状态说清楚，Act 负责把这个方向和数值轨迹变成连续 bidding action。**

### 0. 先明确：为什么自动出价需要 LLM？

传统 DT、IQL、DiffBid 等方法主要处理数值轨迹：状态、动作、reward 或 RTG。它们擅长从历史序列中拟合动作，但不擅长显式表达：

- 为什么现在应该更激进或更保守；
- 预算、CPA、剩余时间、近期趋势之间如何权衡；
- 面对稀疏转化或复杂 KPI 时，策略变化的高层原因是什么。

LLM 的优势是能处理任务描述、约束说明和高层推理。但直接让 LLM 输出连续 multiplier 又有明显问题：

- 浮点动作精度不稳定；
- 文本 token 与数值状态的表示空间不一致；
- 语言理由可能看似合理但不符合离线数据；
- 大模型每个 tick 高频推理成本高。

LBM 的核心答案是：**不要让一个 LLM 同时负责解释和执行，而是分层。**

### 0.1 Think 与 Act 的职责边界

| 模块 | 输入 | 输出 | 角色 |
|---|---|---|---|
| LBM-Think | 历史表现、历史动作、任务描述、约束摘要。 | CoT / reasoning / 高层方向。 | 低频、语言化、解释状态和策略方向。 |
| LBM-Act | 数值 RTG-state-action 序列 + CoT embedding。 | 连续动作 $\tilde a_t$。 | 高频、数值化、精确输出 bidding parameter。 |
| GQPO | 多条候选 CoT + 冻结 Act + 离线 Q。 | 更新 Think 的偏好。 | 让高层 reasoning 朝更高 Q 的方向移动。 |

这条边界非常重要：**Think 不直接下单，Act 不只靠文本拍脑袋。**

### 1. 先认清 Figure 1 的基础符号

| 符号 | 含义 | 图中位置 |
|---|---|---|
| $p_i$ | 历史投放表现摘要，如预算利用率、转化、CPA、成本速度。 | Think 的输入。 |
| $s_t$ | 当前细粒度数值状态，如预算、KPI、曝光价值分布、拍卖状态。 | Act 的数值输入。 |
| $a_t$ | 数据集中的连续 bidding action，可能是一个或多个参数。 | Stage I 的监督标签。 |
| $\tilde a_t$ | Act 根据 CoT 和数值序列预测出的动作。 | 用于动作损失或 Q 评价。 |
| $R_t$ | Decision Transformer 风格的 return-to-go。 | 数值决策序列中的条件 token。 |
| $c_t$ | Think 生成的 chain-of-thought。 | 高层 reasoning，不是最终动作。 |
| $H$ | Think 读取的历史表现窗口长度。 | 偏高层、低频。 |
| $L$ | Act 读取的数值轨迹窗口长度。 | 偏低层、高频。 |

一个自然语言 CoT 可以长这样：

```text
预算消耗明显慢于计划，当前 CPA 低于目标，剩余时间不足。
因此可以适度提高 bidding parameter，但需要避免在低价值流量上过快消耗预算。
```

但最终动作仍由 Act 输出，例如：

$$
\tilde a_t=[1.08,0.97,1.02].
$$

如果动作是一维 multiplier，就是一个标量；如果系统控制多个 bidding parameters，就是连续向量。

### 2. Stage I：双 embedding 怎样走到动作损失？

Stage I 的目标是训练 LBM-Act。Think 在这个阶段冻结，语言 token embedding 也冻结；Act 和动作 head 更新。

流程如下：

1. 历史表现 $\{p_i,a_i\}_{i=t-H:t-1}$ 输入 Think；
2. Think 生成 CoT $c_t$；
3. CoT 通过语言 token embedding 得到文本向量；
4. 数值序列 $\{R_{t-L:t},s_{t-L:t},a_{t-L:t-1}\}$ 通过 decision embedding 得到数值 token；
5. 两路 token 输入 LLM 初始化的 Transformer layers；
6. 动作 head 输出 $\tilde a_t$；
7. 与数据集动作 $a_t$ 做监督损失。

数学上，Act 的输入可以写成：

$$
X_t=\left[\operatorname{Emb}_{\text{text}}(c_t),\operatorname{Emb}_{\text{dec}}(R_{t-L:t},s_{t-L:t},a_{t-L:t-1})\right].
$$

Act 输出：

$$
\tilde a_t=f_\phi(X_t).
$$

动作监督损失：

$$
\mathcal L_a(\phi)=\|\tilde a_t-a_t\|_2.
$$

### 2.1 为什么数值项不直接写成文本？

如果把数值状态写成：

```text
CPA=8.23, budget_ratio=0.61, traffic_speed=1.37
```

再让 LLM 自己从字符 token 里理解浮点关系，会有三个问题：

- 数值精度损失；
- token 长度膨胀；
- 模型不一定稳定理解大小关系和连续变化。

所以 LBM 使用 decision embedding，把 RTG、state、action 等数值结构通过 MLP 映射到和语言 embedding 同维的向量。这样 Transformer 融合的是“语言语义 + 结构化数值表示”，而不是一堆字符串。

### 2.2 为什么 Stage I 要冻结 Think？

Stage I 的损失是连续动作 MSE。如果让它直接更新 Think，语言模型可能为了拟合动作标签而破坏原有推理能力，甚至学出不可读或不稳定的 CoT。

冻结 Think 的含义是：

- 先把 Think 当作高层提示生成器；
- 让 Act 学会在给定 CoT 的情况下模仿日志动作；
- 避免动作监督直接污染语言推理空间。

换句话说，Stage I 先解决“语言和数值怎么融合执行”的问题，不急着优化 Think 的 reasoning 质量。

### 3. Anchor direction：CoT 怎样不和动作标签打架？

论文引入 anchor direction：比较日志动作 $a_t$ 相对 $a_{t-1}$ 的变化方向。

对于一维动作，可以写成：

$$
\operatorname{dir}(a_t)=\operatorname{sign}(a_t-a_{t-1}).
$$

如果 CoT 说“应该提高出价”，但数据标签显示本轮动作是下调，那么监督训练会变得矛盾：Act 一边读到“提高”的文本，一边被 MSE 要求输出更低动作。

因此论文用 anchor direction 过滤冲突 reasoning。这个机制的意义不是“日志永远最优”，而是**避免 Stage I 的监督学习阶段出现文本方向与动作标签相反的噪声条件**。

### 3.1 一个具体例子

假设：

```text
a_{t-1}=1.10
a_t=0.95
```

日志方向是下调。若 Think 生成：

```text
预算消耗过快，CPA 已接近上限，应该降低出价系数。
```

这个 CoT 与 anchor 一致，可以进入 Act。

若 Think 生成：

```text
剩余时间不多，应该提高出价。
```

但此时日志动作实际下调，论文会过滤冲突部分，避免 Act 同时接收“提高”的语言条件和“降低”的数值标签。

### 4. Stage II：一组 CoT 怎样成为 GQPO 的训练样本？

Stage II 的目标是微调 LBM-Think。此时 Act 冻结，Think 可以更新。

对同一个历史，Think 采样多条候选 CoT：

$$
\{c_t^1,c_t^2,\ldots,c_t^N\}.
$$

每条 CoT 都和同一段数值序列输入冻结的 Act，得到不同动作：

$$
\tilde a_t^i=f_\phi(c_t^i,R_{t-L:t},s_{t-L:t},a_{t-L:t-1}).
$$

然后用离线训练好的 Q-function 评价这条 CoT 诱导出来的动作是否比数据集动作更好：

$$
\Delta Q_i=Q_\varphi(s_t,\tilde a_t^i)-Q_\varphi(s_t,a_t).
$$

如果 $\Delta Q_i>0$，说明在 Q 估计器看来，这条 CoT 让 Act 产生了优于日志动作的决策。

### 4.1 图里的 $\Delta Q$ 不是文本打分

这一点很容易误讲。$\Delta Q_i$ 不是 LLM 自己评价“这段 reasoning 写得好不好”，也不是人工规则评分。它来自：

```text
CoT_i → 冻结 Act → 连续动作 ã_i → 离线 Q-function → 相对 Q
```

所以 GQPO 奖励的不是文笔，而是**这段 CoT 通过 Act 改变动作后，离线 Q 认为它更有价值**。

### 4.2 为什么 Stage II 必须冻结 Act？

如果 Act 也同时更新，那么 $\Delta Q_i$ 的变化可能来自两件事：

- Think 生成了更好的 CoT；
- Act 自己改变了解读 CoT 的方式。

这样就无法把收益归因给 reasoning。冻结 Act 后，同一条 CoT 到动作的映射保持稳定，GQPO 才是在优化 Think 的高层 policy。

### 5. GQPO 到底优化谁？

GQPO 可以理解为 group-based policy optimization。Think 是高层 policy，CoT 是 Think 的动作，$\Delta Q$ 是相对 advantage。

图中 Rules 选择组内正向且最优的 CoT：

$$
j=\arg\max_i\Delta Q_i,
\qquad \Delta Q_j>0.
$$

然后提高 Think 在同一历史下生成 $c_t^j$ 的概率：

$$
\mathcal J_{\text{GQPO}}
\propto
\mathbb E\left[\log h_\theta(c_t^j\mid\text{history})\right].
$$

完整链路是：

```text
同一历史
→ Think 采样 N 条 CoT
→ 冻结 Act 将每条 CoT 转成连续动作
→ 离线 Q 计算 ΔQ
→ 选择正向最大 CoT
→ 只更新 Think
```

### 6. 线上推理闭环

线上时不需要每个 tick 都运行一个巨大 LLM 完整思考。合理读法是：

1. Think 读取较长、较低频的投放表现摘要，生成高层 CoT；
2. CoT 可以异步或低频刷新；
3. 每个高频 tick 到来时，Act 读取最新数值窗口和当前 CoT；
4. Act 快速输出连续动作；
5. 动作进入自动出价系统。

这就是层级结构的工程意义：**大模型负责慢变量和高层方向，小模型/Act 负责快变量和精确控制。**

## 第二部分：把每个知识点拆开讲

### 7. 为什么 LBM 不是“LLM 直接出价”？

直接让 LLM 输出：

```text
当前 multiplier 应为 1.137
```

会遇到数值精度、延迟、稳定性和安全问题。LBM 的输出动作来自 Act 的连续 action head，而不是语言 token。Think 的 CoT 更像高层条件：它告诉 Act 应该关注什么趋势和方向，但最终数值由专门的决策模型生成。

### 8. 为什么 Think 的输入是 $p_i$，Act 的输入是 $s_t$？

Think 处理的是压缩历史表现 $p_i$，例如：

- 过去一段时间预算是否消耗过快；
- CPA 是否持续接近上限；
- 转化是否变稀疏；
- 动作调整后效果是否改善。

这些适合语言总结。

Act 处理的是细粒度数值状态 $s_t$，例如：

- 当前 RTG；
- 当前预算和 KPI 状态；
- 曝光价值分布；
- 近期动作；
- 当前 tick 的可见上下文。

这些适合连续控制。分开输入避免让 LLM 在长字符串中同时承担状态压缩和精确动作输出。

### 9. DT 数值序列在 Act 中起什么作用？

Act 仍然保留 Decision Transformer 风格的序列：

$$
(R_{t-L},s_{t-L},a_{t-L},\ldots,R_t,s_t).
$$

这说明 LBM 没有放弃离线 RL 的数值轨迹建模。CoT 只是额外条件，真正的连续动作仍然依赖历史 RTG、state、action 的时序模式。

因此更准确的说法是：**LBM 是 LLM reasoning 与 DT-style numerical decision modeling 的融合，而不是纯 LLM agent。**

### 10. 双 embedding 为什么重要？

LBM 有两种 token：

- 文本 token：来自 CoT，使用语言 embedding；
- 决策 token：来自 RTG、state、action，使用 decision embedding。

二者进入同一个 Transformer 后通过 attention 融合：

$$
\text{language tokens} \leftrightarrow \text{decision tokens}.
$$

这让模型可以学到：

- “预算消耗慢”对应哪些数值状态；
- “适度提高”对应动作空间中的多大变化；
- “CPA 接近上限”应如何压制激进动作；
- 不同 CoT 对同一数值状态会怎样影响动作。

### 11. CoT 是条件，不是标签

Stage I 中，动作标签是数据集动作 $a_t$，不是 CoT。CoT 的作用是为 Act 提供高层语义条件。

这意味着：

- CoT 不需要逐字等于某个标准答案；
- CoT 的好坏最终要看它诱导出的动作；
- Stage II 才真正用 Q 值筛选更有决策价值的 CoT。

### 12. GQPO 为什么能减少 hallucination？

普通 LLM 可能生成看似合理但行动后果不好的理由。GQPO 用离线 Q-function 把 CoT 拉回数据价值评价：

$$
\text{good CoT} \iff Q(s_t,\tilde a_t^{\text{CoT}})>Q(s_t,a_t).
$$

也就是说，只有当 CoT 经 Act 转成动作后被 Q 认为更好，才会用于更新 Think。这比只做 SFT 更进一步：SFT 学会像历史 reasoning，GQPO 学会偏向高价值 reasoning。

### 13. 但 GQPO 不是万能安全保证

GQPO 的可靠性依赖两个条件：

1. 离线 Q-function 估计准确；
2. CoT 诱导出的动作没有远离日志覆盖分布。

如果 Act 产生 OOD 动作，Q-function 可能高估；如果日志数据本身覆盖不足，$\Delta Q$ 的正负也可能不可靠。

因此不能说“有 GQPO 就不会幻觉”。更严谨的说法是：**GQPO 用离线价值信号约束 Think，使 reasoning 更可能服务于高价值动作，但仍受离线 RL 估计误差限制。**

### 14. LBM 和 GRM 的关系

LBM 与 GRM 解决的问题不同：

| 方法 | 重点 | 强项 | 风险 |
|---|---|---|---|
| GRM | 响应建模 + 约束求根。 | 预算/CPA 显式可控。 | 曲线预测错会导致控制错。 |
| LBM | LLM reasoning + 连续动作。 | 能利用语言化高层推理。 | 约束不是天然硬保证。 |

因此不能说 LBM 替代 GRM。更合理的系统设想是：

```text
LBM-Think 给高层策略解释和方向
LBM-Act 产生候选动作
GRM/MPC 或约束 controller 做最终安全裁剪
```

但这属于工程延伸，不是论文已经验证的完整架构。

### 15. LBM 和 GAVE 的关系

GAVE 的核心是：在日志动作附近做 value-guided exploration，尝试超过历史次优轨迹。LBM 的核心是：生成多条语言 reasoning，让冻结 Act 转成动作，再用离线 Q 选择更优 reasoning。

它们都试图突破纯行为克隆，但突破方式不同：

- GAVE 改的是动作空间附近的探索；
- LBM 改的是高层 reasoning 的生成分布；
- GAVE 的探索变量是连续动作扰动；
- LBM 的探索变量是 CoT 文本。

### 16. 一个完整例子：从历史表现到动作

假设最近几个 tick 的压缩表现是：

| tick | 预算利用 | CPA/目标 | 转化速度 | 上一动作 |
|---|---:|---:|---:|---:|
| $t-3$ | 42% | 0.82 | 正常 | 0.95 |
| $t-2$ | 48% | 0.85 | 偏低 | 1.00 |
| $t-1$ | 53% | 0.88 | 偏低 | 1.04 |

Think 可能生成：

```text
预算消耗低于计划，CPA 仍低于目标，说明效率还有余量。
但转化速度偏低，剩余时间减少，应适度提高出价以获得更多流量。
```

Act 同时读取最近 $L$ 个数值 token：

$$
(R_{t-L},s_{t-L},a_{t-L},\ldots,R_t,s_t).
$$

融合 CoT 后输出：

$$
\tilde a_t=1.08.
$$

如果另一个 CoT 说“强烈提高到非常激进”，Act 可能输出 $1.30$；离线 Q 若认为这个动作会导致 CPA 风险，则 $\Delta Q<0$，该 CoT 不会被 GQPO 选中。

### 17. 为什么说 LBM 是层级模型？

层级体现在三点：

1. **时间尺度分层**：Think 看较长历史、低频推理；Act 看较短数值窗口、高频执行；
2. **表示分层**：Think 输出自然语言 reasoning；Act 输出连续数值动作；
3. **训练分层**：先训练 Act 执行动作，再用 Q 值微调 Think。

这不是简单把 LLM 拼到 DT 前面，而是把“推理”和“行动”拆成两个不同优化对象。

## 第三部分：实验应怎样读

### 18. 论文对比证明了什么？

论文在 AuctionNet 的 dense/sparse conversion 场景中对比了 CQL、IQL、BCQ、DT、DiffBid 及其 Q 变体，也比较了 prompting、SFT、GRPO、LLM-DT、Prompt-LLM-DT 等 LLM 相关方案。公开 PDF 中，LBM(P) 与 LBM(GQPO) 在多个 conversion/score 指标上优于这些 baseline，GQPO 版本进一步改善部分表现。

这些结果支持的结论是：

> 在该 benchmark 和设定下，层级 reasoning + acting 比直接数值策略或简单 LLM prompting 更有效。

但它不自动证明：

- LLM 可以直接替代约束控制器；
- 离线 Q 对所有 OOD 动作都可靠；
- 该方法已经在所有线上广告系统稳定收益。

### 19. Ablation 应重点看什么？

读 LBM 的消融时，应围绕四个问题：

1. 去掉 CoT，Act 是否明显下降？验证 reasoning 是否有用；
2. 去掉 anchor direction，是否出现文本与动作冲突？验证过滤机制；
3. 不用 GQPO，只做 prompting/SFT，是否不如最终版？验证 Q-guided reasoning；
4. Think 与 Act 是否需要分层？验证大模型推理和小模型执行的分工。

如果论文表格中某项提升不稳定，不能只背“LBM 最好”，要能说清楚是哪个模块贡献了收益。

### 20. 最大局限

LBM 的局限包括：

- **Q-function 误差**：GQPO 的训练信号来自离线 Q，Q 错则 Think 会被带偏；
- **OOD reasoning/action**：新 CoT 可能诱导 Act 输出日志外动作；
- **约束不显式**：LBM 本身不像 GRM 那样解析求预算/CPA 根；
- **推理延迟**：Think 若高频运行，成本和延迟可能不可接受；
- **可解释不等于正确**：CoT 可读，但可读理由不一定代表真实因果机制。

### 21. 工程借鉴时应怎么落地？

如果要借鉴 LBM，不应一开始就让 LLM 直接控制线上 bid。更稳的路径是：

1. 先构造高质量状态摘要 $p_i$，让 Think 生成高层诊断；
2. 保留已有数值策略模型或 DT-style Act；
3. 用双 embedding 融合 CoT 和数值序列；
4. 先离线训练 Act，使其在 CoT 条件下稳定拟合日志动作；
5. 再用保守的离线 Q 或回放评估筛选 CoT；
6. 线上先做旁路解释或候选动作建议；
7. 最终动作仍经过预算、CPA、频控等安全 controller。

## 最终 takeaway

> LBM 的价值在于给 LLM 找到了一个合理位置：不是直接输出 bid，而是作为高层 reasoning policy，为数值决策模型提供可解释方向。Act 保留 DT-style 数值轨迹建模和连续动作输出，GQPO 再用离线 Q 值筛选真正能改善动作价值的 CoT。它展示了 LLM 可以增强自动出价中的状态理解和策略解释，但最终安全性仍要依赖数值模型、Q 估计和外部约束控制。
