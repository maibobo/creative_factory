# WCFG 七组波形：设计逻辑与测试点

2026-10-10；按功能重排0929基稿。Word是配图主稿；本文保留同一分析、信号对照及测试点索引。

## 2 下行发送

DDR 读拍经异步 FIFO 送入 10G 用户接口。测试关注一帧的完整性、反压保持和预取限流；两个 64bit 拍是 16 Byte 帧的组成方式，并非发送周期。依据详细设计 §6.2、深度解析 §2。

### 2.1 两拍成帧

#### 图01 两拍保持一帧

DUT位置：TOP.u_pcie.u_pcie_fdma_aurora_brg_adapter.u_fdma_aurora_brg_tx

对应测试点：P-03 单帧16 Byte（S-03、S-04）；P-06 FDMA/LocalLink反压（S-04、S-16）

用例关系：TC-M07 TX单帧、300帧与近满反压。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：tx，250～365 ns；0929原图32。

验证功能：验证一次16 Byte读取能完整变成10G帧，并在目的端暂不能接受时保住首拍。这是数据传输粒度与帧边界测试，帧内两拍之间的等待由ready决定。

图中关系：fdma_rvalid/fdma_rready 的重合段把两个递增序号写入FIFO，fifo_wr_cnt随之上升；跨域后valid/sof先有效，而ready低时tx_data停留在首字。放行后sof转eof，received由0增至2，数据低32bit从0到1。

设计逻辑：FDMA侧只有数据阶段的rvalid&&rready才产生fifo_wr_en；用户侧只有valid&&ready才产生fifo_rd_en。TX_SOF先发首字，接受后进TX_DATA，第二字接受后回空闲；tx_rem=7表示每拍8个字节都有效。异步FIFO隔开两个时钟域，不能将输入rvalid高电平解释为10G已经发出。

判断依据：数据序号连续、SOF/EOF对应首末字、received累计2，共同支持P-03的TX模块部分；测试台TX/DATA_OR_BOUNDARY及STALL_HOLD检查补足数据比较。测试地址从0步进，本图没有H2C、adapter或0x8000业务窗口，P-03整条链仍仅部分有图。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| u_fdma_aurora_brg_tx.cfg_tx_burst_limit | 0 | 图中短名 limit 对应此RTL端口。本次 TX 测试允许的 16Byte 帧数。 |
| u_fdma_aurora_brg_tx.fdma_raddr | 1 | 图中短名 raddr 对应此RTL端口。TX 桥给 FDMA 的字节读地址，每帧递进 16Byte。 |
| u_fdma_aurora_brg_tx.fdma_rareq | 2 | 图中短名 rareq 对应此RTL端口。TX 桥的 FDMA 读请求；近满时不再启动新的突发。 |
| u_fdma_aurora_brg_tx.fdma_rbusy | 2 | 图中短名 rbusy 对应此RTL端口。FDMA 从端已接受读请求并正在给数。 |
| u_fdma_aurora_brg_tx.fdma_rvalid | 2 | 图中短名 rvalid 对应此RTL端口。FDMA 从端当前读数据拍有效。 |
| u_fdma_aurora_brg_tx.fdma_rready | 2 | 图中短名 rready 对应此RTL端口。TX 桥/写 FIFO 可以接受 FDMA 数据拍。 |
| u_fdma_aurora_brg_tx.fdma_rdata | 2 | 图中短名 rdata 对应此RTL端口。FDMA 从端提供的 64bit 数据拍。 |
| u_fdma_aurora_brg_tx.fifo_wr_en | 2 | FDMA 数据握手后送入 TX FIFO 的写使能。 |
| u_fdma_aurora_brg_tx.fifo_wr_cnt | 4 | TX FIFO 写域所见占用拍数，用于 504 阈值节流。 |
| u_fdma_aurora_brg_tx.fifo_rd_en | 2 | 10G 发送拍真正握手后的 FIFO 读使能。 |
| u_fdma_aurora_brg_tx.tx_src_rdy | 2 | 图中短名 valid 对应此RTL端口。10G 当前输出拍有效；停顿时负载必须保持。 |
| u_fdma_aurora_brg_tx.tx_dst_rdy | 4 | 图中短名 ready 对应此RTL端口。10G 用户侧消费者放行信号；与 tx_src_rdy 同时为 1 才完成发送。 |
| u_fdma_aurora_brg_tx.tx_sof | 2 | 图中短名 sof 对应此RTL端口。10G 当前拍为 16Byte 帧的首拍。 |
| u_fdma_aurora_brg_tx.tx_eof | 2 | 图中短名 eof 对应此RTL端口。10G 当前拍为 16Byte 帧的末拍。 |
| u_fdma_aurora_brg_tx.tx_rem | 0 | 图中短名 rem 对应此RTL端口。10G 当前 64bit 拍有效字节数减一；本测试两拍均为 7。 |
| u_fdma_aurora_brg_tx.tx_d | 3 | 图中短名 tx_data 对应此RTL端口。10G LocalLink 输出 64bit 数据拍。 |
| 测试激励/统计：received | 2 | 测试台已验收拍数，只有真正数据握手才递增。 |

### 2.2 近满保护

#### 图02 水位触发限流

DUT位置：TOP.u_pcie.u_pcie_fdma_aurora_brg_adapter.u_fdma_aurora_brg_tx

对应测试点：P-22 TX深度512阈值504（S-16、S-04）；P-06 FDMA/LocalLink反压（S-04、S-16）

用例关系：TC-M07 TX单帧、300帧与近满反压。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：tx，6650～6740 ns；0929原图33。

验证功能：验证消费者长时间停顿时，桥能在FIFO真正溢出前停止继续读DDR，使已存数据保持可恢复。

图中关系：ready保持低，fifo_wr_cnt上升到504；fifo_almost_full置起后fifo_write_ready降低，rareq不再连续发起，peak_words随后记录504，fifo_overflow一直为0。这里稳定的ready=0是构造拥塞的输入条件。

设计逻辑：FIFO深度512、可编程近满阈值504，留8拍余量用于阈值传播和在途读取。RD_IDLE只有FIFO可写且尚未达批次上限才发请求，fdma_rready也受fifo_write_ready门控。近满是预警和节流条件，不要求先把full置起才停。

判断依据：水位达到阈值而非只停在低水位，说明测试确实命中了P-22；停止预取与overflow=0说明保护动作有结果。全批无丢重还要结合600拍顺序比较和最终TX CASE PASS，截图不能单靠一根零错误线证明全部数据正确。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| u_fdma_aurora_brg_tx.fdma_raddr | 3 | 图中短名 raddr 对应此RTL端口。TX 桥给 FDMA 的字节读地址，每帧递进 16Byte。 |
| u_fdma_aurora_brg_tx.fdma_rareq | 6 | 图中短名 rareq 对应此RTL端口。TX 桥的 FDMA 读请求；近满时不再启动新的突发。 |
| u_fdma_aurora_brg_tx.fdma_rvalid | 6 | 图中短名 rvalid 对应此RTL端口。FDMA 从端当前读数据拍有效。 |
| u_fdma_aurora_brg_tx.fdma_rready | 6 | 图中短名 rready 对应此RTL端口。TX 桥/写 FIFO 可以接受 FDMA 数据拍。 |
| u_fdma_aurora_brg_tx.rd_data_hs | 6 | TX FDMA 有效数据被桥接受的握手事件。 |
| u_fdma_aurora_brg_tx.fifo_wr_cnt | 6 | TX FIFO 写域所见占用拍数，用于 504 阈值节流。 |
| u_fdma_aurora_brg_tx.fifo_almost_full | 1 | 近满状态；RX 为目的域观测，TX 为写端预取阈值。 |
| u_fdma_aurora_brg_tx.fifo_write_ready | 1 | TX FIFO 写侧可继续接收数据，近满时拉低。 |
| u_fdma_aurora_brg_tx.fifo_overflow | 0 | TX FIFO 溢出标志，测试中应保持 0。 |
| 测试激励/统计：peak_words | 7 | 测试台记录的 TX FIFO 最大占用拍数。 |
| u_fdma_aurora_brg_tx.tx_src_rdy | 0 | 图中短名 valid 对应此RTL端口。10G 当前输出拍有效；停顿时负载必须保持。 |
| u_fdma_aurora_brg_tx.tx_dst_rdy | 0 | 图中短名 ready 对应此RTL端口。10G 用户侧消费者放行信号；与 tx_src_rdy 同时为 1 才完成发送。 |

### 2.3 停顿恢复

#### 图03 出队后恢复预取

DUT位置：TOP.u_pcie.u_pcie_fdma_aurora_brg_adapter.u_fdma_aurora_brg_tx

对应测试点：P-06 FDMA/LocalLink反压（S-04、S-16）；P-22 TX深度512阈值504（S-16、S-04）

用例关系：TC-M07 TX单帧、300帧与近满反压。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：tx，19820～19945 ns；0929原图34。

验证功能：验证限流可以解除，且输出遇短停顿时保持当前拍，继续传递原来尚未发完的序列。

图中关系：ready恢复后fifo_rd_en和received一起推进，tx_sof/eof交替标出两拍帧；水位下降使fifo_almost_full解除，rareq重新出现。其间ready再次降低时，valid仍保持，tx_data不会跳到下一字。

设计逻辑：FIFO读指针由发送握手驱动，读出腾出空间后占用量再同步回写域，所以读出与预取恢复有跨域延时。新读请求给FIFO补货，因此水位可能再次碰到504并限流，这种起落是供给与消耗平衡的结果。

判断依据：P-06所需的保持和恢复由输出握手、数据序号及水位三者相互印证，P-22由近满解除后重新读取支持。TX/STALL_HOLD与逐拍比较验证整个停顿过程；本图没有证明真实DDR返回或Aurora串行线路的停顿路径。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| u_fdma_aurora_brg_tx.tx_dst_rdy | 5 | 图中短名 ready 对应此RTL端口。10G 用户侧消费者放行信号；与 tx_src_rdy 同时为 1 才完成发送。 |
| u_fdma_aurora_brg_tx.tx_src_rdy | 7 | 图中短名 valid 对应此RTL端口。10G 当前输出拍有效；停顿时负载必须保持。 |
| u_fdma_aurora_brg_tx.tx_sof | 7 | 图中短名 sof 对应此RTL端口。10G 当前拍为 16Byte 帧的首拍。 |
| u_fdma_aurora_brg_tx.tx_eof | 8 | 图中短名 eof 对应此RTL端口。10G 当前拍为 16Byte 帧的末拍。 |
| u_fdma_aurora_brg_tx.tx_d | 11 | 图中短名 tx_data 对应此RTL端口。10G LocalLink 输出 64bit 数据拍。 |
| u_fdma_aurora_brg_tx.fifo_rd_en | 10 | 10G 发送拍真正握手后的 FIFO 读使能。 |
| u_fdma_aurora_brg_tx.fifo_wr_cnt | 8 | TX FIFO 写域所见占用拍数，用于 504 阈值节流。 |
| u_fdma_aurora_brg_tx.fifo_almost_full | 3 | 近满状态；RX 为目的域观测，TX 为写端预取阈值。 |
| u_fdma_aurora_brg_tx.fifo_write_ready | 3 | TX FIFO 写侧可继续接收数据，近满时拉低。 |
| u_fdma_aurora_brg_tx.fdma_rareq | 6 | 图中短名 rareq 对应此RTL端口。TX 桥的 FDMA 读请求；近满时不再启动新的突发。 |
| u_fdma_aurora_brg_tx.fdma_raddr | 2 | 图中短名 raddr 对应此RTL端口。TX 桥给 FDMA 的字节读地址，每帧递进 16Byte。 |
| 测试激励/统计：received | 8 | 测试台已验收拍数，只有真正数据握手才递增。 |

## 3 配置发送

本章六张图来自旧版 1G：6 Byte 两拍，31.25MHz 域每63拍给一次机会。当前设计已经是四拍16 Byte、外部同源2µs事件。旧图只用来解释仍有对应关系的配置锁定、握手和恢复思想，不能据此确认现行帧格式或现行起帧条件。依据详细设计 §7.1/§7.3、深度解析 §4.3/§8。

### 3.1 非法编号

#### 图04 有效输入仍需合法

DUT位置：TOP.U_RTDS_1G_PERIODIC_TX

对应测试点：P-08 非法和重复配置（S-05）

用例关系：当前表单关联 TC-M01 1G十组四拍发送与恢复；本图对应旧版两拍测试，不是现行四拍TC-M01的波形。实际adapter整链TC-F09也未由本图验证。

定位：1g，810～850 ns；0929原图26。

验证功能：验证编号合法性是配置门控条件，避免把任意Byte1误当成可用参数。非法帧仍可以是有效下行数据，不能因为valid出现就让1G启动。

图中关系：cfg_byte_valid先后给出输入机会，cfg_byte为0和11；decode_valid为0，decoded_duty/decoded_vin不形成合法参数，cfg_req、configured_id、configured及tx_valid仍保持未启动。

设计逻辑：源端锁存条件为cfg_byte_valid&&decode_valid&&!cfg_req。valid说明本次输入可采样，decode_valid说明编号在1～10表内，!cfg_req保证首次合法值优先。三者有不同职责，非法输入不能消耗以后合法编号的配置机会。

判断依据：输入确实被提交而配置请求没有生成，是P-08非法过滤的历史模块证据；测试台还等待后检查无完整帧。adapter并未例化，不能由此验证它提取的是CPU每帧的正确Byte1，P-30仍缺完整链路图。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| U_RTDS_1G_PERIODIC_TX.cfg_byte | 1 | 下行 16Byte 帧 Byte1 的编号，只有 1～10 合法。 |
| U_RTDS_1G_PERIODIC_TX.cfg_byte_valid | 4 | Byte1 首次实际接受事件，用于触发一次配置。 |
| U_RTDS_1G_PERIODIC_TX.decode_valid | 0 | 编号组合译码合法标志；非法值即使 valid 也不得锁存。 |
| U_RTDS_1G_PERIODIC_TX.decoded_duty | 0 | 编号表给出的 16bit 占空比定点参数。 |
| U_RTDS_1G_PERIODIC_TX.decoded_vin | 0 | 编号表给出的 32bit Vin 定点参数，单位为电压×2²⁰。 |
| U_RTDS_1G_PERIODIC_TX.cfg_req | 0 | 首次合法配置已提交的源域锁存标志。 |
| U_RTDS_1G_PERIODIC_TX.configured_id | 0 | 源域锁存的首次合法编号；后续合法输入不覆盖。 |
| U_RTDS_1G_PERIODIC_TX.configured | 0 | 源域收到目的域确认后的配置完成状态。 |
| U_RTDS_1G_PERIODIC_TX.tx_valid | 0 | 1G 当前待发拍有效；反压时随状态保持。 |

### 3.2 参数锁定

#### 图05 参数原子锁定

DUT位置：TOP.U_RTDS_1G_PERIODIC_TX

对应测试点：P-07 十组合法参数（S-05、S-20、S-06）；P-08 非法和重复配置（S-05）

用例关系：当前表单关联 TC-M01 1G十组四拍发送与恢复；本图对应旧版两拍测试，不是现行四拍TC-M01的波形。实际adapter整链TC-F09也未由本图验证。

定位：1g，5928～6190 ns；0929原图27。

验证功能：验证首次合法编号形成一份完整48bit配置，经握手跨域后才允许用户逻辑使用；重点是源数据保持与目的端一致，不是跨域耗时多少纳秒。

图中关系：cfg_hold与configured_id先取得编号1对应的值，cfg_req置起；稍后req_sync有效，cfg_user取得同一{Vin,duty}并有cfg_ack，返回ack_sync后configured才置起。源与目的两条总线数值一致且源值在途中稳定。

设计逻辑：cfg_hold把查表结果冻结成{decoded_vin,decoded_duty}；CDC邮箱传完整总线，cfg_user只在req_sync&&!cfg_ack时采样。cfg_req保持到主机复位，因此后续合法输入不能覆盖；configured_id是源端已接受编号的指示，configured是返回确认，二者所处阶段不同。

