# aurora_64b66b_top

- Category: `aurora`
- Source: `R:\aurora_64b66b_10p3125g_2020_2_verified\design\aurora_64b66b_0_ex.srcs\sources_1\new\aurora_64b66b_top.v`
- SHA-256: `94015c797acb99dcb93cbfb4350309287582ba5c8a3bbd8389d995583192362a`
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


module aurora_64b66b_top(
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

    // state lint
    output                              LANE_UP             ,
    output                              CHANNEL_UP          ,
    output                              HARD_ERR            ,
    output                              SOFT_ERR            ,
    output                              CRC_PASS_FAIL_N     ,
    output                              CRC_VALID           ,

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
    input                               rx_dst_rdy
    );

    localparam                    RESET_ASSERT       = 10                   ;   // 2
    localparam                    PMA_INIT_ASSERT    = 1000_1010            ;   // 128 + 10

    // 50M, at least 50_000_000     // 10M, at least 10_000_000
    localparam                    PMA_INIT_DEASSERT  = 60_000_000           ;   // 1.2s
    localparam                    RESET_DEASSERT     = 70_000_000           ;   // 1.2s + 128

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

    reg                                 PMA_INIT               ;
    reg                                 RESET                  ;
    reg                  [25: 0]        init_cnt               ;
    reg                  [26: 0]        reset_delay_cnt        ;

    always@(posedge clk_init)
    begin
        if(sys_rst)
        begin
            init_cnt <= 'd0;
        end
        else if(~(&init_cnt))
        begin
            init_cnt <= init_cnt + 1'b1;
        end
    end

    always@(posedge clk_init)
    begin
        if(sys_rst)
        begin
            reset_delay_cnt <= 'd0;
        end
        else if(~(&reset_delay_cnt))
        begin
            reset_delay_cnt <= reset_delay_cnt + 1'b1;
        end
    end

    always@(posedge clk_init)
    begin
        if(sys_rst)
        begin
            PMA_INIT        <= 1'b0;
        end
        else if(init_cnt == PMA_INIT_ASSERT)
        begin
            PMA_INIT        <= 1'b1;
        end
        else if(reset_delay_cnt == PMA_INIT_DEASSERT)
        begin
            PMA_INIT        <= 1'b0;
        end
    end

    always@(posedge clk_init)
    begin
        if(sys_rst)
        begin
            RESET           <= 1'b0;
        end
        else if(init_cnt == RESET_ASSERT)
        begin
            RESET           <= 1'b1;
        end
        else if(reset_delay_cnt == RESET_DEASSERT)
        begin
            RESET           <= 1'b0;
        end
    end

aurora_64b66b_0_exdes # (
    .USE_CORE_TRAFFIC     (1'b1               ),
    .USR_CLK_PCOUNT       (9'd255             ),
    .EXAMPLE_SIMULATION   (1'b0               ),
    .USE_LABTOOLS         (1'b0               )
  )
  aurora_64b66b_0_exdes_inst (
    .PMA_INIT             (PMA_INIT           ),
    .INIT_CLK_IN          (INIT_CLK_IN        ),
    .RESET                (RESET              ),
    .LANE_UP              (LANE_UP            ),
    .CHANNEL_UP           (CHANNEL_UP         ),
    .GTHQ0_P              (GTHQ0_P            ),
    .GTHQ0_N              (GTHQ0_N            ),
    .RXP                  (RXP                ),
    .RXN                  (RXN                ),
    .TXP                  (TXP                ),
    .TXN                  (TXN                ),
    .HARD_ERR             (HARD_ERR           ),
    .SOFT_ERR             (SOFT_ERR           ),
    .CRC_PASS_FAIL_N      (CRC_PASS_FAIL_N    ),
    .CRC_VALID            (CRC_VALID          ),
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
    .rx_dst_rdy           (rx_dst_rdy         )
  );


//  LED LED_inst(
//	.sys_clk(clk_init),
//	.sys_rst(sys_rst),
//	.led(pl_led)
//  );

  //(* KEEP = "TRUE" *)
//  ila_top ila_top_inst (
//	.clk(clk_init), // input wire clk
//	.probe0(DATA_ERR_COUNT), // input wire [7:0]  probe0
//	.probe1(HARD_ERR), // input wire [0:0]  probe1
//	.probe2(SOFT_ERR), // input wire [0:0]  probe2
//	.probe3(CRC_PASS_FAIL_N), // input wire [0:0]  probe3
//	.probe4(LANE_UP), // input wire [0:0]  probe4
//	.probe5(CHANNEL_UP), // input wire [0:0]  probe5
//	.probe6(sys_rst), // input wire [0:0]  probe6
//	.probe7(reset_delay_cnt), // input wire [9:0]  probe7
//	.probe8(RESET), // input wire [0:0]  probe8
//	.probe9(PMA_INIT), // input wire [0:0]  probe9
//	.probe10(CRC_VALID), // input wire [0:0]  probe10
//	.probe11(locked)
//  );

    assign                     sfp_tx_disable     = 1'b0           ;
    assign                     sfp_rs0            = 1'b1           ;
    assign                     sfp_rs1            = 1'b1           ;
    //assign                     sfp_rs0            = 1'b0           ;
    //assign                     sfp_rs1            = 1'b0           ;

endmodule
```
