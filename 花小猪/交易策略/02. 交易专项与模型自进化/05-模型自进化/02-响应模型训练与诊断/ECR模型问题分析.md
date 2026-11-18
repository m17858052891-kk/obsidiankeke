---
title: "ECR模型问题分析"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2204641704982
cssclasses: ["strategy-body-note"]
---

# ECR模型问题分析

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2204641704982)

分别看 reweight、评估可复现性和 ATE 约束的问题。实验表和代码保留在相应问题下，避免把不同对照混读。

**阅读定位**　[[#Reweight问题分析|Reweight问题分析]] · [[#MTAUCC可复现性|MTAUCC可复现性]] · [[#Loss增加ATE约束|Loss增加ATE约束]]

**接手的ECR训练代码之前遇到的问题**

- 随机性：当固定超参数、全局的随机种子之后，训练模型多次，用auc作为评估指标，差异较大（最好的约0.76，最差的约0.70）

- 训练不稳定：训练时在有些参数下loss会变为nan，有些参数可以正常训练；也会出现训练初期正常，训练过程中变为nan的情况

- 差异性小：各个treatment下的预测值比较接近，数值差的绝对值小于1e-10

原来的代码解决方案：

- 随机性：未解决，通过网格搜参，找到多组能正常训练的参数，比较这些模型的auc、mtaucc

- 训练不稳定：认为是reweight的问题，通过在reweight乘上一个scaling_factor使得每个batch的reweight均值不超过设定的阈值

- 差异性小：计算每个样本的方差，loss上减去这个方差

## Reweight问题分析

问题的起点：这次的debug从reweight开始，reweight的计算方式以及设定均值不超过阈值的代码如下

> [!example]- Python 实现细节（29 行）
> ```Python
> def calculate_Sampled_Factual_loss(true_treat, w, weight_threshold):
>     # true_treat：真实的treatment，onehot的形式
>     # w：模型预测的结果，表示不同treatment的频率
>     # weight_threshold：设定的reweight均值的阈值
>
>     # Step 1. Calculate sample size and sample ratio per discount group
>     n_ratio = tf.reduce_mean(true_treat, axis=0)
>
>     # Step 2. Calculate p_i, which is the actual sample proportion for each sample
>     p_i_mat = tf.multiply(true_treat,n_ratio) # shape = (batch_size, )
>     p_i = tf.reduce_sum(p_i_mat, axis=1, keepdims=True) # shape = (batch_size, 1)
>
>     # Step 3. Calculate Weight term's first component
>     p_j_m = tf.reshape(1/(n_ratio + 1e-8), [1, -1]) # shape=(1,5)
>     w_a = tf.multiply(p_i,p_j_m) # shape = (batch_size,5)
>
>     # Step 4. Calculate Weight term's second compoent
>     pai_mat = tf.multiply(w,true_treat) #模型中delta预测的概率值与t对应元素相乘
>     pai = tf.reduce_sum(pai_mat, 1) # 取到每个样本真实折扣对应的模型预测的概率值,shape = (1024,)
>     pai_m = tf.reshape(1 / (pai + 1e-8), [-1, 1]) #shape = (1024,1)
>     w_b = tf.multiply(w,pai_m) #权重项的后一项
>
>     # Step 5. Calculate final weights
>     weight = tf.reduce_sum(tf.multiply(w_a,w_b), axis=1) # shape = (batch_size,)
>
>     # Step 6. 等比缩小weight的每个分量，使得它们的平均值不超过某个阈值
>     scaling_factor = weight_threshold / (tf.reduce_mean(weight) + 1e-8)
>     scaled_weight = weight * scaling_factor
>     return scaled_weight
> ```


找了下之前盒子呼返的训练代码（训练初期的结果），正常情况下，w的值应该是比较接近的，大小为1 / treament_nums，盒子呼返之前有5个treatment，所以w的每个值应该是0.2左右，现在是7个，w的每个值应该是0.14左右。

![](b5d59d132febe697-image.png)

这是因为，训练用的是随机价格实验数据，模型的输入特征和treatment正交，所以预测结果各个treatment应该是等概率的，这一点对于est_t（模型预测当前数据属于不同treatment的概率值）也是一样的。

但是现在的的训练结果中打印w的结果如下，可以看到，会有1e-7、1e-5这样的值出现，这会使得后续的reweight计算结果很大，这个值作为bce loss的权重之后，就可能会梯度爆炸。

![](4b7d76f01c9e4b98-image.png)

之前的代码是对每一个batch的均值作出限制，但是均值其实不能完全避免这个问题，还是可能会有极端数据出现。

**【猜测可能的原因】**

概率值集中在某个位置，说明模型对于可以从输入x中学习到treatment相关的信息，可能是由于

1. 特征中有和treatment相关的特征

2. RCT数据并不足够随机随机

猜测一：

这里检查使用的特征，有一部分pas开头的特征（24个，额外增加了city_id、day_of_week、semi_hour_of_day, h四个特征），这部分特征可能会和treatment强相关，原因在于随机价格实验是pid分流的。去掉这部分数据之后，问题并未解决。

猜测二：

为了验证这个猜测，基于XGB模型，用现有的特征预测treatment，label构造逻辑为100折label=0，97、94、91折label=1，88、85、82折label=2，全量特征和仅用pas相关特征，分别训练模型，结果如下：

| 仅pas相关特征 | 全部特征 |
| --- | --- |
| ![](b5c8a81a82154fcf-image.png) | ![](0f2538a67592682b-image.png) |

可以看到，仅pas相关特征在label=2的auc=0.699，全量特征label=2的auc=0.711，说明特征和和treatment确实具有相关性，基于全部特征选取top100的特征，onehot特征合并之后，剩下82个特征，从全量数据中剔除相关的特征，重新训练drcfr模型，发现还是有w值很低的问题出现。

之前没想起来，后续打印了est_t的值看了下，发现不论是否去掉top100的特征，est_t的预测基本上是均匀的，这部分符合预期。

![](c45541e6f6c6a8df-image.png)

回头又检查了代码，未发现问题。由于est_t和w的mlp block代码结构是一样的，只有输入不一样，所以尝试交换了est_t和w的mlp block代码，发现预测结果跟之前一样，说明不是代码的问题。

由于est_t是均匀的，或许不是数据的问题，这个现象可能是初始化的问题，训练前期就是不太稳定，需要一些trick。至于为什么之前盒子呼返的代码，w在训练初期就可以收敛到比较均匀的状态，可能是数据分布不同导致的。

后续修改reweight的计算代码为，改变是修改均值的限制为对w做clip操作

> [!example]- Python 实现细节（28 行）
> ```Python
> def calculate_Sampled_Factual_loss(true_treat, w, weight_threshold):
>     # true_treat：真实的treatment，onehot的形式
>     # w：模型预测的结果，表示不同treatment的频率
>     # weight_threshold：设定的reweight均值的阈值
>
>     # Step 1. Calculate sample size and sample ratio per discount group
>     n_ratio = tf.reduce_mean(true_treat, axis=0)
>
>     # Step 2. Calculate p_i, which is the actual sample proportion for each sample
>     p_i_mat = tf.multiply(true_treat,n_ratio) # shape = (batch_size, )
>     p_i = tf.reduce_sum(p_i_mat, axis=1, keepdims=True) # shape = (batch_size, 1)
>
>     # Step 3. Calculate Weight term's first component
>     p_j_m = tf.reshape(1/(n_ratio + 1e-8), [1, -1]) # shape=(1,5)
>     w_a = tf.multiply(p_i,p_j_m) # shape = (batch_size,5)
>
>     # Step 4. Calculate Weight term's second compoent
>     w = tf.clip_by_value(w, 0.1, 1)
>
>     pai_mat = tf.multiply(w,true_treat) #模型中delta预测的概率值与t对应元素相乘
>     pai = tf.reduce_sum(pai_mat, 1) # 取到每个样本真实折扣对应的模型预测的概率值,shape = (1024,)
>     pai_m = tf.reshape(1 / (pai + 1e-8), [-1, 1]) #shape = (1024,1)
>     w_b = tf.multiply(w,pai_m) #权重项的后一项
>
>     # Step 5. Calculate final weights
>     weight = tf.reduce_sum(tf.multiply(w_a,w_b), axis=1) # shape = (batch_size,)
>
>     return weight
> ```


修改之后，w在初期可能会有1e-5这样的值出现，但是训练后期不会突然崩掉，并且会收敛到均匀分布的状态。

![](b5153131db70a5db-image.png)

随机性的验证：

固定一组参数和随机种子，训练10次，每次50个epoch，发现随机性在合理范围内，文件名中的R0表示重复训练的次数，R0表示第一次训练。

> [!example]- JSON 实现细节（42 行）
> ```JSON
> [
>     {
>         "model_name": "./save_models/save_model_0520_0609_multi_test/2025-06-16-18-26_OPTAdam_LR0.0008_LAM0.01_BET0.1_WETT500_CPGD-1_UPFUCV7_ETCC_DP-1_TH-1_R0/export_model",
>         "test_auc": 0.7634645104408264
>     },
>     {
>         "model_name": "./save_models/save_model_0520_0609_multi_test/2025-06-16-20-25_OPTAdam_LR0.0008_LAM0.01_BET0.1_WETT500_CPGD-1_UPFUCV7_ETCC_DP-1_TH-1_R5/export_model",
>         "test_auc": 0.763222336769104
>     },
>     {
>         "model_name": "./save_models/save_model_0520_0609_multi_test/2025-06-16-21-38_OPTAdam_LR0.0008_LAM0.01_BET0.1_WETT500_CPGD-1_UPFUCV7_ETCC_DP-1_TH-1_R8/export_model",
>         "test_auc": 0.763143002986908
>     },
>     {
>         "model_name": "./save_models/save_model_0520_0609_multi_test/2025-06-16-19-37_OPTAdam_LR0.0008_LAM0.01_BET0.1_WETT500_CPGD-1_UPFUCV7_ETCC_DP-1_TH-1_R3/export_model",
>         "test_auc": 0.7630916833877563
>     },
>     {
>         "model_name": "./save_models/save_model_0520_0609_multi_test/2025-06-16-19-13_OPTAdam_LR0.0008_LAM0.01_BET0.1_WETT500_CPGD-1_UPFUCV7_ETCC_DP-1_TH-1_R2/export_model",
>         "test_auc": 0.7629960179328918
>     },
>     {
>         "model_name": "./save_models/save_model_0520_0609_multi_test/2025-06-16-21-14_OPTAdam_LR0.0008_LAM0.01_BET0.1_WETT500_CPGD-1_UPFUCV7_ETCC_DP-1_TH-1_R7/export_model",
>         "test_auc": 0.7629381418228149
>     },
>     {
>         "model_name": "./save_models/save_model_0520_0609_multi_test/2025-06-16-20-01_OPTAdam_LR0.0008_LAM0.01_BET0.1_WETT500_CPGD-1_UPFUCV7_ETCC_DP-1_TH-1_R4/export_model",
>         "test_auc": 0.7629303932189941
>     },
>     {
>         "model_name": "./save_models/save_model_0520_0609_multi_test/2025-06-16-20-49_OPTAdam_LR0.0008_LAM0.01_BET0.1_WETT500_CPGD-1_UPFUCV7_ETCC_DP-1_TH-1_R6/export_model",
>         "test_auc": 0.7629198431968689
>     },
>     {
>         "model_name": "./save_models/save_model_0520_0609_multi_test/2025-06-16-22-02_OPTAdam_LR0.0008_LAM0.01_BET0.1_WETT500_CPGD-1_UPFUCV7_ETCC_DP-1_TH-1_R9/export_model",
>         "test_auc": 0.7627704739570618
>     },
>     {
>         "model_name": "./save_models/save_model_0520_0609_multi_test/2025-06-16-18-50_OPTAdam_LR0.0008_LAM0.01_BET0.1_WETT500_CPGD-1_UPFUCV7_ETCC_DP-1_TH-1_R1/export_model",
>         "test_auc": 0.761604368686676
>     }
> ]
> ```


差异性小的问题，暂时还没有出现，各个treatment下的值有差异，所以之前 “计算每个样本的方差，loss上减去这个方差”的操作也删除了，目前没有发现新的问题。

![](f1eaa5b10c47243f-image.png)

## MTAUCC可复现性

固定一组参数，重复训练10次，每次40个epoch

代码仓库：<https://git.xiaojukeji.com/bwh_stg/ecr_drcfr/tree/zuyao>

代码：commit id: bf2c4c0

数据集：2025-05-20 -- 2025-05-29训练集，2025-06-03 -- 2025-06-09测试集，不含p维度特征

### **可能导致随机性的参数设置**

**重加权参数：**w所有元素的值应该收敛到0.14（7个treatment，1/7）左右，如果w是发散的（某些元素数值非常小），可能会有随机性， 这会导致某些样本权重过高，导致效果有偏差，这次训练会把w截断到\[0.05, 1\]范围内，减小w的方差

**随机种子：**

![](6cec4ec1b12c42f8-image.png)

**环境变量以及线程数设置：**

环境变量：可以帮助确保 TensorFlow 在 GPU 上的计算结果具有确定性

线程数：设置为1，防止线程导致的数据加载顺序和计算的随机性

![](0aaf6dd6d1b530e9-image.png)

**数据处理：**发现即使加载同样的数据计算均值方差，大概在1e-6这个量级会有差别，所以预先计算好均值方差保存成npy，每次加载相同的数据

### 实验结果

best qini：每个treatment下计算出qini score，然后求平均，训练过程中每个epoch都会计算一次，取40 epochs中最大值

随机性：由于内存限制，每次计算MTAUCC需要采样80%的数据，numpy采样时固定了随机种子为42

说明：R0\~R9表示实验重复的次数，best auc和best qini下一行的数据表示该次实验40 epochs中最优的auc或者qini score，MTAUCC-AREA行表示best auc对应epoch计算的MTAUCC-AREA，或者best qini对应epoch计算的MTAUCC-AREA

> [!example]- 完整对照数据（已展开分组表头）
> | 重复轮次 <br> | R0 <br> · best auc <br> | R0 <br> · best qini <br> | R1 <br> · best auc <br> | R1 <br> · best qini <br> | R2 <br> · best auc <br> | R2 <br> · best qini <br> | R3 <br> · best auc <br> | R3 <br> · best qini <br> | R4 <br> · best auc <br> | R4 <br> · best qini <br> | R5 <br> · best auc <br> | R5 <br> · best qini <br> | R6 <br> · best auc <br> | R6 <br> · best qini <br> | R7 <br> · best auc <br> | R7 <br> · best qini <br> | R8 <br> · best auc <br> | R8 <br> · best qini <br> | R9 <br> · best auc <br> | R9 <br> · best qini <br> |
> | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
> | <br> | 0.7552 <br> | 0.139 <br> | 0.7542 <br> | 0.126 <br> | 0.7543 <br> | 0.098 <br> | 0.7552 <br> | 0.190 <br> | 0.7545 <br> | 0.166 <br> | 0.7538 <br> | 0.133 <br> | 0.7540 <br> | **0.211** <br> | 0.7540 <br> | 0.175 <br> | **0.7555** <br> | 0.156 <br> | 0.7536 <br> | 0.140 <br> |
> | MTAUCC-AREA <br> | 0.0651 <br> | 0.0749 <br> | 0.1048 <br> | 0.0889 <br> | 0.0865 <br> | 0.0865 <br> | 0.1378 <br> | 0.113 <br> | 0.1336 <br> | 0.1194 <br> | 0.0592 <br> | 0.1013 <br> | 0.1027 <br> | 0.12 <br> | 0.1056 <br> | 0.1081 <br> | **0.1462** <br> | 0.1258 <br> | 0.1068 <br> | 0.113 <br> |



结论：

- auc、qini score和MTAUCC-AREA没有相关性

- 固定参数的条件下，auc可以认为可复现，但是qini score和mtaucc不可复现，还是具有随机性

	- qini score和mtaucc area不可复现，可能是因为训练过程只监督对正负样本的判断，跟auc直接相关，所以只有auc可复现

由于MTAUCC在计算时会对数据下采样（全量数据内存不够），所以在相同采样率、不同随机种子下计算MTAUCC，观察是否有明显变化

- 感觉没意义暂时没做，随机价格实验本身就是随机选择的人群

### 可复现性问题原因及解决方案

发现代码存在一个问题：在固定参数重跑多次试验时，如果在for循环里重跑，每次调用run函数（函数包含模型初始化和优化器），每次的结果会有差别；但是如果中断代码，重新执行train.py文件，每次运行的结果就完全相同，包括最优的auc、训练过程中每个epoch的各个loss数值。

**原因猜测：**对于具有随机性的操作，即使固定随机种子，for循环每次采样的结果也不一样，除非每次采样过后都重新设定随机种子。

![](9d3133adcb42c473-image.png)

**解决方法：**

- 写成bash脚本，for循环的参数放到bash脚本里传入，用bash脚本调用train.py文件

- 每次循环的时候都重新设定随机种子

### Loss增加ATE约束

**结论：**

- 加ate loss后，模型的值准提升较多，单调性（对角线数据）也符合预期

- 横向看，ate loss权重增大会提高模型的best auc，但是和best qini没有相关性

- theta=0时，ate和ite数值上差距较大

- theta>0时，ate和ite数值上会比较接近，但是V6、V7在97折的ite(图中最右侧的数据)预测差距较大，V8在ate loss权重较小时，拟合97折的ite较差，ate loss权重变大时效果会改善；V9在ate loss权重不为0时，拟合效果较好

【对比不同权重下ate loss效果】

固定lambda=1.0, beta=1.0（其余loss权重）

theta表示ate loss的权重

V6：二次函数

V7：线性函数

V8：分段线性

V9：multi-head

best qini：每个epoch计算每个treatment下的qini score，取平均

ate列：截取best qini对应epoch的数据，其中ate表示当前训练轮次所用到的数据的ate，ite表示模型预测的ite均值，从左往右折扣依次变浅

> [!example]- 完整对照数据（已展开分组表头）
> | <br> | theta=0 <br> · best auc <br> | theta=0 <br> · best qini <br> | theta=0 <br> · ate <br> | theta=0 <br> · mtaucc <br> | theta=10 <br> · best auc <br> | theta=10 <br> · best qini <br> | theta=10 <br> · ate <br> | theta=10 <br> · mtaucc <br> | theta=100 <br> · best auc <br> | theta=100 <br> · best qini <br> | theta=100 <br> · ate <br> | theta=100 <br> · mtaucc <br> |
> | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
> | V6 <br> | 0.7452 <br> | 0.2011 <br> | ![](68fa6da449f9d7b6-image.png) <br> | <br> | 0.7467 <br> | 0.2093 <br> | ![](995e4fe908c5d10b-image.png) <br> | <br> | 0.7495 <br> | 0.2421 <br> | ![](62f3c2a2265983fe-image.png) <br> | <br> |
> | V7 <br> | 0.7447 <br> | 0.1662 <br> | ![](8d49f030d986c14d-image.png) <br> | <br> | **0.7467** <br> | **0.2562** <br> | ![](ee15587024785338-image.png) <br> | <br> | **0.7498** <br> | **0.2436** <br> | ![](b2b71949fe386200-image.png) <br> | 0.1589 <br> |
> | V8 <br> | 0.7440 <br> | 0.1358 <br> | ![](6ae4ba32af299c6e-image.png) <br> | <br> | 0.7464 <br> | 0.081 <br> | ![](f02ee5897385d6de-image.png) <br> | <br> | 0.7495 <br> | 0.1361 <br> | ![](9a2f19b903f1cb13-image.png) <br> | <br> |
> | V9 <br> | **0.7461** <br> | **0.2540** <br> | ![](6cfd190a2b4b9954-image.png) <br> | <br> | 0.7467 <br> | 0.1632 <br> | ![](46867cf24e112a6a-image.png) <br> | <br> | 0.7487 <br> | 0.0614 <br> | ![](2f9b1e6af78e2a0c-image.png) <br> | <br> |



【RCT数据】

ATE：各组ECR减去100折组ECR

边际收益：各组的ATE和上一个step的ATE做差

> [!example]- 完整对照数据（已展开分组表头）
> | uabox_discount <br> | 实际ECR <br> · ECR <br> | 实际ECR <br> · ATE <br> | 实际ECR <br> · 边际收益 <br> | 线上ecr模型 <br> · ECR <br> | 线上ecr模型 <br> · ATE <br> | 线上ecr模型 <br> · 边际收益 <br> | ate loss版本 <br> · ECR <br> | ate loss版本 <br> · ATE <br> | ate loss版本 <br> · 边际收益 <br> |
> | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
> | 82 <br> | 0.8023 <br> | 0.0273 <br> | 0.0020 <br> | 0.5751 <br> | 0.0552 <br> | 0.0001 <br> | 0.8090 <br> | 0.0253 <br> | 0.0029 <br> |
> | 85 <br> | 0.8003 <br> | 0.0253 <br> | 0.0028 <br> | 0.5750 <br> | 0.0551 <br> | -0.0015 <br> | 0.8061 <br> | 0.0224 <br> | 0.0020 <br> |
> | 88 <br> | 0.7975 <br> | 0.0225 <br> | 0.0043 <br> | 0.5765 <br> | 0.0566 <br> | -0.0014 <br> | 0.8041 <br> | 0.0204 <br> | 0.0024 <br> |
> | 91 <br> | 0.7932 <br> | 0.0182 <br> | 0.0047 <br> | 0.5779 <br> | 0.0580 <br> | 0.0000 <br> | 0.8017 <br> | 0.0180 <br> | 0.0026 <br> |
> | 94 <br> | 0.7885 <br> | 0.0135 <br> | 0.0068 <br> | 0.5779 <br> | 0.0580 <br> | 0.0008 <br> | 0.7991 <br> | 0.0154 <br> | 0.0042 <br> |
> | 97 <br> | 0.7817 <br> | 0.0067 <br> | 0.0067 <br> | 0.5771 <br> | 0.0572 <br> | 0.0572 <br> | 0.7949 <br> | 0.0112 <br> | 0.0112 <br> |
> | 100 <br> | 0.7750 <br> | 0 <br> | 0 <br> | 0.5199 <br> | 0 <br> | 0 <br> | 0.7837    <br> | 0 <br> | 0 <br> |



| | mtaucc | 82 | 85 | 88 | 91 | 94 | 97 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 线上ecr模型 | mtaucc=0.1928 <br>![](e9cdbeb40951c024-image.png) | ![](a803d2ead75dea2e-image.png) | ![](18a6365ac70a8116-image.png) | ![](03a42e7c20bf8f37-image.png) | ![](0a2844b1616f93e1-image.png) | ![](493309b30a1422cb-image.png) | ![](2e1507dd68f6811c-image.png) |
| ate loss版本 | mtaucc=0.1589 <br>![](2b1439caaaddcda0-image.png) | ![](26a74c29a95f836d-image.png) | ![](ec570e666c3797f9-image.png) | ![](4315a05be3eccdcb-image.png) | ![](4aceeb6e2b510f04-image.png) | ![](21999abbcabd9d09-image.png) | ![](fcbb002965e73f0d-image.png) |

【观测数据】

2025-07-12 -- 2025-07-15 实验组union_stg_max_order_v1_only_box_ecr_v3数据

ATE：各组ECR减去100折组ECR

边际收益：各组的ATE和上一个step的ATE做差

#### 2025-07-12至07-15 ECR与ATE对照数据

> [!example]- 完整对照数据（已展开分组表头）
> | <br> | 实际ECR <br> · ECR <br> | 实际ECR <br> · ATE <br> | 实际ECR <br> · 边际收益 <br> | 线上ecr模型 <br> · ECR <br> | 线上ecr模型 <br> · ATE <br> | 线上ecr模型 <br> · 边际收益 <br> | ate loss版本 <br> · ECR <br> | ate loss版本 <br> · ATE <br> | ate loss版本 <br> · 边际收益 <br> |
> | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
> | 82 <br> | 0.8415 <br> | 0.0960 <br> | 0.0513 <br> | 0.6786 <br> | 0.0603 <br> | -0.0058 <br> | 0.8539 <br> | 0.0859 <br> | 0.0392 <br> |
> | 85 <br> | 0.7902 <br> | 0.0447 <br> | -0.0111 <br> | 0.6104 <br> | 0.0661 <br> | 0.0026 <br> | 0.8146 <br> | 0.0467 <br> | 0.0022 <br> |
> | 88 <br> | 0.8013 <br> | 0.0558 <br> | 0.0235 <br> | 0.6117 <br> | 0.0635 <br> | 0.0037 <br> | 0.8125 <br> | 0.0445 <br> | 0.0108 <br> |
> | 91 <br> | 0.7778 <br> | 0.0323 <br> | 0.0062 <br> | 0.5918 <br> | 0.0598 <br> | -0.0014 <br> | 0.8017 <br> | 0.0337 <br> | 0.0018 <br> |
> | 94 <br> | 0.7716 <br> | 0.0260 <br> | 0.0163 <br> | 0.5834 <br> | 0.0612 <br> | 0.0019 <br> | 0.7999 <br> | 0.0319 <br> | 0.0193 <br> |
> | 97 <br> | 0.7552 <br> | 0.0097 <br> | 0.0097 <br> | 0.5599 <br> | 0.0593 <br> | 0.0593 <br> | 0.7806 <br> | 0.0126 <br> | 0.0126 <br> |
> | 100 <br> | 0.7455 <br> | 0.0000 <br> | 0.0000 <br> | 0.5394 <br> | 0 <br> | 0 <br> | 0.7680 <br> | 0 <br> | 0 <br> |



RCT数据和观测数据模型预测结果均值
【真实ECR和模型预测ECR均值对比】

- 线上模型各组之间的ecr均值不符合单调性

- 线上模型的值准较差

| | 真实值 | 线上模型均值 | ate loss版本均值 |
| :---: | :---: | :---: | :---: |
| uabox_discount | ecr |
| 82 | 0.8023 | 0.5751 | 0.8090 |
| 85 | 0.8003 | 0.5750 | 0.8061 |
| 88 | 0.7975 | 0.5765 | 0.8041 |
| 91 | 0.7932 | 0.5779 | 0.8017 |
| 94 | 0.7885 | 0.5779 | 0.7991 |
| 97 | 0.7817 | 0.5771 | 0.7949 |
| 100 | 0.7750 | 0.5199 | 0.7837 |

【线上版本模型】

不加ate loss(线上版本，根据mtaucc挑选)

mtaucc=0.1928

| | mtaucc | 82 | 85 | 88 | 91 | 94 | 97 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| | ![](e9cdbeb40951c024-image.png) | ![](a803d2ead75dea2e-image.png) | ![](18a6365ac70a8116-image.png) | ![](03a42e7c20bf8f37-image.png) | ![](0a2844b1616f93e1-image.png) | ![](493309b30a1422cb-image.png) | ![](2e1507dd68f6811c-image.png) |

|  <br> <br>uabox_discount | probabilities82 | probabilities85 | probabilities88 | probabilities91 | probabilities94 | probabilities97 | probabilities100 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 82 | 0.5751 | 0.5729 | 0.5709 | 0.5690 | 0.5672 | 0.5655 | 0.5062 |
| 85 | 0.5771 | 0.5750 | 0.5730 | 0.5711 | 0.5693 | 0.5676 | 0.5084 |
| 88 | 0.5806 | 0.5785 | 0.5765 | 0.5746 | 0.5728 | 0.5711 | 0.5125 |
| 91 | 0.5840 | 0.5818 | 0.5798 | 0.5779 | 0.5761 | 0.5744 | 0.5155 |
| 94 | 0.5857 | 0.5836 | 0.5816 | 0.5797 | 0.5779 | 0.5762 | 0.5180 |
| 97 | 0.5866 | 0.5845 | 0.5825 | 0.5806 | 0.5788 | 0.5771 | 0.5185 |
| 100 | 0.5878 | 0.5857 | 0.5837 | 0.5818 | 0.5800 | 0.5783 | 0.5199 |

【有ate loss版本】

mtaucc=0.1589

| | mtaucc | 82 | 85 | 88 | 91 | 94 | 97 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| | ![](2b1439caaaddcda0-image.png) | ![](26a74c29a95f836d-image.png) | ![](ec570e666c3797f9-image.png) | ![](4315a05be3eccdcb-image.png) | ![](4aceeb6e2b510f04-image.png) | ![](21999abbcabd9d09-image.png) | ![](fcbb002965e73f0d-image.png) |

加ate loss ，V7  theta=100

|  <br> <br>uabox_discount | probabilities82 | probabilities85 | probabilities88 | probabilities91 | probabilities94 | probabilities97 | probabilities100 |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 82 | 0.8090 | 0.8055 | 0.8019 | 0.7984 | 0.7947 | 0.7911 | 0.7802 |
| 85 | 0.8096 | 0.8061 | 0.8026 | 0.7990 | 0.7954 | 0.7918 | 0.7810 |
| 88 | 0.8111 | 0.8076 | 0.8041 | 0.8006 | 0.7970 | 0.7934 | 0.7827 |
| 91 | 0.8122 | 0.8087 | 0.8052 | 0.8017 | 0.7982 | 0.7946 | 0.7837 |
| 94 | 0.8130 | 0.8096 | 0.8061 | 0.8026 | 0.7991 | 0.7955 | 0.7849 |
| 97 | 0.8124 | 0.8090 | 0.8055 | 0.8020 | 0.7985 | 0.7949 | 0.7842 |
| 100 | 0.8118 | 0.8084 | 0.8050 | 0.8015 | 0.7980 | 0.7944 | 0.7837 |

【实验数据】

2025-07-12 -- 2025-07-15 实验组union_stg_max_order_v1_only_box_ecr_v3数据

ATE：各组ECR减去100折组ECR

边际收益：各组的ATE和上一个step的ATE做差

此处数据表与前文完全相同，统一参见 [[#2025-07-12至07-15 ECR与ATE对照数据|ECR、ATE 与边际收益对照数据]]。原文此处使用“实验数据”标签。

## 增加整体的弹性标签

参考ate loss的思路，对整体数据增加ate error的约束，而不是对每一条数据增加约束（也没有办法对每一条数据约束），不仅是的ate error降低，而且使得平均ecr的值准提升。所以参考这个思路，想在训练过程中，增加弹性的监督，监督的标签从其他模型学习的结果获取，目前用的是因果森林。

对比线上ecr模型、ate loss版本、因果森林的dini、ate error和mtaucc，可以看到因果森林版本除了ate error略差于ate loss版本外，其余各项指标均好于另外两个版本（但是由于计算可能由于采样的问题，mtaucc的蓝线基准线略有差异，且每次计算的结果不同）。

| | mtaucc | 82 | 85 | 88 | 91 | 94 | 97 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 因果森林 | mtaucc=0.1973 <br>![](134b7de65c80b3f9-image.png) | ![](85fcadd05c1855f3-image.png) | ![](39a18f4795a30a0d-image.png) | ![](016b07f10b1941f8-image.png) | ![](3571b695a1a6cc26-image.png) | ![](1c344cb1c78469ee-image.png) | ![](dd4c078aeae848f5-image.png) |
| 线上ecr模型 | mtaucc=0.1928 <br>![](e9cdbeb40951c024-image.png) | ![](a803d2ead75dea2e-image.png) | ![](18a6365ac70a8116-image.png) | ![](03a42e7c20bf8f37-image.png) | ![](0a2844b1616f93e1-image.png) | ![](493309b30a1422cb-image.png) | ![](2e1507dd68f6811c-image.png) |
| ate loss版本 | mtaucc=0.1589 <br>![](2b1439caaaddcda0-image.png) | ![](26a74c29a95f836d-image.png) | ![](ec570e666c3797f9-image.png) | ![](4315a05be3eccdcb-image.png) | ![](4aceeb6e2b510f04-image.png) | ![](21999abbcabd9d09-image.png) | ![](fcbb002965e73f0d-image.png) |
