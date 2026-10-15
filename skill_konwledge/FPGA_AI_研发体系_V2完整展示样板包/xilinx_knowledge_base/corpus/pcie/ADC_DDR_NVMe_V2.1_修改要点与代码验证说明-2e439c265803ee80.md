# ADC_DDR_NVMe_V2.1_修改要点与代码验证说明

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\ADC_DDR_NVMe_V2.1_修改要点与代码验证说明.md`
- SHA-256: `2e439c265803ee80b14011d8fb50e14272d3d8a36dc3b05fd1b9e3d10fd743ab`
- Extractor: `text`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\docs\ADC_DDR_NVMe_V2.1_修改要点与代码验证说明.md

# ADC–DDR–NVMe V2.1修改要点与代码验证说明

更新日期：2026-07-28
工作区：`E:\NVME_PRO\nvme_adc_axi_pipeline`
自研工具基线：Vivado 2020.2
供应商当前工程：Vivado 2024.2，尚未交付

## 1. 本文件解决什么问题

V2.0已经完成ADC单/双通道、ADC域256 bit打包、263 bit CDC、DDR分段写入、
通用NVMe请求和异常路径回归。供应商补充回复到达后，最容易出现的错误是：

- 把供应商MIG截图当成NVMe IP M_AXI端口表；
- 为了适配512 bit截图重写已经验证的256 bit Writer；
- 把512 B最小单位误解成所有项目Buffer都应改为512 B；
- 把`0x400 + 4 KiB`示例当成一个合法的单AXI Burst；
- 认为供应商内部16个队列意味着项目层也应立即实现多请求并发；
- 把“重新下载程序”写成MicroBlaze能够自动恢复；
- 用Vivado 2024.2覆盖当前2020.2基线。

V2.1的主要工作不是增加新数据面，而是把“确认事实、歧义和未知”分开，
并为后续真实MIG和供应商IP接入设置可验证的门槛。

## 2. 本轮修改总览

| 类别 | 修改内容 | 是否改变正常RTL功能 |
|---|---|:---:|
| 设计文档 | 新增V2.1设计方案，区分CONFIRMED/AMBIGUOUS/UNKNOWN | 否 |
| 验证文档 | 新增V1.1供应商现场验证说明 | 否 |
| 接口契约 | 重写`vendor_ip_contract.md`为三态矩阵 | 否 |
| 板级说明 | 补充2020.2/2024.2隔离、256→512 bit和地址图门槛 | 否 |
| 现场清单 | 增加文件权限、Pattern闭环、长稳和恢复记录 | 否 |
| 系统TB | 增加单AXI AW Burst不得跨4 KiB边界断言 | 只增加验证 |
| 文档脚本 | 新增V2.1 DOCX生成器和结构检查器 | 否 |
| Vivado 2024.2 | 不创建脚本、不运行 | 不适用 |

正常数据面RTL没有修改。V2.0的行为回归结果继续作为V2.1的代码基线。

## 3. 为什么保持现有数据面

### 3.1 ADC数据率和打包宽度

双通道参数：

```text
2通道 × 250 MSPS × 16 bit = 1 GB/s
```

V2.0在ADC时钟域每8个双通道采样时刻形成一个256 bit字：

```text
8 × {CH1[15:0], CH0[15:0]} = 256 bit
平均输出频率 = 250 MHz / 8 = 31.25 MHz
```

单通道每16个16 bit样本形成一个256 bit字：

```text
16 × CHx[15:0] = 256 bit
平均输出频率 = 250 MHz / 16 = 15.625 MHz
```

ADC域先扩宽后跨时钟，避免了“32 bit在125 MHz系统域只有500 MB/s”的历史
吞吐错误。

### 3.2 为什么不把Writer改成512 bit

供应商补充回复截图显示MIG为512 bit，但没有证明NVMe IP M_AXI端口也是512 bit。
当前256 bit Writer在125 MHz下理论载荷为：

```text
256 bit × 125 MHz = 4 GB/s
```

它已高于双通道1 GB/s输入。当前Writer的尾段补零、WSTRB、CRC、Burst和
Segment边界都已回归。位宽转换应优先放在SmartConnect或集成Wrapper，而不是
重新修改ADC打包和Writer。

## 4. 设计代码逐模块思路

### 4.1 `rtl/adc_channel_packer.sv`

职责：

- 在`capture_start && capture_ready`时锁存单双通道模式和Capture ID；
- 将12 bit ADC码按配置符号扩展或零扩展到16 bit；
- 双通道按`{CH1[15:0], CH0[15:0]}`组织；
- 单通道紧凑保存被选中的16 bit样本；
- 在ADC时钟域累积为256 bit；
- `capture_stop`时输出不足256 bit的尾字、`valid_bytes`和EOC；
- 下游短暂背压时保持完整输出字，不覆盖pending数据；
- 真实ADC不能被反压，缓存耗尽时只能记录overflow和丢样。

V2.1动作：保持不变。

保持的原因：供应商变化发生在DDR/NVMe集成边界，与ADC样本格式和打包节奏
无关。修改本模块会重新打开字节序、尾字、配置锁存和长采样本连续性风险。

### 4.2 `rtl/axis_async_fifo.sv`

职责：

```text
输入/输出宽度 = 263 bit
data           = 256 bit
valid_bytes    = 6 bit
EOC            = 1 bit
默认深度       = 1024
```

FIFO是Xilinx XPM异步FIFO例化，不是手写Gray指针FIFO，也不是C语言参数宏。
`ADC_FIFO_AW=10`表示深度为`2^10=1024`项。双通道约缓存32.8 µs，单通道约
65.5 µs。

V2.1动作：保持不变。

FIFO只解决CDC和DDR微秒级短停顿。SSD毫秒级停顿由DDR Segment承担，不能通过
无限增加BRAM FIFO解决。

### 4.3 `rtl/adc_ddr_segment_writer.sv`

职责：

- 从263 bit FIFO接收256 bit数据字和真实有效字节数；
- 申请一个FREE Segment后立即进入FILLING；
- 将真实Payload写入DDR；
- 对不足256 bit的尾字使用WSTRB或补零语义；
- 将NVMe DMA区域补齐到项目当前4 KiB边界；
- CRC32C只覆盖真实Payload，不覆盖补零；
- 每条AXI Burst使用固定beat数量；
- 收到最后一个B响应后才把Segment标记为READY；
- BRESP错误时保留Segment并上报ERROR_HOLD。

当前关键参数：

```text
AXI_DATA_WIDTH = 256 bit
BURST_BEATS    = 16
Burst字节数    = 256/8 × 16 = 512 Byte
```

V2.1动作：保持不变。

集成时若MIG为512 bit，由SmartConnect在该Master支路执行256→512 bit转换。
不能把供应商MIG截图直接写成本模块默认参数。

### 4.4 `rtl/segment_buffer_manager.sv`

职责：

```text
FREE
  → Writer获得分配
