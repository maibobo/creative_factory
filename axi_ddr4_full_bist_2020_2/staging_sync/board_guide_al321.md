# KU040 DDR4 上板测试操作指南

面向已会使用 Vivado 前仿、ILA 和 VIO，但尚未做过系统 DDR BIST 上板测试的人员。

## 1. 是否需要额外可综合模块

需要。ILA/VIO 本身只负责观察和控制，不能自动产生覆盖 4 GB 的 AXI 事务，也不能比较期望数据。本工程已增加可综合模块 `AXI_DDR_FULL_BIST`：它产生 AXI4 burst、接收响应、比较数据、记录首错现场并给出 PASS/FAIL；VIO 只选择模式和启动，ILA 只抓取关键总线与错误信息。

当前 WDATA 预取/phase 预译码 RTL 已完成远端编译、Elaborate 和 2-burst 快速冒烟；已有 compat bitstream 来自负 WNS 的旧实现，不得作为正式上板版本。本轮尚未重新综合/实现。所以下述流程是实现收敛后的操作说明，当前仍不能直接下载新工程上板。

## 2. 上板前准备

以后获得明确“允许综合”授权后，应分别生成：

1. `compat` bitstream：Micron 别名/CL16，用于复现同事已跑通的 Demo 条件。
2. `gd2400` bitstream：GDQ3BFAM-WJ/CL17，用于正式测试。

每个版本必须同时保留 `.bit`、`.ltx`、时序报告、DRC、route status 和构建日志。只有 WNS≥0、无 Error/Critical Warning、无未解释的未约束时序、无路由错误时，才进入下载步骤。

硬件准备包括：板卡、稳定电源、Xilinx JTAG、带 Hardware Manager 的 Vivado 2020.2。100 次冷启动还需要可记录次数的电源控制方式；温压测试需要温箱/热风与温度测量、电源容差调节及示波器/万用表，由硬件人员配合。

所有 BIST 模式都会覆盖所测 DDR 区域；全空间模式会破坏整片 4 GB 内容。确认板上没有其他主机使用 DDR 后再启动。

### 2.1 在 GUI 中完成构建并判定可发布

打开 `prj/compat/axi_ddr4_full_bist_compat.xpr`。若中断后的 `synth_1` 显示 Running/Queued，但 `runme.log` 没有 `synth_design completed successfully`，先右键 Reset Run，再依次执行 Run Synthesis、Run Implementation。不要同时运行 SSH batch 和 GUI 中的同名 run。

实现完成后依次检查：

1. Design Runs 中 `impl_1` 为 `route_design Complete!`，不是 Failed/Cancelled。
2. 打开 Implemented Design，Timing Summary 中 Setup WNS≥0、Hold WHS≥0，TNS=0，失败端点为0。
3. Report Methodology、Report DRC 和 Report Route Status 无 Error/Critical Warning、无未布通网络。
4. Check Timing 无未约束内部时序端点；外部异步复位/LED 无 I/O delay 必须在记录中说明接口属性，不能随意添加虚假延迟。
5. worst-100 首路径仍应有非负裕量；Clock Interaction 不得有未解释的红色跨时钟组合；Bus Skew 必须满足。
6. 以上全部满足后才 Generate Bitstream，并把 `.bit`、`.ltx` 与本次 reports 一起归档。旧负 WNS bitstream 必须隔离并标记 FAIL。

compat 仅用于复现 Demo 条件。它通过后，还必须对 `prj/gd2400/axi_ddr4_full_bist_gd2400.xpr` 重复完整构建门槛，正式上板验收以 GD2400 版本为主。

## 3. 下载和确认校准

