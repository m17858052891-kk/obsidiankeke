from pathlib import Path
import json,re,os
R=Path(__file__).resolve().parents[1]
M=json.loads((R/'_build/baseline-manifest.json').read_text())
D='repo:strategy-dept-knowledge:directions/trading-efficiency/index.md'
I='repo:strategy-dept-knowledge:common/trading-strategy-introduction.md'
meta={x['id']:x for x in M}
made=[]
def doc(rel,title,typ,body,ids,related=()):
 p=R/'wiki'/rel;p.parent.mkdir(parents=True,exist_ok=True)
 fm='---\n'+f'title: {json.dumps(title,ensure_ascii=False)}\ntype: {typ}\nowner: "@tommywujian"\nfreshness: watch\nstatus: proposed\nlast_reviewed: 2026-07-12\npermission_scope: department\nsource_ids:\n'+''.join('  - '+json.dumps(i,ensure_ascii=False)+'\n' for i in ids)+'related:\n'+(''.join('  - '+json.dumps(i,ensure_ascii=False)+'\n' for i in related) or '  []\n')+'---\n\n'
 notice='> 基于 2026-07-12 复核的部门资料提炼，当前有效性待 owner 复核；不代表已核实的线上状态。\n\n'
 sources='\n\n## 来源\n\n'+''.join(f'- [{Path(meta[i]["original_path"]).name}]({os.path.relpath(R/meta[i]["path"],p.parent)})（快照 commit `a27b537`）\n' for i in ids)
 links='\n## 关联页面\n\n'+(''.join(f'- [{Path(t).stem}]({t})\n' for t in related) or '- 暂无独立关联页。\n')
 p.write_text(fm+'# '+title+'\n\n'+notice+body.strip()+sources+links)
 made.append(p)
def title_body(path):
 text=path.read_text();body=text.split('---',2)[2].strip();title=re.search(r'^title: (.*)$',text,re.M)[1]
 return title,body
def sections(body):
 out={}
 for x in re.split(r'^## ',body,flags=re.M)[1:]:
  key,_,v=x.partition('\n');out[key]=v.strip()
 return out
# Metric cards preserve formulas, event rules and correction logic, but expose a common data-contract section.
metrics=[]
for item in M:
 src=Path(item['original_path'])
 if src.parent.name!='metric' or src.name=='index.md':continue
 title,body=title_body(R/item['path']);s=sections(body)
 rel='指标/'+src.name;metrics.append((src.name,title))
 parts=['## 指标含义\n\n'+s.get('定义',''), '## 计算契约（来源口径，待复核）\n\n'+s.get('公式','')]
 for key in ['口径逻辑','修正逻辑','接驾时间修正']:
  if key in s: parts.append('## '+key+'\n\n'+s[key])
 parts.append('## 诊断用途\n\n'+s.get('使用场景',''))
 caut=s.get('注意事项','')+'\n- SQL、看板字段、过滤条件、统计时间窗及异常值处理尚未获得可核验来源，待补充。'
 if src.stem in ['both-hand-raise-rate','only-hand-raise-rate','hand-raise-rate']:
  caut+='\n- 来源把 only/both 举手率称作整体举手率拆分，但两者分母为参与 PK 数，整体举手率分母为播单数。此处按 PK 竞争结构理解；不能直接相加还原整体举手率，需 owner 确认统计集合与去重粒度。'
 if src.stem in ['avg-etp','avg-pickup-duration','avg-call-to-charge-duration','avg-answer-duration']:
  caut+='\n- 不同时间指标的样本、分母和端点不同，未经同样本对齐，不能直接用指标均值相加减还原链路。'
 parts.append('## 使用限制与待确认\n\n'+caut)
 refs=['index.md']
 # All direct metric relationships from original metadata are valid in this directory.
 fm=(R/item['path']).read_text().split('---',2)[1]
 for x in re.findall(r'^  - \./([^\n]+\.md)$',fm,re.M):
  if x!='index.md' and (R/'raw/department-baseline/directions/trading-efficiency/metric'/x).exists():refs.append(x)
 doc(rel,title,'metric','\n\n'.join(parts),[item['id']],refs)
