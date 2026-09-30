`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/11 16:08:04
// Design Name: 
// Module Name: led
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


module LED(

	input		sys_clk,
	input 		sys_rst,

	output reg		led

    );
	//reg && wire
	reg [31:0]		cnt;
	
	//main
	always@(posedge sys_clk) 
	begin
		if(sys_rst)
		begin
			led <= 1'b1;
			cnt <= 'd0;
		end
		//else if(cnt == 25000000)
		else if(cnt == 100000000)
		begin
			led <= ~led;
			cnt <= 'd0;
		end
		else
		begin
			led <= led;
			cnt <= cnt + 1'b1;
		end
	end
	
	
endmodule