# PPNet 与 D/O/OD 任务输出

## 1. 为什么 OneTrans 后还需要 PPNet

OneTrans 产生的是共享联合表示 $z$。但乘客履约 D、司机履约 O、司乘履约 OD 的决策条件并不相同：同一个接驾距离对乘客取消风险和司机履约意愿的影响可能不同。

PPNet 为每个任务保留独立参数，并在每一层 hidden 前生成个性化 gate：

$$
h_{l+1}^{(t)}=f_l^{(t)}\left(h_l^{(t)}\odot g_l^{(t)}([\operatorname{sg}(z),x_{pp}])\right),
\quad t\in\{OD,O,D\}
$$

其中 $x_{pp}$ 表示主体/类别/场景等先验。它不是为每位用户生成完整网络，而是按样本动态调节共享或任务网络的有效维度。

## 2. 三个任务头

```text
shared OneTrans representation
       ├── PPNet_OD → head_OD → 司乘履约率
       ├── PPNet_O  → head_O  → 司机履约
       └── PPNet_D  → head_D  → 乘客履约
```

每个头输出一个二分类 logit/probability。任务损失可抽象为：

$$
\mathcal L=\lambda_{OD}\mathcal L_{OD}+\lambda_O\mathcal L_O+\lambda_D\mathcal L_D
$$

实际标签窗口、损失函数和权重未在材料中给出，不能补写具体数字。

## 3. D→O 的扩展边界

“将 D 作为 O 的输入”只能使用 D hidden、预测值或 stop-gradient 的 logit；训练时直接喂真实 D 标签会造成标签泄漏和 train-serving skew。该方向属于后续探索，不是当前主模型已确认的结构。

## 4. 与 PosSA baseline 的区别

补充材料中 PosSA baseline 的六 tower 是围绕连环派/非连环派的场景选路设计。当前 PEPNet × OneTrans 资料可确认 D/O/OD 多任务头，但不能据此断言其仍保留相同 six-tower 物理实现。
