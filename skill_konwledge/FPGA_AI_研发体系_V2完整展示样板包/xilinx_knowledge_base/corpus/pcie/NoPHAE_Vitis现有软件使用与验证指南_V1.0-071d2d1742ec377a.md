# NoPHAE_Vitis现有软件使用与验证指南_V1.0

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\NoPHAE_Vitis现有软件使用与验证指南_V1.0.md`
- SHA-256: `071d2d1742ec377a2ec1e040a4df03ebf155573f878efbf525eb424769af6049`
- Extractor: `text`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\docs\NoPHAE_Vitis现有软件使用与验证指南_V1.0.md

# NoPHAE Vitis 现有软件使用与验证指南 V1.0

更新日期：2026-07-31
软件工程：`E:\NVME_PRO\vitis_classic`
原则：使用现有 bitstream、XSA 和 ELF，不重新创建工程，不重新编译 Vitis 软件。源码中文注释不会改变当前 ELF。

## 1. 使用前先看结论

当前软件是 MicroBlaze 裸机 UART 菜单程序。它负责：

- PCIe 和 NVMe 初始化；
- Identify Controller/Namespace；
- I/O Queue 创建和删除；
- NoPHAE 高层 DMA；
- 原生 NVMe 命令；
- 日志页、Feature、IOPS、顺序读写和数据校验；
- 固定地址 `0x90000000` 的 FDMA 控制。

当前已有 XSA/bitstream 中没有 `0x90000000` 外设。也就是说：

- NoPHAE `0x10000000` 相关菜单属于已有硬件基线；
- 菜单 13～17 和 FDMA 相关功能，只有把 V2.3 兼容 RTL 并入实际 Vivado 工程并生成新硬件后才能使用；
- V2.3 RTL 不要求重建 Vitis 软件，寄存器 ABI 就是为当前 ELF 保持兼容；
- 当前没有板卡/JTAG/SSD 连接，本轮只完成了制品静态检查和 XSim 行为验证。

所有写盘测试都必须使用可完全清空的隔离测试 SSD。不要连接保存有项目资料、系统或个人数据的 SSD。

## 2. 当前已有文件

| 文件 | 路径 | SHA256 |
|---|---|---|
| ELF | `E:\NVME_PRO\vitis_classic\nvme\Debug\nvme.elf` | `A75ADA0EF77714EC6C14E4D90028690D47512BC86432EE24591BC4B1D2248BFA` |
| bitstream | `E:\NVME_PRO\vitis_classic\nvme\_ide\bitstream\design_1_wrapper.bit` | `5CD336000563775E97C85C871C0B5C43E62AC3AB0998919DFF3DDE0E9556E0FA` |
| XSA | `E:\NVME_PRO\vitis_classic\wrapper1\hw\design_1_wrapper.xsa` | `C0807F333FB7429BC3733B2D4BD6B2125E3D283133D04DB98FD976104FEAAD5E` |
| Vitis Launch | `E:\NVME_PRO\vitis_classic\nvme\_ide\launch\Debugger_nvme-Default.launch` | 现有 Standalone Debug 配置 |
| 免重建下载脚本 | `E:\NVME_PRO\vitis_classic\run_existing_elf.tcl` | 使用现有 bit/ELF |

运行前静态核验：

```powershell
& E:\NVME_PRO\vitis_classic\verify_existing_artifacts.ps1
```

看到以下结尾才表示文件与本指南一致：

```text
ARTIFACT_VERIFY_PASS: existing ELF/bit/XSA/source contract
```

## 3. 硬件和工具准备

### 3.1 必需硬件

- 对应 XCKU040 板卡；
- 原工程使用的 Digilent JTAG 线缆；
- 独立 UART；
- 只用于破坏性测试的 NVMe SSD；
- 符合板卡电源和 PCIe 参考时钟要求的连接。

历史 Launch 记录中的线缆为：

```text
Digilent JTAG-HS1 210512180081
```

该序列号只是历史配置。更换线缆后应在 Vitis Target Connection 中选择实际线缆，不能照抄旧序列号。

### 3.2 工具

- 原工程 Launch 版本为 Vitis 2024.2；
- `hw_server` 和 XSCT 应来自与该工程兼容的 Vitis 安装；
- 串口参数为 `115200 8N1`，关闭硬件和软件流控；
- 本轮不需要执行 Build Project。

## 4. 启动方法

### 4.1 方法 A：Vitis Classic 已有 Launch

1. 打开现有 `E:\NVME_PRO\vitis_classic` 工作区；
2. 刷新工程，确认 `nvme`、`wrapper1` 和 `nvme_system` 可见；
3. 打开 `Run → Debug Configurations`；
4. 选择 `Debugger_nvme-Default`；
5. 确认：
   - Application 为 `Debug/nvme.elf`；
   - bitstream 为 `_ide/bitstream/design_1_wrapper.bit`；
   - Processor 为 `microblaze_0`；
   - Program FPGA 打开；
   - Reset System 打开；
6. 在 Target Connection 中选择当前实际 JTAG；
7. 不点击 Build，直接 Debug/Run；
8. 程序停在 `main` 时继续运行；
9. 打开 UART，等待版本信息和菜单。

### 4.2 方法 B：XSCT 直接下载已有制品

先启动 `hw_server`，再执行：

```powershell
& '<Vitis 2024.2安装目录>\bin\xsct.bat' `
  E:\NVME_PRO\vitis_classic\run_existing_elf.tcl
```

