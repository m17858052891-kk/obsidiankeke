from pathlib import Path
import json, hashlib, shutil
root=Path(__file__).resolve().parents[1]
repo=root.parent/'strategy-dept-knowledge'
files=[repo/'common/trading-strategy-introduction.md',repo/'directions/trading-efficiency/index.md',*sorted((repo/'directions/trading-efficiency/metric').glob('*.md'))]
items=[]
for src in files:
 rel=src.relative_to(repo)
 dest=root/'raw/department-baseline'/rel
 dest.parent.mkdir(parents=True,exist_ok=True)
 if dest.exists() and dest.read_bytes()!=src.read_bytes():
  raise RuntimeError('Snapshot already exists with different content: '+str(dest))
 if not dest.exists(): shutil.copyfile(src,dest)
 items.append({'id':'repo:strategy-dept-knowledge:'+str(rel),'path':str(dest.relative_to(root)),'original_path':str(rel),'commit':'a27b537bdef2b8f1cd7e3c503602dad9fde164c3','sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'status':'downloaded','review':'watch'})
(root/'_build/baseline-manifest.json').write_text(json.dumps(items,ensure_ascii=False,indent=2)+'\n')
tasks=[{'id':f'T{i}','status':'completed' if i==0 else 'pending','title':t} for i,t in enumerate(['本地骨架与断点','Git盘点','Cooper递归盘点','正文分批获取','主题提炼','合并导航','校验交付'])]
ledger=root/'_build/tasks.json'
if not ledger.exists(): ledger.write_text(json.dumps(tasks,ensure_ascii=False,indent=2)+'\n')
print('Baseline snapshot files:',len(items))
