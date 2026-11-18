---
title: "联合随机实验 冒泡 SDS 特征日志验证"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2208671191414
cssclasses: ["strategy-body-note"]
---

# 联合随机实验 冒泡 SDS 特征日志验证

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2208671191414)

**阅读定位**　[[#最终结论|最终结论]] · [[#目的|目的]] · [[#数据口径|数据口径]] · [[#验证特征列表|验证特征列表]] · [[#分析一：冒泡 SDS 特征覆盖率|分析一：冒泡 SDS 特征覆盖率]] · [[#分析二：特征质量（空值率与非空均值）|分析二：特征质量（空值率与非空均值）]] · [[#分析三：feature_data 为空的场景分布|分析三：feature_data 为空的场景分布]] · [[#分析四：以去重冒泡宽表为基准的 SDS 特征覆盖率|分析四：以去重冒泡宽表为基准的 SDS 特征覆盖率]]

## 最终结论

**RCT 预估场景冒泡的 SDS 特征取值完全正常，可以支撑上线。**

1. **特征覆盖率**：以冒泡宽表（预估场景）的 11,379 条去重 trace 为基准，日志匹配率、SDS 调用成功率、feature_data 有效率均为 **100%**。

2. **特征质量**：32 个特征的 key 缺失率均为 0，-9999 缺失率最高仅 0.01%。0/-9999/null 值率在 3.67%～100% 之间，其中 3 个 `order_create` 特征全为 0；`passenger_bubble_unique_cnt` 仅 3.67%，数据最健康；其余特征均在 64%～93%，非空非 0 均值符合业务预期（金额类 350～2420，时间类 26～38s，司机数 2～7）。

3. **feature_data 为空的原因**：从全量日志看，40% 的 trace 的 feature_data 为空，经排查均来自**修改目的地（97.3%）和等待应答（2.7%）场景**，与预估冒泡无关。该问题需单独跟进工程侧确认这两个场景是否需要支持 SDS 特征下发。

---

## 目的

验证 RCT 组的冒泡 trace 是否可以正常取到商家维度的 SDS 特征，包括：

1. 所有冒泡是否都有对应的 SDS 特征（覆盖率）

2. 各特征的空值率与非空均值是否正常

相关文档：

- 需求文档：https://cooper.didichuxing.com/knowledge/2199610335356/2208391398047

- 工程开发文档：https://cooper.didichuxing.com/knowledge/2200004056890/2208607348033

---

## 数据口径

- **日志表**：`kflower_marketplace.ods_log_kflower_platform_call_return_public_log_h`

- **时间**：2026-07-04 10点（`year='2026' AND month='07' AND day='04' AND hour='10'`）

- **实验组**：`get_json_object(param['flow_control'], '$.ExpGroupName') = 'union_stg_v3_max_order_v1_only_box_rct'`

- **SDS 特征路径**：`param['feature_ar_sds']` → `$.detail_log.feature_data` → `{product_id: {feature_name: value}}`，JSON 结构详见 public.json

---

## 验证特征列表

共 32 个特征，分两类：

**实时特征**（后缀 `_one_circle_grid`，10 个）：

```PlainText
realtime_lucky_box_driver_active_auto_assign_cnt_one_circle_grid
realtime_lucky_box_driver_active_half_assign_cnt_one_circle_grid
realtime_special_offer_box_driver_active_auto_assign_cnt_one_circle_grid
realtime_special_offer_box_driver_active_half_assign_cnt_one_circle_grid
realtime_active_driver_cnt_one_circle_grid
realtime_lucky_box_driver_empty_auto_assign_cnt_one_circle_grid
realtime_lucky_box_driver_empty_half_assign_cnt_one_circle_grid
realtime_special_offer_box_driver_empty_auto_assign_cnt_one_circle_grid
realtime_special_offer_box_driver_empty_half_assign_cnt_one_circle_grid
realtime_idle_driver_cnt_one_circle_grid
```

**交易漏斗 10 分钟特征**（后缀 `_one_circle_grid`，22 个）：

> [!example]- PlainText 实现细节（22 行）
> ```PlainText
> passenger_bubble_unique_cnt_10m_one_circle_grid
> lucky_box_order_create_cnt_10min_one_circle_grid
> special_offer_box_order_create_cnt_10min_one_circle_grid
> non_lucky_special_box_order_create_cnt_10min_one_circle_grid
> lucky_box_duse_pk_driver_unique_cnt_10min_one_circle_grid
> special_offer_box_duse_pk_driver_unique_cnt_10min_one_circle_grid
> non_lucky_special_box_duse_pk_driver_unique_cnt_10min_one_circle_grid
> lucky_box_strive_order_cnt_10min_one_circle_grid
> special_offer_box_strive_order_cnt_10min_one_circle_grid
> non_lucky_special_box_strive_order_cnt_10min_one_circle_grid
> lucky_box_finish_order_cnt_10min_one_circle_grid
> special_offer_box_finish_order_cnt_10min_one_circle_grid
> non_lucky_special_box_finish_order_cnt_10min_one_circle_grid
> lucky_box_srived_order_ept_sum_10min_one_circle_grid
> special_offer_box_srived_order_ept_sum_10min_one_circle_grid
> non_lucky_special_box_srived_order_ept_sum_10min_one_circle_grid
> lucky_box_srived_order_epd_sum_10min_one_circle_grid
> special_offer_box_srived_order_epd_sum_10min_one_circle_grid
> non_lucky_special_box_srived_order_epd_sum_10min_one_circle_grid
> lucky_box_strive_order_time_sum_10min_one_circle_grid
> special_offer_box_strive_order_time_sum_10min_one_circle_grid
> non_lucky_special_box_strive_order_time_sum_10min_one_circle_grid
> ```


完整 SQL 见 [sds_feature_validation.sql](../../../02.%20%E4%BA%A4%E6%98%93%E4%B8%93%E9%A1%B9%E4%B8%8E%E6%A8%A1%E5%9E%8B%E8%87%AA%E8%BF%9B%E5%8C%96/03.%20%E4%BB%B7%E6%A0%BC%E9%94%9A%E7%82%B9/07.%20%E5%B9%B3%E5%8F%B0%E8%81%94%E5%90%88%E5%86%B3%E7%AD%96/%E5%B9%B3%E5%8F%B0%E8%A1%A5%E8%B4%B4%E4%B8%8E%E6%B5%81%E9%87%8F%E5%88%86%E5%8F%91%E8%81%94%E5%90%88%E5%86%B3%E7%AD%96V4/BCR%E6%A8%A1%E5%9E%8B/%E6%A0%B7%E6%9C%AC-%E4%BB%B7%E6%A0%BC%E5%88%97%E8%A1%A8%E6%9E%84%E9%80%A0/sds_feature_validation.sql)。

---

## 分析一：冒泡 SDS 特征覆盖率

**SQL 口径**

```SQL
WITH base AS (
    SELECT
        param['traceid']                                                                AS traceid,
        get_json_object(param['feature_ar_sds'], '$.error_no')                         AS error_no,
        get_json_object(param['feature_ar_sds'], '$.error_msg')                        AS error_msg,
        get_json_object(param['feature_ar_sds'], '$.detail_log.feature_data')          AS feature_data_json
    FROM kflower_marketplace.ods_log_kflower_platform_call_return_public_log_h
    WHERE year = '2026' AND month = '07' AND day = '05' AND hour = '10'
      AND param['traceid'] IS NOT NULL
      AND get_json_object(param['flow_control'], '$.ExpGroupName') = 'union_stg_v3_max_order_v1_only_box_rct'
)
SELECT
    COUNT(*)                                                                                       AS total_bubble_cnt,
    SUM(CASE WHEN error_no = '0' THEN 1 ELSE 0 END)                                               AS sds_success_cnt,
    SUM(CASE WHEN error_no IS NULL OR error_no != '0' THEN 1 ELSE 0 END)                          AS sds_fail_cnt,
    ROUND(SUM(CASE WHEN error_no = '0' THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 4)                   AS sds_success_rate,
    SUM(CASE WHEN error_no = '0'
              AND (feature_data_json IS NULL OR feature_data_json = 'null' OR feature_data_json = '{}')
             THEN 1 ELSE 0 END)                                                                    AS sds_success_but_empty_feature_cnt,
    COUNT(CASE WHEN error_no IS NULL OR error_no != '0' THEN error_msg END)                        AS sds_fail_with_msg_cnt
FROM base;
```

**结论**

- SDS 服务调用成功率 100%，无失败。

- 但有 **40% 的冒泡 trace 的 feature_data 为空**，即 SDS 返回成功但未带回任何商家特征，需结合分析三排查原因。

- 剩余 15,660 条 trace 有特征数据，平均每条 trace 约 27.8 个商家。

| 指标 | 数值 |
| --- | --- |
| 冒泡总数 | 26,094 |
| SDS 调用成功（error_no=0） | 26,094（**100%**） |
| SDS 调用失败 | 0 |
| 成功但 feature_data 为空 | 10,434（**40.0%**） |

---

## 分析二：特征质量（空值率与非空均值）

[v4_feature_quality_20260707162448.csv](60bed00933ea1494-v4_feature_quality_20260707162448.csv)

**SQL 口径**

注意 `-9999` 为特征平台约定的"无数据"占位值，与 NULL 分开统计。

> [!example]- SQL 实现细节（128 行）
> ```SQL
> WITH base AS (
>     SELECT
>         param['traceid']                                                                AS traceid,
>         get_json_object(param['feature_ar_sds'], '$.error_no')                         AS error_no,
>         get_json_object(param['feature_ar_sds'], '$.detail_log.feature_data')          AS feature_data_json
>     FROM kflower_marketplace.ods_log_kflower_platform_call_return_public_log_h
>     WHERE year = '2026' AND month = '07' AND day = '05' AND hour = '10'
>       AND param['traceid'] IS NOT NULL
>       AND get_json_object(param['flow_control'], '$.ExpGroupName') = 'union_stg_v3_max_order_v1_only_box_rct'
>       AND get_json_object(param['feature_ar_sds'], '$.error_no') = '0'
> ),
> merchant_level AS (
>     SELECT
>         traceid,
>         product_id,
>         merchant_features
>     FROM base
>     LATERAL VIEW explode(
>         from_json(feature_data_json, 'MAP<STRING, MAP<STRING, STRING>>')
>     ) t AS product_id, merchant_features
>     WHERE feature_data_json IS NOT NULL
>       AND feature_data_json != 'null'
>       AND feature_data_json != '{}'
> ),
> feature_wide AS (
>     SELECT
>         traceid,
>         product_id,
>         merchant_features['realtime_lucky_box_driver_active_auto_assign_cnt_one_circle_grid']           AS realtime_lucky_box_driver_active_auto_assign_cnt_one_circle_grid,
>         merchant_features['realtime_lucky_box_driver_active_half_assign_cnt_one_circle_grid']           AS realtime_lucky_box_driver_active_half_assign_cnt_one_circle_grid,
>         merchant_features['realtime_special_offer_box_driver_active_auto_assign_cnt_one_circle_grid']   AS realtime_special_offer_box_driver_active_auto_assign_cnt_one_circle_grid,
>         merchant_features['realtime_special_offer_box_driver_active_half_assign_cnt_one_circle_grid']   AS realtime_special_offer_box_driver_active_half_assign_cnt_one_circle_grid,
>         merchant_features['realtime_active_driver_cnt_one_circle_grid']                                 AS realtime_active_driver_cnt_one_circle_grid,
>         merchant_features['realtime_lucky_box_driver_empty_auto_assign_cnt_one_circle_grid']            AS realtime_lucky_box_driver_empty_auto_assign_cnt_one_circle_grid,
>         merchant_features['realtime_lucky_box_driver_empty_half_assign_cnt_one_circle_grid']            AS realtime_lucky_box_driver_empty_half_assign_cnt_one_circle_grid,
>         merchant_features['realtime_special_offer_box_driver_empty_auto_assign_cnt_one_circle_grid']    AS realtime_special_offer_box_driver_empty_auto_assign_cnt_one_circle_grid,
>         merchant_features['realtime_special_offer_box_driver_empty_half_assign_cnt_one_circle_grid']    AS realtime_special_offer_box_driver_empty_half_assign_cnt_one_circle_grid,
>         merchant_features['realtime_idle_driver_cnt_one_circle_grid']                                   AS realtime_idle_driver_cnt_one_circle_grid,
>         merchant_features['passenger_bubble_unique_cnt_10m_one_circle_grid']                            AS passenger_bubble_unique_cnt_10m_one_circle_grid,
>         merchant_features['lucky_box_order_create_cnt_10min_one_circle_grid']                           AS lucky_box_order_create_cnt_10min_one_circle_grid,
>         merchant_features['special_offer_box_order_create_cnt_10min_one_circle_grid']                   AS special_offer_box_order_create_cnt_10min_one_circle_grid,
>         merchant_features['non_lucky_special_box_order_create_cnt_10min_one_circle_grid']               AS non_lucky_special_box_order_create_cnt_10min_one_circle_grid,
>         merchant_features['lucky_box_duse_pk_driver_unique_cnt_10min_one_circle_grid']                  AS lucky_box_duse_pk_driver_unique_cnt_10min_one_circle_grid,
>         merchant_features['special_offer_box_duse_pk_driver_unique_cnt_10min_one_circle_grid']          AS special_offer_box_duse_pk_driver_unique_cnt_10min_one_circle_grid,
>         merchant_features['non_lucky_special_box_duse_pk_driver_unique_cnt_10min_one_circle_grid']      AS non_lucky_special_box_duse_pk_driver_unique_cnt_10min_one_circle_grid,
>         merchant_features['lucky_box_strive_order_cnt_10min_one_circle_grid']                           AS lucky_box_strive_order_cnt_10min_one_circle_grid,
>         merchant_features['special_offer_box_strive_order_cnt_10min_one_circle_grid']                   AS special_offer_box_strive_order_cnt_10min_one_circle_grid,
>         merchant_features['non_lucky_special_box_strive_order_cnt_10min_one_circle_grid']               AS non_lucky_special_box_strive_order_cnt_10min_one_circle_grid,
>         merchant_features['lucky_box_finish_order_cnt_10min_one_circle_grid']                           AS lucky_box_finish_order_cnt_10min_one_circle_grid,
>         merchant_features['special_offer_box_finish_order_cnt_10min_one_circle_grid']                   AS special_offer_box_finish_order_cnt_10min_one_circle_grid,
>         merchant_features['non_lucky_special_box_finish_order_cnt_10min_one_circle_grid']               AS non_lucky_special_box_finish_order_cnt_10min_one_circle_grid,
>         merchant_features['lucky_box_srived_order_ept_sum_10min_one_circle_grid']                       AS lucky_box_srived_order_ept_sum_10min_one_circle_grid,
>         merchant_features['special_offer_box_srived_order_ept_sum_10min_one_circle_grid']               AS special_offer_box_srived_order_ept_sum_10min_one_circle_grid,
>         merchant_features['non_lucky_special_box_srived_order_ept_sum_10min_one_circle_grid']           AS non_lucky_special_box_srived_order_ept_sum_10min_one_circle_grid,
>         merchant_features['lucky_box_srived_order_epd_sum_10min_one_circle_grid']                       AS lucky_box_srived_order_epd_sum_10min_one_circle_grid,
>         merchant_features['special_offer_box_srived_order_epd_sum_10min_one_circle_grid']               AS special_offer_box_srived_order_epd_sum_10min_one_circle_grid,
>         merchant_features['non_lucky_special_box_srived_order_epd_sum_10min_one_circle_grid']           AS non_lucky_special_box_srived_order_epd_sum_10min_one_circle_grid,
>         merchant_features['lucky_box_strive_order_time_sum_10min_one_circle_grid']                      AS lucky_box_strive_order_time_sum_10min_one_circle_grid,
>         merchant_features['special_offer_box_strive_order_time_sum_10min_one_circle_grid']              AS special_offer_box_strive_order_time_sum_10min_one_circle_grid,
>         merchant_features['non_lucky_special_box_strive_order_time_sum_10min_one_circle_grid']          AS non_lucky_special_box_strive_order_time_sum_10min_one_circle_grid
>     FROM merchant_level
> ),
> feature_long AS (
>     SELECT feature_name, feature_value
>     FROM feature_wide
>     LATERAL VIEW STACK(
>         32,
>         'realtime_lucky_box_driver_active_auto_assign_cnt_one_circle_grid',         realtime_lucky_box_driver_active_auto_assign_cnt_one_circle_grid,
>         'realtime_lucky_box_driver_active_half_assign_cnt_one_circle_grid',          realtime_lucky_box_driver_active_half_assign_cnt_one_circle_grid,
>         'realtime_special_offer_box_driver_active_auto_assign_cnt_one_circle_grid',  realtime_special_offer_box_driver_active_auto_assign_cnt_one_circle_grid,
>         'realtime_special_offer_box_driver_active_half_assign_cnt_one_circle_grid',  realtime_special_offer_box_driver_active_half_assign_cnt_one_circle_grid,
>         'realtime_active_driver_cnt_one_circle_grid',                                realtime_active_driver_cnt_one_circle_grid,
>         'realtime_lucky_box_driver_empty_auto_assign_cnt_one_circle_grid',           realtime_lucky_box_driver_empty_auto_assign_cnt_one_circle_grid,
>         'realtime_lucky_box_driver_empty_half_assign_cnt_one_circle_grid',           realtime_lucky_box_driver_empty_half_assign_cnt_one_circle_grid,
>         'realtime_special_offer_box_driver_empty_auto_assign_cnt_one_circle_grid',   realtime_special_offer_box_driver_empty_auto_assign_cnt_one_circle_grid,
>         'realtime_special_offer_box_driver_empty_half_assign_cnt_one_circle_grid',   realtime_special_offer_box_driver_empty_half_assign_cnt_one_circle_grid,
>         'realtime_idle_driver_cnt_one_circle_grid',                                  realtime_idle_driver_cnt_one_circle_grid,
>         'passenger_bubble_unique_cnt_10m_one_circle_grid',                           passenger_bubble_unique_cnt_10m_one_circle_grid,
>         'lucky_box_order_create_cnt_10min_one_circle_grid',                          lucky_box_order_create_cnt_10min_one_circle_grid,
>         'special_offer_box_order_create_cnt_10min_one_circle_grid',                  special_offer_box_order_create_cnt_10min_one_circle_grid,
>         'non_lucky_special_box_order_create_cnt_10min_one_circle_grid',              non_lucky_special_box_order_create_cnt_10min_one_circle_grid,
>         'lucky_box_duse_pk_driver_unique_cnt_10min_one_circle_grid',                 lucky_box_duse_pk_driver_unique_cnt_10min_one_circle_grid,
>         'special_offer_box_duse_pk_driver_unique_cnt_10min_one_circle_grid',         special_offer_box_duse_pk_driver_unique_cnt_10min_one_circle_grid,
>         'non_lucky_special_box_duse_pk_driver_unique_cnt_10min_one_circle_grid',     non_lucky_special_box_duse_pk_driver_unique_cnt_10min_one_circle_grid,
>         'lucky_box_strive_order_cnt_10min_one_circle_grid',                          lucky_box_strive_order_cnt_10min_one_circle_grid,
>         'special_offer_box_strive_order_cnt_10min_one_circle_grid',                  special_offer_box_strive_order_cnt_10min_one_circle_grid,
>         'non_lucky_special_box_strive_order_cnt_10min_one_circle_grid',              non_lucky_special_box_strive_order_cnt_10min_one_circle_grid,
>         'lucky_box_finish_order_cnt_10min_one_circle_grid',                          lucky_box_finish_order_cnt_10min_one_circle_grid,
>         'special_offer_box_finish_order_cnt_10min_one_circle_grid',                  special_offer_box_finish_order_cnt_10min_one_circle_grid,
>         'non_lucky_special_box_finish_order_cnt_10min_one_circle_grid',              non_lucky_special_box_finish_order_cnt_10min_one_circle_grid,
>         'lucky_box_srived_order_ept_sum_10min_one_circle_grid',                      lucky_box_srived_order_ept_sum_10min_one_circle_grid,
>         'special_offer_box_srived_order_ept_sum_10min_one_circle_grid',              special_offer_box_srived_order_ept_sum_10min_one_circle_grid,
>         'non_lucky_special_box_srived_order_ept_sum_10min_one_circle_grid',          non_lucky_special_box_srived_order_ept_sum_10min_one_circle_grid,
>         'lucky_box_srived_order_epd_sum_10min_one_circle_grid',                      lucky_box_srived_order_epd_sum_10min_one_circle_grid,
>         'special_offer_box_srived_order_epd_sum_10min_one_circle_grid',              special_offer_box_srived_order_epd_sum_10min_one_circle_grid,
>         'non_lucky_special_box_srived_order_epd_sum_10min_one_circle_grid',          non_lucky_special_box_srived_order_epd_sum_10min_one_circle_grid,
>         'lucky_box_strive_order_time_sum_10min_one_circle_grid',                     lucky_box_strive_order_time_sum_10min_one_circle_grid,
>         'special_offer_box_strive_order_time_sum_10min_one_circle_grid',             special_offer_box_strive_order_time_sum_10min_one_circle_grid,
>         'non_lucky_special_box_strive_order_time_sum_10min_one_circle_grid',         non_lucky_special_box_strive_order_time_sum_10min_one_circle_grid
>     ) t AS feature_name, feature_value
> )
> SELECT
>     feature_name,
>     COUNT(*)                                                                                                  AS total_cnt,
>     SUM(CASE WHEN feature_value IS NULL THEN 1 ELSE 0 END)                                                   AS null_cnt,
>     SUM(CASE WHEN feature_value = '-9999' THEN 1 ELSE 0 END)                                                 AS missing_val_cnt,
>     SUM(CASE WHEN feature_value IS NOT NULL AND feature_value != '-9999' THEN 1 ELSE 0 END)                  AS valid_cnt,
>     ROUND(SUM(CASE WHEN feature_value IS NULL THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 4)                       AS null_rate,
>     ROUND(SUM(CASE WHEN feature_value = '-9999' THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 4)                     AS missing_rate,
>     ROUND(
>         (SUM(CASE WHEN feature_value IS NULL THEN 1 ELSE 0 END)
>     + SUM(CASE WHEN feature_value = '-9999' THEN 1 ELSE 0 END)) * 1.0 / COUNT(*), 4
>     )                                                                                                          AS total_invalid_rate,
>     ROUND(
>         AVG(CASE WHEN feature_value IS NOT NULL AND feature_value != '-9999'
>                  THEN CAST(feature_value AS DOUBLE) END), 4
>     )                                                                                                          AS non_null_mean,          -- 有效值均值（含0）
>     ROUND(
>         SUM(CASE WHEN feature_value IS NULL OR feature_value = '-9999' OR feature_value = '0'
>                  THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 4
>     )                                                                                                          AS zero_missing_null_rate, -- 0/-9999/null值率
>     ROUND(
>         AVG(CASE WHEN feature_value IS NOT NULL AND feature_value != '-9999' AND feature_value != '0'
>                  THEN CAST(feature_value AS DOUBLE) END), 4
>     )                                                                                                          AS non_null_non_zero_mean  -- 非空非0均值
> FROM feature_long
> GROUP BY feature_name
> ORDER BY feature_name;
> ```


**结论**

基于 434,664 条 product 维度记录（来自有 feature_data 的 15,660 条 trace），32 个特征均可正常取到，整体质量良好。关键发现：

- **key 缺失率全部为 0**，所有特征均正常下发。

- **-9999 缺失率极低**（最高 0.01%），可忽略。

- **0/-9999/null 值率**方面分化明显：3 个 `order_create` 类特征 0 值率达 **100%**，反映该时段三类 box 几乎无下单，属正常业务现象；其余特征集中在 **64%～93%**；`passenger_bubble_unique_cnt` 仅 **3.67%**，几乎所有商家都有非零冒泡数，数据最健康。

- **非空非 0 均值**：金额类（epd/ept sum）在 350～2420 之间，时间类在 26～38 秒，司机数在 2～7 之间，均符合业务预期。

| 指标 | 结论 |
| --- | --- |
| key 缺失率（null_rate） | 所有 32 个特征均为 **0**，无 key 缺失 |
| - 9999 缺失率（missing_rate） <br> | 所有特征均 ≤ 0.0001（最高约 **0.01%**），极低 |
| 总无效率（total_invalid_rate） | 所有特征均 ≤ 0.0001 |
| 0/-9999/null 值率（zero_missing_null_rate） | 3.67%～100%，分化明显（详见下表） |
| 非空非 0 均值（non_null_non_zero_mean） | order_create 类为 null（全0），其余均有合理数值 |

各类特征概览：

| 特征类型 | 代表特征 | 0/-9999/null 值率 | 非空非0均值 |
| --- | --- | --- | --- |
| 冒泡数 | passenger_bubble_unique_cnt_10m | **3.67%** | 60.3 |
| 活跃司机数 | realtime_active_driver_cnt | 64.3% | 6.85 |
| lucky_box 司机数 | realtime_lucky_box_driver_active_auto | 74.4% | 4.90 |
| 成交金额 | lucky_box_srived_order_epd_sum | 87.4% | 2420 |
| 特惠 box 成交金额 | special_offer_box_srived_order_epd_sum | 87.8% | 1952 |
| 下单数 | lucky/special/non_lucky box_order_create | **100%** | null（全0，该时段无下单） |

---

## 分析三：feature_data 为空的场景分布

**SQL 口径**

```SQL
WITH base AS (
    SELECT
        param['call_return_scene_type']                                                 AS call_return_scene_type,
        get_json_object(param['feature_ar_sds'], '$.error_no')                         AS error_no,
        get_json_object(param['feature_ar_sds'], '$.detail_log.feature_data')          AS feature_data_json
    FROM kflower_marketplace.ods_log_kflower_platform_call_return_public_log_h
    WHERE year = '2026' AND month = '07' AND day = '05' AND hour = '10'
      AND param['traceid'] IS NOT NULL
      AND get_json_object(param['flow_control'], '$.ExpGroupName') = 'union_stg_v3_max_order_v1_only_box_rct'
      AND get_json_object(param['feature_ar_sds'], '$.error_no') = '0'
)
SELECT
    call_return_scene_type,
    COUNT(*)                                                AS empty_feature_cnt,
    ROUND(COUNT(*) * 1.0 / SUM(COUNT(*)) OVER (), 4)      AS pct
FROM base
WHERE feature_data_json IS NULL
   OR feature_data_json = 'null'
   OR feature_data_json = '{}'
GROUP BY call_return_scene_type
ORDER BY empty_feature_cnt DESC;
```

**结论**

feature_data 为空的 10,434 条 trace 全部集中在场景类型 2 和 4，不涉及预估场景（1）：

- feature_data 为空几乎完全由**修改目的地**场景贡献（97.3%），该场景下 SDS 调用成功但未返回商家特征，可能是该场景不在 SDS 特征覆盖范围内，需确认工程侧是否支持该场景的特征下发。

- **预估场景（1）feature_data 全部正常**，不受影响。

| call_return_scene_type | 场景 | 空特征数 | 占比 |
| --- | --- | --- | --- |
| 4 | 修改目的地 | 10,150 | **97.3%** |
| 2 | 等待应答 | 284 | 2.7% |
| 1 | 预估 | 0 | 0% |

## 分析四：以去重冒泡宽表为基准的 SDS 特征覆盖率

以 `plft_v4_bubble_vehicle_info` 作为冒泡的权威来源，左连日志表，可额外识别日志中完全缺失的 trace。

**SQL 口径**

> [!example]- SQL 实现细节（41 行）
> ```SQL
> WITH bubble_list AS (
>     -- 冒泡宽表，作为基准集合
>     SELECT DISTINCT trace_id
>     FROM kflower_strategy.plft_v4_bubble_vehicle_info
>     WHERE dt = '2026-07-04'
> ),
> log_data AS (
>     -- 日志表，提取 SDS 特征信息
>     SELECT
>         param['traceid']                                                                AS traceid,
>         get_json_object(param['feature_ar_sds'], '$.error_no')                         AS error_no,
>         get_json_object(param['feature_ar_sds'], '$.detail_log.feature_data')          AS feature_data_json
>     FROM kflower_marketplace.ods_log_kflower_platform_call_return_public_log_h
>     WHERE year = '2026' AND month = '07' AND day = '04' AND hour = '10'
>       AND param['traceid'] IS NOT NULL
>       AND get_json_object(param['flow_control'], '$.ExpGroupName') = 'union_stg_v3_max_order_v1_only_box_rct'
> )
> SELECT
>     COUNT(DISTINCT b.trace_id)                                                                        AS total_bubble_cnt,       -- 宽表冒泡总数
>     COUNT(DISTINCT CASE WHEN l.traceid IS NOT NULL THEN b.trace_id END)                               AS log_matched_cnt,        -- 日志中有记录的 trace
>     COUNT(DISTINCT CASE WHEN l.traceid IS NULL THEN b.trace_id END)                                   AS log_unmatched_cnt,      -- 日志中完全缺失的 trace
>     COUNT(DISTINCT CASE WHEN l.error_no = '0' THEN b.trace_id END)                                   AS sds_success_cnt,        -- SDS 调用成功
>     COUNT(DISTINCT CASE WHEN l.error_no IS NULL OR l.error_no != '0' THEN b.trace_id END)             AS sds_fail_cnt,           -- SDS 调用失败或无记录
>     COUNT(DISTINCT CASE WHEN l.error_no = '0'
>                          AND (l.feature_data_json IS NULL
>                               OR l.feature_data_json = 'null'
>                               OR l.feature_data_json = '{}')
>                         THEN b.trace_id END)                                                           AS sds_success_empty_cnt,  -- SDS 成功但 feature_data 为空
>     COUNT(DISTINCT CASE WHEN l.error_no = '0'
>                          AND l.feature_data_json IS NOT NULL
>                          AND l.feature_data_json != 'null'
>                          AND l.feature_data_json != '{}'
>                         THEN b.trace_id END)                                                           AS sds_with_feature_cnt,   -- SDS 成功且有特征数据
>     ROUND(COUNT(DISTINCT CASE WHEN l.error_no = '0'
>                                AND l.feature_data_json IS NOT NULL
>                                AND l.feature_data_json != 'null'
>                                AND l.feature_data_json != '{}'
>                               THEN b.trace_id END)
>     * 1.0 / COUNT(DISTINCT b.trace_id), 4)                                                      AS feature_coverage_rate   -- 有效特征覆盖率
> FROM bubble_list b
> INNER JOIN log_data l ON b.trace_id = l.traceid;
> ```


**结论**

以冒泡宽表为基准，11,379 条去重 trace 全部在日志中有记录，SDS 调用成功率 100%，且 feature_data 均非空，有效特征覆盖率达到 100%。结合分析一，可以确认：**feature_data 为空的 trace 均来自修改目的地等非预估场景，预估场景下的冒泡 SDS 特征完全正常**。

| 指标 | 数值 |
| --- | --- |
| 冒泡宽表总数（去重） | 11,379 |
| 日志匹配数 | 11,379（**100%**） |
| SDS 调用成功 | 11,379（**100%**） |
| SDS 调用失败 | 0 |
| feature_data 为空 | 0 |
| 有效特征覆盖率 | **100%** |
