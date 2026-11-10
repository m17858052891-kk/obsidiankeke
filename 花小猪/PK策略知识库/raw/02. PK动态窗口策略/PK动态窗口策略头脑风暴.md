# 一、最优时停问题

stochastic process领域

经典问题**秘书问题（The Secretary Problem）**：也称为停留问题。你要从一群候选人中选择一位秘书，候选人按顺序出场且一旦拒绝就无法回头。目标是在观察了一定数量的候选人后，决定何时停止以选择最优的秘书。这个问题的最优策略是先观察前 n/e 个候选人而不做选择，然后在此之后选择第一个比所有之前见过的候选人都更优秀的人。

![](https://s3-ep-inter.didistatic.com/didoc-upload-image-prod/1726717816909a58f7d87b0d70f14e5e8239d3fa651db/%25E6%2588%25AA%25E5%25B1%258F2024-09-19%25E4%25B8%258A%25E5%258D%258811.50.13.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKDD00000000000EBLCTZNRBJHX6ZS%2F20260526%2Fgzep%2Fs3%2Faws4_request&X-Amz-Date=20260526T075923Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=e4eb806fdbac2e1029916962c7d038a0ceffb6c9d6f11a68b5b9e8d7523bed0b)

更进一步，如果提前不知道有几个候选人，则乘上随时间递增的选择概率。最终选到最优候选人的概率为0.3675，（可以再算一下期望的结束时间2/e）

**代码模拟**：

模拟1

假设每一轮PK随机有1-10个司机，到达时间随机，PK时长8s，当PK得分>0.9时立即获胜；模拟10000次

平均结束时长6.03s，94.11%的情况下找到本轮8s内的最优司机

模拟2

在模拟1的基础上，加上如果在only举手时有80%的把握判断only举手，则立即结束；并且在both举手情况下也有20%几率误判，并提前结束；模拟10000次

平均结束时长4.19s，87.59%的情况下找到本轮8s内的最优司机

模拟3

在模拟2中，将总窗口改为4s，司机数1-5

平均结束时长2.10s，87.9%的情况下找到本轮8s内的最优司机

# 二、贝尔曼方程

PK动态时间是一个典型的状态转移问题，在该场景中，时间可以视作状态（或者每个司机进入PK环节视作状态）。不同的状态下可采取的action有两个，该司机获胜并提前结束忙或者继续PK环节。

![](https://s3-ep-inter.didistatic.com/didoc-upload-image-prod/172672689109599d915acde8cb4b56b2e84b5828af9dc/%25E6%2588%25AA%25E5%25B1%258F2024-09-19%25E4%25B8%258B%25E5%258D%25882.21.27.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKDD00000000000EBLCTZNRBJHX6ZS%2F20260526%2Fgzep%2Fs3%2Faws4_request&X-Amz-Date=20260526T075923Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=6beaa2dcaf3cbe56724e96e89b27d25180544fa6801e57b6ccdbd5f0d6614e4f)

![](https://s3-ep-inter.didistatic.com/didoc-upload-image-prod/1726726945915814d65ac6a67056dd087c9eb40045401/%25E6%2588%25AA%25E5%25B1%258F2024-09-19%25E4%25B8%258B%25E5%258D%25882.22.23.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKDD00000000000EBLCTZNRBJHX6ZS%2F20260526%2Fgzep%2Fs3%2Faws4_request&X-Amz-Date=20260526T075923Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=1d1fa7e4807fd9dbfbe19e5583e7729779c00f863f7dfd8783d44dbc1422aca1)

# 三、VAE、bayes等？

# 四、启发式策略

乘客体验视角进行司机过滤，对乘客取消进行过滤。
