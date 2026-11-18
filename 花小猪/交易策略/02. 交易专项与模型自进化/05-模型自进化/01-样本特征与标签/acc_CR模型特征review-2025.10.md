---
title: "acc_CR模型特征review-2025.10"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2205218264960
cssclasses: ["strategy-body-note"]
---

# acc_CR模型特征review-2025.10

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2205218264960)

先检查完单 label，再查传入特征和历史聚合特征的一致性。修复建议、代码与历史验证记录分层阅读。

**阅读定位**　[[#1 label梳理|1 label梳理]] · [[#2 特征梳理|2 特征梳理]]

### 1 label梳理

模型训练的label如下：

| label | 表格 |
| --- | --- |
| 呼叫是否完单 | ar_model_feature_generate_base |
| 该商家是否完单 | |
| 单呼商家时商家是否能应答 | kflower_strategy.price_anchor_build_sample_for_cr_model_v2 |

#### 完单label问题

- 问题描述：存在dt日呼叫，dt+1日完单的订单，落表如下。此时若只取单天数据，会造成cr的低估。

| 分区 | order_id | is_td_call | is_td_finish |
| --- | --- | --- | --- |
| 2025-08-01 | 相同 | 1 | 0 |
| 2025-08-02 | 0 | 1 |

- 解决方案：取dt日is_td_call=1的订单 left join dt+1的订单（不约束is_td_call=1），只要有一个is_td_finish=1，则订单的is_td_finish=1

> [!example]- PlainText 实现细节（60 行）
> ```PlainText
> select 
>     count(distinct a.order_id)
> from 
>     (
>         select 
>             distinct 
>             order_id,
>             bubble_trace_id,
>             estimate_id,
>             is_td_finish,
>             product_id,
>             product_2level,
>             level_type
>         from 
>             kflower_dw.dwd_kf_trd_order_anycar_di   
>         where 
>             dt = '2025-08-24'
>             and is_td_call = 1
>             -- 考虑是否要加改派
>             -- and   source_type <> 2
>             and call_time IS NOT NULL
>             and call_time <> '0000-00-00 00:00:00'
>             and order_id > 0
>             and product_1level in (1, 2, 999)
>             and is_wait_call=0
>             and not (is_td_answer = 0 and cancel_type = 1 and cancel_dur < 60) -- 去除未应答、乘客前取消、取消时间<60s的订单
>             and is_td_finish = 0
>     ) a
>     inner join (
>         select 
>             distinct 
>             order_id,
>             bubble_trace_id,
>             estimate_id,
>             is_td_finish,
>             product_id,
>             product_2level,
>             level_type
>         from 
>             kflower_dw.dwd_kf_trd_order_anycar_di   
>         where 
>             dt = '2025-08-25'
>             -- and is_td_call = 1
>             -- 考虑是否要加改派
>             -- and   source_type <> 2
>             and call_time IS NOT NULL
>             and call_time <> '0000-00-00 00:00:00'
>             and order_id > 0
>             and product_1level in (1, 2, 999)
>             and is_wait_call=0
>             and not (is_td_answer = 0 and cancel_type = 1 and cancel_dur < 60) -- 去除未应答、乘客前取消、取消时间<60s的订单
>             and is_td_finish = 1
>     ) b on a.order_id = b.order_id 
>     and a.bubble_trace_id = b.bubble_trace_id 
>     and a.estimate_id = b.estimate_id 
>     and a.product_id = b.product_id
>     and a.product_2level = b.product_2level
>     and a.level_type = b.level_type
>
> ;
> ```


- label数据验证：

	- 验证修改代码前后，每5分钟一个切片的CR，可以看到接近0点时，旧任务CR=0.1%，新任务CR=66%

> [!example]- PlainText 实现细节（38 行）
> ```PlainText
> select
>     hour(bubble_time),
>     FLOOR(
>         minute(bubble_time) / 5 -- 按5分钟间隔分组
>     ),
>     sum(is_td_finish) as finish_cnt,
>     count(distinct a.trace_id) as call_cnt,
>     sum(is_td_finish) / count(distinct a.trace_id) as cr
> from
>     (
>         select
>             trace_id,
>             max(is_td_cancel) as is_td_cancel,
>             max(is_td_answer) as is_td_answer,
>             max(is_td_finish) as is_td_finish
>         from
>             kflower_strategy.ar_model_feature_generate_base
>         where
>             dt = '2025-08-24'
>         group by
>             trace_id
>     ) a
>     inner join (
>         select
>             trace_id,
>             max(bubble_time) as bubble_time
>         from
>             kflower_dw.dwd_kf_trd_bubble_base_di
>         where
>             dt = '2025-08-24'
>         group by
>             trace_id
>     ) b on a.trace_id = b.trace_id
> group by
>     hour(bubble_time),
>     FLOOR(
>         minute(bubble_time) / 5 -- 按5分钟间隔分组
>     );
> ```


| 小时 | 分钟切片（5分钟一个切片） | 旧CR | 新CR |
| --- | --- | --- | --- |
| 23 | 3 | 0.664436479 | 0.651369719 |
| 23 | 4 | 0.654437573 | 0.678429099 |
| 23 | 5 | 0.639401709 | 0.682488823 |
| 23 | 6 | 0.584394071 | 0.68318719 |
| 23 | 7 | 0.518478457 | 0.67830925 |
| 23 | 8 | 0.377007126 | 0.683010994 |
| 23 | 9 | 0.191073368 | 0.672004045 |
| 23 | 10 | 0.048694425 | 0.672616494 |
| 23 | 11 | 0.001399161 | 0.66813224 |

- 呼叫口径验证：

	- 可能由于改派单算作一单，2025-08-23分区取到的呼单数（5113628） < 大盘的竞争呼叫数（5,309,665），误差3.7%

```PlainText
select
    count(distinct trace_id)
from
    kflower_strategy.ar_model_feature_generate_base
where
    dt = '2025-08-23'
```

### 2 特征梳理

acc_CR使用特征及对应表如下：

| 维度 | | 待更改问题 | 表格 | 数梦产出任务 |
| --- | --- | --- | --- | --- |
| 商家维度 | **7/14d商家历史聚合特征**，by商家、小时、is_weekday、city_id <br>- 应答/取消/完单 X 数/率 <br><br>- max/min/avg X 完单/应答/取消 X 距离/**券前**价/cpm/iph/订单时长 <br><br>	- 备注：券前价对应真实呼叫的券前价，例如对同一个商家，用户勾选了特快盒子、特价盒子，真实呼叫的券前价为特快盒子的价格 <br> | **注意：2025-08-08分区，是聚合的2025-08-01～2025-08-07的数据，但是依赖为dt-1** <br>- 需要更改依赖为dt-2，现状存在离在线不一致 <br><br>	- 训练数据，对dt日冒泡，取dt分区的特征，为\[dt-7,dt-1\]的历史聚合特征 <br><br>	- 线上实际，对dt日冒泡，取dt-1分区的特征，对应\[dt-8,dt-2\]的历史聚合特征 <br> | ar_model_feature_generate_groupby_product | [https://studio.data.didichuxing.com/batch?projectId=1143&taskId=40026845&subType=LOG](https://studio.data.didichuxing.com/batch?projectId=1143&taskId=40026845&subType=LOG) <br> |
| 乘客维度 | 7/14d乘客历史聚合特征，by乘客 <br>- 应答/取消/完单 X 数/商家数/率 <br><br>- max/min/avg X 完单/应答/取消 X 距离/**券后**价/cpm/券额/订单时长 <br> | ar_model_feature_generate_groupby_pas |
| 冒泡维度-实时 | **供需特征**，SDS特征，直接从日志表中直接取数 <br>- 城市/格子 X 呼叫/应答/司乘取消 X 数/率 <br> | | ar_seq_model_training_data <br>- 对应日志表kflower_marketplace.ods_log_kflower_platform_call_return_public_log_h <br> | [https://studio.data.didichuxing.com/batch?projectId=1143&taskId=40892017&subType=LOG](https://studio.data.didichuxing.com/batch?projectId=1143&taskId=40892017&subType=LOG) |
| 价格特征 <br>- **特快/特价/盒子外 X 券前价/券后价/券额/cpm/iph** <br><br>- 价格对应表单位置 <br><br>- 商家优先级 <br><br>	- 3：特快盒子、小猪特快 <br><br>	- 2：普通品类、小猪一口价、小猪打车 <br><br>	- 1：小猪特价、特价盒子、幸运盒子 <br> | | ar_model_feature_generate_base | [https://studio.data.didichuxing.com/batch?projectId=1143&taskId=40026801&subType=LOG](https://studio.data.didichuxing.com/batch?projectId=1143&taskId=40026801&subType=LOG) |
| **实时运力特征**，直接从日志表中取数，同AR模型 <br>- **订单基础特征：订单里程、起点信息、订单发生的时间等；** <br><br>	- 备注：放在这里是因为在同一个表中 <br><br>- 商家实时运力特征：在线司机数、空车司机数、未播订单数、商家一段时间内的举手数、呼单应答完单等； <br><br>- 商家历史时空上的统计特征：商家在当前格子当前时间段内，过去一周的平均呼单、冒泡、完单、应答司机、应答时长等； <br> | | zy_cr_model_test_data_v1 <br>- 对应日志表：kflower_strategy.ods_log_kflower_ether_price_anchor_cr_model <br> | [https://studio.data.didichuxing.com/batch?projectId=1143&taskId=33975853&subType=LOG](https://studio.data.didichuxing.com/batch?projectId=1143&taskId=33975853&subType=LOG) |

#### 2.1 传入特征离在线不一致

问题描述：在线使用呼返券前价，离线模型训练使用呼返券后价

| 离线券后/呼返券前价（在线） <br> | 离线券后/呼返券前价（在线） <br> | 呼返券后价（离线） <br> | 呼返券后价（离线） <br> |
| --- | --- | --- | --- |
| B <br> | 90 <br> | A-特价盒子 <br> | 85 <br> |
| A-特价盒子 <br> | 100 <br> | B <br> | 90 <br> |
| C <br> | 120 <br> | C <br> | 120 <br> |


‍解决方案：~~删除所有券后价、券额（券前-券后）相关特征，包含以下：~~**工程侧修改**

| 特征 | 含义 |
| --- | --- |
| ufbox_estimate_fee | 特快券后 |
| outbox_estimate_fee | 盒子外券后 |
| uabox_estimate_fee | 特价券后 |
| ufbox_fee_diff | 特快券前-券后 |
| outbox_fee_diff | 盒子外券前-券后 |
| uabox_fee_diff | 特价券前-券后 |
| appear_position | 根据券后价排序的出现位置 |

#### 2.2 历史聚合特征离在线不一致

问题描述：对于dt日冒泡，训练数据取dt-1日历史聚合特征，线上使用dt-2日历史聚合特征

| 数据 | 表 | 离线分区 | 在线分区 |
| --- | --- | --- | --- |
| 冒泡数据 | ar_model_feature_generate_base | 0808分区 | 0808日实时调用 |
| 历史聚合特征 | ar_model_feature_generate_groupby_product <br>ar_model_feature_generate_groupby_pas | 0808分区，对应0801～0807历史聚合特征 | 取0807分区数据，对应0731～0806历史聚合特征 |

解决方案：更改历史聚合特征，0808分区，对应0802\~0808历史聚合特征；冒泡数据0808分区，取对应0807分区的历史聚合特征

备注：未回溯数据，0828分区开始生效

#### 2.3 用户历史聚合特征问题

数梦链接：<https://studio.data.didichuxing.com/batch?projectId=1143&taskId=40026845&subType=LOG>

【问题1】部分特征均值为1，方差为0

取数验证：这些特征只有1、null 两种取值

```SQL
select
    pas_ans_cp_cnt_7d,
    pas_ans_cp_cnt_7d,
    pas_cancel_cp_cnt_7d,
    pas_p_cancel_cp_cnt_7d,
    pas_d_cancel_cp_cnt_7d,
    pas_finish_cp_cnt_7d,
    pas_ans_cp_cnt_14d,
    pas_cancel_cp_cnt_14d,
    pas_p_cancel_cp_cnt_14d,
    pas_d_cancel_cp_cnt_14d,
    pas_finish_cp_cnt_14d
from
    kflower_strategy.ar_model_feature_generate_groupby_pas 
    -- kflower_strategy.ar_seq_model_training_data
where
    dt = '2025-09-06'
```

【问题2】乘客应答率均值极低（7.8%）

![](252f4f1d98ba0864-截屏2025-09-10上午10.59.45.png)

【原因】

- 用户历史聚合特征加工逻辑有问题，忘记添加distinct；

- 由于原始表中，一个订单只能被一个商家应答，因此is_td_answer只对应唯一的product_id、trace_id；导致这部分特征全部为1 or null

```PlainText
with raw as(
    select
        order_id,
        count(distinct product_id) as pcnt
    from
        kflower_dw.dwd_kf_trd_order_anycar_di
    where
        dt = '2025-09-06'
        and is_td_answer = 1
    group by
        order_id
)
select
    pcnt,
    count(distinct order_id)
from
    raw
group by
    pcnt
```

- 错误口径：

	- 应答订单数：count(if(is_td_answer=1, trace_id, null)) as pas_ans_cnt_7d,

	- 单均应答商家数：count(if(is_td_answer=1, product_id, null)) / count(if(is_td_answer=1, trace_id, null)) as pas_ans_cp_cnt_7d,

	- 应答率：count(if(is_td_answer=1, trace_id, null)) / count(trace_id) as pas_ans_rate_14d,

- 正确口径

	- 应答订单数：count(distinct if(is_td_answer=1, trace_id, null)) as pas_ans_cnt_7d,

	- 单均应答商家数：**count**(distinct if(is_td_answer=1, concat_ws('-',product_id,trace_id), null)) / **count**(distinct if(is_td_answer=1, trace_id, null)) as pas_ans_cp_cnt_7d,

	- 应答率：count(distinct if(is_td_answer=1, trace_id, null)) / count(distinct trace_id) as pas_ans_rate_14d

- 取数验证：

	- 问题1验证，不再全部为1、null；问题2验证，应答率均值符合预期

![](a084a57805bc226d-截屏2025-09-11下午2.25.32.png)![](4fda2bb5a4cfc966-截屏2025-09-11下午2.30.08.png)

#### 2.4 sds特征问题-全部为null

问题发现：部分商家特征全部为null

```PlainText
select
    distinct 
    realtime_no_broadcast_cnt_one_circle_grid,
    realtime_no_broadcast_cnt,
    realtime_no_broadcast_order_cnt,
    realtime_no_broadcast_order_cnt_one_circle_grid
from
    kflower_strategy.zy_cr_model_test_data_v1
where
    dt = '2025-09-06'
```

原因：

- realtime_no_broadcast_order_cnt、realtime_no_broadcast_order_cnt_one_circle_grid，是旧版SDS特征，直接放弃

- realtime_no_broadcast_cnt_one_circle_grid、realtime_no_broadcast_cnt，工程漏传入，待积累数据后补充该特征

#### 2.5 sds特征问题-trace不全

AR模型日志表：kflower_strategy.ods_log_kflower_ether_price_anchor_cr_model

CR模型日志表：kflower_marketplace.ods_log_kflower_dups_eve_public_log_h

问题描述：

- 目前sds特征只从AR模型日志表中取数，会丢失9%的trace

- AR模型落表与CR模型落表，无交集；AR模型落表 并 CR模型落表 = 冒泡全集

> [!example]- PlainText 实现细节（73 行）
> ```PlainText
> with ar_trace as (
>     select 
>         distinct 
>         param['traceid'] as trace_id
>     from    
>         kflower_strategy.ods_log_kflower_ether_price_anchor_cr_model
>     where   
>         concat_ws('-', year, month, day) = '2025-09-06'
> ),
>
>
> cr_trace as (
>     select 
>         distinct traceid as trace_id
>     from 
>         kflower_marketplace.ods_log_kflower_dups_eve_public_log_h
>     where 
>         concat_ws('-', year, month, day) = '2025-09-06'
>         and model_name ='union_strategy_ar_deep_model_gpu'
> ),
>
> bubble_trace as 	-- 获得去重后时间靠后的trace_id
> (
>     select  
>         distinct trace_id
>     from (
>         select  
>             distinct trace_id,
>             row_number() over(partition by distinct_bubble_id order by bubble_time desc) as time_rank	--新去重冒泡口径
>         from    
>         (
>             select  
>                 *
>             from    
>                 kflower_dw.dwd_kf_trd_bubble_base_di
>             where  
>                 dt = '2025-09-06'
>                 and   product_1level in (1, 2)
>                 and   is_anycar_form = 1
>                 and   is_from_waiting_response <> 1
>                 and   passenger_id <> 0
>         ) a
>         left join (
>             select  
>                 estimate_id
>                 ,distinct_bubble_id
>             from    
>                 kflower_dw.dim_kf_trd_unity_bubble_anycar_label_di
>             where   
>                 dt = '2025-09-06'
>                 and source_id = 'kf'
>         ) c
>         on      a.bubble_id = c.estimate_id
>     ) a
>     where   time_rank = 1
> )
>
> select
>     sum(case when bubble_trace.trace_id is not null and ar_trace.trace_id is not null then 1 else 0 end) as bubble_u_ar,
>     sum(case when bubble_trace.trace_id is not null and ar_trace.trace_id is null then 1 else 0 end) as bubble_d_ar,
>     sum(case when bubble_trace.trace_id is null and ar_trace.trace_id is not null then 1 else 0 end) as ar_d_bubble,
>     sum(case when bubble_trace.trace_id is not null and cr_trace.trace_id is not null then 1 else 0 end) as bubble_u_cr,
>     sum(case when bubble_trace.trace_id is not null and cr_trace.trace_id is null then 1 else 0 end) as bubble_d_cr,
>     sum(case when bubble_trace.trace_id is null and cr_trace.trace_id is not null then 1 else 0 end) as cr_d_bubble,
>     sum(case when bubble_trace.trace_id is not null and (cr_trace.trace_id is not null or ar_trace.trace_id is not null) then 1 else 0 end) as bubble_d_ar_cr,
>     sum(case when ar_trace.trace_id is not null and cr_trace.trace_id is not null then 1 else 0 end) as ar_u_cr,
>     sum(case when ar_trace.trace_id is null and cr_trace.trace_id is not null then 1 else 0 end) as cr_d_ar,
>     sum(case when ar_trace.trace_id is not null and cr_trace.trace_id is null then 1 else 0 end) as ar_d_cr
>
> from 
>     bubble_trace 
>     full join ar_trace on bubble_trace.trace_id = ar_trace.trace_id
>     full join cr_trace on bubble_trace.trace_id = cr_trace.trace_id
> ```


> [!example]- 完整数据表（1 行记录）
> | bubble_u_ar | bubble_d_ar | ar_d_bubble | bubble_u_cr | bubble_d_cr | cr_d_bubble | bubble_d_ar_cr | ar_u_cr | cr_d_ar | ar_d_cr |
> | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
> | 6310752 | 610064 | 2673948 | 610040 | 6310776 | 248512 | 24 | 0 | 858552 | 8984700 |


#### 2.6 商家特征维数不是236

问题发现：在数据获取的过程中，发现1.2%的呼叫，商家特征位数不是236，这些呼叫会被丢掉。

原因：

1. 由于计算product_priority时，没有包含202品类，因此部分商家的product_priority会为null

```PlainText
select
    count(distinct trace_id),
    count(distinct (case when product_priority is null then trace_id end))
from
    kflower_strategy.ar_model_feature_generate_base
where
    dt = '2025-08-17'
```

2. 商家特征是使用concat_ws，组合成string。这个函数在遇到null时，会跳过，导致最终的商家特征数量不是236

```PlainText
concat_ws(';', 
    collect_list(
        concat_ws(',', 
                is_td_call,
                is_cp_answer,
                is_cp_finish,
                product_priority,
                first_appear_position,
                nvl(e.label, -1),
                case    
                    when channel='ziying' then 1
                    when channel='honghu' then 2
                    when channel='api' then 3
                    when channel='didi' then 4
                    else 5
                end
            )
        )
    ) as cp_features 
```

解决方案：在特价盒子加入202品类，需要修改发单优先级、传入特价盒子价格特征。工程同步修复

修改详情
1. 发单优先级修改

when a.level_type in (200, 101) then 3 -- 特快盒子、小猪特快

when a.level_type in (0, 102, 103) then 2 -- 普通品类、小猪一口价、小猪打车

when a.level_type in (104, 105, 107, 202) then 1 -- 小猪特价、特价盒子、幸运盒子、出行快选（特价盒子的一种）

2. 传入价格修改

max(if(level_type in (200, 101), basic_total_fee_amt, null)) as ufbox_basic_fee,

max(if(level_type in (0, 102, 103), basic_total_fee_amt, null)) as outbox_basic_fee,

max(if(level_type in (104, 105, 107,202), basic_total_fee_amt, null)) as uabox_basic_fee,

 max(if(level_type in (200, 101), estimate_fee_amt, null)) as ufbox_estimate_fee,

max(if(level_type in (0, 102, 103), estimate_fee_amt, null)) as outbox_estimate_fee,

max(if(level_type in (104, 105, 107,202), estimate_fee_amt, null)) as uabox_estimate_fee

修正后取数验证：

![](500195a7baa9fbab-截屏2025-09-12下午4.09.28.png)

### 3 数据获取

### 4 新版模型训练

#### 4.1 底表重跑周期记录

修复is_td_finish后，已重跑底表数据

| 底表 | 重跑周期 |
| --- | --- |
| ar_model_feature_base | 7.1-8.25 |
| ar_model_groupby_product_and_pas | 8.1-8.25 |
| ar_seq_model_training_data | 8.11-8.25 |

#### 4.2 数据集

在数梦执行pyspark任务，取数到hdfs后，再get到本地。

| 数据集 | 取数周期 | hdfs目录 | 取数任务 |
| --- | --- | --- | --- |
| 训练集 | 2025-08-11～2025-08-17 | hdfs dfs -get hdfs:///user/prod_kflower_strategy/kflower_strategy/hdp/pricing/zuyao/cr_model_train_0811-0817 | [https://schedule.data.didichuxing.com/v5/cycle/task/detail/kflower_strategy.acc_cr_train_data?projectId=1143](https://schedule.data.didichuxing.com/v5/cycle/task/detail/kflower_strategy.acc_cr_train_data?projectId=1143) |
| 测试集 | 2025-08-18～2025-08-24 | hdfs dfs -get hdfs:///user/prod_kflower_strategy/kflower_strategy/hdp/pricing/zuyao/cr_model_train_0818-0824 | [https://studio.data.didichuxing.com/batch?projectId=1143&taskId=47838295&subType=LOG](https://studio.data.didichuxing.com/batch?projectId=1143&taskId=47838295&subType=LOG) |

#### 4.3 获取均值方差

后台运行cr_data_prepare.py，大概5小时

问题描述

1. 部分cp特征，全部为Null

2. 部分trace特征，全部相同

3. 待之后解决：先分chunk=12000处理数据，后merge；慢且没必要

#### 4.4 模型训练

后台运行./model/cr_sql_model_mlp.py，大概6小时

取epoch=3的结果，此时完单auc最高

| 完单auc | channel auc | cp auc |
| --- | --- | --- |
| 0.764 | 0.900 | 0.879 |

## 5 仿真数据

### 5.1 GMV+COST

#### 模型输出logits单调性分析

- 看头部城市，特价盒子discount加深时（实付价不同），模型输出的特价盒子对应的logits是否单调递增；单调递增的判别标准为，100->97->94->91->88->85，后者折扣输出-前者折扣输出 > -1e-6

特价盒子输出不单调递增的例子
| 商家 | 折扣 | 特价盒子输出 |
| --- | --- | --- |
| 272 | 85 | 0.080198204 |
| 272 | 88 | 0.080158109 |
| 272 | 91 | 0.080211355 |
| 272 | 94 | 0.080316146 |
| 272 | 97 | 0.080467215 |
| 272 | 100 | 0.080661477 |

- 结论：头部城市，by城市看，模型输出的特价盒子对应的logits随折扣加深的单调递增的trace比例，约在70%

详细数据
by城市单调比例

| city_id | 单调递增的trace比例 |
| --- | --- |
| 8 | 70% |
| 13 | 68% |
| 25 | 67% |
| 26 | 70% |
| 32 | 62% |

by 城市、product_id 单调比例

> [!example]- 完整数据表（192 行记录）
> | product_id | city_id | increase_ratio |
> | --- | --- | --- |
> | 80 | 8 | 99.93% |
> | 236 | 8 | 57.16% |
> | 272 | 8 | 46.41% |
> | 275 | 8 | 52.77% |
> | 281 | 8 | 51.74% |
> | 297 | 8 | 44.16% |
> | 344 | 8 | 100.00% |
> | 346 | 8 | 74.94% |
> | 368 | 8 | 69.57% |
> | 373 | 8 | 36.93% |
> | 375 | 8 | 67.85% |
> | 384 | 8 | 100.00% |
> | 388 | 8 | 85.97% |
> | 390 | 8 | 72.49% |
> | 407 | 8 | 100.00% |
> | 408 | 8 | 100.00% |
> | 415 | 8 | 67.58% |
> | 416 | 8 | 100.00% |
> | 420 | 8 | 82.55% |
> | 438 | 8 | 83.17% |
> | 442 | 8 | 100.00% |
> | 444 | 8 | 59.97% |
> | 473 | 8 | 70.90% |
> | 486 | 8 | 51.26% |
> | 497 | 8 | 47.04% |
> | 510 | 8 | 85.16% |
> | 516 | 8 | 100.00% |
> | 527 | 8 | 89.30% |
> | 529 | 8 | 73.05% |
> | 538 | 8 | 40.66% |
> | 542 | 8 | 49.61% |
> | 557 | 8 | 37.59% |
> | 567 | 8 | 68.21% |
> | 571 | 8 | 72.72% |
> | 585 | 8 | 68.66% |
> | 597 | 8 | 62.62% |
> | 599 | 8 | 69.93% |
> | 5003 | 8 | 68.46% |
> | 5018 | 8 | 56.14% |
> | 5034 | 8 | 79.56% |
> | 5048 | 8 | 77.77% |
> | 5079 | 8 | 58.69% |
> | 5119 | 8 | 100.00% |
> | 5169 | 8 | 67.30% |
> | 5176 | 8 | 71.39% |
> | 5245 | 8 | 76.27% |
> | 5264 | 8 | 100.00% |
> | 5301 | 8 | 77.18% |
> | 5318 | 8 | 77.63% |
> | 5338 | 8 | 75.62% |
> | 5397 | 8 | 72.50% |
> | 5409 | 8 | 52.04% |
> | 5421 | 8 | 59.43% |
> | 5490 | 8 | 55.06% |
> | 5553 | 8 | 78.30% |
> | 5563 | 8 | 80.25% |
> | 80 | 13 | 88.47% |
> | 236 | 13 | 23.24% |
> | 275 | 13 | 58.09% |
> | 281 | 13 | 53.80% |
> | 283 | 13 | 53.22% |
> | 344 | 13 | 100.00% |
> | 346 | 13 | 77.15% |
> | 348 | 13 | 76.55% |
> | 368 | 13 | 53.29% |
> | 373 | 13 | 25.51% |
> | 384 | 13 | 100.00% |
> | 386 | 13 | 69.63% |
> | 388 | 13 | 84.75% |
> | 390 | 13 | 60.32% |
> | 399 | 13 | 74.95% |
> | 401 | 13 | 61.34% |
> | 407 | 13 | 100.00% |
> | 408 | 13 | 100.00% |
> | 417 | 13 | 26.34% |
> | 420 | 13 | 77.88% |
> | 442 | 13 | 75.05% |
> | 486 | 13 | 50.54% |
> | 497 | 13 | 41.76% |
> | 516 | 13 | 100.00% |
> | 521 | 13 | 50.88% |
> | 527 | 13 | 49.98% |
> | 529 | 13 | 72.63% |
> | 538 | 13 | 36.92% |
> | 540 | 13 | 71.36% |
> | 557 | 13 | 49.93% |
> | 571 | 13 | 81.11% |
> | 593 | 13 | 63.60% |
> | 5001 | 13 | 79.28% |
> | 5005 | 13 | 100.00% |
> | 5111 | 13 | 63.03% |
> | 5119 | 13 | 78.27% |
> | 5206 | 13 | 79.39% |
> | 5256 | 13 | 73.85% |
> | 5264 | 13 | 100.00% |
> | 5372 | 13 | 70.71% |
> | 5490 | 13 | 37.67% |
> | 5563 | 13 | 72.84% |
> | 80 | 25 | 99.92% |
> | 236 | 25 | 60.45% |
> | 280 | 25 | 72.59% |
> | 281 | 25 | 83.90% |
> | 294 | 25 | 51.44% |
> | 297 | 25 | 37.28% |
> | 344 | 25 | 100.00% |
> | 384 | 25 | 100.00% |
> | 386 | 25 | 81.01% |
> | 415 | 25 | 59.46% |
> | 420 | 25 | 84.91% |
> | 484 | 25 | 52.66% |
> | 486 | 25 | 42.91% |
> | 510 | 25 | 70.87% |
> | 516 | 25 | 100.00% |
> | 529 | 25 | 56.69% |
> | 538 | 25 | 41.75% |
> | 557 | 25 | 82.36% |
> | 593 | 25 | 63.75% |
> | 5018 | 25 | 39.56% |
> | 5079 | 25 | 40.46% |
> | 5185 | 25 | 44.98% |
> | 5264 | 25 | 100.00% |
> | 5318 | 25 | 70.59% |
> | 5490 | 25 | 41.38% |
> | 80 | 26 | 99.98% |
> | 226 | 26 | 100.00% |
> | 236 | 26 | 44.88% |
> | 275 | 26 | 81.59% |
> | 281 | 26 | 46.28% |
> | 344 | 26 | 100.00% |
> | 346 | 26 | 76.09% |
> | 349 | 26 | 72.43% |
> | 368 | 26 | 56.43% |
> | 370 | 26 | 78.30% |
> | 371 | 26 | 70.64% |
> | 373 | 26 | 50.01% |
> | 384 | 26 | 100.00% |
> | 388 | 26 | 81.85% |
> | 407 | 26 | 100.00% |
> | 415 | 26 | 76.08% |
> | 416 | 26 | 62.17% |
> | 417 | 26 | 81.65% |
> | 420 | 26 | 76.66% |
> | 422 | 26 | 86.44% |
> | 438 | 26 | 75.10% |
> | 444 | 26 | 50.36% |
> | 450 | 26 | 33.65% |
> | 454 | 26 | 82.06% |
> | 473 | 26 | 67.39% |
> | 482 | 26 | 60.51% |
> | 486 | 26 | 77.22% |
> | 497 | 26 | 46.98% |
> | 516 | 26 | 100.00% |
> | 529 | 26 | 71.74% |
> | 533 | 26 | 81.73% |
> | 538 | 26 | 20.35% |
> | 540 | 26 | 73.91% |
> | 553 | 26 | 83.92% |
> | 557 | 26 | 50.52% |
> | 567 | 26 | 84.02% |
> | 593 | 26 | 49.45% |
> | 5007 | 26 | 81.26% |
> | 5020 | 26 | 44.01% |
> | 5048 | 26 | 73.12% |
> | 5051 | 26 | 84.21% |
> | 5104 | 26 | 36.04% |
> | 5109 | 26 | 37.82% |
> | 5256 | 26 | 78.79% |
> | 5258 | 26 | 69.64% |
> | 5264 | 26 | 100.00% |
> | 5287 | 26 | 39.98% |
> | 5318 | 26 | 38.28% |
> | 5429 | 26 | 79.20% |
> | 5477 | 26 | 82.91% |
> | 5490 | 26 | 64.78% |
> | 80 | 32 | 99.97% |
> | 236 | 32 | 57.59% |
> | 297 | 32 | 22.72% |
> | 305 | 32 | 65.43% |
> | 344 | 32 | 100.00% |
> | 353 | 32 | 31.06% |
> | 368 | 32 | 58.18% |
> | 384 | 32 | 100.00% |
> | 386 | 32 | 65.88% |
> | 388 | 32 | 84.03% |
> | 407 | 32 | 100.00% |
> | 415 | 32 | 46.65% |
> | 420 | 32 | 48.59% |
> | 486 | 32 | 43.84% |
> | 488 | 32 | 29.08% |
> | 516 | 32 | 100.00% |
> | 550 | 32 | 34.68% |
> | 5049 | 32 | 28.06% |


> [!example]- PlainText 实现细节（78 行）
> ```PlainText
> with trace as (
>     select 
>         a.trace_id as trace_id,
>         discount_group,
>         product_id,
>         city_id,
>         probabilities
>     from 
>         (
>             select
>                 * 
>             from 
>                 kflower_strategy.platform_luckbox_acc_cr_model_predict
>             where
>                 dt = '2025-09-03'
>         ) a
>         inner join 
>         (
>             select 
>                 distinct 
>                 trace_id,
>                 city_id
>             from 
>                 kflower_strategy.pltf_union_stg_offline_simulation_trace_info
>             where 
>                 dt = '2025-09-03'
>                 and city_id in (8,26,32,25,13)
>         ) b on a.trace_id = b.trace_id
> ),
>
> trace_info as (
>     select 
>         trace_id,
>         product_id,
>         city_id,
>         max(case when discount_group='100-97' then probabilities[0] end) as ua_100,
>         max(case when discount_group='97-94' then probabilities[0] end) as ua_97,
>         max(case when discount_group='94-91' then probabilities[0] end) as ua_94,
>         max(case when discount_group='91-88' then probabilities[0] end) as ua_91,
>         max(case when discount_group='88-85' then probabilities[0] end) as ua_88,
>         max(case when discount_group='85-82' then probabilities[0] end) as ua_85
>     from 
>         trace
>     group by 
>         trace_id,
>         product_id,
>         city_id
>     having 
>         count(distinct discount_group) = 6
> ),
>
> raw as (
>     select 
>         (case when 
>             ua_97 - ua_100 > -1e-6
>             and ua_94 - ua_97 > -1e-6
>             and ua_91 - ua_94 > -1e-6
>             and ua_88 - ua_91 > -1e-6
>             and ua_85 - ua_88 > -1e-6
>         then 1 else 0 end)
>         as increase,
>         trace_id,
>         product_id,
>         city_id
>     from 
>         trace_info
> )
>
> select 
>     -- product_id,
>     city_id,
>     sum(increase)/count(*) as increase_ratio
> from 
>     raw
> group by 
>     -- product_id,
>     city_id
> ;
> ```


- 均值分析：特价盒子折扣加深时，特价盒子输出的logits均值只有第四位发生变化，**变幅<0.4%**

| 特价盒子折扣 | 特价盒子输出 | 特价盒子输出变幅 |
| --- | --- | --- |
| 85 | 0.090885 | 0.40% |
| 88 | 0.090525 | 0.31% |
| 91 | 0.090247 | 0.24% |
| 94 | 0.090027 | 0.19% |
| 97 | 0.089860 | 0.13% |
| 100 | 0.089745 | |

#### 仿真任务

eve任务：<https://ether.intra.hongyibo.com.cn/labs/new/14922>

按照特价折扣分组，数梦调度任务：

- 100:<https://studio.data.didichuxing.com/batch?projectId=1143&taskId=49080705&subType=HISTORY>

- 97:<https://studio.data.didichuxing.com/batch?projectId=1143&taskId=49080705&subType=HISTORY>

- 91、88:<https://studio.data.didichuxing.com/batch?projectId=1143&taskId=49086793&subType=HISTORY>

- 94、85:<https://studio.data.didichuxing.com/batch?projectId=1143&taskId=49086597&subType=HISTORY>

产出表：

- kflower_strategy.platform_luckbox_acc_cr_model_predict

- kflower_strategy.platform_luckbox_acc_cr_gmv_cost_offline_data

check每个阶段输出是否符合预期：

- 一阶段结果

	- 符合预期：

		- 幸运盒子折扣符合预期，91-88折模型预测结果对应91-88、91-85、91-82的trace

		- platform_cost符合预期，只有product_priority=1的车型，出折扣

		- penalty_factor符合预期

			- 城市56无数据（可能是幸运盒子未开城，所以默认填充penalty_factor=1）

		- lucky_probabilities符合预期，为特价盒子100折时模型的输出

	- 问题：

		- 部分cp_features（是否能以该商家完单）的输出，特价盒子内、盒子外、特快盒子的输出logits全部为0，导致叠加幸运盒子惩罚项后，依旧是0。原因是模型最后一层是**relu激活函数**

- 二阶段结果

	- 幸运盒子的logits=特价盒子100折的logits输出 X penalty_factor X 幸运盒子折扣 / 100.0，符合预期

- 三阶段结果

	- gmv_sum、cost_sum、acc_cr符合预期

> [!example]- PlainText 实现细节（132 行）
> ```PlainText
> -- 一阶段
> with
> raw as 
> (
>     select  
>         a.trace_id
>         ,b.discount_group
>         ,CAST(SUBSTRING_INDEX(b.discount_group, '-', 1) AS DOUBLE) AS ua_discount
>         ,CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(b.discount_group, '-', -1), ' ', 1) AS DOUBLE) AS lucky_discount
>         ,b.product_id
>         ,b.product_2level
>         ,product_priority
>         ,fee_rank
>         ,basic_total_fee_amt
>         ,platform_cost
>         ,estimate_fee_amt
>         ,a.probabilities
>         ,e.probabilities as lucky_probabilities
>         ,nvl(penalty_factor,1) as penalty_factor
>         ,count(a.product_id) over(partition by a.trace_id, a.discount_group, a.product_id) as product_show_times
>     from    
>         (
>             select 
>                 *
>             from 
>                 $t0
>         ) a
>         inner join 
>         (
>             select 
>                 distinct
>                 trace_id,
>                 discount_group,
>                 product_id,
>                 product_priority,
>                 product_2level,
>                 fee_rank,
>                 basic_total_fee_amt,
>                 platform_cost,
>                 estimate_fee_amt
>             from 
>                 kflower_strategy.pltf_union_stg_lucky_box_offline_simulation_price_list
>             where   
>                 dt = '${BIZ_DATE_LINE}'
>         ) b
>         on  a.trace_id=b.trace_id
>         and a.product_id=b.product_id
>         -- 特价盒子的折扣相等
>         and substr(a.discount_group,1,instr(a.discount_group,'-')-1) = substr(b.discount_group,1,instr(b.discount_group,'-')-1)
>         inner join 
>         (
>             select 
>                 distinct 
>                 trace_id,
>                 city_id
>             from 
>                 kflower_strategy.pltf_union_stg_offline_simulation_trace_info
>             where 
>                 dt = '${BIZ_DATE_LINE}'
>         ) c on a.trace_id = c.trace_id
>         left join (
>             select 
>                 distinct 
>                 penalty_factor,
>                 product_2level,
>                 city_id
>             from 
>                 kflower_strategy.plft_price_anchor_union_ar_model_penalty_rawdata
>             where 
>                 level_type = '107'
>                 and dt = '${BIZ_DATE_LINE}'
>         ) d on b.product_2level = d.product_2level and c.city_id = d.city_id
>         inner join (
>             -- 取100折输出作为幸运盒子的输出
>             select 
>                 *
>             from 
>                 $t0
>             where discount_group = '100-97'
>         ) e on a.trace_id = e.trace_id and a.product_id = e.product_id
> )
> -- 二阶段
> ,add_multi_cp_info as 
> (
>     select  a.trace_id
>             ,a.discount_group
>             ,a.product_id
>             ,a.fee_rank
>             ,b.product_priority as product_priority_b
>             ,b.basic_total_fee_amt
>             ,b.platform_cost
>             ,case 
>                 when b.product_priority=0 then b.lucky_probabilities[0]*b.penalty_factor*b.lucky_discount/100.0 -- 幸运盒子在特价盒子100折输出基础上加惩罚
>                 when b.product_priority=1 then b.probabilities[0]
>                 when b.product_priority=2 then b.probabilities[1]
>                 when b.product_priority=3 then b.probabilities[2]
>             end as trace_predict_logits
>             ,exp(
>                 case 
>                     when b.product_priority=0 then b.lucky_probabilities[3]*b.penalty_factor*b.lucky_discount/100.0 -- 幸运盒子在特价盒子100折输出基础上加惩罚
>                     when b.product_priority=1 then b.probabilities[3]
>                     when b.product_priority=2 then b.probabilities[4]
>                     when b.product_priority=3 then b.probabilities[5]
>                 end
>                 )
>             as cp_finish_predict
>             ,b.estimate_fee_amt as estimate_fee_amt_b	-- 勾到当前cp，都涉及了哪些product_id对应的row，将他们都left join过来，然后对于每一个fee_rank，按照所有left join之后的数据，用product_priority进行去重
>             ,row_number() over(partition by a.trace_id, a.discount_group, a.fee_rank, b.product_id order by b.product_priority desc, b.estimate_fee_amt desc) as same_eid_rank
>     from    raw a 
>     left join raw b
>     on      a.trace_id = b.trace_id
>       and   a.discount_group = b.discount_group
>       and   b.fee_rank <= a.fee_rank
> )
> -- 三阶段
> ,cal_multi_cp_contribution as 
> (
>     select  trace_id
>             ,discount_group
>             ,fee_rank
>             -- 加权求和的gmv和cost
>             ,sum(basic_total_fee_amt * cp_finish_predict) / sum(cp_finish_predict) as gmv_sum
>             ,sum(platform_cost * cp_finish_predict) / sum(cp_finish_predict) as cost_sum
>             ,(1 / (1 + exp(-sum(trace_predict_logits))) - 0.5) * 2 as acc_cr
>     from    add_multi_cp_info 
>     where   same_eid_rank = 1
>       and   basic_total_fee_amt is not null
>     group by trace_id, discount_group, fee_rank
> )
> select  *
> from    cal_multi_cp_contribution
> ;
> ```


[新版仿真验证.xlsx](9dd106717f655db1-新版仿真验证.xlsx)

### 5.2 CR 阈值

eve链接：<https://ether.intra.hongyibo.com.cn/labs/new/14958>

产出表：

- kflower_strategy.luckybox_cr_model_output

- kflower_strategy.luckybox_acc_cr_model_thre（注意有变化）

## 未来todo

1. 特征工程

	1. review特征质量、传入特征一致性

	2. **特征缺失、特征重要性分析**

2. 数据分析

	1. 商家分析，是否每个商家的数据都值得单独建模？
