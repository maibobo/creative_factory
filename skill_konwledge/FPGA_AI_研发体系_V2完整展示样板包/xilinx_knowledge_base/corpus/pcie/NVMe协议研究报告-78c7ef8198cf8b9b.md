# NVMe协议研究报告

- Category: `pcie`
- Source: `E:\NVME_PRO\NVMe协议研究报告.doc`
- SHA-256: `78c7ef8198cf8b9b10389babba82d1339a30483ca023b01b0ed86e8ca11d43c9`
- Extractor: `libreoffice-text`
- Tags: `nvme, pcie, protocol`
- Duplicate sources:
  - none

1 NVMe 协议基础（队列、命令、PRP、LBA）
1.1 一句话理解 NVMe
NVMe 就是一套"怎么对 SSD 下命令"的规矩。
打个比方：SSD 是一个仓库，你往里存东西取东西。你不能直接闯进去翻，得按仓库管理员的规矩来——填一张"存单"或"取单"交给管理员，管理员帮你搬。NVMe 就是这张"单子"的格式，以及"怎么递单子、怎么拿回执"的完整流程。
1.2 队列：NVMe 的核心机制
1.2.1 什么是队列？为什么要用队列？
传统硬盘（SATA）一次只能处理一条命令，命令多了就排队等着。NVMe 不一样，它支持很多条命令同时排队，SSD 内部有多通道并行处理，性能大幅提升。
类比：SATA 像只有一个窗口的银行，所有人排一队；NVMe 像有几十个窗口的银行，每个人进哪个窗口、怎么排，靠队列管理。
1.2.2 两种队列
队列类型	全称	作用	形象比喻
SQ（Submission Queue）	提交队列	你把命令放进去，等 SSD 来取	“下单窗口”——你把单子放这
CQ（Completion Queue）	完成队列	SSD 干完活把回执放这	“取餐窗口”——SSD 把结果放这
关键：SQ 和 CQ 是成对出现的。一个 SQ 对应一个 CQ，叫"一对队列"。
1.2.3 队列长什么样？
队列就是一个环形数组，存在主机内存里：

SQ（提交队列）：
┌──────┬──────┬──────┬──────┬──────┬──────┐
│ 命令1│ 命令2│ 命令3│ (空) │ (空) │ (空) │
└──────┴──────┴──────┴──────┴──────┴──────┘
  ↑                              ↑
 Head                           Tail
(SSD 在读这里)              (你在这放新命令)


    • Head 指针：SSD 读到哪里了
    • Tail 指针：你写到哪里了
    • 当 Tail 追上 Head，说明队列满了（不能再放新命令）
    • CQ 结构类似，只是里面装的是"完成回执"
1.2.4 门铃（Doorbell）——通知机制
问题：你把命令放进 SQ 了，SSD 怎么知道有新命令？
答案：你要"按门铃"。
每个队列有一个 Doorbell 寄存器（在 SSD 的 PCIe 配置空间里）。你写一下 Tail 指针到 Doorbell，SSD 就知道"有新命令了，从上次读到的地方接着读"。
反过来，SSD 往 CQ 放了回执后，会给你发一个中断（MSI/MSI-X），或者你主动去查 CQ 的 Head 指针，看有没有新回执。
类比：
    • 你下单 → 把单子放 SQ → 按 Doorbell 门铃通知服务员
    • 服务员做好 → 把餐放 CQ → 按叫号器（中断）通知你
1.2.5 Admin 队列 vs I/O 队列
有两种级别的队列：
类型	数量	用途	比喻
Admin 队列	只有 1 对	管理用（创建 I/O 队列、查询 SSD 信息、格式化等）	“经理办公室”——处理管理事务
I/O 队列	1~65535 对	实际读写数据	“服务窗口”——干实际活
工作流程：
1. 开机先用 Admin 队列把 SSD 配好（创建 I/O 队列）
2. 以后所有数据读写都用 I/O 队列
1.2.6 队列深度（Queue Depth）
每个队列能装多少条命令，叫"队列深度"。
    • NVMe 规范允许最多 65535
    • 实际 SSD 通常支持 256~1024
    • 队列深度越大 = 未完成命令越多 = SSD 内部并行度越高 = IOPS 越高
1.2.7 队列数量和深度如何确定（详细方法）
两个概念：
    • 队列数量（Queue Pairs）= 能同时开多少条"命令通道"
    • 队列深度（Queue Depth）= 每条通道里能排多少条"未完成命令"
    • 总未完成命令数 = 队列对数 × 队列深度
队列数量怎么定——看"并发模式"：
场景	队列数量建议	理由
单线程顺序存盘	1~2 对	一次存一段，不需要多通道并发
多线程同时存盘（如 4 线程）	4 对	每路一个队列，互不干扰
多任务并发（边存边读）	2~4 对	读写分队列，避免互相阻塞
高并发随机 IO（数据库类）	8~32 对	需要海量并发

队列深度怎么定——看"数据块大小"：
单次数据量	推荐深度	理由
4KB（很小）	32~64	小块需要深度填满带宽
64KB（中等）	8~16	中块需要一定深度
256KB（大）	4~8	大块深度 4 就够
1MB（很大）	2~4	单条已接近 MDTS 上限

大块 IO vs 小块 IO 的深度需求差异：

大块 IO (如 256KB):
  深度=1: 发 Write(256KB) → 等完成 → 发下一条
  每条 256KB, SSD 一次就能吃满通道
  → 深度 4 后带宽基本饱和

小块 IO (如 4K 随机读):
  深度=1: IOPS = 1/50μs = 20000
  深度=32: SSD 内部 32 通道并行, IOPS = 300000+
  → 深度越大 IOPS 越高, 到 64~128 才接近饱和


深度对性能的影响实测参考（三星 980 Pro，Gen3 ×4）：
队列深度	顺序写带宽(512KB块)	4K 随机读 IOPS
1	2.8 GB/s	18 KIOPS
4	3.4 GB/s	65 KIOPS
16	3.5 GB/s	180 KIOPS
32	3.5 GB/s	320 KIOPS
64	3.5 GB/s	580 KIOPS
结论：大块顺序 IO，深度到 4 之后带宽饱和；小块随机 IO，深度到 64~128 才接近饱和。
选多选少的后果：
情况	后果
队列选多了	资源浪费（LUT/BRAM 多占 30%），可能超过 SSD 支持的最大队列数
队列选少了	存读互相阻塞，响应延迟增加
深度选多了	内存多占（其实不多），IP 状态机更复杂
深度选少了	带宽可能打不满，延迟敏感场景有问题（但大块 IO 深度 1 也接近满带宽）
验证方法：
1. 读 CAP.MQES 确认 SSD 支持的最大队列深度
2. 发 Create I/O CQ/SQ 测试队列创建是否成功
3. 用不同深度测带宽，找饱和点
4. 选饱和点对应的深度，不浪费资源

1.3 NVMe 命令：你要让 SSD 干什么
1.3.1 常用命令一览
命令	操作码	作用	你用不用
Read	0x02	从 SSD 读数据	✅ 用
Write	0x01	往 SSD 写数据	✅ 用
Flush	0x00	把 SSD 内部缓存刷到闪存	可能用（保证数据落盘）
Write Zeroes	0x08	把某区域写全零	一般不用
Identify	0x06	查询 SSD 信息（Admin）	IP 内部用
Create I/O CQ	0x05	创建完成队列（Admin）	IP 内部用
Create I/O SQ	0x01	创建提交队列（Admin）	IP 内部用

1.3.2 其他命令的关注程度详解
Create I/O CQ / Create I/O SQ（关注程度 ★★☆☆☆）：这两个是 Admin 命令，IP 初始化时自动执行，你不需要主动发。
    • Create I/O CQ（Opcode=0x05）：告诉 SSD 建一个完成队列，指定 QID/深度/地址/中断向量
    • Create I/O SQ（Opcode=0x01）：告诉 SSD 建一个提交队列，指定 QID/深度/地址/关联 CQ ID
    • 必须先建 CQ 再建 SQ（因为 SQ 要指定关联的 CQ）
Identify（关注程度 ★★★★☆）：IP 内部用，但返回数据你要会读。返回 4096 字节，包含 SSD 的所有能力信息。
关键字段：
    • 偏移 0x04：SN（序列号）
    • 偏移 0x24：MN（型号名，如 “Samsung SSD 980”）
    • 偏移 0x51：MDTS（最大数据传输大小，0x06=256KB, 0x08=1MB）
    • 偏移 0x100：SQES（SQ 项大小，如 0x66=固定 64 字节）
    • 偏移 0x101：CQES（CQ 项大小，如 0x44=固定 16 字节）
    • 偏移 0x102：NN（命名空间数量）
Write Zeroes（关注程度 ★☆☆☆☆）：作用是把 SSD 某区域写全零，无数据传输，SSD 内部直接标记为零区域。
和 Write 全零数据的区别：
    • Write 全零：FPGA 要发 0 数据给 SSD，SSD 写入 NAND，慢
    • Write Zeroes：无数据传输，SSD 标记为零区域，快