多线缆环境显式给出线缆名：

```powershell
& '<Vitis 2024.2安装目录>\bin\xsct.bat' `
  E:\NVME_PRO\vitis_classic\run_existing_elf.tcl `
  'Digilent JTAG-HS1 210512180081'
```

该脚本执行：

```text
connect
→ 选择FPGA
→ 下载已有bitstream
→ 载入已有XSA寄存器描述
→ 系统复位
→ 下载已有nvme.elf
→ 运行MicroBlaze
```

它不调用编译器，也不生成新的 ELF。

## 5. 正常启动时应看到什么

`main()` 的实际顺序是：

1. 初始化平台；
2. 关闭数据缓存；
3. 调用 `initial(1)` 启动 PCIe/NVMe；
4. 调用 `identify()`；
5. 从版本寄存器输出 NoPHAE 版本文本；
6. 写 FDMA 默认参数：
   - Burst Length=`0x20000`；
   - Pattern Start=`0`；
   - Memory Size=`0x40000000`；
   - Start LBA=`0`；
   - SLBA Enable=`1`；
7. 进入永久 UART 菜单。

如果 PCIe/NVMe 未完成，`initial()` 和 `identify()` 中的无超时轮询会让程序停住。此时不要反复输入菜单，应先检查：

- PCIe Link；
- SSD 供电和插接；
- NoPHAE 初始化状态；
- UART 是否接对；
- bitstream/ELF 是否为本指南列出的版本。

## 6. 菜单说明

| 菜单 | 功能 | 是否写介质 | 使用建议 |
|---:|---|---|---|
| 1 | Identify Controller/Namespace | 否 | 首个只读检查；会刷新软件记录的容量 |
| 2 | 指定 GiB 的高层 DMA Read/Write | 取决于方向 | `w` 会覆盖 Raw LBA；`r` 也要求地址和队列正确 |
| 3 | 开关 Volatile Write Cache | 不直接写用户数据 | 修改控制器 Feature；完成检查不充分 |
| 4 | PCIe Memory Read/Write | 写分支危险 | 可改 Endpoint BAR0；只给熟悉寄存器的人使用 |
| 5 | Error Information / SMART Log | 否 | 推荐只读检查 |
| 6 | Get Volatile Write Cache Feature | 否 | 结果提示要求查看 CQ |
| 7 | 任意 AXI 地址 Read/Write | 写分支非常危险 | 菜单提示的旧基址不可信，以本指南地址图为准 |
| 8 | PCIe Configuration Read/Write | 写分支非常危险 | 错写可能导致链路或设备失效 |
| 9 | NVM Flush | 不写 Payload | 以全局命令计数变化判断完成 |
| 10 | 从任意地址输出 NUL 结尾文本 | 否 | 地址无效或无 NUL 时可越界读取 |
| 11 | 固定容量梯度顺序测速 | 是 | 大量覆盖写，只能用于空测试盘 |
| 12 | 读取 FDMA 计数器估算带宽 | 否 | 计时寄存器为 0 时会除零 |
| 13 | FDMA/ADC→DDR→NVMe 完整任务 | 是 | 需要 V2.3 硬件和有效 ADC 输入 |
| 14 | 停止 FDMA 任务 | 可能产生尾段 | V2.3 RTL 会做干净停止或返回取消错误 |
| 15 | 设置 FDMA Burst Length | 否 | 保持软件/硬件约定单位 |
| 16 | 设置 Pattern Start | 否 | V2.3 ADC 采集路径不把它当 ADC 数据源 |
| 17 | 设置 FDMA Memory Size | 否 | 兼容保留寄存器 |
| 18 | 命令/DMA/Fetch 数据校验 | 是 | 三个分支均可能覆盖 LBA0 |
| 20 | 指定 CID 的 4 KiB 命令 | 写分支是 | 固定 LBA0；非法方向字符会使 `rw` 未初始化 |
| 21 | Q1D2、Q8D8 IOPS BIST | 是 | 写/读 BIST，默认破坏性 |
| 22 | 逐 GiB 记录速度 | 写分支是 | 输入上限未检查，固定数组只有 4096 项 |
| 23 | 多种 MDTZ 测试矩阵 | 写分支是 | 数据量很大，只能用于专用测试盘 |

