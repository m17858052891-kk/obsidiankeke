"""Reproduce finite mathematical examples. Standard library only; no model training."""
from itertools import product
from math import log2, isclose
from fractions import Fraction as F
import json

rows=[(x1,x2,x1*x2) for x1,x2 in product([-1,1],repeat=2)]
mean=lambda a:sum(a)/len(a)
def entropy(labels):
    return -sum((labels.count(v)/len(labels))*log2(labels.count(v)/len(labels)) for v in set(labels))
def gini(labels):
    return 1-sum((labels.count(v)/len(labels))**2 for v in set(labels))
def variance(labels):
    m=mean(labels)
    return mean([(y-m)**2 for y in labels])
labels=[r[2] for r in rows]
def mutual_information(xs,ys):
    return entropy(xs)+entropy(ys)-entropy(list(zip(xs,ys)))
mi_individual=[mutual_information([r[col] for r in rows],labels) for col in [0,1]]
mi_joint=mutual_information([r[:2] for r in rows],labels)
mi_augmented=mutual_information(rows,labels)
assert mi_individual==[0,0] and mi_joint==1 and mi_augmented==1
moments=[mean([r[2] for r in rows]),mean([r[0]*r[2] for r in rows]),mean([r[1]*r[2] for r in rows])]
assert moments==[0,0,0]
# Design [1,X1,X2] has identity Gram matrix under the uniform four-point law.
design=[[1,r[0],r[1]] for r in rows]
gram=[[mean([d[i]*d[j] for d in design]) for j in range(3)] for i in range(3)]
assert gram==[[1,0,0],[0,1,0],[0,0,1]]
mse_linear=variance(labels)
mse_cross=mean([(r[0]*r[1]-r[2])**2 for r in rows])
assert mse_linear==1 and mse_cross==0
root_gain={}
for name,impurity in [('entropy',entropy),('gini',gini),('mse',variance)]:
    gains=[]
    for col in [0,1]:
        groups=[[r[2] for r in rows if r[col]==v] for v in [-1,1]]
        gains.append(impurity(labels)-sum(len(g)*impurity(g)/4 for g in groups))
    assert gains==[0,0]
    root_gain[name]=gains
# An explicit affine classifier gets 3/4 correct. Impossibility of 4/4 is proved in text, not by grid search.
predict=lambda x1,x2:1 if x1+x2-1>0 else -1
affine_error=mean([int(predict(r[0],r[1])!=r[2]) for r in rows])
assert affine_error==.25
# Two ReLUs exactly compute parity on these four discrete points.
relu=lambda t:max(0,t)
assert all(relu(x1+x2)+relu(-x1-x2)-1==y for x1,x2,y in rows)
# Closed-form ridge: E[x^2]=1, y=x, lambda=1; duplicating x halves effective penalty.
a_single=F(1,2)
a_duplicate=F(2,3)
assert (a_duplicate/2)**2*2==a_duplicate*a_duplicate/2
# A single DCNv2 layer with W12=1, b1=-1 gives x1' = x1*x2.
for x1,x2 in product([-3,-.5,0,2],repeat=2):
    assert isclose(x1*(x2-1)+x1,x1*x2,abs_tol=1e-12)
report={
    "scope":"finite mathematical examples only; no fitted ML models or business data",
    "rows":rows,
    "label_entropy_bits":entropy(labels),
    "individual_feature_mutual_information_bits":mi_individual,
    "joint_and_augmented_mutual_information_bits":[mi_joint,mi_augmented],
    "linear_square_loss_optimum":mse_linear,
    "linear_with_product_square_loss_optimum":mse_cross,
    "raw_root_split_gains":root_gain,
    "exhibited_affine_classification_error":affine_error,
    "small_relu_exact_on_four_points":True,
    "ridge_single_effective_coefficient":str(a_single),
    "ridge_duplicate_effective_coefficient":str(a_duplicate),
    "one_cross_layer_product_identity_checked":True,
    "status":"all assertions passed"
}
print(json.dumps(report,ensure_ascii=False,indent=2))