1. 断电连接 JTAG，检查板卡供电和散热，再上电。
2. 打开 Hardware Manager，连接目标，确认器件为 `xcku040-ffva1156-2-i`。
3. Program Device 时同时指定匹配的 `.bit` 与 `.ltx`。
4. 观察 LED0 和 VIO `probe_in0`。LED0 在校准前闪烁，`init_calib_complete=1` 后常亮。
5. 确认 ILA `probe1=axi_aresetn` 只在校准完成且 `ui_clk_sync_rst=0` 后延迟两个 `ui_clk` 周期变为 1。
6. 若校准不通过，不启动 BIST，先测 1.2 V、VPP 2.5 V、VREF、AK17/配对脚 100 MHz、AC34 复位和 DDR CK。

注意事项：

- `.ltx` 必须和 `.bit` 来自同一次构建，否则 VIO/ILA 探针可能错位。
- 首次下载先使用 compat 版本建立板卡、JTAG、管脚与供电基线，再断电切换 GD2400 版本。
- 校准期间不要脉冲 start/restart；`init_calib_complete=1` 只代表 PHY 校准完成，不代表 DDR 数据测试通过。
- ILA 满足采样条件不等于功能 PASS，最终仍以 BIST 状态、错误计数和测试覆盖范围判定。

## 4. VIO 控制和结果读取

### VIO 输出

| 输出 | 含义 | 操作 |
|---|---|---|
| `probe_out0` | start | 模式设好后给一个 0→1→0 脉冲 |
| `probe_out1` | restart | 中止/清状态并重新开始，给一个脉冲 |
| `probe_out2[2:0]` | test_mode | 0～7，启动后不要中途修改 |
| `probe_out3` | repeat_enable | 1 表示完成后循环，长稳模式使用 |

顶层 `AUTO_START=1`，上电校准完成后会自动执行一次 mode 0。若要手动重复，等待自动测试结束后设置模式并脉冲 `start`；出现 FAIL 后先记录现场，再脉冲 `restart`。

### VIO 输入

| 输入 | 含义 |
|---|---|
| `probe_in0` | init_calib_complete |
| `probe_in1..4` | busy/done/pass/fail |
| `probe_in5[8:0]` | 当前 phase |
| `probe_in6[32:0]` | 当前扩展地址 |
| `probe_in7[15:0]` | 0～65535 进度 |
| `probe_in8[31:0]` | 错误计数 |
| `probe_in9[31:0]` | 首错地址 |
| `probe_in10[3:0]` | 最近 AXI 响应摘要 |
| `probe_in11[31:0]` | 超时计数 |

判定 PASS 必须同时满足：`done=1`、`pass=1`、`fail=0`、`error_count=0`、`timeout_count=0`。LED1 运行慢闪、PASS 常亮、FAIL 快闪，只适合粗看；正式记录以 VIO/ILA 数值为准。

### 4.1 AL321 连接后的完整 VIO/ILA 操作顺序

当前使用 Xilinx 兼容 USB cable **AL321**。紫光 AL232 不能作为本工程的可靠 JTAG/ILA 线缆；如果两根线同时连接，先拔掉 AL232，避免 Hardware Manager 选错线缆或 hw_server 连接异常。

按以下顺序操作：

1. 启动 Vivado 2020.2，打开 Hardware Manager，`Open Target -> Auto Connect`。确认树中出现 `xcku040_0`，状态为 `Programmed` 或可编程。
2. 右键 `Program Device`，选择同一次构建的 `.bit` 和 `.ltx`。不要只下载 bit 而不下载 ltx。
3. 展开 MIG 对象（截图中的 `MIG_1`/`U_DDR4_AXI_0`），等待 `MIG status=CAL PASS`，并确认 `probe_in0=1`。这一步只证明 PHY 校准通过。
4. 打开 `hw_vio_1`/`vio_bist_ctrl`，先把四个输出设为安全值：`start=0`、`restart=0`、`test_mode=0`、`repeat_enable=0`。
5. 打开 `hw_ila_1`/`ila_bist_status`。先点击 ILA 的 `Run Trigger` 或 `Run Trigger Immediately`，再进行 VIO 脉冲；否则可能错过首个 AW/W 握手。
6. 由于顶层 `AUTO_START=1`，校准释放后会自动执行一次 mode 0。先不要操作 VIO，观察 `busy` 是否从0变1再回到0、`done=1`。若自动测试已完成，先保存 ILA 波形和 VIO 数值。
7. 若需要手动启动 mode 0，必须在 `busy=0` 且 `done=0` 时将 `start` 置1一个 VIO 更新周期，再置回0。不要长按；start 是电平边沿检测输入。
8. 运行期间不要修改 `test_mode` 或 `repeat_enable`。它们在 start/restart 事件时锁存，运行中改动不会安全地切换当前序列。
9. 结束时等待 `busy=0`、`done=1`，读取 `pass/fail/error_count/timeout_count`，保存 ILA 数据、VIO 截图、bit/ltx SHA-256、板号、温度和电压。

