---
title: "特征交叉（PEPNet）"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2209768827066
---

# 特征交叉（PEPNet）

## 1、本阶段结论

**阶段结论：**FiBiNET field 聚合是目前最稳的静态交叉，1epoch收益约 0.07 pp。完整 pair 展开和 full-rank 串行替换都失败，交叉模块应保持 field 边界、有限容量和残差连接。

## 2、实验内容汇总

直接迁移旧玖鑫PLE方案，基于PEP00baseline，lr:1e-2。

| 模型 <br> | AUC(od) <br> | AUC(o) <br> | AUC(d) <br> |
| --- | --- | --- | --- |
| PEP00(baseline:pp+driver) <br> | 0.7439 <br> | 0.7401 <br> | 0.8186 <br> |
| DCNv2 <br> | 0.7436 <br> | 0.7404 <br> | 0.8182 <br> |
| Wukong <br> | 0.7450 <br> | 0.7411 <br> | 0.8206 <br> |
| Senet <br> | 0.7441 <br> | 0.7406 <br> | 0.8203 <br> |

基于PEPNet新逻辑实验

| 实验 <br> | AUC(od) <br> | AUC(o) <br> | AUC(d) <br> | Cross输入/位置 <br> | 层数/Rank <br> | 融合与特殊设置 <br> |
| --- | --- | --- | --- | --- | --- | --- |
| PEP02(baseline) <br> | **0.7456** <br> | **0.7404** <br> | **0.8237** <br> |  <br> |  <br> |  <br> |
| DCNv2 <br> | 0.7451 <br> | 0.7412 <br> | 0.8233 <br> | S+A → Cross → EP <br> | L1/R8 <br> | 内部残差系数0.01、clamp、LayerNorm、Dropout；外层cross_weight=0.1 <br> |
| DCNv2_3e-4lamda <br> | 0.7449 <br> | 0.7412 <br> | 0.8229 <br> | 同DCNv2 <br> | L1/R8 <br> | 仅将EP/PP恒等正则从1e-4提高到3e-4 <br> |
| DCNv2_norm <br> | 0.7452 <br> | 0.7413 <br> | 0.8228 <br> | S+A → Cross → EP <br> | L1/R8 <br> | 同保守版，但增加低秩矩阵逐行L2归一化 <br> |
| DCNv2_cro <br> | 0.7451 <br> | 0.7412 <br> | 0.8233 <br> | 推理时关闭Cross <br> | 同训练checkpoint <br> | 将训练后cross_weight=0，没有重新训练 <br> |
| DCNv2_norm_cro <br> | 0.7452 <br> | 0.7412 <br> | 0.8226 <br> | 推理时关闭归一化版Cross <br> | 同训练checkpoint <br> | 将训练后cross_weight=0，没有重新训练 <br> |
| Dcna1 <br> | 0.7359 <br> | 0.7403 <br> | 0.8150 <br> | S+A → Cross → EP <br> | L1/R8 <br> | 论文Cross公式；删除内外缩放、norm、clamp、dropout；Cross结果直接进入EP <br> |
| Dcna2 <br> | 0.7443 <br> | 0.7390 <br> | 0.8214 <br> | S+A → Cross → EP <br> | **L2/R8** <br> | 相比A1只增加到2层 <br> |
| Dcna3 <br> | 0.7364 <br> | 0.7352 <br> | 0.8153 <br> | S+A → Cross → EP <br> | L2/R64 <br> | 相比A2只把rank从8提高到64 <br> |
| Dcn_cros3 <br> | 0.7436 <br> | 0.7409 <br> | 0.8212 <br> | S+A → Cross → EP <br> | L3/R8 <br> | 相比A2只增加到3层；全量Cross <br> |
| Dcn_alpha3 <br> | 0.7435 <br> | 0.7403 <br> | 0.8229 <br> | S+A → Cross → EP <br> | L2/R8 <br> | 三个任务独立alpha_od/o/d，初始均为1；共享EP参数但分别前向三次 <br> |
| Dcn_after_ep <br> | 0.7426 <br> | 0.7400 <br> | 0.8224 <br> | A → EP → Cross → PP <br> | L2/R8 <br> | 唯一干净A版本；无sparse Cross、无alpha，三个任务共用Cross输出 <br> |
| PEP02(baseline) <br> | **0.7456** <br> | **0.7404** <br> | **0.8237** <br> |  <br> |  <br> |  <br> |
| Senet_bilinear_field <br> | 0.7447 <br> | 0.7411 <br> | 0.8233 <br> | S+A <br> | 字段级SENet＋rank8聚合Bilinear <br> | 内部残差0.1、clamp、LayerNorm、Dropout；外层cross_weight=0.1 <br> |
| Senet_bilinear_dimension <br> | 0.7454 <br> | 0.7410 <br> | 0.8234 <br> | S+A展平2820维 <br> | 每个Embedding坐标一个SENet权重＋全局Bilinear <br> | 同样有内部0.1和外层0.1；参数量远大于字段版 <br> |
| Senet_bilinear_field_cro <br> | 0.7446 <br> | 0.7411 <br> | 0.8235 <br> | 同字段版checkpoint <br> | 推理关闭外层交叉 <br> | cross_weight=0，没有重训 <br> |
| Senet_bilinear_dimension_cro <br> | 0.7444 <br> | 0.7399 <br> | 0.8229 <br> | 同维度版checkpoint <br> | 推理关闭外层交叉 <br> | cross_weight=0，没有重训 <br> |
| Senet_bilinear_nosacle <br> | 0.7431 <br> | 0.7404 <br> | 0.8212 <br> | S+A <br> | 字段SENet＋rank8聚合Bilinear <br> | 删除内外缩放、norm、dropout、clamp，直接input+bilinear <br> |
| Senet_bilinear_nosenet <br> | 0.7454 <br> | **0.7416** <br> | 0.8236 <br> | S+A <br> | 无SENet；Field-All完整20×20 Bilinear <br> | 其他字段均值聚合，直接input+bilinear <br> |
| Senet_bilinear_fibinet <br> | 0.7452 <br> | 0.7406 <br> | 0.8231 <br> | S+A <br> | raw Hadamard＋SENet Bilinear双分支 <br> | concat 40维→投影20维，再执行input+fusion <br> |
| PEP02(baseline) <br> | **0.7456** <br> | **0.7404** <br> | **0.8237** <br> |  <br> |  <br> |  <br> |
| wukong6-6-3 <br> | 0.7453 <br> | **0.7409** <br> | **0.8240** <br> | S+A → WuKong → EP <br> | 2层；每层6个LCB＋6个FMB；FMB rank3；内部1层32维MLP <br> | 12个隐字段投影为131个general槽位；外层cross_weight=0.1 <br> |
| wukong6-6-3_cro <br> | 0.7307 <br> | 0.7251 <br> | 0.7934 <br> | 同一训练checkpoint <br> | 结构不变 <br> | 推理时cross_weight=0，没有重训 <br> |

