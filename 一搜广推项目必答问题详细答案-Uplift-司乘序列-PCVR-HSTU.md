---
tags:
  - 八股
  - 求职
  - 项目面试
  - Uplift
  - 行为序列
  - PCVRHyFormer
  - HSTU
created: 2026-07-23
---

# 一搜广推项目必答问题详细答案：Uplift、司乘序列、PCVR 与 HSTU

配套总纲：[[一搜广推算法岗位面试总纲-自我介绍-项目梳理-技术点]]  
相关专题：[[ECR项目面试问答]]｜[[司乘行为序列建设项目面试问答]]｜[[推荐算法核心模型面试手册-LR-GBDT-FM-DeepFM-DIN-SASRec-MMoE-多目标学习]]

> 回答原则：先用 30～60 秒讲清结论；面试官继续追问时，再展开公式、实验和局限。文中涉及项目实际数值的地方，必须以最终实验记录为准。

---

## 一、多档位补贴因果排序

## 1. 为什么响应预测不等于 Uplift？

**推荐回答：**

响应预测回答“用户在某档补贴下会不会呼叫”：

$$
\mu_m(x)=P(Y=1\mid X=x,T=m)
$$

Uplift 回答“该档补贴相对 Control 额外增加多少呼叫”：

$$
\tau_m(x)=\mu_m(x)-\mu_0(x)
$$

一个用户即使在 Treatment 下呼叫概率很高，如果 Control 下也很高，增量仍接近 0，不应该优先补贴。响应模型容易把自然需求强的 Sure Thing 排在前面；Uplift 模型更关注 Persuadable User。

**进一步追问：** 为什么不能直接用 Treatment 预测概率排序？

因为 $\mu_m(x)$ 混合了用户自然呼叫倾向与补贴增量。正确排序至少需要比较同一用户在 Treatment 与 Control 下的两个潜在结果估计。

**易错点：** 模型输出的 $\hat\tau_m(x)$ 是 CATE/ITE 的估计，不是可观测的个体真实因果标签。

## 2. CFR Baseline 的结构和 Loss 是什么？

**推荐回答：**

Baseline 使用共享表示加多 Treatment Heads：

```text
Sparse/Dense Features
        ↓
Embedding + Shared Bottom Φ(x)
        ↓
h_0, h_1, ..., h_M
        ↓
p̂_0(x), p̂_1(x), ..., p̂_M(x)
```

对样本 $i$ 只在实际观察到的档位 $t_i$ 上计算 Factual Loss：

$$
\mathcal L_{factual}
=\frac1N\sum_i
\operatorname{BCE}\left(y_i,\hat p_{t_i}(x_i)\right)
$$

CFR 的典型核心是在共享表示上加入组间平衡：

$$
\mathcal L_{CFR}
=\mathcal L_{factual}
+\alpha\operatorname{IPM}
\left(P(\Phi(X)\mid T=m),P(\Phi(X)\mid T=0)\right)
+\lambda\lVert\theta\rVert^2
$$

IPM 可以是 MMD 或 Wasserstein。多档位场景可以对各 Treatment 与 Control 做对齐或使用统一的多组约束。

**项目痛点：** Factual BCE 保证响应概率拟合，却没有直接要求：

$$
\hat p_m(x)-\hat p_0(x)
$$

按照真实增量顺序排列，因此和最终 AUCC 目标存在错位。

## 3. IPW 伪标签为什么在期望上有效、单样本却高方差？

**推荐回答：**

以 Treatment $m$ 和 Control $0$ 为例，可以构造：

$$
\phi_{i,m}
=(2y_i-1)
\left[
\frac{\mathbb I(T_i=m)}{e_m(X_i)}
-\frac{\mathbb I(T_i=0)}{e_0(X_i)}
\right]
$$

其中 $e_m(X)=P(T=m\mid X)$ 是 Propensity。给定 $X=x$，在可忽略性和正确 Propensity 下：

$$
\mathbb E[\phi_m\mid X=x]
=2\left(\mu_m(x)-\mu_0(x)\right)
=2\tau_m(x)
$$

常数 2 不影响排序方向，所以它能提供总体正确的增量监督。

单样本方差高有三个原因：

1. 同一用户只观察到一个 Arm，反事实仍缺失；
2. $1/e_t(x)$ 会放大小 Propensity 样本；
3. 二分类标签本身离散，四格符号只是带噪贡献，不是真实 ITE。

**工程处理：** Propensity Clipping、Self-normalized IPW、分档计算、控制 Batch 构成、较大的 Batch、DR Pseudo Outcome 和 Bootstrap。

## 4. 为什么用 $2y-1$？四格样本各代表什么？

**推荐回答：**

如果直接使用 $y\in\{0,1\}$，大量未呼叫样本对伪标签贡献为 0，Treatment Non-caller 和 Control Non-caller 无法提供方向。映射为：

$$
2y-1\in\{-1,+1\}
$$

后，四格都有信号：

| 组别 | 结果 | 伪标签方向 | 直觉 |
|---|---:|---:|---|
| Treatment | 呼叫 | 正 | 给补贴后响应，提供正增量证据 |
| Treatment | 未呼叫 | 负 | 给补贴仍未响应，提供负证据 |
| Control | 呼叫 | 负 | 不补贴也会呼叫，补贴价值较低 |
| Control | 未呼叫 | 正 | 自然响应低，可能存在被激励空间 |

**必须补一句：** Control Non-caller 的正号不表示这个具体用户拿补贴后一定呼叫，它只是在随机化和总体期望意义下提供正方向贡献。

