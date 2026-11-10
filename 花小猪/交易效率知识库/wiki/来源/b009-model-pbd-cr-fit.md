---
title: "B009 模型来源：PBD 成交率拟合"
type: source-summary
owner: "@tommywujian"
freshness: watch
status: draft
last_reviewed: null
permission_scope: department
source_ids: ["cooper:knowledge:2199613433157"]
related: ["../模型/匹配效率成交率拟合.md"]
---

# B009 模型来源：PBD 成交率拟合

材料用呼单量和拉齐量纲 TSH 拟合 PBD 腾讯渠道成交率，给出全国统一 logit 模型的两个历史训练窗口。第一版记录 R²=0.774、MAE=0.012，更新窗口记录 R²=0.879、MAE=0.015；呼单量与 TSH 相关系数 0.927，存在明显共线性风险。

这些数字仅对应材料列出的 2022 年窗口，不能代表当前泛化能力或线上收益；附件公式表未解析。

## 原始来源

- [PBD匹配效率拟合](../../raw/cooper/knowledge-2199613433157.md)（sha256 `16048fcd5aa96400b21ffcd4848302d8235f3d151b40c486455f541fc79211f4`）
