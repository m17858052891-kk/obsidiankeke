---
title: "ACC_AR校准：历史方案、OOD与去isotonic记录"
type: "主题整理"
cssclasses: ["strategy-body-note"]
sources:
  - https://cooper.didichuxing.com/knowledge/2199610335356/2203737284503
  - https://cooper.didichuxing.com/knowledge/2199610335356/2203845646280
aliases:
  - "ACC_AR概率校准"
  - "AR模型去掉isotonic校准"
---

# ACC_AR校准：历史方案、OOD与去isotonic记录

区分单商家 AR 的校准与累积得到 ACC_AR 后的校准，再看数据迁移和离在线版本差异。

## 先读这些

- **累计概率校准**：历史方案比较了不重采样与负样本重采样 9 倍的结果，并记录 Spark 参数实现、查表近似及 3 位／4 位小数两版产物。
- **跨日期稳定性**：使用 2025-01-06～01-12 训练的校准器评估后续两周，原记录认为 isotonic 对分布变化敏感；春节影响是待验证解释。
- **去 isotonic 的范围**：2025-02-12 的记录希望去掉单商家 AR 的 isotonic，再在累计概率上校准。v3 原始输出与新部署 v4 还受 `level_type` 和模型参数差异影响，不能仅凭版本名称视为相同。
- **证据边界**：重新采用 v3 参数后，多渠道分布趋近，但 API 差异仍较大；后续累计校准使用 2025-02-05～02-11 数据，原文明确缺少新验证集。

