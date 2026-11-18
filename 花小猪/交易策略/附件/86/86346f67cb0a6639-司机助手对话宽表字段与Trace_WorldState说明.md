# 第一章：按功能理解全部字段

`kflower_strategy.dws_driver_assistant_dialogue_di` 是一张**对话级宽表**，共 **64 个字段，包含分区字段 `dt`**。以下基于此前查到的字段注释与 DDL。

**核心粒度：一行对应一个 dialogue；一个 session 包含多轮 dialogue；一轮 dialogue 内包含多条消息、多次模型或工具调用。**

```text
session_id
  ├─ dialogue_id：round_no = 1
  ├─ dialogue_id：round_no = 2
  └─ ……
       └─ 消息、模型调用、工具调用及返回结果
```

## 1. 身份、对话定位与时间：9 个字段

| 字段 | 含义 |
|---|---|
| `dt` | 对话业务日期，**分区字段** |
| `company_id` | 品牌 ID |
| `city_id` | 城市 ID |
| `driver_id` | 司机 ID |
| `session_id` | 会话 ID，串联多轮对话 |
| `dialogue_id` | 对话 ID，定位具体一轮 |
| `round_no` | dialogue 在 session 内的轮次 |
| `dialogue_start_time` | 对话开始时间 |
| `dialogue_end_time` | 对话结束时间 |

**用途：**定位样本、按轮次拼接 session、关联司机信息。跨日 session 是否存在需验证，不能默认单个 `dt` 就包含完整 session。

## 2. 对话内容与调用轨迹：6 个字段

| 字段 | 含义 |
|---|---|
| `user_question` | 首条用户可见输入 |
| `assistant_final_answer` | 最终对客回复 |
| `assistant_reply_full_text` | 按时间拼接全部非空、用户可见的 Assistant 回复 |
| `assistant_reply_full_text_with_tool` | 可见回复与工具调用、返回轨迹的拼接文本 |
| `message_id_list` | 消息 ID 列表 |
| **`agent_call_detail_map`** | 结构化事件明细，包含消息、工具参数、返回结果等 |

**用途：**前两个字段适合快速看问答；完整过程分析优先使用 `agent_call_detail_map`，拼接文本适合人工阅读。

## 3. 场景、意图与工具路径：8 个字段

| 字段 | 含义 |
|---|---|
| `skill_name` | 主场景 Skill；未解析到为 `other` |
| `topic` | 主场景知识主题；未解析到为 `other` |
| `intent` | 主场景意图；未解析到为 `other` |
| `sub_intent` | 子意图；没有时为空 |
| `scene_source` | 场景来源：`search_knowledge`、`skill`、`default` |
| `scene_parse_status` | 解析状态：`success`、`skill_only`、`no_tool_call`、`invalid_arguments` |
| `tool_name_list` | 实际调用工具名，去重排序后以逗号连接 |
| `tool_name_sequence` | 工具名称与参数按调用顺序以 `>` 连接，保留重复 |

**重点：**工具覆盖情况看 `tool_name_list`；调用顺序、重复调用看 `tool_name_sequence`。场景字段只描述主场景，不能替代完整轨迹。

## 4. 请求、消息与执行状态：13 个字段

| 字段 | 含义 |
|---|---|
| `ask_cnt` | 全部 Ask 请求数，包含主交互与 AutoExec |
| `auto_exec_ask_cnt` | AutoExec 请求数 |
| `interaction_type` | 主交互类型：`Input`、`Click`，异常时为 `Other` |
| `status` | 主交互的最终状态 |
| `auto_exec_status` | AutoExec 最终状态；没有时为空 |
| `is_interrupted` | 任一 Ask 为 `Stopped` 时取 1 |
| `message_cnt` | 消息总数 |
| `user_message_cnt` | 用户消息数 |
| `assistant_message_cnt` | Assistant 消息数 |
| `tool_message_cnt` | 工具消息数 |
| `system_message_cnt` | 系统消息数 |
| `content_parse_failed_cnt` | 正文解析失败消息数 |
| `message_source_dt` | 消息源业务日期 |

**重点：**一轮 dialogue 可以有多个 Ask；消息数、Ask 数、模型调用数、工具调用数是不同口径。

## 5. 性能与模型消耗：11 个字段