## 5. Corr Loss 为什么适合排序？为什么不用 MSE？

**推荐回答：**

Corr Loss 可写成：

$$
\mathcal L_{corr}
=1-operatorname{Corr}(s,\phi)
$$

其中 $s$ 是模型 Uplift Score，$\phi$ 是高方差伪标签。AUCC 更关心顺序而不是数值校准；相关系数对平移和正比例缩放不敏感，能够推动高伪标签对应高 Score、低伪标签对应低 Score。

MSE：

$$
\mathcal L_{mse}=\lVert s-\phi\rVert^2
$$

会强迫模型拟合 IPW 伪标签的绝对尺度，容易被小 Propensity 产生的极值主导。

**Corr 的局限：**

- 依赖 Batch 方差与构成；
- 只约束全局线性趋势；
- 不能保证局部 Pair 顺序；
- 可能利用 Treatment Composition 捷径。

所以项目中 Corr 作为全局主监督，Pairwise 作为局部补充，同时保留 Factual Anchor。

## 6. Pairwise Pair 如何匹配？为什么不能全局随机配对？

**推荐回答：**

如果随机把任意 Treatment 与 Control 样本配对，两人的 $X$ 差异可能很大，Outcome 差异来自用户基础画像而不是补贴。更合理的是在共享表征或关键协变量空间中，为 Treatment 样本寻找 Top-K 相似 Control，限制距离或使用软匹配权重。

典型有方向的 Pair 包括：

- Treatment Caller vs Control Non-caller：前者 Score 应更高；
- Treatment Non-caller vs Control Caller：前者 Score 应更低。

可使用 Logistic Pairwise Loss：

$$
\mathcal L_{pair}
=\log\left(1+\exp[-r_{ij}(s_i-s_j)]\right)
$$

$r_{ij}\in\{-1,+1\}$ 表示期望顺序。

**风险：** Batch 内有效 Pair 少、匹配质量不稳、Representation 本身可能有偏。应监控有效 Pair 数、距离分布，并与 Corr-only/Factual-only 做消融。

## 7. 为什么 Rank Loss 会污染底层表示？

**推荐回答：**

Uplift Score 是两个 Head 的差：

$$
s_m(x)=\hat p_m(x)-\hat p_0(x)
$$

Rank Loss 的梯度会同时流入 Treatment Head、Control Head、Shared Bottom 和 Embedding。由于伪标签高方差，模型可能选择最容易的捷径：

- 放大两个 Head 的差值而不保持概率校准；
- 编码 Treatment Assignment 或高频样本；
- 破坏原来稳定的 Factual Representation；
- 让不同档位的 Score 尺度无序漂移。

最终可能 AUCC 上涨，但 Factual AUC/LogLoss、Treatment Ratio 或跨时间泛化变差。这就是两阶段训练和软解冻的动机。

## 8. TwoStage、Freeze 与 Soft-Unfreeze 有什么区别？

**推荐回答：**

TwoStage 是训练流程：

1. Stage 1：主要用 Factual Loss 学稳定的 $\hat p_t(x)$；
2. Stage 2：在已有响应 Anchor 上加入 Rank/Pairwise，优化 Uplift 排序。

Freeze 是参数策略：Stage 2 中某些参数完全不更新，例如 Embedding：

$$
\eta_{emb}=0
$$

Soft-Unfreeze 是给共享底座极小学习率：

$$
\eta_{bottom}=0.01\eta_{head}
$$

完全冻结更稳定，但底层无法适配排序；全部解冻表达力强，却容易灾难性漂移。软解冻在两者之间折中：Head 学主要排序变换，Bottom 只做温和调整。

## 9. Z-score 为什么放在每个 Treatment 内？

**推荐回答：**

不同补贴档位的基础响应率、样本量、Head 方差和 Uplift 幅度不同。如果把所有档位一起标准化，深折扣大幅 Score 可能主导梯度，浅折扣信号被淹没。

对每个档位分别做：

$$
z_{i,m}
=\frac{s_{i,m}-\mu_m}{\sigma_m+\epsilon}
$$

可以将 Rank Loss 关注点从“哪个档位天然幅度大”转为“同一档位内谁的相对增量更高”。

**注意：** Batch 太小会导致均值方差抖动；需要足够的每档样本、Moving Statistics 或跨 Batch 估计。Z-score 只服务 Rank 分支，线上原始 Uplift/Probability 的校准要单独处理。

## 10. Tanh 为什么带温度 $T=2$？

**推荐回答：**

标准化后使用：

$$
\tilde s=\tanh(z/T)
$$

它将极端值压到有限区间，减少少量 IPW 极值对相关性和梯度的控制。导数为：

$$
\frac{\partial\tilde s}{\partial z}
=\frac1T\left(1-\tanh^2(z/T)\right)
$$

$T$ 越小，越快饱和，抗极值强但可能丢失排序区分；$T$ 越大，越接近线性，保留区分但抑噪弱。$T=2$ 是消融选择的折中，不是理论常数。

## 11. AUCC/QINI 怎么计算？真实 ITE 不可见如何评估？

**推荐回答：**

先按预测 Uplift 从高到低排序，在 Top-$q$ 人群中利用 Treatment 与 Control 的实际响应构造累计增量：

$$
Gain(q)
\approx
\frac{Y_T(q)}{N_T(q)}N(q)
-\frac{Y_C(q)}{N_C(q)}N(q)
$$

具体实现可能使用样本比例或 IPW 校正。横轴从 Top 0% 到 100%，曲线下面积形成 AUUC/AUCC；Qini 通常是在累计增量基础上减去随机策略基线，再计算面积或系数。

