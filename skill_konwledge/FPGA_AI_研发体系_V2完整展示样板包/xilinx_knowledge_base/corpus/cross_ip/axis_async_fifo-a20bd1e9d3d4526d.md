# axis_async_fifo

- Category: `cross_ip`
- Source: `R:\nvme_adc_axi_pipeline\rtl\axis_async_fifo.sv`
- SHA-256: `a20bd1e9d3d4526de3c65febb0957202406df2f0533b89e048e26d7d20fabcbf`
- Extractor: `text`
- Tags: `ddr, nvme, pcie, rtl`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\rtl\axis_async_fifo.sv

```systemverilog
`timescale 1ns/1ps

// ADC域到系统域的异步ready/valid FIFO。它只负责CDC和短时弹性缓存，
// 不解释DATA_WIDTH内的业务位域，也不能向不可反压的ADC模拟源回传丢数信息。
module axis_async_fifo #(
    parameter integer DATA_WIDTH = 32,    // 每个FIFO条目的总位宽
    parameter integer ADDR_WIDTH = 10    // 深度地址位数，实际深度为2^ADDR_WIDTH
) (
    input  wire                  s_clk,    // 写侧时钟，本项目中为adc_clk
    input  wire                  s_rst_n,    // 写侧低有效复位
    input  wire [DATA_WIDTH-1:0] s_axis_tdata,    // 写侧待跨域条目
    input  wire                  s_axis_tvalid,    // 写侧条目有效
    output wire                  s_axis_tready,    // FIFO写侧可接受，含复位忙门控

    input  wire                  m_clk,    // 读侧时钟，本项目中为sys_clk
    input  wire                  m_rst_n,    // 读侧低有效复位
    output wire [DATA_WIDTH-1:0] m_axis_tdata,    // FWFT模式下的队首条目
    output wire                  m_axis_tvalid,    // 队首有效且读侧不在复位忙
    input  wire                  m_axis_tready,    // 下游已准备接收队首条目

    output wire                  full,    // 写时钟域满标志
    output wire                  empty,    // 读时钟域空标志
    output wire                  prog_full,    // 距满16项时提前告警
    output wire [ADDR_WIDTH:0]   wr_used_count,    // 写侧观察到的占用条目数
    output wire [ADDR_WIDTH:0]   rd_used_count    // 读侧观察到的占用条目数
);

    localparam integer DEPTH = 1 << ADDR_WIDTH;    // XPM FIFO配置深度
    wire fifo_reset = !s_rst_n || !m_rst_n;    // 任一时钟域复位都会复位整个异步FIFO
    wire fifo_read = m_axis_tvalid && m_axis_tready;    // 读侧ready/valid握手脉冲
    wire wr_rst_busy;    // XPM写侧复位过程未完成
    wire rd_rst_busy;    // XPM读侧复位过程未完成

    // stall表示s_axis_tvalid=1而s_axis_tready=0；stall期间写侧条目必须保持。
    assign s_axis_tready = !full && !wr_rst_busy;
    assign m_axis_tvalid = !empty && !rd_rst_busy;

    xpm_fifo_async #(
        .CDC_SYNC_STAGES     (2),
        .DOUT_RESET_VALUE    ("0"),
        .ECC_MODE            ("no_ecc"),
        .FIFO_MEMORY_TYPE    ("block"),
        .FIFO_READ_LATENCY   (0),
        .FIFO_WRITE_DEPTH    (DEPTH),
        .FULL_RESET_VALUE    (0),
        .PROG_EMPTY_THRESH   (10),
        .PROG_FULL_THRESH    (DEPTH - 16),
        .RD_DATA_COUNT_WIDTH (ADDR_WIDTH + 1),
        .READ_DATA_WIDTH     (DATA_WIDTH),
        .READ_MODE           ("fwft"),
        .RELATED_CLOCKS      (0),
        .USE_ADV_FEATURES    ("0707"),
        .WAKEUP_TIME         (0),
        .WRITE_DATA_WIDTH    (DATA_WIDTH),
        .WR_DATA_COUNT_WIDTH (ADDR_WIDTH + 1)
    ) u_xpm_fifo_async (
        .rst        (fifo_reset),
        .wr_clk     (s_clk),
        .wr_en      (s_axis_tvalid && s_axis_tready),
        .din        (s_axis_tdata),
        .full       (full),
        .overflow   (),
        .wr_rst_busy(wr_rst_busy),
        .rd_clk     (m_clk),
        .rd_en      (fifo_read),
        .dout       (m_axis_tdata),
        .empty      (empty),
        .underflow  (),
        .rd_rst_busy(rd_rst_busy),
        .data_valid (),
        .prog_full  (prog_full),
        .prog_empty (),
        .wr_data_count(wr_used_count),
        .rd_data_count(rd_used_count),
        .almost_full(),
        .almost_empty(),
        .injectsbiterr(1'b0),
        .injectdbiterr(1'b0),
        .sbiterr    (),
        .dbiterr    (),
        .sleep      (1'b0)
    );

endmodule
```
