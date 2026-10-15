# rgmii_eth_mac_filter_dma寄存器列表V0.94

- Category: `ethernet`
- Source: `E:\eth_storm_project\rgmii_eth_mac_filter_dma寄存器列表V0.94.docx`
- SHA-256: `b3eb54bab0d6209d32f6218dd58fa8d4ca8378dafcd51e4c1e644003d98aaa46`
- Extractor: `python-docx+zip-structure-check`
- Tags: `dma, ethernet, rgmii, storm-filter`
- Duplicate sources:
  - none

rgmii_eth_storm_filter_dma IP 寄存器列表

# 1. 寄存器总表

## 1.1 MAC模块寄存器总表

| Register Name | Description | 8位 Offset | 32位 Offset | Bit | Access |

| MAC0模块 | MAC0模块 | 0x0000~ 0x00FF | 0x0000~ 0x003F |  |  |

| MAC_CTRL | MAC收发控制、地址策略、组播Hash及名单控制寄存器 | 0x0000 | 0x0000 | 32 | RW/W1AC |

| LOCAL_MAC_ADDR0 | 本地MAC地址前4字节 | 0x0004 | 0x0001 | 32 | RW |

| LOCAL_MAC_ADDR1 | 本地MAC地址后2字节 | 0x0008 | 0x0002 | 32 | RW |

| MCAST_MAC_ADDR0 | 待写入Hash表的组播MAC前4字节 | 0x000C | 0x0003 | 32 | RW |

| MCAST_MAC_ADDR1 | 待写入Hash表的组播MAC后2字节 | 0x0010 | 0x0004 | 32 | RW |

| WHITE0_MAC_ADDR0 | 白名单0源MAC前4字节 | 0x0014 | 0x0005 | 32 | RW |

| WHITE0_MAC_ADDR1 | 白名单0源MAC后2字节 | 0x0018 | 0x0006 | 32 | RW |

| WHITE1_MAC_ADDR0 | 白名单1源MAC前4字节 | 0x001C | 0x0007 | 32 | RW |

| WHITE1_MAC_ADDR1 | 白名单1源MAC后2字节 | 0x0020 | 0x0008 | 32 | RW |

| WHITE2_MAC_ADDR0 | 白名单2源MAC前4字节 | 0x0024 | 0x0009 | 32 | RW |

| WHITE2_MAC_ADDR1 | 白名单2源MAC后2字节 | 0x0028 | 0x000A | 32 | RW |

| WHITE3_MAC_ADDR0 | 白名单3源MAC前4字节 | 0x002C | 0x000B | 32 | RW |

| WHITE3_MAC_ADDR1 | 白名单3源MAC后2字节 | 0x0030 | 0x000C | 32 | RW |

| BLACK0_MAC_ADDR0 | 黑名单0源MAC前4字节 | 0x0034 | 0x000D | 32 | RW |

| BLACK0_MAC_ADDR1 | 黑名单0源MAC后2字节 | 0x0038 | 0x000E | 32 | RW |

| BLACK1_MAC_ADDR0 | 黑名单1源MAC前4字节 | 0x003C | 0x000F | 32 | RW |

| BLACK1_MAC_ADDR1 | 黑名单1源MAC后2字节 | 0x0040 | 0x0010 | 32 | RW |

| BLACK2_MAC_ADDR0 | 黑名单2源MAC前4字节 | 0x0044 | 0x0011 | 32 | RW |

| BLACK2_MAC_ADDR1 | 黑名单2源MAC后2字节 | 0x0048 | 0x0012 | 32 | RW |

| BLACK3_MAC_ADDR0 | 黑名单3源MAC前4字节 | 0x004C | 0x0013 | 32 | RW |

| BLACK3_MAC_ADDR1 | 黑名单3源MAC后2字节 | 0x0050 | 0x0014 | 32 | RW |

| STAT_DROP_CRC_ERR_CNT | CRC错误、gmii_rxer或帧长度不足丢弃计数 | 0x0054 | 0x0015 | 32 | RO |

| STAT_DROP_LEN_ERR_CNT | 长度超限或长度异常丢弃计数 | 0x0058 | 0x0016 | 32 | RO |

| STAT_DROP_BLACKLIST_CNT | 黑名单命中丢弃计数 | 0x005C | 0x0017 | 32 | RO |

| STAT_DROP_NOT_WHITE_CNT | 白名单未命中丢弃计数 | 0x0060 | 0x0018 | 32 | RO |

| STAT_DROP_DST_MISS_CNT | 目的MAC未匹配丢弃计数 | 0x0064 | 0x0019 | 32 | RO |

| MCAST_HASH_TABLE_L | 当前64位组播Hash表低32位回读 | 0x0068 | 0x001A | 32 | RO |

| MCAST_HASH_TABLE_H | 当前64位组播Hash表高32位回读 | 0x006C | 0x001B | 32 | RO |

| MAC_RX_OK_CNT | MAC接收阶段通过帧累计计数 | 0x0070 | 0x001C | 32 | RO |

| TX_SUCCESS_CNT | 发送成功帧累计计数 | 0x0074 | 0x001D | 32 | RO |

| TX_FAILED_CNT | 发送失败帧累计计数 | 0x0078 | 0x001E | 32 | RO |

| Reserved | MAC0模块剩余相对地址保留 | 0x007C~ 0x00FF | 0x001F~ 0x003F | 32 | N/A |

| MAC1模块 | MAC1模块 | 0x0000~ 0x00FF | 0x0000~ 0x003F |  |  |

| Reserved | 保留，预留MAC1寄存器窗口 | 0x0000~ 0x00FF | 0x0000~ 0x003F | 32 | N/A |

| MAC2模块 | MAC2模块 | 0x0000~ 0x00FF | 0x0000~ 0x003F |  |  |

| Reserved | 保留，预留MAC2寄存器窗口 | 0x0000~ 0x00FF | 0x0000~ 0x003F | 32 | N/A |

| … | … | … | … | … | … |

| MAC7模块 | MAC7模块 | 0x0000~ 0x00FF | 0x0000~ 0x003F |  |  |

| Reserved | 保留，预留MAC7寄存器窗口 | 0x0000~ 0x00FF | 0x0000~ 0x003F | 32 | N/A |


## 1.2 网络报文过滤模块寄存器总表

| Register Name | Description | 8位 Offset | 32位 Offset | Bit | Access |

| MAC0网络报文过滤模块 | MAC0网络报文过滤模块 | 0x0000~ 0x00FF | 0x0000~ 0x003F |  |  |

| FILTER_CTRL | 网络过滤、风暴与统计清零控制寄存器 | 0x0000 | 0x0000 | 32 | RW/W1AC |

| ETH_TYPE_GOOSE | GOOSE EtherType配置 | 0x0004 | 0x0001 | 32 | RW |

| ETH_TYPE_SV | SV EtherType配置 | 0x0008 | 0x0002 | 32 | RW |

| LIMIT_PERIOD | 运行时风暴统计窗口长度 | 0x000C | 0x0003 | 32 | RW |

| FRAME_MAX | 运行时窗口最大帧数阈值 | 0x0010 | 0x0004 | 32 | RW |

| BYTE_MAX | 运行时窗口最大字节数阈值 | 0x0014 | 0x0005 | 32 | RW |

