目标：通过分析‘天维度的司机历史长时取消’、‘与’司机未来一天是否长时取消‘之间的相关性，分析长时取消的构建为何效果不够明显

1. 分析前N天司机的长时取消数与第N+1天的是否有长时取消行为之间的相关性

## 1. 历史N天 与当天

- 数据

	- ==1745270个司机，15天2025/06/16-2025/06/30==

	- ==77879593条数据，每个订单为1条==

### 1.1.1 相关性计算

 X：前N天长时取消数量，Y：第N+1天是否发生长时取消，计算X与Y的相关性

```SQL
--SPARK_SQL
--author:liujiyuan (modified)
--create time:2025-07-04
--desc:计算所有司机（包括 long_cnt_14d=0）在过去14天的长时取消与次日长时取消的相关系数、司机总数及原始记录总数
--********************************************************************--

SET spark.sql.shuffle.partitions = 500;

WITH
  -- 1. 最近 14 天的订单及判定特征
  order_14 AS (
    SELECT
      a.driver_id                                    AS hxz_driver_id,
      a.cancel_type,
      a.cancel_time,
      a.answer_time,
      a.arrive_time,
      (unix_timestamp(a.cancel_time) - unix_timestamp(a.answer_time)) / 60.0
        AS cancel_after_answer_dur_min,
      b.feature['order_arrive_to_start_roud_dist_gt_than_thres_hxz']
        AS order_arrive_to_start_roud_dist_gt_than_thres_hxz,
      b.feature['order_passenger_late_time_snapshot']
        AS order_passenger_late_time_snapshot
    FROM kflower_dw.dwd_kf_trd_order_base_di a
    LEFT JOIN dd_cdm.dwd_trip_crs_jury_strategy_middleware_di b
      ON a.order_id = b.order_id
     AND b.dt BETWEEN date_sub('${BIZ_DATE_LINE}', 13) AND '${BIZ_DATE_LINE}'
     AND b.strategy_id    IN (11, 15)
     AND b.process_id     IN (7695, 7701)
     AND b.ihap_product_id IN (60010000,120030000,170010000,170020000)
    WHERE a.dt BETWEEN date_sub('${BIZ_DATE_LINE}', 13) AND '${BIZ_DATE_LINE}'
      AND a.product_1level <> 4
      AND (
        a.is_td_answer   = 1 OR
        a.is_td_cancel   = 1 OR
        a.is_td_reassign = 1 OR
        a.is_td_finish   = 1
      )
  ),

  -- 2. 原始记录总数（聚合前行数）
  raw_count AS (
    SELECT COUNT(*) AS total_records
    FROM order_14
  ),

  -- 3. 统计过去14天的“长时取消”次数
  long14 AS (
    SELECT
      hxz_driver_id            AS driver_id,
      SUM(
        CASE
          WHEN cancel_type = 3
           AND cancel_after_answer_dur_min >= 4
           AND (
             arrive_time = '0000-00-00 00:00:00' OR
             order_arrive_to_start_roud_dist_gt_than_thres_hxz = 1 OR
             unix_timestamp(cancel_time) < order_passenger_late_time_snapshot
           )
          THEN 1
          ELSE 0
        END
      )                        AS long_cnt_14d
    FROM order_14
    GROUP BY hxz_driver_id
  ),

  -- 4. 第15天的订单及判定特征
  order_nd AS (
    SELECT
      a.driver_id                                    AS hxz_driver_id,
      a.cancel_type,
      a.cancel_time,
      a.answer_time,
      a.arrive_time,
      (unix_timestamp(a.cancel_time) - unix_timestamp(a.answer_time)) / 60.0
        AS cancel_after_answer_dur_min,
      b.feature['order_arrive_to_start_roud_dist_gt_than_thres_hxz']
        AS order_arrive_to_start_roud_dist_gt_than_thres_hxz,
      b.feature['order_passenger_late_time_snapshot']
        AS order_passenger_late_time_snapshot
    FROM kflower_dw.dwd_kf_trd_order_base_di a
    LEFT JOIN dd_cdm.dwd_trip_crs_jury_strategy_middleware_di b
      ON a.order_id = b.order_id
     AND b.dt = date_add('${BIZ_DATE_LINE}', 1)
     AND b.strategy_id    IN (11, 15)
     AND b.process_id     IN (7695, 7701)
     AND b.ihap_product_id IN (60010000,120030000,170010000,170020000)
    WHERE a.dt = date_add('${BIZ_DATE_LINE}', 1)
      AND a.product_1level <> 4
      AND (
        a.is_td_answer   = 1 OR
        a.is_td_cancel   = 1 OR
        a.is_td_reassign = 1 OR
        a.is_td_finish   = 1
      )
  ),

  -- 5. 标记次日是否发生“长时取消”（0/1）
  next_day AS (
    SELECT
      hxz_driver_id            AS driver_id,
      MAX(
        CASE
          WHEN cancel_type = 3
           AND cancel_after_answer_dur_min >= 4
           AND (
             arrive_time = '0000-00-00 00:00:00' OR
             order_arrive_to_start_roud_dist_gt_than_thres_hxz = 1 OR
             unix_timestamp(cancel_time) < order_passenger_late_time_snapshot
           )
          THEN 1
          ELSE 0
        END
      )                        AS next_day_long_flag
    FROM order_nd
    GROUP BY hxz_driver_id
  ),

  -- 6. 合并三套 driver_id（去重）
  all_drivers AS (
    SELECT l.driver_id         AS driver_id,
           l.long_cnt_14d,
           n.next_day_long_flag
    FROM long14 l
    JOIN next_day n
      ON l.driver_id = n.driver_id

    UNION

    SELECT m.didi_driver_id     AS driver_id,
           l.long_cnt_14d,
           n.next_day_long_flag
    FROM long14 l
    JOIN next_day n
      ON l.driver_id = n.driver_id
    JOIN kflower_strategy.pk_hxz_driver_id m
      ON l.driver_id = m.hxz_driver_id
     AND concat_ws('-',year,month,day) = date_sub(date('${NOW_DATE}'),1)
    WHERE m.didi_driver_id IS NOT NULL

    UNION

    SELECT m.other_driver_id    AS driver_id,
           l.long_cnt_14d,
           n.next_day_long_flag
    FROM long14 l
    JOIN next_day n
      ON l.driver_id = n.driver_id
    JOIN kflower_strategy.pk_hxz_driver_id m
      ON l.driver_id = m.hxz_driver_id
     AND concat_ws('-',year,month,day) = date_sub(date('${NOW_DATE}'),1)
    WHERE m.other_driver_id IS NOT NULL
  )

-- 最终：输出司机总数、相关系数、原始记录总数
SELECT
  COUNT(*)                                 AS driver_count,
  corr(long_cnt_14d, next_day_long_flag)   AS pearson_corr,
  MAX(rc.total_records)                    AS total_order_14d
FROM all_drivers
CROSS JOIN raw_count rc;
```