什么场景才用：格式化 SSD、安全擦除、稀疏文件、测试前清零。
有些 SSD 不支持 Write Zeroes。读 Identify Controller 的 ONCS 字段 bit 3 确认。
1.3.3 命令里要填什么？
一条 NVMe 命令（SQE）固定 64 字节，但核心字段就几个：
字段	含义	比喻
Opcode	命令类型（读/写/…）	“存"还是"取”
NSID	命名空间 ID（用哪个分区）	仓库几号区
SLBA	起始逻辑块地址	从第几号货位开始
NLB	逻辑块数量（读/写多少块）	存/取几个货位
PRP1 / PRP2	数据缓冲区地址描述	数据放哪/从哪取
场景：
    • 场景1（写数据）：Opcode=Write，SLBA=存盘位置，NLB=数据量，PRP=写数据缓冲区地址
    • 场景2（读回传）：Opcode=Read，SLBA=读取位置，NLB=数据量，PRP=回传缓冲区地址
1.4 PRP：告诉 SSD 数据在哪
1.4.1 为什么需要 PRP？
NVMe 命令里只有 64 字节，存不下一个完整的"数据缓冲区地址 + 长度"（尤其是数据可能分散在不连续的内存区域）。所以 NVMe 设计了 PRP（Physical Region Page）描述符，用"页地址 + 偏移"的方式描述数据位置。
PRP 的两种形态：
    • PRP1（必填）：描述第一段数据
格式：[页基地址（4KB 对齐）| 页内偏移]
能描述的最大范围：从偏移开始，到这页末尾
    • PRP2（条件填）：有两种情况
如果数据在一页内：PRP2 不填
如果数据跨两页且不超过两页：PRP2 填第二页地址
如果数据跨三页以上：PRP2 填一个"PRP 链表"的地址，链表里存后续所有页地址
1.4.2 为什么 PRP 是 FPGA 实现的最大难点？
软件填 PRP 很简单（算几个地址而已），但硬件填 PRP 很复杂：
1.数据缓冲区可能跨任意多个 4KB 页，要动态计算需要多少 PRP 项
2.PRP 链表本身也要存在内存里，要分配空间、写入、再把地址填回 PRP2
3.这一切要在"命令提交前"完成，不能拖慢性能
1.4.3 MDTS：单次命令最多传多少
MDTS（Max Data Transfer Size）= 单条命令能搬的最大数据量。
    • 由 SSD 决定（通过 Identify 命令读取）
    • 常见值：128KB / 256KB / 512KB / 1MB
    • 如果你要传 2MB 数据，但 MDTS 是 1MB，必须拆成 2 条命令
1.5 LBA：数据的"门牌号"
1.5.1 什么是 LBA？
LBA（Logical Block Address）= 逻辑块地址，就是数据的"门牌号"。
    • SSD 被划分成一个个"逻辑块"，每块通常 512B 或 4KB
    • LBA 从 0 开始编号，连续递增
    • 你要存/读数据，就是告诉 SSD"从第 LBA 号开始，操作 NLB 个块"
    • 举例：
    • SSD 容量 1TB，块大小 4KB
    • 总块数 = 1TB / 4KB = 268,435,456 块
    • LBA 范围：0 ~ 268,435,455
    • 你要存到"第 100MB 开始的位置"：LBA = 100MB / 4KB = 25600
1.5.2 LBA 大小要注意
不同 SSD 的 LBA 大小可能不同：
LBA 大小	说明
512 字节	老式 SSD，兼容传统硬盘
4096 字节（4KB）	现代主流，性能更好
注：读 SSD 的 Identify 信息，看 LBA 格式是 512 还是 4KB，避免地址计算搞错。
1.5.3 Namespace：逻辑分区
一个 SSD 可以分成多个 Namespace（命名空间），每个 Namespace 有独立的 LBA 空间。
    • 大部分消费级 SSD 只有 1 个 Namespace（NSID=1）
    • 企业级 SSD 可能有多个，用于隔离不同用途
1.6 深入补充：NVMe vs AHCI、完整时序、SGL、协议版本
1.6.1 NVMe 为什么比 AHCI 快？（理解设计动机）
在 NVMe 之前，SSD 用 AHCI 协议（本为机械硬盘设计）。理解两者的差异，能帮你理解 NVMe 为什么这么设计。
对比项	AHCI（老协议）	NVMe（新协议）
设计对象	机械硬盘（单磁头）	SSD（多通道并行）
最大队列数	1 个	65535 个
最大队列深度	32	65535
接口	必须 PCIe（但协议本身老旧）	原生为 PCIe 设计
CPU 开销	每条命令多次中断	批量处理、少中断
延迟	~10μs（协议开销大）	~5μs（协议精简）
核心差异：AHCI 只有 1 个队列、深度 32，SSD 内部虽然有多通道，但命令入口被卡住了；NVMe 开了 65535 个队列入口，让 SSD 内部并行能力充分发挥。
类比：AHCI 是单车道收费站，再快的车也得排队；NVMe 是 65535 车道的高速公路，车再多也不堵。
1.6.2 完整命令执行时序图
下面是一条 Write 命令从发起到完成的完整时序，这是理解 NVMe 工作流程的核心：

时间轴 →

Host (FPGA)                                    SSD
    │                                            │
    │  1. 把 SQE 写入主机内存 SQ                  │
    │ ──────────────────────────────────────────>│ (SQE 在主机内存)
    │                                            │
    │  2. 写 SQ Doorbell (Tail 指针)             │
    │ ──────────────PCIe TLP────────────────────>│
    │                                            │
    │                                            │ 3. SSD 发现 Tail 变了
    │                                            │    从 SQ 取走 SQE
    │ <──────────PCIe DMA 读─────────────────────│ (SSD 读主机内存的SQE)
    │                                            │
    │                                            │ 4. SSD 解析 SQE
    │                                            │    解析 PRP, 得知数据地址
    │                                            │
    │                                            │ 5. SSD 发起 DMA 读数据
    │ <──────────PCIe DMA 读─────────────────────│ (SSD 从主机内存读数据)
    │ (主机内存中的数据被 SSD 读走)                │
    │                                            │
    │                                            │ 6. SSD 把数据写入闪存
    │                                            │    (SSD 内部操作)
    │                                            │
    │                                            │ 7. SSD 写 CQE 到主机内存 CQ
    │ <──────────PCIe DMA 写─────────────────────│ (SSD 把 CQE 写到主机内存)
    │                                            │
    │                                            │ 8. SSD 发中断 (MSI-X)
    │ <──────────MSI-X 中断──────────────────────│
    │                                            │
    │  9. Host 收到中断, 轮询 CQ                  │
    │     读取 CQE, 检查 Status                   │
    │     更新 CQ Doorbell (Head 指针)            │
    │ ──────────────PCIe TLP────────────────────>│
    │                                            │
    │  10. 命令完成! 可以发下一条                  │


关键理解：
1.SQE 不是直接发给 SSD，而是先写到主机内存，SSD 再通过 PCIe DMA 来取。这是 NVMe 的"共享内存"模型。
2.Doorbell 是唯一一个 Host 主动发给 SSD 的小信号，作用就是"通知有新命令了"。
3.数据搬运是 SSD 主动发起 DMA，不是 Host 推给 SSD。SSD 是 DMA 的主控方。
4.CQE 也是 SSD 写到主机内存，Host 去读。
5.整个过程中 Host 只做了 4 件事：写 SQE、写 Doorbell、收中断、读 CQE。
1.6.3 SQ/CQ 的内存布局与对齐要求
SQ 和 CQ 都存在主机内存里（FPGA 侧的 DDR 或 BRAM），有严格的地址对齐要求：
要求	SQ	CQ
项大小	64 字节	16 字节
起始地址对齐	4KB 页对齐	4KB 页对齐
内存类型	主机物理内存（DMA 可访问）	同左
位置	可以不连续（但通常连续）	同左

举例：假设队列深度 = 64

主机内存布局：

Admin SQ (起始地址 0x0000_0000_1000, 4KB对齐):
┌─────────────────────────────────────────────┐
│ SQE[0]  SQE[1]  SQE[2]  ...  SQE[63]        │
│ 64B     64B     64B          64B            │
│ 总计: 64 × 64B = 4096B = 4KB                 │
└─────────────────────────────────────────────┘

Admin CQ (起始地址 0x0000_0000_2000, 4KB对齐):
┌─────────────────────────────────────────────┐
│ CQE[0]  CQE[1]  ...  CQE[63]                │
│ 16B     16B         16B                      │
│ 总计: 64 × 16B = 1024B                       │
└─────────────────────────────────────────────┘

I/O SQ #1 (起始地址 0x0000_0000_3000):
┌─────────────────────────────────────────────┐
│ SQE[0]  ...  SQE[63]  (64 × 64B = 4KB)      │
└─────────────────────────────────────────────┘

I/O CQ #1 (起始地址 0x0000_0000_4000):
┌─────────────────────────────────────────────┐
│ CQE[0]  ...  CQE[63]  (64 × 16B = 1KB)      │
└─────────────────────────────────────────────┘


