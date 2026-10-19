# RTDS ARM—FPGA 板内联调实验手册

版本：V1.0，2026-10-16。配套程序目录：hardware_joint_lab_20261016。

本手册用于已建立PCIe连接的主机单板实验，依次验证寄存器、DDR DMA、VIO单块上行、多块队列与环回。ARM运行实际测试，Vivado观察或注入FPGA信号。当前reboot问题已由用户修复，固化启动和直接下载bit都作为可用入口。

## 1. 当前状态、交付位置和备份

| 对象 | 位置或实查结果 |
|---|---|
| 本机实验包 | E:\PCIE-CPU\outputs\hardware_joint_lab_20261016 |
| 远程Windows | SSH别名vivado-srv；已核实为DESKTOP-H0AB0MD\vivadoagent |
| 远程工程 | C:\project\RTDS\DDR\RTDS_test_DDR4_64bit_batch_dev |
| 远程实验包 | 上述工程的debug\hardware_joint_lab_20261016 |
| 共享盘访问同一工程 | R:\DDR\RTDS_test_DDR4_64bit_batch_dev |
| ARM程序/结果 | /root/rtds_joint_lab_20261016/arm；同级results每轮独立目录 |
| ARM系统 | Ubuntu 20.04.6、aarch64、Python 3.8.10、GCC及io |
| PCIe | 0000:01:00.0，10ee:8032，已绑定xdma |
| 用户BAR0 | 本次0xf0200000；每次从PCIe resource重新获取 |
| FPGA测试模式 | XPR参数RX_VIO_TEST_ENABLE=1，使用VIO测试源 |

实测项目、运行编号和未测项见《RTDS_部署与实测记录_20261016.md》。本次没有重新烧录，记录启动方式unknown，不把主机bit文件名当成现场Flash身份的证明。

修改前已把10月15日手册、操作卡、信号表及10月13日完整步骤等相关文件打包到本机实验包backups目录，配有backup_manifest.json，逐文件记录SHA256。旧文件仍保留，新文件使用20261016文件名和独立目录。

ARM再次部署前，先将整个原目录保存为/root/rtds_joint_lab_20261016_backup_加PC时间与唯一编号.tar.gz，之后才替换程序；首次部署创建新目录。SFTP传送后核对源码SHA256。备份时间使用PC时间，避免ARM错误日期导致覆盖。恢复时先确认无实验运行，解包到另一个新目录并核对，再从该目录运行，不覆盖正在运行的实验目录。

## 2. 程序原理

本机通过已有SSH密钥登录远程Windows，临时建立仅监听本机回环地址的SSH端口转发，经远程机访问192.168.50.10:22。ARM登录校验远程机已保存的ARM主机密钥；密码在终端输入，不保存。源码通过SFTP传入，再用ARM自带GCC编译为aarch64可执行文件。

Python主程序只用标准库，负责顺序、寄存器、超时、逐字节比对和报告。寄存器调用现有io；C程序通过xdma字符设备做一次同步DMA。缓冲区按4096Byte对齐，DMA映射、缓存同步和完成机制沿用现有驱动。

| 文件或节点 | 作用 |
|---|---|
| arm/rtds_lab.py | 六类实验、控制握手、结果判定、报告 |
| arm/rtds_dma.c及rtds_dma | C源码及ARM可执行文件；lseek指定卡端字节地址，再read/write提交一次DMA |
| /dev/xdma0_user | 检查用户BAR设备节点及其所属PCIe BDF；实际寄存器通过io访问 |
| /dev/xdma0_h2c_0 | CPU向FPGA DDR写入 |
| /dev/xdma0_c2h_0 | FPGA DDR向CPU读回 |
| vivado/rtds_lab.tcl | VIO检查、一次注入、ILA保存；经JTAG访问 |
| vivado/lab_service.tcl | 可选批处理控制器，只接受白名单操作，不执行任意Tcl |
| pc/lab_remote.py | PC侧传输、编译、启动实验、握手和取回结果 |

地址分三类：ARM物理BAR地址0xf0200000；业务偏移0x24；卡端DDR地址0x8000或0x18返回值。内部AXI-Lite的0x40000000不再叠加到BAR。CPU缓冲区由程序分配，也不同于卡端地址。

