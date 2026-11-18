---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-14"
module_id: "ChainAdvancing-bands"
source_papers: ["arxiv:2611.16661"]
version: "v1"
local_validation: "未运行"
---

# 按到达档和已揭示链深分配执行槽

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/ChainAdvancing/精读|Reducing Batch Makespan for LLM Agent Workloads through Inference-Environment Coordination]]

## 输入、动作与输出

每个待执行动作入队时冻结键 (⌊a/B⌋,−n,⌈平均推理时长/Δ⌉,到达序号)，按字典序从小到大取下一项。输入只含入队时间与本次运行已完成的 n 轮。输出一个占用空槽的动作。

## 使用时点与依赖

无须训练和余长标签。先分离准入与环境槽，在相同 C_S、C_E 上才可归因给排序。若深度与未来工作无关，先推进深链只会挤压其他请求。

## 原文证据与实现

§4.1–4.2、§5.3 图 12 作固定槽数的直接比较。

未核到此工作可复现实验的公开仓库。§4.2 式 (13)–(16)、图 11–12 与附录 A.2 给出顺序及配置。

## 迁移假设

用同一组分段轨迹，在固定准入和并发槽下只换 FCFS 与分档深度排序；在同档内打乱已见深度作置换对照。本地尚未验证。

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/ChainAdvancing-tail|推进深链缩短的是末批还是多数请求的等待]]
