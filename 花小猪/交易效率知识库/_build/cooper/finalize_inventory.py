#!/usr/bin/env python3
"""Normalize app routing and classify department metadata without reading bodies."""
import collections,json,pathlib
BASE=pathlib.Path(__file__).resolve().parent
NAMES=['internal','platform','efficiency','planning','proposals','lr26','lr25']
allnodes=[];report=[];department=[]
for name in NAMES:
 p=BASE/(name+'.json')
 if not p.exists():continue
 d=json.loads(p.read_text())
 for n in d['nodes']:
  n['app']='knowledge' if n['kind']=='knowledge' else 'cooper'
  title=n['title'] or ''
  n['relevance']='pending_review'
  n['relevance_reason']='方向父目录内，正文读取后确认主题和可用结论'
  if name in ['proposals','lr26','lr25']:
   if '交易效率' in title:
    n['relevance']='selected';n['relevance_reason']='标题明确归属交易效率方向'
   elif name=='lr25' and any(x.lower() in title.lower() for x in ['PK','连环派','TopSpeed','预分单','升舱','分单召回','商家召回','订单价值','换车','平台规范','平台匹配效率','API多轮举手']):
    n['relevance']='selected';n['relevance_reason']='历史LR标题直接涉及交易效率机制，作为历史证据待正文复核'
   elif name=='proposals' and any(x in title for x in ['PK','换车']):
    n['relevance']='selected';n['relevance_reason']='标题直接涉及PK或换车机制'
   elif any(x in title for x in ['交易生态','乘客与增长','创新策略']):
    n['relevance']='excluded';n['relevance_reason']='标题明确归属其他方向，未发现交易效率直接主题'
   elif any(x in title for x in ['交易市场效率','LTV代理','诱导司机','反作弊','流量分发','流量份额','成交率模型','供需预测']):
    n['relevance']='uncertain';n['relevance_reason']='可能跨方向相关，仅标题不足以确定纳入，需要正文或owner确认'
   else:
    n['relevance']='excluded';n['relevance_reason']='标题未识别交易效率主题，暂不下载正文；保留目录项供复核'
   department.append(n)
  elif any(x in ' / '.join(n['path']) for x in ['节假日休假','人力梳理','D5&D6','新人培养','职场调研']):
   n['relevance']='excluded';n['relevance_reason']='人事/组织材料与交易效率技术Wiki无关，不下载正文'
 allnodes+=d['nodes']
 p.write_text(json.dumps(d,ensure_ascii=False,indent=2))
 report.append({'root':name,'status':d['status'],'queried_directories':d['queried_directories'],'nodes':len(d['nodes']),'max_depth':max([len(n['path']) for n in d['nodes']] or [0]),'errors':d['errors']})
byid=collections.defaultdict(list)
for n in allnodes:byid[(n['app'],n['id'])].append({'root':n['root'],'path':n['path'],'parent_id':n['parent_id']})
dupes=[{'app':app,'id':rid,'occurrences':locs} for (app,rid),locs in byid.items() if len(locs)>1]
for state in ['selected','uncertain','excluded']:
 (BASE/f'department-{state}.json').write_text(json.dumps([n for n in department if n['relevance']==state],ensure_ascii=False,indent=2))
(BASE/'duplicates.json').write_text(json.dumps(dupes,ensure_ascii=False,indent=2))
summary={'roots':report,'total_occurrences':len(allnodes),'unique_app_ids':len(byid),'duplicate_ids':len(dupes),'department_classification':dict(collections.Counter(n['relevance'] for n in department)),'body_downloaded':False,'pagination':'CLI exposes no pagination parameters. All space responses checked totalCount <= returned items; knowledge tree has no total/pagination fields. No evidence of truncation; server-hidden nodes cannot be independently ruled out.','leaf_audit':'12 sampled hasChild=false knowledge pages each returned zero children; all returned nested children arrays checked empty.'}
(BASE/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2))
lines=['# Cooper目录盘点报告','','这是目录元数据盘点，不代表正文已读取或知识已确认。','', '| 入口 | 状态 | 查询目录 | 节点出现数 | 最大相对深度 |','| --- | --- | ---: | ---: | ---: |']
for r in report:lines.append(f"| {r['root']} | {r['status']} | {r['queried_directories']} | {r['nodes']} | {r['max_depth']} |")
lines += ['',f"合计节点出现 {len(allnodes)}，唯一(app, ID) {len(byid)}，重复ID {len(dupes)}。",'', '## 范围与完整性','',summary['pagination'],'',summary['leaf_audit'],'','部门方案/LR已按标题生成selected、uncertain、excluded三份清单，并记录理由。uncertain不自动进入正文下载；excluded仅保存元数据。selected仍需正文复核。','', '## 恢复','', '重新运行 inventory.py 复用 responses/ 下已成功的目录响应，重建每入口清单。每目录响应独立保存；成功结果不需重新拉取。修改输入来源或主动更新应使用新的快照目录，避免覆盖已有来源版本。']
(BASE/'report.md').write_text('\n'.join(lines)+'\n')
print(json.dumps(summary,ensure_ascii=False,indent=2))
