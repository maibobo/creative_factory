# RTDS_test_fdma_aurora_brg_analysis

- Category: `pcie`
- Source: `E:\PCIE-CPU\docs\RTDS_test_fdma_aurora_brg_analysis.md`
- SHA-256: `3217b2aeb7350d132f64e3c5f87436e456f65662e4742de00b1c4fdd43ac5e4e`
- Extractor: `text`
- Tags: `aurora, engineering, pcie, xdma`
- Duplicate sources:
  - none

# RTDS_test 与 fdma_aurora_brg 读写状态机、软件接口和地址联动分析

## 1. 结论先看

`RTDS_test` 里的 `PCIe.v` 不是一个单纯的 FDMA demo。它把 Aurora/CDC 侧来的 66-bit 帧数据、PCIe/XDMA、`CONV_DMA`、AXI-Lite 寄存器和中断揉在一起，形成“软件可控的数据交换通道”。

`fdma_aurora_brg` 自带的独立读/写 FDMA 状态机更像硬件 wrapper 层和独立验证层。它适合单独验证 Aurora LocalLink 与 FDMA 数据搬运是否能跑通；但接入 `RTDS_test` 这种已有 XDMA、寄存器、中断、地址窗口的软件协议工程时，这层独立 FDMA FSM 可以去掉。更合理的做法是保留 `RTDS_test` 的软件控制面和地址协议，只复用或改造 `fdma_aurora_brg` 里的 Aurora 数据桥接、FIFO、帧边界处理和跨时钟域思想。

关键文件：

- `E:\PCIE-CPU\RTDS_test\RTDS_test.srcs\sources_1\new\PCIe.v`
- `E:\PCIE-CPU\RTDS_test\RTDS_test.srcs\sources_1\new\INFO_EXCH.v`
- `E:\PCIE-CPU\RTDS_test\RTDS_test.srcs\sources_1\bd\design_1\hdl\design_1_wrapper.v`
- `E:\PCIE-CPU\RTDS_test\RTDS_test.srcs\sources_1\bd\design_1\synth\design_1.v`
- `E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\new\fdma_aurora_brg_top.v`
- `E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\new\fdma_aurora_pcie_conv_dma_wrapper.v`

## 2. RTDS_test 写状态机的目的和意义

`PCIe.v` 中写方向是 Aurora/RTDS 数据进入 FPGA 后，再写入 PCIe 共享存储区域，供 CPU 读取。输入口是：

```verilog
i_wr_data_valid
i_wr_data[65:0]
```

其中 bit65 被当作 SOF，bit0 被当作 EOF，中间 `i_wr_data[64:1]` 是 64-bit 数据。`PCIe.v` 先根据 SOF/EOF 和 `fifo_sel` 把输入帧分到两个 FIFO，再由 FDMA 写通道搬到共享地址空间。

写状态机的核心作用有四个：

1. 把“流式帧数据”转换成 `CONV_DMA` 能接受的 FDMA 写 burst。
2. 管理 `fdma_wareq`、`fdma_wbusy`、`fdma_wvalid` 之间的握手，不让数据在 AXI 写事务还没建立时就被错误送出。
3. 维护写地址 `fdma_waddr_r`，按固定步长递增，写满 FPGA->CPU 窗口后回到空闲。
4. 写完窗口后拉起 `FPGA_CPU_irq_req`，通知 CPU 侧可以读取 FPGA 写入的数据。

当前关键参数是：

```verilog
localparam FDMA_BURST_LEN = 16'd16;
localparam ADDR_INC       = FDMA_BURST_LEN * 8;
```

`CONV_DMA` 的 FDMA 数据宽度是 64 bit，所以这里 `FDMA_BURST_LEN=16` 表示 16 个 64-bit beat，也就是 128 byte。地址每个 burst 递增 `16 * 8 = 128` byte。

写入窗口目前在硬件里固定为：

```verilog
FPGA_CPU_START_ADDR = 32'd0;
FPGA_CPU_LEN        = 32'd32 * 1024;
fdma_waddr          = fdma_waddr_r + FPGA_CPU_START_ADDR;
```

所以写 FSM 实际是在 0 起始、32KB 长度的窗口内按 128 byte 一个 burst 循环推进。它不是随便写一个状态机，而是在实现 FPGA->CPU 方向的数据批量提交协议。