idxid='repo:strategy-dept-knowledge:directions/trading-efficiency/metric/index.md'
doc('指标/index.md','指标目录与口径边界','link-index','\n'.join(f'- [{t}]({f})' for f,t in metrics)+'\n\n## 跨指标约束\n\n- 改派版本、统计对象、时间窗与去重粒度必须随指标一起引用。\n- only/both 举手率用于 PK 竞争结构；与举手率不同分母。\n- 乘客取消率来源为分子不含改派、分母含改派，保留混合口径待确认。\n- ETP 到到达事件；呼叫-计费到计费事件；司机接驾时长采用分场景修正。\n- 年度目标不是当前线上表现。',[idxid],[f for f,t in metrics])
# Domain concepts.
concepts={
'交易链路':('小猪端的撮合链路为：呼叫 → 商家召回 → 商家内部匹配 → 举手 → 平台 PK → 播单/应答 → 接驾 → 开始计费 → 完单。\n\n商家决定在自身运力池中提交哪个司机，平台在跨商家候选中选择最终胜者。应答后取消可能进入改派、换车等回流链路。\n\n外部平台/DD 入口的最终 PK 权可能属于外部平台，相同“举手”不保证有相同司机感知与归因。',[I],['召回与匹配.md','平台PK.md','特殊交易场景.md']),
'召回与匹配':('召回先基于在线/可听单状态、距离时间、城市品类、范围开关、特殊场景能力、历史行为等约束形成候选集合。过窄可能减少举手机会，过宽可能增加远接驾和取消。\n\n| 匹配方法 | 核心选择 | 权衡 |\n| --- | --- | --- |\n| topspeed/就近贪心 | 单次优先最近司机 | 响应快，但多单多司机下可能非全局最优 |\n| KM/轮次分单 | 收集批量订单司机，二分图整体匹配 | 接驾成本与等待窗口权衡 |\n| GS/稳定匹配 | 考虑双边偏好 | 稳定性与接驾效率权衡 |\n| MDP/动态价值 | 当前收益与未来时空价值 | 依赖时空模型与评估 |\n\n上述为来源中的方法介绍，不代表当前线上均已采用。评估需共同看 ETP、司机接驾时长、取消、CR、GMV。',[I],['交易链路.md','../26年项目/分单召回优化.md','../26年项目/匹配联合决策.md']),
'平台PK':('平台 PK 在举手候选间选择胜者，兼顾履约、接驾成本和业务约束。来源描述的窗口机制是首个举手进入窗口，持续比较候选，窗口结束输出胜者；only 场景通常直接胜出。\n\nPK 分可由预估司乘履约概率结合业务倾斜/管控组成，具体公式、参数、阈值和当前服务版本待补。动态窗口通过增加候选的收益与应答前等待成本进行权衡。\n\n取消改善不等于 PK 胜率立刻提高：还受竞争者变化、距离、密度、参与数量等相对竞争因素影响。应区分 only/both 结构与 both 中绝对胜出率。',[I,D],['../模型/CAA履约率模型.md','../指标/pk-win-rate.md','../指标/absolute-pk-win-rate.md','../26年项目/PK优化.md']),
'派单模式':('全指派由系统派给司机默认接单；半指派给司机决策时间；抢单由多个被播司机主动抢；选单由司机在大厅选择。具体默认行为与时间窗以线上规则复核。\n\n半指派可在司机决策中提前举手：拒单且 PK 成功则重新下一轮；拒单且 PK 失败则拒单成功；接单/无操作且 PK 成功则应答；接单/无操作且 PK 失败则接单失败。需串联司机决策与 PK 结果解释数据。\n\n来源也介绍司机调度，但调度在具体匹配之前改善空间供需，不能混作分单；本 Wiki 仅保留边界引用。',[I],['交易链路.md','../26年项目/匹配联合决策.md']),
'特殊交易场景':('## 连环派\n\n新单播给正在送驾的司机。应同时考虑当前位置到上一单终点再到新起点的全路径与上一终点到新起点的接驾路径。乘客等待可能变长，司机时间指标需扣除上一单送驾占用，具体四类修正见指标页。\n\n## 扩播\n\n扩大召回半径增加应答机会，同时可能增加距离、等待、取消及补偿成本。需记录触发条件、补偿与取消归因。\n\n## 预分单与升舱\n\n预分单为未勾选品类增加水下呼叫，找到运力后由乘客确认；升舱可通过补差价提供更高等级运力。水下呼叫可能未计入普通呼叫数，因此应答数大于呼叫数未必是计算错误。\n\n## 换车与改派\n\n换车是在应答后远接驾、长等待等情况下重新寻找司机；改派是司机取消后再次寻找司机。评估需按原始发单连接前后链路，避免重复计数。权益、补贴和当前规则均待原始方案验证。',[I],['../指标/avg-pickup-duration.md','../指标/response-rate.md','../26年项目/乘客交易.md']),
'指标事件与样本':('乘客视角从首次呼叫开始：单均应答时长到首次应答；ETP 到司机点击到达；呼叫-计费时长到首次开始计费。司机接驾时长从司机时间占用视角计算，按可控运力与连环派拆分修正。\n\n这些指标并非同一批样本：应答时长来源分母是不含改派应答量，ETP 是到达样本，呼叫-计费是完单量，司机接驾量是否含改派待确认。因此不能用整体均值相加减替代事件级计算。\n\n漏斗可用于依次排查流量、召回、PK、应答和履约；只有样本集合、条件概率及统计粒度一致时，漏斗乘法才是恒等式。',[I,idxid],['../指标/avg-answer-duration.md','../指标/avg-etp.md','../指标/avg-call-to-charge-duration.md','../指标/avg-pickup-duration.md'])}
for name,(body,ids,rels) in concepts.items():doc('概念与机制/'+name+'.md',name,'concept',body,ids,rels)
doc('概念与机制/index.md','概念与机制目录','link-index','\n'.join(f'- [{n}]({n}.md)' for n in concepts),[I,D],[n+'.md' for n in concepts])
# Candidate model cards: no invented labels or serving status.
models={
'CAA履约率模型':('预测司乘履约质量，作为平台 PK 的价值依据。','方向规划提到 CAA 迭代考虑乘客已等时长、被取消次数。介绍列出司机/乘客历史取消行为、预计接驾距离时长与特殊场景等候选特征；实际训练特征未核验。','来源在 PK 技术栈中列 LR、Wide&Deep、XGBoost、DQN、PLE，但未逐一映射当前 CAA 版本，不能据此确定线上架构。',['../26年项目/PK优化.md','../指标/fulfillment-rate.md','../概念与机制/平台PK.md']),
'cba应答前取消模型':('建模应答前取消风险，规划用于交易价值统一。','方向页技术栈列出应答前取消生存分析，以及 Cox、Breslow/Nelson-Aalen 基线、PCHIP 样条。观测起点、删失处理和标签窗口尚未提供。','Q2 落地为历史规划；模型注册名、服务部署和当前版本未核验。',['../26年项目/交易价值统一.md','../概念与机制/交易链路.md']),
'DO价值模型':('支撑乘客个性化 PK 和 D 选 O 的匹配价值，规划突破 LR 并保留可解释性。','方向页提出特征交叉、序列建模、id embedding；这些是规划/技术方向，不等于已完成训练配置。','Q1 调研、Q2 离线收益、Q3 落地均为历史计划。目标函数、标签、收益证据和当前模型版本待补。',['../26年项目/DO价值建模.md','../26年项目/PK优化.md','../26年项目/匹配联合决策.md'])}
for name,(target,features,version,rels) in models.items():
 body=f'## 预测目标与使用位置\n\n{target}\n\n## 来源提供的技术线索\n\n{features}\n\n## 版本与上线状态\n\n{version}\n\n## 待补充的模型契约\n\n- 标签定义、正负样本、采样与时间窗：待补充。\n- 训练数据集、特征明细、数据泄露检查：待补充。\n- 训练任务、参数、校准、离线评价：待补充。\n- 推理服务、调用位置、延迟与降级：待补充。\n- 版本变更、线上实验、LR 结论与适用范围：待补充。\n\n本页是来源支持的候选模型卡，不能据此声称模型已上线或有确定收益。'
 doc('模型/'+name+'.md',name,'model-card',body,[D,I],rels)
