--SPARK_SQL
-- 创建新策略自动 buffer 表，并向当天分区写入一条测试数据。
-- 仅用于建表和链路验证；接入正式任务前请覆盖或删除测试分区。

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

-- 测试写入会覆盖当天 dt 分区；首次验证空表时执行即可。
INSERT OVERWRITE TABLE
kflower_strategy.platform_union_strategy_budget_buffer_auto_guardrail_by_city_object_stg
PARTITION (dt = '${BIZ_DATE_LINE}')
SELECT  CAST(1 AS BIGINT) AS city_id,
        'max_order_v1' AS object_group,
        'guardrail_test_lambda_group' AS stg_group,
        CAST(1.0 AS DOUBLE) AS union_buffer,
        '{"source":"fake_test_data"}' AS extra_data
;

-- 验证：预期返回一条测试数据。
SELECT  city_id,
        object_group,
        stg_group,
        union_buffer,
        extra_data,
        dt
FROM kflower_strategy.platform_union_strategy_budget_buffer_auto_guardrail_by_city_object_stg
WHERE dt = '${BIZ_DATE_LINE}'
;
