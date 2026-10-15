# RTDS_test_XDMA_RootPort问题发现与处理台账

- Category: `pcie`
- Source: `E:\PCIE-CPU\docs\RTDS_test_XDMA_RootPort问题发现与处理台账.md`
- SHA-256: `e5a0c9c640aa17341e65b2ad9e8c155dcbea6be047ea9c08f0e9f676092dcce5`
- Extractor: `text`
- Tags: `aurora, engineering, pcie, xdma`
- Duplicate sources:
  - none

# RTDS_test XDMA Root Port 大仿真问题发现与处理台账

## 1. 文档用途与维护规则

本文件汇总本次 XDMA Root Port 大仿真对话中发现的工程、RTL、验证环境、XSim、远端机器和运行流程问题。它是问题追踪入口，不替代搭建记录、运行手册和测试点说明。

后续每次运行按以下规则维护：

1. 新现象先登记为“待定位”，不在证据不足时直接写成 DUT 缺陷。
2. 每项记录现象、证据、影响、根因判断、处理办法、验证状态和日志入口。
3. 修改源码后先标记“已修复，待回归”；只有对应用例真正通过后才标记“已关闭”。
4. Xilinx 模型 warning 只有完成精确分类并进入白名单后才可忽略，不能用模糊正则整体放行。
5. 每个工作日结束时更新“每日记录”和顶部“当前阻塞点”。

状态定义：

- **待定位**：只有现象，尚不能确定根因。
- **已定位**：根因和触发条件已有证据。
- **已修复，待回归**：修改已完成，但尚未通过目标用例。
- **已修复，待专项**：正常验收不覆盖故障注入，仅保留专门的异常路径测试。
- **已关闭**：目标回归通过且证据已归档。
- **设计边界**：属于本轮明确不覆盖或工具固有限制。

## 2. 当前状态摘要

截至 2026-07-24：

- Vivado 2020.2、真实 1ch XDMA Endpoint、官方 Root Port/TPI、轻量 Aurora LocalLink peer BFM 的最小大仿真闭环已经完成。
- 最终运行从 2026-07-23 17:12:04 到 17:48:44，总墙钟 36 分 40 秒；XSim 在 274.094 us 结束。
- Gen3 x2、枚举/BAR、MSI 配置、XDMA user IRQ enable、基础 H2C/C2H、CPU→Aurora、Aurora→CPU、`usr_irq_ack`、read-to-clear、断言和两个 512 B scoreboard 全部通过。
- 最终原句为 `RTDS_ROOTPORT_RESULT ... errors=0`、`RTDS_ROOTPORT_PASS`。精确 warning 白名单更新后，同一组日志复比得到 `RTDS_LOG_COMPARE_PASS`、`unexpected_warnings=0`、`fatal_lines=0`。
- CQ Host-memory sink、FDMA 写侧 wrapper 语义映射、descriptor count 判定和 PowerShell 5.1 日志脚本问题均已关闭。FDMA、adapter 和 `CONV_DMA` 模块本体未修改。
- 当前最小验收无阻塞项；1 KiB、32 KiB、连续多次传输和故障注入属于后续压力/专项回归，不是本轮完成门槛。

## 3. 问题总表

