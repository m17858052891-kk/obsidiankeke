---
title: "AR模型迭代：竞争关系、多任务与离线验证"
type: "主题整理"
cssclasses: ["strategy-body-note"]
sources:
  - https://cooper.didichuxing.com/knowledge/2199610335356/2203928503084
  - https://cooper.didichuxing.com/knowledge/2199610335356/2204114677167
aliases:
  - "AR模型迭代规划"
  - "联合决策AR模型迭代策略方案"
---

# AR模型迭代：竞争关系、多任务与离线验证

把“为什么替换原模型”与“具体怎样实现、怎样验证”连起来阅读。候选设计、落地约束和离线结果各自保留。

## 先读这些

- **原模型问题**：逐商家预估后用 `1 − ∏(1 − AR)` 累积，容易放大误差、使概率集中在 1 附近，也未直接表达商家竞争和应答后取消。
- **设计目标**：规划稿讨论 MLP、Transformer、多任务监督和单调性；策略稿进一步要求一次模型调用支持所有呼叫组合、区分盒内外状态，并输出体现竞争关系的商家权重。
- **输出与监督**：策略稿分别说明订单完单、最终完单商家两个主要任务，以及离线商家应答辅助任务。三种发单状态由 `product_priority` 选取，再分别聚合为概率；各任务的损失与样本范围保留在原章节。
- **离线记录**：同一应答预测任务中，原文列出 AUC 从约 0.82 到约 0.85；另有 acc_CR 约 0.731、CP 完单任务约 0.88。它们是不同任务的指标，不能直接互比，也不是线上收益。
- **开发时查**：价格、距离、时间单位及 dense、sparse、trace 字段保留完整清单；已划掉的历史方案保留删除线，便于追溯。

