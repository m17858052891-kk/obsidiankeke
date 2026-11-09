"""Recompute the report's constructed examples; no empirical research results."""
import json
import math
from pathlib import Path

def gaussian(x, mean, variance):
    return math.exp(-(x-mean)**2/(2*variance))/math.sqrt(2*math.pi*variance)

shrinkage = []
for n in [1, 9, 81]:
    weight = n/(n+9)
    shrinkage.append(dict(n=n, personal_weight=weight,
                          posterior_mean=4*weight, posterior_variance=9/(n+9)))
mixture = []
for y in [0, 3]:
    mixture.append(dict(y=y,
        mixture_density=.5*gaussian(y,-3,.25)+.5*gaussian(y,3,.25),
        matched_gaussian_density=gaussian(y,0,9.25)))
joint = sum(.5 * (0.9 if a == b else 0.1) * [0.8,0.2][a] * [0.8,0.2][b]
            for a in range(2) for b in range(2))
state_after_y1 = .8
state_next = .9*state_after_y1 + .1*(1-state_after_y1)
prediction_next = .8*state_next + .2*(1-state_next)
# Same prior and observations as the Beta–Binomial table in note 02.
alpha, beta = 2, 18
beta_binomial = []
for n, c in [(0, 0), (5, 3), (100, 60)]:
    post_alpha, post_beta = alpha+c, beta+n-c
    total = post_alpha+post_beta
    beta_binomial.append(dict(prior_alpha=alpha, prior_beta=beta,
        observations=n, successes=c, posterior_alpha=post_alpha,
        posterior_beta=post_beta, posterior_mean=post_alpha/total,
        posterior_variance=post_alpha*post_beta/(total**2*(total+1))))
for record, shapes, mean, variance in zip(beta_binomial,
        [(2,18),(5,20),(62,58)], [.1,.2,62/120],
        [.0042857143,.0061538462,.0020638200]):
    assert (record['posterior_alpha'],record['posterior_beta']) == shapes
    assert math.isclose(record['posterior_mean'],mean)
    assert math.isclose(record['posterior_variance'],variance,abs_tol=5e-11)
out = dict(shrinkage=shrinkage, mixture=mixture,
    hmm=dict(marginal_success=.5, joint_success=joint, iid_joint_success=.25,
             state_high_after_y1=state_after_y1, next_state_high=state_next,
             next_success=prediction_next),
    beta_binomial=beta_binomial)
assert math.isclose(joint, .322)
assert math.isclose(prediction_next, .644)
assert mixture[0]['mixture_density'] < mixture[0]['matched_gaussian_density']/1e6
assert all(shrinkage[i]['posterior_variance'] > shrinkage[i+1]['posterior_variance'] for i in range(2))
Path(__file__).with_name('复算数值.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(out,ensure_ascii=False,indent=2))
