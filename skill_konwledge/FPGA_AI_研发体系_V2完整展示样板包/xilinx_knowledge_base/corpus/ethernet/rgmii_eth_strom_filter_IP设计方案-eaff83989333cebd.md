# rgmii_eth_strom_filter IP设计方案

- Category: `ethernet`
- Source: `E:\eth_storm_project\rgmii_eth_strom_filter IP设计方案.doc`
- SHA-256: `eaff83989333cebdecdf825fe5f555cfd27c1afc9eefc2b184a3499d07193f5e`
- Extractor: `libreoffice-text`
- Tags: `dma, ethernet, rgmii, storm-filter`
- Duplicate sources:
  - none

产品名称Product name	密级Confidentiality level
主动保护/通用测量IP2功能完善
产品版本Product version	Total 23 pages 共23页
V1.0


rgmii_eth_storm_filter IP开发详细设计方案


Prepared by
拟制
霍奕轩	Date
日期
2026-6-1
Reviewed by
评审人
	Date
日期

Approved by
批准
	Date
日期


Revision Record 修订记录
Revision Version
修订版本	Change Description
修改描述
	Author
作者	Date
日期
1.0	完成初稿	霍奕轩	26.6.3


目  录
Revision Record 修订记录	2
目  录	3
1 概述	4
1.1 设计背景	4
1.2 设计架构	5
1.3 接口列表	6
1.4 时钟和复位管理	9
1.4.1 时钟管理	9
1.4.2 复位管理	10
2 rgmii_eth_strom_filter整体设计	10
2.1 rgmii_eth_strom_filter架构设计	10
2.2 rgmii_to_gmii模块设计	11
2.2.1 功能说明	11
2.2.2 接口列表	11
2.2.3 接口时序	12
2.2.4 功能设计	12
2.3 eth_storm_filter模块设计	12
2.3.1 功能说明	12
2.3.2 接口列表	14
2.3.3 接口时序	18
2.3.4 功能设计	19

1 概述
1.1 设计背景
FPGA需要直接接收来自外部PHY的高速RGMII数据流，并在本地逻辑中完成协议转换、数据筛选和安全防护。传统接收链路通常只完成RGMII到GMII的接口转换和基本数据接收，缺少对异常流量、重复报文和非法源端的有效抑制。当网络中出现广播风暴、异常重复帧或非授权设备持续发送报文时，后级用户逻辑和缓存资源可能被大量无效数据占用，导致系统处理能力下降，甚至引起数据丢失。
为提高接收链路的可靠性和抗异常流量能力，本设计在rgmii_to_gmii转换模块之后增加eth_storm_filter网络风暴过滤模块。该模块在GMII接收侧完成以太网帧识别、目的MAC检查、源MAC黑白名单过滤、CRC校验、重复CRC去重、窗口帧数和字节数风暴检测，并通过异步FIFO将通过帧同步到本地clk_125m时钟域输出。通过该设计，系统可以在数据进入后级业务逻辑前提前丢弃异常帧和风暴帧，降低无效流量对后级设备的冲击，提高网络接收链路的稳定性、可控性和可调试性。
模块核心功能如下：
1、以太网帧顺序缓存：从GMII字节流中严格识别7字节0x55前导码和1字节0xD5 SFD后开始接收帧内容；通过四字节尾部保留机制剥离末尾4字节FCS，只将DA、SA、EtherType、Payload等有效frame_data写入公共frame FIFO。支持802.1Q VLAN标签解析，并在写入frame FIFO时剥离TPID/TCI，使输出帧恢复为不带VLAN标签的DA/SA/EtherType/Payload格式。
2、跨时钟域设计：输入接收、字段解析、判决和统计工作在gmii_rx_clk时钟域；公共frameFIFO与公共描述符FIFO将帧数据和描述符跨到本地clk_125m时钟域；输出侧在clk_125m域完成业务类型路由和三路独立输出。
3、目的MAC过滤：支持本地单播、广播和软件可编程组播Hash表三类目的MAC准入方式。广播准入由cfg_allow_broadcast控制；组播准入由cfg_allow_multicast控制，并通过cfg_multicast_mac/cfg_multicast_mac_valid将组播MAC写入64bitHash表，通过cfg_multicast_hash_clear清空Hash表。
4、ACL源端过滤：固定支持4条白名单和4条黑名单，由输入寄存器配置地址和使能。黑名单命中优先于白名单未命中；白名单总使能后，源MAC未命中任何已使能白名单规则则丢弃。
5、三路独立输出：解析EtherType后，根据cfg_eth_type_goose和cfg_eth_type_sv将帧分类为GOOSE、SV或Other，并将分类结果写入53bit描述符中的desc_eth_type_class字段。通过帧先进入公共跨时钟FIFO，再由eth_storm_type_router按desc_eth_type_class路由到GOOSE、SV、Other三组二级FIFO，最后分别通过goose、sv、other三套ready/valid输出接口输出。
6、风暴过滤：在可配置时间窗口内统计满足基础有效条件的帧数和字节数，超过cfg_frame_max_per_win/cfg_byte_max_per_win或默认阈值时丢弃。cfg_window_ms为0时使用参数WINDOW_MS默认窗口长度,最大时间窗口长度30000ms。
7、CRC校验：对SFD之后的完整帧内容计算CRC32，计算范围包含DA、SA、EtherType、Payload和FCS。cfg_crc_check_en=1时，帧尾CRC结果必须等于固定残余值32'h2144_DF1C；cfg_crc_check_en=0时不因FCS校验失败丢弃，但gmii_rxer、最小长度等硬错误仍生效。
8、CRC重复帧过滤：以接收到的帧尾FCS字段作为重复帧查表关键值，并使用FCS高低16bit异或后的索引访问CRC去重RAM。同一窗口epoch内查到相同FCS时判定为重复帧。CRC去重RAM在复位后先后台清零，窗口翻转后按epoch清理旧表项；只有最终通过且cfg_filter_en/cfg_dup_crc_en使能的帧才写入去重表。
9、帧尾统一判决：完整帧接收结束后，在W_DECIDE中按照单一优先级链生成dec_pass和dec_drop_reason；在W_COMMIT中写入描述符并更新统计。最终丢弃原因只取最高优先级命中的一个原因。具体判决优先级见2.3.4.1的“(8)帧尾判决优先级”。
10、通过帧输出与丢弃帧排出：接收侧判定通过的帧在clk_125m域按EtherType分类输出到GOOSE、SV或Other通道，接收侧丢弃帧只从公共frameFIFO静默排出，不向三路输出接口产生有效数据。若某一路二级FIFO拥塞，路由模块会将该通过帧静默排出而不阻塞其它通道，该路由级静默丢弃不产生drop_valid/drop_reason统计事件。
11、统计与调试输出：输出通过计数、各类接收侧丢弃计数、当前窗口统计、最近丢弃原因、风暴状态和帧时间标志。frame_time在检测到SFD时锁存，统计清零不清除时间基准计数器。
1.2 设计架构
本系统采用模块化分层设计，整体架构如图1所示。顶层模块rgmii_eth_strom_filter例化了两个核心子模块rgmii_to_gmii、eth_strom_filter，同时集成了用于相位调整和跨时钟域处理的时钟管理单元（PLL/MMCM），并包含tb_rgmii_eth_strom_filter仿真测试模块。

