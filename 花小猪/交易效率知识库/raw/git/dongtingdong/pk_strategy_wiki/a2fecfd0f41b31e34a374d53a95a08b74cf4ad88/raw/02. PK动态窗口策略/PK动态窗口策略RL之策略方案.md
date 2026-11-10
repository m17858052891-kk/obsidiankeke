# 1、背景

PK时间窗口是聚合平台极具特色性的流量调节手段。通过改变窗口形态，权衡PK时间对应答前后取消率的影响，提升平台的成交率

- 静态窗口：固定收集司机的时间窗口为4秒。当有司机举手时，保留PK打分最高的当前胜者，窗口结束时的当前胜者最终胜出

- 动态窗口：动态调整收集司机的时间窗口。当有司机举手时，保留PK打分最高的当前胜者，判断是否满足窗口结束的条件

当前PK时间窗口策略均为模型阈值策略，收益空间受限于策略框架较低的复杂程度，因此探索应用强化学习算法进行框架升级

- 模型阈值：有监督学习司乘组合的完单概率，让完单概率较大的司乘组合尽早胜出，在保证策略精准触发的前提下加快运力流转

- 强化学习：持续与环境进行交互，将探索和更新融入策略框架，能更好地适应在差异化情境下的决策，可视为模型阈值策略的拓展

