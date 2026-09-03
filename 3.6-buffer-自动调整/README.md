# 3.6 Buffer 自动调整

> 更新时间：2026-09-03  
> 本目录以当前 PySpark 实现为准，覆盖 baseline（原策略）与 guardrail（新策略）的正式任务、空跑任务、建表 SQL 和上游参考 SQL。

## 一句话说明

Buffer 是作用在策略补贴率上的乘法调节系数：大于 1 放大补贴，小于 1 缩小补贴，等于 1 不调整，从而让实际补贴率逐步贴近目标补贴率。

## 当前文件

| 文件 | 用途 |
|---|---|
| `auto_buffer_job.py` | baseline 正式任务，递推历史 buffer |
| `auto_buffer_job_new.py` | guardrail 正式任务，递推历史 buffer |
| `reset_previous_buffer_for_dry_run.py` | baseline 空跑任务，每天固定 `old_buffer=1.0` |
| `reset_previous_buffer_for_dry_run_new.py` | guardrail 空跑任务，每天固定 `old_buffer=1.0` |
| `create_auto_buffer_table.sql` | baseline 结果表 DDL，只执行一次 |
| `create_guardrail_auto_buffer_table_with_test_data.sql` | guardrail 结果表 DDL 与链路测试数据；正式运行后不要重复执行测试写入 |
| `reset_auto_buffer_before_launch.sql` | baseline 上线前重置历史空跑分区 |
| `kflower_strategy.pltf_union_stg_budget_control_dashboard.sql` | 实际率看板上游参考 |
| `kflower_strategy.pltf_union_stg_subsidy_detail_by_order.sql` | 订单补贴明细上游参考 |
| `kflower_strategy.pltf_union_stg_daily_exp_by_traceid.sql` | 实验组与 LambdaGroup 明细上游参考 |
| `supply.sql` | 运营侧供需补贴口径参考 |
| `3.6-buffer-自动调整-TODO路线.md` | 当前项目总结、实现结论和上线检查项 |

## 当前输入与输出

| 数据 | baseline | guardrail | 粒度 |
|---|---|---|---|
| 城市全集 | `whole_dw.dim_city` | 相同 | `city_id` |
| LambdaGroup 字典 | `kflower_strategy.platform_greedy_solver_lambda_dict` | 相同 | `stg_group` |
| 目标补贴率 | `kflower_strategy.platform_price_anchor_union_strategy_budget_dict` | `kflower_strategy.platform_price_anchor_union_strategy_budget_guardrail_dict` | `city_id` |
| 实际补贴数据 | `kflower_strategy.pltf_union_stg_budget_control_dashboard` | 相同 | 原始包含 `city_id + exp_group + lambda_group` |
| 切流数据 | `kflower_strategy.pltf_union_stg_exp_evaluation_pas_tag` | 相同 | `pid + exp_group` |
| 输出表 | `kflower_strategy.platform_union_strategy_budget_buffer_auto_baseline_by_city_object_stg` | `kflower_strategy.platform_union_strategy_budget_buffer_auto_guardrail_by_city_object_stg` | `dt + city_id + object_group + stg_group` |

`object_group` 当前固定为 `max_order_v1`，`stg_group` 的业务语义为 LambdaGroup。

## 键空间

每日键空间为：

```text
whole_dw.dim_city.dt=T 的 distinct city_id
×
platform_greedy_solver_lambda_dict 的 distinct stg_group
×
object_group=max_order_v1
```

当前代码读取字典表中的全部 `distinct stg_group`，没有只保留线上活跃 LambdaGroup。当前重点分析的线上组为：

```text
pltf_union_stg_v3_only_ds_acc_cr_thre
```

如果字典表还包含其他未生效或历史分组，这些分组也会被写入结果表；关联不到实际率时会保持旧 buffer，空跑时通常表现为 1。

## 日期口径

```text
T                    = ${BIZ_DATE_LINE}，也是最终输出分区 dt
state_date_type      = weekday（周一至周四）或 weekend（周五至周日）
previous_state_dt    = T 所属日期类型的上一期 T^-d
target_rate_dt       = previous_state_dt
actual_rate_dt       = previous_state_dt
traffic_switch_dt    = 自然日 T-1
```

日期示例：

