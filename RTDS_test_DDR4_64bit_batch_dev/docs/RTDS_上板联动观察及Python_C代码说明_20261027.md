# RTDS 主机上板联动观察与 Python/C 代码说明

日期：2026-10-27。对象为 ARM Linux `192.168.50.10`、主机 FPGA、DDR 和远程 Windows 的 Vivado Hardware Manager。本次实验使用 VIO 固定源，真实 Aurora 对端不参与。

## 1. 先判断什么已经成立

- 当前只读检查：PCIe 端点 `0000:01:00.0` 绑定 `xdma`。初次 BAR0 读版本为 `0xFFFFFFFF`，实际 PCIe `COMMAND/BAR0/BAR1` 均为 0；这不是正常寄存器值。
- 已在无人占用 XDMA 节点的条件下，按既有流程只移除该 FPGA 端点并重扫其父桥，未重启 CPU、未重新下载 FPGA。恢复后 `VERSION=0x2001`、`BUILD_ID=0x20260914`、`0x2C=0x3`、`0x30=0`、`0x38=0`。恢复证据保存在原实验包 `validation/recovery_20261027_144120.json`。
- 图中的 `MIG CAL PASS` 表示 MIG 校准通过；不独自证明 DMA 数据正确。版本号和文件哈希也不能单独证明板上 bit 身份。执行前核对实际运行的 bit/LTX、调试核和探针，不能依赖旧截图或旧桥接文件。
- 2026-10-19 已有 16 Byte DDR 往返和 2/8/2 块实测，本次演示结果另行记录。文件创建或程序部署不代表本轮实板实验通过。

## 2. 观察顺序与通过依据

1. **基线**：确认无其他业务使用 XDMA，核对 `0x00/0x04/0x08`、`0x2C`、`0x30`、`0x38`；等待队列为空。`hw_vio_1` 如提示输出不同步，先刷新并核对 VIO 实际输出；不要直接 Reset VIO Core Outputs。
2. **DDR 往返**：向卡端 `0x8000` 写入 `00…0F` 共 16 Byte，再读回比较。ILA1 查看写侧 AW、W、B 和读侧 AR、R 的 VALID/READY、地址、数据与响应；只有 VALID 和 READY 同时为 1 才是有效握手。
3. **8 块慢速**：每次对 `rx_test_start` 提交 `0→1`，等待硬件确认后队列逐步 `0→8`。每次取队头地址、长度和序号，通过 C2H 读取、比较前 8 个有效字节，再写 `0x14=1` 一次归还，队列逐步 `8→0`。每个确认状态保持约 2 秒；每次注入和读取均保存 ILA 数据。
4. **8 块连续**：同样注入 8 块并逐块读取归还，但不增加人工显示停留；结果仍记录全部块。VIO/JTAG 和控制程序的开销使其不能作为真实 Aurora 速率或性能验证。

上行 8 个槽的起点为 `0x100000 + 槽号 × 0x40000`，实际读取地址必须以 `0x18` 返回的队头为准。每块有效数据为 `11 00 00 00 22 00 00 00`；C 程序的请求长度是对齐后的 16 Byte，只比较前 8 Byte。槽内旧数据和 `0x8000` 的旧 16 Byte 本次允许覆盖，不自动恢复。

## 3. 窗口和执行位置

| 窗口 | 位置 | 内容 |
|---|---|---|
| Vivado Hardware Manager | 远程 Windows 已打开的 GUI | 观察 VIO、布防及显示 ILA，编号可能变化，按实例路径识别。 |
| 寄存器监视 | ARM root 终端 | `python3 /root/rtds_joint_demo_20261027/arm/rtds_regs_watch.py --log /root/rtds_joint_demo_20261027/live_status.log`；只读采样，不轮询 `0x10`。 |
| 实时文字提示 | 远程 Windows 交互桌面 | `notice_window.py` 只读取本轮 JSONL 事件，显示阶段、实测值、波形路径和错误；不操作硬件。 |

在当前连接板卡的 Vivado Tcl Console 中执行：

```tcl
source C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/debug/hardware_joint_demo_20261027/vivado/open_demo.tcl
```

该命令在当前 GUI 用户桌面启动独立提示窗口，并尝试在 VS Code 中打开 Python/C 源文件，然后启动桥接。若未找到 VS Code，可从现有 IDE 打开演示目录。记录本次 `DEMO_READY_JOBS` 返回的目录；每次重新打开 Vivado 要重新启动桥接。若提示旧 `::rtds_gui` 桥接仍在运行，先确认没有其他实验，再在原 GUI 中停止旧桥接。桥接启动只检查当前设备与状态，不下载 bit。只有本次 `inspect` 请求收到回复才能确认桥接在线；旧 `service.ready` 文件不足以证明在线。

