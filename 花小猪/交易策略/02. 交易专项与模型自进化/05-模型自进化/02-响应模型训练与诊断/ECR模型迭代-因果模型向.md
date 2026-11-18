---
title: "ECR模型迭代-因果模型向"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2206140619069
cssclasses: ["strategy-body-note"]
---

# ECR模型迭代-因果模型向

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2206140619069)

**阅读定位**　[[#1 迭代方向|1 迭代方向]] · [[#2 数据口径|2 数据口径]] · [[#3 模型训练结果|3 模型训练结果]] · [[#4 分布距离偏差分析|4 分布距离偏差分析]] · [[#5  多分布Wasserstein距离计算调研|5  多分布Wasserstein距离计算调研]] · [[#6 实验结果|6 实验结果]]

## 1 迭代方向

- 背景：

	- 长期RCT数据，非观察数据建模

	- 多treatment，离散treatment

	- 存在前置券B，B的分布随时间发生分布偏移，导致ITE、ATE偏移

- 优化方向

	- 长期RCT中X不是混淆变量，是中介变量；因果图变成 T->X X->Y T->Y；

	- 多Treatment下的分布距离对齐（需数学证明误差上界）

	- 多Treatment的排序loss的优化

	- 考虑B的影响，X->B B->Y

	- 考虑B的分布偏移下，如何进行保守估计

## 2 数据口径

- 日期：2025.08.26-2025.09.08

- 抓手：基于联合决策V2链路的，特价盒子RCT

- treatment：100、97、94、91、88、85、82、79、76、73

- 代码路径：

	- /nfs/volume-661-1/chenjiaxi/compete_user/plat_torch

	- 在这个路径下改：/ofs/pltf-sub-and-pap/chenjiaxi/ecr_torch

- 环境：

	- source /ofs/pltf-sub-and-pap/DECR/online_test/pltf_mixer_v5_new_wodw_re_one_hot/2024-99-99_cat_sort/zuyao/miniconda3/bin/activate（torch版本不符）

	- conda activate cr_torch

	- source /nfs/volume-661-1/eddiezhang/anaconda3/bin/activate（可运行）

	- conda activate compete_pytorch

- 运行代码：python trainer.py

- 生成log路径代码nohup python -u trainer_PCA.py->log/plat_08260908_modify/0331_1330_plat_cfr_0002_01_01_bs_2048_f_128_128_128_t_64_32_16_e_20_reg_new_top_100_embd_lr2e-4_wd_1e-3_wbce_fenduan.log 2>&1 &

## 3 模型训练结果

黄色底色为上线模型

> [!example]- 完整数据表（5 行记录）
> | 模型 | epoch | batch_size | imbalance | t | ate | lr | aucc | qini | dini | ate_error | call_algo_mtaucc | call_random_mtaucc | qini | mtaucc | 值准 |
> | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
> | DRCFR+分段决策函数 <br>loss：wbce、imbalance、ate、t ce | 20 | 2048 | 0.0002 | 0.01 | 0.001 | 1e-4 | 0.465 | 0.2275 | 0.241 | 0.0037 | 0.5636 | 0.3629 | ![](9500a5bb181dd005-截屏2025-09-18下午2.41.56.png) | ![](8a81524874e6f48c-image.png) | ![](80ffcd58f5745acb-截屏2025-09-18下午2.43.59.png) |
> | 删除DRCFR中的混淆变量头，去除逆倾向加权 <br>loss：bce、imbalance、ate | 20 | 2048 | 0.0002 | 0.01 | 0.001 | 5e-4 | 0.4858 | 0.2468 | 0.2403 | 0.0068 | 0.5862 | 0.352 | | | |
> | CFR+双塔+分段函数 <br>loss：bce、imbalance、ate | 20 | 2048 | 0.0002 | / | 0.01 | 5e-4 | 0.4798 | 0.2488 | 0.2515 | 0.0089 | 0.5746 | 0.3534 | | | |
> | CFR+双塔+分段函数 <br>loss：bce、imbalance、ate | 20 | 2048 | 0.0002 | / | 0.001 | 2e-4 | 0.525 | 0.2321 | 0.2364 | 0.0047 | 0.601 | 0.3414 | ![](b13887f93676c354-截屏2026-03-2320.21.17.png) | ![](556b52e59e67fea3-截屏2026-03-2320.19.59.png) | |
> | CFR+双塔+分段函数 <br>loss：bce、imbalance、ate | 20 | 2048 | 0.0002 | / | 0.001 | 2e-4 | 0.5296 | 0.2488 | 0.241 | 0.0061 | 0.6174 | 0.3524 | ![](606d4ef3bf8474c7-截屏2026-05-06下午7.42.57.png) | ![](38f5bbe98d07994f-截屏2026-05-06下午7.41.45.png) | |


## 4 分布距离偏差分析

目的：将训练数据过模型之后，查看不同组的表征分布

### 4.1 分析方法介绍

**法一：PCA降维分析（舍）**

- 生成图地址：result/plat_08260908_distance/==0323_2030==\_100_plat_cfr_0002_01_01_bs_2048_f_128_128_128_t_64_32_16_e_20_reg_new_top_100_embd_lr2e-4_wd_1e-3_wbce_fenduan

- 用PCA降到2维之后观察，每一个epoch结束后都输出一张图--<u>看不出来明显偏差</u>。

> [!example]- PlainText 实现细节（109 行）
> ```PlainText
>     """
>     def plot_representation_pca(self, epoch):
>         self.model.eval()
>         all_phi = []
>         all_t = []
>
>         with torch.no_grad():
>             for (x_batch, t_batch), _ in self.test_dataloader:
>                 x_batch = x_batch.to(device)
>
>                 # 根据模型类型获取表征 phi / gamma
>                 if self.config['model']['net'] == 'drcfr':
>                     _, _, _, phi = self.model(x_batch)
>                 elif self.config['model']['net'] in ['cfr', 'bmmoe']:
>                     _, phi = self.model(x_batch)
>                 else:
>                     continue
>
>                 all_phi.append(phi.cpu().numpy())
>                 # 将 one-hot 的 t 转回类别索引用于上色
>                 t_idx = torch.argmax(t_batch, dim=1)
>                 all_t.append(t_idx.cpu().numpy())
>                 if len(np.concatenate(all_phi)) > 2000:
>                     break
>
>         phis = np.concatenate(all_phi, axis=0)
>         ts = np.concatenate(all_t, axis=0)
>
>         # PCA 降维
>         pca = PCA(n_components=2)
>         phis_2d = pca.fit_transform(phis)
>
>         # 绘图
>         plt.figure(figsize=(10, 8))
>         scatter = plt.scatter(phis_2d[:, 0], phis_2d[:, 1], c=ts, cmap='viridis', alpha=0.6, s=10)
>         plt.colorbar(scatter, label='Treatment Group (Discount)')
>         plt.title(f'Representation PCA at Epoch {epoch}')
>         plt.xlabel('PC1')
>         plt.ylabel('PC2')
>
>         # 保存图片
>         save_dir = os.path.join(self.config['train']['save_path'], self.config['train']['net_name'], 'plots')
>         os.makedirs(save_dir, exist_ok=True)
>         plt.savefig(os.path.join(save_dir, f'pca_epoch_{epoch}.png'))
>         plt.close()
>         print(f"Saved PCA plot for epoch {epoch} to {save_dir}")
>     """
>     #全样本下，每个组和100折的分布对比
>     def plot_representation_pca(self, epoch):
>         self.model.eval()
>         all_phi = []
>         all_t = []
>
>         # 1. 全样本收集 (移除样本数限制)
>         with torch.no_grad():
>             for (x_batch, t_batch), _ in self.test_dataloader:
>                 x_batch = x_batch.to(device)
>
>                 # 获取表征 phi
>                 if self.config['model']['net'] == 'drcfr':
>                     _, _, _, phi = self.model(x_batch)
>                 elif self.config['model']['net'] in ['cfr', 'bmmoe']:
>                     _, phi = self.model(x_batch)
>                 else:
>                     continue
>
>                 all_phi.append(phi.cpu().numpy())
>                 all_t.append(torch.argmax(t_batch, dim=1).cpu().numpy())
>
>         phis = np.concatenate(all_phi, axis=0)
>         ts = np.concatenate(all_t, axis=0)
>
>         # 2. 对全量表征进行 PCA 降维 (统一坐标系)
>         pca = PCA(n_components=2)
>         phis_2d = pca.fit_transform(phis)
>
>         # 3. 确定对照组索引 (假设 100 折对应的索引是 0，请根据实际 discount_list 调整)
>         # 如果你的 treat 列表是 [9, 8, ..., 0]，那么 0 通常代表 100 折
>         control_idx = 0 
>         unique_treats = np.unique(ts)
>         treatment_groups = [t for t in unique_treats if t != control_idx]
>
>         # 4. 循环绘制每个组与对照组的对比图
>         save_dir = os.path.join(self.config['train']['save_path'], self.config['train']['net_name'], f'epoch_{epoch}_plots')
>         os.makedirs(save_dir, exist_ok=True)
>
>         for treat in treatment_groups:
>             plt.figure(figsize=(8, 6))
>
>             # 提取对照组数据
>             idx_c = (ts == control_idx)
>             # 提取当前实验组数据
>             idx_t = (ts == treat)
>
>             # 绘制背景（对照组）
>             plt.scatter(phis_2d[idx_c, 0], phis_2d[idx_c, 1], color='gray', label='Control (100%)', alpha=0.3, s=10)
>             # 绘制前景（实验组）
>             plt.scatter(phis_2d[idx_t, 0], phis_2d[idx_t, 1], color='red', label=f'Treat {treat}', alpha=0.6, s=10)
>
>             plt.legend()
>             plt.title(f'Distribution Comparison: Group {treat} vs Control (Epoch {epoch})')
>             plt.xlabel('PC1')
>             plt.ylabel('PC2')
>
>             plt.savefig(os.path.join(save_dir, f'comp_treat_{treat}_vs_control.png'))
>             plt.close()
>
>         print(f"Epoch {epoch}: Saved {len(treatment_groups)} comparison plots to {save_dir}")
>
> ```


**法二：LDA线性判别分析**

- 生成图地址：result/plat_08260908_distance/==0325_1110==\_100_plat_cfr_0002_01_01_bs_2048_f_128_128_128_t_64_32_16_e_20_reg_new_top_100_embd_lr2e-4_wd_1e-3_wbce_fenduan

- 有监督降维方法，主动寻找能最大化“类间距离”并最小化“类内方差”的投影方向。

> [!example]- PlainText 实现细节（33 行）
> ```PlainText
> def plot_representation_lda(self, epoch):
>         self.model.eval()
>         all_phi, all_t = [], []
>
>         with torch.no_grad():
>             for (x_batch, t_batch), _ in self.test_dataloader:
>                 x_batch = x_batch.to(device)
>                 # 提取表征 (适配 CFR/DRCFR)
>                 res = self.model(x_batch)
>                 phi = res[-1] if self.config['model']['net'] in ['cfr', 'bmmoe', 'drcfr'] else res
>
>                 all_phi.append(phi.cpu().numpy())
>                 all_t.append(torch.argmax(t_batch, dim=1).cpu().numpy())
>
>         phis = np.concatenate(all_phi, axis=0)
>         ts = np.concatenate(all_t, axis=0)
>
>         # LDA 降维 (注意：LDA 最多降到 类别数-1 维)
>         lda = LDA(n_components=2)
>         try:
>             phis_2d = lda.fit_transform(phis, ts)
>
>             plt.figure(figsize=(10, 8))
>             scatter = plt.scatter(phis_2d[:, 0], phis_2d[:, 1], c=ts, cmap='tab10', alpha=0.6, s=10)
>             plt.colorbar(scatter, label='Treatment Group')
>             plt.title(f'Representation LDA at Epoch {epoch}')
>
>             save_dir = os.path.join(self.config['train']['save_path'], self.config['train']['net_name'], 'lda_plots')
>             os.makedirs(save_dir, exist_ok=True)
>             plt.savefig(os.path.join(save_dir, f'lda_epoch_{epoch}.png'))
>             plt.close()
>         except Exception as e:
>             print(f"LDA failed (possibly not enough classes): {e}")
> ```


**法三：Wasserstein距离热力图分析（最好）**

- 生成图地址：result/plat_08260908_distance/==0325_1330==\_100_plat_cfr_0002_01_01_bs_2048_f_128_128_128_t_64_32_16_e_20_reg_new_top_100_embd_lr2e-4_wd_1e-3_wbce_fenduan

- 直接量化不同组表征分布之间的“推土机距离”，比肉眼看散点图更精确。

> [!example]- PlainText 实现细节（37 行）
> ```PlainText
> def plot_dist_heatmap(self, epoch):
>         self.model.eval()
>         group_data = defaultdict(list)
>
>         with torch.no_grad():
>             for (x_batch, t_batch), _ in self.test_dataloader:
>                 x_batch = x_batch.to(device)
>                 res = self.model(x_batch)
>                 phi = res[-1]
>                 ts = torch.argmax(t_batch, dim=1).cpu().numpy()
>                 phi_np = phi.cpu().numpy()
>
>                 for i, t_val in enumerate(ts):
>                     group_data[t_val].append(phi_np[i])
>
>         # 按折扣组排序 (如 100, 95, 90...)
>         sorted_groups = sorted(group_data.keys())
>         n = len(sorted_groups)
>         matrix = np.zeros((n, n))
>
>         # 计算组间平均表征的欧式距离 (作为 Wass 距离的直观近似)
>         for i, g_i in enumerate(sorted_groups):
>             for j, g_j in enumerate(sorted_groups):
>                 if i != j:
>                     mu_i = np.mean(group_data[g_i], axis=0)
>                     mu_j = np.mean(group_data[g_j], axis=0)
>                     matrix[i, j] = np.linalg.norm(mu_i - mu_j)
>
>         plt.figure(figsize=(12, 10))
>         sns.heatmap(matrix, annot=True, fmt=".2f", cmap='YlGnBu',
>                     xticklabels=sorted_groups, yticklabels=sorted_groups)
>         plt.title(f'Inter-group Representation Distance Heatmap - Epoch {epoch}')
>
>         save_path = os.path.join(self.config['train']['save_path'], self.config['train']['net_name'], 'heatmaps')
>         os.makedirs(save_path, exist_ok=True)
>         plt.savefig(os.path.join(save_path, f'heatmap_epoch_{epoch}.png'))
>         plt.close()
> ```


### 4.2 分析实验结果

| **分析方法** | **epoch 0 结果** | **epoch 19 结果** | **实验结论** |
| :---: | :---: | :---: | :---: |
| PCA | ![](460acd2f3b856de8-pca_epoch_0.png) | ![](a91d84493e0ca051-pca_epoch_19.png) | |
| LDA | ![](cc6ea25a08a49b21-lda_epoch_0.png) | ![](fc25fc25b5ee3bb9-lda_epoch_19.png) | - **Epoch 0 ** <br><br>	- 存在一超多强的分离态 <br><br>	- 4 在下方形成了一个完全独立的“孤岛”，坐标在 (-30, 0) 附近。 <br><br>- **Epoch 19 ** <br><br>	- 实现了**深度混淆**。 <br><br>	- **关键点：**4 已经进入中央大群落 <br><br>	- **坐标轴变化：** Y 轴量级从 (-40, 10) 变为了 (-50, 40)，范围扩大，但点阵的聚拢度更高。 <br> |
| Wasserstein距离热力图 | ![](a07ed68231843896-heatmap_epoch_0.png) | ![](dae3d5a851cf7664-heatmap_epoch_19.png) | - **Epoch 0 ** <br><br>	- 存在极其严重的**选择偏倚** <br><br>	- **4 存在孤立性：**4 与其他所有组的距离均在 **0.46 - 0.63** 之间，说明 4 的分布特征与其他折扣组完全不同。 <br><br>- **Epoch 19 ** <br><br>	- 表征距离大幅压缩，**对齐效果显著**。 <br><br>	- **数值量级跨越：** 全局距离从**0.60**压缩到了**0.06**。 <br><br>	- **残留偏倚：**模型仍然高估了2、3、5-9之间的分布距离，低估了4 vs 剩余的分布距离 <br> |

## 5  多分布Wasserstein距离计算调研

两个概率分布的Wasserstein距离计算方法+例子：<https://zhuanlan.zhihu.com/p/353418080>

### 5.1 Wasserstein Barycenters-2011

- 数学定义：给定$$N$$ 个分布$$\mu_1, \mu_2, \dots, \mu_N$$以及对应的权重$$w_i$$（满足$$\sum w_i = 1$$），Wasserstein 重心$$\mu^*$$定义为：

$$\mu^* = \arg\min_\nu \sum_{i=1}^N w_i \mathcal{W}_2^2(\mu,P_i)$$$$\mathcal{W}_2$$ 代表二阶 Wasserstein 距离

- 直观理解：求一组数字的平均值，就是找一个点，让它到所有数字的欧氏距离之和最小。Wasserstein 重心就是概率分布空间里的“平均值”。通过计算各个分布到这个重心的总代价，我们就能间接衡量这$$N$$个分布的整体发散程度。

论文：[wass重心.pdf](bc09ad36091d7eb7-wass重心.pdf)

- 实现逻辑：基于熵正则化的迭代法 (Sinkhorn)：通过给最优传输问题添加一个熵正则化项$$\epsilon H(\pi)$$，可以将原本的线性规划问题转变为一个简单的矩阵迭代问题（Sinkhorn 迭代）。

- 代码逻辑：

**固定支撑点**：预设重心坐标（通常是一个网格或**随机点**）-代码中若使用randn会出现loss nan的情况，故初始点不能与分布离得太远。

**交替更新**：使用**Iterative Bregman** 投影算法。

		- 计算每个$$P_i$$ 到当前估计重心$$\mu$$ 的传输矩阵。

		- 通过对传输投影进行加权几何平均，更新$$\mu$$的权重。

		- 重复投影直至收敛。

- 代码实现方法：

	- 定义Cost矩阵：计算重心支撑点坐标$$X$$ 与各treatment支撑点坐标$$Y_i$$ 之间的距离矩阵。

$$C_{ik} = \|x_i - y_k\|^2$$

	- 计算Kernel传输矩阵：引入正则化参数$$\epsilon$$(目的是控制平滑度），计算 Gibbs 核：

$$K = \exp(-C / \epsilon)$$

	- Sinkhorn 循环迭代：对于每一个分布$$P_i$$，维护一个对偶变量向量$$v_i$$。在每一轮迭代中：

	1. 计算投影$$a_i = K (v_i \odot P_i)$$($$\odot$$ 表示逐元素乘法）。

	2. **更新重心权**$$\mathbf{a}_{bar}$$是所有投影的加权几何平均$$\mathbf{a}_{bar} = \exp \left( \sum_{i=1}^n w_i \log(a_i) \right)$$

	3. 更新对偶变量$$v_i = \mathbf{a}_{bar} / (K^T u_i)$$（其中$$u_i$$是与$$P_i$$相关的辅助变量）。

	- 得出多分布距离：当重心$$\mu^*$$ 收敛后，**多分布的 Wasserstein 距离**即为：$$D(P_1, \dots, P_n) = \sum_{i=1}^n w_i W_{2,\epsilon}^2(\mu^*, P_i)$$

### 5.2 多样本最大均值差异 (Multi-Sample MMD)-2006

计算逻辑：将数据通过核函数$$\phi(\cdot)$$ 映射到高维的再生核希尔伯特空间(RKHS），计算两个分布在该空间中**均值点**的欧式距离。

计算公式：$$MMD^2(P, Q) = \left\| E_{x \sim P}[\phi(x)] - E_{y \sim Q}[\phi(y)] \right\|^2_{H}$$

展开为核函数$$k(x, y) = \langle \phi(x), \phi(y) \rangle$$形式:$$MMD^2(P, Q) = E_{x,x'} [k(x, x')] + E_{y,y'} [k(y, y')] - 2E_{x,y} [k(x, y)]$$

论文：[MMD.pdf](643aab2c55c4215d-MMD.pdf)

### 5.3 Sliced Wasserstein Distance (SWD)-2015

- **计算逻辑**：将高维分布投影到一系列一维直线（切片）上。由于一维分布的 Wasserstein 距离有解析解（仅需对样本排序），因此计算速度极快。

- **计算公式**：$$SW^2(P, Q) = \int_{S^{d-1}} W_2^2(P_\theta, Q_\theta) d\theta$$

其中：

		- $$S^{d-1}$$ 是单位超球面。

		- $$P_\theta, Q_\theta$$ 是原分布在方向向量$$\theta$$上的投影。

		- 实际计算中，通常使用**蒙特卡洛积分**抽取$$L$$个方向$$SW^2(P, Q) \approx \frac{1}{L} \sum_{l=1}^{L} W_2^2(P_{\theta_l}, Q_{\theta_l})$$。

- 论文：[SWD.pdf](bec2fd6d446e03e2-SWD.pdf)

- 代码逻辑：

	- 采样投影方向：生成$$L$$个（eg:64）随机方向$$\theta_l$$，并保证其在单位超球面上（即长度为 1）。

	- 高维到一维投影：$$\mathcal{R}_{\theta_l} X$$利用矩阵乘法，将高维特征投影到$$L$$ 这个一维方向上。

	- 排序 ：$$F^{-1}(z)$$ 在离散数据上的体现，对投影后的一维数据分别进行排序。

	- 样本量不对齐时进行插值：不同组别在同一个 Batch 内的样本数量往往不同，即排序后的数组长度不一样，无法直接相减。为了在数学上对齐经验分布函数，需要将较短的序列“拉长”（或将两者都拉伸到相同的尺寸），通常通过线性插值实现。

	- 计算$$SW^2(P, Q)$$ 距离并求期望：计算排序且对齐后对应位置元素的差值，最后求均值，完成蒙特卡洛积分近似。

## 6 实验结果

### 6.1 Wasserstein Barycenters实验结果

问题定位：相比于原分布距离度量方法，wasserstein barycenter方法的分布距离度量值**偏小**，故相同的loss权重下，重心方法在20个epoch后分布**更不平衡**。

问题原因：

- **聚合方式的不同**：原分布距离度量方法是将累加和作为loss中的imbalance，计算了 9 个treatment到control组的绝对距离并直接相加。而重心方法是求期望，公式中将样本占比作为权重，本质上是所有组别到重心的**加权平均距离**。显然，平均值小于累加和。

- **重心的几何特性**：重心是空间中距离所有点加权距离最小的点。各个分布走到重心的距离，必然小于它们走到空间边缘（control组）的距离。

问题解决方法尝试：

- 增大imbalance在loss中的权重，原权重0.0002，分别增大5、10倍进行尝试，观察评估指标：

> [!example]- 完整对照数据（已展开分组表头）
> | 权重 <br> | 超参设置 <br> | 模型结果 <br> · aucc⬆️ <br> | 模型结果 <br> · qini⬆️ <br> | 模型结果 <br> · dini⬆️ <br> | 模型结果 <br> · ate_error⬇️ <br> | 模型结果 <br> · call_algo_mtaucc⬆️ <br> | 模型结果 <br> · call_random_mtaucc <br> | epoch19热力图 <br> |
> | --- | --- | --- | --- | --- | --- | --- | --- | --- |
> | **对照:**0.0002 <br>旧分布距离度量方法 <br> | <br> | 0.525 <br> | 0.2321 <br> | 0.2364 <br> | 0.0047 <br> | 0.601 <br> | 0.3414 <br> | <br> |
> | **对照:**0.0002 <br>wasserstein barycenter方法 <br> | reg=0.5 <br> | 0.489   <br> | 0.2264  <br> | 0.2321 <br> | 0.005  <br> | 0.56  <br> | 0.3542 <br> | <br> |
> | 0.002 迭代5次找到重心0403_1530 <br> | reg=0.5 <br> | 0.482 <br> | 0.2469 <br> | 0.2456  <br> | 0.005 <br> | 0.5823  <br> | 0.3451 <br> | ![](cf6b069ec2261efb-heatmap_epoch_19.png) <br> |
> | 0.002 迭代2次找到重心0407_1100 <br> | reg=0.5 <br> | 0.478 <br> | 0.2437  <br> | 0.2339  <br> | 0.0082 <br> | 0.5859  <br> | 0.3442 <br> | ![](a59acffe02c18cb0-heatmap_epoch_19.png) <br> |
> | 0.002 迭代2次找到重心0407_1600_imb_0.002 <br> | reg=0.1 <br>batchsize=1024 <br> | 0.5342   <br> | 0.2547  <br> | 0.2558 <br> | 0.0062  <br> | 0.6109  <br> | 0.3577 <br> | ![](37bc1fc0c1357a37-heatmap_epoch_19.png) <br> |
> | 0.002 迭代2次找到重心0408_1415_2048_imb_0.002 <br> | reg=0.1 <br>batchsize=2048 <br> | 0.4879    <br> | 0.2386  <br> | 0.2438 <br> | 0.0047  <br> | 0.5533 <br> | 0.3592 <br> | ![](9b32b3a42f2aca5c-heatmap_epoch_19.png) <br> |
> | 0.003 迭代2次找到重心0408_1515_imb_0.003 <br> | reg=0.1 <br>batchsize=1024 <br> | 0.4626   <br> | 0.2434  <br> | 0.2461  <br> | 0.0051  <br> | 0.558 <br> | 0.358 <br> | ![](f895f297d979d8ba-heatmap_epoch_19.png) <br> |
> | 0.005 迭代2次找到重心0407_1600_imb_0.005 <br> | reg=0.1 <br> | 0.4498  <br> | 0.2397  <br> | 0.242  <br> | 0.0052  <br> | 0.5436  <br> | 0.353 <br> | ![](5ed115dfa6d0eb69-heatmap_epoch_19.png) <br> |



结论：从运行时间来看，迭代两次找到重心能大大节省运行时间；从reg设置来看，reg=0.1时相较于0.5效果更优；loss权重增大10倍到0.002效果最优；batchsize相较于原版需要降低到1024,效果最优。

### 6.2 Sliced Wasserstein Distance (SWD)实验结果

> [!example]- 完整对照数据（已展开分组表头）
> | 权重 <br> | 超参设置 <br> | 模型结果 <br> · aucc⬆️ <br> | 模型结果 <br> · qini⬆️ <br> | 模型结果 <br> · dini⬆️ <br> | 模型结果 <br> · ate_error⬇️ <br> | 模型结果 <br> · call_algo_mtaucc⬆️ <br> | 模型结果 <br> · call_random_mtaucc <br> | epoch19热力图 <br> |
> | --- | --- | --- | --- | --- | --- | --- | --- | --- |
> | **对照:**0.0002 <br>旧分布距离度量方法 <br> | <br> | 0.525 <br> | 0.2321 <br> | 0.2364 <br> | 0.0047 <br> | 0.601 <br> | 0.3414 <br> | <br> |
> | **对照:**0.002 迭代2次找到重心 <br>wasserstein barycenter方法0407_1400 <br> | reg=0.1 <br>batchsize=1024 <br> | 0.5342   <br> | 0.2547  <br> | 0.2558 <br> | 0.0062  <br> | 0.6109  <br> | 0.3577 <br> | ![](37bc1fc0c1357a37-heatmap_epoch_19.png) <br> |
> | 0.01 <br>0407_1500_swd_imb_0.01 <br> | swd_projections=64 <br> | 0.5045  <br> | 0.2461  <br> | 0.2487  <br> | 0.0052  <br> | 0.5628  <br> | 0.3511 <br> | ![](c0091935157309bd-heatmap_epoch_19.png) <br> |
> | 0.02 <br>0407_1550_swd_imb_0.02 <br> | swd_projections=64 <br>batchsize=1024 <br> | 0.5122   <br> | 0.243  <br> | 0.2472 <br> | 0.0049  <br> | 0.5832  <br> | 0.3357 <br> | ![](110acecaf765def6-heatmap_epoch_19.png) <br> |
> | 0.02 <br>0410_1730_128_1024_imb_0.02 <br> | swd_projections=128 <br>batchsize=1024 <br> | 0.5043    <br> | 0.2309  <br> | 0.2355 <br> | 0.0056 <br> | 0.5723  <br> | 0.3509 <br> | ![](a918b84b60e227e3-heatmap_epoch_19.png) <br> |
> | 0.02 <br>0408_1200_2048_swd_imb_0.02 <br> | swd_projections=64 <br>batchsize=2048 <br> | 0.5279   <br> | 0.2322  <br> | 0.2424  <br> | 0.0049  <br> | 0.596 <br> | 0.3407 <br> | ![](c5acbb908c6e398f-heatmap_epoch_19.png) <br> |
> | 0.02 <br>0410_1550_128_swd_imb_0.02 <br> | swd_projections=128 <br>batchsize=2048 <br> | 0.5181   <br> | 0.2421  <br> | 0.2484  <br> | 0.0051 <br> | 0.5811  <br> | 0.3575 <br> | ![](c904a547a1345dfe-heatmap_epoch_19.png) <br> |
> | 0.02 <br>0409_1720_4096_swd_imb_0.02 <br> | swd_projections=64 <br>batchsize=4096 <br> | 0.4699  <br> | 0.2248  <br> | 0.236  <br> | 0.0046  <br> | 0.5314  <br> | 0.3468 <br> | ![](56928d73cea8ce21-heatmap_epoch_19.png) <br> |
> | 0.03 <br>0407_1650_swd_imb_0.03 <br> | swd_projections=64 <br>batchsize=1024 <br> | 0.4838   <br> | 0.2467  <br> | 0.2534  <br> | 0.0103  <br> | 0.5642 <br> | 0.3449 <br> | ![](9d6e03d554b0ea6d-heatmap_epoch_19.png) <br> |
> | 0.03 <br>0407_2015_2048_swd_imb_0.03 <br> | swd_projections=64 <br>batchsize=2048 <br> | 0.4911   <br> | 0.2322  <br> | 0.2424 <br> | 0.0109  <br> | 0.5643  <br> | 0.3474 <br> | ![](16a75cfbfbccbac5-heatmap_epoch_19.png) <br> |
> | 0.1 <br>0408_1700_swd_imb_0.1 <br> | swd_projections=64 <br>batchsize=1024 <br> | 0.4707  <br> | 0.2385  <br> | 0.2439  <br> | 0.005  <br> | 0.5588  <br> | 0.3391 <br> | ![](b38d19fb9643d145-heatmap_epoch_19.png) <br> |



结论：时间上来看，SWD方法运行速度相较于重心方法大大提升；投影点数量从64增加至128，结果并未提升；batchsize从1024增大至2048，效果更优，继续增大至4096后，效果变差；权重0.02最优，权重继续增大后会导致==过拟合对齐损失，损害主任务。==
