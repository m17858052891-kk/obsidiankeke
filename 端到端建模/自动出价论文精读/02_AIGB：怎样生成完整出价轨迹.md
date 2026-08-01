---
tags:
  - 自动出价
  - Diffusion
  - AIGB
  - 论文精读
created: 2026-07-28
---

# AIGB / DiffBid：怎样生成完整出价轨迹？

论文：[AIGB: Generative Auto-bidding via Diffusion Modeling](https://arxiv.org/abs/2405.16141)  
会议：KDD 2024  
原图：Figure 2（Generative Auto-bidding 总体框架）

> **一句话总结：** DiffBid 不直接逐时段输出出价，更不直接生成每次曝光的 bid。它先在 return、约束和反馈条件下生成一段未来的广告**状态轨迹**；再根据状态历史和计划中的下一状态，预测当前时段应使用的 bidding parameters；最后由解析竞价公式对每条曝光计算具体 bid。

## 1. 先建立问题：一条曝光的 bid 与一个时段的 action 不是一回事

广告主在一个 episode（例如一天）中面对连续到来的曝光机会 $i=1,\ldots,N$。对第 $i$ 条曝光：

- $v_i$：赢得曝光带来的业务价值；
- $o_i\in\{0,1\}$：是否赢得曝光；
- $c_i$：赢得曝光实际支付的成本；
- $b_i^*$：该条曝光的具体竞价。

最简单的目标是总价值最大且不超预算：

$$
\max_{\{o_i\}}\sum_i o_i v_i
\qquad
\text{s.t.}\quad
\sum_i o_i c_i\le B.
$$

论文还使用统一的 ratio 约束形式：

$$
\frac{\sum_i c_{ij}o_i}{\sum_i p_{ij}o_i}\le C_j,
\qquad j=1,\ldots,J.
\tag{1}
$$

$p_{ij}$ 是约束分母侧的 performance indicator，$c_{ij}$ 是对应成本项，$C_j$ 是阈值。例如 Target-CPC 可理解为“累计成本 / 累计点击或效果量”不能超过目标。

已有工作给出多约束竞价的解析形式：

$$
b_i^*
=
\lambda_0v_i
+
c_i\sum_{j=1}^{J}\lambda_jp_{ij}.
\tag{3}
$$

$\lambda_0,\ldots,\lambda_J$ 是 bidding parameters。它们在一个决策时段内作为全局控制参数；而各曝光的 $v_i,c_i,p_{ij}$ 不同，所以代入同一组参数后仍会得到不同的 $b_i^*$。

**AIGB 的 action 是调整 $\lambda$ 的向量，而不是 $b_i^*$。**因此模型按数分钟的时段更新参数，解析公式再按曝光粒度执行竞价。

![[Pasted image 20260730172404.png]]

## 2. 按 Figure 2 的符号走完全流程

整张图可先压缩成这一条链：

$$
\underbrace{s_{0:t},y(\tau)}_{\text{历史与目标}}
\xrightarrow{\text{conditional diffusion}}
\underbrace{x'_0(\tau),s'_{t+1}}_{\text{未来状态计划}}
\xrightarrow{f_\phi}
\underbrace{\hat a_t}_{\text{参数动作}}
\xrightarrow{\text{Eq.(3)}}
\underbrace{b_i^*}_{\text{每次曝光的具体 bid}}.
$$

Figure 2 上方是训练阶段将真实状态轨迹逐步加噪的 Forward Process；下方是生成阶段从噪声逐步去噪的 Reverse Process；右侧才是动作与 bid 的生成。图中一串小折线不是多条独立轨迹，而是同一个高维状态矩阵在不同扩散步的示意。

### 2.1 全部符号、输入和输出

| 图中对象 | 含义 | 输入 | 输出 | 作用 |
|---|---|---|---|---|
| $s_t$ | 时段 $t$ 的状态向量 | 环境实时统计 | 一维向量 | 描述目前处于什么投放局面。 |
| $a_t$ | 时段 $t$ 的参数动作 | 策略或日志 | 对 $\lambda$ 的调整/参数向量 | 不等于某条曝光的 bid。 |
| $r_t$ | 时段 reward | 环境反馈 | 业务价值 | 组成一条 episode 的总 return。 |
| $\tau$ | 一条完整投放轨迹 | $(s_t,a_t,r_t)$ 序列 | episode 索引 | 例如一天的 96 个时间窗口。 |
| $x_0(\tau)$ | 干净状态轨迹 | 日志的 $s_1,\ldots,s_T$ | $T\times d_s$ 矩阵 | 扩散训练的真实样本。 |
| $x_k(\tau)$ | 第 $k$ 步带噪轨迹 | $x_0$ 与噪声 | 同形状矩阵 | 训练时的去噪题目。 |
| $x'_K,x'_0$ | 生成阶段的噪声起点与结果 | 随机噪声、历史、条件 | 未来状态计划 | 撇号表示不是已发生日志。 |
| $y(\tau)$ | 条件 | return、约束、反馈 | 条件向量/序列 | 说明想生成怎样的轨迹。 |
| $\epsilon_\theta$ | 噪声预测器 | $x_k,y,k$ | $\hat\epsilon_k$ | U-Net 去噪网络。 |
| $f_\phi$ | inverse dynamics | 状态历史、计划下一状态 | $\hat a_t$ | 将计划落实为当前参数。 |
| Eq.(3) | 解析竞价层 | $\hat a_t$ 与曝光特征 | $b_i^*$ | 每条曝光的最终执行规则。 |

### 2.2 $s_t$ 到底是什么

论文在问题定义中明确列出 state 的典型组成：

1. 剩余时间；
2. 剩余预算；
3. 预算消耗速度；
4. 实时 cost-efficiency，例如实时 CPC；
5. 平均 cost-efficiency，例如累计平均 CPC。

Figure 2 的示意表还写有 Left Budget、Cost Speed、Bidding Parameters。应将它理解为状态表的示例列：当前参数水平也可以记录为系统状态；而 $a_t$ 则是这一时刻对参数做的动作。论文未披露唯一完整的工业特征 schema。

因此状态不是一个数字，而是向量：

$$
s_t=
[\text{剩余时间},\text{剩余预算},\text{消耗速度},
\text{实时 CPC},\text{平均 CPC},\ldots].
$$

若一天划分为 $T=96$ 个 15 分钟窗口，扩散对象是：

$$
x_0(\tau)=(s_1,\ldots,s_T)\in\mathbb R^{T\times d_s}.
\tag{6}
$$

第一维是时间，第二维是状态字段。图里的多根线只是将这张状态时间表画出来。

### 2.3 用一个例子贯穿全文

现在是上午 11 点：剩余预算 60%，当前消耗偏慢、实时 CPC 偏高、累计平均 CPC 仍可接受；晚高峰价值更高。广告主要求总价值高、最终 CPC 合规，并希望花费平滑。

- 剩余预算、消耗速度、CPC 等进入 $s_t$；
- 高 return、CPC 合规、平滑和晚花偏好进入 $y(\tau)$；
- 模型生成的不是“下一条曝光出 8.3 元”，而是未来状态表：中午相对保守，晚高峰提高消耗速度，同时控制累计 CPC；
- 得到计划下一状态 $s'_{t+1}$ 后，才生成当前参数动作 $\hat a_t$。

## 3. Figure 2 左下：Conditions $y(\tau)$ 如何形成

图中的 Return、Constraints、Feedbacks 经过特征处理并进入去噪网络，形成条件 $y(\tau)$。它不是需要模型预测的标签，而是生成时告诉模型“我希望出现怎样未来状态”的说明书。

### 3.1 Return condition

一条轨迹的总收益：

$$
R(\tau)=\sum_{t=1}^{T}r_t.
$$

论文将它归一化：

$$
\bar R(\tau)
=
\frac{R(\tau)-R_{\min}}{R_{\max}-R_{\min}}
\in[0,1].
\tag{13}
$$

训练时，模型学习某类状态轨迹与相应 return 条件共同出现的模式；生成时将 $\bar R=1$ 设为最高 return 条件。它学习的是：

$$
p_\theta\bigl(x_0(\tau)\mid y(\tau)\bigr),
\tag{4}
$$

而不是直接穷举真实环境中的全局最优轨迹。更稳妥地说，它从日志支持的分布中生成与高 return 条件匹配的状态计划。

### 3.2 Constraint 与 feedback condition

以 Target-CPC 为例，论文使用最终 ratio：

$$
x=\frac{\sum_i c_io_i}{\sum_i p_io_i}
$$

及其是否满足阈值 $C$ 的指示变量：

$$
E=\mathbb I[x\le C].
\tag{14}
$$

它也可以把归一化 ratio 纳入条件。论文还给出两类反馈条件：

- Smoothness：用相邻时段成本变化，例如 $\frac1T\sum_t|\text{cost}_t-\text{cost}_{t-1}|$，表示是否平滑；
- Early/Late Spend：用前半天成本占全天成本的比例，表示希望早花还是晚花。

这些条件是**软生成控制**：模型偏向生成历史中与该条件共现的轨迹，但论文并未保证每一次采样都硬满足预算或 CPC，线上仍需预算、频控与安全规则。

## 4. Figure 2 上方：Forward Process 只在训练时使用

从日志的干净状态轨迹 $x_0(\tau)$ 开始，按噪声日程逐步加高斯噪声：

$$
q\bigl(x_k(\tau)\mid x_{k-1}(\tau)\bigr)
=
\mathcal N\left(
\sqrt{1-\beta_k}\,x_{k-1}(\tau),
\beta_k I
\right).
\tag{7}
$$

$\beta_k$ 是第 $k$ 次加噪的强度；论文采用 cosine schedule，使噪声逐步、平滑地增加。因此图上方的方向是：

$$
x_0\rightarrow x_1\rightarrow\cdots\rightarrow x_K\approx\mathcal N(0,I).
$$

$x_1$ 还可辨识预算消耗趋势，$x_K$ 接近纯噪声。这一过程不输出 action、不执行 bid；唯一目的，是给去噪网络制造不同难度的学习题目。

## 5. Figure 2 下方：Reverse Process 怎样生成未来状态计划

DiffBid 学习反向条件分布：

$$
p_\theta\bigl(x_{k-1}(\tau)\mid x_k(\tau),y(\tau)\bigr).
\tag{5}
$$

### 5.1 去噪网络 $\epsilon_\theta$

图中的 Conv 方块表示 $\epsilon_\theta$。论文实现使用 U-Net；输入为当前带噪状态表、条件和扩散步：

$$
\bigl(x_k(\tau),y(\tau),k\bigr)
\longrightarrow
\epsilon_\theta
\longrightarrow
\hat\epsilon_k.
$$

网络沿时间维度查看整段状态矩阵，因此可同时理解“上午慢花”与“晚高峰留预算”的关系；这与单步 $s_t\rightarrow s_{t+1}$ 预测不同。论文未说明 $y$ 在 U-Net 内具体以拼接、FiLM 还是 cross-attention 注入，不能从图中臆测。

### 5.2 classifier-free guidance

训练时随机丢弃条件，让同一网络既学无条件预测，也学有条件预测：

$$
\epsilon_\theta(x_k,k),
\qquad
\epsilon_\theta(x_k,y,k).
$$

生成时采用：

$$
\hat\epsilon_k
=
\epsilon_\theta(x_k,k)
+\omega\left[
\epsilon_\theta(x_k,y,k)-\epsilon_\theta(x_k,k)
\right].
\tag{8}
$$

无条件项表示日志中自然常见的状态形状；差值表示为了满足 return、约束和反馈应往哪里偏移。$\omega$ 越大，条件作用越强，也更可能偏离自然日志分布。论文实现报告 condition dropout 为 0.2，guidance scale 为 0.2。

### 5.3 线上如何从噪声得到 $x'_0$

服务在时段 $t$ 启动时：

$$
x'_K(\tau)\sim\mathcal N(0,I),
$$

然后把已观测的历史状态 $s_{0:t}$ 放入轨迹。每一步利用噪声预测构造反向均值并采样：

$$
x'_{k-1}(\tau)
=
\mu_\theta(x'_k(\tau),y(\tau),k)
+\sqrt{\beta_k}z,
\qquad
z\sim\mathcal N(0,I).
\tag{10}
$$

重复 $K$ 次后得到：

$$
x'_0(\tau)
=
[s_0,\ldots,s_t,s'_{t+1},\ldots,s'_T].
$$

前半段是事实历史，后半段是生成的计划。AIGB 的“整段生成”指生成对象是整段状态，而不是线上一次生成后全天永不更新；在下一时段拿到新反馈后，系统可以再以更新的历史与条件滚动生成。

## 6. Figure 2 右侧：state plan 如何变成 action，再变成 bid

### 6.1 inverse dynamics $f_\phi$

$x'_0$ 说的是“状态应该怎样演化”，例如下一时段要提升消耗速度但保持 CPC；它不直接给出参数怎么调。论文用非马尔可夫 inverse dynamics：

$$
\hat a_t
=
f_\phi\bigl(s_{t-L:t},s'_{t+1}\bigr).
\tag{11}
$$

- $s_{t-L:t}$：长度 $L$ 的真实历史状态窗口；
- $s'_{t+1}$：生成状态轨迹中的下一状态目标；
- $\hat a_t$：时段 $t$ 的 predicted bidding parameters。

称为非马尔可夫，是因为它不只看 $s_t$，还显式利用一段历史。论文的动机是预算消耗形状、竞争变化、累计效率等影响未必能压缩进一个当前状态。

### 6.2 参数动作到单次曝光 bid

将 $\hat a_t$ 中的 $\hat\lambda_0,\ldots,\hat\lambda_J$ 代回 Eq.(3)，再结合每次到来曝光自己的 $v_i,c_i,p_{ij}$，才得到 $b_i^*$。

在贯穿例子中：

1. 生成轨迹要求下一时段提升消耗速度、保持 CPC；
2. $f_\phi$ 根据过去的消耗与 CPC 历史，输出当前 $\hat a_t$；
3. 高价值曝光和低价值曝光的 $v_i$ 不同，经过 Eq.(3) 后得到不同 bid；
4. 因而 AIGB 时段级更新参数，解析层仍可曝光级精细竞价。

这正是 Figure 2 中 Bid Generation 到 Eq.(3) 再到 $b_i^*$ 的完整含义。

## 7. 训练：两个模块分别怎样更新

论文将离线学习拆为状态去噪和 inverse dynamics 两个监督任务：

$$
\mathcal L(\theta,\phi)
=
\underbrace{
\mathbb E_{k,\tau\sim\mathcal D}
\left\|
\epsilon-\epsilon_\theta(x_k(\tau),y(\tau),k)
\right\|^2
}_{\mathcal L_{\rm diffusion}}
+
\underbrace{
\mathbb E_{(s_{t-L:t},a_t,s'_{t+1})\sim\mathcal D}
\left\|
a_t-f_\phi(s_{t-L:t},s'_{t+1})
\right\|^2
}_{\mathcal L_{\rm ID}}.
\tag{12}
$$

### 7.1 去噪 loss 更新 $\theta$

从日志抽一条 $x_0(\tau)$，随机取扩散步 $k$，加噪得到 $x_k$，再让 $\epsilon_\theta$ 回归真实噪声 $\epsilon$：

$$
x_k,y,k
\rightarrow
\epsilon_\theta
\rightarrow
\mathcal L_{\rm diffusion}
\rightarrow
\theta.
$$

它学习的是条件状态轨迹分布，不是直接监督某条曝光的 bid。

### 7.2 动作 loss 更新 $\phi$

从同类离线日志取历史状态、当时 action 和下一状态目标：

$$
(s_{t-L:t},s'_{t+1})
\rightarrow
f_\phi
\rightarrow
\hat a_t
\rightarrow
\mathcal L_{\rm ID}
\rightarrow
\phi.
$$

它学习“若想从这段历史走向这个下一状态，日志中的系统当时使用了怎样的参数动作”。因此状态计划才有可执行的落点。

两项损失相加联合训练，但直接更新的模块不同：第一项训练 $\epsilon_\theta$，第二项训练 $f_\phi$。论文并非让扩散 loss 穿过环境并直接反传到每一次曝光 bid。

## 8. 把一次训练和一次线上决策走完

### 8.1 训练

1. 从历史日志取 episode $\tau$：状态、动作、reward 序列；
2. 由总 return、约束满足情况、花费偏好构造 $y(\tau)$；
3. 随机采样扩散步 $k$，将 $x_0$ 加噪为 $x_k$；
4. 计算 $\mathcal L_{\rm diffusion}$，更新 $\theta$；
5. 用日志中的历史状态、动作、下一状态样本计算 $\mathcal L_{\rm ID}$，更新 $\phi$；
6. 训练时随机丢弃条件，为 classifier-free guidance 做准备。

### 8.2 服务

1. 读取当前历史 $s_{0:t}$；
2. 设置 $y(\tau)$：高 return、CPC 合规、平滑、早花或晚花等；
3. 从随机 $x'_K$ 开始，把 $s_{0:t}$ 写入轨迹；
4. 执行 $K$ 次反向去噪，得到 $x'_0$；
5. 取 $s'_{t+1}$，由 $f_\phi$ 得到 $\hat a_t$；
6. 该时段每条曝光代入 Eq.(3)，得到 $b_i^*$；
7. 环境产生新的状态与 reward，进入下一时段。

~~~text
历史状态 + 业务目标
      ↓
生成未来状态计划 x'₀
      ↓
取计划下一格 s'ₜ₊₁
      ↓
inverse dynamics 得到参数 âₜ
      ↓
Eq.(3) 按曝光计算 b*ᵢ
      ↓
环境反馈，滚动到下一时段
~~~

## 9. 与逐步 MDP / Decision Transformer 的区别

传统逐步 policy 的形式是：

$$
s_t\rightarrow a_t\rightarrow s_{t+1}\rightarrow a_{t+1}.
$$

前面时段的误差会通过状态传导，长周期中容易累积。AIGB 的层级分解是：

$$
\underbrace{
p_\theta(s_{t+1:T}\mid s_{0:t},y)
}_{\text{先生成未来状态形状}}
\quad+\quad
\underbrace{
f_\phi(s_{t-L:t},s'_{t+1})
}_{\text{再执行当前动作}}.
$$

论文的主张不是任意场景下都能找到真实环境的全局最优，而是：在其理论假设和离线示范数据覆盖下，最大似然拟合条件状态轨迹可对应一个非马尔可夫决策问题；实证上，这种整段建模能缓解一步式建模的误差传播和稀疏 return 问题。

## 10. 实验、效率与边界

- 论文将一天划分为 96 个 15 分钟时段。不同预算和数据规模的离线实验中 DiffBid 表现最好；线上 A/B 相比 IQL 报告 GMV $+2.81\%$、ROI $+3.36\%$、成本 $-0.53\%$。
- 消融中，USCBEx-5K 的完整 DiffBid 为 2280.12；去条件后为 1812.64，去非马尔可夫 inverse dynamics 后为 2254.78。
- 推理复杂度随扩散步数 $K$ 线性增长。论文搜索 $K\in\{5,10,20,30,50\}$，并报告 GPU 下 DiffBid 约 0.2 秒/请求，IQL 约 0.07 秒/请求。

落地时应注意：

1. 条件是软控制，不替代预算、频控、合规的硬校验；
2. 生成质量依赖日志是否覆盖高质量、合规的轨迹；条件明显外推时可能不可靠；
3. inverse dynamics 依赖历史环境与日志动作的关系，竞价机制发生变化时需重新评估；
4. 论文是广告自动出价。迁移到打车券额或价格策略时，state、action、约束和最后执行公式都需要重新定义。

## 11. 最终 takeaway

理解 AIGB 的关键是区分：

$$
\text{状态 }s_t
\neq
\text{参数动作 }a_t
\neq
\text{单曝光出价 }b_i^*
\neq
\text{整段状态轨迹 }x_0(\tau).
$$

DiffBid 的核心不是“扩散模型直接给每条曝光出价”，而是：

> 先在目标与约束条件下生成未来状态的合理整体形状，再由历史依赖的 inverse dynamics 将最近的状态目标转为当前参数动作，最后由解析竞价公式执行到每一条曝光。