判断依据：图展示编号1的duty=0x0BB8、Vin=0x00500000，支持P-07参数表的一例及P-08首次锁定原理。十组查表和重复配置的全程比较在历史TB；本图没有四拍输出，也没有当前adapter与1G的整链验证。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| U_RTDS_1G_PERIODIC_TX.cfg_byte | 1 | 下行 16Byte 帧 Byte1 的编号，只有 1～10 合法。 |
| U_RTDS_1G_PERIODIC_TX.cfg_byte_valid | 2 | Byte1 首次实际接受事件，用于触发一次配置。 |
| U_RTDS_1G_PERIODIC_TX.decode_valid | 1 | 编号组合译码合法标志；非法值即使 valid 也不得锁存。 |
| U_RTDS_1G_PERIODIC_TX.cfg_hold | 1 | 源域保持的 {Vin,duty} 48bit 邮箱数据。 |
| U_RTDS_1G_PERIODIC_TX.cfg_req | 1 | 首次合法配置已提交的源域锁存标志。 |
| U_RTDS_1G_PERIODIC_TX.req_sync | 1 | 标准 CDC 到目的域的完整配置请求边界。 |
| U_RTDS_1G_PERIODIC_TX.cfg_user | 1 | 用户域原子接收的 48bit 配置值。 |
| U_RTDS_1G_PERIODIC_TX.cfg_ack | 1 | 目的域已锁存完整配置的标志。 |
| U_RTDS_1G_PERIODIC_TX.ack_sync | 1 | 标准 CDC 返回源域的配置接受确认。 |
| U_RTDS_1G_PERIODIC_TX.configured_id | 1 | 源域锁存的首次合法编号；后续合法输入不覆盖。 |
| U_RTDS_1G_PERIODIC_TX.configured | 1 | 源域收到目的域确认后的配置完成状态。 |

### 3.3 载荷字节序

#### 图06 参数到线上字节

DUT位置：TOP.U_RTDS_1G_PERIODIC_TX

对应测试点：P-07 十组合法参数（S-05、S-20、S-06）；P-09 四拍帧、节拍与反压恢复（S-06、S-21、S-22）

用例关系：当前表单关联 TC-M01 1G十组四拍发送与恢复；本图对应旧版两拍测试，不是现行四拍TC-M01的波形。实际adapter整链TC-F09也未由本图验证。

定位：1g，8090～8230 ns；0929原图28。

验证功能：利用旧载荷验证48bit参数的字节排列与首末标记，并明确现行格式已经变化，避免把旧图直接用于当前P-09。

图中关系：旧period_tick触发IDLE→FIRST→LAST→IDLE；FIRST带sof、rem=3和B80B0000，LAST带eof、rem=1和50000000。completed_frames在末拍真正接受后加一，尚未握手的值不计作一帧。

设计逻辑：旧数据映射把duty低字节/高字节放在首拍高位，随后依次发Vin的四个小端字节。当前FIRST仍承载Byte0～3，但SECOND应是5000F000且REM=3，随后THIRD/FOURTH为零，EOF在第四拍。旧图的LAST、REM=1和六字节结束都是历史结构。

判断依据：P-07的LUT字节来源可据此理解；P-09四拍16 Byte、Byte6=F0、保留字节以及2µs同源事件都没有本图证据。10月10日TC-M01日志已验证现行四拍，但其wave_count=0，应引用日志而非替换本图含义。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| U_RTDS_1G_PERIODIC_TX.period_tick | 2 | 旧版用户域63拍机会，31.25MHz时为2.016µs；当前RTL改由同源2µs翻转事件跨域检测，旧图不能证明新版间隔。 |
| U_RTDS_1G_PERIODIC_TX.tx_curr_st | 3 | 旧图状态0=IDLE、1=FIRST、2=LAST；当前四拍状态0～4，禁止把旧状态2解读成现行第四拍。 |
| U_RTDS_1G_PERIODIC_TX.tx_ready | 0 | 1G 对端可接受；仅在 tx_valid 同时有效时推进状态。 |
| U_RTDS_1G_PERIODIC_TX.tx_valid | 2 | 1G 当前待发拍有效；反压时随状态保持。 |
| U_RTDS_1G_PERIODIC_TX.tx_sof | 2 | 1G 当前 FIRST 拍的帧首标志。 |
| U_RTDS_1G_PERIODIC_TX.tx_eof | 2 | 1G 当前 LAST 拍的帧尾标志。 |
| U_RTDS_1G_PERIODIC_TX.tx_rem | 2 | 旧图首拍REM=3（4Byte）、末拍REM=1（2Byte）；当前四拍每拍REM=3，本图不是现行格式证据。 |
| U_RTDS_1G_PERIODIC_TX.tx_data | 2 | 当前 1G/10G 用户接口送出的数据拍，需结合 valid/ready 判断接受。 |
| 测试激励/统计：completed_frames | 1 | 1G 测试台完整接受两拍后累计的帧数。 |

### 3.4 反压与跳过

#### 图07 在途帧与周期机会

DUT位置：TOP.U_RTDS_1G_PERIODIC_TX

对应测试点：P-09 四拍帧、节拍与反压恢复（S-06、S-21、S-22）；P-23 逻辑复位与断链恢复（S-15、S-21、S-24）

用例关系：当前表单关联 TC-M01 1G十组四拍发送与恢复；本图对应旧版两拍测试，不是现行四拍TC-M01的波形。实际adapter整链TC-F09也未由本图验证。

定位：1g，14140～16230 ns；0929原图29。

验证功能：说明已开始的数据事务必须保持，而新的周期机会允许被跳过；这是避免反压后积压补发的业务选择。

图中关系：旧图中ready低时仍处FIRST，valid/sof/data/rem保持一份首拍，period_tick继续出现而skipped_periods上升。跳过计数变化时当前拍并未被新参数或新帧替换。

设计逻辑：旧状态机允许IDLE遇tick先进入FIRST再等待ready；忙时tick只计数。现行S-21已改成IDLE必须period_tick&&tx_ready才起帧，空闲但ready低也计跳过；已在途的FIRST～FOURTH仍保持至握手。这一处起帧条件差异须显式保留。

判断依据：图支持P-09的历史在途保持和忙时不排队思想，不能证明当前“空闲且ready低”的分支。当前恢复规则还需四拍状态、外部事件和新TB的检查；P-23也只能获得1G局部参考。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| U_RTDS_1G_PERIODIC_TX.tx_ready | 0 | 1G 对端可接受；仅在 tx_valid 同时有效时推进状态。 |
| U_RTDS_1G_PERIODIC_TX.tx_valid | 1 | 1G 当前待发拍有效；反压时随状态保持。 |
| U_RTDS_1G_PERIODIC_TX.tx_sof | 1 | 1G 当前 FIRST 拍的帧首标志。 |
| U_RTDS_1G_PERIODIC_TX.tx_eof | 0 | 1G 当前 LAST 拍的帧尾标志。 |
| U_RTDS_1G_PERIODIC_TX.tx_rem | 0 | 旧图首拍REM=3（4Byte）、末拍REM=1（2Byte）；当前四拍每拍REM=3，本图不是现行格式证据。 |
| U_RTDS_1G_PERIODIC_TX.tx_data | 1 | 当前 1G/10G 用户接口送出的数据拍，需结合 valid/ready 判断接受。 |
| U_RTDS_1G_PERIODIC_TX.tx_curr_st | 1 | 旧图状态0=IDLE、1=FIRST、2=LAST；当前四拍状态0～4，禁止把旧状态2解读成现行第四拍。 |
| U_RTDS_1G_PERIODIC_TX.period_tick | 4 | 旧版用户域63拍机会，31.25MHz时为2.016µs；当前RTL改由同源2µs翻转事件跨域检测，旧图不能证明新版间隔。 |
| U_RTDS_1G_PERIODIC_TX.skipped_periods | 1 | 1G 忙时到来的周期机会累计数，不是待补发队列长度。 |

#### 图08 握手推进当前拍

DUT位置：TOP.U_RTDS_1G_PERIODIC_TX

对应测试点：P-09 四拍帧、节拍与反压恢复（S-06、S-21、S-22）

用例关系：当前表单关联 TC-M01 1G十组四拍发送与恢复；本图对应旧版两拍测试，不是现行四拍TC-M01的波形。实际adapter整链TC-F09也未由本图验证。

定位：1g，18970～19070 ns；0929原图30。

验证功能：观察反压解除后完成的是原来在途的拍，确保停止期间的数据没有丢掉或被新周期覆盖。

图中关系：ready上升使旧FIRST转到LAST，sof降低、eof置起、data切至原配置的剩余字节；ready随后再降，末拍继续等待，skipped_periods保持此前累计值。

设计逻辑：状态只因当前拍被接受而前进，发送状态决定对应字节，不因计数变化追加历史任务。当前四拍设计使用FIRST→SECOND→THIRD→FOURTH，原理仍是握手前进，但旧图的首拍后立即EOF与REM=1不能当成现行行为。

判断依据：图将“跳过机会”和“完成在途数据”分开，支持历史反压解释。现行P-09必须检查所有四拍在停顿下的负载及边界，旧两拍图无法补齐这项验证。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| U_RTDS_1G_PERIODIC_TX.tx_ready | 2 | 1G 对端可接受；仅在 tx_valid 同时有效时推进状态。 |
| U_RTDS_1G_PERIODIC_TX.tx_valid | 0 | 1G 当前待发拍有效；反压时随状态保持。 |
| U_RTDS_1G_PERIODIC_TX.tx_sof | 1 | 1G 当前 FIRST 拍的帧首标志。 |
| U_RTDS_1G_PERIODIC_TX.tx_eof | 1 | 1G 当前 LAST 拍的帧尾标志。 |
| U_RTDS_1G_PERIODIC_TX.tx_rem | 1 | 旧图首拍REM=3（4Byte）、末拍REM=1（2Byte）；当前四拍每拍REM=3，本图不是现行格式证据。 |
| U_RTDS_1G_PERIODIC_TX.tx_data | 1 | 当前 1G/10G 用户接口送出的数据拍，需结合 valid/ready 判断接受。 |
| U_RTDS_1G_PERIODIC_TX.tx_curr_st | 1 | 旧图状态0=IDLE、1=FIRST、2=LAST；当前四拍状态0～4，禁止把旧状态2解读成现行第四拍。 |
| U_RTDS_1G_PERIODIC_TX.skipped_periods | 0 | 1G 忙时到来的周期机会累计数，不是待补发队列长度。 |

### 3.5 断链恢复

#### 图09 掉线保留配置

DUT位置：TOP.U_RTDS_1G_PERIODIC_TX

对应测试点：P-23 逻辑复位与断链恢复（S-15、S-21、S-24）；P-09 四拍帧、节拍与反压恢复（S-06、S-21、S-22）

用例关系：当前表单关联 TC-M01 1G十组四拍发送与恢复；本图对应旧版两拍测试，不是现行四拍TC-M01的波形。实际adapter整链TC-F09也未由本图验证。

定位：1g，21940～26320 ns；0929原图31。

验证功能：解释链路状态与配置生命周期分开：掉线应停发并重新准备，已锁存的参数由主机复位清除。

图中关系：channel_up降低后arm_count回零且tx_valid无帧；cfg_user/cfg_ack/configured仍保持。重连后arm_count逐步到4，再由后续机会驱动发送；断链期间的机会没有形成密集补发序列。

设计逻辑：恢复等待用于隔离旧事件，链路不可用时状态强制空闲。配置邮箱使用主机逻辑复位，链路user_reset不会清掉首次参数。当前period_tick来自同步后的toggle事件，与旧63拍本地产生方式不同。

判断依据：这是P-23的1G链路局部历史证据，图内掉线发生时旧帧已结束，不能声称已直接展示半帧被中止。新TC-M01提供当前模块日志，DDR/PCIe/10G中断和旧完成隔离属于TC-F11待补。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| U_RTDS_1G_PERIODIC_TX.channel_up | 2 | 用户域链路可用状态；掉线中止未完成发送。 |
| U_RTDS_1G_PERIODIC_TX.user_reset | 0 | 1G 用户接口复位，中止发送而不清首次锁存配置。 |
| U_RTDS_1G_PERIODIC_TX.cfg_user | 0 | 用户域原子接收的 48bit 配置值。 |
| U_RTDS_1G_PERIODIC_TX.cfg_ack | 0 | 目的域已锁存完整配置的标志。 |
| U_RTDS_1G_PERIODIC_TX.configured | 0 | 源域收到目的域确认后的配置完成状态。 |
| U_RTDS_1G_PERIODIC_TX.arm_count | 5 | 1G 恢复后等待四个用户沿的计数，防止立即重放旧事件。 |
| U_RTDS_1G_PERIODIC_TX.period_tick | 6 | 旧版用户域63拍机会，31.25MHz时为2.016µs；当前RTL改由同源2µs翻转事件跨域检测，旧图不能证明新版间隔。 |
| U_RTDS_1G_PERIODIC_TX.tx_curr_st | 2 | 旧图状态0=IDLE、1=FIRST、2=LAST；当前四拍状态0～4，禁止把旧状态2解读成现行第四拍。 |
| U_RTDS_1G_PERIODIC_TX.tx_valid | 1 | 1G 当前待发拍有效；反压时随状态保持。 |
| U_RTDS_1G_PERIODIC_TX.tx_sof | 2 | 1G 当前 FIRST 拍的帧首标志。 |
| U_RTDS_1G_PERIODIC_TX.tx_eof | 1 | 1G 当前 LAST 拍的帧尾标志。 |

## 4 上行写入

10G 原始64bit拍先经 RX FIFO 跨域，再由 writer 仅取低32bit，两个字组成一个64bit写拍。FIFO 保存原拍、writer 形成 DDR 业务序列，是两个不同职责。依据详细设计 §6.3/§6.4、深度解析 §7。

### 4.1 缓存与丢字

#### 图10 缓存积压与容量

DUT位置：TOP.u_pcie.u_pcie_fdma_aurora_brg_adapter.U_RTDS_RX_FRAME_FIFO

对应测试点：P-11 FIFO满与恢复（S-08、S-12）

用例关系：TC-M06 RX FIFO丢字与排空恢复。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：rx_fifo，288～520 ns；0929原图35。

验证功能：验证10G数据先跨域保存完整64bit拍，读取暂停时积压增加，近满与满提供容量状态。高32bit在这一层必须保留，不能提前压缩。

图中关系：rx_data低半顺序递增、高半随机，rx_valid对应fifo_write；读侧frame_data先展示第一拍，frame_valid为高而frame_ready为低，队头持续不动。almost_full_user先于full_user置起，目的域fifo_*稍后跟随。

设计逻辑：写条件是user_ready&&rx_valid&&!full_user&&!wr_busy；读条件是frame_valid&&frame_ready。FWFT可以提前呈现一个队头，测试深度16下存住17个可验收拍，应以XPM实际行为和TB比较为准。源满状态直接门控写，跨域后的fifo_full只是目的域观察。

判断依据：P-11通过积压、满状态和队头保持三者关联，排除“未写到满却宣称验证了满保护”。SOF/EOF变化未阻断写入，符合逐有效字保存规则；生产2048深度的阈值不由本图确认。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| U_RTDS_RX_FRAME_FIFO.rx_data | 17 | 10G 输入的原始 64bit 拍；后续 writer 才取低 32bit。 |
| U_RTDS_RX_FRAME_FIFO.rx_valid | 34 | 10G 输入当前 64bit 拍有效。 |
| U_RTDS_RX_FRAME_FIFO.rx_sof | 12 | 线路帧首拍标记；当前 RX FIFO 不据此封块。 |
| U_RTDS_RX_FRAME_FIFO.rx_eof | 8 | 线路帧末拍标记；当前 RX FIFO 不据此判长度。 |
| U_RTDS_RX_FRAME_FIFO.rx_ready | 0 | 线路侧常高的接口 ready，不能据此断言 FIFO 仍有空位。 |
| U_RTDS_RX_FRAME_FIFO.fifo_write | 34 | 源域真正允许写入异步 FIFO 的条件。 |
| U_RTDS_RX_FRAME_FIFO.almost_full_user | 1 | 源时钟域 FIFO 接近满标志。 |
| U_RTDS_RX_FRAME_FIFO.full_user | 1 | 源时钟域 FIFO 满标志，直接门控写入。 |
| U_RTDS_RX_FRAME_FIFO.fifo_almost_full | 1 | 近满状态；RX 为目的域观测，TX 为写端预取阈值。 |
| U_RTDS_RX_FRAME_FIFO.fifo_full | 1 | 跨到目的域后的满状态；相比 full_user 有同步延时。 |
| U_RTDS_RX_FRAME_FIFO.frame_data | 1 | 异步 FIFO 的 64bit FWFT 队头，frame_ready 握手后才前进。 |
| U_RTDS_RX_FRAME_FIFO.frame_valid | 1 | 当前流数据有效；是否前进还需看 frame_ready。 |
| U_RTDS_RX_FRAME_FIFO.frame_ready | 0 | DDR 域消费者放行；与 frame_valid 一起形成 fifo_read。 |

#### 图11 满时保住旧数据

DUT位置：TOP.u_pcie.u_pcie_fdma_aurora_brg_adapter.U_RTDS_RX_FRAME_FIFO

对应测试点：P-11 FIFO满与恢复（S-08、S-12）

用例关系：TC-M06 RX FIFO丢字与排空恢复。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：rx_fifo，580～630 ns；0929原图36。