需要注意的是，当前写侧还有几个工程风险：

- `PCIe.v` 中 `fdma_waddr/fdma_raddr` 是 32-bit，而 `design_1_wrapper` 端口是 64-bit，综合时会被扩展，但集成时最好显式处理。
- `data_rd_en` 在 EOF 后置位，复位外没有明显清除路径，是否符合帧级背压要结合实际数据节奏确认。
- 注释里已经说明当前逻辑没有真正做下一帧前的 CPU 接收状态背压，因此高速连续数据下需要考虑 FIFO 满和 CPU 未及时读取的问题。

## 3. RTDS_test 读状态机的目的和意义

读方向是 CPU 先把数据写到 FPGA 可读的共享地址区域，再通过寄存器触发 FPGA 读出，最后从 `PCIe.v` 的输出口送往后级 Aurora/RTDS 链路：

```verilog
o_rd_data_valid
o_rd_data[65:0]
```

`INFO_EXCH.v` 中软件写 `CPU_WR_DONE`，产生 `CPU_WR_DONE_pos`，再输出为：

```verilog
assign r_RD_START = CPU_WR_DONE_pos;
```

`PCIe.v` 收到 `RD_START` 后进入读状态机，使用软件配置的：

```verilog
CPU_FPGA_START_ADDR
CPU_FPGA_LEN
```

来产生：

```verilog
fdma_raddr = fdma_raddr_r + CPU_FPGA_START_ADDR;
fdma_rsize = FDMA_BURST_LEN;
```

读状态机的意义是：

1. 把软件寄存器事件 `RD_START` 转成一串 FDMA 读请求。
2. 从 CPU->FPGA 窗口按 128 byte burst 读出数据。
3. 给软件一个 `CPU_WR_DONE_resp` 响应，表示 FPGA 已经接收这个读命令并开始处理。
4. 把 64-bit FDMA 读数据重新封装成 66-bit `{SOF, data, EOF}`，送给后续数据链路。

所以读状态机并不是“为了读内存而读内存”，它承担的是 CPU->FPGA 数据提交协议的硬件执行端。

这里也有一个值得后续修的点：`SOF_R` 当前用 `fdma_raddr == ADDR_INC` 判断首拍，这在 `CPU_FPGA_START_ADDR` 不为 0 时容易偏。更稳妥的判断应基于本地偏移 `fdma_raddr_r` 或一次读事务的 first-beat 标志。

## 4. 不这么写，还可以怎么做

### 4.1 保留现有协议，抽出通用 FDMA burst engine

把 `PCIe.v` 里的读写状态机抽成一个通用模块，例如：

- 输入：`start`、`base_addr`、`length_bytes`、`burst_beats`
- 输出：`done`、`busy`、FDMA request/addr/size
- 数据侧：接 FIFO 或 stream ready/valid

这样 `PCIe.v` 只保留协议控制、寄存器、中断和数据选择，FDMA burst 细节交给公共模块。优点是对软件影响最小，风险也最低。

### 4.2 改成环形缓冲区协议

FPGA 和 CPU 各自维护读写指针，例如：

- FPGA->CPU：FPGA 写数据并更新 write pointer，CPU 读完更新 read pointer。
- CPU->FPGA：CPU 写数据并更新 write pointer，FPGA 读完更新 read pointer。

这种方式比“写满 32KB 后中断一次”更适合连续流，但软件协议要同步改，寄存器也要增加指针、空间、水线、溢出状态等字段。

### 4.3 改成描述符队列

CPU 下发 descriptor：地址、长度、方向、控制位。FPGA 按 descriptor 执行 FDMA 搬运，完成后写回状态或中断。这个方案最灵活，适合多 buffer 和变长帧，但复杂度明显高于当前工程。

### 4.4 复用 fdma_aurora_brg 的数据通路思想

`fdma_aurora_brg` 已经做了 Aurora LocalLink、FIFO、FDMA 风格握手、512B 帧等验证。接入 `RTDS_test` 时，不建议把它的独立 FDMA wrapper FSM 原封不动搬进来，而是：

- 去掉 `fdma_aurora_brg` 自带的独立 TX/RX FDMA 状态机 wrapper。
- 保留或参考它的 Aurora 侧帧处理、FIFO 水线、跨时钟域处理和调试信号。
- 由 `RTDS_test` 现有控制面决定什么时候读、什么时候写、地址从哪里来、完成后怎么通知软件。

