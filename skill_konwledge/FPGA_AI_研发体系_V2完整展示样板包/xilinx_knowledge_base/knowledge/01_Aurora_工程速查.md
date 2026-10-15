# Aurora 工程速查

## 当前可复用基线

知识库保留两套 Vivado 2020.2 工程基线：

| 基线 | 线路与用户接口 | 关键时钟 | 当前证据 |
|---|---|---|---|
| Aurora 64B/66B | 1 lane，10.3125 Gb/s，64 bit 用户数据 | 10.3125 GHz ÷ 64 = 161.1328125 MHz 用户时钟 | 统一用户接口审计、XCI 编译/展开和接口仿真通过；综合、实现、时序、DRC、bitstream 未运行 |
| Aurora 8B/10B | 1 lane，1.25 Gb/s，4 byte/32 bit LocalLink | 125 MHz GT 参考时钟；31.25 MHz 用户时钟；有效载荷约 1 Gb/s | 官方双端点仿真通过；`CHANNEL_UP` 约 26.838 us，测试成功约 31.838 us；设计编译/展开通过 |

64B/66B 工程里常见的 156.25 MHz 是 66 bit block rate，不是 64 bit 用户接口时钟。PCIe 大仿真中使用的 156.25 MHz 也只是 LocalLink 边界 BFM 的建模时钟，不能反向证明真实 10.3125G Core 的 `user_clk_out` 配置。

## 统一用户接口语义

64 bit 版本的对外接口为：

- TX：`tx_data[63:0]`、`tx_rem[2:0]`、`tx_sof`、`tx_eof`、`tx_valid`、`tx_ready`。
- RX：`rx_data[63:0]`、`rx_rem[2:0]`、`rx_sof`、`rx_eof`、`rx_valid`，没有 RX ready。
- 状态：`user_clk_out`、`system_reset_out`、`channel_up`、`rx_crc_error`。
- 复位：`reset` 负责协议/通道复位；`gt_reset` 进入 10G wrapper 的 `PMA_INIT`，负责完整 GT/PMA 初始化。

32 bit 8B/10B 版本遵循同样的帧级语义，`rem` 宽度改为 2 bit。

必须遵守的握手规则：

1. TX 只有 `tx_valid && tx_ready` 才消费当前拍。反压期间，数据、SOF、EOF 和 REM 必须全部保持稳定。
2. `rem` 只在 EOF 拍有效，含义是“最后一拍有效字节数减 1”。中间拍必须按全宽处理。
3. RX 没有反压能力。下游必须连续接收；若后级会暂停，必须先用足够深的 FIFO 吸收，并提供 overflow/sticky 状态。
4. 业务层通常以 `channel_up` 作为可用门槛。`lane_up`、`hard_err`、`soft_err` 和原始 CRC 状态保留在 wrapper 内部用于诊断。
5. `rx_crc_error = crc_valid_i && !crc_pass_fail_n_i`，只在 CRC 结果有效时报告错误。

## 时钟与复位接法

- 用户逻辑在 `user_clk_out` 域运行，并使用 Core 的 `sys_reset_out` 派生出的 `system_reset_out` 复位。
- `reset` 与 `gt_reset` 不应合并成一个含义不清的脉冲。链路协议重启和 GT/PMA 重新初始化的代价不同。
- `channel_up` 之前不得发起业务帧；链路掉线后应停止新事务、清理或重新武装上层状态机。
- 跨到 PCIe、DDR 或系统时钟域时，数据走异步 FIFO；电平状态走同步器；脉冲事件使用 toggle、握手或计数器，不直接打一拍跨域。

## 集成时最容易出错的地方

| 风险 | 工程规则 |
|---|---|
| 把 156.25 MHz 当成 10.3125G 用户时钟 | 根据编码、线路速率和用户位宽重新计算，并以 XCI/Core 输出为准 |
| 认为 RX 可等待下游 ready | Aurora RX 到达后不可在线路上暂停；在边界设置 FIFO 和溢出策略 |
| 只按历史端口名连接 valid/ready | 以模块内赋值、端口方向和已通过 testbench 的语义为准 |
| EOF 字节数错误 | 只在 EOF 使用 `rem + 1`；scoreboard 按有效字节比较 |
| 只看到 `channel_up` 就宣称上板通过 | 链路状态不覆盖数据内容、CRC、时序、GT 约束和板级 SI |

## 已验证与未验证

### 64B/66B 10.3125G

已通过：统一接口审计、实际 XCI 编译/展开、接口仿真、规范化 XCI 配置比较，原始 XDC 哈希一致。

未宣称完成：综合、实现、静态时序、DRC、bitstream、板卡收发和接口调整后的官方双端点完整回归。

### 8B/10B 1.25G

已通过：官方双端点功能仿真、设计编译/展开。工程目标器件为 `xcku040-ffva1156-2-i`，1 lane、4 byte LocalLink、framing/CRC 开启、scrambler 关闭。

未完成：当前 XDC 只覆盖参考时钟、初始化时钟和 GT 参考引脚；最终板卡还需补复位、状态和其他板级 I/O 约束，并执行实现、时序与上板验证。

## 主要证据

- `R:\aurora_64b66b_10p3125g_2020_2_verified\README.md`
- `R:\aurora_64b66b_10p3125g_2020_2_verified\reports\VALIDATION_SUMMARY.md`
- `R:\aurora_8b10b_1p25g_2020_2_verified\README.md`
- `E:\aurora_proc\README.md`
- `R:\fdma_aurora_brg_aurora_loop-validate\docs\pg074-aurora-64b66b-en-us-12.0.pdf`