**分节阅读**　[[#迭代动机与候选架构|迭代动机与候选架构]] · [[#策略方案与离线实验|策略方案与离线实验]]

## 迭代动机与候选架构

**来源**：[AR模型迭代规划](https://cooper.didichuxing.com/knowledge/2199610335356/2203928503084)

### 现状介绍

在用户发单时，可能会勾选一个或多个cp，显而易见的一个需求就是，模型预测的ar应该和勾选的车型数正相关，即勾选的车型数越多，ar的应答概率应该越高。目前ar模型的思路是，预测每个cp会应答的概率，然后基于每个cp的应答概率，计算勾选到不同位置时的acc_ar作为这一单最终的应答概率。例如，一个trace有n个cp，ar模型会预测每个cp的应答概率$$a_i\cdots a_n$$，那么勾选k个cp时的累积应答概率为$$acc\_ar = 1 - (1-a_1)\times(1-a_2)\cdots\times(1-a_k)$$

**存在的问题：**

- 累计误差：模型对于每个cp的预测有一定的误差，多个预测值相乘时，可能会放大这个误差

- 数值分布：对于一些cp数多的城市，例如沈阳，可能会存在勾选车型很多的情况，这种情况下会使得acc_ar分布集中在1附近，和实际的情况不符

	- 从全国随机抽样的数据来看，0.5分位数对应的acc_ar为0.95，0.6分位数对应0.98左右，数据分布相对比较集中

- cp之间的竞争性：目前ar预测的值相当于是单勾当前cp被应答的概率，但是当勾选多个品牌时，每个品牌在竞争态下的ar和单勾时不一样

	- 在联合决策的决策中，需要基于勾选商家的应答率加权的方式计算cost和gmv，当勾选多个商家时，每个商家的应答概率就不再是单勾时的应答概率，而是竞争态下的应答率，所以期望模型可以预测竞争态下的应答率

	- 如果要增加竞争态下的预测概率，需要增加举手、pk以及司机侧相关的信息

- 可扩展性差，目前线上使用的是xgb模型，只能对单任务学习，能利用到的信息较少

	- 对于决策而言，最好的情况是可以预测cr而不是ar，但是在预测cr时也希望保留对中间过程ar的监督，这样需要的就是一个多任务的模型，再使用xgb就难以完成这个目标

	- 想要改预测ar为预测cr，从交易漏斗来看，可以增加由哪个cp应答、是否取消、是否完单等结果的监督，这就需要额外增加司机侧、乘客侧的信息

### 迭代规划

#### 方向选择

从AR模型现状看，基于XGB的模型难以用同一个trace下不同cp信息对这一单的结果进行预测，以及XGB也不能解决多任务的问题，所以之后的迭代方向更倾向于选择深度学习的模型。如果想要用深度学习的方式预测ar，需要对模型结构、预测任务、数据以及评估方式作出一定的修改。

#### 模型

选择深度学习的原因：

- 从交易漏斗，以及之前分析的ar和cr之间的gap来看，**呼单**到**应答**再到**完单**之间还有还存在举手、pk、取消等司乘行为，想要利用这些信息，基于xgb的模型难以实现

- 对于同一个trace下的不同cp，在训练和预测阶段都是独立的，但是每个trace中相似的cp更有可能有相同的label，差异大的cp更有可能有不同的label，cp之间缺少直接的交互，同时，如果一个trace下有更多label=1（表示单勾是否会被应答）的cp，那么这一单就更有可能会被应答

	- 如果需要预测竞争态下的ar，cp之间的交互就更加不可或缺

- 由ar变成cr时，需要增加中间结果的监督，以及更多的信息

	- 不仅是司机侧信息，还要增加乘客侧信息，原因在于例如取消主要是乘客侧行为导致

关于模型选择：

- 基于mlp实现，大概的结构如下所示

	- 模型架构比较简单，或许可以做到不用填充到固定长度，即每次只用呼单的cp得到的特征向量聚合，得到预测is_td_answer的特征向量

	- 效果不确定，是否能学到关于勾选车型数的单调性约束，以及如何构造约束的问题

		- 可以用单勾第一个预测一个值，每个额外的勾选车型输出一个增量，类似drcfr，但这样模型输出的头会比较多

![](74b4624f5f5c3b74-流程图.svg)

> [!example]- 原图结构数据
> ```flowchart
> {"type": "flowchart", "sourceId": "MjIwMzk0MTcxMjM2Nw", "version": "2", "fileUrl": "../../../%E9%99%84%E4%BB%B6/74/74b4624f5f5c3b74-%E6%B5%81%E7%A8%8B%E5%9B%BE.svg"}
> ```


- 基于transformer实现

	- 参考dsar的结果，单调性应该是可以学到的

	- 需要填充到固定长度，模型相对复杂

![](4952d17ac94ca9cb-流程图.svg)

> [!example]- 原图结构数据
> ```flowchart
> {"type": "flowchart", "sourceId": "MjIwMzkzOTM3NTM5MQ", "version": "5", "fileUrl": "../../../%E9%99%84%E4%BB%B6/49/4952d17ac94ca9cb-%E6%B5%81%E7%A8%8B%E5%9B%BE.svg"}
> ```


多任务的问题：

- 多任务可以增加发单到应答以及完单等中间过程的监督，理想情况下，中间过程监督的越细致，效果应该越好

	- 可能的label：cp是否有运力（当前ar模型的label）、最终被哪个cp应答（不考虑改派应答和完单应该是同一个cp）、trace是否应答、trace是否取消、trace是否完单

		- 目前考虑的是，初期迭代还是用cp是否有运力（当前ar模型的label）、trace是否应答，原因：cp是否有运力可以作为迭代前后效果对比的label，trace是否应答是决策阶段用到的输出

		- 后续考虑把 trace是否应答 改 为trace是否完单，这样更符合业务逻辑

	- trace是否应答、trace是否取消、trace是否完单都应该随着勾选车型数变多而提高，如果模型没有学到单调性，如何增加单调性

		- 构造假数据

			- 对于未被应答的trace，勾选的更少也不会被应答

			- 对于被应答的trace，勾选的更多也会被应答

			- 如果预测最终会被哪个cp应答这个任务，勾选更多时应答的cp可能不是真实勾选情况下的cp

		- 勾选车型数作为一个特征预测增量加到单勾的车型上

- 多任务loss之间的平衡问题

	- 根据loss相对数值大小调整权重，给主要任务加权

- 目前应答其实只和运力情况相关，引入更多的label，必然需要更多的特征，例如pk可能需要司机特征，取消需要司机和乘客特征等，这些特征是通过一个模块端到端进学习，还是按照司机、乘客维度，或者trace（p维度信息等）、cp维度分别学习再交互

	- trace维度信息和cp维度信息拼到一起，然后过模型，同一个trace下不同的cp有相同的trace特征

	- trace维度信息单独一个链路，cp维度信息过transformer / mlp拿到特征向量，然后再交互

	- 可以对比两种方案的效果再决定

#### 特征工程

现有的数据主要是

- 历史统计特征

- by商家的运力特征

- 城市、小时、星期、运力渠道等离散型特征

预测不同任务，需要的增加的特征：

- 预测trace维度的label：trace是否应答、trace是否取消、trace是否完单，对数据结构修改

	- 由原来by cp修改为by trace维度，每个trace下有最终发单的所有cp信息

	- by trace的对应label

- 预测 trace是否取消、trace是否完单

	- 需要增加p维度特征，司机侧特征

- 预测 最终被哪个cp应答

	- 需要司机侧信息（可以参考履约率模型用到的特征）、pk信息

	- cp应答的label

#### 评估方式

【离线训练指标】

- cp是否有运力（当前ar模型的label）

	- 整体的auc，以及分渠道的auc

- trace是否应答、trace是否取消、trace是否完单

	- 离线auc

- 最终被哪个cp应答

	- 准确率，或者NDGC这种排序指标

【目前的问题】

在联合决策链路中，treatment是平台和盒子的折扣，以及默勾数，treatment是通过改变平台和盒子的折扣，影响价格分布，再对acc_ar产生影响，这个影响并不是直接产生的。现在ar模型改动时，没有类似mtaucc的业务指标去评估对决策可能产生的影响，主要依靠线上实验论证，周期较长。

#### 基于transformer的架构的模型设计

从业务视角考虑，实际成交只会有三种情况

1. 单勾uabox，只会以uabox发单

2. 勾选了uabox和盒子外，只会以盒子外发单

3. 勾选了盒子外和ufbox，只会以ufbox发单

所以，实际建模的时候，为了能模拟所有的情况，以单勾盒子作为base，如果勾选了盒子外，没有勾选ufbox，则有一个增量，如果勾选了ufbox，则额外再有一个增量。

此外，在预测时，每个cp都预测一个对应答（完单）的增量（限制为正的），对于trace的应答（完单），是所有cp的增量相加，过sigmoid计算得到。

离线预测时，一次过模型计算出类似下方的表格，然后通过类似查表的形式，找到所有的增量，相加过sigmoid，可以计算出所有情况下的预估应答率（完单率）。

| | uabox | 盒子外 | ufbox |
| --- | :---: | :---: | :---: |
| cp1 | d_ua1 | d_ua1 + d_cp1,1 | d_ua1 + d_cp1,1 + d_cp1,2 |
| cp2 | d_ua2 | d_ua2 + d_cp2,1 | d_ua2 + d_cp2,1 + d_cp2,2 |
| cp3 | d_ua3 | d_ua3 + d_cp3,1 | d_ua3 + d_cp3,1 + d_cp3,2 |
| cp4 | d_ua4 | d_ua4 + d_cp4,1 | d_ua4 + d_cp4,1 + d_cp4,2 |
| | | | |

实际假设勾选到cp4，cp1、cp2在uabox内，cp3在盒子外，cp4在ufbox内，那么这一单的应答、完单率为

sigmoid\[d_ua1 + d_ua2 + (d_ua3 + d_cp3,1) + (d_ua4 + d_cp4,1 + d_cp4,2)\]。

## 策略方案与离线实验

**来源**：[联合决策AR模型迭代策略方案](https://cooper.didichuxing.com/knowledge/2199610335356/2204114677167)

望岳：[https://ddp.intra.xiaojukeji.com/requirement/story/R-KF-487708?backUrl=/workbench/requirement](https://ddp.intra.xiaojukeji.com/requirement/story/R-KF-487708?backUrl=/workbench/requirement)

BRD：[==https://cooper.didichuxing.com/docs2/document/2204103548769==](https://cooper.didichuxing.com/docs2/document/2204103548769)

### 1. 背景

AR模型是联合决策整个策略中非常重要的一个部分。目前线上使用的AR模型，是基于XGB模型预测的每个cp**在单勾呼叫下的应答率**，然后通过累计的方式计算出呼叫cp组合时，订单被应答的概率。例如，一个trace有n个cp，ar模型会预测每个cp的应答概率$$a_i\cdots a_n$$，那么勾选前k个cp时的累积应答概率为$$acc\_AR = 1 - (1-a_1)\times(1-a_2)\cdots\times(1-a_k)$$。但当前AR模型，无论是模型结构，还是acc_AR的计算方式，都存在一定的问题：

1. 当前累计应答率的计算方式，会导致acc_AR与真实分布存在一定的偏差（见图1），主要是因为无法使用订单真实的应答label对模型进行监督，同时上述的计算方式也会导致误差累积。acc_AR值准性会严重影响联合决策的优化目标。

	- 以沈阳为例，2025-03-24 -- 2025-03-30期间整体应答率约为0.958左右，而acc_AR的均值约为0.987，其中正样本的acc_AR均值约为0.990，正样本acc_AR大于0.95的占比95.7%，负样本的acc_AR均值约为0.918，其中大于0.95的占比约为68.9%。沈阳正样本和负样本的acc_AR概率分布如下所示，可以看到由于acc_AR累积的形式，概率分布会向1集中。

           ![](../../../%E9%99%84%E4%BB%B6/f6/f6af825176692f5d-image.png)

        （图1）

2. 在联合决策计算订单cost和gmv时，需要根据「**if订单完单时以各cp完单的概率**」进行加权。目前是按照各cp「**单勾呼叫下的应答率」**进行加权的，缺点是没有考虑各cp之间的竞争关系（单勾呼叫应答率高的cp在PK环节胜出的概率不一定高）。

3. 当前我们使用acc_AR来替代CR，没有考虑应答后取消的影响，而在不同区域或时段下，应答后取消率有显著的差异。

为了解决以上问题，本次我们将模型从xgb升级到DNN，通过引入多任务学习，利用多路信息对模型进行监督，包括单勾呼叫是否能应答、组合呼叫订单是否能够被应答、组合呼叫订单是否能完单、完单情况下最终以哪个cp完单等，有望解决以上问题。

### 2. 策略方案

#### 2.1 模型要求

结合业务逻辑，以及工程侧对于在线推理的延时要求，模型需满足以下条件：

1. **性能要求：过一次**模型能够得到所有呼叫车型组合下的订单完单率

2. **盒子内外差异化**：模型需要能区分同一商家以盒子外发单、以盒子发单之间完单率的差异，且不同盒子之间的完单率也存在差异；

3. **CR与商家顺序无关**：对于价格列表上的cp，输出概率和列表上的顺序无关（价格相同的情况下）

	1. 假设有a、b、c三个商家，商家顺序从abc变为bac时，输出的概率不变，以及预测的最终完单的cp也不会变

4. **能输出加权系数且系数能反应竞争关系**：输出具体以哪个商家完单的概率，用于联合决策计算gmv和cost，且对于同一商家，不同勾选组合下加权系数不一样

	1. 勾选a、b、c三个商家和勾选a、b、c、d四个商家时，a商家的完单概率是不一样的，不同商家之间有竞争关系

#### 2.2 模型结构

目前模型结构设计为2个task，分别对应**冒泡是否被完单**以及**最终完单的cp**两个任务**。**每个task输出3个head，表示单勾盒子发单、盒子外发单、特快盒子发单，三种不同发单状态下的输出值（这个值并不表示概率），每个cp都会有这样的三个输出值，也就是说，每个trace会得到**商家数\*3**的矩阵。得到输出矩阵后，再根据实际每个cp的发单状态计算最终每个任务的预测概率（具体细节见【**输出**】部分）。

![](5c06d02a59b15410-image.png)

【**输入**】

输入主要分为trace特征和cp特征，一个冒泡只有一组trace特征，同一个冒泡下有多个商家，每个商家有一组cp特征。输入模型时，包含如下四部分特征，这里只介绍特征的含义，具体口径在【**2.3 模型特征中介绍**】

**dense：**cp维度特征，每个trace有多个商家，每个商家有自己的特征，同一个trace不同商家之间互不相同，入参形状是商家数\* 特征数

**~~mask：~~**~~离线为了数据处理方便，会有统一填充到75个商家的操作，这个数据表示哪些数据是填充的，在线使用时用商家数 \* 1的全1矩阵即可~~

**trace_features：**每个trace只有一组的特征，同一个trace不同商家之间是相同的

**sparse：**依次是city_id、dayofweek、hour，同一个trace不同商家之间是相同的

【**输出以及loss计算**】

- trace完单任务输出：

模型会输出一个矩阵，维度是商家数 \* 3，以及会依赖一个product_priority矩阵（商家数 \* 1）确定最终的输出，product_priority矩阵的元素只有1，2，3，表示不同的发单状态，即每个商家发单只会有三种状态：单勾盒子发单（1）、盒子外发单（2）、特快盒子发单（3）。例如，商家A如果同时勾选了特价盒子和盒子外并发单，那么实际发单只会按照盒子外发单，这时候A商家对应的product_priority元素就是2。

假设勾选了4个商家并发单，那么模型输出一个4\*3的矩阵，同时依赖一个product_priority矩阵（非模型输出，当价格list以及勾选状态确定时，product_priority就唯一确定），如下所示：

##### 三个任务共用的取数示例

| | uabox | 盒子外 | ufbox | product_priority |
| :---: | :---: | :---: | :---: | :---: |
| cp1 | ==d11== | d12 | d13 | 1 |
| cp2 | d21 | ==d22== | d23 | 2 |
| cp3 | d31 | d32 | ==d33== | 3 |

模型给出商家数 \* 3的矩阵之后，需要按照product_priority取数，并且by trace做聚合得到最终对于这一单的完单预测，这一单完单的概率即predict1= ( sigmoid(d11 + d22 + d33) - 0.5 ) \* 2。

**Loss：**有了预测的这一单的完单概率predict1，根据是否完单的label，计算bce loss。

**线上使用时模型只输出商家数 \* 3的矩阵，最终计算完单的概率需要过完模型之后，根据product_priority取数并额外计算的到。**

> sigmoid函数计算公式：$$sigmiod(x) = \frac{1}{1 + e^{-x}}$$。

- cp完单任务的预测

整体逻辑和应答\\完单任务一样，只是模型外的计算方式不一样，举例来说，首先还是计算的到商家数 \* 3的矩阵，以及会依赖一个product_priority矩阵（商家数 \* 1）

取数矩阵与前文相同，见 [[#三个任务共用的取数示例|三个任务共用的取数示例]]；本节保留本任务的输出与损失计算。


模型给出商家数 \* 3的矩阵之后，也需要按照product_priority取数，模型预测结果就是predict2=softmax(d11, d22, d33)，计算结果是一个概率分布，根据概率分布，取出预测概率最高的那个cp，就是预测的最终完单的cp。

**Loss：**预测最终完单的cp的任务当成一个多分类的任务，每个样本只会属于一个类别，总共的类别数就是这个trace呼叫的cp数，那么label就是完单的cp对应的index，有了predict2的概率分布之后，就可以计算ce loss。离线计算loss时，只计算完单的trace，对于没有完单的trace，loss置0且计算平均值时不计数。

> softmax函数会把一个向量映射成另一个向量，映射后的向量所有元素和为1，计算公式为：$$softmax(x_1, x_2, ...,x_n) = \frac{1}{\Sigma_1^n e^{x_i}}(e^{x_1}, e^{x_2}, ..., e^{x_n})$$。

- channel应答任务输出：线上不会使用，只在离线提供辅助作用

channel应答任务对每一个cp会预测一个值，预测的目标和原本的XGB模型相同，即“单勾商家的应答率”，输出的结果就是商家的应答概率，不需要做额外计算。

取数矩阵与前文相同，见 [[#三个任务共用的取数示例|三个任务共用的取数示例]]；本节保留本任务的输出与损失计算。


**Loss：**不需要by trace聚合，在按照product_priority取数后，每个cp都有一个label和一个输出，输出的结果就是每个cp的单勾应答率，直接和label计算bce loss即可。

#### 2.3 模型特征

单位：价格相关特征统一为“分”，距离相关特征统一为“米“，时间都是秒，相关衍生特征也是在转换单位之后计算得到

数据填充：~~缺失值以及用-9999.0作为默认值填充的数据，都用0填充， 包括连续型特征和离散型特征~~

mask：传入的mask为全是1的矩阵，形状为**商家数 \* 1**

商家聚合的历史统计特征，获取的key为：product_id，hour_of_day，is_weekday，city_id，其中is_weekday表示周中周末，day_of_week的规则是，星期天=1，星期一=2，以此类推，星期六=7，当day_of_week=2，3，4，5（周一到周四算作周中，周五到周日是周末）时，is_weekday=1

##### 完整特征清单

> [!example]- dense、sparse 与 trace 字段（保留原字段顺序）
> ```text
> dense特征和sparse特征
>
> ~~##  SDS特征，和原来的ar模型一样，只少不多，目前使用46个~~
>
> \## 全量的原来ar模型的sds特征，共105个
>
> snapshot_realtime_empty_driver_cnt_10m
>
> snapshot_realtime_empty_driver_cnt_3m
>
> hxz_product_city_aft_ansr_dri_cl_cnt_7d
>
> hxz_product_start_grid_time_slice_pas_cancel_after_answer_cnt_14d
>
> city_input_start_end_distance
>
> srived_order_epd_sum_3m_one_circle_grid
>
> hxz_product_start_grid_time_slice_avg_pick_dist_14d
>
> hxz_product_start_grid_time_slice_bubble_cnt_7d
>
> merchant_finish_cnt_3m
>
> strive_order_time_sum_1m
>
> realtime_online_driver_cnt_one_circle_grid
>
> srived_order_ept_sum_10m_one_circle_grid
>
> realtime_online_driver_cnt
>
> hxz_product_start_grid_time_slice_hands_order_cnt_7d
>
> srived_order_epd_sum_10m
>
> hxz_product_city_answer_cnt_7d
>
> hxz_product_city_arrive_cnt_7d
>
> merchant_call_cnt_1m
>
> merchant_call_cnt_10m_one_circle_grid
>
> hxz_product_city_answer_dri_cnt_7d
>
> merchant_answer_cnt_10m_one_circle_grid
>
> realtime_empty_driver_cnt_one_circle_grid
>
> hxz_product_start_grid_time_slice_avg_answer_dur_14d
>
> srived_order_epd_sum_10m_one_circle_grid
>
> strive_order_time_sum_10m_one_circle_grid
>
> hxz_product_city_avg_answer_dur_7d
>
> hxz_product_city_avg_arrive_dur_7d
>
> merchant_hands_cnt_10m_one_circle_grid
>
> merchant_call_cnt_3m_one_circle_grid
>
> snapshot_realtime_empty_driver_cnt_1m
>
> hxz_product_city_compete_call_cnt_7d
>
> merchant_hands_cnt_3m_one_circle_grid
>
> online_driver_cnt10m_one_circle_grid
>
> hxz_product_start_grid_time_slice_avg_pick_dur_14d
>
> merchant_finish_cnt_10m_one_circle_grid
>
> hxz_product_city_finish_cnt_7d
>
> hxz_product_city_participate_cnt_7d
>
> snapshot_realtime_empty_driver_cnt_10m_one_circle_grid
>
> hxz_product_start_grid_time_slice_answer_ratio_14d
>
> realtime_no_broadcast_cnt_one_circle_grid
>
> hxz_product_city_participate_dri_cnt_7d
>
> merchant_ar_10m_one_circle_grid
>
> online_driver_cnt_1m_one_circle_grid
>
> snapshot_realtime_empty_driver_cnt_3m_one_circle_grid
>
> online_driver_cnt_3m_one_circle_grid
>
> snapshot_realtime_empty_driver_cnt_1m_one_circle_grid
>
> merchant_answer_cnt_10m
>
> merchant_answer_cnt_1m
>
> merchant_answer_cnt_1m_one_circle_grid
>
> merchant_answer_cnt_3m
>
> merchant_answer_cnt_3m_one_circle_grid
>
> merchant_ar_10m
>
> merchant_call_cnt_10m
>
> merchant_call_cnt_1m_one_circle_grid
>
> merchant_call_cnt_3m
>
> merchant_finish_cnt_10m
>
> merchant_finish_cnt_1m
>
> merchant_finish_cnt_1m_one_circle_grid
>
> merchant_finish_cnt_3m_one_circle_grid
>
> merchant_hands_cnt_10m
>
> merchant_hands_cnt_1m
>
> merchant_hands_cnt_1m_one_circle_grid
>
> merchant_hands_cnt_3m
>
> online_driver_cnt_1m
>
> online_driver_cnt_3m
>
> online_driver_cnt10m
>
> realtime_empty_driver_cnt
>
> realtime_no_broadcast_cnt
>
> realtime_no_broadcast_order_cnt
>
> realtime_no_broadcast_order_cnt_one_circle_grid
>
> srived_order_epd_sum_1m
>
> srived_order_epd_sum_1m_one_circle_grid
>
> srived_order_epd_sum_3m
>
> srived_order_ept_sum_10m
>
> srived_order_ept_sum_1m
>
> srived_order_ept_sum_1m_one_circle_grid
>
> srived_order_ept_sum_3m
>
> srived_order_ept_sum_3m_one_circle_grid
>
> strive_order_time_sum_10m
>
> strive_order_time_sum_1m_one_circle_grid
>
> strive_order_time_sum_3m
>
> strive_order_time_sum_3m_one_circle_grid
>
> hxz_product_start_grid_time_slice_hands_driver_cnt_14d
>
> hxz_product_start_grid_time_slice_answer_ratio_7d
>
> hxz_product_start_grid_time_slice_answer_order_cnt_7d
>
> hxz_product_start_grid_time_slice_call_cnt_14d
>
> hxz_product_start_grid_time_slice_avg_pick_dist_7d
>
> hxz_product_start_grid_time_slice_call_cnt_7d
>
> hxz_product_start_grid_time_slice_finish_cnt_14d
>
> hxz_product_start_grid_time_slice_answer_order_cnt_14d
>
> hxz_product_start_grid_time_slice_answer_driver_cnt_14d
>
> hxz_product_start_grid_time_slice_answer_cnt_7d
>
> hxz_product_start_grid_time_slice_answer_driver_cnt_7d
>
> hxz_product_city_arrive_dur_7d
>
> hxz_product_start_grid_time_slice_avg_pick_dur_7d
>
> hxz_product_start_grid_time_slice_answer_cnt_14d
>
> hxz_product_start_grid_time_slice_dri_cancel_after_answer_cnt_14d
>
> hxz_product_city_answer_dur_7d
>
> hxz_product_start_grid_time_slice_hands_driver_cnt_7d
>
> hxz_product_start_grid_time_slice_hands_order_cnt_14d
>
> hxz_product_city_aft_ansr_pas_cl_cnt_7d
>
> hxz_product_start_grid_time_slice_dri_cancel_after_answer_cnt_7d
>
> hxz_product_start_grid_time_slice_pas_cancel_after_answer_cnt_7d
>
> hxz_product_start_grid_time_slice_avg_answer_dur_7d
>
> hxz_product_start_grid_time_slice_finish_cnt_7d
>
> \## 传入特征
>
> ufbox_basic_fee            ## 对订单的每一个商家，有该商家在特价盒子、盒子外、以及特快盒子内的basic_total_fee，如果商家不盒子内（特快和特价盒子），用盒子外价格填充
>
> outbox_basic_fee
>
> uabox_basic_fee
>
> ufbox_estimate_fee          ## 对订单的每一个商家，有该商家在特价盒子、盒子外、以及特快盒子内的estimate_fee_amt，如果商家不在盒子内（特快和特价盒子），用盒子外价格填充
>
> outbox_estimate_fee
>
> uabox_estimate_fee
>
> ufbox_fee_diff             ## basic_total_fee - estimate_fee_amt
>
> outbox_fee_diff
>
> uabox_fee_diff
>
> ufbox_cpm           ##    basic_total_fee / start_dest_dis，其中start_dest_dis表示订单起始点距离，同一个订单内所有商家的start_dest_dis相同
>
> outbox_cpm
>
> uabox_cpm
>
> ufbox_iph         ##     basic_total_fee / estimate_dur， 其中estimate_dur表示预估送驾时间，同一个订单内所有商家的estimate_dur相同
>
> outbox_iph
>
> uabox_iph
>
> \## 历史统计特征
>
> product_ans_cnt_7d
>
> product_cancel_cnt_7d
>
> product_p_cancel_cnt_7d
>
> product_d_cancel_cnt_7d
>
> product_finish_cnt_7d
>
> product_ans_rate_7d
>
> product_cancel_rate_7d
>
> product_p_cancel_rate_7d
>
> product_d_cancel_rate_7d
>
> product_finish_rate_7d
>
> product_finish_max_distance_7d
>
> product_finish_min_distance_7d
>
> product_finish_avg_distance_7d
>
> product_answer_max_distance_7d
>
> product_answer_min_distance_7d
>
> product_answer_avg_distance_7d
>
> product_cancel_max_distance_7d
>
> product_cancel_min_distance_7d
>
> product_cancel_avg_distance_7d
>
> product_finish_max_basic_fee_7d
>
> product_finish_min_basic_fee_7d
>
> product_finish_avg_basic_fee_7d
>
> product_answer_max_basic_fee_7d
>
> product_answer_min_basic_fee_7d
>
> product_answer_avg_basic_fee_7d
>
> product_cancel_max_basic_fee_7d
>
> product_cancel_min_basic_fee_7d
>
> product_cancel_avg_basic_fee_7d
>
> product_finish_max_cpm_7d
>
> product_finish_min_cpm_7d
>
> product_finish_avg_cpm_7d
>
> product_answer_max_cpm_7d
>
> product_answer_min_cpm_7d
>
> product_answer_avg_cpm_7d
>
> product_cancel_max_cpm_7d
>
> product_cancel_min_cpm_7d
>
> product_cancel_avg_cpm_7d
>
> product_finish_max_iph_7d
>
> product_finish_min_iph_7d
>
> product_finish_avg_iph_7d
>
> product_answer_max_iph_7d
>
> product_answer_min_iph_7d
>
> product_answer_avg_iph_7d
>
> product_cancel_max_iph_7d
>
> product_cancel_min_iph_7d
>
> product_cancel_avg_iph_7d
>
> product_finish_max_estimate_dur_7d
>
> product_finish_min_estimate_dur_7d
>
> product_finish_avg_estimate_dur_7d
>
> product_answer_max_estimate_dur_7d
>
> product_answer_min_estimate_dur_7d
>
> product_answer_avg_estimate_dur_7d
>
> product_cancel_max_estimate_dur_7d
>
> product_cancel_min_estimate_dur_7d
>
> product_cancel_avg_estimate_dur_7d
>
> product_ans_cnt_14d
>
> product_cancel_cnt_14d
>
> product_p_cancel_cnt_14d
>
> product_d_cancel_cnt_14d
>
> product_finish_cnt_14d
>
> product_ans_rate_14d
>
> product_cancel_rate_14d
>
> product_p_cancel_rate_14d
>
> product_d_cancel_rate_14d
>
> product_finish_rate_14d
>
> product_finish_max_distance_14d
>
> product_finish_min_distance_14d
>
> product_finish_avg_distance_14d
>
> product_answer_max_distance_14d
>
> product_answer_min_distance_14d
>
> product_answer_avg_distance_14d
>
> product_cancel_max_distance_14d
>
> product_cancel_min_distance_14d
>
> product_cancel_avg_distance_14d
>
> product_finish_max_basic_fee_14d
>
> product_finish_min_basic_fee_14d
>
> product_finish_avg_basic_fee_14d
>
> product_answer_max_basic_fee_14d
>
> product_answer_min_basic_fee_14d
>
> product_answer_avg_basic_fee_14d
>
> product_cancel_max_basic_fee_14d
>
> product_cancel_min_basic_fee_14d
>
> product_cancel_avg_basic_fee_14d
>
> product_finish_max_cpm_14d
>
> product_finish_min_cpm_14d
>
> product_finish_avg_cpm_14d
>
> product_answer_max_cpm_14d
>
> product_answer_min_cpm_14d
>
> product_answer_avg_cpm_14d
>
> product_cancel_max_cpm_14d
>
> product_cancel_min_cpm_14d
>
> product_cancel_avg_cpm_14d
>
> product_finish_max_iph_14d
>
> product_finish_min_iph_14d
>
> product_finish_avg_iph_14d
>
> product_answer_max_iph_14d
>
> product_answer_min_iph_14d
>
> product_answer_avg_iph_14d
>
> product_cancel_max_iph_14d
>
> product_cancel_min_iph_14d
>
> product_cancel_avg_iph_14d
>
> product_finish_max_estimate_dur_14d
>
> product_finish_min_estimate_dur_14d
>
> product_finish_avg_estimate_dur_14d
>
> product_answer_max_estimate_dur_14d
>
> product_answer_min_estimate_dur_14d
>
> product_answer_avg_estimate_dur_14d
>
> product_cancel_max_estimate_dur_14d
>
> product_cancel_min_estimate_dur_14d
>
> product_cancel_avg_estimate_dur_14
>
> 乘客历史信息获取的key是passenger_id
>
> trace特征
> \##   传入特征
>
> city_id              ## sparse特征
>
> day_of_week   ## 0-7，0为缺失值
>
> hour_of_day   ## 0-24，0为缺失值填充
>
> start_dest_dis       ## 送驾距离
>
> estimate_dur          ## 预估送驾时长，地图那边预估的送驾时长
>
> estimate_v               ##  根据距离和预估送驾时间计算的速度，start_dest_dis / estimate_dur 
>
> \## SDS特征，特征修正后所有商家一样
>
> bubble_minute_unique_cnt_3m_one_circle_grid
>
> bubble_minute_unique_cnt_10m_one_circle_grid,
>
> bubble_minute_unique_cnt_1m,
>
> bubble_minute_unique_cnt_1m_one_circle_grid,
>
> bubble_minute_unique_cnt_3m,
>
> bubble_minute_unique_cnt_3m_one_circle_grid,
>
> \##    历史统计特征
>
> pas_ans_cnt_7d
>
> pas_cancel_cnt_7d
>
> pas_p_cancel_cnt_7d
>
> pas_d_cancel_cnt_7d
>
> pas_finish_cnt_7d
>
> pas_ans_cp_cnt_7d
>
> pas_cancel_cp_cnt_7d
>
> pas_p_cancel_cp_cnt_7d
>
> pas_d_cancel_cp_cnt_7d
>
> pas_finish_cp_cnt_7d
>
> pas_ans_rate_7d
>
> pas_cancel_rate_7d
>
> pas_p_cancel_rate_7d
>
> pas_d_cancel_rate_7d
>
> pas_finish_rate_7d
>
> pas_finish_max_distance_7d
>
> pas_finish_min_distance_7d
>
> pas_finish_avg_distance_7d
>
> pas_answer_max_distance_7d
>
> pas_answer_min_distance_7d
>
> pas_answer_avg_distance_7d
>
> pas_cancel_max_distance_7d
>
> pas_cancel_min_distance_7d
>
> pas_cancel_avg_distance_7d
>
> pas_finish_max_est_fee_7d
>
> pas_finish_min_est_fee_7d
>
> pas_finish_avg_est_fee_7d
>
> pas_answer_max_est_fee_7d
>
> pas_answer_min_est_fee_7d
>
> pas_answer_avg_est_fee_7d
>
> pas_cancel_max_est_fee_7d
>
> pas_cancel_min_est_fee_7d
>
> pas_cancel_avg_est_fee_7d
>
> pas_finish_max_cpm_7d
>
> pas_finish_min_cpm_7d
>
> pas_finish_avg_cpm_7d
>
> pas_answer_max_cpm_7d
>
> pas_answer_min_cpm_7d
>
> pas_answer_avg_cpm_7d
>
> pas_cancel_max_cpm_7d
>
> pas_cancel_min_cpm_7d
>
> pas_cancel_avg_cpm_7d
>
> pas_finish_max_fee_diff_7d
>
> pas_finish_min_fee_diff_7d
>
> pas_finish_avg_fee_diff_7d
>
> pas_answer_max_fee_diff_7d
>
> pas_answer_min_fee_diff_7d
>
> pas_answer_avg_fee_diff_7d
>
> pas_cancel_max_fee_diff_7d
>
> pas_cancel_min_fee_diff_7d
>
> pas_cancel_avg_fee_diff_7d
>
> pas_finish_max_estimate_eta_7d
>
> pas_finish_min_estimate_eta_7d
>
> pas_finish_avg_estimate_eta_7d
>
> pas_answer_max_estimate_eta_7d
>
> pas_answer_min_estimate_eta_7d
>
> pas_answer_avg_estimate_eta_7d
>
> pas_cancel_max_estimate_eta_7d
>
> pas_cancel_min_estimate_eta_7d
>
> pas_cancel_avg_estimate_eta_7d
>
> pas_ans_cnt_14d
>
> pas_cancel_cnt_14d
>
> pas_p_cancel_cnt_14d
>
> pas_d_cancel_cnt_14d
>
> pas_finish_cnt_14d
>
> pas_ans_cp_cnt_14d
>
> pas_cancel_cp_cnt_14d
>
> pas_p_cancel_cp_cnt_14d
>
> pas_d_cancel_cp_cnt_14d
>
> pas_finish_cp_cnt_14d
>
> pas_ans_rate_14d
>
> pas_cancel_rate_14d
>
> pas_p_cancel_rate_14d
>
> pas_d_cancel_rate_14d
>
> pas_finish_rate_14d
>
> pas_finish_max_distance_14d
>
> pas_finish_min_distance_14d
>
> pas_finish_avg_distance_14d
>
> pas_answer_max_distance_14d
>
> pas_answer_min_distance_14d
>
> pas_answer_avg_distance_14d
>
> pas_cancel_max_distance_14d
>
> pas_cancel_min_distance_14d
>
> pas_cancel_avg_distance_14d
>
> pas_finish_max_est_fee_14d
>
> pas_finish_min_est_fee_14d
>
> pas_finish_avg_est_fee_14d
>
> pas_answer_max_est_fee_14d
>
> pas_answer_min_est_fee_14d
>
> pas_answer_avg_est_fee_14d
>
> pas_cancel_max_est_fee_14d
>
> pas_cancel_min_est_fee_14d
>
> pas_cancel_avg_est_fee_14d
>
> pas_finish_max_cpm_14d
>
> pas_finish_min_cpm_14d
>
> pas_finish_avg_cpm_14d
>
> pas_answer_max_cpm_14d
>
> pas_answer_min_cpm_14d
>
> pas_answer_avg_cpm_14d
>
> pas_cancel_max_cpm_14d
>
> pas_cancel_min_cpm_14d
>
> pas_cancel_avg_cpm_14d
>
> pas_finish_max_fee_diff_14d
>
> pas_finish_min_fee_diff_14d
>
> pas_finish_avg_fee_diff_14d
>
> pas_answer_max_fee_diff_14d
>
> pas_answer_min_fee_diff_14d
>
> pas_answer_avg_fee_diff_14d
>
> pas_cancel_max_fee_diff_14d
>
> pas_cancel_min_fee_diff_14d
>
> pas_cancel_avg_fee_diff_14d
>
> pas_finish_max_estimate_eta_14d
>
> pas_finish_min_estimate_eta_14d
>
> pas_finish_avg_estimate_eta_14d
>
> pas_answer_max_estimate_eta_14d
>
> pas_answer_min_estimate_eta_14d
>
> pas_answer_avg_estimate_eta_14d
>
> pas_cancel_max_estimate_eta_14d
>
> pas_cancel_min_estimate_eta_14d
>
> pas_cancel_avg_estimate_eta_14d
> ```


### 3. 离线验证

### 离线实验结论

【**离线auc评估**】

目前线上by商家预测单勾应答率，然后计算acc_AR的方式，acc_ar AUC=0.82，离线测算深度模型acc_ar AUC=0.85，acc_cr AUC=0.731左右，cp完单任务 AUC=0.88。离线测算深度模型在trace能否应答的任务AUC有约**3pp**的提升。

【**概率分布评估**】

**评估方式：**

- 一般而言，左上角图像越接近于对角线y=x，说明预测概率值越接近真实概率分布

- 经验而言，数据分布应该在\[0, 1\]区间内都有分布，而不会是类似\[0.6, 1\]这样的概率分布

**数据展示：**

线上by商家预测单勾应答率，然后计算的到acc_ar的概率分布如下：

| label: is_td_answer |
| --- |
| ![](5c9b4418ea1f24ed-2732616451.png) |

离线深度模型，不同label下未校准的概率分布：

| label: is_td_answer | label: is_td_finish |
| --- | --- |
| ![](60b880adcb068128-image.png) | ![](ec119b577164ebdc-image.png) |

**结论：**

- 从离线的结果来看，目前线上的acc_ar在校准前和真实概率分布差异较大

- 从XGB模型到深度模型，在同样的应答率预测任务下，离线auc有约3pp提升

### 4. 配置dufe特征产出任务
