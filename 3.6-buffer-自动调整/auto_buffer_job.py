#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 任务类型: py_spark
# desc: 首次自动初始化并按 T-1 日期类型更新原策略 buffer
# 阅读入口：搜索 calculate_new_buffer，可直接定位自动 buffer 核心计算公式。

from datetime import datetime

from pyspark.sql import functions as F
from pyspark.sql.types import (
    StructType,
    StructField,
    LongType,
    StringType,
    DoubleType,
)


CURRENT_BUFFER_TABLE = (
    "kflower_strategy.platform_union_strategy_budget_buffer_source_config"
)
OBJECT_GROUP = "max_order_v1"
DEFAULT_BUFFER = 1.0

# 城市全集只定义“哪些城市可能进入该日期类型”，不直接与全部 LambdaGroup
# 做笛卡尔积。各 LambdaGroup 通过下方 city_scope 决定自己的城市范围。
CITY_UNIVERSE_BY_DATE_TYPE = {
    "weekday": (
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
        15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28,
        29, 30, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43,
        44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57,
        58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71,
        72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85,
        86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99,
        100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113,
        114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127,
        128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141,
        142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155,
        156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169,
        170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183,
        184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197,
        198, 199, 200, 201, 202, 203, 206, 207, 208, 209, 210, 211, 214, 219,
        220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233,
        234, 235, 236, 237, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249,
        250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263,
        264, 265, 266, 267, 268, 269, 270, 271, 272, 273, 277, 278, 279, 280,
        281, 282, 283, 284, 285, 286, 287, 288, 289, 290, 291, 292, 293, 294,
        295, 296, 297, 298, 299, 300, 301, 302, 303, 304, 305, 306, 307, 308,
        309, 310, 311, 314, 315, 317, 318, 319, 320, 321, 322, 323, 324, 325,
        326, 327, 328, 329, 330, 331, 332, 334, 335, 336, 337, 338, 344, 345,
        346, 347, 348, 349, 350, 351, 352, 353, 354, 355, 356, 360, 362, 364,
    ),
    "weekend": (
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
        15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28,
        29, 30, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43,
        44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57,
        58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71,
        72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85,
        86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99,
        100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113,
        114, 115, 116, 117, 118, 119, 120, 121, 123, 124, 125, 126, 127, 128,
        129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142,
        143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156,
        157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170,
        171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184,
        185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198,
        199, 200, 201, 203, 207, 208, 209, 210, 211, 215, 219, 220, 221, 222,
        223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236,
        237, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252,
        253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266,
        267, 268, 269, 270, 271, 272, 273, 277, 278, 279, 280, 281, 282, 283,
        284, 285, 286, 287, 288, 289, 290, 292, 293, 294, 295, 296, 297, 298,
        299, 300, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 311, 314,
        315, 317, 318, 319, 320, 321, 322, 323, 324, 325, 326, 327, 328, 329,
        330, 331, 332, 334, 335, 336, 337, 344, 345, 346, 347, 348, 349, 350,
        351, 352, 353, 355, 356, 360, 362, 364,
    ),
}

