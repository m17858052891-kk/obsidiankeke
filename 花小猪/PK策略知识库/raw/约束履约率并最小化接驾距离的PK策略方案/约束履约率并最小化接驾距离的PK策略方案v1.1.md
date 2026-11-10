
# 约束履约率并最小化接驾距离的PK策略方案v1.1

# 基础信息

| 事项 <br> | 内容 <br> |
| --- | --- |
| brd链接 <br> |  [约束履约率并最小化接驾距离的PK策略BRD](https://cooper.didichuxing.com/docs2/document/2207845057791) <br> |
| 望岳链接（状态要在组内评审中） <br> |  [https://ddp.intra.xiaojukeji.com/requirement/story/R-KF-678689?backUrl=/workbench/requirement](https://ddp.intra.xiaojukeji.com/requirement/story/R-KF-678689?backUrl=/workbench/requirement) <br> |
| 是否产品双评 <br> |  否 <br> |
| 需求业务owner <br> |  董听 <br> |
| 需求策略owner <br> |  董听 <br> |
| 方案版本（V1.0开始） <br> |  V1.1 <br> |
| 上次评审结论（如果不是第一次评审，给出上次评审结论） <br> |  建议拆分成两期： <br>1. 模型部分没什么问题 <br><br>2. 全天是否需要把履约当作资源做做优化问题 需要讨论 <br><br> |
| 需求优先级（以及是否有上线时间的强诉求） <br> |  P1 <br> |
| 是否和AI经过了充分的交互，AI提出的最值的关注的top2问题是什么 <br> |   <br> |

# 一、 背景

当前平台CR已达到较高水平，如何在保持完单和CR不降的同时，通过优化PK环节，来优化交易效率(ETP+司机接驾时长)，是PK的核心挑战。

首先，当前PK打分依据是模型预估的履约率（司机履约率和乘客履约率的加权），没有直接优化ETP和司机接驾时长的抓手，因此需要**转变PK环节的优化目标，在PK打分中加入接驾距离的考量**。

其次，当前的履约率模型存在样本选择性偏差问题，模型为可解释性强但结构简单的Deep&Wide，AUC存在较大提升空间（3pp）。因此，将预测乘客履约率和司机履约率的多任务建模优化为**预测（司机取消、乘客取消、完单）的三分类问题****；**同时，**优化模型结构为多域多专家门控网络**（类似PEPNet、PLE等），提升履约率预测AUC；对于模型的可解释性，通过用完全可解释的LR模型蒸馏深度模型，得到部分的可解释性（80%以上）。

# 二、收益预估

约束完单和CR不显著负，降低ETP+司机接驾时长0.5%

履约率模型 AUC+3pp

# 三、策略细节

## 3.1 PK在线分配司机机制

考虑交易团队的目标：约束完单不负，降低ETP+司机接驾时长，由于PK打分环节（O选D）无法改变应答时长，能直接优化接驾时长（即接驾距离），因此将PK打分的优化目标修改为 **约束完单不显著负，最小化接驾距离**

先定义以下符号

|  <br> | 含义 <br> |
| --- | --- |
| $$i$$ <br> | 订单下标 <br> |
| $$j$$ <br> | 司机下标 <br> |
| $$x_{j}$$ <br> | 是否选司机$$j$$,$$x_{j} \in \{0,1\}$$ <br>$$x_{j} = 1$$ 代表该订单选司机$$j$$ <br> |
| $$()^0$$ <br> | 旧策略上标，如$$f^0$$代表旧策略模型预估履约率 <br> |
| $$f$$ <br> | 模型预估履约率 <br> |
| $$f_p$$ <br> | 模型预估乘客履约率 <br> |
| $$f_d$$ <br> | 模型预估司机履约率 <br> |
| $$d=dist$$ <br> | 司机接驾距离 <br> |

### **优化问题推导**

原来的优化目标：最大化履约率

 $$max \ E[f]= E[\alpha *f_p + (1-\alpha)* f_d]$$

新的优化目标：约束履约率不显著负，最小化接驾距离。**这里by订单决策**，**允许胜出司机的履约率 vs 最高履约率 下降不超过0.2%**

 $$min \  E[d], \ s.t. \ E[f] \geq C \max f_j, \ C =0.998$$

也就是

$$\begin{aligned} \min_{j} \quad & d_{j}  \\ \text{s.t.} \quad &  f_{j} \geq C\max_k f_k \end{aligned}$$

Q：为什么不需要约束“一个司机只能选一个订单"？

A：因为PK阶段，订单之间的司机是相互隔离的，一个司机不能同时举手两个订单。离线获得的订单举手司机也是相互隔离的

### 解法一：硬约束

```diagraming
{"type": "diagraming", "sourceId": "2207967426953", "version": "6a0ebbb3e4b0b6d3638998b5", "fileUrl": "https://s3-ep-inter.didistatic.com/platform-history-version/2207967426953/6a0ebbb3e4b0b6d3638998b5?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKDD00000000000I0P9LNR3TQNA4CC%2F20260531%2Fgzep%2Fs3%2Faws4_request&X-Amz-Date=20260531T111151Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=d119811b2db56ce0b7ac1c49972d4ae6a4770f7e751737880e59a0c9dee6bbeb"}
```

**问题1**：司机是陆续举手进PK的，当最后一个司机到来前，无法知道$$max_k f_k$$

当前的PK逻辑是，举手司机的PK分与当前胜者PK分比较，高者胜出（需要和工程确认现状，PK败者的释放时间）

**问题2**: by订单约束 胜出司机的履约率 >=0.998 最大履约率，**可选司机非常少，收益空间小**

（0324～0330数据）**存在可选司机的订单占比仅0.56%，存在更短接驾距离的可选司机的订单占比仅0.26%，整体降低接驾距离<1m**

```SQL
-- 举手进PK的DO对
-- 看最优司机的履约率*0.998内，有多少司机可选
-- lumian_dis 最小
with win as(
select
    order_id,
    roundnum,
    max(model_pkvalue) win_pkvalue
from
    kflower_strategy.kflower_dusepk_data --从PK模型日志得到
where
    dt between '2026-03-24'
    and '2026-03-30' --验证集日期，所有举手进PK的DO对
group by order_id, roundnum
)
  
select 
    sum(1) ord_cnt,
    sum(if(satisfied_dri_cnt>0,1,0)) has_satified_dri_ord_cnt,
    sum(if(min_lumian_dis < win_lumian_dis,1,0)) lumian_dis_less_ord_cnt
from (

    select 
        a.order_id, 
        a.roundnum,
        count(distinct if(model_pkvalue >=0.998*win_pkvalue and model_pkvalue < win_pkvalue, driver_id, null )) satisfied_dri_cnt,
        min(if(model_pkvalue >= 0.998*win_pkvalue and model_pkvalue < win_pkvalue, lumian_dis, null )) min_lumian_dis,
        max(if(model_pkvalue = win_pkvalue, lumian_dis, null)) win_lumian_dis
    from (
        select 
            order_id, 
            roundnum,
            driver_id,
            model_pkvalue,
            lumian_dis
        from 
            kflower_strategy.kflower_dusepk_data
        where
            dt between '2026-03-24'
            and '2026-03-30' 
    )a left join win b on a.order_id = b.order_id and a.roundnum = b.roundnum 
    group by a.order_id, a.roundnum
)t



```

### 解法二：拉格朗日松弛，历史数据定全局$$\lambda$$

拉格朗日函数

$$\mathcal{L}(j, \lambda) =  d_{j}  + \lambda \left(C \max_k f_k - f_{j} \right) =  \lambda C \max_k f_k+  \left(d_{j} - \lambda f_{j}\right) , \ \lambda \geq 0$$

对偶问题，对固定的$$\lambda$$，求 min，

$$min_j (d_j - \lambda  f_j) \ \Leftrightarrow  \ max_j (\lambda f_j - d_j)$$

因此 PK分 = $$\lambda f -d$$ 

**根据历史数据求解全局**$$\lambda$$

根据打分公式  PK分 = $$\lambda f -d$$ ，$$\lambda$$**就是“履约率值多少距离”的权重**

**对每一个订单**$$i$$**, 会存在一个**$$\lambda_i$$**，使得所有不满足履约率约束的司机不会成为PK分最高的司机，即** $$\max_j(\lambda_i f_j-d_j)$$ **求得的**$$j$$ **能够满足约束**$$f_j \geq C\max_k f_k$$ 

那么，我们就可以对所有的$$\lambda_i$$进行排序，得到x%满足率下的最小$$\lambda_x$$ 

用0324～0330的数据求得$$\lambda$$, 在0324～0406的数据上模拟两种PK过程（新策略：PK分= $$\lambda f -d$$ ，原策略：PK分 =$$f$$）

计算：

1\. PK胜出司机的履约率满足约束的订单占比

2\. 两种PK策略的平均接驾距离 

3\. 新策略 vs 旧策略 的整体履约率降幅（= 未满足履约率约束的订单占比\*未满足约束的订单的平均履约率gap）

可以看到，$$\lambda = 5340$$时，履约率满足约束的订单占比96.39%，**能够有3.81%的订单选到更近的司机，整体平均接驾距离-20m(-1.21%)，整体履约率-0.14pp**

![](https://s3-ep-inter.didistatic.com/didoc2-upload-file-prod/images/1779721180526/VD7o6mMsKHXU7NUNvwzRl/image.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKDD00000000000EBLCTZNRBJHX6ZS%2F20260531%2Fgzep%2Fs3%2Faws4_request&X-Amz-Date=20260531T111151Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=d2ac8987412725dbdb0f5cb8462824766ebd128343bef399cd5b10a68c9cca29)

> train: 0324\~0330 求$$\lambda$$

> valid: 0331\~0406 模拟线上

假设$$\lambda = 5340,   \  \lambda f^*-d^* > \lambda f^0-d^0$$  ($$d^0$$: 履约率最大的司机的接驾距离，$$d^*$$: 当前策略的最优司机的接驾距离）

转换得到 $$d^0 - d^* > \frac{1}{5340} (f^0 -f^*)$$ , **相当于 5.34m的接驾距离与0.1pp的履约率的置换**

**结论：按照整体CR降幅小于0.2pp的目标约束，可以选择解法二拉格朗日松弛，离线测算满足率要求=90%**

## 3.2 履约率模型优化 

### 模型特征

保持不变

| 特征维度 <br> | 特征 <br> | 是否需要建设 <br> |
| --- | --- | --- |
| 订单特征 <br> | ﻿城市、呼叫时间、订单里程等 <br> | 已建设 <br> |
| 司乘特征 <br> | 是否连环派、指派模式、接驾距离、预估价等 <br> | 已建设 <br> |
| 供需特征 <br> | 格子和周围格子近X分钟发单数、空车司机数等 <br> | 已建设 <br> |
| 司机特征 <br> | 司机近X天（分场景）的拒单率、取消率、完单数等 <br> | 已建设 <br> |
| 乘客特征 <br> | 乘客近X天应答后取消率、完单数、平均订单里程等 <br> | 已建设 <br> |

### 模型建模

原PK履约率模型存在问题：在司机履约的样本上训练乘客履约率，存在偏差（司机履约同理）

| 模型版本 <br> | 建模目标 <br> | 所有样本 <br> | 正样本 <br> | 负样本 <br> | PK分 <br> |
| --- | --- | --- | --- | --- | --- |
| 原PK履约率模型（V4) <br> | is_d_finish <br> | PK获胜且乘客未取消 <br> | 完单 <br> | 司机取消/拒单 <br> | $$\alpha$$\*P(is_o_finish) +$$(1-\alpha)$$\*P(is_d_finish) <br> |
| is_o_finish <br> | PK获胜且司机未取消/拒单 <br> | 完单 <br> | 乘客取消 <br> |

以乘客履约率为例

- 训练空间：P(Y = 1｜司机未取消/拒单, X）Y=1表示乘客履约

- 推理空间：P(Y = 1 | X)  

在训练时，特征X的分布被“司机未取消/拒单”这个事件过滤了，发生协变量偏移：训练集的X与测试集的X分布不一致

> 例如

> 恶劣天气+远距离订单 -> 司机取消概率高 -> 这类样本很少出现在乘客履约的训练集中

> 线上推理时遇到此类订单，模型缺少对此类特征的拟合能力，预测不准

**解决方法：**

将多任务建模优化为**预测订单状态是（司机取消，乘客取消，完单）的多分类模型**

- 训练空间：P1 = P(Y1 = 司机取消 | X) , P2 = P(Y2 = 乘客取消 | X), P3 = P(Y3 = 完单 | X)

- 推理空间：P1 = P(Y1 = 司机取消 | X) , P2 = P(Y2 = 乘客取消 | X), P3 = P(Y3 = 完单 | X)

- 乘客履约率 = P(乘客履约｜司机履约）= P(完单) / (P(乘客取消 )+P(完单)) =  P3/(P2+P3), 司机履约率 = P3/(P1+P3)

	- 我们想要在PK中预估的乘客履约率就是 假设司机不取消时 乘客的履约率，因此就是要预测P(乘客履约 | 司机履约）

- 履约率 =$$\alpha$$\*乘客履约率 +$$(1-\alpha)$$\* 司机履约率（与原来保持一致，站在乘客的视角增加乘客履约在O对D打分中的权重）

### 模型结构

使用多域多专家的模型结构

- 多域：是否连环派 \* 派单模式（全指派、半指派、抢单）\*其他（发单星期和时间段，长短单，供需情况等）

	- 使用EPNet的门控结构Gate NU，自适应的调整底层特征编码在不同的域上的重要性

	- Gate NU 输入：连环派类型，派单类型，发单星期和时间段，订单距离，供需等

- 多专家： 用多个专家并行来获得单个任务的解，再通过gate激活决定各个专家的权重

	- Gate NU 输入：所有底层特征编码

![](https://s3-ep-inter.didistatic.com/didoc2-upload-file-prod/images/1779161038409/yzr5l6ga9mHXPoXYaea4I/image.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKDD00000000000EBLCTZNRBJHX6ZS%2F20260531%2Fgzep%2Fs3%2Faws4_request&X-Amz-Date=20260531T111151Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=d952394b3f5e9bfb550259c0416095d0b82e7d91ab118582d2aad59ab3bb97d3)

### 评估指标

OvR Macro AUC

记3个类别：A(司机取消）、B(乘客取消) 、C(完单)

- 类别C的AUC ： 将完单的样本视为正样本，其他(A+B)为负样本，计算AUC_C

- Macro AUC = (AUC_A + AUC_B + AUC_C) /3

### 模型可解释性

「可解释」定义

模型1: 深度模型

模型2：lr（100%的可解释）

对于相同的订单o，两个司机的do对($$d_io, \ d_jo$$) ，模型1的预测PK分为$$v_{i1},  v_{j1}$$，模型2的预测PK分为$$v_{i2},v_{j2}$$

如果两个模型对它们的打分排序一致，即$$(v_{i1}-v_{j1})*(v_{i2}-v_{j2})\geq 0$$，则认为模型1对这个pair的排序可以用模型2的排序来解释

用lr模型蒸馏深度模型在训练集上的预测概率（软标签），通过lr的可解释性得到深度模型在上述定义下的部分的可解释性 （80%）

（城市✖️商家维度 满足95%的可解释性）

# 四、工程说明

**工程：PK分由两项模型输出的加权，修改为模型输出（一项），需要支持实验**

**其它改动由策略完成，在模型中进行计算包装**

1. 模型直接产出PK分

	1. PK分修改：PK分 = 履约率 -$$1/\lambda$$ \* 司机接驾距离

	2. $$1/\lambda$$ 从hive表中读取，由策略生成hive表。 hive表: 天级别的表 （模型如何读取：配置为dufe)

	3. 履约率 =$$\alpha * p3/(p2+p3) + (1-\alpha) * p3/(p1+p3),$$ （p1,p2,p3)为模型输出，$$\alpha$$ 为常数

2. 落日志：模型日志（包含履约率分数f, 和PK分）

3. ~~熔断机制: 策略产出小时级别的关于~~$$\lambda$$ ~~的hive表，通过控制~~$$\lambda$$ ~~来进行熔断和恢复~~

# 五、实验方案

|   <br> | 内容 <br> |
| --- | --- |
| 算法侧实验验证人 <br> | 董听 <br> |
| 实验方式 <br> | 乘客分流 <br>时间片实验 <br> |
| 实验平台 <br> | 评估大师/运筹实验平台 <br> |
| 分流方式 <br> | 乘客分流：随机分流 <br> |
| 时间片实验：每小时翻转 <br> |
| 分流细节 <br> | 见下表格 <br> |
| 实验周期 <br> | 乘客分流：7天 <br>时间片实验：14天 <br> |
| 流量范围 <br> | 流量端：花小猪端 <br>品类：自营鸿鹄 <br>城市 <br>分单场景：全部 <br> |
| 评估指标 <br> | 完单、CR，应答后乘客取消率、ETP，司机接驾时长 <br> |
| 评估人 <br> | DS、算法、评估大师/Apollo自动评估 <br> |

PID分流实验

|   <br> | 对照组 <br> | 实验组1 <br> | 实验组2 <br> | 实验组3 <br> |
| --- | --- | --- | --- | --- |
| 策略 <br> | PK Deep&Wide可解释模型 <br> | 只优化履约率模型， <br>PK打分目标保持原状 <br> | 只优化PK打分目标， <br>履约率模型保持原状 <br> | 优化PK打分目标， <br>且优化履约率模型 <br> |
| 模型 <br> | Deep&Wide <br> | 新模型 <br> | Deep&Wide <br> | 新模型 <br> |
| 1/lambda <br> | 0 <br> | 0 <br> | hive表提供 <br> | hive表提供 <br> |
| alpha <br> | 0.9 <br> | 0.9 <br> | 0.9 <br> | 0.9 <br> |

时间片实验

|   <br> | 对照组 <br> | 实验组 <br> |
| --- | --- | --- |
| 策略 <br> | PK Deep&Wide可解释模型 <br> | 优化PK打分目标， <br>且优化履约率模型 <br> |
| 模型 <br> | Deep&Wide <br> | 新模型 <br> |
| 1/lambda <br> | 0 <br> | hive表提供 <br> |
| alpha <br> | 0.9 <br> | 0.9 <br> |

说明：对照组的策略取决于 PK Deep&Wide版是否最终放量（等待时间片实验结果）。若后续Deep&Wide版不放量，则设置为线上LR模型版本，即为最新线上版本。

# 六、评审意见（\*评审填写，不填写默认通过）

| 结论（\*通过/不通过/修改后通过/建议） <br> | 具体评审建议 <br> | 评委 <br> |
| --- | --- | --- |
| 意见一 <br> | xxx <br> |   <br> |
| 意见二 <br> | xxx <br> |   <br> |

# 七、附录

当前PK模型：[【LR26010】PK模型迭代V4-- 可解释Deep&Wide模型](https://cooper.didichuxing.com/knowledge/2199610335356/2207586429814)
