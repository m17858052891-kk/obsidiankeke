# 离线链路优化问题

## 1 优化目标与约束

- 优化目标：
  - 主要：完单
  - 次要：
    - 一口价完单份额 = 幸运盒子完单份额 + 特价盒子完单份额
    - 可控运力司机单均收入，忽略可控运力，简化为单均 ASP * (1 - TR)
    - 单均呼叫-计费时长，难以预测
    - ECR
    - CR
    - DSAR(默勾接受度)
- 评估口径：
  - $长期完单=人均完单+a_0 \cdot 一口价完单份额+ a_1 \cdot 单均收入+  a_2 \cdot ECR + a_3 \cdot CR + a_4 \cdot DSAR +$
    - 人均完单=完单数/冒泡人数
    - 一口价完单份额=(幸运盒子完单数+特价盒子完单数)/完单数
    - 单均收入=GMV/完单数
    - DSAR=以默勾的呼叫数/呼叫数
    - ECR=呼叫数/冒泡数
    - CR=呼叫数/完单数
- 约束：
  - 补贴率约束
  - 幸运盒子水位约束

## 2 离线决策

### 2.1 决策空间

- 决策维度：冒泡维度决策
- 决策空间：
  - 默勾：同价车型合并后的车型数
  - 折扣：幸运盒子定价、特价盒子折扣，需注意幸运盒子定价=100折意味着幸运盒子不展现
- 剪枝
  - 首先根据规则对全决策空间进行剪枝，剪枝后，如果存在幸运盒子非100折的决策空间，则剪枝掉幸运盒子100折的决策空间

折扣决策空间为：

| 幸运盒子↓ / 特价盒子→ | 100 | 97 | 94 | 91 | 88 | 85 | 82 |
|---|---|---|---|---|---|---|---|
| 幸运盒子不展现 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 97 | ✅ |  |  |  |  |  |  |
| 94 | ✅ | ✅ |  |  |  |  |  |
| 91 | ✅ | ✅ | ✅ |  |  |  |  |
| 88 | ✅ | ✅ | ✅ | ✅ |  |  |  |
| 85 | ✅ | ✅ | ✅ | ✅ | ✅ |  |  |
| 82 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |  |
| 79 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 76 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 73 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

### 2.2 业务背景
- 价格计算
  - B vs C
    - 用B代表司机，C代表乘客
  - 应付价格 vs 实付价格
    - 应付价格是乘客实际应付价格，计算GMV时使用应付价格
    - 实付价格是乘客实际支付的价格，实付价格=应付价格-C补金额
  - B侧应收价格 vs C侧应付价格
    - 定义：B侧应收价格指的是司机侧应该的收入，C侧应付价格指的是乘客侧应付价格，TR指的是平台的taking rate
    - 计算公式：
      - $B侧应收价格 = C侧应付价格 \cdot (1-TR)$
      - $B侧实收价格 = B侧应收价格 + B补$
      - $C侧实付价格 = C侧应付价格 - C补$
- 表单业务背景
  - 品类、商家、车型是什么概念？
    - 品类：为了满足不同的司乘需求，小猪存在多个品类，如低价对应幸运盒子、特价盒子、超值达，确定性对应特快盒子、小猪特快，大盘需求对应盒子外（普通品类）
    - 商家：一个商家可以有多个品类，品类间有发单优先级；例如一个商家同时发单特价盒子、盒子外、特快盒子时，由于优先级为特快盒子 > 盒子外 > 特价盒子，最终会以特快盒子发单
    - 车型：一个车型对应唯一的商家 X 品类组合，在冒泡表中有唯一的estimate_id
  - 价格取整：
    - 收益链路：价格取整通过减小展示价格方差，提升乘客对更高价格的接受度，增加用户呼叫车型数，从而提升CR。
    - 策略：对一口价品类向上取整到角，对实时计价品类向下取整到元。举例如下：
      - 一口价品类「特价盒子」价格为10.73，取整之后的展示价格为10.8元；
      - 实时计价品类「小猪打车」的价格为10.73，取整之后的展示价格为10元；
  - 同价车型合并
    - 对展示价格一致的车型进行合并，但有两例特殊情况：
      - 盒子不与其它车型进行合并；
      - 展示价格一致但计价方式不同（一个为实时计价另外一个为一口价）不进行合并
- 联合决策业务背景
  - 特价盒子折扣
    - 特价盒子折扣以C补形式下发，即只改变C侧价格，不改变B侧价格；且与前置折扣券之间的关系是折上折逻辑
    - 例如特价盒子应付价格=100，前置券=90折，则特价盒子前置券后价格=$100\cdot 0.9=90元$，特价盒子折扣=80折，则特价盒子实付=$90\cdot 0.8=72元$，$C补=100-72=28元$
  - 幸运盒子定价
    - 幸运盒子定价是0C补形式，会同时改变B、C侧的价格
    - 幸运盒子定价会基于特价前置券后价格进行定价，例如幸运盒子折扣=80折，特价盒子前置券后价格=90元，此时幸运盒子实付=幸运盒子应付=$90\cdot 0.8=72元$
    - 幸运盒子在表单不一定会展现
      - 会导致幸运盒子不展现的策略包含：命中围栏、命中动调、展现时段、滴滴快车不存在、盒子/超值达不存在、幸运盒子未预估、风控
      - 会导致幸运盒子定价决策空间被剪枝的策略包含：价格约束剪枝
    - 幸运盒子展现时，幸运盒子实付一定低于特价盒子实付，即幸运盒子定价折扣 < 特价盒子折扣
    - 幸运盒子真 vs 假GMV：
      - 真GMV = 幸运盒子定价
      - 假GMV：基于规则逻辑计算的GMV，不随幸运盒子定价折扣而发生改变，通常高于真GMV，用于规划求解 & 落表
  - 默勾决策空间
    - 在价格取整、同价车型合并后的表单上，决策默勾数，即默勾数=k时，勾选上前k行
    - 备注：表单的一行可能对应多个商家
- 决策空间
  - 剪枝逻辑
    - 幸运盒子价格约束：决策对应的幸运盒子实付<价格阈值时，该折扣被剪枝
    - 幸运盒子不展现约束：若命中围栏、命中动调、展现时段、滴滴快车不存在、盒子/超值达不存在、幸运盒子未预估、风控，则剪枝掉所有幸运盒子非100折的决策空间
  - 优先在幸运盒子非100折，找最优决策，如果幸运盒子非100折都被剪枝了，那么在幸运盒子100折中寻找最优决策

### 2.3 符号定义

