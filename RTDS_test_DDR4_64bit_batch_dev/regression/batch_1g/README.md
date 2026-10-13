> 历史阶段记录：其中128Byte、2µs跨域定时、TOP不例化IP、未运行仿真的表述已被V2.01替代。当前协议见 `docs/PCIe交互协议_V2.01.md`，验证以本轮实际报告为准。

# 新需求前仿源码与运行准备

**所有用例本轮均未运行。** 新增testbench和interface只属于simulation文件集，不会例化进生产TOP，也不需要新增常驻板上逻辑的测试模块。

| 用例 | XPR文件集 | 范围 |
|---|---|---|
| 1g | sim_batch_1g | 十组LUT、首次合法配置、重复/非法编号、2us量化周期、两拍字节序、首/末拍反压、忙时跳过、链路恢复 |
| ring | sim_batch_ring | 24块回绕、八块积压、读清不释放、ACK/读清竞争、延迟完成、写错误、丢帧与恢复 |
| axi | sim_batch_axi | 实际CONV_DMA+4MiB RAM、AW/W独立停顿、B延迟/错误、末拍保持、高地址不别名、4KiB拆分 |
| rx_fifo | sim_batch_rx_fifo | 128帧FIFO满载、整帧丢弃、排空、短帧及链路中断、恢复后的数据序号 |

`rtds_*_test_if.sv` 集中保存引脚和clocking block；driver与monitor使用显式采样偏移。定向测试以 `$fatal` 结束错误路径，并带全局watchdog。只有真实执行后同时满足激励完成、无残留、检查器无错误，日志中的TEST PASS才有效。源代码中预先写有PASS打印语句不表示已经通过。

先运行顺序：1G / FIFO / 块管理 → AXI/DDR → 原快速adapter集成 → 原真实XDMA Root Port集成。时间加速参数只在验证实例中覆盖，生产250MHz下100ms=25000000拍保持不变。1G测试仍使用真实500拍周期与31.25MHz用户时钟。

## 后续手工运行

固定工具：`D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat`。本目录脚本只交付、不自动执行。

```powershell
# 第一步：刷新本地工程BD（不运行仿真/综合）。
& 'D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat' -mode batch -source '.\scripts\refresh_batch_bd.tcl'

# 第二步：显式选择一个用例。
& 'D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat' -mode batch -source '.\regression\batch_1g\run_later.tcl' -tclargs 1g
```

命令从本地开发工程根目录执行。第二步参数可换为ring、axi、rx_fifo、fast或rootport。fast和rootport分别选择原快速与真实XDMA文件集，使用本地工程及DDR4_SIM_RAM，不调用旧远程启动脚本。暂不运行综合、实现或生成bitstream。

原 `sim_xdma_trythrough` 使用行为Host/FDMA后端，已修改为128Byte和4MiB窗口，增加三轮八块回绕及Byte1提取检查；它不证明真实PCIe事务正确。

原 `sim_xdma_rootport` 保留真实XDMA、官方Root Port/TPI和AXI监视器，修改帧长、新版本/容量、上行地址及仿真窗口。其冒烟范围较窄；批量C2H、长时间软件停顿和并发压力需要后续集成验收。历史TB_TOP依赖旧GT顶层，已从当前活动快速文件集中排除，文件仅保留作参考。

## 联板准备与待运行补充

目前无需新增独立联板测试RTL；先复用软件BAR/DMA、0x30/0x34/0x38及原生域调试状态。未来外层接入Aurora IP后，可按需要增加ILA探针，不让ILA/测试发生器成为业务路径前提。

后续需确认：外部1G封装的REM/字节位置、实际时钟/复位、满速窗口边界、块容量上限、软件读完再ACK、批量DMA跨页及真实Root Port积压排空。主机全局复位与链路复位不能混用；恢复链路后首次配置值应仍保留。
