已按 **2026-10-20 当前正式部署代码**核对，并整理为[完整说明文档](/Users/didi/Desktop/司机助手/线上评估集生产流程、完整样本与下载说明-含expected与simulation_spec-20261020.md)。文档包含两条完整样本、字段说明、执行命令和绝对路径。

## 一、先看主线

```text
线上对话数仓表
    ↓ 抽取目标轮及前置历史
候选样本：问题 + 历史 + WorldState
    ↓ 代码校验、去重
    ↓ Codex 参考草标 + 独立覆盖草标
    ↓ 按质量、场景覆盖和多样性选样
    ↓ 从 Agent Runtime 知识 SOP 解析预期行为
expected 草稿 → 人工复核确认
    ↓ Codex 判断司机沟通人格，程序完成人格分配
simulation_spec
    ↓ 整理中文仿真场景，校验完整结构
发布到 PostgreSQL
    ↓ Platform 导出
完整评估集 JSONL
```

**一条目标轮就是一道题。**`expected` 规定助手应该怎样处理；`simulation_spec` 规定多轮仿真中的司机按什么场景、人格继续交流。

## 二、expected 怎么生成

| 内容 | 生成方式 |
|---|---|
| 场景、主题、意图、是否澄清 | Codex 根据当前问题和前置对话，选择本批 Agent Runtime 分类目录中的值 |
| 必要工具 | Codex 判断必要性，代码校验工具目录和结构 |
| 预期行为 `behavior` | 从对应知识 SOP 解析；澄清和其他场景使用固定规则 |
| 最终评价标准 | 人工复核、修正、确认后形成终标 |

参考草标不读取目标轮的助手回答、工具结果或评分。**线上回复用来还原执行过程，不直接作为标准答案。**

对应代码在 Platform 的 `scripts/online_evalset_pipeline/`：取数 → 预处理 → 草标 → 选样 → 行为解析 → 冻结 → 资产生成。

## 三、simulation_spec 怎么生成

| 字段 | 来源 |
|---|---|
| `topic`、`intent`、`sub_intent` | 复制已确认的 `expected.route` |
| `actor_type` | Codex 人格判断，加程序分配 |
| `scene` | 整理成当前 Simulation 接受的中文场景 |

人格判断只看**历史司机原话和当前问题**，不看助手回复、WorldState 或 expected：

- **明确人格**：直接保留。
- **边界人格**：只允许在有原话依据的备选内调整。
- **信号不足**：程序按参考分布缺口分配，审计明确记录。

因此，最终人格包含语义判断和覆盖分配两种来源，不能都理解为模型从司机原话确定的人格。

对应代码在 `scripts/evalset_persona_labeling/`，执行顺序为：

```text
prepare → Codex 写 judgments.jsonl → import → verify
```

**当前需要显式衔接一步：**人格脚本仍原样复制英文 `scene`，而当前 Simulation 要求中文。现有 v3 使用后续整理的 `labeled.scene-zh.jsonl`，例如 `listen → 听单`、`reward → 营销活动`。人格脚本本身不自动转换场景、不写数据库、不发布集合。

## 四、最终一条样本包含什么

```text
样本
├── input              当前问题、历史、WorldState
├── expected
│   ├── route          预期分类及澄清要求
│   ├── tool_calls     必要工具
│   └── behavior       预期行为与边界
├── simulation_spec    仿真场景、主题、意图、人格
├── source             来源与当前集合 ID
└── reporting          报表分类
```

文档中的两条完整 JSON 均取自当前 v3，保留全部历史、WorldState 和两类标签，没有删减字段。

以下两条来自上方链接所对应、已与 PostgreSQL 核对的 v3 标准导出。JSON 保留全部原始字段和值，包括完整 WorldState、历史内容、`expected` 和 `simulation_spec`。人格的语义判断或分布分配来源需查看对应任务的 `audit.json`。

### 1. 无历史样本

**当前问题：**他妈的这么多单子都不派，有违节。

该题没有前置对话，`input.history` 为空数组。预期通过知识检索和接单诊断处理无单诉求；最终仿真人格为猜疑抗衡型。

