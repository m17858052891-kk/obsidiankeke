from pathlib import Path
import json,re,os
R=Path(__file__).resolve().parents[1]
records=json.loads((R/'_build/downloads.json').read_text())['records']
ids=['2205745382077','2206086951587','2207196657296','2208937143735','2210017050557','2209585649315','2207479815678','2209768345955']
items={
'2205745382077':('技术建设2026','2026 技术建设规划；未提供作者复核/更新日期','通过模型、算法与机制研究解决交易难点，以落地新一代交易系统为导向。','覆盖履约多任务建模（特征交叉、行为序列、专家结构）、embedding、样本删失、样本不均衡/过滤导致的曝光偏差、匹配算法与特征挖掘。M3—M8 表为规划排期。','来源表格记录 SENet epoch2 的 OD/O/D AUC 为 0.7995/0.7912/0.8670；行为序列表记录 PEPNet+序列实验2 为 0.8017/0.7679/0.8915。不同表格基线与条件不同，只作为文档内实验记录，不跨表排名。','规划与阶段性离线记录；未提供完整上线/业务增量证据。','文中的“当前进展”仅代表原文记录时点，时点未明确。M3/M4 上线安排不证明已上线。样本、验证流程和其他原文冲突应继续核验。','〇、目标；一、topic；二、机制；三、timeline',['../模型/DO价值模型.md','../26年项目/DO价值建模.md']),
'2206086951587':('序列建模-司乘履约模型','实验样本包含 2025-06 和 2025-12；文档确切更新日未给出','履约多目标预测中，评估历史订单序列及 PLE/PEPNet 对不同任务的影响。','来源定义 OD=司乘履约、O=司机履约、D=乘客履约。343维输入分143维数值和200维司乘序列；司乘各10单×10特征。PEPNet 先由连环派信号进入 EPNet，再由类别 embedding 驱动三个 PPNet，六塔按连环派/非连环派选择三任务输出。','明确样本：2025-12-01～19训练、12-20～24验证；epoch1 的 PLE base 为 0.7735/0.7696/0.8430，PEPNet+序列实验2为 0.8017/0.7679/0.8915。该条件下 OD 与 D 提升，O 低于 PLE base。六月样本和20单扩展另有表，不能与十二月混比。','原文明示当前 PEPNet 实验仅离线，缺乏线上 A/B 和长周期漂移测试；落地场景为候选。','原文“总结”中的平均+9.6pp、消融平均变化等与所列细表不能直接对应，且统计量消融表为空。只引用带样本日期与基线的具体表，不能采纳笼统收益。特征序列截止时点仍需订单级泄露检查。','一、背景；二、特征处理；三、线上base模型抽取+序列改造；四、PEPnet；五、实验结果；六、消融实验；七、总结；八、落地场景；九、网约车序列建模情况',['../模型/CAA履约率模型.md','../模型/DO价值模型.md','../模型/PEPNet与序列履约模型.md']),
'2207196657296':('召回过滤模型序列化落地','正文无明确实验日期或复核日期','为召回过滤使用的司机/乘客取消 XGB 模型补充司乘历史序列。','对照 XGB 与 XGB+司乘序列；特征重要性中涉及司机序列乘客取消、接驾时长与连环派。','司机取消 AUC 0.7822→0.8560，绝对增加7.38pp；乘客取消 0.7044→0.7370，绝对增加3.26pp。TOP50中分别有21与11个序列特征（文中统计）。','只取得离线 AUC 和重要性记录；标题含“落地”不等于已确认上线。','样本日期、样本规模、标签、切分、置信区间、线上策略阈值和业务效果缺失。图片未解析，不能据图补充结论。','召回过滤模型序列化落地；模型版本/AUC/模型可视化表',['../26年项目/分单召回优化.md']),
'2208937143735':('DO价值-序列建模','正文无版本日期；仅记录v0','记录 DO 价值 v0 引入序列特征的探索入口。','正文仅给出v0序列特征说明、Eve实验入口和外置流程图。','存在实验入口 labs/new/15621；无可读实验指标或文字机制细节。','证据线索页，不能据此认定成功上线。','外置 diagraming 未解析，缺少标签、样本、结构、实验与部署状态。不能从图链接猜测模型。','DO价值-序列建模；v0版本引入序列特征',['../模型/DO价值模型.md','../26年项目/DO价值建模.md']),
'2210017050557':('[BRD]DO价值建模离线探索','目录祖先含“多任务模型-2026-08-27”；该日期不是本页更新/生效日','所属【26常规项目】交易系统架构升级，针对司乘多任务履约模型继续离线探索；业务/策略 owner 为李昊远，原文不申请P0。','联合预测司机履约、乘客履约、订单完单。三条路线：LLM辅助AutoFE并做质量/模型筛选；OneTrans/HyFormer序列建模；优化门控与专家使用，探索PEPNet的EPNet场景个性化、PPNet用户个性化，配合消融验证。','目标是相对线上模型三任务平均 AUC +3.5pp；这是目标，原文未报告已达成。工程要求为离线实验、暂不需要工程介入。','离线探索需求，不是上线方案或已实现收益。','原文对“当前线上模型”的描述限记录时点，模型版本未给出；完整标签、训练验证日期、均值口径、上线决策缺失。DO业务价值与三任务代理目标之间关系仍需确认。','项目/内容表；一、需求简述；二、目标与收益；三、需求内容；四、工程要求；五、实验方案',['../26年项目/DO价值建模.md','../模型/DO价值模型.md','../模型/PEPNet与序列履约模型.md']),
'2209585649315':('模型（差体验与乘客流失因果建模）','正文无明确实验日期或复核日期','预测差体验与流失关系，并估计某差体验下降1pp时对流失的反事实影响，希望表达置信程度。','用差体验比例映射到[0,1]作为连续Treatment；讨论反事实支持不足、协变量淹没Treatment、多Treatment相关、DR纠偏、前期差体验对活跃窗口影响。比较VCNet、多维连续DML、DRCFR。','区分需要真实个体效应的PEHE/ATE/ATT/MISE/ADRF AMSE/Policy Regret，与无个体真值时的Qini/AUUC、DR、RATE/AUTOC等；提出用真实W构造T/Y的合成数据方向。','选型与评价框架草稿，无已选定生产模型、估计结果或业务增量。','公式在图片中未解析；多Treatment相关原文标暂不考虑。缺失识别假设、混杂变量、重叠性检验、窗口定义与可验证反事实效果，不能把相关性当因果。','要解决问题；难点；模型选型；指标；备注',['../26年项目/体验留存归因.md']),
'2207479815678':('onetrans实验结果','正文未给实验日期；含验证bug修复前后两组结果','比较 PLE、PEPNet 与 OneTrans/序列融合，并记录只验证一个batch的bug修复。','探索序列分支、8层tower、warmup、司机/乘客单侧序列及OneTrans。必须区分修复前记录与“修改只验证一个batch的bug”之后的完整验证表。','修复后epoch9：PLE-no-seq 0.7150/0.7259/0.7500，PLE-OneTrans 0.7350/0.7258/0.7972；OD绝对+2.00pp、D+4.72pp，O约持平。PEP-seq为0.7421/0.7339/0.8036，PEP-seq-OneTrans为0.7503/0.7613/0.8697。仅文档内同表比较。','离线实验记录，存在评估实现修复，无线上AB或部署确认。','原文将0.715→0.735写为+2.8pp，将0.7500→0.7972写为+6.3pp，混淆相对百分比与AUC绝对百分点；摘要按表值重算并说明。修复前AUC不可与修复后直接比较，数据集与随机种子仍缺失。','PepNet结果；PLENet；修改只验证一个batch的bug：ple/pep',['../模型/PEPNet与序列履约模型.md','../26年项目/DO价值建模.md']),
'2209768345955':('多模型实验','目录祖先含“多任务模型-2026-08-27”；本页实验日期未明确','在OD/O/D三任务下寻找兼顾离线AUC和连环派/非连环派显式domain约束的骨架。','比较STAR、DTN、HyFormer、AutoMTL。HyFormerDomain将binary从普通静态token拆出，独立domain embedding条件化司乘query，共享主干后使用分任务分域adapter/head并硬路由。','HyFormer均值AUC 0.7760；HyFormerDomain为0.7582/0.7560/0.8330、均值0.7824，相对普通HyFormer均值+0.64pp。STAR改动仅小幅变化；DTN相对同期PEP01均值-1.11pp。','本文阶段性离线结果；建议同训练预算复验，不等于已替换生产模型。','STAR缺严格单变量基线。不同路线用不同对照，不能将所有差值相加。训练验证时间、样本规模、随机重复与在线影响未给出；图片结构未解析，仅使用文字描述。','1、本阶段结论；2、模型结构；3.1 STAR；3.2 DTN/HyFormer/AutoMTL；3.3 HyFormer显式Domain改造',['../模型/PEPNet与序列履约模型.md','../模型/DO价值模型.md','../26年项目/DO价值建模.md'])}
def write_source(id):
 x=records['knowledge:'+id]; title,period,problem,mechanism,evidence,state,limit,sections,related=items[id]
 p=R/'wiki/来源'/('cooper-knowledge-'+id+'.md')
 fm={'title':title+'｜Cooper来源摘要','type':'source','owner':'@tommywujian','freshness':'watch','status':'proposed','last_reviewed':None,'permission_scope':'team','source_ids':['knowledge:'+id],'related':related,'source_period':period,'source_date':None,'processed_at':'2026-11-04'}
 head='---\n'+''.join(k+': '+json.dumps(v,ensure_ascii=False)+'\n' for k,v in fm.items())+'---\n\n'
 path=' / '.join(x['occurrences'][0]['path']);url=x['occurrences'][0]['url']
 body=f'# {title}｜来源摘要\n\n> 来源更新/生效日未明确；下载日期不作为内容复核日期。此页为待复核提炼。\n\n## 来源身份与时间\n\n- ID：`knowledge:{id}`\n- 原始目录：{path}\n- [Cooper原文]({url})\n- [不可变本地快照]({os.path.relpath(R/x["file"],p.parent)})\n- SHA-256：`{x["sha256"]}`\n- 时间范围：{period}\n\n## 问题\n\n{problem}\n\n## 机制\n\n{mechanism}\n\n## 证据\n\n{evidence}\n\n## 状态\n\n{state}\n\n## 限制与待确认\n\n{limit}\n\n## 重要章节\n\n{sections}\n\n## 关联页面\n\n'+''.join(f'- [{Path(t).stem}]({t})\n' for t in related)
 p.write_text(head+body)