| DROP_STATUS | 当前接收侧丢弃事件与原因 | 0x0018 | 0x0006 | 32 | RO |

| STAT_PASS_CNT | 接收过滤判决通过帧累计计数 | 0x001C | 0x0007 | 32 | RO |

| STAT_DROP_DUP_CRC_CNT | 重复CRC丢弃计数 | 0x0020 | 0x0008 | 32 | RO |

| STAT_DROP_FRAME_STORM_CNT | 帧数风暴丢弃计数 | 0x0024 | 0x0009 | 32 | RO |

| STAT_DROP_BYTE_STORM_CNT | 字节数风暴丢弃计数 | 0x0028 | 0x000A | 32 | RO |

| STAT_DROP_BUF_FULL_CNT | 一级判决FIFO资源不足丢弃计数 | 0x002C | 0x000B | 32 | RO |

| STAT_WIN_FRAME_CNT | 当前窗口计入帧数 | 0x0030 | 0x000C | 32 | RO |

| STAT_WIN_BYTE_CNT | 当前窗口计入数据帧字节数 | 0x0034 | 0x000D | 32 | RO |

| STAT_LAST_DROP_REASON | 最近一次接收侧丢弃原因 | 0x0038 | 0x000E | 32 | RO |

| STAT_STORM_ACTIVE | 当前窗口风暴激活状态 | 0x003C | 0x000F | 32 | RO |

| STAT_ROUTE_DROP_FIFO_FULL_CNT | 二级分类FIFO拥塞丢弃总计数 | 0x0040 | 0x0010 | 32 | RO |

| STAT_ROUTE_DROP_GOOSE_CNT | GOOSE分类FIFO拥塞丢弃计数 | 0x0044 | 0x0011 | 32 | RO |

| STAT_ROUTE_DROP_SV_CNT | SV分类FIFO拥塞丢弃计数 | 0x0048 | 0x0012 | 32 | RO |

| STAT_ROUTE_DROP_OTHER_CNT | Other分类FIFO拥塞丢弃计数 | 0x004C | 0x0013 | 32 | RO |

| Reserved | MAC0模块剩余相对地址保留 | 0x0050~ 0x00FF | 0x0014~ 0x003F | 32 | N/A |

| MAC1网络报文过滤模块 | MAC1网络报文过滤模块 | 0x0000~ 0x00FF | 0x0000~ 0x003F |  |  |

| Reserved | 保留，预留MAC1寄存器窗口 | 0x0000~ 0x00FF | 0x0000~ 0x003F | 32 | N/A |

| MAC2网络报文过滤模块 | MAC2网络报文过滤模块 | 0x0000~ 0x00FF | 0x0000~ 0x003F |  |  |

| Reserved | 保留，预留MAC2寄存器窗口 | 0x0000~ 0x00FF | 0x0000~ 0x003F | 32 | N/A |

| … | … | … | … | … | … |

| MAC7网络报文过滤模块 | MAC7网络报文过滤模块 | 0x0000~ 0x00FF | 0x0000~ 0x003F |  |  |

| Reserved | 保留，预留MAC7寄存器窗口 | 0x0000~ 0x00FF | 0x0000~ 0x003F | 32 | N/A |


## 1.3 Packet Stream–AXI4-Full DMA 模块寄存器总表

| Register Name | Description | 8位 Offset | 32位 Offset | Bit | Access |

| MAC0 DMA模块 | MAC0 DMA模块 | 0x0000~ 0x00FF | 0x0000~ 0x003F |  |  |

| DMA_CTRL | DMA错误统计清除控制寄存器 | 0x0000 | 0x0000 | 32 | W1AC |

| GOOSE_DATA_BASE | 写DMA GOOSE报文数据环形区基地址 | 0x0004 | 0x0001 | 32 | RO |

| SV_DATA_BASE | 写DMA SV报文数据环形区基地址 | 0x0008 | 0x0002 | 32 | RO |

| OTHER_DATA_BASE | 写DMA Other报文数据环形区基地址 | 0x000C | 0x0003 | 32 | RO |

| GOOSE_DESC_BASE | 写DMA GOOSE描述符环形区基地址 | 0x0010 | 0x0004 | 32 | RO |

| SV_DESC_BASE | 写DMA SV描述符环形区基地址 | 0x0014 | 0x0005 | 32 | RO |

| OTHER_DESC_BASE | 写DMA Other描述符环形区基地址 | 0x0018 | 0x0006 | 32 | RO |

| RING_DEPTH | 写DMA三通道环形缓冲区深度配置 | 0x001C | 0x0007 | 32 | RW |

| GOOSE_RD_PTR | 写DMA GOOSE软件消费者读指针 | 0x0020 | 0x0008 | 32 | RW |

| SV_RD_PTR | 写DMA SV软件消费者读指针 | 0x0024 | 0x0009 | 32 | RW |

| OTHER_RD_PTR | 写DMA Other软件消费者读指针 | 0x0028 | 0x000A | 32 | RW |

| GOOSE_WR_PTR | 写DMA GOOSE硬件生产者写指针 | 0x002C | 0x000B | 32 | RO |

| SV_WR_PTR | 写DMA SV硬件生产者写指针 | 0x0030 | 0x000C | 32 | RO |

| OTHER_WR_PTR | 写DMA Other硬件生产者写指针 | 0x0034 | 0x000D | 32 | RO |

| RING_STATUS | 写DMA三通道环满状态 | 0x0038 | 0x000E | 32 | RO |

| DMA_STATUS | 写DMA运行与事件状态 | 0x003C | 0x000F | 32 | RO |

| DMA_ERROR_CODE | 写DMA最近一次错误码 | 0x0040 | 0x0010 | 32 | RO |

| DMA_ERROR_COUNT | 写DMA错误总次数 | 0x0044 | 0x0011 | 32 | RO |

| DMA_PARAM_ERROR_COUNT | 写DMA参数错误次数 | 0x0048 | 0x0012 | 32 | RO |

| DMA_TAG_MISMATCH_COUNT | 写DMA DataMover标签不匹配次数 | 0x004C | 0x0013 | 32 | RO |

| DMA_DATA_STS_ERR_COUNT | 写DMA报文数据写状态错误次数 | 0x0050 | 0x0014 | 32 | RO |

| DMA_DESC_STS_ERR_COUNT | 写DMA描述符写状态错误次数 | 0x0054 | 0x0015 | 32 | RO |

| DMA_FRAME_COUNT | 写DMA成功提交帧计数 | 0x0058 | 0x0016 | 32 | RO |

| DMA_LAST_DATA_ADDR | 写DMA最近一次分配的数据写地址 | 0x005C | 0x0017 | 32 | RO |

| DMA_LAST_DESC_ADDR | 写DMA最近一次分配的描述符写地址 | 0x0060 | 0x0018 | 32 | RO |

| RD_DATA_BASE | 读DMA帧数据缓冲区基地址 | 0x0064 | 0x0019 | 32 | RW |

| RD_DESC_BASE | 读DMA描述符缓冲区基地址 | 0x0068 | 0x001A | 32 | RW |

| RD_RING_DEPTH | 读DMA环形队列深度 | 0x006C | 0x001B | 32 | RW |

