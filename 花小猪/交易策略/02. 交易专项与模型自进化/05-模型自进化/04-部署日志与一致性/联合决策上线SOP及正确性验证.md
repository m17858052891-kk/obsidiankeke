---
title: "联合决策上线SOP及正确性验证"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2207096623379
cssclasses: ["strategy-body-note"]
---

# 联合决策上线SOP及正确性验证

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2207096623379)

**阅读定位**　[[#一、模型|一、模型]] · [[#二、幸运盒子|二、幸运盒子]] · [[#三、补贴调整|三、补贴调整]]

## 一、模型

#### 1.1 acc_cr模型

##### 1.1.1 样本获取

**数据集构建工作流：从hdfs拉取数据-修改config文件-运行样本预处理文件**

1.样本构建 -- 数梦链接：<https://studio.data.didichuxing.com/?projectId=1143&taskId=56456421&subType=SQLSCAN> 

	- 样本：

		1. 训练样本：01.13-01.19，随机下采样至10%

		2. 测试样本：01.20-01.26，随机下采样至2%

	- label：

is_trace_finish, is_cp_finish, is_cp_answer

	- 空值填充逻辑：

空值填充为-9999.0（注意，模型后续训练中是选择空值填充为0，这里-9999.0仅是数梦上的填充逻辑）

2.特征提取 模型训练V2 -> cr_model_train_data_v22，重跑0113-0126任务，注意事项：

	- 最左表需要是下采样后trice_id

	- 对于历史聚合特征选取时间需处理为dt = date_sub('${BIZ_DATE_LINE}',2)，相应上游表的调度配置依赖偏移应修改为 0 0 -3

	- is_weekday、hour_of_day、day_of_week应与线上逻辑相同，is_cp_finish label的缺失值赋值为-1

3.训练集与测试集数据构建 运行数梦上【模型训练V2 -> acc_cr_train_data_v22+acc_cr_val_data_v22】两个文件，运行成功后停止即可，不用每天运行。

**需要注意：**每次重新运行模型训练v2文件夹下的pyspark文件，都需要更改hdfs文件命名【**file = "all_cr_model_test_0120_0126_v2"】**

	- 由于样本特征构建表格中数据已经进行了10%下采样，故训练集直接select 特征即可，但是测试集需要在此基础上再下采样20%

4.运行后需要在hdfs上**拉取数据**（训练集测试集同理，此处仅展示训练集操作）

	- VS code鲁班终端操作命令：hdfs dfs -get /user/prod_kflower_strategy/kflower_strategy/hdp/pricing/zuyao/【hdfs源路径：cr_model_train_0113_0119_v2_modify】  【本地路径：/ofs/pltf-sub-and-pap/chenjiaxi/acc_cr/data/acc_cr_0113_0126】

	- 即hdfs dfs -get <hdfs源路径> <本地路径>

5.将csv文件预处理为npy文件，并计算数据的均值与方差

	- **运行样本预处理文件 **data_utils/data_preprocess.py，可以看到原来拉取的csv文件在同目录下生成了npy文件，并计算好了均值和方差

##### 1.1.1 模型训练

ofs挂载命令：sudo bash /mnt/common/jianshu/ofs/release/current/script/ofs_mount.sh pltf-sub-and-pap /ofs/pltf-sub-and-pap 7b5e8ffd06d84bd18b322c244cfc527c nmgpu

路径：/ofs/pltf-sub-and-pap/chenjiaxi/acc_cr

实验结果文档：[acc_cr模型增加品类特征](https://cooper.didichuxing.com/knowledge/2199610335356/2206622891914/edit)

运行trainer.py

1.注意修改config文件："share_layers": \[==503==,256,256,128\]--第一层数目计算公式 连续特征数+离散特征数 \* embed_dim

**模型训练+消融实验工作流：新建/修改config文件-修改dataloader文件-运行trainer文件**

为了每次消融实验中不再重新生成npy文件，仅修改config文件和dataloader文件后可以实现对消融实验中所需要特征的切片操作

修改config文件：

```PlainText
"data":{
      "num_feature_index":[ 注意这里的索引从4开始]
}
```

2.修改dataloader文件，文件路径dataloader/dataloader.py

> [!example]- PlainText 实现细节（40 行）
> ```PlainText
> 19-28行：特征进行切片
>         self.priority_num = config['data']['priority_num']
>         #消融实验中特征的切片操作
>         if 'num_feature_index' in config['data']:
>             raw_indices = np.array(config['data']['num_feature_index'])
>
>             self.stats_indices = raw_indices - 4 
>             self.numeric_indices = raw_indices
>         else:
>             self.stats_indices = None
>             self.numeric_indices = None
> 33-44行：均值与方差进行切片
>         if training:
>             ##原代码中均值与方差
>             #self.mean = torch.FloatTensor(np.load(os.path.join(data_dir,'mean.npy')))
>             #self.std = torch.FloatTensor(np.load(os.path.join(data_dir,'std.npy')))
>             full_mean = np.load(os.path.join(data_dir,'mean.npy'))
>             full_std = np.load(os.path.join(data_dir,'std.npy'))
>             if self.stats_indices is not None:
>                 self.mean = torch.FloatTensor(full_mean[self.stats_indices])
>                 self.std = torch.FloatTensor(full_std[self.stats_indices])
>             else:
>                 self.mean = torch.FloatTensor(full_mean)
>                 self.std = torch.FloatTensor(full_std)
> 108-117行：对切片的特征进行拼接
>         if self.numeric_indices is not None:
>             # 关键：提取 选中的数值特征 + 最后的3个类别特征
>             total_cols = trace_data.shape[1]
>             cat_indices = np.arange(4,7)
>             # 合并索引：[]
>             use_indices = np.concatenate([cat_indices,self.numeric_indices+3])
>             features = trace_data[:, use_indices]
>         else:
>             # 全量模式：提取第4列到最后一列
>             features = trace_data[:, 4:]
> 124-127行：
>             #提取全量特征
>             #'features': trace_data[:, 4:]
>             #分片提取特征
>             'features': features
> ```


3.修改trainer文件

```PlainText
90-91行：注意这里需要加上离散特征的数目
        #根据特征数量动态调整
        summary(self.model, input_size=(num_feature_dim+3,))
```

##### 1.1.2 模型导出

eve链接：<https://ether.intra.hongyibo.com.cn/labs/new/15369>

注意，若有新的模型导出必须使用【复制到】，进行深拷贝；避免全部新建

![](0a1ce0cbcf7ce644-截屏2026-03-19_16.19.32.png)

- **SQL：**若进行传入特征修改，必须重新获取特征

string类型特征不得传入，特征名称与特征类型均与==建表==保持一致，数梦链接<https://studio.data.didichuxing.com/?projectId=1143&taskId=56456421&subType=LOG>

```PlainText
select 
        cast(1.0 as bigint) as product_id,
        cast(1.0 as bigint) as product_priority,
        cast(1.0 as bigint) as city_id,
        cast(1.0 as bigint) as passenger_id,
        cast(1.0 as bigint) as is_trace_finish,
        cast(1.0 as bigint) as is_cp_finish,
        cast(1.0 as bigint) as is_cp_answer,
        cast(1.0 as bigint) as hour_of_day,
        cast(1.0 as bigint) as day_of_week,
        cast(1.0 as double) as ufbox_basic_fee,
        cast(1.0 as double) as outbox_basic_fee,
        cast(1.0 as double) as uabox_basic_fee,
        cast(1.0 as double) as ufbox_estimate_fee,
        cast(1.0 as double) as outbox_estimate_fee,
        cast(1.0 as double) as uabox_estimate_fee,
        cast(1.0 as double) as ufbox_fee_diff,
        ......
```

- 通用算子：对实时传入特征进行计算，包含城市、格子维度共16个特征，具体计算方法对应数梦表中544-551，562-569行

- 深拷贝

	- 特征列选取选用文本选取，顺序必须和模型入参相同

![](b9aec7596356d35b-截屏2026-03-19_16.30.23.png)

	- 标签列排序和模型需求相同：

![](dd9c53c8d3c0d0db-截屏2026-03-19_16.40.10.png)

	- 代码编辑器：

![](280d88025f826125-截屏2026-03-19_16.41.53.png)

最左侧新建一个文件夹：202601130126 选用的是所用数据时间范围来命名。

将需要上线的模型config文件，‘.pth'文件和训练集mean，std文件导入至新建文件夹内。

修改model.py文件：将路径/ofs/pltf-sub-and-pap/chenjiaxi/acc_cr/model/mmoe.py文件代码复制过来，并修改最后：

```PlainText
129-134行：
        final_preds_tensor = torch.cat(final_preds, dim=-1) 
        out_trace_finish = final_preds_tensor[:, 0:3]
        out_cp_finish = final_preds_tensor[:, 3:6]
        out_cp_ans = final_preds_tensor[:, 6]

        return out_trace_finish, out_cp_finish, out_cp_ans
保证输出个数和label数目保持一致
```

修改make文件

```PlainText
29行修改为新建文件夹名称：
    data_dir = './202601130126'
43行修改为所用模型的名称：
    model = MMoE(config, mean, std)
46行更改modelInputs的路径为新建文件夹.pth文件名称：
    checkpoint = torch.load(os.path.join(data_dir,'epoch_9_0.777865226850675_0.9021496914616915_0.8859795523224887.pth'), map_location=device)
```

全部跑通无报错后，右击最后一个组件，进行导出；注：如果是新增版本，导出类型要选择「模型新版本」

![](a7d0a372782266d2-image.png)

##### 1.1.3 模型部署

##### 1.1.4

#### 1.2 ECR模型

##### 模型部署

## 二、幸运盒子

#### 2.1 幸运盒子B-CPM参数更改

1. 下载最新b-cpm参数表：

```SQL
select    
  *
from    
  kflower_strategy.pltf_union_stg_lucky_box_config
```

2. 将业务给的人工参数补充在最新的b-cpm参数表中，存储为csv

	1. 人工参数：[幸运盒子分区县参数](https://cooper.didichuxing.com/docs2/sheet/2204410129673?sheetId=wXN7m)

	2. 注意删除不需要的列（开城批次、vs实付最低水位等），添加group_id

3. 在数梦上手动上传csv文件至表pltf_union_stg_lucky_box_config

	1. 选择数据导入

![](becbbef3f05568af-截屏2026-03-18_下午5.56.36.png)

	2. 导入至表pltf_union_stg_lucky_box_config，注意检查左侧的数据显示是否正确

![](4a56bcd628640fff-截屏2026-03-18_下午5.58.16.png)

4. 执行解析表的手动任务：<https://studio.data.didichuxing.com/?projectId=1143&taskId=49084479>

	1. 注意执行完成需要后取数验证：

		1. 确保参数与业务给的是一致的，重点检查参数变化的城市

		2. 取数验证已有参数，新日期分区 vs 旧日期分区

> [!example]- PlainText 实现细节（79 行）
> ```PlainText
> WITH t_new AS (
>     -- 获取 2036-03-17 分区数据
>     SELECT
>         group_id,
>         city_id,
>         county_id,
>         date_type,
>         time_bucket,
>         b_cpm_threshold,
>         b_price_threshold,
>         kuaiche_percent,
>         tr,
>         information_fee
>     FROM
>         kflower_strategy.pltf_union_stg_lucky_box_config_hive_middle_table
>     WHERE
>         dt = '2026-03-17'
>         AND group_id IN ('always_show_251205', 'default_251120')
> ),
> t_old AS (
>     -- 获取 2026-01-19 分区数据
>     SELECT
>         group_id,
>         city_id,
>         county_id,
>         date_type,
>         time_bucket,
>         b_cpm_threshold,
>         b_price_threshold,
>         kuaiche_percent,
>         tr,
>         information_fee
>     FROM
>         kflower_strategy.pltf_union_stg_lucky_box_config_hive_middle_table
>     WHERE
>         dt = '2026-01-19'
>         AND group_id IN ('always_show_251205', 'default_251120')
> ),
> diff_info as (
>     SELECT
>         -- 基础关联键（使用 coalesce 确保即使某一方缺失也能显示 key）
>         COALESCE(t_new.group_id, t_old.group_id) AS group_id,
>         COALESCE(t_new.city_id, t_old.city_id) AS city_id,
>         COALESCE(t_new.county_id, t_old.county_id) AS county_id,
>         COALESCE(t_new.date_type, t_old.date_type) AS date_type,
>         COALESCE(t_new.time_bucket, t_old.time_bucket) AS time_bucket,
>         -- 差异标记：如果任何一个核心参数不一致，标记为 1
>         CASE
>             WHEN NVL(t_new.b_cpm_threshold, -999) != NVL(t_old.b_cpm_threshold, -999)
>             OR NVL(t_new.b_price_threshold, -999) != NVL(t_old.b_price_threshold, -999)
>             OR NVL(t_new.kuaiche_percent, -999) != NVL(t_old.kuaiche_percent, -999)
>             OR NVL(t_new.tr, -999) != NVL(t_old.tr, -999)
>             OR NVL(t_new.information_fee, -999) != NVL(t_old.information_fee, -999) THEN 1
>             ELSE 0
>         END AS diff_status,
>         -- 具体参数对比（左侧为新分区，右侧为旧分区）
>         t_new.b_cpm_threshold AS b_cpm_threshold_new,
>         t_old.b_cpm_threshold AS b_cpm_threshold_old,
>         t_new.b_price_threshold AS b_price_threshold_new,
>         t_old.b_price_threshold AS b_price_threshold_old,
>         t_new.kuaiche_percent AS kuaiche_percent_new,
>         t_old.kuaiche_percent AS kuaiche_percent_old,
>         t_new.tr AS tr_new,
>         t_old.tr AS tr_old,
>         t_new.information_fee AS information_fee_new,
>         t_old.information_fee AS information_fee_old
>     FROM
>         t_new FULL
>         OUTER JOIN t_old ON t_new.group_id = t_old.group_id
>         AND t_new.city_id = t_old.city_id
>         AND t_new.county_id = t_old.county_id
>         AND t_new.date_type = t_old.date_type
>         AND t_new.time_bucket = t_old.time_bucket
> )
> select
>     *
> from
>     diff_info
> where diff_status = 1
> ```


		3. 取数验证新参数 vs 旧参数，变化均值，是否符合业务调整方向

> [!example]- PlainText 实现细节（45 行）
> ```PlainText
> WITH base_data AS (
>     -- 基础数据过滤
>     SELECT 
>         city_id,
>         county_id,
>         date_type,
>         time_bucket,
>         b_cpm_threshold,
>         b_price_threshold,
>         kuaiche_percent,
>         tr,
>         information_fee,
>         group_id
>     FROM 
>         kflower_strategy.pltf_union_stg_lucky_box_config_hive_middle_table
>     WHERE 
>         dt = '2026-03-17'
>         AND group_id IN ('default_260318', 'default_251120')
> ),
> group_new AS (
>     -- 提取新组数据 (default_260318)
>     SELECT * FROM base_data WHERE group_id = 'default_260318'
> ),
> group_old AS (
>     -- 提取旧组数据 (default_251120)
>     SELECT * FROM base_data WHERE group_id = 'default_251120'
> )
> SELECT
>     -- 计算各项参数差异的均值 (新 - 旧)
>     AVG(n.b_cpm_threshold - o.b_cpm_threshold)   AS avg_diff_b_cpm_threshold,
>     AVG(n.b_price_threshold - o.b_price_threshold) AS avg_diff_b_price_threshold,
>     AVG(n.kuaiche_percent - o.kuaiche_percent)     AS avg_diff_kuaiche_percent,
>     AVG(n.tr - o.tr)                               AS avg_diff_tr,
>     AVG(n.information_fee - o.information_fee)     AS avg_diff_information_fee,
>     -- 统计参与对比的记录条数
>     COUNT(1) AS compare_count
> FROM 
>     group_new n
> JOIN 
>     group_old o 
> ON 
>     n.city_id = o.city_id 
>     AND n.county_id = o.county_id 
>     AND n.date_type = o.date_type 
>     AND n.time_bucket = o.time_bucket;
> ```


5. 重跑幸运盒子参数表任务：<https://studio.data.didichuxing.com/?projectId=1143&taskId=51969229>

6. 告知工程重跑下游两个任务

## 三、补贴调整

### 3.1 人工buffer调整

```PlainText
SELECT
    city_id,
    object_group,
    stg_group,
    CASE
        WHEN union_buffer = 1 THEN CAST(1 AS DOUBLE)
        ELSE LEAST(CAST(2 AS DOUBLE), union_buffer * 0.5)
    END AS union_buffer,
    '' AS extra_data
FROM kflower_strategy.platform_union_strategy_budget_buffer_by_city_object_stg
WHERE dt = '2026-08-03'
  AND stg_group = 'pltf_union_stg_v3_only_ds_acc_cr_thre'
  AND object_group = 'max_order_v1'
ORDER BY CAST(city_id AS BIGINT)
```

> [!example]- PlainText 实现细节（62 行）
> ```PlainText
> select
>     b.city_id,
>     b.object_group,
>     b.stg_group,
>     case
>         -- 用户指定：7月30日规划补贴率为0的城市不调整
>         when d30.city_id is not null
>          and d30.plan_total_subsidy_rate = 0
>             then b.union_buffer
>         -- 其余城市按7月31日规划/实花比例调整；无有效分母时保持原值
>         when d31.city_id is not null
>          and d31.plan_total_subsidy_rate > 0
>          and d31.subsidy_rate_including_fuse_saved > 0
>             then case
>                 when b.union_buffer
>                      * d31.plan_total_subsidy_rate
>                      / d31.subsidy_rate_including_fuse_saved < 2.99
>                     then b.union_buffer
>                          * d31.plan_total_subsidy_rate
>                          / d31.subsidy_rate_including_fuse_saved
>                 else 2.99
>             end
>         else b.union_buffer
>     end as union_buffer,
>     b.extra_data
> from
>     (
>         select
>             city_id,
>             object_group,
>             stg_group,
>             union_buffer,
>             extra_data
>         from kflower_strategy.platform_union_strategy_budget_buffer_by_city_object_stg
>         where dt = '2026-07-30'
>           and stg_group = 'pltf_union_stg_v3_only_ds_acc_cr_thre'
>     ) b
> left join
>     (
>         select
>             city_id,
>             plan_total_subsidy_rate
>         from kflower_strategy.pltf_union_stg_budget_control_dashboard
>         where dt = '2026-07-30'
>           and city_id not in ('all', 'all2')
>           and exp_group = 'union_stg_v3_max_order_v1_only_box'
>     ) d30
>     on b.city_id = d30.city_id
> left join
>     (
>         select
>             city_id,
>             plan_total_subsidy_rate,
>             subsidy_rate_including_fuse_saved
>         from kflower_strategy.pltf_union_stg_budget_control_dashboard
>         where dt = '2026-07-31'
>           and city_id not in ('all', 'all2')
>           and exp_group = 'union_stg_v3_max_order_v1_only_box'
>     ) d31
>     on b.city_id = d31.city_id
> order by b.city_id
> ;
> ```


luban机器目录：/ofs/pltf-sub-and-pap/chenjiaxi/analysis/buffer

1. 下载Buffer

	1. 更改buffer.sql中的日期

	2. hive -f buffer.sql > buffer_old.csv

2. 下载实花情况

	1. 更改subsidy.sql中的日期

	2. hive -f subsidy.sql > 0508_subsidy.csv

3. 获取新buffer

	1. 执行buffer_spark_new.ipynb

	2. 更改

		1. date

		2. stg_group、exp_group

		3. exp_map

	3. 观察中间输出是否符合预期

		1. only_subsidy：新增城市数据

		2. df_adj\[(df_adj\['new_union_buffer'\] > 2.99)\]：新buffer>2.99的数据

	4. 输出保存在：buffer_result.csv

4. 更改线上数梦任务的buffer

	1. <https://studio.data.didichuxing.com/?projectId=1143&taskId=32407101&subType=LOG>

	2. 提交&发布

5. 执行当天任务并取数验证是否符合预期

```PlainText
select 
    *
from 
    kflower_strategy.platform_union_strategy_budget_buffer_by_city_object_stg
where 
    dt = '2026-04-15'
```

6. 执行下游h2a任务

7. 任务完成后，观察监控

	1. 观察监控中单城、全国的执行补贴率：<https://monitor.xiaojukeji.com/#/woater/dashboard?id=2633593186563393533&cal_type=all&city=0&exp_group_name=all&hit_cache=all&hit_poison=all&stg_version=all&\__time=MINUTE>

	2. 观察流式监控中，实花整体补贴率变化是否预期：<https://monitor.xiaojukeji.com/#/woater/dashboard?\__time=FIVE_MINUTE&biz_type=-1&budget_group=%27all%27&city_id=0&id=2675233023347136509&strategy_group=%27all%27>