这正好匹配你的判断：`fdma_aurora_brg` 自带读/写 FDMA FSM 是硬件 wrapper 层，可以去掉。

## 5. 加上 fdma_aurora_brg 后，哪些能去掉，哪些不能去掉

### 可以去掉或重构的部分

如果目标是把 `fdma_aurora_brg` 的数据桥接能力合进 `RTDS_test`，可以去掉或重构：

- `fdma_aurora_brg_top.v` 中用于独立运行的 FDMA TX/RX 控制状态机。
- 独立验证 wrapper 里固定 512B burst、固定窗口 wrap、自动循环读写的控制逻辑。
- 为单独 loop/硬件测试服务的测试引擎、VIO/ILA wrapper、独立自激励逻辑。

这些逻辑的价值在于验证桥本身，不应该在最终 `RTDS_test` 系统里和软件控制协议抢控制权。

### 不能直接去掉的部分

`RTDS_test` 里的这些东西不能因为接入 `fdma_aurora_brg` 就直接删：

- `INFO_EXCH.v`：软件寄存器接口。
- XDMA 的 AXI-Lite master 到 `INFO_EXCH` 的通路。
- `FPGA_CPU_irq_req` 中断语义。
- `CPU_FPGA_START_ADDR`、`CPU_FPGA_LEN` 等软件配置的地址窗口。
- FPGA->CPU / CPU->FPGA 两个方向的软件协议。
- `CONV_DMA` 与 AXI interconnect/BRAM 共享存储的数据通路。

一句话：可以删 `fdma_aurora_brg` 的独立硬件 wrapper FSM，但不能删 `RTDS_test` 的软件控制面。最终系统只能有一个地方负责“地址从哪里来、何时开始、何时完成、如何通知 CPU”。

## 6. 软件交互接口在哪里

### 6.1 寄存器接口

软件寄存器接口在：

```text
E:\PCIE-CPU\RTDS_test\RTDS_test.srcs\sources_1\new\INFO_EXCH.v
```

它是一个 AXI-Lite slave，端口是标准的 `S_AXI_*`：

```verilog
S_AXI_AWADDR
S_AXI_AWVALID
S_AXI_WDATA
S_AXI_WVALID
S_AXI_ARADDR
S_AXI_ARVALID
S_AXI_RDATA
S_AXI_RVALID
...
```

`INFO_EXCH.v` 负责把 AXI-Lite 读写转换成内部控制/状态信号，例如：

```verilog
r_INT_STATE
r_CLEAR_INTER
r_CPU_REC_STATE
r_RD_START
r_CPU_FPGA_START_ADDR
r_CPU_FPGA_LEN
```

几个关键寄存器/状态的意义：

- `INT_STATE` / `r_INT_STATE`：CPU 读中断状态，读取后触发内部清除行为。
- `CLEAR_INTER` / `r_CLEAR_INTER`：CPU 清除 FPGA->CPU 中断请求。
- `CPU_REC_STATE` / `r_CPU_REC_STATE`：CPU 接收状态标志，当前 `PCIe.v` 中还没有形成完整背压闭环。
- `CPU_WR_DONE`：CPU 写完成命令，上升沿生成 `r_RD_START`。
- `CPU_FPGA_START_ADDR`：CPU->FPGA 方向，FPGA 读数据的起始地址。
- `CPU_FPGA_LEN`：CPU->FPGA 方向，FPGA 读数据长度。
- `FPGA_CPU_START_ADDR`、`FPGA_CPU_LEN`：FPGA->CPU 方向，CPU 可读的数据窗口信息。
- `CPU_WR_DONE_resp`：FPGA 对 CPU 写完成/读启动命令的响应状态。

### 6.2 AXI-Lite 是怎么连到软件的

寄存器不是直接连软件，而是通过 PCIe XDMA 暴露给主机：

```text
Host 软件
  -> PCIe
  -> XDMA IP
  -> XDMA m_axil AXI-Lite master
  -> axi_interconnect_1
  -> INFO_EXCH S_AXI slave
  -> r_* 控制信号 / *_W 状态信号
```