DMA短传输或错误不循环补传；主程序默认超时10秒。超时后停止实验，进程终止不等于驱动或FPGA已完全停止；先保存状态，不自动复位或归还块。

## 3. 本机与远程机控制

| 方式 | 测试运行位置 | FPGA控制入口 |
|---|---|---|
| 远程桌面使用Windows | ARM | 远程机Vivado GUI，点击或Tcl Console |
| 本机经远程机中转 | ARM | 同一个远程Vivado控制器，或人工GUI配合 |
| 本机Vivado连接远程hw_server | ARM | 本机Hardware Manager；双方同版本 |
| SSH批处理 | ARM | 远程Vivado Tcl，无需打开GUI |

同一板卡、逻辑和实际操作具有相同功能判据。网络改变命令到达时刻，硬件触发后的ILA采样仍由FPGA时钟决定。DMA耗时取ARM单调时钟，不计SSH往返。

提升管理员权限可能解决某些USB驱动或设备访问问题，但不保证目标可见，也不直接提供另一个GUI会话的控制接口。本包通过Tcl和hw_server操作硬件。若target不可见，检查下载线、驱动、供电、服务器和已有占用；不先强制终止其他会话。

同一时刻只允许一个流程管理VIO、ILA、通知清除和块归还。用批处理时让GUI释放硬件连接；用GUI时在该窗口执行Tcl，不另启控制器。

### 3.1 ARM终端：最直接的使用方式

在远程Windows的MobaXterm中登录192.168.50.10，root、端口22。登录后执行：

~~~sh
cd /root/rtds_joint_lab_20261016
python3 arm/rtds_lab.py env
python3 arm/rtds_lab.py regs
python3 arm/rtds_lab.py config --exclusive
python3 arm/rtds_lab.py ddr --exclusive --no-jtag
~~~

最后一条独立验证DDR DMA，无需打开Vivado；不声明VIO/ILA或真实Aurora通过。写入实验前暂停业务程序，--exclusive记录独占声明；程序另有全程锁和设备占用检查，不能替代现场协调。

结束查看FINISH的PASS/FAIL；退出码0表示该项通过。results每轮保存run.log、result.json、summary.csv和收发数据。可用--pc-time传入PC时间；未提供会标记not supplied，ARM日历时间始终标记不可信。

重新编译：sh arm/build.sh。状态等待默认2秒、DMA默认10秒，分别用--state-timeout、--dma-timeout调整；人工/文件握手默认600秒，与硬件状态超时分开。

### 3.2 本机自动执行

本机PC依赖已准备。PowerShell中：

~~~powershell
Set-Location E:\PCIE-CPU\outputs\hardware_joint_lab_20261016
$py = 'C:\Users\MaiBo\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $py pc\lab_remote.py run --case env
& $py pc\lab_remote.py run --case regs
& $py pc\lab_remote.py run --case config --exclusive
& $py pc\lab_remote.py run --case ddr --exclusive --no-jtag
~~~

按提示输入ARM密码，不回显、不保存。再次部署用 & $py pc\lab_remote.py deploy，自动备份、传送、编译和核对哈希；报告自动取回validation\board_runs。

程序沿用vivado-srv SSH别名。远程机DHCP地址变化时先核实并修复已有连接，不将当前Wi-Fi IP写死到ARM程序。

## 4. FPGA共用准备：GUI逐步操作

已正常运行的FPGA直接连接观察。第3节的CPU侧DDR闭环可跳过本节；单块、多块VIO上行需要本节连接成功。

| 顺序 | Vivado 2020.2操作 | 确认点 |
|---|---|---|
| F1 | 打开工程或仅Open Hardware Manager；Open Target→Auto Connect | Hardware树出现下载线和xcku040 |
| F2 | 已正常固化运行时，选设备、关联匹配LTX、Refresh Device | 关联LTX只解释调试探针，不重新烧FPGA |
| F3 | 确需临时下载时，Program Device选配套bit/LTX，等成功，再确认ARM枚举与访问恢复 | 不在DMA或取块进行中下载 |
| F4 | 确需固化时，Program Configuration Memory Device选已验证型号及MCS，Erase/Program/Verify成功后按已验证方式重新上电 | 已正常固化则跳过；本包不自动固化 |
| F5 | 找u_pcie/G_RX_VIO.U_VIO_RX_START，打开Dashboard，点击“+”添加全部探针 | 按实例路径选核，hw_vio_1等编号可能变化 |
| F6 | rx_test_start设0并点击Commit/提交；刷新输入 | busy=0，status低两位3、bit2 fault=0；单块起步blocks=0 |
| F7 | 打开u_pcie/U_PCIE_LINK_DEBUG/vio，添加live/history/uptime和snapshot信号 | clear_vio=0、capture_axi_vio=0；先存基线，不清历史 |
| F8 | live_vio低8位应为0xBF，uptime应更新；IRQ位可变化 | PERST、QPLL、时钟、link、AXI复位释放、DDR、观察稳定正常，业务复位0 |

