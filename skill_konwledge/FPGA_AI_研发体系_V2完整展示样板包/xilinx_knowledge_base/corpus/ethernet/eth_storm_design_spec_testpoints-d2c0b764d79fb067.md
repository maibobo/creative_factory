# eth_storm_design_spec_testpoints

- Category: `ethernet`
- Source: `E:\eth_storm_project\eth_storm_design_spec_testpoints.docx`
- SHA-256: `d2c0b764d79fb067a8548fb124178d9b1b850dcee27ffd9191aa3e81d21dcc1d`
- Extractor: `python-docx+zip-structure-check`
- Tags: `dma, ethernet, rgmii, storm-filter`
- Duplicate sources:
  - none

RGMII 以太网风暴过滤模块
设计规格与分解测试点

基于上传 Verilog 源码整理：crc32_d8 / rgmii_to_gmii / eth_storm_* / rgmii_eth_storm_filter_top

文档目标：用简明规格说明设计行为，并拆解可执行验证点。

# 1. 设计规格概览

| 项目 | 规格摘要 |

| 设计目标 | 从 RGMII/GMII 接收以太网帧，完成基础合法性检查、可配置过滤、风暴抑制、CRC 去重，并将通过帧按 EtherType 输出到 GOOSE / SV / Other 三路 FIFO。 |

| 时钟/复位 | RGMII 接收时钟经 clk_wiz 与 BUFG/IDDR 转为 gmii_rx_clk；本地输出侧使用 clk_125m。sys_rst 或 RGMII 时钟未锁定时复位。 |

| 帧识别 | 接收端要求连续 7 个 0x55 前导码后跟 0xD5 SFD 才进入帧接收；接收期间解析目的 MAC、源 MAC、VLAN TPID/TCI、EtherType。 |

| 帧存储 | 4 字节 hold path 用于剥离 FCS；识别 VLAN TPID=0x8100 时，写入 FIFO 时剥离 VLAN TPID/TCI；描述符长度为实际写入数据长度。 |

| 过滤能力 | 支持目的 MAC、本机 MAC、广播、可编程组播 Hash、源 MAC 4 项白名单、源 MAC 4 项黑名单、CRC 重复帧、帧数风暴、字节风暴、CRC/FCS 检查、长度/FIFO 满检查。 |

| 输出与统计 | 输出三路 data/desc FIFO 接口；提供接收侧丢弃事件、按原因计数、窗口帧/字节统计、风暴状态，以及路由侧二级 FIFO 拥塞丢弃统计。 |


# 2. 模块划分与职责

| 模块 | 职责 | 关键验证关注点 |

| rgmii_eth_storm_filter_top | 顶层封装：RGMII 接收、时钟锁定复位、GMII 过滤核心连接。 | 复位锁定、端口贯通、配置与统计信号一致性。 |

| rgmii_to_gmii | 用 IDDR 将 4bit DDR RGMII 数据/控制转换为 8bit GMII；gmii_rxer = 负沿控制 ^ 正沿 dv。 | 字节拼接顺序、rxer 译码、复位。 |

| eth_storm_filter | 核心集成：main_fsm、stat、crc_clean、tx_fsm。 | 子模块连接、参数派生、跨模块握手。 |

| eth_storm_main_fsm | 接收、解析、FCS/长度/FIFO 错误捕获、ACL/目的 MAC/风暴/去重判决、描述符生成。 | 状态机流程、丢弃优先级、VLAN/FCS 剥离。 |

| eth_storm_stat | 统计窗口、epoch、时间戳、通过/丢弃计数和 drop_valid/drop_reason。 | 窗口翻转、清零优先级、同周期 commit。 |

| eth_storm_crc_clean | CRC 去重 RAM 初始化与窗口翻转后台清理；正常读写优先于清理。 | 初始化完成、epoch 清理、pause 请求。 |

| eth_storm_multicast_hash | 64bit 组播 Hash 表；cfg_multicast_mac_valid 上升沿写入，clear 优先。 | CRC Hash 索引、连续配置、clear 优先级。 |

