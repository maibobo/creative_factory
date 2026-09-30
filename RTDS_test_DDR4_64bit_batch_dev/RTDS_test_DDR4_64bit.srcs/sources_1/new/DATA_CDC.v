`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/03/31 13:47:51
// Design Name:
// Module Name: DATA_CDC
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


module DATA_CDC(

	input						i_clk_100m		,
	input						i_clk_250m		,
	input						i_sys_rst		,

	//Aurora—>PCIe
	//input						i_data66_valid	,
	//input			[65:0]		i_data66		,
	output						o_data66_valid	,
	output			[65:0]		o_data66		,

	//PCIe——》Aurora
	input						i_data64_valid	,
	input			[65:0]		i_data64


    );












	//PCIe—>Aurora
	PCIe_Aurora_cdc PCIe_Aurora_cdc_inst(

		.i_clk_100m		(i_clk_100m		),
		.i_clk_250m		(i_clk_250m		),
		.i_sys_rst		(i_sys_rst		),

		.i_data64_valid	(i_data64_valid	),
		.i_data64		(i_data64		),

		.o_data_valid	(	),
        .o_data			(	)

    );




	//Aurora—>PCIe





	//DEBUG
	wire					data66_valid	;
	wire	[65:0]			data66			;

	Aurora_frame_gen Debug(

	.i_clk_100m		(i_clk_100m		),
	.i_sys_rst		(i_sys_rst		),

	.o_data66_valid	(data66_valid	),
	.o_data66		(data66			)

    );




	Aurora_PCIe_cdc Aurora_PCIe_cdc_inst(

		.i_clk_100m		(i_clk_100m		),
		.i_clk_250m		(i_clk_250m		),
		.i_sys_rst		(i_sys_rst		),

		.i_data66_valid	(data66_valid	),
		.i_data66		(data66			),
		//.i_data66_valid	(i_data66_valid	),
		//.i_data66		(i_data66		),


		.o_data66_valid	(o_data66_valid	),
		.o_data66		(o_data66		)


    );


















endmodule