![](https://cooper.didichuxing.com/uploader/f/J3ATHWxbbGuJraX9.png?accessToken=eyJhbGciOiJIUzI1NiIsImtpZCI6ImRlZmF1bHQiLCJ0eXAiOiJKV1QifQ.eyJleHAiOjE3MjkxNDk3OTEsImZpbGVHVUlEIjoiWkxlQUh3M2x5RGY5NmlJWCIsImlhdCI6MTcyOTE0OTE5MSwiaXNzIjoidXBsb2FkZXJfYWNjZXNzX3Jlc291cmNlIiwidXNlcklkIjoxMDAwMDE4MTExNn0.f5BOC26dgc3u7Y1DN6b17AZ21HXR6iLlTQF4qM4yINk)

# 2、策略部分

## 2.1、概念定义

| 概念 <br> | 定义 <br> |
| --- | --- |
| 状态空间 <br> | $$s_t = (t, [f_c], [f_w], [f_l])$$ <br>$$t$$：司机举手时的PK窗口时间 <br>$$[f_c]$$：订单特征和供需特征 <br>$$[f_w]$$：$$t$$时刻胜出司机的PK打分和特征 <br>$$[f_l]$$：$$t$$时刻失败司机的PK打分和特征 <br> |
| 动作空间 <br> | $$a_t \in \{0,1\}$$ <br>$$a_t=0$$：当前胜者暂不胜出，PK窗口继续 <br>$$a_t=1$$：当前胜者直接胜出，PK窗口结束 <br> |
| 奖励函数 <br> | $$r_t=-\Delta t,  \ t \neq T$$ <br>$$r_T=  \begin{cases}  R - (L - T), & \text{完单}, \\ -\alpha C- (L - T), & \text{司机拒单/司机取消},\\ -C-(L - T), & \text{乘客取消} \end{cases}$$ <br>$$\Delta t$$：当前举手时刻与后一个举手时刻的间隔 <br>$$T$$：最后一个司机举手时刻 <br>$$L$$：窗口结束时刻。若最后一个司机触发直接胜出，则$$L=T$$ <br> |

## 2.2、数据构造

模型训练过程采用窗口内所有司机的序列化特征，推理过程采用举手司机的数值特征

```PlainText
window = {
    "order_id": o1,
    "roundnum": 1,
    "handsup_num": 3,
    "is_trigger": 1,
    "is_finish": 0,
    "driver_id": [d1, d2, d3],
    "pktime": [0.0, 1.5, 3.5],
    "common_city": [32, 32, 32],
    "common_call_hour": [12, 12, 12],
    ...
    "curwin_pkvalue": [0.8, 0.9, 0.9],
    "curwin_pktime": [0.0, 1.5, 1.5],
    "curwin_cp_id": [1373, 1219, 1219],
    "curwin_lumian_dis": [500, 100, 100],
    ...
    "curlose_pkvalue": [-1, 0.8, 0.5],
    "curlose_pktime": [-1, 0.0, 3.5],
    "curwin_cp_id": [-1, 1373, 1197],
    "curlose_lumian_dis": [-1, 500, 800],
    ...
}
```

## 2.3、特征列表

| 特征类型 <br> | 特征来源 <br> | 特征名 <br> | 特征含义 <br> |
| --- | --- | --- | --- |
| 必传项 <br> | 传入特征 <br> | order_id <br> | 城市ID <br> |
| roundnum <br> | 订单PK轮次 <br> |
| driver_id <br> | 当前胜者司机ID <br> |
| ==driver_id_3rd_part== <br> | 当前胜者三方司机ID <br> |
| lose_driver_id <br> | 当前败者司机ID <br> |
| lose\_==driver_id_3rd_part== <br> | 当前败者三方司机ID <br> |
| 共用特征 <br> | 传入特征 <br> | cur_pktime【需要建设】 <br> | 当前窗口时刻 <br> |
| order_waiting_period <br> | 订单等待时间 <br> |
| city <br> | 城市ID <br> |
| call_hour <br> | 呼叫时间（小时） <br> |
| flat <br> | 起点坐标纬度 <br> |
| flng <br> | 起点坐标经度 <br> |
| tlat <br> | 终点坐标纬度 <br> |
| tlng <br> | 终点坐标经度 <br> |
| start_dest_distance <br> | 订单距离 <br> |
| est_start_dest_dur <br> | 预估送驾时长 <br> |
| dufe特征 <br> | coord_start_temperature <br> | 起点坐标温度 <br> |
| coord_start_humidity <br> | 起点坐标湿度 <br> |
| coord_start_intensity <br> | 起点坐标降水强度 <br> |
| coord_start_skycon <br> | 起点坐标天气 <br> |
| coord_last_1min_start_empty_driver_cnt_kf <br> | 近1分钟起点坐标格子空车司机数 <br> |
| coord_last_1min_start_order_cnt_kf <br> | 近1分钟起点坐标格子发单数 <br> |
| coord_last_1min_start_1circle_empty_driver_cnt_kf <br> | 近1分钟起点坐标格子周围1圈格子空车司机数 <br> |
| coord_last_1min_start_1circle_order_cnt_kf <br> | 近1分钟起点坐标周围1圈格子发单数 <br> |
| coord_last_1min_start_2circle_empty_driver_cnt_kf <br> | 近1分钟起点坐标周围2圈格子空车司机数 <br> |
| coord_last_1min_start_2circle_order_cnt_kf <br> | 近1分钟起点坐标周围2圈格子发单数 <br> |
| coord_last_1min_end_empty_driver_cnt_kf <br> | 近1分钟终点坐标格子空车司机数 <br> |
| coord_last_1min_end_order_cnt_kf <br> | 近1分钟终点坐标格子发单数 <br> |
| coord_last_1min_end_1circle_empty_driver_cnt_kf <br> | 近1分钟终点坐标周围1圈格子空车司机数 <br> |
| coord_last_1min_end_1circle_order_cnt_kf <br> | 近1分钟终点坐标周围1圈格子发单数 <br> |
| coord_last_1min_end_2circle_empty_driver_cnt_kf <br> | 近1分钟终点坐标周围2圈格子空车司机数 <br> |
| coord_last_1min_end_2circle_order_cnt_kf <br> | 近1分钟终点坐标周围2圈格子发单数 <br> |
| coord_last_5min_start_empty_driver_cnt_kf <br> | 近5分钟起点坐标格子空车司机数 <br> |
| coord_last_5min_start_order_cnt_kf <br> | 近5分钟起点坐标格子发单数 <br> |
| coord_last_5min_start_1circle_empty_driver_cnt_kf <br> | 近5分钟起点坐标格子周围1圈格子空车司机数 <br> |
| coord_last_5min_start_1circle_order_cnt_kf <br> | 近5分钟起点坐标周围1圈格子发单数 <br> |
| coord_last_5min_start_2circle_empty_driver_cnt_kf <br> | 近5分钟起点坐标周围2圈格子空车司机数 <br> |
| coord_last_5min_start_2circle_order_cnt_kf <br> | 近5分钟起点坐标周围2圈格子发单数 <br> |
| coord_last_5min_end_empty_driver_cnt_kf <br> | 近5分钟终点坐标格子空车司机数 <br> |
| coord_last_5min_end_order_cnt_kf <br> | 近5分钟终点坐标格子发单数 <br> |
| coord_last_5min_end_1circle_empty_driver_cnt_kf <br> | 近5分钟终点坐标周围1圈格子空车司机数 <br> |
| coord_last_5min_end_1circle_order_cnt_kf <br> | 近5分钟终点坐标周围1圈格子发单数 <br> |
| coord_last_5min_end_2circle_empty_driver_cnt_kf <br> | 近5分钟终点坐标周围2圈格子空车司机数 <br> |
| coord_last_5min_end_2circle_order_cnt_kf <br> | 近5分钟终点坐标周围2圈格子发单数 <br> |
| passenger_ziying_answered_pas_cancel_cnt_7d <br> | 近7天乘客自营运力应答后取消数 <br> |
| passenger_ziying_answered_pas_cancel_cnt_14d <br> | 近14天乘客自营运力应答后取消数 <br> |
| passenger_ziying_answered_pas_cancel_cnt_28d <br> | 近28天乘客自营运力应答后取消数 <br> |
| passenger_ziying_pas_answered_pas_cancel_rate_14d <br> | 近14天乘客自营运力应答后取消率 <br> |
| passenger_ziying_pas_answered_pas_cancel_rate_28d <br> | 近28天乘客自营运力应答后取消率 <br> |
| passenger_ziying_finish_rate_14d <br> | 近14天乘客自营运力完单率 <br> |
| passenger_ziying_finish_rate_28d <br> | 近28天乘客自营运力完单率 <br> |
| passenger_ziying_avg_start_dest_dis_28d <br> | 近28天乘客自营运力平均订单距离 <br> |
| passenger_sanfang_answered_pas_cancel_cnt_7d <br> | 近7天乘客三方运力应答后取消数 <br> |
| passenger_sanfang_answered_pas_cancel_cnt_14d <br> | 近14天乘客三方运力应答后取消数 <br> |
| passenger_sanfang_answered_pas_cancel_cnt_28d <br> | 近28天乘客三方运力应答后取消数 <br> |
| passenger_sanfang_pas_answered_pas_cancel_rate_14d <br> | 近14天乘客三方运力应答后取消率 <br> |
| passenger_sanfang_pas_answered_pas_cancel_rate_28d <br> | 近28天乘客三方运力应答后取消率 <br> |
| passenger_sanfang_finish_rate_14d <br> | 近14天乘客三方运力完单率 <br> |
| passenger_sanfang_finish_rate_28d <br> | 近28天乘客三方运力完单率 <br> |
| passenger_sanfang_avg_start_dest_dis_28d <br> | 近28天乘客三方运力平均订单距离 <br> |
| 当前胜者特征 <br> | 传入特征 <br> | pkvalue【需要建设】 <br> | 倾斜后PK打分 <br> |
| enter_pktime【需要建设】 <br> | 进入PK时刻 <br> |
| cp_id <br> | 商家ID <br> |
| serial_type <br> | 是否连环派 <br> |
| isfromdidi <br> | 是否滴滴司机 <br> |
| is_honghu_driver <br> | 是否自营或宏鹄司机 <br> |
| is_compliance <br> | 是否合规司机 <br> |
| is_grab_from_cyborg <br> | 是否选单举手 <br> |
| lumian_dis <br> | 接驾距离 <br> |
| eta <br> | 预估接驾时长 <br> |
| left_lumian_distance <br> | 连环派AB段距离 <br> |
| left_lumian_eta <br> | 连环派预估AB段时长 <br> |
| dropoff_order_distance <br> | 连环派BC段距离 <br> |
| dropoff_order_eta <br> | 连环派预估BC段时长 <br> |
| pre_total_fee <br> | 预估总费用 <br> |
| dufe特征 <br> | driver_order_finished_1h_cnt <br> | 近1小时司机完单数 <br> |
| driver_order_finished_2h_cnt <br> | 近2小时司机完单数 <br> |
| driver_order_finished_1d_cnt <br> | 当天司机完单数 <br> |
| driver_order_refused_1h_cnt <br> | 近1小时司机拒单数 <br> |
| driver_order_refused_2h_cnt <br> | 近2小时司机拒单数 <br> |
| driver_order_refused_1d_cnt <br> | 当天司机拒单数 <br> |
| driver_order_answer_1h_cnt <br> | 近1小时司机应答数 <br> |
| driver_order_answer_2h_cnt <br> | 近2小时司机应答数 <br> |
| driver_order_answer_1d_cnt <br> | 当天司机应答数 <br> |
| driver_answer_after_p_cancel_1h_cnt <br> | 近1小时司机被乘客取消数 <br> |
| driver_answer_after_p_cancel_2h_cnt <br> | 近2小时司机被乘客取消数 <br> |
| driver_answer_after_p_cancel_1d_cnt <br> | 当天司机被乘客取消数 <br> |
| driver_answer_after_d_cancel_1h_cnt <br> | 近1小时司机取消数 <br> |
| driver_answer_after_d_cancel_2h_cnt <br> | 近2小时司机取消数 <br> |
| driver_answer_after_d_cancel_1d_cnt <br> | 当天司机取消数 <br> |
| driver_online_1h_cnt <br> | 近1小时司机在线时长 <br> |
| driver_online_2h_cnt <br> | 近2小时司机在线时长 <br> |
| driver_online_1d_cnt <br> | 当天司机在线时长 <br> |
| driver_charging_1h_cnt <br> | 近1小时司机计费时长 <br> |
| driver_charging_2h_cnt <br> | 近2小时司机计费时长 <br> |
| driver_charging_1d_cnt <br> | 当天司机计费时长 <br> |
| driver_order_broadcast_1h_cnt <br> | 近1小时司机播单数 <br> |
| driver_order_broadcast_2h_cnt <br> | 近2小时司机播单数 <br> |
| driver_order_broadcast_1d_cnt <br> | 当天司机播单数 <br> |
| d_serial_refuse_cnt_1d <br> | 近1天司机连环派拒单数 <br> |
| d_serial_refuse_cnt_3d <br> | 近3天司机连环派拒单数 <br> |
| d_serial_refuse_cnt_7d <br> | 近7天司机连环派拒单数 <br> |
| d_serial_refuse_cnt_14d <br> | 近14天司机连环派拒单数 <br> |
| d_serial_refuse_cnt_28d <br> | 近28天司机连环派拒单数 <br> |
| d_serial_answer_cnt_1d <br> | 近1天司机连环派应答数 <br> |
| d_serial_answer_cnt_3d <br> | 近3天司机连环派应答数 <br> |
| d_serial_answer_cnt_7d <br> | 近7天司机连环派应答数 <br> |
| d_serial_answer_cnt_14d <br> | 近14天司机连环派应答数 <br> |
| d_serial_answer_cnt_28d <br> | 近28天司机连环派应答数 <br> |
| d_serial_reassign_cnt_1d <br> | 近1天司机连环派取消改派数 <br> |
| d_serial_reassign_cnt_3d <br> | 近3天司机连环派取消改派数 <br> |
| d_serial_reassign_cnt_7d <br> | 近7天司机连环派取消改派数 <br> |
| d_serial_reassign_cnt_14d <br> | 近14天司机连环派取消改派数 <br> |
| d_serial_reassign_cnt_28d <br> | 近28天司机连环派取消改派数 <br> |
| d_serial_dri_cancel_cnt_1d <br> | 近1天司机连环派取消数 <br> |
| d_serial_dri_cancel_cnt_3d <br> | 近3天司机连环派取消数 <br> |
| d_serial_dri_cancel_cnt_7d <br> | 近7天司机连环派取消数 <br> |
| d_serial_dri_cancel_cnt_14d <br> | 近14天司机连环派取消数 <br> |
| d_serial_dri_cancel_cnt_28d <br> | 近28天司机连环派取消数 <br> |
| d_serial_pas_cancel_cnt_1d <br> | 近1天司机连环派被乘客取消数 <br> |
| d_serial_pas_cancel_cnt_3d <br> | 近3天司机连环派被乘客取消数 <br> |
| d_serial_pas_cancel_cnt_7d <br> | 近7天司机连环派被乘客取消数 <br> |
| d_serial_pas_cancel_cnt_14d <br> | 近14天司机连环派被乘客取消数 <br> |
| d_serial_pas_cancel_cnt_28d <br> | 近28天司机连环派被乘客取消数 <br> |
| d_serial_close_cnt_1d <br> | 近1天司机连环派被客服关单数 <br> |
| d_serial_close_cnt_3d <br> | 近3天司机连环派被客服关单数 <br> |
| d_serial_close_cnt_7d <br> | 近7天司机连环派被客服关单数 <br> |
| d_serial_close_cnt_14d <br> | 近14天司机连环派被客服关单数 <br> |
| d_serial_close_cnt_28d <br> | 近28天司机连环派被客服关单数 <br> |
| d_serial_finish_cnt_1d <br> | 近1天司机连环派完单数 <br> |
| d_serial_finish_cnt_3d <br> | 近3天司机连环派完单数 <br> |
| d_serial_finish_cnt_7d <br> | 近7天司机连环派完单数 <br> |
| d_serial_finish_cnt_14d <br> | 近14天司机连环派完单数 <br> |
| d_serial_finish_cnt_28d <br> | 近28天司机连环派完单数 <br> |
| d_nonserial_refuse_cnt_1d <br> | 近1天司机非连环派拒单数 <br> |
| d_nonserial_refuse_cnt_3d <br> | 近3天司机非连环派拒单数 <br> |
| d_nonserial_refuse_cnt_7d <br> | 近7天司机非连环派拒单数 <br> |
| d_nonserial_refuse_cnt_14d <br> | 近14天司机非连环派拒单数 <br> |
| d_nonserial_refuse_cnt_28d <br> | 近28天司机非连环派拒单数 <br> |
| d_nonserial_answer_cnt_1d <br> | 近1天司机非连环派应答数 <br> |
| d_nonserial_answer_cnt_3d <br> | 近3天司机非连环派应答数 <br> |
| d_nonserial_answer_cnt_7d <br> | 近7天司机非连环派应答数 <br> |
| d_nonserial_answer_cnt_14d <br> | 近14天司机非连环派应答数 <br> |
| d_nonserial_answer_cnt_28d <br> | 近28天司机非连环派应答数 <br> |
| d_nonserial_reassign_cnt_1d <br> | 近1天司机非连环派取消改派数 <br> |
| d_nonserial_reassign_cnt_3d <br> | 近3天司机非连环派取消改派数 <br> |
| d_nonserial_reassign_cnt_7d <br> | 近7天司机非连环派取消改派数 <br> |
| d_nonserial_reassign_cnt_14d <br> | 近14天司机非连环派取消改派数 <br> |
| d_nonserial_reassign_cnt_28d <br> | 近28天司机非连环派取消改派数 <br> |
| d_nonserial_dri_cancel_cnt_1d <br> | 近1天司机非连环派取消数 <br> |
| d_nonserial_dri_cancel_cnt_3d <br> | 近3天司机非连环派取消数 <br> |
| d_nonserial_dri_cancel_cnt_7d <br> | 近7天司机非连环派取消数 <br> |
| d_nonserial_dri_cancel_cnt_14d <br> | 近14天司机非连环派取消数 <br> |
| d_nonserial_dri_cancel_cnt_28d <br> | 近28天司机非连环派取消数 <br> |
| d_nonserial_pas_cancel_cnt_1d <br> | 近1天司机非连环派被乘客取消数 <br> |
| d_nonserial_pas_cancel_cnt_3d <br> | 近3天司机非连环派被乘客取消数 <br> |
| d_nonserial_pas_cancel_cnt_7d <br> | 近7天司机非连环派被乘客取消数 <br> |
| d_nonserial_pas_cancel_cnt_14d <br> | 近14天司机非连环派被乘客取消数 <br> |
| d_nonserial_pas_cancel_cnt_28d <br> | 近28天司机非连环派被乘客取消数 <br> |
| d_nonserial_close_cnt_1d <br> | 近1天司机非连环派被客服关单数 <br> |
| d_nonserial_close_cnt_3d <br> | 近3天司机非连环派被客服关单数 <br> |
| d_nonserial_close_cnt_7d <br> | 近7天司机非连环派被客服关单数 <br> |
| d_nonserial_close_cnt_14d <br> | 近14天司机非连环派被客服关单数 <br> |
| d_nonserial_close_cnt_28d <br> | 近28天司机非连环派被客服关单数 <br> |
| d_nonserial_finish_cnt_1d <br> | 近1天司机非连环派完单数 <br> |
| d_nonserial_finish_cnt_3d <br> | 近3天司机非连环派完单数 <br> |
| d_nonserial_finish_cnt_7d <br> | 近7天司机非连环派完单数 <br> |
| d_nonserial_finish_cnt_14d <br> | 近14天司机非连环派完单数 <br> |
| d_nonserial_finish_cnt_28d <br> | 近28天司机非连环派完单数 <br> |
| 当前败者特征 <br> | 传入特征 <br> | lose_pkvalue【需要建设】 <br> | 倾斜后PK打分 <br> |
| lose\_enter_pktime【需要建设】 <br> | 进入PK时刻 <br> |
| lose_cp_id <br> | 商家ID <br> |
| lose_serial_type <br> | 是否连环派 <br> |
| lose_isfromdidi <br> | 是否滴滴司机 <br> |
| lose_is_honghu_driver <br> | 是否自营或宏鹄司机 <br> |
| lose_is_compliance <br> | 是否合规司机 <br> |
| lose_is_grab_from_cyborg <br> | 是否选单举手 <br> |
| lose_lumian_dis <br> | 接驾距离 <br> |
| lose_eta <br> | 预估接驾时长 <br> |
| lose_left_lumian_distance <br> | 连环派AB段距离 <br> |
| lose_left_lumian_eta <br> | 连环派预估AB段时长 <br> |
| lose_dropoff_order_distance <br> | 连环派BC段距离 <br> |
| lose_dropoff_order_eta <br> | 连环派预估BC段时长 <br> |
| lose_pre_total_fee <br> | 预估总费用 <br> |
| dufe特征 <br> | lose_driver_order_finished_1h_cnt <br> | 近1小时司机完单数 <br> |
| lose_driver_order_finished_2h_cnt <br> | 近2小时司机完单数 <br> |
| lose_driver_order_finished_1d_cnt <br> | 当天司机完单数 <br> |
| lose_driver_order_refused_1h_cnt <br> | 近1小时司机拒单数 <br> |
| lose_driver_order_refused_2h_cnt <br> | 近2小时司机拒单数 <br> |
| lose_driver_order_refused_1d_cnt <br> | 当天司机拒单数 <br> |
| lose_driver_order_answer_1h_cnt <br> | 近1小时司机应答数 <br> |
| lose_driver_order_answer_2h_cnt <br> | 近2小时司机应答数 <br> |
| lose_driver_order_answer_1d_cnt <br> | 当天司机应答数 <br> |
| lose_driver_answer_after_p_cancel_1h_cnt <br> | 近1小时司机被乘客取消数 <br> |
| lose_driver_answer_after_p_cancel_2h_cnt <br> | 近2小时司机被乘客取消数 <br> |
| lose_driver_answer_after_p_cancel_1d_cnt <br> | 当天司机被乘客取消数 <br> |
| lose_driver_answer_after_d_cancel_1h_cnt <br> | 近1小时司机取消数 <br> |
| lose_driver_answer_after_d_cancel_2h_cnt <br> | 近2小时司机取消数 <br> |
| lose_driver_answer_after_d_cancel_1d_cnt <br> | 当天司机取消数 <br> |
| lose_driver_online_1h_cnt <br> | 近1小时司机在线时长 <br> |
| lose_driver_online_2h_cnt <br> | 近2小时司机在线时长 <br> |
| lose_driver_online_1d_cnt <br> | 当天司机在线时长 <br> |
| lose_driver_charging_1h_cnt <br> | 近1小时司机计费时长 <br> |
| lose_driver_charging_2h_cnt <br> | 近2小时司机计费时长 <br> |
| lose_driver_charging_1d_cnt <br> | 当天司机计费时长 <br> |
| lose_driver_order_broadcast_1h_cnt <br> | 近1小时司机播单数 <br> |
| lose_driver_order_broadcast_2h_cnt <br> | 近2小时司机播单数 <br> |
| lose_driver_order_broadcast_1d_cnt <br> | 当天司机播单数 <br> |
| lose_d_serial_refuse_cnt_1d <br> | 近1天司机连环派拒单数 <br> |
| lose_d_serial_refuse_cnt_3d <br> | 近3天司机连环派拒单数 <br> |
| lose_d_serial_refuse_cnt_7d <br> | 近7天司机连环派拒单数 <br> |
| lose_d_serial_refuse_cnt_14d <br> | 近14天司机连环派拒单数 <br> |
| lose_d_serial_refuse_cnt_28d <br> | 近28天司机连环派拒单数 <br> |
| lose_d_serial_answer_cnt_1d <br> | 近1天司机连环派应答数 <br> |
| lose_d_serial_answer_cnt_3d <br> | 近3天司机连环派应答数 <br> |
| lose_d_serial_answer_cnt_7d <br> | 近7天司机连环派应答数 <br> |
| lose_d_serial_answer_cnt_14d <br> | 近14天司机连环派应答数 <br> |
| lose_d_serial_answer_cnt_28d <br> | 近28天司机连环派应答数 <br> |
| lose_d_serial_reassign_cnt_1d <br> | 近1天司机连环派取消改派数 <br> |
| lose_d_serial_reassign_cnt_3d <br> | 近3天司机连环派取消改派数 <br> |
| lose_d_serial_reassign_cnt_7d <br> | 近7天司机连环派取消改派数 <br> |
| lose_d_serial_reassign_cnt_14d <br> | 近14天司机连环派取消改派数 <br> |
| lose_d_serial_reassign_cnt_28d <br> | 近28天司机连环派取消改派数 <br> |
| lose_d_serial_dri_cancel_cnt_1d <br> | 近1天司机连环派取消数 <br> |
| lose_d_serial_dri_cancel_cnt_3d <br> | 近3天司机连环派取消数 <br> |
| lose_d_serial_dri_cancel_cnt_7d <br> | 近7天司机连环派取消数 <br> |
| lose_d_serial_dri_cancel_cnt_14d <br> | 近14天司机连环派取消数 <br> |
| lose_d_serial_dri_cancel_cnt_28d <br> | 近28天司机连环派取消数 <br> |
| lose_d_serial_pas_cancel_cnt_1d <br> | 近1天司机连环派被乘客取消数 <br> |
| lose_d_serial_pas_cancel_cnt_3d <br> | 近3天司机连环派被乘客取消数 <br> |
| lose_d_serial_pas_cancel_cnt_7d <br> | 近7天司机连环派被乘客取消数 <br> |
| lose_d_serial_pas_cancel_cnt_14d <br> | 近14天司机连环派被乘客取消数 <br> |
| lose_d_serial_pas_cancel_cnt_28d <br> | 近28天司机连环派被乘客取消数 <br> |
| lose_d_serial_close_cnt_1d <br> | 近1天司机连环派被客服关单数 <br> |
| lose_d_serial_close_cnt_3d <br> | 近3天司机连环派被客服关单数 <br> |
| lose_d_serial_close_cnt_7d <br> | 近7天司机连环派被客服关单数 <br> |
| lose_d_serial_close_cnt_14d <br> | 近14天司机连环派被客服关单数 <br> |
| lose_d_serial_close_cnt_28d <br> | 近28天司机连环派被客服关单数 <br> |
| lose_d_serial_finish_cnt_1d <br> | 近1天司机连环派完单数 <br> |
| lose_d_serial_finish_cnt_3d <br> | 近3天司机连环派完单数 <br> |
| lose_d_serial_finish_cnt_7d <br> | 近7天司机连环派完单数 <br> |
| lose_d_serial_finish_cnt_14d <br> | 近14天司机连环派完单数 <br> |
| lose_d_serial_finish_cnt_28d <br> | 近28天司机连环派完单数 <br> |
| lose_d_nonserial_refuse_cnt_1d <br> | 近1天司机非连环派拒单数 <br> |
| lose_d_nonserial_refuse_cnt_3d <br> | 近3天司机非连环派拒单数 <br> |
| lose_d_nonserial_refuse_cnt_7d <br> | 近7天司机非连环派拒单数 <br> |
| lose_d_nonserial_refuse_cnt_14d <br> | 近14天司机非连环派拒单数 <br> |
| lose_d_nonserial_refuse_cnt_28d <br> | 近28天司机非连环派拒单数 <br> |
| lose_d_nonserial_answer_cnt_1d <br> | 近1天司机非连环派应答数 <br> |
| lose_d_nonserial_answer_cnt_3d <br> | 近3天司机非连环派应答数 <br> |
| lose_d_nonserial_answer_cnt_7d <br> | 近7天司机非连环派应答数 <br> |
| lose_d_nonserial_answer_cnt_14d <br> | 近14天司机非连环派应答数 <br> |
| lose_d_nonserial_answer_cnt_28d <br> | 近28天司机非连环派应答数 <br> |
| lose_d_nonserial_reassign_cnt_1d <br> | 近1天司机非连环派取消改派数 <br> |
| lose_d_nonserial_reassign_cnt_3d <br> | 近3天司机非连环派取消改派数 <br> |
| lose_d_nonserial_reassign_cnt_7d <br> | 近7天司机非连环派取消改派数 <br> |
| lose_d_nonserial_reassign_cnt_14d <br> | 近14天司机非连环派取消改派数 <br> |
| lose_d_nonserial_reassign_cnt_28d <br> | 近28天司机非连环派取消改派数 <br> |
| lose_d_nonserial_dri_cancel_cnt_1d <br> | 近1天司机非连环派取消数 <br> |
| lose_d_nonserial_dri_cancel_cnt_3d <br> | 近3天司机非连环派取消数 <br> |
| lose_d_nonserial_dri_cancel_cnt_7d <br> | 近7天司机非连环派取消数 <br> |
| lose_d_nonserial_dri_cancel_cnt_14d <br> | 近14天司机非连环派取消数 <br> |
| lose_d_nonserial_dri_cancel_cnt_28d <br> | 近28天司机非连环派取消数 <br> |
| lose_d_nonserial_pas_cancel_cnt_1d <br> | 近1天司机非连环派被乘客取消数 <br> |
| lose_d_nonserial_pas_cancel_cnt_3d <br> | 近3天司机非连环派被乘客取消数 <br> |
| lose_d_nonserial_pas_cancel_cnt_7d <br> | 近7天司机非连环派被乘客取消数 <br> |
| lose_d_nonserial_pas_cancel_cnt_14d <br> | 近14天司机非连环派被乘客取消数 <br> |
| lose_d_nonserial_pas_cancel_cnt_28d <br> | 近28天司机非连环派被乘客取消数 <br> |
| lose_d_nonserial_close_cnt_1d <br> | 近1天司机非连环派被客服关单数 <br> |
| lose_d_nonserial_close_cnt_3d <br> | 近3天司机非连环派被客服关单数 <br> |
| lose_d_nonserial_close_cnt_7d <br> | 近7天司机非连环派被客服关单数 <br> |
| lose_d_nonserial_close_cnt_14d <br> | 近14天司机非连环派被客服关单数 <br> |
| lose_d_nonserial_close_cnt_28d <br> | 近28天司机非连环派被客服关单数 <br> |
| lose_d_nonserial_finish_cnt_1d <br> | 近1天司机非连环派完单数 <br> |
| lose_d_nonserial_finish_cnt_3d <br> | 近3天司机非连环派完单数 <br> |
| lose_d_nonserial_finish_cnt_7d <br> | 近7天司机非连环派完单数 <br> |
| lose_d_nonserial_finish_cnt_14d <br> | 近14天司机非连环派完单数 <br> |
| lose_d_nonserial_finish_cnt_28d <br> | 近28天司机非连环派完单数 <br> |

## 2.4、DQN算法

DQN算法是基于价值的强化学习算法，核心目标是学习状态-动作价值函数$$Q(s,a)$$，用于估计在状态$$s$$下执行动作$$a$$之后能获得的期望累计奖励

| 概念 <br> | 含义 <br> |
| --- | --- |
| Q网络 <br> | DQN算法依赖主网络与目标网络组成的双网络结构来拟合Q值函数$$Q(s,a)$$ <br>主网络的输入是状态$$s$$，输出为该状态下所有动作的Q值（维度等于动作空间$$|A|$$），持续更新以逼近最优Q值 <br>目标网络的参数定期同步主网络的参数，输入同样是状态$$s$$，用于稳定计算目标Q值$$r+\gamma \max_{a^{\prime}\in A}Q(s^{\prime},a^{\prime})$$，避免训练震荡 <br> |
| 经验回放 <br> | 维护一个回放缓冲区，将与环境交互在线采集的四元组数据$$(s_i,a_i,r_i,s_{i^\prime})$$存储到回放缓冲区中 <br>训练Q网络时，再从回放缓冲区中离线随机采样若干数据进行训练，使样本满足独立假设，同时提高样本效率 <br> |
| ==优化目标== <br> | ==继承==Q-learning算法的时序差分更新方式，但通过目标网络解耦目标Q值与主网络的参数  <br>$$Q(s,a;\theta) \leftarrow Q(s,a;\theta)+ \alpha[r+\gamma \max_{a^{\prime}\in A}Q(s^{\prime},a^{\prime};\theta^-)-Q(s,a;\theta)]$$ <br>其中$$\theta$$为主网络参数，$$\theta^-$$为定期同步$$\theta$$的目标网络参数 <br> |
| 损失函数 <br> | 构造使$$Q(s,a)$$和时序差分目标尽可能接近的均方误差损失函数 <br>$$L=\sum_i[Q_\omega(s_i,a_i)-(r_i+\gamma \max_{a^{\prime}\in A}Q(s_i,a^{\prime}))]^2/N$$ <br> |
| $$\epsilon$$-贪婪策略 <br> | 基于“探索-利用”平衡原则采集交互数据 <br>$$\pi(a|s) =  \begin{cases}  \epsilon / |A| + 1 - \epsilon, &  a = \arg\max\limits_{a'} Q(s, a'), \\ \epsilon / |A|, & a \neq \arg\max\limits_{a'} Q(s, a'). \end{cases}$$ <br>其中$$\epsilon$$为探索率，策略以$$1-\epsilon$$概率选择状态下Q值最大的动作（利用已知最优），以$$\epsilon$$概率随机选择动作（探索潜在更优策略） <br> |

> 2.4、PPO算法

> PPO算法是基于策略的强化学习方法，这类方法依赖策略网络（Actor）$$\theta$$和价值网络（Critic）$$\omega$$决策最优动作

> 两个网络的输入都是某个状态$$s$$，策略网络输出该状态下的动作概率分布$$\pi_\theta(a|s)$$，价值网络输出该==状态的价值==$$V_\omega(s)$$

> PPO-截断算法继承TRPO算法的思想，利用旧策略$$\pi_{\theta_\text{old}}$$采样的数据来优化新策略$$\pi_\theta$$，同时保证新旧策略的距离足够接近

> 策略网络的优化目标为$$max_\theta \mathbb{E_t} \left[ \min \left( p_t(\theta)\hat{A_t}, \text{clip}(p_t(\theta), 1 - \epsilon, 1 + \epsilon) \hat{A_t} \right) \right]$$，其中$$p_t(\theta)=\frac{\pi_\theta(a_t|s_t)}{\pi_{\theta_\text{old}}(a_t|s_t)}$$是重要性采样比率，$$\hat{A_t}=A^{\pi_{\theta_\text{old}}}(s_t,a_t)$$是优势函数估计值

> 价值网络的优化目标为$$\min_\omega \mathbb{E_t} \left[ (V_\omega(s_t) - \hat{V_t}) ^ 2 \right]$$，其中$$\hat{V_t}=r_t+\gamma^{t^\prime-t}V_\omega(s_{t^\prime})$$是目标价值，$$t^\prime-t$$是相邻司机的举手时间差

## 2.5、策略学习

DQN算法采用离线策略（off-policy）的方式进行训练，需要持续更新离线模型，然后进行线上小流量探索

![](https://s3-ep-inter.didistatic.com/didoc-upload-image-prod/17509287041425dab468d30f8b66589328d08f3038fd4/image.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKDD00000000000EBLCTZNRBJHX6ZS%2F20260526%2Fgzep%2Fs3%2Faws4_request&X-Amz-Date=20260526T075943Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=1da85c4a3f7cbc5e81391dc98691f89c88872df777741a99f68739e42bf5c24d)

## 2.6、离线效果

损失函数：训练集和测试集的损失都稳定下降

![](https://s3-ep-inter.didistatic.com/didoc-upload-image-prod/1751369347465d2597fc5a62c5fceed075794cb3f7b4e/image.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKDD00000000000EBLCTZNRBJHX6ZS%2F20260526%2Fgzep%2Fs3%2Faws4_request&X-Amz-Date=20260526T075943Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=0b75d3b57df3b8cc3018d580f94cc817b99dcde25fba52c21ea23de912a094db)

动作分布：特殊情况的提前结束动作占比均符合预期

| 案例 <br> | 样本占比 <br> | DQN提前结束占比 <br> |
| --- | --- | --- |
| 窗口只有1个司机，提前结束，完单 <br> | 15.2% <br> | 74.1% <br> |
| 窗口只有1个司机，提前结束，没有完单 <br> | 5.3% <br> | 57.9% <br> |
| 窗口只有1个司机，没有提前结束，完单 <br> | 17.4% <br> | 72.5% <br> |
| 窗口只有1个司机，没有提前结束，没有完单 <br> | 8.4% <br> | 64.0% <br> |

# 3、工程部分

## 3.1、链路改造

1. 临时结果传入：动态窗口策略的DQN模型依赖当前时刻的PK结果，需要获取当前时刻胜出和失败司机的PK打分和所有特征

- dufe特征：需要改造EVE的调用逻辑，依赖两个key调用两套司机维度的特征，分别对应当前胜出和失败的司机id

- 传入特征：根据当前胜出和失败的司机，工程传入两套特征，根据胜出或失败加特征前缀curwin或curlose，例如curwin_cp_id和curlose_cp_id

2. 随机动作探索：调用DQN模型返回继续和结束窗口的动作价值$$[Q(s,a=0),Q(s,a=1)]$$，然后以$$1-\epsilon$$的概率选择动作价值最大的动作，以$$\epsilon$$的概率随机选择动作

- $$\epsilon$$-贪婪策略的实现逻辑可能无法内置在模型中，需要工程开发实现，要求$$\epsilon$$值可配置

![](https://s3-ep-inter.didistatic.com/didoc-upload-image-prod/17509202763116c6b2f2e67549d65e89aa881b5515fd6/image.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKDD00000000000EBLCTZNRBJHX6ZS%2F20260526%2Fgzep%2Fs3%2Faws4_request&X-Amz-Date=20260526T075943Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=647c944cd6953d0b901846ac676f96addd6e73ffa4a2b0007315148a978db162)

## 3.2、特征建设

对于每个举手的司机，新增3个（套）传入特征

| 特征 <br> | 含义 <br> | 示例 <br> |
| --- | --- | --- |
| cur_pktime <br> | 每次触发PK时，返回当前PK窗口时刻，单位为秒，精度为毫秒 <br> | 司机1举手，pktime=0.000 <br>司机2举手，pktime=1.234 <br>司机3举手，pktime=2.345 <br> |
| enter_pktime <br> | 每次触发PK时，返回司机进入窗口的时刻，单位为秒，精度为毫秒 <br> | 司机1举手，enter_pktime=0.000 <br>司机2举手，enter_pktime=1.234，lose\_enter_pktime=0.000（司机2战胜司机1） <br>司机3举手，enter_pktime=1.234，lose\_enter_pktime=2.345（司机3负于司机2） <br> |
| pkvalue <br> | 每次触发PK时，返回司机的倾斜后PK打分，取值范围0～1 <br> | 司机1举手，pkvalue=0.123 <br>司机2举手，pkvalue=0.789，lose_pkvalue=0.123（司机2战胜司机1） <br>司机3举手，pkvalue=0.789，lose_pkvalue=0.456（司机3负于司机2） <br> |

## 3.3、日志采集

在PK司机举手日志表中，新增两个字段

| 字段 <br> | 含义 <br> | 示例 <br> |
| --- | --- | --- |
| qsa_list <br> | 调用DQN模型的返回值，代表继续和结束窗口的动作价值 <br> | 司机1举手，qsa_list=\[0.5, 0.4\] <br>司机2举手，qsa_list=\[0.1, 0.2\] <br>司机3举手，qsa_list=\[0.3, 0.8\] <br> |
| stop_action <br> | 根据qsa_list和$$\epsilon$$-贪婪策略决策的是否提前结束窗口 <br> | 司机1举手，stop_action=0 <br>司机2举手，stop_action=0 <br>司机3举手，stop_action=1 <br> |

# 4、自动化迭代

上线强化学习策略后，保持N天/次的自动化迭代频率，持续一段时间直至手动停止，不涉及模型评估和推全决策的操作

1. 【策略】模型训练：在EVE平台上，设置自动调度的周期性任务，搭建对前N天实验组样本的数据处理和模型训练链路

2. 【工程】模型部署：定时读取周期性任务产出的模型，关联自动化的模型部署服务，创建模型新版本并完成模型部署

3. 【工程】实验配置：在实验城市进行乘客分流，更换随机数种子重新切a%的小流量作实验组，用新模型版本替换旧模型版本，同步创建评估大师

![](https://s3-ep-inter.didistatic.com/didoc-upload-image-prod/17527383775208215a2ca9b00b08a1eea85d5c9f50ab0/image.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKDD00000000000EBLCTZNRBJHX6ZS%2F20260526%2Fgzep%2Fs3%2Faws4_request&X-Amz-Date=20260526T075943Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=edce5de26947102424bbc6d4cb3af89755992a1ff74fd11ea3c39a209debfbc9)
