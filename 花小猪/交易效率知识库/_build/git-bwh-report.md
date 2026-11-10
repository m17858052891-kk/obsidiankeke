# bwh_stg Git 来源增量报告

5 个指定仓库均已读取成功，共 1,387 个受版本控制文件、368 个 Markdown 文件；固定提交号见 `_build/git-bwh-manifest.json`。

| 仓库 | commit | 文件 | Markdown | 审阅范围 |
| --- | --- | ---: | ---: | --- |
| trade-of-passenger | `cdef137c38e2` | 11 | 3 | 盲盒、换车模型实现 |
| platform_pk | `7b0870808d6f` | 13 | 1 | PLE、DQN 实现 |
| trade-model | `267808883300` | 1143 | 147 | 按模型族和核心入口抽样 |
| pk_strategy_wiki | `a2fecfd0f41b` | 153 | 152 | 模型、版本与导航证据 |
| cp_trade_strategy_wiki | `996f692fa1fc` | 67 | 65 | 模型、版本与导航证据 |

## 纳入 Wiki 的代码层新增内容

- 乘客远接驾盲盒与换车：注意力、多塔、treatment-aware loss、Qini/Dini，以及静态实现风险。
- 平台 PK：PLE/POSO/DCN 多任务结构、DQN 状态动作与目标网络、ONNX 导出；文档与固定代码的差异单列。
- 交易模型：PEPNet、DCNv2、FiBiNet、Wukong、OneTrans、HyFormer 等模型族与训练/验证/预测接口。
- 两个策略 Wiki：版本谱系和来源导航，用于交叉核验，不把方案、离线结果和线上事实混写。

本批新增 5 个 Wiki 页面。未运行训练、未重算离线指标，也未据代码推断生产发布或线上收益。`trade-model` 体量较大，采用模型族与核心入口抽样，不代表逐文件实验复现。原先不同 owner 的同名仓库已保留为独立目录，没有覆盖。