| RD_WR_PTR | 读DMA软件生产者写指针 | 0x0070 | 0x001C | 32 | RW |

| RD_RD_PTR | 读DMA硬件消费者读指针 | 0x0074 | 0x001D | 32 | RO |

| RD_QUEUE_STATUS | 读DMA队列空、满、忙及错误状态 | 0x0078 | 0x001E | 32 | RO |

| RD_SUCCESS_CNT | 读DMA成功读取帧累计计数 | 0x007C | 0x001F | 32 | RO |

| RD_ERROR_CNT | 读DMA读取失败帧累计计数 | 0x0080 | 0x0020 | 32 | RO |

| RD_LAST_ERROR | 读DMA最近一次错误原因及描述符位置 | 0x0084 | 0x0021 | 32 | RO |

| Reserved | MAC0模块剩余相对地址保留 | 0x0088~ 0x00FF | 0x0022~ 0x003F | 32 | N/A |

| MAC1报文数据—AXI4-Full DMA模块 | MAC1报文数据—AXI4-Full DMA模块 | 0x0000~ 0x00FF | 0x0000~ 0x003F |  |  |

| Reserved | 保留，预留MAC1寄存器窗口 | 0x0000~ 0x00FF | 0x0000~ 0x003F | 32 | N/A |

| MAC2报文数据—AXI4-Full DMA模块 | MAC2报文数据—AXI4-Full DMA模块 | 0x0000~ 0x00FF | 0x0000~ 0x003F |  |  |

| Reserved | 保留，预留MAC2寄存器窗口 | 0x0000~ 0x00FF | 0x0000~ 0x003F | 32 | N/A |

| … | … | … | … | … | … |

| MAC7报文数据—AXI4-Full DMA模块 | MAC7报文数据—AXI4-Full DMA模块 | 0x0000~ 0x00FF | 0x0000~ 0x003F |  |  |

| Reserved | 保留，预留MAC7寄存器窗口 | 0x0000~ 0x00FF | 0x0000~ 0x003F | 32 | N/A |


# 2. MAC模块寄存器分表（MAC0）

## 2.1 MAC收发控制、地址策略、组播Hash及名单控制寄存器

名称：MAC_CTRL    偏移地址：0x0000    R/W: Read & Write / Write-1 Auto Clear

| Bit | Name | Access | Default | Description |

| 31:18 | reserved | RO | 0 | 保留 |

| 17 | cfg_src_mac_en | RW | 0 | 发送源MAC替换使能 |

| 16 | cfg_mac_tx_en | RW | 0 | MAC发送使能 |

| 15 | cfg_black3_en | RW | 0 | 第3条源MAC黑名单项使能 |

| 14 | cfg_black2_en | RW | 0 | 第2条源MAC黑名单项使能 |

| 13 | cfg_black1_en | RW | 0 | 第1条源MAC黑名单项使能 |

| 12 | cfg_black0_en | RW | 0 | 第0条源MAC黑名单项使能 |

| 11 | cfg_white3_en | RW | 0 | 第3条源MAC白名单项使能 |

| 10 | cfg_white2_en | RW | 0 | 第2条源MAC白名单项使能 |

| 9 | cfg_white1_en | RW | 0 | 第1条源MAC白名单项使能 |

| 8 | cfg_white0_en | RW | 0 | 第0条源MAC白名单项使能 |

| 7 | cfg_multicast_hash_clear | W1AC | 0 | 组播Hash表清空请求，清空操作优先于Hash写入 |

| 6 | cfg_multicast_mac_valid | W1AC | 0 | 组播Hash表写入请求 |

| 5 | cfg_blacklist_en | RW | 0 | 源MAC黑名单总使能 |

| 4 | cfg_whitelist_en | RW | 0 | 源MAC白名单总使能 |

| 3 | cfg_allow_multicast | RW | 0 | 使能组播目的MAC，组播帧仍需命中内部64bit Hash表 |

| 2 | cfg_allow_broadcast | RW | 0 | 使能广播目的MAC FF:FF:FF:FF:FF:FF |

| 1 | cfg_mac_promiscuous_en | RW | 0 | MAC混杂模式使能，混杂模式时绕过目的MAC和源MAC黑/白名单检查，CRC校验保持生效 |

| 0 | cfg_mac_rx_en | RW | 0 | MAC接收使能 |


## 2.2 本地MAC地址前4字节

名称：LOCAL_MAC_ADDR0    偏移地址：0x0004    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:0 | cfg_local_mac[47:16] | RW | 0 | 本地MAC地址前4字节；用于接收目的MAC匹配；发送时仅在cfg_src_mac_en=1时作为发送源MAC替换地址的前4字节 |


## 2.3 本地MAC地址后2字节

名称：LOCAL_MAC_ADDR1    偏移地址：0x0008    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:16 | reserved | RO | 0 | 保留 |

| 15:0 | cfg_local_mac[15:0] | RW | 0 | 本地MAC地址后2字节；用于接收目的MAC匹配；发送时仅在cfg_src_mac_en=1时作为发送源MAC替换地址的后2字节 |


## 2.4 待写入Hash表的组播MAC前4字节

名称：MCAST_MAC_ADDR0    偏移地址：0x000C    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:0 | cfg_multicast_mac[47:16] | RW | 0 | 待加入内部64bit Hash表的组播MAC地址前4字节；写入cfg_multicast_mac_valid=1时触发加入内部64bit Hash表 |


## 2.5 待写入Hash表的组播MAC后2字节

名称：MCAST_MAC_ADDR1    偏移地址：0x0010    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:16 | reserved | RO | 0 | 保留 |

| 15:0 | cfg_multicast_mac[15:0] | RW | 0 | 待加入内部64bit Hash表的组播MAC地址后2字节；写入cfg_multicast_mac_valid=1时触发加入内部64bit Hash表 |


## 2.6 白名单0源MAC前4字节

名称：WHITE0_MAC_ADDR0    偏移地址：0x0014    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:0 | cfg_white0_mac[47:16] | RW | 0 | 第0条白名单源MAC前4字节；由cfg_white0_en控制该条目是否参与匹配 |


## 2.7 白名单0源MAC后2字节

名称：WHITE0_MAC_ADDR1    偏移地址：0x0018    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:16 | reserved | RO | 0 | 保留 |

| 15:0 | cfg_white0_mac[15:0] | RW | 0 | 第0条白名单源MAC后2字节；由cfg_white0_en控制该条目是否参与匹配 |


## 2.8 白名单1源MAC前4字节

名称：WHITE1_MAC_ADDR0    偏移地址：0x001C    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:0 | cfg_white1_mac[47:16] | RW | 0 | 第1条白名单源MAC前4字节；由cfg_white1_en控制该条目是否参与匹配 |


## 2.9 白名单1源MAC后2字节

名称：WHITE1_MAC_ADDR1    偏移地址：0x0020    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:16 | reserved | RO | 0 | 保留 |

| 15:0 | cfg_white1_mac[15:0] | RW | 0 | 第1条白名单源MAC后2字节；由cfg_white1_en控制该条目是否参与匹配 |


## 2.10 白名单2源MAC前4字节

