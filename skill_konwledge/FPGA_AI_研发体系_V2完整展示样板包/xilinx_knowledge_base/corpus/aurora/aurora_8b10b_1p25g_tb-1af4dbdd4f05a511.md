# aurora_8b10b_1p25g_tb

- Category: `aurora`
- Source: `R:\aurora_8b10b_1p25g_2020_2_verified\verification\aurora_8b10b_1p25g_ex\imports\aurora_8b10b_1p25g_tb.v`
- SHA-256: `1af4dbdd4f05a511c600ca07f3431b25867021cf0680540dee950db2726f265d`
- Extractor: `text`
- Tags: `1.25g, 8b10b, aurora, verified, vivado-2020.2`
- Duplicate sources:
  - none

```verilog
///////////////////////////////////////////////////////////////////////////////
// (c) Copyright 2008 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//
///////////////////////////////////////////////////////////////////////////////
//
//  aurora_8b10b_1p25g_TB
//
//  Aurora Generator
//
//
//
//  Description:  This testbench instantiates 2 Aurora Sample Modules. The serial TX pins from
//                one module are connected to the RX pins of the other and vice versa. A simple Local-Link
//                frame generator is used to generate packets for the TX data interface while a frame checker
//                module is connected to the RX data interface to check the incoming frames and keep
//                track of any errors.
//

`timescale 1 ns / 1 fs

module aurora_8b10b_1p25g_TB;

//*************************Parameter Declarations**************************

    parameter       SIM_MAX_TIME  = 9500000; //To quit the simulation
    //125.0MHz GT Reference clock
parameter       CLOCKPERIOD_1 = 8.0	;
parameter       CLOCKPERIOD_2 = 8.0	;
//parameter       CLOCKPERIOD_1 = 8.0;
//parameter       CLOCKPERIOD_2 = 8.0;
parameter       INIT_CLOCKPERIOD = 40.0 ; // Board/System Clock


//************************Internal Register Declarations*****************************

    //Freerunning Clock
reg                reference_clk_1_n_r;
reg                reference_clk_2_n_r;
reg     init_clk_p;

    //Global signals
reg                gt_reset_in;
reg                gsr_r;
reg                gts_r;
reg                reset_i;

//********************************Wire Declarations**********************************

    //Freerunning Clock
wire               reference_clk_1_p_r;
wire               reference_clk_2_p_r;

wire    init_clk_n;
//Dut1

    //Error Detection Interface
wire               hard_err_1_i;
wire               soft_err_1_i;
wire               frame_err_1_i;

    //Status
wire               channel_up_1_i;
wire               lane_up_1_i;


    //GT Serial I/O
wire               rxp_1_i;
wire               rxn_1_i;

wire               txp_1_i;
wire               txn_1_i;

    // Error signals from the Local Link packet checker
wire    [0:7]      err_count_1_i;


//Dut2

    //Error Detection Interface
wire               hard_err_2_i;
wire               soft_err_2_i;
wire               frame_err_2_i;

    //Status
wire               channel_up_2_i;
wire               lane_up_2_i;


    //GT Serial I/O
wire               rxp_2_i;
wire               rxn_2_i;

wire               txp_2_i;
wire               txn_2_i;

    // Error signals from the Local Link packet checker
wire    [0:7]      err_count_2_i;

    //CRC module signals
wire               crc_pass_fail_n_1;
wire               crc_valid_1;
wire               crc_pass_fail_n_2;
wire               crc_valid_2;

    reg channel_up1 = 1'b0;
    reg channel_up2 = 1'b0;
    reg flag        = 1'b0;
    reg flag_1      = 1'b0;
    reg flag_2      = 1'b1;
    reg flag_3      = 1'b0;
    reg flag_4      = 1'b1;

//*********************************Main Body of Code**********************************

    //_________________________Serial Connections________________


    assign   rxn_1_i      =    txn_2_i;
    assign   rxp_1_i      =    txp_2_i;
    assign   rxn_2_i      =    txn_1_i;
    assign   rxp_2_i      =    txp_1_i;

    //__________________________Global Signals_____________________________

    //Simultate the global reset that occurs after configuration at the beginning
    //of the simulation. Note that both GT smart models use the same global signals.
    assign glbl.GSR = gsr_r;
    assign glbl.GTS = gts_r;

    initial
        begin
            gts_r    = 1'b0;
            gsr_r    = 1'b1;
            gt_reset_in = 1'b1;
            #5000;
            gsr_r    = 1'b0;
            gt_reset_in = 1'b0;
            repeat(10) @(posedge init_clk_p);
            gt_reset_in = 1'b1;
            repeat(10) @(posedge init_clk_p);
            gt_reset_in = 1'b0;
        end


    //____________________________Clocks____________________________

    initial
        reference_clk_1_n_r = 1'b0;


    always
        #(CLOCKPERIOD_1 / 2) reference_clk_1_n_r = !reference_clk_1_n_r;

    assign reference_clk_1_p_r = !reference_clk_1_n_r;


    initial
        reference_clk_2_n_r = 1'b0;


    always
        #(CLOCKPERIOD_2 / 2) reference_clk_2_n_r = !reference_clk_2_n_r;

    assign reference_clk_2_p_r = !reference_clk_2_n_r;


    initial
        init_clk_p = 1'b0;


    always
        #(INIT_CLOCKPERIOD / 2) init_clk_p = !init_clk_p;

    assign init_clk_n =  !init_clk_p;

    //____________________________Resets____________________________

    initial
    begin
        reset_i = 1'b1;
        #1000 reset_i = 1'b0;
    end


    //________________________Instantiate Dut 1 ________________


