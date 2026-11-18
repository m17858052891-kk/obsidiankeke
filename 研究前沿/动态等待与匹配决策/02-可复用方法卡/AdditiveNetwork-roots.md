---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-13"
module_id: "AdditiveNetwork-roots"
source_papers: ["arxiv:2611.13859"]
version: "v1"
local_validation: "未运行"
---

# 把可选服务根固定成连通区域

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/AdditiveNetwork/精读|Online Network Design with Additive Delays and Poisson Arrivals]]

## 输入、流程与输出

树边成本、根的激活成本和每点到达率 → 为根加终端边 → 生成有限候选连通分区 → 逐区算嵌套时钟证书，选证书最小的分区并照表服务。输出根分配和时间表。

## 最小采用单元与依赖

最小采用单元是连通分区加区内合批；分区和周期必须共同计价才能引用整体界。需要已知树与正需求率。

## 原文证据与实现

§6.2–6.5；定理 6.13（PDF 第 24 页）给出确定性的多项式预处理。

正文未列作者代码。设施时间表见 §5.2；多根分区见 §6.2、6.5；移动时钟递推见式 (14) 与 §7.3。

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/AdditiveNetwork-location|固定服务分区对到达率漂移有多敏感]]
