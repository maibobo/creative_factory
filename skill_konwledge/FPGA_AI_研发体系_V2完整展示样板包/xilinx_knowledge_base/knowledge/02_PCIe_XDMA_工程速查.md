# PCIe/XDMA 工程速查

## 当前基线结论

`RTDS_test-1ch` 的 Vivado 2020.2 大仿真使用真实 1 通道 XDMA Endpoint、官方 Root Port/TPI 和轻量 Aurora LocalLink peer BFM。2026-07-24 记录显示：

- G0 工程审计完成：Gen3 x2、64 bit/250 MHz、MSI enabled、MSI-X disabled 和地址映射已确认。
- G1 构建完成：FastMode 的 xvlog/xvhdl/xelab 成功；warning 按精确来源白名单收口，`unexpected_warnings=0`。
- G2 最小闭环完成：链路、枚举/BAR、基础 H2C/C2H、CPU→Aurora、Aurora→CPU、MSI/user IRQ、read-to-clear、断言和两个 512 B scoreboard 全部通过；最终为 `errors=0`、`RTDS_ROOTPORT_PASS`、`RTDS_LOG_COMPARE_PASS`。
- G3 压力回归和 G4 板卡/软件验证未宣称完成。1 KiB、32 KiB、连续多次、故障注入及真实驱动 ISR 仍属后续范围。

## 验证模型边界

```text
Host 数据/描述符模型
  ↕ 官方 Root Port/TPI
PCIe Gen3 x2 串行链路
  ↕ 真实 RTDS Endpoint / XDMA
AXI-MM / BRAM / CONV_DMA
  ↕ pcie_fdma_aurora_brg_adapter
Aurora LocalLink peer BFM
```

该环境验证真实 XDMA Endpoint 和跨模块数据闭环，但 Aurora 侧只停在 LocalLink 用户边界，不实例化 64B/66B Core、GT、CDR 或信号完整性模型。`usr_irq_ack` 证明 XDMA 已发送 MSI 消息，不证明 Windows/Linux 驱动已经进入 ISR。

## 最小闭环数据路径

| 阶段 | 路径与检查 |
|---|---|
| 链路 | LTSSM 到 L0，协商 Gen3 x2；Vendor ID `0x10EE`、Device ID `0x8032` |
| 基础 H2C | Host `0x400` → card `0x8000`，512 B |
| 基础 C2H | card `0x8000` → Host `0x800`，512 B，CQ Host-memory sink 逐字节检查 |
| CPU→Aurora | H2C 写卡端内存，INFO_EXCH 发布地址/长度，FDMA 读出并经 LL TX 发送 512 B |
| Aurora→CPU | LL BFM 连续注入 64 个 64-bit word，FDMA 写 card `0x0000`，触发 IRQ，再 C2H 到 Host 比对 512 B |

描述符约定：H2C 位于 Host `0x100`，C2H 位于 `0x300`，长度 `0x200`；完成条件是 descriptor count=1 且 status=`0x6`。

## 关键协议规则

1. Aurora→FPGA 输入不可反压。BFM 连续发送时不等待 `rx_dst_rdy`；FPGA ready 拉低即报错。
2. FPGA→Aurora 可被反压，但 LocalLink 的 data/SOF/EOF/rem 必须稳定到握手。
3. 512 B 对应 64 个 64-bit FDMA word；地址必须满足本设计的 512 B 对齐和窗口约束。
4. AXI `BRESP/RRESP` 必须为 OKAY，不能只看 DMA descriptor status。
5. sticky 状态在 clear 前保持；clear 后不能被旧 CDC 电平再次置位。
6. 任一 scoreboard mismatch、协议断言、RX not-ready、AXI response error、超时或 IRQ 里程碑缺失都必须使总用例失败。

## MSI 与 Host 内存的正确语义

- `usr_irq_req`：应用逻辑提出用户中断请求。
- `msi_enable`：Host 已在运行时使能 MSI 的镜像。
- `usr_irq_ack`：XDMA 已把请求转换成 MSI 并发送；不是软件 ISR 完成确认。
- INFO_EXCH 的 read-to-clear 只证明寄存器/RTL 状态清除，不能单独证明 Host 中断闭环。

官方 RP 的 `DATA_STORE[]` 是 H2C 和描述符读取的数据源，不是通用双向 Host RAM。C2H 是 Endpoint 发出的 PCIe Memory Write，必须在 RP 的 CQ 接口上接收。因此当前环境使用独立 CQ Host-memory sink；等待 `DATA_STORE` 被 C2H 改写在结构上不会成功。

## 已关闭问题留下的工程规则

| 问题 | 可复用规则 |
|---|---|
| FDMA 写侧历史端口名与真实 valid/ready 语义相反 | 以端口方向、模块内赋值和已通过 integration TB 为准；禁止只按同名连接 |
| descriptor count 被当成全局单调计数 | 每次 descriptor 重新启动后按本次 count/status 判断 |
| 高频 PCIe 寄存器轮询拖慢仿真 | 用本地 AXI/事件唤醒，PCIe 只做最终可见状态检查 |
| 默认 RP x8、harness 只接 x2 | 在 board/harness 中显式固定 Gen3 x2，不依赖 example 默认值 |
| 日志有 PASS 字样但 warning/错误未收口 | PASS 需要语义里程碑、`errors=0`、fatal/error 扫描和精确 warning 门禁同时成立 |

## 后续验证清单

- 1 KiB、32 KiB、多 descriptor、连续双向、随机反压和 reset-during-traffic。
- 4 KB 边界、非整拍尾包、错误 response、超时和 FIFO overflow 故障注入。
- 最终 WaveMode 证据与通过日志对应；旧 WDB 不能覆盖关键修复后的实现。
- 板卡上完成枚举、带宽、DMA、一致性、缓存/内存屏障、MSI/ISR 和异常恢复验证。

## 主要证据

- `E:\PCIE-CPU\docs\RTDS_test_XDMA_RootPort验证环境框架测试点与用例说明.md`
- `E:\PCIE-CPU\docs\RTDS_test_XDMA_RootPort问题发现与处理台账.md`
- `E:\PCIE-CPU\docs\RTDS_test_XDMA_RootPort大仿真搭建与回归记录.md`
- `E:\PCIE-CPU\docs\rtds_top_fdma_aurora_brg_real_integration.md`
- `R:\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport\README.md`