虽然单个 ITE 不可见，但随机实验中每个排序分桶内 Treatment 与 Control 可用于估计群体平均增量。评估依赖分桶内 Overlap 与足够样本量。

**需要说明：** 公司内部 AUCC/MTAUCC 的归一化和多档聚合方式可能不同，面试时以项目真实实现为准。

## 12. Treatment Ratio 不平说明什么？

**推荐回答：**

将样本按 Uplift Score 分桶，如果 Top Bin 中某 Treatment 比例远高于全局，说明 Score 可能学到了历史分配或 Treatment Identity，而不是纯粹的异质增量。

后果是：

- 分桶内 Treatment/Control 画像不可比；
- Control 样本少，增量估计方差大；
- AUCC 可能被 Selection Bias 虚高。

但 Ratio 不平不是作弊的充分条件：真实高 Uplift 人群也可能与历史策略重合。需要结合随机化设计、Propensity、Covariate Balance、跨时间验证和线上实验判断。

## 13. RCT 下为什么还需要 IPW？

**推荐回答：**

如果 RCT 各档分流不等概率，直接比较样本贡献会让大流量 Arm 主导；IPW 用已知分流概率恢复目标总体权重。多档位、过滤、重复行和缺失也可能使分析样本中的实际比例偏离设计比例。

若严格等概率且样本处理没有破坏随机化，IPW 可能退化为常数缩放；此时它不是为“修复混杂”，而是统一多 Arm 估计公式。

**关键检查：** 随机化单位是 User、User-day、Bubble 还是 Order。若同一随机化单元重复多行，方差估计和 Bootstrap 必须按该单元聚类。

## 14. 15% 是绝对还是相对？如何判断统计显著？

**推荐回答模板：**

> 这是离线 Call AUCC 相对 CFR Baseline 的提升 15%+，不是 15 个百分点，也不是线上 ROI。Baseline 绝对值是 `[补充]`，最终模型是 `[补充]`。我会按随机化单位做 Cluster Bootstrap，报告多次重采样的均值、标准误和 95% 置信区间，并结合多随机种子、跨时间切分验证稳定性。

相对提升：

$$
\frac{Metric_{new}-Metric_{base}}{|Metric_{base}|}
$$

绝对提升：

$$
Metric_{new}-Metric_{base}
$$

二者必须区分。若 AUCC 可为负或接近 0，只报相对提升可能误导，更应同时报告绝对值。

## 15. 上线时如何把 Uplift 与补贴成本结合？

**推荐回答：**

不能只选 $\tau_m(x)$ 最大的档位，而应最大化增量净价值：

$$
Utility_m(x)
=\hat\tau_m(x)\cdot V(x)-Cost_m(x)
$$

若有预算：

$$
\max_{a_i}\sum_i Utility_{a_i}(x_i),
\qquad
\sum_i Cost_{a_i}(x_i)\le B
$$

还要加入频控、体验、公平和城市供需约束。可用 Greedy、Knapsack、Lagrangian 或策略优化。上线通过 RCT 比较增量呼叫、完单、补贴成本和 ROI，而不是只看响应率。

---

## 二、司乘行为序列建设

## 16. 为什么使用 Attempt，而不是 Order？

**推荐回答：**

Attempt 表示用户从冒泡看价开始的一次完整出行意图；Order 只有发单后才存在。一个 Attempt 可以看价未发单，也可能因改派产生多个 Order。

如果用 Order 做统一根节点：

- 看价未发单样本全部丢失；
- 价格模型只看到接受价格的人，产生选择偏差；
- 多次改派会被误当成多个独立出行意图。

所以用去重后的 Bubble Trace 作为 Attempt 根，保留 Order ID 表示实际订单事实，Origin Order ID 串联改派链路。

## 17. Bubble 未发单为什么重要？是否一定表示价格拒绝？

**推荐回答：**

它是价格决策链路的重要负反馈。只看已发单样本，相当于对“接受过某种价格的人”建模，模型不知道哪些展示导致退出。加入 Bubble 后，可以学习展示价格、价格锚点、供需、ETA 与是否发单的关系。

但未发单不一定由价格导致，还可能是需求消失、比价、目的地变更、等待时间长或误触。因此不能把所有 Bubble Non-call 直接标成“嫌贵”，而要结合多次冒泡、价格变化、供需和后续行为建模。

## 18. Event、Attempt Enrich、Order Enrich、Sequence 各是什么粒度？

**推荐回答：**

| 层 | 粒度 | 作用 |
|---|---|---|
| Event | 一行一个 Bubble/Call/Answer/Cancel/Finish 等事件 | 统一事实与时间线 |
| Attempt Enrich | 一行一次去重出行尝试 | 发单前价格、供需、看价决策 |
| Order Enrich | 一行一笔实际订单或 `trace+order` | 发单后应答、取消、履约、完单 |
| Sequence Sample | 由具体任务样本和 Anchor 定义 | 生成模型所需历史数组与 Mask |

事件层保真，Enrich 层复用，序列层适配任务。粒度必须写进表契约，否则 Join 时容易重复或穿越。

## 19. 为什么不合并成一张万能宽表？

**推荐回答：**

Attempt 与 Order 是一对零/一/多关系，预测时点也不同。强行合并会导致：

- 未发单 Attempt 大量 Null 或被过滤；
- 改派使 Attempt 特征重复；
- 完单、支付等未来字段容易泄漏到冒泡模型；
- 表越来越宽，但每个任务只用少量字段；
- 更新频率和责任边界混乱。