图1系统顶层设计框图
外部PHY提供的RGMII接口信号，首先rgmii_rx_clk通过MMCM对接收时钟进行相位调整，以补偿FPGA内部布线延迟差异，确保采样窗口中心对齐。然后进入rgmii_to_gmii模块。该模块利用IDDR原语将4位RGMII格式转换为8位GMII格式。
转换后的GMII信号送入eth_storm_filter模块。该模块实现以太网帧过滤、风暴检测、CRC去重及有效帧输出。
tb_rgmii_eth_strom_filter仿真测试模块用于验证IP核的功能正确性。仿真平台模拟PHY行为，生成符合RGMII接口时序的标准UDP数据包。然后通过监测中间变量和输出数据，与预期结果进行比对，验证设计的逻辑功能和时序可靠性。
PLL时钟模块生成125Mhz时钟和locked时钟有效信号。
1.3 接口列表
表1 rgmii_eth_strom_filter IP接口列表
信号	方向	位宽	描述
参数定义
CLK_FREQ_HZ	P	int	RGMII RX 时钟频率，用于计算窗口周期数，125000000
WINDOW_MS	P	int	风暴统计窗口长度，单位ms，默认10ms，最大30000ms
FRAME_MAX_PER_WIN	P	int	默认窗口最大帧数阈值，运行时配置为0时使用，1000
BYTE_MAX_PER_WIN	P	int	默认窗口最大字节数阈值，运行时配置为0时使用，8000000
MIN_FRAME_BYTES	P	int	最小帧字节数，60
MAX_FRAME_BYTES	P	int	最大帧字节数，1514
CRC_TABLE_DEPTH	P	int	CRC去重表深度，建议2的幂，1024，重新配置需修改内置RAM IP配置
DESC_DEPTH	P	int	描述符FIFO深度，需要和Vivado FIFO IP一致，32，重新配置需修改内置FIFO IP配置
时钟、复位接口
clk_125m	I	1	Vivado PLL IP生成的本地125MHz输出侧时钟
sys_rst	I	1	系统复位，高有效异步复位
RGMII PHY 接收接口
rgmii_rx_clk	I	1	RGMII PHY 接收时钟
rgmii_rxd	I	4	RGMII接收数据，4bit数据总线
rgmii_rxdv	I	1	RGMII接收数据有效控制信号
寄存器配置接口
cfg_filter_en	I	1	总过滤使能，关闭后目的MAC、ACL、风暴和重复CRC策略不过滤，但CRC/长度/资源类错误仍然生效
cfg_dst_mac_en	I	1	目的MAC检查使能
cfg_local_mac	I	48	本地MAC地址
cfg_allow_broadcast	I	1	允许广播目的MAC，FF:FF:FF:FF:FF:FF
cfg_allow_multicast	I	1	允许组播目的MAC
cfg_multicast_mac	I	48	待加入64 bit组播Hash表的组播MAC地址
cfg_multicast_mac_valid	I	1	上升沿触发一次组播MAC Hash计算并置位对应表项
cfg_multicast_hash_clear	I	1	高有效，清空64 bit组播Hash表
cfg_eth_type_goose	I	16	GOOSE帧EtherType配置值
cfg_eth_type_sv	I	16	SV帧EtherType配置值
cfg_whitelist_en	I	1	白名单总使能，使能后未命中白名单则丢弃
cfg_blacklist_en	I	1	黑名单总使能，命中黑名单则丢弃，优先级高于白名单
cfg_dup_crc_en	I	1	CRC重复帧过滤使能
cfg_frame_storm_en	I	1	帧数风暴过滤使能
cfg_byte_storm_en	I	1	字节数风暴过滤使能
cfg_crc_check_en	I	1	FCS校验使能，为0时gmii_rxer和长度错误仍生效
cfg_frame_max_per_win	I	32	运行时帧数阈值，为0时使用默认值
cfg_byte_max_per_win	I	32	运行时字节数阈值，为0时使用默认值
cfg_window_ms	I	32	运行时窗口长度，为0时使用默认值，最大值30000
cfg_max_frame_bytes	I	16	运行时单帧最大字节数，为0时使用默认值
cfg_clear_stats	I	1	统计清零控制
cfg_white*_en	I	1	4条白名单规则使能,*表示0、1、2、3
cfg_white*_mac	I	48	4条白名单源MAC匹配值
cfg_black*_en	I	1	4条黑名单规则使能
cfg_black*_mac	I	48	4条黑名单源MAC匹配值
GOOSE输出通道
goose_frame_ready	I	1	GOOSE 通道下游接收能力指示
goose_frame_valid	O	1	GOOSE 通道过滤后帧数据有效
goose_frame_data	O	8	GOOSE 通道过滤后帧数据
goose_frame_sof	O	1	GOOSE 通道帧首字节标志
goose_frame_eof	O	1	GOOSE 通道帧末字节标志
goose_frame_done	O	1	GOOSE 通道帧输出完成脉冲
goose_frame_len	O	16	GOOSE 通道输出帧长度
goose_mac_class	O	2	GOOSE 通道输出帧 MAC 分类
goose_eth_type_class	O	2	GOOSE 通道输出帧 EtherType 分类
goose_frame_time	O	32	GOOSE 通道输出帧时间标志
SV输出通道
sv_frame_ready	I	1	SV 通道下游接收能力指示
sv_frame_valid	O	1	SV 通道过滤后帧数据有效
sv_frame_data	O	8	SV 通道过滤后帧数据
sv_frame_sof	O	1	SV 通道帧首字节标志
sv_frame_eof	O	1	SV 通道帧末字节标志
sv_frame_done	O	1	SV 通道帧输出完成脉冲
sv_frame_len	O	16	SV 通道输出帧长度
sv_mac_class	O	2	SV 通道输出帧 MAC 分类
sv_eth_type_class	O	2	SV 通道输出帧 EtherType 分类
sv_frame_time	O	32	SV 通道输出帧时间标志
Other输出通道
other_frame_ready	I	1	Other 通道下游接收能力指示
other_frame_valid	O	1	Other 通道过滤后帧数据有效
other_frame_data	O	8	Other 通道过滤后帧数据
other_frame_sof	O	1	Other 通道帧首字节标志
other_frame_eof	O	1	Other 通道帧末字节标志
other_frame_done	O	1	Other 通道帧输出完成脉冲
other_frame_len	O	16	Other 通道输出帧长度
other_mac_class	O	2	Other 通道输出帧 MAC 分类
other_eth_type_class	O	2	Other 通道输出帧 EtherType 分类
other_frame_time	O	32	Other 通道输出帧时间标志
丢弃事件与统计接口
drop_valid	O	1	丢弃事件单周期脉冲
drop_reason	O	16	当前丢弃原因
stat_pass_cnt	O	32	通过帧累计计数
stat_drop_crc_err_cnt	O	32	CRC错误、gmii_rxer或帧长度不足丢弃计数
stat_drop_dup_crc_cnt	O	32	重复CRC丢弃计数
stat_drop_frame_storm_cnt	O	32	帧数风暴丢弃计数
stat_drop_byte_storm_cnt	O	32	字节数风暴丢弃计数
stat_drop_buf_full_cnt	O	32	frame FIFO满或描述符FIFO满丢弃计数
stat_drop_len_err_cnt	O	32	长度超限或长度异常丢弃计数
stat_drop_blacklist_cnt	O	32	黑名单命中丢弃计数
stat_drop_not_white_cnt	O	32	白名单未命中丢弃计数
stat_drop_dst_miss_cnt	O	32	目的MAC未匹配丢弃计数
stat_win_frame_cnt	O	32	当前窗口计入的帧数
stat_win_byte_cnt	O	32	当前窗口计入数据帧字节数
stat_last_drop_reason	O	16	最近一次丢弃原因
stat_frame_storm_active	O	1	当前窗口帧数风暴激活标志
stat_byte_storm_active	O	1	当前窗口字节数风暴激活标志
1.4 时钟和复位管理
1.4.1 时钟管理
rgmii_eth_strom_filter IP模块需要输入以下时钟：rgmii_rx_clk和clk_125m。
1、rgmii_rx_clk：RGMII接口时钟，用于FPGA对RGMII接口数据的单沿转双沿处理和网络风暴过滤。
2、clk_125m：本地全局时钟。经过PLL生成125Mhz时钟对解析数据进行跨时钟域处理后，用户在该时钟域下进行后续数据处理。
1.4.2 复位管理
sys_rst	：全局复位信号，高电平有效。
rst		：rgmii_to_gmii模块、eth_strom_filter模块复位信号，rst = sys_rst | (~clk_125m_locked) | (~rgmii_rx_clk_locked)
2 rgmii_eth_strom_filter整体设计
2.1 rgmii_eth_strom_filter架构设计
IP架构设计如下所示，程序设计内部例化了以下子模块，它们共同构成完整的数据通路和控制逻辑。

