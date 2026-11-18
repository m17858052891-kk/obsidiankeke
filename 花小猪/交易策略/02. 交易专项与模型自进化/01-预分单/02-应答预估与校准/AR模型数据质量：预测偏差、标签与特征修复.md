---
title: "AR模型数据质量：预测偏差、标签与特征修复"
type: "主题整理"
cssclasses: ["strategy-body-note"]
sources:
  - https://cooper.didichuxing.com/knowledge/2199610335356/2203347428720
  - https://cooper.didichuxing.com/knowledge/2199610335356/2203524946996
  - https://cooper.didichuxing.com/knowledge/2199610335356/2204017542791
aliases:
  - "AR模型分析"
  - "AR模型label问题记录"
  - "AR模型特征获取问题记录"
---

# AR模型数据质量：预测偏差、标签与特征修复

先区分预测分布异常、训练标签错误和线上特征缺失，再沿各自的证据追查。三份记录的时间、数据范围与处理状态分别保留。

## 先读这些

- **分渠道偏差**：联合决策 V2 将滴滴与其余渠道分开建模；早期分析观察到自营预估偏高、宏鹄偏低。
- **标签问题**：`driver_appid` 缺失及 `product_id` 映射变化，影响了自营、宏鹄的运力归属与正负样本。标签记录保留修正前后分布、两轮重训结果，以及“有运力但未应答”的约 2.1% case；其中与预分单有关的解释，原文注明尚未完全验证。
- **特征问题**：另一份记录定位到新 SDS 链路传入 `ALL` 而非 `KF`，导致六个冒泡计数特征取到 0。2025-03-20 的记录称取数已修复，滴滴渠道仍使用缺失值；这与标签修复是两件事。
- **使用方式**：先核对渠道、数据日期、标签和缺失值，再判断模型偏差。原文中的“已修正”“线上版本”均属于当时记录，不代表当前状态。