| 字段 | 含义 |
|---|---|
| `duration_ms` | dialogue 下全部 Ask 的**累计耗时**，毫秒 |
| `first_content_latency_ms` | `path=new` 主请求首字延迟，毫秒 |
| `llm_call_count` | 模型调用次数 |
| `tool_call_count` | 逻辑工具调用次数 |
| `llm_prompt_tokens` | 输入 Token 总数 |
| `llm_completion_tokens` | 输出 Token 总数 |
| `llm_total_tokens` | 总 Token 数 |
| `llm_cached_tokens` | 缓存输入 Token 总数 |
| `llm_uncached_tokens` | 非缓存输入 Token 总数 |
| `llm_reasoning_tokens` | 推理 Token 总数 |
| `llm_usage_detail_map` | Assistant 消息级 usage 明细，value 为原始 usage JSON |

**重点：**`duration_ms` 不等于对话结束时间减开始时间；各 Token 字段存在包含关系，不能全部相加。

## 6. 卡片行为与用户反馈：11 个字段

| 字段 | 含义 |
|---|---|
| `card_show_cnt` | 卡片展现次数 |
| `card_click_cnt` | 卡片点击次数 |
| `card_show_title_list` | 展现标题，按事件时间以 `>` 连接，保留重复 |
| `card_click_title_list` | 点击标题，按事件时间以 `>` 连接，保留重复 |
| `card_click_bt_txt_list` | 点击按钮名称，按事件时间以 `>` 连接，保留重复 |
| `like_cnt` | 点赞次数 |
| `dislike_cnt` | 点踩次数 |
| `session_feedback_comment` | Session 级评论反馈 |
| `session_feedback_time` | Session 级末次评论提交时间 |
| `session_feedback_submit_cnt` | Session 内评论提交次数 |
| `is_session_feedback_anchor` | 反馈 session 首个 dialogue 标记 |

**重点：Session 反馈会重复出现在该 session 的多行中。统计 Session 反馈时，仅汇总 `is_session_feedback_anchor = 1` 的记录。**

## 7. 司机状态、位置与数据更新：6 个字段

| 字段 | 含义 |
|---|---|
| `latest_order_diagnosis_state_json` | 当前 dialogue 最新一次订单诊断的司机快照与诊断事实 |
| **`worldstate_info`** | 可审计的状态 JSON，包含观测状态、模拟补值状态及来源 |
| `driver_location_lng` | 对话开始前、当日最近有效完整分钟的经度 |
| `driver_location_lat` | 对应纬度，与经度取自同一条记录 |
| `driver_location_time` | 采用的位置记录时间；未找到为 NULL |
| `message_source_update_time` | 消息源最新更新时间 |

**重点：**位置是对话前的分钟级记录；`latest_order_diagnosis_state_json` 是最新诊断状态，不能直接视为 session 初始状态。

# 第二章：如何用两个核心字段构建 Session Trace 与初始 WorldState

先明确这两个字段的分工：

| 字段 | 主要回答的问题 |
|---|---|
| `agent_call_detail_map` | **这轮发生了什么：谁说了什么、调用什么工具、参数和结果是什么？** |
| `worldstate_info` | **这轮参考了什么状态：哪些是观测值、哪些是补值、来源是否可信？** |

**它们都以 dialogue 为单位。要得到 session 级产物，必须跨 dialogue 拼接和校验。**

## 1. `agent_call_detail_map`：还原消息与工具交互流

### 结构

Hive 类型为 `map<string,string>`，value 需要再次解析 JSON：

```text
agent_call_detail_map
  ├─ "000001" → 事件 JSON 字符串
  ├─ "000002" → 事件 JSON 字符串
  └─ ……
```

| 事件字段 | 作用 |
|---|---|
| `call_seq` | dialogue 内事件顺序 |
| `call_time` | 事件时间 |
| `message_id` | 原始消息标识 |
| `role` | user / system / assistant / tool |
| `call_type` | 用户消息、系统消息、助手回复、工具调用、工具结果 |
| `content_raw` | 原始消息 JSON 字符串 |
| `tool_call_id` | 匹配工具调用与结果 |
| `tool_name` | 工具名称 |
| `tool_arguments` | 显式调用参数，JSON 字符串 |
| `tool_result` | 关联的工具返回封装 |
| `content_parse_status` | 内容解析状态，不等于工具执行状态 |

### 结合此前样本

“为什么单子这么少”这一轮有 **18 个事件、6 次工具调用**，可还原为：

```text
用户提问 + 时间上下文 + System
  → 助手前置回复
  → search_knowledge + order_diagnosis
  → 助手中间回复
  → query_mode + query_dispatch_mode
  → recommend_hot_zone：卡片容量不足，失败
  → show_entry：成功展示选单大厅
  → 最终回复
```

**还原时有两个关键去重规则：**