验证功能：验证FIFO无空间时放弃新字，并把丢失显式通知软件，而不覆盖已积压数据。线路数据已到用户接口，不能靠DDR侧ready保证它会重发。

图中关系：full_user保持高时新值100的rx_valid出现，fifo_write仍为0；drop_bin先加一，dropped_frames跨域后加一。frame_data仍为旧队头，rx_ready始终为1。

设计逻辑：rx_ready固定1表达接口接收约定，真正入FIFO需另检查容量。不可写的每个有效拍对应一个低32bit业务字丢失，drop_bin经标准计数CDC到DDR域。先源计数、后目的计数是一次事件的跨域结果，不能当成丢了两次。

判断依据：新字被拒且旧队头未换，配合后续顺序比较支持P-11“不覆盖旧数据”。软件从0x38得知累计丢字，但单个缺口没有位置或采样时间字段；饱和到FFFFFFFF属于P-18，本图未命中。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| U_RTDS_RX_FRAME_FIFO.rx_data | 1 | 10G 输入的原始 64bit 拍；后续 writer 才取低 32bit。 |
| U_RTDS_RX_FRAME_FIFO.rx_valid | 2 | 10G 输入当前 64bit 拍有效。 |
| U_RTDS_RX_FRAME_FIFO.rx_ready | 0 | 线路侧常高的接口 ready，不能据此断言 FIFO 仍有空位。 |
| U_RTDS_RX_FRAME_FIFO.full_user | 0 | 源时钟域 FIFO 满标志，直接门控写入。 |
| U_RTDS_RX_FRAME_FIFO.fifo_write | 0 | 源域真正允许写入异步 FIFO 的条件。 |
| U_RTDS_RX_FRAME_FIFO.drop_bin | 1 | 接收源域统计的已丢有效字数，经计数 CDC 后对外显示。 |
| U_RTDS_RX_FRAME_FIFO.dropped_frames | 1 | 累计无法存储的有效 32bit 字数；名称沿用 frames，但单位不是整帧。 |
| U_RTDS_RX_FRAME_FIFO.fifo_full | 0 | 跨到目的域后的满状态；相比 full_user 有同步延时。 |
| U_RTDS_RX_FRAME_FIFO.frame_valid | 0 | 当前流数据有效；是否前进还需看 frame_ready。 |
| U_RTDS_RX_FRAME_FIFO.frame_data | 0 | 异步 FIFO 的 64bit FWFT 队头，frame_ready 握手后才前进。 |

### 4.2 排空与恢复

#### 图12 只在接受时换队头

DUT位置：TOP.u_pcie.u_pcie_fdma_aurora_brg_adapter.U_RTDS_RX_FRAME_FIFO

对应测试点：P-11 FIFO满与恢复（S-08、S-12）

用例关系：TC-M06 RX FIFO丢字与排空恢复。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：rx_fifo，675～755 ns；0929原图37。

验证功能：验证读取恢复后能按存入顺序输出，并给写侧逐步释放空间。

图中关系：frame_ready放行后fifo_read与received连续推进，frame_data低32bit依次为0～16；full_user解除，目的域fifo_full随后下降。dropped_frames保持1，不因读出而减掉。

设计逻辑：FWFT队头即使已显示也不能提前删除，只有frame_valid&&frame_ready才改变读指针。读指针传播到源域后才解除满状态，因此不能要求第一次读出与full_user同一时刻下降。

判断依据：17个旧拍全部有序验收，说明满保护没有破坏已有内容，计数不会随排空归零。TB比较完整64bit而非只检查低序号，覆盖P-11缩小容量实例的有序恢复。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| U_RTDS_RX_FRAME_FIFO.frame_ready | 1 | DDR 域消费者放行；与 frame_valid 一起形成 fifo_read。 |
| U_RTDS_RX_FRAME_FIFO.frame_valid | 1 | 当前流数据有效；是否前进还需看 frame_ready。 |
| U_RTDS_RX_FRAME_FIFO.frame_data | 16 | 异步 FIFO 的 64bit FWFT 队头，frame_ready 握手后才前进。 |
| U_RTDS_RX_FRAME_FIFO.fifo_read | 2 | 目的域 frame_valid 与 frame_ready 同时成立的读使能。 |
| U_RTDS_RX_FRAME_FIFO.full_user | 1 | 源时钟域 FIFO 满标志，直接门控写入。 |
| U_RTDS_RX_FRAME_FIFO.fifo_full | 1 | 跨到目的域后的满状态；相比 full_user 有同步延时。 |
| U_RTDS_RX_FRAME_FIFO.fifo_almost_full | 1 | 近满状态；RX 为目的域观测，TX 为写端预取阈值。 |
| U_RTDS_RX_FRAME_FIFO.dropped_frames | 0 | 累计无法存储的有效 32bit 字数；名称沿用 frames，但单位不是整帧。 |
| 测试激励/统计：received | 17 | 测试台已验收拍数，只有真正数据握手才递增。 |

#### 图13 恢复后接收新字

DUT位置：TOP.u_pcie.u_pcie_fdma_aurora_brg_adapter.U_RTDS_RX_FRAME_FIFO

对应测试点：P-11 FIFO满与恢复（S-08、S-12）

用例关系：TC-M06 RX FIFO丢字与排空恢复。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：rx_fifo，744～790 ns；0929原图38。

验证功能：验证容量解除后写入门控可以重新打开，既不会永久卡满，也不会把此前丢弃的字延迟补入。

图中关系：新字99有rx_valid与fifo_write，随后读侧出现同一frame_data，received从17到18；满状态低、丢字计数仍1、length_error仍0。

设计逻辑：full_user解除后新的有效拍可入队。此前值100从未写FIFO，所以不存在自动重传；后来的99必须排在所有保留旧拍之后。length_error固定0源于当前不按线路帧长筛选，不能把它解读为完整帧解析已通过。

判断依据：完整64bit对应、新增验收数和累计丢字一起支持P-11的恢复闭环。本图仍不验证writer的低字压缩，那由下一节的ring证据支持。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| U_RTDS_RX_FRAME_FIFO.rx_data | 1 | 10G 输入的原始 64bit 拍；后续 writer 才取低 32bit。 |
| U_RTDS_RX_FRAME_FIFO.rx_valid | 2 | 10G 输入当前 64bit 拍有效。 |
| U_RTDS_RX_FRAME_FIFO.fifo_write | 2 | 源域真正允许写入异步 FIFO 的条件。 |
| U_RTDS_RX_FRAME_FIFO.full_user | 0 | 源时钟域 FIFO 满标志，直接门控写入。 |
| U_RTDS_RX_FRAME_FIFO.frame_ready | 0 | DDR 域消费者放行；与 frame_valid 一起形成 fifo_read。 |
| U_RTDS_RX_FRAME_FIFO.frame_valid | 2 | 当前流数据有效；是否前进还需看 frame_ready。 |
| U_RTDS_RX_FRAME_FIFO.frame_data | 1 | 异步 FIFO 的 64bit FWFT 队头，frame_ready 握手后才前进。 |
| U_RTDS_RX_FRAME_FIFO.dropped_frames | 0 | 累计无法存储的有效 32bit 字数；名称沿用 frames，但单位不是整帧。 |
| 测试激励/统计：received | 2 | 测试台已验收拍数，只有真正数据握手才递增。 |
| U_RTDS_RX_FRAME_FIFO.length_error | 0 | 兼容旧接口的长度错误位；V2.01 固定为 0。 |

### 4.3 低字拼接

#### 图14 两个低字组成写拍

DUT位置：TOP.u_pcie.u_pcie_fdma_aurora_brg_adapter.U_RTDS_RX_BLOCK_WRITER

对应测试点：P-10 低32bit字拼接（S-07）；P-14 延迟及错误B响应（S-10、S-26）

用例关系：TC-M02 上行拼接、环形队列与B响应。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：ring，34～96 ns；0929原图01。

验证功能：验证上行有效载荷是连续32bit序列：每个64bit线路拍只贡献低半，两个有效字紧凑写到DDR，不留随机高半空洞。

图中关系：frame_data两次有效输入后half_valid先置起，pair_start在第二个低字到来时成立；fdma_wdata变成00000001_00000000，WSTRB=FF。fdma_waccept先发生，成功done随后到来，used_bytes才从0到8。

设计逻辑：half_data缓存先到低字，active_transfer在pair_start锁存{8字节,FF,后字,先字}。writer的REQ等busy、DATA等accept、RESPONSE等done；只有RESPONSE&&done&&!error称write_success，used_bytes因此代表已确认的字节而非已送出的总线量。

判断依据：源高半随机而写数据只由两个低字组成，支持P-10排列和压缩；长度在成功响应后增加支持P-14的一般条件。TB独立字节RAM比较排除数据线看似正确但未落入模型的问题。CPU应以head_len读实际成功长度。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| U_RTDS_RX_BLOCK_WRITER.frame_data | 2 | 上游输入的 64bit 原拍，writer 仅取其低 32bit。 |
| U_RTDS_RX_BLOCK_WRITER.frame_valid | 4 | 当前流数据有效；是否前进还需看 frame_ready。 |
| U_RTDS_RX_BLOCK_WRITER.frame_ready | 2 | writer 接收流接口状态；即使满队也可能接收后计丢弃。 |
| U_RTDS_RX_BLOCK_WRITER.half_data | 0 | 待配对的第一个有效低 32bit 字；高 32bit 输入被丢弃。 |
| U_RTDS_RX_BLOCK_WRITER.half_valid | 2 | 已有半个 64bit 写拍，等下一有效字或窗口尾封存。 |
| U_RTDS_RX_BLOCK_WRITER.pair_start | 2 | 第二个 32bit 字到达，触发 FF 全拍组装。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_waddr | 1 | 本次 FDMA 写事务的字节地址；环形块地址由写指针与已提交长度形成。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_wdata | 1 | 交给 FDMA 的 64bit 写拍数据；是否写入由接受、B 响应和 WSTRB 分别决定。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_wstrb | 1 | 8 个字节写使能，FF 为全拍，0F 只更新低四字节。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_wareq | 2 | 写地址/拍数请求，需等 fdma_wbusy 确认接受。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_waccept | 2 | 一个 FDMA 数据拍实际被接受的事件；早于最终 B 响应。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_wdone | 2 | 整笔 FDMA 写在最终 B 响应后完成的脉冲。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_werror | 0 | 最终写响应错误汇总；与 done 同看才能决定是否提交长度。 |
| U_RTDS_RX_BLOCK_WRITER.write_success | 2 | 写状态在 RESPONSE 且 fdma_wdone、无错。 |
| U_RTDS_RX_BLOCK_WRITER.used_bytes | 1 | 当前写块中已经得到成功 B 响应的有效字节数。 |

### 4.4 奇数尾字

#### 图15 单字尾拍计四字节

DUT位置：TOP.u_pcie.u_pcie_fdma_aurora_brg_adapter.U_RTDS_RX_BLOCK_WRITER

对应测试点：P-15 奇数尾字0F使能（S-10、S-07）；P-10 低32bit字拼接（S-07）

用例关系：TC-M02 上行拼接、环形队列与B响应。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：ring，1628～1695 ns；0929原图03。

验证功能：验证窗口收尾时只剩一个有效字仍能保存，且不会把无效高半写入或多计长度。

图中关系：half_valid说明有剩余字，tail_start触发写请求，fdma_wstrb为0F、WDATA低半为12；响应成功后used_bytes由8到12，head_len随后为12。

设计逻辑：tail_start要求状态空闲、seal_pending且half_valid；active_transfer锁成{4字节,0F,0,half_data}。四个低字节更新而非完整8字节更新，write_success时只加4。写事务与最后尾字都结束后才能形成可读块。

判断依据：WSTRB、长度增量和队头长度三者共同支持P-15，P-10的字数×4规则也可见。ring下游是FDMA字节模型；真实CONV_DMA透传及同址高半保留由AXI字节使能小节另验证。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| U_RTDS_RX_BLOCK_WRITER.frame_data | 0 | 上游输入的 64bit 原拍，writer 仅取其低 32bit。 |
| U_RTDS_RX_BLOCK_WRITER.frame_valid | 0 | 当前流数据有效；是否前进还需看 frame_ready。 |
| U_RTDS_RX_BLOCK_WRITER.half_data | 0 | 待配对的第一个有效低 32bit 字；高 32bit 输入被丢弃。 |
| U_RTDS_RX_BLOCK_WRITER.half_valid | 1 | 已有半个 64bit 写拍，等下一有效字或窗口尾封存。 |
| U_RTDS_RX_BLOCK_WRITER.tail_start | 2 | 封存时只有一个 32bit 字，触发 0F 尾拍。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_waddr | 2 | 本次 FDMA 写事务的字节地址；环形块地址由写指针与已提交长度形成。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_wdata | 1 | 交给 FDMA 的 64bit 写拍数据；是否写入由接受、B 响应和 WSTRB 分别决定。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_wstrb | 1 | 8 个字节写使能，FF 为全拍，0F 只更新低四字节。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_wareq | 2 | 写地址/拍数请求，需等 fdma_wbusy 确认接受。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_waccept | 2 | 一个 FDMA 数据拍实际被接受的事件；早于最终 B 响应。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_wdone | 2 | 整笔 FDMA 写在最终 B 响应后完成的脉冲。 |
| U_RTDS_RX_BLOCK_WRITER.write_success | 2 | 写状态在 RESPONSE 且 fdma_wdone、无错。 |
| U_RTDS_RX_BLOCK_WRITER.used_bytes | 2 | 当前写块中已经得到成功 B 响应的有效字节数。 |
| U_RTDS_RX_BLOCK_WRITER.head_len | 2 | 当前队头已成功提交的有效字节数。 |
| U_RTDS_RX_BLOCK_WRITER.head_seq | 2 | 当前队头的发布序号，用于识别回绕后的新块。 |

### 4.5 等待写响应

#### 图16 截止后等待在途写

DUT位置：TOP.u_pcie.u_pcie_fdma_aurora_brg_adapter.U_RTDS_RX_BLOCK_WRITER

对应测试点：P-14 延迟及错误B响应（S-10、S-26）；P-25 真实100ms周期（S-25、S-10、S-09）

用例关系：TC-M02 上行拼接、环形队列与B响应。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：ring，26420～26455 ns；0929原图08。

验证功能：验证周期到期只是要求本块收尾，不能把未确认的写数据立即交给CPU读取。

图中关系：response_delay被放大后，tick发生、seal_pending置起，但write_curr_st保持RESPONSE=3，fdma_wbusy仍高，done/write_success缺席，used_bytes/ready_blocks保持0。这张图主要价值就是这些结果线不提前变化。

设计逻辑：tick只有一拍，seal_pending把收尾要求保存到写事务真正完成；它同时限制新输入追加。seal_done需要状态回IDLE且没有半字，push_block还要求used_bytes非零。等B期间这些条件不满足，即使数据已被accept也不能给CPU可读长度。

判断依据：P-14验证的是相对先后：周期截止和写接受都发生了，成功响应未到仍不可读。P-25只获得收尾机制解释，测试200拍即0.8µs，不能替代生产25000000拍的100ms间隔。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| 测试激励/统计：response_delay | 0 | 测试台故意延迟 FDMA B 响应的配置值。 |
| U_RTDS_RX_BLOCK_WRITER.tick | 2 | writer内部周期到期条件；这份波形 PERIOD_CYCLES=200、250MHz，间隔0.8µs，生产参数100ms另需验证。 |
| U_RTDS_RX_BLOCK_WRITER.seal_pending | 1 | 窗口需封存，但可能仍等在途 B 响应。 |
| U_RTDS_RX_BLOCK_WRITER.write_curr_st | 0 | writer 的请求、数据、等待响应状态。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_wbusy | 0 | FDMA 已接事务且尚未完成响应，不能等同于写成功。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_wdone | 0 | 整笔 FDMA 写在最终 B 响应后完成的脉冲。 |
| U_RTDS_RX_BLOCK_WRITER.write_success | 0 | 写状态在 RESPONSE 且 fdma_wdone、无错。 |
| U_RTDS_RX_BLOCK_WRITER.used_bytes | 0 | 当前写块中已经得到成功 B 响应的有效字节数。 |
| U_RTDS_RX_BLOCK_WRITER.push_block | 0 | 把成功封存的块元数据压入待 CPU 处理队列。 |
| U_RTDS_RX_BLOCK_WRITER.ready_blocks | 0 | 对 CPU 显示的待处理块数量。 |

#### 图17 成功后形成可读块

DUT位置：TOP.u_pcie.u_pcie_fdma_aurora_brg_adapter.U_RTDS_RX_BLOCK_WRITER

对应测试点：P-14 延迟及错误B响应（S-10、S-26）；P-25 真实100ms周期（S-25、S-10、S-09）

用例关系：TC-M02 上行拼接、环形队列与B响应。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：ring，27090～27125 ns；0929原图09。

