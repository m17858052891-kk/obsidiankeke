---
title: "PLE-序列建模"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2209739445174
---

# PLE-序列建模

利用onetrans模块对序列特征进行编码，融入expert c特征。

| 模型 <br> | od_auc <br> | o_auc <br> | d_auc <br> |
| --- | --- | --- | --- |
| PLE引入序列特征前最高版本 <br> | 0.7445 <br> | 0.7417 <br> | 0.8203 <br> |
| 引入序列特征 <br> | 0.7500 <br> | 0.7493 <br> | 0.8221 <br> |
| 修改loss，使用有效样本数-训练3epoch <br> | 0.7523 <br> | 0.7515 <br> | 0.8243 <br> |
| 修改poso分桶-训练3epoch <br> | 0.7538 <br> | 0.7527 <br> | 0.8271 <br> |