控制端按本次桥接目录运行 `pc/demo_runner.py`，运行时从标准输入读取 ARM SSH 密码；在交互终端可加 `--prompt-password` 隐藏输入。示例中的目录需替换为本次实际输出，事件文件须选新名字：

```powershell
python pc/demo_runner.py --jobs "C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/debug/hardware_joint_demo_20261027/jobs/gui_本次会话" --events "C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/debug/hardware_joint_demo_20261027/events/live_20261027.jsonl" --exclusive --prompt-password
```

该示例的工作目录是 `C:\project\RTDS\DDR\RTDS_test_DDR4_64bit_batch_dev\debug\hardware_joint_demo_20261027`。`--exclusive` 是操作者确认其他业务已停止，不是对任意外部程序的硬件互斥保证。程序还会检查 XDMA 设备节点占用，并持有 `/run/lock/rtds_joint_lab.lock`，避免本实验包的并行实例。

## 4. 关键寄存器和信号

| 项目 | 作用与判读 |
|---|---|
| `0x00/0x04/0x08` | VERSION、BUILD_ID、单槽容量。版本不匹配或全 1 时停止；容量不等于当前块长度。 |
| `0x10` | 通知读清寄存器；普通观察不读。正式 8 块实验在取首块前明确读取一次，验证读清不会归还队列块。 |
| `0x14` | 写 1 归还一个已验证块；写返回不等于队列已减一，还要核对 `0x30`。失败或不确定时不重试。 |
| `0x18/0x1C/0x34` | 当前队头 DDR 地址、有效字节数、序号；逐块重读并检查稳定性。 |
| `0x20/0x24/0x28` | 下行忙/启动、起始地址和长度。本次演示不写 `0x20`。 |
| `0x2C/0x30/0x38` | DDR 就绪和错误、已完成未归还块数、累计丢字数；丢字计数饱和后无法证明没有新增丢字。 |
| `rx_test_start` | VIO 输出；一次 `0→1` 提交一次固定数据注入，高电平保持不会持续发块。 |
| `rx_test_accepted_r` | 本次接受的 32 bit 字数；2 表示两个字共 8 Byte，不代表两个块。 |
| `rx_test_busy_r/rx_test_blocks_r/rx_test_status_r` | 注入忙、未归还块数、DDR/link/fault/通知状态；块数与 `0x30` 在状态稳定时对应。 |
| `live_vio` | 当前 PCIe/DDR、复位和时钟等状态位；正常示例 `0x00BF` 需按当前位定义判读，不代替 DMA 校验。 |
| `clear_vio/capture_axi_vio` | 诊断历史清除及捕获选择控制；本演示不提交这两个输出。 |
| `fdma_wareq/wbusy/waddr/wdata/wsize` | ILA2 中的上行写请求、忙、地址、数据及 64 bit 拍数；要结合状态、寄存器和读取结果判定成功。 |
| `ila_axi` | ILA1 的 216 bit DMA AXI 打包信号，包含 AW/W/B/AR/R 的地址、数据及握手；它不直接采集 BAR AXI-Lite 寄存器写入。 |
| `ila_pcie_phy` | PCIe PHY 诊断；PLL 锁定与复位状态需按实际所用 QPLL/CPLL 判断，不要求所有探针都为 1。 |

监视器默认每 0.5 秒依次读寄存器，非原子快照；可能漏掉短脉冲。ILA 是触发后的有限深度采样，不是持续实时录像。Windows 时间、ARM 单调时间和 ILA 采样周期分开记录，不假设严格同步。

## 5. Python 实验程序函数

`arm/rtds_lab.py` 在 ARM 运行，访问既有 XDMA 驱动；它不是驱动源码。

| 函数/方法 | 目的 |
|---|---|
| `atomic_json` | 先写临时文件再替换，避免中断产生半份 JSON。 |
| `parse_io` | 只解析目标物理地址唯一对应的 `io` 读取值。 |
| `compare_bytes` | 检查长度和每个字节，出错时给出偏移。 |
| `Report.__init__/log/finish` | 创建唯一运行目录，追加事件、写 JSON/CSV、记录成功或失败。 |
| `Hardware.__init__` | 按 vendor/device 查找 BDF、BAR、驱动和字符设备，并核对设备属于所选 BDF。 |
| `Hardware.reject_external_users` | 检查其他进程是否打开 XDMA 设备节点；无法覆盖所有可能的外部访问方式。 |
| `Hardware.rd/wr` | 白名单寄存器读写；只有显式 `read_clear` 才读 `0x10`，写操作要求独占并限制地址。 |
| `Hardware.snapshot/wait` | 读取不含读清寄存器的状态快照；按单调时间等待指定寄存器值。 |
| `Hardware.dma` | 检查实验地址和长度，调用 C 辅助程序一次；错误、短传输、超时均停止且不重试。 |
| `Control.__init__/call` | 以人工确认或唯一请求 ID 的文件握手等待 Vivado 检查、布防、注入和保存完成。 |
| `Experiments.health/preflight` | 检查身份、DDR 状态、忙、丢字和空队列基线。 |
| `Experiments.config` | 测试下行地址/长度配置回读，并在健康空闲时恢复原值；本演示不运行此用例。 |
| `Experiments.ddr` | 在 `0x8000` 做 16 Byte H2C/C2H，分别采集 ILA 并比较数据。 |
| `Experiments.inject/demo_hold` | 提交一次 VIO 注入、确认队列数；仅在确认后按演示设置停留，延时不代替握手。 |
| `Experiments.head/consume` | 稳定读取队头；可在读取前布防 ILA；C2H、比较、检查后只归还一次并验证块数减一。 |
| `Experiments.up` | 原 `single/multi` 流程及新增 `eight` 流程，检查 8 个不同槽和环回。 |
| `Experiments.run` | 执行预检、指定用例和最终健康检查。 |
| `arguments/main` | 校验参数、取得实验锁、建立对象；异常时保存现场并以失败退出。 |