名称：WHITE2_MAC_ADDR0    偏移地址：0x0024    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:0 | cfg_white2_mac[47:16] | RW | 0 | 第2条白名单源MAC前4字节；由cfg_white2_en控制该条目是否参与匹配 |


## 2.11 白名单2源MAC后2字节

名称：WHITE2_MAC_ADDR1    偏移地址：0x0028    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:16 | reserved | RO | 0 | 保留 |

| 15:0 | cfg_white2_mac[15:0] | RW | 0 | 第2条白名单源MAC后2字节；由cfg_white2_en控制该条目是否参与匹配 |


## 2.12 白名单3源MAC前4字节

名称：WHITE3_MAC_ADDR0    偏移地址：0x002C    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:0 | cfg_white3_mac[47:16] | RW | 0 | 第3条白名单源MAC前4字节；由cfg_white3_en控制该条目是否参与匹配 |


## 2.13 白名单3源MAC后2字节

名称：WHITE3_MAC_ADDR1    偏移地址：0x0030    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:16 | reserved | RO | 0 | 保留 |

| 15:0 | cfg_white3_mac[15:0] | RW | 0 | 第3条白名单源MAC后2字节；由cfg_white3_en控制该条目是否参与匹配 |


## 2.14 黑名单0源MAC前4字节

名称：BLACK0_MAC_ADDR0    偏移地址：0x0034    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:0 | cfg_black0_mac[47:16] | RW | 0 | 第0条黑名单源MAC前4字节；由cfg_black0_en控制该条目是否参与匹配 |


## 2.15 黑名单0源MAC后2字节

名称：BLACK0_MAC_ADDR1    偏移地址：0x0038    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:16 | reserved | RO | 0 | 保留 |

| 15:0 | cfg_black0_mac[15:0] | RW | 0 | 第0条黑名单源MAC后2字节；由cfg_black0_en控制该条目是否参与匹配 |


## 2.16 黑名单1源MAC前4字节

名称：BLACK1_MAC_ADDR0    偏移地址：0x003C    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:0 | cfg_black1_mac[47:16] | RW | 0 | 第1条黑名单源MAC前4字节；由cfg_black1_en控制该条目是否参与匹配 |


## 2.17 黑名单1源MAC后2字节

名称：BLACK1_MAC_ADDR1    偏移地址：0x0040    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:16 | reserved | RO | 0 | 保留 |

| 15:0 | cfg_black1_mac[15:0] | RW | 0 | 第1条黑名单源MAC后2字节；由cfg_black1_en控制该条目是否参与匹配 |


## 2.18 黑名单2源MAC前4字节

名称：BLACK2_MAC_ADDR0    偏移地址：0x0044    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:0 | cfg_black2_mac[47:16] | RW | 0 | 第2条黑名单源MAC前4字节；由cfg_black2_en控制该条目是否参与匹配 |


## 2.19 黑名单2源MAC后2字节

名称：BLACK2_MAC_ADDR1    偏移地址：0x0048    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:16 | reserved | RO | 0 | 保留 |

| 15:0 | cfg_black2_mac[15:0] | RW | 0 | 第2条黑名单源MAC后2字节；由cfg_black2_en控制该条目是否参与匹配 |


## 2.20 黑名单3源MAC前4字节

名称：BLACK3_MAC_ADDR0    偏移地址：0x004C    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:0 | cfg_black3_mac[47:16] | RW | 0 | 第3条黑名单源MAC前4字节；由cfg_black3_en控制该条目是否参与匹配 |


## 2.21 黑名单3源MAC后2字节

名称：BLACK3_MAC_ADDR1    偏移地址：0x0050    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:16 | reserved | RO | 0 | 保留 |

| 15:0 | cfg_black3_mac[15:0] | RW | 0 | 第3条黑名单源MAC后2字节；由cfg_black3_en控制该条目是否参与匹配 |


## 2.22 CRC错误、gmii_rxer或帧长度不足丢弃计数

名称：STAT_DROP_CRC_ERR_CNT    偏移地址：0x0054    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | stat_drop_crc_err_cnt | RO | 0 | CRC/FCS错误、gmii_rxer或帧长度不足导致的丢弃累计计数；cfg_clear_stats清零 |


## 2.23 长度超限或长度异常丢弃计数

名称：STAT_DROP_LEN_ERR_CNT    偏移地址：0x0058    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | stat_drop_len_err_cnt | RO | 0 | 数据帧长度超限或长度异常导致的丢弃累计计数；cfg_clear_stats清零 |


## 2.24 黑名单命中丢弃计数

名称：STAT_DROP_BLACKLIST_CNT    偏移地址：0x005C    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | stat_drop_blacklist_cnt | RO | 0 | 源MAC命中黑名单导致的丢弃累计计数；cfg_clear_stats清零 |


## 2.25 白名单未命中丢弃计数

名称：STAT_DROP_NOT_WHITE_CNT    偏移地址：0x0060    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | stat_drop_not_white_cnt | RO | 0 | 白名单总使能但源MAC未命中任何已使能白名单项的丢弃累计计数；cfg_clear_stats清零 |


## 2.26 目的MAC未匹配丢弃计数

名称：STAT_DROP_DST_MISS_CNT    偏移地址：0x0064    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | stat_drop_dst_miss_cnt | RO | 0 | 目的MAC不是本地单播、允许广播或Hash表命中的组播地址时的丢弃累计计数；cfg_clear_stats清零 |


## 2.27 当前组播Hash表低32位

名称：MCAST_HASH_TABLE_L    偏移地址：0x0068    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | multicast_hash_table_lo | RO | 0 | 内部64位组播Hash表bit[31:0]当前回读值 |


## 2.28 当前组播Hash表高32位

名称：MCAST_HASH_TABLE_H    偏移地址：0x006C    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | multicast_hash_table_hi | RO | 0 | 内部64位组播Hash表bit[63:32]当前回读值 |


## 2.29 MAC接收OK累计计数

名称：MAC_RX_OK_CNT    偏移地址：0x0070    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | stat_mac_filter_pass_cnt | RO | 0 | MAC接收阶段通过累计计数 |


## 2.30 发送成功帧累计计数

名称：TX_SUCCESS_CNT    偏移地址：0x0074    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | tx_success_cnt | RO | 0 | MAC在本地PHY接口完整、无错误地发送一帧后累计加1 |


## 2.31 发送失败帧累计计数

名称：TX_FAILED_CNT    偏移地址：0x0078    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | tx_failed_cnt | RO | 0 | 当前帧因异常终止等原因未完整发送时累计加1 |


# 3. 网络报文过滤模块寄存器分表（MAC0）

## 3.1 过滤与风暴策略控制寄存器

名称：FILTER_CTRL    偏移地址：0x0000    R/W: Read & Write / Write-1 Auto Clear

| Bit | Name | Access | Default | Description |

| 31:5 | reserved | RO | 0 | 保留 |

| 4 | cfg_clear_stats | W1AC | 0 | 统计清零请求 |

| 3 | cfg_byte_storm_en | RW | 0 | 窗口字节数风暴过滤使能 |

| 2 | cfg_frame_storm_en | RW | 0 | 窗口帧数风暴过滤使能 |

| 1 | cfg_dup_crc_en | RW | 0 | 同一统计窗口epoch内重复CRC过滤使能 |

