from pathlib import Path
import re,json,hashlib,difflib,zipfile
B=Path(__file__).resolve().parent;D=B/'before';A=B/'after';A.mkdir(exist_ok=True)
M=json.loads((D/'source_manifest.json').read_text('utf-8'))
HEAD={
'TOP.v':['板级连接：把主机PCIe、DDR4、Aurora 10G和1G业务连接起来。','板载100MHz经时钟模块产生业务时钟；Aurora发送使用各自用户时钟。','250MHz同一时间基准产生2µs事件和50µs GPIO，2µs事件连接四拍1G发送。','温度原始码先在业务域寄存；DDR、主机和链路复位分别按实际接口连接。'],
'PCIe.v':['主机侧数据连接：XDMA/寄存器、FDMA业务和DDR后端之间的封装。','INFO_EXCH接收软件启动、地址、长度与读完确认；adapter完成10G收发业务。','下行地址范围为0x8000～0xFFFF；上行使用0x100000开始的8个256KiB块。','DDR接口使用低32bit地址；软件命令结束、写响应成功和块可读是不同状态。'],
'CONV_DMA.v':['将FDMA读写请求转换成AXI存储突发，读写方向独立运行。','地址按字节计，fdma_size按数据拍计；突发受256拍和4KiB边界限制。','AW与W允许独立接受，写完成必须等最终B响应；读计数只随实际R握手推进。','本模块fdma_wready输入表示源数据有效，fdma_wvalid输出表示当前拍已接受。'],
'INFO_EXCH.v':['软件寄存器接口：接收AXI-Lite访问，提供版本、状态和业务命令。','软件写0x24/0x28设置下行地址和长度，写0x20启动，忙时不允许改参数。','读0x10清通知和相关错误；写0x14=1只确认一次CPU已读完的上行块。','AXI请求在S_AXI_ACLK处理，低有效复位清命令和握手状态；常量版本不随复位改变。'],
'pcie_fdma_aurora_brg_adapter.v':['连接软件控制、CONV_DMA读写和Aurora 10G用户接口。','下行把DDR载荷按16Byte帧发送，并在每帧首个已接受读拍提取Byte1。','上行每个有效拍取低32bit，经异步FIFO、拼接和块写模块保存到DDR。','链路或DDR失效后停止业务交付，但继续接收旧读，防止旧数据混入下一任务。','重新允许任务需旧读结束、用户域桥停止确认及8拍无旧完成事件；正常结束可暂存一条下一命令。'],
'rtds_ddr4_backend.sv':['DDR接口封装：DDR4_REAL连接实际MIG，DDR4_SIM_RAM连接行为RAM，二者只能选一。','业务AXI与MIG用户时钟之间通过时钟转换IP连接，存储复位在两侧分别同步释放。','已接受AR/AW后保存ID和拍数；存储失效时补齐错误R，或收完并丢弃剩余W后返回错误B。','已经展示的R/B在反压期间保持，不能因为后来失效而改写；业务全局复位仍会清恢复记录。','本模块是项目自写RTL，MIG和Clock Converter为厂商IP；RAM配置不代表DDR物理时序。'],
'rtds_axi_ram_model.sv':['仿真用AXI存储模型，不模拟DDR校准、引脚或物理时序。','AW和W分别保存，按WSTRB逐字节写入；支持当前8Byte拍配置的INCR/FIXED地址模式。','读地址接受后逐拍返回数据，R/B受反压时保持；越界和不支持的请求返回SLVERR。','状态在aclk运行，aresetn清接口状态；真实DDR上板配置不使用本模型。'],
'rtds_1g_periodic_tx.v':['首次合法Byte1编号1～10查表得到duty和Vin，完整48bit配置跨域后锁定。','250MHz产生的2µs事件同步到31.25MHz用户域，事件到来时尝试发送4×32bit。','16Byte中Byte0/1为duty低/高，Byte2～5为Vin低字节先发，Byte6=F0，其余保留字节为0。','反压保持当前拍；忙时跳过事件，不补发。用户复位或断链中止帧，主机复位才清首次配置。'],
'rtds_rx_block_writer.v':['把连续接收拍的低32bit写入DDR：先到字在64bit低半，后到字在高半。','每次写一拍；收到无错误的最终写响应后才增加有效长度。奇数尾字仅使能低4字节。','250MHz下默认25000000拍为100ms；周期到期先完成剩余写入，再登记非空块为可读。','8块依次循环使用，CPU读完确认只释放最早待读块；读清通知不释放数据。','不能保存或写失败的字计入32bit饱和丢失计数，计数单位是字而非帧。'],
'rtds_rx_frame_fifo.v':['接收时钟域保存完整64bit拍，异步FIFO送到DDR业务时钟域；低32bit提取由写块模块完成。','线路侧rx_ready持续为1，接收未允许、FIFO满或复位忙时丢弃新有效字并计数。','读侧只在frame_valid和frame_ready共同成立时取走数据，已存数据顺序保持。','SOF/EOF/REM只保留接口兼容，不据这些标志过滤有效字；丢失计数跨域读出。'],
'rtds_sync_timebase.v':['同一个250MHz时钟与复位产生2µs源事件和50µs GPIO。','每500拍翻转tick_toggle_2us一次；翻转间隔是2µs，完整高低周期为4µs。','GPIO每12500拍一周期，高低各6250拍；每个GPIO周期包含25个源事件。','低有效复位清计数和输出；事件与GPIO不会因1G反压或断链暂停。'],
'rtds_fpga_1g_init.v':['把板载100MHz通过BUFGCE_DIV四分频成25MHz的1G初始化时钟。','主机复位重新开始初始化计数；GT复位先于协议核复位解除。','计数和输出在init_clk域更新，复位解除经过本域同步；不由业务数据生成时钟。'],
'rtds_fpga_cfg_cdc.v':['用XPM握手成组传递48bit配置，源域保持数据直到目的域确认。','src_send发请求，dst_req表示目的侧得到完整数据，dst_ack返回接受确认。','多位配置作为一个整体传递，不逐位独立同步；两侧按各自时钟推进。'],
'rtds_fpga_count_cdc.v':['把源域32bit累计计数以Gray编码跨到目的时钟域。','输入计数与src_clk同步，目的域得到有同步延迟的计数值。','用于统计读回，不能把目的域延迟后的值当成同拍数据接受事件。'],
'rtds_fpga_reset_sync.v':['低有效复位封装：异步进入复位，在目标clk连续运行后同步解除。','rst_async_n为外部复位，rst_sync_n供本时钟域业务逻辑使用。','使用XPM复位同步结构，不改变上游复位来源或极性。'],
'fdma_aurora_brg_tx.v':['将FDMA返回数据写入64bit异步FIFO，再按16Byte帧送到Aurora 10G。','fdma_clk负责读请求和FIFO写入，user_clk负责两拍帧发送与帧完成计数。','FIFO接近满时停止预取；发送只在有效与接收许可同拍成立时取走当前拍。','首拍SOF、末拍EOF、REM=7；链路或本地复位清在途发送状态。'],
'aurora_64b66b_top.v':['10G协议核的板级封装，连接GT差分引脚、参考时钟和LocalLink业务接口。','业务传输使用协议核输出的user_clk，初始化使用独立clk_init。','包含上电复位顺序模块：保持PMA复位后先释放PMA，再经过间隔释放协议复位。','官方协议核内部保持原样；本文件负责外围连接和复位顺序。'],
'CLK_GEN.v':['板载差分参考时钟通过输入缓冲和时钟IP形成业务使用的时钟。','locked未成立时给出系统复位；各使用域仍需按本域规则处理复位解除。','本文件只连接时钟IP，不在普通业务逻辑中分频生成时钟。'],
'LED.v':['按SYS_CLK和LED_CYCLE产生周期指示，计数在i_sys_clk域运行。','复位时LED为1、计数为0；每半周期翻转一次输出。','LED只表示周期计数活动，不作为DDR校准或PCIe/Aurora就绪判断。'],
'TEMP_RD.v':['通过SYSMON接口按设定周期操作DRP端口，temp返回原始16bit温度码。','cnt_time在sys_clk域计时，周期末前10拍发出使能，并在最后10拍给出busy。','当前代码同时驱动den_in和dwe_in，地址/写数据按复位后保存值使用；注释不改接口操作。','sys_rst清控制状态；温度码不是直接的摄氏温度，数值换算由使用方完成。']}