```json
{
  "schema_version": "evaluation_sample_v1",
  "sample_id": "7dce09b8b7750e36fa4a53884b8cbeed81e1e3012564cc2b43074ebc0b6e47c9",
  "sample_type": "base_sample",
  "input": {
    "question": "他妈的这么多单子都不派，有违节。",
    "history": [],
    "world_state": {
      "rewards": {
        "marketing": null
      },
      "driver_profile": {
        "age": 59,
        "city": "22",
        "brand": "花小猪打车",
        "gender": "男",
        "city_name": "石家庄市",
        "driver_id": "615727627983401",
        "driving_age": 29,
        "energy_type": "fuel",
        "display_name": "肖师傅",
        "driver_cycle": "active",
        "business_line": "",
        "driver_identity": "fulltime",
        "current_city_name": "石家庄市",
        "has_vehicle_license": true,
        "historical_cancel_count": 0,
        "acceptable_vehicle_types": []
      },
      "realtime_state": {
        "scene": {
          "only_shunlu": false,
          "accept_kuobo": true,
          "accept_airport": true,
          "accept_train_station": true
        },
        "shunlu": null,
        "city_id": 22,
        "dispatch": {
          "special_mode": "auto",
          "zengliang_mode": "auto",
          "stable_income_mode": "auto"
        },
        "hot_zones": [
          {
            "tags": [
              "大单密集"
            ],
            "area_m": 302,
            "reward": null,
            "area_cr": 0.0,
            "city_id": 22,
            "location": {
              "lat": 38.04089,
              "lng": 114.50138
            },
            "area_name": "中山东路|中国石化(平安大街加油站)",
            "area_call_num": 18,
            "area_driver_num": 0
          }
        ],
        "is_online": true,
        "filter_rules": [],
        "current_coord": {
          "point": {
            "latitude": 38.040974167052795,
            "longitude": 114.50474491548358
          },
          "coord_type": 2
        },
        "pk_order_info": {
          "win_num": 0,
          "fail_num": 0,
          "pk_order_num": 0,
          "fail_reason_detail": ""
        },
        "network_status": "good",
        "online_minutes": 30,
        "raise_hand_info": {
          "grab_click_order_num": 0,
          "grab_raise_hand_rate": 0.0,
          "semi_assign_raise_hand_rate": 0.0,
          "semi_assign_accept_order_num": 0,
          "grab_click_with_raise_hand_order_num": 0,
          "semi_assign_accept_with_raise_hand_order_num": 0
        },
        "waiting_minutes": 14,
        "listening_minutes": 29,
        "all_potential_order_num": 8,
        "dispatch_filter_evidence": [
          {
            "rule_key": "34",
            "filtered_count": 1
          }
        ],
        "unlistenable_time_minutes": 1,
        "spatiotemporal_adjustments": []
      },
      "reference_time": "2026-09-21T15:02:03.000+08:00"
    }
  },
  "expected": {
    "route": {
      "clarification_level": "none",
      "scene": "listen",
      "category_action": "classify",
      "topic": "接单机会与无单改善",
      "intent": "接单机会与无单改善",
      "sub_intent": "",
      "topic_action": "classify_topic_intent"
    },
    "tool_calls": [
      {
        "name": "search_knowledge",
        "arguments": {}
      },
      {
        "name": "order_diagnosis",
        "arguments": {}
      }
    ],
    "behavior": "检索接单机会知识并诊断当前接单情况，不先要求澄清或用设置查询代替诊断。依据结果先处理强阻断；无阻断时推进一个适配建议、直接好处和行动，不臆测个人未获派单原因，不保证来单。后续配置、地点、大厅查询仅在对应推荐条件满足时执行。"
  },
  "source": {
    "sample_set_id": "online-random-test200-0920-0922-label-v3-20261016",
    "source_sample_id": "7dce09b8b7750e36fa4a53884b8cbeed81e1e3012564cc2b43074ebc0b6e47c9",
    "source_type": "online_observed"
  },
  "reporting": {
    "category_l1": "听单与单量问题",
    "category_l2": "接单机会与无单改善",
    "category_l3": "接单机会与无单改善"
  },
  "simulation_spec": {
    "scene": "听单",
    "topic": "接单机会与无单改善",
    "intent": "接单机会与无单改善",
    "actor_type": "猜疑抗衡型",
    "sub_intent": ""
  }
}
```

### 2. 有历史样本

**当前问题：**单弹出来抢不到

历史包含司机上一轮问题、服务器时间消息和助手的澄清提问；当前“单弹出来抢不到”是在回答该澄清。预期处理已出现订单但未抢到的问题；最终仿真人格为焦灼黏着型。