| ==N== <br> | ==Pearson== <br> |
| :---: | :---: |
| 1 <br> | ==0.024788== <br> |
| 2 <br> | ==0.037544== <br> |
| 3 <br> | ==0.042907== <br> |
| 4 <br> | ==0.047129== <br> |
| 5 <br> | ==0.050303== <br> |
| 6 <br> | ==0.051896== <br> |
| 7 <br> | ==0.054390== <br> |
| 8 <br> | 0.056797 <br> |
| 9 <br> | ==0.058977== <br> |
| 10 <br> | ==0.060100== <br> |
| 11 <br> | ==0.061296== <br> |
| 12 <br> | ==0.062594== <br> |
| 13 <br> | 0.063247 <br> |
| 14 <br> | 0.063417 <br> |
| 15 <br> | ==0.063835== <br> |
| 16 <br> | ==0.064010== <br> |
| 28 <br> | ==0.067479== <br> |

### 1.1.2 N=14 数据分布图 & 阈值分析

| **阈值t(历史14天长时取消率)** <br> | **0** <br> | **0.01** <br> | **0.05** <br> | **0.1** <br> | **0.2** <br> | **0.3** <br> | **0.4** <br> | **0.5** <br> |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
|  <br> <br>**司机数** <br> | TP：X &gt; t & Y != 0 <br> | 387 <br> | 251 <br> | 50 <br> | 17 <br> | 2 <br> | 1 <br> | 1 <br> | 1 <br> |
| TN: X &lt;= t & Y == 0 <br> | 478509 <br> | 489875 <br> | 504820 <br> | 507136 <br> | 507884 <br> | 507991 <br> | 508065 <br> | 508123 <br> |
| FP: X &gt; t & Y == 0 <br> | 29662 <br> | 18296 <br> | 3351 <br> | 1035 <br> | 287 <br> | 180 <br> | 106 <br> | 48 <br> |
| FN: X &lt;= t & Y != 0 <br> | 1013 <br> | 1149 <br> | 1350 <br> | 1383 <br> | 1398 <br> | 1399 <br> | 1399 <br> | 1399 <br> |
|  <br> | 召回 <br> | 38.2% <br> | 17.9% <br> | 3.6% <br> | 0.4% <br> | 0.14% <br> | 0.07% <br> | 0.07% <br> | 0.07% <br> |
|  <br>**司机第15天** <br>**长时取消订单数/总订单数** <br> | TP：X &gt; t & Y != 0 <br> | 421/6579 <br> | 275/3278 <br> | 52/311 <br> | 18/74 <br> | 2/9 <br> | 1/1 <br> | 1/1 <br> | 1/1 <br> |
| TN: X &lt;= t & Y == 0 <br> | 0/3595453 <br> | 0/3836895 <br> | 0/3968240 <br> | 0/3977599 <br> | 0/3979808 <br> | 0/3980068 <br> | 0/3980260 <br> | 0/3980365 <br> |
| FP: X &gt; t & Y == 0 <br> | 0/384979 <br> | 0/143537 <br> | 0/12192 <br> | 0/2833 <br> | 0/624 <br> | 0/364 <br> | 0/172 <br> | 0/67 <br> |
| FN: X &lt;= t & Y != 0 <br> | 1061/13072 <br> | 1207/16373 <br> | 1430/19340 <br> | 1464/19577 <br> | 1480/19642 <br> | 1481/19650 <br> | 1481/19650 <br> | 1481/19650 <br> |
|  <br> | 召回 <br> | 28.4% <br> | 18.6% <br> | 3.5% <br> | 1.2% <br> | 0.13% <br> | 0.07% <br> | 0.07% <br> | 0.07% <br> |
|  <br> | 误判率 <br> | 0.0978 <br> | 0.0366 <br> | 0.003 <br> | 0.0007 <br> | 0.00016 <br> | 0.000091 <br> | 0.000043 <br> | 0.000017 <br> |

