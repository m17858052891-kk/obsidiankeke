---
title: "acc_cr模型重梳理-2025.10"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2205586231792
cssclasses: ["strategy-body-note"]
---

# acc_cr模型重梳理-2025.10

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2205586231792)

## 特征工程

| | 含义 | 值 | 结论 | 验证结果 |
| --- | --- | --- | --- | --- |
| 模型传入hour_of_day | 小时 | 1\~24，bigint | 符合预期 | ![](8caa69a6529d0390-截屏2025-10-14下午8.51.53.png) |
| 取特征的hour_of_day | 小时 | 0～23，bigint | 符合预期 | ![](eadcf0e30c8a5247-截屏2025-10-14下午8.57.00.png) |
| day_of_week | 周几 | 1-周日 <br>2-周一 <br>3-周二 <br>4-周三 <br>5-周四 <br>6-周五 <br>7-周六 | 符合预期 | ![](20250cdce90f0aaa-截屏2025-10-14下午8.55.50.png) |
| is_weekday | 是否工作日 | 1:周一～周四（2～5） <br>0:周五～周日（6-7、1） | 符合预期 | ![](d19a18f8692f0810-截屏2025-10-14下午9.02.42.png) |