| 符号 | 含义 | 模型输出 |
|---|---|---|
| $B$ | 总冒泡数 |  |
| $N$ | 总冒泡用户数 |  |
| $C$ | 总呼叫数 |  |
| $F$ | 总完单数 |  |
| $i$ | 第 $i$ 个冒泡，共 $B$ 个 |  |
| $\mathcal{J}_i$ | 冒泡 $i$ 的可行决策集，离线预计算后固定不变；由剪枝逻辑保证：$I_i=0$ 时 $\mathcal{J}_i$ 中所有决策满足 $d^l_j=1$，$I_i=1$ 时 $\mathcal{J}_i$ 中所有决策满足 $d^l_j<1$ |  |
| $j$ | 第 $j$ 种决策，$j \in \mathcal{J}_i$，决策空间为【幸运盒子定价、特价盒子折扣、默勾】 |  |
| $z_{ij}$ | 决策变量，第 $i$ 个冒泡是否采用第 $j$ 个决策，$j \in \mathcal{J}_i$ |  |
| $I_i$ | 0-1 指示变量，代表冒泡 $i$ 的可行决策集是否含有幸运盒子展现的决策（$d^l_j < 1$）；$I_i$ 是 $\mathcal{J}_i$ 结构的等价标量摘要：$I_i=1 \Leftrightarrow \forall j\in\mathcal{J}_i,\ d^l_j<1$；$I_i=0 \Leftrightarrow \forall j\in\mathcal{J}_i,\ d^l_j=1$ |  |
| $d^u_j$ | 第 $j$ 个决策中特价盒子折扣，97 折对应 0.97 |  |
| $d^l_j$ | 第 $j$ 个决策中幸运盒子定价折扣，97 折对应 0.97；$d^l_j=1$ 代表幸运盒子不展现，此时模型预测幸运盒子完单概率 = 0 |  |
| $f^*_{ij}$ | 第 $i$ 个冒泡第 $j$ 种决策下，P(品类完单\|完单)，$l$ 代表幸运盒子，$u$ 代表特价盒子，$o$ 代表其他；满足 $f^l_{ij}+f^u_{ij}+f^o_{ij}=1$ | ✅ |
| $p^{u'}_i$ | 第 $i$ 个冒泡特价盒子前置优惠后价格 |  |
| $p^u_i$ | 第 $i$ 个冒泡特价盒子应付价格 |  |
| $p^e_{i}$ | 第 $i$ 个冒泡，除幸运盒子、特价盒子外的平均应付 ASP<br><br>风险：假设除最低价以外价差不大 |  |
| $\hat{p}^l_i$ | 第 $i$ 个冒泡幸运盒子假GMV，基于规则逻辑计算，不随幸运盒子定价折扣 $d^l_j$ 变化，通常高于真GMV（$p^{u'}_i \cdot d^l_j$）；用于规划求解 & 落表 |  |
| $\beta$ | 补贴率约束阈值 |  |
| $\alpha$ | 幸运盒子水位约束阈值，控制 $\frac{\sum \text{幸运盒子实付}}{\sum \text{特价盒子实付}} \ge \alpha$ |  |

### 2.4 优化问题

- 中间计算过程
  - 冒泡完单率
    - $bcr_{ij} = \phi(x_i, ecr_{ij}, dsar_{ij})$
  - 呼叫完单率
    - $cr_{ij}=\dfrac{bcr_{ij}}{ecr_{ij}}$
  - $cost_{ij} = f^u_{ij} \cdot p^{u'}_i \cdot (1 - d^u_j)$
  - $gmv_{ij} = f^l_{ij} \cdot \hat{p}^l_i + f^u_{ij} \cdot p^u_i + f^o_{ij} \cdot p^e_i$
  - 一口价完单数 $fix_{ij} = bcr_{ij} \cdot (f^l_{ij} + f^u_{ij})$

- 最大化目标

    $$
    \max \frac{\sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot bcr_{ij}}{N}
    + a_0 \frac{\sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot bcr_{ij} \cdot (f^l_{ij} + f^u_{ij})}{\sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot bcr_{ij}}
    + a_1 \frac{\sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot bcr_{ij} \cdot gmv_{ij}}{\sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot bcr_{ij}}
    + a_2 \frac{\sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot ecr_{ij}}{B}
    + a_3 \frac{\sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot bcr_{ij}}{\sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot ecr_{ij}}
    + a_4 \frac{\sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot ecr_{ij} \cdot dsar_{ij}}{\sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot ecr_{ij}}
    $$

- 目标拆解
  - 人均完单
  - 一口价完单份额
  - 单均 ASP
  - ECR
  - CR
  - 呼叫 DSAR

- 线性化简化

  - 假设决策对分母的变化量级不足以影响权重系数，将各分母替换为基于观测数据的常量
  - 原优化问题乘N后，得到：
    $$
    \max \sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot bcr_{ij}
    + a_0 \frac{\sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot bcr_{ij} \cdot (f^l_{ij} + f^u_{ij})}{\frac{F}{N}}
    + a_1 \frac{\sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot bcr_{ij} \cdot gmv_{ij}}{\frac{F}{N}}
    + a_2 \frac{\sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot ecr_{ij}}{\frac{B}{N}}
    + a_3 \frac{\sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot bcr_{ij}}{\frac{C}{N}}
    + a_4 \frac{\sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot ecr_{ij} \cdot dsar_{ij}}{\frac{C}{N}}
    $$

  - 令
    $$
    \begin{aligned}
    b_0&=\frac{a_0}{\frac{F}{N}}=\frac{a_0}{\text{人均完单}} \\
    b_1&=\frac{a_1}{\frac{F}{N}}=\frac{a_1}{\text{人均完单}} \\
    b_2&=\frac{a_2}{\frac{B}{N}}=\frac{a_2}{\text{人均冒泡}} \\
    b_3&=\frac{a_3}{\frac{C}{N}}=\frac{a_3}{\text{人均呼叫}} \\
    b_4&=\frac{a_4}{\frac{C}{N}}=\frac{a_4}{\text{人均呼叫}}
    \end{aligned}
    $$

  - 则最大化目标可简化为
    $$
    \max \sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot bcr_{ij}
    + b_0 \sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot bcr_{ij} \cdot (f^l_{ij} + f^u_{ij})
    + b_1 \sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot bcr_{ij} \cdot gmv_{ij}
    + b_2 \sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot ecr_{ij}
    + b_3 \sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot bcr_{ij}
    + b_4 \sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot ecr_{ij} \cdot dsar_{ij}
    $$

  - 进一步推导：合并同类项

    **第一步**：合并所有 $bcr_{ij}$ 项（第1、2、3、4项）

    $$
    \text{bcr部分} = \sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot bcr_{ij} \cdot \Big[
      (1 + b_3)
      + b_0 (f^l_{ij} + f^u_{ij})
      + b_1 \cdot gmv_{ij}
    \Big]
    $$

    **第二步**：合并所有 $ecr_{ij}$ 项（第3、5项）

    $$
    \text{ecr部分} = \sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot ecr_{ij} \cdot (b_2 + b_4 \cdot dsar_{ij})
    $$

    **第三步**：定义每个冒泡-决策对的得分 $score_{ij}$，目标退化为

    $$
    \max \sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot score_{ij}
    $$

    其中：

    $$
    score_{ij} = bcr_{ij} \cdot \Big[(1+b_3) + b_0(f^l_{ij} + f^u_{ij}) + b_1 \cdot gmv_{ij} \Big]
    + ecr_{ij} \cdot (b_2 + b_4 \cdot dsar_{ij})
    $$

    **工程意义**：$score_{ij}$ 仅依赖单个冒泡-决策对的特征，可全部离线预计算；求解时目标为纯线性，全局耦合仅来自补贴率和水位两个约束。



### 2.5 一阶泰勒线性化简化

上一节的线性化简化使用的是“固定分母法”，即将目标函数中的完单数分母、呼叫数分母替换为历史观测常量。该方法工程实现简单，但会忽略比例指标中分母变化带来的稀释效应。

为更贴近原始目标，可将原始分式目标先改写为几个全局聚合量的函数，再在基准策略附近做一阶泰勒展开。

#### 2.5.1 聚合量定义

定义：

$$
X=\sum_i\sum_{j\in\mathcal{J}_i} z_{ij}\cdot bcr_{ij}
$$

表示预期完单数。

$$
Y=\sum_i\sum_{j\in\mathcal{J}_i} z_{ij}\cdot bcr_{ij}\cdot(f^l_{ij}+f^u_{ij})
$$

表示预期一口价完单数。

$$
G=\sum_i\sum_{j\in\mathcal{J}_i} z_{ij}\cdot bcr_{ij}\cdot gmv_{ij}
$$

表示预期 GMV。

$$
H=\sum_i\sum_{j\in\mathcal{J}_i} z_{ij}\cdot ecr_{ij}
$$

表示预期呼叫数。

$$
D=\sum_i\sum_{j\in\mathcal{J}_i} z_{ij}\cdot ecr_{ij}\cdot dsar_{ij}
$$

表示预期默勾呼叫数。

则原始目标可写为：

$$
L(X,Y,G,H,D)=
\frac{X}{N}
+a_2\frac{H}{B}
+\frac{a_0Y+a_1G}{X}
+\frac{a_3X+a_4D}{H}
$$

其中：

- $X/N$：人均完单；
- $Y/X$：一口价完单份额；
- $G/X$：单均 ASP；
- $H/B$：ECR；
- $X/H$：CR；
- $D/H$：DSAR。

#### 2.5.2 一阶泰勒展开思想

选择一个基准策略，例如线上策略或默认策略，计算其对应的聚合量：

$$
X_0,Y_0,G_0,H_0,D_0
$$

在该基准点附近，对目标函数做一阶泰勒展开：

$$
L(X,Y,G,H,D) \approx L(X_0,Y_0,G_0,H_0,D_0)
+w_X(X-X_0)+w_Y(Y-Y_0)+w_G(G-G_0)+w_H(H-H_0)+w_D(D-D_0)
$$

其中 $w_X,w_Y,w_G,w_H,w_D$ 是目标函数在基准点处对各聚合量的偏导数，也可以理解为各指标在当前基准策略附近的边际价值。

由于 $L(X_0,Y_0,G_0,H_0,D_0)$、$w_XX_0$、$w_YY_0$、$w_GG_0$、$w_HH_0$、$w_DD_0$ 都是常数，不影响最优决策，因此优化目标可简化为：

$$
\max w_XX+w_YY+w_GG+w_HH+w_DD
$$

#### 2.5.3 边际权重及推导过程

一阶泰勒展开中的权重，本质上是目标函数 $L$ 对各聚合量的偏导数。

也就是说：

$$
w_X=\left.\frac{\partial L}{\partial X}\right|_{(X_0,Y_0,G_0,H_0,D_0)},
\quad
w_Y=\left.\frac{\partial L}{\partial Y}\right|_{(X_0,Y_0,G_0,H_0,D_0)},
\quad
...
$$

目标函数为：

$$
L(X,Y,G,H,D)=
\frac{X}{N}
+a_2\frac{H}{B}
+\frac{a_0Y+a_1G}{X}
+\frac{a_3X+a_4D}{H}
$$

为了降低理解成本，可以逐个变量来看。求某个变量的偏导时，可以先把其它变量都当成常数。

**1）$w_Y$ 的推导**

目标函数中，只有这一项包含 $Y$：

$$
\frac{a_0Y+a_1G}{X}
$$

对 $Y$ 求偏导：

$$
\frac{\partial L}{\partial Y}
=\frac{a_0}{X}
$$

在基准点处代入 $X_0$，得到：

$$
w_Y=\frac{a_0}{X_0}
$$

含义：在当前基准策略附近，预期一口价完单数 $Y$ 多增加 1，长期目标大约增加 $a_0/X_0$。当前总完单数 $X_0$ 越大，新增 1 个一口价完单对一口价完单份额的影响越小。

**2）$w_G$ 的推导**

目标函数中，只有这一项包含 $G$：

$$
\frac{a_0Y+a_1G}{X}
$$

对 $G$ 求偏导：

$$
\frac{\partial L}{\partial G}
=\frac{a_1}{X}
$$

在基准点处代入 $X_0$，得到：

$$
w_G=\frac{a_1}{X_0}
$$

含义：在当前基准策略附近，预期 GMV $G$ 多增加 1，长期目标大约增加 $a_1/X_0$。当前总完单数 $X_0$ 越大，新增 1 元 GMV 对单均 ASP 的影响越小。

**3）$w_D$ 的推导**

目标函数中，只有这一项包含 $D$：

$$
\frac{a_3X+a_4D}{H}
$$

对 $D$ 求偏导：

$$
\frac{\partial L}{\partial D}
=\frac{a_4}{H}
$$

在基准点处代入 $H_0$，得到：

$$
w_D=\frac{a_4}{H_0}
$$

含义：在当前基准策略附近，预期默勾呼叫数 $D$ 多增加 1，长期目标大约增加 $a_4/H_0$。当前总呼叫数 $H_0$ 越大，新增 1 个默勾呼叫对 DSAR 的影响越小。

**4）$w_X$ 的推导**

目标函数中，与 $X$ 有关的项有三项：

$$
\frac{X}{N}
$$

$$
\frac{a_0Y+a_1G}{X}
$$

$$
\frac{a_3X+a_4D}{H}
$$

逐项求偏导。

第一项：

$$
\frac{\partial}{\partial X}\left(\frac{X}{N}\right)=\frac{1}{N}
$$

第二项中，$a_0Y+a_1G$ 对 $X$ 来说是常数，因此：

$$
\frac{\partial}{\partial X}\left(\frac{a_0Y+a_1G}{X}\right)
=-\frac{a_0Y+a_1G}{X^2}
$$

第三项中，$H$ 和 $D$ 对 $X$ 来说是常数，因此：

$$
\frac{\partial}{\partial X}\left(\frac{a_3X+a_4D}{H}\right)
=\frac{a_3}{H}
$$

三项相加：

$$
\frac{\partial L}{\partial X}
=\frac{1}{N}
-\frac{a_0Y+a_1G}{X^2}
+\frac{a_3}{H}
$$

在基准点处代入 $X_0,Y_0,G_0,H_0$，得到：

$$
w_X=\frac{1}{N}-\frac{a_0Y_0+a_1G_0}{X_0^2}+\frac{a_3}{H_0}
$$

含义：$w_X$ 是新增一个预期完单的综合边际价值，由三部分组成：

- $\frac{1}{N}$：新增完单会提升人均完单，是正向收益；
- $-\frac{a_0Y_0+a_1G_0}{X_0^2}$：新增完单会作为一口价份额、单均 ASP 的分母，可能稀释这两个比例指标，是负向影响；
- $\frac{a_3}{H_0}$：新增完单会作为 CR 的分子，提升 CR，是正向收益。

因此，$w_X$ 不一定必然为正，它取决于“完单本身收益 + CR 收益”和“一口价份额、单均 ASP 稀释损失”的相对大小。

**5）$w_H$ 的推导**

目标函数中，与 $H$ 有关的项有两项：

$$
a_2\frac{H}{B}
$$

$$
\frac{a_3X+a_4D}{H}
$$

逐项求偏导。

第一项：

$$
\frac{\partial}{\partial H}\left(a_2\frac{H}{B}\right)=\frac{a_2}{B}
$$

第二项中，$a_3X+a_4D$ 对 $H$ 来说是常数，因此：

$$
\frac{\partial}{\partial H}\left(\frac{a_3X+a_4D}{H}\right)
=-\frac{a_3X+a_4D}{H^2}
$$

两项相加：

$$
\frac{\partial L}{\partial H}
=\frac{a_2}{B}
-\frac{a_3X+a_4D}{H^2}
$$

在基准点处代入 $X_0,H_0,D_0$，得到：

$$
w_H=\frac{a_2}{B}-\frac{a_3X_0+a_4D_0}{H_0^2}
$$

含义：$w_H$ 是新增一个预期呼叫的综合边际价值，由两部分组成：

- $\frac{a_2}{B}$：新增呼叫会提升 ECR，是正向收益；
- $-\frac{a_3X_0+a_4D_0}{H_0^2}$：新增呼叫会作为 CR、DSAR 的分母，可能稀释这两个比例指标，是负向影响。

因此，$w_H$ 也不一定必然为正。如果业务权重更重视 CR、DSAR，而新增呼叫质量不高，那么 $w_H$ 可能为负。

**汇总结果**

$$
w_Y=\frac{a_0}{X_0}
$$

$$
w_G=\frac{a_1}{X_0}
$$

$$
w_D=\frac{a_4}{H_0}
$$

$$
w_X=\frac{1}{N}-\frac{a_0Y_0+a_1G_0}{X_0^2}+\frac{a_3}{H_0}
$$

$$
w_H=\frac{a_2}{B}-\frac{a_3X_0+a_4D_0}{H_0^2}
$$

其中：

- $w_X$ 表示新增一个完单的边际价值，包含人均完单的正向收益、CR 分子的正向收益，以及对一口价份额和单均 ASP 分母的稀释影响；
- $w_H$ 表示新增一个呼叫的边际价值，包含 ECR 的正向收益，以及对 CR、DSAR 分母的稀释影响；
- $w_Y,w_G,w_D$ 分别表示新增一口价完单、新增 GMV、新增默勾呼叫的边际价值。

#### 2.5.4 冒泡-决策级得分

将 $X,Y,G,H,D$ 的定义代入线性化目标，可得到每个冒泡-决策对的得分：

$$
score_{ij}
=w_X\cdot bcr_{ij}
+w_Y\cdot bcr_{ij}\cdot(f^l_{ij}+f^u_{ij})
+w_G\cdot bcr_{ij}\cdot gmv_{ij}
+w_H\cdot ecr_{ij}
+w_D\cdot ecr_{ij}\cdot dsar_{ij}
$$

则优化目标变为：

$$
\max \sum_i\sum_{j\in\mathcal{J}_i}z_{ij}\cdot score_{ij}
$$

该目标是线性的，且 $score_{ij}$ 仅依赖单个冒泡-决策对，可离线预计算。

#### 2.5.5 与固定分母法的差异

固定分母法只将 $X,H$ 替换为常数，主要考虑比例指标分子的变化；一阶泰勒展开除了考虑分子变化，还额外考虑分母变化带来的稀释效应。

例如，一口价份额为 $Y/X$。如果某个决策只增加非一口价完单，则 $X$ 增加但 $Y$ 不增加，真实一口价份额会被稀释。固定分母法不容易表达这个影响，而一阶泰勒展开中的 $w_X$ 会通过负项 $-\frac{a_0Y_0+a_1G_0}{X_0^2}$ 体现该稀释影响。

#### 2.5.6 是否迭代

若不进行迭代，则基准点 $X_0,Y_0,G_0,H_0,D_0$ 固定，权重 $w_X,w_Y,w_G,w_H,w_D$ 在整个求解过程中都是常数。

若进行迭代，则每一轮内部权重固定；每轮求解结束后，用新策略重新计算 $X_0,Y_0,G_0,H_0,D_0$，再更新下一轮权重。

#### 2.5.7 一阶泰勒线性化后的完整规划问题

目标：

$$
\max \sum_i\sum_{j\in\mathcal{J}_i}z_{ij}\cdot score_{ij}
$$

约束：

$$
\sum_{j\in\mathcal{J}_i}z_{ij}=1,\quad \forall i
$$

$$
\sum_i\sum_{j\in\mathcal{J}_i} z_{ij}\cdot bcr_{ij}\cdot(cost_{ij}-gmv_{ij}\cdot\beta)\le 0
$$

$$
\sum_i\sum_{j\in\mathcal{J}_i} I_i\cdot z_{ij}\cdot(p^{u'}_i\cdot d^u_j\cdot\alpha-p^{u'}_i\cdot d^l_j)\le 0
$$

$$
z_{ij}\in\{0,1\}
$$

一阶泰勒线性化后，问题变成一个带两个全局约束的多重选择 0-1 线性规划。每个冒泡必须选择一个决策，全局耦合仅来自补贴率约束和幸运盒子水位约束。


### 2.6 基于一阶泰勒目标的拉格朗日松弛与对偶问题

一阶泰勒线性化后，原始分式目标已经被近似为线性目标：

$$
\max \sum_i\sum_{j\in\mathcal{J}_i} z_{ij}\cdot score_{ij}
$$

同时仍然保留两个全局约束：补贴率约束和幸运盒子水位约束。为了简化记号，定义：

$$
s_{ij}=score_{ij}
$$

$$
c_{ij}=bcr_{ij}\cdot(cost_{ij}-\beta\cdot gmv_{ij})
$$

其中 $c_{ij}$ 表示决策 $(i,j)$ 对补贴率约束的占用。若 $c_{ij}$ 越大，表示该决策越容易推高补贴率约束左侧。

再定义：

$$
r_{ij}=I_i\cdot(p^{u'}_i\cdot d^u_j\cdot\alpha-p^{u'}_i\cdot d^l_j)
$$

其中 $r_{ij}$ 表示决策 $(i,j)$ 对水位约束的占用。

因此，一阶泰勒线性化后的规划问题可写成：

$$
\max \sum_i\sum_{j\in\mathcal{J}_i} z_{ij}s_{ij}
$$

约束为：

$$
\sum_{j\in\mathcal{J}_i} z_{ij}=1,\quad \forall i
$$

$$
\sum_i\sum_{j\in\mathcal{J}_i} z_{ij}c_{ij}\le 0
$$

$$
\sum_i\sum_{j\in\mathcal{J}_i} z_{ij}r_{ij}\le 0
$$

$$
z_{ij}\in\{0,1\}
$$

该问题可以理解为一个双约束的多重选择 0-1 背包问题：每个冒泡 $i$ 是一个分组，每个分组必须选择一个决策 $j$；每个决策有收益 $s_{ij}$，同时消耗两类全局资源 $c_{ij}$ 和 $r_{ij}$。

#### 2.6.1 拉格朗日松弛形式

对两个不等式约束分别引入非负拉格朗日乘子：

$$
\lambda_c\ge 0
$$

$$
\lambda_r\ge 0
$$

其中：

- $\lambda_c$ 表示补贴率约束的影子价格；
- $\lambda_r$ 表示水位约束的影子价格。

由于原问题是最大化问题，且约束形式是 $\le 0$，拉格朗日函数可写为：

$$
\mathcal{L}(z,\lambda_c,\lambda_r)
=\sum_i\sum_j z_{ij}s_{ij}
-\lambda_c\sum_i\sum_j z_{ij}c_{ij}
-\lambda_r\sum_i\sum_j z_{ij}r_{ij}
$$

合并同类项：

$$
\mathcal{L}(z,\lambda_c,\lambda_r)
=\sum_i\sum_j z_{ij}\left(s_{ij}-\lambda_c c_{ij}-\lambda_r r_{ij}\right)
$$

松弛问题变成：

$$
\min_{\lambda_c\ge 0,\lambda_r\ge 0} \max_z \sum_i\sum_j z_{ij}\left(s_{ij}-\lambda_c c_{ij}-\lambda_r r_{ij}\right)
$$



#### 2.6.3 对偶问题

拉格朗日对偶问题的核心操作是交换 $\max$ 和 $\min$ 的顺序，得到 min-max 形式：

$$
D^*=
\min_{\lambda_c\ge 0,\lambda_r\ge 0}
\max_{z\in\mathcal{Z}}
\mathcal{L}(z,\lambda_c,\lambda_r)
$$

给定 $\lambda_c,\lambda_r$ 后，内部的最大化问题就是松弛问题：

$$
\max_{z\in\mathcal{Z}}\mathcal{L}(z,\lambda_c,\lambda_r)
$$

它的最优值定义为对偶函数：

$$
q(\lambda_c,\lambda_r)=
\max_{z\in\mathcal{Z}}\mathcal{L}(z,\lambda_c,\lambda_r)
$$

由于给定乘子后，每个冒泡可以独立求解，因此：

$$
q(\lambda_c,\lambda_r)
=
\sum_i \max_{j\in\mathcal{J}_i}
\left(
 s_{ij}-\lambda_c c_{ij}-\lambda_r r_{ij}
\right)
$$

对于原始最大化问题，拉格朗日松弛给出的是原问题最优值的上界，因此对偶问题是寻找最紧的上界：

$$
\min_{\lambda_c\ge 0,\lambda_r\ge 0}q(\lambda_c,\lambda_r)
$$

也就是：

$$
\min_{\lambda_c\ge 0,\lambda_r\ge 0}
\sum_i \max_{j\in\mathcal{J}_i}\left(s_{ij}-\lambda_c c_{ij}-\lambda_r r_{ij}\right)
$$

直观理解：

- 如果 $\lambda_c$ 太小，高补贴消耗的决策没有受到足够惩罚，候选解可能违反补贴率约束；
- 如果 $\lambda_c$ 太大，模型会过度保守，牺牲过多收益；
- $\lambda_r$ 对水位约束起类似作用；
- 对偶问题就是寻找一组合适的惩罚价格，使松弛后的上界尽可能紧。

### 2.7 拉格朗日对偶问题的求解方法

上一节主要讨论拉格朗日松弛、max-min 与 min-max 对偶形式，以及弱对偶、强对偶等理论问题。本节单独整理求解方法，重点关注如何搜索 $\lambda_c,\lambda_r$，以及如何从搜索过程中得到可行的整数策略。

#### 2.7.1 二维三分法的缺点

在求解对偶问题时，一个直观想法是：既然对偶问题只有两个变量 $\lambda_c,\lambda_r$，是否可以用二维三分法来搜索最小值。结论是：**不建议将二维三分法作为主要求解方法**。

原因并不是二维三分法完全不能运行，而是它与本问题的对偶函数形状不匹配。

对偶函数为：

$$
q(\lambda_c,\lambda_r)
=\sum_i \max_{j\in\mathcal{J}_i}
\left(s_{ij}-\lambda_c c_{ij}-\lambda_r r_{ij}\right)
$$

对每个固定决策 $j$ 来说：

$$
s_{ij}-\lambda_c c_{ij}-\lambda_r r_{ij}
$$

是关于 $\lambda_c,\lambda_r$ 的线性函数。多个线性函数取最大值后，会形成一个**分段线性的凸函数**。因此 $q(\lambda_c,\lambda_r)$ 具有以下特点：

- 凸，但通常不光滑；
- 可能存在很多折点；
- 可能存在一大片平台区域；
- $\lambda$ 轻微变化时，诱导出的原始决策可能突然切换；
- 对偶值较小，不一定意味着诱导出的原始整数方案可行或业务目标更好。

而三分法更适合的函数形状是“单谷、平滑、谷底相对明确”的函数。例如一维三分法通常假设函数先下降、后上升。二维三分法或嵌套三分法也隐含类似假设：沿某个方向看，函数最好具有较稳定的单谷结构。

但本问题中的 $q$ 往往不是这种形状。

##### 例子 1：平台会让三分法难以判断方向

先看一个一维简化例子：

$$
q(\lambda)=\max(10-2\lambda,\ 6,\ 2+\lambda)
$$

计算几个点：

| $\lambda$ | $10-2\lambda$ | $6$ | $2+\lambda$ | $q(\lambda)$ |
|---:|---:|---:|---:|---:|
| 0 | 10 | 6 | 2 | 10 |
| 1 | 8 | 6 | 3 | 8 |
| 2 | 6 | 6 | 4 | 6 |
| 3 | 4 | 6 | 5 | 6 |
| 4 | 2 | 6 | 6 | 6 |
| 5 | 0 | 6 | 7 | 7 |

可以看到，在 $[2,4]$ 区间内，$q(\lambda)=6$ 都是最优值。

也就是说，最优区域不是一个点，而是一段平台。

如果三分法取两个点：

$$
m_1=2.5,\quad m_2=3.5
$$

则：

$$
q(m_1)=q(m_2)=6
$$

此时三分法无法判断应该向左缩小区间，还是向右缩小区间，因为两边对偶值一样。更关键的是，平台上的不同 $\lambda$ 可能诱导出不同的原始策略。例如某些点补贴约束更紧，某些点水位约束更紧，某些点收益更高。三分法只看 $q$ 值，无法区分这些业务差异。

##### 例子 2：二维最优区域可能是一大片，而不是一个点

考虑二维例子：

$$
q(\lambda_c,\lambda_r)
=\max(
10-2\lambda_c,
10-2\lambda_r,
6,
1+0.25\lambda_c+0.25\lambda_r
)
$$

若希望 $q(\lambda_c,\lambda_r)=6$，需要满足：

$$
10-2\lambda_c\le 6
$$

即：

$$
\lambda_c\ge 2
$$

同时：

$$
10-2\lambda_r\le 6
$$

即：

$$
\lambda_r\ge 2
$$

还需要：

$$
1+0.25\lambda_c+0.25\lambda_r\le 6
$$

即：

$$
\lambda_c+\lambda_r\le 20
$$

因此，所有满足：

$$
\lambda_c\ge 2,\quad \lambda_r\ge 2,\quad \lambda_c+\lambda_r\le 20
$$

的点，都可以达到同样的最小对偶值 $6$。

这说明二维对偶函数的最优解可能是一片区域，例如：

$$
(2,2),(3,3),(5,4),(10,5)
$$

都可能有相同的对偶值。

但这些点诱导出的原始策略可能完全不同：

- $(2,2)$ 可能补贴使用更充分；
- $(3,3)$ 可能两个约束都稍微保守；
- $(10,5)$ 可能补贴惩罚过强，导致收益损失较大。

二维三分法只能尝试降低对偶值，却不能保证找到业务上最好的原始可行解。

##### 例子 3：离散决策导致原始方案跳变

假设某个冒泡有三个候选决策：

| 决策 | 收益 $s$ | 补贴消耗 $c$ | 水位消耗 $r$ |
|---|---:|---:|---:|
| A | 100 | 10 | 0 |
| B | 98 | 0 | 10 |
| C | 95 | 0 | 0 |

给定 $\lambda_c,\lambda_r$ 后，调整后得分为：

$$
A:100-10\lambda_c
$$

$$
B:98-10\lambda_r
$$

$$
C:95
$$

当 $\lambda_c$ 较小、$\lambda_r$ 较大时，可能选择 A；当 $\lambda_c$ 较大、$\lambda_r$ 较小时，可能选择 B；当两个惩罚都较大时，可能选择 C。

因此，在 $\lambda_c,\lambda_r$ 平面上，不同决策区域像拼图一样分布。只要跨过某条边界，原始决策就会突然切换。对应的总补贴消耗 $C(\lambda)$ 和总水位消耗 $R(\lambda)$ 也会阶梯式跳变，而不是平滑变化。

三分法基于少数点评估函数值来缩小区间，但它无法识别这些决策切换边界。而实际业务中，高质量可行解往往出现在“刚好满足约束”的边界附近。

##### 小结

二维三分法不适合作为主方法，主要原因是：

1. 对偶函数 $q$ 是分段线性凸函数，不是光滑碗状函数；
2. 最优区域可能是一片平台，而不是一个点；
3. $\lambda$ 的轻微变化可能导致原始决策跳变；
4. 对偶值较小，不代表诱导出的原始整数方案一定可行；
5. 最终业务目标是找到高收益的可行原始方案，而不是只最小化对偶上界。

因此，二维三分法最多作为启发式实验，不建议作为主求解方案。更推荐使用：

- 二维粗网格 + 局部细网格；
- 外层枚举 + 内层二分；
- 次梯度法；
- 或更专业的 bundle/cutting-plane 方法。

#### 2.7.2 外层枚举 + 内层二分法

该方法适合双约束问题中的一个约束可以通过某个乘子较稳定地控制的场景。例如：补贴率约束通常是预算类约束，可以用 $\lambda_c$ 控制；水位约束可以通过枚举 $\lambda_r$ 来扫描不同水位惩罚强度。

基本思路是：

- 外层枚举 $\lambda_r$；
- 对每个固定的 $\lambda_r$，内层用二分法搜索 $\lambda_c$，使补贴约束尽量接近边界；
- 对每组得到的候选策略，计算真实约束值和原始目标；
- 最终从所有可行候选策略中选择最优。

##### 2.7.2.1 给定乘子后的决策计算

给定一组 $\lambda_c,\lambda_r$ 后，每个冒泡独立选择：

$$
j_i^*(\lambda_c,\lambda_r)
=\arg\max_{j\in\mathcal{J}_i}
\left(s_{ij}-\lambda_c c_{ij}-\lambda_r r_{ij}\right)
$$

得到全量策略后，计算：

$$
S(\lambda_c,\lambda_r)=\sum_i s_{ij_i^*}
$$

$$
C(\lambda_c,\lambda_r)=\sum_i c_{ij_i^*}
$$

$$
R(\lambda_c,\lambda_r)=\sum_i r_{ij_i^*}
$$

其中：

- $S$ 是一阶泰勒线性化目标；
- $C\le 0$ 表示补贴率约束满足；
- $R\le 0$ 表示水位约束满足。

##### 2.7.2.2 为什么内层可以对 $\lambda_c$ 二分

固定 $\lambda_r$ 后，若增大 $\lambda_c$，高 $c_{ij}$ 的决策会受到更强惩罚，因此整体补贴约束消耗 $C(\lambda_c,\lambda_r)$ 通常会下降。

直观上：

$$
\lambda_c \uparrow
\quad\Rightarrow\quad
\text{高补贴消耗决策更不容易被选中}
\quad\Rightarrow\quad
C(\lambda_c,\lambda_r) \downarrow
$$

由于决策是离散的，$C(\lambda_c,\lambda_r)$ 通常不是连续下降，而是阶梯状下降。因此二分法不一定能找到刚好 $C=0$ 的点，但可以找到：

- 第一个满足 $C\le 0$ 的点；
- 或者一个接近约束边界的可行点；
- 同时保留边界另一侧的略微不可行点，用于后续修复。

##### 2.7.2.3 具体计算流程

设定外层枚举集合：

$$
\Lambda_r=\{\lambda_r^{(1)},\lambda_r^{(2)},\dots,\lambda_r^{(K)}\}
$$

例如可以取：

$$
\lambda_r\in[0,\lambda_r^{max}]
$$

并使用等距网格或对数网格。

对每个固定的 $\lambda_r^{(k)}$，执行以下步骤。

**步骤 1：初始化内层二分下界**

$$
\lambda_c^{low}=0
$$

计算：

$$
C(\lambda_c^{low},\lambda_r^{(k)})
$$

若此时已经满足：

$$
C(\lambda_c^{low},\lambda_r^{(k)})\le 0
$$

说明在当前 $\lambda_r^{(k)}$ 下，不需要补贴惩罚也能满足补贴约束，可以直接记录该候选方案。

**步骤 2：寻找内层二分上界**

从一个较小值开始，例如：

$$
\lambda_c^{high}=1
$$

如果：

$$
C(\lambda_c^{high},\lambda_r^{(k)})>0
$$

说明补贴仍然超约束，则不断扩大上界：

$$
\lambda_c^{high}\leftarrow 2\lambda_c^{high}
$$

直到满足：

$$
C(\lambda_c^{high},\lambda_r^{(k)})\le 0
$$

或达到最大允许上界 $\lambda_c^{max}$。

如果达到 $\lambda_c^{max}$ 后仍无法满足 $C\le 0$，说明当前 $\lambda_r^{(k)}$ 下，单纯增大 $\lambda_c$ 也难以找到满足补贴约束的方案。此时可以跳过该外层点，或者记录最接近可行的候选方案。

**步骤 3：二分搜索 $\lambda_c$**

重复 $T$ 次：

$$
\lambda_c^{mid}=\frac{\lambda_c^{low}+\lambda_c^{high}}{2}
$$

计算当前策略：

$$
j_i^*=\arg\max_{j\in\mathcal{J}_i}
\left(s_{ij}-\lambda_c^{mid}c_{ij}-\lambda_r^{(k)}r_{ij}\right)
$$

并计算：

$$
C^{mid}=\sum_i c_{ij_i^*}
$$

如果：

$$
C^{mid}>0
$$

说明补贴仍然超约束，需要提高补贴惩罚：

$$
\lambda_c^{low}\leftarrow \lambda_c^{mid}
$$

如果：

$$
C^{mid}\le 0
$$

说明补贴约束已经满足，可以尝试降低补贴惩罚，以减少收益损失：

$$
\lambda_c^{high}\leftarrow \lambda_c^{mid}
$$

二分结束后，通常取 $\lambda_c^{high}$ 对应的方案作为“补贴约束满足且较接近边界”的候选方案。

**步骤 4：计算水位约束并记录候选解**

对二分得到的候选方案，计算：

$$
R=\sum_i r_{ij_i^*}
$$

如果：

$$
C\le 0,\quad R\le 0
$$

则记录为可行候选解。

如果：

$$
C\le 0,\quad R>0
$$

说明补贴满足但水位不满足。由于外层正在枚举 $\lambda_r$，可以依赖更大的 $\lambda_r$ 来惩罚水位消耗。

如果：

$$
C>0
$$

说明二分未能找到补贴可行点，可以记录为待修复候选，也可以丢弃。

##### 2.7.2.4 伪代码

```text
candidate_solutions = []

for lambda_r in Lambda_r:
    lambda_c_low = 0
    lambda_c_high = 1

    while C(lambda_c_high, lambda_r) > 0 and lambda_c_high < lambda_c_max:
        lambda_c_high = 2 * lambda_c_high

    if C(lambda_c_high, lambda_r) > 0:
        continue

    for t in range(T):
        lambda_c_mid = (lambda_c_low + lambda_c_high) / 2
        solution_mid = choose_by_adjusted_score(lambda_c_mid, lambda_r)
        C_mid = calc_subsidy_constraint(solution_mid)

        if C_mid > 0:
            lambda_c_low = lambda_c_mid
        else:
            lambda_c_high = lambda_c_mid

    solution = choose_by_adjusted_score(lambda_c_high, lambda_r)
    C_value = calc_subsidy_constraint(solution)
    R_value = calc_waterlevel_constraint(solution)
    S_value = calc_taylor_score(solution)
    original_value = calc_original_fractional_objective(solution)

    if C_value <= 0 and R_value <= 0:
        candidate_solutions.append(solution)
```

##### 2.7.2.5 优缺点

优点：

- 比完整二维网格更省计算；
- 内层二分直接围绕补贴约束边界搜索，业务解释清晰；
- 外层枚举 $\lambda_r$ 可以产生多个水位偏好下的候选策略；
- 容易并行，不同 $\lambda_r$ 之间互不依赖。

缺点：

- 双约束之间存在耦合，外层 $\lambda_r$ 改变后，内层二分得到的 $\lambda_c$ 也会变化；
- $C(\lambda_c,\lambda_r)$ 是阶梯函数，不一定能精确卡到 $0$；
- 若水位约束非常关键，仅靠外层稀疏枚举可能错过好点；
- 不能保证得到原 0-1 问题的全局最优解。

实践建议：

- 外层 $\lambda_r$ 先用粗网格，再在可行解表现较好的区域做细网格；
- 内层二分时同时保留 $\lambda_c^{low}$ 和 $\lambda_c^{high}$ 两侧方案；
- 最终不要只按对偶值排序，而应在可行候选解中用原始分式目标重排。

#### 2.7.3 次梯度法

次梯度法是求解拉格朗日对偶问题的标准方法之一，适合本问题这种“凸但不光滑”的对偶函数。

对偶问题为：

$$
\min_{\lambda_c\ge 0,\lambda_r\ge 0}
q(\lambda_c,\lambda_r)
$$

其中：

$$
q(\lambda_c,\lambda_r)
=\sum_i\max_{j\in\mathcal{J}_i}
\left(s_{ij}-\lambda_c c_{ij}-\lambda_r r_{ij}\right)
$$

##### 2.7.3.1 次梯度的来源

给定当前乘子：

$$
\lambda^t=(\lambda_c^t,\lambda_r^t)
$$

先求每个冒泡的最优决策：

$$
j_i^t=\arg\max_{j\in\mathcal{J}_i}
\left(s_{ij}-\lambda_c^t c_{ij}-\lambda_r^t r_{ij}\right)
$$

此时对偶函数在当前点附近的一组次梯度可以由当前被选中的约束消耗给出：

$$
g_c^t=-\sum_i c_{ij_i^t}
$$

$$
g_r^t=-\sum_i r_{ij_i^t}
$$

记：

$$
C^t=\sum_i c_{ij_i^t},\quad R^t=\sum_i r_{ij_i^t}
$$

则：

$$
g^t=(-C^t,-R^t)
$$

因为我们要最小化对偶函数 $q$，可按负次梯度方向更新。等价地，可写成：

$$
\lambda_c^{t+1}=\max(0,\lambda_c^t+\eta_t C^t)
$$

$$
\lambda_r^{t+1}=\max(0,\lambda_r^t+\eta_t R^t)
$$

这里的 $\max(0,\cdot)$ 是投影操作，用来保证：

$$
\lambda_c\ge 0,\quad \lambda_r\ge 0
$$

##### 2.7.3.2 更新公式的业务解释

如果当前方案补贴超约束：

$$
C^t>0
$$

则：

$$
\lambda_c^{t+1}>\lambda_c^t
$$

即提高补贴惩罚，让高补贴消耗决策下一轮更不容易被选中。

如果当前方案补贴约束很宽松：

$$
C^t<0
$$

则：

$$
\lambda_c^{t+1}<\lambda_c^t
$$

即降低补贴惩罚，避免过度保守。

水位约束同理：

- 若 $R^t>0$，说明水位约束违反，提高 $\lambda_r$；
- 若 $R^t<0$，说明水位约束宽松，降低 $\lambda_r$。

##### 2.7.3.3 具体计算流程

**步骤 1：初始化乘子**

可以取：

$$
\lambda_c^0=0,\quad \lambda_r^0=0
$$

也可以用网格搜索得到的较好点作为初始值。

**步骤 2：给定当前乘子，计算原始候选方案**

对每个冒泡：

$$
j_i^t=\arg\max_{j\in\mathcal{J}_i}
\left(s_{ij}-\lambda_c^t c_{ij}-\lambda_r^t r_{ij}\right)
$$

**步骤 3：计算当前方案的收益与约束**

$$
S^t=\sum_i s_{ij_i^t}
$$

$$
C^t=\sum_i c_{ij_i^t}
$$

$$
R^t=\sum_i r_{ij_i^t}
$$

同时建议计算原始分式目标：

$$
L^t=\frac{X^t}{N}+a_0\frac{Y^t}{X^t}+a_1\frac{G^t}{X^t}+a_2\frac{H^t}{B}+a_3\frac{X^t}{H^t}+a_4\frac{D^t}{H^t}
$$

其中 $X^t,Y^t,G^t,H^t,D^t$ 由当前策略重新聚合得到。

**步骤 4：保存可行候选解**

如果：

$$
C^t\le 0,\quad R^t\le 0
$$

则将当前策略保存为可行候选解。

**步骤 5：更新乘子**

选择步长 $\eta_t$，更新：

$$
\lambda_c^{t+1}=\max(0,\lambda_c^t+\eta_t C^t)
$$

$$
\lambda_r^{t+1}=\max(0,\lambda_r^t+\eta_t R^t)
$$

**步骤 6：重复迭代**

重复步骤 2-5，直到满足停止条件，例如：

- 迭代次数达到上限；
- 连续多轮最好的可行解没有提升；
- $C^t,R^t$ 已经接近 0；
- $\lambda_c,\lambda_r$ 变化很小。

##### 2.7.3.4 步长选择

步长 $\eta_t$ 对次梯度法效果影响较大。常见选择有以下几种。

**固定步长**

$$
\eta_t=\eta
$$

优点是简单；缺点是容易震荡。

**递减步长**

$$
\eta_t=\frac{\eta_0}{\sqrt{t+1}}
$$

或：

$$
\eta_t=\frac{\eta_0}{t+1}
$$

优点是更稳定；缺点是后期可能收敛较慢。

**Polyak 步长**

如果当前已经有一个最好的原始可行解目标值 $LB$，可使用：

$$
\eta_t=\gamma\cdot\frac{q(\lambda^t)-LB}{(C^t)^2+(R^t)^2+\epsilon}
$$

其中：

- $q(\lambda^t)$ 是当前对偶上界；
- $LB$ 是当前找到的最好可行整数解目标值；
- $\gamma$ 是缩放系数，通常取 $(0,2)$ 之间；
- $\epsilon$ 是很小的正数，避免分母为 0。

Polyak 步长利用了“当前上界与当前最好下界的差距”，通常比固定步长更有方向感，但实现略复杂。

##### 2.7.3.5 伪代码

```text
candidate_solutions = []

lambda_c = initial_lambda_c
lambda_r = initial_lambda_r

for t in range(T):
    solution = choose_by_adjusted_score(lambda_c, lambda_r)

    S_value = calc_taylor_score(solution)
    C_value = calc_subsidy_constraint(solution)
    R_value = calc_waterlevel_constraint(solution)
    q_value = calc_dual_value(lambda_c, lambda_r)
    original_value = calc_original_fractional_objective(solution)

    if C_value <= 0 and R_value <= 0:
        candidate_solutions.append(solution)
        update_best_feasible_solution(solution)

    eta_t = choose_step_size(t, q_value, best_feasible_value, C_value, R_value)

    lambda_c = max(0, lambda_c + eta_t * C_value)
    lambda_r = max(0, lambda_r + eta_t * R_value)
```

##### 2.7.3.6 优缺点

优点：

- 与拉格朗日对偶问题结构匹配；
- 不需要二维网格全量枚举，适合大规模数据；
- 每轮计算可以按冒泡并行；
- 更新方向直接来自约束是否违反，业务解释清楚。

缺点：

- 需要调步长；
- 对偶函数不光滑，可能震荡；
- 每轮诱导出的原始整数方案不一定可行；
- 不保证得到原始 0-1 问题的全局最优解。

实践建议：

- 可先用粗网格找到较好的初始 $\lambda$，再用次梯度微调；
- 每轮都保存可行候选解，而不是只保留最后一轮；
- 若候选方案轻微违反约束，可结合局部替换做可行化修复；
- 最终在所有可行候选解中，用原始分式目标重排。

#### 2.7.4 工程使用建议

拉格朗日松弛通常不能直接保证输出的整数方案可行，因此建议将它作为候选策略生成器使用。

推荐流程：

1. 对每个冒泡-决策对预计算 $s_{ij},c_{ij},r_{ij}$；
2. 搜索多组 $\lambda_c,\lambda_r$；
3. 对每组 $\lambda_c,\lambda_r$，每个冒泡独立选择调整后得分最高的决策；
4. 计算候选方案的真实约束值 $C,R$；
5. 只保留满足 $C\le 0,R\le 0$ 的可行方案；
6. 在可行方案中，先按一阶泰勒线性化目标排序，再用原始分式目标重算并重排；
7. 若高收益候选方案轻微违反约束，可通过局部替换做可行化修复。

总结：一阶泰勒简化将原问题转化为“线性收益 + 两个全局线性约束 + 每个冒泡选择一个决策”的结构。该结构可以进行拉格朗日松弛和对偶变换。弱对偶关系成立，因此对偶值可作为原 0-1 问题最优值的上界；但由于整数变量导致可行域非凸，强对偶一般不保证成立，实际落地仍需保留和筛选可行整数解。


- 待解决问题：
  - 司机单均收入不考虑 TR，用乘客应付 ASP 代替；也可简化为单均里程 & TR

- 约束：
  - 决策分配约束：每个冒泡有且仅有一个决策

$$
\sum_{j \in \mathcal{J}_i} z_{ij} = 1, \quad \forall i \qquad z_{ij} \in \{0, 1\}
$$

  - 补贴率约束

$$
\sum_i\sum_{j\in\mathcal{J}_i} z_{ij} \cdot bcr_{ij} \cdot (cost_{ij} - gmv_{ij} \cdot \beta) \le 0
$$

  - 水位约束

$$
\sum_i\sum_{j\in\mathcal{J}_i} I_i \cdot z_{ij} \cdot (p^{u'}_i \cdot d^u_j \cdot \alpha - p^{u'}_i \cdot d^l_j) \le 0
$$
