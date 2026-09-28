# RTDS 64 KiB Address Editor配置

最终板卡存储窗口为共享的64 KiB AXI地址段：

- `0x0000_0000–0x0000_7FFF`：Aurora→CPU，32 KiB。
- `0x0000_8000–0x0000_FFFF`：CPU→Aurora，32 KiB。
- INFO_EXCH保持 `0x4000_0000–0x4000_0FFF`，寄存器偏移不变。

推荐直接运行：

```powershell
& 'D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat' -mode batch `
  -source 'E:\PCIE-CPU\RTDS_test\regression\configure_rtds_64k_bd.tcl'
```

在 Vivado GUI 中核对或手动操作时：

1. 打开 `design_1.bd`，双击 `blk_mem_gen_0`，保持64-bit数据宽度，将 Write Depth A设为8192；True Dual Port的B端深度随A端传播。
2. 打开 **Address Editor**。
3. 在 `CONV_DMA_0/M_AXI` 下，将 `SEG_axi_bram_ctrl_0_Mem0`设为 Offset `0x0000_0000`、Range `64K`。
4. 在 `xdma_0/M_AXI` 下对同一段设置相同的 Offset和Range。
5. 不修改 `xdma_0/M_AXI_LITE`下 INFO_EXCH的 `0x4000_0000/4K`映射。
6. 执行 **Validate Design**，随后重新 **Generate Output Products** 和 **Create HDL Wrapper**。

工程原先由 Vivado 2020.1生成。使用本机2020.2首次执行脚本时，会先升级被锁定的 XDMA、AXI、Clock Wizard及 System Monitor IP；这是保存BD修改所必需的步骤。
