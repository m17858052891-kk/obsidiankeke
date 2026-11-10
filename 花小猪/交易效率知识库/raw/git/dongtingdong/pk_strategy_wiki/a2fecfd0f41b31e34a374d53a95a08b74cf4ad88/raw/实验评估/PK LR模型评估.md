# 〇、结论

- 人均完单-0.13%，CR -0.4pp（CR折损来自于乘客取消）

- （含改派）司机取消-0.9pp，乘客取消+0.6pp，整体司乘取消-0.3pp。但司机取消几乎均从改派出口；（不含改派）司机取消-0.03pp，乘客取消+0.5pp；改派率-0.9pp

- 影响乘客取消的可能因素中，平均应答时长-0.79%，平均应答距离+2.57%，平均应答价格+0.24%

# 一、背景

线上xgb模型可解释性差，模型更新导致商家份额波动，或者某一个商家的份额出现较大变化时，平台并不能给出非常准确的原因分析。另一方面，商家因为不能知悉每个因素的影响，从而不能针对性地调整来提升PK胜率，进而提升商家自身份额。

 

PK胜率直接影响商家份额，预期上线PK模型可解释版本，牵引商家改善司机履约，一方面提高商家自身份额，另一方面促进长期司机生态正向发展。从而提升平台效率。

# 二、实验配置

- 分流方式

	- 乘客分流

- 实验选城

	- 13青岛、14大连、18重庆、24长沙、26太原、32厦门、50绵阳、61秦皇岛、85温州、146舟山、258云浮

- 实验周期

	- 20240615-20240619

- 实验配置

	- 实验流量占比35%

# 三、大盘评估

- 人均完单-0.13%，CR -0.4pp（CR折损来自于乘客取消）

- （含改派）司机取消-0.9pp，乘客取消+0.6pp，整体司乘取消-0.3pp。但司机取消几乎均从改派出口

- （不含改派）司机取消-0.03pp，乘客取消+0.5pp，改派率-0.9pp

- 影响乘客取消的可能因素中，平均应答时长-0.79%，平均应答距离+2.57%，平均应答价格+0.24%

| exp_group <br> | exp_pid_cnt <br> | 人均呼叫 <br> | 人均完单 <br> | 人均GMV <br> | 应答后乘客取消率（含改派） <br> | 应答后司机取消率（含改派） <br> | 改派率 <br> | 应答率 <br> | 成交率 <br> | 司机取消率 <br> | 乘客取消率 <br> | 平均应答时长 <br> | 平均应答距离 <br> | ASP <br> | 平均应答价格 <br> |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| control_group <br> | 1323971 <br> | 2.774 <br> | 2.134 <br> |                        37.139 <br> | 14.3% <br> | 13.9% <br> | 13.1% <br> | 94.1% <br> | 76.9% <br> | 0.9% <br> | 16.4% <br> |                 19.26 <br> |            1,685.94 <br> | 17.41 <br> |                 12.29 <br> |
| treatment_group <br> | 712102 <br> | 2.785 <br> | 2.131 <br> |                        37.030 <br> | 14.9% <br> | 13.0% <br> | 12.2% <br> | 94.2% <br> | 76.5% <br> | 0.9% <br> | 16.9% <br> |                 19.11 <br> |            1,729.28 <br> | 17.38 <br> |                 12.32 <br> |
| 变化 <br> | / <br> | 0.387% <br> | -0.130% <br> | -0.293% <br> | 0.6pp <br> | -0.9pp <br> | -0.9pp <br> | +0.08pp <br> | -0.4pp <br> | -0.03pp <br> | +0.5pp <br> | -0.79% <br> | 2.57% <br> | -0.16% <br> | 0.24% <br> |

# 四、分商家评估

## 4.1 宏鹄

- 宏鹄人均完单+10%，人均GMV+11%