1.6.4 SGL 与 PRP 对比
NVMe 有两种描述数据缓冲区的方式：PRP 和 SGL。
对比项	PRP	SGL
全称	Physical Region Page	Scatter Gather List
设计目的	简单高效	灵活强大
地址对齐	必须 4KB 页对齐（首项除外）	任意字节对齐
段大小	每段必须是页的整数倍（首段除外）	任意大小
链表	PRP 链表项只有地址，无长度	SGL 项有地址 + 长度
支持率	所有 NVMe SSD 必须支持	可选，需查 Identify
复杂度	低	高
FPGA 实现难度	中等	高
注：PRP 是 NVMe 强制支持的，所有 SSD 都兼容。SGL 是可选的，部分 SSD 不支持，而且 FPGA 实现更复杂。
SGL 的数据结构（了解即可）：

SGL 描述符（16 字节）:
┌──────────────────────────┬──────────┬──────┐
│ 地址 (64 bit)             │ 长度(32b) │ 类型 │
└──────────────────────────┴──────────┴──────┘

SGL 链表:
┌────────┬────────┬────────┬────────┐
│SGL项0  │SGL项1  │SGL项2  │  ...   │
│addr+len│addr+len│addr+len│        │
└────────┴────────┴────────┴────────┘
每项可以描述任意地址、任意长度的数据段


1.6.5 NVMe 协议版本演进
版本	发布年份	关键特性	你需要吗
1.0	2011	基础协议	基础
1.1	2012	多路径、保留	否
1.2	2014	主机内存缓冲	否
1.3	2017	Sanitize、虚拟化	基础够用
1.4	2019	IO 确定性	否
2.0	2021	ZNS、KV 命令集	否
建议：买 IP 时要求支持 NVMe 1.3 即可，1.4/2.0 的新特性在 FPGA 本地存储场景基本用不到。但要注意 SSD 本身支持哪个版本——大多数主流 SSD 支持 1.3 或 1.4，IP 支持到 1.3 就能兼容绝大多数 SSD。
1.6.6 Flush 命令的作用
SSD 内部有 DRAM 缓存，Write 命令完成（CQE 返回）不代表数据已经写到闪存了——可能还在 SSD 的 DRAM 缓存里。如果此时掉电，数据会丢。
Flush 命令的作用：强制 SSD 把缓存里的数据刷到闪存。
    • 如果 ADC 数据存盘后不能丢（如军工数据），每次存完后发一条 Flush，确保落盘
    • 如果可以容忍少量丢失（如重复采集覆盖写），可以不 Flush，靠 SSD 自己管理
Flush 的代价：会降低写带宽（每次 Flush 都要等 SSD 刷完缓存），建议批量写完后统一 Flush，不要每条 Write 后都 Flush。
1.6.7 Flush 深入：DRAM 缓存机制与数据落盘确认
餐厅厨房类比理解 Flush：
SSD 内部结构	餐厅对应物
DRAM 缓存（易失性内存）	厨房的"传菜台"——做好的菜先放这
NAND 闪存（非易失）	餐厅的"冷库"——菜最终要放这保存
Write 命令完成（CQE 返回）	厨师把菜放到传菜台，喊一声"好了"
Flush 命令	经理喊"把传菜台的菜全搬进冷库"
掉电	餐厅突然停电
关键矛盾：Write 的 CQE 返回只代表数据进了 SSD 的 DRAM 缓存（传菜台），不代表已写入 NAND 闪存（冷库）。如果此时掉电，DRAM 缓存数据会丢。
重要澄清：FPGA 不会覆盖 DRAM 未刷数据
常见误解：FPGA 直接往 SSD 的 DRAM 写数据，可能覆盖未搬运到 NAND 的数据。
真相：FPGA 根本不直接访问 SSD 的 DRAM。数据流是：

FPGA ──PCIe──> SSD 控制器 ──> SSD 控制器自己决定 ──> DRAM 缓存 or NAND
                  ↑
            SSD 控制器是"中间人"
            所有 DRAM 读写由 SSD 控制器管理


SSD 控制器通过空间分配表管理 DRAM，永远不会把未刷到 NAND 的 DRAM 空间分配给新数据。只有数据已安全写入 NAND，对应 DRAM 空间才会被标记为"可复用"。
DRAM 满了怎么办——反压机制：
如果 FPGA 写得太快，SSD 来不及把 DRAM 数据刷到 NAND，DRAM 缓存会满。此时 SSD 反压：
    • SSD 不分配 DRAM 空间
    • SSD 不发起 DMA 读
    • SSD 不返回 CQE
    • FPGA 的队列深度增加，但收不到完成
这不是错误，是正常反压。FPGA 的 NVMe Host IP 应能处理（等待 CQE，不超时）。

2 PCIe 基础、带宽计算、厂商 IP 架构对照
2.1 PCIe 是什么？
PCIe 是 NVMe 命令和数据在 FPGA 与 SSD 之间跑的"高速公路"。NVMe 定义了"命令格式"，但命令怎么从 FPGA 传到 SSD？靠 PCIe。
类比：
    • NVMe = 快递的"运单格式"（寄件人、收件人、物品）
    • PCIe = 快递的"运输卡车"（把运单和货物从 A 运到 B）
没有 PCIe，NVMe 命令传不出去；没有 NVMe，PCIe 不知道运什么。两者配合使用。
2.2 PCIe 的两个版本维度
2.2.1 速度代际（Gen）
代际	单通道带宽（GB/s）	年份
Gen2	0.5	2007
Gen3	~0.985	2010
Gen4	~1.969	2017
Gen5	~3.938	2019
注意：每代带宽大约翻倍。
2.2.2 通道数（Lane）
PCIe 可以有多个通道并行，像多车道公路：
通道数	写法
1 道	×1
4 道	×4
8 道	×8
16 道	×16
总带宽 = 单通道带宽 × 通道数。
2.2.3 带宽速算表
配置	理论带宽	实际可用（约 85%）
Gen2 ×4	2 GB/s	~1.7 GB/s
Gen3 ×4	3.94 GB/s	~3.3 GB/s
Gen4 ×4	7.88 GB/s	~6.7 GB/s
Gen3 ×8	7.88 GB/s	~6.7 GB/s
Gen4 ×8	15.75 GB/s	~13.4 GB/s
2.3 怎么算你需要多大 PCIe？
第一步：算你的数据率
假设你的 ADC 是 14 位、500 MSPS：数据率 = 14 bit × 500M = 7 Gbps = 0.875 GB/s
第二步：留余量
实际要留 20~30% 余量（PCIe 协议开销、SSD 写放大等）：需求带宽 = 0.875 × 1.3 = 1.14 GB/s
第三步：选 PCIe 规格
    • Gen2 ×4 实际 ~1.7 GB/s > 1.14 GB/s ✅ 够用
    • Gen3 ×4 实际 ~3.3 GB/s，远超需求，有余量
结论：这个 ADC 参数用 Gen2 ×4 就够，不一定要上 Gen3/Gen4。
但要注意：SSD 本身的写速度也要跟上。如果 SSD 标称写 2 GB/s，你的需求 1.14 GB/s，SSD 没问题。
2.4 PCIe 硬核 vs 软核
类型	说明	优缺点
硬核	FPGA 芯片里固化的 PCIe 模块	性能高、资源省；但绑定特定芯片型号
软核	用 FPGA 逻辑资源搭出来的 PCIe	灵活、可移植到任何 FPGA；但性能低、占资源多

2.5 PCIe 的关键参数
参数	含义	影响
MPS（Max Payload Size）	单个 TLP 最大有效载荷	越大效率越高，通常 256B 或 512B
MRRS（Max Read Request Size）	最大读请求大小	通常等于 MPS
TLP（Transaction Layer Packet）	PCIe 传输的基本报文	NVMe 命令和数据都封装在 TLP 里
不用深究：这些参数 IP 会自动配置，你只需要知道"大一点效率高，小一点兼容性好"。

2.6 深入补充：PCIe 协议栈、TLP、BAR、链路训练、中断
2.6.1 PCIe 协议栈三层结构
PCIe 协议分为三层，从上到下：

┌─────────────────────────────────┐
│  事务层 (Transaction Layer)      │  ← NVMe 命令/数据封装成 TLP
│  - 生成/解析 TLP                 │
│  - 流量控制 (Credit)             │
├─────────────────────────────────┤
│  数据链路层 (Data Link Layer)    │  ← 保证可靠传输
│  - 序列号 (Sequence Number)      │
│  - CRC 校验                      │
│  - ACK/NAK 重传                  │
├─────────────────────────────────┤
│  物理层 (Physical Layer)         │  ← 比特级传输
│  - 编码 (128b/130b for Gen3+)   │
│  - 串行/解串 (SerDes)            │
│  - 链路训练 (LTSSM)              │
└─────────────────────────────────┘


每层的职责：
    • 事务层：把 NVMe 的"读写请求"封装成 TLP 报文。你抓 ILA 波形看到的通常是这一层的信号。
    • 数据链路层：保证 TLP 不丢、不乱序。如果传输出错会自动重传，上层无感知。
    • 物理层：把数字信号变成电信号在 PCIe 通道上跑。链路训练（上电握手）在这一层完成。