for id in ids:write_source(id)
# Update specific existing cards with new, traceable evidence. Existing planning sections remain explicitly historical.
def update(rel,chosen,body):
 p=R/'wiki'/rel;t=p.read_text();fm,content=t.split('---',2)[1:]
 for id in chosen:
  if 'knowledge:'+id not in fm:fm=fm.replace('source_ids:\n','source_ids:\n  - "knowledge:'+id+'"\n')
 if '\n## Cooper首批证据补充\n' in content:content=content.split('\n## Cooper首批证据补充\n')[0]
 body+='\n\n### 本批来源\n\n'+''.join(f'- [{items[id][0]}](../来源/cooper-knowledge-{id}.md)\n' for id in chosen)
 t='---'+fm+'---'+content+'\n## Cooper首批证据补充\n\n> 来源时间分别记录在来源摘要中；仅新增证据，不将下载日视为复核日。\n\n'+body+'\n'
 t=t.replace('关联实验/LR、效果量及不确定性：尚未取得。','关联实验/LR、效果量及不确定性：首批新增离线证据见下文，正式LR与线上证据仍待补齐。')
 p.write_text(t)
update('模型/DO价值模型.md',['2210017050557','2208937143735','2206086951587','2209768345955'],'BRD 将本轮明确为【26常规项目】交易系统架构升级下的离线探索，三任务为司机履约、乘客履约、订单完单；平均 AUC +3.5pp 是目标，不是已实现收益。AutoFE、OneTrans/HyFormer及门控专家/PEPNet为三条探索路线。\n\nv0序列页只给实验入口和外置图，无法补齐实际结构。另一份序列实验提供2025年6月/12月时间切分和PEPNet结果；多模型实验提供HyFormerDomain阶段结果。它们属于不同实验条件，不能直接排序为统一版本演进或宣称当前最优线上模型。DO业务价值与三任务代理预测目标之间的正式映射仍待确认。')
update('模型/CAA履约率模型.md',['2206086951587','2210017050557'],'已取得一份多目标序列履约实验：143维数值+200维司乘序列，PEPNet以EPNet场景门控、三路PPNet和双域六塔建模。原文限定为离线实验。\n\n命名存在必须确认的差异：该文把caa称为“应答后取消率”，方向介绍用CAA指履约率模型。取消概率与履约概率的标签方向不能直接等同；O/D任务字母映射应随每个实验原文保留，不能跨文档推断。三任务与当前PK服务模型的注册/部署对应关系仍未知。')
update('26年项目/DO价值建模.md',['2210017050557','2205745382077','2209768345955','2207479815678'],'新增原始BRD：需求owner李昊远、不申请P0、离线实验暂不需要工程介入；三任务平均AUC+3.5pp为目标。方向规划P0与此具体需求“不申请P0”保留为不同层级描述，不能直接覆盖。\n\n离线证据含技术建设规划、序列建模与多模型探索；OneTrans记录出现验证仅一个batch的bug，必须用修复后表。HyFormerDomain文档内均值AUC0.7824，比普通HyFormer+0.64pp；缺线上业务效果和当前生产部署证据。')
update('26年项目/PK优化.md',['2206086951587','2210017050557'],'原始序列履约实验把分单DO匹配、连环派、远接驾换车列为候选落地场景；BRD关联预测能力建设。它们补充了PK价值建模的技术线索，但没有提供当前PK排序公式、距离置换参数、窗口策略或线上实验结果，因此原有PK里程碑仍是计划。')
update('26年项目/分单召回优化.md',['2207196657296'],'取得召回取消XGB+司乘序列的离线对比：司机取消AUC0.7822→0.8560；乘客取消0.7044→0.7370。只报告同文档内的离线预测收益；不能推出应答率、CR或完单增长。样本日期、过滤阈值、线上版本和挤占风险待补。')
update('26年项目/体验留存归因.md',['2209585649315'],'新增选型草稿把差体验比例作为连续Treatment，目标包含“差体验下降1pp对流失”的反事实影响与置信程度。讨论VCNet、多维连续DML、DRCFR及合成评价。它是方法选型，尚未形成可核验因果结论；多Treatment相关暂不考虑，识别假设、混杂控制和重叠性检验仍需补齐。')
# A useful model-family card is justified by real architecture and experiment evidence.
p=R/'wiki/模型/PEPNet与序列履约模型.md'
p.write_text('''---
title: "PEPNet与序列履约模型"
type: model-card
owner: "@tommywujian"
freshness: watch
status: proposed
last_reviewed: null
permission_scope: team
source_ids: ["knowledge:2206086951587", "knowledge:2207479815678", "knowledge:2209768345955", "knowledge:2210017050557"]
related: ["DO价值模型.md", "CAA履约率模型.md", "../26年项目/DO价值建模.md"]
source_date: null
processed_at: "2026-11-04"
---

# PEPNet与序列履约模型

> 模型家族与离线实验知识卡，不代表当前生产模型。来源更新日期未知；样本期与文档层级线索分别记录。

## 任务与数据契约

BRD联合预测司机履约、乘客履约、订单完单。序列实验文内定义OD=司乘履约、O=司机履约、D=乘客履约；其他材料的字母命名需单独核对。训练标签SQL、删失、负样本和服务映射待补。

序列实验输入343维：143数值、200序列；乘客与司机各10单×10特征，包含金额、取消、到达/接驾和连环派等历史信息。不能仅凭“订单dt前”认定无未来泄露，需检查事件级可用时间。

## 结构

- 数值归一化后Scalar2Vec；司乘序列reshape为10×10，位置Self-Attention编码。
- 连环派binary驱动EPNet，对连续/序列表征做逐维调权。
- 类别embedding驱动OD/O/D三路PPNet，每层个性化门控。
- 每任务双域输出头，总六塔，按binary取连环派或非连环派输出。
- 此结构来自具体序列文档，不将其等同于全部PEPNet实现或当前线上服务。

## 带范围的实验记录

| 来源与条件 | 对照 | 实验 | 解释边界 |
| --- | --- | --- | --- |
| 2025-12-01～19训练、12-20～24验证，epoch1 | PLE base：0.7735/0.7696/0.8430 | PEPNet+序列实验2：0.8017/0.7679/0.8915 | OD/D提高，O低于此base；不能称三任务全面提高 |
| OneTrans文档修复只验证一个batch后，epoch9 | PEP-seq：0.7421/0.7339/0.8036 | PEP-seq-OneTrans：0.7503/0.7613/0.8697 | 同表离线比较；与修复前记录不可直接比较 |
| 多模型实验文档内 | HyFormer Mean AUC 0.7760 | HyFormerDomain Mean AUC 0.7824 | +0.64pp，显式domain embedding、adapter/head与硬路由；非PEP同架构消融 |

AUC列按各文档OD/O/D顺序记录，不跨样本、版本、验证流程直接排名。均无线上业务增量和当前上线确认。

## 证据质量限制

- 序列文档“总结”中的平均+9.6pp等数值无法直接从所列细表复核，统计量消融表有空白，不能采用笼统结论。
- OneTrans文档的部分“pp”叙述混淆绝对百分点与相对百分比，应由原表重算。
- 当前缺少随机重复、置信区间、训练预算、样本规模、推理延迟、校准与线上AB证据。
- 图片与外置图未解析，不从图链接补造结构。

## 来源与关联页面

- [序列建模原始摘要](../来源/cooper-knowledge-2206086951587.md)
- [OneTrans验证修复记录](../来源/cooper-knowledge-2207479815678.md)
- [多模型实验](../来源/cooper-knowledge-2209768345955.md)
- [离线探索BRD](../来源/cooper-knowledge-2210017050557.md)
- [DO价值模型](DO价值模型.md)
- [CAA履约率模型](CAA履约率模型.md)
- [DO价值建模项目](../26年项目/DO价值建模.md)
''')
# Append indexed references without discarding existing baseline navigation.
for rel,entries in [('来源/index.md',[(items[id][0],'cooper-knowledge-'+id+'.md') for id in ids]),('模型/index.md',[('PEPNet与序列履约模型','PEPNet与序列履约模型.md')])]:
 p=R/'wiki'/rel;t=p.read_text();marker='\n## Cooper首批原始资料\n'
 if marker in t:t=t.split(marker)[0]
 t+=marker+'\n'+''.join(f'- [{title}]({target})\n' for title,target in entries)
 p.write_text(t)