图2 rgmii_eth_strom_filter IP架构设计框图
rgmii_to_gmii模块：rgmii接口到gmii接口转换模块，实现rgmii到gmii的转换。
eth_strom_filter模块：网络风暴过滤模块，该模块位于GMII接收链路后级，用于对接收到的以太网帧进行缓存、判决和过滤。模块能够识别以太网帧中的目的MAC、源MAC、Type和数据字段，并根据目的MAC、源MAC黑白名单、CRC校验结果、重复CRC、帧数风暴和字节数风暴等条件判断当前帧是否允许通过。模块内部包括crc32_d8校验模块、CRC去重表、frameFIFO和描述符FIFO，通过帧按字节输出，丢弃帧进行静默排出。
PHY芯片将采集到的数据作为数据源发送到FPGA，FPGA内的数据流如下：
首先进入rgmii_to_gmii模块，将一个时钟周期内的上升沿和下降沿都采集数据的4-bit输入，转换为8-bit的单沿数据输出。然后进入eth_strom_filter模块，完场以太网帧过滤、风暴检测、CRC去重及有效帧跨时钟域处理输出。主要输入输出接口时序如下所示：

图3 rgmii_eth_strom_filter IP输入输出接口时序图
表2 数据帧格式
同步标志
8字节	前导码7字节
	SFD1字节
以太网首部
14字节	目标MAC地址6字节
	源MAC地址6字节
	网络类型2字节