- t = 0：历史14天有长时取消，第15天有长时取消

	- 召回：28.4%

- t = 0.1：历史14天长时取消率大于1，第15天有长时取消

	- 召回：18.6%

PS：

（订单）召回 = TP中的长时取消 / （TP + FN）中的长时取消

误判率=(TP总订单- TP长时取消订单 + FP总订单)/所有订单

```SQL


SET spark.sql.shuffle.partitions = 500;
SET spark.sql.autoBroadcastJoinThreshold = -1;

WITH
  ------------------------------------------------------------------------------
  -- 1. 最近 14 天的订单及判定特征
  ------------------------------------------------------------------------------
  order_14 AS (
    SELECT
      a.driver_id                                    AS hxz_driver_id,
      a.cancel_type,
      a.cancel_time,
      a.answer_time,
      a.arrive_time,
      (unix_timestamp(a.cancel_time) - unix_timestamp(a.answer_time)) / 60.0
        AS cancel_after_answer_dur_min,
      b.feature['order_arrive_to_start_roud_dist_gt_than_thres_hxz']
        AS order_arrive_to_start_roud_dist_gt_than_thres_hxz,
      b.feature['order_passenger_late_time_snapshot']
        AS order_passenger_late_time_snapshot
    FROM kflower_dw.dwd_kf_trd_order_base_di a
    LEFT JOIN dd_cdm.dwd_trip_crs_jury_strategy_middleware_di b
      ON a.order_id = b.order_id
     AND b.dt BETWEEN date_sub('${BIZ_DATE_LINE}', 13) AND '${BIZ_DATE_LINE}'
     AND b.strategy_id    IN (11, 15)
     AND b.process_id     IN (7695, 7701)
     AND b.ihap_product_id IN (60010000,120030000,170010000,170020000)
    WHERE a.dt BETWEEN date_sub('${BIZ_DATE_LINE}', 13) AND '${BIZ_DATE_LINE}'
      AND a.product_1level <> 4
      AND (
        a.is_td_answer   = 1 OR
        a.is_td_cancel   = 1 OR
        a.is_td_reassign = 1 OR
        a.is_td_finish   = 1
      )
  ),

  ------------------------------------------------------------------------------
  -- 2. 统计过去14天的“长时取消”次数
  ------------------------------------------------------------------------------
  long14 AS (
    SELECT
      hxz_driver_id            AS driver_id,
      SUM(
        CASE
          WHEN cancel_type = 3
           AND cancel_after_answer_dur_min >= 4
           AND (
              --司机没有点击到达
             arrive_time = '0000-00-00 00:00:00'
              --司机点击了到达，但并没有到该到达的点位点击到达
             OR order_arrive_to_start_roud_dist_gt_than_thres_hxz = 1
              --司机到达了点位，但是并没有等到足够的时间
             OR unix_timestamp(cancel_time) < order_passenger_late_time_snapshot
           )
          THEN 1
          ELSE 0
        END
      )                        AS long_cnt_14d
    FROM order_14
    GROUP BY hxz_driver_id
  ),

  ------------------------------------------------------------------------------
  -- 3. 第15天的订单及判定特征
  ------------------------------------------------------------------------------
  order_nd AS (
    SELECT
      a.driver_id                                    AS hxz_driver_id,
      a.cancel_type,
      a.cancel_time,
      a.answer_time,
      a.arrive_time,
      (unix_timestamp(a.cancel_time) - unix_timestamp(a.answer_time)) / 60.0
        AS cancel_after_answer_dur_min,
      b.feature['order_arrive_to_start_roud_dist_gt_than_thres_hxz']
        AS order_arrive_to_start_roud_dist_gt_than_thres_hxz,
      b.feature['order_passenger_late_time_snapshot']
        AS order_passenger_late_time_snapshot
    FROM kflower_dw.dwd_kf_trd_order_base_di a
    LEFT JOIN dd_cdm.dwd_trip_crs_jury_strategy_middleware_di b
      ON a.order_id = b.order_id
     AND b.dt = date_add('${BIZ_DATE_LINE}', 1)
     AND b.strategy_id    IN (11, 15)
     AND b.process_id     IN (7695, 7701)
     AND b.ihap_product_id IN (60010000,120030000,170010000,170020000)
    WHERE a.dt = date_add('${BIZ_DATE_LINE}', 1)
      AND a.product_1level <> 4
      AND (
        a.is_td_answer   = 1 OR
        a.is_td_cancel   = 1 OR
        a.is_td_reassign = 1 OR
        a.is_td_finish   = 1
      )
  ),

  ------------------------------------------------------------------------------
  -- 4. 标记后一天是否发生“长时取消”（0/1）
  ------------------------------------------------------------------------------
  next_day AS (
    SELECT
      hxz_driver_id            AS driver_id,
      MAX(
        CASE
          WHEN cancel_type = 3
           AND cancel_after_answer_dur_min >= 4
           AND (
             arrive_time = '0000-00-00 00:00:00'
             OR order_arrive_to_start_roud_dist_gt_than_thres_hxz = 1
             OR unix_timestamp(cancel_time) < order_passenger_late_time_snapshot
           )
          THEN 1
          ELSE 0
        END
      )                        AS next_day_long_flag
    FROM order_nd
    GROUP BY hxz_driver_id
  ),

  ------------------------------------------------------------------------------
  -- 5. 合并三套 driver_id（去重）
  ------------------------------------------------------------------------------
  all_drivers AS (
    SELECT l.driver_id         AS driver_id,
           l.long_cnt_14d,
           n.next_day_long_flag
    FROM long14 l
    JOIN next_day n
      ON l.driver_id = n.driver_id

    UNION

    SELECT m.didi_driver_id     AS driver_id,
           l.long_cnt_14d,
           n.next_day_long_flag
    FROM long14 l
    JOIN next_day n
      ON l.driver_id = n.driver_id
    JOIN kflower_strategy.pk_hxz_driver_id m
      ON l.driver_id = m.hxz_driver_id
     AND concat_ws('-', year, month, day) = date_sub(date('${NOW_DATE}'), 1)
    WHERE m.didi_driver_id IS NOT NULL

    UNION

    SELECT m.other_driver_id    AS driver_id,
           l.long_cnt_14d,
           n.next_day_long_flag
    FROM long14 l
    JOIN next_day n
      ON l.driver_id = n.driver_id
    JOIN kflower_strategy.pk_hxz_driver_id m
      ON l.driver_id = m.hxz_driver_id
     AND concat_ws('-', year, month, day) = date_sub(date('${NOW_DATE}'), 1)
    WHERE m.other_driver_id IS NOT NULL
  ),

  ------------------------------------------------------------------------------
  -- 6. 将第一段结果作为临时表 t0
  ------------------------------------------------------------------------------
  t0 AS (
    SELECT
      driver_id,
      long_cnt_14d,
      next_day_long_flag
    FROM all_drivers
  ),

  ------------------------------------------------------------------------------
  -- 7. 每笔订单级别计算 d_answer_cnt_14d
  ------------------------------------------------------------------------------
  modeling_per_order AS (
    SELECT
      driver_id,
      serial_type,
      d_serial_answer_cnt_14d,
      d_nonserial_answer_cnt_14d,
      (serial_type * d_serial_answer_cnt_14d
       + (1 - serial_type) * d_nonserial_answer_cnt_14d
      ) AS d_answer_cnt_14d
    FROM kflower_strategy.pk_hxz_modeling_data
    WHERE date_add(dt, 1) = '${BIZ_DATE_LINE}'
      AND is_finish IS NOT NULL
      AND (
           (serial_type = 1 AND d_serial_finish_cnt_14d    IS NOT NULL)
        OR (serial_type = 0 AND d_nonserial_finish_cnt_14d IS NOT NULL)
      )
  ),

  ------------------------------------------------------------------------------
  -- 8. 按司机取最大 d_answer_cnt_14d（driver 级一致值）
  ------------------------------------------------------------------------------
  modeling_drv AS (
    SELECT
      driver_id,
      MAX(d_answer_cnt_14d) AS d_answer_cnt_14d
    FROM modeling_per_order
    GROUP BY driver_id
  ),

  ------------------------------------------------------------------------------
  -- 9. 与 t0 左连接，映射 driver 级 answer 总数
  ------------------------------------------------------------------------------
  merged AS (
    SELECT
      t0.*,
      m.d_answer_cnt_14d
    FROM t0
    LEFT JOIN modeling_drv AS m
      ON t0.driver_id = m.driver_id
  ),

  ------------------------------------------------------------------------------
  -- 10. 过滤掉 d_answer_cnt_14d = 0 并计算 cancel_rate
  ------------------------------------------------------------------------------
  filtered AS (
    SELECT
      *,
      long_cnt_14d * 1.0 / d_answer_cnt_14d AS cancel_rate
    FROM merged
    WHERE d_answer_cnt_14d > 0
  ),

  ------------------------------------------------------------------------------
  -- 11. 定义阈值列表
  ------------------------------------------------------------------------------
  thresholds AS (
    SELECT 0      AS t UNION ALL
    SELECT 0.001       UNION ALL
    SELECT 0.01        UNION ALL
    SELECT 0.05        UNION ALL
    SELECT 0.1         UNION ALL
    SELECT 0.2         UNION ALL
    SELECT 0.3         UNION ALL
    SELECT 0.4         UNION ALL
    SELECT 0.5
  ),

  ------------------------------------------------------------------------------
  -- 12. 为每个阈值打 TP/TN/FP/FN 标签
  ------------------------------------------------------------------------------
  labeled AS (
    SELECT
      f.*,
      th.t,
      CASE
        WHEN f.cancel_rate  > th.t AND f.next_day_long_flag <> 0 THEN 'TP'
        WHEN f.cancel_rate <= th.t AND f.next_day_long_flag  = 0 THEN 'TN'
        WHEN f.cancel_rate  > th.t AND f.next_day_long_flag  = 0 THEN 'FP'
        WHEN f.cancel_rate <= th.t AND f.next_day_long_flag <> 0 THEN 'FN'
      END AS category
    FROM filtered f
    CROSS JOIN thresholds th
  )

-- 13. 最终：按 阈值 t 和 类别 category 统计司机数
SELECT
  t,
  category,
  COUNT(*) AS total_drivers
FROM labeled
GROUP BY t, category
ORDER BY t, category;
```