| eth_storm_tx_fsm / type_router | 一级 common FIFO 缓冲；按 EtherType 路由到 GOOSE/SV/Other；二级拥塞时静默丢弃并计数。 | 数据先写完再提交描述符、拥塞不阻塞其他类型。 |

| crc32_d8 | 8bit 并行 CRC32 更新模块，供 FCS 与 Hash 使用。 | 初始化、使能、标准 CRC 残值。 |


# 3. 关键接口与数据格式

| 类别 | 信号/字段 | 说明 |

| 配置 | cfg_filter_en | 总过滤使能；关闭时目的 MAC、ACL、风暴、重复 CRC 过滤不生效，但 CRC/FIFO/长度类基础错误仍按代码路径处理。 |

| 配置 | cfg_dst_mac_en / cfg_local_mac / cfg_allow_broadcast / cfg_allow_multicast | 目的 MAC 匹配控制；组播需命中 64bit Hash 表。 |

| 配置 | cfg_whitelist_en / cfg_blacklist_en + white0..3 / black0..3 | 源 MAC 白名单/黑名单，各固定 4 项；黑名单判决优先于白名单未命中。 |

| 配置 | cfg_dup_crc_en / CRC_TABLE_DEPTH | CRC 去重表默认 1024 项；表项格式 {valid, epoch, crc[31:0]}。 |

| 配置 | cfg_frame_max_per_win / cfg_byte_max_per_win / cfg_window_ms | 阈值或窗口为 0 时使用参数默认值；窗口单位 ms。 |

| 描述符 | {pass[52], len[51:36], mac_class[35:34], eth_type_class[33:32], time[31:0]} | pass 表示接收侧判决通过；len 为写入 FIFO 的帧数据长度；time 来自 frame_time_cnt_g。 |

| mac_class | 0/1/2/3 | 0=Unicast，1=Broadcast，2=Multicast，3=Reserved。 |

| eth_type_class | 0/1/2/3 | 0=Other，1=GOOSE，2=SV，3=Reserved；GOOSE/SV EtherType 由 cfg_eth_type_goose / cfg_eth_type_sv 配置。 |


# 4. 接收与判决流程

| 步骤 | 行为 | 输出/状态 |

| 前导码检查 | W_IDLE/W_PREAMBLE 等待 7×0x55 + 0xD5；不满足则保持/回退，不进入有效接收。 | 有效 SFD 触发 FCS CRC 初始化。 |

| 帧接收 | W_RECV 按 GMII 字节解析 DA/SA/EtherType；4 字节 hold path 延迟释放数据以剥离 FCS。 | 写 common frame FIFO；记录 rxer、长度、FIFO 满。 |

| 异常接收 | 若接收过程中 FIFO 满或长度越界，进入 W_DISCARD_RECV，继续解析并丢弃后续数据。 | 避免半帧阻塞；最终生成丢弃描述符。 |

| ACL/目的匹配 | W_ACL_CHK 计算白/黑名单命中、目的 MAC 命中、MAC 类别、EtherType 类别。 | 输出给判决逻辑。 |

| CRC 去重读 | W_CRC_RD/W_CRC_CHK 读取去重表，判断 same epoch 且 CRC/FCS 一致。 | 重复命中可产生 DROP_DUP_CRC。 |

| 最终判决 | W_DECIDE 按固定优先级产生 pass 或 drop_reason，并计算窗口计数/风暴状态。 | 锁存 dec_pass_q 与 dec_drop_reason_q。 |

| 提交描述符 | W_COMMIT 等待 desc FIFO 非满后写描述符；通过帧同时写 CRC 去重表。 | commit_can_push 驱动统计。 |


# 5. 丢弃原因与判决优先级

| 优先级 | 原因位 | 编码 | 触发条件摘要 |

| 1 | DROP_CRC_ERR | 0x0001 | rxer、短帧导致 dec_crc_ok=0，或 cfg_crc_check_en=1 且 FCS CRC 残值不匹配。 |

