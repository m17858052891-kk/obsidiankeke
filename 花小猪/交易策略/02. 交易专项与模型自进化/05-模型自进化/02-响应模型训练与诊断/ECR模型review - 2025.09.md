---
title: "ECR模型review - 2025.09"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2205336871258
cssclasses: ["strategy-body-note"]
---

# ECR模型review - 2025.09

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2205336871258)

按数据获取、重复 trace、P 维度特征及传入特征的排查路径阅读。保留当时的异常与处理记录。

**阅读定位**　[[#1 数据获取|1 数据获取]] · [[#2 模型训练|2 模型训练]] · [[#3 ECR仿真|3 ECR仿真]]

## 1 数据获取

价格实验方案：<https://cooper.didichuxing.com/knowledge/2199610335356/2205203837873>

### 1.1 trace_id不唯一问题

问题描述：理论上一个trace_id，对应一个冒泡样本，但是直接从训练数据表取数，count(distinct trace_id) != count(trace_id)

![](b7a789863a721f5b-截屏2025-09-09下午7.57.00.png)

原因：

- 没有对trace_id去重；增加distinct / group by trace_id的逻辑

- P维度特征表，同一用户重复多次；已更改

修正后取数验证：

![](acaf8fcaa88cbe80-截屏2025-09-10下午2.49.05.png)

### 1.2 P维度特征表问题

特征表：merge_all_acti_features

#### 问题1:日期依赖

数梦任务：<https://studio.data.didichuxing.com/batch?projectId=1143&taskId=41348555>

h2d任务：<https://studio.data.didichuxing.com/batch?projectId=1142&taskId=42398249>

问题描述：

- 该表T-1日分区，取T-2日的竞争特征数据，但是依赖配置的是T-1

- 导致线上：上午的冒泡使用T-3日的竞争特征，下午的冒泡使用的T-2日的竞争特征

- 离线取训练数据时，全部使用T-3日的竞争特征

| | 线上 | ECR模型训练数据 |
| --- | --- | --- |
| 冒泡 | T | T |
| H2D任务取数分区 | T-1，13点更新 | - |
| merge_all_acti_features分区 | T-1，13点更新 | T-2 |
| 对应竞争特征分区 | T-2，13点更新 | T-3 |

解决方案：

- 表merge_all_acti_features，T-1日分区，取T-1日竞争特征，配T-1日依赖

- H2D任务，T-1日分区，读T-2日表，配T-2日依赖

- fastload任务：\\todo 待排查fastload依赖逻辑

#### 问题2: 数据重复

问题描述：同一用户在表中重复多次，count(distinct passenger_id)!=count(passenger_id)

![](5d04b41cd1401668-截屏2025-09-09下午9.44.30.png)

原因：上游套餐特征表kflower_strategy.hxz_pid_feature_package_click，是group by uid,city_id，进行特征统计，导致uid在表中不唯一

解决方案：取套餐特征时，按照group by uid后，sum每个字段

修复后取数验证：count(distinct passenger_id)=count(passenger_id)

![](e544d7c592768cf7-截屏2025-09-10上午11.03.48.png)

数据回溯：2025-08-15-2025-09-09

### 1.3 传入特征排查

最终传入特征未用：

pre_subsidy_uabx,

pre_subsidy_plat_min,

pre_subsidy_plat_max,

pre_subsidy_plat_avg,

min_fee_frac_to_uabx

### 1.4 分折扣弹性分析

1. 由于是pid尾号随机分流，一个冒泡一个样本，因此折扣深的组，样本量大

2. 随折扣加深，88->85、76->73，不单调，其余单调递增

| uabox_discount | ecr | 样本量 | 用户数 | ecr曲线图 |
| --- | --- | --- | --- | --- |
| 73 | 0.74183403 | 155799 | 35667 | ![](fa3cbb95b64bef1b-截屏2025-09-10下午5.13.48.png) |
| 76 | 0.74321458 | 152275 | 35765 |
| 79 | 0.74298503 | 151248 | 35804 |
| 82 | 0.7392914 | 148292 | 35483 |
| 85 | 0.72947975 | 147793 | 35767 |
| 88 | 0.73476296 | 145632 | 35595 |
| 91 | 0.72651742 | 146598 | 35972 |
| 94 | 0.72510639 | 142637 | 35397 |
| 97 | 0.71664282 | 141881 | 35596 |
| 100 | 0.7065916 | 139253 | 35362 |

## 2 模型训练

训练集：0826～0904，102W

测试集：0905～0909，44W

### 2.1 特征工程

| 维度 | 特征 | 传入特征 | 表 |
| --- | --- | --- | --- |
| 订单维度 | 小时、周几、最高/低应付价、订单距离、订单时长 | ✅ | |
| 实时供需特征 | 格子特征：1/5分钟 X 坐标所在格子/所在格子一圈格子 X 冒泡数/发单数/应答数/完单数/乘客取消数/空车司机数/未播订单数/接驾总时长/应答总距离 <br>城市特征：5分钟应答数/订单创建数 | ✅ | |
| 历史P维度 | | | [kflower_strategy](https://datamap.didichuxing.com/detail?uri=hive://mycluster-tj:kflower_strategy:dw_platform_biz_ecr_features_grid_start_dest_ecr&keyword=start,kflower,kflower_strategy%20dw_platform_biz_ecr_features_grid_start_dest_ecr,dest,platform,kflower_strategy,features,dw_platform_biz_ecr_features_grid_start_dest_ecr,biz,dw,ecr,grid,strategy&referrer=search)[.](https://datamap.didichuxing.com/detail?uri=hive://mycluster-tj:kflower_strategy:dw_platform_biz_ecr_features_grid_start_dest_ecr&keyword=start,kflower,kflower_strategy%20dw_platform_biz_ecr_features_grid_start_dest_ecr,dest,platform,kflower_strategy,features,dw_platform_biz_ecr_features_grid_start_dest_ecr,biz,dw,ecr,grid,strategy&referrer=search)[dw_platform_biz_ecr_features_grid_start_dest_ecr](https://datamap.didichuxing.com/detail?uri=hive://mycluster-tj:kflower_strategy:dw_platform_biz_ecr_features_grid_start_dest_ecr&keyword=start,kflower,kflower_strategy%20dw_platform_biz_ecr_features_grid_start_dest_ecr,dest,platform,kflower_strategy,features,dw_platform_biz_ecr_features_grid_start_dest_ecr,biz,dw,ecr,grid,strategy&referrer=search) |

expand
> [!example]- 完整数据表（321 行记录）
> | | 特征名 | 含义 |
> | --- | --- | --- |
> | 订单维度 | semi_hour_of_day | 半小时 |
> | h | 小时 |
> | day_of_week | 周几 |
> | city_id | 城市 |
> | min_basic_total_fee_amt | 表单最低应付价 |
> | max_basic_total_fee_amt | 表单最高应付价 |
> | start_dest_dis | 订单距离 |
> | eta | 预估订单时长 |
> | 格子特征 | grid_last_5min_anycar_start_order_finish_charge_dest_cnt_kf | 坐标所在格子5分钟聚合单完成数 |
> | grid_last_1min_driver_empty_cnt_kf | 格子周围实时平台空车司机数 |
> | grid_last_5min_anycar_start_answer_order_dest_cnt_kf | 坐标所在格子5分钟聚合应答数 |
> | grid_last_5min_start_passenger_order_cancel_after_strive_cnt_kf | 新业务起点坐标所在格子5分钟乘客抢单后取消数 |
> | grid_1circle_last_1min_anycar_start_answer_order_cnt_kf | 坐标所在格子1圈格子1分钟聚合应答数 |
> | grid_last_5min_start_bubble_unq_cnt_kf | 坐标点所属格子新业务5分钟格子的冒泡数 |
> | grid_1circle_last_1min_anycar_start_order_cnt_kf | 坐标所在格子1圈格子1分钟聚合发单数 |
> | grid_1circle_last_5min_anycar_driver_strived_epd_sum_kf | 新业务鸿鹄格子1圈格子5分钟聚合司机总应答距离 |
> | grid_last_5min_anycar_start_passenger_wait_pick_time_sum_kf | 新业务坐标所在格子聚合5分钟接驾总时长 |
> | grid_last_5min_start_nonempty_driver_cnt_kf | 新业务起点坐标所在格子过去5分钟内出现过的平台非空司机数量 |
> | grid_last_1min_realtime_no_broadcast_order_cnt_kf | 坐标所在格子平台实时未播订单数新业务 |
> | grid_last_1min_anycar_start_order_cnt_kf | 坐标所在格子1分钟聚合发单数 |
> | grid_last_5min_anycar_start_response_dur_kf | 起点坐标所在格子的5分钟聚合司机总应答时长 |
> | grid_last_5min_1circle_anycar_empty_driver_cnt_kf | 起点坐标所在格子第1圈格子过去5分钟内出现过的空车新业务司机数量 |
> | grid_last_1min_anycar_start_answer_order_cnt_kf | 坐标所在格子1分钟聚合应答数 |
> | grid_1circle_last_1min_anycar_driver_strived_epd_sum_kf | 新业务鸿鹄格子1圈格子5分钟聚合司机总应答距离 |
> | grid_last_5min_start_passenger_order_cancel_before_strive_cnt_kf | 新业务起点坐标所在格子5分钟乘客抢单前取消数 |
> | grid_1circle_last_5min_anycar_start_order_cnt_kf | 坐标所在格子1圈格子5分钟聚合发单数 |
> | grid_last_5min_anycar_start_order_finish_charge_cnt_kf | 坐标所在格子5分钟聚合单完成数 |
> | grid_last_5min_anycar_start_order_dest_cnt_kf | 坐标所在格子为终点5分钟聚合发单数 |
> | grid_last_5min_anycar_start_answer_order_cnt_kf | 坐标所在格子5分钟聚合应答数 |
> | grid_last_5min_start_passenger_wait_pick_time_minute_cnt_kf | 新业务起点坐标所在格子5分钟司机到达乘客上车点数 |
> | grid_last_1min_1circle_anycar_empty_driver_cnt_kf | 起点坐标所在格子第1圈格子过去1分钟内出现过的空车新业务司机数量 |
> | grid_last_5min_anycar_start_order_cnt_kf | 坐标所在格子5分钟聚合发单数 |
> | grid_1circle_last_5min_anycar_start_answer_order_cnt_kf | 坐标所在格子1圈格子5分钟聚合应答数 |
> | city_last_5min_anycar_start_start_answer_order_cnt_kf | 新业务聚合城市5分钟应答数 |
> | city_last_5min_anycar_start_biz_order_create_cnt_kf | 新业务聚合城市5分钟订单创建数 |
> | 历史统计特征 | dw_platform_biz_distinct_start_dest_avg_hh_finish | |
> | dw_platform_biz_distinct_start_avg_zy_send | |
> | dw_platform_biz_distinct_start_hour_hh_create_ecr | |
> | dw_platform_biz_distinct_start_dest_api_compete_cr | |
> | dw_platform_biz_distinct_dest_avg_zy_create_send | |
> | dw_platform_biz_distinct_city_fee_api_create_ecr | |
> | dw_platform_biz_distinct_start_dest_time_hh_create_ecr | |
> | dw_platform_biz_distinct_start_hour_api_compete_cr | |
> | dw_platform_biz_distinct_city_general_send | |
> | dw_platform_biz_distinct_dest_avg_api_send | |
> | dw_platform_biz_distinct_city_general_hh_compete_cr | |
> | dw_platform_biz_distinct_city_time_avg_hh_create_send | |
> | dw_platform_biz_distinct_start_avg_hh_send | |
> | dw_platform_biz_distinct_start_dest_time_api_create_ecr | |
> | dw_platform_biz_distinct_start_dest_time_finish | |
> | dw_platform_biz_distinct_start_dest_avg_zy_finish | |
> | dw_platform_biz_distinct_start_time_zy_compete_cr | |
> | dw_platform_biz_distinct_city_time_avg_hh_finish | |
> | dw_platform_biz_distinct_start_dest_avg_hh_create_send | |
> | dw_platform_biz_distinct_city_time_bubble | |
> | dw_platform_biz_distinct_city_fee_avg_select_pre_total_fee_amt | |
> | dw_platform_biz_distinct_start_ecr | |
> | dw_platform_biz_distinct_city_time_ecr | |
> | dw_platform_biz_distinct_start_time_hh_compete_cr | |
> | dw_platform_biz_distinct_start_dest_time_avg_api_send | |
> | dw_platform_biz_distinct_start_time_finish | |
> | dw_platform_biz_distinct_start_api_compete_cr | |
> | dw_platform_biz_distinct_start_dest_zy_compete_cr | |
> | dw_platform_biz_distinct_start_dest_hour_zy_compete_cr | |
> | dw_platform_biz_distinct_start_dest_hour_avg_hh_create_send | |
> | dw_platform_biz_distinct_start_avg_zy_create_send | |
> | dw_platform_biz_distinct_start_time_avg_api_create_send | |
> | dw_platform_biz_distinct_dest_hh_create_ecr | |
> | dw_platform_biz_distinct_city_general_zy_create_ecr | |
> | dw_platform_biz_distinct_city_hour_avg_api_finish | |
> | dw_platform_biz_distinct_start_time_avg_zy_create_send | |
> | dw_platform_biz_distinct_dest_ecr | |
> | dw_platform_biz_distinct_start_hour_avg_api_send | |
> | dw_platform_biz_distinct_city_hour_avg_min_pre_total_fee_amt | |
> | dw_platform_biz_distinct_start_dest_time_avg_zy_send | |
> | dw_platform_biz_distinct_start_time_avg_zy_send | |
> | dw_platform_biz_distinct_city_fee_zy_compete_cr | |
> | dw_platform_biz_distinct_start_hour_avg_hh_send | |
> | dw_platform_biz_distinct_city_general_avg_hh_create_send | |
> | dw_platform_biz_distinct_city_time_avg_zy_send | |
> | dw_platform_biz_distinct_city_fee_avg_api_finish | |
> | dw_platform_biz_distinct_start_dest_finish | |
> | dw_platform_biz_distinct_start_time_avg_hh_finish | |
> | dw_platform_biz_distinct_city_hour_zy_create_ecr | |
> | dw_platform_biz_distinct_city_time_zy_compete_cr | |
> | dw_platform_biz_distinct_start_time_api_create_ecr | |
> | dw_platform_biz_distinct_start_dest_time_avg_hh_finish | |
> | dw_platform_biz_distinct_city_time_avg_hh_send | |
> | dw_platform_biz_distinct_start_dest_hour_api_compete_cr | |
> | dw_platform_biz_distinct_start_dest_hour_avg_api_send | |
> | dw_platform_biz_distinct_start_dest_hour_bubble | |
> | dw_platform_biz_distinct_city_hour_avg_api_create_send | |
> | dw_platform_biz_distinct_dest_avg_zy_send | |
> | dw_platform_biz_distinct_start_hour_avg_zy_finish | |
> | dw_platform_biz_distinct_start_time_avg_api_finish | |
> | dw_platform_biz_distinct_dest_api_create_ecr | |
> | dw_platform_biz_distinct_city_fee_avg_api_send | |
> | dw_platform_biz_distinct_start_dest_time_avg_zy_create_send | |
> | dw_platform_biz_distinct_start_avg_api_send | |
> | dw_platform_biz_distinct_city_time_hh_compete_cr | |
> | dw_platform_biz_distinct_start_dest_avg_api_finish | |
> | dw_platform_biz_distinct_city_time_avg_zy_create_send | |
> | dw_platform_biz_distinct_city_general_avg_min_pre_total_fee_amt | |
> | dw_platform_biz_distinct_city_fee_avg_hh_create_send | |
> | dw_platform_biz_distinct_start_dest_send | |
> | dw_platform_biz_distinct_city_fee_avg_min_pre_total_fee_amt | |
> | dw_platform_biz_distinct_start_dest_avg_api_send | |
> | dw_platform_biz_distinct_dest_avg_hh_create_send | |
> | dw_platform_biz_distinct_start_zy_compete_cr | |
> | dw_platform_biz_distinct_start_hour_avg_hh_finish | |
> | dw_platform_biz_distinct_start_hour_zy_create_ecr | |
> | dw_platform_biz_distinct_city_fee_bubble | |
> | dw_platform_biz_distinct_start_hour_finish | |
> | dw_platform_biz_distinct_start_dest_hour_finish | |
> | dw_platform_biz_distinct_start_dest_bubble | |
> | dw_platform_biz_distinct_start_time_avg_api_send | |
> | dw_platform_biz_distinct_city_hour_avg_zy_create_send | |
> | dw_platform_biz_distinct_city_fee_api_compete_cr | |
> | dw_platform_biz_distinct_city_general_bubble | |
> | dw_platform_biz_distinct_city_time_avg_select_pre_total_fee_amt | |
> | dw_platform_biz_distinct_start_hour_avg_api_create_send | |
> | dw_platform_biz_distinct_start_hour_hh_compete_cr | |
> | dw_platform_biz_distinct_start_time_avg_hh_send | |
> | dw_platform_biz_distinct_start_dest_time_avg_hh_send | |
> | dw_platform_biz_distinct_city_time_avg_zy_finish | |
> | dw_platform_biz_distinct_start_avg_api_create_send | |
> | dw_platform_biz_distinct_start_dest_avg_api_create_send | |
> | dw_platform_biz_distinct_city_hour_api_compete_cr | |
> | dw_platform_biz_distinct_city_hour_avg_api_send | |
> | dw_platform_biz_distinct_city_hour_send | |
> | dw_platform_biz_distinct_city_hour_hh_create_ecr | |
> | dw_platform_biz_distinct_start_dest_time_avg_zy_finish | |
> | dw_platform_biz_distinct_start_hour_send | |
> | dw_platform_biz_distinct_city_fee_avg_zy_create_send | |
> | dw_platform_biz_distinct_start_dest_hh_compete_cr | |
> | dw_platform_biz_distinct_city_time_finish | |
> | dw_platform_biz_distinct_dest_avg_hh_send | |
> | dw_platform_biz_distinct_city_general_api_compete_cr | |
> | dw_platform_biz_distinct_start_dest_time_zy_create_ecr | |
> | dw_platform_biz_distinct_start_hour_bubble | |
> | dw_platform_biz_distinct_city_general_avg_api_send | |
> | dw_platform_biz_distinct_city_general_zy_compete_cr | |
> | dw_platform_biz_distinct_start_dest_time_avg_api_create_send | |
> | dw_platform_biz_distinct_city_time_api_create_ecr | |
> | dw_platform_biz_distinct_start_time_ecr | |
> | dw_platform_biz_distinct_start_dest_hour_hh_create_ecr | |
> | dw_platform_biz_distinct_start_time_api_compete_cr | |
> | dw_platform_biz_distinct_city_time_zy_create_ecr | |
> | dw_platform_biz_distinct_dest_zy_compete_cr | |
> | dw_platform_biz_distinct_city_general_ecr | |
> | dw_platform_biz_distinct_start_avg_hh_finish | |
> | dw_platform_biz_distinct_start_dest_hour_avg_api_finish | |
> | dw_platform_biz_distinct_city_hour_avg_hh_finish | |
> | dw_platform_biz_distinct_dest_avg_api_create_send | |
> | dw_platform_biz_distinct_city_time_send | |
> | dw_platform_biz_distinct_start_api_create_ecr | |
> | dw_platform_biz_distinct_city_hour_avg_select_pre_total_fee_amt | |
> | dw_platform_biz_distinct_dest_bubble | |
> | dw_platform_biz_distinct_start_dest_ecr | |
> | dw_platform_biz_distinct_city_general_avg_zy_finish | |
> | dw_platform_biz_distinct_start_finish | |
> | dw_platform_biz_distinct_start_avg_hh_create_send | |
> | dw_platform_biz_distinct_start_dest_time_hh_compete_cr | |
> | dw_platform_biz_distinct_city_hour_avg_hh_create_send | |
> | dw_platform_biz_distinct_start_send | |
> | dw_platform_biz_distinct_start_dest_time_zy_compete_cr | |
> | dw_platform_biz_distinct_start_hour_avg_zy_create_send | |
> | dw_platform_biz_distinct_start_dest_zy_create_ecr | |
> | dw_platform_biz_distinct_start_dest_time_avg_hh_create_send | |
> | dw_platform_biz_distinct_start_dest_time_ecr | |
> | dw_platform_biz_distinct_city_fee_avg_hh_send | |
> | dw_platform_biz_distinct_start_time_hh_create_ecr | |
> | dw_platform_biz_distinct_city_general_finish | |
> | dw_platform_biz_distinct_dest_avg_hh_finish | |
> | dw_platform_biz_distinct_start_dest_api_create_ecr | |
> | dw_platform_biz_distinct_start_dest_hour_avg_zy_create_send | |
> | dw_platform_biz_distinct_start_dest_hour_api_create_ecr | |
> | dw_platform_biz_distinct_start_bubble | |
> | dw_platform_biz_distinct_city_general_avg_hh_finish | |
> | dw_platform_biz_distinct_start_hour_api_create_ecr | |
> | dw_platform_biz_distinct_city_hour_avg_hh_send | |
> | dw_platform_biz_distinct_start_time_avg_hh_create_send | |
> | dw_platform_biz_distinct_start_dest_hour_send | |
> | dw_platform_biz_distinct_dest_api_compete_cr | |
> | dw_platform_biz_distinct_start_avg_api_finish | |
> | dw_platform_biz_distinct_dest_send | |
> | dw_platform_biz_distinct_start_dest_time_send | |
> | dw_platform_biz_distinct_dest_finish | |
> | dw_platform_biz_distinct_city_hour_bubble | |
> | dw_platform_biz_distinct_city_general_avg_api_create_send | |
> | dw_platform_biz_distinct_city_hour_finish | |
> | dw_platform_biz_distinct_start_dest_hour_avg_hh_send | |
> | dw_platform_biz_distinct_city_time_hh_create_ecr | |
> | dw_platform_biz_distinct_city_fee_ecr | |
> | dw_platform_biz_distinct_city_time_avg_api_finish | |
> | dw_platform_biz_distinct_city_fee_finish | |
> | dw_platform_biz_distinct_city_hour_avg_zy_finish | |
> | dw_platform_biz_distinct_city_time_avg_api_create_send | |
> | dw_platform_biz_distinct_start_hour_zy_compete_cr | |
> | dw_platform_biz_distinct_city_general_avg_zy_create_send | |
> | dw_platform_biz_distinct_city_fee_hh_create_ecr | |
> | dw_platform_biz_distinct_start_hour_avg_hh_create_send | |
> | dw_platform_biz_distinct_city_fee_send | |
> | dw_platform_biz_distinct_start_time_send | |
> | dw_platform_biz_distinct_city_general_avg_hh_send | |
> | dw_platform_biz_distinct_city_hour_ecr | |
> | dw_platform_biz_distinct_start_dest_hour_avg_hh_finish | |
> | dw_platform_biz_distinct_start_dest_hh_create_ecr | |
> | dw_platform_biz_distinct_start_dest_hour_avg_api_create_send | |
> | dw_platform_biz_distinct_start_hh_create_ecr | |
> | dw_platform_biz_distinct_start_time_avg_zy_finish | |
> | dw_platform_biz_distinct_city_fee_zy_create_ecr | |
> | dw_platform_biz_distinct_city_fee_avg_zy_finish | |
> | dw_platform_biz_distinct_dest_avg_api_finish | |
> | dw_platform_biz_distinct_start_time_bubble | |
> | dw_platform_biz_distinct_start_hour_avg_api_finish | |
> | dw_platform_biz_distinct_start_dest_hour_avg_zy_finish | |
> | dw_platform_biz_distinct_start_dest_avg_zy_create_send | |
> | dw_platform_biz_distinct_city_time_api_compete_cr | |
> | dw_platform_biz_distinct_city_hour_api_create_ecr | |
> | dw_platform_biz_distinct_start_dest_hour_zy_create_ecr | |
> | dw_platform_biz_distinct_city_time_avg_api_send | |
> | dw_platform_biz_distinct_city_hour_hh_compete_cr | |
> | dw_platform_biz_distinct_city_general_api_create_ecr | |
> | dw_platform_biz_distinct_start_hh_compete_cr | |
> | dw_platform_biz_distinct_city_fee_avg_hh_finish | |
> | dw_platform_biz_distinct_dest_hh_compete_cr | |
> | dw_platform_biz_distinct_city_general_avg_api_finish | |
> | dw_platform_biz_distinct_city_general_avg_zy_send | |
> | dw_platform_biz_distinct_start_dest_avg_hh_send | |
> | dw_platform_biz_distinct_city_time_avg_min_pre_total_fee_amt | |
> | dw_platform_biz_distinct_city_fee_hh_compete_cr | |
> | dw_platform_biz_distinct_city_hour_zy_compete_cr | |
> | dw_platform_biz_distinct_start_hour_ecr | |
> | dw_platform_biz_distinct_city_fee_avg_zy_send | |
> | dw_platform_biz_distinct_city_fee_avg_api_create_send | |
> | dw_platform_biz_distinct_start_time_zy_create_ecr | |
> | dw_platform_biz_distinct_city_general_avg_select_pre_total_fee_amt | |
> | dw_platform_biz_distinct_start_dest_hour_avg_zy_send | |
> | dw_platform_biz_distinct_dest_avg_zy_finish | |
> | dw_platform_biz_distinct_city_hour_avg_zy_send | |
> | dw_platform_biz_distinct_start_dest_time_api_compete_cr | |
> | dw_platform_biz_distinct_start_hour_avg_zy_send | |
> | dw_platform_biz_distinct_city_general_hh_create_ecr | |
> | dw_platform_biz_distinct_start_dest_avg_zy_send | |
> | dw_platform_biz_distinct_start_dest_hour_ecr | |
> | dw_platform_biz_distinct_start_avg_zy_finish | |
> | dw_platform_biz_distinct_dest_zy_create_ecr | |
> | dw_platform_biz_distinct_start_dest_time_bubble | |
> | dw_platform_biz_distinct_start_zy_create_ecr | |
> | dw_platform_biz_distinct_start_dest_hour_hh_compete_cr | |
> | P维度特征 | pas_ecr_1month | |
> | pas_bub_cnt_1month | |
> | pas_called_distance_max_1month | |
> | pas_called_distance_avg_1month | |
> | pas_called_distance_min_1month | |
> | pas_uncalled_distance_max_1month | |
> | pas_uncalled_distance_avg_1month | |
> | pas_uncalled_distance_min_1month | |
> | pas_called_min_fee_cpm_max_1month | |
> | pas_called_min_fee_cpm_avg_1month | |
> | pas_called_min_fee_cpm_min_1month | |
> | pas_called_th_fee_ratio_max_1month | |
> | pas_called_th_fee_ratio_avg_1month | |
> | pas_called_th_fee_ratio_min_1month | |
> | pas_called_kc_fee_ratio_max_1month | |
> | pas_called_kc_fee_ratio_avg_1month | |
> | pas_called_kc_fee_ratio_min_1month | |
> | pas_called_one_price_basic_ratio_max_1month | |
> | pas_called_one_price_basic_ratio_avg_1month | |
> | pas_called_one_price_basic_ratio_min_1month | |
> | 竞争历史特征 | acti_pas_ecr_1month | |
> | acti_pas_called_one_price_basic_ratio_avg_1month | |
> | acti_pas_called_one_price_basic_ratio_max_1month | |
> | other_sm_cnt_weekday_28d | |
> | pbd_gd_sm_cnt_30d | |
> | sm_cnt_weekday_14d | |
> | sm_cnt_weekend_28d | |
> | sm_cnt_weekday_28d | |
> | dm_user_base_oneid_info_last_use_kflw | |
> | dm_user_vzt_pub_rfmpeat_kflw_a | |
> | dm_user_vzt_pub_rfmpeat_ut_f | |
> | dm_user_vzt_pub_rfmpeat_other_p | |
> | dm_user_mkt_netcar_ordacc_gcsv2_cost_mean | |
> | dm_user_vzt_pub_rfmpeat_other_synth | |
> | dm_user_base_oneid_info_age | |
> | dm_user_vzt_pub_rfmpeat_btls_a | |
> | dm_user_mkt_netcar_ordacc_jie_subsidy_c_order_ratio | |
> | dm_user_mkt_biz_abst_kflw_cancel_types_divg | |
> | dm_user_vzt_pub_rfmpeat_ut_a | |
> | dm_user_behv_netcar_htpp_vzt_city_num | |
> | dm_user_vzt_pub_rfmpeat_ut_r | |
> | hxz_finish_asp_28d | |
> | is_kf_student_verify | |
> | hxz_finish_cnt_weekday_28d | |
> | dd_kf_sm_bubble_cnt_14d | |
> | pbd_bubble_cnt_weekday_28d | |
> | wyc_bubble_cnt_1d | |
> | pbd_bubble_cnt_7d | |
> | call_ratio_7d | |
> | dd_pbd_sm_bubble_cnt_7d | |
> | hxz_finish_cnt_7d | |
> | dd_gd_sm_cnt_30d | |
> | kf_gd_sm_cnt_30d | |
> | hxz_finish_cnt_28d | |
> | call_ratio_28d | |
> | kf_gd_sm_cnt_7d | |
> | wyc_bubble_cnt_14d | |
> | is_5d_sm | |
> | is_1d_sm | |
> | is_3d_sm | |
> | is_14d_sm | |
> | is_28d_sm | |
> | is_10d_sm | |
> | 竞争实时特征 <br>暂未使用 | didi_order_created_total_cnt_S60 | |
> | didi_bubble_total_cnt_S120 | |
> | didi_order_created_cnt_S30 | |
> | didi_bubble_total_avg_estimate_time_minutes_S60 | |
> | didi_bubble_total_avg_estimate_distance_metre_S120 | |
> | tencent_service_order_created_total_cnt_S60 | |
> | tencent_service_order_created_cnt_S30 | |


### 2.2 决策公式

x：平台呼返折扣，假设平台呼返折扣都为0，即100折

y：盒子呼返折扣

| 版本 | 公式 | |
| --- | --- | --- |
| V6 | $$b*y^2+c*y+d$$ | |
| V7 | $$a_1*y+c_1*y+a_0$$ | |
| V8 | $$a_i*y_i+b_i+c$$ | |

### 2.3 DRCFR 训练调优

DRCFR+分段函数

> [!example]- 完整数据表（6 行记录）
> | epoch | batch_size | imbalance | t | ate | lr | aucc | qini | dini | ate_error | call_algo_mtaucc | call_random_mtaucc | qini | mtaucc | 值准 |
> | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
> | 20 | 2048 | 0.0002 | 0.01 | 0.01 | 1e-4 | 0.4679 | 0.1877 | 0.1958 | 0.0036 | 0.6102 | 0.3418 | ![](37e83145e434d43e-截屏2025-09-17下午5.11.43.png) | ![](25e6d1dabaf2ba42-截屏2025-09-17下午5.10.53.png) | ![](8cbf5bf67338f9f0-image.png) |
> | 10 | 2048 | 0.002 | 0.01 | 0.01 | 1e-4 | 0.4382 | 0.217 | 0.2156 | 0.0053 | 0.56 | 0.364 | ![](21e39ed739dcf20d-截屏2025-09-17下午6.55.13.png) | ![](7710a9b2bad2c24c-截屏2025-09-17下午6.54.57.png) | |
> | 20 | 2048 | 0.02 | 0.01 | 0.01 | 1e-4 | 0.4706 | 0.2433 | 0.238 | 0.0047 | 0.6072 | 0.3528 | ![](d56239ea5a12d9d7-截屏2025-09-17下午5.13.34.png) | ![](64368df74fc77ec0-截屏2025-09-17下午5.13.08.png) | |
> | 10 | 2048 | 0.0002 | 0.01 | 0.001 | 1e-4 | 0.4739 | 0.2429 | 0.2564 | 0.0059 | 0.581 | 0.3542 | ![](26227190a3e8f2bd-截屏2025-09-17下午6.49.12.png) | ![](0f160d4e9579c8ca-截屏2025-09-17下午6.48.50.png) | ![](21f3ab9116fb43c8-截屏2025-09-17下午7.13.18.png) |
> | 20 | 2048 | 0.0002 | 0.01 | 0.001 | 1e-4 | 0.465 | 0.2275 | 0.241 | 0.0037 | 0.5636 | 0.3629 | ![](9500a5bb181dd005-截屏2025-09-18下午2.41.56.png) | ![](8a81524874e6f48c-image.png) | ![](80ffcd58f5745acb-截屏2025-09-18下午2.43.59.png) |
> | 10 | 2048 | 0.0002 | 0.01 | 0.0001 | 1e-4 | 0.4563 | 0.2315 | 0.2365 | 0.0059 | 0.4989 | 0.3454 | ![](fcf6ed0d0d370ceb-截屏2025-09-17下午6.58.51.png) | ![](7bf8a39ce48a7725-截屏2025-09-17下午6.58.29.png) | |


## 3 ECR仿真

仿真特征表：kflower_strategy.dm_ecr_simulation_data_with_p_features

仿真eve任务：<https://ether.intra.hongyibo.com.cn/labs/new/15008>

仿真结果落表：kflower_strategy.luckybox_offline_data_model_result_ecr