- 同一条 Assistant 消息可能拆成“回复 + 多个工具调用”事件，`message_id` 相同。还原消息列表时不能重复加入其 `content_raw`。
- 工具结果既可能嵌在调用事件中，又有独立结果事件。按 `tool_call_id` 配对，避免重复插入。

### 如何构建 Session Trace

建议同时保留两种视图：

| 产物 | 构建方式 |
|---|---|
| **事件流 `events`** | 收集 session 全部 dialogue，按轮次和各轮 `call_seq` 排序，保留事件边界 |
| **消息流 `messages`** | 从事件中恢复原始消息，按消息标识合并拆分条目，匹配工具调用与结果 |

拼接后至少校验：

- session 各轮是否取全，是否跨日或有缺轮；
- 工具调用是否都有对应结果，是否存在孤立结果；
- 是否有正文解析失败；
- 后续 dialogue 是否重复携带历史消息或 System，需要按实际构造规则处理。

**能力边界：可以构建已落表的消息与工具交互 trace；不能仅据此保证完整模型请求、工具 schema、底层重试、精确并发与耗时均已还原。**

## 2. `worldstate_info`：构建带来源说明的初始状态

### 结构

此前样本使用 `worldstate_info_v2`：

```text
worldstate_info
├─ reference_time                 状态参考时间
├─ 身份与对话标识
├─ observed_worldstate            观测状态
│  ├─ driver_profile              画像、车辆及身份属性
│  ├─ realtime_state              位置、在线、模式、诊断等动态信息
│  └─ rewards                     权益信息
├─ agent_worldstate               补值后的模拟状态
├─ source_meta                    来源、匹配、可注入性
└─ fill_provenance                逐字段补值记录
```

| 部分 | 应如何使用 |
|---|---|
| `observed_worldstate` | 作为真实状态重建的主要依据，保留缺失值并检查来源 |
| `agent_worldstate` | 作为模拟执行候选输入，不能全部视为真实观测 |
| `source_meta` | 判断参考时间、数据匹配及可注入性 |
| `fill_provenance` | 区分供体补值、默认值及对应来源 |

### 此前样本说明了什么

| 信息 | 实际情况 | 对初始状态的影响 |
|---|---|---|
| 参考时间 | 来自本轮 `dialogue_start_time` | 是 dialogue 参考时点，不是逐调用快照 |
| 在线及接单设置 | 有观测值，且与部分工具返回对应 | 可还原部分动态设置 |
| 能源类型、司机身份、网络状态等 | 观测为空，模拟状态填入默认值 | 不能当作真实事实 |
| 派单过滤证据 | 使用其他司机供体 | 不能作为该司机真实过滤记录 |
| 热区 | 使用同品牌同日期的其他司机供体，存在地域不一致 | 不适合还原真实附近热区 |
| 权益 | 信息缺失 | 无法还原完整权益状态 |
| 可注入性 | `non_injectable_defaulted` | 本条不能直接视为合格的完整状态样本 |

其中，车辆证照从观测 `null` 补为模拟 `true`，但来源明确标记：

```text
has_vehicle_license_missing_without_donor
```

**“字段有值”不等于“事实完整”。默认值和供体值必须保留来源标签。**

### 如何得到 Session 初始 WorldState

建议按以下口径构建：

1. **取齐 session 全部 dialogue，确认最早一轮。**
2. 选择最早一轮、且参考时间符合起点要求的 `worldstate_info`，作为**候选初始状态**。
3. 分别保留 `observed_worldstate`、`agent_worldstate` 和来源信息。
4. 检查缺失字段、补值字段、地域一致性及 `injectability_status`。
5. **不能直接用后续轮次状态填补初始动态状态**，否则可能把执行后的结果泄漏到起点。

只有确认首轮未缺失、参考时间符合要求、工具必需字段齐全且来源合格，才能将它标记为可用的 session 初始状态。

## 3. 对后续数据建设的建议

建议每个 session 最终输出以下结构：

```text
session
├─ dialogues                  原始轮次与标识
├─ trace_events               完整事件视图
├─ trace_messages             去重、配对后的消息视图
├─ initial_worldstate
│  ├─ reference_time
│  ├─ observed_worldstate
│  ├─ agent_worldstate
│  ├─ source_meta
│  └─ fill_provenance
└─ quality_checks
   ├─ 轮次完整性
   ├─ 调用与结果配对情况
   ├─ 内容解析失败情况
   └─ 状态缺失、补值及可注入性
```

**最终判断：这两个字段适合作为 Session Trace 和初始 WorldState 的核心来源，但产物必须带完整性与来源校验。Trace 可以还原已记录的交互过程；WorldState 能否作为完整初始环境，需要逐条判定，不能统一视为完整真实快照。**