| ID | 问题 | 状态 | 影响范围 | 当前结论 |
|---|---|---|---|---|
| ENV-001 | 工具版本和旧脚本混用 | 已关闭 | 全流程 | 基线固定 Vivado 2020.2，运行脚本显式指定工具目录 |
| ENV-002 | 1ch 工程 FIFO 派生文件缺失 | 已关闭 | 工程/IP 生成 | 用 2020.2 reset/generate 自身 IP，不从 4ch 工程复制 |
| ENV-003 | 官方 RP 依赖与 Endpoint 混入风险 | 已关闭 | harness 层次 | 只提取 RP/TPI/时钟复位，EP 使用真实 RTDS 1ch |
| ENV-004 | Aurora 模型边界不清 | 已关闭 | Aurora 集成 | 使用轻量 LL BFM，不引入 Aurora 64B/66B/GT；RX 不允许 FPGA 反压 |
| XSIM-001 | snapshot 首次生成非常慢 | 设计边界 | xelab | 完整 PCIe/XDMA/GT 加密模型静态展开成本，源码不变可复用 |
| XSIM-002 | 本机 `--mt auto` 曾崩溃 | 已定位 | 小内存本机 xelab | XSim native heap 异常；本机默认 mt off，远端高配机可 auto |
| XSIM-003 | 单个 `xsimk` 不能强制 4 核运行 | 设计边界 | XSim runtime | 2020.2 只公开多线程编译；运行阶段近似单核 |
| XSIM-004 | WDB/debug 增加运行和展开负担 | 已关闭 | 快速回归 | FastMode 的 `--debug off --O3` 已成功生成 snapshot 并运行完整用例 |
| XSIM-005 | `-O 3` 在实际 2020.2 被拒绝 | 已关闭 | xelab 启动 | 实际参数修正为 `--O3`，2026-07-20 已被 xelab 接受 |
| XSIM-006 | 零时间事件风暴判断缺少证据 | 已关闭 | 长时间仿真 | 新运行推进至 892.654 us 并由 testbench `$fatal` 正常结束，未命中 `maxdeltaid` |
| XSIM-007 | FastMode `debug off` 无法执行 Tcl 层级 force | 已关闭 | TESTNAME 选择 | 自定义 `tests.vh` 已在 debug-off snapshot 正确进入 `rtds_minimum` |
| TPI-001 | Windows plusarg 未选择 `rtds_minimum` | 已关闭 | 用例入口 | 用 Tcl 兼容层强制 testname，避免误跑 `dma_test0` |
| TPI-002 | Tcl 反斜杠路径被解释为转义 | 已关闭 | XSim 启动 | 传给 XSim Tcl 的路径统一转正斜杠 |
| TPI-003 | 自定义 BAR read 并行等待污染官方 TPI | 已关闭 | BAR/后续 TLP | 改为官方要求的串行 read + wait，禁止与 `P_READ_DATA_VALID` 竞争 |
| LINK-001 | Gen3 运行编码误判为 3 | 已关闭 | link checker | 该 RP 观测口中值 4 对应 Gen3/8.0 GT/s |
| LINK-002 | RP example 默认 x8，harness 只连接 x2 | 已关闭 | RP/EP 串行互连 | board 显式设置 RP Gen3 x2；官方内部 x2 到固定 x8 物理端口的四条 warning 已精确分类 |
| DMA-001 | descriptor count 高频 PCIe 轮询 | 已关闭 | 仿真性能 | 新运行由本地 M_AXI 唤醒，终检首读即得到 count=1/status=0x6 |
| DMA-002 | 错把官方 `DATA_STORE` 当作 C2H Host RAM | 已关闭 | 基础 C2H/Aurora→CPU | 独立 CQ Host sink 两次均收到 512 B/1 packet，逐字节 scoreboard 通过 |
| DMA-003 | count/status、卡侧 AXI 与 RP CQ 被混为同一证据 | 已关闭 | scoreboard | 最终日志分别证明 XDMA M_AXI、RP CQ Host sink、软件可见 count/status |
| DMA-004 | AXI response error 缺少独立计数 | 已关闭 | H2C/C2H | monitor 统计 BRESP/RRESP，最终 `errors=0` |
| DMA-005 | 把 descriptor count 误当作跨重启单调计数 | 已关闭 | 第二次 C2H | 两次均按 count=1/status=0x6 通过 |
| TIME-001 | 裸延时/timescale 可能造成超时解释不清 | 已关闭 | 全局超时 | 1 ps timebase 自测通过，用例在 274.094 us 正常结束 |
| LOG-001 | CPU→Aurora 后数小时无阶段日志 | 已关闭 | Aurora→CPU/IRQ | 最终日志完整输出注入、IRQ、DMA、Host drain 阶段 |
| LOG-002 | 日志误比较绝对时间和环境噪声 | 已关闭 | 回归判定 | 只比较语义里程碑；拒绝 ERROR/FATAL/MISMATCH/TIMEOUT |
| LOG-003 | xelab 期间监控误读上一轮 `simulate.log` | 已关闭 | 运行状态判断 | 启动时归档并清除固定名称日志，新一轮由工具重新生成 |
| LOG-004 | PowerShell 5.1 在 `param` 默认值阶段取不到 `$PSScriptRoot` | 已关闭 | PASS 后日志门禁 | 路径默认值移到脚本正文初始化；最终复比 `RTDS_LOG_COMPARE_PASS` |
| IRQ-001 | 官方通用流程没有 MSI 里程碑 | 已定位 | 中断用例 | 通用指枚举/BAR 流程；专用 IRQ 用例才配置 MSI/MSI-X 和 user mask |
| IRQ-002 | `usr_irq_req/ack/msi_enable` 语义混淆 | 已关闭 | 中断 checker/文档 | req=应用请求，ack=XDMA 已发送消息，msi_enable=Host 运行时使能镜像 |
| IRQ-003 | 生产设计未消费 `usr_irq_ack/msi_enable` | 已定位，待设计决策 | adapter 中断状态机 | bind monitor 收集证据；未凭推测修改生产 RTL |
| IRQ-004 | INFO read-to-clear 不能证明 Host MSI 闭环 | 已关闭 | 验收标准 | 完整 PASS 还要求 msi_enable、user mask、req、ack；上板再结合 ISR |
| AUR-001 | Aurora→FPGA 被错误假定可反压 | 已关闭 | LL BFM/断言 | 连续 64 拍源不等待 `rx_dst_rdy`；撤 ready 立即报错 |
| AUR-002 | `PCIe.v` 未沿用已验证的 CONV_DMA 写侧交叉映射 | 已关闭 | Aurora→FDMA→IRQ | 最终 Aurora→CPU 512 B、IRQ req/ack 和 C2H 全部通过 |
| BASE-001 | 官方截图被误解为 DMA 成功 | 已关闭 | 基线解释 | 125.13 us 仍在链路训练，完整 link up 约 192.5 us |
| BASE-002 | 官方 `dma_test0` 128 B 被当作 512 B 证据 | 已关闭 | 验收边界 | 官方日志只证明 128 B，RTDS 用例必须独立通过 512 B |
| REMOTE-001 | 重启后 SSH 连接挂起 | 已关闭 | 远端控制 | TCP/指纹正常；受限环境不能访问 ssh-agent，沙箱外 SSH 已恢复密钥登录 |
| REMOTE-002 | 远端没有 PowerShell 7 | 设计边界 | 自动化脚本 | 使用 Windows PowerShell 5.1 和 UTF-8 BOM |
| REMOTE-003 | 后台派生 PowerShell 随 SSH 退出 | 已定位 | 长任务托管 | 当前由长连接 SSH 同步托管，输出写远端日志 |
| REMOTE-004 | 用户暂停前台时需要保留远端仿真 | 已关闭 | 长任务托管 | `CreateProcess(CREATE_BREAKAWAY_FROM_JOB)` 断连重连验证通过 |
| REMOTE-005 | WMI/计划任务脱离启动受权限和 `/TR` 限制 | 已关闭 | 长任务托管 | WMI/普通 Start-Process/计划任务均不采用，统一使用 breakaway launcher |
| REMOTE-006 | 90 分钟 watchdog 未杀净 breakaway XSim | 已修复，待专项 | 超时回收 | 正常回归 36 分 40 秒内结束；强制超时杀进程路径留作专项故障注入 |
| SIM-001 | 远端未安装可运行的第三方模拟器 | 已定位 | 模拟器迁移 | 无 `vsim/vcs/xrun/irun`；当前继续 XSim 2020.2 |
| SIM-002 | 直接升级 Vivado 2024.2 是否更快 | 设计边界 | 基线一致性 | 可能改善实现但无项目级保证，必须复制工程做隔离 A/B，不能替代 2020.2 验收 |
| WARN-001 | 1ch XDMA 加密/通用模型产生大量宽度/越界 warning | 已关闭 | warning 白名单 | 118 条均按精确来源/文本分类，最终 unexpected=0；新增 warning 仍会失败 |

## 4. 重点问题详解

### 4.1 DMA-002：为什么官方 `DATA_STORE` 永远不会收到 C2H

C2H 路径是：

```text
Card BRAM
  → XDMA M_AXI 读握手
  → XDMA 形成 PCIe Memory Write TLP
  → Endpoint 串行发送
  → Root Port 接收
  → RP m_axis_cq_* 输出 Memory Write Request
  → 大仿真 CQ Host-memory sink 按地址保存 payload
```

`pci_exp_usrapp_tx.v` 中的 `DATA_STORE[]` 是 Host 发起 H2C、描述符读取和 BAR Memory Write 时的发包数据源。官方 example 的 C2H compare task 没有实现通用 Host RAM 写入，而是在 `m_axis_cq_tvalid/ready` 上直接抽取 payload。因此旧 testbench 等待 `DATA_STORE[0x800...]` 变化在结构上就不可能成功。

2026-07-20 的决定性证据是目标区每个实际值都等于期望值的逐位反码，例如 `31→CE`、`56→A9`、末字节 `4B→B4`。这些正是 testbench 初始化的 sentinel，证明不是字节序错误，也不是部分写入，而是该数组没有任何 C2H 写者。

修复是在自定义兼容层增加 `pcie_cq_host_memory_monitor.sv`：按官方 256-bit DWORD-aligned CQ 格式识别 SOP、Memory Write 类型、地址、长度、`tkeep` 和 payload，并写入独立 Host sink。官方 RP/TPI 源码不修改。sentinel 仍保留，但现在写在真正有 CQ 写者的 sink 中。

