#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 任务类型: py_spark
# desc: 按城市 + LambdaGroup 日级自动更新新策略 buffer

from datetime import datetime, timedelta

from pyspark.sql import functions as F


# ============================================================================
# 00 任务参数和表名
# ============================================================================
STAT_DT = "${BIZ_DATE_LINE}"

CITY_TABLE = "whole_dw.dim_city"
LAMBDA_DICT_TABLE = "kflower_strategy.platform_greedy_solver_lambda_dict"
TARGET_TABLE = "kflower_strategy.platform_price_anchor_union_strategy_budget_guardrail_dict"
ACTUAL_RATE_TABLE = "kflower_strategy.pltf_union_stg_budget_control_dashboard"
TRAFFIC_SWITCH_TABLE = "kflower_strategy.pltf_union_stg_exp_evaluation_pas_tag"
OUTPUT_TABLE = "kflower_strategy.platform_union_strategy_budget_buffer_auto_guardrail_by_city_object_stg"

DEFAULT_BUFFER = 1.0
ABSOLUTE_BUFFER_UPPER = 2.99
OBJECT_GROUP = "max_order_v1"


# ============================================================================
# 01 日期工具：weekday/weekend 分别维护状态
# ============================================================================
def resolve_date_type(date_text):
    """周一至周四为 weekday，周五至周日为 weekend。"""
    weekday = datetime.strptime(date_text, "%Y-%m-%d").weekday()
    return "weekday" if weekday in (0, 1, 2, 3) else "weekend"


def previous_date_in_same_type(date_text):
    """返回同一日期类型的上一期，不是固定的自然日 T-1。"""
    current_date = datetime.strptime(date_text, "%Y-%m-%d")
    current_date_type = resolve_date_type(date_text)
    previous_date = current_date - timedelta(days=1)
    while resolve_date_type(previous_date.strftime("%Y-%m-%d")) != current_date_type:
        previous_date -= timedelta(days=1)
    return previous_date.strftime("%Y-%m-%d")


STATE_DATE_TYPE = resolve_date_type(STAT_DT)
# old_buffer、目标率和实际率均读取 T 所属日期类型的上一期 T^-d。
PREVIOUS_STATE_DT = previous_date_in_same_type(STAT_DT)
TARGET_RATE_DT = PREVIOUS_STATE_DT
# 切流只检查自然日 T-1，与 T^-d 独立。
TRAFFIC_SWITCH_DT = (
    datetime.strptime(STAT_DT, "%Y-%m-%d") - timedelta(days=1)
).strftime("%Y-%m-%d")


# ============================================================================
# 02 生成本次需要维护的 buffer 键空间
#
# 粒度：city_id + object_group + stg_group，其中 stg_group = LambdaGroup。
# 城市全集取 dim_city 当天分区，LambdaGroup 全集取人工字典表。
# 两者直接做笛卡尔积。
# ============================================================================
lambda_dict_df = spark.table(LAMBDA_DICT_TABLE)

city_df = (
    spark.table(CITY_TABLE)
    .filter(F.col("dt") == STAT_DT)
    .filter(F.col("city_id").isNotNull())
    .select(F.col("city_id").cast("bigint").alias("city_id"))
    .distinct()
)

stg_group_df = (
    lambda_dict_df
    .filter(F.col("stg_group").isNotNull())
    .select("stg_group")
    .distinct()
)

buffer_key_df = (
    city_df
    .crossJoin(stg_group_df)
    .withColumn("object_group", F.lit(OBJECT_GROUP))
    .select("city_id", "object_group", "stg_group")
)


# ============================================================================
# 03 读取同日期类型上一期 buffer，逐键完成初始化
#
# 已有 city_id + object_group + stg_group 使用历史 union_buffer；新城市或新分组的
# 历史值为 NULL 时，只将该键的 old_buffer 初始化为 1.0。
# ============================================================================
previous_buffer_df = (
    spark.table(OUTPUT_TABLE)
    .filter(F.col("dt") == PREVIOUS_STATE_DT)
    .select(
        "city_id",
        "object_group",
        "stg_group",
        "union_buffer",
        "extra_data",
    )
)

old_buffer_df = (
    buffer_key_df
    .join(
        previous_buffer_df,
        ["city_id", "object_group", "stg_group"],
        "left",
    )
    .select(
        "city_id",
        "object_group",
        "stg_group",
        F.coalesce(
            F.col("union_buffer"),
            F.lit(DEFAULT_BUFFER),
        ).alias("old_buffer"),
        F.coalesce(
            F.col("extra_data"),
            F.lit(""),
        ).alias("extra_data"),
    )
)


# ============================================================================
# 04 读取目标率 T^-d、实际率 T^-d 和自然日 T-1 切流标记
# ============================================================================
# 目标率是城市粒度，与实际率一起读取同日期类型上一期 T^-d，
# 再按 city_id 展开到该城市的全部 LambdaGroup。
target_df = (
    spark.table(TARGET_TABLE)
    .filter(F.col("dt") == TARGET_RATE_DT)
    .select(
        "city_id",
        F.col("total_subsidy_rate").alias("target_rate"),
    )
)

