"""Validate local Wiki pages and immutable source checksums. No network access."""
from pathlib import Path
import json, re, hashlib
root=Path(__file__).resolve().parents[1]
required=['title','type','owner','freshness','status','last_reviewed','permission_scope','source_ids','related']
errors=[];warnings=[];pages=list((root/'wiki').rglob('*.md'))
for p in pages:
 text=p.read_text()
 m=re.match(r'^---\n(.*?)\n---\n',text,re.S)
 if not m:
  errors.append(str(p.relative_to(root))+': missing frontmatter');continue
 for key in required:
  if not re.search(r'^'+re.escape(key)+r':',m[1],re.M):errors.append(str(p.relative_to(root))+': missing '+key)
 for target in re.findall(r'\]\(([^)]+)\)',text):
  target=target.strip().removeprefix('<').removesuffix('>')
  if re.match(r'^[a-zA-Z][a-zA-Z0-9+.-]*:',target) or target.startswith('#'):continue
  target=target.split('#')[0].replace('%20',' ')
  if target and not (p.parent/target).exists():errors.append(str(p.relative_to(root))+': broken link '+target)
for manifest in ['baseline-manifest.json','downloads.json','git-additional-manifest.json']:
 p=root/'_build'/manifest
 if not p.exists():warnings.append('Not available: '+manifest);continue
 data=json.loads(p.read_text())
 if isinstance(data,dict):
  if 'additional_sources' in data: data=[item for source in data['additional_sources'] for item in source['files']]
  else: data=list(data['records'].values()) if 'records' in data else (data['items'] if 'items' in data else list(data.values()))
 if not isinstance(data,list): warnings.append('Unknown manifest format: '+manifest);continue
 for item in data:
  if not isinstance(item,dict):continue
  path=item.get('path') or item.get('local_path') or item.get('file');checksum=item.get('sha256')
  if not path or not checksum:continue
  source=root/path
  if not source.is_file(): errors.append('missing source '+path)
  elif hashlib.sha256(source.read_bytes()).hexdigest()!=checksum:errors.append('checksum mismatch '+path)
result={'pages_checked':len(pages),'errors':errors,'warnings':warnings}
(root/'_build/lint-report.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(result,ensure_ascii=False,indent=2))
raise SystemExit(bool(errors))
