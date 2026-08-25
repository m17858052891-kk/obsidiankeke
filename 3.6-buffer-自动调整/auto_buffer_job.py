#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 任务类型: py_spark
# desc: 首次自动初始化并按生效日 T 的日期类型更新原策略 buffer
# 阅读入口：搜索 calculate_new_buffer，可直接定位自动 buffer 核心计算公式。

from datetime import datetime, timedelta

from pyspark.sql import functions as F
from pyspark.sql.types import (
    StructType,
    StructField,
    LongType,
    StringType,
    DoubleType,
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

TARGET_TABLE = "kflower_strategy.platform_price_anchor_union_strategy_budget_dict"
ACTUAL_RATE_TABLE = "kflower_strategy.pltf_union_stg_budget_control_dashboard"
TRAFFIC_SWITCH_TABLE = "kflower_strategy.pltf_union_stg_exp_evaluation_pas_tag"
OUTPUT_TABLE = (
    "kflower_strategy.platform_union_strategy_budget_buffer_auto_baseline_by_city_object_stg"
)
ABSOLUTE_BUFFER_UPPER = 2.99

def resolve_date_type(date_text):
    """周一至周四为 weekday，周五至周日为 weekend。"""
    weekday = datetime.strptime(date_text, "%Y-%m-%d").weekday()
    return "weekday" if weekday in (0, 1, 2, 3) else "weekend"


def previous_date_in_same_type(date_text):
    """返回同一 date_type 序列中的上一期，而不是简单的自然日减一天。"""
    current_date = datetime.strptime(date_text, "%Y-%m-%d")
    current_date_type = resolve_date_type(date_text)
    previous_date = current_date - timedelta(days=1)
    while resolve_date_type(previous_date.strftime("%Y-%m-%d")) != current_date_type:
        previous_date -= timedelta(days=1)
    return previous_date.strftime("%Y-%m-%d")


# 目标表物理分区 STAT_DT 保存的是源规划 STAT_DT+1，因此：
# - TARGET_BUSINESS_DT：同一 date_type 状态序列中的当前期 T；
# - ACTUAL_RATE_DT：同一 date_type 状态序列中的上一期，不是固定自然日 T-1；
# - PREVIOUS_BUFFER_DT：同一 date_type 上一期结果所在的 baseline 物理分区。
TARGET_PARTITION_DT = STAT_DT
TARGET_BUSINESS_DT = (
    datetime.strptime(STAT_DT, "%Y-%m-%d") + timedelta(days=1)
).strftime("%Y-%m-%d")
STATE_DATE_TYPE = resolve_date_type(TARGET_BUSINESS_DT)
ACTUAL_RATE_DT = previous_date_in_same_type(TARGET_BUSINESS_DT)
PREVIOUS_BUFFER_DT = (
    datetime.strptime(ACTUAL_RATE_DT, "%Y-%m-%d") - timedelta(days=1)
).strftime("%Y-%m-%d")
# 切流判断使用实际率观测日及其自然日前一天。同一 pid 在该
# 窗口内命中多个 exp_group，表示实验组归属发生了切流。
TRAFFIC_SWITCH_BEGIN_DT = PREVIOUS_BUFFER_DT
TRAFFIC_SWITCH_END_DT = ACTUAL_RATE_DT


# 本任务只创建和写入这一张 baseline 表；后续运行从它的同类型上一期
# dt 分区读取 old_buffer，再把新结果写入本次 STAT_DT 分区。
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
# dt 是物理分区；对应业务日为 dt+1。由业务日派生 date_type，判断当前
# 类型是否已经初始化，以及严格的同类型上一期分区是否存在。
output_history_df = spark.table(OUTPUT_TABLE)
snapshot_date_type = F.when(
    F.dayofweek(F.date_add(F.to_date(F.col("dt")), 1)).between(2, 5),
    F.lit("weekday"),
).otherwise(F.lit("weekend"))
output_state = output_history_df.agg(
    F.sum(
        F.when(F.col("dt") == STAT_DT, F.lit(1)).otherwise(F.lit(0))
    ).alias("existing_output_count"),
    F.sum(
        F.when(
            (F.col("dt") < STAT_DT)
            & (snapshot_date_type == F.lit(STATE_DATE_TYPE)),
            F.lit(1),
        ).otherwise(F.lit(0))
    ).alias("same_type_history_count"),
    F.sum(
        F.when(F.col("dt") == PREVIOUS_BUFFER_DT, F.lit(1)).otherwise(F.lit(0))
    ).alias("previous_buffer_count"),
    F.max("dt").alias("max_output_dt"),
).collect()[0]
existing_output_count = output_state["existing_output_count"] or 0
same_type_history_count = output_state["same_type_history_count"] or 0
previous_buffer_count = output_state["previous_buffer_count"] or 0
max_output_dt = output_state["max_output_dt"]
later_output_exists = max_output_dt is not None and max_output_dt > STAT_DT

if later_output_exists:
    raise ValueError(
        "historical stat_dt={} cannot be written after newer snapshot dt={}".format(
            STAT_DT, max_output_dt
        )
    )


def build_initial_old_buffer_df(date_type):
    """某个 date_type 第一次运行时，以 1.0 作为该类型唯一一次初值。"""
    rows = []
    for stg_group, city_scope in STG_GROUP_TO_CITY_SCOPE.items():
        for city_id in sorted(resolve_city_scope(date_type, city_scope)):
            rows.append(
                (
                    int(city_id),
                    OBJECT_GROUP,
                    stg_group,
                    DEFAULT_BUFFER,
                    "",
                )
            )

    return spark.createDataFrame(
        rows,
        StructType(
            [
                StructField("city_id", LongType(), False),
                StructField("object_group", StringType(), False),
                StructField("stg_group", StringType(), False),
                StructField("old_buffer", DoubleType(), False),
                StructField("extra_data", StringType(), False),
            ]
        ),
    )


def load_old_buffer_df():
    """读取严格的同类型上一期；只有该类型从未出现过时才使用 1.0。"""
    if same_type_history_count == 0:
        return build_initial_old_buffer_df(STATE_DATE_TYPE), "initialize_date_type"

    if previous_buffer_count == 0:
        raise ValueError(
            "missing previous same-type buffer partition: stat_dt={}, "
            "state_date_type={}, expected_previous_dt={}".format(
                STAT_DT, STATE_DATE_TYPE, PREVIOUS_BUFFER_DT
            )
        )

    old_buffer_df = (
        spark.table(OUTPUT_TABLE)
        .filter(F.col("dt") == PREVIOUS_BUFFER_DT)
        .select(
            "city_id",
            "object_group",
            "stg_group",
            F.col("union_buffer").cast("double").alias("old_buffer"),
            "extra_data",
        )
    )
    return old_buffer_df, "read_previous_same_type_partition"


def calculate_new_buffer(joined_df):
    """计算本次要写入 baseline 的新 buffer；这是自动调整的核心公式。"""

    # 切流判断的优先级高于 buffer 调整公式。只有没有切流、
    # 目标率非负且实际率为正时才计算。
    # target_rate=0 会严格按公式得到 0；缺数、负目标率、实际率非正或
    # 数据异常时保留 old_buffer，避免除零或异常数据放大结果。
    has_exp_traffic_switch = (
        F.coalesce(F.col("has_exp_traffic_switch"), F.lit(0)) == F.lit(1)
    )
    can_adjust = (
        (~has_exp_traffic_switch)
        & F.col("target_rate").isNotNull()
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
            # union_buffer 就是最终写入本次 baseline dt 分区的新 buffer。
            "union_buffer",
            F.when(has_exp_traffic_switch, F.col("old_buffer")).when(
                can_adjust,
                F.least(F.lit(ABSOLUTE_BUFFER_UPPER), F.col("calculated_buffer")),
            ).otherwise(F.col("old_buffer")),
        )
    )


