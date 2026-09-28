`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/03/21 10:48:14
// Design Name:
// Module Name: CLK_GEN
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


module CLK_GEN(

	input			clk_i		,

	//input			clk			,

	output			clk_250m	,
	output			clk_156m	,
	output			clk_100m	,

	output			sys_rst

    );

	//reg && wire
	wire			locked	;


	//main code
	clk_wiz_0 clk_wiz_0_inst
	(
    // Clock out ports
    .clk_out1(clk_250m),     // output clk_out1
	.clk_out2(clk_156m),     // output clk_out2
	.clk_out3(clk_100m),     // output clk_out3
    // Status and control signals
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(clk_i));      // shared single-ended 100 MHz after one IBUFDS


	// 复位极性/状态转换；解除时序由对应时钟域的复位包装层保证。
	assign sys_rst = !locked;









endmodule
