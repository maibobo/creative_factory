`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/11 09:30:05
// Design Name: 
// Module Name: aurora_64b66b_top
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


module aurora_64b66b_top #(
    parameter                       SIMULATION         = 0,
    parameter integer               INIT_CLK_FREQ_HZ   = 100_000_000,
    parameter integer               PMA_HOLD_TIME_MS   = 1_600,
    parameter integer               RESET_GAP_TIME_MS  = 20
)(
    // init clk and rst
    input                               clk_init            ,
    input                               sys_rst             ,

	//GT IO
    input                               GTHQ0_P             ,
    input                               GTHQ0_N             ,
    input                               RXP                 ,
    input                               RXN                 ,
    output                              TXP                 ,
    output                              TXN                 ,

    output                              sfp_tx_disable      ,
    output                              sfp_rs0             ,
    output                              sfp_rs1             ,

    // LocalLink TX interface 
    input                [63: 0]        tx_d                ,
    input                               tx_sof              ,
    input                               tx_eof              ,
    input                [ 2: 0]        tx_rem              ,
    input                               tx_src_vld          ,
    output                              tx_dst_rdy          ,
    // LocalLink RX interface 
    output               [63: 0]        rx_d                ,
    output                              rx_sof              ,
    output                              rx_eof              ,
    output               [ 2: 0]        rx_rem              ,
    output                              rx_src_vld          ,
    input                               rx_dst_rdy          ,

    // Status outputs
    output                              user_clk            ,
    output                              channel_up          ,
    output                              lane_up             ,
    output                              user_rstn
    );

    // 鍙傝?冪増鏈? (纭呯墖, EXAMPLE_SIMULATION=0):
    //   GT_RESET_ASSERT  = 1_000_000    (init_cnt 鍒? 1M 鏃? assert GT_RESET)
    //   RESET_ASSERT     = 10           (init_cnt 鍒? 10 鏃? assert RESET)
    //   GT_RESET_DEASSERT= 80_000_000   (reset_delay_cnt 鍒? 80M 鏃? deassert GT_RESET)
    //   RESET_DEASSERT   = 81_000_000   (reset_delay_cnt 鍒? 81M 鏃? deassert RESET)
    //
    // 浠跨湡妯″紡 (SIMULATION=1):
    //   鐩存帴鐢? sys_rst 椹卞姩 PMA_INIT 鍜? RESET锛岃烦杩囪鏁板櫒寤惰繜
    //   涓庡弬鑰? TB 涓?鑷?: pma_init_r=1, reset_i=1, repeat(160)鍚? pma_init_r=0, #(60)鍚? reset_i=0
    //   TB 涓? sys_rst 鍏堜负1 (assert), repeat(160)鍚庨噴鏀? 鈫? PMA_INIT/RESET 鑷姩璺熼殢

    localparam integer            CYCLES_PER_MS      = INIT_CLK_FREQ_HZ / 1000;
    localparam integer            PMA_HOLD_CYCLES    = CYCLES_PER_MS * PMA_HOLD_TIME_MS;
    localparam integer            RESET_GAP_CYCLES   = CYCLES_PER_MS * RESET_GAP_TIME_MS;

    //wire                                clk_init               ;
    //wire                                locked                 ;
    //wire                                sys_rst                ;
	
	//main
    //clk_wiz_0 clk_wiz_0_inst
    //(
    //// Clock out ports
    //.clk_out1             (clk_init           ),// output clk_out1    
    //// Status and control signals
    //.locked               (locked             ),// output locked
	//// Clock in ports
    //.clk_in1_p            (clk_p              ),// input clk_in1
    //.clk_in1_n            (clk_n              ) // input clk_in1
    //);
    //assign                     sys_rst            = ~locked        ;
    
    wire                                PMA_INIT               ;
    wire                                RESET                  ;
    wire                 [ 1: 0]        reset_seq_state        ;
    wire                 [26: 0]        reset_seq_cnt          ;
    wire                                gt_pll_lock_i          ;

    // Internal wires for status outputs
    wire                                channel_up_i           ;
    wire                                lane_up_i              ;
    wire                                user_clk_i             ;
    wire                                system_reset_i         ;

    // 浠跨湡妯″紡: PMA_INIT/RESET 鐩存帴璺熼殢 sys_rst (涓庡弬鑰? TB 涓?鑷?)
    // 纭呯墖妯″紡: 浣跨敤璁℃暟鍣ㄥ欢杩? assert/deassert
    generate
        if (SIMULATION != 0) begin : sim_init
            // 浠跨湡: sys_rst=1 鈫? PMA_INIT=1, RESET=1; sys_rst=0 鈫? PMA_INIT=0, RESET=0
            // TB 涓? sys_rst 鍏堜负1, repeat(160)鍚庨噴鏀?, #(60)鍚? fdma_rstn 閲婃斁
            // 杩欎笌鍙傝?? TB 鐩存帴鎺у埗 pma_init_r/reset_i 鐨勬椂搴忎竴鑷?
            assign PMA_INIT        = sys_rst;
            assign RESET           = sys_rst;
            assign reset_seq_state = 2'd0;
            assign reset_seq_cnt   = 27'd0;
        end else begin : silicon_init
            aurora_power_on_reset_seq #(
                .PMA_HOLD_CYCLES  (PMA_HOLD_CYCLES),
                .RESET_GAP_CYCLES (RESET_GAP_CYCLES)
            ) u_power_on_reset_seq (
                .clk_init  (clk_init),
                .sys_rst   (sys_rst),
                .pma_init  (PMA_INIT),
                .reset_pb  (RESET),
                .state_dbg (reset_seq_state),
                .count_dbg (reset_seq_cnt)
            );
        end
    endgenerate
         
aurora_64b66b_0_exdes # (
    .USE_CORE_TRAFFIC     (1'b1               ),
    .USR_CLK_PCOUNT       (9'd255             ),
    .EXAMPLE_SIMULATION   (SIMULATION != 0    ),
    .USE_LABTOOLS         (1'b1               ) 
  )
  aurora_64b66b_0_exdes_inst (
    .PMA_INIT             (PMA_INIT           ),
    .INIT_CLK_IN          (clk_init           ),
    .RESET                (RESET              ),
    .LANE_UP              (lane_up_i          ),
    .CHANNEL_UP           (channel_up_i       ),
    .GTHQ0_P              (GTHQ0_P            ),
    .GTHQ0_N              (GTHQ0_N            ),
    .RXP                  (RXP                ),
    .RXN                  (RXN                ),
    .TXP                  (TXP                ),
    .TXN                  (TXN                ),
    .HARD_ERR             (                   ),
    .SOFT_ERR             (                   ),
    .CRC_PASS_FAIL_N      (                   ),
    .CRC_VALID            (                   ),
    .tx_d                 (tx_d               ),
    .tx_sof               (tx_sof             ),
    .tx_eof               (tx_eof             ),
    .tx_rem               (tx_rem             ),
    .tx_src_vld           (tx_src_vld         ),
    .tx_dst_rdy           (tx_dst_rdy         ),
    .rx_d                 (rx_d               ),
    .rx_sof               (rx_sof             ),
    .rx_eof               (rx_eof             ),
    .rx_rem               (rx_rem             ),
    .rx_src_vld           (rx_src_vld         ),
    .rx_dst_rdy           (rx_dst_rdy         ),
    .user_clk             (user_clk_i         ),
    .sys_reset_out        (system_reset_i     ),
    .gt_pll_lock_out      (gt_pll_lock_i      )
  );
    
    
//  LED LED_inst(
//	.sys_clk(clk_init),
//	.sys_rst(sys_rst),
//	.led(pl_led)
//  );

  // Initialization signals remain available to an external ILA through the
  // wrapper hierarchy; no fixed debug core is instantiated in the product
  // path, which keeps this source portable between the Aurora and RTDS builds.
    
    assign                     sfp_tx_disable     = 1'b0           ;
    assign                     sfp_rs0            = 1'b1           ;
    assign                     sfp_rs1            = 1'b1           ;

    // Status outputs
    assign                     user_clk           = user_clk_i     ;
    assign                     channel_up         = channel_up_i   ;
    assign                     lane_up            = lane_up_i      ;
    assign                     user_rstn          = ~system_reset_i;
    //assign                     sfp_rs0            = 1'b0           ;
    //assign                     sfp_rs1            = 1'b0           ;
    
endmodule

// PG074 Figure 41: both resets assert asynchronously before INIT_CLK is
// usable; PMA_INIT then RESET release synchronously after their hold times.
module aurora_power_on_reset_seq #(
    parameter integer PMA_HOLD_CYCLES  = 80_000_000,
    parameter integer RESET_GAP_CYCLES = 1_000_000
)(
    input               clk_init,
    input               sys_rst,
    output reg          pma_init,
    output reg          reset_pb,
    output reg  [ 1:0]  state_dbg,
    output reg  [26:0]  count_dbg
);
    localparam [1:0] ST_HOLD_BOTH  = 2'd0;
    localparam [1:0] ST_RESET_ONLY = 2'd1;
    localparam [1:0] ST_RUN        = 2'd2;

    // Asynchronous assertion, two-stage synchronous release into INIT_CLK.
    (* ASYNC_REG = "TRUE" *) reg [1:0] sys_rst_sync;

    always @(posedge clk_init or posedge sys_rst) begin
        if (sys_rst)
            sys_rst_sync <= 2'b11;
        else
            sys_rst_sync <= {sys_rst_sync[0], 1'b0};
    end

    always @(posedge clk_init or posedge sys_rst_sync[1]) begin
        if (sys_rst_sync[1]) begin
            pma_init  <= 1'b1;
            reset_pb  <= 1'b1;
            state_dbg <= ST_HOLD_BOTH;
            count_dbg <= 27'd0;
        end else begin
            case (state_dbg)
                ST_HOLD_BOTH: begin
                    pma_init <= 1'b1;
                    reset_pb <= 1'b1;
                    if (count_dbg == PMA_HOLD_CYCLES - 1) begin
                        pma_init  <= 1'b0;
                        state_dbg <= ST_RESET_ONLY;
                        count_dbg <= 27'd0;
                    end else count_dbg <= count_dbg + 1'b1;
                end
                ST_RESET_ONLY: begin
                    pma_init <= 1'b0;
                    reset_pb <= 1'b1;
                    if (count_dbg == RESET_GAP_CYCLES - 1) begin
                        reset_pb  <= 1'b0;
                        state_dbg <= ST_RUN;
                        count_dbg <= 27'd0;
                    end else count_dbg <= count_dbg + 1'b1;
                end
                default: begin
                    pma_init  <= 1'b0;
                    reset_pb  <= 1'b0;
                    state_dbg <= ST_RUN;
                    count_dbg <= 27'd0;
                end
            endcase
        end
    end
endmodule