# 5 类城市范围：大范围保存相对城市全集的排除项，小范围保存包含项。
# 这样既保留原 2070/1997 个有效组合，又避免维护约 4000 行重复明细。
CITY_SCOPE_RULES = {
    "weekday": {
        "ds": {
            "mode": "exclude",
            "city_ids": (
                206, 210, 214, 277, 291, 332, 338, 344,
            ),
        },
        "acc_cr_thre": {
            "mode": "exclude",
            "city_ids": (
                332,
            ),
        },
        "after_fix": {
            "mode": "exclude",
            "city_ids": (
                214, 277, 291,
            ),
        },
        "compete": {
            "mode": "include",
            "city_ids": (
                6, 8, 13, 14, 15, 16, 19, 22, 24, 25, 26, 29, 32, 33,
                34, 35, 38, 42, 44, 50, 58, 60, 74, 81, 83, 85, 86, 125,
                133, 134, 153, 157, 160, 254,
            ),
        },
        "flat": {
            "mode": "exclude",
            "city_ids": (
                122, 195, 206, 210, 214, 277, 290, 291, 322, 332, 338, 344,
            ),
        },
    },
    "weekend": {
        "ds": {
            "mode": "exclude",
            "city_ids": (
                77, 130, 210, 215, 277, 290, 331, 332, 352,
            ),
        },
        "acc_cr_thre": {
            "mode": "exclude",
            "city_ids": (
                201, 331,
            ),
        },
        "after_fix": {
            "mode": "exclude",
            "city_ids": (
                207, 215, 277, 315, 332,
            ),
        },
        "compete": {
            "mode": "include",
            "city_ids": (
                6, 8, 13, 15, 16, 19, 22, 24, 25, 26, 29, 32, 33, 34,
                35, 38, 42, 44, 50, 58, 60, 74, 81, 83, 85, 86, 125, 133,
                134, 153, 157, 160, 254,
            ),
        },
        "flat": {
            "mode": "exclude",
            "city_ids": (
                69, 75, 130, 201, 203, 207, 209, 210, 215, 268, 277, 290, 314, 315,
                318, 322, 327, 331, 332, 334, 336, 352,
            ),
        },
    },
}

# 实验组与 LambdaGroup 的 1:1 映射由运筹平台维护；本任务只维护
# LambdaGroup(stg_group) 应使用哪一类城市范围。
STG_GROUP_TO_CITY_SCOPE = {
    "pltf_union_stg_v3_only_ds": "ds",
    "pltf_union_stg_v3_only_ds_acc_cr_thre": "acc_cr_thre",
    "pltf_union_stg_v3_only_ds_after_fix": "after_fix",
    "pltf_union_stg_v3_only_ds_compete_v2": "compete",
    "pltf_union_stg_v3_only_ds_compete_v3": "compete",
    "pltf_union_stg_v3_only_ds_compete_v4": "compete",
    "pltf_union_stg_v3_only_ds_discount_peak_flat": "flat",
    "pltf_union_stg_v3_only_ds_mogou_acc_cr_thre_flat_less": "flat",
    "pltf_union_stg_v3_only_ds_mogou_acc_cr_thre_flat_same": "flat",
}

def resolve_city_scope(date_type, city_scope):
    universe = set(CITY_UNIVERSE_BY_DATE_TYPE[date_type])
    rule = CITY_SCOPE_RULES[date_type][city_scope]
    configured_city_ids = set(rule["city_ids"])

    if not configured_city_ids.issubset(universe):
        raise ValueError(
            "city scope contains city outside universe: date_type={}, scope={}".format(
                date_type, city_scope
            )
        )

    if rule["mode"] == "exclude":
        return universe - configured_city_ids
    if rule["mode"] == "include":
        return configured_city_ids
    raise ValueError(
        "unsupported city scope mode: date_type={}, scope={}, mode={}".format(
            date_type, city_scope, rule["mode"]
        )
    )



STAT_DT = "${BIZ_DATE_LINE}"
ACTUAL_RATE_TABLE = "${ACTUAL_RATE_TABLE}"  # 口径对齐后的实际率明细表

TARGET_TABLE = "kflower_strategy.platform_price_anchor_union_strategy_budget_dict"
OUTPUT_TABLE = (
    "kflower_strategy.platform_union_strategy_budget_buffer_auto_baseline_by_city_object_stg"
)
ABSOLUTE_BUFFER_UPPER = 2.99

# 目标率取发布/生效日 T，实际率取观察日 T-1。
# 目标率任务的物理分区 P 读取规划源 P+1，因此目标表 dt=STAT_DT
# 保存的正是 T=STAT_DT+1 的目标率，不需要再做日期偏移。
TARGET_PARTITION_DT = STAT_DT

