---
title: "模型AUC显著性报告"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2210040724878
---

# 模型AUC显著性报告

# RankMixer vs PEPNet+Bilinear

在本次固定验证集、10 个配对随机种子实验中，PEPNet+Bilinear 的完单率 AUC 显著优于 RankMixer。

- PEPNet+Bilinear auc_finish：0.772690 ± 0.000129。

- RankMixer auc_finish：0.766710 ± 0.000273。

- 平均差值 RankMixer − PEPNet+Bilinear 为 −0.005980，即 RankMixer 的绝对 AUC 低约 59.8 bp。

- 10/10 个随机种子的差值均为负，方向完全一致。

- Pepnet的AUC标准差为 **σ\_AUC = 0.0001287 ≈ 1.29 bp**

- 双侧配对 t 检验：t(9) = −64.400847，p = 2.6485 × 10⁻¹³。

- 检验结果满足 α = 0.05，拒绝“两个模型平均完单率无差异”的原假设，差异方向为 RankMixer 更差。

- 按约定使用基线模型标准差计算工程阈值，**2σ\_total = 0.000257；平均差值绝对值是该阈值的 23.24 倍。**

## 实验与指标说明

| 项目 <br> | 内容 <br> |
| --- | --- |
| 对比模型 <br> | PEPNet+Bilinear、RankMixer <br> |
| 主要评估指标 <br> | auc_finish，完单率 AUC <br> |
| 样本空间 <br> | 全部验证集样本 <br> |
| 随机种子 <br> | 2024—2033，共 10 个随机种子 <br> |
| 配对方式 <br> | 两个模型使用相同的 seed 进行配对比较 <br> |
| 标准差 <br> | 10 次独立训练结果的样本标准差，分母为 n−1 <br> |
| 置信区间 <br> | 基于 t(9) = 2.262157 的双侧 95% 置信区间 <br> |
| 显著性检验 <br> | 双侧配对 t 检验 <br> |
| 显著性水平 <br> | α = 0.05 <br> |
| 工程判据 <br> | 平均差值是否超过 2σ\_total <br> |

两个模型的配对差值定义为：

$$\Delta\mathrm{AUC}_i  =  \mathrm{AUC}_{\mathrm{RankMixer},i}  -  \mathrm{AUC}_{\mathrm{PEPNet+Bilinear},i}$$

如果 ΔAUC 大于 0，表示 RankMixer 更好；如果 ΔAUC 小于 0，表示 RankMixer 更差。

## 每个随机种子的配对结果

| Seed <br> | PEPNet+Bilinear <br> | RankMixer <br> | ΔAUC <br> | ΔAUC（bp） <br> |
| ---: | ---: | ---: | ---: | ---: |
| 2024 <br> | 0.7729 <br> | 0.7667 <br> | −0.0062 <br> | −62 <br> |
| 2025 <br> | 0.7726 <br> | 0.7670 <br> | −0.0056 <br> | −56 <br> |
| 2026 <br> | 0.7728 <br> | 0.7662 <br> | −0.0066 <br> | −66 <br> |
| 2027 <br> | 0.7728 <br> | 0.7668 <br> | −0.0060 <br> | −60 <br> |
| 2028 <br> | 0.7726 <br> | 0.7669 <br> | −0.0057 <br> | −57 <br> |
| 2029 <br> | 0.7725 <br> | 0.7663 <br> | −0.0062 <br> | −62 <br> |
| 2030 <br> | 0.7728 <br> | 0.7670 <br> | −0.0058 <br> | −58 <br> |
| 2031 <br> | 0.7726 <br> | 0.7666 <br> | −0.0060 <br> | −60 <br> |
| 2032 <br> | 0.7727 <br> | 0.7668 <br> | −0.0059 <br> | −59 <br> |
| 2033 <br> | 0.7726 <br> | 0.7668 <br> | −0.0058 <br> | −58 <br> |

RankMixer 在全部 10 个随机种子上的 auc_finish 均低于 PEPNet+Bilinear，差异方向完全一致。

**汇总统计：**

