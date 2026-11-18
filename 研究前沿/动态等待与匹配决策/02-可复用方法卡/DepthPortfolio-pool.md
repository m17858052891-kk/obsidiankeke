---
type: "方法"
topics: ["动态等待与匹配决策"]
status: "维护中"
created: "2026-11-13"
module_id: "DepthPortfolio-pool"
source_papers: ["arxiv:2611.12293"]
version: "v1"
local_validation: "未运行"
---

# 不同候选来源值得在何时多取一次

[[研究前沿/动态等待与匹配决策/01-论文原文与精读/DepthPortfolio/精读|Depth as a Candidate Source: Portfolio Allocation for Recurrent Test-Time Scaling in Large Language Models]]

## 输入、流程与输出

训练需多个来源的已缓存候选、题目标签与冻结选择器；按已取候选、选择器反馈和剩余预算建状态，以继续取一个或停止为动作，屏蔽超预算选项；奖励为选中正确性前后差。线上输出来源或停止。

## 最小采用单元与依赖

最小采用单元是候选缓存、同一选择器与预算掩码共同构成的回放接口，可先跑固定配比再比较学得策略。真实部署需重测产生候选及选择的总时延。

## 原文证据与实现

§4.1–4.2、图 5、附录 F 表 12–14。比较固定池内分配，实际耗费可低于共同上限。

作者在官方摘要及正文给出匿名仓库。网页和文件 API 均返回 403；文件入口、提交号及一键重现能力未核实。训练与评测协议见 §4.2、附录 D/F。[作者链接](https://anonymous.4open.science/r/LLM-latent-B7BC/)

[[研究前沿/动态等待与匹配决策/03-实验假设与结果/DepthPortfolio-selector|分配收益来自候选覆盖、更多实际计算，还是更好的停止时机]]