| 0 | cfg_filter_en | RW | 0 | 网络风暴/重复CRC过滤总使能 |


## 3.2 GOOSE EtherType配置

名称：ETH_TYPE_GOOSE    偏移地址：0x0004    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:16 | reserved | RO | 0 | 保留 |

| 15:0 | cfg_eth_type_goose | RW | 0x88B8 | 软件配置的GOOSE EtherType，用于报文类型分类 |


## 3.3 SV EtherType配置

名称：ETH_TYPE_SV    偏移地址：0x0008    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:16 | reserved | RO | 0 | 保留 |

| 15:0 | cfg_eth_type_sv | RW | 0x88BA | 软件配置的SV EtherType，用于报文类型分类 |


## 3.4 运行时风暴统计窗口长度

名称：LIMIT_PERIOD    偏移地址：0x000C    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:0 | cfg_window_ms | RW | 0 | 运行时窗口长度，单位ms；为0时使用默认参数，最大值30s |


## 3.5 运行时窗口最大帧数阈值

名称：FRAME_MAX    偏移地址：0x0010    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:0 | cfg_frame_max_per_win | RW | 0 | 运行时帧数阈值；为0时使用默认参数1000超过阈值后的报文按帧风暴丢弃 |


## 3.6 运行时窗口最大字节数阈值

名称：BYTE_MAX    偏移地址：0x0014    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:0 | cfg_byte_max_per_win | RW | 0 | 运行时字节数阈值；为0时使用默认参数8000000超过阈值后的报文按字节风暴丢弃 |


## 3.7 当前接收侧丢弃事件与原因

名称：DROP_STATUS    偏移地址：0x0018    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:17 | reserved | RO | 0 | 保留 |

| 16 | drop_valid | RO | 0 | 接收侧丢弃事件单周期脉冲 |

| 15:0 | drop_reason | RO | 0 | 与drop_valid同周期有效的当前丢弃原因 |


## 3.8 接收过滤判决通过帧累计计数

名称：STAT_PASS_CNT    偏移地址：0x001C    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | stat_pass_cnt | RO | 0 | 通过一级过滤并成功提交公共描述符FIFO的帧累计计数，不等同于二级分类FIFO最终成功接收帧数 |


## 3.9 重复CRC丢弃计数

名称：STAT_DROP_DUP_CRC_CNT    偏移地址：0x0020    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | stat_drop_dup_crc_cnt | RO | 0 | 同一统计窗口epoch内重复CRC命中导致的丢弃累计计数 |


## 3.10 帧数风暴丢弃计数

名称：STAT_DROP_FRAME_STORM_CNT    偏移地址：0x0024    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | stat_drop_frame_storm_cnt | RO | 0 | 当前窗口帧数超过阈值导致的丢弃累计计数 |


## 3.11 字节数风暴丢弃计数

名称：STAT_DROP_BYTE_STORM_CNT    偏移地址：0x0028    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | stat_drop_byte_storm_cnt | RO | 0 | 当前窗口字节数超过阈值导致的丢弃累计计数 |


## 3.12 一级判决FIFO资源不足丢弃计数

名称：STAT_DROP_BUF_FULL_CNT    偏移地址：0x002C    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | stat_drop_buf_full_cnt | RO | 0 | 一级Frame FIFO或一级Descriptor FIFO资源不足导致的丢弃累计计数 |


## 3.13 当前窗口计入帧数

名称：STAT_WIN_FRAME_CNT    偏移地址：0x0030    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | stat_win_frame_cnt | RO | 0 | 当前风暴统计窗口计入的帧数；窗口翻转或统计清零后重新计数 |


## 3.14 当前窗口计入数据帧字节数

名称：STAT_WIN_BYTE_CNT    偏移地址：0x0034    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | stat_win_byte_cnt | RO | 0 | 当前风暴统计窗口计入的数据帧字节数；窗口翻转或统计清零后重新计数 |


## 3.15 最近一次接收侧丢弃原因

名称：STAT_LAST_DROP_REASON    偏移地址：0x0038    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:16 | reserved | RO | 0 | 保留 |

| 15:0 | stat_last_drop_reason | RO | 0 | 最近一次已提交丢弃报文的原因编码 |


## 3.16 当前窗口风暴激活状态

名称：STAT_STORM_ACTIVE    偏移地址：0x003C    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:2 | reserved | RO | 0 | 保留 |

| 1 | stat_byte_storm_active | RO | 0 | 当前窗口字节数风暴激活标志 |

| 0 | stat_frame_storm_active | RO | 0 | 当前窗口帧数风暴激活标志 |


## 3.17 二级分类FIFO拥塞丢弃总计数

名称：STAT_ROUTE_DROP_FIFO_FULL_CNT    偏移地址：0x0040    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | stat_route_drop_fifo_full_cnt | RO | 0 | 已通过一级过滤，但目标二级分类FIFO满或将满而被丢弃的总帧数 |


## 3.18 GOOSE分类FIFO拥塞丢弃计数

名称：STAT_ROUTE_DROP_GOOSE_CNT    偏移地址：0x0044    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | stat_route_drop_goose_cnt | RO | 0 | GOOSE二级分类FIFO拥塞丢弃累计计数 |


## 3.19 SV分类FIFO拥塞丢弃计数

名称：STAT_ROUTE_DROP_SV_CNT    偏移地址：0x0048    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | stat_route_drop_sv_cnt | RO | 0 | SV二级分类FIFO拥塞丢弃累计计数 |


## 3.20 Other分类FIFO拥塞丢弃计数

名称：STAT_ROUTE_DROP_OTHER_CNT    偏移地址：0x004C    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | stat_route_drop_other_cnt | RO | 0 | Other二级分类FIFO拥塞丢弃累计计数 |


# 4. Packet Stream–AXI4-Full DMA模块寄存器分表（MAC0）

## 4.1 DMA读写错误清除控制寄存器

名称：DMA_CTRL    偏移地址：0x0000    R/W: Write-1 Auto Clear

| Bit | Name | Access | Default | Description |

| 31:1 | reserved | RO | 0 | 保留 |

| 0 | clear_dma_error | W1AC | 0 | DMA错误统计清除请求 |


## 4.2 写DMA GOOSE报文数据环形区基地址

名称：GOOSE_DATA_BASE    偏移地址：0x0004    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | cfg_goose_data_base_addr | RO | 0 | GOOSE报文数据环形区基地址；数据槽地址=基地址+entry_index×FRAME_SLOT_BYTES |


## 4.3 写DMA SV报文数据环形区基地址

名称：SV_DATA_BASE    偏移地址：0x0008    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | cfg_sv_data_base_addr | RO | 0 | SV报文数据环形区基地址；数据槽地址=基地址+entry_index×FRAME_SLOT_BYTES |


## 4.4 写DMA Other报文数据环形区基地址

名称：OTHER_DATA_BASE    偏移地址：0x000C    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | cfg_other_data_base_addr | RO | 0 | Other报文数据环形区基地址；数据槽地址=基地址+entry_index×FRAME_SLOT_BYTES |


## 4.5 写DMA GOOSE描述符环形区基地址

名称：GOOSE_DESC_BASE    偏移地址：0x0010    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | cfg_goose_desc_base_addr | RO | 0 | GOOSE描述符环形区基地址；描述符地址=基地址+entry_index×DESC_BYTES |