#### 4.1.1 角色和术语，从零开始理解

`Endpoint` 是 FPGA 板卡这一端；本项目使用真实 `PCIe/design_1_wrapper/xdma_0`。`Root Port` 是 CPU/Host 这一端接入 PCIe 总线的根端口；本仿真使用 Xilinx example model。`RP.tx_usrapp.DATA_STORE` 属于仿真 Root Port，不属于 Endpoint。

`H2C` 是 Host-to-Card。XDMA 要从 Host 地址读取描述符或源数据时，由 Endpoint 发出 PCIe Memory Read，RP 返回 Completion with Data。官方 example 从 `DATA_STORE[address]` 取出返回 payload。因此 `DATA_STORE` 对这条路径是“Host 被读取时的数据源”。本用例的 H2C 描述符在 `0x100`，源数据在 `0x400`。

`C2H` 是 Card-to-Host。XDMA 先从卡端 BRAM/AXI 读取数据，再由 Endpoint 发出 PCIe Memory Write，目标是 Host 地址 `0x800`。对 RP 来说，这是 Endpoint 发来的入站请求，所以由 PCIe core 从 CQ 接口输出给 RP 用户逻辑。

`CQ` 是 Xilinx PCIe AXI-Stream 接口名 `Completer Request`，不是软件数据结构中的普通 completion queue。RP 对 Endpoint 发来的 Memory Read/Write 扮演 completer，所以这些请求出现在 CQ：

| 信号 | 本用例中的含义 |
|---|---|
| `m_axis_cq_tvalid` | PCIe core 当前输出的 CQ beat 有效 |
| `m_axis_cq_tready` | RP 用户模型能接受当前 beat |
| `m_axis_cq_tdata` | CQ descriptor、地址和 Memory Write payload |
| `m_axis_cq_tkeep` | 当前 256-bit beat 中哪些 32-bit DWORD 有效 |
| `m_axis_cq_tlast` | 当前 PCIe request 的最后一个 beat |
| `m_axis_cq_tuser` | SOP、byte enable 等旁带信息 |

这里的 `m_axis` 方向以 PCIe core 为参照：core 是 master，向 testbench/RP 用户模型输出。只有 `tvalid && tready` 同时为 1 的拍才算真正传输。

官方 example 不是完整 PC：它没有操作系统、Root Complex 内存映射、DDR 控制器和可读写系统 RAM。官方 `COMPARE_DATA_C2H` task 只在 CQ handshake 时把 payload 暂存到局部 `READ_DATA_C2H[]`，随后直接比较；没有把解析到的地址作为索引写回 `DATA_STORE[]`。所以 `DATA_STORE` 虽然是 byte array，也不能据其名字推断为双向 Host RAM。

`sentinel` 是目标区的哨兵初值。期望字节若为 `0x31`，先填其反码 `0xCE`：仍为 `0xCE` 表示该观测存储没有被写，变成其他值表示有写但内容错，变成 `0x31` 表示正确。旧 testbench 把 sentinel 放进没有 C2H writer 的 `DATA_STORE`，因此永远不变。新环境把 sentinel 放入真正由 CQ monitor 写入的 `HOST_MEMORY`。

`Host-memory sink` 是最小接收模型：识别 CQ Memory Write，解码目标地址、长度和有效字节，再把 payload 写入 `HOST_MEMORY[address]`。`scoreboard` 不负责接收事务，只负责把该实际内存内容与确定性期望模式逐字节比较。二者分开后可以分别证明：卡侧 AXI 读发生、PCIe Memory Write 到达 RP、Host 地址/长度正确、512 B 内容正确。

从验证环境职责看：BFM/driver 负责制造或响应事务，monitor 负责无侵入观察，sink/reference model 负责形成可寻址状态，scoreboard 负责 expected/actual 比较，assertion 负责检查协议和时序约束。

### 4.2 AUR-002：FDMA 接口已验证，错误发生在 wrapper 语义映射

adapter 的接口使用标准语义：`fdma_wvalid` 是源数据有效，`fdma_wready` 是下游接受。历史 `CONV_DMA` 的两个端口名却与实际方向相反：

```verilog
output wire fdma_wvalid; // 实际是 AXI 本拍已接受，语义等价 ready/accept
input  wire fdma_wready; // 实际是上游数据有效，语义等价 valid
```

已验证的 integration TB 明确交叉连接：

```verilog
.fdma_wvalid(fdma_wready),
.fdma_wready(fdma_wvalid),
```

`PCIe.v` 原先按同名直连，导致 adapter valid 与 BD 输出落在同一网、adapter ready 没有得到正确接受信号。LocalLink 64 拍仍可进入 FIFO，但 FDMA 写突发不能完成，因而 `rx_burst_done`、`FPGA_CPU_irq_req`、`usr_irq_req` 都不会出现。

修复只在 `PCIe.v` 使用 `fdma_w_source_valid` 和 `fdma_w_accept` 两个语义网，并按 integration TB 的既有映射连接。FDMA、adapter、`CONV_DMA` 本体不改。后续集成审查规则是：遇到历史接口名与方向不符时，以已通过 integration harness 的方向和模块内赋值为准，禁止仅按同名连接。

### 4.3 DMA-001：为什么寄存器轮询会让 PCIe 仿真极慢

在软件/真实机器上读 descriptor count 很自然，但完整 Root Port RTL 仿真中一次读包含完整事务：

```text
TSK_XDMA_REG_READ
  → RP Memory Read Request TLP
  → PCIe x2 串行传输和 Endpoint 接收
  → BAR/XDMA register decode
  → Completion with Data TLP
  → PCIe 串行返回和 RP TPI 匹配 tag
```

如果 testbench 每几个时钟读一次，就会制造大量并非 DUT 业务负载的 TLP。事件驱动仿真要计算每个串行 lane、LTSSM/GT 模型、TLP 接口和加密 IP 状态，轮询次数会直接转化为墙钟时间。

新 monitor 只观察已存在的真实 XDMA M_AXI 握手：

- H2C：累计 `WVALID && WREADY` 的有效 strobe byte，并等待 `BVALID && BREADY`。
- C2H：累计 `RVALID && RREADY` 的 64-bit beat，并以 `RLAST` 统计 burst。
- BRESP/RRESP 非 OKAY 立即记错。

当本地数据面已走完后，testbench 再经 PCIe 最多读取 4 次 count，并读取一次 status 要求 `0x6`。因此既保留 Host 软件能看到的完成状态，又避免持续轮询成为仿真主负载。

### 4.4 XSIM-006：零时间事件风暴和单纯运行慢的区别

- 零时间事件风暴：模拟时间停在同一个值，组合反馈或反复调度持续增加 delta cycle；HDL 时钟也不能前进。
- 单纯运行慢：模拟时间仍在增加，但完整 PCIe/GT/XDMA 模型每推进 1 us 需要大量 CPU 事件。
- 周期等待过长：模拟时间正常前进，但 testbench 正在等待一个永远不来的同步事件，最终应命中周期超时。

