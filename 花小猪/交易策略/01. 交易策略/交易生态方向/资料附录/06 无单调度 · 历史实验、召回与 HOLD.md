# 无单调度 · 历史实验、召回与 HOLD

阅读结论先看[[03 供给不足时，怎样判断调价和调司机有没有用|专题正文]]。这里按原资料保留版本、实验表、代码、图表及附件。

## 本卷条目

- [[#^eco-2202751447873|【历史文档归档】]]
- [[#^eco-2204293157304|司机无单调度因果方案]]
- [[#^eco-2205299950001|数据分析-调度接受度]]
- [[#^eco-2201877649623|司机调度-实验方案]]
- [[#^eco-2203561580450|司机调度实验能力支撑 整理]]
- [[#^eco-2205040758747|司机调度端到端方案-backup]]
- [[#^eco-2205633562850|无标题页面]]
- [[#^eco-2202934995519|围栏产出技术方案：]]
- [[#^eco-2203963693901|无标题页面2]]
- [[#^eco-2204241480663|无标题页面4]]
- [[#^eco-2203626898859|调度-模型迭代技术方向-25年]]
- [[#^eco-2206893698120|项目梳理-260227]]

## 【历史文档归档】

原目录：11.司机无单调度 › 【历史文档归档】 · [【历史文档归档】（Cooper 原页）](https://cooper.didichuxing.com/knowledge/2199610335356/2202751447873) ^eco-2202751447873




> [!abstract]- 子页面（9）
> - [司机调度实验能力支撑 整理](06%20%E6%97%A0%E5%8D%95%E8%B0%83%E5%BA%A6%20%C2%B7%20%E5%8E%86%E5%8F%B2%E5%AE%9E%E9%AA%8C%E3%80%81%E5%8F%AC%E5%9B%9E%E4%B8%8E%20HOLD.md#^eco-2203561580450)
> - [司机调度端到端方案-backup](06%20%E6%97%A0%E5%8D%95%E8%B0%83%E5%BA%A6%20%C2%B7%20%E5%8E%86%E5%8F%B2%E5%AE%9E%E9%AA%8C%E3%80%81%E5%8F%AC%E5%9B%9E%E4%B8%8E%20HOLD.md#^eco-2205040758747)
> - [司机无单调度因果方案](06%20%E6%97%A0%E5%8D%95%E8%B0%83%E5%BA%A6%20%C2%B7%20%E5%8E%86%E5%8F%B2%E5%AE%9E%E9%AA%8C%E3%80%81%E5%8F%AC%E5%9B%9E%E4%B8%8E%20HOLD.md#^eco-2204293157304)
> - [调度-模型迭代技术方向-25年](06%20%E6%97%A0%E5%8D%95%E8%B0%83%E5%BA%A6%20%C2%B7%20%E5%8E%86%E5%8F%B2%E5%AE%9E%E9%AA%8C%E3%80%81%E5%8F%AC%E5%9B%9E%E4%B8%8E%20HOLD.md#^eco-2203626898859)
> - [司机调度-实验方案](06%20%E6%97%A0%E5%8D%95%E8%B0%83%E5%BA%A6%20%C2%B7%20%E5%8E%86%E5%8F%B2%E5%AE%9E%E9%AA%8C%E3%80%81%E5%8F%AC%E5%9B%9E%E4%B8%8E%20HOLD.md#^eco-2201877649623)
> - [围栏产出技术方案：](06%20%E6%97%A0%E5%8D%95%E8%B0%83%E5%BA%A6%20%C2%B7%20%E5%8E%86%E5%8F%B2%E5%AE%9E%E9%AA%8C%E3%80%81%E5%8F%AC%E5%9B%9E%E4%B8%8E%20HOLD.md#^eco-2202934995519)
> - [无标题页面2](06%20%E6%97%A0%E5%8D%95%E8%B0%83%E5%BA%A6%20%C2%B7%20%E5%8E%86%E5%8F%B2%E5%AE%9E%E9%AA%8C%E3%80%81%E5%8F%AC%E5%9B%9E%E4%B8%8E%20HOLD.md#^eco-2203963693901)
> - [无标题页面4](06%20%E6%97%A0%E5%8D%95%E8%B0%83%E5%BA%A6%20%C2%B7%20%E5%8E%86%E5%8F%B2%E5%AE%9E%E9%AA%8C%E3%80%81%E5%8F%AC%E5%9B%9E%E4%B8%8E%20HOLD.md#^eco-2204241480663)
> - [项目梳理-260227](06%20%E6%97%A0%E5%8D%95%E8%B0%83%E5%BA%A6%20%C2%B7%20%E5%8E%86%E5%8F%B2%E5%AE%9E%E9%AA%8C%E3%80%81%E5%8F%AC%E5%9B%9E%E4%B8%8E%20HOLD.md#^eco-2206893698120)


## 司机无单调度因果方案

原目录：11.司机无单调度 › 【历史文档归档】 › 司机无单调度因果方案 · [司机无单调度因果方案（Cooper 原页）](https://cooper.didichuxing.com/knowledge/2199610335356/2204293157304) ^eco-2204293157304


### 一、背景

- **调度**：调度是指将长时听不到单的司机从接单概率低的区域牵引到接单概率更高的区域，对司机来说接单概率的提升能提升司机的服占比，**提升司机的收入**；对平台来说，接单概率高的地方会包括缺少运力的地方，将司机牵引到缺少运力的地方，可以带来应答率的提升，**带来平台完单和gmv的提升**

- **调度v1策略：**调度v1策略为两步策略：ML+OR，通过ML预测司机调度到目的地格子带来的gmv提升和调度cost，通过OR在调度roi的限制下最大化gmv，来确定每个司机的调度策略（不下达调度 or 调度到哪个格子），具体方案细节可见:[司机调度v1策略](https://cooper.didichuxing.com/knowledge/2199610335356/2203874016930)，整体的流程如下所示：

- **v1策略存在的不足**：该策略为两步预测，gmv,cost的预测值 会输入到黑盒的运筹规划当中并进行决策。因此**gmv,cost离线预测精度的提升不一定能带来线上效果的提升**。为了解决这个问题，我们提出了**基于因果框架的端到端的调度方案**

![](3d3fbdd3ea7a09a0-流程图.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwNTM4ODgxMjg1OA", "version": "4", "fileUrl": "../../../%E9%99%84%E4%BB%B6/3d/3d3fbdd3ea7a09a0-%E6%B5%81%E7%A8%8B%E5%9B%BE.svg"}
```

### 二、问题求解

#### 2.1 问题定义

$$max \sum_{t}\sum_{i(t),j(t),k} gmv_{i(t)j(t)k} \times z_{i(t)j(t)k}$$

$$st  \quad \sum_{t}\sum_{i(t)j(t)k} cost_{i(t)j(t)k} \times z_{i(t)j(t)k} \leq s \times   \sum_{t}\sum_{i(t)j(t)k}  gmv_{i(t)j(t)k} * z_{i(t)j(t)k}$$ 补贴率小于s

$$\forall t \quad \forall i(t),j(t) \ \sum_{k} z_{ijk} = 1$$.                             每个司机格子对需要下发一个策略（调度/不调度）

$$\forall t \quad \forall j(t)  \ \sum_{i(t)} z_{i(t)j(t)1} \leq 1$$                               每个司机j最多只能调到一个格子

$$\forall t \ \forall i(t) \ \sum_{j(t)} z_{i(t)j(t)1} \leq \text{未播订单数}$$           每个格子i最多能接受未播订单数 司机数

|   <br> |  含义 <br> |
| --- | --- |
| i(t) <br> | t时刻的格子ID <br> |
| j(t) <br> | t时刻的司机ID <br> |
| k <br> | 是否下发调度 <br> |

为了简化问题我们首先先不考以下的约束：

$$\forall t \quad \forall j(t)  \ \sum_{i(t)} z_{i(t)j(t)1} \leq 1$$                               每个司机j最多只能调到一个格子

$$\forall t \ \forall i(t) \ \sum_{j(t)} z_{i(t)j(t)1} \leq \text{未播订单数}$$           每个格子i最多能接受未播订单数 司机数

后续会在算法中加入以上的两个约束

所以问题变成：

$$max \sum_{t}\sum_{i(t),j(t),k} gmv_{i(t)j(t)k} \times z_{i(t)j(t)k}$$

$$st  \quad \sum_{t}\sum_{i(t)j(t)k} cost_{i(t)j(t)k} \times z_{i(t)j(t)k} \leq s \times  \sum_{t}\sum_{i(t)j(t)k}  gmv_{i(t)j(t)k} * z_{i(t)j(t)k}$$ 补贴率小于s

$$\forall t \quad \forall i(t),j(t) \ \sum_{k} z_{ijk} = 1$$.                             每个司机格子对需要下发一个策略（调度/不调度）

#### 2.2 dual 问题

$$min_{\lambda \geq 0  } ( \sum_{t}\sum_{i(t),j(t),k} gmv_{i(t)j(t)k} \times z_{i(t)j(t)k}   +\lambda \times \left [  s \times   \sum_{t}\sum_{i(t),j(t),k} gmv_{i(t)j(t)k} \times z_{i(t)j(t)k}  -\sum_{t}\sum_{i(t)j(t)k} cost_{i(t)j(t)k} \times z_{i(t)j(t)k}  \right ] \quad st \quad \forall t \quad \forall i(t),j(t) \ \sum_{k} z_{ijk} = 1\quad, \forall i,j \quad z_{ijk} \in \{0,1\})$$

$$= min_{\lambda \geq 0  } (max \sum_{t}\sum_{i(t),j(t),k}  \left [ (1+\lambda \times s)\times gmv_{i(t)j(t)k}  - \lambda \times cost_{i(t)j(t)k} \right ] \times  z_{i(t)j(t)k}   \quad st \quad \forall i(t),j(t) \ \sum_{k} z_{ijk} = 1\quad, \forall i,j \quad z_{ijk} \in \{0,1\})$$

#### 2.3 最优解

为了解决以上的min max 问题， 可以通过先固定 $$\lambda$$  
来求解$$max \sum_{t}\sum_{i(t),j(t),k}  \left [ (1+\lambda \times s)\times gmv_{i(t)j(t)k}  - \lambda \times cost_{i(t)j(t)k} \right ] \times  z_{i(t)j(t)k}   \quad st \quad \forall i(t),j(t) \ \sum_{k} z_{ijk} = 1\quad, \forall i,j \quad z_{ijk} \in \{0,1\}$$  
每一轮的策略$$z_{i(t)j(t)k}$$会影响未来的策略$$\forall t' > t \quad z_{i(t')j(t')k}$$, $$max \sum_{t}\sum_{i(t),j(t),k}  \left [ (1+\lambda \times s)\times gmv_{i(t)j(t)k}  - \lambda \times cost_{i(t)j(t)k} \right ] \times  z_{i(t)j(t)k}  > \sum_{t}\sum_{i(t),j(t),k} max _{z_{i(t)j(t)k}} \left [ (1+\lambda \times s)\times gmv_{i(t)j(t)k}  - \lambda \times cost_{i(t)j(t)k} \right ] \times  z_{i(t)j(t)k}$$

因此使用贪心算法无法得到最优解， 但预测每个策略对未来影响比较困难，所以为了简化问题我们使用贪心算法来提供每轮最优的一个决策。

如果找到最优$$\lambda ^*$$最优格子，司机组合如下：

$$\forall i,j \quad z_{ijk}^*  = 1 \quad if \quad  k^*(i,j) = argmax   (1+\lambda^* \times s)\times gmv_{ijk}  - \lambda ^* \times cost_{ijk}$$

$$\quad \quad \quad \quad \quad 0 \quad else$$ 

#### 2.4 ROI条件（决策司机是否可以调到某个格子）

按照以上的公式，需要对每个lambda ，i，j，  $$(1+\lambda^* \times s)\times gmv_{ijk}  - \lambda ^* \times cost_{ijk}$$的排序需要准才能做的最佳的决策，所以我们模型的性能依赖于不同 $$\lambda$$。 

如果$$司机j调到格子i 比不下发调度是一个更优的决策，司机j格子i需要满足以下的条件：$$

$$(1+\lambda^* \times s)\times gmv_{ij1}  - \lambda ^* \times cost_{ij1} \geq (1+\lambda^* \times s)\times gmv_{ij0}  - \lambda ^* \times cost_{ij0}$$

$$\Leftrightarrow \frac{gmv_{ij1} - gmv_{ij0}}{cost_{ij1} - cost_{ij0}} \geq \frac{\lambda^*}{1+\lambda^* \times s}$$

$$\Leftrightarrow ROI_{ij} \geq \frac{\lambda^*}{1+\lambda^* \times s}$$

总结：可以通过$$ROI_{ij}$$和$$\frac{\lambda^*}{1+\lambda^* \times s}$$可下发调度的候选格子

$$可调度格子/司机组=\{  格子i 司机j｜ ROI_{ij} \geq \frac{\lambda^*}{1+s\times \lambda ^*} \}$$

#### 2.5 保证调度的约束（决策司机调到哪一个格子）

##### 格子约束

每个司机j最多只能调到一个格子i， 但以上ROI条件无法保障司机只调到一个格子（$$｜\{ 格子i| ROI_{ij} \geq \frac{\lambda}{1+ \lambda \times s}   \}｜> 1$$）。

为了保证决策约束我们使用二次过滤方法，在每个$$\{ 格子i| ROI_{ij} \geq \frac{\lambda}{1+ \lambda \times s}   \}$$空间中选择$$GMV$$最高的格子。

##### 司机约束

每个格子最多只能接受未播订单数的司机， 但以上ROI条件无法保障这个条件（$$｜\{ 司机j| 决策司机j 调到格子i  \}｜> 未播订单$$）。

为了保证决策约束我们使用二次过滤方法，在每个$$\{ 司机j| 决策司机j 调到格子i  \}$$空间中选择top k （未播订单）$$GMV$$最高的司机。

##### 整体过滤流程

![](2b6776c1502eab26-image.png)

### 三、流程

![](4a0fbc94e282a1ed-流程图.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwNTM4ODU4NDUxOQ", "version": "4", "fileUrl": "../../../%E9%99%84%E4%BB%B6/4a/4a0fbc94e282a1ed-%E6%B5%81%E7%A8%8B%E5%9B%BE.svg"}
```

![](3dc34d005a9bd098-流程图.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwNDg3NzYzODc0Mw", "version": "5", "fileUrl": "../../../%E9%99%84%E4%BB%B6/3d/3dc34d005a9bd098-%E6%B5%81%E7%A8%8B%E5%9B%BE.svg"}
```

### 四、随机调度实验

**核心解决的问题**：

- 之前调度存在轮与轮之间**对照组司机挤占实验组司机流量的问题(左图)**。具体而言，当前轮召回的实验组和对照组司机在下一轮的表现并不一致，实验组司机下发调度任务以后再下一轮不会被召回，但对照组司机虽然下发了调度任务但在播单环节不会被召回，所以在下一轮的调度环节仍旧会被召回，导致一些需要下发调度任务的实验组司机由于上一轮对照组司机重复下发调度任务 无法被成功下发，使得我们的收益变窄

- 我们建模的核心思路是预估 司机格子对 通过调度 的uplift，所以我们需要构造uplift模型，uplift模型的训练和评估依赖于rct数据，因此我们设计了随机调度实验，具体流程如下：

![](504a29f8d40dc517-附件.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwNDg4NDk5Mjg5Mw", "version": "13", "fileUrl": "../../../%E9%99%84%E4%BB%B6/50/504a29f8d40dc517-%E9%99%84%E4%BB%B6.svg"}
```

### 五、模型结构

根据以上的定义，我们需要对每一个**司机/格子对预测这任务是否可以下发以及任务带来的价值**

**整体模型架构**

![](906c7c68b1fb19de-附件.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwNTMwNzkxNTQ4NA", "version": "2", "fileUrl": "../../../%E9%99%84%E4%BB%B6/90/906c7c68b1fb19de-%E9%99%84%E4%BB%B6.svg"}
```

**uplift 模型**

![](c5ec501a7571dd60-image.png)

### 六、离线评估指标

#### 6.1 评估指标介绍

**核心解决的问题**：uplift模型可以通过AUCC来评估模型排序的好坏，并判断线上的收益的正向程度，确保离在线的一致性。但在调度场景这个一致性是不成立的，原因在于dp对的干预不是独立的，对同一个司机我们只能给定一个策略，即司机最多只能调度到一个格子，同样对格子而言，最多只能被调入一个司机。但是在计算AUCC的时候对同一个司机可以调度到不同的格子，同一个格子可以被调度多个不同的司机。因此AUCC会高估线上的收益，为了满足我们上述的限制并解决这个问题，我们提出了dispach-aucc:==该指标通过模拟真实调度过程，衡量按决策因子排序生成的策略在累计成本—收益空间中的表现，更准确刻画了策略的实际有效性。==

|  <br> |  可评估不同预算下的UPLIFT <br> |  考虑流程中的二次过滤  <br> |
| --- | --- | --- |
| AUCC <br> | 可以 <br> | 否 <br> |
| DISPATCH-AUCC <br> | 可以 <br> | 是 <br> |

![](784b2686792ab602-dispatch-aucc_1_Autosaved_.gif)

#### 6.2 模型评估效果

**召回阶段DISPATCH AUCC**

![](9a49d630a57b95bb-image.png)

**播单阶段的AUCC**

![](3c01f79b92c51e4f-image.png)

| COST MAPE <br> | finish AUC <br> |
| --- | --- |
| 0.3883 <br> | 0.7193 <br> |

### 七、动态阈值 

使用预算限制和DISPATCH AUCC曲线来初始化阈值， 让后为了降低线上分布变化对模型带来的变化， 我每小时/by根据前6小时调度的效果来调整过滤占比(保持无单比例在20%)

```PlainText
for each time :
  for each city :
    lambda = lambda + step * [sum(no_order[time-6h : time])/sum(arrived[time-6h : time]) -0.2]  
```

### $$\text{阈值 } = \text{阈值 + 学习率} \times \frac{\text{前6小时的无单量}}{\text{前6小时到达目的地的司机} } -0.2$$

### 八、实验评估

#### 8.1实验方案

通过对实验过程分析，我们发现调度的分流实验相对时间片实验会存在更大的挤占效应，因此实验效果会被放大。

当前的司机分流实验是从召回源头分流，如果整体大盘1000个司机，10%的分流方式，实验组司机和对照组司机数量如下：

**运筹规划逻辑1**

|  <br>  <br> | 整体 <br> | 调度召回司机-Xmin听不到单 <br> | 召回格子 <br>**（实验/对照组不共享格子）** <br> | **运筹规划逻辑1匹配出的** <br>**司机/格子对** <br> | 真实下发调度 <br> |
| :---: | :---: | :---: | :---: | :---: | :---: |
| 大盘 <br> | 1000 <br> | 500 <br> | 100 <br> |  100 <br> | 100 <br> |
| 实验组 <br> | 100 <br> | 50 <br> | **100** <br> | **20** <br> | 20 <br> |
| 对照组 <br> | 900 <br> | 450 <br> | **0** <br> | **0** <br> | 0 <br> |

**司机分流实验存在的问题**：当前使用的是运筹规划逻辑1算的数据，**实验组的司机会和全部格子匹配**，这样能下发调度任务的司机偏多，**导致高估了实际收益**。

为了解决以上的问题， 我们可以通过召回所有司机（实验组+ 对照组）进行司机格子匹配（运筹规划逻辑2）

**运筹规划逻辑2**

|   <br> | 整体 <br> | 调度召回司机-Xmin听不到单 <br> | 召回格子 <br>**（实验/对照组共享格子）** <br> | **运筹规划逻辑2匹配出的** <br>**司机/格子对** <br> | 真实下发调度 <br> |
| :---: | :---: | :---: | :---: | :---: | :---: |
| 大盘 <br> | 1000 <br> | 500 <br> | 100 <br> | 100 <br> |  <br> |
| 实验组 <br> | 100 <br> | 50 <br> | **100** <br> | **10** <br> | 10 <br> |
| 对照组 <br> | 900 <br> | 450 <br> | **90** <br> | 0 <br> |

**运筹规划逻辑2的流程如下（工程流程图）：**

![](0004ddf7413742e4-附件.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwNTMxMDA4MzQxMg", "version": "3", "fileUrl": "../../../%E9%99%84%E4%BB%B6/00/0004ddf7413742e4-%E9%99%84%E4%BB%B6.svg"}
```

#### 8.2 实验结果

##### 司机分流实验

###### 实验配置 ：

- **评估日期：**2025.09.01-2025.09.07

- **实验城市 ：**==南京市,苏州市,厦门市,福州市,绵阳市,淄博市,吉林市,潍坊市,台州市,绍兴市,大理白族自治州,漳州市,莆田市,保山市 （占宏鹄+自营大聚合15%的gmv ）==

- **实验人群** ： 大聚合宏鹄和自营司机

- **分流方式：**司机流量分流 50% 对照组（不下发调度）50% 实验组（下发调度策略）

###### 业务结果

[==https://cooper.didichuxing.com/docs2/sheet/2205321951372==](https://cooper.didichuxing.com/docs2/sheet/2205321951372)

![](814b8f412990dc22-image.png)

**结论 ：**

	- **目前调度完成的订单中～96% 属于免佣订单，** **导致调度ROI和整体ROI的gap较大**

	- **由于tsh的提升能明显看出调度提升了司机的留存**

![](37376f49785ce8e4-image.png)

###### 评估触发调度的任务质量

调度任务平均效果

|  **组** <br> | ** 完单** <br> | ** gmv（元）** <br> |  **调度费用（元）** <br> |
| :---: | :---: | :---: | :---: |
|  平均 <br> |  ATE <br> |  相对提升 <br> |  平均 <br> |  ATE <br> |  相对提升 <br> |  平均 <br> |  ATE <br> |  相对提升 <br> |
| 对照组 <br> | 0.2524 <br> | **3.74pp** <br> | **+14.77%** <br> | 4.8802 <br> | **0.6703** <br> | **+13.73%** <br> | 0 <br> | 0.2861 <br> | $$+ \infin$$ <br> |
| 实验组 <br> | 0.2897 <br> | 5.5505 <br> | 0.2861 <br> |

**结论 ：**

	- 每个任务平均可以**提升3.74pp的完单概率****， 提升13.73%的gmv**

###### 调度任务分布

- 费用分布

![](e1822e8100910c9f-image.png)![](ba96800a23f367c7-image.png)

- ETA分布布

![](81b535999bcd5cbd-image.png)![](722fd9f6de52a5e2-image.png)

- 接受度

|  <br> |  初次下发调度接受率 <br> |
| :---: | :---: |
|  <br> | 0.3831 <br> |
|  复购 <br> |  接受过n次调度任务的司机下次下发调度接受概率  <br> |
|  接受次数 <br> |  1 <br> |  2 <br> |  3 <br> |  4 <br> |  5 <br> |
| 接受率 <br> | 0.4892 <br> | 0.5298 <br> | 0.5465 <br> | 0.5588 <br> | 0.5928 <br> |

##### 未播订单数

| 调度任务占比 <br> |
| :---: |
|  <br> |  召回 <br> |  播任务 <br> |
| $$\text{eta 时未播订单 } \leq 1$$ <br> | 99.57% <br> | 99.44% <br> |

**结论：** 大部分的情况下， 我们只需要最多调一个司机。

> [!abstract]- 子页面（1）
> - [数据分析-调度接受度](06%20%E6%97%A0%E5%8D%95%E8%B0%83%E5%BA%A6%20%C2%B7%20%E5%8E%86%E5%8F%B2%E5%AE%9E%E9%AA%8C%E3%80%81%E5%8F%AC%E5%9B%9E%E4%B8%8E%20HOLD.md#^eco-2205299950001)


## 数据分析-调度接受度

原目录：11.司机无单调度 › 【历史文档归档】 › 司机无单调度因果方案 · [数据分析-调度接受度（Cooper 原页）](https://cooper.didichuxing.com/knowledge/2199610335356/2205299950001) ^eco-2205299950001


周期： 2025.8.30 - 2025.09.03 ：

相似度图

 


## 司机调度-实验方案

原目录：11.司机无单调度 › 【历史文档归档】 · [司机调度-实验方案（Cooper 原页）](https://cooper.didichuxing.com/knowledge/2199610335356/2201877649623) ^eco-2201877649623


**~~一期实验时间~~**~~：预计7.18开始，前几天给司机适应期，正式实验统计时间7.22-8.4~~

**~~时间片：~~**~~CR，司机人均完单，采用2-3小时时间片轮转来看~~

**~~一期实验城市：~~**

| ~~**城市id**~~ <br> | ~~**城市名**~~ <br> | ~~**完单占比**~~ <br> |
| --- | --- | --- |
| ~~**158**~~ <br> | ~~**汕头市**~~ <br> | ~~0.17%~~ <br> |
| ~~**21**~~ <br> | ~~**东莞市**~~ <br> | ~~1.60%~~ <br> |
| ~~**40**~~ <br> | ~~**唐山市**~~ <br> | ~~0.33%~~ <br> |
| ~~**35**~~ <br> | ~~**泉州市**~~ <br> | ~~0.96%~~ <br> |
| ~~**11**~~ <br> | ~~**南京市**~~ <br> | ~~0.77%~~ <br> |

**~~司机分流： ~~**[~~司机调度-司机分流实验评估指标~~](https://cooper.didichuxing.com/docs2/document/2202757122641)

**其他实验规划：**

| **开发期** <br> | **预计开始时间** <br> | **实验时间** <br> | **实验结果产出和分析** <br> | **迭代优化内容** <br> | **备注** <br> |
| --- | --- | --- | --- | --- | --- |
| 实验1期（5周） <br> | 7.22 <br> | 7.22-8.4（时间片 & 司机分流） <br>7.21-7.27（司机分流） <br> | 8.4-8.12 <br>产出实验结果 <br> | 8.4-8.20 <br>- 分析实验数据，考虑优化方案，司机分流实验时间短，分析可以早点介入实验迭代也可以更早一些； <br><br>**7.17-8.23** <br>- **建立司机接单概率，司机接受度模型（需要投入的人力较多）** <br><br> | 模型开发留一周buffer <br> |
| 实验2期（6周） <br> | **8.30（最晚）** <br> | 8.30-9.12（时间片 & 司机分流） <br> | 9.13-9.20  <br>产出实验结果 <br> | 9.13-10.14，按照当期实验做分析和优化迭代 <br> |  <br> |
| 实验3期（4周） <br> | **10.14（最早）** <br> | 10.14-10.27（时间片 & 司机分流） <br> | 10.28-11.3 <br>产出实验结果 <br> | 10.28-11.10  <br>分析&迭代策略产出 <br> |  <br> |
| 实验4期（4周） <br> | 11.12 <br> | 11.12-11.25 （时间片 & 司机分流） <br> | 11.26-12.2 <br>产出实验结果 <br> | 11.26-12.8 <br>分析&迭代策略产出 <br> |  <br> |
| 实验5期（3周） <br> | 12.9 <br> | 12.9-12.22（时间片 & 司机分流） <br> | 12.23-12.29 <br>产出实验结果 <br> | 12.23-1.5 <br> |  <br> |
| 实验6期（3周） <br> | 1.6 <br> | 1.6-1.19（时间片 & 司机分流） <br> | 1.20-1.26 <br>产出实验结果 <br> |  <br> |  <br> |


## 司机调度实验能力支撑 整理

原目录：11.司机无单调度 › 【历史文档归档】 · [司机调度实验能力支撑 整理（Cooper 原页）](https://cooper.didichuxing.com/knowledge/2199610335356/2203561580450) ^eco-2203561580450


实验参数链接：<http://wiki.intra.xiaojukeji.com/pages/viewpage.action?pageId=1219586537>

### 一、当前实验具备的能力

1、有单概率计算：xmin连续ji

|  <br> |  V0 <br> |  V2 <br> |
| --- | :---: | :---: |
| 过滤策略 <br> |
| 未播订单增量  <br> | **目的地接单概率&gt; 起点接单概率 ？** <br>**使用统计方法计算概率** <br> | **目的地或中途接单概率&gt; 起点接单概率 ？** <br>**使用模型预测** <br> |
| 运筹规划 <br> |
| GMV <br> | ![](0d662739474d75b5-image.png) <br>- 不考虑中途接单概率 <br><br>- 使用统计方式司机算概率 <br><br> | ![](efacd344a6392f2b-image.png) <br>- 考虑中途接单概率 <br><br>- 使用模型预测 <br><br> |
| cost <br> | ![](c4fd411c927dd380-image.png) <br> | ![](d5fa48954de5da71-image.png) <br> |
| 格子可调司机数量限制 <br> | ![](586fc8b5d5a5435e-image.png) <br>**不考虑**可到达目的地的司机数量 <br> | ![](e8b9c3f4ee5eb3d3-image.png) <br>**考虑**可到达目的地的司机数量 <br> |

| 变量 <br> | 含义 <br> |
| :---: | :---: |
| $$z_{ij}$$ <br> |  {0,1}，司机i是否调到格子j <br> |
| $$accept_{ij}$$ <br> |  \[0,1\]，司机i接受格子j调度任务的概率 <br> |
| $$or_{ij}$$ <br> |  \[0,1\]，司机i到格子j接单概率 （公式计算） <br> |
| $$or_{io}$$ <br> |  \[0,1\]，司机i呆在原格子接单概率 （公式计算） <br> |
| $$afr_{j}$$ <br> |  \[0,1\]，格子j履约率 <br> |
| $$asp_{j}$$ <br> |  \[0,1\]，格子j asp <br> |
| $$midor_{ij}$$ <br> |  \[0,1\]，格子j asp <br> |
| $$p_{ij}$$ <br> |  \[0,1\]，司机i接受格子j调度任务条件下的接单概率（目的地或中途接单） <br> |
| $$q_{ij}$$ <br> |  \[0,1\]，司机i不接受或不下发格子j调度任条件下的接单概率 <br> |
| $$fee_{j}$$ <br> |  里程费 <br> |
| $$eda_{ij}$$ <br> | 司机i到格子j路面距离 <br> |
| $$subsidy_{ij}$$ <br> | 司机i到格子j路面距离 <br> |
| $$arrive_{ij}$$ <br> |  \[0,1\]，司机i到达格子j的概率 <br> |
| $$nobroad_{j}$$ <br> | 格子j未播订单数 <br> |
| $$empty_{j}$$ <br> | 格子j空车司机数 <br> |


## 司机调度端到端方案-backup

原目录：11.司机无单调度 › 【历史文档归档】 › 司机调度端到端方案-backup · [司机调度端到端方案-backup（Cooper 原页）](https://cooper.didichuxing.com/knowledge/2199610335356/2205040758747) ^eco-2205040758747


### 一、背景

- **调度**：调度是指将长时听不到单的司机从接单概率低的区域牵引到接单概率更高的区域，对司机来说接单概率的提升能提升司机的服占比，**提升司机的收入**；对平台来说，接单概率高的地方会包括缺少运力的地方，将司机牵引到缺少运力的地方，可以带来应答率的提升，**带来平台完单和gmv的提升**

- **调度v1策略：**调度v1策略为两步策略：ML+OR，通过ML预测司机调度到目的地格子带来的gmv提升和调度cost，通过OR在调度roi的限制下最大化gmv，来确定每个司机的调度策略（不下达调度 or 调度到哪个格子），具体方案细节可见:[司机调度v1策略](https://cooper.didichuxing.com/knowledge/2199610335356/2203874016930)，整体的流程如下所示：

![](f8fd9024ad57831b-image.jpg)

- **v1策略存在的不足**：该策略为两步预测，gmv,cost的预测值 会输入到黑盒的运筹规划当中并进行决策。因此**gmv,cost离线预测精度的提升不一定能带来线上效果的提升**。为了解决这个问题，我们提出了**基于因果框架的端到端的调度方案**

### 二、问题求解

#### 2.1 问题定义

$$max \sum_{j} \sum_{i \in G(j) \cup \{0 \}} gmv_{ij} \times z_{ij}$$

$$st  \quad  \sum_{j} \sum_{i \in G(j) \cup \{0 \}} cost_{ij} \times z_{ij} \leq s \times  \sum_{j} \sum_{i \in G(j) \cup \{0 \}} gmv_{ij} \times z_{ij}$$

$$\quad  \quad \forall j \quad  \sum_{i \in G(j) \cup \{0 \}} z_{ij}  = 1  \quad \text{每个司机都需要下发一个策略调到i格子或者不调 (策略约束)}$$

$$\quad  \quad \forall i \quad  \sum_{j} z_{ij}  \leq 未播订单数  \quad \text{每个格子最多只能接受未播订单数的司机(供需约束)}$$

$$\quad  \quad \forall i,j \quad z_{ij} \in \{0,1 \}$$

|   <br> |  含义 <br> |
| --- | --- |
| G(j)  <br> | 所有司机j可以调度的格子 <br> |
| i <br> | 格子ID，如果i=0 不下发调度 <br> |
| j <br> | 司机ID <br> |

#### 2.2 dual 问题

首先为了简化优化问题先不考虑供需约束， 导致优化问题变成

$$max \sum_{j} \sum_{i \in G(j) \cup \{0 \}} gmv_{ij} \times z_{ij}$$

$$st  \quad  \sum_{j} \sum_{i \in G(j) \cup \{0 \}} cost_{ij} \times z_{ij} \leq s \times  \sum_{j} \sum_{i \in G(j) \cup \{0 \}} gmv_{ij} \times z_{ij}$$

$$\quad  \quad \forall j \quad  \sum_{i \in G(j) \cup \{0 \}} z_{ij}  = 1  \quad \text{每个司机都需要下发一个策略调到i格子或者不调 (策略约束)}$$

$$\quad  \quad \forall i,j \quad z_{ij} \in \{0,1 \}$$

##### **拉格朗日及对偶变换**

**PRIMAL PROBLEM**

==为了将带约束的优化转化成无约束的优化，我们将目标函数f转化成拉格朗日乘==子形式

$$\max_{Z} \min_{\lambda\geq 0}  \sum_{j} \sum_{i \in G(j) \cup \{0 \}} gmv_{ij} \times z_{ij}  - \lambda \times  [   \sum_{j} \sum_{i \in G(j) \cup \{0 \}} cost_{ij} \times z_{ij} - s \times  \sum_{j} \sum_{i \in G(j) \cup \{0 \}} gmv_{ij} \times z_{ij} ] , \quad   \forall j \quad  \sum_{i \in G(j) \cup \{0 \}} z_{ij}  = 1$$  
$$\Leftrightarrow \max_{Z} \min_{\lambda\geq 0}  \sum_{j} \sum_{i \in G(j) \cup \{0 \}} [(1+\lambda \times s) \times gmv_{ij} -\lambda \times cost_{i,j} ]\times z_{ij}  , \quad   \forall j \quad  \sum_{i \in G(j) \cup \{0 \}} z_{ij}  = 1$$  
==因此，我们要优化的原问题(Primal problem)即为== $$max_{Z}\ min_{\lambda\geq 0}  \sum_{j} \sum_{i \in G(j) \cup \{0 \}} [(1+\lambda \times s) \times gmv_{ij} -\lambda \times cost_{i,j} ]\times z_{ij}$$ ==。因为Z的搜索空间远大于==λ==的搜索空间，原问题求解比较不直观，为了使求解更方便，我们可将其转化为对偶==

**DUAL PROBLEM** 

$$\min_{\lambda\geq 0} \max_{Z}  \sum_{j} \sum_{i \in G(j) \cup \{0 \}} [(1+\lambda \times s) \times gmv_{ij} -\lambda \times cost_{i,j} ]\times z_{ij}  , \quad   \forall j \quad  \sum_{i \in G(j) \cup \{0 \}} z_{ij}  = 1$$

$$= \min_{\lambda\geq 0} \sum_{j} \max_{i \in \{k | G(i) \cup \{0\}\}} (1+\lambda \times s) \times gmv_{ij} -\lambda \times cost_{ij}$$

#### 2.3最优解

如果找到最优$$\lambda ^*$$最优格子，司机组合如下：

$$\forall i,j \quad z_{ij}  = 1 \Leftrightarrow  \forall j\ i^* (j) = \argmax_{i \in \{k | G(j) \cup \{0\}\}} (1+\lambda \times s) \times gmv_{ij} -\lambda \times cost_{ij}$$

#### 2.4 ROI条件（决策司机是否可以调度）

按照以上的公式，需要对每个lambda ， 司机j  $$(1+\lambda^* \times s)\times gmv_{ijk}  - \lambda ^* \times cost_{ijk}$$的排序需要准才能做的最佳的决策，所以我们模型的性能依赖于不同 lambda。

- case 1 : $$i^*(j) = 0 \ \text{(\textcolor{red}{司机j不需要下发调度})}$$ 

$$\forall j \ z_{0j} = 1 \Leftrightarrow \forall j , \forall i \in G(j) \quad  (1+\lambda \times s) \times gmv_{0j} -\lambda \times cost_{0j} \geq  (1+\lambda \times s) \times gmv_{ij} -\lambda \times cost_{ij}$$  
$$\quad \quad \quad \ \ \ \ \ \ \Leftrightarrow \forall j , \forall i \in G(j) \quad  \frac{gmv_{ij} - gmv_{0j}}{cost_{ij} - cost_{0j}} \leq \frac{\lambda^*}{1+\lambda^* \times s}$$ 

$$\quad \quad \quad \ \ \ \ \ \ \Leftrightarrow \forall j , \forall i \in G(j) \quad  ROI_{ij} \leq \frac{\lambda^*}{1+\lambda^* \times s}$$

- case 2 : $$i^*(j) \neq 0 \ \text{(\textcolor{green}{司机j需要下发调度})}$$ 

$$\forall j \ z_{i^*j} = 1  \Leftrightarrow \forall j , \forall i \in G(j) \setminus {} \{ i^*\} \cup \{0 \} \quad    (1+\lambda \times s) \times gmv_{i^*j} -\lambda \times cost_{i^*j} \geq  (1+\lambda \times s) \times gmv_{ij} -\lambda \times cost_{ij}$$

$$\ \quad \quad \quad \ \ \ \ \ \ \Rightarrow \forall j  \quad (1+\lambda \times s) \times gmv_{i^*j} -\lambda \times cost_{i^*j} \geq  (1+\lambda \times s) \times gmv_{0j} -\lambda \times cost_{0j}$$

$$\ \quad \quad \quad \ \ \ \ \ \ \Leftrightarrow \forall j  \quad  \frac{gmv_{ij} - gmv_{0j}}{cost_{ij} - cost_{0j}} \geq \frac{\lambda^*}{1+\lambda^* \times s}$$

$$\ \quad \quad \quad \ \ \ \ \ \ \Leftrightarrow \forall j  \quad  ROI_{i^*j} \geq \frac{\lambda^*}{1+\lambda^* \times s}$$

总结：可以通过$$ROI_{ij}$$和$$\frac{\lambda^*}{1+\lambda^* \times s}$$的对比来判断是否需要调度 

![](94b1c0e8c583ce14-image.png)

#### 2.5 保证调度的约束（决策司机调到哪一个格子）

##### 决策约束

每个司机j最多只能调到一个格子i， 但以上ROI条件无法保障司机只调到一个格子（$$｜\{ i \in G(j)| ROI_{ij} \geq \frac{\lambda}{1+ \lambda \times s}   \}｜> 1$$）。

为了保证决策约束我们使用二次过滤方法，在每个$$\{ i \in G(j)| ROI_{ij} \geq \frac{\lambda}{1+ \lambda \times s}   \}$$空间中选择$$GMV$$最高的格子。

##### 供需约束

每个格子最多只能接受未播订单数的司机， 但以上ROI条件无法保障这个条件（$$｜\{ j \in G^{-1}(i)| 决策司机j 调到格子i  \}｜> 未播订单$$）。

为了保证决策约束我们使用二次过滤方法，在每个$$\{ j \in G^{-1}(i)| 决策司机j 调到格子i  \}$$空间中选择top k （未播订单）$$GMV$$最高的司机。

##### 整体过滤流程

![](2b6776c1502eab26-image.png)

### 三、流程

![](3dc34d005a9bd098-流程图.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwNTA0MDcxNDI1Nw", "version": "", "fileUrl": "../../../%E9%99%84%E4%BB%B6/3d/3dc34d005a9bd098-%E6%B5%81%E7%A8%8B%E5%9B%BE.svg"}
```

#### 3.1 算法执行： 

```PlainText
for each driver i， grid j ：
    compute each ROI_{ij}  
    filter ROI_{ij}  < lamda / (1+ lambda * s)
for each driver :
    choose the max gmv grid 

tune lambda 
```

#### 3.2 调整阈值策略：

![](22160947567d796e-image.png)

在发C补时，由于策略的单调性（增加cost 肯定会提升gmv）所以$$\lambda ^ * = \lambda_{budget}$$

但是在调度中没有单调性的保证所以会导致$$\lambda ^ * < \lambda_{budget}$$

### 四、随机调度实验

![](483499350c9b18cc-附件.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwNTA0MDczMTMwOQ", "version": "", "fileUrl": "../../../%E9%99%84%E4%BB%B6/48/483499350c9b18cc-%E9%99%84%E4%BB%B6.svg"}
```

### 五、离线评估指标

![](784b2686792ab602-dispatch-aucc_1_Autosaved_.gif)

> [!abstract]- 子页面（1）
> - [无标题页面](06%20%E6%97%A0%E5%8D%95%E8%B0%83%E5%BA%A6%20%C2%B7%20%E5%8E%86%E5%8F%B2%E5%AE%9E%E9%AA%8C%E3%80%81%E5%8F%AC%E5%9B%9E%E4%B8%8E%20HOLD.md#^eco-2205633562850)


## 无标题页面

原目录：11.司机无单调度 › 【历史文档归档】 › 司机调度端到端方案-backup · [无标题页面（Cooper 原页）](https://cooper.didichuxing.com/knowledge/2199610335356/2205633562850) ^eco-2205633562850

原页状态：Cooper 未发布，未返回可读正文


> Cooper 未发布，未返回可读正文。[打开原页](https://cooper.didichuxing.com/knowledge/2199610335356/2205633562850)


## 围栏产出技术方案：

原目录：11.司机无单调度 › 【历史文档归档】 · [围栏产出技术方案：（Cooper 原页）](https://cooper.didichuxing.com/knowledge/2199610335356/2202934995519) ^eco-2202934995519


**围栏产出技术方案：**

基于花小猪业务场景发单的经纬度信息，所在格子的供需特征，通过机器学习的聚类方式，将类似格子聚成一类，这个是初始围栏，之后通过以下方式针对初始围栏进行优化：

1. 首先将单格子为一类的区域合并到周围和其最相似的区域中；

2. 其次针对有孔洞的区域，按照孔洞拆分成多个围栏；

3. 之后对连通性进行检验，针对有多个多边形的围栏拆分成单独的多边形，每个多边形为一个围栏；

![](fcc2acecead25eaa-流程图.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwMjkzNjQ3NzMwMw", "version": "1", "fileUrl": "../../../%E9%99%84%E4%BB%B6/fc/fcc2acecead25eaa-%E6%B5%81%E7%A8%8B%E5%9B%BE.svg"}
```


## 无标题页面2

原目录：11.司机无单调度 › 【历史文档归档】 · [无标题页面2（Cooper 原页）](https://cooper.didichuxing.com/knowledge/2199610335356/2203963693901) ^eco-2203963693901


![](bdb8ac8610eb6d61-流程图.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwMzk2MzY0NTIyOA", "version": "5", "fileUrl": "../../../%E9%99%84%E4%BB%B6/bd/bdb8ac8610eb6d61-%E6%B5%81%E7%A8%8B%E5%9B%BE.svg"}
```

![](3ae6da54534cd6d5-流程图.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwMzk3MzcyOTk2Mw", "version": "1", "fileUrl": "../../../%E9%99%84%E4%BB%B6/3a/3ae6da54534cd6d5-%E6%B5%81%E7%A8%8B%E5%9B%BE.svg"}
```

![](d160767a34c939fb-流程图.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwMzk3Mzc0OTY5Ng", "version": "3", "fileUrl": "../../../%E9%99%84%E4%BB%B6/d1/d160767a34c939fb-%E6%B5%81%E7%A8%8B%E5%9B%BE.svg"}
```

![](664301033c2904d0-流程图.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwMzk2MzcwMzYwNw", "version": "1", "fileUrl": "../../../%E9%99%84%E4%BB%B6/66/664301033c2904d0-%E6%B5%81%E7%A8%8B%E5%9B%BE.svg"}
```

![](16b49429372bcd4a-流程图.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwMzk3MTIzNTQ5Mw", "version": "1", "fileUrl": "../../../%E9%99%84%E4%BB%B6/16/16b49429372bcd4a-%E6%B5%81%E7%A8%8B%E5%9B%BE.svg"}
```

![](ce4a26e2863de247-流程图.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwMzk2NjMxMTgzOA", "version": "2", "fileUrl": "../../../%E9%99%84%E4%BB%B6/ce/ce4a26e2863de247-%E6%B5%81%E7%A8%8B%E5%9B%BE.svg"}
```

![](8f1d2bd540a90648-流程图.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwNDA4MzM2NTE1NQ", "version": "5", "fileUrl": "../../../%E9%99%84%E4%BB%B6/8f/8f1d2bd540a90648-%E6%B5%81%E7%A8%8B%E5%9B%BE.svg"}
```


## 无标题页面4

原目录：11.司机无单调度 › 【历史文档归档】 · [无标题页面4（Cooper 原页）](https://cooper.didichuxing.com/knowledge/2199610335356/2204241480663) ^eco-2204241480663

原页状态：Cooper 未发布，未返回可读正文


> Cooper 未发布，未返回可读正文。[打开原页](https://cooper.didichuxing.com/knowledge/2199610335356/2204241480663)


## 调度-模型迭代技术方向-25年

原目录：11.司机无单调度 › 【历史文档归档】 · [调度-模型迭代技术方向-25年（Cooper 原页）](https://cooper.didichuxing.com/knowledge/2199610335356/2203626898859) ^eco-2203626898859


**现在调度涉及到模块有哪些，具体使用了什么样儿的模型？**

现在调度分为司机调度和动调调度

### 司机调度

#### 未播 - 空车司机数预测模型

==线上模型上线记录：[https://cooper.didichuxing.com/knowledge/share/page/gAhaws1kfVIz](https://cooper.didichuxing.com/knowledge/share/page/gAhaws1kfVIz#)==

模型细节和训练效果梳理：[==https://cooper.didichuxing.com/knowledge/share/page/5L5BKpkFtxiR==](https://cooper.didichuxing.com/knowledge/share/page/5L5BKpkFtxiR#)

之前有将一些模型推上线，但是效果不好后续也没有再分析，25年之后要仔细迭代模型效果，分析线上效果好或者不好的原因，以及

#### 司机接受度模型

==调度司机接受度模型：[https://cooper.didichuxing.com/knowledge/share/page/OOosQb7pnfYd](https://cooper.didichuxing.com/knowledge/share/page/OOosQb7pnfYd#)==

==该模型只是使用xgboost模型简单搭建起来，当前auc不到0.7，还有优化空间，==

#### 起点接单概率，中途接单概率和目的地接单概率模型

这个建模方案还待讨论，起点，中途，目的地接单接单概率，这三个概率是互斥的，可以搭建多任务模型

常规的多任务模型是关联的，这些个多任务模型是互斥的；

### 动调调度

#### 动调触发模型

前段时间改了模型触发label：[==https://cooper.didichuxing.com/knowledge/share/page/0wZfQamUZCY3==](https://cooper.didichuxing.com/knowledge/share/page/0wZfQamUZCY3#)

==触发模型是一个很典型的不平衡数据集任务，最近也针对不平衡数据集做了一些优化：[https://cooper.didichuxing.com/knowledge/share/page/giHQ5h6SeGQo](https://cooper.didichuxing.com/knowledge/share/page/giHQ5h6SeGQo#)==

#### 格子粒度呼叫量随调价系数变化的模型；

[==https://cooper.didichuxing.com/knowledge/share/page/PIhBSklK0qTJ==](https://cooper.didichuxing.com/knowledge/share/page/PIhBSklK0qTJ#)

#### 格子粒度司机履约率模型

[==https://cooper.didichuxing.com/knowledge/share/page/Tb7n86gXRuO9==](https://cooper.didichuxing.com/knowledge/share/page/Tb7n86gXRuO9#)


## 项目梳理-260227

原目录：11.司机无单调度 › 【历史文档归档】 · [项目梳理-260227（Cooper 原页）](https://cooper.didichuxing.com/knowledge/2199610335356/2206893698120) ^eco-2206893698120


### 项目梳理-260227

### 呈现逻辑

![](0e1a048b55951df9-image.png)

个人介绍：

构建了一个跨时间尺度的时空匹配与决策优化框架，覆盖订单生命周期、供给重配置与系统稳态控制。

交易系统本质是一个跨时间、跨空间的连续决策系统。不同时间尺度下优化目标不同，但必须保证系统一致性。

- 秒级优化关注局部完单与体验

- 分钟级优化关注供给重配置效率

- 小时级优化关注供需稳态

不同尺度优化之间存在冲突，需要通过约束与因果建模保证一致性。

交易优化不是单目标问题，而是体验、效率与长期价值的平衡。

- 接驾距离与完单的 tradeoff

- hold 的短期收益与长期风险

- 扩播半径与体验的张力

早期：max 完单

现在：max 完单 - λ × 体验损失 

未来：长期价值函数

问题抽象：当前来看，很多都是带约束的优化问题，这些方法可以迁移到无单调度、召回、扩播半径等多个场景。

背景，方案，问题，迭代引出下一版本；

关于调度，

- 介绍连乘版本为第一版，连乘版本的流程，方案，模型，特征等需要eve中获取，然后画出来模型结构图，还有实验效果，之后模型迭代但是实验效果并没有提升，迭代陷入瓶颈，然后考虑用因果推断的方案，引出调度-V2，V1和V2版本的对比，V2的方案，V2的模型结构，实验效果，设计随机调度实验也可以提一下。

关于召回策略优化：

- 是否要浅浅带一下之前的一些工作？乘客应答后取消率模型搭建，然后通过阈值过滤？需要想清楚这样做的原因是？对未来迭代的启发是？

- 现在到了应答前后取消率的trade off，但是其实本质思想是，当前分单和当前不分单的【取消率】的差异，直接预测应答前后取消率，然后将应答前取消率作为应答后取消率的阈值，但是这种其实不是

### 项目逻辑梳理

![](e4aba6a109e133b8-流程图.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwNzIzMjIwNjczMA", "version": "2", "fileUrl": "../../../%E9%99%84%E4%BB%B6/e4/e4aba6a109e133b8-%E6%B5%81%E7%A8%8B%E5%9B%BE.svg"}
```

主要做的项目是司机调度、动调调度、商家交易、交易体验

分别要优化效率价值和体验价值，效率价值包含【调度】和【商家交易】，体验当前从接驾距离入手，

接驾体验如何和交易效率融合？

![](7567a404d2735f02-流程图.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwNjkyOTIzMDQ0MA", "version": "10", "fileUrl": "../../../%E9%99%84%E4%BB%B6/75/7567a404d2735f02-%E6%B5%81%E7%A8%8B%E5%9B%BE.svg"}
```

交易的主要工作是完成**订单****和司机****在一定****时空****内的匹配。**

#### 时空匹配

交易系统不只是一个瞬时决策，而是一个跨时间、跨空间尺度的连续决策系统，不同时空下适合的匹配方式是不同的。

| **↓时间 / → 空间** <br> | **&lt; 常规播单半径km** <br> | **&gt; 常规播单半径km** <br> |
| :---: | :---: | :---: |
| **&lt; 300ms** <br> | TopSpeed分单 <br> | **轮次分单：乘客价值 iph + 终点价值（听单间隔、gmv、呼叫）** <br> |
| **&lt; Ns** <br> | 轮次分单优化：**gs分单中乘客价值：iph + 订单流失率** <br> |
| **订单生存周期** <br>**（&lt; 应答前取消）** <br> | - **订单hold、司机hold** <br><br>- **订单全生命周期max完单** <br><br> |
| **min级别** <br> |   <br> | 司机无单调度、**动调调度** <br> |
| **小时级别** <br> | **路线调度（针对新司机）** <br> |
| **数小时级别** <br> | **全调度** <br> |

> **横轴是空间尺度：常规播单半径内**，匹配是“就地解决”；**超过常规播单半径**，更长期、更全局的匹配视角。

> **纵轴是时间尺度**，从毫秒级到分钟、小时级，代表系统**允许交易匹配的反应时间和视野**，时间越短，越偏向局部、贪心；时间越长，越偏向全局规划。

> 时间从秒级、并进入订单生命周期，**这是在不断放大解空间的过程；**

> 当时间尺度上升到分钟甚至小时级，我们已经完全脱离了“分单”本身，进入了**通过调度对更大范围供需结构优化，**这些策略不是为“当前订单”服务的，而是为“未来系统状态”服务的；

> **在不同的时间和空间尺度下，交易系统解决的问题层层递进：从“怎么尽快把单子发出去”，到“怎么在生命周期内最大化完单”，再到“怎么让供需系统更平衡、更健康”。**

### 无单调度-V1

#### 背景：

- **司机和乘客的自然分布经常出现错配**：某个区域的司机长时间听不到单，处于空驶状态，而某个区域的乘客长时间打不到车，这种供需不平衡的情况影响了司机的负载率和乘客的打车体验，降低了司乘匹配效率。

- **司机虽然具备一定的自发迁移能力，但是缺乏全局视角**：根据历史经验前往高需求区域，但该行为具有明显局限性，信息滞后可能导致供给过多，群体行为形成拥挤效应，司机自发的迁移决策缺乏全局最优视角，

- **司机长时间听不到单会下线，**平台有效供给收缩，短期影响完单率，长期供需稳定性也会下降。

司机调度是指针对长时间听不到单的司机，平台基于全局供需信息，下发拥有里程费和无单补贴调度任务，将司机牵引到接单概率更高的区域，降低司机听单间隔，提高司机收入，TSH，带动大盘完单提升。

司机调度产品形态：

| **调度任务下发** <br> | **调度行程中** <br> | **达到目的地领里程费** <br> | **目的地等单中** <br> | **无单补贴** <br> |
| :---: | :---: | :---: | :---: | :---: |
| ![](afbd41ce2136ae78-image.png) <br> | ![](4d0f687b55a63b3a-image.png)![](931503703a18539b-image.png) <br> | ![](3d33707dc1f5a4a2-image.png)![](164a4db2198a4a91-image.png) <br> | ![](55a45c590b66a8ed-image.png) <br> | ![](fbe7d676c333092c-image.png)![](057890240b69576d-image.png) <br> |

#### 司机调度流程：

![](fb5ac9b2095690f1-流程图.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwNjg5NTQwODk5Nw", "version": "9", "fileUrl": "../../../%E9%99%84%E4%BB%B6/fb/fb5ac9b2095690f1-%E6%B5%81%E7%A8%8B%E5%9B%BE.svg"}
```

#### 问题定义

|  <br> |  V1 <br> |
| --- | :---: |
| GMV <br> | $$\Delta GMV = \sum_{i=1}^{n} \sum_{j=1}^{m} \left( accept_{ij} \cdot p_{ij} + (1 - accept_{ij}) \cdot q_{ij} - r_{ij} \right) \cdot z_{ij} \cdot afr_{j} \cdot asp_{j}$$ <br>离线比较下发调度未接受和未下发调度任务的司机在未来一段时间接单概率发现二者差异不大，同时为了简化建模，令 q_ij = r_ij ，即假设调度策略不影响司机原地接单概率。 <br>$$\Delta GMV = \sum_{i=1}^{n} \sum_{j=1}^{m} z_{ij} *accept_{ij}  * (p_{ij} - q_{ij}) * afr_j * asp_j$$ <br><table><tr><th>**变量** <br></th><th>**含义** <br></th></tr><tr><td>$$z_{ij}$$ <br></td><td> {0,1}，司机i是否调到格子j <br></td></tr><tr><td>$$accept_{ij}$$ <br></td><td> \[0,1\]，司机i接受格子j调度任务的概率 <br></td></tr><tr><td>$$p_{ij}$$ <br></td><td> \[0,1\]，司机i接受格子j调度任务条件下的接单概率（目的地或中途接单） <br></td></tr><tr><td>$$q_{ij}$$ <br></td><td> \[0,1\]，司机i不接受或不下发格子j调度任务条件下的接单概率 <br></td></tr><tr><td>$$afr_{j}$$ <br></td><td> \[0,1\]，格子j履约率 <br></td></tr><tr><td>$$asp_{j}$$ <br></td><td> \[0,1\]，格子j的asp <br></td></tr></table> |
| Cost <br> | $$\Delta COST = \sum_{i=1}^{n} \sum_{j=1}^{m} z_{ij} * accept_{ij} * arrive_{ij} * \left( fee_j * eda_j + s_{ij} * subsidy_{ij} \right)$$ <br><table><tr><th>**变量** <br></th><th>**含义** <br></th></tr><tr><td>$$arrive_{ij}$$ <br></td><td> \[0,1\]，司机i到达格子j的概率 <br></td></tr><tr><td>$$fee_{j}$$ <br></td><td> 里程费 <br></td></tr><tr><td>$$eda_{ij}$$ <br></td><td>司机i到格子j路面距离 <br></td></tr><tr><td>$$subsidy_{ij}$$ <br></td><td>司机i到格子j路面距离 <br></td></tr></table> |
| 格子可调司机数量限制 <br> | $$\sum_{i=1}^{n} z_{ij} * accept_{ij} * arrive_{ij} \le nobroad_{j}$$ <br><table><tr><th>**变量** <br></th><th>**含义** <br></th></tr><tr><td>$$nobroad_{j}$$ <br></td><td>格子j未播订单数 <br></td></tr></table> |
|  <br> |  <br> |

> [delta_GMV和delta_COST推导过程](https://cooper-vpn.xiaojukeji.com/knowledge/2199610335356/2203816901038)

变量 

| **变量** <br> | **含义** <br> |
| :---: | :---: |
| $$z_{ij}$$ <br> |  {0,1}，司机i是否调到格子j <br> |
| $$accept_{ij}$$ <br> |  \[0,1\]，司机i接受格子j调度任务的概率 <br> |
| $$p_{ij}$$ <br> |  \[0,1\]，司机i接受格子j调度任务条件下的接单概率（目的地或中途接单） <br> |
| $$q_{ij}$$ <br> |  \[0,1\]，司机i不接受或不下发格子j调度任条件下的接单概率 <br> |
| $$afr_{j}$$ <br> |  \[0,1\]，格子j履约率 <br> |
| $$asp_{j}$$ <br> |  \[0,1\]，格子j asp <br> |
| $$midor_{ij}$$ <br> |  \[0,1\]，格子j asp <br> |
| $$fee_{j}$$ <br> |  里程费 <br> |
| $$eda_{ij}$$ <br> | 司机i到格子j路面距离 <br> |
| $$subsidy_{ij}$$ <br> | 司机i到格子j路面距离 <br> |
| $$arrive_{ij}$$ <br> |  \[0,1\]，司机i到达格子j的概率 <br> |
|  <br> |  <br> |
| $$nobroad_{j}$$ <br> | 格子j未播订单数 <br> |
| $$empty_{j}$$ <br> | 格子j空车司机数 <br> |

#### 模型结构：

需要看特征， 以及模型为啥这样设计

==n==o order> dmaster > arrived > accept > origin

![](a2962d2c1176f6ea-流程图.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwNjkwNTQ5MjE2MA", "version": "1", "fileUrl": "../../../%E9%99%84%E4%BB%B6/a2/a2962d2c1176f6ea-%E6%B5%81%E7%A8%8B%E5%9B%BE.svg"}
```

![](1c19430f69a390b6-image.png)<!--评论:[{"u":"rileywu","c":"模型结构中各个模块的输出需要重新梳理"}] -->

#### 实验效果：

| **指标** <br> | **Control Group Metric** <br> | **treatment group metric** <br> | **absolute uplift** <br> | **relative improvement** <br> |
| :---: | :---: | :---: | :---: | :---: |
| 自营宏鹄 司机人均GMV <br> | 545.1014 <br> | 554.5127 <br> | **+9.4113** <br> | +1.73% <br> |
| 自营宏鹄司机人均完单 <br> | 33.0859 <br> | 33.6172 <br> | **+0.5312** <br> | +1.61% <br> |
| 自营宏鹄司机人均在线时长 <br> | 1341.7216 <br> | 1357.9092 <br> | **+16.1876** <br> | +1.21% <br> |

### 无单调度-V2

#### 背景（V1的问题）

- **模型预计误差叠加**：调度v1策略整体分为两步：ML+OR（Operation Research）：

	- **ML部分预测运筹规划求解需要的gmv、cost**，该部分会建立多个模型（司机接受度模型，司机原点格子接单概率，司机中途或者目的地接单概率，司机达到率模型，未播订单数模型），分别预测链路中的各个环节，通过上述模型结果去计算司机调度*(司机-格子对)*带来的gmv提升和对应的cost；

	- **OR部分基于ML给出的司机-格子对的gmv、cost，求解【roi约束下最大化gmv目标】的调度策略**，并下发给司机。

	- ML部分预测的gmv、cost，一方面ML部分涉及到若干个模型，难以拆解每个模型优化对gmv，cost预测的优化效果，其次输入ML部分预测的gmv,cost输入到黑盒的运筹规划当中，ML的误差会在运筹规划中被进一步叠加。

- **离线效果与线上效果存在diff**：离线模型均用于评估模型预估的准确性，但无法用于刻画模型在线上生效带来的收益，且模型的评估是独立的，并非整体评估。

针对以上问题，V2通过因果视角建模，搭建随机调度的RCT数据，预测treatment下的 GMV 和 cost，从整体调度链路来看，核心改动下图中红框内的格子-司机的匹配算法。

![](7098bcd6c5359fbd-流程图.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwNjkwNjUxMDY4MA", "version": "4", "fileUrl": "../../../%E9%99%84%E4%BB%B6/70/7098bcd6c5359fbd-%E6%B5%81%E7%A8%8B%E5%9B%BE.svg"}
```

#### 无单调度-V1和无单调度-V2的区别：

| **改进角度** <br> | **方案v1** <br> | **方案v2** <br> |
| :---: | :---: | :---: |
| **方案设计** <br> | **做法：**拆分调度各过程进行建模‏，**需要搭建5个模型**（起点、中途、目的地接单率‏、司机接受度、未播订单数模型） <br>  <br>**问题：** <br>- 需要建立的**ML模型数量过多** <br><br>- 概率模型预测的是司机“自然状态”下的接单行为，**无法准确估计调度干预本身带来的​​增量效果​** <br><br> | **做法：**使用一个因果uplift模型（drcfr模型），直接预测gmv与cost‏建模 <br>  <br>**优势：** <br>- 降低**模型数量**，维护更简单。 <br><br>- 简化链路，**减少**之前复杂链路造成的**累积误差**。 <br><br>- **从相关到因果**：因果模型直接估计“调度与否”这一​​干预行为​​对完单的影响，使决策更精准。 <br><br> |
| **策略生成** <br> | **做法：**运筹规划生成策略 <br>  <br>**问题：**运筹规划阶段误差积累 <br>运筹规划需要ML模型预测值很准‏ <br> | **做法：**放弃全局最优，利用贪心选取决策因子排序过滤后的结果 <br>  <br>**优势：‏** <br>- **对绝对数值精度依赖低**：​​OR优化严重依赖接单概率预测值的​​绝对准确性​​。贪心排序基于​​相对优先级，对绝对数值的误差不敏感，鲁棒性更强。 <br><br>- **计算效率‏‏**：运筹规划考虑全局最优，计算成本高。**贪心排序算法计算高效**，更适合大规模实时调度场景。 ‏ <br><br> |
| **模型评估** <br> | **做法：**by模型优化和评估 <br>  <br>**问题：**没有一个能够和业务目标保持一致的评估指标 <br> | **做法**：提出了端到端的评估指标 DISPATCH-AUCC <br>  <br>**优势：**DISPATCH-AUCC通过**模拟真实调度过程**，增强**模型优化和业务效果的一致性**。 <br> |

#### 问题定义：

$$\begin{aligned} \max \; GMV_{\text{global}}  &= \max \sum_{\text{round}} GMV_{\text{round}} \\ \text{s.t.} \quad  \Delta GMV_{\text{global}}  &\ge ROI \times \Delta COST_{\text{global}} \end{aligned}$$ 

每一轮的调度策略会影响下一轮，但是轮次之间的影响难以刻画，因此该版本问题由全局最优（Global）简化为单轮最优：

 $$\begin{gathered} \sum_{\text{round}} \max GMV_{\text{round}} \\ \text{s.t.} \quad  \Delta GMV_{\text{global}} \ge ROI \times \Delta COST_{\text{global}} \end{gathered}$$

==由于仅需确保整体ROI符合预设的ROI约束条件，我们可以将整体ROI分解为各轮次的ROI（==$$\text{ROI}_{\text{round}}$$==），随后通过实时调控每一轮的ROI，以保障整体ROI满足约束要求==

$$\begin{gathered} \sum_{\text{round}} \max \; GMV_{\text{round}} \\ \text{s.t.} \quad  \sum_{\text{round}} \Delta GMV_{\text{round}} \ge  \sum_{\text{round}} ROI_{\text{round}}  \times  \Delta COST_{\text{round}} \end{gathered}$$

我们定义调度场景的个体为司机-格子对(i-j)，干预为司机-格子对(i,j)是否下发调度，由此单轮最大化gmv的问题定义如下（**PPT 中可以只写这个？**）：

$$\begin{aligned} \max \quad  & GMV_{\text{round}} = \sum_{i=1}^{n} \sum_{j=1}^{m} \sum_{k=0}^{K-1} gmv_{ijk} \, z_{ijk}  \\[6pt] \text{s.t.} \quad  & \sum_{i=1}^{n} \sum_{j=1}^{m} \sum_{k=0}^{K-1} \big( gmv_{ijk} - gmv_{ij0} \big) z_{ijk} \\ & \quad \ge  ROI_{\text{round}} \sum_{i=1}^{n} \sum_{j=1}^{m} \sum_{k=0}^{K-1} \big( cost_{ijk} - cost_{ij0} \big) z_{ijk} \qquad \text{(ROI约束)} \\[6pt] & \sum_{k=0}^{K-1} z_{ijk} = 1 \qquad \forall i,j \qquad \text{(每个司机-格子对选择一个策略)} \\[6pt] & \sum_{j=1}^{m} z_{ij1} \le 1 \qquad \forall i \qquad \text{(每个司机最多调度到一个格子)} \\[6pt] & \sum_{i=1}^{n} z_{ij1} \le \text{未播订单数}_j \qquad \forall j \qquad \text{(格子容量约束)} \\[6pt] & z_{ijk} \in \{0,1\} \end{aligned}$$

上述问题中，单轮GMV可以用所有格子-司机对的gmv的和来表示，同时我们需要满足如下约束：

- 调度需要满足roi的约束

- 对一个司机来说至多只能调度到一个格子

- 1个格子当前轮次能调度的司机至多为N个（N为未播订单数，因为当前**召回的格子97%的未播订单数小于等于1，因此后续该约束为1**）

- 由于目前我们只有调度这个策略所以K=2。

#### 拉格朗日松弛

**为了简化问题求解， 我们先考虑对ROI约束进行拉格朗日松弛，**其余约束仍在优化中显式（其他约束会在后链路过滤，优化阶段先忽略这些耦合约束以获得可分解的打分形式）。

$$\begin{aligned}  \max_{z}\;\min_{\lambda \ge 0} \quad & \sum_{i=1}^{n}\sum_{j=1}^{m}\sum_{k=0}^{1} gmv_{ijk}\, z_{ijk} \;+\; \lambda\Bigg( \sum_{i=1}^{n}\sum_{j=1}^{m}\sum_{k=0}^{1} (gmv_{ijk}-gmv_{ij0})\, z_{ijk} \\[-2pt] &\hspace{50pt} -\; ROI_{\text{round}} \sum_{i=1}^{n}\sum_{j=1}^{m}\sum_{k=0}^{1} (cost_{ijk}-cost_{ij0})\, z_{ijk} \Bigg) \qquad  \\[8pt] \text{s.t.}\quad & \sum_{k=0}^{1} z_{ijk} = 1,\qquad \forall i,j \qquad \text{(策略选择约束：每个司机-格子对选择一个策略)} \\[6pt] & \sum_{j=1}^{m} z_{ij1} \le 1,\qquad \forall i \qquad \text{(司机约束：每个司机最多调度到一个格子)} \\[6pt] & \sum_{i=1}^{n} z_{ij1} \le \text{1},\qquad \forall j \qquad \text{(格子容量约束)} \\[6pt] & z_{ijk}\in\{0,1\},\qquad \forall i,j,k \qquad \text{(0-1 决策变量)} \end{aligned}$$

原问题中 ROI 约束将所有 i,j,k 的决策全局耦合，导致直接优化困难。 通过拉格朗日松弛引入价格 λ，将全局 ROI 约束转化为局部价格信号。 固定 λ 后，内层问题转化为可排序/可分解的打分优化，**==我们将其转化为==****对偶问题：**

$$\begin{aligned}   \min_{\lambda \ge 0}\max_{z} \quad & \sum_{i=1}^{n}\sum_{j=1}^{m}\sum_{k=0}^{1} gmv_{ijk}\, z_{ijk} \;+\; \lambda\Bigg( \sum_{i=1}^{n}\sum_{j=1}^{m}\sum_{k=0}^{1} (gmv_{ijk}-gmv_{ij0})\, z_{ijk} \\[-2pt] &\hspace{50pt} -\; ROI_{\text{round}} \sum_{i=1}^{n}\sum_{j=1}^{m}\sum_{k=0}^{1} (cost_{ijk}-cost_{ij0})\, z_{ijk} \Bigg) \qquad  \end{aligned}$$

固定 λ 后，ROI 约束已价格化。为得到可分解的近似解，我们**暂时忽略司机侧跨格子容量耦合约束（司机只能被一个格子调度，该约束后续会满足），**从而问题在格子维度可分解为$$\sum_j \max(\cdot)$$结构。

$$\begin{aligned} \min_{\lambda \ge 0} \sum_{j=1}^{m} \sum_{i=1}^{n}\max_{z}\sum_{k=0}^{1} {z_{ijk}*( gmv_{ijk} + \lambda * (gmv_{ijk}-gmv_{ij0}) - \lambda * ROI_{\text{round}}*(cost_{ijk}-cost_{ij0}) )} \end{aligned}$$

#### 决策公式

按照以上的公式，需要对每个$$\lambda$$ ， 司机j的$$\text{gmv}_{ijk} + \lambda \times  \left[ (\text{gmv}_{ijk} - \text{gmv}_{ij0} - \text{ROI}_{\text{round}}(\text{cost}_{ijk} -\text{cost}_{ij0} ))  \right]$$的排序准才能做最佳决策，所以我们模型的性能依赖于不同的$$\lambda$$，然而在评估模型时测试所有的$$\lambda$$下公式的排序较困难， 为了解决这个问题我们通过推到得到了一个新的决策公式

具体的，对应每一个司机-格子对，只有当调度带来的gmv > 不调度的gmv且整体满足ROI约束，我们才会考虑下发调度：

> $$\lambda^*$$ 是“松弛后的对偶最优”

$$gmv_{ijk} + \lambda^* \left( \Delta gmv_{ijk} - ROI_{\text{round}} \cdot \Delta cost_{ijk} \right) \;\ge\; gmv_{ij0}$$

移项得到：

$$(1+\lambda^*)\underbrace{(gmv_{ijk}-gmv_{ij0})}_{\Delta gmv_{ijk}} - \lambda^* ROI_{\text{round}}\, \underbrace{(cost_{ijk}-cost_{ij0})}_{\Delta cost_{ijk}} \ge 0$$

也就是：

$$(1+\lambda^*)\Delta gmv_{ijk} \ge \lambda^* ROI_{\text{round}}\,\Delta cost_{ijk}$$

因为$$\Delta cost_{ijk} > 0$$，因此：

$$\begin{aligned} \frac{\Delta gmv_{ijk}}{\Delta cost_{ijk}} = roi_{ijk} \ge \frac{\lambda^* ROI_{\text{round}}}{1+\lambda^*} \end{aligned}$$

决策公式$$roi_{ijk} \;\ge\; \frac{\lambda^* \, ROI_{\text{round}}}{1+\lambda^*}$$，相对比原始的决策公式  $$\text{gmv}_{ijk} + \lambda \times  \left[ (\text{gmv}_{ijk} - \text{gmv}_{ij0} - \text{ROI}_{\text{round}}(\text{cost}_{ijk} -\text{cost}_{ij0} ))  \right]$$，依赖$$\lambda$$的方式更简单了（从一个复杂打分函数，变成一个阈值），因此我们只需要保障$$\text roi_{ijk}$$的排序准确即可。

上述求解过程中，我们暂时先忽略了司机只能调度到一个格子，格子只能调度一个司机的限制

#### 排序 & 过滤保证调度约束

我们明确将司机与格子对调度的$$\text roi_{ijk}$$作为调度的决策指标。对于那些调度roi较高的司机-格子组合，我们需要优先进行调度下发。线上生效流程具体如下：

- **步骤1**：在每一轮中，召回司机-格子对，并对司机-格子对的roi及GMV进行预测

- **步骤2**：将司机-格子对按照roi进行降序排序，并依据阈值确定可用于下发调度的司机-格子候选集合。具体而言，我们使用ROI限制和DISPATCH AUCC曲线来初始化阈值（其核心思路在于离线确定累计增益值最高的点）。

- **步骤3**：为确保满足决策约束条件，我们采用二次过滤方法：

	- **司机约束**：每个司机i最多仅能被调度至1个格子，针对每位司机，我们仅保留预测GMV最高的格子，

	- **格子约束：**每个格子j最多只能接受1个司机

基于上述步骤，我们得出了当前轮次需要下发调度的司机 - 格子集合。具体的排序及过滤流程图如下所示：

![](d5a0dfa8096d645b-image.png)

因此整体流程：

![](a844dbe07afff450-流程图.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwNjkxMDE4NzQ5NQ", "version": "5", "fileUrl": "../../../%E9%99%84%E4%BB%B6/a8/a844dbe07afff450-%E6%B5%81%E7%A8%8B%E5%9B%BE.svg"}
```

#### 模型整体框架：

因果uplift模型预测cost（考虑了接受度、到达率等） 和 finish（中途），

|  <br>**标签** <br> | ** 标签定义** <br> |
| :---: | :---: |
|  finish_label <br> | 在0 到 eta+10 司机是否接单 <br> |
| cost_label <br> | 在0 到 eta+10 司机产生cost的金额 <br> |

![](f948b3fd4650dcda-流程图.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwNjkxMDIwODYwMw", "version": "1", "fileUrl": "../../../%E9%99%84%E4%BB%B6/f9/f948b3fd4650dcda-%E6%B5%81%E7%A8%8B%E5%9B%BE.svg"}
```

调度模型的框架图

#### UPLIFT 模型

我们使用DRCFR+多头的模型结构来预测不同干预（**调度/不调度**）的完单率和调度费用

![](c5ec501a7571dd60-image.png)

UPLIFT模型的结构图

##### 随机调度实验

- **背景：**uplift模型的训练及评估依赖于随机调度实验，为了降低开发成本我们决定召回所有司机进行调度整体的流程并且在播单阶段只下发需要下发调度的司机（司机分流）。直接使用次方会带来数据 不平衡的问题， 本章的目标是通过流程上的小改造来解决数据不平衡的问题。

- **核心解决的问题**：司机分流下调度存在轮与轮之间**对照组司机挤占实验组司机流量的问题(左图)**。具体而言，当前轮召回的实验组和对照组司机在下一轮的表现并不一致，实验组司机下发调度任务以后再下一轮不会被召回，但对照组司机虽然下发了调度任务但在播单环节不会真实下发调度任务，所以在下一轮的调度环节仍旧会被召回，导致一些需要下发调度任务的实验组司机由于上一轮对**照组司机重复下发调度任务** 无法被成功下发，使得对照组和实验组的分布不一致

- **解决方案：**通过每轮重新分配司机分组可解以上提出的挤占问题，具体流程如下（右图）：

![](504a29f8d40dc517-附件.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwNjkxMTU1OTE2MA", "version": "0", "fileUrl": "../../../%E9%99%84%E4%BB%B6/50/504a29f8d40dc517-%E9%99%84%E4%BB%B6.svg"}
```

随机调度流程图

评估指标：uplift模型可以通过AUCC来评估模型排序的好坏，并判断线上的收益的正向程度，确保离在线的一致性。但在调度场景这个一致性是不成立的，原因在于dp对的干预不是独立的，对同一个司机我们只能给定一个策略，即司机最多只能调度到一个格子，同样对格子而言，最多只能被调入一个司机。但是在计算AUCC的时候部分策略不允许下发（二次过滤逻辑）会被在ATE中计算， ATE和实际ATE存在误差。

![](b945e1ea81d1b042-dispatch-aucc_1_Autosaved_.gif)

| **模型** <br> | **DRCFR** <br> | **双塔** <br> | **V1** <br> |
| :---: | :---: | :---: | :---: |
| **DISPATCH AUCC** <br>（召回数据） <br> | ![](9a49d630a57b95bb-image.png) <br> | ![](19eeb850f36e0bd4-image.png) <br> |  <br> <br> |
| **面积** <br> | **1.1256e10** <br> | 0.4265e10 <br> |  <br> |
| **COST MAPE** <br>（播单数据） <br> | **0.3883** <br> | 0.3897 <br> | ![](2fd656bf53a169d1-image.png) <br>0.3984 <br> |
| **finish AUC** <br>（播单数据） <br> | **0.7193** <br> | 0.6838 <br> |  <br> |

- **贪心在实际应用中的优势：对比贪心和运筹规划**

在模型预测完全准确的情况下，运筹规划算法（追求全局最优）的求解效果会优于贪心算法（仅考虑局部最优）。然而，实际应用中训练零误差模型难度很大，且模型精度的提升未必能改善运筹规划算法的求解效果。实验结果表明**，在当前模型条件下，贪心算法在多数情况下比运筹规划算法能获得更好的收益**，如下图所示：

![](bd9950eaab2bc69c-图片.png)

#### 实验效果

![](2ad0348f12d2c85b-image.png)

### 商家召回策略优化

商家召回

商家召回策略优化-以完单为目标

商家交易以商家完单为目标，在召回侧做优化，

小猪商家分单引擎中的订单侧召回策略V1.0主要基于[**动态播单半径的策略**](https://cooper.didichuxing.com/knowledge/2199610335356/2202866696195)：

1. 基于供需和订单里程确定订单召回半径，对高供需场景订单进行动态缩播，在不折损商家应答的情况下降低应答后司乘取消；

2. 通过平台侧传入的订单预估等待应答时长在乘客等待期间进行竞争视角下的扩播，保证商家竞争应答率；

**策略核心是在商家竞争视角下，通过供需状况及等待时间进行召回半径的动态调整，订单流失前尽可能找到更近的运力。**

召回策略V1希望平衡**竞争应答率**和**应答后履约率**来探索商家成交率最大化，但其并没有显示建模【应答前取消率（流失率）】和【应答后取消率】，只是通过策略中**等待应答时长衡量订单流失率，**用 ETA/接驾距离作为影响应答后取消的关键因子。

| 符号 <br> | 含义 <br> |
| --- | --- |
| i  <br> | 订单i <br> |
| j  <br> | 表示司机j <br> |
| $$DO_{ij }$$ <br> | 召回订单i 和 司机 j组合 <br> |
| $$caa_{ij}$$ <br> | 某个$$DO_{ij}$$对组合下的应答后司机取消率； <br> |
| $$\mathcal{S}_{it} = \left\{\varnothing，S^{(1)},\, S^{(2)},\, \ldots,\, S^{(K)} \right\}$$ <br> | 在时刻 t 对订单 i 可选的召回集合候选集，$$\varnothing$$表示空集，不召回 <br> |
| $$p_{ij}(S)$$ <br> | 召回S集合内的$$DO_{ij}$$的最终胜出概率 <br> |
| $$P_i(S) = \sum_{j \in S} p_{ij}(S)$$ <br> | 在召回集合 S下，订单最终被任一司机应答的概率 <br> |
| $$\begin{aligned}  P(取消|S)= \sum_{j \in S} p_{ij}(S)\, caa_{ij}  \end{aligned}$$ <br> | 某个时刻在召回集合S的取消概率； <br> |
| $$E(CAA \mid \text{应答}, S) = \frac{\sum_{j \in S} p_{ij}(S)caa_{ij}} {\sum_{j \in S} p_{ij}(S)}$$ <br> | 在订单已经被司机应答的前提下，发生取消的概率 <br> |
| $$OCR_{it}$$ <br> | 流失率：占某个商家视角，订单i，在t时刻应答前取消或者被其他商家抢走的概率； <br> |
| $$V_{future}$$ <br> | 当前轮次不召回未取消，未来应答完单的概率 <br> |
| - $$P^{base}_{i,t+\Delta}$$ <br><br> | 商家在下一轮的应答概率（在竞争态里这是最难的那块） <br> |
| - $$E^{base}_{future})$$= $$\mathbb E(CAA\mid应答,\text{baseline at }t+\Delta)$$ <br><br> | 商家在下一轮的订单已经被司机应答的前提下，发生取消的概率 <br> |

理论上单轮召回策略应该是选择全部召回组合内选择完单最大的一组作为召回组合，因为订单已经存活到当前轮次，那么目标为：

召回组合不为0时候的

 $$\begin{aligned}  \max_{\{S_i\}} \sum_{i}   CR_i(S) \end{aligned}$$

因为一个司机连接多个订单的占比只有6%，跨订单共享司机等耦合弱 ⇒ 近似可分解，max 可以进入到sum内部

 $$\begin{aligned} \max_{\{S_i\}} \sum_{i}   CR_i(S) \approx \sum_{i}  \max_{\{S_i\}}  CR_i(S) \end{aligned}$$，

对于订单i，如果召回集合不为空，$$\begin{aligned}  CR_i(S) =  \sum_{j \in S_i} p_{ij}(S_i)\bigl(1 - caa_{ij}\bigr)，S_i \neq  \varnothing  \end{aligned}$$

不召回，也就是并且$$CR_{i}(\varnothing) = (1-OCR_{it}) * V_{future} , S_i = \varnothing$$，

单轮召回的最优决策公式：

$$\begin{aligned} S_i^{*} = \arg\max_{S \in S_{it} } CR_i(S) \end{aligned}$$

如果最优召回组合带来的完单概率还不如“不召回”，那就不召回，：

$$S_i^{*} = \begin{cases} \arg\max_{S \in \mathcal{S}_{it}} CR_i(S), & CR_i(S_i^{*}) > (1 - OCR_{it})V_{future} \\ \varnothing, & \text{otherwise} \end{cases}$$

核心比较是：

$$CR_i(S) > (1 - OCR_{it})V_{future}$$

左边展开：

 $$CR_i(S) = \sum_{j \in S} p_{ij}(S)(1 - caa_{ij}) = \underbrace{\sum_{j \in S} p_{ij}(S)}_{P_i(S)} - \underbrace{\sum_{j \in S} p_{ij}(S)caa_{ij}}_{P(\text{取消}\mid S)}  = P_i(S) -  P_i(S)\cdot E(CAA\mid \text{应答},S)$$

$$CR_i(S) = \sum_{j \in S} p_{ij}(S)(1 - caa_{ij})  = P_i(S) -  P_i(S)\cdot E(CAA\mid \text{应答},S)$$

带回上面不等式：

$$P_i(S)\bigl(1-E(CAA\mid \text{应答},S)\bigr) > (1-OCR_{it})V_{future}$$

下一轮按最优触达后的完单：$$V_{future} \approx P^{base}_{i,t+\Delta} \cdot (1 - E^{base}_{future})$$

- $$P^{base}_{i,t+\Delta}$$= 商家在下一轮的应答概率（在竞争态里这是最难的那块）

- $$E^{base}_{future})$$= $$\mathbb E(CAA\mid应答,\text{baseline at }t+\Delta)$$

因此上面的决策条件为：

$$P_{i,t}(S)(1 - E_{now}) > (1 - OCR)\cdot P^{base}_{i,t+\Delta}(1 - E_{future})$$

假设：$$P_{i,t}(S) \approx P^{base}_{i,t+\Delta} \triangleq P$$，两边除以$$P  > 0$$

$$1 - E_{now} > (1 - OCR)(1 - E_{future})$$

等价于：

$$E_{now} < 1 - (1 - OCR)(1 - E_{future})$$

也就是：

$$E_{now} < OCR + (1 - OCR)E_{future}$$

**如果当前召回组合的应答后取消率低于“等待带来的等效取消率”，要max完单，就召回。**

到此，我们已经把问题从最大化完单，转化为了最小化应答后取消率的期望，同时用$$OCR + (1 - OCR)E_{future}$$作为阈值约束

$$S_i^{*} = \begin{cases} \arg\max_{S \in \mathcal{S}_{it}} CR_i(S), & E(CAA \mid \text{应答}, S_i^{*}) < OCR_{it} + (1-OCR_{it})E_{future} \\[6pt] \varnothing, & \text{otherwise} \end{cases}$$

假设未来匹配质量很好$$E_{future} = 0$$，我们将约束收紧，阈值变得更严格

$$S_i^{*} = \begin{cases} \arg\max_{S \in \mathcal{S}_{it}} CR_i(S), & E(CAA \mid \text{应答}, S_i^{*}) < OCR_{it} \\[6pt] \varnothing, & \text{otherwise} \end{cases}$$

$$E(CAA\mid \text{应答},S) < OCR_{it}$$

expand

单轮决策公式变为：

$$S_i^{*} = \arg\min_{S \in S_{it}} E(CAA \mid \text{应答}, S)$$

判断是否低于阈值

$$E(CAA \mid \text{应答}, S_i^{*}) < OCR_{it}$$

如果成立：$$S_i^{*} = \arg\min_{S \in S_{it}} E(CAA \mid \text{应答}, S)$$，否则：$$S_i^{*} = \varnothing$$

带约束的优化问题？？
当前t时刻，已知订单仍然存活，此时需要选择召回策略，此时的成交率：$$CR_{it}(S) = \sum_{j=0}^{m} p_{ij}(S) \left(1 - caa_{ij}\right)$$，并且$$CR_{it}(\varnothing) = 0$$

目标：$$\begin{aligned} \max_{S \in \mathcal{S}_{it}} \sum_{j \in S} p_{ij}(S)\bigl(1 - caa_{ij}\bigr) \end{aligned}$$

约束：$$\begin{aligned} \sum_{j \in S} p_{ij}(S) \left( caa_{ij} - OCR_{it} \right) \le 0 \end{aligned}$$

> 决策函数：$$\begin{aligned} S_{it}^* = \arg\max_{S \in \mathcal{S}_{it}} CR_{it}(S) \end{aligned}$$

> 约束变换公式：$$\begin{aligned} \mathbb{E}\!\left[ CAA_{it}(S) \right] &\le CBA_{it} \\[8pt] \quad  \frac{\sum_{j \in S} p_{ij} \, caa_{ij}} {\sum_{j \in S} p_{ij}} &\le CBA_{it} \\[8pt] \quad  \sum_{j \in S} p_{ij} \, caa_{ij} &\le CBA_{it} \sum_{j \in S} p_{ij} \\[8pt] \quad  \sum_{j \in S} p_{ij} \left( caa_{ij} - CBA_{it} \right) &\le 0  \end{aligned}$$

#### 理论层面的方案

以上带约束的优化问题，使用拉格朗日松弛 + 对偶搜索，

$$\mathcal{L}(S,\lambda) = \sum_{j \in S} p_{ij}(S)\bigl(1 - caa_{ij}\bigr) - \lambda \left( \sum_{j \in S} p_{ij}(S)\bigl(caa_{ij} - ORC_{it}\bigr) \right)$$

两项合并

$$\begin{aligned} \mathcal{L}(S,\lambda) &= \sum_{j \in S} p_{ij}(S) \bigl((1 - caa_{ij}) - \lambda (caa_{ij} - ORC_{it})\bigr) \\ &= \sum_{j \in S} p_{ij}(S) \bigl(1 + \lambda ORC_{it} - (1+\lambda)caa_{ij}\bigr) \end{aligned}$$

原问题：

$$\begin{aligned} \max_{S \subseteq \mathcal{S}_{it}} \min_{\lambda \ge 0} \sum_{j \in S} p_{ij}(S) \bigl(1 + \lambda ORC_{it} - (1+\lambda)caa_{ij}\bigr) \end{aligned}$$

对偶问题：

$$\begin{aligned} \min_{\lambda \ge 0} \max_{S \subseteq \mathcal{S}_{it}} \sum_{j \in S} p_{ij}(S) \bigl(1 + \lambda ORC_{it} - (1+\lambda)caa_{ij}\bigr) \end{aligned}$$

固定lambda 的最优集合：

$$\begin{aligned} S(\lambda) = \arg\max_{S \subseteq \mathcal{S}_{it}} \sum_{j \in S} p_{ij}(S) \left( 1 + \lambda ORC_{it} - (1+\lambda)caa_{ij} \right) \end{aligned}$$

> max 是在固定 λ 下选最优 S

> min 是在所有 λ 中选一个，使“选完 S 之后的值”最小

关键在于$$p_{ij}(S)$$**是否依赖集合 S**。这决定了难度。

#### 

**情况 A：**$$p_{ij}(S)\approx p_{ij}$$**（不强依赖 S，或你用独立近似）,**对固定 λ，问题**可分解到每个候选**。

$$\begin{aligned}\max_{S \subseteq \mathcal{S}_{it}}\sum_{j \in S} p_{ij}(S)\bigl(1+\lambda ORC_{it} -(1+\lambda)caa_{ij}\bigr)\end{aligned}$$

于是最优选择规则是：对每个 j，算一个分数：

$$score_j(\lambda) = p_{ij} \big(1 + \lambda *ORC_{it} - \big(1 + \lambda\big) caa_{ij} \big)$$

- 如果 $$ORC_{it}-caa_{ij}>0$$（召回它“应答后取消更低”），那它对目标和约束都友好，**倾向于选**；

- 如果$$ORC_{it}-caa_{ij} < 0$$，选它会把约束推向违规，只有在目标收益足够大时才会被 λ允许。

**对固定 λ**：直接选所有 scorej(λ)>0 的 j（如果你还有限制如“最多召回K个/预算”，就按 $$score_j$$排序取前 K 个

**外层怎么找 λ**：用二分法（root finding）。

定义约束残差：

$$C(\lambda)=\sum_{j\in S(\lambda)} p_{ij}(caa_{ij}-ORC_{it})$$，我们希望$$C(\lambda)\le 0$$

$$\mathcal{L}(S,\lambda) = \sum_{j \in S} p_{ij}(S)\bigl(1 - caa_{ij}\bigr) - \lambda \left( \sum_{j \in S} p_{ij}(S)\bigl(caa_{ij} - ORC_{it}\bigr) \right)$$

$$\mathcal{L}(S,\lambda) = CR(S) -\lambda * g(S)$$

我们要求解

 $$\begin{aligned} \min_{\lambda\ge 0} d(\lambda) \end{aligned}$$，其中 $$\begin{aligned}  d(\lambda) = \max_{S} \mathcal{L}(S, \lambda)  \end{aligned}$$

很多条直线的最大值”必然是凸函数（碗状的）。如果直接d(λ)直接用三分法（大家常用的），有一个问题

- 可能在一个区间内完全平坦，有一段斜率为 0，可能跳变

- 比较 d(λ1) 和 d(λ2)， 它们可能一样大，这时你怎么缩区间？

- 

但是当前d(λ)虽然是分段函数不可导，但是在分段内是可导的，存在次梯度集合（可能合法斜率的集合），的斜率为：-g(s(λ))，其中，$$\begin{aligned} g(S) = \sum_{j \in S} p_{ij}(S) \left( caa_{ij} - ORC_{it} \right)  \end{aligned}$$

$$\partial d(\lambda)= - g\big(S(\lambda)\big)  = \sum_{j \in S(\lambda)} p_{ij}\big(S(\lambda)\big) \left( ORC_{it} - caa_{ij} \right)$$

g(s(λ))是现成的，最优 λ 在：斜率从负变正的地方 = g(S(λ)) 从正变负的地方

- λ 小 → 惩罚轻 → 系统更愿意选 g(S) 大的集合（哪怕违规）

- λ 大 → 惩罚重 → 系统更偏向 g(S) 小甚至负的集合

所以随着 λ 增大，内层最优解会越来越“守规矩”。$$g(S(\lambda))$$会单调不增（非连续单调，是阶梯式单调），严格证明如下：于是二分法可用：

**二分流程（工程版）**

1. 设$$\lambda_{low}=0$$，$$\lambda_{high}$$取一个足够大（比如不断翻倍，直到约束满足：$$g(S(\lambda_{high}))\le 0$$。

- while 未收敛：

	- 对每个候选集合的S都计算如下两项，后续任意λ计算都可以直接调用

	- $$\begin{aligned} CR(S) = \sum_{j \in S} p_{ij}(S)\left(1 - caa_{ij}\right)  \\  g(S) = \sum_{j \in S} p_{ij}(S)\left(caa_{ij} - ORC\right) \end{aligned}$$

	- $$\lambda=(\lambda_{low}+\lambda_{high})/2$$

	-  $$\begin{aligned} L(S,\lambda) = CR(S) -\lambda * g(S) \end{aligned}$$，选出最大的$$S(\lambda)$$，直接读取$$g(S(\lambda))$$

	- 若 $$g(S(\lambda)) \le 0$$：说明惩罚够了，$$\lambda_{high}=\lambda$$

	- 否则：$$\lambda_{low}=\lambda$$

- 输出$$S(\lambda_{high})$$

> 这样你每次评估一个 λ：

> **一次 argmax**

> 返回三件东西：(S(λ), d(λ), g(S(λ)) ）

证明：为什么 g(S(λ)) 不会上升？
![](f8cca32c03014961-image.png)

选择二分，不选择三分法的原因是？
关键点：d(λ)d(\\lambda)d(λ) 通常长这样（∪\\cup∪ 但折线、可能平底）：

- **有折点**

1. **可能一段区间完全一样（平坦）**

2. **不可导**

3. 内层 S(λ)S(\\lambda)S(λ) 会跳

三分法/黄金分割这类“只比较函数值”的方法，在这种折线/平坦场景下：

- 经常出现 d(λ1)≈d(λ2) （甚至相等），缩区间变得不稳定

4. 收敛方向依赖数值误差/平手处理

5. 最终你得到的 λ\\lambdaλ 未必是“最小可行惩罚”（工程上常想要这个）

**二分用的不是函数值，而是“斜率符号/次梯度符号”**，对折线凸函数更“天生匹配”。

**二分到底在二分什么？不是 d(λ)，而是 g(S(λ)) 的符号**

你真正想找的是：

- 约束刚好卡边界：g(S(λ))≈0

- 或者更工程的：找到**最小的** λ 使得 g(S(λ))≤0

而关键性质是：

g(S(λ)) 随 λ 单调不增（阶梯式）

于是你可以把问题当成“单调函数找根/找阈值”，二分天然稳定。

> 三分法需要“单峰且靠函数值比较”， 二分只需要“符号单调”，你这里更强、更稳。

**更关键：用 g 的好处是你能做“可行性控制”，三分法做不到那么直接**

工程上你常常想要的是：

- **满足约束**（g≤0）是硬指标

- 在满足约束的前提下尽量大 CR

二分 + g 的符号判断，能保证你最后得到的是：

- **最小可行 λ**（最不保守）

- 或者很快定位到“刚好不违规”的边界

而三分法只是把 d(λ)d(\\lambda)d(λ) 压到最小，它和“找到可行边界”不是同一个目标，尤其在离散/弱对偶场景下可能出现偏差。

线上落地的方案：
#### 

我们召回策略V2为了验证方向正确性，先把原方案简化，原方案中选择不选择j是考虑：

$$p_{ij} \big(1 + \lambda *ORC_{it} - \big(1 + \lambda\big) caa_{ij} \big) > 0$$

实际分单中，订单对司机打分是看司机履约率，可以近似认为履约率 约等于 $$1-caa_{ij}$$，$$p_{ij}​≈g(1−caa_{ij}​)$$，且$$g(⋅)$$单调递增，

那么以上的决策公式，就变成

$$g(1−caa_{ij}​)*\big(1 + \lambda *ORC_{it} - \big(1 + \lambda\big) caa_{ij} \big) > 0$$

因$$g(1−caa_{ij}​) \ge 0$$，且对有效候选通常 $$g(1-caa_{ij})>0$$，因此决定符号的就是$$w_j(\lambda)$$。

令$$w_j(\lambda)= 1 + \lambda *ORC_{it} - \big(1 + \lambda\big) caa_{ij}  =(1 - caa_{ij})+ \lambda *(ORC_{it}- caa_{ij} )$$，

- 当$$ORC-caa_{ij}>0$$时，$$w_j(\lambda)$$对任何 λ≥0 都为正（因为两项都非负）

- 当$$ORC-caa_{ij} < 0$$时，存在阈值$$\lambda^*$$，当 $$\lambda>\lambda^*$$ 后 $$w_j(\lambda)<0$$；

> 当$$caa_{ij}>ORC$$时，如果 w<0 得

> $$\begin{aligned} \lambda>\frac{1-caa_{ij}}{caa_{ij}-ORC} \end{aligned}$$

当 λ增大时，第二项$$\lambda(ORC-caa_{ij})$$线性放大，主导$$w_j(\lambda)$$的符号与大小；因此在大 λ极限下，

$$\operatorname{sign}(w_j(\lambda)) \approx \operatorname{sign}(ORC-caa_{ij})$$

> $$\begin{aligned} \lim_{\lambda \to \infty} \frac{w_j(\lambda)}{\lambda} = ORC - caa_{ij} \end{aligned}$$

相比原问题，我的方案的简化

- 简化 1：把“DO集合约束”变成“DO逐对约束”（最核心的简化）

> 理论约束：

> $$\begin{aligned} \sum_{j \in S}p_{ij}​(caa_{ij}​−ORC_{it})≤0 \end{aligned}$$

> 简化后约束：

> $$\forall j \in S, \; caa_{ij}−ORC<0$$

> **为什么这样简化合理？** 因为它极易解释、极稳，不会出现“平均合规但混进来几个很差的点”导致体验风险。

> **代价是什么？** 可行集合变小，策略更保守，可能损失成交提升的上限。

- 简化 2：把“调 λ”（连续控制风险价格）变成“固定阈值 ORC”（一步到位）

> 理论版外层要调 λ 去满足约束； 你现在直接把门槛设成 ORC，等价于说：

> 风险价格不需要动态定价，我直接规定：比基线差的，一律不准进。

> 这就把外层 root finding / grid search 省掉了。

> **代价是什么？** 你失去了一个很重要的杠杆：在供需紧张时“稍微放松一点点风险来换成交”的能力。

简化3：不考虑p_ij，将其

- 

-  $$\begin{aligned} caa_{ij} < ORC_{it} \end{aligned}$$

- 存

$$f(T) = \begin{cases} a_1 T + b_1(c_1), & T \le 6 \\ a_0 \log_2 T + b_0(c_0), & T > 6 \end{cases}$$

$$\forall j \in S,\quad \max\{ CCAA_{ij},\, BCAA_{ij} \} \le ORC_{it}$$

- 合理方案： “用价格 λ 给风险定价 → 让系统自动做收益/风险权衡”

- 简化方案： “不定价，直接禁掉所有风险比基线高的动作”

虽然应答后司乘取消率与接驾**EDA**(**ETA**)强相关性，但并不完全等价，基于**ODTP**维度建模应答后司乘取消，对高取消DO对进行过滤，效果要优于静态半径的过滤方式，

![](19c1b84270bcffb0-image.png)

建设**应答后司乘取消率预估模型**，**司机和乘客侧分开建模即线上两版模型**

$$\begin{aligned}  \forall j \in S,\quad \max \left\{ CCAA_{ij}, \; BCAA_{ij} \right\} \le ORC_{it}  \end{aligned}$$

特征：

**实时订单特征**：预估接驾时间，订单预付价格，订单送驾里程等；

**格子维度供需特征**：订单周围一圈格子历史呼叫，应答，及完单数等(SDS相关特征)；

**乘客侧历史行为特征**：乘客历史连环派及非连环派呼单，取消，完单等统计特征；

**司机侧历史行为特征**：司机历史连环派及非连环派拒单，取消，完单等统计特征；

模型均选取XGBoost，二分类任务的Cross-Entropy作为损失函数，

在竞争视角下，通过建模**订单应答前流失(竞争商家应答或乘客应答前取消)率**，

为了快速上线，搭建了t维度订单应答前流失率模型

自营宏鹄约75%+的订单在4s内(前两轮分单)举手，因此在**前两轮是商家间竞争最为激烈的阶段**，我们将整个分单过程可划分为发单后0-6s的**竞争视角阶段**和6s后的**乘客视角阶段（**因为乘客应答前取消与等待时长T近似为对数关系，建模乘客取消视角下的订单流失率考虑对数模型**）：**

$$f(T) = \begin{cases} a_1 T + b_1(c_1) & T \le 6 \\[6pt] a_0 \log_2 T + b_0(c_0) & T > 6 \end{cases}$$

#### 实验结果

线上实验结果表明，新版策略在应答前(竞争应答率)和应答后(应答后司乘取消)表现均有明显提升，最终对商家完单收益显著，自营效果：

|  <br> | 人均完单 <br> | 竞争AR <br> | 竞争CR <br> | 应答后司机取消(含改) <br> | 应答后乘客取消(不含改) <br> | 单均接驾距离 <br> | 小猪端整体CR <br> | 小猪端应答后司机取消率 <br> | 小猪端应答后乘客取消率 <br> |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 实验组A-T维度模型 <br> | **+2.17%** <br> | **+0.17pp** <br> | **+0.28pp** <br> | **-0.36pp** <br> | **-0.57pp** <br> | **+53.06(相对+2.86%)** <br> | **+0.15pp** <br> | -0.07pp <br> | +0.005pp <br> |

###### 交易漏斗

对两个实验组分竞争视角和乘客愿等阶段以及整体的交易漏斗进行看清，目前无法取到端外的举手情况仅看端内举手率及胜率的变化；

竞争阶段口径为订单发出后6s内；乘客愿等阶段为6s后的时段；由于**实验组竞争阶段更多的单被应答完单会导致更少的订单流入到乘客愿等阶段**，若两个阶段分母都是全部呼单，无法看清实际流入乘客愿等阶段的真实召回情况；因此将乘客愿等阶段的漏斗分母分别用**全部呼单(乘客愿等阶段A)**和**仅流入该阶段的呼单(乘客愿等阶段B)**给出两版数据；

![](51d8c87110c16252-image.png)

1. 整体上看召回-应答的漏斗由于扩播显著提升，同时模型过滤有效降低了应答后司乘取消，最终带来完单正向；

2. 由于扩播运力承接了更多流量，连环派(应答后取消本身显著高于非连环派)占比有显著下降，一定程度上缓解了应答后司乘取消；同时GS分单系统的扩播配置更为激进，因此TopSpeed播单占比也有一定折损；

3. 商家完单的提升主要来源于竞争阶段，此时对照组基本不会触发扩播策略，因此扩召回带来的应答提升更为明显，而应答后司乘取消率并未显著上涨；

4. 应答后司乘取消率的降低主要来源于乘客愿等阶段，本阶段对照组的扩播占比会大幅度提升，模型对应答后取消率特别是扩播单的约束更加突出；同时本阶段召回率降低而成交率提升，表明T维度的流失率模型一定程度上进行了订单维度的hold，实现应答前后取消率的trade-off；

![](8589935d603aec8e-image.png)

尽管每个城市框内整体的漏斗表现都为正向，但收益情况会有明显波动，与其代表城市前述分析有一定相似性，核心结论为：

- 对于**BC双差的城市**组完单以及整体漏斗正向效果最为明显；

- **BC平衡或缺C的城市**则表现出显著提升召回和举手率的同时，商家PK胜率并未显著上涨，对最终完单的收益也会有一定折损；

- 对于**缺B的城市组**完单收益也较为显著，主要受限于召回率提升较少，理论上适用于更为激进的策略；

##### 后续策略配置启发

即使目前相关策略参数可以支持具体城市配置，但为了保障策略的泛化性以及方便后续维护，后续基于供需分框进行打包配置；

- 策略效果最好的城市组为**BC双差或轻度缺B**的城市，后续策略可follow当前配置；

- 对于**缺C或BC平衡的城市**由于平台竞争激烈，接驾远的运力较难胜出，因此可适当降低最大召回半径，**加快举手速度**，同时减少模型对接驾近运力的过滤(尽量与现状拉齐)；

- 对于**极度缺B**的城市可进一步扩大召回半径，降低模型过滤规模；

- 同时对于应答后乘客或司机取消率过高的城市可优化过滤阈值配置；若模型效果较差则考虑降低模型生效规模或单独训一版模型；

##### 

核心结论：

- 从线上实验表现及交易漏斗来看，新版召回策略通过扩大初始召回半径，显著提升了商家的召回-应答率；同时基于应答后取消率模型对高取消司乘对进行过滤，有效约束应答后司乘取消率，特别是在**扩播场景对取消率的降幅更为显著**；同时**对连环派份额有一定降低**，也有效降低了应答后司乘取消率；

- 即使接驾距离提升，应答后履约率反而更好，也表明了**模型过滤相较于距离过滤的优越性以及ODTP建模履约率的合理性**，整体收益链路与预期一致；

- 策略在不同供需情况的城市框内也体现一定的规律性，对于**BC双差**的城市本身需要更远的召回范围进行双边匹配，因此策略效果最优；而BC平衡或缺C的城市组由于供需已处于较好的阶段，扩召回的影响相对收窄，这部分城市应主要考虑提升PK侧的胜率如加快举手等；

二期针对一起的分析结果进行调整，并且对宏鹄也开启同样的实验，实验结果：

自营

| 自营： <br> | 人均完单 <br> | 竞争AR <br> | 竞争CR <br> | 应答后司机取消(含改) <br> | 应答后乘客取消(不含改) <br> | 人均GMV <br> | 单均接驾距离 <br> | 小猪端整体CR <br> | 小猪端应答后司机取消率 <br> | 小猪端应答后乘客取消率 <br> |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 实验组A <br> | **+2.81%** <br> | **+0.29pp** <br> | **+0.34pp** <br> | **-0.41pp** <br> | **-0.38pp** <br> | **+3.62%** <br> | **+76.36(相对+4.07%)** <br> | **+0.11pp** <br> | -**0.05pp** <br> | +0.09pp <br> |
| 实验组B <br> | **+2.5%** <br> | **+0.23pp** <br> | **+0.29pp** <br> | **-0.32pp** <br> | **-0.47pp** <br> | **+2.99%** <br> | **+59.34(相对+3.14%)** <br> | **+0.16pp** <br> | -0.03pp <br> | +0.05pp <br> |
| 实验组C <br> | **+3.19%** <br> | **+0.58pp** <br> | **+0.37pp** <br> | **+0.21po** <br> | **+0.53pp** <br> | **+3.19%** <br> | **+108.94(相对+5.77%)** <br> | **+0.11pp** <br> | **+0.14pp** <br> | **+0.29pp** <br> |
| 实验组D <br> | **+2.66%** <br> | **+0.43pp** <br> | **+0.32pp** <br> | **+0.10pp** <br> | +0.09pp <br> | **+3.08%** <br> | **+99.20(相对+5.26%)** <br> | **+0.15pp** <br> | **+0.14pp** <br> | **+0.33pp** <br> |

1. 基于供需对城市分框配置策略相关参数，相对于全国统一配置组最终完单有少许提升；

###### 宏鹄商家

**下掉扩播无接驾金转抢单**

|  <br> | 人均完单 <br> | 竞争AR <br> | 竞争CR <br> | 应答后司机取消(含改) <br> | 应答后乘客取消(不含改) <br> | 单均接驾距离 <br> | 小猪端整体CR <br> | 小猪端应答后司机取消率 <br> | 小猪端应答后乘客取消率 <br> |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 实验组A <br> | ==**+2.03％**== <br> | **+0.37pp** <br> | **+0.33pp** <br> | +0.01pp <br> | -0.03pp <br> | **+**==**70.91**==**(相对+3.9%)** <br> | **+0.21pp** <br> | -0.01pp <br> | +0.02pp <br> |
| 实验组B <br> | **+1.66%** <br> | **+0.33pp** <br> | **+0.28pp** <br> | **+0.09pp** <br> | -0.03pp <br> | ==**+61.76**==**(相对+3.4%)** <br> | **+0.22pp** <br> | +0.03pp <br> | +0.03pp <br> |
| 实验组C <br> | **+**==**2.58％**== <br> | **+0.74pp** <br> | **+0.44pp** <br> | **+0.56pp** <br> | **+0.4pp** <br> | **+**==**125.56(**==**相对+6.9%)** <br> | +0.08pp <br> | **+0.39pp** <br> | **+0.4pp** <br> |
| 实验组D <br> | **+**==**3.56％**== <br> | **+1.28pp** <br> | **+0.59pp** <br> | **+1.38pp** <br> | **+1.20pp** <br> | **+**==**196.67**==**(相对+10.82%)** <br> | -0.05pp <br> | **+0.81pp** <br> | **+0.87pp** <br> |

### 平台召回策略优化

#### 背景

商家召回策略以商家完单为目标，平台召回策略以平台司乘体验为目标，**接驾距离影响乘客等待时长与司机空驶成本**，司乘双边的接驾体验均会因接驾距离的增加而变差，因此平台期望以降低整体接驾距离为目标，同时约束完单。

25年初在5s之内应答的订单中，接驾距离>=2.5km的订单占5s内总应答量的12.14%，这类订单的特点是**“应答快但接驾距离远”**，应答后乘客取消率如下，2km以，应答后乘客取消率20%+，但是如果稍微等等，等到一个接驾距离更近的司机（<1500），乘客取消率可以降低到10%以内，将**“应答快但接驾距离远”，**多等几秒置换更近的司机，可以带来更好的乘客体验，不仅能降低接驾距离，更有机会实现完单为正。

不同应答时间-不同接驾距离的乘客取消率
|               **接驾距离/500m  →** <br>**应答时长/s ↓** <br> | (0,**500\]** <br> | (500,**1000\]** <br> | **1500** <br> | **2000** <br> | **2500** <br> | **3000** <br> | **3500** <br> | **4000** <br> | **4500** <br> | **5000** <br> | **5500** <br> | **6000** <br> |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 5 <br> | 6.98% <br> | 7.78% <br> | 9.82% <br> | 12.84% <br> | 17.84% <br> | 24.58% <br> | 25.51% <br> | 26.93% <br> | 27.53% <br> | 28.24% <br> | 23.37% <br> | 23.35% <br> |
| 10 <br> | 6.53% <br> | 6.95% <br> | 8.75% <br> | 11.97% <br> | 17.11% <br> | 23.83% <br> | 24.95% <br> | 28.63% <br> | 33.53% <br> | 38.13% <br> | 30.53% <br> | 28.86% <br> |
| 15 <br> | 8.93% <br> | 9.09% <br> | 11.13% <br> | 14.66% <br> | 20.33% <br> | 26.81% <br> | 25.35% <br> | 28.85% <br> | 33.94% <br> | 38.65% <br> | 37.24% <br> | 37.35% <br> |
| 20 <br> | 8.99% <br> | 10.20% <br> | 12.31% <br> | 15.70% <br> | 21.01% <br> | 27.07% <br> | 24.80% <br> | 27.86% <br> | 32.92% <br> | 37.40% <br> | 36.54% <br> | 37.04% <br> |
| 25 <br> | 8.69% <br> | 10.23% <br> | 12.67% <br> | 16.24% <br> | 21.80% <br> | 27.29% <br> | 25.38% <br> | 27.47% <br> | 31.70% <br> | 35.52% <br> | 35.68% <br> | 35.14% <br> |
| 30 <br> | 8.88% <br> | 9.93% <br> | 12.24% <br> | 15.67% <br> | 21.17% <br> | 26.79% <br> | 24.29% <br> | 26.72% <br> | 31.00% <br> | 34.49% <br> | 34.08% <br> | 33.38% <br> |
| 35 <br> | 8.84% <br> | 9.89% <br> | 12.09% <br> | 15.26% <br> | 20.28% <br> | 25.89% <br> | 23.49% <br> | 26.17% <br> | 29.37% <br> | 32.67% <br> | 34.17% <br> | 34.07% <br> |
| 40 <br> | 9.29% <br> | 10.43% <br> | 12.60% <br> | 15.50% <br> | 20.55% <br> | 25.91% <br> | 23.14% <br> | 25.87% <br> | 30.24% <br> | 33.17% <br> | 34.89% <br> | 34.48% <br> |
| 45 <br> | 10.25% <br> | 10.68% <br> | 12.63% <br> | 15.43% <br> | 20.05% <br> | 25.32% <br> | 22.85% <br> | 25.45% <br> | 29.06% <br> | 32.28% <br> | 33.96% <br> | 34.12% <br> |
| 50 <br> | 9.84% <br> | 10.66% <br> | 12.54% <br> | 15.47% <br> | 20.24% <br> | 25.21% <br> | 23.21% <br> | 24.53% <br> | 28.35% <br> | 31.00% <br> | 33.53% <br> | 31.05% <br> |
| 55 <br> | 9.84% <br> | 10.74% <br> | 12.54% <br> | 15.65% <br> | 19.91% <br> | 24.68% <br> | 23.33% <br> | 23.94% <br> | 28.01% <br> | 30.26% <br> | 32.90% <br> | 30.45% <br> |
| 60 <br> | 10.22% <br> | 11.10% <br> | 12.87% <br> | 15.92% <br> | 20.52% <br> | 24.85% <br> | 23.39% <br> | 24.14% <br> | 27.42% <br> | 31.44% <br> | 33.44% <br> | 33.28% <br> |

不同应答时间-不同接驾距离的司机取消率
|            **接驾距离/500m  →** <br>**应答时长/s ↓** <br> | **500** <br> | **1000** <br> | **1500** <br> | **2000** <br> | **2500** <br> | **3000** <br> | **3500** <br> | **4000** <br> | **4500** <br> | **5000** <br> | **5500** <br> | **6000** <br> |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 5 <br> | 3.57% <br> | 3.68% <br> | 4.36% <br> | 5.58% <br> | 7.74% <br> | 10.26% <br> | 9.91% <br> | 9.21% <br> | 9.61% <br> | 9.89% <br> | 8.68% <br> | 8.16% <br> |
| 10 <br> | 3.16% <br> | 3.35% <br> | 3.99% <br> | 5.07% <br> | 7.00% <br> | 9.58% <br> | 9.88% <br> | 10.74% <br> | 12.04% <br> | 12.70% <br> | 11.44% <br> | 10.97% <br> |
| 15 <br> | 6.40% <br> | 6.72% <br> | 7.54% <br> | 8.82% <br> | 10.59% <br> | 13.04% <br> | 12.36% <br> | 13.42% <br> | 14.85% <br> | 15.70% <br> | 14.15% <br> | 16.11% <br> |
| 20 <br> | 4.76% <br> | 5.67% <br> | 6.79% <br> | 8.13% <br> | 10.09% <br> | 12.55% <br> | 12.29% <br> | 13.22% <br> | 14.77% <br> | 16.19% <br> | 15.61% <br> | 16.21% <br> |
| 25 <br> | 4.95% <br> | 5.69% <br> | 6.78% <br> | 8.22% <br> | 10.20% <br> | 12.82% <br> | 12.49% <br> | 13.36% <br> | 15.06% <br> | 16.01% <br> | 16.57% <br> | 17.86% <br> |
| 30 <br> | 5.33% <br> | 5.87% <br> | 6.88% <br> | 8.26% <br> | 10.25% <br> | 13.03% <br> | 12.13% <br> | 12.71% <br> | 14.69% <br> | 16.02% <br> | 16.44% <br> | 16.75% <br> |
| 35 <br> | 4.69% <br> | 5.18% <br> | 6.24% <br> | 7.49% <br> | 9.50% <br> | 12.56% <br> | 12.85% <br> | 13.84% <br> | 16.25% <br> | 17.35% <br> | 17.42% <br> | 18.19% <br> |
| 40 <br> | 5.09% <br> | 5.49% <br> | 6.42% <br> | 7.65% <br> | 9.74% <br> | 12.72% <br> | 11.51% <br> | 10.89% <br> | 12.74% <br> | 14.35% <br> | 14.96% <br> | 16.45% <br> |
| 45 <br> | 4.94% <br> | 5.32% <br> | 6.12% <br> | 7.30% <br> | 9.26% <br> | 12.65% <br> | 10.81% <br> | 12.45% <br> | 12.77% <br> | 14.95% <br> | 15.38% <br> | 16.84% <br> |
| 50 <br> | 5.34% <br> | 6.03% <br> | 6.96% <br> | 8.14% <br> | 9.74% <br> | 12.91% <br> | 10.87% <br> | 12.40% <br> | 11.40% <br> | 13.53% <br> | 13.81% <br> | 14.99% <br> |
| 55 <br> | 5.50% <br> | 5.98% <br> | 7.05% <br> | 8.00% <br> | 9.50% <br> | 12.77% <br> | 10.67% <br> | 10.46% <br> | 11.83% <br> | 13.31% <br> | 13.29% <br> | 13.11% <br> |
| 60 <br> | 5.48% <br> | 6.34% <br> | 7.31% <br> | 8.58% <br> | 10.02% <br> | 12.86% <br> | 11.53% <br> | 11.48% <br> | 12.73% <br> | 14.54% <br> | 14.42% <br> | 13.01% <br> |
| 65 <br> | 5.45% <br> | 6.51% <br> | 7.37% <br> | 8.53% <br> | 10.24% <br> | 13.06% <br> | 12.15% <br> | 12.95% <br> | 12.80% <br> | 15.64% <br> | 14.29% <br> | 16.17% <br> |
| 70 <br> | 5.63% <br> | 6.54% <br> | 7.41% <br> | 8.67% <br> | 10.64% <br> | 13.09% <br> | 9.70% <br> | 9.42% <br> | 10.20% <br> | 12.87% <br> | 14.32% <br> | 14.46% <br> |
| 75 <br> | 5.75% <br> | 6.22% <br> | 7.39% <br> | 8.73% <br> | 10.63% <br> | 13.17% <br> | 11.11% <br> | 10.93% <br> | 10.96% <br> | 13.19% <br> | 13.88% <br> | 13.75% <br> |

- 基于以上，我们计划对订单进行hold，让本来【快应答但是距离远】的订单，通过多等几秒，找到更近的司机，降接驾距离提升双边整体的接驾体验。

> 在2025年初，以短期完单为目标的迭代下，交易系统中存在一些**低质量交易行为**（部分虽未取消），对整体完单贡献有限，却对乘客体验和司机体验造成显著伤害，司乘体验的重要性逐渐提升，【**应答后接驾距离】**是将司乘体验指标合二为一的选择，25年接驾体验主要的工作是限制接驾距离过远的交易行为，在轻微牺牲完单的前提下，改善交易系统供需状态分布（降低接驾距离），提升交易能力的可持续性。

> 为优化乘客体验，增加乘客长期留存，2025年开启了【接驾体验优化】项目，该项目的主要目标是**降低接驾距离**，**降低体验bad-case率**（约束一定的完单降幅）。

> 是否要提使用策略带来的接驾距离的降幅？还是说这部分放在生态策略优化中？

> 项目初期使用了一些短平快的策略，基于城市不同运力完单份额，以及同样接驾距离下连环派取消率明显高于非连环派现象，by城市设置不同扩播上限值，在完单折损0.19%的前提下，接驾距离降低-310m，

#### 问题定义：

| 符号 <br> | 说明 <br> |
| --- | --- |
| $$\mathbb E[d_i(t)]$$ <br> | hold 到 t 秒，最终能匹配到多近？ <br> |
| $$P_i(t)$$ <br> | hold 到 t 秒，完单概率是多少？ <br> |
| $$S_i​(t) = \prod_{k=1}^{t} (1 - h_k)$$ <br> | 订单存活概率 <br> |
| $$Ai​(t)=P(司机应答∣t,订单仍存在)$$ <br> | 司机应答概率 <br> |
| $$C_i​(t)=E[P(应答后完单∣d,zi​)∣t,已应答]$$ <br> | 应答后司机履约率 <br> |
|  <br> |  <br> |

$$\begin{aligned} \min_{\{t_i \in T\}} \quad & \sum_{i=1}^{N} \mathbb{E}[d_i(t_i)] \\ \text{s.t.} \quad & \sum_{i=1}^{N} \big(P_i(t_i) - P_i(0) \big)\ge 0 \end{aligned}$$

其中完单率为：

$$P(\text{完单}_i \mid t) = S_i(t)\cdot A_i(t)\cdot C_i(t)$$

$$C_i(t) = \mathbb{E} \left[ P(\text{应答后完单} \mid d, z_i) \;\middle|\; t,\ \text{已应答} \right]$$

拉格朗日松弛：

$$\begin{aligned} \min_{\{t_i\}} \sum_i \mathbb{E}[d_i(t_i)] + \lambda \sum_i \left( P_i(0) - P_i(t_i) \right) \end{aligned}$$

单和单之间其实是会有影响的，但是排列组合太多，太复杂了，真实的最优组合，可能是：

订单1，hold 1s，订单2 hold 2秒，订单3 hold 5秒的情况下的；但是这需要遍历全部组合排序，搜索空间也太大了；

因此做了化简，因为一个司机连接多个订单的占比只有6%，假设订单之间独立，对订单维度做最优决策（min 放到了sum里面），

$$\begin{aligned} \sum_i  \min_{\{t_i\}} \mathbb{E}[d_i(t_i)] + \lambda \sum_i \left( P_i(0) - P_i(t_i) \right) \end{aligned}$$

这样决策公式为（商家召回也是类似的，做了这样的化简）：

$$t_i(\lambda) = \arg\min_{t \in T} \left[ \mathbb{E}[d_i(t)] + \lambda \left( P_i(0) - P_i(t) \right) \right]$$

将完单替换：

$$t_i(\lambda) = \arg\min_{t} \left[ \hat{D}_i(t) - \lambda \cdot \hat{S}_i(t)\hat{A}_i(t)\hat{C}_i(t) \right]$$

#### 方案框架

```diagraming
{"type": "diagraming", "sourceId": "2206925630440", "version": "69a595e5e4b02c4e5f0718f5", "fileUrl": "../../../%E9%99%84%E4%BB%B6/d8/d8a1b89cadb48cb7-69a595e5e4b02c4e5f0718f5.bin"}
```

- **核心：**

太复杂by订单的**最大hold秒数**

	- by订单的hold X秒的**最优接驾距离阈值**。

- **整体思路：**

	- 在分单轮次中，如果该轮中订单当前的接驾距离 **>** 模型预测得到的该订单的最优接驾距离阈值，则该订单被hold至下一轮，最多hold X 秒；

	- 在最大hold秒数内，订单匹配到司机的接驾距离 **<** 自身最优接驾距离阈值时，进行GS分单，超出X秒后，订单释放，参与gs分单。

#### 订单hold-V0版本：

V0版本的hold秒数不是搭建的模型，是直接将全部订单统一一个最长hold-10秒，

##### hold 秒数模型：统一hold 10s

> hold秒数的大小影响的是应答前的乘客取消。因此，对于hold秒数的测算，需要衡量的是应答前乘客取消带来的完单折损是否在可接受范围内。

**测算方式：**

> 核心逻辑是模拟计算订单holdX秒的应答前乘客取消率变化，进而测算对完单折损的影响。详细数据见[订单holdv0统一hold秒数选择测算](https://cooper.didichuxing.com/docs2/sheet/2206775795163)

- 计算每个订单从呼叫时间到最终状态时间（应答 / 取消）的生存时长（s）；

- 以2秒为时间粒度生成 \[0-2)、\[2-4)、\[4-6)…\[198-200) 的时间区间；

- 统计每个时间区间内：仍存活的订单数、在该区间内取消的订单数、在该区间内应答的订单数、该区间内的应答前取消率；

- 统计每个时间区间内，hold X秒的应答前取消量 = 该区间内的生存订单量 \* **max(**该区间内的应答前取消率，\[X-2, X)区间内的应答前取消率**)**

- 统计holdX秒(X取10s，20s，30s)下，不hold订单的应答前取消率和hold X秒的应答前取消率，以及hold X秒带来的应答前取消率的绝对值变化量，最终结果如下：

|  <br> | 不hold的应答前取消率 <br> | hold-Ns的应答前取消率 <br> | hold-Ns带来的应答前取消率变化 <br> |
| --- | --- | --- | --- |
| hold-10s <br> | 0.54% <br> | 0.98% <br> | +0.44pp <br> |
| hold-20s <br> | 0.92% <br> | 1.52% <br> | +0.60pp <br> |
| hold-30s <br> | 1.48% <br> | 2.91% <br> | +1.43pp <br> |

应答前取消率变化了-0.44pp，小猪端应答率90%，对应答量的影响是89.56 / 90 - 1 （约等于 -0.48%），

预期接驾距离降低-40 \~ 50m，预计可以带来应答后取消率-0.4pp，也就是履约率增加0.4pp，小猪端司机平均履约率：80%，履约率相对变化率 = 80.4/80 - 1= 0.5%，完单的相对变化 **≈**​ 履约率相对提升+应答量相对变化）= 0.5%-0.48% ，满足完单不负。

##### **hold-10秒的最优接驾距离预测模型**

###### label 如何定？

模拟全部订单的多轮hold逻辑，经过gs分单得到的接驾距离，在不同hold轮次下的接驾距离的最小值就是该订单在hold X 轮下的最小接驾距离。

```diagraming
{"type": "diagraming", "sourceId": "2206926084735", "version": "69a5b572e4b0e4e80d525cad", "fileUrl": "../../../%E9%99%84%E4%BB%B6/56/56902a8827f91a88-69a5b572e4b0e4e80d525cad.bin"}
```

> 具体说明：

> 考虑到每一分单轮次内都会有订单被分出去，存在动态变化，因此在为订单找最优阈值标签时需要考虑动态调整阈值标签的值。

>  

> 循环若干轮：

> Round 1: 所有订单全部 hold 10轮，无过滤阈值。每一个订单，记下订单在未来10轮分别得到的10个接驾距离值（有可能该订单在某轮是分不出去的，则接驾距离值为无穷大），在这10个接驾距离值中取最小，标记在订单上。在Round 1 后，每个订单都会有自己的过滤阈值label_1；

> Round 2: 此时所有的订单都有了自己的过滤阈值label_1，从Round 2开始生效hold逻辑。所有订单再hold10轮，每一轮过GS分单，过滤阈值为label_1+50m；结束后，所有订单又会有其最小的接驾距离label_2；

> Round 3: 所有订单再hold10轮，每一轮过GS分单，过滤阈值为label_2+50m；结束后，所有订单有其最小的接驾距离label_3；

> Round 4: 同理

> Round N：。。。

>  

> 每一Round下，订单是否达到稳态的判断条件：**label\_(round) - label\_(round-1) < 50 m**

> Round循环是否结束的判断条件：**某次循环内的稳态订单占该全部订单的90%**，则跳出round循环，此时每个订单最优接驾距离标签不再更新，确认找到最终label。

> 如遇订单取消，或连边超出预设的播单半径，label为null。如果订单循环结束后订单仍为null，我们设置其label为3600m，相当于不hold该订单。

###### 模型构建

v0一期实验中使用xgboost回归模型、v0二期实验中使用DNN回归模型。

其中，DNN模型核心流程：MLP 特征提取→残差块增强→回归输出

- 输入层：处理\[batch, 128\]的输入特征；

- 特征提取层：MLP（线性层 + GELU 激活 + 批归一化 + Dropout）将特征维度从 128→256→128→64；

- 残差增强层：通过两个残差块增强特征表达；

- 回归输出层：将 64维特征映射为1维预测值，且生成固定的hold秒数。

##### 实验结果

| 实验组(3%全国pid实验) <br> | 接驾距离变化 <br> | 完单量变化 <br> | CR变化 <br> | 应答后C取消率变化 <br> | 应答后B取消率变化 <br> | 应答前C取消率变化 <br> |
| --- | --- | --- | --- | --- | --- | --- |
| hold 10s <br> | **-37m** <br> | **-0.29%** <br> | -0.05pp <br> | **-0.28pp** <br> | **-0.08pp** <br> | **+0.36pp** <br> |
| hold 6s <br> | **-43m** <br> | -0.28% <br> | -0.08pp <br> | **-0.33pp** <br> | -0.002pp <br> | **+0.40pp** <br> |
| **hold 10s + 1000m兜底值** <br> | **-39m** <br> | +0.11% <br> | +0.06pp <br> | **-0.31pp** <br> | -0.03pp <br> | **+0.24pp** <br> |
| 平台规范 <br> | **-88m** <br> | **-0.71%** <br> | **-0.36pp** <br> | **-0.64pp** <br> | **+0.14pp** <br> | **+1.00pp** <br> |

#### 订单hold-V1

##### 最优hold 秒数模型：

预测最优hold秒数，其实最优hold秒数应该是在乘客应答前取消前，能找到的最优接驾距离对应的hold时间，这样就实现了在订单全生命周期替订单找到最近的司机。

那么建立应答前取消率模型就是关键，

[tail 很容易被“早取消样本”污染](https://cooper.didichuxing.com/docs2/document/2206723896322)

[hazard 或者是 CDF建模的优缺点](https://cooper.didichuxing.com/docs2/document/2206724109848)

[订单hold-V1生效策略方案](https://cooper.didichuxing.com/docs2/document/2206879886472)

#### 不同hold时间内的

### 问题：

一、和 wyc 交易的不同、相同

 

二、和国际化、gd 的不同、相同

和外卖的不同、相同

和搜索、广告的不同、相同

 

三、目标体系怎么设计

 

 

四、个人成长

 

 

五、如何判断一件事情要不要做

 

 

六、失败的项目中，失败的原因是什么，learning 是什么；失败的项目，是否有一些共性

七、如何在一个不太熟悉的领域，尽可能少地踩坑？

八、业务这两年的变化是什么，给交易侧带来的挑战是什么；未来一两年的技术规划是怎样的

九、交易匹配效率怎么衡量

十、如何做好的技术规划

十一、交易指标对用户留存的影响

十二、自己对团队的核心价值是什么

十三、交易 vs 体验 / 治理，有目标上的冲突，如何取舍，如何协同

十四、什么是治理？什么是体验？

 

 

十五、有哪些难做的决策，思考过程是什么

十六、如果你是业务负责人 or 自己的上级，你对交易方向最在意的是什么

十七、技术栈广度够、深度不够，怎么解？如何向外看？

十八、交易效率指标 和 双边密度的关系是什么

十九、如何评价你的团队，对业务的贡献、帮助

二十、个人的职业规划

二十一、你认为团队当前面临的最大技术挑战 / 业务挑战 / 组织挑战是什么，如何解决？

二十二、当团队面临技术路线分歧时，你会如何决策？

二十三、如何评估技术方案的风险？请举一个具体案例

二十四、技术管理者的核心能力是什么

二十五、AI（LLM）带来的挑战和机遇

二十六、怎么理解技术深度

二十七、个人缺点

### 细节问题：

**Q：调度中q_ij 等价于 r_ij，这样设计的理由是？为啥这样等价？**

- 当时是为了简化建模，没有下发调度和下发但是没有看到等原因没有接受，直觉来看对后续的接单概率影响不大，同时能降低建模复杂度我们就这样做了；

- 以及V1建模其实是有偏的；

**Q：****V2设计中保留k的原因是？**

当前版本策略空间退化为二元决策，因此可以将三维变量 zijkz\_{ijk}zijk​ 降维为 zijz\_{ij}zij​。但从框架设计上，我们保留 k 维度，是为了支持多档调度强度与策略扩展（未来可能会拓展到：多档调度补贴）。

**Q：****因果模型为啥选择drcfr？**

- 表征平衡（representation balancing）：将treatment 和 control的表示拉到同一分布；

- 有倾向性建模（propensity modeling）：纠正非随机分配带来的样本偏差。

- Doubly Robust（双重稳健）

- 一条 outcome model

- 一条 propensity model

- 两者结合，只要其中一个估计对了， uplift 仍然是一致的，这对线上策略特别重要，因为 propensity 模型往往有噪声。

为什么不是简单 T-Learner？因为T-Learner：

- 分别训练两个模型

- 容易过拟合

- 不共享 representation

- 不做 balancing

DRCFR 相当于：T-Learner + 表征平衡 + IPW + DR 修正

**Q1：为什么要对司机和乘客应答后取消率分开进行建模？**

1. 为便于对司机或乘客取消率进行单独的调控，方便业务及策略侧根据具体诉求调整线上生效阈值等后续维护；

2. 之前一些包括在连环派场景上的建模效果表明一起建模效果往往不达预期；

**Q2：为什么不直接用平台PK打分履约率模型进行过滤，与平台决策标准拉齐？**

1. 目前端内only举手的占比达到**40%**，对于这部分直接胜出运力平台履约率模型对实际应答后取消率效果不佳(AUC仅0.674）；

2. 平台的履约率模型无法对司机和乘客维度单独调控；同时由于司机侧取消可以改派，平台侧更关注应答后乘客取消，而对于商家来讲司机取消后不一定改派给本商家司机，因此司乘取消都需要关注；

3. 不管是平台的履约率打分模型还是本次策略的应答后取消率模型，ETA(EDA)均为最重要的特征之一，一定程度上起到对齐作用；

**Q3**：**司机侧听单半径为何不是直接扩至最大半径？**

1. 司机侧则更多从体验出发，在司机不是很缺单的情况下缩短听单半径，提升司机的接驾体验；

2. 订单侧主要偏向竞争的视角考虑，后续会说明在**最初的几轮分单是商家竞争最激烈的阶段**，希望能够直接扩大召回的范围提升商家举手率；

**Q4**：**加入P维度特征是否会存在对于等待应答耐心差的乘客先找到车，存在公平性问题？**

1. 在保证流失率模型性能的前提下，对于耐心差的乘客会给出较为宽松的过滤阈值先应答，但是运力可能会更远，应答后取消也会更高；

2. 下文分析会指出事实上相对于乘客愿等视角，被竞争商家抢走流量才是最主要的影响商家应答的因素，这种情形对整体大盘影响较小；

