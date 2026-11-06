---
type: "方法"
topics: ["研究前沿", "方法精读"]
status: "维护中"
created: "2026-11-06"
module_id: "projectediv:projected-score"
paper_id: "arxiv:2611.00705"
local_validation: "未验证"
---

# 允许基线关联空间之外的IV残差去偏

来源：[[研究前沿/uplift模型迭代/01-论文原文与精读/ProjectedIV/精读|ProjectedIV 精读]] · [原文](https://arxiv.org/html/2611.00705v1)

## 输入与输出

结果Y、二元处理A、工具Z、协变量X、结构空间S→ATE和不确定性

## 计算、训练与推理流程

拟合S投影与处理预测；构造残差权重、κ与μ；cross-fit影响分数平均，监控残余工具强度。

## 效果证据与归因

Thm1识别、Thm4 EIF；Table7.3 PIV1/2覆盖接近名义、PIV3错误结构可完全失效。

## 最小采用单元与耦合依赖

S的科学假设、残余相关强度和效应修饰正交缺一不可；自适应权重需完整修正。

## 数据假设与失败边界

未测共同效应修饰、弱工具、S错设；条件预测好不能证明IV有效。

## 潜在迁移（推断）

对可解释外生变化尝试多空间敏感性，补充纯无混杂估计。

## 代码与本地验证

已核验[作者仓库](https://github.com/chensy123-sys/Projected-IV)，commit `262641a8deb5b2078f049832bed36eed3b7538ed`；入口：[PIV.R](https://github.com/chensy123-sys/Projected-IV/blob/262641a8deb5b2078f049832bed36eed3b7538ed/PIV.R)。已读取入口声明/关键片段，未审计全部实现、未安装运行。 [[研究前沿/uplift模型迭代/01-论文原文与精读/ProjectedIV/代码核验|核验记录]]

无本地实验结果。