## 4.6 写DMA SV描述符环形区基地址

名称：SV_DESC_BASE    偏移地址：0x0014    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | cfg_sv_desc_base_addr | RO | 0 | SV描述符环形区基地址；描述符地址=基地址+entry_index×DESC_BYTES |


## 4.7 写DMA Other描述符环形区基地址

名称：OTHER_DESC_BASE    偏移地址：0x0018    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | cfg_other_desc_base_addr | RO | 0 | Other描述符环形区基地址；描述符地址=基地址+entry_index×DESC_BYTES |


## 4.8 写DMA三通道环形缓冲区深度配置

名称：RING_DEPTH    偏移地址：0x001C    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31 | reserved | RO | 0 | RTL忽略cfg_ring_depth[31]，保留 |

| 30:0 | cfg_ring_depth[30:0] | RW | 0 | 每通道环形条目数；为0时使用参数CHANNEL_DEPTH = 32 |


## 4.9 写DMA GOOSE软件消费者读指针

名称：GOOSE_RD_PTR    偏移地址：0x0020    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31 | goose_rd_ptr[31] | RW | 0 | 软件消费者读指针回绕位；索引从depth-1回到0时翻转 |

| 30:0 | goose_rd_ptr[30:0] | RW | 0 | 软件消费者读指针条目索引；软件消费完该通道描述符和数据后更新 |


## 4.10 写DMA SV软件消费者读指针

名称：SV_RD_PTR    偏移地址：0x0024    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31 | sv_rd_ptr[31] | RW | 0 | 软件消费者读指针回绕位；索引从depth-1回到0时翻转 |

| 30:0 | sv_rd_ptr[30:0] | RW | 0 | 软件消费者读指针条目索引；软件消费完该通道描述符和数据后更新 |


## 4.11 写DMA Other软件消费者读指针

名称：OTHER_RD_PTR    偏移地址：0x0028    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31 | other_rd_ptr[31] | RW | 0 | 软件消费者读指针回绕位；索引从depth-1回到0时翻转 |

| 30:0 | other_rd_ptr[30:0] | RW | 0 | 软件消费者读指针条目索引；软件消费完该通道描述符和数据后更新 |


## 4.12 写DMA GOOSE硬件生产者写指针

名称：GOOSE_WR_PTR    偏移地址：0x002C    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31 | goose_wr_ptr[31] | RO | 0 | 硬件生产者写指针回绕位 |

| 30:0 | goose_wr_ptr[30:0] | RO | 0 | 硬件生产者写指针条目索引；数据和描述符均写成功后推进 |


## 4.13 写DMA SV硬件生产者写指针

名称：SV_WR_PTR    偏移地址：0x0030    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31 | sv_wr_ptr[31] | RO | 0 | 硬件生产者写指针回绕位 |

| 30:0 | sv_wr_ptr[30:0] | RO | 0 | 硬件生产者写指针条目索引；数据和描述符均写成功后推进 |


## 4.14 写DMA Other硬件生产者写指针

名称：OTHER_WR_PTR    偏移地址：0x0034    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31 | other_wr_ptr[31] | RO | 0 | 硬件生产者写指针回绕位 |

| 30:0 | other_wr_ptr[30:0] | RO | 0 | 硬件生产者写指针条目索引；数据和描述符均写成功后推进 |


## 4.15 写DMA三通道环满状态

名称：RING_STATUS    偏移地址：0x0038    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:3 | reserved | RO | 0 | 保留 |

| 2 | other_ring_full | RO | 0 | Other环满：写、读指针索引相同且wrap位不同 |

| 1 | sv_ring_full | RO | 0 | SV环满：写、读指针索引相同且wrap位不同 |

| 0 | goose_ring_full | RO | 0 | GOOSE环满：写、读指针索引相同且wrap位不同 |


## 4.16 写DMA运行与事件状态

名称：DMA_STATUS    偏移地址：0x003C    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:8 | reserved | RO | 0 | 保留 |

| 7:6 | dma_current_channel | RO | 0 | 当前处理通道：00=NONE，01=GOOSE，10=SV，11=OTHER |

| 5 | dma_s2mm_wr_xfer_cmplt | RO | 0 | AXI DataMover写传输完成指示采样 |

| 4 | dma_datamover_s2mm_err | RO | 0 | AXI DataMover S2MM错误输出采样 |

| 3 | dma_frame_done_pulse | RO | 0 | 一帧数据和描述符均成功写入并提交后的单周期脉冲 |

| 2 | dma_error_pulse | RO | 0 | 每次检测到DMA错误时的单周期脉冲 |

| 1 | dma_error | RO | 0 | 粘滞错误标志；任一参数、标签、写状态或非法状态错误后置1，clear_dma_error清0 |

| 0 | dma_busy | RO | 0 | DMA控制状态机非空闲 |


## 4.17 写DMA最近一次错误码

名称：DMA_ERROR_CODE    偏移地址：0x0040    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:8 | reserved | RO | 0 | 保留 |

| 7:0 | dma_error_code | RO | 0 | 最近一次DMA错误码 |


## 4.18 写DMA错误总次数

名称：DMA_ERROR_COUNT    偏移地址：0x0044    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | dma_error_count | RO | 0 | DMA错误总次数，32位饱和计数；clear_dma_error清零 |


## 4.19 写DMA参数错误次数

名称：DMA_PARAM_ERROR_COUNT    偏移地址：0x0048    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | dma_param_error_count | RO | 0 | 零长度、帧过大或描述符参数错误次数，32位饱和计数 |


## 4.20 写DMA DataMover标签不匹配次数

名称：DMA_TAG_MISMATCH_COUNT    偏移地址：0x004C    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | dma_tag_mismatch_count | RO | 0 | DataMover返回状态标签与预期TAG_DATA/TAG_DESC不匹配次数，32位饱和计数 |


## 4.21 写DMA报文数据写状态错误次数

名称：DMA_DATA_STS_ERR_COUNT    偏移地址：0x0050    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | dma_data_status_error_count | RO | 0 | 报文数据写状态未完成或状态错误位非0的次数，32位饱和计数 |


## 4.22 写DMA描述符写状态错误次数

名称：DMA_DESC_STS_ERR_COUNT    偏移地址：0x0054    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | dma_desc_status_error_count | RO | 0 | 描述符写状态未完成或状态错误位非0的次数，32位饱和计数 |


## 4.23 写DMA成功提交帧计数

名称：DMA_FRAME_COUNT    偏移地址：0x0058    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | dma_frame_count | RO | 0 | 数据和描述符均成功写入并提交的帧数，32位饱和计数；clear_dma_error不清零 |


## 4.24 写DMA最近一次分配的数据写地址

名称：DMA_LAST_DATA_ADDR    偏移地址：0x005C    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | dma_last_data_addr | RO | 0 | 最近一次被接受帧分配的数据写地址；即使随后发生参数错误，该地址也会更新 |


## 4.25 写DMA最近一次分配的描述符写地址

名称：DMA_LAST_DESC_ADDR    偏移地址：0x0060    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | dma_last_desc_addr | RO | 0 | 最近一次被接受帧分配的描述符写地址 |


