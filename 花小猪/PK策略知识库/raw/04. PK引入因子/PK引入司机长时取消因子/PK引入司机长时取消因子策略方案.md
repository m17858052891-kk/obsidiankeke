# 1、背景

由产品侧分析，发现应答长时间后被司机取消的订单占比较高，且这部分取消对乘客留存伤害最重

由平台侧推动，在分单和PK考核中加重对司机长时取消行为的惩罚，通过可解释透传机制降低此类行为的发生频率

# 2、数据分析

对于所有订单改派链路$$i$$，统计**累计司机取消时长**$$t_i$$的分布和**流转完单**$$y_i$$的比例

例如：订单改派链路$$i:O_1 \rightarrow O_2 \rightarrow O_3$$，则$$t_i=t_{1}+t_{2}$$，其中$$t_1$$和$$t_2$$分别代表订单$$O_1$$和$$O_2$$各自从应答到司机取消的时长

```PlainText
with order_f as
(
    select
        order_id,
        answer_time,
        cancel_time
    from
        kflower_dw.dwd_kf_trd_order_base_di
    where
        dt between date_sub('2025-03-10', 13) and '2025-03-10'
        and product_1level <> 4
        and source_type <> 2
        and is_td_reassign = 1
),

order_t as
(
    select
        order_id,
        max(answer_time) as answer_time,
        max(cancel_time) as cancel_time,
        max(is_td_reassign) as is_reassign,
        max(is_td_finish) as is_finish,
        max(reassign_origin_order_id) as reassign_origin_order_id
    from
        kflower_dw.dwd_kf_trd_order_base_di
    where
        dt between date_sub('2025-03-10', 13) and '2025-03-10'
        and product_1level <> 4
        and source_type = 2
    group by
        order_id
),

order_f_t as
(
    select
        f.order_id as f_order_id,
        f.answer_time as f_answer_time,
        f.cancel_time as f_cancel_time,
        t.answer_time as t_answer_time,
        t.cancel_time as t_cancel_time,
        t.is_reassign as t_is_reassign,
        t.is_finish as t_is_finish
    from
        order_f f
        left join order_t t on f.order_id = t.reassign_origin_order_id
),

order_chain as
(
    select
        f_order_id,
        count(1) as reassign_times,
        max(case when t_is_finish is not null then t_is_finish else 0 end) as is_finish,
        avg((unix_timestamp(f_cancel_time) - unix_timestamp(f_answer_time)) / 60.0) + sum(case when t_is_reassign = 1 then (unix_timestamp(t_cancel_time) - unix_timestamp(t_answer_time)) / 60.0 else 0 end) as total_cancel_dur
    from
        order_f_t
    group by
        f_order_id
)


select
    dur_bin,
    count(1) / sum(count(1)) over() as proportion,
    sum(is_finish) / count(1) as finish_proportion
from
    (
        select
            case
                when total_cancel_dur <= 1 / 12.0 then '01_[0,5s]'
                when total_cancel_dur <= 2 / 12.0 then '02_(5s,10s]'
                when total_cancel_dur <= 3 / 12.0 then '03_(10,15s]'
                when total_cancel_dur <= 4 / 12.0 then '04_(15s,20s]'
                when total_cancel_dur <= 5 / 12.0 then '05_(20s,25s]'
                when total_cancel_dur <= 6 / 12.0 then '06_(25s,30s]'
                when total_cancel_dur <= 8 / 12.0 then '07_(30s,40s]'
                when total_cancel_dur <= 10 / 12.0 then '08_(40s,50s]'
                when total_cancel_dur <= 1 then '09_(50s,1min]'
                when total_cancel_dur <= 1 + 1 / 3.0 then '10_(1min,1min20s]'
                when total_cancel_dur <= 1 + 2 / 3.0 then '11_(1min20s,1min40s]'
                when total_cancel_dur <= 2 then '12_(1min40s,2min]'
                when total_cancel_dur <= 2.5 then '13_(2min,2min30s]'
                when total_cancel_dur <= 3 then '14_(2min30s,3min]'
                when total_cancel_dur <= 4 then '15_(3min,4min]'
                when total_cancel_dur <= 6 then '16_(4min,6min]'
                when total_cancel_dur <= 10 then '17_(6min,10min]'
                else '18_(10min,+)'
            end as dur_bin,
            is_finish
        from
            order_chain
    ) t
group by
    dur_bin
order by
    dur_bin
;
```

