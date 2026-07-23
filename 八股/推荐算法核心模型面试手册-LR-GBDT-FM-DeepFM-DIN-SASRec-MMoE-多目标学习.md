---
tags:
  - 八股
  - 推荐系统
  - LR
  - GBDT
  - FM
  - DeepFM
  - DIN
  - SASRec
  - MMoE
  - 多任务学习
  - 多目标学习
created: 2026-07-23
---

# 推荐算法核心模型面试手册：LR、GBDT、FM、DeepFM、DIN、SASRec、MMoE 与多目标学习

## 1. 先用一两句话说明它们分别是什么

| 模型/主题 | 一到两句话定义 |
|---|---|
| LR | Logistic Regression 是一个线性二分类模型：先对特征做加权求和，再通过 Sigmoid 输出正样本概率。它本身只能学习线性决策边界，效果高度依赖人工特征和显式特征交叉，但训练稳定、可解释、易部署。 |
| GBDT | Gradient Boosting Decision Tree 是把多棵回归树按加法方式串行叠加，每一棵新树拟合当前模型在损失函数上的负梯度。它擅长自动学习非线性阈值和高阶特征组合，尤其适合结构化表格数据。 |
| FM | Factorization Machine 在 LR 的一阶项上加入所有特征两两交叉，并用低维向量内积表示交叉权重。它能在高维稀疏场景中让没有充分共现的特征组合共享参数，是矩阵分解向任意稀疏特征的推广。 |
| DeepFM | DeepFM 同时使用 FM 分支学习一阶、二阶显式交叉，使用 DNN 分支学习隐式高阶交叉，两条分支共享同一套 Embedding。它避免了 Wide&Deep 对人工 Wide 特征的强依赖。 |
| DIN | Deep Interest Network 针对当前候选物品，对用户历史行为做 Target-aware Attention，动态提取与候选相关的兴趣。它解决了固定池化把用户所有兴趣压成同一个向量的问题。 |
| SASRec | Self-Attentive Sequential Recommendation 使用带因果 Mask 的 Transformer Self-Attention 编码行为序列，通过位置表示和 Next-item Prediction 学习序列依赖。它能并行训练并捕捉不同距离的行为关系，但 Dense Attention 对序列长度是二次复杂度。 |
| MMoE | Multi-gate Mixture-of-Experts 让多个任务共享一组 Expert，但每个任务用自己的 Gate 选择不同的 Expert 组合。它比 Shared Bottom 更灵活，能够在共享知识的同时缓解任务之间的负迁移。 |
| 多任务学习 | Multi-task Learning 是一个模型同时预测多个相关任务，每个任务通常有自己的标签、Loss 和输出头，通过共享参数提高数据利用率和泛化能力。核心难点是任务相关性、梯度冲突和样本空间不一致。 |
| 多目标学习 | Multi-objective Learning/Optimization 是同时优化多个可能冲突的业务目标，例如点击、时长、转化、收入和成本。它不只关心如何共享模型参数，还要决定各目标如何权衡、约束以及最终如何形成决策。 |

### 30 秒演进主线

```text
LR：线性加权，依赖人工交叉
 ├─ GBDT：用树自动学习非线性规则和组合
 └─ FM：用低秩内积学习稀疏二阶交叉
        └─ DeepFM：FM 显式低阶 + DNN 隐式高阶

用户兴趣建模：
DIN：候选感知地从历史中挑相关兴趣
SASRec：候选无关地先编码行为序列的时序演化

多任务/多目标：
Shared Bottom：所有任务硬共享
MMoE：任务通过独立 Gate 选择共享 Expert
PLE：进一步拆 Shared Expert 与 Task-specific Expert
多目标优化：在预测之后或端到端训练中处理业务目标权衡
```

---

## 2. LR：推荐系统最经典的线性基线

### 2.1 模型公式

输入 $x\in\mathbb R^d$，LR 先计算 Logit：

$$
z=w^Tx+b
$$

再通过 Sigmoid 得到概率：

$$
\hat p=P(Y=1\mid x)=\sigma(z)=\frac{1}{1+e^{-z}}
$$

训练通常使用 Binary Cross Entropy：

$$
\mathcal L
=-\sum_i\left[y_i\log\hat p_i+(1-y_i)\log(1-\hat p_i)\right]
$$

### 2.2 为什么叫“回归”，却用于分类？

LR 回归的是正类概率的 Log Odds：

$$
\log\frac{p}{1-p}=w^Tx+b
$$

模型输出连续概率，再通过阈值完成分类，因此名字中有 Regression。

### 2.3 LR 在推荐系统里怎么做特征交叉？

原始 LR 只有：

$$
w_1x_1+w_2x_2
$$

如果希望学习“男性 × 篮球”这一组合，需要人工构造新特征：

$$
x_{male\_basketball}=x_{male}\cdot x_{basketball}
$$

然后为它学习独立权重。问题是交叉组合数爆炸，而且长尾组合样本不足。

### 2.4 高频面试问答

#### Q：为什么 LR 适合 CTR 预估？