## 3、版本演进与逐实验记录

### 3.1 第一轮静态交叉接入

| **实验** <br> | **OD** <br> | **O** <br> | **D** <br> | **Mean** <br> | **对照口径** <br> |
| --- | --- | --- | --- | --- | --- |
| DCNv2 <br> | 0.7436 <br> | 0.7404 <br> | 0.8182 <br> | 0.7674 <br> | 1024batchsize-baseline <br> |
| Wukong <br> | 0.7450 <br> | 0.7411 <br> | 0.8206 <br> | 0.7689 <br> | 1024batchsize-baseline <br> |
| Wukong_lr-split <br> | 0.7457 <br> | 0.7410 <br> | 0.8237 <br> | 0.7701 <br> | 1024batchsize-baseline <br> |
| Senet <br> | 0.7441 <br> | 0.7406 <br> | 0.8203 <br> | 0.7683 <br> | 1024batchsize-baseline <br> |

**3.1.1  DCNv2**

**实验设计：**只沿交叉路径验证一个具体变化：Version A：sparse+General 共 141 个 20 维字段展平后做 1 层低秩 DCNv2（rank=8），只取交叉后的 General 回灌。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](47d00c81cbcb06b0-image.png)

图 1  DCNv2 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7436 <br> | 0.7404 <br> | 0.8182 <br> | 0.7674 <br> | -0.23 pp <br> |

单头变化：OD -0.18 pp；O -0.01 pp；D -0.51 pp。

**结果分析：**相对 PEP00(baseline-diagnostics)，OD/O/D 分别变化 -0.18/-0.01/-0.51 pp，Mean AUC 变化 -0.23 pp。相对标注基线，Mean AUC 下降 0.23 pp。这条路线不再继续扩容，代码只保留作复现和反例。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.1.2  Wukong**

**实验设计：**只沿交叉路径验证一个具体变化：Version A：两层 WuKong，LCB 与 FMB 各输出 6 个字段，再投影回 131 个 General 字段。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](1ac08452bdc448ef-image.png)

图 2  Wukong 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7450 <br> | 0.7411 <br> | 0.8206 <br> | 0.7689 <br> | -0.08 pp <br> |

单头变化：OD -0.04 pp；O +0.06 pp；D -0.27 pp。

**结果分析：**相对 PEP00(baseline-diagnostics)，OD/O/D 分别变化 -0.04/+0.06/-0.27 pp，Mean AUC 变化 -0.08 pp。相对标注基线，Mean AUC 变化 -0.08 pp，基本持平。现有结果不足以支持继续增加复杂度。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.1.3  Wukong_lr-split**

**实验设计：**保持主体结构基本不变，检查训练配置或优化策略对结果的影响：WuKong 交叉结构叠加 Gate MLP split-LR。

![](8e78c183699c08cc-image.png)

图 3  Wukong_lr-split 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7457 <br> | 0.7410 <br> | 0.8237 <br> | 0.7701 <br> | +0.04 pp <br> |

单头变化：OD +0.03 pp；O +0.05 pp；D +0.04 pp。

**结果分析：**相对 PEP00(baseline-diagnostics)，OD/O/D 分别变化 +0.03/+0.05/+0.04 pp，Mean AUC 变化 +0.04 pp。相对标注基线，Mean AUC 小幅提高 0.04 pp。差值不大，暂不把它当成稳定收益，需要结合单头变化和重复运行。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.1.4  Senet**

**实验设计：**只沿交叉路径验证一个具体变化：Version A：field-wise SENet 重标定后接低秩 bilinear 交互，残差权重从 0.1 开始。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](2adb747cdaa12e79-image.png)

图 4 Senet 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7441 <br> | 0.7406 <br> | 0.8203 <br> | 0.7683 <br> | -0.14 pp <br> |

单头变化：OD -0.13 pp；O +0.01 pp；D -0.30 pp。

**结果分析：**相对 PEP00(baseline-diagnostics)，OD/O/D 分别变化 -0.13/+0.01/-0.30 pp，Mean AUC 变化 -0.14 pp。相对标注基线，Mean AUC 下降 0.14 pp。这条路线不再继续扩容，代码只保留作复现和反例。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

### 3.2 PEP02 上的 DCNv2、SENet 与 WuKong

