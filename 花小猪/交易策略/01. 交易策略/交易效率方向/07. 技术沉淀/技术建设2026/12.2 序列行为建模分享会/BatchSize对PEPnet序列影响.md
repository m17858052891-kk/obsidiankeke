---
title: "BatchSize对PEPnet序列影响"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2207265751646
---

# BatchSize对PEPnet序列影响


**验证集不完整且未对齐！修改了验证集的BatchSize且只验证了一个BatchSize!** 

**结论不可信**

|  <br>模型 <br> | Batch_size<!--评论:[{"u":"dongtingdong","c":"不仅修改了训练集，也同步修改了验证集BatchSize，且只验证了一个step"}] --> <br> | 训练曲线 <br> |
| --- | --- | --- |
| PEPnet模型 <br> <br>序列特征Positional Selfattn   <br> <br>learning_rate=0.0001 <br> | 128 <br> | ![](fb2813b65ccafcdb-image.png) <br> |
| 256 <br> | ![](78d768cff45e4916-3e02d518ca9945f45e2fc463114e02ed.png) <br> |
| 512 <br> | ![](755533ddeb372c46-image.png) <br> |
| 1024 <br> | ![](b191735d3994da1c-image.png) <br> |

# 对比实验

**结论: BatchSize对效果无显著影响！**

| 模型结构 <br> |   <br> | batch_size <br> | auc_od <br> | auc_o <br> | auc_d <br> |
| --- | --- | --- | --- | --- | --- |
| PEPNet+PosSelfAttention <br>  <br> | baseline（无序列特征） <br> | 1024 <br> | 0.7765 <br> | 0.7630 <br> | 0.8571 <br> |
| 加入序列特征 <br> | 1024 <br> | 0.7903 <br> | 0.7652 <br> | 0.8739 <br> |
| 512 <br> | 0.7891 <br> | 0.7654 <br> | 0.8742 <br> |
| 256 <br> | 0.7833 <br> | 0.7619 <br> | 0.8647 <br> |
| 128 <br> | 0.7817 <br> | 0.7593 <br> | 0.8714 <br> |

‍