报文数据
46-1500字节	配置范围为46-1500字节
链路校验
4字节	FCS帧校验4字节
2.2 rgmii_to_gmii模块设计
2.2.1 功能说明
rgmii接口到gmii接口转换模块，实现rgmii到gmii的转换。
2.2.2 接口列表
表3 rgmii_to_gmii模块接口列表
信号	方向	位宽	描述
rst_p	I	1	系统复位,高电平复位
rgmii_rx_clk	I	1	PHY提供的接收时钟(1000Mbps速率下时钟为125MHz，与rgmii_rxd和rgmii_rxdv信号呈中心对齐的关系)
rgmii_rxd	I	4	RGMII数据总线，采用DDR方式传输4个字节
rgmii_rxdv	I	1	RGMII控制信号，上升沿为RX_DV，下降沿为RX_ER
gmii_rx_clk	O	1	与输入时钟同相，用于gmii接口
gmii_rxd	O	8	转换后的GMII字节数据（[3:0]为上升沿数据，[7:4]为下降沿数据）
gmii_rxdv	O	1	GMII接收数据有效（由RGMII上升沿控制位直接得到）
gmii_rxer	O	1	GMII接收错误标志（gmii_rxer_r^gmii_rxdv）
2.2.3 接口时序
IDDR原语采用SAME_EDGE_PIPELINED模式，时序图如下所示：

图4 rgmii_to_gmii模块接口时序图
2.2.4 功能设计
RGMII接收需要例化5个IDDR实现，其中4个用来接收4位的rgmii_rxd信号；1个用来接收rgmii_rxdv信号，rgmii_rx_clk先进入了PLL，由PLL调整到合适的相位之后，再用来捕获rgmii_rxd。

图5 rgmii接口的IDDR数据转换
2.3 eth_storm_filter模块设计
2.3.1 功能说明
eth_storm_filter位于rgmii_to_gmii模块之后，输入侧工作在gmii_rx_clk域，完成前导码/SFD识别、帧字段解析、VLAN标签剥离、目的MAC检查、源MAC ACL过滤、CRC校验、CRC重复帧过滤、窗口风暴判决和统计计数。输出侧工作在本地clk_125m域。
各子模块功能如下：
1、eth_storm_main_fsm：接收侧主状态机，负责GMII帧接收、四字节FCS保留、VLAN剥离、字段解析、目的MAC/ACL/风暴/重复CRC判决，并生成公共frame FIFO和描述符FIFO写入控制。
1.1 eth_storm_multicast_hash：维护64bit可编程组播Hash表，用于目的组播MAC地址查表过滤。
1.1.1 multicast_crc32_d8：对配置的组播MAC地址计算CRC32，生成组播Hash索引。
1.2 fcs_crc32_d8：对SFD后的完整帧进行CRC32计算，用于FCS校验。
1.3 mac_crc32_d8：对当前帧目的MAC计算CRC32，生成组播Hash查表索引。
2、eth_storm_stat：负责窗口计数、epoch翻转、帧时间计数、通过/丢弃统计，以及drop_valid/drop_reason输出。
3、eth_storm_crc_clean：负责CRC去重RAM的复位初始化和窗口翻转后的后台清理，普通读写访问优先于后台清理。
3.1 eth_storm_crc_ram：保存已通过帧的CRC/FCS信息，用于同一窗口内重复帧检测。
4.eth_storm_tx_fsm：负责公共跨时钟FIFO、分类路由、三组二级通道FIFO和三路输出控制，实现GOOSE、SV、Other三类帧独立输出。
4.1 eth_storm_type_router：根据描述符中的pass和eth_type_class字段，将通过帧路由到GOOSE、SV或Other通道；丢弃帧静默排出。
4.2 goose_tx_fsm：GOOSE通道输出状态机，负责GOOSE帧的ready/valid握手和按字节输出。
4.3 sv_tx_fsm：SV通道输出状态机，负责SV帧的ready/valid握手和按字节输出。
4.4 other_tx_fsm：Other通道输出状态机，负责其它类型帧的ready/valid握手和按字节输出。
公共描述符字段为：{desc_pass, desc_len, desc_mac_class, desc_eth_type_class, desc_frame_time}，总宽度53bit。其中desc_len为实际写入公共frame FIFO的字节数；VLAN帧输出时已剥离TPID/TCI，因此desc_len不包含VLAN标签和FCS。