> CTR 是二分类概率预测，LR 的 Sigmoid 输出天然落在 $[0,1]$；模型简单、收敛稳定、易解释，支持大规模稀疏特征和在线增量训练，因此长期作为广告推荐的重要基线。

#### Q：LR 的优缺点是什么？

> 优点是简单、稳定、可解释、训练和推理成本低，概率通常较易校准。缺点是表达能力线性，复杂特征交互必须人工构造，对非线性阈值和高阶组合建模不足。

#### Q：为什么使用 LogLoss，而不是 MSE？

> LR 基于 Bernoulli 分布做最大似然估计，负对数似然正好是 LogLoss；它对高置信度错误惩罚更强。MSE 配合 Sigmoid 容易在饱和区产生更弱梯度，也不对应标准 Bernoulli 最大似然目标。

#### Q：L1 和 L2 正则有什么区别？

> L1 倾向产生稀疏权重，可用于特征选择；L2 连续缩小权重，优化更平滑，对共线特征通常更稳定。工业稀疏 LR 也常使用 Elastic Net 或 FTRL-Proximal 同时获得稳定性和稀疏性。

#### Q：样本极度不平衡怎么办？

> 可以负采样、设置正负样本权重或使用 Focal Loss，但训练分布变化后输出概率不再天然等于线上真实概率，需要做采样率修正或 Calibration。AUC 对类别比例不敏感，但 LogLoss、Precision、概率阈值会受影响。

#### Q：LR 的时间复杂度是多少？

> 单样本前向约为 $O(nnz(x))$，其中 $nnz$ 是非零特征数；稀疏实现不需要遍历完整特征空间。参数量约等于特征维度加一个 Bias。

### 2.5 易错点

- LR 的决策边界对输入特征是线性的，但经过人工非线性变换或交叉后，对原始变量可以表现为非线性。
- AUC 高不代表概率校准好；排序和概率准确性是两个问题。
- 负采样后不能直接把模型输出当作真实 CTR。

---

## 3. GBDT：结构化数据中的非线性规则学习器

### 3.1 核心思想

GBDT 是加法模型：

$$
F_M(x)=\sum_{m=1}^{M}\eta f_m(x)
$$

第 $m$ 棵树拟合当前损失对模型输出的负梯度：

$$
r_{im}=-\left[\frac{\partial L(y_i,F(x_i))}{\partial F(x_i)}\right]_{F=F_{m-1}}
$$

在平方误差下，负梯度就是残差 $y_i-F_{m-1}(x_i)$；在分类任务中，它是损失在 Logit 空间的梯度，不应简单说成“每棵树永远拟合残差”。

### 3.2 GBDT 为什么能自动做特征交叉？

一条树路径天然表示多条件组合：

```text
活跃度 > 5
  └─ 客单价 > 100
       └─ 城市 = 一线
```

叶节点相当于一个高阶分段规则。因此 GBDT 不需要像 LR 那样枚举所有交叉特征。

### 3.3 GBDT + LR 是怎么做的？

先训练 GBDT，再把每棵树落到的叶节点编码成 One-hot：

```text
原始特征 → GBDT → 每棵树的 Leaf ID → One-hot → LR
```

GBDT 负责自动发现非线性组合，LR 负责给这些组合做线性加权。这是深度推荐模型普及前非常经典的 CTR 方案。

### 3.4 GBDT、XGBoost、LightGBM 的关系

> GBDT 是 Boosting Tree 的算法范式；XGBoost 和 LightGBM 是带有大量工程、正则与分裂优化的具体实现。不能把三者当成互斥的同级概念。

- XGBoost：二阶梯度近似、显式正则、列采样、缺失值方向、并行候选分裂等。
- LightGBM：Histogram、Leaf-wise 生长、GOSS、EFB 等，更关注大规模效率。

### 3.5 高频面试问答

#### Q：GBDT 为什么是串行训练？

> 后一棵树的训练目标依赖前面模型的当前预测和梯度，因此树与树之间是串行的；但单棵树内部的特征扫描、样本统计和候选分裂可以并行。

#### Q：GBDT 和 Random Forest 有什么区别？

> Random Forest 是 Bagging：树之间可并行，主要通过样本和特征随机化降低方差；GBDT 是 Boosting：树串行拟合当前错误，主要逐步降低偏差。RF 通常对噪声更稳，GBDT 往往在表格监督任务上精度更强但更需调参。

#### Q：GBDT 怎么防止过拟合？

> 控制树深、叶节点数、最小叶样本，减小学习率并增加树数，使用行/列采样、早停和正则项。Leaf-wise 算法尤其要限制深度或叶节点最小数据量。

#### Q：树模型为什么不需要特征归一化？

> 决策树依据特征排序和阈值切分，单调缩放通常不改变样本的排序关系，因此不像基于距离或梯度尺度的模型那样依赖标准化。

#### Q：GBDT 能直接处理类别特征吗？

> 原始 GBDT 通常需要数值编码；One-hot、Target Encoding 都可使用，但要防止泄漏。CatBoost、LightGBM 对类别特征有专门机制，具体能力取决于实现而不是“所有 GBDT 天生支持类别特征”。

#### Q：GBDT 的复杂度怎么说？

