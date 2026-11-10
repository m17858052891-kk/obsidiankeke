---
title: DUFE 统一特征平台
type: entity
tags: [平台, 特征工程, 在线服务]
sources: [DUFE特征平台使用.md, 离线特征生产.md]
created: 2026-05-29
updated: 2026-05-29
---

# DUFE 统一特征平台

## 定位

滴滴内部的**统一特征管理一站式平台**，提供离线特征生产、在线特征服务、特征注册与质量检查能力。

> 注意：DUFE 与 [[花小猪/平台工具知识库/wiki/entities/EVE]] 的特征中心是不同团队自建，一般一个算法团队只使用其中一个进行注册上线。

## 平台地址

- https://dufe-v2.intra.xiaojukeji.com/
- 使用手册：https://engine.intra.xiaojukeji.com/docs/manual/dufe/

## 核心能力

### 离线特征生产

详见 [[花小猪/平台工具知识库/wiki/workflows/离线特征生产流程]]

基于离线 Hive 表生产特征，同步到在线存储，供在线服务查询：
1. **SQL 特征计算**：平台上配置 SQL 实现特征生产
2. **特征质量检查**：行数校验、空值率校验、空值率环比校验
3. **特征同步**：同步到在线存储（Fastload）
4. **特征注册**：自动注册 DUFE 特征，同步完成即可在模板中引用

### 在线特征服务

- 通过模板（template）配置在线特征获取方式
- 支持 key-field-value 结构查询
- 与 [[花小猪/平台工具知识库/wiki/entities/EVE]] 模型部署时的特征映射打通

## 存储结构

```
Table（一个同步任务一张表）
├── Key = 特征前缀_${主键值}  （如 AAA_driver123）
├── Field = 特征名
└── Value = 特征值
```

## 特征命名规范

SQL 中的特征列名必须添加对应前缀：
- `odt_`：地点类
- `i_`：输入类
- `s_`：供需类
- `b_`：冒泡类
- `d_`：司机类
- `p_`：乘客类
- `o_`：订单类

> 前缀只适用于特征列，不适用于主键列。

## 与其他平台的关系

- [[花小猪/平台工具知识库/wiki/entities/数梦]]：调度离线特征生产任务
- [[花小猪/平台工具知识库/wiki/entities/Spark]]：执行特征计算 SQL
- [[花小猪/平台工具知识库/wiki/entities/EVE]]：模型部署时通过特征映射获取 DUFE 特征

## 相关文档

- [DUFE 使用手册](https://engine.intra.xiaojukeji.com/docs/manual/dufe/)
- [hive2ddict 手册](https://cooper.didichuxing.com/knowledge/2205445164678/2205446397645)
- [离线特征配置到 DUFE](https://cooper.didichuxing.com/knowledge/2199610335356/2200990355391)
