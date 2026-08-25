# baseline 自动 buffer PySpark 任务

本目录只实现原策略自动 buffer 表：

```text
kflower_strategy.platform_union_strategy_budget_buffer_auto_baseline_by_city_object_stg
```

不实现 guardrail 新策略表。

## 分层边界

```text
运筹平台：配置 ExpGroupName → LambdaGroup 的 1:1 映射
自动 buffer 任务：只使用 LambdaGroup，且 stg_group = LambdaGroup
```

自动计算业务粒度：

```text
city_id + LambdaGroup/stg_group + date_type
```

`union_stg_v3_max_order_v1_only_box → pltf_union_stg_v3_only_ds_acc_cr_thre` 只是当前一条映射示例，不是代码限制条件。代码对源配置中全部生效 `stg_group/LambdaGroup` 通用计算。

## 文件和执行顺序

1. `auto_buffer_job.py`
   - 只创建并写入 baseline 一张表，不再创建额外的当前状态表、规则表或审计表。
   - 每个 `date_type` 第一次出现时，使用日期城市全集、5 类城市范围规则和 9 条 `stg_group → city_scope` 映射生成该类型键集合，并以 `old_buffer=1.0` 完成唯一一次初始化。
   - 不创建实验组映射表；实验组到 LambdaGroup 的映射属于运筹平台。
   - `TARGET_BUSINESS_DT=STAT_DT+1` 是本次生效日 T；按 T 的日期类型得到唯一 `state_date_type`，每日只执行一次通用计算链路。
   - 不在同一 `dt` 同时计算两套状态，也不对两个非空分支执行 `UNION ALL`。
   - 后续直接读取 baseline 中同 `date_type` 上一期的 `dt` 分区，将其 `union_buffer` 作为 `old_buffer`；若该类型已有历史但严格上一期缺失，任务阻断，不回退到 1.0。
   - 实际率读取同一 `date_type` 序列中 T 的上一期：周一回看上周四，周五回看上周日，其余日期回看自然日前一天。
   - 最新目标口径：目标率为城市粒度；实际率从 `kflower_strategy.pltf_union_stg_budget_control_dashboard.act_subsidy_rate` 读取，粒度为 `city_id + LambdaGroup`。
   - 若实际观测日有实验切流，受影响的 `city_id + LambdaGroup` 不调整，直接复制 `old_buffer`；非切流键执行 `union_buffer = min(2.99, old_buffer × target_rate / actual_rate)`。
   - 新结果只写 baseline 的 `dt=STAT_DT` 分区；`date_type` 由业务日 `T=dt+1` 派生，不增加表字段或分区。
   - baseline 的日分区同时是状态历史和幂等结果：重跑发现当前分区已存在时直接跳过，避免重复调整。
   - 若已存在晚于 `STAT_DT` 的快照，任务阻断旧日期补写；历史回放应使用独立影子表。
   - 当前按约定不在任务内执行表结构比对、业务键唯一性或输入输出行数一致性校验；代码假定上游表及建表 SQL 符合约定。

2. `3.6-buffer-自动调整-TODO路线.md`
   - 完整口径、字段血缘、状态更新/最终发布分层和待确认项。

## 数梦运行参数

```text
BIZ_DATE_LINE     = baseline 物理分区 stat_dt；T=stat_dt+1
```

最新目标输入口径：

```text
目标：kflower_strategy.platform_price_anchor_union_strategy_budget_dict
      total_subsidy_rate

实际：kflower_strategy.pltf_union_stg_budget_control_dashboard
      字段 = act_subsidy_rate
      粒度 = city_id + LambdaGroup
      上游公式 = ROUND((cost + delay_cost) / gmv_amt * 100, 2)

切流：kflower_strategy.pltf_union_stg_exp_evaluation_pas_tag
      窗口 = previous_buffer_dt ~ actual_rate_dt
      规则 = 同一 pid 的 count(distinct exp_group) > 1
      输出 = city_id + LambdaGroup 粒度 has_exp_traffic_switch
```

目标率按 `city_id` 展开，实际率和切流标记按 `city_id + stg_group/LambdaGroup` 关联。实际率单位最终必须与目标表一致。

> `auto_buffer_job.py` 已读取实花看板的 `act_subsidy_rate`，按 `city_id + LambdaGroup` 关联，并实现切流键复制 `old_buffer`。正式运行前需将看板上游 CTE 修正为 `GROUP BY city_id, exp_group, lambda_group`，并对账切流日期窗口。

## 上线前仍需补齐

- 目标补贴率取生效日 T。目标表读取 `dt=BIZ_DATE_LINE`：该物理分区由源规划表
  `dt=BIZ_DATE_LINE+1` 生成，业务内容对应 T 日目标，因此不再单独传 `TARGET_DT`。
- `actual_rate` 读取 T 所属 `date_type` 的上一期，不是固定读取自然日 `T-1`。
- 修正实际率上游的 LambdaGroup 聚合粒度，并确认缺失值、零值处理和分区就绪时间。
- 对账确认切流窗口 `previous_buffer_dt~actual_rate_dt` 与线上 `${begin}~${end}` 口径一致。
- 最终发布任务读取 baseline 当次 `dt=stat_dt` 分区；该分区对应 `publish_dt=stat_dt+1` 的新 buffer。发布仍与计算任务分开。
