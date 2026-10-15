# CPU-FPGA PCIe交互方案V1.0

- Category: `pcie`
- Source: `E:\PCIE-CPU\CPU-FPGA PCIe交互方案V1.0.docx`
- SHA-256: `518f5cc09c470a3043d3a3e856341c31f014cf5947cbb400f674ec2d2ce69ded`
- Extractor: `python-docx+zip-structure-check`
- Tags: `cpu-fpga, pcie, xdma`
- Duplicate sources:
  - none

| 文档名称： | 文档名称： | 文档名称： | 文档名称： | 文档编号： |

| CPU-FPGA PCIe交互方案 | CPU-FPGA PCIe交互方案 | CPU-FPGA PCIe交互方案 | CPU-FPGA PCIe交互方案 |  |

| 编 写 | 李晓阳 | 日 期 | 2026-4-23 | 文档类型：设计文档 |

| 审 核 |  | 日 期 |  | 文档版本：V1.00 |

| 批 准 |  | 日 期 |  |  |


摘 要：

此文档描述了CPU与FPGA通过PCIe进行数据交互的方案。

版本及修订说明：

| 日 期 | 版 本 | 描 述 | 更改人员 |

| 2026-4-23 | 1.00 | 编写初始版本 | 李晓阳 |


目   录

1.	概述	3

2.	交互方案	3

3.	功能设计	4

3.1.	交互寄存器设计	4

3.2.	数据交互逻辑设计	5

CPU-FPGA PCIe交互方案

# 概述

《基于FPGA的小步长仿真组件硬件设计及数据交互关键技术》系统整体架构如下图所示。

其中，仿真主机负责进行参数下发和结果显示；主机-RK3588负责进行大步长仿真功能，子机上行使用Aurora接口时，主机-FPGA完成PCIe转Aurora功能；子机完成小步长仿真功能。

小步长仿真组件设备上行预留了PCIe（A）和Aurora（B）两种接口。当上行选择使用Aurora接口与主机侧CPU通信时，由于RK3588没有Aurora接口，需要在主机侧使用FPGA完成PCIe转Aurora工作。因此，无论上行使用哪种接口都需要完成CPU-FPGA PCIe交互方案研究。

由于目前没有获取到关于小步长仿真组件-FPGA中模型的信息，因此本文档按照每隔100us进行1K数据通信进行CPU与FPGA的PCIe交互方案设计。

# 交互方案

本方案FPGA侧使用XDMA IP进行PCIe EP设备开发，功能示意图如下：

其中：

FPGA侧负责如下工作：

寄存器交互模块进行CPU与FPGA寄存器信息交互；

数据读写模块对DDR进行数据读写操作；

FPGA侧PCIe EP使用XDMA IP进行开发。XDMA (Xilinx Direct Memory Access) 是Xilinx提供的DMA/Bridge Subsystem for PCI Express IP核，它将PCIe Endpoint功能与DMA引擎集成，使FPGA能够直接与主机内存进行数据交换，无需CPU全程参与，显著降低系统延迟并提高数据传输效率。

CPU侧负责如下工作：

与FPGA侧寄存器交互模块进行寄存器信息交互；

配置FPGA侧XDMA IP相关寄存器，将数据从CPU-DDR搬运至FPGA-DDR或从FPGA-DDR搬运至CPU-DDR。

# 功能设计

## 交互寄存器设计

FPGA寄存器定义如下：每个寄存器位宽为32bit、小端顺序。

| 偏移(B) | 名称 | 属性（CPU） | 默认值 | 说明 |

| 0x0000 | VERSION | R | / | FPGA程序版本号寄存器。 格式：0x00001001 |

| 0x0004 | PROG_TIME | R | / | FPGA程序时间寄存器。 格式：0x20251124 |

| 0x0008 | BUF_LEN_MAX | R | / | FPGA每个通道最大缓存长度寄存器。 格式：0x10000 |

| 0x000C | FPGA_TEMP | R | / | FPGA温度寄存器。 bit[15:0]：FPGA温度数据； bit16为0：FPGA已完成温度采集，此时bit[15:0]数据可用；bit16为1：FPGA正在进行温度采集，此时bit[15:0]数据不可用。 |