## 4.26 读DMA帧数据缓冲区基地址

名称：RD_DATA_BASE    偏移地址：0x0064    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:0 | cfg_rd_data_base_addr | RW | 0 | 读DMA帧数据缓冲区基地址；固定槽位下，帧数据地址=RD_DATA_BASE+entry_index×FRAME_SLOT_BYTES |


## 4.27 读DMA描述符缓冲区基地址

名称：RD_DESC_BASE    偏移地址：0x0068    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31:0 | cfg_rd_desc_base_addr | RW | 0 | 读DMA描述符缓冲区基地址；描述符地址=RD_DESC_BASE+entry_index×DESC_BYTES软件应先写帧数据和描述符，再更新RD_WR_PTR |


## 4.28 读DMA环形队列深度

名称：RD_RING_DEPTH    偏移地址：0x006C    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31 | reserved | RO | 0 | 保留 |

| 30:0 | cfg_rd_ring_depth[30:0] | RW | 0 | 读DMA环形队列条目数；配置值应至少为2，RD_WR_PTR和RD_RD_PTR的条目索引必须小于该深度 |


## 4.29 读DMA软件生产者写指针

名称：RD_WR_PTR    偏移地址：0x0070    R/W: Read & Write

| Bit | Name | Access | Default | Description |

| 31 | rd_wr_ptr[31] | RW | 0 | 软件生产者写指针回绕位；索引从depth-1回到0时翻转 |

| 30:0 | rd_wr_ptr[30:0] | RW | 0 | 软件生产者写指针条目索引软件完成帧数据和描述符写入后更新 |


## 4.30 读DMA硬件消费者读指针

名称：RD_RD_PTR    偏移地址：0x0074    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31 | rd_rd_ptr[31] | RO | 0 | 硬件消费者读指针回绕位 |

| 30:0 | rd_rd_ptr[30:0] | RO | 0 | 硬件消费者读指针条目索引 |


## 4.31 读DMA队列空、满、忙及错误状态

名称：RD_QUEUE_STATUS    偏移地址：0x0078    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:4 | reserved | RO | 0 | 保留 |

| 3 | rd_dma_error | RO | 0 | 读取DMA粘滞错误标志 |

| 2 | rd_dma_busy | RO | 0 | 读取DMA正在处理描述符、读取帧数据或等待下游接收 |

| 1 | rd_queue_full | RO | 0 | 读写指针索引相同且wrap位不同，软件不可继续写入新的待发送帧 |

| 0 | rd_queue_empty | RO | 1 | 读写指针完全相同，队列中没有可供读取DMA处理的帧 |


## 4.32 读DMA成功读取帧累计计数

名称：RD_SUCCESS_CNT    偏移地址：0x007C    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | rd_success_cnt | RO | 0 | 描述符合法、完整帧数据从DDR读取成功且整帧已提交给MAC发送FIFO后累计加1，32位饱和计数 |


## 4.33 读DMA读取失败帧累计计数

名称：RD_ERROR_CNT    偏移地址：0x0080    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:0 | rd_error_cnt | RO | 0 | 描述符非法、地址/长度/指针配置错误、AXI读取响应错误或帧读取异常终止导致的失败帧累计计数同一帧发生多个错误仅累计一次，32位饱和计数 |


## 4.34 读DMA最近一次错误原因及描述符位置

名称：RD_LAST_ERROR    偏移地址：0x0084    R/W: Read Only

| Bit | Name | Access | Default | Description |

| 31:24 | reserved | RO | 0 | 保留 |

| 23:8 | rd_error_desc_index | RO | 0 | 最近一次错误发生时的描述符条目索引，用于定位错误 |

| 7:0 | rd_error_code | RO | 0 | 最近一次读取DMA错误码 |


# 5. 编码与数据格式

## 5.1 丢弃原因编码

| Value | Name | Description |

| 16'h0000 | DROP_NONE | 无丢弃 |

| 16'h0001 | DROP_CRC_ERR | CRC/FCS错误、gmii_rxer或帧长度不足 |

| 16'h0002 | DROP_DUP_CRC | 同一统计窗口epoch内CRC表命中 |

| 16'h0004 | DROP_FRAME_STORM | 当前窗口帧数超过阈值 |

| 16'h0008 | DROP_BYTE_STORM | 当前窗口字节数超过阈值 |

| 16'h0010 | DROP_BUF_FULL | 一级Frame FIFO或Descriptor FIFO资源不足 |

| 16'h0020 | DROP_LEN_ERR | 数据帧长度超限或长度异常 |

| 16'h0040 | DROP_BLACKLIST | 源MAC命中黑名单 |

| 16'h0080 | DROP_NOT_WHITE | 白名单使能但源MAC未命中任何白名单 |

| 16'h0100 | DROP_DST_MISS | 目的MAC不是本地、允许广播或Hash表命中的组播地址 |

| 16'h0200 | DROP_MAC_RX_DISABLED | MAC接收使能=0，接收到的帧被MAC接收级拒绝 |


## 5.2 DMA错误码

| Value | Name | Description |

| 8'h00 | ERR_NONE | 无错误 |

| 8'h01 | ERR_ZERO_LENGTH | 帧长度为0 |

| 8'h02 | ERR_FRAME_TOO_LARGE | 帧长度超过FRAME_SLOT_BYTES或DataMover BTT范围 |

| 8'h03 | ERR_DESC_CONFIG | DESC_BYTES不是8或超出DataMover BTT范围 |

| 8'h10 | ERR_TAG_MISMATCH | DataMover返回状态标签与预期数据/描述符标签不一致 |

| 8'h11 | ERR_DATA_STS | 报文数据写状态未完成或状态错误 |

| 8'h12 | ERR_DESC_STS | 描述符写状态未完成或状态错误 |

| 8'h13 | ERR_ILLEGAL_STATE | DMA控制状态机进入非法状态 |

| 8'h20 | RD_ERR_AXI_RRESP | 读DMA AXI读取响应错误 |

| 8'h21 | RD_ERR_DESC_INVALID | 读DMA描述符无效或字段格式非法 |

| 8'h22 | RD_ERR_ZERO_LENGTH | 读DMA描述符中的帧长度为0 |

| 8'h23 | RD_ERR_FRAME_TOO_LARGE | 读DMA帧长度超过FRAME_SLOT_BYTES或硬件支持上限 |

| 8'h24 | RD_ERR_DATA_ADDR_ALIGN | 读DMA数据地址不满足AXI对齐要求 |

| 8'h25 | RD_ERR_DESC_ADDR_ALIGN | 读DMA描述符地址不满足DESC_BYTES对齐要求 |

| 8'h26 | RD_ERR_RING_CFG | 读DMA环深度、基地址或其他队列配置非法 |

| 8'h27 | RD_ERR_POINTER | 读DMA读写指针越界或状态不一致 |

| 8'h28 | RD_ERR_FRAME_ABORT | 读DMA帧读取过程被复位或异常终止 |


## 5.3 写DMA软件可见64位描述符格式

| Bit | Name | Default | Description |

| 31:0 | TIMESTAMP | 0 | 接收侧时间戳；frame_time_cnt_g每个GMII RX时钟周期加8 |

| 47:32 | FRAME_LENGTH | 0 | 报文数据长度，16位 |

