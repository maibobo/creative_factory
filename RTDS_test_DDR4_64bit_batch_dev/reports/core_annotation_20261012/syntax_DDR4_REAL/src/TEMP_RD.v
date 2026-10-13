// 通过SYSMON接口按设定周期操作DRP端口，temp返回原始16bit温度码。
// cnt_time在sys_clk域计时，周期末前10拍发出使能，并在最后10拍给出busy。
// 当前代码同时驱动den_in和dwe_in，地址/写数据按复位后保存值使用；注释不改接口操作。
// sys_rst清控制状态；温度码不是直接的摄氏温度，数值换算由使用方完成。
// 注释整理 2026-10-12：仅修改说明和排版，端口、表达式、状态条件及连接保持。

`timescale 1ns / 1ps

// 模块参数与输入输出。
module TEMP_RD #
    (

        parameter                                  SYS_CLK       = 125000000 ,        // 输入时钟频率，单位Hz
        parameter                                  RD_TEMP_CYCLE = 1000               // SYSMON操作周期，单位µs

    )
    (

    input                                      sys_clk ,                              // 输入时钟频率，单位Hz
    input                                      sys_rst ,                              // 高有效系统复位

    output reg                                 busy    ,                              // 当前模块忙或周期操作提示
    output        [15:0]                       temp                                   // SYSMON返回的16bit温度原始码

    );


    localparam                                 CYCLE = RD_TEMP_CYCLE * (SYS_CLK / 1000000);    // 由时钟频率和µs参数换算的周期拍数


    reg                                        den_in                                     ;    // SYSMON DRP操作使能
    reg                                        dwe_in                                     ;    // SYSMON DRP写使能，当前与den_in同拍
    reg           [31:0]                       cnt_time                                   ;    // 温度操作周期拍计数
    reg           [7:0]                        daddr_in                                   ;    // SYSMON DRP地址，复位清0后保持

    reg           [15:0]                       di_in                                      ;    // SYSMON DRP写数据，复位清0后保持


    // sys_clk沿独立计时，到采样周期末拍归零；sys_rst同步清零。
    always@(posedge sys_clk) begin
        if (sys_rst) begin
            cnt_time    <= 32'd0    ;
        end else begin
            if(cnt_time == (CYCLE - 32'd1)) begin
                cnt_time    <= 32'd0    ;
            end else begin
                cnt_time    <= cnt_time + 32'd1 ;
            end
        end
    end


    // 在周期末前10拍发出一次DRP使能，其他拍撤销；地址与写数据保持复位后值。
    always@(posedge sys_clk) begin
        if (sys_rst) begin
            den_in      <= 1'b0     ;
            dwe_in      <= 1'b0     ;

            daddr_in    <= 8'd0     ;
            di_in       <= 16'd0    ;
        end else begin
            if(cnt_time == (CYCLE - 32'd10)) begin
                den_in      <= 1'b1 ;
                dwe_in      <= 1'b1 ;
            end else begin
                den_in      <= 1'b0 ;
                dwe_in      <= 1'b0 ;
            end
        end
    end


    // 在周期最后10拍给出busy，其他时刻清零；busy是本模块计时状态。
    always@(posedge sys_clk) begin
        if (sys_rst) begin
            busy    <= 1'b0 ;
        end else begin
            if((cnt_time >= (CYCLE - 32'd10)) && (cnt_time <= (CYCLE - 32'd1))) begin
                busy    <= 1'b1 ;
            end else begin
                busy    <= 1'b0 ;
            end
        end
    end

    sys_mon sys_mon_inst (
        .di_in          (di_in      ),
        .daddr_in       (daddr_in   ),
        .den_in         (den_in     ),
        .dwe_in         (dwe_in     ),
        .drdy_out       (),
        .do_out         (temp       ),
        .dclk_in        (sys_clk    ),
        .reset_in       (sys_rst    ),
        .channel_out    (),
        .eoc_out        (),
        .alarm_out      (),
        .eos_out        (),
        .busy_out       ()
    );


    ila_temp ila_temp_inst (
        .clk    (sys_clk    ),
        .probe0 (den_in     ),
        .probe1 (dwe_in     ),
        .probe2 (cnt_time   ),
        .probe3 (daddr_in   ),
        .probe4 (temp       ),
        .probe5 (busy       )
    );


endmodule