VIO 到 ILA 的复合信号位定义（便于按位观察）：

| ILA 探针 | 位域 | 实际组成 |
|---|---|---|
| `probe2 ila_control[5:0]` | `[5]` repeat、`[4:2]` mode、`[1]` restart、`[0]` start | `vio_repeat_enable, vio_test_mode, vio_restart, vio_start` |
| `probe6 ila_aw_handshake[1:0]` | `[1]` AWVALID、`[0]` AWREADY | AW 握手在两位同时为1时发生 |
| `probe7 ila_w_handshake[2:0]` | `[2]` WVALID、`[1]` WREADY、`[0]` WLAST | WLAST 只在第16 beat有效 |
| `probe8 ila_b_channel[3:0]` | `[3]` BVALID、`[2]` BREADY、`[1:0]` BRESP | `00` 为 OKAY |
| `probe9 ila_ar_handshake[1:0]` | `[1]` ARVALID、`[0]` ARREADY | 两位同时为1时发出读地址 |
| `probe10 ila_r_channel[4:0]` | `[4]` RVALID、`[3]` RREADY、`[2]` RLAST、`[1:0]` RRESP | `RRESP=00` 且末 beat 有 RLAST |

### 4.2 下一个测试项是否需要复位

一般不需要重新上电、重新校准或重新下载 bitstream。当前状态机在 `BIST_DONE` 不会回到 `BIST_IDLE`，因此完成一个测试后，下一个测试项应使用 **restart 脉冲**重新锁存 mode 并启动：

1. 等待当前项 `busy=0、done=1`。
2. 先保存首错现场/ILA，再确保 `start=0、restart=0`。
3. 设置新的 `test_mode`，通常 `repeat_enable=0`。
4. 重新点击 ILA `Run Trigger`。
5. 将 `restart` 从0置1，再置回0。该脉冲会清除上一项状态并立即按新 mode 开始；不要只点 start。
6. 等待 `busy=1` 后观察 AXI，结束后按第4.1节第9步判定。

以下情况才需要外部复位/重新下载：

| 情况 | 操作 |
|---|---|
| 第一次上电或更换 bitstream | 先完成 MIG CAL PASS，再开始 BIST |
| compat 切换 GD2400、怀疑校准状态残留 | 停止业务，断电/上电并重新 Program，再确认 CAL PASS |
| BIST FAIL | 先保存现场；通常只需 `restart` 重跑，不要先复位 |
| MIG CAL FAIL、`axi_aresetn=0`、ui_clk 不运行 | 停止 VIO 操作，检查电源/时钟/复位，重新上电或下载 |
| Hardware Manager 仅断线但板卡仍运行 | 重新连接 target；不要在未保存现场前 restart |

`repeat_enable` 在 start/restart 时锁存。若 mode 7 以 `repeat_enable=1` 启动，运行中把 VIO 改回0不会立即停止当前循环；要结束循环需保存现场后重新 Program/复位，或后续增加独立 stop 控制。因此首次调试和可审计验收建议使用 `repeat_enable=0`。

## 5. ILA 使用方法

ILA 深度为 4096。常用触发建议：