统一底层事件和命名，不统一所有最终形态，是可复用性与任务正确性的折中。

## 20. 改派、多 Bubble、取消阶段如何归因？

**推荐回答：**

改派：每个事件保留当前 `order_id`，同时用 `origin_order_id` 指向最初订单。这样既能还原 A→B→C 的改派过程，也能按根订单聚合。

多 Bubble：事件层保留全部有效冒泡；Attempt 层使用 `distinct_bubble_trace_id` 归并，并根据任务选择最后一次展示或保留价格变化统计。

取消：拆为应答前取消、应答后乘客/司机/客服取消、系统取消。不同阶段和角色对应价格、等待、供给偏好等不同机制，不能统一成一个 Cancel Flag。

## 21. `dt < sample_dt` 为什么不能完全防穿越？

**推荐回答：**

分区是存储裁剪，不是精确业务时点。

- `history.dt < sample.dt` 会丢掉样本当天、Anchor 之前的合法历史；
- 改为 `<=` 后，同日 Anchor 之后的事件又可能泄漏。

正确条件是：

$$
event\_time<anchor\_time
$$

分区只用来缩小扫描：

```sql
h.dt BETWEEN date_sub(s.dt, 120) AND s.dt
AND h.event_time < s.anchor_time
```

若考虑数据产出延迟，还要加 `available_time < anchor_time`。

## 22. Event Time 与 Available Time 有什么区别？

**推荐回答：**

- Event Time：行为真实发生时间；
- Available Time：该字段在生产系统中真正可查询的时间；
- Processing/Partition Time：离线任务何时接收或存储。

例如订单 10:00 完单，但状态 10:05 才入仓。对 10:02 的预测，虽然 Event Time 已发生，线上仍不可见；离线使用就是 Availability Leakage。训练样本必须模拟线上可获得信息，而不只是按最终回刷事实切时间。

## 23. 朴素 Range Join 为什么会膨胀？

**推荐回答：**

样本表与 120 天历史按 ID 和时间范围 Join。一个高频 ID 有 $S$ 个 Anchor 和 $H$ 条历史，中间候选可能接近 $S\times H$。如果历史是数百列宽表，每个匹配还复制宽列，之后才 `row_number <= 128`，前面的 Shuffle 和 Spill 已发生。

因此瓶颈不是最终序列只有 128，而是截断发生得太晚。

## 24. 预排号为什么有效？Sequence No 如何稳定？

**推荐回答：**

先建窄索引：

```text
entity_id, event_time, sequence_no, event_key, dt
```

对 Anchor 先定位窗口内最后一个 `right_no`，再取：

$$
start\_no
=\max(window\_left\_no,right\_no-127)
$$

只回表读取 `[start_no,right_no]` 最多 128 个事件键。这样把宽表无界范围 Join 变成窄索引有界检索。

Sequence No 的排序必须稳定：

```text
event_time, event_priority, stable_event_id
```

同毫秒事件需定义业务优先级。Sequence No 是查询辅助，不应代替 Event Key 成为永久事实主键；迟到回刷可能导致序号重排。

## 25. `COLLECT_LIST` 是否保证顺序？

**推荐回答：**

不保证。分布式 Shuffle 后不能依赖输入顺序。应收集带排序键的 Struct，再显式排序：

```sql
SORT_ARRAY(
  COLLECT_LIST(
    NAMED_STRUCT('seq_no', seq_no, 'event_id', event_id, 'feat', feat)
  )
)
```

再 Transform 取字段。更重要的是先截到 128 条再 Collect，否则排序语义正确但计算仍然昂贵。

## 26. 高频 ID 数据倾斜如何处理？

**推荐回答：**

1. 在 Join 前去重和长度截断；
2. 统计历史长度 P50/P95/P99/Max，识别真实高频与脏数据；
3. 表按 ID Bucket、时间 Sort；
4. 极端热点单独拆分/加盐，结果再合并；
5. 小维表使用 Broadcast；
6. 开启 AQE/Skew Join 作为兜底；
7. 监控最大 Task、Shuffle、Spill，而不只看总时长。

只增加 Executor 无法解决单个热点 Key 的长尾 Task。

## 27. 为什么是 120 天、128 条？

**推荐回答：**

120 天限制自然时间覆盖，128 限制模型 Token 数和样本体积。低频用户可能 120 天才积累少量行为，高频用户则截取最近 128 条，二者同时使用能兼顾覆盖与成本。

参数应通过消融确定：

- Window：30/60/90/120 天；
- Length：32/64/128/256；
- 观察非空率、截断率、模型指标、训练显存、任务时长和线上 P99。

不能说 128 是理论最优，只能说是当前覆盖—收益—成本折中。

## 28. 序列如何输入 DIN、SASRec、HSTU？

**推荐回答：**

每个 Attempt/Event 时间步包含类别、连续、时间和上下文字段，先投影为统一向量：

$$
h_j=Proj([Emb(cat_j),DenseProj(num_j),TimeEmb(\Delta t_j),EventEmb_j])
$$

- DIN：当前价格方案/候选订单作为 Query，对 $h_j$ 做 Target-aware Pooling；
- SASRec：加入位置编码和 Causal Mask，学习行为顺序；
- HSTU：加入相对时间/位置 Bias，用 Pointwise Attention 和门控聚合长且变长序列。

同时需要 Padding Mask、字段缺失 Mask、长度与时间截断。数据层已先防穿越，不能仅依赖模型 Mask。