| FPGA向CPU写数据交互 | FPGA向CPU写数据交互 | FPGA向CPU写数据交互 | FPGA向CPU写数据交互 | FPGA向CPU写数据交互 |

| 0x0010 | INT_STATE | RC | 0x0 | FPGA向CPU写数据中断状态寄存器。 bit0为0：未中断；1：已中断。 CPU读取后自动清零。 |

| 0x0014 | CPU_REC_STATE | W/R | / | CPU读取数据状态寄存器。 bit0为0：CPU未完成数据读取；bit0为1：CPU完成数据读取。 |

| 0x0018 | FPGA_CPU_START_ADDR | R | / | FPGA向CPU写数据起始地址寄存器。 |

| 0x001C | FPGA_CPU_LEN | R | / | FPGA向CPU写数据长度寄存器。 |

| CPU向FPGA写数据交互 | CPU向FPGA写数据交互 | CPU向FPGA写数据交互 | CPU向FPGA写数据交互 | CPU向FPGA写数据交互 |

| 0x0020 | CPU_WR_DONE | W/R | 0x0 | CPU向FPGA写数据状态寄存器。 bit0为0：CPU未完成向FPGA写数据；bit0为1：CPU完成向FPGA写数据。 |

| 0x0024 | CPU_FPGA_START_ADDR | W/R | 0x0000 | CPU向FPGA写数据起始地址寄存器。 |

| 0x0028 | CPU_FPGA _LEN | W/R | 0x0000 | CPU向FPGA写数据长度寄存器。 |


注：寄存器属性：R为只读；W/R可以读写；RC读清除。

## 数据交互逻辑设计

数据交互逻辑主要包括：FPGA向CPU写数据、CPU向FPGA写数据。

FPGA向CPU写数据

FPGA逻辑分为如下步骤：

状态一：相关寄存器初始化后进入状态二。

状态二：没有数据时状态不变，有需要传输给CPU的数据时进入状态三；

状态三：将数据依次写入起始地址为：FPGA_CPU_START_ADDR，长度空间为： FPGA_CPU_LEN的DDR内。写完数据后进入状态四。

状态四：在状态四进行如下操作：

FPGA产生写数据完成中断，同时将INT_STATE寄存器置1；

FPGA收到CPU读清INT_STATE寄存器操作时，取消中断；

FPGA实时读取CPU_REC_STATE寄存器，为0时状态不变，为1时将CPU_REC_STATE寄存器置0后进入状态二。

CPU逻辑分为如下步骤：

状态一：相关寄存器初始化后进入状态二；

状态二：CPU接收中断，没有中断时状态不变，收到中断进入状态三；

状态三：读取起始地址寄存器FPGA_CPU_START_ADDR和长度寄存器FPGA_CPU_LEN 。同时读取INT_STATE是否为1，为0时状态不变，为1进入状态四；

状态四：从上述地址范围内读取数据。读完数据后进入状态五；

状态五：CPU_REC_STATE寄存器置1，进入状态二。

CPU向FPGA写数据

CPU逻辑分为如下步骤：

状态一：相关寄存器初始化后进入状态二；

状态二：CPU收到仿真主机需要发送的数据后，读取CPU_WR_DONE寄存器是否为1，为0状态不变，为1进入状态三；

状态三：将数据依次写入起始地址为：CPU_FPGA_START_ADDR，长度空间为：CPU_FPGA _LEN的DDR内。写完数据后进入状态四。

状态四：将CPU_WR_DONE寄存器置为1，进入状态二。

FPGA逻辑分为初始、空闲、读数据、完成四个状态。

状态一：相关寄存器初始化后进入状态二。

状态二：读取CPU_WR_DONE、CPU_FPGA_START_ADDR、CPU_FPGA _LEN寄存器。CPU_WR_DONE为0时状态不变，为1时进入状态三；

状态三：将数据从起始地址为：CPU_FPGA_START_ADDR，长度空间为：CPU_FPGA _LEN的DDR内依次读取。读完数据后进入状态四。

状态四：将CPU_WR_DONE寄存器置为0，进入状态二。

DDR缓冲区

FPGA统一固定最大长度，并设置BUF_LEN_MAX。
