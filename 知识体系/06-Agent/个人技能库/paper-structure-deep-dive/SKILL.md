---
name: paper-structure-deep-dive
description: Produce rigorous, reusable deep dives for research papers, arXiv PDFs, conference papers, technical reports, and model/system papers. Use when the user asks to 梳理/拆解/解读/分析 a paper, compare its model architecture with baselines, explain methods/experiments/engineering optimizations, create or update a Markdown paper analysis document, or turn an ongoing paper discussion into a structured reusable report.
---

# Paper Structure Deep Dive

## Purpose

Use this skill to turn a paper into a structured, high-signal analysis that can be reused for notes, internal docs, interviews, reading groups, or engineering evaluation.

Prefer a Markdown deliverable when the user asks for a document, an artifact, a report, or to "加入到 md". Keep iterative additions consistent with the existing document's tone, numbering, and section depth.

## Core Workflow

1. Collect the source material.
   - If the user gives a URL or asks to look up a paper, use the available internet/PDF skills and cite stable links.
   - If a PDF or screenshot is attached, inspect it directly.
   - Prefer the paper text over secondary summaries.

2. Identify the paper type.
   - Model architecture paper: emphasize blocks, tokenization, parameterization, attention, training/inference.
   - System/industrial paper: emphasize deployment constraints, latency, caching, scaling, online metrics.
   - Benchmark/experiment paper: emphasize datasets, baselines, metrics, ablations, and validity.
   - Theory/algorithm paper: emphasize problem formalization, assumptions, objective, proof intuition, limitations.

3. Build the primary narrative.
   - What problem does it solve?
   - What was the previous dominant pattern?
   - What is the paper's central move?
   - What changes architecturally or algorithmically?
   - Why should this improve effectiveness or efficiency?
   - What evidence supports the claim?
   - What are the caveats?

4. Separate fact from inference.
   - Say "the paper states/reports" for explicit claims.
   - Say "a reasonable interpretation is" for inferred motivations or implications.
   - If the paper does not specify a detail, say so instead of filling in a common default.

5. Produce a layered explanation.
   - Start with a one-sentence summary.
   - Explain the old architecture or baseline before the proposed method.
   - Break the method into components.
   - Explain each component by role, mechanism, and why it exists.
   - Connect experiments back to the claims they support.
   - End with takeaways and practical adoption advice.

## Recommended Markdown Structure

Use this structure by default, adapting headings to the paper:

```markdown
# <Paper Title> 论文拆解

论文：<title>
链接：<abs/pdf/code if available>
版本/会议：<if known>

## 1. 一句话总结
## 2. 论文要解决什么问题
## 3. 背景范式/关键 baseline
## 4. 核心方法总览
## 5. 模型/算法结构拆解
## 6. 关键设计细节
## 7. 工程优化或实现细节
## 8. 实验设置和结果
## 9. 消融实验结论
## 10. Scaling/复杂度/效率分析
## 11. 论文价值
## 12. 局限和需要谨慎看的地方
## 13. 如果要复现或借鉴，应该关注什么
## 14. 面试或汇报时可以怎么讲
## 15. 最终 takeaway
```

For short answers, use the same thinking but collapse the output into fewer sections.

## Architecture Decomposition Pattern

When explaining a model architecture, use these passes:

1. Define the input units.
   - What is a token/sample/node/state?
   - What features are included?
   - How are raw features embedded or grouped?

2. Define the data flow.
   - Draw or describe `input -> module -> output`.
   - Name what each module consumes and produces.
   - State where fusion happens.

3. Explain parameter strategy.
   - Which parameters are shared?
   - Which are field-specific, token-specific, task-specific, or layer-specific?
   - Why is that choice efficient or expressive?

4. Explain interaction mechanism.
   - Attention, cross network, MLP mixer, graph message passing, retrieval, gating, contrastive loss, etc.
   - Say what interacts with what and under what mask/constraint.

5. Explain order/position information.
   - Identify explicit positional encoding if stated.
   - If not stated, say so.
   - Describe alternative structure carriers such as token order, masks, timestamps, type indicators, special tokens, or field-specific parameters.

6. Explain output heads and objectives.
   - What is predicted?
   - Which token/state feeds the head?
   - What losses or multi-task weights are used?

## Baseline Comparison Pattern

For experiment tables with grouped baselines, explain what each group changes.

Use this template:

```text
Base model:
  establishes the previous production/default architecture.

Feature-interaction group:
  keeps sequence modeling fixed, swaps feature interaction backbone.

Sequence-modeling group:
  keeps feature interaction fixed, swaps user/history/sequence encoder.

Unified framework:
  removes the hard boundary and jointly models the signals.
```

Then answer:

- Which component is being controlled?
- Which component is being replaced?
- What question does this group answer?
- What is the strongest separated baseline?
- Does the proposed method beat that strong baseline, not only the weak base?

## Engineering Optimization Pattern

For systems optimizations, explain each one by bottleneck and trade-off:

```text
Optimization -> bottleneck solved -> mechanism -> train/inference stage -> why it matters for this paper
```

Common Transformer examples:

- FlashAttention: avoid materializing full attention matrix and reduce HBM IO.
- Mixed precision: use BF16/FP16 for throughput and memory efficiency while preserving stability where needed.
- Activation recomputation: reduce training activation memory by recomputing during backward.
- KV cache: reuse historical K/V in causal attention during inference.

Always connect the optimization to the paper's architecture. For recommender Transformers, explicitly check whether user history, candidate items, or requests create reuse opportunities.

## Iterative Document Updates

When the user asks to add an explanation to an existing Markdown document:

1. Locate the relevant section with `rg` and read enough context.
2. Insert the new explanation where the reader would naturally need it.
3. Preserve numbering style and heading depth.
4. Avoid duplicating content already present.
5. If inserting a new subsection changes numbering, fix nearby duplicate numbers.
6. Final response should link the updated file and briefly say what changed.

## Quality Bar

- Be concrete about architecture and data flow; avoid generic "uses Transformer to learn representations" explanations.
- Explain why each design exists, not just what it is.
- Treat missing paper details explicitly as missing.
- Keep claims tied to paper evidence: main results, ablations, online tests, complexity, or qualitative analysis.
- Include limitations and adoption cautions.
- When writing Chinese reports, use clear Chinese technical prose with English terms preserved where helpful.

## Reference

For a compact reusable outline and phrase bank, read `references/markdown-outline.md` when creating a full Markdown paper report.