对 FPGA 工程师的意义：你用的 Xilinx PCIe IP 已经把三层都实现了，你只需要在事务层接口（AXI-Stream）上收发 TLP。但理解分层有助于排查问题——如果链路不稳定，多半是物理层问题；如果数据错，多半是事务层问题。
2.6.2 TLP 报文结构
TLP（Transaction Layer Packet）是 PCIe 传输的基本单位。NVMe 的命令、数据、寄存器访问都封装在 TLP 里。

一个 TLP 的结构：
┌──────────┬──────────┬──────────────┬────────────────┐
│ TLP 头部 │ 数据载荷  │ ECRC (可选)  │ LCRC (链路层)  │
│ (12/16B) │ (0~4096B)│              │                │
└──────────┴──────────┴──────────────┴────────────────┘


TLP 头部格式（12 字节，带摘要时 16 字节）：

Byte 0:  [Fmt(3)] [Type(5)]        ← 格式和类型
Byte 1:  [TC(3)] [TD] [EP] [Attr(2)] [R]   ← 流量类别、属性
Byte 2:  [TH] [R] [Tag(7)] [STag(4)]       ← 标签
Byte 3:  [First BE(4)] [Last BE(4)]        ← 字节使能
Byte 4-7: 地址低 32 位 (或偏移)
Byte 8-11: 地址高 32 位 (64位地址时)
Byte 12-15: 摘要 (可选)


TLP 类型（你最常遇到的）：
Type 值	名称	说明	NVMe 中用途
0x00	MemRead (MRd)	内存读请求	Host 请求读 SSD 寄存器
0x01	MemWrite (MWr)	内存写请求	Host 写 Doorbell / SSD 写 CQE
0x0A	Completion (CplD)	带数据完成	响应读请求
0x04	ConfigRead (CfgRd)	配置读	枚举阶段
0x05	ConfigWrite (CfgWr)	配置写	配置 BAR
关键概念：NVMe 的所有操作都是"内存读写"——Doorbell 寄存器映射成内存地址，SQE/CQE 在主机内存里，SSD 数据传输也是内存 DMA。PCIe 把这些都统一成 MemRead/MemWrite TLP。
2.6.3 BAR 机制详解
BAR（Base Address Register）是 PCIe 设备告诉 Host"我有哪些寄存器空间需要映射到主机内存地址"的机制。
工作流程：

1. 上电时, Host 扫描 PCIe 总线 (枚举)
2. 对每个设备, Host 写全 1 到 BAR, 再读回来
   → 根据返回值算出设备需要多大地址空间
3. Host 给设备分配一个基地址, 写入 BAR
4. 之后 Host 访问这个地址 = 访问设备的寄存器


NVMe SSD 的 BAR0：
BAR	大小	映射内容
BAR0	4KB~16KB	NVMe 控制器寄存器（CAP/CC/CSTS 等）
对你的意义：
    • 初始化时，Host 通过 BAR0 访问 NVMe 寄存器（CAP/CC/CSTS/AQA 等）
    • BAR0 的基地址由 PCIe 枚举时动态分配，不是固定的
    • IP 内部会自动处理 BAR0 地址，你只需通过寄存器接口读写
调试关注：抓初始化波形时，确认 BAR0 被正确分配（非 0），且后续寄存器访问都通过这个地址。
2.6.4 PCIe 链路训练过程（LTSSM）
LTSSM（Link Training and Status State Machine）是 PCIe 物理层的链路训练状态机，上电时自动执行。
简化流程：

上电
  │
  ▼
Detect (检测对端设备)
  │  ← 检测到远端有设备
  ▼
Polling (发送训练序列, 协商速率/通道)
  │  ← 协商 Gen2/3/4, 协商 ×1/×4/×8
  ▼
Configuration (配置链路编号、通道映射)
  │  ← 通道对齐
  ▼
Recovery (速率切换, 如从 Gen1 切到 Gen3)
  │
  ▼
L0 (正常工作状态)  ← link_up 信号拉高
  │
  ├─→ L0s/L1 (节能状态, 可唤醒)
  └─→ Disable/Hot Reset (链路关闭)


耗时参考：
    • 从上电到 L0：通常 50~200ms
    • 速率切换（Gen1→Gen3）：额外 10~50ms
常见问题：如果 link_up 一直不拉高，检查：
    • PCIe 插槽的 REFCLK 是否接对
    • 通道数配置是否匹配（SSD 支持 ×4 但 FPGA 只配了 ×2）
    • 速率配置是否支持（FPGA 设 Gen3 但 SSD 只支持 Gen2）
2.6.5 MSI / MSI-X 中断机制
NVMe 用中断通知 Host"命令完成了"。PCIe 有三种中断方式：
方式	说明	NVMe 使用
INTx	传统引脚中断，电平触发	不推荐
MSI	消息信号中断，单向量	可用
MSI-X	MSI 扩展，多向量	推荐
MSI/MSI-X 的原理：
    • 不是用物理引脚，而是用一个特殊的内存写操作触发中断
    • Host 给设备分配一个"中断地址"，设备往这个地址写数据 = 触发中断
    • MSI 只有 1 个向量，MSI-X 最多 2048 个向量
NVMe 中 MSI-X 的用途：
    • 每个完成队列 CQ 可以绑定一个 MSI-X 向量
    • SSD 往某个 CQ 写完 CQE 后，发对应向量的中断
    • Host 收到中断就知道"哪个队列有新完成"
调试关注：
    • 确认 IP 支持 MSI-X（不只是 MSI）
    • 确认 MSI-X 向量数 ≥ I/O 队列对数（每个 CQ 一个向量）
    • 抓波形看中断是否正确触发

3 NVMe 寄存器、初始化流程、Status Code
3.1 NVMe 寄存器在哪？
NVMe 寄存器不在 FPGA 里，而在 SSD 里面。FPGA 通过 PCIe 访问 SSD 的这些寄存器来配置和控制它。
这些寄存器映射在 PCIe 的 BAR0（Base Address Register 0）指向的地址空间，通常 4KB~16KB 大小。
类比：SSD 是一台设备，寄存器是它面板上的"控制旋钮和指示灯"，FPGA 通过 PCIe “远程拧旋钮、看灯”。
3.2 必须认识的 4 个核心寄存器
3.2.1 寄存器 1：CAP（Controller Capabilities，控制器能力）— 偏移 0x000
作用：告诉 Host 这个 SSD 支持什么能力。只读。
关键字段：
字段	位	含义	你要看的
MQES	15:0	最大队列深度	看支持 256 还是 65535
CPS	25:24	供电状态	确认供电正常
MPSMIN	54:52	最小 MPS	通常 0（4KB）
MPSMAX	57:55	最大 MPS	通常 0（4KB）
怎么看：读 CAP 寄存器，MQES+1 就是最大队列深度。
3.2.2 寄存器 2：CC（Controller Configuration，控制器配置）— 偏移 0x014
作用：Host 写这个寄存器来配置 SSD。可读可写。
关键字段：
字段	位	含义	怎么用
EN	0	控制器使能	写 1 启动 SSD，写 0 关闭
MPS	10:7	MPS 设置 （PRP 描述符里"页"的大小）	0=4KB, 1=8KB…
CSS	16:13	命令集选择	通常 0（NVM 命令集）
IOCQES	21:17	I/O CQ 项大小	4（=16 字节）
IOSQES	29:25	I/O SQ 项大小	6（=64 字节）
怎么用：配置好 MPS、队列项大小后，写 EN=1 启动。
3.2.3 寄存器 3：CSTS（Controller Status，控制器状态）— 偏移 0x01C
作用：告诉 Host SSD 现在什么状态。只读。
关键字段：
字段	位	含义	你要看的
RDY	0	控制器就绪	写 CC.EN=1 后等这个位变 1
CFS	1	致命错误	如果变 1 说明 SSD 挂了
NSS	2	NVM 子系统复位	复位标志
怎么用：写 CC.EN=1 后，轮询 CSTS.RDY，等它变 1 才能发命令。
3.2.4 寄存器 4：AQA / ASQ / ACQ（Admin 队列配置）
这三个一起说，它们配置 Admin 队列：
寄存器	偏移	作用
AQA	0x024	Admin 队列深度（低 16 位 = SQ 深度，高 16 位 = CQ 深度）
ASQ	0x028	Admin SQ 的物理地址（64 位）
ACQ	0x030	Admin CQ 的物理地址（64 位）
怎么用：在启动前，把 Admin 队列的地址和深度写进去。
3.3 完整初始化流程
把寄存器串起来，NVMe 初始化流程如下：

步骤 1：PCIe 链路训练
  上电 → PCIe 物理层握手 → link_up 信号拉高
  (这一步由 PCIe 控制器 IP 自动完成)

步骤 2：PCIe 枚举配置
  Host 通过 PCIe 配置空间，给 SSD 分配 BAR、设置 MPS/MRRS
  configure_finished 信号拉高

步骤 3：读取 SSD 能力
  读 CAP 寄存器 → 知道最大队列深度、MPS 范围
  发 Identify Admin 命令 → 读详细能力（MDTS、LBA 格式等）

步骤 4：配置 Admin 队列
  写 ASQ = Admin SQ 的物理地址
  写 ACQ = Admin CQ 的物理地址
  写 AQA = 队列深度（比如 32）

