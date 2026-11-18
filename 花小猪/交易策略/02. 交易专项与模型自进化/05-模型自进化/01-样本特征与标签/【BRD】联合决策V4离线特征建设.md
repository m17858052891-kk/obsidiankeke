---
title: "【BRD】联合决策V4离线特征建设"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2208607859084
cssclasses: ["strategy-body-note"]
---

# 【BRD】联合决策V4离线特征建设

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2208607859084)

按 V4 离线特征的业务用途、粒度与产出要求阅读。指标明细和表字段仍保留供开发对照。

**阅读定位**　[[#一、需求背景|一、需求背景]] · [[#二、需求收益|二、需求收益]] · [[#三、需求功能点|三、需求功能点]] · [[#四、工程说明|四、工程说明]]

| | **需求基础信息** |
| --- | --- |
| 望岳 | [https://ddp.intra.xiaojukeji.com/requirement/story/R-KF-706532?backUrl=/workbench/requirement](https://ddp.intra.xiaojukeji.com/requirement/story/R-KF-706532?backUrl=/workbench/requirement) |
| 需求名称 | 联合决策V4离线特征建设 |
| 需求归属部门/FT | 平台供需 |
| 对应项目 | 表单策略 |
| 需求业务owner | 陈嘉曦 |
| ==需求是否申请P0== | 否 |
| 申请P0原因 | |

## 一、需求背景

联合决策V4中模型训练依赖离线特征，因此需要工程在联合随机实验结束前，完成离线特征的开发与回溯。

## 二、需求收益

支持联合决策V4的建模，保证特征口径的准确性、稳定性。

## 三、需求功能点

说明：由于工程人力无法支持7.16号前重新建设所有特征，与DE暂无建设基础明细底表计划的原因，本次需求只实现3.1即可。3.2～3.3读原有表

### 3.1 表单序列特征-历史累计运力

###### **商家X城市X品类原始指标明细**

维度：**商家X城市X品类**

统计周期：历史28天

品类及优先级说明：

- 特快：101（小猪特快）、200（特快盒子）

- 普通：0（普通品类）、102（小猪一口价）、103（小猪打车）

- 特价：104（小猪特价）、105（特价盒子）、202（出行快选）、201（超值达）

- 幸运：107（幸运盒子）

流量：只看小猪端

口径说明：
- 不含改：改派订单和原始订单归为一单，只看最终是否有完单

- 含改：改派订单和原始订单归为两单；改派订单记完单、原始订单记未完单

- 快车竞争应答率=应答数/含快车勾选呼叫数

- 快车客观应答率=应答数/含快车勾选呼叫数剔除被其他品类应答

- 原始底表数指标：冒泡数、呼叫数（含改）、举手数、举手司机数、接驾司机数、应答数（含改）、应答前乘客取消数、应答后乘客取消数（含改）、应答后司机取消数（含改）、完单数、完单GMV（完单口径）、完单C补（完单口径）、完单订单距离、完单送驾时间

	- 完单GMV口径：

		- 表：kflower_dw.dwd_kf_trd_order_anycar_di

		- 字段：gmv_amt

	- 支付C补口径：

		- 表：kflower_finance.dm_kf_fin_rpt_bigagg_order_report_extend_di

		- 字段：p_subsidy_c_total_amt

### ~~3.2 历史P维度特征~~

~~时间归因：归因到冒泡时间~~

~~流量：小猪端~~

~~备注：C补、B补，都是已支付的~~

| ~~特征维度~~ | ~~key~~ | ~~特征~~ |
| --- | --- | --- |
| ~~乘客维度~~ | ~~passenger_id~~ | ~~时间窗口：14日/28日~~ <br>~~数指标：~~ <br>	- ~~交易漏斗：冒泡数、呼叫数、应答订单数（含改/不含改）、应答前乘客取消数、应答后乘客取消数（含改/不含改）、应答后司机取消数（含改/不含改）、完单数、完单gmv、C补金额、B补金额、最大/最小/平均冒泡应付、28日最大/最小/平均冒泡实付~~ <br><br>	- ~~单均指标：单均应答时长、单均接驾时长、单均送驾时长、单均订单预估距离、单均司机接驾距离、单均完单gmv、单均最大/最小/平均预估券前价格、单均最小/最大/平均预估券后价格~~ <br><br>~~率指标：~~ <br>	- ~~C补率、B补率、冒泡呼叫率ECR、呼叫应答率ar、呼叫完单率cr、应答前乘客取消率、应答后乘客取消率（含改/不含改）、应答后司机取消率（含改/不含改）、完单cpm、完单iph、完单estimate_v~~ <br> |
| ~~乘客品类维度~~ | ~~passenger_id~~ | ~~时间窗口：14日/28日~~ <br>~~品类：特快盒子/盒子外/特价盒子/幸运盒子~~ <br>~~数指标：~~ <br>	- ~~交易漏斗：冒泡数、呼叫数、应答数、完单数、总GMV~~ <br><br>	- ~~单均指标：单均应答时长、完单单均距离~~ <br><br>~~率指标：~~ <br>	- ~~ECR、竞争应答率、竞争成交率、冒泡占比、呼叫占比、完单占比、完单ASP、C补率、B补率、完单CPM、完单IPH~~ <br> |
| ~~乘客维度增长特征~~ | ~~passenger_id~~ | ~~表：~~~~merge_all_acti_features~~ <br>~~依赖表：~~ <br>~~kflower_strategy.dm_user_pricing_prefer_stat~~ <br>~~kflower_strategy.dm_user_compete_tag_stat~~ <br>~~kflower_strategy.dm_user_common_behavior_stat~~ <br>~~kflower_strategy.dm_user_behavior_multi_app_stat~~ <br>~~kflower_strategy.competition_pid_tag~~ <br>~~kflower_strategy.hxz_pid_feature_package_click~~ <br>~~特征明细见下~~ |
| ~~乘客维度默勾特征~~ | ~~passenger_id~~ | ~~表：platform_passenger_call_history_agg_info_data~~ <br>~~可重新加工以下口径：~~ <br>~~时间窗口：30/60天~~ <br>~~数指标：~~ <br>	- ~~交易漏斗：最大/最小/平均呼叫价格系数、最大/最小/平均呼叫车型数、最大/最小/平均呼叫车型占展示车型比例、加勾订单数、反勾订单数、默勾接受订单数、只呼叫最低价订单数~~ <br><br>	- ~~单均指标：平均（发单最高价与发单次最高价的价差）、平均（未发单最低价与发单最高价的价差）~~ <br><br>~~率指标：~~ <br>	- ~~加勾订单占比、反勾订单占比、默勾接受订单占比、只呼叫最低价订单占比、发单最高价为“幸运盒子”的订单占比、发单最高价为“特价盒子”的订单占比、发单最高价为“小猪特价”的订单占比、发单最高价为“小猪特快”的订单占比、发单最高价为“小猪一口价”的订单占比、发单最高价为“特快盒子”的订单占比~~ <br> |

~~‍~~

~~原始特征明细：~~

> [!example]- 完整数据表（159 行记录）
> | ~~表名~~ | ~~key~~ | ~~特征名~~ | ~~特征含义~~ |
> | --- | --- | --- | --- |
> | ~~pltf_cr_model_passenger_feature_28d~~ | ~~passenger_id~~ | ~~passenger_cr_28d~~ | ~~28日呼叫完单率cr（完单数/呼叫数）~~ |
> | ~~passenger_finish_cnt_28d~~ | ~~28日完单数~~ |
> | ~~passenger_ecr_28d~~ | ~~28日冒泡呼叫率ecr（呼叫数/冒泡数）~~ |
> | ~~passenger_gmv_amt_28d~~ | ~~28日完单gmv~~ |
> | ~~passenger_call_cnt_28d~~ | ~~28日呼叫数~~ |
> | ~~passenger_p_cancel_after_without_reassign_cnt_28d~~ | ~~28日应答后乘客取消数（不含改）~~ |
> | ~~passenger_subsidy_c_rate_28d~~ | ~~28日C补率（C补金额/完单gmv）~~ |
> | ~~passenger_p_cancel_after_without_reassign_rate_28d~~ | ~~28日应答后乘客取消率（不含改）（应答后乘客取消数/应答订单数）~~ |
> | ~~passenger_ar_28d~~ | ~~28日呼叫应答率ar（应答订单数（不含改）/呼叫数）~~ |
> | ~~passenger_estimate_fee_amt_min_cpm_28d~~ | ~~28日最大冒泡实付~~ |
> | ~~passenger_p_cancel_after_cnt_28d~~ | ~~28日应答后乘客取消数（含改）~~ |
> | ~~passenger_answer_without_reassign_cnt_28d~~ | ~~28日应答订单数（不含改）~~ |
> | ~~passenger_p_cancel_before_rate_28d~~ | ~~28日应答前乘客取消率（应答前乘客取消数/呼叫数）~~ |
> | ~~passenger_p_cancel_before_cnt_28d~~ | ~~28日应答前乘客取消数~~ |
> | ~~passenger_finish_estimate_v_28d~~ | ~~28日完单estimate_v（单均订单预估距离/单均送驾时长）~~ |
> | ~~passenger_estimate_fee_amt_avg_cpm_28d~~ | ~~28日最大冒泡实付~~ |
> | ~~passenger_finish_iph_28d~~ | ~~28日完单iph（单均完单gmv\*100/单均送驾时长）~~ |
> | ~~passenger_p_cancel_after_rate_28d~~ | ~~28日应答后乘客取消率（含改）（应答后乘客取消数（含改）/应答订单数（含改））~~ |
> | ~~passenger_subsidy_c_28d~~ | ~~28日C补金额~~ |
> | ~~pltf_cr_model_pas_category_28d~~ | ~~passenger_id~~ | ~~pas_uabox_ecr_28d~~ | ~~28日特价盒子ecr（特价盒子呼叫数/特价盒子冒泡数）~~ |
> | ~~pas_outbox_gmv_amt_28d~~ | ~~28日盒子外总GMV~~ |
> | ~~pas_outbox_finish_cnt_28d~~ | ~~28日盒子外完单数~~ |
> | ~~pas_ufbox_bubble_cnt_28d~~ | ~~28日特快盒子冒泡数~~ |
> | ~~pas_outbox_subsidy_c_rate_28d~~ | ~~28日盒子外C补率（盒子外C补金额/盒子外总GMV）~~ |
> | ~~pas_outbox_ecr_28d~~ | ~~28日盒子外ecr（盒子外呼叫数/盒子外冒泡数）~~ |
> | ~~pas_outbox_call_cnt_28d~~ | ~~28日盒子外呼叫数~~ |
> | ~~pas_ufbox_call_ratio_28d~~ | ~~28日特快盒子呼叫占比（特快盒子呼叫数/总呼叫数）~~ |
> | ~~pas_ufbox_ecr_28d~~ | ~~28日特快盒子ecr（特快盒子呼叫数/特快盒子冒泡数）~~ |
> | ~~pas_luckybox_ecr_28d~~ | ~~28日幸运盒子ecr（幸运盒子呼叫数/幸运盒子冒泡数）~~ |
> | ~~pas_outbox_call_ratio_28d~~ | ~~28日盒子外呼叫占比（盒子外呼叫数/总呼叫数）~~ |
> | ~~pas_uabox_gmv_amt_28d~~ | ~~28日特价盒子总GMV~~ |
> | ~~pas_luckybox_bubble_ratio_28d~~ | ~~28日幸运盒子冒泡占比（幸运盒子冒泡数/总冒泡数）~~ |
> | ~~pas_uabox_call_ratio_28d~~ | ~~28日特价盒子呼叫占比（特价盒子呼叫数/总呼叫数）~~ |
> | ~~pas_luckybox_call_cnt_28d~~ | ~~28日幸运盒子呼叫数~~ |
> | ~~merge_all_acti_features~~ | ~~passenger_id~~ | ~~pas_ecr_1month~~ | |
> | ~~pas_called_one_price_basic_ratio_avg_1month~~ | |
> | ~~pas_called_one_price_basic_ratio_max_1month~~ | |
> | ~~other_sm_cnt_weekday_28d~~ | |
> | ~~pbd_gd_sm_cnt_30d~~ | |
> | ~~sm_cnt_weekday_14d~~ | |
> | ~~sm_cnt_weekend_28d~~ | |
> | ~~sm_cnt_weekday_28d~~ | |
> | ~~dm_user_base_oneid_info_last_use_kflw~~ | |
> | ~~dm_user_vzt_pub_rfmpeat_kflw_a~~ | |
> | ~~dm_user_vzt_pub_rfmpeat_ut_f~~ | |
> | ~~dm_user_vzt_pub_rfmpeat_other_p~~ | |
> | ~~dm_user_mkt_netcar_ordacc_gcsv2_cost_mean~~ | |
> | ~~dm_user_vzt_pub_rfmpeat_other_synth~~ | |
> | ~~dm_user_base_oneid_info_age~~ | |
> | ~~dm_user_vzt_pub_rfmpeat_btls_a~~ | |
> | ~~dm_user_mkt_netcar_ordacc_jie_subsidy_c_order_ratio~~ | |
> | ~~dm_user_mkt_biz_abst_kflw_cancel_types_divg~~ | |
> | ~~dm_user_vzt_pub_rfmpeat_ut_a~~ | |
> | ~~dm_user_behv_netcar_htpp_vzt_city_num~~ | |
> | ~~dm_user_vzt_pub_rfmpeat_ut_r~~ | |
> | ~~hxz_finish_asp_28d~~ | |
> | ~~is_kf_student_verify~~ | |
> | ~~hxz_finish_cnt_weekday_28d~~ | |
> | ~~dd_kf_sm_bubble_cnt_14d~~ | |
> | ~~pbd_bubble_cnt_weekday_28d~~ | |
> | ~~wyc_bubble_cnt_1d~~ | |
> | ~~pbd_bubble_cnt_7d~~ | |
> | ~~call_ratio_7d~~ | |
> | ~~dd_pbd_sm_bubble_cnt_7d~~ | |
> | ~~hxz_finish_cnt_7d~~ | |
> | ~~dd_gd_sm_cnt_30d~~ | |
> | ~~kf_gd_sm_cnt_30d~~ | |
> | ~~hxz_finish_cnt_28d~~ | |
> | ~~call_ratio_28d~~ | |
> | ~~kf_gd_sm_cnt_7d~~ | |
> | ~~wyc_bubble_cnt_14d~~ | |
> | ~~is_5d_sm~~ | |
> | ~~is_1d_sm~~ | |
> | ~~is_3d_sm~~ | |
> | ~~is_14d_sm~~ | |
> | ~~is_28d_sm~~ | |
> | ~~is_10d_sm~~ | |
> | ~~first_sw_1d~~ | |
> | ~~first_sw_7d~~ | |
> | ~~first_sw_14d~~ | |
> | ~~first_sw_28d~~ | |
> | ~~package_sw_1d~~ | |
> | ~~package_sw_7d~~ | |
> | ~~package_sw_14d~~ | |
> | ~~package_sw_28d~~ | |
> | ~~package_ck_1d~~ | |
> | ~~package_ck_7d~~ | |
> | ~~package_ck_14d~~ | |
> | ~~package_ck_28d~~ | |
> | ~~detail_sw_1d~~ | |
> | ~~detail_sw_7d~~ | |
> | ~~detail_sw_14d~~ | |
> | ~~detail_sw_28d~~ | |
> | ~~detail_ck_1d~~ | |
> | ~~detail_ck_7d~~ | |
> | ~~detail_ck_14d~~ | |
> | ~~detail_ck_28d~~ | |
> | ~~package_ck_rate_1d~~ | |
> | ~~package_ck_rate_7d~~ | |
> | ~~package_ck_rate_14d~~ | |
> | ~~package_ck_rate_28d~~ | |
> | ~~detail_ck_rate_1d~~ | |
> | ~~detail_ck_rate_7d~~ | |
> | ~~detail_ck_rate_14d~~ | |
> | ~~detail_ck_rate_28d~~ | |
> | ~~platform_passenger_call_history_agg_info_data~~ | ~~passenger_id~~ | ~~order_cnt_1month~~ | ~~30日呼叫订单数~~ |
> | ~~finish_order_cnt_1month~~ | ~~30日呼叫完单数~~ |
> | ~~pid_cr_1month~~ | ~~30日呼叫完单率~~ |
> | ~~max_fee_scale_1month~~ | ~~30日最大呼叫价格系数~~ |
> | ~~min_fee_scale_1month~~ | ~~30日最小呼叫价格系数~~ |
> | ~~avg_fee_scale_1month~~ | ~~30日平均呼叫价格系数~~ |
> | ~~max_call_cp_cnt_1month~~ | ~~30日最大呼叫车型数~~ |
> | ~~min_call_cp_cnt_1month~~ | ~~30日最小呼叫车型数~~ |
> | ~~avg_call_cp_cnt_1month~~ | ~~30日平均呼叫车型数~~ |
> | ~~max_call_cp_cnt_ratio_1month~~ | ~~30日最大呼叫车型占展示车型比例~~ |
> | ~~min_call_cp_cnt_ratio_1month~~ | ~~30日最小呼叫车型占展示车型比例~~ |
> | ~~avg_call_cp_cnt_ratio_1month~~ | ~~30日平均呼叫车型占展示车型比例~~ |
> | ~~jiagou_order_cnt_1month~~ | ~~30日加勾订单数~~ |
> | ~~jiagou_order_ratio_1month~~ | ~~30日加勾订单占比（加勾订单数/呼叫订单数）~~ |
> | ~~fangou_order_cnt_1month~~ | ~~30日反勾订单数~~ |
> | ~~fangou_order_ratio_1month~~ | ~~30日反勾订单占比（反勾订单数/呼叫订单数）~~ |
> | ~~call_min_fee_cnt_1month~~ | ~~30日只呼叫最低价订单数~~ |
> | ~~call_min_fee_ratio_1month~~ | ~~30日只呼叫最低价订单占比（只呼叫最低价订单数/呼叫订单数）~~ |
> | ~~is_upto_tj_ratio_1month~~ | ~~30日发单最高价为“小猪特价”的订单占比（发单最高价为“小猪特价”的订单/呼叫订单数）~~ |
> | ~~is_upto_tk_ratio_1month~~ | ~~30日发单最高价为“小猪特快”的订单占比（发单最高价为“小猪特快”的订单/呼叫订单数）~~ |
> | ~~is_upto_ykjia_ratio_1month~~ | ~~30日发单最高价为“小猪一口价”的订单占比（发单最高价为“小猪一口价”的订单/呼叫订单数）~~ |
> | ~~is_upto_tjhezi_ratio_1month~~ | ~~30日发单最高价为“特价盒子”的订单占比（发单最高价为“特价盒子”的订单/呼叫订单数）~~ |
> | ~~is_upto_tkhezi_ratio_1month~~ | ~~30日发单最高价为“特快盒子”的订单占比（发单最高价为“特快盒子”的订单/呼叫订单数）~~ |
> | ~~avg_gap_ahead_1month~~ | ~~30日平均（发单最高价与发单次最高价的价差）~~ |
> | ~~avg_gap_after_1month~~ | ~~30日平均（未呼叫最低价与发单最高价的价差）~~ |
> | ~~avg_gap_ahead_ratio_1month~~ | ~~30日gap_ahead_ratio的平均值（gap_ahead_ratio=（发单最高价-发单次最高价）/最低报价）~~ |
> | ~~avg_gap_after_ratio_1month~~ | ~~30日gap_after_ratio的平均值（gap_after_ratio=（未呼叫最低价-发单最高价）/最低报价）~~ |
> | ~~order_cnt_2month~~ | ~~60日呼叫订单数~~ |
> | ~~finish_order_cnt_2month~~ | ~~60日呼叫完单数~~ |
> | ~~pid_cr_2month~~ | ~~60日呼叫完单率~~ |
> | ~~max_fee_scale_2month~~ | ~~60日最大呼叫价格系数~~ |
> | ~~min_fee_scale_2month~~ | ~~60日最小呼叫价格系数~~ |
> | ~~avg_fee_scale_2month~~ | ~~60日平均呼叫价格系数~~ |
> | ~~max_call_cp_cnt_2month~~ | ~~60日最大呼叫车型数~~ |
> | ~~min_call_cp_cnt_2month~~ | ~~60日最小呼叫车型数~~ |
> | ~~avg_call_cp_cnt_2month~~ | ~~60日平均呼叫车型数~~ |
> | ~~max_call_cp_cnt_ratio_2month~~ | ~~60日最大呼叫车型占展示车型比例~~ |
> | ~~min_call_cp_cnt_ratio_2month~~ | ~~60日最小呼叫车型占展示车型比例~~ |
> | ~~avg_call_cp_cnt_ratio_2month~~ | ~~60日平均呼叫车型占展示车型比例~~ |
> | ~~jiagou_order_cnt_2month~~ | ~~60日加勾订单数~~ |
> | ~~jiagou_order_ratio_2month~~ | ~~60日加勾订单占比（加勾订单数/呼叫订单数）~~ |
> | ~~fangou_order_cnt_2month~~ | ~~60日反勾订单数~~ |
> | ~~fangou_order_ratio_2month~~ | ~~60日反勾订单占比（反勾订单数/呼叫订单数）~~ |
> | ~~call_min_fee_cnt_2month~~ | ~~60日只呼叫最低价订单数~~ |
> | ~~call_min_fee_ratio_2month~~ | ~~60日只呼叫最低价订单占比（只呼叫最低价订单数/呼叫订单数）~~ |
> | ~~is_upto_tj_ratio_2month~~ | ~~60日发单最高价为“小猪特价”的订单占比（发单最高价为“小猪特价”的订单/呼叫订单数）~~ |
> | ~~is_upto_tk_ratio_2month~~ | ~~60日发单最高价为“小猪特快”的订单占比（发单最高价为“小猪特快”的订单/呼叫订单数）~~ |
> | ~~is_upto_ykjia_ratio_2month~~ | ~~60日发单最高价为“小猪一口价”的订单占比（发单最高价为“小猪一口价”的订单/呼叫订单数）~~ |
> | ~~is_upto_tjhezi_ratio_2month~~ | ~~60日发单最高价为“特价盒子”的订单占比（发单最高价为“特价盒子”的订单/呼叫订单数）~~ |
> | ~~is_upto_tkhezi_ratio_2month~~ | ~~60日发单最高价为“特快盒子”的订单占比（发单最高价为“特快盒子”的订单/呼叫订单数）~~ |
> | ~~avg_gap_ahead_2month~~ | ~~60日平均（发单最高价与发单次最高价的价差）~~ |
> | ~~avg_gap_after_2month~~ | ~~60日平均（未呼叫最低价与发单最高价的价差）~~ |
> | ~~avg_gap_ahead_ratio_2month~~ | ~~60日gap_ahead_ratio的平均值（gap_ahead_ratio=（发单最高价-发单次最高价）/最低报价）~~ |
> | ~~avg_gap_after_ratio_2month~~ | ~~60日gap_after_ratio的平均值（gap_after_ratio=（未呼叫最低价-发单最高价）/最低报价）~~ |


### ~~3.3 历史城市维度特征~~

| ~~特征维度~~ | ~~key~~ | ~~特征~~ |
| --- | --- | --- |
| ~~城市维度~~ | ~~city_id~~ | ~~时间窗口：28日~~ <br>~~数指标：~~ <br>	- ~~交易漏斗：冒泡数、呼叫数、应答订单数（含改/不含改）、应答前乘客取消数、应答后乘客取消数（含改/不含改）、应答后司机取消数（含改/不含改）、完单数、完单gmv、C补金额、B补金额、最大/最小/平均冒泡应付、最大/最小/平均冒泡实付~~ <br><br>	- ~~单均指标：单均应答时长、单均接驾时长、单均送驾时长、单均订单预估距离、单均司机接驾距离、单均完单gmv、单均最大/最小/平均预估券前价格、单均最大/最小/平均预估券后价格~~ <br><br>~~率指标：~~ <br>	- ~~C补率、B补率、冒泡呼叫率ECR、呼叫应答率ar、呼叫完单率cr、应答前乘客取消率、应答后乘客取消率（含改/不含改）、应答后司机取消率（含改/不含改）、完单cpm、完单iph、完单estimate_v~~ <br> |
| ~~城市小时维度~~ | ~~city_id、hour_of_day、is_weekday~~ | ~~时间窗口：28日~~ <br>~~数指标：~~ <br>	- ~~交易漏斗：冒泡数、呼叫数、应答订单数（含改/不含改）、应答前乘客取消数、应答后乘客取消数（含改/不含改）、应答后司机取消数（含改/不含改）、完单数、完单 GMV、C补金额、B补金额、最大/最小/平均冒泡应付、最大/最小/平均冒泡实付~~ <br><br>	- ~~单均指标：单均应答时长、单均接驾时长、单均送驾时长、单均订单预估距离、单均司机接驾距离、单均完单GMV、单均最大/最小/平均预估券前价格、单均最大/最小/平均预估券后价格~~ <br><br>~~率指标：~~ <br>	- ~~C补率、B补率、冒泡呼叫率ECR、呼叫应答率ar、呼叫完单率cr、应答前乘客取消率、应答后乘客取消率（含改/不含改）、应答后司机取消率（含改/不含改）、完单cpm、完单iph、完单estimate_v~~ <br> |
| ~~城市品类维度~~ | ~~city_id~~ | ~~时间窗口：28日~~ <br>~~品类：特快盒子/盒子外/特价盒子/幸运盒子~~ <br>~~数指标：~~ <br>	- ~~交易漏斗：冒泡数、呼叫数、应答数、完单数、总GMV~~ <br><br>	- ~~单均指标：单均应答时长、完单单均距离~~ <br><br>~~率指标：~~ <br>	- ~~ECR、竞争应答率、竞争成交率、冒泡占比、呼叫占比、完单占比、完单ASP、C补率、B补率、完单CPM、完单IPH~~ <br> |

~~原始特征明细：~~

> [!example]- 完整数据表（130 行记录）
> | ~~表名~~ | ~~key~~ | ~~特征名~~ | ~~特征含义~~ |
> | --- | --- | --- | --- |
> | ~~pltf_cr_model_city_feature_28d~~ | ~~city_id~~ | ~~city_bubble_cnt_28d~~ | ~~28日冒泡数~~ |
> | ~~city_call_cnt_28d~~ | ~~28日呼叫数~~ |
> | ~~city_answer_cnt_28d~~ | ~~28日应答订单数（含改）~~ |
> | ~~city_answer_without_reassign_cnt_28d~~ | ~~28日应答订单数（不含改）~~ |
> | ~~city_p_cancel_before_cnt_28d~~ | ~~28日应答前乘客取消数~~ |
> | ~~city_p_cancel_after_without_reassign_cnt_28d~~ | ~~28日应答后乘客取消数（不含改）~~ |
> | ~~city_d_cancel_cnt_28d~~ | ~~28日应答后司机取消数（含改）~~ |
> | ~~city_d_cancel_without_reassign_cnt_28d~~ | ~~28日应答后司机取消数（不含改）~~ |
> | ~~city_finish_cnt_28d~~ | ~~28日完单数~~ |
> | ~~city_avg_answer_dur_28d~~ | ~~28日单均应答时长（秒）（应答时长/应答数）~~ |
> | ~~city_avg_arrive_dur_28d~~ | ~~28日单均接驾时长（秒）（接驾时长/完单数）~~ |
> | ~~city_avg_finish_dur_28d~~ | ~~28日单均送驾时长（秒）（送驾时长/完单数）~~ |
> | ~~city_avg_start_dest_dis_28d~~ | ~~28日单均订单预估距离（订单预估距离/冒泡数）~~ |
> | ~~city_avg_driver_start_dis_28d~~ | ~~28日单均司机接驾距离（司机接驾距离/完单数）~~ |
> | ~~city_gmv_amt_28d~~ | ~~28日完单gmv~~ |
> | ~~city_subsidy_c_28d~~ | ~~28日C补金额~~ |
> | ~~city_subsidy_c_rate_28d~~ | ~~28日C补率（C补金额/完单gmv）~~ |
> | ~~city_subsidy_b_rate_28d~~ | ~~28日B补率（B补金额/完单gmv）~~ |
> | ~~city_avg_basic_total_fee_amt_min_28d~~ | ~~28日单均最小预估券前价格，分（最小预估券前价格/冒泡数）~~ |
> | ~~city_avg_estimate_fee_amt_min_28d~~ | ~~28日单均最小预估券后价格，分（最小预估券后价格/冒泡数）~~ |
> | ~~city_avg_estimate_fee_amt_avg_28d~~ | ~~28日单均平均预估券后价格，分（平均预估券后价格/冒泡数）~~ |
> | ~~city_ecr_28d~~ | ~~28日冒泡呼叫率ecr（冒泡数/呼叫数）~~ |
> | ~~city_ar_28d~~ | ~~28日呼叫应答率ar（应答订单数（不含改）/呼叫数）~~ |
> | ~~city_cr_28d~~ | ~~28日呼叫完单率cr（完单数/呼叫数）~~ |
> | ~~city_p_cancel_before_rate_28d~~ | ~~28日应答前乘客取消率~~ |
> | ~~city_p_cancel_after_rate_28d~~ | ~~28日应答后乘客取消率（含改）（应答后乘客取消数/应答订单数）~~ |
> | ~~city_p_cancel_after_without_reassign_rate_28d~~ | ~~28日应答后乘客取消率（不含改）（应答后乘客取消数/应答订单数）~~ |
> | ~~city_d_cancel_without_reassign_rate_28d~~ | ~~28日应答后司机取消率（不含改）（应答后司机取消数/应答订单数）~~ |
> | ~~city_basic_total_fee_amt_max_cpm_28d~~ | ~~28日最大冒泡应付~~ |
> | ~~city_basic_total_fee_amt_min_cpm_28d~~ | ~~28日最小冒泡应付~~ |
> | ~~city_basic_total_fee_amt_avg_cpm_28d~~ | ~~28日平均冒泡应付~~ |
> | ~~city_estimate_fee_amt_max_cpm_28d~~ | ~~28日最大冒泡实付~~ |
> | ~~city_estimate_fee_amt_min_cpm_28d~~ | ~~28日最大冒泡实付~~ |
> | ~~city_estimate_fee_amt_avg_cpm_28d~~ | ~~28日最大冒泡实付~~ |
> | ~~city_gmv_amt_cpm_28d~~ | ~~28日完单cpm（单均完单gmv/单均订单预估距离）~~ |
> | ~~city_finish_estimate_v_28d~~ | ~~28日完单estimate_v（单均订单预估距离/单均送驾时长）~~ |
> | ~~pltf_cr_model_city_hour_weekday_28d~~ | ~~city_id、hour_of_day、is_weekday~~ | ~~city_hour_week_cr_28d~~ | ~~28日呼叫完单率 CR（完单数/呼叫数）~~ |
> | ~~city_hour_week_p_cancel_after_without_reassign_rate_28d~~ | ~~28日应答后乘客取消率（不含改）（应答后乘客取消数/应答数）~~ |
> | ~~city_hour_week_avg_answer_dur_28d~~ | ~~28日单均应答时长，秒（应答时长/应答数）~~ |
> | ~~city_hour_week_bubble_cnt_28d~~ | ~~28日冒泡数~~ |
> | ~~city_hour_week_answer_without_reassign_cnt_28d~~ | ~~28日应答订单数（不含改）~~ |
> | ~~city_hour_week_answer_cnt_28d~~ | ~~28日应答订单数（含改）~~ |
> | ~~city_hour_week_avg_driver_start_dis_28d~~ | ~~28日单均司机接驾距离，米（接驾距离/完单数）~~ |
> | ~~city_hour_week_finish_cnt_28d~~ | ~~28日完单数~~ |
> | ~~city_hour_week_d_cancel_without_reassign_cnt_28d~~ | ~~28日应答后司机取消数（不含改）~~ |
> | ~~city_hour_week_avg_arrive_dur_28d~~ | ~~28日单均接驾时长，秒（接驾时长/完单数）~~ |
> | ~~city_hour_week_p_cancel_after_rate_28d~~ | ~~28日应答后乘客取消率（含改）（应答后乘客取消数/应答数）~~ |
> | ~~city_hour_week_call_cnt_28d~~ | ~~28日呼叫数~~ |
> | ~~city_hour_week_d_cancel_cnt_28d~~ | ~~28日应答后司机取消数（含改）~~ |
> | ~~city_hour_week_subsidy_c_28d~~ | ~~28日 C 补金额~~ |
> | ~~city_hour_week_finish_estimate_v_28d~~ | ~~28日完单estimate_v（单均订单预估距离/单均送驾时长）~~ |
> | ~~city_hour_week_avg_finish_dur_28d~~ | ~~28日单均送驾时长，秒（送驾时长/完单数）~~ |
> | ~~city_hour_week_avg_basic_total_fee_amt_avg_28d~~ | ~~28日单均平均预估券前价格，分（平均预估券前价格/冒泡数）~~ |
> | ~~city_hour_week_ar_28d~~ | ~~28日呼叫应答率 AR（应答数（不含改）/呼叫数）~~ |
> | ~~city_hour_week_p_cancel_after_without_reassign_cnt_28d~~ | ~~28日应答后乘客取消数（不含改）~~ |
> | ~~city_hour_week_basic_total_fee_amt_max_cpm_28d~~ | ~~28日最大冒泡应付 CPM（单均最大预估券前价格/单均订单预估距离）~~ |
> | ~~city_hour_week_subsidy_c_rate_28d~~ | ~~28日 C 补率（C补金额/完单gmv）~~ |
> | ~~city_hour_week_subsidy_b_28d~~ | ~~28日 B 补金额~~ |
> | ~~city_hour_week_basic_total_fee_amt_min_cpm_28d~~ | ~~28日最小冒泡应付 CPM（单均最小预估券前价格/单均订单预估距离）~~ |
> | ~~city_hour_week_gmv_amt_cpm_28d~~ | ~~28日完单 CPM（单均完单gmv\*100/单均订单预估距离）~~ |
> | ~~city_hour_week_p_cancel_before_cnt_28d~~ | ~~28日应答前乘客取消数~~ |
> | ~~city_hour_week_p_cancel_after_cnt_28d~~ | ~~28日应答后乘客取消数（含改）~~ |
> | ~~city_hour_week_avg_gmv_amt_28d~~ | ~~28日单均完单 GMV（完单gmv/完单数）~~ |
> | ~~city_hour_week_avg_start_dest_dis_28d~~ | ~~28日单均订单预估距离（总订单预估距离/冒泡数）~~ |
> | ~~city_hour_week_subsidy_b_rate_28d~~ | ~~28日 B 补率（B补金额/完单gmv）~~ |
> | ~~city_hour_week_finish_iph_28d~~ | ~~28日完单 IPH（单均完单gmv\*100/单均送驾时）~~ |
> | ~~city_hour_week_estimate_fee_amt_min_cpm_28d~~ | ~~28日最小冒泡实付 CPM（单均最小预估券后价格/单均订单预估距离）~~ |
> | ~~city_hour_week_gmv_amt_28d~~ | ~~28日完单 GMV~~ |
> | ~~city_hour_week_p_cancel_before_rate_28d~~ | ~~28日应答前乘客取消率（应答前乘客取消数/呼叫数）~~ |
> | ~~city_hour_week_estimate_fee_amt_max_cpm_28d~~ | ~~28日最大冒泡实付 CPM（单均最大预估券后价格/单均订单预估距离）~~ |
> | ~~pltf_cr_model_city_category_28d~~ | ~~city_id~~ | ~~city_ufbox_bubble_cnt_28d~~ | ~~28日特快盒子冒泡数~~ |
> | ~~city_ufbox_call_cnt_28d~~ | ~~28日特快盒子呼叫数~~ |
> | ~~city_ufbox_answer_cnt_28d~~ | ~~28日特快盒子应答数~~ |
> | ~~city_ufbox_finish_cnt_28d~~ | ~~28日特快盒子完单数~~ |
> | ~~city_ufbox_ecr_28d~~ | ~~28日特快盒子 ecr（特快盒子呼叫数/特快盒子冒泡数）~~ |
> | ~~city_ufbox_ar_28d~~ | ~~28日特快盒子竞争应答率（特快盒子应答数（不含改）/特快盒子呼叫数）~~ |
> | ~~city_ufbox_cr_28d~~ | ~~28日特快盒子竞争成交率（特快盒子完单数/特快盒子呼叫数）~~ |
> | ~~city_ufbox_bubble_ratio_28d~~ | ~~28日特快盒子冒泡占比（特快盒子冒泡数/总冒泡数）~~ |
> | ~~city_ufbox_call_ratio_28d~~ | ~~28日特快盒子呼叫占比（特快盒子呼叫数/总呼叫数）~~ |
> | ~~city_ufbox_finish_ratio_28d~~ | ~~28日特快盒子完单占比（特快盒子完单数/总完单数）~~ |
> | ~~city_ufbox_avg_answer_dur_28d~~ | ~~28日特快盒子单均应答时长（特快盒子应答时长/特快盒子应答数）~~ |
> | ~~city_ufbox_avg_start_dest_dis_28d~~ | ~~28日特快盒子完单单均距离（特快盒子完单距离/特快盒子完单数）~~ |
> | ~~city_ufbox_avg_gmv_amt_28d~~ | ~~28日特快盒子完单 ASP（特快盒子完单gmv/特快盒子完单数）~~ |
> | ~~city_ufbox_subsidy_c_rate_28d~~ | ~~28日特快盒子 C 补率（特快盒子C补金额/特快盒子完单gmv）~~ |
> | ~~city_ufbox_finish_cpm_28d~~ | ~~28日特快盒子完单 CPM（特快盒子gmv\*100/特快盒子完单距离）~~ |
> | ~~city_ufbox_finish_iph_28d~~ | ~~28日特快盒子完单 IPH（特快盒子gmv\*100/特快盒子完单时间）~~ |
> | ~~city_outbox_bubble_cnt_28d~~ | ~~28日盒子外冒泡数~~ |
> | ~~city_outbox_call_cnt_28d~~ | ~~28日盒子外呼叫数~~ |
> | ~~city_outbox_answer_cnt_28d~~ | ~~28日盒子外应答数~~ |
> | ~~city_outbox_finish_cnt_28d~~ | ~~28日盒子外完单数~~ |
> | ~~city_outbox_ecr_28d~~ | ~~28日盒子外 ecr（盒子外呼叫数/盒子外冒泡数）~~ |
> | ~~city_outbox_ar_28d~~ | ~~28日盒子外竞争应答率（盒子外应答数（不含改）/盒子外呼叫数）~~ |
> | ~~city_outbox_cr_28d~~ | ~~28日盒子外竞争成交率（盒子外完单数/盒子外呼叫数）~~ |
> | ~~city_outbox_bubble_ratio_28d~~ | ~~28日盒子外冒泡占比（盒子外冒泡数/总冒泡数）~~ |
> | ~~city_outbox_call_ratio_28d~~ | ~~28日盒子外呼叫占比（盒子外呼叫数/总呼叫数）~~ |
> | ~~city_outbox_finish_ratio_28d~~ | ~~28日盒子外完单占比（盒子外完单数/总完单数）~~ |
> | ~~city_outbox_avg_start_dest_dis_28d~~ | ~~28日盒子外完单单均距离（盒子外完单距离/盒子外完单数）~~ |
> | ~~city_outbox_gmv_amt_28d~~ | ~~28日盒子外总 GMV~~ |
> | ~~city_outbox_avg_gmv_amt_28d~~ | ~~28日盒子外完单 ASP（盒子外完单 GMV/盒子外完单数）~~ |
> | ~~city_outbox_subsidy_c_rate_28d~~ | ~~28日盒子外 C 补率（盒子外 C 补金额/盒子外完单 GMV）~~ |
> | ~~city_outbox_subsidy_b_rate_28d~~ | ~~28日盒子外 B 补率（盒子外 B 补金额/盒子外完单 GMV）~~ |
> | ~~city_outbox_finish_cpm_28d~~ | ~~28日盒子外完单 CPM（盒子外 GMV\*100/盒子外完单距离）~~ |
> | ~~city_outbox_finish_iph_28d~~ | ~~28日盒子外完单 IPH（盒子外 GMV\*100/盒子外完单时间）~~ |
> | ~~city_uabox_call_cnt_28d~~ | ~~28日特价盒子呼叫数~~ |
> | ~~city_uabox_finish_cnt_28d~~ | ~~28日特价盒子完单数~~ |
> | ~~city_uabox_ecr_28d~~ | ~~28日特价盒子 ecr（特价盒子呼叫数/特价盒子冒泡数）~~ |
> | ~~city_uabox_ar_28d~~ | ~~28日特价盒子竞争应答率（特价盒子应答数（不含改）/特价盒子呼叫数）~~ |
> | ~~city_uabox_cr_28d~~ | ~~28日特价盒子竞争成交率（特价盒子完单数/特价盒子呼叫数）~~ |
> | ~~city_uabox_bubble_ratio_28d~~ | ~~28日特价盒子冒泡占比（特价盒子冒泡数/总冒泡数）~~ |
> | ~~city_uabox_call_ratio_28d~~ | ~~28日特价盒子呼叫占比（特价盒子呼叫数/总呼叫数）~~ |
> | ~~city_uabox_finish_ratio_28d~~ | ~~28日特价盒子完单占比（特价盒子完单数/总完单数）~~ |
> | ~~city_uabox_avg_answer_dur_28d~~ | ~~28日特价盒子单均应答时长（特价盒子应答时长/特价盒子应答数）~~ |
> | ~~city_uabox_avg_start_dest_dis_28d~~ | ~~28日特价盒子完单单均距离（特价盒子完单距离/特价盒子完单数）~~ |
> | ~~city_uabox_gmv_amt_28d~~ | ~~28日特价盒子总 GMV~~ |
> | ~~city_uabox_avg_gmv_amt_28d~~ | ~~28日特价盒子完单 ASP（特价盒子完单 GMV/特价盒子完单数）~~ |
> | ~~city_uabox_subsidy_c_rate_28d~~ | ~~28日特价盒子 C 补率（特价盒子 C 补金额/特价盒子完单 GMV）~~ |
> | ~~city_uabox_subsidy_b_rate_28d~~ | ~~28日特价盒子 B 补率（特价盒子 B 补金额/特价盒子完单 GMV）~~ |
> | ~~city_uabox_finish_cpm_28d~~ | ~~28日特价盒子完单 CPM（特价盒子 GMV\*100/特价盒子完单距离）~~ |
> | ~~city_uabox_finish_iph_28d~~ | ~~28日特价盒子完单 IPH（特价盒子 GMV\*100/特价盒子完单时间）~~ |
> | ~~city_luckybox_call_cnt_28d~~ | ~~28日幸运盒子呼叫数~~ |
> | ~~city_luckybox_finish_cnt_28d~~ | ~~28日幸运盒子完单数~~ |
> | ~~city_luckybox_ecr_28d~~ | ~~28日幸运盒子 ecr（幸运盒子呼叫数/幸运盒子冒泡数）~~ |
> | ~~city_luckybox_ar_28d~~ | ~~28日幸运盒子竞争应答率（幸运盒子应答数（不含改）/幸运盒子呼叫数）~~ |
> | ~~city_luckybox_cr_28d~~ | ~~28日幸运盒子竞争成交率（幸运盒子完单数/幸运盒子呼叫数）~~ |
> | ~~city_luckybox_call_ratio_28d~~ | ~~28日幸运盒子呼叫占比（幸运盒子呼叫数/总呼叫数）~~ |
> | ~~city_luckybox_finish_ratio_28d~~ | ~~28日幸运盒子完单占比（幸运盒子完单数/总完单数）~~ |
> | ~~city_luckybox_avg_answer_dur_28d~~ | ~~28日幸运盒子单均应答时长（幸运盒子应答时长/幸运盒子应答数）~~ |
> | ~~city_luckybox_gmv_amt_28d~~ | ~~28日幸运盒子总 GMV~~ |
> | ~~city_luckybox_finish_cpm_28d~~ | ~~28日幸运盒子完单 CPM（幸运盒子 GMV\*100/幸运盒子完单距离）~~ |
> | ~~city_luckybox_finish_iph_28d~~ | ~~28日幸运盒子完单 IPH（幸运盒子 GMV\*100/幸运盒子完单时间）~~ |


## 四、工程说明

需回溯7.1后的特征数据