```SQL
 

-- 提高 shuffle 并行度，禁用自动广播 Join
SET spark.sql.shuffle.partitions = 500;
SET spark.sql.autoBroadcastJoinThreshold = -1;

WITH
  --------------------------------------------------------------------------------
  -- 1. 最近14天订单，用于 driver 级 long_cnt_14d
  --------------------------------------------------------------------------------
  order_14 AS (
    SELECT
      a.driver_id                                    AS hxz_driver_id,
      a.cancel_type,
      a.cancel_time,
      a.answer_time,
      a.arrive_time,
      (unix_timestamp(a.cancel_time) - unix_timestamp(a.answer_time)) / 60.0
        AS cancel_after_answer_dur_min,
      b.feature['order_arrive_to_start_roud_dist_gt_than_thres_hxz']
        AS order_arrive_to_start_roud_dist_gt_than_thres_hxz,
      b.feature['order_passenger_late_time_snapshot']
        AS order_passenger_late_time_snapshot
    FROM kflower_dw.dwd_kf_trd_order_base_di a
    LEFT JOIN dd_cdm.dwd_trip_crs_jury_strategy_middleware_di b
      ON a.order_id = b.order_id
     AND b.dt BETWEEN date_sub('${BIZ_DATE_LINE}', 13) AND '${BIZ_DATE_LINE}'
     AND b.strategy_id    IN (11,15)
     AND b.process_id     IN (7695,7701)
     AND b.ihap_product_id IN (60010000,120030000,170010000,170020000)
    WHERE a.dt BETWEEN date_sub('${BIZ_DATE_LINE}', 13) AND '${BIZ_DATE_LINE}'
      AND a.product_1level <> 4
      AND (a.is_td_answer=1 OR a.is_td_cancel=1 OR a.is_td_reassign=1 OR a.is_td_finish=1)
  ),

  long14 AS (
    SELECT
      hxz_driver_id            AS driver_id,
      SUM(
        CASE WHEN cancel_type=3
                  AND cancel_after_answer_dur_min>=4
                  AND (
                    arrive_time='0000-00-00 00:00:00'
                    OR order_arrive_to_start_roud_dist_gt_than_thres_hxz=1
                    OR unix_timestamp(cancel_time)<order_passenger_late_time_snapshot
                  )
             THEN 1 ELSE 0
        END
      )                        AS long_cnt_14d
    FROM order_14
    GROUP BY hxz_driver_id
  ),

  --------------------------------------------------------------------------------
  -- 2. 第15天订单，用于 driver 级 next_day_long_flag + 订单级 is_order_long_cancel
  --------------------------------------------------------------------------------
  order_nd AS (
    SELECT
      a.order_id,
      a.driver_id                                    AS hxz_driver_id,
      a.cancel_type,
      a.cancel_time,
      a.answer_time,
      a.arrive_time,
      (unix_timestamp(a.cancel_time) - unix_timestamp(a.answer_time)) / 60.0
        AS cancel_after_answer_dur_min,
      b.feature['order_arrive_to_start_roud_dist_gt_than_thres_hxz']
        AS order_arrive_to_start_roud_dist_gt_than_thres_hxz,
      b.feature['order_passenger_late_time_snapshot']
        AS order_passenger_late_time_snapshot
    FROM kflower_dw.dwd_kf_trd_order_base_di a
    LEFT JOIN dd_cdm.dwd_trip_crs_jury_strategy_middleware_di b
      ON a.order_id = b.order_id
     AND b.dt = date_add('${BIZ_DATE_LINE}', 1)
     AND b.strategy_id    IN (11,15)
     AND b.process_id     IN (7695,7701)
     AND b.ihap_product_id IN (60010000,120030000,170010000,170020000)
    WHERE a.dt = date_add('${BIZ_DATE_LINE}', 1)
      AND a.product_1level <> 4
      AND (a.is_td_answer=1 OR a.is_td_cancel=1 OR a.is_td_reassign=1 OR a.is_td_finish=1)
  ),

  next_day AS (
    SELECT
      hxz_driver_id            AS driver_id,
      MAX(
        CASE WHEN cancel_type=3
                  AND cancel_after_answer_dur_min>=4
                  AND (
                    arrive_time='0000-00-00 00:00:00'
                    OR order_arrive_to_start_roud_dist_gt_than_thres_hxz=1
                    OR unix_timestamp(cancel_time)<order_passenger_late_time_snapshot
                  )
             THEN 1 ELSE 0
        END
      )                        AS next_day_long_flag
    FROM order_nd
    GROUP BY hxz_driver_id
  ),

  --------------------------------------------------------------------------------
  -- 3. 构建 t0：驱动级特征映射回每笔订单，并剔除 NULL
  --------------------------------------------------------------------------------
  t0 AS (
    SELECT
      o.order_id,
      o.hxz_driver_id         AS driver_id,
      l.long_cnt_14d,
      n.next_day_long_flag,
      -- 订单级长时取消标记
      CASE
        WHEN o.cancel_type=3
         AND o.cancel_after_answer_dur_min>=4
         AND (
           o.arrive_time='0000-00-00 00:00:00'
           OR o.order_arrive_to_start_roud_dist_gt_than_thres_hxz=1
           OR unix_timestamp(o.cancel_time)<o.order_passenger_late_time_snapshot
         )
        THEN 1 ELSE 0
      END                     AS is_order_long_cancel
    FROM order_nd o
    LEFT JOIN long14 l ON o.hxz_driver_id=l.driver_id
    LEFT JOIN next_day n ON o.hxz_driver_id=n.driver_id
    WHERE l.long_cnt_14d IS NOT NULL
      AND n.next_day_long_flag IS NOT NULL
  ),

  --------------------------------------------------------------------------------
  -- 4. 计算 driver 级 d_answer_cnt_14d
  --------------------------------------------------------------------------------
  modeling_per_order AS (
    SELECT
      driver_id,
      (serial_type * d_serial_answer_cnt_14d
       + (1 - serial_type) * d_nonserial_answer_cnt_14d
      )                          AS d_answer_cnt_14d
    FROM kflower_strategy.pk_hxz_modeling_data
    WHERE date_add(dt,1)= date_add('${BIZ_DATE_LINE}', 1)
      AND is_finish IS NOT NULL
      AND (
           (serial_type=1 AND d_serial_finish_cnt_14d    IS NOT NULL)
        OR (serial_type=0 AND d_nonserial_finish_cnt_14d IS NOT NULL)
      )
  ),

  modeling_drv AS (
    SELECT driver_id, MAX(d_answer_cnt_14d) AS d_answer_cnt_14d
    FROM modeling_per_order
    GROUP BY driver_id
  ),

  --------------------------------------------------------------------------------
  -- 5. 合并 t0 与 驱动级答单数 → merged
  --------------------------------------------------------------------------------
  merged AS (
    SELECT
      t0.*,
      m.d_answer_cnt_14d
    FROM t0
    LEFT JOIN modeling_drv m
      ON t0.driver_id = m.driver_id
  ),

  --------------------------------------------------------------------------------
  -- 6. 过滤并计算 cancel_rate
  --------------------------------------------------------------------------------
  filtered_metrics AS (
    SELECT
      *,
      long_cnt_14d * 1.0 / d_answer_cnt_14d AS cancel_rate
    FROM merged
    WHERE d_answer_cnt_14d > 0
  ),

  --------------------------------------------------------------------------------
  -- 7. 定义阈值 & TP/TN/FP/FN 分类
  --------------------------------------------------------------------------------
  thresholds AS (
    SELECT 0     AS t UNION ALL
    SELECT 0.001 UNION ALL
    SELECT 0.01  UNION ALL
    SELECT 0.05  UNION ALL
    SELECT 0.1   UNION ALL
    SELECT 0.2   UNION ALL
    SELECT 0.3   UNION ALL
    SELECT 0.4   UNION ALL
    SELECT 0.5
  ),

  labeled AS (
    SELECT
      f.*,
      th.t,
      CASE
        WHEN f.cancel_rate  > th.t AND f.next_day_long_flag<>0 THEN 'TP'
        WHEN f.cancel_rate <= th.t AND f.next_day_long_flag =0 THEN 'TN'
        WHEN f.cancel_rate  > th.t AND f.next_day_long_flag =0 THEN 'FP'
        WHEN f.cancel_rate <= th.t AND f.next_day_long_flag<>0 THEN 'FN'
      END AS category
    FROM filtered_metrics f
    CROSS JOIN thresholds th
  )

-- 8. 最终：统计订单数 & 长时取消订单数
SELECT
  t,
  category,
  COUNT(*)                   AS total_orders,
  SUM(is_order_long_cancel)  AS long_cancel_orders
FROM labeled
GROUP BY t, category
ORDER BY t, category;
```

## 说明的问题

#### 1.从相关系数来看，长时取消的相关系数一直随着历史时间窗口的增加而增加，且相关系数始终低于0.07，从分析中可以看出：

- 司机历史长时取消数和未来一天司机是否会长时取消的相关性低

- 长时取消的数量本身比诱导取消的数量要少很多，历史时间窗口甚至延长到28天，相关系数仍然较低，历史时段长时取消为0的样本仍然较多

#### 2.从司机数的准召和从订单数的准召来看在阈值为0时，订单召回有28.4%，低于诱导取消的54%，当阈值调到0.1时，召回已经跌到1.2%，明显低于诱导取消阈值0.1时的召回（37.9%），并且在阈值变动很小时，例如从0到0.01，0.05时，召回的变动也非常大，对应的召回从28.4%变为18.6%，3.5%

- 说明长时取消率的取值范围极小，即使对长时取消添加了较高的权重，但效果仍然不够明显
