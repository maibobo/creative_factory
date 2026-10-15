# eth_storm_crc_clean

- Category: `ethernet`
- Source: `E:\eth_storm_project\rgmii_eth_storm_filter_coding\eth_storm_crc_clean.v`
- SHA-256: `bcc955427832104494dbe88b4e96551602daab88896adb1d9bc078ea1e6382a7`
- Extractor: `text`
- Tags: `dma, ethernet, rgmii, storm-filter`
- Duplicate sources:
  - none

```verilog
`timescale 1ns / 1ps
// =============================================================================
// Module : eth_storm_crc_clean
// 位置   : eth_storm_filter 内部，位于主判决状态机与 CRC 去重表 RAM 之间。
// 功能   : 封装 CRC 去重表，并在后台完成上电初始化和跨统计窗口的旧表项清理。
// 时序   : 全部逻辑工作在 gmii_rx_clk 域；rst 为高有效异步复位。
// 表项   : {valid, epoch, crc32}。epoch 随统计窗口翻转，因此新窗口无需立即
//          清空整张表；后台只删除仍有效且 epoch 已过期的表项。
// 访问   : 主判决状态机的 normal_* 访问优先于后台清理。接口没有 ready 信号，
//          normal_dout 的有效时刻遵循所例化 CRC RAM 的同步读延迟。
// =============================================================================