| 2 | DROP_DST_MISS | 0x0100 | 目的 MAC 过滤开启且本机/广播/组播 Hash 均未命中。 |

| 3 | DROP_BLACKLIST | 0x0040 | 黑名单开启且源 MAC 命中任一黑名单项。 |

| 4 | DROP_NOT_WHITE | 0x0080 | 白名单开启且源 MAC 未命中任一白名单项。 |

| 5 | DROP_BUF_FULL | 0x0010 | 接收过程中 common data FIFO 或 desc FIFO 满。 |

| 6 | DROP_LEN_ERR | 0x0020 | 长度超过配置/参数最大值，或其他长度错误。 |

| 7 | DROP_FRAME_STORM | 0x0004 | 窗口内帧数超过 cfg_frame_max_per_win/默认阈值。 |

| 8 | DROP_BYTE_STORM | 0x0008 | 窗口内字节数超过 cfg_byte_max_per_win/默认阈值。 |

| 9 | DROP_DUP_CRC | 0x0002 | 去重开启、表初始化完成，且同 epoch 表项 valid 与 CRC/FCS 匹配。 |

| 通过 | DROP_NONE | 0x0000 | 以上条件均不满足，写入输出路径并统计 pass。 |


# 6. 分解测试点

| ID | 测试主题 | 用例拆分 | 期望结果 |

| T00 | 静态/集成检查 | 语法编译；外部 IP/模块 stub：clk_wiz、FIFO、CRC RAM、BUFG/IDDR；参数 CRC_TABLE_DEPTH 与 CRC_IDX_W。 | 无端口遗漏/位宽错误；可综合依赖明确；参数派生正确。 |

| T01 | RGMII→GMII | DDR 上/下沿 nibble 组合；rxdv 正/负沿组合；rst_p 拉高复位。 | gmii_rxd[3:0]/[7:4] 顺序正确；gmii_rxer = gmii_rxer_r ^ gmii_rxdv。 |

| T02 | 复位与统计清零 | sys_rst、clk_wiz unlocked、cfg_clear_stats 单周期/多周期；清零与窗口翻转同周期。 | 状态机回 idle；统计清零优先；时间戳计数器不被 cfg_clear_stats 清零。 |

| T03 | 前导码/SFD | 标准 7×55+D5；不足 7 个 55；错误 SFD；前导码中断。 | 仅标准序列进入 W_RECV；异常不产生有效通过帧。 |

| T04 | 基础通过路径 | 过滤关闭/开启但均匹配；合法最小/普通帧；背靠背帧。 | pass=1；数据 FIFO 不含前导码/SFD/FCS；desc len 与写入字节数一致。 |

| T05 | CRC/FCS 检查 | cfg_crc_check_en=0/1；正确 FCS；错误 FCS；gmii_rxer 置位。 | 开启时错误 FCS 丢弃；rxer 触发 DROP_CRC_ERR；关闭 FCS 检查时仍需关注 rxer/短帧。 |

| T06 | 长度边界 | <60、=60、=MAX、>MAX；cfg_max_frame_bytes=0；VLAN 帧 MAX+4 输入。 | 短帧按优先级进 DROP_CRC_ERR；超长进 DROP_LEN_ERR；VLAN 剥离后 desc len 正确。 |

| T07 | 目的 MAC 过滤 | 本机 MAC；广播 allow 开/关；组播 Hash hit/miss；cfg_dst_mac_en 关。 | 命中通过；未命中 DROP_DST_MISS；关闭目的过滤时不因目的 MAC 丢弃。 |

| T08 | 组播 Hash 配置 | cfg_multicast_hash_clear；valid 上升沿写入；连续写多个 MAC；配置期间查询。 | clear 优先清零；crc_result[31:26] 对应 bit 被置位；已有 bit 保留。 |

