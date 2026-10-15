# v24_visual_catalog

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\v24_visual_catalog.py`
- SHA-256: `ebe71c2cb14478742f550036858aaf542d54e5f730375397fd0510dd2cd3e493`
- Extractor: `text`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\docs\v24_visual_catalog.py

```python
"""V2.4 文档图形目录。

这里只保存图的结构、读图说明和代表性时序，不复制 RTL 端口定义。
接口信号表由 build_v24_docs.py 在生成时直接从 11 个正式 RTL/SV 模块头提取。
"""

from __future__ import annotations


FORMAL_MODULES = [
    "nvme_adc_vitis_compat_top",
    "fdma_vitis_compat_regs",
    "adc_capture_limit_controller",
    "nvme_adc_pipeline_top",
    "adc_channel_packer",
    "axis_async_fifo",
    "adc_ddr_segment_writer",
    "sync_fifo",
    "segment_buffer_manager",
    "nvme_request_scheduler",
    "nophae_dma_backend",
]


OVERALL_ARCHITECTURE_ROWS = [
    ["MicroBlaze / Vitis 软件\nAXI4-Lite FDMA寄存器访问", "ADC CH0/CH1\nadc_valid + 12 bit×2", "PCIe / NVMe SSD\nNoPHAE实际命令执行"],
    ["↓ 写配置、START/STOP\n↑ 读状态与计数", "↓ 无反压采样源", "↑↓ PCIe事务"],
    ["fdma_vitis_compat_regs\n任务寄存器与软件兼容层", "adc_capture_limit_controller\n跨域启动、定长停止", "nophae_dma_backend\nNoPHAE寄存器微引擎"],
    ["↓ Capture上下文\n↑ 本地/最终完成", "↓ capture_start/stop", "↑↓ 抽象请求/Completion"],
    ["nvme_adc_vitis_compat_top\n正式Vitis兼容顶层", "adc_channel_packer\n256 bit打包与尾字排空", "nvme_request_scheduler\nPayload/Flush/Commit顺序"],
    ["↔ 状态和诊断汇总", "↓ 329 bit CDC条目", "↔ ready描述符/commit上下文"],
    ["segment_buffer_manager\nDDR槽位所有权与描述符表", "axis_async_fifo → Writer\nDDR AXI写入与Commit页", "DDR中的Payload/Commit页\n作为NoPHAE DMA源"],
]


OVERALL_ARCHITECTURE_EXPLANATION = [
    "顶层架构图按控制、采集缓存、存储请求三条纵向通道阅读。左列是软件可见的任务控制和Manager所有权管理，中列是从ADC采样到DDR落盘前缓存的真实数据通路，右列是从抽象请求到NoPHAE、PCIe和SSD的持久化通路。",
    "横向关联不是额外总线标准：Capture Controller把FDMA的START/STOP及配置跨到adc_clk；Writer通过alloc/fill项目内握手与Manager交换槽位所有权和描述符；Scheduler再把Manager的READY描述符转换成NoPHAE抽象请求。",
    "DDR同时承担两个角色：Writer的AXI写目标，以及NoPHAE执行NVMe WRITE时的DMA源。图中的Manager不读写DDR数据，也不是AXI Master；它只决定哪个固定Segment槽位可分配、可提交或可回收。",
    "最终capture_done不等于ADC停止。ADC停止并排空只形成local_capture_done；还必须完成全部Payload WRITE、Flush1、Commit WRITE和Flush2，Scheduler才发出最终完成脉冲。",
]


OVERALL_DATA_FLOW = [
    ["1", "ADC采样", "adc_valid携带CH0/CH1；源端不能因下游ready拉低而停顿"],
    ["2", "Packer 256 bit数据字", "按锁存的单双通道格式扩展为16 bit样点并打包，附带valid_bytes和EOC"],
    ["3", "329 bit CDC条目", "{capture_id, mode, EOC, valid_bytes, tdata}从adc_clk跨到sys_clk"],
    ["4", "Writer与Beat FIFO", "取得Segment槽位后累计CRC/字节数，按4 KiB补零并生成AXI Burst"],
    ["5", "DDR Payload/Commit页", "Payload位于8个1 MiB槽位，Commit页位于默认0xC0800000"],
    ["6", "Manager READY描述符", "DDR最终B响应成功后，fill握手把槽位从FILLING推进到READY"],
    ["7", "Scheduler请求序列", "Payload WRITE → Flush1 → Commit WRITE → Flush2，任一时刻只允许一个请求在途"],
    ["8", "NoPHAE / PCIe / SSD", "Backend编程NoPHAE控制寄存器并把Completion返回Scheduler"],
]


