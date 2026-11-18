---
title: "【快速介入BRD】acc_CR模型落日志"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2206032346365
cssclasses: ["strategy-body-note"]
---

# 【快速介入BRD】acc_CR模型落日志

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2206032346365)

**阅读定位**　[[#一、需求背景|一、需求背景]] · [[#二、工程方案|二、工程方案]]

## 一、需求背景

在「[带盒子愿接开关的SDS实时特征建设](https://cooper.didichuxing.com/knowledge/2199610335356/2205051429416)」需求中，我们建设了区分司机接单模式的一系列SDS特征，本需求旨在收集训练数据，用于acc_CR后续的模型训练。

## 二、工程方案

在acc_CR模型调用的时候，获取新的特征，并落到eve的模型日志中。

- 日志表：kflower_marketplace.ods_log_kflower_dups_eve_public_log_h

- model_name：union_strategy_ar_deep_model_gpu

- 空值填充-9999

本次需要新增的特征包括：

> [!example]- 完整数据表（134 行记录）
> | 分类 | 时间维度 | 含义 | sds特征 | 注意！！！！！ |
> | --- | --- | --- | --- | --- |
> | 司机运力特征 | 实时 | 幸运盒子全指派在线司机数实时 | realtime_lucky_box_driver_active_auto_assign_cnt | **加后缀\_one_circle_grid，代表是中心格子+一圈格子** <br>**不加后缀，代表是中心格子** |
> | 幸运盒子半指派在线司机数实时 | realtime_lucky_box_driver_active_half_assign_cnt |
> | 幸运盒子抢单在线司机数实时 | realtime_lucky_box_driver_active_strive_cnt |
> | 幸运盒子全指派空车司机数实时 | realtime_lucky_box_driver_empty_auto_assign_cnt |
> | 幸运盒子半指派空车司机数实时 | realtime_lucky_box_driver_empty_half_assign_cnt |
> | 幸运盒子抢单空车司机数实时 | realtime_lucky_box_driver_empty_strive_cnt |
> | 特价盒子全指派在线司机数实时 | realtime_special_offer_box_driver_active_auto_assign_cnt |
> | 特价盒子半指派在线司机数实时 | realtime_special_offer_box_driver_active_half_assign_cnt |
> | 特价盒子抢单在线司机数实时 | realtime_special_offer_box_driver_active_strive_cnt |
> | 特价盒子全指派空车司机数实时 | realtime_special_offer_box_driver_empty_auto_assign_cnt |
> | 特价盒子半指派空车司机数实时 | realtime_special_offer_box_driver_empty_half_assign_cnt |
> | 特价盒子抢单空车司机数实时 | realtime_special_offer_box_driver_empty_strive_cnt |
> | 1min | 幸运盒子全指派在线司机数1分钟 | lucky_box_driver_active_auto_assign_cnt_1min |
> | 幸运盒子半指派在线司机数1分钟 | lucky_box_driver_active_half_assign_cnt_1min |
> | 幸运盒子抢单在线司机数1分钟 | lucky_box_driver_active_strive_cnt_1min |
> | 幸运盒子全指派空车司机数1分钟 | lucky_box_driver_empty_auto_assign_cnt_1min |
> | 幸运盒子半指派空车司机数1分钟 | lucky_box_driver_empty_half_assign_cnt_1min |
> | 幸运盒子抢单空车司机数1分钟 | lucky_box_driver_empty_strive_cnt_1min |
> | 特价盒子全指派在线司机数1分钟 | special_offer_box_driver_active_auto_assign_cnt_1min |
> | 特价盒子半指派在线司机数1分钟 | special_offer_box_driver_active_half_assign_cnt_1min |
> | 特价盒子抢单在线司机数1分钟 | special_offer_box_driver_active_strive_cnt_1min |
> | 特价盒子全指派空车司机数1分钟 | special_offer_box_driver_empty_auto_assign_cnt_1min |
> | 特价盒子半指派空车司机数1分钟 | special_offer_box_driver_empty_half_assign_cnt_1min |
> | 特价盒子抢单空车司机数1分钟 | special_offer_box_driver_empty_strive_cnt_1min |
> | 3min | 幸运盒子全指派在线司机数3分钟 | lucky_box_driver_active_auto_assign_cnt_3min |
> | 幸运盒子半指派在线司机数3分钟 | lucky_box_driver_active_half_assign_cnt_3min |
> | 幸运盒子抢单在线司机数3分钟 | lucky_box_driver_active_strive_cnt_3min |
> | 幸运盒子全指派空车司机数3分钟 | lucky_box_driver_empty_auto_assign_cnt_3min |
> | 幸运盒子半指派空车司机数3分钟 | lucky_box_driver_empty_half_assign_cnt_3min |
> | 幸运盒子抢单空车司机数3分钟 | lucky_box_driver_empty_strive_cnt_3min |
> | 特价盒子全指派在线司机数3分钟 | special_offer_box_driver_active_auto_assign_cnt_3min |
> | 特价盒子半指派在线司机数3分钟 | special_offer_box_driver_active_half_assign_cnt_3min |
> | 特价盒子抢单在线司机数3分钟 | special_offer_box_driver_active_strive_cnt_3min |
> | 特价盒子全指派空车司机数3分钟 | special_offer_box_driver_empty_auto_assign_cnt_3min |
> | 特价盒子半指派空车司机数3分钟 | special_offer_box_driver_empty_half_assign_cnt_3min |
> | 特价盒子抢单空车司机数3分钟 | special_offer_box_driver_empty_strive_cnt_3min |
> | 10min | 幸运盒子全指派在线司机数10分钟 | lucky_box_driver_active_auto_assign_cnt_10min |
> | 幸运盒子半指派在线司机数10分钟 | lucky_box_driver_active_half_assign_cnt_10min |
> | 幸运盒子抢单在线司机数10分钟 | lucky_box_driver_active_strive_cnt_10min |
> | 幸运盒子全指派空车司机数10分钟 | lucky_box_driver_empty_auto_assign_cnt_10min |
> | 幸运盒子半指派空车司机数10分钟 | lucky_box_driver_empty_half_assign_cnt_10min |
> | 幸运盒子抢单空车司机数10分钟 | lucky_box_driver_empty_strive_cnt_10min |
> | 特价盒子全指派在线司机数10分钟 | special_offer_box_driver_active_auto_assign_cnt_10min |
> | 特价盒子半指派在线司机数10分钟 | special_offer_box_driver_active_half_assign_cnt_10min |
> | 特价盒子抢单在线司机数10分钟 | special_offer_box_driver_active_strive_cnt_10min |
> | 特价盒子全指派空车司机数10分钟 | special_offer_box_driver_empty_auto_assign_cnt_10min |
> | 特价盒子半指派空车司机数10分钟 | special_offer_box_driver_empty_half_assign_cnt_10min |
> | 特价盒子抢单空车司机数10分钟 | special_offer_box_driver_empty_strive_cnt_10min |
> | 品类聚合特征 | 1min | 幸运盒子去重举手数1分钟 | lucky_box_duse_pk_driver_unique_cnt_1min |
> | 幸运盒子应答数1分钟 | lucky_box_strive_order_cnt_1min |
> | 幸运盒子完单数1分钟 | lucky_box_finish_order_cnt_1min |
> | 特价盒子去重举手数1分钟 | special_offer_box_duse_pk_driver_unique_cnt_1min |
> | 特价盒子应答数1分钟 | special_offer_box_strive_order_cnt_1min |
> | 特价盒子完单数1分钟 | special_offer_box_finish_order_cnt_1min |
> | 3min | 幸运盒子去重举手数3分钟 | lucky_box_duse_pk_driver_unique_cnt_3min |
> | 幸运盒子应答数3分钟 | lucky_box_strive_order_cnt_3min |
> | 幸运盒子完单数3分钟 | lucky_box_finish_order_cnt_3min |
> | 特价盒子去重举手数3分钟 | special_offer_box_duse_pk_driver_unique_cnt_3min |
> | 特价盒子应答数3分钟 | special_offer_box_strive_order_cnt_3min |
> | 特价盒子完单数3分钟 | special_offer_box_finish_order_cnt_3min |
> | 10min | 幸运盒子去重举手数10分钟 | lucky_box_duse_pk_driver_unique_cnt_10min |
> | 幸运盒子应答数10分钟 | lucky_box_strive_order_cnt_10min |
> | 幸运盒子完单数10分钟 | lucky_box_finish_order_cnt_10min |
> | 特价盒子去重举手数10分钟 | special_offer_box_duse_pk_driver_unique_cnt_10min |
> | 特价盒子应答数10分钟 | special_offer_box_strive_order_cnt_10min |
> | 特价盒子完单数10分钟 | special_offer_box_finish_order_cnt_10min |
> | 司机运力特征 | 实时 | 幸运盒子全指派在线司机数实时中心+一圈格子 | realtime_lucky_box_driver_active_auto_assign_cnt_one_circle_grid |
> | 幸运盒子半指派在线司机数实时中心+一圈格子 | realtime_lucky_box_driver_active_half_assign_cnt_one_circle_grid |
> | 幸运盒子抢单在线司机数实时中心+一圈格子 | realtime_lucky_box_driver_active_strive_cnt_one_circle_grid |
> | 幸运盒子全指派空车司机数实时中心+一圈格子 | realtime_lucky_box_driver_empty_auto_assign_cnt_one_circle_grid |
> | 幸运盒子半指派空车司机数实时中心+一圈格子 | realtime_lucky_box_driver_empty_half_assign_cnt_one_circle_grid |
> | 幸运盒子抢单空车司机数实时中心+一圈格子 | realtime_lucky_box_driver_empty_strive_cnt_one_circle_grid |
> | 特价盒子全指派在线司机数实时中心+一圈格子 | realtime_special_offer_box_driver_active_auto_assign_cnt_one_circle_grid |
> | 特价盒子半指派在线司机数实时中心+一圈格子 | realtime_special_offer_box_driver_active_half_assign_cnt_one_circle_grid |
> | 特价盒子抢单在线司机数实时中心+一圈格子 | realtime_special_offer_box_driver_active_strive_cnt_one_circle_grid |
> | 特价盒子全指派空车司机数实时中心+一圈格子 | realtime_special_offer_box_driver_empty_auto_assign_cnt_one_circle_grid |
> | 特价盒子半指派空车司机数实时中心+一圈格子 | realtime_special_offer_box_driver_empty_half_assign_cnt_one_circle_grid |
> | 特价盒子抢单空车司机数实时中心+一圈格子 | realtime_special_offer_box_driver_empty_strive_cnt_one_circle_grid |
> | 1min | 幸运盒子全指派在线司机数1分钟中心+一圈格子 | lucky_box_driver_active_auto_assign_cnt_1min_one_circle_grid |
> | 幸运盒子半指派在线司机数1分钟中心+一圈格子 | lucky_box_driver_active_half_assign_cnt_1min_one_circle_grid |
> | 幸运盒子抢单在线司机数1分钟中心+一圈格子 | lucky_box_driver_active_strive_cnt_1min_one_circle_grid |
> | 幸运盒子全指派空车司机数1分钟中心+一圈格子 | lucky_box_driver_empty_auto_assign_cnt_1min_one_circle_grid |
> | 幸运盒子半指派空车司机数1分钟中心+一圈格子 | lucky_box_driver_empty_half_assign_cnt_1min_one_circle_grid |
> | 幸运盒子抢单空车司机数1分钟中心+一圈格子 | lucky_box_driver_empty_strive_cnt_1min_one_circle_grid |
> | 特价盒子全指派在线司机数1分钟中心+一圈格子 | special_offer_box_driver_active_auto_assign_cnt_1min_one_circle_grid |
> | 特价盒子半指派在线司机数1分钟中心+一圈格子 | special_offer_box_driver_active_half_assign_cnt_1min_one_circle_grid |
> | 特价盒子抢单在线司机数1分钟中心+一圈格子 | special_offer_box_driver_active_strive_cnt_1min_one_circle_grid |
> | 特价盒子全指派空车司机数1分钟中心+一圈格子 | special_offer_box_driver_empty_auto_assign_cnt_1min_one_circle_grid |
> | 特价盒子半指派空车司机数1分钟中心+一圈格子 | special_offer_box_driver_empty_half_assign_cnt_1min_one_circle_grid |
> | 特价盒子抢单空车司机数1分钟中心+一圈格子 | special_offer_box_driver_empty_strive_cnt_1min_one_circle_grid |
> | 3min | 幸运盒子全指派在线司机数3分钟中心+一圈格子 | lucky_box_driver_active_auto_assign_cnt_3min_one_circle_grid |
> | 幸运盒子半指派在线司机数3分钟中心+一圈格子 | lucky_box_driver_active_half_assign_cnt_3min_one_circle_grid |
> | 幸运盒子抢单在线司机数3分钟中心+一圈格子 | lucky_box_driver_active_strive_cnt_3min_one_circle_grid |
> | 幸运盒子全指派空车司机数3分钟中心+一圈格子 | lucky_box_driver_empty_auto_assign_cnt_3min_one_circle_grid |
> | 幸运盒子半指派空车司机数3分钟中心+一圈格子 | lucky_box_driver_empty_half_assign_cnt_3min_one_circle_grid |
> | 幸运盒子抢单空车司机数3分钟中心+一圈格子 | lucky_box_driver_empty_strive_cnt_3min_one_circle_grid |
> | 特价盒子全指派在线司机数3分钟中心+一圈格子 | special_offer_box_driver_active_auto_assign_cnt_3min_one_circle_grid |
> | 特价盒子半指派在线司机数3分钟中心+一圈格子 | special_offer_box_driver_active_half_assign_cnt_3min_one_circle_grid |
> | 特价盒子抢单在线司机数3分钟中心+一圈格子 | special_offer_box_driver_active_strive_cnt_3min_one_circle_grid |
> | 特价盒子全指派空车司机数3分钟中心+一圈格子 | special_offer_box_driver_empty_auto_assign_cnt_3min_one_circle_grid |
> | 特价盒子半指派空车司机数3分钟中心+一圈格子 | special_offer_box_driver_empty_half_assign_cnt_3min_one_circle_grid |
> | 特价盒子抢单空车司机数3分钟中心+一圈格子 | special_offer_box_driver_empty_strive_cnt_3min_one_circle_grid |
> | 10min | 幸运盒子全指派在线司机数10分钟中心+一圈格子 | lucky_box_driver_active_auto_assign_cnt_10min_one_circle_grid |
> | 幸运盒子半指派在线司机数10分钟中心+一圈格子 | lucky_box_driver_active_half_assign_cnt_10min_one_circle_grid |
> | 幸运盒子抢单在线司机数10分钟中心+一圈格子 | lucky_box_driver_active_strive_cnt_10min_one_circle_grid |
> | 幸运盒子全指派空车司机数10分钟中心+一圈格子 | lucky_box_driver_empty_auto_assign_cnt_10min_one_circle_grid |
> | 幸运盒子半指派空车司机数10分钟中心+一圈格子 | lucky_box_driver_empty_half_assign_cnt_10min_one_circle_grid |
> | 幸运盒子抢单空车司机数10分钟中心+一圈格子 | lucky_box_driver_empty_strive_cnt_10min_one_circle_grid |
> | 特价盒子全指派在线司机数10分钟中心+一圈格子 | special_offer_box_driver_active_auto_assign_cnt_10min_one_circle_grid |
> | 特价盒子半指派在线司机数10分钟中心+一圈格子 | special_offer_box_driver_active_half_assign_cnt_10min_one_circle_grid |
> | 特价盒子抢单在线司机数10分钟中心+一圈格子 | special_offer_box_driver_active_strive_cnt_10min_one_circle_grid |
> | 特价盒子全指派空车司机数10分钟中心+一圈格子 | special_offer_box_driver_empty_auto_assign_cnt_10min_one_circle_grid |
> | 特价盒子半指派空车司机数10分钟中心+一圈格子 | special_offer_box_driver_empty_half_assign_cnt_10min_one_circle_grid |
> | 特价盒子抢单空车司机数10分钟中心+一圈格子 | special_offer_box_driver_empty_strive_cnt_10min_one_circle_grid |
> | 品类聚合特征 | 1min | 幸运盒子去重举手数1分钟中心+一圈格子 | lucky_box_duse_pk_driver_unique_cnt_1min_one_circle_grid |
> | 幸运盒子应答数1分钟中心+一圈格子 | lucky_box_strive_order_cnt_1min_one_circle_grid |
> | 幸运盒子完单数1分钟中心+一圈格子 | lucky_box_finish_order_cnt_1min_one_circle_grid |
> | 特价盒子去重举手数1分钟中心+一圈格子 | special_offer_box_duse_pk_driver_unique_cnt_1min_one_circle_grid |
> | 特价盒子应答数1分钟中心+一圈格子 | special_offer_box_strive_order_cnt_1min_one_circle_grid |
> | 特价盒子完单数1分钟中心+一圈格子 | special_offer_box_finish_order_cnt_1min_one_circle_grid |
> | 3min | 幸运盒子去重举手数3分钟中心+一圈格子 | lucky_box_duse_pk_driver_unique_cnt_3min_one_circle_grid |
> | 幸运盒子应答数3分钟中心+一圈格子 | lucky_box_strive_order_cnt_3min_one_circle_grid |
> | 幸运盒子完单数3分钟中心+一圈格子 | lucky_box_finish_order_cnt_3min_one_circle_grid |
> | 特价盒子去重举手数3分钟中心+一圈格子 | special_offer_box_duse_pk_driver_unique_cnt_3min_one_circle_grid |
> | 特价盒子应答数3分钟中心+一圈格子 | special_offer_box_strive_order_cnt_3min_one_circle_grid |
> | 特价盒子完单数3分钟中心+一圈格子 | special_offer_box_finish_order_cnt_3min_one_circle_grid |
> | 10min | 幸运盒子去重举手数10分钟中心+一圈格子 | lucky_box_duse_pk_driver_unique_cnt_10min_one_circle_grid |
> | 幸运盒子应答数10分钟中心+一圈格子 | lucky_box_strive_order_cnt_10min_one_circle_grid |
> | 幸运盒子完单数10分钟中心+一圈格子 | lucky_box_finish_order_cnt_10min_one_circle_grid |
> | 特价盒子去重举手数10分钟中心+一圈格子 | special_offer_box_duse_pk_driver_unique_cnt_10min_one_circle_grid |
> | 特价盒子应答数10分钟中心+一圈格子 | special_offer_box_strive_order_cnt_10min_one_circle_grid |
> | 特价盒子完单数10分钟中心+一圈格子 | special_offer_box_finish_order_cnt_10min_one_circle_grid |
> | 旧sds特征 | 实时 | 实时未播订单数-一圈格子 | realtime_no_broadcast_cnt_one_circle_grid | |
> | 实时未播订单数 | realtime_no_broadcast_cnt | |
