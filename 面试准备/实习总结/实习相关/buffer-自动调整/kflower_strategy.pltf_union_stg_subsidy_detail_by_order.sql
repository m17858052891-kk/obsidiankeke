--SPARK_SQL
--********************************************************************--
--author:teddycheng
--create time:2025-03-18 18:20:59
--desc:by城市by实验的各类补贴率的差异
-- 这里需要注意：该任务都是T+1的定时任务，会存在延迟核销问题，所以不可以此表为最终统计的表。
-- 该表的目的，是为了在T+1时刻，了解在存在延迟核销的情况下，实花情况（主要是对比与定折组）
--remind:请在资源引用中添加需要引用的资源
--********************************************************************--

ALTER TABLE kflower_strategy.pltf_union_stg_subsidy_detail_by_order
ADD COLUMNS (
    lambda_group STRING COMMENT 'Lambda实验分组'
);

create table if not exists `pltf_union_stg_subsidy_detail_by_order`
(
    `city_id` BIGINT COMMENT '起点城市ID'
    ,`passenger_id` STRING COMMENT 'pid'
    ,`product_id` BIGINT COMMENT '产品线ID'
    ,`bubble_trace_id` STRING COMMENT '预估请求trace_id，改派后新建的订单中可能无法取到该值(如需去重或关联，需配合source_id使用)'
    ,`order_id` BIGINT COMMENT '原始订单ID(如需去重或关联，需配合source_id使用'
    ,`gmv_amt` DECIMAL(19, 6) COMMENT 'gvm(元)'
    ,`product_type` STRING COMMENT '品牌类型'
    ,`is_td_finish` BIGINT COMMENT '【是否当日完成计费】'
    ,`is_td_pay` BIGINT COMMENT '【是否当日完成支付】'
    ,`level_type` BIGINT COMMENT '运力类型'
    ,`start_dest_dis` DECIMAL(38, 6)
    ,`apply_from` BIGINT COMMENT '表征platform type'
    ,`subsidy_c` DECIMAL(38, 6)
    ,`subsidy_c_third_part` DECIMAL(38, 6)
    ,`uabox_subsidy_c` DECIMAL(38, 6)
    ,`pltf_subsidy_c` DECIMAL(38, 6)
    ,`shangjia_subsidy_c` DECIMAL(38, 6)
    ,`offline_coupon_subsidy_c` DECIMAL(38, 6)
    ,`api_subsidy_c` DECIMAL(38, 6)
    ,`exp_group` STRING COMMENT '平台呼返策略分组名称'
    ,`is_fuse` BIGINT comment '是否发生熔断'
    ,`lucky_box_subsidy_c` DECIMAL(38, 6)
    ,`business_profit_amt` DECIMAL(38, 6)
    , `lambda_group` STRING COMMENT 'λ 分组'
)
comment "1、每一行是一个订单，只包含当天呼叫且完单的订单；2、完单订单的关键信息都有，包括GMV、各类COST、命中的实验组（在联合决策中）、是否熔断，是否当天支付等"
partitioned by
(
    dt string
)
tblproperties
(
    'TTL' = '180'
)
;