在 `design_1.v` 中可以看到 `INFO_EXCH_0` 的 `S_AXI_*` 接到 `axi_interconnect_1_M00_AXI_*`。XDMA 的 `m_axil_*` 再进入这个 AXI-Lite interconnect。也就是说，软件访问 BAR 空间里的寄存器，本质上是在发 AXI-Lite transaction 到 `INFO_EXCH`。

### 6.3 除了寄存器，还有哪些软件交互

除了 `INFO_EXCH` 寄存器，软件还通过共享数据窗口和 FPGA 交换大块数据：

```text
Host 软件 / XDMA AXI-MM
  <-> AXI interconnect / shared memory window
  <-> CONV_DMA
  <-> PCIe.v FDMA-style interface
  <-> Aurora/RTDS 数据链路
```

`PCIe.v` 不直接实现 PCIe TLP，它只通过 `design_1_wrapper` 暴露的 FDMA 风格接口和 `CONV_DMA` 对接。`CONV_DMA` 再作为 AXI master 去访问 AXI 地址空间。CPU 侧也通过 XDMA 去访问同一个或相关的 AXI 地址空间。因此，真正的大数据交互不是寄存器，而是“软件可访问的共享内存/BRAM/AXI memory window”。

另外还有中断：

```verilog
FPGA_CPU_irq_req
```

这个信号接入 XDMA 用户中断侧，用于 FPGA 写完数据后通知主机软件。

## 7. RTDS_test 与 fdma_aurora_brg 地址和 size 的注意事项

### 7.1 RTDS_test 当前地址步进

`RTDS_test` 里：

```verilog
FDMA_BURST_LEN = 16
ADDR_INC       = FDMA_BURST_LEN * 8 = 128 byte
```

所以每次 FDMA 请求是 16 个 64-bit beat，地址递增 128 byte。

FPGA->CPU 方向：

```verilog
FPGA_CPU_START_ADDR = 0
FPGA_CPU_LEN        = 32KB
```

CPU->FPGA 方向：

```verilog
CPU_FPGA_START_ADDR = 软件寄存器配置
CPU_FPGA_LEN        = 软件寄存器配置
```

`INFO_EXCH.v` 复位时给 `CPU_FPGA_START_ADDR` 和 `CPU_FPGA_LEN` 的默认值都是 32KB。也就是说，默认意图很可能是：

- FPGA->CPU 使用低 32KB 窗口。
- CPU->FPGA 使用从 32KB 开始的另一个 32KB 窗口。

这两个窗口不要重叠，否则一个方向还没读完，另一个方向可能已经覆盖数据。

### 7.2 fdma_aurora_brg 的地址步进

`fdma_aurora_brg` 独立工程默认：

```verilog
FRAME_BYTES      = 512
FDMA_BURST_LEN   = 512 byte
MEM_WINDOW_BYTES = 4096 或 wrapper 中 8192
```

它的 TX/RX 状态机按 512 byte 一帧推进地址，并在 `MEM_WINDOW_BYTES` 内 wrap。这个行为适合独立环回和硬件验证，但和 `RTDS_test` 当前 32KB 窗口、128 byte burst 的协议不一致。

如果集成时保留 `RTDS_test` 控制面，就要决定最终系统采用哪种粒度：

- 继续用 `RTDS_test` 的 16 beat / 128 byte burst。
- 改成 `fdma_aurora_brg` 风格的 64 beat / 512 byte frame。
- 或者让内部 Aurora 帧是 512 byte，但 AXI/FDMA 侧允许拆成多个 128 byte burst。

这个选择必须和软件读取长度、缓存对齐、窗口 wrap 规则一致。

### 7.3 CONV_DMA 的 size 单位

这是最容易踩坑的地方。

`RTDS_test` 使用的 `CONV_DMA` 里，`fdma_wsize` 和 `fdma_rsize` 表示 64-bit beat 数，不是 byte 数。也就是：

```text
fdma_*size = 16  -> 16 个 64-bit beat -> 128 byte
fdma_*size = 64  -> 64 个 64-bit beat -> 512 byte
```

而 `fdma_aurora_brg` 独立 wrapper 里的 raw `fdma_wsize=512` 是 byte 语义。它不能直接接到 `CONV_DMA`。如果直接接，`CONV_DMA` 会把 512 当成 512 个 64-bit beat，实际就是 4096 byte，地址、burst 和数据量都会错。