> 复杂度依赖建树算法。粗略地说，$M$ 棵树、$N$ 个样本、每次考虑 $D'$ 个特征、深度 $H$ 时，训练成本与 $MND'H$ 同阶；Histogram 会把连续取值压成有限 Bin。单样本推理约为 $O(MH)$。

### 3.6 易错点

- “GBDT 每棵树拟合残差”只在平方误差下最直观，通用说法是拟合负梯度。
- Feature Importance 高不等于因果重要性。
- Target Encoding 必须使用 OOF/时间切分，不能把当前样本标签泄漏进特征。

---

## 4. FM：高维稀疏场景的低秩二阶交叉

### 4.1 模型公式

$$
\hat y(x)=w_0+\sum_{i=1}^{n}w_ix_i
+\sum_{i<j}\langle v_i,v_j\rangle x_ix_j
$$

其中：

- $w_i$：一阶权重；
- $v_i\in\mathbb R^k$：第 $i$ 个特征的隐向量；
- $\langle v_i,v_j\rangle$：特征 $i,j$ 的二阶交叉权重。

### 4.2 为什么比直接学习交叉权重好？

直接为每对特征学习 $w_{ij}$ 需要 $O(n^2)$ 个参数，并且长尾组合缺少共现样本。FM 使用：

$$
w_{ij}=\langle v_i,v_j\rangle
$$

将交叉矩阵做低秩分解，只需 $O(nk)$ 参数。即使特征 $i$ 与 $j$ 很少一起出现，它们也能通过与其他特征的共现更新各自 Embedding，获得可泛化的交叉权重。

### 4.3 二阶项如何从 $O(n^2k)$ 降到 $O(nk)$？

利用恒等式：

$$
\sum_{i<j}\langle v_i,v_j\rangle x_ix_j
=\frac12\sum_{f=1}^{k}
\left[
\left(\sum_i v_{if}x_i\right)^2
-\sum_i(v_{if}x_i)^2
\right]
$$

### 4.4 FM 和矩阵分解是什么关系？

矩阵分解为用户、物品学习向量：

$$
\hat y_{ui}=b+b_u+b_i+p_u^Tq_i
$$

如果 FM 的输入只有一个 User ID One-hot 和一个 Item ID One-hot，那么其二阶项就是用户向量与物品向量内积。因此：

> MF 是特定 user-item 交互；FM 将同一低秩内积思想推广到任意稀疏特征之间。

### 4.5 高频面试问答

#### Q：FM 为什么适合推荐和广告？

> 这些场景有大量 User ID、Item ID、Category 等高维稀疏特征，很多组合共现不足。FM 通过 Embedding 内积共享统计强度，能稳定学习二阶交叉。

#### Q：FM 的不足是什么？

> 标准 FM 主要学习二阶交叉，且所有特征交叉都使用同一种内积形式，无法灵活建模高阶、强非线性或不同 Field 语义。后续 FFM、DeepFM、xDeepFM 等分别增强 Field 感知或高阶交互。

#### Q：FM 与 Polynomial LR 有什么区别？

> Polynomial LR 为每个交叉项学习独立参数；FM 用低秩向量内积生成交叉参数，因此参数更少，并能在稀疏共现下泛化。

#### Q：FM 的 Embedding 和神经网络 Embedding 一样吗？

> 参数形态相似，都是特征 ID 对应的低维向量；FM 通过向量内积直接定义二阶交叉权重，而神经网络中的 Embedding 还可以进入 MLP、Attention 等更复杂模块。

---

## 5. DeepFM：显式低阶交叉与隐式高阶交叉

### 5.1 架构

```text
                         ┌─ FM 一阶 + 二阶 ─┐
Sparse Features → Shared Embedding          ├─ Logit → Sigmoid
                         └─ 拼接 → DNN ─────┘
```

最终：

$$
\hat y=\sigma(y_{FM}+y_{DNN})
$$

### 5.2 FM 分支做什么？

- 一阶项：$\sum_iw_ix_i$；
- 二阶项：$\sum_{i<j}\langle v_i,v_j\rangle x_ix_j$；
- 显式保证模型具备一阶与二阶交叉能力。

### 5.3 DNN 分支做什么？

把各 Field Embedding 拼接：

$$
h_0=[e_1;e_2;\ldots;e_F]
$$

再经过 MLP：

$$
h_{l+1}=\phi(W_lh_l+b_l)
$$

DNN 学习隐式高阶、非线性交互，但不能把“第几层”机械等同于“几阶交叉”。

### 5.4 为什么共享 Embedding？

> FM 与 DNN 使用同一套特征 Embedding，可以让低阶和高阶目标共同更新参数，减少参数量，避免两个分支学出完全割裂的特征空间。

但共享也可能造成梯度冲突；在复杂工业模型中，有时会使用部分共享、独立投影或 Field-specific Embedding。

### 5.5 高频面试问答

#### Q：DeepFM 相比 FM 改进了什么？

> FM 只显式建模一阶和二阶交叉；DeepFM 增加 DNN 分支学习高阶非线性交互，同时保留 FM 在稀疏二阶交叉上的稳定归纳偏置。