# BIZ_DATE_LINE 表示公式观察日 T-1。周一至周四更新 weekday，
# 周五至周日更新 weekend；另一类型分区保持不变。
STATE_DATE_TYPE = (
    "weekday"
    if datetime.strptime(STAT_DT, "%Y-%m-%d").weekday() in (0, 1, 2, 3)
    else "weekend"
)


spark.sql(
    """
    CREATE TABLE IF NOT EXISTS {table_name}
    (
        city_id BIGINT COMMENT '城市ID',
        object_group STRING COMMENT '优化目标',
        stg_group STRING COMMENT 'lambda分组，业务语义等于LambdaGroup',
        union_buffer DOUBLE COMMENT '当前使用的buffer',
        extra_data STRING COMMENT '扩展字段'
    )
    PARTITIONED BY
    (
        date_type STRING COMMENT 'weekday/weekend'
    )
    TBLPROPERTIES ('TTL' = '730')
    """.format(table_name=CURRENT_BUFFER_TABLE)
)

# baseline 始终保留现有 dt 分区契约。
spark.sql(
    """
    CREATE TABLE IF NOT EXISTS {output_table}
    (
        city_id BIGINT COMMENT '城市ID',
        object_group STRING COMMENT '优化目标',
        stg_group STRING COMMENT '线上策略版本，业务语义等于LambdaGroup',
        union_buffer DOUBLE COMMENT '联合决策buffer',
        extra_data STRING COMMENT '兼容现有下游的扩展字段'
    )
    PARTITIONED BY
    (
        dt STRING COMMENT '自动状态统计日stat_dt'
    )
    TBLPROPERTIES ('TTL' = '180')
    """.format(output_table=OUTPUT_TABLE)
)
# 只用一次聚合得到当前分区、全量历史和最大分区日期，供初始化与幂等共用。
output_state = spark.table(OUTPUT_TABLE).agg(
    F.sum(
        F.when(F.col("dt") == STAT_DT, F.lit(1)).otherwise(F.lit(0))
    ).alias("existing_output_count"),
    F.count(F.lit(1)).alias("output_total_count"),
    F.max("dt").alias("max_output_dt"),
).collect()[0]
existing_output_count = output_state["existing_output_count"] or 0
output_total_count = output_state["output_total_count"] or 0
max_output_dt = output_state["max_output_dt"]
later_output_exists = max_output_dt is not None and max_output_dt > STAT_DT

if later_output_exists:
    raise ValueError(
        "historical stat_dt={} cannot overwrite current buffer because max snapshot dt={}".format(
            STAT_DT, max_output_dt
        )
    )


def build_initial_buffer_df():
    rows = []
    row_counts = {"weekday": 0, "weekend": 0}
    for date_type in ("weekday", "weekend"):
        for stg_group, city_scope in STG_GROUP_TO_CITY_SCOPE.items():
            for city_id in sorted(resolve_city_scope(date_type, city_scope)):
                rows.append(
                    (
                        int(city_id),
                        OBJECT_GROUP,
                        stg_group,
                        date_type,
                        DEFAULT_BUFFER,
                        "",
                    )
                )
                row_counts[date_type] += 1

    init_df = spark.createDataFrame(
        rows,
        StructType(
            [
                StructField("city_id", LongType(), False),
                StructField("object_group", StringType(), False),
                StructField("stg_group", StringType(), False),
                StructField("date_type", StringType(), False),
                StructField("union_buffer", DoubleType(), False),
                StructField("extra_data", StringType(), False),
            ]
        ),
    )

    return init_df, row_counts


