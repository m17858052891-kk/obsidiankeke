---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-13"
module_id: "SparsePredictDemote-sparse"
source_papers: ["arxiv:2611.10293"]
version: "v1"
local_validation: "未运行"
---

# 按已获服务时长抽查，再把长任务降级

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/SparsePredictDemote/精读|Sparse Predict and Demote: Optimal Scheduling with Minimal Size Advice]]

## 输入、流程与输出

输入已服务量、负载、服务量分布与抽查成本；到触发量后抽 Bernoulli(q)，问剩余量是否超过 b；返回继续高优先级或永久降级。线上需要支持抢占并记录已获服务量。

## 最小采用单元与依赖

最小单元是稀疏查询加永久降级；低优先队列的排序、触发参数与尾部分布共同决定能否引用同阶保证。调参在服务前，预测成本必须计入占用。

## 原文证据与实现

图 1；定理 3.8、4.3、4.6、4.7 与 5.7，数值见图 2。

核对版本页与全文，未见官方仓库；原理可按 §4 图 1 及式中四个参数定义重建。

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/SparsePredictDemote-inference|把预测本身占用的处理时间算进去，稀疏查询何时得益]]
