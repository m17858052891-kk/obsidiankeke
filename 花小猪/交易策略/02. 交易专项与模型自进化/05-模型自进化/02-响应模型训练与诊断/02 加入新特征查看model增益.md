---
title: "02 加入新特征查看model增益"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2204491121237
cssclasses: ["strategy-body-note"]
---

# 02 加入新特征查看model增益

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2204491121237)

按新增特征需求、周期任务和数据提取查实现，再结合对应实验结果判断增益。代码保留，默认折叠。

**阅读定位**　[[#2.1 特征需求|2.1 特征需求]] · [[#2.2 周期任务设置|2.2 周期任务设置]] · [[#2.3 数据提取|2.3 数据提取]]

## 2.1 特征需求

**第一种需求字段：使用全量用户建模top50特征**

[https://cooper.didichuxing.com/knowledge/2199610335356/2204316054918](https://cooper.didichuxing.com/knowledge/2199610335356/2204316054918)

**第二种需求字段：花小猪支付特征表**

[https://datamap.didichuxing.com/detail?uri=hive://mycluster-tj:kflower_strategy:hxz_pid_feature_package_click&keyword=hxz_pid_feature_package_click](https://datamap.didichuxing.com/detail?uri=hive://mycluster-tj:kflower_strategy:hxz_pid_feature_package_click&keyword=hxz_pid_feature_package_click)[,package,feature,pid,hxz,click](https://datamap.didichuxing.com/detail?uri=hive://mycluster-tj:kflower_strategy:hxz_pid_feature_package_click&keyword=hxz_pid_feature_package_click,package,feature,pid,hxz,click)

## 2.2 周期任务设置

**（1）需求 1 融合50维PC特征**

从6个表拉取字段融合50维的新特征信息

> [!example]- SQL 实现细节（419 行）
> ```SQL
> --SPARK_SQL
> --********************************************************************--
> --author:jakeyzheng_i
> --create time:2025-05-22 17:14:34
> --desc:为训练联合决策中的dsar模型构造数据，融入了50维的全量用户特征
> --remind:请在资源引用中添加需要引用的资源
> --********************************************************************--
> create table if not exists platform_union_dsar_training_with_full_user_modeling
> (
>     `city_id` BIGINT COMMENT '城市ID'
>     ,`passenger_id` BIGINT COMMENT '乘客ID'
>     ,`trace_id` STRING COMMENT 'nginx生成的唯一ID，串联整个请求'
>     ,`start_dest_dis` DOUBLE
>     ,`h` INT
>     ,`product_cnt` BIGINT NOT NULL
>     ,`kflower_one_price_estimate_fee_amt` BIGINT
>     ,`min_estimate_fee_amt` BIGINT
>     ,`max_estimate_fee_amt` BIGINT
>     ,`avg_estimate_fee_amt` DOUBLE
>     ,`quarter_estimate_fee_amt` BIGINT
>     ,`median_estimate_fee_amt` BIGINT
>     ,`three_quarter_estimate_fee_amt` BIGINT
>     ,`stddev_estimate_fee_amt` DOUBLE
>     ,`pap_rank` INT
>     ,`pap_price` BIGINT
>     ,`pap_estimate_id` STRING
>     ,`pap_stddev` DOUBLE
>     ,`gap_with_ahead_cp` BIGINT
>     ,`gap_with_after_cp` BIGINT
>     ,`is_dsa` INT
>     ,`is_fangou` INT
>     ,`is_jump` INT
>     ,`hit_rct` INT
>     ,`basic_plist` array<int>
>     ,`show_fee_plist` array<int>
>     ,`price_stddev_list` array<DOUBLE> COMMENT "实付价格的累计方差list"
>     ,`min_basic_total_fee_amt` INT COMMENT "最低应付价"
>     ,`max_basic_total_fee_amt` INT COMMENT "最高应付价"
>     ,`avg_basic_total_fee_amt` DOUBLE COMMENT "平均应付价"
>     ,`quarter_basic_total_fee_amt` DOUBLE COMMENT "1/4应付价分位点"
>     ,`median_basic_total_fee_amt` DOUBLE COMMENT "应付价中位数"
>     ,`three_quarter_basic_total_fee_amt` DOUBLE COMMENT "应付价3/4分位点"
>     ,`min_fee_subsidy_amt` INT COMMENT "最低价品牌的优惠金额"
>     ,`max_subsidy_rate` DOUBLE COMMENT "所有品类的最大的折扣"
>     ,`min_fee_subsidy_rate` DOUBLE COMMENT "最低价品牌的优惠率"
>     ,`order_cnt_1month` BIGINT NOT NULL
>     ,`finish_order_cnt_1month` BIGINT NOT NULL
>     ,`pid_cr_1month` DOUBLE
>     ,`max_fee_scale_1month` DECIMAL(38, 6)
>     ,`min_fee_scale_1month` DECIMAL(38, 6)
>     ,`avg_fee_scale_1month` DECIMAL(38, 10)
>     ,`max_call_cp_cnt_1month` BIGINT
>     ,`min_call_cp_cnt_1month` BIGINT
>     ,`avg_call_cp_cnt_1month` DOUBLE
>     ,`max_call_cp_cnt_ratio_1month` DOUBLE
>     ,`min_call_cp_cnt_ratio_1month` DOUBLE
>     ,`avg_call_cp_cnt_ratio_1month` DOUBLE
>     ,`jiagou_order_cnt_1month` BIGINT NOT NULL
>     ,`jiagou_order_ratio_1month` DOUBLE
>     ,`fangou_order_cnt_1month` BIGINT NOT NULL
>     ,`fangou_order_ratio_1month` DOUBLE
>     ,`call_min_fee_cnt_1month` BIGINT NOT NULL
>     ,`call_min_fee_ratio_1month` DOUBLE
>     ,`is_upto_tj_ratio_1month` DOUBLE
>     ,`is_upto_tk_ratio_1month` DOUBLE
>     ,`is_upto_ykjia_ratio_1month` DOUBLE
>     ,`is_upto_tjhezi_ratio_1month` DOUBLE
>     ,`is_upto_tkhezi_ratio_1month` DOUBLE
>     ,`avg_gap_ahead_1month` DOUBLE
>     ,`avg_gap_after_1month` DOUBLE
>     ,`avg_gap_ahead_ratio_1month` DOUBLE
>     ,`avg_gap_after_ratio_1month` DOUBLE
>     ,`order_cnt_2month` BIGINT
>     ,`finish_order_cnt_2month`BIGINT
>     ,`pid_cr_2month`DOUBLE
>     ,`max_fee_scale_2month`DECIMAL(38, 6)
>     ,`min_fee_scale_2month`DECIMAL(38, 6)
>     ,`avg_fee_scale_2month`DECIMAL(38, 10)
>     ,`max_call_cp_cnt_2month`BIGINT
>     ,`min_call_cp_cnt_2month`BIGINT
>     ,`avg_call_cp_cnt_2month`DOUBLE
>     ,`max_call_cp_cnt_ratio_2month`DOUBLE
>     ,`min_call_cp_cnt_ratio_2month`DOUBLE
>     ,`avg_call_cp_cnt_ratio_2month`DOUBLE
>     ,`jiagou_order_cnt_2month`BIGINT NOT NULL
>     ,`jiagou_order_ratio_2month`DOUBLE
>     ,`fangou_order_cnt_2month`BIGINT NOT NULL
>     ,`fangou_order_ratio_2month`DOUBLE
>     ,`call_min_fee_cnt_2month`BIGINT NOT NULL
>     ,`call_min_fee_ratio_2month`DOUBLE
>     ,`is_upto_tj_ratio_2month`DOUBLE
>     ,`is_upto_tk_ratio_2month`DOUBLE
>     ,`is_upto_ykjia_ratio_2month`DOUBLE
>     ,`is_upto_tjhezi_ratio_2month`DOUBLE
>     ,`is_upto_tkhezi_ratio_2month`DOUBLE
>     ,`avg_gap_ahead_2month`DOUBLE
>     ,`avg_gap_after_2month`DOUBLE
>     ,`avg_gap_ahead_ratio_2month`DOUBLE
>     ,`avg_gap_after_ratio_2month`DOUBLE
>     -- 加上来自kflower_strategy.dm_user_pricing_prefer_stat表的字段：（3个）
>     ,`pas_ecr_1month` DOUBLE
>     ,`pas_called_one_price_basic_ratio_avg_1month` DOUBLE
>     ,`pas_called_one_price_basic_ratio_max_1month` DOUBLE
>     -- 加上来自kflower_strategy.dm_user_compete_tag_stat表的字段：（4个）
>     ,`other_sm_cnt_weekday_28d` DOUBLE
>     ,`sm_cnt_weekday_14d` DOUBLE
>     ,`sm_cnt_weekend_28d` DOUBLE
>     ,`sm_cnt_weekday_28d` DOUBLE
>     -- 加上来自kflower_strategy.dm_user_common_behavior_stat表的字段：（13个）
>     ,`dm_user_vzt_pub_rfmpeat_kflw_a` DOUBLE
>     ,`dm_user_vzt_pub_rfmpeat_ut_f` DOUBLE
>     ,`dm_user_vzt_pub_rfmpeat_other_p` DOUBLE
>     ,`dm_user_mkt_netcar_ordacc_gcsv2_cost_mean` DOUBLE
>     ,`dm_user_vzt_pub_rfmpeat_other_synth` DOUBLE
>     ,`dm_user_base_oneid_info_age` BIGINT
>     ,`dm_user_vzt_pub_rfmpeat_btls_a` DOUBLE
>     ,`dm_user_mkt_netcar_ordacc_jie_subsidy_c_order_ratio` DOUBLE
>     ,`dm_user_vzt_pub_rfmpeat_ut_a` DOUBLE
>     ,`dm_user_behv_netcar_htpp_vzt_city_num` INT
>     ,`dm_user_vzt_pub_rfmpeat_ut_r` DOUBLE
>     ,`type_convert_dm_user_base_oneid_info_last_use_kflw` DOUBLE  -- 要转为STRING dm_user_base_oneid_info_last_use_kflw
>     ,`dm_user_mkt_biz_abst_kflw_cancel_types_divg` DOUBLE
>     -- 加上来自kflower_strategy.dm_user_behavior_multi_app_stat表的字段：（17个）
>     ,`hxz_finish_asp_28d` DOUBLE
>     ,`is_kf_student_verify` BIGINT
>     ,`hxz_finish_cnt_weekday_28d` BIGINT
>     ,`dd_kf_sm_bubble_cnt_14d` BIGINT
>     ,`pbd_bubble_cnt_weekday_28d` BIGINT
>     ,`wyc_bubble_cnt_1d` BIGINT
>     ,`pbd_bubble_cnt_7d` BIGINT
>     ,`call_ratio_7d` DOUBLE
>     ,`dd_pbd_sm_bubble_cnt_7d` BIGINT
>     ,`hxz_finish_cnt_7d` BIGINT
>     ,`dd_gd_sm_cnt_30d` BIGINT
>     ,`kf_gd_sm_cnt_30d` BIGINT
>     ,`hxz_finish_cnt_28d` BIGINT
>     ,`call_ratio_28d` DOUBLE
>     ,`kf_gd_sm_cnt_7d` BIGINT
>     ,`wyc_bubble_cnt_14d` BIGINT
>     ,`pbd_gd_sm_cnt_30d` BIGINT
>     -- 加上来自kflower_strategy.competition_pid_tag表的字段：（6个）
>     ,`is_5d_sm` BIGINT
>     ,`is_1d_sm` BIGINT
>     ,`is_3d_sm` BIGINT
>     ,`is_14d_sm` BIGINT
>     ,`is_28d_sm` BIGINT
>     ,`is_10d_sm` BIGINT
>     -- 加上来自kflower_strategy.merge_all_acit_features表的动态字段：（7个）
>     ,`didi_order_created_total_cnt_s60` DOUBLE
>     ,`didi_bubble_total_cnt_s120` DOUBLE
>     ,`didi_order_created_cnt_s30` DOUBLE
>     ,`didi_bubble_total_avg_estimate_time_minutes_s60` DOUBLE
>     ,`didi_bubble_total_avg_estimate_distance_metre_s120` DOUBLE
>     ,`tencent_service_order_created_total_cnt_s60` DOUBLE
>     ,`tencent_service_order_created_cnt_s30` DOUBLE
> )
> partitioned by 
> (
>     dt string
> )
> tblproperties 
> (
>     'TTL' = '180'
> );
>
> with
> base_trace as ( --获取现有的base表的全部信息，先前的DSAR模型的数据获取形式
>     -- select   *
>     select  city_id, 
>             passenger_id, 
>             trace_id, 
>             start_dest_dis, 
>             h, 
>             product_cnt,
>             kflower_one_price_estimate_fee_amt, 
>             min_estimate_fee_amt, 
>             max_estimate_fee_amt,
>             avg_estimate_fee_amt, 
>             quarter_estimate_fee_amt, 
>             median_estimate_fee_amt,
>             three_quarter_estimate_fee_amt, 
>             stddev_estimate_fee_amt, 
>             pap_rank, 
>             pap_price,
>             pap_estimate_id, 
>             pap_stddev, 
>             gap_with_ahead_cp, 
>             gap_with_after_cp, 
>             is_dsa, 
>             is_fangou,
>             is_jump, 
>             hit_rct, 
>             basic_plist, 
>             show_fee_plist, 
>             price_stddev_list,
>             min_basic_total_fee_amt, 
>             max_basic_total_fee_amt, 
>             avg_basic_total_fee_amt,
>             quarter_basic_total_fee_amt, 
>             median_basic_total_fee_amt,
>             three_quarter_basic_total_fee_amt, 
>             min_fee_subsidy_amt, 
>             max_subsidy_rate,
>             min_fee_subsidy_rate, 
>             order_cnt_1month, 
>             finish_order_cnt_1month, 
>             pid_cr_1month,
>             max_fee_scale_1month, 
>             min_fee_scale_1month, 
>             avg_fee_scale_1month,
>             max_call_cp_cnt_1month, 
>             min_call_cp_cnt_1month, 
>             avg_call_cp_cnt_1month,
>             max_call_cp_cnt_ratio_1month, 
>             min_call_cp_cnt_ratio_1month,
>             avg_call_cp_cnt_ratio_1month, 
>             jiagou_order_cnt_1month, 
>             jiagou_order_ratio_1month,
>             fangou_order_cnt_1month, 
>             fangou_order_ratio_1month, 
>             call_min_fee_cnt_1month,
>             call_min_fee_ratio_1month, 
>             is_upto_tj_ratio_1month, 
>             is_upto_tk_ratio_1month,
>             is_upto_ykjia_ratio_1month, 
>             is_upto_tjhezi_ratio_1month, 
>             is_upto_tkhezi_ratio_1month,
>             avg_gap_ahead_1month, 
>             avg_gap_after_1month, 
>             avg_gap_ahead_ratio_1month,
>             avg_gap_after_ratio_1month, 
>             order_cnt_2month, 
>             finish_order_cnt_2month, 
>             pid_cr_2month,
>             max_fee_scale_2month, 
>             min_fee_scale_2month, 
>             avg_fee_scale_2month,
>             max_call_cp_cnt_2month, 
>             min_call_cp_cnt_2month, 
>             avg_call_cp_cnt_2month,
>             max_call_cp_cnt_ratio_2month, 
>             min_call_cp_cnt_ratio_2month,
>             avg_call_cp_cnt_ratio_2month, 
>             jiagou_order_cnt_2month, 
>             jiagou_order_ratio_2month,
>             fangou_order_cnt_2month, 
>             fangou_order_ratio_2month, 
>             call_min_fee_cnt_2month,
>             call_min_fee_ratio_2month, 
>             is_upto_tj_ratio_2month, 
>             is_upto_tk_ratio_2month,
>             is_upto_ykjia_ratio_2month, 
>             is_upto_tjhezi_ratio_2month, 
>             is_upto_tkhezi_ratio_2month,
>             avg_gap_ahead_2month, 
>             avg_gap_after_2month, 
>             avg_gap_ahead_ratio_2month,
>             avg_gap_after_ratio_2month
>     from    kflower_strategy.platform_union_strategy_dsar_traning_data_daily
>     where   dt = '${BIZ_DATE_LINE}'
> ),
>
> user_pricing_prefer_stat as (
>     select  passenger_id,
>             pas_ecr_1month,
>             pas_called_one_price_basic_ratio_avg_1month,
>             pas_called_one_price_basic_ratio_max_1month
>     from    kflower_strategy.dm_user_pricing_prefer_stat
>     where   dt = '${BIZ_DATE_LINE}'
> ),
>
> user_compete_tag_stat as (
>     select  passenger_id,
>             other_sm_cnt_weekday_28d,
>             sm_cnt_weekday_14d,
>             sm_cnt_weekend_28d,
>             sm_cnt_weekday_28d
>     from    kflower_strategy.dm_user_compete_tag_stat
>     where   dt = '${BIZ_DATE_LINE}'
> ),
>
> user_common_behavior_stat as (
>     select  passenger_id,
>             dm_user_vzt_pub_rfmpeat_kflw_a,
>             dm_user_vzt_pub_rfmpeat_ut_f,
>             dm_user_vzt_pub_rfmpeat_other_p,
>             dm_user_mkt_netcar_ordacc_gcsv2_cost_mean,
>             dm_user_vzt_pub_rfmpeat_other_synth,
>             dm_user_base_oneid_info_age,
>             dm_user_vzt_pub_rfmpeat_btls_a,
>             dm_user_mkt_netcar_ordacc_jie_subsidy_c_order_ratio,
>             dm_user_vzt_pub_rfmpeat_ut_a,
>             dm_user_behv_netcar_htpp_vzt_city_num,
>             dm_user_vzt_pub_rfmpeat_ut_r,
>             cast(dm_user_base_oneid_info_last_use_kflw AS DOUBLE) AS type_convert_dm_user_base_oneid_info_last_use_kflw,
>             dm_user_mkt_biz_abst_kflw_cancel_types_divg
>     from    kflower_strategy.dm_user_common_behavior_stat
>     where   dt = '${BIZ_DATE_LINE}'
> ),
>
> dm_user_behavior_multi_app_stat as (
>     select  passenger_id,
>             hxz_finish_asp_28d,
>             is_kf_student_verify,
>             hxz_finish_cnt_weekday_28d,
>             dd_kf_sm_bubble_cnt_14d,
>             pbd_bubble_cnt_weekday_28d,
>             wyc_bubble_cnt_1d,
>             pbd_bubble_cnt_7d,
>             call_ratio_7d,
>             dd_pbd_sm_bubble_cnt_7d,
>             hxz_finish_cnt_7d,
>             dd_gd_sm_cnt_30d,
>             kf_gd_sm_cnt_30d,
>             hxz_finish_cnt_28d,
>             call_ratio_28d,
>             kf_gd_sm_cnt_7d,
>             wyc_bubble_cnt_14d,
>             pbd_gd_sm_cnt_30d
>     from    kflower_strategy.dm_user_behavior_multi_app_stat
>     where   dt = '${BIZ_DATE_LINE}'
> ),
>
> competition_pid_tag as (
>     select  passenger_id,
>             is_5d_sm,
>             is_1d_sm,
>             is_3d_sm,
>             is_14d_sm,
>             is_28d_sm,
>             is_10d_sm
>     from    kflower_strategy.competition_pid_tag
>     where   dt = '${BIZ_DATE_LINE}'
> ),
>
> acit_features as (
>     select  passenger_id,
>             didi_order_created_total_cnt_s60,
>             didi_bubble_total_cnt_s120,
>             didi_order_created_cnt_s30,
>             didi_bubble_total_avg_estimate_time_minutes_s60,
>             didi_bubble_total_avg_estimate_distance_metre_s120,
>             tencent_service_order_created_total_cnt_s60,
>             tencent_service_order_created_cnt_s30
>     from    kflower_strategy.merge_all_acit_features
>     where   dt = '${BIZ_DATE_LINE}'
> ),
>
> merge_all_infor as (
>     select  a.*,
>             b.pas_ecr_1month,
>             b.pas_called_one_price_basic_ratio_avg_1month,
>             b.pas_called_one_price_basic_ratio_max_1month,
>             c.other_sm_cnt_weekday_28d,
>             c.sm_cnt_weekday_14d,
>             c.sm_cnt_weekend_28d,
>             c.sm_cnt_weekday_28d,
>             d.dm_user_vzt_pub_rfmpeat_kflw_a,
>             d.dm_user_vzt_pub_rfmpeat_ut_f,
>             d.dm_user_vzt_pub_rfmpeat_other_p,
>             d.dm_user_mkt_netcar_ordacc_gcsv2_cost_mean,
>             d.dm_user_vzt_pub_rfmpeat_other_synth,
>             d.dm_user_base_oneid_info_age,
>             d.dm_user_vzt_pub_rfmpeat_btls_a,
>             d.dm_user_mkt_netcar_ordacc_jie_subsidy_c_order_ratio,
>             d.dm_user_vzt_pub_rfmpeat_ut_a,
>             d.dm_user_behv_netcar_htpp_vzt_city_num,
>             d.dm_user_vzt_pub_rfmpeat_ut_r,
>             d.type_convert_dm_user_base_oneid_info_last_use_kflw,
>             d.dm_user_mkt_biz_abst_kflw_cancel_types_divg,
>             e.hxz_finish_asp_28d,
>             e.is_kf_student_verify,
>             e.hxz_finish_cnt_weekday_28d,
>             e.dd_kf_sm_bubble_cnt_14d,
>             e.pbd_bubble_cnt_weekday_28d,
>             e.wyc_bubble_cnt_1d,
>             e.pbd_bubble_cnt_7d,
>             e.call_ratio_7d,
>             e.dd_pbd_sm_bubble_cnt_7d,
>             e.hxz_finish_cnt_7d,
>             e.dd_gd_sm_cnt_30d,
>             e.kf_gd_sm_cnt_30d,
>             e.hxz_finish_cnt_28d,
>             e.call_ratio_28d,
>             e.kf_gd_sm_cnt_7d,
>             e.wyc_bubble_cnt_14d,
>             e.pbd_gd_sm_cnt_30d,
>             f.is_5d_sm,
>             f.is_1d_sm,
>             f.is_3d_sm,
>             f.is_14d_sm,
>             f.is_28d_sm,
>             f.is_10d_sm,
>             g.didi_order_created_total_cnt_s60,
>             g.didi_bubble_total_cnt_s120,
>             g.didi_order_created_cnt_s30,
>             g.didi_bubble_total_avg_estimate_time_minutes_s60,
>             g.didi_bubble_total_avg_estimate_distance_metre_s120,
>             g.tencent_service_order_created_total_cnt_s60,
>             g.tencent_service_order_created_cnt_s30
>     from    base_trace a
>     left join   user_pricing_prefer_stat b
>     on a.passenger_id = b.passenger_id
>     left join   user_compete_tag_stat c
>     on a.passenger_id = c.passenger_id
>     left join   user_common_behavior_stat d
>     on a.passenger_id = d.passenger_id
>     left join   dm_user_behavior_multi_app_stat e
>     on a.passenger_id = e.passenger_id
>     left join   competition_pid_tag f
>     on a.passenger_id = f.passenger_id
>     left join   acit_features g
>     on a.passenger_id = g.passenger_id
> )
>
> -- 写入新表
> insert overwrite table platform_union_dsar_training_with_full_user_modeling partition (dt = '${BIZ_DATE_LINE}')
> select *
> from merge_all_infor;
> ```


**（2）需求 2 融合hxz_pid_feature_package_click表**

将原先的kflower_strategy.platform_union_strategy_dsar_traning_data_daily表和kflower_strategy.hxz_pid_feature_package_click表中的**7d 14d 28d**的特征分别做拼接，得到新的特征表，具体提取了2个表。

**表1: platform_dsar_traning_with_hxz_pid_feature_28d_daily**

> [!example]- SQL 实现细节（184 行）
> ```SQL
> --SPARK_SQL
> --********************************************************************--
> --author:jakeyzheng_i
> --create time:2025-05-21 10:54:26
> --desc:为训练联合决策中的dsar模型构造数据，融入了kflower_strategy.hxz_pid_feature_package_click表的28d字段
> --remind:请在资源引用中添加需要引用的资源
> --********************************************************************--
> create table if not exists platform_dsar_traning_with_hxz_pid_feature_28d_daily
> (
>     `city_id` BIGINT COMMENT '城市ID，这里用于串联查询'
>     ,`passenger_id` BIGINT COMMENT '乘客ID'
>     ,`trace_id` STRING COMMENT 'nginx生成的唯一ID'
>     ,`start_dest_dis` DOUBLE
>     ,`h` INT
>     ,`product_cnt` BIGINT NOT NULL
>     ,`kflower_one_price_estimate_fee_amt` BIGINT
>     ,`min_estimate_fee_amt` BIGINT
>     ,`max_estimate_fee_amt` BIGINT
>     ,`avg_estimate_fee_amt` DOUBLE
>     ,`quarter_estimate_fee_amt` BIGINT
>     ,`median_estimate_fee_amt` BIGINT
>     ,`three_quarter_estimate_fee_amt` BIGINT
>     ,`stddev_estimate_fee_amt` DOUBLE
>     ,`pap_rank` INT
>     ,`pap_price` BIGINT
>     ,`pap_estimate_id` STRING
>     ,`pap_stddev` DOUBLE
>     ,`gap_with_ahead_cp` BIGINT
>     ,`gap_with_after_cp` BIGINT
>     ,`is_dsa` INT
>     ,`is_fangou` INT
>     ,`is_jump` INT
>     ,`hit_rct` INT
>     ,`basic_plist` array<int>
>     ,`show_fee_plist` array<int>
>     ,`price_stddev_list` array<DOUBLE> COMMENT "实付价格的累计方差list"
>     ,`min_basic_total_fee_amt` INT COMMENT "最低应付价"
>     ,`max_basic_total_fee_amt` INT COMMENT "最高应付价"
>     ,`avg_basic_total_fee_amt` DOUBLE COMMENT "平均应付价"
>     ,`quarter_basic_total_fee_amt` DOUBLE COMMENT "1/4应付价分位点"
>     ,`median_basic_total_fee_amt` DOUBLE COMMENT "应付价中位数"
>     ,`three_quarter_basic_total_fee_amt` DOUBLE COMMENT "应付价3/4分位点"
>     ,`min_fee_subsidy_amt` INT COMMENT "最低价品牌的优惠金额"
>     ,`max_subsidy_rate` DOUBLE COMMENT "所有品类的最大的折扣"
>     ,`min_fee_subsidy_rate` DOUBLE COMMENT "最低价品牌的优惠率"
>     ,`order_cnt_1month` BIGINT NOT NULL
>     ,`finish_order_cnt_1month` BIGINT NOT NULL
>     ,`pid_cr_1month` DOUBLE
>     ,`max_fee_scale_1month` DECIMAL(38, 6)
>     ,`min_fee_scale_1month` DECIMAL(38, 6)
>     ,`avg_fee_scale_1month` DECIMAL(38, 10)
>     ,`max_call_cp_cnt_1month` BIGINT
>     ,`min_call_cp_cnt_1month` BIGINT
>     ,`avg_call_cp_cnt_1month` DOUBLE
>     ,`max_call_cp_cnt_ratio_1month` DOUBLE
>     ,`min_call_cp_cnt_ratio_1month` DOUBLE
>     ,`avg_call_cp_cnt_ratio_1month` DOUBLE
>     ,`jiagou_order_cnt_1month` BIGINT NOT NULL
>     ,`jiagou_order_ratio_1month` DOUBLE
>     ,`fangou_order_cnt_1month` BIGINT NOT NULL
>     ,`fangou_order_ratio_1month` DOUBLE
>     ,`call_min_fee_cnt_1month` BIGINT NOT NULL
>     ,`call_min_fee_ratio_1month` DOUBLE
>     ,`is_upto_tj_ratio_1month` DOUBLE
>     ,`is_upto_tk_ratio_1month` DOUBLE
>     ,`is_upto_ykjia_ratio_1month` DOUBLE
>     ,`is_upto_tjhezi_ratio_1month` DOUBLE
>     ,`is_upto_tkhezi_ratio_1month` DOUBLE
>     ,`avg_gap_ahead_1month` DOUBLE
>     ,`avg_gap_after_1month` DOUBLE
>     ,`avg_gap_ahead_ratio_1month` DOUBLE
>     ,`avg_gap_after_ratio_1month` DOUBLE
>     ,`order_cnt_2month` BIGINT
>     ,`finish_order_cnt_2month`BIGINT
>     ,`pid_cr_2month`DOUBLE
>     ,`max_fee_scale_2month`DECIMAL(38, 6)
>     ,`min_fee_scale_2month`DECIMAL(38, 6)
>     ,`avg_fee_scale_2month`DECIMAL(38, 10)
>     ,`max_call_cp_cnt_2month`BIGINT
>     ,`min_call_cp_cnt_2month`BIGINT
>     ,`avg_call_cp_cnt_2month`DOUBLE
>     ,`max_call_cp_cnt_ratio_2month`DOUBLE
>     ,`min_call_cp_cnt_ratio_2month`DOUBLE
>     ,`avg_call_cp_cnt_ratio_2month`DOUBLE
>     ,`jiagou_order_cnt_2month`BIGINT NOT NULL
>     ,`jiagou_order_ratio_2month`DOUBLE
>     ,`fangou_order_cnt_2month`BIGINT NOT NULL
>     ,`fangou_order_ratio_2month`DOUBLE
>     ,`call_min_fee_cnt_2month`BIGINT NOT NULL
>     ,`call_min_fee_ratio_2month`DOUBLE
>     ,`is_upto_tj_ratio_2month`DOUBLE
>     ,`is_upto_tk_ratio_2month`DOUBLE
>     ,`is_upto_ykjia_ratio_2month`DOUBLE
>     ,`is_upto_tjhezi_ratio_2month`DOUBLE
>     ,`is_upto_tkhezi_ratio_2month`DOUBLE
>     ,`avg_gap_ahead_2month`DOUBLE
>     ,`avg_gap_after_2month`DOUBLE
>     ,`avg_gap_ahead_ratio_2month`DOUBLE
>     ,`avg_gap_after_ratio_2month`DOUBLE
>     -- 加上来自kflower_strategy.hxz_pid_feature_package_click表的字段：（28d的XX个）
>     ,`first_sw_28d` FLOAT
>     ,`package_sw_28d` FLOAT
>     ,`package_ck_28d` FLOAT
>     ,`detail_sw_28d` FLOAT
>     ,`detail_ck_28d` FLOAT
>     ,`package_ck_rate_28d` FLOAT
>     ,`detail_ck_rate_28d` FLOAT
> )
> partitioned by 
> (
>     dt string
> )
> tblproperties 
> (
>     'TTL' = '180'
> );
>
> with
> base_trace as ( --获取现有的base表的全部信息，先前的DSAR模型的数据获取形式
>     -- select   *
>     select    city_id, passenger_id, trace_id, start_dest_dis, h, product_cnt,
>         kflower_one_price_estimate_fee_amt, min_estimate_fee_amt, max_estimate_fee_amt,
>         avg_estimate_fee_amt, quarter_estimate_fee_amt, median_estimate_fee_amt,
>         three_quarter_estimate_fee_amt, stddev_estimate_fee_amt, pap_rank, pap_price,
>         pap_estimate_id, pap_stddev, gap_with_ahead_cp, gap_with_after_cp, is_dsa, is_fangou,
>         is_jump, hit_rct, basic_plist, show_fee_plist, price_stddev_list,
>         min_basic_total_fee_amt, max_basic_total_fee_amt, avg_basic_total_fee_amt,
>         quarter_basic_total_fee_amt, median_basic_total_fee_amt,
>         three_quarter_basic_total_fee_amt, min_fee_subsidy_amt, max_subsidy_rate,
>         min_fee_subsidy_rate, order_cnt_1month, finish_order_cnt_1month, pid_cr_1month,
>         max_fee_scale_1month, min_fee_scale_1month, avg_fee_scale_1month,
>         max_call_cp_cnt_1month, min_call_cp_cnt_1month, avg_call_cp_cnt_1month,
>         max_call_cp_cnt_ratio_1month, min_call_cp_cnt_ratio_1month,
>         avg_call_cp_cnt_ratio_1month, jiagou_order_cnt_1month, jiagou_order_ratio_1month,
>         fangou_order_cnt_1month, fangou_order_ratio_1month, call_min_fee_cnt_1month,
>         call_min_fee_ratio_1month, is_upto_tj_ratio_1month, is_upto_tk_ratio_1month,
>         is_upto_ykjia_ratio_1month, is_upto_tjhezi_ratio_1month, is_upto_tkhezi_ratio_1month,
>         avg_gap_ahead_1month, avg_gap_after_1month, avg_gap_ahead_ratio_1month,
>         avg_gap_after_ratio_1month, order_cnt_2month, finish_order_cnt_2month, pid_cr_2month,
>         max_fee_scale_2month, min_fee_scale_2month, avg_fee_scale_2month,
>         max_call_cp_cnt_2month, min_call_cp_cnt_2month, avg_call_cp_cnt_2month,
>         max_call_cp_cnt_ratio_2month, min_call_cp_cnt_ratio_2month,
>         avg_call_cp_cnt_ratio_2month, jiagou_order_cnt_2month, jiagou_order_ratio_2month,
>         fangou_order_cnt_2month, fangou_order_ratio_2month, call_min_fee_cnt_2month,
>         call_min_fee_ratio_2month, is_upto_tj_ratio_2month, is_upto_tk_ratio_2month,
>         is_upto_ykjia_ratio_2month, is_upto_tjhezi_ratio_2month, is_upto_tkhezi_ratio_2month,
>         avg_gap_ahead_2month, avg_gap_after_2month, avg_gap_ahead_ratio_2month,
>         avg_gap_after_ratio_2month
>     from     kflower_strategy.platform_union_strategy_dsar_traning_data_daily
>     where    dt = '${BIZ_DATE_LINE}'
> ),
>
> hxz_pid_feature as ( -- 获取联合查询的表的结果
>     select  city_id,
>             first_sw_28d,
>             package_sw_28d,
>             package_ck_28d,
>             detail_sw_28d,
>             detail_ck_28d,
>             package_ck_rate_28d,
>             detail_ck_rate_28d
>     from    kflower_strategy.hxz_pid_feature_package_click
>     where   dt = '${BIZ_DATE_LINE}'
> ),
>
> trace_with_pkg as (
>     select  a.*,
>             b.first_sw_28d,
>             b.package_sw_28d,
>             b.package_ck_28d,
>             b.detail_sw_28d,
>             b.detail_ck_28d,
>             b.package_ck_rate_28d,
>             b.detail_ck_rate_28d
>     from    base_trace a
>     left join hxz_pid_feature b
>     on      a.city_id = b.city_id
> )
>
> -- 写入新表
> insert overwrite table platform_dsar_traning_with_hxz_pid_feature_28d_daily partition (dt = '${BIZ_DATE_LINE}')
> select *
> from trace_with_pkg;
>
> ```


**表2: platform_dsar_traning_with_hxz_pid_feature_7d_to_28d_daily**

> [!example]- SQL 实现细节（288 行）
> ```SQL
> --SPARK_SQL
> --********************************************************************--
> --author:jakeyzheng_i
> --create time:2025-05-21 11:04:43
> --desc:训练联合决策中的dsar模型构造数据，结合kflower_strategy.hxz_pid_feature_package_click表的7-28d的字段
> --remind:请在资源引用中添加需要引用的资源
> --********************************************************************--
> create table if not exists platform_dsar_traning_with_hxz_pid_feature_7d_to_28d_daily
> (
>     `city_id` BIGINT COMMENT '城市ID，这里用于串联查询'
>     ,`passenger_id` BIGINT COMMENT '乘客ID'
>     ,`trace_id` STRING COMMENT 'nginx生成的唯一ID'
>     ,`start_dest_dis` DOUBLE
>     ,`h` INT
>     ,`product_cnt` BIGINT NOT NULL
>     ,`kflower_one_price_estimate_fee_amt` BIGINT
>     ,`min_estimate_fee_amt` BIGINT
>     ,`max_estimate_fee_amt` BIGINT
>     ,`avg_estimate_fee_amt` DOUBLE
>     ,`quarter_estimate_fee_amt` BIGINT
>     ,`median_estimate_fee_amt` BIGINT
>     ,`three_quarter_estimate_fee_amt` BIGINT
>     ,`stddev_estimate_fee_amt` DOUBLE
>     ,`pap_rank` INT
>     ,`pap_price` BIGINT
>     ,`pap_estimate_id` STRING
>     ,`pap_stddev` DOUBLE
>     ,`gap_with_ahead_cp` BIGINT
>     ,`gap_with_after_cp` BIGINT
>     ,`is_dsa` INT
>     ,`is_fangou` INT
>     ,`is_jump` INT
>     ,`hit_rct` INT
>     ,`basic_plist` array<int>
>     ,`show_fee_plist` array<int>
>     ,`price_stddev_list` array<DOUBLE> COMMENT "实付价格的累计方差list"
>     ,`min_basic_total_fee_amt` INT COMMENT "最低应付价"
>     ,`max_basic_total_fee_amt` INT COMMENT "最高应付价"
>     ,`avg_basic_total_fee_amt` DOUBLE COMMENT "平均应付价"
>     ,`quarter_basic_total_fee_amt` DOUBLE COMMENT "1/4应付价分位点"
>     ,`median_basic_total_fee_amt` DOUBLE COMMENT "应付价中位数"
>     ,`three_quarter_basic_total_fee_amt` DOUBLE COMMENT "应付价3/4分位点"
>     ,`min_fee_subsidy_amt` INT COMMENT "最低价品牌的优惠金额"
>     ,`max_subsidy_rate` DOUBLE COMMENT "所有品类的最大的折扣"
>     ,`min_fee_subsidy_rate` DOUBLE COMMENT "最低价品牌的优惠率"
>     ,`order_cnt_1month` BIGINT NOT NULL
>     ,`finish_order_cnt_1month` BIGINT NOT NULL
>     ,`pid_cr_1month` DOUBLE
>     ,`max_fee_scale_1month` DECIMAL(38, 6)
>     ,`min_fee_scale_1month` DECIMAL(38, 6)
>     ,`avg_fee_scale_1month` DECIMAL(38, 10)
>     ,`max_call_cp_cnt_1month` BIGINT
>     ,`min_call_cp_cnt_1month` BIGINT
>     ,`avg_call_cp_cnt_1month` DOUBLE
>     ,`max_call_cp_cnt_ratio_1month` DOUBLE
>     ,`min_call_cp_cnt_ratio_1month` DOUBLE
>     ,`avg_call_cp_cnt_ratio_1month` DOUBLE
>     ,`jiagou_order_cnt_1month` BIGINT NOT NULL
>     ,`jiagou_order_ratio_1month` DOUBLE
>     ,`fangou_order_cnt_1month` BIGINT NOT NULL
>     ,`fangou_order_ratio_1month` DOUBLE
>     ,`call_min_fee_cnt_1month` BIGINT NOT NULL
>     ,`call_min_fee_ratio_1month` DOUBLE
>     ,`is_upto_tj_ratio_1month` DOUBLE
>     ,`is_upto_tk_ratio_1month` DOUBLE
>     ,`is_upto_ykjia_ratio_1month` DOUBLE
>     ,`is_upto_tjhezi_ratio_1month` DOUBLE
>     ,`is_upto_tkhezi_ratio_1month` DOUBLE
>     ,`avg_gap_ahead_1month` DOUBLE
>     ,`avg_gap_after_1month` DOUBLE
>     ,`avg_gap_ahead_ratio_1month` DOUBLE
>     ,`avg_gap_after_ratio_1month` DOUBLE
>     ,`order_cnt_2month` BIGINT
>     ,`finish_order_cnt_2month`BIGINT
>     ,`pid_cr_2month`DOUBLE
>     ,`max_fee_scale_2month`DECIMAL(38, 6)
>     ,`min_fee_scale_2month`DECIMAL(38, 6)
>     ,`avg_fee_scale_2month`DECIMAL(38, 10)
>     ,`max_call_cp_cnt_2month`BIGINT
>     ,`min_call_cp_cnt_2month`BIGINT
>     ,`avg_call_cp_cnt_2month`DOUBLE
>     ,`max_call_cp_cnt_ratio_2month`DOUBLE
>     ,`min_call_cp_cnt_ratio_2month`DOUBLE
>     ,`avg_call_cp_cnt_ratio_2month`DOUBLE
>     ,`jiagou_order_cnt_2month`BIGINT NOT NULL
>     ,`jiagou_order_ratio_2month`DOUBLE
>     ,`fangou_order_cnt_2month`BIGINT NOT NULL
>     ,`fangou_order_ratio_2month`DOUBLE
>     ,`call_min_fee_cnt_2month`BIGINT NOT NULL
>     ,`call_min_fee_ratio_2month`DOUBLE
>     ,`is_upto_tj_ratio_2month`DOUBLE
>     ,`is_upto_tk_ratio_2month`DOUBLE
>     ,`is_upto_ykjia_ratio_2month`DOUBLE
>     ,`is_upto_tjhezi_ratio_2month`DOUBLE
>     ,`is_upto_tkhezi_ratio_2month`DOUBLE
>     ,`avg_gap_ahead_2month`DOUBLE
>     ,`avg_gap_after_2month`DOUBLE
>     ,`avg_gap_ahead_ratio_2month`DOUBLE
>     ,`avg_gap_after_ratio_2month`DOUBLE
>     -- 加上来自kflower_strategy.hxz_pid_feature_package_click表的字段：（7d-28d的）
>     ,`first_sw_28d` FLOAT
>     ,`package_sw_28d` FLOAT
>     ,`package_ck_28d` FLOAT
>     ,`detail_sw_28d` FLOAT
>     ,`detail_ck_28d` FLOAT
>     ,`package_ck_rate_28d` FLOAT
>     ,`detail_ck_rate_28d` FLOAT
>     ,`first_sw_14d` FLOAT
>     ,`package_sw_14d` FLOAT
>     ,`package_ck_14d` FLOAT
>     ,`detail_sw_14d` FLOAT
>     ,`detail_ck_14d` FLOAT
>     ,`package_ck_rate_14d` FLOAT
>     ,`detail_ck_rate_14d` FLOAT
>     ,`first_sw_7d` FLOAT
>     ,`package_sw_7d` FLOAT
>     ,`package_ck_7d` FLOAT
>     ,`detail_sw_7d` FLOAT
>     ,`detail_ck_7d` FLOAT
>     ,`package_ck_rate_7d` FLOAT
>     ,`detail_ck_rate_7d` FLOAT
> )
> partitioned by 
> (
>     dt string
> )
> tblproperties 
> (
>     'TTL' = '180'
> );
>
> with
> base_trace as ( --获取现有的base表的全部信息，先前的DSAR模型的数据获取形式
>     -- select   *
>     select  city_id, 
>             passenger_id, 
>             trace_id, 
>             start_dest_dis, 
>             h, 
>             product_cnt,
>             kflower_one_price_estimate_fee_amt, 
>             min_estimate_fee_amt, 
>             max_estimate_fee_amt,
>             avg_estimate_fee_amt, 
>             quarter_estimate_fee_amt, 
>             median_estimate_fee_amt,
>             three_quarter_estimate_fee_amt, 
>             stddev_estimate_fee_amt, 
>             pap_rank, 
>             pap_price,
>             pap_estimate_id, 
>             pap_stddev, 
>             gap_with_ahead_cp, 
>             gap_with_after_cp, 
>             is_dsa, 
>             is_fangou,
>             is_jump, 
>             hit_rct, 
>             basic_plist, 
>             show_fee_plist, 
>             price_stddev_list,
>             min_basic_total_fee_amt, 
>             max_basic_total_fee_amt, 
>             avg_basic_total_fee_amt,
>             quarter_basic_total_fee_amt, 
>             median_basic_total_fee_amt,
>             three_quarter_basic_total_fee_amt, 
>             min_fee_subsidy_amt, 
>             max_subsidy_rate,
>             min_fee_subsidy_rate, 
>             order_cnt_1month, 
>             finish_order_cnt_1month, 
>             pid_cr_1month,
>             max_fee_scale_1month, 
>             min_fee_scale_1month, 
>             avg_fee_scale_1month,
>             max_call_cp_cnt_1month, 
>             min_call_cp_cnt_1month, 
>             avg_call_cp_cnt_1month,
>             max_call_cp_cnt_ratio_1month, 
>             min_call_cp_cnt_ratio_1month,
>             avg_call_cp_cnt_ratio_1month, 
>             jiagou_order_cnt_1month, 
>             jiagou_order_ratio_1month,
>             fangou_order_cnt_1month, 
>             fangou_order_ratio_1month, 
>             call_min_fee_cnt_1month,
>             call_min_fee_ratio_1month, 
>             is_upto_tj_ratio_1month, 
>             is_upto_tk_ratio_1month,
>             is_upto_ykjia_ratio_1month, 
>             is_upto_tjhezi_ratio_1month, 
>             is_upto_tkhezi_ratio_1month,
>             avg_gap_ahead_1month, 
>             avg_gap_after_1month, 
>             avg_gap_ahead_ratio_1month,
>             avg_gap_after_ratio_1month, 
>             order_cnt_2month, 
>             finish_order_cnt_2month, 
>             pid_cr_2month,
>             max_fee_scale_2month, 
>             min_fee_scale_2month, 
>             avg_fee_scale_2month,
>             max_call_cp_cnt_2month, 
>             min_call_cp_cnt_2month, 
>             avg_call_cp_cnt_2month,
>             max_call_cp_cnt_ratio_2month, 
>             min_call_cp_cnt_ratio_2month,
>             avg_call_cp_cnt_ratio_2month, 
>             jiagou_order_cnt_2month, 
>             jiagou_order_ratio_2month,
>             fangou_order_cnt_2month, 
>             fangou_order_ratio_2month, 
>             call_min_fee_cnt_2month,
>             call_min_fee_ratio_2month, 
>             is_upto_tj_ratio_2month, 
>             is_upto_tk_ratio_2month,
>             is_upto_ykjia_ratio_2month, 
>             is_upto_tjhezi_ratio_2month, 
>             is_upto_tkhezi_ratio_2month,
>             avg_gap_ahead_2month, 
>             avg_gap_after_2month, 
>             avg_gap_ahead_ratio_2month,
>             avg_gap_after_ratio_2month
>     from    kflower_strategy.platform_union_strategy_dsar_traning_data_daily
>     where   dt = '${BIZ_DATE_LINE}'
> ),
>
> hxz_pid_feature as ( -- 获取联合查询的表的结果
>     select  city_id,
>             first_sw_28d,
>             package_sw_28d,
>             package_ck_28d,
>             detail_sw_28d,
>             detail_ck_28d,
>             package_ck_rate_28d,
>             detail_ck_rate_28d,
>             first_sw_14d,
>             package_sw_14d,
>             package_ck_14d,
>             detail_sw_14d,
>             detail_ck_14d,
>             package_ck_rate_14d,
>             detail_ck_rate_14d,
>             first_sw_7d,
>             package_sw_7d,
>             package_ck_7d,
>             detail_sw_7d,
>             detail_ck_7d,
>             package_ck_rate_7d,
>             detail_ck_rate_7d
>     from    kflower_strategy.hxz_pid_feature_package_click
>     where   dt = '${BIZ_DATE_LINE}'
> ),
>
> trace_with_pkg as (
>     select  a.*,
>             b.first_sw_28d,
>             b.package_sw_28d,
>             b.package_ck_28d,
>             b.detail_sw_28d,
>             b.detail_ck_28d,
>             b.package_ck_rate_28d,
>             b.detail_ck_rate_28d,
>             b.first_sw_14d,
>             b.package_sw_14d,
>             b.package_ck_14d,
>             b.detail_sw_14d,
>             b.detail_ck_14d,
>             b.package_ck_rate_14d,
>             b.detail_ck_rate_14d,
>             b.first_sw_7d,
>             b.package_sw_7d,
>             b.package_ck_7d,
>             b.detail_sw_7d,
>             b.detail_ck_7d,
>             b.package_ck_rate_7d,
>             b.detail_ck_rate_7d
>     from    base_trace a
>     left join hxz_pid_feature b
>     on      a.city_id = b.city_id
> )
>
> -- 写入新表
> insert overwrite table platform_dsar_traning_with_hxz_pid_feature_7d_to_28d_daily partition (dt = '${BIZ_DATE_LINE}')
> select *
> from trace_with_pkg;
>
> ```


## 2.3 数据提取

通过pyspark进行HDFS数据获取代码如下
