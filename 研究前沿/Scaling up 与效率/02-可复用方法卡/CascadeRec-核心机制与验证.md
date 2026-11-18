---
type: "方法卡"
topics: ["Scaling up 与效率"]
status: "维护中"
created: "2026-11-18"
method_id: "arxiv:2611.08566:mechanism"
experiment_status: "未运行"
---

# CascadeRec：把更多推理预算给难样本，一定提高排序吗？

[[研究前沿/Scaling up 与效率/01-论文原文与精读/CascadeRec/精读|来源精读]]

## 接口与计算

- 输入：固定召回候选、小模型排序/置信及成本预算。
- 输出：是否升级、最终排序及失败回退记录。
- 流程：轻量 reranker 对每个请求给排序和信号，router 决定是否升级至昂贵推理；格式失败或超时回退到此前排序。公开实验按历史长度分层，对比无重排、统一重排、self-consistency/multi-pass 级联。
- 训练/推理依赖：离线路由训练与测试隔离；线上超时/格式错误均计入总质量和成本。


$$
\max_\pi\sum_u quality(\hat R_u)-\lambda cost(\hat R_u).
$$

核心计算关系（非完整训练目标）：这是成本约束的目标示意，π 是升级路由；质量需用真实排序指标测量，不能以 LLM 自报置信替代。

## 最小采用单元及耦合

负结果验收与分层路由；保留无重排基线和可审计回退。

生产和公开实验设置不同，不能把生产收益当作公开级联机制的独立佐证。历史少不必然值得更多计算，候选召回已限制上界。此前 11-13 仅有候选记录，本轮是补完精读，不是首次发现。

## 原文证据

表 2 MovieLens 无重排 NDCG@10 0.0636；Mistral 统一 0.0612，级联 MP 0.0633 且 token 1335→3376。Amazon 无重排 0.5380，Qwen 最佳级联 0.5049。表 4 显示格式错误率依模型与约束变化，不能静默丢掉失败样本。

位置：§3–6，表 1–4，v1。不把整体收益归给未经单独验证的模块；未运行本地实验。

## 代码入口

[论文所链仓库](https://github.com/GuilinDev/llm-cascade-reranking) 的 README 已读取；README 定位 src/cascade/、src/routers/、scripts/analyze_iaai.py 与 experiments/iaai/。目录 API 返回 403 限流，未逐文件审计或运行代码，入口路径仅核至作者 README。[[研究前沿/Scaling up 与效率/01-论文原文与精读/CascadeRec/assets/source/repo-readme|本地 README]]。

## 潜在迁移与验证

固定候选召回和总推理预算，对比原排序、全部小模型、随机升级和置信/历史分层升级；按分层比较质量、P99、失败率、总成本。若升级只增加成本或召回上界太低，停止加算力。

[[研究前沿/Scaling up 与效率/03-实验假设与结果/CascadeRec-首个验证|具体实验假设（未运行）]]
