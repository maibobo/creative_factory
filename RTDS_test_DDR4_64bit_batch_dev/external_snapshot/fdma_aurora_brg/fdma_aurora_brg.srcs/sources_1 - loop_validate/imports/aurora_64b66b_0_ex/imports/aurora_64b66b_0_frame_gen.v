 ///////////////////////////////////////////////////////////////////////////////
 //
 // Project:  Aurora 64B/66B 
 // Company:  Xilinx
 //
 //
 //
 // (c) Copyright 2008 - 2009 Xilinx, Inc. All rights reserved.
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
 //  FRAME GEN
 //
 //
 //  Description: This module is a pattern generator to test the Aurora
 //               designs in hardware. It generates data and passes it 
 //               through the Aurora channel. 
 ///////////////////////////////////////////////////////////////////////////////
 
 `timescale 1 ns / 10 ps
 `define DLY #1

(* DowngradeIPIdentifiedWarnings="yes" *)
 module aurora_64b66b_0_FRAME_GEN
 (
     // User Interface
     TX_D,  
     TX_REM,   
     TX_SOF_N,     
     TX_EOF_N,
     TX_SRC_RDY_N,
     TX_DST_RDY_N,
    TX_FRAME_CNT,
     // System Interface
     CHANNEL_UP,
     USER_CLK,       
     RESET
 ); 
 
 //*****************************Parameter Declarations****************************
     parameter            AURORA_LANES    = 1;
     parameter            LANE_DATA_WIDTH = (AURORA_LANES*64);
     parameter            REM_BUS         = 3;
     parameter            REM_BITS_MAX    = (LANE_DATA_WIDTH/8);
     parameter            DATA_WIDTH      = 8;
 
 //***********************************Port Declarations*******************************
 
    //PDU Interface
(* mark_debug = "true" *)     output   reg [0:LANE_DATA_WIDTH-1]  TX_D;
(* mark_debug = "true" *)     output   reg [0:REM_BUS-1]          TX_REM;
(* mark_debug = "true" *)     output   reg                        TX_SOF_N;
(* mark_debug = "true" *)     output   reg                        TX_EOF_N;
(* mark_debug = "true" *)     output   reg                        TX_SRC_RDY_N;
                               output       [0:31]                 TX_FRAME_CNT; 
(* mark_debug = "true" *)     input                               TX_DST_RDY_N;
     
     // System Interface
(* mark_debug = "true" *)       input                            CHANNEL_UP; 
(* mark_debug = "true" *)       input                            USER_CLK; 
(* mark_debug = "true" *)       input                            RESET;  

 
 //***************************Internal Register Declarations*************************** 
 
       reg                              first_tx_dst_rdy_n;
       reg                   [0:31]     bytes_sent_r; 

 
 
 //*********************************Wire Declarations**********************************

     wire                             reset_i;
     wire                             RESET_ii;
 
 //*********************************Main Body of Code**********************************

    //parameter [0:63] FIXED_DATA = 64'h0123456789ABCDEF; // 固定发�?�数�??
    parameter [0:63] FIXED_DATA_A = 64'h5555_5555_5555_5555;
    parameter [0:63] FIXED_DATA_B = 64'hAAAA_AAAA_AAAA_AAAA;    
    parameter EOF_REM    = 3'b011;               // 结束时的有效字节�?? (0~7)
    parameter SEND_CNT   = 32'd500; 

    // 状�?�定�??
    localparam IDLE   = 1'b0,
               FRAME  = 1'b1;

    reg state, next_state;
    reg [3:0] cnt, next_cnt; // 计数�?? 0~9

    assign RESET_ii = RESET ; 
    assign resetUFC = reset_i;     

    assign reset_i = RESET || (CHANNEL_UP==1'b0); 

    // 时序逻辑：状态和计数�??
    always @(posedge USER_CLK) begin
        if (reset_i) begin
            state <= IDLE;
            cnt   <= 4'b0;
        end else begin
            state <= next_state;
            cnt   <= next_cnt;
        end
    end

    // 组合逻辑：次态和计数器更�??
    always @* begin
        next_state = state;
        next_cnt   = cnt;

        case (state)
            IDLE: begin
                if (!reset_i) begin // 通道就绪且复位无�??
                    next_state = FRAME;
                    next_cnt   = 4'b0;
                end
            end
            FRAME: begin
                if (!TX_DST_RDY_N) begin // 接收端就绪，可发�??
                    if (cnt == 4'd9) begin
                        next_cnt = 4'b0; // 下一周期�??始新�??
                    end else if(bytes_sent_r < SEND_CNT) begin
                        next_cnt = cnt + 1'b1;
                    end
                end
                // 否则计数器保�??
            end
        endcase
    end

    // ������֡���ͼĴ�����0 ��ʾ��ǰ֡�� A��1 ��ʾ�� B
    reg frame_type, next_frame_type;

    // ��ʱ���߼��и��� frame_type
    always @(posedge USER_CLK) begin
        if (reset_i) begin
            // ... ������λ
            frame_type <= 1'b0;          // ��λ���һ֡��? A
        end else begin
            // ... ״̬�� cnt ����
            frame_type <= next_frame_type;
        end
    end

    // ������߼��м���? next_frame_type
    always @* begin
        next_frame_type = frame_type;     // Ĭ�ϱ���
        case (state)
            FRAME: begin
                if (!TX_DST_RDY_N && (cnt == 4'd9)) begin
                    // ��ǰ֡������ϣ���һ֡�л�����?
                    next_frame_type = ~frame_type;
                end
            end
            // IDLE ʱ����
        endcase
    end
    
    // 输出逻辑
    always @* begin
        if(frame_type == 1'b0) begin
            TX_D = FIXED_DATA_A;
        end
        else begin
            TX_D = FIXED_DATA_B;
        end
    end
    always @* begin
        
        //TX_D         = 64'h5555_5555_5555_5555;  
        TX_SOF_N     = 1'b1;
        TX_EOF_N     = 1'b1;
        TX_SRC_RDY_N = 1'b1;
        TX_REM       = 3'b111;   // 非结束周期默认为全字节有�??

        if ((state == FRAME) && (bytes_sent_r < SEND_CNT)) begin
            TX_SRC_RDY_N = 1'b0;
            if (cnt == 4'd0)
                TX_SOF_N = 1'b0;
            if (cnt == 4'd9) begin
                TX_EOF_N = 1'b0;
                TX_REM   = EOF_REM;   // 结束周期使用参数�??
            end
        end
    end

 
     //Use a second counter to determine how many bytes of the frame have already been sent
     always @(posedge USER_CLK)
         if (reset_i) 
             bytes_sent_r    <=  `DLY    32'h0;
         else if(&bytes_sent_r)
             bytes_sent_r    <=  `DLY    bytes_sent_r;
         else if(!TX_DST_RDY_N && (state == FRAME) && (cnt == 4'd9))
             bytes_sent_r    <=  `DLY    bytes_sent_r + 1;
 
 assign TX_FRAME_CNT = bytes_sent_r;
 
     always @(posedge USER_CLK)
        if (reset_i) 
           first_tx_dst_rdy_n <= `DLY 1'b0; 
        else if (CHANNEL_UP==1'b0)
           first_tx_dst_rdy_n <= `DLY 1'b0; 
        else if(!TX_DST_RDY_N && CHANNEL_UP)
           first_tx_dst_rdy_n <= `DLY 1'b1; 


 
 endmodule 
