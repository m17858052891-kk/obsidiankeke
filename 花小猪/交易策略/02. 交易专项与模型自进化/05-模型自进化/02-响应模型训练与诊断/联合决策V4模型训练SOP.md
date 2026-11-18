---
title: "联合决策V4模型训练SOP"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2209092410239
cssclasses: ["strategy-body-note"]
---

# 联合决策V4模型训练SOP

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2209092410239)

## 1 仓库与luban机器

代码仓库：<https://git.xiaojukeji.com/bwh_stg/union_v4_bcr>

luban机器（密码）：10.191.156.163（RBdgGzKr ）、10.191.84.190 （ZGlzinG1）

luban本地路径：`/ofs/pltf-sub-and-pap/chenjiaxi/bcr/`

- Python 环境：

```PlainText
/ofs/pltf-sub-and-pap/DECR/online_test/pltf_mixer_v5_new_wodw_re_one_hot/2024-99-99_cat_sort/zuyao/miniconda3/envs/cr_torch/bin/python
```

注意：163机器没有HDFS环境，无法从远端下载数据，190机器有HDFS环境，可从该机器下载远端数据。163有两台GPU，可通过--gpu 0/1设置使用。

## 2 训练数据获取

### 2.1 数据来源

- 数梦任务：<https://studio.data.didichuxing.com/batch?projectId=1143&taskId=65393448>

- HDFS 根目录：

```PlainText
hdfs://DClusterNmg5/user/prod_kflower_strategy/kflower_strategy/hive/kflower_strategy/plft_v4_training_sample
```

- 鲁班落盘目录：

```PlainText
/ofs/pltf-sub-and-pap/chenjiaxi/bcr/datasets/train/dt=YYYY-MM-DD/
```

数梦任务产出是按日期分区的 ORC 文件，文件名为 `part-*`。

### 2.2 下载 ORC 分区

完整下载 07-08～07-21：

```Bash
HDFS_ROOT="hdfs://DClusterNmg5/user/prod_kflower_strategy/kflower_strategy/hive/kflower_strategy/plft_v4_training_sample"
LOCAL_ROOT="/ofs/pltf-sub-and-pap/chenjiaxi/bcr/datasets/train"

for day in $(seq -w 8 21); do
  dt="2026-07-$day"
  mkdir -p "$LOCAL_ROOT/dt=$dt"
  hdfs dfs -get -f "$HDFS_ROOT/dt=$dt/part-*" "$LOCAL_ROOT/dt=$dt/"
done
```

如果出现：

```PlainText
zsh: command not found: hdfs
```

说明当前容器没有安装或没有配置 HDFS 环境，切换到190机器。

### 2.3 下载验收

以 07-08 为例：

```Bash
hdfs dfs -count -h "$HDFS_ROOT/dt=2026-07-08"
du -sh "$LOCAL_ROOT/dt=2026-07-08"
find "$LOCAL_ROOT/dt=2026-07-08" -maxdepth 1 -type f | wc -l
find "$LOCAL_ROOT/dt=2026-07-08" -maxdepth 1 -type f | sed -n '1,20p'
```

已验证的 07-08 数据：

- HDFS：15 个文件，约 3.3G。

- 鲁班 OFS：15 个文件，约 3.4G。

文件数量应一致；HDFS 与本地显示的数据量可能因统计口径略有差异。

## 3 数据预处理：ORC 转 Parquet

数据预处理会创建四个文件：

rct_train.parquet：训练分区的RCT数据

obs_train.parquet：训练分区的OBS数据

rct_test.parquet：测试分区的RCT数据

rct_train_stats.pt：训练分区的RCT数据中序列特征、非序列特征的均值和方差

### 3.1 两天数据：

两天 small 数据用于测试（训练分区：07-08，测试分区：07-09）

运行下述代码处理两天数据，并保存在datasets/preprocess_small：

```bash
python3 dataloader/preprocess.py --dataset small
```

若使用该数据进行训练，将 `config/v4_mmoe_esmm.json` 中三项路径设置为：

```json
{
  "rct_train_path": "datasets/preprocess_small/rct_train.parquet",
  "rct_test_path": "datasets/preprocess_small/rct_test.parquet",
  "statistics_path": "datasets/preprocess_small/rct_train_stats.pt"
}
```

### 3.2 两周数据：

完整两周数据用于正式训练：（训练分区：07-08～07-14，测试分区：07-15～07-21）

运行下述代码处理两周数据，并保存在datasets/preprocess：：

```bash
python3 dataloader/preprocess.py --dataset full
```

若使用该数据进行训练，将配置中的三项路径设置为：

```json
{
  "rct_train_path": "datasets/preprocess/rct_train.parquet",
  "rct_test_path": "datasets/preprocess/rct_test.parquet",
  "statistics_path": "datasets/preprocess/rct_train_stats.pt"
}
```

## 4  模型训练

### 4.1 启动训练

推荐在 screen 中运行：

```bash
screen -S v4_train
python trainer.py --gpu 0
```

训练启动后，按 `Ctrl+A`，再按 `D`，退出 screen。断开 SSH 后训练仍会继续。

重新进入训练窗口：

```bash
screen -ls
screen -r v4_train
```

### 4.2 结果保存

训练开始后会自动创建独立结果目录：

```text
results/v4_mmoe_esmm/
└── bs{batch_size}_ep{epochs}_lr{lr}_wd{weight_decay}_bcr{权重}_ecr{权重}_dsar{权重}_finish_category{权重}_gmv{权重}_{时间戳}/
```

当前配置生成的目录名称类似：

```text
results/v4_mmoe_esmm/bs2048_ep5_lr2e-4_wd1e-3_bcr1_ecr1_dsar1_finish_category1_gmv0.1_YYYYMMDD_HHMMSS_微秒/
```

单次训练目录包含：

```text
<run_dir>/
├── model.pth
├── train.log
├── train.png
├── results.json
└── uplift/
    ├── mtaucc_curve.png
    ├── mtaucc_curve_cost_rate.png
    ├── mtaupc_uabox_*_curve.png
    └── report.pdf
```

各文件保存内容：

- `model.pth`：训练总 loss 最低 epoch 的 checkpoint，包含最佳 epoch、最佳 loss、训练配置、该 epoch 的测试指标、模型参数和优化器状态。 

- `train.log`：本次训练的设备、随机种子、数据量、训练参数、每个 batch 的总 loss 与五项子 loss、每个 epoch 的汇总 loss 和测试指标、最佳 epoch、Uplift 指标、输出路径及总耗时。 

- `train.png`：各 epoch 的训练 loss、BCR、ECR、CR、DSAR、完单品类和 GMV 指标曲线。 

- `results.json`：本次训练的结构化结果，包含模型路径、训练/测试行数、设备、开始时间、耗时、最佳 epoch、最佳 loss、最佳 epoch 的常规测试指标及 Uplift 指标。 

- `uplift/mtaucc_curve.png`：Model 与 Random 的 Cost-Finish 曲线。 

- `uplift/mtaucc_curve_cost_rate.png`：Model 与 Random 的 C 补率-Finish 曲线。 

- `uplift/mtaupc_uabox_*_curve.png`：不同特价盒子折扣下的 P 投入-Finish 曲线。 

- `uplift/report.pdf`：本次 Uplift 评估的汇总报告。

所有训练运行还会向项目级汇总文件追加一行：

```text
results/summary.csv
```

`summary.csv` 保存模型绝对路径、BCR AUC/ACC、MTAUCC、MTAUPC 和 BR-DC，便于比较多次实验。
