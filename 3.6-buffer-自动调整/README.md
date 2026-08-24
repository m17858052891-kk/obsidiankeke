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
   - 首次初始化和每日状态更新已合并为一个任务。
   - 仅当当前 buffer 表完全为空且 baseline 没有任何历史分区时，使用两套日期城市全集、5 类城市范围规则和 9 条 `stg_group → city_scope` 映射，展开 weekday 2070、weekend 1997 个有效键，初始 `union_buffer=1.0`；当前表为空但 baseline 已有历史时阻断，避免误重置。
   - weekday/weekend 两个分区都已存在时跳过初始化；仅存在一个分区时直接阻断，避免残缺状态被静默补齐。
   - 不创建实验组映射表；实验组到 LambdaGroup 的映射属于运筹平台。
   - 按 `STAT_DT=${BIZ_DATE_LINE}` 的自然星期得到唯一 `state_date_type`，每日只执行一次通用计算链路。
   - 不在同一 `dt` 同时计算两套状态，也不对两个非空分支执行 `UNION ALL`。
   - 直接读取当前 buffer 表对应 `date_type` 分区的 `union_buffer` 作为 `old_buffer`，不查询历史值，也没有冷启动回退。
   - 严格执行 `union_buffer = min(2.99, old_buffer × target_rate / actual_rate)`；不设置 buffer 下限或单日调整比例上下限，也不依赖规则配置表。
   - 先写 baseline 自动结果表 `dt=STAT_DT`，再覆盖当前 buffer 表的本次 `date_type` 分区；另一分区保持不变。baseline 只保留 `dt` 分区，不增加 `date_type`。
   - baseline 的日分区同时作为幂等日志：重跑发现该分区已存在时复用结果，仅重新同步当前 buffer，避免重复调整。
   - 若已存在晚于 `STAT_DT` 的快照，任务阻断该历史日期回写，防止补数把当前状态倒退；历史回放应使用独立影子表。
   - 当前按约定不在任务内执行表结构比对、业务键唯一性或输入输出行数一致性校验；代码假定上游表及建表 SQL 符合约定。

2. `3.6-buffer-自动调整-TODO路线.md`
   - 完整口径、字段血缘、状态更新/最终发布分层和待确认项。

## 数梦运行参数

```text
BIZ_DATE_LINE     = 状态统计日 stat_dt（T-1）
ACTUAL_RATE_TABLE = 已归因完成的 T-1 实际率明细表
```

`ACTUAL_RATE_TABLE` 必须至少提供：

```text
dt
city_id
lambda_group
actual_rate
```

`actual_rate` 与 `target_rate` 都使用百分数值，例如 `3.0` 表示 `3%`。

## 上线前仍需补齐

- 实际补贴率上游根据运筹平台映射完成实验归因，并向本任务输出 `city_id + lambda_group`粒度。
- 目标补贴率取生效日 T。目标表读取 `dt=BIZ_DATE_LINE`：该物理分区由源规划表
  `dt=BIZ_DATE_LINE+1` 生成，业务内容对应 T 日目标，因此不再单独传 `TARGET_DT`。
- `actual_rate<=0` 时当前代码保持 `old_buffer` 以避免除零；`target_rate=0` 且实际率有效时按公式得到 `0`。
- 最终发布任务应按 `publish_dt=stat_dt+1` 选择日期类型，并读取当前 buffer 表对应的 `date_type` 分区；不应与本状态更新任务混为一步。
