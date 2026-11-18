---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-13"
module_id: "MatroidCutoff-cutoff"
source_papers: ["arxiv:2611.06891"]
version: "v2"
local_validation: "未运行"
---

# 按剩余集合可替代性设接纳分位阈值

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/MatroidCutoff/精读|Prophet Secretary for Matroids and XOS Valuations: A Separation at 1-1/e and a 0.6767 Guarantee for I.I.D. Weights]]

## 输入、流程与输出

输入剩余拟阵、独立性查询、当前元素权重与共同分布。先作上尾分位变换，再计算随机剩余集不能张成当前元素的概率；根据固定阈值接纳或拒绝，分别收缩或删除元素。

## 最小采用单元与依赖

最小采用单元为分位变换与剩余拟阵独立性接口；有限样本的阈值估计须保留附录 A 的误差余量。适用于独立同分布权重；一般二部匹配的可行边集未必形成一个拟阵。

## 原文证据与实现

v2 §3 定理 4 与 §3.1，整体保证为至少 0.6767。

正文指向作者仓库，核对到 MatroidProphetSecretary_XOS_Proofs.zip 与 iid-matroid-prophet-lean.zip 两个证明包，未发现生产调度实现，未编译。[固定仓库版本](https://github.com/hajiaghayi/Matroid-Prophet-Secretary-XOS/tree/ffaa3702ed58865a03ec29e7da41cdee137542ce)

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/MatroidCutoff-iid|共同分布被打破时，替代性阈值会不会失去优势]]
