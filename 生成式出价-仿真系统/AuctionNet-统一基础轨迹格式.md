# AuctionNet 路线：从原始竞价日志到模型输入

## 1. 完整数据链路

C2、GAVE、GAS、GUIDE、QGA、SEGB，以及 TAR 的 Auto-Bidding 部分，基本都建立在 AuctionNet 或 AuctionNet-Sparse 数据上。

整体链路可以统一理解为：

```text
AuctionNet 原始竞价日志
  已划分为 48 个 timeStepIndex
  每个时间片包含很多次竞价机会
                │
                ├── 路线 1：使用代码从原始日志生成轨迹
                │            C2、GAVE 明确提供完整生成器
                │
                └── 路线 2：直接读取官方/预处理好的 trajectory CSV
                             GAS、GUIDE、QGA、SEGB、TAR 等主要走这条路线
                │
                ▼
时间片级基础轨迹
  state、action、reward、next_state、done
  budget、CPAConstraint、realAllCost 等
                │
                ▼
各模型自己的 loader 再加工
  归一化、切 episode、序列窗口、RTG、cost、CTG、score、扩散条件等
                │
                ▼
最终模型输入
```

最重要的区分是：

> 所有这些模型都有“轨迹读取并处理成模型输入”的代码；但不是每个仓库都有“从 AuctionNet 原始逐竞价日志生成 16 维轨迹”的代码。当前明确包含完整原始日志生成器的是 C2 和 GAVE，其他模型主要读取已经处理好的轨迹。

## 2. 第一层：AuctionNet 原始竞价日志

### 2.1 48 个时间片由 AuctionNet 给定

AuctionNet 已经把一个投放周期划分为 48 个时间片：

```text
timeStepIndex = 0, 1, 2, ..., 47
```

这不是模型根据数据量临时决定的。C2/GAVE 的生成器直接设置：

```python
timeStepIndexNum = 48
```

但是一个时间片并不是一条竞价记录。一个广告主在同一个时间片内通常会参与很多次竞价：

```text
广告主 A，timeStepIndex=7
├── 竞价机会 1
├── 竞价机会 2
├── 竞价机会 3
└── ...
```

后续需要把这些竞价记录聚合为一条时间片状态。

### 2.2 原始字段分组

根据当前仓库 C2/GAVE 生成器实际读取的字段，可以分成四组。

#### 2.2.1 广告主和投放配置

| 字段 | 含义 |
|---|---|
| `deliveryPeriodIndex` | 投放周期编号 |
| `advertiserNumber` | 广告主编号 |
| `advertiserCategoryIndex` | 广告主类别 |
| `budget` | 该周期的总预算 |
| `CPAConstraint` | CPA 约束 |

#### 2.2.2 时间信息

| 字段 | 含义 |
|---|---|
| `timeStepIndex` | 当前竞价记录属于第几个时间片，通常为 `0..47` |
| `isEnd` | 当前广告主轨迹是否提前结束 |

#### 2.2.3 预估和竞价信息

| 字段 | 含义 |
|---|---|
| `pValue` | 当前竞价机会的预估转化概率 |
| `pValueSigma` | 转化概率的不确定性；评估代码会用到，但不在当前 16 维 state 中 |
| `bid` | 历史策略给出的实际出价 |
| `leastWinningCost` | 赢得该次曝光需要的最低价格 |
| `xi` | AuctionNet 提供的辅助统计量 |

#### 2.2.4 竞价结果

| 字段 | 含义 |
|---|---|
| `isExposed` | 是否赢得竞价并获得曝光 |
| `conversionAction` | 是否发生真实转化 |
| `cost` | 实际消耗 |
| `remainingBudget` | 当前剩余预算 |

此时一行仍代表一次竞价机会，还不是 RL 中的一步。

## 3. 第二层：获得时间片级聚合轨迹

### 3.1 从原始日志自己生成

C2 和 GAVE 明确提供完整生成器。生成器先按照下面五个字段确定一条广告主投放轨迹：

```text
deliveryPeriodIndex
advertiserNumber
advertiserCategoryIndex
budget
CPAConstraint
```

然后在轨迹内部按照 `timeStepIndex` 聚合。

```text
逐竞价记录
    ↓ 按广告主、投放周期分组
广告主级投放记录
    ↓ 按 timeStepIndex 聚合
最多 48 行的时间片轨迹
```

### 3.2 直接读取官方或预处理好的轨迹 CSV

AuctionNet 数据下载中也可能直接提供 trajectory 数据。GAS、GUIDE、QGA、SEGB、TAR 等仓库主要假设用户已经准备好类似：

```text
trajectory_data.csv
training_data_all-rlData.csv
autoBidding_*_trajectory_data.csv
```

这些 CSV 已经包含 `state/action/reward`，所以模型不需要重新读取逐竞价日志，而是直接进入模型专用处理阶段。