with
subsidy_raw as 
(
    -- 从subsidy_c表中，获取每一个order每一种补贴的记录
    select  order_id
            ,subsidy_type
            ,subsidy_name
            ,is_cheap_lane_order
            ,sum(subsidy_c) as subsidy_c
    from    kflower_dw.dwm_kf_fin_order_subsidy_c_di
    where   dt = '${BIZ_DATE_LINE}'
      and   product_category <> 4	-- 去掉非小猪端流量
    group by order_id, subsidy_type, subsidy_name, is_cheap_lane_order
)
,order_info as 
(
    -- 获取每一个订单的信息，这里我们只考虑当天完单的订单
    select  start_city_id as city_id
            ,passenger_id
            ,product_id
            ,bubble_trace_id
            ,order_id
            ,gmv_amt
            ,product_type
            ,is_td_finish
            ,level_type
            ,start_dest_dis
    from    kflower_dw.dwd_kf_trd_unity_order_di
    where   dt = '${BIZ_DATE_LINE}'
      and   is_hxz = 1
      and   order_id is not null
      --   and   is_td_call = 1 -- 保留所有当天完单的订单，避免遗漏昨天发单今天完单的订单
      and   is_td_finish = 1
)
,extra_order_info as 
(
    select  order_id
            ,is_td_pay
    from    kflower_dw.dwd_kf_trd_order_base_di
    where   dt = '${BIZ_DATE_LINE}'
)
,platform_info as 
(
    select  distinct product_id
            ,apply_from
    from    kflower_dw.dim_hh_com_id_map_df
    where   dt = '${BIZ_DATE_LINE}'
)
,exp_info as 
(
    select  trace_id
            ,max(exp_group) as exp_group
            ,max(lambda_group) as lambda_group
    from    kflower_strategy.pltf_union_stg_daily_exp_by_traceid
    where   dt between date_sub('${BIZ_DATE_LINE}', 1)
      and   '${BIZ_DATE_LINE}'
    group by trace_id
)
,subsidy_agg_base_info as 
(
    select  a.*
            ,b.product_id
            ,product_type
            ,level_type
            ,apply_from
    from    subsidy_raw a
    left join order_info b
    on      a.order_id = b.order_id
    left join platform_info c
    on      b.product_id = c.product_id
)
,subsidy_agg as 
(
    select  order_id
            ,sum(subsidy_c) as subsidy_c
            ,sum(if((product_type = '三方品牌' and apply_from = 4 and subsidy_type in (69, 71, 72, 85)) or (product_type = '三方品牌' and apply_from = 1 and subsidy_type in (67, 71)), subsidy_c, 0)) as subsidy_c_third_part
            ,sum(if(subsidy_type = 81 and is_cheap_lane_order = 1, subsidy_c, 0)) as uabox_subsidy_c
            ,sum(if(subsidy_type = 81 and is_cheap_lane_order = 0, subsidy_c, 0)) as pltf_subsidy_c
            ,sum(if(subsidy_type = 82, subsidy_c, 0)) as shangjia_subsidy_c
            ,sum(if(subsidy_type = 3, subsidy_c, 0)) as offline_coupon_subsidy_c
            ,sum(if(subsidy_type = 69, subsidy_c, 0)) as api_subsidy_c
            ,sum(if(subsidy_type = 64, subsidy_c, 0)) as lucky_box_subsidy_c
    from    subsidy_agg_base_info
    group by order_id
)
,fuse_info as 
(
    select  distinct param ['traceid'] as trace_id
            ,param ['is_fuse'] as is_fuse
    from    kflower_marketplace.ods_log_kflower_platform_call_return_public_log_h
    where   concat_ws('-', year, month, day) = '${BIZ_DATE_LINE}'
)
,fuse_cost_info as 
(
    select  *
    from    (
        select  param['traceid'] AS trace_id
                ,CAST(COALESCE(GET_JSON_OBJECT(cl, '$.lt'), '0') AS BIGINT) AS lt
                ,CAST(COALESCE(GET_JSON_OBJECT(cl, '$.pro_id'), '0') AS BIGINT) AS pro_id
                -- saved_by_fuse 均为“分”，转“元”
                ,CAST(COALESCE(GET_JSON_OBJECT(cl, '$.box_call_return_saved_by_fuse'), '0') AS BIGINT) / 100.0 AS box_saved_yuan
                ,CAST(COALESCE(GET_JSON_OBJECT(cl, '$.platform_call_return_saved_by_fuse'), '0') AS BIGINT) / 100.0 AS pltf_saved_yuan
        from    kflower_marketplace.ods_log_kflower_platform_call_return_public_log_h
        lateral view explode(from_json(param['category_list'], 'array<string>')) exploded AS cl
        WHERE   concat_ws('-', year, month, day) = '${BIZ_DATE_LINE}'
          and   param['is_fuse'] = 'true'
          and   param['category_list'] IS NOT NULL
          and   CAST(COALESCE(GET_JSON_OBJECT(cl, '$.fuse_discount'), '100') AS BIGINT) <> 100
          and   CAST(COALESCE(param['fuse_type'], '0') AS BIGINT) not in (0, 4)
    )
    where   lt <> 107 and (box_saved_yuan > 0 or pltf_saved_yuan > 0)	-- 去掉幸运盒子的结果，因为幸运盒子会有不应该有的补贴率
)
,profit_info as 
(
    select  order_id_flow
            ,sum(business_profit_amt) as business_profit_amt
    -- ,sum(gmv) as gmv -- 已验证，与gmv_amt的口径一致
    from    kflower_finance.dm_kf_fin_rpt_bigagg_order_report_extend_di
    where   dt = '${BIZ_DATE_LINE}'
      and   flow_platform = '花小猪端'
    group by order_id_flow
)
insert overwrite table pltf_union_stg_subsidy_detail_by_order partition (dt = '${BIZ_DATE_LINE}')
select  city_id
        ,passenger_id
        ,a.product_id
        ,bubble_trace_id
        ,a.order_id
        ,gmv_amt
        ,product_type
        ,is_td_finish
        ,is_td_pay
        ,level_type
        ,start_dest_dis
        ,apply_from
        ,coalesce(subsidy_c, 0) as subsidy_c
        ,coalesce(subsidy_c_third_part, 0) as subsidy_c_third_part	-- 非花业务补贴率，从总C补中去掉该部分即可获得花业务
        ,coalesce(uabox_subsidy_c, 0) as uabox_subsidy_c
        ,coalesce(pltf_subsidy_c, 0) as pltf_subsidy_c
        ,coalesce(shangjia_subsidy_c, 0) as shangjia_subsidy_c
        ,coalesce(offline_coupon_subsidy_c, 0) as offline_coupon_subsidy_c
        ,coalesce(api_subsidy_c, 0) as api_subsidy_c
        ,exp_group
        ,is_fuse
        ,coalesce(lucky_box_subsidy_c, 0) as lucky_box_subsidy_c
        ,coalesce(business_profit_amt, 0.0000001)	-- 用一个很小的值，与原始的0区分开来
        ,coalesce(box_saved_yuan, 0) as box_saved_yuan
        ,coalesce(pltf_saved_yuan, 0) as pltf_saved_yuan
        ,lambda_group
from    order_info a
left join subsidy_agg b
on      a.order_id = b.order_id
left join exp_info c
on      a.bubble_trace_id = c.trace_id
left join platform_info d
on      a.product_id = d.product_id
left join extra_order_info e
on      a.order_id = e.order_id
left join fuse_info f
on      a.bubble_trace_id = f.trace_id
left join profit_info g
on      a.order_id = g.order_id_flow
left join fuse_cost_info h
on      a.bubble_trace_id = h.trace_id
  and   (
                (
                        a.level_type = 105
                    and a.level_type = h.lt
                )
            or  (
                        a.level_type <> 105
                    and a.product_id = h.pro_id
                    and a.level_type = h.lt
                )
        )
;