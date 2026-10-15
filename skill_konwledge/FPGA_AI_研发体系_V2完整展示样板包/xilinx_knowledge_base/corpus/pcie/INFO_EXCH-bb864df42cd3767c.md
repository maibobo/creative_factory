# INFO_EXCH

- Category: `pcie`
- Source: `E:\PCIE-CPU\RTDS_test-1ch\RTDS_test.srcs\sources_1\new\INFO_EXCH.v`
- SHA-256: `bb864df42cd3767cfb43b23d7627a7a3be1caf03583bada40c1ebab9d77a0f0b`
- Extractor: `text`
- Tags: `pcie, rtl, xdma`
- Duplicate sources:
  - none

```verilog
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/04/20 16:31:01
// Design Name:
// Module Name: INFO_EXCH
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

// =============================================================================
// 模块用途：提供 XDMA 用户 BAR 后的 32-bit AXI-Lite 软件控制/状态寄存器。
// 输入：AXI-Lite 读写事务、FPGA 温度、Adapter 的 RX 地址/长度/中断状态和
// CPU_WR_DONE_resp；输出：CPU→FPGA 地址/长度、RD_START、CPU_REC_STATE、
// INT_STATE/CLEAR_INTER 单周期读清脉冲。
//
// 关键寄存器：0x10 中断状态(read-to-clear)、0x14 接收所有权确认、
// 0x20 CPU_WR_DONE(0→1→0，上升沿启动)、0x24/0x28 CPU→Aurora 地址/长度。
// 失败定位：AXI 无响应查 AW/W 或 AR/R 握手；寄存器不更新查 WSTRB/地址；
// RD_START 不出查 0x20 上升沿；IRQ 不清查 0x10 读握手和两个清除脉冲。
// =============================================================================


module INFO_EXCH#
	(
		// Users to add parameters here
		parameter integer	VERSION				= 32'h0000_1001,
		parameter integer	PROG_TIME			= 32'h2026_0506,
		parameter integer	CH_BUF_LEN			= 32'h0000_8000,
		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer	C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer	C_S_AXI_ADDR_WIDTH	= 32
	)
	(
		// Users to add ports here
		input	wire	[C_S_AXI_DATA_WIDTH-1 : 0]	FPGA_TEMP_W				,

		input	wire	[0 : 0]						INT_STATE_W				,
		input	wire	[0 : 0]						CPU_REC_STATE_W			,
		input	wire	[C_S_AXI_DATA_WIDTH-1 : 0]	FPGA_CPU_START_ADDR		,
		input	wire	[C_S_AXI_DATA_WIDTH-1 : 0]	FPGA_CPU_LEN			,
		input	wire	[0 : 0]						CPU_WR_DONE_resp		,

		output										r_INT_STATE				,
		output										r_CLEAR_INTER			,
		output										r_CPU_REC_STATE			,
		output										r_RD_START				,
		output			[C_S_AXI_DATA_WIDTH-1 : 0]	r_CPU_FPGA_START_ADDR	,
		output			[C_S_AXI_DATA_WIDTH-1 : 0]	r_CPU_FPGA_LEN			,


		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave)
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg		[C_S_AXI_ADDR_WIDTH-1 : 0]	axi_awaddr				;
	reg  								axi_awready				;
	reg  								axi_wready				;
	reg		[1 : 0] 					axi_bresp				;
	reg  								axi_bvalid				;
	reg		[C_S_AXI_ADDR_WIDTH-1 : 0]	axi_araddr				;
	reg  								axi_arready				;
	reg		[C_S_AXI_DATA_WIDTH-1 : 0]	axi_rdata				;
	reg		[1 : 0] 					axi_rresp				;
	reg									axi_rvalid				;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 14;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 32

	reg		[0 : 0]						INT_STATE_R				;

	reg									CLEAR_INTER_R			;
	reg		[C_S_AXI_DATA_WIDTH-1 : 0]	CPU_WR_DONE				;
	reg		[C_S_AXI_DATA_WIDTH-1 : 0]	CPU_REC_STATE			;
	reg		[C_S_AXI_DATA_WIDTH-1 : 0]	CPU_FPGA_START_ADDR		;
	reg		[C_S_AXI_DATA_WIDTH-1 : 0]	CPU_FPGA_LEN			;

	wire	 							slv_reg_rden			;
	wire	 							slv_reg_wren			;
	reg		[C_S_AXI_DATA_WIDTH-1:0]	reg_data_out			;
	integer	 							byte_index				;
	reg	 								aw_en					;


	// ---------- 语义段 1：AXI-Lite 外部端口映射 ----------
	// 输入：内部 axi_* 寄存器；输出：S_AXI ready/response/read data。
	// 作用：把协议状态寄存器连接到模块端口，不包含地址译码。
	// 失败定位：外部端口为 X/Z 时先查本段映射和复位。
	// I/O Connections assignments
	assign S_AXI_AWREADY= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	// ---------- 语义段 2：写地址/写数据联合接收 ----------
	// 输入：AWVALID、WVALID、AWADDR、WDATA；输出：AWREADY/WREADY 和锁存地址。
	// 作用：本实现只接受单个未完成事务，地址与数据同时有效时接收。
	// 失败定位：软件写卡住时同时观察 AW/W 两通道和 aw_en。
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end
	  else
	    begin
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // slave is ready to accept write address when
	          // there is a valid write address and write data
	          // on the write address and data bus. This design
	          // expects no outstanding transactions.
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else
	        begin
	          axi_awready <= 1'b0;
	        end
	    end
	end

	// Implement axi_awaddr latching
	// This process is used to latch the address when both
	// S_AXI_AWVALID and S_AXI_WVALID are valid.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end
	  else
	    begin
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // Write Address latching
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end
	end

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end
	  else
	    begin
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          // slave is ready to accept write data when
	          // there is a valid write address and write data
	          // on the write address and data bus. This design
	          // expects no outstanding transactions.
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end
	end

	// ---------- 语义段 3：软件可写寄存器与字节使能 ----------
	// 输入：已接受的地址、WDATA、WSTRB；输出：0x14/0x20/0x24/0x28 寄存器。
	// 作用：保留 AXI-Lite 逐字节写语义，并给出软件命令的持久电平。
	// 失败定位：只更新部分字节时检查 WSTRB；地址应使用模块内低 16-bit 偏移。
	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
	    begin

			CPU_REC_STATE			<= 'd0			;

			CPU_WR_DONE				<= 'd0			;
			CPU_FPGA_START_ADDR		<= 32'd32*1024	;
			CPU_FPGA_LEN			<= 32'd32*1024	;//32KB

		end
		else begin
			if (slv_reg_wren)
			begin
				//case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
				case ( axi_awaddr[15:0] )

					16'h0014:
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
						if ( S_AXI_WSTRB[byte_index] == 1 ) begin
							// Respective byte enables are asserted as per write strobes
							CPU_REC_STATE[(byte_index*8) +: 8]	<= S_AXI_WDATA[(byte_index*8) +: 8];
						end
					end


					16'h0020:
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
						if ( S_AXI_WSTRB[byte_index] == 1 ) begin
							// Respective byte enables are asserted as per write strobes
							CPU_WR_DONE[(byte_index*8) +: 8]	<= S_AXI_WDATA[(byte_index*8) +: 8];
						end
					end
					16'h0024:
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
						if ( S_AXI_WSTRB[byte_index] == 1 ) begin
							// Respective byte enables are asserted as per write strobes
							CPU_FPGA_START_ADDR[(byte_index*8) +: 8]	<= S_AXI_WDATA[(byte_index*8) +: 8];
						end
					end
					16'h0028:
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
						if ( S_AXI_WSTRB[byte_index] == 1 ) begin
							// Respective byte enables are asserted as per write strobes
							CPU_FPGA_LEN[(byte_index*8) +: 8]	<= S_AXI_WDATA[(byte_index*8) +: 8];
						end
					end

					default :
					begin

						CPU_REC_STATE			<= CPU_REC_STATE			;

						CPU_WR_DONE				<= CPU_WR_DONE				;
						CPU_FPGA_START_ADDR		<= CPU_FPGA_START_ADDR		;
						CPU_FPGA_LEN			<= CPU_FPGA_LEN				;

					end
				endcase
			end
		end
	end


	// ---------- 语义段 4：写响应 ----------
	// 输入：地址/数据接收完成与 BREADY；输出：BVALID/BRESP=OKAY。
	// 作用：通知 XDMA AXI-Lite master 本次寄存器写已完成。
	// 失败定位：寄存器已变但软件仍等待时检查 BVALID/BREADY 生命周期。
	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
	// This marks the acceptance of address and indicates the status of
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end
	  else
	    begin
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid)
	            //check if bready is asserted while bvalid is high)
	            //(there is a possibility that bready is always asserted high)
	            begin
	              axi_bvalid <= 1'b0;
	            end
	        end
	    end
	end

	// ---------- 语义段 5：读地址接收 ----------
	// 输入：ARVALID/ARADDR；输出：ARREADY 和锁存读地址。
	// 作用：每次只接收一个读事务，为寄存器译码提供稳定地址。
	// 失败定位：读请求无返回先确认 ARVALID 是否真正与 ARREADY 握手。
	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is
	// de-asserted when reset (active low) is asserted.
	// The read address is also latched when S_AXI_ARVALID is
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end
	  else
	    begin
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end
	end

	// ---------- 语义段 6：读响应握手 ----------
	// 输入：读地址握手和 RREADY；输出：RVALID/RRESP=OKAY。
	// 作用：保持 RVALID 直到 master 接受，避免读数据只出现一个不可见脉冲。
	// 失败定位：有 reg_data_out 无软件返回时检查 RVALID/RREADY。
	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers
	// data are available on the axi_rdata bus at this instance. The
	// assertion of axi_rvalid marks the validity of read data on the
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid
	// is deasserted on reset (active low). axi_rresp and axi_rdata are
	// cleared to zero on reset (active low).
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end
	  else
	    begin
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end
	    end
	end

	// ---------- 语义段 7：寄存器读译码 ----------
	// 输入：锁存读地址及 Adapter/温度/软件寄存器状态；输出：reg_data_out。
	// 作用：组合选择固定信息、IRQ 状态、双向地址长度和完成响应。
	// 失败定位：读值错误时按 0x00～0x28 偏移逐项核对，不使用 BD 绝对地址译码。
	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
	      //case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
		  case ( axi_araddr[15:0] )
	        16'h0000	: reg_data_out	<= VERSION				;
	        16'h0004	: reg_data_out	<= PROG_TIME			;
	        16'h0008	: reg_data_out	<= CH_BUF_LEN			;
			16'h000C	: reg_data_out	<= FPGA_TEMP_W			;

			16'h0010	: reg_data_out	<= INT_STATE_W			;
			16'h0014	: reg_data_out	<= CPU_REC_STATE_W		;
			16'h0018	: reg_data_out	<= FPGA_CPU_START_ADDR	;
			16'h001C	: reg_data_out	<= FPGA_CPU_LEN			;

			16'h0020	: reg_data_out	<= CPU_WR_DONE_resp		;
			16'h0024	: reg_data_out	<= CPU_FPGA_START_ADDR	;
			16'h0028	: reg_data_out	<= CPU_FPGA_LEN			;


	        default : reg_data_out <= 0;
	      endcase
	end

	// ---------- 语义段 8：读数据锁存 ----------
	// 输入：slv_reg_rden 和 reg_data_out；输出：AXI RDATA。
	// 作用：在读地址被接受时锁存数据，供后续 RVALID/RREADY 握手。
	// 失败定位：译码正确但 RDATA 错时检查 slv_reg_rden 的时序。
	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end
	  else
	    begin
	      // When there is a valid read address (S_AXI_ARVALID) with
	      // acceptance of read address by the slave (axi_arready),
	      // output the read dada
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end
	    end
	end

	// ---------- 语义段 9：0x10 read-to-clear ----------
	// 输入：对 0x10 的真实 AR 握手；输出：INT_STATE_R/CLEAR_INTER_R 单周期。
	// 作用：软件读取状态的同一事务触发 Adapter 清 IRQ 和 sticky 状态。
	// 失败定位：不能只看 ARADDR，必须确认 ARREADY && ARVALID 同拍成立。
	// Add user logic here

	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			INT_STATE_R		<= 1'b0;
			CLEAR_INTER_R	<= 1'b0;
		end
		else
		begin
			if (S_AXI_ARREADY && S_AXI_ARVALID && (S_AXI_ARADDR[15:0] == 16'h0010))
			begin
				INT_STATE_R		<= 1'b1;
				CLEAR_INTER_R	<= 1'b1;
	        end
			else
			begin
				INT_STATE_R		<= 1'b0;
				CLEAR_INTER_R	<= 1'b0;
			end
	    end
	end

	// ---------- 语义段 10：0x20 上升沿生成 RD_START ----------
	// 输入：CPU_WR_DONE[0] 持久寄存器；输出：单周期 CPU_WR_DONE_pos/RD_START。
	// 作用：软件必须写 0→1→0，只有上升沿启动一次 CPU→Aurora 事务。
	// 失败定位：重复写 1 不会再次触发；检查延迟寄存器和软件写序列。
	//CPU_WR_DONE[0]
	reg			CPU_WR_DONE_d	;
	wire		CPU_WR_DONE_pos	;
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			CPU_WR_DONE_d	<= 1'b0;
		end
		else
		begin
			CPU_WR_DONE_d	<= CPU_WR_DONE[0];
		end
	end

	assign CPU_WR_DONE_pos = (CPU_WR_DONE[0] && (!CPU_WR_DONE_d)) ? 1'b1 : 1'b0;


	// ---------- 语义段 11：控制/状态输出汇总 ----------
	// 输入：本模块寄存器和边沿脉冲；输出：连接 Adapter 的 r_* 端口。
	// 作用：保持生产端口不变，将软件语义明确传给集成层。
	// 失败定位：内部信号正确而 Adapter 未收到时检查 PCIe.v/BD 端口连接。
	assign r_INT_STATE				= INT_STATE_R			;
	assign r_CLEAR_INTER			= CLEAR_INTER_R			;
	assign r_CPU_REC_STATE			= CPU_REC_STATE[0]		;
	assign r_RD_START				= CPU_WR_DONE_pos		;
	assign r_CPU_FPGA_START_ADDR	= CPU_FPGA_START_ADDR	;
	assign r_CPU_FPGA_LEN			= CPU_FPGA_LEN		    ;

	// User logic ends


	endmodule
```
