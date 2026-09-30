`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/03/30 08:45:23
// Design Name:
// Module Name: Aurora_frame_gen
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


module Aurora_frame_gen(

	input						i_clk_100m		,
	input						i_sys_rst		,

	output	reg					o_data66_valid	,
	output	reg		[65:0]		o_data66

    );

	//parameter
	localparam		M_IDLE		=	0;
	localparam		M_SOF		=	1;
	localparam		M_DATA		=	2;
	localparam		M_EOF		=	3;
	localparam		M_STOP		=	4;



	//reg && wire
	reg		[31:0]	data_cnt		;
	reg				data_valid		;
	reg		[63:0]	data			;
	reg		[2:0]	T_S				;
	reg				SOF				;
	reg				EOF				;


	//reg				o_data66_valid	;
	//reg		[65:0]	o_data66		;

	//main code

	//上板debug
	//wire           WR_START        ;
	//vio_WR_START vio_WR_START_inst (
	//	.clk(i_clk_100m),                // input wire clk
	//	.probe_in0(WR_START),    // input wire [0 : 0] probe_in0
	//	.probe_out0(WR_START)  // output wire [0 : 0] probe_out0
	//);

	//Sim+上板
	reg					WR_START        ;
	reg		[31:0]		WR_START_cnt	;

	reg		[31:0]		frame_gen_cnt	;


	always@(posedge i_clk_100m)begin
		if(i_sys_rst)begin
			WR_START		<= 1'b0;
			WR_START_cnt	<= 1'b0;
		end else if(WR_START_cnt == 32'd100)begin//1us
			WR_START		<= 1'b1;
			WR_START_cnt	<= WR_START_cnt;
		end else begin
			WR_START		<= 1'b0;
			WR_START_cnt	<= WR_START_cnt + 32'd1;
		end
	end

	always @(posedge i_clk_100m)begin
		if(i_sys_rst)begin
			data_cnt	<= 32'd1	;
			data_valid	<= 1'b0		;
			data		<= 64'd0	;
			T_S 		<=0			;
			SOF			<= 1'b0		;
			EOF			<= 1'b0		;

			frame_gen_cnt	<= 32'd0	;
		end
		else begin
			SOF	<= 1'b0;
			EOF	<= 1'b0;
			data_valid	<= 1'b0;
			case(T_S)
			M_IDLE:begin
				if(WR_START)begin
					data_cnt	<= 32'd1;

					data		<= 64'd0;
					T_S			<= M_SOF;
				end
			end
			M_SOF:begin
				SOF			<= 1'b1;
				data_cnt	<= data_cnt + 32'd1;
				data_valid	<= 1'b1;
				data		<= data + 64'd1;
				T_S			<= M_DATA;
			end
			M_DATA:begin
				data_cnt	<= data_cnt + 32'd1;
				data_valid	<= 1'b1;
				data		<= data + 64'd1;
				if(data_cnt >= (32'd8192 - 32'd1))begin
					T_S		<= M_EOF;
				end
			end
			M_EOF:begin
				EOF			<= 1'b1;
				data_cnt	<= data_cnt + 32'd1;
				data_valid	<= 1'b1;
				data		<= data + 64'd1;
				T_S			<= M_STOP;
			end

			M_STOP:begin
				if((frame_gen_cnt >= 32'd10) && (frame_gen_cnt <= 32'd100000)) begin
					T_S			<= M_STOP;

					frame_gen_cnt	<= frame_gen_cnt + 32'd1	;
				end else if(frame_gen_cnt >= 32'd100020) begin
					T_S			<= M_STOP;

					frame_gen_cnt	<= frame_gen_cnt + 32'd1	;
				end else begin
					T_S			<= M_IDLE;

					frame_gen_cnt	<= frame_gen_cnt + 32'd1	;
				end
			end

			default:
				T_S <= M_IDLE;
			endcase
		end
	end

	always@(posedge i_clk_100m)begin
		if(i_sys_rst)begin
			o_data66_valid	<= 1'b0;
			o_data66		<= 66'd0;
		end else begin
			o_data66_valid	<= data_valid;
			o_data66		<= {SOF,data,EOF};
		end
	end





endmodule
