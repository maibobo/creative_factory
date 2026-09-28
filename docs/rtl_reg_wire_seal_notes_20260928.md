# RTL 关键 reg、wire 与 `seal` 说明

本文对应 `C:\project\RTDS\DDR\RTDS_test_DDR4_64bit_batch_dev\rtl` 当前版本，分析 `RTDS_FPGA_1G_INIT`、`RTDS_1G_PERIODIC_TX` 和 `RTDS_RX_BLOCK_WRITER`。`ddr4` 目录及 `*cdc.v`、`*sync.v`、`*fifo.v` 不在信号分析范围内。表中的 `reg`、`wire` 是 Verilog 声明类型；`always @(*)` 内赋值的 `reg` 仍是组合逻辑，不能仅凭声明类型判断它是触发器。

## `seal` 前缀的含义

`RTDS_RX_BLOCK_WRITER` 使用 `seal` 表示一个计时周期的收尾过程。`tick` 到达时，模块暂时停止读取新的接收字，但已经开始的 FDMA 写事务仍须等到最终写响应。若还留有一个未配对的 32 位字，模块会将它写成低四字节有效的 64 位尾拍。以上工作结束后，当前块中已经成功写入的数据才可供 CPU 读取。

| 信号 | 类型 | 条件及作用 |
| --- | --- | --- |
| `seal_pending` | `reg` | `tick` 到达后置 1，表示收尾尚未结束；正常情况下遇到 `seal_done` 清 0。若两者同拍成立，`tick` 优先，下一拍继续检查。 |
| `seal_done` | `wire` | `write_curr_st == IDLE && seal_pending && !half_valid`。只有 FDMA 写状态空闲，且没有剩余单字时才成立。 |
| `tail_start` | `wire` | 收尾期间还留有单字且写状态空闲时启动尾拍写入。 |
| `push_block` | `wire` | `seal_done` 且 `used_bytes != 0` 时成立；空周期不会产生可读块。 |

这几个信号不会直接取消正在进行的写事务。`used_bytes` 只随无错误的最终写响应增加，因此块长度反映的是已确认写入的字节数。

## `RTDS_FPGA_1G_INIT`

模块用 `BUFGCE_DIV` 将 `clk_100m` 四分频生成 25 MHz `init_clk`，再在该时钟域内分阶段解除 GT 和协议核复位。主机复位 `rst` 为高有效。

| 信号 | 类型 | 定义原因和工作原理 |
| --- | --- | --- |
| `rst_n` | `wire` | 将高有效的 `rst` 取反，供低有效复位接口使用。 |
| `init_rst_n` | `wire` | 由复位同步模块产生，在 `init_clk` 域同步解除复位，作为计数器和输出寄存器的复位条件。 |
| `startup_count` | 8 位 `reg` | 从 0 计到 `8'hff` 后保持；提供两个复位解除时刻，避免依赖组合布线产生业务时钟。 |
| `gt_reset` | 输出 `reg` | 计数小于 128 时为 1，先解除 GT 复位。 |
| `core_reset` | 输出 `reg` | 计数尚未到 255 时为 1，晚于 GT 解除，给收发器留出初始化时间。 |

`gt_reset` 和 `core_reset` 在时钟沿赋值，比较的是该沿之前的 `startup_count`，因此输出比对应计数条件晚一个 `init_clk` 拍变化。

## `RTDS_1G_PERIODIC_TX`

模块从 250 MHz 控制域接收首次合法编号，译码为 48 位参数，再通过配置跨域模块送到 `user_clk` 域。用户域按固定拍数尝试发送两拍数据；`tx_ready` 暂停时保持当前状态和数据。

| 信号 | 类型 | 定义原因和工作原理 |
| --- | --- | --- |
| `src_rst_n`、`user_rst_n` | `wire` | 分别在控制域和用户域同步解除主机复位，避免直接用另一时钟域的复位释放时序。 |
| `decoded_duty`、`decoded_vin`、`decode_valid` | 组合 `reg` | 根据 `cfg_byte` 的 1～10 编号查表；先给默认值，非法编号使 `decode_valid` 为 0，避免锁存器及错误配置。 |
| `cfg_hold` | 48 位 `reg` | 首次合法数据到达时保存 `{Vin,duty}`；跨域请求期间数据保持稳定。 |
| `cfg_req` | `reg` | 首次合法配置后保持为 1，防止后续配置帧覆盖首次参数。 |
| `configured_id` | 输出 `reg` | 保存首次合法编号，供控制域读取和核对。 |
| `cfg_send` | `wire` | `cfg_req && !configured && rst_n`，控制源端跨域请求；确认后撤销。 |
| `req_sync`、`cfg_cdc_data` | `wire` | 分别是用户域收到的请求和完整 48 位参数；参数由跨域模块整体传递。 |
| `cfg_user`、`cfg_ack` | `reg` | 用户域首次看到 `req_sync` 时锁定参数并记录已接收状态；链路临时复位不清除已配置参数。 |
| `cfg_dest_ack`、`ack_sync` | `reg`、`wire` | 目的端确认先寄存，再由跨域模块返回源端；请求撤销后目的端确认也撤销。 |
| `configured` | 输出 `reg` | 源端收到 `ack_sync` 后保持为 1，表明一次配置流程完成。 |
| `period_count`、`period_tick` | `reg`、`wire` | 用户域每 `PERIOD_CYCLES` 拍产生一次发送机会；未配置时计数清零。发送忙或链路掉线不会把机会累加成待发数据。 |
| `arm_count` | 3 位 `reg` | 链路恢复或接口复位结束后等到计数 4 才允许发送，避免立即使用恢复前的状态。 |
| `tx_curr_st`、`tx_next_st` | 时序 `reg`、组合 `reg` | 状态按 `IDLE → FIRST → LAST → IDLE` 推进；首拍和末拍只有在 `tx_ready` 为 1 时才切换。 |
| `skipped_periods` | 输出 `reg` | 已允许发送且状态忙时，若 `period_tick` 到达则累加一次，记录错过的发送机会。 |
| `tx_data`、`tx_rem`、`tx_sof`、`tx_eof`、`tx_valid` | 输出 `wire` | 根据当前状态组合形成发送数据、有效字节数和帧标记；状态保持时输出也保持。 |

