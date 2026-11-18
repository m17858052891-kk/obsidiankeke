---
title: "【CIFT-25】Continual Causal Effect Estimation for Dataset Shifting Streams in Marketing Optimization"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2206333733374
cssclasses: ["strategy-body-note"]
---

# 【CIFT-25】Continual Causal Effect Estimation for Dataset Shifting Streams in Marketing Optimization

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2206333733374)

从分布变化的问题设定进入方法，再看模型对照与消融。论文结果作为方法参考，和本地业务验证分开理解。

**阅读定位**　[[#1. 背景概述|1. 背景概述]] · [[#2. 方法介绍|2. 方法介绍]] · [[#3. 实验分析|3. 实验分析]]

| **文章标题** | Continual Causal Effect Estimation for Dataset Shifting Streams in Marketing Optimization |
| --- | --- |
| **汇报者** | 张入月 |
| **主要解决的问题** | 持续性因果效应估计中的数据分布偏移 |
| **内容一句话总结** | ==针对营销优化中因果效应估计面临的数据集偏移问题，提出了基于先验知识蒸馏的因果推断增量学习框架--ICE-PKD，并通过实验和实际部署验证了其有效性== |
| **最最重要的贡献点** | 1）提出了multi-treatment因果建模方案，消除confounding bias--DRCFR <br>2）提出了增量学习策略适应数据漂移 <br>3）提出了新的multi-treatment场景下更精确的在线评估指标--RAS-AUCC |
| **小猪场景上的落地思考** | 如果业务数据存在以下现象，可以尝试该方案：随着时间的推移，特征分布变化大、建模目标如bcr变化大、模型效果变化大（如auc降低、ate error变大）。 |
| **会议/期刊 \[发表时间\]** | IEEE Big Data 已中稿并现场参会，正式期刊1月初发表 <br>[Big_data_2025.11.1_camera_ready.pdf](4b9ce1e66296e36c-Big_data_2025.11.1_camera_ready.pdf) |
| **踩坑记录/成功复用案例** | 目前为新客业务上主流量策略[技术分享：增量学习方法](https://cooper.didichuxing.com/knowledge/2199610335356/2203040915088) |

## 1. 背景概述

先前的研究在利用观测数据进行因果效应估计方面取得了显著进展，旨在解决反事实结果缺失和选择偏差带来的挑战。然而，在实际应用中，线上数据的分布会随时间不断变化，上述方法未能充分应对这一问题，导致模型性能随时间的推移迅速下降。

在在线营销场景中，数据来源受到新闻、节假日和天气状况等多重因素影响。**这些数据随时间的动态变化被称为数据偏移**。实践中通常关注两种类型的数据集偏移：

	- **协变量偏移covariate shift：**协变量分布随时间的变化，如用户画像分布随时间的变化，![](../../../%E9%99%84%E4%BB%B6/3a/3a59a26780b80938-%E6%88%AA%E5%B1%8F2025-12-31_15.25.24.png)

	- **概念漂移concept drift**：每个处理组中协变量与结果变量之间关系随时间的变化，

如用户画像对完单率的影响这一关系随时间的变化，![](32741088803f815a-截屏2025-12-31_15.25.58.png)

## 2. 方法介绍

DRCFR部分不过多赘述，主要介绍增量学习部分

***The Incremental Causal Effect Learning***

![](2fb51274c27768fd-截屏2025-12-31_15.29.24.png)

**1）*Initial Model Selection and Parameter Initialization:***

考虑到因果模型的复杂性，随机初始化参数会导致模型性能显著波动。为了避免这种情形，使用初始可用数据训练多次后，选择最优模型作为$$g_{\theta_{0}}^{t}(x)$$

在2个月数据上训练5次取最优，避免了参数初始化随机性导致的很差的模型效果。

***2) Loss Function Regularization via Knowledge Distillation:***

为了保证模型在增量训练过程中的泛化性，==借鉴了类增量方法LwF的思路。在概念漂移的假设下，重点关注模型在增量训练前后预测分布之间的差异。为量化这一差异，采用KL散度进行计算。具体而言，第k次增量训练中的知识蒸馏损失函数计算公式如下：==

![](158083adad1a84d6-截屏2025-12-31_16.17.01.png)

通过惩罚增量学习前后预测分布的差异，能够保留前期知识并且避免了灾难性遗忘。

***3) Replay Mechanism:***

==由于协变量偏移，仅依靠新数据计算分布差异以保留先验知识不可行，因为神经网络在面对分布外数据时往往表现不佳。受类增量方法iCaRL的启发，将知识蒸馏应用于一个回放样本集。==

==采用均匀采样的方法，从先前的数据集中保留固定数量==$$N_{save}$$==的样本作为历史训练数据的代表。较大的==$$N_{save}$$==能提升模型鲁棒性，但也会增加计算开销。在实践中，保留<u>初始可用样本量</u>约1%的数据作为回放样本是比较好的选择，==![](9271f6d9e117ed2c-截屏2025-12-31_16.55.04.png)

==在第k次增量训练中，使用包含==$$N_{k}$$==个样本的最新可用数据集==$$D_{k}$$==。用于先前训练的样本数量更新为：==![](3853c905c461a3ca-截屏2025-12-31_16.46.58.png)

	- 对于初次训练的模型，在个数为$$N_{0}$$的新增点集$$D_{0}$$中随机选取保存个数为$$N_{save}$$的点集$$D_{save}$$,并保存先前训练点个数$$\tilde{N_{0}}=N_{0}$$。

	- 对于增量训练模型，将新增点集$$D_{k}$$和保存的点集$$D_{save}$$合并作为训练点集。在个数为$$N_{k}$$的新增点集$$D_{k}$$中随机选取$$\frac{N_{k}}{N_{k}+\tilde{N_{k-1}}}*N_{save}$$个点，在上一次保存的训练点集$$D_{save}$$中随机选取$$\frac{\tilde{N_{k-1}}}{N_{k}+\tilde{N_{k-1}}}*N_{save}$$个点，一起保存为个数为$$N_{save}$$的点集，更新先前训练点个数$$\tilde{N_{k}}=\tilde{N_{k-1}}+N_{k}$$。

按照此方法，保证了每次保存数据时，历史数据被保留的概率都相等。

$$p(历史点被保存）= \frac{\tilde{N_{k-1}}/\tilde{N_{k-1}}}{N_{k}+\tilde{N_{k-1}}}= \frac{1}{N_{k}+\tilde{N_{k-1}}}$$

$$p(新增点被保存）=  \frac{N_{k}/{N_{k}}}{N_{k}+\tilde{N_{k-1}}}= \frac{1}{N_{k}+\tilde{N_{k-1}}}$$

***4) Proxy Teacher for Knowledge Distillation:***

概念漂移会导致用于知识蒸馏的教师模型在输出分布上出现固有差异。因此，教师模型可能对标签分布的估计产生偏差。若要求学生模型盲目模仿教师模型$$g_{\theta_{0}}^{t}(x)$$，会导致学生模型继承这些偏差，从而在第 k 次增量训练期间做出次优预测。

为缓解此问题，受 PTLoss 替代解决方案的启发，通过在 KL 散度计算中加入校正器 $$h_{\theta_{c}}(x)$$，将原始教师模型转化为代理教师模型。$$h_{\theta_{c}}(x)$$是一个神经网络,与 $$g_{\theta_{k-1}}(x)$$共享相同的输入协变量和输出维度。此外，其隐藏层的激活函数为 ReLU，输出层设置为 Tanh，同时采用 Xavier 初始化方法，确保$$h_{\theta_{c}}(x)$$在训练前的输出值保持较小。目的是减轻了训练初期对教师模型的大幅度扰动，有助于模型更快收敛。

通过这一修改，不仅模型参数$$\theta_{k}$$的更新会受到先前知识（即教师模型 $$g_{\theta_{k-1}}(x)$$）的影响，而且教师模型本身也会在第 k 次增量训练期间受到新数据的引导和校正。

![](d7d6e618371bc433-截屏2025-12-31_17.30.32.png)

***5) Overall Loss Function of ICE-PKD:*** 

第k次增量训练中ICE-PKD的总损失函数为：

![](5cf549693603e1d5-截屏2025-12-31_17.33.41.png)

![](e5534e22dc4a1e98-image.png)

## 3. 实验分析

为了证明ICE-PKD的有效性，比较了三种建模方案：

1. ICE-PKD:==选取在初始可用记录上表现最优的初始模型==$$g_{\theta_{0}}^{t}(x)$$==，随后使用数据集==$$D_{k}$$==对其进行增量更新==

2. DRCFR A:==采用滑动窗口（9周）训练 DR-CFR 模型--baseline==

3. DRCFR B:==仅使用最新可用数据集 Dk 训练 DR-CFR==

4. DRCFR C: ==则不更新模型==$$g_{\theta_{0}}^{t}(x)$$

新增指标：

AD: Average Difference，即不同时期上各指标的平均值

PRIO-10: The Percentage of Relative Improvement Over 10%，==用于衡量模型性能提升幅度超过10%的情况所占的比例。==

PRDU-5:The Percentage of Relative Deterioration Under 5%，==用于衡量模型性能劣化幅度低于5%的情况所占的比例。==

### 3.1 模型对比

==在合成数据集与线上数据集上，通过与其他策略进行对比来评估ICE-PKD的有效性。ICE-PKD在误差指标𝜖\_𝐴𝑇𝐸和*𝜖\_𝑃𝐸H𝐸*上实现了最大程度的降低，同时在排序指标QINI与RAS-AUCC上也取得了几乎最显著的提升。值得注意的是，它是唯一一个在所有指标上均超越基线方法（DR-CFR A）的策略==

![](17bbc3935453e3e6-截屏2025-12-31_17.48.37.png)

### 3.2 ablation study

- w/o PT: ICE-PKD without the proxy teacher

- w/o RM: ICE-PKD without the replay mechanism

- w/o KD: ICE-PKD without the knowledge distillation

在𝜖\_𝑃𝐸𝐻𝐸和RAS-AUCC指标上，ICE-PKD的PRIO-10与PRDU-5均达到了100%，同时取得了最低的𝜖\_𝑃𝐸𝐻𝐸平均值以及最高的RAS-AUCC平均值。这些结果证实了所提方法中整合所有组件的有效性。

![](2f93ea1e57d0eaf7-截屏2025-12-31_17.54.24.png)

## 4. 现场参会分享

pre:

[ICE-PKD论文展示ppt.pdf](dfcc6bd727786e9e-ICE-PKD论文展示ppt.pdf)

QA:

印度大哥的问题--解释covariate shift 和concept drift；在模型中怎么考虑这两种分布变化的？多久更新一次模型？

韩国小哥的问题--drcfr的框架中特征解耦的原理，有做过详细的特征分解分析吗？

chairman的问题--replay dataset如何获取？

其他相关topic及论文：

[Notes](https://cooper.didichuxing.com/knowledge/share/page/3gD5VJzOwGjU#页面《Notes》)

## 5. 业务应用

新客的代码实现和策略部署及业务收益

### 5.1 业务背景

见[技术分享：增量学习方法](https://cooper.didichuxing.com/knowledge/2199610335356/2203040915088)

新人业务存在的问题：特征分布变化大、大盘平均完单率变化大、模型效果变化大。

业务现状：已线上运行1年，稳定花费预算0.6pp

### 代码实现与部署

[模型训练与上线](https://cooper.didichuxing.com/knowledge/2199610335356/2203611265099#:~:text=%E9%85%8Ddufe%E6%A8%A1%E7%89%88%EF%BC%89-,%E6%A8%A1%E5%9E%8B%E8%AE%AD%E7%BB%83%E5%92%8C%E4%B8%8A%E7%BA%BF,-%E8%AE%AD%E7%BB%83%E4%BB%A3%E7%A0%81)

从实际使用的代码上看，主要使用的新数据对模型进行finetune，并未采取数据回放机制和校正器设计

### 业务收益

见[新客自动化实验报告](https://cooper.didichuxing.com/knowledge/2199610335356/2203441851837)【DS - 实验核心结论】
