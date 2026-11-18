---
type: "实验"
topics: ["动态等待与匹配决策"]
status: "草稿"
created: "2026-11-12"
experiment_id: "RandomEdgeReserve-orders"
experiment_status: "待设计/未运行"
source_modules: ["RandomEdgeReserve-phases", "RandomEdgeReserve-exact-bound"]
result: null
run_at: null
logs: null
---

# 端点保留的收益对到达顺序有多敏感

**待设计，未运行。** 相比即时贪心，三阶段策略可能在随机排序、早期中心边竞争严重时获得更高匹配规模；高峰成簇顺序可能改变排序。

## 最小改动与基线

固定同一组无权图与线性时间窗，交替使用独立均匀、按核心边聚集、按叶边聚集三种到达。比较贪心、三阶段策略，小图再用 §5 递推作均匀序对照。

## 数据、预算与失败判据

保留独立测试图库及序列种子；统一每边单次承诺、容量与终止时刻。指标为规模/离线最优、首次放弃端点后续被使用比例，比较置信区间。枚举 CPU 状态数与时间上限待确认。若预设随机子群无改善或加入可召回边才见效，拒绝本假设。

代码版本、数据版本、运行时间和日志待确认。论文报告值见 [[研究前沿/动态等待与匹配决策/01-论文原文与精读/RandomEdgeReserve/精读|Improved Bounds for Online Matching with Random Edge Arrivals]]。

- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/RandomEdgeReserve-phases|用影子匹配决定早期保留、晚期恢复的端点]]
- [[研究前沿/动态等待与匹配决策/02-可复用方法卡/RandomEdgeReserve-exact-bound|在固定小图上计算随机顺序在线策略的精确上界]]