| **实验** <br> | **OD** <br> | **O** <br> | **D** <br> | **Mean** <br> | **对照口径** <br> |
| --- | --- | --- | --- | --- | --- |
| PEP02_DCNv2 <br> | 0.7451 <br> | 0.7412 <br> | 0.8233 <br> | 0.7699 <br> | PEP01/PEP02 特征交叉基线 <br> |
| PEP02_DCNv2_3e-4lamda <br> | 0.7449 <br> | 0.7412 <br> | 0.8229 <br> | 0.7697 <br> | PEP01/PEP02 特征交叉基线 <br> |
| PEP02_DCNv2_norm <br> | 0.7452 <br> | 0.7413 <br> | 0.8228 <br> | 0.7698 <br> | PEP01/PEP02 特征交叉基线 <br> |
| Senet_bilinear_field <br> | 0.7447 <br> | 0.7411 <br> | 0.8233 <br> | 0.7697 <br> | PEP01/PEP02 特征交叉基线 <br> |
| Senet_bilinear_dimension <br> | 0.7454 <br> | 0.7410 <br> | 0.8234 <br> | 0.7699 <br> | PEP01/PEP02 特征交叉基线 <br> |
| wukong6-6-3 <br> | 0.7453 <br> | 0.7409 <br> | 0.8240 <br> | 0.7701 <br> | PEP01/PEP02 特征交叉基线 <br> |
| PEP02_DCNv2_cro <br> | 0.7451 <br> | 0.7412 <br> | 0.8233 <br> | 0.7699 <br> | PEP01/PEP02 特征交叉基线 <br> |
| PEP02_DCNv2_norm_cro <br> | 0.7452 <br> | 0.7412 <br> | 0.8226 <br> | 0.7697 <br> | PEP01/PEP02 特征交叉基线 <br> |
| Senet_bilinear_field_cro <br> | 0.7446 <br> | 0.7411 <br> | 0.8235 <br> | 0.7697 <br> | PEP01/PEP02 特征交叉基线 <br> |
| Senet_bilinear_dimension_cro <br> | 0.7444 <br> | 0.7399 <br> | 0.8229 <br> | 0.7691 <br> | PEP01/PEP02 特征交叉基线 <br> |
| wukong6-6-3_cro <br> | 0.7307 <br> | 0.7251 <br> | 0.7934 <br> | 0.7497 <br> | PEP01/PEP02 特征交叉基线 <br> |

**3.2.1  PEP02_DCNv2**

**实验设计：**只沿交叉路径验证一个具体变化：PEP02 上的低秩 DCNv2，1 层、rank=8，交叉输入为 sparse+General。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](788144dcf9cdb688-image.png)

图 5  PEP02_DCNv2 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7451 <br> | 0.7412 <br> | 0.8233 <br> | 0.7699 <br> | -0.00 pp <br> |

单头变化：OD -0.05 pp；O +0.08 pp；D -0.04 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.05/+0.08/-0.04 pp，Mean AUC 变化 -0.00 pp。相对标注基线，Mean AUC 变化 -0.00 pp，基本持平。现有结果不足以支持继续增加复杂度。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.2.2  PEP02_DCNv2_3e-4lamda**

**实验设计：**只沿交叉路径验证一个具体变化：DCNv2 结构不变，将 gate 正则系数改为 3e-4。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](bf2537fb5ca5d02a-image.png)

图 6  PEP02_DCNv2_3e-4lamda 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7449 <br> | 0.7412 <br> | 0.8229 <br> | 0.7697 <br> | -0.02 pp <br> |

单头变化：OD -0.07 pp；O +0.08 pp；D -0.08 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.07/+0.08/-0.08 pp，Mean AUC 变化 -0.02 pp。相对标注基线，Mean AUC 变化 -0.02 pp，基本持平。现有结果不足以支持继续增加复杂度。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.2.3  PEP02_DCNv2_norm**

**实验设计：**只沿交叉路径验证一个具体变化：在 DCNv2 交叉路径增加归一化与稳定性处理。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](108be6ac3f238c91-image.png)

图 7  PEP02_DCNv2_norm 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7452 <br> | 0.7413 <br> | 0.8228 <br> | 0.7698 <br> | -0.01 pp <br> |

单头变化：OD -0.04 pp；O +0.09 pp；D -0.09 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.04/+0.09/-0.09 pp，Mean AUC 变化 -0.01 pp。相对标注基线，Mean AUC 变化 -0.01 pp，基本持平。现有结果不足以支持继续增加复杂度。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.2.4  Senet_bilinear_field**

**实验设计：**只沿交叉路径验证一个具体变化：按字段求 SENet 权重；U/V 将每个 20 维字段投到 rank=8，以其他字段 V 之和形成 bilinear context。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](d5a8c50871e44120-image.png)

图 8  Senet_bilinear_field 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7447 <br> | 0.7411 <br> | 0.8233 <br> | 0.7697 <br> | -0.02 pp <br> |

单头变化：OD -0.09 pp；O +0.07 pp；D -0.04 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.09/+0.07/-0.04 pp，Mean AUC 变化 -0.02 pp。相对标注基线，Mean AUC 变化 -0.02 pp，基本持平。现有结果不足以支持继续增加复杂度。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.2.5  Senet_bilinear_dimension**

**实验设计：**只沿交叉路径验证一个具体变化：把全部 embedding 展平后按维度做 SENet 与全局 bilinear，而不是逐 field 交互。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](de3bbe1cc61415e2-image.png)

图 9  Senet_bilinear_dimension 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7454 <br> | 0.7410 <br> | 0.8234 <br> | 0.7699 <br> | +0.00 pp <br> |

单头变化：OD -0.02 pp；O +0.06 pp；D -0.03 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.02/+0.06/-0.03 pp，Mean AUC 变化 +0.00 pp。相对标注基线，Mean AUC 小幅提高 0.00 pp。差值不大，暂不把它当成稳定收益，需要结合单头变化和重复运行。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.2.6  wukong6-6-3**

