# TaQFormer v1 覆盖清单

来源：[arXiv:2610.26199v1](https://arxiv.org/abs/2610.26199v1)。先于正文建立清单，完成后逐项回核。

主笔记：[TaQFormer：多维优惠券建模与 OBS–RCT 融合](TaQFormer%EF%BC%9A%E5%A4%9A%E7%BB%B4%E4%BC%98%E6%83%A0%E5%88%B8%E5%BB%BA%E6%A8%A1%E4%B8%8EOBS-RCT%E8%9E%8D%E5%90%88.md)。

| 类型 | 原文条目 | 笔记位置 | 状态／说明 |
|---|---|---|---|
| section | Abstract | §1 | covered |
| section | Introduction | §1 | covered |
| section | Related Work | §2 | covered |
| paragraph | Uplift modeling with structured treatments. | §2.1 | covered |
| paragraph | Combining randomized and observational data. | §2.2 | covered |
| paragraph | Transformers, model capacity, and efficient industrial inference. | §2.3 | covered |
| section | Problem Formulation | §3 | covered |
| subsection | Coupled multi-treatment setting | §3.1 | covered |
| subsection | Causal target and identification | §3.2 | covered |
| subsection | Decision formulation | §3.3 | covered |
| section | The TaQFormer Model | §4 | covered |
| subsection | Architecture | §4.1 | covered |
| paragraph | Feature tokenizer and encoder. | §4.1.2 | covered |
| paragraph | Compositional treatment encoding. | §4.1.3 | covered |
| paragraph | Treatment-aware cross-attention. | §4.1.4–4.1.5 | covered |
| subsection | Two-stage training: observational pretraining and randomized adaptation | §4.2 | covered |
| paragraph | Stage I: observational pretraining. | §4.2.1 | covered |
| paragraph | Stage II: parameter-efficient randomized fine-tune. | §4.2.2 | covered |
| paragraph | Instance-wise gated fusion. | §4.2.3–4.2.4 | covered |
| subsection | Treatment-parallel serving | §4.3 | covered |
| section | Experiments | §5 | covered |
| subsection | Experimental Setup | §5.1 | covered |
| paragraph | Metrics. | §5.1.2 | covered |
| paragraph | Implementation details. | §5.1.1、5.1.3 | covered |
| subsection | RQ1: Overall effectiveness | §5.2 | covered |
| subsection | RQ2: Architectural choices | §5.3 | covered |
| subsection | RQ3: Capacity selection | §5.4 | covered |
| subsection | RQ4: Two-stage training | §5.5 | covered |
| subsection | RQ5: Serving efficiency | §5.6 | covered |
| subsection | RQ6: Online impact | §5.7 | covered |
| section | Conclusion | §6 | covered |
| equation | 1 | §3.1 | covered |
| equation | 2 | §3.1 | covered |
| equation | 3 | §3.1 | covered |
| equation | 4 | §3.3 | covered |
| equation | 5 | §3.3 | covered |
| equation | 6 | §3.3 | covered |
| equation | 7 | §4.1.3 | covered |
| equation | 8 | §4.1.4 | covered |
| equation | 9 | §4.1.4 | covered |
| equation | 10 | §4.1.4 | covered |
| equation | 11 | §4.1.5 | covered |
| equation | 12 | §4.2.2 | covered |
| equation | 13 | §4.2.3 | covered |
| equation | 14 | §4.2.3 | covered |
| equation | 15 | §5.1.3 | covered |
| Figure | 1 | §4.1 | covered |
| Figure | 2 | §4.2 | covered |
| Figure | 3 | §5.4 | covered |
| Table | 1 | §5.2；5.3 复用 | covered |
| Table | 2 | §5.5 | covered |
| Table | 3 | §5.7 | covered |
| unnumbered | 因果目标与识别：潜在结果、CATE、响应曲面、四项假设及可识别表达式 | §3.2 | covered |
| unnumbered | 表示形状与解码初值 | §4.1 | covered |
| unnumbered | 两阶段共享前缀及 LoRA 参数 | §4.2.2、5.1.1 | covered |
| unnumbered | 并行服务张量形状及计算复杂度 | §4.3 | covered |
| unnumbered | 直接残差融合 | §5.5 | covered |
| unnumbered | 实验配置、指标与统计检验 | §5.1、5.7 | covered |
| unnumbered-detail | §3.1：类别索引、分品类网格与严格序关系 | §3.1 | covered |
| unnumbered-detail | §3.2：Y(a)∈{0,1}；τ(x;a,a₀)=E[Y(a)−Y(a₀)∣X=x] | §3.2 | covered |
| unnumbered-detail | §3.2：μ(x,a)=E[Y(a)∣X=x]；τ=μ(x,a)−μ(x,a₀) | §3.2 | covered |
| unnumbered-detail | §3.2：一致性、无干扰、条件交换性、正性 | §3.2 | covered |
| unnumbered-detail | §3.2：识别式 μ=E[Y∣X,A] 及条件均值差 | §3.2 | covered |
| unnumbered-detail | §3.3：cᵢₐr̂ᵢₐ、I={1,…,n}、二元 b 与逐请求和为 1 | §3.3 | covered |
| unnumbered-detail | §3.3：λ≥0 与全动作响应向量 | §3.3 | covered |
| unnumbered-detail | §4.1：X(x)、H(x)、T(a) 的 N×d/M×d 形状 | §4.1.1 | covered |
| unnumbered-detail | §4.1：eⱼ:Dⱼ→Rᵈ 与坐标参数共享 | §4.1.3 | covered |
| unnumbered-detail | §4.1：Z⁽⁰⁾=T(a) 与逐头 M×N 权重 | §4.1.4 | covered |
| unnumbered-detail | §4.2：共享前缀 L−Lₐ 与末尾 Lₐ 层；原文 L 的复用 | §4.2.2 | covered |
| unnumbered-detail | §4.2：冻结/适配 memory、独立 treatment 表征与 logits | §4.2.2–4.2.3 | covered |
| unnumbered-detail | §4.2：mean/max pooled gate 输入与 stop-gradient | §4.2.3–4.2.4 | covered |
| unnumbered-detail | §4.3：H(X): B×N×d；T(A): ∣A∣×M×d | §4.3 | covered |
| unnumbered-detail | §4.3：B∣A∣ decoder batch 与 B×∣A∣ 响应矩阵 | §4.3 | covered |
| unnumbered-detail | §4.3：∣A∣(Cenc+Cdec) → Cenc+∣A∣Cdec | §4.3 | covered |
| unnumbered-detail | §5.1：M=2、∣A∣=33、32 个 Qini 对照；全部网络配置 | §5.1 | covered |
| unnumbered-detail | §5.3 Figure 3 / §5.4：宽度集合与 L1–L4 深度配置 | §5.4 | covered |
| unnumbered-detail | §5.5：s(x,a)=sobs(x,a)+srct(x,a) | §5.5 | covered |
| unnumbered-detail | §5.7：5% 流量、p<0.05 与两个显著性上标 | §5.7 | covered |
| unnumbered-detail | Figure 1–2：图中简写网络/训练目标，与正文公式重复 | §4.1–4.2；原图完整保留 | covered |
| scope | 技术附录、独立算法块、独立理论证明 | §7 | omitted with reason；v1 原文不存在这些内容，不补造。 |
| bibliography | References（26 条） | §2、7 | covered；相关工作按原文归纳；完整条目保存在原始 PDF 与 BibTeX，不逐篇扩展。 |

## 验收记录

- 摘要与引言合并去重；保留 Related Work 位置；所有原文小节和段落标题已覆盖。
- 公式（1）—（15）齐全，使用同 display 内的可移植编号；另外覆盖方法性无编号公式。
- 图 1–3 来自独立原图 PDF，表 1–3 来自原论文对象级裁剪；表 1 在 RQ2 引用复用。
- 图片宽度：宽幅合成图 900px，表格 760px；居中、保持比例、自适应。
- Markdown 已写入后重新读取；源命令、数学分隔符、花括号、环境闭合和图片路径通过静态检查。
- 实际浏览器渲染检查记录另见 `assets/preview/validation.json`。
- 原文没有独立技术附录或算法块；无待覆盖条目。