| 累计司机取消时长 <br> | 比例 <br> | 流转完单比例 <br> |
| :---: | :---: | :---: |
| \[0, 5s\] <br> | 2.36% <br> | 59.76% <br> |
| (5s, 10s\] <br> | 26.39% <br> | 60.89% <br> |
| (10, 15s\] <br> | 20.36% <br> | 61.88% <br> |
| (15s, 20s\] <br> | 10.75% <br> | 63.33% <br> |
| (20s, 25s\] <br> | 6.68% <br> | 63.69% <br> |
| (25s, 30s\] <br> | 4.61% <br> | 64.46% <br> |
| (30s, 40s\] <br> | 5.88% <br> | 64.35% <br> |
| (40s, 50s\] <br> | 3.53% <br> | 64.57% <br> |
| (50s, 1m\] <br> | 2.44% <br> | 64.18% <br> |
| (1m, 1m20s\] <br> | 3.18% <br> | 63.99% <br> |
| (1m20s, 1m40s\] <br> | 2.09% <br> | 63.46% <br> |
| (1m40s, 2m\] <br> | 1.49% <br> | 62.96% <br> |
| (2m, 2m30s\] <br> | 1.64% <br> | 62.04% <br> |
| (2m30s, 3m\] <br> | 1.21% <br> | 61.36% <br> |
| (3m, 4m\] <br> | 1.70% <br> | 59.95% <br> |
| (4m, 6m\] <br> | 2.00% <br> | 57.12% <br> |
| (6m, 10m\] <br> | 1.74% <br> | 51.24% <br> |
| (10m, +) <br> | 1.94% <br> | 23.21% <br> |

# 3、特征和模型

## 3.1、司机取消订单的流转完单率

对于所有**订单改派链路**$$i$$，利用LR建模**是否流转完单**$$y_i$$与改派链路上**累计司机取消时长**$$t_i$$的关系

模型输出**订单流转完单率**$$p_i$$，用于表征乘客遇到司机取消并改派后仍愿意等待的耐心程度

$$p_i=F(t_i)=1/[1+\exp[{-(wt_i+b)}]$$

| 司机取消时长 <br> | 流转完单率 <br> | 加权系数 <br> |
| --- | --- | --- |
| 0.5 <br> | 0.654 <br> | 1.000 <br> |
| 1 <br> | 0.645 <br> | 1.015 <br> |
| 1.5 <br> | 0.635 <br> | 1.031 <br> |
| 2 <br> | 0.625 <br> | 1.047 <br> |
| 2.5 <br> | 0.615 <br> | 1.064 <br> |
| 3 <br> | 0.605 <br> | 1.082 <br> |
| 3.5 <br> | 0.594 <br> | 1.100 <br> |
| 4 <br> | 0.584 <br> | 1.120 <br> |
| 4.5 <br> | 0.574 <br> | 1.140 <br> |
| 5 <br> | 0.563 <br> | 1.161 <br> |
| 6 <br> | 0.542 <br> | 1.206 <br> |
| 7 <br> | 0.521 <br> | 1.255 <br> |
| 8 <br> | 0.500 <br> | 1.308 <br> |
| 9 <br> | 0.479 <br> | 1.366 <br> |
| 10 <br> | 0.458 <br> | 1.430 <br> |
| 11 <br> | 0.437 <br> | 1.498 <br> |
| 12 <br> | 0.416 <br> | 1.573 <br> |
| 13 <br> | 0.395 <br> | 1.655 <br> |
| 14 <br> | 0.375 <br> | 1.744 <br> |
| 15 <br> | 0.355 <br> | 1.840 <br> |
| 16 <br> | 0.336 <br> | 1.945 <br> |
| &gt;16 <br> | &lt;0.336 <br> | 2.000 <br> |

## 3.2、司机长时取消数加权特征

在统计司机历史取消数$$x$$时，对每一次取消$$x_i$$，需判断是否为**需要加权的长时取消情形**$$D$$，该逻辑前置依赖于工程建设的乘客是否迟到等特征

若判断为是，则根据该单的取消时长$$t_i$$计算**流转完单率**$$p_i$$，得到**加权系数**$$p_m/p_i$$，其中$$p_m=F(t_m)$$代表合理司机取消时长$$t_m$$的流转完单率

若判断为不是，则正常参与求和

$$x = \sum_i  [ \mathbb{I}_{\{x_i \in D\}} x_i p_i /p_m + (1 - \mathbb{I}_{\{x_i \in D\}}) x_i  ]$$

## 3.3、司机长时取消数加权的PK模型

利用司机长时取消数加权特征，替换原先的司机取消数特征，重复PK模型的建模链路
