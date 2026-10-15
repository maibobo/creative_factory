# Packet Stream-AXI4-Full DMA writer IP设计方案V0.1

- Category: `ethernet`
- Source: `E:\eth_storm_project\Packet Stream-AXI4-Full DMA writer IP设计方案V0.1.docx`
- SHA-256: `c195f69ea6ad77e5729f4bd3b0f80ecb928f8b23331dffd4b9463e9eca67671d`
- Extractor: `python-docx+zip-structure-check`
- Tags: `dma, ethernet, rgmii, storm-filter`
- Duplicate sources:
  - none

| 产品名称Product name | 密级Confidentiality level |

| RTDS/以太网 IP |  |

| 产品版本Product version | Total 23 pages 共23页 |

| V0.1 | Total 23 pages 共23页 |


Packet Stream–AXI4-Full DMA Writer IP设计方案

| Prepared by 拟制 | 霍奕轩 | Date 日期 | 2026-7-20 |

| Reviewed by 评审人 |  | Date 日期 |  |

| Approved by 批准 |  | Date 日期 |  |


Revision Record 修订记录

| Revision Version 修订版本 | Change Description 修改描述 | Author 作者 | Date 日期 |

| 0.1 | 完成初稿 | 霍奕轩 | 26.8.14 |


目  录

Revision Record 修订记录	2

目  录	3

1 概述	5

1.1 设计背景	5

1.2 设计架构	5

1.3 接口列表	6

1.4 时钟和复位管理	10

1.4.1 时钟管理	10

1.4.2 复位管理	10

1.5 存储布局与描述符格式	10

2 Packet Stream_AXI4-Full DMA Writer整体设计	11

2.1 Packet Stream_AXI4-Full DMA Writer架构设计	11

2.2 eth_classified_frame_arbiter 模块设计	12

2.2.1功能说明	12

2.2.2 接口列表	12

2.2.3 功能设计	13

2.3 eth_classified_frame_ring_manager模块设计	13

2.3.1 功能说明	13

2.3.2 接口列表	13

2.3.3 接口时序	14

2.3.4 功能设计	15

2.4 eth_classified_frame_data_packer 模块设计	15

2.4.1功能说明	15

2.4.2 接口列表	15

2.4.3 接口时序	16

2.4.4 功能设计	16

2.5 eth_classified_frame_desc_builder 模块设计	17

2.5.1功能说明	17

2.5.2 接口列表	17

2.5.3 接口时序	18

2.5.4 功能设计	18

2.6 eth_classified_frame_s2mm_ctrl 模块设计	18

2.6.1功能说明	18

2.6.2 接口列表	18

2.6.3 接口时序	20

2.6.4 功能设计	21

2.7 AXI DataMover模块设计	21

2.7.1 功能说明	21

2.7.2 接口列表	21

2.7.3 接口时序	23

2.7.4 功能设计	23

1 概述

1.1 设计背景

Packet Stream–AXI4-Full DMA Writer用于将上游网络报文分类/过滤逻辑输出的GOOSE、SV和OTHER三类完整以太网报文写入外部BRAM/DDR存储空间。上游每个通道提供一组8bit报文字节FIFO和一组53bit描述符FIFO。本模块完成帧选择、环形槽位管理、字节打包、DataMover命令生成、写状态检查、描述符发布以及写指针提交。模块采用“先写报文数据、再写描述符、最后提交写指针”的事务顺序。

三类报文拥有相互独立的数据区、描述符区、读指针和写指针。默认每个报文槽位固定占用1536Byte。错误处理采用记录并自动恢复策略，错误信息通过错误状态和错误计数器输出，控制状态机不会长期停留在错误状态。

模块核心功能如下：

1.对三路完整报文进行帧级固定优先级仲裁，优先级为SV>GOOSE>OTHER。

2.为获胜通道申请一个环形槽位，计算data_addr和desc_addr。

4.控制8bit FWFT数据FIFO按真实帧长读取，并打包为64bit AXI4-Stream。

5.生成72bit DataMover S2MM命令，先完成报文数据写入，再完成8Byte描述符写入。

6.检查DataMover状态OKAY位、错误位和TAG，成功提交槽位，失败中止槽位并自动恢复。

7.维护三路写指针和满标志，并输出成功帧计数、最近地址及错误统计。

1.2 设计架构

顶层Packet Stream_AXI4-Full DMA Writer位于分类FIFO与AXI DataMover之间，本地逻辑按仲裁/解析—环形槽位—数据打包—S2MM时序控制—描述符构造分工。DataMover再将72bit命令流和64bit数据流转换为AXI4-Full写事务。系统集成时，m_axi接口可连接RAM IP或MIG IP，最终访问BRAM/DDR。

上游分别设置GOOSE、SV和Other三组数据FIFO与描述符FIFO，控制器通过对应的data_rd_en和desc_rd_en信号读取报文字节及描述符，并采用GOOSE、SV、Other的固定优先级完成帧级仲裁。选中报文后，控制器根据数据区基地址、描述符区基地址及环形写指针计算存储地址，并将8 bit字节流打包为64 bit AXI4-Stream数据。每个报文槽位固定为1536 Byte，但DataMover的BTT使用实际帧长，未使用空间不会自动补零。控制器先写报文数据，确认成功后再写8 Byte描述符，最后更新写指针。AXI DataMover将命令流和数据流转换为AXI4-Full写事务，并通过状态接口向控制器返回写入结果。

图1系统顶层设计框图-

1.3 接口列表

表1 rgmii_eth_storm_filter IP接口列表

| 参数 | 默认值 | 说明 |

| DESC_W | 53 | 输入分类描述符宽度 |

