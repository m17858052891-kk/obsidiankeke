
# 网顺融合需求之PK改造——加权系数测算

# 1、顺风车加权系数

由于顺风车司机没有历史履约，PK模型的特征会采用填充的均值，原始PK打分代表的是网约车的平均履约情况

因此，设定简单的策略逻辑，使顺风车过渡到和网约车共同参与PK决策。顺风车的倾斜前PK打分逻辑：

- 顺风车的倾斜前PK打分 = 顺风车的模型打分 x 折扣系数

- 折扣系数 = 0.53 （顺风车的司乘履约率 / 网约车的司乘履约率 =  0.435 / 0.828 =  0.53）

```PlainText
select
    wyc_finish_cnt / (wyc_finish_cnt + wyc_cancel_cnt) as wyc_finish_rate,
    sfc_finish_cnt / (sfc_finish_cnt + sfc_cancel_cnt) as sfc_finish_rate
from
    (
        select
            count(distinct case when product_id not in (5075,5135,5149,5150) and is_td_finish = 1 then order_id end) as wyc_finish_cnt,
            count(distinct case when product_id not in (5075,5135,5149,5150) and (is_td_reassign = 1 or is_td_cancel = 1) then order_id end) as wyc_cancel_cnt,
            count(distinct case when product_id in (5075,5135,5149,5150) and is_td_finish = 1 then order_id end) as sfc_finish_cnt,
            count(distinct case when product_id in (5075,5135,5149,5150) and (is_td_reassign = 1 or is_td_cancel = 1) then order_id end) as sfc_cancel_cnt
        from
            kflower_dw.dwd_kf_trd_order_base_di
        where
            dt between '2026-01-19' and '2026-01-25'
            and product_1level <> 4
            and is_td_answer = 1
    ) t;
```

# 2、目标人群倾斜分

运营方给出需要倾斜的目标人群标签，对于目标人群的发单，平台会对参与PK的顺风车司机赋予相应的加权分

倾斜人群标签逻辑：

- 顺风车忠实用户：近30天只有顺风车发单，没有网约车发单

- 顺风车高发单意愿用户：近30天既有顺风车发单也有网约车发单，顺风车发单订单数占比≥50%

- 顺风车高GMV份额用户：近30天既有顺风车发单也有网约车发单，顺风车完单GMV份额≥50%

顺风车的倾斜后PK打分逻辑：

- 顺风车的倾斜后PK打分 = 顺风车的倾斜前PK打分 + 倾斜分（>0）

- 三类人群的顺风车目标PK胜率分别为90%、70%、50%

- 近似用PK打分的分位数（正序）90%、70%、50%作为目标PK打分

| 目标人群 <br> | 平均PK打分 <br> | 目标PK打分 <br> | 倾斜分 <br> |
| --- | --- | --- | --- |
| 顺风车忠实用户（is_sfc_fans_user） <br> | 0.6167 <br> | 0.8919 <br> | 0.2752 <br> |
| 顺风车高发单意愿用户（is_sfc_high_call_willing_user） <br> | 0.6165 <br> | 0.8047 <br> | 0.1882 <br> |
| 顺风车高GMV份额用户（is_sfc_high_gmv_user） <br> | 0.6364 <br> | 0.7009 <br> | 0.0645 <br> |

```PlainText
select
    avg(case when is_sfc_fans_user = 1 then pkvalue end) as is_sfc_fans_user_pkvalue,
    avg(case when is_sfc_high_call_willing_user = 1 then pkvalue end) as is_sfc_high_call_willing_user_pkvalue,
    avg(case when is_sfc_high_gmv_user = 1 then pkvalue end) as is_sfc_high_gmv_user_pkvalue,
    percentile(pkvalue, 0.9) as pkvalue_90,
    percentile(pkvalue, 0.7) as pkvalue_70, 
    percentile(pkvalue, 0.5) as pkvalue_50
from
    (
        select
            order_id, roundnum, driver_id, pkvalue, passenger_id
        from
            kflower_strategy.kflower_dusepk_data
        where
            dt between '2026-01-19' and '2026-01-25'
    ) a
    left join
    (
        select
            passenger_id,
            max(is_sfc_fans_user) as is_sfc_fans_user,
            max(is_sfc_high_call_willing_user) as is_sfc_high_call_willing_user,
            max(is_sfc_high_gmv_user) as is_sfc_high_gmv_user
        from
            kflower_dw.dm_kf_pas_tag_system_df
        where
            dt between '2026-01-19' and '2026-01-25'
        group by
            passenger_id
    ) b on a.passenger_id = b.passenger_id;
```
