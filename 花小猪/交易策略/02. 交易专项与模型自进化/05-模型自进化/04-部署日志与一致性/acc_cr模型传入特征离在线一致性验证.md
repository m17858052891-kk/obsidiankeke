---
title: "acc_cr模型传入特征离在线一致性验证"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2205469953172
cssclasses: ["strategy-body-note"]
---

# acc_cr模型传入特征离在线一致性验证

[Cooper 原文](https://cooper.didichuxing.com/knowledge/2199610335356/2205469953172)

先定位时间距离、价格及传入特征处理问题；逐条 trace 差异是复查证据，已集中折叠，所有原数值仍可展开检索。

**阅读定位**　[[#问题1：estimate_dur、start_dest_dis|问题1：estimate_dur、start_dest_dis]] · [[#问题2：传入价格|问题2：传入价格]] · [[#传入特征处理问题|传入特征处理问题]]

## 问题1：estimate_dur、start_dest_dis
> [!example]- 逐单差异明细（所有 trace 与原始数值）
>
> ```PlainText
> trace_id: e0e8bf1f68d40a4f17061a7010d70303 product_id: 5216.0
> 特征 线上真实值 训练数据值
> estimate_v 7.037037037037037 4.897436
> ufbox_cpm 0.22210526315789475 0.220942
> uabox_estimate_fee 607 647.0
> ufbox_iph 1.5629629629629629 1.082051
> uabox_fee_diff 60 20.0
> uabox_iph 1.2351851851851852 0.855128
> start_dest_dis 3800 3820.0
> estimate_dur 540 780.0
> outbox_iph 1.3037037037037038 0.902564
> ```
>
> 很多trace
>
>
> trace_id: aed75d2868d407b48505b6facf1bd29e product_id: 538.0
>
> 特征 线上真实值 训练数据值
>
> uabox_iph 1.5547619047619048 1.674359
>
> uabox_estimate_fee 1071 1267.0
>
> estimate_dur 840 780.0
>
> start_dest_dis 10800 10830.0
>
> uabox_fee_diff 235 39.0
>
> outbox_iph 1.8273809523809523 1.967949
>
> ufbox_iph 2.0595238095238093 2.217949
>
> estimate_v 12.857142857142858 13.884615
>
>
>
> trace_id: 6f01c10c68d411d87b1446c110bd0303 product_id: 386.0
>
> 特征 线上真实值 训练数据值
>
> estimate_v 7.142857142857143 7.238095
>
> uabox_fee_diff 0 52.0
>
> uabox_estimate_fee 883 831.0
>
> start_dest_dis 3000 3040.0
>
>
>
> trace_id: 8781716468d411dc0000751acf1cffd1 product_id: 5276.0
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6300 6310.0
>
> estimate_v 9.545454545454545 9.560606
>
>
>
> trace_id: 61fc78cf68d40f8082ba18b2aadcaefc product_id: 5160.0
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 13200 13170.0
>
> uabox_estimate_fee 2317 2391.0
>
> estimate_v 7.857142857142857 8.442308
>
> ufbox_iph 1.9077380952380953 2.054487
>
> uabox_fee_diff 147 73.0
>
> uabox_iph 1.4666666666666666 1.579487
>
> estimate_dur 1680 1560.0
>
> outbox_iph 1.6648809523809525 1.792949
>
>
>
> trace_id: fbf324a468d4145084f371ebd4dd94c0 product_id: 569.0
>
> 特征 线上真实值 训练数据值
>
> uabox_cpm 0.295 0.296347
>
> uabox_estimate_fee 649 552.0
>
> ufbox_cpm 0.36954545454545457 0.371233
>
> uabox_fee_diff 0 97.0
>
> estimate_v 6.111111111111111 6.083333
>
> start_dest_dis 2200 2190.0
>
> outbox_cpm 0.3209090909090909 0.322374
>
>
>
> trace_id: 7ba3a73168d40d13a6f4655ddce18272 product_id: 571.0
>
> 特征 线上真实值 训练数据值
>
> estimate_v 8.03921568627451 8.0
>
> ufbox_cpm 0.22353658536585366 0.224632
>
> start_dest_dis 8200 8160.0
>
>
>
> trace_id: 83c04b5668d41080b01b5848f05cd7b3 product_id: 488.0
>
> 特征 线上真实值 训练数据值
>
> outbox_cpm 0.20622222222222222 0.207606
>
> ufbox_cpm 0.2508888888888889 0.252573
>
> uabox_cpm 0.1991111111111111 0.200447
>
> estimate_v 9.375 9.3125
>
> start_dest_dis 4500 4470.0
>
>
>
> trace_id: 9ebf794268d40f1983de5bf7c0bf354c product_id: 5160.0
>
> 特征 线上真实值 训练数据值
>
> uabox_cpm 0.49923076923076926 0.503101
>
> start_dest_dis 1300 1290.0
>
> uabox_fee_diff 38 58.0
>
> uabox_estimate_fee 611 591.0
>
> outbox_cpm 0.5815384615384616 0.586047
>
> ufbox_cpm 0.6253846153846154 0.630233
>
> estimate_v 7.222222222222222 7.166667
>
>
>
> trace_id: 4d741f4f68d411a8000068200570d0ce product_id: 497.0
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 11817 11820.0
>
> estimate_v 10.365789473684211 10.368421
>
>
>
> trace_id: 21fe105c68d4106b861f242310e60303 product_id: 416.0
>
> 特征 线上真实值 训练数据值
>
> estimate_v 15.114942528735632 15.12069
>
> start_dest_dis 26300 26310.0
>
>
>
> trace_id: aed75d2868d407b48505b6facf1bd29e product_id: 305.0
>
> 特征 线上真实值 训练数据值
>
> uabox_fee_diff 235 39.0
>
> uabox_estimate_fee 1071 1267.0
>
> start_dest_dis 10800 10830.0
>
> estimate_v 13.846153846153847 13.884615
>
>
>
> trace_id: 790a383268d40a3389082b87acad6bac product_id: 275.0
>
> 特征 线上真实值 训练数据值
>
> outbox_cpm 0.17810810810810812 0.175733
>
> start_dest_dis 3700 3750.0
>
> uabox_fee_diff 68 34.0
>
> estimate_v 6.851851851851852 6.944444
>
> ufbox_cpm 0.2 0.197333
>
> uabox_cpm 0.15405405405405406 0.152
>
> uabox_estimate_fee 502 536.0
>
>
>
> trace_id: d439181668d40cd29566c49159f1f051 product_id: 294.0
>
> 特征 线上真实值 训练数据值
>
> uabox_cpm 0.18739130434782608 0.186043
>
> ufbox_cpm 0.2482608695652174 0.246475
>
> outbox_cpm 0.20782608695652174 0.206331
>
> start_dest_dis 6900 6950.0
>
> estimate_v 6.052631578947368 6.096491
>
>
>
> trace_id: c711138168d40aad000065cec36ad775 product_id: 420.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_cpm 0.265 0.263636
>
> outbox_cpm 0.22913793103448277 0.227959
>
> uabox_estimate_fee 1209 1173.0
>
> estimate_v 10.74074074074074 10.796296
>
> start_dest_dis 5800 5830.0
>
> uabox_cpm 0.20844827586206896 0.207376
>
> uabox_fee_diff 0 36.0
>
>
>
> trace_id: 606b48c468d4106795d10a1be5964cb6 product_id: 348.0
>
> 特征 线上真实值 训练数据值
>
> uabox_fee_diff 166 33.0
>
> uabox_estimate_fee 944 1077.0
>
>
>
> trace_id: 7a6c138668d4082682b17cfd0f5865df product_id: 415.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_cpm 0.3011111111111111 0.3
>
> start_dest_dis 2700 2710.0
>
> outbox_cpm 0.2762962962962963 0.275277
>
> estimate_v 7.5 7.527778
>
> uabox_estimate_fee 649 591.0
>
> uabox_fee_diff 0 58.0
>
>
>
> trace_id: 1c60c04868d40942b4c3d3c23a1a368c product_id: 80.0
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 16900 16860.0
>
> estimate_v 8.802083333333334 8.78125
>
>
>
> trace_id: 75deeac468d4124ea9ee3f368aca4fdd product_id: 304.0
>
> 特征 线上真实值 训练数据值
>
> uabox_fee_diff 192 0.0
>
> uabox_iph 1.115625 1.226042
>
> uabox_cpm 0.14472972972972972 0.159918
>
> uabox_estimate_fee 879 1177.0
>
> ufbox_cpm 0.18743243243243243 0.188451
>
> uabox_basic_fee 1071 1177.0
>
>
>
> trace_id: 1c60c04868d40942b4c3d3c23a1a368c product_id: 80.0
>
> 特征 线上真实值 训练数据值
>
> estimate_v 8.802083333333334 8.78125
>
> start_dest_dis 16900 16860.0
>
>
>
> trace_id: aed75d2868d407b48505b6facf1bd29e product_id: 297.0
>
> 特征 线上真实值 训练数据值
>
> uabox_fee_diff 117 39.0
>
> estimate_v 13.846153846153847 13.884615
>
> start_dest_dis 10800 10830.0
>
> uabox_estimate_fee 1189 1267.0
>
>
>
> trace_id: 390897d668d4026300005c4231174aa0 product_id: 280.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_cpm 0.34241379310344827 0.347203
>
> uabox_cpm 0.26068965517241377 0.264336
>
> outbox_cpm 0.2996551724137931 0.303846
>
> start_dest_dis 2900 2860.0
>
> estimate_v 6.904761904761905 6.809524
>
>
>
> trace_id: 6ee5d21668d40ef8ad2cb2ef5e4bec92 product_id: 5189.0
>
> 特征 线上真实值 训练数据值
>
> uabox_estimate_fee 748 772.0
>
> uabox_fee_diff 47 23.0
>
>
>
> trace_id: 790a383268d40a3389082b87acad6bac product_id: 5018.0
>
> 特征 线上真实值 训练数据值
>
> uabox_estimate_fee 502 536.0
>
> outbox_cpm 0.17675675675675676 0.1744
>
> uabox_cpm 0.15405405405405406 0.152
>
> ufbox_cpm 0.2 0.197333
>
> start_dest_dis 3700 3750.0
>
> estimate_v 6.851851851851852 6.944444
>
> uabox_fee_diff 68 34.0
>
>
>
> trace_id: 1108959968d408dfaa7fc253fa16b402 product_id: 345.0
>
> 特征 线上真实值 训练数据值
>
> uabox_fee_diff 145 48.0
>
> uabox_iph 1.4210526315789473 1.285714
>
> outbox_iph 1.6464912280701753 1.489683
>
> estimate_dur 1140 1260.0
>
> uabox_estimate_fee 1475 1572.0
>
> start_dest_dis 9300 9320.0
>
> ufbox_iph 1.8859649122807018 1.706349
>
> estimate_v 8.157894736842104 7.396825
>
>
>
> trace_id: 464c473e68d407df00007155cecb40ac product_id: 386.0
>
> 特征 线上真实值 训练数据值
>
> estimate_v 6.25 6.291667
>
> outbox_cpm 0.30833333333333335 0.306291
>
> ufbox_cpm 0.35533333333333333 0.35298
>
> start_dest_dis 3000 3020.0
>
> uabox_cpm 0.29433333333333334 0.292384
>
>
>
> trace_id: fc146dad68d4080d0000496c21856e86 product_id: 386.0
>
> 特征 线上真实值 训练数据值
>
> estimate_v 11.666666666666666 11.696078
>
> uabox_estimate_fee 2009 2222.0
>
> start_dest_dis 11900 11930.0
>
> uabox_fee_diff 354 141.0
>
>
>
> trace_id: 434d40e168d410468a1dbe36733fc507 product_id: 349.0
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 9000 8980.0
>
> uabox_estimate_fee 1035 1225.0
>
> estimate_v 7.5 7.483333
>
> uabox_fee_diff 227 37.0
>
>
>
> trace_id: b7fc644c68d40d468a43396809efb6ec product_id: 5104.0
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4100 4110.0
>
> estimate_v 7.592592592592593 7.611111
>
>
>
> trace_id: e0e8bf1f68d40a4f17061a7010d70303 product_id: 5216.0
>
> 特征 线上真实值 训练数据值
>
> estimate_v 7.037037037037037 4.897436
>
> ufbox_cpm 0.22210526315789475 0.220942
>
> uabox_estimate_fee 607 647.0
>
> ufbox_iph 1.5629629629629629 1.082051
>
> uabox_fee_diff 60 20.0
>
> uabox_iph 1.2351851851851852 0.855128
>
> start_dest_dis 3800 3820.0
>
> estimate_dur 540 780.0
>
> outbox_iph 1.3037037037037038 0.902564
>
>
>
> trace_id: f1e49b5768d412d4e52ba3b110820303 product_id: 593.0
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 11500 11520.0
>
> uabox_fee_diff 147 98.0
>
> uabox_estimate_fee 1497 1546.0
>
> estimate_v 10.648148148148149 10.666667
>
>
>
> trace_id: 2531765568d40d2bb733f64da5dd070e product_id: 497.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_iph 1.584848484848485 1.515942
>
> outbox_iph 1.584848484848485 1.515942
>
> estimate_dur 1320 1380.0
>
> estimate_v 7.892424242424243 7.550725
>
> uabox_iph 1.8636363636363635 1.782609
>
> start_dest_dis 10418 10420.0
>
>
>
> trace_id: c0a8010968d410d23a0f6c2410500503 product_id: 571.0
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 8300 8450.0
>
> estimate_v 7.280701754385965 7.412281
>
>
>
> trace_id: be15011868d4084cc1cddf4f10760303 product_id: 236.0
>
> 特征 线上真实值 训练数据值
>
> outbox_iph 3.4862745098039216 4.558974
>
> estimate_dur 2040 1560.0
>
> estimate_v 11.803921568627452 15.435897
>
> ufbox_iph 3.4862745098039216 4.558974
>
> uabox_estimate_fee 3692 3936.0
>
> uabox_fee_diff 365 121.0
>
> uabox_iph 1.9887254901960785 2.600641
>
>
>
> trace_id: aed75d2868d407b48505b6facf1bd29e product_id: 534.0
>
> 特征 线上真实值 训练数据值
>
> estimate_dur 840 780.0
>
> uabox_estimate_fee 1071 1267.0
>
> uabox_fee_diff 235 39.0
>
> outbox_iph 1.7678571428571428 1.903846
>
> uabox_iph 1.5547619047619048 1.674359
>
> ufbox_iph 2.0595238095238093 2.217949
>
> estimate_v 12.857142857142858 13.884615
>
> start_dest_dis 10800 10830.0
>
>
>
> trace_id: 4c713b6a68d4102fdc240358106e0403 product_id: 236.0
>
> 特征 线上真实值 训练数据值
>
> uabox_iph 1.485 1.747059
>
> estimate_v 8.933333333333334 10.509804
>
> outbox_iph 2.4783333333333335 2.915686
>
> estimate_dur 1200 1020.0
>
> ufbox_iph 2.4783333333333335 2.915686
>
>
>
> trace_id: ef4b170e68d41101a91b222410360403 product_id: 5490.0
>
> 特征 线上真实值 训练数据值
>
> estimate_v 9.166666666666666 9.333333
>
> outbox_cpm 0.40954545454545455 0.402232
>
> ufbox_cpm 0.4713636363636364 0.462946
>
> start_dest_dis 2200 2240.0
>
> uabox_cpm 0.3718181818181818 0.365179
>
>
>
> trace_id: 61fc78cf68d40f8082ba18b2aadcaefc product_id: 375.0
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 13100 13170.0
>
> estimate_v 8.397435897435898 8.442308
>
> ufbox_cpm 0.24465648854961833 0.243356
>
> uabox_estimate_fee 2317 2391.0
>
> uabox_fee_diff 147 73.0
>
> outbox_cpm 0.2082442748091603 0.207137
>
>
>
> trace_id: 0808162d68d409da00003e52cf851642 product_id: 5034.0
>
> 特征 线上真实值 训练数据值
>
> estimate_v 5.462962962962963 5.481481
>
> start_dest_dis 5900 5920.0
>
>
>
> trace_id: 0e74abc468d40c579524cf5fc5eb466c product_id: 280.0
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 35900 35850.0
>
> uabox_iph 1.9366666666666668 1.889431
>
> outbox_iph 2.3441666666666667 2.286992
>
> uabox_estimate_fee 4648 4370.0
>
> ufbox_iph 2.7108333333333334 2.644715
>
> estimate_v 14.958333333333334 14.573171
>
> estimate_dur 2400 2460.0
>
> uabox_fee_diff 0 278.0
>
>
>
> trace_id: 34f7076568d40afe8c9bf1cd24493699 product_id: 416.0
>
> 特征 线上真实值 训练数据值
>
> uabox_iph 2.062962962962963 0.807246
>
> start_dest_dis 5700 5740.0
>
> ufbox_iph 2.6425925925925924 1.034058
>
> estimate_v 10.555555555555555 4.15942
>
> estimate_dur 540 1380.0
>
> outbox_iph 2.1944444444444446 0.858696
>
>
>
> trace_id: c0a800e068d4133d8ea4246b10870403 product_id: 5256.0
>
> 特征 线上真实值 训练数据值
>
> uabox_cpm 0.19880597014925372 0.2
>
> start_dest_dis 6700 6660.0
>
> ufbox_cpm 0.2653731343283582 0.266967
>
> outbox_cpm 0.2317910447761194 0.233183
>
> uabox_fee_diff 39 0.0
>
> estimate_v 10.151515151515152 10.090909
>
> uabox_estimate_fee 1293 1332.0
>
>
>
> trace_id: 0808162d68d409da00003e52cf851642 product_id: 368.0
>
> 特征 线上真实值 训练数据值
>
> uabox_iph 1.2645833333333334 1.124074
>
> ufbox_iph 1.821875 1.619444
>
> estimate_dur 960 1080.0
>
> start_dest_dis 5855 5860.0
>
> estimate_v 6.098958333333333 5.425926
>
> outbox_iph 1.821875 1.619444
>
>
>
> trace_id: d07f5e5f68d409358d41a28f108f0303 product_id: 304.0
>
> 特征 线上真实值 训练数据值
>
> outbox_iph 1.3 1.361905
>
> uabox_iph 1.187878787878788 1.384127
>
> uabox_estimate_fee 1286 1744.0
>
> uabox_fee_diff 282 0.0
>
> estimate_dur 1320 1260.0
>
> uabox_cpm 0.14654205607476636 0.163143
>
> estimate_v 8.106060606060606 8.492063
>
> uabox_basic_fee 1568 1744.0
>
> ufbox_iph 1.5469696969696969 1.620635
>
>
>
> trace_id: 0ae18be868d40a64625fb4a0106a0303 product_id: 346.0
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 8000 8040.0
>
> uabox_fee_diff 467 271.0
>
> ufbox_cpm 0.259625 0.258333
>
> estimate_v 13.333333333333334 13.4
>
> uabox_estimate_fee 1075 1271.0
>
> outbox_cpm 0.23225 0.231095
>
>
>
> trace_id: 0ae18be868d40a64625fb4a0106a0303 product_id: 275.0
>
> 特征 线上真实值 训练数据值
>
> uabox_estimate_fee 1075 1271.0
>
> uabox_fee_diff 467 271.0
>
> estimate_v 13.333333333333334 13.4
>
> outbox_cpm 0.228 0.226866
>
> start_dest_dis 8000 8040.0
>
> ufbox_cpm 0.259625 0.258333
>
>
>
> trace_id: 1252c53168d40e1ebff0dc96ebba6b82 product_id: 5477.0
>
> 特征 线上真实值 训练数据值
>
> uabox_estimate_fee 1969 2170.0
>
> estimate_v 16.574074074074073 16.583333
>
> uabox_fee_diff 268 67.0
>
> start_dest_dis 17900 17910.0
>
>
>
> trace_id: e9ee4ea168d41183882ae4c373ff503d product_id: 5018.0
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 9000 8990.0
>
> estimate_v 10 9.988889
>
>
>
> trace_id: 4e1a27e868d410d5972bfacefc64d12d product_id: 5599.0
>
> 特征 线上真实值 训练数据值
>
> uabox_iph 1.7338383838383837 1.907222
>
> ufbox_iph 2.4318181818181817 2.675
>
> estimate_v 10.858585858585858 11.944444
>
> outbox_iph 2.103030303030303 2.313333
>
> uabox_fee_diff 900 344.0
>
> uabox_estimate_fee 2533 3089.0
>
> estimate_dur 1980 1800.0
>
>
>
> trace_id: 439c636f68d414b18f45c23525ed8077 product_id: 236.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_iph 2.315942028985507 4.097436
>
> outbox_iph 2.315942028985507 4.097436
>
> uabox_estimate_fee 1827 1663.0
>
> estimate_v 6.3768115942028984 11.282051
>
> estimate_dur 1380 780.0
>
> uabox_fee_diff 429 593.0
>
> uabox_iph 1.6347826086956523 2.892308
>
>
>
> trace_id: c8ad483568d40b598b21ee63d33d09d1 product_id: 275.0
>
> 特征 线上真实值 训练数据值
>
>
>
> trace_id: f22011d468d41500a984143e27de1ff3 product_id: 415.0
>
> 特征 线上真实值 训练数据值
>
> uabox_estimate_fee 577 655.0
>
> start_dest_dis 5100 5060.0
>
> estimate_v 10.625 10.541667
>
> ufbox_cpm 0.16745098039215686 0.168775
>
> uabox_fee_diff 78 0.0
>
> outbox_cpm 0.14823529411764705 0.149407
>
> uabox_cpm 0.1284313725490196 0.129447
>
>
>
> trace_id: b5de4a1868d40de3be43792f62286091 product_id: 5007.0
>
> 特征 线上真实值 训练数据值
>
> uabox_estimate_fee 768 936.0
>
> start_dest_dis 6100 6130.0
>
> uabox_fee_diff 168 0.0
>
> estimate_v 6.354166666666667 6.385417
>
>
>
> trace_id: 7b67c43b68d41438b047d0af60455006 product_id: 5264.0
>
> 特征 线上真实值 训练数据值
>
> outbox_iph 2.6305555555555555 3.156667
>
> uabox_iph 2.6305555555555555 3.156667
>
> estimate_v 5.277777777777778 6.333333
>
> ufbox_iph 2.6305555555555555 3.156667
>
> estimate_dur 360 300.0
>
>
>
> trace_id: faf839c068d40f70ab8602306686ced5 product_id: 346.0
>
> 特征 线上真实值 训练数据值
>
> estimate_v 6.111111111111111 6.0
>
> uabox_estimate_fee 699 560.0
>
> start_dest_dis 1100 1080.0
>
> ufbox_cpm 0.8036363636363636 0.818519
>
> outbox_cpm 0.7372727272727273 0.750926
>
> uabox_cpm 0.6354545454545455 0.647222
>
> uabox_fee_diff 0 139.0
>
>
>
> trace_id: 0808162d68d409da00003e52cf851642 product_id: 538.0
>
> 特征 线上真实值 训练数据值
>
> estimate_v 5.462962962962963 5.481481
>
> start_dest_dis 5900 5920.0
>
>
>
> trace_id: 3fc5f51a68d408ebb3504fb67b616da1 product_id: 349.0
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 11500 11450.0
>
> estimate_v 10.648148148148149 10.601852
>
>
>
> trace_id: 9f519cb068d40123a0e9825f205520c0 product_id: 373.0
>
> 特征 线上真实值 训练数据值
>
> uabox_estimate_fee 958 1056.0
>
> start_dest_dis 8200 8240.0
>
> estimate_v 9.11111111111111 9.155556
>
> uabox_fee_diff 130 32.0
>
>
>
> trace_id: bd6dfd8268d40fc4b69450e57fccb309 product_id: 486.0
>
> 特征 线上真实值 训练数据值
>
> uabox_fee_diff 156 58.0
>
> estimate_v 10.74074074074074 10.759259
>
> start_dest_dis 5800 5810.0
>
> uabox_estimate_fee 561 659.0
>
>
>
> trace_id: fe8adeb268d4124ebb4ae57d3b723e5f product_id: 557.0
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 9500 9490.0
>
> estimate_v 11.30952380952381 11.297619
>
>
>
> trace_id: 57a9a5c168d40a05a5f7f655b7a7cd37 product_id: 390.0
>
> 特征 线上真实值 训练数据值
>
> estimate_v 9.583333333333334 9.53125
>
> ufbox_cpm 0.18978260869565217 0.19082
>
> start_dest_dis 9200 9150.0
>
>
>
> trace_id: 5a3f459768d41465b4f43437b1f530d6 product_id: 458.0
>
> 特征 线上真实值 训练数据值
>
> uabox_fee_diff 105 0.0
>
> uabox_estimate_fee 770 875.0
>
>
>
> trace_id: 64b054d068d40804b7e0c89b7e6b595d product_id: 5020.0
>
> 特征 线上真实值 训练数据值
>
> uabox_estimate_fee 911 971.0
>
> uabox_fee_diff 90 30.0
>
>
>
> trace_id: 434d40e168d410468a1dbe36733fc507 product_id: 438.0
>
> 特征 线上真实值 训练数据值
>
> uabox_fee_diff 151 37.0
>
> estimate_v 7.5 7.483333
>
> uabox_estimate_fee 1111 1225.0
>
> start_dest_dis 9000 8980.0
>
>
>
> trace_id: b484523368d3fc209824c2b533f348fc product_id: 527.0
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 20400 20370.0
>
> estimate_v 10.96774193548387 10.951613
>
>
>
> trace_id: 023c9de768d40f0dac806f44c2e3afab product_id: 488.0
>
> 特征 线上真实值 训练数据值
>
> estimate_v 9.23611111111111 9.256944
>
> uabox_estimate_fee 1498 1710.0
>
> start_dest_dis 13300 13330.0
>
> uabox_fee_diff 264 52.0
>
>
>
> trace_id: e7d3ca2968d4154e905dd0c2ec87419d product_id: 80.0
>
> 特征 线上真实值 训练数据值
>
>
>
> trace_id: 487a36bd68d4105fb452c010a479dc3c product_id: 345.0
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 7100 7080.0
>
> estimate_v 10.757575757575758 10.727273
>
>
>
> trace_id: 74a2472a68d410f6b8afc64c1eeb2771 product_id: 281.0
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 7500 7510.0
>
> estimate_v 9.615384615384615 9.628205
>
>
>
> trace_id: e4c1755868d40e6500000b46b5bdbf45 product_id: 593.0
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3400 3390.0
>
> estimate_v 7.083333333333333 7.0625
>
>
>
> trace_id: 344f29c768d40cb8813a5f025f79e207 product_id: 529.0
>
> 特征 线上真实值 训练数据值
>
> uabox_cpm 0.20310344827586208 0.199661
>
> uabox_estimate_fee 1037 1178.0
>
> ufbox_cpm 0.27827586206896554 0.273559
>
> uabox_fee_diff 141 0.0
>
> start_dest_dis 5800 5900.0
>
> estimate_v 6.444444444444445 6.555556
>
> outbox_cpm 0.24793103448275863 0.243729
>
>
>
> trace_id: ffa8a8a768d40f2700001498b72928e5 product_id: 236.0
>
> 特征 线上真实值 训练数据值
>
> estimate_dur 720 600.0
>
> ufbox_iph 2.408333333333333 2.89
>
> uabox_iph 1.4125 1.695
>
> uabox_estimate_fee 861 888.0
>
> uabox_fee_diff 156 129.0
>
> estimate_v 8.208333333333334 9.85
>
> outbox_iph 2.408333333333333 2.89
>
>
>
> trace_id: 00fab46f68d410f2aca4168a2a528260 product_id: 5034.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_iph 2.332738095238095 2.252299
>
> estimate_v 12.619047619047619 12.183908
>
> outbox_iph 2.0154761904761904 1.945977
>
> estimate_dur 1680 1740.0
>
> uabox_estimate_fee 2319 2828.0
>
> uabox_fee_diff 509 0.0
>
> uabox_iph 1.6833333333333333 1.625287
>
>
>
> trace_id: 2b128e8e68d40952b01b52fd5613b377 product_id: 5372.0
>
> 特征 线上真实值 训练数据值
>
> uabox_cpm 0.18689655172413794 0.190175
>
> uabox_estimate_fee 1052 889.0
>
> uabox_fee_diff 32 195.0
>
> start_dest_dis 5800 5700.0
>
> ufbox_cpm 0.24517241379310345 0.249474
>
> outbox_cpm 0.2143103448275862 0.21807
>
> estimate_v 7.435897435897436 7.307692
>
>
>
> trace_id: ac140a0268d40e64ecfd737210120403 product_id: 5492.0
>
> 特征 线上真实值 训练数据值
>
> uabox_fee_diff 0 113.0
>
> estimate_v 12.543859649122806 12.570175
>
> uabox_estimate_fee 1891 1778.0
>
> start_dest_dis 14300 14330.0
>
>
>
> trace_id: d9faac4168d40f62b12f3bdbf7fc42a3 product_id: 527.0
>
> 特征 线上真实值 训练数据值
>
> uabox_fee_diff 0 260.0
>
> estimate_v 15.476190476190476 15.464286
>
> uabox_estimate_fee 1739 1479.0
>
> start_dest_dis 13000 12990.0
>
>
>
> trace_id: 8c02f5b968d403fd00005a6f9ca60bd8 product_id: 5427.0
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3200 3150.0
>
> estimate_v 7.619047619047619 7.5
>
> ufbox_cpm 0.2578125 0.261905
>
> uabox_cpm 0.2153125 0.21873
>
> outbox_cpm 0.2209375 0.224444
>
>
>
> trace_id: 5fc7e40268d40b4192bc339b06e714d0 product_id: 388.0
>
> 特征 线上真实值 训练数据值
>
> uabox_iph 3.1708333333333334 2.717857
>
> outbox_iph 3.9131944444444446 3.354167
>
> estimate_dur 1440 1680.0
>
> ufbox_iph 4.454166666666667 3.817857
>
> start_dest_dis 23400 23380.0
>
> estimate_v 16.25 13.916667
>
>
>
> trace_id: 9ac77e8668d3fb68a2ca3291d78c0495 product_id: 386.0
>
> 特征 线上真实值 训练数据值
>
> uabox_estimate_fee 1497 1423.0
>
> uabox_fee_diff 0 74.0
>
>
>
> trace_id: f79cbcfb68d40805b576ce645dd0066a product_id: 401.0
>
> 特征 线上真实值 训练数据值
>
> estimate_v 5.833333333333333 5.916667
>
> outbox_cpm 1.1128571428571428 1.097183
>
> ufbox_cpm 1.282857142857143 1.264789
>
> uabox_cpm 1 0.985915
>
> start_dest_dis 700 710.0
>
>
>
> trace_id: 1fcc6c0268d40a21b4221c0c9fd1e7d9 product_id: 304.0
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 14400 14350.0
>
> estimate_v 12.631578947368421 12.587719
>
>
>
> trace_id: ca07fca368d407ee9d86392028b87225 product_id: 5111.0
>
> 特征 线上真实值 训练数据值
>
> uabox_cpm 0.556 0.541558
>
> uabox_fee_diff 125 0.0
>
> ufbox_cpm 0.7046666666666667 0.686364
>
> uabox_estimate_fee 709 834.0
>
> outbox_cpm 0.6166666666666667 0.600649
>
> start_dest_dis 1500 1540.0
>
> estimate_v 8.333333333333334 8.555556
>
>
>
> trace_id: 0a56231768d40f1a872620f666a27347 product_id: 5036.0
>
> 特征 线上真实值 训练数据值
>
> uabox_estimate_fee 2273 2348.0
>
> estimate_v 9.516129032258064 9.510753
>
> start_dest_dis 17700 17690.0
>
> uabox_fee_diff 224 149.0
>
>
>
> trace_id: 7901c4e468d40953aaaab8910231787d product_id: 458.0
>
> 特征 线上真实值 训练数据值
>
> estimate_v 8.333333333333334 8.363636
>
> start_dest_dis 5500 5520.0
>
>
>
> trace_id: fde2d7fc68d40d7eb33e1f3d719854b7 product_id: 438.0
>
> 特征 线上真实值 训练数据值
>
> estimate_v 8.75 8.78125
>
> uabox_fee_diff 46 138.0
>
> start_dest_dis 8400 8430.0
>
> uabox_estimate_fee 1492 1400.0
>
>
>
> trace_id: 4ee7fc1468d40d65bdc02e9710d20303 product_id: 5277.0
>
> 特征 线上真实值 训练数据值
>
> uabox_estimate_fee 890 1085.0
>
> start_dest_dis 9300 9310.0
>
> estimate_v 10.333333333333334 10.344444
>
> uabox_fee_diff 496 301.0
>
>
>
> trace_id: f6ca326868d40c10863784faa88ca446 product_id: 5160.0
>
> 特征 线上真实值 训练数据值
>
> uabox_estimate_fee 1707 1654.0
>
> uabox_fee_diff 594 647.0
>
>
>
> trace_id: 21fe105c68d4106b861f242310e60303 product_id: 236.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_iph 2.7241935483870967 2.912069
>
> outbox_iph 2.7241935483870967 2.912069
>
> estimate_dur 1860 1740.0
>
> uabox_iph 1.8112903225806452 1.936207
>
> estimate_v 13.96774193548387 14.931034
>
>
>
> trace_id: c428364068d4070d85ece7f2847d6b6f product_id: 5180.0
>
> 特征 线上真实值 训练数据值
>
>
>
> trace_id: 14d1760468d409bfa1b9b569217cc93d product_id: 5533.0
>
> 特征 线上真实值 训练数据值
>
> uabox_fee_diff 320 665.0
>
> estimate_v 10.178571428571429 10.202381
>
> uabox_estimate_fee 2878 2533.0
>
> start_dest_dis 17100 17140.0
>
>
>
> trace_id: 05f04e4f68d40a1ac3c9e36d10700303 product_id: 345.0
>
> 特征 线上真实值 训练数据值
>
> uabox_fee_diff 72 144.0
>
> uabox_estimate_fee 1133 1061.0
>
> start_dest_dis 8300 8340.0
>
> estimate_v 9.880952380952381 9.928571
>
>
>
> trace_id: 756075ff68d40838000075401ef1ea8e product_id: 5048.0
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 14100 14090.0
>
> estimate_v 12.368421052631579 12.359649
>
> uabox_fee_diff 639 691.0
>
> uabox_estimate_fee 1633 1581.0
>
>
>
> trace_id: 57a9a5c168d40a05a5f7f655b7a7cd37 product_id: 294.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_cpm 0.18978260869565217 0.19082
>
> start_dest_dis 9200 9150.0
>
> estimate_v 9.583333333333334 9.53125
>
>
>
> trace_id: 977497e468d41119bc38cd371e1d3237 product_id: 5176.0
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 23900 23930.0
>
> estimate_v 10.213675213675213 10.226496
>
>
>
> trace_id: 115d998668d40ba7bb8d439599a40ba8 product_id: 5049.0
>
> 特征 线上真实值 训练数据值
>
> uabox_estimate_fee 649 585.0
>
> start_dest_dis 2800 2820.0
>
> uabox_fee_diff 0 64.0
>
> estimate_v 9.333333333333334 9.4
>
>
>
> trace_id: 30f1d83268d41398ba79efb40710ef19 product_id: 407.0
>
> 特征 线上真实值 训练数据值
>
> estimate_v 7.696666666666666 7.7
>
> start_dest_dis 2309 2310.0
>
>
>
> trace_id: 205e205d68d40c49a301d71410400403 product_id: 80.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_cpm 0.5435714285714286 0.547482
>
> estimate_dur 240 180.0
>
> outbox_iph 2.7416666666666667 3.655556
>
> outbox_cpm 0.47 0.473381
>
> estimate_v 5.833333333333333 7.777778
>
> ufbox_iph 3.1708333333333334 4.227778
>
> uabox_cpm 0.43714285714285717 0.440288
>
> uabox_iph 2.55 3.4
>
>
>
> trace_id: 53a1ef9168d40772a2173c1b830f1909 product_id: 5160.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_cpm 0.5123809523809524 0.502804
>
> estimate_v 5.833333333333333 5.944444
>
> uabox_cpm 0.39 0.38271
>
> outbox_cpm 0.42952380952380953 0.421495
>
> start_dest_dis 2100 2140.0
>
>
>
> trace_id: 023c9de768d40f0dac806f44c2e3afab product_id: 272.0
>
> 特征 线上真实值 训练数据值
>
> estimate_v 9.23611111111111 9.256944
>
> start_dest_dis 13300 13330.0
>
> uabox_estimate_fee 1498 1710.0
>
> uabox_fee_diff 264 52.0
>
>
>
> trace_id: b88cd39368d4131ca38522e0c0f62784 product_id: 438.0
>
> 特征 线上真实值 训练数据值
>
> uabox_cpm 0.1988709677419355 0.200814
>
> start_dest_dis 6200 6140.0
>
> uabox_estimate_fee 1123 1233.0
>
> estimate_v 9.393939393939394 9.30303
>
> ufbox_cpm 0.2540322580645161 0.256515
>
> outbox_cpm 0.21177419354838709 0.213844
>
> uabox_fee_diff 110 0.0
>
>
>
> trace_id: 71197db568d40ec285f0e7143297847b product_id: 438.0
>
> 特征 线上真实值 训练数据值
>
> 结论：
>
> - 原因：策略侧计算estimate_dur、start_dest_dis时，max(X) as X group by trace_id，是冒泡维度；工程侧传入是冒泡X商家维度的
>
> - 解决方案：策略侧改逻辑，与工程拉齐
>
> 	- 工程逻辑：==盒子外>特价盒子内>特快盒子内，baseInfo按这个优先级，start_dest_dis，city_input_start_end_distance，estimate_dur均用的baseInfo==
>
> 后续：
>
> - 需要确认trace维度、cp维度
>
> - 看是工程的逻辑问题还是sql底表的问题
>
> - 排查sds、dufe特征的空值率、均值等，空值必须传-9999
>

## 问题2：传入价格
> [!example]- 逐单差异明细（所有 trace 与原始数值）
>
> 特价盒子应付、特快盒子应付/实付、盒子外应付/实付
>
> ```PlainText
> **************************************************
> trace_id: b484523368d3fc209824c2b533f348fc product_id: 5264.0
> 特征 线上真实值 训练数据值
> ufbox_estimate_fee 2927（盒子外应付） 3350.0 
> **************************************************
> trace_id: d3e7feba68d40c9300001ac60019cd33 product_id: 484.0
> 特征 线上真实值 训练数据值
> ufbox_basic_fee 2032 1778.0
> ```
>
> 很多trace
>
>
> trace_id: 75deeac468d4124ea9ee3f368aca4fdd product_id: 304.0
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 1071 1177.0
>
>
>
> trace_id: d07f5e5f68d409358d41a28f108f0303 product_id: 304.0 **【****南宁，有出行快选，1744是出行快选的价格****】**
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 1568 1744.0
>
>
>
> trace_id: 75deeac468d4124ea9ee3f368aca4fdd product_id: 80.0【**南宁**】
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 1164 1177.0
>
>
>
> trace_id: b484523368d3fc209824c2b533f348fc product_id: 5264.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_fee_diff 600 0.0
>
>
>
> trace_id: b484523368d3fc209824c2b533f348fc product_id: 5264.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_estimate_fee 2927 3350.0
>
>
>
> trace_id: b484523368d3fc209824c2b533f348fc product_id: 5264.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 3527 3350.0
>
>
>
> trace_id: b484523368d3fc209824c2b533f348fc product_id: 5264.0
>
> 特征 线上真实值 训练数据值
>
> outbox_estimate_fee 2927 3350.0
>
>
>
> trace_id: b484523368d3fc209824c2b533f348fc product_id: 5264.0
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 3527 3350.0
>
>
>
> trace_id: b746511168d4114b8ef6dc632686b4f0 product_id: 80.0
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 1065 1077.0
>
>
>
> trace_id: 5c82d69e68d40796a82153e85ad9bb8f product_id: 304.0
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 667 708.0
>
>
>
> trace_id: d3e7feba68d40c9300001ac60019cd33 product_id: 484.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_estimate_fee 2032 1778.0
>
>
>
> trace_id: d3e7feba68d40c9300001ac60019cd33 product_id: 484.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 2032 1778.0
>
>
>
> trace_id: 1e9db11968d40776bab1517ae3f0bfc3 product_id: 80.0
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 956 967.0
>
>
>
> trace_id: c0a8010368d4048ab5f94598106e0303 product_id: 348.0
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 643 681.0
>
>
>
> trace_id: d3e7feba68d40c9300001ac60019cd33 product_id: 5111.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 2032 1835.0
>
>
>
> trace_id: d3e7feba68d40c9300001ac60019cd33 product_id: 5111.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_estimate_fee 2032 1835.0
>
>
>
> trace_id: c0a865ee68d414435201973b10960503 product_id: 497.0
>
> 特征 线上真实值 训练数据值
>
> outbox_estimate_fee 580 654.0
>
>
>
> trace_id: c0a865ee68d414435201973b10960503 product_id: 497.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 664 654.0
>
>
>
> trace_id: c0a865ee68d414435201973b10960503 product_id: 497.0
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 664 654.0
>
>
>
> trace_id: c0a865ee68d414435201973b10960503 product_id: 497.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_estimate_fee 580 654.0
>
>
>
> trace_id: c0a865ee68d414435201973b10960503 product_id: 497.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_fee_diff 84 0.0
>
>
>
> trace_id: 3e98b91a68d40938ab5878631b5b6038 product_id: 304.0
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 779 837.0
>
>
>
> trace_id: e0e8bf1f68d40a4f17061a7010d70303 product_id: 80.0
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 697 708.0
>
>
>
> trace_id: d3e7feba68d40c9300001ac60019cd33 product_id: 305.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_estimate_fee 2032 1883.0
>
>
>
> trace_id: d3e7feba68d40c9300001ac60019cd33 product_id: 305.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 2032 1883.0
>
>
>
> trace_id: d3e7feba68d40c9300001ac60019cd33 product_id: 297.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 2032 1780.0
>
>
>
> trace_id: d3e7feba68d40c9300001ac60019cd33 product_id: 297.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_estimate_fee 2032 1780.0
>
>
>
> trace_id: b9afd79c68d4000f8d6fa7dfb6efeafb product_id: 304.0
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 776 831.0
>
>
>
> trace_id: b9afd79c68d4000f8d6fa7dfb6efeafb product_id: 80.0
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 814 831.0
>
>
>
> trace_id: 1e9db11968d40776bab1517ae3f0bfc3 product_id: 304.0
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 893 967.0
>
>
>
> trace_id: 2b0ad22768d410f4aafa0cb959991a92 product_id: 373.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_estimate_fee 1717 1500.0
>
>
>
> trace_id: 2b0ad22768d410f4aafa0cb959991a92 product_id: 373.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 1717 1500.0
>
>
>
> trace_id: 438d3d8a68d40c57aa50d93f69988ecd product_id: 304.0
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 667 708.0
>
>
>
> trace_id: 6e730ccf68d40dbf9e99cac2e4a24b18 product_id: 5020.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_fee_diff 500 516.0
>
>
>
> trace_id: 6e730ccf68d40dbf9e99cac2e4a24b18 product_id: 5020.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 634 593.0
>
>
>
> trace_id: 6e730ccf68d40dbf9e99cac2e4a24b18 product_id: 5020.0
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 634 593.0
>
>
>
> trace_id: 6e730ccf68d40dbf9e99cac2e4a24b18 product_id: 5020.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_estimate_fee 134 77.0
>
>
>
> trace_id: 6e730ccf68d40dbf9e99cac2e4a24b18 product_id: 5020.0
>
> 特征 线上真实值 训练数据值
>
> outbox_estimate_fee 134 77.0
>
>
>
> trace_id: 6e730ccf68d40dbf9e99cac2e4a24b18 product_id: 5020.0
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 634 593.0
>
>
>
> trace_id: 4a48261268d40cc700001c16bbea4d06 product_id: 304.0
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 1236 1356.0
>
>
>
> trace_id: e8d33d6a68d4134d397e2cbe10d30303 product_id: 533.0
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 3536 2449.0
>
>
>
> trace_id: d3e7feba68d40c9300001ac60019cd33 product_id: 375.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 2032 1790.0
>
>
>
> trace_id: d3e7feba68d40c9300001ac60019cd33 product_id: 375.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_estimate_fee 2032 1790.0
>
>
>
> trace_id: 30d428e168d41414baf203a386ee261d product_id: 124008.0
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 3650 2606.0
>
>
>
> trace_id: 30d428e168d41414baf203a386ee261d product_id: 124008.0
>
> 特征 线上真实值 训练数据值
>
> outbox_estimate_fee 3650 2606.0
>
>
>
> trace_id: 30d428e168d41414baf203a386ee261d product_id: 124008.0
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 3650 2606.0
>
>
>
> trace_id: e96e026a68d409b28f0906887a4d9ac5 product_id: 497.0
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 649 530.0
>
>
>
> trace_id: e96e026a68d409b28f0906887a4d9ac5 product_id: 497.0
>
> 特征 线上真实值 训练数据值
>
> outbox_estimate_fee 591 530.0
>
>
>
> trace_id: e96e026a68d409b28f0906887a4d9ac5 product_id: 497.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_estimate_fee 591 530.0
>
>
>
> trace_id: e96e026a68d409b28f0906887a4d9ac5 product_id: 497.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 649 530.0
>
>
>
> trace_id: e96e026a68d409b28f0906887a4d9ac5 product_id: 497.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_fee_diff 58 0.0
>
> ### trace_id: b484523368d3fc209824c2b533f348fc product_id: 5264.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_estimate_fee 2927（盒子外应付） 3350.0 
>
> bubble_base表数据
>
> | trace_id | product_id | level_type | start_dest_dis_noncarpool | basic_total_fee_amt | estimate_fee_amt |
> | --- | --- | --- | --- | --- | --- |
> | b484523368d3fc209824c2b533f348fc | 5264 | 0 | 20.3 | 3350 | 3350 |
> | b484523368d3fc209824c2b533f348fc | 5264 | 105 | 20.3 | 3527 | 2927 |
>
> 处理结果值：
>
> > [!example]- 完整数据表（2 行记录）
> > | trace_id | estimate_id | product_id | passenger_id | hour_of_day | day_of_week | is_weekday | city_id | product_priority | ufbox_basic_fee | outbox_basic_fee | uabox_basic_fee | ufbox_estimate_fee | outbox_estimate_fee | uabox_estimate_fee | appear_position | priority_rank |
> > | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
> > | b484523368d3fc209824c2b533f348fc | 294d723ace036a36d9e61127b0c3b0c6 | 5264 | 52779255674471 | 22 | 4 | 1 | 160 | 1 | 3350 | 3350 | 3527 | 3350 | 3350 | 2927 | 15 | 1 |
> > | b484523368d3fc209824c2b533f348fc | 294d723ace036a36d9e61127b0c3b0c6 | 5264 | 52779255674471 | 22 | 4 | 1 | 160 | 1 | 3350 | 3350 | 3527 | 3350 | 3350 | 2927 | 16 | 2 |
>
>
> - 策略侧结论：策略处理无问题
>
> - 工程侧结论：
>
> 	- 原因：价格折叠逻辑，productId 5264 被应付折叠：特价盒子应付3527，盒子外3350，盒子外的被折叠了，最终只有特价盒子的，那么就是用的特价盒子
>
> 	- 解决方案：工程侧，将应付折叠放在cr模型之后
>
> ### trace_id: d3e7feba68d40c9300001ac60019cd33 product_id: 484.0
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 2032 1778.0
>
> bubble_base底表：
>
> | trace_id | product_id | level_type | start_dest_dis_noncarpool | basic_total_fee_amt | estimate_fee_amt |
> | --- | --- | --- | --- | --- | --- |
> | d3e7feba68d40c9300001ac60019cd33 | 484 | 107 | 11.61 | 1494 | 1494 |
> | d3e7feba68d40c9300001ac60019cd33 | 484 | 0 | 11.6 | 1778 | 1778 |
> | d3e7feba68d40c9300001ac60019cd33 | 484 | 105 | 11.61 | 1540 | 1540 |
>
> 处理结果值：
>
> ```PlainText
> max(if(level_type in (200, 101), basic_total_fee_amt, null)) as ufbox_basic_fee,
> max(if(level_type in (0, 102, 103), basic_total_fee_amt, null)) as outbox_basic_fee,
> max(if(level_type in (104, 105, 107,202), basic_total_fee_amt, null)) as uabox_basic_fee,
> COALESCE(ufbox_basic_fee, outbox_basic_fee, uabox_basic_fee) as ufbox_basic_fee,
> COALESCE(outbox_basic_fee, uabox_basic_fee, ufbox_basic_fee) as outbox_basic_fee,
> COALESCE(uabox_basic_fee, outbox_basic_fee, ufbox_basic_fee) as uabox_basic_fee,
> ```
>
> > [!example]- 完整数据表（2 行记录）
> > | trace_id | estimate_id | product_id | passenger_id | city_id | ufbox_basic_fee | outbox_basic_fee | uabox_basic_fee | ufbox_estimate_fee | outbox_estimate_fee | uabox_estimate_fee | appear_position | priority_rank |
> > | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
> > | d3e7feba68d40c9300001ac60019cd33 | d965f7d6e8eba48bfa320ccd2a1b38c0 | 484 | 35184604434003 | 58 | 1778 | 1778 | 1540 | 1778 | 1778 | 1540 | 6 | 1 |
> > | d3e7feba68d40c9300001ac60019cd33 | 82edd180af1bd6c24c9fe57f1cf5062d | 484 | 35184604434003 | 58 | 1778 | 1778 | 1540 | 1778 | 1778 | 1540 | 47 | 2 |
>
>
> - 策略侧结论：策略处理无问题
>
> - 工程侧结论：
>
> 	- 原因：线上请求里是有特快盒子的，但是离线bubble_base表中没有特快盒子品类；
>
> 	- 解决方案：看这部分冒泡的比例，比例低则忽略
>
> ### 出行快选
>
> 上线的城市去除出行快选所在城市：南宁、成都、大同、齐齐哈尔
>
> 训练数据不去除
>

## 传入特征处理问题

基于冒泡的所有品类，处理这些传入字段

| 类型 | 特征 | 维度 | 备注 |
| --- | --- | --- | --- |
| 传入价格 | basic_total_fee <br>estimate_fee <br>fee_diff = basic_total_fee - estimate_fee | trace_id、product_id、【特快盒子、盒子外、特价盒子】 | 缺失时，按照【盒子外&gt;特价盒子内&gt;特快盒子内】的优先级填充 |
| 订单信息 | start_dest_dis <br>estimate_dur <br>estimate_v = start_dest_dis / estimate_dur | trace_id、product_id | 按照盒子外&gt;特价盒子&gt;特快盒子优先级，取优先级高的 <br>原因：理论上不同level_type的订单时长、距离不会有变化 |
| 计算值 | cpm=basic_total_fee / start_dest_dis <br>iph=basic_total_fee / estimate_dur | trace_id、product_id、【特快盒子、盒子外、特价盒子】 | 取完以上值后计算 <br> |

1. 对于自营80品类，product_id=80

	1. 盒子外：小猪一口价（102）、小猪打车（103）

		1. 由于**二者互斥**，不会同时出现，因此取max = 取出现的品类的值

		2. 应付：取2个的最大

		3. 实付：取2个的最大

		4. eta、距离：应付最大值对应的level_type对应的eta = 取max

	2. 特价盒子：特价盒子内的小猪特价（105）、超值达（201，端内无）、~~出行快选（202）~~

		1. **小猪特价和超值达是互斥的**，不会同时出现，取max=取出现品类的值；

		2. 出行快选处理：训练时丢**弃所有出行快选开城城市的冒泡；线上暂不对开出行快选的城市做实验**

		3. 应付：取2个的最大

		4. 实付：取2个的最大

		5. eta、距离：应付最大值对应的level_type对应的eta = 取max

	3. 特快盒子：特快盒子内的小猪特快（200）

		1. 同上

	4. 对于应付、实付只要缺失，就按照【==盒子外>特价盒子内>特快盒子内】的优先级填充；不缺失则用自己的==

	5. 对于eta、距离，按照【==盒子外>特价盒子内>特快盒子内】的优先级取数==

	6. 填充完后，对于iph、cpm，按照填充好的值进行计算

		1. iph=应付/eta

		2. cpm=应付/eta

2. 对于宏鹄，product_id !=80

	1. 盒子外：普通品类（0）

	2. 特价盒子：特价盒子（105）、超值达（201）

		1. 特价盒子与超值达互斥，不会同时出现，取max=取出现品类的值；

	3. 特快盒子：特快盒子（200）

	4. 对于应付、实付只要缺失，就按照【==盒子外>特价盒子内>特快盒子内】的优先级填充；不缺失则用自己的==

	5. 对于eta、距离，按照【==盒子外>特价盒子内>特快盒子内】的优先级取数==

	6. 填充完后，对于iph、cpm，按照填充好的值进行计算

		1. iph=应付/eta

		2. cpm=应付/eta

## 发单优先级处理

参考文档：<https://cooper.didichuxing.com/docs2/document/2203352674960>

| 相对优先级 | 不同品类优先级可相同 | 取模型的值 |
| --- | --- | --- |
| 3 | 101（小猪特快）、200（特快盒子） | 取特快盒子 |
| 2 | 0（普通品类）、102（小猪一口价）、103（小猪打车） | 取盒子外 |
| 1 | 104（小猪特价）、105（特价盒子）、~~202（出行快选）~~、201（超值达） | 取特价盒子 |
| 0 | 107（幸运盒子） | 取特价盒子 |
| 绝对优先级 | 相对优先级相同的品类，若实付不一致时，按实付价格高的，发单优先级高；若实付一致，理论应该用绝对优先级，此处忽略这个问题 | |

## 问题1014
> [!example]- 逐单差异明细（所有 trace 与原始数值）
>
> 约50%的trace，etd不同
>
> 约5%的trace，传入价格特征不同
>
> 所有不同的特征
> ---
>
> trace_id: bd96c24268ecfd64384ed00f10930303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 13504 13500.0
>
> ---
>
> trace_id: 2f0c047d68ecfd0b8d446dbf71af7b66 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4359 4360.0
>
> ---
>
> trace_id: aad6aa4668ecfad600004d941529f12d product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2931 2930.0
>
> ---
>
> trace_id: e7bb1ea468ecf818be674790a9d8fc09 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 9689 9690.0
>
> ---
>
> trace_id: e7bb1ea468ecf818be674790a9d8fc09 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 1900 1995.0
>
> ---
>
> trace_id: e7bb1ea468ecf818be674790a9d8fc09 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 1900 1995.0
>
> ---
>
> trace_id: e7bb1ea468ecf818be674790a9d8fc09 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 1900 1995.0
>
> ---
>
> trace_id: f48df62d68ed01fc856e8d11a913c9ec product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5127 5130.0
>
> ---
>
> trace_id: a1eeb50f68ed055bb46da7f740a5d163 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 35153 35150.0
>
> ---
>
> trace_id: a114fd8668ed0129b8d42bf25df6ceff product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3117 3120.0
>
> ---
>
> trace_id: 5cf8ec1c68ed01580000530834f2898e product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 17545 17550.0
>
> ---
>
> trace_id: 81d47c3868ecf91d973867c035309b0f product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2491 2490.0
>
> ---
>
> trace_id: dc590f1068ecfcaef0b8e17a10ab0303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3055 3060.0
>
> ---
>
> trace_id: 53f4feaa68ed02b4a1d9539628addc3c product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3273 3270.0
>
> ---
>
> trace_id: 3893362368ecfaa79dca84969a6b2469 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3595 3600.0
>
> ---
>
> trace_id: 7cb79b6468ed004ff306214e10720303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5953 5950.0
>
> ---
>
> trace_id: ca6f09af68ed05d0a33cf9b53382ae5a product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 12536 12540.0
>
> ---
>
> trace_id: cbf13ff968ecfcca00003a04ad101ffd product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 12826 12830.0
>
> ---
>
> trace_id: 057ef85f68ecfef0e2fa508210840303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 21701 21700.0
>
> ---
>
> trace_id: f89b9fe168ecfcc98f16d5a403c563fa product_id: 384
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 830 844.0
>
> ---
>
> trace_id: f89b9fe168ecfcc98f16d5a403c563fa product_id: 384
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3203 3200.0
>
> ---
>
> trace_id: f89b9fe168ecfcc98f16d5a403c563fa product_id: 384
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 830 844.0
>
> ---
>
> trace_id: f89b9fe168ecfcc98f16d5a403c563fa product_id: 384
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 830 844.0
>
> ---
>
> trace_id: 0a798b1268ecfb1e00004f58f320c611 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 785 793.0
>
> ---
>
> trace_id: 0a798b1268ecfb1e00004f58f320c611 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 785 793.0
>
> ---
>
> trace_id: 0a798b1268ecfb1e00004f58f320c611 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 785 793.0
>
> ---
>
> trace_id: 0a798b1268ecfb1e00004f58f320c611 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3783 3780.0
>
> ---
>
> trace_id: c0a8008568ecf7e40b1bd140108e0303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5692 5690.0
>
> ---
>
> trace_id: 62ec613268ecfb9500000d2eb6a71752 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2877 2880.0
>
> ---
>
> trace_id: c0a8010768ed05483f1e3659106d0303 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 1820 1840.0
>
> ---
>
> trace_id: c0a8010768ed05483f1e3659106d0303 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 7333 7330.0
>
> ---
>
> trace_id: c0a8010768ed05483f1e3659106d0303 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 1820 1840.0
>
> ---
>
> trace_id: c0a8010768ed05483f1e3659106d0303 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 1820 1840.0
>
> ---
>
> trace_id: 2d2488e168ed000fbbf24e2dfd4b75db product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 7176 7180.0
>
> ---
>
> trace_id: 9352c6cf68ecfda7bfe1e3bcd3f087f1 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 14809 14810.0
>
> ---
>
> trace_id: a1ea481f68ecfbe2d116876010890303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5534 5530.0
>
> ---
>
> trace_id: 0ddc700968ecfce493253b483947e5f2 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1221 1220.0
>
> ---
>
> trace_id: f000d09368ecf9cf9899b5dd6c8f9b17 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5508 5510.0
>
> ---
>
> trace_id: df0810c468ed00c60000395016a45202 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5089 5090.0
>
> ---
>
> trace_id: 235dba1e68ed019b3860df3e10950303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 8718 8720.0
>
> ---
>
> trace_id: a9e4152268ecf9299411437146a7baa1 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 20765 20770.0
>
> ---
>
> trace_id: 5aade2b768ecfc788370170c11931e34 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 26181 26180.0
>
> ---
>
> trace_id: f619cd3568ecff6cb9601f9e2c299895 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2975 2980.0
>
> ---
>
> trace_id: da9a82ee68ecfa3687196af1b13e1e33 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 8139 8140.0
>
> ---
>
> trace_id: a42a928a68ecfe459be3bcfbd9387b67 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 12159 12160.0
>
> ---
>
> trace_id: 021ee0bf68ecf92e00007bf727e903ce product_id: 384
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 970 990.0
>
> ---
>
> trace_id: 021ee0bf68ecf92e00007bf727e903ce product_id: 384
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2524 2520.0
>
> ---
>
> trace_id: 021ee0bf68ecf92e00007bf727e903ce product_id: 384
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 970 990.0
>
> ---
>
> trace_id: 021ee0bf68ecf92e00007bf727e903ce product_id: 384
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 970 990.0
>
> ---
>
> trace_id: 915ec26f68ed00c000000ec2f6061ba3 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1652 1650.0
>
> ---
>
> trace_id: 915ec26f68ed00c000000ec2f6061ba3 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1613 1610.0
>
> ---
>
> trace_id: cfae13f968ecf8da0000632590a4f0cf product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2039 2040.0
>
> ---
>
> trace_id: 72a0b0b968ecf8e1af34b79482043ad8 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2571 2570.0
>
> ---
>
> trace_id: dac45cd668ecfcc9b90ecd9e8c3ef97c product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6039 6040.0
>
> ---
>
> trace_id: b314dfa668ecfcbf84346aad5e68b9f9 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4593 4590.0
>
> ---
>
> trace_id: 12ec3d2068ed02a48dcd385b20f4d9a4 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3286 3290.0
>
> ---
>
> trace_id: c06ba4bc68ed0536801e71634bd01ef4 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 7048 7050.0
>
> ---
>
> trace_id: e7bb1ea468ecf818be674790a9d8fc09 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 9594 9590.0
>
> ---
>
> trace_id: b595519568ecff89000018c2e13584c5 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6547 6550.0
>
> ---
>
> trace_id: 10150caa68ed00ada57192273fb8ed48 product_id: 5340
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 1543 -9999.0
>
> ---
>
> trace_id: 10150caa68ed00ada57192273fb8ed48 product_id: 5340
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 1543 -9999.0
>
> ---
>
> trace_id: 10150caa68ed00ada57192273fb8ed48 product_id: 5340
>
> 特征 线上真实值 训练数据值
>
> estimate_dur 1500 -9999.0
>
> ---
>
> trace_id: 10150caa68ed00ada57192273fb8ed48 product_id: 5340
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 1543 -9999.0
>
> ---
>
> trace_id: 10150caa68ed00ada57192273fb8ed48 product_id: 5340
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 10000 -9999.0
>
> ---
>
> trace_id: 860e086968ed0366000067c9e7a1e5ec product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 11613 11610.0
>
> ---
>
> trace_id: 997ce12968ecf818b1a37131b9499549 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5956 5960.0
>
> ---
>
> trace_id: 730778f768ecfdbcbfa8d7ff390f6449 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5565 5570.0
>
> ---
>
> trace_id: 81002bdc68ecf961a4e96916947c23a2 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 10057 10060.0
>
> ---
>
> trace_id: 7794790368ed01aa000063bf547c1637 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 23099 23100.0
>
> ---
>
> trace_id: 7a01c5fe68ecfc4fa12a11cbf6760b5c product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6066 6070.0
>
> ---
>
> trace_id: 021ee0bf68ecf92e00007bf727e903ce product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2681 2680.0
>
> ---
>
> trace_id: 021ee0bf68ecf92e00007bf727e903ce product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2906 2910.0
>
> ---
>
> trace_id: 22a684c068ecf92cbab8c8bb76d1eab1 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2626 2630.0
>
> ---
>
> trace_id: 898c394768ed0405bb336b8a10780303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5952 5950.0
>
> ---
>
> trace_id: f8633ac468ecfcfbb83f2dd221b13d92 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3874 3870.0
>
> ---
>
> trace_id: a404a10a68ecfb35b46a24397ef0362f product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3246 3250.0
>
> ---
>
> trace_id: bfe9a9f068ecfbdb9720b4e523b5e8ca product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2449 2450.0
>
> ---
>
> trace_id: 01fc1e0a68ecfbaba7133a2b39f0212c product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6332 6330.0
>
> ---
>
> trace_id: 349ed24468ed04219a404ade6c3ef685 product_id: 344
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5369 5370.0
>
> ---
>
> trace_id: c6118d8168ecfc17000048bbbb3ae4b7 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4301 4300.0
>
> ---
>
> trace_id: 68c3c09868ecfe89a83934e011d3628a product_id: 344
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3718 3720.0
>
> ---
>
> trace_id: 68c3c09868ecfe89a83934e011d3628a product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3725 3730.0
>
> ---
>
> trace_id: 62ec613268ecfb9500000d2eb6a71752 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2918 2920.0
>
> ---
>
> trace_id: c0a8010768ed05483f1e3659106d0303 product_id: 516
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 7333 7330.0
>
> ---
>
> trace_id: c0a8df6468ed00c6af21021810b60303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 10644 10640.0
>
> ---
>
> trace_id: 491dd74e68ed04f700001213131fad46 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3975 3980.0
>
> ---
>
> trace_id: 71db869668ecfd27835c9d881cf10ae8 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 7611 7610.0
>
> ---
>
> trace_id: f0f6c23f68ed039800003eff6e5ee0fa product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 8655 8650.0
>
> ---
>
> trace_id: 5eb1f20868ecfa2c6c04c14110a00303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5518 5520.0
>
> ---
>
> trace_id: ac10021468ecf86674ecf6b5107b0303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2635 2640.0
>
> ---
>
> trace_id: 91833b6368ed0416b6ce2d122d4c6b14 product_id: 516
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2561 2560.0
>
> ---
>
> trace_id: c0a8010968ecffb09ea09e8d10c10303 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 8608 8610.0
>
> ---
>
> trace_id: dcf37ed668ed05b5000028e0a46189b8 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 9979 9980.0
>
> ---
>
> trace_id: 0a00009668ed0578e507b71d10930503 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2091 2090.0
>
> ---
>
> trace_id: a90897fb68ed0435bb40af53c0fa6f02 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 14951 14950.0
>
> ---
>
> trace_id: 0c75257868ed0152a5145d387b95d77e product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 10283 10280.0
>
> ---
>
> trace_id: 81d47c3868ecf91d973867c035309b0f product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2477 2480.0
>
> ---
>
> trace_id: e63330a468ecfa520000475d7ed9dbc0 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5096 5100.0
>
> ---
>
> trace_id: e6ed829368ed016daf9771874830aea5 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2562 2560.0
>
> ---
>
> trace_id: c0a8010e68ecff963e58572810690303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 12025 12030.0
>
> ---
>
> trace_id: 02ad64c968ecf9f1bc25f7c2b1d88d67 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2618 2620.0
>
> ---
>
> trace_id: 349ed24468ed04219a404ade6c3ef685 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 1150 1210.0
>
> ---
>
> trace_id: 349ed24468ed04219a404ade6c3ef685 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 1150 1210.0
>
> ---
>
> trace_id: 349ed24468ed04219a404ade6c3ef685 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 1150 1210.0
>
> ---
>
> trace_id: 349ed24468ed04219a404ade6c3ef685 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5584 5580.0
>
> ---
>
> trace_id: fb85e61268ecfc25c6353013106c0303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 11758 11760.0
>
> ---
>
> trace_id: f0f6c23f68ed039800003eff6e5ee0fa product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 7603 7600.0
>
> ---
>
> trace_id: d07f5e5f68ed0082b0206eb1108f0303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5179 5180.0
>
> ---
>
> trace_id: 337f7be268ecfe41884d53a72ab3f684 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 8461 8460.0
>
> ---
>
> trace_id: 993c231068ed003b7e3e3736107d0303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 12788 12790.0
>
> ---
>
> trace_id: 2844b74068ecf8eb0000204993bd822e product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1596 1600.0
>
> ---
>
> trace_id: 6672686c68ed01bf80ba9ac0e5506403 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2025 2030.0
>
> ---
>
> trace_id: 14ddb35368ed053f82eb692ade1c5629 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3916 3920.0
>
> ---
>
> trace_id: 53f4feaa68ed02b4a1d9539628addc3c product_id: 227
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3277 3280.0
>
> ---
>
> trace_id: f89b9fe168ecfcc98f16d5a403c563fa product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3197 3200.0
>
> ---
>
> trace_id: f89b9fe168ecfcc98f16d5a403c563fa product_id: 516
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3203 3200.0
>
> ---
>
> trace_id: 4335401768ecf8b9b61046ffa86bf5de product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 11722 11720.0
>
> ---
>
> trace_id: df4fe04668ecfdc5b905c7a9e9439735 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4842 4840.0
>
> ---
>
> trace_id: df4fe04668ecfdc5b905c7a9e9439735 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4164 4160.0
>
> ---
>
> trace_id: 021ee0bf68ecf92e00007bf727e903ce product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2948 2950.0
>
> ---
>
> trace_id: f07beba768ed0115a9932ee248bd989c product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 11406 11410.0
>
> ---
>
> trace_id: 22a684c068ecf92cbab8c8bb76d1eab1 product_id: 516
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2661 2660.0
>
> ---
>
> trace_id: d18be23a68ecfc13000057790b2cb30e product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 11341 11340.0
>
> ---
>
> trace_id: c2167d3268ecfa268247394cf7ffc7e5 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3049 3050.0
>
> ---
>
> trace_id: d329f01d68ecf8b72489104310f30303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2134 2130.0
>
> ---
>
> trace_id: 5d21d4f568ed051d000033bcc8b5a5d3 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1975 1980.0
>
> ---
>
> trace_id: 37c6be8068ed03f48b8507a18e46e3e0 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5679 5680.0
>
> ---
>
> trace_id: dd98e7da68ecf8af8013d201ee8b6b11 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 13295 13300.0
>
> ---
>
> trace_id: 05f04e4f68ed052fb40ea25e10700303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 8407 8410.0
>
> ---
>
> trace_id: f882a4d368ecf7f79243476fd761cb16 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3416 3420.0
>
> ---
>
> trace_id: 57534f0868ecf90587d24d6198f5ddbc product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 13165 13170.0
>
> ---
>
> trace_id: b14ac95f68ecfae0a072e389ad907ff0 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 21016 21020.0
>
> ---
>
> trace_id: abfc5a9368ed027d9bcbcb745b5fb8a1 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6441 6440.0
>
> ---
>
> trace_id: 9bfedbc068ed022b8c673e14ee598180 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 46852 46850.0
>
> ---
>
> trace_id: 337ee11468ecfb4f150e254710b40303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 8898 8900.0
>
> ---
>
> trace_id: ceff65b568ecf921beded52801f0797f product_id: 344
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 7454 7450.0
>
> ---
>
> trace_id: 2907461f68ecfbcdb36d4006e9f42ad2 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 9343 9340.0
>
> ---
>
> trace_id: bd96c24268ecfd64384ed00f10930303 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 15229 15230.0
>
> ---
>
> trace_id: c0a8010d68ed00065715773e10d90303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4674 4670.0
>
> ---
>
> trace_id: 985d139f68ed0298000065f6b62ef242 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1314 1310.0
>
> ---
>
> trace_id: 9d7a19c268ed02d5acc3b2c6301b45f7 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2256 2260.0
>
> ---
>
> trace_id: 0f1a25f768ecfd8ebdf2f450834c3f72 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 21885 21890.0
>
> ---
>
> trace_id: 2ae637ac68ed037aa49da3a7e4920675 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3757 3760.0
>
> ---
>
> trace_id: 678c270368ed0075bc124a06cdb3d1a4 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 13512 13510.0
>
> ---
>
> trace_id: c0a8012f68ecff29956c539c107a0303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2929 2930.0
>
> ---
>
> trace_id: dc58a12a68ed02f982ff14cd32caa6dc product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4778 4780.0
>
> ---
>
> trace_id: 1166fc0f68ecf851b2d4d8708ac80f4c product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 9657 9660.0
>
> ---
>
> trace_id: eb35ae7768ecffd83b07826510810303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3963 3960.0
>
> ---
>
> trace_id: 728d4f7c68ecff709d8cae12ddf41387 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6617 6620.0
>
> ---
>
> trace_id: c0978d3768ecfe6cb049687810c10403 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 16068 16070.0
>
> ---
>
> trace_id: 6906254a68ecfbce842ae453ac543a7a product_id: 384
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3951 3950.0
>
> ---
>
> trace_id: 3dbd3d7c68ecfa858c36f17c10410303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 17922 17920.0
>
> ---
>
> trace_id: ad67213168ecf8f5c408cbaa10280403 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3147 3150.0
>
> ---
>
> trace_id: 039ad30968ecf9e4b5e0abe718c547cd product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3333 3330.0
>
> ---
>
> trace_id: f9828f8568ed02c8915314ad65d84692 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2081 2080.0
>
> ---
>
> trace_id: 61208ec068ecfc878c8059873336345f product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4676 4680.0
>
> ---
>
> trace_id: 413be7c268ed037400000c2d09c1ad68 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 24186 24190.0
>
> ---
>
> trace_id: e7bb1ea468ecf818be674790a9d8fc09 product_id: 344
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 9532 9530.0
>
> ---
>
> trace_id: a7c7c13768ecf7ec8c3863b2ccd3184c product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3137 3140.0
>
> ---
>
> trace_id: c051187b68ed01b683769930ecfde4d8 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5347 5350.0
>
> ---
>
> trace_id: f882a4d368ecf7f79243476fd761cb16 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2984 2980.0
>
> ---
>
> trace_id: df0810c468ed00c60000395016a45202 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4554 4550.0
>
> ---
>
> trace_id: fd4a6e2c68ed02ad6aaf5e0810000403 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4492 4490.0
>
> ---
>
> trace_id: 9e54963468ecfeceb0cf25ff698ffdf4 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6569 6570.0
>
> ---
>
> trace_id: 985d139f68ed0298000065f6b62ef242 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1552 1550.0
>
> ---
>
> trace_id: 82bc596668ed0574b7cf81b893517936 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5931 5930.0
>
> ---
>
> trace_id: c0a8006768ed050aa8026a5d10930303 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2682 2680.0
>
> ---
>
> trace_id: c0a8006768ed050aa8026a5d10930303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3053 3050.0
>
> ---
>
> trace_id: fba0b13a68ed03219afe0cd6fdee22f1 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2303 2300.0
>
> ---
>
> trace_id: c0a8016968ecfb7e8038cf6110950303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5675 5680.0
>
> ---
>
> trace_id: 22a684c068ecf92cbab8c8bb76d1eab1 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2644 2640.0
>
> ---
>
> trace_id: 0e444c8f68ed03a28a98d044bf916c6b product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 11695 11700.0
>
> ---
>
> trace_id: 8f06e07168ecfedb8667761cbe2b3484 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 25679 25680.0
>
> ---
>
> trace_id: e0c9b26d68ed0508b12a3e0e5db0c132 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5548 5550.0
>
> ---
>
> trace_id: fa234b9d68ecffe6a94a8f4219f24c47 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2258 2260.0
>
> ---
>
> trace_id: 0c75257868ed0152a5145d387b95d77e product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 8943 8940.0
>
> ---
>
> trace_id: f619cd3568ecff6cb9601f9e2c299895 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2946 2950.0
>
> ---
>
> trace_id: 21aa958268ed024294c45d25df21caba product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2045 2050.0
>
> ---
>
> trace_id: ecec400f68ecfa96b51072ec3431bebd product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3654 3650.0
>
> ---
>
> trace_id: 8234697c68ed03e88e865c1c6262c9ed product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 12797 12800.0
>
> ---
>
> trace_id: b7fb222e68ed042ffc40b403104b0403 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 15654 15650.0
>
> ---
>
> trace_id: e1f84e5c68ecfb72bf338ac7322c7b28 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4775 4780.0
>
> ---
>
> trace_id: 4e9aa43a68ecfb5500005319db158fac product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2758 2760.0
>
> ---
>
> trace_id: 06248b7668ed05dd8c71f8f6c829cb85 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 8033 8030.0
>
> ---
>
> trace_id: 166d8d6868ecff3f00000b469b7f1d9f product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1439 1440.0
>
> ---
>
> trace_id: 2c6464df68ed0464a4d25e8e3720f64a product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 14834 14830.0
>
> ---
>
> trace_id: 6bf9f7b868ecfa0a87ca3b0a7cb4515a product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2201 2200.0
>
> ---
>
> trace_id: 2c6464df68ed0464a4d25e8e3720f64a product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 15068 15070.0
>
> ---
>
> trace_id: 9352c6cf68ecfda7bfe1e3bcd3f087f1 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 12809 12810.0
>
> ---
>
> trace_id: d09a5f5468ed02108031ab57e9b7d722 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5131 5130.0
>
> ---
>
> trace_id: 5f837c7168ecf86e8c6c9f2213f80cfa product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3564 3560.0
>
> ---
>
> trace_id: c0a81f8a68ed050c4dc710a410820303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 9203 9200.0
>
> ---
>
> trace_id: c0a8035e68ecfd7a29ace3b4107a0303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 11503 11500.0
>
> ---
>
> trace_id: 3850955a68ed00cba36f6a1bf8d70539 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 13094 13090.0
>
> ---
>
> trace_id: c0a87c3568ecfdfd52c47d5e10930303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 12957 12960.0
>
> ---
>
> trace_id: 8c02aa5d68ed00bd0000521137477b49 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 990 1025.0
>
> ---
>
> trace_id: 8c02aa5d68ed00bd0000521137477b49 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 990 1025.0
>
> ---
>
> trace_id: 8c02aa5d68ed00bd0000521137477b49 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 990 1025.0
>
> ---
>
> trace_id: 8c02aa5d68ed00bd0000521137477b49 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3697 3700.0
>
> ---
>
> trace_id: c32d49a568ed0579bce0e7b1dda7734e product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2629 2630.0
>
> ---
>
> trace_id: 99e1693968ecfac700005fdcf7ef1bc2 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 10021 10020.0
>
> ---
>
> trace_id: 62d3649468ecf8e888f74fa9402de05e product_id: 384
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 2290 2390.0
>
> ---
>
> trace_id: 62d3649468ecf8e888f74fa9402de05e product_id: 384
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 2290 2390.0
>
> ---
>
> trace_id: 62d3649468ecf8e888f74fa9402de05e product_id: 384
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 10026 10030.0
>
> ---
>
> trace_id: 62d3649468ecf8e888f74fa9402de05e product_id: 384
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 2290 2390.0
>
> ---
>
> trace_id: 56b43f4468ecfa950000280913ffd8c0 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1728 1730.0
>
> ---
>
> trace_id: b798fab368ed0183a531bf17b3136b26 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 8534 8530.0
>
> ---
>
> trace_id: ca6f09af68ed05d0a33cf9b53382ae5a product_id: 344
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 10314 10310.0
>
> ---
>
> trace_id: 898c394768ed004ada6d0fa510780303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 11006 11010.0
>
> ---
>
> trace_id: 71d0b9b168ed04ff8ca510666d8437bd product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4154 4150.0
>
> ---
>
> trace_id: 932d594768ecfd48b1308a5f57cf80b5 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2541 2540.0
>
> ---
>
> trace_id: 3019ff9e68ecfa0e8a1f3626c015c89d product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4611 4610.0
>
> ---
>
> trace_id: b595519568ecff89000018c2e13584c5 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5752 5750.0
>
> ---
>
> trace_id: 74c4741768ed03dc98a03c55dc02524a product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6299 6300.0
>
> ---
>
> trace_id: e7bb1ea468ecf818be674790a9d8fc09 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 9655 9650.0
>
> ---
>
> trace_id: 7ef9ddf868ed0336ab50adcee366ac06 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5878 5880.0
>
> ---
>
> trace_id: 8fe451eb68ed031083a8fef30f193190 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3899 3900.0
>
> ---
>
> trace_id: 3392b0f868ed0429a7b9526a0c386194 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 7456 7460.0
>
> ---
>
> trace_id: 15f3b12368ed00d5bb0573fc21509e56 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2502 2500.0
>
> ---
>
> trace_id: 7fce667d68ecf92d99441cbeb980cb03 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6406 6410.0
>
> ---
>
> trace_id: 6bd930fe68ecfe4db511c10217e9b79b product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 21578 21580.0
>
> ---
>
> trace_id: 43dac42868ed033595bfe6da91693592 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 10161 10160.0
>
> ---
>
> trace_id: cadb0f1b68ecfd4700002bcecdc61732 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2581 2580.0
>
> ---
>
> trace_id: 97680e2868ecf7d2c13f2d0910c10503 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2895 2900.0
>
> ---
>
> trace_id: c0a8648b68ecfcc0ae77624010d30503 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4464 4460.0
>
> ---
>
> trace_id: 8ab5fa6c68ecff0bb7b1c5af38b5469b product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5522 5520.0
>
> ---
>
> trace_id: 62f8b9f468ed051f8a4b0808567a510a product_id: 5340
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 1164 -9999.0
>
> ---
>
> trace_id: 62f8b9f468ed051f8a4b0808567a510a product_id: 5340
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 1164 -9999.0
>
> ---
>
> trace_id: 62f8b9f468ed051f8a4b0808567a510a product_id: 5340
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 1164 -9999.0
>
> ---
>
> trace_id: 62f8b9f468ed051f8a4b0808567a510a product_id: 5340
>
> 特征 线上真实值 训练数据值
>
> estimate_dur 1080 -9999.0
>
> ---
>
> trace_id: 62f8b9f468ed051f8a4b0808567a510a product_id: 5340
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 7500 -9999.0
>
> ---
>
> trace_id: 997ce12968ecf818b1a37131b9499549 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6852 6850.0
>
> ---
>
> trace_id: 6bd930fe68ecfe4db511c10217e9b79b product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 34636 34640.0
>
> ---
>
> trace_id: 730778f768ecfdbcbfa8d7ff390f6449 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4908 4910.0
>
> ---
>
> trace_id: 55bfa35968ed050bba3dd33b0b3feea1 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 7992 7990.0
>
> ---
>
> trace_id: 6cd67e8a68ed0072a5aebe546d0fc3bf product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 13672 13670.0
>
> ---
>
> trace_id: 18c39ff668ecf7d4b778462d6934c370 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3765 3770.0
>
> ---
>
> trace_id: c0a8010968ed00819ea09e8d10830403 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 8257 8260.0
>
> ---
>
> trace_id: 0a798b1268ecfb1e00004f58f320c611 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3771 3770.0
>
> ---
>
> trace_id: 97680e2868ecf7d2c13f2d0910c10503 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3368 3370.0
>
> ---
>
> trace_id: c0a8648b68ecfcc0ae77624010d30503 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5139 5140.0
>
> ---
>
> trace_id: dc58a12a68ed02f982ff14cd32caa6dc product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6093 6090.0
>
> ---
>
> trace_id: c0a8010768ed05483f1e3659106d0303 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 7398 7400.0
>
> ---
>
> trace_id: 82bc596668ed0574b7cf81b893517936 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5892 5890.0
>
> ---
>
> trace_id: d09a5f5468ed02108031ab57e9b7d722 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4439 4440.0
>
> ---
>
> trace_id: 5d21d4f568ed051d000033bcc8b5a5d3 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1975 1980.0
>
> ---
>
> trace_id: 94e46a1168ecf91245a8d61810770403 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2785 2790.0
>
> ---
>
> trace_id: 3d468df968ecfac58c3ca6367ca14d57 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 9406 9410.0
>
> ---
>
> trace_id: 7e74e6b868ecfa63b9978ecd7a15fbd9 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 13652 13650.0
>
> ---
>
> trace_id: 2ad6b8e468ecf8aa00007d7703a51686 product_id: 272
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 694 -9999.0
>
> ---
>
> trace_id: 2ad6b8e468ecf8aa00007d7703a51686 product_id: 272
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4100 -9999.0
>
> ---
>
> trace_id: 2ad6b8e468ecf8aa00007d7703a51686 product_id: 272
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 694 -9999.0
>
> ---
>
> trace_id: 2ad6b8e468ecf8aa00007d7703a51686 product_id: 272
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 694 -9999.0
>
> ---
>
> trace_id: 2ad6b8e468ecf8aa00007d7703a51686 product_id: 272
>
> 特征 线上真实值 训练数据值
>
> estimate_dur 600 -9999.0
>
> ---
>
> trace_id: da91adcc68ecf8f6884160ad2f27a803 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1223 1220.0
>
> ---
>
> trace_id: 3fa70ba568ecfa4fa9991b835f46d730 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5489 5490.0
>
> ---
>
> trace_id: de8edbb968ecf828bc75c2e62a071f10 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 13983 13980.0
>
> ---
>
> trace_id: 6480e68a68ecfd51ba6ad4c4ccc38ead product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6037 6040.0
>
> ---
>
> trace_id: e7bb1ea468ecf818be674790a9d8fc09 product_id: 243
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 9689 9690.0
>
> ---
>
> trace_id: 68c3c09868ecfe89a83934e011d3628a product_id: 384
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3765 3770.0
>
> ---
>
> trace_id: 801410ad68ecff9281d4f64ccc3e9a0f product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3135 3140.0
>
> ---
>
> trace_id: 53f4feaa68ed02b4a1d9539628addc3c product_id: 344
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3309 3310.0
>
> ---
>
> trace_id: 678c270368ed0075bc124a06cdb3d1a4 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 12038 12040.0
>
> ---
>
> trace_id: fa234b9d68ecffe6a94a8f4219f24c47 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2258 2260.0
>
> ---
>
> trace_id: 9447ff5b68ed0548b600af5c49a219a9 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2219 2220.0
>
> ---
>
> trace_id: c32d49a568ed0579bce0e7b1dda7734e product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2686 2690.0
>
> ---
>
> trace_id: 4092ac9668ecfbe90000629c419125d2 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5122 5120.0
>
> ---
>
> trace_id: 0fb66a3f68ed0485c25c1724107e0303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 11252 11250.0
>
> ---
>
> trace_id: a0f127f968ecfcfa000040aa7cb57ddc product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 7141 7140.0
>
> ---
>
> trace_id: 81d47c3868ecf91d973867c035309b0f product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2506 2510.0
>
> ---
>
> trace_id: cebcf63368ecf9819f83ba0dd4cc1ff7 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4219 4220.0
>
> ---
>
> trace_id: 3e00b40868ed0030b81e565a53c6a2f5 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 13666 13670.0
>
> ---
>
> trace_id: cff91d4368ed00df0000455c68872377 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 10534 10530.0
>
> ---
>
> trace_id: f89b9fe168ecfcc98f16d5a403c563fa product_id: 344
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3338 3340.0
>
> ---
>
> trace_id: 65f88c9068ed008f000078ffa1fcf478 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5757 5760.0
>
> ---
>
> trace_id: 8a4de91b68ecf9d100003776bad780a4 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 19278 19280.0
>
> ---
>
> trace_id: 27560bd568ecfa2b929e55b495b41702 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6381 6380.0
>
> ---
>
> trace_id: 10a6bc1f68ecfb2384bfabc17c66324c product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4068 4070.0
>
> ---
>
> trace_id: 10a6bc1f68ecfb2384bfabc17c66324c product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4674 4670.0
>
> ---
>
> trace_id: c0a8012a68ecfea199021a3a10e90303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6653 6650.0
>
> ---
>
> trace_id: 37581d8d68ed026200007cc7088db4a4 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5144 5140.0
>
> ---
>
> trace_id: d81fe52068ecf9c9b4cc4295b3aafcd8 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2493 2490.0
>
> ---
>
> trace_id: d44f14fd68ed0244000077fb4dbb1c17 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 14637 14640.0
>
> ---
>
> trace_id: 233f5f3568ecfeb0a7ac78b974399c36 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 12414 12410.0
>
> ---
>
> trace_id: bcefb3a468ed0274bb940722f9e88feb product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 9591 9590.0
>
> ---
>
> trace_id: c0a8010d68ed00065715773e10d90303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4914 4910.0
>
> ---
>
> trace_id: c0a8010968ed00819ea09e8d10830403 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 8616 8620.0
>
> ---
>
> trace_id: 6112db6968ed02dd00006b2252820cb3 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 17627 17630.0
>
> ---
>
> trace_id: c0a8010268ecfec471fa0f43103a0403 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4182 4180.0
>
> ---
>
> trace_id: 8234697c68ed03e88e865c1c6262c9ed product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 12451 12450.0
>
> ---
>
> trace_id: e1f84e5c68ecfb72bf338ac7322c7b28 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5455 5460.0
>
> ---
>
> trace_id: 7ef9ddf868ed0336ab50adcee366ac06 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5877 5880.0
>
> ---
>
> trace_id: b168ac4f68ed042c8174e73a2728d7de product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 9571 9570.0
>
> ---
>
> trace_id: f0b8009068ed02ad000025dfd0749fc4 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6196 6200.0
>
> ---
>
> trace_id: 057ef85f68ecfef0e2fa508210840303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 24083 24080.0
>
> ---
>
> trace_id: f174b09a68ecfdbbb08508546043a8b7 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6938 6940.0
>
> ---
>
> trace_id: cc79a9ec68ecfe65a4dffb461161559b product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4881 4880.0
>
> ---
>
> trace_id: 5cf8ec1c68ed01580000530834f2898e product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 15615 15620.0
>
> ---
>
> trace_id: 7565383968ecf9b391aeeb6710740303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 7197 7200.0
>
> ---
>
> trace_id: 94c75a2768ecfc3cf5b4898510730303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 8799 8800.0
>
> ---
>
> trace_id: 18c39ff668ecf7d4b778462d6934c370 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3271 3270.0
>
> ---
>
> trace_id: cd6f029b68ecf92900007fbbafa463dc product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1489 1490.0
>
> ---
>
> trace_id: 3d8b896e68ed018080d52797ec992758 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1274 1270.0
>
> ---
>
> trace_id: 1d6e498c68ecfe0ea1bab9e6edb9cfed product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4699 4700.0
>
> ---
>
> trace_id: 5bdf916b68ecfded83b0418dd9681e5e product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5942 5940.0
>
> ---
>
> trace_id: 8fe451eb68ed031083a8fef30f193190 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3387 3390.0
>
> ---
>
> trace_id: 956c388a68ecfcefab1e4af9855d4270 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 14395 14400.0
>
> ---
>
> trace_id: aad6aa4668ecfad600004d941529f12d product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3171 3170.0
>
> ---
>
> trace_id: 6447b90668ecfce7575515a710920303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1149 1150.0
>
> ---
>
> trace_id: 5d91114d68ecfc7e9320c6d0372aa346 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3905 3910.0
>
> ---
>
> trace_id: cd6f029b68ecf92900007fbbafa463dc product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1511 1510.0
>
> ---
>
> trace_id: c0a80a3a68ed0289bc479f4e10aa0303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2113 2110.0
>
> ---
>
> trace_id: 00d80ac468ecf85089d789e70b364510 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5386 5390.0
>
> ---
>
> trace_id: f9828f8568ed02c8915314ad65d84692 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2081 2080.0
>
> ---
>
> trace_id: d77ed36e68ed05510000164241b9a06b product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5122 5120.0
>
> ---
>
> trace_id: b303957768ed03bb88b23fd8774ece84 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4692 4690.0
>
> ---
>
> trace_id: 06248b7668ed05dd8c71f8f6c829cb85 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 8722 8720.0
>
> ---
>
> trace_id: 5275615468ecfb22a5529e823f29d70f product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2062 2060.0
>
> ---
>
> trace_id: 85d40cd568ecfd23973971b0cbfe7394 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 12882 12880.0
>
> ---
>
> trace_id: b46b5a0468ed015f82789b0d8b941f39 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2942 2940.0
>
> ---
>
> trace_id: 6cd67e8a68ed0072a5aebe546d0fc3bf product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 13154 13150.0
>
> ---
>
> trace_id: 5dd51e6e68ecfe62b4bd16a9c6a8f9a4 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2807 2810.0
>
> ---
>
> trace_id: 6b30034c68ecf97a84f660368bf7f085 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 11203 11200.0
>
> ---
>
> trace_id: c0a8010768ed05483f1e3659106d0303 product_id: 344
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 7325 7330.0
>
> ---
>
> trace_id: 82bc596668ed0574b7cf81b893517936 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 7469 7470.0
>
> ---
>
> trace_id: 5519cc9968ecfe3db568dd2c00ab98ea product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2705 2710.0
>
> ---
>
> trace_id: e9471e1868ed05b59f97b7a94cfb7670 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 10497 10500.0
>
> ---
>
> trace_id: 72a0b0b968ecf8e1af34b79482043ad8 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2488 2490.0
>
> ---
>
> trace_id: 7f8fa76a68ed00d8da003f9810c80303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 13645 13650.0
>
> ---
>
> trace_id: a90897fb68ed0435bb40af53c0fa6f02 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 10781 10780.0
>
> ---
>
> trace_id: 4145b21468ecf8cebd7f69f1dde9f41a product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1863 1860.0
>
> ---
>
> trace_id: c0a8df6468ed00c6af21021810b60303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 12117 12120.0
>
> ---
>
> trace_id: c0a8012a68ecfea199021a3a10e90303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6888 6890.0
>
> ---
>
> trace_id: 12574eb068ecffca8cb2f1b93c7b6749 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4564 4560.0
>
> ---
>
> trace_id: 98e61ccf68ed02aeb6b3df9a538f2637 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 12092 12090.0
>
> ---
>
> trace_id: 7f42cebe68ecfa920000400bf3aacc83 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3399 3400.0
>
> ---
>
> trace_id: 44e6ac3b68ecfe028cc08af7e2c16b31 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4467 4470.0
>
> ---
>
> trace_id: 3667590468ecfaef944d38d454fc6a97 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4595 4600.0
>
> ---
>
> trace_id: 41b10ada68ed058100001a23d4dfd301 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2513 2510.0
>
> ---
>
> trace_id: 99e1693968ecfac700005fdcf7ef1bc2 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 9735 9740.0
>
> ---
>
> trace_id: dace43cf68ecfa169a75fa7920d717f1 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3685 3690.0
>
> ---
>
> trace_id: a9cfeeda68ed02ee000017df504f1534 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3883 3880.0
>
> ---
>
> trace_id: e04eb03168ecffb4aec7c79ccdc1a174 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4394 4390.0
>
> ---
>
> trace_id: e22ec81268ed040fab2ab35bafe18ec6 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3731 3730.0
>
> ---
>
> trace_id: e22ec81268ed040fab2ab35bafe18ec6 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3506 3510.0
>
> ---
>
> trace_id: e8d33d6a68ecfbdab1232a9e10d30303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 10575 10580.0
>
> ---
>
> trace_id: e8d33d6a68ecfbdab1232a9e10d30303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 9387 9390.0
>
> ---
>
> trace_id: 53f4feaa68ed02b4a1d9539628addc3c product_id: 384
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 1000 1050.0
>
> ---
>
> trace_id: 53f4feaa68ed02b4a1d9539628addc3c product_id: 384
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 1000 1050.0
>
> ---
>
> trace_id: 53f4feaa68ed02b4a1d9539628addc3c product_id: 384
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3277 3280.0
>
> ---
>
> trace_id: 53f4feaa68ed02b4a1d9539628addc3c product_id: 384
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 1000 1050.0
>
> ---
>
> trace_id: c0a8012f68ecff29956c539c107a0303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3173 3170.0
>
> ---
>
> trace_id: 039ad30968ecf9e4b5e0abe718c547cd product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3252 3250.0
>
> ---
>
> trace_id: 9d7a19c268ed02d5acc3b2c6301b45f7 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2238 2240.0
>
> ---
>
> trace_id: b7fb222e68ed042ffc40b403104b0403 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 12362 12360.0
>
> ---
>
> trace_id: cadb0f1b68ecfd4700002bcecdc61732 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2618 2620.0
>
> ---
>
> trace_id: 3d468df968ecfac58c3ca6367ca14d57 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 9211 9210.0
>
> ---
>
> trace_id: c0a8006468ed04ab8a56fc9f10990303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3364 3360.0
>
> ---
>
> trace_id: f1a3f5f668ecfc8a9556fb671d71d724 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5441 5440.0
>
> ---
>
> trace_id: 22a684c068ecf92cbab8c8bb76d1eab1 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2661 2660.0
>
> ---
>
> trace_id: c7c4c41268ed043cb498ea5df37eff1a product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4106 4110.0
>
> ---
>
> trace_id: c06ba4bc68ed0536801e71634bd01ef4 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6975 6980.0
>
> ---
>
> trace_id: 71d0b9b168ed04ff8ca510666d8437bd product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3642 3640.0
>
> ---
>
> trace_id: 10e4becc68ed020bb5f948611ad7cb19 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1794 1790.0
>
> ---
>
> trace_id: a0dd53e268ed02b68c251bf98b3e693c product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2849 2850.0
>
> ---
>
> trace_id: f0b8009068ed02ad000025dfd0749fc4 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5459 5460.0
>
> ---
>
> trace_id: 12574eb068ecffca8cb2f1b93c7b6749 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4361 4360.0
>
> ---
>
> trace_id: 8ab5fa6c68ecff0bb7b1c5af38b5469b product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5678 5680.0
>
> ---
>
> trace_id: 7f42cebe68ecfa920000400bf3aacc83 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3309 3310.0
>
> ---
>
> trace_id: c7d2303068ecfb759bd4577c2ceb836a product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 14224 14220.0
>
> ---
>
> trace_id: b46b5a0468ed015f82789b0d8b941f39 product_id: 516
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3199 3200.0
>
> ---
>
> trace_id: 9bc2384d68ecf8049fac733f23853622 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6812 6810.0
>
> ---
>
> trace_id: 57534f0868ecf90587d24d6198f5ddbc product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 11569 11570.0
>
> ---
>
> trace_id: d329f01d68ecf8b72489104310f30303 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2262 2260.0
>
> ---
>
> trace_id: a1ea481f68ecfbe2d116876010890303 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5653 5650.0
>
> ---
>
> trace_id: 2ad6b8e468ecf8aa00007d7703a51686 product_id: 5020
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 723 -9999.0
>
> ---
>
> trace_id: 2ad6b8e468ecf8aa00007d7703a51686 product_id: 5020
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 723 -9999.0
>
> ---
>
> trace_id: 2ad6b8e468ecf8aa00007d7703a51686 product_id: 5020
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 723 -9999.0
>
> ---
>
> trace_id: 2ad6b8e468ecf8aa00007d7703a51686 product_id: 5020
>
> 特征 线上真实值 训练数据值
>
> estimate_dur 600 -9999.0
>
> ---
>
> trace_id: 2ad6b8e468ecf8aa00007d7703a51686 product_id: 5020
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4100 -9999.0
>
> ---
>
> trace_id: c0a80a5968ed00b65939566b10810303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3253 3250.0
>
> ---
>
> trace_id: 3f28566d68ed03c5bf3b3f19d460dd6e product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6711 6710.0
>
> ---
>
> trace_id: e579736668ecfaef000020858e688539 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2638 2640.0
>
> ---
>
> trace_id: fa234b9d68ecffe6a94a8f4219f24c47 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2341 2340.0
>
> ---
>
> trace_id: 6447b90668ecfce7575515a710920303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1124 1120.0
>
> ---
>
> trace_id: c0a80a6568ed002b3a110fa110940303 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2527 2530.0
>
> ---
>
> trace_id: 3893362368ecfaa79dca84969a6b2469 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3098 3100.0
>
> ---
>
> trace_id: 0dc6bc1668ed0363b50cf987ae386126 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 8613 8610.0
>
> ---
>
> trace_id: dd98e7da68ecf8af8013d201ee8b6b11 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 13844 13840.0
>
> ---
>
> trace_id: b46b5a0468ed015f82789b0d8b941f39 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 685 692.0
>
> ---
>
> trace_id: b46b5a0468ed015f82789b0d8b941f39 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 685 692.0
>
> ---
>
> trace_id: b46b5a0468ed015f82789b0d8b941f39 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 685 692.0
>
> ---
>
> trace_id: b46b5a0468ed015f82789b0d8b941f39 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3199 3200.0
>
> ---
>
> trace_id: 1b80e56f68ecffcb801e8fa0b788566a product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4343 4340.0
>
> ---
>
> trace_id: 44f0482e68ecf7e47d84554f10130403 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 7516 7520.0
>
> ---
>
> trace_id: 78d5ee5c68ed04d8000038dc1526abed product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 12185 12190.0
>
> ---
>
> trace_id: bcefb3a468ed0274bb940722f9e88feb product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 9173 9170.0
>
> ---
>
> trace_id: f469f73868ecfd88893470b9ba4d832b product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2849 2850.0
>
> ---
>
> trace_id: 1149e5c268ecfb6dbd475298af559a59 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 8879 8880.0
>
> ---
>
> trace_id: d07f5e5f68ed0082b0206eb1108f0303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3644 3640.0
>
> ---
>
> trace_id: 7b5a3e4868ecfdf2bb9a46d346f4bb60 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3849 3850.0
>
> ---
>
> trace_id: 823ee75968ecfda500006e03d1c4e7fc product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 10161 10160.0
>
> ---
>
> trace_id: 81d47c3868ecf91d973867c035309b0f product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2477 2480.0
>
> ---
>
> trace_id: 5ccb635f68ecf84b0000144e1fcee74e product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4563 4560.0
>
> ---
>
> trace_id: a0f127f968ecfcfa000040aa7cb57ddc product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5589 5590.0
>
> ---
>
> trace_id: fba0b13a68ed03219afe0cd6fdee22f1 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2277 2280.0
>
> ---
>
> trace_id: c0a8012a68ecfea199021a3a10e90303 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 8501 8500.0
>
> ---
>
> trace_id: 61208ec068ecfc878c8059873336345f product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5973 5970.0
>
> ---
>
> trace_id: 68b183cf68ecfcd689f54ce744c0f579 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 11762 11760.0
>
> ---
>
> trace_id: 8731b46a68ecff1091df44f21418032b product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4166 4170.0
>
> ---
>
> trace_id: 8d8b8fc168ecfbd1a1e88412862df4ff product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 13706 13710.0
>
> ---
>
> trace_id: a89ec75d68ed030da433052110970303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 7783 7780.0
>
> ---
>
> trace_id: 6b30034c68ecf97a84f660368bf7f085 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 10773 10770.0
>
> ---
>
> trace_id: 4176f84968ecfee193e19b3fc6575547 product_id: 482
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 752 -9999.0
>
> ---
>
> trace_id: 4176f84968ecfee193e19b3fc6575547 product_id: 482
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 752 -9999.0
>
> ---
>
> trace_id: 4176f84968ecfee193e19b3fc6575547 product_id: 482
>
> 特征 线上真实值 训练数据值
>
> estimate_dur 540 -9999.0
>
> ---
>
> trace_id: 4176f84968ecfee193e19b3fc6575547 product_id: 482
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4700 -9999.0
>
> ---
>
> trace_id: 4176f84968ecfee193e19b3fc6575547 product_id: 482
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 752 -9999.0
>
> ---
>
> trace_id: 98c50df168ed05bf00004d3f28fa9b05 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3736 3740.0
>
> ---
>
> trace_id: 7565383968ecf9b391aeeb6710740303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 8139 8140.0
>
> ---
>
> trace_id: 5d21d4f568ed051d000033bcc8b5a5d3 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1982 1980.0
>
> ---
>
> trace_id: 0ddc700968ecfce493253b483947e5f2 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1221 1220.0
>
> ---
>
> trace_id: 15f3b12368ed00d5bb0573fc21509e56 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2418 2420.0
>
> ---
>
> trace_id: 41df7c7968ed036191d763a49dea14b4 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 10518 10520.0
>
> ---
>
> trace_id: a9cfeeda68ed02ee000017df504f1534 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3883 3880.0
>
> ---
>
> trace_id: 56b43f4468ecfa950000280913ffd8c0 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1753 1750.0
>
> ---
>
> trace_id: e9ac426668ed01f283dc33e8c421631f product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 12959 12960.0
>
> ---
>
> trace_id: 81d47c3868ecf91d973867c035309b0f product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2506 2510.0
>
> ---
>
> trace_id: f9828f8568ed02c8915314ad65d84692 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2043 2040.0
>
> ---
>
> trace_id: f89b9fe168ecfcc98f16d5a403c563fa product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3674 3670.0
>
> ---
>
> trace_id: 4335401768ecf8b9b61046ffa86bf5de product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 10305 10310.0
>
> ---
>
> trace_id: 743d790368ecfcf2a1a8842e5b25fb3a product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2754 2750.0
>
> ---
>
> trace_id: 4f85251c68ecfb72bc893c27df93a27c product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2148 2150.0
>
> ---
>
> trace_id: aadea17968ed02ba1136af26106a0303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 8262 8260.0
>
> ---
>
> trace_id: c0a8008568ecf7e40b1bd140108e0303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4647 4650.0
>
> ---
>
> trace_id: bc615e1e68ecfbb500001c4b01161e5d product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 11287 11290.0
>
> ---
>
> trace_id: c0a8df6468ed00fdaf210218106c0403 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 12117 12120.0
>
> ---
>
> trace_id: c0a8012a68ecfea199021a3a10e90303 product_id: 344
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6753 6750.0
>
> ---
>
> trace_id: 9bfedbc068ed022b8c673e14ee598180 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 40716 40720.0
>
> ---
>
> trace_id: c0a8020768ecfa34380dd34d10930303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 11994 11990.0
>
> ---
>
> trace_id: 3667590468ecfaef944d38d454fc6a97 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5296 5300.0
>
> ---
>
> trace_id: 7565383968ecff66184a5b5a10740303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2851 2850.0
>
> ---
>
> trace_id: 7f6a9ae768ecfecb9b247edd982f93d3 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6335 6340.0
>
> ---
>
> trace_id: c5d0cd1968ecfdd30000496a3e6ca80e product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1947 1950.0
>
> ---
>
> trace_id: a0dd53e268ed02b68c251bf98b3e693c product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2821 2820.0
>
> ---
>
> trace_id: 68c3c09868ecfe89a83934e011d3628a product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 3804 3800.0
>
> ---
>
> trace_id: b54618d968ecfb2500002a30a59169c1 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 19795 19800.0
>
> ---
>
> trace_id: c0a80a6568ed002b3a110fa110940303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2249 2250.0
>
> ---
>
> trace_id: 4145b21468ecf8cebd7f69f1dde9f41a product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1849 1850.0
>
> ---
>
> trace_id: 5ccb635f68ecf84b0000144e1fcee74e product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5234 5230.0
>
> ---
>
> trace_id: 8731b46a68ecff1091df44f21418032b product_id: 384
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 990 1027.0
>
> ---
>
> trace_id: 8731b46a68ecff1091df44f21418032b product_id: 384
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 990 1027.0
>
> ---
>
> trace_id: 8731b46a68ecff1091df44f21418032b product_id: 384
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 990 1027.0
>
> ---
>
> trace_id: 8731b46a68ecff1091df44f21418032b product_id: 384
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4107 4110.0
>
> ---
>
> trace_id: ca6f09af68ed05d0a33cf9b53382ae5a product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 10214 10210.0
>
> ---
>
> trace_id: a0f127f968ecfcfa000040aa7cb57ddc product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 7297 7300.0
>
> ---
>
> trace_id: a32393b368ed041ca858d95c13df5d83 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6396 6400.0
>
> ---
>
> trace_id: 8e2d2e5468ed006a8113960a8b16d037 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 7115 7120.0
>
> ---
>
> trace_id: e3b6003a68ecff3a172445b210800303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6178 6180.0
>
> ---
>
> trace_id: 0fb66a3f68ed0485c25c1724107e0303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 12752 12750.0
>
> ---
>
> trace_id: 2ab4953468ed026c96176fe9883e3aee product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 14775 14780.0
>
> ---
>
> trace_id: 4335401768ecf8b9b61046ffa86bf5de product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 12691 12690.0
>
> ---
>
> trace_id: f48bb4f068ecff4f9f2109f8e4c95854 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 17775 17770.0
>
> ---
>
> trace_id: 42cae81c68ecfd90ae0a7a505350d4d6 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5842 5840.0
>
> ---
>
> trace_id: 932d594768ecfd48b1308a5f57cf80b5 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 683 690.0
>
> ---
>
> trace_id: 932d594768ecfd48b1308a5f57cf80b5 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 683 690.0
>
> ---
>
> trace_id: 932d594768ecfd48b1308a5f57cf80b5 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 683 690.0
>
> ---
>
> trace_id: 7a01c5fe68ecfc4fa12a11cbf6760b5c product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5956 5960.0
>
> ---
>
> trace_id: 357285c868ecf91299d73c1d49b70c74 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 7421 7420.0
>
> ---
>
> trace_id: cff91d4368ed00df0000455c68872377 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 12109 12110.0
>
> ---
>
> trace_id: 56b43f4468ecfa950000280913ffd8c0 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 810 830.0
>
> ---
>
> trace_id: 56b43f4468ecfa950000280913ffd8c0 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 810 830.0
>
> ---
>
> trace_id: 56b43f4468ecfa950000280913ffd8c0 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 810 830.0
>
> ---
>
> trace_id: 56b43f4468ecfa950000280913ffd8c0 product_id: 384
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 1751 1750.0
>
> ---
>
> trace_id: 021ee0bf68ecf92e00007bf727e903ce product_id: 516
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2524 2520.0
>
> ---
>
> trace_id: 65f88c9068ed008f000078ffa1fcf478 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6069 6070.0
>
> ---
>
> trace_id: dd98e7da68ecf8af8013d201ee8b6b11 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 13751 13750.0
>
> ---
>
> trace_id: 9554f4fd68ecfd2c99e44f9e32297e7d product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 6077 6080.0
>
> ---
>
> trace_id: 1b80e56f68ecffcb801e8fa0b788566a product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4676 4680.0
>
> ---
>
> trace_id: e63330a468ecfa520000475d7ed9dbc0 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4469 4470.0
>
> ---
>
> trace_id: be15011868ecfdc6b81de69210760303 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4859 4860.0
>
> ---
>
> trace_id: 81d47c3868ecf91d973867c035309b0f product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2491 2490.0
>
> ---
>
> trace_id: a8b6340d68ecfca868c2342c107c0303 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 22743 22740.0
>
> ---
>
> trace_id: 2f0c047d68ecfd0b8d446dbf71af7b66 product_id: 407
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4927 4930.0
>
> ---
>
> trace_id: 02ad64c968ecf9f1bc25f7c2b1d88d67 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 2619 2620.0
>
> ---
>
> trace_id: f81c1fcb68ed03b800003840edef1922 product_id: 368
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 8157 8160.0
>
> ---
>
> trace_id: 4176f84968ecfee193e19b3fc6575547 product_id: 272
>
> 特征 线上真实值 训练数据值
>
> ufbox_basic_fee 732 -9999.0
>
> ---
>
> trace_id: 4176f84968ecfee193e19b3fc6575547 product_id: 272
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4700 -9999.0
>
> ---
>
> trace_id: 4176f84968ecfee193e19b3fc6575547 product_id: 272
>
> 特征 线上真实值 训练数据值
>
> uabox_basic_fee 732 -9999.0
>
> ---
>
> trace_id: 4176f84968ecfee193e19b3fc6575547 product_id: 272
>
> 特征 线上真实值 训练数据值
>
> estimate_dur 540 -9999.0
>
> ---
>
> trace_id: 4176f84968ecfee193e19b3fc6575547 product_id: 272
>
> 特征 线上真实值 训练数据值
>
> outbox_basic_fee 732 -9999.0
>
> ---
>
> trace_id: 2907461f68ecfbcdb36d4006e9f42ad2 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 9262 9260.0
>
> ---
>
> trace_id: 3256922a68ed05ab8f7016d4c94a0b02 product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 4275 4280.0
>
> ---
>
> trace_id: d77ed36e68ed05510000164241b9a06b product_id: 497
>
> 特征 线上真实值 训练数据值
>
> start_dest_dis 5096 5100.0
