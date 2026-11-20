"""Reproduce finite mathematical examples. Standard library only; no model training."""
from itertools import combinations, product
from math import log2, isclose, prod
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
x_second_moment = F(sum(x1**2 for x1, _, _ in rows), len(rows))
ridge_penalty = F(1)
a_single = x_second_moment / (x_second_moment + ridge_penalty)
a_duplicate = x_second_moment / (x_second_moment + ridge_penalty / 2)
assert (a_single, a_duplicate) == (F(1, 2), F(2, 3))
assert (a_duplicate/2)**2*2==a_duplicate*a_duplicate/2
# A single DCNv2 layer with W12=1, b1=-1 gives x1' = x1*x2.
for x1,x2 in product([-3,-.5,0,2],repeat=2):
    assert isclose(x1*(x2-1)+x1,x1*x2,abs_tol=1e-12)


def inner(left, right):
    """Exact expectation of a product under the uniform distribution on the rows."""
    return F(sum(a * b for a, b in zip(left, right)), len(left))


def residual(values, basis):
    """Remove the projection on a given orthonormal basis."""
    assert all(inner(col, col) == 1 for col in basis)
    assert all(inner(a, b) == 0 for a, b in combinations(basis, 2))
    coefficients = [inner(values, col) for col in basis]
    return [
        value - sum(weight * col[i] for weight, col in zip(coefficients, basis))
        for i, value in enumerate(values)
    ]


# A column's marginal R² and its contribution after the baseline can disagree.
four_point_basis = list(zip(*design))
main_plus_cross = [3 * x1 + cross for x1, _, cross in rows]
target_residual = residual(main_plus_cross, four_point_basis)
baseline_mse = inner(target_residual, target_residual)
assert baseline_mse == 1
centered_target = residual(main_plus_cross, [four_point_basis[0]])
candidates = {"2*x1": [2 * x1 for x1, _, _ in rows], "x1*x2": labels}
candidate_report = {}
for name, z in candidates.items():
    centered_z = residual(z, [four_point_basis[0]])
    marginal_r2 = inner(centered_target, centered_z) ** 2 / (
        inner(centered_target, centered_target) * inner(centered_z, centered_z)
    )
    u = residual(z, four_point_basis)
    u_variance = inner(u, u)
    beta = inner(target_residual, u) / u_variance if u_variance else F(0)
    errors = [r - beta * ui for r, ui in zip(target_residual, u)]
    augmented_mse = inner(errors, errors)
    gain = baseline_mse - augmented_mse
    assert gain == (inner(target_residual, u) ** 2 / u_variance if u_variance else 0)
    candidate_report[name] = [marginal_r2, augmented_mse, gain]
assert candidate_report == {"2*x1": [F(9, 10), 1, 0], "x1*x2": [F(1, 10), 0, 1]}


def polynomial_mse(inputs, targets, degree):
    # Every input is a sign, so x² = 1. Deduplicate identical product columns.
    basis = set()
    for size in range(degree + 1):
        for indices in combinations(range(len(inputs[0])), size):
            column = tuple(prod(row[i] for i in indices) for row in inputs)
            basis.add(column)
    errors = residual(targets, sorted(basis))
    return inner(errors, errors)


# The stronger model can use the engineered column in a further interaction.
cube = list(product([-1, 1], repeat=3))
augmented_cube = [(a, b, c, a * b) for a, b, c in cube]
cube_targets = [a * c + a * b * c for a, b, c in cube]
upgrade_report = {}
for degree in (1, 2):
    raw_mse = polynomial_mse(cube, cube_targets, degree)
    augmented_mse = polynomial_mse(augmented_cube, cube_targets, degree)
    upgrade_report[degree] = [raw_mse, augmented_mse, raw_mse - augmented_mse]
assert upgrade_report == {1: [2, 2, 0], 2: [1, 0, 1]}

# Both input levels occur in training. Only their joint activation is absent.
seen = [(0, 0), (0, 1), (1, 0)]
assert all({row[j] for row in seen} == {0, 1} for j in (0, 1))
assert all(a * b == 0 for a, b in seen)


def interaction_rule(a, b, weight):
    return a + b + weight * a * b


observed_responses = [a + b for a, b in seen]
for weight in (0, 3):
    assert [interaction_rule(a, b, weight) for a, b in seen] == observed_responses
unseen_predictions = [interaction_rule(1, 1, weight) for weight in (0, 3)]
assert unseen_predictions == [2, 5]

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
    "conditional_feature_gain": {
        "baseline_mse": float(baseline_mse),
        "by_candidate": {
            name: {"marginal_r2": float(r2), "augmented_mse": float(mse), "mse_gain": float(gain)}
            for name, (r2, mse, gain) in candidate_report.items()
        }
    },
    "model_upgrade": {
        f"degree_{d}": {"raw_mse": float(raw), "augmented_mse": float(aug), "mse_gain": float(gain)}
        for d, (raw, aug, gain) in upgrade_report.items()
    },
    "unseen_combination": {
        "training_inputs": seen,
        "observed_responses_for_both_rules": observed_responses,
        "interaction_weights": [0, 3],
        "predictions_at_1_1": unseen_predictions
    },
    "status":"all assertions passed"
}
print(json.dumps(report,ensure_ascii=False,indent=2))
