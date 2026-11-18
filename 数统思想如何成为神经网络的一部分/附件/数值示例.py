"""第 02、06 篇的构造例子。运行 python3 数值示例.py，在终端查看结果。"""
import json
import math


def normal_shrinkage(counts, observed_mean=4, prior_variance=1, noise_variance=9):
    """群体先验均值为 0，观测独立且方差已知。"""
    rows = []
    for n in counts:
        denominator = n * prior_variance + noise_variance
        personal_weight = n * prior_variance / denominator
        rows.append(dict(n=n, personal_weight=personal_weight,
                         posterior_mean=personal_weight * observed_mean,
                         posterior_variance=prior_variance * noise_variance / denominator))
    return rows


def beta_binomial(observations, prior_alpha=2, prior_beta=18):
    rows = []
    for n, successes in observations:
        alpha = prior_alpha + successes
        beta = prior_beta + n - successes
        total = alpha + beta
        rows.append(dict(prior_alpha=prior_alpha, prior_beta=prior_beta,
                         observations=n, successes=successes, posterior_alpha=alpha,
                         posterior_beta=beta, posterior_mean=alpha / total,
                         posterior_variance=alpha * beta / (total ** 2 * (total + 1))))
    return rows


def normal_density(y, mean, variance):
    return math.exp(-(y - mean) ** 2 / (2 * variance)) / math.sqrt(2 * math.pi * variance)


def compare_densities(positions, center=3, within_variance=0.25):
    """两个等权成分的均值为 ±center，整体均值为 0。"""
    total_variance = within_variance + center ** 2
    rows = []
    for y in positions:
        density = (normal_density(y, -center, within_variance)
                   + normal_density(y, center, within_variance)) / 2
        rows.append(dict(y=y, mixture_density=density,
                         matched_gaussian_density=normal_density(y, 0, total_variance)))
    return rows


def two_state_predictions(stay=0.9, success_high=0.8, success_low=0.2):
    """两种状态初始各半，切换概率对称，两步示例以首次成功为条件。"""
    marginal = (success_high + success_low) / 2
    if marginal == 0:
        raise ValueError('首次成功概率为零，无法对该事件求条件概率。')
    posterior_high = 0.5 * success_high / marginal
    next_high = posterior_high * stay + (1 - posterior_high) * (1 - stay)
    next_success = next_high * success_high + (1 - next_high) * success_low
    return dict(marginal_success=marginal, joint_success=marginal * next_success,
                iid_joint_success=marginal ** 2, state_high_after_y1=posterior_high,
                next_state_high=next_high, next_success=next_success)


if __name__ == '__main__':
    examples = dict(shrinkage=normal_shrinkage([1, 9, 81]),
                    beta_binomial=beta_binomial([(0, 0), (5, 3), (100, 60)]),
                    mixture=compare_densities([0, 3]),
                    hmm=two_state_predictions())
    print(json.dumps(examples, indent=2, ensure_ascii=False))