现有旧日志只有“数小时无新打印”，不能区分三者。新保护分别是：

| 保护 | 能识别的问题 |
|---|---|
| `-maxdeltaid 10000` | 同一仿真时刻的 delta-cycle 风暴 |
| 2 ms 时钟周期看门狗 | HDL 时间能前进，但用例没有按逻辑时间结束 |
| 90 分钟墙钟看门狗 | HDL 时间无法推进或模型墙钟成本不可接受 |
| `RTDS_STAGE_*` 日志 | 最后完成的功能阶段 |

## 5. 每日维护记录

### 2026-07-15

- 建立真实 1ch Endpoint + 官方 RP/TPI + 轻量 LL BFM 的独立 harness。
- 本机完成首版编译/展开；确认 snapshot 是 xelab 可执行映像，不是 WDB 截图。
- 本机多线程展开曾出现 `XSIM 43-3294 EXCEPTION_ACCESS_VIOLATION`，低配机默认改为 `-XelabMt off`。

### 2026-07-16

- 诊断旧 snapshot：link、Gen3 x2、BAR、MSI capability、XDMA user mask 通过。
- 发现 Gen3 speed 编码检查错误和 BAR read 的 TPI 竞争，均修正。
- 加入 Windows `TESTNAME` 和 Tcl 路径兼容层。

### 2026-07-17

- 远端长运行通过基础 DMA count/status 和 CPU→Aurora 512 B；C2H Host 比较为全 0，之后 Aurora→CPU 阶段无新里程碑。
- 归档长运行日志并停止对应进程，未操作无关 xsimk。
- 新增 XDMA AXI activity monitor、C2H sentinel/Host drain、稀疏 PCIe 完成确认、时间基准检查、阶段日志、maxdeltaid、墙钟看门狗和 FastMode。
- 发现 2020.2 实际 xelab 参数需用 `--O3`，脚本修正；按用户要求当日未重新验证。

### 2026-07-20

- 本地和远端重启后，确认 22 端口、主机指纹和远端公钥均正常；受限运行环境不能访问 Windows ssh-agent，改用已授权的沙箱外 SSH，密钥登录恢复。
- 远端无残留 Vivado/XSim 任务，脚本 SHA-256 为 `41019080CB8AB2E565F97412508147184EBF094574D57E3BCA4DD5FBCCCC794C`。
- 启动包含全部修复的新一轮：`--debug off --mt auto --O3`。xvlog 已分析 `xdma_axi_activity_monitor` 和 `board`；xelab 正在生成新 snapshot。
- 监控时发现 2026-07-17 的 `simulate.log` 仍保留在固定路径，容易在新 xelab 阶段被误读为本轮结果。已为后续运行加入启动归档：旧日志复制到 `logs/previous_<时间>` 后清除工作副本；当前状态判断同时检查 LastWriteTime。
- 新 snapshot 成功后，为允许用户断开 SSH/暂停前台，新增 `run_xsim_detached.ps1`。它由 WMI 系统进程启动，复用 snapshot，只运行 XSim，并持续写 `detached_status.json`、独立 console 和 error 日志。
- 首个 `debug off` snapshot 在 XSim 启动时报告 `[Simulator 45-10] compiled without trace information`，因为旧 Tcl 兼容层调用 `get_objects/add_force`。已停止空转 XSim；用例选择改到自定义 `tests.vh`，隔离 harness 内将官方 AXI-MM 默认 `dma_test0` 映射到 `rtds_minimum`，不修改 vendor TPI 主文件。
- 为实现断开 SSH 后继续运行，依次验证：WMI `Win32_Process.Create` 被当前 token 拒绝（0x80041003）；普通 `Start-Process` 在断连后被 sshd 回收；Task Scheduler 又受到账号 token/命令长度限制。新增 Win32 `CreateProcessW(CREATE_BREAKAWAY_FROM_JOB)` 启动器，需通过断连重连实测后再关闭本项。
- `CreateProcessW(CREATE_BREAKAWAY_FROM_JOB)` 断连重连实测通过：独立 launcher PID 2600 在 SSH 结束后仍存活，`detached_status.json` 为 running，并已启动 xelab PID 18792。用户可以关闭前台/SSH，后续重新连接只读状态和日志。

### 2026-07-21

- 复核远端已无 Vivado/XSim 残留进程。2026-07-20 新 snapshot 实际从 17:32:48 运行到 19:17:38，在 892.654 us 由 `rtds_minimum` 失败路径正常结束；未发生 delta-cycle 风暴。
- C2H 两次卡侧 AXI 都读取 512 B，但 Host sentinel 完全不变。对照官方 `COMPARE_DATA_C2H` 后确认 `DATA_STORE` 不是 C2H RAM，新增 CQ Host-memory sink。
- Aurora→FPGA 连续 64 拍没有反压，但 IRQ 超时。沿真实端口方向对照已通过 integration TB，定位 `PCIe.v` 对历史误命名 CONV_DMA 写端口按同名误连；按已验证映射修复，未修改 FDMA/adapter/CONV_DMA 本体。
- 第二次 C2H 的 `count_before=1/count_after=1` 被证明不是充分失败条件；本地 AXI 已再次读取 512 B。终检改为计划原定的 count=1/status=0x6。
- 90 分钟 detached wrapper 在 19:02 报失败，但 XSim 子进程继续到 19:17，说明旧 `taskkill /T` 在 breakaway 场景被拒绝。watchdog 改为按本轮进程和唯一日志路径清理。
- 本机 Vivado 2020.2 重新导出 fileset，`PCIe.v`、CQ Host monitor 和 `board.sv` 全量 xvlog/xvhdl 编译返回 0。6 个改动文件与远端 SHA-256 一致，远端 PowerShell 5.1 解析 errors=0。
- 09:22:38 通过 `CREATE_BREAKAWAY_FROM_JOB` 启动新一轮，原句 `BREAKAWAY_PROCESS_PID=13716`；`detached_status.json` 为 `state=running`，Vivado PID 9176 正在重新导出包含 CQ monitor 的 fileset。

### 2026-07-23

- 17:12:04 通过 breakaway launcher 启动最终重建回归，PID 16804；显式把官方 RP 的最大链路参数锁定为 Gen3 x2。
- 17:48:43 XSim 在 274.094 us 正常结束。基础 H2C/C2H、双向 Aurora 512 B、MSI、`usr_irq_req/ack`、read-to-clear、断言和 scoreboard 全部通过，`errors=0`。
- detached 首次仍记为 exit 1，确认并非功能失败：Windows PowerShell 5.1 在 `param` 默认值绑定阶段 `$PSScriptRoot` 为空；路径初始化移到脚本正文后问题关闭。
- board 的四条 x2/x8 告警已消失；相同告警转移到官方 `xilinx_pcie_uscale_rp.v` 内部，根因是参数化 x2 外层连接固定 x8 底层物理端口。按端口名、官方文件和精确行号加入白名单。