步骤 5：使能控制器
  写 CC.EN = 1

步骤 6：等待就绪
  轮询 CSTS.RDY，等它变 1（通常 1 秒内）

步骤 7：创建 I/O 队列
  发 Admin 命令 Create I/O Completion Queue
  发 Admin 命令 Create I/O Submission Queue

步骤 8：nvme_ready 信号拉高，可以发 Read/Write 命令了！


抓波形调试时，就是对照这个流程，看每个步骤的寄存器读写是否正确发生、时序是否合理。
3.4 Status Code：看懂 SSD 的"回执"
每条命令完成后，SSD 会在 CQE 里返回一个 Status Code，告诉你"成功了还是出错了"。
3.4.1 Status Code 的位置
CQE 第 3 个字（Word 2）的低 8 位是 Status Code，第 8~11 位是 Status Code Type。

CQE 结构（16 字节）：
┌──────────┬──────────┬──────────┬──────────┐
│  CID     │  Status  │  P       │  Command │
│ (Word 0) │ (Word 1) │ (Word 2) │ (Word 3) │
└──────────┴──────────┴──────────┴──────────┘
                         ↑
                    Status Code 在这


3.4.2 常见 Status Code 速查表
成功：
Type	Code	含义
0	0x00	Success（成功）
通用错误（Type=0，最常见的）：
Code	名称	含义	可能原因
0x01	Invalid Opcode	命令码非法	IP 发了 SSD 不支持的命令
0x02	Invalid Field	字段非法	SQE 某字段填错了（如 NSID=0）
0x03	Command ID Conflict	命令 ID 冲突	IP 的 CID 管理有 bug
0x04	Data Transfer Error	数据传输错	PRP 地址错 / DMA 出错
0x05	Commands Aborted due to Power Loss	掉电中止	正常现象
0x07	Commands Aborted due to Timeout	超时中止	SSD 卡住了
0x08	Commands Aborted due to Sanitize	被清除中止	不常见
命名空间相关错误（Type=0）：
Code	名称	含义
0x0B	Namespace Not Ready	命名空间没就绪（初始化没完成就发命令）
0x0C	Namespace Not Found	命名空间不存在（NSID 写错了）
0x0D	Namespace Insufficient Capacity	空间不足
命令特定错误（Type=0）：
Code	含义
0x10	LBA 超出范围（SLBA + NLB 超过 SSD 容量）
0x11	容量超出（写太多）
测试时要做的：故意发错误命令，看 Status Code 是否符合预期：
故意犯的错	期望 Status Code
发非法操作码（如 0xFF）	0x01 Invalid Opcode
NSID 写 0	0x02 Invalid Field
SLBA 超大	0x10 LBA Out of Range
在 RDY=0 时发命令	0x0B Namespace Not Ready
如果 Status Code 和预期不符，说明 IP 的命令构造有问题。
3.5 深入补充：完整寄存器映射、Identify 结构、初始化排查
3.5.1 完整 NVMe 寄存器映射表
除了第 3.2 节的 4 个核心寄存器，NVMe 还有以下寄存器。测试时如果能读懂这些，说明你的协议功底扎实了。
偏移	名称	读写	说明	你要关注的
0x000	CAP	RO	控制器能力	MQES / MPSMAX / DSTRD
0x008	VS	RO	版本号	确认 SSD 支持 NVMe 1.3+
0x00C	INTMS	RW	中断屏蔽设置	一般不用
0x010	INTMC	RW	中断屏蔽清除	一般不用
0x014	CC	RW	控制器配置	EN / MPS / IOSQES / IOCQES
0x01C	CSTS	RO	控制器状态	RDY / CFS
0x020	NSTS	RO	NVM 子系统复位	写 1 触发复位
0x024	AQA	RW	Admin 队列属性	ASQS / ACQS
0x028	ASQ	RW	Admin SQ 基地址	64 位 4KB 对齐
0x030	ACQ	RW	Admin CQ 基地址	64 位 4KB 对齐
0x038	CMBLOC	RO	控制器内存缓冲位置	一般不用
0x03C	CMBSZ	RO	控制器内存缓冲大小	一般不用
0x040	BPINFO	RO	引导分区信息	一般不用
0x044	BPRSEL	RW	引导分区读选择	一般不用
0x048	BPMBL	RW	引导分区内存缓冲	一般不用
0x050	CMBMSC	RW	CMB 内存空间控制	一般不用
0x058	CMBSTS	RO	CMB 状态	一般不用
0x060+	I/O 队列 Doorbell	RW	每个 SQ/CQ 一对	Tail/Head 指针
Doorbell 的地址计算：
    • Admin SQ Doorbell = BAR0 基地址 + 0x1000
    • Admin CQ Doorbell = BAR0 基地址 + 0x1004
    • I/O SQ #1 Doorbell = BAR0 基地址 + 0x1000 + (2 × QID × (4 << DSTRD))
    • I/O CQ #1 Doorbell = BAR0 基地址 + 0x1004 + (2 × QID × (4 << DSTRD))
其中 DSTRD 从 CAP 寄存器读取（通常为 0，表示每个 Doorbell 占 4 字节）。
VS（Version）寄存器：

Bits 31:16 = 主版本号 (如 0x0001 = 1.x)
Bits 15:0  = 次版本号 (如 0x0030 = 1.3)
所以 NVMe 1.3 的 VS = 0x0001_0030


3.5.2 Identify 命令返回数据结构
Identify 是最重要的 Admin 命令，用来查询 SSD 的详细能力。返回数据固定 4096 字节（4KB）。
Identify Controller（CNS=0x01）返回的关键字段：
偏移	字段	大小	说明	你要看的
0	VID	2B	厂商 ID	识别品牌
2	SSVID	2B	子系统厂商 ID	-
4	SN	20B	序列号	标识具体盘
24	MN	40B	型号名	如 “Samsung SSD 980”
64	FR	8B	固件版本	-
77	IEEE[2:0]	3B	IEEE OUI	-
80	CMIC	1B	多端口信息	-
81	MDTS	1B	最大数据传输大小	关键！ 0=无限制, 5=128KB, 6=256KB, 7=512KB, 8=1MB
84	CNTLID	2B	控制器 ID	-
100	VER	4B	NVMe 版本	确认支持版本
108	OAES	4B	异步事件支持	-
256	SQES	1B	SQ 项大小	关键！ 如 0x66 = 最小64B/最大64B
257	CQES	1B	CQ 项大小	关键！ 如 0x44 = 最小16B/最大16B
258	NN	4B	命名空间数量	通常 1
264	ONCS	2B	可选 NVM 命令支持	看支持哪些命令
519	NNMT	1B	介质类型	-
MDTS 的计算：MDTS 字段值 = 2^n × MPS
    • 如 MDTS=6, MPS=4KB → 最大传输 = 2^6 × 4KB = 256KB
    • 如 MDTS=8, MPS=4KB → 最大传输 = 2^8 × 4KB = 1MB
SQES/CQES 的编码：

SQES 格式: [高4位=最大值的log2] [低4位=最小值的log2]
如 SQES = 0x66:
  最小 = 2^6 = 64 字节
  最大 = 2^6 = 64 字节
  → SQ 项固定 64 字节

如 SQES = 0x76:
  最小 = 2^6 = 64 字节
  最大 = 2^7 = 128 字节
  → SQ 项可配 64 或 128 字节


调试动作：初始化完成后，读 Identify 返回数据，记录 MDTS / SQES / CQES / NN，可作为兼容性测试的参考。
3.5.3 初始化各阶段耗时参考
正常的初始化耗时大致如下（供调试时判断是否异常）：
阶段	正常耗时	异常信号
PCIe 链路训练	50~200ms	>500ms 可能有问题
PCIe 枚举配置	1~5ms	-
读 CAP 寄存器	<1μs	-
写 ASQ/ACQ/AQA	<1μs	-
写 CC.EN=1	<1μs	-
等待 CSTS.RDY=1	100ms~2s	>5s 说明 SSD 有问题
Identify 命令	1~10ms	>100ms 可能有问题
Create I/O CQ	1~5ms	-
Create I/O SQ	1~5ms	-
总计	200ms~3s	>10s 需排查
3.5.4 常见初始化失败原因排查
症状	可能原因	排查方法
link_up 不拉高	PCIe 物理层问题	检查 REFCLK / 通道配置 / 速率
configure_finished 不拉高	BAR 分配失败	检查 PCIe 枚举日志
CSTS.RDY 一直不拉高	CC 配置错误	检查 MPS / CSS / 队列大小配置
Identify 返回全 0	SQE 没正确提交	抓 SQE 波形，检查 Doorbell
Identify 超时	PRP 地址错	检查 PRP1 指向的地址是否有效
Create I/O Queue 失败	队列参数超限	检查队列深度是否超过 CAP.MQES
发 Read/Write 返回 0x0B	命名空间没就绪	等更长时间再发命令

4 SQE/CQE 细节、PRP 描述符、ILA 抓波形练习
4.1 SQE 详细结构（64 字节）
一条 NVMe 命令（SQE）固定 64 字节，分为 16 个 DWORD（每个 4 字节）：