**分节阅读**　[[#分渠道预测偏差|分渠道预测偏差]] · [[#标签口径与重训验证|标签口径与重训验证]] · [[#SDS特征获取与修复|SDS特征获取与修复]]

## 分渠道预测偏差

**来源**：[AR模型分析](https://cooper.didichuxing.com/knowledge/2199610335356/2203347428720)

AR模型在联合决策V2中，被拆成了2个模型，一个用来预测「自营+宏鹄+API」，一个用来预测滴滴。主要是因为滴滴无法获取到任何实时特征，只能基于历史统计特征进行预估。

但目前存在的一个问题是，自营预测的结果偏高，宏鹄预测的结果偏低，具体可见下方的份额柱状图。

![](c62be27e7ce8d4fc-联合决策v2自营预测结果分布.png)![](2dab9e4061f13d4c-联合决策v2宏鹄预测结果分布.png)

![](fb7da26d32695d11-应答宏鹄品牌的预测结果分布.png)

```SQL
with
raw as 
(
    select  probabilities_value['values'][1] as prediction 
            ,round(probabilities_value['values'][1] * 100) as prediction_value_bucket
    from    kflower_strategy.ether_self_sql_13736_c8049041791229585_1729741624039_9503556928315213
)
select prediction_value_bucket, count(*) as cnt from raw group by prediction_value_bucket;
```

## 标签口径与重训验证

**来源**：[AR模型label问题记录](https://cooper.didichuxing.com/knowledge/2199610335356/2203524946996)

### 总结

**问题：**上游数据表字段改变导致ar模型构造label不符合预期

**影响：**会使得自营的正样本比例变高，宏鹕的负样本比例变高

**现状：**已修正，待离线测算对ar模型造成的影响

### 问题梳理&离线测算

离线跑2024-12-01数据时，发现kflower_marketplace.ods_log_kflower_stgmatrix_hh这张表里的driver_appid都是null。

**影响：**后续需要通过driver_appid字段join表kflower_dw.dim_kf_trd_product_df获取product_id，如果driver_appid是null，则会用product_id=80填充，进而会导致按商家统计可用司机数时，所有的运力都算作**花小猪自营**运力，hh的运力为0。但是hh商家还是有正阳本，是因为在生成label时会有额外**pk司机数是否大于0**的条件。

**离线数据测算：**

kflower_marketplace.ods_log_kflower_stgmatrix_hh表中2024-06-10(左)数据可以正常获取driver_appid，但是2024-10-08(右)拿不到driver_appid

这张表最旧分区是2024-06-21，这个时间点已经拿不到driver_appid这个字段了

![](91c34892632255ef-image.png)![](2ff13888e4a711bc-image.png)

相同取数口径下(原先的数据口径)，不同日期数据分布，这里的正负样本是产出label时的表数据，还没有和feature表关联

这里除了app_id的问题，product_id似乎也有问题，kflower_dw.dim_hh_com_id_map_df这张表很早（可能是去年的事情）就把product_id=80删了，所以关联之后很少product_id=80的数据出现（app_id为null会把product_id置为80），cr的特征表自营的product_id全部是80，关联的时候就会有问题。

| 日期 | zy正样本 | zy负样本 | zy正负样本比 | hh正样本 | hh负样本 | hh正负样本 |
| --- | --- | --- | --- | --- | --- | --- |
| 2024-06-10 | 2747216 | 2934068 | 0.94 | 4814113 | 73566756 | 0.07 |
| 2024-10-08 | 3120133 | 502698 | 6.21 | 3575426 | 60610028 | 0.06 |

修正后的取数口径下：

这里会增加一个逻辑：company_id=1400时，product_id置为80，不然和cr的特征表join不上

| 日期 | zy正样本 | zy负样本 | zy正负样本比 | hh正样本 | hh负样本 | hh正负样本 |
| --- | --- | --- | --- | --- | --- | --- |
| 2024-10-08 | 2305605 | 1317227 | 1.75 | 11203077 | 52982404 | 0.21 |

#### 模型重新训练

重跑10-08 -- 10-20的数据，重新训练模型，其中10-08 -- 10-14为训练数据10-15 -- 10-20为测试数据

关联特征表后数据正负样本比如下：

| **channel** | **正样本数** | **负样本数** | **正样本占比** | **负****样本占比** | **正 : 负** |
| --- | --- | --- | --- | --- | --- |
| ziying | 33730874 | 16806722 | 66.74% | 33.26% | 2.01 |
| honghu | 142202553 | 661657853 | 17.69% | 82.31% | 0.21 |
| lingxi | 60635 | 2464744 | 2.40% | 97.60% | 0.02 |
| didi | 3689734 | 10610360 | 25.80% | 74.20% | 0.35 |
| api | 13087276 | 54045326 | 19.49% | 80.51% | 0.24 |
| 合计 | 192771072 | 745585005 | 20.54% | 79.46% | 0.26 |

修正后数据正负样本比基本符合预期

同期数据（2024-10-08 -- 2024-10-20）对比修正前后各个运力渠道auc

| | zy | HH | api | dd |
| --- | --- | --- | --- | --- |
| 修正前 | ==0.88== | ==0.88== | ==0.87== | ==0.74== |
| 修正后 | 0.84 | 0.91 | 0.88 | 0.74 |

用新数据（2024-12-01 -- 2024-12-12）重新训练分渠道模型

数据分布总览

| **运力渠道** | **正样本数** | **负样本数** | **正样本占比** | **负****样本占比** | **正 : 负** |
| --- | --- | --- | --- | --- | --- |
| didi | 2997721 | 7121081 | 30% | 70% | 0.42 |
| api | 14306096 | 52446553 | 21% | 79% | 0.27 |
| ziying | 33930623 | 18824209 | 64% | 36% | 1.80 |
| lingxi | 23560 | 1922519 | 1% | 99% | 0.01 |
| honghu | 159691964 | 793423545 | 17% | 83% | 0.20 |

auc结果

| 运力渠道 | zy | HH | api | dd |
| --- | --- | --- | --- | --- |
| auc | 0.83 | 0.91 | 0.89 | 0.79 |

预测值分布

| zy | HH | api | dd |
| --- | --- | --- | --- |
| ![](d004583134827d95-image.png) | ![](8bdd9d15c342ef1c-image.png) | ![](36245953c25bda5d-image.png) | ![](a768feb5c60f9699-image.png) |

按照ar_gt_0_cnt（应答率大于零的数量排序）分商家查看平均的应答率，左图是未修正的结果，小猪三品类显著高于其余商家的平均应答率

右图是修正的结果，修正之后不会出现自营三品类平均应答率显著高于hh商家的情况。

![](f4beffa76d5a32a7-image.png)![](28cabaa1ab6db13b-image.png)

**发现一个新问题：**

对于每一单，如果有一个商家构造的label=1，那么is_td_answer应该等于1，但是观察到有不符合预期的情况出现。

这部分订单cancel_type=1，表示应答前乘客取消，等待时常cancel_dur>60s，派单类型dispatch_type=3是全指派（也有null的情况）

group by order_id之后这部分case的占比约为2.1%，测算基于的是2024-11-30的数据

available_driver_cnt > 0的几种情况都有，也有pk_driver_cnt > 0的情况。

**原因（未完全验证）：**发单之后在等待应答页没有运力，触发了预分单，召回了司机（可能会提前参与pk），但是乘客没有同意，所以最终没有应答，直到被乘客取消

## SDS特征获取与修复

**来源**：[AR模型特征获取问题记录](https://cooper.didichuxing.com/knowledge/2199610335356/2204017542791)

注：新链路（联合决策链路）缺失值用-9999.0填充，老链路（老的平台呼返链路）用0填充，老链路不能区分填充为0还是真实为0

### 问题记录

**问题：**kflower_strategy.ods_log_kflower_ether_price_anchor_cr_model这张表在落日志时，会有两个部分的流量，分别为**联合决策**的流量和**老的价格锚点链路**的流量，其中联合决策的流量在获取bubble_minute_unique_cnt_10m、bubble_minute_unique_cnt_10m_one_circle_grid、bubble_minute_unique_cnt_1m、bubble_minute_unique_cnt_1m_one_circle_grid、bubble_minute_unique_cnt_3m、bubble_minute_unique_cnt_3m_one_circle_grid这6个特征时，会全都落成0。

**原因**：访问sds老链路，没有渠道的概念，所以sds兼容了一下，将锚点的key，强制访问KF(自营)渠道。 新的sds链路有渠道的概念，可以直接传渠道，并且key也会替换，所以不需要那个强制指定的逻辑。只需在入参的channel字段传KF。 因为锚点传的还是ALL（需求是KF），sds未生产ALL的特征，导致查到的都是0

以'2025-03-10' and '2025-03-12'数据为例（联合决策流量标黄），统计大于0的数据比例，记录如下：

| **version** | **dt** | **bubble_minute_unique_cnt_10m** | **bubble_minute_unique_cnt_10m_one_circle_grid** | **bubble_minute_unique_cnt_1m** | **bubble_minute_unique_cnt_1m_one_circle_grid** | **bubble_minute_unique_cnt_3m** | **bubble_minute_unique_cnt_3m_one_circle_grid** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ar_model_v1_2024_v1 | 2025-03-10 | 0.67 | 0.83 | 0.33 | 0.62 | 0.53 | 0.77 |
| ar_model_v1_2024_v1 | 2025-03-11 | 0.66 | 0.83 | 0.33 | 0.62 | 0.53 | 0.77 |
| ar_model_v1_2024_v1 | 2025-03-12 | 0.64 | 0.82 | 0.31 | 0.59 | 0.50 | 0.75 |
| ==ar_model_without_isotonic_dd_v2== | 2025-03-10 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| ==ar_model_without_isotonic_dd_v2== | 2025-03-11 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| ==ar_model_without_isotonic_dd_v2== | 2025-03-12 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| ==ar_model_without_isotonic_v2== | 2025-03-10 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| ==ar_model_without_isotonic_v2== | 2025-03-11 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| ==ar_model_without_isotonic_v2== | 2025-03-12 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| version-77557774 | 2025-03-10 | 0.67 | 0.84 | 0.35 | 0.61 | 0.55 | 0.77 |
| version-77557774 | 2025-03-11 | 0.66 | 0.83 | 0.34 | 0.60 | 0.54 | 0.76 |
| version-77557774 | 2025-03-12 | 0.66 | 0.83 | 0.34 | 0.60 | 0.54 | 0.76 |

可以看到，联合决策部分流量的非0值占比为0，老链路的数据占比符合预期。

计数sql
> [!example]- SQL 实现细节（28 行）
> ```SQL
> with
> feature_info as 
> (
>     select  cast(param['bubble_minute_unique_cnt_10m'] as double) as bubble_minute_unique_cnt_10m
>             ,cast(param['bubble_minute_unique_cnt_10m_one_circle_grid'] as double) as bubble_minute_unique_cnt_10m_one_circle_grid
>             ,cast(param['bubble_minute_unique_cnt_1m'] as double) as bubble_minute_unique_cnt_1m
>             ,cast(param['bubble_minute_unique_cnt_1m_one_circle_grid'] as double) as bubble_minute_unique_cnt_1m_one_circle_grid
>             ,cast(param['bubble_minute_unique_cnt_3m'] as double) as bubble_minute_unique_cnt_3m
>             ,cast(param['bubble_minute_unique_cnt_3m_one_circle_grid'] as double) as bubble_minute_unique_cnt_3m_one_circle_grid
>             ,param['version'] as version
>             ,concat_ws('-', year, month, day) as dt
>     from    kflower_strategy.ods_log_kflower_ether_price_anchor_cr_model
>     where   concat_ws('-', year, month, day) between '2025-03-10' and '2025-03-12'      
> )
> select  
>         version,
>         dt,
>         sum(if(bubble_minute_unique_cnt_10m>0, 1, 0)) / count(*) as bubble_minute_unique_cnt_10m,
>         sum(if(bubble_minute_unique_cnt_10m_one_circle_grid>0, 1, 0)) / count(*) as bubble_minute_unique_cnt_10m_one_circle_grid,
>         sum(if(bubble_minute_unique_cnt_1m>0, 1, 0)) / count(*) as bubble_minute_unique_cnt_1m,
>         sum(if(bubble_minute_unique_cnt_1m_one_circle_grid>0, 1, 0)) / count(*) as bubble_minute_unique_cnt_1m_one_circle_grid,
>         sum(if(bubble_minute_unique_cnt_3m>0, 1, 0)) / count(*) as bubble_minute_unique_cnt_3m,
>         sum(if(bubble_minute_unique_cnt_3m_one_circle_grid>0, 1, 0)) / count(*) as bubble_minute_unique_cnt_3m_one_circle_grid
> from    
>         feature_info
> group by 
>         version,
>         dt
> ```


### 影响评估

目前线上模型用的训练数据是2024-12-01 -- 2024-12-07，期间联合决策的流量约为30%左右，也就是大概30%左右训练数据在这几个特征上会有问题。

从模型的结果看，这些特征均不在特征重要性前50，前100有4个（一共113个特征）。

![](8d32a8364ceb0ee9-image.png)

从流量占比以及特征重要性来看，这些特征的影响并不会很大。

### 处理方案

现阶段联合决策正在扩量，不太适合对线上模型做大的改动，并且预估对于线上的影响不大，所以会先把这个bug修复，但是线上模型不变。但后期会重新训练模型，重新上线，可能会对模型表现有增益。

### 现状

**2025-03-20**

目前bug已经修复dd运力渠道拿不到sds特征，所以都是默认值-9999.0，统计大于0的数比例为0，其他版本正常有数。ar_model_without_isotonic_v2版本的bubble_minute_unique_cnt_10m_one_circle_grid特征大于0比例略低，应该是刚修复的原因。

![](50bb5c06f98dfcd9-image.png)