两条路线最后应得到兼容的时间片级轨迹，但必须确认 state 的维度、顺序、reward 类型和 action 公式一致。

## 4. 第三层：构造统一的基础 RL 轨迹

### 4.1 state：通常是 16 维

C2/GAVE 的生成器明确构造以下 16 个特征；GAS、GUIDE、QGA、SEGB 的 loader 也声明 `state_dim=16` 并读取兼容轨迹。

| 下标 | 特征 | 构造方式 |
|---:|---|---|
| 0 | 剩余时间比例 | `(48 - timeStepIndex) / 48` |
| 1 | 剩余预算比例 | `remainingBudget / budget` |
| 2 | 历史平均 bid | 当前时间片之前所有时间片的平均 bid |
| 3 | 最近 3 片平均 bid | 当前片之前最近 3 个时间片的平均 bid |
| 4 | 历史平均最低赢价 | 历史 `leastWinningCost` 均值 |
| 5 | 历史平均 pValue | 历史 `pValue` 均值 |
| 6 | 历史平均转化 | 历史 `conversionAction` 均值 |
| 7 | 历史平均 xi | 历史 `xi` 均值 |
| 8 | 最近 3 片平均最低赢价 | 最近 3 片 `leastWinningCost` 均值 |
| 9 | 最近 3 片平均 pValue | 最近 3 片 `pValue` 均值 |
| 10 | 最近 3 片平均转化 | 最近 3 片 `conversionAction` 均值 |
| 11 | 最近 3 片平均 xi | 最近 3 片 `xi` 均值 |
| 12 | 当前时间片平均 pValue | 当前片内所有竞价机会的 `pValue` 均值 |
| 13 | 当前时间片流量数 | 当前片内竞价机会数量 |
| 14 | 最近 3 片流量数 | 当前片之前最近 3 片的竞价机会总数 |
| 15 | 历史累计流量数 | 当前片之前累计竞价机会数 |

可以把它简化理解为：

```text
16维state
├── 时间和预算：2维
├── 长期历史统计：6维
├── 最近三步统计：6维
└── 当前时间片统计：2维
```

第一时间片没有历史信息时，相关历史特征填 0。

需要注意：16 维是当前代码使用的公共特征方案，不是 AuctionNet 强制要求。聚合方法、历史窗口和附加特征都可以修改，但修改后需要重新生成数据并重新训练模型。

### 4.2 action：通常是 1 维

当前基础轨迹把时间片内的历史 bid 汇总成一个标量出价系数：

```text
action_t = sum(bid_i) / sum(pValue_i)
```

若 `sum(pValue_i) == 0`，action 设为 0。

它对应常见的自动出价形式：

```text
bid_i ≈ action_t × pValue_i
```

因此轨迹中的 action 不是单次竞价的 bid，而是整个时间片的策略系数。

### 4.3 reward：通常是 1 维

当前生成器同时提供两种奖励。

#### 4.3.1 稀疏真实转化奖励

```text
reward_t
= 当前时间片 isExposed == 1 的记录中
  conversionAction 的总和
```

它反映实际获得了多少次转化，但通常比较稀疏。

#### 4.3.2 连续期望转化奖励

```text
reward_continuous_t
= 当前时间片 isExposed == 1 的记录中
  pValue 的总和
```

它提供更密集的学习信号。模型应明确选择哪种 reward，因为这会影响 RTG、reward scale 和评价目标。

### 4.4 next_state 与 done

`next_state` 是同一广告主、同一投放周期中下一个时间片的 state：

```text
next_state_t = state_{t+1}
```

终止标记为：

```text
done_t = 1
若 timeStepIndex == 47 或 isEnd == 1
```

终止步的 `next_state` 通常为空。部分模型 loader 不直接信任 CSV 的 `next_state`，而是重新对 state 做 shift。

### 4.5 最终基础轨迹的一行

时间片级轨迹通常包含：

```text
state
action
reward
reward_continuous
next_state
done

timeStepIndex
budget
CPAConstraint
realAllCost
realAllConversion

deliveryPeriodIndex
advertiserNumber
advertiserCategoryIndex
```

其中最核心的标准 RL 部分是：

```text
(state_t, action_t, reward_t, next_state_t, done_t)
```

预算和 CPA 等字段用于构造约束、成本和评价得分。

## 5. 第四层：各模型再处理成最终输入

基础轨迹通常还不能直接送入模型。每个仓库的 loader 会继续做自己的处理。

