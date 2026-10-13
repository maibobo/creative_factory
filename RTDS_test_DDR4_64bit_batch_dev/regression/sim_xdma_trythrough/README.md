# PCIe–FDMA–Aurora快速回归

该回归使用与Root Port TPI相同的 BAR/H2C/C2H任务接口，行为后端模拟64 KiB card memory，LocalLink BFM模拟Aurora对端。它不替代真实XDMA和GT模型，但覆盖adapter与FDMA桥的完整功能契约。

基础地址配置：

```powershell
& 'E:\PCIE-CPU\RTDS_test\regression\sim_xdma_trythrough\run_xsim.ps1'
```

非零高32位地址配置：

```powershell
& 'E:\PCIE-CPU\RTDS_test\regression\sim_xdma_trythrough\run_xsim.ps1' -NonzeroCardHi
```

通过条件包括：512 B、1 KiB和32 KiB TX；RX中断、read-clear与CPU_REC所有权；64帧环形回绕；随机FDMA/LocalLink背压；RX预期溢出及链路恢复；FDMA size、地址窗口、4 KiB边界和stall稳定性断言。