### 2026-07-24

- 对 2026-07-23 同一组日志重新执行 `compare_logs.ps1`，输出 `RTDS_LOG_COMPARE_PASS`。
- `summary.json` 为 `passed=true`、全部里程碑 true、118 条 warning 均精确匹配、`unexpected_warnings=0`、`fatal_lines=0`。
- 最终证据已归档到本地 `RTDS_test-1ch/regression/sim_xdma_rootport/logs/final_remote_20260723`，并增加机器可读 `final_acceptance.json`。

## 6. 日志和复现入口

- 当前问题断点：`RTDS_test-1ch/regression/sim_xdma_rootport/logs/NEXT_DIAGNOSTIC_2026-07-17.md`
- 本机新增 HDL 编译检查：`RTDS_test-1ch/regression/sim_xdma_rootport/logs/xvlog_patch_check.log`
- 旧远端长运行归档：远端 `logs/archive_run_20260717_102456`
- 2026-07-20 远端控制台：远端 `logs/remote_fast_console_20260720.log`
- 2026-07-20 远端错误流：远端 `logs/remote_fast_console_20260720.err.log`
- 运行日志：远端 `logs/xvlog.log`、`xvhdl.log`、`xelab.log`、`simulate.log`

远端完整命令：

```powershell
Set-Location C:\project\RTDS\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport_remote_20260717
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\run_xsim.ps1 `
  -SkipAudit -SkipPrepare -FastMode `
  -VivadoBin C:\Xilinx\Vivado\2020.2\bin `
  -XelabMt auto -XelabOptimize 3 `
  -XsimMaxDeltaId 10000 -WallClockTimeoutMinutes 90
```

## 7. 关联文档

- `docs/RTDS_test_XDMA_RootPort大仿真搭建与回归记录.md`
- `docs/RTDS_test_XDMA_RootPort另一台电脑运行与回归步骤.md`
- `docs/RTDS_test_XDMA_RootPort验证环境框架测试点与用例说明.md`
- `RTDS_test-1ch/regression/sim_xdma_rootport/README.md`

## 8. 大仿真核心执行过程

本章按仿真时间线说明一次最小闭环验证了什么。时间为 XSim HDL 仿真时间，不是墙钟；墙钟只反映电脑运行模型的耗时。每个阶段同时保留日志里程碑、协议握手和 scoreboard 三类证据，避免仅凭一个寄存器值判断通过。

### 8.1 复位、链路训练与枚举（0～228.49 us）

仿真开始时 PCIe 参考时钟为 100 MHz，RTDS `i_sys_clk` 为 250 MHz，Aurora LocalLink 用户时钟为 156.25 MHz。PCIe 系统复位保持低电平约 5 us 后释放；Aurora 复位在 LocalLink 时钟稳定 16 拍后释放，并由 BFM 置 `channel_up/lane_up`。

Root Port 和 Endpoint 随后运行 LTSSM，协商到 Gen3 x2。这里的 `LINK_SPEED=4` 是该模型的 Gen3 编码，`LINK_WIDTH=2` 表示两条 lane。完成枚举后，官方 TPI 读取 Vendor/Device ID、Capability 和 BAR，建立用户 BAR、XDMA control BAR 及 AXI-Lite BAR 的地址映射。这个阶段只证明 PCIe 总线能建立并且软件能找到设备，还没有证明 DMA 数据正确。

### 8.2 BAR 初始化与 INFO_EXCH（约 228.49～245.73 us）

TPI 按官方流程完成 BAR 搜索和 XDMA 寄存器初始化，再通过用户 BAR 访问 RTDS `INFO_EXCH`。固定检查项为：`0x00=0x00001001`、`0x04=0x20260506`、`0x08=0x00008000`，并对 `0x24/0x28` 做写入/读回。读写必须串行完成；兼容层不与官方 `P_READ_DATA_VALID` 竞争，以免一个 BAR read 的返回数据被下一次 read 覆盖。

### 8.3 基础 H2C/C2H（约 245.73～261.94 us）

H2C 用主机源区 `0x400` 的 512 B 通过 XDMA 写入卡侧 `0x8000`；C2H 再从卡侧 `0x8000` 读回主机目标区 `0x800`。描述符分别放在 `0x100` 和 `0x300`，完成条件是 descriptor count 为 1、status 为 `0x6`。

本阶段的关键证据分层如下：

1. XDMA 本地 M_AXI 的 AW/W 或 AR/R 握手证明卡侧确实完成了 512 B 数据搬运；
2. RP 的 CQ Host-memory sink 证明 C2H 的 PCIe Memory Write 到达了正确主机地址；
3. Host sink 中的 512 B 逐字节 scoreboard 证明内容正确；
4. 最后少量读取 count/status 只用于软件可见完成状态，不再高频轮询制造额外 TLP。

### 8.4 CPU→Aurora（约 261.94～263.30 us）

先执行 H2C 将 512 B 写到卡侧 `0x8000`，再写入 `INFO_EXCH` 的起始地址和长度，并对 `CPU_WR_DONE` 做 `0→1→0` 边沿操作。LocalLink peer BFM 接收 FPGA 发出的 TX 数据，按 `valid && ready` 采集有效字节并交给 scoreboard。由于本轮采用最小闭环，TX 方向不施加随机背压；仍检查 SOF/EOF、keep/rem 和长度一致性。

该阶段同时检查 `CPU_WR_DONE_resp` 的生命周期和 adapter 断言，确保完成响应不会粘住，也不会在清除后被旧 CDC 电平重新置位。

### 8.5 Aurora→CPU、IRQ 和第二次 C2H（约 263.30～273.99 us）

BFM 向 FPGA RX LocalLink 注入另一组 512 B。Aurora→FPGA 方向不支持 FPGA 侧数据反压，这是 SerDes/官方 Aurora 接口的设计边界；因此 BFM 连续发送，撤掉 ready 会立即触发协议错误，而不是等待发送方暂停。

接收完成后，检查 `FPGA_CPU_irq_req`，并观察 XDMA 侧 `msi_enable`、`usr_irq_req`、`usr_irq_ack`。`req` 是应用请求保持电平，`ack` 是 XDMA 已接受并发出用户中断消息的确认，`msi_enable` 是 Host 配置空间允许消息中断的运行时状态镜像。随后读取 `INFO_EXCH` 的 `0x10` 验证 read-to-clear，并检查 `0x18=0`、`0x1C=512`。C2H 从卡侧 `0x0000` 发送到主机 `0x800`，由 CQ sink 接收并逐字节比较；最后对 `CPU_REC_STATE` 执行 `1→0` 释放并重新武装接收路径。