**实验设计：**只沿交叉路径验证一个具体变化：S+A 进入两层 WuKong；每层含 6 个 LCB 和 6 个 FMB，FMB rank=3、内部一层 32 维 MLP；12 个隐字段投影回 131 个 General 槽位，外层 cross_weight=0.1。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](df8f15f02c7a4a0b-image.png)

图 10  wukong6-6-3 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7453 <br> | 0.7409 <br> | 0.8240 <br> | 0.7701 <br> | +0.02 pp <br> |

单头变化：OD -0.03 pp；O +0.05 pp；D +0.03 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.03/+0.05/+0.03 pp，Mean AUC 变化 +0.02 pp。相对标注基线，Mean AUC 小幅提高 0.02 pp。差值不大，暂不把它当成稳定收益，需要结合单头变化和重复运行。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.2.7  PEP02_DCNv2_cro**

**实验设计：**关闭或移除局部路径，判断当前收益究竟来自哪个模块：沿用 PEP02_DCNv2 已训练 checkpoint，只在推理时把 cross_weight 置零；没有重新训练。该实验检查收益是否真的来自 Cross 路径。

![](577d8e585071679a-image.png)

图 11  PEP02_DCNv2_cro 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7451 <br> | 0.7412 <br> | 0.8233 <br> | 0.7699 <br> | -0.00 pp <br> |

单头变化：OD -0.05 pp；O +0.08 pp；D -0.04 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.05/+0.08/-0.04 pp，Mean AUC 变化 -0.00 pp。这是同一 checkpoint 的推理期关路实验。它可用于判断路径依赖，但不能代替重新训练后的消融。 该结果用于解释已训练模型对 Cross 路径的依赖，不作为新的训练候选。

**3.2.8  PEP02_DCNv2_norm_cro**

**实验设计：**关闭或移除局部路径，判断当前收益究竟来自哪个模块：沿用 normalized DCNv2 checkpoint，只在推理时关闭外层 Cross；没有重新训练。

![](1a58affd30f368b2-image.png)

图 12  PEP02_DCNv2_norm_cro 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7452 <br> | 0.7412 <br> | 0.8226 <br> | 0.7697 <br> | -0.02 pp <br> |

单头变化：OD -0.04 pp；O +0.08 pp；D -0.11 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.04/+0.08/-0.11 pp，Mean AUC 变化 -0.02 pp。这是同一 checkpoint 的推理期关路实验。它可用于判断路径依赖，但不能代替重新训练后的消融。 该结果用于解释已训练模型对 Cross 路径的依赖，不作为新的训练候选。

**3.2.9  Senet_bilinear_field_cro**

**实验设计：**关闭或移除局部路径，判断当前收益究竟来自哪个模块：沿用 field-wise SENet+Bilinear checkpoint，只在推理时把外层交叉权重置零；没有重新训练。

![](3b9994c204feb6cd-image.png)

图 13  Senet_bilinear_field_cro 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7446 <br> | 0.7411 <br> | 0.8235 <br> | 0.7697 <br> | -0.02 pp <br> |

单头变化：OD -0.10 pp；O +0.07 pp；D -0.02 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.10/+0.07/-0.02 pp，Mean AUC 变化 -0.02 pp。这是同一 checkpoint 的推理期关路实验。它可用于判断路径依赖，但不能代替重新训练后的消融。 该结果用于解释已训练模型对 Cross 路径的依赖，不作为新的训练候选。

**3.2.10  Senet_bilinear_dimension_cro**

**实验设计：**关闭或移除局部路径，判断当前收益究竟来自哪个模块：沿用 dimension-wise SENet+Bilinear checkpoint，只在推理时关闭外层交叉；没有重新训练。

![](814e82c599fed4ea-image.png)

图 14  Senet_bilinear_dimension_cro 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7444 <br> | 0.7399 <br> | 0.8229 <br> | 0.7691 <br> | -0.08 pp <br> |

单头变化：OD -0.12 pp；O -0.05 pp；D -0.08 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.12/-0.05/-0.08 pp，Mean AUC 变化 -0.08 pp。这是同一 checkpoint 的推理期关路实验。它可用于判断路径依赖，但不能代替重新训练后的消融。 该结果用于解释已训练模型对 Cross 路径的依赖，不作为新的训练候选。

**3.2.11  wukong6-6-3_cro**

**实验设计：**关闭或移除局部路径，判断当前收益究竟来自哪个模块：沿用 WuKong 6-6-3 checkpoint，只在推理时把 cross_weight 置零；没有重新训练。

![](fff700fc9f8e20bd-image.png)

图 15 wukong6-6-3_cro 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7307 <br> | 0.7251 <br> | 0.7934 <br> | 0.7497 <br> | -2.02 pp <br> |

单头变化：OD -1.49 pp；O -1.53 pp；D -3.03 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -1.49/-1.53/-3.03 pp，Mean AUC 变化 -2.02 pp。这是同一 checkpoint 的推理期关路实验。它可用于判断路径依赖，但不能代替重新训练后的消融。 该结果用于解释已训练模型对 Cross 路径的依赖，不作为新的训练候选。

### 3.3 DCNv2 论文对齐与插入位置

| **实验** <br> | **OD** <br> | **O** <br> | **D** <br> | **Mean** <br> | **对照口径** <br> |
| --- | --- | --- | --- | --- | --- |
| Dcna1 <br> | 0.7359 <br> | 0.7403 <br> | 0.8150 <br> | 0.7637 <br> | PEP02 特征交叉基线 <br> |
| Dcna2 <br> | 0.7443 <br> | 0.7390 <br> | 0.8214 <br> | 0.7682 <br> | PEP02 特征交叉基线 <br> |
| Dcna3 <br> | 0.7364 <br> | 0.7352 <br> | 0.8153 <br> | 0.7623 <br> | PEP02 特征交叉基线 <br> |
| Dcn_cros3 <br> | 0.7436 <br> | 0.7409 <br> | 0.8212 <br> | 0.7686 <br> | PEP02 特征交叉基线 <br> |
| Dcn_alpha3 <br> | 0.7435 <br> | 0.7403 <br> | 0.8229 <br> | 0.7689 <br> | PEP02 特征交叉基线 <br> |
| Dcn_after_ep <br> | 0.7426 <br> | 0.7400 <br> | 0.8224 <br> | 0.7683 <br> | PEP02 特征交叉基线 <br> |