#### Q：DeepFM 和 Wide&Deep 有什么区别？

> Wide&Deep 的 Wide 分支通常依赖人工选择的 Cross-product 特征；DeepFM 用 FM 自动学习全部二阶交叉，减少人工特征工程。两者都有 Deep 分支学习高阶泛化。

#### Q：DeepFM 和 DCN 有什么区别？

> DeepFM 的显式部分主要是二阶 FM，DNN 高阶交叉是隐式的；DCN 的 Cross Network 通过特定递推形式显式构造有界阶数的特征交叉。DCNv2 又用矩阵/低秩专家增强了交叉表达力。

#### Q：DeepFM 为什么不只用 MLP？

> 理论上 MLP 能逼近二阶交叉，但在高维稀疏、小共现数据中不一定容易学到。FM 分支把二阶低秩交互作为明确归纳偏置，通常更省样本、更稳定。

#### Q：DeepFM 的参数量和复杂度？

> Embedding 参数通常占大头，约为各稀疏表词表大小乘 Embedding 维度；FM 二阶计算约 $O(Fk)$，DNN 取决于拼接维度和各层宽度。参数量大不等于 FLOPs 高，大 Embedding 往往更偏内存与通信瓶颈。

### 5.6 易错点

- DeepFM 的 FM 分支不是把所有 Embedding 先拼接再过 MLP。
- “显式交叉”指公式明确规定二阶结构，不代表每个特征对有独立参数。
- 输出前通常应合并 Logit，再统一 Sigmoid，而不是分别 Sigmoid 后相加。

---

## 6. DIN：候选感知的用户兴趣提取

### 6.1 DIN 解决什么问题？

传统方法对历史行为做 Sum/Mean Pooling：

$$
u=\frac1L\sum_{j=1}^{L}e_j
$$

无论当前候选是篮球鞋还是手机，用户向量都一样。DIN 认为用户兴趣是多峰的，当前应该激活哪部分兴趣取决于候选物品。

### 6.2 核心公式

设候选 Embedding 为 $e_c$，第 $j$ 个历史行为为 $e_j$：

$$
a_j=f_{att}(e_j,e_c)
$$

常见输入组合为：

$$
[e_j,e_c,e_j-e_c,e_j\odot e_c]
$$

再加权聚合：

$$
u(c)=\sum_{j=1}^{L}a_je_j
$$

最终将 $u(c)$、候选、用户画像和上下文特征送入 MLP 预测 CTR。

### 6.3 DIN 的权重一定要 Softmax 吗？

> 不一定。原始 DIN 的 Local Activation Unit 更强调每个行为与候选的相关强度，权重不必像标准 Attention 一样在序列维归一化为和等于 1。这样可以保留“相关行为数量/强度”信息。

工程实现可以使用 Sigmoid、Softmax 或未归一化权重，但应讲清语义和数值稳定性。

### 6.4 DIN 是否建模行为顺序？

> 原始 DIN 的核心是候选感知加权，本身不显式建模严格序列顺序。若没有时间、位置或序列模块，交换历史行为顺序通常不会改变聚合结果。DIEN、SASRec 等进一步建模兴趣演化或序列依赖。

### 6.5 高频面试问答

#### Q：DIN 为什么有效？

> 用户兴趣具有多样性，固定用户向量会把无关兴趣混在一起。DIN 让每个候选生成自己的用户兴趣表示，减少无关历史噪声，强化候选相关行为。

#### Q：DIN 和普通 Attention 有什么区别？

> DIN 的 Query 是候选商品，Key/Value 是用户历史行为，目标是候选感知兴趣聚合；它的 Local Activation Unit 常用 MLP 直接建模候选与行为的组合特征，而且权重不一定做 Softmax 归一化。

#### Q：DIN 的计算复杂度是多少？

> 对单个候选，需要与长度 $L$ 的每个历史行为计算相关性，主要是 $O(Ld)$ 加上 Attention MLP 成本。若同一用户有 $C$ 个候选且逐候选计算，成本近似为 $O(CLd)$，候选多时要做批量矩阵化、历史缓存或两阶段召排。

#### Q：Padding 怎么处理？

> 必须用 Length/Mask 将 Padding 行为的权重置零。只把 Padding Embedding 设零仍不总是安全，因为 Attention MLP 的 Bias 可能产生非零分数。

#### Q：DIN 的用户表示能否离线缓存？

> 完整的 $u(c)$ 依赖候选，不能为用户缓存一个对所有候选通用的最终向量；但历史 Embedding、部分投影和候选无关特征可以缓存。

#### Q：DIN 中的 Dice 是什么？

> Dice 是 Data-adaptive Activation，根据输入分布自适应控制线性与缩放分支，思想类似数据依赖的 PReLU。它不是 DIN target attention 的必要条件，工程上常被 PReLU、SiLU 等替代。

### 6.6 易错点

- DIN 不是严格的时序模型。
- Attention 权重不等于因果贡献，也不一定具有稳定可解释性。
- 候选相关计算提升表达力，也增加多候选推理成本。

---

## 7. SASRec：基于因果 Self-Attention 的序列推荐

### 7.1 输入与目标