def initialize_current_buffer_once(output_history_exists):
    partition_counts = {
        row["date_type"]: row["count"]
        for row in spark.table(CURRENT_BUFFER_TABLE)
        .groupBy("date_type")
        .count()
        .collect()
    }
    unexpected_date_types = set(partition_counts) - {"weekday", "weekend"}
    if unexpected_date_types:
        raise ValueError(
            "unexpected current buffer date_type: {}".format(
                sorted(unexpected_date_types)
            )
        )

    weekday_count = partition_counts.get("weekday", 0)
    weekend_count = partition_counts.get("weekend", 0)
    if weekday_count and weekend_count:
        print(
            "current buffer already initialized; skip initialization: counts={}".format(
                partition_counts
            )
        )
        return False

    if weekday_count or weekend_count:
        raise ValueError(
            "partial current buffer state; refuse automatic initialization: counts={}".format(
                partition_counts
            )
        )

    if output_history_exists:
        raise ValueError(
            "current buffer is empty but baseline history exists; refuse reset to 1.0"
        )

    init_df, row_counts = build_initial_buffer_df()
    for date_type in ("weekday", "weekend"):
        (
            init_df.filter(F.col("date_type") == date_type)
            .select(
                "city_id",
                "object_group",
                "stg_group",
                "union_buffer",
                "extra_data",
            )
            .createOrReplaceTempView("current_buffer_init_tmp")
        )
        spark.sql(
            """
            INSERT OVERWRITE TABLE {table_name}
            PARTITION (date_type='{date_type}')
            SELECT
                city_id,
                object_group,
                stg_group,
                union_buffer,
                extra_data
            FROM current_buffer_init_tmp
            """.format(
                table_name=CURRENT_BUFFER_TABLE,
                date_type=date_type,
            )
        )

    print(
        "current buffer initialized once: table={}, counts={}, default_buffer={}".format(
            CURRENT_BUFFER_TABLE,
            row_counts,
            DEFAULT_BUFFER,
        )
    )
    return True


initialize_current_buffer_once(output_total_count > 0)


def calculate_new_buffer(joined_df):
    """计算本次要写入 baseline 的新 buffer；这是自动调整的核心公式。"""

    # 只有目标率非负且实际率为正时才计算。
    # target_rate=0 会严格按公式得到 0；缺数、负目标率、实际率非正或
    # 数据异常时保留 old_buffer，避免除零或异常数据放大结果。
    can_adjust = (
        F.col("target_rate").isNotNull()
        & (F.col("target_rate") >= 0.0)
        & F.col("actual_rate").isNotNull()
        & (F.col("actual_rate") > 0.0)
    )

    # 核心计算严格对应需求公式：
    # 1. raw_factor = target_rate / actual_rate
    # 2. calculated_buffer = old_buffer * raw_factor
    # 3. new_buffer = min(2.99, calculated_buffer)
    # 不设置 buffer 下限，也不设置单日调整比例上下限。
    # 因此：actual_rate < target_rate 时系数大于 1，buffer 上调；
    #       actual_rate > target_rate 时系数小于 1，buffer 下调。
    return (
        joined_df.withColumn(
            "raw_factor",
            F.when(can_adjust, F.col("target_rate") / F.col("actual_rate")),
        )
        .withColumn(
            "calculated_buffer",
            F.col("old_buffer") * F.col("raw_factor"),
        )
        .withColumn(
            # union_buffer 就是最终落 baseline、并回写当前状态表的新 buffer。
            "union_buffer",
            F.when(
                can_adjust,
                F.least(F.lit(ABSOLUTE_BUFFER_UPPER), F.col("calculated_buffer")),
            ).otherwise(F.col("old_buffer")),
        )
    )


