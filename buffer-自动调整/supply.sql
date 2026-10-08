#
,supply_c_actual as 
(
    select  dt
            ,CAST(city_id AS BIGINT) AS city_id
            ,CAST(order_id AS BIGINT) AS order_id #新加入的orderid粒度用于后续聚合
            ,CAST(
                SUM(
                    COALESCE(activity_current_amt, 0)
                ) AS DECIMAL(38, 6)
             ) AS supply_c_actual_amt
            ,CAST(
                SUM(
                    case
                        when project_no = 'PJZ202502170009'
                        then COALESCE(activity_current_amt, 0)
                        else 0
                    end
                ) AS DECIMAL(38, 6)
             ) AS joint_decision_call_return_actual_amt
    from    kflower_finance.dm_kf_fin_yy_subsidy_c_di
    where   dt = '${BIZ_DATE_LINE}'
      and   city_id is not null
      and   project_no in (
                'PJZ202502170004',
                'PJZ202512220072',
                'PJZ202512220070',
                'PJZ202512220073',
                'PJZ202508290014',
                'PJZ202512220071',
                'PJZ202502170009'
            )
      and   (
                (
                        level_type = 105
                    and product_id not in (
                            368,
                            497,
                            408,
                            5264,
                            407
                        )
                )
                or level_type <> 105
            )
    group by dt, city_id
)

#链接order_id / （可能有两种名字bubble_trace_id-trace_id）
,order_info as 
(-- 获取每一个订单的信息，这里我们只考虑当天完单的订单
    select  start_city_id as city_id
            ,bubble_trace_id
            ,order_id
    from    kflower_dw.dwd_kf_trd_unity_order_di
    where   dt = '${BIZ_DATE_LINE}'
      and   is_hxz = 1
      and   order_id is not null
      --   and   is_td_call = 1 -- 保留所有当天完单的订单，避免遗漏昨天发单今天完单的订单
      and   is_td_finish = 1
)

#分母
,actual_city_gmv as 
(
    select  dt
            ,CAST(city_id AS BIGINT) AS city_id
            ,CAST(SUM(gmv_amt) AS DECIMAL(38, 6)) AS actual_city_gmv
    from    kflower_dw.dwm_kf_dri_unity_order_index_di
    where   dt = '${BIZ_DATE_LINE}'
      and   channel_id = 300
      and   is_dd_platform = 0
      and   city_id is not null
    group by dt, city_id
)