| T09 | 源 MAC ACL | 白名单命中/未命中；黑名单命中/未命中；黑白同时开启且同一 MAC 同时命中。 | 黑名单优先 DROP_BLACKLIST；白名单未命中 DROP_NOT_WHITE；关闭对应使能后不生效。 |

| T10 | CRC 去重 | 初始化期间收帧；首次帧写表；同 epoch 重复帧；窗口翻转后旧 epoch；后台清理被主访问 pause。 | init_done 前不判重；首次通过、重复丢弃；旧 epoch 不误杀；正常读写优先于清理。 |

| T11 | 风暴窗口 | cfg_window_ms=0/非0；帧数阈值=0/小阈值；字节阈值=0/小阈值；窗口边界提交。 | 超过阈值置 DROP_FRAME_STORM/DROP_BYTE_STORM；窗口翻转清空当前窗口并翻转 epoch。 |

| T12 | 判决优先级 | 人为叠加 CRC 错+黑名单、目的 miss+黑名单、风暴+重复、FIFO 满+超长等组合。 | drop_reason 始终符合第 5 节优先级；每帧只输出一个主原因编码。 |

| T13 | 一级 FIFO 满处理 | 接收前 desc/data FIFO 满；接收中变满；desc_fifo_full 阻塞 commit。 | 进入丢弃/等待路径；DROP_BUF_FULL 计数；不会写入半帧造成错位。 |

| T14 | 描述符格式 | 不同 MAC 类、EtherType 类、VLAN/非 VLAN、pass/drop。 | desc bit[52:0] 字段与规格一致；GOOSE/SV/Other 分类正确；time 单调增加。 |

| T15 | 二级路由 | GOOSE/SV/Other 三类；接收侧 drop 描述符；零长度描述符。 | 通过帧写对应通道；接收侧 drop 仅 drain common FIFO；零长度不写通道 FIFO。 |

| T16 | 二级拥塞策略 | 目标 data_full、prog_full、desc_full；单一通道拥塞时其他通道有流量。 | 拥塞帧静默丢弃且 route_drop_* 计数；不等待拥塞解除；其他通道不被长期阻塞。 |

| T17 | 统计输出 | 通过、各类丢弃、route drop、cfg_clear_stats；drop_valid 脉冲宽度。 | 各计数器增量准确；drop_valid 单周期；stat_last_drop_reason 保存最后原因。 |

| T18 | 顶层贯通 | RGMII 输入到三路 FIFO 输出；clk_wiz locked 抖动；所有配置端口扫描。 | 复位/锁定行为正确；端到端帧内容、描述符和统计一致。 |


# 7. 回归建议

| 层级 | 建议内容 |

| 单元级 | crc32_d8、multicast_hash、crc_clean、stat、type_router 各自独立 testbench，优先覆盖边界与优先级。 |

| 核心级 | eth_storm_filter 使用 GMII 帧生成器、CRC/FCS 生成器、FIFO stub，覆盖过滤矩阵和统计矩阵。 |

| 顶层级 | rgmii_eth_storm_filter_top 使用 RGMII DDR 激励做端到端冒烟，验证时钟锁定、复位、接口贯通。 |

| 覆盖率 | 覆盖状态机状态/跳转、drop_reason 全 bit、MAC/EtherType class、VLAN/非 VLAN、窗口 rollover、FIFO 拥塞。 |

| 断言 | 数据先于描述符提交；drop 帧不写二级 FIFO；desc len 等于实际写入字节；route 拥塞不等待；统计只在 commit 时更新。 |


设计假设/待确认：

二级 data FIFO 的 prog_full 阈值需预留至少一个最大帧长度空间，否则 R_COPY 期间可能因 target_data_full 防护而停顿。

外部 FIFO、CRC RAM、clk_wiz 以及 FPGA 原语未包含在上传文件中，集成仿真需提供模型或 IP。

短帧会使 dec_crc_ok=0，因此按当前优先级先记为 DROP_CRC_ERR，而不是 DROP_LEN_ERR；测试预期需与此实现保持一致。
