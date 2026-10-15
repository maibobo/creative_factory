# eth_storm_verification_testpoint_case_mapping

- Category: `ethernet`
- Source: `E:\eth_storm_project\eth_storm_verification_testpoint_case_mapping.xlsx`
- SHA-256: `3b2c3ff56e8cebb51782927e2df9288d5a5c066fe1cce6ba5593cc385f6ae5c9`
- Extractor: `artifact-tool`
- Tags: `dma, ethernet, rgmii, storm-filter, testpoints, verification`
- Duplicate sources:
  - none

# Workbook (6 sheets)

## Sheet: 总览

### Range: 总览!A1:D15
| 以太网风暴过滤模块验证测试点—用例映射与归并建议 |  |  |  |
| 生成日期 | 2026-07-06 |  |  |
| 适用范围 | 基于上传RTL：rgmii_eth_storm_filter_top、eth_storm_filter、main_fsm、stat、crc_clean、type_router、multicast_hash、rgmii_to_gmii、crc32_d8 |  |  |
| 说明 | 未提供现有testbench源码；“当前散列用例”按RTL功能点和常见用例命名估算，重点用于重构方向和覆盖映射。 |  |  |
|  |  |  |  |
| 指标 | 值 | 建议 | 备注 |
| 验证测试点数 | 22 | 保持可追溯 | 每个测试点至少映射1个推荐用例 |
| 当前用例数量估算 | 75 | 减少重复 | 按表中散列用例示例估算 |
| 归并后推荐用例数 | 17 | 建议作为定向用例主集合 | 长回归仍可另列 |
| 建议归并功能组 | 16 | 优先处理 | 高重复、高相似度 |
| 建议拆出函数/任务类别 | 10 | 先拆公共库 | 减少单case函数数量 |
| P0测试点数量 | 16 | 优先完成 | 用于冒烟+日常回归 |
|  |  |  |  |
| 推荐重构原则 | 用例主体保留“配置-发送-检查”三段式；帧构造、CRC、驱动、FIFO、统计checker全部抽成公共库。 |  |  |
| 归并边界 | 可以归并“同一判决链/同一状态机/仅参数不同”的用例；不要把跨模块长压力和单点P0完全混在一起。 |  |  |


## Sheet: 测试点_用例映射

