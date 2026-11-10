#!/usr/bin/env python3
"""Read-only Cooper directory inventory. Persist every API response before traversal."""
import concurrent.futures, datetime, json, pathlib, subprocess, threading

BASE = pathlib.Path(__file__).resolve().parent
WRAPPER = '/Users/didi/.SmartWork/skills/smartwork-cli/smartwork-shared/assets/dws-unix.sh'
ROOTS = [
 ('internal','space','2199582756311','2208633130437'),
 ('platform','space','2204461264302','0'),
 ('efficiency','knowledge','2199610335356','2208512037161'),
 ('planning','knowledge','2199610335356','2199613330623'),
 ('proposals','knowledge','2199610335356','2207798311615'),
 ('lr26','knowledge','2199610335356','2206286462215'),
 ('lr25','knowledge','2199610335356','2204239157450'),
]
lock=threading.Lock()

def atomic(path,obj):
 path.parent.mkdir(parents=True,exist_ok=True)
 tmp=path.with_suffix(path.suffix+'.tmp')
 tmp.write_text(json.dumps(obj,ensure_ascii=False,indent=2),encoding='utf8')
 tmp.replace(path)

def traverse(root):
 name,kind,container,parent=root
 queue=[(parent,[],True)];seen=set();nodes=[];errors=[];queries=0
 while queue:
  pid,ancestors,isroot=queue.pop(0)
  if pid in seen:continue
  seen.add(pid)
  path=BASE/'responses'/f'{kind}-{container}-{pid}.json'
  if path.exists():
   payload=json.loads(path.read_text())
  else:
   args=['bash',WRAPPER]
   args += ['knowledge','tree',container,'--parent-id',pid,'--type','1'] if kind=='knowledge' else ['space','list','--space-id',container,'--parent-id',pid]
   args += ['--output','json']
   try:
    proc=subprocess.run(args,capture_output=True,text=True,timeout=90)
    try:payload=json.loads(proc.stdout or proc.stderr)
    except ValueError:payload={'ok':False,'error':{'type':'invalid_json','message':(proc.stdout+proc.stderr)[:1500]}}
   except subprocess.TimeoutExpired:payload={'ok':False,'error':{'type':'timeout','message':'90 second timeout'}}
   atomic(path,payload)
  queries+=1
  if not payload.get('ok') or payload.get('data',{}).get('success') is False:
   errors.append({'parent_id':pid,'error':payload.get('error',payload.get('data'))})
   if isroot:break
   continue
  data=payload['data']['data']
  items=data if kind=='knowledge' else data['items']
  if kind=='space' and data.get('totalCount',len(items))>len(items):
   errors.append({'parent_id':pid,'error':'pagination_unavailable','total':data['totalCount'],'returned':len(items)})
  for item in items:
   rid=str(item['pageId'] if kind=='knowledge' else item['id'])
   title=item.get('pageName') if kind=='knowledge' else item.get('display_name')
   typ=item.get('type') if kind=='knowledge' else item.get('space_resource_type')
   node={'root':name,'kind':kind,'container_id':container,'id':rid,'parent_id':pid,'title':title,'type':typ,'path':ancestors+[title], 'url':f'https://cooper.didichuxing.com/knowledge/{container}/{rid}' if kind=='knowledge' else f'https://cooper.didichuxing.com/team-file/{container}/{rid}'}
   nodes.append(node)
   if (kind=='knowledge' and item.get('hasChild')) or (kind=='space' and typ=='DIR'):
    queue.append((rid,ancestors+[title],False))
  atomic(BASE/f'{name}.json',{'root':root,'queried_directories':queries,'pending_directories':len(queue),'nodes':nodes,'errors':errors,'status':'running' if queue else 'complete' if not errors else 'partial'})
  if queries%10==0:print(f'{name}: directories={queries} nodes={len(nodes)} pending={len(queue)} errors={len(errors)}',flush=True)
 result={'root':root,'queried_directories':queries,'pending_directories':len(queue),'nodes':nodes,'errors':errors,'status':'complete' if not errors else 'partial'}
 atomic(BASE/f'{name}.json',result)
 print(f'{name} finished: directories={queries} nodes={len(nodes)} errors={len(errors)}',flush=True)
 return result

if __name__=='__main__':
 with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:results=list(pool.map(traverse,ROOTS))
 atomic(BASE/'manifest.json',{'created':datetime.datetime.now().astimezone().isoformat(),'roots':[{k:v for k,v in r.items() if k!='nodes'} for r in results], 'total_nodes':sum(len(r['nodes']) for r in results),'note':'Metadata only. Department sources require relevance review before body download.'})
