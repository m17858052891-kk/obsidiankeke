---
title: "01 base_DSAR和POSO_DASR效率or效果对比"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2204463182826
cssclasses: ["strategy-body-note"]
---

# 01 base_DSAR和POSO_DASR效率or效果对比

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2204463182826)

先看数据对齐、验证指标、运行结果与对比分析；模型定义和处理代码按需展开。原文使用的特征维度、训练数据量和日期均保留。

**阅读定位**　[[#1.1.3 验证指标、对比维度|1.1.3 验证指标、对比维度]] · [[#1.1.4 运行结果|1.1.4 运行结果]] · [[#1.1.5 对比分析|1.1.5 对比分析]]

## 1.1 基于eve线上数据字段的模型效果对比

**datetime**：20250521

用先前留存的模型和数据来测试base_DSAR和POSO_DSAR两个模型的效率/效果情况

目前所用的字段是eve环境上的base_model的**41维**特征

### 1.1.1 模型准备

通过查看上一版本的训练日志，得到如下**POSO_DSAR模型代码**

> [!example]- Python 实现细节（448 行）
> ```Python
> import torch
> from torch import nn
> from functools import partial
> import torch.nn as nn
> import torch.nn.functional as F
> import random
> import math
>
> random.seed(42)
> torch.manual_seed(42)
> # 如果使用 CUDA
> if torch.cuda.is_available():
>     torch.cuda.manual_seed_all(42)
>
>
> # poso attention  with multi-head
> class SelfAttentionLayer(nn.Module):
>     def __init__(self, feature_size, dropout_rate=0.1, n_head=2):
>         super(SelfAttentionLayer, self).__init__()
>         self.feature_size = feature_size
>
>         # 考虑attention 头数
>         self.n_head = n_head
>         self.w_combine = nn.Linear(feature_size, feature_size)
>         # Linear transformations for Q, K, V from the same source
>         self.key = nn.Linear(feature_size, feature_size)
>         self.query = nn.Linear(feature_size, feature_size)
>         self.value = nn.Linear(feature_size, feature_size)
>         self.dropout = nn.Dropout(dropout_rate)
>
>         self.gate_k = nn.Sequential(
>             nn.Linear(1, feature_size * 2),
>             nn.ReLU(),
>             # nn.BatchNorm1d(feature_size*2),
>             nn.Linear(feature_size * 2, feature_size),
>             nn.ReLU(),
>             # nn.BatchNorm1d(feature_size),
>             nn.Sigmoid()
>         )
>         self.gate_v = nn.Sequential(
>             nn.Linear(1, feature_size * 2),
>             nn.ReLU(),
>             # nn.BatchNorm1d(feature_size*2),
>             nn.Linear(feature_size * 2, feature_size),
>             nn.ReLU(),
>             # nn.BatchNorm1d(feature_size),
>             nn.Sigmoid()
>         )
>
>     def forward(self, x, user_fea, mask=None):
>         # Apply linear transformations
>         batch, seq, dim = x.shape
>         n_d = self.feature_size // self.n_head
>
>         queries = self.query(x)
>         keys = self.key(x)
>         values = self.value(x)
>
>         queries = queries.view(batch, seq, self.n_head, n_d).permute(0, 2, 1, 3)
>         keys = keys.view(batch, seq, self.n_head, n_d).permute(0, 2, 1, 3)
>         values = values.view(batch, seq, self.n_head, n_d).permute(0, 2, 1, 3)
>
>         user_fea = user_fea[:, None, None]
>         user_fea = user_fea.repeat(1, 75, 1)
>         gate = self.gate_k(user_fea)
>
>         # Scaled dot-product attention
>         # scores = torch.matmul(queries, keys.transpose(-2, -1)) / torch.sqrt(
>         #     torch.tensor(self.feature_size, dtype=torch.float32)
>         # )
>
>         # 重写一下multi-head
>         scores = queries @ keys.transpose(2, 3) / math.sqrt(n_d)
>         # Apply mask (if provided)
>         if mask is not None:
>             mask = mask == 0
>             mask = mask[:, :, None, None]
>             mask = mask.transpose(1, 2)
>             scores = scores.masked_fill(mask, -1e9)
>
>         # Apply softmax
>         attention_weights = F.softmax(scores, dim=-1)
>         # 这里的dropout作用在注意力权重，在multi-head就应该在这，而不是输出上
>         attention_weights = self.dropout(attention_weights)
>
>         scores = torch.matmul(attention_weights, values)
>         scores = scores.permute(0, 2, 1, 3).contiguous().view(batch, seq, dim)
>         scores = scores * self.gate_k(user_fea)
>         scores = self.w_combine(scores)
>
>         return scores
>
>
> # refer to: https://github.com/codertimo/BERT-pytorch/blob/master/bert_pytorch/model/transformer.py
> class TransformerBlock(nn.Module):
>     def __init__(
>             self,
>             emb_dim,  # 采用的embedding的长度
>             dropout_rate=0.1,  # 用于ff中的dropout
>     ):
>         """
>         一个完整的Transformer Block，包括attention，一个ff，和一个shortcut的残差链接
>         """
>         super().__init__()
>         self.layer_norm_layer = nn.LayerNorm(emb_dim)
>         self.attention_layer = SelfAttentionLayer(emb_dim)
>         self.positionwise_ff_layer = nn.Sequential(
>             nn.LayerNorm(emb_dim),  # 这里增加一个layer normalization层
>             nn.Linear(emb_dim, emb_dim * 2),
>             nn.ReLU(),
>             nn.Dropout(dropout_rate),
>             nn.Linear(emb_dim * 2, emb_dim),
>         )
>
>     def forward(self, x, user_fea, mask=None):
>         residual_x = x
>         x = self.layer_norm_layer(x)  # 先对sequential input进行layer Normlization
>         x = self.attention_layer(x, user_fea, mask)
>         x += residual_x
>
>         x = self.positionwise_ff_layer(x)
>
>         return residual_x + x
>
>
> def gen_ff_layer(input_dim=128, output_dim=64):
>     """
>     一个标准的FeedForward层
>     """
>     return nn.Sequential(
>         nn.Linear(input_dim, output_dim), nn.ReLU(), nn.BatchNorm1d(output_dim)
>     )
>
>
> class linear_poso(nn.Module):
>     def __init__(self, input_size):
>         """
>         固定为 4 层的 poso 模块
>         input_size: 输入特征维度
>         hidden_units: 隐藏层单元数
>         output_size: 输出特征维度
>         """
>         super(linear_poso, self).__init__()
>
>         self.fc1 = nn.Linear(input_size, input_size * 2)
>         self.gate1 = nn.Sequential(
>             nn.Linear(1, input_size),
>             nn.ReLU(),
>             nn.Linear(input_size, input_size * 2),
>             nn.ReLU(),
>             nn.Sigmoid()
>         )
>         self.bn1 = nn.BatchNorm1d(input_size * 2)  # 批归一化
>
>         self.fc2 = nn.Linear(input_size * 2, input_size)
>         self.gate2 = nn.Sequential(
>             nn.Linear(1, input_size),
>             nn.ReLU(),
>             nn.Linear(input_size, input_size),
>             nn.ReLU(),
>             nn.Sigmoid()
>         )
>         self.bn2 = nn.BatchNorm1d(input_size)
>
>         self.fc3 = nn.Linear(input_size, input_size * 2)
>         self.gate3 = nn.Sequential(
>             nn.Linear(1, input_size),
>             nn.ReLU(),
>             nn.Linear(input_size, input_size * 2),
>             nn.ReLU(),
>             nn.Sigmoid()
>         )
>         self.bn3 = nn.BatchNorm1d(input_size * 2)
>
>         self.fc4 = nn.Linear(input_size * 2, input_size)
>         self.gate4 = nn.Sequential(
>             nn.Linear(1, input_size),
>             nn.ReLU(),
>             nn.Linear(input_size, input_size),
>             nn.ReLU(),
>             nn.Sigmoid()
>         )
>         self.bn4 = nn.BatchNorm1d(input_size)
>
>         self.relu = nn.ReLU()
>
>     def forward(self, concat_fea, user_fea):
>         """
>         concat_fea: dense+sparse
>         user_fea: 你所选的fea特征
>         """
>         user_fea = user_fea[:, None]
>
>         x = self.fc1(concat_fea) * self.gate1(user_fea) * 2
>         x = self.relu(x)
>         x = self.bn1(x)
>
>         x = self.fc2(x) * self.gate2(user_fea) * 2
>         x = self.relu(x)
>         x = self.bn2(x)
>
>         x = self.fc3(x) * self.gate3(user_fea) * 2
>         x = self.relu(x)
>         x = self.bn3(x)
>
>         x = self.fc4(x) * self.gate4(user_fea) * 2
>         x = self.relu(x)
>         x = self.bn4(x)
>         return x
>
>
> # pytorch集成的Transformer可以方便的快速自定义
> class Transformer(nn.Module):
>     def __init__(self, d_model=32, nhead=2, num_encoder_layers=2, dim_feedforward=256, dropout=0.1):
>         super(Transformer, self).__init__()
>         encoder_layers = nn.TransformerEncoderLayer(
>             d_model=d_model,
>             nhead=nhead,
>             dim_feedforward=dim_feedforward,
>             dropout=dropout
>         )
>
>         # 定义 TransformerEncoder，堆叠多个 encoder layer
>         self.transformer_encoder = nn.TransformerEncoder(
>             encoder_layers,
>             num_layers=num_encoder_layers
>         )
>
>     def forward(self, x, mask=None):
>         # x 的形状是 (batch_size, seq_len, d_model)，需要转置为 (seq_len, batch_size, d_model)
>         x = x.transpose(0, 1)
>         # 使用 TransformerEncoder 进行前向传播
>         output = self.transformer_encoder(x, src_key_padding_mask=mask)
>         # 转置回来 (batch_size, seq_len, d_model)
>         output = output.transpose(0, 1)
>         return output
>
>
> class DSAR(nn.Module):
>     def __init__(
>             self,
>             sparse_feat_num=3,  # categorical特征的个数
>             # 根据样本计算出的均值和标准差，以样本估计总体)
>             dense_mean=torch.tensor([7.9134e+00, 3.2940e-01, 2.1132e+03, 1.2431e+00, 1.4642e+02, 1.5249e-01,
>                                      3.9444e+01, 3.6540e-02, 8.9634e-01, 3.2395e-01, 5.2822e-01, 1.8922e-01,
>                                      2.0747e+00, 2.0180e-01, 3.7767e-01, 5.6712e-02, 3.0824e-02, 1.3337e-03,
>                                      5.9766e-01, 2.2410e-01, 3.1463e+03, 1.2114e+01, 4.7322e-01, 3.1007e+03,
>                                      1.4022e+00, 1.1458e-01, 1.9826e+03, 1.6417e+03, 4.4816e+00, 2.0377e-01,
>                                      1.5635e+03, 1.1345e+00, 9.5175e+01, 7.3934e-02, 2.7450e+00, 7.6429e-01,
>                                      1.5561e+01, 1.7805e+03, 9.7460e+03, 4.3540e+02, 2.3650e+03]),
>             dense_std=torch.tensor([8.3522e+00, 2.5697e-01, 6.0009e+03, 2.5196e+00, 1.9071e+02, 1.6099e+00,
>                                     1.0968e+02, 6.2347e-01, 1.1649e+00, 3.8688e-01, 9.4016e-01, 3.2278e-01,
>                                     1.2875e+00, 3.1115e-01, 3.9027e-01, 1.7562e-01, 1.3131e-01, 2.8409e-02,
>                                     8.9892e-01, 3.3205e-01, 9.6722e+03, 1.2262e+01, 3.2777e-01, 9.6708e+03,
>                                     3.8777e+00, 1.2174e-01, 5.3867e+03, 4.0202e+03, 7.2152e+00, 2.5161e-01,
>                                     4.0038e+03, 2.1755e+00, 2.0570e+02, 1.3719e-01, 1.4022e+00, 3.0976e-01,
>                                     8.4289e+00, 4.7344e+03, 2.2504e+04, 1.7420e+03, 6.7160e+03]),
>             # dense_mean=torch.tensor([8.2706e+03, 1.3064e+01, 1.3716e+03, 2.6233e+03, 1.8364e+03, 1.5246e+03,
>             #                          1.7171e+03, 2.0811e+03, 3.7897e+02, 1.5147e+03, 2.6649e+03, 1.6474e+02,
>             #                          1.3812e-01, 1.2244e-01, 8.2710e+00, 6.3592e+00, 7.1260e-01, 1.2145e+00,
>             #                          9.8686e-01, 1.0658e+00, 1.2790e+01, 4.6259e+00, 8.3799e+00, 5.2225e-01,
>             #                          2.1400e-01, 3.5874e-01, 1.2699e+00, 1.5522e-01, 1.9008e+00, 1.8903e-01,
>             #                          1.9641e+00, 1.9273e-01, 2.3365e-01, 3.5683e-02, 1.6140e-05, 1.7208e-01,
>             #                          2.3890e-02, 2.5356e+01, 9.8696e+01, 2.2579e-02, 9.4386e-02, 1.5119e+01,
>             #                          1.1605e+01, 7.0596e-01, 1.3150e+00, 9.6819e-01, 1.0748e+00, 1.4828e+01,
>             #                          3.5553e+00, 8.5808e+00, 5.9875e-01, 1.6976e-01, 3.6761e-01, 2.2827e+00,
>             #                          1.5307e-01, 3.6323e+00, 1.9427e-01, 3.6706e+00, 1.9441e-01, 2.1470e-01,
>             #                          3.2485e-02, 2.6172e-03, 1.7148e-01, 2.2012e-02, 2.6162e+01, 1.0297e+02,
>             #                          2.4057e-02, 9.7600e-02]),
>             # dense_std=torch.tensor([1.3960e+04, 5.4408e+00, 2.4200e+03, 5.2740e+03, 3.3317e+03, 2.6778e+03,
>             #                         2.9783e+03, 3.7669e+03, 9.4234e+02, 2.4588e+03, 5.2778e+03, 2.3053e+02,
>             #                         1.3095e-01, 1.4213e-01, 1.3166e+01, 1.0260e+01, 3.3466e-01, 2.8097e+00,
>             #                         1.4027e+00, 1.6114e+00, 1.3201e+01, 7.4753e+00, 9.4767e+00, 3.4036e-01,
>             #                         2.4633e-01, 2.6517e-01, 3.3630e+00, 2.6651e-01, 5.9711e+00, 3.2518e-01,
>             #                         6.0090e+00, 3.2574e-01, 3.0059e-01, 1.2718e-01, 3.0128e-03, 2.9804e-01,
>             #                         1.0226e-01, 6.5764e+01, 1.2522e+02, 4.5314e-01, 1.0366e+00, 2.3720e+01,
>             #                         1.8491e+01, 3.0403e-01, 3.2197e+00, 1.3925e+00, 1.6299e+00, 1.3788e+01,
>             #                         6.1992e+00, 9.1830e+00, 3.3970e-01, 2.1370e-01, 2.5302e-01, 5.6435e+00,
>             #                         2.3073e-01, 1.0818e+01, 3.0386e-01, 1.0783e+01, 3.0190e-01, 2.4970e-01,
>             #                         1.0405e-01, 2.4462e-02, 2.7045e-01, 8.3991e-02, 5.9563e+01, 1.0975e+02,
>             #                         4.5968e-01, 1.0299e+00]),
>             sparse_feat_cands=[24, 8, 400],  # hour, dayofweek, city_id
>             sparse_embedding_dim=128,  # onehot特征的dimension（所有onehot特征的dimension都一样哈）
>             # dense_feat_num=41 + 27,  # dense特征的个数
>             dense_feat_num=41,  # dense特征的个数
>             max_len=75,  # padding的最长长度
>             price_embedding_dim=128,  # 价格对应的embedding的长度
>             # price_embedding_dim=256,  # 主要是这里用了multi-head，所以emd扩大了，不然可能会有low-rank，65<75，无法捕捉信息
>
>             price_cap=10002,  # 价格细分为1万个，即最高价为1000元，另外两个特征，一个是大于1000元的，一个是padding mask对应的
>             attention_layer_num=2,  # attention层的次数
>             ff_repetition_num=4,  # 全连接层的层数
>     ):
>         """
>         首先，sparse特征按照nn.embedding进行赋值，然后打平之后，降维之后，跟dense特征进行拼接
>         然后过一些MLP层；
>         与此同时，我们对price_list，将价格作为word，进行attention；
>         得到的class的表征，作为整个价格list的表征，concat到order——user的embdding上去；
>         然后每个价格的输出结果，最后拼接到整体的embedding上，进行预测；
>         """
>         super().__init__()
>         self.register_buffer('dense_mean', dense_mean)
>         self.register_buffer('dense_std', dense_std)
>
>         self.sparse_feat_num = sparse_feat_num
>         self.sparse_feat_cands = sparse_feat_cands
>         self.dense_feat_num = dense_feat_num
>         self.price_cap = price_cap
>         self.max_len = max_len
>
>         self.sparse_embedding_lookup = nn.ModuleList()
>         for i in sparse_feat_cands:
>             self.sparse_embedding_lookup.append(nn.Embedding(i, sparse_embedding_dim))
>
>         # concat之后的onehot特征的embedding的维度
>         emb_concat_dim = sparse_embedding_dim * len(sparse_feat_cands)
>
>         self.sparse_embedding_ff = nn.Sequential(
>             nn.Linear(emb_concat_dim, emb_concat_dim // 4),
>             nn.ReLU(),
>             nn.BatchNorm1d(emb_concat_dim // 4),
>         )
>
>         self.price_embedding_lookup = nn.Embedding(
>             price_cap + 1, price_embedding_dim
>         )  # +1的原因是：index为0到10000都是有值的
>
>         self.price_linaer = nn.Linear(1, 128)
>
>         self.pos_embedding = nn.Parameter(
>             torch.randn(1, max_len, price_embedding_dim)
>         )  # 维度需要跟价格embedding保持一致
>
>         self.self_attention_layers = nn.ModuleList()
>
>         for _ in range(attention_layer_num):
>             self.self_attention_layers.append(TransformerBlock(price_embedding_dim))
>
>         self.transformer_encoder = Transformer()
>
>         input_dim = dense_feat_num + len(sparse_feat_cands) * sparse_embedding_dim // 4
>
>         self.ff_layers = nn.Sequential(
>             gen_ff_layer(input_dim, input_dim * 2),
>             gen_ff_layer(input_dim * 2, input_dim),
>             gen_ff_layer(input_dim, input_dim * 2),
>             gen_ff_layer(input_dim * 2, input_dim),
>         )
>
>         # 加入poso_linear
>         self.poso = linear_poso(input_dim)
>
>         input_dim += price_embedding_dim
>         print("concat之后的ff的input dim为：{}".format(input_dim))
>         self.price_emb_feat_emb_ff_layer = gen_ff_layer(input_dim, input_dim)
>
>         input_dim += price_embedding_dim  # dense feature的dim，拼接了price表征的dim，最后还要拼接上当前cp的price embedding
>         input_dim = input_dim + 1  # 这里最后还加了一个维度是因为拼接了一个cpm
>         self.last_layer = nn.Sequential(nn.Linear(input_dim, 1), nn.Sigmoid())
>
>     def forward(self, sparse, dense, price_list):
>         """
>         spare: [batch_size, -1]
>         dense: [batch_size, -1]
>         price_list: [batch_size, 75]，这个需要固定长度，不然不好输入？padding提前用-1填充
>         """
>         batch_size = sparse.shape[0]
>
>         # 先对price进行取整，取整到角
>         price_list = torch.div(price_list, 10, rounding_mode="trunc").to(torch.long)
>         # 对price_list进行处理：大于price_cap - 2的，改成price_cap-1；小于0的，改成price_cap
>         price_list[price_list > self.price_cap - 2] = self.price_cap - 1
>         price_list[price_list < 0] = self.price_cap
>
>         sparse = sparse.to(torch.long)
>
>         embedding_list = []
>         for i in range(len(self.sparse_feat_cands)):
>             embedding_list.append(self.sparse_embedding_lookup[i](sparse[:, i]))
>
>         # 将所有的embedding concat到一起
>         sparse_embeddings = torch.concat(embedding_list, dim=1)
>
>         # 避免sparse embedding太长，淹没了原本的dense特征的重要性
>         sparse_embeddings = self.sparse_embedding_ff(sparse_embeddings)
>
>         # 获取距离，并计算cpm
>         # dest = dense[:, 0]
>         dest = dense[:, 38]
>         dense = (dense - self.dense_mean) / self.dense_std
>         error_dest = (dest == 0) | (dest == -1)
>         valid_values = dest[~error_dest]
>         mean_dest = valid_values.mean()
>         dest[error_dest] = mean_dest
>         dest = dest.unsqueeze(-1)
>         cpm = price_list.clone() / dest
>         cpm_mean = torch.mean(cpm)
>         cpm_std = torch.std(cpm)
>         cpm = ((cpm - cpm_mean) / cpm_std).unsqueeze(-1)
>
>         feature_embeddings = torch.concat((sparse_embeddings, dense), dim=1)
>
>         # 3+23 用的是max_call_cp_cnt_ratio_1month
>         # pc = dense[:, 56]
>         pc = dense[:, 22]
>         feature_embeddings = self.poso(feature_embeddings, pc)
>
>         price_embedding = self.price_embedding_lookup(price_list)
>         price_embedding += self.pos_embedding
>
>         # price_embedding +=
>         mask_of_price = price_list >= 0
>         for att_layer in self.self_attention_layers:
>             price_embedding = att_layer(price_embedding, pc, mask_of_price)
>
>         # 下面是标准torch的mask，即如果你用pytorch封装的transformer可以用这个模块
>         # mask_of_price = price_list < 0
>         # price_embedding = self.transformer_encoder(price_embedding,mask_of_price)
>
>         # 获取整个price_list的表征，concat到feature_embedding上
>         price_repr = price_embedding.mean(
>             dim=1
>         )  # TODO: 看一下是否需要将mask掉的token去掉？
>         feature_embeddings = torch.concat((feature_embeddings, price_repr), dim=1)
>
>         # 然后过一个mlp
>         feature_embeddings = self.price_emb_feat_emb_ff_layer(feature_embeddings)
>
>         # 最后，将feature_embeddings 和 price_embedding进行concat
>         feature_embeddings = feature_embeddings[:, None, :]  # 对
>         feature_embeddings = feature_embeddings.repeat(1, self.max_len, 1)
>         feature_embeddings = torch.concat([feature_embeddings, price_embedding, cpm], dim=-1)
>
>         output = self.last_layer(feature_embeddings)
>         return output.squeeze()
>
>
> if __name__ == "__main__":
>     device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
>     # device = torch.device("cpu")
>
>     spare_data = torch.Tensor([[8, 4, 33] for _ in range(16)]).to(device)
>     dense_data = torch.rand(16, 41 + 27).to(device)
>     price_list = torch.randint(100600, (16, 75)).to(device)
>     model = DSAR().to(device)
>
>     output = model(spare_data, dense_data, price_list)
>     print(output)
> ```


以及其对应的**训练脚本**

> [!example]- Python 实现细节（220 行）
> ```Python
> import os
> from os import path
> from torch import nn
> import torch
> import numpy as np
> from tqdm import tqdm
> import torch.optim as optim
> import configparser
> import torch.nn.functional as F
> from torch.optim.lr_scheduler import CosineAnnealingLR
> from sklearn.metrics import classification_report, roc_auc_score, mean_absolute_error
> from model_poso_41_500w import DSAR
> from loguru import logger
> import torch
> import gc
>
> # 清除 Python 层垃圾对象
> gc.collect()
> # 清除 PyTorch CUDA 缓存
> torch.cuda.empty_cache()
> # 重置已分配显存的最大值统计（可选）
> torch.cuda.reset_max_memory_allocated()
>
> # 用于存储poso_model训练的日志
> logger.add("/ofs/pltf-sub-and-pap/zhengyang/202505_project/DSAR_new_feature1/V2/logs/poso_model_500w_02.log",
>            rotation="500 MB")  # 当文件大小达到500MB时，自动创建新文件
>
> torch.backends.cudnn.benchmark = True
> os.environ["CUDA_DEVICE_ORDER"] = "PCI_BUS_ID"
> os.environ["CUDA_VISIBLE_DEVICES"] = "0"
> BASE_DIR = path.dirname(path.abspath(__file__))
>
> model_dir = path.join(BASE_DIR, "data", "model_saved")
>
> # device = torch.device("cpu")
> device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
>
>
> def read_training_data_from_numpy(data, sparse_feat_num, dense_feat_num, max_len):
>     """
>     存储的numpy或pt格式的文件，以sparse/dense/price_list/rank/label的顺序重新读取出来
>     """
>     sparse = data[:, :sparse_feat_num].to(torch.long)
>     dense = data[:, sparse_feat_num: sparse_feat_num + dense_feat_num].to(torch.float32)
>     price_list = data[:, sparse_feat_num + dense_feat_num: sparse_feat_num + dense_feat_num + max_len,].to(torch.long)
>
>     rank = data[:, -2].to(torch.long) - 1
>     label = data[:, -1].to(torch.float32)
>
>     return sparse, dense, price_list, rank, label
>
>
> conf = configparser.ConfigParser()
> conf.read(path.join(BASE_DIR, "model.config"))
>
> # 下面为训练参数配置
> # 00 原始参数训练
> # adam_learning_rate = 2e-4
> # sgd_learning_rate = 1e-5
> # adam_weight_decay = 2e-5
> # sgd_weight_decay = 1e-4
> # 01 调整参数训练
> # adam_learning_rate = 2e-3
> # sgd_learning_rate = 1e-4
> # adam_weight_decay = 2e-5
> # sgd_weight_decay = 1e-4
> # 02 调整参数训练
> adam_learning_rate = 2e-2
> sgd_learning_rate = 1e-4
> adam_weight_decay = 2e-5
> sgd_weight_decay = 1e-4
> # 03 调整参数训练（上一个有效果）
> # adam_learning_rate = 2e-1
> # sgd_learning_rate = 1e-4
> # adam_weight_decay = 2e-5
> # sgd_weight_decay = 1e-4
> # 04 使用动态预测，基于Adam在连续两次AUC下降后进行后续的SGD训练
> nepoch = 50
> batch_size = 16384
> # batch_size = 8192
> predict_batch_size = 16384
> # predict_batch_size = 8192
> sparse_feat_num = 3
> # dense_feat_num = 41 + 27
> dense_feat_num = 41
> max_len = 75
> price_embedding_dim = 128
> switch_epoch = 20  # adam切换为sgd的epoch
> momentum = 0.9  # 设置momentum的惯性系数
>
> model = DSAR(
>     sparse_feat_num=sparse_feat_num,
>     dense_feat_num=dense_feat_num,
>     price_embedding_dim=price_embedding_dim,
> ).to(device)
>
> auc = 0
> best_auc = 0.899
> best_epoch = 0
> best_iter = 0
>
> training_data = torch.load('/ofs/pltf-sub-and-pap/zhengyang/202505_project/DSAR_new_feature1/V2/datas/base_500w_train_data.pt')
> training_data = training_data[torch.randperm(training_data.shape[0])] # 打乱顺序，随机设置训练样本
> training_data = training_data.to(device)
>
> testing_data = torch.load('/ofs/pltf-sub-and-pap/zhengyang/202505_project/DSAR_new_feature1/V2/datas/base_500w_test_data.pt')
> testing_data = testing_data.to(device)  # 因为预测跟顺序无关，可以不用shuffle
>
> ######### Optimizer ###########
> start_epoch = 1
> optimizer = optim.Adam(
>     model.parameters(),
>     lr=adam_learning_rate,
>     betas=(0.9, 0.999),
>     eps=1e-8,
>     weight_decay=adam_weight_decay,
> )
> optimizer.step()
>
> ######### Scheduler ###########
> # step = 25
> # print("Using StepLR,step={}!".format(step))
> # scheduler = StepLR(optimizer, step_size=step, gamma=0.5)
> # scheduler.step()
>
>
> # 使用余弦退火进行调度优化器
> scheduler = CosineAnnealingLR(optimizer, T_max=20, eta_min=1e-5)
> criterion = torch.nn.BCELoss().to(device)  # TODO: 可以考虑给两个label不同的权重
>
> # 考虑加权交叉熵
>
> # 训练的所有的batch的批次大小
> batch_for_each_epoch = training_data.shape[0] // batch_size
>
> for epoch in range(start_epoch, nepoch + 1):
>     epoch_loss = 0
>     model.train() # 开始训练
>     for i in tqdm(range(batch_for_each_epoch)): # 多少个batch作为一次epoch
>         optimizer.zero_grad()
>
>         # 没有用data_loader，手动写的
>         cur_training_data = training_data[i * batch_size: i * batch_size + batch_size, ...]
>
>         sparse, dense, price_list, rank, label = read_training_data_from_numpy(
>             cur_training_data, sparse_feat_num, dense_feat_num, max_len
>         )
>
>         output = model(sparse, dense, price_list)
>
>         # 从每个样本中，获取对应rank的结果
>         output = output.gather(1, rank.unsqueeze(1)).squeeze()
>         loss = criterion(output, label)
>         loss.backward()
>         optimizer.step()
>         epoch_loss += loss.item()
>
>     if epoch < switch_epoch:
>         scheduler.step()
>
>     if epoch == switch_epoch:
>         print("Switching optimizer to SGD with momentum...")
>         logger.info(f" Switching optimizer to SGD with momentum...,switch_epoch is {epoch}")
>         optimizer = optim.SGD(model.parameters(), lr=sgd_learning_rate, momentum=momentum,
>                               weight_decay=sgd_weight_decay)
>         scheduler = None  # 或根据需要设定新的调度器
>
>     # 跑完一个epoch之后，过一遍testing data，打印各种指标
>     with torch.no_grad():
>         model.eval()
>
>         output_list, pred_label_list, target_label_list = [], [], []
>
>         test_data_length = testing_data.shape[0]
>         for i in tqdm(range(0, test_data_length, predict_batch_size)):
>             cur_testing_data = testing_data[i: i + predict_batch_size]
>             sparse, dense, price_list, rank, label = read_training_data_from_numpy(
>                 cur_testing_data, sparse_feat_num, dense_feat_num, max_len
>             )
>             output = model(sparse, dense, price_list)
>
>             output = (
>                 output.gather(1, rank.unsqueeze(1)).squeeze().cpu().numpy()
>             )  # 将结果存到cpu中，sklearn不支持GPU
>             output_list.append(output)
>
>             target_label_list.append(label.to(torch.long).cpu().numpy())
>
>             pred_label = output > 0.5
>             pred_label_list.append(pred_label)
>
>         output = np.hstack(output_list) # 预测的概率分数
>
>         pred_label = np.hstack(pred_label_list)  # 预测的标签，转为0 1
>         target_label = np.hstack(target_label_list) # 原始的标签，为0 1
>
>         auc = roc_auc_score(target_label, output) # 最终目标指标之一，求AUC
>         mae = mean_absolute_error(target_label, output) # 新加的目标，求MAE
>
>         report = classification_report(target_label, pred_label, output_dict=True)
>         pos_report = report["1"]
>         precesion = pos_report["precision"]
>         recall = pos_report["recall"]
>         f1_score = pos_report["f1-score"]
>         accuracy = report["accuracy"]
>         if epoch < switch_epoch:
>             logger.info(
>                 f" Epoch of {epoch}:loss is {epoch_loss:.2%},batchsize is {batch_size},lr is {scheduler.get_lr()},auc is {auc:.5%}, mae is {mae:.5%}, precesion is {precesion:.5%},recall is {recall:.5%},f1-score is {f1_score:.5%},accuracy is {accuracy:.5%},weight_decay is {adam_weight_decay:.5%}")
>         else:
>             logger.info(
>                 f" Epoch of {epoch}:loss is {epoch_loss:.2%},auc is {auc:.5%}, mae is {mae:.5%}, precesion is {precesion:.5%},recall is {recall:.5%},f1-score is {f1_score:.5%},accuracy is {accuracy:.5%}")
>         if auc > best_auc:
>             best_auc = auc
>             best_epoch = epoch
>             best_iter = i
>             torch.save({'epoch': epoch,
>                         'state_dict': model.state_dict(),
>                         'optimizer': optimizer.state_dict()
>                         },
>                        '/ofs/pltf-sub-and-pap/zhengyang/202505_project/DSAR_new_feature1/V2/logs/poso_model_500w_best_params.pth')
> ```


 

对应的，原始的**base_DSAR模型代码**如下

> [!example]- Python 实现细节（249 行）
> ```Python
> import torch
> from torch import nn
> # from einops import rearrange, repeat
> from functools import partial
> import torch.nn as nn
> import torch.nn.functional as F
>
>
> class SelfAttentionLayer(nn.Module):
>     def __init__(self, feature_size, dropout_rate=0.1):
>         super(SelfAttentionLayer, self).__init__()
>         self.feature_size = feature_size
>
>         # Linear transformations for Q, K, V from the same source
>         self.key = nn.Linear(feature_size, feature_size)
>         self.query = nn.Linear(feature_size, feature_size)
>         self.value = nn.Linear(feature_size, feature_size)
>         self.dropout = nn.Dropout(dropout_rate)
>
>     def forward(self, x, mask=None):
>         # Apply linear transformations
>         keys = self.key(x)
>         queries = self.query(x)
>         values = self.value(x)
>
>         # Scaled dot-product attention
>         scores = torch.matmul(queries, keys.transpose(-2, -1)) / torch.sqrt(
>             torch.tensor(self.feature_size, dtype=torch.float32)
>         )
>
>         # Apply mask (if provided)
>         if mask is not None:
>             mask = mask == 0
>             mask = mask[:, :, None]
>             scores = scores.masked_fill(mask, -1e9)
>
>         # Apply softmax
>         attention_weights = F.softmax(scores, dim=-1)
>         # 这里的dropout作用在scores上
>         attention_weights = self.dropout(attention_weights)
>
>         # Multiply weights with values
>         output = torch.matmul(attention_weights, values)
>
>         return output
>         # return output, attention_weights
>
>
> # refer to: https://github.com/codertimo/BERT-pytorch/blob/master/bert_pytorch/model/transformer.py
> class TransformerBlock(nn.Module):
>     def __init__(
>             self,
>             emb_dim,  # 采用的embedding的长度
>             dropout_rate=0.1,  # 用于ff中的dropout
>     ):
>         """
>         一个完整的Transformer Block，包括attention，一个ff，和一个shortcut的残差链接
>         """
>         super().__init__()
>         self.layer_norm_layer = nn.LayerNorm(emb_dim)
>         self.attention_layer = SelfAttentionLayer(emb_dim)
>         self.positionwise_ff_layer = nn.Sequential(
>             nn.LayerNorm(emb_dim),  # 这里增加一个layer normalization层
>             nn.Linear(emb_dim, emb_dim * 2),
>             nn.ReLU(),
>             nn.Dropout(dropout_rate),
>             nn.Linear(emb_dim * 2, emb_dim),
>         )
>
>     def forward(self, x, mask=None):
>         residual_x = x
>         x = self.layer_norm_layer(x)  # 先对sequential input进行layer Normlization
>         x = self.attention_layer(x, mask)
>         x += residual_x
>
>         x = self.positionwise_ff_layer(x)
>
>         return residual_x + x
>
>
> def gen_ff_layer(input_dim=128, output_dim=64):
>     """
>     一个标准的FeedForward层
>     """
>     return nn.Sequential(
>         nn.Linear(input_dim, output_dim), nn.ReLU(), nn.BatchNorm1d(output_dim)
>     )
>
>
> class DSAR(nn.Module):
>     def __init__(
>             self,
>             sparse_feat_num=3,  # categorical特征的个数
>             # 根据样本计算出的均值和标准差，以样本估计总体)
>             dense_mean=torch.tensor([7.9134e+00, 3.2940e-01, 2.1132e+03, 1.2431e+00, 1.4642e+02, 1.5249e-01,
>                                      3.9444e+01, 3.6540e-02, 8.9634e-01, 3.2395e-01, 5.2822e-01, 1.8922e-01,
>                                      2.0747e+00, 2.0180e-01, 3.7767e-01, 5.6712e-02, 3.0824e-02, 1.3337e-03,
>                                      5.9766e-01, 2.2410e-01, 3.1463e+03, 1.2114e+01, 4.7322e-01, 3.1007e+03,
>                                      1.4022e+00, 1.1458e-01, 1.9826e+03, 1.6417e+03, 4.4816e+00, 2.0377e-01,
>                                      1.5635e+03, 1.1345e+00, 9.5175e+01, 7.3934e-02, 2.7450e+00, 7.6429e-01,
>                                      1.5561e+01, 1.7805e+03, 9.7460e+03, 4.3540e+02, 2.3650e+03]),
>             dense_std=torch.tensor([8.3522e+00, 2.5697e-01, 6.0009e+03, 2.5196e+00, 1.9071e+02, 1.6099e+00,
>                                     1.0968e+02, 6.2347e-01, 1.1649e+00, 3.8688e-01, 9.4016e-01, 3.2278e-01,
>                                     1.2875e+00, 3.1115e-01, 3.9027e-01, 1.7562e-01, 1.3131e-01, 2.8409e-02,
>                                     8.9892e-01, 3.3205e-01, 9.6722e+03, 1.2262e+01, 3.2777e-01, 9.6708e+03,
>                                     3.8777e+00, 1.2174e-01, 5.3867e+03, 4.0202e+03, 7.2152e+00, 2.5161e-01,
>                                     4.0038e+03, 2.1755e+00, 2.0570e+02, 1.3719e-01, 1.4022e+00, 3.0976e-01,
>                                     8.4289e+00, 4.7344e+03, 2.2504e+04, 1.7420e+03, 6.7160e+03]),
>             sparse_feat_cands=[24, 8, 400],  # hour, dayofweek, city_id
>             sparse_embedding_dim=128,  # onehot特征的dimension（所有onehot特征的dimension都一样哈）
>             dense_feat_num=41,  # dense特征的个数
>             max_len=75,  # padding的最长长度
>             price_embedding_dim=128,  # 价格对应的embedding的长度
>             price_cap=10002,  # 价格细分为1万个，即最高价为1000元，另外两个特征，一个是大于1000元的，一个是padding mask对应的
>             attention_layer_num=2,  # attention层的次数
>             ff_repetition_num=4,  # 全连接层的层数
>     ):
>         """
>         首先，sparse特征按照nn.embedding进行赋值，然后打平之后，降维之后，跟dense特征进行拼接
>         然后过一些MLP层；
>         与此同时，我们对price_list，将价格作为word，进行attention；
>         得到的class的表征，作为整个价格list的表征，concat到order——user的embdding上去；
>         然后每个价格的输出结果，最后拼接到整体的embedding上，进行预测；
>         """
>         super().__init__()
>         self.register_buffer('dense_mean', dense_mean)
>         self.register_buffer('dense_std', dense_std)
>
>         self.sparse_feat_num = sparse_feat_num
>         self.sparse_feat_cands = sparse_feat_cands
>         self.dense_feat_num = dense_feat_num
>         self.price_cap = price_cap
>         self.max_len = max_len
>
>         self.sparse_embedding_lookup = nn.ModuleList()
>         for i in sparse_feat_cands:
>             self.sparse_embedding_lookup.append(nn.Embedding(i, sparse_embedding_dim))
>
>         # concat之后的onehot特征的embedding的维度
>         emb_concat_dim = sparse_embedding_dim * len(sparse_feat_cands)
>         self.sparse_embedding_ff = nn.Sequential(
>             nn.Linear(emb_concat_dim, emb_concat_dim // 4),
>             nn.ReLU(),
>             nn.BatchNorm1d(emb_concat_dim // 4),
>         )
>
>         self.price_embedding_lookup = nn.Embedding(
>             price_cap + 1, price_embedding_dim
>         )  # +1的原因是：index为0到10000都是有值的
>
>         self.pos_embedding = nn.Parameter(
>             torch.randn(1, max_len, price_embedding_dim)
>         )  # 维度需要跟价格embedding保持一致
>
>         self.self_attention_layers = nn.ModuleList()
>
>         for _ in range(attention_layer_num):
>             self.self_attention_layers.append(TransformerBlock(price_embedding_dim))
>
>         input_dim = dense_feat_num + len(sparse_feat_cands) * sparse_embedding_dim // 4
>         self.ff_layers = nn.Sequential(
>             gen_ff_layer(input_dim, input_dim * 2),
>             gen_ff_layer(input_dim * 2, input_dim),
>             gen_ff_layer(input_dim, input_dim * 2),
>             gen_ff_layer(input_dim * 2, input_dim),
>         )
>
>         input_dim += price_embedding_dim
>         print("concat之后的ff的input dim为：{}".format(input_dim))
>         self.price_emb_feat_emb_ff_layer = gen_ff_layer(input_dim, input_dim)
>
>         input_dim += price_embedding_dim  # dense feature的dim，拼接了price表征的dim，最后还要拼接上当前cp的price embedding
>         # input_dim += 2
>         self.last_layer = nn.Sequential(nn.Linear(input_dim, 1), nn.Sigmoid())
>
>     def forward(self, sparse, dense, price_list):
>         """
>         spare: [batch_size, -1]
>         dense: [batch_size, -1]
>         price_list: [batch_size, 75]，这个需要固定长度，不然不好输入？padding提前用-1填充
>         """
>         batch_size = sparse.shape[0]
>
>         # 先对price进行取整，取整到角
>         price_list = torch.div(price_list, 10, rounding_mode="trunc").to(torch.long)
>         # 对price_list进行处理：大于price_cap - 2的，改成price_cap-1；小于0的，改成price_cap
>         price_list[price_list > self.price_cap - 2] = self.price_cap - 1
>         price_list[price_list < 0] = self.price_cap
>
>         sparse = sparse.to(torch.long)
>
>         embedding_list = []
>         for i in range(len(self.sparse_feat_cands)):
>             embedding_list.append(self.sparse_embedding_lookup[i](sparse[:, i]))
>
>         # 将所有的embedding concat到一起
>         sparse_embeddings = torch.concat(embedding_list, dim=1)
>
>         # 避免sparse embedding太长，淹没了原本的dense特征的重要性
>         sparse_embeddings = self.sparse_embedding_ff(sparse_embeddings)
>
>         dense = (dense - self.dense_mean) / self.dense_std
>
>         feature_embeddings = torch.concat((sparse_embeddings, dense), dim=1)
>         feature_embeddings = self.ff_layers(feature_embeddings)
>
>         price_embedding = self.price_embedding_lookup(price_list)
>
>         price_embedding += self.pos_embedding
>
>         # price_embedding +=
>         mask_of_price = price_list >= 0
>
>         # 对价格list进行attention操作
>         for att_layer in self.self_attention_layers:
>             price_embedding = att_layer(price_embedding, mask_of_price)
>             # price_embedding = att_layer(price_embedding)
>
>         # 获取整个price_list的表征，concat到feature_embedding上
>         price_repr = price_embedding.mean(
>             dim=1
>         )  # TODO: 看一下是否需要将mask掉的token去掉？
>         feature_embeddings = torch.concat((feature_embeddings, price_repr), dim=1)
>         # 然后过一个mlp
>         feature_embeddings = self.price_emb_feat_emb_ff_layer(feature_embeddings)
>
>         # 最后，将feature_embeddings 和 price_embedding进行concat
>         feature_embeddings = feature_embeddings[:, None, :]  # 对
>         feature_embeddings = feature_embeddings.repeat(1, self.max_len, 1)
>
>         feature_embeddings = torch.concat([feature_embeddings, price_embedding], dim=-1)
>
>         output = self.last_layer(feature_embeddings)
>
>         return output.squeeze()
>
>
> if __name__ == "__main__":
>     device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
>
>     spare_data = torch.Tensor([[8, 4, 33] for _ in range(16)]).to(device)
>     dense_data = torch.rand(16, 41).to(device)
>     price_list = torch.randint(100600, (16, 75)).to(device)
>     model = DSAR().to(device)
>
>     output = model(spare_data, dense_data, price_list)
>
>     print(output)
>     # print(output.shape)
> ```


对应的训练脚本

> [!example]- Python 实现细节（220 行）
> ```Python
> import os
> from os import path
> from torch import nn
> import torch
> import numpy as np
> from tqdm import tqdm
> import torch.optim as optim
> import configparser
> import torch.nn.functional as F
> from torch.optim.lr_scheduler import CosineAnnealingLR
> from sklearn.metrics import classification_report, roc_auc_score, mean_absolute_error
> from model_base_41_500w import DSAR
> from loguru import logger
> import torch
> import gc
>
> # 清除 Python 层垃圾对象
> gc.collect()
> # 清除 PyTorch CUDA 缓存
> torch.cuda.empty_cache()
> # 重置已分配显存的最大值统计（可选）
> torch.cuda.reset_max_memory_allocated()
>
> # 用于存储poso_model训练的日志
> logger.add("/ofs/pltf-sub-and-pap/zhengyang/202505_project/DSAR_new_feature1/V2/logs/base_model_500w_02.log",
>            rotation="500 MB")  # 当文件大小达到500MB时，自动创建新文件
>
> torch.backends.cudnn.benchmark = True
> os.environ["CUDA_DEVICE_ORDER"] = "PCI_BUS_ID"
> os.environ["CUDA_VISIBLE_DEVICES"] = "0"
> BASE_DIR = path.dirname(path.abspath(__file__))
>
> model_dir = path.join(BASE_DIR, "data", "model_saved")
>
> # device = torch.device("cpu")
> device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
>
>
> def read_training_data_from_numpy(data, sparse_feat_num, dense_feat_num, max_len):
>     """
>     存储的numpy或pt格式的文件，以sparse/dense/price_list/rank/label的顺序重新读取出来
>     """
>     sparse = data[:, :sparse_feat_num].to(torch.long)
>     dense = data[:, sparse_feat_num: sparse_feat_num + dense_feat_num].to(torch.float32)
>     price_list = data[:, sparse_feat_num + dense_feat_num: sparse_feat_num + dense_feat_num + max_len,].to(torch.long)
>
>     rank = data[:, -2].to(torch.long) - 1
>     label = data[:, -1].to(torch.float32)
>
>     return sparse, dense, price_list, rank, label
>
>
> conf = configparser.ConfigParser()
> conf.read(path.join(BASE_DIR, "model.config"))
>
> # 下面为训练参数配置
> # 00 原始参数训练
> # adam_learning_rate = 2e-4
> # sgd_learning_rate = 1e-5
> # adam_weight_decay = 2e-5
> # sgd_weight_decay = 1e-4
> # 01 调整参数训练
> # adam_learning_rate = 2e-3
> # sgd_learning_rate = 1e-4
> # adam_weight_decay = 2e-5
> # sgd_weight_decay = 1e-4
> # 02 调整参数训练
> adam_learning_rate = 2e-2
> sgd_learning_rate = 1e-4
> adam_weight_decay = 2e-5
> sgd_weight_decay = 1e-4
> # 03 调整参数训练（上一个有效果）
> # adam_learning_rate = 2e-1
> # sgd_learning_rate = 1e-4
> # adam_weight_decay = 2e-5
> # sgd_weight_decay = 1e-4
> # 04 使用动态预测，基于Adam在连续两次AUC下降后进行后续的SGD训练
> nepoch = 50
> batch_size = 16384
> # batch_size = 8192
> predict_batch_size = 16384
> # predict_batch_size = 8192
> sparse_feat_num = 3
> # dense_feat_num = 41 + 27
> dense_feat_num = 41
> max_len = 75
> price_embedding_dim = 128
> switch_epoch = 20  # adam切换为sgd的epoch
> momentum = 0.9  # 设置momentum的惯性系数
>
> model = DSAR(
>     sparse_feat_num=sparse_feat_num,
>     dense_feat_num=dense_feat_num,
>     price_embedding_dim=price_embedding_dim,
> ).to(device)
>
> auc = 0
> best_auc = 0.899
> best_epoch = 0
> best_iter = 0
>
> training_data = torch.load('/ofs/pltf-sub-and-pap/zhengyang/202505_project/DSAR_new_feature1/V2/datas/base_500w_train_data.pt')
> training_data = training_data[torch.randperm(training_data.shape[0])] # 打乱顺序，随机设置训练样本
> training_data = training_data.to(device)
>
> testing_data = torch.load('/ofs/pltf-sub-and-pap/zhengyang/202505_project/DSAR_new_feature1/V2/datas/base_500w_test_data.pt')
> testing_data = testing_data.to(device)  # 因为预测跟顺序无关，可以不用shuffle
>
> ######### Optimizer ###########
> start_epoch = 1
> optimizer = optim.Adam(
>     model.parameters(),
>     lr=adam_learning_rate,
>     betas=(0.9, 0.999),
>     eps=1e-8,
>     weight_decay=adam_weight_decay,
> )
> optimizer.step()
>
> ######### Scheduler ###########
> # step = 25
> # print("Using StepLR,step={}!".format(step))
> # scheduler = StepLR(optimizer, step_size=step, gamma=0.5)
> # scheduler.step()
>
>
> # 使用余弦退火进行调度优化器
> scheduler = CosineAnnealingLR(optimizer, T_max=20, eta_min=1e-5)
> criterion = torch.nn.BCELoss().to(device)  # TODO: 可以考虑给两个label不同的权重
>
> # 考虑加权交叉熵
>
> # 训练的所有的batch的批次大小
> batch_for_each_epoch = training_data.shape[0] // batch_size
>
> for epoch in range(start_epoch, nepoch + 1):
>     epoch_loss = 0
>     model.train() # 开始训练
>     for i in tqdm(range(batch_for_each_epoch)): # 多少个batch作为一次epoch
>         optimizer.zero_grad()
>
>         # 没有用data_loader，手动写的
>         cur_training_data = training_data[i * batch_size: i * batch_size + batch_size, ...]
>
>         sparse, dense, price_list, rank, label = read_training_data_from_numpy(
>             cur_training_data, sparse_feat_num, dense_feat_num, max_len
>         )
>
>         output = model(sparse, dense, price_list)
>
>         # 从每个样本中，获取对应rank的结果
>         output = output.gather(1, rank.unsqueeze(1)).squeeze()
>         loss = criterion(output, label)
>         loss.backward()
>         optimizer.step()
>         epoch_loss += loss.item()
>
>     if epoch < switch_epoch:
>         scheduler.step()
>
>     if epoch == switch_epoch:
>         print("Switching optimizer to SGD with momentum...")
>         logger.info(f" Switching optimizer to SGD with momentum...,switch_epoch is {epoch}")
>         optimizer = optim.SGD(model.parameters(), lr=sgd_learning_rate, momentum=momentum,
>                               weight_decay=sgd_weight_decay)
>         scheduler = None  # 或根据需要设定新的调度器
>
>     # 跑完一个epoch之后，过一遍testing data，打印各种指标
>     with torch.no_grad():
>         model.eval()
>
>         output_list, pred_label_list, target_label_list = [], [], []
>
>         test_data_length = testing_data.shape[0]
>         for i in tqdm(range(0, test_data_length, predict_batch_size)):
>             cur_testing_data = testing_data[i: i + predict_batch_size]
>             sparse, dense, price_list, rank, label = read_training_data_from_numpy(
>                 cur_testing_data, sparse_feat_num, dense_feat_num, max_len
>             )
>             output = model(sparse, dense, price_list)
>
>             output = (
>                 output.gather(1, rank.unsqueeze(1)).squeeze().cpu().numpy()
>             )  # 将结果存到cpu中，sklearn不支持GPU
>             output_list.append(output)
>
>             target_label_list.append(label.to(torch.long).cpu().numpy())
>
>             pred_label = output > 0.5
>             pred_label_list.append(pred_label)
>
>         output = np.hstack(output_list) # 预测的概率分数
>
>         pred_label = np.hstack(pred_label_list)  # 预测的标签，转为0 1
>         target_label = np.hstack(target_label_list) # 原始的标签，为0 1
>
>         auc = roc_auc_score(target_label, output) # 最终目标指标之一，求AUC
>         mae = mean_absolute_error(target_label, output) # 新加的目标，求MAE
>
>         report = classification_report(target_label, pred_label, output_dict=True)
>         pos_report = report["1"]
>         precesion = pos_report["precision"]
>         recall = pos_report["recall"]
>         f1_score = pos_report["f1-score"]
>         accuracy = report["accuracy"]
>         if epoch < switch_epoch:
>             logger.info(
>                 f" Epoch of {epoch}:loss is {epoch_loss:.2%},batchsize is {batch_size},lr is {scheduler.get_lr()},auc is {auc:.5%}, mae is {mae:.5%}, precesion is {precesion:.5%},recall is {recall:.5%},f1-score is {f1_score:.5%},accuracy is {accuracy:.5%},weight_decay is {adam_weight_decay:.5%}")
>         else:
>             logger.info(
>                 f" Epoch of {epoch}:loss is {epoch_loss:.2%},auc is {auc:.5%}, mae is {mae:.5%}, precesion is {precesion:.5%},recall is {recall:.5%},f1-score is {f1_score:.5%},accuracy is {accuracy:.5%}")
>         if auc > best_auc:
>             best_auc = auc
>             best_epoch = epoch
>             best_iter = i
>             torch.save({'epoch': epoch,
>                         'state_dict': model.state_dict(),
>                         'optimizer': optimizer.state_dict()
>                         },
>                        '/ofs/pltf-sub-and-pap/zhengyang/202505_project/DSAR_new_feature1/V2/logs/base_model_500w_best_params.pth')
> ```


### 1.1.2 数据准备

原始的poso_model_v2使用的特征是3 + 41 + 27 + 75；base_model使用的特征是3 + 41 + 27 + **6** + 75，特征维度不统一，无法直接把两个数据放一起进行训练来对比两个模型的效果。

**（1）原始特征**

上一位同学使用的原始特征包括：

h,dayofweek,city_id,start_dest_dis,product_cnt,min_estimate_fee_amt,max_estimate_fee_amt,avg_estimate_fee_amt,quarter_estimate_fee_amt,median_estimate_fee_amt,three_quarter_estimate_fee_amt,stddev_estimate_fee_amt,min_basic_total_fee_amt,max_basic_total_fee_amt,avg_basic_total_fee_amt,quarter_basic_total_fee_amt,median_basic_total_fee_amt,three_quarter_basic_total_fee_amt,min_fee_subsidy_amt,max_subsidy_rate,min_fee_subsidy_rate,order_cnt_1month,finish_order_cnt_1month,pid_cr_1month,max_fee_scale_1month,min_fee_scale_1month,avg_fee_scale_1month,max_call_cp_cnt_1month,min_call_cp_cnt_1month,avg_call_cp_cnt_1month,max_call_cp_cnt_ratio_1month,min_call_cp_cnt_ratio_1month,avg_call_cp_cnt_ratio_1month,jiagou_order_cnt_1month,jiagou_order_ratio_1month,fangou_order_cnt_1month,fangou_order_ratio_1month,call_min_fee_cnt_1month,call_min_fee_ratio_1month,is_upto_tj_ratio_1month,is_upto_tk_ratio_1month,is_upto_ykjia_ratio_1month,is_upto_tjhezi_ratio_1month,is_upto_tkhezi_ratio_1month,avg_gap_ahead_1month,avg_gap_after_1month,avg_gap_ahead_ratio_1month,avg_gap_after_ratio_1month,pap_rank,is_fangou,show_fee_plist,dt

> [!example]- 完整数据表（52 行记录）
> | | feature_name |
> | --- | --- |
> | 0 | h |
> | 1 | dayofweek                                                                           时空维度特征 |
> | 2 | city_id |
> | 3 | start_dest_dis |
> | 4 | product_cnt |
> | 5 | min_estimate_fee_amt |
> | 6 | max_estimate_fee_amt |
> | 7 | avg_estimate_fee_amt |
> | 8 | quarter_estimate_fee_amt                                                   与实付价格相关的数值特征 |
> | 9 | median_estimate_fee_amt |
> | 10 | three_quarter_estimate_fee_amt |
> | 11 | stddev_estimate_fee_amt |
> | 12 | min_basic_total_fee_amt |
> | 13 | max_basic_total_fee_amt |
> | 14 | avg_basic_total_fee_amt                                                          与应付价格相关的数值特征 |
> | 15 | quarter_basic_total_fee_amt |
> | 16 | median_basic_total_fee_amt |
> | 17 | three_quarter_basic_total_fee_amt |
> | 18 | min_fee_subsidy_amt |
> | 19 | max_subsidy_rate |
> | 20 | min_fee_subsidy_rate |
> | 21 | order_cnt_1month |
> | 22 | finish_order_cnt_1month |
> | 23 | pid_cr_1month |
> | 24 | max_fee_scale_1month |
> | 25 | min_fee_scale_1month |
> | 26 | avg_fee_scale_1month |
> | 27 | max_call_cp_cnt_1month |
> | 28 | min_call_cp_cnt_1month |
> | 29 | avg_call_cp_cnt_1month                  过去一个月cp呼叫数目与比例的数值特征 |
> | 30 | max_call_cp_cnt_ratio_1month |
> | 31 | min_call_cp_cnt_ratio_1month |
> | 32 | avg_call_cp_cnt_ratio_1month |
> | 33 | jiagou_order_cnt_1month |
> | 34 | jiagou_order_ratio_1month                   用户加反勾数目和比例 |
> | 35 | fangou_order_cnt_1month |
> | 36 | fangou_order_ratio_1month |
> | 37 | call_min_fee_cnt_1month |
> | 38 | call_min_fee_ratio_1month |
> | 39 | is_upto_tj_ratio_1month |
> | 40 | is_upto_tk_ratio_1month |
> | 41 | is_upto_ykjia_ratio_1month                      ykjia(一口价) |
> | 42 | is_upto_tjhezi_ratio_1month                    tj(特价) |
> | 43 | is_upto_tkhezi_ratio_1month                   tk(特快) |
> | 44 | avg_gap_ahead_1month                           当前价与前一个价差 |
> | 45 | avg_gap_after_1month                              当前价与后一个价差 |
> | 46 | avg_gap_ahead_ratio_1month |
> | 47 | avg_gap_after_ratio_1month |
> | 48 | pap_rank |
> | 49 | is_fangou |
> | 50 | show_fee_plist |
> | 51 | dt |


**（2）线上实际运行的特征**

<https://ether.intra.hongyibo.com.cn/model/10430?userModelId=15744>

> [!example]- 完整数据表（44 行记录）
> | | feature_name |
> | --- | --- |
> | 1 | h |
> | 2 | city_id |
> | 3 | day_of_work (由dt得到) |
> | 4 | avg_call_cp_cnt_1month |
> | 5 | avg_call_cp_cnt_ratio_1month |
> | 6 | avg_estimate_fee_amt |
> | 7 | avg_fee_scale_1month |
> | 8 | avg_gap_after_1month |
> | 9 | avg_gap_after_ratio_1month |
> | 10 | avg_gap_ahead_1month |
> | 11 | avg_gap_ahead_ratio_1month |
> | 12 | call_min_fee_cnt_1month |
> | 13 | call_min_fee_ratio_1month |
> | 14 | fangou_order_cnt_1month |
> | 15 | fangou_order_ratio_1month |
> | 16 | finish_order_cnt_1month |
> | 17 | is_upto_tj_ratio_1month |
> | 18 | is_upto_tjhezi_ratio_1month |
> | 19 | is_upto_tk_ratio_1month |
> | 20 | is_upto_tkhezi_ratio_1month |
> | 21 | is_upto_ykjia_ratio_1month |
> | 22 | jiagou_order_cnt_1month |
> | 23 | jiagou_order_ratio_1month |
> | 24 | max_basic_total_fee_amt |
> | 25 | max_call_cp_cnt_1month |
> | 26 | max_call_cp_cnt_ratio_1month |
> | 27 | max_estimate_fee_amt |
> | 28 | max_fee_scale_1month |
> | 29 | max_subsidy_rate |
> | 30 | median_estimate_fee_amt |
> | 31 | min_basic_total_fee_amt |
> | 32 | min_call_cp_cnt_1month |
> | 33 | min_call_cp_cnt_ratio_1month |
> | 34 | min_estimate_fee_amt |
> | 35 | min_fee_scale_1month |
> | 36 | min_fee_subsidy_amt |
> | 37 | min_fee_subsidy_rate |
> | 38 | order_cnt_1month |
> | 39 | pid_cr_1month |
> | 40 | product_cnt |
> | 41 | quarter_estimate_fee_amt |
> | 42 | start_dest_dis |
> | 43 | stddev_estimate_fee_amt |
> | 44 | three_quarter_estimate_fee_amt |


修改排序后的特征表

需要加入 **pap_rank** 和 **is_fangou** 两个字段，作为标签；加入 **show_fee_plist** 作为价格列表75维。

**（3）结合线上特征进行数据获取**

选择上述**44个基础特征**+**75价格特征**+**2标签特征**进行实验

提取所需数据的代码如下：

> [!example]- Python 实现细节（103 行）
> ```Python
> """
> 基于先前的代码，从Spark上拉取训练数据
> """
>
> # 第一步：配置spark
> import matplotlib
> import pandas as pd
> import numpy as np
> from pyspark import SparkConf
> from pyspark.context import SparkContext
>
> from pyspark.sql import SparkSession, SQLContext, HiveContext
> import findspark
>
> findspark.init()
>
> spark = SparkSession.builder \
>     .master("yarn") \
>     .appName("cgh") \
>     .config("spark.yarn.queue", "root.kflower_strategy_prod") \
>     .config("spark.kryoserializer.buffer.max", "1G") \
>     .config("spark.driver.memory", "12G") \
>     .config("spark.executor.memory", "8G") \
>     .config("spark.executor.cores", "4") \
>     .config("spark.executor.memoryOverhead", "6G") \
>     .config("spark.dynamicAllocation.minExecutors", "4") \
>     .config("spark.dynamicAllocation.maxExecutors", "100") \
>     .config("mapred.input.dir.recursive", "TRUE") \
>     .config("hive.mapred.supports.subdirectories", "TRUE") \
>     .config("spark.executorEnv.PYSPARK_PYTHON", "/home/odin/teddycheng/anaconda3/bin/python") \
>     .enableHiveSupport() \
>     .getOrCreate()
>
>
> # 第二步：获取数据并存储到hdfs上
> import os
>
> start_day = "2025-05-12"
> end_day = "2025-05-18"
>
> sql_string = """
>              select h, \
>                     city_id, \
>                     avg_call_cp_cnt_1month, \
>                     avg_call_cp_cnt_ratio_1month, \
>                     avg_estimate_fee_amt, \
>                     avg_fee_scale_1month, \
>                     avg_gap_after_1month, \
>                     avg_gap_after_ratio_1month, \
>                     avg_gap_ahead_1month, \
>                     avg_gap_ahead_ratio_1month, \
>                     call_min_fee_cnt_1month, \
>                     call_min_fee_ratio_1month, \
>                     fangou_order_cnt_1month, \
>                     fangou_order_ratio_1month, \
>                     finish_order_cnt_1month, \
>                     is_upto_tj_ratio_1month, \
>                     is_upto_tjhezi_ratio_1month, \
>                     is_upto_tk_ratio_1month, \
>                     is_upto_tkhezi_ratio_1month, \
>                     is_upto_ykjia_ratio_1month, \
>                     jiagou_order_cnt_1month, \
>                     jiagou_order_ratio_1month, \
>                     max_basic_total_fee_amt, \
>                     max_call_cp_cnt_1month, \
>                     max_call_cp_cnt_ratio_1month, \
>                     max_estimate_fee_amt, \
>                     max_fee_scale_1month, \
>                     max_subsidy_rate, \
>                     median_estimate_fee_amt, \
>                     min_basic_total_fee_amt, \
>                     min_call_cp_cnt_1month, \
>                     min_call_cp_cnt_ratio_1month, \
>                     min_estimate_fee_amt, \
>                     min_fee_scale_1month, \
>                     min_fee_subsidy_amt, \
>                     min_fee_subsidy_rate, \
>                     order_cnt_1month, \
>                     pid_cr_1month, \
>                     product_cnt, \
>                     quarter_estimate_fee_amt, \
>                     start_dest_dis, \
>                     stddev_estimate_fee_amt, \
>                     three_quarter_estimate_fee_amt, \
>                     pap_rank, \
>                     is_fangou, \
>                     cast(show_fee_plist as string) as show_fee_plist, \
>                     dt
>              from kflower_strategy.platform_union_dsar_training_with_full_user_modeling
>              where dt between '2025-05-12' and '2025-05-18'
>                and order_cnt_1month <= 5
>              order by rand() limit 5000000 \
>              """
>
> df = spark.sql(sql_string)
>
> hdfs_path = "hdfs:///user/prod_kflower_strategy/kflower_strategy/hdp/teddycheng/zhengyang/DSAR_new_feature1/"
> file = f"base_test_online_dsar_model_data_500w_{start_day}_{end_day}"
> fp = os.path.join(hdfs_path, file)
> df.repartition(1).write.csv(fp, header=True)
> print(f">>>>>>>>>>>> 已完成当前周期的文件获取 >>>>>>>>>>>>")
>
> # 第三步:从hdfs上获取数据，存储到服务器上 （可以从Linux控制台操作）
> ```


随后在Linux里把提取的数据从HDFS放到服务器中，进行下一步操作。

针对所提取数据，进行训练集和测试集的提取，处理代码如下：

> [!example]- Python 实现细节（155 行）
> ```Python
> # 01 数据预处理，对于nan数据赋0，并根据时间段进行训练集和测试集到划分
> import pandas as pd
> import numpy as np
> import torch
> from sklearn.model_selection import train_test_split
> import ast
>
>
> # 这里制定你想用到的df的字段
> MAX_LEN = 75
>
> selected_fields = """
> h,
> city_id,
> avg_call_cp_cnt_1month,
> avg_call_cp_cnt_ratio_1month,
> avg_estimate_fee_amt,
> avg_fee_scale_1month,
> avg_gap_after_1month,
> avg_gap_after_ratio_1month,
> avg_gap_ahead_1month,
> avg_gap_ahead_ratio_1month,
> call_min_fee_cnt_1month,
> call_min_fee_ratio_1month,
> fangou_order_cnt_1month,
> fangou_order_ratio_1month,
> finish_order_cnt_1month,
> is_upto_tj_ratio_1month,
> is_upto_tjhezi_ratio_1month,
> is_upto_tk_ratio_1month,
> is_upto_tkhezi_ratio_1month,
> is_upto_ykjia_ratio_1month,
> jiagou_order_cnt_1month,
> jiagou_order_ratio_1month,
> max_basic_total_fee_amt,
> max_call_cp_cnt_1month,
> max_call_cp_cnt_ratio_1month,
> max_estimate_fee_amt,
> max_fee_scale_1month,
> max_subsidy_rate,
> median_estimate_fee_amt,
> min_basic_total_fee_amt,
> min_call_cp_cnt_1month,
> min_call_cp_cnt_ratio_1month,
> min_estimate_fee_amt,
> min_fee_scale_1month,
> min_fee_subsidy_amt,
> min_fee_subsidy_rate,
> order_cnt_1month,
> pid_cr_1month,
> product_cnt,
> quarter_estimate_fee_amt,
> start_dest_dis,
> stddev_estimate_fee_amt,
> three_quarter_estimate_fee_amt,
> pap_rank,
> is_fangou,
> show_fee_plist,
> dt
> """
> cols = [item.strip() for item in selected_fields.strip().split(',')]
> print(f'>>>>>>>>>>>共需要处理{len(cols)}个字段')
>
>
> def split_price_list(df):
>     # 取出价格列表
>     price_list = df["show_fee_plist"]
>     # 得到星期几，放到第一列
>     df['dt'] = pd.to_datetime(df['dt'])
>     df['dayofweek'] = df['dt'].dt.dayofweek + 1
>     df.insert(1, 'dayofweek', df.pop('dayofweek'))
>
>     # 删除无用的列
>     df.drop(columns=["show_fee_plist", "dt"], inplace=True)
>     df = df.astype(np.float32)
>
>     # 对价格列进行处理，包括做MASK
>     price_list = price_list.map(lambda x: x[1:-1].split(","))
>     price_list_length = price_list.map(lambda x: len(x))
>     mask = price_list_length < MAX_LEN
>
>     # 对于不满75的做mask
>     df = df[mask] # 做了一遍筛选？ 似乎没有生效？或者是针对len <= 75的长度才做训练
>     price_list = price_list[mask]
>     # print(price_list.head(5).tolist())
>     price_list = price_list.map(lambda x: [float(i.strip()) if i.strip() else -1 for i in x])  # 转 float，空值补 -1
>     price_list = price_list.map(lambda x: x + [-1] * (MAX_LEN - len(x))) # 这里是对每一个价格列表 某一行补齐到75,如果没有，用-1表示
>     price_list = np.array(price_list.to_list()).astype(np.float32)
>
>     feature_np = df.to_numpy()
>
>     print(feature_np.dtype)
>     print(df.columns)
>     print(len(df.columns.to_list()))
>
>     # sparse和dense特征切割
>     sparse_and_dense = feature_np[:, :-2]
>     # rank和label特征标记
>     rank_and_label = feature_np[:, -2:]
>
>     print(f'sparse & dense格式：{sparse_and_dense.shape}, price_list格式：{price_list.shape}, rank_and_label格式：{rank_and_label.shape}') # 44， 75， 2
>     return np.hstack((sparse_and_dense, price_list, rank_and_label)) # 第一个是原始特征，第二个是75个价格列表带有mask的，第三个是标签（可能标签的获取涉及到前面SQL的判断）
>
>
> # 该函数的作用是处理得到的data_df文件，并转化为训练集与测试集（目前测试是用的随机划分）
> # def convert_csv_to_pt(data_df, classify_name):
> #     # 输入的数据维度是 3【sparse】 + 41【dense】 + 1【price_list】+ 2【labels】
> #     df = data_df[cols]
> #     df = df.fillna(0)
> #     df = df[df["pap_rank"] > 0]
> #
> #     print(f'======>>>>>>数据集长度：{len(df)}')
> #
> #     # 把数据转成能够直接进行运行的数据格式
> #     data_numpy = split_price_list(df).astype(np.float32)
> #     print(f'======>>>>>>训数据格式：{data_numpy.shape}')
> #
> #     # 存储为.pt文件
> #     torch.save(torch.from_numpy(data_numpy),
> #                f'/ofs/pltf-sub-and-pap/zhengyang/202505_project/DSAR_new_feature1/V2/datas/base_500w_{classify_name}_data.pt')
> def convert_csv_to_pt_chunked(file_path, classify_name, chunk_size = 100000):
>     chunk_iter = pd.read_csv(file_path, chunksize=chunk_size)
>     process_chunks = []
>
>     for i, chunk in enumerate(chunk_iter):
>         print(f'>>>>>>>>>>>><Processing> {i} <chunk>')
>         chunk = chunk[cols]
>         chunk = chunk.fillna(0)
>         chunk = chunk[chunk["pap_rank"] > 0]
>         if len(chunk) == 0:
>             continue
>         chunk_np = split_price_list(chunk).astype(np.float32)
>         process_chunks.append(torch.from_numpy(chunk_np))
>
>     # 合并所有的chunk,并存储
>     if process_chunks:
>         all_tensor = torch.cat(process_chunks, dim=0)
>         torch.save(all_tensor,
>                    f'/ofs/pltf-sub-and-pap/zhengyang/202505_project/DSAR_new_feature1/V2/datas/base_500w_{classify_name}_data.pt')
>         print(f'>>>>>>>>>>>><保存成功>，总样本数：{all_tensor.shape}<UNK>')
>
> # 获取数据
> def get_init_df(file_path):
>     df = pd.read_csv(file_path)
>     return df
>
>
> train_file_path = '/ofs/pltf-sub-and-pap/zhengyang/202505_project/DSAR_new_feature1/V2/datas/base_test_online_dsar_model_data_500w_2025-05-12_2025-05-18/part-00000-fddfe5cf-90f4-448f-b9ee-90783337e19d-c000.csv'
> test_file_path = '/ofs/pltf-sub-and-pap/zhengyang/202505_project/DSAR_new_feature1/V2/datas/base_test_online_dsar_model_data_500w_2025-05-19_2025-05-25/part-00000-3aabb80e-6f2b-4eba-9135-bd1c8f31697e-c000.csv'
>
> data_df_train = get_init_df(train_file_path)
> data_df_test = get_init_df(test_file_path)
>
> convert_csv_to_pt_chunked(train_file_path, 'train')
> convert_csv_to_pt_chunked(test_file_path, 'test')
> ```


**（4）数据策略**

本次对比实验，考虑到要在训练的数据量上进行差异对比，故涉及到250W和500W两个量级数据的准备。目前的策略：

收集2025-05-12到2025-05-18这周的500W数据作为**训练**数据

收集2025-05-19到2025-05-25这周的500W数据作为**验证**数据

- 在进行250W的训练时，从500W数据中随机拿1/2（250W）作为训练数据，验证数据是500W

- 在进行250W的训练时，把500W数据作为训练数据，验证数据是500W

以此保证数据的一致性

### 1.1.3 验证指标、对比维度

**（1）验证指标**

核心指标：**AUC + MAE**，本是是个二分类任务，输出是0 / 1，除了AUC以外，还拿到概率分数，来和0 / 1进行计算MAE分数。

**（2）对比的维度**

此次对比将从三个维度展开

- **训练策略对比**，什么样的训练策略最优（大grid上的搜索情况较好，便于下一步工作延伸开展）

- **数据量的对比**，250W和500W的数据训练对模型是否有影响

- **base和poso的对比**，看看两个模型架构哪个更好

### 1.1.4 运行结果

**（1）base_model的运行结果**

> [!example]- PlainText 实现细节（36 行）
> ```PlainText
> 2025-05-28 14:37:47.989 | INFO     | __main__:<module>:193 -  Epoch of 1:loss is 6975.75%,batchsize is 16384,lr is [0.00019850474670168042],auc is 86.74233%, mae is 28.89967%, precesion is 72.56947%,recall is 72.17329%,f1-score is 72.37084%,accuracy is 78.94076%,weight_decay is 0.00200%
> 2025-05-28 14:39:17.777 | INFO     | __main__:<module>:193 -  Epoch of 2:loss is 6388.21%,batchsize is 16384,lr is [0.00019480631043664284],auc is 87.07963%, mae is 28.32983%, precesion is 73.61958%,recall is 71.56749%,f1-score is 72.57903%,accuracy is 79.33433%,weight_decay is 0.00200%
> 2025-05-28 14:40:47.692 | INFO     | __main__:<module>:193 -  Epoch of 3:loss is 6267.53%,batchsize is 16384,lr is [0.00018971480662186157],auc is 87.12324%, mae is 28.10554%, precesion is 73.37241%,recall is 72.06442%,f1-score is 72.71253%,accuracy is 79.33017%,weight_decay is 0.00200%
> 2025-05-28 14:42:17.408 | INFO     | __main__:<module>:193 -  Epoch of 4:loss is 6181.94%,batchsize is 16384,lr is [0.00018331024831919505],auc is 87.08811%, mae is 27.96006%, precesion is 73.12720%,recall is 72.46180%,f1-score is 72.79298%,accuracy is 79.30036%,weight_decay is 0.00200%
> 2025-05-28 14:43:47.234 | INFO     | __main__:<module>:193 -  Epoch of 5:loss is 6108.54%,batchsize is 16384,lr is [0.00017569334825199377],auc is 87.01433%, mae is 27.82072%, precesion is 73.18355%,recall is 71.99407%,f1-score is 72.58394%,accuracy is 79.21627%,weight_decay is 0.00200%
> 2025-05-28 14:45:16.952 | INFO     | __main__:<module>:193 -  Epoch of 6:loss is 6038.84%,batchsize is 16384,lr is [0.00016698392539746915],auc is 86.93745%, mae is 27.77389%, precesion is 72.88145%,recall is 72.25369%,f1-score is 72.56621%,accuracy is 79.12274%,weight_decay is 0.00200%
> 2025-05-28 14:46:46.673 | INFO     | __main__:<module>:193 -  Epoch of 7:loss is 5972.05%,batchsize is 16384,lr is [0.00015731900947751968],auc is 86.80850%, mae is 27.67451%, precesion is 72.69739%,recall is 72.28834%,f1-score is 72.49229%,accuracy is 79.03509%,weight_decay is 0.00200%
> 2025-05-28 14:48:16.499 | INFO     | __main__:<module>:193 -  Epoch of 8:loss is 5904.94%,batchsize is 16384,lr is [0.00014685067282485607],auc is 86.70501%, mae is 27.57010%, precesion is 72.79998%,recall is 71.97806%,f1-score is 72.38669%,accuracy is 79.01437%,weight_decay is 0.00200%
> 2025-05-28 14:49:46.238 | INFO     | __main__:<module>:193 -  Epoch of 9:loss is 5841.79%,batchsize is 16384,lr is [0.00013574362324948375],auc is 86.55356%, mae is 27.50562%, precesion is 72.87282%,recall is 71.20779%,f1-score is 72.03068%,accuracy is 78.86735%,weight_decay is 0.00200%
> 2025-05-28 14:51:15.952 | INFO     | __main__:<module>:193 -  Epoch of 10:loss is 5780.99%,batchsize is 16384,lr is [0.00012417259505834288],auc is 86.41722%, mae is 27.56199%, precesion is 72.36032%,recall is 71.88499%,f1-score is 72.12188%,accuracy is 78.76282%,weight_decay is 0.00200%
> 2025-05-28 14:52:45.704 | INFO     | __main__:<module>:193 -  Epoch of 11:loss is 5719.88%,batchsize is 16384,lr is [0.00011231957817747883],auc is 86.29050%, mae is 27.50252%, precesion is 72.34184%,recall is 71.42459%,f1-score is 71.88029%,accuracy is 78.64444%,weight_decay is 0.00200%
> 2025-05-28 14:54:15.632 | INFO     | __main__:<module>:193 -  Epoch of 12:loss is 5664.91%,batchsize is 16384,lr is [0.00010037092724974396],auc is 86.14855%, mae is 27.53594%, precesion is 72.31122%,recall is 71.07620%,f1-score is 71.68840%,accuracy is 78.54631%,weight_decay is 0.00200%
> 2025-05-28 14:55:45.386 | INFO     | __main__:<module>:193 -  Epoch of 13:loss is 5611.36%,batchsize is 16384,lr is [8.85143934234081e-05],auc is 86.01347%, mae is 27.51120%, precesion is 72.45469%,recall is 70.32562%,f1-score is 71.37428%,accuracy is 78.44290%,weight_decay is 0.00200%
> 2025-05-28 14:57:18.028 | INFO     | __main__:<module>:193 -  Epoch of 14:loss is 5564.31%,batchsize is 16384,lr is [7.693612095933395e-05],auc is 85.89694%, mae is 27.50308%, precesion is 72.54716%,recall is 69.72222%,f1-score is 71.10664%,accuracy is 78.34685%,weight_decay is 0.00200%
> 2025-05-28 14:58:49.352 | INFO     | __main__:<module>:193 -  Epoch of 15:loss is 5519.57%,batchsize is 16384,lr is [6.58176481172423e-05],auc is 85.82547%, mae is 27.48658%, precesion is 72.29230%,recall is 70.02717%,f1-score is 71.14171%,accuracy is 78.28924%,weight_decay is 0.00200%
> 2025-05-28 15:00:19.151 | INFO     | __main__:<module>:193 -  Epoch of 16:loss is 5479.82%,batchsize is 16384,lr is [5.533294572308324e-05],auc is 85.74561%, mae is 27.50145%, precesion is 71.81760%,recall is 70.56357%,f1-score is 71.18506%,accuracy is 78.16911%,weight_decay is 0.00200%
> 2025-05-28 15:01:50.481 | INFO     | __main__:<module>:193 -  Epoch of 17:loss is 5444.67%,batchsize is 16384,lr is [4.5645514527745775e-05],auc is 85.66292%, mae is 27.45019%, precesion is 71.66161%,recall is 70.56357%,f1-score is 71.10835%,accuracy is 78.08738%,weight_decay is 0.00200%
> 2025-05-28 15:03:20.403 | INFO     | __main__:<module>:193 -  Epoch of 18:loss is 5412.34%,batchsize is 16384,lr is [3.690553735078684e-05],auc is 85.60822%, mae is 27.39768%, precesion is 71.65037%,recall is 70.46077%,f1-score is 71.05059%,accuracy is 78.05773%,weight_decay is 0.00200%
> 2025-05-28 15:04:51.507 | INFO     | __main__:<module>:193 -  Epoch of 19:loss is 5384.69%,batchsize is 16384,lr is [2.9247027575644716e-05],auc is 85.59231%, mae is 27.38006%, precesion is 71.53452%,recall is 70.59696%,f1-score is 71.06265%,accuracy is 78.02821%,weight_decay is 0.00200%
> 2025-05-28 15:06:35.255 | INFO     | __main__:<module>:193 -  Epoch of 20:loss is 5358.56%,batchsize is 16384,lr is [2.278478675218773e-05],auc is 85.55938%, mae is 27.37852%, precesion is 71.52608%,recall is 70.38519%,f1-score is 70.95105%,accuracy is 77.97504%,weight_decay is 0.00200%
> 2025-05-28 15:08:05.311 | INFO     | __main__:<module>:193 -  Epoch of 21:loss is 5334.54%,batchsize is 16384,lr is [1.7610643409926482e-05],auc is 85.52223%, mae is 27.36128%, precesion is 71.59580%,recall is 70.12012%,f1-score is 70.85028%,accuracy is 77.95056%,weight_decay is 0.00200%
> 2025-05-28 15:09:34.806 | INFO     | __main__:<module>:193 -  Epoch of 22:loss is 5316.21%,batchsize is 16384,lr is [1.3787411348611318e-05],auc is 85.49723%, mae is 27.32498%, precesion is 71.76102%,recall is 69.75834%,f1-score is 70.74551%,accuracy is 77.95288%,weight_decay is 0.00200%
> 2025-05-28 15:11:04.531 | INFO     | __main__:<module>:193 -  Epoch of 23:loss is 5298.84%,batchsize is 16384,lr is [1.1335260543845686e-05],auc is 85.48771%, mae is 27.30072%, precesion is 71.76953%,recall is 69.69846%,f1-score is 70.71883%,accuracy is 77.94340%,weight_decay is 0.00200%
> 2025-05-28 15:12:34.267 | INFO     | __main__:<module>:193 -  Epoch of 24:loss is 5284.23%,batchsize is 16384,lr is [1.0188017129392783e-05],auc is 85.47339%, mae is 27.28957%, precesion is 71.76305%,recall is 69.67752%,f1-score is 70.70491%,accuracy is 77.93520%,weight_decay is 0.00200%
> 2025-05-28 15:13:36.148 | INFO     | __main__:<module>:148 -  Switching optimizer to SGD with momentum...,switch_epoch is 25
> 2025-05-28 15:14:04.033 | INFO     | __main__:<module>:196 -  Epoch of 25:loss is 5272.63%,auc is 85.45690%, mae is 27.28286%, precesion is 71.71705%,recall is 69.65763%,f1-score is 70.67234%,accuracy is 77.90679%
> 2025-05-28 15:15:33.226 | INFO     | __main__:<module>:196 -  Epoch of 26:loss is 5254.35%,auc is 85.43958%, mae is 27.28523%, precesion is 71.73776%,recall is 69.55211%,f1-score is 70.62803%,accuracy is 77.89307%
> 2025-05-28 15:17:02.363 | INFO     | __main__:<module>:196 -  Epoch of 27:loss is 5253.93%,auc is 85.43849%, mae is 27.28740%, precesion is 71.73690%,recall is 69.54489%,f1-score is 70.62389%,accuracy is 77.89095%
> 2025-05-28 15:18:31.591 | INFO     | __main__:<module>:196 -  Epoch of 28:loss is 5252.74%,auc is 85.43797%, mae is 27.28893%, precesion is 71.73503%,recall is 69.54698%,f1-score is 70.62406%,accuracy is 77.89047%
> 2025-05-28 15:20:01.019 | INFO     | __main__:<module>:196 -  Epoch of 29:loss is 5252.21%,auc is 85.43729%, mae is 27.29022%, precesion is 71.73464%,recall is 69.54593%,f1-score is 70.62333%,accuracy is 77.89003%
> 2025-05-28 15:21:30.025 | INFO     | __main__:<module>:196 -  Epoch of 30:loss is 5250.99%,auc is 85.43676%, mae is 27.29117%, precesion is 71.72958%,recall is 69.54478%,f1-score is 70.62029%,accuracy is 77.88715%
> 2025-05-28 15:23:02.142 | INFO     | __main__:<module>:196 -  Epoch of 31:loss is 5250.49%,auc is 85.43611%, mae is 27.29194%, precesion is 71.72652%,recall is 69.54038%,f1-score is 70.61654%,accuracy is 77.88455%
> 2025-05-28 15:24:32.136 | INFO     | __main__:<module>:196 -  Epoch of 32:loss is 5250.60%,auc is 85.43567%, mae is 27.29245%, precesion is 71.72538%,recall is 69.53222%,f1-score is 70.61177%,accuracy is 77.88207%
> 2025-05-28 15:26:14.486 | INFO     | __main__:<module>:196 -  Epoch of 33:loss is 5250.59%,auc is 85.43507%, mae is 27.29284%, precesion is 71.72070%,recall is 69.52814%,f1-score is 70.60740%,accuracy is 77.87871%
> 2025-05-28 15:27:44.214 | INFO     | __main__:<module>:196 -  Epoch of 34:loss is 5249.30%,auc is 85.43452%, mae is 27.29319%, precesion is 71.71878%,recall is 69.52447%,f1-score is 70.60458%,accuracy is 77.87687%
> 2025-05-28 15:29:17.733 | INFO     | __main__:<module>:196 -  Epoch of 35:loss is 5249.15%,auc is 85.43409%, mae is 27.29322%, precesion is 71.71824%,recall is 69.52740%,f1-score is 70.60583%,accuracy is 77.87727%
> ```


> [!example]- PlainText 实现细节（41 行）
> ```PlainText
> 2025-05-28 17:35:10.235 | INFO     | __main__:<module>:210 -  Epoch of 1:loss is 6574.57%,batchsize is 16384,lr is [0.0019755752073205815],auc is 87.46865%, mae is 27.53242%, precesion is 73.97678%,recall is 72.59088%,f1-score is 73.27728%,accuracy is 79.76722%,weight_decay is 0.00200%
> 2025-05-28 17:36:39.902 | INFO     | __main__:<module>:210 -  Epoch of 2:loss is 6258.99%,batchsize is 16384,lr is [0.0019155242941128502],auc is 87.60826%, mae is 27.43573%, precesion is 74.25460%,recall is 72.53990%,f1-score is 73.38724%,accuracy is 79.89480%,weight_decay is 0.00200%
> 2025-05-28 17:38:09.981 | INFO     | __main__:<module>:210 -  Epoch of 3:loss is 6183.92%,batchsize is 16384,lr is [0.0018336407384582924],auc is 87.57479%, mae is 27.41359%, precesion is 74.12885%,recall is 72.55277%,f1-score is 73.33235%,accuracy is 79.83467%,weight_decay is 0.00200%
> 2025-05-28 17:39:39.599 | INFO     | __main__:<module>:210 -  Epoch of 4:loss is 6132.98%,batchsize is 16384,lr is [0.001731929423223569],auc is 87.53382%, mae is 27.24102%, precesion is 75.07806%,recall is 70.73295%,f1-score is 72.84076%,accuracy is 79.84295%,weight_decay is 0.00200%
> 2025-05-28 17:41:09.204 | INFO     | __main__:<module>:210 -  Epoch of 5:loss is 6087.04%,batchsize is 16384,lr is [0.001612882948904035],auc is 87.48871%, mae is 27.23433%, precesion is 75.55399%,recall is 69.85423%,f1-score is 72.59240%,accuracy is 79.84259%,weight_decay is 0.00200%
> 2025-05-28 17:42:39.047 | INFO     | __main__:<module>:210 -  Epoch of 6:loss is 6043.74%,batchsize is 16384,lr is [0.0014794199126881501],auc is 87.55095%, mae is 27.01709%, precesion is 75.95304%,recall is 69.21251%,f1-score is 72.42628%,accuracy is 79.86063%,weight_decay is 0.00200%
> 2025-05-28 17:44:09.068 | INFO     | __main__:<module>:210 -  Epoch of 7:loss is 5999.89%,batchsize is 16384,lr is [0.001334812614570576],auc is 87.44494%, mae is 26.99329%, precesion is 74.67097%,recall is 71.34357%,f1-score is 72.96936%,accuracy is 79.80086%,weight_decay is 0.00200%
> 2025-05-28 17:45:38.841 | INFO     | __main__:<module>:210 -  Epoch of 8:loss is 5945.48%,batchsize is 16384,lr is [0.0011826059175833808],auc is 87.39066%, mae is 26.74112%, precesion is 74.31648%,recall is 71.68055%,f1-score is 72.97472%,accuracy is 79.71097%,weight_decay is 0.00200%
> 2025-05-28 17:47:08.558 | INFO     | __main__:<module>:210 -  Epoch of 9:loss is 5888.87%,batchsize is 16384,lr is [0.001026529177460072],auc is 87.26734%, mae is 26.75273%, precesion is 74.25301%,recall is 71.24443%,f1-score is 72.71762%,accuracy is 79.57060%,weight_decay is 0.00200%
> 2025-05-28 17:48:38.328 | INFO     | __main__:<module>:210 -  Epoch of 10:loss is 5824.64%,batchsize is 16384,lr is [0.0008704032740976682],auc is 87.09460%, mae is 26.80447%, precesion is 73.60107%,recall is 71.84898%,f1-score is 72.71447%,accuracy is 79.39397%,weight_decay is 0.00200%
> 2025-05-28 17:50:08.056 | INFO     | __main__:<module>:210 -  Epoch of 11:loss is 5751.45%,batchsize is 16384,lr is [0.0007180447977131023],auc is 87.02914%, mae is 26.73803%, precesion is 73.41806%,recall is 71.94948%,f1-score is 72.67635%,accuracy is 79.32549%,weight_decay is 0.00200%
> 2025-05-28 17:51:37.803 | INFO     | __main__:<module>:210 -  Epoch of 12:loss is 5669.60%,batchsize is 16384,lr is [0.0005731693173844226],auc is 86.93831%, mae is 26.56024%, precesion is 73.37430%,recall is 71.66118%,f1-score is 72.50762%,accuracy is 79.23295%,weight_decay is 0.00200%
> 2025-05-28 17:53:07.829 | INFO     | __main__:<module>:210 -  Epoch of 13:loss is 5580.59%,batchsize is 16384,lr is [0.000439295279461272],auc is 86.73012%, mae is 26.46962%, precesion is 73.87957%,recall is 69.86616%,f1-score is 71.81684%,accuracy is 79.04477%,weight_decay is 0.00200%
> 2025-05-28 17:54:37.614 | INFO     | __main__:<module>:210 -  Epoch of 14:loss is 5482.71%,batchsize is 16384,lr is [0.0003196491785505438],auc is 86.54804%, mae is 26.34322%, precesion is 73.18009%,recall is 70.59005%,f1-score is 71.86174%,accuracy is 78.87459%,weight_decay is 0.00200%
> 2025-05-28 17:56:07.343 | INFO     | __main__:<module>:210 -  Epoch of 15:loss is 5377.29%,batchsize is 16384,lr is [0.00021707047943692935],auc is 86.24463%, mae is 26.42367%, precesion is 72.79225%,recall is 70.65517%,f1-score is 71.70779%,accuracy is 78.69377%,weight_decay is 0.00200%
> 2025-05-28 17:57:36.934 | INFO     | __main__:<module>:210 -  Epoch of 16:loss is 5272.25%,batchsize is 16384,lr is [0.00013390910258153139],auc is 85.90538%, mae is 26.57708%, precesion is 72.77067%,recall is 69.73698%,f1-score is 71.22154%,accuracy is 78.46318%,weight_decay is 0.00200%
> 2025-05-28 17:59:06.685 | INFO     | __main__:<module>:210 -  Epoch of 17:loss is 5173.91%,batchsize is 16384,lr is [7.189126536137628e-05],auc is 85.84787%, mae is 26.40101%, precesion is 72.73857%,recall is 69.51913%,f1-score is 71.09242%,accuracy is 78.39497%,weight_decay is 0.00200%
> 2025-05-28 18:00:36.490 | INFO     | __main__:<module>:210 -  Epoch of 18:loss is 5082.98%,batchsize is 16384,lr is [3.186816464409299e-05],auc is 85.68065%, mae is 26.25160%, precesion is 72.17548%,recall is 69.92081%,f1-score is 71.03026%,accuracy is 78.20435%,weight_decay is 0.00200%
> 2025-05-28 18:02:06.427 | INFO     | __main__:<module>:210 -  Epoch of 19:loss is 5012.47%,batchsize is 16384,lr is [1.308149443191136e-05],auc is 85.45860%, mae is 26.34710%, precesion is 72.00863%,recall is 69.58006%,f1-score is 70.77352%,accuracy is 78.03897%,weight_decay is 0.00200%
> 2025-05-28 18:03:08.445 | INFO     | __main__:<module>:165 -  Switching optimizer to SGD with momentum...,switch_epoch is 20
> 2025-05-28 18:03:36.182 | INFO     | __main__:<module>:213 -  Epoch of 20:loss is 4958.61%,auc is 85.37719%, mae is 26.47312%, precesion is 72.02049%,recall is 69.24162%,f1-score is 70.60372%,accuracy is 77.96596%
> 2025-05-28 18:05:05.637 | INFO     | __main__:<module>:213 -  Epoch of 21:loss is 4926.24%,auc is 85.38325%, mae is 26.48882%, precesion is 71.83857%,recall is 69.58351%,f1-score is 70.69306%,accuracy is 77.95236%
> 2025-05-28 18:06:34.731 | INFO     | __main__:<module>:213 -  Epoch of 22:loss is 4925.00%,auc is 85.38816%, mae is 26.48105%, precesion is 71.85511%,recall is 69.56027%,f1-score is 70.68907%,accuracy is 77.95548%
> 2025-05-28 18:08:03.880 | INFO     | __main__:<module>:213 -  Epoch of 23:loss is 4924.65%,auc is 85.39204%, mae is 26.47482%, precesion is 71.87610%,recall is 69.54583%,f1-score is 70.69177%,accuracy is 77.96292%
> 2025-05-28 18:09:33.219 | INFO     | __main__:<module>:213 -  Epoch of 24:loss is 4923.13%,auc is 85.39511%, mae is 26.46985%, precesion is 71.88923%,recall is 69.53107%,f1-score is 70.69049%,accuracy is 77.96624%
> 2025-05-28 18:11:02.316 | INFO     | __main__:<module>:213 -  Epoch of 25:loss is 4922.27%,auc is 85.39748%, mae is 26.46588%, precesion is 71.90032%,recall is 69.52772%,f1-score is 70.69412%,accuracy is 77.97116%
> 2025-05-28 18:12:31.432 | INFO     | __main__:<module>:213 -  Epoch of 26:loss is 4922.08%,auc is 85.39955%, mae is 26.46222%, precesion is 71.90993%,recall is 69.51578%,f1-score is 70.69259%,accuracy is 77.97332%
> 2025-05-28 18:14:00.802 | INFO     | __main__:<module>:213 -  Epoch of 27:loss is 4921.05%,auc is 85.40121%, mae is 26.45912%, precesion is 71.91961%,recall is 69.50887%,f1-score is 70.69370%,accuracy is 77.97668%
> 2025-05-28 18:15:30.220 | INFO     | __main__:<module>:213 -  Epoch of 28:loss is 4921.42%,auc is 85.40243%, mae is 26.45681%, precesion is 71.92532%,recall is 69.50144%,f1-score is 70.69261%,accuracy is 77.97788%
> 2025-05-28 18:16:59.498 | INFO     | __main__:<module>:213 -  Epoch of 29:loss is 4919.70%,auc is 85.40343%, mae is 26.45467%, precesion is 71.93115%,recall is 69.50165%,f1-score is 70.69553%,accuracy is 77.98092%
> 2025-05-28 18:18:28.682 | INFO     | __main__:<module>:213 -  Epoch of 30:loss is 4920.18%,auc is 85.40377%, mae is 26.45322%, precesion is 71.93290%,recall is 69.49778%,f1-score is 70.69438%,accuracy is 77.98092%
> 2025-05-28 18:19:57.804 | INFO     | __main__:<module>:213 -  Epoch of 31:loss is 4919.38%,auc is 85.40415%, mae is 26.45178%, precesion is 71.93053%,recall is 69.49014%,f1-score is 70.68928%,accuracy is 77.97792%
> 2025-05-28 18:21:26.827 | INFO     | __main__:<module>:213 -  Epoch of 32:loss is 4918.20%,auc is 85.40431%, mae is 26.45040%, precesion is 71.93955%,recall is 69.49464%,f1-score is 70.69596%,accuracy is 77.98360%
> 2025-05-28 18:22:55.801 | INFO     | __main__:<module>:213 -  Epoch of 33:loss is 4917.45%,auc is 85.40450%, mae is 26.44905%, precesion is 71.93834%,recall is 69.48993%,f1-score is 70.69294%,accuracy is 77.98188%
> 2025-05-28 18:24:24.922 | INFO     | __main__:<module>:213 -  Epoch of 34:loss is 4918.29%,auc is 85.40451%, mae is 26.44795%, precesion is 71.93973%,recall is 69.48773%,f1-score is 70.69247%,accuracy is 77.98208%
> 2025-05-28 18:25:53.968 | INFO     | __main__:<module>:213 -  Epoch of 35:loss is 4917.66%,auc is 85.40445%, mae is 26.44705%, precesion is 71.93918%,recall is 69.48344%,f1-score is 70.68999%,accuracy is 77.98080%
> 2025-05-28 18:27:23.157 | INFO     | __main__:<module>:213 -  Epoch of 36:loss is 4917.88%,auc is 85.40425%, mae is 26.44634%, precesion is 71.94003%,recall is 69.48448%,f1-score is 70.69094%,accuracy is 77.98148%
> 2025-05-28 18:28:52.283 | INFO     | __main__:<module>:213 -  Epoch of 37:loss is 4917.95%,auc is 85.40368%, mae is 26.44620%, precesion is 71.93760%,recall is 69.48092%,f1-score is 70.68792%,accuracy is 77.97940%
> 2025-05-28 18:30:21.372 | INFO     | __main__:<module>:213 -  Epoch of 38:loss is 4917.11%,auc is 85.40311%, mae is 26.44550%, precesion is 71.93634%,recall is 69.47632%,f1-score is 70.68493%,accuracy is 77.97768%
> 2025-05-28 18:31:50.542 | INFO     | __main__:<module>:213 -  Epoch of 39:loss is 4916.47%,auc is 85.40272%, mae is 26.44479%, precesion is 71.93420%,recall is 69.47244%,f1-score is 70.68189%,accuracy is 77.97568%
> 2025-05-28 18:33:19.623 | INFO     | __main__:<module>:213 -  Epoch of 40:loss is 4915.83%,auc is 85.40236%, mae is 26.44404%, precesion is 71.93194%,recall is 69.46711%,f1-score is 70.67804%,accuracy is 77.97328%
> ```


> [!example]- PlainText 实现细节（46 行）
> ```PlainText
> 2025-05-29 17:02:44.226 | INFO     | __main__:<module>:208 -  Epoch of 1:loss is 7916.74%,batchsize is 16384,lr is [0.019754647434340918],auc is 87.23958%, mae is 29.33138%, precesion is 75.23617%,recall is 69.41737%,f1-score is 72.20974%,accuracy is 79.56240%,weight_decay is 0.00200%
> 2025-05-29 17:04:42.830 | INFO     | __main__:<module>:208 -  Epoch of 2:loss is 6390.80%,batchsize is 16384,lr is [0.019151422431817024],auc is 87.58677%, mae is 28.46438%, precesion is 75.71492%,recall is 69.80069%,f1-score is 72.63761%,accuracy is 79.88515%,weight_decay is 0.00200%
> 2025-05-29 17:06:41.376 | INFO     | __main__:<module>:208 -  Epoch of 3:loss is 6339.38%,batchsize is 16384,lr is [0.018328883598885057],auc is 87.64311%, mae is 28.44947%, precesion is 73.58138%,recall is 73.84912%,f1-score is 73.71501%,accuracy is 79.85524%,weight_decay is 0.00200%
> 2025-05-29 17:08:39.881 | INFO     | __main__:<module>:208 -  Epoch of 4:loss is 6299.64%,batchsize is 16384,lr is [0.0173071704373061],auc is 87.66316%, mae is 28.28964%, precesion is 75.45930%,recall is 70.56951%,f1-score is 72.93254%,accuracy is 79.96414%,weight_decay is 0.00200%
> 2025-05-29 17:10:38.626 | INFO     | __main__:<module>:208 -  Epoch of 5:loss is 6285.48%,batchsize is 16384,lr is [0.016111321682709373],auc is 87.66842%, mae is 28.28545%, precesion is 74.09734%,recall is 73.09682%,f1-score is 73.59368%,accuracy is 79.93539%,weight_decay is 0.00200%
> 2025-05-29 17:12:37.149 | INFO     | __main__:<module>:208 -  Epoch of 6:loss is 6267.99%,batchsize is 16384,lr is [0.014770655303837246],auc is 87.77707%, mae is 27.93738%, precesion is 76.76594%,recall is 68.69823%,f1-score is 72.50836%,accuracy is 80.07387%,weight_decay is 0.00200%
> 2025-05-29 17:14:35.597 | INFO     | __main__:<module>:208 -  Epoch of 7:loss is 6250.84%,batchsize is 16384,lr is [0.013318042294103423],auc is 87.75118%, mae is 27.72032%, precesion is 77.11929%,recall is 67.86174%,f1-score is 72.19495%,accuracy is 80.00568%,weight_decay is 0.00200%
> 2025-05-29 17:16:34.011 | INFO     | __main__:<module>:208 -  Epoch of 8:loss is 6235.87%,batchsize is 16384,lr is [0.011789091604267225],auc is 87.79727%, mae is 27.83467%, precesion is 80.05185%,recall is 61.63020%,f1-score is 69.64342%,accuracy is 79.44909%,weight_decay is 0.00200%
> 2025-05-29 17:18:32.371 | INFO     | __main__:<module>:208 -  Epoch of 9:loss is 6217.44%,batchsize is 16384,lr is [0.010221265455993386],auc is 87.79119%, mae is 27.57271%, precesion is 80.89701%,recall is 59.81754%,f1-score is 68.77839%,accuracy is 79.22712%,weight_decay is 0.00200%
> 2025-05-29 17:20:31.367 | INFO     | __main__:<module>:208 -  Epoch of 10:loss is 6201.31%,batchsize is 16384,lr is [0.008652945451865521],auc is 87.87794%, mae is 27.81370%, precesion is 78.78763%,recall is 64.72390%,f1-score is 71.06666%,accuracy is 79.84132%,weight_decay is 0.00200%
> 2025-05-29 17:22:30.444 | INFO     | __main__:<module>:208 -  Epoch of 11:loss is 6186.28%,batchsize is 16384,lr is [0.007122470103660761],auc is 87.95697%, mae is 27.74195%, precesion is 77.17823%,recall is 68.64233%,f1-score is 72.66044%,accuracy is 80.24167%,weight_decay is 0.00200%
> 2025-05-29 17:24:29.447 | INFO     | __main__:<module>:208 -  Epoch of 12:loss is 6163.93%,batchsize is 16384,lr is [0.005667163142972163],auc is 88.05595%, mae is 27.58467%, precesion is 74.90680%,recall is 73.10764%,f1-score is 73.99629%,accuracy is 80.34590%,weight_decay is 0.00200%
> 2025-05-29 17:26:28.496 | INFO     | __main__:<module>:208 -  Epoch of 13:loss is 6144.00%,batchsize is 16384,lr is [0.004322368159010465],auc is 88.04147%, mae is 27.65856%, precesion is 78.82852%,recall is 65.51322%,f1-score is 71.55672%,accuracy is 80.07845%,weight_decay is 0.00200%
> 2025-05-29 17:28:27.332 | INFO     | __main__:<module>:208 -  Epoch of 14:loss is 6123.22%,batchsize is 16384,lr is [0.0031204960197112413],auc is 88.07205%, mae is 27.86929%, precesion is 78.17806%,recall is 66.85853%,f1-score is 72.07658%,accuracy is 80.18490%,weight_decay is 0.00200%
> 2025-05-29 17:30:26.177 | INFO     | __main__:<module>:208 -  Epoch of 15:loss is 6100.88%,batchsize is 16384,lr is [0.0020900697909267425],auc is 88.12763%, mae is 27.64157%, precesion is 77.59659%,recall is 68.27115%,f1-score is 72.63578%,accuracy is 80.32410%,weight_decay is 0.00200%
> 2025-05-29 17:32:25.185 | INFO     | __main__:<module>:208 -  Epoch of 16:loss is 6075.41%,batchsize is 16384,lr is [0.001254694955077795],auc is 88.13596%, mae is 27.32614%, precesion is 77.75505%,recall is 68.05815%,f1-score is 72.58417%,accuracy is 80.33452%,weight_decay is 0.00200%
> 2025-05-29 17:34:23.968 | INFO     | __main__:<module>:208 -  Epoch of 17:loss is 6045.00%,batchsize is 16384,lr is [0.0006317117560672925],auc is 88.05206%, mae is 27.17028%, precesion is 75.63327%,recall is 71.67495%,f1-score is 73.60093%,accuracy is 80.33302%,weight_decay is 0.00200%
> 2025-05-29 17:36:22.659 | INFO     | __main__:<module>:208 -  Epoch of 18:loss is 6012.42%,batchsize is 16384,lr is [0.00022967065891227074],auc is 88.05950%, mae is 27.05397%, precesion is 75.70216%,recall is 71.51205%,f1-score is 73.54748%,accuracy is 80.32370%,weight_decay is 0.00200%
> 2025-05-29 17:38:21.383 | INFO     | __main__:<module>:208 -  Epoch of 19:loss is 5979.57%,batchsize is 16384,lr is [4.095430838889852e-05],auc is 88.04793%, mae is 26.79939%, precesion is 74.96109%,recall is 72.71434%,f1-score is 73.82063%,accuracy is 80.27275%,weight_decay is 0.00200%
> 2025-05-29 17:39:23.401 | INFO     | __main__:<module>:163 -  Switching optimizer to SGD with momentum...,switch_epoch is 20
> 2025-05-29 17:40:20.427 | INFO     | __main__:<module>:211 -  Epoch of 20:loss is 5951.78%,auc is 88.03874%, mae is 26.74856%, precesion is 75.31313%,recall is 72.08493%,f1-score is 73.66368%,accuracy is 80.28436%
> 2025-05-29 17:42:18.708 | INFO     | __main__:<module>:211 -  Epoch of 21:loss is 5940.94%,auc is 88.03624%, mae is 26.72421%, precesion is 75.31379%,recall is 72.07489%,f1-score is 73.65875%,accuracy is 80.28210%
> 2025-05-29 17:44:16.981 | INFO     | __main__:<module>:211 -  Epoch of 22:loss is 5940.54%,auc is 88.03643%, mae is 26.72587%, precesion is 75.31832%,recall is 72.07217%,f1-score is 73.65950%,accuracy is 80.28360%
> 2025-05-29 17:46:15.107 | INFO     | __main__:<module>:211 -  Epoch of 23:loss is 5940.31%,auc is 88.03668%, mae is 26.72828%, precesion is 75.32180%,recall is 72.07594%,f1-score is 73.66313%,accuracy is 80.28626%
> 2025-05-29 17:48:12.976 | INFO     | __main__:<module>:211 -  Epoch of 24:loss is 5939.75%,auc is 88.03678%, mae is 26.72952%, precesion is 75.32278%,recall is 72.07416%,f1-score is 73.66267%,accuracy is 80.28628%
> 2025-05-29 17:50:11.688 | INFO     | __main__:<module>:211 -  Epoch of 25:loss is 5939.74%,auc is 88.03687%, mae is 26.73076%, precesion is 75.32171%,recall is 72.07432%,f1-score is 73.66224%,accuracy is 80.28580%
> 2025-05-29 17:52:10.046 | INFO     | __main__:<module>:211 -  Epoch of 26:loss is 5939.64%,auc is 88.03698%, mae is 26.73232%, precesion is 75.32646%,recall is 72.07468%,f1-score is 73.66470%,accuracy is 80.28820%
> 2025-05-29 17:54:08.038 | INFO     | __main__:<module>:211 -  Epoch of 27:loss is 5940.40%,auc is 88.03696%, mae is 26.73316%, precesion is 75.32418%,recall is 72.07081%,f1-score is 73.66159%,accuracy is 80.28610%
> 2025-05-29 17:56:06.102 | INFO     | __main__:<module>:211 -  Epoch of 28:loss is 5939.73%,auc is 88.03700%, mae is 26.73372%, precesion is 75.32938%,recall is 72.06668%,f1-score is 73.66192%,accuracy is 80.28756%
> 2025-05-29 17:58:03.907 | INFO     | __main__:<module>:211 -  Epoch of 29:loss is 5939.89%,auc is 88.03708%, mae is 26.73471%, precesion is 75.32688%,recall is 72.06579%,f1-score is 73.66026%,accuracy is 80.28612%
> 2025-05-29 18:00:01.737 | INFO     | __main__:<module>:211 -  Epoch of 30:loss is 5939.81%,auc is 88.03709%, mae is 26.73534%, precesion is 75.32942%,recall is 72.06239%,f1-score is 73.65970%,accuracy is 80.28648%
> 2025-05-29 18:01:59.611 | INFO     | __main__:<module>:211 -  Epoch of 31:loss is 5939.77%,auc is 88.03715%, mae is 26.73604%, precesion is 75.32755%,recall is 72.06266%,f1-score is 73.65894%,accuracy is 80.28564%
> 2025-05-29 18:03:57.470 | INFO     | __main__:<module>:211 -  Epoch of 32:loss is 5939.36%,auc is 88.03723%, mae is 26.73642%, precesion is 75.32643%,recall is 72.05988%,f1-score is 73.65696%,accuracy is 80.28438%
> 2025-05-29 18:05:55.274 | INFO     | __main__:<module>:211 -  Epoch of 33:loss is 5939.71%,auc is 88.03728%, mae is 26.73707%, precesion is 75.32573%,recall is 72.05957%,f1-score is 73.65646%,accuracy is 80.28396%
> 2025-05-29 18:07:53.328 | INFO     | __main__:<module>:211 -  Epoch of 34:loss is 5939.98%,auc is 88.03728%, mae is 26.73720%, precesion is 75.32841%,recall is 72.05816%,f1-score is 73.65701%,accuracy is 80.28490%
> 2025-05-29 18:09:51.222 | INFO     | __main__:<module>:211 -  Epoch of 35:loss is 5940.13%,auc is 88.03731%, mae is 26.73781%, precesion is 75.32856%,recall is 72.06145%,f1-score is 73.65880%,accuracy is 80.28582%
> 2025-05-29 18:11:49.031 | INFO     | __main__:<module>:211 -  Epoch of 36:loss is 5939.88%,auc is 88.03735%, mae is 26.73796%, precesion is 75.32960%,recall is 72.06036%,f1-score is 73.65872%,accuracy is 80.28604%
> 2025-05-29 18:13:47.165 | INFO     | __main__:<module>:211 -  Epoch of 37:loss is 5939.77%,auc is 88.03740%, mae is 26.73862%, precesion is 75.32867%,recall is 72.06396%,f1-score is 73.66016%,accuracy is 80.28652%
> 2025-05-29 18:15:45.424 | INFO     | __main__:<module>:211 -  Epoch of 38:loss is 5939.26%,auc is 88.03743%, mae is 26.73835%, precesion is 75.32948%,recall is 72.06423%,f1-score is 73.66069%,accuracy is 80.28698%
> 2025-05-29 18:17:43.767 | INFO     | __main__:<module>:211 -  Epoch of 39:loss is 5939.82%,auc is 88.03753%, mae is 26.73829%, precesion is 75.33268%,recall is 72.06145%,f1-score is 73.66077%,accuracy is 80.28782%
> 2025-05-29 18:19:41.885 | INFO     | __main__:<module>:211 -  Epoch of 40:loss is 5939.13%,auc is 88.03754%, mae is 26.73847%, precesion is 75.33104%,recall is 72.06098%,f1-score is 73.65973%,accuracy is 80.28690%
> 2025-05-29 18:21:39.967 | INFO     | __main__:<module>:211 -  Epoch of 41:loss is 5939.11%,auc is 88.03754%, mae is 26.73868%, precesion is 75.33118%,recall is 72.06187%,f1-score is 73.66027%,accuracy is 80.28720%
> 2025-05-29 18:23:38.228 | INFO     | __main__:<module>:211 -  Epoch of 42:loss is 5939.09%,auc is 88.03762%, mae is 26.73877%, precesion is 75.33073%,recall is 72.06172%,f1-score is 73.65997%,accuracy is 80.28694%
> 2025-05-29 18:25:36.805 | INFO     | __main__:<module>:211 -  Epoch of 43:loss is 5939.41%,auc is 88.03762%, mae is 26.73902%, precesion is 75.33036%,recall is 72.06093%,f1-score is 73.65939%,accuracy is 80.28656%
> 2025-05-29 18:27:35.100 | INFO     | __main__:<module>:211 -  Epoch of 44:loss is 5939.33%,auc is 88.03764%, mae is 26.73890%, precesion is 75.33070%,recall is 72.06161%,f1-score is 73.65990%,accuracy is 80.28690%
> 2025-05-29 18:29:33.513 | INFO     | __main__:<module>:211 -  Epoch of 45:loss is 5939.57%,auc is 88.03767%, mae is 26.73912%, precesion is 75.32987%,recall is 72.06318%,f1-score is 73.66033%,accuracy is 80.28690%
> ```


> [!example]- PlainText 实现细节（44 行）
> ```PlainText
> 2025-05-29 11:53:20.292 | INFO     | __main__:<module>:208 -  Epoch of 1:loss is 14714.67%,batchsize is 16384,lr is [0.019754647434340918],auc is 87.25986%, mae is 29.56912%, precesion is 74.18277%,recall is 71.21790%,f1-score is 72.67011%,accuracy is 79.51028%,weight_decay is 0.00200%
> 2025-05-29 11:56:21.103 | INFO     | __main__:<module>:208 -  Epoch of 2:loss is 12711.25%,batchsize is 16384,lr is [0.019151422431817024],auc is 87.56387%, mae is 28.52096%, precesion is 77.14811%,recall is 66.81157%,f1-score is 71.60875%,accuracy is 79.73555%,weight_decay is 0.00200%
> 2025-05-29 11:59:21.723 | INFO     | __main__:<module>:208 -  Epoch of 3:loss is 12621.26%,batchsize is 16384,lr is [0.018328883598885057],auc is 87.68780%, mae is 27.78594%, precesion is 75.00851%,recall is 71.22935%,f1-score is 73.07010%,accuracy is 79.91745%,weight_decay is 0.00200%
> 2025-05-29 12:02:22.084 | INFO     | __main__:<module>:208 -  Epoch of 4:loss is 12548.67%,batchsize is 16384,lr is [0.0173071704373061],auc is 87.81414%, mae is 28.08271%, precesion is 84.36929%,recall is 50.32631%,f1-score is 63.04579%,accuracy is 77.43331%,weight_decay is 0.00200%
> 2025-05-29 12:05:22.850 | INFO     | __main__:<module>:208 -  Epoch of 5:loss is 12496.62%,batchsize is 16384,lr is [0.016111321682709373],auc is 87.76523%, mae is 27.67248%, precesion is 81.36607%,recall is 57.96163%,f1-score is 67.69809%,accuracy is 78.84285%,weight_decay is 0.00200%
> 2025-05-29 12:08:23.158 | INFO     | __main__:<module>:208 -  Epoch of 6:loss is 12459.07%,batchsize is 16384,lr is [0.014770655303837246],auc is 87.78867%, mae is 27.23396%, precesion is 81.71520%,recall is 57.49987%,f1-score is 67.50151%,accuracy is 78.82217%,weight_decay is 0.00200%
> 2025-05-29 12:11:23.561 | INFO     | __main__:<module>:208 -  Epoch of 7:loss is 12419.02%,batchsize is 16384,lr is [0.013318042294103423],auc is 87.97213%, mae is 27.33594%, precesion is 77.87706%,recall is 67.10008%,f1-score is 72.08801%,accuracy is 80.12462%,weight_decay is 0.00200%
> 2025-05-29 12:14:24.083 | INFO     | __main__:<module>:208 -  Epoch of 8:loss is 12395.78%,batchsize is 16384,lr is [0.011789091604267225],auc is 87.96843%, mae is 27.10682%, precesion is 79.45797%,recall is 63.48820%,f1-score is 70.58102%,accuracy is 79.75595%,weight_decay is 0.00200%
> 2025-05-29 12:17:24.657 | INFO     | __main__:<module>:208 -  Epoch of 9:loss is 12362.97%,batchsize is 16384,lr is [0.010221265455993386],auc is 88.04914%, mae is 27.12340%, precesion is 82.86372%,recall is 56.24043%,f1-score is 67.00435%,accuracy is 78.81311%,weight_decay is 0.00200%
> 2025-05-29 12:20:25.226 | INFO     | __main__:<module>:208 -  Epoch of 10:loss is 12329.75%,batchsize is 16384,lr is [0.008652945451865521],auc is 88.10863%, mae is 27.24197%, precesion is 82.57704%,recall is 57.21649%,f1-score is 67.59638%,accuracy is 79.01756%,weight_decay is 0.00200%
> 2025-05-29 12:23:25.607 | INFO     | __main__:<module>:208 -  Epoch of 11:loss is 12301.64%,batchsize is 16384,lr is [0.007122470103660761],auc is 88.09420%, mae is 27.36268%, precesion is 81.61067%,recall is 59.25820%,f1-score is 68.66104%,accuracy is 79.30871%,weight_decay is 0.00200%
> 2025-05-29 12:26:26.360 | INFO     | __main__:<module>:208 -  Epoch of 12:loss is 12269.46%,batchsize is 16384,lr is [0.005667163142972163],auc is 88.14445%, mae is 26.91591%, precesion is 79.02955%,recall is 65.16332%,f1-score is 71.42972%,accuracy is 80.06099%,weight_decay is 0.00200%
> 2025-05-29 12:29:27.028 | INFO     | __main__:<module>:208 -  Epoch of 13:loss is 12233.36%,batchsize is 16384,lr is [0.004322368159010465],auc is 88.10856%, mae is 26.93816%, precesion is 78.26452%,recall is 66.73831%,f1-score is 72.04331%,accuracy is 80.18782%,weight_decay is 0.00200%
> 2025-05-29 12:32:27.470 | INFO     | __main__:<module>:208 -  Epoch of 14:loss is 12200.79%,batchsize is 16384,lr is [0.0031204960197112413],auc is 88.12457%, mae is 26.83975%, precesion is 76.22827%,recall is 70.83940%,f1-score is 73.43511%,accuracy is 80.39603%,weight_decay is 0.00200%
> 2025-05-29 12:35:28.580 | INFO     | __main__:<module>:208 -  Epoch of 15:loss is 12162.61%,batchsize is 16384,lr is [0.0020900697909267425],auc is 88.22503%, mae is 26.77921%, precesion is 77.20974%,recall is 69.34322%,f1-score is 73.06536%,accuracy is 80.44452%,weight_decay is 0.00200%
> 2025-05-29 12:38:29.346 | INFO     | __main__:<module>:208 -  Epoch of 16:loss is 12118.22%,batchsize is 16384,lr is [0.001254694955077795],auc is 88.21925%, mae is 26.74598%, precesion is 75.68484%,recall is 72.01836%,f1-score is 73.80609%,accuracy is 80.44688%,weight_decay is 0.00200%
> 2025-05-29 12:41:30.331 | INFO     | __main__:<module>:208 -  Epoch of 17:loss is 12070.45%,batchsize is 16384,lr is [0.0006317117560672925],auc is 88.22118%, mae is 26.56012%, precesion is 76.00237%,recall is 71.58814%,f1-score is 73.72924%,accuracy is 80.48634%,weight_decay is 0.00200%
> 2025-05-29 12:44:31.116 | INFO     | __main__:<module>:208 -  Epoch of 18:loss is 12016.68%,batchsize is 16384,lr is [0.00022967065891227074],auc is 88.21173%, mae is 26.56420%, precesion is 76.01149%,recall is 71.70366%,f1-score is 73.79476%,accuracy is 80.52091%,weight_decay is 0.00200%
> 2025-05-29 12:47:32.088 | INFO     | __main__:<module>:208 -  Epoch of 19:loss is 11965.54%,batchsize is 16384,lr is [4.095430838889852e-05],auc is 88.20383%, mae is 26.54348%, precesion is 75.66884%,recall is 72.30561%,f1-score is 73.94900%,accuracy is 80.51373%,weight_decay is 0.00200%
> 2025-05-29 12:49:36.250 | INFO     | __main__:<module>:163 -  Switching optimizer to SGD with momentum...,switch_epoch is 20
> 2025-05-29 12:50:33.250 | INFO     | __main__:<module>:211 -  Epoch of 20:loss is 11927.73%,auc is 88.20239%, mae is 26.53243%, precesion is 75.58291%,recall is 72.43797%,f1-score is 73.97703%,accuracy is 80.50644%
> 2025-05-29 12:53:33.654 | INFO     | __main__:<module>:211 -  Epoch of 21:loss is 11914.87%,auc is 88.20213%, mae is 26.53868%, precesion is 75.59278%,recall is 72.43609%,f1-score is 73.98078%,accuracy is 80.51074%
> 2025-05-29 12:56:40.403 | INFO     | __main__:<module>:211 -  Epoch of 22:loss is 11914.40%,auc is 88.20248%, mae is 26.54035%, precesion is 75.61320%,recall is 72.38384%,f1-score is 73.96329%,accuracy is 80.50710%
> 2025-05-29 13:00:53.689 | INFO     | __main__:<module>:211 -  Epoch of 23:loss is 11914.19%,auc is 88.20269%, mae is 26.54170%, precesion is 75.62944%,recall is 72.34881%,f1-score is 73.95276%,accuracy is 80.50588%
> 2025-05-29 13:03:53.544 | INFO     | __main__:<module>:211 -  Epoch of 24:loss is 11913.20%,auc is 88.20270%, mae is 26.54259%, precesion is 75.64197%,recall is 72.32737%,f1-score is 73.94754%,accuracy is 80.50638%
> 2025-05-29 13:06:52.270 | INFO     | __main__:<module>:211 -  Epoch of 25:loss is 11912.42%,auc is 88.20257%, mae is 26.54302%, precesion is 75.64704%,recall is 72.30943%,f1-score is 73.94059%,accuracy is 80.50418%
> 2025-05-29 13:09:52.105 | INFO     | __main__:<module>:211 -  Epoch of 26:loss is 11912.14%,auc is 88.20247%, mae is 26.54377%, precesion is 75.65465%,recall is 72.30080%,f1-score is 73.93971%,accuracy is 80.50562%
> 2025-05-29 13:12:51.744 | INFO     | __main__:<module>:211 -  Epoch of 27:loss is 11912.50%,auc is 88.20230%, mae is 26.54494%, precesion is 75.65885%,recall is 72.30248%,f1-score is 73.94259%,accuracy is 80.50808%
> 2025-05-29 13:15:51.439 | INFO     | __main__:<module>:211 -  Epoch of 28:loss is 11912.18%,auc is 88.20219%, mae is 26.54545%, precesion is 75.66133%,recall is 72.29599%,f1-score is 73.94039%,accuracy is 80.50760%
> 2025-05-29 13:18:50.270 | INFO     | __main__:<module>:211 -  Epoch of 29:loss is 11911.94%,auc is 88.20208%, mae is 26.54644%, precesion is 75.66264%,recall is 72.29249%,f1-score is 73.93918%,accuracy is 80.50732%
> 2025-05-29 13:21:49.833 | INFO     | __main__:<module>:211 -  Epoch of 30:loss is 11911.38%,auc is 88.20193%, mae is 26.54698%, precesion is 75.66046%,recall is 72.29693%,f1-score is 73.94046%,accuracy is 80.50742%
> 2025-05-29 13:24:49.742 | INFO     | __main__:<module>:211 -  Epoch of 31:loss is 11912.16%,auc is 88.20181%, mae is 26.54790%, precesion is 75.65992%,recall is 72.29531%,f1-score is 73.93936%,accuracy is 80.50674%
> 2025-05-29 13:27:49.210 | INFO     | __main__:<module>:211 -  Epoch of 32:loss is 11912.24%,auc is 88.20163%, mae is 26.54842%, precesion is 75.66109%,recall is 72.29552%,f1-score is 73.94003%,accuracy is 80.50736%
> 2025-05-29 13:30:48.812 | INFO     | __main__:<module>:211 -  Epoch of 33:loss is 11911.74%,auc is 88.20143%, mae is 26.54875%, precesion is 75.66250%,recall is 72.29536%,f1-score is 73.94062%,accuracy is 80.50800%
> 2025-05-29 13:33:48.431 | INFO     | __main__:<module>:211 -  Epoch of 34:loss is 11911.56%,auc is 88.20149%, mae is 26.54921%, precesion is 75.66328%,recall is 72.28689%,f1-score is 73.93656%,accuracy is 80.50618%
> 2025-05-29 13:36:48.031 | INFO     | __main__:<module>:211 -  Epoch of 35:loss is 11911.30%,auc is 88.20137%, mae is 26.54957%, precesion is 75.66242%,recall is 72.29081%,f1-score is 73.93820%,accuracy is 80.50678%
> 2025-05-29 13:39:47.809 | INFO     | __main__:<module>:211 -  Epoch of 36:loss is 11911.32%,auc is 88.20132%, mae is 26.55021%, precesion is 75.66381%,recall is 72.28768%,f1-score is 73.93722%,accuracy is 80.50664%
> 2025-05-29 13:42:47.783 | INFO     | __main__:<module>:211 -  Epoch of 37:loss is 11911.53%,auc is 88.20118%, mae is 26.55068%, precesion is 75.66141%,recall is 72.28506%,f1-score is 73.93471%,accuracy is 80.50480%
> 2025-05-29 13:45:47.626 | INFO     | __main__:<module>:211 -  Epoch of 38:loss is 11911.52%,auc is 88.20106%, mae is 26.55116%, precesion is 75.65946%,recall is 72.28830%,f1-score is 73.93547%,accuracy is 80.50470%
> 2025-05-29 13:48:48.064 | INFO     | __main__:<module>:211 -  Epoch of 39:loss is 11911.12%,auc is 88.20100%, mae is 26.55166%, precesion is 75.66067%,recall is 72.28721%,f1-score is 73.93548%,accuracy is 80.50500%
> 2025-05-29 13:51:48.022 | INFO     | __main__:<module>:211 -  Epoch of 40:loss is 11911.90%,auc is 88.20094%, mae is 26.55196%, precesion is 75.66192%,recall is 72.28836%,f1-score is 73.93667%,accuracy is 80.50590%
> 2025-05-29 13:54:48.425 | INFO     | __main__:<module>:211 -  Epoch of 41:loss is 11912.07%,auc is 88.20100%, mae is 26.55255%, precesion is 75.66046%,recall is 72.29029%,f1-score is 73.93699%,accuracy is 80.50570%
> 2025-05-29 13:57:48.699 | INFO     | __main__:<module>:211 -  Epoch of 42:loss is 11910.98%,auc is 88.20092%, mae is 26.55217%, precesion is 75.66058%,recall is 72.29123%,f1-score is 73.93754%,accuracy is 80.50600%
> 2025-05-29 14:00:48.716 | INFO     | __main__:<module>:211 -  Epoch of 43:loss is 11911.65%,auc is 88.20087%, mae is 26.55230%, precesion is 75.66018%,recall is 72.29228%,f1-score is 73.93790%,accuracy is 80.50608%
> ```


**（2）poso_model的运行结果**

> [!example]- PlainText 实现细节（31 行）
> ```PlainText
> 2025-05-29 10:29:08.740 | INFO     | __main__:<module>:208 -  Epoch of 1:loss is 6534.13%,batchsize is 16384,lr is [0.0019755752073205815],auc is 87.42645%, mae is 27.52418%, precesion is 74.32518%,recall is 71.31049%,f1-score is 72.78663%,accuracy is 79.62272%,weight_decay is 0.00200%
> 2025-05-29 10:31:40.864 | INFO     | __main__:<module>:208 -  Epoch of 2:loss is 6243.30%,batchsize is 16384,lr is [0.0019155242941128502],auc is 87.63006%, mae is 27.29081%, precesion is 75.37796%,recall is 70.35661%,f1-score is 72.78078%,accuracy is 79.88935%,weight_decay is 0.00200%
> 2025-05-29 10:34:42.298 | INFO     | __main__:<module>:208 -  Epoch of 3:loss is 6167.34%,batchsize is 16384,lr is [0.0018336407384582924],auc is 87.72023%, mae is 27.12313%, precesion is 75.25860%,recall is 71.10677%,f1-score is 73.12380%,accuracy is 80.02521%,weight_decay is 0.00200%
> 2025-05-29 10:38:18.201 | INFO     | __main__:<module>:208 -  Epoch of 4:loss is 6116.38%,batchsize is 16384,lr is [0.001731929423223569],auc is 87.71923%, mae is 27.23662%, precesion is 75.81671%,recall is 69.95975%,f1-score is 72.77057%,accuracy is 79.99249%,weight_decay is 0.00200%
> 2025-05-29 10:40:50.775 | INFO     | __main__:<module>:208 -  Epoch of 5:loss is 6072.04%,batchsize is 16384,lr is [0.001612882948904035],auc is 87.66323%, mae is 27.32265%, precesion is 75.25366%,recall is 70.60115%,f1-score is 72.85320%,accuracy is 79.89316%,weight_decay is 0.00200%
> 2025-05-29 10:43:22.970 | INFO     | __main__:<module>:208 -  Epoch of 6:loss is 6027.38%,batchsize is 16384,lr is [0.0014794199126881501],auc is 87.64121%, mae is 27.13645%, precesion is 75.83935%,recall is 69.71301%,f1-score is 72.64725%,accuracy is 79.93876%,weight_decay is 0.00200%
> 2025-05-29 10:45:55.265 | INFO     | __main__:<module>:208 -  Epoch of 7:loss is 5980.27%,batchsize is 16384,lr is [0.001334812614570576],auc is 87.54516%, mae is 27.09285%, precesion is 75.53667%,recall is 69.78911%,f1-score is 72.54924%,accuracy is 79.81767%,weight_decay is 0.00200%
> 2025-05-29 10:48:27.487 | INFO     | __main__:<module>:208 -  Epoch of 8:loss is 5931.80%,batchsize is 16384,lr is [0.0011826059175833808],auc is 87.43407%, mae is 26.86858%, precesion is 75.83904%,recall is 68.81576%,f1-score is 72.15690%,accuracy is 79.70497%,weight_decay is 0.00200%
> 2025-05-29 10:51:12.018 | INFO     | __main__:<module>:208 -  Epoch of 9:loss is 5879.12%,batchsize is 16384,lr is [0.001026529177460072],auc is 87.31166%, mae is 26.78951%, precesion is 75.13279%,recall is 69.71186%,f1-score is 72.32088%,accuracy is 79.60812%,weight_decay is 0.00200%
> 2025-05-29 10:53:44.507 | INFO     | __main__:<module>:208 -  Epoch of 10:loss is 5817.77%,batchsize is 16384,lr is [0.0008704032740976682],auc is 87.32325%, mae is 26.64185%, precesion is 75.22921%,recall is 69.54112%,f1-score is 72.27342%,accuracy is 79.60980%,weight_decay is 0.00200%
> 2025-05-29 10:56:17.333 | INFO     | __main__:<module>:208 -  Epoch of 11:loss is 5750.01%,batchsize is 16384,lr is [0.0007180447977131023],auc is 87.20056%, mae is 26.71261%, precesion is 74.27694%,recall is 71.09065%,f1-score is 72.64888%,accuracy is 79.54399%,weight_decay is 0.00200%
> 2025-05-29 10:58:50.791 | INFO     | __main__:<module>:208 -  Epoch of 12:loss is 5669.39%,batchsize is 16384,lr is [0.0005731693173844226],auc is 87.03755%, mae is 26.65967%, precesion is 73.63944%,recall is 71.54540%,f1-score is 72.57732%,accuracy is 79.33893%,weight_decay is 0.00200%
> 2025-05-29 11:01:23.635 | INFO     | __main__:<module>:208 -  Epoch of 13:loss is 5581.45%,batchsize is 16384,lr is [0.000439295279461272],auc is 86.80402%, mae is 26.42043%, precesion is 73.50383%,recall is 71.09055%,f1-score is 72.27705%,accuracy is 79.15927%,weight_decay is 0.00200%
> 2025-05-29 11:03:56.097 | INFO     | __main__:<module>:208 -  Epoch of 14:loss is 5484.55%,batchsize is 16384,lr is [0.0003196491785505438],auc is 86.73105%, mae is 26.15486%, precesion is 73.30388%,recall is 71.28023%,f1-score is 72.27789%,accuracy is 79.10454%,weight_decay is 0.00200%
> 2025-05-29 11:06:28.378 | INFO     | __main__:<module>:208 -  Epoch of 15:loss is 5382.83%,batchsize is 16384,lr is [0.00021707047943692935],auc is 86.50783%, mae is 26.21290%, precesion is 72.82520%,recall is 71.34378%,f1-score is 72.07688%,accuracy is 78.87551%,weight_decay is 0.00200%
> 2025-05-29 11:09:00.867 | INFO     | __main__:<module>:208 -  Epoch of 16:loss is 5280.14%,batchsize is 16384,lr is [0.00013390910258153139],auc is 86.20169%, mae is 26.42814%, precesion is 72.24912%,recall is 71.55587%,f1-score is 71.90082%,accuracy is 78.62692%,weight_decay is 0.00200%
> 2025-05-29 11:11:33.307 | INFO     | __main__:<module>:208 -  Epoch of 17:loss is 5183.17%,batchsize is 16384,lr is [7.189126536137628e-05],auc is 85.98249%, mae is 26.38091%, precesion is 71.71346%,recall is 71.70933%,f1-score is 71.71140%,accuracy is 78.37973%,weight_decay is 0.00200%
> 2025-05-29 11:14:38.300 | INFO     | __main__:<module>:208 -  Epoch of 18:loss is 5097.99%,batchsize is 16384,lr is [3.186816464409299e-05],auc is 85.79254%, mae is 26.34680%, precesion is 71.41977%,recall is 71.47861%,f1-score is 71.44918%,accuracy is 78.16971%,weight_decay is 0.00200%
> 2025-05-29 11:18:10.301 | INFO     | __main__:<module>:208 -  Epoch of 19:loss is 5028.87%,batchsize is 16384,lr is [1.308149443191136e-05],auc is 85.65998%, mae is 26.33947%, precesion is 71.54142%,recall is 70.81429%,f1-score is 71.17599%,accuracy is 78.08185%,weight_decay is 0.00200%
> 2025-05-29 11:19:54.616 | INFO     | __main__:<module>:163 -  Switching optimizer to SGD with momentum...,switch_epoch is 20
> 2025-05-29 11:20:42.796 | INFO     | __main__:<module>:211 -  Epoch of 20:loss is 4975.30%,auc is 85.56308%, mae is 26.40323%, precesion is 71.75179%,recall is 70.14588%,f1-score is 70.93974%,accuracy is 78.03789%
> 2025-05-29 11:23:23.850 | INFO     | __main__:<module>:211 -  Epoch of 21:loss is 4943.06%,auc is 85.55857%, mae is 26.38085%, precesion is 71.90808%,recall is 69.81246%,f1-score is 70.84477%,accuracy is 78.04145%
> 2025-05-29 11:25:58.212 | INFO     | __main__:<module>:211 -  Epoch of 22:loss is 4941.77%,auc is 85.56880%, mae is 26.37280%, precesion is 71.91709%,recall is 69.82889%,f1-score is 70.85761%,accuracy is 78.04993%
> 2025-05-29 11:28:30.740 | INFO     | __main__:<module>:211 -  Epoch of 23:loss is 4941.84%,auc is 85.57669%, mae is 26.36684%, precesion is 71.92884%,recall is 69.84324%,f1-score is 70.87070%,accuracy is 78.05933%
> 2025-05-29 11:31:10.908 | INFO     | __main__:<module>:211 -  Epoch of 24:loss is 4940.00%,auc is 85.58352%, mae is 26.36141%, precesion is 71.93903%,recall is 69.85433%,f1-score is 70.88136%,accuracy is 78.06717%
> 2025-05-29 11:33:42.338 | INFO     | __main__:<module>:211 -  Epoch of 25:loss is 4939.64%,auc is 85.58879%, mae is 26.35742%, precesion is 71.94726%,recall is 69.86082%,f1-score is 70.88869%,accuracy is 78.07293%
> 2025-05-29 11:36:26.209 | INFO     | __main__:<module>:211 -  Epoch of 26:loss is 4940.23%,auc is 85.59316%, mae is 26.35419%, precesion is 71.95291%,recall is 69.86857%,f1-score is 70.89542%,accuracy is 78.07765%
> 2025-05-29 11:38:57.714 | INFO     | __main__:<module>:211 -  Epoch of 27:loss is 4938.42%,auc is 85.59693%, mae is 26.35109%, precesion is 71.95810%,recall is 69.87684%,f1-score is 70.90220%,accuracy is 78.08225%
> 2025-05-29 11:41:29.558 | INFO     | __main__:<module>:211 -  Epoch of 28:loss is 4938.00%,auc is 85.60013%, mae is 26.34833%, precesion is 71.95679%,recall is 69.88951%,f1-score is 70.90808%,accuracy is 78.08454%
> 2025-05-29 11:44:08.962 | INFO     | __main__:<module>:211 -  Epoch of 29:loss is 4938.21%,auc is 85.60239%, mae is 26.34642%, precesion is 71.95961%,recall is 69.89767%,f1-score is 70.91366%,accuracy is 78.08790%
> 2025-05-29 11:46:40.826 | INFO     | __main__:<module>:211 -  Epoch of 30:loss is 4937.67%,auc is 85.60458%, mae is 26.34471%, precesion is 71.95830%,recall is 69.89715%,f1-score is 70.91275%,accuracy is 78.08710%
> ```


> [!example]- PlainText 实现细节（51 行）
> ```PlainText
> 2025-06-03 10:55:26.326 | INFO     | __main__:<module>:212 -  Epoch of 1:loss is 8516.29%,batchsize is 16384,lr is [0.019754647434340918],auc is 87.07552%, mae is 29.81274%, precesion is 73.88773%,recall is 71.34994%,f1-score is 72.59667%,accuracy is 79.39630%,weight_decay is 0.00200%
> 2025-06-03 10:58:47.881 | INFO     | __main__:<module>:212 -  Epoch of 2:loss is 6394.27%,batchsize is 16384,lr is [0.019151422431817024],auc is 87.22232%, mae is 29.59035%, precesion is 71.66105%,recall is 75.44063%,f1-score is 73.50228%,accuracy is 79.19452%,weight_decay is 0.00200%
> 2025-06-03 11:02:09.612 | INFO     | __main__:<module>:212 -  Epoch of 3:loss is 6335.66%,batchsize is 16384,lr is [0.018328883598885057],auc is 87.48404%, mae is 28.95781%, precesion is 75.56781%,recall is 69.59418%,f1-score is 72.45808%,accuracy is 79.76305%,weight_decay is 0.00200%
> 2025-06-03 11:05:31.195 | INFO     | __main__:<module>:212 -  Epoch of 4:loss is 6304.00%,batchsize is 16384,lr is [0.0173071704373061],auc is 87.62131%, mae is 28.40860%, precesion is 75.27317%,recall is 71.07587%,f1-score is 73.11433%,accuracy is 80.00574%,weight_decay is 0.00200%
> 2025-06-03 11:08:52.887 | INFO     | __main__:<module>:212 -  Epoch of 5:loss is 6277.02%,batchsize is 16384,lr is [0.016111321682709373],auc is 87.65588%, mae is 28.25127%, precesion is 75.56733%,recall is 70.50556%,f1-score is 72.94874%,accuracy is 79.99872%,weight_decay is 0.00200%
> 2025-06-03 11:12:14.783 | INFO     | __main__:<module>:212 -  Epoch of 6:loss is 6253.93%,batchsize is 16384,lr is [0.014770655303837246],auc is 87.76938%, mae is 27.52220%, precesion is 77.80427%,recall is 66.53227%,f1-score is 71.72813%,accuracy is 79.93855%,weight_decay is 0.00200%
> 2025-06-03 11:15:36.777 | INFO     | __main__:<module>:212 -  Epoch of 7:loss is 6233.01%,batchsize is 16384,lr is [0.013318042294103423],auc is 87.88004%, mae is 27.69291%, precesion is 73.97041%,recall is 73.84269%,f1-score is 73.90649%,accuracy is 80.05555%,weight_decay is 0.00200%
> 2025-06-03 11:18:58.160 | INFO     | __main__:<module>:212 -  Epoch of 8:loss is 6216.69%,batchsize is 16384,lr is [0.011789091604267225],auc is 87.86183%, mae is 28.16333%, precesion is 71.67293%,recall is 77.47836%,f1-score is 74.46266%,accuracy is 79.67258%,weight_decay is 0.00200%
> 2025-06-03 11:22:20.163 | INFO     | __main__:<module>:212 -  Epoch of 9:loss is 6192.40%,batchsize is 16384,lr is [0.010221265455993386],auc is 87.90887%, mae is 27.49251%, precesion is 73.97985%,recall is 74.07335%,f1-score is 74.02657%,accuracy is 80.11761%,weight_decay is 0.00200%
> 2025-06-03 11:25:41.443 | INFO     | __main__:<module>:212 -  Epoch of 10:loss is 6173.68%,batchsize is 16384,lr is [0.008652945451865521],auc is 87.91695%, mae is 27.59410%, precesion is 75.70575%,recall is 70.97458%,f1-score is 73.26386%,accuracy is 80.18580%,weight_decay is 0.00200%
> 2025-06-03 11:29:03.454 | INFO     | __main__:<module>:212 -  Epoch of 11:loss is 6157.79%,batchsize is 16384,lr is [0.007122470103660761],auc is 87.97755%, mae is 27.58449%, precesion is 75.42953%,recall is 71.86153%,f1-score is 73.60232%,accuracy is 80.28324%,weight_decay is 0.00200%
> 2025-06-03 11:32:25.332 | INFO     | __main__:<module>:212 -  Epoch of 12:loss is 6138.73%,batchsize is 16384,lr is [0.005667163142972163],auc is 88.08871%, mae is 27.71718%, precesion is 75.37163%,recall is 72.23611%,f1-score is 73.77057%,accuracy is 80.35170%,weight_decay is 0.00200%
> 2025-06-03 11:35:47.221 | INFO     | __main__:<module>:212 -  Epoch of 13:loss is 6119.24%,batchsize is 16384,lr is [0.004322368159010465],auc is 88.08487%, mae is 27.51784%, precesion is 74.93902%,recall is 72.92618%,f1-score is 73.91890%,accuracy is 80.31576%,weight_decay is 0.00200%
> 2025-06-03 11:39:09.405 | INFO     | __main__:<module>:212 -  Epoch of 14:loss is 6095.84%,batchsize is 16384,lr is [0.0031204960197112413],auc is 88.19447%, mae is 27.26289%, precesion is 76.77459%,recall is 70.14907%,f1-score is 73.31244%,accuracy is 80.46480%,weight_decay is 0.00200%
> 2025-06-03 11:42:31.402 | INFO     | __main__:<module>:212 -  Epoch of 15:loss is 6070.50%,batchsize is 16384,lr is [0.0020900697909267425],auc is 88.05453%, mae is 27.18511%, precesion is 73.81405%,recall is 74.76311%,f1-score is 74.28555%,accuracy is 80.20183%,weight_decay is 0.00200%
> 2025-06-03 11:46:15.472 | INFO     | __main__:<module>:212 -  Epoch of 16:loss is 6041.35%,batchsize is 16384,lr is [0.001254694955077795],auc is 88.14288%, mae is 27.27353%, precesion is 73.19121%,recall is 75.99547%,f1-score is 74.56698%,accuracy is 80.17086%,weight_decay is 0.00200%
> 2025-06-03 11:50:00.414 | INFO     | __main__:<module>:212 -  Epoch of 17:loss is 6006.43%,batchsize is 16384,lr is [0.0006317117560672925],auc is 88.06934%, mae is 27.21556%, precesion is 71.90596%,recall is 77.74328%,f1-score is 74.71078%,accuracy is 79.86832%,weight_decay is 0.00200%
> 2025-06-03 11:53:25.031 | INFO     | __main__:<module>:212 -  Epoch of 18:loss is 5970.08%,batchsize is 16384,lr is [0.00022967065891227074],auc is 88.10104%, mae is 26.71121%, precesion is 74.53698%,recall is 73.67942%,f1-score is 74.10572%,accuracy is 80.30468%,weight_decay is 0.00200%
> 2025-06-03 11:56:46.927 | INFO     | __main__:<module>:212 -  Epoch of 19:loss is 5931.45%,batchsize is 16384,lr is [4.095430838889852e-05],auc is 88.07771%, mae is 26.66495%, precesion is 75.85041%,recall is 71.36762%,f1-score is 73.54076%,accuracy is 80.35667%,weight_decay is 0.00200%
> 2025-06-03 11:58:31.151 | INFO     | __main__:<module>:167 -  Switching optimizer to SGD with momentum...,switch_epoch is 20
> 2025-06-03 12:00:09.336 | INFO     | __main__:<module>:215 -  Epoch of 20:loss is 5900.23%,auc is 88.07836%, mae is 26.60520%, precesion is 75.28284%,recall is 72.45486%,f1-score is 73.84178%,accuracy is 80.36467%
> 2025-06-03 12:03:30.641 | INFO     | __main__:<module>:215 -  Epoch of 21:loss is 5885.15%,auc is 88.07347%, mae is 26.56056%, precesion is 75.38335%,recall is 72.25724%,f1-score is 73.78720%,accuracy is 80.36285%
> 2025-06-03 12:06:53.186 | INFO     | __main__:<module>:215 -  Epoch of 22:loss is 5886.21%,auc is 88.07348%, mae is 26.55605%, precesion is 75.39370%,recall is 72.23972%,f1-score is 73.78302%,accuracy is 80.36337%
> 2025-06-03 12:10:14.350 | INFO     | __main__:<module>:215 -  Epoch of 23:loss is 5885.82%,auc is 88.07343%, mae is 26.55216%, precesion is 75.40011%,recall is 72.22414%,f1-score is 73.77796%,accuracy is 80.36247%
> 2025-06-03 12:13:35.106 | INFO     | __main__:<module>:215 -  Epoch of 24:loss is 5886.00%,auc is 88.07336%, mae is 26.54911%, precesion is 75.40978%,recall is 72.21175%,f1-score is 73.77612%,accuracy is 80.36397%
> 2025-06-03 12:16:56.267 | INFO     | __main__:<module>:215 -  Epoch of 25:loss is 5885.93%,auc is 88.07325%, mae is 26.54632%, precesion is 75.41575%,recall is 72.20165%,f1-score is 73.77371%,accuracy is 80.36427%
> 2025-06-03 12:20:17.609 | INFO     | __main__:<module>:215 -  Epoch of 26:loss is 5885.90%,auc is 88.07314%, mae is 26.54388%, precesion is 75.42080%,recall is 72.19099%,f1-score is 73.77056%,accuracy is 80.36397%
> 2025-06-03 12:23:38.514 | INFO     | __main__:<module>:215 -  Epoch of 27:loss is 5885.87%,auc is 88.07303%, mae is 26.54200%, precesion is 75.42278%,recall is 72.17959%,f1-score is 73.76555%,accuracy is 80.36199%
> 2025-06-03 12:26:58.985 | INFO     | __main__:<module>:215 -  Epoch of 28:loss is 5885.79%,auc is 88.07289%, mae is 26.54035%, precesion is 75.42960%,recall is 72.16813%,f1-score is 73.76283%,accuracy is 80.36235%
> 2025-06-03 12:30:20.052 | INFO     | __main__:<module>:215 -  Epoch of 29:loss is 5885.61%,auc is 88.07279%, mae is 26.53916%, precesion is 75.43086%,recall is 72.16515%,f1-score is 73.76188%,accuracy is 80.36219%
> 2025-06-03 12:33:41.150 | INFO     | __main__:<module>:215 -  Epoch of 30:loss is 5885.79%,auc is 88.07266%, mae is 26.53770%, precesion is 75.43229%,recall is 72.16254%,f1-score is 73.76120%,accuracy is 80.36221%
> 2025-06-03 12:37:02.116 | INFO     | __main__:<module>:215 -  Epoch of 31:loss is 5886.00%,auc is 88.07251%, mae is 26.53649%, precesion is 75.43748%,recall is 72.15752%,f1-score is 73.76105%,accuracy is 80.36343%
> 2025-06-03 12:40:23.476 | INFO     | __main__:<module>:215 -  Epoch of 32:loss is 5885.03%,auc is 88.07236%, mae is 26.53556%, precesion is 75.43819%,recall is 72.15469%,f1-score is 73.75992%,accuracy is 80.36305%
> 2025-06-03 12:44:03.038 | INFO     | __main__:<module>:215 -  Epoch of 33:loss is 5885.78%,auc is 88.07224%, mae is 26.53465%, precesion is 75.43836%,recall is 72.15213%,f1-score is 73.75866%,accuracy is 80.36247%
> 2025-06-03 12:47:25.328 | INFO     | __main__:<module>:215 -  Epoch of 34:loss is 5885.00%,auc is 88.07212%, mae is 26.53382%, precesion is 75.44030%,recall is 72.14716%,f1-score is 73.75699%,accuracy is 80.36213%
> 2025-06-03 12:50:46.741 | INFO     | __main__:<module>:215 -  Epoch of 35:loss is 5885.10%,auc is 88.07199%, mae is 26.53325%, precesion is 75.44130%,recall is 72.14591%,f1-score is 73.75681%,accuracy is 80.36229%
> 2025-06-03 12:54:07.789 | INFO     | __main__:<module>:215 -  Epoch of 36:loss is 5884.99%,auc is 88.07194%, mae is 26.53230%, precesion is 75.44197%,recall is 72.14481%,f1-score is 73.75656%,accuracy is 80.36233%
> 2025-06-03 12:57:29.218 | INFO     | __main__:<module>:215 -  Epoch of 37:loss is 5885.51%,auc is 88.07183%, mae is 26.53183%, precesion is 75.44308%,recall is 72.14528%,f1-score is 73.75734%,accuracy is 80.36299%
> 2025-06-03 13:00:50.400 | INFO     | __main__:<module>:215 -  Epoch of 38:loss is 5885.01%,auc is 88.07180%, mae is 26.53114%, precesion is 75.44446%,recall is 72.14152%,f1-score is 73.75603%,accuracy is 80.36269%
> 2025-06-03 13:04:11.517 | INFO     | __main__:<module>:215 -  Epoch of 39:loss is 5885.55%,auc is 88.07170%, mae is 26.53078%, precesion is 75.44647%,recall is 72.14565%,f1-score is 73.75915%,accuracy is 80.36473%
> 2025-06-03 13:07:32.687 | INFO     | __main__:<module>:215 -  Epoch of 40:loss is 5885.29%,auc is 88.07161%, mae is 26.53064%, precesion is 75.44722%,recall is 72.14695%,f1-score is 73.76019%,accuracy is 80.36543%
> 2025-06-03 13:10:54.259 | INFO     | __main__:<module>:215 -  Epoch of 41:loss is 5885.15%,auc is 88.07160%, mae is 26.53030%, precesion is 75.44696%,recall is 72.14643%,f1-score is 73.75979%,accuracy is 80.36517%
> 2025-06-03 13:14:16.729 | INFO     | __main__:<module>:215 -  Epoch of 42:loss is 5885.30%,auc is 88.07155%, mae is 26.53005%, precesion is 75.44613%,recall is 72.14847%,f1-score is 73.76046%,accuracy is 80.36529%
> 2025-06-03 13:17:39.490 | INFO     | __main__:<module>:215 -  Epoch of 43:loss is 5884.80%,auc is 88.07146%, mae is 26.52944%, precesion is 75.44678%,recall is 72.14925%,f1-score is 73.76118%,accuracy is 80.36581%
> 2025-06-03 13:21:00.774 | INFO     | __main__:<module>:215 -  Epoch of 44:loss is 5885.10%,auc is 88.07142%, mae is 26.52940%, precesion is 75.44561%,recall is 72.14758%,f1-score is 73.75975%,accuracy is 80.36481%
> 2025-06-03 13:24:21.794 | INFO     | __main__:<module>:215 -  Epoch of 45:loss is 5884.53%,auc is 88.07136%, mae is 26.52899%, precesion is 75.44786%,recall is 72.14382%,f1-score is 73.75886%,accuracy is 80.36493%
> 2025-06-03 13:27:43.817 | INFO     | __main__:<module>:215 -  Epoch of 46:loss is 5885.30%,auc is 88.07134%, mae is 26.52852%, precesion is 75.44637%,recall is 72.14429%,f1-score is 73.75839%,accuracy is 80.36433%
> 2025-06-03 13:31:14.394 | INFO     | __main__:<module>:215 -  Epoch of 47:loss is 5885.05%,auc is 88.07131%, mae is 26.52800%, precesion is 75.44529%,recall is 72.14554%,f1-score is 73.75853%,accuracy is 80.36413%
> 2025-06-03 13:34:40.709 | INFO     | __main__:<module>:215 -  Epoch of 48:loss is 5885.74%,auc is 88.07131%, mae is 26.52806%, precesion is 75.44446%,recall is 72.14392%,f1-score is 73.75729%,accuracy is 80.36331%
> 2025-06-03 13:38:02.379 | INFO     | __main__:<module>:215 -  Epoch of 49:loss is 5884.55%,auc is 88.07130%, mae is 26.52758%, precesion is 75.44519%,recall is 72.14256%,f1-score is 73.75692%,accuracy is 80.36331%
> 2025-06-03 13:41:49.215 | INFO     | __main__:<module>:215 -  Epoch of 50:loss is 5885.02%,auc is 88.07124%, mae is 26.52722%, precesion is 75.44750%,recall is 72.14131%,f1-score is 73.75737%,accuracy is 80.36411%
> ```


> [!example]- PlainText 实现细节（31 行）
> ```PlainText
> 2025-05-29 14:20:15.577 | INFO     | __main__:<module>:208 -  Epoch of 1:loss is 17275.88%,batchsize is 16384,lr is [0.019754647434340918],auc is 87.30285%, mae is 30.12124%, precesion is 68.20826%,recall is 81.11262%,f1-score is 74.10284%,accuracy is 78.31445%,weight_decay is 0.00200%
> 2025-05-29 14:26:17.167 | INFO     | __main__:<module>:208 -  Epoch of 2:loss is 14068.69%,batchsize is 16384,lr is [0.019151422431817024],auc is 87.25300%, mae is 29.80324%, precesion is 65.29365%,recall is 84.89200%,f1-score is 73.81409%,accuracy is 76.96119%,weight_decay is 0.00200%
> 2025-05-29 14:32:26.664 | INFO     | __main__:<module>:208 -  Epoch of 3:loss is 12722.05%,batchsize is 16384,lr is [0.018328883598885057],auc is 87.70222%, mae is 28.02800%, precesion is 74.27850%,recall is 72.94626%,f1-score is 73.60636%,accuracy is 79.98978%,weight_decay is 0.00200%
> 2025-05-29 14:37:57.491 | INFO     | __main__:<module>:208 -  Epoch of 4:loss is 12623.23%,batchsize is 16384,lr is [0.0173071704373061],auc is 87.78931%, mae is 27.48290%, precesion is 75.65638%,recall is 71.08398%,f1-score is 73.29894%,accuracy is 80.19078%,weight_decay is 0.00200%
> 2025-05-29 14:43:04.043 | INFO     | __main__:<module>:208 -  Epoch of 5:loss is 12536.39%,batchsize is 16384,lr is [0.016111321682709373],auc is 87.76799%, mae is 27.43221%, precesion is 74.31437%,recall is 73.00321%,f1-score is 73.65296%,accuracy is 80.02216%,weight_decay is 0.00200%
> 2025-05-29 14:48:10.790 | INFO     | __main__:<module>:208 -  Epoch of 6:loss is 12511.88%,batchsize is 16384,lr is [0.014770655303837246],auc is 87.89179%, mae is 27.19213%, precesion is 75.85535%,recall is 71.14568%,f1-score is 73.42507%,accuracy is 80.30114%,weight_decay is 0.00200%
> 2025-05-29 14:53:17.299 | INFO     | __main__:<module>:208 -  Epoch of 7:loss is 12466.00%,batchsize is 16384,lr is [0.013318042294103423],auc is 87.91777%, mae is 27.19523%, precesion is 77.03007%,recall is 68.68348%,f1-score is 72.61772%,accuracy is 80.18728%,weight_decay is 0.00200%
> 2025-05-29 14:58:23.687 | INFO     | __main__:<module>:208 -  Epoch of 8:loss is 12427.87%,batchsize is 16384,lr is [0.011789091604267225],auc is 88.00490%, mae is 27.38495%, precesion is 78.25731%,recall is 66.49640%,f1-score is 71.89908%,accuracy is 80.11799%,weight_decay is 0.00200%
> 2025-05-29 15:03:30.304 | INFO     | __main__:<module>:208 -  Epoch of 9:loss is 12390.73%,batchsize is 16384,lr is [0.010221265455993386],auc is 87.98550%, mae is 27.37554%, precesion is 77.04033%,recall is 68.87164%,f1-score is 72.72733%,accuracy is 80.24235%,weight_decay is 0.00200%
> 2025-05-29 15:08:36.648 | INFO     | __main__:<module>:208 -  Epoch of 10:loss is 12357.38%,batchsize is 16384,lr is [0.008652945451865521],auc is 88.01893%, mae is 27.19577%, precesion is 78.04021%,recall is 66.92474%,f1-score is 72.05632%,accuracy is 80.14532%,weight_decay is 0.00200%
> 2025-05-29 15:13:43.394 | INFO     | __main__:<module>:208 -  Epoch of 11:loss is 12321.74%,batchsize is 16384,lr is [0.007122470103660761],auc is 88.10339%, mae is 27.23884%, precesion is 74.23640%,recall is 74.36719%,f1-score is 74.30174%,accuracy is 80.32336%,weight_decay is 0.00200%
> 2025-05-29 15:18:50.487 | INFO     | __main__:<module>:208 -  Epoch of 12:loss is 12286.45%,batchsize is 16384,lr is [0.005667163142972163],auc is 88.20495%, mae is 27.16849%, precesion is 74.97982%,recall is 73.39563%,f1-score is 74.17927%,accuracy is 80.45566%,weight_decay is 0.00200%
> 2025-05-29 15:23:57.111 | INFO     | __main__:<module>:208 -  Epoch of 13:loss is 12247.01%,batchsize is 16384,lr is [0.004322368159010465],auc is 88.23498%, mae is 27.23209%, precesion is 73.95322%,recall is 75.45250%,f1-score is 74.69534%,accuracy is 80.44556%,weight_decay is 0.00200%
> 2025-05-29 15:29:08.700 | INFO     | __main__:<module>:208 -  Epoch of 14:loss is 12208.92%,batchsize is 16384,lr is [0.0031204960197112413],auc is 88.23780%, mae is 26.86758%, precesion is 76.38549%,recall is 70.93457%,f1-score is 73.55919%,accuracy is 80.49434%,weight_decay is 0.00200%
> 2025-05-29 15:34:16.062 | INFO     | __main__:<module>:208 -  Epoch of 15:loss is 12166.09%,batchsize is 16384,lr is [0.0020900697909267425],auc is 88.21592%, mae is 26.81617%, precesion is 76.67839%,recall is 70.32598%,f1-score is 73.36493%,accuracy is 80.46804%,weight_decay is 0.00200%
> 2025-05-29 15:39:36.418 | INFO     | __main__:<module>:208 -  Epoch of 16:loss is 12122.42%,batchsize is 16384,lr is [0.001254694955077795],auc is 88.26012%, mae is 27.04924%, precesion is 75.79624%,recall is 71.96340%,f1-score is 73.83011%,accuracy is 80.48606%,weight_decay is 0.00200%
> 2025-05-29 15:44:53.397 | INFO     | __main__:<module>:208 -  Epoch of 17:loss is 12073.21%,batchsize is 16384,lr is [0.0006317117560672925],auc is 88.27578%, mae is 26.92763%, precesion is 75.18155%,recall is 73.01806%,f1-score is 74.08401%,accuracy is 80.45938%,weight_decay is 0.00200%
> 2025-05-29 15:50:01.454 | INFO     | __main__:<module>:208 -  Epoch of 18:loss is 12023.11%,batchsize is 16384,lr is [0.00022967065891227074],auc is 88.26249%, mae is 26.69936%, precesion is 76.00351%,recall is 71.72991%,f1-score is 73.80490%,accuracy is 80.52399%,weight_decay is 0.00200%
> 2025-05-29 15:55:22.613 | INFO     | __main__:<module>:208 -  Epoch of 19:loss is 11973.07%,batchsize is 16384,lr is [4.095430838889852e-05],auc is 88.20825%, mae is 26.64327%, precesion is 75.80727%,recall is 71.93412%,f1-score is 73.81993%,accuracy is 80.48372%,weight_decay is 0.00200%
> 2025-05-29 15:58:51.731 | INFO     | __main__:<module>:163 -  Switching optimizer to SGD with momentum...,switch_epoch is 20
> 2025-05-29 16:00:29.911 | INFO     | __main__:<module>:211 -  Epoch of 20:loss is 11936.44%,auc is 88.20936%, mae is 26.57749%, precesion is 75.97809%,recall is 71.66015%,f1-score is 73.75598%,accuracy is 80.49366%
> 2025-05-29 16:05:34.932 | INFO     | __main__:<module>:211 -  Epoch of 21:loss is 11921.27%,auc is 88.20495%, mae is 26.60326%, precesion is 75.71481%,recall is 72.13681%,f1-score is 73.88252%,accuracy is 80.49206%
> 2025-05-29 16:10:53.758 | INFO     | __main__:<module>:211 -  Epoch of 22:loss is 11920.54%,auc is 88.20379%, mae is 26.60615%, precesion is 75.72513%,recall is 72.12703%,f1-score is 73.88230%,accuracy is 80.49448%
> 2025-05-29 16:15:58.717 | INFO     | __main__:<module>:211 -  Epoch of 23:loss is 11920.54%,auc is 88.20361%, mae is 26.60804%, precesion is 75.72882%,recall is 72.13059%,f1-score is 73.88592%,accuracy is 80.49718%
> 2025-05-29 16:21:03.774 | INFO     | __main__:<module>:211 -  Epoch of 24:loss is 11920.76%,auc is 88.20386%, mae is 26.60951%, precesion is 75.72901%,recall is 72.13477%,f1-score is 73.88821%,accuracy is 80.49836%
> 2025-05-29 16:26:22.888 | INFO     | __main__:<module>:211 -  Epoch of 25:loss is 11920.51%,auc is 88.20445%, mae is 26.61025%, precesion is 75.72555%,recall is 72.13848%,f1-score is 73.88851%,accuracy is 80.49766%
> 2025-05-29 16:31:41.847 | INFO     | __main__:<module>:211 -  Epoch of 26:loss is 11920.97%,auc is 88.20502%, mae is 26.61042%, precesion is 75.72478%,recall is 72.13906%,f1-score is 73.88844%,accuracy is 80.49744%
> 2025-05-29 16:44:01.552 | INFO     | __main__:<module>:211 -  Epoch of 27:loss is 11920.77%,auc is 88.20560%, mae is 26.61112%, precesion is 75.72309%,recall is 72.14288%,f1-score is 73.88964%,accuracy is 80.49762%
> 2025-05-29 16:49:08.118 | INFO     | __main__:<module>:211 -  Epoch of 28:loss is 11919.91%,auc is 88.20621%, mae is 26.61149%, precesion is 75.72502%,recall is 72.14308%,f1-score is 73.89067%,accuracy is 80.49860%
> 2025-05-29 16:54:13.773 | INFO     | __main__:<module>:211 -  Epoch of 29:loss is 11919.94%,auc is 88.20672%, mae is 26.61146%, precesion is 75.72411%,recall is 72.14230%,f1-score is 73.88982%,accuracy is 80.49796%
> 2025-05-29 16:59:18.973 | INFO     | __main__:<module>:211 -  Epoch of 30:loss is 11920.25%,auc is 88.20715%, mae is 26.61125%, precesion is 75.72348%,recall is 72.14047%,f1-score is 73.88856%,accuracy is 80.49718%
> ```


### 1.1.5 对比分析

#### （1）模型训练策略对比

目前有三个训练策略：

```PlainText
# 00 原始参数训练
# adam_learning_rate = 2e-4
# sgd_learning_rate = 1e-5
# adam_weight_decay = 2e-5
# sgd_weight_decay = 1e-4
# 01 调整参数训练
# adam_learning_rate = 2e-3
# sgd_learning_rate = 1e-4
# adam_weight_decay = 2e-5
# sgd_weight_decay = 1e-4
# 02 调整参数训练 （效果最优）
adam_learning_rate = 2e-2
sgd_learning_rate = 1e-4
adam_weight_decay = 2e-5
sgd_weight_decay = 1e-4
```

以**base_model**为基础，观察这三种训练策略的效果，具体的几个参数结果如下：

![](92896cd7a5a01347-loss_comparison_1_.png)![](87e59d758d7f5415-auc_comparison_1_.png)![](704982240cc7aff3-mae_comparison_1_.png)![](5e684039eb13a8ea-precision_comparison_1_.png)![](36ea565ac974cab4-recall_comparison_1_.png)![](f352cf6a3c13b69e-f1_score_comparison_1_.png)![](b22c3db08b0ff213-accuracy_comparison_1_.png)

其次，以**poso_model**的两个策略作为辅助验证（poso运行时间过长，只跑了2个），结果如下：

![](a9dc67eaeffc036f-loss_comparison_2_.png)![](a19d39fb0d0514d3-auc_comparison_2_.png)![](ea1e3eb32a655057-mae_comparison_2_.png)![](85a86f65b661f2e0-precision_comparison_2_.png)![](57eeaf670374beaa-recall_comparison_2_.png)![](bdc830c12747224c-f1_score_comparison_2_.png)![](01e5208193d94e20-accuracy_comparison_2_.png)

从上述训练策略的对比来看，基于lr = 2e-2的Adam先进行 20个epoch的训练，接着使用SGD进行平稳的收敛性训练，具有较好的训练效果。故后面的对比测试均在此训练策略下进行。

#### （2）数据量对比

在上述最优训练策略的情况下，进行数据量效果的对比，分别以**base_model**和**poso_model**两组为基础，分别训练250W和500W 查看效果

**base_model组结果**

![](3566400e418c4276-loss_comparison_3_.png)![](cd1e96c24a0ae8ec-auc_comparison_3_.png)![](5a0973527ddf10d9-mae_comparison_3_.png)![](c3aec5a2c83723d6-precision_comparison_3_.png)![](512236eb5dfa20ce-recall_comparison_3_.png)![](731396562caf2967-f1_score_comparison_3_.png)![](3da018b50afc0623-accuracy_comparison_3_.png)

**base_model组结果**

![](d2215a7c102f55b1-loss_comparison_4_.png)![](9f7e87ea3bf41adb-auc_comparison_4_.png)![](bb040ade0215c753-mae_comparison_4_.png)![](d6477ce8d3f31945-precision_comparison_4_.png)![](41a8b583d11205ae-recall_comparison_4_.png)![](d6169c0d5a0cf432-f1_score_comparison_4_.png)![](44f7035bf0f451cc-accuracy_comparison_4_.png)

**总结**：从上述训练数据量的对比来看，500W数据样本的训练，在**auc、precision、f1_socre、accuracy**指标上表现全面优于250W数据样本；在**mae**指标上base模型500W优于250W，poso模型有些差异，但差异不明显，可以忽略；在**recall**指标上500W和250W的效果基本一致。因此，在不考虑训练成本的情况下，较大规模的训练数据量能提高模型的效果

#### （3）base_model和poso_model对比

在上述最优训练策略的情况下，进行base和poso两个模型效果的对比，具体结果如下：

![](6d232ed9ecad639d-auc_comparison_5_.png)![](bc479051da82031c-precision_comparison_5_.png)![](6ae35b9876997681-mae_comparison_5_.png)![](4eee15905a5431dc-accuracy_comparison_5_.png)![](dbac53569fac9a48-recall_comparison_5_.png)![](5e4555126dc9e4b7-f1_score_comparison_5_.png)![](5acbfced258785f1-loss_comparison_5_.png)

**总结**：在上述结果中，当数据量在500W时，在**auc**指标上poso模型base模型高了0.05%个点；但**mae**指标上poso模型比base模型高了0.3-0.4%个点；其他的辅助性指标，两个模型的差异不大。此外，poso模型的训练和推理时间是base模型的一倍。

#### （4）小结

- 基于lr=2e-2的动态训练策略（上述02）可以有效用于下一步的模型优化探索

- 在训练成本支撑下，大数据量的训练数据能够有更好的效果

- poso模型比base的模型的提高不大（auc 0.05%），但mae效果和推理成本相对更差，实际收益待定