图7 eth_storm_filter模块架构设计框图
2.3.2 接口列表
表4 eth_storm_filter模块接口列表
信号	方向	位宽	描述
参数定义
CLK_FREQ_HZ	P	int	GMII RX 时钟频率，用于计算窗口周期数，125000000
WINDOW_MS	P	int	风暴统计窗口长度，单位ms，10
FRAME_MAX_PER_WIN	P	int	默认窗口最大帧数阈值，运行时配置为0时使用，1000
BYTE_MAX_PER_WIN	P	int	默认窗口最大字节数阈值，运行时配置为0时使用，8000000
MIN_FRAME_BYTES	P	int	最小帧字节数，60
MAX_FRAME_BYTES	P	int	最大帧字节数，1514
CRC_TABLE_DEPTH	P	int	CRC去重表深度，建议2的幂，1024
DESC_DEPTH	P	int	描述符FIFO深度，需要和Vivado FIFO IP一致，32
时钟、复位与配置接口
gmii_rx_clk	I	1	rgmii_to_gmii输出时钟
clk_125m	I	1	Vivado PLL IP生成的本地125MHz输出侧时钟
rst	I	1	高有效异步复位
cfg_filter_en	I	1	总过滤使能，cfg_filter_en=0时目的MAC、ACL、风暴和重复CRC策略不过滤，但CRC/长度/资源类错误仍然生效
cfg_dst_mac_en	I	1	目的MAC检查使能
cfg_local_mac	I	48	本地MAC地址
cfg_allow_broadcast	I	1	允许广播目的MAC，FF:FF:FF:FF:FF:FF
cfg_allow_multicast	I	1	允许组播目的MAC
cfg_multicast_mac	I	48	待加入64 bit组播Hash表的组播MAC地址
cfg_multicast_mac_valid	I	1	上升沿触发一次组播MAC Hash计算并置位对应表项
cfg_multicast_hash_clear	I	1	高有效，清空64 bit组播Hash表
cfg_eth_type_goose	I	16	GOOSE帧EtherType配置值
cfg_eth_type_sv	I	16	SV帧EtherType配置值
cfg_whitelist_en	I	1	白名单总使能，使能后未命中白名单则丢弃
cfg_blacklist_en	I	1	黑名单总使能，命中黑名单则丢弃，优先级高于白名单
cfg_dup_crc_en	I	1	CRC重复帧过滤使能
cfg_frame_storm_en	I	1	帧数风暴过滤使能
cfg_byte_storm_en	I	1	字节数风暴过滤使能
cfg_crc_check_en	I	1	FCS校验使能，为0时仅依赖gmii_rxer和长度合法性
cfg_frame_max_per_win	I	32	运行时帧数阈值，为0时使用默认值
cfg_byte_max_per_win	I	32	运行时字节数阈值，为0时使用默认值
cfg_max_frame_bytes	I	16	运行时单帧最大字节数，为0时使用默认值
cfg_window_ms	I	32	运行时窗口长度，为0时使用默认值
cfg_clear_stats	I	1	统计清零控制
cfg_white*_en	I	1	4条白名单规则使能,*表示0、1、2、3
cfg_white*_mac	I	48	4条白名单源MAC匹配值
cfg_black*_en	I	1	4条黑名单规则使能
cfg_black*_mac	I	48	4条黑名单源MAC匹配值
上游输入接口
gmii_rxdv	I	1	GMII 接收数据有效
gmii_rxd	I	8	GMII 接收数据字节
gmii_rxer	I	1	GMII 接收错误
GOOSE输出通道
goose_frame_ready	I	1	GOOSE 通道下游接收能力指示
goose_frame_valid	O	1	GOOSE 通道过滤后帧数据有效
goose_frame_data	O	8	GOOSE 通道过滤后帧数据
goose_frame_sof	O	1	GOOSE 通道帧首字节标志
goose_frame_eof	O	1	GOOSE 通道帧末字节标志
goose_frame_done	O	1	GOOSE 通道帧输出完成脉冲
goose_frame_len	O	16	GOOSE 通道输出帧长度
goose_mac_class	O	2	GOOSE 通道输出帧 MAC 分类
goose_eth_type_class	O	2	GOOSE 通道输出帧 EtherType 分类
goose_frame_time	O	32	GOOSE 通道输出帧时间标志
SV输出通道
sv_frame_ready	I	1	SV 通道下游接收能力指示
sv_frame_valid	O	1	SV 通道过滤后帧数据有效
sv_frame_data	O	8	SV 通道过滤后帧数据
sv_frame_sof	O	1	SV 通道帧首字节标志
sv_frame_eof	O	1	SV 通道帧末字节标志
sv_frame_done	O	1	SV 通道帧输出完成脉冲
sv_frame_len	O	16	SV 通道输出帧长度
sv_mac_class	O	2	SV 通道输出帧 MAC 分类
sv_eth_type_class	O	2	SV 通道输出帧 EtherType 分类
sv_frame_time	O	32	SV 通道输出帧时间标志
Other输出通道
other_frame_ready	I	1	Other 通道下游接收能力指示
other_frame_valid	O	1	Other 通道过滤后帧数据有效
other_frame_data	O	8	Other 通道过滤后帧数据
other_frame_sof	O	1	Other 通道帧首字节标志
other_frame_eof	O	1	Other 通道帧末字节标志
other_frame_done	O	1	Other 通道帧输出完成脉冲
other_frame_len	O	16	Other 通道输出帧长度
other_mac_class	O	2	Other 通道输出帧 MAC 分类
other_eth_type_class	O	2	Other 通道输出帧 EtherType 分类
other_frame_time	O	32	Other 通道输出帧时间标志
丢弃事件与统计接口
drop_valid	O	1	丢弃事件单周期脉冲
drop_reason	O	16	当前丢弃原因
stat_pass_cnt	O	32	通过帧累计计数
stat_drop_crc_err_cnt	O	32	CRC错误、gmii_rxer或帧长度不足丢弃计数
stat_drop_dup_crc_cnt	O	32	重复CRC丢弃计数
stat_drop_frame_storm_cnt	O	32	帧数风暴丢弃计数
stat_drop_byte_storm_cnt	O	32	字节数风暴丢弃计数
stat_drop_buf_full_cnt	O	32	frame FIFO满或描述符FIFO满丢弃计数
stat_drop_len_err_cnt	O	32	长度超限或长度异常丢弃计数
stat_drop_blacklist_cnt	O	32	黑名单命中丢弃计数
stat_drop_not_white_cnt	O	32	白名单未命中丢弃计数
stat_drop_dst_miss_cnt	O	32	目的MAC未匹配丢弃计数
stat_win_frame_cnt	O	32	当前窗口计入的帧数
stat_win_byte_cnt	O	32	当前窗口计入数据帧字节数
stat_last_drop_reason	O	16	最近一次丢弃原因
stat_frame_storm_active	O	1	当前窗口帧数风暴激活标志
stat_byte_storm_active	O	1	当前窗口字节数风暴激活标志
表5 丢弃原因编码
	丢弃原因编码
值	定义	含义
16'h0001	DROP_FRAME_ERR	CRC错误、gmii_rxer或帧长度不足
16'h0002	DROP_DUP_CRC	同一窗口epoch内CRC表命中
16'h0004	DROP_FRAME_STORM	当前窗口帧数超过阈值
16'h0008	DROP_BYTE_STORM	当前窗口字节数超过阈值
16'h0010	DROP_BUF_FULL	frame FIFO满或描述符FIFO满
16'h0020	DROP_LEN_ERR	数据帧长度超限或小于最小长度
16'h0040	DROP_BLACKLIST	源MAC命中黑名单
16'h0080	DROP_NOT_WHITE	白名单使能但源MAC未命中任何白名单
16'h0100	DROP_DST_MISS	目的MAC不是本地、广播或允许的组播
表6 MAC 分类编码
值	2'b00	2'b01	2'b10	2'b11
含义	单播	广播	组播	保留/数据无效

表7 Ethtype 分类编码
值	2'b00	2'b01	2'b10	2'b11
含义	其它	GOOSE	SV	保留/数据无效

2.3.3 接口时序

