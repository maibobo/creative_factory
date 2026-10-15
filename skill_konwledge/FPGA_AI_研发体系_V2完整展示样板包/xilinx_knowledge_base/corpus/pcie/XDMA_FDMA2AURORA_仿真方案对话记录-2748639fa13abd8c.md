# XDMA_FDMA2AURORA_仿真方案对话记录

- Category: `pcie`
- Source: `E:\PCIE-CPU\docs\XDMA_FDMA2AURORA_仿真方案对话记录.md`
- SHA-256: `2748639fa13abd8c1408c6e4296c847342c66b4a18ebf19d06bbc82eba6b8d04`
- Extractor: `text`
- Tags: `aurora, engineering, pcie, xdma`
- Duplicate sources:
  - none

# XDMA / FDMA2AURORA 仿真方案对话记录

日期：2026-07-09
范围：仅整理本话题中用户与助手的可见对话内容，不包含系统消息、工具内部日志或隐藏推理过程。

---

## Turn 1

### 用户

fpga工程的xilinx xdmaip 在仿真时如何验证，有木有对应的VIP，能不能用AXI VIP

### 助手要点

- XDMA 仿真可以使用 Vivado 生成的 XDMA example design。
- 完整验证入口通常是 `XDMA example design + Root Port Model`。
- AXI VIP 可以验证 XDMA 后面的 AXI-MM / AXI-Lite 用户侧，但不能替代 PCIe Host/Root Port。
- AXI4-Stream 模式应使用 AXI4-Stream VIP 或 stream BFM。
- 推荐分层：
  - PCIe Host 侧：Root Port Model 或商业 PCIe VIP/BFM。
  - AXI-MM 用户侧：AXI VIP。
  - AXI-ST 用户侧：AXI4-Stream VIP。
  - PCIe 极端协议场景：第三方 PCIe VIP/BFM。
- 结论：AXI VIP 很有用，但不是 XDMA 完整替代验证环境。

---

## Turn 2

### 用户

只有XDMA example design 才有 Root Port Model吗，XDMA 的仿真模型又是什么 这个是我当前的工程，我只想做仿真验证的话，怎么添加模型比较好呢

### 助手要点

- Root Port Model 不属于 XDMA IP 本体，而是 testbench 侧的 Host/Root Complex BFM。
- “XDMA 仿真模型”至少有三层含义：
  1. XDMA IP 自身的功能仿真模型，用于展开和运行 endpoint。
  2. XDMA example design 的 testbench，用于从 PCIe 侧发起测试。
  3. Root Port Model，用于模拟 Host/Root Complex。
- 对当前 RTDS_test 工程，真实结构是：

```text
TOP.v
  -> PCIe.v
     -> pcie_fdma_aurora_brg_adapter.v
     -> design_1_wrapper
        -> XDMA / CONV_DMA / INFO_EXCH / BRAM
```

- 建议不要一上来就接 Root Port Model，因为完整 PCIe/XDMA/BD 大仿真编译复杂、速度慢、定位难。
- 当时建议优先做：
  1. adapter 功能 TB。
  2. PCIe.v mock design_1_wrapper TB。
  3. 最后再做完整 XDMA + Root Port Model。
- AXI VIP 对当前 adapter 的 FDMA 接口不是主角，因为 adapter 面对的是 `fdma_*`，不是标准 AXI4。

---

## Turn 3

### 用户

请分析：原始fdmatx-locallinktx-aurora-locallinkrx-fdmarx  这个环路已经做好了UT+IT仿真验证+上版调试，现在adapter仅仅加了一些控制逻辑（这部分你能给我总结一下什么功能以及必要性吗），所以我认为adapter额外的逻辑靠代码检视可以保证，即使有问题大环路的仿真也能看出来，所以我理解要么都不验，要么就直接上完整 XDMA + Root Port Model 仿真，你中间的；当然，还有个疑问，xilinx的xdma ip当然不会有问题，只是我在simulate SV验证环境下肯定要包他对应的仿真模型吧，只是把通路try通，另外入口模拟软件的激励不知道要怎么给，是不是智能通过Root Port Model

### 助手要点