### Range: 测试点_用例映射!A1:K23
| 测试点ID | 验证测试点/需求 | RTL关联模块 | 推荐用例ID | 用例作用 | 关键激励/配置 | 期望检查点 | 当前散列用例可归并项 | 归并判断 | 函数复杂度处理 | 优先级 |
| VP01 | 复位与初始化：所有输出/计数器/FIFO控制信号回到空闲，CRC清理完成后 crc_init_done 置位 | top/filter/stat/crc_clean/router | TC_OPT_01_RESET_INIT | 建立全局基线，排除复位后残留状态 | sys_rst/rst 拉高释放；等待 CRC_TABLE_DEPTH*2 周期以上；不送帧 | 统计清零、drop_valid=0、路由写使能=0、crc_init_done=1、窗口计数从0开始 | TC_RESET_BASIC、TC_CRC_TABLE_INIT、TC_IDLE_OUTPUT | 建议归并 | 复位驱动/等待稳定/默认检查拆为公共 task | P0 |
| VP02 | RGMII DDR 到 GMII 字节拼接及 rxer 生成 | rgmii_to_gmii/top | TC_OPT_02_RGMII_GMII_BASIC | 验证顶层入口数据位序与错误信号 | 构造 RGMII 上/下沿 nibble；rxdv 下沿携带 rxer_r | gmii_rxd={negedge_nibble,posedge_nibble}；gmii_rxer=gmii_rxer_r^gmii_rxdv | TC_RGMII_DDR、TC_RGMII_RXER | 建议归并 | RGMII bit/nibble drive 抽成 interface BFM | P1 |
| VP03 | 前导码与 SFD 检测：7 个 0x55 后跟 0xD5 才进入接收 | main_fsm/crc32 | TC_OPT_03_FRAME_RX_FORMAT | 覆盖以太帧接收入口条件 | 合法 preamble/SFD、短 preamble、错误 SFD、rxdv 中断 | 合法帧进入 W_RECV；非法序列不产生有效描述符或产生长度/CRC类丢弃 | TC_PREAMBLE_OK、TC_PREAMBLE_SHORT、TC_SFD_BAD | 建议归并 | 前导码变体由参数表驱动，不单独写多个 case | P0 |
| VP04 | FCS 剥离、最小长度、最大长度和 VLAN 长度折算 | main_fsm | TC_OPT_03_FRAME_RX_FORMAT | 确认写入二级路径前的数据长度正确 | 普通帧60/1514/越界；VLAN帧带0x8100 TPID/TCI；cfg_max_frame_bytes=0/非0 | store_len 不含 FCS；VLAN TPID/TCI 不写入数据 FIFO；短帧/超长帧 DROP_LEN_ERR | TC_LEN_MIN、TC_LEN_MAX、TC_LEN_SHORT、TC_LEN_OVERSIZE、TC_VLAN_STRIP | 建议归并 | 帧构造、FCS、VLAN 插入分离成 build_frame 参数 | P0 |
| VP05 | CRC 检查与 GMII RXER：cfg_crc_check_en 开关、CRC residue、rxer 错误 | main_fsm/crc32 | TC_OPT_04_CRC_AND_RX_ERROR | 验证错误帧不会误通过 | 正确FCS、错误FCS、rxer=1、cfg_crc_check_en=0/1 | CRC错误或rxer导致 DROP_CRC_ERR；关闭CRC检查时仅错误FCS不丢弃，但rxer仍丢弃 | TC_CRC_OK、TC_CRC_ERR、TC_CRC_DISABLE、TC_RXER_ERR | 建议归并 | CRC黄金模型放 tb_lib，不在每个用例重复写 function | P0 |
| VP06 | 目的 MAC 过滤：本机单播命中、广播允许/禁止 | main_fsm | TC_OPT_05_DST_MAC_FILTER | 覆盖 cfg_dst_mac_en 与 cfg_allow_broadcast | dst=cfg_local_mac；dst=ff:ff:ff:ff:ff:ff；cfg_dst_mac_en/allow_broadcast组合 | 本机单播通过；广播按配置通过或 DROP_DST_MISS；filter_en=0 时目的MAC不阻断 | TC_DST_LOCAL、TC_BROADCAST_ALLOW、TC_BROADCAST_BLOCK、TC_DST_FILTER_DISABLE | 建议归并 | MAC地址生成与命中期望用数据表驱动 | P0 |
| VP07 | 组播 hash：配置 MAC 写入64bit表、命中/未命中、clear 优先级 | multicast_hash/main_fsm | TC_OPT_06_MULTICAST_HASH | 验证组播准入路径 | cfg_multicast_mac_valid 上升沿；cfg_multicast_hash_clear；allow_multicast=0/1；命中/未命中组播 | hash bit 被置位并保持；clear 后全清；命中且允许时通过，否则 DROP_DST_MISS | TC_MC_HASH_ADD、TC_MC_HASH_HIT、TC_MC_HASH_MISS、TC_MC_HASH_CLEAR | 建议归并 | hash计算/配置时序/check 表状态拆为公共子任务 | P1 |
| VP08 | 白名单/黑名单：源 MAC 命中、未命中以及优先级 | main_fsm | TC_OPT_07_ACL_WHITE_BLACK | 验证 ACL 对通过/丢弃的影响 | 4路白名单/黑名单配置；white_en/black_en 组合；同一源同时黑白命中 | 黑名单命中 DROP_BLACKLIST；白名单开启未命中 DROP_NOT_WHITE；关闭对应功能不阻断；优先级按目的MAC、黑名单、白名单顺序 | TC_WL_HIT、TC_WL_MISS、TC_BL_HIT、TC_ACL_PRIORITY | 建议归并 | ACL配置矩阵用 for/参数表，不拆成过多单case | P0 |
| VP09 | 过滤总开关 cfg_filter_en：目的MAC/ACL/风暴/重复CRC受控，CRC/长度/FIFO错误仍有效 | main_fsm/stat | TC_OPT_08_FILTER_ENABLE_BYPASS | 防止总开关理解偏差 | filter_en=0；构造 dst miss/ACL miss/storm/dup_crc/len_err/crc_err | dst/ACL/storm/dup不丢；CRC错误、长度错误、一级FIFO满仍按错误丢弃 | TC_FILTER_DISABLE_DST、TC_FILTER_DISABLE_ACL、TC_FILTER_DISABLE_STORM、TC_FILTER_DISABLE_DUP | 建议归并 | 禁用场景作为边界矩阵，不要单点一案到底 | P0 |
| VP10 | 一级缓冲拥塞：pfifo_full/desc_fifo_full 导致接收侧 DROP_BUF_FULL | main_fsm/filter/tx_fsm | TC_OPT_09_BUFFER_AND_DESCRIPTOR | 验证接收侧数据/描述符保护 | 接收过程中拉高 pfifo_full 或 desc_fifo_full；边界在首字节/中间/尾部 | 进入 DISCARD_RECV；最终描述符 pass=0；drop_reason=DROP_BUF_FULL；不会写坏后续帧 | TC_PFIFO_FULL、TC_DESC_FIFO_FULL、TC_DISCARD_DRAIN | 建议归并 | FIFO backpressure 驱动单独封装，边界点参数化 | P0 |
| VP11 | 描述符格式：pass、len、mac_class、eth_type_class、frame_time | main_fsm/type_router | TC_OPT_09_BUFFER_AND_DESCRIPTOR | 验证上下游协议契约 | 分别送本机/广播/组播、GOOSE/SV/Other、pass/drop帧 | desc[52]=pass；desc[51:36]=store_len；desc[35:34]=MAC类；desc[33:32]=类型类；time递增 | TC_DESC_PASS、TC_DESC_CLASS、TC_FRAME_TIME | 建议归并 | 描述符解码器写成 checker，不写在每个 case | P0 |
| VP12 | 帧数风暴：窗口计数、阈值覆盖、active粘滞到窗口结束 | stat/main_fsm | TC_OPT_10_STORM_WINDOW | 验证 frame storm 策略 | cfg_frame_storm_en=1；阈值=1/2/默认；窗口内连续帧；跨窗口 | 超过阈值后 DROP_FRAME_STORM；stat_frame_storm_active置位；窗口翻转后重新计数 | TC_FRAME_STORM_THRESH、TC_FRAME_STORM_ACTIVE、TC_WINDOW_ROLLOVER | 建议归并 | 窗口推进、帧注入、计数检查封装为 storm_seq | P0 |
| VP13 | 字节数风暴：窗口字节累计、VLAN帧长度口径、阈值覆盖 | stat/main_fsm | TC_OPT_10_STORM_WINDOW | 验证 byte storm 策略 | 不同长度普通帧/VLAN帧；cfg_byte_max_per_win=0/非0；跨窗口 | 累计字节超过阈值后 DROP_BYTE_STORM；窗口计数/统计值符合帧长度口径 | TC_BYTE_STORM_THRESH、TC_BYTE_STORM_VLAN、TC_BYTE_STORM_ROLLOVER | 建议归并 | 与帧数风暴共用窗口模型，只换阈值维度 | P0 |
| VP14 | 重复 CRC：首次写表、同窗口第二次命中、禁用开关、初始化完成前不查重 | main_fsm/crc_clean | TC_OPT_11_DUP_CRC_AND_CLEAN | 验证重复帧抑制 | 同一FCS帧连续发送；cfg_dup_crc_en=0/1；crc_init_done=0/1 | 首次通过并写表；同窗口重复 DROP_DUP_CRC；禁用或未初始化时不因重复丢弃 | TC_DUP_FIRST_PASS、TC_DUP_SECOND_DROP、TC_DUP_DISABLE、TC_DUP_INIT_NOT_DONE | 建议归并 | CRC表模型单独维护，case仅给帧序列 | P0 |
| VP15 | CRC 表后台清理：窗口翻转后旧 epoch 项清除，normal读写优先，pause请求有效 | crc_clean/main_fsm/stat | TC_OPT_11_DUP_CRC_AND_CLEAN | 验证去重表生命周期 | 窗口翻转；制造normal_rd/we与清理同周期；crc_clear_pause_req拉高 | 旧epoch条目被清零；normal_we优先；pause期间清理停顿且不破坏正常访问 | TC_CRC_CLEAN_ROLLOVER、TC_CRC_CLEAN_PAUSE、TC_CRC_NORMAL_PRIORITY | 建议归并 | 建议作为dup_crc子场景，不单独堆大量小case | P1 |
| VP16 | EtherType 路由：GOOSE/SV/Other 数据先写入，描述符后提交 | type_router/tx_fsm | TC_OPT_12_TYPE_ROUTER | 验证二级FIFO分流和数据/描述符对齐 | cfg_eth_type_goose/cfg_eth_type_sv配置；三类通过帧；不同长度 | 对应通道 data_wr_en 持续len拍；最后写 desc；其他通道无写入 | TC_ROUTE_GOOSE、TC_ROUTE_SV、TC_ROUTE_OTHER、TC_ROUTE_DESC_AFTER_DATA | 建议归并 | 路由通道作为参数，不需三份完全重复代码 | P0 |
| VP17 | 二级 FIFO 拥塞：full/prog_full/desc_full 时静默丢弃并计数，不阻塞其它类 | type_router/tx_fsm | TC_OPT_13_ROUTE_CONGESTION | 验证分类输出拥塞保护 | 分别拉高目标data_full/prog_full/desc_full；轮换GOOSE/SV/Other；后续其它类帧继续路由 | route_drop_fifo_full_valid脉冲；按class统计；只读common FIFO不写目标FIFO；后续帧不被饥饿 | TC_ROUTE_FULL_GOOSE、TC_ROUTE_FULL_SV、TC_ROUTE_FULL_OTHER、TC_ROUTE_NO_WAIT | 建议归并 | 拥塞类型和通道二维参数化，避免9个重复case | P0 |
| VP18 | 接收侧已丢弃帧/零长度描述符：router 只 drain，不计入二级拥塞丢弃 | type_router | TC_OPT_13_ROUTE_CONGESTION | 区分接收侧丢弃与路由侧丢弃 | pass=0且len>0；pass=0且len=0；pass=1但len=0 | pass=0帧被静默读走；route_drop计数不增；len=0不读data FIFO | TC_RX_DROP_DRAIN、TC_ZERO_DESC_SKIP | 建议归并 | 作为路由拥塞用例的边界场景 | P1 |
| VP19 | 统计清零：cfg_clear_stats 同步、清零优先级、窗口时基保留 | stat/type_router | TC_OPT_14_STATS_AND_CLEAR | 验证软件可观测寄存器行为 | 产生pass/drop/route_drop后拉 cfg_clear_stats；清零周期与帧提交/窗口翻转重合 | 统计计数清零；drop_valid默认0；frame_time不清零；窗口周期继续推进 | TC_CLEAR_STATS_RX、TC_CLEAR_STATS_ROUTE、TC_CLEAR_STATS_WITH_COMMIT | 建议归并 | 统计寄存器读写/check统一封装 | P0 |
| VP20 | 丢弃原因优先级：CRC、目的MAC、黑名单、白名单、缓冲、长度、风暴、重复CRC | main_fsm/stat | TC_OPT_15_DROP_PRIORITY_MATRIX | 验证多错误叠加时只报最高优先级 | 构造多个错误同时成立：crc+dstmiss、black+whiteMiss、len+storm、storm+dup等 | drop_reason按RTL if-else顺序输出；对应统计只增加一个原因 | TC_PRIORITY_CRC_DST、TC_PRIORITY_ACL、TC_PRIORITY_LEN_STORM、TC_PRIORITY_STORM_DUP | 建议归并 | 用优先级矩阵数据驱动，避免排列组合爆炸 | P0 |
| VP21 | 参数与配置默认值：cfg_*阈值为0时使用 parameter 默认，非0时覆盖 | main_fsm/stat/filter/top | TC_OPT_16_CFG_DEFAULT_OVERRIDE | 验证可配置边界 | cfg_window_ms/frame_max/byte_max/max_frame_bytes 分别置0和非0 | 置0使用参数默认；非0使用寄存器值；边界比较大于阈值才丢弃 | TC_CFG_DEFAULTS、TC_CFG_OVERRIDE_FRAME、TC_CFG_OVERRIDE_BYTE、TC_CFG_OVERRIDE_LEN | 建议归并 | 配置覆盖参数表驱动，不单独写四套函数 | P1 |
| VP22 | 连续帧/背靠背帧：状态机回到IDLE后可正确接下一帧 | main_fsm/type_router | TC_OPT_17_BACK_TO_BACK_REGRESSION | 回归级压力覆盖 | 不同类型、通过/丢弃、不同长度帧连续发送，中间最小IFG | 每帧描述符、统计、路由输出均不串帧；丢弃帧不污染下一帧 | TC_BACK_TO_BACK_PASS、TC_BACK_TO_BACK_MIXED_DROP、TC_BACK_TO_BACK_ROUTE | 部分保留 | 作为少量高价值回归，不与单点规则完全混在一起 | P1 |


