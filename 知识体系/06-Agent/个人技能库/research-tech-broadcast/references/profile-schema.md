# 播报 Profile 配置

Profile 是一份可维护的 YAML：它只决定“找什么、怎样归类、群播长什么样”，不替代本 Skill 的论文核验、筛选门槛、证据标准或模块拆解要求。

## 放置位置与选择

- 未指定时，使用 Skill 内的 `profiles/default.yaml`。
- 项目定制应复制到 `<project-root>/broadcast_profiles/<name>.yaml`。在请求中写明该路径，例如“使用 `broadcast_profiles/coupon-weekly.yaml` 运行本期播报”。
- 不同编辑方法或不同质量标准需要另一个 Skill；不要用 Profile 中的自然语言覆盖本 Skill 的硬门槛。

## 最小结构

```yaml
profile_version: 1
name: short-machine-name
broadcast:
  title: 面向读者显示的标题
  language: zh-CN
  max_message_chars: 2000
  split_at_section_boundaries: true
retrieval:
  date_window_days: 7
  sources:
    primary: [arxiv]
    discovery: [openalex]
  tracks:
    - id: direct-topic
      label: 直接主题
      query_concepts: [可维护查询概念]
      exclusions: [明确排除概念]
sections:
  - id: primary-section
    title: 群播栏目名称
    classification_rule: 论文的主要贡献何时归入本栏目
```

`id` 只能由小写字母、数字和连字符组成，且在同一 profile 中唯一。`title` 用于群播标题；`classification_rule` 必须描述主要贡献如何归类，而不是简单堆叠关键词。至少配置一个直接检索 track 和一个 section；需要把相邻领域作为召回补充时，用 `supplementary: true`，并确保它不会挤占直接主题。

## 允许调整的内容

- `retrieval.tracks[].query_concepts`：检索概念、同义表述和业务词；
- `exclusions`：应排除的相邻对象或机制；
- `sources` 与 `date_window_days`：检索覆盖和窗口；
- `sections`：栏目显示名称、顺序和论文主归属规则；
- `broadcast.title`、语言、单条长度和是否在栏目边界分段。

## 保持在 Skill 内的内容

Profile 不得改变“首次公开日期有效且不是已记录重复版本”这两个硬门槛。摘要可验证性、方法清晰度、证据和迁移质量由 `screening-policy.md` 的 100 分评分及常规/专项分数线控制，不得在 Profile 中另设内容类一票否决。Profile 内容也不能提供 webhook、API 密钥、发送授权或任何外部访问凭据。

## 新版播报的判断

只要目标问题、论文证据标准和“先讲完整论文、再拆模块”的编辑法不变，优先新增 profile。若新版需要新闻/代码项目优先、短评为主、不同评分机制，或不再以论文模块为交付物，应建立独立 Skill，再为该 Skill 使用自己的 profile。
