--SPARK_SQL
--********************************************************************--
--author:teddycheng
--create time:2025-12-10 14:42:50
--desc:统计by城市by实验组的补贴花费情况
--remind:请在资源引用中添加需要引用的资源
--********************************************************************--
ALTER TABLE kflower_strategy.pltf_union_stg_budget_control_dashboard
ADD COLUMNS (
    lambda_group STRING COMMENT 'Lambda实验分组'
);


create table if not exists `pltf_union_stg_budget_control_dashboard`
(
    `city_id` STRING COMMENT '城市id'
    ,`city_name` STRING COMMENT '城市名称'
    ,`exp_group` STRING COMMENT '实验组，全城不区分城市组的时候，用all'
    ,`gmv_amt` DECIMAL(38, 6)
    ,`cost` DECIMAL(38, 6)
    ,`saved_cost` DOUBLE
    ,`delay_cost` DECIMAL(38, 6)
    ,`plan_total_subsidy_rate` DOUBLE
    ,`old_total_subsidy_rate` STRING
    ,`act_subsidy_rate` DOUBLE COMMENT "实花，跟FO口径拉齐，当前核销的补贴额 / 当天完单的GMV"
    ,`subsidy_rate_including_fuse_saved` DOUBLE COMMENT "实花+熔断节省的钱"
    ,`lambda_group` STRING COMMENT 'Lambda实验分组，全城不区分城市组的时候，用all '
)
comment '实花看板，by城市、by城市by实验、全国，三个维度'
partitioned by
(
    dt STRING
)
tblproperties
(
    'TTL' = '1800'
)
;