doc('模型/index.md','模型目录','link-index','\n'.join(f'- [{n}]({n}.md)：候选模型卡，线上版本待确认。' for n in models)+'\n\n召回 PPNet、订单流失率、CR、体验留存 MTA/LTV 等在方向规划中出现，但缺少模型粒度资料，暂不生成独立正式模型卡。',[D],[n+'.md' for n in models])
projects=[
('交易价值统一','交易配置和解法收敛至平台侧，串联分发指导、分单遵循、PK 执行、乘客透传；司机价值准入 F_j vs F_∅。','Q1：平台规范与价值统一 V1.0；Q2：cba 模型；Q3：召回与 PK 联动复盘。',['../模型/cba应答前取消模型.md','../概念与机制/平台PK.md']),
('PK优化','约束履约率下最小化接驾距离；规划 v1.1、CAA 加入已等时长/被取消次数，以及乘客个性化 PK。','Q1：v1.1 Wide&Deep 全量；Q2：履约率/CAA 模型迭代；Q3：个性化 PK 上线复盘。',['../模型/CAA履约率模型.md','../模型/DO价值模型.md','../指标/absolute-pk-win-rate.md']),
('DO价值建模','突破 LR 并保留解释性，支持乘客个性化 PK 与 D 选 O；研究特征交叉、序列建模。','Q1：难度调研；Q2：离线收益；Q3：落地。',['../模型/DO价值模型.md','PK优化.md']),
('分单召回优化','维护优化商家召回主流程；漏斗考虑订单流失；品类透出向乘客价值导向调整。','Q1：摸清主流程更新频率与维护状态；Q2：优化方案；Q3：实验复盘。',['../概念与机制/召回与匹配.md','../指标/response-rate.md']),
('匹配联合决策','联合派单模式、匹配和一播多优化；tp/GS 考虑竞争胜率，D 选 O 前置验证。','Q1：目标和约束；Q2：联合方案；Q3：风险红线。',['../概念与机制/召回与匹配.md','../概念与机制/派单模式.md','../模型/DO价值模型.md']),
('体验留存归因','量化应答时长、接驾距离等差体验及极端值对乘客留存的影响。','Q1：MTA/LTV 选型；Q2：差体验到留存影响量化；Q3：沉淀体验价值口径。',['../指标/avg-etp.md','../指标/average-pickup-distance.md','../概念与机制/指标事件与样本.md']),
('乘客交易','梳理换车、升舱透传；换车希望降低接驾距离，并探索商家出钱升舱换车。','年度完成梳理；未提供可核验实际里程碑。',['../概念与机制/特殊交易场景.md','../指标/passenger-cancel-after-answer-rate.md']),
('交易策略解法统一','盘点并收敛交易阈值解法，规划由多个收敛至 2 个。','Q1：端分发、召回、派单模式、topspeed、换车、PK 窗口阈值盘点；Q2：统一方案；Q3：逐步替换。',['交易价值统一.md','../概念与机制/派单模式.md'])]
for name,target,plan,rels in projects:
 body=f'## 问题与规划目标\n\n{target}\n\n## 2026 历史计划\n\n{plan}\n\n以上来自方向规划，不是实际完成记录。\n\n## 评估约束\n\n方向规划优先考虑乘客 ETP 与司机接驾时长，关注乘客取消、接驾距离；双边效率目标列 CR 不负。具体项目的主指标、护栏、样本范围和成本约束需由项目方案确认。\n\n## 方案演进与当前状态\n\n- 已有证据：方向规划摘要。\n- 详细方案、版本替代关系、实际里程碑：待接入原始文档。\n- 是否上线、覆盖城市/运力、线上配置与负责人分工：待确认。\n- 关联实验/LR、效果量及不确定性：尚未取得。\n\n## 下一批来源应补齐\n\n原始方案 → 模型/策略版本 → 离线和线上实验 → LR 决策 → 当前部署证据；历史计划不自动晋升为当前结论。'
 doc('26年项目/'+name+'.md',name,'technical-design',body,[D],rels)
