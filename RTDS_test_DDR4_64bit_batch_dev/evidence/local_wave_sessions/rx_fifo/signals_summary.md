# rx_fifo：10G 接收跨时钟 FIFO

接收数据/有效/帧标记、用户域与存储域时钟复位、FIFO 写读使能/满空/忙、frame 握手、源域丢失计数及目的域同步计数；用于检查按序透传和满时丢失。

当前本机重跑日志：798 个 WCFG 对象，790 个 VCD 声明；结束时间 790000 × 1ps。

```text
```

## 核心层信号与变化概要

以下逐项列出测试顶层、接口与 DUT 第一层信号。深层 CDC/XPM、clocking block 别名和存储对象见 signals.csv / signals.txt；WCFG 同时包含完整层次。变化次数不包含初值，不等于成功握手次数；已知值范围按无符号二进制解释，X/Z 次数包含初始化阶段，不单独判错。时间单位见上文。

| 信号全名 | 位宽 | 变化次数 | 首次变化 | 最后变化 | 已知最小值 | 已知最大值 |
|---|---:|---:|---:|---:|---:|---:|

## 仿真源码文件列表（编译顺序）

- [xpm_cdc.sv](D:/Xilinx_2020_2/Vivado/2020.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv)
- [xpm_fifo.sv](D:/Xilinx_2020_2/Vivado/2020.2/data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv)
- [xpm_memory.sv](D:/Xilinx_2020_2/Vivado/2020.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv)
