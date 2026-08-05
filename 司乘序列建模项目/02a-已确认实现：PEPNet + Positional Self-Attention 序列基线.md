# 已确认实现：PEPNet + Positional Self-Attention 序列基线

> 定位：这是当前项目中可用于介绍的**主序列建模 baseline**。它不同于 OneTrans：先分别编码乘客/司机历史订单序列，再与静态特征融合进 PEPNet。

## 1. 输入与任务

| 项目 | 已确认内容 |
|---|---|
| 任务 | `OD`=司乘履约率，`O`=司机履约，`D`=乘客履约 |
| 总输入 | 一版配置为 343 维：143 维数值/类别 + 200 维序列 |
| 乘客序列 | 10 笔历史订单 × 每单 10 个特征 = 100 维 |
| 司机序列 | 10 笔历史订单 × 每单 10 个特征 = 100 维 |
| 序列形状 | 各自 reshape 为 `[B, 10, 10]` 后做 Positional Self-Attention |

数值块的已知划分：`n_sparse=10`、`n_dense=61`、`n_serial=35`、`n_nonserial=35`、`n_binary=1`、`n_poso=1`。`poso` 是“28 天内完单数”；但其在 PLE/PEP 的启用状态存在材料内冲突，须以 run 配置为准。

## 2. 数据流

~~~text
稀疏类别特征 ── Embed ───────────────────────────────┐
连续/连环派/非连环派特征 ── Scalar2Vec ────────────────┤
乘客 10×10 历史序列 ── Positional Self-Attention ───────┤
司机 10×10 历史序列 ── Positional Self-Attention ───────┤
连环派标志 x_binary ── EPNet gate / 最终场景选路 ────────┘
                           ↓
                  EPNet：输入层逐维 LHUC gate
                           ↓
      三个独立 PPNet：OD / O / D，每层逐维 LHUC gate
                           ↓
      6 个 tower（每任务 2 个场景 tower）→ 按 x_binary 选路
                           ↓
                       OD / O / D 履约预测
~~~

## 3. PEPNet 的明确接入位置

### 3.1 EPNet：场景级粗调

`x_dnn` 由连续与序列表示组成，`x_ep` 是场景先验（材料记为约 20 维）。EPNet 用 LHUC 生成与 `x_dnn` 同维、范围约为 `0–2` 的 gate，对底层输入逐维缩放：

$$
x_{ep} = x_{dnn} \odot g_{ep}(\operatorname{stopgrad}(x_{dnn}), x_{scene})
$$

它表达的是：连环派/非连环派等场景下，同一组连续和序列特征的重要性不同。

### 3.2 PPNet：任务级细调

OD、O、D 各有一个独立 PPNet，补充材料给出的主干隐藏层为 `[512, 512, 256, 128]`。PPNet 的 gate 输入是拉平后的司乘类别 Embedding；在每层 DNN 前生成同维 LHUC gate：

$$
h_{l+1}^{(t)} = f_l\left(h_l^{(t)} \odot g_l^{(t)}([\operatorname{stopgrad}(x_{ep}),x_{pp}])\right),\quad t\in\{OD,O,D\}
$$

### 3.3 6 tower 的场景路由

每个任务有两座场景 tower。以二值连环派标志 `b=x_binary` 选择对应输出：

$$
\hat y_t = b\cdot p_{t,1}+(1-b)\cdot p_{t,0}
$$

这不是 OneTrans 的 token-level 混合参数化，而是 PEPNet 多场景多任务下的任务/场景路由。

## 4. PLE 对照模型的已知改造

补充材料将 PLE 称为“线上 base 模型抽取”的架构来源。本项目离线抽取/简化该基座后，形成 `PLE base` 对照；它不是本文能够证明的线上 AUC 或线上效果。

PLE 序列版本的通路为：`Scalar2Vec/Embed → Positional Self-Attention → PLELayer（无 Gate）→ 15 个 Expert MLP → 6 tower`。原材料解释，旧 Gate 在连环派和非连环派下都几乎只激活同一共享专家，造成专家利用退化；因此该 baseline 将其移除。

这解释了为什么 PEPNet 和 PLE 不是只差一个“模型名称”：前者以 EP/PP 的 LHUC 逐层调节序列与连续表示，后者主要依赖共享/任务专家分工。

## 5. 与 OneTrans 的关系

| 方案 | 序列处理位置 | 主要交互方式 |
|---|---|---|
| PEPNet + PosSA（baseline） | 乘客/司机序列先独立编码 | 序列表示与静态特征在 PEPNet 中融合、门控 |
| PEPNet × OneTrans | 序列与静态特征共同 token 化 | Transformer 内统一进行序列内、跨序列、序列—静态交互 |

因此汇报时可说“以 PEPNet + PosSA 为 baseline，探索 OneTrans 统一交互”，但 `pep-seq-onetrans` 的精确 pp 仍应相对 `pep-seq` 表述，见 [[03-实验基线与对照口径]]。