aurora_8b10b_1p25g_exdes example_design_1_i
(
    // User IO
    .RESET(reset_i),
    // Error signals from Aurora
    .HARD_ERR(hard_err_1_i),
    .SOFT_ERR(soft_err_1_i),
    .FRAME_ERR((frame_err_1_i)),

    // Status Signals
    .LANE_UP(lane_up_1_i),
    .CHANNEL_UP(channel_up_1_i),
    .INIT_CLK_P(init_clk_p),
    .INIT_CLK_N(init_clk_n),
    .GT_RESET_IN(gt_reset_in),

    // Clock Signals
    .GT_REFCLK_P(reference_clk_1_p_r),
    .GT_REFCLK_N(reference_clk_1_n_r),


    // GT I/O
    .RXP(rxp_1_i),
    .RXN(rxn_1_i),

    .TXP(txp_1_i),
    .TXN(txn_1_i),

    .CRC_PASS_FAIL_N(crc_pass_fail_n_1),
    .CRC_VALID(crc_valid_1),
    // Error signals from the Local Link packet checker
    .ERR_COUNT(err_count_1_i)
);

    //________________________Instantiate Dut 2 ________________


aurora_8b10b_1p25g_exdes example_design_2_i
(
    // User IO
    .RESET(reset_i),
    // Error signals from Aurora
    .HARD_ERR(hard_err_2_i),
    .SOFT_ERR(soft_err_2_i),
    .FRAME_ERR((frame_err_2_i)),

    // Status Signals
    .LANE_UP(lane_up_2_i),
    .CHANNEL_UP(channel_up_2_i),
    .INIT_CLK_P(init_clk_p),
    .INIT_CLK_N(init_clk_n),
    .GT_RESET_IN(gt_reset_in),

    // Clock Signals
    .GT_REFCLK_P(reference_clk_2_p_r),
    .GT_REFCLK_N(reference_clk_2_n_r),


    // GT I/O
    .RXP(rxp_2_i),
    .RXN(rxn_2_i),

    .TXP(txp_2_i),
    .TXN(txn_2_i),

    .CRC_PASS_FAIL_N(crc_pass_fail_n_2),
    .CRC_VALID(crc_valid_2),
    // Error signals from the Local Link packet checker
    .ERR_COUNT(err_count_2_i)
);


always @(posedge crc_valid_1)
 begin
      flag_1 = 1'b1;
      if (flag_2 == 0)
       begin
         $display("\n## aurora_8b10b_1p25g_TB : @Time : %0t CRC_FAIL in DUT1\n",$time);
         flag = 1'b1;
       end
      else
        flag_2 = 1'b0;
end

always @ (posedge crc_pass_fail_n_1)
begin
     if(flag_1 == 1)
       begin
        flag_2 = 1'b1;
        flag_1 = 1'b0;
      end
end

always @(posedge crc_valid_2)
 begin
      flag_3 = 1'b1;
      if (flag_4 == 0)
       begin
         $display("\n## aurora_8b10b_1p25g_TB : @Time : %0t CRC_FAIL in DUT2\n",$time);
         flag = 1'b1;
       end
      else
        flag_4 = 1'b0;
end

always @ (posedge crc_pass_fail_n_2)
begin
     if(flag_3 == 1)
       begin
        flag_4 = 1'b1;
        flag_3 = 1'b0;
      end
end


    always @ (posedge channel_up_1_i or posedge channel_up_2_i or
              posedge err_count_1_i[7] or posedge err_count_2_i[7])
    begin
       if(channel_up_1_i == 1 && !channel_up1)
       begin
          $display("\n## aurora_8b10b_1p25g_TB : @Time : %0t CHANNEL_UP is asserted in DUT1\n",$time);
          channel_up1 = 1'b1;
       end

       if(channel_up_2_i == 1 && !channel_up2)
       begin
          $display("\n## aurora_8b10b_1p25g_TB : @Time : %0t CHANNEL_UP is asserted in DUT2\n",$time);
          channel_up2 = 1'b1;
       end

       if((err_count_1_i[7] != 1'b0) || ( err_count_2_i[7] != 1'b0))
       begin
          $display("\n## aurora_8b10b_1p25g_TB : @Time : %0t ERROR : TEST FAIL\n",$time);
          #2000;
          $finish;
       end

       if(channel_up_1_i == 1 && channel_up_2_i == 1)
       begin
          #5000;
          if(!(err_count_1_i[7] & err_count_2_i[7]))
          begin
           if(flag == 1)
             $display("\n## aurora_8b10b_1p25g_TB : @Time : %0t TEST PASS AND CRC FAIL\n",$time);
           else
             $display("\n## aurora_8b10b_1p25g_TB : @Time : %0t Test Completed Successfully\n",$time);
             $finish;
          end
          else
          begin
             $display("\n## aurora_8b10b_1p25g_TB : @Time : %0t TEST FAIL\n",$time);
             $finish;
          end
       end
    end


//Abort the simulation when it reaches to max time limit
initial
begin
  #(SIM_MAX_TIME) $display("\nAURORA_TB : INFO : Reached max. simulation time limit\n");
  $finish;
end

endmodule
```