用户行为序列：

$$
[i_1,i_2,\ldots,i_L]
$$

每个位置输入由 Item Embedding 和 Positional Embedding 相加：

$$
h_t^{(0)}=e_{i_t}+p_t
$$

模型在位置 $t$ 使用前缀行为预测下一个物品 $i_{t+1}$。

### 7.2 为什么使用 Causal Mask？

训练时所有位置并行预测，但位置 $t$ 不能看到未来行为：

$$
M_{t,j}=
\begin{cases}
0,&j\le t\\
-\infty,&j>t
\end{cases}
$$

这避免标签泄漏，并保持训练与自回归推理语义一致。

### 7.3 模型结构

每层通常包含：

1. Multi-Head/Causal Self-Attention；
2. Residual + LayerNorm；
3. Position-wise FFN；
4. Residual + LayerNorm。

位置 $t$ 的隐状态 $h_t$ 与候选 Item Embedding 做点积或经过打分网络：

$$
s(i\mid h_t)=h_t^Te_i
$$

训练常使用负采样 BCE、Sampled Softmax 或全量 Softmax。

### 7.4 SASRec 和 DIN 的区别

| 维度 | DIN | SASRec |
|---|---|---|
| 核心问题 | 当前候选与哪些历史行为相关 | 行为序列如何随时间演化 |
| Query | 候选 Item | 序列中每个位置 |
| 顺序建模 | 原始模型较弱 | 位置编码 + Causal Mask |
| 用户表示 | 每个候选不同 | 可先得到候选无关的序列状态 |
| 复杂度 | 单候选约 $O(Ld)$ | Dense Attention 约 $O(L^2d)$ |
| 多候选服务 | 候选相关计算较重 | 序列表示可缓存，再与候选打分 |

二者可以组合：先用 SASRec 编码时序状态，再用候选 Cross-Attention/DIN 对历史或多尺度状态做目标感知聚合。

### 7.5 SASRec 和 BERT4Rec 的区别

> SASRec 使用单向 Causal Attention 做 Next-item Prediction；BERT4Rec 使用双向 Attention，通过随机 Mask Item 恢复被遮盖物品。SASRec 训练目标与在线前缀预测更一致，BERT4Rec 能利用左右上下文但训练—推理目标存在一定差异。

### 7.6 高频面试问答

#### Q：SASRec 为什么比 RNN 更适合长依赖？

> Self-Attention 让任意两个位置的交互路径长度为 1，更容易捕捉远距离依赖；训练可以并行处理所有位置，而 RNN 必须按时间步串行。但 Self-Attention 的显存和计算随长度平方增长。

#### Q：SASRec 的时间复杂度？

> 单层主要为 $O(BL^2d+BLd^2)$；Attention 矩阵带来 $O(BL^2)$ 级别显存。短序列时 FFN/投影的 $Ld^2$ 也可能占主导。

#### Q：为什么需要位置编码？

> 不加位置编码时 Self-Attention 对输入排列本质上是置换等变的，无法区分点击顺序。位置表示为行为注入先后关系；实际推荐还可以加入时间间隔、行为类型等 Bias。

#### Q：负采样有什么风险？

> 随机负样本太容易，模型可能只学会区分热门与无关物品；曝光未点击、同类 Hard Negative 更有信息，但也可能包含用户实际喜欢但没反馈的 False Negative。训练采样分布变化还会影响分数校准。

#### Q：如何处理序列过长？

> 可以截断最近行为、重要性采样、分层/滑窗编码、稀疏 Attention、兴趣聚类、缓存历史状态，或采用更适合长序列的推荐架构。需要同时评估效果损失、显存、延迟和更新频率。

### 7.7 易错点

- Causal Mask 屏蔽未来位置，Padding Mask 屏蔽无效行为，两者不能混为一谈。
- SASRec 的 Attention 权重不是严格的兴趣解释。
- 序列变长不一定持续提升，噪声、兴趣漂移和位置截断都会影响效果。

---

## 8. MMoE：任务选择性共享

### 8.1 为什么 Shared Bottom 不够？

Shared Bottom 使用：

```text
Input → Shared Network → Task Towers
```

所有任务被迫共享同一个底层表示。当 CTR 与 CVR、时长与投诉等任务相关性不同甚至梯度相反时，容易产生 Negative Transfer 和跷跷板现象。

### 8.2 MMoE 公式

设有 $E$ 个 Expert：

$$
f_e(x),\qquad e=1,\ldots,E
$$

任务 $k$ 的 Gate：

$$
g_k(x)=\operatorname{Softmax}(W_{g,k}x)
$$

任务 $k$ 的混合表示：

$$
h_k(x)=\sum_{e=1}^{E}g_{k,e}(x)f_e(x)
$$

再进入任务独立 Tower：

$$
\hat y_k=Tower_k(h_k(x))
$$

### 8.3 为什么每个任务要有独立 Gate？

不同任务可以对同一样本选择不同 Expert 组合。例如：

- CTR Gate 更关注短期兴趣 Expert；
- CVR Gate 更关注购买意图和价格 Expert；
- 时长 Gate 更关注内容消费 Expert。