## 6. Windows 控制与提示函数

`pc/lab_remote.py` 是复用的控制/传输库：

| 函数 | 目的 |
|---|---|
| `ssh_win/connect/remote_exec` | 通过既有 Windows SSH 或 ARM SSH 执行远程命令；核对保存的主机密钥。 |
| `deploy/deploy_locked` | 原实验包的部署与互斥部署入口；演示运行不依赖自动覆盖原 ARM 程序。 |
| `windows_job_url/hw_call_ssh/hw_call` | 限定桥接动作、生成唯一请求、等待应答；不确定时不重复提交。 |
| `discover_gui_jobs` | 发现符合日期的 GUI 作业目录；本演示显式选择本次目录，避免误用旧目录。 |
| `download_tree` | 将本轮 ARM 结果取回 Windows，保留独立目录。 |
| `run_case` | 启动 ARM 单个用例、转发 Vivado 握手、追加实时日志并传递事件；不自动重试失败动作。 |
| `main` | 原工具命令行入口；演示使用单独的 `demo_runner.py`。 |

`pc/demo_runner.py`：`EventLog.__init__/emit/arm_event` 创建并追加带会话编号的事件；`connect_arm` 按已保存主机密钥认证；`run` 依次执行只读预检、GUI 在线检查、DDR、慢速 8 块、连续 8 块；`main` 解析参数并从标准输入或隐藏提示读取密码，不把密码写入日志。

`pc/notice_window.py`：`describe` 将事件转成中文说明；`NoticeWindow.__init__` 创建独立窗口；`NoticeWindow.poll` 增量读取 JSONL 并刷新文字；`main` 解析事件文件路径并运行窗口。该窗口只观察事件，不直接读取寄存器或控制 Vivado。

`arm/rtds_regs_watch.py`：`discover_bar` 从 PCIe 资源中确认 BAR；`parse_value` 解析目标地址；`sample` 逐个读取安全白名单；`describe` 解释寄存器含义；`Journal.__init__/update/describe` 增量解读实验日志；`frame` 生成完整快照；`changed_rows/change_output` 提取和显示变化；`main` 解析采样参数并运行。它不读清 `0x10`、不写寄存器、不提交 DMA。

## 7. C DMA 程序函数

`arm/rtds_dma.c` 是用户态辅助程序，不是 Linux 内核驱动：

| 函数 | 目的 |
|---|---|
| `number` | 解析十进制或十六进制无符号参数，拒绝负数、溢出和多余字符。 |
| `file_io` | 对普通输入/输出文件循环读写完整长度；不对 XDMA 字符设备补发。 |
| `main` | 验证方向、地址、长度及 16 Byte 对齐；分配页对齐缓冲区；H2C 先读完整输入文件；打开 XDMA 节点并 `lseek` 到 FPGA 卡端地址；恰好一次 `write/read`；输出请求数、完成数和错误；C2H 成功后独占创建结果文件并落盘，最后释放资源。 |

`h2c` 对应 CPU→FPGA，`c2h` 对应 FPGA→CPU；CPU 内存缓冲地址和 FPGA DDR 地址不能混用。当前内核已有 `xdma` 驱动，C 程序通过 `/dev/xdma0_h2c_0` 和 `/dev/xdma0_c2h_0` 使用它。

## 8. 异常与未完成项

任何 ILA 布防失败、DMA 错误/短传输、数据不一致、队列头变化或 ACK 结果不确定均停止，不自动重试、不清历史、不归还未验证块。保持现场并查看本次 `events/*.jsonl`、ARM `results/<run-id>` 和远程 `captures/<session>` 中的 `.ila/.csv`。

真实 Aurora/主子机收发、外部 I/O、用户中断实际送达、持续运行、性能和故障注入均需另行验证。上行 VIO 固定源验证的是板内 DDR/C2H 与队列协议。
