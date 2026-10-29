---
type: "索引"
topics: ["推荐系统", "序列建模"]
status: "维护中"
aliases: ["PCVRHyFormer 项目"]
---

# PCVRHyFormer 项目入口

[[00-首页|返回首页]] · [[00-导航/面试与分享|面试与分享]]

## 当前主线

当前讲解采用 **516 前置候选感知结构**。先读 [[PCVRHyFormer/具体结构/当前模型架构（516 前置候选感知）|当前模型架构（516 前置候选感知）]]，模块顺序与事实卡见 [[PCVRHyFormer/具体结构/README|结构阅读路线]]。

## 实验证据

- [[PCVRHyFormer/实验复盘与证据边界|实验复盘与证据边界]]：特征、序列长度与模型容量尝试的结果和边界。
- [[PCVRHyFormer/具体结构/README#证据边界|已有证据边界]]：516 结构的代码依据与历史分数并非严格等预算的完整因果对照；缺少日志的模块增益不能单独归因。

## 下一步

- 补齐当前结构与历史版本的同口径实验日志，再判断单项改动增益。
- 扩展方案按 [[PCVRHyFormer/具体结构/共享序列Encoder与域特定Adapter-FiLM|共享序列Encoder与域特定Adapter-FiLM]] 和 [[PCVRHyFormer/具体结构/Pyramid序列压缩：从逐层缩短到候选感知筛选|Pyramid序列压缩：从逐层缩短到候选感知筛选]] 中的验证思路逐项评估。

## 讲解材料

- [[PCVRHyFormer/讲解逐字稿（3分钟）|讲解逐字稿（3分钟）]]。
- [[PCVRHyFormer/具体结构/PCVRHyFormer完整模型架构逐字稿-516最终版|PCVRHyFormer完整模型架构逐字稿-516最终版]]。
- [[PCVRHyFormer/具体结构/面试深挖问题地图（从业务到落地）|面试深挖问题地图（从业务到落地）]]；[[PCVRHyFormer/具体结构/面试问答（精简）|面试问答（精简）]]。

## 相关论文

[[论文精读/HyFormer/HyFormer：CTR中的序列建模与特征交互|HyFormer：CTR中的序列建模与特征交互]] · [[论文精读/OneTrans/OneTrans：统一特征交互与序列建模|OneTrans：统一特征交互与序列建模]]
