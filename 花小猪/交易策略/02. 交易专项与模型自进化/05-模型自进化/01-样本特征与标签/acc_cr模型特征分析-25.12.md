---
title: "acc_cr模型特征分析-25.12"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2206187595016
cssclasses: ["strategy-body-note"]
---

# acc_cr模型特征分析-25.12

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2206187595016)

先核对呼叫样本口径，再看补勾、预分单、升舱和目的地修改怎样落表；样本与特征差异分别保留。

**阅读定位**　[[#1 呼叫样本|1 呼叫样本]] · [[#2 特征分析|2 特征分析]] · [[#3 补充特征|3 补充特征]]

## 1 呼叫样本

### 1.1 当前样本处理问题

1. 去除未应答、乘客前取消、取消时间<30s的订单，考虑30s以内，是非乘客主观意愿取消，可能写错终点、勾错车型；但是CR建模需要考虑司乘取消，应该删除此限制

2. 剔除了等待应答页呼叫

3. 由于取数口径问题，不包含等待应答页补勾、升舱、预分单的完单

与看板对比CR GAP：看12-15日的口径差异，CR模型的CR低5pp；修正口径与看板差距0.02pp

| | 去重冒泡数 | 呼叫数 | 完单数 | CR | 取数sql |
| --- | --- | --- | --- | --- | --- |
| [cr模型](https://studio.data.didichuxing.com/?projectId=1143&taskId=49981241) | 6064490 | 4246615 | 3168415 | 74.61% | ```PlainText<br>select <br>    count(distinct trace_id) as call_cnt,<br>    sum(is_td_finish) as finish_cnt,<br>    sum(is_td_finish)/count(distinct trace_id) as cr<br>from <br>    kflower_strategy.cr_model_feature_generate_base<br>where <br>    dt = '2025-12-15'``` |
| [看板](http://kfdata.didichuxing.com/?menuId=i37EqOqMb) | 6064491 | 4313744 | 3446253 | 79.89% | |
| 修正口径-不含改 | 6064490 | 4300167 | 3436408 | 79.91% | ```SQL<br>select <br>    count(distinct trace_id) as bubble_cnt,<br>    count(distinct case when is_td_call = 1 then trace_id end ) as call_cnt,<br>    count(distinct case when is_td_finish = 1 then trace_id end ) as finish_cnt<br>from <br>    (<br>        select <br>            distinct<br>            trace_id,<br>            product_id,<br>            level_type<br>        from <br>            kflower_strategy.pltf_union_stg_v3_offline_simulation_cp_info<br>        where <br>            dt = '${BIZ_DATE_LINE}'<br>    ) a<br>    left join <br>    (<br>        select <br>            bubble_trace_id,<br>            product_id,<br>            level_type,<br>            max(is_td_call) as is_td_call,<br>            max(is_td_answer) as is_td_answer,<br>            max(is_td_cancel) as is_td_cancel,<br>            max(is_td_finish) as is_td_finish<br>        from <br>            kflower_dw.dwd_kf_trd_order_anycar_di<br>        where <br>            dt between '${BIZ_DATE_LINE}' and date_add('${BIZ_DATE_LINE}',1)<br>            -- and is_td_call = 1<br>            -- 考虑是否要加改派<br>            -- and   source_type <> 2<br>            and call_time IS NOT NULL<br>            and call_time <> '0000-00-00 00:00:00'<br>            and order_id > 0<br>            and product_1level in (1, 2, 999)<br>        group by <br>            bubble_trace_id,<br>            product_id,<br>            level_type<br>    ) b on a.trace_id = b.bubble_trace_id and a.product_id = b.product_id and a.level_type = b.level_type<br>;``` |

### 1.2 口径确认

有以下场景，用户第一次呼叫的品类与最终呼叫品类可能不同：**等待应答页补勾、预分单、修改目的地、升舱、改**派。

以下为几种场景的冒泡表、订单表落表情况：

- 冒泡表：kflower_dw.dwd_kf_trd_bubble_base_all_di

- 订单表：kflower_dw.dwd_kf_trd_order_anycar_di

#### 1.2.1 等待应答页补勾落表

- 结论：等待应答页补勾，冒泡表与呼叫表用product_id、level_type关联即可

	- 冒泡表：trace_id变化，estimate_id变化

	- 订单表：order_id不变，bubble_trace_id不变，estimate_id为补勾的estimate_id

等待应答页补勾场景，冒泡、订单表落表，详细取数验证过程，日期2025-12-15
【订单表】

- 订单表order_id-不变：包含等待应答页呼叫 vs 剔除等待应答页呼叫，order_id数相同，均为4455846，说明order_id不变

```PlainText
select 
    count(distinct order_id)
from 
    kflower_dw.dwd_kf_trd_order_anycar_di
where 
    dt = '2025-12-15'
    -- and is_td_call = 1
    -- 考虑是否要加改派
    and   source_type <> 2
    and call_time IS NOT NULL
    and call_time <> '0000-00-00 00:00:00'
    and order_id > 0
    and product_1level in (1, 2, 999)
    and is_td_call = 1
```

```PlainText
select 
    count(distinct order_id)
from 
    kflower_dw.dwd_kf_trd_order_anycar_di
where 
    dt = '2025-12-15'
    -- and is_td_call = 1
    -- 考虑是否要加改派
    and   source_type <> 2
    and call_time IS NOT NULL
    and call_time <> '0000-00-00 00:00:00'
    and order_id > 0
    and product_1level in (1, 2, 999)
    and is_td_call = 1
    and is_wait_call = 0
```

- 订单表bubble_trace_id-不变：distinct order_id,bubble_trace_id vs distinct order_id的样本数量相同（4823764），说明一个order_id对应唯一的bubble_trace_id

> [!example]- PlainText 实现细节（22 行）
> ```PlainText
> with order_info as (
>     select 
>         distinct 
>         order_id,
>         bubble_trace_id
>     from 
>         kflower_dw.dwd_kf_trd_order_anycar_di
>     where 
>         dt = '2025-12-15'
>         -- and source_type <> 2 -- 非改派订单
>         and call_time IS NOT NULL
>         and call_time <> '0000-00-00 00:00:00'
>         and order_id > 0
>         and product_1level in (1, 2, 999)
>         and is_td_call = 1
>         -- and is_wait_call = 1  -- 等待应答页呼叫        
> )
>
> select 
>     count(*)
> from 
>     order_info
> ```


- 订单表estimate_id：对应冒泡表等待应答页补勾的estimate_id

【冒泡表】

- 冒泡表trace_id-变化：取等待应答页补勾的order_id，与冒泡表按照estimate_id的条件left join，发现补勾的品类，trace_id发生了变化

> [!example]- PlainText 实现细节（51 行）
> ```PlainText
> with order_info as (
>     select 
>         order_id,
>         bubble_trace_id,
>         estimate_id,
>         call_time,
>         append_call_time,
>         update_time,
>         is_wait_call,
>         is_td_call,
>         is_td_answer,
>         is_td_charge,
>         is_td_finish,
>         is_td_cancel
>     from 
>         kflower_dw.dwd_kf_trd_order_anycar_di
>     where 
>         dt = '2025-12-15'
>         -- and source_type <> 2 -- 非改派订单
>         and call_time IS NOT NULL
>         and call_time <> '0000-00-00 00:00:00'
>         and order_id > 0
>         and product_1level in (1, 2, 999)
>         and is_td_call = 1
>         and order_id = '140737702051533'
> )
>
> select 
>     a.*,
>     b.trace_id,
>     b.estimate_id,
>     bubble_time,
>     is_from_waiting_response
> from 
>     order_info a 
>     left join (
>         select 
>             trace_id,
>             estimate_id,
>             bubble_time,
>             is_from_waiting_response
>         from 
>             kflower_dw.dwd_kf_trd_bubble_base_all_di
>         where 
>             dt = '2025-12-15'
>             and product_1level <> 4	-- 去掉 PBD 端
>             and is_anycar_form = 1	-- 新表单
>             and order_type = 0	-- 实时单
>             -- and is_from_waiting_response <> 1
>             -- and trace_id = '9bf44a06693f0ac65223bc2610800403'
>     ) b on a.estimate_id = b.estimate_id
> ```


[等待应答页补勾冒泡trace.xlsx](1d535568bfcb0b37-等待应答页补勾冒泡trace.xlsx)

- 冒泡表estimate_id-变化：对比初次冒泡、等待应答页补勾，product_id、level_type相同时，estimate_id变化；等待应答页补勾的trace不会记录第一次发单的estimate_id，只会记录补勾的

> [!example]- PlainText 实现细节（57 行）
> ```PlainText
> with order_info as (
>     select 
>         order_id,
>         bubble_trace_id,
>         estimate_id,
>         product_id,
>         level_type,
>         call_time,
>         append_call_time,
>         update_time,
>         is_wait_call,
>         is_td_call,
>         is_td_answer,
>         is_td_charge,
>         is_td_finish,
>         is_td_cancel
>     from 
>         kflower_dw.dwd_kf_trd_order_anycar_di
>     where 
>         dt = '2025-12-15'
>         -- and source_type <> 2 -- 非改派订单
>         and call_time IS NOT NULL
>         and call_time <> '0000-00-00 00:00:00'
>         and order_id > 0
>         and product_1level in (1, 2, 999)
>         and is_td_call = 1
>         and order_id = '140737702051533'
> )
>
> select 
>     b.*,
>     a.trace_id,
>     a.estimate_id as bubble_id,
>     a.product_id,
>     a.level_type,
>     bubble_time,
>     is_from_waiting_response
> from 
>     (
>         select 
>             trace_id,
>             estimate_id,
>             product_id,
>             level_type,
>             bubble_time,
>             is_from_waiting_response
>         from 
>             kflower_dw.dwd_kf_trd_bubble_base_all_di
>         where 
>             dt = '2025-12-15'
>             and product_1level <> 4	-- 去掉 PBD 端
>             and is_anycar_form = 1	-- 新表单
>             and order_type = 0	-- 实时单
>             -- and is_from_waiting_response <> 1
>             and trace_id in ('9bf44a06693f0ac65223bc2610800403','824a532e693f0acc5223bc2610990403')
>     ) a 
>     left join order_info b on a.estimate_id = b.estimate_id
> ```


[冒泡表初次冒泡对比等待应答页补勾.xlsx](04c6258b749c6728-冒泡表初次冒泡对比等待应答页补勾.xlsx)

【完单label问题】

- 等待应答页补勾完单，会记录在补勾对应的estimate_id中；也就是说使用去重冒泡的最后一个冒泡，是无法关联到这个商家的完单label的

> [!example]- PlainText 实现细节（51 行）
> ```PlainText
> with order_info as (
>     select 
>         order_id,
>         bubble_trace_id,
>         estimate_id,
>         call_time,
>         append_call_time,
>         update_time,
>         is_wait_call,
>         is_td_call,
>         is_td_answer,
>         is_td_charge,
>         is_td_finish,
>         is_td_cancel
>     from 
>         kflower_dw.dwd_kf_trd_order_anycar_di
>     where 
>         dt = '2025-12-15'
>         -- and source_type <> 2 -- 非改派订单
>         and call_time IS NOT NULL
>         and call_time <> '0000-00-00 00:00:00'
>         and order_id > 0
>         and product_1level in (1, 2, 999)
>         and is_td_call = 1
>         and order_id = '140737701800705'
> )
>
> select 
>     a.*,
>     b.trace_id,
>     b.estimate_id,
>     bubble_time,
>     is_from_waiting_response
> from 
>     order_info a 
>     left join (
>         select 
>             trace_id,
>             estimate_id,
>             bubble_time,
>             is_from_waiting_response
>         from 
>             kflower_dw.dwd_kf_trd_bubble_base_all_di
>         where 
>             dt = '2025-12-15'
>             and product_1level <> 4	-- 去掉 PBD 端
>             and is_anycar_form = 1	-- 新表单
>             and order_type = 0	-- 实时单
>             -- and is_from_waiting_response <> 1
>             -- and trace_id = '9bf44a06693f0ac65223bc2610800403'
>     ) b on a.estimate_id = b.estimate_id
> ```


| 数据表 | 车型 <br> | 冒泡页 <br> · 车型A✅ <br> | 冒泡页 <br> · 车型B❌ <br> | 等待应答页补勾 <br> · 车型A✅ <br> | 等待应答页补勾 <br> · 车型B✅ <br> |
| --- | --- | --- | --- | --- | --- |
| 冒泡表 <br> | trace_id <br> | t1 <br> | t1 <br> | / <br> | t2 <br> |
| 冒泡表 <br> | estimate_id <br> | eA1 <br> | eB1 <br> | / <br> | eB2 <br> |
| 冒泡表 <br> | is_from_waiting_response <br> | 0 <br> | 0 <br> | / <br> | 1 <br> |
| 订单表 <br> | order_id <br> | o1 <br> | / <br> | / <br> | o1 <br> |
| 订单表 <br> | bubble_trace_id <br> | t1 <br> | / <br> | / <br> | t1 <br> |
| 订单表 <br> | estimate_id <br> | eA1 <br> | / <br> | / <br> | eB2 <br> |
| 订单表 <br> | is_wait_call <br> | 0 <br> | / <br> | / <br> | 1 <br> |


#### 1.2.2 预分单/升舱落表

结论：预分单/升舱占比上呼叫14%，完单占比1%；类似系统帮忙在等待应答页补勾了

- 冒泡表：trace_id变化，estimate_id变化

- 订单表：order_id不变，bubble_trace_id不变，estimate_id为预分单的estimate_id

预分单场景排查细节
【订单表】dwd_kf_trd_order_anycar_di

- 预分单flag：is_pre_dispatch = 1

- order_id：不变

- bubble_trace_id：改变

- estimate_id：变化

- 完单flag：记在预分单的estimate_id中

> [!example]- PlainText 实现细节（58 行）
> ```PlainText
> with order_info as (
>     select 
>         order_id,
>         bubble_trace_id,
>         estimate_id,
>         product_id,
>         level_type,
>         call_time,
>         append_call_time,
>         update_time,
>         is_pre_dispatch,
>         is_wait_call,
>         is_td_call,
>         is_td_answer,
>         is_td_charge,
>         is_td_finish,
>         is_td_cancel
>     from 
>         kflower_dw.dwd_kf_trd_order_anycar_di
>     where 
>         dt = '2025-12-15'
>         -- and source_type <> 2 -- 非改派订单
>         and call_time IS NOT NULL
>         and call_time <> '0000-00-00 00:00:00'
>         and order_id > 0
>         and product_1level in (1, 2, 999)
>         and is_td_call = 1
>         and order_id = '140737701878821'
> )
>
> select 
>     b.*,
>     a.trace_id,
>     a.estimate_id as bubble_id,
>     a.product_id,
>     a.level_type,
>     bubble_time,
>     is_from_waiting_response
> from 
>     (
>         select 
>             trace_id,
>             estimate_id,
>             product_id,
>             level_type,
>             bubble_time,
>             is_from_waiting_response
>         from 
>             kflower_dw.dwd_kf_trd_bubble_base_all_di
>         where 
>             dt = '2025-12-15'
>             and product_1level <> 4	-- 去掉 PBD 端
>             and is_anycar_form = 1	-- 新表单
>             and order_type = 0	-- 实时单
>             -- and is_from_waiting_response <> 1
>             and trace_id in ('fa53d7a2693eec7c9b3c4f0f35398ee5','64a8f005693eec9c967bf18ebfa74280')
>     ) a 
>     left join order_info b on a.estimate_id = b.estimate_id
> ```


[预分单订单冒泡表呼叫表.xlsx](cddd39f07a3e74da-预分单订单冒泡表呼叫表.xlsx)

升舱场景排查细节
```PlainText
select 
    order_id 
from 
    kflower_dw.dwm_kf_trd_order_index_di
where 
    dt = '2025-12-15'
    and is_upcabin_ans = 1
limit 10
```

> [!example]- PlainText 实现细节（57 行）
> ```PlainText
> select 
>     b.*,
>     a.trace_id,
>     a.estimate_id as bubble_id,
>     a.product_id,
>     a.level_type,
>     bubble_time,
>     is_from_waiting_response
> from 
>     (
>         select 
>             trace_id,
>             estimate_id,
>             product_id,
>             level_type,
>             bubble_time,
>             is_from_waiting_response
>         from 
>             kflower_dw.dwd_kf_trd_bubble_base_all_di
>         where 
>             dt = '2025-12-15'
>             and product_1level <> 4	-- 去掉 PBD 端
>             and is_anycar_form = 1	-- 新表单
>             and order_type = 0	-- 实时单
>             -- and is_from_waiting_response <> 1
>             and trace_id in ('6f65f64b693f42aeadbbff70d3952f93','d0b953b3693f42f7968d0755731df913')
>     ) a 
>     left join (
>         select 
>             order_id,
>             bubble_trace_id,
>             estimate_id,
>             product_id,
>             level_type,
>             call_time,
>             append_call_time,
>             update_time,
>             -- is_update_dest,
>             is_pre_dispatch,
>             is_wait_call,
>             is_td_call,
>             is_td_answer,
>             is_td_charge,
>             is_td_finish,
>             is_td_cancel
>         from 
>             kflower_dw.dwd_kf_trd_order_anycar_di
>         where 
>             dt = '2025-12-15'
>             -- and source_type <> 2 -- 非改派订单
>             and call_time IS NOT NULL
>             and call_time <> '0000-00-00 00:00:00'
>             and order_id > 0
>             and product_1level in (1, 2, 999)
>             and is_td_call = 1
>             -- and order_id = '140737702386370'
>     ) b on a.estimate_id = b.estimate_id
> ```


[升舱订单冒泡表呼叫表.xlsx](821465b4356576a6-升舱订单冒泡表呼叫表.xlsx)

| 数据表 | 车型 <br> | 冒泡页 <br> · 车型A✅ <br> | 冒泡页 <br> · 车型B❌ <br> | 预分单 <br> · 车型A✅ <br> | 预分单 <br> · 车型B✅ <br> |
| --- | --- | --- | --- | --- | --- |
| 冒泡表 <br> | trace_id <br> | t1 <br> | t1 <br> | / <br> | t2 <br> |
| 冒泡表 <br> | estimate_id <br> | eA1 <br> | eB1 <br> | / <br> | eB2 <br> |
| 冒泡表 <br> | is_from_waiting_response <br> | 0 <br> | 0 <br> | / <br> | 1 <br> |
| 订单表 <br> | order_id <br> | o1 <br> | / <br> | / <br> | o1 <br> |
| 订单表 <br> | bubble_trace_id <br> | t1 <br> | / <br> | / <br> | t1 <br> |
| 订单表 <br> | estimate_id <br> | eA1 <br> | / <br> | / <br> | eB2 <br> |
| 订单表 <br> | is_pre_dispatch <br> | 0 <br> | / <br> | / <br> | 1 <br> |


#### 1.2.3 修改目的地场景落表

结论：由于乘客上车开始计费后才能修改目的地，因此不需要额外处理

- 修改目的地呼叫占比：1%

- 订单标识：is_update_dest=1；其余落表字段无区别

修改目的地排查过程，日期2025-12-15
【订单表】

> [!example]- PlainText 实现细节（56 行）
> ```PlainText
> select 
>     b.*,
>     a.trace_id,
>     a.estimate_id as bubble_id,
>     a.product_id,
>     a.level_type,
>     bubble_time,
>     is_from_waiting_response
> from 
>     (
>         select 
>             trace_id,
>             estimate_id,
>             product_id,
>             level_type,
>             bubble_time,
>             is_from_waiting_response
>         from 
>             kflower_dw.dwd_kf_trd_bubble_base_all_di
>         where 
>             dt = '2025-12-15'
>             and product_1level <> 4	-- 去掉 PBD 端
>             and is_anycar_form = 1	-- 新表单
>             and order_type = 0	-- 实时单
>             -- and is_from_waiting_response <> 1
>             and trace_id in ('45e0448a693ef0a2b1b09ae9c0973e9d')
>     ) a 
>     left join (
>         select 
>             order_id,
>             bubble_trace_id,
>             estimate_id,
>             product_id,
>             level_type,
>             call_time,
>             append_call_time,
>             update_time,
>             is_update_dest,
>             is_wait_call,
>             is_td_call,
>             is_td_answer,
>             is_td_charge,
>             is_td_finish,
>             is_td_cancel
>         from 
>             kflower_dw.dwd_kf_trd_order_anycar_di
>         where 
>             dt = '2025-12-15'
>             -- and source_type <> 2 -- 非改派订单
>             and call_time IS NOT NULL
>             and call_time <> '0000-00-00 00:00:00'
>             and order_id > 0
>             and product_1level in (1, 2, 999)
>             and is_td_call = 1
>             -- and order_id = '140737701878821'
>     ) b on a.estimate_id = b.estimate_id
> ```


[修改目的地订单.xlsx](0a376b7b3622f0ea-修改目的地订单.xlsx)

#### 1.2.4 改派订单落表

- 结论：改派订单「冒泡表」 与 「呼叫表」 直接用bubble_trace_id、estimate_id关联即可；呼叫表不能加source_type <> 2的条件 

	- 订单表：order_id改变，可通过reassign_origin_order_id可关联原始订单order_id；bubble_trace_id、estimate_id不变

改派订单排查过程
- 改派单flag：source_type = 2，通过reassign_origin_order_id可关联原始订单order_id

- 改派单bubble_trace_id：不变

- 改派单estimate_id：不变

- 改派单完单如何统计：记在改派单中，但可以通过bubble_trace_id、estimate_id关联到

> [!example]- PlainText 实现细节（60 行）
> ```PlainText
> with order_info as (
>     select 
>         order_id,
>         reassign_origin_order_id,
>         bubble_trace_id,
>         estimate_id,
>         product_id,
>         level_type,
>         call_time,
>         append_call_time,
>         update_time,
>         is_wait_call,
>         is_td_call,
>         is_td_answer,
>         is_td_charge,
>         is_td_finish,
>         is_td_cancel
>     from 
>         kflower_dw.dwd_kf_trd_order_anycar_di
>     where 
>         dt = '2025-12-15'
>         -- and source_type <> 2 -- 非改派订单
>         and call_time IS NOT NULL
>         and call_time <> '0000-00-00 00:00:00'
>         and order_id > 0
>         and product_1level in (1, 2, 999)
>         and is_td_call = 1
>         and order_id in ('140737701761729','140737701777523')
>         -- and reassign_origin_order_id = '140737701777523'
> )
>
> select 
>     a.*,
>     b.trace_id,
>     b.estimate_id,
>     b.product_id,
>     b.level_type,
>     bubble_time,
>     is_from_waiting_response
> from 
>     order_info a 
>     left join (
>         select 
>             trace_id,
>             estimate_id,
>             product_id,
>             level_type,
>             bubble_time,
>             is_from_waiting_response
>         from 
>             kflower_dw.dwd_kf_trd_bubble_base_all_di
>         where 
>             dt = '2025-12-15'
>             and product_1level <> 4	-- 去掉 PBD 端
>             and is_anycar_form = 1	-- 新表单
>             and order_type = 0	-- 实时单
>             -- and is_from_waiting_response <> 1
>             -- and trace_id = '9bf44a06693f0ac65223bc2610800403'
>     ) b on a.estimate_id = b.estimate_id
> ;
> ```


[改派单分析.xlsx](68db7d49699b6832-改派单分析.xlsx)

| 订单表字段 | 原始订单 | 改派订单 |
| :---: | :---: | :---: |
| order_id | o1 | o2 |
| reassign_origin_order_id | null | o1 |
| bubble_trace_id | t1 | t1 |
| estimate_id | e1 | e1 |
| is_td_finsih | 0 | 1 |

#### 1.2.5 冒泡表与订单表关联总结

- trace_id：

	- 由于去重冒泡统计以呼叫作为分割点，因此呼叫表的bubble_trace_id一定是去重冒泡中时间最靠后的一个冒泡；

	- 在每种场景下，订单对应的bubble_trace_id都不会发生变化

- 品类：由于estimate_id会发生变化，因此只能通过product_id X level_type进行关联

### 1.3 供需变化分析

分析目的：判断X分钟内，供需变化是否大；若供需变化不大，则可考虑等待应答页补勾的完单

结论：4min之内，供需变化不大

#### 1.3.1 by分钟供需变化

取去重冒泡、自营（product_id=80）对应的实时供需sds特征，按照冒泡时间，by分钟计算特征均值，观察每分钟的变化

特征包含：

- 供：

	- snapshot_realtime_empty_driver_cnt_1m_one_circle_grid

	- snapshot_realtime_empty_driver_cnt_3m_one_circle_grid

	- online_driver_cnt_1m_one_circle_grid

- 需：

	- merchant_call_cnt_1m_one_circle_grid

结论：4min之内，供需变化不大

- 观察特征曲线，特征值基本连续，能够反映某一时段的供给情况

- 观察相对变化：剔除夜间

	- 与1分钟之前相比，供需特征的相对变化<10%

	- 与3分钟之前相比，高峰供需特征的相对变化<20%，平峰供需特征的相对变化<10%

![](9e4b8dacc7b65eea-image.png)

#### 1.3.2 改派订单处理

当前处理为不含改

1. **不含改：改派订单和原始订单归为一单，只看最终是否有完单**

	1. 好处：体现了某种勾选下的最终成交率

	2. 坏处：剔除了应答后司机取消；改派订单与原始订单供需不一定一致

2. 含改：改派订单和原始订单归为两单；改派订单记完单、原始订单记未完单

	1. 好处：体现了应答后司机取消

	2. 坏处：相比不含改CR，呼叫数变多，CR更低

#### 1.3.3 等待应答页处理问题

结论：**需要考虑等到应答页补勾的完单**，并剔除补勾时间GAP>4分钟（再考虑）的订单，原因如下

- 呼单占比：11%的呼叫会在等待应答页补勾，8%的完单来自等待应答页补勾

- 补勾时间：60%的订单在1分钟内补勾，90%的订单在3分钟内补勾，此时供需变化不大，因此需要考虑等待应答页补勾的完单

> [!example]- SQL 实现细节（42 行）
> ```SQL
> with call_info as (
>     select 
>         order_id,
>         max(is_wait_call) as is_wait_call,
>         max(case 
>             when is_wait_call = 1 then append_call_time
>         end) as bugou_time,
>         min(case 
>             when is_wait_call = 0 then call_time
>         end) as call_time
>     from 
>         kflower_dw.dwd_kf_trd_order_anycar_di
>     where 
>         dt = '2025-12-15'
>         -- and is_td_call = 1
>         -- 考虑是否要加改派
>         and   source_type <> 2
>         and call_time IS NOT NULL
>         and call_time <> '0000-00-00 00:00:00'
>         and order_id > 0
>         and product_1level in (1, 2, 999)
>         and is_td_call = 1
>     group by 
>         order_id
> ),
>
> time_gap as (
>     select 
>         order_id,
>         unix_timestamp(bugou_time)-unix_timestamp(call_time) as gap,
>         bugou_time,
>         call_time
>     from 
>         call_info
>     where 
>         is_wait_call = 1
> )
>
> select 
>     percentile_approx(gap, array(0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1)) as gap
> from 
>     time_gap
> ```


> [!example]- 完整数据表（1 行记录）
> | 分位数 | 0 | 1 | 20 | 30 | 40 | 50 | 60 | 70 | 80 | 90 | 95 | 100 |
> | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
> | 补勾时间-呼叫时间(s) | 2 | 18 | 23 | 28 | 34 | 44 | 60 | 81 | 114 | 181 | 262 | 5134 |


### 1.4 底表验证数据

- 验证1-12号的数据，应答后乘客取消率有GAP；但是与DS给的口径一致

```PlainText
select 
    count(distinct trace_id) as bubble_cnt,
    count(distinct case when is_td_call = 1 then trace_id end) as call_cnt,
    sum(is_td_answer) as ans_cnt,
    sum(is_td_answer_without_reassign) as ans_without,
    sum(is_td_finish) as finish,
    sum(gmv_amt) as gmv,
    count(distinct case when is_grab_before_pas_cancel = 1 then trace_id end) as is_grab_before_pas_cancel,
    count(distinct case when is_grab_after_pas_cancel = 1 then trace_id end) as is_grab_after_pas_cancel,
    count(distinct case when is_grab_after_pas_cancel_without_reassign = 1 then trace_id end) as is_grab_after_pas_cancel_without_reassign,
    sum(is_grab_after_dri_cancel) as is_grab_after_dri_cancel,
    sum(is_grab_after_dri_cancel_without_reassign) as is_grab_after_dri_cancel_without_reassign,
    sum(driver_start_dis)/sum(is_td_finish) as driver_start_dis,
    sum(answer_dur)/sum(is_td_answer) as answer_dur,
    sum(arrive_dur)/sum(is_td_finish) as arrive_dur,
    sum(finish_dur)/sum(is_td_finish) as finish_dur

from 
    kflower_strategy.pltf_cr_model_bubble_call_base_info
where 
    dt = '2026-01-12'
```

> [!example]- 完整数据表（19 行记录）
> | 指标 | 底表 | 看板 | 差距 |
> | --- | --- | --- | --- |
> | bubble_cnt | 6573837 | 6573396 | 0.0% |
> | call_cnt | 4574865 | 4592832 | -0.4% |
> | ans_cnt | 4345922 | 4,359,920 | -0.3% |
> | ans_without | 4067696 | 4,081,058 | -0.3% |
> | finish | 3592482 | 3604933 | -0.3% |
> | gmv | 53971060.6 | 54240300 | -0.5% |
> | is_grab_before_pas_cancel | 454843 | 454690 | 0.0% |
> | is_grab_after_pas_cancel | 490290 | 507735 | -3.4% |
> | is_grab_after_pas_cancel_without_reassign | 426108 | 427905 | -0.4% |
> | is_grab_after_dri_cancel | 237089 | 238052 | -0.4% |
> | is_grab_after_dri_cancel_without_reassign | 34892 | 35097 | -0.6% |
> | 冒泡呼叫率 | 69.59% | 69.87% | -0.3% |
> | 应答率 | 88.91% | 88.86% | 0.1% |
> | 成交率 | 78.53% | 78.53% | 0.0% |
> | 应答前乘客取消率 | 9.94% | 9.90% | 0.0% |
> | 应答后乘客取消率-含改 | 11.28% | 9.78% | 1.5% |
> | 应答后乘客取消率-不含改 | 10.48% | 9.16% | 1.3% |
> | 应答后司机取消率-含改 | 5.46% | 5.46% | 0.0% |
> | 应答后司机取消率-不含改 | 0.86% | 0.86% | 0.0% |


## 2 特征分析

### 2.1 缺失率

- 缺失率高的特征：

	- product_id X start_grid_id X time_slice的取消、应答特征；格子 X 小时维度特征缺失率极高

	- passenger_id维度司机取消特征、价差

[特征缺失率.xlsx](7d8a83fe0dee5f8c-特征缺失率.xlsx)

### 2.2 XGB重要性

EVE任务及口径
运用XGB模型评估特征重要性

- 注意事项

	- 对于特征选取组件，缺失值填充-9999，每个特征选取组件的特征顺序保持一致，通过文本编辑复制粘贴实现更为稳妥。

	- is_cp_answer 缺失值填充的-1，需要在样本提取中剔除-1的值，逻辑回归的label必须是\[0,1\],只在实验3️⃣中剔除。

（1）数据来源：

	- 表：cr_model_train_data，维度为呼叫 X 商家

	- 日期范围：

		- 训练集2025-12-15～2025-12-21，按照==呼叫维度==随机下采样10%；

		- 测试集2025-12-22～2025-12-28，按照==呼叫维度==随机下采样2%；

（2）分析目标：呼叫的特征与完单label，商家特征与商家完单、应答label

**特征与label选取**

	- 呼叫维度特征：trace_id 维度 共计170个特征

完单label：is_trace_finish  1️⃣

	- 商家特征维度：product_id 维度  共计236个特征

商家完单label：is_cp_finish 2️⃣

商家应答label：is_cp_answer 3️⃣

- eve任务：<https://ether.intra.hongyibo.com.cn/labs/new/15267>

[特征重要性排序.xlsx](443d82096afb27ee-特征重要性排序.xlsx)

#### 2.2.1 特征重要性分析结论

分析三个实验中排名前30的特征重要性

**呼叫特征与is_trace_finish**

- **乘客侧特征主导影响完单**，14 日完单率、完单量等乘客历史行为特征较为重要。

- 时间维度来看，14 天历史聚合特征(rank 3 8 14 18 19)比7天历史聚合特征(rank 25)更为重要，呼叫特征实时相较于聚合更为重要。

- 地点维度来看，**城市相较于格子更加重要**，一圈格子相较于中心格子更为重要，含有更多的trace特征。

**商家特征与is_cp_finish**

- 商家测历史完单指标重要性远超其他维度特征(rank 1 2)，说明商家自身的履约历史是预测其完单的核心依据，**更长周期**的商家完单情况对完单预测的参考价值更高。

- 时间维度来看，1 分钟级聚合的司机、订单指标（1 分钟一圈格子空车司机数、1 分钟商家举手数）是实时维度的核心特征，10 分钟聚合特征重要性相对靠后。实时特征与 1 分钟聚合特征重要性接近，说明超短周期的司机供给波动，是影响商家实时完单的关键。

- 地点维度来看，一圈格子特征是地点维度的核心（如一圈格子的空车司机数、在线司机数、冒泡数、呼单数），前 20 中占比超 60%，中心格子特征权重低，与该特征缺失率较高有关。

**商家特征与is_cp_answer**

- 司机侧特征是应答转化的核心，一圈格子内的空车司机数、在线司机数等司机供给类更为重要，说明周边司机资源的实时充足度，直接决定商家订单能否被快速应答。商家 14 天的历史完单率重要性排名第一，同时商家的 14 日取消率、应答率等特征也排名靠前，进一步验证商家自身运营水平对答的关键影响。

- 时间维度来看，历史聚合特征**14日特征全面优于7日特征**；实时与短周期聚合特征重要性排名为：1 分钟聚合(rank 2 4 14 21)＞3 分钟聚合(rank 6 10 22 26)＞10 分钟聚合(rank 9 17 23 27)

- 地点维度来看，一圈格子特征占比超 70%，说明商家周边一圈格子的司机供需环境，是影响订单应答的核心地理因素；中心格子特征重要性排名靠后。       

#### 2.2.2 模型预估评价指标

| label | auc | f_1 score | 召回率 | 精确率 | 准确率 |
| --- | --- | --- | --- | --- | --- |
| is_trace_finish | ==0.760687== | 0.841745 | 0.923945 | 0.772976 | 0.755210 |
| is_cp_finish | 0.897146 | 0.059682 | 0.031505 | 0.564897 | 0.971969 |
| is_cp_answer | ==0.901564== | 0.502253 | 0.395402 | 0.689266 | 0.925069 |

模型评估指标细节

实验1️⃣：

| 实际值（正） | TP:447874 | FN:36867 | P:484741 |
| --- | --- | --- | --- |
| 实际值（负） | FP:131541 | TN:71687 | N:203228 |
| 总数 | T:579415 | F:108554 | |

==实验2️⃣：==

| | 模型预测（正） | 模型预测（负） | 总数 |
| --- | --- | --- | --- |
| 实际值（正） | TP:15272 | FN:469470 | P:484742 |
| 实际值（负） | FP:11763 | TN:16671593 | N:16683356 |
| 总数 | T:27035 | F:17141063 | |

实验3️⃣： 测试集auc-==0.901564==

| | 模型预测（正） | 模型预测（负） | 总数 |
| --- | --- | --- | --- |
| 实际值（正） | TP:==638831== | FN:==976820== | P:==1615651== |
| 实际值（负） | FP:==287997== | TN:==14976054== | N:==15264051== |
| 总数 | T:==926828== | F:==15952874== | |

## 3 补充特征

### 3.1 特征一览

在之前基础上补充：（P/商家/城市）X 品类维度特征、P维度特征、城市维度特征

| 分类 | key | 特征 |
| --- | --- | --- |
| 商家维度实时sds特征 | | pltf_cr_model_input_feature <br>pltf_cr_input_log_parse_product_feature （注意其中city开头的是城市维度特征） |
| 商家维度历史特征 | product_id、city_id  <br>product_id、city_id、hour_of_day、is_weekday <br>product_id、city_id、level_type / product_priority  <br>     幸运盒子、特价盒子、盒子外、特快盒子 <br>~~product_id、city_id、is_weekday~~ <br>~~product_id、start_grid_id~~ <br> | - 数指标： <br><br>	- 交易漏斗：冒泡数、呼叫数、应答数（含改/不含改）、应答前乘客取消数、应答后乘客取消数（含改/不含改）、应答后司机取消数（含改/不含改）、完单数 <br><br>	- ~~司机数：举手参与司机数、应答司机数、接驾司机数~~ <br><br>	- 订单单均：应答时长、接驾时长(只取完单口径下的)、送驾时长（完单）、接驾距离（应答）、订单距离（冒泡）、冒泡max/avg/min应付、冒泡max/avg/min实付、完单应付（完单）、完单C补、完单B补 <br><br>		- 冒泡应付要先by trace_id product_id 算好max min avg <br><br>- 率指标： <br><br>	- 客观冒泡呼叫率、客观呼叫应答率、客观呼叫完单率、应答前乘客取消率、应答后乘客取消率（含改/不含改）、应答后司机取消率（含改/不含改） <br><br>	- 冒泡平均cpm、完单cpm（分/米）、完单iph（分/秒）、完单estimate_v（米/秒） <br> |
| 城市维度历史特征 | city_id  <br>city_id、product_priority <br>幸运盒子、特价盒子、盒子外、特快盒子 <br>~~city_id、is_weekday~~ <br>city_id、hour_of_day、is_weekday | - 数指标： <br><br>	- 交易漏斗：冒泡数、呼叫数、应答数、应答前乘客取消数、应答后乘客取消数、应答后司机取消数、完单数 <br><br>	- ~~司机数：举手参与司机数、应答司机数、接驾司机数~~ <br><br>	- 订单单均：应答时长、接驾时长、送驾时长、接驾距离、订单距离、完单应付、完单C补、完单B补 <br><br>- 率指标： <br><br>	- 冒泡呼叫率、呼叫应答率、呼叫完单率、应答前乘客取消率、应答后乘客取消率、应答后司机取消率 <br><br>	- cpm（分/米）、iph（分/秒）、estimate_v（米/秒） <br><br>- product_priority： <br><br>	- 数指标：呼叫量、应答量、完单量、完单GMV、完单C补、完单B补、完单距离、完单送驾时长 <br><br>	- 率指标：呼叫占比、完单占比、应答率、完单率、单均应答时长、完单C补率、完单ASP、完单距离、完单cpm、完单iph、完单C补率、完单B补率 <br> |
| 乘客维度历史特征 | passenger_id <br>passenger_id、product_priority <br>~~passenger_id、is_weekday~~ <br> | - 竞争相关P维度表 <br><br>	- todo：前两个表直接找入月要TOP特征里的 <br><br>		- [【LR25027】流失召回算法策略v0](https://cooper.didichuxing.com/knowledge/2199610335356/2205121614750) <br><br>		- [kflower_strategy.dm_user_behavior_multi_app_stat](https://datamap.didichuxing.com/detail?uri=hive://mycluster-tj:kflower_strategy:dm_user_behavior_multi_app_stat&keyword=kflower_strategy,dm_user_behavior_multi_app_stat,kflower_strategy+dm_user_behavior_multi_app_stat) <br><br>		- [kflower_strategy.dm_user_common_behavior_stat](https://datamap.didichuxing.com/detail?uri=hive://mycluster-tj:kflower_strategy:dm_user_common_behavior_stat&keyword=stat,common,dm_user_common_behavior_stat,dm,behavior,user) <br><br>	- [kflower_strategy.dm_user_compete_tag_stat](https://datamap.didichuxing.com/detail?uri=hive://mycluster-tj:kflower_strategy:dm_user_compete_tag_stat) <br><br>	- ==[kflower_strategy.competition_pid_tag](https://datamap.didichuxing.com/detail?uri=hive://mycluster-tj:kflower_strategy:competition_pid_tag&keyword=kflower_strategy+competition_pid_tag,kflower_strategy,competition_pid_tag,kflower,competition,pid,tag,strategy)== <br><br>- 数指标： <br><br>	- 交易漏斗：冒泡数、呼叫数、应答数、应答后乘客取消数、完单数 <br><br>	- 订单单均：应答时长、接驾时长、送驾时长、接驾距离、订单距离、完单应付、完单C补 <br><br>- 率指标： <br><br>	- 冒泡呼叫率、呼叫应答率、呼叫完单率 <br><br>	- cpm（分/米）、iph（分/秒）、estimate_v（米/秒） <br> |

### 3.2 呼叫底表的label

#### 3.2.1 订单流转

![](a57d102e850ca899-附件.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwNjg1Mjc0Mjg3OA", "version": "", "fileUrl": "../../../%E9%99%84%E4%BB%B6/a5/a57d102e850ca899-%E9%99%84%E4%BB%B6.svg"}
```

#### 3.2.2 不同场景的label落表

Q：如何区分含改/不含改口径？

- 含改口径，将原始订单和改派订单，视作两个订单；

- 不含改口径只看不断改派的最后一单

- 例子：原始订单A，应答后司机取消，改派订单B，应答后完单，此处应答数-含改=2，应答数不含改=1，应答后司机取消数-含改=1，应答后司机取消数不含改=0；

> [!example]- 场景与 label 原始对照（保留各行完整内容）
> > 原导出表缺少部分合并单元格信息。以下按原行、原单元顺序保留；字段与场景的精确归属请对照本页 Cooper 原文。
>
> **原表头**：表名称 <br> · label <br> · 完单有改派 <br> · 完单无改派 <br> · 应答前乘客取消（无改派） <br> · 改派单应答前取消 <br> · ==应答后乘客取消无改派（未完单）== <br> · ==应答后乘客取消有改派（未完单）== <br> · ==应答后司机取消无改派（未完单）== <br> · 应答后司机取消有改派（未完单） <br>
>
> **原记录 1**
>
> - 例子 <br>
> - （空单元格）
> - [完单有改派例子.xlsx](0334ee8c0e0535ae-完单有改派例子.xlsx) <br>
> - [完单例子.xlsx](985cd21c83b10e5b-完单例子.xlsx) <br>
> - [应答前取消例子.xlsx](57c26f8191fbe72e-应答前取消例子.xlsx) <br>
> - [改派后应答前取消例子.xlsx](bffea98e797ab937-改派后应答前取消例子.xlsx) <br>
> - [应答后乘客取消-无改派.xlsx](2c7ed5aec70ef0bc-应答后乘客取消-无改派.xlsx) <br>
> - <br>[应答后乘客取消-有改派.xlsx](a108f1ccb74a94b8-应答后乘客取消-有改派.xlsx) <br>
> - [应答后司机取消（无改派）.xlsx](5dbe810093afab37-应答后司机取消_无改派_.xlsx) <br>
> - [应答后司机取消（有改派）.xlsx](54ecc0aba2dc3100-应答后司机取消_有改派_.xlsx) <br>
>
> **原记录 2**
>
> - 订单类别 <br>
> - （空单元格）
> - 改派订单 <br>
> - 原始订单 <br>
> - 原始订单 <br>
> - 原始订单 <br>
> - 改派订单 <br>
> - 原始订单 <br>
> - 原始订单 <br>
> - 改派订单 <br>
> - 原始订单 <br>
> - 原始订单 <br>
> - 改派订单 <br>
> - 原始订单 <br>
>
> **原记录 3**
>
> - 链路说明 <br>
> - （空单元格）
> - 用户发单，应答后司机取消，改派后，司机应答，完单 <br>
> - （空单元格）
> - 用户发单，第一次应答前，乘客取消 <br>
> - 用户发单，第一次应答后，司机取消，等第二次应答时乘客取消 <br>
> - 用户发单，第一次应答后，乘客取消 <br>
> - 用户发单，第一次应答后，司机取消，第二次应答后，乘客取消 <br>
> - 用户发单，第一次应答后，司机取消 <br>
> - 用户发单，第一次应答后，司机取消，第二次应答后，司机取消 <br>
>
> **原记录 4**
>
> - 呼叫车型维度订单明细表 kflower_dw.dwd_kf_trd_order_anycar_di <br>
> - is_td_call <br>
> - 只要呼叫的车型都为1 <br>
> - 1 <br>
> - 1 <br>
> - 1 <br>
> - 1 <br>
> - 1 <br>
> - 1 <br>
> - 1 <br>
> - 1 <br>
> - 1 <br>
> - 1 <br>
> - 1 <br>
>
> **原记录 5**
>
> - is_td_answer <br>
> - 每次呼叫时仅有一个product_id对应label为‘1’ <br>
> - 每次呼叫时仅有一个product_id对应label为‘1’ <br>
> - 仅有一个product_id对应label为‘1’ <br>
> - 均为‘0’ <br>
> - 均为‘0’ <br>
> - 仅有一个product_id对应label为‘1’ <br>
> - 仅有一个product_id对应label为‘1’ <br>
> - 此次呼叫时仅一个product_id对应label为‘1’ <br>
> - 此次呼叫时仅一个product_id对应label为‘1’ <br>
> - 仅有一个product_id对应label为‘1’ <br>
> - 此次呼叫时仅一个product_id对应label为‘1’ <br>
> - 此次呼叫时仅一个product_id对应label为‘1’ <br>
>
> **原记录 6**
>
> - is_td_charge <br>
> - is_td_finish为‘1’时，is_td_charge为‘1’，answer_dur, arrive_dur, finish_dur有数值 <br>order_id product_id level_type 聚合下仅有一个 <br>
> - 均为‘0’ <br>
> - 同有改派的改派订单 <br>
> - 均为‘0’ <br>
> - 均为‘0’ <br>
> - 只有answer_dur有数值 <br>
> - 只有answer_dur有数值 <br>
> - 只有answer_dur有数值 <br>
> - 只有answer_dur有数值 <br>
> - answer_dur和arrive_dur 有数值 <br>（可能司机到达后，乘客一直不来，故司机无奈取消） <br>
> - 只有answer_dur有数值 <br>
> - answer_dur和arrive_dur均有数值 <br>
>
> **原记录 7**
>
> - is_td_finish <br>
>
> **原记录 8**
>
> - answer_dur <br>
>
> **原记录 9**
>
> - arrive_dur <br>
>
> **原记录 10**
>
> - finish_dur <br>
>
> **原记录 11**
>
> - is_td_cancel <br>
> - 均为‘0‘ <br>
> - 均为‘0’ <br>
> - 均为‘0’ <br>
> - 均为‘1’ <br>
> - 均为‘1’ <br>
> - 仅取消的一个商家product_id 对应‘1’，其余‘0’ <br>
> - 仅取消的一个商家product_id 对应‘1’，其余‘0’ <br>
> - 仅取消的一个商家product_id 对应‘1’，其余‘0’ <br>
> - 均为‘0’ <br>
> - 仅取消的一个商家product_id 对应‘1’，其余‘0’ <br>
> - 仅取消的一个商家product_id 对应‘1’，其余‘0’ <br>
> - 均为‘0’ <br>
>
> **原记录 12**
>
> - cancel_type <br>
> - 均为‘1’ <br>
> - order_id下所有商家product_id均为‘2’ <br>
> - order_id下所有商家product_id均为‘2’ <br>（即使原始订单司机取消，但仍记录应答后乘客取消） <br>
> - order_id下所有商家product_id均为‘2’ <br>
> - order_id下所有商家product_id均为‘2’ <br>
> - 均为‘0’ <br>
> - order_id下所有商家product_id均为‘3’ <br>
> - order_id下所有商家product_id均为‘3’ <br>
>
> **原记录 13**
>
> - source_type <br>
> - 2 <br>
> - 1 <br>
> - 1 <br>
> - 无改派-均为‘1’ <br>
> - 2 <br>
> - 1 <br>
> - 1 <br>
> - 第二次呼叫-‘2‘（改派） <br>
> - 第一次呼叫-’1‘ <br>
> - 无改派-均为‘1’ <br>
> - 第二次呼叫-‘2‘（改派） <br>
> - 第一次呼叫-’1‘ <br>
>
> **原记录 14**
>
> - 订单指标口径标签表 kflower_dw.dim_kf_trd_unity_order_label_di <br>同一个订单的label都相同 <br>
> - is_td_answer <br>
> - 只要有司机应答，改派前后的order_id对应label均为‘1’ <br>
> - 1 <br>
> - 1 <br>
> - 均为‘0’ <br>
> - 0 <br>
> - 1 <br>
> - 1 <br>
> - 均为‘1’ <br>
> - 均为‘1’ <br>
> - 均为‘1’ <br>
> - 均为‘1’ <br>
> - 均为‘1’ <br>
>
> **原记录 15**
>
> - is_td_finish <br>
> - ==1== <br>
> - 0 <br>
> - 1 <br>
> - 0 <br>
> - 0 <br>
> - 0 <br>
> - 均为‘0‘ <br>
> - 均为‘0’ <br>
> - 均为‘0’ <br>
> - 均为‘0’ <br>
> - 均为‘0’ <br>
>
> **原记录 16**
>
> - is_grab_after_dri_cancel <br>
> - 0 <br>
> - 1 <br>
> - 0 <br>
> - 0 <br>
> - 0 <br>
> - 0 <br>
> - 均为‘0’ <br>
> - 均为‘1’ <br>
> - 该order_id下所有label均为‘1’ <br>
> - 均为‘1’ <br>
> - 均为‘1’ <br>
>
> **原记录 17**
>
> - is_grab_after_pas_cancel <br>
> - 0 <br>
> - 0 <br>
> - 1 <br>
> - 1 <br>
> - 该order_id下所有label均为‘1’ <br>
> - 该order_id下所有label均为‘0’ <br>
> - 均为‘0’ <br>
> - 均为‘0’ <br>
> - 均为‘0’ <br>
>
> **原记录 18**
>
> - is_grab_after_srvc_cancel <br>
> - 0 <br>
> - 0 <br>
> - 0 <br>
> - 均为‘0’ <br>
> - 均为‘0’ <br>
> - 均为‘0’ <br>
> - 均为‘0’ <br>
> - 均为‘0’ <br>
>
> **原记录 19**
>
> - is_td_answer_without_reassign <br>
> - 1 <br>
> - 0 <br>
> - 1 <br>
> - 0 <br>
> - 1 <br>
> - 1 <br>
> - 均为‘1’ <br>
> - 均为‘0’ <br>
> - 该order_id下均为‘1’ <br>
> - 均为‘1’ <br>
> - 均为‘0’ <br>
>
> **原记录 20**
>
> - is_grab_after_dri_cancel_without_reassign <br>
> - 0 <br>
> - 不含改的label均为‘0’ <br>
> - 0 <br>
> - 0 <br>
> - 0 <br>
> - 均为‘0’ <br>
> - 均为‘0’ <br>
> - 该order_id下均为‘1’ <br>
> - 均为‘1’ <br>
> - 均为‘0’ <br>
>
> **原记录 21**
>
> - is_grab_after_pas_cancel_without_reassign <br>
> - 1 <br>
> - 0 <br>
> - 1 <br>
> - 均为‘1’ <br>
> - 均为‘0’ <br>
> - 均为‘0’ <br>
> - 均为‘0’ <br>
> - 均为‘0’ <br>
>
> **原记录 22**
>
> - is_grab_after_srvc_cancel_without_reassign <br>
> - 0 <br>
> - 0 <br>
> - 0 <br>
> - 均为‘0’ <br>
> - 均为‘0’ <br>
> - 均为‘0’ <br>
> - 均为‘0’ <br>
> - 均为‘0’ <br>
>



#### 3.3 聚合label方式

| product_id X trace_id | 订单维度 | 备注 | 聚合到冒泡维度后 | 备注 |
| --- | --- | --- | --- | --- |
| 呼叫 | (is_td_call) as is_td_call | | max(is_td_call) as is_td_call | |
| 应答-含改 | order.is_td_answer as is_td_answer | | sum(is_td_anwser) as is_td_answer | 乘客视角，可能应答多次 |
| 应答-不含改 | (case when label.is_td_answer_without_reassign = 1 and order.is_td_answer = 1 then 1 else 0 end) as is_td_answer_without_reassign | 归因到应答的车型 | max(is_td_answer_without_reassign) as is_td_answer_without_reassign | 平台视角，只要应答过一次就算应答，只记录 |
| 应答前乘客取消 | (case when cancel_type= 1 then 1 else 0 end) as is_grab_before_pas_cancel | 归因到乘客 | max(is_grab_before_pas_cancel) as is_grab_before_pas_cancel | 平台视角，只要应答前乘客取消，此次呼叫所有车型都记录。 |
| 应答后乘客取消-含改 | (case when label.is_grab_after_pas_cancel =1 and order.is_td_answer = 1 then 1 else 0 end)   as is_grab_after_pas_cancel | 归因到第二次订单乘客取消--含两种情况，第二次呼叫有司机应答，第二次呼叫无应答 | sum(is_grab_after_pas_cancel) as is_grab_after_pas_cancel | 平台视角，记录所有呼叫后的应答后乘客取消 |
| 应答后乘客取消-不含改 | case when label.is_grab_after_pas_cancel_without_reassign = 1 and (order.is_td_answer = 1 or (label.is_td_answer = 0 and order.is_td_call = 1)) then 1 else 0 end as is_grab_after_pas_cancel_without_reassign <br> | 归因到应答的车型 | max(is_grab_after_pas_cancel_without_reassign) as is_grab_after_pas_cancel_without_reassign | 平台视角，只记录最后一次应答后乘客取消 |
| 应答后司机取消-含改 | (case when label.is_grab_after_dri_cancel =1 and order.is_td_answer = 1 then 1 else 0 end)   as is_grab_after_dri_cancel | 归因到每个订单中取消的司机 | sum(is_grab_after_dri_cancel) as is_grab_after_dri_cancel | 平台视角，记录所有呼叫后的应答后司机取消 |
| 应答后司机取消-不含改 | (case when label.is_grab_after_dri_cancel_without_reassign = 1 and order.is_td_answer = 1 then 1 else 0 end) as is_grab_after_dri_cancel_without_reassign | 归因到第二次订单应答后司机取消 | max(is_grab_after_dri_cancel_without_reassign) as is_grab_after_dri_cancel_without_reassign | 平台视角，只记录最后一次应答后司机取消 |
| 完单 | (order.is_td_finish) as is_td_finish | 无论是否改派，归因到完单的订单 | max (is_td_finish) as is_td_finish | 平台视角，记录完单的订单 |
| answer_dur | (case when order.is_td_answer=1 then answer_dur else 0 end) as answer_dur | 只要有司机应答，就计算应答时间 | sum(answer_dur) as answer_dur | 若有应答的情况下，应答时间统计值&gt;=1,故用sum |
| arrive_dur | (case when label.is_td_finish=1 then arrive_dur else 0 end) as arrive_dur | 只有订单完单，才计算接驾时间 | max(arrive_dur) as arrive_dur | 完单&lt;=1，故取max与sum均可 |
| finish_dur | (case when label.is_td_finish=1 then finish_dur else 0 end) as finish_dur | 只有订单完单，才计算送驾时间 | max(finish_dur) as finish_dur | 完单&lt;=1，故取max与sum均可 |
| driver_start_dis | (case when label.is_td_finish=1 then driver_start_dis else 0 end) as driver_start_dis | 只有订单完单，才计算送驾距离 | max(driver_start_dis) as driver_start_dis | 完单&lt;=1，故取max与sum均可 |

### 3.3 补充特征缺失率/均值分析

[1d_28d聚合特征空值_均值统计xlsx.xlsx](b648ce330d4ab425-1d_28d聚合特征空值_均值统计xlsx.xlsx)
