# 1、PK

对每个订单，平台通过商家收集若干举手司机，从中决策出胜者

- PK打分：用于排序举手司机

	- 一轮PK的胜者是PK窗口中PK打分最高的司机

	- PK打分的预测目标是司乘组合的胜出完单率

- PK窗口：用于收集举手司机

	- 一轮PK的持续时间取决于PK窗口的类型和策略

	- PK窗口的优化目标是权衡等待时间对CR的影响

# 2、PK模型

## 模型简介

样本空间

- 正样本：PK胜出后完单的司乘对

- 负样本：PK胜出后未完单的司乘对，包括司机拒单、司机取消和乘客取消的司乘对

特征选择

- 订单特征：司机接驾距离、单位距离价格、订单距离、发单后等待时间

- 司机特征：近14天司机的司乘取消率、拒单数、完单数

- 乘客特征：近28天乘客的自营应答后取消率、三方应答后取消率

- 供需特征：近5分钟起点坐标格子的发单数、空车司机数

特征工程

- 特征隔离：分场景的司机特征硬隔离

- 特征处理：特征空值的均值填充、特征标准化

模型选择

- 逻辑回归：y=sigmoid(w1\*x1+w2\*x2+...+wk\*xk)

## PK模型迭代

[【2024年终】PK模型迭代版本](https://cooper.didichuxing.com/knowledge/2199610335356/2203514410868)

- 从XGB过渡到LR。特征筛选；司乘取消率合并；接驾距离权重放大到2倍

[【LR25012】PK可解释模型迭代V1](https://cooper.didichuxing.com/knowledge/2199610335356/2204705480400)

- 连环派接驾距离特征统一用AB+BC；优化司机维度特征和空值填充逻辑

[【LR25033】PK可解释模型迭代V2&区分半指派模式](https://cooper.didichuxing.com/knowledge/2199610335356/2205554882388)

- 重建司机维度特征，将原先仅区分是否连环派，变成区分是否半指派x是否连环派

[【LR25050】PK可解释模型迭代V3&联合展示策略优化连环派](https://cooper.didichuxing.com/knowledge/2199610335356/2206026814309)

- 建设连环派的接驾特征（距离和夹角），增加绕路比特征进行考核

[【策略方案】PK可解释模型结构升级方案](https://cooper.didichuxing.com/knowledge/2199610335356/2205042583153)

- 重建乘客维度特征；利用Wide&Deep框架；司乘履约分开建模

## PK引入毛利因子

[【策略方案】PK引入毛利因子](https://cooper.didichuxing.com/knowledge/2199610335356/2202985412631)

- 1pp的毛利率差会使PK阶段的接驾距离特征增加100米

[【2024总结】PK引入毛利因子评估](https://cooper.didichuxing.com/knowledge/2199610335356/2203673810707)

- 完单（%）和毛利率（pp）的置换比大致在1：1

[【2025年初】PK引入毛利因子评估](https://cooper.didichuxing.com/knowledge/2199610335356/2203965220675)

- 引入毛利因子后，折损0.12%完单，置换0.15pp毛利率

[【2025年初】PK引入毛利因子一期扩量](https://cooper.didichuxing.com/knowledge/2199610335356/2204193286736)

- 经规则评审，决定在完单和毛利率双正城市扩量，但遭商家阻挠，扩量失败

## PK引入治理因子

[【LR25013】PK引入司机长时取消因子](https://cooper.didichuxing.com/knowledge/2199610335356/2204705569645)

- 统计司机历史取消数特征时，对长时取消进行加权，权重和取消时长成正比

[【LR25014】PK引入司机诱导取消因子](https://cooper.didichuxing.com/knowledge/2199610335356/2204738768922)

- 统计司机历史取消数特征时，对诱导取消数进行加权，加权系数约4倍

# 3、PK窗口

## 策略简介

![](https://cooper.didichuxing.com/uploader/f/2odlCBlvDwMpGW2c.png?source=all&accessToken=eyJhbGciOiJIUzI1NiIsImtpZCI6ImRlZmF1bHQiLCJ0eXAiOiJKV1QifQ.eyJleHAiOjE3NjU1MjgxODIsImZpbGVHVUlEIjoidGJzeVJQbXltbFBHOWRKdCIsImlhdCI6MTc2NTUyNzU4MiwiaXNzIjoidXBsb2FkZXJfYWNjZXNzX3Jlc291cmNlIiwicGFhIjoic2RrOnRoaXJkOmUwNjhhMDcxZTQ3MzQyMTI5NmE4ZDRmODE2MWY4MjU5IiwidXNlcklkIjoxMDAwMDE4MTExNn0.ysAUMXHOkdvTC6whLiCG4WyT1zwb1hV4vN1dnPYKBwQ)

静态窗口

- PK窗口固定4秒。有运力举手时，保留PK打分最高的当前胜者，窗口结束时当前胜者胜出

动态窗口

- PK窗口动态调整。有运力举手时，保留PK打分最高的当前胜者，判断是否满足PK窗口结束的条件，决策当前胜者能否即刻直接胜出

## 阈值法V0（线上策略）

[【实验评估】PK动态窗口策略V0](https://cooper.didichuxing.com/knowledge/2199610335356/2201642828464)

- 若举手运力是4秒内预估接驾时长最短的概率>0.95，则提前结束PK窗口

## 阈值法V1（扩量失败）

[【策略方案】PK动态窗口策略V1](https://cooper.didichuxing.com/knowledge/2199610335356/2203145965400)

[【实验评估】PK动态窗口策略V1](https://cooper.didichuxing.com/knowledge/2199610335356/2204369766055)

[【LR25010】PK动态窗口策略V1](https://cooper.didichuxing.com/knowledge/2199610335356/2204562271351)

- 若当前胜者的预估乘客取消率<0.09，则提前结束PK窗口

- 若PK窗口到4秒时，当前胜者的预估乘客取消率>0.45，则延长PK窗口至最多8秒

## 强化学习策略（优化中）

[【策略方案】PK动态窗口策略之强化学习方案](https://cooper.didichuxing.com/knowledge/2199610335356/2205761610947)

[【实验评估】PK动态窗口策略之强化学习方案](https://cooper.didichuxing.com/knowledge/2199610335356/2206196027825)

- 从完单概率的预测转变为等待价值的设计和学习