- 首次调试：在 `init_calib_complete` 上升沿触发，检查 `axi_aresetn` 两拍释放。
- 总线握手：对 AWVALID/AWREADY、WVALID/WREADY/WLAST、BVALID/BREADY、ARVALID/ARREADY、RVALID/RREADY/RLAST 分组观察。
- 错误定位：以 `error_count != 0` 或 `last_axi_response != 0` 触发，并保存 `first_error_addr/expected/actual`。
- 末地址：mode 5/6 在 `current_addr_ext[32]=1` 或接近 `0x0_FFFF_FF80` 时触发，确认不会回绕重测低地址。

每个失败至少保存一份 ILA `.wdb`/CSV、VIO 截图或数值记录、bit/ltx SHA-256、板号、电源、温度和复现步骤。

## 6. 分项测试流程

### 6.1 GD 正式时序 32 KiB 冒烟

1. 先用 compat bitstream 复现校准和 mode 0 PASS，证明板卡/JTAG/管脚基线未退化。
2. 换用 gd2400 bitstream，重新上电，不复用上一个校准状态。
3. 等 `init_calib_complete=1`、`axi_aresetn=1`。
4. mode 0 会自动运行；或设置 `test_mode=0` 后脉冲 start。
5. 检查写/读各 256 个 burst、末地址 `0x0000_7FF8`、无响应/超时/数据错误。
6. 冷启动重复至少 3 次后再进入定向测试。

这一步证明 GD 参数下 32 KiB 基本读写，不证明全空间或长稳。

### 6.2 数据线测试

1. 设置 `test_mode=1`、`repeat_enable=0`，脉冲 start。
2. 测试依次覆盖全 0、全 1、AA、55、64 位 Walking-1 和 Walking-0。
3. PASS 期望写/读各 132 个 burst。
4. 失败时查看 `phase`：`phase/2` 对应模式序号，再结合首错数据定位疑似 DQ 位或 lane。

### 6.3 WSTRB 字节通道测试

1. 设置 `test_mode=2`，启动。
2. BIST 先清零一整个 burst，再依次只写一个 WSTRB lane，并每次回读确认已写字节改变、未写字节保持。
3. PASS 期望写/读各 9 个 burst。
4. 某一固定字节 lane 失败时，结合管脚表核对该 lane 的 DQ[7:0]、DQS 和 DM/DBI。

### 6.4 地址线与高地址别名

1. 设置 `test_mode=3`，启动。
2. BIST 先写完 26 个稀疏幂次地址，再统一回读，能够发现后写高地址覆盖先写低地址。
3. 记录首错地址和另一个呈镜像关系的地址；重复失败通常指向地址/Bank/片选映射或容量配置。

### 6.5 边界测试

1. 设置 `test_mode=4`，启动。
2. 观察 6 个 burst 基址：`0x00000000`、`0x00000080`、`0x00000780`、`0x00000F80`、`0x00003F80`、`0xFFFFFF80`。
3. 最后一组必须访问到 `0xFFFFFFF8`，且任何 burst 都不能跨 4 KiB。
4. 在 ILA 中核对 AWLEN/ARLEN=15、AWSIZE/ARSIZE=3、WLAST/RLAST 时序。

### 6.6 全 4 GB 正反向测试

1. 确认 DDR 没有业务数据且散热、电源稳定。
2. 设置 `test_mode=5`、`repeat_enable=0`，启动。
3. 阶段为：正向地址相关数据写、正向读；反向反码写、反向读。
4. 进度从 0 增至 65535，反向阶段相反；定期记录阶段、地址、进度和 elapsed cycles。
5. 最终地址必须覆盖 `0x00000000～0xFFFFFFF8`，错误计数为 0 才能记为“4 GB 地址相关模式 PASS”。

预计耗时不能由 RTL 编译阶段给出。上板时用 `elapsed_cycle_count / 实际 ui_clk` 计算，并分别记录读写吞吐。

### 6.7 全 4 GB March 类测试

