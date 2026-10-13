// Static-check boundary only. No functional behavior is implemented.
(* syn_black_box = 1 *)
module xpm_fifo_async # (

  
  parameter                         FIFO_MEMORY_TYPE     = "auto",
  parameter                         ECC_MODE             = "no_ecc",
  parameter integer                 RELATED_CLOCKS       = 0,
  parameter integer                 SIM_ASSERT_CHK       = 0,
  parameter integer                 CASCADE_HEIGHT       = 0,

  parameter integer                 FIFO_WRITE_DEPTH     = 2048,
  parameter integer                 WRITE_DATA_WIDTH     = 32,
  parameter integer                 WR_DATA_COUNT_WIDTH  = 1,
  parameter integer                 PROG_FULL_THRESH     = 10,
  parameter integer                 FULL_RESET_VALUE     = 0,
  parameter                         USE_ADV_FEATURES     = "0707",

  parameter                         READ_MODE            = "std",
  parameter integer                 FIFO_READ_LATENCY    = 1,
  parameter integer                 READ_DATA_WIDTH      = WRITE_DATA_WIDTH,
  parameter integer                 RD_DATA_COUNT_WIDTH  = 1,
  parameter integer                 PROG_EMPTY_THRESH    = 10,
  parameter                         DOUT_RESET_VALUE     = "0",
  parameter integer                 CDC_SYNC_STAGES      = 2,

  parameter                         WAKEUP_TIME          = 0
) (

  
  input  wire                                         sleep,
  input  wire                                         rst,

  
  input  wire                                         wr_clk,
  input  wire                                         wr_en,
  input  wire [WRITE_DATA_WIDTH-1:0]                  din,
  output wire                                         full,
  output wire                                         prog_full,
  output wire [WR_DATA_COUNT_WIDTH-1:0]               wr_data_count,
  output wire                                         overflow,
  output wire                                         wr_rst_busy,
  output wire                                         almost_full,
  output wire                                         wr_ack,

  
  input  wire                                         rd_clk,
  input  wire                                         rd_en,
  output wire [READ_DATA_WIDTH-1:0]                   dout,
  output wire                                         empty,
  output wire                                         prog_empty,
  output wire [RD_DATA_COUNT_WIDTH-1:0]               rd_data_count,
  output wire                                         underflow,
  output wire                                         rd_rst_busy,
  output wire                                         almost_empty,
  output wire                                         data_valid,

  
  input  wire                                         injectsbiterr,
  input  wire                                         injectdbiterr,
  output wire                                         sbiterr,
  output wire                                         dbiterr
);
endmodule
