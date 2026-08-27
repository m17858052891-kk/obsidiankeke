--SPARK_SQL
--********************************************************************--
--desc: baseline 自动 buffer 正式上线前，将上线日前近 7 天重置为 1.0
--usage: ${BIZ_DATE_LINE} 表示正式上线日 T；本任务只覆盖 T-7 至 T-1
--********************************************************************--

-- 使用动态分区，只覆盖本次 SELECT 产生的 7 个 dt 分区。
SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;
SET spark.sql.sources.partitionOverwriteMode = dynamic;

WITH
lambda_dict AS
(
    SELECT  city_id,
            stg_group
    FROM    kflower_strategy.platform_union_stg_lambda_dict_manually_update
    WHERE   city_id IS NOT NULL
      AND   stg_group IS NOT NULL
),
city_list AS
(
    SELECT DISTINCT
            CAST(city_id AS BIGINT) AS city_id
    FROM    lambda_dict
),
stg_group_list AS
(
    SELECT DISTINCT
            stg_group
    FROM    lambda_dict
),
reset_date_list AS
(
    SELECT  DATE_FORMAT(
                DATE_SUB(TO_DATE('${BIZ_DATE_LINE}'), days_before_start),
                'yyyy-MM-dd'
            ) AS dt
    FROM
    (
        SELECT EXPLODE(ARRAY(1, 2, 3, 4, 5, 6, 7)) AS days_before_start
    ) t
)
INSERT OVERWRITE TABLE
kflower_strategy.platform_union_strategy_budget_buffer_auto_baseline_by_city_object_stg
PARTITION (dt)
SELECT  city.city_id,
        'max_order_v1' AS object_group,
        stg.stg_group,
        CAST(1.0 AS DOUBLE) AS union_buffer,
        '' AS extra_data,
        reset_dt.dt
FROM    city_list city
CROSS JOIN stg_group_list stg
CROSS JOIN reset_date_list reset_dt
;