BLOCK={
'aurora_64b66b_top.v':['clk_init沿处理复位同步：sys_rst立即置两级为1，解除后逐拍移入0。','clk_init沿执行PMA与协议核复位顺序：先保持两者，再释放PMA、等待间隔，最后解除协议复位。'],
'fdma_aurora_brg_tx.v':['fdma_clk沿保存读状态，低有效复位回RD_IDLE。','计算读次态：链路允许、FIFO可写且批量未结束才请求；busy接受后等该次读结束。','只在rd_data_hs成立时统计当前读拍，达到突发末拍后回零。','读busy释放后移动下一帧地址，地址超过配置范围时从0重新开始。','请求状态保持fdma_rareq，CONV_DMA置busy接受后撤销，避免重复请求。','user_clk沿保存发送状态，低有效复位回TX_IDLE。','计算发送次态：有完整帧数据才开始，SOF及后续数据状态仅随tx_hs推进。','组合输出当前FIFO数据和帧标记；REM固定7，反压期间不改变当前FIFO读位置。','只在LocalLink实际接受时增加帧内拍位置，帧末归零。','在用户域每发送完整一帧增加frame_cnt，复位清零。','在FDMA域每结束一次读突发增加burst_cnt，复位清零。'],
'CONV_DMA.v':['计算写次态：校验请求后分段，AW/W独立处理，等B响应后继续下一段或结束。','AXI时钟沿保存写次态，复位回W_IDLE。','接受新写请求时保存基址；每个B响应完成当前段后，地址增加该段字节数。','保存整次写请求尚未完成的拍数；收到B响应后扣除当前段，不能按W末拍提前扣除。','准备每段写长度：取剩余拍数、256拍上限和距4KiB边界拍数的最小值。','每个W握手推进段内拍位置，末拍后归零；没有握手时保持。','每段开始置AW待接受，实际AW握手后清除；不要求AW与W同拍到达。','每段开始置W待发送，最后一拍实际接受后清除，之后仍需等待AW/B。','只在最后B握手或拒绝非法请求时给一次fdma_wdone；W末拍不等于写成功。','新写请求清上一任务错误；本请求任一B非OKAY后保持fdma_werror直到下一请求。','计算读次态：分段提交AR，收到该段规定的全部R拍后继续或结束。','AXI时钟沿保存读次态，复位回R_IDLE。','接受读请求时保存地址；当前读段收齐后增加已读字节数，AR等待期间地址保持。','保存整次读尚未完成的拍数；当前段最后R实际接受后扣减。','准备每段读长度，采用与写方向相同的256拍和4KiB限制。','只在R有效与ready同拍成立时推进段内读位置，不把等待周期计成数据拍。'],
'INFO_EXCH.v':['AW和W同时有效且允许新写时给一次地址接受；等待B完成后才重新开放写入口。','保存写入口许可：接受本次AW/W后关闭，B被软件接受后重新开放。','写请求接受时锁存AW地址，后续软件改变AWADDR不影响这次寄存器选择。','AW/W同时有效且入口开放时给一次W接受；其余周期撤销，避免重复写。','有效写0x14、byte0使能且bit0为1时生成单拍读完确认，下一拍自动回0。','0x20接受一次启动并保持忙；结束事件优先清忙，忙期间重复启动不产生新任务。','仅空闲时按WSTRB更新0x24下行地址，复位为0x8000；忙时保持。','仅空闲时按WSTRB更新0x28长度，复位为32KiB；忙时保持。','本次AW/W接受后保持BVALID，直到BREADY接受；复位撤销。','寄存器写响应固定OKAY，B响应形成时更新为0。','AR有效时给一个接受脉冲，下一周期撤销。','AR接受时保存读地址，供后续译码和数据返回使用。','读请求被接受后保持RVALID，直到软件RREADY接受。','寄存器读响应固定OKAY，复位和读响应形成时置0。','按已保存的低16bit读地址选择版本、命令和状态；未定义偏移返回0。','读请求有效时把译码结果保存到AXI返回寄存器，未产生新读时保持。','真实AR握手读取0x10时给单拍清通知，不释放待读数据块。','读取0x10时给单拍清相关错误请求；与CPU读完确认分别处理。','延迟保存0x20忙位，用0到1变化生成下行启动单拍。'],
'LED.v':['i_sys_clk沿累加半周期计数，到设定末拍翻转LED并归零；同步复位令LED为1。'],
'PCIe.v':['仅仿真检查实际AXI地址握手：高32bit非零时报错，防止连接到32bit后端时静默截断。'],
'pcie_fdma_aurora_brg_adapter.v':['FDMA域保存一条正常结束期间的下一命令及地址/帧数；失去就绪取消，异常退出期间不接收暂存命令。','FDMA域产生发送桥复位：链路失效或无当前任务时清管线，有效任务连续两拍后解除。','用户域产生发送桥复位：用户就绪或任务无效时清管线，两拍稳定后解除。','在用户时钟沿确认任务无效且桥处于复位，得到tx_user_quiet，再同步回FDMA域。','保持旧任务清理状态；旧busy结束、用户停止确认及无旧完成事件连续8拍后才允许下一任务。','每完成一帧翻转用户域完成标志，跨域后通过异或恢复单拍事件。','保存上一拍同步完成翻转位，供异或检测新完成事件。','启动有效任务置tx_active；就绪失效或最后一帧完成后清除。','启动时保存目标帧数，正常暂存命令使用其快照；任务结束或失效清目标。','只为当前有效任务计已完成帧，启动、失效或最后帧结束时清零。','启动时锁定本批起始地址，暂存命令用地址快照，读数据时不再跟随软件寄存器变化。','当前任务开始置响应忙，完成或就绪失效清除；与旧读busy是否结束分开判断。','保存上一拍FIFO丢字计数，识别接收侧新丢字。','保存上一拍块写丢字计数，识别DDR写入或空间不足引起的新丢字。','发现新的丢字时保持接收超额错误，软件清相关状态后解除。','保存CPU确认位的上一拍，形成一次0到1确认事件。','同步保存当前CPU确认状态，供寄存器读回。','仅当前有效交付任务统计帧内读拍；每两拍归零，停止交付时重置首拍位置。','每次软件清相关错误翻转标志，将清除动作可靠传到用户域。','保存用户域上一拍清除翻转位，通过异或检测清除单拍。','跟踪接收帧是否处于首尾之间，失去用户就绪时回到无帧状态。','在用户域按实际接收握手统计帧内拍数，首拍重新计数，末拍归零。','长度筛除已取消，此兼容错误标志复位及运行时均为0。','用户域检测接收无法保存的拍并保持溢出标志，收到软件跨域清除后归零。','用户域保持发送读空错误，收到跨域清除后归零。','把等待和进展条件同时寄存一级，使超时计算使用同一拍状态。','FDMA域保持新的接收溢出或丢字错误；清除后等旧跨域高电平撤销再允许重新置位。','FDMA域保持用户侧发送读空错误；软件清除时优先清零。','仅等待且无进展达到阈值时置超时，软件清除时归零；空闲不应算等待。','保持非法命令或用户侧长度错误；软件清除和跨域清除等待共同约束重新置位。','启动时未就绪或活动任务失去就绪时置链路错误；曾建立链路后下降也记录。','记录是否曾出现完整就绪，复位清零，用于区别尚未建链与建链后丢失。','有进展、无等待或软件清错时清计数，仅持续无进展等待时累加到超时阈值。','软件清错后保持用户侧清除等待；旧跨域错误都回低后再接受新的错误事件。'],
'TEMP_RD.v':['sys_clk沿独立计时，到采样周期末拍归零；sys_rst同步清零。','在周期末前10拍发出一次DRP使能，其他拍撤销；地址与写数据保持复位后值。','在周期最后10拍给出busy，其他时刻清零；busy是本模块计时状态。'],
'TOP.v':['250MHz沿保存温度原始码和busy字段，系统复位清零；寄存器可见值增加一拍延迟。'],
'rtds_axi_ram_model.sv':['aclk沿独立保存AW和W；两者都有且B空闲时按WSTRB写入。最后拍形成一次B，反压期间保持ID和响应码。','aclk沿保存AR参数并逐拍返回数据；仅R被接受后推进地址/剩余拍数，RREADY为0时保持当前拍。'],
'rtds_ddr4_backend.sv':['AR接受时保存ID和拍数；存储失效后尚未装载的R改为零数据SLVERR。已展示R保持，最后R被接受后清旧读记录。','AW接受时保存ID和拍数；失效后接收并丢弃剩余W，收齐后只给一次错误B。已展示B保持到接受。','按地址接受和最终响应维护未完成事务数；无进展达到阈值或存储ready下降时保持错误，clear_status清诊断。','RAM模式等待业务和DDR系统复位解除，再连续两拍给出存储ready。','业务时钟域异步进入转换器复位，连续16个业务时钟后解除本侧复位。','MIG用户时钟域异步进入转换器复位，连续16个UI时钟后解除本侧复位。','把MIG侧复位解除确认同步回业务域；任一共同复位条件失效时清同步管线。','MIG未校准或UI要求复位时保持接口复位，校准后在UI域两拍解除。','把UI接口可用标志同步到业务时钟域；业务全局复位清该同步状态。'],
'rtds_1g_periodic_tx.v':['组合译码编号1～10为duty和Vin；非法编号给默认0且decode_valid=0，所有分支都有赋值。','控制域只在首个合法配置事件时保存完整48bit参数，此后保持到主机复位。','首个合法配置到来后保持请求，禁止后续配置覆盖已保存参数。','收到目的域确认后记录配置完成，只有主机复位清除。','首次合法配置时保存编号，后续编号不覆盖。','用户域寄存配置接受确认，避免组合确认直接进入跨域模块。','用户域仅第一次配置请求建立时记录已接收，主机复位清除。','用户域在首次请求到达时保存完整跨域参数，避免duty和Vin来自不同配置。','持续同步2µs翻转事件并保存上一拍值；链路暂停时也跟踪，不累存旧事件。','配置和链路有效后等待4个用户时钟才开放发送，失效时重新计数。','事件到来且ready有效时开始四拍；各拍只随握手推进，反压保持，失效立即回空闲。','用户时钟沿保存四拍发送状态，低有效复位回IDLE。','仅已配置、链路有效且恢复等待结束时累计忙/反压跳过次数；32bit自然回绕，不补发。'],
'rtds_fpga_1g_init.v':['25MHz初始化时钟沿累加到255后保持，复位重新从0开始。','初始化域先在计数128后解除GT复位，再在255后解除协议核复位；输出均由寄存器形成。'],
'rtds_rx_block_writer.v':['计算单拍写次态：请求被busy接受后给数据，数据accept后等最终done，响应结束才回空闲。','业务时钟沿保存写次态，低有效复位回IDLE。','独立计接收周期，到PERIOD_CYCLES末拍归零，不因写响应延迟而停计时。','周期到期置结束处理标志，直到剩余单字和全部写响应处理完才清除。','记录是否保存了一个待配对低32bit字；启动写拍后清标志，输入有效字时切换。','只在没有旧半字时保存新输入低32bit，供第二个字配对或周期末尾写入。','开始写入时整体保存数据、WSTRB和有效字节数；双字为FF/8Byte，尾字为0F/4Byte。','仅成功的最终响应增加有效字节数，块变可读后从0计下一块。','非空块变可读后移动下一写块，利用有限位宽循环使用块编号。','CPU确认现有可读块后移动最早待读块编号；读清通知不移动。','按块变可读和CPU确认增减数量，两者同拍发生时数量不变。','每个非空块变可读后递增顺序号，空周期不占用编号。','块变可读时保存其成功写入长度，复位逐项清全部长度表。','块变可读时保存其顺序编号，复位逐项清全部编号表。','累加被拒绝或写失败的32bit字数，33bit中间和溢出时保持FFFFFFFF。','从空变为有块时通知CPU；确认后依据剩余块保持通知，读清只清通知不释放块。'],
'rtds_rx_frame_fifo.v':['旧长度错误端口保留兼容，用户复位和运行时都固定为0，不据SOF/EOF拒收数据。','接收有效但未允许、FIFO满或写复位忙时每拍计丢1字，达到FFFFFFFF后不回绕。'],
'rtds_sync_timebase.v':['250MHz沿同时推进两个计数；2µs计数归零时翻转事件，50µs计数产生6250高/6250低，复位同时清输出。']}

