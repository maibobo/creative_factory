`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/04/20 16:45:13
// Design Name:
// Module Name: TEMP_RD
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


module TEMP_RD #
	(

		parameter SYS_CLK		= 125000000	,//Hz
		parameter RD_TEMP_CYCLE	= 1000		 //us

	)
	(

	input						sys_clk	,
	input						sys_rst	,

	output	reg					busy	,
	output			[15:0]		temp

    );

	//param
	localparam			CYCLE = RD_TEMP_CYCLE * (SYS_CLK / 1000000);

	//reg && wire
	reg					den_in		;
	reg					dwe_in		;
	reg		[31:0]		cnt_time	;
	reg		[7:0]		daddr_in	;

	reg		[15:0]		di_in		;

	//main code

	always@(posedge sys_clk) begin
		if (sys_rst) begin
			cnt_time	<= 32'd0	;
		end else begin
			if(cnt_time == (CYCLE - 32'd1)) begin
				cnt_time	<= 32'd0	;
			end else begin
				cnt_time	<= cnt_time + 32'd1	;
			end
		end
	end


	always@(posedge sys_clk) begin
		if (sys_rst) begin
			den_in		<= 1'b0		;
			dwe_in		<= 1'b0		;

			daddr_in	<= 8'd0		;
			di_in		<= 16'd0	;
		end else begin
			if(cnt_time == (CYCLE - 32'd10)) begin
				den_in		<= 1'b1	;
				dwe_in		<= 1'b1	;
			end else begin
				den_in		<= 1'b0	;
				dwe_in		<= 1'b0	;
			end
		end
	end

	always@(posedge sys_clk) begin
		if (sys_rst) begin
			busy	<= 1'b0	;
		end else begin
			if((cnt_time >= (CYCLE - 32'd10)) && (cnt_time <= (CYCLE - 32'd1))) begin
				busy	<= 1'b1	;
			end else begin
				busy	<= 1'b0	;
			end
		end
	end

	sys_mon sys_mon_inst (
		.di_in			(di_in		), // input wire [15 : 0] di_in
		.daddr_in		(daddr_in	), // input wire [7 : 0] daddr_in
		.den_in			(den_in		), // input wire den_in
		.dwe_in			(dwe_in		), // input wire dwe_in
		.drdy_out		(), // output wire drdy_out
		.do_out			(temp		), // output wire [15 : 0] do_out
		.dclk_in		(sys_clk	), // input wire dclk_in
		.reset_in		(sys_rst	), // input wire reset_in
		.channel_out	(), // output wire [5 : 0] channel_out
		.eoc_out		(), // output wire eoc_out
		.alarm_out		(), // output wire alarm_out
		.eos_out		(), // output wire eos_out
		.busy_out		()  // output wire busy_out
	);

/*
	SYSMONE1 #(
		// INIT_40 - INIT_44: SYSMON configuration registers
		.INIT_40(16'h0000),
		.INIT_41(16'h0000),
		.INIT_42(16'h0000),
		.INIT_43(16'h0000),
		.INIT_44(16'h0000),
		.INIT_45(16'h0000),              // Analog Bus Register
		// INIT_46 - INIT_4F: Sequence Registers
		.INIT_46(16'h0000),
		.INIT_47(16'h0000),
		.INIT_48(16'h0000),
		.INIT_49(16'h0000),
		.INIT_4A(16'h0000),
		.INIT_4B(16'h0000),
		.INIT_4C(16'h0000),
		.INIT_4D(16'h0000),
		.INIT_4E(16'h0000),
		.INIT_4F(16'h0000),
		// INIT_50 - INIT_5F: Alarm Limit Registers
		.INIT_50(16'h0000),
		.INIT_51(16'h0000),
		.INIT_52(16'h0000),
		.INIT_53(16'h0000),
		.INIT_54(16'h0000),
		.INIT_55(16'h0000),
		.INIT_56(16'h0000),
		.INIT_57(16'h0000),
		.INIT_58(16'h0000),
		.INIT_59(16'h0000),
		.INIT_5A(16'h0000),
		.INIT_5B(16'h0000),
		.INIT_5C(16'h0000),
		.INIT_5D(16'h0000),
		.INIT_5E(16'h0000),
		.INIT_5F(16'h0000),
		// INIT_60 - INIT_6F: User Supply Alarms
		.INIT_60(16'h0000),
		.INIT_61(16'h0000),
		.INIT_62(16'h0000),
		.INIT_63(16'h0000),
		.INIT_64(16'h0000),
		.INIT_65(16'h0000),
		.INIT_66(16'h0000),
		.INIT_67(16'h0000),
		.INIT_68(16'h0000),
		.INIT_69(16'h0000),
		.INIT_6A(16'h0000),
		.INIT_6B(16'h0000),
		.INIT_6C(16'h0000),
		.INIT_6D(16'h0000),
		.INIT_6E(16'h0000),
		.INIT_6F(16'h0000),
		// Programmable Inversion Attributes: Specifies the use of the built-in programmable inversion on
		// specific pins
		.IS_CONVSTCLK_INVERTED(1'b0),    // Optional inversion for CONVSTCLK, 0-1
		.IS_DCLK_INVERTED(1'b0),         // Optional inversion for DCLK, 0-1
		// Simulation attributes: Set for proper simulation behavior
		.SIM_MONITOR_FILE("design.txt"), // Analog simulation data file name
		// User Voltage Monitor: SYSMON User voltage monitor
		.SYSMON_VUSER0_BANK(0),          // Specify IO Bank for User0
		.SYSMON_VUSER0_MONITOR("NONE"),  // Specify Voltage for User0
		.SYSMON_VUSER1_BANK(0),          // Specify IO Bank for User1
		.SYSMON_VUSER1_MONITOR("NONE"),  // Specify Voltage for User1
		.SYSMON_VUSER2_BANK(0),          // Specify IO Bank for User2
		.SYSMON_VUSER2_MONITOR("NONE"),  // Specify Voltage for User2
		.SYSMON_VUSER3_MONITOR("NONE")   // Specify Voltage for User3
	)
	SYSMONE1_inst (
		// ALARMS outputs: ALM, OT
		.ALM(	),                   // 16-bit output: Output alarm for temp, Vccint, Vccaux and Vccbram
		.OT(	),                     // 1-bit output: Over-Temperature alarm
		// Dynamic Reconfiguration Port (DRP) outputs: Dynamic Reconfiguration Ports
		.DO(temp),                     // 16-bit output: DRP output data bus
		.DRDY(	),                 // 1-bit output: DRP data ready
		// I2C Interface outputs: Ports used with the I2C DRP interface
		.I2C_SCLK_TS(	),   // 1-bit output: I2C_SCLK output port
		.I2C_SDA_TS(	),     // 1-bit output: I2C_SDA_TS output port
		// STATUS outputs: SYSMON status ports
		.BUSY(	),                 // 1-bit output: System Monitor busy output
		.CHANNEL(	),           // 6-bit output: Channel selection outputs
		.EOC(	),                   // 1-bit output: End of Conversion
		.EOS(	),                   // 1-bit output: End of Sequence
		.JTAGBUSY(	),         // 1-bit output: JTAG DRP transaction in progress output
		.JTAGLOCKED(	),     // 1-bit output: JTAG requested DRP port lock
		.JTAGMODIFIED(	), // 1-bit output: JTAG Write to the DRP has occurred
		.MUXADDR(	),           // 5-bit output: External MUX channel decode
		// Auxiliary Analog-Input Pairs inputs: VAUXP[15:0], VAUXN[15:0]
		.VAUXN(0),               // 16-bit input: N-side auxiliary analog input
		.VAUXP(0),               // 16-bit input: P-side auxiliary analog input
		// CONTROL and CLOCK inputs: Reset, conversion start and clock inputs
		.CONVST(0),             // 1-bit input: Convert start input
		.CONVSTCLK(0),       // 1-bit input: Convert start input
		.RESET(sys_rst),               // 1-bit input: Active-High reset
		// Dedicated Analog Input Pair inputs: VP/VN
		.VN(0),                     // 1-bit input: N-side analog input
		.VP(0),                     // 1-bit input: P-side analog input
		// Dynamic Reconfiguration Port (DRP) inputs: Dynamic Reconfiguration Ports
		.DADDR(daddr_in),               // 8-bit input: DRP address bus
		.DCLK(sys_clk),                 // 1-bit input: DRP clock
		.DEN(den_in),                   // 1-bit input: DRP enable signal
		.DI(di_in),                     // 16-bit input: DRP input data bus
		.DWE(dwe_in),                   // 1-bit input: DRP write enable
		// I2C Interface inputs: Ports used with the I2C DRP interface
		.I2C_SCLK(0),         // 1-bit input: I2C_SCLK input port
		.I2C_SDA(0)            // 1-bit input: I2C_SDA input port
	);

	XADC #(
		// INIT_40 - INIT_42: XADC configuration registers
		.INIT_40(16'h0000),
		.INIT_41(16'h0000),
		.INIT_42(16'h0800),
		// INIT_48 - INIT_4F: Sequence Registers
		.INIT_48(16'h0000),
		.INIT_49(16'h0000),
		.INIT_4A(16'h0000),
		.INIT_4B(16'h0000),
		.INIT_4C(16'h0000),
		.INIT_4D(16'h0000),
		.INIT_4F(16'h0000),
		.INIT_4E(16'h0000),                // Sequence register 6
		// INIT_50 - INIT_58, INIT5C: Alarm Limit Registers
		.INIT_50(16'h0000),
		.INIT_51(16'h0000),
		.INIT_52(16'h0000),
		.INIT_53(16'h0000),
		.INIT_54(16'h0000),
		.INIT_55(16'h0000),
		.INIT_56(16'h0000),
		.INIT_57(16'h0000),
		.INIT_58(16'h0000),
		.INIT_5C(16'h0000),
		// Simulation attributes: Set for proper simulation behavior
		.SIM_DEVICE("7SERIES"),            // Select target device (values)
		.SIM_MONITOR_FILE("design.txt")  // Analog simulation data file name
	)
	sys_mon_inst (
		// ALARMS: 8-bit (each) output: ALM, OT
		.ALM			(	), // 8-bit output: Output alarm for temp, Vccint, Vccaux and Vccbram
		.OT				(	), // 1-bit output: Over-Temperature alarm
		// Dynamic Reconfiguration Port (DRP): 16-bit (each) output: Dynamic Reconfiguration Ports
		.DO				(temp		), // 16-bit output: DRP output data bus
		.DRDY			(	), // 1-bit output: DRP data ready
		// STATUS: 1-bit (each) output: XADC status ports
		.BUSY			(	), // 1-bit output: ADC busy output
		.CHANNEL		(	), // 5-bit output: Channel selection outputs
		.EOC			(	), // 1-bit output: End of Conversion
		.EOS			(	), // 1-bit output: End of Sequence
		.JTAGBUSY		(	), // 1-bit output: JTAG DRP transaction in progress output
		.JTAGLOCKED		(	), // 1-bit output: JTAG requested DRP port lock
		.JTAGMODIFIED	(	), // 1-bit output: JTAG Write to the DRP has occurred
		.MUXADDR		(	), // 5-bit output: External MUX channel decode
		// Auxiliary Analog-Input Pairs: 16-bit (each) input: VAUXP[15:0], VAUXN[15:0]
		.VAUXN			(0	), // 16-bit input: N-side auxiliary analog input
		.VAUXP			(0	), // 16-bit input: P-side auxiliary analog input
		// CONTROL and CLOCK: 1-bit (each) input: Reset, conversion start and clock inputs
		.CONVST			(0	), // 1-bit input: Convert start input
		.CONVSTCLK		(0	), // 1-bit input: Convert start input
		.RESET			(sys_rst	), // 1-bit input: Active-high reset
		// Dedicated Analog Input Pair: 1-bit (each) input: VP/VN
		.VN				(0			), // 1-bit input: N-side analog input
		.VP				(0			), // 1-bit input: P-side analog input
		// Dynamic Reconfiguration Port (DRP): 7-bit (each) input: Dynamic Reconfiguration Ports
		.DADDR			(daddr_in	), // 7-bit input: DRP address bus
		.DCLK			(sys_clk	), // 1-bit input: DRP clock
		.DEN			(den_in		), // 1-bit input: DRP enable signal
		.DI				(di_in		), // 16-bit input: DRP input data bus
		.DWE			(dwe_in		)  // 1-bit input: DRP write enable
	);
*/

	//debug
	ila_temp ila_temp_inst (
		.clk	(sys_clk	), // input wire clk

		.probe0	(den_in		), // input wire [0:0]  probe0
		.probe1	(dwe_in		), // input wire [0:0]  probe1
		.probe2	(cnt_time	), // input wire [31:0]  probe2
		.probe3	(daddr_in	), // input wire [7:0]  probe3
		.probe4	(temp		), // input wire [15:0]  probe4
		.probe5	(busy		) // input wire [0:0]  probe5
	);


endmodule
