# 为什么要用 Z-score 标准化与温度系数

## 30 秒回答

不同补贴档位的 uplift score 均值、方差和长尾不同，直接把原始 score 输入 Corr/Pairwise，会让方差大、极值多的档位获得更强梯度，排序 loss 实际上先优化了尺度而不是排序。我们只在 rank loss 内按 treatment 做 Z-score，再使用 $\tanh(z/T)$ 压缩极端值。Z-score 解决组间尺度与中心漂移；Tanh 解决长尾主导；温度 $T$ 控制压缩强度。H2 取 T=2，在区分度和稳健性间折中；最终概率输出不被校准改写。

## 1. 原始 score 的两个问题

对第 $m$ 档 $q=\hat\mu_m-\hat\mu_{100}$，深档位、样本量差异、head 学习进度与伪标签方差都可能造成：

- 某档 score 均值整体偏移；
- 某档方差明显更大；
- 少量极端 score 形成长尾；
- Corr/Pairwise 的梯度被某一档或几个样本主导。

这并不说明该档真实 uplift 更高。若不处理，模型可能通过拉大 score 尺度降低 rank loss，甚至放大 treatment-ratio 风险。

## 2. 按 treatment 的 Z-score

在每个 treatment group 内计算：

$$
z_i=\frac{q_i-\mu_m}{\sigma_m+\epsilon}
$$

必须按 treatment 而非全样本统计：不同档位本来拥有不同基线与有效样本比例，混在一起标准化会把档位间差异重新注入 loss。batch statistics 可跟随当前训练分布，但 batch 过小、组内方差接近 0 时应跳过该 group 或使用稳健统计/滑动统计。

当前方案使用 `detach_stats=true`：

$$
z_i=\frac{q_i-\mathrm{stopgrad}(\mu_m)}{\mathrm{stopgrad}(\sigma_m)+\epsilon}
$$

这样均值与方差仅是校准常数，不让模型通过调整 batch 统计量改变梯度路径。否则 gradient 会耦合到全 batch 的 mean/std，模型可能“操纵统计量”而非改善样本相对顺序。

## 3. 为什么还需要 Tanh

Z-score 后极端点仍可能有很大的绝对 z 值。使用：

$$
\tilde q_i=\tanh(z_i/T)
$$

把极端值压到 $(-1,1)$，使少量异常样本不会无限主导 Corr/Pairwise 的梯度，同时保留中心区间的相对顺序。

## 4. 温度到底控制什么

温度在分母：

- **T 较大**：$z/T$ 较小，Tanh 更接近线性，区分度更平缓、压尾较弱；
- **T 较小**：更快进入 $\pm1$ 饱和，极端值压得更强，但大量中间样本会被压扁，梯度和细粒度排序信息下降；
- **T=2**：当前 H2 的实验证据表明是折中点；T=3 更保守，T=1 更锐化但未在主指标上超过 H2。

这里的 temperature 不等同于 pairwise logistic 的 `rank_temperature`，也不等同于 matching softmax 的 `match_temperature`：三者分别调控 score calibration、pair 排序曲线和邻居权重集中度。

## 5. 为什么不直接校准最终 uplift

最终 $\hat\mu_m$ 是具有业务含义的响应概率，$\hat\tau_m$ 是概率差。直接对线上输出做 batch Z-score/Tanh 会破坏跨批、跨天的解释性和阈值含义。这里的校准仅是训练时 rank loss 的数值预条件化：

$$
\mathcal L_{rank}=\mathcal L_{rank}(\tilde q),\qquad \text{serve }\hat\mu_m,\hat\tau_m
$$

因此它改善训练稳定性，不应被表述为概率校准。若需要线上概率校准，应另用独立验证集开展 Platt/isotonic 等概率校准并验证因果指标。

## 6. 实践检查清单

- 每个 treatment group 是否满足最小样本数；
- 是否记录原始 score、z-score、Tanh 后 score 的分布；
- 是否检查某档 sigma 接近零、NaN 和饱和比例；
- T、Corr 权重和 soft-unfreeze 是否联合调参并仅用 validation 选型；
- 校准后 AUCC 改善是否伴随 ratio 恶化；
- 是否确认 serving 没有意外使用 batch calibration 后分数。