def build_output_df():
    # 1. 当前 buffer 表同时维护 weekday/weekend 两套状态。每日只读取
    #    stat_dt 对应分区；stg_group 的业务语义就是 LambdaGroup。
    current_buffer_df = (
        spark.table(CURRENT_BUFFER_TABLE)
        .filter(F.col("date_type") == STATE_DATE_TYPE)
        .select(
            "city_id",
            "object_group",
            "stg_group",
            "date_type",
            F.col("stg_group").alias("lambda_group"),
            F.col("union_buffer").cast("double").alias("old_buffer"),
            "extra_data",
        )
    )
    # 2. 目标补贴率取 T 日。目标表 dt=STAT_DT 的内容对应 T=STAT_DT+1，
    #    再与当前 buffer 键关联，展开到该城市全部 LambdaGroup。
    target_df = (
        spark.table(TARGET_TABLE)
        .filter(F.col("dt") == TARGET_PARTITION_DT)
        .select(
            "city_id",
            F.col("total_subsidy_rate").cast("double").alias("target_rate"),
        )
    )
    # 3. 实际率上游按运筹平台实验组—LambdaGroup 映射完成归因。
    #    要求字段：city_id, lambda_group, actual_rate, dt。
    actual_df = (
        spark.table(ACTUAL_RATE_TABLE)
        .filter(F.col("dt") == STAT_DT)
        .select(
            "city_id",
            "lambda_group",
            F.col("actual_rate").cast("double").alias("actual_rate"),
        )
    )
    actual_keys = ["city_id", "lambda_group"]

    joined_df = (
        current_buffer_df.alias("c")
        .join(target_df.alias("t"), ["city_id"], "left")
        .join(actual_df.alias("a"), actual_keys, "left")
        .persist()
    )

    # 4. 调用核心公式，得到本次新的 union_buffer。
    result_df = calculate_new_buffer(joined_df)

    output_df = result_df.select(
        "city_id",
        "object_group",
        "stg_group",
        F.col("union_buffer").cast("double"),
        F.coalesce(F.col("extra_data"), F.lit("")).alias("extra_data"),
    ).persist()
    joined_df.unpersist()
    return output_df


# baseline 的 dt 分区是日级结果，也是幂等日志。若分区已经存在，说明该日
# 已经计算过：直接复用它同步当前状态，避免重跑时再次乘调整系数。
existing_output_df = (
    spark.table(OUTPUT_TABLE)
    .filter(F.col("dt") == STAT_DT)
    .select("city_id", "object_group", "stg_group", "union_buffer", "extra_data")
)

if existing_output_count:
    output_df = existing_output_df
    run_mode = "reuse_existing_daily_snapshot"
else:
    # 首次执行该 stat_dt：计算新 buffer，并保存为 baseline 的 dt 日快照。
    output_df = build_output_df()
    output_df.createOrReplaceTempView("auto_buffer_result_tmp")
    spark.sql(
        """
        INSERT OVERWRITE TABLE {output_table} PARTITION (dt='{stat_dt}')
        SELECT city_id, object_group, stg_group, union_buffer, extra_data
        FROM auto_buffer_result_tmp
        """.format(output_table=OUTPUT_TABLE, stat_dt=STAT_DT)
    )
    run_mode = "compute_new_daily_snapshot"

# baseline 快照成功后，再把同一份新 buffer 回写当前状态表。
# 这里只覆盖本次 STATE_DATE_TYPE；另一个 date_type 完全不动，因此
# weekday/weekend 两套 buffer 可分别连续演进。
output_df.createOrReplaceTempView("current_buffer_state_tmp")
spark.sql(
    """
    INSERT OVERWRITE TABLE {current_buffer_table}
    PARTITION (date_type='{state_date_type}')
    SELECT city_id, object_group, stg_group, union_buffer, extra_data
    FROM current_buffer_state_tmp
    """.format(
        current_buffer_table=CURRENT_BUFFER_TABLE,
        state_date_type=STATE_DATE_TYPE,
    )
)

if run_mode == "compute_new_daily_snapshot":
    output_df.unpersist()

# target/actual/old buffer、adjust_status 和截断原因未来应另行落审计表，
# 不在当前任务中计算后丢弃，也不塞入 extra_data 改变下游契约。
print(
    "baseline auto buffer updated: stat_dt={}, state_date_type={}, mode={}".format(
        STAT_DT, STATE_DATE_TYPE, run_mode
    )
)