FILLING
  → DDR最后B响应成功
READY
  → 大NVMe请求被接受
INFLIGHT
  → 匹配且成功的整笔Completion
FREE

任一错误 → ERROR_HOLD
```

所有权规则：

- Segment分配给Writer时立即离开FREE；
- INFLIGHT完成前ADC不得覆盖；
- ERROR_HOLD不得自行释放；
- Tag使用`{generation, segment_id}`，避免迟到Completion释放新一代数据。

V2.1动作：保持不变。

供应商内部16个Queue和1024深度不能替代项目的DDR所有权管理。内部Queue只管理
NVMe命令，Segment Manager管理ADC生产者与SSD消费者对同一DDR区域的生命周期。

### 4.5 `rtl/nvme_request_scheduler.sv`

职责：

- 从READY Segment形成抽象WRITE请求；
- 项目层只允许一个大请求在途；
- 维护请求地址、长度、SLBA和项目Tag；
- Payload排空后执行Flush #1；
- 写Commit页；
- 执行Flush #2；
- 只有正常完成才释放Segment和结束Capture；
- Timeout、Completion错误、Tag错误、Link Down、ECQE和Flush失败进入fatal。

V2.1动作：正常逻辑保持不变。

供应商已经确认上层一次一个大DMA任务，内部按MDTS拆SQE并使用多Queue。因此
本模块不实现CID、PRP、SQ Doorbell或应用层多Outstanding。

待确认的关键语义：

> 供应商上层大任务Completion是否只在该任务拆出的全部内部SQE完成后返回。

在该语义确认前，真实Adapter不能把部分完成转换成项目Completion。

### 4.6 `rtl/nvme_mailbox_backend.sv`

职责：

- 将PL的抽象请求交给MicroBlaze控制面；
- MicroBlaze调用供应商Read/Write/Flush API；
- 将供应商完成状态返回PL；
- MicroBlaze只处理描述符，不复制1 GB/s ADC Payload。

V2.1约束：

- 不假定供应商API会原样返回项目`user_tag`；
- Mailbox软件需保存“当前项目Tag ↔ 当前供应商大任务”的本地上下文；
- 真实API未提供前不编写地址Absolute/Offset Adapter；
- 不写“MicroBlaze一定能够自动重新初始化恢复”。

### 4.7 `rtl/nvme_adc_pipeline_top.sv`

职责：

- 连接ADC时钟域、XPM FIFO、DDR Writer、Segment Manager和NVMe Scheduler；
- 暴露256 bit AXI写Master；
- 暴露通用NVMe request/completion；
- 汇总Capture、FIFO、DDR和NVMe诊断状态。

V2.1动作：保持不变。

未来真实板级Wrapper位于本模块之外：

```text
nvme_adc_pipeline_top
  256 bit ADC Writer M_AXI
        ↓