验证功能：与上一图组成反例/正例：同一写事务在B未到与B成功到达时，可读队列应有不同结果。

图中关系：fdma_wdone到来且error低使write_success出现；状态退出RESPONSE，used_bytes增加8，随后push_block使ready_blocks与head_len从0到1块/8字节。seal_pending在收尾完成后解除。

设计逻辑：先把成功字节计入当前块，再把长度保存到block_len[write_block]，同时写序号并推进写槽。push_block是“元数据已可交付”的条件，并非重复写一次数据；CPU读取的长度只能包含此前确认的字节。

判断依据：上一图不早读、此图成功后只加入一个块，共同支持P-14；TB的EARLY_PUBLISH检查跨图之间的长等待。P-25仍缺生产周期图，延迟B时可读时刻晚于周期边界是预期。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| U_RTDS_RX_BLOCK_WRITER.seal_pending | 1 | 窗口需封存，但可能仍等在途 B 响应。 |
| U_RTDS_RX_BLOCK_WRITER.write_curr_st | 1 | writer 的请求、数据、等待响应状态。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_wbusy | 1 | FDMA 已接事务且尚未完成响应，不能等同于写成功。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_wdone | 2 | 整笔 FDMA 写在最终 B 响应后完成的脉冲。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_werror | 0 | 最终写响应错误汇总；与 done 同看才能决定是否提交长度。 |
| U_RTDS_RX_BLOCK_WRITER.write_success | 2 | 写状态在 RESPONSE 且 fdma_wdone、无错。 |
| U_RTDS_RX_BLOCK_WRITER.used_bytes | 2 | 当前写块中已经得到成功 B 响应的有效字节数。 |
| U_RTDS_RX_BLOCK_WRITER.push_block | 2 | 把成功封存的块元数据压入待 CPU 处理队列。 |
| U_RTDS_RX_BLOCK_WRITER.ready_blocks | 1 | 对 CPU 显示的待处理块数量。 |
| U_RTDS_RX_BLOCK_WRITER.head_len | 1 | 当前队头已成功提交的有效字节数。 |
| U_RTDS_RX_BLOCK_WRITER.head_seq | 1 | 当前队头的发布序号，用于识别回绕后的新块。 |

### 4.6 失败与恢复

#### 图18 失败写不算有效长度

DUT位置：TOP.u_pcie.u_pcie_fdma_aurora_brg_adapter.U_RTDS_RX_BLOCK_WRITER

对应测试点：P-14 延迟及错误B响应（S-10、S-26）

用例关系：TC-M02 上行拼接、环形队列与B响应。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：ring，27135～27200 ns；0929原图10。

验证功能：验证下游报告写失败时，硬件不把这两个字当成可用数据交给CPU，同时把损失计入诊断。

图中关系：inject_error使done与error同时有效，write_failure出现；dropped_frames增加2，used_bytes保持0，push_block和ready_blocks不产生新可读块。

设计逻辑：done表示事务结束，error决定成功与否。write_failure按active_transfer中有效字节数/4增加丢字，write_success分支不成立所以长度不前进。新写地址由已成功长度生成，失败数据不会作为一段有效间隙对外报告。

判断依据：P-14由“错误被真实注入—失败条件命中—长度不加—队列不增加—丢字加2”完整关联支持。RAM内容本身可能不可靠，软件仅按成功长度读取，并用累计丢字诊断；这不提供逐字缺口位置。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| 测试激励/统计：inject_error | 1 | 测试台注错开关，用于区分预期错误路径和偶发故障。 |
| U_RTDS_RX_BLOCK_WRITER.frame_data | 2 | 上游输入的 64bit 原拍，writer 仅取其低 32bit。 |
| U_RTDS_RX_BLOCK_WRITER.frame_valid | 4 | 当前流数据有效；是否前进还需看 frame_ready。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_wdone | 2 | 整笔 FDMA 写在最终 B 响应后完成的脉冲。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_werror | 1 | 最终写响应错误汇总；与 done 同看才能决定是否提交长度。 |
| U_RTDS_RX_BLOCK_WRITER.write_failure | 2 | 写状态在 RESPONSE 且 fdma_wdone、有错。 |
| U_RTDS_RX_BLOCK_WRITER.dropped_frames | 1 | 累计无法存储的有效 32bit 字数；名称沿用 frames，但单位不是整帧。 |
| U_RTDS_RX_BLOCK_WRITER.used_bytes | 0 | 当前写块中已经得到成功 B 响应的有效字节数。 |
| U_RTDS_RX_BLOCK_WRITER.push_block | 0 | 把成功封存的块元数据压入待 CPU 处理队列。 |
| U_RTDS_RX_BLOCK_WRITER.ready_blocks | 0 | 对 CPU 显示的待处理块数量。 |
| U_RTDS_RX_BLOCK_WRITER.head_seq | 0 | 当前队头的发布序号，用于识别回绕后的新块。 |

#### 图19 失败后继续写新数据

DUT位置：TOP.u_pcie.u_pcie_fdma_aurora_brg_adapter.U_RTDS_RX_BLOCK_WRITER

对应测试点：P-14 延迟及错误B响应（S-10、S-26）；P-15 奇数尾字0F使能（S-10、S-07）

用例关系：TC-M02 上行拼接、环形队列与B响应。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：ring，28830～28895 ns；0929原图11。

验证功能：验证错误处理没有把writer永久留在响应等待，也没有给失败块占用新的可读序号。

图中关系：注错关闭后新的单字4000走0F尾拍，done无错使write_success成立；used_bytes计4，push_block形成head_len=4、head_seq=33、ready_blocks=1。

设计逻辑：写失败结束事务但不提交长度，可读序号只有push_block时递增。后续新有效字仍按当前未提交位置处理，尾拍也遵守成功响应后计数；一次失败不会自动确认CPU旧块，也不会生成虚假可读块。

判断依据：正确新字、四字节长度和连续队头序号支持P-14恢复，0F路径支持P-15。TB还核对恢复数据4000，避免只看状态恢复却没有检查载荷；DDR后端超时和整体链路恢复属于其他测试。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| 测试激励/统计：inject_error | 0 | 测试台注错开关，用于区分预期错误路径和偶发故障。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_wdata | 1 | 交给 FDMA 的 64bit 写拍数据；是否写入由接受、B 响应和 WSTRB 分别决定。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_wstrb | 1 | 8 个字节写使能，FF 为全拍，0F 只更新低四字节。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_wdone | 2 | 整笔 FDMA 写在最终 B 响应后完成的脉冲。 |
| U_RTDS_RX_BLOCK_WRITER.fdma_werror | 1 | 最终写响应错误汇总；与 done 同看才能决定是否提交长度。 |
| U_RTDS_RX_BLOCK_WRITER.write_success | 2 | 写状态在 RESPONSE 且 fdma_wdone、无错。 |
| U_RTDS_RX_BLOCK_WRITER.used_bytes | 2 | 当前写块中已经得到成功 B 响应的有效字节数。 |
| U_RTDS_RX_BLOCK_WRITER.push_block | 2 | 把成功封存的块元数据压入待 CPU 处理队列。 |
| U_RTDS_RX_BLOCK_WRITER.ready_blocks | 2 | 对 CPU 显示的待处理块数量。 |
| U_RTDS_RX_BLOCK_WRITER.head_len | 2 | 当前队头已成功提交的有效字节数。 |
| U_RTDS_RX_BLOCK_WRITER.head_seq | 2 | 当前队头的发布序号，用于识别回绕后的新块。 |

## 5 块管理

上行 DDR 有8个256KiB槽，数据写成功并收尾后才成为 CPU 可读块；只有 CPU 读完确认才归还一个槽。IRQ是通知、ready_blocks是工作数量、head_*是本次读取目标，三个概念应分开。依据详细设计 §5.1/§6.4、深度解析 §3/§5.3～§5.5。

### 5.1 可读与确认

确认规则：确认是数据所有权归还：CPU先用head_addr/head_len完成C2H，再写0x14=1。0x20是下行忙位及启动命令，与上行读完确认不同；fdma_wdone表示一次DDR写请求结束，也不是CPU已读完。

确认规则：writer的条件是pop_block=cpu_ack&&(queued!=0)，每个clk上升沿都检查，不在writer内部做上升沿过滤。单拍保证来自INFO_EXCH的W1P源；若cpu_ack持续多拍而队列非空，会逐拍释放多块。空队列时确认不pop，head_seq=0也可能是首个有效块，是否为空应看ready_blocks。

确认规则：read_block仅在pop_block时前进并按8槽回绕。head_addr=BASE_ADDR+read_block×BLOCK_BYTES，head_len/head_seq取这个槽保存的元数据；每释放一块，这三项一同转向下一块。它们不表示正在写入的write_block。

确认规则：queued按{push_block,pop_block}更新：10加1、01减1、00/11保持。若新块发布和旧块确认同拍，数量不变，但读写指针仍分别前进；不能仅看ready_blocks不变就认为没发生确认。本组未专门隔离验证同拍push/pop，规则来自RTL。

确认规则：IRQ更新有优先级：pop时按(queued>1)||push_block决定是否仍有待读块；否则从空队列push置1；否则irq_clear清0。最后一块确认后通常通知清除，仍有多个块时可继续保持。irq_clear不参与pop或读指针逻辑。

确认规则：截图把cpu_ack与irq_clear一起驱动，所以它可展示pop后的数量/队头/IRQ结果，不能分离“只读清通知”的行为。regs图证明0x14脉冲源及WSTRB门控，ring图证明队列端动作；真实五块逐读确认仍需TC-F12把两端与C2H串起。

#### 图20 可读块与读完确认

DUT位置：TOP.u_pcie.u_pcie_fdma_aurora_brg_adapter.U_RTDS_RX_BLOCK_WRITER

对应测试点：P-17 每次确认只释放一块（S-11、S-14、S-37、S-44、S-45）；P-14 延迟及错误B响应（S-10、S-26）

用例关系：TC-M02 上行拼接、环形队列与B响应。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：ring，824～854 ns；0929原图02。

验证功能：验证数据写成功后，在窗口收尾形成一个可读块；CPU随后读完确认应只归还这个块。

图中关系：tick之后seal_pending/seal_done/push_block成立，queued与ready_blocks从0到1，head_addr/head_len显示首块及8字节，irq置起；cpu_ack使pop_block有效，之后数量回0、队头输出清零。

设计逻辑：push_block=seal_done&&used_bytes!=0保存元数据，pop_block=cpu_ack&&queued!=0归还最老槽。head_*由read_block选出的块元数据形成，确认前应稳定。irq_clear只走通知逻辑，不参与读指针更新；本TB把它与cpu_ack同拍驱动。

判断依据：图支持P-17的队列侧单块释放和P-14的成功后可读。它没有真实0x14写事务或C2H，CPU已完成读取是激励假设；不要在真实DMA尚未结束时确认，以免槽被后续写入重用。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| U_RTDS_RX_BLOCK_WRITER.tick | 2 | writer内部周期到期条件；这份波形 PERIOD_CYCLES=200、250MHz，间隔0.8µs，生产参数100ms另需验证。 |
| U_RTDS_RX_BLOCK_WRITER.seal_pending | 2 | 窗口需封存，但可能仍等在途 B 响应。 |
| U_RTDS_RX_BLOCK_WRITER.seal_done | 2 | 当前封存条件已处理完成。 |
| U_RTDS_RX_BLOCK_WRITER.push_block | 2 | 把成功封存的块元数据压入待 CPU 处理队列。 |
| U_RTDS_RX_BLOCK_WRITER.queued | 2 | 尚未收到 CPU 确认的块数量，范围 0～8。 |
| U_RTDS_RX_BLOCK_WRITER.ready_blocks | 2 | 对 CPU 显示的待处理块数量。 |
| U_RTDS_RX_BLOCK_WRITER.head_addr | 2 | CPU 当前应读的最老块 DDR 首地址。 |
| U_RTDS_RX_BLOCK_WRITER.head_len | 2 | 当前队头已成功提交的有效字节数。 |
| U_RTDS_RX_BLOCK_WRITER.head_seq | 0 | 当前队头的发布序号，用于识别回绕后的新块。 |
| U_RTDS_RX_BLOCK_WRITER.irq | 2 | 有待处理队头的通知状态；与队列所有权不同。 |
| U_RTDS_RX_BLOCK_WRITER.cpu_ack | 2 | CPU 已处理当前队头后的单拍释放确认。 |
| U_RTDS_RX_BLOCK_WRITER.irq_clear | 2 | 只清通知位，不移动队列读指针。 |
| U_RTDS_RX_BLOCK_WRITER.pop_block | 2 | cpu_ack 且队列非空时的出队条件。 |
| U_RTDS_RX_BLOCK_WRITER.read_block | 1 | 最老未确认队头的环槽指针。 |

### 5.2 环槽回绕

#### 图21 第七槽与顺序号

DUT位置：TOP.u_pcie.u_pcie_fdma_aurora_brg_adapter.U_RTDS_RX_BLOCK_WRITER

对应测试点：P-12 三轮地址回绕（S-09、S-07、S-11）

用例关系：TC-M02 上行拼接、环形队列与B响应。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：ring，6470～6510 ns；0929原图04。

验证功能：理解物理环槽与业务序号的区别，并检查最后一个槽后不会生成窗口外地址。

图中关系：head_seq为7时head_addr到0x002C0000，push_block之后write_block从7回0；read_block/ready_blocks随确认反映块仍按先后处理。

设计逻辑：块基址=0x00100000+槽号×0x40000，8个槽覆盖2MiB上行区。write_block取模回绕，但发布序号继续递增，用来区分同一物理地址被后来数据重用。256KiB是单槽容量，不代表此小测试每次真写满256KiB。

判断依据：这是P-12一次回绕前半；必须与下一图的新序号、旧基址配对读。三轮24块的全部内容一致由TB逐字检查，单图只定位边界。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| U_RTDS_RX_BLOCK_WRITER.write_block | 1 | 下一个可写环槽指针，满队时不能覆盖旧槽。 |
| U_RTDS_RX_BLOCK_WRITER.read_block | 1 | 最老未确认队头的环槽指针。 |
| U_RTDS_RX_BLOCK_WRITER.push_block | 2 | 把成功封存的块元数据压入待 CPU 处理队列。 |
| U_RTDS_RX_BLOCK_WRITER.queued | 2 | 尚未收到 CPU 确认的块数量，范围 0～8。 |
| U_RTDS_RX_BLOCK_WRITER.ready_blocks | 2 | 对 CPU 显示的待处理块数量。 |
| U_RTDS_RX_BLOCK_WRITER.head_addr | 2 | CPU 当前应读的最老块 DDR 首地址。 |
| U_RTDS_RX_BLOCK_WRITER.head_len | 2 | 当前队头已成功提交的有效字节数。 |
| U_RTDS_RX_BLOCK_WRITER.head_seq | 2 | 当前队头的发布序号，用于识别回绕后的新块。 |
| U_RTDS_RX_BLOCK_WRITER.irq | 2 | 有待处理队头的通知状态；与队列所有权不同。 |
| U_RTDS_RX_BLOCK_WRITER.cpu_ack | 2 | CPU 已处理当前队头后的单拍释放确认。 |
| U_RTDS_RX_BLOCK_WRITER.pop_block | 2 | cpu_ack 且队列非空时的出队条件。 |

#### 图22 新块复用基地址

DUT位置：TOP.u_pcie.u_pcie_fdma_aurora_brg_adapter.U_RTDS_RX_BLOCK_WRITER

对应测试点：P-12 三轮地址回绕（S-09、S-07、S-11）

用例关系：TC-M02 上行拼接、环形队列与B响应。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：ring，7225～7265 ns；0929原图05。

验证功能：检查回绕后合法重用已经归还的槽，而不是把地址重置误当成旧块重新出现。

图中关系：下一块head_seq继续为8，head_addr回0x00100000，写/读指针在槽0继续推进；ready_blocks和cpu_ack体现每块有独立生命周期。

设计逻辑：槽号是有限地址索引，head_seq是单调业务标识。只有旧块已经确认释放才可重用该槽。序号7→8而地址末槽→首槽，与固定八槽布局相符。

