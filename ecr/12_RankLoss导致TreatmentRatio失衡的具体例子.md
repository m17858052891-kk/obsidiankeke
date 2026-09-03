# 光加入 Rank Loss 导致的问题：Treatment Ratio 失衡的具体例子

可以。核心问题是：强 rank loss 不只会学习“谁更可能有增量”，也会学习任何能让伪标签排序更好的捷径；如果它间接识别出了 treatment/control 身份，排序头部的人群构成就会偏离原始随机分流比例。

假设某个补贴档位与 100 档 control 的实验样本原本各 1,000 人：

\[
p_t=\frac{1000}{1000+1000}=0.5
\]

排序后取 Top 10%（200 人），treatment ratio 定义为：

\[
r(10\%)=\frac{N_t(\text{Top 10\%})}
{N_t(\text{Top 10\%})+N_c(\text{Top 10\%})}
\]

正常情况下，若 score 没有学到分组身份，Top 10% 约应有 100 个 treatment、100 个 control，即 ratio 接近 0.5。

---

### 先看 rank loss 本来想把谁排前面

对某个 treatment \(t\) 和 control \(c\)，使用 \(2y-1\) 的 IPW 伪标签时：

| 实际组别与结果 | 伪标签方向 | 理想排序含义 |
|---|---:|---|
| treatment + call | 正 | 更靠前 |
| treatment + no-call | 负 | 更靠后 |
| control + call | 负 | 更靠后 |
| control + no-call | 正 | 更靠前 |

这四类是**带噪的总体证据**，不是某个用户真实 uplift 的直接标签。

Corr Rank Loss 的目标是让预测分数和这些伪标签整体正相关。若特征干净，模型应该学到：哪些用户的历史、上下文和候选匹配模式，像“会被券拉动的人”。

---

## 具体例子一：Top 人群被 control-no-call 挤占

假设训练数据中存在一个不该进入模型、却和分组身份高度相关的特征，例如：

- 某个日志字段的填充值在 control 与 treatment 不一致；
- 过滤或曝光链路让某类用户在 control 侧保留得更多；
- 高频用户/重复订单在某一侧的分布明显不同；
- 处理前后时间截点没切干净，间接泄漏了组别。

强 Corr Loss 发现：这个特征可以快速区分 control 样本。而在伪标签中，`control + no-call` 恰好是正向信号，于是它走了捷径：

```text
真正想学：
“候选相关、近期有兴趣、但基础转化不高的人” → 高分

实际学到：
“更像 control 样本的人” → 高分
```

假设 Top 10% 最后变成：

| 人群 | 数量 |
|---|---:|
| treatment | 40 |
| control | 160 |
| 合计 | 200 |

那么：

\[
r(10\%)=\frac{40}{200}=0.2
\]

全局基线是 0.5，头部却是 0.2，说明高分人群中 control 异常多。若按二项近似，200 个样本在 0.5 分流下的标准误约为：

\[
SE=\sqrt{\frac{0.5(1-0.5)}{200}}\approx0.035
\]

0.2 距离 0.5 约 8.6 个标准误，基本不能再当作随机波动解释。

这时模型表面上可能仍有不错的 Corr/AUCC，因为它很擅长把 `control-no-call` 这类正伪标签排前；但这并不是一个线上可用的 targeting 规则——线上待打分用户还没有被分进 control 或 treatment，模型不应该依赖这个身份。

---

## 具体例子二：Top 人群被 treatment-call 挤占

也可能是反方向。若泄漏特征让模型更容易识别 treatment 身份，而 treatment 侧的 call 又更容易得到高正伪标签，强 rank loss 可能学成：

```text
“像 treatment 样本” → 高分
```

于是 Top 10% 变为：

| 人群 | 数量 |
|---|---:|
| treatment | 165 |
| control | 35 |
| 合计 | 200 |

\[
r(10\%)=\frac{165}{200}=0.825
\]

同样明显偏离 0.5。它不一定表现为“红线下凸”，也可能上凸；重点不是方向，而是 score 与实验分组身份产生了不该有的系统性关联。

---

## 为什么只加 rank loss 更容易发生

原始 CFR 的 factual BCE 主要约束“当前实际档位下的 call 概率”，而且表征平衡项会限制一部分组间差异。

强加 Corr/Pairwise 后：

\[
\mathcal L
=
\mathcal L_{\text{base}}
+
\lambda_{\text{corr}}\mathcal L_{\text{corr}}
+
\lambda_{\text{pair}}\mathcal L_{\text{pair}}
\]

若 \(\lambda_{\text{corr}}\) 过大，Corr 的稠密梯度会推动 shared bottom 重组表征。只要“分组痕迹”比真实 uplift 特征更容易拟合，它就可能优先利用这个捷径。于是：

```text
AUCC 上升
≠
真正的可干预人群排得更准
```

而 treatment-ratio 曲线正是在检查：模型 Top 人群是否仍保留 treatment/control 的可比较性。

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

需要强调：ratio 平稳不能证明模型一定正确；ratio 明显失衡也不能单独证明模型无效。但当“AUCC 大涨”和“ratio 明显偏离”同时出现时，应优先怀疑 rank loss 学到了分组/曝光捷径，而不是直接选择 AUCC 最高的模型。