- 用户判断有相当大一部分是对的。
- 原始数据面大环路已做 UT、IT 和上板后，主要风险不再是 `fdma_aurora_brg_tx/rx` 数据面本身，而是 adapter 的控制面和边界条件。
- adapter 主要不是重做数据桥，而是协议适配层，功能包括：
  - 接收 `RD_START`、`CPU_FPGA_START_ADDR`、`CPU_FPGA_LEN`。
  - 锁存地址和长度。
  - 检查 512B 对齐。
  - 生成 FDMA read 请求。
  - 固定 `fdma_rsize/fdma_wsize=64`。
  - 32-bit 软件地址扩展为 64-bit FDMA 地址。
  - TX 完成反馈 `CPU_WR_DONE_resp`。
  - RX 完成后更新 `FPGA_CPU_START_ADDR/FPGA_CPU_LEN`。
  - 置 `INT_STATE_W/FPGA_CPU_irq_req`。
  - 响应 `CLEAR_INTER_R/INT_STATE_R` 清中断。
  - sticky error 状态。
  - `link_enable` 门控。
- 若只做 happy path，大环路能暴露明显错误，但不一定覆盖所有异常边界。
- 修正建议：
  - 不重做原始 bridge UT/IT。
  - 不写很重的 adapter UVM。
  - 用 adapter 代码检视 + 少量 assert。
  - 直接做完整 XDMA + Root Port Model 系统级 try-through。
- XDMA 仿真模型是 endpoint 内部 IP/BD 仿真表示；Root Port Model 是 testbench 侧 Host/Root Complex BFM。
- 如果坚持从真正 PCIe Host 入口进来，软件激励基本需要通过 Root Port Model / PCIe VIP / 第三方 Root Complex BFM。
- Root Port Model 不会“智能知道软件流程”，需要把软件操作改写为 TPI/BFM task。
- 情况 B 下，软件动作应映射为：
  1. Root Port 对 Host memory 写 payload pattern。
  2. 配置 XDMA H2C descriptor，把 Host 数据搬到 Card payload window。
  3. Root Port 写 INFO_EXCH 寄存器：START_ADDR、LEN、CPU_WR_DONE。
  4. 等待 TX done 或 status。
  5. 通过 loopback/RX BFM 让数据进入 RX。
  6. 等待 IRQ/status。
  7. 配置 XDMA C2H descriptor，把 Card payload window 读回 Host memory。
  8. Host 端 compare。
  9. 清中断。
- 最终一句话：用代码检视/assert 保 adapter 控制面，用 Root Port Model 保系统入口和通路。

---

## Turn 4

### 用户

是情况 B，我就是做到通路 try-through就基本ok，我不需要测非 512B 对齐长度，最多关注压力测试和aurora rx fifo的状态   你说的少量 assert是加设计还是验证文件里          给我设计一个大仿真模型的思路，先给出当前的设计要怎么调整（即验证对象需要再改吗，当前的fdma2ll转换桥已经包含了已补转换，之前的data—CDC就不要了吧）  给我完整的设计和验证方案（2个md文档），并将以上全部对话log保存为md文档

### 当前答复产物

本轮根据上述要求生成 3 个 Markdown 文件：

1. `RTDS_test_XDMA_RP大仿真前设计调整方案.md`
2. `RTDS_test_XDMA_RootPort大仿真验证方案.md`
3. `XDMA_FDMA2AURORA_仿真方案对话记录.md`

核心结论：

```text
- 当前属于情况 B：payload 通过 XDMA H2C/C2H 搬运。
- 第一阶段只做 try-through，不测非 512B 对齐长度。
- 压力测试重点观察 Aurora RX FIFO 状态。
- 少量 assert 推荐放在验证文件里，用 bind 挂到 DUT；不建议直接污染正式 RTL。
- 旧 DATA_CDC 不应再作为大仿真或产品主路径。
- 当前主路径应改成 XDMA/CONV_DMA/INFO_EXCH -> adapter -> 完整 FDMA2AURORA 桥。
- Root Port Model/TPI 负责模拟软件入口，把 H2C/C2H descriptor 和 INFO_EXCH 寄存器操作串起来。
```
