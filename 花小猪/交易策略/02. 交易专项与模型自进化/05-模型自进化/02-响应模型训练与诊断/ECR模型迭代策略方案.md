---
title: "ECR模型迭代策略方案"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2204622943696
cssclasses: ["strategy-body-note"]
---

# ECR模型迭代策略方案

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2204622943696)

**阅读定位**　[[#一、策略背景|一、策略背景]] · [[#二、策略方案|二、策略方案]]

## 一、策略背景

在新一轮的随机价格实验中，补贴由平台和特价盒子变为只给特价盒子补贴，同时补贴率的步长由5pp变为3pp，详见[RCT实验设计](文件名称：联合决策支持更细粒度折扣的RCT实验 链接：https://cooper.didichuxing.com/knowledge/2199610335356/2204429255383)。由于实验精细化了补贴率的步长，相应地需要更新模型版本，修改模型的输出。同时，模型的输入部分也会新增部分dufe特征。

## 二、策略方案

### 2.1 模型输入

新增**补充摇摆用户特征**部分，更新下方表格最后。这部分特征都是历史统计特征，配置在dufe里，可以直接获取。

所有特征
> [!example]- 完整数据表（272 行记录）
> | Index | 分类 | 特征 | type | default value | 特征说明 |
> | --- | --- | --- | --- | --- | --- |
> | | 订单维度特征 | semi_hour_of_day | | | 0\~47 |
> | | h | | | 0\~23 |
> | | day_of_week | | | 1\~7 |
> | | city_id | | | 0\~400 |
> | | min_basic_total_fee_amt | | | |
> | | max_basic_total_fee_amt | | | |
> | | start_dest_dis | | | |
> | | eta | | | |
> | | 格子特征 | grid_last_5min_anycar_start_order_finish_charge_dest_cnt_kf | | | |
> | | grid_last_1min_driver_empty_cnt_kf | | | |
> | | grid_last_5min_anycar_start_answer_order_dest_cnt_kf | | | |
> | | grid_last_5min_start_passenger_order_cancel_after_strive_cnt_kf | | | |
> | | grid_1circle_last_1min_anycar_start_answer_order_cnt_kf | | | |
> | | grid_last_5min_start_bubble_unq_cnt_kf | | | |
> | | grid_1circle_last_1min_anycar_start_order_cnt_kf | | | |
> | | grid_1circle_last_5min_anycar_driver_strived_epd_sum_kf | | | |
> | | grid_last_5min_anycar_start_passenger_wait_pick_time_sum_kf | | | |
> | | grid_last_5min_start_nonempty_driver_cnt_kf | | | |
> | | grid_last_1min_realtime_no_broadcast_order_cnt_kf | | | |
> | | grid_last_1min_anycar_start_order_cnt_kf | | | |
> | | grid_last_5min_anycar_start_response_dur_kf | | | |
> | | grid_last_5min_1circle_anycar_empty_driver_cnt_kf | | | |
> | | grid_last_1min_anycar_start_answer_order_cnt_kf | | | |
> | | grid_1circle_last_1min_anycar_driver_strived_epd_sum_kf | | | |
> | | grid_last_5min_start_passenger_order_cancel_before_strive_cnt_kf | | | |
> | | grid_1circle_last_5min_anycar_start_order_cnt_kf | | | |
> | | grid_last_5min_anycar_start_order_finish_charge_cnt_kf | | | |
> | | grid_last_5min_anycar_start_order_dest_cnt_kf | | | |
> | | grid_last_5min_anycar_start_answer_order_cnt_kf | | | |
> | | grid_last_5min_start_passenger_wait_pick_time_minute_cnt_kf | | | |
> | | grid_last_1min_1circle_anycar_empty_driver_cnt_kf | | | |
> | | grid_last_5min_anycar_start_order_cnt_kf | | | |
> | | grid_1circle_last_5min_anycar_start_answer_order_cnt_kf | | | |
> | | city_last_5min_anycar_start_start_answer_order_cnt_kf | | | |
> | | city_last_5min_anycar_start_biz_order_create_cnt_kf | | | |
> | | 历史统计特征 | dw_platform_biz_distinct_start_dest_avg_hh_finish | | | |
> | | dw_platform_biz_distinct_start_avg_zy_send | | | |
> | | dw_platform_biz_distinct_start_hour_hh_create_ecr | | | |
> | | dw_platform_biz_distinct_start_dest_api_compete_cr | | | |
> | | dw_platform_biz_distinct_dest_avg_zy_create_send | | | |
> | | dw_platform_biz_distinct_city_fee_api_create_ecr | | | |
> | | dw_platform_biz_distinct_start_dest_time_hh_create_ecr | | | |
> | | dw_platform_biz_distinct_start_hour_api_compete_cr | | | |
> | | dw_platform_biz_distinct_city_general_send | | | |
> | | dw_platform_biz_distinct_dest_avg_api_send | | | |
> | | dw_platform_biz_distinct_city_general_hh_compete_cr | | | |
> | | dw_platform_biz_distinct_city_time_avg_hh_create_send | | | |
> | | dw_platform_biz_distinct_start_avg_hh_send | | | |
> | | dw_platform_biz_distinct_start_dest_time_api_create_ecr | | | |
> | | dw_platform_biz_distinct_start_dest_time_finish | | | |
> | | dw_platform_biz_distinct_start_dest_avg_zy_finish | | | |
> | | dw_platform_biz_distinct_start_time_zy_compete_cr | | | |
> | | dw_platform_biz_distinct_city_time_avg_hh_finish | | | |
> | | dw_platform_biz_distinct_start_dest_avg_hh_create_send | | | |
> | | dw_platform_biz_distinct_city_time_bubble | | | |
> | | dw_platform_biz_distinct_city_fee_avg_select_pre_total_fee_amt | | | |
> | | dw_platform_biz_distinct_start_ecr | | | |
> | | dw_platform_biz_distinct_city_time_ecr | | | |
> | | dw_platform_biz_distinct_start_time_hh_compete_cr | | | |
> | | dw_platform_biz_distinct_start_dest_time_avg_api_send | | | |
> | | dw_platform_biz_distinct_start_time_finish | | | |
> | | dw_platform_biz_distinct_start_api_compete_cr | | | |
> | | dw_platform_biz_distinct_start_dest_zy_compete_cr | | | |
> | | dw_platform_biz_distinct_start_dest_hour_zy_compete_cr | | | |
> | | dw_platform_biz_distinct_start_dest_hour_avg_hh_create_send | | | |
> | | dw_platform_biz_distinct_start_avg_zy_create_send | | | |
> | | dw_platform_biz_distinct_start_time_avg_api_create_send | | | |
> | | dw_platform_biz_distinct_dest_hh_create_ecr | | | |
> | | dw_platform_biz_distinct_city_general_zy_create_ecr | | | |
> | | dw_platform_biz_distinct_city_hour_avg_api_finish | | | |
> | | dw_platform_biz_distinct_start_time_avg_zy_create_send | | | |
> | | dw_platform_biz_distinct_dest_ecr | | | |
> | | dw_platform_biz_distinct_start_hour_avg_api_send | | | |
> | | dw_platform_biz_distinct_city_hour_avg_min_pre_total_fee_amt | | | |
> | | dw_platform_biz_distinct_start_dest_time_avg_zy_send | | | |
> | | dw_platform_biz_distinct_start_time_avg_zy_send | | | |
> | | dw_platform_biz_distinct_city_fee_zy_compete_cr | | | |
> | | dw_platform_biz_distinct_start_hour_avg_hh_send | | | |
> | | dw_platform_biz_distinct_city_general_avg_hh_create_send | | | |
> | | dw_platform_biz_distinct_city_time_avg_zy_send | | | |
> | | dw_platform_biz_distinct_city_fee_avg_api_finish | | | |
> | | dw_platform_biz_distinct_start_dest_finish | | | |
> | | dw_platform_biz_distinct_start_time_avg_hh_finish | | | |
> | | dw_platform_biz_distinct_city_hour_zy_create_ecr | | | |
> | | dw_platform_biz_distinct_city_time_zy_compete_cr | | | |
> | | dw_platform_biz_distinct_start_time_api_create_ecr | | | |
> | | dw_platform_biz_distinct_start_dest_time_avg_hh_finish | | | |
> | | dw_platform_biz_distinct_city_time_avg_hh_send | | | |
> | | dw_platform_biz_distinct_start_dest_hour_api_compete_cr | | | |
> | | dw_platform_biz_distinct_start_dest_hour_avg_api_send | | | |
> | | dw_platform_biz_distinct_start_dest_hour_bubble | | | |
> | | dw_platform_biz_distinct_city_hour_avg_api_create_send | | | |
> | | dw_platform_biz_distinct_dest_avg_zy_send | | | |
> | | dw_platform_biz_distinct_start_hour_avg_zy_finish | | | |
> | | dw_platform_biz_distinct_start_time_avg_api_finish | | | |
> | | dw_platform_biz_distinct_dest_api_create_ecr | | | |
> | | dw_platform_biz_distinct_city_fee_avg_api_send | | | |
> | | dw_platform_biz_distinct_start_dest_time_avg_zy_create_send | | | |
> | | dw_platform_biz_distinct_start_avg_api_send | | | |
> | | dw_platform_biz_distinct_city_time_hh_compete_cr | | | |
> | | dw_platform_biz_distinct_start_dest_avg_api_finish | | | |
> | | dw_platform_biz_distinct_city_time_avg_zy_create_send | | | |
> | | dw_platform_biz_distinct_city_general_avg_min_pre_total_fee_amt | | | |
> | | dw_platform_biz_distinct_city_fee_avg_hh_create_send | | | |
> | | dw_platform_biz_distinct_start_dest_send | | | |
> | | dw_platform_biz_distinct_city_fee_avg_min_pre_total_fee_amt | | | |
> | | dw_platform_biz_distinct_start_dest_avg_api_send | | | |
> | | dw_platform_biz_distinct_dest_avg_hh_create_send | | | |
> | | dw_platform_biz_distinct_start_zy_compete_cr | | | |
> | | dw_platform_biz_distinct_start_hour_avg_hh_finish | | | |
> | | dw_platform_biz_distinct_start_hour_zy_create_ecr | | | |
> | | dw_platform_biz_distinct_city_fee_bubble | | | |
> | | dw_platform_biz_distinct_start_hour_finish | | | |
> | | dw_platform_biz_distinct_start_dest_hour_finish | | | |
> | | dw_platform_biz_distinct_start_dest_bubble | | | |
> | | dw_platform_biz_distinct_start_time_avg_api_send | | | |
> | | dw_platform_biz_distinct_city_hour_avg_zy_create_send | | | |
> | | dw_platform_biz_distinct_city_fee_api_compete_cr | | | |
> | | dw_platform_biz_distinct_city_general_bubble | | | |
> | | dw_platform_biz_distinct_city_time_avg_select_pre_total_fee_amt | | | |
> | | dw_platform_biz_distinct_start_hour_avg_api_create_send | | | |
> | | dw_platform_biz_distinct_start_hour_hh_compete_cr | | | |
> | | dw_platform_biz_distinct_start_time_avg_hh_send | | | |
> | | dw_platform_biz_distinct_start_dest_time_avg_hh_send | | | |
> | | dw_platform_biz_distinct_city_time_avg_zy_finish | | | |
> | | dw_platform_biz_distinct_start_avg_api_create_send | | | |
> | | dw_platform_biz_distinct_start_dest_avg_api_create_send | | | |
> | | dw_platform_biz_distinct_city_hour_api_compete_cr | | | |
> | | dw_platform_biz_distinct_city_hour_avg_api_send | | | |
> | | dw_platform_biz_distinct_city_hour_send | | | |
> | | dw_platform_biz_distinct_city_hour_hh_create_ecr | | | |
> | | dw_platform_biz_distinct_start_dest_time_avg_zy_finish | | | |
> | | dw_platform_biz_distinct_start_hour_send | | | |
> | | dw_platform_biz_distinct_city_fee_avg_zy_create_send | | | |
> | | dw_platform_biz_distinct_start_dest_hh_compete_cr | | | |
> | | dw_platform_biz_distinct_city_time_finish | | | |
> | | dw_platform_biz_distinct_dest_avg_hh_send | | | |
> | | dw_platform_biz_distinct_city_general_api_compete_cr | | | |
> | | dw_platform_biz_distinct_start_dest_time_zy_create_ecr | | | |
> | | dw_platform_biz_distinct_start_hour_bubble | | | |
> | | dw_platform_biz_distinct_city_general_avg_api_send | | | |
> | | dw_platform_biz_distinct_city_general_zy_compete_cr | | | |
> | | dw_platform_biz_distinct_start_dest_time_avg_api_create_send | | | |
> | | dw_platform_biz_distinct_city_time_api_create_ecr | | | |
> | | dw_platform_biz_distinct_start_time_ecr | | | |
> | | dw_platform_biz_distinct_start_dest_hour_hh_create_ecr | | | |
> | | dw_platform_biz_distinct_start_time_api_compete_cr | | | |
> | | dw_platform_biz_distinct_city_time_zy_create_ecr | | | |
> | | dw_platform_biz_distinct_dest_zy_compete_cr | | | |
> | | dw_platform_biz_distinct_city_general_ecr | | | |
> | | dw_platform_biz_distinct_start_avg_hh_finish | | | |
> | | dw_platform_biz_distinct_start_dest_hour_avg_api_finish | | | |
> | | dw_platform_biz_distinct_city_hour_avg_hh_finish | | | |
> | | dw_platform_biz_distinct_dest_avg_api_create_send | | | |
> | | dw_platform_biz_distinct_city_time_send | | | |
> | | dw_platform_biz_distinct_start_api_create_ecr | | | |
> | | dw_platform_biz_distinct_city_hour_avg_select_pre_total_fee_amt | | | |
> | | dw_platform_biz_distinct_dest_bubble | | | |
> | | dw_platform_biz_distinct_start_dest_ecr | | | |
> | | dw_platform_biz_distinct_city_general_avg_zy_finish | | | |
> | | dw_platform_biz_distinct_start_finish | | | |
> | | dw_platform_biz_distinct_start_avg_hh_create_send | | | |
> | | dw_platform_biz_distinct_start_dest_time_hh_compete_cr | | | |
> | | dw_platform_biz_distinct_city_hour_avg_hh_create_send | | | |
> | | dw_platform_biz_distinct_start_send | | | |
> | | dw_platform_biz_distinct_start_dest_time_zy_compete_cr | | | |
> | | dw_platform_biz_distinct_start_hour_avg_zy_create_send | | | |
> | | dw_platform_biz_distinct_start_dest_zy_create_ecr | | | |
> | | dw_platform_biz_distinct_start_dest_time_avg_hh_create_send | | | |
> | | dw_platform_biz_distinct_start_dest_time_ecr | | | |
> | | dw_platform_biz_distinct_city_fee_avg_hh_send | | | |
> | | dw_platform_biz_distinct_start_time_hh_create_ecr | | | |
> | | dw_platform_biz_distinct_city_general_finish | | | |
> | | dw_platform_biz_distinct_dest_avg_hh_finish | | | |
> | | dw_platform_biz_distinct_start_dest_api_create_ecr | | | |
> | | dw_platform_biz_distinct_start_dest_hour_avg_zy_create_send | | | |
> | | dw_platform_biz_distinct_start_dest_hour_api_create_ecr | | | |
> | | dw_platform_biz_distinct_start_bubble | | | |
> | | dw_platform_biz_distinct_city_general_avg_hh_finish | | | |
> | | dw_platform_biz_distinct_start_hour_api_create_ecr | | | |
> | | dw_platform_biz_distinct_city_hour_avg_hh_send | | | |
> | | dw_platform_biz_distinct_start_time_avg_hh_create_send | | | |
> | | dw_platform_biz_distinct_start_dest_hour_send | | | |
> | | dw_platform_biz_distinct_dest_api_compete_cr | | | |
> | | dw_platform_biz_distinct_start_avg_api_finish | | | |
> | | dw_platform_biz_distinct_dest_send | | | |
> | | dw_platform_biz_distinct_start_dest_time_send | | | |
> | | dw_platform_biz_distinct_dest_finish | | | |
> | | dw_platform_biz_distinct_city_hour_bubble | | | |
> | | dw_platform_biz_distinct_city_general_avg_api_create_send | | | |
> | | dw_platform_biz_distinct_city_hour_finish | | | |
> | | dw_platform_biz_distinct_start_dest_hour_avg_hh_send | | | |
> | | dw_platform_biz_distinct_city_time_hh_create_ecr | | | |
> | | dw_platform_biz_distinct_city_fee_ecr | | | |
> | | dw_platform_biz_distinct_city_time_avg_api_finish | | | |
> | | dw_platform_biz_distinct_city_fee_finish | | | |
> | | dw_platform_biz_distinct_city_hour_avg_zy_finish | | | |
> | | dw_platform_biz_distinct_city_time_avg_api_create_send | | | |
> | | dw_platform_biz_distinct_start_hour_zy_compete_cr | | | |
> | | dw_platform_biz_distinct_city_general_avg_zy_create_send | | | |
> | | dw_platform_biz_distinct_city_fee_hh_create_ecr | | | |
> | | dw_platform_biz_distinct_start_hour_avg_hh_create_send | | | |
> | | dw_platform_biz_distinct_city_fee_send | | | |
> | | dw_platform_biz_distinct_start_time_send | | | |
> | | dw_platform_biz_distinct_city_general_avg_hh_send | | | |
> | | dw_platform_biz_distinct_city_hour_ecr | | | |
> | | dw_platform_biz_distinct_start_dest_hour_avg_hh_finish | | | |
> | | dw_platform_biz_distinct_start_dest_hh_create_ecr | | | |
> | | dw_platform_biz_distinct_start_dest_hour_avg_api_create_send | | | |
> | | dw_platform_biz_distinct_start_hh_create_ecr | | | |
> | | dw_platform_biz_distinct_start_time_avg_zy_finish | | | |
> | | dw_platform_biz_distinct_city_fee_zy_create_ecr | | | |
> | | dw_platform_biz_distinct_city_fee_avg_zy_finish | | | |
> | | dw_platform_biz_distinct_dest_avg_api_finish | | | |
> | | dw_platform_biz_distinct_start_time_bubble | | | |
> | | dw_platform_biz_distinct_start_hour_avg_api_finish | | | |
> | | dw_platform_biz_distinct_start_dest_hour_avg_zy_finish | | | |
> | | dw_platform_biz_distinct_start_dest_avg_zy_create_send | | | |
> | | dw_platform_biz_distinct_city_time_api_compete_cr | | | |
> | | dw_platform_biz_distinct_city_hour_api_create_ecr | | | |
> | | dw_platform_biz_distinct_start_dest_hour_zy_create_ecr | | | |
> | | dw_platform_biz_distinct_city_time_avg_api_send | | | |
> | | dw_platform_biz_distinct_city_hour_hh_compete_cr | | | |
> | | dw_platform_biz_distinct_city_general_api_create_ecr | | | |
> | | dw_platform_biz_distinct_start_hh_compete_cr | | | |
> | | dw_platform_biz_distinct_city_fee_avg_hh_finish | | | |
> | | dw_platform_biz_distinct_dest_hh_compete_cr | | | |
> | | dw_platform_biz_distinct_city_general_avg_api_finish | | | |
> | | dw_platform_biz_distinct_city_general_avg_zy_send | | | |
> | | dw_platform_biz_distinct_start_dest_avg_hh_send | | | |
> | | dw_platform_biz_distinct_city_time_avg_min_pre_total_fee_amt | | | |
> | | dw_platform_biz_distinct_city_fee_hh_compete_cr | | | |
> | | dw_platform_biz_distinct_city_hour_zy_compete_cr | | | |
> | | dw_platform_biz_distinct_start_hour_ecr | | | |
> | | dw_platform_biz_distinct_city_fee_avg_zy_send | | | |
> | | dw_platform_biz_distinct_city_fee_avg_api_create_send | | | |
> | | dw_platform_biz_distinct_start_time_zy_create_ecr | | | |
> | | dw_platform_biz_distinct_city_general_avg_select_pre_total_fee_amt | | | |
> | | dw_platform_biz_distinct_start_dest_hour_avg_zy_send | | | |
> | | dw_platform_biz_distinct_dest_avg_zy_finish | | | |
> | | dw_platform_biz_distinct_city_hour_avg_zy_send | | | |
> | | dw_platform_biz_distinct_start_dest_time_api_compete_cr | | | |
> | | dw_platform_biz_distinct_start_hour_avg_zy_send | | | |
> | | dw_platform_biz_distinct_city_general_hh_create_ecr | | | |
> | | dw_platform_biz_distinct_start_dest_avg_zy_send | | | |
> | | dw_platform_biz_distinct_start_dest_hour_ecr | | | |
> | | dw_platform_biz_distinct_start_avg_zy_finish | | | |
> | | dw_platform_biz_distinct_dest_zy_create_ecr | | | |
> | | dw_platform_biz_distinct_start_dest_time_bubble | | | |
> | | dw_platform_biz_distinct_start_zy_create_ecr | | | |
> | | dw_platform_biz_distinct_start_dest_hour_hh_compete_cr | | | |
> | | P维度特征 | pas_ecr_1month | | | |
> | | pas_bub_cnt_1month | | | |
> | | pas_called_distance_max_1month | | | |
> | | pas_called_distance_avg_1month | | | |
> | | pas_called_distance_min_1month | | | |
> | | pas_uncalled_distance_max_1month | | | |
> | | pas_uncalled_distance_avg_1month | | | |
> | | pas_uncalled_distance_min_1month | | | |
> | | pas_called_min_fee_cpm_max_1month | | | |
> | | pas_called_min_fee_cpm_avg_1month | | | |
> | | pas_called_min_fee_cpm_min_1month | | | |
> | | pas_called_th_fee_ratio_max_1month | | | |
> | | pas_called_th_fee_ratio_avg_1month | | | |
> | | pas_called_th_fee_ratio_min_1month | | | |
> | | pas_called_kc_fee_ratio_max_1month | | | |
> | | pas_called_kc_fee_ratio_avg_1month | | | |
> | | pas_called_kc_fee_ratio_min_1month | | | |
> | | pas_called_one_price_basic_ratio_max_1month | | | |
> | | pas_called_one_price_basic_ratio_avg_1month | | | |
> | | pas_called_one_price_basic_ratio_min_1month | | | |
> | | **补充摇摆用户特征** | acti_pas_ecr_1month <br>acti_pas_called_one_price_basic_ratio_avg_1month <br>acti_pas_called_one_price_basic_ratio_max_1month <br>other_sm_cnt_weekday_28d <br>pbd_gd_sm_cnt_30d <br>sm_cnt_weekday_14d <br>sm_cnt_weekend_28d <br>sm_cnt_weekday_28d <br>dm_user_base_oneid_info_last_use_kflw <br>dm_user_vzt_pub_rfmpeat_kflw_a <br>dm_user_vzt_pub_rfmpeat_ut_f <br>dm_user_vzt_pub_rfmpeat_other_p <br>dm_user_mkt_netcar_ordacc_gcsv2_cost_mean <br>dm_user_vzt_pub_rfmpeat_other_synth <br>dm_user_base_oneid_info_age <br>dm_user_vzt_pub_rfmpeat_btls_a <br>dm_user_mkt_netcar_ordacc_jie_subsidy_c_order_ratio <br>dm_user_mkt_biz_abst_kflw_cancel_types_divg <br>dm_user_vzt_pub_rfmpeat_ut_a <br>dm_user_behv_netcar_htpp_vzt_city_num <br>dm_user_vzt_pub_rfmpeat_ut_r <br>hxz_finish_asp_28d <br>is_kf_student_verify <br>hxz_finish_cnt_weekday_28d <br>dd_kf_sm_bubble_cnt_14d <br>pbd_bubble_cnt_weekday_28d <br>wyc_bubble_cnt_1d <br>pbd_bubble_cnt_7d <br>call_ratio_7d <br>dd_pbd_sm_bubble_cnt_7d <br>hxz_finish_cnt_7d <br>dd_gd_sm_cnt_30d <br>kf_gd_sm_cnt_30d <br>hxz_finish_cnt_28d <br>call_ratio_28d <br>kf_gd_sm_cnt_7d <br>wyc_bubble_cnt_14d <br>is_5d_sm <br>is_1d_sm <br>is_3d_sm <br>is_14d_sm <br>is_28d_sm <br>is_10d_sm <br>--这部分特征没有配置到dufe，暂时不用考虑 <br>~~didi_order_created_total_cnt_S60~~ <br>~~didi_bubble_total_cnt_S120~~ <br>~~didi_order_created_cnt_S30~~ <br>~~didi_bubble_total_avg_estimate_time_minutes_S60~~ <br>~~didi_bubble_total_avg_estimate_distance_metre_S120~~ <br>~~tencent_service_order_created_total_cnt_S60~~ <br>~~tencent_service_order_created_cnt_S30~~ | | | |


### 2.2 模型输出

由于折扣从平台跟盒子的组合折扣（17种组合折扣），变为单独的盒子折扣（原来盒子折扣只有5种），且盒子的补贴率折扣步长由5pp变为3pp，输出部分会由长度为17的list变为长度为7的list，表示盒子在不同折扣下的ecr。

**【改动点】**

- 模型输出长度：有17变为7

- 对应的补贴率折扣步长：由5pp变为3pp，变动后只有盒子折扣，可选的折扣有100，97，94，91，88，85，82

【**下游影响**】

在联合决策中，当折扣发生变化时，相应地会影响price list，从而对DSAR和acc_CR模型产生影响。本次主要是ECR模型的更新，但是需要关注，当折扣步长变化时，下游的DSAR以及acc_CR模型是否会受到影响，以及能否支持步长修改后的折扣类型。

### 2.3 平台定折、盒子智能呼返功能支持

虽然现阶段平台呼返不回给折扣，但是需要保留这部分的功能。目前是给平台呼返固定的折扣，然后盒子通过智能呼返拿到在线决策的折扣。但是这个功能只有在平台呼返step为5pp的折扣时可用，这次希望在平台呼返其他折扣下，也支持盒子的智能呼返。即对于平台呼返在任意折扣下定折，支持配置特价盒子呼返为智能呼返。