doc('26年项目/index.md','26年项目目录','link-index','\n'.join(f'- [{n}]({n}.md)' for n,*_ in projects)+'\n\n本目录按方向页的八个项目建立候选卡片。计划优先级存在上下文差异：DO 在目标表为技术 P1、项目表为 P0；保留待 owner 确认，不自行合并。',[D],[n+'.md' for n,*_ in projects])
# One structured source summary per snapshot.
for item in M:
 src=Path(item['original_path']);title,body=title_body(R/item['path']);sec=sections(body)
 if src.parent.name=='metric' and src.name!='index.md':
  summ=sec.get('定义','')+'\n\n### 核心计算\n\n'+sec.get('公式','')
  if src.stem=='avg-pickup-duration':summ+='\n\n### 重要限制\n\n修正逻辑区分可控/非可控运力和连环派/非连环派，详见指标卡与原文表格。'
  targets=['../指标/'+src.name]
 elif src.name=='index.md' and src.parent.name=='metric':
  summ='汇总 15 个指标及双边效率、乘客体验、司机效率、PK 质量目标；列日期、城市、工作日、运力/连环派、改派版本等必拆维度。年度目标与指标口径均待复核。';targets=['../指标/index.md']
 elif src.parent.name=='common':
  summ='介绍聚合交易链路、商家分单与平台 PK 边界、派单模式和连环派/扩播/预分单/升舱/换车场景；提供漏斗排查顺序。概念解释较宽泛，正式指标公式应转到具体指标卡并核对样本。';targets=['../概念与机制/index.md']
 else:
  summ='记录交易效率职责、2026 年目标、八个重点项目和技术栈线索。属于规划摘要，可作为项目和模型线索，不能证明模型已上线或里程碑已完成。';targets=['../26年项目/index.md','../模型/index.md']
 slug=('common-' if src.parent.name=='common' else 'direction-' if src.parent.name=='trading-efficiency' else 'metric-')+src.stem
 text=f'## 来源身份\n\n- 稳定 ID：`{item["id"]}`\n- 仓库相对路径：`{src}`\n- 快照 commit：`{item["commit"]}`\n- SHA-256：`{item["sha256"]}`\n- 层级：部门库二次整理材料；原始 Cooper 来源未在本批逐一复核。\n\n## 结构化摘要\n\n{summ}\n\n## 使用边界\n\n原材料 freshness 为 watch，最近内容复核日期为 2026-07-12。可用于定义候选知识与追溯，不据此宣布当前线上事实。'
 doc('来源/'+slug+'.md',title+'｜来源摘要','source',text,[item['id']],targets)