偏移    字段                        你要关心的
─────────────────────────────────────────────
0x00    CDW0 (DWORD 0)
        ├── Opcode [7:0]            ✅ 命令码
        ├── FUSE [9:8]              不用管（0）
        ├── PSDT [11:10]            PRP 描述类型（0=PRP, 1=SGL）
        └── CID [31:16]             ✅ 命令 ID（硬件自管理）
0x04    NSID (DWORD 1)              ✅ 命名空间 ID（通常 1）
0x08    Reserved (DWORD 2-3)        不用管
0x10    MPTR (DWORD 4-5)            不用管（元数据指针）
0x18    PRP1 (DWORD 6-7)            ✅ 数据缓冲区地址 1
0x20    PRP2 (DWORD 8-9)            ✅ 数据缓冲区地址 2（或链表指针）
0x28    CDW10 (DWORD 10)            ✅ SLBA 低 32 位
0x2C    CDW11 (DWORD 11)            ✅ SLBA 高 32 位
0x30    CDW12 (DWORD 12)
        ├── NLB [15:0]              ✅ 扇区数 - 1（注意是减 1！）
        └── Control [31:16]         不用管
0x34    CDW13~15 (DWORD 13-15)      不用管
─────────────────────────────────────────────


调试抓波形时，重点看这几个字段：
    • Opcode 对不对（Read=0x02, Write=0x01）
    • NSID 对不对（应该是 1）
    • PRP1/PRP2 指向的地址对不对
    • SLBA 对不对（你要存的地址）
    • NLB 对不对（注意是"数量 - 1"，写 256 扇区要填 255）
4.1.1 NLB 的"减 1"陷阱
NLB 字段是 16 位，表示"要操作的扇区数 减 1"。
    • 想操作 1 个扇区 → NLB = 0
    • 想操作 64 个扇区 → NLB = 63
    • 想操作 256 个扇区 → NLB = 255
这是新手最容易犯的错，调试时一定要检查。
4.1.2 SQE 64 字节逐字节详解
DW0：命令控制字（最关键的一个 DWORD）
DW0 包含 4 个字段：

DW0 (32 位):
┌────────┬──────┬──────┬────────────────┐
│ 31:16  │ 11:10│ 9:8  │      7:0       │
│  CID   │ PSDT │ FUSE │    Opcode      │
└────────┴──────┴──────┴────────────────┘


字段	位	含义	调试关注
Opcode	7:0	命令码	Read=0x02, Write=0x01, Flush=0x00
FUSE	9:8	融合命令	应该是 00（非融合）
PSDT	11:10	PRP/SGL 选择	用 PRP 应该是 00
CID	31:16	命令 ID	递增不重复
注意：Create I/O SQ 的 Opcode 是 0x01，和 Write 的 0x01 一样！区分方法是看命令属于哪个队列——Admin 队列里的 0x01 是 Create I/O SQ，I/O 队列里的 0x01 是 Write。
DW1：NSID（命名空间 ID）
固定填 1（多数 SSD 只有 1 个命名空间）。如果 NSID=0，SSD 返回 Status=0x02。
DW2~DW3：保留字段
必须填 0。抓波形看到非 0，说明 IP 有 bug。
DW4~DW5：MPTR（元数据指针）
不用元数据时填 0。企业级 SSD 启用端到端保护（DIF/DIX）时才用。
DW6~DW7：PRP1（数据缓冲区地址 1）

PRP1 (64 位):
63                    12 11        0
┌──────────────────────┬──────────┐
│   页基地址            │ 页内偏移  │
│   (低12位为0, 4KB对齐) │          │
└──────────────────────┴──────────┘


    • 对 Admin 命令（如 Identify）：PRP1 必须 4KB 对齐（低 12 位为 0）
    • 对 I/O 命令（如 Read/Write）：PRP1 低 12 位 = 数据缓冲区地址低 12 位
DW8~DW9：PRP2（数据缓冲区地址 2 或链表指针）
三种情况：
    • 数据在一页内：PRP2 = 0
    • 数据跨两页：PRP2 = 第二页基地址（4KB 对齐）
    • 数据跨三页以上：PRP2 = PRP 链表起始地址
DW10~DW11：SLBA（起始逻辑块地址）
64 位 LBA 地址。注意是按 LBA 块编号，不是按字节地址。
举例：LBA=4KB，要从 100MB 位置开始 → SLBA = 100MB / 4KB = 25600
DW12：NLB + Control

DW12 (32 位):
┌────────────────┬────────────────────────────┐
│     31:16      │           15:0             │
│   Control      │           NLB              │
└────────────────┴────────────────────────────┘


Control 关键位：
    • Bit 30 = FUA（Force Unit Access）：FUA=1 时数据必须写入 NAND 后 CQE 才返回
    • 其他位通常为 0
DW13~DW15：命令特定字段
对 Read/Write 通常填 0。对 Admin 命令有特殊含义（如 Identify 的 CNS 在 DW10）。
4.1.3 SQE 填写实例
实例 1：Write 256KB 到 LBA=1024（跨多页，需 PRP 链表）

假设: LBA=4KB, 256KB=64块, 数据地址=0x8000_0000(4KB对齐), 链表地址=0x8001_0000

DW0:  0x0000_0001  (Opcode=0x01 Write, FUSE=0, PSDT=00, CID=0)
DW1:  0x0000_0001  (NSID=1)
DW2:  0x0000_0000  (保留)
DW3:  0x0000_0000  (保留)
DW4:  0x0000_0000  (MPTR=0, 无元数据)
DW5:  0x0000_0000
DW6:  0x8000_0000  (PRP1 低)
DW7:  0x0000_0000  (PRP1 高)
DW8:  0x8001_0000  (PRP2 低=链表地址)
DW9:  0x0000_0000  (PRP2 高)
DW10: 0x0000_0400  (SLBA 低=1024)
DW11: 0x0000_0000  (SLBA 高=0)
DW12: 0x0000_003F  (NLB=63, 即64块; Control=0)
DW13: 0x0000_0000
DW14: 0x0000_0000
DW15: 0x0000_0000


实例 2：Read 4KB 从 LBA=0（单页，PRP2 不填）

DW0:  0x0000_0002  (Opcode=0x02 Read)
DW1:  0x0000_0001  (NSID=1)
DW6:  0x8000_0000  (PRP1)
DW7:  0x0000_0000
DW8:  0x0000_0000  (PRP2=0, 不需要)
DW9:  0x0000_0000
DW10: 0x0000_0000  (SLBA=0)
DW11: 0x0000_0000
DW12: 0x0000_0000  (NLB=0, 即1块)
其他: 全 0


实例 3：Flush（无数据传输）

DW0:  0x0000_0000  (Opcode=0x00 Flush)
DW1:  0x0000_0001  (NSID=1)
DW2~DW15: 全 0


实例 4：Identify Controller（Admin 命令）

DW0:  0x0000_0006  (Opcode=0x06 Identify)
DW1:  0x0000_0000  (NSID=0, Admin命令不指定NS)
DW6:  0x0000_1000  (PRP1, 4KB对齐, 存返回数据)
DW7:  0x0000_0000
DW8:  0x0000_0000  (PRP2=0, 4KB在一页内)
DW10: 0x0000_0001  (CNS=1, Identify Controller)
其他: 全 0


4.1.4 SQE 调试抓波形检查清单
检查项	检查方法	正常值
Opcode [7:0]	对照命令类型	Read=0x02, Write=0x01, Flush=0x00
FUSE [9:8]	应该是 0	00
PSDT [11:10]	用 PRP 应该是 0	00
CID [31:16]	递增不重复	0,1,2,…
NSID	应该是 1	0x0000_0001
DW2~DW3 (保留)	应该全 0	0
MPTR (DW4~DW5)	无元数据应该 0	0
PRP1 (DW6~DW7)	指向有效内存	有效地址
PRP2 (DW8~DW9)	按数据跨度	0/页地址/链表地址
SLBA (DW10~DW11)	在 SSD 容量范围内	合法 LBA
NLB [DW12 15:0]	实际块数 - 1	数量-1
Control [DW12 31:16]	正常=0, FUA=0x8000	0 或 0x8000
DW13~DW15	Read/Write 应该 0	0
4.2 CQE 详细结构（16 字节）

偏移    字段                你要关心的
───────────────────────────────────
0x00    CDW0 (DWORD 0)     不用管（命令返回结果）
0x04    Reserved (DWORD 1) 不用管
0x08    SQHD (DWORD 2)     ✅ SQ Head 指针（SSD 读到哪里了）
        ├── SQHD [15:0]
        ├── SQID [31:16]   ✅ 来源队列 ID
0x0C    CDW3 (DWORD 3)
        ├── CID [15:0]     ✅ 命令 ID（对应哪条命令）
        ├── P [16]         Phase 位（轮转标记）
        └── Status [31:17] ✅ 状态码（重点看！）
───────────────────────────────────


调试抓波形时，重点看：
    • Status 是否为 0x00（成功）
    • CID 是否对应你发的那条命令
    • SQHD 是否在递增