## Sheet: 归并后用例集

### Range: 归并后用例集!A1:H18
| 推荐用例ID | 用例名称 | 主要作用 | 覆盖测试点 | 场景数量建议 | 建议保留/归并 | 用例内函数控制建议 | 检查器/scoreboard重点 |
| TC_OPT_01_RESET_INIT | 复位与初始化 | 验证全局复位、CRC表初始化和默认输出 | VP01 | 2~3个子场景 | 保留为独立基础用例 | 仅调用 reset_dut、wait_crc_init、check_idle 三类公共task | 复位后状态、统计、crc_init_done |
| TC_OPT_02_RGMII_GMII_BASIC | RGMII入口基础 | 验证DDR采样和rxer组合 | VP02 | 2个子场景 | 保留，可选独立模块级 | RGMII驱动放interface BFM，避免case内bit级拼装 | GMII字节、rxdv、rxer |
| TC_OPT_03_FRAME_RX_FORMAT | 接收帧格式/长度/VLAN | 覆盖preamble/SFD、FCS剥离、长度、VLAN删除 | VP03,VP04 | 8~10个参数化子场景 | 将多个长度/前导码小用例归并 | frame_builder参数化：len、vlan、preamble_mode、expect_drop | store_len、DROP_LEN_ERR、数据FIFO内容 |
| TC_OPT_04_CRC_AND_RX_ERROR | CRC和RX错误 | 覆盖CRC开关、错误FCS、rxer | VP05 | 4个子场景 | 归并CRC正反例 | CRC计算使用公共golden model，case只配置是否篡改FCS/rxer | DROP_CRC_ERR、pass/drop统计 |
| TC_OPT_05_DST_MAC_FILTER | 目的MAC过滤 | 覆盖本机单播、广播开关、filter_en旁路 | VP06 | 5~6个子场景 | 归并单播/广播/disable | 用表格驱动dst_mac和配置组合 | DROP_DST_MISS、mac_class |
| TC_OPT_06_MULTICAST_HASH | 组播Hash过滤 | 覆盖hash配置、命中、未命中、清除 | VP07 | 4~5个子场景 | 归并组播hash相关用例 | hash_config_task和send_multicast_frame分离 | hash_hit、DROP_DST_MISS、clear优先级 |
| TC_OPT_07_ACL_WHITE_BLACK | ACL白黑名单 | 覆盖4路白/黑名单、优先级 | VP08 | 6~8个子场景 | 归并ACL矩阵 | 白黑名单配置用数组循环；check_priority放checker | DROP_BLACKLIST、DROP_NOT_WHITE |
| TC_OPT_08_FILTER_ENABLE_BYPASS | 过滤总开关旁路 | 验证filter_en只旁路部分过滤项 | VP09 | 4~5个子场景 | 由多个disable用例归并 | 使用统一错误类型枚举生成帧 | dst/ACL/storm/dup是否被旁路 |
| TC_OPT_09_BUFFER_AND_DESCRIPTOR | 一级缓冲和描述符 | 覆盖pfifo/desc满、desc编码和time | VP10,VP11 | 6~8个子场景 | 归并FIFO满和描述符检查 | FIFO压力任务与descriptor_decoder拆出 | DROP_BUF_FULL、desc字段对齐 |
| TC_OPT_10_STORM_WINDOW | 风暴窗口 | 覆盖帧数/字节数阈值、窗口翻转、active | VP12,VP13 | 8~10个子场景 | 归并frame/byte storm主干 | storm_sequence参数化threshold_kind/limit/frame_len | 窗口计数、DROP_FRAME/BYTE_STORM |
| TC_OPT_11_DUP_CRC_AND_CLEAN | 重复CRC和后台清理 | 覆盖去重、epoch、清理、normal优先级 | VP14,VP15 | 6~8个子场景 | 归并CRC表相关用例 | CRC表参考模型独立，清理节奏封装 | DROP_DUP_CRC、crc_clean行为 |
| TC_OPT_12_TYPE_ROUTER | 三路类型路由 | 覆盖GOOSE/SV/Other分流与desc后提交 | VP16 | 3~4个子场景 | 三通道用参数化归并 | route_class枚举驱动，不写三套case | 目标FIFO数据/desc顺序 |
| TC_OPT_13_ROUTE_CONGESTION | 二级路由拥塞与drain | 覆盖full/prog_full/desc_full、pass=0、len=0边界 | VP17,VP18 | 8~10个子场景 | 归并9类拥塞小用例 | 二维参数：channel x congest_kind；pass/len作为边界参数 | route_drop计数、无阻塞 |
| TC_OPT_14_STATS_AND_CLEAR | 统计和清零 | 覆盖RX统计、路由统计、clear优先级 | VP19 | 5~6个子场景 | 归并统计清零用例 | 统计采样/checker统一 | 计数器清零、frame_time不清零 |
| TC_OPT_15_DROP_PRIORITY_MATRIX | 丢弃原因优先级矩阵 | 覆盖多错误叠加时优先级 | VP20 | 8~12个矩阵行 | 用数据驱动替代多个组合case | priority_matrix表驱动，checker按优先级计算期望 | drop_reason唯一性和统计唯一性 |
| TC_OPT_16_CFG_DEFAULT_OVERRIDE | 配置默认值和覆盖 | 覆盖cfg=0默认值、非0覆盖 | VP21 | 6~8个子场景 | 归并配置边界用例 | config_apply和expected_limit_model分离 | 阈值生效和边界比较 |
| TC_OPT_17_BACK_TO_BACK_REGRESSION | 背靠背混合回归 | 覆盖连续帧压力和跨模块串扰 | VP22 | 3~5条长序列 | 保留为系统级回归 | 只用高层sequence，不在case内堆底层function | 数据不串帧、统计连续性 |


