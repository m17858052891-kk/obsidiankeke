---
name: paper-markdown-section-deep-dive
description: Create or update complete Obsidian/Markdown paper-analysis documents with section-by-section translation and explanation, tightly cropped original figures and tables, fully covered portable formulas, and brief plain-language explanations for complex modules. Use when the user asks to 梳理、拆解、逐节翻译、补充图片公式、完整覆盖论文、整理论文 Markdown or Obsidian notes.
---

# Paper Markdown Section Deep Dive

## Purpose

Turn a research paper into a reusable Chinese Markdown/Obsidian note. The note must completely cover the paper, follow its own structure after a deduplicated opening section, preserve all source formulas and figure/table content, explain difficult modules briefly, and render correctly in Markdown.

## Required Scope

Unless the user asks otherwise:

- Cover the abstract, introduction, related work, preliminaries, method, theory, experiments, conclusion, and appendices that contain technical content.
- Translate or summarize every section and subsection. Do not skip content merely because it is implementation-specific, mathematically difficult, or appears only in an appendix.
- Cover every source equation, figure, table, and algorithm in the included sections. If an item is intentionally omitted because it is an exact duplicate, record the reason and point to the earlier coverage.
- Keep a clear distinction between what the paper states, what the figures show, and what is an interpretation.

## Workflow

1. Locate the target Markdown note and read its existing structure before editing.
2. Obtain the authoritative paper source: arXiv HTML/PDF/source or the publisher version.
3. Build a coverage ledger from the paper before editing. List every section/subsection, equation, figure, table, algorithm, and technical appendix item with its source number or page and a status of `pending`, `covered`, or `omitted with reason`.
4. Compare the coverage ledger with the existing note. Preserve useful user-written explanations, but merge repeated overview/abstract/introduction material and repair numbering when the structure changes.
5. Write each subsection in this order when appropriate:
   - What the paper is saying;
   - Plain-language explanation;
   - Formula, figure, table, or algorithm from the paper;
   - Why the component exists and what it contributes;
   - Boundary conditions or limitations explicitly supported by the paper.
6. Embed tightly cropped original paper figures, tables, and algorithm blocks. Do not substitute a large page screenshot for a figure or table.
7. Reconcile the completed note against the coverage ledger. Every item must be `covered` or have a specific omission reason.
8. Write the note, read it back, and inspect the rendered Markdown. Fix formula rendering, image paths, heading numbers, and delimiters before finishing.

## Recommended Note Structure

Use the paper's section order, adapted to Chinese prose:

```markdown
# <paper title>

论文：<paper URL>
代码：<code URL if available>
会议/版本：<venue or version>

## 1. 前置信息：总览、摘要与引言
### 1.1 一句话总览
### 1.2 研究背景与核心问题
### 1.3 核心思路与主要贡献

## 2. <从这里开始按论文原始章节顺序组织，包括 Related Work>
```

Merge overview, abstract, and introduction into one opening section organized by information rather than by source paragraph. State each motivation, problem, method idea, and contribution once. After this opening section, preserve the paper's original section order, including Related Work and technical appendices, while keeping heading numbers sequential in the note.

## Formula Portability Rules

Obsidian and other Markdown renderers may not support `\tag{}` consistently. Never leave paper equation tags in the final note. Convert:

```latex
$$
f(x)=x^2. \tag{4}
$$
```

to:

```latex
$$
f(x)=x^2. \qquad \text{(4)}
$$
```

Rules:

- Keep formulas in `$$ ... $$` blocks when they are displayed equations.
- Put the source equation number inside the same display using `\qquad \text{(n)}`.
- Preserve sub-equation labels such as `(4a)` and `(4b)`. Do not merge separately numbered equations into one unlabeled block.
- For a multiline equation, place the source number after the complete `aligned` or `gathered` expression, not on an arbitrary intermediate line.
- Preserve the paper's symbols and terms; do not silently rename variables.
- If the paper has an apparent typo, preserve the source form and add a short note explaining the ambiguity.
- Do not invent a formula when the paper only gives prose.
- Cover every formula in the included paper sections, including unnumbered formulas that define the method, loss, constraints, or inference procedure. Do not omit a formula because it is long or difficult.
- Only source equations may keep source equation numbers. Mark additional derivations as `等价变形` or `解释性公式` and do not assign them paper numbers.
- Put every inline variable or expression inside `$ ... $`; never leave raw forms such as `s_t`, `\rho_t`, `\frac`, `\widehat`, or `\mathcal` in ordinary prose.
- Remove unsupported source commands such as `\tag`, `\label`, `\ref`, and `\eqref` from display math. Replace prose references with Chinese text such as `公式（4）`.
- Check that every `$$` and LaTeX environment has a matching close, braces are balanced, and no currency symbol accidentally opens a math block.
- Rendering is the acceptance criterion: inspect the actual Markdown preview after writing. Syntactically balanced source is not sufficient if the renderer still shows raw LaTeX.

## Figure and Table Rules