4.2.1 Phase 位的作用
CQE 里有一个 Phase 位（P），SSD 每次往 CQ 写新项时翻转一次 P（0→1→0→1…）。
Host 轮询 CQ 时，通过 P 位判断"这条 CQE 是新的还是旧的"：
    • 如果 P 和上次不一样 → 是新完成项
    • 如果 P 和上次一样 → 还没新完成项
这是避免重复处理同一 CQE 的机制，调试时确认 P 位翻转正确。
4.3 PRP 描述符深入
4.3.1 PRP1 的格式
PRP1 是 64 位，格式如下：

63                    12 11        0
┌──────────────────────┬──────────┐
│   页基地址（4KB对齐） │ 页内偏移  │
└──────────────────────┴──────────┘


    • 高 52 位：4KB 页基地址（低 12 位为 0）
    • 低 12 位：页内偏移（数据从这个位置开始）
举例：数据缓冲区地址 = 0x0000_1234_5678
    • 页基地址 = 0x0000_1234_5000（对齐到 4KB）
    • 页内偏移 = 0x678
    • PRP1 = 0x0000_1234_5678（原地址，低 12 位就是偏移）
4.3.2 PRP2 的三种情况
情况 1：数据在一页内（长度 ≤ 4KB - 偏移），PRP2 = 0（不填）
情况 2：数据跨两页（长度 ≤ 8KB - 偏移），PRP2 = 第二页的基地址（必须是 4KB 对齐，低 12 位为 0）
情况 3：数据跨三页以上
    • PRP2 = PRP 链表的起始地址
    • 链表是一个数组，每项 8 字节（64 位地址），存后续每页的基地址

PRP 链表：
┌──────────────┬──────────────┬──────────────┬───┐
│ 第3页基地址   │ 第4页基地址   │ 第5页基地址   │...│
└──────────────┴──────────────┴──────────────┴───┘
  (8 字节)       (8 字节)       (8 字节)


4.3.3 调试时检查 PRP
抓 ILA 波形，检查：
1. PRP1 低 12 位是否等于缓冲区地址的低 12 位
2. 数据跨页时，PRP2 是否正确填写（页地址 or 链表地址）
3. PRP 链表内容是否正确（每项 4KB 对齐、连续递增）
4. PRP 项数量是否和"数据长度 / 4KB"匹配
常见 bug：
    • PRP 地址算错（没对齐）
    • 链表长度算错（少了一项）
    • 链表项地址重复
4.3.4 PRP 与 SLBA/NLB 的关系详解
核心结论：SLBA、NLB 和 PRP 有关系，但是"间接关系"
字段	描述什么	和数据量的关系
SLBA + NLB	描述数据在 SSD 上的位置和大小	决定总数据量
PRP1 + PRP2	描述数据在主机内存中的位置	由总数据量间接决定用哪种 PRP 填法
一句话：SLBA + NLB 决定"搬多少数据"（数据量），PRP1 + PRP2 决定"这些数据在主机内存里放哪"。数据量大小会反过来影响 PRP 的填法（单页/两页/链表）。
四个字段的分工：

┌─────────────────────────────────────────────────────────┐
│                    一条 NVMe Write 命令                   │
│                                                          │
│  ┌─────────────┐  ┌─────────────┐                       │
│  │   SLBA      │  │   NLB       │                       │
│  │  起始扇区号  │  │  扇区数量-1  │  → 描述 SSD 侧       │
│  │  (SSD 上)   │  │  (SSD 上)   │                       │
│  └─────────────┘  └─────────────┘                       │
│                                                          │
│  ┌─────────────┐  ┌─────────────┐                       │
│  │   PRP1      │  │   PRP2      │                       │
│  │  内存地址1   │  │  内存地址2   │  → 描述主机内存侧     │
│  │  (主机内存)  │  │  (主机内存)  │                       │
│  └─────────────┘  └─────────────┘                       │
└─────────────────────────────────────────────────────────┘


    • SLBA + NLB：告诉 SSD “把数据写到 SSD 的哪个位置、写多少”
    • PRP1 + PRP2：告诉 SSD “数据在主机内存的哪个位置”
    • 两者描述的是同一段数据的两端，数据量必须两边匹配
NLB 如何影响 PRP 的填法（计算链）：

NLB (扇区数)
  × LBA 大小 (通常 4KB)
  = 总数据量
  → 数据在内存里从 PRP1 指向的地址开始，连续放这么长
  → 看这段数据跨多少个 4KB 页
  → 决定 PRP2 怎么填


完整对应关系表：
NLB 值	扇区数	数据量(LBA=4KB)	跨页数	PRP2 填法
0	1	4KB	1 页	0（不填）
1	2	8KB	2 页	第二页地址
3	4	16KB	4 页	链表指针
7	8	32KB	8 页	链表指针
15	16	64KB	16 页	链表指针
31	32	128KB	32 页	链表指针
63	64	256KB	64 页	链表指针
255	256	1MB	256 页	链表指针
注意：跨页数还和数据起始地址的偏移有关。如果起始地址刚好 4KB 对齐，跨页数 = 数据量 / 4KB；如果不对齐，可能多跨一页。
SLBA 和 PRP 没有直接关系：
字段	描述	和谁有关
SLBA	SSD 上的起始扇区号	和你要存到 SSD 哪个位置有关
PRP1	主机内存的数据起始地址	和数据在主机内存哪里有关
两者完全独立——SLBA 可以是任意值，不影响 PRP 怎么填；PRP1 可以指向任意主机内存地址，不影响 SLBA 的值。
类比：
    • SLBA = 快递送到哪个地址（SSD 侧）
    • PRP1 = 快递从哪个地址取货（主机内存侧）
    • 两个地址互不影响
容易搞混的典型场景：
场景 1：SLBA=0 vs SLBA=10000，同样数据量

命令 A: SLBA=0,    NLB=63, PRP1=0x8000_0000  (256KB)
命令 B: SLBA=10000, NLB=63, PRP1=0x8000_0000  (256KB)

两条命令的 PRP2 填法完全一样！
因为数据量一样, 内存起始地址一样, 跨页数一样
SLBA 不同只影响数据存到 SSD 的位置, 不影响 PRP


场景 2：同样 SLBA，不同 NLB，PRP 填法不同

命令 A: SLBA=0, NLB=0,  PRP1=0x8000_0000  (4KB, 单页)
  → PRP2 = 0

命令 B: SLBA=0, NLB=63, PRP1=0x8000_0000  (256KB, 64页)
  → PRP2 = 链表指针

SLBA 相同, 但 NLB 不同导致数据量不同, PRP 填法不同


场景 3：同样 NLB，不同 PRP1 偏移，跨页数可能不同

命令 A: NLB=0, PRP1=0x8000_0000  (4KB对齐, 4KB数据)
  → 数据在 0x8000_0000~0x8000_0FFF, 1页
  → PRP2 = 0

命令 B: NLB=0, PRP1=0x8000_0800  (偏移0x800, 4KB数据)
  → 数据在 0x8000_0800~0x8000_17FF, 跨2页
  → PRP2 = 0x8000_1000

NLB 相同, 但 PRP1 偏移不同, 导致跨页数不同, PRP2 填法不同


调试时的检查逻辑：
抓到一条 SQE 波形后，按这个顺序检查 PRP 是否正确：

步骤 1: 读 NLB, 算数据量
  NLB = 63 → 扇区数 = 64 → 数据量 = 64 × 4KB = 256KB

步骤 2: 读 PRP1, 算数据起始位置和跨页数
  PRP1 = 0x8000_0800
  → 起始页 = 0x8000_0000, 偏移 = 0x800
  → 第一页可用空间 = 4096 - 0x800 = 3072 字节
  → 剩余数据 = 256KB - 3072 = 258048 字节
  → 剩余页数 = ceil(258048 / 4096) = 63 页
  → 总跨页数 = 1 + 63 = 64 页

步骤 3: 判断 PRP2 填法
  跨页数 = 64 ≥ 3 → PRP2 应该是链表指针

步骤 4: 检查 PRP2
  PRP2 应该指向一个有效链表地址 (4KB对齐)
  链表应该有 63 项 (64页 - 1页由PRP1覆盖)

步骤 5: 检查链表内容
  每项 8 字节, 指向后续每页的基地址
  地址应该连续递增: 0x8000_1000, 0x8000_2000, ...


总结：
问题	答案
SLBA 和 PRP 有关系吗？	没有直接关系。SLBA 描述 SSD 侧位置，PRP 描述主机内存侧位置
NLB 和 PRP 有关系吗？	有间接关系。NLB 决定数据量，数据量决定跨页数，跨页数决定 PRP2 填法
PRP1 偏移影响 PRP2 吗？	影响。偏移不同可能导致跨页数不同
调试时要一起看吗？	要。NLB + PRP1 + PRP2 必须一致对应，不能单独看
一句话记忆：SLBA + NLB 决定"搬多少"（数据量），PRP1 + PRP2 决定"从哪搬"（内存位置）。NLB 算出的数据量会反过来决定 PRP2 怎么填。四者必须匹配，否则数据会错。
4.4 ILA 抓波形实操
4.4.1 要抓哪些信号？
信号类别	信号	看什么
初始化	link_up / configure_finished / nvme_ready	时序是否合理
命令	SQE 的 Opcode / NSID / SLBA / NLB / PRP	填得对不对
门铃	Doorbell 写操作	Tail 指针更新
完成	CQE 的 Status / CID / Phase	状态对不对
数据	DMA 请求 / 响应	数据搬运对不对
错误	error_flags	有没有报错
4.4.2 ILA 设置技巧
    • 触发条件：设在 nvme_ready 上升沿，抓初始化全过程
    • 命令触发：设在 Doorbell 写操作，抓命令提交和完成
    • 存储深度：至少 4096 个样本，够抓一条完整命令流程
    • 采样时钟：用 PCIe user clock（250MHz），别用太慢的时钟
