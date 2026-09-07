# 长期研究技术群播

这是面向网约车平台用户侧价格、报价、券、折扣和激励决策的长期论文库。2026 年 3—4 月作为首轮回填，用来验证群播和模型构建交接能否共用同一份论文模块记录。

论文仍按“论文—重要模块”理解和播报，不按 DT、DFCL、AIGB 等范式分类。当前 DT 只作为项目已有主要 baseline 记录在系统接口契约中，不参与论文筛选和组织。

## 读取入口

- [当前系统接口契约](research_map/system_contract.yaml)
- [2026 年 3 月筛选摘要](research_map/summaries/2026-03.md)
- [03-01—03-07｜无达标论文](research_map/digests/2026/03/2026-03-07.md)
- [03-08—03-14](research_map/digests/2026/03/2026-03-14.md)
- [03-15—03-21｜仿真系统](research_map/digests/2026/03/2026-03-21-b.md)
- [03-15—03-21｜出价模型](research_map/digests/2026/03/2026-03-21-a.md)
- [03-22—03-28](research_map/digests/2026/03/2026-03-28.md)
- [03-29—03-31](research_map/digests/2026/03/2026-03-31.md)
- [2026 年 4 月筛选摘要](research_map/summaries/2026-04.md)
- [04-01—04-07](research_map/digests/2026/04/2026-04-07.md)
- [04-08—04-14｜无达标论文](research_map/digests/2026/04/2026-04-14.md)
- [04-15—04-21](research_map/digests/2026/04/2026-04-21.md)
- [04-22—04-28｜仿真系统](research_map/digests/2026/04/2026-04-28-b.md)
- [04-22—04-28｜出价模型](research_map/digests/2026/04/2026-04-28-a.md)
- [04-29—04-30](research_map/digests/2026/04/2026-04-30.md)

## 长期状态

- `research_map/papers.jsonl`：论文级筛选、评分和去重记录。
- `research_map/paper_modules.jsonl`：唯一的模块中间协议；群播抽取其中的可读字段，模型构建读取完整接入字段。
- `research_map/system_contract.yaml`：当前仿真系统和出价模型的真实接口。只有项目接口变化时才更新。
- `research_map/summaries/YYYY-MM.md`：月度筛选摘要。
- `research_map/digests/YYYY/MM/*.md`：按日期归档的群播。

这里不维护实验进度、负责人、排期或业务增益。

## 查询模块

在本目录执行：

```bash
python3 .codex/skills/research-tech-broadcast/scripts/query_modules.py \
  --project . \
  "离线评估可以采用什么方法"
```

按系统位置和接入方式过滤：

```bash
python3 .codex/skills/research-tech-broadcast/scripts/query_modules.py \
  --project . \
  --target 用户状态构造 \
  "用户历史"
```

更新模块协议或系统契约后校验：

```bash
python3 .codex/skills/research-tech-broadcast/scripts/validate_protocol.py \
  --project .
```

## 业务边界

仿真生成用户、会话、请求、聚合供需/等待上下文和用户反馈；出价模型输出平台面向用户的价格、券、折扣或激励。供需、等待和服务可用性可以作为外部或聚合输入，但不模拟车辆、司机、匹配、调度、再平衡、车队规模或路网。