| CHANNEL_DEPTH | 32 | cfg_ring_depth=0 时采用的默认环形深度 |

| FRAME_SLOT_BYTES | 1536 | 每个报文数据槽位固定占用字节数 |

| DESC_BYTES | 8 | 输出描述符固定占用字节数 |

| TAG_DATA | 4'h1 | 报文数据写命令TAG |

| TAG_DESC | 4'h2 | 描述符写命令TAG |


| 信号 | 方向 | 位宽 | 描述 |

| 时钟、复位和配置接口 | 时钟、复位和配置接口 | 时钟、复位和配置接口 | 时钟、复位和配置接口 |

| clk | I | 1 | 系统时钟，125MHz |

| rst | I | 1 | 系统高有效复位 |

| clear_error | I | 1 | 清除各类错误及错误计数 |

| cfg_goose_data_base_addr | I | 32 | GOOSE数据区基地址 |

| cfg_sv_data_base_addr | I | 32 | SV数据区基地址 |

| cfg_other_data_base_addr | I | 32 | OTHER数据区基地址 |

| cfg_goose_desc_base_addr | I | 32 | GOOSE描述符区基地址 |

| cfg_sv_desc_base_addr | I | 32 | SV描述符区基地址 |

| cfg_other_desc_base_addr | I | 32 | OTHER描述符区基地址 |

| cfg_ring_depth | I | 32 | 环形缓冲区深度，低31bit有效；配置为0时使用默认值32 |

| 环形缓冲区接口 | 环形缓冲区接口 | 环形缓冲区接口 | 环形缓冲区接口 |

| goose_rd_ptr | I | 32 | GOOSE消费者读指针，格式{wrap,index[30:0]} |

| sv_rd_ptr | I | 32 | SV消费者读指针 |

| other_rd_ptr | I | 32 | OTHER消费者读指针 |

| goose_wr_ptr | O | 32 | GOOSE生产者写指针 |

| sv_wr_ptr | O | 32 | SV生产者写指针 |

| other_wr_ptr | O | 32 | OTHER生产者写指针 |

| goose_ring_full | O | 1 | GOOSE环形区满标志 |

| sv_ring_full | O | 1 | SV环形区满标志 |

| other_ring_full | O | 1 | OTHER环形区满标志 |

| GOOSE分类FIFO接口 | GOOSE分类FIFO接口 | GOOSE分类FIFO接口 | GOOSE分类FIFO接口 |

| goose_data_dout | I | 8 | GOOSE FWFT数据FIFO当前字节 |

| goose_data_empty | I | 1 | GOOSE数据FIFO空标志 |

| goose_data_rd_en | O | 1 | GOOSE数据FIFO读使能 |

| goose_desc_dout | I | 53 | GOOSE描述符FIFO当前条目 |

| goose_desc_empty | I | 1 | GOOSE描述符FIFO空标志 |

| goose_desc_rd_en | O | 1 | GOOSE描述符FIFO读使能 |

| SV分类FIFO接口 | SV分类FIFO接口 | SV分类FIFO接口 | SV分类FIFO接口 |

| sv_data_dout | I | 8 | SVFWFT数据FIFO当前字节 |

| sv_data_empty | I | 1 | SV数据FIFO空标志 |

| sv_data_rd_en | O | 1 | SV数据FIFO读使能 |

| sv_desc_dout | I | 53 | SV描述符FIFO当前条目 |

| sv_desc_empty | I | 1 | SV描述符FIFO空标志 |

| sv_desc_rd_en | O | 1 | SV描述符FIFO读使能 |

| OTHER分类FIFO接口 | OTHER分类FIFO接口 | OTHER分类FIFO接口 | OTHER分类FIFO接口 |

| other_data_dout | I | 8 | OTHERFWFT数据FIFO当前字节 |

| other_data_empty | I | 1 | OTHER数据FIFO空标志 |

| other_data_rd_en | O | 1 | OTHER数据FIFO读使能 |

| other_desc_dout | I | 53 | OTHER描述符FIFO当前条目 |

| other_desc_empty | I | 1 | OTHER描述符FIFO空标志 |

| other_desc_rd_en | O | 1 | OTHER描述符FIFO读使能 |

| AXI4-Full写接口 | AXI4-Full写接口 | AXI4-Full写接口 | AXI4-Full写接口 |

| m_axi_awaddr | O | 32 | 写地址 |

| m_axi_awlen | O | 8 | 突发长度减1 |

| m_axi_awsize | O | 3 | 每拍字节数编码 |

| m_axi_awburst | O | 2 | 突发类型 |

| m_axi_awprot | O | 3 | 保护属性 |

| m_axi_awcache | O | 4 | Cache属性 |

| m_axi_awuser | O | 4 | 用户侧带信号 |

| m_axi_awvalid | O | 1 | 写地址有效 |

| m_axi_awready | I | 1 | 写地址接收就绪 |

| m_axi_wdata | O | 64 | 写数据 |

| m_axi_wstrb | O | 8 | 写字节选通 |

| m_axi_wlast | O | 1 | 突发最后一拍 |

| m_axi_wvalid | O | 1 | 写数据有效 |

| m_axi_wready | I | 1 | 写数据接收就绪 |

| m_axi_bresp | I | 2 | 写响应 |

| m_axi_bvalid | I | 1 | 写响应有效 |

| m_axi_bready | O | 1 | 写响应接收就绪 |

| 运行状态与错误统计接口 | 运行状态与错误统计接口 | 运行状态与错误统计接口 | 运行状态与错误统计接口 |

| busy | O | 1 | S2MM控制器状态机不在S_IDLE时为1 |

