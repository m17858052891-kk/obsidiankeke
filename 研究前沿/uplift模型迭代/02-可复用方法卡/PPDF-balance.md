---
type: "方法"
topics: ["uplift模型迭代", "目标相关矩平衡与校准噪声"]
status: "维护中"
created: "2026-11-05"
module_id: "arxiv:2610.12332:balance"
evidence_types: ["理论", "错设压力实验"]
local_validation: "未验证"
---

# 目标相关矩平衡与校准噪声

来源：[[研究前沿/uplift模型迭代/01-论文原文与精读/PPDF/精读|PPDF 关键方法精读]]；定位：§3.2–3.3，公式（8）–（14）；§4.3；Table 11。

## 机制、接口与采用边界

输入为 RCT/OBS 协变量、基础密度比和辅助函数；输出为归一化校准权重。对基础比值作指数倾斜，令 OBS 加权特征均值接近 RCT 均值：

$$
\widehat r_{BAL}(x)\propto\widehat r_{base}(x)\exp(\widehat\xi^\top f(x)).
$$

ATE 重点平衡 $\widehat g$；CATE 的线性 sieve 还需其乘积矩，不能只匹配一个均值。离线使用 nuisance 数据拟合比值，再用分开的调参与评估数据；ATE 区间额外计算校准噪声方差。**训练集平衡精确不代表总体偏差为零。**

最小单元为目标相关平衡器与对应的方差/损失修正，依赖 RCT 目标人群和支持重叠。原文 Proposition 1 给出偏移等于 $\omega\,\mathrm{imb}_{\widehat g}(r)$；Table 11 检验错设密度比。可借鉴到领域迁移后的因果评估，不能作为无条件去混杂工具。代码入口 `fuse_ate`/`fuse_cate` 已核验，底层各平衡器未逐函数审计。

## 本地验证

尚未运行。论文结果、移植推断与本地结果分别记录。

候选验证：[[研究前沿/uplift模型迭代/03-实验假设与结果/2026-11-05-PPDF-候选假设|关联假设（待设计、未运行）]]。