| 对象 <br> | 均值 <br> | 样本标准差 <br> | 95% 置信区间 <br> |
| --- | ---: | ---: | ---: |
| PEPNet+Bilinear <br> | 0.772690 <br> | 0.000129 <br> | \[0.772598, 0.772782\] <br> |
| RankMixer <br> | 0.766710 <br> | 0.000273 <br> | \[0.766515, 0.766905\] <br> |
| ΔAUC <br> | −0.005980 <br> | 0.000294 <br> | \[−0.006190, −0.005770\] <br> |

该置信区间完全位于 0 以下，说明在本次实验协议下，RankMixer 的平均 auc_finish 下降无法由观测到的随机初始化波动解释。

## 双侧配对 t 检验

由于两个模型使用相同的 10 个随机种子，因此采用双侧配对 t 检验。

对每一个随机种子的配对差值进行检验：

$$d_i  =  \mathrm{AUC}_{\mathrm{RankMixer},i}  -  \mathrm{AUC}_{\mathrm{PEPNet+Bilinear},i}$$

$$H_0:\mu_d=0$$

$$H_1:\mu_d\neq 0$$

检验统计量为：

$$t  =  \frac{\overline{d}}  {s_d/\sqrt{n}}$$

本次实验得到：

- n = 10

- t = −64.400847

- 自由度 df = 9

- 双侧 p = 2.6485 × 10⁻¹³

由于：

$$p < 0.05$$

因此，在 α = 0.05 的显著性水平下，拒绝“两个模型平均完单率无差异”的原假设。

## 2σ\_total 工程判据

按照约定，总体波动定义为：

$$\sigma_{\mathrm{total}}  =  \sqrt{  \sigma_{\mathrm{data}}^2  +  \sigma_{\mathrm{model}}^2  }$$

本次实验使用固定验证集，因此暂时设定：

$$\sigma_{\mathrm{data}}=0$$

使用对照组 PEPNet+Bilinear 的多 seed 样本标准差作为模型波动：

$$\sigma_{\mathrm{model}}  =  0.000128668$$

因此：

$$\sigma_{\mathrm{total}}  =  \sqrt{  0^2+0.000128668^2  }  =  0.000128668$$

对应的 2σ 工程阈值为：

$$2\sigma_{\mathrm{total}}  =  2\times 0.000128668  =  0.000257337$$

而：

$$\overline{\Delta\mathrm{AUC}}  =  -0.005980$$

平均差值绝对值与 2σ 工程阈值的比值为：

$$\frac{  \left|\overline{\Delta\mathrm{AUC}}\right|  }{  2\sigma_{\mathrm{total}}  }  =  \frac{0.005980}{0.000257337}  =  23.24$$

因此：

- 正向收益判据 $$\overline{\Delta\mathrm{AUC}}>2\sigma_{\mathrm{total}}$$：不满足。

- 差异幅度判据 $$\left|\overline{\Delta\mathrm{AUC}}\right|>2\sigma_{\mathrm{total}}$$：满足。

- 平均差值绝对值约为 2σ 工程阈值的 23.24 倍。

- RankMixer 出现了工程上显著的负向退化。

## 结论

在固定验证集和 10 个配对随机种子的实验条件下：

1. PEPNet+Bilinear 的平均 auc_finish 为 0.772690，RankMixer 的平均 auc_finish 为 0.766710。

2. RankMixer 相对于 PEPNet+Bilinear 平均下降 0.005980，即下降约 59.8 bp。

3. 10/10 个随机种子的差值均为负，结果方向完全一致。

4. ΔAUC 的 95% 置信区间为 \[−0.006190, −0.005770\]，完全位于 0 以下。

5. 双侧配对 t 检验结果为 t(9) = −64.400847，p = 2.6485 × 10⁻¹³，差异具有统计显著性。

6. 平均差值绝对值约为 2σ 工程阈值的 23.24 倍，差异同时具有工程显著性。

综上，在本次实验设置下，RankMixer 的完单率 AUC 显著低于 PEPNet+Bilinear。

## 
