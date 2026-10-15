# Aurora_PCIe_cdc

- Category: `pcie`
- Source: `R:\pcie_07\RTDS_test-1ch\RTDS_test-1ch\RTDS_test.srcs\sources_1\new\Aurora_PCIe_cdc.v`
- SHA-256: `d96707c9855111931712c1831c0a8ed4f245b523d361796185938d02def51a1c`
- Extractor: `text`
- Tags: `aurora, pcie, rtl, xdma`
- Duplicate sources:
  - E:\PCIE-CPU\RTDS_test-1ch\RTDS_test.srcs\sources_1\new\Aurora_PCIe_cdc.v

```verilog
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/03/27 14:06:54
// Design Name:
// Module Name: Aurora_PCIe_cdc
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


module Aurora_PCIe_cdc(

	input						i_clk_100m		,
	input						i_clk_250m		,
	input						i_sys_rst		,

	input						i_data66_valid	,
	input			[65:0]		i_data66		,

	output						o_data66_valid	,
	output			[65:0]		o_data66

    );

	//parameter


	//reg && wire
	wire			fifo_rd_en		;
	wire			fifo_empty		;

	//main code

	fifo_cdc_pcie fifo_cdc_pcie_inst (
		.rst	(i_sys_rst		), // input wire rst
		.wr_clk	(i_clk_100m		), // input wire wr_clk
		.rd_clk	(i_clk_250m		), // input wire rd_clk
		.din	(i_data66		), // input wire [65 : 0] din
		.wr_en	(i_data66_valid	), // input wire wr_en
		.rd_en	(fifo_rd_en		), // input wire rd_en
		.dout	(o_data66		), // output wire [65 : 0] dout
		.full	(	), // output wire full
		.empty	(fifo_empty		) // output wire empty
	);

	assign fifo_rd_en = !fifo_empty;
	assign o_data66_valid = fifo_rd_en;


endmodule
```