| frame_done_pulse | O | 1 | 数据和描述符均成功后，提交槽位时产生单周期脉冲 |

| error | O | 1 | 粘滞错误标志；发生错误后保持为1，clear_error清零 |

| error_pulse | O | 1 | 每次检测到错误时产生一个时钟周期脉冲 |

| error_code | O | 8 | 最近一次错误码；clear_error清零 |

| error_count | O | 32 | 累计错误次数，饱和计数 |

| param_error_count | O | 32 | 参数错误累计次数，饱和计数 |

| tag_mismatch_count | O | 32 | DataMover状态TAG不匹配累计次数，饱和计数 |

| data_status_error_count | O | 32 | 数据写状态异常累计次数，饱和计数 |

| desc_status_error_count | O | 32 | 描述符写状态异常累计次数，饱和计数 |

| frame_count | O | 32 | 成功提交帧数，饱和计数 |

| last_data_addr | O | 32 | 最近一次被接收描述符对应的数据目标地址计算值 |

| last_desc_addr | O | 32 | 最近一次被接收描述符对应的描述符目标地址计算值 |

| current_channel | O | 2 | 1=GOOSE，2=SV，3=OTHER |

| datamover_s2mm_err | O | 1 | AXI DataMover S2MM错误汇总直接输出 |

| s2mm_wr_xfer_cmplt | O | 1 | AXI DataMover内存侧写传输完成指示直接输出 |


1.4 时钟和复位管理

1.4.1 时钟管理

该模块为单时钟域。clk同时驱动arbiter、ring_manager、data_packer、s2mm_ctrl以及axi_datamover_rx的m_axi_s2mm_aclk和m_axis_s2mm_cmdsts_awclk。

1.4.2 复位管理

rst为高有效复位。本地三个时序模块ring_manager、data_packer和s2mm_ctrl在rst有效时同步清零内部状态、写指针、打包缓存、统计计数和状态输出。DataMover低有效复位端m_axi_s2mm_aresetn与m_axis_s2mm_cmdsts_aresetn连接~rst。

1.5 存储布局与描述符格式

每个通道具有独立的数据区和描述符区。同一帧的数据和描述符使用相同entry_index；ring_manager根据当前写指针低31 bit计算条目地址。

data_addr = channel_data_base + entry_index × FRAME_SLOT_BYTES

desc_addr = channel_desc_base + entry_index × DESC_BYTES

默认配置下FRAME_SLOT_BYTES = 1536、DESC_BYTES = 8。DataMover数据写命令的BTT等于真实frame_len，描述符写命令BTT固定为8。

表3 输入分类描述符位域

| 位域 | 字段 | 说明 |

| [52] | valid | 1 表示该描述符包含一个待处理完整报文 |

| [51:36] | frame_len | 报文真实字节长度 |

| [35:34] | mac_class | MAC 分类：00 单播，01 广播，10 组播，11 非法/保留 |

| [33:32] | ethtype_class | TYPE分类：00 Other，01 GOOSE，10 SV，11 非法/保留 |

| [31:0] | timestamp | 时间戳 |


表4 输出软件描述符位域

| 位域 | 字段 | 说明 |

| [63] | valid | 固定为 1；只有数据写状态成功后才进入描述符写流程 |

| [62:61] | mac_class | MAC 分类：00 单播，01 广播，10 组播，11 非法/保留 |

| [60:48] | reserved | 固定为0 |

| [47:32] | frame_len | 当前帧真实长度 |

| [31:0] | timestamp | 当前帧时间戳 |


2 Packet Stream–AXI4-Full DMA Writer整体设计

2.1 Packet Stream–AXI4-Full DMA Writer架构设计

Packet Stream_AXI4-Full DMA Writer仅负责模块例化、信号互联和DataMover外部AXI端口导出。顶层实例化arbiter、ring_manager、data_packer、desc_builder、s2mm_ctrl和axi_datamover_rx六个功能块。

图2 Packet Stream–AXI4-Full DMA Writer IP架构设计框图

表5 顶层模块分工

| 模块 | 主要职责 |

| eth_classified_frame_arbiter | 根据环形满状态和描述符FIFO状态形成帧请求，选择通道并解析输入描述符 |

| eth_classified_frame_ring_manager | 维护三路写指针和满标志，完成地址计算、commit/abort |

| eth_classified_frame_data_packer | 将8bit FWFT数据FIFO读取准确frame_len字节并打包为64bit AXI4-Stream |

| eth_classified_frame_desc_builder | 组合生成64bit软件可见输出描述符 |

| eth_classified_frame_s2mm_ctrl | 参数检查、槽位申请、DataMover命令/数据/状态控制、提交与错误恢复 |

| axi_datamover_rx | 将命令/数据流转换为AXI4-Full写事务 |


2.2 eth_classified_frame_arbiter 模块设计

2.2.1功能说明

eth_classified_frame_arbiter对GOOSE、SV和OTHER三路描述符进行有效性检查和固定优先级仲裁，综合描述符FIFO空状态、描述符有效位及环形区满状态选择可处理报文，解析并输出获胜通道、报文长度、时间戳和原始描述符，并通过frame_valid/frame_ready握手在接收成功时产生对应通道的描述符FIFO读使能。

2.2.2 接口列表

表3模块接口列表

| 信号 | 方向 | 位宽 | 描述 |

| clk | I | 1 | 当前组合仲裁未使用，保留用于后续注册化升级 |

| rst | I | 1 | 当前组合仲裁未使用 |

| goose_ring_full | I | 1 | GOOSE环形区满状态 |

| sv_ring_full | I | 1 | SV环形区满状态 |