EXACT={
'clk_250m':'250MHz业务/时间基准时钟','clk_100m':'100MHz板载或初始化参考时钟','clk_156m':'156.25MHz时钟输出','sys_rst':'高有效系统复位','rst_n':'低有效全局复位输入','fdma_rstn':'FDMA域低有效复位','user_rstn':'用户域低有效复位','s_axi_aresetn':'业务AXI低有效复位','ddr_sys_rst_n':'DDR系统低有效复位','converter_reset_n':'存储侧共同低有效复位条件','src_clk':'源时钟域时钟','dst_clk':'目的时钟域时钟','src_data':'源域保持的成组数据','dst_data':'目的域收到的完整成组数据','src_send':'源域提交请求','dst_req':'目的域配置请求已到达','dst_ack':'目的域已接收的返回确认','src_rcv':'源域收到目的端接受确认','rst_async_n':'外部低有效异步复位','rst_sync_n':'本时钟域同步解除后的低有效复位',
'SYS_CLK':'输入时钟频率，单位Hz','RD_TEMP_CYCLE':'SYSMON操作周期，单位µs','LED_CYCLE':'LED完整指示周期，单位µs','CYCLE':'由时钟频率和µs参数换算的周期拍数','FRAME_BYTES':'单帧字节数，当前16Byte','MEM_WINDOW_BYTES':'发送所使用的存储字节范围','ACTIVE_WINDOW_BYTES':'允许的下行数据字节范围','CARD_ADDR_HI':'卡端地址高32bit，当前使用0','RX_PERIOD_CYCLES':'上行接收周期拍数，生产值25000000','PERIOD_CYCLES':'接收周期拍数，生产250MHz对应100ms','BLOCK_BYTES':'每个上行块的字节容量','BLOCK_COUNT':'循环使用的上行块数量','BASE_ADDR':'第一个上行块的DDR字节地址','FIFO_DEPTH':'FIFO可保存的数据拍数','TIMEOUT_CYCLES':'无进展等待的诊断阈值拍数','FDMA_TIMEOUT_CYCLES':'FDMA持续无进展的诊断阈值拍数','AXI_ADDR_WIDTH':'AXI字节地址位宽','AXI_DATA_WIDTH':'AXI数据位宽','AXI_ID_WIDTH':'AXI事务ID位宽','ADDR_WIDTH':'模型字节地址位宽','DATA_WIDTH':'数据位宽','ID_WIDTH':'事务ID位宽','MEM_BYTES':'行为RAM总字节容量','INDEX_BITS':'由存储字数或块数计算的索引位宽','BYTE_BITS':'数据拍内部字节位置位宽','STRB_WIDTH':'每拍字节使能位数','WORDS':'行为RAM可存放的数据拍数量','mem':'按数据拍保存的行为RAM数组','byte_index':'按WSTRB逐字节操作的循环索引',
'CPU_WR_DONE':'下行命令忙状态，结束事件清零','CPU_REC_STATE':'写1形成的单拍CPU读完确认','CPU_WR_DONE_EVENT':'下行成功、拒绝或中止的命令结束事件','CPU_WR_DONE_resp':'下行业务任务响应忙状态','CPU_FPGA_START_ADDR':'软件配置的下行DDR起始字节地址','CPU_FPGA_LEN':'软件配置的下行字节长度','FPGA_CPU_START_ADDR':'最早待读块的DDR字节地址','FPGA_CPU_LEN':'最早待读块成功写入的字节长度','DDR_STATUS_W':'DDR就绪、校准和错误状态输入','FPGA_TEMP_W':'温度原始码及busy组成的状态输入','RX_READY_BLOCKS':'完整待读块数量','RX_HEAD_SEQ':'最早待读块的顺序编号','RX_DROPPED_FRAMES':'累计丢失32bit字数，端口名保留历史命名','VERSION':'软件只读版本常量','PROG_TIME':'软件只读构建标识常量','CH_BUF_LEN':'单个上行块的字节容量常量','FPGA_TEMP_W':'温度原始码和busy组合状态',
'aw_en':'当前是否允许接受下一次寄存器写','slv_reg_wren':'本次AXI-Lite写已满足地址和数据接受条件','slv_reg_rden':'本次AXI-Lite读可以保存返回数据','reg_data_out':'按保存地址译码的寄存器读值','CPU_WR_DONE_d':'上一拍下行命令忙位','CPU_WR_DONE_pos':'下行忙位0到1的启动事件','INT_STATE_R':'读取0x10形成的单拍清通知','CLEAR_INTER_R':'读取0x10形成的单拍清相关错误','byte_index_CPU_FPGA_START_ADDR':'按写字节使能更新起始地址的循环索引','byte_index_CPU_FPGA_LEN':'按写字节使能更新长度的循环索引',
'den_in':'SYSMON DRP操作使能','dwe_in':'SYSMON DRP写使能，当前与den_in同拍','daddr_in':'SYSMON DRP地址，复位清0后保持','di_in':'SYSMON DRP写数据，复位清0后保持','cnt_time':'温度操作周期拍计数','busy':'当前模块忙或周期操作提示','temp':'SYSMON返回的16bit温度原始码','led_cnt':'LED半周期拍计数','o_led':'周期翻转的LED输出','i_sys_clk':'本模块业务时钟','i_sys_rst':'本模块高有效复位',
'tx_active':'当前下行业务任务有效','tx_target_frames':'当前下行批量目标帧数','tx_completed_frames':'当前任务已经接受完成事件的帧数','tx_base_addr_lo':'当前任务锁定的DDR低32bit起始地址','tx_recovering':'旧读和跨域事件尚在清理，禁止新任务立即启动','tx_quiet_count':'旧读结束及用户停止确认后的连续安静拍数','tx_user_quiet_fdma':'用户发送桥停止确认已同步回FDMA域','tx_user_quiet':'用户域看到任务无效且发送桥复位的确认','tx_deliver_enable':'当前数据可进入发送桥和Byte1配置提取','tx_bridge_rareq':'发送桥提出的原始读请求，仍需adapter门控','tx_bridge_rready':'发送桥正常接收读数据许可','tx_recovery_aborted':'当前清理来自异常退出，不能暂存下一命令','tx_restart_pending':'正常结束期间已保存一条等待启动的命令','tx_deferred_base':'等待命令的起始地址快照','tx_deferred_frames':'等待命令的总帧数快照','tx_defer_accept':'正常结束清理阶段接受一条合法下一命令','tx_start_valid':'可以实际启动当前或等待命令的条件','tx_config_valid':'地址、长度和范围满足下行请求要求','tx_config_error_event':'非法请求或不允许的重复启动事件','tx_start_link_error':'启动时完整就绪未成立的错误事件','tx_requested_end':'请求末端地址的33bit中间值','tx_window_end':'允许下行地址范围的末端','tx_addr_aligned':'起始地址为16Byte对齐','tx_len_aligned':'长度为16Byte整数倍','requested_frames_32':'由字节长度除16得到的帧数','tx_fdma_reset_pipe':'发送桥FDMA侧同步解除复位管线','tx_user_reset_pipe':'发送桥用户侧同步解除复位管线','tx_fdma_rstn':'发送桥FDMA侧低有效复位','tx_user_rstn':'发送桥用户侧低有效复位','tx_active_user':'当前任务有效标志已同步到用户域','tx_done_toggle_user':'用户域每完成一帧翻转的事件标志','tx_done_toggle_fdma':'完成翻转标志已同步到FDMA域','tx_done_toggle_fdma_d':'上一拍同步完成翻转标志','tx_frame_done_fdma':'FDMA域恢复的单拍帧完成事件','tx_frame_done_user':'用户域当前帧完成单拍','config_read_beat':'帧内读拍位置，0表示下一拍提取Byte1',
'cfg_byte':'首读拍Byte1配置编号','cfg_byte_valid':'该帧首读拍被实际接受的配置事件','cfg_hold':'源域首次合法配置的完整48bit参数','cfg_user':'用户域已经接收并锁定的完整48bit配置','cfg_req':'首次合法配置请求已提交并保持','cfg_send':'源端配置握手提交许可','cfg_ack':'用户域已接收首次配置','cfg_dest_ack':'用户域寄存后的配置接受确认','cfg_cdc_data':'XPM传递到目的侧的完整48bit参数','req_sync':'目的域收到的配置请求','ack_sync':'返回源域的配置确认','configured':'首次配置跨域确认已完成','configured_id':'首次合法配置编号','decoded_duty':'编号查表得到的16bit占空比整数','decoded_vin':'编号查表得到的32bit电压定点值','decode_valid':'编号处于合法1～10范围','tick_toggle_2us':'250MHz域每2µs翻转一次的事件标志','tick_sync':'用户域同步的两级事件翻转位','tick_seen':'用户域上一拍同步翻转位','period_tick':'用户域恢复出的单拍周期事件','arm_count':'链路与配置有效后的4拍启动等待计数','skipped_periods':'忙或反压遇周期事件的32bit跳过计数','cpu_sync_50us':'50µs GPIO输出，高低各25µs','count_2us':'500拍源事件计数','count_50us':'12500拍GPIO周期计数',
'write_block':'当前写入块编号','read_block':'最早可读且待CPU确认的块编号','queued':'完整待读块数量','block_len':'各块成功写入字节长度表','block_seq':'各块对应的完成顺序号表','used_bytes':'当前块已得到成功写响应的字节数','publish_seq':'下一个非空完成块使用的顺序号','time_count':'与写响应等待独立的接收周期计数','seal_pending':'周期已结束，但尾字或写响应尚未处理完','half_valid':'已有一个待配对的32bit字','half_data':'先到的低32bit字，配对时放写拍低半','active_transfer':'本次写拍的有效字节数、WSTRB和64bit数据','tick':'接收周期到期的单拍事件','take_word':'输入valid和ready同拍成立，取得一字','reject_word':'取得的字因未允许或无空间被舍弃','pair_start':'已有半字时与新字组成完整写拍','tail_start':'周期末把未配对单字组成0F尾拍','start_write':'完整拍或尾拍需要发起写入','seal_done':'周期所需写入和尾字已全部处理完','push_block':'成功非空块登记为可读','pop_block':'CPU确认并释放最早可读块','write_success':'最终done且无error的成功响应','write_failure':'最终done且error的失败响应','drop_sum':'丢字33bit中间和，用于判断32bit饱和','len_index':'复位清块长度表的循环索引','seq_index':'复位清顺序号表的循环索引',
'fifo_write':'RX有效且允许、未满、复位不忙时写FIFO','fifo_read':'数据有效且下游接受时取FIFO当前拍','fifo_input':'原始64bit接收数据，不在此模块丢弃高半','fifo_reset':'FIFO高有效复位','user_rst_n':'用户时钟域同步解除后的低有效复位','src_rst_n':'源时钟域同步解除后的低有效复位','wr_busy':'FIFO写侧复位仍在进行','rd_busy':'FIFO读侧复位仍在进行','full_user':'FIFO用户写侧满状态','almost_full_user':'FIFO用户写侧接近满状态','empty_mem':'FIFO存储读侧空状态','drop_bin':'用户域累计丢失32bit字数，达到最大值后保持',
'recovery_read_pending':'AR已接受，最后R尚未被业务侧接受','recovery_write_pending':'AW已接受，B尚未被业务侧接受','recovery_read_abort':'旧读发生存储失效，剩余拍须返回错误','recovery_write_abort':'旧写发生存储失效，剩余W不再进入存储','recovery_read_left':'尚未装入业务响应寄存器的读拍数，9bit支持256拍','recovery_write_left':'原突发尚未从业务侧接受的写拍数，9bit支持256拍','recovery_read_id':'AR接受时保存的原ID','recovery_write_id':'AW接受时保存的原ID','recovery_rslot':'R保持寄存器为空或旧拍正在被接受，可装下一拍','recovery_rload':'可以装入真实R或补齐的错误R','recovery_bload':'全部原W已接收且可以装入一次B','recovery_read_fault':'旧读已标记失效或存储当前不可用','recovery_write_fault':'旧写已标记失效或存储当前不可用','storage_ready':'模型或MIG校准与存储接口实际可用','outstanding_reads':'AR接受后尚未收完最后R的事务数','outstanding_writes':'AW接受后尚未接受B的事务数','timeout_count':'在途事务连续无握手进展的拍数','ready_seen':'曾经观察到业务DDR就绪','any_pending':'存在尚未结束的读或写事务','any_progress':'AXI五通道任一实际握手发生','sim_ready_pipe':'RAM配置复位解除后的两拍就绪管线','ui_clk':'MIG输出的用户时钟','ui_clk_sync_rst':'MIG用户域高有效复位请求','mig_calib_complete':'真实MIG校准完成','ui_reset_pipe':'MIG用户域两拍接口复位解除管线','ui_axi_aresetn':'MIG用户域接口已同步解除复位','ready_sync':'MIG接口可用标志同步到业务域的管线','converter_s_reset_pipe':'业务侧转换器16拍复位解除管线','converter_m_reset_pipe':'MIG侧转换器16拍复位解除管线','converter_ready_sync':'MIG侧转换器复位解除确认同步回业务域',
'wa':'当前写突发的字节地址','ra':'当前读突发的字节地址','wleft':'整次FDMA写尚未响应完成的拍数','rleft':'整次FDMA读尚未接受完成的拍数','wb':'当前写段拍数，1～256','rb':'当前读段拍数，1～256','wbeat':'当前写段已接受拍位置','rbeat':'当前读段已接受拍位置','aw_pending':'当前段AW尚未接受','w_pending':'当前段W尚未收完','whs':'AXI W实际接受事件','rhs':'AXI R实际接受事件','AW_HS':'AXI写地址接受事件','ar_hs':'AXI读地址接受事件','aw_hs':'AXI写地址接受事件','w_hs':'AXI写数据接受事件','r_hs':'AXI读数据接受事件','b_hs':'AXI写响应接受事件',
'startup_count':'1G初始化计数，255后保持','init_rst_n':'初始化时钟域同步解除后的复位','init_clk':'25MHz专用分频初始化时钟','gt_reset':'GT高有效复位，早于协议核解除','core_reset':'1G协议核高有效复位','sys_rst_sync':'初始化域高有效复位同步管线','state_dbg':'上电复位顺序状态','count_dbg':'当前复位阶段拍计数','pma_init':'PMA高有效初始化复位','reset_pb':'10G协议核高有效复位','frame_cnt':'用户域已发送完整帧数量','burst_cnt':'FDMA域已结束读突发数量','rd_word_cnt':'当前读突发的实际接受拍位置','rd_addr':'发送桥相对读地址','tx_word_cnt':'当前发送帧内拍位置','rd_state':'读请求状态机当前状态','rd_state_nxt':'组合计算的下一读状态','tx_state':'LocalLink发送当前状态','tx_state_nxt':'组合计算的下一发送状态','tx_hs':'用户域发送valid/ready实际握手','rd_data_hs':'FDMA有效读拍实际接受','rd_burst_done':'当前FDMA读突发完成','wr_burst_done':'当前帧最后数据拍已经发送',
}