判断依据：两图共同支持P-12地址/序号的回绕趋势；TB对seq0～23按seq%8检查地址与载荷。这个测试每次及时确认，积压时禁止覆盖需要下一节的满队场景。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| U_RTDS_RX_BLOCK_WRITER.write_block | 1 | 下一个可写环槽指针，满队时不能覆盖旧槽。 |
| U_RTDS_RX_BLOCK_WRITER.read_block | 1 | 最老未确认队头的环槽指针。 |
| U_RTDS_RX_BLOCK_WRITER.push_block | 2 | 把成功封存的块元数据压入待 CPU 处理队列。 |
| U_RTDS_RX_BLOCK_WRITER.queued | 2 | 尚未收到 CPU 确认的块数量，范围 0～8。 |
| U_RTDS_RX_BLOCK_WRITER.ready_blocks | 2 | 对 CPU 显示的待处理块数量。 |
| U_RTDS_RX_BLOCK_WRITER.head_addr | 2 | CPU 当前应读的最老块 DDR 首地址。 |
| U_RTDS_RX_BLOCK_WRITER.head_len | 2 | 当前队头已成功提交的有效字节数。 |
| U_RTDS_RX_BLOCK_WRITER.head_seq | 2 | 当前队头的发布序号，用于识别回绕后的新块。 |
| U_RTDS_RX_BLOCK_WRITER.irq | 2 | 有待处理队头的通知状态；与队列所有权不同。 |
| U_RTDS_RX_BLOCK_WRITER.cpu_ack | 2 | CPU 已处理当前队头后的单拍释放确认。 |
| U_RTDS_RX_BLOCK_WRITER.pop_block | 2 | cpu_ack 且队列非空时的出队条件。 |

### 5.3 满队保护

#### 图23 满队宁可丢新字

DUT位置：TOP.u_pcie.u_pcie_fdma_aurora_brg_adapter.U_RTDS_RX_BLOCK_WRITER

对应测试点：P-13 八块满不覆盖（S-09、S-12）

用例关系：TC-M02 上行拼接、环形队列与B响应。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：ring，25672～25710 ns；0929原图06。

验证功能：CPU暂不取走时保护已有八块。允许报告新字损失，但不能损坏CPU仍拥有的旧数据。

图中关系：queued/ready_blocks保持8，输入两个新字时take_word与reject_word同时成立，dropped_frames由0到2；head_addr/head_seq不变，写读指针没有为了新数据挤走队头。

设计逻辑：reject_word=take_word&&(!enable||queued==BLOCK_COUNT||used_bytes>=BLOCK_BYTES)。frame_ready表达writer本拍能处理输入，不保证可存；在满队条件下处理方式是计丢失。停止追加可保护八槽所有权，也避免上游继续把不可存数据永久堵在FIFO。

判断依据：P-13由真实满队、额外输入、丢字增量和旧队头保持支持；TB读取八个原块比较数据排除隐性覆盖。软件应持续按ready_blocks取完块，并观察0x38丢字增长，不能认为只要rx_ready高就无损。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| U_RTDS_RX_BLOCK_WRITER.frame_data | 2 | 上游输入的 64bit 原拍，writer 仅取其低 32bit。 |
| U_RTDS_RX_BLOCK_WRITER.frame_valid | 4 | 当前流数据有效；是否前进还需看 frame_ready。 |
| U_RTDS_RX_BLOCK_WRITER.frame_ready | 1 | writer 接收流接口状态；即使满队也可能接收后计丢弃。 |
| U_RTDS_RX_BLOCK_WRITER.take_word | 4 | 本拍有效输入进入 writer 业务判断。 |
| U_RTDS_RX_BLOCK_WRITER.reject_word | 4 | 本拍无法归属可写块而计丢弃。 |
| U_RTDS_RX_BLOCK_WRITER.queued | 1 | 尚未收到 CPU 确认的块数量，范围 0～8。 |
| U_RTDS_RX_BLOCK_WRITER.ready_blocks | 1 | 对 CPU 显示的待处理块数量。 |
| U_RTDS_RX_BLOCK_WRITER.dropped_frames | 2 | 累计无法存储的有效 32bit 字数；名称沿用 frames，但单位不是整帧。 |
| U_RTDS_RX_BLOCK_WRITER.head_addr | 0 | CPU 当前应读的最老块 DDR 首地址。 |
| U_RTDS_RX_BLOCK_WRITER.head_seq | 0 | 当前队头的发布序号，用于识别回绕后的新块。 |
| U_RTDS_RX_BLOCK_WRITER.write_block | 1 | 下一个可写环槽指针，满队时不能覆盖旧槽。 |
| U_RTDS_RX_BLOCK_WRITER.read_block | 0 | 最老未确认队头的环槽指针。 |

### 5.4 逐块归还

#### 图24 一次确认归还一槽

DUT位置：TOP.u_pcie.u_pcie_fdma_aurora_brg_adapter.U_RTDS_RX_BLOCK_WRITER

对应测试点：P-13 八块满不覆盖（S-09、S-12）；P-17 每次确认只释放一块（S-11、S-14、S-37、S-44、S-45）

用例关系：TC-M02 上行拼接、环形队列与B响应。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：ring，25730～25860 ns；0929原图07。

验证功能：验证积压队列每拍确认只前进一个队头，并观察数量、地址、序号和通知如何配合；读清通知的独立性还需要单独激励。

图中关系：每次cpu_ack/pop_block对应ready_blocks逐级8→7→…→0，head_seq依次24～31，head_addr按0x40000步进；最后读指针回0，队头归零。中间irq即使同时有irq_clear仍因剩余块保持。

设计逻辑：read_block仅pop时前进，queued按{push,pop}增减；同拍双向操作数量保持。irq在pop分支按queued>1或push继续提醒，通知与队列释放各有条件，不能互相替代。

判断依据：支持P-17队列端“一次确认一块”以及P-13旧块可逐一取走。但输入确认由ring TB直接驱动，regs另测脉冲源；真实INFO_EXCH的五块C2H读取、读清0x10不释放属于TC-F12/P-33，尚无本组整链图。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| U_RTDS_RX_BLOCK_WRITER.cpu_ack | 16 | CPU 已处理当前队头后的单拍释放确认。 |
| U_RTDS_RX_BLOCK_WRITER.irq_clear | 16 | 只清通知位，不移动队列读指针。 |
| U_RTDS_RX_BLOCK_WRITER.pop_block | 16 | cpu_ack 且队列非空时的出队条件。 |
| U_RTDS_RX_BLOCK_WRITER.queued | 8 | 尚未收到 CPU 确认的块数量，范围 0～8。 |
| U_RTDS_RX_BLOCK_WRITER.ready_blocks | 8 | 对 CPU 显示的待处理块数量。 |
| U_RTDS_RX_BLOCK_WRITER.head_addr | 8 | CPU 当前应读的最老块 DDR 首地址。 |
| U_RTDS_RX_BLOCK_WRITER.head_len | 1 | 当前队头已成功提交的有效字节数。 |
| U_RTDS_RX_BLOCK_WRITER.head_seq | 8 | 当前队头的发布序号，用于识别回绕后的新块。 |
| U_RTDS_RX_BLOCK_WRITER.read_block | 8 | 最老未确认队头的环槽指针。 |
| U_RTDS_RX_BLOCK_WRITER.irq | 1 | 有待处理队头的通知状态；与队列所有权不同。 |

## 6 AXI访问

CONV_DMA 把一笔 FDMA 请求拆成合法 AXI 事务，地址、数据、响应各按自身握手前进。行为 RAM 用来检查地址与字节内容，图中 AXI 结果不是 MIG 的物理存储时序。依据详细设计 §5.2、深度解析 §6.1/§7.5。

### 6.1 独立握手

#### 图25 地址等待不妨碍数据

DUT位置：TOP.u_pcie.design_1_wrapper_inst.design_1_i.CONV_DMA_0

对应测试点：P-19 AXI独立通道（S-13、S-10）

用例关系：TC-M03 CONV_DMA独立AXI通道与地址。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：axi，40～100 ns；0929原图12。

验证功能：验证AW地址通道与W数据通道各自受理，地址尚未ready时桥不能撤销或改动已宣布的写地址。

图中关系：allow_aw低使AWREADY晚出现，AWVALID/AWADDR/AWLEN保持；WVALID/WREADY可以独立变化，aw_pending与w_pending不要求同时清除。

设计逻辑：AXI把地址、数据、响应分成独立握手通道；bridge以pending记录尚未完成的部分。AW握手只登记地址，不代表所有数据已写完，W握手也不能替代AW接受。地址负载需在VALID高且READY低时保持。

判断依据：有实际AW停顿前件且地址不变，支持P-19，而不是仅因没有错误就判通过。AW_HOLD断言逐沿比较保持；系统集成的跨域桥/IP签核仍属于设计检查。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| CONV_DMA.fdma_wareq | 2 | 写地址/拍数请求，需等 fdma_wbusy 确认接受。 |
| CONV_DMA.fdma_waddr | 1 | 整个 FDMA 写请求起始地址，桥据此拆成 AXI 段。 |
| CONV_DMA.fdma_wsize | 1 | FDMA 请求的 64bit 拍数，不是字节数。 |
| 测试激励/统计：allow_aw | 2 | 测试台人为允许 AWREADY 的门控。 |
| CONV_DMA.M_AXI_AWADDR | 1 | AXI 写地址；只在 AWVALID 与 AWREADY 同时为 1 的沿被接受。 |
| CONV_DMA.M_AXI_AWLEN | 1 | AXI 写突发长度减一，0 表示 1 拍，FF 表示 256 拍。 |
| CONV_DMA.M_AXI_AWVALID | 2 | 桥的写地址有效请求；反压期间必须保持地址和长度。 |
| CONV_DMA.M_AXI_AWREADY | 2 | 下游写地址接受能力；与 AWVALID 同时成立才握手。 |
| CONV_DMA.M_AXI_WVALID | 1 | 桥当前 W 拍有效；WREADY 低时数据和末拍标志需保持。 |
| CONV_DMA.M_AXI_WREADY | 6 | 下游 W 拍接受能力；与 WVALID 同时成立才写拍握手。 |
| CONV_DMA.aw_pending | 2 | 桥仍待下游接受的 AW 地址事务。 |
| CONV_DMA.w_pending | 1 | 桥仍待下游接受的 W 数据事务。 |

#### 图26 末数据拍之后仍等响应

DUT位置：TOP.u_pcie.design_1_wrapper_inst.design_1_i.CONV_DMA_0

对应测试点：P-19 AXI独立通道（S-13、S-10）；P-14 延迟及错误B响应（S-10、S-26）

用例关系：TC-M03 CONV_DMA独立AXI通道与地址。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：axi，210～300 ns；0929原图13。

验证功能：解释AXI末拍被送出与FDMA整笔成功完成是两个阶段，保护上层writer有效长度计数。

图中关系：WLAST与WVALID已高时WREADY仍低，WDATA/WSTRB保持最后一拍；WREADY放行后末拍接受，但fdma_wbusy持续，直到BVALID/BREADY才有done并结束busy。

设计逻辑：WLAST描述当前突发最后数据拍，不能提供响应码。CONV_DMA等AW和W完成后结算B，只有最后一段的B才结束整个FDMA；RESP非OKAY还要汇总error。上层writer据done/error而不是WLAST计长度。

判断依据：图直接支持P-19的W保持与完成边界，并与P-14“成功后计入可读长度”建立设计联系。AXI/W_HOLD断言覆盖多个停顿，不能用总线最后数据消失代替B成功。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| 测试激励/统计：allow_w | 3 | 测试台人为允许 WREADY 的门控。 |
| 测试激励/统计：allow_b | 2 | 测试台人为允许 B 响应的门控。 |
| CONV_DMA.M_AXI_WDATA | 2 | AXI 写数据，只有被 WREADY 接受且 WSTRB 允许的字节才有效。 |
| CONV_DMA.M_AXI_WSTRB | 0 | AXI 每字节写使能，核对 FDMA WSTRB 是否透传。 |
| CONV_DMA.M_AXI_WLAST | 1 | 本段突发最后一个 W 拍标志；不是最终 B 响应。 |
| CONV_DMA.M_AXI_WVALID | 1 | 桥当前 W 拍有效；WREADY 低时数据和末拍标志需保持。 |
| CONV_DMA.M_AXI_WREADY | 5 | 下游 W 拍接受能力；与 WVALID 同时成立才写拍握手。 |
| CONV_DMA.M_AXI_BRESP | 0 | AXI 写响应码；0 为 OKAY，2 为 SLVERR。 |
| CONV_DMA.M_AXI_BVALID | 2 | 下游写响应有效。 |
| CONV_DMA.M_AXI_BREADY | 2 | 桥接受写响应；BVALID 与 BREADY 同时成立才结算事务。 |
| CONV_DMA.fdma_wbusy | 1 | FDMA 已接事务且尚未完成响应，不能等同于写成功。 |
| CONV_DMA.fdma_wdone | 2 | 整笔 FDMA 写在最终 B 响应后完成的脉冲。 |
| CONV_DMA.fdma_werror | 0 | 最终写响应错误汇总；与 done 同看才能决定是否提交长度。 |

### 6.2 地址无别名

#### 图27 八个块地址各自写入

DUT位置：TOP.u_pcie.design_1_wrapper_inst.design_1_i.CONV_DMA_0

对应测试点：P-20 低地址无别名与4KiB拆分（S-13、S-09、S-27）

用例关系：TC-M03 CONV_DMA独立AXI通道与地址。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：axi，40～2035 ns；0929原图14。

验证功能：验证不同上行块基址能被桥与RAM区别，防止测试模型只用低地址位导致不同块互相覆盖。

图中关系：AWADDR按0x00100000、0x00140000…0x002C0000步进，每处AWLEN=0F，即16拍；每笔done之后才开始下一写，wa显示对应写位置。

设计逻辑：地址字段是DDR字节地址，256KiB步长来自上行块布局；不是CPU主机缓冲地址，也不是寄存器偏移。64bit端口宽度不等于当前支持大于4GiB，所选八处都在低4MiB。

判断依据：图支持P-20地址传递部分，是否无别名须与下一读图及不同模式比较合用。旧标题“高地址”应理解为模型内不同块基址，不可解释成CARD_ADDR_HI非零扩展已通过。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| CONV_DMA.fdma_wareq | 16 | 写地址/拍数请求，需等 fdma_wbusy 确认接受。 |
| CONV_DMA.fdma_waddr | 8 | 整个 FDMA 写请求起始地址，桥据此拆成 AXI 段。 |
| CONV_DMA.M_AXI_AWADDR | 8 | AXI 写地址；只在 AWVALID 与 AWREADY 同时为 1 的沿被接受。 |
| CONV_DMA.M_AXI_AWLEN | 1 | AXI 写突发长度减一，0 表示 1 拍，FF 表示 256 拍。 |
| CONV_DMA.M_AXI_AWVALID | 16 | 桥的写地址有效请求；反压期间必须保持地址和长度。 |
| CONV_DMA.M_AXI_AWREADY | 24 | 下游写地址接受能力；与 AWVALID 同时成立才握手。 |
| CONV_DMA.M_AXI_WLAST | 15 | 本段突发最后一个 W 拍标志；不是最终 B 响应。 |
| CONV_DMA.M_AXI_BVALID | 16 | 下游写响应有效。 |
| CONV_DMA.M_AXI_BREADY | 16 | 桥接受写响应；BVALID 与 BREADY 同时成立才结算事务。 |
| CONV_DMA.fdma_wdone | 16 | 整笔 FDMA 写在最终 B 响应后完成的脉冲。 |
| CONV_DMA.wa | 8 | 拆分后的下一写段 AXI 地址。 |

#### 图28 地址隔离靠读回确认

DUT位置：TOP.u_pcie.design_1_wrapper_inst.design_1_i.CONV_DMA_0

对应测试点：P-20 低地址无别名与4KiB拆分（S-13、S-09、S-27）；P-19 AXI独立通道（S-13、S-10）

用例关系：TC-M03 CONV_DMA独立AXI通道与地址。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：axi，2038～3220 ns；0929原图15。

验证功能：给前面的八处写入建立反向证据，确认多个地址并非最终都读到同一个RAM位置。

图中关系：ARADDR按原八处发请求，ARLEN为0F；RDATA高32bit区分块号、低32bit为拍号，RLAST与fdma_rvalid指出每段最后一个被接受的字。

设计逻辑：实际接受是RVALID&&RREADY，数据线上停留并不多算一拍。模型保存各地址内容，TB对每一拍{block_id,beat}严格比较，而非只看RLAST。八种不同模式都读回才排除别名。

判断依据：写址序列、读址序列与数据差异一起支持P-20，完整读序列支持P-19。模型范围仍为4MiB，不验证真实MIG存储、物理DDR或>4GiB映射。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| CONV_DMA.fdma_rareq | 16 | FDMA 读请求；桥/存储侧接受后才进入数据阶段。 |
| CONV_DMA.fdma_raddr | 8 | 整个 FDMA 读请求起始地址，桥据此拆成 AXI 段。 |
| CONV_DMA.M_AXI_ARADDR | 8 | AXI 读地址；用于核对高地址与跨 4KiB 拆分。 |
| CONV_DMA.M_AXI_ARLEN | 1 | AXI 读突发长度减一。 |
| CONV_DMA.M_AXI_ARVALID | 16 | 桥发出的读地址有效请求。 |
| CONV_DMA.M_AXI_ARREADY | 16 | 下游读地址接受能力。 |
| CONV_DMA.M_AXI_RDATA | 127 | AXI 返回的 64bit 数据；只有 RVALID/RREADY 握手才计拍。 |
| CONV_DMA.M_AXI_RLAST | 16 | 当前 AXI 读突发的最后一拍。 |
| CONV_DMA.M_AXI_RVALID | 256 | 下游当前读拍有效。 |
| CONV_DMA.M_AXI_RREADY | 16 | 桥当前可以接受读拍。 |
| CONV_DMA.fdma_rvalid | 256 | 本桥历史接口的已接受读拍脉冲，须与 AXI RVALID/RREADY 区分。 |
| CONV_DMA.ra | 8 | 拆分后的下一读段 AXI 地址。 |