菜单 19 未实现。

## 7. 地址图

| 地址 | 含义 | 当前事实 |
|---:|---|---|
| `0x10000000` | NoPHAE AXI4-Lite 控制 | XSA 已存在，4 KiB |
| `0x40600000` | AXI UARTLite | XSA 已存在 |
| `0x80000000`～`0xFFFFFFFF` | MicroBlaze DDR | XSA 已存在，2 GiB |
| `0x90000000` | FDMA/Vitis 兼容寄存器 | 原 ELF 固定访问；当前原 XSA 不存在，V2.3 RTL 已补 |
| `0xC0000000` 起 | V2.3 建议 ADC Segment 区 | 新硬件集成时分配 |

菜单 7 输出中的 `0xA0000000` NoPHAE 基址和 `0x5_00000000` DDR 基址是旧文本，与当前源码/XSA 不一致。

## 8. 最安全的首次上板流程

### 8.1 只读基线

1. 连接专用测试 SSD；
2. 下载现有 bit/ELF；
3. 保存完整 UART 启动日志；
4. 执行菜单 1，记录：
   - NVMe 版本；
   - Controller/Namespace Identify；
   - Namespace 容量；
5. 执行菜单 5、LID 2，记录温度和 SMART；
6. 执行菜单 6、SEL 0，读取当前写缓存 Feature；
7. 用菜单 7 只读：
   - `0x100000DC`：NoPHAE 版本区域；
   - `0x1000001C`：NoPHAE 状态；
8. 不执行任何写盘菜单。

### 8.2 V2.3 硬件是否真正并入

用菜单 7 读取：

```text
0x90000018
```

V2.3 返回：

```text
0x00000100
```

即 256 bit。再读取：

```text
0x9000004C
0x90000060
0x90000064
```

空闲、无错误时应为 0。若读访问无响应、返回总线错误或值不可信，说明当前 bitstream 没有并入 V2.3 FDMA 兼容块，禁止执行菜单 13。

## 9. 安全配置菜单 13

### 9.1 为什么必须先改 LBA

软件上电执行：

```c
Xil_Out32(START_LBA_ADDR, 0x0);
Xil_Out32(SLBA_ENABLE_ADDR, 0x1);
```

因此默认从 LBA0 写入，会破坏分区表、文件系统或已有 Raw 数据。V2.3 RTL 默认保护前 1,048,576 个 512 B LBA，即前 512 MiB；LBA0 START 会返回 `D004`，不会向 NoPHAE 提交。

保护区只避免最前面的误写，不代表后续区域安全。仍必须使用隔离测试 SSD，并根据 SSD 容量计算任务尾地址。

### 9.2 通过菜单 7 设置安全 LBA

以下输入均为十六进制。示例把起点设为 `0x00100000`：

```text
菜单: 7
操作: w
地址: 90000030
数据: 00100000
```

确认 SLBA Enable：

```text
菜单: 7
操作: w
地址: 9000003c
数据: 00000001
```

读取回查：

```text
菜单: 7
操作: r
地址: 90000030

菜单: 7
操作: r
地址: 9000003c
```

### 9.3 选择 ADC 模式

V2.3 扩展寄存器 `0x90000040`：