BAD=['事务寄存器按原状态','组合接口映射','握手条件供本时钟域','连接本级与上下游','2026-10-11','接口允许时接收','按所属事务保持','原生时钟域','例化','input wire','output wire']
EXACT.update({
'rd_start':'INFO_EXCH发出的单拍下行启动命令','cpu_wr_done_event':'本条下行命令结束单拍，成功/拒绝/失效均可能触发','int_state_w':'当前待读块的通知状态','int_state_clear':'软件读0x10形成的清通知单拍','clear_inter':'软件读0x10形成的清相关错误单拍','clear_status':'软件读0x10形成的清诊断请求，不清事务记录','ddr_ready':'存储接口可用且旧读写错误事务已结束，可接收新业务','cpu_rec_state_r':'软件写0x14形成的CPU读完确认','cpu_rec_state_w':'CPU确认状态返回寄存器侧','fpga_cpu_irq_req':'有待读块时向XDMA申请中断','rx_ready_blocks':'已经完整写入且等待CPU读取的块数量','rx_head_seq':'最早待读块的顺序编号','rx_dropped_frames':'FIFO和块写统计的累计丢失32bit字数','dbg_rx_state':'上行块写模块当前状态','dbg_tx_state':'下行桥当前状态','ddr_ready_user':'DDR业务ready同步到Aurora用户域','tx_fdma_raddr_raw':'发送桥给出的相对DDR读字节地址','tx_fdma_dbg_bus':'发送桥FDMA侧状态和FIFO写侧统计','tx_user_dbg_bus':'发送桥用户侧状态和FIFO读侧统计','rx_packet':'异步FIFO送到DDR域的原始64bit接收拍','fifo_drops':'接收FIFO累计丢失32bit字数','writer_drops':'块空间不足或写响应失败的累计丢字','rx_length_error_raw':'RX FIFO保留的长度错误兼容输出','cpu_rec_state_d':'上一拍CPU确认位，用于检测0到1变化','dropped_frames_previous':'上一拍合计丢字，用于检测新增加的丢字','fifo_drops_previous':'上一拍FIFO丢字计数','rx_overrun_flag':'块空间或写入失败引起的新丢字保持标志','status_clear_toggle_fdma':'软件每次清错翻转的源事件位','status_clear_toggle_user':'同步到用户域的清错翻转位','status_clear_toggle_user_d':'用户域上一拍清错翻转位','status_clear_user':'用户域检测到的单拍清错事件','rx_in_frame':'用户域接收当前处于SOF和EOF之间','rx_frame_word_count':'用户域接收帧内实际接受的拍数','rx_length_error_fdma':'用户长度错误同步到FDMA域的兼容状态','fdma_wait_count':'FDMA连续等待且无进展的拍计数','user_status_clear_hold':'等待用户域旧错误清除反馈，避免旧高电平重新置错','c0_ddr4_cke':'DDR4时钟使能输出','c0_ddr4_odt':'DDR4片内终端电阻控制输出'})
GROUPS={'storage_ready':'存储侧AXI通道连接；业务侧恢复状态另行保存。','recovery_read_pending':'已接受事务的长度、ID和中断状态。','recovery_rvalid':'业务侧R/B响应保持寄存器；反压时字段不能改变。','outstanding_writes':'未结束事务数量和超时诊断。','sim_ready_pipe':'行为RAM分支的就绪与接口连接。','ui_clk':'真实MIG分支的时钟、校准和复位。','converter_s_reset_pipe':'Clock Converter两侧分别同步解除复位。','cc_s_awready':'Clock Converter业务侧AXI字段。','m_awid':'MIG用户时钟域AXI字段。','pcie_link_up_user':'将PCIe、DDR和Aurora就绪分别同步到使用域。','tx_active':'下行任务地址、目标帧数和完成统计。','tx_recovering':'旧任务隔离、停止确认和下一命令暂存。','tx_fdma_reset_pipe':'发送桥两侧同步解除的本地复位。','tx_fdma_raddr_raw':'发送桥的地址、调试状态和跨域完成事件。','rx_packet':'上行异步FIFO数据、块写接口及丢字统计。','cpu_rec_state_d':'CPU读完确认的单拍检测。','status_clear_toggle_fdma':'软件清错事件的翻转跨域传递。','rx_in_frame':'用户域帧观察和错误状态。','rx_overflow_sticky_r':'FDMA域错误保持与软件清除。','fdma_waiting':'等待/进展判断；仅持续无进展时累计超时。'}
EXACT.update({'locked':'时钟IP输出锁定状态，未锁定时保持系统复位','gt_pll_lock_i':'10G GT PLL锁定状态','sfp_tx_disable':'SFP发送禁止控制，当前固定允许发送','sfp_rs0':'SFP速率选择控制位0','sfp_rs1':'SFP速率选择控制位1','tx_src_vld':'10G LocalLink发送有效，随当前拍保持','rx_src_vld':'10G LocalLink接收有效','dbg_fdma_bus':'发送桥FDMA域读状态、计数和FIFO状态集合','dbg_user_bus':'发送桥用户域帧状态、计数和FIFO状态集合','tx_frame_done':'用户域帧尾实际接受后的完成事件','fifo_wr_en':'读数据实际接受时写异步FIFO','fifo_rd_en':'LocalLink发送握手时取走FIFO当前拍','wr_en':'异步FIFO写使能','rd_en':'异步FIFO读使能','fifo_wdata':'异步FIFO写入的64bit读数据','fifo_rdata':'异步FIFO当前64bit输出拍','fifo_wr_cnt':'FDMA域观察的FIFO存储拍数','fifo_rd_cnt':'用户域观察的FIFO存储拍数','rd_data_phase':'当前读数据阶段，包含请求刚被busy接受的周期','dbg_state':'当前写事务状态供调试观察','M_AXI_ID':'本AXI主机固定事务ID数值','M_AXI_ID_WIDTH':'本AXI主机事务ID位宽','M_AXI_ADDR_WIDTH':'本AXI主机字节地址位宽','M_AXI_DATA_WIDTH':'本AXI主机数据位宽','write_curr_st':'当前写事务状态','read_curr_st':'当前读事务状态','address':'计算分段长度时使用的当前字节地址','remaining':'整次请求剩余数据拍数','available':'当前地址距4KiB末端可容纳的拍数','write_len_minus_one':'当前写段拍数减1，形成AXI AWLEN','read_len_minus_one':'当前读段拍数减1，形成AXI ARLEN','r_INT_STATE':'软件读0x10形成的清通知输出','r_CLEAR_INTER':'软件读0x10形成的清相关错误输出','r_CPU_REC_STATE':'软件写0x14形成的一拍读完确认','r_RD_START':'0x20忙位0到1形成的一拍下行启动','r_CPU_FPGA_START_ADDR':'保存的下行起始DDR字节地址输出','r_CPU_FPGA_LEN':'保存的下行字节长度输出','user_lnk_up':'XDMA报告PCIe链路已经建立','user_lnk_up_int':'XDMA链路状态内部连接','fdma_w_accept':'CONV_DMA已接受当前写拍，映射至adapter写接收输入','rx_pending':'至少有一个完整上行块等待CPU读取确认','adapter_tx_state_dbg':'adapter发送状态调试值','adapter_rx_state_dbg':'adapter块写状态调试值','ddr_init_calib_complete':'后端DDR校准完成状态','aurora1g_configured':'实际1G首次配置已确认','aurora1g_configured_id':'实际1G保存的首次合法编号','aurora1g_skipped_periods':'实际1G因忙或反压跳过的周期数','aurora1g_tx_data':'1G当前32bit发送拍，先发字节在高位','FPGA_TEMP_BUSY_W':'SYSMON周期操作busy状态','led':'LED周期指示输出'})
for n,t in {'act_n':'行激活控制，低有效','adr':'行列复用地址','ba':'Bank地址','bg':'Bank组地址','cs_n':'片选，低有效','ck_t':'差分时钟正端','ck_c':'差分时钟负端','dm_dbi_n':'双向字节掩码/DBI','dq':'双向数据线','dqs_c':'双向选通负端','dqs_t':'双向选通正端'}.items():EXACT['c0_ddr4_'+n]='DDR4'+t
for n,t in {'RXP':'GT接收差分正端','RXN':'GT接收差分负端','TXP':'GT发送差分正端','TXN':'GT发送差分负端','GTHQ0_P':'GT参考差分时钟正端','GTHQ0_N':'GT参考差分时钟负端','pcie_mgt_rxn':'PCIe GT接收差分负端','pcie_mgt_rxp':'PCIe GT接收差分正端','pcie_mgt_txn':'PCIe GT发送差分负端','pcie_mgt_txp':'PCIe GT发送差分正端','aurora_rxp':'10G GT接收差分正端','aurora_rxn':'10G GT接收差分负端','aurora_txp':'10G GT发送差分正端','aurora_txn':'10G GT发送差分负端','aurora1g_rxp':'1G GT接收差分正端','aurora1g_rxn':'1G GT接收差分负端','aurora1g_txp':'1G GT发送差分正端','aurora1g_txn':'1G GT发送差分负端'}.items():EXACT[n]=t
REPLACE={'粘滞':'保持至清除的','封存':'完成本周期写入','发布':'登记为可读','消费':'处理','门铃':'启动命令','窗口':'地址范围','积压':'尚未处理的数据','队头':'最早待读块','单写者':'唯一写入模块','单消费者':'单个读取方','单读取':'单个读取方'}
def plain(s):
    s=re.sub(r'^(?:2026-\d\d-\d\d[:：]?\s*)','',s.strip())
    for a,b in REPLACE.items():s=s.replace(a,b)
    return s.rstrip('。;；')