### 6.3 突发拆分

#### 图29 先到4KiB边界

DUT位置：TOP.u_pcie.design_1_wrapper_inst.design_1_i.CONV_DMA_0

对应测试点：P-20 低地址无别名与4KiB拆分（S-13、S-09、S-27）

用例关系：TC-M03 CONV_DMA独立AXI通道与地址。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：axi，3218～3300 ns；0929原图16。

验证功能：说明跨边界请求可以合法完成，桥通过拆分满足AXI规则，而不是将请求拒绝或直接跨4KiB发突发。

图中关系：FDMA起址0x00180FF8、总数520拍；首段AWLEN=0，W末拍单独结束，随后B结算并出现下段0x00181000。首段W接受可以早于AW接受。

设计逻辑：burst_beats取剩余拍数、256、到4KiB边界可容纳拍数的最小值。0xFF8到0x1000只剩8Byte，64bit每拍8Byte，所以只能1拍；LEN存拍数减一。通道独立允许先收数据，再把这次单拍地址受理。

判断依据：P-20关键是首段停在边界而下段从整4KiB地址开始；CROSS_4K断言检查每段不跨界。整个520拍请求跨界是输入条件，拆分后的每段不跨界才是设计结果。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| CONV_DMA.fdma_wareq | 2 | 写地址/拍数请求，需等 fdma_wbusy 确认接受。 |
| CONV_DMA.fdma_waddr | 1 | 整个 FDMA 写请求起始地址，桥据此拆成 AXI 段。 |
| CONV_DMA.fdma_wsize | 1 | FDMA 请求的 64bit 拍数，不是字节数。 |
| CONV_DMA.wleft | 2 | 整个 FDMA 写请求尚未完成的拍数。 |
| CONV_DMA.M_AXI_AWADDR | 2 | AXI 写地址；只在 AWVALID 与 AWREADY 同时为 1 的沿被接受。 |
| CONV_DMA.M_AXI_AWLEN | 2 | AXI 写突发长度减一，0 表示 1 拍，FF 表示 256 拍。 |
| CONV_DMA.M_AXI_AWVALID | 4 | 桥的写地址有效请求；反压期间必须保持地址和长度。 |
| CONV_DMA.M_AXI_AWREADY | 4 | 下游写地址接受能力；与 AWVALID 同时成立才握手。 |
| CONV_DMA.M_AXI_WLAST | 1 | 本段突发最后一个 W 拍标志；不是最终 B 响应。 |
| CONV_DMA.M_AXI_WVALID | 3 | 桥当前 W 拍有效；WREADY 低时数据和末拍标志需保持。 |
| CONV_DMA.M_AXI_WREADY | 6 | 下游 W 拍接受能力；与 WVALID 同时成立才写拍握手。 |
| CONV_DMA.M_AXI_BVALID | 2 | 下游写响应有效。 |
| CONV_DMA.M_AXI_BREADY | 2 | 桥接受写响应；BVALID 与 BREADY 同时成立才结算事务。 |
| CONV_DMA.fdma_wdone | 0 | 整笔 FDMA 写在最终 B 响应后完成的脉冲。 |

#### 图30 满长突发与剩余拍数

DUT位置：TOP.u_pcie.design_1_wrapper_inst.design_1_i.CONV_DMA_0

对应测试点：P-20 低地址无别名与4KiB拆分（S-13、S-09、S-27）

用例关系：TC-M03 CONV_DMA独立AXI通道与地址。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：axi，5858～6030 ns；0929原图17。

验证功能：验证跨过首个边界后，大请求仍受256拍上限约束，并在收到段响应后按实际长度推进地址。

图中关系：第二段AWLEN=FF对应256拍，WLAST结束该段但wleft尚未归零；B完成后wa和AWADDR进入0x00181800，下一段仍FF。

设计逻辑：一个满长段占256×8=2048Byte。wleft按已完成段拍数扣减，wa按相同字节数递增，地址计数不能只在WLAST出现时重复启动而跳过B结算。此时还剩后段，所以fdma_wdone不应出现。

判断依据：地址步长、LEN和未完成数量相互对应，支持P-20的中段拆分，也验证P-19响应与下一事务的先后。全程拍数由TB计数，截图只展示段间收束位置。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| CONV_DMA.wleft | 1 | 整个 FDMA 写请求尚未完成的拍数。 |
| CONV_DMA.wa | 1 | 拆分后的下一写段 AXI 地址。 |
| CONV_DMA.M_AXI_AWADDR | 1 | AXI 写地址；只在 AWVALID 与 AWREADY 同时为 1 的沿被接受。 |
| CONV_DMA.M_AXI_AWLEN | 0 | AXI 写突发长度减一，0 表示 1 拍，FF 表示 256 拍。 |
| CONV_DMA.M_AXI_AWVALID | 2 | 桥的写地址有效请求；反压期间必须保持地址和长度。 |
| CONV_DMA.M_AXI_AWREADY | 2 | 下游写地址接受能力；与 AWVALID 同时成立才握手。 |
| CONV_DMA.M_AXI_WLAST | 1 | 本段突发最后一个 W 拍标志；不是最终 B 响应。 |
| CONV_DMA.M_AXI_WVALID | 2 | 桥当前 W 拍有效；WREADY 低时数据和末拍标志需保持。 |
| CONV_DMA.M_AXI_WREADY | 6 | 下游 W 拍接受能力；与 WVALID 同时成立才写拍握手。 |
| CONV_DMA.M_AXI_BVALID | 2 | 下游写响应有效。 |
| CONV_DMA.M_AXI_BREADY | 2 | 桥接受写响应；BVALID 与 BREADY 同时成立才结算事务。 |
| CONV_DMA.fdma_wdone | 0 | 整笔 FDMA 写在最终 B 响应后完成的脉冲。 |

#### 图31 最后一段结束总请求

DUT位置：TOP.u_pcie.design_1_wrapper_inst.design_1_i.CONV_DMA_0

对应测试点：P-20 低地址无别名与4KiB拆分（S-13、S-09、S-27）；P-19 AXI独立通道（S-13、S-10）

用例关系：TC-M03 CONV_DMA独立AXI通道与地址。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：axi，8700～8860 ns；0929原图18。

验证功能：验证剩余拍数不足256时不会补齐多余数据，且上层done只在整个请求结束时产生。

图中关系：前三段1+256+256完成后，末段AWADDR到0x00182000、AWLEN=6表示7拍；WLAST后等待B，最后B才有fdma_wdone。

设计逻辑：520−1−256−256=7，LEN=7−1。wleft/wa把拆分段与原请求联系起来；每段都能有B响应，但前三段只减少剩余量，最后段才释放FDMA busy并给完成。

判断依据：段长度合计520且done只跟最终响应，支持P-20数量正确及P-19事务完整性。若把每个B当整个FDMA完成，上层会漏写后段，这正是需要测试的风险。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| CONV_DMA.wleft | 1 | 整个 FDMA 写请求尚未完成的拍数。 |
| CONV_DMA.wa | 1 | 拆分后的下一写段 AXI 地址。 |
| CONV_DMA.M_AXI_AWADDR | 1 | AXI 写地址；只在 AWVALID 与 AWREADY 同时为 1 的沿被接受。 |
| CONV_DMA.M_AXI_AWLEN | 1 | AXI 写突发长度减一，0 表示 1 拍，FF 表示 256 拍。 |
| CONV_DMA.M_AXI_AWVALID | 2 | 桥的写地址有效请求；反压期间必须保持地址和长度。 |
| CONV_DMA.M_AXI_AWREADY | 2 | 下游写地址接受能力；与 AWVALID 同时成立才握手。 |
| CONV_DMA.M_AXI_WLAST | 2 | 本段突发最后一个 W 拍标志；不是最终 B 响应。 |
| CONV_DMA.M_AXI_WVALID | 2 | 桥当前 W 拍有效；WREADY 低时数据和末拍标志需保持。 |
| CONV_DMA.M_AXI_WREADY | 14 | 下游 W 拍接受能力；与 WVALID 同时成立才写拍握手。 |
| CONV_DMA.M_AXI_BVALID | 4 | 下游写响应有效。 |
| CONV_DMA.M_AXI_BREADY | 3 | 桥接受写响应；BVALID 与 BREADY 同时成立才结算事务。 |
| CONV_DMA.fdma_wdone | 2 | 整笔 FDMA 写在最终 B 响应后完成的脉冲。 |

#### 图32 读拆分保持总序列

DUT位置：TOP.u_pcie.design_1_wrapper_inst.design_1_i.CONV_DMA_0

对应测试点：P-20 低地址无别名与4KiB拆分（S-13、S-09、S-27）；P-19 AXI独立通道（S-13、S-10）

用例关系：TC-M03 CONV_DMA独立AXI通道与地址。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：axi，12980～13060 ns；0929原图19。

验证功能：验证读侧用相同边界规则，返回全请求的数据顺序，没有在段切换处重拍或丢拍。

图中关系：最后ARLEN=6，ARADDR与末段写地址对应；RDATA低拍号继续递增到519，高半保持本请求模式123，RLAST只标段尾，rleft在完成后收束。

设计逻辑：AR/R分开握手，rleft和ra描述全请求剩余拍数与下一段字节地址。每个R拍只有被RREADY接受才计入fdma_rvalid，段间RLAST不能重置业务模式中的全局拍号。

判断依据：末拍{123,519}配合520拍逐拍比较支持P-20读写一致和P-19完整返回。单独末值不能排除中间错拍，所以保留AXI/DATA比较依据。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| CONV_DMA.M_AXI_ARADDR | 1 | AXI 读地址；用于核对高地址与跨 4KiB 拆分。 |
| CONV_DMA.M_AXI_ARLEN | 1 | AXI 读突发长度减一。 |
| CONV_DMA.M_AXI_ARVALID | 2 | 桥发出的读地址有效请求。 |
| CONV_DMA.M_AXI_ARREADY | 3 | 下游读地址接受能力。 |
| CONV_DMA.M_AXI_RDATA | 8 | AXI 返回的 64bit 数据；只有 RVALID/RREADY 握手才计拍。 |
| CONV_DMA.M_AXI_RLAST | 4 | 当前 AXI 读突发的最后一拍。 |
| CONV_DMA.M_AXI_RVALID | 17 | 下游当前读拍有效。 |
| CONV_DMA.M_AXI_RREADY | 3 | 桥当前可以接受读拍。 |
| CONV_DMA.fdma_rvalid | 17 | 本桥历史接口的已接受读拍脉冲，须与 AXI RVALID/RREADY 区分。 |
| CONV_DMA.fdma_rbusy | 1 | FDMA 读事务从接受到结束的占用状态。 |
| CONV_DMA.rleft | 1 | 整个 FDMA 读请求尚未完成的拍数。 |
| CONV_DMA.ra | 1 | 拆分后的下一读段 AXI 地址。 |

### 6.4 响应错误

#### 图33 响应错误向上层传递

DUT位置：TOP.u_pcie.design_1_wrapper_inst.design_1_i.CONV_DMA_0

对应测试点：P-19 AXI独立通道（S-13、S-10）；P-14 延迟及错误B响应（S-10、S-26）

用例关系：TC-M03 CONV_DMA独立AXI通道与地址。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：axi，13280～13316 ns；0929原图20。

验证功能：验证桥能够把下游失败告知业务层，防止上层把事务结束误作存储成功。

图中关系：ram_bresp保持OKAY，inject_error使总线BRESP变SLVERR=2；BVALID/BREADY握手之后fdma_wdone与fdma_werror同时出现，busy解除。

设计逻辑：注错发生在响应边界，不是原RAM偶发失败。B只在VALID&&READY时结算，done表示请求结束，error表示不可作为成功提交。writer以这对信号选择write_failure，故与ring错误图构成模块间设计对照而非同一次整链波形。

判断依据：P-19的错误传播有实际非OKAY前件；P-14获得桥端关联证据，ring另验证长度与丢字处理。DDR_STATUS真实寄存器位映射、清错或超时不是本图内容，P-34仍待补。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| 测试激励/统计：inject_error | 0 | 测试台注错开关，用于区分预期错误路径和偶发故障。 |
| 测试激励/统计：ram_bresp | 0 | 行为 RAM 原始 B 响应，用来辨认注错来自测试台。 |
| CONV_DMA.M_AXI_WLAST | 0 | 本段突发最后一个 W 拍标志；不是最终 B 响应。 |
| CONV_DMA.M_AXI_WVALID | 1 | 桥当前 W 拍有效；WREADY 低时数据和末拍标志需保持。 |
| CONV_DMA.M_AXI_WREADY | 2 | 下游 W 拍接受能力；与 WVALID 同时成立才写拍握手。 |
| CONV_DMA.M_AXI_BRESP | 0 | AXI 写响应码；0 为 OKAY，2 为 SLVERR。 |
| CONV_DMA.M_AXI_BVALID | 2 | 下游写响应有效。 |
| CONV_DMA.M_AXI_BREADY | 2 | 桥接受写响应；BVALID 与 BREADY 同时成立才结算事务。 |
| CONV_DMA.fdma_wbusy | 1 | FDMA 已接事务且尚未完成响应，不能等同于写成功。 |
| CONV_DMA.fdma_wdone | 2 | 整笔 FDMA 写在最终 B 响应后完成的脉冲。 |
| CONV_DMA.fdma_werror | 1 | 最终写响应错误汇总；与 done 同看才能决定是否提交长度。 |

### 6.5 字节使能

#### 图34 先建立完整旧值

DUT位置：TOP.u_pcie.design_1_wrapper_inst.design_1_i.CONV_DMA_0

对应测试点：P-15 奇数尾字0F使能（S-10、S-07）

用例关系：TC-M04 AXI奇数尾字保留高半。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：axi_tail，40～175 ns；0929原图39。

验证功能：为部分字节写建立有意义的初始数据，使随后可以辨别高半是否被误改，而非只看WSTRB线路值。

图中关系：同址0x002FFFF8的数据为12345678_12345678，FDMA与AXI两侧WSTRB都FF；W握手后成功B到来，done才指示第一次写结束。

设计逻辑：WSTRB每一位控制WDATA的一个Byte，FF允许全部八字节更新。先得到成功响应再覆盖低半，保证第二步的高32bit有可比较的预置模式。该地址是低4MiB模型内一个高偏移位置，并非模型末字。

判断依据：本图是P-15部分写测试的基线，不单独构成高半保留结论；与后两图连读才得到字节使能到存储内容的证据链。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| CONV_DMA.fdma_waddr | 1 | 本次 FDMA 写事务的字节地址；环形块地址由写指针与已提交长度形成。 |
| CONV_DMA.fdma_wdata | 1 | 交给 FDMA 的 64bit 写拍数据；是否写入由接受、B 响应和 WSTRB 分别决定。 |
| CONV_DMA.fdma_wstrb | 0 | 8 个字节写使能，FF 为全拍，0F 只更新低四字节。 |
| CONV_DMA.fdma_wareq | 2 | 写地址/拍数请求，需等 fdma_wbusy 确认接受。 |
| CONV_DMA.M_AXI_AWADDR | 1 | AXI 写地址；只在 AWVALID 与 AWREADY 同时为 1 的沿被接受。 |
| CONV_DMA.M_AXI_AWLEN | 1 | AXI 写突发长度减一，0 表示 1 拍，FF 表示 256 拍。 |
| CONV_DMA.M_AXI_WDATA | 1 | AXI 写数据，只有被 WREADY 接受且 WSTRB 允许的字节才有效。 |
| CONV_DMA.M_AXI_WSTRB | 0 | AXI 每字节写使能，核对 FDMA WSTRB 是否透传。 |
| CONV_DMA.M_AXI_WVALID | 2 | 桥当前 W 拍有效；WREADY 低时数据和末拍标志需保持。 |
| CONV_DMA.M_AXI_WREADY | 6 | 下游 W 拍接受能力；与 WVALID 同时成立才写拍握手。 |
| CONV_DMA.M_AXI_BVALID | 2 | 下游写响应有效。 |
| CONV_DMA.M_AXI_BREADY | 2 | 桥接受写响应；BVALID 与 BREADY 同时成立才结算事务。 |
| CONV_DMA.fdma_wdone | 2 | 整笔 FDMA 写在最终 B 响应后完成的脉冲。 |

