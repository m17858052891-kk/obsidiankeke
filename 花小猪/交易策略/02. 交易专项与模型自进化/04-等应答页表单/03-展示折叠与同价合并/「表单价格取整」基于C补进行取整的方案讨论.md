---
title: "「表单价格取整」基于C补进行取整的方案讨论"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2201788859772
cssclasses: ["strategy-body-note"]
---

# 「表单价格取整」基于C补进行取整的方案讨论

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2201788859772)

**阅读定位**　[[#背景|背景]] · [[#技术方案|技术方案]] · [[#实验评估|实验评估]] · [[#附：「表单价格取整」实验报告|附：「表单价格取整」实验报告]]

## 背景

表单价格取整的实验显示：

1. 四舍五入取整组，大盘完单**无显著变化**；

2. 向下取整组，根据一口价交易模式的品牌（自营三品类、特价盒子、哈啰）的处理方式的不同，有以下两个实验组：

	1. 一口价仍然保留小数（**组A**）：**大盘完单显著上涨1.1%左右**，但是因为一口价保留小数，导致**一口价品牌的排序受损，从而导致完单折损，自营完单显著下降-6.7%**；

	2. 一口价也向下取整，文案改成「预估」（**组B**）：**大盘完单显著上涨0.6\~0.8%，自营完单降幅有所收窄（-5.3%）**，但**人均冒泡有显著下降（-0.8%），呼单次周留存也有显著下降****；**

| **指标** | **向下取整组A** | **显著性** | **向下取整组B** | **显著性** |
| --- | --- | --- | --- | --- |
| 人均去重冒泡 | -0.10% | 不显著 | **-0.74%** | 显著 |
| **人均呼单** | **0.00%** | 不显著 | **-0.88%** | 显著 |
|     --人均自营呼单 | **-0.90%** | 显著 | -0.33% | 不显著 |
|     --人均宏鹄呼单 | **0.90%** | 显著 | -0.47% | 不显著 |
|     --人均api呼单 | **2.72%** | 显著 | **2.29%** | 显著 |
|     --人均滴滴呼单 | **11.22%** | 显著 | **7.96%** | 显著 |
| **人均完单** | **1.11%** | 显著 | **0.81%** | 显著 |
|     --人均自营完单 | **-6.73%** | 显著 | **-5.37%** | 显著 |
|     --人均宏鹄完单 | **5.07%** | 显著 | **3.94%** | 显著 |
|     --人均api完单 | **7.72%** | 显著 | **6.18%** | 显著 |
|     --人均滴滴完单 | **4.34%** | 显著 | **3.19%** | 显著 |
| **人均完单不含滴滴** | **+0.68%** | 显著 | **+0.50%** | 显著 |

*注：数据取自于最新的二期长周期实验报告，实验周期为2024-01-19 ～ 2024-02-20，完整报告见附录*

向下取整组中，以上两种对于一口价品牌的处理方式都存在一定的缺点，因此，当前建议**通过调节C补，将一口价品牌实付价补齐到整数。**

这样既能不影响价格排序，也能让一口价品牌展示价等于用户实付价格，同时还能对所有价格都进行取整，进一步降低用户反勾意愿。

参考jp，一口价品牌的展示价格取整到「角」，「分」的部分也是通过C补的方式进行补齐的，如下图

![](cbe698b584ebbaae-image.png)![](9a9160b200e4f9a9-image.png)

## 技术方案

以下两个方案的差异在于**具体补贴取整的方式**以及**预算来源**。

### 方案一【**推荐**】

- **自营三品类**：由自营承担取整C补，通过微调冒泡级别的补贴率，达到取整目的。经测算，**调整前后，自营C补率基本保持不变**（6.8pp vs 6.8pp）

	- 具体而言，对于原本没有给自营呼返的（订单占比45%），给0\~1元的C补进行取整；原本给了自营呼返的（订单占比55%），以最小调整幅度调整呼返金额，达到取整目的；

	- 平台呼返对于自营三品类目前仅覆盖不到15%，对于这15%，平台呼返可以适度调整呼返金额（多给或少给），以达到取整目的

- **特价盒子**：由平台呼返承担取整的C补，同样是以最小影响进行取整；

- **哈啰出行**：暂时不考虑，可以保留「一口价」变成「预估」的方案；

> [!example]- 完整数据表（3 行记录）
> | **cp_type** | **实付** | **平台呼返合计** | **智能呼返合计** | **ziying_adjusted_hufan** | **ubox_adjusted_hufan** | **智能呼返** | **平台呼返** | **调整后智能呼返** | **调整后平台呼返** |
> | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
> | 特价盒子 | 46238881 | 3509714 | 0 | 0 | 3016778 | 0.0% | **7.6%** | 0.0% | **6.5%** |
> | 自营三品类 | 98880038 | 910568 | 6724999 | 6679673 | 0 | **6.8%** | 0.9% | **6.8%** | 0.0%(?) |
> | other | 123561846 | 1062927 | 8419198 | 0 | 0 | 6.8% | 0.9% | 0.0% | 0.0% |


*时间周期：2024-02-27\~2024-03-04*

> [!example]- SQL 实现细节（79 行）
> ```SQL
> with sub_info as (
>     select
>         order_id,
>         product_id,
>         product_category,
>         pas_c_gmv,
>         is_cheap_lane_order,
>         collect_list(concat(subsidy_type, ':', subsidy_c)) as all_subsidy,
>         sum(subsidy_c) as total_subc,
>         count(*) as subsidy_rows,
>         sum(if(subsidy_type = 81, subsidy_c, 0)) as hufan,
>         sum(if(subsidy_type = 82, subsidy_c, 0)) as zhinenghufan
>     from
>         kflower_dw.dwm_kf_fin_order_subsidy_c_di
>     where
>         -- dt between '${begin_date}'
>         -- and date_add('${end_date}', 10)
>         dt between '2024-02-27' and '2024-03-03'
>     group by
>         order_id,
>         product_id,
>         product_category,
>         pas_c_gmv,
>         is_cheap_lane_order
> ),
> middle_info as (
>     select
>         *,
>         case
>             when is_cheap_lane_order = 1 then 'ubox'
>             when product_id = 80 then 'ziying'
>             else 'other'
>         end as cp_type,
>         pas_c_gmv - total_subc as estimate_fee
>     from
>         sub_info
> ),
> preprocess_info as (
>     select
>         *,
>         -- 先处理特价盒子
>         if(
>             is_cheap_lane_order = 1,
>             if(
>                 ceil(estimate_fee) - estimate_fee < hufan,
>                 hufan - ceil(estimate_fee) + estimate_fee,
>                 hufan + estimate_fee - floor(estimate_fee)
>             ),
>             0
>         ) as ubox_adjusted_hufan,
>         if(
>             cp_type = 'ziying',
>             if(
>                 ceil(estimate_fee) - estimate_fee < zhinenghufan,
>                 zhinenghufan - ceil(estimate_fee) + estimate_fee,
>                 zhinenghufan + estimate_fee - floor(estimate_fee)
>             ),
>             0
>         ) as ziying_adjusted_zhinenghufan
>     from
>         middle_info
> ),
> agg_info as (
>     select
>         cp_type,
>         sum(pas_c_gmv) as pas_c_gmv,
>         sum(hufan) as hufan_total,
>         sum(zhinenghufan) as zhinenghufan_total,
>         sum(if(cp_type='ziying', ziying_adjusted_zhinenghufan, 0)) as ziying_adjusted_hufan,
>         sum(if(cp_type='ubox', ubox_adjusted_hufan, 0)) as ubox_adjusted_hufan
>     from
>         preprocess_info
>     group by
>         cp_type
> )
> select
>     *
> from
>     agg_info;
> ```


**预算方面，特价盒子的呼返调整后，补贴率有小幅下降；自营调整前后，补贴率基本不变。整体上不需要额外申请预算。**

### 方案二

由平台呼返进行C补补齐取整，具体可有以下两种不同的方案

| 方案 | 预估补贴率 <br>（占大盘GMV） | 方案描述 |
| --- | --- | --- |
| A | 1.23pp | 不改变平台呼返原有策略，仅在原有补贴基础上，对于一口价品牌增加一项取整补齐的预算 |
| B | 0.60pp <br>（特价盒子-0.2pp，自营三品类+0.78pp） | 最小改动，对于平台呼返原本不打折的订单，补齐取整；对于原本打折的订单，改变折扣幅度，让最终价格为整数； |

> [!example]- SQL 实现细节（60 行）
> ```SQL
> --SPARK_SQL
> --********************************************************************--
> --author:teddycheng
> --create time:2024-02-26 14:58:33
> --desc:
> --remind:请在资源引用中添加需要引用的资源
> --********************************************************************--
> -- 过滤出所有完单的订单，然后关联出其对应的bubble数据，
> -- 即自营一口价、特价、特快，特快盒子（取一个level_type=105的品牌），然后以最后的实付价为基数，计算折扣比例
> with trace_set as (
>     select
>         distinct bubble_trace_id
>     from
>         kflower_dw.dwd_kf_trd_order_base_di
>     where
>         dt between "${begin}"
>         and "${end}"
>         and is_td_finish = 1
> ),
> bub_info as (
>     select
>         product_2level,
>         case when level_type = 105 and product_2level = 82 then '特价盒子'
>         else product_2level_name end as product_2level_name,
>         basic_total_fee_amt,
>         estimate_fee_amt,
>         floor(estimate_fee_amt / 100) * 100 as estimate_fee_amt_floor,
>         start_dest_dis_noncarpool,
>         if(start_dest_dis_noncarpool > 10, 'long', 'short') as dis_group
>     from
>         kflower_dw.dwd_kf_trd_bubble_base_all_di
>     where
>         dt between "${begin}"
>         and "${end}"
>         and (
>             (
>                 product_2level in (80, 81, 82, 497)
>                 and level_type != 105
>             )
>             or (
>                 product_2level = 82
>                 and level_type = 105
>             )
>         )
>         and trace_id in (
>             select
>                 bubble_trace_id
>             from
>                 trace_set
>         )
> )
> select
>     product_2level,
>     product_2level_name,
>     if(dis_group is null, 'all_dis_group', dis_group) as dis_group,
>     sum((estimate_fee_amt - estimate_fee_amt_floor)) / sum(estimate_fee_amt) as rate
> from
>     bub_info
> group by grouping sets ((product_2level, product_2level_name), (product_2level, product_2level_name, dis_group))
> ;
> ```


> [!example]- SQL 实现细节（47 行）
> ```SQL
> ---- 首先，获取到所有的完单，每个完单都有对应的完单品牌，
> ---- 在冒泡的时候，为了能将展示价格取整，我们需要加补一定的金额（实际上是改变折扣）
> ---- 我们先统计出所有一口价完单的订单，我们需要加补的金额，然后除以GMV之和
> with order_info as (
>     select
>         product_2level_name,
>         product_2level,
>         estimate_id,
>         level_type
>     from
>         kflower_dw.dwd_kf_trd_order_base_di
>     where
>         dt between '${begin}'
>         and "${end}"
>         and is_td_finish = 1
>         and product_1level <> 4
> ),
> bub_info as (
>     select
>         estimate_id,
>         product_2level,
>         product_2level_name,
>         basic_total_fee_amt,
>         estimate_fee_amt,
>         level_type,
>         estimate_fee_amt - floor(estimate_fee_amt / 100) * 100 as gap_floor,
>         start_dest_dis_noncarpool,
>         if(start_dest_dis_noncarpool > 10, 'long', 'short') as dis_group,
>         if(
>             level_type = 105
>             or product_2level in (80, 81, 82, 497),
>             'one_price',
>             'real_time'
>         ) as model_type
>     from
>         kflower_dw.dwd_kf_trd_bubble_base_all_di
>     where
>         dt between "${begin}"
>         and "${end}"
>         and product_1level <> 4
> )
> select
>     sum(basic_total_fee_amt) as gmv,
>     sum(if(model_type='one_price', gap_floor, 0)) as extra_subsidy
> from
>     bub_info a
>     join order_info b on a.estimate_id = b.estimate_id;
> ```


## 实验评估

1. 跟「表单价格取整」实验一样，评估对于大盘的收益；

2. 评估取整+补齐C补之后的，各补贴抓手的ROI；

## 附：「表单价格取整」实验报告

一期实验报告（2023.10.18-2023.10.24）：<https://cooper.didichuxing.com/docs/document/2201042278909>

一期实验长周期报告（2023.11.02 - 2023.11.29）：[https://cooper.didichuxing.com/docs2/document/2201320738393](https://cooper.didichuxing.com/docs2/document/2201320738393) ==（密码5835）==

==二期实验报告（==2023.12.26 ～ 2024.01.08==）：==<https://cooper.didichuxing.com/docs2/document/2201551466794>（密码==7406）==

==二期实验长周期报告（==2024.01.19 ～ 2024.02.20==）：==<https://cooper.didichuxing.com/docs2/document/2201757936689>（密码8469）

「表单价格取整」prd：<http://wiki.intra.xiaojukeji.com/pages/viewpage.action?pageId=1067240571>

补刀需求BRD：<https://cooper.didichuxing.com/knowledge/share/page/uHRyU4fByeRb#>
