`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/21 14:11:48
// Design Name: 
// Module Name: TB_TOP
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


module TB_TOP();

// reg sysclk_p;
//
//
// TOP TOP_inst
//(
//    .clk_p(sysclk_p),
//    .clk_n(~sysclk_p)
// );
// 
//initial begin
//     sysclk_p  = 0;
//     #100;
//end
//
//    always #5 sysclk_p = ~sysclk_p;

	reg	clk		;
	
	TOP TOP_inst
	(
		//.clk_p(sysclk_p),
		//.clk_n(~sysclk_p)
		.clk(clk)
	);

initial begin
     clk  = 0;
     #100;
end

    always #20 clk = ~clk;
	
endmodule
