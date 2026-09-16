# KU040 DDR4 管脚对照与 XDC 审计

更新时间：2026-09-11

## 1. 审计结论

第 32 章 Demo、原 AXI 最小工程和新全空间工程的 111 条 PACKAGE_PIN 完全一致。原最小工程与新工程的 XDC 内容及 SHA-256 完全一致，因此本轮没有修改物理绑定。

| 工程 | PACKAGE_PIN | IOSTANDARD | 手写 create_clock | SHA-256 |
|---|---:|---:|---:|---|
| `26_top_ddr4_rw` | 111 | 120 | 1 | `430AD760...DDF0D` |
| `axi_ddr4_min_2020_2` | 111 | 120 | 0 | `66010B15...1DEA` |
| `axi_ddr4_full_bist_2020_2` | 111 | 120 | 0 | `66010B15...1DEA` |

Demo 唯一需要排除的时钟差异是：

```tcl
create_clock -period 10.000 -waveform {0.000 5.000} [get_ports sys_clk_p]
```

新工程不复制该行，由 MIG 生成输入时钟及内部派生时钟约束，避免同一时钟重复建立。旧 Debug Hub 约束也不复制。

## 2. 板级控制与命令地址管脚

| 端口 | 管脚 | 端口 | 管脚 |
|---|---|---|---|
| `sys_rst_n` | AC34 | `sys_clk_p` | AK17 |
| `led[0]` | T22 | `led[1]` | T23 |
| `adr[0]` | AG14 | `adr[1]` | AF17 |
| `adr[2]` | AF15 | `adr[3]` | AJ14 |
| `adr[4]` | AD18 | `adr[5]` | AG17 |
| `adr[6]` | AE17 | `adr[7]` | AK18 |
| `adr[8]` | AD16 | `adr[9]` | AH18 |
| `adr[10]` | AD19 | `adr[11]` | AD15 |
| `adr[12]` | AH16 | `adr[13]` | AL17 |
| `adr[14]` | AL15 | `adr[15]` | AL19 |
| `adr[16]` | AM19 | `ba[0]` | AG15 |
| `ba[1]` | AL18 | `bg[0]` | AJ15 |
| `ck_t[0]` | AE16 | `ck_c[0]` | AE15 |
| `cs_n[0]` | AE18 | `cke[0]` | AJ16 |
| `odt[0]` | AG19 | `act_n` | AF18 |
| `reset_n` | AG16 |  |  |

`sys_clk_n` 和各 `dqs_c` 是差分对的互补端，由器件差分管脚配对/MIG pinout 关联，不在该 XDC 中另写 PACKAGE_PIN。

## 3. DQ 管脚

| DQ范围 | 按位管脚（低位到高位） |
|---|---|
| DQ[7:0] | AE20, AF22, AF20, AG20, AD20, AG22, AE22, AE23 |
| DQ[15:8] | AF24, AJ23, AF23, AH23, AG25, AJ24, AG24, AH22 |
| DQ[23:16] | AK22, AM20, AL22, AL23, AL20, AL24, AK23, AL25 |
| DQ[31:24] | AM22, AP24, AN22, AN24, AN23, AP25, AP23, AM24 |
| DQ[39:32] | AM26, AK26, AM27, AJ28, AK27, AH28, AK28, AH27 |
| DQ[47:40] | AM30, AP29, AM29, AP28, AL29, AN28, AL30, AN27 |
| DQ[55:48] | AH31, AH34, AJ31, AK32, AH32, AJ34, AJ30, AK31 |
| DQ[63:56] | AN31, AP33, AP31, AM32, AN32, AM34, AN33, AL34 |

## 4. DQS 与 DM/DBI 管脚

| 字节通道 | DQS_T | DM/DBI_N |
|---:|---|---|
| 0 | AG21 | AD21 |
| 1 | AH24 | AE25 |
| 2 | AJ20 | AJ21 |
| 3 | AP20 | AM21 |
| 4 | AL27 | AH26 |
| 5 | AN29 | AN26 |
| 6 | AH33 | AJ29 |
| 7 | AN34 | AL32 |

## 5. I/O 标准

- `sys_clk_p/n`：`DIFF_HSTL_I_12`。
- 外部低有效复位和 LED：`LVCMOS18`。
- DDR CK：`DIFF_SSTL12_DCI`。
- DDR 地址/命令/控制：`SSTL12_DCI`，DDR reset_n 为 `LVCMOS12`。
- DDR DQ/DM：`POD12_DCI`。
- DDR DQS：`DIFF_POD12_DCI`。

## 6. 上板前仍需完成的确认

XDC 与已通过 Demo 一致，说明逻辑网名到 FPGA 封装脚的复用有强证据，但不能代替板卡原理图逐网核对。最终上板前仍应让硬件人员对照原理图确认：四颗 x16 的字节 lane 排列、DQS/DM 与相应 DQ 组、差分极性、VREF、1.2 V、2.5 V VPP、ODT/终端网络和复位电平。综合未执行，因此本轮还没有 Vivado 的未约束 I/O、I/O bank、DRC 或实现后 pin report 结论。