1. 全空间地址相关模式通过后，设置 `test_mode=6`。
2. 执行 W0/R0、W1/R1、反向 W0/R0 多遍测试。
3. 期间不要复位或让其他主机访问 DDR。
4. 任何失败立即保存首错现场；不要先 restart，否则会清除最有价值的首错数据。

March PASS 是更强的单元耦合/保持故障证据，但仍不能替代温压和长稳。

### 6.8 10 分钟保持

1. 设置 `test_mode=7`、`repeat_enable=0`。
2. BIST 写入确定性 PRBS 后进入 HOLD，期间不改写测试区；默认保持计数按约 300 MHz 配成 10 分钟。
3. 用实现后的真实 `ui_clk` 重新核算时间；若频率不是 300 MHz，调整 `HOLD_CYCLES` 并重新生成 bitstream。
4. HOLD 结束后回读比较，记录实际保持时间、温度和电压。

### 6.9 不少于 1 小时 PRBS 压力

1. `test_mode=7`、`repeat_enable=1`，清零计时并启动。
2. 运行不少于 1 小时，周期性记录累计循环、错误计数、超时计数和温度。
3. 到时后将 repeat 置 0，让当前循环正常结束，再判定 PASS。
4. 任何单次错误都算 FAIL，不以随后循环通过抵消。

### 6.10 100 次热复位与冷启动

热复位和冷启动要分开统计，建议各 100 次；若项目只要求合计 100 次，报告中仍需分别列出次数。

- 热复位：保持板卡供电，使用外部 AC34 复位或确认能真正复位 MIG 的板级复位方式。每次记录校准是否在限时内完成、mode 0 是否 PASS。
- 冷启动：断开主电源，等待板上电源轨充分掉电后再上电。不要只重新下载 bitstream 冒充冷启动。
- 每次记录序号、校准耗时、测试结果、板温和异常。一次校准失败即标记该轮 FAIL 并保留现场。

## 7. 验收分层

报告必须分开写：

1. 校准通过。
2. 32 KiB 冒烟通过。
3. 数据线/地址线/WSTRB/边界通过。
4. 全 4 GB 地址相关模式通过。
5. 全 4 GB March 类通过。
6. 100 次复位循环通过。
7. 10 分钟保持和 1 小时 PRBS 通过。
8. 温压条件下关键测试通过。

前一层不能替代后一层。FPGA BIST 也不能替代 1.2 V、VPP、VREF、时钟、复位和信号完整性的板级测量。

### 7.1 每一级如何判定成功

| 层级 | 成功判据 | 不能替代的后续项 |
|---|---|---|
| 构建 | WNS/WHS≥0、TNS=0、失败端点0、DRC/Route无错误，bit/ltx同构建 | 不能证明上板校准 |
| 校准 | 每次上电 `init_calib_complete=1`，复位按两拍规则释放 | 不能证明读写正确 |
| 单模式 | `done=1, pass=1, fail=0, error_count=0, timeout_count=0`，事务数与模式预期一致 | 不能证明其他模式 |
| 32 KiB | mode 0 覆盖至 `0x00007FF8`，写/读各256 burst并满足单模式判据 | 不能证明4 GB |
| 定向项 | mode 1～4 分别通过，且末边界访问到 `0xFFFFFFF8` | 不能证明连续全空间 |
| 全4 GB | mode 5 完整结束，地址/阶段/进度连续且零错误 | 不能证明March和长稳 |
| 长稳/复位 | mode 6/7、保持、压力和规定次数冷热复位分别零错误 | 不能替代温压与电气测量 |

发生 FAIL 时先保存首错地址、期望/实际数据、AXI 响应、phase、当前地址和 ILA 波形，再决定 restart；先重启会清掉根因现场。固定 DQ 位失败优先查数据线/焊接，固定字节 lane 优先查 DQS/DM/DBI，成对或镜像地址失败优先查地址/Bank/容量映射，随机温度相关错误优先查时序裕量、电源和信号完整性。
