# tx：16Byte 下行与异步 FIFO

FDMA 地址/请求/数据握手、批量上限、FIFO 水位和满空保护、读/发状态机、10G 数据与 SOF/EOF/REM/ready；用于区分预取、反压保持、补读和排空。

当前本机重跑日志：790 个 WCFG 对象，783 个 VCD 声明；结束时间 28905600 × 1ps。

```text
TX CASE PASS frames=1 peak=2
TX CASE PASS frames=300 peak=504
```

## 核心层信号与变化概要

以下逐项列出测试顶层、接口与 DUT 第一层信号。深层 CDC/XPM、clocking block 别名和存储对象见 signals.csv / signals.txt；WCFG 同时包含完整层次。变化次数不包含初值，不等于成功握手次数；已知值范围按无符号二进制解释，X/Z 次数包含初始化阶段，不单独判错。时间单位见上文。

| 信号全名 | 位宽 | 变化次数 | 首次变化 | 最后变化 | 已知最小值 | 已知最大值 |
|---|---:|---:|---:|---:|---:|---:|

## 仿真源码文件列表（编译顺序）

- [xpm_cdc.sv](D:/Xilinx_2020_2/Vivado/2020.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv)
- [xpm_fifo.sv](D:/Xilinx_2020_2/Vivado/2020.2/data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv)
- [xpm_memory.sv](D:/Xilinx_2020_2/Vivado/2020.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv)