OVERALL_DATA_FLOW_EXPLANATION = [
    "数据流图中的序号是一次Capture的因果顺序，不表示各模块只有串行工作。Packer、CDC FIFO、Writer和Manager可以流水并行；Scheduler仍保持单项目请求在途。",
    "步骤2到步骤4使用ready/valid反压。若valid=1且ready=0，即发生stall，发送方必须保持数据和所有伴随字段不变。ADC物理输入不支持反压，因此反压只能由Packer两级缓存和CDC FIFO短时吸收，耗尽后会记录丢样。",
    "步骤5到步骤8把易失DDR内容持久化到SSD。Payload的真实字节数用于CRC和元数据，DMA字节数则向4 KiB对齐；两者不能混用。",
    "Commit页不是普通Payload Segment。它是Capture结束标志和汇总元数据，必须在所有Payload已经写入并完成第一次Flush之后提交。",
]


MODULE_VISUALS = {
    "nvme_adc_vitis_compat_top": {
        "role": "正式Vitis兼容集成顶层，把软件FDMA寄存器、跨域Capture控制、ADC到DDR/NVMe流水线和NoPHAE后端连接为完整工程边界。",
        "architecture": [
            ["ADC CH0/CH1\nMicroBlaze AXI4-Lite\nDDR/NoPHAE返回通道", "FDMA寄存器 → Capture Controller\n↓\nPipeline Top ↔ Backend\n↓\n状态/诊断汇总", "DDR AXI Master\nNoPHAE AXI-Lite Master\n软件可读任务状态"],
        ],
        "architecture_explanation": [
            "从左到右读图：外部输入先分别进入控制面和数据面。FDMA寄存器产生transfer_start_pulse，Capture Controller在时钟域间传递上下文，Pipeline完成打包、缓存、DDR写和请求调度，Backend再驱动NoPHAE寄存器接口。",
            "顶层没有新增数据缓存或协议状态机，主要责任是实例化和连线。定位故障时，应先按端口前缀分为s_axi_fdma、m_axi_ddr、m_axi_nophae和诊断四组，再下钻对应子模块。",
            "fatal_error是Pipeline和Backend错误的汇总边界；local_capture_done_pulse只表示ADC侧排空，capture_done才表示第二次Flush完成，软件不得混用。",
        ],
        "timing": """时刻                 C0    C1    C2 ... Cn    Cn+1  ... Cm\nFDMA START写握手        0     1     0      0      0       0\ntransfer_start_pulse    0     1     0      0      0       0\ncapture_start_adc       0     0    (CDC等待) 1      0       0\nlocal_capture_done      0     0     0  ...  1      0       0\nPayload/Flush/Commit    -     -    DATA ... F1/COMMIT/F2   -\ncapture_done            0     0     0      0      0       1""",
        "timing_explanation": [
            "C1的START写被FDMA寄存器校验通过后只产生一个sys_clk脉冲；跨域控制器不会组合传递该脉冲，而是用toggle事件和两级同步把它安全送到adc_clk。",
            "图中CDC等待和Cn/Cm为示意间隔，不能用固定周期替代实际握手。local_capture_done出现后仍有DDR和NVMe尾部工作，capture_done必须晚于Flush2 Completion。",
            "若fatal_error在中途置位，正常序列可进入错误保持，软件应读fdma_last_error/backend_last_status，不应等待一个不会到来的正常capture_done。",
        ],
    },
    "fdma_vitis_compat_regs": {
        "role": "软件兼容寄存器块，接受AXI4-Lite访问，校验并锁存一次传输配置，产生START/STOP脉冲并汇总任务状态。",
        "architecture": [["AXI-Lite AW/W/AR\n完成、取消、错误与计数", "AW/W独立缓存与配对\n寄存器文件/字节写使能\nSTART合法性检查\nsticky状态锁存", "transfer_start/stop_pulse\nCapture配置与base SLBA\n读响应/写响应/last_error"]],
        "architecture_explanation": [
            "AXI-Lite写地址AW和写数据W可以在不同周期到达，模块分别缓存，二者齐备后才执行一次寄存器写并返回B响应。图中的配对逻辑用于兼容合法AXI-Lite时序，不能假定AW/W同拍。",
            "START写入不是简单透传。模块检查任务是否空闲、长度和地址配置是否有效，再锁存transfer_size_bytes、capture_id和通道模式，最后生成单拍transfer_start_pulse。",
            "任务活动期间收到本地完成只表示采集停止；transfer_active要保持到最终NVMe完成、取消或致命错误。错误码和诊断计数通过读通道提供给现有Vitis软件。",
        ],
        "timing": """时刻               C0  C1  C2  C3  C4  C5\ns_axi_awvalid       0   1   0   0   0   0\ns_axi_awready       1   1   1   1   1   1\ns_axi_wvalid        0   0   1   0   0   0\ns_axi_wready        1   1   1   1   1   1\n内部AW/W齐备        0   0   1   0   0   0\ntransfer_start_pulse 0  0   1   0   0   0\ns_axi_bvalid        0   0   0   1   1→握手 0""",
        "timing_explanation": [
            "示例故意让AW先于W一拍到达。C1只缓存地址，C2缓存数据并执行配对后的START寄存器写；这说明START副作用只能发生一次。",
            "若B通道被软件stall，s_axi_bvalid和s_axi_bresp必须保持到bready握手，不能重复生成START。WSTRB只更新被选中的字节。",
            "读通道AR/R遵循同样的valid保持原则，但没有AW/W配对；读地址被接受后，rdata/rresp保持到rready。",
        ],
    },
    "adc_capture_limit_controller": {
        "role": "跨sys_clk/adc_clk传递Capture上下文，并在ADC域实现等待Packer就绪、运行、定长停止、排空完成和提前取消。",
        "architecture": [["sys_clk START/STOP\ntarget_bytes/模式/ID", "事件toggle与两级同步\n多位上下文两级同步+额外等待\nST_IDLE/CONTEXT/WAIT_READY/RUN/WAIT_DRAIN", "adc_clk capture_start/stop\n锁存配置\nlocal_done/cancelled/busy"]],
        "architecture_explanation": [
            "单拍START不能直接跨域，因此系统域先翻转start_toggle，ADC域用两级同步后检测异或变化。target_bytes、模式和capture_id是多位上下文，需先稳定，再经过两级同步，并在ST_CONTEXT额外等待一拍后统一锁存。",
            "ST_WAIT_READY保证Packer真正可以接受新Capture后才发capture_start_adc；ST_RUN比较Packer已接受样点数与目标字节数，手动STOP或定长条件满足时拉高capture_stop_adc；ST_WAIT_DRAIN等Packer回到非活动状态。",
            "停止判定优先于同拍adc_valid，避免超过目标长度一个数据时刻。若STOP早于实际启采，则走cancelled_pulse_sys，不伪造local_done。",
        ],
        "timing": """时刻/ADC拍        A0  A1  A2  A3  A4  A5 ... Ak\nstart_toggle同步后变化 0   1   1   1   1   1     1\n状态                 IDLE CTX CTX WAIT RUN RUN  DRAIN\n上下文同步级2有效      0   0   1   1   1   1     1\ncapture_start_adc     0   0   0   1   0   0     0\nstop条件              0   0   0   0   0   1     1\npacker_active         0   0   0   1   1   1     0\nlocal_done_sys        0   0   0   0   0   0   (CDC脉冲)""",
        "timing_explanation": [
            "A1检测到toggle事件后进入ST_CONTEXT，但不立即使用多位配置；到同步数据稳定并额外等待后，才进入WAIT并在Packer ready时产生单拍START。",
            "A5的stop条件可能来自软件STOP或定长计数。capture_stop_adc维持到Packer完成尾字排空，不能只给单拍，否则Packer可能在反压时漏掉停止请求。",
            "local_done_sys是ADC域完成事件再次通过toggle同步回系统域形成的脉冲，其延迟不固定，图中只描述因果关系。",
        ],
    },
    "nvme_adc_pipeline_top": {
        "role": "ADC到DDR和NVMe请求的流水线集成层，例化Packer、CDC FIFO、Writer、Manager和Scheduler并汇总诊断。",
        "architecture": [["ADC样点/Capture控制\nDDR与NVMe返回\n初始化/链路状态", "Packer → 329 bit异步FIFO → Writer\nWriter ↔ Manager → Scheduler\n错误、FIFO水位和计数汇总", "DDR AXI写通道\n抽象NVMe请求/Completion\ncapture_done与诊断"]],
        "architecture_explanation": [
            "主数据路径严格从Packer流向异步FIFO，再由Writer写DDR。Manager旁挂在Writer和Scheduler之间，只接收alloc/fill/ready/completion控制与描述符，不接触256 bit Payload。",
            "系统域只有在ddr_init_done后才允许消费CDC FIFO，避免MIG尚未可用时Writer提前启动。外部fatal条件会汇入Scheduler，使后续存储请求停止并锁存错误。",
            "顶层同时输出ADC域和系统域诊断。adc_fifo_max_used_count是历史水位，用于判断短时反压是否接近耗尽，但不等于丢样；丢样以Packer的dropped_sample_times和overflow_sticky为准。",
        ],
        "timing": """阶段              P0   P1   P2   P3   P4   P5\nPacker tvalid         1    1    0    0    0    0\nAsync FIFO s_ready    1    1    1    1    1    1\nFIFO m_valid          0   (CDC)  1    1    0    0\nWriter tready         0    0    0    1    1    1\nalloc_valid/ready     0    0   1/0  1/1  0    0\nfill_valid/ready      0    0    0    0   1/1   0\nManager ready_valid   0    0    0    0    0    1""",
        "timing_explanation": [
            "Packer条目跨异步FIFO后到达Writer。首个非空字出现时Writer先申请槽位，因此Writer tready在alloc握手前保持为0；alloc于P3完成后，数据才在后续WR_FILL周期消费。",
            "fill握手必须晚于该Segment最后一个DDR B响应。Manager接受描述符后把槽位推进READY，Scheduler才可能看到ready_valid。",
            "图省略多个实际DDR Burst周期，只表示模块间合同。任何ready拉低时，对应valid方都必须保持数据、Tag和描述符字段。",
        ],
    },
    "adc_channel_packer": {
        "role": "把不可反压的12 bit ADC样点按锁存配置扩展为16 bit并装入256 bit字，利用输出寄存器和pending寄存器吸收短时stall。",
        "architecture": [["capture_start/stop与配置\nadc_valid + CH0/CH1", "配置锁存/样点选择与符号扩展\npack_data装填\noutput寄存器 + pack_full_pending\nIDLE/ACTIVE/DRAIN", "256 bit + valid_bytes + EOC\nactive/ready\naccepted/dropped/sticky诊断"]],
        "architecture_explanation": [
            "Capture START只在IDLE且capture_ready时锁存配置。双通道每个数据时刻写入4 Byte，单通道写入2 Byte；运行期间外部配置变化只置config_change_sticky，不改变本次数据格式。",
            "output寄存器是标准ready/valid发送级；pack_full_pending是第二级弹性缓存。当output因stall占用而pack_data又装满时，完整字先进入pending，避免立即丢失。",
            "ST_DRAIN在STOP后禁止接收新ADC样点，但继续把部分尾字和EOC送出。没有DRAIN会过早回到IDLE，没有pending会在连续满字遇到下游stall时覆盖数据。",
        ],
        "timing": """时刻             A0   A1   A2   A3   A4   A5\nm_axis_tvalid      1    1    1    1    1    0\nm_axis_tready      1    0    0    1    1    1\noutput_take        1    0    0    1    1    0\npack字装满          0    1    0    0    0    0\npack_full_pending  0    1    1    0    0    0\ncapture_stop       0    0    1    1    0    0\n状态             ACTIVE ACTIVE DRAIN DRAIN IDLE IDLE""",
        "timing_explanation": [
            "A1到A2满足tvalid=1且tready=0，构成stall。输出寄存器的tdata、valid_bytes和EOC必须保持不变；同时新装满的数据字进入pack_full_pending并保持。",
            "A3下游恢复后，原输出字完成握手，pending字被提升到输出级。capture_stop已使状态进入DRAIN，但不会丢弃缓存数据。",
            "A4最后一个带EOC的输出字握手后才能回IDLE并拉高capture_ready。accepted计数记录被纳入打包的数据时刻，dropped只在两级缓存均无法接收而adc_valid仍到来时增加。",
        ],
    },
    "axis_async_fifo": {
        "role": "基于XPM异步FIFO把329 bit复合条目从adc_clk安全传到sys_clk，并用ready/valid包装复位忙、满和空条件。",
        "architecture": [["s_clk域329 bit tdata\ns_valid/s_ready", "XPM async FIFO\n写指针/读指针跨域同步\nFWFT读出\nfull/prog_full/used_count", "m_clk域329 bit tdata\nm_valid/m_ready\n水位诊断"]],
        "architecture_explanation": [
            "写侧只有s_axis_tvalid与s_axis_tready同时为1才写FIFO；s_ready由非full且写复位不忙共同决定。读侧采用FWFT，非empty且读复位不忙时直接给出m_axis_tvalid。",
            "329 bit是一个不可拆分条目，包含256 bit数据、6 bit有效字节数、EOC、模式、Capture ID等伴随信息。所有字段必须通过同一个FIFO跨域，不能分别同步后再拼接。",
            "prog_full是提前水位告警，不直接阻止写入；full才使s_ready拉低。由于ADC源不能反压，持续full最终会在Packer侧形成丢样。",
        ],
        "timing": """写侧时刻          W0  W1  W2  W3\ns_valid/s_ready     1/1 1/1 0/1 0/1\nFIFO写入             1   1   0   0\n读侧时刻          R0  R1  R2  R3  R4\nm_valid             0   0   1   1   1\nm_ready             0   0   0   1   1\nm_data              -   -   D0  D0  D1\nFIFO读出             0   0   0   1   1""",
        "timing_explanation": [
            "写侧W0/W1接受D0和D1后，读指针域要经过异步FIFO内部同步延迟才在R2看到m_valid，延迟不是固定一拍。",
            "R2发生stall，FWFT队首D0必须稳定。R3握手后队首推进为D1；伴随字段与tdata作为同一329 bit字一起保持和推进。",
            "跨域used_count是各自时钟域对占用量的近似同步观察，适合诊断水位，不应用作跨域精确事件计数。",
        ],
    },
    "adc_ddr_segment_writer": {
        "role": "为每个Payload Segment申请DDR槽位，接收复合流、计算CRC和元数据、4 KiB补零，驱动AXI写Burst并生成fill及Commit上下文。",
        "architecture": [["329 bit复合流\nManager alloc返回\nDDR B响应", "Writer八状态\nCRC/字节/样点/序号累计\n补零与Commit页生成\nBeat FIFO\nAXI AW/W/B四状态", "Manager fill描述符\nScheduler commit上下文\nDDR AXI Master\n错误与计数"]],
        "architecture_explanation": [
            "首个非空Payload字只触发alloc_valid，不能在分配前被消费。alloc握手取得segment_id、generation Tag和DDR基地址后，Writer进入WR_FILL，s_axis_tready才允许真实数据入队。",
            "Writer主状态机负责Segment边界、格式、CRC、补零和描述符；AXI子状态机负责把Beat FIFO转成最多16拍的Burst并等待B响应。两者通过queued_beats、job_target_beats和最终B响应协同。",
            "fill_payload_bytes是真实ADC字节数，fill_dma_bytes是向4 KiB对齐后的传输长度。fill_valid只有最终B响应已经覆盖全部目标beat后才成立；Commit页复用同一AXI写引擎，但不经过Manager槽位。",
        ],
        "timing": """时刻               S0   S1   S2   S3 ... Sn  Sn+1\ns_axis_tvalid       1    1    1    1      0    0\nWriter状态          WAIT ALLOC FILL FILL    DESC WAIT\nalloc_valid/ready    1/0  1/1  0/1  0/1     0/1  0/1\ns_axis_tready       0    0    1    1       0    0\n输入首字握手          0    0    1    0/1     0    0\nAXI最终B响应          0    0    0    0       1    0\nfill_valid/ready     0    0    0    0       0   1/1""",
        "timing_explanation": [
            "S0首个非空字已经有效，但没有槽位时tready必须为0，发送方保持整个复合条目。S1完成alloc后仍不在同拍消费首字，S2进入WR_FILL才握手，避免地址和Tag尚未锁存就写数据。",
            "中间省略真实数据、4 KiB补零和多个AXI Burst。只有最后一个Burst的B响应成功，job完成计数才覆盖所有目标beat，随后才能进入描述符状态。",
            "若FIFO满、复合格式非法、输入越过Segment边界或Writer不在接收状态，s_axis_tready都必须拉低。B响应错误置axi_error_sticky并在描述符中携带fill_error。",
        ],
    },
    "sync_fifo": {
        "role": "Writer内部同一sys_clk域的256 bit Beat FIFO，解耦复合流整理/补零与AXI Burst发送。",
        "architecture": [["Writer生成的Payload/零填充Beat\nwr_en", "XPM同步FIFO（FWFT）\n满/空门控\nused_count", "AXI W通道队首dout\nrd_en\n排队beat数量"]],
        "architecture_explanation": [
            "该FIFO不是CDC，读写都在Writer的clk域。上游每生成一个完整256 bit beat并且非full时写入，AXI引擎在W握手时读取。",
            "FWFT使dout在非empty时直接呈现队首，适合保持m_axi_wdata。AXI W发生stall时rd_en必须为0，队首不推进，wdata与wlast保持稳定。",
            "used_count参与queued_beats计算，帮助Writer判断已经生成但尚未完成发送的数据量；它不是Payload真实字节计数。",
        ],
        "timing": """时刻          C0  C1  C2  C3  C4\nwr_en          1   1   0   0   0\ndin            B0  B1  -   -   -\nempty          1→0 0   0   0  1\ndout           B0  B0  B0  B1  -\nrd_en          0   0   1   1   0\nused_count     1   2   1   0   0""",
        "timing_explanation": [
            "C0写入B0后FIFO进入非空，FWFT队首直接为B0。C1继续写B1，但读侧未握手，dout仍保持B0。",
            "C2的rd_en对应AXI W握手，队首在下一观察点推进B1；C3再次读取后empty置1。满时包装器会抑制写使能，上游Writer必须通过tready/状态门控停住。",
            "图中的used_count以当前实现的同步FIFO观察语义为准，用于相对水位和排队计算，不应与外部CDC FIFO水位混淆。",
        ],
    },
    "segment_buffer_manager": {
        "role": "管理固定DDR Segment槽位的所有权、generation Tag和描述符表，在Writer与Scheduler之间执行FREE→FILLING→READY→INFLIGHT→FREE生命周期。",
        "architecture": [["Writer alloc/fill\nScheduler completion", "槽位状态数组\ngeneration数组\n描述符RAM/寄存器阵列\n最低编号FREE/READY扫描\nTag与状态检查", "Writer alloc返回\nScheduler ready描述符\nsegment_states/free_count\nstate_error_sticky"]],
        "architecture_explanation": [
            "Manager不是AXI Master，也不搬运Payload。它保存每个固定DDR槽位的状态和描述符，alloc时把最低编号FREE槽位置为FILLING，fill成功后置READY，Scheduler接受后置INFLIGHT，匹配Completion后才回FREE。",
            "Tag由generation和segment_id组成。每次重新分配同一槽位先递增generation，再返回新Tag；迟到Completion即使segment_id相同，只要generation不匹配也不能释放当前槽位。",
            "fill_error或非法状态/Tag会使槽位进入ERROR_HOLD或置state_error_sticky，避免错误槽位被静默复用。free_count和segment_states只用于资源/诊断观察。",
        ],
        "timing": """时刻               M0    M1    M2    M3    M4\n槽位k状态           FREE FILLING READY INFLIGHT FREE\nalloc_valid/ready    1/1   0/1   0/1    0/1    0/1\nalloc_tag            G+1:k  -     -      -      -\nfill_valid/ready      0    1/1    0      0      0\nready_valid/accept    0     0    1/1     0      0\ncompletion_valid      0     0     0      1      0\ncompletion_tag        -     -     -    G+1:k    -""",
        "timing_explanation": [
            "M0的alloc握手同时确定槽位、DDR地址和新一代Tag，Writer必须保存这三个字段。M1的fill只有在segment_id、Tag和FILLING状态全部匹配时才接受。",
            "M2 ready_accept表示Scheduler已经接受并提交该Payload请求，不等于SSD已经完成；槽位进入INFLIGHT后仍不可重新分配。M3匹配成功Completion才释放。",
            "若M3到来旧generation的迟到Completion，Manager保持当前状态并置错误；若fill_error为1，槽位进入ERROR_HOLD，不走READY。",
        ],
    },
    "nvme_request_scheduler": {
        "role": "把READY Payload和Commit上下文排成单请求在途的持久化序列，推进SLBA、匹配Completion并在第二次Flush后完成Capture。",
        "architecture": [["Manager READY描述符\nWriter Commit上下文\n链路/初始化/错误\nBackend Completion", "单请求FSM与请求寄存器\nTag/状态匹配\nSLBA推进\nwatchdog\nPayload→F1→Commit→F2", "Backend抽象请求\nManager completion\ncommit_ready\ncapture_done/fatal/sticky"]],
        "architecture_explanation": [
            "Scheduler一次只保持一个nvme_req_valid并等待对应Completion，避免软件式NoPHAE寄存器接口出现多个未决命令。Payload请求来自Manager READY描述符，Commit请求来自Writer独立上下文。",
            "Payload成功后按ready_dma_bytes/512推进SLBA；真实payload_bytes只用于入口一致性检查。DDR物理地址由Backend转换为NoPHAE Offset，Scheduler仍保存物理地址。",
            "最后一个Payload完成后先发Flush1，再写Commit页，再发Flush2。只有Flush2成功才产生capture_done并更新last_capture_id；超时、链路下降、Tag/状态错误进入fatal路径并锁存sticky。",
        ],
        "timing": """事件/阶段           Q0    Q1    Q2    Q3    Q4    Q5    Q6    Q7\n请求类型             DATA  wait  F1   wait COMMIT wait  F2   wait\nreq_valid/ready       1/1   0    1/1   0    1/1   0   1/1   0\ncpl_valid/ready        0   1/1    0   1/1    0   1/1   0   1/1\nManager completion     0    1      0    0      0    0     0    0\ncommit_ready           0    0      0    0      1    0     0    0\ncapture_done           0    0      0    0      0    0     0    1""",
        "timing_explanation": [
            "Q0请求握手后req_valid可以撤销，但Scheduler保持等待状态，直到Q1收到Tag和状态匹配的Completion。Manager槽位在Q1才通过manager_completion_valid回收。",
            "图从最后一个Payload开始。Flush1成功后才能接受Commit上下文，Commit WRITE成功后还不能报告完成，必须继续Flush2。",
            "任一wait阶段若Completion错误、超时或链路掉线，capture_done不产生，fatal_error及相应sticky保持，避免软件把部分持久化误判为成功。",
        ],
    },
    "nophae_dma_backend": {
        "role": "把Scheduler的抽象WRITE/FLUSH请求转换为NoPHAE AXI-Lite寄存器访问序列，轮询DMA状态并返回项目级Completion。",
        "architecture": [["Scheduler req_valid/opcode\nDDR物理地址/长度/SLBA\nNoPHAE AXI-Lite返回", "请求合法性与上下文锁存\n物理地址→Offset\n高层命令FSM\nAXI-Lite读写微引擎\n超时/状态译码", "NoPHAE AXI-Lite Master\nScheduler cpl_valid/status\nbusy/last_status/sticky"]],
        "architecture_explanation": [
            "Backend不是NoPHAE内部RTL，而是项目侧适配器。它检查请求长度、对齐和DDR地址范围，将物理地址减去DMA窗口基址形成Offset，再按用户指南约定写NoPHAE寄存器。",
            "高层FSM决定先轮询DMA_READY、再写Offset/SLBA/长度/命令并轮询DMA_DONE；底层AXI-Lite微引擎负责AW/W独立握手、B响应以及AR/R握手。二者通过一次微事务完成事件解耦。",
            "cpl_valid一旦置1必须保持Tag和status到Scheduler的cpl_ready握手。enable撤销、非法请求、AXI响应错误或轮询超时都形成非零状态，并置error_sticky或timeout_sticky。",
        ],
        "timing": """阶段              B0      B1       B2       B3      B4      B5\nreq_valid/ready      1/1     0        0        0       0       0\n高层动作            锁存   读READY  写参数/命令 读DONE  形成CPL  等待取走\nAXIL事务            -       AR/R   AW/W/B×N  AR/R     -       -\ncpl_valid/ready      0       0        0        0      1/0     1/1\ncpl_tag/status       -       -        -        -     保持      保持\nbusy                 1       1        1        1       1       0""",
        "timing_explanation": [
            "B0只在req_valid与req_ready同时为1时锁存请求。后续NoPHAE寄存器访问可能经历任意AXI-Lite stall，Backend不得再次接受新请求。",
            "B1/B3的轮询可能重复多次，直到READY/DONE满足或watchdog超时；图中的单列代表阶段而非一个时钟周期。WRITE需要参数和命令寄存器序列，FLUSH使用相应控制序列。",
            "B4即使Scheduler暂未ready，cpl_valid、cpl_user_tag和cpl_status也保持；B5握手后才清空Completion并重新允许下一请求。",
        ],
    },
}


