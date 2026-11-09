# AdKDD 三篇全文获取与复核记录

执行日期：2026-11-07（Asia/Shanghai）。工作边界：仅新增 `work/round2/adkdd/`；未修改 outputs 或 Obsidian vault。

## 获取路径与原因

1. 重新打开三篇 AdKDD 官方论文页，核对作者、PDF/Slides/Video链接。
2. 官方页面 PDF 链接均为 `https://papers.adkdd.org/...`。web open/click 全部 timeout；终端 sandbox curl 先被本机代理权限挡住，require_escalated 后 HTTPS 仍 SSL timeout。
3. DNS 查询显示 `papers.adkdd.org` CNAME 为 `s3-website-us-west-1.amazonaws.com`。这类网站端点的 HTTPS 不可用；官方 HTTP 地址返回 HTTP 200，Content-Type application/pdf，Server AmazonS3。
4. 使用 HTTPS S3 对象端点 `https://s3.us-west-1.amazonaws.com/papers.adkdd.org/2026/papers/…` 下载成功；同时下载官方 HTTP 版本，三份各自逐字节相同。没有通过第三方重新打包来源代替官方全文。

| 论文 | 官方对象文件名 | 本地PDF | 页数 | SHA256 |
|---|---|---|---:|---|
| Tatari | adkdd26-kim-causal.pdf | materials/tatari.pdf | 6 | 58dd594a7c957c8b929ff43d2bd7ce64bd8b934df1e5ca056798df2746242979 |
| Teads | adkdd26-vodopija-estimating.pdf | materials/teads.pdf | 6 | 5abe2a260ae5eb79edc7d167e7e89dbdf1006d17704e8026d1809922e02461da |
| Ad-POM | adkdd26-tanaka-ad.pdf | materials/adpom.pdf | 6 | 71f45c164b09ec9df8cf6a121b26e316c4cc9e21f76936ee06f35310b971984c |

HTTP response headers 已保存为 `{tatari,teads,adpom}_http_headers.txt`。Last-Modified 是服务器对象修改时间，**不用于声称最早公开日期**。

## 阅读/视觉复核

- pypdf 逐页提取全文，`materials/{tatari,teads,adpom}.txt`；未只读摘要。
- bundled Poppler 渲染 Tatari pp.4–5、Teads/AdPOM全部6页为PNG。
- 已视觉检查 Tatari Table2–4 的数值/footnote、Teads Table2/Figure3、AdPOM Eq10–18/Algorithm1/Figure2–3。
- 图中数值没有数据表的 AdPOM，仅标注约数/读图近似，不编造精确提升率或显著性。
- 未运行论文复现实验，未生成新的算法表现数字。

## 代码来源

`git clone --depth 1 https://github.com/outbrain-inc/ab-tea-lab.git` 成功，目录 `materials/ab-tea-lab`。

复核 commit：`49f7fc0e5df52869acfe8fa92d631a99a2cd4d3c`。

读过：README、BayesianPoissonRegression、PoissonRegression、InverseVariance、RandomSimulator、Evaluator。主要发现是模型结构可印证，但默认采样、continuity correction 与DGP并非论文精确配置。卡片给出永久源码链接。没有将代码提供能力当作论文实际运行条件。

## 重要纠错清单

### Tatari

- matched ATT ≠ whole population ATE；CEM-weighted 不能自动识别无支持区域。
- R-learner不是geo四组比较的最优通吃方案；CEM+IPW四组点估计均在geoCI内，CEM+R三组。
- geo不是ground truth，且全DMA vs addressable matched群体目标不一致；宽CI的agreement辨别力弱。
- LaLonde的1.4%是bootstrap估计均值1819距1794，不是逐rep平均绝对误差；R+CEM-cut MAE922。
- Mobile App A/A因过滤会100%drop而使用未过滤样本；后验筛选负lift cells不能省略。
- 对称窗未独立消融；下一曝光截断可能内生；A/A不排除未测混杂。
- SBI 5min窗在§1写post、§4.1写pre，保留原文不一致。
- 33.8×是两个内部估计器的访问增量估计比，不是业务转化增长。

### Teads

- θ是campaign平均log CVI ratio，非总conversion/总spend lift。
- CaseIII不发布主要来自ROPE门槛；同HBM以0为门槛也会显著。
- HDI跨ROPE边界但变窄＝精确但边界未决，不能称已证明等价。
- 无optional-stopping定理；经验校准不替代保证。
- 缺GLMM/HKSJ强baseline与advertiser-level treatment dependence。
- 低spend过滤两臂资格规则/estimand需明确，零conversions不应自动删去。
- 原文称200rep但若干百分比并非0.5个百分点整数倍，仅按原表记录、不倒推计数。

### Ad-POM

- 官网摘要bias/variance顺序写反，以PDF为准。
- 第二阶段主版本使用真实reward structure；实用错误diversity版本独立讨论。
- CPC是同meta内真实奖励差准确，不仅排序正确。
- metasupport不能为未见组合制造真值，依赖外推；贪心无global-optimum保证。
- Eq6缺经验损失完整写法，不默补为作者使用MSE。
- 真实素材/CTR + 合成组合reward/logger；不是线上ROI。
- 2000 logs/25 seeds/5–9 assets是机制实验，非工业大候选规模实证。

## 交付给主agent

新卡：

- `cards/Tatari_CEM_DML_全文拆解.md`
- `cards/Teads_分层贝叶斯_全文拆解.md`
- `cards/AdPOM_组合素材_全文拆解.md`

建议主agent将原待核实三卡升级到全文阅读目录，同时替换地图/汇总中的旧“PDF无法取得”声明，保留论文证据类型差异。全文与截图可由主agent按用户vault结构复制；本agent未自行改vault。


> 以上为检索时的工作记录，文中临时文件名属于研究工作区留痕。最终交付路径、证据等级与阅读入口以 [第二轮补全文与复核](../08-第二轮补全文与复核.md) 为准。
