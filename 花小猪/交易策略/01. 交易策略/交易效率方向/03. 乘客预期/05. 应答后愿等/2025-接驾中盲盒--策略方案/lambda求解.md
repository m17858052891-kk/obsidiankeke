---
title: "lambda求解"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2205064117740
---

目标函数：最大化总完单量提升

![](131f19499a834d89-image.png)

约束条件：

![](990f84cdbb267251-image.png)

# 问题抽象

![](2e8ab7cac50b2da5-image.png)

# 求解思路

对于"最大化目标 + 不等式约束"的标准形式，拉格朗日函数为：

![](0def38d9aca5788e-image.png)

对固定的 λ，问题可以逐项分解：

![](df045f1c926a67c4-image.png)

最优解为：

![](2f668a7d87cf260e-image.png)

代入得到**对偶函数**（原问题最优值的上界）：

![](6b07ee7fa552aac5-image.png)

因为v，w和B都是大于0的，所以g(λ) 是 λ的凸函数，所以有最小值，最小值在极值点，一阶梯度为0的点为极值点（最小值点）

1. ![](8a651252a368184d-image.png)

2. ![](ec0d20b43a2ffa80-image.png)

3. ![](7fbba5f831802e7c-image.png)

f(λ) 关于λ是非增的，基于 f(λ) 的单调性，使用二分搜索求解 f(λ∗)=B：

```PlainText
import numpy as np

def find_optimal_lambda(v, w, B, eps=1e-8, max_iter=30):
    """
    二分搜索求解最优拉格朗日乘数
    
    Args:
        v: 价值数组 [N]
        w: 权重数组 [N] 
        B: 预算约束
        eps: 收敛精度
        max_iter: 最大迭代次数
    
    Returns:
        lambda_star: 最优拉格朗日乘数
        selected_mask: 选中订单的布尔掩码
    """
    # 预处理：过滤无效数据
    valid_mask = (w > 0) & (v > 0)
    if not valid_mask.any():
        return 0.0, np.zeros(len(v), dtype=bool)
    
    v_valid, w_valid = v[valid_mask], w[valid_mask]
    
    # 计算效价比上界
    rho_max = float(np.max((v_valid / w_valid).astype(np.float64)))
    
    # 二分搜索边界
    lo, hi = 0.0, rho_max
    
    for iteration in range(max_iter):
        lambda_mid = 0.5 * (lo + hi)
        
        # 计算当前阈值下的总权重 - 关键：O(N)向量化计算
        total_weight = w[v > lambda_mid * w].sum()
        
        # 二分更新
        if total_weight > B:
            lo = lambda_mid  # 超预算，阈值太低
        else:
            hi = lambda_mid  # 欠预算，阈值太高
        
        # 收敛检查
        if hi - lo < eps:
            break
    
    lambda_star = hi
    selected_mask = v > lambda_star * w
    
    return lambda_star, selected_mask
```

why not 三分法

二分法面对的是梯度，三分法面对的是原函数（如果原函数的梯度难以求解，但是知道凹凸性）

# 其他求解方法总结

| 方法 <br> | 适配情况 <br> | 保预算精确性 <br> | 时间复杂度 <br> | 备注 <br> |
| --- | --- | --- | --- | --- |
| **权重二分扫描**（解 f(λ)=B） <br> | **通用情形**：完单才花钱、$$w_i$$不等；日/小时求一次 λ\* <br> | 天然卡住预算 <br> | **O(N)**（约 20–25 轮） <br> | 每轮一次向量化：`mask+sum`；**推荐首选** <br> |
| **ρ 排序 + 前缀和** <br> | 多预算/多人群要**反复查询**阈值；离线批量 <br> | 前缀跨点处做 tie 贴近 B <br> | 预处理 **O(N log⁡N)**；每次查询 **O(log⁡N)** <br> | 一次排序，多次复用阈值/候选集 <br> |
| **Top-B ρ（堆）** <br> | **权重近似相同**（或按张数预算、发了即花钱） <br> | 仅在 $$w_i$$≈ 常数时成立 <br> | 堆：**O(N log⁡B)** <br> | 得到第 B大 ρ 作为阈值；**w_i 差异大时不适用** <br> |
| **三分法**（最大化 g(λ)） <br> | 只知道**凹/单峰**，不便用 f(λ) <br> | 需再校准 <br> | **O(N）**（每轮评估两次） <br> | 等价于最小化 g，但常数更大；不如二分直接且省时 <br> |

# 开发记录

开发思路：在eve平台中，使用python组件直接读取预测离线预测结果计算lambda，同时给出出盲盒的取消率阈值，输出by城市的lambda和by全国的取消率阈值（出盲盒）

1. 数据思路

	1. 前置数据加工

	2. 计算出盲盒的取消率阈值

	3. by城市分组过滤数据

	4. 计算lambda

	5. 输出

2. 当前todo

	1. 城市id未传入（现在python的计算中先随机生成了一列城市ID） 周三修正城市ID传入

	2. 二分法求解思路和代码校对

	3. 调整输出格式

3. 确认点

	1. 出盲盒的取消率阈值 -- 当前和工程沟通的为全国一致（现在实现的也是全国一致）

	2. 预算控制：现在控制的是出盲盒的10% -- 直接计算数量作为B

		1. todo

			1. 补充实际覆盖的数量 -- 这个实际上可以推算

			2. 补充城市ID的同时补充订单画像特征等特征 便于后续分析离线测算时的补贴订单的共性特点

			3. 这里如果需要可以根据预算输入定制 by城市

				1. 上传eve一张表，或者直接写一张hive表在eve读取

		2. 确认点

			1. 预算控制，需要求解出多个预算下面的lambda阈值情况吗

				1. 但是这里和工程沟通的没有说这个，如果只是策略自己看阈值情况的话可以加工一张离线表，包含每个城市-不同的补贴比例（预算）对应的阈值，但是最终给到工程的表一个城市只能有一个lambda

	3. 这里如果需要自动化，需要确认的就是在eve的python组件写到确定表里

	4. todo：透传城市ID和特征

**TODO：需要确认是否限制端内（包括训练和测试数据）包括modeling data的实际情况**
