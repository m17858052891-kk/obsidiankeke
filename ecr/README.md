# ECR：多档补贴 Uplift 排序

本项目的目标不是找「最可能呼叫」的用户，而是找「因补贴而新增呼叫概率最高」的用户，并在控制补贴风险的前提下提升 Call AUCC。

## 结论先读

最终推荐方案为 **CFR + TwoStage + calibrated PU-Corr + matched pairwise + progressive soft-unfreeze（H2 Soft T2）**：先用 factual response 训练得到稳定的多档位响应锚点；再温和引入直接面向 uplift 排序的损失。选择它不是因为离线 AUCC 最高，而是它在候选中兼顾了 Call MTAUCC 与 Qini treatment-ratio 的稳定性。

## 文档导航

1. [Qini 人群结构与 Treatment Ratio](01_Qini人群结构与TreatmentRatio.md)
2. [RankLoss 与 Pairwise Loss 构造](02_RankLoss与PairwiseLoss构造.md)
3. [项目简单概述逐字稿](03_项目简单概述逐字稿.md)
4. [模型全部损失函数](04_模型全部损失函数.md)
5. [CFR 模型结构与输出塔](05_CFR模型结构与输出塔.md)
6. [AUCC、AUUC、Qini 区别](06_AUCC_AUUC_Qini区别.md)
7. [新损失函数为何有效](07_新损失函数为何有效.md)
8. [模型局限与后续迭代](08_模型局限与后续迭代.md)
9. [最难问题：Treatment Ratio 失衡](09_最难问题_TreatmentRatio失衡.md)
10. [Z-score 与温度系数](10_Zscore与温度系数.md)
11. [补充深挖：实验细节与项目边界](11_补充深挖_实验细节与项目边界.md)

## 使用边界

文档中的实验数字只描述已有离线实验。线上流量、收益和策略效果若没有对应实验记录，均应表述为上线验证方案，不应作为既有事实。