**3.3.1  Dcna1**

**实验设计：**只沿交叉路径验证一个具体变化：论文式 DCNv2 Cross，1 层、rank=8；移除内外缩放、归一化、clamp 和 dropout，Cross 结果直接进入 EP。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](4d5c76f7176cbc21-image.png)

图 16  Dcna1 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7359 <br> | 0.7403 <br> | 0.8150 <br> | 0.7637 <br> | -0.62 pp <br> |

单头变化：OD -0.97 pp；O -0.01 pp；D -0.87 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.97/-0.01/-0.87 pp，Mean AUC 变化 -0.62 pp。相对标注基线，Mean AUC 下降 0.62 pp。这条路线不再继续扩容，代码只保留作复现和反例。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.3.2  Dcna2**

**实验设计：**只沿交叉路径验证一个具体变化：在 Dcna1 上仅把低秩 Cross 从 1 层增加到 2 层，rank 保持 8。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](f94a1c081fa998f2-image.png)

图 17 Dcna2 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7443 <br> | 0.7390 <br> | 0.8214 <br> | 0.7682 <br> | -0.17 pp <br> |

单头变化：OD -0.13 pp；O -0.14 pp；D -0.23 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.13/-0.14/-0.23 pp，Mean AUC 变化 -0.17 pp。相对标注基线，Mean AUC 下降 0.17 pp。这条路线不再继续扩容，代码只保留作复现和反例。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.3.3  Dcna3**

**实验设计：**只沿交叉路径验证一个具体变化：在 2 层论文式 Cross 上把 rank 从 8 提高到 64，检查交叉子空间容量。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](02e0e6ada638ad21-image.png)

图 18  Dcna3 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7364 <br> | 0.7352 <br> | 0.8153 <br> | 0.7623 <br> | -0.76 pp <br> |

单头变化：OD -0.92 pp；O -0.52 pp；D -0.84 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.92/-0.52/-0.84 pp，Mean AUC 变化 -0.76 pp。相对标注基线，Mean AUC 下降 0.76 pp。这条路线不再继续扩容，代码只保留作复现和反例。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.3.4  Dcn_cros3**

**实验设计：**关闭或移除局部路径，判断当前收益究竟来自哪个模块：保持 rank=8，把论文式低秩 DCNv2 从 2 层增加到 3 层，使用全量 Cross。

![](9316089fc0068f8f-image.png)

图 19  Dcn_cros3 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7436 <br> | 0.7409 <br> | 0.8212 <br> | 0.7686 <br> | -0.13 pp <br> |

单头变化：OD -0.20 pp；O +0.05 pp；D -0.25 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.20/+0.05/-0.25 pp，Mean AUC 变化 -0.13 pp。相对标注基线，Mean AUC 下降 0.13 pp。这条路线不再继续扩容，代码只保留作复现和反例。 该结果用于解释已训练模型对 Cross 路径的依赖，不作为新的训练候选。

**3.3.5  Dcn_alpha3**

**实验设计：**只沿交叉路径验证一个具体变化：为 OD/O/D 分别学习交叉残差系数 alpha，让三个任务控制交叉强度。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](8573e8f0e3f32044-image.png)

图 20  Dcn_alpha3 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7435 <br> | 0.7403 <br> | 0.8229 <br> | 0.7689 <br> | -0.10 pp <br> |

单头变化：OD -0.21 pp；O -0.01 pp；D -0.08 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.21/-0.01/-0.08 pp，Mean AUC 变化 -0.10 pp。相对标注基线，Mean AUC 变化 -0.10 pp，基本持平。现有结果不足以支持继续增加复杂度。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.3.6  Dcn_after_ep**

**实验设计：**只沿交叉路径验证一个具体变化：先做 EPNet，再在 EP 输出上运行两层 rank=8 DCNv2，改变交叉与 domain 调制的先后顺序。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](5364c82ad108f241-image.png)

图 21  Dcn_after_ep 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7426 <br> | 0.7400 <br> | 0.8224 <br> | 0.7683 <br> | -0.16 pp <br> |

单头变化：OD -0.30 pp；O -0.04 pp；D -0.13 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.30/-0.04/-0.13 pp，Mean AUC 变化 -0.16 pp。相对标注基线，Mean AUC 下降 0.16 pp。这条路线不再继续扩容，代码只保留作复现和反例。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

### 3.4 FiBiNET 聚合与去 EP 实验

| **实验** <br> | **OD** <br> | **O** <br> | **D** <br> | **Mean** <br> | **对照口径** <br> |
| --- | --- | --- | --- | --- | --- |
| Senet_bilinear_nosacle <br> | 0.7431 <br> | 0.7404 <br> | 0.8212 <br> | 0.7682 <br> | PEP02 特征交叉基线 <br> |
| Senet_bilinear_nosenet <br> | 0.7454 <br> | 0.7416 <br> | 0.8236 <br> | 0.7702 <br> | PEP02 特征交叉基线 <br> |
| Senet_bilinear_fibinet <br> | 0.7452 <br> | 0.7406 <br> | 0.8231 <br> | 0.7696 <br> | PEP02 特征交叉基线 <br> |
| Senet_bilinear_field_f1 <br> | 0.7458 <br> | 0.7414 <br> | 0.8245 <br> | 0.7706 <br> | PEP02 特征交叉基线 <br> |
| Senet_bilinear_field_f2 <br> | 0.7457 <br> | 0.7417 <br> | 0.8243 <br> | 0.7706 <br> | PEP02 特征交叉基线 <br> |
| Senet_bilinear_field_noep <br> | 0.7454 <br> | 0.7416 <br> | 0.8239 <br> | 0.7703 <br> | PEP02 特征交叉基线 <br> |
| Dcn_noep <br> | 0.7445 <br> | 0.7397 <br> | 0.8227 <br> | 0.7690 <br> | PEP02 特征交叉基线 <br> |