当前配套文件目录：

~~~text
C:\project\RTDS\pcie_cold_boot_audit_20261014\main_spi4_50_gui
TOP_main_spi4_50.bit
TOP_main_spi4_50.ltx
TOP_main_spi4_50.mcs
~~~

哈希见artifact_manifest.json。0x04的20260914是常量，不是本次bit日期；应使用与实际下载逻辑匹配的LTX。Auto Connect只显示server而无target时，停止VIO/ILA项目，保留日志；打开GUI本身不保证能连接，CPU侧仍可独立检查。

## 5. VIO、ILA信号与按钮

### 5.1 旧VIO：u_pcie/G_RX_VIO.U_VIO_RX_START

| 名称 | 端口 | 含义 |
|---|---|---|
| rx_test_start | probe_out0 | 提交0→1一次注入；保持1不重复；下一轮先提交0再提交1 |
| rx_test_busy_r | probe_in0 | 等周期、发送和等真实块完成期间为1；下一次前必须0 |
| rx_test_accepted_r | probe_in1 | 接受的32bit字数，成功为2；单看2不证明DDR完成 |
| rx_test_status_r | probe_in2 | bit0 DDR；bit1 PCIe；bit2 fault；bit3通知 |
| rx_test_blocks_r | probe_in3 | 可读块数0～8，与BAR 0x30核对 |

发生器先等原writer周期，送0x11、0x22，再等真实块登记；250MHz下通常约100～200ms加事务时间。程序按状态等待，不以固定延迟代替完成。

### 5.2 ILA：先布防，再产生事件

| 事件 | ILA实例 | 触发条件 | 布防后动作 |
|---|---|---|---|
| VIO上行写DDR | u_pcie/ila_FDMA_inst | fdma_wareq==1 | 旧VIO start=0→1 |
| CPU H2C | u_pcie/U_PCIE_LINK_DEBUG/ila | ila_axi[0]=1且[1]=1，其余X | ARM执行H2C |
| CPU C2H | 同上 | ila_axi[6]=1且[7]=1，其余X | ARM执行C2H |
| 有对端的业务下行 | u_pcie/ila_FDMA_inst | fdma_rareq==1 | 软件0x20=1；本版不自动执行 |

选ILA→Trigger Setup，只保留对应条件；Trigger Mode=BASIC_ONLY、AND，Capture Mode=ALWAYS；FDMA 1024点、原生PCIe 2048点，触发位置128。点击单箭头Run Trigger，确认等待，再产生事件。Run Trigger Immediate会立即采样，不用于等待本轮业务。

FDMA采样250MHz，1024点约4.096µs，只看单次事务，不能覆盖100ms整周期。原生PCIe按实际axi_aclk换算。CPU直接访问DDR不经业务FDMA，所以FDMA没触发不代表DMA失败。

### 5.3 Tcl替代重复点击

在已连接此板的GUI Tcl Console中加载：

~~~tcl
source C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/debug/hardware_joint_lab_20261016/vivado/rtds_lab.tcl
set ::rtds_joint::report_dir C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/reports/hardware_joint_lab_20261016
::rtds_joint::snapshot
::rtds_lab::inspect
~~~

source只定义命令；snapshot读VIO并保存，inspect检查就绪。注入分阶段执行：

~~~tcl
::rtds_joint::arm fdma_up
::rtds_lab::inject
::rtds_lab::save fdma
~~~

inject检查busy、ready、fault和块数，提交0→1，再等块数增加且busy回0；失败不重试。手动点VIO与inject二选一。save等待完成后保存.csv/.ila，不自动前台显示。

