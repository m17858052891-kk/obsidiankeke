--SPARK_SQL
CREATE TABLE IF NOT EXISTS
kflower_strategy.platform_union_strategy_budget_buffer_auto_guardrail_by_city_object_stg
(
    city_id BIGINT COMMENT '城市ID',
    object_group STRING COMMENT '优化目标',
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
)
;

INSERT OVERWRITE TABLE
kflower_strategy.platform_union_strategy_budget_buffer_auto_guardrail_by_city_object_stg
PARTITION (dt = '${BIZ_DATE_LINE}')

SELECT  CAST(1 AS BIGINT) AS city_id,
        'max_order_v1' AS object_group,
        'guardrail_test_lambda_group' AS stg_group,
        CAST(1.0 AS DOUBLE) AS union_buffer,
        '' AS extra_data

UNION ALL

SELECT  CAST(2 AS BIGINT) AS city_id,
        'max_order_v1' AS object_group,
        'guardrail_test_lambda_group' AS stg_group,
        CAST(1.2 AS DOUBLE) AS union_buffer,
        '' AS extra_data

UNION ALL

SELECT  CAST(3 AS BIGINT) AS city_id,
        'max_order_v1' AS object_group,
        'guardrail_test_lambda_group' AS stg_group,
        CAST(0.8 AS DOUBLE) AS union_buffer,
        '' AS extra_data
;