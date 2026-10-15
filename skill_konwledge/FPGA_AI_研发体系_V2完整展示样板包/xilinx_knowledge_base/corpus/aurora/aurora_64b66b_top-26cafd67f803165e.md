# aurora_64b66b_top

- Category: `aurora`
- Source: `R:\aurora_64b66b_10p3125g_2020_2_verified\verification\aurora_64b66b_0_ex.srcs\sources_1\new\aurora_64b66b_top.v`
- SHA-256: `26cafd67f803165ec108f550c6c3d1198c47dcf5aca82db60f52f5187feb2ecd`
- Extractor: `text`
- Tags: `10.3125g, 64b66b, aurora, verified, vivado-2020.2`
- Duplicate sources:
  - none

```verilog
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/03/11 09:30:05
// Design Name:
// Module Name: aurora_64b66b_top
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module aurora_64b66b_top(
    input           clk_p			,
    input           clk_n			,

	//GT IO
    input			GTHQ0_P		,
    input			GTHQ0_N		,
    input 			RXP			,
    input 			RXN			,
    output			TXP			,
    output			TXN			,

    output          sfp_tx_disable,
    output          sfp_rs0     ,
    output          sfp_rs1     ,

    output          pl_led
    );

localparam RESET_ASSERT       = 10;             //
localparam GT_RESET_ASSERT    = 1_000_000;      //

localparam GT_RESET_DEASSERT  = 80_000_000;     //
localparam RESET_DEASSERT     = 81_000_000;     // 大于 pma_init 释放时间

	//wire clk_work;
	wire clk_init;
	wire locked;
	wire sys_rst;

	//main
	clk_wiz_0 clk_wiz_0_inst
	(
    // Clock out ports
    .clk_out1(clk_init),     // output clk_out1
    // Status and control signals
    .locked(locked),       // output locked
	// Clock in ports
    .clk_in1_p(clk_p),      // input clk_in1
    .clk_in1_n(clk_n)      // input clk_in1
    );
	assign sys_rst = ~locked;

    reg GT_RESET;
    reg RESET;
    reg [19:0] init_cnt;
    reg [26:0]  reset_delay_cnt;

    always@(posedge clk_init)
    begin
        if(sys_rst)
        begin
            init_cnt <= 'd0;
        end
        else if(~(&init_cnt))
        begin
            init_cnt <= init_cnt + 1'b1;
        end
    end

    always@(posedge clk_init)
    begin
        if(sys_rst)
        begin
            reset_delay_cnt <= 'd0;
        end
        else if(~(&reset_delay_cnt))
        begin
            reset_delay_cnt <= reset_delay_cnt + 1'b1;
        end
    end

    always@(posedge clk_init)
    begin
        if(sys_rst)
        begin
            GT_RESET        <= 1'b0;
            RESET           <= 1'b0;
        end
        else if(init_cnt == GT_RESET_ASSERT)
        begin
            GT_RESET        <= 1'b1;
        end
        else if(init_cnt == RESET_ASSERT)
        begin
            RESET           <= 1'b1;
        end
        else if(reset_delay_cnt == GT_RESET_DEASSERT)
        begin
            GT_RESET        <= 1'b0;
        end
        else if(reset_delay_cnt == RESET_DEASSERT)
        begin
            RESET           <= 1'b0;
        end
    end

    wire                HARD_ERR;
    wire                SOFT_ERR;
    wire                FRAME_ERR;
    wire     [0:7]      DATA_ERR_COUNT;
    wire                LANE_UP;
    wire                CHANNEL_UP;

 aurora_64b66b_0_exdes  #(
    .EXAMPLE_SIMULATION(0),   // 强制为1，禁用脉冲扩展
    .USE_LABTOOLS(1)
)  aurora_64b66b_0_exdes_inst (
    .RESET(RESET),
    .HARD_ERR(HARD_ERR),
    .SOFT_ERR(SOFT_ERR),
    .DATA_ERR_COUNT(DATA_ERR_COUNT),
    .LANE_UP(LANE_UP),
    .CHANNEL_UP(CHANNEL_UP),
    .PMA_INIT(GT_RESET),
    //.INIT_CLK_P(INIT_CLK_P),
    //.INIT_CLK_N(INIT_CLK_N),
    .INIT_CLK_IN(clk_init),
    .GTHQ0_P(GTHQ0_P),
    .GTHQ0_N(GTHQ0_N),
    .RXP(RXP),
    .RXN(RXN),
    .TXP(TXP),
    .TXN(TXN),
    .CRC_PASS_FAIL_N(CRC_PASS_FAIL_N),
    .CRC_VALID(CRC_VALID)
  );

  LED LED_inst(
	.sys_clk(clk_init),
	.sys_rst(sys_rst),
	.led(pl_led)
  );

  ila_top ila_top_inst (
	.clk(clk_init), // input wire clk
	.probe0(DATA_ERR_COUNT), // input wire [7:0]  probe0
	.probe1(HARD_ERR), // input wire [0:0]  probe1
	.probe2(SOFT_ERR), // input wire [0:0]  probe2
	.probe3(CRC_PASS_FAIL_N), // input wire [0:0]  probe3
	.probe4(LANE_UP), // input wire [0:0]  probe4
	.probe5(CHANNEL_UP), // input wire [0:0]  probe5
	.probe6(sys_rst), // input wire [0:0]  probe6
	.probe7(reset_delay_cnt), // input wire [9:0]  probe7
	.probe8(RESET), // input wire [0:0]  probe8
	.probe9(GT_RESET), // input wire [0:0]  probe9
	.probe10(CRC_VALID), // input wire [0:0]  probe10
	.probe11(locked),
	.probe12(init_cnt)
  );

    assign sfp_tx_disable = 1'b0;
    assign sfp_rs0  = 1'b1;
    assign sfp_rs1  = 1'b1;

endmodule
```