## 6. E0/E1：环境与寄存器

先env，再regs。程序检查PCIe身份、资源、驱动和设备节点BDF一致，并保存下表。0x10读清，默认不读；0x14也不用于轮询。起步若有旧块则停止，不盲写0x14清空。

| 偏移 | 含义 | 判据 |
|---|---|---|
| 0x00/0x04/0x08 | 版本/日期常量/块容量 | 0x2001、0x20260914、0x40000 |
| 0x0C | 温度原始码 | 记录，不直接当摄氏度 |
| 0x18/0x1C/0x34 | 队头地址/长度/序号 | 起步空；序号0也可能是合法首块 |
| 0x20 | 下行忙 | 0 |
| 0x24/0x28 | 下行地址/长度 | 保存原值；长度复位为0x8000，0x10是实验值 |
| 0x2C | DDR状态 | 低两位3，bit[4:2]无错误 |
| 0x30 | 块数 | 起步0；工作期间0～8 |
| 0x38 | 累计丢失32bit字数 | 实验前后不增长；饱和则不能证明无新丢字 |

## 7. E2：配置写回与恢复

~~~sh
python3 arm/rtds_lab.py config --exclusive
~~~

| 顺序 | 软件动作 | FPGA操作/判定 |
|---|---|---|
| C1 | 等0x20=0，队列空，保存0x24/0x28 | 旧VIO不注入；无需ILA |
| C2 | 写地址0x8000、长度0x10并读回 | 一致，0x20仍0 |
| C3 | 写地址0x8010、长度0x20并读回 | 一致，未启动业务 |
| C4 | 健康空闲时恢复原值并核对 | 日志CONFIG_RESTORED |

不写启动寄存器0x20。遇到硬件错误不能安全恢复时停止并保留现场。

## 8. E3：16Byte DDR闭环

### 8.1 无ILA，自动完成

~~~sh
python3 arm/rtds_lab.py ddr --exclusive --no-jtag
~~~

向卡端0x8000写00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F，H2C完成后同址C2H读16Byte并逐字节比较。接收缓冲区预填A5；完成长度必须16。检查DDR无新错误、丢字不增长、队列仍空。

### 8.2 配合ILA，半自动执行

~~~sh
python3 arm/rtds_lab.py ddr --exclusive --capture
~~~

每个提示后，先完成对应Vivado操作，再回ARM输入PASS：

| ARM请求 | Vivado操作 |
|---|---|
| inspect | ::rtds_lab::inspect，确认健康 |
| arm dma_write | ::rtds_joint::arm dma_write，确认等待后输入PASS，ARM才提交H2C |
| save native | ::rtds_lab::save native，成功后确认 |
| arm dma_read | ::rtds_joint::arm dma_read，确认后ARM才提交C2H |
| save native | 保存读事务波形后确认 |
| snapshot | ::rtds_joint::snapshot，确认后看最终PASS/FAIL |

人工确认记manual_ack，不等于程序独立验证了波形。自动文件握手会保存硬件响应和证据路径。任何一侧失败都停止，不继续点下一次Trigger。

## 9. E4：一个8Byte上行块

~~~sh
python3 arm/rtds_lab.py single --exclusive --capture
~~~

| 顺序 | ARM自动动作 | Vivado操作和预期 |
|---|---|---|
| U1 | 先保存，要求队列空、下行闲，保留下行配置 | inspect：busy0、status低3位3、blocks0 |
| U2 | 请求布防并等待确认 | FDMA设置fdma_wareq==1，Run Trigger；或arm fdma_up |
| U3 | 请求一次注入 | start先提交0再1，或inject；accepted2、busy回0、fault0 |
| U4 | 等0x30=1，读地址/长度/序号 | 长度8；FDMA wsize1，数据00000022_00000011 |
| U5 | 请求保存波形 | save fdma后输入PASS，不先重新布防覆盖 |
| U6 | 连续1秒核对队头稳定；存0x2C/0x38；读一次0x10 | 通知bit0为1；读清后块数和队头不变 |
| U7 | 按返回地址C2H请求16Byte，只比有效前8Byte | 11 00 00 00 22 00 00 00；后8Byte未规定 |
| U8 | 确认状态及队头，再写一次0x14=1，等队列空 | 不需再写0；块数0、地址/长度0 |
| U9 | 检查无新错误/丢字、下行配置未变，存VIO | 最终PASS；下一轮注入先start0再1 |