### 8.6 完成判定（274.094 us）

当所有阶段的断言、AXI response、CQ sink、两路 512 B scoreboard 和 IRQ 生命周期均通过后，testbench 输出：

```text
RTDS_ROOTPORT_RESULT ... errors=0
RTDS_ROOTPORT_PASS
RTDS_LOG_COMPARE_PASS
```

最终日志还必须有 `unexpected_warnings=0`、`fatal_lines=0`。这四项是机器可读的收口证据，单独看到某一个 count/status 或某一条 INFO_EXCH 状态不能代替完整判定。

## 9. Bug 调试时间线

以下记录采用“现象 → 当时的错误判断 → 决定性证据 → 根因 → 修复 → 回归结果”的格式，用于防止以后重复走同一条错误路径。

### 9.1 `DATA_STORE` 被误当作 C2H Host RAM（DMA-002）

- **现象**：C2H 卡侧 AXI 已读出 512 B，但 `DATA_STORE[0x800...]` 的 sentinel 不变。
- **错误判断**：一度认为 PCIe Memory Write 没到达，或需要再增加延时。
- **决定性证据**：对照官方 `COMPARE_DATA_C2H`，RP 只在 `m_axis_cq_*` 上直接抽取入站 payload；`DATA_STORE` 仅作为 Host 发起 H2C/描述符读取的数据源。
- **根因**：官方 RP example 不是完整主机 RAM 模型，没有把 Endpoint 的 Memory Write 写回 `DATA_STORE`。
- **修复**：新增 CQ Host-memory sink，按地址、长度、`tkeep` 写入独立 `HOST_MEMORY`，scoreboard 在该 sink 上比较。
- **回归**：基础 C2H 和 Aurora→CPU 两次均收到 512 B/1 packet，逐字节通过。

### 9.2 CQ Host-memory sink 的引入

- **现象**：延长 sentinel 等待时间仍不能看到目标区变化。
- **证据**：CQ `valid/ready/last` 和 payload 已出现，说明 PCIe 入站请求实际到达 RP。
- **修复原则**：不改 XDMA、不改官方 Root Port TPI；在兼容层增加 Memory Write 解码、地址累加和有效字节写入，并单独统计 `cq_host_write_bytes`、packet 数及协议错误。
- **回归意义**：现在可以分别证明“请求到达”“地址正确”“数据内容正确”，而不是把三者混为 `DATA_STORE` 的一个数组观察。

### 9.3 FDMA 写侧历史误命名端口映射（AUR-002）

- **现象**：Aurora RX 64 拍可进入 FIFO，但 `rx_burst_done`、`FPGA_CPU_irq_req` 和 `usr_irq_req` 不出现。
- **错误判断**：怀疑 FDMA 或 adapter 本体不能接收连续 LocalLink 数据。
- **决定性证据**：已通过的 integration TB 使用 `.fdma_wvalid(fdma_wready)`、`.fdma_wready(fdma_wvalid)` 交叉连接，证明历史端口名与实际 valid/ready 语义相反。
- **修复**：仅在 `PCIe.v` 引入 `fdma_w_source_valid`、`fdma_w_accept` 语义网，沿用已验证交叉映射；不修改 FDMA、adapter、`CONV_DMA` 本体。
- **回归**：Aurora→CPU 512 B、IRQ req/ack、C2H 均通过。

### 9.4 descriptor count 非单调（DMA-005）

- **现象**：第二次 C2H 观察到 `count_before=1/count_after=1`，曾被误判为没有新传输。
- **证据**：本地 AXI 再次完成 512 B 读取，CQ sink 也收到新的 packet；count 是本次 descriptor ring/通道完成值，不保证跨重启或跨事务单调递增。
- **修复**：每个 descriptor 按 count=1、status=0x6、长度和数据 scoreboard 独立判断，不再要求 count 比上一轮更大。
- **回归**：两次 C2H 均通过。

### 9.5 PCIe 高频寄存器轮询造成慢仿真（DMA-001）

- **现象**：前台长时间没有新阶段日志，墙钟远大于预期。
- **错误判断**：怀疑 xsimk 崩溃或零时间事件风暴。
- **根因**：每次 descriptor count 读取都会生成完整 Memory Read/Completion TLP，并经过 x2 串行/加密模型；高频轮询把非业务负载变成主要 CPU 成本。
- **修复**：由本地 M_AXI 活动唤醒 monitor，数据面完成后最多读取 4 次 count/status；保留超时和 error response 检查。
- **回归**：完整最小用例在 274.094 us 正常结束，日志阶段连续推进。

### 9.6 posted write 与 sentinel 判断（DMA-002 相关）

- **现象**：C2H 事务日志已经出现，但立即比较目标区仍可能看到旧 sentinel。
- **根因**：RP 接收 CQ beat、sink 写入 Host memory 和 testbench 比较发生在不同事件队列；posted write 没有 Completion 可供软件等待。
- **修复**：目标区先填反码 sentinel，等待 sink 的末字节到达，再等待 32 个 RP 时钟排空 posted write；若字节仍未变化则失败。该等待只用于同步，不掩盖地址/长度错误。
- **回归**：两个 512 B sink scoreboard 均通过。

### 9.7 MSI、`usr_irq_req/ack` 语义混淆（IRQ-001～004）

- **现象**：官方通用流程没有明显 MSI 里程碑，且生产 RTL 未连接 `usr_irq_ack`。
- **澄清**：通用流程只覆盖枚举/BAR；专用 user-interrupt 用例必须配置 MSI、user mask 并观察 `req/ack`。`usr_irq_req` 是应用保持的请求，`usr_irq_ack` 是 XDMA 接受请求并发送 MSI 消息后的确认，`msi_enable` 是 Host 配置空间允许消息中断的运行时状态。
- **处理**：本轮用 bind monitor 观察三者并验证 INFO read-to-clear；不凭警告推测修改生产 IRQ 状态机。
- **边界**：完整硬件 ISR 行为仍需上板软件验证；本仿真已证明 TPI/MSI 配置、请求保持和 XDMA ack 证据链。

### 9.8 零时间事件风暴误判（XSIM-006）

- **现象**：曾因长时间无打印而认为仿真卡在 delta cycle。
- **区分方法**：零时间风暴会让 HDL 时间停住并触发 `-maxdeltaid`；普通模型慢则 HDL 时间持续增加；同步等待过长则应触发周期 watchdog。
- **证据与修复**：新运行推进到 892.654 us 并由 testbench `$fatal` 正常结束，未命中 `maxdeltaid`；加入阶段日志、2 ms 仿真时间看门狗和 90 分钟墙钟看门狗。

### 9.9 RP 默认 x8 与最终 x2 参数（LINK-002）