只有主机逻辑复位会清除首次配置。`user_reset` 和 `channel_up` 影响当前帧发送及 `arm_count`，不会改写控制域保存的编号和用户域已接收参数。

## `RTDS_RX_BLOCK_WRITER`

模块在 `clk` 域将两个 32 位有效字拼为一个 64 位 FDMA 写拍；周期末尾若只有一个字，则写低四字节有效的尾拍。写地址和有效长度依据最终写响应维护。默认有 8 个块，每块 262144 字节。

| 信号 | 类型 | 定义原因和工作原理 |
| --- | --- | --- |
| `INDEX_BITS` | `localparam` | 由 `BLOCK_COUNT` 取 `$clog2`，确定块指针位宽。默认 8 块时，3 位指针截断后自然回到 0。若改为非 2 的整数次幂的块数，需要另外处理指针回绕。 |
| `write_curr_st`、`write_next_st` | 时序 `reg`、组合 `reg` | 写事务经过 `IDLE`、`REQ`、`DATA`、`RESPONSE`；请求被接受、数据握手、最终响应分别推进状态。 |
| `write_block`、`read_block` | `reg` | 分别指向当前写块和最早可读块；块完成时移动写指针，CPU 确认时移动读指针。 |
| `queued` | `reg` | 记录尚未由 CPU 确认的完整块数；`push_block` 增加，`pop_block` 减少，两者同拍时数量不变。 |
| `block_len[]`、`block_seq[]` | `reg` 数组 | 块完成时分别记录有效字节数和顺序编号，使 CPU 读取的元数据在确认前保持。 |
| `used_bytes` | 32 位 `reg` | 当前写块已成功写入的字节数；仅 `write_success` 时增加，块完成后清零，失败的写入不会造成地址空洞。 |
| `time_count`、`tick` | `reg`、`wire` | 按 `PERIOD_CYCLES` 独立计时；`tick` 标识周期末尾，与写响应等待时间无关。 |
| `publish_seq` | 32 位 `reg` | 每完成一个非空块递增，用于给块分配顺序编号。 |
| `half_valid`、`half_data` | `reg` | 保存第一个尚未配对的 32 位字；下一字到达时组成完整拍，周期结束时组成尾拍。 |
| `active_transfer` | 76 位 `reg` | 一次锁定 `{有效字节数, WSTRB, 数据}`，在事务完成前保持；完整拍为 8 字节和 `8'hff`，尾拍为 4 字节和 `8'h0f`。 |
| `take_word`、`reject_word` | `wire` | 前者表示输入拍已被本模块读取；后者在未使能、块数已满或当前块空间不足时要求舍弃该字。 |
| `pair_start`、`tail_start`、`start_write` | `wire` | 分别识别两个字配对、单字尾拍和两种写入共同的启动条件。 |
| `write_success`、`write_failure` | `wire` | 仅在 `RESPONSE` 状态收到 `fdma_wdone` 时依据 `fdma_werror` 判定；数据握手本身不代表 DDR 写成功。 |
| `push_block`、`pop_block` | `wire` | 分别表示非空块已可读、CPU 确认已有可读块；空队列上的确认不会移走同拍新完成的块。 |
| `drop_sum`、`dropped_frames` | 33 位 `wire`、32 位输出 `reg` | 统计被拒绝的字和失败事务对应的字数，利用额外一位判断溢出并在 32 位最大值处保持。此处单位是有效 32 位字。 |
| `head_addr`、`head_len`、`head_seq`、`ready_blocks` | 输出 `wire` | 根据 `read_block`、块元数据和 `queued` 提供 CPU 可读状态；无可读块时前三项返回 0。 |
| `irq` | 输出 `reg` | 新的可读块可置位通知；CPU 确认后按是否仍有块更新，`irq_clear` 只清通知，不移走数据块。 |
| `fdma_waddr`、`fdma_wsize`、`fdma_wdata`、`fdma_wstrb`、`fdma_wareq`、`fdma_wvalid` | 输出 `wire` | 由块地址、成功写入长度、锁定的事务内容及状态机构成 FDMA 写接口；`fdma_wsize` 固定为一个 64 位拍。 |

一个数据字到达时，若可接受且未被拒绝，模块先将它放入 `half_data`；第二个字到达后锁定完整写拍。`fdma_waccept` 使状态进入等待最终响应，只有 `fdma_wdone && !fdma_werror` 才增加 `used_bytes`。CPU 看到的块地址、长度和编号均来自已经完成的块；读取中断状态不等于确认块，只有 `cpu_ack` 才会推进 `read_block`。
