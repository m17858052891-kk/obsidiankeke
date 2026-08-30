# AUCC、AUUC、Qini 的区别与使用方式

## 先给结论

三者都评估 uplift 排序，而不是普通分类 AUC。AUUC 通常是 uplift curve 下的面积；Qini 是对 treatment/control 样本量进行校正后的增量曲线，常进一步相对随机策略做归一化；AUCC 在实际业务/代码中常被用作“累计增量曲线面积”的统称，必须先确认本项目实现的纵轴与随机基线。这里的 Call AUCC 是项目主排序目标，Qini 及 treatment-ratio 用于交叉诊断而非替代。

## 1. 为什么普通 AUC 不够

普通 AUC 评价“call 与 no-call 能否分开”，却无法区分两类人：不发券也会 call 的自然高响应者，和只有发券才会 call 的可拉动者。后者才是 uplift 排序与补贴决策真正需要优先的人。

## 2. 从排序到累计增量曲线

对某一 treatment 与 control，把样本按 $\hat\tau$ 降序排列。对前 $k$ 个样本，最原始的累计增量估计可理解为 treatment outcome 与按比例校正的 control outcome 差：

$$
U(k)=\sum_{i\le k,W_i=t}y_i-\frac{n_t(k)}{n_c(k)}\sum_{i\le k,W_i=c}y_i
$$

不同工具可能使用 Horvitz–Thompson/IPW、按全局比例而非前缀比例、归一化人数或 call 数等不同实现。比较任何两个数字前必须统一这部分口径。

## 3. AUUC 与 AUCC

**AUUC（Area Under the Uplift Curve）**：对 $U(k)$ 或归一化后的 uplift curve 积分/求和；衡量模型在不同投放覆盖率下累计增量的总体表现。

**AUCC（Area Under the Cumulative Curve）**：常被泛称为累计增益/累计呼叫增量曲线下面积。在本项目中是 Call AUCC，强调 outcome 是 call。部分平台把 AUCC 与 AUUC 当同义词，部分平台使用不同归一化方式或用相对随机的面积，因此**名称本身不足以判断可比性**。

项目报告时应补足：“按每个档位相对 100 control 计算；排序按预测 uplift；曲线为累计 call 增量的某实现；指标如何跨档聚合”。

## 4. Qini

Qini curve 也是按预测 uplift 排序后累计 treatment-control 增量的曲线，但强调对两组样本数量不同进行校正。Qini coefficient 通常表示该曲线与随机 targeting 基线之间的面积差：

$$
Q=\int_0^1\{Qini(q)-Qini_{random}(q)\}\,dq
$$

具体符号、是否归一化、random 是否为零，取决于实现。随机指标不一定为 0：若报告的是原始累计曲线面积或有限样本估计，它可能保留总体 ATE、样本不平衡或归一化常数。

## 5. 对比表

| 维度 | AUCC / Call AUCC | AUUC | Qini |
| --- | --- | --- | --- |
| 关注点 | 本项目中累计 call 增量排序 | 累计 uplift 增量 | 校正组样本量后的增量与随机差异 |
| 常见用途 | 主业务排序指标 | 通用 uplift 排序指标 | 模型比较、可比性诊断 |
| 是否有统一定义 | 否，强依赖平台 | 相对常见，仍有实现差异 | 仍有多个实现 |
| 是否足够做模型选择 | 否 | 否 | 否 |
| 本项目角色 | 主指标 | 辅助/口径核验 | 辅助指标 + ratio 诊断 |

## 6. 本项目的模型选择方式

不能仅选 Avg AUCC、Call MTAUCC 或 Avg Qini 中最大的单点。不同档位的样本量、SNR 与业务优先级不同，聚合方式不同会产生不同最优点。推荐固定：

1. 预先声明主指标（Call MTAUCC）；
2. 同时报告各档位 AUCC/Qini、Random、ATE error 与 treatment-ratio；
3. 用 validation 调参，test 只做最终确认；
4. 做多 seed、时间与人群切分；
5. 最终由线上随机实验验证增量和成本。
