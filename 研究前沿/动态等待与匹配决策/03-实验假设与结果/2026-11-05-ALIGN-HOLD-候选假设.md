---
type: "实验"
topics: ["动态等待与匹配决策", "实验假设"]
status: "维护中"
created: "2026-11-05"
experiment_id: "2026-11-05:ALIGN-HOLD"
experiment_status: "待设计"
execution_status: "not_run"
baseline_commit: null
data_version: null
budget: null
run_at: null
result: null
logs: null
---

# 困难偏好分位采样能否稳定提高跨时间排序

来源方法：[[研究前沿/动态等待与匹配决策/02-可复用方法卡/ALIGN-HOLD-preferences|preferences]] · [[研究前沿/动态等待与匹配决策/02-可复用方法卡/ALIGN-HOLD-hardpairs|hardpairs]] · [[研究前沿/动态等待与匹配决策/02-可复用方法卡/ALIGN-HOLD-filter|filter]]

## 可证伪假设与验证设计草案

假设：在配对规则、模型和训练步数固定时，跳过极端高损失尾部的采样比普通 hardest-pair sampling 更能提高跨时间/实体留出排序，且不损害稀疏群体。

最小改动仅为离线 RM 采样器：三视角平衡基线、平衡加 hardest 20%、平衡加 70–90 分位 20% 三组对照；配对池和模型相同。先检验 RM 排序，不把改善外推为完单提升。数据需能关联订单、司机或对应服务实体的轨迹；实际可用字段、时间窗和隐式标签质量待确认。

按时间划分并隔离实体。主指标为留出 Pair Accuracy，辅助为分视角/人群指标和训练稳定性；预算、种子、步数、判定阈值待确认。最终测试集不得反复选择分位。

失败判据：整体无稳健改善、仅训练指标提高，或稀疏群体显著恶化。下游策略实验另行设计；本候选不触发仿真训练或上线。

## 真实结果

**未运行。** 没有本地训练结果、日志或收益数值。论文结果不可填入本栏。执行前需确认项目、数据版本、基线 commit、资源预算；执行后记录命令、配置、数据划分、随机种子和原始日志。