#### 图35 低四字节允许覆盖

DUT位置：TOP.u_pcie.design_1_wrapper_inst.design_1_i.CONV_DMA_0

对应测试点：P-15 奇数尾字0F使能（S-10、S-07）

用例关系：TC-M04 AXI奇数尾字保留高半。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：axi_tail，176～300 ns；0929原图40。

验证功能：验证writer的单字尾拍格式可以穿过CONV_DMA，后端不会因WDATA有64bit值而误写高半。

图中关系：FDMA和AXI的WSTRB同为0F，新WDATA虽然高低半都为DEADBEEF，W握手期间仅低四字节被标有效；随后B为OKAY，done高而error低。

设计逻辑：CONV_DMA透传WSTRB；行为RAM循环每个Byte，仅在对应strobe位为1时更新该Byte。上半DEADBEEF在线上可见但不具写授权，所以预置高半12345678必须保持。数据总线宽度与有效字节数分开是奇数尾字设计的核心。

判断依据：P-15首先由两侧0F一致支持透传，最终正确性仍看下一张同址读回。成功B只能说明事务结算，没有读回比较不能声称未误改高半。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| CONV_DMA.fdma_waddr | 0 | 本次 FDMA 写事务的字节地址；环形块地址由写指针与已提交长度形成。 |
| CONV_DMA.fdma_wdata | 1 | 交给 FDMA 的 64bit 写拍数据；是否写入由接受、B 响应和 WSTRB 分别决定。 |
| CONV_DMA.fdma_wstrb | 1 | 8 个字节写使能，FF 为全拍，0F 只更新低四字节。 |
| CONV_DMA.fdma_wareq | 2 | 写地址/拍数请求，需等 fdma_wbusy 确认接受。 |
| CONV_DMA.M_AXI_AWADDR | 0 | AXI 写地址；只在 AWVALID 与 AWREADY 同时为 1 的沿被接受。 |
| CONV_DMA.M_AXI_WDATA | 1 | AXI 写数据，只有被 WREADY 接受且 WSTRB 允许的字节才有效。 |
| CONV_DMA.M_AXI_WSTRB | 1 | AXI 每字节写使能，核对 FDMA WSTRB 是否透传。 |
| CONV_DMA.M_AXI_WVALID | 2 | 桥当前 W 拍有效；WREADY 低时数据和末拍标志需保持。 |
| CONV_DMA.M_AXI_WREADY | 2 | 下游 W 拍接受能力；与 WVALID 同时成立才写拍握手。 |
| CONV_DMA.M_AXI_BVALID | 2 | 下游写响应有效。 |
| CONV_DMA.M_AXI_BREADY | 2 | 桥接受写响应；BVALID 与 BREADY 同时成立才结算事务。 |
| CONV_DMA.M_AXI_BRESP | 0 | AXI 写响应码；0 为 OKAY，2 为 SLVERR。 |
| CONV_DMA.fdma_wdone | 2 | 整笔 FDMA 写在最终 B 响应后完成的脉冲。 |
| CONV_DMA.fdma_werror | 0 | 最终写响应错误汇总；与 done 同看才能决定是否提交长度。 |

#### 图36 读回检验字节结果

DUT位置：TOP.u_pcie.design_1_wrapper_inst.design_1_i.CONV_DMA_0

对应测试点：P-15 奇数尾字0F使能（S-10、S-07）

用例关系：TC-M04 AXI奇数尾字保留高半。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：axi_tail，300～326 ns；0929原图41。

验证功能：直接检查部分写在存储器中的结果，补足只看WSTRB变化无法确认实际写掩码是否生效的问题。

图中关系：AR请求同一地址的单拍，RDATA/fdma_rdata为12345678_DEADBEEF；RVALID/RREADY接受且RLAST指出该唯一拍。

设计逻辑：高32bit来自第一次FF写，低32bit来自第二次0F写，读回组合必须同时保留两种不同模式。TB对完整64bit严格比较，因此高半被误清零、全拍被覆盖或低半未更新都会失败。

判断依据：三图一起支持P-15的桥加行为RAM按字节更新。ring另支持尾字长度+4，两个独立模块证据合起来解释方案，但没有同一份端到端DDR实物写掩码记录。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| CONV_DMA.fdma_raddr | 1 | FDMA 读事务的字节地址。 |
| CONV_DMA.fdma_rareq | 2 | FDMA 读请求；桥/存储侧接受后才进入数据阶段。 |
| CONV_DMA.M_AXI_ARADDR | 1 | AXI 读地址；用于核对高地址与跨 4KiB 拆分。 |
| CONV_DMA.M_AXI_ARLEN | 1 | AXI 读突发长度减一。 |
| CONV_DMA.M_AXI_ARVALID | 2 | 桥发出的读地址有效请求。 |
| CONV_DMA.M_AXI_ARREADY | 2 | 下游读地址接受能力。 |
| CONV_DMA.M_AXI_RDATA | 1 | AXI 返回的 64bit 数据；只有 RVALID/RREADY 握手才计拍。 |
| CONV_DMA.M_AXI_RLAST | 2 | 当前 AXI 读突发的最后一拍。 |
| CONV_DMA.M_AXI_RVALID | 2 | 下游当前读拍有效。 |
| CONV_DMA.M_AXI_RREADY | 2 | 桥当前可以接受读拍。 |
| CONV_DMA.fdma_rdata | 1 | 返回 FDMA 侧的 64bit 读数据。 |
| CONV_DMA.fdma_rvalid | 2 | 本桥历史接口的已接受读拍脉冲，须与 AXI RVALID/RREADY 区分。 |

## 7 寄存器

INFO_EXCH 把 AXI-Lite 访问转换成持久忙位、单拍命令及只读状态。本测试使用真实寄存器 RTL，但队头/丢字输入是固定测试值，done由测试台模拟。依据详细设计 §4.1、深度解析 §5。

### 7.1 只读状态

#### 图37 只读值来自指定输入

DUT位置：TOP.u_pcie.design_1_wrapper_inst.design_1_i.INFO_EXCH_0

对应测试点：P-01 版本与容量读回（S-01、S-32、S-33、S-34）；P-21 busy锁参、W1P及WSTRB（S-14、S-37、S-40、S-41、S-42）

用例关系：TC-M05 真实INFO_EXCH命令及只读值。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：regs，30～126 ns；0929原图21。

验证功能：验证寄存器地址译码，把固定版本/容量和外部状态输入正确返回给CPU。

图中关系：araddr依次选择0x00/04/08与0x30/34/38，slv_reg_rden之后rvalid给出对应值；后面三个状态分别为1/7/9，与RX_READY_BLOCKS/RX_HEAD_SEQ/RX_DROPPED_FRAMES固定输入一致。

设计逻辑：AR地址握手触发读译码，再在RVALID/RREADY时读取结果。版本、构建标识和BUF_LEN_MAX是常量，0x40000表示单个上行块容量而非下行32KiB长度；诊断寄存器只展示外部输入，不在INFO_EXCH里生成队列。

判断依据：P-01三项固定读回有图且TB严格比较，P-21只读输入映射也有局部支持。队头状态没有动态接ring、未读0x2C真实来源，因此P-33/34不能据静态1/7/9宣称覆盖。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| INFO_EXCH.S_AXI_ARADDR | 5 | 图中短名 araddr 对应此RTL端口。CPU AXI-Lite 读寄存器地址。 |
| INFO_EXCH.S_AXI_ARVALID | 12 | 图中短名 arvalid 对应此RTL端口。CPU 读地址有效。 |
| INFO_EXCH.S_AXI_ARREADY | 12 | 图中短名 arready 对应此RTL端口。寄存器从端读地址接受。 |
| INFO_EXCH.slv_reg_rden | 12 | AXI-Lite 读地址被采样后触发寄存器译码。 |
| INFO_EXCH.S_AXI_RDATA | 6 | 图中短名 rdata 对应此RTL端口。INFO_EXCH 的 S_AXI_RDATA：当前地址译码的32bit读回值；只在 S_AXI_RVALID 与 S_AXI_RREADY 同时有效时由总线接受。不是FDMA数据。 |
| INFO_EXCH.S_AXI_RVALID | 12 | 图中短名 rvalid 对应此RTL端口。INFO_EXCH 的 S_AXI_RVALID：读回值有效，遇 RREADY 低时须保持，不能当作FDMA返回。 |
| INFO_EXCH.S_AXI_RREADY | 0 | 图中短名 rready 对应此RTL端口。INFO_EXCH 的 S_AXI_RREADY：CPU/测试台接受寄存器读结果的条件。 |
| INFO_EXCH.RX_READY_BLOCKS | 0 | 测试台固定接入的队列数量，用于读寄存器译码检查。 |
| INFO_EXCH.RX_HEAD_SEQ | 0 | 测试台固定接入的队头序号，用于读寄存器译码检查。 |
| INFO_EXCH.RX_DROPPED_FRAMES | 0 | 测试台固定接入的丢字数，用于读寄存器译码检查。 |

### 7.2 一次启动

#### 图38 参数先锁再启动一次

DUT位置：TOP.u_pcie.design_1_wrapper_inst.design_1_i.INFO_EXCH_0

对应测试点：P-21 busy锁参、W1P及WSTRB（S-14、S-37、S-40、S-41、S-42）

用例关系：TC-M05 真实INFO_EXCH命令及只读值。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：regs，128～190 ns；0929原图22。

验证功能：验证CPU的一次启动写被转换成单拍start，同时留下持久busy给软件查询。

图中关系：0x24/0x28写地址/长度后，command_len变16；0x20写1使CPU_WR_DONE高，CPU_WR_DONE_pos/start只高一拍，starts加1，延迟位随后追上忙位。

设计逻辑：CPU_WR_DONE保持任务忙状态，CPU_WR_DONE_d保存上一拍，pos=当前bit0&&!延迟位把0→1转为一次启动。command_addr原本即0x8000，写相同值没有跳变但握手真实成立。只有忙位空闲时参数可更新。

判断依据：忙位持续而start不持续说明P-21一次启动成立；软件等待0x20为0再设置地址/长度、完成H2C、最后写1。这里start后没有真实adapter/DDR工作，不能确认H2C完成顺序或数据已送到子机。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| INFO_EXCH.S_AXI_AWADDR | 3 | 图中短名 awaddr 对应此RTL端口。CPU AXI-Lite 写寄存器地址。 |
| INFO_EXCH.S_AXI_WDATA | 3 | 图中短名 wdata 对应此RTL端口。CPU AXI-Lite 写数据。 |
| INFO_EXCH.S_AXI_WSTRB | 0 | 图中短名 wstrb 对应此RTL端口。CPU AXI-Lite 每字节写使能，bit0 决定 0x14 ACK 是否生效。 |
| INFO_EXCH.S_AXI_AWVALID | 6 | 图中短名 awvalid 对应此RTL端口。CPU AXI-Lite 写地址有效。 |
| INFO_EXCH.S_AXI_WVALID | 6 | 图中短名 wvalid 对应此RTL端口。CPU AXI-Lite 写数据有效。 |
| INFO_EXCH.S_AXI_AWREADY | 6 | 图中短名 awready 对应此RTL端口。寄存器从端写地址接受。 |
| INFO_EXCH.S_AXI_WREADY | 6 | 图中短名 wready 对应此RTL端口。寄存器从端写数据接受。 |
| INFO_EXCH.r_CPU_FPGA_START_ADDR | 0 | 图中短名 command_addr 对应此RTL端口。忙位未置起时允许锁存的 CPU 下行地址。 |
| INFO_EXCH.r_CPU_FPGA_LEN | 1 | 图中短名 command_len 对应此RTL端口。忙位未置起时允许锁存的 CPU 下行长度。 |
| INFO_EXCH.slv_reg_wren | 6 | AXI-Lite 写地址和数据均可接受的寄存器写条件。 |
| INFO_EXCH.CPU_WR_DONE | 1 | 0x20 提交后的忙/门铃保持位，直到 CPU_WR_DONE_EVENT 事件清零。 |
| INFO_EXCH.CPU_WR_DONE_d | 1 | 忙位延迟一拍，用于边沿检测。 |
| INFO_EXCH.CPU_WR_DONE_pos | 2 | 忙位 0→1 时的一拍上升沿脉冲。 |
| INFO_EXCH.r_RD_START | 2 | 图中短名 start 对应此RTL端口。CPU_WR_DONE 上升沿转换出的单拍下行启动脉冲。 |
| 测试激励/统计：starts | 1 | 测试台已看到的 r_RD_START 脉冲次数。 |

### 7.3 忙时锁参

#### 图39 总线受理不等于改参数

DUT位置：TOP.u_pcie.design_1_wrapper_inst.design_1_i.INFO_EXCH_0

对应测试点：P-21 busy锁参、W1P及WSTRB（S-14、S-37、S-40、S-41、S-42）

用例关系：TC-M05 真实INFO_EXCH命令及只读值。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：regs，194～270 ns；0929原图23。

验证功能：验证任务忙时CPU重复提交不会重启，修改命令寄存器也不会改变在途任务使用的参数。

图中关系：S_AXI_AWVALID/S_AXI_WVALID、ready和slv_reg_wren说明重复写实际被受理，但CPU_WR_DONE没有新的上升沿，r_RD_START/starts不变；尝试0x9000/32后读回仍0x8000/16。

设计逻辑：AXI-Lite写响应处理与业务条件分开。!CPU_WR_DONE[0]门控地址/长度更新，忙位已高时pos不再出现。总线B响应表示寄存器访问已结束，不承诺请求变成一个排队任务。

判断依据：“写握手存在而参数不变”排除未送达造成的假保持，直接支持P-21的忙时锁参。软件不能靠连续写0x20=1积压批次，也不应在busy期间重用本批DDR数据。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| INFO_EXCH.S_AXI_AWADDR | 2 | 图中短名 awaddr 对应此RTL端口。CPU AXI-Lite 写寄存器地址。 |
| INFO_EXCH.S_AXI_WDATA | 2 | 图中短名 wdata 对应此RTL端口。CPU AXI-Lite 写数据。 |
| INFO_EXCH.S_AXI_AWVALID | 6 | 图中短名 awvalid 对应此RTL端口。CPU AXI-Lite 写地址有效。 |
| INFO_EXCH.S_AXI_WVALID | 6 | 图中短名 wvalid 对应此RTL端口。CPU AXI-Lite 写数据有效。 |
| INFO_EXCH.S_AXI_AWREADY | 6 | 图中短名 awready 对应此RTL端口。寄存器从端写地址接受。 |
| INFO_EXCH.S_AXI_WREADY | 6 | 图中短名 wready 对应此RTL端口。寄存器从端写数据接受。 |
| INFO_EXCH.slv_reg_wren | 6 | AXI-Lite 写地址和数据均可接受的寄存器写条件。 |
| INFO_EXCH.CPU_WR_DONE | 0 | 0x20 提交后的忙/门铃保持位，直到 CPU_WR_DONE_EVENT 事件清零。 |
| INFO_EXCH.CPU_WR_DONE_pos | 0 | 忙位 0→1 时的一拍上升沿脉冲。 |
| INFO_EXCH.r_RD_START | 0 | 图中短名 start 对应此RTL端口。CPU_WR_DONE 上升沿转换出的单拍下行启动脉冲。 |
| 测试激励/统计：starts | 0 | 测试台已看到的 r_RD_START 脉冲次数。 |
| INFO_EXCH.r_CPU_FPGA_START_ADDR | 0 | 图中短名 command_addr 对应此RTL端口。忙位未置起时允许锁存的 CPU 下行地址。 |
| INFO_EXCH.r_CPU_FPGA_LEN | 0 | 图中短名 command_len 对应此RTL端口。忙位未置起时允许锁存的 CPU 下行长度。 |
| INFO_EXCH.S_AXI_ARADDR | 2 | 图中短名 araddr 对应此RTL端口。CPU AXI-Lite 读寄存器地址。 |
| INFO_EXCH.S_AXI_RDATA | 2 | 图中短名 rdata 对应此RTL端口。INFO_EXCH 的 S_AXI_RDATA：当前地址译码的32bit读回值；只在 S_AXI_RVALID 与 S_AXI_RREADY 同时有效时由总线接受。不是FDMA数据。 |
| INFO_EXCH.S_AXI_RVALID | 4 | 图中短名 rvalid 对应此RTL端口。INFO_EXCH 的 S_AXI_RVALID：读回值有效，遇 RREADY 低时须保持，不能当作FDMA返回。 |

### 7.4 完成后再启

#### 图40 结束后重新允许启动

DUT位置：TOP.u_pcie.design_1_wrapper_inst.design_1_i.INFO_EXCH_0