def strip(s,keep_pragmas=False):
    def replace(m):
        if m[0].startswith('"'):return m[0]
        if keep_pragmas and re.match(r'//\s*(?:synthesis|synopsys|pragma|verilator)\b',m[0]):return m[0]
        return re.sub(r'[^\n]',' ',m[0])
    return re.sub(r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*.*?\*/',replace,s,flags=re.S)
def top_split(s):
    out=[];st=0;depth=0;string=False;escape=False
    for i,c in enumerate(s):
        if string:
            if escape:escape=False
            elif c=='\\':escape=True
            elif c=='"':string=False
            continue
        if c=='"':string=True
        elif c in '([{':depth+=1
        elif c in ')]}':depth-=1
        elif c==',' and depth==0:out.append(s[st:i]);st=i+1
    return out+[s[st:]]
def expand_declarations(s):
    pat=r'(?m)^([ \t]*)(wire|reg|logic|integer|localparam)\s+([^\n;]+);'
    def convert(m):
        parts=top_split(m[3])
        if len(parts)==1:return m[0]
        first=parts[0];p=re.match(r'((?:(?:signed|unsigned|integer|logic|reg)\s+)?(?:\[[^]]+\]\s*)?)([A-Za-z_]\w*.*)',first)
        if not p:return m[0]
        return '\n'.join(m[1]+m[2]+' '+p[1]+v.strip()+';' for v in [p[2]]+parts[1:])
    return re.sub(pat,convert,s)
def tokens(s):
    s=expand_declarations(strip(s))
    return re.findall(r'"(?:\\.|[^"\\])*"|\\\S+|[A-Za-z_$][\w$]*|\d+\s*\x27[sS]?[hHdDbBoO][0-9a-fA-F_xXzZ?]+|\d+(?:\.\d+)?|\S',s)
def declaration_name(s):
    m=re.match(r'\s*(?:\(\*.*?\*\)\s*)?(?:input|output|inout|wire|reg|logic|integer|parameter|localparam)\s+(?:(?:wire|reg|logic|integer|real|signed|unsigned)\s+)*(?:\[[^]]+\]\s*)?([A-Za-z_]\w*)',s)
    return m[1] if m else None
def output_name(s):
    m=re.match(r'\s*assign\s+([A-Za-z_]\w*)',s);return m[1] if m else None
def mean(name,old='',code=''):
    if name in EXACT:return EXACT[name]
    for k,v in EXACT.items():
        if k.lower()==name.lower():return v
    old=plain(old)
    if old and not any(x in old for x in BAD) and re.search(r'[\u4e00-\u9fff]',old) and len(old)<95:return old
    n=name.lower();base=n
    for prefix,title in [('cc_s_','时钟转换器业务侧'),('cc_m_','时钟转换器MIG侧'),('m_','MIG用户域')]:
        if n.startswith(prefix):return title+mean(n[len(prefix):])
    if n.endswith('_nc'):return '未使用的'+n[:-3]+'输出，仅保留接口连接'
    if n.startswith('mem_'):base=n[4:]
    if 'axi_' in n:base=n.split('axi_',1)[1]
    if base in ('awaddr','araddr'):return ('写' if base=='awaddr' else '读')+'突发起始字节地址'
    for channel,txt in [('aw','写地址'),('ar','读地址'),('w','写数据'),('b','写响应'),('r','读数据')]:
        if base==channel+'valid':return txt+'通道有效，保持到ready接受'
        if base==channel+'ready':return txt+'通道当前可接受'
        if base==channel+'id':return txt+'事务ID'
        if base==channel+'len':return txt+'突发拍数减1'
        if base==channel+'size':return txt+'每拍字节数的log2编码'
        if base==channel+'burst':return txt+'地址类型，INCR为逐拍递增'
        if base==channel+'resp':return txt+'响应码，0为OKAY、2为SLVERR'
        if base==channel+'last':return txt+'最后一拍标志'
        if base==channel+'data':return txt+'当前数据'
        if base==channel+'strb':return '写数据逐字节使能，尾字仅低4位'
        if base.startswith(channel) and base[len(channel):] in ('lock','cache','prot','qos','region'):return txt+'通道'+base[len(channel):]+'属性'
    if n.startswith('fdma_'):
        suffix=n[5:]
        names={'raddr':'读起始字节地址','waddr':'写起始字节地址','rsize':'读请求64bit拍数','wsize':'写请求64bit拍数','rareq':'读请求，保持到busy接受','wareq':'写请求，保持到busy接受','rbusy':'读请求仍在处理','wbusy':'写请求仍在处理，包含等待响应','rdata':'当前读数据','wdata':'当前写数据','rvalid':'读数据已接受事件','rready':'读数据接收许可','wvalid':'写有效/接受信号，方向含义见模块头','wready':'写接受/有效信号，方向含义见模块头','wdone':'本次写最终响应完成单拍','werror':'本次写错误，与done共同判断','wstrb':'写字节使能，完整FF、尾字0F'}
        if suffix in names:return names[suffix]
    if n.startswith('recovery_r'):return '恢复逻辑保持的R通道'+n.removeprefix('recovery_r')+'字段'
    if n.startswith('recovery_b'):return '恢复逻辑保持的B通道'+n.removeprefix('recovery_b')+'字段'
    if n.startswith('ram_'):return '行为RAM侧'+mean(n[4:])
    if n.startswith('mem_'):return '实际存储侧'+mean(n[4:])
    if n in ('tx_data','tx_d','aurora_tx_d','rx_data','rx_d','aurora_rx_d','frame_data'):return ('发送' if 'tx' in n else '接收')+'当前数据拍'
    if n.endswith('sof'):return '当前帧首拍标志，与有效/接受共同使用'
    if n.endswith('eof'):return '当前帧末拍标志，与有效/接受共同使用'
    if n.endswith('rem'):return '当前拍有效字节数减1'
    if 'clk' in n:return '对应接口时钟，使用域由连接关系确定'
    if 'rst' in n or 'reset' in n:return ('低' if n.endswith(('n','_n')) else '高')+'有效复位或同步复位状态'
    if n.endswith('valid') or 'src_rdy' in n:return '当前数据/事件有效'
    if n.endswith('ready') or 'dst_rdy' in n:return '当前通道可接受数据或业务'
    if 'channel_up' in n or 'lane_up' in n or 'link_up' in n:return '对应链路就绪状态，跨域副本按后缀区分'
    if 'sticky' in n:return '相应错误出现后保持为1，直到软件清除或复位'
    if 'overflow' in n:return '对应FIFO不能保存新输入的溢出状态'
    if 'underflow' in n:return '对应FIFO读侧无数据的错误状态'
    if 'almost_full' in n:return 'FIFO接近满，需暂停继续输入'
    if 'almost_empty' in n:return 'FIFO剩余数据接近空'
    if 'full' in n:return 'FIFO当前已满'
    if 'empty' in n:return 'FIFO当前为空'
    if n in ('bready','rready','awready','wready','arready'):return '对应AXI通道当前接受许可'
    if name.upper()==name:
        if '=' in code:return '本模块'+name+'固定配置/状态编码'
    if '=' in code and code.count('=')==1:
        expr=code.split('=',1)[1].strip(' ;')
        if len(expr)<60:return '由'+expr+'确定的'+name+'条件/值'
    return '用于'+name+'的数据、控制或状态，见同名连接和更新块'

def format_named_ports(s):
    # Split only named parameter/port separators. No identifiers or expressions change.
    return re.sub(r',\s*(?=\.[A-Za-z_]\w*\s*\()',',\n        ',s)

checks=[]
import sys
selected=set(sys.argv[sys.argv.index('--only')+1].split(',')) if '--only' in sys.argv else None
for item in M:
    path=item['path'];name=Path(path).name
    if selected and name not in selected:continue
    raw=(D/path).read_text('utf-8-sig');s=strip(raw,keep_pragmas=True)
    assert name in HEAD,name
    # Retain synthesis directives whose meaning is carried by comments.
    directives=[l.strip() for l in raw.splitlines() if re.search(r'//\s*(?:synthesis|synopsys|pragma|verilator)\b',l)]
    old={}
    for line in raw.splitlines():
        if '//' in line:
            code,c=line.split('//',1);n=declaration_name(code) or output_name(code)
            if n and n not in old:old[n]=c
    s=expand_declarations(s);s=format_named_ports(s)
    lines=[l.expandtabs(4).rstrip() for l in s.splitlines()]
    # Put every header item on its own line without changing inherited Verilog types.
    split=[]
    for line in lines:
        if re.match(r'\s*(?:input|output|inout|parameter)\b',line):
            parts=top_split(line.strip())
            meaningful=[x for x in parts if x.strip()]
            if len(meaningful)>1:
                indent=' '*(len(line)-len(line.lstrip()))
                trailing=not parts[-1].strip()
                split.extend(indent+x.strip()+(',' if i<len(meaningful)-1 or trailing else '') for i,x in enumerate(meaningful))
                continue
        split.append(line)
    lines=split
    # Make the declaration names/widths readable while retaining explicit keyword choice.
    for i,l in enumerate(lines):
        m=re.match(r'^(\s*)((?:input|output|inout|wire|reg|logic|integer|parameter|localparam)\s+(?:(?:wire|reg|logic|integer|real|signed|unsigned)\s+)*)(\[[^]]+\]\s*)?([A-Za-z_]\w*)(.*)$',l)
        if m:
            lines[i]=m[1]+' '.join(m[2].split()).ljust(14)+(m[3] or '').strip().ljust(29)+m[4]+m[5]
    # Wrap long declarative/assign expressions rather than pushing every comment far right.
    wrapped=[]
    for l in lines:
        if len(l.rstrip())>95 and re.match(r'\s*(?:wire|reg|assign)\b',l) and '=' in l and ';' in l:
            left,expr=l.split('=',1)
            wrapped.append(left.rstrip()+' =')
            parts=re.split(r'\s*(&&|\|\|)\s*',expr.strip())
            current='        '
            for part in parts:
                if len(current)+len(part)+1>90 and current.strip():wrapped.append(current.rstrip());current='        '
                current+=part+' '
            wrapped.append(current.rstrip())
        else:wrapped.append(l)
    lines=wrapped
    # Identify all always bodies; body-level boilerplate was removed with old comments.
    code='\n'.join(lines);starts=list(re.finditer(r'\balways\b',code));descs=BLOCK.get(name,[])
    assert len(starts)==len(descs),(name,len(starts),len(descs))
    inserts={};block_spans=[]
    for i,m in enumerate(starts):
        begin=code.find('begin',m.end());depth=0;end=None
        for w in re.finditer(r'\b(begin|end)\b',code[begin:]):
            depth+=1 if w[1]=='begin' else -1
            if depth==0:end=begin+w.end();break
        line=code[:m.start()].count('\n');stop=code[:end].count('\n');block_spans.append((line,stop))
        indent=' '*(len(lines[line])-len(lines[line].lstrip()))
        inserts[line]=[indent+'// '+descs[i]]
    # Align declaration and assign semicolons in one file-wide column.
    eligible=[];assigning=False;decl_cont=False
    for i,l in enumerate(lines):
        if re.match(r'\s*assign\b',l):assigning=True
        decl=declaration_name(l)
        if decl and l.rstrip().endswith('='):decl_cont=True
        if ';' in l and (decl or assigning or decl_cont) and not any(a<=i<=b for a,b in block_spans):eligible.append(i)
        if assigning and ';' in l:assigning=False
        if decl_cont and ';' in l:decl_cont=False
    semi_col=max([75]+[len(lines[i].split(';',1)[0].rstrip()) for i in eligible])
    assigning=False;assign_name=None;decl_pending=None
    port_col=max([80]+[len(x.rstrip()) for x in lines if re.match(r'\s*(?:input|output|inout|parameter)\b',x)])+2
    for i,l in enumerate(lines):
        n=declaration_name(l)
        if n and not ';' in l and not re.match(r'\s*(?:input|output|inout|parameter)\b',l):decl_pending=n
        if re.match(r'\s*assign\b',l):assigning=True;assign_name=output_name(l)
        inblock=any(a<=i<=b for a,b in block_spans)
        if inblock:continue
        desc=None
        if decl_pending and ';' in l:
            desc=mean(decl_pending,old.get(decl_pending,''),l);decl_pending=None
        elif n and not (l.rstrip().endswith('=') and not ';' in l):
            desc=mean(n,old.get(n,''),l)
        elif assigning and ';' in l:
            desc=mean(assign_name,old.get(assign_name,''),l)
        if desc:
            if i in eligible:
                left,right=l.split(';',1);lines[i]=left.rstrip().ljust(semi_col)+';'+right.rstrip()+'    // '+desc
            else:lines[i]=l.rstrip().ljust(port_col if re.match(r'\s*(?:input|output|inout|parameter)\b',l) else semi_col+1)+'    // '+desc
        if assigning and ';' in l:assigning=False;assign_name=None
    # Numbered broad sections before modules and long state/control sections.
    final=[];module_added=False;last_kind=None;body=False
    for i,l in enumerate(lines):
        if i in inserts:
            while final and not final[-1].strip():final.pop()
            final.extend(['','']+inserts[i])
        if re.match(r'\s*module\b',l):
            while final and not final[-1].strip():final.pop()
            final.extend(['','// 模块参数与输入输出。']);module_added=True
        kind='assign' if re.match(r'\s*assign\b',l) else 'decl' if declaration_name(l) and re.match(r'\s*(?:wire|reg|logic|integer|localparam)\b',l) else None
        if kind and not any(a<=i<=b for a,b in block_spans):
            n=declaration_name(l) or output_name(l)
            if n in GROUPS:
                if len(final)>0 and final[-1].strip():final.append('')
                final.append('    // '+GROUPS[n])
            elif last_kind!=kind and kind=='assign':
                if len(final)>0 and final[-1].strip():final.append('')
        if kind:last_kind=kind
        elif l.strip() and not re.match(r'\s*(?:`|\.|\(|\)|#)',l):last_kind=None
        final.append(l)
    text='\n'.join(final)
    text=re.sub(r'\n[ \t]*\n(?:[ \t]*\n)+','\n\n\n',text).strip()+'\n'
    # Keep timescale/preprocessor defaults in their original order; put module explanation before them.
    header='\n'.join('// '+x for x in HEAD[name])+'\n'
    header+='// 注释整理 2026-10-12：仅修改说明和排版，端口、表达式、状态条件及连接保持。\n'
    if name=='pcie_fdma_aurora_brg_adapter.v':
        header+='// 功能修改 2026-10-11：旧读排空、用户停止确认、跨任务完成事件隔离及正常下一命令暂存。\n'
    if name=='rtds_ddr4_backend.sv':
        header+='// 功能修改 2026-10-11：记录原ID/拍数，DDR失效后补齐错误响应并保持已展示R/B。\n'
        header+='// 设计修改 2026-10-12：恢复同步链属性与定点约束；当前生效约束段在DDR4_PIN.xdc。\n'
    header+='\n'
    after=header+text
    # Mark the affected functionality once per section, not on every statement.
    if name=='pcie_fdma_aurora_brg_adapter.v':
        after=after.replace('用户就绪或任务无效时清管线','用户未就绪或任务无效时清管线')
        after=after.replace('// 旧任务隔离、停止确认和下一命令暂存。','// 2026-10-11修改：旧任务隔离、停止确认和下一命令暂存。')
        after=after.replace('// FDMA域产生发送桥复位：','// 2026-10-11修改：FDMA域产生发送桥复位：')
        after=after.replace('// 用户域产生发送桥复位：','// 2026-10-11修改：用户域产生发送桥复位：')
        after=after.replace('// 保持旧任务清理状态；','// 2026-10-11修改：保持旧任务清理状态；')
    if name=='rtds_ddr4_backend.sv':
        after=after.replace('// 已接受事务的长度、ID和中断状态。','// 2026-10-11修改：已接受事务的长度、ID和中断状态。')
        after=after.replace('// Clock Converter两侧分别同步解除复位。','// 2026-10-11修改：两侧分别同步解除复位；2026-10-12补同步链属性。')
    assert tokens(raw)==tokens(after),'Non-comment token change: '+path
    # No line-level comments are allowed within the simple always bodies.
    dest=A/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(after,'utf-8')
    checks.append({'path':path,'before_sha256':item['sha256'],'after_sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'token_equivalent':True,'always_blocks':len(starts),'before_lines':len(raw.splitlines()),'after_lines':len(after.splitlines()),'semicolon_column':semi_col,'generic_comment_fallbacks':sum('的数据、控制或状态，见同名连接' in x for x in after.splitlines())})
(B/'annotation_checks.json').write_text(json.dumps(checks,ensure_ascii=False,indent=2),'utf-8')
with zipfile.ZipFile(B/'core_annotations_after.zip','w',zipfile.ZIP_DEFLATED) as z:
    for x in checks:z.write(A/x['path'],x['path'])
    z.write(B/'annotation_checks.json','annotation_checks.json')
print(json.dumps({'files':len(checks),'always_blocks':sum(x['always_blocks'] for x in checks),'fallback_comments':sum(x['generic_comment_fallbacks'] for x in checks),'checks':checks},ensure_ascii=False))