module eth_storm_crc_clean #(
    parameter integer CRC_TABLE_DEPTH = 1024,
    parameter integer CRC_IDX_W         = 10,
    parameter integer CRC_ENTRY_W       = 34            // 有效位 + 窗口代际位 + 32 bit CRC
)(
    // 接收处理时钟与高有效异步复位
    input  wire                     gmii_rx_clk,
    input  wire                     rst,

    // 窗口翻转后启动一次后台扫描；pause_req 要求清理让出 RAM 读口
    input  wire                     win_rollover,
    input  wire [0:0]               win_epoch,
    input  wire                     crc_clear_pause_req,

    // 主判决状态机的正常查表/写表通道，写请求具有最高优先级
    input  wire                     normal_rd_en,
    input  wire [CRC_IDX_W-1:0]     normal_raddr,
    input  wire                     normal_we,
    input  wire [CRC_IDX_W-1:0]     normal_waddr,
    input  wire [CRC_ENTRY_W-1:0]   normal_din,
    output wire [CRC_ENTRY_W-1:0]   normal_dout,

    // 复位后的全表强制清零完成后置 1，后续窗口清理不会将其拉低
    output reg                      crc_init_done
);

    localparam [CRC_IDX_W-1:0] CRC_TABLE_DEPTH_M1 = CRC_TABLE_DEPTH - 1;

    reg                     crc_clear_active;
    reg                     crc_clear_active_r;
    reg                     crc_clear_phase;
    reg [CRC_IDX_W-1:0]     crc_clear_addr;
    reg [CRC_IDX_W-1:0]     crc_clear_addr_q;
    reg                     crc_clear_force_zero;

    wire                    crc_clear_rd_en;
    wire                    crc_clear_entry_old;
    wire                    crc_ram_clear_we;
    wire                    crc_ram_we;
    wire [0:0]              crc_ram_wea;
    wire [CRC_IDX_W-1:0]    crc_ram_waddr;
    wire [CRC_ENTRY_W-1:0]  crc_ram_din;
    wire                    crc_ram_rd_en;
    wire [CRC_IDX_W-1:0]    crc_ram_raddr;
    wire [CRC_ENTRY_W-1:0]  crc_ram_dout;


    // 后台每个地址分两拍处理：第 1 拍发起同步读，第 2 拍检查返回表项并按需清零。
    // 初次扫描由 force_zero 无条件清零；后续扫描仅清除有效且 epoch 不匹配的表项。
    assign crc_clear_rd_en     = crc_clear_active && (!crc_clear_phase) && (!crc_clear_pause_req);
    assign crc_clear_entry_old = crc_clear_force_zero ||
                                 (crc_ram_dout[CRC_ENTRY_W-1] && (crc_ram_dout[32] != win_epoch) && (crc_clear_active_r && crc_clear_active));
    assign crc_ram_clear_we    = crc_clear_active && crc_clear_phase &&
                                 (!crc_clear_pause_req) && crc_clear_entry_old;

    // 正常写覆盖后台清零写；两者最终复用 RAM 的 A 写端口。
    assign crc_ram_we    = normal_we || crc_ram_clear_we;
    assign crc_ram_wea   = {crc_ram_we};
    assign crc_ram_waddr = normal_we ? normal_waddr : crc_clear_addr_q;
    assign crc_ram_din   = normal_we ? normal_din : {CRC_ENTRY_W{1'b0}};

    // 正常读覆盖后台扫描读；normal_dout 直接转发 RAM 的 B 口输出。
    assign crc_ram_rd_en = normal_rd_en || crc_clear_rd_en;
    assign crc_ram_raddr = normal_rd_en ? normal_raddr : crc_clear_addr;
    assign normal_dout   = crc_ram_dout;

    eth_storm_crc_ram u_crc_ram (
        .clka  (gmii_rx_clk  ),
        .ena   (crc_ram_we   ),
        .wea   (crc_ram_wea  ),
        .addra (crc_ram_waddr),
        .dina  (crc_ram_din  ),
        .clkb  (gmii_rx_clk  ),
        .enb   (crc_ram_rd_en),
        .addrb (crc_ram_raddr),
        .doutb (crc_ram_dout )
    );

    // 延迟一拍的 active 用来屏蔽刚启动扫描时尚未对应当前读地址的 RAM 输出。
    always @(posedge gmii_rx_clk or posedge rst)
        if (rst)
            crc_clear_active_r <= 1'b1;
        else
            crc_clear_active_r <= crc_clear_active;

    always @(posedge gmii_rx_clk or posedge rst) begin
        if (rst) begin
            crc_clear_active     <= 1'b1;
            crc_clear_phase      <= 1'b0;
            crc_clear_addr       <= {CRC_IDX_W{1'b0}};
            crc_clear_addr_q     <= {CRC_IDX_W{1'b0}};
            crc_clear_force_zero <= 1'b1;
            crc_init_done        <= 1'b0;
        end else begin
            // 初次全表清零完成后，统计窗口翻转会从地址 0 重新开始按 epoch 清理。
            if (win_rollover & crc_init_done) begin
                crc_clear_active     <= 1'b1;
                crc_clear_phase      <= 1'b0;
                crc_clear_addr       <= {CRC_IDX_W{1'b0}};
                crc_clear_addr_q     <= {CRC_IDX_W{1'b0}};
                crc_clear_force_zero <= 1'b0;
            end else if (crc_clear_active) begin
                if (crc_clear_pause_req) begin
                    // 若在检查拍被暂停，则退回读拍；恢复后重读该地址，避免使用
                    // 正常访问期间留在 RAM 输出端的无关数据。
                    if (crc_clear_phase)
                        crc_clear_phase <= 1'b0;
                end else begin
                    if (!crc_clear_phase) begin
                        crc_clear_addr_q <= crc_clear_addr;
                        crc_clear_phase  <= 1'b1;
                    end else begin
                        if (crc_clear_addr == CRC_TABLE_DEPTH_M1) begin
                            crc_clear_active <= 1'b0;
                            crc_clear_phase  <= 1'b0;
                            crc_clear_addr   <= {CRC_IDX_W{1'b0}};
                            crc_clear_addr_q <= {CRC_IDX_W{1'b0}};
                            if (crc_clear_force_zero)
                                crc_init_done <= 1'b1;
                            crc_clear_force_zero <= 1'b0;
                        end else begin
                            crc_clear_addr  <= crc_clear_addr + 1'b1;
                            crc_clear_phase <= 1'b0;
                        end
                    end
                end
            end
        end
    end

endmodule
```
