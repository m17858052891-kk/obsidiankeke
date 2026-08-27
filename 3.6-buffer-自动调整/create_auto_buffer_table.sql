--SPARK_SQL
-- 仅执行一次：创建原策略自动 buffer 结果表。
-- 日常调度只运行 auto_buffer_job.py，不重复执行 DDL。

CREATE TABLE IF NOT EXISTS
kflower_strategy.platform_union_strategy_budget_buffer_auto_baseline_by_city_object_stg
(
    city_id BIGINT COMMENT '城市ID',
    object_group STRING COMMENT '优化目标，当前固定为max_order_v1',
    stg_group STRING COMMENT 'Lambda分组',
    union_buffer DOUBLE COMMENT '联合决策buffer',
    extra_data STRING COMMENT '兼容现有下游的扩展字段'
)
PARTITIONED BY
(
    dt STRING COMMENT 'buffer业务生效日'
)
TBLPROPERTIES
(
    'TTL' = '180'
);