`fdma_aurora_pcie_conv_dma_wrapper.v` 已经体现了正确做法：

```verilog
localparam [15:0] FRAME_WORDS = FRAME_BYTES / 8;
assign fdma_rsize = FRAME_WORDS;
assign fdma_wsize = FRAME_WORDS;
```

默认 `FRAME_BYTES=512` 时，传给 `CONV_DMA` 的 size 是 64 beat。

### 7.4 地址宽度

`PCIe.v` 中 FDMA 地址信号是 32-bit：

```verilog
wire [31:0] fdma_raddr;
wire [31:0] fdma_waddr;
```

`design_1_wrapper.v` 中相应端口是 64-bit。后续集成时建议显式零扩展：

```verilog
{32'd0, fdma_addr_32}
```

不要依赖隐式位宽扩展，尤其是在之后要接更大 BAR 或 DDR 地址空间时。

### 7.5 base address 与 wrap 规则

`fdma_aurora_brg` 的独立 FSM 默认从 0 开始，在本地窗口里自动 wrap；`RTDS_test` 则有明确的软件可见窗口：

- FPGA->CPU：硬件给 CPU 报告 `FPGA_CPU_START_ADDR` / `FPGA_CPU_LEN`。
- CPU->FPGA：CPU 写 `CPU_FPGA_START_ADDR` / `CPU_FPGA_LEN` 告诉 FPGA 去哪里读。

所以集成时需要做到：

1. 每个方向有独立 base 和 length。
2. bridge 内部地址如果仍从 0 开始，外层必须加 base offset。
3. wrap 只能在本方向窗口内部发生。
4. CPU 和 FPGA 对“写指针走到哪里、数据是否可读”必须有同一套协议。

否则会出现仿真能 loop，软件上板后读错地址或读到旧数据的情况。

## 8. 建议的后续集成方式

推荐路线如下：

1. 保留 `RTDS_test` 的 XDMA、`INFO_EXCH`、中断和地址窗口协议。
2. 去掉 `fdma_aurora_brg` 独立硬件 wrapper 层里的读/写 FDMA FSM。
3. 从 `fdma_aurora_brg` 复用 Aurora LocalLink 侧 FIFO、SOF/EOF、跨时钟域、水线和调试思路。
4. 把 FDMA 请求发起权收回到 `RTDS_test` 的控制面，或抽象成一个由 `RTDS_test` 配置的通用 burst engine。
5. 明确统一 burst 粒度：继续 128 byte，或整体升级到 512 byte。
6. 明确统一窗口：至少区分 FPGA->CPU 和 CPU->FPGA 两段地址，避免双向覆盖。
7. 明确统一 size 单位：进入 `CONV_DMA` 的 `fdma_*size` 一律是 64-bit beat 数。

## 9. 后续如果真正改 RTL，建议优先修的点

这些不是本报告要修改的内容，但后续集成前建议处理：

- `PCIe.v` 中 FDMA 32-bit 地址到 `design_1_wrapper` 64-bit 地址的显式扩展。
- `SOF_R` 判断不要用全局 `fdma_raddr == ADDR_INC`，改成本次读事务 first beat 标志。
- `CPU_REC_STATE_W` 当前没有明显置 1 路径，CPU 接收状态闭环需要重新确认。
- `data_src`、`fifo1_full`、`fifo2_full` 等信号如果依赖隐式 wire，建议显式声明。
- 写方向需要明确 FIFO 满时的背压策略，避免 Aurora 连续输入时丢帧。
- 如果采用 512 byte 帧，软件 buffer、cache 对齐和中断粒度也要一起更新。

## 10. 最终判断

`RTDS_test` 的读写状态机本质上是在服务软件协议：它们负责把软件寄存器命令、中断、共享地址窗口和 FDMA 数据搬运串起来。

`fdma_aurora_brg` 自带的独立读/写 FDMA FSM是硬件 wrapper 层，主要服务独立验证和 loop 场景。集成到 `RTDS_test` 时，这层可以去掉；但去掉以后必须由 `RTDS_test` 或新的通用 burst engine 接管 FDMA 请求、地址、长度、完成状态和软件通知。

因此最稳的方向是：删 wrapper FSM，留软件控制面；复用数据桥，不复用独立控制权。
