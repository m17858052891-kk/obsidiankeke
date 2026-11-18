---
title: "acc_cr模型特征一览"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2205679248871
cssclasses: ["strategy-body-note"]
---

# acc_cr模型特征一览

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2205679248871)

按特征链路、品类与优先级定义、处理逻辑查字段。模型输入的字段名与取值约定保持原样。

**阅读定位**　[[#1 特征链路|1 特征链路]] · [[#2 定义|2 定义]] · [[#3 特征处理逻辑|3 特征处理逻辑]]

## 1 特征链路

![](1ccbbd11b9a03347-流程图.svg)

```flowchart
{"type": "flowchart", "sourceId": "MjIwNTY3OTMxNjI3Ng", "version": "4", "fileUrl": "../../../%E9%99%84%E4%BB%B6/1c/1ccbbd11b9a03347-%E6%B5%81%E7%A8%8B%E5%9B%BE.svg"}
```

## 2 定义

### 2.1 品类定义

1. 对于自营品类，product_id = 80

	1. 特快盒子：特快盒子内的小猪特快（200）

	2. 盒子外：小猪一口价（102）、小猪打车（103），取max

	3. 特价盒子：特价盒子内的小猪特价（105）、超值达（201，端内无）、~~出行快选（202），~~取max

2. 对于宏鹄，product_id != 80

	1. 特快盒子：特快盒子（200）

	2. 盒子外：普通品类（0）

	3. 特价盒子：特价盒子（105）、超值达（201），取max

### 2.2 发单优先级

参考文档：<https://cooper.didichuxing.com/docs2/document/2203352674960>

| 相对优先级 | 不同品类优先级可相同 | 取模型的值 |
| --- | --- | --- |
| 3 | 101（小猪特快）、200（特快盒子） | 取特快盒子 |
| 2 | 0（普通品类）、102（小猪一口价）、103（小猪打车） | 取盒子外 |
| 1 | 104（小猪特价）、105（特价盒子）、~~202（出行快选）~~、201（超值达） | 取特价盒子 |
| 0 | 107（幸运盒子） | 取特价盒子 |
| 绝对优先级 | **相对优先级相同的品类，若实付不一致时，按实付价格高的，发单优先级高**；若实付一致，理论应该用绝对优先级，此处忽略这个问题 | |

## 3 特征处理逻辑

### 3.0 特征一览

| 分类 | 特征 | 维度/key | 精度类型 | 缺失值处理 | 落表 |
| --- | --- | --- | --- | --- | --- |
| 传入特征 | city_id <br>hour_of_day <br>day_of_week | trace_id | int | 0 <br>0 <br>2 | / |
| 应付、实付、应付-实付、cpm、iph | trace_id <br>product_id <br>特快盒子、盒子外、特价盒子 | double <br>保留6位小数 | -9999 |
| eta、etd、estimate_v | trace_id <br>product_id |
| 默勾sds特征 | - 1/3/10/实时 X 中心格子/一圈格子 <br><br>	- 自营+宏鹄空车司机数、自营+宏鹄在线司机数 <br><br>- 1/3/10分钟 X 中心格子/一圈格子  <br><br>	- 小猪端冒泡数、客观呼单数、应答数、完单数、商家举手数、单均应答时长、单均接驾时长、单均接驾距离、应答率 <br><br>- 实时 X 中心格子/一圈格子  <br><br>	- 未播订单数 <br> | product_id <br>start_grid_id | |
| 熔断特征 | - 过去5分钟 X 城市/格子 <br><br>	- 呼叫数、应答数、开始计费数、乘客取消数-不含改、司机取消数-不含改、乘客取消数-含改、司机取消数-含改 <br><br>	- 应答率、开始计费完单率、取消数-不含改、取消数-含改、取消率-不含改、取消率-含改 <br> | product_id <br>start_grid_id | |
| 商家维度历史特征 | - 7日 <br><br>	- 竞争呼叫数、举手参与订单数、应答数、完单数、应答后乘客取消数、应答后司机取消数-含改、举手参与司机数、应答司机数、应答时长、平均应答时长、接驾司机数、接驾时长、平均接驾时长 <br> | product_id <br>city_id | kflower_app.app_kf_trd_answer_strategy_index_week_di |
| - 7/14日平均 <br><br>	- 冒泡数、呼叫数、完单数、应答订单数、应答司机数、应答后司机取消数、应答后乘客取消数、举手司机数 <br><br>	- 接驾时长、接驾距离 <br><br>	- 应答率 <br> | product_id <br>start_grid_id <br>time_slice（每半小时） | kflower_marketplace.dwm_kf_grid_time_slice_days_data_di |
| - 7/14日 <br><br>	- 应答数、取消数、乘客取消数、司机取消数、完单数 <br><br>	- 应答率、取消率、乘客取消率、司机取消率、完单率 <br><br>	- 最大/最小/平均 X 完单/应答/取消 etd、应付、cpm、iph、eta <br> | product_id <br>hour_of_day(0-23) <br>is_weekday(1:周一-周四；0:周五-周日) <br>city_id | ar_model_feature_generate_groupby_product |
| 乘客维度历史特征 | - 7/14日 <br><br>	- 应答数、取消数、乘客取消数、司机取消数、完单数 <br><br>	- 单均应答/取消/乘客取消/司机取消 商家数 <br><br>	- 应答率、取消率、乘客取消率、司机取消率、完单率 <br><br>	- 最大/最小/平均 X 完单/应答/取消 etd、实付、应付-实付、cpm、eta <br> | passenger_id | ar_model_feature_generate_groupby_pas |

### 3.1 传入特征

特征表：cr_model_train_data

数梦任务：<https://studio.data.didichuxing.com/batch?projectId=1143&taskId=50113287>

> [!example]- 完整数据表（22 行记录）
> | 分类类型 | 特征名 | 含义/计算逻辑 | 维度/key | 精度类型 | 缺失值处理 |
> | --- | --- | --- | --- | --- | --- |
> | 随单特征 | city_id | 发单起点城市 | trace_id | int | 填充0 |
> | hour_of_day | 小时，1-24 | 填充0 |
> | is_weekday | 是否周末 <br>1：2（周一）-5（周四） <br>0：其他 <br>模型未用，取商家维度历史特征时用 | 填充2 |
> | day_of_week | 1（周日）-7（周六） | 填充0 |
> | 价格特征 | ufbox_basic_fee | 单位：分 <br>basic_total_fee = 应付 <br>estimate_fee = 实付 <br>fee_diff = basic_total_fee - estimate_fee <br> | trace_id <br>product_id <br>特快盒子、盒子外、特价盒子 | double <br>保留6位小数 | **按照【盒子外&gt;特价盒子内&gt;特快盒子内】的优先级填充** <br>缺失时填充-9999 |
> | outbox_basic_fee |
> | uabox_basic_fee |
> | ufbox_estimate_fee |
> | outbox_estimate_fee |
> | uabox_estimate_fee |
> | ufbox_fee_diff |
> | outbox_fee_diff |
> | uabox_fee_diff |
> | 里程特征 | start_dest_dis | 里程，单位米 | trace_id <br>product_id | **按照盒子外&gt;特价盒子&gt;特快盒子优先级，取优先级高的** <br>缺失时填充-9999 |
> | estimate_dur | 预估送驾时长，单位秒 |
> | estimate_v | 速度，start_dest_dis / estimate_dur，单位米/秒 |
> | 计算值 | ufbox_cpm | 得到价格特征、里程特征后计算得到 <br>cpm=basic_total_fee / start_dest_dis，单位分/米 <br>iph=basic_total_fee / estimate_dur，单位分/秒 | trace_id <br>product_id <br>特快盒子、盒子外、特价盒子 | 缺失值填充-9999 |
> | outbox_cpm |
> | uabox_cpm |
> | ufbox_iph |
> | outbox_iph |
> | uabox_iph |


### 3.2 sds特征-实时商家X格子交易漏斗

> [BRD+详细描述](https://cooper.didichuxing.com/knowledge/share/page/40t0QGYBWTb9#%E9%A1%B5%E9%9D%A2%E3%80%8A%E9%BB%98%E5%8B%BE%E7%AD%96%E7%95%A5AR%E6%A8%A1%E5%9E%8B%E7%89%B9%E5%BE%81%E4%BC%98%E5%8C%96%E3%80%8B)

日志底表：kflower_strategy.ods_log_kflower_ether_price_anchor_cr_model、kflower_marketplace.ods_log_kflower_dups_eve_public_log_h

特征表：zy_cr_model_test_data_v1

数梦任务：<https://studio.data.didichuxing.com/batch?projectId=1143&taskId=33975853>

维度：product_id X start_grid_id

> [!example]- 完整数据表（68 行记录）
> | 类型 | 特征名 | 含义 | 类型 | 缺失值处理 |
> | --- | --- | --- | --- | --- |
> | | merchant_answer_cnt_10m | 10分钟内中心格子应答数 | double <br>保留6位小数 | 填充-9999.0 |
> | | merchant_answer_cnt_10m_one_circle_grid | 10分钟内一圈格子应答数 |
> | | merchant_answer_cnt_1m | 1分钟内中心格子应答数 |
> | | merchant_answer_cnt_1m_one_circle_grid | 1分钟内一圈格子应答数 |
> | | merchant_answer_cnt_3m | 3分钟内中心格子应答数 |
> | | merchant_answer_cnt_3m_one_circle_grid | 3分钟内一圈格子应答数 |
> | | merchant_ar_10m | 10分钟内中心格子应答率 |
> | | merchant_ar_10m_one_circle_grid | 10分钟内一圈格子应答率 |
> | | merchant_call_cnt_10m | 10分钟内中心格子客观呼单数 |
> | | merchant_call_cnt_10m_one_circle_grid | 10分钟内一圈格子客观呼单数 |
> | | merchant_call_cnt_1m | 1分钟内中心格子客观呼单数 |
> | | merchant_call_cnt_1m_one_circle_grid | 1分钟内一圈格子客观呼单数 |
> | | merchant_call_cnt_3m | 3分钟内中心格子客观呼单数 |
> | | merchant_call_cnt_3m_one_circle_grid | 3分钟内一圈格子客观呼单数 |
> | | merchant_finish_cnt_10m | 10分钟内中心格子完单数 |
> | | merchant_finish_cnt_10m_one_circle_grid | 10分钟内一圈格子完单数 |
> | | merchant_finish_cnt_1m | 1分钟内中心格子完单数 |
> | | merchant_finish_cnt_1m_one_circle_grid | 1分钟内一圈格子完单数 |
> | | merchant_finish_cnt_3m | 3分钟内中心格子完单数 |
> | | merchant_finish_cnt_3m_one_circle_grid | 3分钟内一圈格子完单数 |
> | | merchant_hands_cnt_10m | 10分钟内中心格子商家举手数 |
> | | merchant_hands_cnt_10m_one_circle_grid | 10分钟内一圈格子商家举手数 |
> | | merchant_hands_cnt_1m | 1分钟内中心格子商家举手数 |
> | | merchant_hands_cnt_1m_one_circle_grid | 1分钟内一圈格子商家举手数 |
> | | merchant_hands_cnt_3m | 3分钟内中心格子商家举手数 |
> | | merchant_hands_cnt_3m_one_circle_grid | 3分钟内一圈格子商家举手数 |
> | | online_driver_cnt_1m | 1分钟内中心格子自营+宏鹄在线司机数（1分钟去重累计） |
> | | online_driver_cnt_1m_one_circle_grid | 1分钟内一圈格子自营+宏鹄在线司机数（1分钟去重累计） |
> | | online_driver_cnt_3m | 3分钟内中心格子自营+宏鹄在线司机数（1分钟去重累计） |
> | | online_driver_cnt_3m_one_circle_grid | 3分钟内一圈格子自营+宏鹄在线司机数（1分钟去重累计） |
> | | online_driver_cnt10m | 10分钟内中心格子自营+宏鹄在线司机数（1分钟去重累计） |
> | | online_driver_cnt10m_one_circle_grid | 10分钟内一圈格子自营+宏鹄在线司机数（1分钟去重累计） |
> | | realtime_empty_driver_cnt | 实时中心格子自营+宏鹄空车司机数（1分钟去重累计） |
> | | realtime_empty_driver_cnt_one_circle_grid | 实时一圈格子自营+宏鹄空车司机数（1分钟去重累计） |
> | | realtime_no_broadcast_cnt -- 暂时不用 | 实时中心格子未播订单数 |
> | | realtime_no_broadcast_cnt_one_circle_grid -- 暂时不用 | 实时一圈格子未播订单数 |
> | | realtime_online_driver_cnt | 实时中心格子自营+宏鹄在线司机数（1分钟去重累计） |
> | | realtime_online_driver_cnt_one_circle_grid | 实时一圈格子自营+宏鹄在线司机数（1分钟去重累计） |
> | | snapshot_realtime_empty_driver_cnt_10m | 10分钟中心格子自营+宏鹄空车司机数（1分钟去重累计） |
> | | snapshot_realtime_empty_driver_cnt_10m_one_circle_grid | 10分钟一圈格子自营+宏鹄空车司机数（1分钟去重累计） |
> | | snapshot_realtime_empty_driver_cnt_1m | 1分钟中心格子自营+宏鹄空车司机数（1分钟去重累计） |
> | | snapshot_realtime_empty_driver_cnt_1m_one_circle_grid | 1分钟一圈格子自营+宏鹄空车司机数（1分钟去重累计） |
> | | snapshot_realtime_empty_driver_cnt_3m | 3分钟中心格子自营+宏鹄空车司机数（1分钟去重累计） |
> | | snapshot_realtime_empty_driver_cnt_3m_one_circle_grid | 3分钟一圈格子自营+宏鹄空车司机数（1分钟去重累计） |
> | | srived_order_epd_sum_10m | 10分钟内中心格子单均接驾距离，单位米 |
> | | srived_order_epd_sum_10m_one_circle_grid | 10分钟内一圈格子单均接驾距离，单位米 |
> | | srived_order_epd_sum_1m | 1分钟内中心格子单均接驾距离，单位米 |
> | | srived_order_epd_sum_1m_one_circle_grid | 1分钟内一圈格子单均接驾距离，单位米 |
> | | srived_order_epd_sum_3m | 3分钟内中心格子单均接驾距离，单位米 |
> | | srived_order_epd_sum_3m_one_circle_grid | 3分钟内一圈格子单均接驾距离，单位米 |
> | | srived_order_ept_sum_10m | 10分钟内中心格子单均接驾时长，单位秒 |
> | | srived_order_ept_sum_10m_one_circle_grid | 10分钟内一圈格子单均接驾时长，单位秒 |
> | | srived_order_ept_sum_1m | 1分钟内中心格子单均接驾时长，单位秒 |
> | | srived_order_ept_sum_1m_one_circle_grid | 1分钟内一圈格子单均接驾时长，单位秒 |
> | | srived_order_ept_sum_3m | 3分钟内中心格子单均接驾时长，单位秒 |
> | | srived_order_ept_sum_3m_one_circle_grid | 3分钟内一圈格子单均接驾时长，单位秒 |
> | | strive_order_time_sum_10m | 10分钟内中心格子单均应答时长，单位秒 |
> | | strive_order_time_sum_10m_one_circle_grid | 10分钟内一圈格子单均应答时长，单位秒 |
> | | strive_order_time_sum_1m | 1分钟内中心格子单均应答时长，单位秒 |
> | | strive_order_time_sum_1m_one_circle_grid | 1分钟内一圈格子单均应答时长，单位秒 |
> | | strive_order_time_sum_3m | 3分钟内中心格子单均应答时长，单位秒 |
> | | strive_order_time_sum_3m_one_circle_grid | 3分钟内一圈格子单均应答时长，单位秒 |
> | | bubble_minute_unique_cnt_10m | 10分钟内中心格子小猪端冒泡数（1分钟用户维度去重） |
> | | bubble_minute_unique_cnt_10m_one_circle_grid | 10分钟内一圈格子小猪端冒泡数（1分钟用户维度去重） |
> | | bubble_minute_unique_cnt_1m | 1分钟内中心格子小猪端冒泡数（1分钟用户维度去重） |
> | | bubble_minute_unique_cnt_1m_one_circle_grid | 1分钟内一圈格子小猪端冒泡数（1分钟用户维度去重） |
> | | bubble_minute_unique_cnt_3m | 3分钟内中心格子小猪端冒泡数（1分钟用户维度去重） |
> | | bubble_minute_unique_cnt_3m_one_circle_grid | 3分钟内一圈格子小猪端冒泡数（1分钟用户维度去重） |


### 3.3 熔断特征

日志底表：kflower_marketplace.ods_log_kflower_platform_call_return_public_log_h

问题：几分钟？key？找具体文档

> [!example]- 完整数据表（30 行记录）
> | 类型 | 特征名 | 含义/计算逻辑 | 类型 | 缺失值处理 |
> | --- | --- | --- | --- | --- |
> | 城市维度 | city_order_count | 城市订单数 | double <br>保留6位小数 | 填充-9999.0 |
> | city_answer_count | 城市应答订单数 |
> | city_start_billing | 城市计费订单数 |
> | city_passenger_cancel_exclude_reassign | 城市乘客取消数-不含改 |
> | city_driver_cancel_exclude_reassign | 城市司机取消数-不含改 |
> | city_passenger_cancel_include_reassign | 城市乘客取消数-含改 |
> | city_driver_cancel_include_reassign | 城市司机取消数-含改 |
> | city_ar | city_answer_count / city_order_count |
> | city_cr_billing | city_start_billing / city_order_count |
> | city_cancel_count_exclude_reassign | city_passenger_cancel_exclude_reassign + city_driver_cancel_exclude_reassign |
> | city_cancel_count_include_reassign | city_passenger_cancel_include_reassign + city_driver_cancel_include_reassign |
> | city_cancel_rate_exclude_reassign | (city_passenger_cancel_exclude_reassign + city_driver_cancel_exclude_reassign) / city_order_count |
> | city_cr_exclude_reassign | ((city_passenger_cancel_exclude_reassign + city_driver_cancel_exclude_reassign) / city_order_count) |
> | city_cancel_rate_include_reassign | (city_passenger_cancel_include_reassign + city_driver_cancel_include_reassign) / city_order_count |
> | city_cr_include_reassign | ((city_passenger_cancel_include_reassign + city_driver_cancel_include_reassign) / city_order_count) \* (city_answer_count / city_order_count) |
> | 格子维度 | first_circle_order_count | |
> | first_circle_answer_count | |
> | grid_start_billing | |
> | grid_passenger_cancel_exclude_reassign | |
> | grid_driver_cancel_exclude_reassign | |
> | grid_passenger_cancel_include_reassign | |
> | grid_driver_cancel_include_reassign | |
> | grid_ar | |
> | grid_cr_billing | |
> | grid_cancel_count_exclude_reassign | |
> | grid_cancel_count_include_reassign | |
> | grid_cancel_rate_exclude_reassign | |
> | grid_cr_exclude_reassign | |
> | grid_cancel_rate_include_reassign | |
> | grid_cr_include_reassign | |


### 3.4 商家维度历史特征

#### 交易漏斗(冒泡->完单)-from工程

> [!example]- 完整数据表（43 行记录）
> | 类型 | 特征名 | 含义 | 维度/key | 类型 | 缺失值处理 |
> | --- | --- | --- | --- | --- | --- |
> | 城市 <br>交易漏斗 | 底表：kflower_app.app_kf_trd_answer_strategy_index_week_di |
> | hxz_product_city_compete_call_cnt_7d | 近7日竞争呼叫订单数 | product_id <br>city_id | double <br>保留6位小数 | 填充-9999 |
> | hxz_product_city_participate_cnt_7d | 近7日举手参与订单数 |
> | hxz_product_city_answer_cnt_7d | 近7日应答订单数 |
> | hxz_product_city_finish_cnt_7d | 近7日完成订单数 |
> | hxz_product_city_aft_ansr_pas_cl_cnt_7d | 近7日应答后乘客取消订单数 |
> | hxz_product_city_aft_ansr_dri_cl_cnt_7d | 近7日应答后司机取消订单数（含改派单） |
> | hxz_product_city_participate_dri_cnt_7d | 近7日举手参与司机数 |
> | hxz_product_city_answer_dri_cnt_7d | 近7日应答司机数 |
> | hxz_product_city_answer_dur_7d | 近7日应答时长，秒 |
> | hxz_product_city_avg_answer_dur_7d | 近7日平均应答时长，秒 |
> | hxz_product_city_arrive_cnt_7d | 近7日接驾司机数 |
> | hxz_product_city_arrive_dur_7d | 近7日接驾时长，秒 |
> | hxz_product_city_avg_arrive_dur_7d | 近7日平均接驾时长，秒 |
> | 类型 | 特征名 | 含义 | 维度 | 类型 | 缺失值处理 |
> | 格子X半小时 <br>交易漏斗 | 底表：kflower_marketplace.dwm_kf_grid_time_slice_days_data_di |
> | hxz_product_start_grid_time_slice_answer_cnt_14d | 14日半小时平均应答数 | product_id <br>start_grid <br>time_slice(值域?) | double <br>保留6位小数 | 填充-9999 |
> | hxz_product_start_grid_time_slice_answer_cnt_7d | 7日半小时平均应答数 |
> | hxz_product_start_grid_time_slice_answer_driver_cnt_14d | 14日半小时平均应答司机数 |
> | hxz_product_start_grid_time_slice_answer_driver_cnt_7d | 7日半小时平均应答司机数 |
> | hxz_product_start_grid_time_slice_answer_order_cnt_14d | 14日半小时平均应答订单数 |
> | hxz_product_start_grid_time_slice_answer_order_cnt_7d | 7日半小时平均应答订单数 |
> | hxz_product_start_grid_time_slice_answer_ratio_14d | 14日半小时总应答率 |
> | hxz_product_start_grid_time_slice_answer_ratio_7d | 7日半小时总应答率 |
> | hxz_product_start_grid_time_slice_avg_answer_dur_14d | 14日半小时平均应答时长 |
> | hxz_product_start_grid_time_slice_avg_answer_dur_7d | 7日半小时平均应答时长 |
> | hxz_product_start_grid_time_slice_avg_pick_dist_14d | 14日半小时平均接驾距离 |
> | hxz_product_start_grid_time_slice_avg_pick_dist_7d | 7日半小时平均接驾距离 |
> | hxz_product_start_grid_time_slice_avg_pick_dur_14d | 14日半小时平均接驾时长 |
> | hxz_product_start_grid_time_slice_avg_pick_dur_7d | 7日半小时平均接驾时长 |
> | hxz_product_start_grid_time_slice_bubble_cnt_7d | 7日半小时平均冒泡数 |
> | hxz_product_start_grid_time_slice_call_cnt_14d | 14日半小时平均呼叫数 |
> | hxz_product_start_grid_time_slice_call_cnt_7d | 7日半小时平均呼叫数 |
> | hxz_product_start_grid_time_slice_dri_cancel_after_answer_cnt_14d | 14日半小时平均应答后司机取消数 |
> | hxz_product_start_grid_time_slice_dri_cancel_after_answer_cnt_7d | 7日半小时平均应答后司机取消数 |
> | hxz_product_start_grid_time_slice_finish_cnt_14d | 14日半小时平均完单数 |
> | hxz_product_start_grid_time_slice_finish_cnt_7d | 7日半小时平均完单数 |
> | hxz_product_start_grid_time_slice_hands_driver_cnt_14d | 14日半小时平均举手司机数 |
> | hxz_product_start_grid_time_slice_hands_driver_cnt_7d | 7日半小时平均举手司机数 |
> | hxz_product_start_grid_time_slice_hands_order_cnt_14d | 14日半小时平均举手订单数 |
> | hxz_product_start_grid_time_slice_hands_order_cnt_7d | 7日半小时平均举手订单数 |
> | hxz_product_start_grid_time_slice_pas_cancel_after_answer_cnt_14d | 14日半小时应答后乘客取消数 |
> | hxz_product_start_grid_time_slice_pas_cancel_after_answer_cnt_7d | 7日半小时应答后乘客取消数 |


#### 交易漏斗(应答-完单)-from策略

表名：ar_model_feature_generate_groupby_product

数梦任务：<https://studio.data.didichuxing.com/batch?projectId=1143&taskId=50068779>

key：product_id、hour_of_day(0-23)、is_weekday（0:周一-周四；1:周五-周日）、city_id

> [!example]- 完整数据表（110 行记录）
> | 分类 | 特征名 | 含义 | 类型 | 缺失值处理 |
> | --- | --- | --- | --- | --- |
> | / | product_ans_cnt_7d | 7日应答订单数 | double <br>保留6位小数 | 填充-9999 |
> | product_cancel_cnt_7d | 7日取消订单数 |
> | product_p_cancel_cnt_7d | 7日乘客取消订单数 |
> | product_d_cancel_cnt_7d | 7日司机取消订单数 |
> | product_finish_cnt_7d | 7日完单数 |
> | product_ans_rate_7d | 7日应答率 |
> | product_cancel_rate_7d | 7日取消率 |
> | product_p_cancel_rate_7d | 7日乘客取消率 |
> | product_d_cancel_rate_7d | 7日司机取消率 |
> | product_finish_rate_7d | 7日完单率 |
> | product_finish_max_distance_7d | 7日最大完单订单距离，单位米 |
> | product_finish_min_distance_7d | 7日最小完单订单距离，单位米 |
> | product_finish_avg_distance_7d | 7日平均完单订单距离，单位米 |
> | product_answer_max_distance_7d | 7日最大应答订单距离，单位米 |
> | product_answer_min_distance_7d | 7日最小应答订单距离，单位米 |
> | product_answer_avg_distance_7d | 7日平均应答订单距离，单位米 |
> | product_cancel_max_distance_7d | 7日最大取消订单距离，单位米 |
> | product_cancel_min_distance_7d | 7日最小取消订单距离，单位米 |
> | product_cancel_avg_distance_7d | 7日平均取消订单距离，单位米 |
> | product_finish_max_basic_fee_7d | 7日最大完单应付，单位分 |
> | product_finish_min_basic_fee_7d | 7日最小完单应付，单位分 |
> | product_finish_avg_basic_fee_7d | 7日平均完单应付，单位分 |
> | product_answer_max_basic_fee_7d | 7日最大应答应付，单位分 |
> | product_answer_min_basic_fee_7d | 7日最小应答应付，单位分 |
> | product_answer_avg_basic_fee_7d | 7日平均应答应付，单位分 |
> | product_cancel_max_basic_fee_7d | 7日最大取消应付，单位分 |
> | product_cancel_min_basic_fee_7d | 7日最小取消应付，单位分 |
> | product_cancel_avg_basic_fee_7d | 7日平均取消应付，单位分 |
> | product_finish_max_cpm_7d | 7日最大完单cpm，单位分/米 |
> | product_finish_min_cpm_7d | 7日最小完单cpm，单位分/米 |
> | product_finish_avg_cpm_7d | 7日平均完单cpm，单位分/米 |
> | product_answer_max_cpm_7d | 7日最大应答cpm，单位分/米 |
> | product_answer_min_cpm_7d | 7日最小应答cpm，单位分/米 |
> | product_answer_avg_cpm_7d | 7日平均应答cpm，单位分/米 |
> | product_cancel_max_cpm_7d | 7日最大取消cpm，单位分/米 |
> | product_cancel_min_cpm_7d | 7日最小取消cpm，单位分/米 |
> | product_cancel_avg_cpm_7d | 7日平均取消cpm，单位分/米 |
> | product_finish_max_iph_7d | 7日最大完单iph，单位分/秒 |
> | product_finish_min_iph_7d | 7日最小完单iph，单位分/秒 |
> | product_finish_avg_iph_7d | 7日平均完单iph，单位分/秒 |
> | product_answer_max_iph_7d | 7日最大应答iph，单位分/秒 |
> | product_answer_min_iph_7d | 7日最小应答iph，单位分/秒 |
> | product_answer_avg_iph_7d | 7日平均应答iph，单位分/秒 |
> | product_cancel_max_iph_7d | 7日最大取消iph，单位分/秒 |
> | product_cancel_min_iph_7d | 7日最小取消iph，单位分/秒 |
> | product_cancel_avg_iph_7d | 7日平均取消iph，单位分/秒 |
> | product_finish_max_estimate_dur_7d | 7日最大完单eta，单位秒 |
> | product_finish_min_estimate_dur_7d | 7日最小完单eta，单位秒 |
> | product_finish_avg_estimate_dur_7d | 7日平均完单eta，单位秒 |
> | product_answer_max_estimate_dur_7d | 7日最大应答eta，单位秒 |
> | product_answer_min_estimate_dur_7d | 7日最小应答eta，单位秒 |
> | product_answer_avg_estimate_dur_7d | 7日平均应答eta，单位秒 |
> | product_cancel_max_estimate_dur_7d | 7日最大取消eta，单位秒 |
> | product_cancel_min_estimate_dur_7d | 7日最小取消eta，单位秒 |
> | product_cancel_avg_estimate_dur_7d | 7日平均取消eta，单位秒 |
> | product_ans_cnt_14d | 14日应答订单数 |
> | product_cancel_cnt_14d | 14日取消订单数 |
> | product_p_cancel_cnt_14d | 14日乘客取消订单数 |
> | product_d_cancel_cnt_14d | 14日司机取消订单数 |
> | product_finish_cnt_14d | 14日完单数 |
> | product_ans_rate_14d | 14日应答率 |
> | product_cancel_rate_14d | 14日取消率 |
> | product_p_cancel_rate_14d | 14日乘客取消率 |
> | product_d_cancel_rate_14d | 14日司机取消率 |
> | product_finish_rate_14d | 14日完单率 |
> | product_finish_max_distance_14d | 14日最大完单订单距离，单位米 |
> | product_finish_min_distance_14d | 14日最小完单订单距离，单位米 |
> | product_finish_avg_distance_14d | 14日平均完单订单距离，单位米 |
> | product_answer_max_distance_14d | 14日最大应答订单距离，单位米 |
> | product_answer_min_distance_14d | 14日最小应答订单距离，单位米 |
> | product_answer_avg_distance_14d | 14日平均应答订单距离，单位米 |
> | product_cancel_max_distance_14d | 14日最大取消订单距离，单位米 |
> | product_cancel_min_distance_14d | 14日最小取消订单距离，单位米 |
> | product_cancel_avg_distance_14d | 14日平均取消订单距离，单位米 |
> | product_finish_max_basic_fee_14d | 14日最大完单应付，单位分 |
> | product_finish_min_basic_fee_14d | 14日最小完单应付，单位分 |
> | product_finish_avg_basic_fee_14d | 14日平均完单应付，单位分 |
> | product_answer_max_basic_fee_14d | 14日最大应答应付，单位分 |
> | product_answer_min_basic_fee_14d | 14日最小应答应付，单位分 |
> | product_answer_avg_basic_fee_14d | 14日平均应答应付，单位分 |
> | product_cancel_max_basic_fee_14d | 14日最大取消应付，单位分 |
> | product_cancel_min_basic_fee_14d | 14日最小取消应付，单位分 |
> | product_cancel_avg_basic_fee_14d | 14日平均取消应付，单位分 |
> | product_finish_max_cpm_14d | 14日最大完单cpm，单位分/米 |
> | product_finish_min_cpm_14d | 14日最小完单cpm，单位分/米 |
> | product_finish_avg_cpm_14d | 14日平均完单cpm，单位分/米 |
> | product_answer_max_cpm_14d | 14日最大应答cpm，单位分/米 |
> | product_answer_min_cpm_14d | 14日最小应答cpm，单位分/米 |
> | product_answer_avg_cpm_14d | 14日平均应答cpm，单位分/米 |
> | product_cancel_max_cpm_14d | 14日最大取消cpm，单位分/米 |
> | product_cancel_min_cpm_14d | 14日最小取消cpm，单位分/米 |
> | product_cancel_avg_cpm_14d | 14日平均取消cpm，单位分/米 |
> | product_finish_max_iph_14d | 14日最大完单iph，单位分/秒 |
> | product_finish_min_iph_14d | 14日最小完单iph，单位分/秒 |
> | product_finish_avg_iph_14d | 14日平均完单iph，单位分/秒 |
> | product_answer_max_iph_14d | 14日最大应答iph，单位分/秒 |
> | product_answer_min_iph_14d | 14日最小应答iph，单位分/秒 |
> | product_answer_avg_iph_14d | 14日平均应答iph，单位分/秒 |
> | product_cancel_max_iph_14d | 14日最大取消iph，单位分/秒 |
> | product_cancel_min_iph_14d | 14日最小取消iph，单位分/秒 |
> | product_cancel_avg_iph_14d | 14日平均取消iph，单位分/秒 |
> | product_finish_max_estimate_dur_14d | 14日最大完单eta，单位秒 |
> | product_finish_min_estimate_dur_14d | 14日最小完单eta，单位秒 |
> | product_finish_avg_estimate_dur_14d | 14日平均完单eta，单位秒 |
> | product_answer_max_estimate_dur_14d | 14日最大应答eta，单位秒 |
> | product_answer_min_estimate_dur_14d | 14日最小应答eta，单位秒 |
> | product_answer_avg_estimate_dur_14d | 14日平均应答eta，单位秒 |
> | product_cancel_max_estimate_dur_14d | 14日最大取消eta，单位秒 |
> | product_cancel_min_estimate_dur_14d | 14日最小取消eta，单位秒 |
> | product_cancel_avg_estimate_dur_14d | 14日平均取消eta，单位秒 |


### 3.5 乘客维度历史特征

表名：ar_model_feature_generate_groupby_pas

数梦任务：<https://studio.data.didichuxing.com/batch?projectId=1143&taskId=50068793>

key：passenger_id

> [!example]- 完整数据表（118 行记录）
> | 分类 | 特征名 | 含义 | 类型 | 默认值处理 |
> | --- | --- | --- | --- | --- |
> | / | pas_ans_cnt_7d | 7日应答订单数 | double <br>保留6位小数 | 填充-9999 |
> | pas_cancel_cnt_7d | 7日取消订单数 |
> | pas_p_cancel_cnt_7d | 7日乘客取消订单数 |
> | pas_d_cancel_cnt_7d | 7日司机取消订单数 |
> | pas_finish_cnt_7d | 7日完单数 |
> | pas_ans_cp_cnt_7d | 7日单均应答商家数 |
> | pas_cancel_cp_cnt_7d | 7日单均取消商家数 |
> | pas_p_cancel_cp_cnt_7d | 7日单均乘客取消商家数 |
> | pas_d_cancel_cp_cnt_7d | 7日单均司机取消商家数 |
> | pas_ans_rate_7d | 7日应答率 |
> | pas_cancel_rate_7d | 7日取消率 |
> | pas_p_cancel_rate_7d | 7日乘客取消率 |
> | pas_d_cancel_rate_7d | 7日司机取消率 |
> | pas_finish_rate_7d | 7日完单率 |
> | pas_finish_max_distance_7d | 7日最大完单订单距离，单位米 |
> | pas_finish_min_distance_7d | 7日最小完单订单距离，单位米 |
> | pas_finish_avg_distance_7d | 7日平均完单订单距离，单位米 |
> | pas_answer_max_distance_7d | 7日最大应答订单距离，单位米 |
> | pas_answer_min_distance_7d | 7日最小应答订单距离，单位米 |
> | pas_answer_avg_distance_7d | 7日平均应答订单距离，单位米 |
> | pas_cancel_max_distance_7d | 7日最大取消订单距离，单位米 |
> | pas_cancel_min_distance_7d | 7日最小取消订单距离，单位米 |
> | pas_cancel_avg_distance_7d | 7日平均取消订单距离，单位米 |
> | pas_finish_max_est_fee_7d | 7日最大完单实付，单位分 |
> | pas_finish_min_est_fee_7d | 7日最小完单实付，单位分 |
> | pas_finish_avg_est_fee_7d | 7日平均完单实付，单位分 |
> | pas_answer_max_est_fee_7d | 7日最大应答实付，单位分 |
> | pas_answer_min_est_fee_7d | 7日最小应答实付，单位分 |
> | pas_answer_avg_est_fee_7d | 7日平均应答实付，单位分 |
> | pas_cancel_max_est_fee_7d | 7日最大取消实付，单位分 |
> | pas_cancel_min_est_fee_7d | 7日最小取消实付，单位分 |
> | pas_cancel_avg_est_fee_7d | 7日平均取消实付，单位分 |
> | pas_finish_max_cpm_7d | 7日最大完单cpm，单位分/米 |
> | pas_finish_min_cpm_7d | 7日最小完单cpm，单位分/米 |
> | pas_finish_avg_cpm_7d | 7日平均完单cpm，单位分/米 |
> | pas_answer_max_cpm_7d | 7日最大应答cpm，单位分/米 |
> | pas_answer_min_cpm_7d | 7日最小应答cpm，单位分/米 |
> | pas_answer_avg_cpm_7d | 7日平均应答cpm，单位分/米 |
> | pas_cancel_max_cpm_7d | 7日最大取消cpm，单位分/米 |
> | pas_cancel_min_cpm_7d | 7日最小取消cpm，单位分/米 |
> | pas_cancel_avg_cpm_7d | 7日平均取消cpm，单位分/米 |
> | pas_finish_max_fee_diff_7d | 7日最大完单应付-实付，单位分 |
> | pas_finish_min_fee_diff_7d | 7日最小完单应付-实付，单位分 |
> | pas_finish_avg_fee_diff_7d | 7日平均完单应付-实付，单位分 |
> | pas_answer_max_fee_diff_7d | 7日最大应答应付-实付，单位分 |
> | pas_answer_min_fee_diff_7d | 7日最小应答应付-实付，单位分 |
> | pas_answer_avg_fee_diff_7d | 7日平均应答应付-实付，单位分 |
> | pas_cancel_max_fee_diff_7d | 7日最大取消应付-实付，单位分 |
> | pas_cancel_min_fee_diff_7d | 7日最小取消应付-实付，单位分 |
> | pas_cancel_avg_fee_diff_7d | 7日平均取消应付-实付，单位分 |
> | pas_finish_max_estimate_eta_7d | 7日最大完单eta，单位秒 |
> | pas_finish_min_estimate_eta_7d | 7日最小完单eta，单位秒 |
> | pas_finish_avg_estimate_eta_7d | 7日平均完单eta，单位秒 |
> | pas_answer_max_estimate_eta_7d | 7日最大应答eta，单位秒 |
> | pas_answer_min_estimate_eta_7d | 7日最小应答eta，单位秒 |
> | pas_answer_avg_estimate_eta_7d | 7日平均应答eta，单位秒 |
> | pas_cancel_max_estimate_eta_7d | 7日最大取消eta，单位秒 |
> | pas_cancel_min_estimate_eta_7d | 7日最小取消eta，单位秒 |
> | pas_cancel_avg_estimate_eta_7d | 7日平均取消eta，单位秒 |
> | pas_ans_cnt_14d | 14日应答订单数 |
> | pas_cancel_cnt_14d | 14日取消订单数 |
> | pas_p_cancel_cnt_14d | 14日乘客取消订单数 |
> | pas_d_cancel_cnt_14d | 14日司机取消订单数 |
> | pas_finish_cnt_14d | 14日完单数 |
> | pas_ans_cp_cnt_14d | 14日单均应答商家数 |
> | pas_cancel_cp_cnt_14d | 14日单均取消商家数 |
> | pas_p_cancel_cp_cnt_14d | 14日单均乘客取消商家数 |
> | pas_d_cancel_cp_cnt_14d | 14日单均司机取消商家数 |
> | pas_ans_rate_14d | 14日应答率 |
> | pas_cancel_rate_14d | 14日取消率 |
> | pas_p_cancel_rate_14d | 14日乘客取消率 |
> | pas_d_cancel_rate_14d | 14日司机取消率 |
> | pas_finish_rate_14d | 14日完单率 |
> | pas_finish_max_distance_14d | 14日最大完单订单距离，单位米 |
> | pas_finish_min_distance_14d | 14日最小完单订单距离，单位米 |
> | pas_finish_avg_distance_14d | 14日平均完单订单距离，单位米 |
> | pas_answer_max_distance_14d | 14日最大应答订单距离，单位米 |
> | pas_answer_min_distance_14d | 14日最小应答订单距离，单位米 |
> | pas_answer_avg_distance_14d | 14日平均应答订单距离，单位米 |
> | pas_cancel_max_distance_14d | 14日最大取消订单距离，单位米 |
> | pas_cancel_min_distance_14d | 14日最小取消订单距离，单位米 |
> | pas_cancel_avg_distance_14d | 14日平均取消订单距离，单位米 |
> | pas_finish_max_est_fee_14d | 14日最大完单实付，单位分 |
> | pas_finish_min_est_fee_14d | 14日最小完单实付，单位分 |
> | pas_finish_avg_est_fee_14d | 14日平均完单实付，单位分 |
> | pas_answer_max_est_fee_14d | 14日最大应答实付，单位分 |
> | pas_answer_min_est_fee_14d | 14日最小应答实付，单位分 |
> | pas_answer_avg_est_fee_14d | 14日平均应答实付，单位分 |
> | pas_cancel_max_est_fee_14d | 14日最大取消实付，单位分 |
> | pas_cancel_min_est_fee_14d | 14日最小取消实付，单位分 |
> | pas_cancel_avg_est_fee_14d | 14日平均取消实付，单位分 |
> | pas_finish_max_cpm_14d | 14日最大完单cpm，单位分/米 |
> | pas_finish_min_cpm_14d | 14日最小完单cpm，单位分/米 |
> | pas_finish_avg_cpm_14d | 14日平均完单cpm，单位分/米 |
> | pas_answer_max_cpm_14d | 14日最大应答cpm，单位分/米 |
> | pas_answer_min_cpm_14d | 14日最小应答cpm，单位分/米 |
> | pas_answer_avg_cpm_14d | 14日平均应答cpm，单位分/米 |
> | pas_cancel_max_cpm_14d | 14日最大取消cpm，单位分/米 |
> | pas_cancel_min_cpm_14d | 14日最小取消cpm，单位分/米 |
> | pas_cancel_avg_cpm_14d | 14日平均取消cpm，单位分/米 |
> | pas_finish_max_fee_diff_14d | 14日最大完单应付-实付，单位分 |
> | pas_finish_min_fee_diff_14d | 14日最小完单应付-实付，单位分 |
> | pas_finish_avg_fee_diff_14d | 14日平均完单应付-实付，单位分 |
> | pas_answer_max_fee_diff_14d | 14日最大应答应付-实付，单位分 |
> | pas_answer_min_fee_diff_14d | 14日最小应答应付-实付，单位分 |
> | pas_answer_avg_fee_diff_14d | 14日平均应答应付-实付，单位分 |
> | pas_cancel_max_fee_diff_14d | 14日最大取消应付-实付，单位分 |
> | pas_cancel_min_fee_diff_14d | 14日最小取消应付-实付，单位分 |
> | pas_cancel_avg_fee_diff_14d | 14日平均取消应付-实付，单位分 |
> | pas_finish_max_estimate_eta_14d | 14日最大完单eta，单位秒 |
> | pas_finish_min_estimate_eta_14d | 14日最小完单eta，单位秒 |
> | pas_finish_avg_estimate_eta_14d | 14日平均完单eta，单位秒 |
> | pas_answer_max_estimate_eta_14d | 14日最大应答eta，单位秒 |
> | pas_answer_min_estimate_eta_14d | 14日最小应答eta，单位秒 |
> | pas_answer_avg_estimate_eta_14d | 14日平均应答eta，单位秒 |
> | pas_cancel_max_estimate_eta_14d | 14日最大取消eta，单位秒 |
> | pas_cancel_min_estimate_eta_14d | 14日最小取消eta，单位秒 |
> | pas_cancel_avg_estimate_eta_14d | 14日平均取消eta，单位秒 |



> [!abstract]- 子页面（3）
> - [acc_CR模型特征review-2025.10](acc_CR%E6%A8%A1%E5%9E%8B%E7%89%B9%E5%BE%81review-2025.10.md)
> - [acc_cr模型传入特征离在线一致性验证](acc_cr模型传入特征离在线一致性验证.md)
> - [acc_cr模型特征分析-25.12](acc_cr%E6%A8%A1%E5%9E%8B%E7%89%B9%E5%BE%81%E5%88%86%E6%9E%90-25.12.md)
