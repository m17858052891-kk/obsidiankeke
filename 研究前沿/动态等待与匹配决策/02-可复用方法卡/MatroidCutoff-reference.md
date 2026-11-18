---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-13"
module_id: "MatroidCutoff-reference"
source_papers: ["arxiv:2611.06891"]
version: "v2"
local_validation: "未运行"
---

# 不同分布的资源如何用参考价格和虚拟基接纳

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/MatroidCutoff/精读|Prophet Secretary for Matroids and XOS Valuations: A Separation at 1-1/e and a 0.6767 Guarantee for I.I.D. Weights]]

## 输入、流程与输出

各候选独立已知价值分布、拟阵独立性 oracle → 抽样估计参考实例与收缩/删除价值 → 在当前元素到达前设价；参考参数或差异触发时转入对虚拟基的回放和交换。输出可行接纳集。

## 最小采用单元与依赖

定理依赖随机到达以及抽样、切换、基交换共同作用。可先复用接纳后收缩/拒绝后删除的可行性维护，单用该部件没有整体收益保证。

## 原文证据与实现

v2 §5.2 算法 1、§8.2 算法 2 与定理 1；v1 已含该机制。

正文指向作者仓库，核对到 MatroidProphetSecretary_XOS_Proofs.zip 与 iid-matroid-prophet-lean.zip 两个证明包，未发现生产调度实现，未编译。[固定仓库版本](https://github.com/hajiaghayi/Matroid-Prophet-Secretary-XOS/tree/ffaa3702ed58865a03ec29e7da41cdee137542ce)

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/MatroidCutoff-iid|共同分布被打破时，替代性阈值会不会失去优势]]