如果所有任务共用 Gate，就又退化为较强的硬共享。

### 8.4 高频面试问答

#### Q：MMoE 如何缓解负迁移？

> 它不要求所有任务使用同一个共享表示，而是让任务独立 Gate 从多个共享 Expert 中选择不同组合。相关任务可以共享 Expert，不相关任务可以通过不同路由减少干扰。

#### Q：MMoE 能完全消除任务冲突吗？

> 不能。Expert 参数仍被多个任务共同更新，Gate 也可能集中到相同 Expert；Loss 尺度、样本量和梯度方向问题仍然存在，需要结合 Loss Weighting、梯度冲突处理或 PLE 等结构。

#### Q：什么是“死专家”？

> Gate 长期把概率集中到少数 Expert，其他 Expert 接收的权重和梯度极小，导致欠训练；欠训练又使 Gate 更不愿使用它们，形成正反馈。Dense Softmax Gate 通常是近似死亡，Top-K Sparse MoE 更容易完全收不到流量。

#### Q：怎么解决死专家？

> 可以使用 Load-balancing Loss、Gate Entropy、Temperature、Noisy Gating、Expert Dropout、更对称初始化和流量监控。平衡不能过强，否则所有 Gate 被迫均匀，Expert 又失去专业化意义。

#### Q：MMoE 和 PLE 的区别？

> MMoE 的 Expert 全部共享，任务只通过 Gate 选择组合；PLE 同时设置 Shared Experts 和 Task-specific Experts，并通过 CGC 多层渐进抽取，更明确地隔离公共知识和任务私有知识，通常更能缓解复杂任务的负迁移。

#### Q：MMoE 的参数量和 FLOPs？

> 若是 Dense MMoE，每个样本通常都计算所有 Expert，再由 Gate 加权，所以 FLOPs 随 Expert 数近似线性增长；参数量也包含全部 Expert。只有真正的 Top-K Sparse Routing 才能让激活 FLOPs 小于总 Expert 对应的 Dense FLOPs。

#### Q：Expert 数是不是越多越好？

> 不是。Expert 太少表达受限，太多会增加计算、路由塌缩和样本不足风险。应通过 Gate 使用率、Expert 相似度、任务收益和线上延迟共同选择。

### 8.5 MMoE 常见实现问题

- 不同任务样本空间不一致时，必须使用 Loss Mask；没有标签不等于负样本。
- Gate 输入可以是共享输入，也可加入 Task/Scene Embedding。
- 需要监控每个任务的 Gate 分布，而不只看总 Loss。
- 任务 A 提升、任务 B 下降时，应检查梯度 Cosine、Loss 尺度与主任务权重。

---

## 9. 多任务学习：不只是“多个 Loss 相加”

### 9.1 什么是多任务学习？

设任务集合为 $k=1,\ldots,K$：

$$
\mathcal L=\sum_{k=1}^{K}\lambda_k\mathcal L_k
$$

多任务学习通过共享部分参数，让相关任务相互提供归纳偏置和额外监督，同时保留任务独立的输出能力。

### 9.2 常见模型范式

#### 参数共享

- Shared Bottom：共享底座 + Task Towers；
- Cross-Stitch/Sluice：学习不同任务表示之间的软组合；
- MTAN：任务 Attention 从共享 Backbone 选择特征。

#### 专家路由

- MMoE：共享 Experts + Task Gates；
- CGC/PLE：Shared Experts + Task-specific Experts；
- AdaTT：自适应任务到任务的信息融合。

#### 漏斗任务

- ESMM：用 CTR × CVR = CTCVR，在全曝光空间联合训练，缓解 CVR 样本选择偏差与稀疏问题；
- AITM：显式把上游任务信息传递给下游任务，建模曝光→点击→转化等序列依赖；
- ESM2 等：进一步拆解更长行为链路。

#### 优化方法

- Uncertainty Weighting：按任务噪声学习权重；
- GradNorm：平衡各任务训练速度；
- PCGrad：投影掉冲突梯度分量；
- CAGrad/MGDA：寻找更兼顾多个任务的更新方向。

### 9.3 高频面试问答

#### Q：多任务学习为什么可能有效？

> 相关任务共享底层统计信息，相当于增加监督并形成正则化。数据丰富任务还能帮助数据稀疏任务学习更好的表示，例如点击信号帮助转化任务理解用户兴趣。

#### Q：为什么会出现跷跷板？

> 任务的最优表示和梯度方向不同，且样本量、Loss 尺度、收敛速度不同。共享参数更新可能有利于一个任务、损害另一个任务，表现为一个指标上涨、另一个下降。

#### Q：怎么判断梯度冲突？

> 可以计算共享参数上不同任务梯度的 Cosine Similarity。小于 0 表示局部方向冲突，但不能只看一次 Batch，应观察随训练阶段、场景和样本群体的分布。

#### Q：Loss 权重怎么设置？

> 可以从业务重要性和梯度量级出发手调，也可以使用 Uncertainty、GradNorm、Dynamic Weight Average 等方法。最终仍应以线上 Pareto 收益和约束为准，自动权重不保证符合业务价值。

