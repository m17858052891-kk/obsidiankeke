"""第 02、03、06 篇的构造例子。运行 python3 数值示例.py，在终端查看结果。"""
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


def static_vs_dynamic(lags=(1, 2, 5)):
    """静态 Beta–Bernoulli 与正文平稳 HMM；不条件化于中间观测。"""
    alpha = beta = 89 / 72
    total = alpha + beta
    static_joint = alpha * (alpha + 1) / (total * (total + 1))
    rows = []
    for lag in lags:
        if not isinstance(lag, int) or lag < 1:
            raise ValueError('lag 必须是正整数。')
        # 首次成功后的状态后验；用转移矩阵递推，而非直接套协方差公式。
        high = 0.8
        for _ in range(lag):
            high = high * 0.9 + (1 - high) * 0.1
        hmm_joint = 0.5 * (high * 0.8 + (1 - high) * 0.2)
        rows.append(dict(lag=lag, hmm_joint=hmm_joint,
                         static_joint=static_joint,
                         hmm_covariance=hmm_joint - 0.25,
                         static_covariance=static_joint - 0.25))
    return dict(beta_alpha=alpha, beta_beta=beta, comparisons=rows)


def competing_waiting(cancel_rate=0.1, arrival_rates=(0.2, 0.4)):
    """两个独立、恒定速率的指数时钟；速率单位为每分钟。"""
    return [dict(cancel_rate=cancel_rate, arrival_rate=arrival,
                 mean_observed_wait=1 / (cancel_rate + arrival),
                 cancel_probability=cancel_rate / (cancel_rate + arrival))
            for arrival in arrival_rates]


def posterior_nonlinearity():
    """a=1，个人参数后验在 -2、2 处等权。"""
    def sigmoid(value):
        return 1 / (1 + math.exp(-value))
    return dict(averaged_prediction=(sigmoid(-1) + sigmoid(3)) / 2,
                prediction_at_mean=sigmoid(1))


def repeated_evidence():
    """N(0,1) 先验、方差 1 的 y=2；第二行错误重复使用同一观测。"""
    return [dict(likelihood_copies=copies, posterior_mean=2 * copies / (1 + copies),
                 posterior_variance=1 / (1 + copies)) for copies in (1, 2)]


if __name__ == '__main__':
    examples = dict(shrinkage=normal_shrinkage([1, 9, 81]),
                    beta_binomial=beta_binomial([(0, 0), (5, 3), (100, 60)]),
                    mixture=compare_densities([0, 3]),
                    hmm=two_state_predictions(),
                    static_vs_dynamic=static_vs_dynamic(),
                    competing_waiting=competing_waiting(),
                    posterior_nonlinearity=posterior_nonlinearity(),
                    repeated_evidence=repeated_evidence())
    print(json.dumps(examples, indent=2, ensure_ascii=False))