| exp_group <br> | exp_pid_cnt <br> | 人均呼叫 <br> | 人均完单 <br> | 人均GMV <br> | 应答后乘客取消率 <br> | 应答后司机取消率 <br> | 改派率 <br> | 应答率 <br> | 成交率 <br> | 司机取消率 <br> | 乘客取消率 <br> | 平均应答时长 <br> | 平均应答距离 <br> | ASP <br> | 平均应答价格 <br> |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| control_group <br> | 1248814 <br> |           2.679 <br> |           1.084 <br> |                        18.747 <br> | 14.2% <br> | 15.3% <br> | 14.7% <br> | 49.7% <br> | 40.5% <br> | 0.7% <br> | 16.5% <br> |                 17.56 <br> |            1,650.86 <br> |           17.30 <br> |                 11.96 <br> |
| treatment_group <br> | 671789 <br> |           2.689 <br> |           1.195 <br> |                        20.824 <br> | 14.5% <br> | 14.0% <br> | 13.4% <br> | 54.6% <br> | 44.4% <br> | 0.7% <br> | 16.7% <br> |                 16.43 <br> |            1,677.18 <br> |           17.42 <br> |                 12.20 <br> |
| 变化 <br> | / <br> | 0.386% <br> | 10.258% <br> | 11.078% <br> | 0.3% <br> | -1.3% <br> | -1.2% <br> | 4.90% <br> | 3.98% <br> | -0.02% <br> | 0.18% <br> | -6.42% <br> | 1.59% <br> | 0.74% <br> | 2.01% <br> |

## 4.2 自营

- 自营人均完单-14%，人均GMV-15%

| exp_group <br> | exp_pid_cnt <br> | 人均呼叫 <br> | 人均完单 <br> | 人均GMV <br> | 应答后乘客取消率 <br> | 应答后司机取消率 <br> | 改派率 <br> | 应答率 <br> | 成交率 <br> | 司机取消率 <br> | 乘客取消率 <br> | 平均应答时长 <br> | 平均应答距离 <br> | ASP <br> | 平均应答价格 <br> |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| control_group <br> | 1248814 <br> |           2.729 <br> |           0.901 <br> |                        16.148 <br> | 14.03% <br> | 14.58% <br> | 13.65% <br> | 40.24% <br> | 33.00% <br> | 1.07% <br> | 16.16% <br> |                 18.21 <br> |            1,782.64 <br> |           17.93 <br> |                 12.65 <br> |
| treatment_group <br> | 671789 <br> |           2.740 <br> |           0.772 <br> |                        13.691 <br> | 14.99% <br> | 14.17% <br> | 13.24% <br> | 34.83% <br> | 28.17% <br> | 1.07% <br> | 17.15% <br> |                 19.69 <br> |            1,883.31 <br> |           17.74 <br> |                 12.43 <br> |
| 变化 <br> | / <br> | 0.387% <br> | -14.316% <br> | -15.216% <br> | 0.96% <br> | -0.42% <br> | -0.42% <br> | -5.40% <br> | -4.83% <br> | -0.01% <br> | 0.99% <br> | 8.11% <br> | 5.65% <br> | -1.05% <br> | -1.74% <br> |

## 4.3 API

人均呼叫+0.49%

人均完单+9.6%

人均GMV+11.2%

## 4.4 滴滴

人均呼叫+0.38%

人均完单+0.62%

人均GMV+0.09%

# 五、分城市评估

- 11城中，5个城市完单正向，6个城市完单负向

- 乘客取消率变化与应答距离变化正相关关系明显

| city_id <br> | 人均完单变化 <br> | CR变化 <br> |
| --- | --- | --- |
| 13 <br> | 0.39% <br> | 0.00030834 <br> |
| 14 <br> | 1.34% <br> | 0.00239249 <br> |
| 18 <br> | -0.50% <br> | -0.0023759 <br> |
| 24 <br> | -0.99% <br> | -0.0017189 <br> |
| 26 <br> | 0.01% <br> | -0.0063268 <br> |
| 32 <br> | -0.35% <br> | -0.0084079 <br> |
| 50 <br> | -0.10% <br> | -0.0034322 <br> |
| 61 <br> | 0.47% <br> | 0.00854647 <br> |
| 85 <br> | -0.43% <br> | -0.0048122 <br> |
| 146 <br> | 1.34% <br> | 0.00298946 <br> |
| 258 <br> | -0.06% <br> | -0.0082365 <br> |

横轴是实验组相比于对照组应答距离相对变化

