1. Spark相关背景
Spark是一个分布式数据计算的开源项目，最初在2010年由UC Berkeley 的AMP 实验室开发，2014年被Apache接管，并成为其顶级项目[what_is_spark]。Spark的最初提出基于MapReduce的改进，从而在机器学习这种数据复用高，迭代次数多的应用场景取得更快的计算速度。根据Spark官方历史文档介绍，Spark比Memory-based Hadoop MapReduce快100倍，比Disk-based Hadoop MapReduce快10倍（最新文档已经删去相关论述）。
Spark的出现给大数据计算带来了巨大进步：不仅并行程序易于编写，性能也有巨大提升。Spark曾经是“全能王”，后被各个领域的platform逐渐取代，如tensorflow，Flink。


1.1. 竞争对手
Flink：具有流式数据处理的能力，延迟为毫秒级；Spark的流式处理本质上是micro-batch，延迟只能做到秒级
TensorFlow: 对深度模型的支持更好，效率更高；Spark机器学习因其DAG限制，需要频繁进行数据shuffle，效率低
2. Spark基本架构
我们用到的Spark基本上都是跑在YARN集群上，因此下面主要讲基于YARN的架构。先介绍几个术语[https://spark.apache.org/docs/latest/cluster-overview.html]：
Application: 用户编译好的的Spark程序，包括一个Driver程序和运行在多个Executor上的代码
Driver（类似于team leader）: 运行Driver Program，在Spark中有SparkContext负责与ClusterManager通信，进行资源申请、任务的分配和监控等
Worker Node（类似于工区）: 集群中可运行Application代码的节点
Executor（类似于team member）: 运行Task的的进程，其中Executor的core数为其执行task的最大并发数
Task（类似于需求）：任务执行单元

Spark大致的工作流程如下：
用户提交Spark Application，Driver启动，启动SparkContext
SparkContext向Cluster Manager(YARN)发送消息，申请计算资源
Cluster Manager进行资源分配，并且把Executor的地址等信息发给SparkContext(Driver)
SparkContext把要运行的代码发送给Executor
SparkContext把Task发给Executor，并回收运行结果


2.1. YARN
YARN (Yet Another Resource Negotiator) 是Hadoop的资源管理框架。下图是hadoop生态中YARN的定位[https://medium.com/@chenglong.w1/demystifying-yarn-understanding-its-architecture-components-and-how-it-works-738dd95ad453]

下图是YARN的架构与工作流程简图[https://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/YARN.html]

关键概念解释[https://zhuanlan.zhihu.com/p/54192454]
Container: YARN对资源的抽象，由NodeManager进行启动，监控和管理
ResourceManager：RM，系统中只有1个，负责资源管理和调度
ApplicationMaster：AM，client提交任务后建立一个AM，
NodeManager：NM，物理机上RM的代理，向RM汇报资源使用情况

提交一个Application到YARN的完整流程图


2.2. HDFS
HDFS (Hadoop Distributed File System) 是Hadoop的分布式文件系统，架构如下[https://medium.com/analytics-vidhya/understanding-hadoop-hdfs-e0821c5fadc3]

2.3. Launching Mode
yarn-client: driver运行在client（用户所在的机器）进程里，executor在集群里
spark-submit --conf spark.driver.host=10.84.176.122 --master yarn --deploy-mode client --queue root.kflower_strategy_prod main.py
yarn-cluster: driver和executor都在集群里
spark-submit --master yarn --deploy-mode cluster --queue root.kflower_strategy_prod datagenerate.py
spark-shell with yarn-client mode: 可交互的spark编程环境，也是yarn-client模式，一般可以用于调试代码或者做数据分析
pyspark --queue=root.kflower_strategy_prod --conf spark.driver.host=10.84.176.122 
2.4. PySpark vs ScalaSpark
绝大多数情况下，PySpark和ScalaSpark运行速度一致
计算密集型的程序中，要避免过多的udf


3. Spark核心计算原理
3.1. Dataset, Dataframe, RDD
Spark2.0以前，最常用的数据抽象方案是RDD (Resilient Distributed Dataset), 2.0往后，RDD逐渐被Dataset这种优化更好的API[https://spark.apache.org/docs/latest/sql-programming-guide.html]。其中Dataset是type-safe的，但其带来的缺点也显而易见，程序员需要花很多精力在处理数据类型上面；Dataframe是一种特殊的Dataset，它把所有的列封装到一个Row对象里面。一些文章从用户角度对比Dataframe，Dataset和RDD[https://sparkbyexamples.com/spark/spark-rdd-vs-dataframe-vs-dataset/]。
3.2. Lazy Evaluation
spark中对于数据的操作分为2类：transformation和action。其中transformation指filter, map, repartition这种不需要对结果进行展示或者写磁盘的操作[https://spark.apache.org/docs/latest/rdd-programming-guide.html#transformations]；而action指collect, head, toPandas, write这类需要对结果进行展示或者写磁盘的操作。
spark中所有transformation都采用lazy evaluation(惰性执行)的方式[https://blog.damavis.com/en/apache-spark-transformations-and-lazy-evaluation/]。因此，当执行transformation时，它们在底层并不会被真正执行，而是被延迟，直到遇到action，spark才会根据action依赖的所有运行动作构建DAG，对transformation进行优化并执行。以下是一个简单的例子：
rdd= sc.textFile("file.csv")
transformation_1 = rdd.map(parsedLine_returningTuple) 
transformation_2 = transformation_1.filter(lambda x: "FILTER" in x[1])
transformation_3 = transformation_2.map(lambda x: (x[0], x[2]))
transformation_4 = transformation_3.reduceByKey(lambda x, y: min(x, y))
print(transformation_4.toDebugString())
这么做一个最明显的好处就是，spark可以把任务做一个整体的优化，大大减少预算量和GC代价。
3.3. Shuffle
Shuffle是spark进行数据重新分片的一种事件，Spark中很多操作都会触发shuffle[https://spark.apache.org/docs/latest/rdd-programming-guide.html#shuffle-operations]。Shuffle的一个显著特点就是代价高，主要原因是其需要把数据进行executor之间的传输，代价来自3个方面：磁盘IO，数据序列化，网络IO。因其代价高昂，spark很多优化都是针对shuffle的[http://lionheartwang.github.io/blog/2018/03/11/spark-shuffle-implementation/]。
通常来说，类似repartition，join和sort这种，需要按照key把数据进行重新分片的操作，都会触发shuffle，因此一个常用的spark优化技巧就是通过代码的重新设计减少shuffle次数。辨别是否需要shuffle的一个方法就是识别RDD或Dataset之间的依赖属于宽依赖(ShuffleDependency)还是窄依赖(NarrowDependency)[https://blog.csdn.net/Colton_Null/article/details/112299969]。当然，也可以通过理解shuffle的底层代码逻辑[https://0x0fff.com/spark-architecture-shuffle/]。
3.4. Persistance
Spark支持显式地对中间结果进行缓存来减少重复计算，方法是persist()或cache()。根据不同的需要，可以通过设置StorageLevel来指定数据缓存在内存（默认）里还是磁盘里。一个较好的习惯是，在persist的数据使用完（这里需要考虑lazy evaluation）以后，进行unpersist来释放内存。persist另外一个风险就是占用太多内存，导致计算得不到足够内存而速度变慢甚至OOM。
4. 常见问题和优化技巧
阅读本章需要有一定的spark或者sparkSQL使用经验。
4.1. OOM
首先通过日志和TrackingURL判断是driver OOM还是executor OOM。如果是driver OOM，那么可以[https://i.xiaojukeji.com/way/article/11301941?from=personal]
增加driver内存，其中对于yarn-client模式的任务，如果本地内存小，可能要切换到yarn-cluster
减少由action操作导致的大量数据塞进driver里，如toPandas, collect等
如果是executor导致的OOM，那么可以
增加每个core的内存量，减少spark.executor.cores或者增加spark.executor.memory
排除是否因为数据倾斜导致的个别executor OOM[https://i.xiaojukeji.com/way/article/11331137?from=personal]
增加partition数量来使每个task处理的数据量更少
4.2. 运行速度优化
通过日志排除因为申请不到资源hang住[https://i.xiaojukeji.com/way/article/11315851?from=personal]
通过TrackingURL排除因为UDF等局部逻辑导致死循环或长循环[https://i.xiaojukeji.com/way/article/11318349]
打开TrackingURL需要配置代理[http://wiki.intra.xiaojukeji.com/pages/viewpage.action?pageId=689557979]
排除因为内存占用等问题导致的FullGC [https://i.xiaojukeji.com/way/article/11315851?from=personal]
可能是因为persist了太多的数据导致内存占用高，其他计算获取不到足够的内存，因此JVM进行FullGC以释放内存
也可能是driver内存占用高导致FullGC
对于重复用到的中间结果进行persist或cache
合理配置partition number提高并行效率
文件数少而大，并且对原数据进行了丰富的transformation操作，实际并发数少导致负载及其不均衡运行慢；对原文件进行repartition操作可以提高并发数（侧面说明了hdfs文件过大的危害）
优化算法减少shuffle次数
4.3. 查看TrackingURL
先为你的chrome浏览器安装插件SwitchyOmega
打开SwitchyOmega的option界面
增加Proxy Profile，路径为：+new profile... -> Proxy Profile，然后按照如下截图配置
增加auto switch，路径为+new profile... -> auto switch，然后按照如下截图配置：
或者导入下列pac文件来配置auto switch

需要浏览trackingURL的时候，手动切换到proxy，或者常年使用auto switch，后者的缺点是不能使用VPN作为默认proxy
Reference
大数据引擎发布的分享列表：https://i.xiaojukeji.com/way/article/11484806
pyspar和spark对比：https://mungingdata.com/apache-spark/python-pyspark-scala-which-better/
spark中文介绍：https://cloud.tencent.com/developer/article/1559471
spark提出的论文：https://www.usenix.org/legacy/event/hotcloud10/tech/full_papers/Zaharia.pdf
yarn 教程：https://zhuanlan.zhihu.com/p/54192454
yarn doc：https://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/YARN.html
spark on yarn：https://spark.apache.org/docs/latest/running-on-yarn.html
spark configuration: https://spark.apache.org/docs/latest/configuration.html