| other_ring_full | I | 1 | OTHER环形区满状态 |

| goose_desc_dout | I | 53 | GOOSE描述符FIFO当前输出 |

| goose_desc_empty | I | 1 | GOOSE描述符FIFO空 |

| goose_desc_rd_en | O | 1 | GOOSE描述符读取使能 |

| sv_desc_dout | I | 53 | SV描述符FIFO当前输出 |

| sv_desc_empty | I | 1 | SV描述符FIFO空 |

| sv_desc_rd_en | O | 1 | SV描述符读取使能 |

| other_desc_dout | I | 53 | OTHER描述符FIFO当前输出 |

| other_desc_empty | I | 1 | OTHER描述符FIFO空 |

| other_desc_rd_en | O | 1 | OTHER描述符读取使能 |

| frame_valid | O | 1 | 至少存在一路可服务描述符 |

| frame_ready | I | 1 | 下游控制器可接收当前帧 |

| frame_mac_class | O | 2 | 输入描述符[35:34] |

| frame_len | O | 16 | 获胜描述符中的帧长 |

| frame_timestamp | O | 32 | 获胜描述符中的时间戳 |

| frame_desc | O | 53 | 获胜描述符原始值；当前顶层未参与功能控制 |


2.2.3 功能设计

三个请求分别为goose_req、sv_req和other_req。当前RTL的frame_channel选择表达式首先判断sv_req，其次goose_req，最后other_req，因此实际固定优先级为SV>GOOSE>OTHER。frame_desc的选择顺序与frame_channel完全一致。

frame_len直接取frame_desc[51:36]，frame_timestamp取[31:0]，frame_mac_class取[35:34]。当没有请求时frame_channel = CH_NONE、frame_desc清零、frame_valid=0。clk和rst当前仅保留在接口中，模块内部功能逻辑为组合逻辑。

2.3 eth_classified_frame_ring_manager模块设计

2.3.1 功能说明

ring_manager负责三个通道的生产者写指针、ring_full、地址计算以及槽位的申请/提交/中止。写指针格式统一为{wrap_bit,index[30:0]}；读指针由软件或下游消费者维护。通过将分配与提交分离，可以在DataMover写失败时释放内部槽位但不发布新写指针。

2.3.2 接口列表

表7 eth_classified_frame_ring_manager接口

| 信号 | 方向 | 位宽 | 描述 |

| clk | I | 1 | 模块工作时钟 |

| rst | I | 1 | 高电平有效的同步复位信号 |

| cfg_goose_data_base_addr | I | 32 | GOOSE报文数据存储区基地址 |

| cfg_sv_data_base_addr | I | 32 | SV报文数据存储区基地址 |

| cfg_other_data_base_addr | I | 32 | OTHER报文数据存储区基地址 |

| cfg_goose_desc_base_addr | I | 32 | GOOSE描述符存储区基地址 |

| cfg_sv_desc_base_addr | I | 32 | SV描述符存储区基地址 |

| cfg_other_desc_base_addr | I | 32 | OTHER描述符存储区基地址 |

| cfg_ring_depth | I | 32 | 环形缓冲区深度，低31位有效；配置为0时使用CHANNEL_DEPTH |

| goose_rd_ptr | I | 32 | GOOSE通道读指针，格式为{翻转位,槽位编号[30:0]} |

| sv_rd_ptr | I | 32 | SV通道读指针，格式为{翻转位,槽位编号[30:0]} |

| other_rd_ptr | I | 32 | OTHER通道读指针，格式为{翻转位,槽位编号[30:0]} |

| goose_wr_ptr | O | 32 | GOOSE通道写指针 |

| sv_wr_ptr | O | 32 | SV通道写指针 |

| other_wr_ptr | O | 32 | OTHER通道写指针 |

| goose_ring_full | O | 1 | GOOSE环形缓冲区已满标志 |

| sv_ring_full | O | 1 | SV环形缓冲区已满标志 |

| other_ring_full | O | 1 | OTHER环形缓冲区已满标志 |

| alloc_valid | I | 1 | 槽位申请有效信号 |

| alloc_ready | O | 1 | 槽位申请就绪信号 |

| alloc_channel | I | 2 | 申请槽位的通道编号：1:GOOSE，2:SV，3:OTHER |

| alloc_data_addr | O | 32 | 当前申请槽位对应的报文数据存储地址 |

| alloc_desc_addr | O | 32 | 当前申请槽位对应的描述符存储地址 |

| alloc_entry_index | O | 32 | 当前申请槽位的编号 |

| commit_valid | I | 1 | 槽位提交信号，表示报文数据和描述符均已成功写入 |

| abort_valid | I | 1 | 槽位中止信号，需要释放已申请槽位且保持写指针不变 |


2.3.3 接口时序

cfg_ring_depth[30:0]为有效深度；为0时使用CHANNEL_DEPTH。ring_ptr_next在index到达depth-1时回到0并翻转wrap位。ring_full的判定为写指针与读指针index相同且wrap不同。

三个ring_full采用寄存器输出，构成环形指针计算到下游仲裁之间的时序边界。模块只允许一个未决槽位：alloc_ready=!slot_active&&!alloc_channel_full。alloc握手后锁存active_channel和当时的有效depth；commit_valid仅推进该active_channel的写指针，abort_valid仅释放slot_active。若abort_valid与commit_valid同时出现，abort具有优先级，从而保证失败事务不会误发布。

2.3.4 功能设计

