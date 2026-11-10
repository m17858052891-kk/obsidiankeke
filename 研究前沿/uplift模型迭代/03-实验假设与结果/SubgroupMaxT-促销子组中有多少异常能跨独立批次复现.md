---
type: "实验"
topics: ["研究前沿","uplift模型迭代"]
status: "维护中"
created: "2026-11-10"
paper_id: "arxiv:2602.06910"
experiment_id: "SubgroupMaxT:exp"
experiment_status: "未运行"
---

# 促销子组中有多少异常能跨独立批次复现

[[研究前沿/uplift模型迭代/02-可复用方法卡/SubgroupMaxT-重叠人群的最大统计量校正|重叠人群的最大统计量校正]] · [[研究前沿/uplift模型迭代/01-论文原文与精读/SubgroupMaxT/精读|SubgroupMaxT 精读]]

## 假设、数据与最小改动

固定一份人群字典，生成折外伪结果；在相同人群上对照未校正、Bonferroni 及最大统计量校正。先做 A/A，再用下一次独立实验复核。

## 基线、指标和失败判据

量化 A/A 下至少一组误报的频率、不同人群覆盖和跨批复现。若误报未受控或结论对稀疏组阈值极为敏感，则停止用作筛选。

项目数据可用性、预算与时限待确认。未运行，无本地结果或训练日志。
