"""独立核算 Netflix Blending 的公式一致性；不是论文实验复现。

按 arXiv 2606.21745v1 的 (P,Y) 次序。仅使用 numpy 与标准库。
输出 Eq.6、公开代码无门槛惩罚公式、Eq.5 网格最优和 Y=0 条件错误发布率。
"""
import json
import math
from pathlib import Path
import numpy as np

sx = np.array([[1., .08], [.08, .01]])
omega = np.array([[25., 8.], [8., 16.]])
gamma = sx[:, 1]
z = 1.645
grid = np.linspace(0., 1., 100001)
a = np.column_stack([grid, 1-grid])
rows = []
for n in [1000, 5000, 20000]:
    noise = 2*omega/n
    sh = sx + noise
    approx = np.linalg.solve(sx+(1+z*z)*noise, gamma)
    approx /= approx.sum()
    repo = np.linalg.solve(sh, gamma)
    repo /= repo.sum()
    total_var = np.einsum('ij,jk,ik->i', a, sh, a)
    noise_var = np.einsum('ij,jk,ik->i', a, noise, a)
    r = (a @ gamma)/np.sqrt(total_var) * np.exp(-z*z*noise_var/total_var/2)/math.sqrt(2*math.pi)
    k = int(np.argmax(r)); best = a[k]
    conditional_var = total_var[k]-(best@gamma)**2/sx[1,1]
    fpr = .5*math.erfc(z*math.sqrt(noise_var[k]/conditional_var)/math.sqrt(2))
    rows.append(dict(n=n, Eq6_proxy_weight=float(approx[0]),
        repo_proxy_weight=float(repo[0]), Eq5_grid_proxy_weight=float(best[0]),
        Eq10_bound=float((z*z-1)*(2*approx@omega@approx)/(approx@sx@approx)),
        Eq5_expected_return=float(r[k]),
        north_null_false_positive_rate_at_grid_weight=float(fpr)))
Path(__file__).with_suffix('.json').write_text(json.dumps(rows, ensure_ascii=False, indent=2)+'\n')
print(json.dumps(rows, ensure_ascii=False, indent=2))