alloc_entry_index直接取当前生产者写指针current_wr_ptr的低31bit，即去除最高位的wrap翻转标志后得到当前可分配槽位的实际索引；随后根据该索引分别计算报文数据和描述符的目标存储地址，其中数据地址由对应通道的数据区基地址selected_data_base加上槽位索引乘以固定数据槽位大小FRAME_SLOT_BYTES得到，描述符地址则由描述符区基地址selected_desc_base加上槽位索引乘以单个描述符大小DESC_BYTES得到。这样可以保证同一帧的数据和描述符使用相同的entry_index，分别写入对应通道的数据区和描述符区中的匹配位置，从而建立报文数据与软件描述符之间的一一对应关系。

alloc_entry_index = current_wr_ptr[30:0]

alloc_data_addr = selected_data_base + alloc_entry_index × FRAME_SLOT_BYTES

alloc_desc_addr = selected_desc_base + alloc_entry_index × DESC_BYTES

2.4 eth_classified_frame_data_packer 模块设计

2.4.1功能说明

eth_classified_frame_data_packer用于根据写入控制模块指定的报文通道和报文长度，从GOOSE、SV或OTHER对应的8位数据FIFO中连续读取报文字节，并按照字节顺序将数据打包为64位AXI4-Stream数据。模块在启动时锁存通道和报文长度，根据剩余字节数控制对应数据FIFO的读使能，每收集8个字节生成一个完整数据拍；当报文长度不是8字节的整数倍时，在最后一个数据拍中通过TKEEP标识有效字节数量，并同时产生TLAST。当下游未准备好接收数据时，模块暂停FIFO读取并保持当前输出数据、有效字节掩码和帧尾标志稳定；在FIFO非空且下游能够接收数据时，读使能可连续保持有效，以提高报文数据传输效率。整帧最后一个数据拍完成握手后，模块产生单周期完成脉冲并返回空闲状态；收到中止信号时，立即停止当前报文处理并清除内部缓存和输出状态。

2.4.2 接口列表

表3模块接口列表

| 信号 | 方向 | 位宽 | 描述 |

| clk | I | 1 | 模块工作时钟 |

| rst | I | 1 | 高电平有效的同步复位信号 |

| abort | I | 1 | 中止当前报文打包，清除内部缓存及输出状态 |

| start_valid | I | 1 | 报文打包启动有效信号 |

| start_ready | O | 1 | 模块启动就绪信号，表示当前可以接收新的报文打包请求 |

| start_channel | I | 2 | 报文通道选择：1表示GOOSE，2表示SV，3表示OTHER |

| start_length | I | 16 | 当前报文需要读取和打包的总字节数 |

| 三路 8 bit FWFT FIFO | 三路 8 bit FWFT FIFO | 三路 8 bit FWFT FIFO | 三路 8 bit FWFT FIFO |

| goose_data_dout | I | 8 | GOOSE数据FIFO当前输出字节 |

| goose_data_empty | I | 1 | GOOSE数据FIFO空标志 |

| goose_data_rd_en | O | 1 | GOOSE数据FIFO读使能 |

| sv_data_dout | I | 8 | SV数据FIFO当前输出字节 |

| sv_data_empty | I | 1 | SV数据FIFO空标志 |

| sv_data_rd_en | O | 1 | SV数据FIFO读使能 |

| other_data_dout | I | 8 | Other数据FIFO当前输出字节 |

| other_data_empty | I | 1 | Other数据FIFO空标志 |

| other_data_rd_en | O | 1 | Other数据FIFO读使能 |

| AXI4-Stream 输出 | AXI4-Stream 输出 | AXI4-Stream 输出 | AXI4-Stream 输出 |

| m_axis_tdata | O | 64 | 打包后的64位报文数据 |

| m_axis_tkeep | O | 8 | 当前数据拍的有效字节标志，每一位对应一个有效字节 |

| m_axis_tlast | O | 1 | 当前数据拍为整帧最后一拍时置高 |

| m_axis_tvalid | O | 1 | 当前输出数据有效 |

| m_axis_tready | I | 1 | 下游模块准备好接收当前数据拍 |

| done_pulse | O | 1 | 整帧最后一个数据拍完成传输后的单周期完成脉冲 |

| active | O | 1 | 当前正在读取和打包一帧报文 |


2.4.3 接口时序

eth_classified_frame_arbiter采用组合仲裁和握手机制。当描述符FIFO非空、描述符有效位为1且对应环形区未满时，模块立即按照SV > GOOSE > OTHER的优先级输出frame_valid、frame_channel、frame_len和frame_timestamp。下游未置位frame_ready时，描述符不被读取；当frame_valid与frame_ready同时有效时，模块产生获胜通道的desc_rd_en，并在当前时钟上升沿完成描述符接收和FIFO输出，其他通道读使能保持为0。

2.4.4 功能设计

eth_classified_frame_data_packer在接收到启动请求后，锁存当前报文所属通道和报文长度，并从对应的GOOSE、SV或OTHER数据FIFO中连续读取8位报文字节。模块按照读取顺序将字节依次填入64位缓存，每累计8个字节生成一个完整的数据拍。当报文长度不是8字节的整数倍时，最后一个数据拍只包含剩余有效字节，并通过TKEEP标识有效字节位置，同时置位TLAST表示整帧结束。

表9 TKEEP 生成规则

| 有效字节数 | TKEEP | 有效 lane |

| 1 | 8'h01 | lane0 |

| 2 | 8'h03 | lane0～1 |

| 3 | 8'h07 | lane0～2 |

| 4 | 8'h0F | lane0～3 |

| 5 | 8'h1F | lane0～4 |

| 6 | 8'h3F | lane0～5 |

| 7 | 8'h7F | lane0～6 |

| 8 | 8'hFF | lane0～7 |


