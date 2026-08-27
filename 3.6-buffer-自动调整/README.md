# baseline 自动 buffer 任务

本目录只实现原策略自动 buffer 表：

```text
kflower_strategy.platform_union_strategy_budget_buffer_auto_baseline_by_city_object_stg
```

## 文件与执行顺序

1. `create_auto_buffer_table.sql`
   - 只执行一次；
   - 建表粒度为 `dt + city_id + object_group + stg_group`；
   - `object_group` 当前固定为 `max_order_v1`。
2. `auto_buffer_job.py`
   - 每日调度；
   - 不执行 DDL；
   - 读取同日期类型上一期 buffer，计算后覆盖写入 `dt=T`。
3. `reset_auto_buffer_before_launch.sql`
   - 仅在空跑结束、正式上线前执行一次；
   - `${BIZ_DATE_LINE}` 传正式上线日 `T`；
   - 使用 Spark SQL 动态分区，将 `T-7` 至 `T-1` 七个分区按当前完整键空间覆盖为 `union_buffer=1.0`；
   - 不覆盖正式上线日 `T`，执行完成后再启用每日任务。
4. `reset_previous_buffer_for_dry_run.py`
   - 只在线上空跑阶段每日运行；
   - 独立完成与正式任务相同的目标率、实际率、切流、buffer 计算和 `dt=T` 写表；
   - 不读取历史 buffer，每日直接令全部键 `old_buffer=1.0`；
   - 不修改 `PREVIOUS_STATE_DT`，可以保留各日空跑结果；
   - 正式上线后停止调度。

## 线上空跑调度

线上空跑期间每天只运行：

```text
reset_previous_buffer_for_dry_run.py  # 独立计算并写入 dt=T
```

该脚本与正式任务使用相同的目标率 `T`、实际率 `T^-d`、自然日 `T-1` 切流判断和计算公式，唯一差异是不会从 baseline 读取历史 `union_buffer`，而是在当天计算中直接令 `old_buffer=1.0`。这样每日输出都是一次独立调整，不会累计上一期空跑结果。

脚本只覆盖当天 `dt=T`，不会修改昨天或同日期类型上一期分区，因此各日空跑快照可以保留。同日重跑仍会覆盖同一个 `dt=T` 分区。正式上线后必须停止该脚本，改为调度 `auto_buffer_job.py`，恢复真实 buffer 的连续状态更新。

## 上线前清理空跑结果

空跑期间产生的 buffer 会被后续同日期类型状态链继续读取。正式上线前运行：

```text
reset_auto_buffer_before_launch.sql
```

例如正式上线日 `${BIZ_DATE_LINE}=2026-09-08`，脚本重置：

```text
2026-09-01 ～ 2026-09-07
```

每个分区重新写入当前 `distinct city_id × distinct stg_group × max_order_v1` 键空间，`union_buffer=1.0`、`extra_data=''`。SQL 通过动态分区一次覆盖这七个分区，不会覆盖范围外的分区。覆盖完整一周可同时清理 weekday 和 weekend 两条状态链；同一上线日参数重复执行结果不变。

## buffer 键空间

从下表读取当前城市和 LambdaGroup 值域：

```text
kflower_strategy.platform_union_stg_lambda_dict_manually_update
```

生成方式：

```text
distinct city_id × distinct stg_group
```

`stg_group = LambdaGroup`；`object_group` 固定为 `max_order_v1`。不再维护 weekday/weekend 两套城市 include/exclude 配置。

## 日期口径

```text
T                  = ${BIZ_DATE_LINE}
target_rate_dt     = T
previous_state_dt  = T 所属日期类型的上一期
traffic_switch_dt  = 自然日 T-1
```

- weekday：周一至周四；
- weekend：周五至周日；
- 周一回看上周四，周五回看上周日；
- 最终写入 `baseline.dt=T`。

## 初始化

完整键空间左关联同日期类型上一期 baseline：

```text
历史 union_buffer 存在  -> old_buffer = history_buffer
具体键历史值缺失 -> old_buffer = 1.0
```

因此新城市或新 LambdaGroup 可以逐键初始化，无需重新初始化整表。

## 计算规则

输入：

- 目标率：`platform_price_anchor_union_strategy_budget_dict.dt=T`，城市粒度；
- 实际率：`pltf_union_stg_budget_control_dashboard.dt=T^-d`，`city_id + LambdaGroup` 粒度；
- 切流：`pltf_union_stg_exp_evaluation_pas_tag.dt=自然日 T-1`。

任一条件成立时不调整：

- 自然日 T-1 有 PID 命中多个实验组；
- `target_rate` 缺失；
- `actual_rate` 缺失或等于 0。

此时：

```text
new_buffer = old_buffer
```

否则：

```text
new_buffer = min(2.99, old_buffer * target_rate / actual_rate)
```

## 输出

```text
字段：city_id, object_group, stg_group, union_buffer, extra_data
分区：dt=T
粒度：dt + city_id + object_group + stg_group
```

输出表同时是当日自动 buffer 结果和后续同日期类型的历史 buffer 来源。
