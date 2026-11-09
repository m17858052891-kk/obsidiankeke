---
type: 文献研究笔记
topics: [特征工程, 模型反馈]
created: 2026-11-06
year: 2026
category: "基准与研究可用性"
---

# LATTEArena: An Evaluation Framework for LLM-powered Tabular Feature Engineering (Extended Version)

> [!summary] 为什么读这篇
> 把15代表方法分为6维：提示策略、特征搜索、示范、输出格式、元数据、数据抽样；24核心代理配置，非15原作原样复现

[论文/作者来源](https://arxiv.org/html/2606.09004v3) · [代码来源](https://github.com/goodenhak/LATTEArena)

**版本与发表状态：** arXiv2606.09004v3，2026-10-12；文中声明submitted to IEEE，未核得接收  
**实际阅读范围：** 方法分类、Table1-8、评估设置、主要Finding；README、目录与4源码文件核查  
**本研究定位：** 基准与研究可用性；重点阅读。未运行算法。

## 反馈怎样进入搜索

**反馈内容：** 历史正负特征、top-k效用、CART、critic、进化历史等组件对比；统一RF验证、RF测试和AutoGluon测试

**搜索单位：** 代理流程/组件配置

**机制：** 把15代表方法分为6维：提示策略、特征搜索、示范、输出格式、元数据、数据抽样；24核心代理配置，非15原作原样复现

## 对两个关键问题的意义

**互补组合：** Finding4指出只记录新增特征及分数会丢掉父集合上下文；这是对失效机制的解释，未独立证明因果归因

**跨模型或跨任务：** VG→TG主要表征反馈集到测试集；TG→AG还更换预测流程，二者不可都归因为验证过拟合

## 已核的验证与效果

**设置：** Table4，主数据9分类+4回归；3:1:1划分，6种子；默认GPT-4o温度1，RF评价；分类单位绝对准确率百分点

**method：** OGR

**VG：** 3.55

**TG：** 0.73

**AG：** -0.32

**设置：** Table4，分类平均测试增益

**method：** EBR_w

**TG：** 0.86

**AG：** 0.12

**设置：** Table6，去CART改为metadata，作者相对变化口径

**VG：** -2.2%

**TG：** -1.4%

**tokens：** +约280%

以上保留论文实际设置。若只读摘要或定向段落，不从未读表格补写数值；作者报告与本研究是否复现是两件事。

## 局限与取舍

预测增益、token和执行可靠性必须分别报告

Table2用ELLM-FT替换LLM-FE，称LLM-FE无进化与原作及buffer.py不符

Table1 CAAFE年份写2024，实际NeurIPS2023；Table2 FeatLLM/基因组FREEFORM描述疑似对调

等token曲线选择5个VG差异大的分类集，结论不宜泛化全部任务

论文称大数据自然消除过拟合、复杂架构成本指数增长，属于过强概括；有限基准不足支持数学/普适定律

源码当前版本未能直接确定就是产生论文全部表格的版本

**可以支持的判断：**

历史反馈未必提高同预算收益

结构化反馈的信息价值应连同成本和统计口径评价

需要记录候选依赖/父集合而不是孤立历史分数

**不能据此推出：**

15原始方法已被完全忠实公平复现

99%等于每次生成无错率

表格必然是所有六种子无偏平均

所有反馈过拟合风险会因样本增大自动消失

其中对搜索盲区、适用范围与缺失对照的解释，是本研究根据方法或表格作出的判断；不把它们冒充作者报告的实验损失。

## 实现核查与复查位置

**仓库层级：** 已读源码；未运行

已读材料：Preprocess.py；Evaluator.py；execution_logs/extract.py；execution_logs/check_success_rate.py。

日志README声明过滤早期失败日志

extract.py n>1删除最低值后求均值/标准差，不是全种子平均

成功率OPRO任何一个turn成功即整轮成功；ToT与普通族按不同单位解析；仅检索warning标记

Evaluator RF分类编码拼接train与test特征拟合，属于测试协变量参与预处理，未看到此处读取测试标签

Preprocess在val_size=.2,test_size=.2时正确计算val_ratio=.25得到60/20/20；README OpenFE段落80/20再80/20表述与实际代码不一致

真实数据要求外部GoogleDrive下载，不全在GitHub根目录

作者称4000+；未逐个计数/重放

**论文位置：** §3/Table1

§4.2/Table2

§5.1/Table3

§5.2设置

§5.3/Table4与Finding3/4

§5.5等token

§5.6/Table6

§5.9成功率

execution_logs/extract.py:472–480,593–595

execution_logs/check_success_rate.py:113–154

Evaluator.py:221–235

代码观察针对核查时的公开版本；没有逐项重放论文结果，也没有把找到链接等同于可复现。

返回：[[模型反馈与特征发现/03-论文与代码总索引|论文与代码总索引]] · [[模型反馈与特征发现/01-研究结论与技术路线|研究主报告]]
