---
name: artifact-template-method-cards
description: "Create an image using the 方法检验图 Method Cards template and its retained reference file. Use when the user selects this template, names 方法检验图 Method Cards, or explicitly invokes $artifact-template-method-cards. 将模型评估、实验检验与技术方法沉淀为清晰的中文图片：蓝白卡片、图示与公式并排、检验原因及判据。适用于沿用响应模型检验图风格的新图或改图；不用于单纯文字答疑。"
---

# 方法检验图 Method Cards

Create an image from this template. Keep the reference file unchanged.

## Workflow

1. Read `artifact-template.json` and resolve its paths relative to this skill directory.
2. Invoke $imagegen with the retained PNG as a reference image and the user's requested content as the edit or generation brief.
3. Treat the user's prompt and available sources as the content input. Do not invent factual claims merely to fill the composition.
4. Preserve the reference's visual language unless the user explicitly requests a deviation.
5. Visually inspect the generated image for fidelity and defects, then return the final image.

## Fidelity

Preserve the reference image's composition, visual hierarchy, palette, typography, material treatment, lighting, and recurring brand elements.

User instructions control requested content and explicit deviations. The retained reference controls layout and formatting where the user has not requested a change.


## 本模板的使用约定

这是用于方法沉淀的中文科研/业务评估图片模板。默认展示“检验什么、为什么检验、怎么计算、什么标准算好”，而不是当前实验结果。用户明确要结果时，才加入有来源的数值。用户的新指令优先于这些默认风格。

### 先确定内容，再生成图片

- 把每个方法压缩成四项：一个直白问题、一句检验原因、一个解释机制的图示、核心公式与检验标准。不要把整段解释缩小后塞入画布。
- 核对评估对象、实际分组/预测分组、样本范围、参照来源、符号、聚合权重、差值方向和单位。资料未说明的实现不要擅自写成既有事实；可明确为建议口径。
- 原图是视觉参考，不是新任务的事实来源。不能照搬原图的档位、分组数、95% 区间、样本范围等条件。
- 先在心中或草稿中完成内容梳理；资料足够时直接出图，不要求用户先批准提纲。
- 仅在绘制因果效应/uplift 评估图时，读 [references/causal-checks.md](references/causal-checks.md) 核对易错点。其他领域不套用这些统计公式。

### 视觉语言

- 用 assets/reference.png 作为唯一主视觉参考：白色背景、深海军蓝文字、蓝色和青绿色分区、浅色判据底框、细边框圆角卡片、宽松留白；弱化渐变和装饰纹理，优先清晰度。
- 页面顶部使用大标题和一句简短总览。多项方法采用纵向平行卡片；通常每页 2–4 项，过密就拆页。单项解释可以输出横向单卡，不强制长图。
- 每张卡片的色条包含编号、方法名称、一个口语化问题；右侧一句“为什么检验”。卡片主体左侧为图示，右侧为公式；底部用浅色条承载“检验标准”。
- 方法之间是并列关系，不使用连接整张图的大流程图、密集箭头或思维导图。单项内部可用少量箭头解释分组、预测、比较等操作。
- 图示要承担解释功能：同一批样本、排序条、分组小人、散点与校准线、并列基线等；不用无意义装饰替代方法。
- 公式每项一般 1–2 组，必要符号就近解释；公共符号只放一个简洁定义区。长公式应增宽或拆页，不能缩成看不清的小字。
- 默认不添加逐卡“注意事项”、免责声明或冗长尾注；影响理解的必要限定直接融入轴标签、定义或标准，例如“DR 估计参照”“示意，非实验结果”。
- 不把“显著改善判据”写成“已经显著改善”的结果句。用“越小越好”“95% CI 下界 > 0”等可核验判据，前提是来源和检验方向支持它们；不杜撰阈值。

### 生成、修改与交付

- 使用当前可用的 imagegen skill 和图像生成工具，将保留的参考 PNG 作为风格参考，传入已核对的中文文案、公式、排版要求。不要只交付 Mermaid、HTML、提示词或文字方案来代替用户要的图片。
- 修改现有图时，以用户指定或最近确认的图为编辑输入，改动请求涉及的部分；保留其他已认可的结构和内容。新主题生成时只继承风格，替换旧主题文字与数据。
- 将实际提示词与最终 PNG 保存在当前项目的输出目录；本工作区沿用 outputs/。其他项目跟随用户指定目录，避免写死本会话路径。
- 查看最终成图：核对中文、公式上下标/求和范围/正负号、轴名称、分组颜色、样本口径、图文对应及可读性。发现公式或文字错误后继续修图，不能因为视觉漂亮就交付错误图片。
- 最终用绝对路径内嵌 PNG，并附简短说明；用户未要求时不额外交付 PPT、网页或 PDF。

### 可复用绘图提示词骨架

“以附图为视觉风格参考，绘制一张中文方法说明图片。主题：{主题}。内容表达方法与判据，不编造当前结果。使用白底、深蓝文字、蓝/青绿平行卡片、清晰大字和充足留白。每卡包含：{方法名与直白问题}、{为什么检验}、左侧{解释图示}、右侧{准确公式及符号}、浅色标准框{判据}。模块并列，不做整页流程图；默认没有逐项注意事项。示意数值和示意曲线明确标注。严格保留提供的公式，避免文字溢出、字符错写和过密排版。”
