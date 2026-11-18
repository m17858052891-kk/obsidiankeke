---
title: "召回重构pid实验V1.1.1"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2210405435645
---

# 召回重构pid实验V1.1.1


沿用召回重构V1.0的工程框架，策略和参数测算适用V1.1策略方案中的方法 

|  <br> | 内容 <br> | 备注 <br> |
| --- | --- | --- |
| 实验方式 <br> | 乘客pid分流 <br> |  <br> |
| 分流策略内容 <br> | 分为几个实验组，每个组流量分别为多少，每个实验组策略内容 <br> <br>==对照组【80%】== <br>==实验组1【5%】== <br>==实验组2【5%】== <br>==实验组3【5%】== <br>==实验组4【5%】== <br> | 详细见策略文档5.2.2[【交易效率-商家分单-商家召回重构-V1.0-V1】](https://cooper.didichuxing.com/knowledge/2199610335356/2208246237476/edit)，==参数和模型配置见本文档下文内容==。 <br>对照组策略：线上原策略 <br>==4个实验组策略：均使用mode=3== <br>模型：每个组模型版本独立可配置（暂定版本和上一个实验一致，模型名还是recall_caa_model_onnx） <br>参数：每个实验组参数独立可配置（由策略同学自行在运筹配置） <br>- 每个组的架构都是： <br><br>	- **TP 引擎过滤公式**：==【满足如下公式条件则召回；含义：播单的期望完单大于不播单的期望完单则召回（期望完单（价值）是越大越好）】== <br><br>		- 比较 1（TP vs Hold）：$$[(1-CAA_{\text{深度}}) - \lambda' \cdot (p_{next}-\gamma)] > \beta \cdot (1-OCR_{\text{深度}}) \cdot E(\text{finish})_{\text{baseline}}$$ <br><br>		- 比较 2（TP vs GS）：$$[(1-CAA_{\text{深度}}) - \lambda' \cdot (p_{next}-\gamma)] > (1-CAA_{\text{深度}})$$ <br><br>	- **GS 引擎过滤公式**（GS vs Hold）：==【满足如下公式条件则召回；含义：播单的期望完单大于不播单的期望完单则召回（期望完单（价值）是越大越好）】== <br><br>		- $$(1-CAA_{\text{深度}}) > \beta \cdot (1-OCR_{\text{深度}}) \cdot E(\text{finish})_{\text{baseline}}$$ <br><br> <br>- 实验组1（mode=3）： <br><br>	- caa模型版本：==v5== <br><br>	- beta：==1.35== <br><br>	- lambda：0.00001 <br><br>	- gamma：30 <br><br>- 实验组2（mode=3）： <br><br>	- caa模型版本：==v4== <br><br>	- beta：==1.35== <br><br>	- lambda：0.00001 <br><br>	- gamma：30 <br><br>- 实验组3（mode=3）： <br><br>	- caa模型版本：==v5== <br><br>	- beta：==1.35== <br><br>	- lambda：0.00001 <br><br>	- gamma：30 <br><br>- 实验组4（mode=3）： <br><br>	- caa模型版本：==v4== <br><br>	- beta：==1.35== <br><br>	- lambda：0.00001 <br><br>	- gamma：30 <br><br> <br> |
| 实验周期 <br> | 实验周期：14天（1111-1125） <br> | —— <br> |
| 流量范围 <br> | 来自哪个流量端（全部） <br> | 流量端： <br>- 小猪端 <br><br>- 滴滴端 <br><br>- pbd <br><br>- 企业级 <br><br>- other <br><br> |
| 实验生效品类（全部） <br> | 品类： <br>- 特价盒子 <br><br>- 特快盒子 <br><br>- 实时计价盒子 <br><br>- 宏鹄 <br><br>- 小猪一口价 <br><br>- 小猪打车 <br><br>- 小猪特价 <br><br>- 小猪特快 <br><br> |
| 分单场景（TP、GS） <br> | 默认全部 <br>- 自营轮次分单、自营Topspeed <br><br>- 宏鹄轮次分单、宏鹄Topspeed <br><br> |
| 分城市 <br> | ==实验城市：待给== <br> <br> |
| 实验生效商家 <br> | 自营、宏鹄 <br> |
| 评估人 <br> | DS、算法、评估大师 <br> |   <br> |


> [!abstract]- 子页面（2）
> - [召回重构pid实验V1.1.0实验方案](%E5%8F%AC%E5%9B%9E%E9%87%8D%E6%9E%84pid%E5%AE%9E%E9%AA%8CV1.1.0%E5%AE%9E%E9%AA%8C%E6%96%B9%E6%A1%88.md)
> - [召回实验城市分框](%E5%8F%AC%E5%9B%9E%E5%AE%9E%E9%AA%8C%E5%9F%8E%E5%B8%82%E5%88%86%E6%A1%86.md)