纵轴是实验组相比于对照组乘客取消率变化

![](https://s3-ep-inter.didistatic.com/didoc-upload-image-prod/17188741667955e2210e51c4ff7c31d8b9e2c138389de/image.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKDD00000000000EBLCTZNRBJHX6ZS%2F20260526%2Fgzep%2Fs3%2Faws4_request&X-Amz-Date=20260526T080111Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=91756d5a880a2cccad035e31f830441a2c4e7455586d538d61388d007927fd55)

![](https://s3-ep-inter.didistatic.com/didoc-upload-image-prod/17188871575248dc535d64dd29919953492af93b7350e/image.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKDD00000000000EBLCTZNRBJHX6ZS%2F20260526%2Fgzep%2Fs3%2Faws4_request&X-Amz-Date=20260526T080111Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=dca860ffcd2f3887edea81163e349d0d967a60acc14beffc2c53ec0bf5b625bf)![](https://s3-ep-inter.didistatic.com/didoc-upload-image-prod/171888757333875b9da5a3315574f7834603758310445/image.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKDD00000000000EBLCTZNRBJHX6ZS%2F20260526%2Fgzep%2Fs3%2Faws4_request&X-Amz-Date=20260526T080111Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=f9fe5e40c4618eef1d87ee5e66ecb51b84cd02174b8070d29e295786934711da)

# 六、附录

[PK乘客分流评估.csv](https://s3-ep-inter.didistatic.com/didoc-upload-file-prod/1718864956453a1fa56f853d68d477268db9168856a41/PK%25E4%25B9%2598%25E5%25AE%25A2%25E5%2588%2586%25E6%25B5%2581%25E8%25AF%2584%25E4%25BC%25B0.csv?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKDD00000000000EBLCTZNRBJHX6ZS%2F20260526%2Fgzep%2Fs3%2Faws4_request&X-Amz-Date=20260526T080111Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=3be50f9b6b97940383262f16dbc16f516a1b3d6a6958b653d0afb6856af3439b)

[分城市底数.csv](https://s3-ep-inter.didistatic.com/didoc-upload-file-prod/171886495339958a3c64db2eb885f663873a828e47609/%25E5%2588%2586%25E5%259F%258E%25E5%25B8%2582%25E5%25BA%2595%25E6%2595%25B0.csv?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKDD00000000000EBLCTZNRBJHX6ZS%2F20260526%2Fgzep%2Fs3%2Faws4_request&X-Amz-Date=20260526T080111Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=b39639b21a408975f93667d9e65901b068e30532fe3e1494cbf3406e3c8fe729)

```SQL
with target as --target表请替换为实验分流的表，仅保留两列，order_id,exp_group，需去重
    (select order_id,exp_group,passenger_id
from
        (select
            distinct order_id,
            passenger_id
        from
            kflower_dw.dwd_kf_trd_unity_order_anycar_di
        where
            dt between "${date}" and "${date2}"
            and start_city_id in (${city_list})
            -- and source_id = 'kf'
            -- and is_hxz_call = 1
            )a 
        left join 

        (select 
		distinct apollo_key as pid,
		exp_group
	from 
		apollo.exp_group_data
	where 
		ymd between "${date}" and "${date2}"
		and experiment = 'pk_explain_lr_model_PID_experiment')b 
on a.passenger_id = b.pid
        
    ),
    table1 as (
        select
            a.dt,
            call_time,
            a.order_id,
            city_id,
            a.estimate_id,
            a.product_id,
            a.call_car_level_id,
            is_hxz_call,
            is_pbd_call,
            is_thlm_call,
            is_compete_call,
            is_objective_call,
            is_platform_objective_call,
            product_type,
            platform_name,
            source_id,
            case
                when is_hxz_call = 1 then '小猪端'
                when is_thlm_call = 1 then '特惠联盟端'
                when is_pbd_call = 1
                and channel_name in ('百度地图', '腾讯地图') then 'PBD端-地图'
                when is_pbd_call = 1
                and channel_name not in ('百度地图', '腾讯地图') then 'PBD端-其他'
                else '其他'
            end as channel_name,
            case
                when product_type = '滴滴自营' then '滴滴'
                when product_type = '花小猪自营' then '自营'
                when product_type = '三方品牌'
                and platform_name in ('鸿鹄', '宏鹄') then '三方-宏鹄'
                when product_type = '三方品牌'
                and platform_name = 'API接入' then '三方-API'
                when product_type = '三方品牌'
                and platform_name not in ('API接入', '鸿鹄', '宏鹄') then '三方-其他'
                else '其他'
            end as order_type,case
                when is_hxz_call = 1 then '小猪端'
                when is_thlm_call = 1 then '特惠联盟端'
                when is_pbd_call = 1 then 'PBD端'
                else '其他'
            end as channel_name2,case
                when product_type = '滴滴自营' then '滴滴'
                when product_type = '花小猪自营' then '自营'
                when product_type = '三方品牌' then '三方'
                else '其他'
            end as order_type2
        from
            (
                select
                    dt,
                    call_time,
                    order_id,
                    start_city_id as city_id,
                    estimate_id,
                    product_id,
                    call_car_level_id,
                    is_hxz_call,
                    is_pbd_call,
                    is_thlm_call,
                    product_type,
                    platform_name,
                    channel_name
                from
                    kflower_dw.dwd_kf_trd_unity_order_anycar_di
                where
                    dt between "${date}" and "${date2}"
                    and start_city_id in (${city_list})
                    and product_id not in (26, 0)
                    and to_date(call_time) between "${date}" and "${date2}"
            ) a
            left join (
                select
                    source_id,
                    dt,
                    order_id,
                    estimate_id,
                    product_id,
                    call_car_level_id,
                    is_compete_call,
                    is_objective_call,
                    is_platform_objective_call
                from
                    kflower_dw.dim_kf_trd_unity_order_anycar_label_di
                where
                    dt between "${date}" and "${date2}"
            ) b on a.order_id = b.order_id
            and a.estimate_id = b.estimate_id
            and a.product_id = b.product_id
            and a.call_car_level_id = b.call_car_level_id
            and a.dt = b.dt
        where
            is_compete_call = 1
    ),
    table2 as (
        select
            a.dt,
            a.source_id,
            a.order_id,
            call_time,
            is_hxz,
            is_pbd,
            is_thlm,
            city_id,
            platform_name,
            product_name_unit,
            product_type,
            a.driver_id,
            answer_dur,
            est_arrive_dis,
            is_td_answer,
            is_td_reassign,
            is_grab_after_dri_cancel,
            is_grab_after_pas_cancel,
            is_grab_after_srvc_cancel,
            is_td_finish,
            gmv_amt,
            is_td_answer_without_reassign,
            is_grab_after_dri_cancel_without_reassign,
            is_grab_after_pas_cancel_without_reassign,
            is_grab_after_srvc_cancel_without_reassign,
            is_reassign,case
                when is_hxz = 1 then '小猪端'
                when is_thlm = 1 then '特惠联盟端'
                when is_pbd = 1
                and channel_name in ('百度地图', '腾讯地图') then 'PBD端-地图'
                when is_pbd = 1
                and channel_name not in ('百度地图', '腾讯地图') then 'PBD端-其他'
                else '其他'
            end as channel_name,case
                when product_type = '滴滴自营' then '滴滴'
                when product_type = '花小猪自营' then '自营'
                when product_type = '三方品牌'
                and platform_name in ('鸿鹄', '宏鹄') then '三方-宏鹄'
                when product_type = '三方品牌'
                and platform_name = 'API接入' then '三方-API'
                when product_type = '三方品牌'
                and platform_name not in ('API接入', '鸿鹄', '宏鹄') then '三方-其他'
                else '其他'
            end as order_type,case
                when is_hxz = 1 then '小猪端'
                when is_thlm = 1 then '特惠联盟端'
                when is_pbd = 1 then 'PBD端'
                else '其他'
            end as channel_name2,case
                when product_type = '滴滴自营' then '滴滴'
                when product_type = '花小猪自营' then '自营'
                when product_type = '三方品牌' then '三方'
                else '其他'
            end as order_type2
        from
            (
                select
                    dt,
                    source_id,
                    order_id,
                    call_time,
                    is_hxz,
                    is_pbd,
                    is_thlm,
                    start_city_id as city_id,
                    platform_name,
                    product_name_unit,
                    product_type,
                    driver_id,
                    answer_dur,
                    est_arrive_dis,
                    is_td_reassign,
                    channel_name,
                    is_reassign
                from
                    kflower_dw.dwd_kf_trd_unity_order_di
                where
                    dt between "${date}" and "${date2}"
                    and start_city_id in (${city_list})
            ) a
            left join (
                select
                    dt,
                    source_id,
                    order_id,
                    is_td_answer,
                    is_grab_after_dri_cancel,
                    is_grab_after_pas_cancel,
                    is_grab_after_srvc_cancel,
                    is_td_finish,
                    gmv_amt,
                    is_td_answer_without_reassign,
                    is_grab_after_dri_cancel_without_reassign,
                    is_grab_after_pas_cancel_without_reassign,
                    is_grab_after_srvc_cancel_without_reassign
                from
                    kflower_dw.dim_kf_trd_unity_order_label_di
                where
                    dt between "${date}" and "${date2}"
            ) b on a.source_id = b.source_id
            and a.order_id = b.order_id
            and a.dt = b.dt
    ),
    order_base as (
        select
            -- coalesce(t1.dt, t2.dt) as dt,
            coalesce(t1.city_id, t2.city_id) as city_id,
            coalesce(t1.exp_group, t2.exp_group) as exp_group,
            coalesce(t1.channel_name, t2.channel_name) as channel_name,
            coalesce(t1.order_type, t2.order_type) as order_type,
            nvl(t2.exp_pid_cnt, 0) as exp_pid_cnt,
            nvl(t2.call, 0) as compete_call_cnt,
            nvl(t1.answer_cnt, 0) as answer_cnt,
            nvl(t1.grab_after_pas_cancel_cnt, 0) as grab_after_pas_cancel_cnt,
            nvl(t1.grab_after_dri_cancel_cnt, 0) as grab_after_dri_cancel_cnt,
            nvl(t1.finish_cnt, 0) as finish_cnt,
            nvl(t1.reassign_cnt, 0) as reassign_cnt,
            nvl(t1.gmv, 0) as gmv,
            nvl(t1.answer_gmv, 0) as answer_gmv,
            nvl(t1.answer_dur, 0) as answer_dur,
            nvl(t1.est_arrive_dis,0) as est_arrive_dis,
            nvl(t1.answer_cnt_without_reassign, 0) as answer_cnt_without_reassign,
            nvl(t1.grab_after_pas_cancel_cnt_without_reassign, 0) as grab_after_pas_cancel_cnt_without_reassign,
            nvl(t1.grab_after_dri_cancel_cnt_without_reassign, 0) as grab_after_dri_cancel_cnt_without_reassign,
            nvl(t1.answer_cnt_without_reassign, 0) / nvl(t2.call, 0) as answer_rate,
            nvl(t1.finish_cnt, 0) / nvl(t2.call, 0) as fin_rate,
            nvl(t1.finish_cnt, 0) / nvl(t1.answer_cnt_without_reassign, 0) as answer_fin_rate,
            nvl(t1.grab_after_dri_cancel_cnt_without_reassign, 0) / nvl(t1.answer_cnt_without_reassign, 0) as dri_cancel_rate,
            nvl(t1.grab_after_pas_cancel_cnt, 0) / nvl(t1.answer_cnt_without_reassign, 0) as pas_cancel_rate,
            nvl(t1.reassign_cnt, 0) / nvl(t1.answer_cnt_without_reassign, 0) as reassign_rate,
            nvl(t1.answer_dur, 0) / nvl(t1.answer_cnt, 0) as avg_answer_dur,
            nvl(t1.est_arrive_dis, 0) / nvl(t1.answer_cnt, 0) as avg_est_arrive_dis,
            nvl(t1.gmv, 0) / nvl(t1.finish_cnt, 0) as asp,
            nvl(t1.answer_gmv, 0) / nvl(t1.answer_cnt, 0) as answer_asp,
            nvl(t1.answer_cnt_first, 0) as answer_cnt_first
        from
            (
                select
                    -- dt,
                    city_id,
                    exp_group,
                    nvl(channel_name, '整体') as channel_name,
                    nvl(order_type, '整体') as order_type,
                    answer_cnt,
                    grab_after_pas_cancel_cnt,
                    grab_after_dri_cancel_cnt,
                    finish_cnt,
                    reassign_cnt,
                    gmv,
                    answer_gmv,
                    answer_dur,
                    est_arrive_dis,
                    answer_cnt_without_reassign,
                    grab_after_pas_cancel_cnt_without_reassign,
                    grab_after_dri_cancel_cnt_without_reassign,
                    answer_cnt_first
                from
                    (
                        select
                            -- dt,
                            city_id,
                            exp_group,
                            channel_name,
                            order_type,
                            -- count(distinct passenger_id) as exp_pid_cnt,
                            count(
                                distinct case
                                    when b.is_td_answer = 1 then b.order_id
                                end
                            ) as answer_cnt,
                            count(
                                distinct case
                                    when b.is_grab_after_pas_cancel = 1 then b.order_id
                                end
                            ) as grab_after_pas_cancel_cnt,
                            count(
                                distinct case
                                    when b.is_grab_after_dri_cancel = 1 then b.order_id
                                end
                            ) as grab_after_dri_cancel_cnt,
                            count(
                                distinct case
                                    when b.is_td_finish = 1 then b.order_id
                                end
                            ) as finish_cnt,
                            count(
                                distinct case
                                    when b.is_td_reassign = 1 then b.order_id
                                end
                            ) as reassign_cnt,
                            sum(
                                case
                                    when b.is_td_finish = 1 then b.gmv_amt
                                end
                            ) as gmv,
                            sum(
                                case
                                    when b.is_td_answer = 1 then b.gmv_amt
                                end
                            ) as answer_gmv,
                            sum(
                                case
                                    when is_td_answer = 1 then b.answer_dur
                                end
                            ) as answer_dur,
                            sum(
                                case 
                                    when is_td_answer = 1 then b.est_arrive_dis
                                end
                            ) as est_arrive_dis,
                            count(
                                distinct case
                                    when b.is_td_answer_without_reassign = 1 then b.order_id
                                end
                            ) as answer_cnt_without_reassign,
                            count(
                                distinct case
                                    when b.is_grab_after_dri_cancel_without_reassign = 1 then b.order_id
                                end
                            ) as grab_after_dri_cancel_cnt_without_reassign,
                            count(
                                distinct case
                                    when b.is_grab_after_pas_cancel_without_reassign = 1 then b.order_id
                                end
                            ) as grab_after_pas_cancel_cnt_without_reassign,
                            count(
                                distinct case
                                    when b.is_reassign = 0
                                    and b.is_td_answer = 1 then b.order_id
                                end
                            ) as answer_cnt_first
                        from
                            target a
                            inner join table2 b on a.order_id = b.order_id
                        group by
                            -- dt,
                            city_id,
                            exp_group,
                            channel_name,
                            order_type grouping sets(
                                -- (dt, city_id, exp_group),(dt, city_id, exp_group, channel_name),(dt, city_id, exp_group, order_type),(dt, city_id, exp_group, channel_name, order_type)
                                (city_id,exp_group),(city_id,exp_group, channel_name),(city_id,exp_group, order_type),(city_id,exp_group, channel_name, order_type)
                            )
                    ) t
            ) t1
            left join (
                select
                    -- dt,
                    city_id,
                    exp_group,
                    nvl(channel_name, '整体') as channel_name,
                    nvl(order_type, '整体') as order_type,
                    call,
                    exp_pid_cnt
                from
                    (
                        select
                            -- dt,
                            city_id,
                            exp_group,
                            channel_name,
                            order_type,
                            count(distinct b.order_id) as call,
                            count(distinct passenger_id) as exp_pid_cnt
                        from
                            target a
                            inner join table1 b on a.order_id = b.order_id
                        group by
                            -- dt,
                            city_id,
                            exp_group,
                            channel_name,
                            order_type grouping sets(
                                -- (dt, city_id, exp_group),(dt, city_id, exp_group, channel_name),(dt, city_id, exp_group, order_type),(dt, city_id, exp_group, channel_name, order_type)
                                (city_id,exp_group),(city_id,exp_group, channel_name),(city_id,exp_group, order_type),(city_id,exp_group, channel_name, order_type)
                            )
                    ) t
            ) t2 on t1.exp_group = t2.exp_group
            and t1.channel_name = t2.channel_name
            and t1.order_type = t2.order_type
            and t1.city_id = t2.city_id
            -- and t1.dt = t2.dt
    ),
    order_base2 as (
        select
            -- coalesce(t1.dt, t2.dt) as dt,
            coalesce(t1.city_id, t2.city_id) as city_id,
            coalesce(t1.exp_group, t2.exp_group) as exp_group,
            coalesce(t1.channel_name, t2.channel_name) as channel_name,
            coalesce(t1.order_type, t2.order_type) as order_type,
            nvl(t2.exp_pid_cnt, 0) as exp_pid_cnt,
            nvl(t2.call, 0) as compete_call_cnt,
            nvl(t1.answer_cnt, 0) as answer_cnt,
            nvl(t1.grab_after_pas_cancel_cnt, 0) as grab_after_pas_cancel_cnt,
            nvl(t1.grab_after_dri_cancel_cnt, 0) as grab_after_dri_cancel_cnt,
            nvl(t1.finish_cnt, 0) as finish_cnt,
            nvl(t1.reassign_cnt, 0) as reassign_cnt,
            nvl(t1.gmv, 0) as gmv,
            nvl(t1.answer_gmv, 0) as answer_gmv,
            nvl(t1.answer_dur, 0) as answer_dur,
            nvl(t1.est_arrive_dis, 0) as est_arrive_dis,
            nvl(t1.answer_cnt_without_reassign, 0) as answer_cnt_without_reassign,
            nvl(t1.grab_after_pas_cancel_cnt_without_reassign, 0) as grab_after_pas_cancel_cnt_without_reassign,
            nvl(t1.grab_after_dri_cancel_cnt_without_reassign, 0) as grab_after_dri_cancel_cnt_without_reassign,
            nvl(t1.answer_cnt_without_reassign, 0) / nvl(t2.call, 0) as answer_rate,
            nvl(t1.finish_cnt, 0) / nvl(t2.call, 0) as fin_rate,
            nvl(t1.finish_cnt, 0) / nvl(t1.answer_cnt_without_reassign, 0) as answer_fin_rate,
            nvl(t1.grab_after_dri_cancel_cnt_without_reassign, 0) / nvl(t1.answer_cnt_without_reassign, 0) as dri_cancel_rate,
            nvl(t1.grab_after_pas_cancel_cnt, 0) / nvl(t1.answer_cnt_without_reassign, 0) as pas_cancel_rate,
            nvl(t1.reassign_cnt, 0) / nvl(t1.answer_cnt_without_reassign, 0) as reassign_rate,
            nvl(t1.answer_dur, 0) / nvl(t1.answer_cnt, 0) as avg_answer_dur,
            nvl(t1.est_arrive_dis, 0) / nvl(t1.answer_cnt, 0) as avg_est_arrive_dis,
            nvl(t1.gmv, 0) / nvl(t1.finish_cnt, 0) as asp,
            nvl(t1.answer_gmv, 0) / nvl(t1.answer_cnt, 0) as answer_asp,
            nvl(t1.answer_cnt_first, 0) as answer_cnt_first
        from
            (
                select
                    -- dt,
                    city_id,
                    exp_group,
                    nvl(channel_name2, '整体') as channel_name,
                    nvl(order_type2, '整体') as order_type,
                    answer_cnt,
                    grab_after_pas_cancel_cnt,
                    grab_after_dri_cancel_cnt,
                    finish_cnt,
                    reassign_cnt,
                    gmv,
                    answer_gmv,
                    answer_dur,
                    est_arrive_dis,
                    answer_cnt_without_reassign,
                    grab_after_pas_cancel_cnt_without_reassign,
                    grab_after_dri_cancel_cnt_without_reassign,
                    answer_cnt_first
                from
                    (
                        select
                            -- dt,
                            city_id,
                            exp_group,
                            channel_name2,
                            order_type2,
                            count(
                                distinct case
                                    when b.is_td_answer = 1 then b.order_id
                                end
                            ) as answer_cnt,
                            count(
                                distinct case
                                    when b.is_grab_after_pas_cancel = 1 then b.order_id
                                end
                            ) as grab_after_pas_cancel_cnt,
                            count(
                                distinct case
                                    when b.is_grab_after_dri_cancel = 1 then b.order_id
                                end
                            ) as grab_after_dri_cancel_cnt,
                            count(
                                distinct case
                                    when b.is_td_finish = 1 then b.order_id
                                end
                            ) as finish_cnt,
                            count(
                                distinct case
                                    when b.is_td_reassign = 1 then b.order_id
                                end
                            ) as reassign_cnt,
                            sum(
                                case
                                    when b.is_td_finish = 1 then b.gmv_amt
                                end
                            ) as gmv,
                            sum(
                                case
                                    when b.is_td_answer = 1 then b.gmv_amt
                                end
                            ) as answer_gmv,
                            sum(
                                case
                                    when is_td_answer = 1 then b.answer_dur
                                end
                            ) as answer_dur,
                            sum(
                                case
                                    when is_td_answer = 1 then b.est_arrive_dis
                                end
                            ) as est_arrive_dis,
                            count(
                                distinct case
                                    when b.is_td_answer_without_reassign = 1 then b.order_id
                                end
                            ) as answer_cnt_without_reassign,
                            count(
                                distinct case
                                    when b.is_grab_after_dri_cancel_without_reassign = 1 then b.order_id
                                end
                            ) as grab_after_dri_cancel_cnt_without_reassign,
                            count(
                                distinct case
                                    when b.is_grab_after_pas_cancel_without_reassign = 1 then b.order_id
                                end
                            ) as grab_after_pas_cancel_cnt_without_reassign,
                            count(
                                distinct case
                                    when b.is_reassign = 0
                                    and b.is_td_answer = 1 then b.order_id
                                end
                            ) as answer_cnt_first
                        from
                            target a
                            inner join table2 b on a.order_id = b.order_id
                        group by
                            -- dt,
                            city_id,
                            exp_group,
                            channel_name2,
                            order_type2 grouping sets(
                                -- (dt, city_id, exp_group),(dt, city_id, exp_group, channel_name2),(dt, city_id, exp_group, order_type2),(dt, city_id, exp_group, channel_name2, order_type2)
                                (city_id,exp_group),(city_id,exp_group, channel_name),(city_id,exp_group, order_type),(city_id,exp_group, channel_name, order_type)
                            )
                    ) t
            ) t1 full
            join (
                select
                    -- dt,
                    city_id,
                    exp_group,
                    nvl(channel_name2, '整体') as channel_name,
                    nvl(order_type2, '整体') as order_type,
                    call,
                    exp_pid_cnt
                from
                    (
                        select
                            -- dt,
                            city_id,
                            exp_group,
                            channel_name2,
                            order_type2,
                            count(distinct b.order_id) as call,
                            count(distinct passenger_id) as exp_pid_cnt
                        from
                            target a
                            inner join table1 b on a.order_id = b.order_id
                        group by
                            -- dt,
                            city_id,
                            exp_group,
                            channel_name2,
                            order_type2 grouping sets(
                                -- (dt, city_id, exp_group),(dt, city_id, exp_group, channel_name2),(dt, city_id, exp_group, order_type2),(dt, city_id, exp_group, channel_name2, order_type2)
                                (city_id, exp_group),(city_id,exp_group, channel_name),(city_id,exp_group, order_type),(city_id,exp_group, channel_name, order_type)
                            )
                    ) t
            ) t2 on t1.exp_group = t2.exp_group
            and t1.channel_name = t2.channel_name
            and t1.order_type = t2.order_type
            and t1.city_id = t2.city_id
            -- and t1.dt = t2.dt
    )
        select
            *
        from
            order_base
        where
            channel_name <> 'PBD-其他'
            and order_type <> '其他'
        union all
        select
            *
        from
            order_base2
        where
            (
                channel_name = 'PBD端'
                or order_type = '三方'
            )
            and channel_name <> 'PBD-其他'
            and order_type <> '其他'
```
