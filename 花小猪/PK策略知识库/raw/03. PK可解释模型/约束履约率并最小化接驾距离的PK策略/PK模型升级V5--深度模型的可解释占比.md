
# PK模型升级V5--深度模型的可解释占比


怎样算「可解释」？

模型1: 深度模型

模型2：lr（100%的可解释）

对于两个do对$$do_i, do_j$$组成的pair，模型1的预测PK分为$$v_{i1},  v_{j1}$$，模型2的预测PK分为$$v_{i2},v_{j2}$$

如果两个模型对它们的打分排序一致，即$$(v_{i1}-v_{i2})*(v_{j1}-v_{j2})\geq 0$$，则认为模型1对这个pair的排序可以用模型2的排序来解释

- 在PK上复用 jiuxin的DO价值多任务模型 senet（仅对齐数据周期，未做模型修改），计算可解释占比

	- <https://ether.intra.hongyibo.com.cn/labs/new/15407>

	- 模型结构：senet，模型输出：is_do_finish, is_o_finish, is_d_finish, PK分=is_do_finish

	- 模型AUC 

|  <br> | is_do_finish <br> | is_o_finish <br> | is_d_finish <br> |
| --- | --- | --- | --- |
| senet <br> | 0.7719 <br> | 0.7276 <br> | 0.8928 <br> |
| lr <br> | 0.7347 <br> | / <br> | / <br> |

	- 仅有1个D的O占比53%，超过1的D的O占比47%

	- 可解释的do对pair / 总pair = 89.6% (仅看超过1个D的订单）
