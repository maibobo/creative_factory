`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/03/31 13:46:18
// Design Name:
// Module Name: PCIe_Aurora_cdc
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


module PCIe_Aurora_cdc(

	input						i_clk_100m		,
	input						i_clk_250m		,
	input						i_sys_rst		,

	//PCIe——》Aurora
	input						i_data64_valid	,
	input			[65:0]		i_data64		,

	output						o_data_valid	,
	output			[65:0]		o_data

    );


	wire				fifo_rd_en	;
	wire				fifo_empty	;
	wire	[65:0]		fifo_dout	;


	ila_0 u1 (
		.clk	(i_clk_250m		), // input wire clk


		.probe0	(i_data64_valid	), // input wire [0:0]  probe0
		.probe1	(i_data64		), // input wire [65:0]  probe1
		.probe2	(fifo_full		) // input wire [0:0]  probe2

	);

	//深度与一帧数据长度有关
	fifo_cdc_aurora fifo_cdc_aurora_inst (
		.srst	(i_sys_rst		), // input wire srst
		.wr_clk	(i_clk_250m		), // input wire wr_clk
		.rd_clk	(i_clk_100m		), // input wire rd_clk
		.din	(i_data64		), // input wire [65 : 0] din
		.wr_en	(i_data64_valid	), // input wire wr_en
		.rd_en	(fifo_rd_en		), // input wire rd_en
		.dout	(fifo_dout		), // output wire [65 : 0] dout
		.full	(fifo_full		), // output wire full
		.empty	(fifo_empty		), // output wire empty
		.wr_rst_busy(), // output wire wr_rst_busy
		.rd_rst_busy()  // output wire rd_rst_busy
	);
	// 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
	assign fifo_rd_en	= !fifo_empty	;
	// 连接本级与上下游同一事务字段；保持原有时序和位宽语义。
	assign o_data_valid	= fifo_rd_en	;
	// 连接本级与上下游同一事务字段；保持原有时序和位宽语义。
	assign o_data		= fifo_dout		;

	ila_0 u2 (
		.clk	(i_clk_100m		), // input wire clk


		.probe0	(o_data_valid	), // input wire [0:0]  probe0
		.probe1	(o_data			), // input wire [65:0]  probe1
		.probe2	(fifo_empty		) // input wire [0:0]  probe2

	);

endmodule