## Sheet: 用例归并评估

### Range: 用例归并评估!A1:H18
| 功能组 | 当前散列用例示例 | 当前用例数量估计 | 问题判断 | 建议归并到 | 归并依据 | 归并后数量建议 | 归并结论 |
| 复位/空闲 | TC_RESET_BASIC、TC_CRC_TABLE_INIT、TC_IDLE_OUTPUT | 3 | 激励简单且检查点高度重合 | TC_OPT_01_RESET_INIT | 均为无帧场景，复用reset/wait/check_idle | 1 | 建议归并 |
| RGMII入口 | TC_RGMII_DDR、TC_RGMII_RXER | 2 | 只差rxer组合，bit级驱动可复用 | TC_OPT_02_RGMII_GMII_BASIC | 接口级采样逻辑相同 | 1 | 建议归并 |
| 前导码/长度/VLAN | TC_PREAMBLE_OK、TC_SFD_BAD、TC_LEN_MIN、TC_LEN_SHORT、TC_VLAN_STRIP等 | 8 | 格式维度多但激励生成相同 | TC_OPT_03_FRAME_RX_FORMAT | 参数化frame profile即可覆盖 | 1 | 建议归并 |
| CRC/RXER | TC_CRC_OK、TC_CRC_ERR、TC_CRC_DISABLE、TC_RXER_ERR | 4 | CRC黄金模型重复，期望逻辑类似 | TC_OPT_04_CRC_AND_RX_ERROR | 仅FCS是否篡改、开关和rxer变化 | 1 | 建议归并 |
| 目的MAC过滤 | TC_DST_LOCAL、TC_BROADCAST_ALLOW、TC_BROADCAST_BLOCK、TC_DST_FILTER_DISABLE | 4 | 同一判决链的配置组合 | TC_OPT_05_DST_MAC_FILTER | 表驱动配置矩阵即可 | 1 | 建议归并 |
| 组播Hash | TC_MC_HASH_ADD、TC_MC_HASH_HIT、TC_MC_HASH_MISS、TC_MC_HASH_CLEAR | 4 | 配置/查找/clear属于同一状态机 | TC_OPT_06_MULTICAST_HASH | hash流程连续验证更有效 | 1 | 建议归并 |
| ACL白黑名单 | TC_WL_HIT、TC_WL_MISS、TC_BL_HIT、TC_ACL_PRIORITY | 4 | 列表配置重复，检查为drop_reason差异 | TC_OPT_07_ACL_WHITE_BLACK | 用配置矩阵覆盖优先级 | 1 | 建议归并 |
| 过滤总开关 | TC_FILTER_DISABLE_DST、TC_FILTER_DISABLE_ACL、TC_FILTER_DISABLE_STORM、TC_FILTER_DISABLE_DUP | 4 | 同一旁路开关的不同功能维度 | TC_OPT_08_FILTER_ENABLE_BYPASS | 验证开关范围而非每个功能单独回归 | 1 | 建议归并 |
| 一级FIFO/描述符 | TC_PFIFO_FULL、TC_DESC_FIFO_FULL、TC_DESC_PASS、TC_DESC_CLASS、TC_FRAME_TIME | 5 | 接收提交路径相同 | TC_OPT_09_BUFFER_AND_DESCRIPTOR | 拥塞和描述符字段可在同一用例组检查 | 1 | 建议归并 |
| 风暴窗口 | TC_FRAME_STORM_THRESH、TC_BYTE_STORM_THRESH、TC_WINDOW_ROLLOVER、TC_STORM_ACTIVE | 6 | 窗口模型相同，仅阈值维度不同 | TC_OPT_10_STORM_WINDOW | 同一sequence参数化threshold_kind | 1 | 建议归并 |
| 重复CRC/清理 | TC_DUP_FIRST_PASS、TC_DUP_SECOND_DROP、TC_CRC_CLEAN_ROLLOVER、TC_CRC_NORMAL_PRIORITY | 7 | 同一CRC RAM生命周期 | TC_OPT_11_DUP_CRC_AND_CLEAN | 连续场景可覆盖首次/重复/跨窗口/清理 | 1 | 建议归并 |
| 类型路由 | TC_ROUTE_GOOSE、TC_ROUTE_SV、TC_ROUTE_OTHER、TC_ROUTE_DESC_AFTER_DATA | 4 | 通道差异是枚举，流程相同 | TC_OPT_12_TYPE_ROUTER | class参数化即可 | 1 | 建议归并 |
| 二级拥塞 | TC_ROUTE_FULL_GOOSE、TC_ROUTE_FULL_SV、TC_ROUTE_FULL_OTHER、TC_ROUTE_NO_WAIT、TC_ZERO_DESC_SKIP | 6 | 通道/拥塞原因组合爆炸 | TC_OPT_13_ROUTE_CONGESTION | 二维矩阵驱动，保留关键组合 | 1 | 建议归并 |
| 统计清零 | TC_CLEAR_STATS_RX、TC_CLEAR_STATS_ROUTE、TC_CLEAR_STATS_WITH_COMMIT | 3 | 清零机制和检查对象一致 | TC_OPT_14_STATS_AND_CLEAR | 同一clear_stats时序覆盖即可 | 1 | 建议归并 |
| 丢弃优先级 | TC_PRIORITY_CRC_DST、TC_PRIORITY_ACL、TC_PRIORITY_LEN_STORM、TC_PRIORITY_STORM_DUP | 4 | 排列组合会爆炸 | TC_OPT_15_DROP_PRIORITY_MATRIX | 表驱动优先级矩阵 | 1 | 建议归并 |
| 配置默认/覆盖 | TC_CFG_DEFAULTS、TC_CFG_OVERRIDE_FRAME、TC_CFG_OVERRIDE_BYTE、TC_CFG_OVERRIDE_LEN | 4 | 仅配置寄存器和阈值不同 | TC_OPT_16_CFG_DEFAULT_OVERRIDE | 统一limit model | 1 | 建议归并 |
| 背靠背压力 | TC_BACK_TO_BACK_PASS、TC_BACK_TO_BACK_MIXED_DROP、TC_BACK_TO_BACK_ROUTE | 3 | 系统级组合较长，调试价值高 | TC_OPT_17_BACK_TO_BACK_REGRESSION | 保留少量长序列，不再继续合并到单点用例 | 1 | 部分保留 |