success=[k for k,x in records.items() if x['status']=='success']
report='# Cooper首批小批次提炼\n\n已通读并提炼8篇原始正文；不是所有已下载来源的完成声明。\n\n'+''.join(f'- `knowledge:{id}`：{items[id][0]}。\n' for id in ids)+f'\n本报告截点成功下载正文{len(success)}篇，本批阅读8篇，剩余{len(success)-8}篇未由本批通读提炼；下载仍可能继续增长。\n\n新增8篇来源摘要和1篇PEPNet模型家族页；补充2个模型页、4个项目页与2个目录索引。正文source_date和last_reviewed未知时使用null，processed_at仅是处理日期。既有部门快照复核日期保留，不伪造新来源复核。\n\n## 重要发现\n\n- OneTrans文档有仅验证一个batch的bug修复，修复前结果不可用作修复后基线；部分pp说明需按表重算。\n- 序列模型总结中的+9.6pp与具体表不能对应，消融表有空白；知识页保留具体实验条件与待复核标记。\n- caa取消率/CAA履约率、O/D任务字母映射存在上下文差异，不能直接统一标签。\n- BRD +3.5pp是目标，离线且不需工程介入；HyFormerDomain为离线阶段结果。\n- 来源图表未解析，未据链接补造图内内容。\n'
(R/'_build/cooper-first-synthesis.md').write_text(report)
(R/'_build/cooper-first-read-ids.json').write_text(json.dumps({'read_ids':['knowledge:'+id for id in ids],'successful_at_report':len(success),'not_read_by_this_batch':len(success)-8},ensure_ascii=False,indent=2)+'\n')
# Local links in touched pages.
checks=[]
paths=[R/'wiki/来源'/('cooper-knowledge-'+id+'.md') for id in ids]+[p]
for f in (R/'wiki').rglob('*.md'):
 for target in re.findall(r'\]\(([^)]+)\)',f.read_text()):
  if '://' not in target and target and not (f.parent/target.split('#')[0]).exists():checks.append(str(f.relative_to(R))+': '+target)
print(json.dumps({'read':8,'successful_at_report':len(success),'not_read_by_this_batch':len(success)-8,'broken_links':checks},ensure_ascii=False))
