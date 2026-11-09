# 根代理决策/可塑性笔记独立复核

复核日：2026-11-07。复核者：训练动力学方向代理。复核对象O01/O02/C02；源为`90_原文证据/decision_continual_system/2609.14907v1.txt`、`2609.39261v1.txt`、`2605.09044v1.txt`及对应官方HTML缓存。没有重跑作者实验；没有声称逐表校验O02全部53页。

## O01 Strategic DFL

- 原文§4/算法1确认监督跨区探索、KKT区内梯度、每regime验证utility保留/回滚。附录真实轨迹实验R=50，地铁KKT/Hybrid带退火Huber，笔记表述一致。
- 表1核对：保育PTO utility −.831±.005/MAE .110±.005，Hybrid −.173±.013/.458±.107；地铁−13.611±.210/.409±.009与−12.578±.383/.736±.028，5运行std，396/1098实例。笔记差值和负分母解读正确。
- 附录命题3.3证明确实基于Nash和限制策略集构造；笔记所写“不可外推为已知真实状态仍能击败同域精确SSE最优”边界正确。
- 附录B.1合成实验给KKT/PTO/ZOC各自更合适的分布，已按根代理授权直接补入O01：10×10格、20epoch交替区别于真实轨迹50epoch，避免Hybrid普适优越误读。仅描述原文定性负结果，不把该实验当真实线上证据。

## O02 Jacobian Rank Collapse

- §5 Proposition4、Theorem1、Proposition5支持秩1非零梯度共线但可异号、逐例秩1不代表batch秩1。笔记没有把参数数/输入Jacobian/proxy混用。
- §3/4确认默认market-cap选支持集、选择detach、QP读选中block与selected-to-all cross terms；MSE是过去63天重建，DFL用未来21天，BD-DFL是相对Frobenius正则。笔记准确。
- 表28核对：Path144方向+11.59%、Holm .0684；Knapsack72方向+10.59%、.0156；单方向+.24/−.61。表29+12.12/+12.54与+13.67/+13.76，knapsack校正p .0156/.0273。表30Path11.79→1.19，补偿所有ε恢复11.79，exact rank未变。均匹配。
- E.3/E.4/F.1确认512/256/512、各loss独立验证调学习率、train-only ridge、10独立数据、先平均3batch-order再推断、fresh study非预注册、补偿plainSGD 40epoch。笔记已保留范围，未发现必须修改的问题。

## C02 Optimization Readiness

- §4定义S/R/OR及无偏/β-smooth、η<R/β的一步下界匹配。反例是标签依赖零方向，笔记没有把“高rank非充分”误写成“rank无用”。
- 表2核对SCR k100 .977±.002、representation .704±.001、eNTK .779±.003；P-MNIST .899±.004/.873±.002；±为标准误。训练1000/800任务、1M/8M样本、20序列、30/10目标任务及Adam batch1均吻合。
- 附录C.1含探测具体预算：SGD batch4、η=.001、128rollout；OR全量均值梯度+128个batch4范数。图4少样本版本16个batch1。已授权直接补入C02。
- 同一固定validation任务数据集用于抽batch更新与测empirical gain，原文不是独立未来泛化收益；新增段落明确区别，并保持推荐迁移实验独立时间外评估要求。

## 限制

本轮完成核心公式、数据单位、重点表数字与推断边界核对；未检查官方代码/所有隐藏超参/全部历史archive或会议目录，未做外部撤稿库全覆盖。原文已披露的模拟、调参预算、观测性与独立性限制不因笔记正确转述而消失。