## 29. 如何验证优化前后序列完全等价？

**推荐回答：**

对固定日期和样本，同时运行朴素 Range Join 与优化链路，逐样本比较：

- Event Key 集合；
- 序列顺序；
- 长度、首尾时间；
- 每个字段与 Null；
- 序列 Hash；
- 同毫秒、窗口边界、同日 Anchor、多 Bubble、多改派、高频 ID 等 Case。

先做全量统计，再抽异常 Case 人工回放。只有语义一致后，才比较 Shuffle、耗时和资源。

## 30. 这个项目不是 ETL 的算法价值是什么？

**推荐回答：**

算法价值体现在：

1. 样本定义：Attempt 决定什么是一条决策样本；
2. 负反馈：Bubble 未发单改变价格敏感度的可学习信号；
3. 时点控制：决定离线指标是否存在未来信息；
4. 表示能力：保留顺序、价格和供需，使深度序列模型可用；
5. 可扩展计算：决定亿级数据是否能稳定产出。

它建设的是模型的观测空间与监督语义，不是单纯字段搬运。

---

## 三、PCVRHyFormer 多域序列 CVR

## 31. PCVR 是什么？与 CTR/CVR 有什么关系？

**推荐回答：**

在广告漏斗中：

- CTR：$P(Click\mid Impression)$；
- CVR：$P(Conversion\mid Click)$；
- CTCVR：$P(Click\cap Conversion\mid Impression)=CTR\times CVR$。

项目中的 PCVR 需要按比赛真实标签口径解释；如果标签是在曝光或请求全空间直接预测转化，更接近 PCTCVR/Conversion Probability；如果只在点击样本上预测，才是严格 CVR。

**面试安全回答：**

> 我会先说明数据集标签和样本空间，不只根据项目名猜定义。模型最终做二分类转化排序，核心问题是多域历史与候选广告的匹配。

## 32. Baseline 是什么？真正有效的改动有哪些？

**推荐回答：**

Baseline 应按实际代码描述为 PCVRHyFormer 主干：静态稀疏/稠密特征编码、四路行为序列、MultiSeq Query、Query-to-Sequence Cross-Attention、RankMixer 和 MLP Head，而不是临场说成 DeepFM。

最终最值得讲的改动有三类：

1. 同 FID 的离散 ID Embedding 与统计量 Projection 做语义对齐；
2. 请求时间与行为时间桶的双尺度时间建模；
3. 516 版本在 Query Generator 中加入前置 Candidate-aware DIN Pooling。

硬匹配、盲目加长序列、更大维度、额外后置 DIN 等不是最终稳定贡献，应作为失败消融讲。

## 33. 为什么将静态特征 Token 化，而不是全部 Concat？

**推荐回答：**

全量 Concat 后过 MLP 会把用户、物品、请求时间和强 Dense 向量混成一个长向量，交互只隐式发生，维度随字段增长。

Token 化将不同语义组压成固定数量、统一维度的 NS Tokens：

- 保留 User/Item/Context 的语义边界；
- 便于 Query Generator 和 RankMixer 选择性交互；
- 将可变字段压成固定长度，控制输出层参数；
- 强特征可单独成 Token，避免被稀释。

代价是 Tokenizer 本身带来信息压缩；若压得过少，细粒度特征可能丢失。

## 34. 为什么同 FID 的 ID 和统计量使用逐元素加法？

**推荐回答：**

同一 FID 的类别 ID 与统计值描述同一个实体或语义槽，例如某类目 ID 及其统计强度。分别得到：

$$
e_{id}=Embedding(id),\qquad e_{stat}=Wv+b
$$

再融合：

$$
e=e_{id}+e_{stat}
$$

加法要求两者在同一维度对齐，使统计量成为该类别语义的修正，而不是在大 Concat 中失去对应关系。参数少、优化稳定，也保留残差式语义。

乘法容易在统计值小或噪声大时过度门控；无约束 Concat 需要后续网络重新学习对应关系。项目消融中加法更稳。

## 35. 四路序列为什么分域编码？

**推荐回答：**

不同域的事件字段、频率、长度和对转化的含义不同。强行拼成一条序列会导致：

- Event Type 冲突；
- 高频域淹没低频域；
- 不同时间尺度混合；
- 一个统一 Position 难表达各域内部顺序。

分域编码让每个域先学习自己的行为演化，再通过 Query Tokens/RankMixer 做跨域融合。代价是跨域交互被推迟，因此后续需要轻量融合模块。

## 36. Query Token 如何生成？

**推荐回答：**

先从静态 NS Tokens 得到当前 User-Item-Context 条件，再结合每路历史的 Masked Pooling；516 版本进一步让 Candidate Item 对该域历史做 DIN 式软匹配：

$$
a_j=f(e_{candidate},h_j),
\qquad
p_{din}=\sum_j a_jh_j
$$

将静态上下文、域摘要和候选感知兴趣输入 Query Generator，生成每域多个 Query：

$$
Q_d=MLP([NS,pool_d,p_{din,d}])
$$

这些 Query 不是固定可学习 CLS，而是随用户、候选和域变化的条件兴趣槽；之后通过 Cross-Attention 从完整序列读取更细信息。

## 37. 516 前置 DIN 与后置 DIN Residual 有什么区别？

**推荐回答：**

前置 DIN：候选感知发生在 Query 生成阶段：

```text
Candidate + History → Target-aware Pool
→ Query Generator → HyFormer/Cross-Attention
```

它让进入主干的 Query 从一开始就带候选语义，无关历史在早期被降权。