## Sheet: 函数拆分建议

### Range: 函数拆分建议!A1:G11
| 函数/任务类别 | 当前常见放置方式 | 问题 | 建议归属 | 建议拆分粒度 | 适用用例 | 处理结论 |
| 帧构造 build_eth_frame | 散落在多个case内或每案重写 | 长度/VLAN/FCS/前导码耦合，case臃肿 | tb_lib/frame_builder | 输入profile：dst/src/type/payload_len/vlan/fcs_mode/preamble_mode | TC_OPT_03~17 | 建议拆出 |
| CRC32黄金模型 | CRC用例和组播hash用例内各自实现 | 重复且易与RTL位序不一致 | tb_lib/crc_model | 提供 calc_eth_fcs、calc_mac_hash_index | TC_OPT_04,06,11 | 建议拆出 |
| GMII/RGMII驱动 | case内直接逐拍drive | 时序细节掩盖用例意图 | interface BFM/driver | send_gmii_frame、send_rgmii_nibbles、inject_rxer | TC_OPT_02~17 | 建议拆出 |
| 配置寄存器/开关设置 | 每个case手动赋值 | 配置遗漏导致case之间互相污染 | cfg_agent/reset_cfg | set_default_cfg、apply_mac_filter、apply_acl、apply_storm_limit | 全部 | 建议拆出 |
| FIFO读写/拥塞控制 | router和buffer用例内自写full/rd_en逻辑 | 代码长，边界点难复用 | fifo_agent | set_fifo_backpressure、drain_channel、expect_no_write | TC_OPT_09,12,13 | 建议拆出 |
| Scoreboard描述符解码 | 每个case直接切片desc字段 | 字段位宽更改时维护成本高 | scoreboard/desc_decoder | decode_desc、expect_desc、expect_route | TC_OPT_09,12,13,17 | 建议拆出 |
| 统计计数检查 | 每个case手写计数器比较 | 清零/窗口/route计数规则分散 | scoreboard/stat_checker | expect_stat_delta、expect_drop_reason、expect_clear | TC_OPT_01,08,10,14,15,17 | 建议拆出 |
| 优先级期望模型 | 多错误用例中硬编码期望 | RTL优先级变化时难以统一更新 | scoreboard/decision_model | calc_expected_drop_reason(error_vector,cfg) | TC_OPT_15,08 | 建议拆出 |
| 窗口推进/风暴序列 | frame storm 和 byte storm 各写一套 | 重复驱动窗口周期和阈值 | sequence_lib/storm_seq | threshold_kind、limit、frame_count、payload_len参数化 | TC_OPT_10 | 建议拆出 |
| 随机/回归序列 | 与定向case混在一起 | 单case function过多且失败定位差 | regression_seq | 少量高层sequence调用公共BFM，不放底层细节 | TC_OPT_17 | 建议拆出 |


## Sheet: 假设与风险

### Range: 假设与风险!A1:C6
| 风险/注意点 | 说明 | 建议动作 |
| 未看到现有testbench源码 | 本表按RTL功能和常见命名估算“当前用例”数量与可归并项 | 用真实用例名替换当前散列用例示例列，即可作为重构跟踪表 |
| 不建议无限归并 | 归并目标是减少重复和函数臃肿，不是把所有场景塞进一个大case | 每个推荐用例内用参数表/子场景，失败时打印子场景ID |
| P0单点仍需清晰 | CRC、长度、ACL、风暴、拥塞、路由等P0测试点必须独立可定位 | P0用例可归并功能组，但检查点和场景ID要可追溯 |
| 函数拆分优先级 | 最先拆 frame_builder、driver、cfg_agent、scoreboard | 拆完后用例主体应保持在“配置-发送-检查”三段式 |
| 统计/窗口跨时钟 | route_drop在clk_125m域，rx drop在gmii_rx_clk域 | 用checker分别采样时钟域，不要单周期硬对齐 |
