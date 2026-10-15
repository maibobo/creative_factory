# top_nvme_adc_ddr_system

- Category: `cross_ip`
- Source: `R:\DDR\axi_ddr4_min_2020_2\integration\top_nvme_adc_ddr_system.sv`
- SHA-256: `6c1085c65ba836848ac450914e235be9e12a7601a7b5c4085c41453082c9b0b9`
- Extractor: `text`
- Tags: `ddr4, integration, nvme`
- Duplicate sources:
  - E:\ddr_proc\integration\top_nvme_adc_ddr_system.sv

```systemverilog
`timescale 1ns/1ps

// NVMe-ADC真实工程的自研集成边界。
//
// 本模块不是DDR BIST顶层，也不直接实例化MIG、SmartConnect、MicroBlaze或
// NoPHAE供应商IP。它给Vivado Block Design提供一个稳定的RTL入口：
//   1. m_axi_ddr_* 接SmartConnect的一个Slave入口，再由SmartConnect接MIG；
//   2. s_axi_fdma_* 接MicroBlaze侧AXI4-Lite互连的0x9000_0000地址段；
//   3. m_axi_nophae_* 接NoPHAE的s_axi_ctrl；
//   4. ddr_init_done、PCIe和ECQE状态从板级BD返回。
//
// 真正拥有DDR/PCIe物理引脚的最外层仍应是供应商BD生成的design_1_wrapper
// （或等价板级wrapper）。保持这一层后，业务RTL可独立于MIG和供应商IP版本编译。
module top_nvme_adc_ddr_system #(
    parameter integer AXI_ADDR_WIDTH = 32,
    parameter integer CTRL_ADDR_WIDTH = 40,
    parameter integer AXI_DATA_WIDTH = 256,
    parameter integer SEGMENT_BYTES = 1024 * 1024,
    parameter integer SEGMENT_COUNT = 8,
    parameter integer BURST_BEATS = 16,
    parameter integer ADC_FIFO_AW = 10,
    parameter integer COMMAND_TIMEOUT_CYCLES = 125_000_000,
    parameter integer AXIL_TIMEOUT_CYCLES = 4096,
    parameter integer LBA_BYTES = 512,
    parameter [AXI_ADDR_WIDTH-1:0] CAPTURE_DDR_BASE_ADDR = 32'hC000_0000,
    parameter [AXI_ADDR_WIDTH-1:0] COMMIT_DDR_ADDR =
        CAPTURE_DDR_BASE_ADDR + SEGMENT_COUNT * SEGMENT_BYTES,
    parameter [63:0] DDR_AXI_BASE_ADDR = 64'h0000_0000_8000_0000,
    parameter [63:0] DDR_WINDOW_BYTES = 64'h0000_0000_8000_0000,
    parameter [CTRL_ADDR_WIDTH-1:0] NOPHAE_CTRL_BASE_ADDR =
        40'h00_1000_0000,
    parameter [CTRL_ADDR_WIDTH-1:0] FDMA_CTRL_BASE_ADDR =
        40'h00_9000_0000,
    parameter [31:0] MIN_START_SLBA = 32'd1_048_576
) (
    input  wire                         adc_clk,
    input  wire                         adc_rst_n,
    input  wire                         adc_valid,
    input  wire [11:0]                  adc_ch0,
    input  wire [11:0]                  adc_ch1,

    input  wire                         sys_clk,
    input  wire                         sys_rst_n,
    input  wire                         ddr_init_done,
    input  wire                         nvme_init_done,
    input  wire                         pcie_link_up,
    input  wire                         ecqe_error_valid,
    input  wire [15:0]                  ecqe_error_status,

    output wire [AXI_ADDR_WIDTH-1:0]    m_axi_ddr_awaddr,
    output wire [7:0]                   m_axi_ddr_awlen,
    output wire [2:0]                   m_axi_ddr_awsize,
    output wire [1:0]                   m_axi_ddr_awburst,
    output wire                         m_axi_ddr_awvalid,
    input  wire                         m_axi_ddr_awready,
    output wire [AXI_DATA_WIDTH-1:0]    m_axi_ddr_wdata,
    output wire [AXI_DATA_WIDTH/8-1:0]  m_axi_ddr_wstrb,
    output wire                         m_axi_ddr_wlast,
    output wire                         m_axi_ddr_wvalid,
    input  wire                         m_axi_ddr_wready,
    input  wire [1:0]                   m_axi_ddr_bresp,
    input  wire                         m_axi_ddr_bvalid,
    output wire                         m_axi_ddr_bready,

    input  wire [CTRL_ADDR_WIDTH-1:0]   s_axi_fdma_awaddr,
    input  wire [2:0]                   s_axi_fdma_awprot,
    input  wire                         s_axi_fdma_awvalid,
    output wire                         s_axi_fdma_awready,
    input  wire [31:0]                  s_axi_fdma_wdata,
    input  wire [3:0]                   s_axi_fdma_wstrb,
    input  wire                         s_axi_fdma_wvalid,
    output wire                         s_axi_fdma_wready,
    output wire [1:0]                   s_axi_fdma_bresp,
    output wire                         s_axi_fdma_bvalid,
    input  wire                         s_axi_fdma_bready,
    input  wire [CTRL_ADDR_WIDTH-1:0]   s_axi_fdma_araddr,
    input  wire [2:0]                   s_axi_fdma_arprot,
    input  wire                         s_axi_fdma_arvalid,
    output wire                         s_axi_fdma_arready,
    output wire [31:0]                  s_axi_fdma_rdata,
    output wire [1:0]                   s_axi_fdma_rresp,
    output wire                         s_axi_fdma_rvalid,
    input  wire                         s_axi_fdma_rready,

    output wire [CTRL_ADDR_WIDTH-1:0]   m_axi_nophae_awaddr,
    output wire [2:0]                   m_axi_nophae_awprot,
    output wire                         m_axi_nophae_awvalid,
    input  wire                         m_axi_nophae_awready,
    output wire [31:0]                  m_axi_nophae_wdata,
    output wire [3:0]                   m_axi_nophae_wstrb,
    output wire                         m_axi_nophae_wvalid,
    input  wire                         m_axi_nophae_wready,
    input  wire [1:0]                   m_axi_nophae_bresp,
    input  wire                         m_axi_nophae_bvalid,
    output wire                         m_axi_nophae_bready,
    output wire [CTRL_ADDR_WIDTH-1:0]   m_axi_nophae_araddr,
    output wire [2:0]                   m_axi_nophae_arprot,
    output wire                         m_axi_nophae_arvalid,
    input  wire                         m_axi_nophae_arready,
    input  wire [31:0]                  m_axi_nophae_rdata,
    input  wire [1:0]                   m_axi_nophae_rresp,
    input  wire                         m_axi_nophae_rvalid,
    output wire                         m_axi_nophae_rready,

    output wire                         fdma_transfer_active,
    output wire                         capture_controller_busy,
    output wire                         capture_active,
    output wire                         capture_ready,
    output wire                         local_capture_done_pulse,
    output wire                         capture_cancelled_pulse,
    output wire                         capture_done,
    output wire [63:0]                  last_capture_id,
    output wire                         backend_busy,
    output wire [15:0]                  backend_last_status,
    output wire [15:0]                  fdma_last_error,
    output wire                         fatal_error,
    output wire [63:0]                  adc_accepted_sample_times,
    output wire [63:0]                  adc_dropped_sample_times,
    output wire [31:0]                  submitted_requests,
    output wire [31:0]                  completed_requests
);

    // 端口名与业务顶层保持完全一致，使用显式参数和SystemVerilog .*连接。
    // 板级BD只连接本wrapper，不直接依赖内部子模块层次。
    nvme_adc_vitis_compat_top #(
        .AXI_ADDR_WIDTH         (AXI_ADDR_WIDTH),
        .CTRL_ADDR_WIDTH        (CTRL_ADDR_WIDTH),
        .AXI_DATA_WIDTH         (AXI_DATA_WIDTH),
        .SEGMENT_BYTES          (SEGMENT_BYTES),
        .SEGMENT_COUNT          (SEGMENT_COUNT),
        .BURST_BEATS            (BURST_BEATS),
        .ADC_FIFO_AW            (ADC_FIFO_AW),
        .COMMAND_TIMEOUT_CYCLES (COMMAND_TIMEOUT_CYCLES),
        .AXIL_TIMEOUT_CYCLES    (AXIL_TIMEOUT_CYCLES),
        .LBA_BYTES              (LBA_BYTES),
        .CAPTURE_DDR_BASE_ADDR  (CAPTURE_DDR_BASE_ADDR),
        .COMMIT_DDR_ADDR        (COMMIT_DDR_ADDR),
        .DDR_AXI_BASE_ADDR      (DDR_AXI_BASE_ADDR),
        .DDR_WINDOW_BYTES       (DDR_WINDOW_BYTES),
        .NOPHAE_CTRL_BASE_ADDR  (NOPHAE_CTRL_BASE_ADDR),
        .FDMA_CTRL_BASE_ADDR    (FDMA_CTRL_BASE_ADDR),
        .MIN_START_SLBA         (MIN_START_SLBA)
    ) u_business_core (.*);

endmodule
```