sourcefiles=sorted((R/'wiki/来源').glob('*.md'))
doc('来源/index.md','来源目录','link-index','本批为 18 份部门库材料快照；不代表用户提供的全部 Git/Cooper 来源已获取。\n\n'+'\n'.join(f'- [{p.stem}]({p.name})' for p in sourcefiles),list(meta),[p.name for p in sourcefiles])
# Verify local Markdown links and required frontmatter.
issues=[]
for p in made:
 text=p.read_text()
 for key in ['title','type','owner','freshness','status','last_reviewed','permission_scope','source_ids','related']:
  if not re.search('^'+key+':',text,re.M):issues.append(str(p)+':missing '+key)
 for target in re.findall(r'\]\(([^)]+)\)',text):
  if '://' not in target and not (p.parent/target.split('#')[0]).exists():issues.append(str(p)+':broken '+target)
counts={d:len(list((R/'wiki'/d).glob('*.md'))) for d in ['指标','概念与机制','模型','26年项目','来源']}
report='# 首批部门资料提炼报告\n\n- 来源：18 份不可变快照，commit `a27b537`。\n- 知识页：'+str(sum(counts.values()))+'。\n'+''.join(f'- {k}：{v} 页（含索引）。\n' for k,v in counts.items())+'\n## 验证\n\n- 必填 frontmatter 检查及本批相对 Markdown 链接检查：'+('通过。' if not issues else '\n'.join(issues))+'\n\n## 待确认\n\n- 指标 SQL、看板与统计窗、过滤/去重细节未取得。\n- only/both 与举手率分母不同，不能视作可加拆分。\n- 乘客取消率混合改派口径保留待确认。\n- 时长指标端点、样本与分母不同，不能直接均值相减。\n- CAA/cba/DO 标签、样本、训练推理、版本、上线和实验均未完整取得。\n- 八项目均为历史规划卡，实际进度、LR/效果待接入。\n- DO 项目 P0 与目标表技术 P1 的上下文差异待 owner 确认。\n'
(R/'_build/baseline-report.md').write_text(report)
(R/'_build/baseline-pages.json').write_text(json.dumps({'counts':counts,'pages':[str(p.relative_to(R)) for p in made],'checks':issues},ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'counts':counts,'pages':len(made),'issues':issues},ensure_ascii=False))
