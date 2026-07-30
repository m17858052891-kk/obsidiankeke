---
tags: [模型架构, 梯度, Batch, 梯度累积, FLOPs, 面试]
---

# Batch、梯度累积、参数量与 FLOPs

## 1. Batch 扩大 4 倍、走 1 个 step，等于原 Batch 走 4 个 step 吗？

不等价。大 batch 的一次更新使用同一参数 $\theta_t$ 上四倍样本的平均梯度：

$$g_{large}=\frac1{4B}\sum_{i=1}^{4B}\nabla_\theta\ell_i(\theta_t).$$

小 batch 连走四步时，第二、三、四步已在更新后的 $\theta_{t+1},\theta_{t+2},\theta_{t+3}$ 上计算梯度。Momentum/Adam 的一二阶矩、weight decay、学习率调度、Dropout mask 和数据顺序也会更新四次，因此优化轨迹不同。

## 2. 什么情况下梯度累积近似大 Batch？

将 $4$ 个 micro-batch 的 loss 除以 $4$，只在最后 `optimizer.step()` 一次：

```text
zero_grad
for micro_batch in 4 batches:
    (loss / 4).backward()
optimizer.step()
```

此时参数在四个 micro-batch 间不变，累积梯度近似大 batch 的平均梯度。仍有边界：BatchNorm 会看到不同小 batch 统计量；in-batch negative、跨样本 contrastive loss 和动态 loss scaling 也可能不同；混合精度下需正确处理梯度缩放。

## 3. 大 Batch 的收益与代价

- 收益：吞吐更高、梯度方差更小、便于硬件并行；
- 代价：显存更大、每 epoch step 数减少、可能需要调整学习率/warmup；过大 batch 有时泛化变差或落入不同优化区域。

因此“线性学习率放大”只是常见起点，不是定律；需用相同 token/sample 预算、相同训练时长和 OOT 指标比较。

## 4. Params、FLOPs、显存、延迟分别是什么？

| 指标 | 描述 | 典型例子 |
|---|---|---|
| Params | 可学习参数数量，影响模型/优化器状态存储 | 大 embedding 表参数很多 |
| FLOPs | 一次前向或训练的理论浮点运算量 | 长序列 attention 有 $O(L^2D)$ 计算 |
| Activation Memory | 为反向传播保存的中间表示 | 宽 FFN、长序列常很大 |
| Latency | 真实服务耗时 | 受访存、并行度、kernel、batch、网络影响 |

参数量大不等于 FLOPs 高：embedding 表可能很大却只是少量 lookup；attention 参数不多但序列很长时计算昂贵。FLOPs 也不等于延迟：稀疏 lookup、kernel launch、HBM 带宽、融合程度都可能成为瓶颈。

## 5. 面试回答

> 大 batch 一步不等于小 batch 四步，因为小 batch 每步都会更新参数和 Adam/Momentum 状态；只有不更新参数的梯度累积才近似等价。参数量回答“要存多少”，FLOPs 回答“理论上要算多少”，但线上延迟还要看 activation、访存和硬件利用率。比较模型时我会同时报参数、训练/推理 FLOPs、峰值显存、吞吐和 p99 延迟。
