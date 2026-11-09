# 博报堂 Ad-POM：先决定素材组合结构，再选择具体素材

论文：**Ad Asset Portfolio Optimization via Policy Learning**。Koichi Tanaka（庆应大学）、Zhi Wang / Masahiro Asami / Kota Ishizuka（HAKUHODO Technologies）、Kosuke Kawakami（HAKUHODO Technologies / Institute of Science Tokyo）、Yuta Saito（Hanjuku-kaso）。AdKDD workshop，2026-08-10。

来源：[官方论文页](https://www.adkdd.org/papers/ad-asset-portfolio-optimization-via-policy-learning/2026) · [6 页全文，官方 S3](https://s3.us-west-1.amazonaws.com/papers.adkdd.org/2026/papers/adkdd26-tanaka-ad.pdf) · [企业 2026-08-06 公告](https://www.hakuhodody-holdings.co.jp/news/corporate/2026/08/6671.html)。检索日 2026-11-07；已逐页读全文，视觉核对 Eq.10–18 / Algorithm 1 / Figure 2–3。首次公开日仍未完全确定。原摘要级卡升级为全文卡。

**源信息纠错**：官网英文摘要把 independent/exact 的 high variance/high bias 顺序写反；PDF 摘要与正文正确区分“独立相加遗漏交互导致偏差、完整组合 IPS 导致高方差”。PDF 的 Yuta Saito 署名是 Hanjuku-kaso，企业新闻所列单位与 PDF 不同，这里以论文署名为准。PDF 页脚含占位 DOI/ISBN，不把占位符写成真实出版标识。

## 本次独立审计记录

复核截止：**2026-11-07（Asia/Shanghai）**。证据状态：**正文可得但关键材料缺失**：6页官方稿、Eq.1–18、Algorithm1、Figure1–3已核；稿内无单列附录，没有完整证明/精确实验配置可核。采用结论：**需先补关键条件**。

|日期类型|核验结果|
|---|---|
|首次公开|已核企业公告2026-08-06；这不是已证实的全文首发日，更早预印本未核|
|修订|官方PDF无版本历史，本次固定本地6页稿及其校验值|
|会议|AdKDD 2026-08-10；企业/大学作者归属按PDF首页|
|正式出版|PDF DOI/ISBN仍为占位符；[workshop官网](https://www.adkdd.org/)称proceedings将经Springer出版，具体正式出版日尚未核实|

【原文事实】干预对象为整套提交素材向量，比较的是新旧portfolio policy；样本是context—集合—reward日志，实验用产品context，目标为策略价值而非用户ATE。没有真实线上treatment随机化/结果窗可报告，半合成日志为2000条、25个seed；实际投放成熟窗需落地时另定。

训练需要context、完整组合、整组reward、logging概率及meta映射；部署用context、可用素材/quality特征、固定映射与两阶段策略，不用未来reward。与传统OPL复用importance weighting、policy gradient和reward regression；新增是广告portfolio问题的meta参数化、组合构造及相应估计分析。POTEC等已有两阶段路线只作谱系参照，不据此宣称本文实比或胜过它。

## 1. 一句话结论

Ad-POM 改的是广告主**提交哪些素材组成一个候选集合**：先在低维空间学组合大小、多样性等结构，再在该结构内挑素材，用 meta 层重加权和组内奖励回归控制组合动作空间的方差与偏差。它不是素材生成器，也不是平台已有的“从素材集合给用户挑一张”的在线排序器。

论文给出半合成实验的机制证据，没有线上增量转化或 ROI 结果。主结果包含使用真实奖励结构的 oracle 版本；实用参考应优先看不知道真实 diversity function 的变体。

## 2. 旧 pipeline 与为什么单张素材模型不够

原链路：

```text
生成/制作大量候选素材
  → 广告主按单张CTR、经验或固定数量选一个portfolio
  → 提交平台
  → 平台display algorithm在该portfolio内探索并给用户选素材
  → 点击/转化与探索成本
```

候选太少：平台即便有很强的个性化模型，也无法给不同用户找到合适内容。候选太多：每张素材需要探索，有限预算被分散。多张高 CTR 素材若内容高度相似，也可能不能互补覆盖用户偏好。

本文把上游“构造素材集合”显式定义为 Ad-POP（ad asset portfolio optimization）；Ad-POM 是解法名（via meta information）。这里 reward 是整组素材供平台使用后的表现，天然可能含成员之间互补/替代和探索成本。

## 3. 问题形式与识别条件

context $x$ 可代表平台、campaign 或产品；素材全集 $\mathcal B$；portfolio $a\in\{0,1\}^{|\mathcal B|}$，每位表示是否提交该素材。历史日志 $D=\{(x_i,a_i,r_i)\}_{i=1}^n$ 由 logging policy $\pi_0$ 产生。

$$
q(x,a)=E[r\mid x,a],\qquad
V(\pi)=E_{p(x)\pi(a\mid x)}[q(x,a)].
$$

目标是学一个新 portfolio policy 最大化 $V$，不是估计“曝光广告 vs 不曝光”的用户 ATT。其因果/反事实成分是 **在同一个 context 下，改用另一套素材提交策略会得到什么 reward**。

推断要求 logging probabilities 可得/可信、历史与目标环境的 reward mechanism 可迁移、样本与 context 设置满足所述 bandit model。semi-synthetic 实验直接生成 logging probabilities，这并不证明真实业务日志里能准确回收 propensity 或排除 selection bias。

## 4. Baseline 矩阵：替换了什么，哪个假设出问题

| 动作表示/学习方式 | 本文比较器 | 做法 | 方差/偏差瓶颈 |
|---|---|---|---|
| 完整组合、policy gradient | IPS-PG，Eq.3 | 整个集合当一个 action，$\pi(a\mid x)/\pi_0(a\mid x)$ 加权 reward×score | 组合概率很小，重要性权重极端；需 full portfolio support |
| 完整组合、reward regression | Reg-based，Eq.4 | 预测每个 $q(x,a)$，取 argmax | 不受IPS权重方差，但未见/少见组合的预测外推偏差大 |
| 独立素材、policy gradient | PI-PG，Eq.5 | 用 asset-wise 权重与 score；假设 $q=\sum\eta$ | 动作空间更小，但相加假设不成立时有偏 |
| 独立素材、reward regression | Independent Reg-based，Eq.6 | 学单张价值后拼集合 | 忽略多样性与交互，可能选一组重复高分素材 |
| meta 分解 | Ad-POM | 第一阶段meta policy gradient，第二阶段回归/贪心 | 用更小空间控制权重，但依赖meta选择和组内奖励差准确性 |

这是一组“表示空间 × 学习方式”的受控比较，不是四个强弱模型名字。exact 不意味着无误差：IPS 的主要问题是方差，exact regression 则可能严重有偏。独立模型也不总差，在真正可加的 reward 下可以更好。

## 5. 两阶段结构与数据流

$$
\pi^{overall}_{\theta,\phi}(a\mid x)
=\sum_{m\in\mathcal M}\pi^1_\theta(m\mid x)\pi^2_\phi(a\mid x,m).
$$

$m$ 是预定义 meta，例如数量、多样性程度、成本权衡；$|\mathcal M|\ll|\mathcal A|$。第一阶段选“要怎样的组合”，第二阶段在该要求下选具体素材。

```text
历史(x,a,r) + logging policy + portfolio→meta映射
  ├→ 奖励回归 f̂(x,a) / 单素材价值 η̂(x,b)
  ├→ 训练/固定第二阶段 portfolio constructor π²(a|x,m)
  └→ meta重要性权重 × reward residual + 回归补偿
       → 第一阶段 policy gradient 更新 θ
部署：context → m（数量/多样性/成本偏好）→具体素材集合→既有平台投放器
```

理论部分先固定已经训练的第二阶段，再优化第一阶段；不应写成论文证明了两个阶段任意交替训练都收敛到全局最优。

## 6. 核心估计器：为什么只重加权 meta 还需要回归

记 $m_a$ 为 portfolio 对应的 meta，

$$
w_m(x,m)=\frac{\pi^1_\theta(m\mid x)}{\pi^1_0(m\mid x)},\quad
s_\theta(x,m)=\nabla_\theta\log\pi^1_\theta(m\mid x),
$$

$$
\widehat f^{\pi^2}(x,m)=E_{a\sim\pi^2_\phi(\cdot\mid x,m)}[\widehat f(x,a)].
$$

Eq.10 的 Ad-POM gradient：

$$
\widehat G=\frac1n\sum_i\left[
w_m(x_i,m_{a_i})\{r_i-\widehat f(x_i,a_i)\}s_\theta(x_i,m_{a_i})
+E_{m\sim\pi^1_\theta(\cdot\mid x_i)}\{\widehat f^{\pi^2}(x_i,m)s_\theta(x_i,m)\}
\right].
$$

**两个加项分别干什么：**

1. 第一项在 meta 空间校正 logging 与新策略选择频率的差异，但只对 reward residual 加权。比在完整集合空间做 IPS 更容易有充足日志支持。
2. 第二项把目标第二阶段将选出的具体 portfolios 的预测价值加回来。如果同一个 meta 下新旧第二阶段选的是不同素材，仅对 meta 重加权是不够的；此项负责组内差异。

不能把它简写成“压缩 action 后做 IPS，所以无偏”。回归修正和组内结构条件是关键，也不是在任意 propensity 正确时都自动成立的标准 doubly robust 保证。

## 7. CPC 条件、bias 与 variance 的实际含义

**Full meta support**：$\pi^1_0(m\mid x)>0$，比每个完整 portfolio 都出现的 full action support 弱。但 meta 里出现过某个 portfolio，不表示其他未见 portfolio 的 reward 真值突然可观测。

**Conditional Pairwise Correctness（CPC）**：对任意同 meta 的 $a,b$，

$$
q(x,a)-q(x,b)=\widehat f(x,a)-\widehat f(x,b).
$$

这是**奖励差值正确**，强于“排序正确”、AUC 高或整体 MSE 不错。直觉上，允许某个 meta 内所有预测带同一个加性偏移，因为这种偏移可由 residual 校正；但若把同 meta 内两套素材的真实差距预测错了，新旧第二阶段重新分配这些组合的概率就会引入偏差。

Theorem 3.1 的 bias 正比于组内 pairwise reward error 与新旧 action weight 差异的交互。Theorem 3.2 在 meta support + CPC 下给出 variance 分解：reward noise、regression error 和 context variation；前两项中放大噪声的是 $w_m$，而不是完整 portfolio 的极端权重。

这支持“合适的抽象可降低方差”，不意味着任何划分都比 IPS 方差低、更不意味着较少 meta 永远更好。粗 meta 减少权重波动，却扩大组内 reward 差异的回归难度；细 meta 减轻 CPC 压力，却重新变稀疏。这是应由数据验证的偏差—方差权衡。

全文对条件做理论陈述，但没有独立实证测量 CPC violation 与 estimator bias，也没有展示全套定理证明/代码复现。尤其未见组合的 CPC 依赖模型外推，不是支持条件本身保证。

## 8. 第二阶段：贪心构造，不是黑盒“学到组合交互”

结构示例为：

$$
\widetilde q(x,a)=\sum_{b\in a}\widehat\eta(x,b)+\lambda Div(a).
$$

给定素材数量 $d$ 和 diversity coefficient $\lambda$，Algorithm 1 从空集合起，重复 $d$ 次：

$$
b^*\leftarrow\arg\max_{b\notin a}\big[\widehat\eta(x,b)+\lambda Div(a\cup\{b\})\big].
$$

选完加入集合。它显式把单素材质量与组合多样性合并；不是任意复杂 pairwise interaction 的无约束学习。论文未给出 submodularity 等额外条件，不能宣称贪心输出全局最优 portfolio。

全文没有足够细节说明所有 regressors、policy network 架构、优化器、learning rate、meta 网格及训练/验证划分。Eq.6 书面表达只有 residual，缺少平方/其他损失及完整经验求和；复现者可以选择一个合理损失，但必须标为自己补的实现，不能说作者明确使用 MSE。

## 9. 数据与奖励：真实素材，不是真实组合回报

CreativeRanking 数据来自阿里 display advertising，含真实素材、展示/点击记录。论文把素材经 CLIP+PCA 压到 10 维向量 $e$，产品 context 是该产品素材向量的平均；单素材 $\eta(x,b)$ 用真实 CTR。然后**合成组合 reward 与 logging policy**。

$$
q(x,a)=(1-\lambda_g^*)\sum_{b\in a}\eta(x,b)+\lambda_g^*Div(a)-\lambda_c^*|a|,
$$

$$
Div(a)=1-\frac{1}{|a|^2}\sum_{i<j}\frac{e_i\cdot e_j}{\|e_i\|\|e_j\|},\quad
r\sim N(q(x,a),0.5^2).
$$

$\lambda_g^*$ 控制多样性作用，$\lambda_c^*$ 用线性数量惩罚模拟探索成本；并没有真实运行 display bandit 记录完整探索轨迹。第一阶段 logger 为 meta-context softmax（β₁=−2），第二阶段为 true-reward softmax（β₂=5）。

默认 $n=2000$、每产品候选素材 $n_b=6$、$\lambda_g^*=0.5$、$\lambda_c^*=0.02$，25 个随机种子；候选数测试 5–9，对应 $2^5=32$ 到 $2^9=512$ 组合。该规模支持机制检验，不等同于十万素材/工业全组合的可运行性证明。

## 10. 主结果、实用变体与数值的正确读法

Figure 2 的纵轴是**策略价值除以最优策略价值**，不是 CTR 百分比，也不是线上 ROI。阴影是 95% CI；没有提供数值表，因此下面近似值仅用于读图，不能再计算精确 lift 或显著性。

必须区分两条 Ad-POM 线：

- **主 Ad-POM（橙色）**：正文 explicitly 令第二阶段奖励结构 $\widetilde q=q$，知道真实结构，作者称实践不可得。
- **w/o true diversity function（灰色）**：用另一种 $\widehat{Div}(a)=1-|a|^{-1}\sum_{i<j}\|e_i-e_j\|^2$，模拟不知道真实 diversity function 的场景。它仍是特定错设，不代表任意模型错设或未知组合交互都稳健。

| 实验切面 | 主 Ad-POM | 实用错设变体 | 最强传统线的大致水平 | 解读 |
|---|---:|---:|---:|---|
| Figure 2a，group effect≈0.5 | ≈0.48 | ≈0.45 | ≈0.40 | 交互存在时分解有优势；不能只和较弱PI-PG比 |
| Figure 2b，cost≈0.04 | ≈0.42 | ≈0.37 | ≈0.27 | 高成本下需要同时调数量与组合 |
| Figure 2c，9素材 | ≈0.47 | ≈0.44 | ≈0.41 | 实用变体优势缩小，CI需一起看 |

**关键反例**：当 $\lambda_g^*=0$，独立假设恰好成立，PI-PG / Independent Reg-based 优于 Ad-POM。新增组合模块有代价，不能把它当普适替代。

作者称组合数增加时整体更难，但图中各线并非逐点单调。随着 cost coefficient 从 0、0.02、0.04 增加，Figure 3 最常选的组合大小从 **4→3→1**；这比单纯“平均 reward 更高”更能验证第一阶段学到了数量/成本权衡。

## 11. 消融回答了什么，没有回答什么

| 操作 | 能解释的机制 | 仍不能推出 |
|---|---|---|
| 扫 group effect 0→1 | 独立相加在有多样性 reward 时失效 | 真实平台交互恰好等于所选 cosine diversity |
| 扫 cost 0→0.04 | 第一阶段可调整组合大小 | 真实探索成本是固定线性每素材成本 |
| 扫候选数5→9 | 更大组合空间下meta方法仍有优势 | 海量候选、训练/推理成本可工业扩展 |
| true vs wrong diversity | 对一种结构错设有一定容忍 | CPC在真实日志成立或任意错设无偏 |

缺少：固定第二阶段只换 gradient estimator 的充分消融；meta粒度/大小扫描；回归模型去掉/换弱强模型；CPC误差—实际bias关系；logging overlap/β变化与 effective sample size；独立 reward prediction + diversity heuristic 这个容易部署的强 baseline；线上策略 A/B。

## 12. 逐模块收益审计

### 12.1 meta压缩：减少极端权重，代价是组内模型必须承担更多解释

【原文事实】Eq.10将完整portfolio重要性权重换成meta权重，Theorem3.1/3.2在support与CPC条件下分析偏差/方差；Figure2c把素材数从5增至9，完整集合空间32→512，Ad-POM的归一化policy value更高，但同时改变了动作空间与组合选择难度。

【分析推断】低维meta频次高于单个组合频次→梯度少受一条罕见组合日志的大权重支配→第一阶段更稳定地学“投几张、要多大差异”→生成的素材集合发生变化→既有展示器有更合适的选择空间。例：10张图的几百种集合各只有很少记录，而“3张且中等多样性”可汇聚多个集合的信息。表示压缩本身不会创造未见组合的反事实数据。

【待验证假说】相同logger、数据、模型容量和优化器下，meta应提高ESS、降低梯度跨seed方差，并改善独立评估的policy value。替代解释是oracle第二阶段、基线未同等调参或合成reward正好贴合meta。若ESS改善却价值不升，或只在知道真实reward时胜出，应否定“降低权重方差已足以提高决策”的解释。meta过细重新稀疏，过粗则组内交互难学，不能只追求更少meta。

### 12.2 reward残差与组内差值：防止把同一meta内不同素材当成相同

【原文事实】Eq.10第一项加权残差，第二项补入目标第二阶段的预测reward；CPC要求同meta内$q(a)-q(b)$与预测差相等。正文没有独立测量CPC违反程度，也没有证明“propensity正确或reward正确任选一个”即可成立的一般DR性质。

【分析推断】保留组内差值→meta重加权后仍能分辨“同是3张图，一组互补、一组重复”→第二阶段选更适配的组合，而不是平均meta收益掩盖成员差异。允许同组整体预测偏移，但不允许把组合差距搞错；因此预测MSE或排序AUC相同也可能产生不同策略价值。

【待验证假说】在有随机组合数据的小空间上画组内pairwise error、组内新旧策略差异与最终偏差的关系。固定meta，只消融残差补偿/回归精度；若错误集中于策略最想迁移的组内组合且随迁移增大，必须缩小策略变化或细化meta。真实日志缺少选择概率、上下文漏掉广告主人工偏好、展示器版本改变，都会破坏OPL输入契约；不能靠加入残差项自动解决。

### 12.3 贪心constructor与多样性：结构假设可有用，但不是学会任意交互

【原文事实】Algorithm1按单素材价值+多样性贪心添加；主版本使用真实reward结构，另比较错设diversity函数的变体。Figure2a在交互系数0时独立方法更好，说明组合模块并非免费收益。未报告次模性或全局最优保证。

【分析推断】在确有重复/互补时，多样性项能阻止选出几张几乎相同的高CTR图→覆盖更多偏好→可能改善既有展示器的表现；例如三张同色同角度产品照可以换一张使用场景图。但颜色差异大不一定意味着用户价值互补，组合模型也可能为了多样性舍弃优质素材。

【待验证假说】保留同一quality模型和候选池，比较独立top-K、固定多样性贪心、学习meta+同constructor、小空间精确枚举。检查每步边际reward、组合重叠度和最优性缺口；如果真实组合reward近似可加或素材间互动方向与所选距离函数不符，应退回独立基线。文中“实用变体”仍有合成logger与reward，不能等同端到端真实业务部署结果。

### 12.4 规模/探索成本：在固定展示器与总曝光下才可能兑现

【原文事实】Eq.14以$-\lambda_c^*|a|$模拟探索成本；Figure3最常选的素材数随成本系数0/0.02/0.04由4→3→1。本文没有直接量化真实平台探索耗费、上线延迟或净利润。

【分析推断】减少低价值素材数量→展示算法少把有限曝光耗在探索上→更多流量用于高价值素材；但集合过小又会损失偏好覆盖。例：小campaign只有很少预算，提交50张图每张几乎学不到；提交3张可能更快集中，但大campaign可能从更多候选获益。

【待验证假说】实际试验中固定广告主预算、候选质量、展示器、总曝光与学习期，记录探索曝光份额、冷启动时长、最终点击/转化与成本。若净值提升仅来自更大投放量或换了展示算法，不能归因于portfolio优化；若真实探索代价随数量呈非线性或平台跨campaign共享学习，线性惩罚可能选得过少。只有真实探索代价曲线得到支持，才将合成λ解释为业务成本。

## 13. baseline与pipeline关系表

|现有方法或论文（关系身份）|共同问题|本文具体改动|可替换或组合|不能替换|接口与假设对齐|公平比较实验|
|---|---|---|---|---|---|---|
|IPS-PG、Reg-based（原文实比，Eq.3/4、Fig2）|完整组合离线策略优化|meta加权梯度+组内回归取代完整动作估计|替换OPL更新与portfolio选择层|不能替代真实logger和反事实支持|同context、组合空间、reward窗、数据/概率/算力|固定网络和constructor，比较bias/梯度方差/ESS及独立policy value|
|PI-PG、Independent Reg-based（原文实比，Eq.5/6）|以单素材价值构造集合|解除纯加和假设，加入组合结构|可复用单素材quality模型|不保证无交互时仍有益|同候选池、组合数量/成本、调参预算|交互强度与样本量二维对照；包含真实可加情形|
|oracle Ad-POM与错设diversity变体（原文实比）|两阶段组合构造|只改变奖励结构可知程度|oracle作机制上界线索；采用应看可得信息版本|不能把oracle结果当生产承诺|双方都不得用测试reward真值；清楚记录可见η/概率/特征|相同样本/seed，追加真正训练的reward模型并独立评估|
|[POTEC](https://arxiv.org/abs/2402.06151)（原文引用，未实比）|大动作空间的两阶段OPL|Ad-POM把上层解释为素材规模/多样性等meta，组内用组合constructor|可借鉴cluster选择+组内回归的接口|POTEC组内最优条件不自动覆盖本文贪心及业务组合约束|动作聚类与meta映射、局部差值条件、第二阶段可优化程度|统一动作/数据与第二阶段，比较不同抽象而非各用各的数据|
|BUOPLR、预算LP、用户uplift（分析补充）|在有限资源下选动作|这里选择广告主提交的整个集合|可在素材生成后、展示器前组合；另加预算层|不替换CATE、bidder、生成模型或多用户预算器|portfolio不是时间×样式；reward不是单用户treatment增量|只在动作/价值定义重建后做模块实验，不横比论文收益百分比|

## 14. 最小验证方案与采用结论

|项目|可执行方案|
|---|---|
|适用症状|独立top-K选出重复素材，扩大候选数却让小campaign探索期更长；完整组合IPS权重极端|
|数据前提|context、完整portfolio、成熟整组reward、可靠logging概率、稳定展示器；需一小批随机组合数据测组内差值|
|最小改动|先固定少量meta及greedy constructor，只替换完整动作IPS为meta残差梯度；不用oracle reward|
|固定项|候选素材、quality特征、样本量、logger、展示器、预算/曝光、训练与调参资源、独立测试划分|
|对照组|独立top-K、固定多样性贪心、完整IPS/回归、小空间精确枚举；用同一训练reward模型|
|中间诊断|ESS、权重尾部、梯度方差、组内pairwise error、meta覆盖、贪心缺口、组合大小、探索曝光比例|
|最终指标|独立随机日志上的policy value/保守OPE及CI；小流量线上相同实际预算下成熟转化与贡献毛利|
|失败判据|只在oracle/特定合成diversity有效；收益来自增加曝光；CPC误差在新策略高权重组放大；独立法同等或更优|
|后续步骤|小空间随机校验与非oracle结果通过后扩候选，再验证真实探索成本和部署时延；前提未齐不能称论文复现|

**采用结论：需先补关键条件。** 结构有清楚的偏差—方差依据，但真实portfolio日志、propensity和组内差值可验证性是入口。只有单素材CTR而没有组合reward时，最多做半合成机制验证；不能声称已确认营销业务收益。

**实现前还须澄清的原文缺口：** Eq.15/18包含$1/|a|$或$1/|a|^2$，而正文按$2^{n_b}$计组合数、向量定义允许全0；未清楚规定空portfolio的reward/diversity。应明确排除空集合或为其定义no-op价值，否则logger归一化和最优策略分母可能不同。这是可执行接口的歧义，不据此擅自改作者公式。Eq.6损失写法与未公开完整网络/调参配置的缺口也仍保留。

[本地完整原文](../原文/AdPOM_组合素材.pdf) · [返回阅读入口](../00-阅读入口.md) · [独立复核总报告](../09-独立逐篇复核报告.md)