```json
{
  "schema_version": "evaluation_sample_v1",
  "sample_id": "128dc17c29d7b351f9d0f3f57b08f4c3c21970f55ec0cc728c3580dba2df1bc6",
  "sample_type": "history_sample",
  "input": {
    "question": "单弹出来抢不到",
    "history": [
      {
        "role": "user",
        "content": "怎么抢不到单"
      },
      {
        "role": "user",
        "content": "<runtime_context source=\"server_clock\">\n当前时间：2026-09-20T11:59:31+08:00\n时区：Asia/Shanghai\n说明：仅用于理解上一条请求中的相对时间，不要单独回答本消息。\n</runtime_context>"
      },
      {
        "role": "assistant",
        "content": "师傅，别着急，我先了解一下您的情况。您是一直没等到单，还是刚才有单弹出来但没抢到？",
        "reasoning_content": "好的，司机说\"怎么抢不到单\"，这是一个关于听单接单的问题。根据路由规则，我需要先确定具体意图。\n\n\"抢不到单\" - 这可能有两种情况：\n1. 一直没单、少单 - 走`接单机会与无单改善`\n2. 已经看到播报但没抢到 - 走`订单获取与播报异常`\n\n根据3.4节澄清规则：\"为什么抢不到单\"无可继承上下文时，需要区分一直没单、个人抢单模式还是某笔订单没抢到。但我先看看能否通过工具诊断来获取更多信息。\n\n让我先调用Knowledge来确定处理路径。这个应该是听单场景下的。不过我需要先确认一下是\"一直没单\"还是\"抢单失败\"。\n\n等等，根据3.3节关键相邻边界：\n- \"一直没收到订单、没派到或等很久走听单\"\n- \"已经看到或播报某单但没拿到、获取失败或页面异常走'订单获取与播报异常'\"\n\n现在没有上下文，司机只说\"怎么抢不到单\"，有两种可能，我需要做窄澄清。\n\n不过，先让我调用一下skill看看。根据Skill系统，listen skill可以处理没单问题。\n\n等等，根据执行架构硬约束，我应该先调用`search_knowledge`来获取Knowledge，而不是调用skill。让我看看2.1节：\n\n\"执行链固定为：System完成场景、Topic和Intent路由，调用`search_knowledge`加载对应Knowledge，再按Knowledge调用必要的业务工具。本Agent不使用Skill系统；禁止调用名称为`skill`、`query_skill`、`query_skill_detail`或其他用于加载Skill的工具，也不读取Skill文件。\"\n\n好的，我应该先调用search_knowledge。但首先，根据3.4节，我需要做澄清。\n\n\"为什么抢不到单\"无可继承上下文时，需要区分一直没单、个人抢单模式还是某笔订单没抢到，可问：\"师傅，您是一直没单，还是刚才有一单没抢到？\"\n\n不过根据首次工具调用硬门禁，我需要先发出一条独立、非空、司机可见的中文短句，说明正在处理什么，然后再调用工具。\n\n但澄清问题本身也是需要先发消息的。让我先直接做澄清吧。\n\n不对，让我再想想。根据路由步骤，我需要先确定唯一路径。司机说\"怎么抢不到单\"，这个\"抢\"字可能暗示他已经是抢单模式。但按照3.3节：\n\n\"接单目标与设置：没有点名具体模式、开关或筛选项时，'接单、派单、快速接单、安排单子、多久或何时发单'等表达的是争取订单机会，走`接单机会与无单改善`，不先追问模式\"\n\n但这里司机明确说\"抢不到单\"，说明他看到了单但没抢到？还是说一直没单？\n\n我觉得这里确实需要澄清。根据3.4节，我应该问一句窄问题。\n\n好，我准备先发一个短句，说明正在处理，然后问澄清问题。"
      }
    ],
    "world_state": {
      "rewards": {
        "marketing": null
      },
      "driver_profile": {
        "age": 54,
        "city": "3",
        "brand": "花小猪打车",
        "gender": "男",
        "city_name": "广州市",
        "driver_id": "615727097322943",
        "driving_age": 20,
        "energy_type": "fuel",
        "display_name": "韩师傅",
        "driver_cycle": "active",
        "business_line": "",
        "driver_identity": "fulltime",
        "current_city_name": "广州市",
        "has_vehicle_license": true,
        "historical_cancel_count": 0,
        "acceptable_vehicle_types": []
      },
      "realtime_state": {
        "scene": {
          "only_shunlu": false,
          "accept_kuobo": true,
          "accept_airport": false,
          "accept_train_station": true
        },
        "shunlu": null,
        "city_id": 3,
        "dispatch": {
          "special_mode": "auto",
          "zengliang_mode": "auto",
          "stable_income_mode": "auto"
        },
        "hot_zones": [
          {
            "tags": [
              "大单密集"
            ],
            "area_m": 815,
            "reward": null,
            "area_cr": 0.0,
            "city_id": 3,
            "location": {
              "lat": 31.46143,
              "lng": 104.750213
            },
            "area_name": "人民公园|肯德基(新涪城店)",
            "area_call_num": 56,
            "area_driver_num": 0
          }
        ],
        "is_online": false,
        "filter_rules": [],
        "current_coord": {
          "point": {
            "latitude": 23.574686453149795,
            "longitude": 113.51585484674409
          },
          "coord_type": 2
        },
        "pk_order_info": {
          "win_num": 0,
          "fail_num": 0,
          "pk_order_num": 0,
          "fail_reason_detail": ""
        },
        "network_status": "good",
        "online_minutes": 0,
        "raise_hand_info": {
          "grab_click_order_num": 0,
          "grab_raise_hand_rate": 0.0,
          "semi_assign_raise_hand_rate": 0.0,
          "semi_assign_accept_order_num": 0,
          "grab_click_with_raise_hand_order_num": 0,
          "semi_assign_accept_with_raise_hand_order_num": 0
        },
        "waiting_minutes": 0,
        "listening_minutes": 2,
        "all_potential_order_num": 0,
        "dispatch_filter_evidence": [
          {
            "rule_key": "34",
            "filtered_count": 1
          }
        ],
        "unlistenable_time_minutes": 1,
        "spatiotemporal_adjustments": []
      },
      "reference_time": "2026-09-20T12:00:15.000+08:00"
    },
    "target_turn_index": 1
  },
  "expected": {
    "route": {
      "clarification_level": "none",
      "scene": "dispatch",
      "category_action": "classify",
      "topic": "订单获取与播报异常",
      "intent": "订单获取与播报异常",
      "sub_intent": "",
      "topic_action": "classify_topic_intent"
    },
    "tool_calls": [
      {
        "name": "search_knowledge",
        "arguments": {}
      }
    ],
    "behavior": "承接已出现订单但没抢到，说明无法核实本次抢单原因；必要时给一个尚未尝试的排查动作。不强制查询接单模式，不要求切自动抢单，不承诺切换后不用抢或提高抢单成功率。 本条历史未提供与确认路由一致且覆盖当前问题的知识，须本轮检索。"
  },
  "source": {
    "sample_set_id": "online-random-test200-0920-0922-label-v3-20261016",
    "source_sample_id": "128dc17c29d7b351f9d0f3f57b08f4c3c21970f55ec0cc728c3580dba2df1bc6",
    "source_type": "online_observed"
  },
  "reporting": {
    "category_l1": "派单与订单问题",
    "category_l2": "订单获取与播报异常",
    "category_l3": "订单获取与播报异常"
  },
  "simulation_spec": {
    "scene": "派单接单",
    "topic": "订单获取与播报异常",
    "intent": "订单获取与播报异常",
    "actor_type": "焦灼黏着型",
    "sub_intent": ""
  }
}
```

