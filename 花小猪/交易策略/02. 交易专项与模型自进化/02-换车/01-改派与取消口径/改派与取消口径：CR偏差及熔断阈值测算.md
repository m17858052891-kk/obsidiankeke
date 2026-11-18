---
title: "改派与取消口径：CR偏差及熔断阈值测算"
type: "主题整理"
cssclasses: ["strategy-body-note"]
sources:
  - https://cooper.didichuxing.com/knowledge/2199610335356/2206322000172
  - https://cooper.didichuxing.com/knowledge/2199610335356/2203756265493
aliases:
  - "CR熔断策略改派订单分析"
  - "新增应答后取消数据熔断阈值测算"
---

# 改派与取消口径：CR偏差及熔断阈值测算

先看改派链路怎样影响取消归因，再看用应答后取消率估计 CR 能否改善熔断判断。两份记录分别回答统计口径与策略效果问题。

## 先读这些

- **改派归因**：原单 A 改派为 B、再改派为 C 时，C 的取消难以追到 A 的呼叫时间。原测算中，忽略两次及以上改派后的取消，会使全天 CR 高估约 0.29pp、周一 7 点高峰高估约 0.40pp。
- **CR 估计**：2025-03-12 的阈值测算使用前一周数据，以 `CR = AR × (1 − 应答后取消率)` 估计并做时间片校准；该记录选择不含改派的取消率继续分析。
- **策略结果**：仅把城市熔断改为 `预估 CR < 0.6`，badcase 合计由 0.0573 升至 0.0840。原文建议在旧策略上增加识别“高 AR、低 CR”的约束，而非据此整体替换。
- **口径边界**：“忽略多次改派后的取消”与“取消率不含改派”并非同一过滤条件。SQL、分位数、图表和阈值定义分别保留，使用时按对应分析范围对照。