4.4.3 怎么看波形？
第一步：看初始化
    • nvme_ready 拉高了吗？
    • 之前有没有写 CC.EN=1？
    • CSTS.RDY 有没有变 1？
第二步：发一条 Read 命令，抓全过程
    • SQE 填得对不对？
    • Doorbell 写了吗？
    • CQE 回来了吗？Status=0x00？
    • 数据搬对了吗？（读回的数据和预期一致）
第三步：发错误命令，看 Status Code。比如发 NSID=0，看 Status Code 是不是 0x02
4.5 深入补充：SGL 详解、Doorbell 机制、ILA 触发示例、波形诊断
4.5.1 SGL（Scatter Gather List）详解
虽然你的场景用 PRP 就够了，但调试时可能遇到 SGL 相关问题，需要了解。
SGL 与 PRP 的本质区别：

PRP 描述数据缓冲区:
  只能描述"以 4KB 页为单位的物理地址"
  每个页必须 4KB 对齐
  → 适合连续大块数据

SGL 描述数据缓冲区:
  可以描述"任意地址 + 任意长度"的数据段
  每个段可以任意字节对齐
  → 适合分散的不连续数据


SGL 数据块格式（16 字节）：

Byte 0-7:   地址 (64 位)
Byte 8-11:  长度 (32 位)
Byte 12:    类型 (8 位)
Byte 13-15: 保留

类型值:
  0x00 = Data Block (数据段)
  0x01 = Bit Bucket (写时忽略, 读时填零)
  0x02 = Segment (指向下一个 SGL 段)
  0x03 = Last Segment (最后一个段)
  0x04 = Transport (传输特定)


SGL 链表示例：

SQE 中的 PRP1 位置填第一个 SGL 描述符:

SGL 描述符 0 (在 SQE 中):
  地址 = 0x0000_1000, 长度 = 2048, 类型 = Segment (指向下一段)
      │
      ▼
SGL 描述符 1 (在主机内存 0x0000_1000):
  地址 = 0x0000_5000, 长度 = 4096, 类型 = Data Block
  地址 = 0x0001_2000, 长度 = 1024, 类型 = Data Block
  地址 = 0x0002_8000, 长度 = 8192, 类型 = Last Segment


SQE 中选择 PRP 还是 SGL：
SQE 的 CDW0 中 PSDT 字段决定用哪种：
    • PSDT = 00 → 用 PRP1 + PRP2
    • PSDT = 01 → 用 SGL1（在 PRP1/PRP2 位置）
    • PSDT = 10 → 保留
    • PSDT = 11 → 用 SGL2
调试关注：
    • 确认 IP 用的是 PRP（PSDT=00），不是 SGL
    • 如果 IP 支持 SGL，确认 SQE 的 PSDT 字段设置正确
4.5.2 Doorbell 寄存器工作机制详解
Doorbell 是 NVMe 最精巧的设计之一，值得深入理解。
Doorbell 的本质：
    • 每个 SQ 有一个 Doorbell 寄存器（Host 写 Tail 指针）
    • 每个 CQ 有一个 Doorbell 寄存器（Host 写 Head 指针）
    • Doorbell 在 SSD 的 PCIe 配置空间里（通过 BAR0 访问）
SQ Doorbell 工作流程：

初始状态: SQ 深度=4, Head=0, Tail=0

  Step 1: Host 写 SQE[0] 到主机内存
          Host 写 SQ Doorbell = 1 (Tail=1)
          → SSD 知道有 1 条新命令, 从 SQ[0] 取
          → SSD 取完后, SSD 内部更新 Head=1

  Step 2: Host 写 SQE[1] 到主机内存
          Host 写 SQ Doorbell = 2 (Tail=2)
          → SSD 取 SQ[1], Head=2

  Step 3: Host 写 SQE[2], SQE[3]
          Host 写 SQ Doorbell = 0 (Tail=0, 环形回绕!)
          → SSD 取 SQ[2], SQ[3], Head=0

  队列已满 (Head==Tail), 不能再写了


CQ Doorbell 工作流程：

初始状态: CQ 深度=4, Head=0

  Step 1: SSD 写 CQE[0] 到主机内存
          SSD 发中断
          → Host 读 CQE[0], 处理
          → Host 写 CQ Doorbell = 1 (Head=1)
          → 告诉 SSD "我处理到 CQE[0] 了, 可以覆盖了"

  Step 2: SSD 写 CQE[1], 发中断
          → Host 读 CQE[1], 写 CQ Doorbell = 2

  ...

  Step 4: Host 写 CQ Doorbell = 0 (Head=0, 环形回绕)


关键理解：
    • SQ Doorbell：Host 告诉 SSD"我写到了哪里"（Tail）
    • CQ Doorbell：Host 告诉 SSD"我读到了哪里"（Head）
    • SSD 不主动写 Doorbell，是 Host 写
    • Tail 和 Head 都是环形递增的（0,1,2,…,depth-1,0,1,…）
Phase 位与 CQ 的配合：

CQE 的 Phase 位:
  第1轮: P=1, CQE[0],CQE[1],CQE[2],CQE[3]
  第2轮: P=0, CQE[0],CQE[1],CQE[2],CQE[3]
  第3轮: P=1, CQE[0],...

Host 轮询 CQ 时:
  读 CQE[Head], 检查 Phase
  如果 Phase != 上次记录的值 → 新完成项, 处理它
  如果 Phase == 上次记录的值 → 没有新的, 继续等

  处理完后, Head++, 写 CQ Doorbell
  当 Head 回绕到 0, 更新记录的 Phase 值


为什么要 Phase 位？
因为 CQ 是环形队列，Head 和 Tail 都可能回绕到 0。如果不用 Phase 位，Host 无法区分"CQE[0] 是新写的"还是"上次处理过的旧数据"。Phase 位每轮翻转一次，解决了这个问题。
4.5.3 常见波形异常诊断指南
异常 1：nvme_ready 一直不拉高

诊断步骤:
1. 看 link_up 是否拉高
   → 否: PCIe 物理层问题, 检查 REFCLK/通道/速率
   → 是: 继续

2. 看 configure_finished 是否拉高
   → 否: BAR 分配失败, 检查 PCIe 枚举
   → 是: 继续

3. 读 CSTS.RDY 是否为 1
   → 否: CC.EN 可能没写, 或 SSD 还在初始化
   → 是: 但 nvme_ready 不拉高 → IP 内部状态机问题

4. 检查 I/O 队列创建命令的返回 Status
   → 不是 0x00: 队列创建失败, 看错误码排查


异常 2：Write 命令 CQE Status = 0x04 (Data Transfer Error)

诊断步骤:
1. 抓 SQE 波形, 检查 PRP1 地址:
   → PRP1 地址是否在有效内存范围
   → PRP1 低 12 位是否与缓冲区偏移匹配

2. 检查 DMA 通路:
   → DMA 请求是否发出
   → DMA 地址是否与 PRP 一致
   → DMA 响应是否正常 (无 SLVERR/DECERR)

3. 检查内存:
   → 缓冲区地址是否已正确分配
   → DDR 是否初始化正常


异常 3：数据错位（读回数据顺序不对）

诊断步骤:
1. 写递增序列 0,1,2,...,255,0,1,2,...
2. 读回, 找出错位位置
3. 如果错位粒度 = 4KB → 可能是 PRP 页顺序错
4. 如果错位粒度 = 64B → 可能是 SQE 顺序错
5. 如果错位粒度 = DMA burst → DMA 乱序

6. 抓 DMA 请求地址序列, 看是否按顺序递增
   → 如果乱序: IP 的 DMA 没有严格顺序保证
   → 这是博原"DMA 严格顺序"设计要解决的问题


异常 4：CQE Phase 位不翻转

诊断步骤:
1. 连续读多条 CQE, 记录 Phase 值
2. 正常应该: 1,1,1,1,0,0,0,0,1,1,1,1,...
3. 如果一直是 1 → SSD 的 Phase 逻辑有问题 (罕见)
4. 如果一直是 0 → Host 可能漏读了 CQE
5. 如果随机翻转 → 信号完整性问题 (检查 PCIe 信号)


4 完整数据传输流程
设备从上电到完成一次读写操作流程如下所示：

FPGA与SSD工作内容对照如下所示：

FPGA芯片内部逻辑工作流程如下：


附录：推荐学习资料
资料	用途	获取方式
NVMe Base Specification 1.3	协议权威定义	NVM Express 官网免费下载
Xilinx PG054 PCIe IP 文档	PCIe 基础	Xilinx 官网
