# RTDS ARM Linux 三层代码架构

日期：2026-10-19  
重构分支：`refactor/linux-three-layer-20261019`  
重构前备份：`backup/linux-before-three-layer-20261019`

## 1. 先澄清“驱动”

当前仓库内可直接修改的：

- `arm/rtds_lab.py`
- `arm/rtds_dma.c`
- `arm/rtds_dma`

都不是 Linux XDMA 内核驱动源码。

`rtds_dma.c` 是用户态 helper，通过 `open/lseek/read/write` 调用已经存在的
`/dev/xdma*_h2c_0`、`/dev/xdma*_c2h_0` 字符设备。

真正的内核 XDMA 驱动当前只确认已经绑定和可用；其精确源码、内核 commit、
配置和补丁尚未取得。因此本次重构只调整用户态软件，不声称修改了内核驱动。

## 2. 为什么要拆层

重构前 `rtds_lab.py` 中的 `Hardware` 同时负责：

1. 查找 PCIe BDF；
2. 验证 XDMA 设备节点；
3. 读写 BAR 寄存器；
4. 启动 DMA helper；
5. 限制实验 DMA 地址；
6. 参与 RTDS 队列所有权。

这会造成两个问题：

- “底层搬运机制”和“RTDS 业务规则”耦合，正式应用难复用；
- 后续若把寄存器访问从 `io` 改为 `/dev/xdma0_user + mmap`，或把 helper 改为
  进程内 C API，会牵动上层队列代码。

因此拆成三层。

## 3. 第一层：寄存器访问层

文件：

`arm/rtds_regs.py`

职责：

- 查找指定 Xilinx PCIe 端点；
- 验证驱动绑定为 `xdma`；
- 验证 `xdmaN_user/h2c_0/c2h_0` 属于同一 BDF；
- 检查其他进程是否占用设备；
- BAR0 安全寄存器读取；
- 受限寄存器写入；
- 快照和状态等待。

不负责：

- H2C/C2H DMA；
- RTDS 上行队列；
- 数据比较；
- ACK 决策。

核心对象：

`PcieEndpoint` + `RegisterAccess`

## 4. 第二层：DMA 传输层

文件：

`arm/rtds_dma_transport.py`

职责：

- 选择 H2C/C2H 字符设备；
- 启动一次 `rtds_dma` helper；
- 设置 DMA 超时；
- 解析 helper JSON；
- 检查进程退出码；
- 检查 `completed == requested`；
- DMA 超时/短传输不自动重试。

它故意不知道：

- `0x14` 是 ACK；
- `0x18` 是队头；
- 上行有 8 个环形 slot；
- `0x8000` 是本次实验下行地址。

因此未来正式应用可以复用该层，而不必复制实验协议。

底层 C helper `rtds_dma.c` 本轮保持 DMA 语义不变。

## 5. 第三层：RTDS 协议层

文件：

`arm/rtds_protocol.py`

职责：

- 判断实验 DMA 地址是否合法；
- 下行 H2C/配置的顺序；
- 上行读取 `0x18/0x1C/0x34`；
- C2H 后校验有效数据；
- 校验队头在 DMA 期间未变化；
- 成功后才写 `0x14=1`；
- ACK 后等待 `0x30` 减一；
- 通知读清与块释放分离；
- 短 DMA、超时、数据错误时不 ACK；
- 验证 2/8/2 队列和环形回绕。

核心对象：

`RtdsProtocol`

## 6. rtds_lab.py 现在负责什么

重构后的 `rtds_lab.py` 只做：

- 命令行参数；
- 运行互斥锁；
- 日志/证据；
- Vivado 控制握手；
- 创建三层对象；
- 调用 `RtdsProtocol.run()`。

调用关系：

```text
rtds_lab.py
   |
   +--> PcieEndpoint + RegisterAccess
   |       |
   |       +--> io -> BAR0
   |
   +--> XdmaTransport
   |       |
   |       +--> rtds_dma
   |               |
   |               +--> /dev/xdma*_h2c_0 / c2h_0
   |                       |
   |                       +--> Linux XDMA 内核驱动
   |
   +--> RtdsProtocol
           |
           +--> 规定寄存器 + DMA 的先后顺序和 ACK 所有权
```

## 7. 和正式应用的关系

后续正式业务 main 不应复制整个实验程序，而应复用相同边界：

```text
Business main
   |
   +--> RegisterAccess
   +--> XdmaTransport
   +--> RTDS protocol/service
```

未来可以替换：

- RegisterAccess：从 `io` 改成 mmap；
- XdmaTransport：从 helper 子进程改成进程内 C 函数；

只要接口语义保持一致，RTDS 协议层不用跟着重写。

## 8. 本轮明确不做的事情

为了降低风险，本轮不同时修改：

- `rtds_dma.c` 的一次 DMA 提交语义；
- FPGA RTL；
- 寄存器定义；
- 真实 XDMA 内核驱动；
- 设备启动配置；
- VIO/ILA 协议。

这使本分支主要成为“结构重构”，便于后续把行为优化和结构变化分开评审。

## 9. 保留的安全语义

重构必须继续满足：

- DMA 短返回不补传；
- DMA 超时不重提；
- 数据不一致不 ACK；
- `0x10` 读清不等于释放块；
- `0x14` 不确定时不重写；
- 每个块 DMA 前后检查队头；
- ACK 后必须观察到 `0x30` 减一；
- 同一时刻只允许一个实验进程拥有队列。

对应离线测试已调整到新的三层结构。

## 10. 下一轮可做的优化

在三层结构稳定后，再单独做第二阶段优化更安全：

1. 把 `rtds_dma.c` 的 one-shot 函数抽成可链接 C API，减少每次 DMA 创建进程；
2. 正式应用长期打开 H2C/C2H fd，而不是每次重新 open；
3. 根据现场 XDMA 驱动源码确认对齐、最大传输、缓存同步和并发能力；
4. 将 BAR 访问从外部 `io` 进程替换为经过验证的 mmap/设备接口；
5. 为用户 MSI 增加独立通知层，但仍以 `0x30` 队列数量为数据真值；
6. 增加性能、压力和错误注入测试。

这些属于“行为/性能优化”，不应和本次结构拆分混在同一个验证结论里。