**分节阅读**　[[#多次改派取消的统计偏差|多次改派取消的统计偏差]] · [[#应答后取消与阈值测算|应答后取消与阈值测算]]

## 多次改派取消的统计偏差

**来源**：[CR熔断策略改派订单分析](https://cooper.didichuxing.com/knowledge/2199610335356/2206322000172)

### 1 背景

对于多次改派订单，工程难以追踪原始订单；如A订单，改派为B，再次改派为C，此时C订单的取消难以归因到A订单的呼叫时间

### 2 结论

在计算乘客取消数指标时，改派一次以上的订单（即C订单）的取消，不需要被计入，此时全天CR高估0.29pp，高峰CR高估0.40pp

### 3 分析数据

> [!example]- SQL 实现细节（80 行）
> ```SQL
> with order_info as (
>     select 
>         a.order_id as origin_order_id,
>         min(a.call_time) as first_call_time,
>         max(b.call_time) as last_call_time,
>         min(hour_of_day) as hour_of_day,
>         max(cancel_time) as cancel_time,
>         max(p_cancel) as p_cancel,
>         max(is_td_finish) as is_td_finish,
>         least(count(distinct b.order_id),3) as reassign_cnt
>     from 
>         (
>             select 
>                 order_id,
>                 min(call_time) as call_time,
>                 min(hour(call_time)) as hour_of_day
>             from 
>                 kflower_dw.dwd_kf_trd_unity_order_di
>             where 
>                 dt = '2025-12-15'
>                 and is_hxz = 1 
>                 and is_td_call = 1 
>                 and is_reassign <> 1
>             group by 
>                 order_id
>         ) a 
>         inner join 
>         (
>             select 
>                 order_id,
>                 coalesce(call_reassign_order_id, answer_reassign_order_id, order_id) as origin_order_id,
>                 call_time,
>                 cancel_time,
>                 (case 
>                     when (is_grab_before_cannel = 1 or is_grab_after_pas_cancel = 1) then 1 
>                     else 0 
>                 end) as p_cancel,
>                 is_td_finish
>             from 
>                 kflower_dw.dwd_kf_trd_unity_order_di
>             where 
>                 dt between '2025-12-15' and '2025-12-16'
>                 and is_hxz = 1
>         ) b on a.order_id = b.origin_order_id
>     group by 
>         a.order_id
>
> ),
>
> reassign_detail as (
>     select 
>         origin_order_id,
>         unix_timestamp(last_call_time) - unix_timestamp(first_call_time) as reassign_dur,
>         if(p_cancel = 1,unix_timestamp(cancel_time) - unix_timestamp(first_call_time),null) as cancel_dur,
>         p_cancel,
>         is_td_finish,
>         reassign_cnt
>     from 
>         order_info
>     where 
>         hour_of_day = 7
> )
>
> select 
>     reassign_cnt,
>     -- 用于计算真实cr
>     count(distinct origin_order_id) as order_cnt,
>     sum(p_cancel) as p_cancel_cnt,
>     sum(is_td_finish)/count(distinct origin_order_id) as real_cr,
>     1-sum(p_cancel)/count(distinct origin_order_id) as cal_cr,
>     -- 过滤改派3单以上的取消
>     count(distinct case when reassign_cnt > 2 then origin_order_id end) as reassign_2_order_cnt, 
>     sum(if(reassign_cnt<3 and cancel_dur < 300, p_cancel,0)) as filter_p_cancel_cnt,
>     1-sum(if(reassign_cnt<3 and cancel_dur < 300, p_cancel,0))/count(distinct origin_order_id) as filter_cr,
>     percentile_approx(reassign_dur, array(0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1)) as reassign_dur,
>     percentile_approx(cancel_dur, array(0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1)) as cancel_dur
> from 
>     reassign_detail
> group by 
>     reassign_cnt
> ```


全天统计数据

- 有0.8%的订单，改派1次以上

- 「改派1次以上」且「取消」的订单中，60%的订单取消时间<5分钟；若忽略改派1次以上的取消，CR高估0.8%\*62%\*60%=0.29pp

| 改派次数 | 订单数 | 乘客取消订单数 | 乘客取消率 | 改派时间分位数(s) | 取消订单取消时间分位数 |
| --- | --- | --- | --- | --- | --- |
| 0 | 4019229 | 702441 | 17.48% | \[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0\] | \[2, 20, 31, 46, 65, 87, 115, 154, 218, 344, 127603\] |
| 1 | 280979 | 136307 | 48.51% | \[1, 16, 22, 30, 36, 50, 73, 115, 187, 314, 101492\] | \[5, 39, 58, 82, 111, 149, 200, 265, 357, 522, 123753\] |
| 1以上 | 34858 | 21616 | 62.01% | \[9, 43, 57, 77, 104, 139, 188, 255, 354, 539, 78555\] | \[15, 74, 111, 149, 197, 250, 315, 401, 526, 744, 52573\] |

周一早高峰7点统计数据

- 有1.1%的订单，改派1次以上

- 「改派1次以上」且「取消」的订单中，60%的订单取消时间<5分钟；若忽略改派1次以上的取消，CR高估1.1%\*61.19%\*60%=0.40pp

| 改派次数 | 订单数 | 乘客取消订单数 | 乘客取消率 | 改派时间分位数(s) | 取消订单取消时间分位数 |
| --- | --- | --- | --- | --- | --- |
| 0 | 260228 | 80167 | 30.81% | \[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0\] | \[2, 22, 34, 50, 68, 90, 118, 158, 220, 340, 90855\] |
| 1 | 27874 | 14842 | 53.25% | \[2, 15, 23, 32, 37, 53, 74, 110, 174, 303, 10858\] | \[6, 38, 52, 72, 95, 124, 167, 229, 319, 484, 123753\] |
| 1以上 | 3272 | 2002 | 61.19% | \[11, 45, 59, 80, 105, 136, 180, 235, 330, 497, 2681\] | \[15, 78, 110, 143, 185, 231, 293, 371, 478, 692, 3963\] |

## 应答后取消与阈值测算

**来源**：[新增应答后取消数据熔断阈值测算](https://cooper.didichuxing.com/knowledge/2199610335356/2203756265493)

==新增数据口径：[https://cooper.didichuxing.com/knowledge/share/page/RLlywpjpud6F#](https://cooper.didichuxing.com/knowledge/share/page/RLlywpjpud6F#)《差供需场景SDS特征建设策略方案》==

**==测算方案：==**

- 基于应答后取消率：分为含改派和不含改派两种

- 基于开始计费数

- 基于动调预测应答率

**测算数据时间：**2025-03-12，2025-03-05 -- 2025-03-11作为过去一周的数据

从折现图来看，蓝线是基于开始计费数计算的CR，明显高于其他方式计算的CR以及真实CR，差距过大，暂时不做考虑

![](5a62ebe91d779184-image.png)

用应答后取消率计算CR的逻辑为：cr = ar \* (1 - cancel_rate)。基于这种方式，分别计算含改派和不含改派的应答后取消率计算CR。

蓝线：真实CR

黄线：不含改派取消率计算的CR

绿线：含改派取消率计算的CR

![](6874b12a573d5c6b-image.png)

从折现图看，黄线（不含改派取消率计算的CR）更贴合真实CR一些（后续曲线相似度计算可以考虑用MAE作为客观参考指标），后续分析会基于**不含改派取消率**计算。

### 基于应答后取消率预测CR

首先要基于应答后取消率预估cr，首先会统计过去一周每个时间片（5min一个）预测的CR和真实CR之间的gap，gap的均值作为校准值，加到当天的预估CR上，作为最终的CR，然后基于这个预估的CR，设定阈值，统计badcase率。

【**CR是否有校准对比**】

蓝线：校准后的CR

黄线：预估的CR

绿线：真实CR

可以看到，一般而言，校准之后的cr要比没有校准更贴合真实的CR（可以考虑计算两条线的MAE作为参考指标）

![](31b9ba662c3c307c-image.png)

【**基固定CR阈值判定是否熔断**】

 badcase定义：

1. 时间片平均CR高于0.70，熔断比例高于10%的时间片

2. 时间片平均CR低于0.50，熔断比例低于70%的时间片

策略介绍：

1）只修改城市熔断，格子熔断保持不变

2）如果预估的**CR<0.6**，则触发熔断，反之则不触发

对比原来的策略和新策略的badcase率

| | badcase1 | badcase2 | 合计 |
| --- | --- | --- | --- |
| 旧策略 | 0.0037 | 0.0536 | 0.0573 |
| 新策略 | 0.0578 | 0.0262 | 0.0840 |

新策略badcase1会显著变高，badcase2会显著降低，但是总的badcase率新策略会高于旧策略。

分析：

- 旧策略主要的问题在于，CR低的时候会有熔断比例过低的问题，这是由于旧策略基于AR判断，但是AR和CR会有差距导致的，所以，考虑只是简单额外增加一个约束来识别高AR低CR的场景就可以，而不需要基于应答后取消计算CR，然后根据CR判断这种方式。

- 第二种badcase是熔断比例不够，想要高比例触发熔断，主要依赖城市熔断，格子熔断可以考虑暂不做修改