def build_output_df(old_buffer_df):
    # 1. old_buffer_df 来自 baseline 同日期类型上一期分区；该类型首次运行
    #    时才由初始化键集合提供 1.0。stg_group 的业务语义就是 LambdaGroup。
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
    # 3. 实际率直接读取实花看板的 act_subsidy_rate，不在本任务内重算。
    #    上游口径为：
    #        act_subsidy_rate = round((cost + delay_cost) / gmv_amt * 100, 2)
    #    看板同时包含全国、城市汇总和实验明细行，这里只保留
    #    city_id + lambda_group 粒度的实验明细行。看板 city_id 是 string，
    #    需转成 bigint；lambda_group 的业务语义等于 baseline.stg_group。
    actual_detail_df = (
        spark.table(ACTUAL_RATE_TABLE)
        .filter(F.col("dt") == ACTUAL_RATE_DT)
        .filter(~F.col("city_id").isin("all", "all2"))
        .filter(F.col("exp_group") != "all")
        .filter(~F.col("lambda_group").isin("all", "未分组"))
        .select(
            F.col("city_id").cast("bigint").alias("city_id"),
            F.col("exp_group"),
            F.col("lambda_group").alias("stg_group"),
            F.col("act_subsidy_rate").cast("double").alias("actual_rate"),
        )
    )
    actual_df = actual_detail_df.select(
        "city_id", "stg_group", "actual_rate"
    )

    # 4. 切流判断：在 begin~end 窗口内，如果同一 pid 命中过多个
    #    exp_group，则将该 pid 命中的城市—实验组标记为切流。
    #    再通过实花看板当日的 exp_group—lambda_group 关系，转换为
    #    buffer 任务需要的 city_id + stg_group 粒度。
    pas_info_raw_df = (
        spark.table(TRAFFIC_SWITCH_TABLE)
        .filter(
            F.col("dt").between(
                TRAFFIC_SWITCH_BEGIN_DT, TRAFFIC_SWITCH_END_DT
            )
        )
        .select(
            F.col("pid").cast("string").alias("pid"),
            F.col("exp_group"),
            F.col("city_id").cast("bigint").alias("city_id"),
        )
        .filter(
            F.col("pid").isNotNull()
            & F.col("exp_group").isNotNull()
            & F.col("city_id").isNotNull()
        )
        .distinct()
    )
    switched_pid_df = (
        pas_info_raw_df.groupBy("pid")
        .agg(F.countDistinct("exp_group").alias("pid_exp_group_count"))
        .filter(F.col("pid_exp_group_count") > 1)
        .select("pid")
    )
    switched_city_exp_df = (
        pas_info_raw_df.join(switched_pid_df, ["pid"], "inner")
        .select("city_id", "exp_group")
        .distinct()
    )
    traffic_switch_df = (
        actual_detail_df.select("city_id", "exp_group", "stg_group")
        .join(switched_city_exp_df, ["city_id", "exp_group"], "inner")
        .select("city_id", "stg_group")
        .distinct()
        .withColumn("has_exp_traffic_switch", F.lit(1))
    )

    joined_df = (
        old_buffer_df
        .join(target_df, ["city_id"], "left")
        .join(actual_df, ["city_id", "stg_group"], "left")
        .join(traffic_switch_df, ["city_id", "stg_group"], "left")
    )

    # 5. 切流键优先保留 old_buffer；非切流键才调用核心公式。
    result_df = calculate_new_buffer(joined_df)

    return result_df.select(
        "city_id",
        "object_group",
        "stg_group",
        F.col("union_buffer").cast("double"),
        F.coalesce(F.col("extra_data"), F.lit("")).alias("extra_data"),
    )