模块通过握手机制向下游输出数据。当下游能够持续接收且数据FIFO非空时，对应通道的读使能可以连续保持有效，实现连续读取和打包，提高传输效率。当下游产生反压时，模块暂停新的FIFO读取，并保持当前输出的TDATA、TKEEP、TLAST和TVALID不变，直到当前数据拍完成传输。最后一个数据拍完成握手后，模块产生单周期完成脉冲并返回空闲状态。若收到中止信号，则立即停止当前报文处理，清除内部缓存和输出状态。

2.5 eth_classified_frame_desc_builder 模块设计

2.5.1功能说明

eth_classified_frame_desc_builder用于根据当前报文的通道类型、报文长度和时间戳生成64位输出描述符。模块将GOOSE、SV和OTHER三类通道分别转换为对应的类型编码，并按照预定字段格式组合描述符内容，其中最高位为有效标志，中间字段记录报文类型和报文长度，低32位保存时间戳。

2.5.2 接口列表

表3模块接口列表

| 信号 | 方向 | 位宽 | 描述 |

| frame_mac_class | I | 2 | MAC 分类：00 单播，01 广播，10 组播，11 非法/保留 |

| frame_len | I | 16 | 当前报文的实际字节长度 |

| frame_timestamp | I | 32 | 当前报文对应的时间戳 |

| desc_payload | O | 64 | 根据通道类型、报文长度和时间戳生成的64位输出描述符 |


2.5.3 接口时序

eth_classified_frame_desc_builder采用纯组合逻辑实现，不包含时钟、复位和握手机制。

2.5.4 功能设计

组合表达式为desc_payload = {1'b1, frame_mac_class, 13'd0, frame_len, frame_timestamp}。

2.6 eth_classified_frame_s2mm_ctrl 模块设计

2.6.1功能说明

eth_classified_frame_s2mm_ctrl是报文写入流程的核心控制模块，用于协调仲裁结果、环形槽位、数据打包、描述符生成和AXI DataMover之间的工作顺序。模块接收选中报文的通道、长度和时间戳，申请对应的存储槽位并锁存数据地址和描述符地址，随后启动数据打包模块，生成报文数据写命令，并将64位报文数据发送至AXI DataMover。

报文数据写入成功后，模块继续生成描述符写命令并发送64位描述符。当数据写入和描述符写入状态均正确时，提交环形槽位、推进对应通道写指针、增加成功帧计数并产生完成脉冲。若检测到报文长度异常、描述符配置错误、返回标识不匹配或写入状态错误，则中止当前槽位并锁存错误信息，等待错误清除信号后恢复工作。

2.6.2 接口列表

表3模块接口列表

| 信号 | 方向 | 位宽 | 描述 |

| 时钟、复位和控制接口 | 时钟、复位和控制接口 | 时钟、复位和控制接口 | 时钟、复位和控制接口 |

| clk | I | 1 | 模块工作时钟 |

| rst | I | 1 | 高电平有效的同步复位信号 |

| frame_valid | I | 1 | 仲裁模块输出的报文信息有效 |

| frame_ready | O | 1 | 当前可以接收仲裁模块输出的报文 |

| frame_channel | I | 2 | 报文通道，1为GOOSE，2为SV，3为OTHER |

| frame_mac_class | I | 2 | MAC分类 |

| frame_len | I | 16 | 报文实际字节长度 |

| frame_timestamp | I | 32 | 报文时间戳 |

| 环形槽位管理接口 | 环形槽位管理接口 | 环形槽位管理接口 | 环形槽位管理接口 |

| ring_alloc_valid | O | 1 | 请求分配一个环形缓冲区槽位 |

| ring_alloc_ready | I | 1 | 环形管理模块可以分配当前槽位 |

| ring_alloc_channel | O | 2 | 申请槽位的报文通道 |

| ring_alloc_data_addr | I | 32 | 当前槽位对应的数据存储地址 |

| ring_alloc_desc_addr | I | 32 | 当前槽位对应的描述符存储地址 |

| ring_alloc_entry_index | I | 32 | 当前槽位编号 |

| ring_commit_valid | O | 1 | 数据和描述符写入成功，提交当前槽位 |

| ring_abort_valid | O | 1 | 写入失败或事务取消，放弃当前槽位 |

| 数据打包模块接口 | 数据打包模块接口 | 数据打包模块接口 | 数据打包模块接口 |

| packer_start_valid | O | 1 | 启动一帧报文的数据打包 |

| packer_start_ready | I | 1 | 数据打包模块可以接收新的启动请求 |

| packer_start_channel | O | 2 | 需要读取的数据通道 |

| packer_start_length | O | 16 | 需要读取和打包的报文字节数 |

| packer_abort | O | 1 | 中止当前报文的数据打包 |

| packer_axis_tdata | I | 64 | 数据打包模块输出的64位报文数据 |

| packer_axis_tkeep | I | 8 | 当前数据拍的有效字节标志 |

| packer_axis_tlast | I | 1 | 当前数据拍为整帧最后一拍 |

| packer_axis_tvalid | I | 1 | 当前打包数据有效 |

| packer_axis_tready | O | 1 | 当前可以接收打包数据 |

| 描述符接口 | 描述符接口 | 描述符接口 | 描述符接口 |

| desc_payload | I | 64 | 描述符构建模块生成的64位输出描述符 |

| 数据搬移命令接口 | 1 | 1 | 1 |

| m_axis_s2mm_cmd_tvalid | O | 1 | 写命令有效 |

| m_axis_s2mm_cmd_tready | I | 1 | 数据搬移模块可以接收写命令 |

| m_axis_s2mm_cmd_tdata | O | 72 | 写入地址、事务标识和传输字节数等命令信息 |

