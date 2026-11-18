---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-12"
module_id: "PoissonClocks-first-age"
source_papers: ["arxiv:2611.11133"]
version: "v1"
local_validation: "未运行"
---

# 保持逐轮分配概率的跨轮相关指数时钟

来源为 [[研究前沿/动态等待与匹配决策/01-论文原文与精读/PoissonClocks/精读|Online Correlated Exponential Clocks]]。

## 输入、操作与输出

输入每轮确定的分数 $x_{ij}$，资源之间独立。每个资源保持自己的 Poisson 时间线，读取长度 $x_{ij}$ 区间首点的前一空档；经随机化 CDF 变换得 $U$ 后发出 $-\log(U)/x_{ij}$。选最小时钟的资源。生成器在线可复用，无须训练；分数层须独立于舍入随机性。

## 原文证据与实现

§3.1–3.2 证明指数边际与跨次负关联。§5 及附录 B.2 的 0.556297869 属于 Display Ads 水位分配、势函数、舍入三者的共同保证；§6 的 0.530 使用另一套分数规则。

作者仓库按任务给出证明的数值核验代码，包括 display-ads/verify.py、adwords/verify.py 与 load-balancing/verify_kernel.py。未执行这些证书核验。[验证仓库](https://github.com/Jiahao566/Online-Correlated-Exponential-Clocks)

## 迁移推断

可在已固定分数的批流中与独立指数时钟对比遗漏概率或平方负荷。若竞争者会按舍入结果立即离场并改变下一轮配额，需重建基准。

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/PoissonClocks-rounding-only|只替换舍入的随机性，能否降低连续遗漏]]
