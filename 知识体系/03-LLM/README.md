---
type: 索引
topics: [LLM]
---

# LLM

先理解语言建模，再读训练、推理、适配，最后接偏好优化。

先修：[[知识体系/02-神经网络与Transformer/02-Attention：数学、信息流与复杂度|Attention原理]]、[[知识体系/02-神经网络与Transformer/04-位置编码与RoPE|位置编码与RoPE]]；第 06 章还需 [[知识体系/05-强化学习/03-策略梯度、Actor-Critic与GAE|策略梯度与GAE]]。

[[知识体系/README|回到统一知识体系]]

## 主线阅读

- [[知识体系/03-LLM/01-分词、自回归与语言建模|分词、自回归与语言建模]]
- [[知识体系/03-LLM/02-预训练：数据、优化与Scaling|预训练：数据、优化与 Scaling]]
- [[知识体系/03-LLM/03-推理：KVCache、FlashAttention与解码|推理：KV cache、FlashAttention 与解码]]
- [[知识体系/03-LLM/04-训练系统：显存、并行与量化|训练系统：显存、并行与量化]]
- [[知识体系/03-LLM/05-SFT、LoRA与任务适配|SFT、LoRA 与任务适配]]
- [[知识体系/03-LLM/06-偏好优化：DPO、PPO与GRPO|偏好优化：DPO、PPO 与 GRPO]]

## 理解到什么程度

- 能区分目标、参数化、数值表示和系统优化。
- 能从 KL 正则推导 DPO，并解释 PPO/GRPO 信号来源。