| 数据搬移数据接口 | 数据搬移数据接口 | 数据搬移数据接口 | 数据搬移数据接口 |

| s_axis_s2mm_tvalid | O | 1 | 写入数据有效 |

| s_axis_s2mm_tready | I | 1 | 数据搬移模块可以接收当前数据拍 |

| s_axis_s2mm_tdata | O | 64 | 报文数据或描述符数据 |

| s_axis_s2mm_tkeep | O | 8 | 当前数据拍的有效字节标志 |

| s_axis_s2mm_tlast | O | 1 | 当前写命令对应数据的最后一拍 |

| 数据搬移状态接口 | 数据搬移状态接口 | 数据搬移状态接口 | 数据搬移状态接口 |

| m_axis_s2mm_sts_tvalid | I | 1 | 写入状态有效 |

| m_axis_s2mm_sts_tready | O | 1 | 当前可以接收写入状态 |

| m_axis_s2mm_sts_tdata | I | 8 | 写入完成标志、错误标志及事务标识 |

| m_axis_s2mm_sts_tkeep | I | 1 | 状态字节有效标志，当前未参与判断 |

| m_axis_s2mm_sts_tlast | I | 1 | 状态结束标志，当前未参与判断 |

| 状态输出接口 | 状态输出接口 | 状态输出接口 | 状态输出接口 |

| busy | O | 1 | 模块当前正在处理报文 |

| frame_done_pulse | O | 1 | 一帧报文完整提交后的单周期脉冲 |

| error | O | 1 | 错误状态锁存 |

| error_code | O | 8 | 当前错误类型 |

| frame_count | O | 32 | 成功写入并提交的报文数量 |

| last_data_addr | O | 32 | 最近一次接收报文对应的数据地址 |

| last_desc_addr | O | 32 | 最近一次接收报文对应的描述符地址 |

| current_channel | O | 2 | 当前正在处理的报文通道 |

| active_frame_len | O | 16 | 当前锁存的报文长度 |

| active_timestamp | O | 32 | 当前锁存的报文时间戳 |


2.6.3 接口时序

模块在空闲且无错误状态时，通过frame_valid和frame_ready接收报文信息。两者同时有效时，模块锁存通道、报文长度、时间戳及环形管理模块输出的存储地址，并同时产生槽位申请和数据打包启动信号。写命令、报文数据和描述符数据均采用握手机制，在有效信号置高而就绪信号未置高期间，命令或数据内容保持不变。

报文数据最后一拍完成传输后，模块进入数据状态等待阶段，仅在该阶段接收数据写入状态；数据写入成功后再发送描述符命令和单拍描述符数据。描述符状态返回成功后产生槽位提交信号和报文完成脉冲。若状态中的事务标识不匹配或存在错误，模块产生槽位中止信号并进入错误状态，直到clear_error有效后恢复为空闲状态。

2.6.4 功能设计

eth_classified_frame_s2mm_ctrl按照“申请槽位、写入报文数据、检查数据状态、写入描述符、检查描述符状态、提交槽位”的顺序完成一帧报文处理。模块接收仲裁后的报文信息，检查报文长度和描述符配置是否合法，锁存环形管理模块计算的数据地址及描述符地址，并启动数据打包模块。随后生成报文数据写命令，将打包后的64位数据发送至数据搬移模块；数据写入成功后，再发送描述符写命令和64位描述符。

模块通过状态机控制各处理阶段，并检查返回状态中的完成标志、错误标志和事务标识。只有报文数据和描述符均写入成功时，才提交环形槽位、增加报文计数并产生完成脉冲；任一阶段发生错误时，放弃当前槽位并锁存错误码，保证不完整报文不会通过写指针对外发布。

| 状态 | 主要功能 | 跳转条件 |

| S_IDLE | 等待并接收报文信息，检查参数，申请槽位并启动数据打包 | 合法报文进入S_SEND_DATA_CMD；参数错误进入S_ERROR |

| S_SEND_DATA_CMD | 发送报文数据写命令 | 命令完成握手后进入S_STREAM_DATA |

| S_STREAM_DATA | 发送打包后的报文数据 | 最后一拍完成握手后进入S_WAIT_DATA_STS |

| S_WAIT_DATA_STS | 等待并检查报文数据写入状态 | 成功进入S_SEND_DESC_CMD；失败进入S_ERROR |

| S_SEND_DESC_CMD | 发送描述符写命令 | 命令完成握手后进入S_STREAM_DESC |

| S_STREAM_DESC | 发送单拍64位描述符 | 描述符完成握手后进入S_WAIT_DESC_STS |

| S_WAIT_DESC_STS | 等待并检查描述符写入状态 | 成功进入S_COMMIT；失败进入S_ERROR |

| S_COMMIT | 提交槽位、增加报文计数并产生完成脉冲 | 下一周期返回S_IDLE |

| S_ERROR | 保持错误状态并停止接收新报文 | clear_error有效后返回S_IDLE |


2.7 AXI DataMover模块设计

2.7.1 功能说明

axi_datamover_0采用AMD/Xilinx AXI DataMover v5.1 IP实现。设计仅启用S2MM方向，接收本地控制器产生的72 bit命令和64 bit AXI4-Stream数据，自动生成AXI4-Full写地址、写数据和写响应事务，并在每条命令完成后通过8 bit状态流返回结果。

2.7.2 接口列表

| 信号 | 方向 | 位宽 | 描述 |

| 时钟与复位 | 时钟与复位 | 时钟与复位 | 时钟与复位 |

| m_axi_s2mm_aclk | I | 1 | S2MM存储器映射侧时钟，连接clk |