# baseline 的 dt 分区既是结果也是状态历史。当前分区已存在时不再重复计算。
if existing_output_count:
    run_mode = "reuse_existing_daily_snapshot"
    state_source = "current_partition_already_exists"
else:
    # 读取同类型上一期作为 old_buffer；该类型第一次出现时仅初始化一次 1.0。
    old_buffer_df, state_source = load_old_buffer_df()
    output_df = build_output_df(old_buffer_df)
    output_df.createOrReplaceTempView("auto_buffer_result_tmp")
    spark.sql(
        """
        INSERT OVERWRITE TABLE {output_table} PARTITION (dt='{stat_dt}')
        SELECT city_id, object_group, stg_group, union_buffer, extra_data
        FROM auto_buffer_result_tmp
        """.format(output_table=OUTPUT_TABLE, stat_dt=STAT_DT)
    )
    run_mode = "compute_new_daily_snapshot"

print(
    "baseline auto buffer updated: stat_dt={}, target_business_dt={}, "
    "actual_rate_dt={}, previous_buffer_dt={}, state_date_type={}, "
    "traffic_switch_window={}~{}, state_source={}, mode={}".format(
        STAT_DT,
        TARGET_BUSINESS_DT,
        ACTUAL_RATE_DT,
        PREVIOUS_BUFFER_DT,
        STATE_DATE_TYPE,
        TRAFFIC_SWITCH_BEGIN_DT,
        TRAFFIC_SWITCH_END_DT,
        state_source,
        run_mode,
    )
)