| 值 | 模式 |
|---:|---|
| `0x1` | 双通道，4 Byte/采样时刻 |
| `0x0` | 单通道 CH0，2 Byte/采样时刻 |
| `0x2` | 单通道 CH1，2 Byte/采样时刻 |

写双通道：

```text
菜单: 7
操作: w
地址: 90000040
数据: 00000001
```

默认复位值已经是双通道。

### 9.4 容量边界计算

软件菜单 13 输入十进制 GiB，并执行：

```text
transfer_bytes = input_GiB << 30
```

512 B LBA 数：

```text
payload_lbas = transfer_bytes / 512
```

还要为 4 KiB Commit 页保留 8 个 LBA：

```text
last_exclusive_lba = start_lba + payload_lbas + 8
```

必须满足：

```text
last_exclusive_lba <= Identify得到的Namespace容量
```

示例：1 GiB 任务、起点 `0x00100000`：

```text
payload_lbas       = 0x00200000
commit_lbas        = 0x00000008
last_exclusive_lba = 0x00300008
```

### 9.5 启动

确认 ADC 数据源有效且 DDR/PCIe/NVMe 已初始化后：

```text
菜单: 13
数据大小: 1
```

软件会：

```text
create_queues(2, 8)
→ 写0x9000001C/20总字节数
→ 写0x90000000=1
→ 等0x90000024=1
→ 等0x90000038=1
→ delete_queues(2)
```

如果 ADC 没有送 `adc_valid`，自动定长采集无法达到目标，菜单会一直等待本地完成。

## 10. 任务完成后必须检查

不能只看菜单返回。使用菜单 7 读取：

| 地址 | 正常值/判断 |
|---:|---|
| `0x90000024` | 1，本地采集完成 |
| `0x90000038` | 1，Payload/Flush/Commit/Flush 全部完成 |
| `0x9000004C` | 低 8 bit 正常终态通常为 `0x0E` |
| `0x90000050/54` | 已接受采样时刻数 |
| `0x90000058/5C` | 丢样数，应为 0 |
| `0x90000060` | FDMA 错误，应为 0 |
| `0x90000064` | NoPHAE Backend 错误，应为 0 |

样本数期望：

```text
双通道 accepted_sample_times = transfer_bytes / 4
单通道 accepted_sample_times = transfer_bytes / 2
```

只要 `0x60` 或 `0x64` 非 0，就不能把两个 Done 解释为成功。启动参数被拒绝时，硬件也会置 Done，目的是让旧软件的无超时轮询退出。

## 11. 停止任务

菜单 14 写 `0x90000000=0`。

V2.3 行为：

- 已经采集时：停止接收新样本，发送尾段 EOC，完成已接收数据的 DDR/NVMe/Commit/Flush；
- 尚未真正开始采集时：返回取消终态 `D006`，两个 Done 同时置位；
- 不会把未提交的数据静默当作正常完整 Capture。

停止后读取 `0x90000060`。`D006` 表示任务在 Packer 启动前被取消，不是 SSD 写入成功。

## 12. 错误码

### 12.1 `0x90000060`

| 低 16 bit | 含义 | 处理 |
|---:|---|---|
| `D001` | Active 期间再次 START | 等当前任务结束 |
| `D002` | 总字节数为 0 | 重新设置 Size |
| `D003` | Size 不符合通道样本粒度 | 双通道按 4 Byte、单通道按 2 Byte 对齐 |
| `D004` | LBA 落入保护区 | 选择安全 LBA，并重新核算容量 |
| `D005` | Pipeline 已 Fatal | 系统复位，先查根因 |
| `D006` | 开始采集前被取消 | 属于取消结果 |
| `D100` | Pipeline Fatal | 查看状态、DDR、Link、ECQE 和 Backend |

### 12.2 `0x90000064`

| 低 16 bit | 含义 |
|---:|---|
| `E001` | Opcode 非法 |
| `E002` | DMA 长度非法 |
| `E003` | DDR 地址或窗口非法 |
| `E004` | SLBA 超出 32 bit |
| `E005` | NoPHAE AXI4-Lite 错误响应 |
| `E006` | NoPHAE AXI4-Lite 单事务超时 |
| `E007` | 整笔命令超时 |
| `E008` | 命令在途时 Backend 被禁止 |

出现 Fatal 后不要自动重试同一 Buffer。保存 UART、ILA 和寄存器快照，再按供应商定义的复位/重新下载流程恢复。

## 13. 软件源码中的已知风险

