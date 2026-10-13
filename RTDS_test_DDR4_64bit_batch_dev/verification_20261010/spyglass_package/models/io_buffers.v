`timescale 1ns/1ps
// Clock buffer connectivity model, not a differential electrical model.
module IBUFDS #(parameter DIFF_TERM="FALSE", IBUF_LOW_PWR="TRUE", IOSTANDARD="DEFAULT") (input I, input IB, output O);
  assign O=I;
endmodule
// Dedicated clock macro. Its 25 MHz output is a clock root in SGDC.
(* syn_black_box = 1 *)
module BUFGCE_DIV #(parameter integer BUFGCE_DIVIDE=1, parameter IS_CE_INVERTED=1'b0, IS_CLR_INVERTED=1'b0, IS_I_INVERTED=1'b0) (input I, CE, CLR, output O);
endmodule