**3.4.1  Senet_bilinear_nosacle**

**实验设计：**关闭或移除局部路径，判断当前收益究竟来自哪个模块：移除外层可学习残差缩放，直接使用 field-wise 交叉输出。

![](bc79dee138887fb3-image.png)

图 22  Senet_bilinear_nosacle 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7431 <br> | 0.7404 <br> | 0.8212 <br> | 0.7682 <br> | -0.17 pp <br> |

单头变化：OD -0.25 pp；O +0.00 pp；D -0.25 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.25/+0.00/-0.25 pp，Mean AUC 变化 -0.17 pp。相对标注基线，Mean AUC 下降 0.17 pp。这条路线不再继续扩容，代码只保留作复现和反例。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.4.2  Senet_bilinear_nosenet**

**实验设计：**关闭或移除局部路径，判断当前收益究竟来自哪个模块：FiBiNET 聚合路径关闭 SENet，只保留原始字段交互分支。

![](11e16b0528f0b2fd-image.png)

图 23  Senet_bilinear_nosenet 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7454 <br> | 0.7416 <br> | 0.8236 <br> | 0.7702 <br> | +0.03 pp <br> |

单头变化：OD -0.02 pp；O +0.12 pp；D -0.01 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.02/+0.12/-0.01 pp，Mean AUC 变化 +0.03 pp。相对标注基线，Mean AUC 小幅提高 0.03 pp。差值不大，暂不把它当成稳定收益，需要结合单头变化和重复运行。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.4.3  Senet_bilinear_fibinet**

**实验设计：**只沿交叉路径验证一个具体变化：FiBiNET 风格双分支聚合：原始字段 bilinear 与 SENet 重标定后的 bilinear 共同进入 General。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](f3c7c3d61dfdbc89-image.png)

图 24  Senet_bilinear_fibinet 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7452 <br> | 0.7406 <br> | 0.8231 <br> | 0.7696 <br> | -0.03 pp <br> |

单头变化：OD -0.04 pp；O +0.02 pp；D -0.06 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.04/+0.02/-0.06 pp，Mean AUC 变化 -0.03 pp。相对标注基线，Mean AUC 变化 -0.03 pp，基本持平。现有结果不足以支持继续增加复杂度。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.4.4  Senet_bilinear_field_f1**

**实验设计：**只沿交叉路径验证一个具体变化：FiBiNET 01 聚合实现，保留 SENet；每个字段聚合与其他字段的 Hadamard 交互，不展开全部 pair。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](1014b066478409b8-image.png)

图 25  Senet_bilinear_field_f1 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7458 <br> | 0.7414 <br> | 0.8245 <br> | 0.7706 <br> | +0.07 pp <br> |

单头变化：OD +0.02 pp；O +0.10 pp；D +0.08 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 +0.02/+0.10/+0.08 pp，Mean AUC 变化 +0.07 pp。相对标注基线，Mean AUC 小幅提高 0.07 pp。差值不大，暂不把它当成稳定收益，需要结合单头变化和重复运行。 后续静态交叉优先保留 field 聚合，不再回到全量 pair 展开。

**3.4.5  Senet_bilinear_field_f2**

**实验设计：**只沿交叉路径验证一个具体变化：与 f1 使用相同的 field 聚合骨架，但关闭 SENet；Raw Hadamard 与普通 Bilinear 双分支 concat 40->20。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](286b0b5c47d3f101-image.png)

图 26  Senet_bilinear_field_f2 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7457 <br> | 0.7417 <br> | 0.8243 <br> | 0.7706 <br> | +0.07 pp <br> |

单头变化：OD +0.01 pp；O +0.13 pp；D +0.06 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 +0.01/+0.13/+0.06 pp，Mean AUC 变化 +0.07 pp。相对标注基线，Mean AUC 小幅提高 0.07 pp。差值不大，暂不把它当成稳定收益，需要结合单头变化和重复运行。 后续静态交叉优先保留 field 聚合，不再回到全量 pair 展开。

**3.4.6  Senet_bilinear_field_noep**

**实验设计：**通过删除关键模块验证其独立贡献：在 f1 聚合交叉表示上删除 EP 调制，检查交叉模块是否已吸收 domain 差异。

![](ccf9436faecf3a34-image.png)

图 27  Senet_bilinear_field_noep 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7454 <br> | 0.7416 <br> | 0.8239 <br> | 0.7703 <br> | +0.04 pp <br> |

单头变化：OD -0.02 pp；O +0.12 pp；D +0.02 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.02/+0.12/+0.02 pp，Mean AUC 变化 +0.04 pp。相对标注基线，Mean AUC 小幅提高 0.04 pp。差值不大，暂不把它当成稳定收益，需要结合单头变化和重复运行。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.4.7  Dcn_noep**

**实验设计：**通过删除关键模块验证其独立贡献：两层低秩 DCNv2 对齐版删除 EP 调制。

![](556711eddd3ebbaa-image.png)

图 28  Dcn_noep 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7445 <br> | 0.7397 <br> | 0.8227 <br> | 0.7690 <br> | -0.09 pp <br> |