**分节阅读**　[[#累计应答率校准与OOD|累计应答率校准与OOD]] · [[#去掉单商家isotonic的版本对齐|去掉单商家isotonic的版本对齐]]

## 累计应答率校准与OOD

**来源**：[ACC_AR概率校准](https://cooper.didichuxing.com/knowledge/2199610335356/2203737284503)

参考dsar的方案：<https://cooper.didichuxing.com/knowledge/2199610335356/2203717309378>

### 冒泡数据

2025-01-06 -- 2025-01-12发单的数据，量级约3382w，其中正样本占比约为0.94，

| 校准前 | 校准后 | 负样本重采样（9倍）之后未校准 | 负样本重采样（9倍）之后校准 |
| --- | --- | --- | --- |
| ![](5c9b4418ea1f24ed-2732616451.png) | ![](bfc3f53ab65011bd-image.png) | ![](62c16f32601c063e-image.png) | ![](b514a7d780b0e6a9-image.png) |

绘图代码
> [!example]- Python 实现细节（74 行）
> ```Python
> def plot_iso_fig(data):
>     num_bins = 100
>     total = data.shape[0]
>     bins = np.linspace(0, 1, num_bins + 1)  # 创建 10 个等宽区间
>     bin_indices = np.digitize(data[:, 1], bins, right=True)  # 获取每个数值的分桶索引
>     bin_indices = bin_indices.squeeze()
>
>     bin_centers = (bins[:-1] + bins[1:]) / 2  # 确保 bin_centers 覆盖所有分桶
>     proportions = []
>     bin_totals = []  # 每个桶的总样本数
>     label_1_totals = []  # 每个桶中 label=1 的样本数
>     label_0_totals = []  # 每个桶中 label=0 的样本数
>
>     for b in range(1, num_bins + 1):
>         bin_data = data[bin_indices == b] # 获取属于当前桶的数据
>
>         if len(bin_data) > 0:
>             proportions.append(np.mean(bin_data[:, 0]))  # 计算桶中 label=1 的比例
>             bin_totals.append(len(bin_data)/total)  # 总样本数
>             label_1_totals.append(np.sum(bin_data[:, 0] == 1)/total)  # label=1 的样本频率
>             label_0_totals.append(np.sum(bin_data[:, 0] == 0)/total)  # label=0 的样本频率
>         else:
>             proportions.append(0)
>             bin_totals.append(0)
>             label_1_totals.append(0)
>             label_0_totals.append(0)
>
>     # 3. 绘图
>     fig, axes = plt.subplots(2, 2, figsize=(14, 14), gridspec_kw={'width_ratios': [1, 1]})
>
>     # 左上图：校准曲线
>     x = np.linspace(0, 1, num_bins)
>     axes[0, 0].plot(x, x, label='y=x', linestyle='--', color='gray')
>     axes[0, 0].scatter(bin_centers, proportions, label='Proportion of 1s', marker='o')
>     axes[0, 0].set_xlabel('Predicted Probability')
>     axes[0, 0].set_ylabel('Proportion')
>     axes[0, 0].set_title('Calibration Curve')
>     axes[0, 0].legend()
>     axes[0, 0].grid()
>
>     # 右上图：分桶样本概率分布
>     axes[0, 1].bar(bin_centers, bin_totals, width=1 / num_bins, color='skyblue', edgecolor='black', alpha=0.7)
>     axes[0, 1].set_xlabel('Predicted Probability')
>     axes[0, 1].set_ylabel('Proportion')
>     axes[0, 1].set_title('Bucket Sample Probability')
>     axes[0, 1].grid(axis='y', linestyle='--', alpha=0.7)
>
>     # 左下图：label=1 样本分布
>     axes[1, 0].bar(bin_centers, label_1_totals, width=1 / num_bins, color='green', edgecolor='black', alpha=0.7)
>     axes[1, 0].set_xlabel('Predicted Probability')
>     axes[1, 0].set_ylabel('Proportion')
>
>     # yticks = np.arange(0,0.03,0.005)
>     # axes[1, 0].set_yticks(yticks)
>     # 进行上述操作主要是为了坐标轴对齐
>     axes[1, 0].set_title('Bucket Proportion for Label=1')
>     axes[1, 0].grid(axis='y', linestyle='--', alpha=0.7)
>
>     # 右下图：label=0 样本分布
>     axes[1, 1].bar(bin_centers, label_0_totals, width=1 / num_bins, color='orange', edgecolor='black', alpha=0.7)
>     axes[1, 1].set_xlabel('Predicted Probability')
>     axes[1, 1].set_ylabel('Proportion')
>     # yticks_2 = np.arange(0,0.07,0.01)
>     # axes[1, 1].set_yticks(yticks_2)
>     # 进行上述操作主要是为了坐标轴对齐
>     axes[1, 1].set_title('Bucket Proportion for Label=0')
>     axes[1, 1].grid(axis='y', linestyle='--', alpha=0.7)
>
>     # 调整布局并显示
>     plt.tight_layout()
>     plt.show()
>
> data = np.concatenate([label_list, predict_list[:, None]], axis=1)
> plot_iso_fig(data)
> ```


关于acc_ar小于0.2的部分，计算了下占比，

![](b3a180829354eb50-image.png)

### 在spark中实现

isotonic_regression模型保存的参数及含义

![](2355a66b33c88b25-image.png)

- 方案一：基于保存的参数实现isotonic_regression的方法，increasing\_=True的条件（当前场景）

> [!example]- Python 实现细节（34 行）
> ```Python
> import numpy as np
> from sklearn.isotonic import IsotonicRegression
>
> # 假设你已经训练了一个 IsotonicRegression 模型
> # 并保存了以下参数
> X_thresholds_ = np.array([0.0, 1.0, 2.0, 3.0, 4.0])
> y_thresholds_ = np.array([0.1, 0.3, 0.5, 0.7, 0.9])
> increasing_ = True
>
> # 定义一个函数，用于预测新数据的值
> def predict_isotonic(X_new, X_thresholds_, y_thresholds_, increasing_):
>     if increasing_:
>         # 找到 X_new 所在的区间
>         idx = np.searchsorted(X_thresholds_, X_new, side='right') - 1
>         if idx < 0:
>             return y_thresholds_[0]  # 如果 X_new 小于最小的 X_thresholds_，返回最小的 y_thresholds_
>         if idx >= len(X_thresholds_) - 1:
>             return y_thresholds_[-1]  # 如果 X_new 大于最大的 X_thresholds_，返回最大的 y_thresholds_
>
>         # 线性插值
>         x1, x2 = X_thresholds_[idx], X_thresholds_[idx + 1]
>         y1, y2 = y_thresholds_[idx], y_thresholds_[idx + 1]
>         y_new = y1 + (y2 - y1) * (X_new - x1) / (x2 - x1)
>         return y_new
>     else:
>         # 如果是递减函数，可以类似处理
>         pass
>
> # 新数据点
> X_new = 2.5
>
> # 预测新数据点的值
> y_new = predict_isotonic(X_new, X_thresholds_, y_thresholds_, increasing_)
> print(f"Predicted value for X_new = {X_new}: y_new = {y_new}")
> ```


- 方案二：考虑到sql实现类似np.searchsorted的逻辑有些困难，所以不用isotonic_regression的计算逻辑，而是对acc_ar取近似，保留几位小数之后遍历所有可能解并落表，线上直接查表获得结果。保留4位小数，生成的临时查询表为kflower_strategy_dev.acc_ar_isotonic_calibrate，其中的with_resample字段表示在训练isotonic regression时是否有重采样，1有0没有。

	- 2025-02-07：保留4位小数，重采样、未重采样都有

	- 2025-02-08：保留3位小数，只有未重采样

### OOD问题

**结论：**

- 不论是否重采样，isotonic regression的校准方式对ood问题比较敏感，在线使用需要定期更新

- 2025-01-24 -- 2025-01-30的数据波动较大，可能受到春节的影响，需要在节后时间段重新测试

【训练测试都不重采样】

取2025-01-17 -- 2025-01-23的数据，量级约3516w，用2025-01-06 -- 2025-01-12产出的校准模型校准，训练及测试都未重采样

| 校准前 | 校准后 |
| --- | --- |
| ![](a66aac935c661565-image.png) | ![](6df19ae2f1593549-image.png) |

取2025-01-24 -- 2025-01-30的数据，量级约2583w，用2025-01-06 -- 2025-01-12产出的校准模型校准，训练及测试都未重采样

| 校准前 | 校准后 |
| --- | --- |
| ![](11858285928ae93c-image.png) | ![](cf4790927b854678-image.png) |

【训练测试都重采样】

取2025-01-17 -- 2025-01-23的数据，量级约3516w，用2025-01-06 -- 2025-01-12产出的校准模型校准，同样对负样本重采样9倍

| 校准前 | 校准后 |
| --- | --- |
| ![](5b7b11b60434a8ac-image.png) | ![](8baa8c3e68067794-image.png) |

取2025-01-24 -- 2025-01-30的数据，量级约2583w，用2025-01-06 -- 2025-01-12产出的校准模型校准，同样对负样本采样9倍

| 校准前 | 校准后 |
| --- | --- |
| ![](ac796dd2d21cfc40-image.png) | ![](cf4d4eed93826dca-image.png) |

### 线上使用版本号

kflower_strategy_dev.acc_ar_isotonic_calibrate

==当前线上ar模型为==**ar_model_general_data_review_v1**==和==**ar_model_general_data_review_dd_v1**两个版本模型

校准对照版本号：version = v1

数据日期：2025-01-13 -- 2025-01-19

## 去掉单商家isotonic的版本对齐

**来源**：[AR模型去掉isotonic校准](https://cooper.didichuxing.com/knowledge/2199610335356/2203845646280)

**2025-02-12**

**核心目标：**期望用v3版本没有isotonic的模型结果，线上调用时不能直接从v3版本模型结果中直接拿到没有isotonic的结果，所以需要重新部署v4版本模型，使得v4结果尽量和v3没有isotonic的结果一致。

**【离在线差异】**

由于上线时间问题，这里离线规划求解用的ar模型（v3，模型原始的预测值，没有isotonic的结果）和在线的ar模型(v4，训练时直接去掉isotonic的过程)有一些gap，差异在于：

- 训练数据相同，但是v4版本去掉了level_type这个特征

- v3版本加上了isotonic regression，v4去掉了这个过程

- 离线规划求解用的v3没有isotonic的结果（isotonic_feature），即模型原始的预测值，然后计算出acc_ar之后，再做isotonic，在线用v4的模型预测结果(probabilities_value.values\[1\])，**假设是v3没有isotonic之前的结果和v4的模型预测结果差别不大**。

v3的isotonic_feature和v4probabilities_value.values\[1\]差异比较：

【**数据分布差异**】

v4版本的数据分布反倒和v3版本isotonci校准之后的数据分布类似，分析数据分布差异是模型参数导致的，所以用v3版本模型参数重新训练模型。

| | zy | hh | api | dd |
| --- | --- | --- | --- | --- |
| v3 | ![](01eaa7c2d2832e24-image.png) | ![](6a0da40160df1b33-image.png) | ![](d429ded5f30cf199-image.png) | ![](c04631f4f4470b43-image.png) |
| v4 | ![](7f9793bdd273d4b8-image.png) | ![](fa724328fda206db-image.png) | ![](f69ea8739359eed4-image.png) | ![](e237be9488ccfb0f-image.png) |
| v3的参数、特征去掉level_type | ![](64c9e6c3982841c2-image.png) | ![](0dc4e8720ac3aaf5-image.png) | ![](880516db279748b0-image.png) | ![](82587c935d3ba22b-image.png) |

v3的参数、特征去掉level_type重新训练一版本，输出分布和v3没有isotonic情况类似。重新用v3版本参数训练之后，输出分布和之前变得相似，差异不大（api差异较大一点）。

v3的isotonic_feature保留三位小数分桶，对abs(diff)的均值结果倒序排列如下

| **isotonic_feature** | **diff_avg** |
| --- | --- |
| 0.487 | 0.139892741 |
| 0.478 | 0.136980673 |
| 0.49 | 0.136843388 |
| 0.546 | 0.1320579 |
| 0.469 | 0.13171349 |
| 0.48 | 0.13088479 |
| 0.622 | 0.129799118 |
| 0.493 | 0.12967455 |
| 0.454 | 0.129555885 |
| 0.47 | 0.129331121 |
| 0.506 | 0.128832743 |
| 0.501 | 0.12855809 |
| 0.495 | 0.127353706 |
| 0.492 | 0.127153109 |

单个trace的最大diff约为0.44。

【**acc_ar校准**】

v3没有isotocin校准，计算acc_ar之后再校准，校准**没有进行负样本重采样**：

数据时间：2025-02-05 -- 2025-02-11

| 校准前 | |
| --- | --- |
| ![](b4486ceec1002a23-image.png) | ![](e0ace8d74bf67eae-image.png) |

暂时没有验证，因为没有新的数据作为验证集。

看起来这版本有两个优点在于：

- 校准之前的数据跟对角线贴合很多，而且曲线接近sigmoid的反函数形状

- 校准之后的数据范围要广一点，不会像之前一样被压缩到一个很小的范围内，现在0会映射到0.32左右的值