- **现象**：官方 Root Port 默认内部物理端口为 x8，而 harness 只连接 x2，出现宽度告警。
- **修复**：board 显式锁定 Gen3 x2；剩余官方内部 x2 到固定 x8 端口告警按文件、行号和精确文本加入白名单。
- **回归**：board 自身四条告警消失，最终 warning 比对 `unexpected_warnings=0`。

### 9.10 PowerShell 5.1、detached/watchdog 与 SSH 断联（LOG-004、REMOTE-003～006）

- **PowerShell 5.1**：`$PSScriptRoot` 在 `param` 默认值绑定阶段为空，导致 PASS 后 wrapper 误记 exit 1。路径初始化移到脚本正文，并复比 `RTDS_LOG_COMPARE_PASS`。
- **detached**：`run_xsim_detached.ps1` 只是仿真工作器，本身不会脱离 SSH 作业对象。普通 `Start-Process` 随 SSH 退出，WMI/计划任务受 token 或命令长度限制；最终由 `launch_breakaway.ps1` 使用 `CreateProcessW(CREATE_BREAKAWAY_FROM_JOB)` 启动该工作器，断联重连实测仍能保留 XSim。远端实际启动命令为：

  ```powershell
  Set-Location C:\project\RTDS\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport_remote_20260717
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\launch_breakaway.ps1 `
    -WorkingDirectory C:\project\RTDS\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport_remote_20260717 `
    -CommandLine 'powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File C:\project\RTDS\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport_remote_20260717\run_xsim_detached.ps1 -VivadoBin C:\Xilinx\Vivado\2020.2\bin -RebuildSnapshot -WaveMode -WallClockTimeoutMinutes 120'
  ```

  只有看到 `BREAKAWAY_PROCESS_PID=...` 才可断开 SSH。远端查看 WDB 时，`open_final_wdb.ps1` 必须显式传 `-VivadoBin C:\Xilinx\Vivado\2020.2\bin`；本机默认路径仍为 `D:\Xilinx_2020_2\Vivado\2020.2\bin`。
- **watchdog**：旧 `taskkill /T` 不能可靠回收 breakaway 子进程；改为按本轮 PID 和唯一日志路径清理。正常回归 36 分 40 秒内结束，90 分钟超时回收保留为专项故障注入。

### 9.11 WaveMode 批处理未创建 WCFG（WAVE-001）

- **现象**：第一轮精选波形运行已生成新 WDB，但在 0 ns 报
  `RTDS_WCFG_SAVE_ERROR: There is no current wave configuration open to save`，
  用例没有开始，detached worker 仍等待 XSim 退出。
- **根因**：`-wdb` 只指定波形数据库文件；XSim 2020.2 的 batch 模式不会像
  GUI 一样自动创建当前 wave configuration。原 `waves.tcl` 为兼容层级差异，
  对 `add_wave` 使用 `catch`，导致“没有 current wave configuration”的前置
  错误直到 `save_wave_config` 才显现。
- **处理**：仅终止本轮路径对应的 `xsim/xsimk` 和 detached PowerShell PID，
  不影响同时运行的 Aurora example；现场归档到
  `logs/failed_wave_wcfg_20260724_105547`。在 `run.tcl` 中先显式执行
  `create_wave_config`，成功后再加载 `waves.tcl` 和保存 WCFG。
- **加速重试**：该失败发生在运行期 Tcl，`board` 的 `debug=typical/O2`
  WaveMode snapshot 已输出 `Built simulation snapshot board`。因此增加显式
  `-ReuseWaveSnapshot`，只允许在 HDL/TB/include/xelab 参数均未改变时跳过
  prepare/compile/elaborate；FastMode snapshot 仍禁止用于 WaveMode。
- **重跑证据**：2026-07-24 10:57 重试输出
  `RTDS_WCFG_SAVED: .../logs/rtds_minimum.wcfg`，WCFG 非空，XSim 随后进入
  0 ns 之后的实际用例运行。最终功能与波形验收仍以本轮完成状态为准。

### 9.12 CQ `tuser` 位切片导致新增 Simtcl warning（WAVE-002）

- **现象**：修复 WCFG 后的 WaveMode 已完整运行到 274.094 us，功能输出
  `RTDS_ROOTPORT_PASS`，WDB 为 24,521,538 B；但日志门禁报告两条新增 warning：
  `Simtcl 6-197` 和 `Simtcl 6-55`，因此 detached 包装状态为 failed。
- **定位**：warning 紧跟在 `/board/RP/m_axis_cq_tuser[7:0]` 和 `[40]`
  的 `log_wave` 后。XSim 2020.2 batch 不能可靠把 packed vector bit-select
  作为独立可记录对象；`get_objects -quiet`/`catch` 只能避免 Tcl 中止，不能
  阻止模拟器写 warning。
- **处理**：完整 `m_axis_cq_tuser` 已在 RP TLP 分组中记录，包含 byte-enable、
  SOP 和包上下文，因此删除重复的完整向量调用及两个位切片；查看 WDB 时在
  Waveform Viewer 内展开完整向量。该 warning 不加入官方模型白名单。
- **证据保留与重跑**：功能通过但日志门禁失败的整轮现场归档到
  `logs/functional_wave_simtcl_warning_20260724_121254`。随后复用同一
  WaveMode snapshot 重跑，启动 PID 为 24124；最终验收仍要求
  `RTDS_LOG_COMPARE_PASS` 和 `unexpected_warnings=0`。

## 10. 最终证据与边界

### 10.1 证据归属

| 证据 | 证明内容 | 归属 | 本轮状态 |
|---|---|---|---|
| `cfg_ltssm_state`、协商速率/宽度、Vendor/Device ID | PCIe Gen3 x2 链路与枚举 | Xilinx RP/真实 XDMA EP + TPI | 通过 |
| BAR read/write、INFO_EXCH 值 | 地址映射和用户寄存器可访问 | TPI + RTDS RTL | 通过 |
| XDMA AXI AW/W、AR/R、BRESP/RRESP | 卡侧数据面真正搬运及 response | 真实 RTDS XDMA | 通过 |
| `m_axis_cq_*`、CQ sink 计数/地址/长度 | Endpoint Memory Write 到达 RP 且落入 Host sink | Xilinx RP + 自定义兼容层 | 通过 |
| 512 B 逐字节 scoreboard | H2C/C2H、CPU↔Aurora 数据内容 | testbench/reference model | 通过 |
| `FPGA_CPU_irq_req`、`usr_irq_req/ack`、`msi_enable`、read-to-clear | 中断请求、XDMA 接受和软件清除生命周期 | RTDS RTL + XDMA monitor + TPI | 通过 |
| LocalLink SOF/EOF、keep/rem、channel/lane up | Aurora LL 边界协议 | 轻量 LL peer BFM + adapter assertions | 通过 |
| `RTDS_ROOTPORT_PASS`、`RTDS_LOG_COMPARE_PASS`、warning/fatal 计数 | 机器可读的最终收口 | 脚本与 testbench | 通过 |

