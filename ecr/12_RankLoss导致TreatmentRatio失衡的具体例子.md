# 光加入 Rank Loss 导致的问题：实际观察到的 Treatment Ratio 失衡

可以。核心问题是：强 rank loss 不只会学习“谁更可能有增量”，也会学习任何能让伪标签排序更好的捷径；如果它间接识别出了 treatment/control 身份，排序头部的人群构成就会偏离原始随机分流比例。

对某个补贴档位与 100 档 control 的有效评估样本，先以实际样本量计算全局 treatment 比例：

$$
p_t=\frac{N_t}{N_t+N_c}
$$

排序后，对任一累计 Top-$q$ 人群，treatment ratio 定义为：

$$
r(q)=\frac{N_t(\text{Top-}q)}
{N_t(\text{Top-}q)+N_c(\text{Top-}q)}
$$

正常情况下，若 score 没有学到分组身份，任意足够大的 Top 人群中的 ratio 应围绕该评估切片的全局比例 $p_t$ 波动。

---

### 先看 rank loss 本来想把谁排前面

对某个 treatment $t$ 和 control $c$，使用 $2y-1$ 的 IPW 伪标签时：

| 实际组别与结果 | 伪标签方向 | 理想排序含义 |
|---|---:|---|
| treatment + call | 正 | 更靠前 |
| treatment + no-call | 负 | 更靠后 |
| control + call | 负 | 更靠后 |
| control + no-call | 正 | 更靠前 |

这四类是**带噪的总体证据**，不是某个用户真实 uplift 的直接标签。

Corr Rank Loss 的目标是让预测分数和这些伪标签整体正相关。若特征干净，模型应该学到：哪些用户的历史、上下文和候选匹配模式，像“会被券拉动的人”。

---

## 实际观察到的现象：高分人群的 control 占比异常偏高

当前实验中观察到的是：treatment-ratio 曲线在前半段快速下降。这表示随着排序从最高分人群向后展开，累计人群中的 treatment 占比持续低于该评估切片的全局基线 $p_t$；换言之，高分区域的 **control 样本异常偏多**。

这对应的真实结论是：

```text
强 rank loss 后，score 与实验分组身份产生了不应有的关联；
模型的高分人群偏向 control，而非 treatment/control 仍大致均衡。
```

仅根据 treatment-ratio 曲线，不能把原因直接下结论为“所有 control-no-call 都被排在前面”，也不能给出未记录的具体人数。要确认是哪一类样本被过度抬高，需要在各个 score bucket 中继续拆解四格样本：treatment-call、treatment-no-call、control-call、control-no-call。

## 为什么强 Rank Loss 可能造成这一现象

强 Corr Rank Loss 可能放大任何与伪标签相关的结构；当数据存在和分组身份相关的痕迹时，模型就可能利用这些痕迹，而不是只学习真实的 uplift 异质性。需要重点排查：

- 某个日志字段的填充值在 control 与 treatment 不一致；
- 过滤或曝光链路让某类用户在 control 侧保留得更多；
- 高频用户/重复订单在某一侧的分布明显不同；
- 处理前后时间截点没切干净，间接泄漏了组别。

在当前的 $2y-1$ 伪标签中，`control + no-call` 是正向信号。因此，若模型能从某些特征间接识别 control 身份，就**可能**走如下捷径：

```text
真正想学：
“候选相关、近期有兴趣、但基础转化不高的人” → 高分

实际学到：
“更像 control 样本的人” → 高分
```

这里的“可能”是机制解释，不是已验证的四格归因结果。当前已确认的只有：前半段高分人群 control 偏多，treatment-ratio 明显低于全局基线。

---

## 为什么只加 rank loss 更容易发生

原始 CFR 的 factual BCE 主要约束“当前实际档位下的 call 概率”，而且表征平衡项会限制一部分组间差异。

强加 Corr/Pairwise 后：

$$
\mathcal L
=
\mathcal L_{\text{base}}
+
\lambda_{\text{corr}}\mathcal L_{\text{corr}}
+
\lambda_{\text{pair}}\mathcal L_{\text{pair}}
$$

若 $\lambda_{\text{corr}}$ 过大，Corr 的稠密梯度会推动 shared bottom 重组表征。只要“分组痕迹”比真实 uplift 特征更容易拟合，它就可能优先利用这个捷径。于是：

```text
AUCC 上升
≠
真正的可干预人群排得更准
```

而 treatment-ratio 曲线正是在检查：模型 Top 人群是否仍保留 treatment/control 的可比较性。当前曲线前半段迅速下降，正说明这一可比较性已经受到风险提示。

---

## H2 为什么能缓解

H2 的逻辑不是取消 rank loss，而是限制它改坏底座：

1. Stage 1 先用 factual/base loss 得到较稳定的 response anchor；
2. Stage 2 保留 factual loss，不让模型完全只服务于排序伪标签；
3. 对每个 treatment 的 score 做 Z-score + Tanh，避免个别档位尺度和极端值主导梯度；
4. Corr 为主、Pairwise 为辅；
5. 先只训练 head，再以很小学习率软解冻 shared bottom。

所以最终想实现的是：

```text
真实可拉动人群 → 排前面
而不是
“更像 treatment/control 某一组的人” → 排前面
```

需要强调：ratio 平稳不能证明模型一定正确；ratio 明显失衡也不能单独证明模型无效。但当“AUCC 大涨”和“ratio 明显偏离”同时出现时，应优先排查 rank loss 是否学到了分组/曝光捷径，而不是直接选择 AUCC 最高的模型。