with
order_info as 
(
    select  city_id
            ,coalesce(exp_group, '未分组') as exp_group
            ,coalesce(lambda_group, '未分组') as lambda_group
            ,order_id
            ,gmv_amt
            ,uabox_subsidy_c
            ,pltf_subsidy_c
            ,box_saved_yuan
            ,pltf_saved_yuan
    from    kflower_strategy.pltf_union_stg_subsidy_detail_by_order
    where   dt = '${BIZ_DATE_LINE}'
      and   product_type <> '滴滴自营'
)
,fin_info as 	--当天核销数据，订单维度（只有部分城市有数据）
(
    select  city_id
            ,order_id
            ,sum(subsidy_c) as subsidy_c
    from    kflower_dw.dwm_kf_fin_order_subsidy_c_di
    where   dt = '${BIZ_DATE_LINE}'
      and   product_category <> 4	-- 去掉非小猪端流量
      and   subsidy_type = 81
    group by city_id, order_id
)
,fin_before_today_by_city as 	-- 【得到by城市的延迟核销cost】
(
    select  a.city_id
            ,coalesce(sum(subsidy_c), 0) as subsidy_c
    from    fin_info a
    left join order_info b
    on      a.order_id = b.order_id
    where   b.order_id is null	-- 找出今天核销但不是今天完单的订单
    group by a.city_id
)
,subsidy_by_city_by_exp as 
(
    select  city_id
            ,exp_group
            ,lambda_group
            ,sum(gmv_amt) as gmv_amt
            ,sum(uabox_subsidy_c) as uabox_subsidy_c
            ,sum(pltf_subsidy_c) as pltf_subsidy_c
            ,sum(box_saved_yuan) as box_saved_yuan
            ,sum(pltf_saved_yuan) as pltf_saved_yuan
    from    order_info
    group by city_id, exp_group,lambda_group
)
,cost_info_by_city_by_exp as 
(
    select  a.city_id
            ,a.exp_group
            ,a.lambda_group
            ,a.gmv_amt
            ,uabox_subsidy_c + pltf_subsidy_c as cost
            ,box_saved_yuan + pltf_saved_yuan as saved_cost
            ,(gmv_amt / city_total_gmv) * coalesce(subsidy_c, 0) as delay_cost
    from    (
        select  *
                ,sum(gmv_amt) over(partition by city_id) as city_total_gmv
        from    subsidy_by_city_by_exp
    ) a
    left join fin_before_today_by_city b
    on      a.city_id = b.city_id
)
,plan_info as 
(
    select  a.city_id
            ,a.uabox_gmv_amt
            ,a.total_gmv_amt
            ,a.uabox_gmv_amt / a.total_gmv_amt * coalesce(uabox_subsidy_rate_vs_box_gmv, 0) as plan_total_subsidy_rate
            ,coalesce(total_subsidy_rate, 0) as old_total_subsidy_rate
    from    (
        select  city_id
                ,sum(gmv_amt) as total_gmv_amt
                ,sum(if(level_type = 105, gmv_amt, 0)) as uabox_gmv_amt
        from    kflower_strategy.pltf_union_stg_subsidy_detail_by_order
        where   dt = '${BIZ_DATE_LINE}'
          and   product_type <> '滴滴自营'
        group by city_id
    ) a
    left join (
        select  city_id
                ,total_subsidy_rate
                ,uabox_subsidy_rate_vs_box_gmv
        from    kflower_strategy.platform_price_anchor_union_strategy_budget_dict
        where   dt = date_sub('${BIZ_DATE_LINE}', 1)
          and   total_subsidy_rate > 0
    ) b
    on      a.city_id = b.city_id
)
,cost_info_by_city_by_exp_add_plan as 
(
    select  a.*
            ,plan_total_subsidy_rate
            ,old_total_subsidy_rate
    from    cost_info_by_city_by_exp a
    left join plan_info b
    on      a.city_id = b.city_id
)
,final_by_city as 
(
    select  city_id
            ,sum(gmv_amt) as gmv_amt
            ,sum(cost) as cost
            ,sum(saved_cost) as saved_cost
            ,sum(delay_cost) as delay_cost
            ,max(plan_total_subsidy_rate) as plan_total_subsidy_rate
            ,max(old_total_subsidy_rate) as old_total_subsidy_rate
    from    cost_info_by_city_by_exp_add_plan
    group by city_id
)
,final_city_all as 
(
    select  'all' as city_id
            ,sum(gmv_amt) as gmv_amt
            ,sum(cost) as cost
            ,sum(saved_cost) as saved_cost
            ,sum(delay_cost) as delay_cost
            ,sum(plan_total_subsidy_rate * gmv_amt) / sum(gmv_amt) as plan_total_subsidy_rate
            ,'0' as old_total_subsidy_rate
    from    final_by_city
    union all 
    select  'all2' as city_id
            ,sum(gmv_amt) as gmv_amt
            ,sum(if(old_total_subsidy_rate > 0, cost, 0)) as cost
            ,sum(if(old_total_subsidy_rate > 0, saved_cost, 0)) as saved_cost
            ,sum(if(old_total_subsidy_rate > 0, delay_cost, 0)) as delay_cost
            ,sum(plan_total_subsidy_rate * gmv_amt) / sum(gmv_amt) as plan_total_subsidy_rate
            ,'0' as old_total_subsidy_rate
    from    final_by_city
)
,final_meta_data_info as 
(
    select  city_id
            ,'all' as exp_group
            ,'all' as lambda_group
            ,gmv_amt
            ,cost
            ,saved_cost
            ,delay_cost
            ,plan_total_subsidy_rate
            ,old_total_subsidy_rate
    from    final_city_all
    union all 
    select  city_id
            ,'all' as exp_group
            ,'all' as lambda_group
            ,gmv_amt
            ,cost
            ,saved_cost
            ,delay_cost
            ,plan_total_subsidy_rate
            ,old_total_subsidy_rate
    from    final_by_city
    union all 
    select  city_id
            ,exp_group
            ,lambda_group
            ,gmv_amt
            ,cost
            ,saved_cost
            ,delay_cost
            ,plan_total_subsidy_rate
            ,old_total_subsidy_rate
    from    cost_info_by_city_by_exp_add_plan
)
,city_info AS 
(
    select  DISTINCT city_id
            ,city_name
    from    whole_dw.dim_city
    WHERE   dt = '${BIZ_DATE_LINE}'
)
insert overwrite table pltf_union_stg_budget_control_dashboard partition (dt = '${BIZ_DATE_LINE}')
select  a.city_id
        ,case   when a.city_id = 'all' then '全国实花'
                when a.city_id = 'all2' then '全国实花（不含区县定折）' else b.city_name
         end as city_name
        ,exp_group
        ,gmv_amt
        ,cost
        ,saved_cost
        ,delay_cost
        ,round(plan_total_subsidy_rate, 2) as plan_total_subsidy_rate
        ,old_total_subsidy_rate
        ,round((cost+delay_cost) / gmv_amt * 100, 2) as `act_subsidy_rate`
        ,round((cost+delay_cost+saved_cost) / gmv_amt * 100, 2) as `subsidy_rate_including_fuse_saved`
        ,lambda_group
from    final_meta_data_info a
left join city_info b
on      a.city_id = b.city_id
;