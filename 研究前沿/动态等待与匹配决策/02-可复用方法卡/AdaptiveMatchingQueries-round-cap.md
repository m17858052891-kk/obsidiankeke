---
type: "方法"
topics: ["动态等待与匹配决策", "乐观图逐轮匹配的端点查询上界"]
status: "维护中"
created: "2026-11-09"
module_id: "doi:10.5281/zenodo.23959746/round-cap"
source_paper_id: "doi:10.5281/zenodo.23959746"
source_version: "1.0.0"
local_validation: "未验证"
---

# 乐观图逐轮匹配的端点查询上界

来源 [[研究前沿/动态等待与匹配决策/01-论文原文与精读/AdaptiveMatchingQueries/精读|Adaptive Stochastic Matching: An Expected Query Bound and the Cost of Mandatory Batching]]。

**输入输出。** 给定静态宿主二分图、每条边独立的 $p=1/2$ 和容忍误差 $\varepsilon$，输出已验证正边上的一组不冲突匹配。查询同时在两个端点计数。

**过程。** $H\gets\varnothing,U\gets G$。共 $R=\lceil6/\varepsilon\rceil$ 轮，每轮在 $U$ 中找最大匹配，只探测其中未知边。成功边加入 $H$，失败边从 $U$ 删除。返回 $H$ 上的最大匹配。无统计训练，推理时每轮一次匹配求解。已知成功边保留且不需提前确认，端点额度不能跨顶点抵销。

**证据。** §3 Thm. 3.1，$R$ 轮后期望缺口不超过 $[2\log3/(R\log(3/2))]\,\mathbb E[\mathrm{OPT}]$，每条实际执行路径上顶点查询数均不超 $R$。本文改进期望界分析，轮次算法出自已有工作。没有实验或对数级通用上界。

**迁移推断。** 对每个资源接触次数有限的匹配审查，可将它作为统一预算的清晰参考基线。异质成功率、双边响应相关、边按时间失效、需立即承诺时，理论保证应另行研究。

代码核验。作者在 Zenodo 提供的 sources.zip 含论文 TeX、图的 TeX、README 和许可证。核对其文件清单，算法实现入口未知。[作者附件](https://zenodo.org/records/23959746)

候选实验 [[研究前沿/动态等待与匹配决策/03-实验假设与结果/AdaptiveMatchingQueries-screening-budget|同一匹配覆盖目标下，批内中止能节省多少热点询问]]。