DMA、比对或队头检查失败时不执行U8。通知清除和块归还是独立动作；是否有块看0x30，不看0x10。

## 10. E5：2块、8块、环回

~~~sh
python3 arm/rtds_lab.py multi --exclusive --capture
~~~

空队列开始，执行“积2块→逐块读完归还→积8块→逐块归还→再积2块→逐块归还”，共12次注入。每次先确认busy0，布防后才触发，等待真实块数增长；后续入队不能改变最早队头。

每块重新读取地址、长度和序号，C2H完成并比对后才归还一次。序号按32bit自然回绕连续；实际覆盖8个不同环形槽，最后队列空。起始地址不一定为0x100000，始终用硬件返回值。满8块不触发第9次；VIO会拒绝满队列注入，不能用它证明真实Aurora过载策略。

## 11. 无GUI的可选控制器

JTAG可见且无其他Vivado控制时，在本机PowerShell启动：

~~~powershell
Set-Location E:\PCIE-CPU\outputs\hardware_joint_lab_20261016
.\pc\start_vivado_service.ps1
~~~

保留终端，记下SESSION，等对应jobs目录出现service.ready。另一个终端：

~~~powershell
$py = 'C:\Users\MaiBo\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$jobs = 'R:\DDR\RTDS_test_DDR4_64bit_batch_dev\debug\hardware_joint_lab_20261016\jobs\替换为SESSION'
& $py pc\lab_remote.py run --case single --exclusive --capture --jobs $jobs
& $py pc\lab_remote.py run --case multi --exclusive --capture --jobs $jobs
& $py pc\lab_remote.py hardware --action stop --jobs $jobs
~~~

ARM发出布防/注入/保存请求，PC等Vivado完成再响应，ARM才继续。请求唯一编号，不因网络超时重复注入。stop仅关本控制器；空闲30分钟自动退出。若报已有Vivado运行，用现有GUI；若No matching targets，先恢复下载线目标可见性。实际通过状态见部署记录。

## 12. 故障取证和范围

| 现象 | 保存内容 | 处理 |
|---|---|---|
| 节点/BAR缺失 | env、PCIe枚举、驱动绑定 | 不启动DMA，先核对连接和系统 |
| DDR错误 | 无副作用寄存器、VIO、已有ILA | 不自动读0x10清历史 |
| DMA超时/短传输/不符 | result.json、错误、收发文件、驱动日志 | 停止，上行保留块，不归还或盲重试 |
| 通知0但块非空 | 队头/块数/0x2C/0x38 | 检查其他读清者，不能盲清队列 |
| 归还结果不确定 | WRITE_INTENT及后续状态 | 不再写第二次，先读块数与队头 |
| VIO fault | busy/accepted/status/blocks、FDMA波形 | 先取证；fault保持到全局复位 |
| ILA未触发 | 核路径、条件、布防顺序、操作类型 | BAR访问不在当前原生DMA ILA观察范围 |

重新下载/复位后，原映射、队列、序号和DMA现场可能改变，重新env/regs。程序不自动reboot、清历史、切换测试模式、改内核或重载驱动。

报告记录PC时间、ARM单调时间、程序与主机产物哈希、启动方式、寄存器、DMA地址/有效/请求/完成长度、比对和归还意图/确认、VIO/ILA路径。主机产物哈希只证明文件身份，不证明已固化。

RX_VIO_TEST_ENABLE=1替代真实Aurora RX/FIFO，start=0也不恢复正式接收。真实Aurora、对端下行、外部I/O和reboot专项后续开展。首轮轮询，不配置用户MSI；DMA完成沿用驱动机制。

参考：当前RTL、20261015手册、20261013《RTDS_驱动与主机单机联调_上下行完整操作步骤》；远程服务参考[AMD UG908 2020.2](https://docs.amd.com/r/2020.2-English/ug908-vivado-programming-debugging/Opening-a-New-Hardware-Target)，DMA接口参考[Xilinx官方工具](https://github.com/Xilinx/dma_ip_drivers/blob/master/XDMA/linux-kernel/tools/dma_to_device.c)。
