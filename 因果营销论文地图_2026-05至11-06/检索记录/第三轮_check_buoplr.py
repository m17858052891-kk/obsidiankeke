from fractions import Fraction as F
from itertools import product
import json
from pathlib import Path
d=[F('0.010'),F('0.015'),F('0.009'),F('0.0135')]
c=[F('0.001'),F('0.0015'),F('0.001'),F('0.0015')]
beta=F('0.5')
s=[d[j]-(1-beta)*d[j^1] for j in range(4)]
keep=[max((k,k+2),key=lambda j:s[j]) for k in (0,1)]
rows=[]
for z in product((0,1),repeat=4):
 if any(z[k]+z[k+2]>1 for k in (0,1)) or z[0]+z[1]>1 or z[2]+z[3]>1:continue
 if sum(c[j]*z[j] for j in range(4))>F('.01') or sum(z)>3:continue
 rows.append({'z':z,'value':float(sum(d[j]*z[j] for j in range(4))), 'pruned':all(not z[j] or j in keep for j in range(4))})
orig=max(rows,key=lambda r:r['value']);pruned=max((r for r in rows if r['pruned']),key=lambda r:r['value'])
result={'source':'Eq8-11 and Appendix B, official PDF SHA256 matched 2026-11-07','beta':float(beta),'scores':[float(v) for v in s],'keep':keep,'feasible_enumeration':rows,'original_optimum':orig,'pruned_optimum':pruned,'relative_loss':1-pruned['value']/orig['value'],'slack_budget':.01,'quota':3,'cost_max':max(sum(float(c[j])*r['z'][j] for j in range(4)) for r in rows),'scope':'Formal objective Eq1, K=2; disproves universal vanishing pruning-loss assertion, not empirical gains or restricted K=1 result'}
Path(__file__).with_name('第三轮_buoplr_independent_enumeration.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