图8 正常通过帧时序
正常通过帧时，输入侧在gmii_rx_clk域首先检测到gmii_rxdv拉高，状态机由IDLE进入PREAMBLE，并在前导码之后识别到SFD，进入RECV状态接收当前以太网帧。接收过程中，模块对SFD之后的DA、SA、TYPE、PAYLOAD、FCS进行CRC计算，同时通过四字节尾部保留机制只将DA、SA、TYPE、PAYLOAD写入frame FIFO，不写入末尾FCS。帧结束后，输入状态机依次进入ACL检查、CRC表读取、CRC比较、统一判决和提交状态。当CRC正确、目的MAC匹配、ACL通过、未触发风暴且CRC未重复时，模块在提交阶段写入通过描述符，统计通过计数加1。然后本地clk_125m域的输出状态机从描述符FIFO读取该帧描述符，进入DRAIN状态，在m_frame_ready有效时从frame FIFO顺序读出并输出帧数据，输出首字节时拉高m_frame_sof，输出最后一个字节时拉高m_frame_eof和m_frame_done，同时给出帧长度、MAC分类和帧时间标志。

图9 帧风暴过滤时序
图9表示帧风暴过滤场景下的接收和丢弃过程。输入状态机与正常通过帧相同。由于当前窗口帧计数已经达到阈值，本帧加入后超过阈值，因此在W_DECIDE/W_COMMIT阶段判定为帧风暴丢弃，drop_valid拉高一个周期，丢弃原因为帧风暴，帧风暴丢弃计数加1，窗口帧计数继续累加，帧风暴状态标志拉高。随后本地clk_125m域输出状态机读取该帧描述符，进入DRAIN状态对frame FIFO中对应长度的数据进行静默排出，不拉高m_frame_valid、m_frame_sof、m_frame_eof和m_frame_done，该帧不会向下游输出有效数据。
2.3.4 功能设计
2.3.4.1功能详细描述
(1) frame FIFO顺序缓存
四字节hold0~hold3路径只用于延迟释放数据，从而剥离最后4字节FCS，并在VLAN帧场景下删除TPID/TCI四字节。模块在识别到SFD后进入RECV状态，后续输入字节依次进入hold0~hold3四级保留寄存器。开始阶段hold_cnt从0递增到4，此时只填充保留寄存器，不向frame FIFO写入数据；当hold_cnt达到4后，每收到一个新字节，最早进入的hold0就可以确认不是最后4字节FCS，因此被释放出来作为有效帧数据写入frame FIFO，同时参与目的MAC、源MAC、Type等字段解析。CRC计算路径与FIFO写入路径不同，CRC直接对SFD后的输入字节计算，因此包含DA、SA、TYPE、PAYLOAD、FCS；而frame FIFO只写入从hold0延迟释放出的DA、SA、TYPE、PAYLOAD，不写入最后保留的FCS。帧结束时，hold0~hold3中剩余的4个字节即为接收到的FCS字段，只用于CRC重复校验，不进入frame FIFO。

