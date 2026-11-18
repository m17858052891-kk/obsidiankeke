---
title: "默勾接受度 DE 口径"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2207753019343
cssclasses: ["strategy-body-note"]
---

# 默勾接受度 DE 口径

**对照阅读**　[[默勾接受度：定义、口径修复与目标讨论|定义、修复与目标讨论]]

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2207753019343)

这篇保留 DE 看板的计算逻辑和 SQL。先看过滤范围、trace 与 box_name 聚合方式，再与口径修复需求逐项核对。

**阅读定位**　[[#默勾、加勾、反勾呼叫冒泡数|默勾、加勾、反勾呼叫冒泡数]] · [[#跳勾呼叫冒泡数|跳勾呼叫冒泡数]] · [[#冒泡页竞争呼叫数|冒泡页竞争呼叫数]]

- DE 看板：<https://kfdata.didichuxing.com/?menuId=Vx9cotGLK9>

- 底表：[kflower_app.app_kf_trd_bubble_silent_check_platform_index_di](https://datamap.didichuxing.com/detail?uri=hive://mycluster-tj:kflower_app:app_kf_trd_bubble_silent_check_platform_index_di&keyword=kflower_app.app_kf_trd_bubble_silent_check_platform_index_di,kflower_app,app_kf_trd_bubble_silent_check_platform_index_di&version=next)

- 底表+：[kflower_dw.dwm_kf_trd_bubble_silent_check_all_di](https://datamap.didichuxing.com/detail?uri=hive://mycluster-tj:kflower_dw:dwm_kf_trd_bubble_silent_check_all_di&keyword=kflower_dw,kflower_dw.dwm_kf_trd_bubble_silent_check_all_di,dwm_kf_trd_bubble_silent_check_all_di&version=next)

## 默勾、加勾、反勾呼叫冒泡数

从表 `kflower_dw.dwm_kf_trd_bubble_silent_check_all_di` 取数

过滤条件为：

- `coalesce(is_from_waiting_response, 0) <> 1` ：排除等待应答页重新冒泡

- `product_1level <> 4` ：不含 didi 运力

- `is_fold_cp = 0` ：排除底部折叠车型（应该就是无车折叠）

然后统一先按 `trace_id + box_name` 聚合，得到每个维度 2 车型两个状态：

- `is_selected = max(if(selected_status = 1, 1, 0))`

- `is_call = max(if(is_call = 1, 1, 0))`

再按 `trace_id` 统计三类 `box_name` 数量：

- `mg_call`：count(distinct case when is_selected = 1 and is_call = 1 then box_name end)   默勾且被呼叫 box_name 数

- `jg_call`：count(distinct case when is_selected = 0 and is_call = 1 then box_name end) 加勾的 box_name 数

- `fg_call`：count(distinct case when is_selected = 1 and is_call = 0 then box_name end) 反勾的 box_name 数

- `is_calls` ：max(is_call) 这个 trace_id 是否发生呼叫

最后城市指标是基于上面每个 trace_id 的统计结果进行计算的：

- `默勾呼叫冒泡数`：count(distinct case when mg_call > 0 and jg_call = 0 and fg_call = 0 then trace_id end) 统计既没有加勾也没有反勾的 trace 数，同时要求呼叫

- `加勾呼叫冒泡数`：count(distinct case when jg_call > 0 then trace_id end) 统计有加勾的 trace 数

- `反勾呼叫冒泡数`：count(distinct case when fg_call > 0 and is_calls > 0 then trace_id end) 统计有反勾且有呼叫的 trace 数

## 跳勾呼叫冒泡数

过滤条件为：

- 排除等待应答页重新冒泡，

- 排除滴滴运力

- 排除底部折叠车型

先按 trace_id + box_name 聚合

- max(car_rank) as car_rank 每个 box_name 取最大的 car_rank

- max(is_call) as is_call

对每个 trace_id 里的车型按 car_rank 排序，算两个序号

- show_rn = row_number() over (partition by trace_id order by car_rank) 这是展示顺序

- call_rn = row_number() over (partition by trace_id, is_call order by car_rank) 这是“在呼叫组内”的顺序

只保留 is_call = 1 的车型，再按 trace_id 聚合，算两个值

- call_cnt = sum(is_call) 即这个冒泡页呼叫了几个 box_name

- serial_item = count(distinct show_rn - call_rn)

	- 如果被呼叫的车型在展示顺序里是连续的一段，那么 ==show_rn - call_rn== 会都一样，==serial_item = 1==

	- 如果中间跳过了某些未呼叫车型，那么这个差值会出现多个，==serial_item > 1==

- 满足这两个条件的 ==trace_id==，就算 1 个跳勾呼叫冒泡数：

	- 至少呼叫了 2 个维度2车型

	- 综上，这些被呼叫车型在展示顺序上不是连续的

## 冒泡页竞争呼叫数

对于一个 trace_id 来说，只要明细至少存在一行 `is_call = 1` ，就算这个 trace_id 的 ==call_bubble_trace_cnt = 1==：count(distinct if(is_call = 1, trace_id, null))

最后在城市维度统计总的 call_bubble_trace_cnt 数：sum(call_bubble_trace_cnt) as call_bubble_trace_cnt 

冒泡页数是率指标的分母

附 SQL：

> [!example]- SQL 实现细节（293 行）
> ```SQL
> --SPARK_SQL
> --********************************************************************--
> --author:xxuda_v
> --create time:2025-03-13 16:53:25
> --desc:花小猪打车网约车冒泡页默勾平台指标表
> --remind:请在资源引用中添加需要引用的资源
> --********************************************************************--
> insert overwrite table app_kf_trd_bubble_silent_check_platform_index_di partition (dt = '${BIZ_DATE_LINE}')
> select  city_id
>         ,sum(bubble_trace_cnt) as bubble_trace_cnt	--冒泡数
>         ,sum(mg_product_car_cnt) as mg_product_car_cnt	--默勾车型数，维度1
>         ,sum(mg_box_car_cnt) as mg_box_car_cnt	--默勾车型数，维度2
>         ,sum(mg_merge_car_cnt) as mg_merge_car_cnt	--默勾车型数，维度3
>         ,sum(car1_cnt) as car_product_cnt	--车型数，维度1
>         ,sum(car2_cnt) as car_box_cnt	--车型数，维度2
>         ,sum(car3_cnt) as car_merge_cnt	--车型数，维度3
>         ,percentile(if(mg_merge_car_cnt > 0, mg_merge_car_cnt, null), 0.75) as mg_quantile_75	--默勾车型75分位数(展现)
>         ,percentile(if(mg_merge_car_cnt > 0, mg_merge_car_cnt, null), 0.5) as mg_quantile_50	--默勾车型50分位数(展现)
>         ,percentile(if(mg_merge_car_cnt > 0, mg_merge_car_cnt, null), 0.25) as mg_quantile_25	--默勾车型25分位数(展现)
>         ,null as mg_dg_bubble_trace_cnt	--默勾单钩冒泡数(仅首行)
>         ,count(distinct case when is_mg_qg > 0 then trace_id end) as mg_qg_bubble_trace_cnt	--默勾全勾冒泡数(展现)
>         ,count(distinct case when is_mg_bottom_price > 0 then trace_id end) as mg_bottom_price_bubble_trace_cnt	--仅默勾最低价冒泡数(展现) 
>         ,avg(mg_max_price / mg_mix_price) as mg_price_coefficient	--默勾价格系数       
>         ,sum(call_bubble_trace_cnt) as call_bubble_trace_cnt	--冒泡页的竞争呼叫订单数
>         ,sum(call_car1_cnt) as call_product_car_cnt	--呼叫车型数，维度1
>         ,sum(call_car2_cnt) as call_box_car_cnt	--呼叫车型数，维度2
>         ,sum(call_car3_cnt) as call_merge_car_cnt	--呼叫车型数，维度3
>         ,sum(if(just_call = 1, car1_cnt, null)) as call_just_product_car_cnt	--呼叫车型数,维度1(只要有呼叫，并统计所有车型)
>         ,sum(if(just_call = 1, car2_cnt, null)) as call_just_box_car_cnt	--呼叫车型数,维度2(只要有呼叫，并统计所有车型)
>         ,sum(if(just_call = 1, car3_cnt, null)) as call_just_merge_car_cnt	--呼叫车型数,维度3(只要有呼叫，并统计所有车型)
>         ,percentile(if(call_car3_cnt > 0, call_car3_cnt, null), 0.75) as call_quantile_75	--呼叫车型75分位数(展现)
>         ,percentile(if(call_car3_cnt > 0, call_car3_cnt, null), 0.5) as call_quantile_50	--呼叫车型50分位数(展现)
>         ,percentile(if(call_car3_cnt > 0, call_car3_cnt, null), 0.25) as call_quantile_25	--呼叫车型25分位数(展现)
>         ,null as dg_call_bubble_trace_cnt	--单钩呼叫冒泡数（仅首行）
>         ,count(distinct if(is_qg_call > 0, trace_id, null)) as qg_call_bubble_trace_cnt	--全勾呼叫冒泡数
>         ,count(distinct if(is_call_bottom_price > 0, trace_id, null)) as call_bottom_price_bubble_trace_cnt	--仅呼最低价的呼叫冒泡数（展现）
>         ,avg(call_max_price / call_mix_price) as call_price_coefficient	--呼叫价格系数
>         ,null as mg_call_bubble_trace_cnt	--默勾呼叫冒泡数(维度2，基于呼叫)
>         ,null as jg_call_bubble_trace_cnt	--加勾呼叫冒泡数(维度2，基于呼叫)
>         ,null as fg_call_bubble_trace_cnt	--反勾呼叫冒泡数(维度2，基于呼叫)
>         ,null as tg_call_bubble_trace_cnt	--跳勾呼叫冒泡数(维度2，基于呼叫)
> from    (
>     select  trace_id
>             ,max(city_id) as city_id
>             ,count(distinct trace_id) as bubble_trace_cnt
>             ,count(distinct if(selected_status = 1, product_id_name, null)) as mg_product_car_cnt
>             ,count(distinct if(selected_status = 1, box_name, null)) as mg_box_car_cnt
>             ,count(distinct if(selected_status = 1, equivalent_merge_name, null)) as mg_merge_car_cnt
>             ,count(distinct product_id_name) as car1_cnt
>             ,count(distinct box_name) as car2_cnt
>             ,count(distinct equivalent_merge_name) as car3_cnt
>             ,case   when min(selected_status) <> 0 then 1
>                     else 0
>              end as is_mg_qg	--判断默勾全勾，最小值不等于0，那就是全勾 1
>             ,case   when max(case when selected_status = 1 then estimate_fee_amt end) = min(estimate_fee_amt) then 1
>                     else 0
>              end as is_mg_bottom_price	--判断默勾的最大价格 等于 整体的最小价格
>             ,max(case when selected_status = 1 then estimate_fee_amt end) as mg_max_price	--默勾最高价
>             ,min(case when selected_status = 1 then estimate_fee_amt end) as mg_mix_price	--默勾最低价
>             ,count(distinct if(is_call = 1, trace_id, null)) as call_bubble_trace_cnt
>             ,count(distinct if(is_call = 1, product_id_name, null)) as call_car1_cnt
>             ,count(distinct if(is_call = 1, box_name, null)) as call_car2_cnt
>             ,count(distinct if(is_call = 1, equivalent_merge_name, null)) as call_car3_cnt
>             ,case   when max(is_call) <> 0 then 1
>                     else 0
>              end as just_call	--只要有呼叫，并统计车型数
>             ,case   when min(is_call) <> 0 then 1
>                     else 0
>              end as is_qg_call	--判断呼叫全勾
>             ,case   when max(case when is_call = 1 then estimate_fee_amt end) = min(estimate_fee_amt) then 1
>                     else 0
>              end as is_call_bottom_price	--判断呼叫的最大价格 等于 整体的最小价格
>             ,max(case when is_call = 1 then estimate_fee_amt end) as call_max_price	--默勾最高价
>             ,min(case when is_call = 1 then estimate_fee_amt end) as call_mix_price	--默勾最低价
>             ,max(case when selected_status = 1 then 1 else 0 end)
>     from    (
>         select  trace_id
>                 ,city_id
>                 ,product_id_name	--维度1
>                 ,box_name	--维度2
>                 ,equivalent_merge_name	--维度3
>                 ,level_type
>                 ,car_rank
>                 ,selected_status
>                 ,select_status
>                 ,is_call
>                 ,merge_rank
>                 ,estimate_fee_amt
>         from    kflower_dw.dwm_kf_trd_bubble_silent_check_all_di
>         where   dt = '${BIZ_DATE_LINE}'
>           and   coalesce(is_from_waiting_response, 0) <> 1	--是冒泡页
>           and   product_1level <> 4	--是花小猪
>           and   is_fold_cp = 0	--是否底部折叠车型, 1-是，0-否
>     ) as a
>     group by trace_id
> ) as b
> group by city_id
> union all 
> --维度2，默勾、加勾、反勾
> select  city_id
>         ,null as bubble_trace_cnt	--冒泡数
>         ,null as mg_product_car_cnt	--默勾车型数，维度1
>         ,null as mg_box_car_cnt	--默勾车型数，维度2
>         ,null as mg_merge_car_cnt	--默勾车型数，维度3
>         ,null as car_product_cnt	--车型数，维度1
>         ,null as car_box_cnt	--车型数，维度2
>         ,null as car_merge_cnt	--车型数，维度3
>         ,null as mg_quantile_75	--默勾车型75分位数(展现)
>         ,null as mg_quantile_50	--默勾车型75分位数(展现)
>         ,null as mg_quantile_25	--默勾车型75分位数(展现)
>         ,null as mg_dg_bubble_trace_cnt	--默勾单钩冒泡数(仅首行)
>         ,null as mg_qg_bubble_trace_cnt	--默勾全勾冒泡数(展现)
>         ,null as mg_bottom_price_bubble_trace_cnt	--仅默勾最低价冒泡数(展现) 
>         ,null as mg_price_coefficient	--默勾价格系数       
>         ,null as call_bubble_trace_cnt	--冒泡页的竞争呼叫订单数
>         ,null as call_product_car_cnt	--呼叫车型数，维度1
>         ,null as call_box_car_cnt	--呼叫车型数，维度2
>         ,null as call_merge_car_cnt	--呼叫车型数，维度3
>         ,null as call_just_product_car_cnt	--呼叫车型数,维度1(只要有呼叫，并统计所有车型)
>         ,null as call_just_box_car_cnt	--呼叫车型数,维度2(只要有呼叫，并统计所有车型)
>         ,null as call_just_merge_car_cnt	--呼叫车型数,维度3(只要有呼叫，并统计所有车型)
>         ,null as call_quantile_75	--呼叫车型75分位数(展现)
>         ,null as call_quantile_50	--呼叫车型75分位数(展现)
>         ,null as call_quantile_25	--呼叫车型75分位数(展现)
>         ,null as dg_call_bubble_trace_cnt	--单钩呼叫冒泡数
>         ,null as qg_call_bubble_trace_cnt	--全勾呼叫冒泡数
>         ,null as call_bottom_price_bubble_trace_cnt	--仅呼最低价的呼叫冒泡数（展现）
>         ,null as call_price_coefficient	--呼叫价格系数
>         ,count(distinct case when mg_call > 0 and jg_call = 0 and fg_call = 0 then trace_id end) as mg_call_bubble_trace_cnt	--默勾呼叫冒泡数(维度2，基于呼叫)
>         ,count(distinct case when jg_call > 0 then trace_id end) as jg_call_bubble_trace_cnt	--加勾呼叫冒泡数(维度2，基于呼叫)
>         ,count(distinct case when fg_call > 0 and is_calls > 0 then trace_id end) as fg_call_bubble_trace_cnt	--反勾呼叫冒泡数(维度2，基于呼叫)
>         ,null as tg_call_bubble_trace_cnt	--跳勾呼叫冒泡数(维度2，基于呼叫)
> from    (
>     select  trace_id
>             ,max(city_id) as city_id
>             ,count(distinct case when is_selected = 1 and is_call = 1 then box_name end) as mg_call	-- 默勾呼叫
>             ,count(distinct case when is_selected = 0 and is_call = 1 then box_name end) as jg_call	-- 加勾呼叫
>             ,count(distinct case when is_selected = 1 and is_call = 0 then box_name end) as fg_call	-- 反勾呼叫
>             ,max(is_call) as is_calls
>     from    (
>         select  trace_id
>                 ,box_name
>                 ,max(city_id) as city_id
>                 ,max(if(selected_status = 1, 1, 0)) as is_selected
>                 ,max(if(is_call = 1, 1, 0)) as is_call
>         from    (
>             select  city_id
>                     ,trace_id
>                     ,box_name
>                     ,selected_status
>                     ,is_call
>             from    kflower_dw.dwm_kf_trd_bubble_silent_check_all_di
>             where   dt = '${BIZ_DATE_LINE}'
>               and   coalesce(is_from_waiting_response, 0) <> 1	--是冒泡页
>               and   product_1level <> 4	--是花小猪
>               and   is_fold_cp = 0	--是否底部折叠车型, 1-是，0-否
>         ) as a
>         group by trace_id, box_name
>     ) as b
>     group by trace_id
>     having  max(is_call) > 0
> ) as c
> group by city_id
> union all 
> --维度2，跳勾
> select  city_id
>         ,null as bubble_trace_cnt	--冒泡数
>         ,null as mg_product_car_cnt	--默勾车型数，维度1
>         ,null as mg_box_car_cnt	--默勾车型数，维度2
>         ,null as mg_merge_car_cnt	--默勾车型数，维度3
>         ,null as car_product_cnt	--车型数，维度1
>         ,null as car_box_cnt	--车型数，维度2
>         ,null as car_merge_cnt	--车型数，维度3
>         ,null as mg_quantile_75	--默勾车型75分位数(展现)
>         ,null as mg_quantile_50	--默勾车型75分位数(展现)
>         ,null as mg_quantile_25	--默勾车型75分位数(展现)
>         ,null as mg_dg_bubble_trace_cnt	--默勾单钩冒泡数(仅首行)
>         ,null as mg_qg_bubble_trace_cnt	--默勾全勾冒泡数(展现)
>         ,null as mg_bottom_price_bubble_trace_cnt	--仅默勾最低价冒泡数(展现) 
>         ,null as mg_price_coefficient	--默勾价格系数       
>         ,null as call_bubble_trace_cnt	--冒泡页的竞争呼叫订单数
>         ,null as call_product_car_cnt	--呼叫车型数，维度1
>         ,null as call_box_car_cnt	--呼叫车型数，维度2
>         ,null as call_merge_car_cnt	--呼叫车型数，维度3
>         ,null as call_just_product_car_cnt	--呼叫车型数,维度1(只要有呼叫，并统计所有车型)
>         ,null as call_just_box_car_cnt	--呼叫车型数,维度2(只要有呼叫，并统计所有车型)
>         ,null as call_just_merge_car_cnt	--呼叫车型数,维度3(只要有呼叫，并统计所有车型)
>         ,null as call_quantile_75	--呼叫车型75分位数(展现)
>         ,null as call_quantile_50	--呼叫车型75分位数(展现)
>         ,null as call_quantile_25	--呼叫车型75分位数(展现)
>         ,null as dg_call_bubble_trace_cnt	--单钩呼叫冒泡数
>         ,null as qg_call_bubble_trace_cnt	--全勾呼叫冒泡数
>         ,null as call_bottom_price_bubble_trace_cnt	--仅呼最低价的呼叫冒泡数（展现）
>         ,null as call_price_coefficient	--呼叫价格系数
>         ,null as mg_call_bubble_trace_cnt	--默勾呼叫冒泡数(维度2，基于呼叫)
>         ,null as jg_call_bubble_trace_cnt	--加勾呼叫冒泡数(维度2，基于呼叫)
>         ,null as fg_call_bubble_trace_cnt	--反勾呼叫冒泡数(维度2，基于呼叫)
>         ,count(distinct trace_id) as tg_call_bubble_trace_cnt	--跳勾呼叫冒泡数(维度2，基于呼叫)
> from    (
>     select  trace_id
>             ,max(city_id) as city_id
>             ,sum(is_call) as call_cnt
>             ,count(distinct show_rn-call_rn) as serial_item
>     from    (
>         select  trace_id
>                 ,box_name
>                 ,city_id
>                 ,car_rank
>                 ,is_call
>                 ,row_number() over (partition by trace_id, is_call order by car_rank) as call_rn
>                 ,row_number() over (partition by trace_id order by car_rank) as show_rn
>         from    (
>             select  trace_id
>                     ,box_name
>                     ,max(city_id) as city_id
>                     ,max(car_rank) as car_rank
>                     ,max(is_call) as is_call
>             from    kflower_dw.dwm_kf_trd_bubble_silent_check_all_di
>             where   dt = '${BIZ_DATE_LINE}'
>               and   coalesce(is_from_waiting_response, 0) <> 1	--是冒泡页
>               and   product_1level <> 4	--是花小猪
>               and   is_fold_cp = 0	--是否底部折叠车型, 1-是，0-否
>             group by trace_id, box_name
>         ) as a
>         order by car_rank
>     ) as b
>     where   is_call = 1
>     group by trace_id
> ) tt
> where   call_cnt > 1
>   and   serial_item > 1
> group by city_id
> union all 
> --默勾单钩，维度3
> select  city_id
>         ,null as bubble_trace_cnt	--冒泡数
>         ,null as mg_product_car_cnt	--默勾车型数，维度1
>         ,null as mg_box_car_cnt	--默勾车型数，维度2
>         ,null as mg_merge_car_cnt	--默勾车型数，维度3
>         ,null as car_product_cnt	--车型数，维度1
>         ,null as car_box_cnt	--车型数，维度2
>         ,null as car_merge_cnt	--车型数，维度3
>         ,null as mg_quantile_75	--默勾车型75分位数(展现)
>         ,null as mg_quantile_50	--默勾车型50分位数(展现)
>         ,null as mg_quantile_25	--默勾车型25分位数(展现)
>         ,count(distinct if(is_mg_dg = 1, trace_id, null)) as mg_dg_bubble_trace_cnt	--默勾单钩冒泡数(仅首行)
>         ,null as mg_qg_bubble_trace_cnt	--默勾全勾冒泡数(展现)
>         ,null as mg_bottom_price_bubble_trace_cnt	--仅默勾最低价冒泡数(展现) 
>         ,null as mg_price_coefficient	--默勾价格系数       
>         ,null as call_bubble_trace_cnt	--冒泡页的竞争呼叫订单数
>         ,null as call_product_car_cnt	--呼叫车型数，维度1
>         ,null as call_box_car_cnt	--呼叫车型数，维度2
>         ,null as call_merge_car_cnt	--呼叫车型数，维度3
>         ,null as call_just_product_car_cnt	--呼叫车型数,维度1(只要有呼叫，并统计所有车型)
>         ,null as call_just_box_car_cnt	--呼叫车型数,维度2(只要有呼叫，并统计所有车型)
>         ,null as call_just_merge_car_cnt	--呼叫车型数,维度3(只要有呼叫，并统计所有车型)
>         ,null as call_quantile_75	--呼叫车型75分位数(展现)
>         ,null as call_quantile_50	--呼叫车型50分位数(展现)
>         ,null as call_quantile_25	--呼叫车型25分位数(展现)
>         ,count(distinct if(is_call_dg = 1, trace_id, null)) as dg_call_bubble_trace_cnt	--默勾单钩冒泡数(仅首行)
>         ,null as qg_call_bubble_trace_cnt	--全勾呼叫冒泡数
>         ,null as call_bottom_price_bubble_trace_cnt	--仅呼最低价的呼叫冒泡数（展现）
>         ,null as call_price_coefficient	--呼叫价格系数
>         ,null as mg_call_bubble_trace_cnt	--默勾呼叫冒泡数(维度2，基于呼叫)
>         ,null as jg_call_bubble_trace_cnt	--加勾呼叫冒泡数(维度2，基于呼叫)
>         ,null as fg_call_bubble_trace_cnt	--反勾呼叫冒泡数(维度2，基于呼叫)
>         ,null as tg_call_bubble_trace_cnt	--跳勾呼叫冒泡数(维度2，基于呼叫)
> from    (
>     select  trace_id
>             ,max(city_id) as city_id
>             ,case   when sum(selected_status) = 1 then 1
>                     else 0
>              end as is_mg_dg	--是否默勾单钩
>             ,case   when sum(is_call) = 1 then 1
>                     else 0
>              end as is_call_dg	--是否呼叫单钩
>     from    (
>         select  trace_id
>                 ,equivalent_merge_name	--维度3
>                 ,max(city_id) as city_id
>                 ,max(selected_status) as selected_status
>                 ,max(is_call) as is_call
>         from    kflower_dw.dwm_kf_trd_bubble_silent_check_all_di
>         where   dt = '${BIZ_DATE_LINE}'
>           and   coalesce(is_from_waiting_response, 0) <> 1	--是冒泡页
>           and   product_1level <> 4	--是花小猪
>           and   is_fold_cp = 0	--是否底部折叠车型, 1-是，0-否
>         group by trace_id, equivalent_merge_name
>     ) as a
>     group by trace_id
> ) as b
> group by city_id
> ;
> ```
