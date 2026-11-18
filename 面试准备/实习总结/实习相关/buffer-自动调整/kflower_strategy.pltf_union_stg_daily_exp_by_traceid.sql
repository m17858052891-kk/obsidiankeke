--SPARK_SQL
--********************************************************************--
--author:teddycheng
--create time:2024-12-05 13:59:51
--desc:by traceid维度的，所属的实验组，以及折扣、默勾等信息
--remind:请在资源引用中添加需要引用的资源
--********************************************************************--
ALTER TABLE kflower_strategy.pltf_union_stg_daily_exp_by_traceid
ADD COLUMNS (
    lambda_group STRING COMMENT 'Lambda实验分组'
);



create table if not exists pltf_union_stg_daily_exp_by_traceid
(
    `city_id` STRING
    ,`exp_group` STRING COMMENT '平台呼返策略分组名称'
    ,`trace_id` STRING
    ,`lambda_group` STRING COMMENT 'λ 分组'
)
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
union_log as 
(
    select  param ['city_id'] as city_id
            ,param['traceid'] as traceid
            ,get_json_object(param ['flow_control'], '$.ExpGroupName') as exp_group
            ,get_json_object(param ['flow_control'], '$.LambdaGroup') as lambda_group
    from    kflower_marketplace.ods_log_kflower_platform_call_return_public_log_h
    where   concat_ws('-', year, month, day) = '${BIZ_DATE_LINE}'
      and   param ['call_return_scene_type'] = 1	-- 不等于1的是其它情况，比如补勾、修改目的地等；但此处不需要去掉，因为能表征当前pid所在实验组即可
)
insert overwrite table pltf_union_stg_daily_exp_by_traceid partition (dt = '${BIZ_DATE_LINE}')
select  city_id
        ,exp_group
        ,traceid as trace_id
        ,lambda_group
from    union_log
;