| m_axi_s2mm_aresetn | I | 1 | S2MM存储器映射侧低有效复位，连接~rst |

| m_axis_s2mm_cmdsts_awclk | I | 1 | 命令/状态侧时钟，连接clk |

| m_axis_s2mm_cmdsts_aresetn | I | 1 | 命令/状态侧低有效复位，连接~rst |

| S2MM命令与状态接口 | S2MM命令与状态接口 | S2MM命令与状态接口 | S2MM命令与状态接口 |

| s_axis_s2mm_cmd_tvalid | I | 1 | 接收本地控制器S2MM命令 |

| s_axis_s2mm_cmd_tready | O | 1 | 接收本地控制器S2MM命令 |

| s_axis_s2mm_cmd_tdata | I | 72 | 接收本地控制器S2MM命令 |

| m_axis_s2mm_sts_tvalid | O | 1 | 返回S2MM命令状态 |

| m_axis_s2mm_sts_tready | I | 1 | 返回S2MM命令状态 |

| m_axis_s2mm_sts_tdata | O | 8 | 返回S2MM命令状态 |

| m_axis_s2mm_sts_tkeep | O | 1 | 状态AXI4-Stream侧带信号 |

| m_axis_s2mm_sts_tlast | O | 1 | 状态AXI4-Stream侧带信号 |

| S2MM数据接口 | S2MM数据接口 | S2MM数据接口 | S2MM数据接口 |

| s_axis_s2mm_tdata | I | 64 | 输入AXI4-Stream数据 |

| s_axis_s2mm_tkeep | I | 8 | 输入有效字节掩码 |

| s_axis_s2mm_tlast | I | 1 | 输入命令数据包末拍 |

| s_axis_s2mm_tvalid | I | 1 | 输入数据有效 |

| s_axis_s2mm_tready | O | 1 | 数据接收就绪 |

| AXI4-Full写地址通道 | AXI4-Full写地址通道 | AXI4-Full写地址通道 | AXI4-Full写地址通道 |

| m_axi_s2mm_awaddr | O | 32 | 写地址 |

| m_axi_s2mm_awlen | O | 8 | 突发长度减1 |

| m_axi_s2mm_awsize | O | 3 | 每拍字节数 |

| m_axi_s2mm_awburst | O | 2 | 突发类型 |

| m_axi_s2mm_awprot | O | 3 | 保护属性 |

| m_axi_s2mm_awcache | O | 4 | 缓存属性 |

| m_axi_s2mm_awuser | O | 4 | 用户侧带 |

| m_axi_s2mm_awvalid | O | 1 | 写地址握手 |

| m_axi_s2mm_ awready | I | 1 |  |

| AXI4-Full写数据/响应通道 | AXI4-Full写数据/响应通道 | AXI4-Full写数据/响应通道 | AXI4-Full写数据/响应通道 |

| m_axi_s2mm_wdata | O | 64 | 写数据 |

| m_axi_s2mm_wstrb | O | 8 | 写字节选通 |

| m_axi_s2mm_wlast | O | 1 | 突发末拍 |

| m_axi_s2mm_wvalid | O | 1 | 写数据握手 |

| m_axi_s2mm_wready | I | 1 | 写数据握手 |

| m_axi_s2mm_bresp | I | 2 | 写响应 |

| m_axi_s2mm_bvalid | I | 1 | 写响应握手 |

| m_axi_s2mm_ bready | O | 1 | 写响应握手 |

| 控制与调试 | 控制与调试 | 控制与调试 | 控制与调试 |

| s2mm_halt | I | 1 | 固定为0，不请求停止 |

| s2mm_halt_cmplt | O | 1 | 停止完成指示 |

| s2mm_err | O | 1 | S2MM错误汇总 |

| s2mm_allow_addr_req | I | 1 | 固定为1，允许地址请求 |

| s2mm_addr_req_posted | O | 1 | 地址请求已提交 |

| s2mm_wr_xfer_cmplt | O | 1 | 写传输完成 |

| s2mm_ld_nxt_len | O | 1 | 加载下一长度指示 |

| s2mm_wr_len | O | 8 | 当前写长度信息 |

| s2mm_dbg_sel | I | 4 | 调试选择 |

| s2mm_dbg_data | O | 32 | 调试数据 |


2.7.3 接口时序

DataMover命令接口、数据接口和状态接口均采用AXI4-Stream valid/ready握手。命令握手后，控制器发送与BTT对应的有效字节数，并在命令数据包末拍置TLAST。DataMover根据64 bit流宽、TKEEP及BTT产生一个或多个AXI4突发。AW与W通道分别完成写地址和写数据握手，BRAM/DDR侧通过B通道返回写响应。DataMover汇总该命令的写响应后输出状态，控制器收到状态后决定继续写描述符或进入错误处理。

2.7.4 功能设计

AXI DataMover采用Vivado配置生成的S2MM通道，将写入控制模块发送的写命令和64位数据流转换为AXI4-Full存储器写事务。模块首先接收包含目标地址、传输字节数和事务标识的72位写命令，随后根据命令中的传输字节数接收报文数据或描述符数据，并结合TKEEP判断最后一个数据拍中的有效字节，通过TLAST确认本次数据包结束。

在存储器侧，DataMover根据传输长度和最大突发长度自动生成一个或多个AXI4写地址和写数据事务，并通过写响应通道检查存储器返回结果。全部写事务完成后，模块通过状态接口返回完成标志、错误标志和事务标识，写入控制模块根据返回状态判断本次报文数据或描述符是否写入成功。只有数据写入和描述符写入均成功后，系统才提交环形写指针，从而保证报文数据与描述符的一致性。