- Cover every source figure, table, and algorithm in the included sections using the paper's original asset or a tight crop of the relevant object, not a full-page screenshot.
- Preserve figure numbering and captions, for example `Figure 2：模型总览`.
- Add one or two sentences explaining how to read the figure and which claim it supports.
- Preserve table values, units, arrows, bold/underline emphasis, mean/variance notation, and footnotes exactly as reported.
- Prefer the original tightly cropped table image. Add a Markdown transcription only when it materially improves searchability or explanation.
- Store assets beside the note or in a note-local assets folder with descriptive, collision-resistant names such as `Paper Figure 3 - Ablation.png`.
- Prefer portable Markdown embeds such as `![Figure 3：消融实验](./assets/Paper-Figure-3-Ablation.png)` and confirm every referenced asset exists.
- Normalize rendered display size instead of inheriting each crop's native pixel width. Use this default width profile unless the user or target renderer requires otherwise:
  - regular figures, short tables, and normal algorithm blocks: `760px`;
  - wide tables or very wide composite figures: `900px`;
  - unusually tall algorithm blocks or narrow vertical objects: `620px`.
- Center each object, preserve its aspect ratio, and allow it to shrink responsively on narrow viewports. Never stretch an image by forcing both width and height.
- When explicit sizing is needed, prefer portable inline HTML rather than Obsidian-only image-size syntax:

```html
<p align="center"><img src="./assets/Paper-Figure-3-Ablation.png" alt="Figure 3：消融实验" width="760" style="max-width: 100%; height: auto;"></p>
```

- Keep objects in the same category at the same rendered width. Deviate only when the aspect ratio would make an object unreadably small or excessively tall.

## Brief Plain-Language Explanations

For a complex module, loss, solver, sampling process, or training stage that the paper does not explain intuitively, add only one or two sentences after the faithful technical description:

```markdown
**直观理解：** <输入什么、做了什么、为什么需要它。>
```

- Keep the explanation short and concrete; do not turn it into a second long derivation.
- Make clear that it is an explanatory interpretation, not a direct paper claim.
- Do not invent unspecified architecture, dimensions, losses, causal claims, or implementation details. If the missing detail matters, state `论文未说明`.

## Technical Explanation Rules

For model papers, explicitly identify:

- The input unit: state, action, token, trajectory, impression, or window;
- The output at each level: trajectory-level, window-level, or impression-level;
- The data flow between modules;
- The exact loss for each module;
- Whether a component is trained jointly, in stages, or only used at inference;
- Which constraints are hard controls and which are only conditions, rewards, penalties, or fallback heuristics;
- The source of every prediction used to generate an exploration or fallback action.

For diffusion papers, separately explain:

1. What is diffused: state, action, trajectory, or latent representation;
2. The forward noising process and its schedule;
3. The reverse denoising process and what is fixed during sampling;
4. The conditioning variables;
5. The decoder or inverse-dynamics step that converts generated objects into executable actions.

For experiments, connect each result to a claim:

- Main table: whether the proposed method improves the target metric;
- Ablation: which component is necessary;
- Sensitivity/stability: where the method is fragile;
- Online test: whether the offline improvement survives deployment constraints.

## Source Fidelity and Uncertainty

- Prefer exact paper wording and equations over secondary summaries.
- Say “论文明确说明” for explicit claims.
- Say “从图中可以看出” for visual observations.
- Say “一个合理解释是” for interpretation.
- If the paper does not specify a network type, loss, or deployment detail, write that it is unspecified rather than assuming an MLP, Transformer, or standard loss.

## Update and Validation Checklist

Before finishing an existing note:

- [ ] Overview, abstract, and introduction are integrated into one opening section without repeating the same motivation or contribution.
- [ ] Related Work is covered in its original position.
- [ ] Every source section and subsection is marked `covered` in the coverage ledger or has a specific omission reason.
- [ ] Headings are sequential after any merge.
- [ ] No `\tag{}` remains in the Markdown.
- [ ] Every source formula is present; numbered formulas retain a portable `(n)` label and added explanations do not reuse paper numbers.
- [ ] Inline symbols and LaTeX commands are enclosed in math delimiters.
- [ ] Every embedded figure path exists.
- [ ] Every source figure, table, and algorithm is represented by a tight object-level crop rather than a broad paper-page screenshot.
- [ ] Rendered image widths follow the standard profile: `760px` for regular objects, `900px` for wide objects, and `620px` for unusually tall objects, unless an aspect-ratio exception is necessary.
- [ ] Images are centered, preserve their aspect ratio, and shrink responsively without overflowing on narrow screens.
- [ ] Every `$$` block and LaTeX environment is balanced.
- [ ] The actual rendered preview shows formulas, figures, and tables correctly; no raw LaTeX remains visible.
- [ ] Complex modules without an intuitive paper explanation have a one- or two-sentence `直观理解` block.
- [ ] Main claims, ablations, limitations, and online results are tied to paper evidence.
- [ ] The updated file is read back after writing to the user's Obsidian vault.