#### Q：任务标签缺失怎么办？

> 对每个任务设置 Observation Mask，只在真实可观测样本上计算相应 Loss；对于漏斗任务，还要区分“标签未发生”和“标签不可观测”。ESMM、IPW 或延迟反馈建模分别处理不同问题。

#### Q：ESMM 和 MMoE 是替代关系吗？

> 不是。ESMM 主要解决 CTR/CVR 漏斗的样本空间和概率分解问题；MMoE 主要解决参数共享方式。可以在 ESMM 的任务结构中使用 MMoE/PLE 作为共享底座。

---

## 10. 多目标学习：预测多个指标之后，如何做业务决策

### 10.1 多任务与多目标的区别

| 维度 | 多任务学习 | 多目标学习/优化 |
|---|---|---|
| 核心问题 | 多个预测任务如何共享参数 | 多个业务目标如何权衡和决策 |
| 示例 | 同时预测 CTR、CVR、时长 | 同时最大化 GMV、留存并控制补贴和投诉 |
| 主要矛盾 | 表示共享与梯度冲突 | 目标不可通约、约束和 Pareto 权衡 |
| 常见方法 | Shared Bottom、MMoE、PLE、AITM | 加权和、约束优化、Pareto、RL、重排 |

多任务模型可以是多目标系统的预测层，但两者不是同义词。

### 10.2 最常见的加权融合

例如排序分数：

$$
score
=\alpha\log pCTR
+\beta\log pCVR
+\gamma\log \widehat{WatchTime}
+\delta\log Price
$$

或者乘法形式：

$$
score=pCTR^{\alpha}\cdot pCVR^{\beta}\cdot Value^{\gamma}
$$

使用 Log 后，乘法会转化为线性加权，更便于调参和数值稳定。

### 10.3 为什么简单加权不够？

- 各目标量纲不同；
- 权重对应的业务边际价值随场景变化；
- 目标之间可能强冲突；
- 固定权重无法表达预算、库存、体验红线；
- 模型输出若未校准，权重含义会漂移。

### 10.4 约束优化

可以把主目标与约束分开：

$$
\max_{\pi}\ \mathbb E[GMV(\pi)]
$$

约束：

$$
Cost(\pi)\le B,
\qquad ComplaintRate(\pi)\le c
$$

通过 Lagrangian：

$$
\mathcal J
=GMV-\lambda_1(Cost-B)-\lambda_2(Complaint-c)
$$

$\lambda$ 可以理解为约束资源的影子价格，并可根据线上约束违反程度动态更新。

### 10.5 Pareto 最优

如果不存在一种方案能在不损害任何其他目标的情况下继续提升某个目标，该方案位于 Pareto Front。实际系统通常先离线探索 Pareto 候选，再根据业务阶段选择 operating point。

### 10.6 高频面试问答

#### Q：点击率、时长、转化率应该怎么联合优化？

> 预测层可用 MMoE/PLE 分别预估各目标；决策层先校准输出，再依据业务价值做加权、约束或 Pareto 优化。不能简单把三个原始概率直接相加，因为量纲、分布和边际价值不同。

#### Q：为什么多目标不能只调 Loss Weight？

> Loss Weight 控制训练时共享参数的学习方向，Serving Weight 控制线上候选排序的业务取舍，两者作用位置不同。即使预测模型训练得很好，最终策略仍需要成本、约束和价值函数。

#### Q：主目标涨了，长期留存跌了怎么办？

> 说明短期代理目标与长期价值不一致。可以把留存作为约束或长期 Value Model，引入延迟反馈、长期实验指标、序列决策/RL，并限制策略变化幅度，不能只继续微调点击权重。

#### Q：怎么确定多目标权重？

> 离线先做归一化、校准和敏感性分析，生成多组 Pareto 候选；线上通过 A/B 实验选择满足硬约束且总体价值最高的点。权重应允许按场景、人群和业务阶段动态调整，但要防止策略不稳定。

#### Q：加权和能找到所有 Pareto 解吗？

> 当目标可行域或 Pareto Front 非凸时，简单线性加权不一定覆盖所有 Pareto 最优点，需要 ε-constraint、进化算法、条件化策略或其他多目标优化方法。

#### Q：多目标模型如何评估？

> 不能只报一个离线加权分。应分别报告每个目标的预测指标与校准，展示 Pareto 曲线、约束满足率和分人群结果，最终以长期线上实验的整体业务价值判断。

---

## 11. 横向对比：面试官最喜欢问的“为什么不用另一个模型”

