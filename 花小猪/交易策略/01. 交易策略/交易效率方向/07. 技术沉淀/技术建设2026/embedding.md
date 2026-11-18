---
title: "embedding"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2207393714430
---

# embedding

<https://ether-nmg.intra.hongyibo.com.cn/labs/new/15203>

[https://datamap.didichuxing.com/detail?uri=hive://mycluster-tj:kflower_strategy:h2d_cancel_sequential_passenger_avg  ](https://datamap.didichuxing.com/detail?uri=hive://mycluster-tj:kflower_strategy:h2d_cancel_sequential_passenger_avg)[https://datamap.didichuxing.com/detail?uri=hive://mycluster-tj:kflower_strategy:h2d_cancel_sequential_driver_avg](https://datamap.didichuxing.com/detail?uri=hive://mycluster-tj:kflower_strategy:h2d_cancel_sequential_driver_avg)

[https://ether.intra.hongyibo.com.cn/labs/new/15171](https://ether.intra.hongyibo.com.cn/labs/new/15171)

![](4c2b9d0370dab84d-image.png)

# **Embeddings  嵌入**

Extract latent feature representations from TabPFN models.

The [Embeddings](https://github.com/PriorLabs/tabpfn-extensions/tree/main/src/tabpfn_extensions/embedding) extension enables extraction of **latent feature representations** (embeddings) from TabPFN models. These embeddings provide a way to analyze, visualize, or reuse the learned representations produced by TabPFN’s transformer architecture - useful for downstream tasks such as clustering, feature analysis, search, or meta-learning. [嵌入](https://github.com/PriorLabs/tabpfn-extensions/tree/main/src/tabpfn_extensions/embedding)扩展使得从 TabPFN 模型中提取**潜在特征表示** （嵌入）成为可能。这些嵌入提供了分析、可视化或重用 TabPFN 变换器架构所学到表示的方式——适用于后游任务，如聚类、特征分析、搜索或元学习。

[PEPModel](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html) 中接入 `OneTrans` 的思路是：**先分别编码乘客序列和司机序列，再与非序列特征融合后进入** [EPNet/PPNet](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html)。

1. 接入入口 在 [model.py](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html) 里，[PEPModel](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html) 先定义两套 `OneTrans` 编码器：[self.otb_pas](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html) 和 [self.otb_driver](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html)，分别处理乘客序列与司机序列。

- 序列预处理 在 [forward()](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html) 中，把 [x_seq_pas](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html)、[x_seq_driver](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html) 从平铺向量 reshape 为 [(B, 10, 10)](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html)，并通过 [channel_norm()](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html) 做按通道归一化。

- 投射到统一维度 用 [self.in_proj_pas](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html)、[self.in_proj_driver](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html) 将序列特征映射到 [d_embed](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html) 维，得到可送入 `OneTrans` 的序列 embedding。

- 与非序列上下文拼接 将 [x_s2v](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html)（dense/serial/nonserial 的 `Scalar2Vec` 结果）分别与两路序列拼接，形成 [cat_pas](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html)、[cat_driver](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html)，再分别输入 [self.otb_pas](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html)、[self.otb_driver](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html)。

- 截取序列输出并融合 `OneTrans` 输出后，按 [ns_len](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html) 截取后 10 个时间步得到 [seq_pas_emb](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html)、[seq_driver_emb](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html)，再与 [x_s2v](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html) 拼接成 [x_s2v_all](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html)，作为后续 [EPNet](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html) 和三路 [PPNet](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html) 的输入。

- `OneTrans` 内部做了什么 在 [onetrans.py](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html) 中，[MultiOneTransBlock](vscode-file://vscode-app/Applications/Visual%20Studio%20Code%202.app/Contents/Resources/app/out/vs/code/electron-browser/workbench/workbench.html) 负责：

- 显式可学习位置编码；

- 因果掩码注意力；

- 残差 + FFN；

- 多层串联堆叠。

## 实验

![](d14e8daaaf9fe04f-image.png)

## 实验是否是司机序列和乘客序列一起交叉有问题

==写一个新模型以pep为基础，去掉pep中的乘客序列特征，然后用onetrans做特征交叉做个实验==

![](e664ec6d4082a60f-image.png)

## 实验是否单独的onetrans即可替代其他的模块

拿掉ple

拿掉pep

直接输出开三个头

## 由于混合特征比较高阶难以理解，即有普通特征以及司机和乘客的特征

对于塔进行加深
