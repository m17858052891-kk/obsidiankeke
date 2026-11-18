---
title: "联合决策V3 acc_cr分析-新进特价盒子 or 新开城商家冷启动"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2206270316022
cssclasses: ["strategy-body-note"]
---

# 联合决策V3 acc_cr分析-新进特价盒子 or 新开城商家冷启动

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2206270316022)

**阅读定位**　[[#0、结论|0、结论]] · [[#1 API进特价盒子影响|1 API进特价盒子影响]] · [[#2 新开城商家冷启动现状|2 新开城商家冷启动现状]]

## 0、结论

1. 当前「新商家进盒子会影响商家盒子外默勾」的问题，在**联合决策V3**中依然存在，其关键在于目前acc_CR模型在**预测商家盒子内和盒子外的CR贡献**时，没有**单独的特征**（过一次模型同时输出盒子内外的贡献），仅能通过**少量价格特征**和**盒子内外完单label**监督来体现他们的差异。这导致新商家进盒子后，预测的CR贡献，盒子内外没有差异。

2. 短期方案，我们可以通过人工干预新商家在盒子内的贡献（置0），使得新商家开城后，商家在盒子外的默勾不受影响；

	1. 什么时候能去商家进盒子开城保护呢？需要基于新商家开城后的数据重新训练模型后，才能去掉商家开城保护；

	2. 优化节奏：本周提需，预计1月中旬能修复完毕；

3. 长期方案，优化acc_CR模型，在acc_CR模型中增加幸运盒子、特价盒子相关的特征，包括历史统计特征和实时的SDS特征，后者目前已经建设完毕，收集特征阶段；

	1. 优化节奏：

		1. 独立的SDS特征已建设完毕，目前在收集特征阶段；

		2. 历史统计特征建设：预计1月底完成；

		3. 新模型上线：时间待定；

## 1 API进特价盒子影响

### 1.1 背景

API商家新进特价盒子时，会提高特价盒子的acc_CR / acc_AR，导致整体默勾少勾，影响盒子外的API商家完单

具体而言，在联合决策V2链路中，由于AR模型对新进商家，特价盒子输出的惩罚项为1，会高估新进商家在特价盒子的AR；在联合决策V3中，模型会输出同一商家特价盒子、特快盒子、盒子外的输出，由模型学出不同品类之间的差异

### 1.2 分析

#### 特价盒子未开城时模型输出

- 分析口径：

	- 选城：如祺回滚的大城市，2,17,36,41,84,158

	- 实验流量：联合决策V3主流量，按照trace取即可

	- 时间：2025.12.15

	- product_id：如祺

	- 计算：呼叫完单贡献，在特价盒子、特快盒子、盒子外的输出均值；直接从EVE日志表中取

结论：如祺在特价盒子、盒子外输出无差异，均高于特快盒子

原因：在特价盒子未开城时，特价盒子价格会被盒子外覆盖，且模型无其他品类相关特征，建模时无该商家在特价盒子的监督label

> [!example]- SQL 实现细节（113 行）
> ```SQL
> -- 从日志表里取这些城市的trace，和对应的真实折扣
> with trace_info as (
>     select 
>         distinct 
>         param['traceid'] as trace_id,
>         param['box_discount'] as box_discount
>     from 
>         kflower_marketplace.ods_log_kflower_platform_call_return_public_log_h
>     where 
>         concat_ws('-', year, month, day) = '2025-12-15'
>         and param['is_fuse'] = 'false'  -- 非熔断
>         and param['hit_bubble_cache'] is null -- 非缓存
>         and param['estimate_bubble_id']='' -- 预估场景
>         and param['call_return_scene_type']=1-- 只取冒泡页预估
>         and param['city_id'] in (2,17,36,41,84,158)
>         and get_json_object(param['flow_control'], '$.ExpGroupName') in (
>                 'union_stg_v3_max_order_v1_only_box'
>             )
> ),
>
> log_cr as (
>     select 
>         a.trace_id,
>         input,
>         output
>     from 
>         (
>             select 
>                 traceid as trace_id,
>                 input,
>                 output
>             from 
>                 kflower_marketplace.ods_log_kflower_dups_eve_public_log_h
>             where 
>                 concat_ws('-',year,month,day) = '2025-12-15'
>                 and model_name = 'union_strategy_ar_deep_model_gpu'
>                 and model_version = 'v27'
>                 and primary_key = 'PlatformJointPrice'
>         ) a 
>         inner join 
>         (
>             select 
>                 distinct 
>                 trace_id
>             from 
>                 trace_info
>         ) b on a.trace_id = b.trace_id
> ),
>
> cr_info as (
>     select 
>         trace_id,
>         substring_index(substring_index(get_json_object(input,'$[0].discount'), '_', 2), '_', -1) as box_discount,
>         get_json_object(input,'$[*].product_id') as product_id_list,
>         get_json_object(output,'$.outputs.0') as output_data
>     from 
>         log_cr
> ),
>
> product_index as (
>     select 
>         trace_id,
>         box_discount,
>         (case 
>             when locate('"408"', product_id_list) > 0 then
>                 (length(substring(product_id_list, 2, locate('"408"', product_id_list) - 2)) 
>                 - length(replace(substring(product_id_list, 2, locate('"408"', product_id_list) - 2), ',', '')))
>             else -1
>         end) as ruqi_idx,
>         output_data
>     from 
>         cr_info
> ),
>
> cr_out as (
>     select 
>         a.trace_id,
>         a.box_discount,
>         ruqi_idx,
>         uabox_output,
>         out_output,
>         ufbox_output
>     from 
>         (
>             select 
>                 trace_id,
>                 box_discount,
>                 ruqi_idx,
>                 get_json_object(output_data,concat('$.float_data[',ruqi_idx*3,']')) as uabox_output,
>                 get_json_object(output_data,concat('$.float_data[',ruqi_idx*3+1,']')) as out_output,
>                 get_json_object(output_data,concat('$.float_data[',ruqi_idx*3+2,']')) as ufbox_output
>             from 
>                 product_index
>             where 
>                 ruqi_idx <> -1
>         ) a 
>         inner join 
>         (
>             select 
>                 trace_id,
>                 box_discount
>             from 
>                 trace_info
>         ) b on a.trace_id = b.trace_id and a.box_discount = b.box_discount
> )
>
> select 
>     count(*),
>     avg(uabox_output) as uabox_output,
>     avg(out_output) as out_output,
>     avg(ufbox_output) as ufbox_output
> from 
>     cr_out
> ```


| 冒泡样本量 | 32832 |
| --- | --- |
| 特价盒子输出 | 0.72 |
| 盒子外输出 | 0.72 |
| 特快盒子输出 | 0.65 |

#### 特价盒子已开城时模型输出

石家庄如祺、深圳阳光出行、深圳享道出行已接入特价盒子，因此特价盒子  < 盒子外，符合预期

| 商家 | 石家庄如祺 | 深圳阳光出行-238 | 深圳享道出行-368 |
| --- | --- | --- | --- |
| 冒泡样本量 | 43632 | 8264 | 7756 |
| 特价盒子输出 | 0.1641 | 0.48246035 | 0.193 |
| 盒子外输出 | 0.1811 | 0.4964197 | 0.213 |
| 特快盒子输出 | 0.1644 | 0.43504521 | 0.190 |

‍

## 2 新开城商家冷启动现状

### 2.1 背景

新开城商家只有实时特征，无历史统计特征，需看此时的新商家的预测CR情况

### 2.2 分析

分析口径：

- 选城：哈尔滨

- 实验流量：联合决策V3主流量，按照trace取即可

- 时间：2025.12.25

- product_id：国泰优行（5391）；大城市的小商家

- 计算：呼叫完单贡献，在特价盒子、特快盒子、盒子外的输出均值；直接从EVE日志表中取

结论：新开城商家的呼叫完单贡献偏低

| 冒泡样本量 | 1287 |
| --- | --- |
| 特价盒子输出 | 0.044 |
| 盒子外输出 | 0.047 |
| 特快盒子输出 | 0.048 |

原始分析需求
1. 新进特价盒子的商家（主要是API品类），会如何影响默勾，开城一周之后有了该商家在特价盒子内的特征之后呢？

	1. 找一个API没有进特价盒子的城市，看盒子内外的差异

	2. 10.29，API商家是如祺，实验组看acc_cr、V3（最好看这个）组，看前后的默勾水位

	3. 城市：找没有回滚的城市

	4. 开城后每一天的盒子内、盒子外的输出均值

	5. 直接从eve的日志表里捞

1. e.g.宏鹄新开城的商家，当前的冷启动现状

	1. 只缺失商家特征时，模型的输出值

	2. 找一些刚开城的product_id的结果

	3. 最好和类似商家做对比