后置 DIN Residual：主干已完成序列提取后，再额外计算一条 Candidate-to-History 分支并加到输出：

```text
HyFormer Output + DIN Residual → Head
```

它更像保守补丁，信息可能与已有 Query Cross-Attention 重复。当前实验结论是 516 前置方案更好，所以后置分支只能作为消融经历讲。

## 38. 为什么候选感知应在 Query 生成阶段进入？

**推荐回答：**

用户有多兴趣，候选广告决定本次应该读取哪部分历史。如果先生成候选无关 Query，再在末端补 Candidate，主干已经把无关历史混入表示。

前置 Candidate-aware Pooling 带来：

1. Query 定向：Query 表示“与当前候选相关的兴趣槽”；
2. 早期降噪：无关历史在深层编码前降权；
3. 条件化后续交互：Cross-Attention 的查询方向更明确；
4. 避免末端分支与主干重复建模。

## 39. HyFormer 的 Sequence Evolution、Query Decoding、Query Boosting 是什么？

**推荐回答：**

可以按三步讲：

1. Sequence Evolution：每路历史先做域内序列变换，建模行为之间的关系与时间信息；
2. Query Decoding：每域 Query 作为 Query，序列作为 Key/Value，通过 Cross-Attention 提取与兴趣槽相关的历史；
3. Query Boosting：所有域 Query 与静态 NS Tokens 通过 RankMixer 交互，补充跨域和静态上下文。

核心是 Query Bottleneck：长序列不会全部进入最终 Head，而是压缩成固定数量的兴趣 Query，控制计算与参数。

## 40. RankMixer 与直接堆 MLP/Self-Attention 有什么区别？

**推荐回答：**

普通逐 Token MLP 只做通道变换，不能直接交换 Token 信息；Flatten 后大 MLP 可以交互，但参数随 $T\times D$ 快速增长并破坏 Token 结构。

Self-Attention 通过 $QK^T$ 为每个样本动态学习 Token 两两权重，表达强但有投影和 $O(T^2D)$ 计算。

RankMixer 使用 Reshape/Transpose 在 Token 与 Channel 之间做近乎无参数的重排，再用共享 FFN 混合，适合 Token 数较短且语义较强的阶段。它要求：

$$
D\bmod T=0
$$

优点是轻量，缺点是没有 Attention 那种内容自适应两两权重，表达受固定重排归纳偏置限制。

## 41. 为什么更长序列、更大 $d_{model}$ 反而下降？

**推荐回答：**

更长序列会加入陈旧、跨兴趣和低相关行为，正信号密度下降；如果数据量有限，Attention 可能记忆噪声。更大维度增加高基数 ID 记忆能力，本地同分布验证可能更好，但时间后移测试泛化变差。

还可能存在：

- 有效训练 Epoch 不足；
- 正则和学习率未随容量调整；
- Padding 比例增大；
- RankMixer 的 $D\%T$ 约束被破坏；
- 候选感知模块已提取关键信息，额外容量冗余。

因此用时间切分和长度/维度消融，而不是默认 Scaling 一定有效。

## 42. 硬匹配特征为什么从约 0.826 降到约 0.820？

**推荐回答：**

硬匹配把 `candidate_id == history_id` 或类目相等作为强规则，可能有三类问题：

1. 过拟合：记住高频 Item 和短期共现；
2. 稀疏：精确匹配覆盖低，新 Item 几乎无信号；
3. 分布漂移：验证期 Item 结构变化后规则失效；
4. 冗余：Attention 本来能学习软相似，硬规则反而放大噪声。

软 Attention 可以学习相似程度与上下文条件，比二值硬匹配更平滑。失败实验说明业务直觉需要通过泛化验证，而不是越显式越好。

## 43. Adagrad 和 AdamW 为什么分组使用？

**推荐回答：**

高基数稀疏 Embedding 更新频率差异大。Adagrad 为每个参数累计平方梯度：

$$
G_t=G_{t-1}+g_t^2,
\qquad
\theta_{t+1}=\theta_t-\frac{\eta}{\sqrt{G_t}+\epsilon}g_t
$$

低频 ID 累积小，仍能获得较大步长；高频 ID 步长逐渐缩小。

Dense Attention/MLP 使用 AdamW，利用一二阶矩加速非平稳优化，并用 Decoupled Weight Decay 正则。分组还允许 Embedding 与 Dense Module 使用不同学习率和 Weight Decay。

**局限：** Adagrad 状态占内存，后期学习率可能过小；分组策略必须通过实验验证。

## 44. AUC 与 LogLoss 的区别？比赛为什么看 AUC？

**推荐回答：**

AUC 衡量随机正样本 Score 大于随机负样本的概率：

$$
AUC=P(s^+>s^-)
$$

它只关心排序，对单调变换和类别比例相对稳健。

LogLoss：

$$
-y\log p-(1-y)\log(1-p)
$$

关心概率是否准确，高置信错误惩罚强。

比赛以 AUC 排名，是因为 CVR 任务常更关注候选排序；但业务出价、ROI 或概率乘法需要校准，不能因为比赛看 AUC 就忽略 LogLoss/Calibration。

## 45. 如何确认模型不是在记忆高基数 ID？

**推荐回答：**

1. 使用严格时间切分，而不是随机切分；
2. 分 Seen/Unseen、Head/Tail Item 报告指标；
3. 去掉/Hash/Drop 高基数 ID 做消融；
4. 监控训练—验证 Gap 和 Embedding Norm；
5. 对新 Item 冷启动单独评估；
6. 比较更小 $d_{model}$、Embedding Dropout 和频率裁剪；
7. 检查显式硬匹配是否只在同分布验证有效。

