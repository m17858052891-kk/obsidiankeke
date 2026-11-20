# Markdown Outline And Phrase Bank

## Full Report Skeleton

```markdown
# <Paper Title> 论文拆解

论文：<title>  
链接：<links>  
版本/会议：<version/conference if known>

## 1. 一句话总结

<One paragraph: problem + method + evidence + practical meaning.>

## 2. 论文要解决什么问题

### 2.1 原有范式
### 2.2 原有范式的局限

## 3. 核心思想

<Name the central move.>

## 4. 输入和表示

### 4.1 输入单元
### 4.2 特征/token 构造
### 4.3 顺序、位置、类型信息

## 5. 模型结构

### 5.1 总体数据流
### 5.2 Block/module 设计
### 5.3 参数共享/专属策略
### 5.4 Attention/fusion/interaction 机制
### 5.5 输出头和训练目标

## 6. 工程优化

### 6.1 计算瓶颈
### 6.2 优化方法逐项解释
### 6.3 在线/离线收益

## 7. 实验设计

### 7.1 数据集和任务
### 7.2 Baseline 分组
### 7.3 指标
### 7.4 主结果

## 8. 消融实验

<Explain what each ablation proves.>

## 9. Scaling/复杂度/效率

## 10. 论文价值

## 11. 局限和谨慎点

## 12. 复现或落地建议

## 13. 汇报话术

## 14. 最终 takeaway
```

## Useful Chinese Phrases

- "这篇论文的关键不在于简单使用 X，而在于把 Y 和 Z 统一到同一个框架中。"
- "这个 baseline 组的作用是控制 A 不变，只替换 B，从而验证 B 的贡献。"
- "更稳妥的表述是：论文没有明确声明 X；从结构上看，它主要依赖 Y。"
- "这里的压缩不应理解成简单删除信息，而是减少深层中某类表示参与计算的数量。"
- "这个设计是在表达力和效率之间做折中。"
- "如果要落地，不建议一开始复现最大模型，而应先验证最关键的结构假设。"

## Baseline Explanation Mini-Template

```markdown
### 对比模型架构怎么理解

这张表不是简单罗列 baseline，而是在逐层回答：

1. 传统 base model 表现如何？
2. 只增强特征交互是否有效？
3. 只增强序列建模是否有效？
4. 统一框架是否超过强分离式 baseline？

<Then explain each group with controlled component, replaced component, and conclusion.>
```

## Optimization Explanation Mini-Template

```markdown
### <Optimization>

它解决的瓶颈是：<memory/io/compute/latency/redundant computation>。

机制是：<short mechanism>.

在本文中，它的意义是：<connect to sequence length, model depth, online serving, caching, etc.>.

取舍是：<extra compute, precision risk, implementation complexity, cache invalidation, etc.>.
```
