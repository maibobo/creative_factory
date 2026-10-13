// Static-check boundary only. No functional behavior is implemented.
(* syn_black_box = 1 *)
module aurora_64b66b_top #(
    parameter                       SIMULATION         = 0,
    parameter integer               INIT_CLK_FREQ_HZ   = 100_000_000,
    parameter integer               PMA_HOLD_TIME_MS   = 1_600,
    parameter integer               RESET_GAP_TIME_MS  = 20
)(
    
    input                               clk_init            ,
    input                               sys_rst             ,

	
    input                               GTHQ0_P             ,
    input                               GTHQ0_N             ,
    input                               RXP                 ,
    input                               RXN                 ,
    output                              TXP                 ,
    output                              TXN                 ,

    output                              sfp_tx_disable      ,
    output                              sfp_rs0             ,
    output                              sfp_rs1             ,

    
    input                [63: 0]        tx_d                ,
    input                               tx_sof              ,
    input                               tx_eof              ,
    input                [ 2: 0]        tx_rem              ,
    input                               tx_src_vld          ,
    output                              tx_dst_rdy          ,
    
    output               [63: 0]        rx_d                ,
    output                              rx_sof              ,
    output                              rx_eof              ,
    output               [ 2: 0]        rx_rem              ,
    output                              rx_src_vld          ,
    input                               rx_dst_rdy          ,

    
    output                              user_clk            ,
    output                              channel_up          ,
    output                              lane_up             ,
    output                              user_rstn
    );
endmodule