项目中更大维度和硬匹配退化，本身就是 ID 记忆风险的证据，所以最终选择较小维度和软语义交互。

---

## 四、itemCF + HSTU 双阶段推荐

## 46. itemCF 相似度公式是什么？热门物品为什么会污染共现？

**推荐回答：**

基础 Cosine ItemCF：

$$
sim(i,j)
=\frac{|U_i\cap U_j|}{\sqrt{|U_i||U_j|}}
$$

也可以对每个用户的共现贡献加权：

$$
C_{ij}
=\sum_{u:i,j\in I_u}w(u,i,j)
$$

热门物品与大量物品共现，即使没有强语义关系也会获得高 $C_{ij}$；重度用户行为多，会产生 $O(|I_u|^2)$ Pair 并主导统计。

常用修正：Cosine/流行度归一、$1/\log(1+|I_u|)$ 用户活跃度惩罚、时间间隔衰减、同类目/行为类型权重和热门项降权。

## 47. 时间衰减、用户活跃度惩罚、热度校正分别解决什么？

**推荐回答：**

- 时间衰减：近期共现更能代表当前兴趣，例如 $\exp(-\gamma\Delta t)$；
- 用户活跃度惩罚：减少超长行为用户对海量 Item Pair 的过度贡献；
- 热度校正：避免所有用户都召回同一批热门 Item，提升个性化和长尾覆盖。

三者作用层次不同：时间处理新鲜度，活跃度处理用户贡献偏差，热度处理 Item Exposure Bias。权重过强会伤害有效热门信号，需要消融。

## 48. 为什么召回和排序分开？

**推荐回答：**

全库可能有百万/亿级 Item，不可能对每个 Item 使用 HSTU 重模型。召回阶段用 itemCF/双塔等低成本方法，将候选缩到几百或几千并保证覆盖；排序阶段对小候选集使用丰富序列和上下文精确打分。

召回优化上限：真实相关 Item 没进入候选，排序无法补救；排序优化精度：召回只保证候选相关，不保证最终顺序。两阶段分别平衡 Recall、Latency 和 Accuracy。

## 49. HR@K、Recall@K、NDCG@K 有什么区别？

**推荐回答：**

Hit Rate：

$$
HR@K=\frac1N\sum_u\mathbb I(R_u^K\cap G_u\neq\emptyset)
$$

Recall：

$$
Recall@K
=\frac1N\sum_u\frac{|R_u^K\cap G_u|}{|G_u|}
$$

单正样本时 HR 与 Recall 数值相同；多正样本时 Recall 衡量找回比例。

NDCG 使用位置折损：

$$
DCG@K=\sum_{r=1}^{K}\frac{2^{rel_r}-1}{\log_2(r+1)},
\qquad
NDCG=DCG/IDCG
$$

它奖励把相关 Item 放得更靠前。

## 50. 类目多样性如何定义？如何与准确率权衡？

**推荐回答：**

可以使用 Top-K 不同类目覆盖：

$$
CategoryCoverage@K
=\frac{|\{cat(i):i\in R^K\}|}{K}
$$

或 Intra-list Diversity：

$$
ILD@K
=\frac{2}{K(K-1)}\sum_{i<j}(1-sim(i,j))
$$

简单类目降权可以在候选集中抑制拥挤类目；更通用可用 MMR：

$$
\lambda Rel(i)-(1-\lambda)\max_{j\in S}sim(i,j)
$$

准确率和多样性通常冲突，应画 HR/NDCG 与 Coverage/ILD 的 Pareto 曲线，通过业务价值或 A/B 选择权重，而不是只追求最大多样性。

## 51. HSTU Pointwise Attention 与 Softmax Attention 有什么区别？

**推荐回答：**

标准 Attention：

$$
A_{ij}
=\operatorname{Softmax}_j
\left(\frac{q_i^Tk_j}{\sqrt d}+b_{ij}\right)
$$

每个 Query 对所有 Key 的权重和为 1，历史行为之间形成全局竞争。

HSTU 类 Pointwise Attention 对每个 Pair 的 Logit 使用点式非线性，例如：

$$
A_{ij}=\operatorname{SiLU}(q_i^Tk_j+b_{ij})
$$

不做跨所有 Key 的 Softmax 归一化，再聚合 $V$ 并通过归一化/门控 Transformation 稳定输出。它能够保留“相关行为有多少、强度多大”的信息，更贴合重复消费与兴趣强度。

**不要说：** 去掉 Softmax 就去掉了 $QK^T$；Pairwise Attention Matrix 仍存在。

## 52. HSTU Dense Attention 的复杂度是否仍为 $O(L^2d)$？

**推荐回答：**

是。单层主要包括：

$$
O(BL^2d_a)
$$

的 $QK^T$ 和加权聚合，以及：

$$
O(BLd^2)
$$

的线性投影/Transformation，因此常写：

$$
O(BL^2d+BLd^2)
$$

变长 Jagged 序列实际更接近：

$$
O\left(\sum_iL_i^2d\right)
$$

而不是按全局 $L_{max}$ Padding 的 $O(BL_{max}^2d)$。这减少无效计算，但没有改变 Dense Attention 的二次渐近阶。

## 53. HSTU 相比 Transformer 主要节省在哪里？

**推荐回答：**