图10 四字节延迟保留时序图
正常接收状态W_RECV下，如果描述符FIFO未满、frame FIFO未满，并且当前帧长度没有超限，则将hold0写入frame FIFO，同时递增实际写入长度desc_len。当资源不足或长度超限时，状态机进入W_DISCARD_RECV，停止继续写入frame FIFO，但仍继续接收直到gmii_rxdv拉低。若某帧在接收中途进入W_DISCARD_RECV，则描述符中的desc_len为进入丢弃接收前已经写入frame FIFO的字节数，输出侧按该长度静默排出，避免后续通过帧错位。
eth_storm_frame_fifo使用如下配置：
配置项	建议值
InterfaceType	Native
FIFO Implementation	Independent Clocks Block RAM
DataWidth	8
Depth	4096
ReadMode	FWFT
(2) VLAN 802.1Q 标签处理
该模块支持802.1Q VLAN标签解析并过滤。状态机在接收字节计数等于12、13时读取TPID。若为16'h8100，则说明该网络帧中带有802.1Q VLAN标签，接收字节计数等于16、17解析真实EtherType。同时写frame FIFO时，wr_len_seen 处于12~15的TPID/TCI四字节不会写入，因此输出帧被还原为不带VLAN标签的DA/SA/EtherType/Payload格式。
(3) 描述符队列
公共描述符FIFO为异步FIFO，写侧工作在gmii_rx_clk域，读侧工作在clk_125m域。描述符宽度为53bit，字段如下：
字段	位宽	含义
desc_pass	1	1表示通过输出，0表示静默排出
desc_len	16	本帧实际写入frame FIFO的字节数
desc_mac_class	2	当前帧MAC分类标志，00单播、01广播、10组播、11保留
desc_eth_type_class	2	当前帧Ethtype分类标志，00其他、01 GOOSE、10 SV、11保留
desc_frame_time	32	当前帧时间标志，在检测到SFD时锁存计时器值
公共描述符FIFO与公共frame FIFO的写入顺序保持一致。clk_125m域的eth_storm_type_router先读取公共描述符，再按desc_len从公共frame FIFO读出对应字节。若desc_pass=0，router只静默排出数据；若desc_pass=1，则按desc_eth_type_class将完整帧数据写入GOOSE、SV或Other二级data FIFO，并在最后一个字节写入后再提交对应二级desc FIFO，保证通道内数据与描述符对齐。
eth_storm_desc_fifo使用如下配置：
配置项	建议值
InterfaceType	Native
FIFO Implementation	Independent Clocks Block RAM
Data Width	53
Depth	32
ReadMode	FWFT
(3) CRC校验设计
CRC校验采用crc32_d8子模块完成，CRC初始化发生在识别到合法SFD的时刻，计算使能覆盖W_RECV和W_DISCARD_RECV中的gmii_rxdv有效字节，因此即使当前帧因FIFO满或长度超限进入W_DISCARD_RECV，也会继续计算到帧尾。cfg_crc_check_en=1时，帧结束后的fcs_crc_result必须等于固定残余值32'h2144_DF1C；cfg_crc_check_en=0时，FCS校验结果不作为丢弃条件。
(4) W_DISCARD_RECV丢弃接收
W_DISCARD_RECV用于处理接收过程中的资源不足或长度超限场景。当模块在等待SFD后发现描述符FIFO满、frame FIFO满，或者在接收过程中发现当前帧长度超过最大允许值时，输入状态机会进入该状态。
进入W_DISCARD_RECV后，模块不再向frame FIFO写入当前帧数据，避免占用缓存资源；但仍会继续接收GMII字节，直到gmii_rxdv拉低表示当前帧结束。该状态下会继续统计SFD后输入的字节数量，并继续维护四字节尾部保留机制。
(5) 目的MAC与ACL过滤
目的MAC过滤用于判断当前以太网帧是否属于允许接收范围。目的MAC准入包括本地单播、广播和可编程组播Hash表三类：
类型	匹配条件	MAC分类
本地单播	dec_dst_mac==cfg_local_mac	00
广播	cfg_allow_broadcast=1且目的MAC为FF:FF:FF:FF:FF:FF	01
组播	cfg_allow_multicast=1，目的MAC CRC[31:26]对应的Hash表bit已置1	10
组播Hash表由eth_storm_multicast_hash维护。软件通过cfg_multicast_mac输入待允许的组播MAC，并对cfg_multicast_mac_valid产生上升沿；模块对该MAC的6个字节计算CRC32，并将crc_result[31:26]对应的Hash表bit置1。cfg_multicast_hash_clear高有效时清空整个64bit Hash表。
目的MAC是否参与丢弃判决由cfg_filter_en和cfg_dst_mac_en共同控制：
cfg_filter_en=1且cfg_dst_mac_en=1：目的MAC未命中上述任何准入规则时，在帧尾统一判决中产生DROP_DST_MISS。
cfg_filter_en=0或cfg_dst_mac_en=0：目的MAC未命中不导致丢弃，但MAC分类仍按目的地址类型输出。
类型	匹配条件	Ethtype分类
GOOSE	dec_eth_type == cfg_eth_type_goose	01
SV	dec_eth_type == cfg_eth_type_sv	10
Other	未命中上述两类	00
ACL源端过滤保持4条白名单和4条黑名单规则。黑名单在统一判决中优先于白名单；当cfg_filter_en=1且cfg_blacklist_en=1时，源MAC命中任意已使能黑名单规则产生DROP_BLACKLIST；当cfg_filter_en=1且cfg_whitelist_en=1时，源MAC未命中任何已使能白名单规则产生DROP_NOT_WHITE。
(6) CRC去重表
CRC去重表采用直接映射结构。模块将当前帧32bit CRC的高16bit与低16bit异或折叠得到Hash值，并截取低位作为表索引。每个表项保存{valid , epoch , crc}，即有效标志、窗口标识和完整CRC。只有表项有效、窗口标识一致、完整CRC相同这三个条件同时满足时，才判定为重复帧。最终判定通过的帧才会写入CRC去重表，丢弃帧不会写入，因此不会影响后续正常帧的重复判断。若同一索引已有记录，新通过帧会覆盖旧记录。
CRC去重只在同一统计窗口内生效。窗口翻转时模块切换窗口标识，旧窗口表项不再参与当前窗口匹配。后台清表逻辑会在窗口切换后逐项扫描CRC表，清除旧窗口记录，保留当前窗口记录。清表优先级低于正常判重读写，避免RAM端口冲突和误清新写入表项。系统复位后，CRC表会先执行强制清零。在强制清零完成前，CRC去重功能不参与有效判定，避免RAM初值不确定导致误判。
CRC Hash结构存在表项覆盖问题。当不同CRC经过Hash后得到相同表索引时，新写入的CRC会覆盖原有记录。由于表项保存完整CRC，不会将不同帧误判为重复帧；但被覆盖的旧CRC后续再次出现时，可能无法再被识别为重复帧，如图11所示。该问题属于直接映射结构的固有限制，可通过增大CRC表深度降低覆盖概率。