| 输出 T | 类型 | old buffer / 目标率 / 实际率 | 切流检查 |
|---|---|---|---|
| 周四 | weekday | 周三 | 周三 |
| 周五 | weekend | 上周日 | 周四 |
| 周六 | weekend | 周五 | 周五 |
| 周日 | weekend | 周六 | 周六 |
| 周一 | weekday | 上周四 | 周日 |
| 周二 | weekday | 周一 | 周一 |

因此周一和周五会跨越另一套日期类型回看，这是当前两条状态链分别维护的预期行为。

## 实际补贴率

看板中同一城市与 LambdaGroup 可能存在多个 `exp_group`。任务先排除全国、城市汇总和未分组 Lambda，再按 `city_id + lambda_group` 汇总：

```text
actual_rate
= ROUND(
    (SUM(cost) + SUM(delay_cost)) / SUM(gmv_amt) * 100,
    2
  )
```

其中：

- `cost`：当日核销补贴；
- `delay_cost`：延迟核销补贴；
- `gmv_amt`：与看板一致的完单 GMV；
- 实际率和目标率都使用百分数值，例如 `3.0` 表示 3%。

当前代码先将实际率保留两位小数，再参与 buffer 计算；实际率很小时，舍入可能放大调整比例。

## Buffer 计算

正式任务：

```text
raw_buffer = old_buffer × target_rate / actual_rate
new_buffer = min(2.99, raw_buffer)
```

空跑任务每天固定：

```text
old_buffer = 1.0
new_buffer = min(2.99, target_rate / actual_rate)
```

下列任一条件成立时不调整：

- 自然日 `T-1` 存在 PID 命中多个实验组；
- `target_rate` 缺失或小于等于 0；
- `actual_rate` 缺失或小于等于 0。

不调整时，正式任务沿用历史 `old_buffer`，空跑任务输出 1。

当前只设置绝对上限 `2.99`，不设置 buffer 下限和单日调整比例限制，因此出现很低的正 buffer 是公式允许的结果。

## 切流逻辑

切流只作为全局开关，不参与实验组到 LambdaGroup 的映射：

```text
读取自然日 T-1 的 PAS 数据
→ 按 pid 统计 exp_group 范围
→ 任一 pid 的 min(exp_group) != max(exp_group)
→ has_exp_traffic_switch=1
→ 当期全部 buffer 不调整
```

## 正式任务与空跑任务

两类任务的目标率、实际率、切流、键空间、公式和输出分区均相同，主要差异是：

| 项目 | 正式任务 | 空跑任务 |
|---|---|---|
| old buffer | 读取同类型上一期结果 | 每天固定 1.0 |
| extra_data | 继承上一期，缺失时为空 | 固定为空 |
| 状态是否累计 | 是 | 否 |
| 输出表 | 正式表 | 当前仍是同一张正式表 |

空跑和正式任务会覆盖同一张表的同一个 `dt=T` 分区，不能在同一天同时运行。正式上线前必须先停止空跑调度。

## baseline 与 guardrail

两套代码结构和公式完全一致，只有两类表不同：

- baseline 读取原策略目标率表并写 baseline buffer 表；
- guardrail 读取新策略目标率表并写 guardrail buffer 表。

## 运行顺序

1. 独立执行建表 SQL；
2. 空跑阶段仅运行对应的 `reset_previous_buffer_for_dry_run*.py`；
3. 检查目标率、实际率匹配率、极端值与上限命中；
4. 上线前停止空跑；
5. 重置空跑可能污染的历史状态分区；
6. 启动对应的正式 `auto_buffer_job*.py`；
7. 下游发布任务读取当天 `dt=T` 分区。

## 当前需要注意

1. `reset_auto_buffer_before_launch.sql` 仍使用旧表 `platform_union_stg_lambda_dict_manually_update`，与四个 PySpark 使用的 `platform_greedy_solver_lambda_dict` 不一致，上线前需要统一。
2. guardrail 建表文件包含测试数据写入，正式链路接入后不要重复执行该 INSERT。
3. `dim_city.dt=T`、目标率 `T^-d`、实际率 `T^-d` 和 PAS 自然日 `T-1` 分区必须在任务执行前就绪。
4. 业务调休日目前没有单独日历覆盖，代码仅按自然星期划分 weekday/weekend。
5. 当前没有下限或日调整幅度限制，需继续观察极低值、2.99 命中率和连续命中天数。
