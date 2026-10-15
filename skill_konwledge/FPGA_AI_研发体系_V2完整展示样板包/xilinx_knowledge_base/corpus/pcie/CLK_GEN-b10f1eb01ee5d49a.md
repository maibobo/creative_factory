# CLK_GEN

- Category: `pcie`
- Source: `R:\pcie_07\RTDS_test-1ch\RTDS_test-1ch\RTDS_test.srcs\sources_1\new\CLK_GEN.v`
- SHA-256: `b10f1eb01ee5d49a777f44866ad21e0617649236b3b5c2f0871d3f5c165c7cee`
- Extractor: `text`
- Tags: `aurora, pcie, rtl, xdma`
- Duplicate sources:
  - E:\PCIE-CPU\RTDS_test-1ch\RTDS_test.srcs\sources_1\new\CLK_GEN.v

```verilog
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

	input			clk_p		,
	input			clk_n		,

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
    .clk_in1_p(clk_p),    // input clk_in1_p
    .clk_in1_n(clk_n));    // input clk_in1_n
    //.clk_in1(clk));      // input clk_in1


	assign sys_rst = !locked;


endmodule
```
