# rtds_rootport_pkg

- Category: `pcie`
- Source: `R:\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport\tb\rtds_rootport_pkg.sv`
- SHA-256: `38697e29fd1edae34ff3c73b28d04bcc14ee269c9df6643dc3603072bd9b7395`
- Extractor: `text`
- Tags: `pcie, root-port, verification, xdma`
- Duplicate sources:
  - none

```systemverilog
`timescale 1ns / 1ps

// 大仿真公共常量：地址、长度和确定性数据模式集中定义，避免用例散落魔数。
package rtds_rootport_pkg;
    localparam integer FRAME_BYTES       = 512;
    localparam integer HOST_H2C_DESC     = 16'h0100;
    localparam integer HOST_C2H_DESC     = 16'h0300;
    localparam integer HOST_SOURCE       = 16'h0400;
    localparam integer HOST_DESTINATION  = 16'h0800;
    localparam integer CARD_TX_BASE      = 32'h0000_8000;
    localparam integer CARD_RX_BASE      = 32'h0000_0000;

    // 每个字节都与序号相关，能同时发现丢拍、重拍、错序和端序错误。
    function automatic [7:0] pattern_byte(input [7:0] seed, input integer index);
        pattern_byte = seed + (index * 8'd37) + (index >> 3);
    endfunction
endpackage
```
