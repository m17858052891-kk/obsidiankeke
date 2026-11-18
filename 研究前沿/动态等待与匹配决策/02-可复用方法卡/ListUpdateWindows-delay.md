---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-14"
module_id: "ListUpdateWindows-delay"
source_papers: ["arxiv:2611.17083"]
version: "v1"
local_validation: "未运行"
---

# 用当前位置给同类累计等待定服务阈值

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/ListUpdateWindows/精读|List Update with Time Windows and Delays without Batch-Serving]]

## 输入、动作与输出

输入位置 x、同一元素所有未处理请求的当前延迟。总延迟达 2x/3 触发，将首访结果移到表首后逐笔清空同项。输出服务时点、新列表和各项访问费。

## 使用时点与依赖

无需训练，只需不断感知累计延迟和列表次序。无法瞬时完成访问时需重新建模。

## 原文证据与实现

§5.2 算法 3 与等待损失定理。软等待和硬截止使用各自对应的比较基准。

未核到作者仓库。正文算法 1、2、3 与 §5.2 提供执行规则。

## 迁移假设

在相同请求流和初始列表上比较 FER、纯到期移首与到达即移首；同类请求逐笔收费。用小实例精确枚举对照。本地尚未验证。

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/ListUpdateWindows-separate|逐笔收费后，表首清理比只看截止多赚多少]]