| 60:48 | reserved | 0 | 保留 |

| 62:61 | MAC_CLASS | — | 00=单播，01=广播，10=组播，11=非法/保留 |

| 63 | VALID | 1 | 描述符有效；硬件仅在报文数据写成功后写入描述符 |


# 6. DMA环形缓冲区与软硬件交互规则

## 6.1 软件侧DMA环形缓冲区读取规则

| 项目 | 规则 |

| 通道 | GOOSE、SV、OTHER各自拥有独立数据基地址、描述符基地址、软件RD_PTR、硬件WR_PTR和ring_full状态 |

| 指针职责 | RD_PTR由软件更新，表示软件当前读取位置；WR_PTR由FPGA更新，表示FPGA当前写入位置 |

| 数据地址 | 软件根据当前RD_PTR计算数据地址：DATA_BASE + RD_PTR × 1536 |

| 描述符地址 | 软件根据当前 RD_PTR 计算描述符地址：DESC_BASE + RD_PTR × 8 |

| 指针格式 | bit[31]为wrap位，bit[30:0]为entry index。指针由RING_DEPTH-1更新至0时，软件同步翻转RD_PTR的wrap位 |

| 数据可读判断 | 当RD_PTR != WR_PTR时，表示该通道存在FPGA已完成写入的数据，软件可继续读取对应描述符和帧数据 |


## 6.2 FPGA侧DMA数据写入流程

1、仲裁器按SV>GOOSE>OTHER固定优先级选择可用通道。

2、握手成功后，队列管理模块根据当前WR_PTR分配槽位并计算数据、描述符地址。

3、DMA先写完整帧数据，并校验DataMover写状态及TAG；失败则终止当前槽位，WR_PTR不更新。

4、数据写成功后再写64位软件描述符，并再次校验写状态及TAG；失败同样不更新WR_PTR。

5、数据与描述符均写入成功后，对应WR_PTR加1，DMA_FRAME_COUNT加1，并产生完成脉冲。

## 6.3 软件侧DMA数据读取要求

针对SOOSE、SV通道：

1、软件首先分别读取SV、GOOSE环形缓冲区对应的WR_PTR和RD_PTR，比较同一缓冲区的两个指针是否相等，判断是否存在待读取数据。当RD_PTR!=WR_PTR时，表示该缓冲区存在可读取数据。

2、对于存在可读取数据的缓冲区，软件根据当前RD_PTR、对应的描述符基地址和数据基地址，计算当前条目的描述符地址和数据地址。根据描述符地址读取描述符后，首先检查VALID位是否有效。

3、当VALID=1时，软件根据数据地址和描述符中的FRAME_LENGTH等信息读取完整帧数据。帧数据处理完成后，将对应描述符的VALID位置0，同时将该缓冲区的RD_PTR加1；当指针达到RING_DEPTH-1后，下一次更新回到索引0，并切换相应的wrap标志。

4、当VALID=0时，表示当前描述符无有效帧数据，软件不读取对应数据区，仅将该缓冲区的RD_PTR加1，继续检查下一条描述符。

5、RD_PTR更新后，表示该条目已完成软件读取。重复执上述过程。

针对OTHER通道：

1、软件响应FPGA产生的中断后，首先在CPU中断控制器侧屏蔽该中断源，避免软件在批量处理环形缓冲区期间重复响应同一数据通道的中断请求。

2、软件根据OTHER环形缓冲区的RD_PTR、描述符基地址和数据基地址，计算当前条目的描述符地址和数据地址。根据描述符地址读取描述符后，首先检查VALID位是否有效。

3、当VALID=1时，软件根据数据地址和描述符中的FRAME_LENGTH等信息读取完整帧数据。帧数据处理完成后，将对应描述符的VALID位置0，同时将该缓冲区的RD_PTR加1；当指针达到RING_DEPTH-1后，下一次更新回到索引0，并切换相应的wrap标志。

4、当VALID=0时，表示当前描述符无有效帧数据，软件不读取对应数据区，仅将该缓冲区的RD_PTR加1，继续检查下一条描述符。

5、RD_PTR更新后，表示当前条目已完成软件侧处理。软件重新读取WR_PTR，并与当前RD_PTR进行比较。若二者不相等，表示环形缓冲区中仍存在待处理条目，则重复执行步骤2～5；若二者相等，表示当前缓冲区已处理完毕，软件重新使能该中断源，等待FPGA后续产生新的中断请求。

## 6.4 软件侧DMA环形缓冲区写入规则

| 项目 | 规则 |

| 通道 | 发送缓冲区数据基地址、描述符基地址、软件WR_PTR、硬件RD_PTR和ring_full状态 |

| 指针职责 | WR_PTR由软件更新，表示软件当前写入的位置；RD_PTR由FPGA更新，表示FPGA当前读取的位置 |

| 数据地址 | 软件根据当前WR_PTR计算数据地址：DATA_BASE + WR_PTR × 1536 |

| 描述符地址 | 软件根据当前WR_PTR计算描述符地址：DESC_BASE + WR_PTR × 8 |

| 指针格式 | bit[31]为wrap位，bit[30:0]为entry index。指针由RING_DEPTH-1更新至0时，软件同步翻转RD_PTR的wrap位 |

| 数据可写判断 | 当ring_full = 0时，表示该通道存在可写入位置；当ring_full = 1时，软件不得继续写入该通道数据 |


## 6.5 软件侧DMA数据写入要求

1、软件首先分别读取环形缓冲区的WR_PTR和ring_full状态，判断是否存在可写入位置。当ring_full = 0时，表示该通道存在可写入位置。

2、缓冲区存在可写入位置，软件根据当前WR_PTR、数据基地址DATA_BASE和描述符基地址DESC_BASE，计算当前条目的数据地址和描述符地址。

3、软件首先将完整帧数据写入对应的数据地址，再填写描述符内容。数据及描述符内容全部写入完成后，将描述符VALID位置1。

4、确认帧数据和描述符均已写入完成后，软件将WR_PTR加1；当指针达到RING_DEPTH - 1后，下一次更新回到索引0，并切换对应的wrap标志。

5、WR_PTR更新后，表示该条目已准备完成，FPGA可以根据RD_PTR读取对应描述符和帧数据。软件随后重新检查缓冲区状态，继续写入后续报文。

## 6.6 FPGA侧DMA数据读取流程

1、FPGA比较环形缓冲区对应的RD_PTR和WR_PTR。当RD_PTR != WR_PTR时，表示对应缓冲区存在待读取数据。

2、FPGA根据当前RD_PTR、描述符基地址DESC_BASE和数据基地址DATA_BASE，计算当前描述符地址和数据地址，并读取对应描述符。

3、当描述符VALID = 1时，FPGA获取FRAME_LENGTH等信息，并根据对应数据地址读取完整帧数据。

4、完整帧数据读取成功并交给后级MAC发送模块后，将对应缓冲区的RD_PTR加1；当指针达到RING_DEPTH-1后，下一次更新回到索引0，并切换对应的wrap位。

5、RD_PTR更新后，表示该条目已完成FPGA读取，对应的数据区和描述符位置可供软件后续重新写入。FPGA随后重新读取缓冲区的WR_PTR和RD_PTR，重复上述过程。
