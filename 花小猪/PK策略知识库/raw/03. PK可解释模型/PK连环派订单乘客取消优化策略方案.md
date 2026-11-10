BRD：<https://cooper.didichuxing.com/knowledge/2204598041545/2204686259908>

PRD：<https://cooper.didichuxing.com/knowledge/2204598041545/2204831142541>

# 1、需求背景

平台产品侧认为，乘客对连环派有天然厌恶，连环派是否顺路（或绕路）是这一倾向性的重要原因， 所以希望优化

- 乘客感知：对于高顺路度的连环派订单，改变订单应答页面展示，不向乘客透传连环派，从而降低应答后乘客取消率 

- 平台策略：优化O对D打分模型，精确化对连环派模式的考核，降低低顺路连环派司机的胜出占比，从而降低应答后乘客取消率

# 2、数据分析

- 乘客倾向性：在相同接驾距离下，连环派订单的应答后乘客取消率都大幅高于非连环派

![](https://s3-ep-inter.didistatic.com/didoc-upload-image-prod/1752830323582bb741fcc633b9d46a371c7e7a5dddc89/image.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKDD00000000000EBLCTZNRBJHX6ZS%2F20260526%2Fgzep%2Fs3%2Faws4_request&X-Amz-Date=20260526T080023Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=d7b881aea65d2fd4350f9c32d4035b366faf380e58f831be99ad2817274eea88)  

- 订单顺路度：对于连环派订单，顺路度越低（绕路比越高），乘客取消率越高，并且和非连环派订单的差距越大。推测订单顺路度是乘客倾向性的重要原因

	- 判断司机是否变远：若AB和AC的夹角小于90度且BC和AC的夹角小于90度，则司机不会变远

	- 定义连环派绕路比：等于接驾路面距离（AB+BC）除以起终点路面距离（AC），绕路比为1说明完全不绕路

![](https://s3-ep-inter.didistatic.com/didoc-upload-image-prod/1751252229429c719185045e6c544fcfd82b9e6a513fd/image.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKDD00000000000EBLCTZNRBJHX6ZS%2F20260526%2Fgzep%2Fs3%2Faws4_request&X-Amz-Date=20260526T080023Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=542ac216a04998c233855ae6024d6e245e5a6b63ff97182fb920c0f8b18b4156)

- 模型区分度：当前PK模型对连环派（黑线）和非连环派（黄线）的区分度有限，打分差距小于实际取消率差距，仍有优化空间

![](https://s3-ep-inter.didistatic.com/didoc-upload-image-prod/1753152298558941b34263f7a55bca505510d6fb2d599/image.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKDD00000000000EBLCTZNRBJHX6ZS%2F20260526%2Fgzep%2Fs3%2Faws4_request&X-Amz-Date=20260526T080023Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=354bdfd9c6c7b8bb3060379d1b525d14280327bf57de66f37d5b3c5aa448b391)

# 3、技术方案

## 3.1、概念定义

定义3个刻画维度，通过相互之间的组合，形成对顺路情况的4种刻画结果

| 模块 <br> | 概念 <br> | 定义 <br> |
| --- | --- | --- |
| 刻画维度 <br> | 司机不会变远 <br> | （AB和AC直线距离的夹角&lt;a）且（BC和AC直线距离的夹角&lt;a）【a=90度】 <br> |
| 司机不会绕路 <br> | 绕路比等于接驾路面距离除以起终点路面距离，即R=(AB+BC)/AC，若R&lt;=R\*则认为不绕路【R\*=1.2】 <br> |
| 上单终点在司机当前位置或本单起点附近 <br> | AB或BC路面距离小于L【L=200米】 <br> |
| 刻画结果 <br> | 绝对顺路 <br> | R=1 <br> |
| 高顺路 <br> | （司机不会变远 且 司机不会绕路）或（司机会变远 且 上一单终点在司机当前位置或本单起点附近） <br> |
| 低顺路 <br> | 司机不会变远 且 司机会绕路 <br> |
| 不顺路 <br> | 司机会变远 且 上一单终点不在司机当前位置或本单起点附近 <br> |

## 3.2、特征建设

需要工程配合建设新特征

| 特征 <br> | 含义 <br> |
| --- | --- |
| direct_distance <br> | AC段路面接驾距离，单位是米，非连环派取-1。 <br> |
| direct_eta <br> | AC段预估接驾时间，单位是分钟，非连环派取-1。 <br> |
| detour_ratio <br> | 绕路比R=(AB+BC)/AC，非连环派取值为1 <br> |
| bac_angle <br> | AB和AC直线距离的夹角，连环派取值范围0～180，非连环派取值为-1，精确到若干位小数 <br> |
| acb_angle <br> | BC和AC直线距离的夹角，连环派取值范围0～180，非连环派取值为-1，精确到若干位小数 <br> |

## 3.3、模型优化

需要在PK模型中加入4个新特征，预期权重全部为负，增加对连环派和不顺路的惩罚

| 特征 <br> | 预期权重 <br> |
| --- | --- |
| serial_type <br> | 权重为负，增加对连环派的惩罚 <br> |
| direct_distance <br> | 权重为负，增加对绕路的惩罚 <br> |
| bac_angle <br> | 权重为负，增加对司机向更远方向走的惩罚 <br> |
| acb_angle <br> | 权重为负，增加对司机从更远方向来的惩罚 <br> |

# 4、实验方案

| 模块 <br> | 内容 <br> |
| --- | --- |
| 分流方式 <br> | 乘客随机分流 <br> |
| 分组配置 <br> | 对照组：无策略，线上PK模型；实验组：新策略，优化后的PK模型 <br> |
| 核心指标 <br> | 平台CR、完单量、GMV；应答后乘客取消率、司机取消率 <br> |
| 策略指标 <br> | 低顺路和不顺路连环派的应答和完单占比 <br> |