## 五、如何发布构建任务、保存与下载

### 1. 只需说明主要要求

向 Codex 下达任务时，主要说清楚：

- **数据日期**：从哪天到哪天的线上数据中取样。
- **样本数量**：最终需要多少条。
- **覆盖重点**：需要哪些场景、是否有特定比例；没有特殊要求就随机抽样、兼顾场景覆盖。
- **交付目标**：完成 expected 和 simulation_spec 打标，交付复核结果、完整文件及保存路径；如需正式发布，一并说明。

Runtime 未特别指定时，使用执行时的当前正式部署并记录版本。任务编号、目录和执行命令由 Codex 处理，无需逐项填写。

### 2. 一句话任务示例

> 请从 2026 年 10 月 17 日至 19 日的线上数据中生成 200 条评估样本，使用当前正式 Runtime，兼顾听单、派单、奖励、澄清和其他场景，保留可获取的历史与 WorldState，完成 expected 和 simulation_spec 打标。人工复核确认后发布为新版本，给我完整文件、场景及人格分布、保存路径和下载入口。

上面仅为任务说明示例。实际执行主线是：**取数 → 校验与选样 → expected 草标及人工确认 → simulation_spec 打标与校验 → 发布 → 下载核对。**

### 3. 保存位置与下载入口

- **正式数据**：PostgreSQL 中已发布的 SampleSet。
- **取数及 expected 生产文件**：`data/online_evalset_pipeline/<run-id>/`。
- **人格任务文件**：`scripts/evalset_persona_labeling/tasks/<task-id>/`。
- **完整标准下载**：`GET /api/platform/sample-sets/{sample_set_id}/samples-file`。
- **标注与审计下载**：`GET /api/platform/sample-sets/{sample_set_id}/audit-samples-file`。

当前 v3 已重新下载：[完整 200 条 JSONL](/Users/didi/Desktop/司机助手/artifacts/online-evalset-doc-review-20261020/v3-current.jsonl)。已确认与 PostgreSQL 逐条一致，200 条均完整保留 `simulation_spec`，并通过当前 Simulation 的结构校验。

当前正式版本：`release-a-v0.0.65-s-v0.0.53-e-v0.0.40`。完整说明中的所有服务器目录均给出了绝对路径。