对应测试点：P-21 busy锁参、W1P及WSTRB（S-14、S-37、S-40、S-41、S-42）；P-23 逻辑复位与断链恢复（S-15、S-21、S-24）

用例关系：TC-M05 真实INFO_EXCH命令及只读值。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：regs，272～314 ns；0929原图24。

验证功能：验证忙时保护可以解除，任务结束后允许下一次正常提交，而不会永久只响应第一次启动。

图中关系：测试台done使CPU_WR_DONE及延迟位依次回0；随后新的0x20=1再次产生pos/r_RD_START，starts由1到2，读回忙位与这次任务一致。

设计逻辑：done映射内部CPU_WR_DONE_EVENT，优先清持久忙位；清零使下一次0→1可被边沿检测。当前工程完成、拒绝或断链都可能产生结束事件，0x20清零本身不提供子机执行成功或上行读完信息。

判断依据：P-21复用命令生命周期有正反对照；P-23仅获得寄存器端“结束后可再启”的局部证据。done在本组直接驱动，不能证明真实任务中断会正确生成结束事件。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| INFO_EXCH.CPU_WR_DONE_EVENT | 2 | 图中短名 done 对应此RTL端口。CPU_WR_DONE_EVENT 输入，本图由测试台模拟任务结束，使0x20忙位清零；未连接真实业务完成链。 |
| INFO_EXCH.CPU_WR_DONE | 2 | 0x20 提交后的忙/门铃保持位，直到 CPU_WR_DONE_EVENT 事件清零。 |
| INFO_EXCH.CPU_WR_DONE_d | 2 | 忙位延迟一拍，用于边沿检测。 |
| INFO_EXCH.CPU_WR_DONE_pos | 2 | 忙位 0→1 时的一拍上升沿脉冲。 |
| INFO_EXCH.r_RD_START | 2 | 图中短名 start 对应此RTL端口。CPU_WR_DONE 上升沿转换出的单拍下行启动脉冲。 |
| 测试激励/统计：starts | 1 | 测试台已看到的 r_RD_START 脉冲次数。 |
| INFO_EXCH.S_AXI_ARADDR | 1 | 图中短名 araddr 对应此RTL端口。CPU AXI-Lite 读寄存器地址。 |
| INFO_EXCH.S_AXI_RDATA | 1 | 图中短名 rdata 对应此RTL端口。INFO_EXCH 的 S_AXI_RDATA：当前地址译码的32bit读回值；只在 S_AXI_RVALID 与 S_AXI_RREADY 同时有效时由总线接受。不是FDMA数据。 |
| INFO_EXCH.S_AXI_AWADDR | 1 | 图中短名 awaddr 对应此RTL端口。CPU AXI-Lite 写寄存器地址。 |
| INFO_EXCH.S_AXI_WDATA | 1 | 图中短名 wdata 对应此RTL端口。CPU AXI-Lite 写数据。 |
| INFO_EXCH.slv_reg_wren | 2 | AXI-Lite 写地址和数据均可接受的寄存器写条件。 |

### 7.5 读完确认

#### 图41 写一形成单拍确认

DUT位置：TOP.u_pcie.design_1_wrapper_inst.design_1_i.INFO_EXCH_0

对应测试点：P-17 每次确认只释放一块（S-11、S-14、S-37、S-44、S-45）；P-21 busy锁参、W1P及WSTRB（S-14、S-37、S-40、S-41、S-42）

用例关系：TC-M05 真实INFO_EXCH命令及只读值。此图来自历史模块运行；表单关联的F/R整链用例不能因该图自动视作覆盖。

定位：regs，330～406 ns；0929原图25。

验证功能：验证0x14是一次性读完确认命令，每次有效写最多输出一拍；最低字节未授权时不能释放数据块。

图中关系：两次0x14写1且byte0有效使CPU_REC_STATE/ack各出现一拍，acks加到2；第三次WSTRB=E仍有写握手和B响应，却不出现第三个ack。

设计逻辑：确认条件同时含地址命中、slv_reg_wren、WDATA[0]和WSTRB[0]。寄存器下一拍自动回0，不依赖软件再写0；输出经adapter接writer.cpu_ack，writer只在队列非空时归还一个槽。每取完一块写一次，多写可能归还下一块。

判断依据：P-17的脉冲源与P-21的WSTRB门控有真实正反例；ring逐块图另测接收端行为。两个测试未把真实0x14、五个块与C2H一起例化，P-33/TC-F12仍未执行。

| DUT信号原名 | 跳变 | 设计含义与读法 |
| --- | ---: | --- |
| INFO_EXCH.S_AXI_AWADDR | 1 | 图中短名 awaddr 对应此RTL端口。CPU AXI-Lite 写寄存器地址。 |
| INFO_EXCH.S_AXI_WDATA | 0 | 图中短名 wdata 对应此RTL端口。CPU AXI-Lite 写数据。 |
| INFO_EXCH.S_AXI_WSTRB | 1 | 图中短名 wstrb 对应此RTL端口。CPU AXI-Lite 每字节写使能，bit0 决定 0x14 ACK 是否生效。 |
| INFO_EXCH.S_AXI_AWVALID | 6 | 图中短名 awvalid 对应此RTL端口。CPU AXI-Lite 写地址有效。 |
| INFO_EXCH.S_AXI_WVALID | 6 | 图中短名 wvalid 对应此RTL端口。CPU AXI-Lite 写数据有效。 |
| INFO_EXCH.S_AXI_AWREADY | 6 | 图中短名 awready 对应此RTL端口。寄存器从端写地址接受。 |
| INFO_EXCH.S_AXI_WREADY | 6 | 图中短名 wready 对应此RTL端口。寄存器从端写数据接受。 |
| INFO_EXCH.slv_reg_wren | 6 | AXI-Lite 写地址和数据均可接受的寄存器写条件。 |
| INFO_EXCH.S_AXI_BVALID | 6 | 图中短名 bvalid 对应此RTL端口。INFO_EXCH 的 S_AXI_BVALID：寄存器写响应有效；总线写已结束不等于下行业务完成。 |
| INFO_EXCH.r_CPU_REC_STATE | 4 | 图中短名 ack 对应此RTL端口。寄存器模块导出的单拍 CPU 接收确认。 |
| 测试激励/统计：acks | 2 | 测试台已看到的 ACK 脉冲次数。 |
| INFO_EXCH.CPU_REC_STATE | 4 | 0x14 写 1 且 WSTRB[0] 有效时形成的单拍 ACK 源。 |

## 8 待补与来源

### 8.1 测试点索引

| 测试点 | 规格/用例 | 本稿图支持 | 分析与待补 |
| --- | --- | --- | --- |
| P-01；版本与容量读回 | S-01、S-32、S-33、S-34；TC-F01、TC-M05 | 模块有图；图37 | 版本、时间标识和单块容量三项读回有图；当前日志TC-M05另见核查报告。 |
| P-02；非法命令拒绝 | S-02、S-14；TC-F02、TC-F10 | 无对应图；— | 缺adapter非法命令图；旧快速模型只测一类非法地址，完整边界TC-F10未执行。 |
| P-03；单帧16 Byte | S-03、S-04；TC-F03、TC-M07、TC-R01 | 部分支持；图01 | 仅TX两拍成帧；不含H2C、0x8000窗口和adapter整链。 |
| P-04；Byte1帧首取样 | S-19、S-05；TC-F03、TC-F08、TC-F09 | 无对应图；— | 七组未例化adapter首拍提取；配置输入图不能替代Byte1取样检查。 |
| P-05；1KiB与32KiB批量 | S-02、S-04；TC-F04、TC-F05、TC-F10 | 无对应图；— | 300帧TX不等于1KiB/32KiB业务批量；当前fast日志另有结果。 |
| P-06；FDMA/LocalLink反压 | S-04、S-16；TC-F04、TC-F05、TC-M07 | 部分支持；图01、图02、图03 | TX停顿保持和近满有图；完整DDR返回/业务批量反压链仍未配图。 |
| P-07；十组合法参数 | S-05、S-20、S-06；TC-M01、TC-F09 | 历史参考；图05、图06 | 编号1参数有图、十组旧TB有比较；现行四拍检查仅有10月10日日志。 |
| P-08；非法和重复配置 | S-05；TC-M01、TC-F09 | 历史参考；图04、图05 | 非法过滤和一次锁定原理；重复配置全程在旧TB，现行模块日志另见TC-M01。 |
| P-09；四拍帧、节拍与反压恢复 | S-06、S-21、S-22；TC-M01 | 历史格式；图06、图07、图08、图09 | 两拍6Byte/2.016µs旧图不覆盖四拍16Byte、F0、2µs源事件或现行起帧条件。 |
| P-10；低32bit字拼接 | S-07；TC-M02、TC-F06、TC-F07 | 模块有图；图14、图15 | 随机高半被排除，先后低字正确拼拍，成功长度按字数×4。 |
| P-11；FIFO满与恢复 | S-08、S-12；TC-M06 | 缩容有图；图10、图11、图12、图13 | 深度16的满丢弃/有序恢复；生产2048阈值不由此验证。 |
| P-12；三轮地址回绕 | S-09、S-07、S-11；TC-M02、TC-F07 | 模块有图；图21、图22 | 图示回绕边界，24块三轮及数据全程靠TB比较。 |
| P-13；八块满不覆盖 | S-09、S-12；TC-M02 | 模块有图；图23、图24 | 八块满后丢新字、旧块逐一归还；TB逐字查旧数据。 |
| P-14；延迟及错误B响应 | S-10、S-26；TC-M02、TC-M03、TC-M09 | 缩时有图；图14、图16、图17、图18、图19、图33 | FDMA成功才计长，跨缩时边界等待B，失败与恢复；不覆盖真实DDR超时。 |
| P-15；奇数尾字0F使能 | S-10、S-07；TC-M02、TC-M04、TC-M09 | 模块有图；图15、图34、图35、图36 | writer尾长+4及独立CONV_DMA+字节RAM高半保留；不是同一份集成VCD。 |
| P-16；读清通知不释放块 | S-11、S-36；TC-F06、TC-F12 | 无对应图；— | ring同时驱动ack/irq_clear，regs未读0x10，不能证明真实读清不释放；TC-F12待补。 |
| P-17；每次确认只释放一块 | S-11、S-14、S-37、S-44、S-45；TC-M05、TC-F12 | 部分支持；图20、图24、图41 | 源端W1P与队列端每次pop1分别有图；真实五块读取整链TC-F12未执行。 |
| P-18；丢字饱和边界 | S-12、S-46；待补：尚无用例 | 无对应图；— | 没有接近FFFFFFFF的丢字计数，饱和边界仍待专项。 |
| P-19；AXI独立通道 | S-13、S-10；TC-M03 | 模块有图；图25、图26、图33、图32 | 独立通道、等待响应及读拍接受；完整保持靠AW/W_HOLD断言。 |
| P-20；低地址无别名与4KiB拆分 | S-13、S-09、S-27；TC-M03 | 模块有图；图27、图28、图29、图30、图31、图32 | 低4MiB不同块基址无别名及520拍拆分；不涉及>4GiB卡端扩展。 |
| P-21；busy锁参、W1P及WSTRB | S-14、S-37、S-40、S-41、S-42；TC-M05 | 模块有图；图37、图38、图39、图40、图41 | 真实INFO_EXCH忙时锁参、单拍命令与WSTRB；结束及诊断输入由TB代替。 |
| P-22；TX深度512阈值504 | S-16、S-04；TC-M07 | 模块有图；图02、图03 | 512/504阈值实际命中；300帧完整性由TB验600拍。 |
| P-23；逻辑复位与断链恢复 | S-15、S-21、S-24；TC-M01、TC-M08、TC-F11 | 部分历史；图09、图07、图40 | 1G配置保留及局部寄存器恢复；当前DDR/PCIe/10G整任务恢复TC-F11待补。 |
| P-24；Root Port路径 | S-03、S-04、S-11；TC-R01 | 无对应图；— | 七组没有Root Port/XDMA；9月23日历史16Byte功能结果见核查报告，当前未重跑。 |
| P-25；真实100ms周期 | S-25、S-10、S-09；TC-M09 | 只有机制图；图16、图17、图15 | 仅PERIOD_CYCLES=200的收尾先后；生产100ms/连续3周期TC-M09未执行。 |
| P-27；真实DDR/PCIe/Aurora与GPIO | S-26、S-27、S-28、S-23；待补：尚无用例 | 无对应图；— | 真实DDR校准、GT、PCIe与GPIO测量缺板级记录。 |
| P-28；2µs事件计数 | S-22、S-24；TC-M08 | 无对应图；— | 没有RTDS_SYNC_TIMEBASE的500拍事件图；当前TC-M08日志通过，wave_count=0。 |
| P-29；GPIO周期及相位 | S-23、S-24；TC-M08 | 无对应图；— | 没有50µs GPIO相位图；当前TC-M08日志验证25事件/周期，不能用旧1G tick代替。 |
| P-30；实际adapter到实际1G | S-19、S-05、S-20、S-06；TC-F09 | 无对应图；— | 实际adapter到实际1G、首拍解析再四拍输出TC-F09未执行。 |
| P-31；最小、最大及窗口末端 | S-02、S-04；TC-F10 | 无对应图；— | 完整最小/最大/窗口末端合法与非法组TC-F10未执行。 |
| P-32；DDR/链路未就绪与恢复 | S-15、S-26；TC-F11 | 无对应图；— | DDR/链路未就绪、中断、恢复与旧事件隔离TC-F11未执行。 |
| P-33；真实INFO_EXCH五块逐读 | S-11、S-36、S-37、S-38、S-39、S-44、S-45；TC-F12 | 无对应图；— | 真实INFO_EXCH五块C2H逐读确认TC-F12未执行；八次TB ACK不能替代。 |
| P-34；DDR状态位真实映射 | S-26、S-43；TC-F11 | 无对应图；— | 0x2C真实来源、清错/校准保持TC-F11未执行；常量诊断不构成证据。 |
| P-35；温度码及busy读回 | S-30、S-35；待补：尚无用例 | 无对应图；— | TEMP_RD/SYSMON温度和busy动态读回未配图，无对应用例。 |
| P-36；LED指示 | S-31；待补：尚无用例 | 无对应图；— | LED复位及生产计数未配图，无对应用例。 |

### 8.2 优先补图

TC-F09：实际adapter→实际1G，覆盖首拍Byte1、十组参数、重复锁定及四拍载荷；旧1G图无法替代。 当前表状态：未执行｜截至2026-10-10｜计划验证层级：行为模型集成（实际模块）。
TC-F10：完整下行长度、对齐、窗口起止边界；已有TX图只证明发送桥部分。 当前表状态：未执行｜截至2026-10-10｜计划验证层级：行为模型集成（实际模块）。
TC-F11：未就绪/中断/恢复与0x2C真实状态来源；现有注错仅在模块响应边界。 当前表状态：未执行｜截至2026-10-10｜计划验证层级：行为模型集成（实际模块）。
TC-F12：真实寄存器五块C2H逐读与一次确认；把regs W1P和ring pop真正接起来，同时隔离0x10读清。 当前表状态：未执行｜截至2026-10-10｜计划验证层级：行为模型集成（实际模块）。
TC-M09：生产100ms、不缩时连续周期及B/奇尾完成后的可读边界。 当前表状态：未执行｜截至2026-10-10｜计划验证层级：模块测试（生产参数）。

### 8.3 资料来源

F:\RTDS_test_DDR4_64bit_batch_dev\evidence\local_wave_sessions\WCFG_ring_axi_regs_观察链与时间刻度_配图_20260928_remote_20260929.docx
F:\RTDS_test_DDR4_64bit_batch_dev\evidence\local_wave_sessions\word_wave_captures\manifest.json
E:\PCIE-CPU\outputs\RTDS_spec_test_refined_20261010\RTDS_设计规格_测试点_测试用例_精炼版_20261010.xlsx
E:\PCIE-CPU\outputs\RTDS_spec_test_refined_20261010\RTDS_规格与测试文档核查报告_20261010.docx
E:\codex_history_md\PCIE-CPU\2026-10-10_13-59_规划PCIE-CPU测试文档精简版.md
E:\PCIE-CPU\outputs\RTDS_spec_test_refined_20261010\_sources\documents\RTDS_主机FPGA_PCIe_DDR4_Aurora_详细设计方案_V1.0_20261002.docx
E:\PCIE-CPU\outputs\RTDS_spec_test_refined_20261010\_sources\documents\RTDS_设计方案_时序_CDC与软硬件协同深度解析_V1.0_20261008.docx
E:\PCIE-CPU\outputs\RTDS_spec_test_refined_20261010\_sources\documents\CPU-FPGA_PCIe寄存器表单_软件指导手册_V2.0.docx