SmartConnect/Width Converter
        ↓
MIG 512 bit S_AXI
        ↑
供应商NVMe DDR M_AXI
```

这样可以使自研数据面与供应商工程、MIG版本和Block Design解耦。

## 5. V2.1没有实现的代码

### 5.1 没有实现供应商地址Adapter

未来需要的逻辑边界是：

```text
project_ddr_addr[63:0]
→ Payload/Readback窗口检查
→ 高位和加法溢出检查
→ Absolute或Offset换算
→ vendor_address
```

目前不知道：

- API传绝对地址还是Offset；
- DDR Offset参数位置；
- 供应商地址字段位宽；
- SQ/CQ/PRP/Context保留区；
- 当前32 bit MIG地址和此前2 TB答复的关系。

因此现在写Adapter只能是猜测，V2.1明确禁止。

### 5.2 没有实现应用层多Outstanding

供应商上层一次只能提交一个大任务，内部已经可以使用16个Queue和按MDTS拆分。
项目层实现多Outstanding不会提升已确认接口能力，却会引入：

- 多Tag分配；
- 乱序聚合Completion；
- 每请求独立Timeout；
- 错误隔离和重试；
- Segment快速复用与迟到完成。

当前不做。

### 5.3 没有实现自动恢复

供应商只回复“重新下载程序”，尚不清楚是bitstream还是MicroBlaze ELF。
Timeout不等于SSD已经停止读取DDR，直接释放或重试可能造成旧命令继续访问已
被ADC覆盖的Buffer。

当前保守策略：

```text
fatal_error
→ 禁止新Capture
→ 禁止新NVMe请求
→ 保留INFLIGHT/ERROR_HOLD
→ 人工恢复
```

## 6. 验证代码思路

### 6.1 `sim/tb_adc_channel_packer.sv`

验证对象：ADC时钟域格式化和弹性输出。

主要用例：

- 双通道、单CH0、单CH1；
- 0、1、7、8、9、15、16、17个采样时刻；
- 10 µs、50 µs、100 µs、1 ms；
- `0x000、0x7FF、0x800、0xFFF`符号边界；
- 输出ready随机短暂停顿；
- Capture内修改配置；
- EOC、`valid_bytes`和尾部补零。

检查方法：

- 测试平台建立逐字节参考数组；
- 每次输出握手后按字节比较；
- `valid && !ready`时检查Payload稳定；
- 长采检查输入样本数、输出字节数和丢样计数。

V2.1未修改此测试，因为供应商答疑不影响ADC数据格式。

### 6.2 `sim/tb_nvme_adc_pipeline.sv`

验证对象：ADC→CDC→DDR Stub→Segment→NVMe Stub的系统骨架。

配置：

```text
ADC时钟     = 250 MHz
系统时钟    = 125 MHz
Segment     = 4 × 4 KiB
AXI数据宽度 = 256 bit
Burst       = 16 beat = 512 Byte
```

系统测试检查：

- 三种采集模式的DDR逐字节内容；
- ADC无丢样；
- 随机AWREADY/WREADY和BVALID延迟；
- Segment状态迁移；
- Payload Write、Flush、Commit Write、Flush；
- NVMe请求地址和长度4 KiB对齐；
- AW/W/NVMe请求在stall时字段稳定。

V2.1新增断言：

```systemverilog
if (ddr_awvalid && ddr_awready &&
    ({1'b0, ddr_awaddr[11:0]} +
     ((ddr_awlen + 1) << ddr_awsize) > 13'd4096))
    $fatal(...);
```

断言放在`AWVALID && AWREADY`的原因：

1. 此时AW事务真正被从设备接受；
2. `AWADDR`、`AWLEN`和`AWSIZE`构成完整Burst描述；
3. 低12 bit表示Burst起点在当前4 KiB页内的偏移；
4. `AWLEN+1`是实际beat数，因为AXI的AWLEN为0-based；
5. `1 << AWSIZE`是每beat字节数；
6. 两者相加大于4096就表示单个Burst跨页。

对当前配置：

```text
AWLEN  = 15 → 16 beat
AWSIZE = 5  → 32 Byte/beat
16 × 32 = 512 Byte
```

4 KiB对齐Segment中的合法起点为：

```text
0x000, 0x200, 0x400, 0x600,
0x800, 0xA00, 0xC00, 0xE00
```

最后一个Burst：

```text
0xE00 + 0x200 = 0x1000
```

结束于边界是合法的；超过边界才失败。

### 6.3 `sim/tb_nvme_scheduler_errors.sv`

验证对象：项目级请求完成和fatal冻结。

独立复位后分别注入：

- Completion status错误；
- Completion Tag错误；
- Command Timeout；
- PCIe Link Down；
- Flush失败；
- ECQE。

预期：

- sticky状态正确；
- `fatal_error=1`；
- 错误Segment不得释放；
- 下一个正常Capture不得在未复位时启动。

V2.1没有虚构“重新下载程序”的行为模型。现场恢复属于供应商黑盒/真实工程
验证，不应由现有Stub猜测。

### 6.4 两个Stub的验证边界

`axi_ddr_mem_stub.sv`：

- 接收AW/W/B；
- 按WSTRB写仿真数组；
- 注入背压和BRESP错误；
- 不模拟MIG校准、刷新、Bank/Row或读带宽。

`nvme_req_cpl_stub.sv`：

- 接收抽象请求；
- 固定延迟返回完成；
- 注入失败、Timeout和错误Tag；
- 不读取DDR、不生成SQE/PRP、不运行PCIe、不访问SSD。

所以系统PASS只能证明数字逻辑骨架，不证明真实SSD已写入。

## 7. 本轮回归结果

执行命令：

```powershell
& 'D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat' `
  -mode batch -source .\scripts\run_vivado_test.tcl `
  -tclargs tb_adc_channel_packer

& 'D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat' `
  -mode batch -source .\scripts\run_vivado_test.tcl `
  -tclargs tb_nvme_adc_pipeline

& 'D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat' `
  -mode batch -source .\scripts\run_vivado_test.tcl `
  -tclargs tb_nvme_scheduler_errors
```

结果：

| 测试平台 | 结果 | V2.1关注点 |
|---|---|---|
| `tb_adc_channel_packer` | PASS | 证明保留的数据格式和边界未被影响 |
| `tb_nvme_adc_pipeline` | PASS | 新4 KiB Burst断言未触发 |
| `tb_nvme_scheduler_errors` | PASS | 原错误检测和fatal行为保持 |

汇总文件：

```text
build/regression/summary.json
3 PASS / 0 FAIL / FirstFatal=null
```

## 8. 真实集成时的验证代码扩展

### 8.1 真实MIG阶段

需要增加但当前不伪造：

- 内部500 MB/s和1 GB/s数据发生器；
- 独立AXI Reader；
- DDR读回CRC比较器；
- ILA探针：FIFO水位、AW/W Stall、BRESP、读写Outstanding；
- MIG `init_calib_complete`和错误状态采集。

### 8.2 SmartConnect并发阶段

测试组合：

```text
ADC Writer持续写DDR
+
独立Reader或NVMe IP持续读DDR
```

必须记录：

- FIFO最大水位；
- ADC Writer最长连续AWREADY低；
- 最长连续WREADY低；
- DDR读写有效带宽；
- 是否出现写饥饿；
- `dropped_sample_times`是否为0。

### 8.3 供应商IP阶段

使用我方Pattern：

```text
DDR A
→ NVMe Write
→ SSD
→ NVMe Read
→ DDR B
→ 全量/CRC比较
```

还需要验证：

- 4 KiB、512 KiB、4 MiB和条件允许时1 GiB；
- 不同DDR地址和SLBA；
- 大任务Completion等待全部内部SQE；
- `Write→Flush→Readback`；
- 连续写至少10分钟；
- 最低1秒带宽、最长停顿、Flush延迟和SSD温度；
- 一次“重新下载程序”的完整恢复。

## 9. 中文语义注释规则

本项目新增或修改代码的注释按以下规则执行：

1. 文件头说明模块在完整链路中的位置以及PASS不能证明什么；
2. 参数例化处说明单位、深度、时钟、Burst和地址含义；
3. 状态机按状态职责和进入/退出条件分段，不写“状态机逻辑”一类空注释；
4. 握手逻辑说明谁持有Payload、何时消费、stall时必须保持什么；
5. 跨时钟信号说明源时钟域、目标时钟域和同步方式；
6. FIFO例化处说明是XPM IP、数据宽度组成和深度参数；
7. 地址计算说明字节单位、对齐规则和溢出条件；
8. 错误路径说明为什么不能释放Buffer或自动重试；
9. testbench断言说明公式、触发时刻和它防止的具体故障；
10. Stub注释明确模拟了什么、没有模拟什么。

禁止使用以下泛泛注释：

```text
// 数据处理
// 状态机
// 参数设置
// 错误处理
// FIFO模块
```

应改成：

```text
// AW握手后用地址低12位和Burst字节数检查单事务是否跨越4 KiB边界；
// 该断言只约束ADC Writer的AXI Burst，不限制高层NVMe大任务跨多个页面。
```

## 10. 当前准确状态

已经具备：

- 自研ADC格式化和CDC；
- DDR AXI写入骨架；
- Segment所有权和错误保持；
- 抽象NVMe请求顺序；
- 供应商接口三态契约；
- 现场黑盒验证清单；
- 4 KiB AXI Burst边界断言。

仍未具备：

- 本板真实MIG/XDC；
- 供应商NVMe M_AXI正式参数；
- 正式Read/Write/Flush API；
- DDR Absolute/Offset换算；
- 聚合Completion定义；
- ECQE字段；
- 自动恢复流程；
- Vivado 2024.2可复现工程；
- 真实ADC→DDR→SSD闭环。

因此V2.1的正确结论是：

> 自研数据通路骨架和供应商集成契约已经收敛；真实MIG、地址映射、供应商API
> 和SSD闭环仍需按分阶段测试完成。