1. Block 更紧凑，减少 Attention 外线性层和较重 FFN 路径；
2. 门控 Pointwise Transformation 让交互与变换融合；
3. Jagged/Ragged Kernel 只计算真实序列长度，减少 Padding；
4. Fused Kernel 减少中间 Tensor、HBM IO 和 Kernel Launch；
5. Stochastic Length 在训练时减少有效 Token；
6. 生成式多位置监督把序列编码摊到多个 Target；
7. 推理可用 KV/历史表示缓存与 Candidate Microbatch 复用计算。

所以加速主要来自常数、有效长度、内存 IO 和重复计算复用，不是简单的 Big-O 降阶。

## 54. InfoNCE 的公式是什么？温度有什么作用？

**推荐回答：**

对用户表示 $u$、正 Item $v^+$ 和负样本集合：

$$
\mathcal L
=-\log
\frac{\exp(sim(u,v^+)/\tau)}
{\exp(sim(u,v^+)/\tau)+\sum_{j}\exp(sim(u,v_j^-)/\tau)}
$$

温度 $\tau$ 控制 Logit 尺度：

- 小温度让分布更尖，强调最难负样本，梯度更强但可能不稳；
- 大温度让分布平滑，训练稳定但区分力弱。

$\tau=0.07$ 是常见起点，但必须结合 Batch Size、负样本数、相似度分布做消融，不是通用最优值。

## 55. 为什么要做 L2 归一化？

**推荐回答：**

归一化后：

$$
\bar u=\frac{u}{\lVert u\rVert_2},
\qquad
\bar v=\frac{v}{\lVert v\rVert_2}
$$

内积变为 Cosine Similarity，分数主要由方向而不是向量模长决定。这样避免模型仅靠无限增大 Norm 降低 InfoNCE，温度的尺度含义也更稳定，方便 ANN 使用 Cosine/Inner Product。

代价是丢失 Norm 可能承载的热门度或置信度信息；如业务需要，可另行建模 Bias/Popularity。

## 56. 6:4 混合负样本是哪两类？比例如何验证？

**推荐回答：**

必须以你的实际代码为准，不要临场猜。若项目确实是“随机负样本 + 难负样本”，可以回答：

> 60% 随机负样本保证全局分布覆盖、帮助区分明显无关 Item；40% Hard/同类目/热门曝光负样本提高局部决策边界。全 Hard 容易引入 False Negative 和训练不稳，全随机又太容易。

验证方法：

- 比较 10:0、8:2、6:4、4:6、0:10；
- 看 HR/NDCG、训练 Loss、Hard Negative 命中率；
- 分 Head/Tail、新老 Item；
- 监控正负相似度分布和 False Negative 率。

若两类实际定义不同，应替换上面的名称与解释。

## 57. False Negative 如何处理？

**推荐回答：**

用户未点击不等于不喜欢，尤其是未曝光 Item。可以：

1. 优先从已曝光未反馈中采负，语义更明确；
2. 排除用户未来正样本和历史正反馈；
3. 同类目 Hard Negative 设置较低权重；
4. 使用 Debiased/Weighted Contrastive Loss；
5. 根据 Item Popularity 修正采样概率；
6. 多正样本学习，允许多个相关 Item；
7. 控制 Hard Negative 比例。

需要在“难度”和“标签可信度”之间折中。

## 58. 召回指标提高为什么不一定带来最终 NDCG 提升？

**推荐回答：**

召回增加的候选可能是：

- 重复或同类 Item；
- 排序模型无法区分的 Hard Candidates；
- 与精排训练分布不一致；
- 虽然命中，但进入候选位置太后或被规则过滤；
- 提高覆盖却挤掉高价值候选。

因此需要看 Recall Channel 的独占命中、精排后保留率、Oracle NDCG、候选重复率和端到端 Ablation。召回与排序要联合评估，不能各自只优化局部指标。

## 59. 如果上线上量，如何做 ANN、缓存和增量更新？

**推荐回答：**

如果排序/召回改成双塔向量检索：

1. 离线或准实时生成 Item Embedding；
2. 用 FAISS/Milvus 构建 HNSW 或 IVF-PQ 索引；
3. User Sequence Encoder 生成 User Vector；
4. ANN Top-K 召回，再进入 HSTU/精排；
5. 监控 Recall@K、QPS、P99、Index Size 和更新延迟。

缓存方面：

- 缓存用户历史 Embedding/序列状态；
- Item Embedding 与静态特征常驻；
- 候选无关计算提前做，候选相关部分轻量化。

增量方面：

- 新 Item 实时追加或进入 Delta Index；
- 定期 Merge/Rebuild 主索引；
- 用户新行为触发增量序列更新；
- 处理删除、版本一致性、冷热分层和回退策略。

**边界说明：** 如果没有生产 ANN 经验，应明确这是设计方案，而不是已落地成果。

---

## 五、最后速记

### Uplift

> Factual BCE 学响应，IPW/Corr/Pairwise 学增量顺序；TwoStage 和软解冻保护因果表征；AUCC 必须结合 Treatment Ratio、Overlap 和置信区间。

### 司乘序列

> Attempt 统一决策语义，Event 保真、Enrich 复用、Sequence 适配任务；先窄索引截 128，再回宽表，分区裁剪不能替代 Event/Available Time 防穿越。

### PCVR

> 静态 Token + 四域序列 + 条件 Query；516 把候选感知放进 Query Generator；RankMixer 轻量跨 Token 融合；软交互比硬匹配更能泛化。

### HSTU

> Pointwise Attention 保留兴趣强度，但 Dense 复杂度仍是二次；实际加速来自紧凑 Block、Jagged/Fused Kernel、有效长度和历史计算复用。

