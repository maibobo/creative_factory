# LED

- Category: `pcie`
- Source: `R:\pcie_07\RTDS_test-1ch\RTDS_test-1ch\RTDS_test.srcs\sources_1\new\LED.v`
- SHA-256: `1f45e5cbda11736f2ee65f47bdbf8cdac7b56019b3827289249b14d31728b083`
- Extractor: `text`
- Tags: `aurora, pcie, rtl, xdma`
- Duplicate sources:
  - E:\PCIE-CPU\RTDS_test-1ch\RTDS_test.srcs\sources_1\new\LED.v

```verilog
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/03/26 09:43:55
// Design Name:
// Module Name: LED
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


module LED #
	(
		parameter  SYS_CLK		= 125000000,//Hz
		parameter  LED_CYCLE	= 1000000//us
	)
	(

	input					i_sys_clk	,//125M
	input					i_sys_rst	,

	output	reg		o_led

    );

	//param
	localparam			CYCLE = LED_CYCLE * (SYS_CLK / 1000000);

	//reg && wire
	reg	[31:0]			led_cnt;
	//main
	always@(posedge i_sys_clk)
	begin
		if(i_sys_rst)
		begin
			o_led		<= 1'b1;
			led_cnt	<= 32'd0;
		end
		else if(led_cnt == CYCLE/2 - 1)
		//else if(led_cnt == 62500000)
		begin
			o_led		<= ~o_led;
			led_cnt	<= 32'd0;
		end
		else
		begin
			o_led		<= o_led;
			led_cnt	<= led_cnt + 32'b1;
		end
	end


endmodule
```