# 看板原始明细包含 exp_group 维度。先按 city_id + LambdaGroup 汇总
# cost、delay_cost 和 gmv_amt，再计算实际率，保证关联键唯一。
actual_df = (
    spark.table(ACTUAL_RATE_TABLE)
    .filter(
        (F.col("dt") == PREVIOUS_STATE_DT)
        & (~F.col("city_id").isin("all", "all2"))
        & F.col("lambda_group").isNotNull()
        & (~F.col("lambda_group").isin("all", "未分组"))
    )
    .groupBy(
        F.col("city_id").cast("bigint").alias("city_id"),
        F.col("lambda_group").alias("stg_group"),
    )
    .agg(
        F.sum(F.coalesce(F.col("cost"), F.lit(0.0))).alias("cost"),
        F.sum(F.coalesce(F.col("delay_cost"), F.lit(0.0))).alias(
            "delay_cost"
        ),
        F.sum(F.coalesce(F.col("gmv_amt"), F.lit(0.0))).alias("gmv_amt"),
    )
    .select(
        "city_id",
        "stg_group",
        F.when(
            F.col("gmv_amt") > 0,
            F.round(
                (F.col("cost") + F.col("delay_cost"))
                / F.col("gmv_amt")
                * 100,
                2,
            ),
        )
        .otherwise(F.lit(0.0))
        .alias("actual_rate"),
    )
)

# 同一 pid 在自然日 T-1 命中多个 exp_group 即视为当日切流。
# 切流不与城市或 LambdaGroup 映射，只输出整次任务的全局开关。
pid_exp_group_range_df = (
    spark.table(TRAFFIC_SWITCH_TABLE)
    .filter(F.col("dt") == TRAFFIC_SWITCH_DT)
    .filter(F.col("pid").isNotNull() & F.col("exp_group").isNotNull())
    .groupBy("pid")
    .agg(
        F.min("exp_group").alias("min_exp_group"),
        F.max("exp_group").alias("max_exp_group"),
    )
)

traffic_switch_flag_df = pid_exp_group_range_df.agg(
    F.coalesce(
        F.max(
            F.when(
                F.col("min_exp_group") != F.col("max_exp_group"),
                F.lit(1),
            ).otherwise(F.lit(0))
        ),
        F.lit(0),
    ).alias("has_exp_traffic_switch")
)


# ============================================================================
# 05 计算新 buffer
#
# 不调整：自然日 T-1 切流，或目标率缺失/小于等于 0，或实际率缺失/为 0。
# 正常调整：min(2.99, old_buffer * target_rate / actual_rate)。
# ============================================================================
calculated_buffer = (
    F.col("old_buffer") * F.col("target_rate") / F.col("actual_rate")
)

keep_old_buffer = (
    (F.col("has_exp_traffic_switch") == 1)
    | F.col("target_rate").isNull()
    | (F.col("target_rate") <= 0)
    | F.col("actual_rate").isNull()
    | (F.col("actual_rate") <= 0)
)

output_df = (
    old_buffer_df
    .join(target_df, ["city_id"], "left")
    .join(actual_df, ["city_id", "stg_group"], "left")
    .crossJoin(traffic_switch_flag_df)
    .withColumn(
        "union_buffer",
        F.when(keep_old_buffer, F.col("old_buffer"))
        .when(
            calculated_buffer > ABSOLUTE_BUFFER_UPPER,
            F.lit(ABSOLUTE_BUFFER_UPPER),
        )
        .otherwise(calculated_buffer),
    )
    .select(
        "city_id",
        "object_group",
        "stg_group",
        "union_buffer",
        "extra_data",
    )
)


# ============================================================================
# 06 覆盖写入当天 T 分区
#
# 输出表同时作为当日结果和后续同日期类型的历史 buffer 来源。
# 表 DDL 由独立 SQL 任务一次性执行，每日 PySpark 不再执行建表语句。
# ============================================================================
output_df.createOrReplaceTempView("auto_buffer_result_tmp")
spark.sql(
    """
    INSERT OVERWRITE TABLE {output_table} PARTITION (dt='{stat_dt}')
    SELECT city_id, object_group, stg_group, union_buffer, extra_data
    FROM auto_buffer_result_tmp
    """.format(output_table=OUTPUT_TABLE, stat_dt=STAT_DT)
)

print(
    "baseline auto buffer updated: stat_dt={}, date_type={}, "
    "target_rate_dt={}, actual_rate_dt={}, traffic_switch_dt={}".format(
        STAT_DT,
        STATE_DATE_TYPE,
        TARGET_RATE_DT,
        PREVIOUS_STATE_DT,
        TRAFFIC_SWITCH_DT,
    )
)