| 问题 | 推荐回答 |
|---|---|
| LR 与 GBDT | LR 是全局线性模型，依赖人工交叉；GBDT 用树路径自动学习阈值和高阶非线性。LR 更易在线更新和解释，GBDT 对表格结构通常表达更强。 |
| LR 与 FM | LR 的交叉需要单独参数和人工构造；FM 用低秩向量内积自动泛化二阶交叉，更适合高维稀疏数据。 |
| FM 与 DeepFM | FM 主要到二阶；DeepFM 保留 FM 的低阶归纳偏置，同时用 DNN 学习高阶非线性关系。 |
| DeepFM 与 GBDT | DeepFM 更适合大规模稀疏 Embedding 和端到端训练；GBDT 擅长中小规模表格非线性与阈值规则。两者也可以做 Stacking 或用树叶特征输入深度模型。 |
| DIN 与 DeepFM | DeepFM 解决静态字段交叉，DIN 解决候选与历史行为的动态兴趣匹配；实践中 DIN 的兴趣向量通常会与 DeepFM/DCN 等特征交互主干结合。 |
| DIN 与 SASRec | DIN 是候选感知聚合，擅长从历史中筛当前相关兴趣；SASRec 是因果序列编码，擅长学习顺序和兴趣演化。它们可以互补而不是必须二选一。 |
| Shared Bottom 与 MMoE | Shared Bottom 强制所有任务使用同一表示；MMoE 允许任务通过 Gate 选择不同 Expert 组合，更能处理任务相关性不一致。 |
| MMoE 与 PLE | MMoE 只有共享 Expert；PLE 进一步加入任务私有 Expert 并逐层抽取，隔离能力更强，但参数和调参复杂度也更高。 |
| 多任务与多目标 | 多任务关注模型如何同时预测；多目标关注系统如何在多个业务价值间决策。多任务模型只是多目标系统的一部分。 |

---

## 12. 综合场景题

### Q1：如果让你设计一个推荐排序模型，会怎么组合这些模块？

> 我会先按信号类型拆分。User/Item/Context 静态稀疏特征用 Embedding + DeepFM/DCNv2 做交互；短期历史用 DIN 做候选感知兴趣，长序列用 SASRec 类模块编码顺序；CTR、CVR、时长等任务用 MMoE/PLE 做选择性共享。预测输出先做校准，再在重排层按业务价值、成本和体验约束做多目标优化。

### Q2：线上资源有限，如何选择模型？

> 先建立 LR/GBDT 或 DeepFM 稳定基线，量化静态交互收益；只有历史序列确实提供增益时再加入 DIN/SASRec；只有多任务冲突明显时再从 Shared Bottom 升级到 MMoE/PLE。模型选择要同时看增量收益、延迟、显存、特征新鲜度和维护成本。

### Q3：模型离线 AUC 提升，线上收益没有提升，为什么？

> 可能是离线样本与线上分布不同、负采样导致概率失真、目标与业务价值错位、校准变差、位置偏差或曝光偏差、延迟导致特征过期，也可能提升集中在非关键人群。需要检查 Calibration、分桶收益、线上策略权重、特征一致性和长期指标，而不只看总体 AUC。

### Q4：怎么判断应该使用 DIN 还是 SASRec？

> 如果关键问题是“当前候选与哪些历史行为相关”，DIN 更直接；如果关键问题是“行为顺序和兴趣演化”，SASRec 更合适。候选多、延迟敏感时 SASRec 的序列状态更易缓存；但真正最优方案可能是 SASRec 编码加候选感知轻量交互。

### Q5：为什么模型越来越复杂却未必更好？

> 复杂模型只有在数据量、信号强度和任务结构支持时才兑现表达力；否则会增加方差、优化冲突和工程误差。应通过控制变量实验逐步验证特征交互、序列、路由和多目标模块的独立贡献。

---

## 13. 面试速记版

### LR

> 线性 Logit + Sigmoid；优点是稳定、可解释、适合稀疏特征，缺点是依赖人工交叉。

### GBDT

> 多棵树串行拟合负梯度；自动学习阈值和高阶组合，强于表格非线性，但树之间训练不可完全并行。

### FM

> LR + 低秩二阶交叉；用 Embedding 内积解决高维稀疏组合泛化，是 MF 的一般化。

### DeepFM

> FM 显式低阶 + DNN 隐式高阶，共享 Embedding；比 Wide&Deep 更少依赖人工 Wide 特征。

### DIN

> 候选作为 Query，对历史行为做局部激活；每个候选得到不同的用户兴趣向量，但原始 DIN 不擅长显式顺序建模。

### SASRec

> Causal Self-Attention + Position Embedding 做 Next-item Prediction；并行、长依赖强，但 Dense Attention 是 $O(L^2d)$。

### MMoE

> 多任务共享 Experts、任务独立 Gates；通过任务选择性共享缓解负迁移，但仍要处理死专家和梯度冲突。

### 多任务学习

> 多个标签、多个 Loss、共享部分参数；核心是共享什么、冲突怎么处理、样本空间是否一致。

### 多目标学习

> 同时优化多个业务目标；核心是校准、价值权衡、约束与 Pareto，而不只是把多个 Loss 相加。

---

## 14. 最终 Takeaway

1. LR、FM、DeepFM 是一条从线性到低阶交叉再到高阶交互的演进线。
2. GBDT 是另一条结构化非线性路线，靠树路径学习规则组合。
3. DIN 与 SASRec 分别强调候选相关性和行为时序，解决的问题不同。
4. MMoE 属于多任务参数共享结构，多目标学习属于更上层的业务决策问题。
5. 面试回答不要只背模型定义，要固定回答五件事：解决什么问题、输入是什么、核心数据流、为什么有效、局限与替代方案。

