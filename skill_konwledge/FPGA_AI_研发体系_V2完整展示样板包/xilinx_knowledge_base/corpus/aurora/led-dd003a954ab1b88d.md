# led

- Category: `aurora`
- Source: `R:\aurora_64b66b_10p3125g_2020_2_verified\verification\aurora_64b66b_10p3125g_verification.srcs\sources_1\new\led.v`
- SHA-256: `dd003a954ab1b88db38f1396217d76835a0029011f84384070a157d3c2681702`
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

	output reg	led

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
```
