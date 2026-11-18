---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-14"
module_id: "ListUpdateWindows-head"
source_papers: ["arxiv:2611.17083"]
version: "v1"
local_validation: "未运行"
---

# 到期前先清掉当前表首的请求

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/ListUpdateWindows/精读|List Update with Time Windows and Delays without Batch-Serving]]

## 输入、动作与输出

输入表序、所有已到达且未完成请求和当前截止事件。若到期项仍在，先清空表首对应的活跃请求；再对仍待处理的到期项访问并移首。输出逐笔访问序列及新表序。

## 使用时点与依赖

在线到截止运行，必须保留即时访问、访问后可免费前移及每笔单独收费的模型。

## 原文证据与实现

§3.2 算法 1、定理 3.2，k 是输入时窗最大重叠。

未核到作者仓库。正文算法 1、2、3 与 §5.2 提供执行规则。

## 迁移假设

在相同请求流和初始列表上比较 FER、纯到期移首与到达即移首；同类请求逐笔收费。用小实例精确枚举对照。本地尚未验证。

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/ListUpdateWindows-separate|逐笔收费后，表首清理比只看截止多赚多少]]