单头变化：OD -0.11 pp；O -0.07 pp；D -0.10 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.11/-0.07/-0.10 pp，Mean AUC 变化 -0.09 pp。相对标注基线，Mean AUC 变化 -0.09 pp，基本持平。现有结果不足以支持继续增加复杂度。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

### 3.5 Full-rank 与 Full-pair 扩容边界

| **实验** <br> | **OD** <br> | **O** <br> | **D** <br> | **Mean** <br> | **对照口径** <br> |
| --- | --- | --- | --- | --- | --- |
| DCNv2_parallel_fullrank <br> | 0.7436 <br> | 0.7400 <br> | 0.8225 <br> | 0.7687 <br> | PEP02 特征交叉基线 <br> |
| DCnv2_stacked_fullrank <br> | 0.7005 <br> | 0.7207 <br> | 0.7477 <br> | 0.7230 <br> | PEP02 特征交叉基线 <br> |
| Senet_bilinear_fullpair_mean <br> | 0.6623 <br> | 0.6294 <br> | 0.8060 <br> | 0.6992 <br> | PEP02 特征交叉基线 <br> |
| Senet_bilinear_fullpair_20to1 <br> | 0.6681 <br> | 0.6791 <br> | 0.7756 <br> | 0.7076 <br> | PEP02 特征交叉基线 <br> |
| Senet_bilinear_fullpair <br> | 0.7326 <br> | 0.7316 <br> | 0.7956 <br> | 0.7533 <br> | PEP02 特征交叉基线 <br> |

**3.5.1  DCNv2_parallel_fullrank**

**实验设计：**保持主体结构基本不变，检查训练配置或优化策略对结果的影响：论文式 full-rank DCNv2 与原 General 并行，再进入后续 PEP 主干。

![](176b74e78d58795f-image.png)

图 29  DCNv2_parallel_fullrank 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7436 <br> | 0.7400 <br> | 0.8225 <br> | 0.7687 <br> | -0.12 pp <br> |

单头变化：OD -0.20 pp；O -0.04 pp；D -0.12 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.20/-0.04/-0.12 pp，Mean AUC 变化 -0.12 pp。相对标注基线，Mean AUC 下降 0.12 pp。这条路线不再继续扩容，代码只保留作复现和反例。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.5.2  DCnv2_stacked_fullrank**

**实验设计：**保持主体结构基本不变，检查训练配置或优化策略对结果的影响：两层 full-rank DCNv2 串行替换 General；该路径出现大幅退化。

![](097fbbac9276f276-image.png)

图 30 DCnv2_stacked_fullrank 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7005 <br> | 0.7207 <br> | 0.7477 <br> | 0.7230 <br> | -4.69 pp <br> |

单头变化：OD -4.51 pp；O -1.97 pp；D -7.60 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -4.51/-1.97/-7.60 pp，Mean AUC 变化 -4.69 pp。相对标注基线，Mean AUC 下降 4.69 pp。这条路线不再继续扩容，代码只保留作复现和反例。 该失败结果明确排除了 full-rank 串行替换或 full-pair 暴力展开。

**3.5.3  Senet_bilinear_fullpair_mean**

**实验设计：**只沿交叉路径验证一个具体变化：展开所有字段对，对每对 20 维交互做固定 mean 聚合后适配回主干。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](0951c1eb195373c0-image.png)

图 31  Senet_bilinear_fullpair_mean 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.6623 <br> | 0.6294 <br> | 0.8060 <br> | 0.6992 <br> | -7.07 pp <br> |

单头变化：OD -8.33 pp；O -11.10 pp；D -1.77 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -8.33/-11.10/-1.77 pp，Mean AUC 变化 -7.07 pp。相对标注基线，Mean AUC 下降 7.07 pp。这条路线不再继续扩容，代码只保留作复现和反例。 该失败结果明确排除了 full-rank 串行替换或 full-pair 暴力展开。

**3.5.4  Senet_bilinear_fullpair_20to1**

**实验设计：**只沿交叉路径验证一个具体变化：展开所有字段对，把每个 20 维交互压成 1 维后再适配。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](c8025ce089706b82-image.png)

图 32  Senet_bilinear_fullpair_20to1 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.6681 <br> | 0.6791 <br> | 0.7756 <br> | 0.7076 <br> | -6.23 pp <br> |

单头变化：OD -7.75 pp；O -6.13 pp；D -4.81 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -7.75/-6.13/-4.81 pp，Mean AUC 变化 -6.23 pp。相对标注基线，Mean AUC 下降 6.23 pp。这条路线不再继续扩容，代码只保留作复现和反例。 该失败结果明确排除了 full-rank 串行替换或 full-pair 暴力展开。

**3.5.5  Senet_bilinear_fullpair**

**实验设计：**只沿交叉路径验证一个具体变化：131 个字段展开 8515 对；Raw 与 SENet 两分支各保留 20 维，形成 340600 维后经 340600->512->2620 适配。完整版本曾出现显存压力，结果表另保留一次已完成运行。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](59f8eada884b0c02-image.png)

图 33  Senet_bilinear_fullpair 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7326 <br> | 0.7316 <br> | 0.7956 <br> | 0.7533 <br> | -1.66 pp <br> |

单头变化：OD -1.30 pp；O -0.88 pp；D -2.81 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -1.30/-0.88/-2.81 pp，Mean AUC 变化 -1.66 pp。相对标注基线，Mean AUC 下降 1.66 pp。这条路线不再继续扩容，代码只保留作复现和反例。 该失败结果明确排除了 full-rank 串行替换或 full-pair 暴力展开。

### 3.6 后续复验、Seed 与 Binary

