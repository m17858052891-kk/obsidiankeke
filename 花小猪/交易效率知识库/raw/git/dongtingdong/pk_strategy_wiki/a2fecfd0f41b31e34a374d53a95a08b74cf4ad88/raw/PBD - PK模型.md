
现状： 

- 司机行为特征会根据场景（连环派/非连环派）分开记录

优化点：

- 冷启动没传替代的司机ID，新司机的打分会受影响

部署链接 ：<https://ether.intra.xiaojukeji.com/deploy/4965>

实验链接 ： <https://ether.intra.xiaojukeji.com/labs/new/127551>

AUC= ==0.7345==

模型类型： XGB

特征
| **features name** <br> | **importance** <br> |  <br> |
| --- | --- | --- |
| true_kflower_total_finish_dri_cnt_1d <br> | 307 <br> | 根据是否连环派司机完单 <br> |
| call_hour <br> | 2875 <br> | 发单时间 <br> |
| true_kflower_total_avg_ans_dur_dri_cnt_7d <br> | 739 <br> | 根据是否连环派-司机平均应答时间 <br> |
| true_kflower_total_reassign_dri_cnt_3d <br> | 26 <br> | 根据是否连环派-司机平均应答时间 <br> |
| est_pick_dur <br> | 2041 <br> | 接驾时间 <br> |
| true_kflower_total_avg_ans_dur_dri_cnt_3d <br> | 630 <br> | 根据是否连环派-司机平均应答时间 <br> |
| driver_start_dis <br> | 2582 <br> | 接驾距离 <br> |
| true_kflower_total_cancel_pas_cnt_21d <br> | 566 <br> | 根据是否连环派乘客取消 <br> |
| true_kflower_total_cancel_dri_cnt_21d <br> | 635 <br> | 根据是否连环派司机取消 <br> |
| true_kflower_total_avg_ans_dur_dri_cnt_28d <br> | 1126 <br> | 根据是否连环派-司机平均应答时间 <br> |
| dest_lat <br> | 1077 <br> | 目的地纬度 <br> |
| true_kflower_total_finish_dri_cnt_14d <br> | 739 <br> | 根据是否连环派司机完单 <br> |
| order_waiting_period <br> | 2381 <br> | 等待时间 <br> |
| app_id <br> | 3084 <br> | 商家ID <br> |
| dest_lng <br> | 1022 <br> | 目的地经度 <br> |
| true_kflower_total_cancel_dri_cnt_1d <br> | 216 <br> | 根据是否连环派司机取消 <br> |
| basic_total_fee_amt <br> | 2063 <br> | 预估价 <br> |
| true_kflower_total_refuse_cnt_14d <br> | 333 <br> | 根据是否连环派拒单 <br> |
| true_kflower_total_finish_dri_cnt_28d <br> | 1761 <br> | 根据是否连环派司机完单 <br> |
| true_kflower_total_cancel_pas_cnt_14d <br> | 394 <br> | 根据是否连环派乘客取消 <br> |
| est_start_dest_dur <br> | 1836 <br> | 预估接送时间 <br> |
| true_kflower_total_reassign_dri_cnt_7d <br> | 29 <br> | 根据是否连环派改派 <br> |
| true_kflower_total_cancel_pas_cnt_3d <br> | 165 <br> | 根据是否连环派乘客取消 <br> |
| true_kflower_total_refuse_cnt_1d <br> | 80 <br> | 根据是否连环派拒单 <br> |
| true_kflower_total_reassign_dri_cnt_14d <br> | 41 <br> | 根据是否连环派改派 <br> |
| true_kflower_total_cancel_dri_cnt_14d <br> | 490 <br> | 根据是否连环派司机取消 <br> |
| true_kflower_total_cancel_pas_cnt_7d <br> | 326 <br> | 根据是否连环派乘客取消 <br> |
| city_id <br> | 3188 <br> | 城市 <br> |
| true_kflower_total_reassign_dri_cnt_21d <br> | 56 <br> | 根据是否连环派改派 <br> |
| true_kflower_total_finish_dri_cnt_3d <br> | 378 <br> | 根据是否连环派司机完单 <br> |
| true_kflower_total_avg_ans_dur_dri_cnt_21d <br> | 695 <br> | 根据是否连环派司机平均应答时间 <br> |
| true_kflower_total_avg_ans_dur_dri_cnt_1d <br> | 355 <br> | 根据是否连环派司机平均应答时间 <br> |
| true_kflower_total_reassign_dri_cnt_1d <br> | 24 <br> | 根据是否连环派改派 <br> |
| start_lng <br> | 1576 <br> | 出发地经度 <br> |
| true_kflower_total_avg_ans_dur_dri_cnt_14d <br> | 710 <br> | 根据是否连环派司机平均应答时间 <br> |
| start_lat <br> | 1614 <br> | 出发地纬度 <br> |
| start_dest_distance <br> | 4037 <br> | 送驾距离 <br> |
| true_kflower_total_finish_dri_cnt_7d <br> | 642 <br> |  <br> |
| tre_kflower_total_refuse_cnt_21d <br> | 351 <br> | 根据是否连环派拒单 <br> |
| true_kflower_total_cancel_dri_cnt_3d <br> | 298 <br> | 根据是否连环派司机取消 <br> |
| true_kflower_total_cancel_dri_cnt_7d <br> | 386 <br> | 根据是否连环派司机取消 <br> |
| true_kflower_total_refuse_cnt_28d <br> | 551 <br> | 根据是否连环派拒单 <br> |
| true_kflower_total_finish_dri_cnt_21d <br> | 833 <br> | 根据是否连环派司机完单 <br> |
| true_kflower_total_cancel_pas_cnt_28d <br> | 1264 <br> | 根据是否连环派乘客取消 <br> |
| true_kflower_total_refuse_cnt_3d <br> | 119 <br> | 根据是否连环派拒单 <br> |
| true_kflower_total_cancel_pas_cnt_1d <br> | 99 <br> | 根据是否连环派乘客取消 <br> |
| true_kflower_total_refuse_cnt_7d <br> | 236 <br> | 根据是否连环派拒单 <br> |
| true_kflower_total_cancel_dri_cnt_28d <br> | 1057 <br> | 根据是否连环派司机取消 <br> |
| true_kflower_total_reassign_dri_cnt_28d <br> | 131 <br> | 根据是否连环派改派 <br> |

# 训练数据收集

pbd端：2023/12/29 - 2023/12/29 

# 验证集

pbd端：2024/01/02 - 2024/01/15

|   <br> | AUC <br> |
| --- | --- |
| pbd端 <br> | ==0.7360== <br> |

|   <br> | 绝对胜出率 <br> |
| --- | --- |
| 宏鹄 <br> | 30.34 <br> |
| 滴滴 <br> | 62.19 <br> |
| 一汽 <br> | 28.58 <br> |
| 广汽 <br> | 47.63 <br> |
| 阳光 <br> | 27.48 <br> |
| 享道 <br> | 24.28 <br> |
| 首汽 <br> | 17.13 <br> |
| 曹操出行\_dd <br> | 45.87 <br> |
| ==T3出行\_dd== <br> | 50.76 <br> |
| 花小猪打车 <br> | 35.54 <br> |