这些问题已在源码行尾注释中标出，但本轮没有修改功能：

1. 多处硬件轮询没有 Timeout；
2. 菜单 7 打印的 NoPHAE/DDR 基址是旧值；
3. 菜单 20 输入非法方向后仍可能使用未初始化的 `rw`；
4. 多数速度和数据测试默认从 LBA0 开始；
5. 容量回卷判断晚一拍，Namespace 边界附近可能越界；
6. `full_transfer_data()` 的速度数组只有 4096 项，Size 过大会越界，Size=0 会除零；
7. `test_data_cmd()` 文本说 16 MB，实际只校验 8 KiB；
8. `test_data_dma()` 实际覆盖 256 MiB；
9. Fetch 校验不处理不足 4 MiB 的尾部；
10. `start_transfer()` 不先清残留 Done，也没有错误/Timeout 分支；
11. `cmd()` 提交后不等待 Ready 或匹配 Completion；
12. `cmd_alloc_cid()` 创建两条队列但原路径只删除一条；
13. `test_seq()` 的长度单位是 512 B LBA 数，不是 Byte；
14. Trim 描述符使用 `0x10000000` 控制空间，地址明显可疑；
15. Identify 假设 512 B LBA 和 4 KiB MPS；
16. Capability 链遍历没有空指针、环路和最大次数保护；
17. Flush 只看全局命令计数变化，没有匹配该命令 CQE；
18. `txt_rd()` 一直读取到 NUL，没有最大长度；
19. 部分 `scanf` 格式与变量类型不匹配，已有构建警告；
20. 头文件保留旧式非原型声明。

在修复这些软件功能前，不应把该程序当作无人值守生产工具。

## 14. 没有板卡时怎样验证

### 14.1 Vitis 制品静态验证

```powershell
& E:\NVME_PRO\vitis_classic\verify_existing_artifacts.ps1
```

验证：

- ELF/bit/XSA 哈希；
- ELF32 MicroBlaze 类型；
- XSA 中 NoPHAE、DDR、UART 地址；
- XSA 中确实没有 `0x90000000`；
- 四个核心源码的 token 等价、注释覆盖率和分支覆盖。

### 14.2 RTL/XSim 验证

```powershell
Set-Location E:\NVME_PRO\nvme_adc_axi_pipeline
& .\scripts\run_vivado_regression.ps1
```

五项回归全部出现 `TEST_PASS` 后，查看：

```text
E:\NVME_PRO\nvme_adc_axi_pipeline\build\regression\summary.json
```

2026-07-31 的本轮结果为 `5 PASS / 0 FAIL / FirstFatal=null`；五项日志更新时间
为 11:55～12:01，均由 Vivado 2020.2 重新编译和运行，且未执行综合。

其中 `tb_nvme_adc_vitis_compat` 是最接近当前软件使用方式的一项：

```text
写0x90000000兼容寄存器
→ 自动采16个双通道样本
→ DDR写入
→ NoPHAE Payload DMA
→ Flush
→ Commit DMA
→ Flush
→ 软件Done/Status
```

它证明 RTL 和软件 ABI 的行为一致，不证明真实 SSD 已写入。

## 15. 现场证据记录模板

每次上板至少记录：

```text
日期/操作者：
板卡与序列号：
JTAG与序列号：
SSD厂商/型号/容量/固件：
Vitis/Vivado版本：
bit SHA256：
ELF SHA256：
XSA SHA256：
UART启动日志：
PCIe/NVMe初始化结果：
Identify容量：
SMART温度：
起始LBA：
传输字节数：
通道模式：
accepted/dropped：
FDMA status/error：
Backend status：
Write/Flush/Commit/Flush结果：
读回CRC或逐字节比较：
最长停顿/FIFO最高水位：
异常与恢复过程：
结论等级：
```

结论等级必须区分：

| 等级 | 可写结论 |
|---|---|
| 静态 | 制品、源码和 XSA 契约核对通过 |
| XSim | RTL/软件 ABI 行为模型通过 |
| 板级基础 | bit/ELF 可下载，UART、PCIe/NVMe 初始化通过 |
| 数据闭环 | DDR→SSD→DDR 回读一致 |
| ADC 闭环 | ADC→DDR→SSD→DDR 数据一致和长稳通过 |

没有达到相应等级时，不使用“完整通路已跑通”的表述。