### 10.2 本轮明确不覆盖的边界

1. Aurora 侧使用轻量 LocalLink peer BFM；不覆盖官方 Aurora 64B/66B 编码、GT/SerDes、CDR、极性反转和真实串行链路误码。
2. Aurora→FPGA 方向不支持 FPGA 侧反压，符合底层 SerDes 数据路径约束；本轮不把随机 `ready` 撤销作为合法场景。
3. FDMA、adapter、`CONV_DMA` 已按既有接口验证，未单独重测其全部异常注入；本轮只保留协议、数据和状态断言。
4. CQ Host-memory sink 是仿真兼容层，不等同于真实 CPU/DDR/操作系统内存子系统；硬件 Host 写入排序和 IOMMU 行为不在本模型内。
5. MSI 仿真证明配置、请求保持、XDMA ack 和 read-to-clear 证据链；真正的主机驱动 ISR、CPU 中断路由和上板中断延迟仍需软件/硬件联合验证。
6. 本轮门槛为单次 512 B、Gen3 x2、单通道 H2C/C2H。1 KiB、32 KiB、连续多次传输、随机背压、链路错误和 watchdog 超时回收属于后续压力或专项回归。
7. FastMode 日志可作为功能 PASS 证据；2026-07-16 旧 `logs/rtds_minimum.wdb` 早于 CQ sink、FDMA 映射等关键修复，不能作为最终波形证据。精选信号 WDB/WCFG 必须由最终 WaveMode 回归重新生成，并与本台账记录的 274.094 us 时间窗对应。

### 10.3 最终波形与日志查看入口

最终 WaveMode 运行应归档 `rtds_minimum.wdb`、`rtds_minimum.wcfg`、`simulate.log`、`summary.json` 和 `final_wave_acceptance.json`，并计算 SHA-256。查看时先加载 WDB，再加载 WCFG，按 Reset/Link、RP TLP、DMA、CQ Host、FDMA、Aurora LL、IRQ、Result 分组定位；不要递归加入整个 `HOST_MEMORY` 数组，数据正确性以 scoreboard 和 CQ 事务计数为准。

建议按以下时间窗互相对照波形和日志：

| 时间窗 | 重点信号/日志 |
|---|---|
| 0～228.49 us | 复位、LTSSM、`user_lnk_up`、协商 Gen3 x2 |
| 245.73～261.94 us | BAR/XDMA、基础 H2C/C2H、AXI 与 CQ sink |
| 261.94～263.30 us | CPU→Aurora TX、SOF/EOF、512 B scoreboard |
| 263.30～273.99 us | Aurora→CPU RX、IRQ req/ack、read-to-clear、第二次 C2H |
| 274.094 us | `RTDS_ROOTPORT_PASS`、finish、结果摘要 |

日志比对忽略绝对时间戳、临时路径和许可证信息，只比对上述语义里程碑；任何新增或无法精确归类的 `ERROR/FATAL/MISMATCH/TIMEOUT` 或 warning 都必须使报告失败。

### 10.4 2026-07-24 最终精选波形验收

最终清洁 WaveMode 回归于 2026-07-24 12:12:54（UTC+8）启动，12:35:42
结束，墙钟约 22 分 48 秒，仿真终点为 274.094 us。detached 状态为
`completed`，`exit_code=0`，并同时满足：

```text
RTDS_ROOTPORT_PASS
RTDS_LOG_COMPARE_PASS
errors=0
unexpected_warnings=0
fatal_lines=0
```

本轮共有 7 条 warning（`simulate.log` 6 条、prepare 1 条），均与精确
Xilinx 模型白名单匹配，不存在新增或模糊放行项。最终现场归档目录为
`logs/final_wave_20260724_123542`，核心文件如下：

| 文件 | 大小/用途 | SHA-256 |
|---|---|---|
| `rtds_minimum.wdb` | 24,521,538 B；覆盖至 274.094 us | `2b4814207fafce67f89132bb08512bb4f6d7f3eacefe7eacfd8865c836df2440` |
| `rtds_minimum.wcfg` | 796 B；恢复语义分组 | `65f56e00e8d1babc5b6e71e3105df4a0f628cd115115b78187d9cacf87aeecee` |
| `simulate.log` | 最终仿真与 PASS 里程碑 | `83e3204363ffa2ce52cf6f49648fbf7157124f41b7a3a206ab59ffaa402db403` |
| `summary.json` | 机器可读结果 | `b1272471d299e6d18889b240c643a16b79548123f8045a41114934138bed6090` |

该结果关闭了 WAVE-001（batch 模式未创建 WCFG）与 WAVE-002（CQ `tuser`
位切片造成新增 Simtcl warning）。旧的 2026-07-16 WDB 仍只作为历史现场，
最终功能与波形证据以本节归档为准。

## 11. 2026-07-28 中文语义注释收口

为避免后续只看到信号名却无法判断其所属协议阶段，本轮对后续集成修改的
生产设计和全部自研 Root Port 验证文件补充了中文语义段。重点生产设计为：

- `pcie_fdma_aurora_brg_adapter.v`：十个阶段，覆盖双向数据、CDC、缓冲区
  所有权、IRQ、sticky clear 和 watchdog。
- `PCIe.v`：五个阶段，区分 BD/XDMA、Adapter 和 ILA 的职责。
- `INFO_EXCH.v`：十一个阶段，覆盖 AXI-Lite 五通道、寄存器译码、
  read-to-clear 和 `RD_START` 边沿。

`sim_xdma_rootport` 下 29 个自研 `.sv/.vh/.tcl/.ps1` 文件均已补齐至少一组
“输入、输出、作用、失败定位”。Aurora→FPGA 方向明确按不可反压接口处理：
验证 BFM 不等待 FPGA ready 后再发送，`rx_dst_rdy_n` 下降属于需要失败定位
的容量或协议问题。

Xilinx Root Port/TPI、BD/IP 自动生成 RTL、Xilinx 仿真库和编译/波形产物
没有批量修改，以保持官方来源哈希、重新生成能力和升级可比性。完整文件
列表、阅读顺序和维护规则见
`docs/RTDS_test_XDMA_RootPort中文语义注释覆盖清单.md`。

核验结果：

```text
POWERSHELL_SYNTAX_PASS files=11
TCL_SYNTAX_PASS
COMMENT_COVERAGE_PASS custom_verification_files=29
XVLOG_ANALYZE_PASS exit_code=0
```

HDL 检查使用 Vivado 2020.2、实际 `vlog.prj`、工程 include 路径和
`XILINX_SIMULATOR` 宏，Adapter、`PCIe`、`INFO_EXCH` 及所有自研 TB 均
成功分析。本轮未改变可执行逻辑或仿真选项，因此不重新消耗一轮完整
Root Port 仿真；功能与波形结论继续引用 2026-07-23/24 的最终 PASS。