| 模型 | 基础数据来源 | 模型专用处理 |
|---|---|---|
| C2 | 可从原始日志生成16维轨迹 | 序列切片、RTG、mask、预算/CPA约束 penalty |
| GAVE | 可从原始日志生成16维轨迹 | `K=20` 序列、RTG、约束得分 |
| GAS | 主要读取预处理轨迹 | 从预算变化推导 cost、CTG、score-to-go |
| GUIDE | 主要读取预处理轨迹 | DT序列、下一状态预测、逆动力学、Q transition |
| QGA | 主要读取预处理轨迹 | RTG、cost、CTG、score-to-go、double-Q数据 |
| SEGB | 主要读取预处理轨迹 | 48步状态轨迹、return条件、扩散状态生成、DT/critic数据 |
| TAR Auto-Bidding | 读取 AuctionNet-Sparse 轨迹 | 16维扩展为18维，48步增加终止状态变49步，生成pickle |

### 5.1 C2 和 GAVE

这两个仓库的数据链路最完整：

```text
period-*.csv
→ 16维时间片轨迹CSV
→ episode/序列窗口
→ 模型输入
```

### 5.2 GAS、GUIDE、QGA、SEGB

这些仓库主要从已处理好的 trajectory CSV 开始：

```text
trajectory_data.csv
→ 解析 state/action/reward
→ 切 episode
→ 构造 RTG、cost、constraint、mask 等
→ 模型输入
```

它们有“轨迹到模型输入”的代码，但没有完整重复 C2/GAVE 的原始日志聚合生成器。需要时可以复用 C2/GAVE 的生成逻辑。

### 5.3 TAR Auto-Bidding

TAR 在基础 16 维 state 后增加：

```text
剩余RTG / 整条轨迹总回报
上一时间片action
```

所以：

```text
基础轨迹：48 × 16
TAR输入： 49 × 18
```

第49步是额外终止状态，并为整条轨迹增加条件：

```text
condition = [总回报, 初始预算]
```

TAR Auto-Pacing 使用另一套仿真数据和5维状态，不属于这条 AuctionNet 16维基础轨迹链路。

## 6. 哪些是固定的，哪些可以修改

| 内容 | 来源或选择方 |
|---|---|
| 48个 `timeStepIndex` | AuctionNet 数据和任务协议 |
| 每条原始记录属于哪个时间片 | AuctionNet 数据 |
| budget、CPA、pValue、bid、曝光、成本等原始字段 | AuctionNet 数据 |
| 时间片内部使用均值、分位数还是其他聚合 | 数据构造选择 |
| 16维 state | C2/GAVE 等代码的公共特征方案 |
| 最近3个时间片 | 数据构造超参数 |
| action 的聚合公式 | 动作定义选择 |
| 稀疏或连续 reward | 训练目标选择 |
| 模型窗口长度 `K`、RTG、cost、CTG、mask | 各模型 loader 和超参数 |

理论上可以把48步进一步合并为24或12步，但必须从原始竞价记录重新聚合，不能只隔行抽样。还需要同步修改 `timeleft`、`done`、最大episode长度、位置编码、padding、Diffusion horizon和评估模拟器。

## 7. 推荐的统一复现方式

如果希望所有 AuctionNet 模型共用一套数据，建议把流程统一成：

```text
1. 保存原始 period-*.csv

2. 复用 C2/GAVE 生成器
   生成统一的 16维基础轨迹

3. 固定并记录
   state维度顺序
   action公式
   reward类型
   时间粒度
   数据版本

4. 分别交给各模型 loader
   生成 RTG、cost、CTG、score、扩散条件等

5. 模型训练与评估
```

这样可以明确区分：

```text
公共的数据构造差异
vs.
模型方法本身的差异
```

## 8. 当前仓库的数据与代码情况

- GAVE 带有 1 条 48 步样例轨迹，可用于检查格式，但不足以训练。
- C2/GAVE 提供原始日志到 16 维轨迹的完整生成器。
- GAS、GUIDE、QGA、SEGB 主要提供轨迹 loader 和模型专用加工代码。
- TAR Auto-Bidding 提供预处理轨迹到 TAR pickle 的转换脚本。
- 完整 AuctionNet / AuctionNet-Sparse 大数据需要另外下载。

## 9. 对应代码

- C2 原始日志生成器：`paper_repos/transformer/c2/bidding_train_env/train_data_generator/train_data_generator.py`
- GAVE 原始日志生成器：`paper_repos/transformer/gave/code/bidding_train_env/dataloader/rl_data_generator.py`
- GAVE 轨迹样例：`paper_repos/transformer/gave/data/trajectory/trajectory_data.csv`
- GAS loader：`paper_repos/transformer/gas/bidding_train_env/baseline/dt_baselines/utils.py`
- GUIDE loader：`paper_repos/transformer/guide/strategy_train_env/bidding_train_env/baseline/GUIDE/utils.py`
- QGA loader：`paper_repos/transformer/qga/strategy_train_env/bidding_train_env/baseline/QGA/utils.py`
- SEGB loader：`paper_repos/diffusion/segb/bidding_train_env/baseline/segb/dataset.py`
- TAR 转换：`paper_repos/transformer/tar/Auto-Bidding/scripts/data_processing.py`