图11哈希冲突覆盖问题示例
(7) 风暴窗口统计
模块在gmii_rx_clk域统计窗口计数器。每到达固定窗口周期最后一个clk窗口翻转，当前窗口内的帧数、字节数和风暴激活标志清零，并进入新窗口重新统计。
风暴阈值比较固定采用超过阈值丢弃。帧数风暴使用frame_cnt_next>eff_frame_max判定；字节数风暴使用byte_cnt_next>eff_byte_max判定。
窗口统计更新条件由dec_count_window控制。当前代码中，FCS/帧错误不计入窗口；目的MAC未匹配、黑名单命中和白名单未命中也不计入窗口。资源类错误、长度类错误、风暴类丢弃和重复CRC丢弃在满足基础条件时仍可计入窗口。
(8) 帧尾判决优先级
帧尾统一判决在 W_DECIDE 状态完成，W_DECIDE 只锁存组合判决结果；W_COMMIT 在 desc FIFO 未满时写入描述符，并触发统计、drop_valid/drop_reason 和 CRC 去重表写入。若 W_COMMIT 阶段 desc FIFO 满，状态机会停留在 W_COMMIT，直到可提交为止。
统一判决只输出一个最终结果：
dec_pass=1：帧通过，desc_pass=1，drop_valid 不产生。
dec_pass=0：帧丢弃，desc_pass=0，dec_drop_reason 只取最高优先级命中的单一原因。
优先级	RTL判决条件	使能约束	丢弃原因
1	gmii_rxer曾有效，或帧长度小于MIN_FRAME_BYTES，或cfg_crc_check_en=1且CRC残余值不等于32'h2144_DF1C	gmii_rxer和最小长度始终生效；FCS校验受cfg_crc_check_en控制	DROP_CRC_ERR
16'h0001
2	目的MAC检查使能且dec_meta_valid=1，目的MAC未命中本地单播、允许广播或组播Hash表	cfg_filter_en=1
cfg_dst_mac_en=1	DROP_DST_MISS
16'h0100
3	源MAC命中任意已使能黑名单规则	cfg_filter_en=1
cfg_blacklist_en=1	DROP_BLACKLIST
16'h0040
4	白名单总使能且源MAC未命中任意已使能白名单规则	cfg_filter_en=1
cfg_whitelist_en=1	DROP_NOT_WHITE
16'h0080
5	接收过程中frameFIFO满，或接收/提交过程中descFIFO满	始终生效	DROP_BUF_FULL
16'h0010
6	长度超过cfg_max_frame_bytes /默认MAX_FRAME_BYTES	始终生效	DROP_LEN_ERR
16'h0020
7	当前帧计入窗口后帧数超过阈值，或当前窗口帧数风暴状态已激活	cfg_filter_en=1 cfg_frame_storm_en=1	DROP_FRAME_STORM
16'h0004
8	当前帧计入窗口后字节数超过阈值，或当前窗口字节数风暴状态已激活	cfg_filter_en=1 cfg_byte_storm_en=1	DROP_BYTE_STORM
16'h0008
9	CRC/FCS去重表在同一active_epoch内命中相同FCS值	cfg_filter_en=1
cfg_dup_crc_en=1
crc_init_done=1 	DROP_DUP_CRC
16'h0002
10	以上条件均不满足	-	通过，desc_pass=1
1、该优先级是RTL中else-if链的实际顺序，因此同一帧即使同时满足多个丢弃条件，也只会上报最高优先级的一个drop_reason。
2、cfg_filter_en=0时，第2、3、4、7、8、9项策略过滤旁路；第1、5、6项硬错误仍生效。
3、目的MAC/ACL的优先级高于资源不足和长度超限，这是当前RTL的实际行为。若文档希望表达“硬错误完全优先于策略错误”，需同步修改RTL；否则方案应按本表描述。
4、窗口帧数/字节数只对dec_count_window_q=1的帧更新。实际条件为：CRC基础检查通过，且未被目的MAC、黑名单、白名单过滤排除。资源不足、长度超限、风暴帧和重复帧仍可能计入窗口统计。
5、只有最终通过的帧才写入CRC/FCS去重表；重复帧自身不会更新表项。
(9) 输出通过与静默排出
输出侧由eth_storm_tx_fsm完成，包含两级缓存和三路输出：
1.一级公共FIFO：eth_storm_frame_fifo和eth_storm_desc_fifo为异步FIFO，写侧为gmii_rx_clk，读侧为clk_125m，用于跨时钟传递接收侧写入的帧数据和53bit描述符。
2.类型路由：eth_storm_type_router在clk_125m域读取公共描述符。若desc_pass=0，则按desc_len从公共frameFIFO静默排出，不写入任何通道FIFO；若desc_pass=1，则根据desc_eth_type_class选择目标通道：01路由到GOOSE，10路由到SV，其他值路由到Other。
3.二级通道FIFO：每个通道包含dataFIFO和descFIFO。router先将完整帧数据写入目标dataFIFO，最后一个字节写入后才写入目标descFIFO，保证通道内描述符不会早于数据到达。
4.三路输出FSM：三个eth_storm_channel_tx_fsm分别从本通道二级FIFO中取描述符和数据，按各自的frame_ready输出frame_valid/ frame_data/ frame_sof/ frame_eof/ frame_done/ frame_len/ mac_class/ eth_type_class/ frame_time。
路由拥塞策略：当接收侧判定通过的帧目标通道dataFIFOfull/prog_full，或目标通道descFIFOfull时，router不等待该通道释放空间，而是从公共FIFO静默排出该帧，不写入任何二级FIFO。该策略避免单一路拥塞长期阻塞其它业务类型，但该路由级静默丢弃发生在接收侧pass/drop判决之后，不产生drop_valid/drop_reason，也不增加现有接收侧丢弃统计计数。若系统要求统计该类丢弃，需要新增router级丢弃计数接口和文档说明。
2.3.4.2状态机设计
本模块主要包含两个状态机：
1.输入接收/判决状态机w_state：接收上游frame，锁存帧级数据，执行ACL、CRC校验、CRC去重、风暴判决，并写入描述符。
2.输出/排出状态机o_state：按描述符顺序从frame FIFO读出数据，对通过帧输出，对丢弃帧静默排出。
4.2.1输入接收/判决状态机

图12输入接收/判决状态机
状态	含义	进入条件	主要操作
W_IDLE	等待新GMII帧	复位后或上一帧提交完成	清除当前帧现场；检测gmii_rxdv
W_PREAMBLE	等待SFD	gmii_rxdv=1	检测前导码；若SFD到来且资源不足，则进入W_DISCARD_RECV
W_RECV	接收并缓存当前帧	SFD后资源可用	解析FCS；写frame FIFO；解析DA / SA / Type；计算CRC
W_DISCARD_RECV	资源不足或长度超限后的接收丢弃	desc_fifo_full、frame_fifo_full或长度超限	不再写FIFO，只统计输入字节数量，等待gmii_rxdv拉低
W_ACL_CHK	目的MAC与ACL匹配	帧接收结束	计算dst_mac_hit、acl_white_hit、acl_black_hit
W_CRC_RD	读取CRC去重表	ACL检查完成	使用dec_crc_idx读取crc_mem
W_CRC_CHK	CRC表项比较	CRC表项读出后一拍	比较valid/epoch/crc_tag，生成crc_dup_hit_q
W_DECIDE	组合判决结果打一拍	CRC重复检查完成	将dec_pass/dec_drop_reason、窗口计数值和风暴状态寄存
W_COMMIT	提交判决	W_DECIDE后一拍	更新统计；通过帧写入CRC表；产生drop_valid/drop_reason；推入描述符；返回W_IDLE
4.2.2 输出/排出状态机
输出/排出状态机工作在clk_125m时钟域。

图13输出状态机
状态	含义	进入条件	主要操作
O_IDLE	等待描述符	复位后或当前帧完成	若描述符FIFO非空，读取{desc_pass, desc_len, desc_mac_class, desc_frame_time}，desc_len!=0时进入O_DRAIN
O_DRAIN	根据描述符从frame FIFO读数据	描述符装载完成	desc_pass=1时受m_ frame _ready控制输出；
desc_pass=0时不等待m_ frame _ready，直接静默排出