# 时序图以结构化电平数据保存。L/H只在生成器内部表示低/高电平，DOCX中会转换为
# 对齐的“▁/▔”波形；其他字符串表示状态或总线阶段，不作为逻辑0/1显示。
WAVEFORMS = {
    "nvme_adc_vitis_compat_top": {
        "cycles": ["T0", "T1", "T2", "T3", "T4", "T5", "T6", "T7"],
        "signals": [
            ("FDMA_START写握手", ["L", "H", "L", "L", "L", "L", "L", "L"]),
            ("transfer_start_pulse", ["L", "H", "L", "L", "L", "L", "L", "L"]),
            ("capture_start_adc", ["L", "L", "L", "H", "L", "L", "L", "L"]),
            ("local_capture_done", ["L", "L", "L", "L", "L", "H", "L", "L"]),
            ("存储阶段", ["空闲", "启动", "采集", "采集", "DATA", "F1", "COMMIT", "F2"]),
            ("capture_done", ["L", "L", "L", "L", "L", "L", "L", "H"]),
        ],
    },
    "fdma_vitis_compat_regs": {
        "cycles": ["T0", "T1", "T2", "T3", "T4", "T5"],
        "signals": [
            ("s_axi_awvalid", ["L", "H", "L", "L", "L", "L"]),
            ("s_axi_awready", ["H", "H", "H", "H", "H", "H"]),
            ("s_axi_wvalid", ["L", "L", "H", "L", "L", "L"]),
            ("s_axi_wready", ["H", "H", "H", "H", "H", "H"]),
            ("AW/W齐备", ["L", "L", "H", "L", "L", "L"]),
            ("transfer_start_pulse", ["L", "L", "H", "L", "L", "L"]),
            ("s_axi_bvalid", ["L", "L", "L", "H", "H", "L"]),
        ],
    },
    "adc_capture_limit_controller": {
        "cycles": ["A0", "A1", "A2", "A3", "A4", "A5", "A6"],
        "signals": [
            ("start_toggle变化", ["L", "H", "H", "H", "H", "H", "H"]),
            ("控制状态", ["IDLE", "CTX", "CTX", "WAIT", "RUN", "RUN", "DRAIN"]),
            ("上下文同步有效", ["L", "L", "H", "H", "H", "H", "H"]),
            ("capture_start_adc", ["L", "L", "L", "H", "L", "L", "L"]),
            ("stop条件", ["L", "L", "L", "L", "L", "H", "H"]),
            ("packer_active", ["L", "L", "L", "H", "H", "H", "L"]),
            ("local_done事件", ["L", "L", "L", "L", "L", "L", "H"]),
        ],
    },
    "nvme_adc_pipeline_top": {
        "cycles": ["P0", "P1", "P2", "P3", "P4", "P5"],
        "signals": [
            ("Packer_tvalid", ["H", "H", "L", "L", "L", "L"]),
            ("AsyncFIFO_s_ready", ["H", "H", "H", "H", "H", "H"]),
            ("FIFO_m_valid", ["L", "L", "H", "H", "L", "L"]),
            ("Writer_tready", ["L", "L", "L", "H", "H", "H"]),
            ("alloc_valid", ["L", "L", "H", "H", "L", "L"]),
            ("alloc_ready", ["H", "H", "L", "H", "H", "H"]),
            ("fill握手", ["L", "L", "L", "L", "H", "L"]),
            ("Manager_ready_valid", ["L", "L", "L", "L", "L", "H"]),
        ],
    },
    "adc_channel_packer": {
        "cycles": ["A0", "A1", "A2", "A3", "A4", "A5"],
        "signals": [
            ("m_axis_tvalid", ["H", "H", "H", "H", "H", "L"]),
            ("m_axis_tready", ["H", "L", "L", "H", "H", "H"]),
            ("output_take", ["H", "L", "L", "H", "H", "L"]),
            ("pack字装满", ["L", "H", "L", "L", "L", "L"]),
            ("pack_full_pending", ["L", "H", "H", "L", "L", "L"]),
            ("capture_stop", ["L", "L", "H", "H", "L", "L"]),
            ("状态", ["ACTIVE", "ACTIVE", "DRAIN", "DRAIN", "IDLE", "IDLE"]),
        ],
    },
    "axis_async_fifo": {
        "cycles": ["T0", "T1", "T2", "T3", "T4", "T5"],
        "signals": [
            ("s_axis_tvalid", ["H", "H", "L", "L", "L", "L"]),
            ("s_axis_tready", ["H", "H", "H", "H", "H", "H"]),
            ("FIFO写入", ["H", "H", "L", "L", "L", "L"]),
            ("m_axis_tvalid", ["L", "L", "H", "H", "H", "L"]),
            ("m_axis_tready", ["L", "L", "L", "H", "H", "H"]),
            ("m_axis_tdata", ["空", "同步", "D0", "D0", "D1", "空"]),
            ("FIFO读出", ["L", "L", "L", "H", "H", "L"]),
        ],
    },
    "adc_ddr_segment_writer": {
        "cycles": ["S0", "S1", "S2", "S3", "S4", "S5", "S6"],
        "signals": [
            ("s_axis_tvalid", ["H", "H", "H", "H", "L", "L", "L"]),
            ("Writer状态", ["WAIT", "ALLOC", "FILL", "FILL", "PAD", "AXI_B", "DESC"]),
            ("alloc_valid", ["H", "H", "L", "L", "L", "L", "L"]),
            ("alloc_ready", ["L", "H", "H", "H", "H", "H", "H"]),
            ("s_axis_tready", ["L", "L", "H", "H", "L", "L", "L"]),
            ("输入首字握手", ["L", "L", "H", "L", "L", "L", "L"]),
            ("AXI最终B响应", ["L", "L", "L", "L", "L", "H", "L"]),
            ("fill握手", ["L", "L", "L", "L", "L", "L", "H"]),
        ],
    },
    "sync_fifo": {
        "cycles": ["C0", "C1", "C2", "C3", "C4"],
        "signals": [
            ("wr_en", ["H", "H", "L", "L", "L"]),
            ("din", ["B0", "B1", "空", "空", "空"]),
            ("empty", ["H", "L", "L", "L", "H"]),
            ("dout", ["B0", "B0", "B0", "B1", "空"]),
            ("rd_en", ["L", "L", "H", "H", "L"]),
            ("水位", ["一拍", "两拍", "一拍", "空", "空"]),
        ],
    },
    "segment_buffer_manager": {
        "cycles": ["M0", "M1", "M2", "M3", "M4"],
        "signals": [
            ("槽位k状态", ["FREE", "FILLING", "READY", "INFLIGHT", "FREE"]),
            ("alloc_valid", ["H", "L", "L", "L", "L"]),
            ("alloc_ready", ["H", "H", "H", "H", "H"]),
            ("fill握手", ["L", "H", "L", "L", "L"]),
            ("ready握手", ["L", "L", "H", "L", "L"]),
            ("completion_valid", ["L", "L", "L", "H", "L"]),
            ("Tag", ["G+1:k", "保持", "保持", "匹配", "释放"]),
        ],
    },
    "nvme_request_scheduler": {
        "cycles": ["Q0", "Q1", "Q2", "Q3", "Q4", "Q5", "Q6", "Q7"],
        "signals": [
            ("请求类型", ["DATA", "等待", "F1", "等待", "COMMIT", "等待", "F2", "等待"]),
            ("req_valid", ["H", "L", "H", "L", "H", "L", "H", "L"]),
            ("req_ready", ["H", "L", "H", "L", "H", "L", "H", "L"]),
            ("cpl_valid", ["L", "H", "L", "H", "L", "H", "L", "H"]),
            ("cpl_ready", ["H", "H", "H", "H", "H", "H", "H", "H"]),
            ("Manager完成", ["L", "H", "L", "L", "L", "L", "L", "L"]),
            ("commit_ready", ["L", "L", "L", "L", "H", "L", "L", "L"]),
            ("capture_done", ["L", "L", "L", "L", "L", "L", "L", "H"]),
        ],
    },
    "nophae_dma_backend": {
        "cycles": ["B0", "B1", "B2", "B3", "B4", "B5"],
        "signals": [
            ("req_valid", ["H", "L", "L", "L", "L", "L"]),
            ("req_ready", ["H", "L", "L", "L", "L", "L"]),
            ("高层动作", ["锁存", "读READY", "写参数", "读DONE", "形成CPL", "等待取走"]),
            ("AXIL读事务", ["L", "H", "L", "H", "L", "L"]),
            ("AXIL写事务", ["L", "L", "H", "L", "L", "L"]),
            ("cpl_valid", ["L", "L", "L", "L", "H", "H"]),
            ("cpl_ready", ["H", "H", "H", "H", "L", "H"]),
            ("busy", ["H", "H", "H", "H", "H", "L"]),
        ],
    },
}


for _wave_module, _wave in WAVEFORMS.items():
    assert _wave_module in FORMAL_MODULES
    assert all(
        len(values) == len(_wave["cycles"])
        for _, values in _wave["signals"]
    )


assert set(MODULE_VISUALS) == set(FORMAL_MODULES)
assert set(WAVEFORMS) == set(FORMAL_MODULES)
```
