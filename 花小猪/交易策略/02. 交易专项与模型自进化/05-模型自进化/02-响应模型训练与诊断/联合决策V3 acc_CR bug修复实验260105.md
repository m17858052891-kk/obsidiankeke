---
title: "联合决策V3 acc_CR bug修复实验260105"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2206382975464
cssclasses: ["strategy-body-note"]
---

# 联合决策V3 acc_CR bug修复实验260105

**对照阅读**　[[acc_CR修复：负向分析与逐单验算|负向分析与逐单验算]]

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2206382975464)

**阅读定位**　[[#实验背景|实验背景]] · [[#实验结果记录|实验结果记录]] · [[#二期实验配置调整1.9|二期实验配置调整1.9]] · [[#二期实验结果记录|二期实验结果记录]]

## 实验背景

- 实验日期：2026.01.05开启

- 实验城市：全国

	- 5,6,8,9,12,13,14,15,16,19,22,24,25,26,29,32,33,34,35,38,42,44,50,58,60,74,81,83,85,86,125,133,134,153,157,160,254,1,2,3,4,7,10,11,17,18,20,21,23,27,28,30,36,37,39,40,41,43,45,46,47,48,49,51,52,53,54,55,56,57,59,61,62,63,64,65,66,67,68,69,70,71,72,73,75,76,77,78,79,80,82,84,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,126,127,128,129,130,131,132,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,154,155,156,158,159,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301,302,303,304,305,306,307,308,309,310,311,312,313,314,315,316,317,318,319,320,321,322,323,324,325,326,327,328,329,330,331,332,333,334,335,336,337,338,339,340,341,342,343,344,345,346,347,348,349,350,351,352,353,354,355,356,359,360,361,362,363,364,365,366,367,368,369,370,371,372,373

- 有幸运盒子城市：

	- 5,6,8,9,12,13,14,15,16,19,22,24,25,26,29,32,33,34,35,38,42,44,50,58,60,74,81,83,85,86,125,133,134,153,157,160,254,11,18,20,37,39,40,41,46,47,57,71,72,76,79,87,102,108,121,127,135,137,138,142,143,146,156,166,167,168,193,226,253,256,258,259,270,300,301,306,308

- 分流

| 实验组 | 策略 | 流量 |
| --- | --- | --- |
| V3 | V3主流量 | 62% |
| V3_a | V3主流量 | 10% |
| V3_b | V3主流量 | 10% |
| V3修复 | V3，修复acc_CR问题 | 10% |

## 实验结果记录

**打包实验结果**

| 日期 | 星期 | 实验范围 | by天实验结果 |
| --- | --- | --- | --- |
| 1.5 <br> | 周一 <br> | 原记录 | ![](96017ed510af341b-截屏2026-01-07下午2.00.15.png) <br> |
| 1.6 <br> | 周二 <br> | 原记录 | ![](51e448a55a6b2381-截屏2026-01-07下午1.59.45.png) <br> |
| 1.7 <br> | 周三 <br> | 原记录 | ![](c9bcc49c29604279-截屏2026-01-08下午2.13.15.png) <br> |
| 1.8 <br> | 周四 <br> | 原记录 | ![](2b3a6664263406c1-截屏2026-01-09上午10.44.35.png) <br> |
| 1.9 <br> | 周五 <br> | 原记录 | <br> |
| 1.10 <br> | 周六 <br> | 原记录 | <br> |
| 1.11 <br> | 周日 <br> | 原记录 | <br> |


‍

## 二期实验配置调整1.9

- 调整原因

	- 由于1.8号实验结果中，修复组acc_cr阈值分位点从50->60后，默勾比例上升，完单负向缩窄至-0.14%；为拉齐主流量、修复组默勾比例，**进一步提高修复组acc_cr阈值分位点至70**

	- 1.8号工程进行了ECR修复，判断1.8实验结果中完单负向是由于人均冒泡负向，因此**重新分流**

	- 为观察V3_a、V3_b的AB diff是否由于acc_cr的并发BUG导致，修复组开两个10%的流量

- 实验日期：2026.01.09开启；观察周期2026.01.10～2026.01.16

- 实验城市：全国；Top37城和其余城市，是两个运筹实验，分流seed不同

	- Top37城：5,6,8,9,12,13,14,15,16,19,22,24,25,26,29,32,33,34,35,38,42,44,50,58,60,74,81,83,85,86,125,133,134,153,157,160,254 

	- 其余40城：11,18,20,37,39,40,41,46,47,57,71,72,76,79,87,102,108,121,127,135,137,138,142,143,146,156,166,167,168,193,226,253,256,258,259,270,300,301,306,308

	- 无幸运盒子城市：1,3,4,7,10,23,27,28,30,36,43,45,48,49,51,52,53,54,55,56,59,61,62,63,64,65,66,67,68,69,70,73,75,77,78,80,82,84,88,89,90,91,92,93,94,95,96,97,98,99,100,101,103,104,105,106,107,109,110,111,112,113,114,115,116,117,118,119,120,122,123,124,126,128,129,130,131,132,136,139,140,141,144,145,147,148,149,150,151,152,154,155,158,159,161,162,163,164,165,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,194,195,196,197,198,199,200,201,202,203,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,255,257,260,261,262,263,264,265,266,267,268,269,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,302,303,304,305,307,309,310,311,312,313,314,315,316,317,318,319,320,321,322,323,324,325,326,327,328,329,330,331,332,333,334,335,336,337,338,339,340,341,342,343,344,345,346,347,348,349,350,351,352,353,354,355,356,359,360,361,362,363,364,365,366,367,368,369,370,371,372,373

- 分流：1.9-1.12，修复组默勾acc_cr阈值分位点为70，1.13起V3修复组调整为60分位点，V3修复B调整为65分位点

| 实验组 | 策略 | acc_cr阈值分位点 | 流量 |
| --- | --- | --- | --- |
| V3 | V3主流量 | 50 | 57% |
| V3空白 | V3，不出呼返，幸运盒子智能定价 | 3% |
| V3_a | V3主流量 | 10% |
| V3_b | V3主流量 | 10% |
| V3修复 | V3，修复acc_CR问题 | 60 | 10% |
| V3修复\_b | V3，修复acc_CR问题 | 65 | 10% |

## 二期实验结果记录

[202601联合决策实验结果修正版.xlsx](5b289a63c4418d11-202601联合决策实验结果修正版.xlsx)

评估期：2026.01.14\~2026.01.20

有幸运盒子打包实验结果：V3修复 vs 主流量

- Top37城（完单占比82%）：花业务补贴率显著-0.1pp，人均完单显著**+0.18%**，幸运盒子完单份额+1.8%

- 有幸运盒子其他40城（完单占比18%）：花业务补贴率不显著-0.09pp，人均完单显著**-0.33%**，幸运盒子完单份额+0.73%

- 打包有幸运盒子城市实验结果：花业务补贴率-0.1pp，人均完单**+0.09%**

> [!example]- PlainText 实现细节（205 行）
> ```PlainText
> with pas_info_raw as (
>     select
>         distinct pid,
>         exp_group,
>         city_id
>     from
>         kflower_strategy.pltf_union_stg_exp_evaluation_pas_tag
>     where
>         dt between '${begin}'
>         and '${end}'
>         and city_id in (${city})
> ),
> pas_info_cnt as (
>     select
>         pid,
>         count(distinct exp_group) as pid_cnt
>     from
>         pas_info_raw
>     group by
>         pid
> ),
> pas_info as (
>     select
>         *
>     from
>         pas_info_raw
>     where
>         pid in (
>             select
>                 distinct pid
>             from
>                 pas_info_cnt
>             where
>                 pid_cnt = 1
>         )
> ),
> core_data as (
>     select
>         *
>     from
>         kflower_strategy.pltf_union_stg_daily_core_data_for_evaluation
>     where
>         dt between '${begin}'
>         and '${end}'
>         and city_id in (${city})
> ),
> agg_info as (
>     select
>         exp_group,
>         count(a.passenger_id) as pid_num,
>         count(distinct a.passenger_id) as pnum,
>         sum(nvl(bubble_cnt, 0)) as bubble_cnt,
>         sum(nvl(call_cnt, 0)) as call_cnt,
>         sum(nvl(dedup_call_cnt, 0)) as dedup_call_cnt,
>         sum(nvl(lucky_box_compete_call_cnt, 0)) as lucky_box_compete_call_cnt,
>         sum(nvl(uabox_compete_call_cnt, 0)) as uabox_compete_call_cnt,
>         sum(nvl(ufbox_compete_call_cnt, 0)) as ufbox_compete_call_cnt,
>         sum(nvl(fin_cnt, 0)) as fin_cnt,
>         sum(nvl(fin_dis, 0)) as fin_dis,
>         sum(nvl(lucky_box_fin_cnt, 0)) as lucky_box_fin_cnt,
>         sum(nvl(uabox_fin_cnt, 0)) as uabox_fin_cnt,
>         sum(nvl(ufbox_fin_cnt, 0)) as ufbox_fin_cnt,
>         sum(nvl(zy_fin_cnt, 0)) as zy_fin_cnt,
>         sum(nvl(hh_fin_cnt, 0)) as hh_fin_cnt,
>         sum(nvl(dd_fin_cnt, 0)) as dd_fin_cnt,
>         sum(nvl(api_fin_cnt, 0)) as api_fin_cnt,
>         sum(nvl(api_as_uabox_fin_cnt, 0)) as api_as_uabox_fin_cnt,
>         sum(nvl(no_dd_fin_cnt, 0)) as no_dd_fin_cnt,
>         sum(nvl(gmv, 0)) as gmv,
>         sum(nvl(uabox_gmv, 0)) as uabox_gmv,
>         sum(nvl(api_gmv, 0)) as api_gmv,
>         sum(nvl(subsidy_c - lucky_box_subsidy_c, 0)) as subsidy_c,
>         -- 总C补去掉了幸运盒子C补
>         sum(nvl(subsidy_c_third_part, 0)) as subsidy_c_third_part,
>         sum(nvl(uabox_subsidy_c, 0)) as uabox_subsidy_c,
>         sum(nvl(pltf_subsidy_c, 0)) as pltf_subsidy_c,
>         sum(nvl(shangjia_subsidy_c, 0)) as shangjia_subsidy_c,
>         sum(nvl(offline_coupon_subsidy_c, 0)) as offline_coupon_subsidy_c,
>         sum(nvl(api_subsidy_c, 0)) as api_subsidy_c,
>         sum(nvl(no_dd_gmv, 0)) as no_dd_gmv,
>         sum(nvl(no_dd_subsidy_c, 0)) as no_dd_subsidy_c,
>         sum(nvl(mogou_call_cnt, 0)) as mogou_call_cnt,
>         sum(nvl(only_mogou_call_cnt, 0)) as only_mogou_call_cnt,
>         sum(nvl(call_cnt_new, 0)) as call_cnt_new,
>         sum(nvl(call_cp_cnt_new, 0)) as call_cp_cnt_new,
>         sum(nvl(can_reverse_cnt, 0)) as can_reverse_cnt,
>         sum(nvl(had_reverse_cnt, 0)) as had_reverse_cnt,
>         sum(nvl(can_append_cnt, 0)) as can_append_cnt,
>         sum(nvl(had_append_cnt, 0)) as had_append_cnt,
>         sum(nvl(mogou_cnt_box_as_one, 0)) as mogou_cnt_box_as_one,
>         sum(nvl(called_cnt_box_as_one, 0)) as called_cnt_box_as_one,
>         sum(nvl(is_mogou_accept, 0)) as is_mogou_accept,
>         sum(nvl(is_jiagou, 0)) as is_jiagou,
>         sum(nvl(is_fangou, 0)) as is_fangou,
>         sum(nvl(call_cnt_new_mogou, 0)) as call_cnt_new_mogou,
>
>         -- 求方差
>         var_pop(coalesce(bubble_cnt,0)) as var_bubble_cnt,
>         var_pop(coalesce(call_cnt,0)) as var_call_cnt,
>         var_pop(coalesce(dedup_call_cnt,0)) as var_dedup_call_cnt,
>         var_pop(coalesce(fin_cnt,0)) as var_fin_cnt,
>         var_pop(coalesce(gmv,0)) as var_gmv,
>         var_pop(coalesce(subsidy_c,0)) as var_subsidy_c,
>
>         var_pop(coalesce(no_dd_fin_cnt,0)) as var_no_dd_fin_cnt,
>         var_pop(coalesce(no_dd_gmv,0)) as var_no_dd_gmv,
>         var_pop(coalesce(no_dd_subsidy_c,0)) as var_no_dd_subsidy_c
>     from
>         core_data a
>         inner join pas_info b on a.passenger_id = b.pid
>         and a.city_id = b.city_id
>     group by
>         exp_group
> ),
> exp_result as (
>     select
>         exp_group,
>         pnum,
>         bubble_cnt / pnum as `人均冒泡`,
>         call_cnt / pnum as `人均呼叫`,
>         dedup_call_cnt / pnum as `人均去重呼叫`,
>         fin_cnt / pnum as `人均完单`,
>         gmv / pnum as `人均GMV`,
>         subsidy_c / pnum as `人均补贴额`,
>         call_cnt / bubble_cnt as `ecr`,
>         fin_cnt / call_cnt as `cr`,
>
>         subsidy_c / gmv as `补贴率`,
>         (subsidy_c - subsidy_c_third_part) / gmv as `花业务补贴率`,
>         uabox_subsidy_c / gmv as `特价盒子补贴率`,
>         uabox_subsidy_c / uabox_gmv as `特价盒子补贴率（盒子gmv口径）`,
>         pltf_subsidy_c / gmv as `平台呼返补贴率`,
>         shangjia_subsidy_c / gmv as `商家呼返补贴率`,
>         offline_coupon_subsidy_c / gmv as `离线券补贴率`,
>         api_subsidy_c / gmv as `API独补补贴率`,
>         api_subsidy_c / api_gmv as `API独补补贴率（APIgmv口径）`,
>         (uabox_subsidy_c + pltf_subsidy_c) / gmv as `平台供需c补率`,
>
>         (fin_dis / 1000) / fin_cnt as `单均完单里程`,
>         gmv * 1000 / fin_dis as `应付cpm`,
>         (gmv - subsidy_c) * 1000 / fin_dis as `实付cpm`,
>         gmv / fin_cnt as `asp`,
>
>         mogou_cnt_box_as_one / call_cnt_new_mogou as `单均默勾车型数`,
>         called_cnt_box_as_one / call_cnt_new_mogou as `单均呼叫车型数`,
>         is_jiagou / call_cnt_new_mogou as `加勾率`,
>         is_fangou / call_cnt_new_mogou as `反勾率`,
>         is_mogou_accept / call_cnt_new_mogou as `默勾接受度`,
>
>         lucky_box_fin_cnt / fin_cnt as `幸运盒子完单份额`,
>         uabox_fin_cnt / fin_cnt as `特价盒子完单份额`,
>         ufbox_fin_cnt / fin_cnt as `特快盒子完单份额`,
>         dd_fin_cnt / fin_cnt as `滴滴完单份额`,
>         api_fin_cnt / fin_cnt as `API完单份额`,
>         api_as_uabox_fin_cnt / fin_cnt as `API以特价盒子完单份额`,
>         zy_fin_cnt / fin_cnt as `自营完单份额`,
>         hh_fin_cnt / fin_cnt as `宏鹄完单份额`,
>         lucky_box_compete_call_cnt / call_cnt as `幸运盒子竞呼占比`,
>         uabox_compete_call_cnt / call_cnt as `特价盒子竞呼占比`,
>         ufbox_compete_call_cnt / call_cnt as `特快盒子竞呼占比`,
>
>         no_dd_fin_cnt / pnum as `人均完单不含dd`,
>         no_dd_gmv / pnum as `人均GMV（不含滴滴）`,
>         no_dd_subsidy_c / pnum as `人均补贴额（不含滴滴）`,
>         no_dd_subsidy_c / no_dd_gmv as `补贴率（不含滴滴）`,
>
>         var_bubble_cnt/pnum as var_bubble_cnt,
>         var_call_cnt/pnum as var_call_cnt,
>         var_dedup_call_cnt/pnum as var_dedup_call_cnt,
>         var_fin_cnt/pnum as var_fin_cnt,
>         var_gmv/pnum as var_gmv,
>         var_subsidy_c/pnum as var_subsidy_c,
>         var_no_dd_fin_cnt/pnum as var_no_dd_fin_cnt,
>         var_no_dd_gmv/pnum as var_no_dd_gmv,
>         var_no_dd_subsidy_c/pnum as var_no_dd_subsidy_c
>     from
>         agg_info
>     order by
>         exp_group
> ),
> control_result as (
>     select
>         exp_group,
>         `人均完单`,
>         `人均GMV`,
>         `人均补贴额`,
>         `花业务补贴率`,
>         `asp`
>     from
>         exp_result
>     where
>         exp_group = 'union_stg_v3_max_order_v1_only_box_blank'
> )
> select
>     (a.`人均完单` - b.`人均完单`) / (a.`人均补贴额` * b.`asp` / a.`asp` - b.`人均补贴额`) as `adj-FROI`,
>     (a.`人均完单` - b.`人均完单`) / (
>         a.`人均GMV` * a.`花业务补贴率` * b.`asp` / a.`asp` - b.`人均GMV` * b.`花业务补贴率`
>     ) as `花业务adj-FROI`,
>     -- (a.`人均GMV` - b.`人均GMV`) / (a.`人均补贴额` - b.`人均补贴额`) as `GMV-ROI`,
>     a.*
> from
>     exp_result a
>     left join control_result b on b.exp_group = 'union_stg_v3_max_order_v1_only_box_blank'
> order by
>     exp_group;
> ```


**打包实验结果 · 有幸运盒子Top37城市 · 有幸运盒子其他40城**

**有幸运盒子Top37城市**

![](88e0863cd88507a1-截屏2026-01-21上午10.55.18.png) <br>

**有幸运盒子其他40城**

![](ec0bf91ce9ff50f6-截屏2026-01-21上午10.55.50.png) <br>

| 日期 | 星期 | 实验范围 | by天实验结果 |
| --- | --- | --- | --- |
| 1.14 <br> | 周三 <br> | 有幸运盒子Top37城市 | ![](3524555103fa7c8c-截屏2026-01-20下午1.52.45.png) <br> |
| 1.15 <br> | 周四 <br> | 有幸运盒子Top37城市 | ![](7f0a0c0d536f0353-截屏2026-01-20下午3.56.09.png) <br> |
| 1.16 <br> | 周五 <br> | 有幸运盒子Top37城市 | ![](d021a6243719291c-截屏2026-01-20下午3.56.20.png) <br> |
| 1.17 <br> | 周六 <br> | 有幸运盒子Top37城市 | ![](e28392294bb138d1-截屏2026-01-20下午3.56.31.png) <br> |
| 1.18 <br> | 周日 <br> | 有幸运盒子Top37城市 | ![](011f0119b25e85b8-截屏2026-01-20下午3.56.44.png) <br> |
| 1.19 <br> | 周一 <br> | 有幸运盒子Top37城市 | ![](900ac10a4945718a-截屏2026-01-20下午3.56.53.png) <br> |
| 1.20 <br> | 周二 <br> | 有幸运盒子Top37城市 | ![](a35c3bb1143e8734-截屏2026-01-21上午10.56.01.png) <br> |
| 1.14 <br> | 周三 <br> | 有幸运盒子其他40城 | ![](95793d9f15cdd26f-截屏2026-01-20下午3.58.27.png) <br> |
| 1.15 <br> | 周四 <br> | 有幸运盒子其他40城 | ![](d68c3eec54d6cae8-截屏2026-01-20下午3.58.42.png) <br> |
| 1.16 <br> | 周五 <br> | 有幸运盒子其他40城 | ![](af0eef92a95790d8-截屏2026-01-20下午3.58.56.png) <br> |
| 1.17 <br> | 周六 <br> | 有幸运盒子其他40城 | ![](46f47e9e1ffeb94f-截屏2026-01-20下午4.02.18.png) <br> |
| 1.18 <br> | 周日 <br> | 有幸运盒子其他40城 | ![](09c0f858cc97844e-截屏2026-01-20下午4.19.27.png) <br> |
| 1.19 <br> | 周一 <br> | 有幸运盒子其他40城 | ![](83a117c5d4e6d02a-截屏2026-01-20下午4.19.44.png) <br> |
| 1.20 <br> | 周二 <br> | 有幸运盒子其他40城 | ![](b99e80a682aba6d3-截屏2026-01-21上午10.56.14.png) <br> |


无幸运盒子城市实验结果：

![](88acf39b4bca9baa-截屏2026-01-21上午10.58.43.png)

实验结果排查验证
‍分流验证

![](488acf7448b322a6-截屏2026-01-12上午11.37.31.png)

平均默勾比例对比

主流量 vs 修复组

幸运盒子展现时段：1.11号中午12点，42 vs 49，修复组勾的更多

幸运盒子不展现时段：1.11号下午18点，33 vs 42，相比于幸运盒子展现时段，主流量会少勾，修复组勾的更多，GAP更大

| 主流量 | 修复组 | |
| --- | --- | --- |
| ![](eb9e97b13adbeb9d-截屏2026-01-12上午11.50.35.png) | ![](d899f6508a79e514-截屏2026-01-12上午11.51.07.png) | |

 按城市拆分

AB期：01.10-01.11

结论：负向主要由于TOP37城有幸运盒子，人均完单-0.23%导致，原因是花业务补贴率-0.29%；其余城市-有幸运盒子 & 其余城市-无幸运盒子，由于补贴率拉齐，人均完单微正

| 日期 | TOP37城 有幸运盒子 | 其余城市-有幸运盒子 | 有幸运盒子 | 其余城市-无幸运盒子 |
| --- | --- | --- | --- | --- |
| 1.10-1.11 | ![](02e6f7a1e7ca13ea-截屏2026-01-12下午6.08.18.png) | ![](2e49af98ae5f8524-截屏2026-01-12下午6.10.22.png) | | ![](9a4ab6b6abbaf1e7-截屏2026-01-12下午6.10.02.png) |
| 1.12 | ![](56f905de57269a3b-截屏2026-01-13上午10.56.33.png) | ![](6e9560cd1d0377e0-截屏2026-01-13上午10.56.39.png) | ![](55a67124f0f45041-截屏2026-01-13上午11.08.56.png) | ![](8b10fe58381abad7-截屏2026-01-13上午10.58.00.png) |

### AA结果-待重新跑

AA期：2026.01.01-2026.01.07

AB期：2026.01.10-2026.01.11

> [!example]- PlainText 实现细节（268 行）
> ```PlainText
> -- 2. 评估 区分整体/分类型
>
> -- 没有串组样本
> -- 少量样本会被归到两种类型，猜测是取数周期的问题
>
> with pas_info_raw as (
>     select
>         distinct pid,
>         exp_group
>     from
>         kflower_strategy.pltf_union_stg_exp_evaluation_pas_tag
>     where
>         dt between '${begin}'
>         and '${end}'
>         and city_id in (${city})
> ),
> pas_info_cnt as (
>     select
>         pid,
>         count(distinct exp_group) as pid_cnt
>     from
>         pas_info_raw
>     group by
>         pid
> ),
> pas_tag as (
>     select
>         *
>     from
>         pas_info_raw
>     where
>         pid in (
>             select
>                 distinct pid
>             from
>                 pas_info_cnt
>             where
>                 pid_cnt = 1
>         )
> ),
>
> visit as 
> (
>     select 
>         passengerid as passenger_id,
>         count(*) as visit_cnt
>     from 
>         kflower_dw.dwm_kf_log_pas_visit_event_di
>     where 
>         dt between '${begin_date}' and '${end_date}' 
>         and city_id in (${city})
>         and is_valid_visit = 1
>     group by 
>         passengerid
> ),
>
> bubble as 
> (
>     select 
>         passenger_id,
>         count(distinct distinct_bubble_id) as bubble_cnt 
>     from 
>     (
>         select
>             *
>         from 
>             kflower_dw.dwd_kf_trd_bubble_base_di
>         where 
>             dt between '${begin_date}' and '${end_date}' 
>             and product_1level in (1,2)
>             and is_anycar_form = 1
>             and is_from_waiting_response <> 1 
>             and passenger_id <> 0
>             and city_id in (${city})
>     ) a 
>     left join 
>     (
>         select  
>             estimate_id
>             ,distinct_bubble_id
>         from    
>             kflower_dw.dim_kf_trd_unity_bubble_anycar_label_di
>         where   
>             dt between '${begin_date}' and '${end_date}'
>             and source_id = 'kf'
>     ) c
>     on a.bubble_id = c.estimate_id
>     group by 
>         passenger_id
> ),
>
>
> call as 
> (
>     select 
>         passenger_id
>         ,count(distinct case when is_compete_call = 1 then a.order_id end) as call_cnt
>     from 
>     (
>         select 
>             *,
>             start_city_id as city_id 
>         from 
>             kflower_dw.dwd_kf_trd_unity_order_anycar_di
>         where 
>             dt between '${begin_date}' and '${end_date}' 
>             and passenger_id <> 0
>             and is_hxz_call = 1
>             and to_date(call_time) = dt
>             and product_id <> 26 
>             and start_city_id in (${city})
>     ) a 
>     left join
>     (
>         select 
>             source_id,
>             dt,
>             order_id,
>             estimate_id,
>             product_id,
>             call_car_level_id,
>             is_compete_call,
>             is_objective_call,
>             is_platform_objective_call
>         from 
>             kflower_dw.dim_kf_trd_unity_order_anycar_label_di
>         where 
>             dt between '${begin_date}' and '${end_date}'
>     ) c 
>     on  
>         a.order_id = c.order_id 
>         and a.estimate_id = c.estimate_id 
>         and a.product_id = c.product_id 
>         and a.call_car_level_id = c.call_car_level_id 
>         and a.dt = c.dt
>     group by 
>         passenger_id
> ),
>
>
> finish as 
> (
>     select 
>         passenger_id,
>         count(distinct case when is_td_finish = 1 then a.order_id end) as fin_cnt,
>         sum(case when is_td_finish = 1 then a.gmv_amt end) as gmv,
>         sum(case when is_td_finish = 1 then subsidy_c end) as subsidy_c,
>         count(distinct case when is_grab_before_cannel = 1 then a.order_id end) as grab_before_cannel_cnt,
>         count(distinct case when is_td_answer = 1 then a.order_id end) as ans_cnt,
>         count(distinct case when is_td_answer_without_reassign = 1 then a.order_id end) as ans_cnt_without_reassign,
>         count(distinct case when is_grab_after_pas_cancel = 1 then a.order_id end) as grab_after_pas_cancel_cnt,
>         count(distinct case when is_grab_after_pas_cancel_without_reassign = 1 then a.order_id end) as grab_after_pas_cancel_cnt_without_reassign,
>         count(distinct case when is_grab_after_dri_cancel = 1 then a.order_id end) as grab_after_dri_cancel_cnt,
>         count(distinct case when is_grab_after_dri_cancel_without_reassign = 1 then a.order_id end) as grab_after_dri_cancel_cnt_without_reassign,
>         count(distinct case when is_td_answer = 1 then origin_order_id end) as origin_order_cnt,
>         sum(case when a.origin_order_id = a.order_id and is_td_answer = 1 then a.answer_dur end) as first_ans_dur,
>         count(distinct origin_order_id) as origin_call_cnt,
>         sum(wait_dur) as wait_dur,
>         sum(case when is_grab_before_cannel = 1 then wait_dur end) as before_cancel_wait_dur
>     from 
>     (
>         select distinct 
>             passenger_id,
>             source_id,
>             product_id,
>             order_id,
>             product_type,
>             gmv_amt,
>             start_city_id as city_id,
>             is_grab_before_cannel,
>             est_arrive_dur,
>             est_arrive_dis / 1000 as est_arrive_dis,
>             call_car_level_id,
>             dt,
>             level_type,
>             order_charge_dis/1000 as order_charge_dis,
>             coalesce(call_reassign_order_id,answer_reassign_order_id,order_id) as origin_order_id,
>             unix_timestamp(answer_time) - unix_timestamp(call_time) as answer_dur,
>             case 
>                 when answer_time != '0000-00-00 00:00:00' then (unix_timestamp(answer_time) - unix_timestamp(call_time))
>                 else (unix_timestamp(cancel_time) - unix_timestamp(call_time))
>             end as wait_dur
>         from 
>             kflower_dw.dwd_kf_trd_unity_order_di
>         where 
>             dt between '${begin_date}' and '${end_date}'
>             and is_hxz = 1
>             and start_city_id in (${city})
>     ) a 
>     left join 
>     (   
>         select  
>             *
>         from    
>             kflower_dw.dim_kf_trd_unity_order_label_di
>         where   
>             dt between '${begin_date}' and '${end_date}'
>             and source_id = 'kf'
>     ) label
>     on  a.source_id = label.source_id and a.order_id = label.order_id and a.dt = label.dt
>     left join
>     (
>         select
>             order_id,
>             sum(subsidy_c) as subsidy_c
>         from 
>             kflower_dw.dwm_kf_fin_order_subsidy_c_di
>         where 
>             dt between '${begin_date}' and date_add('${end_date}',2)
>             and subsidy_type not in (64) -- 去除幸运盒子假C补
>         group by 
>             order_id 
>     ) b  
>         on a.order_id = b.order_id
>     group by 
>         passenger_id
> ),
>
> raw as 
> (
>     select 
>         pas_tag.exp_group
>         -- ,pas_tag.type
>         ,count(distinct pas_tag.pid) as `样本量`
>         ,count(distinct case when visit_cnt > 0 then pas_tag.pid end) as `访问样本量`
>         ,count(distinct case when bubble_cnt > 0 then pas_tag.pid end) as `冒泡样本量`
>         ,count(distinct case when call_cnt > 0 then pas_tag.pid end) as `呼叫样本量`
>         ,count(distinct case when fin_cnt > 0 then pas_tag.pid end) as `完单样本量`
>         -- ,count(distinct case when coupon_spend_amt > 0 then pas_tag.pid end) as `券核销样本量`
>         ,sum(nvl(visit_cnt,0))/count(distinct pas_tag.pid) as `大盘访问`
>         ,sum(nvl(bubble_cnt,0))/count(distinct pas_tag.pid) as `大盘冒泡`
>         ,sum(nvl(call_cnt,0))/count(distinct pas_tag.pid) as `大盘呼单`
>         ,sum(nvl(fin_cnt,0))/count(distinct pas_tag.pid) as `大盘完单`
>         ,sum(nvl(gmv,0))/count(distinct pas_tag.pid) as `大盘gmv`
>         ,sum(nvl(subsidy_c,0))/count(distinct pas_tag.pid) as `大盘c补`
>         -- ,sum(nvl(coupon_spend_amt,0))/count(distinct pas_tag.pid) as `券c补`
>         ,sum(nvl(subsidy_c,0))/sum(nvl(gmv,0)) as `大盘c补率`
>         ,sum(nvl(call_cnt,0))/sum(nvl(bubble_cnt,0)) as `大盘ecr`
>         ,sum(nvl(fin_cnt,0))/sum(nvl(call_cnt,0)) as `大盘cr`
>
>         ,sum(nvl(ans_cnt_without_reassign,0))/sum(nvl(call_cnt,0)) as `应答率`
>         ,sum(nvl(grab_before_cannel_cnt,0))/sum(nvl(call_cnt,0)) as `应答前乘客取消率`
>         ,sum(nvl(grab_after_pas_cancel_cnt_without_reassign,0))/sum(nvl(ans_cnt_without_reassign,0)) as `应答后乘客取消率`
>         ,sum(nvl(grab_after_dri_cancel_cnt,0))/sum(nvl(ans_cnt,0)) as `应答后司机取消率含改派`
>         ,sum(nvl(grab_after_dri_cancel_cnt_without_reassign,0))/sum(nvl(ans_cnt_without_reassign,0)) as `应答后司机取消率不含改派`
>
>         ,sum(nvl(first_ans_dur,0))/sum(nvl(origin_order_cnt,0)) as `应答单单均首次应答时长`
>         ,sum(nvl(wait_dur,0))/sum(nvl(call_cnt,0)) as `呼叫单均愿等时长`
>         ,sum(nvl(before_cancel_wait_dur,0))/sum(nvl(grab_before_cannel_cnt,0)) as `应答前取消单单均愿等时长`
>
>         ,var_pop(coalesce(visit_cnt,0))/count(distinct pas_tag.pid) as `var_访问`
>         ,var_pop(coalesce(bubble_cnt,0))/count(distinct pas_tag.pid) as `var_冒泡`
>         ,var_pop(coalesce(call_cnt,0))/count(distinct pas_tag.pid) as `var_呼单` 
>         ,var_pop(coalesce(fin_cnt,0))/count(distinct pas_tag.pid) as `var_完单`
>         ,var_pop(coalesce(gmv,0))/count(distinct pas_tag.pid) as `var_gmv`
>         ,var_pop(coalesce(subsidy_c,0))/count(distinct pas_tag.pid) as `var_c补`
>     from 
>         pas_tag 
>         left join visit on pas_tag.pid = visit.passenger_id 
>         left join bubble on pas_tag.pid = bubble.passenger_id 
>         left join call on pas_tag.pid = call.passenger_id
>         left join finish on pas_tag.pid = finish.passenger_id
>     group by 
>         pas_tag.exp_group
>         -- ,pas_tag.type
> )
>
> select * from raw
> ```


vs空白组结果

![](66ccc306bc6a69e2-截屏2026-01-12下午12.02.39.png)


> [!abstract]- 子页面（2）
> - [联合决策V3 acc_cr BUG修复实验负向分析](acc_CR%E4%BF%AE%E5%A4%8D%EF%BC%9A%E8%B4%9F%E5%90%91%E5%88%86%E6%9E%90%E4%B8%8E%E9%80%90%E5%8D%95%E9%AA%8C%E7%AE%97.md#%E8%B4%9F%E5%90%91%E7%BB%93%E6%9E%9C%E4%B8%8E%E9%98%88%E5%80%BC%E5%88%86%E6%9E%90)
> - [联合决策acc_cr修复验证](acc_CR%E4%BF%AE%E5%A4%8D%EF%BC%9A%E8%B4%9F%E5%90%91%E5%88%86%E6%9E%90%E4%B8%8E%E9%80%90%E5%8D%95%E9%AA%8C%E7%AE%97.md#%E5%B9%B8%E8%BF%90%E7%9B%92%E5%AD%90%E9%80%90%E5%8D%95%E9%AA%8C%E7%AE%97)