| **实验** <br> | **OD** <br> | **O** <br> | **D** <br> | **Mean** <br> | **对照口径** <br> |
| --- | --- | --- | --- | --- | --- |
| dcnv2 <br> | 0.7394 <br> | 0.7376 <br> | 0.8132 <br> | 0.7634 <br> | 同期 PEP01 基线；仅作阶段参考 <br> |
| fibinet <br> | 0.7439 <br> | 0.7397 <br> | 0.8210 <br> | 0.7682 <br> | 同期 PEP01 基线；仅作阶段参考 <br> |
| dcnv2更新seed顺序 <br> | 0.7394 <br> | 0.7371 <br> | 0.8154 <br> | 0.7640 <br> | 同期 PEP01 基线；仅作阶段参考 <br> |
| fibinet更新seed顺序 <br> | 0.7441 <br> | 0.7397 <br> | 0.8216 <br> | 0.7685 <br> | 同期 PEP01 基线；仅作阶段参考 <br> |
| dcnv2-binary <br> | 0.7424 <br> | 0.7390 <br> | 0.8185 <br> | 0.7666 <br> | 同期 PEP01 基线；仅作阶段参考 <br> |
| fibinet-binary <br> | 0.7441 <br> | 0.7400 <br> | 0.8215 <br> | 0.7685 <br> | 同期 PEP01 基线；仅作阶段参考 <br> |

**3.6.1  dcnv2**

**实验设计：**只沿交叉路径验证一个具体变化：另一阶段的 DCNv2 主干/对照记录；与 PEP02_DCNv2 不是同名同配置。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](fb52317b7dee2b52-image.png)

图 34  dcnv2 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7394 <br> | 0.7376 <br> | 0.8132 <br> | 0.7634 <br> | -0.65 pp <br> |

单头变化：OD -0.62 pp；O -0.28 pp；D -1.05 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.62/-0.28/-1.05 pp，Mean AUC 变化 -0.65 pp。相对标注基线，Mean AUC 下降 0.65 pp。这条路线不再继续扩容，代码只保留作复现和反例。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.6.2  fibinet**

**实验设计：**只沿交叉路径验证一个具体变化：另一阶段的 FiBiNET 主干/对照记录。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](79b3b0b8ef3db38c-image.png)

图 35  fibinet 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7439 <br> | 0.7397 <br> | 0.8210 <br> | 0.7682 <br> | -0.17 pp <br> |

单头变化：OD -0.17 pp；O -0.07 pp；D -0.27 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.17/-0.07/-0.27 pp，Mean AUC 变化 -0.17 pp。相对标注基线，Mean AUC 下降 0.17 pp。这条路线不再继续扩容，代码只保留作复现和反例。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.6.3  dcnv2更新seed顺序**

**实验设计：**保持主体结构基本不变，检查训练配置或优化策略对结果的影响：保持 DCNv2 结构，修正或统一 seed 设置顺序后重跑。

![](a1667529d2e82c99-image.png)

图 36  dcnv2更新seed顺序 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7394 <br> | 0.7371 <br> | 0.8154 <br> | 0.7640 <br> | -0.59 pp <br> |

单头变化：OD -0.62 pp；O -0.33 pp；D -0.83 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.62/-0.33/-0.83 pp，Mean AUC 变化 -0.59 pp。相对标注基线，Mean AUC 下降 0.59 pp。这条路线不再继续扩容，代码只保留作复现和反例。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.6.4  fibinet更新seed顺序**

**实验设计：**保持主体结构基本不变，检查训练配置或优化策略对结果的影响：保持 FiBiNET 结构，修正或统一 seed 设置顺序后重跑。

![](cde7f19fb8b26fcf-image.png)

图 37  fibinet更新seed顺序 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7441 <br> | 0.7397 <br> | 0.8216 <br> | 0.7685 <br> | -0.14 pp <br> |

单头变化：OD -0.15 pp；O -0.07 pp；D -0.21 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.15/-0.07/-0.21 pp，Mean AUC 变化 -0.14 pp。相对标注基线，Mean AUC 下降 0.14 pp。这条路线不再继续扩容，代码只保留作复现和反例。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.6.5  dcnv2-binary**

**实验设计：**只沿交叉路径验证一个具体变化：在 DCNv2 路径中显式加入 binary domain 信息。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](c2292113cc4e9799-image.png)

图 38  dcnv2-binary 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7424 <br> | 0.7390 <br> | 0.8185 <br> | 0.7666 <br> | -0.33 pp <br> |

单头变化：OD -0.32 pp；O -0.14 pp；D -0.52 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.32/-0.14/-0.52 pp，Mean AUC 变化 -0.33 pp。相对标注基线，Mean AUC 下降 0.33 pp。这条路线不再继续扩容，代码只保留作复现和反例。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

**3.6.6  fibinet-binary**

**实验设计：**只沿交叉路径验证一个具体变化：在 FiBiNET 路径中显式加入 binary domain 信息。目标是在不破坏 PEP 主干和双域路由的前提下提高 AUC。

![](61093f10d3f766e6-image.png)

图 39  fibinet-binary 的完整结构与本次改动

| **OD AUC** <br> | **O AUC** <br> | **D AUC** <br> | **Mean AUC** <br> | **Mean 对照差** <br> |
| --- | --- | --- | --- | --- |
| 0.7441 <br> | 0.7400 <br> | 0.8215 <br> | 0.7685 <br> | -0.14 pp <br> |

单头变化：OD -0.15 pp；O -0.04 pp；D -0.22 pp。

**结果分析：**相对 PEP01_loss_1e-4，OD/O/D 分别变化 -0.15/-0.04/-0.22 pp，Mean AUC 变化 -0.14 pp。相对标注基线，Mean AUC 下降 0.14 pp。这条路线不再继续扩容，代码只保留作复现和反例。 它帮助确定交叉的输入范围、插入位置和容量边界，后续只保留有解释力的聚合方式。

## 
